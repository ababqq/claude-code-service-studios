# Skill Spec: /smoke-check

> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-09-28

## Skill Summary

`/smoke-check` is the gate between "implementation done" and "ready for QA hand-off":
a build that fails it does not go to QA. It runs `project-coherence.sh`, confirms that
**product** tests exist (scaffold example files and `tests/e2e/capture.spec.ts` do not
count), runs `commands.test`, checks story coverage (COVERED / MANUAL / MISSING /
WAIVED / EXPECTED / UNKNOWN, with the migration floor), and drives four smoke batches against
the named environment — **1 Build & boot** (`commands.build`, boot, the build deployed
on staging is the build under test, health endpoint 200), **2 Critical journeys**
(sign-in and the core journey via `commands.smoke` or the `commands.e2e` smoke tag, plus
batch-verified manual checks), **3 Integrations** (payment and notification sandboxes,
migrations applied on a disposable database — runs in every mode) and **4 Non-functional
spot check** (p95 and error rate against `performance.*`, or a NOT CHECKED line).
`--surface web|ios|android|api|all` adds per-surface batches; `quick` skips the
coverage scan and Batch 4 and caps the verdict at PASS WITH WARNINGS.

Output: `production/qa/smoke-YYYY-MM-DD.md` — the only file it writes — naming the
environment (staging or local), the build under test and the checklist source, with
`> **Verdict**:` directly under its H1. Verdict order **FAIL > NOT ASSESSED > PASS WITH
WARNINGS > PASS**. Whether a FAIL blocks hand-off comes from `qa.level` (minimal ⇒
advisory) and then `testing.strict.config` from the resolved block — **unset ⇒
blocking**, the smoke-check exception to the Config story default. NOT ASSESSED is
never governed by `testing.strict.config`. The skill never deploys, migrates or calls a
third-party service.

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`); `name: smoke-check` equals the skill directory and the catalog `name`
- [ ] Bootstrap: the first body line is exactly `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,qa.level,testing.strict,surfaces,stack` `` and `allowed-tools` grants `Bash(bash "*/.claude/skills/smoke-check/../../hooks/yaml-helper.sh" resolve_config *)`
- [ ] `--keys` is exactly `automation,qa.level,testing.strict,surfaces,stack`
- [ ] The line after the bootstrap block is exactly ``Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] Automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") present verbatim right after that line
- [ ] `allowed-tools` is exactly: `Read, Glob, Grep, Write, Bash, AskUserQuestion` plus the bootstrap grant — no `Edit`, no `Agent`
- [ ] `argument-hint` is `"[sprint | quick | --surface web|ios|android|api|all]"`
- [ ] 2+ phase headings found (`## Phase 1: Detect Test Setup` … `## Phase 6: Write and Gate`), with `### Batch 1 — Build & boot`, `### Batch 2 — Critical journeys`, `### Batch 3 — Integrations`, `### Batch 4 — Non-functional spot check`
- [ ] Verdict keywords present, exactly: `PASS`, `PASS WITH WARNINGS`, `NOT ASSESSED`, `FAIL`; the NOT RUN suite status
- [ ] Reads `## Smoke Test Scope` from the newest `production/qa/qa-plan-*.md`, falling back to `.claude/docs/templates/test-plan.md`
- [ ] "May I write this to `production/qa/smoke-YYYY-MM-DD.md`?" before the only write
- [ ] Output at the exact path `production/qa/smoke-YYYY-MM-DD.md`, with `> **Verdict**: [PASS | PASS WITH WARNINGS | NOT ASSESSED | FAIL]` directly under its H1
- [ ] Reads `testing.strict` `config=` from the resolved block (not from the file) and states that unset ⇒ blocking
- [ ] No `!` injection other than the bootstrap line; no `file:line` citations of other files
- [ ] Next-step handoff present at end (closing `AskUserQuestion`), naming current skills: `/team-qa`, `/bug-report`, `/test-setup`, `/smoke-check quick`, `/regression-suite update`, `/gate-check hardening`, `/gate-check launch`

---

## Director Gate Checks

- **N/A**: `/smoke-check` spawns no agent and no director gate, and `review_mode` is
  not among its keys. It is a build-health gate in its own right: `/gate-check` treats
  its report as a floor at every tier (Build → Hardening needs PASS or PASS WITH
  WARNINGS; Hardening → Launch needs PASS on the release candidate).

---

## Test Cases

Fixtures use the canonical product Moa: `stack` resolves web (Next.js) and backend
(NestJS, PostgreSQL); `commands.build`, `commands.test`, `commands.e2e` and
`commands.run` are set in `project.yaml`.

### Case 1: Happy Path — Clean run on staging returns PASS

**Fixture** (assumed project state):
- `qa.level` resolves to `standard`; `platform.surfaces: [web, api]`
- Product tests exist under `apps/api/src/**/*.test.ts` and `tests/e2e/`; `production/qa/qa-plan-sprint-07-2026-11-02.md` has a `## Smoke Test Scope`
- `docs/ops/slo.md` lists the sign-in and create-goal journeys; the Toss Payments sandbox tests pass
- `performance.api_p95_ms: 300`, `performance.error_rate_pct: 1`; the dashboard shows p95 210 ms and 0.2 %

**Input**: `/smoke-check sprint`

**Expected behavior**:
1. Phase 1 runs `bash .claude/scripts/project-coherence.sh`, counts product tests, notes CI, reads the commands, names the QA plan, and asks which environment and build are under test (Staging)
2. Phase 2 runs `commands.test` with a generous timeout and parses the results
3. Phase 3 marks every Logic/Integration/E2E story COVERED and the Config story EXPECTED
4. Batches 1–4 pass; the health endpoint answers 200 with the database up; the reported version equals the build under test
5. Phase 6 asks "May I write this to `production/qa/smoke-YYYY-MM-DD.md`?"

**Assertions**:
- [ ] The report names the environment (`staging — <web origin>, <API base URL>`) and the build under test
- [ ] A `Checklist source:` line names `production/qa/qa-plan-sprint-07-2026-11-02.md` § Smoke Test Scope
- [ ] `> **Verdict**: PASS` sits directly under the H1
- [ ] The closing widget offers `/team-qa` as the hand-off

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — Migration not applied, gate blocking by default

**Fixture**:
- Same as Case 1, except the staging deploy log shows a pending migration that did not apply
- `testing.strict` line in the resolved block: `config=unset`

**Expected behavior**:
1. Batch 3 records "Migrations: not all applied on the target database — FAILED" with the evidence it relied on (deploy log)
2. The verdict is FAIL
3. Unset `testing.strict.config` resolves to **blocking**; the message says "Do not hand off to QA until these failures are resolved" and lists each failure
4. The report is written only after approval

**Assertions**:
- [ ] Verdict is FAIL
- [ ] `**Gate level**` reads blocking with the reason `testing.strict.config unset ⇒ blocking`
- [ ] The skill does not run the migration, edit code or configuration, or call a third party itself
- [ ] `/bug-report` is offered for each failure

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: NOT ASSESSED — No product tests; suite not run

**Fixture**:
- `qa.level` resolves to `standard`
- `tests/unit/example.test.ts`, `tests/e2e/example.spec.ts` and `tests/e2e/capture.spec.ts` exist (written by `/test-setup`); no other test file
- In a second run, product tests exist but the integration database is not running locally, so `commands.test` cannot execute, and the developer answers "I can't confirm" about CI

**Input**: `/smoke-check`

**Expected behavior**:
1. First run: the skill delivers "Smoke check: **NOT ASSESSED — no product tests found** (searched: `<patterns>`)" and stops, naming `/test-setup`
2. Second run: the suite is NOT RUN (unconfirmed); the verdict is NOT ASSESSED, not FAIL and not a pass
3. The NOT ASSESSED message names each check that could not execute and the one thing that would make it runnable

**Assertions**:
- [ ] Scaffold example files and the capture script are not counted as product tests
- [ ] A bare halt without a verdict never happens — NOT ASSESSED is delivered
- [ ] Unconfirmed NOT RUN never resolves to PASS or PASS WITH WARNINGS, and is not an automatic FAIL
- [ ] The NOT ASSESSED outcome is not softened by `testing.strict.config: false`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Mode Variant — `quick` and `--surface ios`

**Fixture**:
- `platform.surfaces: [web, ios, android, api]`; `platform.min_os.ios` set
- Everything that runs passes

**Input**: `/smoke-check quick --surface ios`

**Expected behavior**:
1. Phase 3 (coverage) and Batch 4 are skipped with the note "Coverage scan skipped — run `/smoke-check sprint` for full coverage analysis."
2. Batch 3 still runs (a migration that did not apply is a failed deploy)
3. The iOS batch runs (fresh install on the minimum iOS, deep links signed in and out, push permission and a test notification, background → foreground)
4. The verdict is capped at PASS WITH WARNINGS, with the reason stated

**Assertions**:
- [ ] A `quick` run can never be PASS
- [ ] Batch 3 runs in `quick`
- [ ] The Surface-Specific Results table lists `ios`
- [ ] A `--surface` value not in `platform.surfaces` would be reported and ignored; an unset `platform.surfaces` is asked about, never read as "web only"

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Edge Case — `qa.level: minimal`, local run and invalid strictness values

**Fixture**:
- `qa.level` resolves to `minimal`; the run targets a local build; Batch 1 fails (the web app shows a blank screen)
- In a second run, `qa.level: standard`, the user picks `[B] Local build`, and every check passes
- In a third run, the notes line reports a dropped `testing.strict.config: maybe`

**Expected behavior**:
1. First run: FAIL, delivered as **advisory** regardless of `testing.strict.config`; the message says QA hand-off is not blocked but the phase gates will not accept this report
2. Second run: NOT ASSESSED with the reason "staging not checked"
3. Third run: the dropped value is surfaced and the key is treated as unset ⇒ blocking

**Assertions**:
- [ ] At `qa.level: minimal` a local run is acceptable and a FAIL is advisory
- [ ] At `standard`/`full` a local-only run cannot pass
- [ ] Only `true` and `false` are honoured for `testing.strict.config`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Edge Case — Unknown coverage rows and a skipped non-functional check

**Fixture**:
- One story path in the sprint plan does not exist (coverage row `UNKNOWN`); the suite passes
- In a second run, the user answers Batch 4 with "Not checked this session"
- In a third run, the user answers "No metrics source exists for this environment yet"

**Expected behavior**:
1. First run: NOT ASSESSED — a story nobody could read is not a story with no gaps
2. Second run: NOT ASSESSED — an offered-and-skipped Batch 4 matches no pass rule
3. Third run: `NOT CHECKED — non-functional spot check (no metrics source)`, a warning ⇒ PASS WITH WARNINGS

**Assertions**:
- [ ] Any `UNKNOWN` coverage row forces NOT ASSESSED
- [ ] "Not checked this session" and "no metrics source" produce different verdicts
- [ ] MISSING coverage alone (a Logic, Integration or E2E test at standard/full, a UI capture, or migration evidence) yields PASS WITH WARNINGS, never FAIL, and is listed under `## Missing Test Evidence`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: Mode Variant — `qa.level: minimal` with no product tests

**Fixture**:
- `qa.level` resolves to `minimal`
- Only the scaffold files exist: `tests/unit/example.test.ts`, `tests/e2e/example.spec.ts`, `tests/e2e/capture.spec.ts`
- Sprint stories: a Logic story with no test, a UI story with retained captures in `production/qa/evidence/<story-slug>/`, and a Config story; no story carries a `**Migration**` other than `None`
- Every Batch 1–3 check passes; Batch 4 is within the `performance.*` budgets

**Input**: `/smoke-check sprint`

**Expected behavior**:
1. Phase 1 finds no product tests, records `NOT CHECKED — no product tests (qa.level minimal: tests waived)` in the Automated Tests section and continues
2. Phase 2 is skipped: the suite is `NOT CHECKED` (waived), not NOT RUN
3. Phase 3 rows: Logic → `WAIVED`, UI → `MANUAL`, Config → `EXPECTED`
4. Batches 1–3 run and pass; Batch 4 is within budget
5. The verdict is PASS

**Assertions**:
- [ ] The run does not stop at Phase 1 and does not deliver NOT ASSESSED for the missing product tests
- [ ] WAIVED rows stay in the coverage table and never lower the verdict
- [ ] A UI story without captures would still be MISSING (the run-and-observe capture is never waived)
- [ ] The migration floor still applies: a story with a `**Migration**` and no `migration-dry-run.log` would be MISSING

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses "May I write this to `<path>`?" before the single write; a same-day report is never overwritten silently
- [ ] Presents the full report before requesting approval
- [ ] Ends with the closing `AskUserQuestion` offering only the steps that apply
- [ ] Does not auto-create files without user approval; never auto-fixes failures
- [ ] Writes no evidence, reports or plans under `production/session-logs/`
- [ ] Never writes `modes.review_mode` or any other knob that `modes.rigor` fronts
- [ ] Never guesses an unset `commands.*` value; asks or records the check as not executed

---

## Coverage Notes

- The web, Android and API surface batches follow the same pattern as Case 4's iOS
  batch and are not fixture-tested one by one.
- CI configuration detection (GitHub, GitLab, Bitbucket, Azure) is reported, not
  scored; it is not asserted beyond the Phase 1 summary.
- `project-coherence.sh` `MISMATCH:` lines are reported in `## Environment` and do not
  decide the verdict; their content is covered by the script's own smoke runs.
