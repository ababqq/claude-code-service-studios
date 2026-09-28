# Retrospective: [Milestone / Release / Project Name]

## Document Status
- **Date**: [Date]
- **Facilitator**: `delivery-manager`
- **Participants**: [List of agents/people involved]
- **Scope**: [Milestone <name> | Release <version> | Project]
- **Period Covered**: [Start date] to [End date]
- **Release Record**: [`production/releases/<version>/release-record.md` — final state COMPLETED | HALTED | ROLLED BACK] (release scope only)

## Summary
[2-3 sentence summary of what this milestone, release or project accomplished and
whether it delivered the value it set out to deliver]

## Goals vs Results

| Goal | Target | Result | Status |
| ---- | ------ | ------ | ------ |
| [Goal 1] | [Metric] | [Actual] | [Met / Partially / Missed] |

## Outcome vs Success Metrics

> **Required for a release retrospective** (`/retrospective release <version>`);
> optional for a milestone or project retrospective. One row per success metric of
> each PRD shipped in the release (the PRD's `## Success Metrics & Instrumentation`
> section). **Observed** is a sourced value or `NOT DETERMINED — <reason>` — never
> an estimate. **Decision** is one of `KEEP | ITERATE | ROLL BACK | REMOVE`, made by
> the product owner after the analytics review.

| Feature | PRD | Metric | Baseline | Target | Observed | Source (dashboard or file, date range) | Decision |
| ------- | --- | ------ | -------- | ------ | -------- | -------------------------------------- | -------- |
| [feature-slug] | `design/prd/[feature-slug].md` | [metric name] | [value] | [value] | [value or NOT DETERMINED — reason] | [source] | [KEEP / ITERATE / ROLL BACK / REMOVE] |

### Decision Rationale

- **[feature-slug]** — [DECISION]: [why, including guardrails (error rate, latency,
  complaints, refunds) and exposure (rollout %, days live); the follow-up and its owner]

Decision meanings:
- **KEEP** — the metric met its target or is on track, with no guardrail breach;
  finish the rollout and schedule removal of the release flag.
- **ITERATE** — value partly delivered or not yet readable; keep it live and change
  it (revised PRD or quick spec), with a date to read the metric again.
- **ROLL BACK** — a guardrail was breached or users were harmed; turn the flag off
  or revert, fix, then re-expose through a new rollout plan.
- **REMOVE** — the feature does not deliver its value and iterating is not worth
  it; plan removal of the flag, code and data, and announce the deprecation.

## Timeline

| Date | Event | Impact |
| ---- | ----- | ------ |
| [Date] | [What happened — rollout stage, incident, hotfix, scope change] | [How it affected the release or project] |

## What Went Well

### [Category 1: e.g., Technical Execution]
**What**: [Description]
**Why it worked**: [Root cause of success]
**How to repeat**: [What to keep doing]

### [Category 2: e.g., Team Coordination]
**What**: [Description]
**Why it worked**: [Root cause]
**How to repeat**: [Action]

## What Went Poorly

### [Category 1: e.g., Scope Management]
**What**: [Description]
**Root cause**: [Why this happened — systemic, never personal]
**Impact**: [Time/quality/customer cost]
**Prevention**: [How to avoid next time]

### [Category 2]
[Same structure]

## Key Metrics

| Metric | Target | Actual | Notes |
| ------ | ------ | ------ | ----- |
| Stories completed | [N] | [N] | |
| Bugs found | — | [N] | |
| Bugs fixed | — | [N] | |
| Escaped defects (found after release) | 0 | [N] | |
| Incidents (SEV1–SEV4) | — | [N] | [INC IDs] |
| Hotfixes | 0 | [N] | |
| Estimation accuracy | 100% | [N%] | |
| Scope changes | 0 | [N] | |

## Delivery Metrics (DORA — optional)

| Metric | Value | Source | Notes |
| ------ | ----- | ------ | ----- |
| Deployment frequency | [deploys per week, or NOT DETERMINED — reason] | [release records, CI/CD history] | |
| Lead time for changes | [median commit → production] | [git history + release record timestamps] | |
| Change failure rate | [deploys followed by a hotfix, rollback or incident ÷ deploys] | [release records, hotfixes, incidents] | |
| Time to restore service | [median incident start → mitigated] | [`production/incidents/` timelines] | |

## Lessons Learned

1. **[Lesson]**: [Explanation and how it changes future work]
2. **[Lesson]**: [Explanation]

## Action Items

| # | Action | Owner | Deadline | Status |
| - | ------ | ----- | -------- | ------ |
| 1 | [Action] | [Who] | [When] | [Open/Done] |

## Acknowledgments
[Call out exceptional contributions]
