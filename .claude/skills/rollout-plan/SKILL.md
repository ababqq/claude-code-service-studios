---
name: rollout-plan
description: "Progressive-delivery plan: flags/canary stages, mobile phased release, migration ordering, guardrails, halt thresholds, rollback, comms."
argument-hint: "[version] [--feature <flag-key>]"
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/rollout-plan/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys distribution,surfaces,performance.enforce,compliance`

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.

> **Explicit invocation only**: This skill runs only when the user types `/rollout-plan`. Do not start it because a
> release is being discussed.

# Rollout Plan

A release reaches users in stages, not all at once. This skill writes the plan for **how** a version is exposed to
production traffic: which stages each surface goes through (flag percentages and canary stages for web and API; App
Store phased release and Google Play staged rollout for mobile), in what order database migrations run relative to
the deploy, which guardrail metrics are watched and at what threshold a stage halts, how each stage is rolled back,
who is told what and when, and who says Go at each stage. Before the plan can say `READY TO ROLL OUT`, the
sre-engineer's **production readiness review** (SR-PRODUCTION-READINESS) checks that the service can take the
traffic and that the way back is real.

**A plan, not a rollout.** The skill never deploys, changes a production flag, runs a migration or submits a store
build — those are `production_deploys` and `db_migrations` actions for a person, executed stage by stage through
`/team-release`, and the project's settings deny list blocks the common deploy and store-submission commands for
agents anyway. Commands in the plan are written for a human to run.

**Always collaborative.** Every question is asked and every write is approved, whatever `modes.automation` says —
production exposure is listed among the exemptions in `.claude/docs/automation-modes.md`.

**Review-mode exemption.** `/hotfix`, `/rollout-plan` and `/incident` are release-critical: every agent and gate they name runs at every `review_mode`. They do not resolve `review_mode`.

SR-PRODUCTION-READINESS therefore runs on every plan, at every review mode, and its outcome is always recorded under
the plan's `## Production Readiness Review` — the launch gate requires that line and never accepts a skip note in its
place.

**When to run**: in Hardening, after `/release-checklist` for the first public release (the launch gate requires the
plan at `standard` and `full`); in Launch, for every subsequent release; and with `--feature <flag-key>` when one
flag's exposure is planned on its own after its code has shipped dark.

### Output

| Path | Template |
|---|---|
| `production/releases/<version>/rollout-plan.md` | `.claude/docs/templates/rollout-plan.md` |

`<version>` is the argument, else `project.version`; semver (`2.4.0`). Mobile build numbers go inside the file, not
in the directory name. The catalog's `rollout-plan` steps find the plan through `production/releases/*/rollout-plan.md`;
`/gate-check launch` and `/team-release` read its verdict line.

### Sections (exact headings, from the template)

`## Scope` · `## Strategy per Surface` · `## Migration Ordering` · `## Guardrail Metrics & Halt Thresholds` ·
`## Rollback Plan` · `## Communication Plan` · `## Go/No-Go per Stage` · `## Production Readiness Review`

### Verdicts

`READY TO ROLL OUT` · `NOT READY` · `NOT ASSESSED`

- `READY TO ROLL OUT` — every section is complete; every stage has a named owner, entry criteria and a rollback;
  every guardrail has a threshold; migrations are ordered expand → deploy → contract; SR-PRODUCTION-READINESS
  returned `READY`, or `CONCERNS` the user accepted.
- `NOT READY` — a blocker is open: SR-PRODUCTION-READINESS `NOT READY`, a `NO-GO` release checklist, an unresolved
  `S1-Critical` bug, an unresolved `S2-Major` bug in a journey the release touches that the user has not explicitly
  accepted, a stage without a rollback, or a Contract-phase migration scheduled while readers of the old shape are
  still deployed.
- `NOT ASSESSED` — an input the plan depends on is missing or unverifiable: no release checklist, no SLO document,
  a guardrail without a threshold the user has not waived, the gate reply unparseable.

Precedence: **NOT READY > NOT ASSESSED > READY TO ROLL OUT**. A plan that could not be assessed never says
`READY TO ROLL OUT`; a known blocker is never hidden behind `NOT ASSESSED`.

### Agents

| Agent | Contribution | Runs |
|---|---|---|
| `release-manager` | Stage design per surface; store phased release and staged rollout; minimum supported version and force-update policy; Go/No-Go owners | every run |
| `devops-engineer` | Deploy strategy (canary, blue-green, rolling), flag mechanics, rollback commands and their time to effect, rehearsal evidence | every run |
| `qa-lead` | Quality inputs (smoke, QA sign-off, unresolved bugs), per-stage verification checks | every run |
| `customer-success-manager` | `## Communication Plan`: support briefing, macros, known issues, customer and API consumer messages | every run |
| `sre-engineer` | SR-PRODUCTION-READINESS gate | every run, after the draft is written |

All five run at every review mode. Agents return drafts and findings; they never write the plan or run commands.

---

## Phase 0: Parse Arguments and Resolve Context

1. **Version.** Use the argument when given. Otherwise read `project.version` from `project.yaml` with Read. Still
   none: Glob `production/releases/*/`; exactly one directory ⇒ propose it; several ⇒ ask which; none ⇒ ask for the
   version (semver). Never invent one.
2. **`--feature <flag-key>`** scopes the plan to one flag's exposure (e.g. `goals.v2-progress-ring`, already deployed
   dark in `<version>`): `## Scope` names only that flag, and the stages are flag stages. When the version's plan
   already exists, the flag's stages are added to it as their own table under `## Strategy per Surface` (Phase 5
   asks before editing).
3. **Resolved config** (the block above):
   - `release.distribution` — decides the tracks. *Stores* (`stores`, `web+stores`) ⇒ mobile phased release rows;
     `web` ⇒ web/API stages only; `enterprise` ⇒ staged by customer organization or tenant (ring deployment) and
     the customer's own change window; `internal` ⇒ internal cohorts only. Unset ⇒ ask how this release ships —
     never emit every track.
   - `platform.surfaces` — which surface blocks the strategy needs (`web`, `ios`, `android`, `api`). Unset ⇒ ask.
   - `performance.enforce` — what a guardrail breach does during a stage: `block` ⇒ automatic halt; `warn` ⇒ the
     stage owner decides and the decision is recorded; `off` ⇒ budgets are informational, and the plan says so.
   - `compliance` — `regions=` for message-consent rules in the communication plan (Phase 4e); unset ⇒ ask when the
     plan includes customer messages.
4. **Read from `project.yaml` with Read** (keys with no resolved label): `performance.error_rate_pct`,
   `performance.api_p95_ms`, `performance.crash_free_pct`, `performance.lcp_ms`, `performance.inp_ms`,
   `performance.cls`, `performance.availability_pct`, `platform.min_os.ios`, `platform.min_os.android`,
   `localization.locales`. An unset budget is not a threshold of zero and not a default: it is asked for in Phase 4.
5. **Stage context.** Run `bash .claude/scripts/stage-estimate.sh` and read its `STAGE:` line — Hardening (the first
   public release) or Launch (a subsequent release). It informs the wording of the plan and which next steps Phase 9
   offers; it never blocks.

---

## Phase 1: Load the Release Context — Check the Premise

The plan rests on a release that is already verified. Check that rather than assuming it — the stage value is a
claim, the records are the evidence. Read:

| Input | Where | If missing or negative |
|---|---|---|
| Release checklist | `production/releases/<version>/release-checklist.md`, its `> **Verdict**:` line | not found ⇒ `Release checklist: NOT ASSESSED — no record found`; recommend `/release-checklist <version>` first; drafting may continue but the verdict is capped at `NOT ASSESSED`. `NO-GO` ⇒ name its open items; the verdict is capped at `NOT READY` |
| Launch gate record | newest `production/gate-checks/gate-launch-*.md`, its `> **Verdict**:` line | absent ⇒ a note in `## Scope` (normal in Hardening — the launch gate reads this plan), never a stop. `FAIL` or `CONCERNS` ⇒ name it in `## Scope` so the reader sees it |
| SLO document | `docs/ops/slo.md` (`## Critical User Journeys`, `## SLIs & SLOs`, `## Error Budget Policy`, `## Dashboards & Alerts`, `## On-call`) | not found ⇒ `NOT CHECKED — SLOs (no docs/ops/slo.md)`; the verdict is capped at `NOT ASSESSED` |
| Unresolved bugs | `production/qa/bugs/BUG-*.md` — unresolved = `**Status**:` `Open`, `In Progress` or `Fixed — Pending Verification`; severity from `**Severity**:` | any unresolved `S1-Critical` ⇒ `NOT READY`; unresolved `S2-Major` in a journey this release touches ⇒ `NOT READY` unless the user explicitly accepts it (recorded in `## Scope` with an owner) |
| Migration plans | `docs/data/migrations/*.md` referenced by the release's stories, each plan's `## Deploy Ordering` and `## Status` | none ⇒ "None — this release changes no schema or data" after asking |
| Flags | stories' `**Feature Flag**` fields and the PRDs' `## Configuration & Flags` sections | a story with a flag but no default recorded ⇒ ask |
| Security audit | newest `production/security/security-audit-*.md`, its verdict and open Critical/High findings | open Critical or High ⇒ name them; the user decides whether they block the rollout |
| Load test | newest `production/qa/load/load-test-*.md` | none ⇒ passed to the gate as "none" (the gate treats it as CONCERNS; NOT READY only at workflow `full` when the release changes a peak-traffic path such as sign-in, payments or the core journey) |
| Runbooks | `docs/ops/runbooks/*.md` against the paging alerts in `docs/ops/slo.md` `## Dashboards & Alerts` | missing runbooks ⇒ list them; recommend `/incident runbook <alert-slug>` |
| Release contents | `production/sprints/`, the stories closed for the version, `docs/CHANGELOG.md` `## [<version>]`, `git log` between the previous tag and `HEAD` (read-only) | the scope table in Phase 2 is confirmed by the user either way |

**`NOT ASSESSED` is not a pass.** A QA, smoke or checklist input that returned `NOT ASSESSED` means nobody checked;
it is never read as `GO`, `PASS` or `PASS WITH WARNINGS`. Under release pressure the permissive reading is the one
that will feel reasonable, which is why it is written down here. Either obtain the missing result — the input names
what would make it runnable — or record in `## Scope` that the user explicitly decided to plan a rollout on an
unverified input.

---

## Phase 2: Scope

Draft `## Scope`: what ships (PRD and story paths), the surfaces each item touches, its flag and default, its
migration plan and phase; what is **not** in the release; the inputs-checked table from Phase 1; accepted risks with
owners. Present it:

- Prompt: "Here is what version <version> exposes to users. Is the scope right?"
- Options: `Approve the scope` / `Adjust — add or remove items` / `Stop — the release is not ready to plan`

"Stop" ends the skill without writing (no verdict is recorded for a plan that was not written). Scope discipline
matters: every item added to a release that is already verified widens what the stages must watch.

---

## Phase 3: Expert Input

Spawn in parallel (issue every `Agent` call before waiting for any result), each with the version, the approved
scope, the resolved `distribution` and `surfaces` lines, and the input paths from Phase 1:

- `release-manager` — stages per surface and their exposure, dwell times and entry criteria; for *Stores*: App Store
  phased release or immediate release, Play staged rollout percentages, store-review timing, minimum supported app
  version, force-update policy, server compatibility window; a named owner per stage.
- `devops-engineer` — deploy strategy per service (canary by traffic, blue-green, rolling), flag mechanics and the
  flag service, rollback action per stage with the exact command or console path **for a human**, its time to
  effect, and whether it was rehearsed on staging (date and evidence path).
- `qa-lead` — the quality evidence (smoke report, QA sign-off, unresolved bugs), and the checks that verify each
  stage before the next one starts.
- `customer-success-manager` — the communication plan: support briefing and macros before the first stage, known
  issues, customer-facing messages per stage and a pre-drafted holding message for a halt or rollback, API
  consumer notices when `api` is a surface.

Collect every reply. Conflicts between them (e.g. dwell times too short for the qa-lead's checks) are shown to the
user side by side, never resolved silently.

---

## Phase 4: Draft the Plan, Section by Section

Draft each section from the template and the expert input; show it and ask for approval or corrections before the
next.

### 4a. `## Strategy per Surface`

- **Web and API**: code ships dark behind flags; exposure grows by stages (internal cohort → canary → 25% → 50% →
  100% is the default proposal); canary stages have dwell times long enough to include real traffic peaks. A stage's
  entry criteria are the previous stage's guardrails staying green for its dwell time.
- **iOS and Android** (*Stores*): App Store phased release (Apple's automatic seven-day schedule, pausable) or
  release to all users; Google Play staged rollout with the percentages the team sets (e.g. 1% → 5% → 20% → 50% →
  100%, haltable). Minimum supported app version and force-update policy, minimum OS (`platform.min_os.*`), and the
  server compatibility window — the API keeps serving every app version at or above the minimum until the stated
  date. Stages are planned from store approval, not from submission.
- **Feature flags** table: key, production default, kill switch, stage schedule, owner, removal story.
- For Moa, the 25th of the month is an auto-debit peak (a common payday in Korea): avoid moving a stage that touches
  payments or notifications through that window, or make it an explicit Go/No-Go decision.

### 4b. `## Migration Ordering`

Copy each migration plan's ordering: **Expand** applied before the deploy that needs it, **Migrate** (backfill) after
the stage that writes both shapes is healthy, **Contract** only after every reader of the old shape is gone — for
mobile, only after the minimum supported app version no longer reads it, which is usually a later release. A
Contract phase scheduled inside this rollout while old readers remain is a blocker (`NOT READY`). Each step names the
person who runs it and the verification query from the plan.

### 4c. `## Guardrail Metrics & Halt Thresholds`

One row per metric: server error rate (`performance.error_rate_pct`), p95 latency of the critical endpoints
(`performance.api_p95_ms`), crash-free sessions for mobile (`performance.crash_free_pct`), Core Web Vitals for web
(`performance.lcp_ms`, `performance.inp_ms`, `performance.cls`), SLO burn rate for every journey the release touches,
and **one business KPI** (for Moa: goals created per hour, auto-debit success rate). Each row: source, baseline, halt
threshold, evaluation window, action on breach per `performance.enforce`.

A metric whose budget is unset is asked for: "What error rate should halt a stage?" If the user declines to set one,
the row reads `NOT ASSESSED — no threshold`, and the verdict stays below `READY TO ROLL OUT` unless the user
explicitly accepts rolling out without that guardrail (recorded under `## Scope` as an accepted risk). List the
**automatic halt conditions** — any SEV1 or SEV2 incident opened during the rollout window always halts it.

### 4d. `## Rollback Plan`

**Rollback before rollout, always.** One row per stage: trigger (the halt threshold that fires it), action, exact
command or console path for a human, time to effect, data considerations (Expand-phase migrations stay applied and
remain compatible), and whether it was rehearsed on staging with the date and evidence. Mobile binaries cannot be
rolled back: the path for installed apps is the server flag or kill switch, API compatibility, and an expedited fix
through `/hotfix`. A stage without a rollback is a blocker.

### 4e. `## Communication Plan`

From customer-success-manager's draft: internal (support briefing, macros, on-call hand-off), customers (in-app,
release notes at `production/releases/<version>/release-notes.md`, store "What's New"), API consumers, and the
holding message for a halt. Customer-facing text is written in the locale(s) in `localization.locales`. For each
region in `compliance.regions`, read `.claude/docs/compliance/<region>.md` `## Marketing Messages & Consent` and
check promotional launch messages against it (for `kr`: prior opt-in for advertising messages, separate consent for
night-time sending, and 알림톡 only for informational messages). Unset regions ⇒ ask; `regions=none` ⇒ note that no
regional message rules apply.

### 4f. `## Go/No-Go per Stage`

One row per stage: Go criteria and a **named person** as owner, plus who is consulted. Decisions themselves are
recorded during the rollout in `production/releases/<version>/release-record.md` by `/team-release`.

---

## Phase 5: Write the Draft

Assemble the plan with `> **Verdict**: NOT ASSESSED` (the gate has not run yet) and `## Production Readiness Review`
reading "pending — SR-PRODUCTION-READINESS runs next". The gate reads the plan from disk, so the draft is written
before it runs.

Ask: "May I write this to `production/releases/<version>/rollout-plan.md`?" When the file exists (a re-plan, or
`--feature` adding a flag), show what changes and ask the same question before editing it.

---

## Phase 6: Production Readiness Review — SR-PRODUCTION-READINESS

This gate runs at every review mode (exemption above). Spawn `sre-engineer` via `Agent`:

- Gate: SR-PRODUCTION-READINESS — the `Agent` prompt instructs the agent to read
  `.claude/docs/director-gates/sr-production-readiness.md` FIRST (this skill does not read that file).
- Pass: rollout-plan path · `docs/ops/slo.md` path · runbook paths · latest load-test report path (or "none") · release-checklist path
- Parse the first line of the reply as `[SR-PRODUCTION-READINESS]: TOKEN` and map the token to its class:
  - `READY` (APPROVE-class) ⇒ proceed.
  - `CONCERNS` (CONCERNS-class) ⇒ show the findings and ask: `Revise flagged items` / `Accept and proceed` /
    `Discuss further`. "Revise" returns to the relevant Phase 4 section and, after the edit is written, re-runs this
    gate.
  - `NOT READY` (REJECT-class) ⇒ show the blockers. The plan cannot say `READY TO ROLL OUT`. Ask:
    `Revise the plan and re-run the review` / `Record the plan as NOT READY` / `Stop`.
  - A first line that does not parse, or a token not on the gate's Verdicts line, is not an approval: show the full
    reply as CONCERNS-class and say the verdict line was missing.

Record the outcome under `## Production Readiness Review`, keeping the gate's first line:

```markdown
> **Site Reliability Engineer Review (SR-PRODUCTION-READINESS)**: APPROVED 2026-11-02

**Gate reply**: `[SR-PRODUCTION-READINESS]: READY`

**Findings**: <each finding with owner and due point in the rollout>

**Accepted concerns**: <what the user accepted, and why — or "none">
```

The recording token is `APPROVED` for `READY`, `CONCERNS (accepted)` when the user accepted CONCERNS, `REVISED` when
the plan was revised in response and the user chose not to re-run the review, and `NOT READY` when the plan is
recorded with open blockers. A skip note never appears here.

---

## Phase 7: Verdict

Apply the rules of the Verdicts section with their precedence and show the reasoning: every capping input from
Phase 1, every `NOT ASSESSED — no threshold` row, the gate outcome. Present the verdict and the plan's header block:

- Prompt: "The plan's verdict is **<TOKEN>** because <reasons>. Record it?"
- Options: `Record this verdict` / `Revise a section first` / `Stop without recording`

Ask: "May I write this to `production/releases/<version>/rollout-plan.md`?" and update the verdict line, the
`## Production Readiness Review` section and any section revised in Phase 6.

**Deferred is not forgotten.** Items moved out of the release, S2 bugs accepted, guardrails waived and concerns
accepted are listed under `## Scope` with an owner — never dropped.

---

## Phase 8: What the Plan Hands Over

The plan is executed by people through `/team-release`, which walks the stages, puts each Go/No-Go to its owner, and
records every stage with UTC and KST timestamps in `production/releases/<version>/release-record.md`. During the
rollout:

- a halt threshold that fires ⇒ the stage's rollback row, run by a person; an incident that follows ⇒
  `/incident open`;
- a defect that needs a code fix during the rollout ⇒ `/hotfix <BUG-id | INC-id>`.

After the rollout completes (the release record's final state is `COMPLETED`, `HALTED` or `ROLLED BACK`), the loop
closes with `/retrospective release <version>`, which compares the outcome with each shipped PRD's success metrics.

---

## Phase 9: Close

Print the verdict line `Verdict: <TOKEN>`, the plan path, and every `NOT CHECKED` and `NOT ASSESSED` line. Then
close with `AskUserQuestion`, offering only what applies:

- `READY TO ROLL OUT` in Hardening: `/launch-checklist <version>` (first public launch) · `/gate-check launch` ·
  `/release-notes <version>` when the notes are not drafted · stop here;
- `READY TO ROLL OUT` in Launch: `/team-release` to execute the stages · `/release-notes <version>` when the notes
  are not drafted · `/retrospective release <version>` once the rollout has completed · stop here;
- `NOT READY` or `NOT ASSESSED`: the skill that closes the named gap — `/release-checklist <version>`,
  `/incident runbook <alert-slug>`, `/load-test`, `/data-model migration <slug>`, `/bug-triage` — then
  `/rollout-plan <version>` again · stop here.

---

## Collaborative Protocol

1. **Question → Options → Decision → Draft → Approval** for every section. Recommend stage sizes, dwell times and
   thresholds with reasons; the user decides.
2. **"May I write this to `<path>`?"** before every write — the draft, every revision, the verdict.
3. **The gate always runs.** SR-PRODUCTION-READINESS is never skipped, at any review mode, and its outcome is always
   recorded in the plan.
4. **Check the premise.** A missing or negative release checklist, SLO document or guardrail is named and caps the
   verdict; `NOT ASSESSED` is never read as a pass.
5. **Rollback before rollout.** No stage without a rollback row; mobile relies on server-side flags and expedited
   fixes because binaries cannot be recalled.
6. **Humans run production.** Every deploy, flag change in production, migration and store action in the plan is a
   command for a person, executed through `/team-release`.
7. **Unset is not "no".** Unset distribution, surfaces, regions or budgets are asked, never assumed.
8. **No commits.** Committing the plan is the user's decision.
9. **The next step is offered, never taken.** Phase 9 recommends the next skill — `/team-release` to execute,
   `/retrospective release <version>` after the rollout completes — and waits for the user's choice.
