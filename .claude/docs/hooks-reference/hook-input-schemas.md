# Hook Input/Output Schemas

This documents the JSON payloads each Claude Code hook receives on stdin for every event type.

Every payload also carries the common fields `session_id`, `transcript_path`, `cwd` and `hook_event_name`
(tool events add `permission_mode`). The examples below show the event-specific fields; the hooks in
`.claude/hooks/` read only the fields named in their own header comments.

## PreToolUse

Fired before a tool is executed. Can **allow** (exit 0) or **block** (exit 2).

### PreToolUse: Bash

```json
{
  "tool_name": "Bash",
  "tool_input": {
    "command": "git commit -m 'feat(goals): add savings goal creation' -m 'Story: production/epics/goals-core/story-001-create-goal.md'",
    "description": "Commit changes with message",
    "timeout": 120000
  }
}
```

`validate-commit.sh` and `validate-push.sh` read `tool_input.command`.

### PreToolUse: Write

```json
{
  "tool_name": "Write",
  "tool_input": {
    "file_path": "/Users/dev/moa/apps/api/src/modules/goals/goals.service.ts",
    "content": "import { Injectable } from '@nestjs/common';\n..."
  }
}
```

### PreToolUse: Edit

```json
{
  "tool_name": "Edit",
  "tool_input": {
    "file_path": "/Users/dev/moa/apps/api/src/modules/goals/goals.service.ts",
    "old_string": "const maxActiveGoals = 20;",
    "new_string": "const maxActiveGoals = this.plans.activeGoalLimit(user.plan);"
  }
}
```

### PreToolUse: Read

```json
{
  "tool_name": "Read",
  "tool_input": {
    "file_path": "/Users/dev/moa/apps/api/src/modules/goals/goals.service.ts"
  }
}
```

`file_path` is absolute for Write, Edit and Read. A hook that matches repo-relative patterns
(`validate-data-files.sh` checks `config/**`, `docs/api/**` …) strips the project root first.

## PostToolUse

Fired after a tool completes. **Cannot block** — the tool has already run. Exit 2 feeds stderr back to
Claude as feedback it can act on (`validate-data-files.sh` uses this so Claude fixes a file it just broke);
any other non-zero exit shows stderr to the user only.

### PostToolUse: Write

```json
{
  "tool_name": "Write",
  "tool_input": {
    "file_path": "/Users/dev/moa/config/plans.yaml",
    "content": "schemaVersion: 2\nplans:\n  - id: free\n    activeGoalLimit: 3\n"
  },
  "tool_response": {
    "filePath": "/Users/dev/moa/config/plans.yaml",
    "success": true
  }
}
```

### PostToolUse: Edit

```json
{
  "tool_name": "Edit",
  "tool_input": {
    "file_path": "/Users/dev/moa/config/plans.yaml",
    "old_string": "activeGoalLimit: 3",
    "new_string": "activeGoalLimit: 5"
  },
  "tool_response": {
    "filePath": "/Users/dev/moa/config/plans.yaml",
    "success": true
  }
}
```

`validate-data-files.sh` and `validate-skill-change.sh` read `tool_input.file_path`.

## SubagentStart

Fired when a subagent is spawned via the `Agent` tool (named `Task` before
Claude Code 2.1.63; `Task` still works as an alias in permission rules and
`tools:` frontmatter, but the hook payload's `tool_name` is now `Agent`).

```json
{
  "session_id": "4f1c…",
  "hook_event_name": "SubagentStart",
  "agent_id": "agent-abc123",
  "agent_type": "qa-engineer"
}
```

The agent name is in **`agent_type`**, not `agent_name`. `log-agent.sh` reads `agent_type` and `session_id`;
reading a field that does not exist returns null on every spawn, and the audit trail records nothing useful.

## SubagentStop

Fired when a subagent finishes.

```json
{
  "session_id": "4f1c…",
  "hook_event_name": "SubagentStop",
  "stop_hook_active": false,
  "agent_id": "agent-abc123",
  "agent_type": "qa-engineer"
}
```

`log-agent-stop.sh` reads `agent_type` and `session_id`.

## SessionStart

Fired when a Claude Code session begins. **stdin IS supplied** — a single line of JSON:

```json
{
  "session_id": "4f1c…",
  "transcript_path": "/Users/dev/.claude/projects/…/4f1c….jsonl",
  "cwd": "/Users/dev/moa",
  "hook_event_name": "SessionStart",
  "source": "startup"
}
```

`source` is `startup`, `resume`, `clear` or `compact`. The hook's stdout is added to Claude's context.
`session-start.sh` and `detect-gaps.sh` do not need the payload and must never read stdin unboundedly: the
harness may leave it open, and a blocking read costs the hook its whole timeout on every session start.

## PreCompact

Fired before context window compression. stdin carries the common fields plus `trigger` (`manual` or `auto`)
and `custom_instructions`. `pre-compact.sh` does not read it — it prints the session state so the state
survives summarization.

## Stop

Fired when Claude finishes a response — **every response**, not once per session. **stdin IS supplied**:

```json
{
  "session_id": "4f1c…",
  "transcript_path": "/Users/dev/.claude/projects/…/4f1c….jsonl",
  "hook_event_name": "Stop",
  "stop_hook_active": false
}
```

`session-stop.sh` reads `session_id` — **last**, after the state archive has run, and with a bounded read — so
a stdin read that ever blocked would cost only the spawn tally, never the archive.

## Notification

Fired when Claude Code sends a notification (a permission prompt, an idle wait). stdin carries the common
fields plus `message`; `notify.sh` reads `message`.

## Exit Code Reference

| Exit Code | Meaning | Applicable Events |
|-----------|---------|-------------------|
| 0 | Allow / Success. stdout is added to Claude's context for SessionStart; for other events it appears in the transcript only | All events |
| 2 | PreToolUse: block the tool call, stderr shown to Claude. PostToolUse: stderr fed back to Claude (the tool already ran). Stop / SubagentStop: prevents stopping — never used by this framework's hooks | PreToolUse, PostToolUse (feedback) |
| Other | Treated as a non-blocking error: stderr shown to the user, the tool proceeds | All events |

## Notes

- Hooks receive JSON on **stdin** (pipe). Use `INPUT=$(cat)` to capture — except in SessionStart and Stop
  hooks, where the read must be bounded or skipped (see above).
- Parse with `jq` if available, fall back to `grep` for cross-platform compatibility.
- On Windows, `grep -P` (Perl regex) is often unavailable. Use `grep -E` (POSIX extended) instead.
- Path separators may be `\` on Windows. Normalize with `sed 's|\\\\|/|g; s|\\|/|g'` when comparing paths — two
  rules, because the `grep` fallback cannot unescape the JSON-escaped `\\` (see `validate-skill-change.sh`).
