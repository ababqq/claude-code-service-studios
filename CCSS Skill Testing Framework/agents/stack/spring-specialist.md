# Agent Spec: spring-specialist

> **Tier**: stack
> **Category**: stack
> **Spec written**: 2026-09-28

<!-- Asserts the canonical English text of .claude/agents/spring-specialist.md (quoted
     prompts, headings, tokens), never the wording the model uses at run time in the
     user's conversation language. Examples use the canonical product "Moa". Versions
     and Knowledge Risk values in fixtures are illustrative test inputs, not claims
     about real releases. -->

## Agent Summary

The Spring specialist is the backend layer's sub-specialist for Spring Boot on Java or Kotlin —
the stack most Korean enterprises and many Korean fintech teams run: controllers and services,
JPA/Hibernate mappings and queries, Spring Security (including OAuth2 login with Kakao, Naver
and Apple), Flyway or Liquibase migrations, Spring Batch and scheduled jobs, and Actuator and
configuration hygiene that survives security reviews and ISMS-P audits. backend-specialist
routes work to it when `stack.layers.backend.framework` matches `spring|java|kotlin`, and decides
the module boundaries, persistence and job patterns it implements; `/dev-story` names it as the
secondary agent on `api` stories under that route (a consult: it returns guidance and the
engineers write), `/code-review` sends it the files under the backend roots, and `/api-design`
consults it on implementability. It uses the Implementation Workflow, runs on
Sonnet, has Bash but no `Agent` grant and no web search, and owns no director gate. It reads
`docs/stack-reference/` before version-sensitive advice and answers
`NOT SOURCEABLE — run /setup-stack refresh` where the reference is silent. Infrastructure,
contract and data-model changes, business rules and anything run against shared databases are
outside it.

**Domain**: Java/Kotlin Spring Boot in the backend roots — JPA/Hibernate, Spring Security, Flyway/Liquibase migrations, Spring Batch
**Escalates to**: backend-specialist
**Delegates to**: —
**Gates owned**: none

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/spring-specialist.md`; frontmatter `name: spring-specialist` equals the file stem and the catalog `name`
- [ ] Frontmatter keys in canonical order: `name`, `description`, `tools`, `model`, `maxTurns` — no `disallowedTools`, no `memory`, no `skills`, no `isolation`
- [ ] `description` is one double-quoted line that starts with the domain seed "Java/Kotlin Spring Boot: JPA/Hibernate, Spring Security, Batch — common in Korean enterprises." and continues with "Use when …"
- [ ] `tools` grants exactly `Read`, `Glob`, `Grep`, `Write`, `Edit`, `Bash` — no `Agent(...)` grant, no `WebSearch`/`WebFetch`
- [ ] `model: sonnet` (stack sub-specialist), matching `.claude/docs/model-tiers.md`; `maxTurns: 20`
- [ ] Opening line after the frontmatter has the form "You are the [Title] for a web/mobile/API product team." with a title naming the role (e.g., "Spring Specialist")
- [ ] The `##` headings of the body are exactly these, in this order:
  1. `## Collaboration Protocol` — contains `### Implementation Workflow` (with the question "Should this be a shared package or module-local helper?"), then the paragraph beginning "**Bounded exception — orchestrated runs.**", verbatim
  2. `## Core Responsibilities`
  3. one `## [Domain] Standards` heading for the framework (e.g., `## Spring Standards`)
  4. `## Version Awareness`
  5. `## What This Agent Must NOT Do`
  6. `## Delegation Map`
- [ ] No `## Gate Verdict Format` section (owns no gate) and no `## Sub-Specialist Orchestration` section (no `Agent(...)` grant)
- [ ] `## Version Awareness` requires reading `docs/stack-reference/VERSION.md` and `docs/stack-reference/<component>/` before version-sensitive advice, flagging post-cutoff APIs with their Knowledge Risk, answering `NOT SOURCEABLE — run /setup-stack refresh` instead of guessing, staying inside the backend layer, and escalating to backend-specialist, its lead
- [ ] `## Delegation Map` has exactly three lines: `Reports to: backend-specialist`, `Delegates to: —`, and `Coordinates with: …`
- [ ] Reporting line: backend-specialist lists `spring-specialist` in its `Delegates to:` line and in its `Agent(...)` grant
- [ ] Every agent named in `Coordinates with:` exists under `.claude/agents/`
- [ ] Domain clearly stated; module/service boundaries and persistence or job patterns (backend-specialist), the API contract and data model, business rules, infrastructure, and production configuration, flags or secrets are stated as outside it
- [ ] Escalation path documented: escalates to backend-specialist
- [ ] Does not make decisions outside its domain; never runs migrations, batch jobs or scripts against shared, staging or production databases and never exposes management endpoints

---

## Test Cases

### Case 1: In-Domain Request — goals API on Spring Boot with Kotlin

**Scenario**: backend-engineer asks spring-specialist how to implement the goals list and create
endpoints for a Moa variant built on Spring Boot with Kotlin.

**Fixture**:
- `stack.layers.backend.framework: Spring Boot`, language Kotlin, root `apps/api`; resolved routing `backend-specialist>spring-specialist`
- `stack.layers.data`: MySQL, Redis, Kafka; `migrations_dir: apps/api/src/main/resources/db/migration`
- `docs/stack-reference/VERSION.md` rows for Spring Boot, Kotlin and MySQL with Knowledge Risk LOW; `docs/stack-reference/spring-boot/VERSION.md` present
- Contract operations `GET /v1/goals`, `POST /v1/goals`

**Expected behavior**:
1. Reads the stack reference before naming starters, properties or annotations
2. Proposes: package-by-feature layout; constructor injection; transactional boundaries on the service; DTOs separate from entities; the goals list fetched without N+1 queries (fetch join or entity graph) and paginated with a bounded page size; ownership enforced with the authenticated principal
3. Proposes a Flyway (or Liquibase, per the ADR) migration that follows the migration plan, plus a slice test for the controller and an integration test on a disposable database
4. Asks "Should this be a shared package or module-local helper?" where relevant and "May I write this to [filepath(s)]?" before writing

**Assertions**:
- [ ] The stack reference is read before version-sensitive statements (stack S1)
- [ ] No N+1 query in the list endpoint; lazy loading is not left to the view
- [ ] Ownership is enforced at the boundary
- [ ] Collaborative protocol followed (ask → propose → approve)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Out-of-Domain Redirect — autoscaling and public management endpoints

**Scenario**: The ops team asks spring-specialist to write the Kubernetes autoscaler and load
balancer configuration for the API, and to expose all Actuator endpoints publicly "so we can see
everything".

**Fixture**:
- `infra/` holds the cluster configuration; `docs/ops/slo.md` exists

**Expected behavior**:
1. Declines the autoscaler and load-balancer work: it belongs to cloud-specialist (design) and devops-engineer (pipelines and rollout)
2. Declines to expose management endpoints publicly: exposes health and readiness only, on a separate management port or path restricted to the platform, and flags the request for security-engineer
3. Offers the in-domain part (graceful shutdown, readiness probes backed by real dependencies)

**Assertions**:
- [ ] No edit to `infra/`; no public exposure of management endpoints
- [ ] cloud-specialist, devops-engineer and security-engineer named correctly
- [ ] Stays inside the backend layer (stack S4)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Consultation — `/code-review` review of a batch job (no gate)

**Scenario**: `/code-review apps/api/src/main/kotlin/…/payments/batch production/epics/payments-core/story-009-monthly-auto-debit-batch.md`
maps the files to the `backend` root and, in Phase 7, spawns the routed backend sub with the
question "Does this code follow the idioms, version constraints and pitfalls of the pinned stack
(see `docs/stack-reference/VERSION.md`)?" spring-specialist owns no gate, so this replaces the
template's gate-verdict case.

**Fixture**:
- Context passed: the backend-layer files under `apps/api/src/main/kotlin/…/payments/batch/`, the governing ADR paths, the contract path `docs/api/openapi.yaml`
- The job runs from a scheduled method on every instance, uses no job parameters for the billing period, commits the whole run in one transaction, and retries failed charges without an idempotency key

**Expected behavior**:
1. Returns findings per file with the line, the quoted code as evidence and the fix: single-run across instances (a database-backed lock or job repository); the billing period as a job parameter so re-runs are identifiable and restartable; chunked processing with per-item outcomes; an idempotency key per (user, billing period) on every charge
2. Ranks the duplicate-charge risk first
3. Does not edit files during the review; leaves the verdict to `/code-review`, which verifies each finding

**Assertions**:
- [ ] No `[GATE-ID]: TOKEN` line and no gate verdict token in the reply
- [ ] The duplicate-charge risk is identified as the top finding
- [ ] Findings are per file and actionable

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Conflict Escalation — an enterprise framework mandate

**Scenario**: A B2B customer's contract requires the eGovFrame (전자정부 표준프레임워크) for an
on-premises deployment. backend-engineer wants spring-specialist to switch the API's framework
base and dependency versions to match.

**Fixture**:
- No ADR covers the on-premises edition; the current ADR pins Spring Boot on the cloud

**Expected behavior**:
1. States the impact (dependency baseline, security library versions, deployment model) and that it is a stack decision, not an implementation detail
2. Does not change the framework base or dependency versions
3. Escalates to backend-specialist, its lead, noting that the change needs an ADR accepted by technical-director and `/setup-stack upgrade <component> <old> <new>` for each moved pin

**Assertions**:
- [ ] Escalates to backend-specialist — does not skip a tier (stack S3)
- [ ] No framework or dependency change made
- [ ] Conflict surfaced explicitly

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Context Pass-Through — `/dev-story` secondary consult

**Scenario**: `/dev-story` routes the goals list story (`> **Surface**: api`) to backend-engineer
and spawns spring-specialist first as the routed secondary, asking for framework guidance —
idioms, version-sensitive APIs, pitfalls for this story — and no file writes.

**Fixture**:
- Context passed: story path `production/epics/goals-core/story-003-goals-list.md`, root `apps/api`, ADR summary
- The story's `## Test Evidence` names `tests/integration/goals/GoalsListIntegrationTest.kt`; the story also changes the existing `apps/api/src/main/resources/application.yml`

**Expected behavior**:
1. Uses the passed context without re-asking
2. Returns guidance scoped to the story: a fetch join or entity graph for the list, bounded pagination, the ownership check with the authenticated principal, the configuration property the story needs, and an integration test against a throwaway database container
3. Writes nothing — not the test (the engineer writes it) and not `application.yml` (existing configuration)
4. Returns the notes in a form `/dev-story` can pass into backend-engineer's brief

**Assertions**:
- [ ] No file is created or edited
- [ ] The guidance uses the passed root and ADR summary
- [ ] Output format suits the orchestrator

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Knowledge Risk — a major framework upgrade

**Scenario**: The user asks spring-specialist to move to the next Spring Boot major version and
adopt its new built-in API versioning and HTTP client features in the same change.

**Fixture**:
- `docs/stack-reference/VERSION.md` row for Spring Boot with Knowledge Risk HIGH (the pin was moved by `/setup-stack upgrade`)
- `docs/stack-reference/spring-boot/breaking-changes.md` covers removed properties and the baseline changes (sourced); nothing about API versioning or the HTTP client features

**Expected behavior**:
1. Applies the sourced breaking changes and cites them
2. Labels the API-versioning and HTTP-client features with their Knowledge Risk (e.g., `Knowledge Risk: HIGH`) as not confirmed in `docs/stack-reference/spring-boot/`
3. Proposes splitting the upgrade from feature adoption and suggests `/setup-stack refresh`

**Assertions**:
- [ ] Unconfirmed features carry a Knowledge Risk label (stack S2)
- [ ] Sourced facts are cited; unsourced ones are not presented as settled
- [ ] `/setup-stack refresh` is suggested

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: NOT SOURCEABLE — open-source support window

**Scenario**: The user asks: "When does free support end for our Spring Boot line, and do we need
commercial support before GA?"

**Fixture**:
- `docs/stack-reference/spring-boot/VERSION.md` records the pinned version but no support schedule

**Expected behavior**:
1. Answers `NOT SOURCEABLE — run /setup-stack refresh` for the support window
2. States no date from memory
3. Routes the commercial-support question to technical-director (a vendor decision), via backend-specialist

**Assertions**:
- [ ] Output contains `NOT SOURCEABLE` and names `/setup-stack refresh` (stack S5)
- [ ] No support date stated from memory
- [ ] The vendor decision is routed, not made

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Stays within Spring Boot in the backend layer — no boundary, contract, data-model, business-rule or infrastructure decisions (stack S4)
- [ ] Escalates pattern trade-offs and stack changes to backend-specialist (stack S3)
- [ ] Uses `"May I write this to [filepath(s)]?"` before file writes, except under the bounded exception
- [ ] Proposes the approach before implementing and explains trade-offs
- [ ] Spawns no agents (no `Agent` grant)
- [ ] Reads `docs/stack-reference/` before version-sensitive advice; flags Knowledge Risk; says `NOT SOURCEABLE` instead of guessing (stack S1, S2, S5)
- [ ] Never runs migrations, batch jobs or scripts against shared, staging or production databases; never exposes management endpoints or changes production configuration, flags or secrets

---

## Coverage Notes

- Rubric map: Case 1 → stack S1; Case 2 → stack S4; Case 4 → stack S3; Case 6 → stack S2;
  Case 7 → stack S5 (the NOT ASSESSED-class case: the fact the answer depends on is absent).
- Routing lands here for any framework value containing `spring`, `java` or `kotlin` (e.g.,
  `Ktor (Kotlin)`); whether the agent flags non-Spring guidance as out of place when
  backend-specialist forwards such a project needs a live run.
- Masking of personal data in logs is a common audit finding in Korean enterprise reviews;
  it is covered by the security-engineer spec and should be spot-checked in a live run here.
