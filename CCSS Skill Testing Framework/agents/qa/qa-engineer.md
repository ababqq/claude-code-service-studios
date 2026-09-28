# Agent Spec: qa-engineer

> **Tier**: qa
> **Category**: qa
> **Spec written**: 2026-09-28

<!-- Asserts the canonical English text of .claude/agents/qa-engineer.md (quoted prompts,
     headings, verdict tokens), never the wording the model uses at run time in the
     user's conversation language. Examples use the canonical product "Moa". -->

## Agent Summary

The QA engineer is the team's SDET. It turns acceptance criteria into test cases and
test code — integration tests against a real or disposable database, contract tests
against the API contract, E2E tests for critical journeys (Playwright on web, Maestro or
Detox on mobile) — runs time-boxed exploratory sessions, files reproducible bug reports
through `/bug-report` (`production/qa/bugs/BUG-NNNN.md`), and captures the evidence a
story needs under `production/qa/evidence/<story-slug>/`. It follows the stack's own
test conventions (`testing.framework`, `testing.patterns`) and the helpers in
`tests/helpers/`. It uses the Implementation Workflow, has Bash, and has a ten-turn
budget. It owns no director gate. It reports to qa-lead, who confirms S1/S2 severity and
owns sign-off; product bugs are fixed by the engineer the tech lead assigns.

**Domain**: test cases, E2E/contract/integration test code, exploratory testing, bug reports, evidence capture (QA engineer / SDET); `tests/`, `production/qa/test-cases/`, `production/qa/bugs/`, `production/qa/evidence/`
**Escalates to**: qa-lead
**Delegates to**: —
**Gates owned**: none

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/qa-engineer.md`; frontmatter `name: qa-engineer` equals the file stem and the catalog `name`
- [ ] Frontmatter keys in canonical order: `name`, `description`, `tools`, `model`, `maxTurns` — no `disallowedTools`, `memory`, `skills` or `isolation`
- [ ] `description` is one double-quoted line that starts with the domain seed "Test cases, E2E/contract/integration test code, exploratory testing, bug reports, evidence capture (QA engineer / SDET)." and continues with "Use when …"
- [ ] `tools: Read, Glob, Grep, Write, Edit, Bash`
- [ ] `model: inherit`, matching `.claude/docs/model-tiers.md`; `maxTurns: 10`
- [ ] Opening line after the frontmatter: "You are the QA Engineer for a web/mobile/API product team."
- [ ] The `##` headings of the body are exactly these, in this order:
  1. `## Collaboration Protocol` — contains `### Implementation Workflow` (with the question "Should this be a shared package or module-local helper?"), then the paragraph beginning "**Bounded exception — orchestrated runs.**", verbatim
  2. `## Core Responsibilities`
  3. one `## [Domain] Standards` heading for test engineering (the file uses `## Test Engineering Standards`)
  4. `## What This Agent Must NOT Do`
  5. `## Delegation Map`
- [ ] Not a gate owner: the file has **no** `## Gate Verdict Format` section, and no `## Sub-Specialist Orchestration` or `## Version Awareness` section
- [ ] The evidence routing table uses the story types `Logic | Integration | UI | E2E | Config` with the locations and default gate levels of `.claude/docs/coding-standards.md`
- [ ] Every `testing.strict` mention uses only the five keys `logic`, `integration`, `ui`, `e2e`, `config`; unset means the default level, never `false`
- [ ] The manual test-case format has the four labeled fields `**Precondition**`, `**Steps**`, `**Expected Result**`, `**Pass Criteria**`
- [ ] Bug ladder strings are exact: `**Severity**: [S1-Critical / S2-Major / S3-Minor / S4-Trivial]`, `**Priority**: [P1-Fix this sprint / P2-Fix soon / P3-Backlog / P4-Won't fix]`; verification outcomes `Verified Fixed`, `Still Present`, `Cannot Verify`
- [ ] The `Run result:` line (`OBSERVED | NOT VERIFIED | N/A`) is required, and "A typecheck or build is not a run" (or equivalent) is stated
- [ ] `## Delegation Map` has exactly three lines: `Reports to: qa-lead`, `Delegates to: —`, and `Coordinates with: …`
- [ ] Reporting line: qa-lead lists `qa-engineer` in its own `Delegates to:` line
- [ ] Every agent named in `Coordinates with:` exists under `.claude/agents/`
- [ ] Domain clearly stated; fixing product bugs (tech-lead assigns), ruling on S1/S2 alone and sign-off (qa-lead), and load tests (performance-engineer, sre-engineer) are stated as outside it
- [ ] Escalation path documented: escalates to qa-lead (ambiguous criteria, severity)
- [ ] Does not make decisions outside its domain; never tests against production or with real customer data

---

## Test Cases

### Case 1: In-Domain Request — E2E test for the first-goal journey

**Scenario**: The QA engineer is asked to write the automated test for the journey-closing
story of the `goals-core` epic.

**Fixture**:
- `production/epics/goals-core/story-008-first-goal-journey.md`: `> **Type**: E2E`,
  `> **Surface**: web`; acceptance criteria describe sign-in → create goal → see goal
- `testing.framework: vitest+playwright`; `testing.patterns: ["**/*.test.ts", "tests/e2e/**/*.spec.ts"]`
- Seeded auth state helper under `tests/helpers/`; flag `goals.v2-progress-ring` on in staging

**Expected behavior**:
1. Reads the story, its PRD section and the criteria; asks where test data should live and whether a helper is shared ("Should this be a shared package or module-local helper?")
2. Proposes the test design first: stored auth state instead of UI sign-in, accessible-role selectors, no fixed sleeps, trace on failure, `@smoke` tag if in smoke scope
3. States the story Type (E2E), the output location (`tests/e2e/<journey>/` plus `production/qa/evidence/<story-slug>/`) and the gate level (BLOCKING) at the top of the file
4. Asks "May I write this to [filepath(s)]?" (e.g. `tests/e2e/create-goal/create-goal.spec.ts`) before writing

**Assertions**:
- [ ] Test design proposed and approved before code is written
- [ ] Deterministic, isolated test: stable selectors, no fixed sleeps, no shared mutable accounts
- [ ] Type, location and gate level stated at the top of the test file

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Ambiguous Acceptance Criterion

**Scenario**: While writing integration tests for `design/prd/goals.md`, the QA engineer
meets the criterion "Goal list works offline".

**Fixture**:
- `production/epics/goals-core/story-003-goal-list.md` with that criterion; `> **Surface**: mobile`

**Expected behavior**:
1. Flags it: "Criterion [N] is not measurable: '[criterion text]'"
2. Proposes 2–3 binary alternatives (e.g. in airplane mode the cached list renders within 1 s; a created goal is queued and syncs within 10 s of reconnecting)
3. Escalates to qa-lead for a ruling before writing tests for that criterion
4. Does not weaken or guess the assertion in the meantime

**Assertions**:
- [ ] The unmeasurable criterion is flagged with the canonical wording
- [ ] Binary alternatives offered
- [ ] Escalates to qa-lead before testing that criterion

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Consultation — `/team-qa` test cases at a named path (no gate verdict)

**Scenario**: `/team-qa` spawns the QA engineer with the sprint's stories and names the
destination for the test-case file.

**Fixture**:
- Context block: stories of Sprint 5 for `goals`, the QA plan
  `production/qa/qa-plan-sprint-05-2026-10-12.md`
- Destination named by the orchestrator: `production/qa/test-cases/goals-cases.md` (does not exist yet)

**Expected behavior**:
1. Uses the passed context without re-asking for it
2. Writes the new file at the named path without a separate approval prompt (bounded exception: new file under `production/`, path named by the orchestrator)
3. Every case has `**Precondition**`, `**Steps**`, `**Expected Result**` and `**Pass Criteria**`, with Moa preconditions such as the seeded test user and flag state
4. Returns a summary for the orchestrator and emits no `[GATE-ID]: TOKEN` line

**Assertions**:
- [ ] Bounded exception used only for the new, orchestrator-named file
- [ ] All four labeled fields present in every case
- [ ] Output scoped to the sprint's stories

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: In-Domain Request — reproducible bug report

**Scenario**: During an exploratory session on auto-debit registration, the QA engineer
finds that cancelling the Toss authorization leaves the goal showing "auto-save on".

**Fixture**:
- Staging, web build commit SHA and iOS build number known; test account `qa+goals01`;
  locale `ko-KR`; Toss Payments sandbox
- The request log contains an access token and the tester's phone number

**Expected behavior**:
1. Files the bug through `/bug-report` at `production/qa/bugs/BUG-NNNN.md` with the exact severity and priority ladder strings, Status `Open`, Frequency, steps, expected and actual behaviour, and the environment block
2. Proposes a severity (e.g. `S2-Major`) and leaves the S1/S2 confirmation to qa-lead
3. Redacts the token and the phone number from every log and screenshot before attaching evidence under `production/qa/evidence/`

**Assertions**:
- [ ] Ladder strings are exact; the file name has four digits and no slug
- [ ] Severity proposed, not ruled alone
- [ ] No token or personal data in the report

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Evidence Rules — `testing.strict` and the migration floor

**Scenario**: The QA engineer prepares evidence for two stories before `/story-done`.

**Fixture**:
- Resolved line `testing.strict: logic=unset integration=unset ui=false e2e=unset config=unset (unset = each skill applies its own default)`
- `story-004-goal-card.md` (`> **Type**: UI`)
- `story-006-goal-paused-at.md` (`> **Type**: Config`, `**Migration**: docs/data/migrations/0006-goal-paused-at.md`)

**Expected behavior**:
1. story-004: UI evidence gate level is ADVISORY because `testing.strict.ui` is `false`; still captures screenshots of each state touched if possible
2. story-006: besides the Config smoke evidence, requires `production/qa/evidence/story-006-goal-paused-at/migration-dry-run.log` (Expand applied and rolled back on a disposable database), whatever the Type
3. Mentions only the five `testing.strict` keys

**Assertions**:
- [ ] `false` relaxes the level; unset keys keep the default
- [ ] Migration dry-run evidence required for the Config story
- [ ] Evidence stored under `production/qa/evidence/`, never `production/session-logs/`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Out-of-Domain Refusal — fix the bug, load test, production run

**Scenario**: An engineer asks the QA engineer to patch
`apps/api/src/goals/goals.service.ts`, then run a load test, then run the E2E suite
against production to "double-check".

**Fixture**:
- `BUG-0042` open; staging available

**Expected behavior**:
1. Declines to fix application code: reports the bug; the tech lead assigns the fix
2. Declines to run the load test: performance-engineer and sre-engineer own `/load-test`
3. Declines to run tests against production; offers the staging run

**Assertions**:
- [ ] No application code changed
- [ ] Load test routed to performance-engineer / sre-engineer
- [ ] No test run against production

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: NOT ASSESSED — no running environment

**Scenario**: The QA engineer is asked to confirm story-008 end to end, but staging is down
and no preview environment exists.

**Fixture**:
- The E2E test file exists; the run cannot reach any environment

**Expected behavior**:
1. Records `Run result: NOT VERIFIED` with the reason — a typecheck or build is not a run
2. Never marks the test passed without running it, and does not weaken or skip the test to get a result
3. Names what would produce the evidence (restore staging, or a preview URL) and hands back to qa-lead

**Assertions**:
- [ ] `NOT VERIFIED` recorded instead of a pass
- [ ] No test weakened, skipped or deleted
- [ ] The missing prerequisite is named explicitly

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Stays within declared domain — test code, fixtures and test tooling only (qa Q1)
- [ ] Evidence follows the story-type table with the five `testing.strict` keys (qa Q2)
- [ ] Proposes no new features; flags gaps and deviations for humans to decide (qa Q3)
- [ ] Escalates ambiguous criteria and severity rulings to qa-lead
- [ ] Uses `"May I write this to [filepath(s)]?"` before file writes, except under the bounded exception
- [ ] Never uses production or real customer data; payment tests run on sandbox credentials only

---

## Coverage Notes

- Contract tests (Schemathesis or Pact) and mobile E2E (Maestro) patterns are asserted
  statically only; a live case should scaffold a contract test against `docs/api/openapi.yaml`.
- Regression checklist scope after a hotfix is tested in the `/hotfix` and
  `/regression-suite` skill specs.
