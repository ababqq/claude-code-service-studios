# Skill Spec: /milestone-review

> **Category**: sprint
> **Priority**: low
> **Spec written**: 2026-09-28

## Skill Summary

`/milestone-review` reviews a milestone (MVP, Private Beta, Public Beta, GA …): feature
completeness against the definition's Must Ship / Should Ship / Stretch lists, quality
and ops metrics (unresolved bugs by severity, crash-free sessions, error rate, API p95
latency, availability, smoke and QA sign-off verdicts), code health, risks, velocity and
scope recommendations, ending in a go/no-go recommendation. It checks its inputs first
and reports `NOT ASSESSED — NO DATA` for sections — or the whole verdict — whose inputs
are absent. The active milestone (`current` or no argument) is the newest
`production/milestones/*.md` **excluding** `*-review.md`. The review is written to
`production/milestones/<milestone>-review.md` with
`> **Verdict**: [GO | CONDITIONAL GO | NO-GO | NOT ASSESSED]` directly under its H1. The
DM-MILESTONE gate (milestone risk) runs in `full` review mode — on a draft written first
— and is skipped in `lean` and `solo` with a note. Skill verdicts: COMPLETE, BLOCKED, and
`NOT ASSESSED — NO DATA` as the whole verdict when every required input is absent.

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`); `name` is `milestone-review`, equal to the directory `.claude/skills/milestone-review/` and the catalog `name`
- [ ] Bootstrap: the first body line is `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation` `` and `allowed-tools` grants `Bash(bash "*/.claude/skills/milestone-review/../../hooks/yaml-helper.sh" resolve_config *)`
- [ ] `--keys` is exactly `review_mode,automation`
- [ ] The line after the bootstrap block is exactly: ``Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] Automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") present verbatim right after that line
- [ ] `allowed-tools` is exactly: `Read, Glob, Grep, Write, Agent, AskUserQuestion` plus the bootstrap grant — no `Edit`, no unrestricted `Bash`
- [ ] 2+ phase headings found (`## Phase 0: Parse Arguments` … `## Phase 5: Next Steps`, including `## Phase 3b: Delivery Risk Assessment`), preceded by `## Insufficient input — check this before producing any report`
- [ ] Verdict keywords present, exactly: report `GO`, `CONDITIONAL GO`, `NO-GO`, `NOT ASSESSED`; skill `COMPLETE`, `BLOCKED` (declined write, declined draft, or "Verdict: **BLOCKED** — DM-MILESTONE OFF TRACK unresolved."), and `NOT ASSESSED — NO DATA` as the whole verdict when every input is ABSENT; section value `NOT ASSESSED — NO DATA`; gate tokens `ON TRACK`, `AT RISK`, `OFF TRACK`
- [ ] "May I write this to `production/milestones/<milestone>-review.md`?" appears before the final write; at `full`, "May I write the draft review to `production/milestones/<milestone>-review.md` for the DM-MILESTONE review?" before the draft write
- [ ] Output at the exact path `production/milestones/<milestone>-review.md`, with `> **Verdict**: [GO | CONDITIONAL GO | NO-GO | NOT ASSESSED]` directly under the H1 `# Milestone Review: [Milestone Name]` and the `> **Delivery Manager Review (DM-MILESTONE)**:` line under it
- [ ] The active milestone is the newest `production/milestones/*.md` excluding `*-review.md`
- [ ] The sprint-plan grep alternates are exactly the `##` headings of `.claude/docs/templates/sprint-plan.md` — `^## (Sprint Goal|Milestone Context|Capacity|Tasks|Carryover|Risks|External Dependencies|Definition of Done)` — and no heading the template does not emit; `production/sprint-status.yaml` is read with the enum `backlog | ready-for-dev | in-progress | review | done | blocked`
- [ ] Unresolved bugs are counted by `**Severity**:` and `**Status**:` lines, with unresolved = `Open`, `In Progress`, `Fixed — Pending Verification`
- [ ] Phase 3b names DM-MILESTONE and contains the lean sentence verbatim: "`lean` → **skip every gate whose ID does not end in `-PHASE-GATE`**. Note: `[GATE-ID] skipped — Lean mode`"
- [ ] No `!` injection other than the bootstrap line; no `file:line` citations of other files
- [ ] Next steps name current skills: `/gate-check <target-phase>` (e.g. `/gate-check launch`), `/sprint-plan update`, `/sprint-plan new`, `/bug-triage`, `/retrospective <milestone-name>`

---

## Director Gate Checks

The skill spawns one gate, **DM-MILESTONE** (owner `delivery-manager`), in Phase 3b,
after the review is generated and before it is saved. At `full` the draft is written
first (with `> **Verdict**: NOT ASSESSED` and "pending DM-MILESTONE"); the spawn names
`.claude/docs/director-gates/dm-milestone.md` for the agent to read first, passes
`Pass: milestone review draft path · milestone definition path · `production/sprint-status.yaml` path · unresolved S1/S2 count`,
and parses the first line as `[DM-MILESTONE]: TOKEN` (`ON TRACK` / `AT RISK` / `OFF TRACK`).

- **Full mode**: DM-MILESTONE spawns
- **Lean mode**: skip every gate whose ID does not end in `-PHASE-GATE` — note `[DM-MILESTONE] skipped — Lean mode`
- **Solo mode**: no gates — note `[DM-MILESTONE] skipped — Solo mode`
- **Review-mode exempt**: not applicable
- When skipped, the note goes into the `> **Delivery Manager Review (DM-MILESTONE)**:` header line, the provisional recommendation of Phase 3 becomes final, and the summary says "DM-MILESTONE not consulted — <Mode> mode; `--review full` runs it."

---

## Test Cases

Quoted prompts, option labels and verdict tokens below are the canonical English text
of `SKILL.md`; at run time the model renders them in the user's conversation language.

### Case 1: Happy Path — Private Beta review, ON TRACK, GO

**Fixture** (assumed project state):
- `production/milestones/private-beta.md` (type Private Beta, target 2026-11-30, Must Ship: auth, onboarding, goals, payments; `## Quality Gates`: 0 unresolved S1, crash-free ≥ 99.5%, API p95 ≤ 300 ms)
- Sprint plans `production/sprints/sprint-01.md` … `sprint-04.md` built from the template; `production/sprint-status.yaml` with every Must Ship story `done`
- `production/qa/bugs/` holds 22 files: 0 unresolved S1, 1 unresolved S2 (`Fixed — Pending Verification`), 3 unresolved S3
- `production/qa/smoke-2026-11-20.md` (`> **Verdict**: PASS`), `production/qa/qa-signoff-sprint-04-2026-11-21.md` (`> **Verdict**: APPROVED`), `production/qa/load/load-test-load-2026-11-19.md` (p95 240 ms)
- Review mode: `full`

**Input:** `/milestone-review private-beta`

**Expected behavior:**
1. The insufficient-input check records each input FOUND or ABSENT
2. Phase 1 reads the definition and the sprint records (the grep over the template headings, then full reads of any plan with no match)
3. Phase 2 counts bugs by severity and status (1 unresolved S2 — `Fixed — Pending Verification` counts), reads the verdict lines, takes each metric's threshold from `## Quality Gates` and its measurement with source and date
4. Phase 3 derives the provisional recommendation GO
5. Phase 3b: "May I write the draft review to `production/milestones/private-beta-review.md` for the DM-MILESTONE review?"; `delivery-manager` receives the four Context items (unresolved count as "S1: 0, S2: 1"); `[DM-MILESTONE]: ON TRACK`
6. The header line records `APPROVED [date]`; Phase 4 asks "May I write this to `production/milestones/private-beta-review.md`?" → Verdict **COMPLETE**

**Assertions:**
- [ ] Every number in `## Quality Metrics` carries its source (file or dashboard, date)
- [ ] Unresolved bugs are counted by status and severity lines, never by `Open` alone
- [ ] The draft is on disk before DM-MILESTONE runs, with `> **Verdict**: NOT ASSESSED` until the gate has run
- [ ] The final review has `> **Verdict**: GO` directly under the H1
- [ ] The write happens only after "May I write"

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — Public Beta with an unresolved S1, OFF TRACK

**Fixture:**
- `production/milestones/public-beta.md` (target in 6 days); the payments Must Ship feature has 5 of 9 stories `done`, and velocity implies 11 more days
- `production/qa/bugs/BUG-0061.md`: `S1-Critical`, `**Status**: Open` (duplicate auto-debit on retry)
- Review mode: `full`

**Input:** `/milestone-review public-beta`

**Expected behavior:**
1. Phase 3's provisional recommendation is **NO-GO** (a Must Ship feature cannot finish by the target date; an unresolved S1 for a Public Beta)
2. DM-MILESTONE returns `[DM-MILESTONE]: OFF TRACK`
3. `AskUserQuestion`: "Delivery manager verdict: OFF TRACK. The milestone is in jeopardy. This review will recommend NO-GO. How do you want to proceed?" — `[A] Accept NO-GO …` / `[B] Override to CONDITIONAL GO …` / `[C] Stop …`
4. On [C] the skill stops, the draft keeps `> **Verdict**: NOT ASSESSED`, and the run ends "Verdict: **BLOCKED** — DM-MILESTONE OFF TRACK unresolved."

**Assertions:**
- [ ] An unresolved S1 for a Public Beta or GA milestone yields NO-GO
- [ ] No GO is issued against OFF TRACK unless the user explicitly selects the override
- [ ] Stopping leaves the draft at NOT ASSESSED — an abandoned draft never reads as a decision — and the run verdict is BLOCKED, never COMPLETE
- [ ] Cut candidates are listed with their impact in `## Scope Recommendations`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: NOT ASSESSED — No data, or no definition

**Fixture (variant A):** no milestone definition, no sprint plans, no `production/sprint-status.yaml`, no bug directory, no QA or perf reports

**Fixture (variant B):** sprint plans and the yaml exist, but `production/milestones/` holds no definition and `production/qa/bugs/` does not exist

**Input:** `/milestone-review current`

**Expected behavior (variant A):**
1. Every required input is ABSENT: the skill stops and reports `NOT ASSESSED — NO DATA` as the whole verdict, naming what was missing and which skill produces it
2. No gate is invoked; nothing is written

**Expected behavior (variant B):**
1. The skill says no definition exists and reviews against the sprint records alone — it does not fabricate a definition, a target date or quality gates
2. Target date, feature lists and quality-gate thresholds are `NOT ASSESSED — NO DATA`
3. Bug counts read "no bug files — bug counts NOT ASSESSED", not "0 bugs"
4. The recommendation is NOT ASSESSED when the feature or quality sections lack data

**Assertions:**
- [ ] With no inputs at all, the verdict is NOT ASSESSED — NO DATA, not a filled-in template
- [ ] A missing definition is never fabricated
- [ ] A missing bug directory is never reported as zero bugs
- [ ] The skill says which of "looked and found nothing" and "could not look" happened

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Mode Variant — `current` picks the definition, not the last review

**Fixture:**
- `production/milestones/mvp.md`, `production/milestones/private-beta.md`, and `production/milestones/mvp-review.md` (the most recently modified file)

**Input:** `/milestone-review current` (and `/milestone-review` with no argument)

**Expected behavior:**
1. The active milestone is `private-beta.md` — the newest file excluding `*-review.md`
2. The review is written to `production/milestones/private-beta-review.md`

**Assertions:**
- [ ] `*-review.md` files are never selected as the active milestone
- [ ] A named milestone reads `production/milestones/<milestone>.md` (kebab-case)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Edge Case — Threshold sources, N/A rows and a pre-template sprint plan

**Fixture:**
- The definition of a web-only GA milestone marks crash-free sessions N/A and has no error-rate row
- `project.yaml` sets `performance.error_rate_pct: 0.5`; the user reads 0.3% off Datadog for the last 7 days
- `production/sprints/sprint-01.md` predates the template and matches none of the grep headings

**Input:** `/milestone-review ga`

**Expected behavior:**
1. Crash-free sessions is `N/A`
2. The error-rate threshold falls back to `performance.error_rate_pct` read with Read; the measurement is recorded with "Datadog, [date range]"
3. `sprint-01.md` is read in full rather than dropped; any sprint that contributed nothing is reported

**Assertions:**
- [ ] The threshold chain is definition → `project.yaml` `performance.*` → `docs/ops/slo.md` → "no threshold set"
- [ ] A row with neither threshold nor measurement is `NOT ASSESSED — NO DATA`
- [ ] A zero-match sprint plan is full-read, never silently omitted

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Director Gate — full mode (AT RISK)

**Fixture:**
- As Case 1, but two Should Ship stories remain and velocity leaves one day of slack
- Review mode: `full`

**Input:** `/milestone-review private-beta`

**Expected behavior:**
1. DM-MILESTONE returns `[DM-MILESTONE]: AT RISK`
2. `AskUserQuestion`: "Delivery manager verdict: AT RISK. The milestone may slip. How should the Go/No-Go section be framed?" — `[A] CONDITIONAL GO …` / `[B] NO-GO …` / `[C] GO …` / `[D] Discuss further before deciding`
3. On [A] the conditions go into the review; the header line records `CONCERNS (accepted) [date]`

**Assertions:**
- [ ] In full mode DM-MILESTONE spawns with the gate file path and the four Context items
- [ ] A CONCERNS-class verdict is surfaced via AskUserQuestion before the recommendation is finalized
- [ ] A first line that does not parse is handled as CONCERNS-class, never as approval

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: Director Gate — lean mode

**Fixture:**
- As Case 1; review mode: `lean`

**Input:** `/milestone-review private-beta`

**Expected behavior:**
1. Phase 3b skips DM-MILESTONE; the header line reads `[DM-MILESTONE] skipped — Lean mode`
2. No draft is written for the gate; the provisional recommendation (GO) becomes final
3. The summary says "DM-MILESTONE not consulted — Lean mode; `--review full` runs it."; the user still approves the write

**Assertions:**
- [ ] Output contains `[DM-MILESTONE] skipped — Lean mode`
- [ ] No gate spawns (DM-MILESTONE does not end in `-PHASE-GATE`)
- [ ] Skipping the gate does not skip the write approval

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 8: Director Gate — solo mode

**Fixture:**
- As Case 1; `project.yaml` sets `modes.rigor: minimal` and no `modes.review_mode`

**Input:** `/milestone-review private-beta`

**Expected behavior:**
1. `review_mode` resolves to `solo`
2. The header line reads `[DM-MILESTONE] skipped — Solo mode`; the summary names the omission

**Assertions:**
- [ ] In solo mode no director gate spawns
- [ ] Output contains `[DM-MILESTONE] skipped — Solo mode`
- [ ] Nothing is written to `modes.review_mode` or any other rigor-fronted knob

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Shows the compiled review before invoking DM-MILESTONE (full) or asking to write
- [ ] Uses "May I write …" before the draft (at `full`) and before the final review; a declined draft write stops with BLOCKED and names `--review lean` as the way to review without the gate
- [ ] Ends with next steps naming current skills
- [ ] Does not auto-create files without user approval; never writes a milestone definition (those are authored by hand)
- [ ] Reads `production/sprint-status.yaml` with the hyphenated `in-progress` enum
- [ ] Writes no evidence, reports or plans under `production/session-logs/` (gitignored)
- [ ] Never writes `modes.review_mode` or any other knob that `modes.rigor` fronts

---

## Coverage Notes

- The debt-marker scan (`TODO|FIXME|HACK` across source files, leaving out `.claude/`,
  `design/`, `docs/` and `production/`) and the tech-debt register read are asserted by the
  skill text but not given a fixture.
- A missing risk register is noted rather than skipped; covered by the Phase 2 text.
- A declined user write in Phase 4 (Verdict **BLOCKED** — user declined write) mirrors the
  draft-decline path and is not given its own case.
