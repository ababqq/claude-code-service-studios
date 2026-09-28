# Runbook: [alert-slug]

> **Owner**: [team or role that maintains this runbook]
> **Last Reviewed**: [YYYY-MM-DD]
> **Last Exercised**: [YYYY-MM-DD — failure drill on staging or incident INC-YYYYMMDD-NN / never]

<!-- Written by `/incident runbook <alert-slug>` to `docs/ops/runbooks/<alert-slug>.md`,
one runbook per paging alert named in `docs/ops/slo.md` `## Dashboards & Alerts`.
The Hardening `runbooks` step and the launch gate look for these files.

Write for a tired human at 3 a.m. KST who did not build this service: exact
commands, exact console paths, what "good" looks like after each step. Agents
draft and review runbooks; every step that changes production, shared
infrastructure, a shared database or secrets is run by a human.

Keep the headings in English exactly as spelled; body text in the team's
language. Never paste secrets, tokens or personal data — reference where they
live (secret manager path, dashboard name) instead. -->

## Alert

| Field | Value |
|---|---|
| Alert name | [exactly as defined in the monitoring system and in `docs/ops/slo.md`] |
| Slug | [alert-slug] |
| SLO / journey | [e.g. "Create a savings goal — 99.9% of `POST /goals` without 5xx in ≤ 300 ms, 28 days"] |
| Condition | [e.g. error-budget burn rate ≥ 14.4× over 1 h, confirmed over 5 min] |
| Source | [monitoring tool and query or monitor ID] |
| Routing | [page / ticket — on-call rotation name] |
| Dashboard | [name and link] |
| Known false positives | [e.g. synthetic check failing during a scheduled maintenance window — or "none known"] |

## Impact

- **What users experience**: [e.g. "Goal creation fails with an error toast on all
  surfaces; existing goals and auto-debits are unaffected."]
- **Surfaces and segments**: [web / ios / android / api; plans; regions]
- **Business impact**: [e.g. "new-goal activation stops; no money moves incorrectly"]
- **Suggested severity**: [SEV1 when <condition>; SEV2 when <condition>; SEV3
  otherwise — the Incident Commander decides]
- **Declare an incident when**: [the alert stays firing after the first diagnosis
  step, or any payment or personal-data impact is suspected → `/incident open`]

## Diagnosis

Read-only steps, in order. Each step says what to look at, what "normal" looks like,
and where to go next.

1. **Confirm the symptom** — [dashboard panel]; normal: [value]. If normal, the
   alert is likely a false positive → [verify the monitor, then acknowledge].
2. **Recent changes** — last deploys in the delivery pipeline, the current
   `production/releases/<version>/release-record.md`, flag changes in the flag
   service's audit log, configuration changes. A change within [30] minutes before
   impact start → Mitigation 1 or 2.
3. **Dependencies** — status pages and error rates for [payment provider, identity
   providers (Kakao, Naver, Apple), push (APNs, FCM), 알림톡 vendor, cloud region].
   A dependency failing → Mitigation 3.
4. **Capacity and saturation** — [CPU, memory, connection-pool usage, queue depth,
   database locks and slow queries]. Saturated → Mitigation 4.
5. **Errors and traces** — [log query filtered by `trace_id` / error class, trace
   search by operation]. Queries return aggregates or redacted fields only; never
   export logs containing personal data.

| Finding | Go to |
|---|---|
| [Error spike starts with deploy `<digest>`] | Mitigation 2 |
| [Errors only on requests with the new flag enabled] | Mitigation 1 |
| [Provider timeouts] | Mitigation 3 |

## Mitigation

Each option is run by a human after the Incident Commander approves it (or by the
on-call engineer alone for the options marked "on-call may run").

### 1. [Turn the kill-switch flag `goals.v2-progress-ring` off]

- **When**: [errors correlate with the flag]
- **Command or console path**: [exact command / console steps]
- **Blast radius**: [all users lose the new progress ring; no data change]
- **Expected result**: [error rate below [0.5]% within [5] minutes]
- **Undo**: [turn the flag back on at the previous percentage]
- **Who may run it**: [on-call may run]

### 2. [Roll back to the previous release]

- **When**: [a deploy in the last [30] minutes is the likely trigger]
- **Command or console path**: [redeploy the previous image digest / promote the
  previous release in the deploy tool — as in the rollout plan's `## Rollback Plan`]
- **Blast radius**: [every change in the release is reverted; migrations of the
  Expand phase stay applied and remain compatible]
- **Expected result**: [ ]
- **Undo**: [roll forward to the release again once fixed]
- **Who may run it**: [Incident Commander approves]

### 3. [Degrade or disable a failing dependency]

- **When**: [ ]
- **Command or console path**: [ ]
- **Blast radius**: [ ]
- **Expected result**: [ ]
- **Undo**: [ ]
- **Who may run it**: [ ]

### 4. [Scale out or shed load]

- **When**: [ ]
- **Command or console path**: [ ]
- **Blast radius**: [ ]
- **Expected result**: [ ]
- **Undo**: [ ]
- **Who may run it**: [ ]

Mobile binaries cannot be rolled back: mitigations for iOS and Android act on the
server (flags, remote configuration, API compatibility); the fix itself ships
through `/hotfix`.

## Escalation

| After | Escalate to | How |
|---|---|---|
| [15] min without a working mitigation | [secondary on-call] | [paging tool / phone] |
| [30] min, or any SEV1 | [service owner, Incident Commander on duty] | [ ] |
| Dependency at fault | [vendor support — plan level, case URL, account ID location] | [ ] |
| Personal data possibly exposed | security-engineer and the privacy officer (개인정보 보호책임자) | [ ] |
| Customers noticing | Comms Lead (customer-success-manager drafts messages) | [ ] |

## Verification

- [ ] The SLI is back within the SLO threshold for [N] consecutive minutes
      ([dashboard panel]).
- [ ] Synthetic checks for the affected journey pass on every affected surface.
- [ ] Backlogs (queues, retries, scheduled jobs) are drained or draining at the
      expected rate.
- [ ] No duplicated side effects — [e.g. no double auto-debits, no duplicate push or
      알림톡 messages; idempotency-key collisions checked].
- [ ] The alert has resolved on its own; it was not silenced.
- [ ] The incident record's timeline has the mitigation and verification entries
      (`/incident update <INC-id>`).

## Related

- SLO document: `docs/ops/slo.md` ([journey])
- Dashboards: [names and links]
- Architecture: `docs/architecture/architecture.md` ([section]); ADRs: [paths]
- Rollout plan of the current release: `production/releases/<version>/rollout-plan.md`
- Previous incidents and postmortems: [`production/incidents/INC-…`,
  `production/incidents/postmortems/INC-…`]
- Vendor documentation: [links]
