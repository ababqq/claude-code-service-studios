# Skill Spec: /perf-profile

> **Category**: analysis
> **Priority**: low
> **Spec written**: 2026-09-28

## Skill Summary

`/perf-profile` measures the product against its committed `performance.*` budgets —
API latency p95 and error rate (and availability from monitoring), Core Web Vitals
(LCP, INP, CLS at p75) and initial JavaScript per route on the web, cold start and
crash-free sessions on mobile — for one surface, one route or the whole product, and
turns the result into ranked, measurable optimization recommendations. Budgets are
read from `project.yaml` with Read (they have no `resolve_config` label);
`docs/ops/slo.md` adds critical journeys and per-journey targets. Measurements follow
an evidence ladder (field data the user supplies → lab runs against local, preview or
staging → static review, which yields candidates only); `performance-engineer` is
briefed via `Agent`. `performance.enforce` decides what a breach means: `block` ⇒
FAIL, `warn` ⇒ CONCERNS, `off` ⇒ recorded but not scored. The report
`production/qa/perf/perf-profile-<scope>-YYYY-MM-DD.md` has the headings `## Scope`,
`## Budgets`, `## Measurements`, `## Breaches`, `## Ranked Recommendations` and the
verdict line `PASS | CONCERNS | FAIL | NOT ASSESSED` (precedence FAIL > CONCERNS >
NOT ASSESSED > PASS). It never loads or probes production, is the optional Hardening
catalog step `perf-profile`, and spawns no director gate.

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`); `name: perf-profile` equals the skill directory, the catalog `name` and this spec's basename
- [ ] `argument-hint` is exactly `"[surface:<web|ios|android|api> | route:<path> | full]"`; `description` is "Measure against performance.* budgets and produce ranked optimization recommendations."
- [ ] Bootstrap: the first body line is `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys performance.enforce,automation,surfaces,stack,code_roots` `` — exactly these five labels
- [ ] `allowed-tools` grants `Bash(bash "*/.claude/skills/perf-profile/../../hooks/yaml-helper.sh" resolve_config *)` with this skill's own directory name
- [ ] The line after the bootstrap block is exactly ``Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.`` (plain variant)
- [ ] The automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") follows that line verbatim
- [ ] `allowed-tools` is exactly: `Read, Glob, Grep, Write, Bash, Agent` plus the grant — membership exact, order free (`Write` is present: the skill writes its report)
- [ ] `model: sonnet`; no `disable-model-invocation` and no `isolation` flag
- [ ] 2+ phase headings found
- [ ] Verdict keywords present exactly: `PASS`, `CONCERNS`, `FAIL`, `NOT ASSESSED`, with precedence **FAIL > CONCERNS > NOT ASSESSED > PASS**; row statuses `OK`, `BREACH`, `NOT ASSESSED — <reason>`, `N/A — <surface> not configured`
- [ ] "May I write this to `production/qa/perf/perf-profile-<scope>-YYYY-MM-DD.md`?" appears before the report write
- [ ] Output at that exact path (`<scope>` = `web`, `ios`, `android`, `api`, `route-<kebab-path>` or `full`); the template has `> **Verdict**: <TOKEN>` directly under its H1 and one blank line, then `## Scope`, `## Budgets`, `## Measurements`, `## Breaches`, `## Ranked Recommendations`
- [ ] Every budget key is spelled in full (`performance.api_p95_ms`, `performance.error_rate_pct`, `performance.availability_pct`, `performance.lcp_ms`, `performance.inp_ms`, `performance.cls`, `performance.bundle_kb`, `performance.cold_start_ms`, `performance.crash_free_pct`)
- [ ] No `!` injection other than the bootstrap line; no `file:line` citations of other files; static findings name a path plus function, component or route, never a line number
- [ ] Next-step section present at the end, naming current skills only (`/architecture-decision`, `/quick-spec`, `/create-stories`, `/sprint-plan`, `/load-test`, `/bundle-audit`, `/settings`, `/create-architecture`, `/perf-profile`, `/gate-check hardening`, `/gate-check launch`, `/scope-check`)

---

## Director Gate Checks

**N/A.** No director gate at any review mode; `review_mode` is not among the keys.
`performance-engineer` is a consultant briefed inline with a return contract ("Do not
write any file — this skill writes the report. Return only …"); the verdict comes from
the Phase 4 table, not from the agent (analysis AN4). `/gate-check hardening` and
`/gate-check launch` read the newest report.

---

## Test Cases

### Case 1: Happy Path — one API route inside its budgets

**Fixture** (assumed project state):
- `project.yaml`: `platform.surfaces: [web, ios, android, api]`; backend NestJS at `apps/api`; `performance.enforce: warn`; `performance.api_p95_ms: 300`; `performance.error_rate_pct: 0.5`
- `production/qa/load/load-test-load-2026-09-20.md` reports `GET /v1/goals` at p95 212 ms and 0.1 % errors on staging
- `docs/ops/slo.md` lists the "view goals" critical journey with no conflicting target

**Input**: `/perf-profile route:/v1/goals`

**Expected behavior**:
1. Announces `Profiling route-v1-goals — surfaces: api — enforcement: warn`
2. Loads the two API budgets with Read; briefs `performance-engineer` with the budgets, the resolved `stack` and `code_roots` lines and the newest report paths and dates
3. Takes p95 and error rate from the load-test report (evidence rung recorded), with environment, build and window
4. Both rows `OK` with headroom shown → verdict `PASS`; asks "May I write this to `production/qa/perf/perf-profile-route-v1-goals-YYYY-MM-DD.md`?"

**Assertions**:
- [ ] The file name uses the scope `route-v1-goals`
- [ ] Each Measurements row names method and tool, statistic, sample or window, environment and build
- [ ] The verdict line reads `> **Verdict**: PASS`
- [ ] After writing, the summary names the tightest budget's headroom

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure — LCP breach under `performance.enforce: block`

**Fixture**:
- `performance.enforce: block`; `performance.lcp_ms: 2500`
- The user supplies a web-vitals export: `/goals` LCP p75 3,100 ms (28-day field window)
- Static review of `apps/web` finds the LCP hero image lazily loaded and a full Korean web font preloaded without subsetting

**Input**: `/perf-profile surface:web`

**Expected behavior**:
1. Records the field row (p75, 28-day window) and marks it `BREACH`, over by 600 ms, scored as FAIL
2. States that `/gate-check` treats the breach as a blocker at the `hardening` and `launch` gates
3. Ranks recommendations by expected gain ÷ effort, breaches first; each has target metric, location, expected gain (`measured` or `estimated`), effort, risk, approach and "Verify with"
4. For an M or L recommendation addressing the breach, presents options A–D in plain text (schedule, reduce scope, accept for this release, architecture decision) and waits; records each `Decision`
5. Verdict `FAIL`

**Assertions**:
- [ ] Verdict is `FAIL` and `## Breaches` shows budget, measured value and overage
- [ ] Static candidates that were not confirmed sit under `### Requires Measurement`, not in `## Measurements`
- [ ] An accepted breach stays in `## Breaches` with `Accepted — <owner>, <target date>`
- [ ] The skill loads and probes no production system (field data comes only from the supplied export)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: NOT ASSESSED — no budgets and no percentile data

**Fixture**:
- `project.yaml` has no `performance.*` budget keys (`performance.enforce` resolves to its default `warn`)
- No `production/qa/load/load-test-*.md`, no APM export
- A developer offers "I curled `/v1/goals` five times locally, about 80 ms"

**Input**: `/perf-profile surface:api`

**Expected behavior**:
1. Lists inputs as `FOUND` or `ABSENT`
2. Marks each API row `NOT ASSESSED — budget unset` and the latency row `NOT ASSESSED — no percentile data (run /load-test)`; five local requests are not a p95
3. May suggest a published starting threshold with its source, but never scores against it; names `/settings performance.api_p95_ms=<n>` or `/create-architecture` to commit one
4. Verdict `NOT ASSESSED`; the written report keeps every `NOT ASSESSED` row (if every input is absent the skill stops with `NOT ASSESSED — NO DATA` instead)

**Assertions**:
- [ ] Verdict is `NOT ASSESSED` with the reasons stated, never `PASS`
- [ ] No placeholder or published threshold stands in for an unset budget
- [ ] No headroom figure is shown for an unmeasured row

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Mode Variant — the Case 2 breach under `warn`, `off` and an invalid value

**Fixture**:
- The Case 2 measurements
- Run A: `performance.enforce: warn`
- Run B: `performance.enforce: off`
- Run C: `performance.enforce: strict` (invalid) — the bootstrap notes line reports the dropped value and the default `warn` applies

**Input**: `/perf-profile surface:web` (three runs)

**Expected behavior**:
1. Run A: verdict `CONCERNS`; `/gate-check` surfaces it as CONCERNS, not a blocker
2. Run B: the breach is listed but not scored; the header says `Budgets not scored — performance.enforce: off`; the verdict is computed as if the row were `OK`
3. Run C: the dropped-value note is repeated in the report header; scoring follows `warn`

**Assertions**:
- [ ] The enforcement value comes from the resolved line, never a direct read of `project.yaml`
- [ ] Every budget is measured the same way at every enforcement value — only the scoring changes
- [ ] Under `off` the breach row is still in the written report

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Edge Case — unset surfaces, unconfigured surface, lab vs field, SLO conflict

**Fixture**:
- Run A: `platform.surfaces` unset (the bootstrap prints `platform.surfaces: (unset -- ask which surfaces ship)`)
- Run B: `platform.surfaces: [web, api]` and the argument `surface:ios`
- Run C: `docs/ops/slo.md` sets the goals journey p95 at 250 ms while `performance.api_p95_ms: 300`; web LCP measured only by a single Lighthouse lab run; `code_roots: unresolved`

**Input**: `/perf-profile full` (A), `/perf-profile surface:ios` (B), `/perf-profile full` (C)

**Expected behavior**:
1. Run A: asks in plain text which surfaces ship; without an answer, profiles only what the argument names and marks other families `NOT ASSESSED — platform.surfaces unset`
2. Run B: reports `N/A — ios not configured` and stops for that surface; nothing is left in scope, so no report is written and the run ends `Verdict: NOT ASSESSED — nothing to profile (ios not configured)`
3. Run C: records both targets in `## Budgets` and flags the inconsistency (CONCERNS); scores the lab LCP row with the statistic column `lab`, never presenting one run as a p75; never reports Total Blocking Time as INP; prints the unresolved code roots line under `### Not Checked`, skips the static review and keeps measuring

**Assertions**:
- [ ] Unset surfaces are not read as "web only"
- [ ] A per-journey SLO that contradicts a `project.yaml` budget is never resolved silently
- [ ] Unresolved code roots stop the static review only, not the measured profile
- [ ] Run B never ends in PASS for a scope with no measured row

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses "May I write this to `<path>`?" before the report write; asks before overwriting a same-scope, same-day report
- [ ] Presents findings and decisions before requesting approval
- [ ] Ends with a recommended next step
- [ ] Does not auto-create files without user approval; raw tool output is not committed by the skill
- [ ] Writes no evidence, reports or plans under `production/session-logs/` (gitignored)
- [ ] Never writes `modes.review_mode` or any other knob that `modes.rigor` fronts
- [ ] analysis AN1 — measurement and review phases read files and run lab tools against local, preview or staging only; nothing is written before Phase 6
- [ ] analysis AN2 — `## Budgets`, `## Measurements` and `## Breaches` are tables with one status per row; recommendations carry effort and risk
- [ ] analysis AN3 — the report write is gated behind "May I write"; fixes are scheduled through other skills
- [ ] analysis AN4 — no director gate; the consultant returns rows and rankings, not a verdict
- [ ] Observation vs verdict: every Measurements cell is an observed value with its source; unmeasured or unbudgeted rows are `NOT ASSESSED — <reason>`; the verdict follows the Phase 4 table only

---

## Coverage Notes

- Tool commands (Lighthouse, `adb shell am start -W`, Instruments, profilers) vary by
  version; the spec checks that each row names the command or export that produced it,
  not the exact flags.
- `performance.availability_pct` is measured by monitoring over the SLO window; the
  spec does not include a fixture with an availability export.
- The skill has no `AskUserQuestion`; its decision prompts are plain text. A live run
  is needed to confirm it waits for the reply before writing.
