---
paths:
  - "tests/**"
  - "**/*.test.*"
  - "**/*.spec.*"
  - "**/__tests__/**"
  - "e2e/**"
---

# Test Standards

## Every test

- Test naming follows the stack convention recorded in `testing.patterns`
  (`*.test.ts`, `*.spec.ts`, `test_*.py`, `*Test.kt`, `*_test.dart`); test names
  describe `scenario → expected` (`it('rejects a goal below the minimum target')`)
- Every test has a clear arrange / act / assert structure and asserts through the
  runner's own API (`expect`, pytest `assert`, JUnit `Assertions`)
- **Deterministic**: the same result on every run and every machine — seeded
  generators (`TEST_SEED` from `tests/helpers/`), a fixed reference date or fake
  timers instead of the clock, an explicit timezone (`TZ=UTC` or the zone under
  test — CI runs in UTC, developers in KST), no dependence on test order
- **Isolated**: each test sets up and tears down its own state — its own rows,
  users and flags; no shared mutable fixtures, no module-level state carried
  between tests; parallel workers never share a database schema or a port
- Test data is defined in the test or built by factories in `tests/helpers/`;
  obviously fake values only (`example.com` addresses) — never real personal data
  and never production or staging credentials
- Mock at the boundary you do not own (third-party APIs, the clock, the network),
  not the code under test

## Unit tests

- **No network, no database, no filesystem** — business rules, calculations,
  validators and state machines run in memory; an unmocked request fails the test
  (MSW `onUnhandledRequest: 'error'`, `nock.disableNetConnect()`)
- Money is asserted in integer minor units with the rounding rule of the PRD's
  `## Business Rules & Calculations`, including the boundary values

## Integration and contract tests

- Run against a **disposable database** (Testcontainers, a `docker compose`
  service, CI `services:`) that the project's migrations created; never a shared
  or staging database. Reset between tests with the guarded reset helper
- Clean up after themselves — queues drained, servers and connection pools closed
  in teardown
- Contract tests validate the implementation against `docs/api/` (Schemathesis,
  Pact); a contract change and its test change land together

## E2E tests

- **No fixed sleeps** — never `waitForTimeout`, `sleep` or `setTimeout` to wait for
  the product; wait for a condition (Playwright web-first assertions
  `await expect(locator).toBeVisible()`, `waitForResponse`, Maestro
  `extendedWaitUntil`)
- **Stable selectors** — role, label and text locators (`getByRole`,
  `getByLabel`), or a dedicated `data-testid` / accessibility identifier; never CSS
  paths, nth-child or generated class names
- **Seeded data** — each journey creates the data it needs through the API or the
  factories (or uses a dedicated seeded test account), and never depends on what a
  previous test or a human left on the environment
- Critical-journey tests carry the smoke tag (`@smoke`) so `/smoke-check` can run
  them on staging; evidence (traces, screenshots) is retained under
  `production/qa/evidence/<story-slug>/`

## Performance and load tests

- Specify the thresholds (p95 latency, error rate) from `performance.*` and fail
  when they are exceeded; a load test without thresholds is a demo

## Regression tests

- Every bug fix has a regression test that would have caught the original bug —
  and **you must watch it fail before you trust it.** Run the new test against the
  unfixed code, confirm it fails, then apply the fix and confirm it passes. A
  regression test that has only ever been seen passing is not known to test anything.

  > This is `.claude/rules/skill-authoring.md`'s "a gate you have not watched fail
  > is not a gate", applied to tests. It is written out here because stating the
  > *goal* is not enough. A regression test for a double-charge race can use a
  > fixture where two debit requests never overlap — it then passes against the
  > very bug it was written for, and looks authoritative doing it. The fixture,
  > not the assertion, is what makes it useless, and only running it against the
  > unfixed code exposes that.

## Examples

**Correct** (scenario → expected naming, arrange / act / assert, deterministic data):

```ts
import { describe, it, expect } from 'vitest';
import { buildGoal, MIN_TARGET_KRW } from '../../tests/helpers/backend/goals.factory';
import { validateGoal } from './validate-goal';

describe('validateGoal', () => {
  it('rejects a target one won below the minimum', () => {
    // Arrange
    const goal = buildGoal({ targetKrw: MIN_TARGET_KRW - 1 });

    // Act
    const result = validateGoal(goal);

    // Assert
    expect(result).toEqual({ ok: false, error: 'TARGET_BELOW_MINIMUM' });
  });
});
```

**Incorrect**:

```ts
it('test1', async () => {                        // VIOLATION: name says nothing
  const goal = { targetKrw: Math.random() * 1e6 }; // VIOLATION: unseeded, non-deterministic data
  await new Promise((r) => setTimeout(r, 2000));   // VIOLATION: fixed sleep
  expect(validateGoal(goal).ok).toBeTruthy();      // VIOLATION: imprecise assertion
});
```
