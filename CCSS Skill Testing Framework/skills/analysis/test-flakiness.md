# Skill Test Spec: /test-flakiness

## Skill Summary

`/test-flakiness` finds flaky tests from test-result history on disk — JUnit XML from
Vitest, Jest, Playwright, pytest, Gradle and Schemathesis, Playwright JSON reports
(whose `flaky` status marks a fail-then-pass retry within one run) and plain-text CI
logs. It reads CI artifacts the user has downloaded (one directory per run, e.g.
`test-results/ci-<run-id>/`) or a path given as argument; it does not fetch from the
CI service. It aggregates per-test results with Python's standard library, flags a
test flaky when it both passes and fails across runs without a relevant code change
(or passes on retry), grades it (High >25 %, Moderate 5–25 %, Low/suspected 1–5 %),
classifies the likely cause (timing/async, order dependency, random seed, time and
timezone, resource leak, shared or external state, parallelism, rendering/hydration
race, numeric comparison) and recommends quarantine (tag and a separate non-blocking
job), fix or monitor. Modes: `[ci-log-path]`, `scan`, `registry`; with no argument it
runs `scan` when result files exist, else `registry`, and with no
`tests/regression-suite.md` either it shows the no-data options (an explicit `registry`
with no manifest ends NOT ASSESSED). With approval it
appends rows to the Quarantined Tests table of `tests/regression-suite.md` (Edit) and
writes `production/qa/flakiness-report-YYYY-MM-DD.md`. It asks in plain text (no
question widget). Verdicts: **COMPLETE** (written), **BLOCKED** (write declined),
**NOT ASSESSED** (no result history to analyse, or no quarantine registry to review). No
director gates are invoked.

---

## Static Assertions (Structural)

Verified automatically by `/skill-test static` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] `name: test-flakiness` equals the skill directory, the catalog `name` and this spec's basename
- [ ] First body line is `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation` `` — exactly this one label
- [ ] `allowed-tools` grants `Bash(bash "*/.claude/skills/test-flakiness/../../hooks/yaml-helper.sh" resolve_config *)` with this skill's own directory name
- [ ] The line after the bootstrap block is exactly ``Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] The automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") follows that line verbatim
- [ ] `allowed-tools` is exactly: `Read, Glob, Grep, Write, Edit, Bash` plus the grant — membership exact, order free; no Agent or AskUserQuestion
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: COMPLETE, BLOCKED, and NOT ASSESSED for a run with no result history (obligation 1)
- [ ] Contains "May I write this to `tests/regression-suite.md`?" and, separately, "May I write this to `production/qa/flakiness-report-YYYY-MM-DD.md`?"
- [ ] Outputs only `tests/regression-suite.md` (Quarantined Tests rows appended) and `production/qa/flakiness-report-YYYY-MM-DD.md`; states the report is never written under `production/session-logs/`
- [ ] No `!` injection other than the bootstrap line; no `file:line` citations
- [ ] Has a next-step handoff naming current skills (`/regression-suite audit`, `/test-flakiness registry`, `/test-helpers`, `/sprint-plan`)

---

## Director Gate Checks

None. Flakiness detection is an advisory quality skill with no `Agent` tool; no gates
are invoked and `review_mode` is not among its keys.

---

## Test Cases

### Case 1: Happy Path — ten consistent CI runs

**Fixture:**
- `test-results/ci-<run-id>/` for 10 runs of `main`, each with `junit-api.xml` (Vitest) and `junit-e2e.xml` (Playwright)
- Every test has the same outcome in all 10 runs
- `tests/regression-suite.md` exists with an empty Quarantined Tests table

**Input:** `/test-flakiness scan`

**Expected behavior:**
1. Locates the result files on disk (one directory per run)
2. Aggregates per-test history with the Python standard-library script
3. Finds no test with both passes and failures
4. Summary: runs analysed, tests tracked, "[N] tests ran across [N] runs with consistent results — no flakiness detected"

**Assertions:**
- [ ] The number of runs and tests analysed is stated
- [ ] "no flakiness detected" is stated only together with those denominators
- [ ] No quarantine rows are proposed
- [ ] No test file is modified

---

### Case 2: Flaky Tests Found — timing race in an E2E spec

**Fixture:**
- The Case 1 runs, but `[chromium] › goals/create-goal.spec.ts › creates a goal from the empty state` fails 3 of 10 runs with a timeout while waiting for the goal card, on the same commit
- `goals/create-goal.spec.ts` uses `page.waitForTimeout(2000)` before the assertion

**Input:** `/test-flakiness scan`

**Expected behavior:**
1. Reports the test with fail rate 30 % → High flakiness
2. Classifies the cause as Timing / async, confirmed by grepping the spec for the fixed wait
3. Recommends quarantine now — tag `@quarantine`, exclude it from the gating job with `--grep-invert @quarantine`, run the tag in a separate non-blocking job — plus the fix (a web-first assertion instead of the fixed wait); notes that retries are not a fix
4. Asks "May I write this to `tests/regression-suite.md`?" and appends to the Quarantined Tests table with Edit; separately asks for the flakiness report; on approval, verdict COMPLETE

**Assertions:**
- [ ] The flaky test is named with its fail rate and the runs that failed
- [ ] The cause classification names the evidence (the fixed wait)
- [ ] Existing quarantine entries are never removed — only added
- [ ] Both writes require separate approval; the skill does not add the quarantine tag to the test itself

---

### Case 3: NOT ASSESSED — no result history on disk

**Fixture:**
- No `test-results/`, `playwright-report/`, `schemathesis-report/`, `reports/` or `**/build/test-results/**` directories
- No `tests/regression-suite.md` (so the no-argument fallback to `registry` has nothing to review)
- No argument path is given

**Input:** `/test-flakiness`

**Expected behavior:**
1. Auto-detect finds no result files and no `tests/regression-suite.md`, so it goes to Option C
2. Shows the "No CI result data found" options: download the JUnit artifacts of the last CI runs (e.g. `gh run download <run-id> --dir test-results/ci-<run-id>`), run the suite locally at least 3 times saving each run separately, or `/test-flakiness registry`
3. Stops and asks which option to pursue; the outcome is NOT ASSESSED — no test result history

**Assertions:**
- [ ] The skill does not report "no flaky tests" when zero runs were analysed
- [ ] Verdict is NOT ASSESSED with the missing input (result history) named
- [ ] Nothing is written
- [ ] The skill does not fetch from the CI service itself

---

### Case 4: Edge Case — few runs, a green run with a retry, a timezone failure

**Fixture:**
- Only 2 local runs in `test-results/local/` plus one Playwright `results.json` where `goals/deposit.spec.ts` has status `flaky` in an otherwise green run
- `apps/api/src/goals/schedule.test.ts` fails once, on the run that crossed midnight KST while CI ran in UTC

**Input:** `/test-flakiness test-results/`

**Expected behavior:**
1. Counts the Playwright `flaky` status as a flaky observation even though the run was green
2. With fewer than 3 runs, flags findings as "suspected", not "confirmed", and asks whether more run data is available
3. Classifies the schedule test as Time & timezone, recommending fake timers and an explicit `TZ`
4. `### Data Limitations` notes that fewer than 5 runs were available

**Assertions:**
- [ ] A retry that turned a failure into a pass counts as flakiness
- [ ] Low run counts lower the confidence stated in the report
- [ ] The fix direction is given even when quarantine is not recommended

---

### Case 5: Mode Variant — `registry` mode and a missing regression suite

**Fixture:**
- Run A: `tests/regression-suite.md` lists 2 quarantined tests with reasons and dates
- Run B: `tests/regression-suite.md` does not exist; the Case 2 history is on disk

**Input:** `/test-flakiness registry` (Run A), `/test-flakiness scan` (Run B), `/test-flakiness registry` on the Run B project (Run C)

**Expected behavior:**
1. Run A: reads the existing Quarantined Tests section and gives remediation guidance per test from the cause classification
2. Run B: says the manifest is missing, skips the regression-suite update and recommends `/regression-suite audit`; the flakiness report can still be written after approval
3. Run C: says the manifest is missing, recommends `/regression-suite audit`, and ends Verdict: **NOT ASSESSED** — no quarantine registry to review

**Assertions:**
- [ ] Run A writes nothing unless the user asks for the report
- [ ] Run B never creates `tests/regression-suite.md` itself
- [ ] Run B still names the flaky test and its recommendation

---

### Case 6: Gate Compliance — no gate; declined write is BLOCKED

**Fixture:**
- The Case 2 history
- `modes.review_mode: full` in `project.yaml`
- The user declines both writes

**Input:** `/test-flakiness scan`

**Expected behavior:**
1. Analyses the history and presents the findings
2. No director gate is invoked regardless of review mode
3. Asks both write questions; both are declined
4. Verdict BLOCKED — user declined write

**Assertions:**
- [ ] No director gate is invoked in any review mode
- [ ] A declined write leaves `tests/regression-suite.md` unchanged
- [ ] The report is advisory; the skill never deletes or disables a test

---

## Protocol Compliance

- [ ] Reads local result history (argument path, `scan` locations or downloaded CI artifacts) before analysis; tells the user how to download more runs instead of fetching
- [ ] States runs analysed and tests tracked; fewer than 3 runs ⇒ "suspected", not "confirmed"
- [ ] Always asks "May I write" before updating the regression suite and, separately, before writing the report
- [ ] Never deletes test files; quarantine means tag or annotate plus list
- [ ] Writes no evidence, reports or plans under `production/session-logs/`
- [ ] Never writes `modes.review_mode` or any other knob that `modes.rigor` fronts
- [ ] No director gates are invoked
- [ ] Verdict is COMPLETE, BLOCKED or NOT ASSESSED
- [ ] analysis AN1 — analysis reads result files and runs read-only parsing (the stdlib script, Grep over test files); nothing is written before approval
- [ ] analysis AN2 — the Flaky Tests Found table gives fail rate, likely cause and recommendation per test
- [ ] analysis AN3 — both writes are gated behind "May I write"
- [ ] analysis AN4 — no director gates
- [ ] Observation vs verdict: fail rates come from the parsed runs only; with zero runs the result is NOT ASSESSED, never a clean list

---

## Coverage Notes

- The flakiness thresholds (>25 %, 5–25 %, 1–5 %) are the skill's grading; the spec
  checks that intermittent failures are graded and named, not the exact cut-offs.
- Environment failures (a missing sandbox account, an expired staging certificate) can
  look like flakiness; the cause table's "Shared or external state" row covers the
  common case, and no fixture here separates the two.
- The flakiness report carries per-test analysis; it has no verdict token, so rule-12
  (the report verdict line) does not apply to it.
