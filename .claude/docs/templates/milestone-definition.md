# Milestone: [Name]

## Overview

- **Target Date**: [Date]
- **Type**: [Discovery | MVP | Private Beta | Public Beta | GA | Post-GA]
- **Duration**: [N weeks]
- **Number of Sprints**: [N]

## Milestone Goal

[2-3 sentences describing what this milestone achieves and why it matters.
What can we demonstrate or evaluate at the end of this milestone — and with whom
(internal team, invited beta users, the public)?]

## Success Criteria

[Specific, measurable criteria. The milestone is complete ONLY when all of
these are met.]

- [ ] [Criterion 1 -- specific and testable, e.g. "a user can create a savings goal and set up Toss Payments auto-debit on web, iOS and Android"]
- [ ] [Criterion 2]
- [ ] [Criterion 3]
- [ ] No unresolved S1-Critical or S2-Major bugs (unresolved = Status `Open`, `In Progress` or `Fixed — Pending Verification`)
- [ ] Quality gates below met on the environment the milestone ships to (staging for internal milestones, production for betas and GA)
- [ ] Error budget not exhausted over the last [X] consecutive days

## Feature List

### Must Ship (Milestone Fails Without These)

| Feature | PRD | Owner | Sprint Target | Status |
|---------|-----|-------|--------------|--------|

### Should Ship (Planned but Cuttable)

| Feature | PRD | Owner | Sprint Target | Cut Impact | Status |
|---------|-----|-------|--------------|-----------|--------|

### Stretch Goals (Only if Ahead of Schedule)

| Feature | PRD | Owner | Value Add |
|---------|-----|-------|----------|

## Quality Gates

Thresholds default to the `performance.*` budgets in `project.yaml` and the SLOs in
`docs/ops/slo.md`; a milestone may set a stricter value. Mark a row `N/A` when it
does not apply (for example crash-free sessions for a web-only product).

| Gate | Threshold | Measurement Method |
|------|-----------|-------------------|
| Crash-free sessions (mobile) | ≥ [X]% (`performance.crash_free_pct`) | Crash reporting (Firebase Crashlytics, Sentry) over the last [N] days |
| Error rate | ≤ [X]% of requests (`performance.error_rate_pct`) | APM / metrics (server 5xx and client error rate) |
| API p95 latency | ≤ [X] ms (`performance.api_p95_ms`) | APM traces or `/load-test` report on the critical journeys |
| Availability | ≥ [X]% over [window] (`performance.availability_pct`) | SLO dashboard or uptime monitor |
| Unresolved S1-Critical bugs | 0 | `production/qa/bugs/` |
| Unresolved S2-Major bugs | ≤ [X], each with an owner and a target date | `production/qa/bugs/` |
| Test coverage | > [X]% | Test runner coverage report |

## Risk Register

| Risk | Probability | Impact | Mitigation | Owner | Status |
|------|------------|--------|-----------|-------|--------|

## Dependencies

### Internal Dependencies

| Feature | Depends On | Owner of Dependency | Status |
|---------|-----------|-------------------|--------|

### External Dependencies

| Dependency | Provider | Status | Risk if Delayed |
|-----------|---------|--------|----------------|

## Review Schedule

| Date | Review Type | Attendees |
|------|-----------|-----------|
| [Week 2] | Early progress check | delivery-manager, directors |
| [Midpoint] | Mid-milestone review | Full team |
| [Week N-1] | Pre-milestone review (`/milestone-review`) | Full team |
| [Target Date] | Milestone review | Full team |
