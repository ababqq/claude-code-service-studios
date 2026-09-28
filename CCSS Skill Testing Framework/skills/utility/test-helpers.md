# Skill Spec: /test-helpers

> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-09-28

## Skill Summary

`/test-helpers` generates a `tests/helpers/` library per configured stack layer, in
the idiom of the runner the project actually uses, so every test does the same five
things the same way: **generate data** (factories seeded from one exported
`TEST_SEED`, dates relative to one `REFERENCE_DATE`), **sign in** (auth fixtures — test
users per role, tokens signed with a test-only key, social sign-in mocked at the
network boundary), **reset and seed the database** (behind a guard that refuses any
database that is not a local test database), **mock the network** (unmocked calls fail
the test — MSW `onUnhandledRequest: 'error'`, `nock.disableNetConnect()`, strict
`respx`/`responses`) and **drive the browser as a signed-in user** (Playwright
fixtures). Modes: `scaffold` (base library), `<feature-slug>` (factories and bounds
from one PRD's `## Business Rules & Calculations`), `all`; `--layer web|mobile|backend`
narrows any mode.

Helpers assert through the runner's own assertion API, are never discoverable as tests,
and are generated only when the API for the installed version can be confirmed —
otherwise `NOT SOURCEABLE — <API> for <runner> <version> is not covered by docs/stack-reference/`
and no helper. The skill reads, asks in plain text, and writes **new** files only under
`tests/helpers/**` — it has no shell, no edit and no question widget, and never
overwrites an existing helper. Verdicts: **COMPLETE**, **PARTIAL** (something withheld
or skipped, each named) and **NOT ASSESSED** (no stack, no runner known for any layer
in scope, or the write declined).

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`); `name: test-helpers` equals the skill directory and the catalog `name`
- [ ] Bootstrap: the first body line is exactly `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,stack` `` and `allowed-tools` grants `Bash(bash "*/.claude/skills/test-helpers/../../hooks/yaml-helper.sh" resolve_config *)`
- [ ] `--keys` is exactly `automation,stack`
- [ ] The line after the bootstrap block is exactly ``Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] Automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") present verbatim right after that line
- [ ] `allowed-tools` is exactly: `Read, Glob, Grep, Write` plus the bootstrap grant — no `Edit`, no plain `Bash`, no `AskUserQuestion`, no `Agent`
- [ ] `argument-hint` is `"[scaffold | <feature-slug> | all] [--layer web|mobile|backend]"`
- [ ] 2+ phase headings found (`## 1. Parse Arguments` … `## 6. Write Output`)
- [ ] Verdict keywords present, exactly: `COMPLETE`, `PARTIAL`, `NOT ASSESSED`; the `NOT SOURCEABLE` and `NOT CHECKED` lines are defined
- [ ] "May I write this to `tests/helpers/` — the files listed above? Existing files are skipped." before writing
- [ ] Outputs only under `tests/helpers/**`; runner configs, `tsconfig.json` and root `conftest.py` are listed as the user's wiring steps, never written
- [ ] No `!` injection other than the bootstrap line; no `file:line` citations of other files (feature constants cite the PRD path and section heading)
- [ ] Next-step handoff present at end, naming current skills: `/test-setup`, `/dev-story`, `/regression-suite update`, `/test-flakiness`

---

## Director Gate Checks

- **N/A**: `/test-helpers` spawns no agent and no director gate, and `review_mode` is
  not among its keys. It is a code-generation utility for test infrastructure.

---

## Test Cases

Fixtures use the canonical product Moa: `stack` resolves web (Next.js 15.3 @apps/web,apps/admin)
and backend (NestJS 11.0 @apps/api,services/worker) with PostgreSQL 16 via Prisma.

### Case 1: Happy Path — `scaffold` for web and backend

**Fixture** (assumed project state):
- `project.yaml`: `testing.framework: vitest+testing-library+playwright+jest+supertest`, `testing.patterns` set, `stack.package_manager: pnpm`
- `@faker-js/faker`, `msw`, `nock` and `@playwright/test` are in the manifests; `tests/helpers/` does not exist
- `docs/data/data-model.md` and the Prisma schema define `User` and `Goal`; `docs/api/openapi.yaml` defines the sign-in operation

**Input**: `/test-helpers` (no argument ⇒ `scaffold`, because `tests/helpers/` does not exist)

**Expected behavior**:
1. Skill reports the layers, runners, and installed and missing helper libraries
2. Skill samples up to five existing tests per layer to match their setup, assertion and mock style, and reuses helpers that already exist elsewhere
3. Skill lists every file it would create — `tests/helpers/README.md`, `shared/seed.ts`, `backend/factories.ts`, `backend/db.ts`, `backend/auth.ts`, `backend/network.ts`, `web/msw.ts`, `web/render.tsx`, `web/e2e-fixtures.ts`
4. Skill asks in plain text "May I write this to `tests/helpers/` — the files listed above? Existing files are skipped." and writes on yes
5. Skill reports Verdict: COMPLETE and the wiring steps that apply (installs, path alias, setup-file lines, `DATABASE_TEST_URL`, `TEST_JWT_SECRET`, `E2E_*` in the local environment and the CI secret store)

**Assertions**:
- [ ] Every generator is seeded from `TEST_SEED`; generated dates are relative to `REFERENCE_DATE`; factories never read the clock
- [ ] The database reset calls the test-database guard first (local host, database name `test` or ending in `_test`) and throws otherwise
- [ ] Unmocked network calls fail — `nock.disableNetConnect()` with only localhost allowed; MSW with `onUnhandledRequest: 'error'`
- [ ] Generated users use `example.com` addresses; no real account, staging or production key appears
- [ ] Factory fields come from the data model and ORM schema — no invented entity or field

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — Existing helper and unconfirmable API

**Fixture**:
- `tests/helpers/web/render.tsx` already exists with hand-written providers
- The mobile layer's runner version cannot be matched to a confirmed API in `docs/stack-reference/`

**Input**: `/test-helpers scaffold`

**Expected behavior**:
1. The plan marks `tests/helpers/web/render.tsx` as `skip (exists)` and the write reports "Skipping `tests/helpers/web/render.tsx` — already exists. Remove or rename it if you want it regenerated."
2. The mobile helpers are withheld with `NOT SOURCEABLE — <API> for <runner> <version> is not covered by docs/stack-reference/`
3. Verdict: PARTIAL, naming each withheld or skipped helper

**Assertions**:
- [ ] An existing helper is never overwritten or merged into
- [ ] No helper with a guessed API reaches disk
- [ ] PARTIAL names every gap

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: NOT ASSESSED — No stack configured

**Fixture**:
- The resolved `stack` line reads `stack: unset — run /setup-stack`

**Input**: `/test-helpers scaffold`

**Expected behavior**:
1. Skill stops with "Test helpers: **NOT ASSESSED** — no stack is configured. Run `/setup-stack`, then `/test-setup`."
2. No file is listed or written

**Assertions**:
- [ ] Verdict is NOT ASSESSED with the reason stated
- [ ] No runner or layer is guessed from files on disk
- [ ] No write tool is called

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Mode Variant — Feature helpers for `goals`

**Fixture**:
- `design/prd/goals.md` has `## Business Rules & Calculations` stating a minimum target of KRW 10,000, a Free-plan limit of 3 active goals and debit amounts in KRW 1,000 steps; it states no maximum target

**Input**: `/test-helpers goals`

**Expected behavior**:
1. Skill greps `^## (Business Rules & Calculations|Edge Cases|Functional Requirements)` in the PRD instead of reading it whole, and cross-checks `design/registry/entities.yaml`
2. Skill proposes `tests/helpers/backend/goals.factory.ts` with a `buildGoal` builder, the three bounds as named constants and a boundary table
3. The file header cites `design/prd/goals.md § Business Rules & Calculations`
4. The missing maximum is reported as a gap in the PRD, not invented

**Assertions**:
- [ ] Every constant traces to the PRD by path and section heading — never a line number
- [ ] A bound the PRD does not state is not written as a constant
- [ ] The output path is `tests/helpers/<layer>/<feature-slug>.factory.<ext>`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Edge Case — Runner unknown for one layer; Python backend

**Fixture**:
- `testing.framework` is unset; the web layer's runner stays unknown after the plain-text question
- A second project has a FastAPI backend with pytest

**Expected behavior**:
1. The runner is not guessed: the skill asks in plain text and recommends `/test-setup`; the web layer gets `NOT CHECKED — web: testing.framework unset (run /test-setup)` and no helpers
2. For the Python backend the skill generates `factories.py`, `auth.py`, `db.py`, `network.py` and `fixtures.py`, with the wiring step `pytest_plugins = ["tests.helpers.backend.fixtures"]` in the root `conftest.py` (which gives the helpers assertion rewriting)

**Assertions**:
- [ ] A skipped layer announces itself with a `NOT CHECKED` line
- [ ] Python helpers are registered through `pytest_plugins`, never imported as plain modules
- [ ] No helper file is named `*.test.*`, `*.spec.*`, `test_*.py` or `*Test.kt`, and none contains a top-level `describe` / `test` / `it`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Edge Case — `all` mode and autonomous writes

**Fixture**:
- `design/product/feature-map.md` lists `goals`, `payments` and `notifications`; `goals` and `payments` each have a PRD and at least one test; `notifications` has no PRD; `tests/helpers/backend/goals.factory.ts` exists
- `modes.automation: autonomous`

**Input**: `/test-helpers all`

**Expected behavior**:
1. `notifications` is skipped with the reason "no PRD"; `goals` is skipped because its factory exists; `payments` gets its factory
2. In `autonomous` mode the files are written and the decision is logged with `log_decision`; in `collaborative` and `guided` modes the plain-text question is asked first

**Assertions**:
- [ ] Every skipped feature is named with its reason
- [ ] Autonomous writes still create new files only
- [ ] The verdict is PARTIAL when any in-scope helper was skipped

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses "May I write this to `tests/helpers/` …?" before writing (or is autonomous and logs the decision)
- [ ] Presents the full list of files, marking existing ones, before requesting approval
- [ ] Ends with the verdict, the wiring steps and the next skills
- [ ] Does not auto-create files without user approval in `collaborative` and `guided` modes
- [ ] Writes no evidence, reports or plans under `production/session-logs/`
- [ ] Never writes `modes.review_mode` or any other knob that `modes.rigor` fronts
- [ ] Never reads `.env` files of other environments and never uses a non-test key

---

## Coverage Notes

- JVM helpers (seeded `Random`, a Testcontainers PostgreSQL singleton, WireMock stubs)
  and the mobile React Native Testing Library render follow Case 1's rules and are not
  fixture-tested separately.
- Whether a third-party mock's paths and shapes match the provider's real API needs a
  live check against the provider's documentation or the adapter code.
- The `--layer` flag narrows the file list only; it is not tested on its own.
