# Skill Spec: /usability-report

> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-09-28

## Skill Summary

`/usability-report` plans and reports user research in three types: `usability`
(task-based sessions on a clickable prototype, the walking skeleton, staging or a store
test build), `beta` (a private or public beta cohort on a real build) and `interview`
(discovery / JTBD interviews). `new` writes a **session plan** before any session runs
— hypotheses (one primary), participant criteria, tasks with success criteria,
discussion guide, metric definitions, environment, consent — with `> **Stage**: plan`
and verdict NOT ASSESSED. `analyze <path-to-notes>` spawns `ux-researcher` to turn raw
notes into the structured report: participants by code (P1…Pn), tasks with success
`x of n`, time on task, errors, SEQ per task, optional SUS; for `beta` also crash-free
sessions %, activation, D1/D7 retention, NPS/CSAT; for `interview` themes; issues with
severity `Critical | Serious | Minor | Cosmetic`; hypotheses `Supported | Refuted |
Inconclusive`; and action routing to the skill that owns each fix.

Output: `production/qa/usability/usability-YYYY-MM-DD-<slug>.md` — never
`production/session-logs/` — with `> **Verdict**: ACTIONABLE | INCONCLUSIVE | NOT
ASSESSED` directly under its H1. After an analyzed report, the skill runs the director
gate **PD-USER-VALIDATION** (product-director) under the review-mode rules: `full`
spawns it; `lean` and `solo` skip it (its ID does not end in `-PHASE-GATE`) and record
the skip note in `## Director Review`. The gate never changes the report's verdict by
itself.

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`); `name: usability-report` equals the skill directory and the catalog `name`
- [ ] Bootstrap: the first body line is exactly `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation` `` and `allowed-tools` grants `Bash(bash "*/.claude/skills/usability-report/../../hooks/yaml-helper.sh" resolve_config *)`
- [ ] `--keys` is exactly `review_mode,automation`
- [ ] The line after the bootstrap block is exactly the `--review` variant: ``Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] Automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") present verbatim right after that line
- [ ] `allowed-tools` is exactly: `Read, Glob, Grep, Write, Agent, AskUserQuestion` plus the bootstrap grant — no `Edit`, no plain `Bash`
- [ ] `argument-hint` is `"[new | analyze <path-to-notes>] [--type usability|beta|interview] [--review full|lean|solo]"`
- [ ] 2+ phase headings found (`## Phase 0: Parse Arguments` … `## Phase 6: Next Steps`, incl. `## Phase 5: Director Review — PD-USER-VALIDATION`)
- [ ] Verdict keywords present, exactly: `ACTIONABLE`, `INCONCLUSIVE`, `NOT ASSESSED`; issue severities `Critical`, `Serious`, `Minor`, `Cosmetic`
- [ ] Gate spawning: names PD-USER-VALIDATION, has a review-mode check with the lean suffix rule sentence "`lean` → **skip every gate whose ID does not end in `-PHASE-GATE`**. Note: `[GATE-ID] skipped — Lean mode`" and the solo note `[GATE-ID] skipped — Solo mode`
- [ ] The spawn passes the gate file path `.claude/docs/director-gates/pd-user-validation.md` (read by the agent, not the parent) and the line `Pass: report path (usability report, prototype REPORT.md or walking-skeleton report) · hypotheses tested · target segment · brief path`
- [ ] Parses the agent's first line as `[PD-USER-VALIDATION]: TOKEN` (APPROVE / CONCERNS / REJECT)
- [ ] "May I write this to `production/qa/usability/usability-YYYY-MM-DD-<slug>.md`?" before every write (plan, report, director review update)
- [ ] Output at the exact path `production/qa/usability/usability-YYYY-MM-DD-<slug>.md`, with `> **Verdict**: [ACTIONABLE | INCONCLUSIVE | NOT ASSESSED]` directly under its H1
- [ ] No `!` injection other than the bootstrap line; no `file:line` citations of other files
- [ ] Next-step handoff present at end (closing `AskUserQuestion`), naming current skills: `/usability-report analyze`, `/usability-report new`, `/write-prd`, `/propagate-prd-change`, `/quick-spec`, `/ux-design`, `/ux-review`, `/team-content`, `/business-rules-check`, `/bug-report`, `/perf-profile`, `/gate-check build`, `/gate-check launch`

---

## Director Gate Checks

PD-USER-VALIDATION (owner `product-director`, verdicts APPROVE / CONCERNS / REJECT) runs
after an **analyzed** report is written. The spawn passes the gate file path plus the
four Context bullets on a `Pass:` line and parses the first line of the reply; the
outcome is recorded in the report's `## Director Review` as
`> **Product Director Review (PD-USER-VALIDATION)**: APPROVED <date>` /
`CONCERNS (accepted) <date>` / `REVISED <date>`.

- **Full mode**: PD-USER-VALIDATION spawns
- **Lean mode**: skip every gate whose ID does not end in `-PHASE-GATE` — note `[PD-USER-VALIDATION] skipped — Lean mode` (no gate of this skill still runs)
- **Solo mode**: no gates — note `[PD-USER-VALIDATION] skipped — Solo mode`
- **Plan or NOT ASSESSED report**: no evidence to review — the line is `> [PD-USER-VALIDATION] not run — verdict NOT ASSESSED`

---

## Test Cases

Fixtures use the canonical product Moa (B2C savings app for the Korean market);
the target segment is salaried people in Korea in their 20s–30s saving toward a goal.

### Case 1: Happy Path — Analyze sessions against a pre-registered plan

**Fixture** (assumed project state):
- `production/qa/usability/usability-2026-11-03-goals-onboarding.md` is a plan: `> **Stage**: plan`, `> **Verdict**: NOT ASSESSED`, primary hypothesis H1 "Users who reach the auto-debit step authorise it without help (≥ 4 of 5 participants, SEQ ≥ 5)"
- Session notes at `research/goals-onboarding-notes.md` for five in-segment participants on a TestFlight build
- `design/product/product-brief.md` and `design/prd/goals.md` exist; `review_mode` resolves to `solo`

**Input**: `/usability-report analyze research/goals-onboarding-notes.md --type usability`

**Expected behavior**:
1. Phase 0 finds the matching plan and asks whether these notes complete it; the hypotheses count as pre-registered
2. Phase 1 reads only the named sections of the brief, PRD, journey and UX specs and records each input as `FOUND` or `ABSENT`
3. Phase 2B spawns `ux-researcher` with the notes path, hypotheses, type and metric definitions, and the return contract (no file written)
4. The report fills `## Hypotheses`, `## Participants`, `## Tasks`, `## Issues`, `## Quotes`, `## Recommendations` with counts as `x of n`, participant codes only, and quotes verbatim in Korean as spoken
5. H1 is Supported (5 of 5); the verdict is ACTIONABLE; Phase 3 routes each issue to its owning skill
6. Phase 4 asks "May I replace the plan at `<path>` with the full report?"

**Assertions**:
- [ ] The report is written to the plan's own path under `production/qa/usability/`
- [ ] `> **Verdict**: ACTIONABLE` sits directly under the H1; `> **Hypotheses pre-registered**: yes — plan written 2026-11-03`
- [ ] No names, phone numbers, e-mail addresses or account identifiers appear — codes P1…P5 only
- [ ] Behaviour ("did") is separated from opinion ("said")
- [ ] No percentages are reported from five sessions

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — Evidence that cannot support a decision

**Fixture**:
- Notes from four sessions with team members' friends (outside the target segment); no plan exists; the hypotheses are stated only now
- The notes contain no SEQ answers although the task-based study needed them

**Input**: `/usability-report analyze research/checkout-notes.md --type usability`

**Expected behavior**:
1. The report records `> **Hypotheses pre-registered**: no — stated after the sessions`
2. SEQ is `NOT ASSESSED — not in the data`; nothing is back-filled
3. The verdict is INCONCLUSIVE, with the reasons (participants outside the segment, hypotheses written after the sessions, missing metrics)
4. The closing widget offers `/usability-report new` for another round

**Assertions**:
- [ ] Verdict is INCONCLUSIVE — not ACTIONABLE
- [ ] A metric absent from the data is never invented
- [ ] Offering `new` before `analyze` when no plan exists is part of the protocol

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: NOT ASSESSED — A plan only, or notes missing

**Fixture**:
- No sessions have run
- In a second run, the notes path given to `analyze` does not exist

**Input**: `/usability-report new --type usability`, then `/usability-report analyze research/missing.md`

**Expected behavior**:
1. `new` spawns `ux-researcher` for the plan (drafting it itself if the agent is blocked, and saying so), writes `> **Stage**: plan`, empty results tables and the verdict NOT ASSESSED
2. The missing notes produce a NOT ASSESSED report — no sessions analyzed
3. PD-USER-VALIDATION is not spawned; `## Director Review` reads `> [PD-USER-VALIDATION] not run — verdict NOT ASSESSED`

**Assertions**:
- [ ] Verdict is NOT ASSESSED with the reason stated
- [ ] A plan is never mistaken for a result (stage line and verdict)
- [ ] No gate runs on a report with no evidence

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Mode Variant — `beta` and `interview` types

**Fixture**:
- A private beta of Moa 0.9.0 with crash-reporter data and `design/product/tracking-plan.md` defining the activation event (first goal created and auto-debit linked within 7 days of sign-up)
- Separately, six discovery interviews

**Input**: `/usability-report analyze research/beta-1.md --type beta`, then `/usability-report analyze research/jtbd.md --type interview`

**Expected behavior**:
1. The beta report keeps `## Beta Metrics`: crash-free sessions % with the session count, activation % with n, D1/D7 retention with the day boundary stated (Asia/Seoul) and cohort size, NPS/CSAT with n and response rate
2. The interview report keeps `## Themes` (evidence strength, did or said, switching forces) and no task metrics
3. A section the type uses but the data lacks stays with `NOT ASSESSED — <reason>`

**Assertions**:
- [ ] Only the sections the type uses are kept
- [ ] Every beta metric carries its definition, n and window
- [ ] A beta without instrumentation for the question it needed is INCONCLUSIVE, not ACTIONABLE

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Edge Case — Gate disagrees with the report

**Fixture**:
- `review_mode` resolves to `full`; the report is ACTIONABLE and recommends proceeding
- The product-director replies with a first line `[PD-USER-VALIDATION]: REJECT`; in a second run the reply has no parseable first line

**Expected behavior**:
1. REJECT-class: the blockers are presented; the findings are not routed as validated until the user decides
2. The verdict conflict is surfaced with `AskUserQuestion`: `Keep <verdict>` / `Change to <verdict>` / `Run more sessions first` — the gate never changes the verdict by itself
3. An unparseable first line is treated as CONCERNS-class, and the skill says the verdict line was missing

**Assertions**:
- [ ] Neither side of a disagreement is kept silently
- [ ] A missing verdict line is never read as approval
- [ ] The outcome line is recorded in `## Director Review` after "May I write this to `production/qa/usability/usability-YYYY-MM-DD-<slug>.md`?"

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Director Gate — full mode

**Fixture**:
- The analyzed report from Case 1
- Review mode: `full` (via `--review full`, overriding the resolved `solo`)

**Expected behavior**:
1. After the report is written, `product-director` is spawned with the instruction to read `.claude/docs/director-gates/pd-user-validation.md` first (the parent does not read it) and the `Pass:` line filled with the report path, the hypotheses table, the target segment and `design/product/product-brief.md`
2. The first line `[PD-USER-VALIDATION]: APPROVE` maps to APPROVE-class; the skill records `> **Product Director Review (PD-USER-VALIDATION)**: APPROVED <YYYY-MM-DD>`
3. A CONCERNS reply would be surfaced with `Revise flagged items` / `Accept and proceed` / `Discuss further`

**Assertions**:
- [ ] In full mode: PD-USER-VALIDATION spawns, after the report exists on disk
- [ ] With no product brief the prompt says "No product brief — assess against the hypotheses alone." instead of passing silence
- [ ] A CONCERNS-class verdict is surfaced via AskUserQuestion (revise / accept / discuss)
- [ ] Skill does not auto-advance past a CONCERNS-class or REJECT-class verdict

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: Director Gate — lean mode

**Fixture**:
- Same analyzed report as Case 6
- Review mode: `lean`

**Expected behavior**:
1. PD-USER-VALIDATION does not end in `-PHASE-GATE`, so it is skipped
2. The report's `## Director Review` holds `> [PD-USER-VALIDATION] skipped — Lean mode`, written with the report

**Assertions**:
- [ ] Output contains `[PD-USER-VALIDATION] skipped — Lean mode`
- [ ] No agent is spawned for the gate; `ux-researcher` still runs for the analysis

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 8: Director Gate — solo mode

**Fixture**:
- Same analyzed report as Case 6
- Review mode: `solo` (the default statement: unset rigor ⇒ `minimal` ⇒ `solo`)

**Expected behavior**:
1. No director gate spawns
2. The report's `## Director Review` holds `> [PD-USER-VALIDATION] skipped — Solo mode`

**Assertions**:
- [ ] In solo mode: no director gates spawn
- [ ] Output contains `[PD-USER-VALIDATION] skipped — Solo mode`
- [ ] The skill never writes `modes.review_mode`; `--review` changes only this run

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses "May I write this to `<path>`?" before every write — the plan, the report and the director review update
- [ ] Presents the plan or report before requesting approval
- [ ] Ends with the closing `AskUserQuestion` offering the next skill
- [ ] Does not auto-create files without user approval
- [ ] Writes no evidence, reports or plans under `production/session-logs/` — only under `production/qa/usability/`
- [ ] Never writes `modes.review_mode` or any other knob that `modes.rigor` fronts
- [ ] Keeps recordings and personal data out of the repository

---

## Coverage Notes

- SUS scoring (`(Σ(odd item − 1) + Σ(5 − even item)) × 2.5`) and benchmark comparison
  with a cited source are not fixture-tested; the formula is asserted only as text.
- The same gate is spawned by `/prototype` and `/walking-skeleton`; their specs cover
  those spawns.
- The phase gates that read these reports (usability before Build; usability or beta
  sessions before Launch) are covered by the `/gate-check` spec.
