# Rollout Plan: [Product] v[version]

> **Verdict**: [READY TO ROLL OUT / NOT READY / NOT ASSESSED]
> **Version**: [semver, e.g. 2.4.0] — builds: [web bundle / container digest; iOS 2.4.0 (412); Android 2.4.0 (20400412)]
> **Release Checklist**: `production/releases/<version>/release-checklist.md` — [GO / NO-GO / NOT ASSESSED / not found]
> **Rollout Window**: [YYYY-MM-DD HH:MM KST → YYYY-MM-DD HH:MM KST] ([UTC equivalents])
> **Release Owner**: [person who runs the stages]
> **Prepared**: [YYYY-MM-DD] by `/rollout-plan`

<!-- Written by `/rollout-plan [version]` to `production/releases/<version>/rollout-plan.md`.
Read by `/team-release` (it executes the stages and records each one in
`release-record.md`), by `/gate-check launch` (verdict line and the recorded
SR-PRODUCTION-READINESS line) and by the incident rollback path.

Verdicts:
- READY TO ROLL OUT — every section is complete, every stage has a named owner,
  guardrails have thresholds, rollback is defined per stage, and
  SR-PRODUCTION-READINESS returned READY (or CONCERNS the user accepted).
- NOT READY — a blocker is open: SR-PRODUCTION-READINESS NOT READY, a NO-GO release
  checklist, an unresolved S1 bug, a stage without a rollback, a Contract-phase
  migration scheduled before its readers are gone.
- NOT ASSESSED — an input the plan depends on could not be read or verified
  (no release checklist, no SLO document, a guardrail with no threshold).

Plans describe; humans act. Every deploy, flag change in production, migration and
store action named here is run by a person, stage by stage. Keep headings, field
labels and tokens in English exactly as spelled; body in the team's language. -->

## Scope

| What ships | Reference | Surfaces | Flag | Migration |
|---|---|---|---|---|
| [Goal progress ring v2] | [`design/prd/goals.md`; `production/epics/goals-core/story-001-create-goal.md`] | [web, ios, android] | [`goals.v2-progress-ring`] | [none / `docs/data/migrations/NNNN-<slug>.md`] |

**Not in this release**: [features held back, flags that stay off]

**Inputs checked**:

| Input | Path | State |
|---|---|---|
| Release checklist | `production/releases/<version>/release-checklist.md` | [GO / NO-GO / NOT ASSESSED / not found] |
| Launch gate record | `production/gate-checks/gate-launch-YYYY-MM-DD.md` | [verdict / none — note only] |
| SLO document | `docs/ops/slo.md` | [present / not found] |
| Latest load test | `production/qa/load/load-test-<profile>-YYYY-MM-DD.md` | [PASS / CONCERNS / FAIL / none] |
| Latest security audit | `production/security/security-audit-<mode>-YYYY-MM-DD.md` | [verdict; open Critical/High count] |
| Unresolved S1/S2 bugs | `production/qa/bugs/BUG-NNNN.md` | [none / list — S2s accepted with owner] |
| Runbooks | `docs/ops/runbooks/*.md` | [paging alerts covered / missing: <slugs>] |

## Strategy per Surface

### Web and API

Deploy strategy: [canary by traffic / blue-green / rolling] — flags separate deploy
from exposure; the code ships dark, the flag exposes it.

| Stage | Exposure | Dwell time | Entry criteria | Owner |
|---|---|---|---|---|
| 0 — Internal | [flag on for employees and the dogfood cohort] | [24 h] | [staging smoke PASS] | [person] |
| 1 — Canary | [5% of traffic on the new deploy; flag 5% of users] | [30 min] | [stage 0 guardrails green] | [ ] |
| 2 | [25%] | [2 h] | [ ] | [ ] |
| 3 | [50%] | [4 h, including a peak hour] | [ ] | [ ] |
| 4 — Full | [100%] | [—] | [ ] | [ ] |

### iOS and Android (only when the release ships store builds)

| Item | iOS | Android |
|---|---|---|
| Rollout mechanism | [App Store phased release — automatic 7-day schedule, pausable; or release to all] | [Google Play staged rollout — percentages the team sets, haltable] |
| Stages | [per the store's schedule] | [1% → 5% → 20% → 50% → 100%] |
| Minimum supported app version | [e.g. 2.2.0 — enforced by the server] | [ ] |
| Force-update policy | [when the app shows a blocking update prompt; the kill switch for it] | [ ] |
| Minimum OS | [`platform.min_os.ios`] | [`platform.min_os.android`] |
| Server compatibility window | [the API keeps serving app versions ≥ <min> until <date or condition>] | [ ] |

Store review timing is outside the team's control: plan stages from approval, not
from submission.

### Feature flags

| Flag key | Default in production | Kill switch? | Stage schedule | Owner | Removal |
|---|---|---|---|---|---|
| [`goals.v2-progress-ring`] | [off] | [yes] | [stages 0–4 above] | [ ] | [removal story after 100% for 2 weeks] |

## Migration Ordering

Expand before deploy, contract after — and for mobile, contract only after the
minimum supported app version no longer reads the old shape. Copied from each
migration plan's `## Deploy Ordering`.

| Step | Migration plan | Phase | When | Run by | Verification | Rollback |
|---|---|---|---|---|---|---|
| 1 | [`docs/data/migrations/NNNN-<slug>.md`] | Expand | [before stage 1] | [person] | [verification query from the plan] | [per plan `## Rollback per Phase`] |
| 2 | [ ] | Migrate | [after stage 1 is green] | [ ] | [ ] | [ ] |
| 3 | [ ] | Contract | [not in this release — scheduled for <version> / after min app version <x>] | [ ] | [ ] | [ ] |

[or "None — this release changes no schema or data"]

## Guardrail Metrics & Halt Thresholds

| Metric | Source | Baseline | Halt threshold | Window | On breach |
|---|---|---|---|---|---|
| Server error rate | [monitor] | [0.1%] | [> `performance.error_rate_pct` or 2× baseline] | [10 min] | [automatic halt / stage owner decides] |
| p95 latency (critical endpoints) | [ ] | [ ] | [> `performance.api_p95_ms`] | [ ] | [ ] |
| Crash-free sessions (mobile) | [crash reporter / store vitals] | [ ] | [< `performance.crash_free_pct`] | [ ] | [ ] |
| Core Web Vitals (web) | [RUM] | [ ] | [LCP / INP / CLS above budget] | [ ] | [ ] |
| SLO burn rate | [ ] | [ ] | [page-level burn on any journey the release touches] | [ ] | [ ] |
| Business KPI | [e.g. goals created per hour; auto-debit success rate] | [ ] | [ ] | [ ] | [ ] |

**Automatic halt conditions**: [the list that stops the rollout without a decision —
e.g. any SEV1 or SEV2 incident opened during the window; guardrail breach under
`performance.enforce: block`]

**Breach handling**: `performance.enforce` = [block → automatic halt / warn → the
stage owner decides and records the decision / off → budgets informational, noted].
A metric with no committed threshold is written `NOT ASSESSED — no threshold` and
keeps the verdict from READY TO ROLL OUT until the user sets one or explicitly
accepts rolling out without it.

## Rollback Plan

| Stage | Trigger | Rollback action | Command or console path (for a human) | Time to effect | Data considerations | Rehearsed |
|---|---|---|---|---|---|---|
| 0–4 (web/API) | [halt threshold hit] | [flag off; then redeploy the previous digest if needed] | [ ] | [< 5 min flag / < 15 min redeploy] | [Expand-phase migrations stay; they are backward-compatible] | [staging, YYYY-MM-DD, evidence path] |
| iOS / Android | [crash-free below threshold] | [pause phased release / halt staged rollout; flag off on the server] | [store console steps] | [ ] | [binaries already installed stay — fix ships through `/hotfix`] | [ ] |

Mobile binaries cannot be rolled back: the rollback path for installed apps is the
server flag or kill switch, API compatibility, and an expedited fix release.

## Communication Plan

| When | Audience | Channel | Message | Drafted by | Approved / sent by |
|---|---|---|---|---|---|
| [before stage 0] | [support team] | [internal channel, macros] | [known issues, what changed, how to escalate] | customer-success-manager | [person] |
| [stage 4] | [users] | [in-app / release notes / store "What's New"] | [`production/releases/<version>/release-notes.md`] | [ ] | [ ] |
| [on halt or rollback] | [users, API consumers] | [status page / in-app banner] | [pre-drafted holding message] | [ ] | [ ] |

Customer-facing text is written in the locale(s) the product ships in. Marketing
messages follow the consent rules of each region in `compliance.regions`.

## Go/No-Go per Stage

| Stage | Go criteria | Owner | Consulted |
|---|---|---|---|
| 0 | [staging smoke PASS; runbooks linked; on-call confirmed] | [person] | [sre-engineer, qa-lead] |
| 1 | [stage 0 guardrails green for the dwell time; no new S1/S2 bugs] | [ ] | [ ] |
| 2–4 | [ ] | [ ] | [ ] |

Decisions are made during the rollout and recorded, with UTC and KST times, in
`production/releases/<version>/release-record.md` by `/team-release`.

## Production Readiness Review

> **Site Reliability Engineer Review (SR-PRODUCTION-READINESS)**: [APPROVED YYYY-MM-DD / CONCERNS (accepted) YYYY-MM-DD / REVISED YYYY-MM-DD / NOT READY YYYY-MM-DD]

**Gate reply**: `[SR-PRODUCTION-READINESS]: [READY / CONCERNS / NOT READY]`

**Findings**: [the sre-engineer's findings, each with an owner and a due point in
the rollout — e.g. "load test at the 25th auto-debit peak — owner: performance-engineer
— before stage 2"]

**Accepted concerns**: [the concerns the user accepted, with who accepted them and
why — or "none"]
