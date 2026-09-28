# Skill Spec: /load-test

> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-09-28

## Skill Summary

`/load-test` designs, writes and — only when allowed — runs a load test against
staging or another non-production environment, and reports the result against the
product's SLO thresholds. Five profiles answer five questions: `smoke` (does the script
work), `load` (SLOs at expected peak), `stress` (breaking point and failure mode),
`spike` (sudden surge and recovery) and `soak` (degradation over hours). The tool is
chosen from the resolved `stack` line (a tool already in the repo first, then k6 for
JavaScript/TypeScript stacks, Locust for Python, Gatling for JVM). Thresholds come from
`performance.api_p95_ms` and `performance.error_rate_pct` in `project.yaml` (unset ⇒
ask; never invented), and `performance.enforce` decides whether a breach is an advisory
FAIL (`warn`), a blocking FAIL (`block`) or not scored (`off`).

`performance-engineer` (workload model, script) and `sre-engineer` (environment
readiness, observability, third-party traffic, scaling proposals) are spawned in
parallel. **Production targets are refused outright.** The test runs only when
`commands.load_test` is set and the user confirms the exact command; otherwise the
skill writes the protocol with an empty results table and verdict NOT ASSESSED.
Scaling staging is an `infra_changes` decision the skill proposes and never applies.

Outputs: `tests/load/<profile>.<ext>` and
`production/qa/load/load-test-<profile>-YYYY-MM-DD.md` with `> **Verdict**: PASS |
FAIL | NOT ASSESSED` directly under its H1 (precedence FAIL > NOT ASSESSED > PASS). Raw
tool output goes only to the gitignored `production/qa/load/raw/` and never counts as
evidence.

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`); `name: load-test` equals the skill directory and the catalog `name`
- [ ] Bootstrap: the first body line is exactly `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,automation_always_ask,performance.enforce,stack` `` and `allowed-tools` grants `Bash(bash "*/.claude/skills/load-test/../../hooks/yaml-helper.sh" resolve_config *)`
- [ ] `--keys` is exactly `automation,automation_always_ask,performance.enforce,stack`
- [ ] The line after the bootstrap block is exactly ``Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] Automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") present verbatim right after that line
- [ ] `allowed-tools` is exactly: `Read, Glob, Grep, Write, Bash, Agent, AskUserQuestion` plus the bootstrap grant — no `Edit`
- [ ] `argument-hint` is `"[profile: smoke|load|stress|spike|soak] [--target <env-name>]"`
- [ ] 2+ phase headings found (`## Phase 0: Parse Arguments` … `## Phase 8: Next Steps`)
- [ ] Verdict keywords present, exactly: `PASS`, `FAIL`, `NOT ASSESSED`
- [ ] The production refusal text begins "REFUSED — `/load-test` never targets production"
- [ ] "May I write this to `tests/load/<profile>.<ext>`?" before the script and "May I write this to `production/qa/load/load-test-<profile>-YYYY-MM-DD.md`?" before the report
- [ ] Outputs at the exact paths `tests/load/<profile>.<ext>` and `production/qa/load/load-test-<profile>-YYYY-MM-DD.md`; the report template carries `> **Verdict**: [PASS | FAIL | NOT ASSESSED]` directly under its H1; raw output only under `production/qa/load/raw/`
- [ ] Names the always-ask categories it touches (`infra_changes`, `external_calls`) and keeps `automation_always_ask` in its keys
- [ ] No `!` injection other than the bootstrap line; no `file:line` citations of other files
- [ ] Next-step handoff present at end, naming current skills: `/bug-report`, `/perf-profile`, `/architecture-decision`, `/load-test`, `/rollout-plan`, `/gate-check launch`

---

## Director Gate Checks

- **N/A**: `/load-test` spawns no director gate and `review_mode` is not among its keys.
  `performance-engineer` and `sre-engineer` are specialists that return content inline
  and write no file. The latest load-test report is later read by the
  SR-PRODUCTION-READINESS review in `/rollout-plan` and by `/gate-check launch`.

---

## Test Cases

Fixtures use the canonical product Moa: `stack` resolves `backend=NestJS 11.0 @apps/api,services/worker`,
`docs/ops/slo.md` lists the critical journeys, and staging runs the release candidate.

### Case 1: Happy Path — `load` profile on staging passes

**Fixture** (assumed project state):
- `project.yaml`: `performance.api_p95_ms: 300`, `performance.error_rate_pct: 1`, `performance.enforce` unset (resolves `warn`), `commands.load_test: k6 run tests/load/load.js`
- No script exists yet in `tests/load/`; a previous `smoke` report passed

**Input**: `/load-test load --target staging`

**Expected behavior**:
1. Phase 1 confirms the target is non-production by name and host
2. Phase 2 maps the budgets to k6 thresholds `http_req_duration: ['p(95)<300']` and `http_req_failed` `rate<0.01` with an abort on fail
3. Phase 3 spawns `performance-engineer` and `sre-engineer` in parallel with inline context and the return contract ("Do not write any file …"); the open arrival-rate model and the request mix are presented and approved
4. The script is written after "May I write this to `tests/load/load.js`?"
5. The run is confirmed with the exact command, target, duration, rates, abort conditions and third-party handling; raw output goes to `production/qa/load/raw/`
6. The report is written after "May I write this to `production/qa/load/load-test-load-YYYY-MM-DD.md`?"

**Assertions**:
- [ ] Both agents are spawned before either result is awaited
- [ ] The script contains no secrets — base URL and tokens come from environment variables named in the report
- [ ] Every number the verdict depends on is copied into the report (raw output is not evidence)
- [ ] `> **Verdict**: PASS` sits directly under the H1; `## Budgets` names both keys and their values
- [ ] The report states `performance.enforce = warn` and what a FAIL would mean

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — A production target is refused

**Fixture**:
- `modes.automation: autonomous`

**Input**: `/load-test load --target production` (and, separately, `--target live-api` whose host is the public API host recorded in `docs/architecture/architecture.md`)

**Expected behavior**:
1. Phase 1 identifies the environment as production by name or host
2. The skill stops with the refusal beginning "REFUSED — `/load-test` never targets production" and points to `/perf-profile` for production capacity evidence
3. No question is asked, no agent is spawned, no script or report is written

**Assertions**:
- [ ] The refusal is not a question and no automation mode or flag changes it
- [ ] A host that cannot be shown to be non-production is treated as production
- [ ] No write tool and no Bash run is called

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: NOT ASSESSED — No run command and an unset threshold

**Fixture**:
- `commands.load_test` is absent from `project.yaml`
- `performance.error_rate_pct` is unset and the user chooses "Leave it unset"

**Input**: `/load-test load --target staging`

**Expected behavior**:
1. The error-rate rows read `NOT ASSESSED — threshold unset`
2. Phase 5 skips the run and writes the protocol: workload model, budgets and safety plan, an empty `## Measurements` table, `> **Run status**: not run — commands.load_test unset`
3. The report verdict is NOT ASSESSED

**Assertions**:
- [ ] Verdict is NOT ASSESSED with the reason stated in the run-status line
- [ ] No PASS is possible while a threshold is unset or the run did not happen
- [ ] No threshold is invented and no vendor default is used
- [ ] A value given for this run only is recorded as `user-provided for this run — not in project.yaml`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Mode Variant — `soak` handed to a human, then analyzed

**Fixture**:
- `commands.load_test` set; an agreed soak duration of 4 hours

**Input**: `/load-test soak --target staging`, and later the same command after the run

**Expected behavior**:
1. The long run is not kept open in the session: the protocol is written with verdict NOT ASSESSED and run status `not run — handed to a human`, with the printed command and the checkpoint schedule (T+0, T+15, T+30, T+60, T+120, T+180, T+240)
2. On the rerun, Phase 0 finds the protocol and raw output under `production/qa/load/raw/` and offers `Analyze that run` / `Plan a new run`
3. If the run stopped at T+60 with no failure, the verdict is NOT ASSESSED with `> **Run status**: incomplete — reached T+60 of 4h; checkpoints … not reached`
4. If memory grew monotonically across three checkpoints after warm-up, the verdict is FAIL

**Assertions**:
- [ ] A short soak can never return PASS
- [ ] A failure observed early is FAIL however short the run — never demoted behind the run length
- [ ] Growth conditions are ratios or deltas against this run's T+0, recorded in the unit the tool displays
- [ ] `## Soak Checkpoints` appears only for the `soak` profile

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Edge Case — Enforcement off, stack unset, scaling proposals

**Fixture**:
- `performance.enforce: off`; a threshold is breached at peak and one pod restarts during the run
- In a second run, the `stack` line reads `stack: unset — run /setup-stack`
- `sre-engineer` proposes raising the staging replica count

**Expected behavior**:
1. With `off`, the breach is recorded but not scored (`Thresholds not scored — performance.enforce: off`); the restart is a stability failure and the verdict is FAIL
2. With the stack unset, the skill prints `NOT CHECKED — backend layer not configured (run /setup-stack)` and asks which tool to use
3. The scaling proposal is an `infra_changes` decision: the skill asks (the default always-ask list includes it), records the proposal, and never scales anything itself

**Assertions**:
- [ ] Stability failures (crash, restart, out-of-memory kill, data error) are FAIL at every `performance.enforce` value
- [ ] The tool is never defaulted silently when the stack is unset
- [ ] No infrastructure change is executed by the skill
- [ ] Traffic that would reach a third party (payments, 알림톡, SMS, OAuth) is stubbed or explicitly approved as an `external_calls` decision

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Edge Case — `stress` knee and failure mode

**Fixture**:
- `stress` profile stepping 100 % → 150 % → 200 % → 300 % of the expected peak; thresholds met up to 100 %; at 200 % the API returns `503` with `Retry-After`; at 300 % timeouts and `500`s appear, with no corrupted writes

**Input**: `/load-test stress --target staging`

**Expected behavior**:
1. Thresholds are scored only up to the expected-peak step
2. The report records the knee (the highest arrival rate still within budget) and the failure mode above it — graceful at 200 %, ungraceful at 300 % (a finding in `## Findings`)
3. The verdict is PASS because nothing failed at or below the peak and nothing corrupted data or failed to recover

**Assertions**:
- [ ] Degradation above the peak is recorded, not scored
- [ ] Data errors, crashes or no recovery would be FAIL at any step
- [ ] Findings use the bug severity ladder (`S1-Critical` … `S4-Trivial`) and name a next step

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses "May I write this to `<path>`?" before the script and before the report (and before replacing an existing protocol)
- [ ] Presents the workload model and safety plan for approval before writing
- [ ] Ends with a recommended next step via `AskUserQuestion`
- [ ] Does not auto-create files without user approval; runs nothing without the run confirmation, asked in every automation mode
- [ ] Writes no evidence, reports or plans under `production/session-logs/`; raw output only under `production/qa/load/raw/`
- [ ] Never writes `modes.review_mode` or any other knob that `modes.rigor` fronts
- [ ] Never targets production and never changes infrastructure

---

## Coverage Notes

- The Locust and Gatling threshold mappings follow the same rules as k6 and are not
  fixture-tested separately.
- `spike` recovery-time scoring (`NOT ASSESSED — recovery target unset` when no target
  was agreed) follows Case 3's unset-threshold rule.
- Whether staging is representative of production (the size ratio the sre-engineer
  reports) is recorded, not asserted.
