# Skill Test Spec: /qa-plan

## Skill Summary

`/qa-plan` generates the QA plan for a sprint, a feature or a single story. It reads the
in-scope stories with targeted section greps (type, surface, acceptance criteria, PRD /
TR-ID, `**API Contract**`, `**Migration**`, `**Feature Flag**`, `**Analytics Events**`),
mines each referenced PRD by that feature's workflow tier, and classifies every story by
the five story types of `.claude/docs/coding-standards.md` — Logic, Integration, UI, E2E,
Config. A story's declared `> **Type**:` is accepted as-is; a missing one is inferred and
flagged.

The plan is built from `.claude/docs/templates/test-plan.md`, the single source of its
headings — `## Story Coverage Summary`, `## Automated Tests Required`,
`## Manual QA Checklist`, `## Smoke Test Scope`, `## Usability / Beta Requirements`,
`## Non-Functional Checks`, `## Definition of Done — This Sprint` — because
`/smoke-check` reads `## Smoke Test Scope` and `/create-stories` reads
`## Automated Tests Required`. `qa.level` scales the plan (minimal: smoke and manual
only; full: every criterion and edge case mapped), and two floors survive every level:
the smoke check and the migration dry-run log. The accessibility row of
`## Non-Functional Checks` targets the resolved `accessibility.target` (unset ⇒
`NOT DETERMINED — accessibility.target unset`), and budgets come from `performance.*`
read from `project.yaml` — never an invented number.

Output: `production/qa/qa-plan-<sprint-slug>-YYYY-MM-DD.md`, written after approval; the
same approval may cover back-filling `## QA Test Cases` into the in-scope story files.
An empty scope is **NOT ASSESSED — no stories in scope** and produces no plan. No
director gates apply.

---

## Static Assertions (Structural)

Verified automatically by `/skill-test static` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] `name: qa-plan` equals the directory `.claude/skills/qa-plan/` and the catalog entry name
- [ ] First body line is exactly `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow,qa.level,feature_overrides,accessibility` `` — `--keys` is exactly `automation,workflow,qa.level,feature_overrides,accessibility`
- [ ] `allowed-tools` grants `Bash(bash "*/.claude/skills/qa-plan/../../hooks/yaml-helper.sh" resolve_config *)` (this skill's own directory)
- [ ] The line after the bootstrap block is exactly ``Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] The automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") follows that line verbatim
- [ ] `allowed-tools` is exactly `Read, Glob, Grep, Write, Edit, AskUserQuestion` plus the bootstrap grant — no `Agent`
- [ ] Has ≥2 phase headings (`## Phase 1: Parse Scope` … `## Phase 5: Write Output`)
- [ ] Contains the verdict keyword NOT ASSESSED (`NOT ASSESSED — no stories in scope`)
- [ ] Reads `.claude/docs/templates/test-plan.md` and contains no inline plan skeleton of its own
- [ ] Names the story types Logic, Integration, UI, E2E, Config and the five override keys `testing.strict.logic`, `testing.strict.integration`, `testing.strict.ui`, `testing.strict.e2e`, `testing.strict.config` (without resolving `testing.strict` itself)
- [ ] Contains the Phase 5 question "May I write this to production/qa/qa-plan-<sprint-slug>-YYYY-MM-DD.md? Choose output options:"
- [ ] Output path is exactly `production/qa/qa-plan-<sprint-slug>-YYYY-MM-DD.md`
- [ ] No `!` injection other than the bootstrap line; no `file:line` citation of another file
- [ ] Has a next-step handoff naming current skills (`/smoke-check sprint`, `/team-qa sprint`, `/story-done`)

---

## Director Gate Checks

None. `/qa-plan` is a planning utility. Story testability is reviewed by QL-STORY-READY
inside `/create-stories` and `/story-readiness`, not here.

---

## Test Cases

### Case 1: Happy Path — Sprint of five stories, one per type

**Fixture:**
- Canonical product Moa; `production/sprints/sprint-07.md` and `production/sprint-status.yaml` list five stories in `production/epics/goals-core/`:
  - `story-001-create-goal.md` — `> **Type**: Logic` (monthly debit rounding rule)
  - `story-002-goal-api.md` — `> **Type**: Integration`, `**API Contract**` `POST /goals`, `**Migration**` `docs/data/migrations/0003-goals-table.md`
  - `story-003-goal-card.md` — `> **Type**: UI`, Surface `web, ios`
  - `story-004-first-deposit-journey.md` — `> **Type**: E2E`
  - `story-005-free-plan-limit.md` — `> **Type**: Config`
- `design/prd/goals.md` exists; `modes.workflow` resolves to `standard`; `qa.level` resolves to `standard`

**Input:** `/qa-plan sprint`

**Expected behavior:**
1. Skill reports "Building QA plan for 5 stories in sprint-07."
2. Skill greps the story headers and sections instead of reading every story whole
3. Skill mines `design/prd/goals.md` at the standard tier (`## Acceptance Criteria`, `## Edge Cases`, `## Non-Functional Requirements`, plus `## Business Rules & Calculations` because the feature defines numeric rules)
4. Skill accepts each declared Type, prints the classification summary, then fills every section of the test-plan template
5. `story-002` appears on the **Migration stories** line with `production/qa/evidence/story-002-goal-api/migration-dry-run.log`
6. Skill asks the Phase 5 multi-select question and writes `production/qa/qa-plan-sprint-07-YYYY-MM-DD.md` on approval

**Assertions:**
- [ ] The plan's headings are the template's, byte for byte
- [ ] Every story appears in `## Story Coverage Summary` with Type, Surface, automated and manual requirement
- [ ] Logic, Integration and E2E stories each get a `###` block in `## Automated Tests Required` with a test path per `testing.patterns` (else `tests/unit/<feature>/`, `tests/integration/<feature>/`, `tests/contract/<feature>/`, `tests/e2e/<journey>/`)
- [ ] The Integration block includes the contract check against `docs/api/`, the authorization negative case and idempotency for the webhook path
- [ ] The migration floor is named for the migration story at this `qa.level`
- [ ] The plan is written only after the approval question

---

### Case 2: Story With No Acceptance Criteria — Flagged, not skipped

**Fixture:**
- Sprint plan lists three stories; one matched no `## Acceptance Criteria` in the grep

**Input:** `/qa-plan sprint`

**Expected behavior:**
1. Skill full-reads that one story and says so
2. The story is reported as a QA finding: it has no testable criteria
3. The other two stories are planned normally; the plan is still produced

**Assertions:**
- [ ] The story without criteria appears in the plan with the finding — it is never dropped
- [ ] The plan is not blocked by one story's gap
- [ ] The output suggests adding acceptance criteria before implementation

---

### Case 3: NOT ASSESSED — No stories in scope

**Fixture:**
- `production/sprints/` is empty; `production/sprint-status.yaml` does not exist

**Input:** `/qa-plan sprint`

**Expected behavior:**
1. Skill resolves the scope and counts zero stories
2. Skill reports `NOT ASSESSED — no stories in scope`, naming the scope searched and the empty path
3. Skill routes: "No sprint plan found. Run `/sprint-plan new`."
4. No plan is built and no write is offered

**Assertions:**
- [ ] Verdict is NOT ASSESSED with the searched scope named
- [ ] No plan document with empty tables is produced — a plan for zero stories is not a plan
- [ ] No write tool is called
- [ ] A sprint plan that lists no stories routes to `/create-stories [epic-slug]` instead

---

### Case 4: Mode Variant — `qa.level: minimal`

**Fixture:**
- Same sprint as Case 1; `qa.level` resolves to `minimal`

**Input:** `/qa-plan sprint`

**Expected behavior:**
1. `## Automated Tests Required` keeps its heading and says only "Not required at `qa.level: minimal` — manual and smoke verification only."
2. The Story Coverage Summary's "Automated Test Required" cells are blanked the same way
3. The Definition of Done drops the test-file and retained-evidence rows; acceptance-criteria verification, the migration floor and the smoke check remain

**Assertions:**
- [ ] No template heading is removed at minimal
- [ ] The migration floor and the smoke check survive `qa.level: minimal`
- [ ] Output differs from Case 1 only in the automated-test and DoD content

---

### Case 5: Feature Scope and Tier Override

**Fixture:**
- `workflow_overrides.feature_overrides.payments: full` in `project.yaml`; project `workflow` is `standard`
- Stories in `production/epics/payments-core/` name `design/prd/payments.md` in their `**PRD**:` line

**Input:** `/qa-plan feature: payments`

**Expected behavior:**
1. Skill keeps the stories whose `**PRD**:` names `design/prd/payments.md`
2. Because the `feature_overrides` line pins `payments` to `full`, the PRD is mined for all seven sections of the full tier (Acceptance Criteria, Edge Cases, Business Rules & Calculations, Functional Requirements incl. `### User Flows & States`, Non-Functional Requirements, Configuration & Flags, Success Metrics & Instrumentation)
3. The output file is `production/qa/qa-plan-payments-YYYY-MM-DD.md`

**Assertions:**
- [ ] The per-feature tier comes from the resolved `feature_overrides` line, not from the project tier
- [ ] Unset `performance.*` budgets read "budget unset — set `performance.*`" in `## Non-Functional Checks`, never an invented number
- [ ] Unset `testing.patterns` is announced and the `tests/**` convention is used
- [ ] With `accessibility.target` unset in the block (`accessibility.target: (unset -- ask; unset is not none)`), the accessibility row of `## Non-Functional Checks` reads `NOT DETERMINED — accessibility.target unset`; an absent `design/accessibility-requirements.md` is noted with `/ux-design accessibility`

---

### Case 6: Back-fill Option — Approval covers exactly the in-scope story files

**Fixture:**
- Same as Case 1

**Input:** `/qa-plan sprint` — the user selects both output options

**Expected behavior:**
1. The plan is written in full
2. For each Logic, Integration and E2E story, the `## QA Test Cases` section is replaced with its generated test specs (appended before `## Test Evidence` when absent); UI stories receive manual verification steps
3. No file outside the listed story paths is edited without its own question

**Assertions:**
- [ ] Selecting the back-fill option is the approval for exactly the in-scope story files listed in the plan
- [ ] Any other file needs its own "May I write this to `<path>`?"
- [ ] Next steps include `/smoke-check sprint` (after implementation) and `/team-qa sprint`

---

### Case 7: Director Gate Check — No gate; QA planning is a utility

**Fixture:**
- Sprint with valid stories and acceptance criteria

**Input:** `/qa-plan sprint`

**Expected behavior:**
1. Skill generates and writes the QA plan
2. No agents or director gates are spawned

**Assertions:**
- [ ] No director gate is invoked and no gate skip note appears
- [ ] The only verdict token the skill emits is NOT ASSESSED, for an empty scope

---

## Protocol Compliance

- [ ] Accepts a declared story Type; infers and flags a missing one
- [ ] Classifies an ambiguous Logic/Integration story as Integration
- [ ] Never invents test cases, budgets or an accessibility target beyond its sources
- [ ] Routes usability and beta evidence to `/usability-report` and `production/qa/usability/` — never `production/session-logs/`
- [ ] Asks before writing the plan and before back-filling any story file
- [ ] Ends with next steps naming current skills

---

## Coverage Notes

- The session-state checkpoint comment appended to `production/session-state/active.md`
  after writing is a session-continuity marker, not a plan artifact, and is not asserted
  here.
- Multi-sprint scopes are not tested; the skill plans one sprint, feature or story per run.
- The `story: <path>` scope follows the same path as Case 1 with N = 1 and is not
  fixture-tested separately.
