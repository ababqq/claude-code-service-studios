# Skill Spec: /test-setup

> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-09-28

## Skill Summary

`/test-setup` scaffolds the automated testing infrastructure one configured stack layer
at a time, in the Architecture phase before Validation. It reads the resolved `stack`,
`code_roots` and `surfaces` lines, detects what already exists (existing files are never
overwritten), proposes a runner per layer from its runner table — web: Vitest (or Jest)
+ Testing Library + Playwright; React Native: Jest + Maestro (or Detox); Flutter:
`flutter_test` + `integration_test`; iOS native: XCTest; Android native: JUnit +
Espresso; Node backend: Vitest/Jest + Supertest; Spring: JUnit 5 + Testcontainers;
Python: pytest + httpx; contract: Schemathesis against the OpenAPI contract (or Pact) —
and lets the user confirm **each layer separately**.

It writes runner configs in each resolved code root, `tests/{unit,integration,contract,e2e}/`
with one example test each (co-located per the stack convention in a monorepo), the
**web capture interface** `tests/e2e/capture.spec.ts` (only with a web layer: run as
`npx playwright test tests/e2e/capture.spec.ts` with `CAPTURE_URL`, `CAPTURE_STATE`,
`CAPTURE_OUT_DIR`; writes `NN-<state>-desktop.png` 1280×800, `NN-<state>-mobile.png`
390×844 and, with `@axe-core/playwright`, `NN-<state>-axe.json`), the CI workflow
`.github/workflows/ci.yml` with jobs `lint`, `typecheck`, `test`, `e2e` over a matrix of
the layer roots (an `infra_changes` decision that always asks), and the `project.yaml`
keys `testing.framework`, `testing.patterns`, `commands.test`, `commands.e2e`,
`commands.lint`, `commands.typecheck` — one question per key. It verifies that the
scaffold runs, and reports the verdict in the conversation only: **SCAFFOLDED**,
**PARTIAL** or **NOT ASSESSED**.

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`); `name: test-setup` equals the skill directory and the catalog `name`
- [ ] Bootstrap: the first body line is exactly `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,automation_always_ask,stack,code_roots,surfaces` `` and `allowed-tools` grants `Bash(bash "*/.claude/skills/test-setup/../../hooks/yaml-helper.sh" resolve_config *)`
- [ ] `--keys` is exactly `automation,automation_always_ask,stack,code_roots,surfaces`
- [ ] The line after the bootstrap block is exactly ``Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] Automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") present verbatim right after that line
- [ ] `allowed-tools` is exactly: `Read, Glob, Grep, Write, Edit, Bash, AskUserQuestion` plus the bootstrap grant — no `Agent`
- [ ] `argument-hint` is `"[all | web | mobile | backend] [--ci github|gitlab|none]"`
- [ ] 2+ phase headings found (`## Phase 0: Resolve Configuration and Arguments` … `## Phase 8: Summary and Verdict`)
- [ ] Verdict keywords present, exactly: `SCAFFOLDED`, `PARTIAL`, `NOT ASSESSED`
- [ ] "May I write this to `tests/`, the runner config paths above and `.github/workflows/ci.yml`? Existing files are skipped, never overwritten." for the plan, "May I write this to `.github/workflows/ci.yml`?" for the CI workflow, and "May I write this to `<path>`?" before any other write
- [ ] Outputs at the exact paths: runner configs in the resolved roots, `tests/{unit,integration,contract,e2e}/`, `tests/e2e/capture.spec.ts` (web), `.github/workflows/ci.yml` (or `.gitlab-ci.yml` with `--ci gitlab`), and the six `project.yaml` keys
- [ ] The capture interface text names `CAPTURE_URL`, `CAPTURE_STATE`, `CAPTURE_OUT_DIR`, 1280×800, 390×844 and `@axe-core/playwright`
- [ ] No `!` injection other than the bootstrap line; no `file:line` citations of other files
- [ ] Next-step handoff present at end (closing `AskUserQuestion`), naming current skills: `/test-helpers scaffold`, `/api-design`, `/gate-check validation`, `/walking-skeleton`, `/qa-plan`

---

## Director Gate Checks

- **N/A**: `/test-setup` spawns no agent and no director gate, and `review_mode` is not
  among its keys. The Architecture → Validation gate later checks "a runner config per
  configured layer and at least one example test — and a CI workflow"; `PARTIAL` names
  what that check will find missing.

---

## Test Cases

Fixtures use the canonical product Moa: a pnpm monorepo (`stack.monorepo: true`) with
web Next.js (`apps/web`, `apps/admin`), mobile Expo (`apps/mobile`), backend NestJS
(`apps/api`, `services/worker`) and data PostgreSQL 16; `platform.surfaces: [web, ios, android, api]`.

### Case 1: Happy Path — Full scaffold returns SCAFFOLDED

**Fixture** (assumed project state):
- `apps/admin/vitest.config.ts` and `apps/api/jest.config.js` already exist; no Playwright config, no CI workflow
- `docs/api/openapi.yaml` exists; `modes.automation: collaborative`; `automation_always_ask` is the default list

**Input**: `/test-setup`

**Expected behavior**:
1. Phase 0 reports the layers, data layer, surfaces, package manager and CI target from the resolved lines
2. Phase 1 presents one table per layer; the existing configs are kept
3. Phase 2 asks one `AskUserQuestion` per layer (recommendation first); versions are resolved by the package manager, never from memory
4. Phase 3 lists every file with `skip (exists)` where applicable and asks the set question; installs are asked separately ("May I run these install commands?")
5. Phase 4 writes the configs, co-located example tests (names carry `example`), `tests/README.md`, `playwright.config.ts` at the repository root and `tests/e2e/capture.spec.ts`
6. Phase 5 shows the complete `ci.yml` and asks "May I write this to `.github/workflows/ci.yml`?"; Phase 6 asks before each of the six `project.yaml` keys; Phase 7 runs `commands.test`, lint, typecheck, e2e and one capture into a temporary directory outside the repository

**Assertions**:
- [ ] Each layer's runner is confirmed separately
- [ ] The CI workflow has jobs `lint`, `typecheck`, `test`, `e2e`, a matrix over the resolved roots, a `postgres:16` service for integration tests, and uploads JUnit XML on every run
- [ ] `testing.patterns` is written as a flow list covering co-located tests
- [ ] The summary ends with `Verdict: SCAFFOLDED` and writes no report file
- [ ] The capture verification leaves nothing in the repository

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — Declined CI and installs yield PARTIAL

**Fixture**:
- Same as Case 1, but `.github/workflows/ci.yml` already exists with a `lint` job only
- The user declines the install commands and declines the merge of the new CI jobs

**Expected behavior**:
1. The existing `ci.yml` is not overwritten: the skill shows the diff of the jobs it would add and offers to merge them with `Edit`, job by job
2. The declined installs are listed in the summary as the user's next step
3. Verdict: PARTIAL, naming each gap (missing CI jobs, example tests that cannot run)

**Assertions**:
- [ ] No existing file is overwritten
- [ ] Every declined item appears in the summary
- [ ] The verdict is PARTIAL, not SCAFFOLDED

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: NOT ASSESSED — No stack configured

**Fixture**:
- The resolved `stack` line reads `stack: unset — run /setup-stack`

**Input**: `/test-setup`

**Expected behavior**:
1. The skill stops with: "Test setup: **NOT ASSESSED** — no stack is configured, so there is no layer to scaffold a runner for. Run `/setup-stack` first, then `/test-setup`."
2. Nothing is proposed or written

**Assertions**:
- [ ] Verdict is NOT ASSESSED with the reason stated
- [ ] No runner is guessed from files on disk
- [ ] No write tool and no install command is called

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Mode Variant — Backend scope, GitLab CI, no web layer

**Fixture**:
- A second product with only a FastAPI backend (`stack.layers.backend.root: services/api`) and PostgreSQL; `platform.surfaces: [api]`

**Input**: `/test-setup backend --ci gitlab`

**Expected behavior**:
1. pytest + httpx is proposed for the backend; Schemathesis contract tests are proposed because `docs/api/openapi.yaml` exists
2. No capture script is written; the summary says `NOT CHECKED — capture script: no web layer (run-and-observe uses the ios/android/api procedures)`
3. `.gitlab-ci.yml` is written instead of `.github/workflows/ci.yml`, with the same four jobs as stages

**Assertions**:
- [ ] The capture script exists only when a web layer is configured, and its absence is announced
- [ ] `--ci gitlab` changes the CI file path, not the job names
- [ ] A scope naming a layer that is not configured stops with that reason

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Edge Case — Unresolved root and no API contract

**Fixture**:
- The `code_roots` line reports `apps/mobile` as `missing`; `docs/api/` holds no contract

**Input**: `/test-setup`

**Expected behavior**:
1. The mobile layer gets no runner config: `NOT CHECKED — mobile: no code root resolved (set stack.layers.mobile.root via /setup-stack)`
2. Contract tests are not scaffolded: `NOT CHECKED — contract tests: no API contract (run /api-design)`
3. Verdict: PARTIAL; the closing widget offers `/api-design`

**Assertions**:
- [ ] Nothing is scaffolded at a guessed path
- [ ] Every skipped layer or suite appears as a `NOT CHECKED` line in the summary
- [ ] A `WARN: undeclared code roots: …` line is printed when the label reports undeclared directories

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Edge Case — Autonomous mode still asks for the CI workflow

**Fixture**:
- `modes.automation: autonomous`; `infra_changes` is in the resolved `automation_always_ask` list

**Input**: `/test-setup`

**Expected behavior**:
1. The file set is written and the decision logged with `log_decision`
2. The CI workflow still stops for its own question — `infra_changes` always prompts
3. Each `project.yaml` key is written with `Edit` and logged; no other key is touched, and none of the six knobs `modes.rigor` fronts is ever written

**Assertions**:
- [ ] The always-ask category overrides autonomous mode for the CI workflow
- [ ] Only the six testing and command keys change in `project.yaml`
- [ ] Secrets are referenced as `${{ secrets.NAME }}` and listed for the user; no secret value is read or created

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses "May I write this to `<path>`?" before any file writes — the plan set, the CI workflow and each `project.yaml` key get their own question
- [ ] Presents the plan (every file, marking existing ones) before requesting approval
- [ ] Ends with the summary, the verdict and the closing `AskUserQuestion`
- [ ] Does not auto-create files without user approval (autonomous mode logs each decision; `infra_changes` still asks)
- [ ] Writes no evidence, reports or plans under `production/session-logs/`
- [ ] Never writes `modes.review_mode` or any other knob that `modes.rigor` fronts
- [ ] Never edits product code to make an example pass; never commits

---

## Coverage Notes

- The Flutter, iOS native (XCTest), Android native (JUnit + Espresso) and Spring rows
  of the runner table follow Case 1's per-layer confirmation and are not fixture-tested
  one by one; a test target that must exist in Xcode or Gradle is recorded as a
  `NOT CHECKED` line when absent.
- The pinned GitHub Actions majors are confirmed from each action's releases page at
  revision time; this spec does not assert specific majors.
- Phase 7 verification depends on a running disposable database and a startable app;
  when either is missing the skill records a `NOT CHECKED` line, which a live run must
  confirm.
