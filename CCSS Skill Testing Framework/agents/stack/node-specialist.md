# Agent Spec: node-specialist

> **Tier**: stack
> **Category**: stack
> **Spec written**: 2026-09-28

<!-- Asserts the canonical English text of .claude/agents/node-specialist.md (quoted
     prompts, headings, tokens), never the wording the model uses at run time in the
     user's conversation language. Examples use the canonical product "Moa". Versions
     and Knowledge Risk values in fixtures are illustrative test inputs, not claims
     about real releases. -->

## Agent Summary

The Node.js specialist is the backend layer's sub-specialist for Node.js and TypeScript
backends: NestJS, Express, Fastify (and Hono), data access with Prisma, TypeORM or Drizzle,
queue workers and scheduled jobs, and Node.js runtime behaviour (event loop health, timeouts,
graceful shutdown). backend-specialist routes work to it when `stack.layers.backend.framework`
matches `nest|express|fastify|hono|node`, and decides the module boundaries, persistence and job
patterns it implements; `/dev-story` names it as the secondary agent on `api` stories (and ML
stories) under that route (a consult: it returns guidance and the engineers write),
`/code-review` sends it the files under the backend roots, and `/api-design` consults it on
implementability. It uses the
Implementation Workflow, runs on Sonnet, has Bash but no `Agent` grant and no web search, and
owns no director gate. It reads `docs/stack-reference/` before version-sensitive advice and
answers `NOT SOURCEABLE — run /setup-stack refresh` where the reference is silent. Contract and
data-model changes, business rules and anything run against shared databases are outside it.

**Domain**: Node.js/TypeScript backends in the backend roots (Moa: `apps/api`, `services/worker`) — NestJS, Express, Fastify; Prisma / TypeORM / Drizzle; queue workers
**Escalates to**: backend-specialist
**Delegates to**: —
**Gates owned**: none

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/node-specialist.md`; frontmatter `name: node-specialist` equals the file stem and the catalog `name`
- [ ] Frontmatter keys in canonical order: `name`, `description`, `tools`, `model`, `maxTurns` — no `disallowedTools`, no `memory`, no `skills`, no `isolation`
- [ ] `description` is one double-quoted line that starts with the domain seed "Node.js/TypeScript backends: NestJS, Express, Fastify; Prisma / TypeORM / Drizzle." and continues with "Use when …"
- [ ] `tools` grants exactly `Read`, `Glob`, `Grep`, `Write`, `Edit`, `Bash` — no `Agent(...)` grant, no `WebSearch`/`WebFetch`
- [ ] `model: sonnet` (stack sub-specialist), matching `.claude/docs/model-tiers.md`; `maxTurns: 20`
- [ ] Opening line after the frontmatter has the form "You are the [Title] for a web/mobile/API product team." with a title naming the role (e.g., "Node.js Specialist")
- [ ] The `##` headings of the body are exactly these, in this order:
  1. `## Collaboration Protocol` — contains `### Implementation Workflow` (with the question "Should this be a shared package or module-local helper?"), then the paragraph beginning "**Bounded exception — orchestrated runs.**", verbatim
  2. `## Core Responsibilities`
  3. one `## [Domain] Standards` heading for the runtime (e.g., `## Node.js Standards`)
  4. `## Version Awareness`
  5. `## What This Agent Must NOT Do`
  6. `## Delegation Map`
- [ ] No `## Gate Verdict Format` section (owns no gate) and no `## Sub-Specialist Orchestration` section (no `Agent(...)` grant)
- [ ] `## Version Awareness` requires reading `docs/stack-reference/VERSION.md` and `docs/stack-reference/<component>/` before version-sensitive advice, flagging post-cutoff APIs with their Knowledge Risk, answering `NOT SOURCEABLE — run /setup-stack refresh` instead of guessing, staying inside the backend layer, and escalating to backend-specialist, its lead
- [ ] `## Delegation Map` has exactly three lines: `Reports to: backend-specialist`, `Delegates to: —`, and `Coordinates with: …`
- [ ] Reporting line: backend-specialist lists `node-specialist` in its `Delegates to:` line and in its `Agent(...)` grant
- [ ] Every agent named in `Coordinates with:` exists under `.claude/agents/`
- [ ] Domain clearly stated; module/service boundaries and persistence or job patterns (backend-specialist), the API contract and data model (`/api-design`, `/data-model`), business rules, and production configuration, flags or secrets are stated as outside it
- [ ] Escalation path documented: escalates to backend-specialist
- [ ] Does not make decisions outside its domain; never runs migrations or scripts against shared, staging or production databases

---

## Test Cases

### Case 1: In-Domain Request — `POST /v1/goals` in NestJS with Prisma

**Scenario**: backend-engineer asks node-specialist how to implement the create-goal endpoint for
`production/epics/goals-core/story-001-create-goal.md`.

**Fixture**:
- Story: `> **Surface**: api, web`, `**API Contract**: docs/api/openapi.yaml#/paths/~1v1~1goals/post`, `**Requirement**: TR-goals-001`
- Resolved routing `backend-specialist>node-specialist`; roots `apps/api`, `services/worker`
- `docs/stack-reference/VERSION.md` rows `| backend | NestJS | 11.0 | LOW | … |`, `| data | Prisma | 6 | LOW | … |`; component folders `nestjs/` and `prisma/` present
- ADR `docs/architecture/adr-0001-identity-and-auth.md` Accepted

**Expected behavior**:
1. Reads the story, `design/prd/goals.md`, the contract, the ADR and the stack reference before choosing APIs
2. Asks "Should this be a shared package or module-local helper?" where relevant (the KRW amount validator: module-local unless another module needs it)
3. Proposes: a controller with request validation matching the contract schema; the authenticated user taken from the session guard, never from the request body; a service enforcing the goal limit from the PRD; a repository using the ORM with the user scope in every query; errors in the contract's error model
4. Proposes unit tests for the limit rule and an integration test against a disposable database
5. Asks "May I write this to [filepath(s)]?" before writing

**Assertions**:
- [ ] The stack reference is read before version-sensitive statements (stack S1)
- [ ] Ownership is enforced at the boundary (no BOLA/IDOR path)
- [ ] Business limits come from the PRD, not invented
- [ ] Collaborative protocol followed (ask → propose → approve)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Out-of-Domain Redirect — a business rule and a shared database

**Scenario**: The user asks node-specialist to change the maximum number of active goals for Free
users from 3 to 5 "directly in the service" and to run `prisma migrate deploy` against staging
so QA can test today.

**Fixture**:
- `design/prd/subscription.md` defines the Free-plan goal limit
- Staging database credentials are available in the developer's shell

**Expected behavior**:
1. Declines the limit change: business rules belong to the PRD and business-analyst; the code follows the PRD (or the configuration key the PRD names)
2. Declines to run the migration against staging: it gives the exact command, expected output and rollback for a human to run
3. Routes both through backend-specialist, its lead, where a decision is needed

**Assertions**:
- [ ] No business-rule change and no command run against a shared database
- [ ] business-analyst / PRD named for the rule; a human named for the staging run
- [ ] Stays inside its domain (stack S4)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Consultation — `/api-design` implementability review (no gate)

**Scenario**: `/api-design new`, Phase 3 (Resource Modelling), consults the routed backend sub on
the goals operation table before the user approves it, in parallel with tech-lead.
node-specialist owns no gate (SE-SECURITY-REVIEW belongs to security-engineer), so this replaces
the template's gate-verdict case.

**Fixture**:
- Context passed: the goals operation table (`listGoals` `GET /v1/goals` with `cursor`/`limit`; `createGoal` `POST /v1/goals` with `Idempotency-Key` required; `createDeposit` `POST /v1/goals/{goalId}/deposits` with `Idempotency-Key` required), `docs/api/api-guidelines.md`, the pinned NestJS and Prisma rows
- No decision yet on contract-first code generation versus code-first with a CI diff

**Expected behavior**:
1. Uses the passed context instead of asking for it again
2. Answers how the handlers stay honest to the contract in NestJS — contract-first generation or code-first with a CI diff against the contract — and which validation approach fits (global `ValidationPipe` or schema pipes)
3. Returns findings per operation on what the framework and ORM make awkward: a stable unique sort key for cursor pagination with Prisma; where idempotency keys and replayed responses are stored, and their retention
4. Consults `docs/stack-reference/nestjs/` and `docs/stack-reference/prisma/` for version-specific answers, and leaves the table and contract edits to the skill; disagreements with tech-lead are returned, not resolved

**Assertions**:
- [ ] No `[GATE-ID]: TOKEN` line and no gate verdict token in the reply
- [ ] Findings are per operation and actionable
- [ ] The contract file is not edited by the agent

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Conflict Escalation — splitting `payments` into a service

**Scenario**: backend-engineer wants node-specialist to extract `payments` into a separately
deployed microservice now, "to scale it independently". backend-specialist's architecture keeps a
modular monolith until an ADR says otherwise.

**Fixture**:
- `docs/architecture/architecture.md`: modular monolith; no ADR for a service split

**Expected behavior**:
1. Explains the costs (distributed transactions, a second deploy pipeline, network failure modes) and what the module boundary already gives
2. Does not change service boundaries
3. Escalates to backend-specialist, its lead; a split needs an ADR accepted by technical-director

**Assertions**:
- [ ] Escalates to backend-specialist — does not skip a tier (stack S3)
- [ ] No service extraction started
- [ ] Conflict surfaced explicitly

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Context Pass-Through — `/dev-story` secondary consult on a migration story

**Scenario**: `/dev-story` routes an `api` story that carries a migration to backend-engineer and
spawns node-specialist first as the routed secondary, asking for framework guidance — idioms,
version-sensitive APIs, pitfalls for this story — and no file writes.

**Fixture**:
- Context passed: story path `production/epics/goals-core/story-006-goal-paused-at.md` (`> **Surface**: api`, `**Migration**: docs/data/migrations/0006-goal-paused-at.md`, Expand phase), root `apps/api`, ADR summary
- Migrations dir `apps/api/prisma/migrations`; the story also changes the existing `apps/api/src/goals/goals.service.ts` and its `## Test Evidence` names `tests/integration/goals/goal-paused-at.test.ts`

**Expected behavior**:
1. Uses the passed context without re-asking
2. Returns guidance scoped to the story: generating the Expand migration with the ORM and reviewing its SQL (reviewed as SQL by data-specialist), backward compatibility with the running application version, the service change, and an integration test against a disposable database
3. Writes nothing and runs nothing against any database — the migration, the service change and the test are the engineer's, and a dry run belongs to a disposable local database only
4. Returns the notes in a form `/dev-story` can pass into backend-engineer's brief

**Assertions**:
- [ ] No file is created or edited
- [ ] No command is run against a shared database
- [ ] Output format suits the orchestrator

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Knowledge Risk — a new ORM client generator

**Scenario**: The user asks node-specialist to switch the ORM to its newer client generator and
driver adapters "for faster cold starts".

**Fixture**:
- `docs/stack-reference/VERSION.md` row `| data | Prisma | 6 | HIGH | <source url> | 2026-09-27 |`
- `docs/stack-reference/prisma/breaking-changes.md` covers the generator output location change (sourced); nothing about driver adapters or cold-start effects

**Expected behavior**:
1. Applies the sourced generator change and cites it
2. Labels the driver-adapter configuration and the performance claim with their Knowledge Risk (e.g., `Knowledge Risk: HIGH`) as not confirmed in `docs/stack-reference/prisma/`
3. Proposes a measured spike (cold start and p95 before and after) and suggests `/setup-stack refresh`

**Assertions**:
- [ ] Unconfirmed configuration and claims carry a Knowledge Risk label (stack S2)
- [ ] Sourced facts are cited; unsourced ones are not presented as settled
- [ ] A measurement is proposed instead of an assumed benefit

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: NOT SOURCEABLE — a runtime module-loading behaviour

**Scenario**: The user asks: "Can we `require()` ES modules without a flag on our pinned Node.js,
so we can drop the dual build of `packages/api-client`?"

**Fixture**:
- `docs/stack-reference/VERSION.md` row `| backend | Node.js | NOT DETERMINED — accepted by user 2026-09-27 | HIGH | — | — |`
- No `docs/stack-reference/nodejs/` folder

**Expected behavior**:
1. Answers `NOT SOURCEABLE — run /setup-stack refresh`
2. States no runtime behaviour from memory; may run `node --version` locally and report it as an observation, not as the pin
3. Keeps the dual build until the behaviour is sourced

**Assertions**:
- [ ] Output contains `NOT SOURCEABLE` and names `/setup-stack refresh` (stack S5)
- [ ] No runtime capability stated from memory
- [ ] Observed versions are labelled as observations

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Stays within Node.js/TypeScript in the backend layer — no boundary, contract, data-model, business-rule or infrastructure decisions (stack S4)
- [ ] Escalates pattern trade-offs and cross-layer questions to backend-specialist (stack S3)
- [ ] Uses `"May I write this to [filepath(s)]?"` before file writes, except under the bounded exception
- [ ] Proposes the approach before implementing and explains trade-offs
- [ ] Spawns no agents (no `Agent` grant)
- [ ] Reads `docs/stack-reference/` before version-sensitive advice; flags Knowledge Risk; says `NOT SOURCEABLE` instead of guessing (stack S1, S2, S5)
- [ ] Never runs migrations or scripts against shared, staging or production databases; never changes production configuration, flags or secrets

---

## Coverage Notes

- Rubric map: Case 1 → stack S1; Case 2 → stack S4; Case 4 → stack S3; Case 6 → stack S2;
  Case 7 → stack S5 (the NOT ASSESSED-class case: the reference the answer depends on is absent).
- Queue workers (idempotent consumers, graceful shutdown) are covered by the backend-specialist
  and data-specialist specs; a live run on `services/worker` is the stronger test here.
- The migration floor (`migration-dry-run.log` at every `qa.level`) is enforced by `/story-done`;
  `/dev-story` asks before retaining it. This spec checks only that the agent's guidance keeps any dry run
  on a disposable database.
- A `Config` story with a migration routes to backend-engineer with data-specialist, not to
  this agent; Case 5 therefore uses an `api` story.
