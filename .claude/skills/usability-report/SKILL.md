---
name: usability-report
description: "Usability, beta or interview report: task success, time on task, SEQ/SUS, issues by severity."
argument-hint: "[new | analyze <path-to-notes>] [--type usability|beta|interview] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/usability-report/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation`

Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

# Usability Report

Plans and reports user research sessions in one of three types:

| `--type` | Sessions | What the report measures |
|----------|----------|--------------------------|
| `usability` | Task-based sessions (moderated or unmoderated) on a clickable prototype, the walking skeleton, staging or a store test build | Task success, time on task, errors, SEQ per task, optional SUS, issues by severity, quotes |
| `beta` | A private or public beta cohort using a real build | Everything above that applies, plus crash-free sessions %, activation, D1/D7 retention, NPS/CSAT |
| `interview` | Discovery or JTBD interviews | Themes with evidence strength, jobs-to-be-done, switching forces, quotes — no task metrics |

Two modes:

- **`new`** — writes a **session plan** before any session runs: hypotheses, participant
  criteria, tasks and success criteria, the moderator guide and the metrics to collect.
  Writing the hypotheses down first is what makes the later evidence strong; results
  interpreted after the fact are weaker evidence, and the director review caps them.
- **`analyze <path-to-notes>`** — turns raw notes, transcripts or exports into the
  structured report, completing the plan when one exists.

| Output | Path |
|--------|------|
| Plan or report (with the verdict line) | `production/qa/usability/usability-YYYY-MM-DD-<slug>.md` |

`<slug>` names the study in kebab-case (`goals-onboarding`, `beta-1-core-journey`).
Output goes only under `production/qa/usability/` — never to `production/session-logs/`,
which is gitignored and therefore never counts as evidence.

**Where the reports are read:** the Validation phase (usability on a prototype or the
walking skeleton, recommended before the Build gate) and the Hardening phase (the
Launch gate requires usability or beta sessions — at least three at `full`, at least one
at `standard`; a beta readout counts).

Verdict vocabulary (exact): `ACTIONABLE | INCONCLUSIVE | NOT ASSESSED`.

Director gate: **PD-USER-VALIDATION** (after an analyzed report). See
`.claude/docs/director-gates.md` for the full check pattern. The gate definition lives in
`.claude/docs/director-gates/pd-user-validation.md` — the spawned agent reads its own
gate file; do not read it in the parent session.

---

## Phase 0: Parse Arguments

- **Mode** — `new` or `analyze <path-to-notes>`. If absent, `AskUserQuestion`:
  `Plan a new study (new)` / `Analyze session notes (analyze)`.
- **Type** — `--type usability|beta|interview`. If absent, ask with the table above.
- **Review mode** — `--review full|lean|solo` overrides the resolved `review_mode` for
  this run.
- **Existing plan** (analyze mode) — Glob `production/qa/usability/*.md` for plans whose
  verdict is `NOT ASSESSED` and whose `> **Stage**:` is `plan`. If one matches the study,
  ask whether these notes complete it: the report is then written to the plan's path and
  its hypotheses count as pre-registered.

---

## Phase 1: Context

Read what the study is testing — only the sections named:

- the product brief `design/product/product-brief.md` (`## Target Users & Jobs-to-be-Done`,
  `## Value Proposition`, `## Riskiest Assumptions`) — or `design/product/one-pager.md` at
  minimal workflow;
- the PRD(s) of the features under test: `## User Value`, `## Acceptance Criteria`,
  `## Success Metrics & Instrumentation`;
- `design/product/user-journey.md` (`## Moments of Value`, `## Drop-off Risks`) and
  personas in `design/product/personas/`;
- the UX specs of the screens in the tasks (`design/ux/`);
- for `beta`: `design/product/tracking-plan.md` (activation and retention events) and the
  PRDs' metric definitions;
- earlier reports in `production/qa/usability/` — known issues are referenced, not
  re-documented as new;
- the prototype's `prototypes/<name>-concept/REPORT.md` or the newest
  `production/walking-skeleton/report-*.md`, when the sessions ran on them.

Record every input as `FOUND` or `ABSENT`. A study with no brief and no PRD can still
run — the hypotheses then come from the user and the report says so.

---

## Phase 2A: `new` — the Session Plan

Spawn **`ux-researcher`** via `Agent` with a distilled brief (the target segment, the value
proposition, the riskiest assumptions and the features under test — inline, not as paths
you have already read). Return contract: *"Do not write any file. Return only (1) the plan
sections below, filled, (2) a ≤5-bullet summary of your choices, (3) BLOCKED items, one
line each."* If it is blocked, draft the plan yourself and say so in the plan.

The plan contains:

- **Hypotheses** — each as a behaviour and a measure: "Users who reach the auto-debit
  step authorise it without help (≥ 4 of 5 participants, SEQ ≥ 5)". One is the
  **primary hypothesis** — the decision the study exists to inform.
- **Participants** — the segment and screener (for Moa: salaried people in Korea in
  their 20s–30s saving toward a goal; not colleagues or friends of the team),
  device and surface mix (iOS / Android / web share of the target users), the planned
  number of sessions and the recruiting source. Task-based sessions find problems; they
  do not measure how common a problem is — plan the count to see patterns repeat, and
  never plan to report percentages from a handful of sessions.
- **Tasks** (`usability`, `beta` exit sessions) — realistic scenarios without UI words
  ("You want to save ₩3,000,000 for a trip next August — set that up"), each with a
  success criterion and a time limit.
- **Discussion guide** (`interview`) — the switch story (first thought, passive and
  active looking, deciding, first use) and non-leading prompts.
- **Metrics** — per type (Phase 2B) with their definitions written down now.
- **Environment** — the build, surface and link (prototype URL, staging URL, TestFlight
  or Play internal testing build) and the test accounts.
- **Consent and privacy** — participant consent to record, recordings kept in the
  research tool (never in this repository), participants referred to only as P1…Pn.

Write the plan with `> **Stage**: plan`, empty results tables, and the verdict
`NOT ASSESSED` — a plan is not a result, and the stage line and verdict make sure no
reader of this directory mistakes it for sessions that ran. Continue at Phase 4 (write).

---

## Phase 2B: `analyze` — Structure the Evidence

Spawn **`ux-researcher`** via `Agent`. Pass the notes path (a document you have not read
and only this agent needs), the hypotheses (from the plan, or as the user states them
now), the type, and the metric definitions below. Return contract: *"Do not write any
file. Return only (1) the report tables below, filled from the notes, with participant
codes and verbatim quotes in the language spoken, (2) the hypotheses table with a result
per hypothesis, (3) anything in the notes you could not interpret, one line each."* If it
is blocked, read the notes and fill the tables yourself.

**Rules for the evidence:**

- Separate what participants **did** from what they **said**; behaviour outranks opinion.
- Report counts as `x of n` (`3 of 5`), never as percentages of a small sample.
- Use participant codes only — never names, phone numbers, e-mail addresses or account
  identifiers. Quotes stay in the language spoken (Korean as said), with the code.
- An observation that conflicts with a PRD's intended behaviour is flagged with the PRD
  path and section.

**Metrics:**

| Metric | Definition | Report as |
|--------|------------|-----------|
| Task success | Completed the success criterion without assistance (assisted completions reported separately) | `x of n` per task |
| Time on task | Seconds from task start to success, successful attempts only | median and range |
| Errors | Wrong paths, mis-taps, validation errors per attempt | count per task |
| SEQ | Single Ease Question after each task, 1 (very difficult) – 7 (very easy) | median and distribution |
| SUS (optional) | 10 items, 1–5; score = (Σ(odd item − 1) + Σ(5 − even item)) × 2.5, range 0–100 | per participant and mean; compare with a benchmark only when you cite its source |
| Crash-free sessions (`beta`) | Sessions without a crash ÷ all sessions, per build, from the crash reporter | % with the session count |
| Activation (`beta`) | The activation event the PRD or tracking plan defines, within its window (Moa: first goal created and auto-debit linked within 7 days of sign-up) | % of the sign-up cohort, with n |
| D1 / D7 retention (`beta`) | Share of a sign-up cohort active on day 1 / day 7 after sign-up — state the day boundary (Asia/Seoul) and whether "day 7" means exactly day 7 or within days 1–7 | % with cohort size |
| NPS (`beta`) | "How likely are you to recommend…" 0–10; % promoters (9–10) − % detractors (0–6) | score, n and response rate |
| CSAT (`beta`) | Share of 4–5 answers on a 1–5 satisfaction scale | %, n and response rate |

A metric the study planned but the notes do not contain is `NOT ASSESSED — not in the
data`; never back-fill it.

**Issues** — each with a severity (exact tokens):

| Severity | Meaning |
|----------|---------|
| `Critical` | Prevents completing the task, or causes a wrong outcome with real consequence (wrong amount, lost data, an unintended subscription), with no workaround |
| `Serious` | Major delay or frustration; completed only with difficulty or assistance |
| `Minor` | Brief confusion or slowdown; recovered unaided |
| `Cosmetic` | Noticed, with no effect on completion |

**Hypotheses** — each `Supported`, `Refuted` or `Inconclusive`, with its evidence.

**Verdict:**

- `ACTIONABLE` — sessions ran with participants from the target segment, the primary
  hypothesis is resolved (supported or refuted), and the top issues are specific enough
  to act on (each seen in at least two participants, or Critical);
- `INCONCLUSIVE` — sessions ran, but the evidence cannot support a decision:
  participants outside the segment, hypotheses written only after the sessions, too few
  sessions to see a pattern, contradictory results, or the metrics the question needed
  are missing (a beta without instrumentation);
- `NOT ASSESSED` — no sessions analyzed: a plan only, or notes missing or unreadable.

---

## Phase 3: Action Routing

Sort every issue and conflict into the bucket that owns the fix, and name the next skill:

| Bucket | Examples | Next skill |
|--------|----------|------------|
| Product change | The value is not landing; a flow the PRD intends confuses users | Revise the PRD with `/write-prd <feature>`, then `/propagate-prd-change design/prd/<feature>.md`; small tweaks via `/quick-spec` |
| UX change | Navigation, layout, affordances, states | `/ux-design <screen>`, then `/ux-review` |
| Copy and content | Misread labels, unclear errors, notification wording | `/team-content <area>` |
| Pricing and policy | Users misunderstand what they pay, limits, refunds | `/business-rules-check <feature>` |
| Defect | Reproducible bugs, crashes in beta | `/bug-report` |
| Performance | Slow screens, slow launches reported or observed | `/perf-profile <surface or route>` |

---

## Phase 4: Write

Show the plan or report, then ask: "May I write this to
`production/qa/usability/usability-YYYY-MM-DD-<slug>.md`?" — for a completed plan, the
plan's own path ("May I replace the plan at `<path>` with the full report?"). Create the
directory if absent.

```markdown
# Usability Report: [study name]

> **Verdict**: [ACTIONABLE | INCONCLUSIVE | NOT ASSESSED]

> **Stage**: [plan | report]
> **Type**: [usability | beta | interview]
> **Sessions**: [YYYY-MM-DD – YYYY-MM-DD, n sessions — or "not run yet"]
> **Surface & build**: [e.g. iOS TestFlight 1.2.0 (45) · web staging (commit) · clickable prototype]
> **Features**: [`design/prd/goals.md`, …]
> **Hypotheses pre-registered**: [yes — plan written YYYY-MM-DD | no — stated after the sessions]
> **Generated by**: /usability-report

## Hypotheses

| # | Hypothesis (behaviour + measure) | Primary | Result | Evidence |
|---|----------------------------------|---------|--------|----------|
| H1 | [..] | [yes] | [Supported / Refuted / Inconclusive / —] | [task results, quotes] |

## Participants

| Code | Segment / persona | Device & surface | Recruiting source | Notes |
|------|-------------------|------------------|-------------------|-------|
| P1 | [..] | [Galaxy A-series, Android app] | [..] | [..] |

## Tasks

| # | Scenario | Success criterion | Success | Time on task (median, range) | Errors | SEQ (median) |
|---|----------|-------------------|---------|------------------------------|--------|--------------|
| T1 | [..] | [..] | [x of n] | [..] | [..] | [..] |

## SUS

| Participant | Score |
|-------------|-------|

## Beta Metrics

| Metric | Definition | Value | n / window | Source |
|--------|------------|-------|------------|--------|

## Themes

| Theme | Evidence (participants) | Did or said | Implication |
|-------|-------------------------|-------------|-------------|

## Issues

| ID | Issue | Severity | Frequency | Task / screen | Evidence | Recommendation |
|----|-------|----------|-----------|---------------|----------|----------------|
| U-01 | [..] | [Critical / Serious / Minor / Cosmetic] | [x of n] | [..] | [P2: "…"] | [..] |

## Quotes

- P3: "[verbatim, in the language spoken]" — [task / moment]

## Recommendations

1. [Highest-impact change first, with the bucket and next skill from Action Routing]

## Director Review

[The PD-USER-VALIDATION outcome line or skip note — Phase 5]
```

Keep only the sections the type uses: `## Tasks` and `## SUS` for `usability` (and
`beta` exit sessions), `## Beta Metrics` for `beta`, `## Themes` for `interview`; a
section the type uses but the data lacks stays, with `NOT ASSESSED — <reason>`.

After writing, confirm the file exists and the verdict line sits directly under the H1.
A plan ends here — go to Phase 6.

---

## Phase 5: Director Review — PD-USER-VALIDATION

Runs after an analyzed report is written (the agent reads the report at its path).

**Review mode check** — apply before spawning (`--review` overrides the resolved
`review_mode`):
- `full` → spawn as normal.
- `lean` → **skip every gate whose ID does not end in `-PHASE-GATE`**. Note: `[GATE-ID] skipped — Lean mode`
- `solo` → skip all gates. Note: `[GATE-ID] skipped — Solo mode`

PD-USER-VALIDATION does not end in `-PHASE-GATE`, so `lean` and `solo` skip it: the
report's `## Director Review` holds `> [PD-USER-VALIDATION] skipped — Lean mode` (or
`— Solo mode`), written with the report in Phase 4. A report whose verdict is
`NOT ASSESSED` has no evidence to review: its line is
`> [PD-USER-VALIDATION] not run — verdict NOT ASSESSED`.

When it runs, spawn `product-director` via `Agent`:
- Gate: **PD-USER-VALIDATION** — the prompt instructs the agent to read
  `.claude/docs/director-gates/pd-user-validation.md` first (do not read it yourself).
- Pass: report path (usability report, prototype REPORT.md or walking-skeleton report) · hypotheses tested · target segment · brief path
- Fill: the report just written; the hypotheses table; the segment from the plan or the
  brief; `design/product/product-brief.md`, or `design/product/one-pager.md` at minimal
  workflow, or `none` — and when it is `none`, say in the prompt *"No product brief —
  assess against the hypotheses alone."* A reviewer handed silence about the product's
  value proposition will invent one.

Parse the first line of the reply as `[PD-USER-VALIDATION]: TOKEN` (APPROVE / CONCERNS /
REJECT) and map it with `.claude/docs/director-gates.md` § Standard Verdict Format:

- **APPROVE-class** → record `> **Product Director Review (PD-USER-VALIDATION)**: APPROVED <YYYY-MM-DD>`.
- **CONCERNS-class** → present the gaps and the cheapest test that would close each, then
  `AskUserQuestion`: `Revise flagged items` (update the report or run more sessions, then
  rerun the gate → `REVISED <YYYY-MM-DD>`) / `Accept and proceed` (`CONCERNS (accepted)
  <YYYY-MM-DD>`) / `Discuss further`.
- **REJECT-class** → the value is not landing. Present the blockers; do not route the
  findings as if the study were validated until the user decides how to resolve them
  (rework, more sessions, or a product decision recorded in the brief).
- A first line that does not parse is not an approval: treat it as CONCERNS-class and say
  that the verdict line was missing.

**The gate never changes the report's verdict by itself.** When it disagrees with it —
REJECT on an ACTIONABLE report that recommends proceeding, APPROVE on an INCONCLUSIVE one
— surface the conflict with `AskUserQuestion`: `Keep <verdict>` / `Change to <verdict>` /
`Run more sessions first`. The user decides; neither side is silently kept.

Record the outcome line (and any verdict change) in `## Director Review` with one update,
after asking "May I write this to `production/qa/usability/usability-YYYY-MM-DD-<slug>.md`?"

---

## Phase 6: Next Steps

Use `AskUserQuestion` with the options that apply:

- `Run the sessions, then /usability-report analyze <notes>` (after a plan)
- The next skill of the highest-severity bucket from Action Routing (Recommended after a
  report with Critical or Serious issues)
- `/usability-report new` — another round on the revised flow (INCONCLUSIVE, or after
  fixes)
- `/bug-report` — defects found in the sessions
- `/gate-check build` or `/gate-check launch` — when this report was the missing evidence
- `Stop here`

---

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and `autonomous`
modes, see `.claude/docs/automation-modes.md`.

- **Hypotheses before sessions** — offer `new` before `analyze` whenever no plan exists;
  say in the report when hypotheses were stated afterwards.
- **Evidence, not impressions** — counts with their denominators, behaviour before
  opinion, quotes verbatim with participant codes.
- **Protect participants** — no personal data in the report; recordings stay out of the
  repository.
- **Never back-fill** — a metric not in the data is `NOT ASSESSED`.
- Ask "May I write this to `<path>`?" before every write — the plan, the report, and the
  director review update.
