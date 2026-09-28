# Skill Test Spec: /estimate

## Skill Summary

`/estimate` estimates the effort of a task or story from its complexity, the code it
touches, its dependencies, historical velocity and service risk drivers. The argument
is a task description or a story path
(`production/epics/<epic-slug>/story-NNN-<slug>.md`); for a story it starts from the
header fields (`> **Type**:`, `> **Surface**:`, acceptance criteria,
`**API Contract**`, `**Migration**`, `**Feature Flag**`, `**Stack**` / `**Risk**`). It
reads the governing PRD (or `design/product/one-pager.md` when the feature has no PRD)
and ADRs, scans the affected code, and reads past sprints and the `## Metrics` /
`## Estimation Accuracy` sections of sprint retrospectives for velocity. The output
is a report in the conversation: a complexity table, a **Service Risk Drivers** table
(third-party/vendor integrations, migrations, store review lead time, compliance
items, unknown stack components with Knowledge Risk — each scored or `N/A` with a
reason), an optimistic / expected / pessimistic estimate in days, the recommended
budget (the expected value), a confidence level and a suggested breakdown. The skill
resolves no configuration, writes no file, spawns no agent and no director gate; its
closing verdict is **COMPLETE** — estimate generated, or **NOT ASSESSED** when the
named story path does not exist or cannot be parsed (it never estimates from a file
name alone). With no completed sprints it writes
`Velocity: NOT DETERMINED — no completed sprints in production/sprints/` and lowers
the confidence.

---

## Static Assertions (Structural)

Verified automatically by `/skill-test static` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] `name: estimate` equals the skill directory, the catalog `name` and this spec's basename
- [ ] No bootstrap line and no `resolve_config` grant — the skill resolves no configuration keys
- [ ] `allowed-tools` is exactly `Read, Glob, Grep` — membership exact; no Write, Edit, Bash, Agent or AskUserQuestion
- [ ] Has ≥2 phase headings
- [ ] Contains the verdict keyword COMPLETE, and NOT ASSESSED for an estimate that cannot be made (obligation 1)
- [ ] Contains the three scenario labels Optimistic, Expected, Pessimistic and the confidence levels High / Medium / Low
- [ ] Does NOT contain "May I write" language (read-only: "This skill is read-only — no files are written.")
- [ ] No `!` injection; no `file:line` citations
- [ ] Has a next-step handoff naming current skills (`/prototype --spike`, `/create-stories`, `/sprint-plan update`, `/sprint-plan new`)

---

## Director Gate Checks

None. Estimation is advisory; no gate is invoked, no agent is spawned, and no review
mode is resolved.

---

## Test Cases

### Case 1: Happy Path — clear story on a known stack

**Fixture:**
- `production/epics/goals-core/story-001-create-goal.md` exists with `> **Type**: Integration`, `> **Surface**: api`, 4 clear Given/When/Then acceptance criteria, `**API Contract**: POST /v1/goals (createGoal)`, `**Migration**: None`, `**Feature Flag**: goals.v2-progress-ring`
- `design/prd/goals.md` and an Accepted `docs/architecture/adr-0001-identity-and-auth.md` exist
- `production/sprints/sprint-01.md` … `sprint-03.md` and `production/retrospectives/retro-sprint-3-2026-09-18.md` (with `## Metrics`) exist
- `apps/api/src/modules/goals/` already has a similar handler and tests

**Input:** `/estimate production/epics/goals-core/story-001-create-goal.md`

**Expected behavior:**
1. Reads the story header fields and acceptance criteria, `CLAUDE.md`, the PRD and the governing ADR
2. Scans the affected module and its test coverage; reads sprint and retrospective data for similar completed stories
3. Scores the service risk drivers — vendor, migration, store review and compliance marked `N/A` with reasons; Knowledge Risk checked against `docs/stack-reference/VERSION.md`
4. Outputs the estimate template with a three-scenario table in half-day increments and a High or Medium confidence
5. No files are written; verdict COMPLETE

**Assertions:**
- [ ] The estimate is a range (optimistic / expected / pessimistic), not a single number
- [ ] Recommended budget equals the expected value, not the optimistic one
- [ ] Every risk-driver row is filled or `N/A` with a reason — none is blank
- [ ] Reasoning references the acceptance criteria, existing patterns and velocity data
- [ ] No files are written

---

### Case 2: High Uncertainty — Toss Payments auto-debit across three surfaces

**Fixture:**
- `production/epics/payments-core/story-004-toss-auto-debit.md` exists with `> **Surface**: web, ios, android, api`, vague acceptance criteria ("should handle failures gracefully", "TBD: retry schedule"), `**Migration**: docs/data/migrations/0003-payment-methods.md`
- The Toss Payments billing-key contract is pending approval (sandbox only)
- `docs/stack-reference/VERSION.md` marks the payments SDK component `HIGH` Knowledge Risk

**Input:** `/estimate production/epics/payments-core/story-004-toss-auto-debit.md`

**Expected behavior:**
1. Flags the vague criteria and the pending vendor approval
2. Applies each risk driver with its effect: vendor approval, expand/migrate/contract migration phases, store review days for the iOS and Android changes, compliance review for stored billing keys, a spike budget for the HIGH Knowledge Risk component
3. Produces a wide range with Low confidence and names the single biggest risk
4. Recommends a time-boxed spike (`/prototype --spike`) before committing, and `/create-stories` if the estimate exceeds 10 days

**Assertions:**
- [ ] Waiting time (vendor approval, store review) appears as named items in the estimate
- [ ] Three surfaces are counted as three implementations and three test passes
- [ ] Confidence is Low and the explanation names the drivers
- [ ] Risk is called out explicitly rather than padded silently
- [ ] No files are written

---

### Case 3: No Sprint History — velocity basis stated, not invented

**Fixture:**
- The Case 1 story file exists
- `production/sprints/` and `production/retrospectives/` are empty

**Input:** `/estimate production/epics/goals-core/story-001-create-goal.md`

**Expected behavior:**
1. Reads the story and code — assesses complexity
2. Finds no sprint or retrospective data
3. States in the output that no historical velocity exists and that the estimate rests on complexity and code scan alone
4. Lowers confidence accordingly; the estimate is still produced

**Assertions:**
- [ ] Skill does not error when no sprint history exists
- [ ] Output explicitly says historical velocity is unavailable (e.g., `NOT DETERMINED — no completed sprints`) instead of citing a velocity
- [ ] Confidence reflects the missing history (not High)
- [ ] An estimate is still produced

---

### Case 4: NOT ASSESSED — the story file does not exist

**Fixture:**
- `production/epics/goals-core/story-009-share-goal.md` does not exist
- No other file mentions "share goal"

**Input:** `/estimate production/epics/goals-core/story-009-share-goal.md`

**Expected behavior:**
1. Attempts to read the story — not found
2. Reports that the named story is missing and does not estimate from the file name alone
3. Verdict NOT ASSESSED, naming the missing path, with the next step (`/create-stories goals-core`, or re-run with a task description)

**Assertions:**
- [ ] Verdict is NOT ASSESSED (not COMPLETE) with the missing input named
- [ ] No day range is produced for the unread story
- [ ] Output names how to supply the input

---

### Case 5: Mode Variant — task description instead of a story path

**Fixture:**
- `design/prd/notifications.md` exists; `.claude/docs/compliance/kr.md` exists
- No story exists for the task

**Input:** `/estimate "Send a 알림톡 reminder when an auto-debit fails"`

**Expected behavior:**
1. Restates the task in 1–2 sentences; reads the notifications PRD
2. Scores the messaging vendor driver (template approval lead time) and the compliance driver (informational vs advertising message, consent), marks store review `N/A — server-side only`
3. Outputs the estimate template and closes with COMPLETE

**Assertions:**
- [ ] A task description is accepted as input (no story file required)
- [ ] Vendor template approval appears as a named waiting-time item
- [ ] The compliance row cites the regional reference rather than a remembered rule

---

### Case 6: Gate Compliance — no gate; estimates are informational

**Fixture:**
- The Case 1 story file exists
- `modes.review_mode: full` in `project.yaml`

**Input:** `/estimate production/epics/goals-core/story-001-create-goal.md`

**Expected behavior:**
1. Computes the estimate as in Case 1
2. No director gate or agent is invoked in any review mode
3. Next steps point to `/sprint-plan update` (current sprint) or `/sprint-plan new`

**Assertions:**
- [ ] No director gate is invoked regardless of review mode
- [ ] Output is purely informational — no approval or write prompt
- [ ] Next-step recommendation references `/sprint-plan`
- [ ] Estimate does not change based on review mode

---

## Protocol Compliance

- [ ] Reads the story (or task description), PRD and ADRs before estimating
- [ ] Reads sprint and retrospective history when available; says so when it is not
- [ ] Produces a range (optimistic / expected / pessimistic) in half-day increments, never hours for multi-day work
- [ ] Does not write any files
- [ ] No director gates are invoked and no configuration is resolved
- [ ] Verdict is COMPLETE, or NOT ASSESSED when the task or story cannot be read
- [ ] analysis AN1 — read-only scan (Read, Glob, Grep only)
- [ ] analysis AN2 — structured tables (complexity, service risk drivers, scenarios, risks, dependencies, breakdown)
- [ ] analysis AN3 — nothing to write; no write prompt
- [ ] analysis AN4 — no director gates
- [ ] Observation vs verdict: velocity and risk levels come from the files read; an absent input is stated, never filled with an assumed number

---

## Coverage Notes

- The skill does not produce PASS/FAIL verdicts; tests check the structure of the
  range, the reasoning and the stated inputs, not the accuracy of the day counts.
- Team-specific calibration (what one day means for this team) comes from the
  retrospective metrics and is not tested here.
- Rule-12 (the report verdict line) does not apply: the estimate is not written to a file.
