# Skill Test Spec: /scope-check

## Skill Summary

`/scope-check` is a Haiku-tier, read-only skill that measures scope creep for a
feature, a sprint or a milestone. It compares a baseline with the current state:
for a feature, the PRD's `## Goals & Non-Goals` (goals in scope, non-goals explicitly
out) plus the `## Functional Requirements` and `## Acceptance Criteria` items the goals
cover; with no PRD (at `workflow: minimal` there are none), the one-pager's
`## Scope & Non-Goals` with `## Build Order` as the planned items; for a sprint, the
sprint plan's `## Tasks` as first planned; for a milestone, its feature lists (never a
`*-review.md`). The current state comes from stories whose `**PRD**:` names the PRD,
`production/sprint-status.yaml`, `git log`, TODO/FIXME comments, and new API
operations, flags and tracking events. The report stays in the conversation. Verdict
by net scope change: ≤10 % **PASS**, 10–25 % **CONCERNS**, 25–50 % and >50 % **FAIL**;
any Non-Goal now in scope makes it at least CONCERNS; a missing baseline file, a baseline
with no items or an unreadable current state is **NOT ASSESSED** (outranks PASS, below
CONCERNS and FAIL).
No configuration is resolved, no file is written, no gate is invoked.

---

## Static Assertions (Structural)

Verified automatically by `/skill-test static` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] `name: scope-check` equals the skill directory, the catalog `name` and this spec's basename
- [ ] `argument-hint` is exactly `"[feature-name | sprint-N | milestone-name]"` — the three baselines Phase 1 accepts
- [ ] No bootstrap line and no `resolve_config` grant — the skill resolves no configuration keys
- [ ] `allowed-tools` is exactly `Read, Glob, Grep, Bash` — membership exact; no Write, Edit, Agent or AskUserQuestion
- [ ] `model: haiku` (kept)
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: PASS, CONCERNS, FAIL, NOT ASSESSED — in the output line `**Scope Verdict: [PASS / CONCERNS / NOT ASSESSED / FAIL]**`
- [ ] Does NOT contain "May I write" language; states "This skill is read-only — it reports findings but writes no files."
- [ ] The report template contains `### Non-Goals Now in Scope` and `### Bloat Score`
- [ ] No `!` injection; no `file:line` citations
- [ ] Has a next-step handoff naming current skills (`/sprint-plan update`, `/estimate`, `/write-prd`, `/propagate-prd-change`, `/scope-check`)

---

## Director Gate Checks

None. Scope check is a read-only advisory skill; no gates are invoked and no review
mode is resolved.

---

## Test Cases

### Case 1: Happy Path — goals feature within 10 %

**Fixture:**
- `design/prd/goals.md` `## Goals & Non-Goals` plus the covered `## Functional Requirements` and `## Acceptance Criteria` items enumerate 10 planned items; Non-Goals: "No shared or family goals in v1", "No investment products"
- `production/epics/goals-core/story-*.md` with `**PRD**: design/prd/goals.md` cover the 10 items plus one justified addition (an empty-state CTA)
- `production/sprint-status.yaml` shows their statuses; `git log` since the PRD date touches only `apps/api/src/modules/goals` and `apps/web/app/goals`

**Input:** `/scope-check goals`

**Expected behavior:**
1. Reads the PRD baseline (Goals & Non-Goals, covered requirements)
2. Reads stories, sprint status, commits, new operations, flags and events for the feature
3. Produces the comparison report: 1 addition, 0 removals, net +10 %
4. Verdict **PASS** — On Track

**Assertions:**
- [ ] The report names the baseline (`design/prd/goals.md` § Goals & Non-Goals)
- [ ] The Bloat Score shows original items 10, items added 1 (+10 %)
- [ ] Verdict is PASS when the net change is ≤10 % and no Non-Goal is in scope
- [ ] No files are written; sprint and PRD files are not modified

---

### Case 2: Scope Creep Detected — a Non-Goal is being built

**Fixture:**
- `design/prd/goals.md` as in Case 1 (10 planned items; Non-Goal "No shared or family goals in v1")
- Four stories were added after the baseline date, including `production/epics/goals-core/story-007-invite-family-member.md` and a new operation `POST /v1/goals/{goalId}/members` in `docs/api/openapi.yaml`

**Input:** `/scope-check goals`

**Expected behavior:**
1. Reads baseline and current state; counts 4 additions (+40 %)
2. Lists the family-goal work under `### Non-Goals Now in Scope` with its evidence (story, endpoint) and who must decide
3. Puts it in the **Flag** recommendation (product-manager for feature scope, delivery-manager for schedule)
4. Verdict **FAIL** — Significant Creep

**Assertions:**
- [ ] Out-of-scope additions are named explicitly with their source
- [ ] A Non-Goal now in scope is always a Flag item, pointing to either a PRD change (`/write-prd goals`, then `/propagate-prd-change design/prd/goals.md`) or stopping the work
- [ ] Verdict is FAIL for +25–50 %
- [ ] Skill does not remove stories — findings are advisory

---

### Case 3: NOT ASSESSED — baseline present but empty

**Fixture:**
- `design/prd/goals.md` exists, but `## Goals & Non-Goals` and `## Functional Requirements` hold only template placeholders
- Stories and commits for the feature exist

**Input:** `/scope-check goals`

**Expected behavior:**
1. Finds the baseline file, but it enumerates no scope items
2. Does not render the numeric block; writes `Baseline unusable — see verdict` with the reason
3. Verdict **NOT ASSESSED** — which side could not be read, and why
4. Next step: populate the baseline's `## Goals & Non-Goals`; no re-run against the same inputs is offered

**Assertions:**
- [ ] Verdict is NOT ASSESSED, never PASS from a 0 % change over zero items
- [ ] No `Original items: 0 / Net scope change: 0%` block is rendered
- [ ] The reason names the empty baseline section

---

### Case 4: Mode Variant — sprint baseline and the `minimal` one-pager

**Fixture:**
- Run A: `production/sprints/sprint-03.md` with a `## Tasks` table of 12 stories as first planned; 2 stories added mid-sprint
- Run B: no `design/prd/` files (`workflow: minimal`); `design/product/one-pager.md` has `## Scope & Non-Goals` and a `## Build Order` of 6 items; 2 unplanned items are in progress

**Input:** `/scope-check sprint-3` (Run A), `/scope-check goals` (Run B)

**Expected behavior:**
1. Run A: baseline = the sprint plan's Tasks; each story's PRD Goals & Non-Goals is the secondary baseline; +16.7 % → CONCERNS
2. Run B: baseline = the one-pager's `## Scope & Non-Goals` with `## Build Order` items; +33 % → FAIL

**Assertions:**
- [ ] A sprint argument is accepted and resolved to `production/sprints/sprint-03.md`
- [ ] With no PRD, the one-pager sections are used as the baseline
- [ ] CONCERNS output offers to identify the 2–3 additions with the best cut ratio and references `/sprint-plan update`

---

### Case 5: Edge Case — baseline file missing, current state unreadable

**Fixture:**
- Run A: `/scope-check wallet` — no `design/prd/wallet.md` and no one-pager
- Run B: `design/prd/goals.md` has a populated baseline, but no story names it, no commit exists in the window, and nothing is in progress

**Input:** `/scope-check wallet` (A), `/scope-check goals` (B)

**Expected behavior:**
1. Run A: reports the missing baseline file and stops without a comparison, with `**Scope Verdict: NOT ASSESSED**` — no baseline: the path looked for, not found
2. Run B: the current state cannot be determined → NOT ASSESSED, not a 0 % change

**Assertions:**
- [ ] Run A names the file it looked for, does not proceed without a baseline, and its verdict is NOT ASSESSED
- [ ] Run B's verdict is NOT ASSESSED with the unreadable side named
- [ ] Neither run renders a percentage

---

### Case 6: Gate Compliance — no gate; decisions go to the named roles

**Fixture:**
- The Case 2 project
- `modes.review_mode: full` in `project.yaml`

**Input:** `/scope-check goals`

**Expected behavior:**
1. Identifies the additions and the Non-Goal as in Case 2
2. No director gate is invoked regardless of review mode
3. Recommends escalation to delivery-manager (schedule) and a product-manager decision (feature scope)
4. Ends with "Run `/scope-check [name]` again after cuts are made to verify the verdict improves."

**Assertions:**
- [ ] No director gate is invoked in any review mode
- [ ] Escalation is suggested, not mandated; no files are written
- [ ] The closing line is present

---

## Protocol Compliance

- [ ] Reads the baseline and the current state before analysis
- [ ] Quantifies every change (items added and removed, net percentage) or says why it cannot
- [ ] Does not write any files
- [ ] No director gates are invoked; no configuration is resolved
- [ ] Runs on the Haiku model tier
- [ ] Verdict is one of: PASS, CONCERNS, FAIL, NOT ASSESSED
- [ ] analysis AN1 — read-only scan (Read, Glob, Grep; Bash only for `git log`)
- [ ] analysis AN2 — additions, removals and Non-Goals are tables; risk levels are stated per dimension
- [ ] analysis AN3 — nothing is written; cuts and re-plans go through `/sprint-plan update`
- [ ] analysis AN4 — no director gates
- [ ] Observation vs verdict: counts come from the files and commits read; NOT ASSESSED replaces any percentage whose denominator is empty

---

## Coverage Notes

- Partial overlap (a story that serves a goal but adds new behaviour) is judged by the
  model; the spec checks only that it is listed as an addition with a justification.
- Milestone mode (`production/milestones/<name>.md`, never `*-review.md`) is not
  exercised by a fixture here.
- The catalog step `scope-check` has no artifact (the report is conversational), so
  `/help` shows it as a repeatable optional step with no completion check.
