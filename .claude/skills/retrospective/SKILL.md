---
name: retrospective
description: "Sprint, milestone or release retrospective with actionable insights; release mode compares outcomes with PRD success metrics."
argument-hint: "[sprint-N | <milestone-name> | release <version>]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/retrospective/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation`

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

# Retrospective

A retrospective turns what happened into what changes next. This skill runs in
three modes:

| Mode | Argument | Looks back on | Output |
|------|----------|---------------|--------|
| Sprint | `sprint-N` | one sprint: plan vs done, velocity, blockers, estimation, quality | `production/retrospectives/retro-sprint-<N>-YYYY-MM-DD.md` |
| Milestone | `<milestone-name>` | every sprint of a milestone (MVP, Private Beta, Public Beta, GA …) and its exit criteria | `production/retrospectives/retro-<milestone>-YYYY-MM-DD.md` |
| Release | `release <version>` | one shipped release: the delivery process **and** whether each shipped feature moved its PRD success metric | `production/retrospectives/retro-release-<version>-YYYY-MM-DD.md` |

Release mode closes the continuous-delivery loop after launch: every release leaves
a record set under `production/releases/<version>/`, and this retrospective compares
what shipped with what each PRD promised, deciding per feature whether to
**KEEP**, **ITERATE**, **ROLL BACK** or **REMOVE** it. `/hotfix` and `/rollout-plan`
hand off here with `/retrospective release <version>`.

Milestone and release retrospectives follow `.claude/docs/templates/project-retrospective.md`;
sprint retrospectives use the format in Phase 5.

### What this skill never does

- Never invents a number. A metric with no source is `NOT DETERMINED — <reason>`;
  a section with no inputs is `NOT ASSESSED — NO DATA`.
- Never decides KEEP / ITERATE / ROLL BACK / REMOVE on the user's behalf — it
  recommends, the product owner decides.
- Never assigns blame to a person; it names systemic causes.
- Never changes a flag, a rollout or a PRD — it hands those off to the owning skill.

---

## Phase 0: Configuration & Arguments

`modes.automation` is resolved above and governs every question and write below.

Parse the argument:

- `sprint-N` (`sprint-3` or `sprint-03`) → **sprint mode**. Locate the plan
  `production/sprints/sprint-NN.md`. `<N>` in the output name is the sprint number
  exactly as the plan's file name writes it (`sprint-03.md` →
  `retro-sprint-03-YYYY-MM-DD.md`), so retrospectives sort with their plans.
- `release <version>` → **release mode**. `<version>` is the semver directory name
  under `production/releases/` (for example `1.4.0`); mobile build numbers live
  inside the records, never in the name.
- Any other argument → **milestone mode**; the argument is the milestone name in
  kebab-case, matching `production/milestones/<milestone>.md`.
- No argument → use `AskUserQuestion`:
  - Prompt: "What should this retrospective cover?"
  - Options: `[A] The latest sprint — sprint-[NN]` · `[B] The active milestone — [name]` ·
    `[C] The latest release — [version]` · `[D] Cancel`
  Fill the options from `Glob production/sprints/sprint-*.md`, the newest
  `production/milestones/*.md` excluding `*-review.md`, and
  `Glob production/releases/*/release-record.md`; leave out an option with nothing
  behind it.

---

## Phase 1: Check for an Existing Retrospective

Before loading any data, glob for an existing retrospective of the same scope:

- Sprint: `production/retrospectives/retro-sprint-<N>-*.md`
- Milestone: `production/retrospectives/retro-<milestone>-*.md`
- Release: `production/retrospectives/retro-release-<version>-*.md`

If a matching file is found, use `AskUserQuestion`:
- Prompt: "An existing retrospective was found: [filename]. How do you want to proceed?"
- Options:
  - `[A] Update existing — load it and add/revise sections with new data`
  - `[B] Start fresh — write a new retrospective dated today; the existing file stays as history`

If [A]: read the existing file and carry its content forward, revising sections with
new data; the write in Phase 6 goes to the existing path.
If [B]: continue with a blank slate. A file with today's date already at the target
path is overwritten only after "May I overwrite `<path>`?".

---

## Phase 2: Insufficient Input — Check Before Producing Anything

**If the inputs this skill needs do not exist, the answer is "could not run" —
not a filled-in report.** Check first, and stop if the check fails.

1. List the inputs the chosen mode reads (Phase 3).
2. For each, record `FOUND` or `ABSENT` — not "assumed present".
3. If any input required for a section is ABSENT, that section is
   **`NOT ASSESSED — NO DATA`**. Do not estimate it, do not infer it from an
   adjacent artifact, and do not leave a mandated cell to be filled by whoever
   reads the template next.
4. If **every** required input is ABSENT, report **`NOT ASSESSED — NO DATA`**,
   naming what was missing and which skill produces it, and offer the choice below.

The required input per mode: **sprint** — the sprint plan, or a
`production/sprint-status.yaml` whose `sprint:` is this sprint (`/sprint-plan`
writes both); **milestone** — the milestone definition or its
`<milestone>-review.md` (`/milestone-review`), or the sprint plans inside the
milestone's dates; **release** — `production/releases/<version>/release-record.md`
(`/team-release` writes it).

When the required input is absent, use `AskUserQuestion`:
- **[A] Provide data manually** — the user pastes or describes the tasks, dates and
  outcomes (release mode: what shipped, when, and which PRDs); record the source of
  every figure as "provided in conversation, [date]".
- **[B] Stop** — Verdict: **NOT ASSESSED** — no [sprint / milestone / release] data available.

**A verdict of `NOT ASSESSED` is a success.** It is the correct, useful answer to
"what does the data say?" when there is no data. Report templates whose verdict
enum had no "could not run" state have produced **false clean passes** in practice
— an audit returning COMPLIANT on a project with nothing to audit and no standards
to audit against, and a performance profile reporting ">99% headroom" against a
budget nobody had set, with zero measurements behind it.

**Absence of evidence is never evidence of absence.** A scan that finds no
matches because there are no files to scan has not verified anything. Say which of
the two happened — a reader cannot tell from a green result.

---

## Phase 3: Load Data

### 3a. Sprint mode

- The sprint plan `production/sprints/sprint-NN.md`: goal, dates, committed stories
  (Must / Should / Nice to Have), estimates, owners, carryover, risks.
- `production/sprint-status.yaml` when its `sprint:` is this sprint — the
  authoritative completion status (`done`, `completed` dates, `blocker`). Note
  discrepancies between the yaml and the plan (stories in one but not the other).
- Story files named in the plan (`> **Status**:`, `> **Estimate**:`,
  `> **Last Updated**:`), for modified or re-estimated stories.
- Bugs opened or resolved in the sprint window: `production/qa/bugs/BUG-*.md`
  (`**Severity**:` and `**Status**:` lines; unresolved = `Open`, `In Progress`,
  `Fixed — Pending Verification`).
- The sprint's `production/qa/smoke-*.md`, `production/qa/qa-plan-*.md` and
  `production/qa/qa-signoff-*.md` — their `> **Verdict**:` lines.
- Incidents and hotfixes in the window: `production/incidents/INC-*.md`,
  `production/hotfixes/hotfix-*.md`.
- Previous retrospectives in `production/retrospectives/` — their action items and
  velocity rows.

### 3b. Milestone mode

- The definition `production/milestones/<milestone>.md` (goal, success criteria,
  feature lists, quality gates) and its review `production/milestones/<milestone>-review.md`
  (the `> **Verdict**:` line and the metrics table).
- Every sprint plan whose dates fall inside the milestone, and those sprints'
  retrospectives.
- Bugs, incidents and hotfixes inside the milestone's dates, as in 3a.
- Release records inside the milestone's dates, when the milestone shipped to users
  (Private Beta, Public Beta, GA).

### 3c. Release mode

- `production/releases/<version>/release-record.md` — required. Read the
  `> **Verdict**:` line directly under its H1 (`COMPLETED`, `HALTED` or
  `ROLLED BACK`; `NOT ASSESSED` means the release is still in progress — say so,
  and ask whether to wait for `/team-release <version>` to close it), the PRD paths
  and story paths that shipped, and the rollout stages with their timestamps. The
  first stage timestamp opens the release window; the window closes today unless
  the user names an end date.
- The rest of the record set when present: `rollout-plan.md` (guardrails and halt
  thresholds), `release-checklist.md` and `launch-checklist.md` (verdict lines),
  `release-notes.md`.
- Incidents opened in the window (`production/incidents/INC-*.md`), their
  postmortems (`production/incidents/postmortems/`), and hotfixes that reference
  the version (`production/hotfixes/hotfix-*.md`).
- For every shipped PRD: its `## Success Metrics & Instrumentation` section (metric,
  baseline, target, events) and its `## Configuration & Flags` section (flag keys
  and defaults); the events' rows in `design/product/tracking-plan.md`.
- Growth readouts covering these features: `production/growth/*/readout.md`.

### 3d. Git history (every mode)

Run git log for the window to see what was actually committed and when. Use the
Bash tool (on Windows it runs Git Bash — the redirection below is bash syntax):

```
Bash: git log --oneline --since="<window start>" --until="<window end>" 2>/dev/null
```

Without dates, fall back to `git log --oneline -20` and say the window is
approximate.

---

## Phase 4: Analyze

### 4a. Delivery (every mode)

Compare the plan against actual deliverables:

- Stories completed as planned
- Stories completed but modified from the plan
- Stories carried over (not completed), and how many times each has been carried
- Stories added mid-window (unplanned work — incidents and hotfixes count here)
- Stories removed or descoped
- Estimation accuracy: the most over- and under-estimated stories and the share
  within ±20% of estimate
- Blockers: what blocked, for how long, how it was resolved
- Quality: bugs found and fixed by severity, unresolved S1/S2 at the end of the
  window, escaped defects (found after release), incidents by SEV level, hotfixes
- Technical debt: compare `docs/tech-debt-register.md` item counts by category with
  the counts recorded in the previous retrospective. No register ⇒
  `NOT CHECKED — no docs/tech-debt-register.md; /tech-debt scan creates it`.
- Previous action items: which were done, which recur — a recurring unaddressed
  item is a process smell and is called out as such.

### 4b. Outcome vs Success Metrics (release mode — required)

For each shipped PRD, compare the outcome with its success metrics.

**Consult `analytics-engineer`** via `Agent` (a consultant — it reads and
recommends; this skill writes). Pass: the release record path, the shipped PRD
paths, `design/product/tracking-plan.md`, any readout paths from 3c, and the release
window. Ask it, per metric:

1. Are the events the metric depends on instrumented and verified on every surface
   that shipped (tracking-plan status, story evidence)?
2. Where does the observed value come from — the dashboard, saved query or readout
   to read, and the exact date range and population (rollout percentage, platform)?
3. Has enough exposure accumulated to read it? (A weekly-cycle metric needs at least
   one full week; D7 retention is readable seven days after the cohort's exposure.)
4. Confounders in the window: concurrent campaigns or experiments, holidays such as
   Chuseok, partial rollout, an incident or rollback.
5. Guardrails (error rate, latency, crash-free sessions, refunds, support tickets)
   and whether any was breached.
6. A recommended decision — KEEP, ITERATE, ROLL BACK or REMOVE — with its reasoning.

The analytics engineer must not invent observed values. Observed values come from a
readout on disk or from the user: ask the user to paste each figure with its
dashboard and date range. A metric with no value is recorded as
`NOT DETERMINED — <reason>` (for example "NOT DETERMINED — `goal_created` not
instrumented on Android" or "NOT DETERMINED — 3 days of exposure; D7 retention
readable from 2026-11-18").

**Decide per feature** with `AskUserQuestion` — one question per shipped feature
(batch up to four features in one call), recommendation first:
- Prompt: "[feature]: [metric] [observed] vs target [target]; guardrails [state]. Analytics recommends [DECISION]. What is the decision?"
- Options: `[A] KEEP` · `[B] ITERATE` · `[C] ROLL BACK` · `[D] REMOVE`

The decisions follow the meanings in the template's `## Outcome vs Success Metrics`
section. A feature decided without outcome data says so in its rationale
("ITERATE — decided without outcome data; re-read on [date]").

### 4c. Delivery metrics — DORA (optional; milestone and release modes)

Ask whether to include the DORA section. When included, compute each metric only
from records on disk, else `NOT DETERMINED — <reason>`:

- **Deployment frequency** — production deploys in the window: release records,
  hotfix records, or the CI/CD deploy history the user provides.
- **Lead time for changes** — median time from a shipped story's first commit (git
  history) to the release-record stage that reached 100% of users.
- **Change failure rate** — deploys followed by a hotfix, a `HALTED` or
  `ROLLED BACK` release record, or an incident, divided by all deploys.
- **Time to restore service** — median incident start to `MITIGATED`, from the
  `## Timeline` of each `production/incidents/INC-*.md`.

Report the values; do not grade them against DORA performance bands on a handful of
data points.

---

## Phase 5: Generate the Retrospective

**Milestone and release modes**: read `.claude/docs/templates/project-retrospective.md`
and copy its headings byte for byte. `## Outcome vs Success Metrics` is **required**
in release mode; in milestone mode include it when the milestone shipped features
to users, otherwise write "N/A — nothing shipped to users in this milestone" under
the heading. `## Delivery Metrics (DORA — optional)` is included only when the user
asked for it in 4c.

**Sprint mode** uses this format:

```markdown
# Retrospective: Sprint [N]

Period: [Start Date] -- [End Date]
Generated: [Date]
Sprint plan: `production/sprints/sprint-NN.md`

## Metrics

| Metric | Planned | Actual | Delta |
|--------|---------|--------|-------|
| Stories | [X] | [Y] | [+/- Z] |
| Completion Rate | -- | [Z%] | -- |
| Estimate Days | [X] | [Y] | [+/- Z] |
| Bugs Found | -- | [N] | -- |
| Bugs Fixed | -- | [N] | -- |
| Unresolved S1/S2 at sprint end | 0 | [N] | -- |
| Incidents / Hotfixes | -- | [N] / [N] | -- |
| Unplanned Stories Added | -- | [N] | -- |
| Commits | -- | [N] | -- |

## Velocity Trend

| Sprint | Planned | Completed | Rate |
|--------|---------|-----------|------|
| [N-2] | [X] | [Y] | [Z%] |
| [N-1] | [X] | [Y] | [Z%] |
| [N] (current) | [X] | [Y] | [Z%] |

**Trend**: [Increasing / Stable / Decreasing]
[One sentence explaining the trend]

## What Went Well
- [Observation backed by specific data or examples]
- [Recognize specific decisions that paid off]

## What Went Poorly
- [Specific issue with measurable impact — e.g., "Toss Payments sandbox access took
  4 days instead of 1, blocking the auto-debit stories"]
- [Do not assign blame — focus on systemic causes]

## Blockers Encountered

| Blocker | Duration | Resolution | Prevention |
|---------|----------|------------|------------|
| [What blocked progress] | [How long] | [How it was resolved] | [How to prevent recurrence] |

## Estimation Accuracy

| Story | Estimated | Actual | Variance | Likely Cause |
|-------|-----------|--------|----------|--------------|
| [Most overestimated story] | [X] | [Y] | [+Z] | [Why] |
| [Most underestimated story] | [X] | [Y] | [-Z] | [Why] |

**Overall estimation accuracy**: [X%] of stories within +/- 20% of estimate

[Analysis: are we consistently over- or under-estimating? For which kinds of
stories — third-party integrations, migrations, store submissions? What adjustment
should the next `/sprint-plan` apply?]

## Carryover Analysis

| Story | Original Sprint | Times Carried | Reason | Action |
|-------|----------------|---------------|--------|--------|
| [Story not completed] | [Sprint N-X] | [N] | [Why] | [Complete / Descope / Split] |

## Technical Debt Status
- Register items: [N] (previous retrospective: [N]) — or `NOT CHECKED — no docs/tech-debt-register.md`
- By category: [Security N, Infra N, Observability N, …]
- Trend: [Growing / Stable / Shrinking]

## Previous Action Items Follow-Up

| Action Item (from Sprint N-1) | Status | Notes |
|-------------------------------|--------|-------|
| [Previous action] | [Done / In Progress / Not Started] | [Context] |

## Action Items for Next Iteration

| # | Action | Owner | Priority | Deadline |
|---|--------|-------|----------|----------|
| 1 | [Specific, measurable action] | [Who] | [High/Med/Low] | [When] |

## Process Improvements
- [Specific change to how we work, with expected benefit — 2-3 items, not a wish list]

## Summary
[2-3 sentence overall assessment: was this a good sprint? What is the single most
important thing to change going forward?]
```

Present the retrospective and the top findings to the user: completion rate,
velocity trend, top blocker, the most important action item — and, in release mode,
the per-feature decisions.

---

## Phase 6: Save Retrospective

Ask, with the path for the mode:
- Sprint: "May I write this to `production/retrospectives/retro-sprint-<N>-YYYY-MM-DD.md`?"
- Milestone: "May I write this to `production/retrospectives/retro-<milestone>-YYYY-MM-DD.md`?"
- Release: "May I write this to `production/retrospectives/retro-release-<version>-YYYY-MM-DD.md`?"

If yes, write the file, creating the `production/retrospectives/` directory if
needed. Verdict: **COMPLETE** — retrospective saved.

If no, stop here. Verdict: **BLOCKED** — user declined write.

---

## Phase 7: Next Steps

Use `AskUserQuestion`, with the options for the mode:

- **Sprint**:
  - Prompt: "Retrospective complete. Would you like to start sprint planning now with the action items and velocity data pre-loaded?"
  - Options:
    - `[A] Yes — open /sprint-plan new with the retro action items and velocity delta`
    - `[B] No — I'll reference the retrospective file when I'm ready`

  If [A]: invoke `/sprint-plan new`, passing the retrospective file path and a
  summary of the action items and the velocity change.
- **Milestone**:
  - Prompt: "Milestone retrospective complete. What next?"
  - Options:
    - `[A] Run /gate-check for the next phase — this milestone closes a phase`
    - `[B] Run /milestone-review for the next milestone`
    - `[C] Nothing now`
- **Release** — one follow-up per decision:
  - ITERATE → `/write-prd <feature>` to revise the PRD, or `/quick-spec` for a small change
  - ROLL BACK → `/rollout-plan <version> --feature <flag-key>` to plan turning the flag off
  - REMOVE → `/propagate-prd-change design/prd/<feature>.md` after the PRD records the
    removal, and `/tech-debt add` for the flag, code and data cleanup
  - KEEP → `/tech-debt add` to schedule removal of the release flag
  - Any SEV1 or SEV2 incident without a postmortem → `/postmortem <INC-id>`

  - Prompt: "Release retrospective complete. Which follow-up do you want to start?"
  - Options: the follow-ups above for the decisions actually made (up to four),
    plus `[Nothing now]`.

---

## Collaborative Protocol

- **Question → Options → Decision → Draft → Approval.** The skill gathers and
  analyzes; the user decides the scope in Phase 0, the per-feature outcomes in 4b and
  the follow-ups in Phase 7.
- "May I write this to `<path>`?" before every write; nothing is written before the
  user has seen the draft.
- The analytics engineer recommends outcome decisions; the product owner makes
  them. Record both when they differ.
- Blameless: name systems, handoffs and incentives, never individuals.

### Guidelines

- Be honest and specific. Vague retrospectives ("communication could be better")
  produce vague improvements. Use data and examples.
- Limit action items to 3-5. More than that dilutes focus.
- Every action item must have an owner and a deadline.
- Check whether previous action items were completed. Recurring unaddressed items
  are a process smell.
- In milestone mode, also evaluate whether the milestone goals were achieved and
  what that means for the overall timeline.
- In release mode, an outcome that cannot be measured yet is a finding in itself:
  record when it becomes readable and put that date on an action item.
