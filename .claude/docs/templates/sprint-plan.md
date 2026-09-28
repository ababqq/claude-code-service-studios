# Sprint [N] — [Start Date] to [End Date]

> **Delivery Manager Review (DM-SPRINT)**: [pending | APPROVED [date] | CONCERNS (accepted) [date] | REVISED [date] | [DM-SPRINT] skipped — Lean mode | [DM-SPRINT] skipped — Solo mode]

## Sprint Goal

[One sentence: what does this sprint achieve toward the current milestone?
Example: "A user can create a savings goal and see its progress on web and mobile."]

## Milestone Context

- **Current Milestone**: [Name — MVP / Private Beta / Public Beta / GA, or "none defined"]
- **Milestone Deadline**: [Date]
- **Sprints Remaining**: [N]

## Capacity

- **Total days**: [X person-days]
- **Reductions**: [public holidays, time off, on-call rotation, release or store-review duty — Y days]
- **Buffer (20%)**: [Z days reserved for unplanned work: incidents, review feedback, store rejections]
- **Available**: [W days]

## Tasks

Status values are those of `production/sprint-status.yaml`:
`backlog | ready-for-dev | in-progress | review | done | blocked`.

### Must Have (Critical Path)

| ID | Story | Story File | Owner | Est. Days | Dependencies | Acceptance Criteria | Status |
|----|-------|------------|-------|-----------|--------------|---------------------|--------|
| S[N]-001 | | `production/epics/[epic-slug]/story-NNN-[slug].md` | | | None | | ready-for-dev |
| S[N]-002 | | `production/epics/[epic-slug]/story-NNN-[slug].md` | | | S[N]-001 | | ready-for-dev |

### Should Have

| ID | Story | Story File | Owner | Est. Days | Dependencies | Acceptance Criteria | Status |
|----|-------|------------|-------|-----------|--------------|---------------------|--------|
| S[N]-010 | | | | | | | backlog |

### Nice to Have (Cut First)

| ID | Story | Story File | Owner | Est. Days | Dependencies | Acceptance Criteria | Status |
|----|-------|------------|-------|-----------|--------------|---------------------|--------|
| S[N]-020 | | | | | | | backlog |

## Carryover from Sprint [N-1]

| Original ID | Story | Reason for Carryover | New Estimate | Priority Change |
|------------|-------|---------------------|-------------|----------------|

## Risks to This Sprint

| Risk | Probability | Impact | Mitigation | Owner |
|------|------------|--------|-----------|-------|

## External Dependencies

| Dependency | Status | Impact if Delayed | Contingency |
|-----------|--------|------------------|-------------|

## Definition of Done

- [ ] All Must Have stories completed (`status: done` in `production/sprint-status.yaml`)
- [ ] All stories pass their acceptance criteria
- [ ] QA plan for this sprint exists (`production/qa/qa-plan-*.md`, from `/qa-plan sprint`)
- [ ] All Logic, Integration and E2E stories have passing automated tests; UI stories have retained evidence in `production/qa/evidence/[story-slug]/`
- [ ] Smoke check passed (`/smoke-check sprint`)
- [ ] QA sign-off report: APPROVED or APPROVED WITH CONDITIONS (`/team-qa sprint`)
- [ ] No unresolved S1-Critical or S2-Major bugs in delivered features
- [ ] Feature flag default state recorded for every flag added or changed this sprint
- [ ] Tracking events verified against `design/product/tracking-plan.md`
- [ ] API contract in `docs/api/` updated for every operation added or changed
- [ ] Migration phase noted in each touched `docs/data/migrations/NNNN-[slug].md`, with dry-run evidence (`production/qa/evidence/[story-slug]/migration-dry-run.log`)
- [ ] Observability added for new endpoints, jobs and journeys (logs, metrics, traces; alerts where an SLO applies)
- [ ] Accessibility checked against `accessibility.target` for every screen touched
- [ ] No PII in new or changed log statements
- [ ] PRDs updated for any deviations
- [ ] Code reviewed and merged to trunk
