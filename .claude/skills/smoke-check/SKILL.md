---
name: smoke-check
description: "Critical-path smoke gate (boot, health, auth, core journey, integrations, migrations) before QA hand-off."
argument-hint: "[sprint | quick | --surface web|ios|android|api|all]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash, AskUserQuestion, Bash(bash "*/.claude/skills/smoke-check/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,qa.level,testing.strict,surfaces,stack`

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

# Smoke Check

This skill is the gate between "implementation done" and "ready for QA hand-off".
It runs the automated suite, checks for test coverage gaps, drives the critical
path of the running product — build and boot, health endpoint, sign-in, the core
journey, the third-party integrations and the database migrations — and produces a
report with one verdict.

The rule is simple: **a build that fails the smoke check does not go to QA.**
Handing a broken release candidate to QA spends their day on a build nobody
should have tested, and teaches everyone that red means "probably fine".

**Output:** `production/qa/smoke-YYYY-MM-DD.md` — the only file this skill writes.

**Environment.** The smoke check runs against **staging** — the environment QA
will test. At `qa.level: minimal` it may run against staging or a local build; the
report always says which, because the phase gates state which environment each
tier accepts.

**`qa.level`** (resolved above): at `minimal`, the smoke check is **optional** —
if run, a FAIL is advisory and never blocks hand-off, and a local run is
acceptable; at `standard`, it is required before a phase transition and on every
release candidate; at `full`, before every QA hand-off and on every release
candidate. This sits in front of the Phase 6 `testing.strict.config` resolution
(which only matters once a smoke run gates). Distinct axis from `workflow`.

At `minimal`, **tests are waived here too**, as they are in `/dev-story` and
`/story-done`: a project with no product tests does not end the run (Phase 1), the
suite is `NOT CHECKED` when there is nothing to run (Phase 2), and a Logic,
Integration or E2E story with no test is `WAIVED`, not MISSING (Phase 3). Build,
boot, health, the critical journeys, the integrations, the UI captures and the
migration floor still decide the verdict, so PASS stays reachable on the minimal
path — the Hardening → Launch floor needs it. The waiver relaxes what must exist,
never what must work: a product test that exists and fails is still a FAIL.

> **Hand-off is one axis; the phase gates are another.** Whatever `qa.level` says
> about QA hand-off, `/gate-check` treats the smoke report as the **floor at every
> tier**: the Build → Hardening gate needs PASS or PASS WITH WARNINGS, the
> Hardening → Launch gate needs PASS on the release candidate. An advisory FAIL here
> still fails those gates.

---

## Parse Arguments

Arguments can be combined: `/smoke-check sprint --surface ios`

**Base mode** (first argument, default: `sprint`):
- `sprint` — full smoke check against the current sprint's stories
- `quick` — skip the coverage scan (Phase 3) and Batch 4; use for a rapid
  re-check after fixing a specific failure. A quick report is capped at
  PASS WITH WARNINGS and says why, so it can never stand in for a full run at a
  gate that needs PASS.

**Surface flag** (`--surface`, default: none):
- `--surface web` — add the web batch (browsers, mobile viewport, session, console errors)
- `--surface ios` — add the iOS batch (fresh install on the minimum OS, deep links, push, lifecycle)
- `--surface android` — add the Android batch (the same, plus system back)
- `--surface api` — add the API batch (authentication, authorization, pagination, rate limits)
- `--surface all` — every surface in `platform.surfaces`; output a per-surface verdict table

Without `--surface`, Batches 1–4 still cover **every** surface in
`platform.surfaces` at the level of boot and critical journeys; the flag adds
each surface's own batch. A `--surface` value that is not in `platform.surfaces`
is reported and ignored. If `platform.surfaces` is unset
(`(unset -- ask which surfaces ship)`), ask which surfaces ship before Phase 1 —
unset is not "web only".

---

## Phase 1: Detect Test Setup

Before running anything, understand the environment:

0. **Stack coherence**: run `bash .claude/scripts/project-coherence.sh`.

   It compares what `project.yaml` declares about the stack with
   `docs/stack-reference/VERSION.md`, the runtime version files, the framework
   dependency in each layer's manifest (under the layer paths the `stack` line
   prints after `@`), the lockfile, and the `package.json` scripts that
   `commands.*` name. This runs first because a `commands.test` or
   `commands.build` naming a script that does not exist would otherwise read as a
   broken build rather than broken config.

   Report every `MISMATCH:` line in the report's Environment section;
   `UNCHECKED:` lines are not agreement — name their reasons. The script prints
   `COMPARISONS:` before its rows, always exits 0 and never decides the verdict.

1. **Test files check**: verify that **product** tests exist — not merely that a
   test directory does. Look where `testing.patterns` in `project.yaml` says tests
   live (read it with `Read`); if it is unset, use the `tests/**` convention plus
   the co-located forms `**/*.test.*`, `**/*.spec.*`, `**/__tests__/**`, and say
   so: `testing.patterns unset — using the tests/** convention`. **Do not count**
   the scaffold's example files (basename containing `example`, written by
   `/test-setup`) or `tests/e2e/capture.spec.ts` — they prove a runner, not the
   product.

   If no product test is found, the outcome depends on `qa.level`:

   - At `standard` or `full`, **deliver a NOT ASSESSED verdict — do not merely
     stop.** "Smoke check: **NOT ASSESSED — no product tests found** (searched:
     `<patterns>`). Run `/test-setup` to scaffold the runners, or point me at where
     tests live." Then stop.
   - At `minimal`, tests are waived, so no product tests is the configured posture,
     not a hole. Record `NOT CHECKED — no product tests (qa.level minimal: tests
     waived)` in the report's Automated Tests section, skip Phase 2, and continue
     with Phase 3 and the smoke batches. The waiver covers the tests only: a
     project with no build still lands NOT ASSESSED (`commands.build` unset) or
     FAIL in Batch 1. Stopping here instead would make the smoke floor of the
     Build → Hardening and Hardening → Launch gates unreachable at `minimal`.

   > A bare halt is the wrong shape here.
   > This is the state with the **least** information about build health, so it is
   > the last one that should exit without a verdict: the caller gets no
   > machine-readable outcome, and "the skill said nothing" is easy to read as
   > "nothing was wrong". Replacing a *wrong* verdict with *no* verdict is not an
   > improvement either — the honest result is the one that names what could not
   > be established.

   > **Do not gate on the test directory existing.** `/test-setup` creates the
   > test folders with example tests, so the tree — and even a green test run — is
   > present on any project that ran setup, whether or not a single product test
   > was ever written. Count product test files instead. A fixture with no build
   > and nothing but scaffold examples would otherwise pass this step and go on to
   > score **PASS WITH WARNINGS**.

2. **CI check**: check whether a CI workflow (`.github/workflows/*.yml`,
   `.github/workflows/*.yaml`, `.gitlab-ci.yml`, `bitbucket-pipelines.yml`,
   `azure-pipelines.yml`) runs the tests. Note in the report whether CI is
   configured.

3. **Stack and commands**: take the layers from the `stack` line (framework,
   version and the layer paths printed after `@`). Read from `project.yaml` with
   `Read` the commands this skill executes — `commands.build`, `commands.test`,
   `commands.e2e`, `commands.smoke`, `commands.run`, `commands.dev` — and
   `testing.framework` (named in the report). A command is a string, or an OS map
   read for the current OS (`uname`: `Darwin` → `macos`, `Linux` → `linux`,
   Windows → `windows`), falling back to `default`. **Unset commands are never
   guessed** — a guessed build command either fails loudly or, worse, builds the
   wrong app of a monorepo and passes.

4. **Smoke scope**: read the `## Smoke Test Scope` section of the newest QA plan
   (`production/qa/qa-plan-*.md`, most recent by date in the name). If there is no
   QA plan, or its section is empty, read the `## Smoke Test Scope` section of
   `.claude/docs/templates/test-plan.md`. If that yields nothing usable, use the
   standard batches below as they stand. Also read `docs/ops/slo.md`
   `## Critical User Journeys` when it exists — those journeys are always in scope.

5. **QA plan check**: note the QA plan path found in step 4; it is also used in
   Phase 3. If none: "No QA plan found. Run `/qa-plan` before smoke-checking for
   best results."

6. **Target environment**: ask (one `AskUserQuestion`, **major**) which
   environment this run checks and for its base URL(s) — web origin, API base URL
   and the health route — and which build is under test (commit SHA, release
   candidate version, iOS/Android build numbers). Options: `[A] Staging` ·
   `[B] Local build` · `[C] Other preview environment`. At `qa.level` `standard`
   or `full`, choosing local means the run is informational only: the verdict
   will be NOT ASSESSED with the reason "staging not checked" (see Phase 5).

Report findings before proceeding: "Environment: [staging — URL | local]. Build
under test: [SHA / version / build numbers]. Stack: [layers]. Product tests:
[N files | none — tests waived at qa.level minimal]. CI configured: [yes / no].
QA plan: [path / not found]. Checklist source: [path]."

---

## Phase 2: Run the Automated Suite

**At `qa.level: minimal`, the suite is waived when there is nothing to run** — no
product tests (Phase 1), or `commands.test` unset and the user has none. Record the
status `NOT CHECKED — no product tests (qa.level minimal: tests waived)` or
`NOT CHECKED — no test command (qa.level minimal: tests waived)` and go to Phase 3.
When product tests and a command both exist, run them as below at every
`qa.level`: a failure is a FAIL, and a suite that exists but could not run is
NOT RUN.

Run `commands.test` via Bash from the repository root, with the Bash tool's
timeout set generously (10 minutes). If `commands.test` is unset, ask for the
command — do not invent one — and if the user has none, the suite is **NOT RUN**
(at `standard` or `full`; at `minimal` it is waived, above).

**A timeout is a FAILURE, never a pass** — the run never completed and nothing
was verified. A runner that hangs is a finding.

Parse the runner output (or the JUnit XML it wrote to `test-results/`) and
extract:
- Total tests run
- Passing count
- Failing count
- Names of any failing tests (up to 10; if more, note the count)
- Any crash or error output from the runner itself (a module that did not load,
  a database the integration tests could not reach)

**If the runner is not available in this environment** (dependencies not
installed, the toolchain missing, the disposable database the integration tests
need is not running), report clearly:

"Automated tests could not be executed — [reason]. Status will be recorded as
NOT RUN. Confirm the result from your IDE or from the CI run on this commit.
Until you do, the verdict is NOT ASSESSED — not FAIL, and not a pass either:
nothing has been observed about this build yet."

Do not treat NOT RUN as an automatic FAIL. Record it, and let the developer's
confirmation resolve it (ask with `AskUserQuestion`: `[A] CI passed on this
commit` · `[B] CI failed on this commit` · `[C] I can't confirm`). Until that
confirmation arrives the verdict is **NOT ASSESSED** (see the verdict rules in
Phase 5), which ranks above both pass values and below FAIL. An unrun suite is not
a healthy build; it is an unknown one, and the two need different follow-ups. A
CI run the developer reports as failed counts as a FAIL of the suite.

---

## Phase 3: Check Test Coverage

Draw the story list from, in priority order:
1. The QA plan found in Phase 1 (its `## Automated Tests Required` section lists
   the expected test per story)
2. `production/sprint-status.yaml` and the newest sprint plan
   `production/sprints/sprint-*.md` — the stories of the current sprint
3. If the `quick` argument was passed, skip this phase entirely and note:
   "Coverage scan skipped — run `/smoke-check sprint` for full coverage
   analysis."

For each story in scope (`production/epics/<epic-slug>/story-NNN-<slug>.md`):

1. Read its header: `> **Type**:` (`Logic | Integration | UI | E2E | Config`),
   `**PRD**:` (the feature slug is the PRD stem, `design/prd/<feature-slug>.md`)
   and `**Migration**:`.
2. Search the test locations from Phase 1 for files whose path or name contains
   the feature slug, the story slug, or a closely related term; E2E stories look
   under `tests/e2e/<journey>/` (or the matching pattern).
3. Check the story file itself for a test reference or a `## Test Evidence`
   section, and `production/qa/evidence/<story-slug>/` for retained evidence.

Assign a coverage status to each story:

| Status | Meaning |
|--------|---------|
| **COVERED** | A test file was found matching this story's feature and scope (Logic, Integration, E2E) |
| **MANUAL** | UI story; component tests or retained screenshots were found in `production/qa/evidence/<story-slug>/` |
| **MISSING** | At `qa.level` `standard` or `full`, a Logic, Integration or E2E story with no matching test; at every `qa.level`, a UI story with neither component tests nor evidence (the run-and-observe capture is never waived), or **any** story whose `**Migration**` is not `None` without `production/qa/evidence/<story-slug>/migration-dry-run.log` (the migration floor) |
| **WAIVED** | At `qa.level: minimal`, a Logic, Integration or E2E story with no matching test — tests are waived at this level |
| **EXPECTED** | Config story — no test file required; this smoke check is its evidence |
| **UNKNOWN** | Story file missing or unreadable |

MISSING entries are advisory gaps for this verdict. They do not cause a FAIL
verdict but must appear prominently in the report and must be resolved before
`/story-done` can fully close those stories.

WAIVED rows stay in the table so the waiver announces itself, but they are not
gaps: they never count as MISSING and never lower the verdict.

---

## Phase 4: Run the Smoke Batches

Tailor Batches 2 and 3 to the product's actual journeys and integrations — from
the smoke scope, `docs/ops/slo.md` and the current sprint's stories. Replace every
bracketed placeholder with a real journey name.

**Name the source you used in the report**, on its own line — *"Checklist source:
`production/qa/qa-plan-sprint-07-2026-11-02.md` § Smoke Test Scope"*, or
*"Checklist source: `.claude/docs/templates/test-plan.md` § Smoke Test Scope — no
QA plan"*, or *"Checklist source: standard batches — neither source had a Smoke
Test Scope"*. `/gate-check` validates a smoke report's claims against the repo,
and it cannot weigh them without knowing what the checklist was drawn from.

**Automation first, then the human.** Every check runs automatically where a
command or tag exists; `AskUserQuestion` batch-verifies the rest. Keep to at most
four question calls for Batches 1–4 (up to four questions per call, up to four
options each), plus one per requested surface. For every selected FAILED item,
ask the user to describe what broke before generating the report. Record each
answer verbatim for the Phase 5 report.

This skill never calls a third-party service, runs a database migration or
deploys anything itself: sandbox payments, notification sends and migration
state are observed through the product's own tests or confirmed by the developer.

### Batch 1 — Build & boot (always run)

1. **Build**: run `commands.build` via Bash (local build, or the build of the
   commit being deployed). Non-zero exit ⇒ FAIL. `commands.build` unset ⇒ the
   check could not be executed.
2. **Build under test is the build deployed** (staging): read the version or
   commit the health or version endpoint exposes (`/health`, `/version`, a
   `x-app-version` header) and compare it with the build under test from Phase 1.
   A different commit ⇒ the check could not be executed on the build under test
   (NOT ASSESSED, "staging runs <sha>, not <sha>"). Nothing exposes a version ⇒
   ask the developer to confirm which build staging runs.
3. **Boot** (local): start `commands.run` (else `commands.dev`) with the Bash
   tool's background mode, and stop it when the batches end. Staging: no boot step.
4. **Health endpoint**: `curl -fsS --retry 30 --retry-delay 2 --retry-all-errors --max-time 5 <api-base>/<health-route>`
   must answer 200 (and, when the body carries dependency status — database,
   cache, queue — each dependency must be up). Find the route in the backend
   layer's paths (Grep for `/health`, `/healthz`, `/readyz`, `@nestjs/terminus`,
   Spring Actuator `/actuator/health`); none ⇒ ask for it.
5. **Web and mobile boot** (per surface in `platform.surfaces`), batch-verified:

```
question: "Build & boot — select any items that FAILED (leave all unselected if everything passed):"
multiSelect: true
options:
  - "Web: the app does not load, shows an error page or a blank screen"
  - "iOS: the build under test crashes or hangs before the first screen"
  - "Android: the build under test crashes or hangs before the first screen"
  - "A boot check could not be run (no device, no build) — describe after"
```

Offer only the options for the surfaces that ship.

### Batch 2 — Critical journeys (always run)

1. **Automated**: run the smoke subset — `commands.smoke` when it is set, else
   `commands.e2e` filtered to the smoke tag (Playwright `--grep @smoke`, Maestro
   `--include-tags=smoke`, pytest `-m smoke`) — against the target environment
   (`E2E_BASE_URL=<staging web origin>` for the Playwright config `/test-setup`
   writes). Failures ⇒ FAIL; list the failing journeys with their trace or
   screenshot paths. Neither command set ⇒ no automated journeys; every journey
   goes to the manual batch.
2. **Manual**, for the journeys the automated subset does not cover — sign-in
   first, then the core journey of each surface:

```
question: "Critical journeys — select any items that FAILED (leave all unselected if everything passed):"
multiSelect: true
options:
  - "Sign-in ([methods, e.g. email, Kakao, Naver, Apple]) — FAILED"
  - "[Core journey, e.g. create a savings goal] — FAILED"
  - "[Journey changed this sprint] — FAILED"
  - "Regression in a previous sprint's journey — FAILED"
```

### Batch 3 — Integrations (always run, including `quick`)

A migration that did not apply is a failed deploy, not a slow one, so this batch
runs in every mode.

1. **Migrations applied**: the evidence is either the Phase 2 suite when its
   integration tests apply every migration to a throwaway database
   (Testcontainers, a `docker compose` service, CI `services:`), or the deploy log
   of the staging release showing each pending migration applied. Say which one
   the report relies on.
2. **Third-party sandboxes**, batch-verified (automated sandbox tests, when the
   suite has them, answer first):

```
question: "Integrations — select any items that FAILED (leave all unselected if everything passed):"
multiSelect: true
options:
  - "Payments sandbox ([provider, e.g. Toss Payments test keys]): registration or a test charge — FAILED"
  - "Notifications sandbox ([push / email / SMS / 알림톡 test sender]) — FAILED"
  - "Migrations: not all applied on the target database — FAILED"
  - "An integration could not be checked (no sandbox credentials, no staging access) — describe after"
```

An integration the product does not have yet is **N/A** — the user says so and the
report records `N/A — <reason>`.

### Batch 4 — Non-functional spot check (skipped by `quick`)

Compare what the target environment shows now with the budgets in `project.yaml`
(`performance.api_p95_ms`, `performance.error_rate_pct`, and for web
`performance.lcp_ms` / `performance.inp_ms` / `performance.cls`; for mobile
`performance.crash_free_pct` — read with `Read`). The numbers come from a metrics
source the developer can read (an APM or dashboard — Datadog, Grafana, Sentry,
CloudWatch — or a recent `/load-test` smoke-profile report
`production/qa/load/load-test-smoke-*.md`); ask for them:

```
question: "Non-functional spot check — what does the metrics source show for the critical endpoints and screens?"
multiSelect: false
options:
  - "Within the budgets (enter p95 and error rate after)"
  - "Over a budget (enter which and the numbers after)"
  - "No metrics source exists for this environment yet"
  - "Not checked this session"
```

- Within budgets ⇒ PASS. Over a budget ⇒ a warning (whether a breach blocks is
  decided by the phase gates; this skill reports the number).
- No metrics source ⇒ `NOT CHECKED — non-functional spot check (no metrics source)`,
  a warning.
- "Not checked this session" ⇒ offered and skipped — see NOT ASSESSED below.

### Surface batches *(run only if `--surface` was provided)*

Read `platform.browsers`, `platform.min_os.ios` and `platform.min_os.android`
from `project.yaml` with `Read` for the option text.

**Web** (`--surface web` or `all`):
```
question: "Web — select any items that FAILED (leave all unselected if everything passed):"
multiSelect: true
options:
  - "Supported browsers ([platform.browsers]) — layout or script error (describe after)"
  - "Mobile viewport (390 px wide) — layout broken or controls unreachable (describe after)"
  - "Session — refresh, sign-out/sign-in or an expired session lands in the wrong state (describe after)"
  - "Console errors or failed network requests on the core journey (describe after)"
```

**iOS** (`--surface ios` or `all`):
```
question: "iOS — select any items that FAILED (leave all unselected if everything passed):"
multiSelect: true
options:
  - "Fresh install on the minimum iOS ([platform.min_os.ios]) — crash or blank screen (describe after)"
  - "Deep link opens the right screen, signed in and signed out (describe after)"
  - "Push permission prompt and a test notification (describe after)"
  - "Background → foreground keeps the session and state (describe after)"
```

**Android** (`--surface android` or `all`):
```
question: "Android — select any items that FAILED (leave all unselected if everything passed):"
multiSelect: true
options:
  - "Fresh install on the minimum Android ([platform.min_os.android]) — crash or blank screen (describe after)"
  - "Deep link / App Link opens the right screen, signed in and signed out (describe after)"
  - "System back button and gesture navigation behave as specified (describe after)"
  - "Notification permission (Android 13+) and a test notification (describe after)"
```

**API** (`--surface api` or `all`) — run these automatically with `curl` against the
API base URL where a test token is available, else batch-verify:
```
question: "API — select any items that FAILED (leave all unselected if everything passed):"
multiSelect: true
options:
  - "Missing or expired token is rejected with 401 and a problem+json body (describe after)"
  - "Another user's resource is refused (403/404) — no object-level authorization bypass (describe after)"
  - "A list endpoint paginates and its limit is enforced (describe after)"
  - "Rate limiting answers 429 with retry information (describe after)"
```

---

## Phase 5: Generate Report

Assemble the full smoke check report:

````markdown
# Smoke Check Report — [YYYY-MM-DD]

> **Verdict**: [PASS | PASS WITH WARNINGS | NOT ASSESSED | FAIL]

**Date**: [date]
**Environment**: [staging — <web origin>, <API base URL> | local — <URLs> | preview — <URL>]
**Build under test**: [commit SHA · version / release candidate · iOS build · Android build]
**Sprint**: [sprint name / number, or "Not identified"]
**Stack**: [the stack line, layers only]
**Test framework**: [testing.framework value, or "unset"]
**Surfaces**: [platform.surfaces; surface batches run: …]
**QA Plan**: [path, or "Not found — run /qa-plan first"]
**Checklist source**: [path § Smoke Test Scope | standard batches]
**Argument**: [sprint | quick] [--surface …]
**Gate level**: [blocking | advisory] — [reason: testing.strict.config=<v> | testing.strict.config unset ⇒ blocking | qa.level minimal ⇒ advisory]

---

## Environment

[Stack coherence: the `COMPARISONS:` line from project-coherence.sh; `MISMATCH:` lines, or "no mismatches"; `UNCHECKED:` lines with their reasons]
[Health endpoint: <route> → <status>; dependencies: <db/cache/queue status>; reported version: <v>]
[NOT CHECKED lines for anything this run could not reach]

---

## Automated Tests

**Status**: [PASS ([N] tests, [N] passing) | FAIL ([N] failures) | FAIL (timed out) |
NOT RUN ([reason]) — [confirmed by developer: CI passed / unconfirmed] |
NOT CHECKED — no product tests (qa.level minimal: tests waived) |
NOT CHECKED — no test command (qa.level minimal: tests waived)]

[If FAIL, list failing tests:]
- `[test name]` — [brief failure description from runner output]

---

## Smoke Batches

### Batch 1 — Build & Boot
- [x] Build (`[commands.build]`) — PASS
- [x] Build under test deployed on staging (reported version [v]) — PASS
- [x] Health endpoint `[route]` — 200, database up — PASS
- [x] Web loads — PASS
- [ ] iOS build [n] — FAIL: [user's description]

### Batch 2 — Critical Journeys
- Automated smoke subset: [command] — [N passed, N failed]
- [x] Sign-in ([methods]) — PASS
- [x] [Core journey] — PASS

### Batch 3 — Integrations
- Migrations: [PASS — evidence: <integration run on a throwaway database | staging deploy log>]
- [x] [Payments sandbox] — PASS
- [-] [Notifications] — N/A: [reason]

### Batch 4 — Non-Functional Spot Check
- [API p95: <n> ms (budget <n> ms) · error rate: <n>% (budget <n>%) — within budget |
  over budget: … | NOT CHECKED — non-functional spot check (no metrics source) |
  not checked this session | skipped (quick)]

---

## Test Coverage

| Story | Type | Test / Evidence | Coverage Status |
|-------|------|-----------------|----------------|
| [title] | Logic | `[apps/api/src/goals/goal-limits.test.ts]` | COVERED |
| [title] | UI | `production/qa/evidence/[story-slug]/01-[state]-desktop.png` | MANUAL |
| [title] | Integration | — | MISSING ⚠ |
| [title] | Logic | — (qa.level minimal: tests waived) | WAIVED |
| [title] | Config | — | EXPECTED |

**Summary**: [N] covered, [N] manual, [N] missing, [N] waived, [N] expected, [N] unknown.

---

## Missing Test Evidence

Stories that must have test evidence before they can be marked Complete via
`/story-done`:

- **[story title]** (`[path]`) — [Logic story has no test file | UI story has no
  component test or capture | migration without `migration-dry-run.log`]. Expected
  location: `[path per testing.patterns | production/qa/evidence/<story-slug>/]`

[If none:] "All Logic, Integration and E2E stories have test coverage." [At
qa.level minimal:] "No MISSING rows — Logic, Integration and E2E tests are waived at
qa.level minimal; UI captures and migration dry-run logs are present."

---

## Surface-Specific Results *(only if `--surface` was provided)*

| Surface | Checks Run | Passed | Failed | Surface Verdict |
|---------|-----------|--------|--------|-----------------|
| web | [N] | [N] | [N] | PASS / FAIL |
| ios | [N] | [N] | [N] | PASS / FAIL |
| android | [N] | [N] | [N] | PASS / FAIL |
| api | [N] | [N] | [N] | PASS / FAIL |

Any surface with one or more FAIL checks contributes to the overall FAIL verdict.

---

## Verdict: [PASS | PASS WITH WARNINGS | NOT ASSESSED | FAIL]

[The rule that decided it, and every reason that applied.]
````

**Verdict rules** — first matching rule wins:

**FAIL** if ANY of:
- The automated suite ran and reported one or more failures, or timed out, or the
  developer reports that CI failed on this commit
- Any Batch 1 check returned FAIL (build, boot, health endpoint)
- Any Batch 2 check returned FAIL (sign-in, a critical journey, a regression)
- Any Batch 3 check returned FAIL (payments or notification sandbox, migrations)
- Any surface batch check returned FAIL

**NOT ASSESSED** if ANY of:
- The automated suite is **unconfirmed NOT RUN** — nobody has reported a result
  (a suite waived at `qa.level: minimal` is `NOT CHECKED`, not NOT RUN, and does
  not trigger this)
- A Batch 1, 2 or 3 check could not be executed (no build command, environment
  unreachable, no device, no sandbox access) as opposed to executing and failing
- The build deployed on staging is not the build under test
- At `qa.level` `standard` or `full`, the run checked a local build, not staging
  ("staging not checked")
- **Any story's coverage row is `UNKNOWN`** (Phase 3: story file missing or
  unreadable). A story nobody could read is not a story with no gaps — without
  this line, a run where *every* row is UNKNOWN and the suite passes matches
  **PASS**, because PASS only requires "no MISSING entries"
- **Batch 4 was offered and skipped** ("Not checked this session"). It is not a
  FAIL, not an execution failure, and not "PASS or N/A", so without this line it
  matches no rule at all and renders as `[-]` beside a PASS

**PASS WITH WARNINGS** if ALL of:
- The automated suite PASSED, or is NOT RUN **and the developer has confirmed that
  CI passed on this commit**, or — at `qa.level: minimal` only — is `NOT CHECKED`
  because tests are waived
- All Batch 1, 2 and 3 checks PASS or N/A
- And one or more of: a story has MISSING test evidence (a Logic, Integration or
  E2E test, a UI capture, or the migration floor); Batch 4 is over a budget or
  `NOT CHECKED` (no metrics source); the run was `quick`

**PASS** if ALL of:
- The automated suite PASSED, or — at `qa.level: minimal` only — is `NOT CHECKED`
  because tests are waived
- All checks in all batches PASS or N/A, and Batch 4 is within the budgets
- No MISSING test evidence entries (WAIVED rows are not MISSING)
- The run was not `quick`

**Why the waiver reaches PASS at `minimal`.** `/gate-check` keeps the smoke report
as the floor at every `qa.level`, and the Hardening → Launch gate needs PASS on the
release candidate. The minimal path writes no product tests by design, so if waived
tests counted against the verdict, the floor could never be met there. What the
waiver does not touch — build, boot, health, the critical journeys, the
integrations, the UI captures, the migration floor and any product test that
exists — decides the verdict exactly as at `standard`.

**`NOT ASSESSED` — the build nobody could check.** Rank: it **outranks PASS and
PASS WITH WARNINGS** and **ranks below FAIL**. A suite that never ran has not
shown the build is healthy; a suite that ran and failed is the more actionable
finding and must not be demoted behind one that did not run.

This is deliberate about where unconfirmed `NOT RUN` lands. The rule — **never
treat NOT RUN as an automatic FAIL** — still holds: NOT ASSESSED is not a FAIL,
and it ranks below one. What it prevents is an unrun suite resolving to a *pass*
verdict while waiting for a confirmation that may never come. Confirmed NOT RUN
(the developer reports the CI result on this commit) still lands at PASS WITH
WARNINGS at best, because somebody did look — but not at PASS, because this skill
did not.

---

## Phase 6: Write and Gate

Present the full report in conversation, then ask:

"May I write this to `production/qa/smoke-YYYY-MM-DD.md`?"

Write only after approval. If a report for today already exists, show its verdict
and ask whether to replace it — never overwrite silently. The report lives under
`production/qa/`; nothing from this run (runner output, screenshots, logs) is
ever written under `production/session-logs/`, which is gitignored and never
counts as evidence.

**First apply `qa.level` (resolved above).** At `qa.level: minimal`, a FAIL is
**advisory** regardless of `testing.strict.config` — skip the resolution below and
deliver the advisory-FAIL outcome (the smoke check is optional at minimal and never
blocks hand-off; the phase gates still require their floor). Otherwise:

**Resolve the gate enforcement level.** A FAIL verdict either *blocks* QA
hand-off or is *flagged while hand-off proceeds*, governed by the
`testing.strict` line **of the resolved-config block at the top of this skill**
(which merges `project.local.yaml` over `project.yaml` — read that block, not the
file, or a developer's local override is silently ignored):

1. Take `config=` from the `testing.strict:` line. If its value is `true` →
   blocking; if `false` → advisory; `unset` → fall through.
2. Else default to **blocking** — an unset `testing.strict.config` keeps the
   smoke check's FAIL gate blocking. Smoke check is a build-health gate, so its
   unset default is strict even though the `config` test type defaults to
   advisory elsewhere. The reciprocal carve-out is recorded in
   `.claude/skills/story-done/SKILL.md` and `.claude/docs/coding-standards.md`,
   which own the per-story evidence table.

Only `true` and `false` are valid values. The resolver drops any other value
(`maybe`, `1`, `yes`) and reports it on its notes line; when the notes line names a
dropped `testing.strict.config`, surface that to the user and treat the key as
unset (step 2).

After writing, deliver the gate verdict:

**If verdict is FAIL and the gate is blocking:**

"The smoke check failed. Do not hand off to QA until these failures are
resolved:

[List each failing automated test or smoke check with a one-line description]

Fix the failures and run `/smoke-check` again (or `/smoke-check quick` for a
rapid re-check) before QA hand-off."

**If verdict is FAIL and the gate is advisory** (`testing.strict.config: false`,
or `qa.level: minimal`):

"The smoke check failed, but the gate is advisory ([reason]) — QA hand-off is not
blocked. Resolve these before release:

[List each failing automated test or smoke check with a one-line description]

QA hand-off: run `/team-qa`, or share the QA plan
`production/qa/qa-plan-[sprint-slug]-[date].md` with the qa-engineer agent.
Re-run `/smoke-check` once the failures are fixed — the phase gates will not
accept this report."

**If verdict is NOT ASSESSED:**

"The smoke check could not establish build health — it did not fail, it did not
run. Do not hand off to QA on this result:

[Name each check that could not execute, and why: suite unconfirmed NOT RUN,
build command unset, staging unreachable, staging runs a different build, no
device, no sandbox access, local run at qa.level standard/full]

[For each, the one thing that would make it runnable — e.g. 'confirm the CI
result for this commit', 'set commands.build with /settings', 'deploy the release
candidate to staging', 'boot the iOS simulator'.]

Re-run `/smoke-check` once any of those is resolved."

This outcome is **not governed by `testing.strict.config`**. That setting decides
whether a *failure* blocks hand-off; it has nothing to say about a check that
never produced a result, and reading an unrun check as advisory-therefore-fine is
the exact substitution this verdict exists to prevent. Say what could not be
checked and let the user decide — do not resolve it to either pass or FAIL on
their behalf.

**If verdict is PASS WITH WARNINGS:**

"Smoke check passed with warnings. The build is ready for manual QA.

Advisory items to resolve before running `/story-done` on affected stories:
[list MISSING test evidence entries, the Batch 4 warning, the quick-mode cap]

QA hand-off: run `/team-qa`, or share the QA plan with the qa-engineer agent."

**If verdict is PASS:**

"Smoke check passed cleanly. The build is ready for manual QA.

QA hand-off: run `/team-qa`, or share the QA plan with the qa-engineer agent."

Close with `AskUserQuestion`, offering only the steps that apply:
- `/team-qa` — hand-off: strategy, cases, execution and sign-off (PASS, PASS WITH WARNINGS, advisory FAIL)
- `/bug-report` — one report per failure found (FAIL)
- `/test-setup` — when no product tests or no runner were found
- `/smoke-check quick` — re-check after fixing a specific failure
- `/regression-suite update` — when a failure was a regression without a test
- `/gate-check hardening` or `/gate-check launch` — when this report is the missing floor
- Stop here

---

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and
`autonomous` modes, see `.claude/docs/automation-modes.md` — the rules below
describe what collaborative mode requires, not universal behavior.

- **Never treat NOT RUN as automatic FAIL** — record it as NOT RUN and let
  the developer confirm status. Unconfirmed NOT RUN yields **NOT ASSESSED**, not
  FAIL — and not a pass verdict either.
- **Never auto-fix failures** — report them and state what must be resolved.
  Do not edit source code, test files or configuration.
- **Never act on shared systems** — no deploys, no migrations, no third-party
  calls from this skill; sandbox results and migration state come from the
  product's tests, logs or the developer.
- **Commands are read, never guessed** — an unset `commands.*` value is asked for,
  or the check it drives is recorded as not executed.
- **PASS WITH WARNINGS does not block QA hand-off** — it records advisory
  gaps for `/story-done` to follow up on. It does not satisfy the Launch gate.
- **`quick` argument** skips Phase 3 (coverage scan) and Batch 4, and caps the
  verdict at PASS WITH WARNINGS. Use it for rapid re-checks after fixing a
  specific failure.
- Use `AskUserQuestion` for all manual smoke check verification.
- **Evidence stays on disk, outside gitignored paths** — the report under
  `production/qa/`; never `production/session-logs/`.
- **Never write the report without asking** — Phase 6 requires explicit
  approval before the file is created or replaced.
