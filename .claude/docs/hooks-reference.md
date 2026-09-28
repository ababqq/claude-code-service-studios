# Active Hooks

Hooks are configured in `.claude/settings.json` and fire automatically. The table lists every file in
`.claude/hooks/`: the registered hooks, the one opt-in hook that ships unregistered, and the config library the
others source.

| Hook | Event | Trigger | Action | Blocking |
| ---- | ----- | ------- | ------ | -------- |
| `session-start.sh` | SessionStart | Session begins | Prints the `Claude Code Service Studios` banner, branch and recent commits, the resolved `review_mode` (via yaml-helper; `review_mode: unknown (yaml-helper unavailable)` when it cannot resolve — never a hard-coded fallback), `project.yaml` enum and scope errors, the stage from `stage-estimate.sh --quick`, the current sprint, the active milestone (newest `production/milestones/*.md`, excluding `*-review.md`), the count of unresolved bugs, a TODO/FIXME count across the resolved code roots plus the undeclared-roots warning, the stack reference check (`@docs/stack-reference/VERSION.md`), and a preview of the session-state checkpoint for recovery | no |
| `detect-gaps.sh` | SessionStart | Session begins | Detects a fresh project (suggests `/start`) and gaps once work exists: code with sparse PRDs (`/reverse-document prd`), concept or spike prototypes without `REPORT.md` / `SPIKE-NOTE.md` (`/prototype report`), imported designs — `design/handoff/<slug>/` directories — without `HANDOFF.md` (Check 7, not tier-aware: `⚠️  GAP: N imported design(s) without a record (no HANDOFF.md):`, one `- design/handoff/<slug>/` line per directory, then `Suggested action: /design-handoff --for <slug>`), code roots without ADRs (`/reverse-document architecture`), a backend without an API contract (`/api-design`), migrations without `docs/data/data-model.md` (`/data-model`), a recorded stage lagging the tree (`/gate-check`). Tier-aware; an unresolved code root prints `NOT CHECKED` lines | no |
| `validate-commit.sh` | PreToolUse (Bash) | `git commit`, alone or chained after other commands | **Blocks** unparseable JSON/YAML config, API contracts, locales, registries, CI workflows and `project.yaml`; secrets in added lines; credential files. **Warns** on Firebase client configs, PRD sections missing for the PRD's tier, hardcoded business values and URL hosts in code, TODOs without an owner, and commit messages that are not Conventional Commits or carry no story/task ID. Details below | JSON/YAML, secrets, credential files |
| `validate-push.sh` | PreToolUse (Bash) | `git push` commands | Warns on pushes to `main`, `master`, `develop`, `release/*`, `production`, `prod`; reminds you to confirm the migration plan's phase when the pushed commits touch `stack.layers.data.migrations_dir` | no — the block path ships commented out |
| `validate-data-files.sh` | PostToolUse (Write/Edit) | Write/Edit of a JSON/YAML file on the `validate-commit.sh` data-file list | Parses the file right after the write with the same rule as `validate-commit.sh`; prints `Invalid <JSON\|YAML> in <path>: <error>` on failure. No naming rules | feedback — exit 2 routes the error to Claude (the write already happened) |
| `validate-skill-change.sh` | PostToolUse (Write/Edit) | Skill or agent file changes | `.claude/skills/<name>/…` → advises `/skill-test static <name>`; `.claude/agents/<name>.md` → advises `/skill-test spec <name>` | no |
| `notify.sh` | Notification | Notification event | Desktop notification: Windows toast via PowerShell, macOS `osascript`, Linux `notify-send` when available; a silent no-op elsewhere | no |
| `pre-compact.sh` | PreCompact | Context compression | Dumps session state (`active.md`, modified files, work-in-progress docs under `design/prd/`, `design/product/`, `docs/architecture/`, `docs/api/`, `docs/data/`) into the conversation before compaction so it survives summarization | no |
| `post-compact.sh` | PostCompact | After compaction | Reminds Claude to restore session state from the `active.md` checkpoint | no |
| `session-stop.sh` | Stop | **Every response ends** — not once per session | Summarizes accomplishments, updates the session log, and writes the subagent spawn tally to `production/session-logs/session-cost.md`. Archives `active.md` only when its content hash changed; without that guard a long session appended the whole file on every turn | no |
| `log-agent.sh` | SubagentStart | Agent spawned | Audit trail start — logs the subagent invocation with timestamp and session id | no |
| `log-agent-stop.sh` | SubagentStop | Agent stops | Audit trail stop — completes the subagent record | no |
| `log-instructions.sh` | InstructionsLoaded | **Opt-in — not registered** | Records which `CLAUDE.md` or rules file loaded and why — for example whether `.claude/rules/domain-logic.md` actually reaches the model while it works in `apps/api/src/modules/**`. Wire it in your own `.claude/settings.local.json` when you need the answer | no |
| `yaml-helper.sh` | — (library) | Sourced by the hooks above; executed directly by skill bootstraps (`resolve_config` only) | The config engine: resolution chain (`project.local.yaml` → `project.yaml` → `modes.rigor` → default), enum validation, code roots (`resolve_code_roots`, `list_code_files`, `code_extensions`), specialist routing | — |

Blocking hooks exit 2 with the reason on stderr; Claude sees it and can fix the cause. Every other finding is
advisory and exits 0. A check that cannot run says so (`NOT CHECKED: …` / `SKIPPED: …`) — obligation 3 of
`.claude/rules/skill-authoring.md` — so a skipped check never reads as a clean one.

## `validate-commit.sh` in detail

It runs only when the Bash command contains `git commit` — on its own or chained (`pnpm test && git commit …`).
The checked set is the index, plus tracked working-tree changes when the commit uses `-a` / `--all`. Files
staged by a `git add` **in the same command** are staged only after the hook has run, so the hook prints a
`NOT CHECKED` line for them: stage in one command, commit in the next.

**Blocks (exit 2)**

| Check | Scope | Rule |
| ----- | ----- | ---- |
| Data files parse | `config/**`, `docs/api/**`, `**/locales/**`, `**/i18n/**`, `design/registry/*.yaml`, `docs/registry/*.yaml`, `docs/architecture/tr-registry.yaml`, `.github/workflows/*`, `project.yaml` — JSON and YAML files | JSON via the Python standard library. YAML via PyYAML when importable (local tags such as `!Ref` are accepted); otherwise a standard-library structural check — no tab indentation; brackets `[]` / `{}` and quotes balanced (a quote opens a quoted scalar only at the start of a value; `"` is counted only outside single-quoted scalars and `'` only outside double-quoted ones; a flow collection, quoted string or plain scalar may continue on the next lines, but must close); every other line a `key: value` entry or a `- ` list item; block-scalar bodies skipped — the lines after a value of `\|` or `>` (optionally followed by `+`, `-` or an indentation digit, as in `run: \|`), up to the next non-blank line indented at or left of that key — plus the line `NOT CHECKED: full YAML parse (PyYAML unavailable)`. A structural failure blocks; a missing PyYAML never does. `tsconfig*.json` / `jsconfig*.json` are JSON with comments and are skipped |
| Secrets | added lines of the staged diff | AWS access key IDs, private-key headers, GitHub tokens, Slack tokens, Google API keys, Stripe live secret keys. A token ending in `EXAMPLE` (`AKIAIOSFODNN7EXAMPLE`) or a line carrying `pragma: allowlist secret` is ignored. The report names the file, line and kind, never the full value |
| Credential files | staged paths | `.env` and `.env.*` (except `.env.example`), `*.keystore`, `*.jks`, `*.p12`, `*.mobileprovision`, and `*.pem` files that hold a private key (a public certificate is fine) |

**Warns (exit 0)**

| Check | Rule |
| ----- | ---- |
| Firebase client config | `google-services.json` / `GoogleService-Info.plist` staged — restrict the key; decide deliberately whether it belongs in the repository |
| PRD sections | Staged `design/prd/<feature>.md` (never `design/prd/reviews/`) against the sections its tier requires — the project `modes.workflow`, or the PRD's `workflow_overrides.feature_overrides.<feature>` entry. `full`: all eleven sections of `.claude/docs/templates/prd.md`; `standard`: the eight required ones; `minimal`: none (a note says so). Same heading match as `.claude/scripts/prd-structure-check.sh`. Tier unresolved ⇒ `NOT CHECKED: PRD sections (workflow tier unresolved)` — there is no fallback tier |
| Hardcoded business values | `price`, `amount`, `fee`, `limit`, `quota`, `timeout`, `ttl`, `max_*` assigned a number, in application code under the resolved code roots — tests, fixtures, seeds, stories, framework config files, migrations and IaC excluded |
| Absolute URL hosts | `http(s)://<host>` in the same files, outside comment lines; `localhost`, reserved example domains and namespace URIs (`w3.org`, `schema.org`) excluded |
| TODO owners | `TODO` / `FIXME` / `HACK` without the `TODO(owner)` form, in any file under the code roots |
| Code roots | An undeclared workspace package in the commit prints `WARN: undeclared code roots: <dirs> — declare them with /setup-stack`; no code root resolved while code is staged prints a `SKIPPED:` note naming `/setup-stack` |
| Commit message | Read from `-m` / `--message` (including the `-m "$(cat <<'EOF' … EOF)"` form). Subject must match Conventional Commits — `feat`, `fix`, `chore`, `docs`, `test`, `refactor`, `perf`, `build`, `ci`, `revert`, optional scope and `!`; the message must carry a story/task ID line (`Story: production/epics/…`, `Task:`, `Refs:`, a `TR-`, `BUG-` or `INC-` ID, a tracker key). Any other message source prints `NOT CHECKED: commit message (not passed with -m)` |

**YAML parser.** PyYAML is optional. Without it every YAML check is the structural one; install it
(`python3 -m pip install pyyaml`) for a full parse. `CCSS_YAML_PARSER=stdlib` forces the structural check, which
is how the fallback is tested on a machine that has PyYAML.

## `validate-data-files.sh` in detail

The PostToolUse twin of the data-file block: the same path list and the same parse program (kept byte-identical
in both scripts), run right after each Write/Edit so Claude fixes a broken file before it ever reaches a commit.
Write and Edit pass absolute paths; the hook resolves them against the project root and ignores files outside
it. It has no naming rules — file names follow `naming.files` and the stack's own conventions.

## Subagent cost visibility

`log-agent.sh`, `log-agent-stop.sh` and `session-stop.sh` form one chain. `log-agent.sh` writes a record per
spawn to `production/session-logs/agent-audit.log` in a fixed three-field shape:

```
YYYYMMDD_HHMMSS | <session_id> | Agent invoked: <agent_type>
```

`session-stop.sh` greps the literal string `" | $SESSION_ID | Agent invoked: "`
to tally the current session, then writes a count plus a per-agent breakdown to
`production/session-logs/session-cost.md` and echoes a one-line total.

Three constraints that must not be "tidied" later:

- **The field order is load-bearing.** Nothing else parses this log, so a
  reformat looks free — but it silently zeroes the spawn count rather than
  erroring.
- **`session-stop.sh` reads stdin last, on purpose.** Everything above the
  tally block (notably archiving `active.md`) runs first, so a stdin read that
  ever blocked would cost only the count, not the state archive.
- **No session id means no number.** The hook prints nothing rather than a
  total spanning every session in the log. Silence here is correct; a
  plausible-but-wrong cost figure is worse than none.

`agent_type` — not `agent_name` — is the field carrying the agent name. See
`hooks-reference/hook-input-schemas.md`.

## Optional git-hook recipes (not registered)

The hooks above guard what Claude runs. The recipes in `.claude/docs/hooks-reference/` are **git** hooks and
workflow hooks a team installs itself (plain `.git/hooks/`, lefthook or husky) so the same guardrails cover
every contributor's commits and pushes. None of them is wired by default.

| Recipe | Git event | What it does |
| ------ | --------- | ------------ |
| `hooks-reference/pre-commit-code-quality.md` | pre-commit | Linters, formatters and the type check per stack (ESLint, Prettier, `tsc`, Ruff, ktlint, SwiftLint), commands read from `commands.lint` / `commands.typecheck`, plus a secret scan |
| `hooks-reference/pre-commit-prd-check.md` | pre-commit | Staged PRDs against their tier's required sections via `prd-structure-check.sh` — warn only, mirrors `validate-commit.sh` |
| `hooks-reference/pre-push-test-gate.md` | pre-push | Unit, integration, contract and E2E suites via `commands.test` / `commands.e2e` before shared branches; migration dry-run reminder |
| `hooks-reference/post-merge-bundle-budget.md` | post-merge | Web JavaScript chunk sizes against `performance.bundle_kb`, mobile release artifacts by size — observations only; `/bundle-audit` gives the per-route verdict |
| `hooks-reference/post-sprint-retrospective.md` | workflow (end of sprint) | A retrospective starter from sprint data via `delivery-manager` and `/retrospective` |

## Events considered and deliberately not added

Claude Code offers many more hook events than the ones registered above. These were
evaluated and rejected. Recorded so a future review does not re-propose them
from the event list alone.

| Event | Why not |
| ---- | ---- |
| `UserPromptSubmit` | Would re-inject session state on **every prompt**. `.claude/docs/config-resolution.md` already rejects the weaker version of this — injecting config at session start — because it "would cost tokens on every session whether or not any skill needs config, and it would go stale mid-session as `/settings` writes land". Firing per prompt is the same argument, multiplied. |
| `ConfigChange` | Fires only for Claude Code's own settings files — user, project, local, policy and skills. It does **not** fire for `project.yaml`, so a hook watching CCSS config here would never run. `FileChanged` is the event that watches arbitrary files. |
| `FileChanged` on `project.yaml` | Config is resolved per skill invocation, in the skill body, precisely so each run reads fresh values. The only staleness left is text already injected into an earlier invocation, which is the accepted trade in `config-resolution.md`. A warning hook would second-guess a settled decision. |
| `PreToolUse` `updatedInput` | Could rewrite a non-conventional commit message instead of warning about it. Silently editing the user's input contradicts the collaboration protocol: this project blocks or warns and explains rather than acting unasked. |
| `PostToolUseFailure` | Would add another log with no reader. This repo has already been bitten by that — `log-agent.sh` wrote per-spawn records nothing consumed until `session-stop.sh` was given the job. |
| `SessionEnd` | `session-stop.sh` stays on `Stop`. `SessionEnd` fires on termination, which a crash may never reach, and the content-hash guard already makes the per-response firing cheap. |
| `InstructionsLoaded` | Useful for debugging which CLAUDE.md and rules files actually loaded, but it is a diagnostic, not a project requirement. `log-instructions.sh` ships for it, unregistered: wire it in your own `.claude/settings.local.json` when you need it rather than paying for it on every load. |

Hook reference documentation: `.claude/docs/hooks-reference/`
Hook input schema documentation: `.claude/docs/hooks-reference/hook-input-schemas.md`
