---
name: test-flakiness
description: "Find flaky tests from CI history (JUnit from Jest/Vitest/Playwright/pytest); recommend quarantine."
argument-hint: "[ci-log-path | scan | registry]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, Bash(bash "*/.claude/skills/test-flakiness/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation`

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

# Test Flakiness Detection

A flaky test is one that sometimes passes and sometimes fails without any code
change. Flaky tests are worse than no tests in some ways — they train the team
to ignore red CI runs and hit "re-run jobs" by reflex, masking genuine failures.
This skill identifies them, explains likely causes, and recommends whether to
quarantine or fix each one.

This skill asks its questions in plain text (it has no question widget): every
"Ask" below is a direct question in the conversation, and nothing is written
before the answer.

**Output:** Updated `tests/regression-suite.md` quarantine section + optional
`production/qa/flakiness-report-YYYY-MM-DD.md`

**When to run:**
- Hardening phase (tests have had many CI runs; the statistical signal is reliable)
- When developers start dismissing CI failures as "probably flaky" or re-running
  jobs until they pass
- After `/regression-suite` identifies quarantined tests that need diagnosis

---

## 1. Parse Arguments

**Modes:**
- `/test-flakiness [ci-log-path]` — analyse a specific result file or directory
  (JUnit XML, a Playwright JSON report, or a plain-text CI log)
- `/test-flakiness scan` — scan all result files available locally
  (`test-results/`, `playwright-report/`, `schemathesis-report/`, `reports/`,
  `**/build/test-results/**`, and downloaded CI artifacts)
- `/test-flakiness registry` — read the existing `tests/regression-suite.md`
  quarantine section and provide remediation guidance for already-known flaky tests
  (no manifest ⇒ say so, recommend `/regression-suite audit`, and end
  Verdict: **NOT ASSESSED** — no quarantine registry to review)
- No argument — auto-detect: run `scan` if result files are accessible, else
  `registry`; when `tests/regression-suite.md` does not exist either, go to
  Option C below (there is neither history to analyse nor a registry to review)

---

## 2. Locate CI Log Data

### Option A — CI artifacts (preferred)

The CI workflow `/test-setup` writes uploads every runner's JUnit XML as an
artifact on every run, pass or fail. That history is the input. Check what is
already on disk:

```bash
ls -d test-results/ test-results/ci-*/ playwright-report/ schemathesis-report/ 2>/dev/null
find . -path ./node_modules -prune -o -name '*.xml' -path '*test-results*' -print 2>/dev/null | head -50
```

Where each runner writes its results:
- **Vitest** — `--reporter=junit --outputFile=…` (the `/test-setup` config writes
  `test-results/junit-<root>.xml` in CI)
- **Jest** — the `jest-junit` reporter (`junit.xml`, or `JEST_JUNIT_OUTPUT_DIR`)
- **Playwright** — the `junit` reporter (`test-results/junit-e2e.xml`); the JSON
  reporter additionally marks a test that failed and then passed on retry as
  `flaky` — the strongest single-run signal there is
- **pytest** — `--junitxml=test-results/junit.xml`
- **Gradle (JUnit 5)** — `build/test-results/test/TEST-*.xml` per module
- **Schemathesis** — `--report junit` (`schemathesis-report/`)

If the history lives only in the CI service, this skill does not fetch it — it
reads local files. Tell the user how to bring several runs down, one directory
per run so runs stay separable, for example with the GitHub CLI:

```bash
gh run list --workflow ci.yml --branch main --limit 20
gh run download <run-id> --dir test-results/ci-<run-id>
```

(GitLab: download the job artifacts of the last pipelines into
`test-results/ci-<pipeline-id>/`.) Then continue with `scan`.

### Option B — Local log files

If a path argument is provided, read that file or directory directly. Plain-text
logs from a local loop also work — for example 10 runs of one suite, each saved
separately:

```bash
mkdir -p test-results/local
for i in $(seq 1 10); do
  JEST_JUNIT_OUTPUT_DIR="$PWD/test-results/local" JEST_JUNIT_OUTPUT_NAME="run-$i.xml" \
    pnpm --filter api exec jest --ci --reporters=default --reporters=jest-junit >/dev/null 2>&1
done
```

### Option C — No log data available

If no logs found:
> "No CI result data found. To detect flaky tests, this skill needs test result
> history from multiple runs. Options:
> 1. Download the JUnit artifacts of the last CI runs into `test-results/ci-<run-id>/`
> 2. Run the suite locally at least 3 times, saving each run's results separately
> 3. Run `/test-flakiness registry` to review tests already flagged as flaky
>    in `tests/regression-suite.md`"

Stop and ask the user which option to pursue.
Until result history is supplied, the outcome is Verdict: **NOT ASSESSED** — no test result history (0 runs found). Never report "no flaky tests" or a clean-tests line from zero runs.

---

## 3. Parse Test Results

For each CI log or result file found, parse:

**JUnit XML format** (Jest, Vitest, Playwright, pytest, Gradle, Schemathesis):
- `<testcase name=… classname=…>` gives the test identifier (`classname` + `name`;
  Playwright adds the project, e.g. `[chromium] › goals/create-goal.spec.ts`)
- a `<failure>` or `<error>` child marks a failed attempt; `<skipped>` is neither
  a pass nor a fail and is left out of the rate
- one file (or one run directory) = one run

Aggregate with Python's standard library rather than by hand — one line per test,
runs in chronological order:

```bash
python3 - test-results <<'PY'
import sys, pathlib, xml.etree.ElementTree as ET
from collections import defaultdict
root = pathlib.Path(sys.argv[1])
history = defaultdict(list)
for run in sorted(p for p in root.rglob('*.xml')):
    for case in ET.parse(run).getroot().iter('testcase'):
        if case.find('skipped') is not None:
            continue
        tid = f"{case.get('classname', '')}::{case.get('name')}"
        failed = case.find('failure') is not None or case.find('error') is not None
        history[tid].append((run.parent.name, 'F' if failed else 'P'))
for tid, results in sorted(history.items()):
    fails = sum(1 for _, r in results if r == 'F')
    if 0 < fails < len(results):
        print(f"{fails}/{len(results)}\t{tid}\t{''.join(r for _, r in results)}")
PY
```

**Playwright JSON report** (`results.json`): a test whose `status` is `flaky`
failed at least once and passed on retry in the same run — count it as a flaky
observation even when the run was green.

**Plain text logs**:
- Grep for pass/fail patterns:
  - Jest / Vitest: `✓` / `✕` (or `×`) beside test names, `FAIL <file>` lines
  - pytest: `PASSED` / `FAILED` (with `-rA` or `-v`)
  - Gradle: `PASSED` / `FAILED` per test with `--info` or a test logger

Build a table: `test_id → [run1_result, run2_result, run3_result, ...]`

---

## 4. Identify Flaky Tests

A test is **flaky** if it appears in the result history with both PASS and
FAIL outcomes across runs with no code changes between them (same commit, or
commits that did not touch the test or the code under it), or if a retry turned a
failure into a pass within one run.

Flakiness thresholds:
- **High flakiness**: Fails in >25% of runs — quarantine immediately
- **Moderate flakiness**: Fails in 5–25% of runs — investigate and fix soon
- **Low/suspected flakiness**: Fails in 1–5% of runs — monitor; may be
  genuinely rare failure

For each flaky test, classify the likely cause:

### Cause classification

| Cause | Symptoms | Fix direction |
|-------|----------|---------------|
| **Timing / async** | Fails while waiting on a network response, a debounce or a queue consumer; pass rate correlates with CI load | Await the condition, never a duration: Playwright web-first assertions (`await expect(locator).toBeVisible()`), `waitForResponse`, polling with a deadline; no `sleep` / `waitForTimeout` |
| **Order dependency** | Fails when run after specific other tests; passes in isolation or with `--runInBand` | Each test creates and cleans up its own data; reset the database per test or per worker; no module-level state |
| **Random seed** | Fails intermittently with no pattern; involves generated data | Seed the generator (`faker.seed(<constant>)`), log the seed on failure, use `/test-helpers` factories |
| **Time & timezone** | Fails around midnight, month end or DST; passes on developer machines in KST, fails on CI in UTC | Fake timers (`vi.useFakeTimers`, `jest.useFakeTimers`, `freezegun`), set `TZ` explicitly, compare dates in one zone |
| **Resource leak** | Fails more often later in a run; "open handles", connection-pool exhaustion | Close servers, DB pools and queues in teardown (`afterAll`); Jest `--detectOpenHandles` |
| **Shared or external state** | Fails when another test, worker or CI job touched the same database rows, bucket or sandbox account | Per-worker schemas or containers; unique IDs per test; mock the network (MSW, nock, WireMock, responses) instead of calling a live sandbox |
| **Parallelism / port collision** | Fails only with several workers; `EADDRINUSE` | Port 0 or per-worker ports; per-worker test databases |
| **Rendering / hydration race** | E2E clicks land before hydration or an animation; element "detached from DOM" | Role-based locators with auto-wait; wait for the network-idle signal the app exposes, not a timeout; disable animations in tests |
| **Numeric comparison** | Fails on exact comparisons of computed decimals (`0.1 + 0.2`), currency conversion | Money as integer minor units (KRW has none — integers); `toBeCloseTo` / `pytest.approx` for true floats |

Use Grep to check the test file for fixed waits (`waitForTimeout`, `setTimeout`,
`sleep`), unseeded randomness, `Date.now()` / `new Date()`, global state access,
real network hosts, or exact float equality to narrow down the cause.

---

## 5. Recommend Action

For each flaky test:

**Quarantine (High flakiness):**
> "Quarantine this test now: take it out of the gating run but keep it running.
> Tag it and exclude the tag from the gating job — Playwright
> `{ tag: '@quarantine' }` with `--grep-invert @quarantine`, pytest
> `@pytest.mark.quarantine` (registered under `markers` in the pytest settings)
> with `-m 'not quarantine'` — and run the tag in a
> separate, non-blocking job so the data keeps coming. Where tagging is not
> available, skip it with the reason and the tracking bug in the message
> (`test.skip('BUG-0042: flaky — auto-debit webhook race', …)`, `@Disabled("BUG-0042 …")`).
> Log it in the `tests/regression-suite.md` quarantine section. Fix the root cause
> before removing quarantine."

**Investigate and fix soon (Moderate):**
> "This test is intermittently unreliable. Root cause appears to be [cause].
> Suggested fix: [specific fix based on cause classification]. Do not quarantine
> yet — fix the test directly."

**Monitor (Low/suspected):**
> "This test shows suspected flakiness. Collect more run data before
> quarantining. Note it as 'suspected' in the regression suite."

**Retries are not a fix.** A retry setting (Playwright `retries`, `jest.retryTimes`,
`pytest-rerunfailures`) hides flakiness from the gate; it is acceptable only while
the test is tracked here and a fix is scheduled.

---

## 6. Generate Reports

### In-conversation summary

```
## Flakiness Detection Results

**Runs analysed**: [N] ([source: CI artifacts ci-<id>… | local runs])
**Tests tracked**: [N]

### Flaky Tests Found

| Test | Feature | Fail Rate | Likely Cause | Recommendation |
|------|---------|-----------|--------------|----------------|
| [test id] | [feature] | [N]% | Timing | Quarantine + fix the await |
| [test id] | [feature] | [N]% | Time & timezone | Fix: fake timers, TZ=UTC |
| [test id] | [feature] | [N]% | Order dependency | Investigate teardown |

### Clean Tests (no flakiness detected)

[N] tests ran across [N] runs with consistent results — no flakiness detected.

### Data Limitations

[Note if fewer than 5 runs were available — fewer runs = less statistical confidence;
note runs spanning code changes to the tests involved]
```

---

## 7. Update Regression Suite + Optional Report File

If `tests/regression-suite.md` does not exist, say so, skip this update and
recommend `/regression-suite audit` to create the manifest first.

Ask: "May I write this to `tests/regression-suite.md`?" — the new rows for its
Quarantined Tests table.

If yes: use `Edit` to append entries to the Quarantined Tests table.
Never remove existing quarantine entries — only add new ones.

Ask (separately): "May I write this to
`production/qa/flakiness-report-YYYY-MM-DD.md`?" — the full report.

The full report includes per-test analysis with cause details, the evidence
(which runs failed, with their run IDs) and the stack-specific fix snippet. It is
written under `production/qa/` — never under `production/session-logs/`, which is
gitignored and never counts as evidence.

After writing:

- For each quarantined test: "Add the quarantine tag (or skip annotation) to
  take this test out of the gating run. Re-enable it after the root cause is fixed."
- For fix-eligible tests: "The fix for [test] is straightforward —
  replace the fixed wait on line [N] with a web-first assertion on the element it
  waits for."
- Summary: "Once all quarantine annotations are applied, CI should run green.
  Schedule fix work for the [N] quarantined tests before the release candidate —
  `/sprint-plan` can take them as stories."

---

## Collaborative Protocol

- **Never delete test files** — quarantine means tag or annotate + list, not remove
- **Statistical confidence matters** — with < 3 runs, flag findings as
  "suspected" not "confirmed"; ask if more run data is available
- **Fix is always the goal** — quarantine is temporary; surface the fix
  direction even when recommending quarantine
- **Read, don't fetch** — result history comes from local files; the user
  downloads CI artifacts with the commands shown in Option A
- **Ask before writing** — both the regression-suite update and the report
  file require explicit approval. On write: Verdict: **COMPLETE** — flakiness report written. On decline: Verdict: **BLOCKED** — user declined write. No runs to analyse: Verdict: **NOT ASSESSED**.
- **Flakiness in CI is a team problem** — surface the list and recommended
  actions clearly; do not just silently quarantine without the team knowing
