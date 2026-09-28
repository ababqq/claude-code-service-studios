# Coding Standards

## Service Code

- **Contract-first.** Every API operation exists in the contract under `docs/api/`
  (`openapi.yaml`, `schema.graphql`, `<service>.proto` or `asyncapi.yaml`) before it
  is implemented. Handlers conform to it — paths, methods, status codes, the error
  model, pagination, field names — and clients are generated from it or tested
  against it. A breaking change goes through `/api-design` (versioning and
  deprecation), never straight into a handler.
- **Typed boundaries.** Validate every input where it crosses into the service —
  request bodies, query strings, webhooks, queue messages, environment variables,
  third-party responses — with a schema (Zod, class-validator, Pydantic, Bean
  Validation or the stack's equivalent). No untyped values (`any`, raw maps) cross a
  module boundary; shared types live in a shared package, not in copies.
- **Configuration and flags are never hardcoded.** Business values — prices, fees,
  limits, quotas, time windows, rounding — come from configuration or the pricing
  model and link to the PRD rule that defines them (`## Business Rules &
  Calculations`). Every feature flag has a key, a recorded default, an owner and a
  removal date (`## Configuration & Flags`); the flag's off state is a working kill
  switch.
- **Secrets never enter the repository.** Keys, tokens and credentials live in the
  environment's secret manager and reach code through typed config; `.env` files
  stay gitignored; fixtures use obviously fake values. A committed secret is
  rotated, not just deleted from the file.
- **No PII in logs.** Structured logs carry a correlation ID and entity IDs, never
  values: no email, phone number, name, account number, resident registration
  number, card data, token or session cookie. Redact at the logger, not at each
  call site.
- **Authorization on every endpoint.** Deny by default. Each operation checks that
  the caller may act on *this* resource, not only that they are signed in — for Moa,
  `GET /goals/{goalId}` compares the goal's owner with the session user, otherwise
  any user reads any goal by guessing IDs. Admin operations check roles; no mass
  assignment of fields such as `ownerId` or `plan`.
- **Resilience at the edges.** Money-moving and webhook handlers are idempotent (a
  payment webhook delivered twice records one deposit); outbound calls have
  timeouts and bounded retries with backoff; list endpoints paginate.
- **Documented, testable public APIs.** Public functions and modules carry doc
  comments; dependencies are injected so every public method is unit-testable.
- **Stay inside the rules.** Follow the governing ADR's `### Implementation
  Guidelines`, the layer rules of `docs/architecture/control-manifest.md` and
  `docs/architecture/tech-radar.md` — nothing from `## Forbidden Patterns`, nothing
  newly introduced from `## Hold`. Naming follows `naming.*` in `project.yaml`.
- **Architecture decisions are recorded as ADRs** in `docs/architecture/`. **How many
  is set by `modes.workflow`** — all ADRs at `full`, *critical* ADRs (Foundation
  layer) only at `standard`, and none required at `minimal`, where the decision log
  and `design/product/one-pager.md` carry the rationale instead. See
  `.claude/docs/workflow-modes.md`.
- **Commits** reference the story or task they implement. Use Conventional Commits —
  `feat:`, `fix:`, `chore:`, `docs:`, `test:`, `refactor:`, `perf:`, `ci:` — with the
  story in the body (e.g. `Story: production/epics/goals-core/story-001-create-goal.md`).
- **Verification-driven development.** Write the test first for domain rules and
  API behaviour; for UI changes, capture each state touched. Compare expected with
  actual output before calling work complete — every implementation has a way to
  prove it works.
- **A typecheck or build is not a run.** Every story that changes something
  user-observable is launched and observed before it closes, and the observation
  is retained in `production/qa/evidence/<story-slug>/` — screenshots for web and
  mobile, a redacted request/response snapshot for an API. Procedure per surface:
  `.claude/docs/run-and-observe.md`. Not waived at `qa.level: minimal` — tests are,
  the look is not.

`<story-slug>` is the story file name without `.md`: the evidence for
`production/epics/goals-core/story-001-create-goal.md` lives in
`production/qa/evidence/story-001-create-goal/`.

## PRD Standards

- One PRD per feature at `design/prd/<feature-slug>.md` (kebab-case, no suffix),
  written from `.claude/docs/templates/prd.md` by `/write-prd`. The feature slug is
  also the `feature_overrides` key, the `TR-<feature-slug>-NNN` prefix and the
  story's `**PRD**:` value. Nothing else lives at depth 1 of `design/prd/`.
- The 11 contract sections, in this order and with this exact heading text:
  1. `## Overview` — what and why, one paragraph
  2. `## Goals & Non-Goals` — goals tied to the brief; an explicit out-of-scope list
  3. `## User Value` — persona, JTBD, user stories, success moment
  4. `## Functional Requirements` — `### Core Rules`, `### User Flows & States`,
     `### Interactions with Other Features`
  5. `## Business Rules & Calculations` — each rule with variables, units, rounding
     and a worked example
  6. `## Edge Cases` — including network loss, partial failure, concurrency, retries
  7. `## Dependencies` — the `| Feature | PRD | Direction | Nature |` table plus
     `### External Services`
  8. `## Non-Functional Requirements` — performance, availability, security &
     privacy, accessibility, localization
  9. `## Configuration & Flags` — flag key, default, owner, removal date; config
     values and limits exposed to operations
  10. `## Success Metrics & Instrumentation` — metrics with baseline and target;
      events appended to `design/product/tracking-plan.md`
  11. `## Acceptance Criteria` — testable Given/When/Then
- **How many are required depends on `modes.workflow`**:
  - `full` — all 11.
  - `standard` — 8: Overview, Goals & Non-Goals, Functional Requirements, Edge
    Cases, Dependencies, Non-Functional Requirements, Success Metrics &
    Instrumentation, Acceptance Criteria; plus Business Rules & Calculations when
    the feature defines any numeric or policy rule (prices, fees, limits, quotas,
    rate limits, eligibility thresholds, time windows, rounding). User Value and
    Configuration & Flags are advisory.
  - `minimal` — no PRD; `design/product/one-pager.md` is the design record.
  - `workflow_overrides.edge_cases: true` forces Edge Cases on a PRD written
    voluntarily at `minimal`; `workflow_overrides.config_flags: true` forces
    Configuration & Flags at `standard`. See `.claude/docs/workflow-modes.md`.
- Never translate or renumber a contract heading — `prd-structure-check.sh`,
  `/prd-review` and the phase gates match on the text.
- Every business rule value links to its source rule or rationale; a number with no
  source is a finding, not a default.

## Testing Standards

### Test Evidence by Story Type

A story is marked Complete only with the evidence its type requires, retained on
disk:

| Story Type | Covers | Required Evidence | Location | Default Gate Level | `testing.strict` key |
|---|---|---|---|---|---|
| **Logic** | domain rules, calculations, validators, state machines | Automated unit test — must pass | per `testing.patterns` (co-located) or `tests/unit/<feature>/` | BLOCKING | `testing.strict.logic` |
| **Integration** | API handler + DB, queue consumers, third-party adapters, **contract tests** against `docs/api/` | Integration or contract test — must pass | `tests/integration/<feature>/`, `tests/contract/<feature>/` (or per `testing.patterns`) | BLOCKING | `testing.strict.integration` |
| **UI** | screens, components, visual states (incl. visual regression) | Component test and/or retained screenshots of each state touched (desktop + mobile viewport, or device) | `production/qa/evidence/<story-slug>/` | BLOCKING | `testing.strict.ui` |
| **E2E** | a critical user journey across UI → API → DB | Automated E2E test (Playwright / Cypress / Detox / Maestro) passing against a running environment, with trace/screenshot | `tests/e2e/<journey>/` + `production/qa/evidence/<story-slug>/` | BLOCKING | `testing.strict.e2e` |
| **Config** | feature flags, env config, pricing/limit tables | Smoke check pass | `production/qa/smoke-YYYY-MM-DD.md` | ADVISORY (`/smoke-check` unset ⇒ BLOCKING, intentional exception kept) | `testing.strict.config` |

**Migration floor.** A story whose `**Migration**` is not `None` (any Type)
requires `production/qa/evidence/<story-slug>/migration-dry-run.log` — the Expand
phase applied and rolled back on a disposable database — **at every `qa.level` and
regardless of `testing.strict.config`**. Absent ⇒ BLOCKING. It is a floor in the
same sense as the smoke report: `qa.level` relaxes per-story evidence, never this.

The **Default Gate Level** applies when `testing.strict` is not set. A project may
override it per story type with the five keys `testing.strict.logic`,
`testing.strict.integration`, `testing.strict.ui`, `testing.strict.e2e` and
`testing.strict.config` — each `true` (BLOCKING) or `false` (ADVISORY), and each
locally overridable in `project.local.yaml`. `/story-done`, `/story-readiness`,
`/dev-story`, `/gate-check` and `/smoke-check` read the resolved values from the
`testing.strict` line of their `resolve_config` block and fall back to the defaults
above for any key it reports as `unset`. `qa.level` is the other axis: it decides
whether evidence is *required* at all; `testing.strict` decides whether a gap
*blocks* once it is.

> **Why UI and E2E block.** "Retained" is load-bearing — the screenshot, trace or
> snapshot must still be on disk in `production/qa/evidence/` when the story is
> closed, and never only in gitignored paths such as `production/session-logs/`.
> One that was captured and discarded is an assertion, not evidence. UI and E2E
> block by default because the rendered screen and the working journey *are* what
> the user gets: an advisory UI gate gets deferred in favour of whatever does block,
> and the result is a well-tested service whose sign-up screen clips on a 390-pixel
> phone.

> **Exception — `/smoke-check`.** The ADVISORY default for **Config** above
> applies to *per-story evidence* gates. `/smoke-check` is a build-health gate,
> not a per-story evidence gate, so its own unset default for
> `testing.strict.config` is **BLOCKING**. This divergence is intentional and is
> documented at both sites; do not reconcile one to the other.

### Automated Test Rules

- **Naming**: test files follow the stack convention recorded in
  `testing.patterns` (`*.test.ts`, `*.spec.ts`, `test_*.py`, `*Test.kt`,
  `*Tests.swift`); test names describe `scenario → expected` (e.g.
  `rejects a goal whose target date is in the past`).
- **Determinism**: the same result on every run — fixed seeds, frozen clocks, no
  `sleep`-based waits (wait on a condition), no dependence on today's date or the
  machine's time zone (Moa computes KST month boundaries; test them with a fixed
  clock).
- **Isolation**: each test sets up and tears down its own state — a transaction
  rolled back per test, a fresh schema or a Testcontainers database; tests never
  depend on execution order or on data another test left behind.
- **No hardcoded data**: fixtures come from factories or constant files, not inline
  magic numbers (exception: boundary-value tests where the exact number is the
  point, such as the KRW 10 rounding edge).
- **Independence**: unit tests do not touch the network, a database or the file
  system — inject the dependency. Integration tests use a disposable database and
  stub third parties at the boundary (payment gateway, KakaoTalk message API, push
  providers) or call their sandbox; no test ever calls a production endpoint.
- **Contract tests** verify the implementation against `docs/api/` (schema-based,
  e.g. Schemathesis, or consumer-driven, e.g. Pact) — one per operation a client
  uses.

### What NOT to Automate

- Pixel-perfect visual fidelity beyond the visual-regression snapshots the stack
  already produces
- Subjective usability and comprehension (usability sessions, `/usability-report`)
- Real payments, real store review and real message delivery in production
  (sandboxes and staging only)
- Exploratory testing of new flows (qa-engineer sessions, recorded as bugs)

### CI/CD Rules

- CI runs `commands.lint`, `commands.typecheck`, `commands.test` and
  `commands.e2e` from `project.yaml` on every push to main and every pull request
  (the workflow `/test-setup` writes, e.g. `.github/workflows/ci.yml`, with a job
  per configured layer). A configured command that CI does not run is a gap, not a
  choice.
- No merge when a required job fails — tests are a blocking gate in CI.
- **Never disable, skip or delete a failing test to make CI pass** — fix the
  underlying issue. A flaky test is quarantined with a tracking bug
  (`/test-flakiness`), never retried until green.
- Migrations run as a dry-run in CI against a disposable database; deploys to
  staging go through the pipeline, never by hand.
- Secret scanning runs on every push; a detected secret fails the build.
- Never edit CI/CD configuration to make a failing check pass.

## Language Policy

**Rule**: everything an AI loads or a script parses is **English**. Documents
primarily read by humans are **Korean**.

**Korean-language files (the complete list — 15):**

| File | Why Korean |
|---|---|
| `README.md` | human landing page |
| `CHANGELOG.md` | human release history of the framework |
| `UPGRADING.md` | human upgrade guide |
| `CONTRIBUTING.md` | human contribution guide |
| `SECURITY.md` | human vulnerability-report policy |
| `docs/WORKFLOW-GUIDE.md` | human walkthrough |
| `docs/skill-flow-diagrams.md` | human diagrams |
| `.claude/docs/quick-start.md` | human onboarding |
| `.claude/docs/setup-requirements.md` | install prerequisites for humans; no skill, hook or script loads it |
| `.claude/docs/agent-roster.md` | cited only by human docs; no skill, hook or script loads it |
| `.claude/docs/skills-reference.md` | cited only by human docs |
| `.claude/docs/rules-reference.md` | cited only by human docs |
| `.github/PULL_REQUEST_TEMPLATE.md` | human form |
| `.github/ISSUE_TEMPLATE/bug_report.md` | human form |
| `.github/ISSUE_TEMPLATE/feature_request.md` | human form |

Everything else is English, including the borderline files an AI loads or a script
parses: `.claude/docs/hooks-reference.md` and `.claude/docs/hooks-reference/*.md`,
`.claude/docs/model-tiers.md`, `.claude/docs/compliance/*.md`,
`docs/COLLABORATIVE-DESIGN-PRINCIPLE.md`, every `CLAUDE.md`, every file of the
`CCSS Skill Testing Framework/`, `LICENSE`, all templates, all agents, skills,
rules, hooks and scripts and their messages, and the comments in `project.yaml`.
Inside the Korean files, identifiers — skill names, paths, keys, enum values,
verdict tokens, agent names — stay in English exactly as spelled, commands stay in
code font, and prose uses 합니다체.

**Artifacts skills write at project run time** (PRDs, ADRs, UX specs, reports,
stories, checklists):

1. **Machine-contract text stays English, exactly as the template spells it**:
   every `#`/`##`/`###` heading that comes from a template or is matched by a script
   or grep; bold field labels used as keys (`**Status**`, `**Depends On**`,
   `**Surface**`, `> **Type**:`, `> **Verdict**:`); verdict, severity and status
   tokens (`PASS`, `NOT ASSESSED`, `S1-Critical`, `SEV2`, `in-progress`,
   `Approved`); YAML keys and enum values; file names and paths;
   `TR-`/`ADR-`/`BUG-`/`INC-` IDs; the `Run result:` line.
2. **Body text is written in the user's conversation language** (the language of
   the user's most recent substantive messages): paragraphs, bullet content, table
   cell prose, rationale, user stories, copy drafts.
3. **Never translate a heading "for readability"** — scripts and gates stop
   finding it.
4. **Customer-facing copy** (release notes, store text, microcopy) is written in
   the locale(s) it ships in (`localization.locales`), regardless of the
   conversation language.
5. **Conversation**: skills and agents talk to the user in the user's conversation
   language. Quoted phrases in skill and agent files ("May I write this to …?",
   AskUserQuestion option labels) are canonical English forms that the model
   renders in the conversation language.
