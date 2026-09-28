---
name: team-release
description: "Execute the release train and rollout plan; record every stage."
argument-hint: "[version | next] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, Agent, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskUpdate, Bash(bash "*/.claude/skills/team-release/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,automation_always_ask,team.size,distribution`

Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**Argument check:** If no version number is provided:
1. Read `project.version` in `project.yaml`, `production/session-state/active.md` and the most recent file in `production/milestones/` (if they exist) to infer the target version. Also Glob `production/releases/*/release-record.md` for a record whose verdict line is still `NOT ASSESSED` — an unfinished release to resume.
2. If a version is found: report "No version argument provided — inferred [version] from [source]. Proceeding." Then confirm with `AskUserQuestion`: "Releasing [version]. Is this correct?"
3. If no version is discoverable: use `AskUserQuestion` to ask "What version should be released? (SemVer, e.g. 1.4.0)" and wait for user input before proceeding. Do NOT default to a hardcoded version string.

`next` means the version after the latest `COMPLETED` release record: propose MAJOR for a
breaking change, MINOR for new features, PATCH for fixes only — from the
`## [Unreleased]` entries of `docs/CHANGELOG.md` — and confirm it with the user.

**Resuming.** Rollouts outlast sessions — an App Store phased release alone runs for
seven days. If `production/releases/<version>/release-record.md` exists with
`> **Verdict**: NOT ASSESSED`, read it and resume where it stopped — in Phase 6, at the
first row of `## Rollout Stages` without a recorded decision; before Phase 6, at the
first phase whose section is still empty. Do not repeat completed phases, unless the
release candidate changed since they ran (then Phases 2–5 run again). A record with a final
verdict (`COMPLETED`, `HALTED`, `ROLLED BACK`) is closed: shipping again means a new
version (e.g. `1.4.1`) — ask.

When this skill is invoked, orchestrate the release team through a structured pipeline.
It **executes** a release that has already been prepared: the release checklist
(`/release-checklist`) says the candidate is ready, the rollout plan (`/rollout-plan`)
says how it is exposed to users stage by stage, and this skill walks those stages with
the team and records each one in `production/releases/<version>/release-record.md`.
**It never runs a deploy command itself.** Every deploy, promotion, store submission,
migration run and production flag change is prepared as exact commands or console
steps for a human, who runs them and reports the result.

Track the phases and the rollout stages with `TaskCreate` / `TaskUpdate`, so
`TaskList` shows where the release stands when a session resumes.

**Decision Points:** At each phase transition, use `AskUserQuestion` to present
the user with the subagent's proposals as selectable options. Write the agent's
full analysis in conversation, then capture the decision with concise labels.
In `collaborative` mode, the user must approve before moving to the next phase.
In `guided` mode the pipeline advances automatically unless a phase is BLOCKED;
in `autonomous` mode it runs end to end, recording each phase outcome via
`log_decision`. Decisions in `automation_always_ask` categories (the resolved
list is in the block above, label `automation_always_ask`; hooks use the
`is_always_ask_category` helper) always prompt regardless of mode. See
`.claude/docs/automation-modes.md`.

**Deploy stages always prompt.** Every rollout stage is a `production_deploys`
decision: it prompts at every automation mode, including `autonomous`. This skill
does not let a narrowed `automation_always_ask` list skip it — if the resolved list
omits `production_deploys`, say so in the Phase 0 announcement and prompt anyway.
A stage that runs a migration is also `db_migrations`; one that changes DNS, CDN,
scaling or other infrastructure is also `infra_changes`. Changing `project.version`
is a `version_bumps` decision, and this skill asks before writing it at every mode.

## Phase 0: Resolve Config

Use the values resolved in the block at the top of this skill.

`review_mode` sets gate depth:
- `full` — spawn all director and lead gates as described
- `lean` → **skip every gate whose ID does not end in `-PHASE-GATE`**. Note: `[GATE-ID] skipped — Lean mode`
- `solo` — skip all gates, note `[GATE-ID] skipped — Solo mode`

Unset on an unconfigured project: `modes.rigor` defaults to `minimal`, which resolves `review_mode` to `solo`.

This skill's gate list is empty — it spawns no director or lead gate at any review
mode, so the pipeline below runs the same in `full`, `lean` and `solo`. The production
readiness review belongs to `/rollout-plan`, which runs it at every review mode; Phase 1
reads the verdict that plan recorded instead of re-running it.

`automation` drives the Decision Points note above. See the Decision Points note above and
`.claude/docs/automation-modes.md` for how each mode changes pipeline behavior.

**`release.distribution`** decides which tracks the rollout walks: `web` — web and API
deploys, flags and canaries; `stores` — App Store and Google Play submission, phased
and staged rollout; `web+stores` — both; `enterprise` — private distribution (Apple
Business Manager custom app, Managed Google Play, customer-hosted or single-tenant
deploys) with each customer's change window; `internal` — internal tracks only.
**Unset ⇒ ask how this release ships** before Phase 1; never walk every track.

**`team.size`**: which agents are active (orthogonal to review_mode gate-depth and workflow docs).
- **`individual`** (what `modes.rigor` `minimal` and `standard` resolve to): `release-manager` only. Other agents consulted via the release-manager, not spawned separately.
- **`small`**: + `qa-lead` + `devops-engineer` + `sre-engineer` — the documented pipeline release-manager → qa-lead → devops-engineer → sre-engineer.
- **`studio`** (what `modes.rigor: full` resolves to): + `security-engineer` + `customer-success-manager` + `localization-lead` + `delivery-manager` + `analytics-engineer`.
Team skills spawn only the gates `.claude/docs/director-gates.md` § Gate Index lists this skill under (Spawned by column), after the review-mode check (lean suffix rule); team-size scoping never removes a director gate. A non-core agent needed at `individual` routes through the nearest active core agent with an informational note. **"Phase gate" means any phase that ends in an `AskUserQuestion` decision point before the pipeline advances** — not every phase. Apply the test literally: if the phase below has no decision point, it is not a gate, and an agent restricted to "phase gates only" is not spawned for it. This active-set scoping applies throughout the pipeline below: any phase that names an agent outside the active set routes through the nearest core agent rather than spawning it.

**Announce the active set before Phase 1 — never let the collapse be silent.**
Before spawning anything, state in one line which agents this run will actually
spawn, and which the pipeline below names but will **not** spawn at the resolved
`team.size`. For example:

> `Active set (team.size: <resolved>): <the agents listed for that size above>.`
> `Not spawned this run: <every other agent this pipeline names> — consulted`
> `through <nearest active core agent>. Raise team.size (or modes.rigor) to widen.`

Fill it from the `team.size` list directly above and the agents this file's own
pipeline names — not from an example. Both sets differ per orchestrator.

The pipeline below reads as a multi-agent fan-out and at the narrowest size it is one
agent — this skill names nine and, at `individual`, runs `release-manager` alone.
**The collapse is correct**: `team.size` is rigor-fronted and the narrow default is the
token lever, measured at roughly 10x. What was wrong is that nothing said so, so a
reader could not distinguish a correctly-collapsed run from a broken pipeline, and the
per-agent "routes through the nearest core agent with an informational note" rule above
fires at routing time and never states the shape of the run as a whole.

This is the same rule as the skipped-check reporting elsewhere in this file: **a constraint that is enforced but never surfaced is
indistinguishable, to the person reading the output, from one that was never
enforced.**

## Team Composition
- **release-manager** — Release scope, versioning, release candidate, stage-by-stage rollout execution, store submissions, the content of the release record
- **qa-lead** — Release quality gate: smoke check on the release candidate, QA sign-off, unresolved bugs, regression watch after release
- **devops-engineer** — Release artifacts and pipeline; deploy, promote and rollback commands prepared for a human
- **sre-engineer** — Guardrail metrics and halt thresholds at every stage, dashboards and alerts, on-call coverage, capacity
- **security-engineer** — Pre-release security posture: open audit findings, secrets, dependency advisories (invoke when the release changes sign-in, payments or personal data)
- **customer-success-manager** — Customer communication: status page and in-app notices, support briefing and macros for known issues, app-review replies
- **localization-lead** — Every shipping locale complete: strings, release notes, store text, notification templates
- **delivery-manager** — Go/no-go facilitation, milestone tracking, stakeholder communication
- **analytics-engineer** — Tracking events of the shipped PRDs verified; guardrail and business-KPI dashboards live

## How to Delegate

Use the `Agent` tool to spawn each team member as a subagent:
- `subagent_type: release-manager` — Release scope, versioning, release candidate, rollout execution, store submissions
- `subagent_type: qa-lead` — Smoke check on the candidate, QA sign-off, unresolved bugs, regression watch
- `subagent_type: devops-engineer` — Artifacts, pipeline, deploy and rollback commands for a human
- `subagent_type: sre-engineer` — Guardrails and halt thresholds per stage, dashboards, on-call, capacity
- `subagent_type: security-engineer` — Security posture for releases touching sign-in, payments or personal data
- `subagent_type: customer-success-manager` — Customer communication and support readiness
- `subagent_type: localization-lead` — Locale completeness of strings, notes, store text and templates
- `subagent_type: delivery-manager` — Go/no-go facilitation and stakeholder communication
- `subagent_type: analytics-engineer` — Tracking and dashboard verification

**Brief each agent — do not dump context.** Read the shared inputs **once** and pass a distilled brief inline: the lines each agent actually needs, never a file path for a document you have already read (an agent handed a path re-reads the whole file). Pass a path only for a document you have not read and only that agent needs.

**End every agent prompt with a return contract:** "Do not write any file — this skill is the single writer of the release record. Return **only** (1) your verdict line `<agent>: GO | NO-GO | NOT ASSESSED — <reason>`, (2) the entry to record: at most 10 lines, starting with a UTC + KST timestamp, (3) a ≤5-bullet summary of decisions, (4) any BLOCKED/CONCERNS items, one line each. Do not restate the documents you read." Without it, an agent returns everything it read back into this session.

**One writer, one record.** Every phase's outcome goes into
`production/releases/<version>/release-record.md`, and only this skill writes it:

| Phase / agent | Returns | Recorded by this skill in |
|---|---|---|
| 1 release-manager (+ delivery-manager) | scope, preflight findings | `## Shipped`, `## Preflight` |
| 2 release-manager (+ devops-engineer) | release candidate identifiers, version files to bump | header, `## Timeline` |
| 3 qa-lead, devops-engineer, security-engineer | quality verdicts | `## Quality Gate` |
| 4 localization-lead, sre-engineer, analytics-engineer | readiness verdicts | `## Readiness Sign-offs` |
| 5 delivery-manager or release-manager | go/no-go recommendation | `## Go/No-Go` |
| 6 release-manager, devops-engineer, sre-engineer, customer-success-manager | stage preparation, guardrail readings, communication drafts | `## Rollout Stages`, `## Timeline`, `## Communications` |
| 7 all active agents | post-release observations | `## Timeline`, `## Outcome` |

> **Parallel agents never write the record themselves.** Phase 3 and Phase 4 spawn
> agents in parallel; two agents appending to one file race, and the loser's section
> vanishes silently. Agents return their entries; this skill appends them one at a
> time after all of them have returned, then re-reads the file.

> **Why this does not violate the Collaboration Protocol.** `CLAUDE.md` requires an agent to ask "May I write this to [filepath]?" before Write/Edit. Other orchestrators let a spawned subagent write **without** asking under a deliberate, bounded exception: (1) the path is one **you** named in the prompt, so the user approved the destination when they approved the phase; (2) it is a new artifact under `production/`, `docs/` or `tests/`, never an edit to existing source or config; (3) the phase that produced it is itself gated by an `AskUserQuestion` before the pipeline advances. Outside those three, the agent must ask. This skill does not use the exception at all — its agents write nothing, and this skill asks before its own writes (see File Write Protocol). **Do not "fix" that by asking per subagent** — a prompt per agent per phase makes an orchestrator unusable, which is why the exception exists; and do not "fix" it by letting agents append to the record, which reintroduces the race above.

Launch independent agents in parallel where the pipeline allows it (e.g., Phase 3 agents can run simultaneously).

## Pipeline

### Phase 1: Release Planning
Delegate to **release-manager** (and, at `studio`, **delivery-manager** in parallel):
- Confirm what ships: the PRD paths and story paths of this version — from the release checklist's `## Scope`, `production/sprint-status.yaml` (`status: done`) and the story files — and anything deferred from this version
- (delivery-manager) Confirm the milestone's acceptance criteria are met (`production/milestones/<milestone>.md`) and the stakeholders who must hear about the release
- Propose the release window: staffed on-call, not the evening before a weekend or a public holiday (for a Korean team, not the eve of Seollal or Chuseok), store review lead time for mobile binaries
- Output: scope confirmation and release window

Read the release inputs yourself — each verdict comes from the file's `> **Verdict**:` line directly under its H1:

| Input | Path | Needed | If missing or not passing |
|---|---|---|---|
| Release checklist | `production/releases/<version>/release-checklist.md` | verdict `GO` | **Stop.** Absent → run `/release-checklist <version>`. `NO-GO` or `NOT ASSESSED` → resolve the items it names and re-run it. This skill never overrides the checklist |
| Rollout plan | `production/releases/<version>/rollout-plan.md` | verdict `READY TO ROLL OUT`, with the production readiness verdict recorded under its `## Production Readiness Review` | `NOT READY` → **stop**, run `/rollout-plan <version>`. Absent → ask: `[A] Stop and run /rollout-plan (Recommended)` / `[B] Proceed as a single-stage release` — [B] is recorded as `NOT CHECKED — no rollout plan; single stage, rollback per the release checklist's Rollback Path` |
| Launch gate (first public release only — no earlier `COMPLETED` release record) | latest `production/gate-checks/gate-launch-*.md` | `PASS` (or `CONCERNS` the user accepted) | Absent → `Launch gate: NOT ASSESSED — no gate-check record found`; ask whether to run `/gate-check launch` first. `NOT ASSESSED` is not a pass — ask the same. `FAIL` → stop |
| Release notes | `production/releases/<version>/release-notes.md` | present | Note it; offer `/release-notes <version>` before Phase 6 |
| Changelog section | `docs/CHANGELOG.md` `## [<version>]` | present | Note it; offer `/changelog <version>` |

Then create the release record (format under **Release Record** below) with the verdict
line `> **Verdict**: NOT ASSESSED`, the header, `## Shipped` and `## Preflight`. Ask:
"May I write this to `production/releases/<version>/release-record.md`?"

### Phase 2: Release Candidate
Delegate to **release-manager** (with **devops-engineer** at `small` and above):
- Identify the release candidate: the tagged commit, container image digest, web build ID, iOS build number and Android `versionCode` — and confirm they are the ones the release checklist verified. A different candidate means the checklist is stale: stop and re-run `/release-checklist <version>`
- Prepare the tag for a human to run (`git tag -a v<version> <sha> -m "<version>"`, then `git push origin v<version>`) — pushing a tag can start a deploy pipeline, so it is never run here
- List every file whose version must change in the product (`package.json`, `app.json` / `app.config.ts`, the iOS `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION`, Android `versionName` / `versionCode`); those edits go through the normal commit flow on the release branch, not through this skill
- Freeze the release branch — no feature changes, bug fixes only; list any cherry-picks
- Output: release candidate identifiers and the version-file list

**`project.version`.** If `project.version` in `project.yaml` is not `<version>`, show the
change (`project.version: <current or unset> → <version>`) and ask:
"May I write this to `project.yaml`?" — at every automation mode. This is the only `project.yaml` key this
skill writes; it never writes `project.stage`.

### Phase 3: Quality Gate (parallel)
Delegate in parallel:
- **qa-lead**: Confirm the smoke check on the release candidate (`production/qa/smoke-*.md` — `PASS`; `PASS WITH WARNINGS` only with the warnings listed and accepted; `NOT ASSESSED` is not a pass) and the QA sign-off (`production/qa/qa-signoff-*.md` — `APPROVED` or `APPROVED WITH CONDITIONS`). Count unresolved bugs: a `production/qa/bugs/BUG-NNNN.md` whose `**Status**:` is `Open`, `In Progress` or `Fixed — Pending Verification`, by its `**Severity**:` — with the denominator ("scanned 37 bug files: 0 unresolved S1, 1 unresolved S2"). Any unresolved S1, or an unresolved S2 in a journey this release touches, is NO-GO.
- **devops-engineer**: Verify the artifacts were built by CI from the tagged commit and are reproducible, the pipeline is green, and the promote path takes the artifact verified on staging (promote, never rebuild). Prepare — do not run — the deploy, promote and rollback commands for every stage of the rollout plan, each with its blast radius and expected output. When a migration ships, confirm its dry-run evidence and the Expand phase on staging.
- **security-engineer** *(when the release changes sign-in, payments or personal data)*: Confirm the latest security audit (`production/security/security-audit-*.md`) has no open Critical or High finding affecting this release, no new dependency advisory since the audit, and no secret in the diff. Sign off on security posture.

Where the release checklist wrote the QA sign-off or the CI items as `N/A — QA sign-off not required at minimal` or `N/A — CI workflow not configured (optional at minimal)` (its `minimal`-tier reductions), that line stands: pass it to the agents and record it in `## Quality Gate`; do not re-demand the item here. Every other missing input is `NOT ASSESSED`.

### Phase 4: Localization, Performance, and Analytics
Delegate (can run in parallel with Phase 3 if resources available):
- **localization-lead**: Verify every locale in `localization.locales` (read from `project.yaml`) has complete strings for the changed screens and notification templates, release notes and store text — and, with two or more locales, a localization QA report `production/qa/localization-qa-*.md` covering this release.
- **sre-engineer**: Verify the rollout guardrails can be watched live — error rate, p95 latency, crash-free sessions, and the business KPI named in the rollout plan (for Moa: auto-debit success rate) — that each halt threshold names its exact signal, that dashboards and paging alerts cover the journeys this release touches (`docs/ops/slo.md`, `docs/ops/runbooks/`), that performance is within the `performance.*` budgets in `project.yaml` on the latest perf-profile and load-test reports, and that the on-call rota covers the rollout window (KST, with UTC in the record).
- **analytics-engineer**: Verify the tracking events of the shipped PRDs exist in `design/product/tracking-plan.md` and fire on staging, and that the dashboards for the business KPI and the shipped features receive data. Check that critical funnels (sign-up, onboarding, activation, subscription) are instrumented.
- Output: localization, performance, and analytics sign-off

### Phase 5: Go/No-Go
Delegate to **delivery-manager** (at `studio`; otherwise **release-manager**):
- Collect sign-off from: qa-lead, release-manager, devops-engineer, sre-engineer, security-engineer (if spawned in Phase 3), and the verdicts read in Phase 1
- Evaluate any open issues — are they blocking or can they ship?
- Make the go/no-go recommendation; the user makes the call
- Output: release decision with rationale

**If the recommendation is NO-GO:**
- Surface the decision immediately: "GO/NO-GO: NO-GO — [rationale, e.g., unresolved S1 found in Phase 3]."
- Use `AskUserQuestion` with options:
  - Fix the blocker and re-run the affected phase
  - Defer the release to a later date
  - Override NO-GO with documented rationale (user must provide written justification)
- **Skip Phase 6 entirely** — do not tag, deploy to staging, deploy to production, submit to a store, or spawn customer-success-manager.
- Produce a partial report summarizing Phases 1–5 and what was skipped (Phase 6) and why.
- Record the decision and set the record's verdict to `HALTED` (halted before Stage 1) when the user defers; keep `NOT ASSESSED` when they choose to fix and re-run.

After the user selects "Override NO-GO with documented rationale":
- Ask (plain text, not widget): "Please describe the justification for overriding the NO-GO verdict. This will be embedded in the release record."
- Wait for the user's written justification.
- Embed the justification text in the record's `## Go/No-Go` section before Phase 6: append an "**Override Justification**: [user's text]" field.
- Only then proceed to Phase 6.

An override never covers an input that Phase 1 stops on: a release checklist that is
not `GO`, or a rollout plan that is `NOT READY`, is fixed in its own skill first.

### Phase 6: Deployment (if GO)

**Every stage in this phase requires explicit user approval regardless of
`modes.automation` — including `autonomous` mode.** Each stage is a
`production_deploys` decision (see Decision Points), and a human runs every command.

Walk the stages of the rollout plan in order (a single stage when Phase 1 recorded
`NOT CHECKED — no rollout plan`). The plan's sections drive each stage: the stages
and their exposure from `## Strategy per Surface`, migration steps from
`## Migration Ordering`, guardrails and halt thresholds from
`## Guardrail Metrics & Halt Thresholds`, rollback steps from `## Rollback Plan`,
announcements from `## Communication Plan`, and the owner of each stage's decision
from `## Go/No-Go per Stage`. A typical plan for Moa `web+stores`:
staging → web and API canary 5% → flag `goals.v2-progress-ring` 25% → 100% → iOS
phased release (seven days, Apple's fixed percentages) and Android staged rollout
10% → 50% → 100%. Migrations follow the plan's
ordering: Expand before the deploy that needs it, Contract only after every running
version — including every supported app version — has stopped reading the old shape.

For each stage, delegate to **release-manager** + **devops-engineer** to prepare it:
- the exact commands or console steps for a human, each with its blast radius, expected output and rollback command
- the stage's exposure (percentage, segment or store track), dwell time, guardrails and halt thresholds from the rollout plan
- for store stages: the submission package (build, review notes, demo account, phased-release or staged-rollout setting). Upload and submit commands (`eas submit`, `fastlane deliver`, `fastlane supply`) are for a human; the settings deny list blocks them for agents

Then use `AskUserQuestion`:
- Prompt: "Stage [N] of [M] — [what]. Run the steps above yourself, then tell me the result."
- Options: `[A] Ran it — succeeded; start the dwell and record it` / `[B] Ran it — failed or looks wrong` / `[C] Not now — hold (the record stays open)` / `[D] Stop the release here`

After **[A]**, delegate to **sre-engineer**: compare the guardrail readings the human
shares (or the dashboards and queries sre-engineer can read without changing anything)
with the stage's halt thresholds after the dwell time. Record the stage row and a
timeline entry, with the stage owner from `## Go/No-Go per Stage` as "Decided by" —
show them, and write them once the user confirms.
- **A halt threshold crossed** → use `AskUserQuestion`: `[A] Roll back per the rollback plan (steps for a human)` / `[B] Hold at the current exposure and investigate — /incident open when users are affected` / `[C] Accept and continue — written justification required`. A rollback executed ends the release as `ROLLED BACK`.
- **[B] failed** → treat as a halt: offer rollback or hold as above.
- **[C] hold** → the record keeps `NOT ASSESSED`; resume later with `/team-release <version>`.
- **[D] stop** → the release ends as `HALTED` at the current exposure.

Mobile binaries cannot be rolled back: their "rollback" is pausing the App Store phased
release or halting the Play staged rollout, turning the server-side kill switch off, and
shipping a fixed build (`/hotfix`).

Delegate to **customer-success-manager** (in parallel with the first production stage):
- Prepare the customer communication: in-app notice or status-page note where the release changes something visible, the support briefing and macros for known issues, app-review reply templates — per locale with **localization-lead**
- Confirm `production/releases/<version>/release-notes.md` exists; if not, stop the communication track and offer `/release-notes <version>` (it asks before writing)
- Output: all customer-facing release communication, ready to publish on deploy confirmation — publishing is a human action

### Phase 7: Post-Release
- **sre-engineer**: Watch the guardrails and error budget through the post-release window of the rollout plan (typically 24 and 72 hours); anything user-affecting goes to `/incident open`
- **qa-lead**: Monitor incoming bug reports for regressions; each becomes `/bug-report`
- **customer-success-manager**: Confirm the communication was published; watch support volume and app reviews
- **analytics-engineer**: Confirm live dashboards are healthy; alert if any critical events are missing
- **delivery-manager**: Update milestone tracking, communicate to stakeholders
- **release-manager**: Close the record — what shipped and what was deferred, follow-ups
- Write the record's `## Outcome` and replace its verdict line with the final state (`COMPLETED`, `HALTED` or `ROLLED BACK`) — show the change and ask before writing
- Schedule `/retrospective release <version>` once the rollout has completed, or promptly after a `HALTED` or `ROLLED BACK` release

## Release Record

`production/releases/<version>/release-record.md` — created in Phase 1, extended after
every phase and stage, closed in Phase 7. Entries are append-only; a correction is a new
timeline entry, never an edit of an old one. The verdict line and the `**Closed**` field
are the only lines that change. Headings stay in English exactly as below;
the text under them follows the user's conversation language.

```markdown
# Release Record: [version]

> **Verdict**: [COMPLETED | HALTED | ROLLED BACK | NOT ASSESSED]

**Version**: [x.y.z] · **Distribution**: [web | stores | web+stores | enterprise | internal]
**Release candidate**: tag `v[x.y.z]` · commit `[sha]` · image `sha256:[…]` · iOS build [n] · Android versionCode [n]
**Release checklist**: `production/releases/[version]/release-checklist.md` — [GO]
**Rollout plan**: `production/releases/[version]/rollout-plan.md` — [READY TO ROLL OUT; production readiness READY] | NOT CHECKED — no rollout plan
**Release notes**: `production/releases/[version]/release-notes.md` | none
**Team**: team.size [value] — spawned: [agents]; not spawned: [agents]
**Opened**: [YYYY-MM-DD HH:MM UTC / HH:MM KST] · **Closed**: [YYYY-MM-DD HH:MM UTC / HH:MM KST | open]

## Shipped

**PRDs**:
- `design/prd/[feature-slug].md`

**Stories**:
- `production/epics/[epic-slug]/story-NNN-[slug].md`

**Bug fixes**: [BUG-NNNN, …] · **Deferred**: [item — reason — target version]

## Preflight

| Input | Path | Verdict read |
|---|---|---|

## Quality Gate

## Readiness Sign-offs

## Go/No-Go

## Rollout Stages

| # | Stage | Surface | Exposure | Started (UTC / KST) | Guardrails after dwell | Decision | Decided by |
|---|---|---|---|---|---|---|---|

## Timeline

- [YYYY-MM-DD HH:MM UTC / HH:MM KST] — [event, reading, decision and who made it]

## Communications

## Outcome
```

Verdict meanings:
- **COMPLETED** — every stage reached its target exposure and the post-release window closed without a rollback.
- **HALTED** — the release stopped short of full exposure and was not reverted: a NO-GO or a deferral before Stage 1, or a stop the user chose at partial exposure.
- **ROLLED BACK** — exposure was reversed: the previous artifact redeployed, the flag turned off, or a mobile rollout halted and superseded by a fixed build.
- **NOT ASSESSED** — the release has not reached a final state: a rollout still in progress, a held stage, or a stage whose outcome was never confirmed. It is the record's verdict while the release runs and is replaced when the release ends.

Example timeline entry:

```
2026-11-04 01:30 UTC / 10:30 KST — Stage 4: iOS phased release 2% → paused. Crash-free sessions 99.2% < 99.5% halt threshold. Decision: pause (on-call product manager). Next check 04:30 UTC / 13:30 KST.
```

## Error Recovery Protocol

**First, verify the artifact.** This skill's artifact is the release record. After
writing each phase's entries, re-read `production/releases/<version>/release-record.md`
and confirm the phase's section is on disk before treating the phase as done — **a phase
whose entries are not in the record is a failed phase, however fluent the responses
read.** For each spawned agent, the contracted return (verdict line and entry) is the
artifact of its turn: an agent can burn a full phase and return a plausible preamble
with neither, which is neither BLOCKED nor an error nor "cannot complete", so the
trigger below never fires. Resume it naming the unmet contract; the context is
usually still there.

If any spawned agent returns BLOCKED, errors, or cannot complete: **surface it
immediately, don't proceed past a dependency it blocks, and always produce a
partial report.** Full procedure: `.claude/docs/error-recovery-protocol.md`.

Common blockers:
- Input file missing (release checklist, rollout plan, release notes not found) → redirect to the skill that creates it (`/release-checklist`, `/rollout-plan`, `/release-notes`)
- Release checklist `NO-GO` or `NOT ASSESSED`, rollout plan `NOT READY` → do not deploy; fix the items and re-run that skill
- Release candidate differs from the one the checklist verified → re-run `/release-checklist <version>`
- Unresolved S1 bug, or S2 in a touched journey → `/bug-triage`; ship the fix, then re-run the smoke check
- Guardrails not observable (no dashboard for a halt signal) → do not start the stage; sre-engineer names what is missing
- Conflicting instructions between the rollout plan and the release checklist (e.g. different rollback steps) → surface the conflict, do not guess

## File Write Protocol

This orchestrator writes exactly two things, asking before each write:

- **`production/releases/<version>/release-record.md`** — created in Phase 1
  ("May I write this to `production/releases/<version>/release-record.md`?"); every later
  addition is shown first and approved through the decision widget of its phase or
  stage ("record it") before it is written.
- **`project.yaml` `project.version`** — Phase 2, asked every time, at every
  automation mode.

Everything else belongs to other skills, which are not sub-agents and follow the normal
Collaboration Protocol — they ask before writing: `/release-checklist`, `/rollout-plan`,
`/release-notes`, `/changelog`, `/smoke-check`, `/bug-report`, `/incident`, `/hotfix`,
`/retrospective`. Spawned agents write nothing (see "Why this does not violate the
Collaboration Protocol" above).

Nothing here authorises an outward-facing or irreversible action — tags, pushes,
builds, deploys, migrations, flag changes and storefront changes are run by a human
after explicit confirmation, whichever rule above applies.

## Output

A summary report covering: release version, what shipped (PRD and story paths), quality
gate results, the go/no-go decision, every rollout stage with its timestamps and
decision, the monitoring plan, and the record's path.

Verdict: **COMPLETED** — every stage reached its target exposure and the post-release window closed cleanly.
Verdict: **HALTED** — the release stopped before full exposure (NO-GO, deferral or a stop at partial exposure).
Verdict: **ROLLED BACK** — exposure was reversed after a stage.
Verdict: **NOT ASSESSED** — the release is still in progress or a stage outcome is unconfirmed; resume with `/team-release <version>`. A stop in Phase 1 on one of its release inputs, before the record exists, also ends the run NOT ASSESSED: no record is written; name the input and the skill that fixes it.

## Next Steps

- Watch the guardrails through the post-release window of the rollout plan.
- Run `/retrospective release <version>` after the rollout completes (or after a `HALTED` or `ROLLED BACK` release) — it reads this record and compares each shipped PRD's outcome with its success metrics.
- Production breaks: `/incident open`, then `/hotfix` for the fix and `/postmortem <INC-id>` for SEV1/SEV2.
- The next release repeats the delivery loop: `/write-prd` or `/quick-spec` → `/sprint-plan` → `/dev-story` → `/smoke-check` → `/release-checklist` → `/rollout-plan` → `/team-release`.
- This skill never changes `project.stage`. `/gate-check launch` moved the project to `Launch`, which is terminal: every later release is recorded under `production/releases/<version>/`, not gated.
