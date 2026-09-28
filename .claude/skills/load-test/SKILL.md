---
name: load-test
description: "Load test protocol and run (smoke, load, stress, spike, soak) against staging with SLO thresholds."
argument-hint: "[profile: smoke|load|stress|spike|soak] [--target <env-name>]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/load-test/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,automation_always_ask,performance.enforce,stack`

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

# Load Test

Designs, writes and (when allowed) runs a load test against **staging** — never
production — and reports the result against the product's SLO thresholds. Five
profiles, one per question:

| Profile | Question it answers | Shape | Typical length |
|---------|---------------------|-------|----------------|
| `smoke` | Do the script, test data and environment work at all? | 1–2 virtual users, a few iterations | 1–2 min |
| `load` | Does the service meet its SLOs at expected peak traffic? | Ramp to the expected peak arrival rate, hold, ramp down | 15–30 min hold |
| `stress` | Where is the breaking point, and how does it break? | Step the arrival rate past the peak (e.g. 100 % → 150 % → 200 % → 300 %) | Until the knee or a safety abort |
| `spike` | Does it survive a sudden surge and recover? | Jump from baseline to several times peak within seconds, hold briefly, drop | 5–10 min |
| `soak` | Does anything degrade over hours? | The expected load held constant | Hours (agreed with the user) |

The lengths are working conventions, not sourced limits — agree the numbers for this
product in Phase 3. Typical surges for a Korean consumer product are a push campaign,
a payday morning, a 선착순 promotion or a holiday; for Moa, the 09:00 KST auto-debit
batch on payday plus the app opens that follow the deposit notifications.

| Output | Path |
|--------|------|
| Load script (one per profile) | `tests/load/<profile>.<ext>` |
| Report (with the verdict line) | `production/qa/load/load-test-<profile>-YYYY-MM-DD.md` |
| Raw tool output (gitignored, never evidence) | `production/qa/load/raw/` |

Verdict vocabulary (exact): `PASS | FAIL | NOT ASSESSED` — precedence
**FAIL > NOT ASSESSED > PASS**.

---

## Phase 0: Parse Arguments

- **Profile** — `smoke | load | stress | spike | soak`. If absent, use
  `AskUserQuestion` with the table above; recommend `smoke` when no script exists yet
  in `tests/load/` (a load run with an untested script measures the script).
- **Target** — `--target <env-name>`. If absent, ask which environment to use;
  `staging` is the recommended option. Also ask for (or read from
  `docs/architecture/architecture.md` § deployment topology) the target's base URL.
- **A run finished outside the session** — if the newest
  `production/qa/load/load-test-<profile>-*.md` is a protocol (verdict `NOT ASSESSED`,
  `> **Run status**: not run — …`) and raw output for that run now exists under
  `production/qa/load/raw/`, offer `Analyze that run` (Phase 1 still applies to its
  recorded target, then go straight to Phase 7) / `Plan a new run`.

---

## Phase 1: Target Safety Check — production is refused

Identify the target environment by its name and its host before anything else.

**Refuse production outright.** If the environment name denotes production
(`production`, `prod`, `prd`, `live`), or the host is the product's public web or API
host as recorded in the architecture document, the SLO document or release records,
stop with this refusal — it is not a question, no automation mode and no flag
changes it:

> REFUSED — `/load-test` never targets production (`<name>` / `<host>`). Load against
> production degrades real users' experience, can trigger real payments, messages
> and fraud controls, and pollutes the metrics your SLOs are computed from. Run it
> against staging or a dedicated performance environment. For production capacity
> evidence, give `/perf-profile` an export from your monitoring tool.

If you cannot tell whether a host serves real users, treat it as production and refuse
until the user names a non-production environment. Accepted targets: `local`, `dev`,
`preview` / pull-request environments (smoke only — they are rarely sized for load),
`staging`, and dedicated performance environments.

---

## Phase 2: Load Context and Thresholds

Read with Read (none of these has a `resolve_config` label; `project.local.yaml` is not
consulted for them):

- `project.yaml` → `performance.api_p95_ms`, `performance.error_rate_pct` (spell each
  key in full — the dead-settings audit matches full dotted keys) and
  `commands.load_test`;
- `docs/ops/slo.md` → `## Critical User Journeys` (which flows to load) and
  `## SLIs & SLOs` (per-journey targets, if any);
- `docs/api/openapi.yaml` (or the project's contract under `docs/api/`) → operations,
  authentication scheme, idempotency and pagination rules;
- `docs/architecture/architecture.md` → topology, autoscaling limits, third-party
  integrations in the request path;
- the newest `production/qa/load/load-test-*.md` → the baseline to compare against;
- the newest `production/qa/perf/perf-profile-*.md` → known hotspots.

**Thresholds** come from the two budget keys:

| Threshold | Source | k6 | Locust | Gatling |
|-----------|--------|----|--------|---------|
| Latency p95 | `performance.api_p95_ms` | `http_req_duration: ['p(95)<X']` | quitting-event check of `get_response_time_percentile(0.95)` | `global().responseTime().percentile(95.0).lt(X)` |
| Error rate | `performance.error_rate_pct` | `http_req_failed: ['rate<R']`, R = X ÷ 100 (1 % → `0.01`) | quitting-event check of `fail_ratio` (a ratio, like R) | `global().failedRequests().percent().lt(X)` |

A per-journey target from `docs/ops/slo.md` becomes a per-operation threshold (k6 tag
filters such as `http_req_duration{name:create-deposit}`). When a per-journey target
contradicts the `project.yaml` budget, show both and ask which governs this run.

**Unset threshold ⇒ ask** (`AskUserQuestion`: "Set a value for this run" / "Leave it
unset"). A value given for the run is recorded in `## Budgets` as
`user-provided for this run — not in project.yaml`, and the summary suggests persisting
it (`/settings performance.api_p95_ms=<n>`). A threshold left unset makes its rows
`NOT ASSESSED — threshold unset`, and the verdict cannot be PASS. Never invent a
threshold and never use a vendor default.

**`performance.enforce`** (from the resolved block — it is locally overridable) decides
whether a breach blocks:

| Value | Effect |
|-------|--------|
| `warn` | A breached threshold makes this report **FAIL**; the report states that the FAIL is advisory, and `/gate-check` treats it as CONCERNS. |
| `block` | A breached threshold makes this report **FAIL**, and the report states that the FAIL is blocking. |
| `off` | Thresholds are informational: breaches are recorded, not scored, and the report says `Thresholds not scored — performance.enforce: off`. Stability failures (crashes, restarts, data errors) are still FAIL — they are not budget breaches. |

**Tool choice** — from the resolved `stack` line, first match wins:

1. A load tool already used in the repo (`commands.load_test`, existing files in
   `tests/load/`) — reuse it and say so.
2. JavaScript / TypeScript stacks → **k6** (`tests/load/<profile>.js`; `.ts` when the
   installed k6 runs TypeScript natively — check `k6 version`).
3. Python stacks → **Locust** (`tests/load/<profile>.py`).
4. JVM stacks (Spring, Kotlin, Java) → **Gatling** (`tests/load/<profile>.kt` with the
   Kotlin DSL, or `.java` with the Java DSL, where the class name must match the file
   name), placed in the Gatling plugin's simulation source set.

When the backend layer is under `unset=` (or the stack line says
`stack: unset — run /setup-stack`), print
`NOT CHECKED — backend layer not configured (run /setup-stack)` and ask which tool to
use — do not default silently.

---

## Phase 3: Workload Model (performance-engineer ∥ sre-engineer)

Spawn both agents via `Agent` **in parallel** (issue both calls before waiting). Brief
each one inline with the distilled context — profile, target, thresholds, the critical
journeys, the operations in scope, the resolved `stack` line, the architecture's
topology and third-party list — never a path to a document you have already read. End
each prompt with the return contract: *"Do not write any file — this skill writes the
script and the report. Return only (1) the content asked for below, (2) a ≤5-bullet
summary of your decisions, (3) any BLOCKED items, one line each."*

**`performance-engineer`** returns:

- **Arrival model** — prefer an open model (k6 `ramping-arrival-rate` /
  `constant-arrival-rate`, Locust `constant_throughput`, Gatling `injectOpen`) for API
  SLOs: a closed, fixed-user model slows its own request rate when the system slows
  down (coordinated omission) and under-reports latency. Use virtual-user models only
  for session-shaped flows, with realistic think time.
- **Target rates** — expected peak requests per second per journey, derived from a
  stated source (analytics peak-hour share of daily active users, the architecture's
  capacity estimate, a previous report). An unsourced peak is asked, never invented.
- **Request mix** — per critical journey, e.g. for Moa: 55 % list goals, 20 % goal
  detail, 10 % create deposit, 10 % token refresh, 5 % notification settings.
- **Test data** — synthetic accounts seeded on staging (the factories in
  `tests/helpers/` when present), unique idempotency keys per write, pre-generated
  auth tokens (so the run does not hammer sign-in or SMS/identity verification unless
  that journey is the target), and a cleanup plan.
- **The script** — complete, for the chosen tool, with thresholds wired to the Phase 2
  values and a safety abort on the error rate (k6:
  `{ threshold: 'rate<0.01', abortOnFail: true, delayAbortEval: '1m' }`).
- **Soak only** — the checkpoint schedule (Phase 6).

**`sre-engineer`** returns:

- **Environment readiness** — staging runs the release-candidate build; its size
  relative to production (a smaller staging caps what `load` can prove — state the
  ratio); autoscaling limits; database and cache sizing.
- **Observability during the run** — the dashboards to watch (latency, error rate,
  saturation: CPU, memory, connection pools, queue lag), and the alerts that will fire
  on staging (announce the run to on-call and the team channel rather than muting
  production alerting).
- **Safety** — abort conditions beyond the tool's thresholds (database CPU, queue lag,
  disk), and who can stop the run.
- **Third-party traffic** — every dependency in the request path (payment, KakaoTalk
  알림톡 or SMS, push, e-mail, identity verification, OAuth). Traffic that would reach a
  third party is an `external_calls` decision: stub it at the adapter boundary, or get
  explicit approval to use the vendor's sandbox — most sandboxes forbid load and rate
  limit hard.
- **Scaling proposals** — any change to staging needed for a meaningful run (replica
  counts, database size, autoscaling ceilings). This is an `infra_changes` decision:
  `is_always_ask_category infra_changes` decides whether it prompts, and with the
  default list it always does. This skill never scales anything itself; it records the
  proposal, and a human (or the team's normal infrastructure workflow) applies it.

If an agent returns BLOCKED or errors, surface it immediately and continue with what
the other returned; the affected section of the report says
`<agent> not consulted — <reason>`.

Present the model, thresholds and safety plan, then `AskUserQuestion`:
`Approve the workload model` / `Adjust (say what)` / `Stop here`.

---

## Phase 4: Write the Script

Ask: "May I write this to `tests/load/<profile>.<ext>`?" and write it on approval.
Scripts never contain secrets: read the base URL and credentials from environment
variables (`BASE_URL`, `LOADTEST_TOKEN_FILE`, …) and name them in the report.

A minimal k6 shape, for reference (values come from Phase 2 and 3, never from here):

```js
import http from 'k6/http';
import { check } from 'k6';

export const options = {
  scenarios: {
    load: {
      executor: 'ramping-arrival-rate',
      startRate: 10, timeUnit: '1s',
      preAllocatedVUs: 50, maxVUs: 500,
      stages: [
        { target: 120, duration: '5m' },   // ramp to the expected peak (req/s)
        { target: 120, duration: '20m' },  // hold
        { target: 0, duration: '2m' },
      ],
    },
  },
  thresholds: {
    http_req_duration: ['p(95)<300'],      // performance.api_p95_ms
    http_req_failed: [{ threshold: 'rate<0.01', abortOnFail: true, delayAbortEval: '1m' }], // performance.error_rate_pct
  },
};

export default function () {
  const res = http.get(`${__ENV.BASE_URL}/v1/goals`, {
    headers: { Authorization: `Bearer ${__ENV.LOADTEST_TOKEN}` },
    tags: { name: 'list-goals' },
  });
  check(res, { 'status is 200': (r) => r.status === 200 });
}
```

---

## Phase 5: Run Decision

The test **runs only when both hold**:

1. `commands.load_test` is set in `project.yaml` (read in Phase 2). When it names a
   script under `tests/load/`, substitute this profile's script and show the final
   command.
2. The user confirms the run with `AskUserQuestion`, after seeing: the exact command,
   the target and host, the duration, the arrival rates, the abort conditions and the
   third-party handling. The options are `Run now` / `A human runs it (print the
   command)` / `Do not run — write the protocol only`. A run loads a shared environment,
   so this confirmation is asked in every automation mode.

Otherwise — `commands.load_test` unset, the user declines, or a Phase 3 prerequisite is
unmet (staging not on the release candidate, third parties not stubbed) — skip to
Phase 7 and write the **protocol**: the full report with the workload model, budgets
and safety plan, an empty `## Measurements` table, the verdict `NOT ASSESSED` and
`> **Run status**: not run — <reason>`. A protocol is not a result.

---

## Phase 6: Run and Observe

- **Short runs** (smoke, spike, a short load hold — anything that fits the session's
  command timeout) may run here with Bash. Write raw output only under
  `production/qa/load/raw/`, e.g.
  `k6 run --out json=production/qa/load/raw/<profile>-YYYY-MM-DD.json tests/load/<profile>.js`
  (plus a summary JSON from `handleSummary()` into the same directory); Locust
  `--csv production/qa/load/raw/<profile>-YYYY-MM-DD --html …`; Gatling's results
  directory pointed at the same place.
- **Long runs** (soak, long load or stress holds) are started by a human in a terminal
  or a CI job with the printed command; this skill does not keep a session open for
  hours. Write the protocol first (Phase 7: verdict `NOT ASSESSED`, run status
  `not run — handed to a human`); when the run finishes, rerun
  `/load-test <profile> --target <env>` —
  Phase 0 finds the protocol and the raw output and offers to analyze them.

### Soak checkpoints

Record resource metrics at fixed checkpoints — for a 4-hour soak: T+0, T+15, T+30, T+60,
T+120, T+180, T+240 (scale the schedule to the agreed duration). At each checkpoint
record, per service instance: p95 and error rate over the last interval, memory
(RSS or heap), open database connections and pool usage, queue depth or consumer lag,
disk or log volume growth, and restarts.

> **Record the unit the tool shows; never convert, and never assume one.** A soak
> looks for **growth**, so every alert condition is a ratio or a delta against this
> run's own T+0 baseline — unit-agnostic and correct however the monitoring tool
> reports the number. Write the unit down at T+0 exactly as displayed and keep it
> for the rest of the run. Alert conditions: memory growing monotonically across
> three or more checkpoints after warm-up; connection-pool usage that never returns to
> its baseline between bursts; queue lag that rises while the arrival rate is
> constant; any restart or out-of-memory kill.

> **A short soak cannot return PASS.** Everything a soak exists to detect — slow leaks,
> pool exhaustion, token or cache expiry, late-appearing errors — is invisible early, so
> a run that ended before its planned duration has not shown stability; it has shown
> nothing yet. Record the verdict `NOT ASSESSED` with `> **Run status**: incomplete —
> reached T+<N> of <duration>; checkpoints <list> not reached`. This ranks above PASS
> and below FAIL: a failure observed at T+20 is a
> real finding however short the run, and is never demoted behind the run's length.
> The same applies when no resource metrics were available (nothing was measured, so
> "no leak detected" means "no leak could have been detected") and when the protocol
> was written but never executed.

---

## Phase 7: Analyze and Write the Report

Summarize the raw output into the report — every number the verdict depends on goes
into the report itself, because `production/qa/load/raw/` is gitignored and never counts
as evidence. Compare with the previous report of the same profile when one exists.

**Verdict:**

| Verdict | When |
|---------|------|
| `FAIL` | A threshold breached at or below the expected peak (and `performance.enforce` is not `off`); the run aborted on a threshold; a stability failure (crash, restart, out-of-memory kill, data error or corrupted write, a failure cascading into another service); no recovery once the load returns to baseline (spike, stress); a soak growth trend meeting an alert condition |
| `NOT ASSESSED` | Not run (protocol only); run incomplete without a failure; a threshold unset; soak without resource metrics |
| `PASS` | The run completed the planned shape on a non-production target, every threshold is set and met, and (soak) no growth trend |

For `stress`, thresholds apply up to the expected-peak step; above it, degradation is
expected and is recorded, not scored: the **knee** (the highest arrival rate still
within budget) and the failure mode — graceful (`429`/`503` with `Retry-After`,
back-pressure, shed load) or ungraceful (timeouts and `500`s everywhere, crashes,
corrupted writes). An ungraceful mode above the peak is a finding for `## Findings`;
data errors, crashes and failure to recover are FAIL at any step. For `spike`, record
the time back to within budget
after the surge; a recovery target that was never agreed makes that row
`NOT ASSESSED — recovery target unset`.

Ask: "May I write this to `production/qa/load/load-test-<profile>-YYYY-MM-DD.md`?" If
the protocol file for this run already exists, ask before replacing it with the results.

```markdown
# Load Test: [profile] — [environment]

> **Verdict**: [PASS | FAIL | NOT ASSESSED]

> **Date**: [YYYY-MM-DD]
> **Run status**: [complete | not run — <reason> | incomplete — reached T+<N> of <duration>]
> **Profile**: [smoke | load | stress | spike | soak] — planned duration [..], actual [..]
> **Target**: [environment name] — [host] (non-production confirmed)
> **Tool**: [k6 / Locust / Gatling + version] — script `tests/load/<profile>.<ext>`
> **Enforcement**: performance.enforce = [warn | block | off] — [a FAIL here is advisory | a FAIL here is blocking | thresholds not scored]
> **Build**: [release candidate version / commit SHA]
> **Run by**: [this skill | a human — command below | CI job]
> **Generated by**: /load-test

## Workload Model

- Arrival model: [open (arrival rate) | closed (virtual users, think time)]
- Expected peak: [req/s] — source: [analytics / architecture estimate / user]
- Request mix: [journey → share]
- Test data: [synthetic accounts, token pool, idempotency keys, cleanup]

## Budgets

| Threshold | Key / source | Value | Applies to |
|-----------|--------------|-------|------------|
| Latency p95 | `performance.api_p95_ms` | [value / user-provided for this run / unset] | [all operations / per journey] |
| Error rate | `performance.error_rate_pct` | [value / unset] | [..] |

## Environment & Safety

- [ ] Target is non-production: [name / host]
- [ ] Staging runs the release candidate; size relative to production: [ratio]
- [ ] Third parties stubbed or sandbox use approved: [list]
- [ ] Synthetic data only; no production data copied
- [ ] On-call and team channel informed; dashboards: [links]
- [ ] Abort conditions: [list]
- [ ] Scaling changes: [none | proposed — applied by <who>]

## Measurements

| Scenario / operation | Requests | Rate (avg / peak req/s) | p50 | p95 | p99 | Error rate | Threshold result |
|----------------------|----------|-------------------------|-----|-----|-----|------------|------------------|
| [list-goals] | | | | | | | [met / breached / NOT ASSESSED — reason] |

## Soak Checkpoints

| Checkpoint | p95 | Error rate | Memory (unit as displayed) | Δ vs T+0 | DB connections | Queue lag | Restarts |
|------------|-----|------------|----------------------------|----------|----------------|-----------|----------|
| T+0 | | | | — | | | |

## Findings

| ID | Severity | Observation | Evidence | Next step |
|----|----------|-------------|----------|-----------|
| LT-01 | [S1-Critical / S2-Major / S3-Minor / S4-Trivial] | [..] | [metric, time window] | [/bug-report, /perf-profile, ADR] |

## Follow-ups

- [Change, owner, rerun condition]

## Run Log

- Command: `[exact command]`
- Start / end: [timestamps, KST and UTC]
- Raw output: `production/qa/load/raw/[files]` (gitignored — not evidence)
```

Keep `## Soak Checkpoints` only for the `soak` profile. After writing, confirm the file
exists and the verdict line sits directly under the H1, then summarize: verdict, the
worst operation against its threshold, the knee (stress) or recovery time (spike), and
each `NOT ASSESSED` row with what would close it.

---

## Phase 8: Next Steps

Use `AskUserQuestion` with the options that apply:

- `/bug-report` — file each S1/S2 finding (Recommended when the verdict is FAIL)
- `/perf-profile surface:api` — locate the bottleneck behind a breached threshold
- `/architecture-decision` — capacity, caching, queueing or scaling changes
- `/load-test <next profile> --target staging` — e.g. `smoke` → `load` → `soak`
- `/rollout-plan` — its production readiness review takes the latest load-test report
- `/gate-check launch` — the launch gate reads the newest load-test report
- `Stop here`

---

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and `autonomous`
modes, see `.claude/docs/automation-modes.md` — except where this file says a prompt is
asked in every mode.

- **Production is refused, never negotiated** (Phase 1).
- **No run without both conditions** — `commands.load_test` set and the user's
  confirmation of the exact command (Phase 5). Without them, the protocol is written
  with verdict NOT ASSESSED.
- **This skill never changes infrastructure** — scaling proposals are recorded for a
  human; `infra_changes` follows the always-ask list.
- **Numbers come from sources** — thresholds from `performance.*` or the user, peaks
  from analytics or the architecture, never invented.
- **Evidence lives in the report** — raw output stays under the gitignored
  `production/qa/load/raw/`, and nothing is ever written to `production/session-logs/`.
- Ask "May I write this to `<path>`?" before writing the script and before writing the
  report.
