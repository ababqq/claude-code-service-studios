---
name: test-setup
description: "Scaffold test runners per layer (unit, integration, contract, E2E), the web capture script and the CI workflow."
argument-hint: "[all | web | mobile | backend] [--ci github|gitlab|none]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, AskUserQuestion, Bash(bash "*/.claude/skills/test-setup/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,automation_always_ask,stack,code_roots,surfaces`

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

# Test Setup

This skill scaffolds the automated testing infrastructure of the product, one
configured stack layer at a time: a test runner per layer (unit, integration,
contract, E2E), one example test per test folder, the **web capture script** that
run-and-observe uses to retain screenshot evidence, and the CI workflow that runs
all of it on every push and pull request.

Run it once in the Architecture phase (catalog step `test-setup`, required at
`standard` and `full`), before Validation. The walking skeleton of Validation rides
on the CI this skill creates, and every story from the first sprint onwards needs a
runner to hold its evidence. A test harness set up before Sprint 0 costs an hour;
one bolted on in sprint four costs the three sprints of untested code before it.

**Outputs** (each written only after approval, never overwriting a file that exists):

- runner configs in each resolved code root (`vitest.config.ts`, `jest.config.js`,
  `playwright.config.ts`, `pytest` settings in `pyproject.toml`, Gradle test
  dependencies, Maestro flows …)
- `tests/{unit,integration,contract,e2e}/` — one example test each, or co-located
  per the stack convention
- `tests/e2e/capture.spec.ts` — the web capture interface (web layer only)
- `.github/workflows/ci.yml` — jobs `lint`, `typecheck`, `test`, `e2e`
  (`--ci gitlab` writes `.gitlab-ci.yml` instead; `--ci none` writes no CI file)
- `project.yaml` — `testing.framework`, `testing.patterns`, `commands.test`,
  `commands.e2e`, `commands.lint`, `commands.typecheck` (asked one by one)

**Verdict** (conversation only — this skill writes no report):
`SCAFFOLDED | PARTIAL | NOT ASSESSED`.

---

## Phase 0: Resolve Configuration and Arguments

Read the resolved block above. Every value below comes from it or, for the keys
that have no `resolve_config` label, from `project.yaml` read with `Read`.

1. **`stack` line** — the configured layers (`web`, `mobile`, `backend`, `data`,
   `cloud`), their framework and version, and the routing. If it reads
   `stack: unset — run /setup-stack`, stop:

   > "Test setup: **NOT ASSESSED** — no stack is configured, so there is no layer
   > to scaffold a runner for. Run `/setup-stack` first, then `/test-setup`."

   Never guess a runner from files on disk when the stack is unset — a guessed
   runner is the one a later skill will trust.

2. **`code_roots` line** — the directory (or directories) of each layer. A layer
   whose root is unresolved or `missing` gets **no runner config**; record
   `NOT CHECKED — <layer>: no code root resolved (set stack.layers.<layer>.root via /setup-stack)`
   and carry it into the summary. Print the `WARN: undeclared code roots: …` line
   when the label reports `undeclared` directories — they get no runner until they
   are declared.

3. **`platform.surfaces` line** — which surfaces ship. It decides the E2E runners
   (web → Playwright, `ios`/`android` → the mobile E2E runner) and whether
   contract tests are proposed for an externally consumed API (`api`). If it reads
   `(unset -- ask which surfaces ship)`, ask — unset is not "none".

4. **`project.yaml` keys without a label** (read with `Read`):
   `stack.monorepo`, `stack.package_manager`, `testing.framework`,
   `testing.patterns`, `commands.install`, `commands.dev`, `commands.run`,
   `commands.test`, `commands.e2e`, `commands.lint`, `commands.typecheck`,
   `platform.browsers`. An existing value is a decision someone made: show it,
   and change it only with an explicit yes.

5. **Arguments.**
   - Scope (first argument, default `all`): `all` = every configured layer;
     `web`, `mobile`, `backend` = that layer only (a layer that is not configured
     ⇒ say so and stop). Data and cloud layers have no runner of their own: the
     data layer is exercised by the backend's integration tests, and the
     `cloud` layer is out of scope for this skill.
   - `--ci github|gitlab|none` (default `github`). `none` is allowed, and the
     summary says the Architecture → Validation gate requires a CI workflow.

Report before proceeding:

```
Layers in scope: web (Next.js 15.3 @ apps/web, apps/admin) · mobile (React Native (Expo) 0.79 @ apps/mobile) · backend (NestJS 11.0 @ apps/api, services/worker)
Data layer: PostgreSQL 16 (integration tests need a disposable database)
Surfaces: web, ios, android, api
Package manager: pnpm (monorepo: true)
CI target: github
```

(The versions above are illustrative — use exactly what the `stack` line prints.)

---

## Phase 1: Detect Existing Test Infrastructure

For every resolved root, and for the repository root, look for what already
exists. **Existing files are never overwritten** — this phase decides what is
missing, not what to replace.

| Look for | Glob / check |
|---|---|
| Runner configs | `vitest.config.*`, `jest.config.*`, `playwright.config.*`, `.maestro/`, `detox.config.*`, `.detoxrc*`, `pytest.ini`, `pyproject.toml` (`[tool.pytest.ini_options]`), `build.gradle*` (`testImplementation`), `pubspec.yaml` (`flutter_test`, `integration_test`), an Xcode test target (`*Tests/`) |
| Existing tests | the globs of `testing.patterns` when set; else `tests/**`, `**/*.test.*`, `**/*.spec.*`, `**/__tests__/**`, `**/test_*.py`, `**/*Test.kt`, `**/*_test.dart` |
| Package scripts | `test`, `test:e2e`, `e2e`, `lint`, `typecheck` in each root's `package.json` and the root `package.json` |
| CI | `.github/workflows/*.yml`, `.github/workflows/*.yaml`, `.gitlab-ci.yml`, `bitbucket-pipelines.yml`, `azure-pipelines.yml` |
| API contract | `docs/api/openapi.yaml` (or `openapi.json`), `docs/api/schema.graphql` |
| Capture script | `tests/e2e/capture.spec.ts` |

Present one table per layer:

```
| Layer | Root | Unit/Integration runner | E2E runner | Tests found | Package scripts |
|---|---|---|---|---|---|
| web | apps/web | none | none | 0 | lint |
| backend | apps/api | jest (jest.config.js) | — | 3 | test, lint |
```

A layer that already has a runner is **kept as it is**: the skill proposes only
what is missing for it (for example a Playwright config next to an existing
Vitest setup), never a second unit runner.

---

## Phase 2: Choose the Runners (one decision per layer)

Propose runners per configured layer from this table. **The user confirms each
layer separately** — one `AskUserQuestion` per layer, 2–4 options, the first one
marked as the recommendation. A runner choice is a **major** decision (every story
of that layer inherits it), so `guided` asks too.

| Layer / stack | Unit & integration | E2E | Notes |
|---|---|---|---|
| Web (React / Next.js, Vue / Nuxt, SvelteKit) | Vitest (or Jest) + Testing Library | Playwright | Vitest is the default for Vite-based and Next.js apps; keep Jest where the project already runs it |
| React Native / Expo | Jest (`jest-expo` preset for Expo) + React Native Testing Library | Maestro (or Detox) | Maestro flows are YAML and need no native build config; Detox needs a debug build per platform |
| Flutter | `flutter_test` | `integration_test` (or Maestro) | tests live in the app root's `test/` and `integration_test/` by convention |
| iOS native (Swift) | XCTest | XCTest UI tests (XCUITest) | a test target in the Xcode project — the skill writes the test file and says the target must exist |
| Android native (Kotlin) | JUnit | Espresso | `src/test/` and `src/androidTest/` of the module |
| Node backend (NestJS, Express, Fastify) | Vitest / Jest + Supertest | — | NestJS scaffolds Jest; keep it unless the repo already standardised on Vitest |
| Spring (Kotlin / Java) | JUnit 5 + Testcontainers | — | Testcontainers gives each integration run a disposable database |
| Python (FastAPI, Django) | pytest + httpx | — | FastAPI's `TestClient` is built on httpx |
| API contract | Schemathesis against the OpenAPI contract (or Pact when consumer-driven) | — | proposed when the backend layer is configured or `api` is a surface |

A stack that is not in this table gets the stack's own standard runner as the
proposal, labelled `not in the default table — confirm`. Never present a runner
the stack reference does not support as settled; if `docs/stack-reference/` has
nothing on the stack, say `NOT SOURCEABLE — <stack> test runner is not covered by docs/stack-reference/`
and ask the user to name it.

**Contract tests need a contract.** If no `docs/api/openapi.*` or
`docs/api/schema.graphql` exists, do not scaffold contract tests: record
`NOT CHECKED — contract tests: no API contract (run /api-design)`.

**Versions are never written from memory.** Runner packages are added with the
package manager's resolver (`pnpm add -D vitest@latest`, `uv add --dev pytest`,
the Gradle version catalog the project already uses), and the summary reports the
versions the lockfile actually resolved.

---

## Phase 3: Present the Plan

List every file this run would create, per layer, marking anything that already
exists as `skip (exists)`. Example for the illustrative product Moa (a pnpm +
Turborepo monorepo; web = Next.js, mobile = Expo, backend = NestJS, data =
PostgreSQL):

```
## Test Setup Plan — Moa

Runners (confirmed): web vitest+testing-library+playwright · mobile jest+maestro · backend jest+supertest · contract schemathesis

Repository root
  playwright.config.ts                    E2E runner for the web layer (testDir tests/e2e)
  tests/README.md                         layout, commands, naming, evidence table
  tests/contract/README.md                the Schemathesis run and what it checks
  tests/e2e/example.spec.ts               example journey, tagged @smoke
  tests/e2e/capture.spec.ts               web capture interface (run-and-observe)
  tests/e2e/mobile/example.yaml           example Maestro flow, tagged smoke
apps/web
  vitest.config.ts                        jsdom + Testing Library setup
  vitest.setup.ts
  src/example.test.tsx                    example unit/component test (co-located — monorepo)
apps/admin
  vitest.config.ts                        skip (exists)
apps/mobile
  jest.config.js                          jest-expo preset
  src/__tests__/example.test.tsx          example screen test (React Native Testing Library)
apps/api
  jest.config.js                          skip (exists)
  test/example.integration.test.ts        example API + DB test (Supertest, disposable DB)
.github/workflows/ci.yml                  lint · typecheck · test · e2e   ← infra_changes (always asks)
project.yaml                              testing.framework, testing.patterns, commands.test/e2e/lint/typecheck (asked one by one)

Install (after approval, per root): pnpm add -D -w @playwright/test @axe-core/playwright
                                    pnpm --filter web add -D vitest @vitejs/plugin-react jsdom @testing-library/react @testing-library/jest-dom
                                    …
```

Then ask once for the set: "May I write this to `tests/`, the runner config paths
above and `.github/workflows/ci.yml`? Existing files are skipped, never
overwritten." Options: `[A] Write the whole set` · `[B] Show me each file first` ·
`[C] Change the plan` · `[D] Not now`.

- **`collaborative`** — nothing is written before the answer. **`guided`** — these
  are new files, so the question is asked too (guided asks before new files).
  **`autonomous`** — write and log the decision with `log_decision`; the CI
  workflow still stops for its own question (Phase 5).
- The dependency installs change `package.json` files and lockfiles: ask
  separately — "May I run these install commands?" — and on "no", list them in the
  summary as the user's next step. A declined install leaves the verdict at
  `PARTIAL` (the example tests cannot run).

---

## Phase 4: Write Runner Configs and Example Tests

After approval, write each file with `Write` (new files) — before each one, the
approval covers it or the question "May I write this to `<path>`?" is asked. Use the
project's `naming.files` convention and the language of the layer.

### Layout and naming

- **Single-app repository**: `tests/unit/`, `tests/integration/`,
  `tests/contract/` and `tests/e2e/` at the repository root, one example each.
- **Monorepo** (`stack.monorepo: true`): unit and integration tests are
  co-located in each code root, where that package's runner finds them and
  `commands.test` (for example `pnpm turbo run test`) runs them —
  `apps/web/src/example.test.tsx`, `apps/api/test/example.integration.test.ts`.
  The repository-root `tests/` then holds the cross-package suites: `contract/`,
  `e2e/` (and later `helpers/`, `load/`, `regression-suite.md`); `tests/unit/` and
  `tests/integration/` are not created, and `tests/README.md` says where those
  tests live.
- Stacks whose own convention is co-location (Flutter's `test/`, Gradle's
  `src/test/`, an Xcode test target) keep it in either layout. `testing.patterns`
  records every place, so each reader finds co-located tests too.
- **Example files carry `example` in their name** (`example.test.ts`,
  `example.spec.ts`, `test_example.py`, `ExampleTest.kt`, `example_test.dart`).
  They prove the runner works; they are not product tests, and `/smoke-check`
  does not count them as coverage.
- Test names describe `scenario → expected`: `it('rejects a goal below the minimum target amount')`.

### `tests/README.md`

```markdown
# Tests

**Runners**: [testing.framework value, e.g. vitest+testing-library+playwright+maestro+schemathesis]
**Patterns**: [testing.patterns value]
**CI**: `.github/workflows/ci.yml`

## Layout

In a monorepo, unit and integration tests are co-located in each app or package
(see **Patterns** above); the folders below marked (single-app) are then absent.

tests/
  unit/          # (single-app) pure logic: business rules, calculations, validators, state machines
  integration/   # (single-app) API handler + DB, queue consumers, third-party adapters (mocked network)
  contract/      # the API against docs/api/ (Schemathesis) or consumer pacts
  e2e/           # critical user journeys; capture.spec.ts = evidence capture (web)
  helpers/       # factories, auth fixtures, DB reset, network mocks (/test-helpers)
  load/          # load-test scripts (/load-test)

## Commands

| What | Command |
|---|---|
| Unit + integration | [commands.test] |
| E2E | [commands.e2e] |
| Smoke subset | [commands.e2e] filtered to the smoke tag |
| Lint | [commands.lint] |
| Typecheck | [commands.typecheck] |

## Story type → evidence

| Story Type | Evidence | Where |
|---|---|---|
| Logic | automated unit test, passing | `tests/unit/<feature>/` or co-located |
| Integration | integration or contract test, passing | `tests/integration/<feature>/`, `tests/contract/<feature>/` |
| UI | component test and/or retained screenshots of each state | `production/qa/evidence/<story-slug>/` |
| E2E | automated journey test against a running environment, with trace/screenshot | `tests/e2e/<journey>/` + `production/qa/evidence/<story-slug>/` |
| Config | smoke check pass | `production/qa/smoke-YYYY-MM-DD.md` |

Evidence lives under `production/qa/evidence/`, never under `tests/` and never under
`production/session-logs/` (gitignored — it vanishes on the next clone).
```

The story-type table mirrors `.claude/docs/coding-standards.md`, which is the
authority; if the two ever disagree, coding-standards wins and this README is
fixed.

### Web layer (Vitest + Testing Library + Playwright)

`<web root>/vitest.config.ts` (one per web root):

```ts
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    setupFiles: ['./vitest.setup.ts'],
    include: ['src/**/*.test.{ts,tsx}', 'app/**/*.test.{ts,tsx}', 'components/**/*.test.{ts,tsx}'],
    reporters: process.env.CI ? ['default', 'junit'] : ['default'],
    outputFile: { junit: '../../test-results/junit-apps-web.xml' },
  },
});
```

`vitest.setup.ts` imports `@testing-library/jest-dom/vitest`. Adjust `include` to
the framework's source layout (a Vue/Nuxt app uses `@vitejs/plugin-vue` or
`@nuxt/test-utils`), and name the JUnit file after the root (`junit-apps-admin.xml`
for `apps/admin`) so roots never overwrite each other. The JUnit files CI keeps
are what `/test-flakiness` reads later.

Example unit test (co-located in a monorepo, `tests/unit/example.test.ts` in a
single-app repository) — it proves the runner, not the product:

```ts
import { describe, it, expect } from 'vitest';

// Replace with the first real business rule; this file only proves the runner works.
function roundDownToKrw10(amount: number): number {
  return Math.floor(amount / 10) * 10;
}

describe('example', () => {
  it('rounds a KRW amount down to the nearest 10', () => {
    expect(roundDownToKrw10(12_345)).toBe(12_340);
  });
});
```

`playwright.config.ts` at the **repository root** — the capture interface is run
from the root (`npx playwright test tests/e2e/capture.spec.ts`), so the E2E config
lives there even in a monorepo:

```ts
import { defineConfig, devices } from '@playwright/test';

const external = process.env.E2E_BASE_URL ?? process.env.CAPTURE_URL;

export default defineConfig({
  testDir: 'tests/e2e',
  // capture.spec.ts runs only when invoked with CAPTURE_URL (run-and-observe)
  testIgnore: process.env.CAPTURE_URL ? [] : ['**/capture.spec.ts'],
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  reporter: process.env.CI
    ? [['list'], ['junit', { outputFile: 'test-results/junit-e2e.xml' }], ['html', { open: 'never' }]]
    : [['list']],
  use: {
    baseURL: process.env.E2E_BASE_URL ?? 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'mobile-safari', use: { ...devices['iPhone 15'] } },
  ],
  // Local runs start the app; runs against staging (E2E_BASE_URL) or a capture
  // against an already running server (CAPTURE_URL) start nothing.
  webServer: external
    ? undefined
    : [
        { command: 'pnpm --filter api start', url: 'http://localhost:4000/health', reuseExistingServer: !process.env.CI },
        { command: 'pnpm --filter web start', url: 'http://localhost:3000', reuseExistingServer: !process.env.CI },
      ],
});
```

Fill `webServer` from `commands.run` / `commands.dev` and the ports the web and
API frameworks actually use; derive the browser projects from `platform.browsers`
when it is set (Safari/WebKit matters for the Korean iPhone share). Never invent a
start command — if `commands.run` is unset, ask for it.

`tests/e2e/example.spec.ts` — one journey step, tagged for the smoke subset:

```ts
import { test, expect } from '@playwright/test';

test('home renders the sign-in entry point', { tag: '@smoke' }, async ({ page }) => {
  await page.goto('/');
  await expect(page.getByRole('link', { name: /sign in|로그인/i })).toBeVisible();
});
```

Web-first assertions (`await expect(locator).toBeVisible()`), role/label locators
and no `waitForTimeout` — the same rules `.claude/rules/test-standards.md` states
for every E2E test.

### Web capture interface — `tests/e2e/capture.spec.ts`

**Written only when a web layer is configured** (Playwright requires Node). No web
layer ⇒ no capture script, and the summary says so in one line:
`NOT CHECKED — capture script: no web layer (run-and-observe uses the ios/android/api procedures)`.

The interface is fixed — `.claude/docs/run-and-observe.md` invokes it exactly so:

```
CAPTURE_URL=<route> CAPTURE_STATE=<state> CAPTURE_OUT_DIR=production/qa/evidence/<story-slug> npx playwright test tests/e2e/capture.spec.ts
```

It writes `NN-<state>-desktop.png` (1280×800) and `NN-<state>-mobile.png`
(390×844) into `CAPTURE_OUT_DIR`, and, when `@axe-core/playwright` is installed,
`NN-<state>-axe.json`. `NN` is the next free two-digit number in that directory,
shared by the files of one capture. Write the file exactly as follows:

```ts
// Evidence capture for run-and-observe (.claude/docs/run-and-observe.md).
// Run from the repository root:
//   CAPTURE_URL=/goals/new CAPTURE_STATE=empty-form \
//   CAPTURE_OUT_DIR=production/qa/evidence/story-001-create-goal \
//   npx playwright test tests/e2e/capture.spec.ts
// Writes NN-<state>-desktop.png (1280x800), NN-<state>-mobile.png (390x844) and,
// when @axe-core/playwright is installed, NN-<state>-axe.json.
import { test, expect } from '@playwright/test';
import * as fs from 'node:fs';
import * as path from 'node:path';

const url = process.env.CAPTURE_URL ?? '';
const state = process.env.CAPTURE_STATE ?? '';
const outDir = process.env.CAPTURE_OUT_DIR ?? '';

const VIEWPORTS = [
  { name: 'desktop', width: 1280, height: 800 },
  { name: 'mobile', width: 390, height: 844 },
] as const;

function nextIndex(dir: string): string {
  const used = fs
    .readdirSync(dir)
    .map((f) => /^(\d{2})-/.exec(f)?.[1])
    .filter((n): n is string => n !== undefined)
    .map(Number);
  return String(used.length ? Math.max(...used) + 1 : 1).padStart(2, '0');
}

async function loadAxe(): Promise<any | null> {
  const moduleName = '@axe-core/playwright'; // optional dependency
  try {
    return (await import(moduleName)).default;
  } catch {
    return null;
  }
}

test('capture evidence', async ({ page }) => {
  if (!url || !state || !outDir) {
    throw new Error('capture.spec.ts needs CAPTURE_URL, CAPTURE_STATE and CAPTURE_OUT_DIR');
  }
  if (!/^[a-z0-9][a-z0-9-]*$/.test(state)) {
    throw new Error(`CAPTURE_STATE must be a kebab-case slug, got "${state}"`);
  }
  fs.mkdirSync(outDir, { recursive: true });
  const nn = nextIndex(outDir);

  for (const vp of VIEWPORTS) {
    await page.setViewportSize({ width: vp.width, height: vp.height });
    const response = await page.goto(url, { waitUntil: 'load' });
    expect(response, `no response from ${url}`).not.toBeNull();
    expect(response!.status(), `${url} returned an error status`).toBeLessThan(400);
    await page.evaluate(async () => { await document.fonts.ready; });
    await page.screenshot({
      path: path.join(outDir, `${nn}-${state}-${vp.name}.png`),
      fullPage: true,
      animations: 'disabled',
    });
  }

  const AxeBuilder = await loadAxe();
  if (AxeBuilder) {
    await page.setViewportSize({ width: 1280, height: 800 });
    await page.goto(url, { waitUntil: 'load' });
    const results = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'wcag22aa'])
      .analyze();
    fs.writeFileSync(path.join(outDir, `${nn}-${state}-axe.json`), JSON.stringify(results, null, 2));
  }
});
```

Why it is shaped this way:
- **It fails loudly, never skips quietly.** Missing variables, a non-slug state or
  a 4xx/5xx route throw — a capture that silently produced nothing would read as
  evidence that was never taken. The config's `testIgnore` keeps it out of the
  normal E2E run (no `CAPTURE_URL`), and invoking it without `CAPTURE_URL` makes
  Playwright report "No tests found" and exit non-zero.
- **Relative routes work** (`CAPTURE_URL=/goals/new`) through `baseURL`
  (`E2E_BASE_URL`, default the local web server); absolute URLs work too.
- **Authenticated screens**: the capture uses the project's `use` options, so a
  `storageState` configured there (or the auth fixture of `/test-helpers`) applies.
- **The axe import is dynamic and optional**, so the typecheck job passes whether
  or not `@axe-core/playwright` is installed. The tags cover WCAG 2.x A and AA; the
  reader compares the violations with the project's accessibility target.

### Mobile layer

- **React Native / Expo** — `<mobile root>/jest.config.js` with `preset: 'jest-expo'`
  (bare React Native: `preset: 'react-native'`), `testMatch` for
  `**/*.test.{ts,tsx}`, and `jest-junit` as a CI reporter. Example
  `<mobile root>/src/__tests__/example.test.tsx` renders one screen with React
  Native Testing Library. Maestro: `tests/e2e/mobile/example.yaml`:

  ```yaml
  appId: com.moa.app
  tags:
    - smoke
  ---
  - launchApp:
      clearState: true
  - assertVisible:
      text: "시작하기"
  ```

  Run with `maestro test --include-tags=smoke tests/e2e/mobile/`. Take `appId`
  from the app config (`app.json` / `app.config.ts`), never invent it.
- **Flutter** — `<root>/test/example_test.dart` (`flutter_test`) and
  `<root>/integration_test/example_test.dart` (`integration_test`); no config file
  beyond the `dev_dependencies` the user installs.
- **iOS / Android native** — an example XCTest in the existing test target, a
  JUnit test in `src/test/` and an Espresso test in `src/androidTest/`. If the test
  target or the Gradle test dependencies are absent, write the example file and
  record `NOT CHECKED — <root>: test target not configured (create it in Xcode / add testImplementation)`.

Mobile E2E in CI needs an emulator, a simulator or a device cloud. The skill
**scaffolds the flows but adds no mobile E2E job by default**; the summary offers
the choices (an Android emulator job, EAS Workflows or Maestro Cloud, a device farm)
as a follow-up, and says `NOT CHECKED — mobile E2E in CI (not scaffolded)`.

### Backend layer

- **Node (NestJS / Express / Fastify)** — keep the framework's runner (NestJS:
  Jest with `ts-jest`), add Supertest. The integration example
  (`apps/api/test/example.integration.test.ts` in a monorepo,
  `tests/integration/example.test.ts` otherwise) boots the HTTP app in-process and
  calls the health route. The bootstrap is inline on purpose — `/test-helpers`
  runs later and may replace it with a shared helper:

  ```ts
  import { Test } from '@nestjs/testing';
  import request from 'supertest';
  import { AppModule } from '../src/app.module';

  describe('GET /health', () => {
    it('answers 200 with status ok', async () => {
      const moduleRef = await Test.createTestingModule({ imports: [AppModule] }).compile();
      const app = moduleRef.createNestApplication();
      await app.init();
      await request(app.getHttpServer())
        .get('/health')
        .expect(200)
        .expect(({ body }) => expect(body.status).toBe('ok'));
      await app.close();
    });
  });
  ```

  Take the health route from the API code (`@nestjs/terminus`, an Express
  `/health` handler); if there is none yet, the example calls the root route and the
  summary suggests adding one — `/smoke-check` Batch 1 needs it.

- **Spring** — JUnit 5 + Testcontainers (`@Testcontainers`, a `PostgreSQLContainer`
  whose image matches the data layer's database), example `ExampleIntegrationTest`
  using `MockMvc` or `WebTestClient`.
- **Python** — pytest settings in `pyproject.toml` (`[tool.pytest.ini_options]`,
  `testpaths = ["tests"]`, markers `smoke`, `integration`), example
  `tests/unit/test_example.py` and `tests/integration/test_example.py` using
  httpx against the app (FastAPI `TestClient`).
- **Integration tests never touch a shared database.** The integration example and
  CI use a disposable database (Testcontainers, a `docker compose` service, or the
  CI `services:` block); the connection string comes from an environment variable
  whose name ends in `_TEST_URL` or points at `localhost`, and the example refuses to
  run against anything else.

### Contract tests

- **Schemathesis** (provider-side, against the OpenAPI contract) —
  `tests/contract/README.md` states the run and what it checks:

  ```
  schemathesis run docs/api/openapi.yaml --url "$API_BASE_URL" --report junit
  ```

  It generates requests from every operation in the contract and fails on 5xx
  responses, schema-violating responses and undocumented status codes. The run
  needs the API up, so CI runs it in the `e2e` job. `--url` is the base URL of the
  API under test (required for a file-based schema).
- **Pact** (consumer-driven — when mobile and web clients own the expectations) —
  one consumer test `tests/contract/<consumer>.pact.test.ts` and the provider
  verification step; offered instead of Schemathesis only when the user picks it.

---

## Phase 5: The CI Workflow — `infra_changes`

A CI workflow is an `infra_changes` change: **always ask, at every automation mode**
(unless the user removed the category from `automation_always_ask`, which the
resolved block shows). Show the complete file, then ask "May I write this to
`.github/workflows/ci.yml`?". An existing `ci.yml` is never overwritten: show the
diff of the jobs you would add and ask to merge them with `Edit`, job by job.

Rules for the workflow:
- **Jobs `lint`, `typecheck`, `test`, `e2e`.** The first three run, in each
  matrix root, the package script behind `commands.lint`, `commands.typecheck` and
  `commands.test` (`pnpm run lint` in the root is the per-root form of
  `pnpm turbo run lint`); `e2e` runs `commands.e2e` from the repository root. CI
  runs what the skills run, so a green CI and a green `/smoke-check` mean the same
  thing.
- **A matrix over the layer roots** that share a toolchain (every root printed
  by the `code_roots` line for those layers). A layer with a different toolchain
  (a Python backend beside a TypeScript web app) gets its own job with the layer as
  suffix — `test-backend` — so the four job names stay the prefix.
- **Services** for integration tests come from the data layer: `PostgreSQL 16` in
  the `stack` line ⇒ a `postgres:16` service with a health check; Redis ⇒ `redis:7`.
- **JUnit XML from every runner is uploaded as an artifact** on every run, pass or
  fail — `/test-flakiness` reads that history.
- **No secrets are created or printed.** Where a job needs one (a Toss Payments
  test key for the payment sandbox, a Maestro Cloud key), reference
  `${{ secrets.NAME }}` and list the secret in the summary as the user's step;
  reading or creating secret values is `secrets_access` and never happens here.
- **Pin every action to a major.** Reuse the majors the repository's existing
  workflows pin; otherwise use the ones below, which were the current majors when
  this skill was last revised (`actions/checkout` v7, `actions/setup-node` v7,
  `pnpm/action-setup` v6, `actions/upload-artifact` v7 — Source: each action's
  GitHub releases page, retrieved 2026-09-27). Say in the summary that the
  majors should be confirmed and kept current by Dependabot or Renovate.

Example for Moa (pnpm monorepo, TypeScript on every layer):

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

jobs:
  lint:
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        root: [apps/web, apps/admin, apps/mobile, apps/api, services/worker]
    steps:
      - uses: actions/checkout@v7
      - uses: pnpm/action-setup@v6
      - uses: actions/setup-node@v7
        with:
          node-version-file: .nvmrc
          cache: pnpm
      - run: pnpm install --frozen-lockfile
      - run: pnpm run lint
        working-directory: ${{ matrix.root }}

  typecheck:
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        root: [apps/web, apps/admin, apps/mobile, apps/api, services/worker]
    steps:
      - uses: actions/checkout@v7
      - uses: pnpm/action-setup@v6
      - uses: actions/setup-node@v7
        with:
          node-version-file: .nvmrc
          cache: pnpm
      - run: pnpm install --frozen-lockfile
      - run: pnpm run typecheck
        working-directory: ${{ matrix.root }}

  test:
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        root: [apps/web, apps/admin, apps/mobile, apps/api, services/worker]
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_USER: moa
          POSTGRES_PASSWORD: moa
          POSTGRES_DB: moa_test
        ports: ["5432:5432"]
        options: >-
          --health-cmd "pg_isready -U moa"
          --health-interval 5s --health-timeout 5s --health-retries 10
    env:
      DATABASE_TEST_URL: postgresql://moa:moa@localhost:5432/moa_test
    steps:
      - uses: actions/checkout@v7
      - uses: pnpm/action-setup@v6
      - uses: actions/setup-node@v7
        with:
          node-version-file: .nvmrc
          cache: pnpm
      - run: pnpm install --frozen-lockfile
      - run: pnpm run test
        working-directory: ${{ matrix.root }}
      - uses: actions/upload-artifact@v7
        if: always()
        with:
          name: junit-test-${{ strategy.job-index }}
          path: test-results/
          if-no-files-found: ignore

  e2e:
    runs-on: ubuntu-latest
    needs: [test]
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_USER: moa
          POSTGRES_PASSWORD: moa
          POSTGRES_DB: moa_test
        ports: ["5432:5432"]
        options: >-
          --health-cmd "pg_isready -U moa"
          --health-interval 5s --health-timeout 5s --health-retries 10
    env:
      DATABASE_TEST_URL: postgresql://moa:moa@localhost:5432/moa_test
      API_BASE_URL: http://localhost:4000
    steps:
      - uses: actions/checkout@v7
      - uses: pnpm/action-setup@v6
      - uses: actions/setup-node@v7
        with:
          node-version-file: .nvmrc
          cache: pnpm
      - run: pnpm install --frozen-lockfile
      - run: pnpm exec playwright install --with-deps chromium webkit
      - run: pnpm turbo run build
      - run: pnpm exec playwright test
      - name: Contract tests (Schemathesis)
        run: |
          pnpm --filter api start &
          curl -fsS --retry 30 --retry-delay 2 --retry-all-errors "$API_BASE_URL/health"
          pipx run schemathesis run docs/api/openapi.yaml --url "$API_BASE_URL" --report junit
      - uses: actions/upload-artifact@v7
        if: always()
        with:
          name: e2e-results
          path: |
            test-results/
            playwright-report/
            schemathesis-report/
          if-no-files-found: ignore
```

Adapt, never copy blindly: the matrix roots are the `code_roots` of the layers in
scope; the commands are the `commands.*` values the user confirms in Phase 6; the
Node version comes from `.nvmrc` / `.node-version` / `package.json#engines`
(whichever the repo has — create none); the Schemathesis step exists only when the
contract exists (it needs the API running — a Playwright `webServer` entry for the
API, or an explicit start step with a health wait). With the web layer absent,
the `e2e` job runs only the contract step, or is omitted when there is nothing to run.

`--ci gitlab` writes the same four jobs as `.gitlab-ci.yml` stages (`lint`,
`typecheck`, `test`, `e2e`), `parallel: matrix:` over the roots, `services:` for the
database and `artifacts: reports: junit:` for the XML. `--ci none` writes nothing and
records `NOT CHECKED — CI workflow (--ci none): the Architecture → Validation gate requires one`.

---

## Phase 6: Record the Test Configuration in `project.yaml`

Ask **before each key** — one question per key, the proposed value first, the
current value (if any) shown beside it. These values become what `/smoke-check`,
`/dev-story`, `/story-done` and the phase gates run and search, so each is a
**major** decision (`guided` asks; `autonomous` writes and logs each with
`log_decision`). Write with `Edit` into the existing `testing:` / `commands:`
blocks, or add the block when it is absent. Never touch any other key — and never
the six knobs `modes.rigor` fronts.

| Key | Example (Moa) | Rule |
|---|---|---|
| `testing.framework` | `vitest+testing-library+playwright+jest+maestro+schemathesis` | the confirmed runners, `+`-joined |
| `testing.patterns` | `[apps/*/src/**/*.test.ts, apps/*/src/**/*.test.tsx, apps/mobile/src/**/__tests__/**, tests/**]` | **flow list** of globs covering every place tests live, co-located ones included |
| `commands.test` | `pnpm turbo run test` | unit + integration for every layer |
| `commands.e2e` | `pnpm exec playwright test` | the E2E suite from the repository root; the smoke subset is this command with `--grep @smoke` |
| `commands.lint` | `pnpm turbo run lint` | |
| `commands.typecheck` | `pnpm turbo run typecheck` | `tsc --noEmit`, mypy, … |

A command that differs per OS is written as an OS map (`default` / `linux` /
`macos` / `windows`), for example `./gradlew test` with a `windows:
gradlew.bat test` entry. After the edit, the PostToolUse data-file hook validates
`project.yaml`; if it reports a parse error, fix the edit before continuing.

---

## Phase 7: Verify the Scaffold Runs

Run each configured command once via Bash (unit/integration first):

1. `commands.test` — the example unit and integration tests must pass. The
   integration example needs the disposable database; if none is reachable
   locally, record `NOT CHECKED — integration example: no disposable database (docker compose up db, or run it in CI)`.
2. `commands.lint` and `commands.typecheck` — must exit 0 on the new files.
3. `commands.e2e` — run only when the app can be started locally (the Playwright
   `webServer` does it); otherwise `NOT CHECKED — e2e example: app not startable locally`.
4. Capture interface (web only) — when the web server is running, run it once
   against the home route with `CAPTURE_OUT_DIR` set to a temporary directory
   outside the repository, confirm the two PNGs (and the axe JSON when installed)
   appear, then delete the temporary directory. This is the proof that
   run-and-observe will work for the first UI story.

A command that fails is reported with its output tail; do not edit product code to
make an example pass — fix the scaffold file or report it.

---

## Phase 8: Summary and Verdict

```
Test setup — Moa

Runners: web vitest+testing-library+playwright · mobile jest+maestro · backend jest+supertest · contract schemathesis
Created:  [list of files]
Skipped (exist): [list]
Installed: [packages with the versions the lockfile resolved]
project.yaml: testing.framework, testing.patterns, commands.test, commands.e2e, commands.lint, commands.typecheck
Verified: commands.test PASS (4 tests) · lint PASS · typecheck PASS · e2e PASS · capture PASS (2 PNG + axe JSON)
NOT CHECKED — mobile E2E in CI (not scaffolded)
Secrets to add in the repository settings: [names, or none]
Confirm the pinned action majors: actions/checkout v7, actions/setup-node v7, pnpm/action-setup v6, actions/upload-artifact v7

Verdict: SCAFFOLDED
```

**Verdict rules** — first matching rule wins:
- **NOT ASSESSED** — the stack is unset, or no layer in scope resolved to a code
  root, so nothing could be scaffolded; or the user declined the whole plan.
- **PARTIAL** — anything in scope is missing: a layer with no runner (declined,
  unresolved root, `NOT SOURCEABLE` runner), no CI workflow (declined, or
  `--ci none`), a declined install, a `project.yaml` key left unset, an example test
  that failed, or a `NOT CHECKED` line on something in scope. Name each gap.
- **SCAFFOLDED** — every layer in scope has a runner config and an example test
  that ran green, the CI workflow exists, the capture script exists when a web
  layer is configured, and the six `project.yaml` keys are set.

The Architecture → Validation gate checks "a runner config per configured layer
and at least one example test — and a CI workflow"; `PARTIAL` names what that
check will find missing.

Close with `AskUserQuestion`, offering only the steps that apply:
- `/test-helpers scaffold` — factories, auth fixtures, DB reset and network mocks per layer
- `/api-design` — when contract tests were skipped for lack of a contract
- `/gate-check validation` — when the Architecture readiness list is complete
- `/walking-skeleton` — in Validation: the first real path through this CI to staging
- `/qa-plan` — before the first sprint, to classify stories and their evidence
- Stop here

---

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and
`autonomous` modes, see `.claude/docs/automation-modes.md` — the rules below
describe what collaborative mode requires, not universal behavior.

- **Never overwrite an existing file** — runner configs, tests and workflows that
  exist are kept; additions to an existing `ci.yml` are shown as a diff and merged
  with `Edit` only on a yes.
- **The stack is the input, not a guess** — no configured stack ⇒ NOT ASSESSED and
  `/setup-stack`. An unresolved code root ⇒ that layer is skipped with a
  `NOT CHECKED` line, never scaffolded at a guessed path.
- **Each layer's runner is the user's decision** — propose, recommend, and let
  the user confirm layer by layer.
- **"May I write this to `<path>`?" before every write** — the Phase 3 set
  approval covers the listed files; the CI workflow (`infra_changes`) and each
  `project.yaml` key get their own question.
- **No versions from memory, no secrets touched** — packages resolve through the
  package manager; secrets are referenced by name and added by the user.
- **Skips announce themselves** — every layer, job, contract or capture step that
  was not scaffolded or not run appears in the summary as a `NOT CHECKED` line.
- **No commits** — committing is the user's decision.
