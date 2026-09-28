> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# QL-TEST-COVERAGE — Test Coverage Review

Agent: `qa-lead` | Model tier: inherit | Domain: Test coverage

**Trigger**: Spawned by `/story-done` before a story is closed, and by `/team-qa`
immediately before its sign-off phase. Only these two skills spawn it; phase gates
read the evidence and QA sign-off records it leads to instead. It reviews contract
tests, critical-journey E2E coverage and coverage of the PRD acceptance criteria.

**Context to pass**:
- story path(s) or sprint id
- test file paths
- evidence directory paths
- resolved `testing.strict` and `qa.level` lines

**Prompt**:
> "Review the test coverage and evidence for these stories. Read the stories, the
> test files and the evidence directories at the paths given (for a sprint id, the
> stories listed for that sprint in `production/sprint-status.yaml`). Check:
>
> 1. **Evidence by story type** — per `> **Type**:`
>    - `Logic`: automated unit tests exist and pass.
>    - `Integration`: integration or contract tests against the contract in
>      `docs/api/` exist and pass.
>    - `UI`: component tests and/or retained screenshots of each state touched
>      (desktop and mobile viewport, or device) under
>      `production/qa/evidence/<story-slug>/`.
>    - `E2E`: an automated end-to-end test (Playwright, Cypress, Detox or Maestro)
>      passing against a running environment, with its trace or screenshots retained.
>    - `Config`: a smoke check pass recorded in `production/qa/smoke-YYYY-MM-DD.md`.
> 2. **Contract tests** — every API operation a client uses is covered by a contract
>    test (schema-based or consumer-driven), not only the operations the latest story
>    touched.
> 3. **Critical-journey E2E** — every journey in `docs/ops/slo.md`
>    `## Critical User Journeys` has an E2E test (for Moa: sign up with Kakao →
>    create a goal → authorise automatic debit → see the first deposit).
> 4. **PRD acceptance criteria** — each criterion maps to at least one test or
>    evidence item; the PRD's `## Edge Cases` that matter (a duplicate payment
>    webhook, network loss mid-payment, an expired token) are tested.
> 5. **Migration floor** — a story whose `**Migration**` is not `None` (any type)
>    requires `production/qa/evidence/<story-slug>/migration-dry-run.log`, showing the
>    Expand phase applied and rolled back on a disposable database, at every
>    `qa.level` and regardless of `testing.strict.config`. Absent ⇒ blocking.
> 6. **Evidence is retained** — on disk in the evidence location, never only in
>    gitignored paths such as `production/session-logs/`; each user-observable story
>    carries its `Run result: OBSERVED | NOT VERIFIED | N/A` line.
> 7. **Test quality** — meaningful assertions, deterministic runs, no skipped tests
>    hiding failures; flaky tests quarantined with a tracking bug rather than retried
>    until green.
> 8. **Strictness** — from the resolved lines: `testing.strict.<type>` `true` makes
>    that type's evidence blocking, `false` advisory, unset leaves the default
>    (blocking for Logic, Integration, UI and E2E; advisory for Config); `qa.level`
>    may relax what per-story evidence is expected, but never the migration floor.
>
> Return ADEQUATE (coverage meets the standard), GAPS [specific missing tests or
> evidence, per story], or INADEQUATE [critical logic, a critical journey or a
> migration floor is untested — do not close the story or sign off]."

**Verdicts**: ADEQUATE / GAPS / INADEQUATE

The first line of the reply is exactly `[QL-TEST-COVERAGE]: <TOKEN>` with one token
from the line above; the spawning skill parses it. Findings follow the first line.

**Special handling**:
- When a test run is needed to know whether tests pass and none was run, say so:
  `NOT CHECKED — test results (suite not run)`. Existing test files are not passing
  tests.
- From `/story-done` (one story), items 2 and 3 apply only to the operations and
  journeys the story touches; from `/team-qa` (a sprint), apply them in full.
