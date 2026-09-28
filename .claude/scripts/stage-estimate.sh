#!/usr/bin/env bash
# stage-estimate.sh — the single place that estimates a project's stage from disk.
#
# Every consumer that needs "where is this project?" asks this script instead of
# carrying its own ladder: statusline.sh (--quick), /help and
# /project-stage-detect (full), /adopt, /start (existing-product path),
# /gate-check (target phase when called with no argument) and detect-gaps.sh
# (stage-lag check). One ladder means the status line, /help and the gates can
# never disagree about the same tree.
#
# EMITS OBSERVATIONS, NOT A VERDICT (per .claude/docs/context-management.md
# rule 2). It reports the recorded stage and what the tree looks like; it never
# says a stage is wrong, never writes project.stage, and never decides whether
# a gap matters. Only /gate-check advances the stage, on a PASS and an explicit
# user confirmation.
#
# Usage: bash .claude/scripts/stage-estimate.sh [--quick] [project-root]
#   --quick       status-line mode: fixed paths only (bounded shell globs, no
#                 recursive walk), no source-file count. Budget: < 100 ms on a
#                 typical repo, because the status line runs it on every turn.
#   project-root  defaults to the four-step root resolution below; an explicit
#                 path is taken as-is (used by the test suite against fixtures).
#
# Skills run it at run time with the Bash tool — never as a `!` injection.
#
# Output (exactly these four lines, in this order):
#   STAGE: <Discovery|Definition|Architecture|Validation|Build|Hardening|Launch>
#   SOURCE: <project.yaml|estimated>
#   ESTIMATE: <one of the seven stage values>
#   EVIDENCE: <one short clause naming the rung that matched>
#
#   STAGE     project.stage from project.yaml when it is set AND a valid stage
#             value; otherwise the ESTIMATE. SOURCE says which.
#   ESTIMATE  always computed, even when project.stage is set, so a caller can
#             compare the recorded stage with the tree (detect-gaps warns when
#             the estimate is two or more phases ahead).
#   EVIDENCE  names the rung and the path that satisfied it; rung 7 names the
#             two Discovery markers instead (product brief or one-pager —
#             required; stack.pinned_on — recommended in Discovery, required by
#             the later gates). When a check was skipped (--quick, no code root
#             resolved, helper missing) and the estimate landed below the rung
#             that check belongs to, the clause says so in parentheses — a skip
#             announces itself. A project.stage value that is not a stage is
#             named there too, so SOURCE: estimated never hides a typo.
#
# THE LADDER (first match wins, most-advanced first):
#   1. any production/releases/*/release-record.md                  -> Launch
#   2. any production/qa/hardening-*.md or
#      production/releases/*/release-checklist.md                   -> Hardening
#      (QA sign-offs are deliberately NOT a rung: /team-qa also writes
#      per-sprint sign-offs during Build, so a sign-off proves nothing about
#      the phase.)
#   3. production/sprint-status.yaml has a story at in-progress, review or
#      done (the same pattern as the catalog's `implement` step), or >= 10
#      source files across the resolved code roots (yaml-helper
#      `list_code_files --limit 10`; skipped with --quick)          -> Build
#   4. any production/epics/*/EPIC.md, production/sprints/sprint-*.md,
#      production/walking-skeleton/report-*.md, or >= 1 design/ux/*.md
#                                                                   -> Validation
#   5. docs/architecture/architecture.md, any docs/architecture/adr-*.md,
#      docs/data/data-model.md, or a file matching any API contract glob of
#      the catalog's architecture/api-design step                   -> Architecture
#   6. design/product/feature-map.md or >= 1 design/prd/*.md        -> Definition
#   7. otherwise                                                    -> Discovery
#
# The API contract globs are READ FROM THE CATALOG, not repeated here: a new
# contract style added to workflow-catalog.yaml is picked up without editing
# this script (derive coverage, don't enumerate).
#
# ALWAYS EXITS 0: a non-zero exit would abort the status line or a skill step,
# and "could not tell" is itself an observation the four lines can carry.

set +e

# --- work from the project root ----------------------------------------------
# Every path below is repo-relative, so a script invoked with a working
# directory that is not the repo root would silently read the WRONG TREE --
# estimating an empty directory as Discovery instead of the real project.
#
# PRECEDENCE IS LOAD-BEARING. A cwd that IS a project root carries real
# information and must win: a caller sitting inside another project means that
# project, not this one. Resolving to the script's own location first would
# override them. So, in order:
#   1. cwd holds project.yaml   -> cwd   (a project root)
#   2. cwd holds .claude/       -> cwd   (a project root not yet configured)
#   3. CLAUDE_PROJECT_DIR       -> that  (populated in the hook environment)
#   4. this script's location   -> <root>/.claude/scripts/../.. by construction
# Rule 4 always works and needs no environment at all; rules 1-2 stop it from
# overriding a caller that legitimately means somewhere else.
#
# NOT an upward search: that resolves a nested project to its parent's config.
# An explicit project-root argument bypasses all four rules.
_se_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"

QUICK=false
ROOT_ARG=""
while [ $# -gt 0 ]; do
  case "$1" in
    --quick) QUICK=true ;;
    -h|--help) sed -n '2,/^set +e$/p' "$0" | sed '$d'; exit 0 ;;
    *) [ -z "$ROOT_ARG" ] && ROOT_ARG="$1" ;;
  esac
  shift
done

if [ -n "$ROOT_ARG" ]; then
  CCSS_ROOT="$ROOT_ARG"
elif [ -f "project.yaml" ] || [ -d ".claude" ]; then
  CCSS_ROOT="$PWD"
elif [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -d "${CLAUDE_PROJECT_DIR}" ]; then
  CCSS_ROOT="$CLAUDE_PROJECT_DIR"
else
  CCSS_ROOT="$(cd "$_se_script_dir/../.." 2>/dev/null && pwd)"
fi

emit() {  # emit <stage> <source> <estimate> <evidence>
  printf 'STAGE: %s\nSOURCE: %s\nESTIMATE: %s\nEVIDENCE: %s\n' "$1" "$2" "$3" "$4"
}

if [ -z "$CCSS_ROOT" ] || ! cd "$CCSS_ROOT" 2>/dev/null; then
  # Nothing on disk could be inspected. Still four lines (consumers parse them),
  # and the evidence says exactly why the estimate is the bottom rung.
  emit "Discovery" "estimated" "Discovery" "rung 7: project root not readable (${CCSS_ROOT:-unset})"
  exit 0
fi
CCSS_ROOT="$PWD"

# The project's own framework copy first (it matches the catalog the project's
# skills read); this script's installation as the fallback, so a bare fixture
# directory with no .claude/ still resolves.
_se_pick() {  # _se_pick <repo-relative path> <installation path>
  if [ -f "$CCSS_ROOT/$1" ]; then printf '%s' "$CCSS_ROOT/$1"
  elif [ -f "$2" ]; then printf '%s' "$2"
  fi
}
HELPER="$(_se_pick .claude/hooks/yaml-helper.sh "$_se_script_dir/../hooks/yaml-helper.sh")"
CATALOG="$(_se_pick .claude/docs/workflow-catalog.yaml "$_se_script_dir/../docs/workflow-catalog.yaml")"

# --- helpers -----------------------------------------------------------------

# first_file <glob>... — print the first regular file any glob matches.
# Plain shell pathname expansion: every glob here is a fixed path with at most
# one `*` segment, so the walk is depth-bounded by construction. Matched names
# containing spaces survive intact (pathname expansion runs after word
# splitting); a glob that matches nothing stays literal and fails the -f test.
first_file() {
  local g f
  for g in "$@"; do
    for f in $g; do
      if [ -f "$f" ]; then printf '%s' "$f"; return 0; fi
    done
  done
  return 1
}

# catalog_globs <phase-id> <step-id> — the artifact globs one catalog step
# declares (`glob:` at 10 spaces and any_of `- glob:` at 12), one per line.
# Reads the catalog's indentation contract directly, the same contract
# artifact-check.sh parses; a malformed catalog yields nothing, never an error.
catalog_globs() {
  [ -n "$CATALOG" ] || return 0
  awk -v P="$1" -v S="$2" -v Q="'" '
    { sub(/\r$/, "") }
    /^[[:space:]]*#/ || /^[[:space:]]*$/ { next }
    /^[^ ]/         { phase = ""; step = ""; next }
    /^  [^ ]/       { phase = $1; sub(/:$/, "", phase); step = ""; next }
    /^      - id:/  { step = $0; sub(/^      - id:[[:space:]]*/, "", step)
                      gsub(/"/, "", step); gsub(Q, "", step); gsub(/[[:space:]]/, "", step); next }
    phase == P && step == S && ($0 ~ /^          glob:/ || $0 ~ /^            - glob:/) {
      v = $0; sub(/^[^:]*:[[:space:]]*/, "", v); sub(/[[:space:]]+$/, "", v)
      gsub(/"/, "", v); gsub(Q, "", v)
      if (v != "") print v
    }
  ' "$CATALOG" 2>/dev/null
}

# --- recorded stage ----------------------------------------------------------
# project.stage is read through yaml-helper's get_yaml_key with BOTH arguments
# (file, dotted path) — the one YAML reader every hook shares. It is not
# locally overridable, so project.local.yaml is never consulted. A value
# outside the seven stages is ignored (reported in EVIDENCE), never trusted.
recorded=""
stage_note=""
# Cheap superset pre-filter first: the status line runs this on every turn, and
# a project.yaml with no indented `stage:` line at all (the shipped template)
# cannot hold project.stage — no need to start an interpreter to learn that.
# It only ever skips the precise read, never decides the value.
if [ -f project.yaml ] && grep -qE '^[[:space:]]+stage:' project.yaml 2>/dev/null; then
  if [ -n "$HELPER" ]; then
    # Silenced on BOTH streams: anything the helper printed while being
    # sourced would land in front of the four contract lines.
    # shellcheck disable=SC1090
    . "$HELPER" >/dev/null 2>&1
    if command -v get_yaml_key >/dev/null 2>&1; then
      recorded="$(get_yaml_key "$CCSS_ROOT/project.yaml" project.stage 2>/dev/null)"
    else
      stage_note="project.stage NOT CHECKED — yaml-helper has no get_yaml_key"
    fi
  else
    stage_note="project.stage NOT CHECKED — yaml-helper.sh not found"
  fi
fi
case "$recorded" in
  Discovery|Definition|Architecture|Validation|Build|Hardening|Launch) ;;
  "") ;;
  *) stage_note="project.stage '$recorded' ignored — not a stage value"; recorded="" ;;
esac

# --- the ladder --------------------------------------------------------------
estimate=""
evidence=""
skipped=""   # why the rung-3 source count did not run, when it did not

# Rung 1 — a release has been recorded.
if f="$(first_file 'production/releases/*/release-record.md')"; then
  estimate="Launch"; evidence="rung 1: $f"
fi

# Rung 2 — hardening report or a release checklist exists.
if [ -z "$estimate" ] && f="$(first_file 'production/qa/hardening-*.md' \
                                         'production/releases/*/release-checklist.md')"; then
  estimate="Hardening"; evidence="rung 2: $f"
fi

# Rung 3 — stories are moving, or there is real code.
if [ -z "$estimate" ] && [ -f production/sprint-status.yaml ] \
   && grep -qE '^[[:space:]]+status:[[:space:]]*(in-progress|review|done)' production/sprint-status.yaml 2>/dev/null; then
  estimate="Build"; evidence="rung 3: production/sprint-status.yaml has a story in-progress, in review or done"
fi
if [ -z "$estimate" ]; then
  if [ "$QUICK" = true ]; then
    skipped="source count skipped in --quick mode"
  elif [ -z "$HELPER" ]; then
    skipped="source count NOT CHECKED — yaml-helper.sh not found"
  else
    # A subshell with CLAUDE_PROJECT_DIR pinned to the tree being estimated:
    # yaml-helper resolves its root from the cwd first and CLAUDE_PROJECT_DIR
    # second, and an unconfigured fixture must never be scanned as the project
    # the session happens to run in. `missing` roots are not scanned by
    # list_code_files; if every root is missing or none resolved, say so.
    scan="$(
      CLAUDE_PROJECT_DIR="$CCSS_ROOT"; export CLAUDE_PROJECT_DIR
      # shellcheck disable=SC1090
      . "$HELPER" >/dev/null 2>&1
      if ! command -v list_code_files >/dev/null 2>&1 \
         || ! command -v resolve_code_roots >/dev/null 2>&1; then
        echo "NOHELPER"; exit 0
      fi
      roots="$(resolve_code_roots 2>/dev/null | awk -F '\t' '$1 != "" && $3 != "missing"' | wc -l | tr -d ' ')"
      if [ "${roots:-0}" -eq 0 ]; then echo "NOROOT"; exit 0; fi
      echo "COUNT $(list_code_files --limit 10 2>/dev/null | awk 'NF' | wc -l | tr -d ' ')"
    )"
    case "$scan" in
      NOHELPER) skipped="source count NOT CHECKED — yaml-helper has no list_code_files" ;;
      NOROOT)   skipped="source count NOT CHECKED — no code root resolved" ;;
      COUNT\ *)
        n="${scan#COUNT }"
        case "$n" in ''|*[!0-9]*) n=0 ;; esac
        if [ "$n" -ge 10 ]; then
          estimate="Build"; evidence="rung 3: >= 10 source files under the resolved code roots"
        fi
        ;;
      *)        skipped="source count NOT CHECKED — code-root scan produced no result" ;;
    esac
  fi
fi

# Rung 4 — the path to Build is being validated.
if [ -z "$estimate" ] && f="$(first_file 'production/epics/*/EPIC.md' \
                                         'production/sprints/sprint-*.md' \
                                         'production/walking-skeleton/report-*.md' \
                                         'design/ux/*.md')"; then
  estimate="Validation"; evidence="rung 4: $f"
fi

# Rung 5 — architecture, decisions, data model or an API contract exist.
api_note=""
if [ -z "$estimate" ]; then
  if f="$(first_file 'docs/architecture/architecture.md' \
                     'docs/architecture/adr-*.md' \
                     'docs/data/data-model.md')"; then
    estimate="Architecture"; evidence="rung 5: $f"
  else
    api_globs="$(catalog_globs architecture api-design)"
    if [ -z "$api_globs" ]; then
      api_note="API contract globs NOT CHECKED — catalog step architecture/api-design not readable"
    else
      while IFS= read -r g; do
        [ -n "$g" ] || continue
        if f="$(first_file "$g")"; then
          estimate="Architecture"; evidence="rung 5: $f"; break
        fi
      done <<EOF
$api_globs
EOF
    fi
  fi
fi

# Rung 6 — features are being defined.
if [ -z "$estimate" ] && f="$(first_file 'design/product/feature-map.md' 'design/prd/*.md')"; then
  estimate="Definition"; evidence="rung 6: $f"
fi

# Rung 7 — nothing past Discovery on disk. Name the two Discovery markers so the
# caller sees what the bottom rung is made of: the brief (or one-pager) is
# required; the stack pin is recommended in Discovery and required by the later
# gates (Definition → Architecture at standard/full, Architecture → Validation
# at every tier).
if [ -z "$estimate" ]; then
  estimate="Discovery"
  if f="$(first_file 'design/product/product-brief.md' 'design/product/one-pager.md')"; then
    brief="$f present"
  else
    brief="no product brief or one-pager"
  fi
  # Same pattern as the catalog's stack-setup step, so the two never disagree.
  if [ -f project.yaml ] \
     && grep -qE '^[[:space:]]+pinned_on:[[:space:]]*.?[0-9]{4}-[0-9]{2}-[0-9]{2}' project.yaml 2>/dev/null; then
    pin="stack.pinned_on set"
  else
    pin="stack.pinned_on unset"
  fi
  evidence="rung 7: no Definition-or-later artifact ($brief; $pin)"
fi

# Skips announce themselves — but only when they could have mattered: a skipped
# source count is noise once a rung at or above Build has matched.
case "$estimate" in
  Validation|Architecture|Definition|Discovery)
    [ -n "$skipped" ] && evidence="$evidence ($skipped)" ;;
esac
case "$estimate" in
  Definition|Discovery)
    [ -n "$api_note" ] && evidence="$evidence ($api_note)" ;;
esac
[ -n "$stage_note" ] && evidence="$evidence ($stage_note)"

if [ -n "$recorded" ]; then
  emit "$recorded" "project.yaml" "$estimate" "$evidence"
else
  emit "$estimate" "estimated" "$estimate" "$evidence"
fi
exit 0
