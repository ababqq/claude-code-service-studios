# Agent Spec: qa-lead

> **Tier**: leads
> **Category**: lead
> **Spec written**: 2026-09-28

<!-- Asserts the canonical English text of .claude/agents/qa-lead.md (quoted prompts,
     headings, verdict tokens), never the wording the model uses at run time in the
     user's conversation language. Examples use the canonical product "Moa". -->

## Agent Summary

The QA lead owns the test strategy across every layer — unit, integration and contract,
UI, end-to-end — the evidence each story type needs before it can close, the bug
severity scheme, and the quality bar a release must clear. It practises shift-left
testing: it reviews acceptance criteria for testability before a story enters a sprint
(QL-STORY-READY, spawned by `/create-stories` and `/story-readiness`) and confirms
coverage and on-disk evidence after implementation (QL-TEST-COVERAGE, spawned by
`/story-done` and `/team-qa`). It plans QA with `/qa-plan`, owns the smoke gate hand-off,
rules on S1/S2 severity, and feeds the quality block of `/release-checklist`.
qa-engineer writes and executes the tests; accessibility-specialist takes accessibility
testing work from it while reporting to design-director. It uses the Question-First
Workflow, has Bash, and never tests against production or with real customer data.

**Domain**: test strategy (unit / integration+contract / UI / E2E), story-type evidence, release quality gates, bug severity; `production/qa/` plans, sign-offs and bug policy
**Escalates to**: technical-director
**Delegates to**: qa-engineer, accessibility-specialist
**Gates owned**: QL-STORY-READY (ADEQUATE / GAPS / INADEQUATE); QL-TEST-COVERAGE (ADEQUATE / GAPS / INADEQUATE)

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/qa-lead.md`; frontmatter `name: qa-lead` equals the file stem and the catalog `name`
- [ ] Frontmatter keys in canonical order: `name`, `description`, `tools`, `model`, `maxTurns`, `memory`, `skills` — no `disallowedTools`, no `isolation`
- [ ] `description` is one double-quoted line that starts with the domain seed "Test strategy (unit / integration+contract / UI / E2E), story-type evidence, release quality gates, bug severity." and continues with "Use when …"
- [ ] `tools: Read, Glob, Grep, Write, Edit, Bash`
- [ ] `model: inherit`, matching `.claude/docs/model-tiers.md` (lead L3); `maxTurns: 20`; `memory: project`; `skills: [bug-report, release-checklist]`
- [ ] Opening line after the frontmatter: "You are the QA Lead for a web/mobile/API product team."
- [ ] The `##` headings of the body are exactly these, in this order:
  1. `## Collaboration Protocol` — contains `### Question-First Workflow`, then the paragraph beginning "**Bounded exception — orchestrated runs.**", verbatim
  2. `## Core Responsibilities`
  3. one `## [Domain] Standards` heading for test strategy (the file uses `## Test Strategy Standards`)
  4. `## Gate Verdict Format`
  5. `## What This Agent Must NOT Do`
  6. `## Delegation Map`
- [ ] No `## Sub-Specialist Orchestration` and no `## Version Awareness` section
- [ ] `## Gate Verdict Format` lists exactly these two gates with exactly these tokens — no other gate ID, no other token:
  - QL-STORY-READY — ADEQUATE / GAPS / INADEQUATE
  - QL-TEST-COVERAGE — ADEQUATE / GAPS / INADEQUATE
- [ ] `## Gate Verdict Format` states the first-line contract `[GATE-ID]: TOKEN` (the spawning skill parses the first line) and tells the agent to read the gate file `.claude/docs/director-gates/<lowercase-id>.md` whose path it was passed
- [ ] Story types are exactly `Logic | Integration | UI | E2E | Config`, with the evidence, location and default gate level of `.claude/docs/coding-standards.md` (Config is ADVISORY; `/smoke-check` unset ⇒ BLOCKING kept as the intentional exception)
- [ ] Every `testing.strict` mention uses only the five keys `logic`, `integration`, `ui`, `e2e`, `config` (`testing.strict.logic`, `testing.strict.integration`, `testing.strict.ui`, `testing.strict.e2e`, `testing.strict.config`); unset is never read as `false`
- [ ] The migration floor is stated: a story whose `**Migration**` is not `None` needs `production/qa/evidence/<story-slug>/migration-dry-run.log` at every `qa.level`
- [ ] Bug ladder strings are exact: `**Severity**: [S1-Critical / S2-Major / S3-Minor / S4-Trivial]`, `**Priority**: [P1-Fix this sprint / P2-Fix soon / P3-Backlog / P4-Won't fix]`; "unresolved" = Status `Open`, `In Progress` or `Fixed — Pending Verification`; bug files are `production/qa/bugs/BUG-NNNN.md`
- [ ] `## Delegation Map` has exactly three lines: `Reports to: technical-director`, `Delegates to: qa-engineer, accessibility-specialist`, and `Coordinates with: …`
- [ ] Reporting line: technical-director lists `qa-lead` in its own `Delegates to:` line; qa-engineer names `qa-lead` in its `Reports to:` line; accessibility-specialist is an additional delegation — its own parent, design-director, lists it too
- [ ] Every agent named in `Delegates to:` or `Coordinates with:` exists under `.claude/agents/`
- [ ] Domain clearly stated; fixing bugs or writing production code (tech-lead assigns), acceptance-criteria content (product-manager), incident SEV classification (`/incident` with sre-engineer) and configuration changes (`/settings`) are stated as outside it
- [ ] Escalation path documented: quality-standard disputes to technical-director, scope and date trade-offs to delivery-manager
- [ ] Does not make decisions outside its domain; never downgrades a severity to fit a date

---

## Test Cases

### Case 1: In-Domain Request — test strategy for auto-debit

**Scenario**: The user asks the QA lead how Moa's auto-debit registration should be tested
before Private Beta.

**Fixture**:
- `design/prd/payments.md` Approved; `docs/api/openapi.yaml` includes the mandate and
  webhook operations; `docs/ops/slo.md` names "register auto-debit" as a critical journey
- `platform.surfaces: web, ios, android, api (project.yaml)`; `qa.level: standard`

**Expected behavior**:
1. Asks clarifying questions first — the risk protected against (money movement), constraints (date, CI minutes, devices), which environments exist
2. Presents 2–4 options (e.g. contract + integration tests against the Toss Payments sandbox with one E2E journey per surface, versus broad E2E coverage) with pros, cons and a recommendation; defers the decision to the user
3. Places idempotency and retry behaviour in integration tests, not E2E; payment tests use sandbox credentials only
4. After the choice, drafts the QA plan section by section with the headings of `.claude/docs/templates/test-plan.md` (including `## Automated Tests Required` and `## Smoke Test Scope`) and asks "May I write this section to [filepath]?"

**Assertions**:
- [ ] Clarifying questions precede options
- [ ] 2–4 options with a recommendation and an explicit hand-back to the user
- [ ] No test that could move real money; sandbox only
- [ ] Each section written only after approval

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Gate Verdict — QL-STORY-READY returns GAPS

**Scenario**: `/story-readiness` spawns QL-STORY-READY.

**Fixture**:
- Context bullets passed: story path `production/epics/goals-core/story-003-goal-list.md`
  · PRD path `design/prd/goals.md` · resolved `testing.strict` line
  `testing.strict: logic=unset integration=unset ui=unset e2e=unset config=unset (unset = each skill applies its own default)`
- The story (`> **Type**: UI`) has four criteria; three are Given/When/Then and binary; one
  reads "The goal list should load fast and work offline"

**Expected behavior**:
1. Reads `.claude/docs/director-gates/ql-story-ready.md`, then the story and PRD
2. First line: `QL-STORY-READY` with the token `GAPS`
3. Identifies the unmeasurable criterion and proposes measurable wording (e.g. a latency threshold from `## Non-Functional Requirements`; cached list renders with no network), leaving the content decision to product-manager
4. Does not edit the story during the gate review

**Assertions**:
- [ ] The first line is the single verdict line — gate ID `QL-STORY-READY` and a token from ADEQUATE / GAPS / INADEQUATE
- [ ] The failing criterion is quoted and a binary alternative proposed
- [ ] Acceptance-criteria content is not rewritten by the QA lead

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Gate Verdict — QL-TEST-COVERAGE returns INADEQUATE (migration floor)

**Scenario**: `/story-done` spawns QL-TEST-COVERAGE for a story that adds a column.

**Fixture**:
- Context bullets passed: story path `production/epics/goals-core/story-006-goal-paused-at.md`
  (`**Migration**: docs/data/migrations/0006-goal-paused-at.md`) · test file paths
  (`tests/integration/goals/goal-pause.test.ts`) · evidence directory paths
  (`production/qa/evidence/story-006-goal-paused-at/`, empty) · resolved lines
  `testing.strict: logic=unset integration=unset ui=unset e2e=unset config=false (unset = each skill applies its own default)`
  and `qa.level: minimal (rigor:minimal)`
- A dry-run log exists only under `production/session-logs/`

**Expected behavior**:
1. First line: `QL-TEST-COVERAGE` with the token `INADEQUATE`
2. Names the blocker: `production/qa/evidence/story-006-goal-paused-at/migration-dry-run.log` is absent — required at every `qa.level` and regardless of `testing.strict.config`
3. States that evidence under the gitignored `production/session-logs/` does not count

**Assertions**:
- [ ] The migration floor is applied at `qa.level: minimal` and with `config=false`
- [ ] Evidence in a gitignored path is rejected as evidence
- [ ] Token comes from ADEQUATE / GAPS / INADEQUATE only

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: NOT ASSESSED — QL-TEST-COVERAGE with unreadable inputs

**Scenario**: `/team-qa` spawns QL-TEST-COVERAGE for Sprint 5, but the test file paths
passed do not exist and no evidence directory was given.

**Fixture**:
- Context bullets passed: sprint id `sprint-05` · test file paths
  (`tests/e2e/create-goal/create-goal.spec.ts`, absent) · evidence directory paths: none ·
  resolved `testing.strict` and `qa.level` lines

**Expected behavior**:
1. Does not return ADEQUATE: absence is not a pass
2. Names each missing input in the rationale (test file absent; no evidence directory passed)
3. First line: `QL-TEST-COVERAGE` with GAPS or INADEQUATE
4. Says what would produce the missing input (run `/team-qa` execution, capture evidence under `production/qa/evidence/<story-slug>/`)

**Assertions**:
- [ ] No APPROVE-class token when an input could not be read
- [ ] Missing inputs named explicitly
- [ ] No coverage claim for tests that were not found

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Evidence Rules — `testing.strict` overrides and unset keys

**Scenario**: The user asks whether two stories can close.

**Fixture**:
- Resolved line `testing.strict: logic=unset integration=unset ui=false e2e=unset config=unset (unset = each skill applies its own default)`
- `story-004-goal-card.md` (`> **Type**: UI`): component test passes; no retained screenshots
- `story-008-first-goal-journey.md` (`> **Type**: E2E`): no automated E2E test; a manual walkthrough note only

**Expected behavior**:
1. story-004: UI evidence is ADVISORY because `testing.strict.ui` is `false`; the missing screenshots are reported as a gap, not a blocker
2. story-008: `e2e` is unset, so the default gate level (BLOCKING) applies — unset is never read as `false`; a manual note is not an automated E2E test, so the story cannot close
3. Refers only to the five keys `logic`, `integration`, `ui`, `e2e`, `config`

**Assertions**:
- [ ] `false` relaxes the level; unset falls back to the default, never to `false`
- [ ] E2E evidence requires an automated journey test passing against a running environment
- [ ] No `testing.strict` key outside the five is mentioned

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Out-of-Domain Redirect — fixing the bug and classifying the incident

**Scenario**: During a staging outage of goal creation, an engineer asks the QA lead to
patch `apps/api/src/goals/goals.service.ts` and to declare the incident SEV1.

**Fixture**:
- `BUG-0042` open in `production/qa/bugs/BUG-0042.md`; staging only, no production impact

**Expected behavior**:
1. Declines to write the fix — tech-lead assigns it to the routed engineer
2. Declines to classify SEV — incident severity is set in `/incident` with the human incident commander and sre-engineer; the bug keeps its S-ladder severity
3. Offers what it owns: the severity ruling on `BUG-0042` and the regression test it will require

**Assertions**:
- [ ] No production code written
- [ ] SEV classification routed to `/incident` / sre-engineer
- [ ] S-ladder and SEV schemes kept separate

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: Conflict Escalation — shipping with a known S2

**Scenario**: release-manager wants to ship 1.3.0 with an unresolved `S2-Major` bug in the
"register auto-debit" journey the release touches; the date was promised to a partner.

**Fixture**:
- `BUG-0051` (`S2-Major`, Status `Fixed — Pending Verification`)
- Release quality bar: zero unresolved S2 bugs in the journeys the release touches

**Expected behavior**:
1. Counts `BUG-0051` as unresolved and states that the quality bar is not met
2. Does not downgrade the severity to fit the date
3. Escalates the date trade-off to delivery-manager and the quality-standard exception to technical-director; the release proceeds only with the user's explicit, recorded acceptance of the named exception

**Assertions**:
- [ ] Severity unchanged
- [ ] Correct escalation targets for date and quality
- [ ] No release approval without the user's recorded acceptance

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Stays within declared domain — no production code, no acceptance-criteria content, no SEV classification
- [ ] Escalates quality-standard disputes to technical-director and date trade-offs to delivery-manager (lead L2)
- [ ] Uses `"May I write this section to [filepath]?"` before file writes, except under the bounded exception
- [ ] Presents options and reasoning before requesting approval (Question-First)
- [ ] Does not skip tiers — test code through qa-engineer, accessibility testing through accessibility-specialist
- [ ] Gate replies use only the tokens of the gate spawned, on the first line (lead L1)
- [ ] Every `testing.strict` reference uses only `logic`, `integration`, `ui`, `e2e`, `config`

---

## Coverage Notes

- Flaky-test quarantine policy (`/test-flakiness`), smoke gate ownership and release
  quality inputs to `/rollout-plan` are asserted statically only.
- `/qa-plan` output paths and headings are tested in the `/qa-plan` skill spec.
- The first-line contract is written `[GATE-ID]: TOKEN`; Cases 2–4 accept the gate ID with
  or without the square brackets the gate file prints, as long as it is the spawned gate's
  ID followed by one of its tokens.
