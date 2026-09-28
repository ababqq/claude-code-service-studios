# Hook: post-sprint-retrospective

## Trigger

Manual trigger at the end of each sprint (typically invoked by the
`delivery-manager` agent or the human developer).

## Purpose

Automatically generates a retrospective starting point by analyzing the sprint
data: what was planned vs completed, velocity changes, bug trends, and common
blockers. This is not a git hook but a workflow hook invoked through the
`delivery-manager` agent. `/retrospective sprint-[N]` runs the same analysis as a
skill, with the full facilitation flow; use it when the team holds the meeting.

## Implementation

This is a workflow hook, not a git hook. It is invoked by running:

```
@delivery-manager Generate sprint retrospective for Sprint [N]
```

The delivery-manager agent should:

1. **Read the sprint plan** from `production/sprints/sprint-[N].md` and story
   states from `production/sprint-status.yaml`
2. **Calculate metrics**:
   - Tasks planned vs completed
   - Story points planned vs completed (if used)
   - Carryover items from previous sprint
   - New tasks added mid-sprint
   - Average task completion time
3. **Analyze patterns**:
   - Most common blockers
   - Which agent/area had the most incomplete work
   - Which estimates were most inaccurate
4. **Generate the retrospective**:

```markdown
# Sprint [N] Retrospective

## Metrics
| Metric | Value |
|--------|-------|
| Tasks Planned | [N] |
| Tasks Completed | [N] |
| Completion Rate | [X%] |
| Carryover from Previous | [N] |
| New Tasks Added | [N] |
| Bugs Found | [N] |
| Bugs Fixed | [N] |

## Velocity Trend
[Sprint N-2]: [X] | [Sprint N-1]: [Y] | [Sprint N]: [Z]
Trend: [Improving / Stable / Declining]

## What Went Well
- [Automatically detected: tasks completed ahead of estimate]
- [Facilitator adds team observations]

## What Went Poorly
- [Automatically detected: tasks that were carried over or cut]
- [Automatically detected: areas with significant estimate overruns]
- [Facilitator adds team observations]

## Blockers
| Blocker | Frequency | Resolution Time | Prevention |
|---------|-----------|----------------|-----------|

## Action Items for Next Sprint
| # | Action | Owner | Priority |
|---|--------|-------|----------|

## Estimation Accuracy
| Area | Avg Planned | Avg Actual | Accuracy |
|------|------------|-----------|----------|
```

5. **Save** to `production/retrospectives/retro-sprint-[N]-YYYY-MM-DD.md` — the
   path `/retrospective` writes, so a retrospective started here counts for the
   catalog's retrospective step (never under `production/sprints/`, whose
   `sprint-*.md` glob belongs to sprint plans)
