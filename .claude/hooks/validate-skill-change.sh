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

# Claude Code PostToolUse hook: Advises running /skill-test after a skill or an
# agent definition changes.
#   .claude/skills/<name>/...   -> /skill-test static <name>  (structural lint)
#   .claude/agents/<name>.md    -> /skill-test spec <name>    (behavioural spec)
#
# Exit behavior:
#   exit 0 = advisory only (non-blocking)
#
# Input schema (PostToolUse for Write|Edit):
# { "tool_name": "Write", "tool_input": { "file_path": "...", "content": "..." } }

INPUT=$(cat)

# Parse file path -- use jq if available, fall back to grep
if command -v jq >/dev/null 2>&1; then
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
else
    FILE_PATH=$(echo "$INPUT" | grep -oE '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/"file_path"[[:space:]]*:[[:space:]]*"//;s/"$//')
fi

# Normalize path separators (Windows backslash to forward slash).
#
# TWO rules, and the order matters. The hook input is JSON, so a Windows path
# arrives escaped: "C:\\Users\\x". jq unescapes it to a single backslash, but
# the grep fallback CANNOT -- it hands back the raw two-character `\\`. A
# single `s|\\|/|g` then turns each of those into its own slash, producing
# `.claude//skills//help//SKILL.md`, which no path test below matches. The hook
# went silent on every Windows edit whenever jq was absent -- and jq is absent
# on a stock Windows Git Bash, one of the supported platforms.
#
# Rule 1 collapses the escaped pair to one slash; rule 2 handles an already
# unescaped separator (the jq path, or a POSIX caller). Running both is safe
# for either input because rule 1 finds nothing to do on unescaped text.
FILE_PATH=$(printf '%s' "$FILE_PATH" | sed 's|\\\\|/|g; s|\\|/|g')

# Agent definitions: .claude/agents/<name>.md (top level only -- agent memory
# lives in .claude/agent-memory/, which is not an agent definition).
if echo "$FILE_PATH" | grep -qE '(^|/)\.claude/agents/[^/]+\.md$'; then
    AGENT_NAME=$(echo "$FILE_PATH" | grep -oE '\.claude/agents/[^/]+\.md$' | sed 's|\.claude/agents/||; s|\.md$||')
    [ -z "$AGENT_NAME" ] && exit 0
    echo "=== Agent Modified: $AGENT_NAME ===" >&2
    echo "Run /skill-test spec $AGENT_NAME to check the agent against its behavioural spec." >&2
    echo "====================================" >&2
    exit 0
fi

# Only act on files inside .claude/skills/
if ! echo "$FILE_PATH" | grep -qE '(^|/)\.claude/skills/'; then
    exit 0
fi

# Extract skill name from path (.claude/skills/[skill-name]/SKILL.md)
SKILL_NAME=$(echo "$FILE_PATH" | grep -oE '\.claude/skills/[^/]+' | sed 's|\.claude/skills/||')

if [ -z "$SKILL_NAME" ]; then
    exit 0
fi

echo "=== Skill Modified: $SKILL_NAME ===" >&2
echo "Run /skill-test static $SKILL_NAME to validate structural compliance." >&2
echo "====================================" >&2

exit 0
