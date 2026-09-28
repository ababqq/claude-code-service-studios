# Skill Spec: /sprint-plan

> **Category**: sprint
> **Priority**: medium
> **Spec written**: 2026-09-28

## Skill Summary

`/sprint-plan` builds the next sprint from the active milestone (when one exists), the
previous sprint's velocity and carryover, and the `Ready` stories under
`production/epics/*/story-*.md`. `new` fills `.claude/docs/templates/sprint-plan.md`
byte for byte (Sprint Goal, Milestone Context, Capacity, Tasks by Must / Should / Nice
to Have, Carryover, Risks, External Dependencies, Definition of Done) and prepares
`production/sprint-status.yaml` with the status enum
`backlog | ready-for-dev | in-progress | review | done | blocked`; `update` revises the
current plan without resetting statuses; `status` reports in the conversation and
writes nothing. The DM-SPRINT gate (delivery feasibility) runs in `full` review mode and
is skipped in `lean` and `solo` with a note; a QA plan check runs in every mode. Both
files are written together after one approval. The skill **never writes
`modes.review_mode`** — the user changes review depth with `--review` for one run or
with `/settings`. Verdicts: COMPLETE, BLOCKED (a declined draft or final write, or an
UNREALISTIC verdict left unresolved), NOT ASSESSED (no stories to plan from).

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`); `name` is `sprint-plan`, equal to the directory `.claude/skills/sprint-plan/` and the catalog `name`
- [ ] Bootstrap: the first body line is `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,story_granularity,workflow` `` and `allowed-tools` grants `Bash(bash "*/.claude/skills/sprint-plan/../../hooks/yaml-helper.sh" resolve_config *)`
- [ ] `--keys` is exactly `review_mode,automation,story_granularity,workflow`
- [ ] The line after the bootstrap block is exactly: ``Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] Automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") present verbatim right after that line
- [ ] `allowed-tools` is exactly: `Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion` plus the bootstrap grant — no unrestricted `Bash`
- [ ] 2+ phase headings found (`## Phase 0: Parse Arguments` … `## Phase 6: Next Steps`, including `## Phase 4: Delivery Feasibility Gate` and `## Phase 5: QA Plan Gate`)
- [ ] Verdict keywords present: `COMPLETE`, `BLOCKED`, `NOT ASSESSED`; gate tokens `REALISTIC`, `CONCERNS`, `UNREALISTIC`; the stop lines "Verdict: **NOT ASSESSED** — no stories to plan from", "Verdict: **BLOCKED** — DM-SPRINT UNREALISTIC unresolved." and "Verdict: **BLOCKED** — user declined write." are present
- [ ] "May I write the sprint plan to `production/sprints/sprint-NN.md` and `production/sprint-status.yaml`?" appears before the final write; at `full`, "May I write the draft sprint plan to `production/sprints/sprint-NN.md` for the DM-SPRINT review? …" before the draft write; the risk-register offer asks "May I write this to `production/risk-register/<risk-slug>.md`?"
- [ ] Outputs at the exact paths `production/sprints/sprint-NN.md` (two-digit number) and `production/sprint-status.yaml`
- [ ] The yaml format lists the status values exactly `backlog | ready-for-dev | in-progress | review | done | blocked` — the hyphenated `in-progress` is the only accepted spelling — with the mapping to the story `> **Status**:` values (`ready-for-dev` ↔ `Ready`, `in-progress` ↔ `In Progress`, `review` ↔ `In Review`, `done` ↔ `Complete`, `blocked` ↔ `Blocked`)
- [ ] States that the skill never writes `modes.review_mode` — not to `project.yaml`, not to `project.local.yaml`, not on request mid-run — and points to `--review full|lean|solo` and `/settings modes.review_mode=<value>` (or `/settings --local …`)
- [ ] Phase 4 names DM-SPRINT and contains the lean sentence verbatim: "`lean` → **skip every gate whose ID does not end in `-PHASE-GATE`**. Note: `[GATE-ID] skipped — Lean mode`"
- [ ] Contains the default statement verbatim: "Unset on an unconfigured project: `modes.rigor` defaults to `minimal`, which resolves `review_mode` to `solo`."
- [ ] Stories are found with `Glob production/epics/*/story-*.md` and the status/type/surface/estimate grep; the plan template is `.claude/docs/templates/sprint-plan.md`
- [ ] No `!` injection other than the bootstrap line; no `file:line` citations of other files
- [ ] Next-step handoff names current skills: `/qa-plan sprint`, `/story-readiness [story-file]`, `/dev-story [story-file]`, `/sprint-status`, `/scope-check [feature-or-sprint]`, `/retrospective sprint-<N>`

---

## Director Gate Checks

The skill spawns one gate, **DM-SPRINT** (owner `delivery-manager`), in Phase 4, after the
plan draft is built and before the files are written. At `full` the draft plan is
written first so the gate can read it; the spawn names
`.claude/docs/director-gates/dm-sprint.md` for the agent to read first, passes
`Pass: sprint plan draft path · velocity of previous sprints (or "none") · story paths in the sprint`,
and parses the first line as `[DM-SPRINT]: TOKEN` (`REALISTIC` / `CONCERNS` / `UNREALISTIC`).

- **Full mode**: DM-SPRINT spawns
- **Lean mode**: skip every gate whose ID does not end in `-PHASE-GATE` — note `[DM-SPRINT] skipped — Lean mode`
- **Solo mode**: no gates — note `[DM-SPRINT] skipped — Solo mode`
- **Review-mode exempt**: not applicable
- The note (or the outcome `APPROVED [date] / CONCERNS (accepted) [date] / REVISED [date]`) replaces `pending` in the plan's `> **Delivery Manager Review (DM-SPRINT)**:` header line; the QA plan check of Phase 5 runs in every mode

---

## Test Cases

Quoted prompts, option labels and verdict tokens below are the canonical English text
of `SKILL.md`; at run time the model renders them in the user's conversation language.

### Case 1: Happy Path — Sprint 03 planned from Ready stories, DM-SPRINT REALISTIC

**Fixture** (assumed project state):
- `production/milestones/mvp.md` and `production/milestones/private-beta.md` (target date 2026-11-30) exist, and `production/milestones/mvp-review.md` is the most recently modified file in the directory
- `production/sprints/sprint-01.md` and `sprint-02.md` exist; `production/sprint-status.yaml` still has `sprint: 2` with 9 of 11 stories `done`
- 12 stories under `production/epics/goals-core/` and `production/epics/payments-auto-debit/` have `> **Status**: Ready` with Type, Surface and Estimate
- `production/qa/qa-plan-sprint-03-2026-10-02.md` exists
- Resolved block: `review_mode: full`, `story_granularity: balanced`, `workflow: standard`

**Input:** `/sprint-plan new`

**Expected behavior:**
1. Phase 1: the active milestone is `private-beta.md` (the newest file excluding `*-review.md`); velocity 9 of 11 from the yaml; carryover 2 stories; stories found by the Glob and the header grep; capacity reducers (holidays, time off, on-call, store review work) are asked about, not assumed zero
2. Phase 2 fills the template headings byte for byte; Must Have is the critical path to the sprint goal ("A user can create a savings goal and see its progress on web and mobile"); commitment sized to velocity and to 6–10 stories for `balanced`; owners are the routed engineers for each `**Surface**`
3. Phase 3 prepares the yaml in context without writing it
4. Phase 4: "May I write the draft sprint plan to `production/sprints/sprint-03.md` for the DM-SPRINT review? …"; `delivery-manager` spawned with the three Context items; `[DM-SPRINT]: REALISTIC`
5. Phase 5 finds the QA plan and notes its path
6. "May I write the sprint plan to `production/sprints/sprint-03.md` and `production/sprint-status.yaml`?" → both written; Verdict **COMPLETE**

**Assertions:**
- [ ] The milestone, the previous sprint's velocity and the backlog are read before the plan is drafted
- [ ] `*-review.md` is never taken as the active milestone
- [ ] Template headings are copied byte for byte (`/milestone-review` greps them)
- [ ] Must Have stories start as `ready-for-dev`; Should Have and Nice to Have as `backlog`; every status uses the hyphenated enum
- [ ] The yaml is not written before the gate and the QA plan check have run
- [ ] The plan and the yaml are written together after one approval

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — draft write declined at `full`

**Fixture:**
- Review mode: `full`
- 5 `Ready` stories exist

**Input:** `/sprint-plan new`

**Expected behavior:**
1. The draft plan is shown; before the gate the skill asks "May I write the draft sprint plan to `production/sprints/sprint-NN.md` for the DM-SPRINT review? (`production/sprint-status.yaml` is not written until the plan is final.)"
2. The user declines
3. Verdict **BLOCKED** — the DM-SPRINT review needs the draft on disk; the stop names re-running when ready, or `--review lean` to plan without the per-skill gate

**Assertions:**
- [ ] Nothing is written — neither `production/sprints/sprint-NN.md` nor `production/sprint-status.yaml`
- [ ] DM-SPRINT is not spawned
- [ ] The verdict is BLOCKED, never COMPLETE; configuration is untouched (no `modes.review_mode` write)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: NOT ASSESSED — Missing inputs are named, never filled

**Fixture:**
- No `production/milestones/` directory; no previous sprint plan; no `production/risk-register/`
- 5 `Ready` stories exist
- No QA plan for the sprint
- Review mode: `full`

**Input:** `/sprint-plan new`

**Expected behavior:**
1. Phase 1 notes "no milestone defined — planning against the story backlog alone" and continues — the milestone is never inferred from sprint files
2. Velocity is `none` and the skill says this is a calibration sprint; DM-SPRINT receives `none` for the velocity item
3. "no risk register — risks assessed from the sprint contents only" is stated once
4. Phase 5: no QA plan — the skill surfaces it and asks `[A] Run /qa-plan sprint now …` / `[B] Skip for now …`; on [B] the "No QA Plan" warning block is added directly under `## Definition of Done`

**Assertions:**
- [ ] Each absent input is named in the output, not skipped silently
- [ ] Absent velocity is passed to the gate as `none`, never as an invented figure
- [ ] A missing QA plan is surfaced in every review mode, and skipping it leaves the warning block in the plan
- [ ] A missing milestone never blocks planning

**Variant 3b — no stories in the backlog:**

**Fixture:**
- `production/epics/` holds EPIC.md files but no `story-*.md`

**Input:** `/sprint-plan new`

**Expected behavior:**
1. Phase 1 step 3: the Glob returns nothing
2. The skill says "No stories found under `production/epics/`. Run `/create-stories` first (at `standard`/`full`, `/create-epics` before it)."
3. Verdict **NOT ASSESSED** — no stories to plan from; no gate invoked; nothing written; configuration untouched

**Assertions:**
- [ ] No work items are invented
- [ ] DM-SPRINT is not invoked
- [ ] No file is written and no configuration is changed on the way to the stop

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Mode Variant — `update`, `status` and `workflow: minimal`

**Fixture:**
- Variant A: sprint 03 is running; the yaml has two stories `in-progress`, one `review`; the user wants to add one story and remove an `in-progress` one
- Variant B: same state
- Variant C: resolved `workflow: minimal`; `design/product/one-pager.md` has `## Build Order`

**Input:** `/sprint-plan update` (A) · `/sprint-plan status` (B) · `/sprint-plan new` (C)

**Expected behavior:**
1. Variant A: the current stories and statuses are presented; changes are gathered with `AskUserQuestion`; statuses of `in-progress`, `review` and `done` stories are kept; removing the `in-progress` story needs the user's explicit decision, recorded in carryover or risks; DM-SPRINT re-runs on the revised plan
2. Variant B: a status report in the conversation; nothing is written
3. Variant C: the skill says once that at `minimal` the one-pager's `## Build Order` already is the plan, then plans anyway because the user asked; the one-pager replaces per-feature PRDs as context

**Assertions:**
- [ ] `update` does not reset statuses
- [ ] `status` writes nothing
- [ ] At `minimal` the absent PRDs are not treated as missing work

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Edge Case — Carryover and a mid-run request to change review mode

**Fixture:**
- `production/sprint-status.yaml` (sprint 2) has two stories `in-progress` and one `blocked`
- Midway, the user says "switch this project to lean review from now on"

**Input:** `/sprint-plan new`

**Expected behavior:**
1. The carryover stories appear in `## Carryover from Sprint [N-1]` with reason and new estimate and keep their last status (`in-progress`, `blocked`) in the new yaml
2. Before replacing the previous sprint's yaml, the skill says `/retrospective sprint-02` should run first if that sprint's data is to be captured
3. The skill does not write `modes.review_mode`; it continues with the resolved value and points to `--review lean` for this run or `/settings modes.review_mode=lean`

**Assertions:**
- [ ] Open stories of the previous sprint are carried, not dropped
- [ ] The retrospective reminder precedes the yaml replacement
- [ ] `modes.review_mode` is never written, even on the user's request mid-run

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Director Gate — full mode (CONCERNS, then UNREALISTIC)

**Fixture:**
- 14 stories totalling 38 estimate days against 24 available person-days after reducers and the 20% buffer
- Review mode: `full`

**Input:** `/sprint-plan new`

**Expected behavior:**
1. The draft is written after its "May I write the draft sprint plan …" approval; `delivery-manager` is spawned with the draft path, the velocity figures (e.g. "sprint-02: 9 of 11 committed stories done, 27 of 34 estimate days") and every story path
2. `[DM-SPRINT]: CONCERNS` → `AskUserQuestion`: `[A] Accept and proceed …` / `[B] Revise — defer the flagged Should Have stories` / `[C] Revise — move the sprint dates or capacity` / `[D] Discuss further before deciding`; on [B] the plan is revised, re-presented and the draft updated after asking
3. Variant: `[DM-SPRINT]: UNREALISTIC` → the named stories are descoped, the draft updated and DM-SPRINT re-run; `production/sprint-status.yaml` is not written while the latest verdict is REJECT-class; if the user stops before the verdict clears: Verdict **BLOCKED** — DM-SPRINT UNREALISTIC unresolved
4. The outcome is recorded in the header line, e.g. `REVISED [date]`

**Assertions:**
- [ ] In full mode DM-SPRINT spawns with the gate file path and the three Context items
- [ ] A CONCERNS-class verdict is surfaced via AskUserQuestion before any final write
- [ ] The revised plan, not the original, is written
- [ ] The yaml is never written while the latest verdict is REJECT-class; stopping with UNREALISTIC unresolved ends BLOCKED, never COMPLETE
- [ ] A first line that does not parse is handled as CONCERNS-class

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: Director Gate — lean mode

**Fixture:**
- 6 `Ready` stories; review mode: `lean`

**Input:** `/sprint-plan new`

**Expected behavior:**
1. Phase 4 skips DM-SPRINT; the header line reads `> **Delivery Manager Review (DM-SPRINT)**: [DM-SPRINT] skipped — Lean mode`
2. The summary says "DM-SPRINT not consulted — Lean mode; `--review full` runs it."
3. No draft is written for the gate; Phase 5 runs; the user still approves the final write

**Assertions:**
- [ ] Output contains `[DM-SPRINT] skipped — Lean mode`
- [ ] No gate spawns (DM-SPRINT does not end in `-PHASE-GATE`)
- [ ] Skipping the gate does not skip the user's write approval

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 8: Director Gate — solo mode (unconfigured default)

**Fixture:**
- 6 `Ready` stories; `project.yaml` sets neither `modes.review_mode` nor `modes.rigor`

**Input:** `/sprint-plan new`

**Expected behavior:**
1. `review_mode` resolves to `solo` through the rigor default
2. Phase 4 skips DM-SPRINT with `[DM-SPRINT] skipped — Solo mode` in the header line
3. The QA plan check and the final approval still run

**Assertions:**
- [ ] In solo mode no director gate spawns
- [ ] Output contains `[DM-SPRINT] skipped — Solo mode`
- [ ] Nothing is written to `modes.review_mode` or any other rigor-fronted knob

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Shows the draft plan before invoking DM-SPRINT or asking to write
- [ ] Uses "May I write …" before the draft (at `full`), before the final plan and yaml, and before any risk-register entry
- [ ] Ends with next steps, `/qa-plan sprint` first when no QA plan exists
- [ ] Does not auto-create files without user approval
- [ ] Writes the hyphenated `in-progress` status only; the yaml enum is exactly `backlog | ready-for-dev | in-progress | review | done | blocked`
- [ ] Writes no evidence, reports or plans under `production/session-logs/` (gitignored)
- [ ] Never writes `modes.review_mode` or any other knob that `modes.rigor` fronts

---

## Coverage Notes

- The risk-register offer (High probability or High impact risks without an entry, drafted
  from `.claude/docs/templates/risk-register-entry.md`) is asserted by the static checks
  but not given its own fixture; a declined offer changes nothing else in the run.
- Story ordering by dependencies (a migration's Expand phase before the client story that
  needs it) is judged by the Must Have critical-path rule rather than a separate case.
- The scope-check reminder after writing is covered by the next-step assertion.
