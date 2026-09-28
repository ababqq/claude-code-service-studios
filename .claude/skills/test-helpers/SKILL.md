---
name: test-helpers
description: "Test helper libraries per layer: factories (fixed seed), auth fixtures, DB reset/seed, network mocks, Playwright fixtures."
argument-hint: "[scaffold | <feature-slug> | all] [--layer web|mobile|backend]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash(bash "*/.claude/skills/test-helpers/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,stack`

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

# Test Helpers

Tests are faster to write and far more stable when the same five things are done
the same way everywhere: **generating data** (factories with a fixed seed),
**signing in** (auth fixtures — test users and tokens), **resetting and seeding the
database**, **mocking the network** (MSW, nock, WireMock, responses), and **driving
the browser as a signed-in user** (Playwright fixtures). This skill generates a
`tests/helpers/` library for each configured stack layer, in the idiom of the
runner the project actually uses, so every test writes less setup and more
assertions.

**Output:** `tests/helpers/**` — nothing else. Wiring a helper into a runner
config, `tsconfig.json` or a root `conftest.py` is listed as the user's next step.

This skill has no shell, no edit and no question widget: it reads, asks in plain
text, and writes **new** files only. An existing helper is never touched.

**When to run:**
- After `/test-setup` scaffolds the runners (first time: `scaffold`)
- When several test files repeat the same setup, sign-in or mocking boilerplate
- When starting the tests of a new feature (`/test-helpers <feature-slug>`)

---

## Rules every generated helper follows

**Assert through the runner's own assertion API.** Jest and Vitest: `expect`;
Playwright: `expect` from `@playwright/test` (web-first assertions); pytest: plain
`assert` — **with assertion rewriting**, which pytest applies only to test modules
and to modules it is told about, so Python helpers are registered through
`pytest_plugins` (or `pytest.register_assert_rewrite`), never imported as ordinary
modules; JUnit 5: `Assertions` or AssertJ; XCTest: `XCTAssert*`; Dart: `expect`.
Two things go wrong with an assertion outside the runner's API, and both are silent:

1. **It aborts or degrades instead of failing the test.** A runner assertion
   records a failure with a diff and a location; a hand-rolled check produces a
   bare exception, or none at all.
2. **It can be stripped.** Python's `assert` disappears under `python -O`, and an
   un-rewritten `assert` in a helper reports `AssertionError` with no values — the
   helper that was meant to explain a failure explains nothing.

**Look up the API for the installed version before generating code.** Read the
version from the layer's `package.json` / lockfile / `pyproject.toml` / Gradle
catalog, and check `docs/stack-reference/<component>/` for post-cutoff changes.
Do not copy the forms in this file as authoritative — they are illustrative and
drift with releases. If you cannot confirm the correct API for the project's
runner, say so — `NOT SOURCEABLE — <API> for <runner> <version> is not covered by docs/stack-reference/`
— and **generate no helper** for it rather than guessing. An invented API reaching
disk is a bug; a missing helper is a task.

**Helpers are never discovered as tests.** A helper file is not named
`*.test.*`, `*.spec.*`, `test_*.py` or `*Test.kt`, contains no top-level
`describe` / `test` / `it`, and does not extend a test base class. A helper the
runner collects shows up as a suite with zero tests, or runs its setup as a test.

**Deterministic by construction.** Every generator is seeded from one exported
constant (`TEST_SEED`), every generated date is relative to one exported
reference date (`REFERENCE_DATE`) — factories never read the clock — and a reset
function restores the seed so each test sees the same sequence regardless of order.

**No real people, no real credentials.** Generated users use `example.com`
addresses and obviously fake names and numbers; tokens are signed with a test-only
key read from the test environment (never a staging or production key); social
sign-in (Kakao, Naver, Apple) is mocked at the network boundary — never a real
account. Helpers never read `.env` files of other environments.

**The database helper refuses anything but a test database.** Reset and seed
functions check the connection target first — local host, database name `test` or
ending in `_test` — and throw otherwise. A reset helper that trusts its
environment variable truncates whatever that variable happens to point at.

**Unmocked network calls fail the test.** MSW with `onUnhandledRequest: 'error'`,
`nock.disableNetConnect()` with only localhost allowed, `respx` / `responses` in
strict mode. A test that silently reaches the real Toss Payments or Kakao API is
flaky on a good day and costly on a bad one.

---

## 1. Parse Arguments

**Modes:**
- `/test-helpers scaffold` — the base library for every configured layer (no
  feature-specific helpers); use this on first run
- `/test-helpers <feature-slug>` — factories and bounds for one feature, from its
  PRD (e.g. `/test-helpers goals`)
- `/test-helpers all` — feature helpers for every feature that has a PRD and at
  least one test
- No argument — run `scaffold` if `tests/helpers/` does not exist, else `all`
- `--layer web|mobile|backend` — limit any mode to one layer (default: every
  configured layer)

---

## 2. Detect Stack and Test Framework

1. **`stack` line** (resolved above): the configured layers, their framework and
   version, and the layer paths printed after `@`. If it reads
   `stack: unset — run /setup-stack`, stop: "Test helpers: **NOT ASSESSED** — no
   stack is configured. Run `/setup-stack`, then `/test-setup`."
2. **`project.yaml` keys without a label** (read with `Read`): `testing.framework`
   (the runners), `testing.patterns` (where tests live), `naming.files`,
   `stack.package_manager`. If `testing.framework` is unset, the runner is **not
   guessed**: ask in plain text which runner each layer uses, and recommend
   `/test-setup`; a layer whose runner stays unknown gets
   `NOT CHECKED — <layer>: testing.framework unset (run /test-setup)` and no helpers.
3. **Installed versions**: for each layer, read the versions of the runner and of
   the helper libraries it would use (`@faker-js/faker`, `msw`, `nock`,
   `@testing-library/*`, `@playwright/test`, `factory_boy`, `respx`, `responses`,
   `testcontainers`, WireMock) from the layer's manifest. A library that is not
   installed is listed as the user's install step; helpers that need it are still
   generated only if its API for the version the user will install can be confirmed.

Report: "Layers: [web (Next.js 15.3) · mobile (Expo) · backend (NestJS 11.0,
PostgreSQL 16 via Prisma)]. Runners: [testing.framework]. Helper libraries
installed: [list]; missing: [list]."

---

## 3. Load Existing Test Patterns

Scan the test locations — every glob of `testing.patterns`, or the `tests/**`
convention plus co-located `**/*.test.*`, `**/*.spec.*`, `**/__tests__/**`,
`**/test_*.py` when it is unset (say which) — and the existing `tests/helpers/`.

For a representative sample (up to 5 test files per layer), read the tests and
extract:
- Setup patterns (how `beforeEach` / fixtures / `setUp` are written)
- Common assertion patterns (what is asserted most often)
- Object creation patterns (inline literals, builders, ORM calls)
- Mock/stub patterns (how HTTP, time and the database are replaced)
- Helpers that already exist anywhere (a `test/utils.ts` in a package) — reuse or
  reference them; never generate a second factory for the same entity

This ensures generated helpers match the project's existing style, not a
generic template.

Also read, when they exist:
- `design/product/feature-map.md` — which features exist
- The in-scope PRD(s) — section grep only (Step 5)
- `design/registry/entities.yaml` — entity names, fields and constants
- `docs/data/data-model.md` — entities, required fields and relationships
- `docs/api/openapi.yaml` (or `schema.graphql`) — request and response shapes the
  network mocks must honour, and the sign-in operation the auth fixtures call

---

## 4. Generate the Base Helpers (`scaffold`)

Layout (one folder per configured layer; only the layers in scope):

```
tests/helpers/
  README.md              what each helper does, how to import it, the seed
  shared/seed.ts         TEST_SEED and REFERENCE_DATE (one source for every layer in TS)
  web/
    factories.ts         in-memory builders for UI tests
    render.tsx           Testing Library render with the app's providers
    msw.ts               MSW handlers + server for component tests
    e2e-fixtures.ts      Playwright fixtures: signed-in pages per role
  mobile/
    render.tsx           React Native Testing Library render with providers
    msw.ts               MSW server for Jest (Jest runs in Node)
  backend/
    factories.ts         builders + persisted creators per entity
    auth.ts              test users per role, tokens, mocked social sign-in
    db.ts                test-database guard, reset, seed
    network.ts           nock guard and third-party mocks (payments, social login)
```

A Python backend gets `factories.py`, `auth.py`, `db.py`, `network.py` and
`fixtures.py` (pytest fixtures) instead; a JVM backend gets the equivalent classes
under `tests/helpers/backend/` plus the wiring note of Step 6. Examples below use
the illustrative product Moa (TypeScript on every layer, PostgreSQL via Prisma).

**`tests/helpers/shared/seed.ts`**

```ts
/** Fixed seed for every generated value in tests. Change it only on purpose. */
export const TEST_SEED = 20260927;

/** Reference "now" for generated dates — factories never read the clock. */
export const REFERENCE_DATE = new Date('2026-01-15T00:00:00.000Z');
```

**`tests/helpers/backend/factories.ts`** — `build*` returns an object in memory,
`create*` persists it through the same client the app uses:

```ts
import { fakerKO as faker } from '@faker-js/faker';
import type { PrismaClient } from '@prisma/client';
import { REFERENCE_DATE, TEST_SEED } from '../shared/seed';

faker.seed(TEST_SEED);
faker.setDefaultRefDate(REFERENCE_DATE);

/** Restore the seed — call in beforeEach so every test sees the same sequence. */
export function resetFactories(): void {
  faker.seed(TEST_SEED);
}

export interface UserInput {
  email: string;
  displayName: string;
  plan: 'FREE' | 'PLUS';
}

export function buildUser(overrides: Partial<UserInput> = {}): UserInput {
  return {
    email: faker.internet.email({ provider: 'example.com' }).toLowerCase(),
    displayName: faker.person.firstName(),
    plan: 'FREE',
    ...overrides,
  };
}

export function createUser(prisma: PrismaClient, overrides: Partial<UserInput> = {}) {
  return prisma.user.create({ data: buildUser(overrides) });
}
```

Model names, fields and enum values come from the data model and the ORM schema —
never invented. An entity the schema does not define gets no factory.

**`tests/helpers/backend/db.ts`** — the guard runs before every destructive call:

```ts
import type { PrismaClient } from '@prisma/client';

const LOCAL_HOSTS = new Set(['localhost', '127.0.0.1', '::1']);

/** Throws unless the URL points at a local database named `test` or `*_test`. */
export function assertTestDatabase(url = process.env.DATABASE_TEST_URL ?? ''): void {
  const parsed = new URL(url);
  const name = parsed.pathname.replace(/^\//, '');
  if (!LOCAL_HOSTS.has(parsed.hostname) || !/(^|_)test$/.test(name)) {
    throw new Error(`Refusing to reset ${parsed.hostname}/${name}: not a local test database`);
  }
}

/** Empty every application table (keeps the migrations table). */
export async function resetDatabase(prisma: PrismaClient): Promise<void> {
  assertTestDatabase();
  const tables = await prisma.$queryRaw<{ tablename: string }[]>`
    SELECT tablename FROM pg_tables
    WHERE schemaname = 'public' AND tablename <> '_prisma_migrations'`;
  if (tables.length === 0) return;
  const list = tables.map((t) => `"public"."${t.tablename}"`).join(', ');
  await prisma.$executeRawUnsafe(`TRUNCATE ${list} RESTART IDENTITY CASCADE`);
}
```

The schema is created by the project's migrations, applied once per run to the
disposable database (Testcontainers, a `docker compose` service, CI `services:`);
the helper never runs migrations itself. Other stores follow the same shape: a
guard, then the store's own reset (MySQL `TRUNCATE` per table with foreign-key
checks off, MongoDB `deleteMany({})` per collection, Redis `FLUSHDB` on a
dedicated test database index).

**`tests/helpers/backend/auth.ts`** — test users per role and tokens issued by the
app's own auth code with a test-only key:

```ts
import type { JwtService } from '@nestjs/jwt';
import { buildUser, type UserInput } from './factories';

export type Role = 'member' | 'plusMember' | 'admin';

export const TEST_USERS: Record<Role, UserInput> = {
  member: buildUser({ email: 'member@example.com', plan: 'FREE' }),
  plusMember: buildUser({ email: 'plus@example.com', plan: 'PLUS' }),
  admin: buildUser({ email: 'admin@example.com', plan: 'FREE' }),
};

/** Sign a token the way production does; the test module configures the key from TEST_JWT_SECRET. */
export function tokenFor(jwt: JwtService, userId: string, role: Role): string {
  return jwt.sign({ sub: userId, role });
}
```

Take the claim names and the signing setup from the auth module; if the product
uses sessions instead of bearer tokens, the helper creates a session through the
session store instead.

**`tests/helpers/backend/network.ts`** — no real third-party calls:

```ts
import nock from 'nock';

/** Call in the runner's setup file: only localhost may be reached. */
export function blockExternalNetwork(): void {
  nock.disableNetConnect();
  nock.enableNetConnect(/^(localhost|127\.0\.0\.1)(:\d+)?$/);
}

/** Kakao login: token exchange and user profile return a fixed test profile. */
export function mockKakaoLogin(profile = { id: 1234567890, email: 'member@example.com' }): void {
  nock('https://kauth.kakao.com').post('/oauth/token').reply(200, {
    access_token: 'test-kakao-access-token',
    token_type: 'bearer',
    expires_in: 21599,
  });
  nock('https://kapi.kakao.com')
    .get('/v2/user/me')
    .reply(200, { id: profile.id, kakao_account: { email: profile.email } });
}

/** Toss Payments auto-debit: billing-key issue succeeds with a fixed key. */
export function mockTossBillingIssue(billingKey = 'test-billing-key'): void {
  nock('https://api.tosspayments.com')
    .post('/v1/billing/authorizations/issue')
    .reply(200, { billingKey, customerKey: 'test-customer-key' });
}
```

The paths and response shapes of third-party APIs come from the provider's
documentation or the adapter code — confirm them before writing; a mock that
drifts from the provider's real response tests nothing. Check the installed nock
version intercepts `fetch` as well as `http`, or use MSW's Node server for
`fetch`-based adapters.

**`tests/helpers/web/msw.ts`** — component tests never hit the API:

```ts
import { http, HttpResponse } from 'msw';
import { setupServer } from 'msw/node';

export const handlers = [
  http.get('*/api/goals', () => HttpResponse.json({ items: [], nextCursor: null })),
];

export const server = setupServer(...handlers);
// In the runner's setup file:
//   beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));
//   afterEach(() => server.resetHandlers());
//   afterAll(() => server.close());
```

Response shapes follow the operation's schema in `docs/api/openapi.yaml`.

**`tests/helpers/web/render.tsx`** — one render with the app's real providers
(data-fetching client with retries off, i18n in the default locale, theme, router
stub), so a component test sees the same tree the app renders.

**`tests/helpers/web/e2e-fixtures.ts`** — a page already signed in as a role,
through the real sign-in operation, with no state written to disk:

```ts
import { test as base, type Page } from '@playwright/test';

type Role = 'member' | 'plusMember';

const credentials: Record<Role, { email?: string; password?: string }> = {
  member: { email: process.env.E2E_MEMBER_EMAIL, password: process.env.E2E_MEMBER_PASSWORD },
  plusMember: { email: process.env.E2E_PLUS_EMAIL, password: process.env.E2E_PLUS_PASSWORD },
};

export const test = base.extend<{ pageAs: (role: Role) => Promise<Page> }>({
  pageAs: async ({ browser, playwright, baseURL }, use) => {
    const contexts: Awaited<ReturnType<typeof browser.newContext>>[] = [];
    await use(async (role) => {
      const { email, password } = credentials[role];
      if (!email || !password) throw new Error(`E2E credentials for role "${role}" are not set`);
      const api = await playwright.request.newContext({ baseURL });
      const res = await api.post('/api/auth/sign-in', { data: { email, password } });
      if (!res.ok()) throw new Error(`sign-in as ${role} failed with ${res.status()}`);
      const context = await browser.newContext({ baseURL, storageState: await api.storageState() });
      await api.dispose();
      contexts.push(context);
      return context.newPage();
    });
    await Promise.all(contexts.map((c) => c.close()));
  },
});

export { expect } from '@playwright/test';
```

The sign-in route is the real operation from the API contract; the E2E accounts
are dedicated test accounts on the target environment, and their credentials live
in the CI secret store, never in the repository.

**`tests/helpers/mobile/`** — `render.tsx` wraps React Native Testing Library's
`render` with the app's providers; `msw.ts` is the same MSW server as the web
layer (Jest runs mobile unit tests in Node). Maestro flows need no helper library;
shared sub-flows go in the flow folder, not here.

**Python backend (pytest)** — `factories.py` with `factory_boy`
(`factory.random.reseed_random(TEST_SEED)` and `Faker.seed(TEST_SEED)`),
`db.py` with the same guard, `auth.py`, `network.py` with `respx` (httpx) or
`responses` (requests) in strict mode, and `fixtures.py` exposing them as pytest
fixtures — registered from the root `conftest.py` with
`pytest_plugins = ["tests.helpers.backend.fixtures"]`, which also gives them
assertion rewriting.

**JVM backend** — factory objects with a seeded `Random`, a Testcontainers
`PostgreSQLContainer` singleton, and WireMock stubs for third parties. Gradle does
not compile `tests/helpers/` by default: the wiring (a `testFixtures` source set or
`sourceSets.test` including the folder) is the user's step.

**`tests/helpers/README.md`** — the table of helpers (file, purpose, how to
import), the seed and reference date, the environment variables the helpers read
(`DATABASE_TEST_URL`, `TEST_JWT_SECRET`, `E2E_*`), and the setup-file lines that
activate the network guards.

---

## 5. Generate Feature-Specific Helpers (`<feature-slug>` or `all`)

For each feature in scope, read only the PRD sections this needs — Grep
`^## (Business Rules & Calculations|Edge Cases|Functional Requirements)` on
`design/prd/<feature-slug>.md` with context — rather than the full PRD. Extract:
- Entities and value types the feature owns (cross-check `design/registry/entities.yaml`)
- Business rules with their bounds, units and rounding (prices, fees, limits,
  quotas, eligibility, time windows)
- The edge cases that need data set up in a specific shape

Generate `tests/helpers/<layer>/<feature-slug>.factory.<ext>` with builders for the
feature's entities and the bounds as named constants. **Every constant traces to
the PRD** — cite the PRD path and section heading in a comment, never a line
number; a bound the PRD does not state is not invented, it is reported as a gap in
the PRD. Example for Moa's `goals` feature (values illustrative):

```ts
// Factories and bounds for goals tests. Generated by /test-helpers goals on 2026-09-27.
// Source: design/prd/goals.md § Business Rules & Calculations
import { fakerKO as faker } from '@faker-js/faker';
import { REFERENCE_DATE } from '../shared/seed';

/** Smallest savings target a goal may have (KRW). */
export const MIN_TARGET_KRW = 10_000;
/** Active goals allowed on the Free plan. */
export const MAX_ACTIVE_GOALS_FREE = 3;
/** Auto-debit amounts are whole multiples of this (KRW). */
export const DEBIT_STEP_KRW = 1_000;

export interface GoalInput {
  title: string;
  targetKrw: number;
  monthlyDebitKrw: number;
  startsOn: Date;
}

export function buildGoal(overrides: Partial<GoalInput> = {}): GoalInput {
  return {
    title: faker.word.noun(),
    targetKrw: 1_000_000,
    monthlyDebitKrw: 50_000,
    startsOn: REFERENCE_DATE,
    ...overrides,
  };
}

/** Boundary values of the target rule, for table-driven tests. */
export const TARGET_BOUNDARIES = [MIN_TARGET_KRW - 1, MIN_TARGET_KRW, MIN_TARGET_KRW + 1];
```

In `all` mode, skip features without a PRD (say so) and features whose factory
file already exists.

---

## 6. Write Output

Present the full list of files that would be created, marking existing ones:

```
## Test Helpers to Create

Base helpers (runners: vitest+testing-library+playwright · jest+supertest):
- tests/helpers/README.md
- tests/helpers/shared/seed.ts
- tests/helpers/backend/factories.ts
- tests/helpers/backend/db.ts
- tests/helpers/backend/auth.ts
- tests/helpers/backend/network.ts
- tests/helpers/web/msw.ts
- tests/helpers/web/render.tsx
- tests/helpers/web/e2e-fixtures.ts
- tests/helpers/mobile/render.tsx          skip (exists)

Feature helpers (goals):
- tests/helpers/backend/goals.factory.ts   ← design/prd/goals.md § Business Rules & Calculations

NOT SOURCEABLE — [any helper withheld, and why]
```

Then ask in plain text: "May I write this to `tests/helpers/` — the files listed
above? Existing files are skipped." In `collaborative` mode wait for the answer;
in `guided` mode these are new files, so ask as well; in `autonomous` mode write
and log the decision with `log_decision`.

**Never overwrite existing files.** If a file already exists, report:
"Skipping `[path]` — already exists. Remove or rename it if you want it
regenerated." (This skill cannot merge into an existing file.)

After writing, report the verdict and the user's wiring steps:

- **Verdict: COMPLETE** — every helper in scope was written.
- **Verdict: PARTIAL** — some helpers were withheld (`NOT SOURCEABLE`, runner
  unknown, existing file skipped, a layer `NOT CHECKED`); name each.
- **Verdict: NOT ASSESSED** — no stack configured, no runner known for any layer
  in scope, or the user declined the write.

Wiring steps to list (only those that apply):
- Install the helper libraries that are missing (with the package manager, e.g.
  `pnpm add -D -w @faker-js/faker msw nock`)
- TypeScript: add a path alias (`"@test-helpers/*": ["tests/helpers/*"]`) to the
  test tsconfig of each app, or import relatively
- Add the network-guard and MSW lines to each runner's setup file
- Python: add `pytest_plugins = ["tests.helpers.backend.fixtures"]` to the root
  `conftest.py`
- JVM: include `tests/helpers/backend/` in the test source set
- Set `DATABASE_TEST_URL`, `TEST_JWT_SECRET` and the `E2E_*` accounts in the local
  test environment and the CI secret store

---

## Next Steps

- `/test-setup` — if the runners and the CI workflow are not scaffolded yet
- `/dev-story` — implement stories; the helpers cut the setup in every new test
- `/regression-suite update` — once regression tests written with these helpers land
- `/test-flakiness` — when tests turn intermittent; seeded factories and the
  network guard remove the two most common causes

---

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and
`autonomous` modes, see `.claude/docs/automation-modes.md` — the rules below
describe what collaborative mode requires, not universal behavior.

- **Never overwrite existing helpers** — they may contain hand-written
  customisations. Only generate new files that don't exist yet
- **Generated code is a starting point** — builders mirror the data model as it
  is today; adapt them as the schema evolves
- **Helpers reflect the PRD** — bounds and constants trace to the PRD's
  Business Rules & Calculations section, not invented values
- **No guessed APIs** — an API that cannot be confirmed for the installed version
  yields `NOT SOURCEABLE` and no helper
- **Safety is built in, not documented** — the test-database guard, the network
  guard and test-only keys are part of every scaffold, not optional extras
- **Ask before writing** — always confirm before creating files in `tests/helpers/`
