# Skill Test Spec: /regression-suite

## Skill Summary

`/regression-suite` maintains `tests/regression-suite.md` — a curated manifest of the
tests that already exist (under `tests/` and wherever `testing.patterns` says tests
live) and that together guard the product's PRD critical paths, its critical user
journeys and its fixed bugs. Modes: `update` (bugs fixed this sprint and stories done
this sprint — append-only), `audit` (every PRD critical path and every critical journey
of `docs/ops/slo.md` against the test inventory — rewrites the manifest) and `report`
(read-only status). No argument = `update` when a sprint is clearly active, else ask.

Coverage per critical path is `COVERED`, `PARTIAL`, `MISSING` or `EXEMPT` (only UI and
Config criteria can be exempt); fixed bugs are `HAS REGRESSION TEST` or
`MISSING REGRESSION TEST`, with `S1-Critical` and `S2-Major` gaps HIGH priority. The
workflow tier (with per-feature `feature_overrides`) decides which PRD sections are
mapped; at the `minimal` tier the latest smoke report replaces PRD critical paths.
`qa.level` decides whether the suite is generated at all: at `qa.level: minimal` the
skill reports "Regression suite not generated at qa.level minimal" and stops before any
scan.

An empty denominator is **`Coverage: NOT ASSESSED — [no PRDs found | no critical
journeys found | no test files found]`**, never a percentage. The run-level verdict is
**COMPLETE** (manifest updated, or in `report` mode the status printed with coverage
computed), **BLOCKED** (the user declined the write) or **NOT ASSESSED** (the coverage
denominator is empty, or the `minimal`-tier audit found no smoke report — `Verdict:
NOT ASSESSED — no smoke report found`), with precedence BLOCKED > NOT ASSESSED >
COMPLETE. No director gates apply.

---

## Static Assertions (Structural)

Verified automatically by `/skill-test static` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] `name: regression-suite` equals the directory `.claude/skills/regression-suite/` and the catalog entry name
- [ ] First body line is exactly `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow,qa.level,feature_overrides` `` — `--keys` is exactly `automation,workflow,qa.level,feature_overrides`
- [ ] `allowed-tools` grants `Bash(bash "*/.claude/skills/regression-suite/../../hooks/yaml-helper.sh" resolve_config *)` (this skill's own directory)
- [ ] The line after the bootstrap block is exactly ``Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] The automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") follows that line verbatim
- [ ] `allowed-tools` is exactly `Read, Glob, Grep, Write, Edit, AskUserQuestion` plus the bootstrap grant — no `Agent`
- [ ] Has ≥2 phase headings (`## 1. Parse Arguments` … `## 7. Write Output`)
- [ ] Contains verdict keywords COMPLETE, BLOCKED and NOT ASSESSED, and the coverage statuses COVERED, PARTIAL, MISSING, EXEMPT
- [ ] Contains "May I write this to `tests/regression-suite.md`?"
- [ ] Output path is exactly `tests/regression-suite.md`; `report` mode writes nothing
- [ ] No `!` injection other than the bootstrap line; no `file:line` citation of another file
- [ ] Has a next-step handoff naming current skills (`/test-helpers`, `/dev-story`, `/quick-spec`, `/sprint-plan`, `/test-flakiness registry`)

---

## Director Gate Checks

None. `/regression-suite` is a QA analysis utility. It spawns no agent and no director
gate.

---

## Test Cases

### Case 1: Audit — PRD critical paths and critical journeys mapped

**Fixture:**
- Canonical product Moa; `qa.level` resolves to `standard`, `workflow` to `standard`
- `design/product/feature-map.md` lists `goals` (Tier `MVP`, PRD `design/prd/goals.md`) and `payments` (Tier `MVP`)
- `docs/ops/slo.md` `## Critical User Journeys` names "sign in with Kakao → create a savings goal → register a Toss Payments auto-debit"
- `testing.patterns: [apps/*/src/**/*.test.ts, tests/**]`; co-located tests exist under `apps/api/src/goals/`; `tests/e2e/first-deposit/first-deposit.spec.ts` covers the journey on web only, while the journey also ships on iOS

**Input:** `/regression-suite audit`

**Expected behavior:**
1. Skill globs every `testing.patterns` entry and excludes the scaffold's example files, `tests/e2e/capture.spec.ts`, `tests/helpers/` and `tests/load/`
2. Skill greps each MVP PRD's `## Acceptance Criteria`, `## Business Rules & Calculations`, `## Edge Cases` and `## Functional Requirements` instead of reading the PRDs whole
3. Skill maps each criterion and rule by feature slug, key terms or `TR-goals-NNN` ID, and the journey to its E2E test
4. The journey is `PARTIAL` (one surface of several); a MISSING payment rule is elevated to HIGH PRIORITY
5. Skill asks "May I write this to `tests/regression-suite.md`?" naming whether it is new or an update; audit rewrites the manifest; verdict COMPLETE

**Assertions:**
- [ ] Co-located tests count — "no file under `tests/`" is not "no test"
- [ ] The Critical Journey Coverage table lists the journey with its surfaces and status
- [ ] Business rules, state machines, payment and authorization gaps are HIGH priority
- [ ] The manifest has `## How to run`, `## Registered Regression Tests`, `## Known Gaps`, `## Quarantined Tests`
- [ ] Verdict is COMPLETE after the approved write

---

### Case 2: Update — Fixed bugs without regression tests

**Fixture:**
- `production/qa/bugs/BUG-0012.md` (`S1-Critical`, `**Status**: Verified Fixed`, duplicate deposit on webhook retry) — no test references `BUG-0012` or the retry scenario
- `production/qa/bugs/BUG-0006.md` has `**Status**: Won't Fix`
- `production/sprint-status.yaml` has stories with `status: in-progress`

**Input:** `/regression-suite` (no argument)

**Expected behavior:**
1. Skill runs `update` because a sprint is clearly active
2. Skill keeps closed bugs with `Verified Fixed` or `Closed`; the `Won't Fix` bug needs no regression test
3. `BUG-0012` is `MISSING REGRESSION TEST`, HIGH priority, with a suggested path following `testing.patterns` and `testing.framework`
4. Skill appends to the manifest with targeted `Edit` insertions after "May I write this to `tests/regression-suite.md`?"

**Assertions:**
- [ ] `Won't Fix` bugs are excluded from the regression gap list
- [ ] The S1 gap is HIGH priority and says the bug can silently return
- [ ] `update` never removes an existing manifest entry
- [ ] After writing, the skill points to `/test-helpers` and a `/dev-story` or `/quick-spec` story for the missing test

---

### Case 3: NOT ASSESSED — Empty denominator

**Fixture:**
- `qa.level` resolves to `standard`
- No PRDs exist under `design/prd/`, no `docs/ops/slo.md`, and the test globs return only scaffold example files

**Input:** `/regression-suite audit`

**Expected behavior:**
1. Skill finds zero critical paths and zero product test files
2. Skill reports `Coverage: NOT ASSESSED — no PRDs found` and `no test files found`, naming the empty side and the skill that produces it (`/map-features` and `/write-prd` for PRDs, `/create-architecture` for critical journeys, `/test-setup` for the scaffold)
3. Critical journeys print `NOT CHECKED — critical journeys: docs/ops/slo.md absent (written by /create-architecture)`
4. No percentage is emitted
5. The run verdict is **NOT ASSESSED**

**Assertions:**
- [ ] No coverage percentage (neither `0%` nor `100%`) is printed for an empty denominator
- [ ] Each empty source is named with its producing skill
- [ ] The absent journey source is a named `NOT CHECKED` line, not silence
- [ ] Run verdict is NOT ASSESSED — never COMPLETE — when the coverage denominator is empty

---

### Case 4: Mode Variant — `qa.level: minimal` stops before any scan

**Fixture:**
- `qa.level` resolves to `minimal` (the default rigor expansion)

**Input:** `/regression-suite audit`

**Expected behavior:**
1. The early guard reports "Regression suite not generated at qa.level minimal"
2. Skill stops before Step 2, in every mode

**Assertions:**
- [ ] No test inventory, PRD or bug scan runs
- [ ] No write is offered
- [ ] The `qa.level` guard is not confused with the `workflow`-tier `minimal` branch

---

### Case 5: Workflow Tier `minimal` — Smoke report as the critical-path source

**Fixture:**
- `qa.level` resolves to `standard`; `workflow` resolves to `minimal`
- `production/qa/smoke-2026-11-18.md` exists and names its critical journeys

**Input:** `/regression-suite audit`

**Expected behavior:**
1. Skill skips the PRD critical-path scan and takes the critical paths the latest smoke report exercises
2. Coverage is mapped against those paths
3. With no smoke report the skill says so and stops with **Verdict: NOT ASSESSED** — no smoke report found (`production/qa/smoke-*.md`, written by `/smoke-check`); nothing is written — there is no critical-path source at this tier without one

**Assertions:**
- [ ] The critical-path source is named in the report
- [ ] A missing smoke report stops the audit with the reason, never a clean result
- [ ] That stop's run verdict is NOT ASSESSED, naming `/smoke-check` — never COMPLETE

---

### Case 6: Report Mode — Read-only

**Fixture:**
- `tests/regression-suite.md` exists with a Quarantined Tests row

**Input:** `/regression-suite report`

**Expected behavior:**
1. Skill prints the Regression Suite Status report in the conversation
2. No write is offered

**Assertions:**
- [ ] No write tool is called in `report` mode
- [ ] Quarantined tests are listed; the skill points to `/test-flakiness registry` for them

---

### Case 7: Director Gate Check — No gate; regression-suite is a QA utility

**Fixture:**
- Stories and test files exist

**Input:** `/regression-suite`

**Expected behavior:**
1. Skill produces the report and, with approval, the manifest
2. No agents or director gates are spawned

**Assertions:**
- [ ] No director gate is invoked and no gate skip note appears
- [ ] The verdict is COMPLETE, BLOCKED or NOT ASSESSED — never a gate verdict

---

## Protocol Compliance

- [ ] Checks the denominator before computing any percentage
- [ ] Derives the test inventory from `testing.patterns` (or announces the `tests/**` convention)
- [ ] Never removes a registered regression test without explicit approval
- [ ] Treats quarantine as a manifest note, not deletion
- [ ] Asks "May I write this to `tests/regression-suite.md`?" before writing
- [ ] Writes nothing under `production/session-logs/`
- [ ] Gaps are advisory; no other work is blocked by them

---

## Coverage Notes

- Matching a criterion to a test uses the feature slug, key terms and TR-IDs; it is
  approximate and not fixture-tested beyond Cases 1–2.
- This skill does not run tests; execution belongs to CI and `/smoke-check`.
- Coverage drift (new features, revised PRDs, new journeys since the last update) is
  covered by the drift section of Case 1's report and not tested separately.
