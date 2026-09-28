---
name: estimate
description: "Effort estimate from complexity, dependencies, velocity and service risk drivers."
argument-hint: "[task-description | story-path]"
user-invocable: true
allowed-tools: Read, Glob, Grep
model: sonnet
---

## Phase 1: Understand the Task

Read the task description from the argument. When the argument is a story path
(`production/epics/<epic-slug>/story-NNN-<slug>.md`), read the story: its
`> **Type**:`, `> **Surface**:`, acceptance criteria, `**API Contract**`,
`**Migration**`, `**Feature Flag**` and `**Stack**` / `**Risk**` fields are the
estimate's starting point. If the description is too vague to estimate meaningfully,
ask for clarification before proceeding.

If the argument names a story path that does not exist or cannot be parsed, stop:
Verdict: **NOT ASSESSED** — `<path>` not found (create it with
`/create-stories <epic-slug>`, or re-run with a task description). Never estimate
from a file name alone.

Read CLAUDE.md for project context: stack, coding standards, architectural
patterns, and any estimation guidelines.

Read the relevant PRD from `design/prd/` if the task relates to a documented
feature — or `design/product/one-pager.md` when the feature has no PRD (a
`minimal`-tier project writes none) — and the ADRs in `docs/architecture/` that
govern it.

---

## Phase 2: Scan Affected Code

Identify files and modules that would need to change:

- Assess complexity (size, dependency count, cyclomatic complexity)
- Identify integration points with other modules and services (API operations in
  `docs/api/`, queues and webhooks, shared packages)
- Check for existing test coverage in the affected areas (unit, integration and
  contract, E2E)
- Read past sprint data from `production/sprints/` and the `## Metrics` and
  `## Estimation Accuracy` sections of `production/retrospectives/retro-sprint-*.md`
  for similar completed stories and historical velocity
- No completed sprints or retrospective metrics ⇒ write
  `Velocity: NOT DETERMINED — no completed sprints in production/sprints/` in the
  estimate and lower the confidence; never assume a velocity.

---

## Phase 3: Analyze Complexity Factors

**Code Complexity:**
- Lines of code in affected files
- Number of dependencies and coupling level
- Whether this touches Foundation or Core layer code (auth, payments, data access,
  shared packages) versus Feature or Presentation code
- Whether existing patterns can be followed or new patterns are needed

**Scope:**
- Number of layers and surfaces touched (web, iOS, Android, API, data, infra) — a
  change that ships on web and both mobile apps is three implementations and three
  test passes, not one
- New code vs modification of existing code
- Amount of new test coverage required
- Data migration or configuration changes needed

**Service risk drivers** (score each; mark `N/A` with the reason when it does not
apply):
- **Third-party / vendor integrations** — payment (Toss Payments, Stripe), identity
  (Kakao, Naver, Apple sign-in), messaging (알림톡, push, email): sandbox access,
  contract or account approval, rate limits, webhook retries and idempotency,
  certification before live keys.
- **Migrations** — schema or data changes: the expand/migrate/contract phases,
  backfill size and lock time, deploy ordering between the migration and the
  application change (`docs/data/migrations/`).
- **Store review lead time** — iOS App Store and Google Play review before users get
  a mobile change: budget days, not hours; a first submission, a new permission or a
  rejection adds review round-trips, and phased release stretches exposure further.
- **Compliance items** — personal data, consent, payment or age rules the task
  touches (the PRD's `## Non-Functional Requirements`; `.claude/docs/compliance/`):
  legal or privacy review time, consent UI and audit logging.
- **Unknown stack components (Knowledge Risk)** — a component or version marked
  `MEDIUM` or `HIGH` Knowledge Risk in `docs/stack-reference/VERSION.md`, or used by
  the team for the first time: add a spike or research budget.

**Other Risk:**
- Unclear or ambiguous requirements
- Dependencies on unfinished work
- Cross-service integration complexity
- Performance sensitivity (latency budgets, bundle size, mobile cold start)

---

## Phase 4: Generate the Estimate

```markdown
## Task Estimate: [Task Name]
Generated: [Date]

### Task Description
[Restate the task clearly in 1-2 sentences]

### Complexity Assessment

| Factor | Assessment | Notes |
|--------|-----------|-------|
| Layers / surfaces affected | [List] | [web, iOS, Android, API, data, infra] |
| Files likely modified | [Count] | [Key files listed below] |
| New code vs modification | [Ratio] | |
| Integration points | [Count] | [Which services, APIs, queues interact] |
| Test coverage needed | [Low / Medium / High] | |
| Existing patterns available | [Yes / Partial / No] | |

**Key files likely affected:**
- `[path/to/file1]` -- [what changes here]

### Service Risk Drivers

| Driver | Applies? | Effect on Estimate | Notes |
|--------|----------|--------------------|-------|
| Third-party / vendor integration | [Yes / No / N/A] | [+X days or none] | [vendor, sandbox status] |
| Migration | [Yes / No / N/A] | | [phases, backfill size] |
| Store review lead time | [Yes / No / N/A] | | [first submission? new permission?] |
| Compliance items | [Yes / No / N/A] | | [consent, PII, payments] |
| Unknown stack components (Knowledge Risk) | [Yes / No / N/A] | | [component, risk level] |

### Effort Estimate

| Scenario | Days | Assumption |
|----------|------|------------|
| Optimistic | [X] | Everything goes right, no surprises |
| Expected | [Y] | Normal pace, minor issues, one round of review |
| Pessimistic | [Z] | Significant unknowns surface, blocked on a vendor or a review for a day or more |

**Recommended budget: [Y days]**

### Confidence: [High / Medium / Low]

[Explain which factors drive the confidence level for this specific task.]

### Risk Factors

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|

### Dependencies

| Dependency | Status | Impact if Delayed |
|-----------|--------|-------------------|

### Suggested Breakdown

| # | Sub-task | Estimate | Notes |
|---|----------|----------|-------|
| 1 | [Research / spike] | [X days] | |
| 2 | [Core implementation] | [X days] | |
| 3 | [Testing and validation] | [X days] | |
| | **Total** | **[Y days]** | |

### Notes and Assumptions
- [Key assumption that affects the estimate]
- [Any caveats about scope boundaries]
```

Output the estimate with a brief summary: recommended budget, confidence level, and the single biggest risk factor.

This skill is read-only — no files are written. Verdict: **COMPLETE** — estimate generated (or **NOT ASSESSED** — see Phase 1).

---

## Phase 5: Next Steps

- If confidence is Low: recommend a time-boxed spike (`/prototype --spike`) before committing.
- If the task is > 10 days: recommend breaking it into smaller stories via `/create-stories`.
- To schedule the task: run `/sprint-plan update` to add it to the current sprint, or `/sprint-plan new` for the next one.

### Guidelines

- Always give a range (optimistic / expected / pessimistic), never a single number
- The recommended budget should be the expected estimate, not the optimistic one
- Round to half-day increments — estimating in hours implies false precision for tasks longer than a day
- Do not pad estimates silently — call out risk explicitly so the team can decide
- Waiting time is effort on the calendar even when nobody is typing: vendor
  approvals, store review and legal review belong in the estimate as named items
