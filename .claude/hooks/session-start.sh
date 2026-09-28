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

# Claude Code SessionStart hook: Load project context at session start
# Outputs context information that Claude sees when a session begins
#
# Input schema (SessionStart): stdin IS supplied -- VERIFIED, not asserted.
# Observed on real harness events as a single line of JSON with session_id,
# transcript_path, cwd, hook_event_name and `source` ("clear", "compact").
# Do NOT read stdin here unboundedly -- the harness may leave it open, and a
# blocking read costs this hook its whole 10s budget on every session start.
#
# THIS HOOK MUST FINISH INSIDE ITS BUDGET. If it is killed partway, the
# session-state block never reaches context and the session starts blind --
# and nothing visible from inside the session says so. The early-exit gating
# and bounded reads below are what keep it inside 2s; treat them as load-
# bearing, not as optimisation. The one open-ended piece of work -- the
# TODO/FIXME scan across every code root -- runs under its own 2-second budget
# and announces itself when it runs out.
#
# If that ever recurs, the diagnostic that works is a FIRE/DONE pair appended
# to a gitignored log at the top and bottom of this script -- "did it run at
# all" and "did it get here" are opposite failures with opposite fixes, and
# nothing else distinguishes them. /compact in particular CANNOT be used as
# evidence: PostCompact runs post-compact.sh, which prints the checkpoint
# independently, so seeing the checkpoint proves nothing about this script.
#
# Every line below is an OBSERVATION. Helpers emit observations, never verdicts
# (CLAUDE.md): this hook reports what the config and the tree say, and never
# writes project.yaml, the stage, or the session state.

echo "=== Claude Code Service Studios — Session Context ==="

# Current branch
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
if [ -n "$BRANCH" ]; then
    echo "Branch: $BRANCH"

    # Recent commits
    echo ""
    echo "Recent commits:"
    git log --oneline -5 2>/dev/null | while read -r line; do
        echo "  $line"
    done
fi

# --- yaml-helper, sourced once ---
# Every config read below goes through yaml-helper.sh, the one YAML reader the
# hooks, scripts and skills share. When it is missing or fails to load, each
# consumer below says so on its own line instead of substituting a value of its
# own -- a hook-local default is a second default, and two defaults disagree.
YH_LOADED=false
if [ -f .claude/hooks/yaml-helper.sh ]; then
    . .claude/hooks/yaml-helper.sh 2>/dev/null
    command -v resolve_setting >/dev/null 2>&1 && YH_LOADED=true
fi
TAB=$(printf '\t')

# --- review_mode ---
# Resolved the way skills resolve it: resolve_setting applies the FULL chain
# (project.local.yaml -> project.yaml -> modes.rigor expansion -> terminal
# default). modes.review_mode is rigor-fronted and locally overridable, so only
# resolve_setting reflects both a rigor-derived value (a project that set only
# `rigor: standard` shows `lean`) and a local override.
#
# NO FALLBACK VALUE. Unset on an unconfigured project: `modes.rigor` defaults to
# `minimal`, which resolves `review_mode` to `solo` -- and resolve_setting
# already knows that. A literal written here would be a second, independent
# default that drifts from the documented one (it did: this banner once showed
# `lean` on projects every skill treated as `solo`). When the helper cannot
# answer, the line says so.
echo ""
if [ "$YH_LOADED" = true ]; then
    RM=$(resolve_setting modes.review_mode 2>/dev/null)
    RM_VAL="${RM%%"$TAB"*}"
    RM_SRC=""
    case "$RM" in *"$TAB"*) RM_SRC="${RM#*"$TAB"}" ;; esac
    echo "review_mode: ${RM_VAL:-unset} (${RM_SRC:-unset})"
else
    echo "review_mode: unknown (yaml-helper unavailable)"
fi

# --- Stage ---
# From the one shared estimator, .claude/scripts/stage-estimate.sh -- the same
# ladder the status line, /help and /gate-check read, so the banner can never
# disagree with them. STAGE is project.stage when it is set and a valid stage,
# otherwise the estimate; SOURCE says which. --quick reads fixed paths only (no
# source-file count) and is budgeted under 100 ms, which this hook needs.
#
# The project root is passed explicitly: this hook already resolved it, and the
# estimator must look at the same tree.
SE_SCRIPT=".claude/scripts/stage-estimate.sh"
if [ -f "$SE_SCRIPT" ]; then
    SE_OUT=$(bash "$SE_SCRIPT" --quick "$PWD" 2>/dev/null)
    SE_STAGE=$(printf '%s\n' "$SE_OUT" | sed -n 's/^STAGE:[[:space:]]*//p' | head -1)
    SE_SOURCE=$(printf '%s\n' "$SE_OUT" | sed -n 's/^SOURCE:[[:space:]]*//p' | head -1)
    if [ -n "$SE_STAGE" ]; then
        echo "Stage: $SE_STAGE (${SE_SOURCE:-source not reported})"
    else
        echo "Stage: NOT CHECKED — $SE_SCRIPT printed no STAGE: line"
    fi
else
    echo "Stage: NOT CHECKED — $SE_SCRIPT not found"
fi

# --- Schema validation ---
# Surface invalid enum values in project.yaml and project.local.yaml so typos
# like `automation: chaotic` or `stage: Beta` surface at session start rather
# than failing inside a skill -- resolve_setting drops an invalid value and
# falls through, so without this line the typo is invisible.
#
# Scope, too: a key hand-written into project.local.yaml that is not on the
# local whitelist has a perfectly valid value and is still never read.
# validate_local_scope names those keys; it warns and never moves them.
if [ "$YH_LOADED" = true ]; then
    # Hard-error guard: project.local.yaml requires a project.yaml base
    if ! BASE_ERR=$(validate_local_yaml_base 2>&1); then
        echo ""
        echo "[!] $BASE_ERR"
    fi
    if [ -f "project.yaml" ] && command -v validate_yaml_enum >/dev/null 2>&1; then
        SCHEMA_ERRORS=$(validate_yaml_enum project.yaml 2>&1)
        if [ -n "$SCHEMA_ERRORS" ]; then
            echo ""
            echo "[!] project.yaml schema errors:"
            echo "$SCHEMA_ERRORS" | sed 's/^/    /'
        fi
    fi
    if [ -f "project.local.yaml" ]; then
        if command -v validate_yaml_enum >/dev/null 2>&1; then
            SCHEMA_ERRORS=$(validate_yaml_enum project.local.yaml 2>&1)
            if [ -n "$SCHEMA_ERRORS" ]; then
                echo ""
                echo "[!] project.local.yaml schema errors:"
                echo "$SCHEMA_ERRORS" | sed 's/^/    /'
            fi
        fi
        if command -v validate_local_scope >/dev/null 2>&1; then
            SCOPE_ERRORS=$(validate_local_scope project.local.yaml 2>&1 >/dev/null)
            if [ -n "$SCOPE_ERRORS" ]; then
                echo ""
                echo "[!] project.local.yaml scope errors (keys resolution never reads):"
                echo "$SCOPE_ERRORS" | sed 's/^/    /'
            fi
        fi
    fi
fi

# Current sprint (find most recent sprint file)
LATEST_SPRINT=$(ls -t production/sprints/sprint-*.md 2>/dev/null | head -1)
if [ -n "$LATEST_SPRINT" ]; then
    echo ""
    echo "Active sprint: $(basename "$LATEST_SPRINT" .md)"
fi

# Current milestone
#
# The newest milestone DEFINITION, not the newest file. /milestone-review writes
# `<milestone>-review.md` into the same directory, so right after a review the
# newest file is the review -- and the banner named "private-beta-review" as
# the milestone being worked toward. Reviews are excluded by name.
LATEST_MILESTONE=$(ls -t production/milestones/*.md 2>/dev/null | grep -v -- '-review\.md$' | head -1)
if [ -n "$LATEST_MILESTONE" ]; then
    echo "Active milestone: $(basename "$LATEST_MILESTONE" .md)"
fi

# --- Unresolved bugs ---
# One definition, shared with the phase gates, /team-qa sign-off,
# /release-checklist, /milestone-review and /bug-triage: a bug is UNRESOLVED
# when its `**Status**:` line is `Open`, `In Progress` or
# `Fixed — Pending Verification`. Counting files, or counting only `Open`,
# hides a fix nobody has verified yet -- the bug most likely to reach users.
#
# A missing or unrecognised status is not a permissive default: the file counts
# as unresolved and is named as unreadable, exactly as /bug-triage treats it.
# One awk pass over every bug file (xargs bounds the spawn count by ARG_MAX),
# reading only each file's first `**Status**:` line -- the Summary field.
BUG_DIR="production/qa/bugs"
if [ -d "$BUG_DIR" ]; then
    BUG_TALLY=$(find "$BUG_DIR" -maxdepth 1 -type f -name 'BUG-*.md' -print0 2>/dev/null \
        | xargs -0 awk '
            function tally() {
                if (st == "Open" || st == "In Progress" || st == "Fixed — Pending Verification") u++
                else if (st == "Verified Fixed" || st == "Closed" || st == "Won'"'"'t Fix") r++
                else x++
            }
            FNR == 1 { if (seen) tally(); seen = 1; st = ""; got = 0 }
            !got && /^[>[:space:]*-]*\*\*Status\*\*:/ {
                v = $0
                sub(/^[^:]*:[[:space:]]*/, "", v)
                sub(/[[:space:]]+$/, "", v)
                st = v; got = 1
            }
            END { if (seen) tally(); print u + 0, x + 0 }
        ' 2>/dev/null \
        | awk '{ u += $1; x += $2 } END { print u + 0, x + 0 }')
    UNRESOLVED=${BUG_TALLY%% *}
    UNREADABLE=${BUG_TALLY##* }
    case "$UNRESOLVED" in ''|*[!0-9]*) UNRESOLVED=0 ;; esac
    case "$UNREADABLE" in ''|*[!0-9]*) UNREADABLE=0 ;; esac
    BUG_TOTAL=$((UNRESOLVED + UNREADABLE))
    if [ "$BUG_TOTAL" -gt 0 ]; then
        if [ "$UNREADABLE" -gt 0 ]; then
            echo "Unresolved bugs: $BUG_TOTAL ($UNREADABLE with no readable **Status**: line — counted as unresolved)"
        else
            echo "Unresolved bugs: $BUG_TOTAL"
        fi
    fi
fi

# --- Code health quick check ---
#
# Every code root, not one directory. Roots come from yaml-helper
# resolve_code_roots: each layer's declared stack.layers.<layer>.root (a path
# or a flow list), the data layer's migrations_dir, stack.shared_roots, and
# every apps/* / services/* / packages/* workspace with a manifest that no layer
# declares. A single-directory read made a monorepo look clean whenever the one
# directory it opened was clean -- apps/web scanned, apps/api never opened.
#
# The walk goes through list_code_files (pruned: node_modules, build output,
# caches) and is capped twice: at 2000 files, and at 2 seconds of wall clock.
# The scan runs in a child shell with a watchdog; if the watchdog fires first
# the line says NOT CHECKED rather than printing a partial count as if it were
# the whole tree. The child writes only to this hook's capture pipe, and its
# stdin and stderr are /dev/null: the `2>/dev/null` after the capture does not
# reach a command substitution inside an assignment, so without them a killed
# scan's surviving descendants (the find and the awk reading it) held the
# hook's stderr open until the walk finished -- the hook exited at 2 s while a
# reader of its stderr kept waiting (measured: 31 s against a 30 s stub walk).
#
# Unresolved roots are NOT a clean result: nothing scanned is indistinguishable
# from nothing found, so the line says the scan did not run and never defaults
# to `src/`.
if [ "$YH_LOADED" = true ] && command -v resolve_code_roots >/dev/null 2>&1; then
    CODE_ROOTS=$(resolve_code_roots 2>/dev/null)
    SCAN_ROOTS=$(printf '%s\n' "$CODE_ROOTS" | awk -F '\t' '$1 != "" && $3 != "missing" { print $1 }')
    UNDECLARED=$(printf '%s\n' "$CODE_ROOTS" | awk -F '\t' '$2 == "undeclared" { print $1 }' \
                 | paste -sd, - | sed 's/,/, /g')
    MISSING_ROOTS=$(printf '%s\n' "$CODE_ROOTS" | awk -F '\t' '$3 == "missing" { print $1 }' \
                    | paste -sd, - | sed 's/,/, /g')
    CH_BLANK=false   # one blank line before this block, printed once
    if [ -z "$SCAN_ROOTS" ]; then
        echo ""; CH_BLANK=true
        if [ -n "$MISSING_ROOTS" ]; then
            echo "Code health: NOT CHECKED — every declared code root is missing on disk ($MISSING_ROOTS)"
        else
            echo "Code health: NOT CHECKED — no code root resolved (set stack.layers.<layer>.root via /setup-stack)"
        fi
    else
        # The child re-sources the helper (functions do not cross `bash -c`) and
        # pins CLAUDE_PROJECT_DIR to this tree, so the helper cannot resolve a
        # different project than the one this hook already chose.
        _SS_TODO_SCAN='
            . .claude/hooks/yaml-helper.sh >/dev/null 2>&1
            command -v list_code_files >/dev/null 2>&1 || { echo "SCAN-NOHELPER"; exit 0; }
            files=$(list_code_files --limit 2000 2>/dev/null | awk "NF")
            ext="derived"
            if command -v _yaml_helper_ext_derived >/dev/null 2>&1 \
               && [ -z "$(_yaml_helper_ext_derived 2>/dev/null)" ]; then
                ext="union"
            fi
            if [ -z "$files" ]; then echo "SCAN 0 0 0 $ext"; exit 0; fi
            n=$(printf "%s\n" "$files" | wc -l | tr -d " ")
            tf=$(printf "%s\n" "$files" | tr "\n" "\000" \
                 | xargs -0 grep -hE "TODO|FIXME" 2>/dev/null \
                 | awk "/TODO/ { t++ } /FIXME/ { f++ } END { print t + 0, f + 0 }")
            echo "SCAN $n ${tf:-0 0} $ext"
        '
        SCAN_OUT=$(
            CLAUDE_PROJECT_DIR="$PWD" bash -c "$_SS_TODO_SCAN" </dev/null 2>/dev/null &
            _ss_pid=$!
            ( sleep 2; kill "$_ss_pid" 2>/dev/null ) >/dev/null 2>&1 &
            _ss_dog=$!
            wait "$_ss_pid" 2>/dev/null
            kill "$_ss_dog" 2>/dev/null
        ) 2>/dev/null
        SCAN_LINE=$(printf '%s\n' "$SCAN_OUT" | grep '^SCAN ' | head -1)
        if printf '%s\n' "$SCAN_OUT" | grep -q '^SCAN-NOHELPER'; then
            echo ""; CH_BLANK=true
            echo "Code health: NOT CHECKED — yaml-helper has no list_code_files"
        elif [ -z "$SCAN_LINE" ]; then
            echo ""; CH_BLANK=true
            echo "Code health: NOT CHECKED — the TODO/FIXME scan did not finish inside its 2-second budget"
        else
            # SCAN <files> <todo lines> <fixme lines> <derived|union>
            set -- $SCAN_LINE
            SC_FILES=$2; SC_TODO=$3; SC_FIXME=$4; SC_EXT=$5
            if [ "${SC_TODO:-0}" -gt 0 ] 2>/dev/null || [ "${SC_FIXME:-0}" -gt 0 ] 2>/dev/null; then
                SC_SCOPE="$SC_FILES source files"
                [ "${SC_FILES:-0}" -ge 2000 ] 2>/dev/null && SC_SCOPE="the first 2000 source files (scan capped)"
                SC_ROOTS=$(printf '%s\n' "$SCAN_ROOTS" | paste -sd, - | sed 's/,/, /g')
                SC_NOTE=""
                [ "$SC_EXT" = "union" ] && SC_NOTE="; extensions: default union"
                echo ""; CH_BLANK=true
                echo "Code health: ${SC_TODO} TODOs, ${SC_FIXME} FIXMEs in ${SC_SCOPE} (roots: ${SC_ROOTS}${SC_NOTE})"
            fi
        fi
    fi
    # Undeclared roots were scanned above (skipping them would reproduce the
    # silent pass); the warning names them so /setup-stack can declare them.
    if [ -n "$UNDECLARED" ]; then
        [ "$CH_BLANK" = true ] || echo ""
        echo "WARN: undeclared code roots: $UNDECLARED — declare them with /setup-stack"
    fi
else
    echo ""
    echo "Code health: NOT CHECKED — yaml-helper unavailable, code roots cannot be resolved"
fi

# --- Active session state recovery ---
# Only THIS block is gated by features.session_state, not the whole hook: the
# sprint/milestone/git context above is not part of the session-state pipeline
# and a user who turns that pipeline off still wants it. Gating the whole hook
# (as the original spec's "exit early at the top" wording implies) would take
# the branch and stage context away with it.
#
# Fail OPEN: yaml-helper.sh is sourced conditionally above, so
# session_state_enabled may be undefined. An undefined function is falsey, which
# would silently suppress the recovery checkpoint -- the one piece of output
# whose absence the user cannot notice. Show the state unless we positively
# determined the flag is off.
STATE_FILE="production/session-state/active.md"
if [ -f "$STATE_FILE" ] && { ! command -v session_state_enabled >/dev/null 2>&1 || session_state_enabled; }; then
    echo ""
    echo "=== ACTIVE SESSION STATE DETECTED ==="
    echo "A previous session left state at: $STATE_FILE"
    echo "Read this file to recover context and continue where you left off."
    echo ""
    # The CHECKPOINT region -- the same region pre-compact.sh injects.
    #
    # Previewing `tail -20` here while pre-compact takes `head -100` would put two
    # consumers on opposite ends of one file, so which slice you got would
    # depend on which hook happened to fire. Neither was wrong, because
    # nothing defined where the recoverable state lived. The schema in
    # .claude/docs/templates/session-state.md defines it; both read it now.
    CHECKPOINT=$(sed -n '/<!-- CHECKPOINT -->/,/<!-- \/CHECKPOINT -->/p' "$STATE_FILE" 2>/dev/null \
                 | grep -v '<!-- /\?CHECKPOINT -->')
    TOTAL_LINES=$(wc -l < "$STATE_FILE" 2>/dev/null | tr -d ' ')
    # A sed range whose END address never matches runs to EOF. So a file with an
    # opening marker and NO closing one produced a non-empty capture of the whole
    # remaining file and took the healthy branch below -- silently previewing
    # narrative under a "Checkpoint:" heading, with no warning and no template
    # named. Emptiness cannot distinguish "no block" from
    # "unterminated block"; only the markers can, so test them directly.
    # rotate-session-state.sh already checks the CLOSING marker and refuses.
    # Two consumers of one region must agree on what malformed means.
    # `<!-- CHECKPOINT -->` cannot match `<!-- /CHECKPOINT -->` -- the slash sits
    # where the space would be -- so these two counts are independent.
    CP_OPEN=$(grep -c '<!-- CHECKPOINT -->' "$STATE_FILE" 2>/dev/null | tr -d ' ')
    CP_CLOSE=$(grep -c '<!-- /CHECKPOINT -->' "$STATE_FILE" 2>/dev/null | tr -d ' ')
    if [ "${CP_OPEN:-0}" -gt 0 ] && [ "${CP_CLOSE:-0}" -eq 0 ]; then
        echo "  [!] CHECKPOINT block is not terminated — no <!-- /CHECKPOINT --> marker."
        echo "      Not previewing it: without the closing marker the checkpoint"
        echo "      cannot be told from the narrative, and everything to the end"
        echo "      of the file would be shown as if it were recoverable state."
        echo "      Re-create from .claude/docs/templates/session-state.md."
        echo "  ... ($TOTAL_LINES total lines — read the full file to continue)"
    elif [ -n "$CHECKPOINT" ]; then
        echo "Checkpoint:"
        printf '%s\n' "$CHECKPOINT"
        echo "  ... ($TOTAL_LINES total lines — read the full file for detail)"
    else
        echo "Quick summary (first 20 lines — no CHECKPOINT block in this file):"
        head -20 "$STATE_FILE" 2>/dev/null
        echo "  ... ($TOTAL_LINES total lines — read the full file to continue)"
        echo "  NOTE: re-create from .claude/docs/templates/session-state.md so"
        echo "        recovery reads a bounded checkpoint instead of a slice."
    fi
    # Rotation is an OBSERVATION, never an action: helpers in .claude/scripts/
    # emit observations, never verdicts (CLAUDE.md). The user decides.
    if [ "${TOTAL_LINES:-0}" -gt 200 ] 2>/dev/null; then
        echo "  Note: $TOTAL_LINES lines. Narrative can be rotated into"
        echo "        production/session-logs/ — bash .claude/scripts/rotate-session-state.sh"
    fi
    echo "=== END SESSION STATE PREVIEW ==="
fi

# --- Stack reference ----------------------------------------------------------
# CLAUDE.md imports docs/stack-reference/VERSION.md through one FIXED line that
# nothing rewrites; /setup-stack fills the file behind it. Two things can still
# go wrong, and both are silent from inside a session:
#   1. the import line is gone (a hand edit or a merge) -- every session then
#      runs without the pinned versions and the knowledge-gap warning;
#   2. the file is gone, or was never refreshed -- stack.pinned_on says the
#      stack is pinned, but the `**Stack Pinned**` row still reads
#      NOT DETERMINED, so the reference sessions load is the empty skeleton.
# The configured stack itself is never compared by guessing at names in
# project.yaml: the pin date and the reference's own row are the two facts.
# OBSERVATIONS, never actions (CLAUDE.md): this reports, the user decides.
STACK_REF="docs/stack-reference/VERSION.md"
if [ -f CLAUDE.md ]; then
    if ! grep -qE '^@docs/stack-reference/VERSION\.md[[:space:]]*$' CLAUDE.md 2>/dev/null; then
        echo ""
        echo "!! STACK REFERENCE NOT IMPORTED"
        echo "   CLAUDE.md has no \`@docs/stack-reference/VERSION.md\` line, so sessions load"
        echo "   no pinned stack versions and no knowledge-gap warning."
        echo "   Fix: restore that line under \`## Stack Version Reference\` in CLAUDE.md."
    elif [ ! -f "$STACK_REF" ]; then
        echo ""
        echo "!! STACK REFERENCE MISSING"
        echo "   CLAUDE.md imports $STACK_REF, but the file does not exist."
        echo "   Fix: run /setup-stack (or /setup-stack refresh on a configured project)."
    fi
fi
if [ -f "$STACK_REF" ] && [ -f project.yaml ] \
   && grep -qE '^[[:space:]]+pinned_on:[[:space:]]*[^[:space:]#]' project.yaml 2>/dev/null; then
    # The grep is a cheap superset pre-filter (no interpreter for a project
    # with no pin at all); get_yaml_key confirms the value is stack.pinned_on.
    # Without the helper, the pre-filter's own line is the evidence --
    # `pinned_on` exists only under `stack:` in the schema.
    PINNED_ON=""
    if [ "$YH_LOADED" = true ] && command -v get_yaml_key >/dev/null 2>&1; then
        PINNED_ON=$(get_yaml_key project.yaml stack.pinned_on 2>/dev/null)
    else
        PINNED_ON=$(sed -n 's/^[[:space:]][[:space:]]*pinned_on:[[:space:]]*//p' project.yaml 2>/dev/null \
                    | head -1 | sed 's/[[:space:]]*#.*$//; s/["'"'"']//g; s/[[:space:]]*$//')
    fi
    if [ -n "$PINNED_ON" ] \
       && grep -E '^\|[[:space:]]*\*\*Stack Pinned\*\*[[:space:]]*\|' "$STACK_REF" 2>/dev/null \
          | grep -q 'NOT DETERMINED'; then
        echo ""
        echo "!! STACK REFERENCE NOT REFRESHED"
        echo "   project.yaml stack.pinned_on : $PINNED_ON"
        echo "   $STACK_REF **Stack Pinned** row : NOT DETERMINED"
        echo "   Sessions are loading the empty reference skeleton for a pinned stack."
        echo "   Fix: run /setup-stack refresh"
    fi
fi

echo "==================================="
exit 0
