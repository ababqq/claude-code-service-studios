---
name: regression-suite
description: "Map test coverage to PRD critical paths and critical journeys; find fixed bugs lacking regression tests."
argument-hint: "[update | audit | report]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, Bash(bash "*/.claude/skills/regression-suite/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow,qa.level,feature_overrides`

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).


# Regression Suite

This skill ensures that every bug fix is backed by a test that would have
caught the original bug — and that the regression suite stays current as the
product evolves. It also detects when new features have been added without
corresponding regression coverage.

A regression suite is not a new test category — it is a **curated list of
tests that already exist** (in `tests/` and wherever `testing.patterns` says tests
live) that collectively cover the product's critical paths, its critical user
journeys and its known failure points. This skill maintains that list.

**Output:** `tests/regression-suite.md`

**When to run:**
- After fixing a bug (confirm a regression test was written or identify the gap)
- Before entering the phase at which `qa.level` requires the suite (Hardening at
  `standard`, Build at `full`) and before each release candidate
- As part of sprint close to detect coverage drift

---

**Workflow tier**: `modes.workflow` as resolved above — supplied by `modes.rigor`
unless set explicitly — per `.claude/docs/workflow-modes.md`; in `audit` mode
resolve each feature's effective tier from the `feature_overrides` line
(`workflow_overrides.feature_overrides.<prd-stem>`) as each PRD is read. It
sets whether PRD critical paths are mapped or coverage is smoke-only — see Step 2c.

**`qa.level`**: controls whether the suite is generated at
all. At `minimal`, the regression suite is **not generated** (report that and
stop); at `standard`, generate it at Hardening-phase entry; at `full`, at
Build-phase entry. Distinct axis from `workflow`.

## 1. Parse Arguments

**Early `qa.level` guard (resolved above):** if `qa.level: minimal`, the
regression suite is **not generated** — report "Regression suite not generated at
qa.level minimal" and **STOP here, before any scan**, in every mode
(`update` / `audit` / `report`). This is the `qa.level` axis; it is distinct from
the `workflow`-tier `minimal` branch in Step 2c (which only changes the
critical-path *source*, not *whether* the suite runs). Do not enter Step 2c's
`minimal` branch on account of `qa.level`.

**Modes:**
- `/regression-suite update` — scan new bug fixes this sprint and check
  for regression test presence; add new tests to the suite manifest
- `/regression-suite audit` — full audit of all PRD critical paths and critical
  user journeys vs. existing test coverage; flag paths with no regression test
- `/regression-suite report` — read-only status report (no writes); suitable
  for sprint reviews
- No argument — if a sprint is clearly active (`production/sprint-status.yaml`
  has stories with `status: in-progress` or `review`), run `update`. If ambiguous
  or no active sprint is detected, use `AskUserQuestion`:
  - Prompt: "No subcommand specified. Which mode do you want to run?"
  - Options:
    - `[A] update — scan new bug fixes this sprint and add missing regression tests`
    - `[B] audit — full audit of all PRD critical paths and critical journeys vs. existing test coverage`
    - `[C] report — read-only status report (no writes)`

---

## 2. Load Context

### Step 2a — Load existing regression suite

Read `tests/regression-suite.md` if it exists. Extract:
- Total registered regression tests
- Last updated date
- Any tests flagged as `STALE` or `QUARANTINED`

If it does not exist: note "No regression suite found — will create one."

### Step 2b — Load test inventory

Read `testing.patterns` and `testing.framework` from `project.yaml` with `Read`.
Glob every pattern of `testing.patterns`; if it is unset, use the `tests/**`
convention plus the co-located forms `**/*.test.*`, `**/*.spec.*`,
`**/__tests__/**`, `**/test_*.py`, `**/*Test.kt`, `**/*_test.dart`, and say so in
the report: `testing.patterns unset — using the tests/** convention`. In a
monorepo with co-located tests, "no file under `tests/`" is not "no test".

Exclude the scaffold's example files (basename containing `example`, written by
`/test-setup`), `tests/e2e/capture.spec.ts` and everything under `tests/helpers/`
and `tests/load/` — they are not regression tests.

For each file, note the feature (from the directory path or the file name) and
the test type (unit, integration, contract, E2E — from the folder or the
runner). Do not read test file contents unless needed for name-to-test mapping.

### Step 2c — Load PRD critical paths and critical journeys

For `audit` mode: read `design/product/feature-map.md` to get all features (its
`| Feature | Category | Layer | Tier | Status | PRD | Depends On |` table), then
scope the scan by each feature's workflow tier (resolved above):
- **`full`** — read the PRD and map critical paths from all sections.
- **`standard`** — same, from the required sections (Acceptance Criteria, Edge
  Cases, Functional Requirements, and Business Rules & Calculations where the
  feature defines numeric or policy rules).
  A feature pinned higher via `feature_overrides` is mapped at its higher tier.
- **`minimal`** — **skip the PRD critical-path scan**. Instead read the latest
  smoke-check report in `production/qa/smoke-*.md` and take the critical paths it
  exercises as the regression scope (Step 3 maps coverage against those, not PRD
  acceptance criteria). If no smoke report exists, report that and stop with
  **Verdict: NOT ASSESSED** — no smoke report found (`production/qa/smoke-*.md`,
  written by `/smoke-check`); nothing written. There is no critical-path source at
  minimal without one.

(Tier affects `audit` mode only; `update` and `report` modes are tier-independent.)

For each in-scope feature's PRD (feature-map Tier `MVP`, plus any later-tier
feature whose Status is already `Implemented`), extract — with a section grep
(`^## (Acceptance Criteria|Business Rules & Calculations|Edge Cases|Functional Requirements)`
on `design/prd/<feature>.md`, output with context) rather than a full read:
- Acceptance Criteria (these define the critical paths)
- Business Rules & Calculations (prices, fees, limits, quotas, eligibility and
  rounding rules must have regression tests)
- Edge Cases (known edge cases — network loss, retries, concurrency — should have
  regression tests)

**Critical user journeys** (every mode except `update`, at every tier): read
`docs/ops/slo.md` `## Critical User Journeys` when it exists. Each journey is a
critical path whose regression guard is an **E2E** test (for example "sign in with
Kakao → create a savings goal → register a Toss Payments auto-debit"). No
`docs/ops/slo.md` ⇒ say `NOT CHECKED — critical journeys: docs/ops/slo.md absent (written by /create-architecture)`.

For `update` mode: skip the full PRD scan. Instead read
`production/sprint-status.yaml` and the current sprint's story files to find
stories with `status: done` (`> **Status**: Complete`) this sprint.

### Step 2d — Load closed bugs

Glob `production/qa/bugs/BUG-*.md` and keep the bugs whose `**Status**:` is
`Verified Fixed` or `Closed` (a `Won't Fix` bug was never fixed and needs no
regression test). Note:
- Which story, feature or journey the bug was in, and its `**Severity**:`
  (`S1-Critical`, `S2-Major`, `S3-Minor`, `S4-Trivial`)
- Whether a regression test was mentioned in the fix description

---

## 3. Map Coverage — Critical Paths

For `audit` mode only. (At `minimal` the critical paths come from the smoke-check
report identified in Step 2c, not from PRD acceptance criteria — map coverage
against those smoke paths and skip the PRD-criterion loop below.)

For each PRD acceptance criterion, business rule and critical journey, determine
whether a test exists:

1. Grep the Step 2b inventory for the feature slug (for example `goals`), and
   inside those files for test names related to the criterion's key noun/verb or
   its `TR-<feature>-NNN` ID; critical journeys look for E2E tests under
   `tests/e2e/<journey>/` or the matching pattern
2. Assign coverage:

| Status | Meaning |
|--------|---------|
| **COVERED** | A test file exists that targets this criterion's logic or this journey end to end |
| **PARTIAL** | A test exists but doesn't cover all cases (e.g. happy path only, or one surface of a journey that ships on several) |
| **MISSING** | No test found for this critical path |
| **EXEMPT** | The criterion's evidence is by design not an automated test — a UI criterion evidenced by retained screenshots, or a Config criterion evidenced by the smoke check |

Story types and their evidence follow the five types of
`.claude/docs/coding-standards.md` (Logic, Integration, UI, E2E, Config); only UI
and Config criteria can be EXEMPT, and a UI criterion with a component test is
COVERED, not EXEMPT.

3. Elevate MISSING items that correspond to business rules & calculations, state
   machines, payment or authorization logic, or a critical user journey to
   **HIGH PRIORITY** gap — these are the most likely and most expensive
   regression sources.

---

## 4. Map Coverage — Fixed Bugs

For each closed bug:

1. Extract the feature slug from the bug's metadata (its story's `**PRD**:`
   field, or the component it names)
2. Grep that feature's tests (Step 2b inventory) for a test that references the
   bug ID (`BUG-0042`) or the specific failure scenario
3. Assign:
   - **HAS REGRESSION TEST** — a test was found that would catch this bug
   - **MISSING REGRESSION TEST** — bug was fixed but no test guards against recurrence

For MISSING REGRESSION TEST items:
- Flag them as regression gaps; `S1-Critical` and `S2-Major` bugs are HIGH priority
- Suggest the test file path following the stack's naming in `testing.patterns`
  and `testing.framework` — e.g. `apps/api/src/goals/goal-auto-debit.regression.test.ts`,
  `tests/integration/goals/test_bug_0042_regression.py`
- Note: "Without this test, this bug can silently return in a future sprint."

---

## 5. Detect Coverage Drift

Coverage drift occurs when the product grows but the regression suite doesn't.

Check for drift indicators:
- Stories completed this sprint with no corresponding test files
- New features added to `design/product/feature-map.md` since the last
  regression-suite update
- PRDs revised since the regression suite was last updated (compare each PRD's
  `> **Last Updated**:` date with the manifest's `Last Updated`, or ask the user)
- New journeys in `docs/ops/slo.md` `## Critical User Journeys` with no E2E test
- `tests/regression-suite.md` last-updated date vs. current date — if gap >
  2 sprints, flag as likely stale

---

## 6. Generate Report and Suite Manifest

### Report format (in conversation)

```
## Regression Suite Status

**Mode**: [update | audit | report]
**Existing registered tests**: [N]
**Test files scanned**: [N] ([testing.patterns | tests/** convention])

### Critical Path Coverage (audit mode only)
| Feature | Total ACs + rules | Covered | Partial | Missing | Exempt |
|---------|-------------------|---------|---------|---------|--------|
| [name] | [N] | [N] | [N] | [N] | [N] |

### Critical Journey Coverage (audit mode only)
| Journey (docs/ops/slo.md) | Surfaces | E2E Test | Status |
|---------------------------|----------|----------|--------|
| [journey] | web, ios | `tests/e2e/[journey]/[file]` | COVERED / PARTIAL / MISSING |

**Coverage rate (non-exempt)**: [N]% | NOT ASSESSED — [no PRDs found | no critical journeys found | no test files found]

### Bug Regression Coverage
| Bug ID | Feature | Severity | Has Regression Test? |
|--------|---------|----------|----------------------|
| BUG-NNNN | [feature] | S[N]-[label] | YES / NO ⚠ |

**Bugs without regression tests**: [N]

### Coverage Drift Indicators
[List new features, revised PRDs, new journeys or stories with no test coverage, or "None detected."]

### Recommended New Regression Tests
| Priority | Feature | Suggested Test File | Covers |
|----------|---------|---------------------|--------|
| HIGH | [feature] | `[path per testing.patterns]` | BUG-NNNN / AC-[N] / CUJ: [journey] |
| MEDIUM | [feature] | `[path per testing.patterns]` | [criterion] |
```

### Suite manifest format (`tests/regression-suite.md`)

> **Before computing coverage, check the denominator.** If the PRD and journey
> sources return **zero critical paths**, or the test globs return **zero test
> files**, do not emit a percentage — report
> `Coverage: NOT ASSESSED — [no PRDs found | no critical journeys found | no test files found]`
> and name which side was empty and the skill that produces it (`/map-features`
> and `/write-prd` for PRDs, `/create-architecture` for the critical journeys of
> `docs/ops/slo.md`, `/test-setup` for the test scaffold).
>
> A percentage computed from an empty denominator is not a low score; it is not a
> number. `0%` reads as "measured and terrible" and `100%` as "measured and
> perfect" — both are claims about a comparison that never happened. This is the
> same defect `/scope-check` carries a Phase 4 guard against, in the same words:
> *"a percentage computed from no baseline items is not a small number; it is not
> a number."*
>
> **A hand-written list of skills required to carry `NOT ASSESSED` pins what was
> known when it was written**, so a skill added later inherits no obligation and
> nothing notices. Derive that set rather than enumerating it.

The manifest is a curated index — not the tests themselves, but a registry
of which tests should always pass before a release:

```markdown
# Regression Suite Manifest

> Last Updated: [date]
> Total registered tests: [N]
> Coverage: [N]% of PRD critical paths and critical journeys | NOT ASSESSED — [no PRDs found | no critical journeys found | no test files found]

## How to run

[The commands that run the registered tests — `commands.test` and `commands.e2e`
from `project.yaml`, or the tag filter the project uses (e.g. `--grep @regression`)]

## Registered Regression Tests

### [Feature Name]

| Test File | Test Name (if known) | Covers | Added |
|-----------|----------------------|--------|-------|
| `[path]` | `[scenario → expected]` | AC-N / BUG-NNNN / CUJ: [journey] | [date] |

## Known Gaps

Tests that should exist but don't yet:

| Priority | Feature | Suggested Path | Covers | Reason Not Yet Written |
|----------|---------|----------------|--------|------------------------|
| HIGH | [feature] | `[path]` | BUG-NNNN | Bug fixed without test |

## Quarantined Tests

Tests that are flaky or disabled (do not gate CI):

| Test File | Test Name | Reason | Quarantined Since |
|-----------|-----------|--------|-------------------|
| (none) | | | |
```

---

## 7. Write Output

Ask: "May I write this to `tests/regression-suite.md`?" — naming whether it is a
new manifest or an update to the existing one.

For `update` mode: append new entries; never remove existing entries
(use `Edit` with targeted insertions).
For `audit` mode: rewrite the full manifest with updated coverage data.
For `report` mode: do not write anything.

After writing (if approved):

- For each HIGH priority gap: "Consider creating the missing regression test
  before the next sprint. Run `/test-helpers` for factories and fixtures, then
  write the test with `/dev-story` or a `/quick-spec` story."
- If bug regression gaps > 0: "These bugs can silently return without regression
  tests. The next sprint should include a story to write the missing tests
  (`/sprint-plan`)."
- If coverage drift detected: "Regression suite may be drifting. Consider
  running `/regression-suite audit` at the next sprint boundary."
- If the Quarantined Tests table is non-empty: "Run `/test-flakiness registry`
  for the fix direction of each quarantined test."

**Run verdict** — every run past the Step 1 `qa.level` guard, in every mode,
ends with exactly one of these; precedence
**BLOCKED > NOT ASSESSED > COMPLETE**:

- **Verdict: COMPLETE** — regression suite updated with coverage computed
  (`update` / `audit`); in `report` mode, which writes nothing, the status report
  was printed with coverage computed.
- **Verdict: NOT ASSESSED** — the coverage denominator was empty (the section 6
  denominator guard printed `Coverage: NOT ASSESSED — no PRDs found | no critical journeys found | no test files found`),
  or the `minimal`-tier audit stopped with no smoke report (Step 2c). Name the
  empty side and the skill that produces it (`/map-features` and `/write-prd` for
  PRDs, `/create-architecture` for the critical journeys of `docs/ops/slo.md`,
  `/test-setup` for the test scaffold, `/smoke-check` for the smoke report). The
  manifest may still be written, recording the gap on its `Coverage:` line, but
  the run is never COMPLETE. The same holds in `report` mode.
- **Verdict: BLOCKED** — the user declined the write; nothing was written.

---

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and
`autonomous` modes, see `.claude/docs/automation-modes.md` — the rules below
describe what collaborative mode requires, not universal behavior.

- **Never remove existing regression tests from the manifest** without
  explicit user approval — removing a test that was deliberately written is a
  regression risk itself
- **Gaps are advisory, not blocking** — surface them clearly but do not prevent
  other work from proceeding
- **Quarantine is not deletion** — tests with intermittent failures should be
  quarantined (noted in manifest) but not removed; they should be diagnosed and
  fixed with `/test-flakiness`
- **Ask before writing** — always confirm before creating or updating the manifest
