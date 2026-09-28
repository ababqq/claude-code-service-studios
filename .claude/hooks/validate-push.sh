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

# Claude Code PreToolUse hook: Validates git push commands
#   - Warns on pushes to shared branches: main, master, develop, release/*,
#     production, prod
#   - Reminds once when the pushed commits touch the data layer's migrations
#     directory (stack.layers.data.migrations_dir), so the migration plan's
#     expand/contract phase is confirmed before it reaches a shared branch
# Exit 0 = allow, Exit 2 = block (the block path below is commented out: pushes
# are warned about, never stopped, unless a team opts in)
#
# Input schema (PreToolUse for Bash):
# { "tool_name": "Bash", "tool_input": { "command": "git push origin main" } }

INPUT=$(cat)

# Parse command -- use jq if available, fall back to grep
if command -v jq >/dev/null 2>&1; then
    COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
else
    COMMAND=$(echo "$INPUT" | grep -oE '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/"command"[[:space:]]*:[[:space:]]*"//;s/"$//')
fi

# Only process git push commands -- as the whole command or as one segment of a
# chained one (`pnpm test && git push`).
if ! printf '%s\n' "$COMMAND" | grep -qE '(^|[;&|(])[[:space:]]*git[[:space:]]+push([[:space:]]|$)'; then
    exit 0
fi

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

_is_protected() {
    case "$1" in
        main|master|develop|production|prod|release/*) return 0 ;;
    esac
    return 1
}

# The push arguments: the words after `git push` on the line that carries it, up
# to the next command separator. Options are skipped (those that take a value
# consume it); the first remaining word is the remote, the rest are refspecs.
PUSH_ARGS=$(printf '%s\n' "$COMMAND" \
    | grep -E '(^|[;&|(])[[:space:]]*git[[:space:]]+push([[:space:]]|$)' | head -1 \
    | sed -E 's/.*git[[:space:]]+push//; s/[;&|)].*//')

REMOTE=""
SOURCES=""
TARGETS=""
ALL_BRANCHES=0
_skip_next=0
for _w in $PUSH_ARGS; do
    if [ "$_skip_next" = 1 ]; then _skip_next=0; continue; fi
    case "$_w" in
        --all|--mirror) ALL_BRANCHES=1; continue ;;
        -o|--push-option|--repo|--receive-pack|--exec) _skip_next=1; continue ;;
        -*) continue ;;
    esac
    if [ -z "$REMOTE" ]; then REMOTE="$_w"; continue; fi
    _spec="${_w#+}"
    case "$_spec" in
        *:*) _src="${_spec%%:*}"; _dst="${_spec#*:}" ;;
        *)   _src="$_spec";       _dst="$_spec" ;;
    esac
    [ "$_src" = "HEAD" ] && _src="$CURRENT_BRANCH"
    [ "$_dst" = "HEAD" ] && _dst="$CURRENT_BRANCH"
    _dst="${_dst#refs/heads/}"
    [ -n "$_src" ] && SOURCES="$SOURCES $_src"
    [ -n "$_dst" ] && TARGETS="$TARGETS $_dst"
done
# No refspec: git pushes the current branch (push.default simple/upstream).
if [ -z "$TARGETS" ] && [ "$ALL_BRANCHES" = 0 ]; then
    TARGETS="$CURRENT_BRANCH"
    SOURCES="HEAD"
fi

MATCHED_BRANCH=""
for _t in $TARGETS; do
    if _is_protected "$_t"; then MATCHED_BRANCH="$_t"; break; fi
done
[ "$ALL_BRANCHES" = 1 ] && [ -z "$MATCHED_BRANCH" ] && MATCHED_BRANCH="(every local branch -- --all/--mirror)"

if [ -n "$MATCHED_BRANCH" ]; then
    echo "Push to shared branch '$MATCHED_BRANCH' detected." >&2
    echo "Reminder: CI green (tests, lint, typecheck), no unresolved S1-Critical or S2-Major bugs, and a rollback path (feature flag or revert) for anything users will see." >&2
    # Allow the push but warn -- uncomment below to block instead:
    # echo "BLOCKED: Open a pull request instead of pushing to $MATCHED_BRANCH" >&2
    # exit 2
fi

# --- migrations in the pushed range ------------------------------------------------
# The pushed range = commits reachable from each pushed source ref that no
# remote-tracking branch has yet. Silent when the project declares no data
# layer migrations directory: there is nothing to remind about.
if [ -f .claude/hooks/yaml-helper.sh ] && [ -f project.yaml ]; then
    . .claude/hooks/yaml-helper.sh 2>/dev/null || true
    MIGRATIONS_DIR=""
    if command -v get_yaml_key >/dev/null 2>&1; then
        MIGRATIONS_DIR=$(get_yaml_key project.yaml stack.layers.data.migrations_dir 2>/dev/null)
        MIGRATIONS_DIR="${MIGRATIONS_DIR#./}"
        MIGRATIONS_DIR="${MIGRATIONS_DIR%/}"
    fi
    if [ -n "$MIGRATIONS_DIR" ]; then
        [ "$ALL_BRANCHES" = 1 ] && SOURCES="$SOURCES --branches"
        [ -z "$SOURCES" ] && SOURCES="HEAD"
        # shellcheck disable=SC2086  # SOURCES is a word list of refs
        if git log --format= --name-only $SOURCES --not --remotes 2>/dev/null \
            | head -n 5000 | awk -v d="$MIGRATIONS_DIR/" 'index($0, d) == 1 { f = 1 } END { exit !f }'; then
            echo "Reminder: this push includes database migrations under $MIGRATIONS_DIR/ -- confirm the migration plan's phase (docs/data/migrations/: expand, backfill or contract) before it reaches a shared branch." >&2
        fi
    fi
fi

exit 0
