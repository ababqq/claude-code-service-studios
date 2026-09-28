# Skill Spec: /propagate-prd-change

> **Category**: pipeline
> **Priority**: high
> **Spec written**: 2026-09-28

## Skill Summary

`/propagate-prd-change design/prd/<feature>.md` handles a PRD revision cascade. It asks
git what changed (`git diff HEAD -- design/prd/<stem>.md`, widening to the last commit
that touched the file), maps every hunk to its PRD section by heading line numbers, and
writes a change summary. It then finds every artifact written against the PRD — ADRs
(requirement-table scan plus a prose recall net, full-reading only the matches), API
contract operations, data-model entities and migration plans, tracking-plan events,
stories citing the PRD, and downstream PRDs via `design/registry/entities.yaml` — and
classifies each (ADR: Still Valid / Needs Review / Likely Superseded; contract:
Unaffected / Additive / Breaking; entities: Unaffected / Additive / Migration needed /
Classification change; events: Unaffected / Added / Renamed or removed / Properties
changed; stories: Unaffected / Needs update / Blocked / Follow-up needed). The tier
scopes the cascade (`full` everything; `standard` without data model and tracking plan,
each named `NOT CHECKED`; `minimal` no cascade). It writes the report draft, applies the
review mode to **TD-CHANGE-IMPACT** (technical-director), resolves each affected item
with the user, and completes the report. It writes **only**
`docs/architecture/change-impact-YYYY-MM-DD-<prd-stem>.md` — ADRs, the contract, the data
model, the tracking plan, stories and the TR registry change through their owning skills,
which the report names.

Verdicts (the report's `> **Verdict**:` line): **COMPLETE** / **INCOMPLETE** /
**NOT ASSESSED**.

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`); `name: propagate-prd-change` equals the skill directory, the catalog `name` and this spec's basename
- [ ] `description` is exactly "A PRD changed — find stale ADRs, API contract operations, data model entities, tracking events and stories."; `argument-hint: "[design/prd/<feature>.md] [--review full|lean|solo]"`; `model: sonnet`; no `disable-model-invocation`, no `isolation`
- [ ] Bootstrap: the first body line is exactly `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,feature_overrides` `` and `allowed-tools` grants `Bash(bash "*/.claude/skills/propagate-prd-change/../../hooks/yaml-helper.sh" resolve_config *)`
- [ ] The line after the bootstrap block is exactly `` Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`. ``
- [ ] Automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") present verbatim right after that line
- [ ] `allowed-tools` is exactly: `Read, Glob, Grep, Write, Bash, Agent, AskUserQuestion` plus the grant — no `Edit`
- [ ] ≥2 phase headings (`## 1. Validate Argument` … `## 10. Follow-Up Actions`, incl. `## 6b. Director Gate — Technical Impact Review`)
- [ ] Verdict keywords present exactly: `COMPLETE`, `INCOMPLETE`, `NOT ASSESSED`; the tier lines `NOT CHECKED — data model (full tier only)` and `NOT CHECKED — tracking plan (full tier only)` present
- [ ] "May I write this to `docs/architecture/change-impact-YYYY-MM-DD-<prd-stem>.md`?" before the draft and again before the final report
- [ ] Output at the exact path `docs/architecture/change-impact-YYYY-MM-DD-<prd-stem>.md` (e.g. `change-impact-2026-11-02-goals.md`) with `> **Verdict**: <TOKEN>` directly under its H1; the report headings are `## Change Summary`, `## ADR Impact`, `## API Contract Impact`, `## Data Model Impact`, `## Tracking Plan Impact`, `## Story Impact`, `## Downstream PRDs`, `## Superseded Requirements`, `## Resolutions`, `## Open Items`
- [ ] TD-CHANGE-IMPACT review-mode check carries the lean suffix sentence; the spawn line is exactly `- Pass: changed PRD path · summary of the PRD diff · impact report draft path`; the reply's first line is parsed as `[TD-CHANGE-IMPACT]: TOKEN` and mapped into the three verdict classes (APPROVE-class, CONCERNS-class, REJECT-class) of `.claude/docs/director-gates.md` § Standard Verdict Format
- [ ] The skill states it never edits an ADR, the API contract, the data model, the tracking plan, a story or the TR registry
- [ ] No `!` injection other than the bootstrap line; no `file:line` citations of other files
- [ ] Next-step handoff names `/architecture-decision`, `/architecture-review`, `/api-design update <resource>`, `/api-design breaking-check`, `/data-model`, `/story-readiness`, `/create-stories`, `/consistency-check`, `/prd-review`

---

## Director Gate Checks

One gate: **TD-CHANGE-IMPACT** — `technical-director`, Domain "Change impact", verdicts
`APPROVE / CONCERNS / REJECT`. It reviews the written draft (Step 6) before resolution
(Step 7).

- **Full mode**: spawn with the `Pass:` line above (the draft path, or "not written — the
  draft follows inline" when the user declined the draft write); the prompt tells the
  agent to read `.claude/docs/director-gates/td-change-impact.md`.
- **Lean mode**: skip every gate whose ID does not end in `-PHASE-GATE` —
  `[TD-CHANGE-IMPACT] skipped — Lean mode`, written under the verdict line where the
  review line goes.
- **Solo mode**: `[TD-CHANGE-IMPACT] skipped — Solo mode` in the same place.
- In lean and solo the summary names the omission: "TD-CHANGE-IMPACT not consulted —
  <Mode> mode; `--review full` runs it."

---

## Test Cases

Fixtures use the Moa example: `design/prd/goals.md` changes the Free-plan limit on active
goals from 3 to 5 in `## Business Rules & Calculations` and renames the event
`goal_created` to `savings_goal_created` in `## Success Metrics & Instrumentation`.

### Case 1: Happy Path — full-tier cascade with every item resolved

**Fixture** (assumed project state):
- `modes.workflow: full`; review mode `lean` (gate behaviour is Cases 6–8)
- The change is uncommitted (`git diff HEAD` shows two hunks)
- `ADR-0006` tables `TR-goals-002` (the goal limit) in `## PRD Requirements Addressed`; `ADR-0001` does not cite goals
- `docs/api/openapi.yaml` has `createGoal`; `design/product/tracking-plan.md` lists `goal_created` with Owner PRD `design/prd/goals.md`
- Stories `story-001-create-goal.md` (`in-progress` in `production/sprint-status.yaml`) and `story-002-goal-limits.md` cite the PRD; `design/registry/entities.yaml` records `design/prd/subscription.md` in the limit rule's `referenced_by:`

**Expected behavior:**
1. Runs `git diff HEAD -- design/prd/goals.md` and maps each hunk to its section using `^##+ ` heading line numbers; prints the Change Summary
2. Greps the registry for `source: design/prd/goals.md` → downstream PRD `subscription`
3. Scans ADRs with the requirement-table grep and the recall net, full-reads only ADR-0006; checks the contract, the data model, the tracking plan and the stories; reports "Scanned [N] ADRs — [M] rely on design/prd/goals.md …"
4. Classifies: ADR-0006 Needs Review; `createGoal` Unaffected; `goal_created` Renamed or removed; both stories Needs update, the `in-progress` one named first with a pause note
5. Asks "May I write this to `docs/architecture/change-impact-YYYY-MM-DD-goals.md`? This is the draft the technical director reviews; resolutions are added after the review." and writes the draft with `> **Verdict**: INCOMPLETE`
6. Records `[TD-CHANGE-IMPACT] skipped — Lean mode`; resolves ADR-0006 in its own question, then each category; asks again before the final write; verdict **COMPLETE**

**Assertions:**
- [ ] Changed sections come from the git diff, not from reading both versions of the PRD
- [ ] The N − M non-matching ADRs are called out of scope, not "verified unaffected"
- [ ] The event rename is flagged as breaking dashboards and experiment readouts silently, with a transition-period recommendation
- [ ] `TR-goals-002` appears in `## Superseded Requirements`; the TR registry and `requirements-traceability.md` are not edited, and `/architecture-review` is recommended
- [ ] Only the change-impact report is written; each write follows its "May I write" answer
- [ ] Final report: `> **Verdict**: COMPLETE` with the skip note directly under it

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — deferred items leave the report INCOMPLETE

**Fixture:**
- Case 1 fixture; the user chooses "Defer (revisit later)" for ADR-0006

**Expected behavior:**
1. The deferral is recorded in `## Resolutions` and listed in `## Open Items`
2. The final report's verdict is **INCOMPLETE**
3. If the user declines the final write: "Verdict: INCOMPLETE — change-impact report not written (user declined)."

**Assertions:**
- [ ] A deferred or undecided item never yields COMPLETE
- [ ] `## Open Items` lists what remains
- [ ] Nothing other than the report is written in either variant

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: NOT ASSESSED — no argument, or no baseline

**Fixture:**
- (3a) No argument
- (3b) `design/prd/goals.md` has never been committed, `production/epics/goals-core/story-001-create-goal.md` cites it, and the user cannot say which sections changed

**Expected behavior:**
1. (3a) Stops with **NOT ASSESSED** and the usage text "Usage: `/propagate-prd-change design/prd/<feature>.md` …"
2. (3b) Asks which sections changed and what they said before; with no answer, stops with **NOT ASSESSED** ("no baseline — commit the PRD before revising it")

**Assertions:**
- [ ] Verdict is NOT ASSESSED with the missing input named — never COMPLETE, never "no impact"
- [ ] No report is written in either variant
- [ ] 3b contrast: an uncommitted PRD that nothing cites is "a new PRD, not a revision. Nothing to propagate." — verdict COMPLETE, nothing written
- [ ] A path under `design/prd/reviews/` or `design/product/` is rejected as not a feature PRD, and a path that does not exist gets "[path] not found. Check the path and try again." — both stop with NOT ASSESSED

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Mode Variant — `standard` and `minimal` tiers

**Fixture:**
- (4a) `modes.workflow: standard` (or `workflow_overrides.feature_overrides.goals: standard`)
- (4b) `modes.workflow: minimal`

**Expected behavior:**
1. (4a) ADR scope is the Foundation-layer ADRs plus any ADR citing the PRD; the contract, stories and downstream PRDs are checked; the report's `Not checked:` line carries `NOT CHECKED — data model (full tier only)` and `NOT CHECKED — tracking plan (full tier only)`
2. (4b) Reports "No architecture cascade at `minimal` workflow — the one-pager is the design record; the PRD change needs no impact analysis." — verdict **NOT ASSESSED**, nothing written

**Assertions:**
- [ ] The tier is resolved for the changed PRD's feature through `feature_overrides`
- [ ] A category the tier does not cover is named in the report, never silently absent
- [ ] 4b writes no file and spawns no agent

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Edge Case — ADRs without requirement tables; breaking contract change

**Fixture:**
- Five ADRs exist; none has a `## PRD Requirements Addressed` section and none mentions `design/prd/goals.md` or `TR-goals-`
- The diff also makes `targetDate` required in `## API & Data Impact`, which `createGoal` has as optional

**Expected behavior:**
1. Both ADR scans return 0 with N > 0; the follow-up grep finds no requirement table: "[5] ADRs found, none contains a `## PRD Requirements Addressed` section — traceability cannot be computed … Run `/architecture-decision retrofit <path>`."
2. The ADR category is **NOT ASSESSED**; the other categories are still assessed
3. `createGoal` is classified **Breaking** (a tightened validation), with a note that app builds already in users' hands keep calling the old shape

**Assertions:**
- [ ] A zero-match ADR scan is never reported as "no ADR impact" when the tables are missing
- [ ] `## ADR Impact` carries the NOT ASSESSED line
- [ ] The Breaking operation's follow-up is `/api-design update <resource>`, then `/api-design breaking-check`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Director Gate — full mode

**Fixture:**
- Case 1 fixture; review mode `full`; TD-CHANGE-IMPACT first returns REJECT ("ADR-0009 caches the limit in the API gateway and was missed"), then APPROVE

**Expected behavior:**
1. After the draft is written, spawns `technical-director` with `- Pass: changed PRD path · summary of the PRD diff · impact report draft path`
2. Parses `[TD-CHANGE-IMPACT]: TOKEN`
3. REJECT → re-analyzes (Steps 4–6) including ADR-0009 and offers the review again; the report stays INCOMPLETE meanwhile
4. APPROVE → proceeds to resolution; records `> **Technical Director Review (TD-CHANGE-IMPACT)**: APPROVED [date]` under the verdict line

**Assertions:**
- [ ] CONCERNS → `AskUserQuestion` with `Revise the impact assessment` / `Accept with noted concerns` / `Discuss further`; accepting records `CONCERNS (accepted) [date]` and copies the concerns into `## Open Items`
- [ ] A revision re-run records `REVISED [date]`
- [ ] A first line that does not parse, or names another gate, is treated as CONCERNS-class
- [ ] The parent never reads `.claude/docs/director-gates/td-change-impact.md`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: Director Gate — lean mode

**Fixture:**
- Case 1 fixture; review mode `lean`

**Expected behavior:**
1. TD-CHANGE-IMPACT is skipped

**Assertions:**
- [ ] No `technical-director` spawn
- [ ] The report carries `> [TD-CHANGE-IMPACT] skipped — Lean mode` directly under the verdict line
- [ ] The summary says "TD-CHANGE-IMPACT not consulted — Lean mode; `--review full` runs it."
- [ ] COMPLETE is reachable when every item has a decision other than Defer

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 8: Director Gate — solo mode

**Fixture:**
- Case 1 fixture; review mode `solo`

**Expected behavior:**
1. No director gates spawn

**Assertions:**
- [ ] In solo mode: no director gates spawn
- [ ] The report carries `> [TD-CHANGE-IMPACT] skipped — Solo mode` directly under the verdict line

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Computes the full impact before presenting anything; shows the full report before asking for any action
- [ ] Asks per ADR — ADR decisions are never batched
- [ ] "May I write this to `<path>`?" before the draft and before the final report
- [ ] Non-destructive: writes only the change-impact report; follow-ups name the owning skill for every other artifact
- [ ] Closes with the follow-up widget in collaborative and guided modes; in autonomous mode prints the verdict and follow-ups and logs them via `log_decision`
- [ ] Writes nothing under `production/session-logs/`; never writes `modes.review_mode` or any knob `modes.rigor` fronts

---

## Coverage Notes

- Pipeline rubric mapping: P1 (report schema and verdict line — Case 1), P2 (not
  applicable — the skill orders follow-ups by urgency, not by layer), P3 (May-I-write
  before the draft and the final report — Cases 1, 2), P4 (TD-CHANGE-IMPACT per review
  mode — Cases 6–8), P5 (diff, scans and full reads of the matched ADRs before writing —
  Case 1). The skill is not a catalog step (phase `any`).
- The ADR size check (`wc -c` under/over ~50KB, bounded reads of `## Context`,
  `## Decision`, `## Consequences`) is not fixture-tested.
- Hunks that only remove lines (mapped with the previous version's headings via
  `git show <base>:design/prd/<stem>.md`) are not fixture-tested.
