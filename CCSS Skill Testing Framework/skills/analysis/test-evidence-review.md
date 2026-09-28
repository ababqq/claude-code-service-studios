# Skill Test Spec: /test-evidence-review

## Skill Summary

`/test-evidence-review` reviews the **quality** of the tests and evidence records
behind stories — where `/smoke-check` only verifies that tests exist and pass. Scope
is one story, the current sprint, or a feature or epic slug. For each story it takes
the Type (`Logic | Integration | UI | E2E | Config`), Surface, `**API Contract**` and
`**Migration**` from the header with targeted greps, locates the evidence the story
type requires (per `testing.patterns` read from `project.yaml`, else the `tests/**`
convention; `production/qa/evidence/<story-slug>/` for UI and E2E; a smoke report for
Config; `migration-dry-run.log` for any story with a Migration), and evaluates it:
assertion coverage, skipped or focused tests, edge cases, naming
(`scenario → expected`), business-rule traceability, contract verification, E2E trace and
environment, criterion linkage, sign-offs, screenshots per state and viewport, axe
results, the `Run result:` token and redaction. Evidence under
`production/session-logs/` never counts. Per-story verdicts are
**ADEQUATE / INCOMPLETE / MISSING / NOT ASSESSED**; the overall verdict is the worst
present, with NOT ASSESSED above ADEQUATE but below INCOMPLETE and MISSING. It reports
against the default gate levels of `.claude/docs/coding-standards.md` (it resolves neither
`testing.strict` nor `qa.level`; `/story-done` does — at `qa.level: minimal` its MISSING means
"no evidence present", not "required evidence absent"). The report is shown in the conversation
and optionally written to `production/qa/evidence-review-YYYY-MM-DD.md`. No director
gates are invoked.

---

## Static Assertions (Structural)

Verified automatically by `/skill-test static` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] `name: test-evidence-review` equals the skill directory, the catalog `name` and this spec's basename
- [ ] First body line is `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation` `` — exactly this one label
- [ ] `allowed-tools` grants `Bash(bash "*/.claude/skills/test-evidence-review/../../hooks/yaml-helper.sh" resolve_config *)` with this skill's own directory name
- [ ] The line after the bootstrap block is exactly ``Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] The automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") follows that line verbatim
- [ ] `allowed-tools` is exactly: `Read, Glob, Grep, Write` plus the grant — membership exact, order free; no Edit, Agent or AskUserQuestion
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: ADEQUATE, INCOMPLETE, MISSING, NOT ASSESSED; issue levels BLOCKING and ADVISORY
- [ ] Contains "May I write this to `production/qa/evidence-review-YYYY-MM-DD.md`?" before the optional report write
- [ ] The report template starts `# Test Evidence Review` followed by one blank line and `> **Verdict**: [ADEQUATE | INCOMPLETE | MISSING | NOT ASSESSED]`
- [ ] The five story types and the `testing.strict.logic|integration|ui|e2e|config` override keys are named; the migration floor is stated as independent of `testing.strict`; the skill states it resolves neither `testing.strict` nor `qa.level`, and the report's `> **Strictness**:` line says so
- [ ] The artefact-completeness check states that images under `design/handoff/` are design references and never evidence, with the line `Reference image <path> is a design reference, not a capture`
- [ ] No `!` injection other than the bootstrap line; no `file:line` citations
- [ ] Has a next-step handoff naming current skills (`/story-done`, `/test-helpers`, `/test-setup`, `/sprint-plan new`, `/create-stories`)

---

## Director Gate Checks

None. Evidence review is an advisory quality skill with no `Agent` tool; no gate is
invoked and `review_mode` is not among its keys. QL-TEST-COVERAGE is spawned by
`/story-done` and `/team-qa`, not by this skill.

---

## Test Cases

### Case 1: Happy Path — Logic story with strong co-located tests

**Fixture:**
- `production/epics/goals-core/story-002-goal-plan-calc.md`: `> **Type**: Logic`, `**PRD**: design/prd/goals.md`, 4 acceptance criteria including "monthly debit rounds up to the nearest KRW 10"
- `testing.patterns: [apps/*/src/**/*.test.ts, tests/**]`
- `apps/api/src/goals/goal-plan.test.ts` has 5 tests with 3+ `expect(` each, names such as `it('rounds the monthly debit up to the nearest KRW 10')`, a zero-months case, and a comment citing `TR-goals-001`

**Input:** `/test-evidence-review production/epics/goals-core/story-002-goal-plan-calc.md`

**Expected behavior:**
1. Reads the story header and test evidence section with targeted greps
2. Locates the co-located test through `testing.patterns` and matches it by TR-ID
3. Checks assertion coverage, edge cases ("zero", "max"), naming and business-rule traceability
4. Story verdict ADEQUATE; overall ADEQUATE

**Assertions:**
- [ ] Each quality dimension is reported (assertions, skipped/focused, edge cases, naming, traceability)
- [ ] The report header records the test search globs from `testing.patterns`
- [ ] Verdict is ADEQUATE
- [ ] No files are written unless the user accepts the optional report

---

### Case 2: Fail — vacuous and skipped tests

**Fixture:**
- The Case 1 story, but `goal-plan.test.ts` contains `it('works', () => { createGoalPlan(input) })` with no `expect(`, and `it.skip('rejects a target date in the past', …)` covering an acceptance criterion

**Input:** `/test-evidence-review production/epics/goals-core/story-002-goal-plan-calc.md`

**Expected behavior:**
1. Flags the zero-assertion test as BLOCKING (it passes vacuously)
2. Flags the skipped test covering an acceptance criterion as BLOCKING and the generic name `works` as a naming issue
3. Story verdict INCOMPLETE; the BLOCKING count is reported
4. Recommends `/test-helpers` for assertion patterns; states that BLOCKING items must be resolved before `/story-done` can mark the story Complete

**Assertions:**
- [ ] Zero assertions are classified BLOCKING
- [ ] A skipped test covering a criterion is BLOCKING; a focused `.only` would be ADVISORY
- [ ] Verdict is INCOMPLETE (the test exists but has quality gaps)
- [ ] The skill does not edit the test file

---

### Case 3: Fail — contract test that asserts status only, no BOLA negative case

**Fixture:**
- `production/epics/goals-core/story-001-create-goal.md`: `> **Type**: Integration`, `**API Contract**: GET /v1/goals/{goalId} (getGoal)`
- `tests/contract/goals/get-goal.test.ts` asserts only `expect(res.status).toBe(200)`; no test requests another user's goal

**Input:** `/test-evidence-review production/epics/goals-core/story-001-create-goal.md`

**Expected behavior:**
1. Locates the contract test under `tests/contract/goals/`
2. Reports contract verification as status-only (thin), not schema-validated against `docs/api/`
3. Flags the missing authorization negative case (another user's resource refused)
4. Story verdict INCOMPLETE

**Assertions:**
- [ ] Contract verification line reads status-only / thin coverage
- [ ] The missing cross-user negative case is flagged
- [ ] Verdict is INCOMPLETE
- [ ] The skill does not modify the test file

---

### Case 4: NOT ASSESSED — empty scope, or a story whose type is unknown

**Fixture:**
- Run A: `production/sprints/` is empty
- Run B: a story file in scope has no `> **Type**:` line

**Input:** `/test-evidence-review sprint` (Run A), `/test-evidence-review goals-core` (Run B)

**Expected behavior:**
1. Run A: stops with `NOT ASSESSED — no stories in scope`, names the scope searched and the empty path, and routes to `/sprint-plan new`
2. Run B: marks the untyped story NOT ASSESSED — type cannot be determined — never MISSING; the other stories are reviewed normally

**Assertions:**
- [ ] Run A emits NOT ASSESSED rather than an empty summary reading `BLOCKING items: 0`
- [ ] Run B names the reason per story
- [ ] NOT ASSESSED outranks ADEQUATE in the overall verdict but not INCOMPLETE or MISSING

---

### Case 5: Edge Case — UI evidence gaps, migration floor, evidence in session logs

**Fixture:**
- `production/epics/goals-core/story-003-goal-progress-ring.md`: `> **Type**: UI`, `> **Surface**: web`
- `production/qa/evidence/story-003-goal-progress-ring/` holds `01-default-desktop.png` only (no mobile screenshot, no `NN-<state>-axe.json`); the evidence record's `Run result:` is `NOT VERIFIED`
- `production/epics/payments-core/story-005-payment-methods-table.md` has `**Migration**: docs/data/migrations/0003-payment-methods.md` and no `migration-dry-run.log`; its only log sits under `production/session-logs/`

**Input:** `/test-evidence-review payments-core` and `/test-evidence-review production/epics/goals-core/story-003-goal-progress-ring.md`

**Expected behavior:**
1. UI story: missing mobile-viewport screenshots and `NOT VERIFIED` run result → INCOMPLETE; writes `NOT CHECKED — axe results (no axe report in the evidence directory)`
2. Migration story: MISSING and BLOCKING at every `qa.level`; the session-logs file is recorded as not found, naming the path it should move to
3. For missing web captures, points to `tests/e2e/capture.spec.ts` with `CAPTURE_OUT_DIR=production/qa/evidence/<story-slug>`

**Assertions:**
- [ ] An absent axe report is never read as a clean accessibility result
- [ ] The migration floor is applied regardless of `testing.strict`
- [ ] Evidence under `production/session-logs/` does not count
- [ ] Variant: when `02-filled-mobile.png` in the evidence directory is a copy of `design/handoff/goal-progress-ring/screens/02-filled.png`, the report says `Reference image production/qa/evidence/story-003-goal-progress-ring/02-filled-mobile.png is a design reference, not a capture` and the filled state still counts as having no retained image (INCOMPLETE); files under `design/handoff/` never count

---

### Case 6: Gate Compliance — no gate; optional report requires approval

**Fixture:**
- The Case 3 story (one INCOMPLETE finding)
- `modes.review_mode: full` in `project.yaml`

**Input:** `/test-evidence-review production/epics/goals-core/story-001-create-goal.md`

**Expected behavior:**
1. Reviews the story as in Case 3
2. No director gate is invoked
3. Presents the report and asks "May I write this to `production/qa/evidence-review-YYYY-MM-DD.md`?"
4. Writes only if the user wants the persistent record

**Assertions:**
- [ ] No director gate is invoked in any review mode
- [ ] The optional report requires "May I write" before writing
- [ ] The written report's verdict line sits directly under the H1

---

## Protocol Compliance

- [ ] Reads the story headers and the default gate levels of `.claude/docs/coding-standards.md` before reviewing evidence
- [ ] Checks assertion coverage, skipped/focused tests, edge cases, naming, traceability, contract verification, E2E runs, criterion linkage, sign-offs, artefacts, axe results, run result, redaction and the migration floor as the story type requires
- [ ] Does not edit any test file or evidence record
- [ ] Writes no evidence, reports or plans under `production/session-logs/`
- [ ] Never writes `modes.review_mode` or any other knob that `modes.rigor` fronts
- [ ] No director gates are invoked
- [ ] Verdict is one of: ADEQUATE, INCOMPLETE, MISSING, NOT ASSESSED
- [ ] analysis AN1 — the review reads only (Read, Glob, Grep); nothing is written before the optional report prompt
- [ ] analysis AN2 — story-by-story results and a summary table with BLOCKING / ADVISORY counts
- [ ] analysis AN3 — the report write is optional and gated behind "May I write"
- [ ] analysis AN4 — no director gates
- [ ] Observation vs verdict: each story's evidence path is recorded as found or not found; "could not look" is NOT ASSESSED, "looked and found nothing" is MISSING

---

## Coverage Notes

- Batch review of an epic or sprint applies the same checks per story and takes the
  worst story verdict; only the empty-scope boundary is tested explicitly.
- The QL-TEST-COVERAGE director gate (spawned by `/story-done` and `/team-qa`) is a
  separate concern and is intentionally not invoked here.
- The design-reference exclusion is asserted as a Case 5 variant; detecting a copied
  reference image needs the files on disk, so it is not exercised statically.
- Redaction checks depend on reading screenshots and traces; a live run is needed to
  confirm personal data is noticed in images.
