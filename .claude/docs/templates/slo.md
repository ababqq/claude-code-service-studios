# Service Level Objectives — [Product Name]

> **Status**: Draft | Approved
> **Owner**: [role — usually sre-engineer, with technical-director approving targets]
> **Last Updated**: [YYYY-MM-DD]
> **Last Verified**: [YYYY-MM-DD — when the targets were last checked against real traffic or a load test]
> **Measurement Window**: [e.g. rolling 30 days]

<!--
TEMPLATE for docs/ops/slo.md, written by /create-architecture together with
sre-engineer. Architecture-time NFRs that later phases consume:

- ## Critical User Journeys — /walking-skeleton picks its journey here; a story
  of Type E2E closes one of these journeys; the Hardening gate expects an E2E
  test for every journey; /load-test builds its scenarios from them.
- ## SLIs & SLOs — the Validation gate expects an SLO for each journey (at
  standard, the journeys are required and the numbers recommended);
  /perf-profile, /load-test and /rollout-plan compare against them.
- ## Error Budget Policy — the Launch gate checks it is defined.
- ## Dashboards & Alerts — the Hardening gate checks dashboards and alerts per
  SLO; every alert marked as paging gets a runbook at
  docs/ops/runbooks/<alert-slug>.md, written by /incident runbook <alert-slug>.
- ## On-call — the Launch gate checks for an on-call rota here.

Keep these five headings exactly as spelled; use tables and bold labels inside
them instead of adding headings. Journey and alert names are kebab-case slugs —
other files refer to them by name, so rename one only together with its
references. Targets come from project.yaml performance.* where a key exists;
a target with no key and no measurement is written as a proposal and says so.
Write prose in the user's conversation language.
-->

## Critical User Journeys

[The few journeys whose failure users notice first and the business feels most —
usually three to seven. Each is a user-visible outcome, not a single endpoint.]

| Journey | What the user does | Surfaces | Backing operations and jobs | PRDs | Criticality |
|---------|--------------------|----------|-----------------------------|------|-------------|
| [e.g. `sign-in`] | [signs in with email, Kakao, Naver or Apple and lands on the home screen] | [web, ios, android] | [POST /v1/auth/token, GET /v1/me] | [`design/prd/auth.md`] | [High] |
| [e.g. `create-goal`] | [creates a savings goal with a target amount and date] | [web, ios, android] | [POST /v1/goals] | [`design/prd/goals.md`] | [High] |
| [e.g. `auto-debit-deposit`] | [nothing — the scheduled debit moves money into the goal and the user is notified] | [api (worker)] | [debit job, Toss Payments charge, goals.deposit.recorded event, push] | [`design/prd/payments.md`, `design/prd/notifications.md`] | [Critical — money movement] |

## SLIs & SLOs

[One or more SLIs per journey. An SLI is a ratio of good events to valid events,
with the place it is measured. Budgets come from `project.yaml` `performance.*`;
the key column names the one each target implements.]

| Journey | SLI (good ÷ valid) | Measured at | SLO | Window | Budget key |
|---------|--------------------|-------------|-----|--------|------------|
| [`sign-in`] | [token requests answered without a 5xx ÷ all valid token requests] | [load balancer / API gateway logs] | [99.9%] | [30 days] | [`performance.availability_pct`] |
| [`sign-in`] | [token requests answered within [N] ms ÷ all valid token requests] | [API server histogram] | [95% ≤ [N] ms] | [30 days] | [`performance.api_p95_ms`] |
| [`create-goal`] | [page views of the goal screens with LCP ≤ [N] ms ÷ all page views of them] | [web RUM] | [≥ 75% (the p75 target)] | [28 days] | [`performance.lcp_ms`] |
| [`create-goal`] | [app sessions without a crash ÷ all sessions] | [mobile crash reporting] | [≥ [N]%] | [7 days] | [`performance.crash_free_pct`] |
| [`auto-debit-deposit`] | [due mandates charged and recorded within [N] hours of schedule ÷ all due mandates] | [worker job metrics + ledger reconciliation] | [99.5%] | [30 days] | [— (no key; proposal)] |

**Error budget per SLO**: [the allowed failure over the window — e.g. 99.9% over
30 days allows 43.2 minutes of full unavailability, or 0.1% of requests; 99.5%
allows 3.6 hours]

**Dependencies that bound these targets**: [third parties and shared components
whose availability caps a journey — e.g. the payment gateway, the identity
provider, push delivery — with their published SLA where one exists (Source: URL,
retrieved YYYY-MM-DD) or NOT DETERMINED]

## Error Budget Policy

[What the team does as the budget is consumed. Agreed by product and engineering
before launch — a policy written during an incident is not a policy.]

| Budget state (rolling window) | Action |
|-------------------------------|--------|
| [More than [50]% remaining] | [Normal delivery; experiments and rollouts proceed] |
| [Less than [25]% remaining] | [Rollouts slow to smaller stages; reliability stories are prioritised in the next sprint] |
| [Exhausted] | [Feature rollouts stop except security fixes and fixes for the SLO itself, until the SLO is met again over the window] |
| [A single incident consumes more than [20]% of the budget] | [A postmortem is written with `/postmortem`, with at least one action item that prevents a recurrence] |

**Decision owner**: [who may grant an exception — e.g. technical-director with
the product-director, recorded in the incident or release record]

**Reference**: the example policy in the Google SRE Workbook
(https://sre.google/workbook/error-budget-policy/) — adapt it, do not copy
its numbers without agreeing them.

## Dashboards & Alerts

**Dashboards**:

| Dashboard | Shows | Tool | Link |
|-----------|-------|------|------|
| [e.g. `journeys-overview`] | [every SLI above with its remaining error budget] | [e.g. Grafana, Datadog, CloudWatch] | [URL once created] |

**Alerts** (alert on budget burn, not on raw thresholds):

| Alert | SLO | Condition | Severity | Pages | Runbook |
|-------|-----|-----------|----------|-------|---------|
| [e.g. `sign-in-fast-burn`] | [`sign-in` availability] | [burn rate ≥ 14.4 over 1 h and over 5 min (2% of a 30-day budget in an hour)] | [SEV2] | [yes] | [`docs/ops/runbooks/sign-in-fast-burn.md`] |
| [e.g. `sign-in-slow-burn`] | [`sign-in` availability] | [burn rate ≥ 6 over 6 h and over 30 min] | [SEV3] | [yes] | [`docs/ops/runbooks/sign-in-slow-burn.md`] |
| [e.g. `auto-debit-backlog`] | [`auto-debit-deposit`] | [due mandates not recorded after [N] hours] | [SEV2] | [yes] | [`docs/ops/runbooks/auto-debit-backlog.md`] |
| [e.g. `sign-in-budget-trend`] | [`sign-in` availability] | [burn rate ≥ 1 over 3 days and over 6 h] | [SEV4] | [no — ticket] | [—] |

- Every alert with **Pages** = yes names a runbook path; `/incident runbook
  <alert-slug>` writes it before launch.
- The burn-rate pairs above follow the multiwindow, multi-burn-rate approach in
  the Google SRE Workbook (https://sre.google/workbook/alerting-on-slos/);
  tune them to the window and traffic volume actually used.

## On-call

| Rotation | Primary | Secondary | Coverage | Handoff |
|----------|---------|-----------|----------|---------|
| [e.g. `api-and-worker`] | [name or role] | [name or role] | [e.g. 24×7, or business hours in Asia/Seoul (KST) plus best effort] | [e.g. Monday 10:00 KST] |

**Paging tool and channel**: [e.g. PagerDuty or incident.io → Slack `#incidents`]

**Escalation path**: [primary → secondary → tech-lead → technical-director, with
the time before each step]

**Response targets by incident severity**:

| Severity | Acknowledge within | Update cadence |
|----------|--------------------|----------------|
| SEV1 | [e.g. 5 min] | [e.g. every 30 min] |
| SEV2 | [e.g. 15 min] | [e.g. every hour] |
| SEV3 | [e.g. next business day] | [on change] |
| SEV4 | [no page] | [—] |

**Incident roles**: the incident commander, comms lead and scribe are people,
opened with `/incident open <summary>`; agents advise but never run
production-changing commands.
