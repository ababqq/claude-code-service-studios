# Skill Spec: /retrospective

> **Category**: sprint
> **Priority**: low
> **Spec written**: 2026-09-28

## Skill Summary

`/retrospective` turns what happened into what changes next, in three modes:
**sprint** (`sprint-N` → `production/retrospectives/retro-sprint-<N>-YYYY-MM-DD.md`),
**milestone** (`<milestone-name>` → `production/retrospectives/retro-<milestone>-YYYY-MM-DD.md`)
and **release** (`release <version>` →
`production/retrospectives/retro-release-<version>-YYYY-MM-DD.md`). It checks for an
existing retrospective of the same scope, checks its required inputs before producing
anything (`NOT ASSESSED — NO DATA` when they are absent), loads sprint plans,
`production/sprint-status.yaml`, stories, bugs, QA and smoke verdicts, incidents,
hotfixes and git history, and analyzes delivery. Release mode reads
`production/releases/<version>/release-record.md` and adds the required section
`## Outcome vs Success Metrics`: for each shipped PRD the metric target, the observed
value or `NOT DETERMINED — <reason>`, and a per-feature decision
`KEEP | ITERATE | ROLL BACK | REMOVE` made by the user after consulting
`analytics-engineer`. An optional DORA section is computed only from records on disk.
Milestone and release retrospectives copy the headings of
`.claude/docs/templates/project-retrospective.md`. Verdicts: COMPLETE, BLOCKED,
NOT ASSESSED. No director gate.

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`); `name` is `retrospective`, equal to the directory `.claude/skills/retrospective/` and the catalog `name`
- [ ] `argument-hint` is `[sprint-N | <milestone-name> | release <version>]`
- [ ] Bootstrap: the first body line is `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation` `` and `allowed-tools` grants `Bash(bash "*/.claude/skills/retrospective/../../hooks/yaml-helper.sh" resolve_config *)`
- [ ] `--keys` is exactly `automation`
- [ ] The line after the bootstrap block is exactly: ``Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] Automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") present verbatim right after that line
- [ ] `allowed-tools` is exactly: `Read, Glob, Grep, Write, Bash, Agent, AskUserQuestion` plus the bootstrap grant — no `Edit`
- [ ] 2+ phase headings found (`## Phase 0: Configuration & Arguments` … `## Phase 7: Next Steps`, including `## Phase 2: Insufficient Input — Check Before Producing Anything`)
- [ ] Verdict keywords present, exactly: `COMPLETE`, `BLOCKED` (user declined write), run-level `NOT ASSESSED` (Phase 2 `[B] Stop` — "Verdict: **NOT ASSESSED** — no [sprint / milestone / release] data available."), section value `NOT ASSESSED — NO DATA`; per-feature decisions `KEEP`, `ITERATE`, `ROLL BACK`, `REMOVE`; `NOT DETERMINED — <reason>` for unsourced metrics
- [ ] One "May I write this to `<path>`?" per mode before the write: `production/retrospectives/retro-sprint-<N>-YYYY-MM-DD.md`, `production/retrospectives/retro-<milestone>-YYYY-MM-DD.md`, `production/retrospectives/retro-release-<version>-YYYY-MM-DD.md`; "May I overwrite `<path>`?" before replacing a same-day file
- [ ] Outputs at exactly those three path forms
- [ ] The sprint-mode format uses H2 headings, among them `## Metrics`, `## Velocity Trend` and `## Estimation Accuracy`
- [ ] Milestone and release modes read `.claude/docs/templates/project-retrospective.md` and copy its headings byte for byte; `## Outcome vs Success Metrics` is required in release mode
- [ ] Release mode reads `production/releases/<version>/release-record.md` and its `> **Verdict**:` line directly under the H1 (`COMPLETED`, `HALTED` or `ROLLED BACK`; `NOT ASSESSED` = the release is still in progress — said so, and the user asked whether to wait for `/team-release <version>` to close it)
- [ ] No `!` injection other than the bootstrap line; no `file:line` citations of other files
- [ ] Phase 7 next steps name current skills per mode (`/sprint-plan new`; `/gate-check`, `/milestone-review`; `/write-prd`, `/quick-spec`, `/rollout-plan <version> --feature <flag-key>`, `/propagate-prd-change`, `/tech-debt add`, `/postmortem <INC-id>`)

---

## Director Gate Checks

- **Full mode**: no gate
- **Lean mode**: no gate
- **Solo mode**: no gate
- **Review-mode exempt**: not applicable
- **N/A**: `review_mode` is not among the skill's keys; `analytics-engineer` is consulted in release mode as a consultant that recommends — it returns no gate verdict, and the product owner decides

---

## Test Cases

Quoted prompts, option labels and verdict tokens below are the canonical English text
of `SKILL.md`; at run time the model renders them in the user's conversation language.

### Case 1: Happy Path — Sprint 03 retrospective

**Fixture** (assumed project state):
- `production/sprints/sprint-03.md` (goal, dates 2026-10-05 to 2026-10-16, 9 committed stories with estimates)
- `production/sprint-status.yaml` with `sprint: 3`: 7 stories `done`, 1 `in-progress`, 1 `blocked` (Toss Payments sandbox access)
- `production/retrospectives/retro-sprint-02-2026-10-02.md` exists with three action items
- `docs/tech-debt-register.md` exists; no retrospective for sprint 03 yet

**Input:** `/retrospective sprint-03`

**Expected behavior:**
1. Phase 0: sprint mode; `<N>` is `03`, as the plan's file name writes it
2. Phase 1: no existing `retro-sprint-03-*.md`
3. Phase 2: required inputs FOUND
4. Phase 3a loads the plan, the yaml (noting discrepancies with the plan), stories, bugs by severity and unresolved status, QA and smoke verdict lines, incidents, hotfixes, the previous retrospective; 3d runs `git log --oneline --since=… --until=…`
5. Phase 4a: completion rate, carryover with times carried, unplanned work, estimation accuracy (share within ±20%), blockers with duration and prevention, debt counts by category versus the previous retrospective, previous action items followed up
6. Phase 5 produces the sprint format (`## Metrics`, `## Velocity Trend`, …, `## Action Items for Next Iteration`, `## Summary`) and presents the top findings
7. Phase 6: "May I write this to `production/retrospectives/retro-sprint-03-2026-10-16.md`?" → Verdict **COMPLETE**
8. Phase 7 offers `[A] Yes — open /sprint-plan new with the retro action items and velocity delta`

**Assertions:**
- [ ] The sprint plan and `production/sprint-status.yaml` are read before any output; the yaml's `done` status is authoritative for completion
- [ ] The output name keeps the plan's sprint number format (`retro-sprint-03-…`)
- [ ] Every metric carries a source; no number is invented
- [ ] Action items are 3–5, each with an owner and a deadline; recurring unaddressed items are called out
- [ ] Causes are systemic — no person is blamed
- [ ] The write happens only after "May I write"

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — Declined write (and, by contrast, no data and Stop)

**Fixture (variant A):** as Case 1; the user answers no to the write question

**Fixture (variant B):** `production/sprints/sprint-09.md` does not exist and the yaml's `sprint:` is 8; the user chooses `[B] Stop`

**Input:** `/retrospective sprint-03` (A) · `/retrospective sprint-09` (B)

**Expected behavior:**
1. Variant A: nothing is written; Verdict **BLOCKED** — user declined write
2. Variant B: Phase 2 reports `NOT ASSESSED — NO DATA`, names the missing plan and `/sprint-plan` as the skill that writes it, and offers `[A] Provide data manually` / `[B] Stop`; on Stop: Verdict **NOT ASSESSED** — no sprint data available

**Assertions:**
- [ ] A declined write yields BLOCKED, never COMPLETE
- [ ] Stopping on a missing required input yields NOT ASSESSED, never BLOCKED or COMPLETE
- [ ] Missing inputs are detected before any report is produced
- [ ] The missing input and the skill that produces it are named

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: NOT ASSESSED — Release mode without a release record

**Fixture:**
- `production/releases/1.4.0/` holds `release-checklist.md` and `rollout-plan.md` but NO `release-record.md`

**Input:** `/retrospective release 1.4.0`

**Expected behavior:**
1. Phase 2 checks the required release-mode input — `production/releases/1.4.0/release-record.md` — and records it ABSENT
2. The skill reports `NOT ASSESSED — NO DATA`, names the missing record and `/team-release` as the skill that writes it
3. `AskUserQuestion`: `[A] Provide data manually` (what shipped, when, which PRDs — each figure recorded as "provided in conversation, [date]") / `[B] Stop`; on Stop: Verdict **NOT ASSESSED** — no release data available, nothing written
4. Sections whose inputs are absent stay `NOT ASSESSED — NO DATA`; none is estimated or inferred from an adjacent artifact (the checklist is not a record of what shipped)

**Assertions:**
- [ ] The release record is required; its absence is NOT ASSESSED, not a filled-in report
- [ ] No section is estimated from adjacent artifacts
- [ ] Manually provided figures carry their source line
- [ ] The skill states that NOT ASSESSED is a correct answer, not a failure to hide

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Mode Variant — Release 1.4.0 outcomes against PRD success metrics

**Fixture:**
- `production/releases/1.4.0/release-record.md` with `> **Verdict**: COMPLETED`, shipped PRDs `design/prd/goals.md` and `design/prd/auth.md`, and stage timestamps
- `design/prd/goals.md` `## Success Metrics & Instrumentation`: share of new users creating a goal within 24 h, target +3 pp; `goal_created` is instrumented on web and iOS but not on Android
- `production/growth/first-goal-suggestion/readout.md` exists
- The release window has run 5 days; D7 retention is one of the auth metrics

**Input:** `/retrospective release 1.4.0`

**Expected behavior:**
1. Phase 3c reads the record, the rest of the record set, incidents and hotfixes in the window, each shipped PRD's success metrics and `## Configuration & Flags`, the tracking-plan rows and the readout
2. Phase 4b spawns `analytics-engineer` with the record path, PRD paths, tracking plan, readout path and window; it answers the six questions per metric and recommends a decision
3. Observed values come from the readout or from figures the user pastes with their dashboard and date range; the Android gap becomes `NOT DETERMINED — goal_created not instrumented on Android`; D7 retention becomes `NOT DETERMINED — 5 days of exposure; D7 retention readable from [date]`
4. One `AskUserQuestion` per feature (batched up to four): "[feature]: [metric] [observed] vs target [target]; guardrails [state]. Analytics recommends [DECISION]. What is the decision?" with `[A] KEEP` · `[B] ITERATE` · `[C] ROLL BACK` · `[D] REMOVE`
5. The report copies the template headings byte for byte, with `## Outcome vs Success Metrics` filled; a feature decided without outcome data says so ("ITERATE — decided without outcome data; re-read on [date]")
6. Phase 7 offers one follow-up per decision (e.g. KEEP → `/tech-debt add` for the release flag removal)

**Assertions:**
- [ ] `## Outcome vs Success Metrics` is present and filled per shipped PRD
- [ ] No observed value is invented; missing ones are NOT DETERMINED with a reason
- [ ] The decision is the user's; the analytics recommendation is recorded when it differs
- [ ] Headings come byte for byte from `.claude/docs/templates/project-retrospective.md`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Edge Case — Milestone mode and the optional DORA section

**Fixture:**
- `production/milestones/private-beta.md` and `production/milestones/private-beta-review.md` exist; the newest file in the directory is the review
- The milestone shipped nothing to external users
- The user asks for the DORA section; release records and hotfix records exist, CI deploy history does not

**Input:** `/retrospective` (no argument), then the milestone option

**Expected behavior:**
1. With no argument, `AskUserQuestion` offers `[A] The latest sprint`, `[B] The active milestone — private-beta`, `[C] The latest release`, `[D] Cancel`; the active milestone excludes `*-review.md`
2. Milestone mode reads the definition, its review's verdict line and metrics, and the sprints inside its dates
3. `## Outcome vs Success Metrics` carries "N/A — nothing shipped to users in this milestone"
4. `## Delivery Metrics (DORA — optional)` is included because the user asked; each metric is computed from records on disk or is `NOT DETERMINED — <reason>`; values are reported without grading against performance bands

**Assertions:**
- [ ] `*-review.md` files are never taken as the milestone definition
- [ ] Options with nothing behind them are left out of the no-argument question
- [ ] DORA appears only when asked for, and never with invented values

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Existing retrospective for the same scope

**Fixture:**
- `production/retrospectives/retro-sprint-03-2026-10-16.md` already exists

**Input:** `/retrospective sprint-03`

**Expected behavior:**
1. Phase 1 finds it and asks: `[A] Update existing — load it and add/revise sections with new data` / `[B] Start fresh — write a new retrospective dated today; the existing file stays as history`
2. [A] writes to the existing path after "May I write"; [B] writes a new dated file, and a same-day file at the target path is replaced only after "May I overwrite `<path>`?"

**Assertions:**
- [ ] An existing retrospective is detected before data is loaded
- [ ] Neither choice silently overwrites history

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: Hand-off argument from `/hotfix` and `/rollout-plan`

**Fixture:**
- `/hotfix` (not linked to an incident) and `/rollout-plan` hand off with `/retrospective release 1.4.1`
- `production/releases/1.4.1/release-record.md` exists with `> **Verdict**: ROLLED BACK`; `production/hotfixes/hotfix-2026-11-06-auto-debit-retry.md` references 1.4.1

**Input:** `/retrospective release 1.4.1`

**Expected behavior:**
1. `release <version>` is parsed as release mode (not as a milestone named "release")
2. The rolled-back release counts toward change failure rate when DORA is included; the hotfix counts as unplanned work
3. A SEV1 or SEV2 incident in the window without a postmortem is followed up with `/postmortem <INC-id>`

**Assertions:**
- [ ] `release <version>` is accepted as the argument form the ops skills hand off with
- [ ] The release record's verdict line is read directly under its H1
- [ ] Incidents without postmortems are surfaced as a follow-up

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses "May I write this to `<path>`?" before every write; nothing is written before the user has seen the draft
- [ ] Presents the top findings (and, in release mode, the per-feature decisions) before requesting approval
- [ ] Ends with mode-specific next steps
- [ ] Never changes a flag, a rollout or a PRD — it hands those off to the owning skill
- [ ] Blameless: systems, handoffs and incentives, never individuals
- [ ] Writes no evidence, reports or plans under `production/session-logs/` (gitignored); no sprint plan, sprint-status file or milestone record is written
- [ ] Never writes `modes.review_mode` or any other knob that `modes.rigor` fronts

---

## Coverage Notes

- A missing tech-debt register (`NOT CHECKED — no docs/tech-debt-register.md; /tech-debt
  scan creates it`) is asserted by the skill text and not given a fixture.
- Git history without window dates (`git log --oneline -20`, window stated as approximate)
  is covered by Phase 3d only.
- The `[A] Provide data manually` branch of Case 3 is asserted for its source line; its
  downstream analysis follows the normal release-mode path of Case 4.
- A release record whose verdict line is still `NOT ASSESSED` (the release in progress) is
  asserted by the static checks (said so; the user is asked whether to wait for
  `/team-release <version>`); not given a fixture.
