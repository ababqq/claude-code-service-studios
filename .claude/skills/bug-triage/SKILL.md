---
name: bug-triage
description: "Re-evaluate unresolved bugs — severity vs priority, sprint assignment, systemic trends."
argument-hint: "[sprint | full | trend]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash(bash "*/.claude/skills/bug-triage/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation`

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

# Bug Triage

This skill processes the unresolved bug backlog into a prioritised, sprint-assigned
action list. It distinguishes between **severity** (how bad is the impact?) and
**priority** (how urgently must we fix it?), detects systemic trends by feature,
surface and severity, and ensures no critical bug is lost between sprints.

**Output:** `production/qa/bug-triage-YYYY-MM-DD.md`

**Unresolved** — the single definition this skill, the phase gates, the `/team-qa` sign-off,
`/release-checklist`, `/milestone-review` and session-start all use: a bug whose `**Status**:` is one of
`Open`, `In Progress` or `Fixed — Pending Verification`. `Verified Fixed`, `Closed` and `Won't Fix` are
resolved. Never count by `Open` alone — a bug waiting for verification is still unresolved.

**When to run:**
- Sprint start — assign unresolved bugs to the new sprint or backlog
- After `/team-qa` completes and new bugs have been filed
- When the unresolved count crosses 10+ items
- Before `/gate-check hardening` — the gate asks that every unresolved S2 bug names an owner and a target date

---

## 1. Parse Arguments

**Modes:**
- `/bug-triage sprint` — triage against the current sprint; assign fixable bugs
  to the sprint backlog; defer the rest
- `/bug-triage full` — full triage of all unresolved bugs regardless of sprint scope
- `/bug-triage trend` — trend analysis only (no assignment); read-only report
- No argument — run sprint mode if a current sprint exists, else full mode

---

## 2. Load Bug Backlog

### Step 2a — Discover bug files

Glob for bug reports in priority order:
1. `production/qa/bugs/BUG-*.md` — individual bug report files, `BUG-NNNN.md` (the only
   format `/bug-report` and `/team-qa` write)
2. The `## Bugs Found` tables of `production/qa/qa-signoff-*.md` — cross-check only: any
   `BUG-NNNN` listed there with no bug file is reported as `NO FILE` in the report, never
   silently dropped

If no bug files found:
> "No bug files found in `production/qa/bugs/`. If bugs are tracked in a
> different location, adjust the glob pattern. If no bugs exist yet, there is
> nothing to triage — file new bugs with `/bug-report`."

Stop and report. Verdict: **NOT ASSESSED** — no bug records found in `production/qa/bugs/`. Ask whether bugs are tracked elsewhere (an issue tracker). Write no triage report: a report of zero unresolved bugs from a backlog nobody could read would pass for a clean backlog.

Keep the unresolved bugs (definition above) for classification and assignment. Resolved bugs are
read only for trend metrics (closed this sprint). **A bug whose `**Status**:` line is missing or not one
of the six status values is treated as unresolved and flagged `STATUS UNREADABLE`** — an unknown status
may not default to the permissive reading.

**In `trend` mode, do not read full bug bodies.** Trend metrics (volume, severity
mix, by feature, by surface, by date) are computable from the header fields alone:
```
Grep pattern="\*\*(Severity|Priority|Status|Feature|Surface|Category|Reported)\*\*" glob="production/qa/bugs/BUG-*.md" output_mode="content"
```
(Bug-report fields are bolded — `**Severity**:`, `- **Feature**:` — so match the
`**field**` form, not a bare line-start `Field:`.)
Full bug bodies are needed only for the priority-vs-severity **re-evaluation** in
`sprint`/`full` modes; `trend` is a read-only report and skips it. (The one
deviation check that needs a story's status — "bug filed against a Complete
story" — is a targeted story-status grep either way, not a bug-body read.)

### Step 2b — Load sprint context

Read the most recently modified file in `production/sprints/` to understand:
- Current sprint number / name
- Stories in scope (for assignment target)
- Sprint capacity constraints (if noted)

If no sprint file exists: note "No sprint plan found — assigning to backlog only."

### Step 2c — Load severity reference

Use the ladder in Step 3. It is the same text, word for word, as `/bug-report`'s
`## Severity, Priority and Status` — the skill that writes the fields this one parses.
Do not substitute another scheme; qa-lead rules on disputed severities. Production
incidents use the separate `SEV1`–`SEV4` scheme of `/incident` and are not triaged here.

---

## 3. Classify Each Bug

For each bug, extract or infer:

### Severity (impact of the bug)

`**Severity**: [S1-Critical / S2-Major / S3-Minor / S4-Trivial]`

- **S1-Critical**: outage, data loss/corruption, security or privacy breach, payment/billing failure, legal/compliance violation.
- **S2-Major**: a core journey broken for a user segment with no workaround, or severe degradation.
- **S3-Minor**: workaround exists.
- **S4-Trivial**: cosmetic.

### Priority (urgency of the fix)

`**Priority**: [P1-Fix this sprint / P2-Fix soon / P3-Backlog / P4-Won't fix]`

- **P1-Fix this sprint**: blocks QA, blocks a release, or is a regression from the last sprint.
- **P2-Fix soon**: should be resolved before the next milestone.
- **P3-Backlog**: worth fixing, no active blocking impact.
- **P4-Won't fix**: accepted risk or out of scope for the current product scope — set only with the user's approval.

### Status

**Status values** (`**Status**:` line): `Open | In Progress | Fixed — Pending Verification | Verified Fixed | Closed | Won't Fix`.

**Unresolved** = Status ∈ {`Open`, `In Progress`, `Fixed — Pending Verification`}.

Severity is impact; priority is scheduling. Never lower a severity to fit a release
date — lower the priority and record why. A bug whose Severity or Priority label does
not match the ladder strings exactly is flagged `LABEL MISMATCH` with the text found,
so the file can be corrected with `/bug-report`.

### Assignment

For each P1/P2 bug in `sprint` mode:
- Identify which story or epic the fix belongs to
- Check whether the current sprint has remaining capacity
- If capacity exists: assign to sprint (`Sprint: [current]`)
- If capacity is full: flag as `Priority overflow — consider pulling from sprint`

For `full` mode: assign all P1 to current sprint, P2 to next sprint estimate,
P3+ to backlog.

Every unresolved S1 and S2 bug gets an **owner** and a **target date** in the report —
the Build → Hardening gate checks this for S2 bugs. Where neither the bug file nor the
user names one, write `UNASSIGNED` and list the bug under Recommended Actions; never
invent an owner.

### Deviation check

Flag bugs that suggest **systematic problems**:
- 3+ bugs from the same feature in the same sprint → "Potential design or
  implementation quality issue in [feature]"
- 3+ bugs on one surface that the other surfaces do not show (e.g., android only) →
  "Surface-specific defect cluster on [surface] — check the platform layer, device matrix
  or store build"
- 2+ S1/S2 bugs in the same story → "Story may need to be reopened and
  re-reviewed before shipping"
- Bug filed against a story marked Complete (`> **Status**: Complete`, or `status: done`
  in `production/sprint-status.yaml`) → "Regression in completed story —
  story should be re-opened in sprint tracking"

---

## 4. Trend Analysis

After classifying all bugs, generate trend metrics:

### Volume trends
- Total unresolved bugs: [N]
- Opened this sprint: [N]
- Resolved this sprint (`Verified Fixed`, `Closed`, `Won't Fix`): [N]
- Net change: [+N / -N]

### Feature and surface hot spots
- Which feature has the most unresolved bugs?
- Which feature has the highest S1/S2 ratio?
- Which surface (web, ios, android, api, …) carries the most unresolved bugs?

### Severity mix
- Unresolved count per severity (S1-Critical … S4-Trivial), and the change since the last triage report

### Age analysis
- How many bugs are older than 2 sprints?
- Are any S1/S2 bugs un-assigned (sprint = none, owner = `UNASSIGNED`)?

### Regression indicator
- Any bugs filed against previously-completed stories?
- Count: [N] regression bugs (story reopened implied)

---

## 5. Generate Triage Report

```markdown
# Bug Triage Report

> **Date**: [YYYY-MM-DD]
> **Mode**: [sprint | full | trend]
> **Generated by**: /bug-triage
> **Unresolved bugs processed**: [N] (Status Open, In Progress, Fixed — Pending Verification)
> **Sprint in scope**: [sprint name, or "N/A"]

---

## Triage Summary

| Priority | Count | Notes |
|----------|-------|-------|
| P1-Fix this sprint | [N] | [N] assigned to sprint, [N] overflow |
| P2-Fix soon | [N] | Scheduled for next sprint |
| P3-Backlog | [N] | Deferred |
| P4-Won't fix | [N] | Accepted risk (user-approved) |

**Unresolved S1/S2 count**: [N]

---

## P1 Bugs — Fix This Sprint

| ID | Feature | Surface | Severity | Status | Summary | Owner | Target Date | Story |
|----|---------|---------|----------|--------|---------|-------|-------------|-------|
| BUG-NNNN | [feature] | [surface] | S1-Critical | Open | [one-line description] | [owner or UNASSIGNED] | [YYYY-MM-DD] | [story path] |

---

## P2 Bugs — Fix Soon

| ID | Feature | Surface | Severity | Status | Summary | Owner | Target Date | Target Sprint |
|----|---------|---------|----------|--------|---------|-------|-------------|---------------|
| BUG-NNNN | [feature] | [surface] | S2-Major | In Progress | [one-line description] | [owner or UNASSIGNED] | [YYYY-MM-DD] | Sprint [N+1] |

---

## P3/P4 Bugs — Backlog / Won't Fix

| ID | Feature | Surface | Severity | Summary | Disposition |
|----|---------|---------|----------|---------|-------------|
| BUG-NNNN | [feature] | [surface] | S4-Trivial | [one-line description] | Backlog |

---

## Data Issues

[Bugs flagged `STATUS UNREADABLE` or `LABEL MISMATCH`, and `NO FILE` IDs from sign-off reports — or "None."]

---

## Systemic Issues Flagged

[List any patterns from Step 3 deviation check, or "None identified."]

---

## Trend Analysis

**Volume**: [N] unresolved / [+N] net change this sprint
**Feature hot spot**: [feature with most unresolved bugs]
**Surface hot spot**: [surface with most unresolved bugs]
**Severity mix**: [N] S1-Critical · [N] S2-Major · [N] S3-Minor · [N] S4-Trivial
**Regressions**: [N] bugs against completed stories
**Aged bugs (>2 sprints old)**: [N]

[If N aged S1/S2 bugs > 0:]
> ⚠️ [N] high-severity bugs have been unresolved for more than 2 sprints without
> assignment. These represent accepted risk that should be explicitly reviewed.

---

## Recommended Actions

1. [Most urgent action — usually "fix P1 bugs before QA hand-off"]
2. [Second action — usually "investigate [hot spot feature or surface] quality"]
3. [Third action — optional improvement]
```

---

## 6. Write and Gate

Present the report in conversation, then ask:

"May I write this to `production/qa/bug-triage-YYYY-MM-DD.md`?"

Write only after approval.

If the user approved any bug as Won't Fix during the review, ask "May I write this to
`production/qa/bugs/<BUG-ID>.md`?" for each one, then set `**Priority**: P4-Won't fix` and
`**Status**: Won't Fix` in that file — nothing else in it changes.

After writing:
- If any S1 bugs are unassigned: "S1 bugs must be assigned before the sprint
  can be considered healthy. Run `/sprint-status` to see current capacity."
- If any unresolved S2 bug lacks an owner or target date: "The Build → Hardening
  gate needs an owner and a target date for every unresolved S2 bug — record them
  in the bug files or re-run `/bug-triage` once assigned."
- If regression bugs exist: "Regressions found — consider re-opening the
  affected stories in sprint tracking and running `/smoke-check` to re-gate."
- If no P1 bugs exist: "No P1 bugs — build is in good shape for QA hand-off."

Verdict: **COMPLETE** — triage report written.

If user declined write: Verdict: **BLOCKED** — user declined write.

---

## Collaborative Protocol

- **Never close or mark bugs Won't Fix without user approval** — surface them
  as P4 candidates and ask: "Are these acceptable as Won't Fix?"
- **Never auto-assign to a sprint at capacity** — flag overflow and let the
  sprint owner decide what to pull
- **Severity is objective; priority is a team decision** — present severity
  classifications as recommendations, not mandates
- **Trend data is informational** — do not block work on trend findings alone;
  surface them as observations
