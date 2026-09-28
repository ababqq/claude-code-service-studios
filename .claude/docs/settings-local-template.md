# settings.local.json Template

Create `settings.local.json` next to `.claude/settings.json` for personal Claude
Code overrides that should NOT be committed. It is already gitignored (the
`# === Claude Code Local ===` block of `.gitignore`).

This file is Claude Code's own permission and hook configuration. It is **not**
`project.local.yaml`, which holds your personal CCSS settings (`modes.automation`,
`modes.review_mode`, …) and is written with `/settings --local`.

## Example settings.local.json

```json
{
  "permissions": {
    "allow": [
      "Bash(pnpm install*)",
      "Bash(pnpm --filter web dev*)",
      "Bash(pnpm test*)",
      "Bash(pnpm run lint*)",
      "Bash(npm run test*)",
      "Bash(pytest*)",
      "Bash(docker compose up*)",
      "Bash(docker compose down)",
      "Bash(vercel deploy)"
    ],
    "deny": [
      "Bash(git push --force*)",
      "Bash(npm publish*)"
    ]
  }
}
```

The shared `.claude/settings.json` already allows the common read-only and local
test commands (`pnpm test`, `npm test`, `pytest`, `./gradlew test`, `flutter test`,
`go test`, the lint and typecheck scripts). Add here only what *you* run often —
dependency installs, your dev server, local containers.

### Preview deploys yes, production deploys never

You may allow the CLI that deploys a **preview** environment — typically the exact
command recorded in `commands.deploy_preview` of `project.yaml` (for example
`vercel deploy`, or `netlify deploy` without `--prod`). Production deploys, IaC
apply, cluster changes, store submissions and destructive database commands stay
denied by the shared `.claude/settings.json` (`vercel --prod`, `terraform apply`,
`kubectl apply`, `eas submit`, `prisma migrate reset`, `DROP TABLE`, …). Permission
rules from every settings file are combined and deny rules are checked first, so a
local allow cannot re-open a shared deny — by design: agents propose production
commands, and a human runs them.

**Keep preview allows exact.** A trailing `*` matches anything after the prefix, so
`Bash(vercel deploy*)` would also match `vercel deploy --prebuilt --prod`, which the
shared deny rule (a prefix match on `vercel deploy --prod`) does not catch. Allow
the exact preview command you use, with no trailing wildcard.

### Optional: read-only Figma MCP tools

When the project designs in Figma (`design.tool: figma`) and you have the Figma MCP
server installed, `/design-handoff` reads frames through it and each call prompts in
`default` mode. You may allow the **read-only** tools here to stop those prompts.
MCP tool names are `mcp__<server>__<tool>` and the server name is whatever **your**
install registered, so copy the exact names from your session (`/mcp` lists them) —
the names below are an example, not a contract:

```json
{
  "permissions": {
    "allow": [
      "mcp__figma__get_design_context",
      "mcp__figma__get_screenshot",
      "mcp__figma__get_metadata",
      "mcp__figma__get_variable_defs",
      "mcp__figma__get_code_connect_map",
      "mcp__figma__search_design_system"
    ]
  }
}
```

Never allow the Figma **write** tools (`use_figma`, `create_new_file`, Code Connect
writes, asset uploads): a write to Figma changes shared external state and is always
proposed and approved per call. Keep every MCP entry out of the shared
`.claude/settings.json` — tool names vary per install, and the shared file would
pre-approve a name that means nothing (or something else) on a teammate's machine.

## Permission Modes

Claude Code supports different permission modes (`permissions.defaultMode`, or
switched in the session). Recommended for service development:

### During Development (Default)
Use **`default`** — Claude asks before running most commands and before editing
files. This is the safest mode for production code, and it is what the shared
`.claude/settings.json` sets.

### During Prototyping
Use **`acceptEdits`** with limited scope — faster iteration on throwaway code.
Only use this while working in `prototypes/`, which never ships to production.

### During Code Review and Planning
Use **`plan`** — Claude can read and search but not modify files or run
state-changing commands.

Never run with permission checks bypassed on a machine that holds production
credentials, cloud admin sessions or store signing keys.

## Customizing Hooks Locally

You can add personal hooks in `settings.local.json` that extend (not override)
the project hooks. For example, printing a timestamp when a session ends:

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash -c 'echo Session ended at $(date)'",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

Keep personal hooks fast and side-effect free: they run on every matching event,
alongside the project hooks registered in `.claude/settings.json`.
