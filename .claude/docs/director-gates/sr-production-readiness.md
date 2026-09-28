> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# SR-PRODUCTION-READINESS — Production Readiness Review

Agent: `sre-engineer` | Model tier: inherit | Domain: Production readiness & reliability

**Trigger**: Spawned by `/rollout-plan` after the plan's sections are drafted and
before the plan's verdict is set; the outcome is recorded under the plan's
`## Production Readiness Review`. `/rollout-plan` is review-mode-exempt, so this
gate runs at every review mode. It reviews SLOs, dashboards and alerts, runbooks,
on-call, capacity and load evidence, backup and restore, and a rehearsed rollback.

**Context to pass**:
- rollout-plan path
- `docs/ops/slo.md` path
- runbook paths
- latest load-test report path (or "none")
- release-checklist path

**Prompt**:
> "Review whether this release is ready to be exposed to production traffic. Read the
> rollout plan, the SLO document, the runbooks, the load-test report (if any) and the
> release checklist at the paths given. Check:
>
> 1. **SLOs and error budget** — every critical user journey the release touches has
>    an SLO; the current error-budget status allows a rollout under the error-budget
>    policy (an exhausted budget means a freeze except for reliability fixes).
> 2. **Dashboards and alerts** — each SLO has burn-rate alerts that page a human; the
>    rollout plan's guardrail metrics (error rate, p95 latency, crash-free sessions,
>    one business KPI) are visible in real time, and every halt threshold names the
>    exact signal that trips it.
> 3. **Runbooks** — every paging alert has a runbook; each runbook gives exact
>    mitigation steps a human can run (turn the kill-switch flag
>    `goals.v2-progress-ring` off, roll back the deploy, fail over) with the expected
>    result of each step.
> 4. **On-call** — a named rota covers the rollout window in the team's time zone
>    (KST for Moa, with UTC in the timeline); the window avoids the eve of public
>    holidays and late Friday evenings.
> 5. **Capacity and load evidence** — the latest load test meets its thresholds at the
>    expected peak for this release (for Moa, the automatic-debit batch and push
>    fan-out around the 25th, a common payday in Korea); headroom for the canary
>    stages.
> 6. **Backup and restore** — backups exist and a restore was tested with stated
>    recovery point and recovery time objectives; a restore point exists before any
>    Contract-phase migration in this release.
> 7. **Rehearsed rollback** — rollback for each stage was rehearsed on staging for
>    this release or its predecessor; mobile binaries cannot be rolled back, so the
>    plan relies on server-side flags, API compatibility and the force-update policy;
>    migrations are ordered expand before deploy, contract after.
> 8. **Dependencies** — third-party services on the critical path (payment provider,
>    알림톡 vendor, APNs and FCM) have a fallback or a degraded mode and known rate
>    limits.
> 9. **Release checklist** — its rollback section is complete and no blocker is open.
>
> Return READY, CONCERNS [items with an owner and a due point in the rollout], or NOT
> READY [blockers — the rollout must not start until they are resolved]."

**Verdicts**: READY / CONCERNS / NOT READY

The first line of the reply is exactly `[SR-PRODUCTION-READINESS]: <TOKEN>` with one
token from the line above; the spawning skill parses it. Findings follow the first
line.

**Special handling**:
- Review-mode-exempt: this gate is never skipped, so a production readiness verdict
  is recorded for every rollout plan.
- Load-test report "none": CONCERNS at least. Whether it is a blocker follows the
  workflow tier, because the Hardening → Launch gate requires a load test only at
  `full` (it is recommended at `standard` and dropped at `minimal`). Resolve the tier
  with `bash .claude/hooks/yaml-helper.sh resolve_config --keys workflow` (read-only)
  and read its `workflow:` line:
  - `full` — NOT READY when the release changes a path that carries peak traffic
    (sign-in, payments, the core journey); CONCERNS otherwise.
  - `standard` or `minimal` — CONCERNS, never NOT READY on this ground alone. Name each
    peak-traffic path the release changes as a finding with an owner and a due point
    in the rollout (for example, `/load-test` before the stage that exposes it to more
    than a stated share of traffic), so the user can run the test or accept the risk.
  - Tier not resolved — CONCERNS, with `NOT CHECKED — workflow tier (<reason>); at
    full, a missing load test on a peak-traffic path is a blocker`.
- You assess and propose; you never run a command that changes production, shared
  infrastructure, a shared database or secrets. Commands a human should run go into
  the findings with their expected output and rollback.
