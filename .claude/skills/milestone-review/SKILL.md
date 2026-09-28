---
name: milestone-review
description: "Milestone (MVP / Private Beta / Public Beta / GA) progress, quality and ops metrics, go/no-go."
argument-hint: "[milestone-name|current] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/milestone-review/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation`

Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

## Insufficient input — check this before producing any report

**If the inputs this skill needs do not exist, the answer is "could not run" —
not a filled-in report.** Check first, and stop if the check fails.

1. List the inputs this skill reads (milestone definition, sprint plans and
   `production/sprint-status.yaml`, bug files, smoke and QA reports, load-test and
   performance reports, the risk register).
2. For each, record `FOUND` or `ABSENT` — not "assumed present".
3. If any input required for a section is ABSENT, that section is
   **`NOT ASSESSED — NO DATA`**. Do not estimate it, do not infer it from an
   adjacent artifact, and do not leave a mandated cell to be filled by whoever
   reads the template next.
4. If **every** required input is ABSENT, stop and report
   **`NOT ASSESSED — NO DATA`** as the whole verdict, naming what was missing and
   which skill produces it.

**A verdict of `NOT ASSESSED` is a success.** It is the correct, useful answer to
"what does the data say?" when there is no data. The failure mode this prevents is
specific and has been observed in practice: report templates whose verdict
enum had no "could not run" state produced **false clean passes** — an audit
returning COMPLIANT on a project with nothing to audit and no standards to audit
against, and a performance profile reporting ">99% headroom" against a budget
nobody had set, with zero measurements behind it.

**Absence of evidence is never evidence of absence.** A scan that finds no
matches because there are no files to scan has not verified anything. Say which of
the two happened — a reader cannot tell from a green result.

---

## Phase 0: Parse Arguments

Extract the milestone name (`current` or a specific name) and an optional
`--review full|lean|solo`, which overrides the resolved `review_mode` for this run
only.

See `.claude/docs/director-gates.md` for the full check pattern. Individual gate definitions live in `.claude/docs/director-gates/[gate-id].md` — the spawned agent reads its own gate file; do not read it in the parent session.

---

## Phase 1: Load Milestone Data

Read the milestone definition from `production/milestones/` if it exists. The
**active milestone** — what `current` (or no argument) selects — is the newest
`production/milestones/*.md` **excluding** `*-review.md`: this skill writes its own
output as `<milestone>-review.md` in the same directory, so a newest-file match
without the exclusion picks a previous *review* instead of a definition. A named
milestone reads `production/milestones/<milestone>.md` (kebab-case, e.g.
`private-beta.md`).

> **No skill writes milestone definitions** — they are authored by hand from
> `.claude/docs/templates/milestone-definition.md`, whose types are Discovery, MVP,
> Private Beta, Public Beta, GA and Post-GA; so many projects have none. When the
> directory holds no definition, say so and review against the sprint records
> alone; do not fabricate a definition, its target date or its quality gates. The
> sections that need them (target date, feature list, quality gate thresholds) are
> `NOT ASSESSED — NO DATA`.

From the definition take: type, target date, success criteria, the Must Ship /
Should Ship / Stretch feature lists with their PRDs, and the `## Quality Gates`
thresholds.

Gather the sprint records for sprints within this milestone. First
`production/sprint-status.yaml` — the authoritative story status for the current
sprint (`backlog | ready-for-dev | in-progress | review | done | blocked`). Then the
sprint plans in `production/sprints/`: establish the denominator (glob
`production/sprints/sprint-*.md`, count **N**), then scan the sections a milestone
review actually aggregates rather than reading each plan whole:

```
Grep pattern="^## (Sprint Goal|Milestone Context|Capacity|Tasks|Carryover|Risks|External Dependencies|Definition of Done)" glob="production/sprints/sprint-*.md" output_mode="content" -A 12
```

> **These alternates are copied from the headings of
> `.claude/docs/templates/sprint-plan.md`, which `/sprint-plan` copies byte for
> byte — keep them in sync with that template, not with what a milestone review
> wishes existed.** A pattern that asks for headings the template does not emit
> (`Summary`, `Goal`, `Velocity`, `Completed`) matches only by accident: one
> heading that does match (`Carryover`) makes the match count non-zero, so the
> zero-match escape hatch below never fires, and every milestone review silently
> aggregates carryover tables and nothing else while reporting full coverage.

Full-read a single sprint plan when its scanned sections point outside
themselves, or when it matched nothing — a zero-match plan predates the
template and must be read, never silently dropped from the milestone's history.
Report any sprint that contributed nothing: a milestone summary that quietly
omits a sprint understates the work and the slippage both.

Also read, when present, the sprint retrospectives
`production/retrospectives/retro-sprint-*.md` (their `## Metrics` and
`## Velocity Trend` tables are the velocity history).

---

## Phase 2: Scan Codebase Health

Collect the quality and ops evidence the review reports. Every number carries its
source; a number without a source is not reported.

- **Unresolved bugs** — a bug file `production/qa/bugs/BUG-NNNN.md` is unresolved
  when its `**Status**:` is `Open`, `In Progress` or `Fixed — Pending Verification`;
  its severity is its `**Severity**:` value (`S1-Critical`, `S2-Major`, `S3-Minor`,
  `S4-Trivial`). Count by both lines, never by `Open` alone:
  ```
  Grep pattern="\*\*(Severity|Status)\*\*:" glob="production/qa/bugs/BUG-*.md" output_mode="content"
  ```
  No bug directory ⇒ "no bug files — bug counts NOT ASSESSED", not "0 bugs".
  The unresolved S1/S2 count is passed to DM-MILESTONE in Phase 3b.
- **Test status** — the latest `production/qa/smoke-*.md` and
  `production/qa/qa-signoff-*.md`: read the `> **Verdict**:` line directly under
  each H1.
- **Quality & ops metrics** — for each of crash-free sessions %, error rate, API p95
  latency and availability:
  - *threshold*: the milestone definition's `## Quality Gates` row; else the
    matching `project.yaml` key read with Read (`performance.crash_free_pct`,
    `performance.error_rate_pct`, `performance.api_p95_ms`,
    `performance.availability_pct`); else `docs/ops/slo.md` `## SLIs & SLOs`;
    else "no threshold set".
  - *measured*: the latest `production/qa/load/load-test-*.md`,
    `production/qa/perf/perf-profile-*.md` or `production/releases/*/release-record.md`
    that reports it, or a value the user reads off their dashboard (Sentry, Firebase
    Crashlytics, Datadog, Grafana, CloudWatch) — record the source and the date.
  - Neither ⇒ `NOT ASSESSED — NO DATA` for that row. A row the definition marks
    N/A (for example crash-free sessions for a web-only product) is `N/A`.
- **Debt markers** — Grep `TODO|FIXME|HACK` across the repository's source files
  (the Grep tool skips gitignored build and dependency directories; leave out
  `.claude/`, `design/`, `docs/` and `production/`), and read
  `docs/tech-debt-register.md` when it exists for the critical debt items.
- **Risk register** — `production/risk-register/` if it exists (entries from
  `.claude/docs/templates/risk-register-entry.md`, authored by hand or offered by
  `/sprint-plan`); absence is normal — note it rather than skipping risk assessment
  silently.

---

## Phase 3: Generate the Milestone Review

The verdict line directly under the H1 carries the recommendation token
(`GO`, `CONDITIONAL GO`, `NO-GO` or `NOT ASSESSED`). Until Phase 3b has run — or
been skipped by the review mode — the recommendation is not final: a draft written
for the gate carries `> **Verdict**: NOT ASSESSED` and "pending DM-MILESTONE" in
the Go/No-Go section, so an abandoned draft never reads as a decision.

```markdown
# Milestone Review: [Milestone Name]

> **Verdict**: [GO | CONDITIONAL GO | NO-GO | NOT ASSESSED]
> **Delivery Manager Review (DM-MILESTONE)**: [pending | APPROVED [date] | CONCERNS (accepted) [date] | REVISED [date] | [DM-MILESTONE] skipped — Lean mode | [DM-MILESTONE] skipped — Solo mode]

## Overview
- **Milestone Type**: [MVP | Private Beta | Public Beta | GA | …, from the definition]
- **Definition**: [`production/milestones/<milestone>.md` or "none — reviewed against sprint records"]
- **Target Date**: [Date]
- **Current Date**: [Today]
- **Days Remaining**: [N]
- **Sprints Completed**: [X/Y]

## Feature Completeness

### Fully Complete
| Feature | PRD | Acceptance Criteria | Test Status |
|---------|-----|-------------------|-------------|

### Partially Complete
| Feature | PRD | % Done (stories done / total) | Remaining Work | Risk to Milestone |
|---------|-----|-------------------------------|---------------|------------------|

### Not Started
| Feature | Priority | Can Cut? | Impact of Cutting |
|---------|----------|----------|------------------|

## Quality Metrics
| Metric | Threshold | Measured | Source (file or dashboard, date) | Status |
|--------|-----------|----------|----------------------------------|--------|
| Unresolved S1-Critical bugs | 0 | [N] — [BUG IDs] | `production/qa/bugs/` | [MET / NOT MET / NOT ASSESSED] |
| Unresolved S2-Major bugs | [from definition] | [N] | `production/qa/bugs/` | |
| Unresolved S3-Minor bugs | — | [N] | `production/qa/bugs/` | |
| Crash-free sessions | [≥ X%] | [Y%] | | |
| Error rate | [≤ X%] | [Y%] | | |
| API p95 latency | [≤ X ms] | [Y ms] | | |
| Availability | [≥ X%] | [Y%] | | |
| Smoke check | PASS | [latest verdict] | [`production/qa/smoke-*.md`] | |
| QA sign-off | APPROVED | [latest verdict or "none"] | [`production/qa/qa-signoff-*.md`] | |

## Code Health
- **TODO count**: [N across the source tree]
- **FIXME count**: [N]
- **HACK count**: [N]
- **Technical debt items**: [critical items from `docs/tech-debt-register.md`, or "no register"]

## Risk Assessment
| Risk | Status | Impact if Realized | Mitigation Status |
|------|--------|-------------------|------------------|

## Velocity Analysis
- **Planned vs Completed** (across all sprints): [X/Y stories = Z%]
- **Trend**: [Improving / Stable / Declining]
- **Adjusted estimate for remaining work**: [Days needed at current velocity]

## Scope Recommendations
### Protect (Must ship with milestone)
- [Feature and why]

### At Risk (May need to cut or simplify)
- [Feature and risk]

### Cut Candidates (Can defer without compromising milestone)
- [Feature and impact of cutting]

## Go/No-Go Assessment

**Recommendation**: [NOT ASSESSED / GO / CONDITIONAL GO / NO-GO]

**Conditions** (if conditional):
- [Condition 1 that must be met]
- [Condition 2 that must be met]

**Rationale**: [Explanation of the recommendation]

## Action Items
| # | Action | Owner | Deadline |
|---|--------|-------|----------|
```

Derive the provisional recommendation from the evidence before the gate runs:
**NOT ASSESSED** when the Insufficient-input check left the feature or quality
sections without data; **NO-GO** when a Must Ship feature cannot finish by the
target date at current velocity, or an unresolved S1 exists for a Public Beta or GA
milestone, or a quality gate is NOT MET without a credible fix before the date;
**CONDITIONAL GO** when every gap has a specific, dated condition that closes it;
**GO** otherwise.

---

## Phase 3b: Delivery Risk Assessment

**Review mode check** — apply before spawning DM-MILESTONE (`--review` overrides
the resolved `review_mode`):
- `solo` → skip all gates. Note: `[DM-MILESTONE] skipped — Solo mode`
- `lean` → **skip every gate whose ID does not end in `-PHASE-GATE`**. Note: `[GATE-ID] skipped — Lean mode`
  DM-MILESTONE does not end in `-PHASE-GATE`, so lean skips it: `[DM-MILESTONE] skipped — Lean mode`.
- `full` → spawn as normal.

When skipped, the note goes in the review's `> **Delivery Manager Review (DM-MILESTONE)**:`
header line, the Go/No-Go section is presented without a delivery-manager verdict,
the provisional recommendation of Phase 3 becomes the final one, and the summary
says: "DM-MILESTONE not consulted — <Mode> mode; `--review full` runs it."

**At `full`**, the gate reads the draft from disk, so it is written first: ask "May
I write the draft review to `production/milestones/<milestone>-review.md` for the
DM-MILESTONE review?" The draft carries `> **Verdict**: NOT ASSESSED` and "pending
DM-MILESTONE" as its recommendation. If the user declines, stop without writing.
Verdict: **BLOCKED** — the DM-MILESTONE review needs the draft on disk; re-run when
ready, or with `--review lean` to review without the per-skill gate.

Spawn `delivery-manager` via `Agent`:
- Gate: **DM-MILESTONE** — `.claude/docs/director-gates/dm-milestone.md`. The
  `Agent` prompt instructs the agent to read that file **first**; never read it or
  paste its prompt in this session.
- Pass: milestone review draft path · milestone definition path · `production/sprint-status.yaml` path · unresolved S1/S2 count
- Fill them: `production/milestones/<milestone>-review.md`; the definition path (or
  `none`); `production/sprint-status.yaml` (or `none` when absent); the Phase 2
  counts as "S1: N, S2: M" (or `NOT ASSESSED — no bug files`).
- Parse the first line of the reply as `[DM-MILESTONE]: TOKEN` and map the token
  with the verdict-class table of `.claude/docs/director-gates.md` (Standard Verdict
  Format). Present the assessment inline within the Go/No-Go section. The verdict
  (ON TRACK / AT RISK / OFF TRACK) informs the overall recommendation.

Handle all three classes:

- **ON TRACK** (APPROVE-class) → keep the provisional recommendation (GO, or
  CONDITIONAL GO when Phase 3 found conditions) and proceed to Phase 4.
- **AT RISK** (CONCERNS-class) → use `AskUserQuestion`:
  - Prompt: "Delivery manager verdict: AT RISK. The milestone may slip. How should the Go/No-Go section be framed?"
  - Options:
    - `[A] CONDITIONAL GO — include the delivery manager's conditions in the review`
    - `[B] NO-GO — conditions cannot be met in time`
    - `[C] GO — I accept the risk and want to proceed`
    - `[D] Discuss further before deciding`
- **OFF TRACK** (REJECT-class) → use `AskUserQuestion` before finalizing the
  recommendation:
  - Prompt: "Delivery manager verdict: OFF TRACK. The milestone is in jeopardy. This review will recommend NO-GO. How do you want to proceed?"
  - Options:
    - `[A] Accept NO-GO — write the full review with that recommendation`
    - `[B] Override to CONDITIONAL GO — I'll document the accepted risks myself`
    - `[C] Stop — I want to address blockers before finalizing the review`

  Do not issue a GO against an OFF TRACK verdict unless the user explicitly selects [B] above. If [C]: stop; the draft keeps `> **Verdict**: NOT ASSESSED`. Verdict: **BLOCKED** — DM-MILESTONE OFF TRACK unresolved.
- A first line that does not parse (missing, malformed, or a token not on the
  gate's Verdicts line) is not an approval: show the full reply, say the verdict
  line was missing, and handle it as CONCERNS-class.

Record the outcome in the review's header line, replacing `pending`:
`> **Delivery Manager Review (DM-MILESTONE)**: APPROVED [date] / CONCERNS (accepted) [date] / REVISED [date]`.

---

## Phase 4: Save Review

Present the review to the user, with the final recommendation on the verdict line.

Ask: "May I write this to `production/milestones/<milestone>-review.md`?" (at `full`
this updates the draft in place).

If yes, write the file, creating the directory if needed. Verdict: **COMPLETE** — milestone review saved.

If no, stop here. Verdict: **BLOCKED** — user declined write.

---

## Phase 5: Next Steps

- Run `/gate-check <target-phase>` for a formal phase gate verdict if this milestone
  coincides with a phase boundary (for example, GA readiness is checked by
  `/gate-check launch`).
- Run `/sprint-plan update` to adjust the current sprint, or `/sprint-plan new` for
  the next one, based on the scope recommendations above.
- Run `/bug-triage` when unresolved S2 bugs lack an owner or a target date.
- Run `/retrospective <milestone-name>` once the milestone closes.
