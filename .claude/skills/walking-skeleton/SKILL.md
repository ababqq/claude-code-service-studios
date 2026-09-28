---
name: walking-skeleton
description: "Real thin end-to-end path deployed to staging via CI/CD with rollback and flag rehearsal; VALIDATED / NOT VALIDATED / NOT ASSESSED."
argument-hint: "[journey-name] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/walking-skeleton/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,automation_always_ask,stack,code_roots,surfaces,workflow`

Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).


# Walking Skeleton

## Purpose

The **walking skeleton** answers the delivery question before feature sprints start:
*"Can our real stack carry one critical user journey through every configured layer —
UI → API → DB — built by our pipeline, deployed to staging, observable, reversible and
switchable by flag?"*

It is **real code, not a throwaway**: the thinnest end-to-end implementation of one
critical user journey, on a feature branch in the resolved code roots, merged and
evolved like any other change. It is "Sprint 0" — the foundation every later story
builds on.

| | `/prototype` | `/walking-skeleton` |
|---|---|---|
| Question | Do users want this? (the riskiest assumption) | Can we build, ship, observe and reverse this? |
| Code | Throwaway, under `prototypes/` | Production code in the code roots |
| Ends in | PROCEED / PIVOT / KILL | VALIDATED / NOT VALIDATED / NOT ASSESSED |
| Environment | Local, a clickable mock, or a fake door | Staging, deployed by the CI/CD pipeline |

**When to run it** — in Validation, after the architecture exists (ADRs, the API
contract, the data model, `docs/ops/slo.md`) and `/test-setup` has scaffolded CI;
ideally after the UX spec for the journey's screens. It is required at `standard` and
`full` (the Validation → Build gate looks for its report) and optional at `minimal` —
but **once built, its validation rules bind at every tier**: the gate fails a skeleton
that was built and does not work. Re-run it after a NOT VALIDATED verdict once the
failing items are fixed.

**Output:**
- code on a feature branch in the resolved code roots (via the engineer agents)
- `production/walking-skeleton/report-YYYY-MM-DD.md` from
  `.claude/docs/templates/walking-skeleton-report.md`
- journey captures in `production/qa/evidence/walking-skeleton-<journey-slug>/`

---

## Phase 0: Resolve Configuration and Load Context

From the block above:
- **`review_mode`** (`--review` overrides) — whether PD-USER-VALIDATION spawns (Phase 10).
- **`stack`** — the configured layers and their routing. `stack: unset — run /setup-stack`
  ⇒ stop with Verdict **NOT ASSESSED** (no report): a skeleton needs a pinned stack. A
  layer under `unset=` is simply not part of this skeleton; say so in the plan.
- **`code_roots`** — where each layer's code goes. `code_roots: unresolved — NOT CHECKED …`
  ⇒ print `NOT CHECKED — no code root resolved (set stack.layers.<layer>.root via /setup-stack)`,
  write no code, and stop with Verdict **NOT ASSESSED** (no report). A root whose source
  is `missing` (declared, not on disk) is expected here — this skill may scaffold that
  app (Phase 2), after asking.
- **`surfaces`** — `platform.surfaces`: which UI surfaces the journey must reach. Unset ⇒
  ask which surfaces ship before planning.
- **`automation_always_ask`** — the categories that prompt in every mode (table in
  Phase 3).
- **`workflow`** — whether validation item 5 applies (Phase 7).

Read (only what exists; name what is missing):
- `docs/ops/slo.md` — `## Critical User Journeys`
- `docs/architecture/architecture.md` — layers, environments (dev / staging / prod)
- `docs/architecture/control-manifest.md` and `docs/architecture/tech-radar.md`
- the API contract under `docs/api/` and `docs/data/data-model.md` with the migration
  plans in `docs/data/migrations/`
- `design/product/product-brief.md` (or `design/product/one-pager.md`)
- the UX specs of the journey's screens under `design/ux/`
- `docs/stack-reference/VERSION.md` — pinned components and their Knowledge Risk
- the CI workflow(s) `/test-setup` wrote (e.g. `.github/workflows/ci.yml`)
- from `project.yaml` with Read: `commands.*` (`install`, `run`, `build`, `test`,
  `typecheck`, `e2e`, `migrate`, `deploy_preview`), `naming.*` and `performance.*`

**Prerequisites** — surface each missing one with its fix and ask whether to proceed:

| Missing | Why it matters | Fix |
|---|---|---|
| CI workflow | Item 1 needs the pipeline to build and deploy | `/test-setup` |
| API contract (when a backend layer is configured) | The skeleton is contract-first | `/api-design` |
| Data model / migration plan (when a data layer is configured) | The journey writes to the database | `/data-model` |
| `docs/ops/slo.md` | The journey should be a named critical user journey | `/create-architecture` (or pick from a PRD and record the source) |
| A staging environment | Every validation item runs on staging | devops-engineer proposes it in Phase 4 (`infra_changes`); a human applies it |

Write a checkpoint to `production/session-state/active.md` (create it if absent):
`<!-- STATUS -->` with `Task: Walking skeleton — <journey>`, and a `<!-- CHECKPOINT -->`
naming the current phase. Update it at the end of every phase — a skeleton spans many
sessions, and this file is the recovery mechanism.

---

## Phase 1: Pick the Journey and Define Success

**Pick one journey.** If an argument names it, match it against
`docs/ops/slo.md` `## Critical User Journeys` (or the PRDs). Otherwise propose the
thinnest critical journey that still crosses **every configured layer** — UI → API →
DB, plus the cloud layer that hosts it. For Moa: *"sign up with Kakao → create a
savings goal → see it on the home screen"* — it touches auth, the goals API, the
database, web and mobile; the Toss Payments auto-debit stays out unless the payment
integration is itself the riskiest delivery assumption, in which case its sandbox is
in.

**Several UI surfaces** (web and mobile both configured): the journey runs end to end
on one primary UI surface, and every other configured UI surface carries at least one
step of it against the same staging API (the goal list in the mobile app), so each
surface's build and pipeline is exercised. An API-only product has no UI step — the
journey starts at the API client.

**State the validation question** before building:

> *"Can a new user on staging complete [journey] through [surfaces] → [API operations]
> → [database], deployed by our pipeline, visible in [observability tool], rolled back
> and forward once, with [flag] toggled live — within [N] working days?"*

**Scope discipline:**
- One journey. The happy path plus one error path (e.g. the validation error on a past
  target date). No polish, no second feature.
- **Cut screens and polish, never layers.** A skeleton that skips the database or the
  pipeline proves nothing about the path.
- Time-box: 1–2 weeks. If it cannot fit, the journey is too big — pick a thinner one.
- Scope creep is the main risk here: things feel "almost there" and one more screen is
  tempting. Cut, do not extend.

Present the journey, the layers it crosses, the surfaces, the validation question and
the time-box, and confirm with `AskUserQuestion`:
- `Proceed with this journey (Recommended)` / `Pick a thinner journey` / `Change the surfaces` / `Stop`

---

## Phase 2: Plan per Layer

Spawn `tech-lead` via `Agent` with: the journey and validation question, the
`stack` and `code_roots` lines, and the paths of the architecture doc, control
manifest, tech radar, API contract, data model, migration plans and the journey's UX
specs. Ask for a per-layer plan and **no file writes**:

- per layer: modules and files, the contract operations implemented, the migration
  (Expand only), the health endpoint, structured logging with a correlation ID, the
  metric or trace the journey emits
- the feature flag the journey sits behind (a real flag the product will use, e.g.
  `goals.v2-progress-ring`, or a dedicated `skeleton.enabled`) and where the SDK is
  initialised
- tests: unit tests for domain logic, a contract test per operation, one E2E test of
  the journey
- the CI/CD changes the deploy needs and the rollback method per platform
- risks: components with Knowledge Risk HIGH or MEDIUM in VERSION.md

**Map surfaces to roots** with the table in `.claude/docs/code-root-resolution.md`
§ "Surfaces and roots": `web` → the `web` root, `ios` / `android` / `mobile` → the
`mobile` root, `api` → the `backend` root, `admin` → the `web` root whose last segment
contains `admin`, `infra` → the `cloud` root, migrations →
`stack.layers.data.migrations_dir`, Foundation shared code → the first `shared` root.
Several roots in a layer ⇒ ask which one. Only `detected` / `undeclared` roots ⇒ ask
and suggest `/setup-stack`; print
`WARN: undeclared code roots: <dirs> — declare them with /setup-stack` when any exist.

**Scaffolding a `missing` root**: when a declared root does not exist yet (a fresh
monorepo), the plan names the framework's official scaffolder at the pinned version
(e.g. `pnpm create next-app apps/web`, `npx create-expo-app apps/mobile`,
`npx @nestjs/cli new apps/api`). Ask "May I run `<command>`?" before running it.

**Branch**: propose `feat/walking-skeleton-<journey-slug>`. This skill does not create
branches, commit or push — the user runs `git switch -c <branch>` and later commits,
pushes and merges according to the team's trunk-based flow.

Present the plan and confirm with `AskUserQuestion`:
`Approve the plan (Recommended)` / `Revise the plan` / `Stop`.
Update the session checkpoint.

---

## Phase 3: Implement

Spawn the engineers for the layers the journey crosses, with the approved plan, their
root(s), the story-level rules and the specialist notes:

- `backend-engineer` — the API operations exactly as the contract declares them, the
  Expand migration, the health endpoint, structured logs with correlation IDs, and the
  metric or trace hook
- `frontend-engineer` — the journey's web screens (loading, empty and error states
  included), calling the staging API through the generated client or typed fetch layer
- `mobile-engineer` — the journey's mobile screen(s), auth token handling and the API
  base URL per environment
- `platform-engineer` — wires the feature-flag SDK and any shared logging or tracing
  library the layers use, under the shared root

Order: data and API first, then the UI surfaces in parallel on disjoint roots.

**Production standards apply.** No prototype header, no worktree isolation, no
`prototypes/` directory. Follow the control manifest, the tech radar (nothing from
`## Forbidden Patterns`), `naming.*`, authorization on every endpoint, no secrets in
code, no PII in logs. Each engineer asks "May I write this to [path]?" for its files.
Tests: unit tests for domain logic, a contract test per operation, one E2E test for
the journey that can run against a `BASE_URL` (local now, staging in Phase 8).

**Decisions that always ask** — when a decision below comes up, check whether its
category is in the resolved `automation_always_ask` list; if it is, use
`AskUserQuestion` regardless of `modes.automation`:

| Decision | Category |
|---|---|
| Writing a migration, or applying one to any database (the pipeline applying Expand to staging included) | `db_migrations` |
| CI/CD workflow changes, IaC plan/apply, DNS/CDN, or creating or changing the staging environment | `infra_changes` |
| Creating, reading or wiring staging secrets | `secrets_access` |
| An API field or operation the contract does not declare | `schema_changes` |
| Deleting a tracked file | `file_deletions` |
| Adding a second journey, screen or feature to the skeleton | `scope_changes` |
| Any deploy or flag change in **production** | `production_deploys` — **never in this skill**; staging deploys are not production deploys |

**Local run first.** Before anything reaches the pipeline: `commands.typecheck`,
`commands.test`, and the run-and-observe procedure of `.claude/docs/run-and-observe.md`
against the local stack. Fix locally what can be fixed locally.

**Midpoint checkpoint.** At the midpoint of the time-box, if the journey does not yet
run end to end locally, stop and surface the blocker — the scope is too large or an
architectural assumption is wrong. Say which, and offer: thinner journey, an ADR
revision via `/architecture-decision`, or continue with the risk named.

Update the session checkpoint with what was built today (it feeds the report's effort
log).

---

## Phase 4: Pipeline and Deploy to Staging

Spawn `devops-engineer` (Operations Workflow: assess → propose → verify → record) with
the plan, the CI workflow path, the cloud root and the staging environment facts. It
**proposes** — the exact changes and commands, each with its blast radius, expected
output and rollback — and **never executes** anything that changes shared
infrastructure:

- CI: the jobs `/test-setup` wrote (lint, typecheck, test, e2e) run on the branch
- build: one artifact per deployable (container image, web deployment, API bundle)
- deploy to staging: a pipeline job — never a manual deploy from a laptop
- migrations: the Expand migration applied to staging by the pipeline, before the new
  application version starts
- configuration and secrets from the environment's secret manager — no secret value in
  the repository
- mobile: an internal distribution build produced by the pipeline and pointed at the
  staging API (EAS Build internal distribution, TestFlight internal testing or a Play
  internal testing track)
- staging environment itself, if it does not exist yet: IaC under the cloud root

Writing CI workflow or IaC files is `infra_changes`; ask "May I write this to
`<path>`?" for each (the agent asks for its own files). **A human runs** the push, the
pipeline trigger, any IaC apply and the staging deploy. After the human confirms, the
agent verifies: pipeline run green, artifact identifiers, staging health endpoint 200.

Record the pipeline run, artifact, deploy time and migration step for the report.

---

## Phase 5: Observability Hook-up

Spawn `sre-engineer` (Operations Workflow) with the staging URLs, the journey, the
observability tool named in `docs/architecture/architecture.md` and
`docs/ops/slo.md`. It verifies, and proposes what is missing:

- the health endpoint answers on staging with the deployed version
- logs for one journey run are queryable by correlation ID
- at least one metric (request rate, error rate or p95 of the journey's key
  operation) **or** one trace spanning UI → API → DB is visible
- error tracking receives an error from each deployed layer
- the dashboards and alerts `docs/ops/slo.md` names — created now if cheap, otherwise
  recorded as follow-ups

Record the links for the report's `## Observability` table.

---

## Phase 6: Rollback Rehearsal

`devops-engineer` proposes the rollback for each deployed layer, the way the team will
do it in a real incident — redeploy the previous artifact through the pipeline,
`kubectl rollout undo deployment/<name>`, the previous ECS task definition, promoting
the previous Vercel or Cloudflare deployment — with the expected output. **A human
runs it**, then redeploys the current version. After each step, verify the health
endpoint and the journey.

Record both steps with timestamps in UTC and KST and their results. The Expand
migration is backward compatible, so rolling the application back must not need a
database rollback — if it does, that is a finding. Mobile store builds cannot be
rolled back; the mobile rollback path is server-side (the flag and API compatibility),
and the report says so.

---

## Phase 7: Flag Toggle on Staging

The journey sits behind the flag `platform-engineer` wired in Phase 3. Toggle it on
staging in the flag provider (LaunchDarkly, Unleash, GrowthBook, Flagsmith, Firebase
Remote Config, or the product's own config table) — a human does it, or confirms it
was done — and observe the behaviour change **without a redeploy**: capture the state
before and after (run-and-observe procedure). A staging flag toggle is not a
production deploy.

This item (validation item 5) applies at `standard` and `full` and is N/A at
`minimal` — read the resolved `workflow` line above. If no config block resolved, the
tier is unknown and counts as applicable (absence is not a permissive default).

---

## Phase 8: Validation Checklist

Run the journey end to end on staging: the E2E test pointed at the staging
`BASE_URL`, plus captures per `.claude/docs/run-and-observe.md` (web capture script,
simulator or device screenshots, redacted API snapshots). Ask "May I write this to
`production/qa/evidence/walking-skeleton-<journey-slug>/`?" and retain them there.

Record each of the five items of the Validation → Build gate:

| # | Item | Result |
|---|------|--------|
| 1 | Deployed to staging by the CI/CD pipeline (not by hand) | YES / NO |
| 2 | One critical user journey passes end to end on staging (UI → API → DB) | YES / NO |
| 3 | Health endpoint, logs and at least one metric/trace visible in the observability tool | YES / NO |
| 4 | The staging deploy was rolled back once and redeployed successfully | YES / NO |
| 5 | A feature flag was toggled on staging without a redeploy — standard and full only | YES / NO / N/A |

Every result carries its evidence (pipeline run, E2E run, capture path, link). An item
that **could not be checked** — no staging environment reachable from this session,
the human has not yet run the deploy, no access to the observability tool — gets
Result `—` and Evidence `NOT ASSESSED — <reason>`; it is never written as YES, and
never as NO when nobody looked.

**Verdict** (first matching rule wins):
1. **NOT VALIDATED** — any applicable item is NO. The Validation → Build gate fails a
   built skeleton with any applicable NO at every tier.
2. **NOT ASSESSED** — no NO, but at least one applicable item is `—`. Name each and what
   would make it checkable.
3. **VALIDATED** — every applicable item is YES.

A known failure outranks an unknown; an unknown outranks a pass.

---

## Phase 9: Write the Report

Read `.claude/docs/templates/walking-skeleton-report.md` and fill every section from
what was built and observed — `## Journey`, `## Layers Touched`, `## Pipeline &
Deploy`, `## Observability`, `## Validation`, `## Follow-ups` (including the
day-by-day effort log from the session checkpoints: it is the most honest delivery-rate
data the project will have, and `/sprint-plan` uses it). Directly under the H1 and one
blank line, the report carries `> **Verdict**: VALIDATED`, `> **Verdict**: NOT VALIDATED`
or `> **Verdict**: NOT ASSESSED`. Replace every placeholder with a real observation.

Ask "May I write this to `production/walking-skeleton/report-YYYY-MM-DD.md`?". If a
report with today's date exists, ask whether to overwrite it.

---

## Phase 10: Optional Usability Session → PD-USER-VALIDATION

The gate runs **only when a usability session runs on the skeleton.** Ask with
`AskUserQuestion`: `A usability session ran on the skeleton — review it` /
`No usability session — skip`. For the session itself, `/usability-report` structures
the notes into `production/qa/usability/`; the skeleton report links it under
`### Usability Session (optional)`.

With no session: note "PD-USER-VALIDATION not applicable — no usability session on the
skeleton" and go to Phase 11.

**Review mode check** — apply before spawning PD-USER-VALIDATION:
- `solo` → skip all gates. Note: `[PD-USER-VALIDATION] skipped — Solo mode`
- `lean` → **skip every gate whose ID does not end in `-PHASE-GATE`**. Note: `[GATE-ID] skipped — Lean mode` (here: `[PD-USER-VALIDATION] skipped — Lean mode`)
- `full` → spawn as normal

Spawn `product-director` via `Agent` using gate **PD-USER-VALIDATION**. The `Agent`
prompt tells the agent to read `.claude/docs/director-gates/pd-user-validation.md`
first (this session does not read it).

Pass: report path (usability report, prototype REPORT.md or walking-skeleton report) · hypotheses tested · target segment · brief path

Filled in at run time: `production/walking-skeleton/report-YYYY-MM-DD.md`; the
hypotheses the session tested, as written before it ran; the participants' segment;
`design/product/product-brief.md` (or `design/product/one-pager.md`).

Parse the first line of the reply as `[PD-USER-VALIDATION]: TOKEN` and map it
(`.claude/docs/director-gates.md` § "Standard Verdict Format"):
- **APPROVE** (APPROVE-class) → proceed.
- **CONCERNS** (CONCERNS-class) → surface via `AskUserQuestion`:
  `Revise flagged items` / `Accept and proceed` / `Discuss further`.
- **REJECT** (REJECT-class) → blocking: the value is not landing; surface it before any
  feature sprint builds on the journey.
- A first line that does not parse → CONCERNS-class, with the missing verdict line
  named.

The gate does not change the skeleton's own verdict — VALIDATED is about the delivery
path, the gate is about user value. When they disagree (VALIDATED with a REJECT), say
so explicitly to the user rather than silently keeping either. Record the outcome in the
report's header block — `> **Product Director Review (PD-USER-VALIDATION)**: APPROVED
[date]` / `CONCERNS (accepted) [date]` / `REVISED [date]`, or the skip note — after
"May I write this to `production/walking-skeleton/report-YYYY-MM-DD.md`?".

---

## Phase 11: Summary and Next Steps

Output: the journey, the verdict, the five item results, elapsed time, and the report
path. Update the session checkpoint.

**If VALIDATED** — the delivery path works. Next:
- `/gate-check build` — the Validation → Build gate reads this report
- `/create-epics` and `/create-stories` if not done yet; `/sprint-plan` with the
  skeleton's effort log as velocity input
- `/dev-story` — feature stories now build on the skeleton

**If NOT VALIDATED** — fix every NO before feature sprints:
- item 1 → `/test-setup` or the devops-engineer's pipeline changes
- item 2 → the failing step; `/architecture-decision` if an architectural assumption broke
- item 3 → `/create-architecture` (observability, `docs/ops/slo.md`) with sre-engineer
- item 4 → the rollback method; a skeleton you cannot roll back will not be the last thing that needs rolling back
- item 5 → the flag SDK wiring
- then re-run `/walking-skeleton`

**If NOT ASSESSED** — list each unchecked item and what would make it checkable
(staging access, the human deploy, observability access); re-run the validation phase
once that is in place.

**A run that stops before Phase 8** — a Phase 0 stop, `Stop` at Phase 1 or 2, or a stop at
the Phase 3 midpoint checkpoint — writes no report and ends with Verdict
**NOT ASSESSED**: name the phase it stopped in and what would let it continue.

Close with `AskUserQuestion`:
- Prompt: "Walking skeleton: [verdict]. What next?"
- Options (those that apply):
  - `/gate-check build — run the Validation → Build gate (Recommended when VALIDATED)`
  - `/sprint-plan — plan the first feature sprint`
  - `Fix the failing items and re-run /walking-skeleton (Recommended when NOT VALIDATED)`
  - `Stop here`

---

## Important Constraints

- **Production code, not a prototype.** It lives on a feature branch in the resolved
  code roots, follows every engineering rule and is reviewed and merged. It never lives
  under `prototypes/`, carries no prototype header and runs in no isolated worktree.
- **Nothing reaches production.** Staging only; deploys, IaC applies and flag toggles
  are run by a human; agents never execute commands that change shared infrastructure,
  a shared database or secrets.
- **Deployed by the pipeline.** A manual deploy does not satisfy item 1, however quick.
- **Cut scope, not layers.** One journey, thin, through everything configured.
- **Time-boxed.** 1–2 weeks; the midpoint checkpoint stops a skeleton that is turning
  into a feature.
- **Staging is not production load.** The skeleton validates the path, not capacity —
  `/load-test` and `/perf-profile` measure the budgets in Hardening.
- **Evidence is retained** — the report under `production/walking-skeleton/`, captures
  under `production/qa/evidence/`, never only under `production/session-logs/`.

---

## Collaborative Protocol

**Applies in `collaborative` mode.** For `guided` and `autonomous` modes, see
`.claude/docs/automation-modes.md`; the always-ask categories prompt in every mode.

- **Question → Options → Decision → Draft → Approval** at every phase: the journey, the
  plan, each pipeline change, the report.
- "May I write this to `<path>`?" before every file this skill writes (report, captures,
  checkpoint); engineers and the devops-engineer ask for their own files.
- **Humans run what touches shared environments** — the agent proposes commands with
  their blast radius and rollback; the user runs them and reports back.
- **Surface, do not absorb** — an architectural surprise becomes a finding and an ADR
  proposal, not a quiet workaround.
- Never commit, push or merge — suggest the commands; the user runs them.
