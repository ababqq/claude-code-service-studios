#!/bin/bash

# --- work from the project root ----------------------------------------------
# Every path below is repo-relative, so a hook invoked with a working directory
# that is not the repo root would silently read and write the WRONG TREE --
# returning a near-empty result instead of the session-recovery block, and
# creating stray trees such as docs/production/session-logs/ on write.
#
# PRECEDENCE IS LOAD-BEARING. A cwd that IS a project root carries real
# information and must win: a caller sitting inside another project means that
# project, not this one. Resolving to the script's own location first would
# override them. So, in order:
#   1. cwd holds project.yaml   -> cwd   (a project root)
#   2. cwd holds .claude/       -> cwd   (a project root not yet configured)
#   3. CLAUDE_PROJECT_DIR       -> that  (populated in the hook environment)
#   4. this script's location   -> <root>/.claude/hooks/../.. by construction
# Rule 4 always works and needs no environment at all; rules 1-2 stop it from
# overriding a caller that legitimately means somewhere else.
#
# NOT an upward search: that resolves a nested project to its parent's config.
if [ -f "project.yaml" ] || [ -d ".claude" ]; then
  CCSS_ROOT="$PWD"
elif [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -d "${CLAUDE_PROJECT_DIR}" ]; then
  CCSS_ROOT="$CLAUDE_PROJECT_DIR"
else
  CCSS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." 2>/dev/null && pwd)"
fi
[ -n "$CCSS_ROOT" ] && cd "$CCSS_ROOT" 2>/dev/null || true

# Hook: detect-gaps.sh
# Event: SessionStart
# Purpose: Observe documentation gaps between what is on disk and what the
#          project's workflow tier asks for -- code without PRDs, code without
#          ADRs, a backend without an API contract, migrations without a data
#          model, undocumented prototypes, and a recorded stage the tree has
#          outrun -- and name the one skill that closes each gap.
# Cross-platform: Windows Git Bash compatible (grep -E, not -P); bash 3.2.
#
# OBSERVATIONS, NEVER VERDICTS (CLAUDE.md). Every line below says what is on
# disk and suggests a skill. Nothing here writes a file, advances the stage, or
# decides that a gap blocks anything -- /gate-check owns that, and it asks.
#
# THE CHECKS
#   0  fresh project           no stack pin, no product brief or one-pager,
#                              no app manifest                  -> /start
#   1  code, sparse PRDs       > 50 source files, < 5 PRDs      -> /reverse-document prd
#   2  undocumented prototype  neither REPORT.md nor SPIKE-NOTE.md -> /prototype report
#   3  code, no ADRs           0 ADRs at standard, < 3 at full  -> /reverse-document architecture
#   4  backend, no contract    a backend root, no API contract  -> /api-design
#   5  migrations, no model    migrations_dir has files, no
#                              docs/data/data-model.md          -> /data-model
#   6  stage lag               stage-estimate.sh is >= 2 phases
#                              ahead of project.stage           -> /gate-check
#   7  unrecorded import       a design/handoff/<slug>/ directory
#                              without HANDOFF.md               -> /design-handoff --for <slug>
#
# TIER-AWARE. Checks 1, 3, 4 and 5 ask "where is the document for this code?".
# At `modes.workflow: minimal` the answer is that there deliberately is none:
# the one-pager and a pinned stack are all that tier requires before code
# starts. Reporting their absence nags the user about work their own
# configuration told them to skip -- and a warning that fires when nothing is
# wrong trains the user to ignore the ones that matter. So at minimal those
# four checks are skipped, and the skip is announced once. Checks 2, 6 and 7
# are not tiered: an undocumented prototype, a stale stage and an imported
# design nobody recorded are gaps at any tier.
#
# CODE ROOTS come from yaml-helper resolve_code_roots, never from a literal
# directory: every layer's declared root, the data layer's migrations_dir,
# stack.shared_roots, and undeclared apps/*, services/*, packages/* workspaces.
# Counting goes through list_code_files (pruned, extension-filtered). No root
# resolved is NOT "no code": checks 1, 3 and 4 then print NOT CHECKED lines
# instead of a silence that reads as a clean result.

set +e

echo "=== Checking for Documentation Gaps ==="

NOT_RESOLVED_HINT="set stack.layers.<layer>.root via /setup-stack"

# --- yaml-helper, sourced once ---
YH_LOADED=false
if [ -f .claude/hooks/yaml-helper.sh ]; then
  . .claude/hooks/yaml-helper.sh 2>/dev/null
  command -v resolve_setting >/dev/null 2>&1 && YH_LOADED=true
fi

# --- Check 0: Fresh project detection (suggests /start) ---
#
# Fresh = all three of:
#   - no stack.pinned_on        (/setup-stack has never pinned a stack)
#   - no product brief AND no one-pager in design/product/ (the Discovery
#     record at standard/full and at minimal respectively -- testing only one
#     of them greets a minimal project that has run /start and /brainstorm
#     with "NEW PROJECT" at every session)
#   - no manifest at the repo root or in any apps/* or services/* directory
#     (existing code means an existing product, whatever its docs say)
FRESH_PROJECT=true

# Stack pin. The grep is a cheap superset pre-filter so an unconfigured
# template pays no interpreter start; get_yaml_key confirms the dotted path.
if [ -f project.yaml ] && grep -qE '^[[:space:]]+pinned_on:[[:space:]]*[^[:space:]#]' project.yaml 2>/dev/null; then
  if [ "$YH_LOADED" = true ] && command -v get_yaml_key >/dev/null 2>&1; then
    [ -n "$(get_yaml_key project.yaml stack.pinned_on 2>/dev/null)" ] && FRESH_PROJECT=false
  else
    FRESH_PROJECT=false   # the pre-filter's line is the only evidence we have
  fi
fi

# Discovery record.
if [ -f "design/product/product-brief.md" ] || [ -f "design/product/one-pager.md" ]; then
  FRESH_PROJECT=false
fi

# Manifests. The list is yaml-helper's own (the one resolve_code_roots uses to
# recognise a workspace package), so "is there code?" and "which roots are
# there?" can never disagree; the literal is the same list for a tree whose
# helper is missing.
MANIFESTS="${_yaml_helper_manifests:-package.json pyproject.toml build.gradle build.gradle.kts pom.xml go.mod pubspec.yaml Cargo.toml composer.json Gemfile}"
if [ "$FRESH_PROJECT" = true ]; then
  for _dir in . apps/* services/*; do
    [ -d "$_dir" ] || continue
    for _m in $MANIFESTS; do
      if [ -f "$_dir/$_m" ]; then FRESH_PROJECT=false; break 2; fi
    done
  done
fi

if [ "$FRESH_PROJECT" = true ]; then
  echo ""
  echo "🚀 NEW PROJECT: no stack pinned, no product brief or one-pager, no app manifest."
  echo "   This looks like a fresh start! Run: /start"
  echo ""
  echo "💡 To get a comprehensive project analysis, run: /project-stage-detect"
  echo "==================================="
  exit 0
fi

# --- Resolve the workflow tier once, for the checks below ---
#
# resolve_setting, NOT get_yaml_key: `modes.workflow` is rigor-fronted, so a
# project that set `rigor: standard` and nothing else has no `modes.workflow`
# key to read. Only the full chain sees the expansion. Same pattern and same
# reason as validate-commit.sh.
#
# NO FALLBACK TIER. When the helper cannot answer, the tiered checks say NOT
# CHECKED; a hard-coded tier would be a second default that disagrees with the
# documented one.
#
# Resolved AFTER the fresh-project early exit, so a brand-new project never pays
# for the lookup.
WORKFLOW=""
if [ "$YH_LOADED" = true ]; then
  _w=$(resolve_setting modes.workflow 2>/dev/null)
  WORKFLOW="${_w%%$(printf '\t')*}"
fi
case "$WORKFLOW" in
  minimal)       DOC_CHECKS=false ;;
  standard|full) DOC_CHECKS=true ;;
  *)             DOC_CHECKS=unknown ;;
esac

if [ "$DOC_CHECKS" = false ]; then
  echo "ℹ️  Checks 1, 3, 4, 5 skipped — modes.workflow is minimal (PRDs, ADRs, an API contract and a data model are not required at this tier)."
elif [ "$DOC_CHECKS" = unknown ]; then
  echo "ℹ️  NOT CHECKED — checks 1, 3, 4, 5: modes.workflow could not be resolved (yaml-helper unavailable)."
fi

# --- Resolve the code roots once, for checks 1, 3, 4 and 5 ---
#
# One line per root: <dir> TAB <layer> TAB <source>. `missing` roots are
# declared but absent on disk -- never scanned. Resolved AFTER the fresh-project
# early exit, so a brand-new project never pays for the lookup.
CODE_ROOTS=""
ROOTS_STATE="unresolved"
if [ "$YH_LOADED" = true ] && command -v resolve_code_roots >/dev/null 2>&1; then
  CODE_ROOTS=$(resolve_code_roots 2>/dev/null)
  if [ -n "$(printf '%s\n' "$CODE_ROOTS" | awk -F '\t' '$1 != "" && $3 != "missing"')" ]; then
    ROOTS_STATE="resolved"
  fi
else
  ROOTS_STATE="nohelper"
fi
# Roots worth naming in a remediation: every scannable root except the data
# layer's migrations directory (a migration folder is not a module to document).
MODULE_ROOTS=$(printf '%s\n' "$CODE_ROOTS" | awk -F '\t' '$1 != "" && $3 != "missing" && $2 != "data" { print $1 }')
MODULE_ROOTS_LIST=$(printf '%s\n' "$MODULE_ROOTS" | awk 'NF' | paste -sd, - | sed 's/,/, /g')

# A doc check that cannot locate the code has not established that there are no
# gaps -- it has established nothing (obligations 1 and 3 of
# .claude/rules/skill-authoring.md). One line per check that did not run.
if [ "$DOC_CHECKS" = true ] && [ "$ROOTS_STATE" != "resolved" ]; then
  if [ "$ROOTS_STATE" = "nohelper" ]; then
    _why="yaml-helper unavailable, code roots cannot be resolved"
  else
    _why="no code root resolved ($NOT_RESOLVED_HINT)"
  fi
  echo "ℹ️  Check 1 (code vs PRDs): NOT CHECKED — $_why"
  echo "ℹ️  Check 3 (ADRs for existing code): NOT CHECKED — $_why"
  echo "ℹ️  Check 4 (API contract for the backend): NOT CHECKED — $_why"
fi

# Source files across every scannable root. Capped: the checks only need to
# know whether there are more than 50, and a capped walk stops early on a large
# monorepo.
SRC_FILES=0
if [ "$ROOTS_STATE" = "resolved" ] && command -v list_code_files >/dev/null 2>&1; then
  SRC_FILES=$(list_code_files --limit 51 2>/dev/null | awk 'NF' | wc -l | tr -d ' ')
  case "$SRC_FILES" in ''|*[!0-9]*) SRC_FILES=0 ;; esac
fi

# --- Check 1: Substantial codebase but sparse PRDs ---
# PRDs live at depth 1 of design/prd/ -- one file per feature, nothing else
# there (review logs sit in design/prd/reviews/, which this count excludes).
PRD_FILES=$(find design/prd -mindepth 1 -maxdepth 1 -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
case "$PRD_FILES" in ''|*[!0-9]*) PRD_FILES=0 ;; esac

if [ "$DOC_CHECKS" = true ] && [ "$ROOTS_STATE" = "resolved" ] \
   && [ "$SRC_FILES" -gt 50 ] && [ "$PRD_FILES" -lt 5 ]; then
  echo "⚠️  GAP: Substantial codebase (more than 50 source files) but sparse PRDs ($PRD_FILES in design/prd/)"
  echo "    Code roots: ${MODULE_ROOTS_LIST:-none outside the data layer}"
  echo "    Suggested action: /reverse-document prd <root>/<module>  (one feature module at a time)"
  echo "    Or run: /project-stage-detect to get full analysis"
fi

# --- Check 2: Prototypes without their record ---
#
# A concept prototype's record is REPORT.md (/prototype, from
# templates/prototype-report.md); a spike's is SPIKE-NOTE.md (/prototype
# --spike). Either one documents the directory. Asking for a README flagged every
# prototype /prototype had ever produced, and the old remediation wrote the
# wrong file -- a warning that is always on is a warning nobody reads.
if [ -d "prototypes" ]; then
  UNDOCUMENTED_PROTOS=()
  while IFS= read -r proto_dir; do
    [ -z "$proto_dir" ] && continue
    # Normalize path separators for Windows
    proto_dir=$(echo "$proto_dir" | sed 's|\\|/|g')
    if [ ! -f "${proto_dir}/REPORT.md" ] && [ ! -f "${proto_dir}/SPIKE-NOTE.md" ]; then
      UNDOCUMENTED_PROTOS+=("$(basename "$proto_dir")")
    fi
  done <<EOF
$(find prototypes -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
EOF

  if [ ${#UNDOCUMENTED_PROTOS[@]} -gt 0 ]; then
    echo "⚠️  GAP: ${#UNDOCUMENTED_PROTOS[@]} prototype(s) without a record (neither REPORT.md nor SPIKE-NOTE.md):"
    for proto in "${UNDOCUMENTED_PROTOS[@]}"; do
      echo "    - prototypes/$proto/"
      echo "      Suggested action: /prototype report prototypes/$proto"
    done
  fi
fi

# --- Check 3: Code without architecture decisions ---
#
# ADRs are docs/architecture/adr-*.md (the catalog's architecture-decision
# glob) -- not every Markdown file under docs/architecture/, which would count
# architecture.md, reviews and the traceability matrix as decisions.
# Thresholds follow the tier: standard records critical ADRs only, so zero is
# the gap; full expects at least three Foundation-layer ADRs.
if [ "$DOC_CHECKS" = true ] && [ "$ROOTS_STATE" = "resolved" ] && [ "$SRC_FILES" -gt 0 ]; then
  ADR_COUNT=$(find docs/architecture -mindepth 1 -maxdepth 1 -type f -name "adr-*.md" 2>/dev/null | wc -l | tr -d ' ')
  case "$ADR_COUNT" in ''|*[!0-9]*) ADR_COUNT=0 ;; esac
  ADR_MIN=1
  [ "$WORKFLOW" = "full" ] && ADR_MIN=3
  if [ "$ADR_COUNT" -lt "$ADR_MIN" ]; then
    if [ "$ADR_COUNT" -eq 0 ]; then
      echo "⚠️  GAP: Source code exists but no ADRs are recorded (docs/architecture/adr-*.md)"
    else
      echo "⚠️  GAP: Source code exists but only $ADR_COUNT ADR(s) are recorded — the full workflow expects at least $ADR_MIN Foundation-layer ADRs"
    fi
    _shown=0
    while IFS= read -r _root; do
      [ -z "$_root" ] && continue
      [ "$_shown" -ge 3 ] && break
      echo "    Suggested action: /reverse-document architecture $_root"
      _shown=$((_shown + 1))
    done <<EOF
$MODULE_ROOTS
EOF
    [ "$_shown" -eq 0 ] && echo "    Suggested action: /architecture-decision"
  fi
fi

# --- Check 4: Backend without an API contract ---
#
# "Backend root" = a root declared under stack.layers.backend.root that exists
# on disk. The contract globs are READ FROM THE CATALOG (step api-design of the
# architecture phase), not repeated here: a contract style added there --
# OpenAPI, GraphQL, protobuf, AsyncAPI -- is recognised without editing this
# hook (derive coverage, don't enumerate). The reader follows the catalog's
# indentation contract, the same one artifact-check.sh parses.
#
# An UNDECLARED workspace may hold a backend this check cannot see; when there
# is no declared backend root but undeclared ones exist, the check says so
# instead of passing.
if [ "$DOC_CHECKS" = true ] && [ "$ROOTS_STATE" = "resolved" ]; then
  BACKEND_ROOTS=$(printf '%s\n' "$CODE_ROOTS" | awk -F '\t' '$2 == "backend" && $3 != "missing" { print $1 }' \
                  | paste -sd, - | sed 's/,/, /g')
  UNDECLARED_ROOTS=$(printf '%s\n' "$CODE_ROOTS" | awk -F '\t' '$2 == "undeclared" { print $1 }' \
                  | paste -sd, - | sed 's/,/, /g')
  if [ -n "$BACKEND_ROOTS" ]; then
    CATALOG=".claude/docs/workflow-catalog.yaml"
    API_GLOBS=""
    if [ -f "$CATALOG" ]; then
      API_GLOBS=$(awk -v P="architecture" -v S="api-design" -v Q="'" '
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
      ' "$CATALOG" 2>/dev/null)
    fi
    if [ -z "$API_GLOBS" ]; then
      echo "ℹ️  Check 4 (API contract for the backend): NOT CHECKED — the catalog's architecture/api-design step is not readable ($CATALOG)"
    else
      CONTRACT=""
      while IFS= read -r _g; do
        [ -z "$_g" ] && continue
        for _f in $_g; do
          if [ -f "$_f" ]; then CONTRACT="$_f"; break 2; fi
        done
      done <<EOF
$API_GLOBS
EOF
      if [ -z "$CONTRACT" ]; then
        echo "⚠️  GAP: Backend code root ($BACKEND_ROOTS) but no API contract in docs/api/"
        echo "    Expected one of: $(printf '%s\n' "$API_GLOBS" | paste -sd, - | sed 's/,/, /g')"
        echo "    Suggested action: /api-design"
      fi
    fi
  elif [ -n "$UNDECLARED_ROOTS" ]; then
    echo "ℹ️  Check 4 (API contract for the backend): NOT CHECKED — no backend root declared, and undeclared roots ($UNDECLARED_ROOTS) may hold one (declare them with /setup-stack)"
  fi
fi

# --- Check 5: Migrations without a data model ---
#
# The data layer's migrations_dir (stack.layers.data.migrations_dir) is the one
# place executable migrations live. Files there with no docs/data/data-model.md
# mean the schema is evolving with no record of ownership, classification or
# retention -- the document /data-model writes and the migration rules read.
if [ "$DOC_CHECKS" = true ] && [ "$ROOTS_STATE" = "resolved" ]; then
  while IFS= read -r _mdir; do
    [ -z "$_mdir" ] && continue
    if [ -n "$(find "$_mdir" -type f 2>/dev/null | head -1)" ] && [ ! -f "docs/data/data-model.md" ]; then
      echo "⚠️  GAP: Migrations exist in $_mdir but there is no data model (docs/data/data-model.md)"
      echo "    Suggested action: /data-model"
      break
    fi
  done <<EOF
$(printf '%s\n' "$CODE_ROOTS" | awk -F '\t' '$2 == "data" && $3 != "missing" { print $1 }')
EOF
fi

# --- Check 6: project.stage is behind what is actually on disk ---
#
# Only /gate-check advances the stage, and the lightweight path never has to
# run one -- so a project with stories in flight and real code can keep
# reporting `Definition` to the status line, to /help, and to every skill that
# branches on stage.
#
# The comparison comes from .claude/scripts/stage-estimate.sh, the one ladder
# the status line, /help and /gate-check share: SOURCE: project.yaml means a
# stage is recorded, and ESTIMATE is what the tree looks like. Two or more
# phases apart is a gap; one phase apart is ordinary (the next gate is simply
# not run yet).
#
# This is an OBSERVATION, never a write. The stage advances on a /gate-check
# PASS with the user confirming, so a hook that advanced it silently would be the
# worse bug. Say what is inconsistent and name the skill that resolves it.
SE_SCRIPT=".claude/scripts/stage-estimate.sh"
if [ -f "$SE_SCRIPT" ]; then
  SE_OUT=$(bash "$SE_SCRIPT" "$PWD" 2>/dev/null)
  SE_STAGE=$(printf '%s\n' "$SE_OUT" | sed -n 's/^STAGE:[[:space:]]*//p' | head -1)
  SE_SOURCE=$(printf '%s\n' "$SE_OUT" | sed -n 's/^SOURCE:[[:space:]]*//p' | head -1)
  SE_EST=$(printf '%s\n' "$SE_OUT" | sed -n 's/^ESTIMATE:[[:space:]]*//p' | head -1)
  SE_EVIDENCE=$(printf '%s\n' "$SE_OUT" | sed -n 's/^EVIDENCE:[[:space:]]*//p' | head -1)
  _stage_index() {
    case "$1" in
      Discovery) echo 1 ;; Definition) echo 2 ;; Architecture) echo 3 ;;
      Validation) echo 4 ;; Build) echo 5 ;; Hardening) echo 6 ;; Launch) echo 7 ;;
      *) echo 0 ;;
    esac
  }
  if [ "$SE_SOURCE" = "project.yaml" ]; then
    _si=$(_stage_index "$SE_STAGE")
    _ei=$(_stage_index "$SE_EST")
    if [ "$_si" -gt 0 ] && [ "$_ei" -gt 0 ] && [ $((_ei - _si)) -ge 2 ]; then
      echo "⚠️  GAP: project.stage says $SE_STAGE but the tree looks like $SE_EST — run /gate-check"
      [ -n "$SE_EVIDENCE" ] && echo "    Evidence: $SE_EVIDENCE"
      echo "    /gate-check asks before advancing; this hook never writes the stage."
    fi
  fi
else
  echo "ℹ️  Check 6 (stage lag): NOT CHECKED — $SE_SCRIPT not found"
fi

# --- Check 7: Imported designs without their record ---
#
# /design-handoff keeps one directory per imported external design (a Claude
# Design export, a Design artifact, a Figma frame) with the record HANDOFF.md
# (templates/design-handoff.md) beside the snapshot. A directory without it is
# a snapshot nobody can date, trace to a UX spec, or tell apart from a verified
# one -- the same gap Check 2 reports for prototypes.
if [ -d "design/handoff" ]; then
  UNRECORDED_HANDOFFS=()
  while IFS= read -r handoff_dir; do
    [ -z "$handoff_dir" ] && continue
    handoff_dir=$(echo "$handoff_dir" | sed 's|\\|/|g')
    if [ ! -f "${handoff_dir}/HANDOFF.md" ]; then
      UNRECORDED_HANDOFFS+=("$(basename "$handoff_dir")")
    fi
  done <<EOF
$(find design/handoff -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
EOF

  if [ ${#UNRECORDED_HANDOFFS[@]} -gt 0 ]; then
    echo "⚠️  GAP: ${#UNRECORDED_HANDOFFS[@]} imported design(s) without a record (no HANDOFF.md):"
    for handoff in "${UNRECORDED_HANDOFFS[@]}"; do
      echo "    - design/handoff/$handoff/"
      echo "      Suggested action: /design-handoff --for $handoff"
    done
  fi
fi

# --- Summary ---
echo ""
echo "💡 To get a comprehensive project analysis, run: /project-stage-detect"
echo "==================================="

exit 0
