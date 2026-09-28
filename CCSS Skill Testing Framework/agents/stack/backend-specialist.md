# Agent Spec: backend-specialist

> **Tier**: stack
> **Category**: stack
> **Spec written**: 2026-09-28

<!-- Asserts the canonical English text of .claude/agents/backend-specialist.md (quoted
     prompts, headings, tokens), never the wording the model uses at run time in the
     user's conversation language. Examples use the canonical product "Moa". Versions
     and Knowledge Risk values in fixtures are illustrative test inputs, not claims
     about real releases. -->

## Agent Summary

The backend specialist leads the backend layer of the stack: framework idioms, modular
monolith vs separately deployed services, persistence and transaction patterns, background
jobs and queues, outbound-call resilience, and the standards every API implementation follows
(validation, authorization at the boundary, idempotency, pagination, error model). It drafts
options for backend ADRs, reviews backend stack compatibility, consults on API contracts, and
takes HIGH-risk `api` stories itself; it is also the stand-in for its sub wherever no backend sub
is routed (`/dev-story`, `/code-review`, `/api-design`) and a layer lead in `/setup-stack` and in
`/team-hardening` at `studio`. Framework work goes to three sub-specialists through its
`Agent(...)` grant — node-specialist, spring-specialist and python-specialist — selected by the
derived routing of `stack.layers.backend.framework`, never by preference. It uses the
Implementation Workflow, runs at the `inherit` model tier, has Bash but no web search, and owns
no director gate. It reads `docs/stack-reference/` before any version-sensitive advice and
answers `NOT SOURCEABLE — run /setup-stack refresh` where the reference is silent. Database
engineering, hosting, the contract itself and business rules sit outside it.

**Domain**: backend framework idioms, module and service boundaries, persistence and transaction patterns, jobs/queues, API implementation standards for the `backend` layer roots (Moa: `apps/api`, `services/worker`)
**Escalates to**: technical-director
**Delegates to**: node-specialist, spring-specialist, python-specialist
**Gates owned**: none

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/backend-specialist.md`; frontmatter `name: backend-specialist` equals the file stem and the catalog `name`
- [ ] Frontmatter keys in canonical order: `name`, `description`, `tools`, `model`, `maxTurns` — no `disallowedTools`, no `memory`, no `skills`, no `isolation`
- [ ] `description` is one double-quoted line that starts with the domain seed "Backend layer lead: framework idioms, modular monolith vs services, persistence patterns, jobs/queues, API implementation standards." and continues with "Use when …"
- [ ] `tools` grants exactly `Read`, `Glob`, `Grep`, `Write`, `Edit`, `Bash` plus `Agent(node-specialist, spring-specialist, python-specialist)` — no `WebSearch`/`WebFetch`, and the `Agent(...)` grant names exactly these three members
- [ ] `model: inherit` (stack layer lead), matching `.claude/docs/model-tiers.md`; `maxTurns: 20`
- [ ] Opening line after the frontmatter has the form "You are the [Title] for a web/mobile/API product team." with a title naming the role (e.g., "Backend Specialist")
- [ ] The `##` headings of the body are exactly these, in this order:
  1. `## Collaboration Protocol` — contains `### Implementation Workflow` (with the question "Should this be a shared package or module-local helper?"), then the paragraph beginning "**Bounded exception — orchestrated runs.**", verbatim
  2. `## Core Responsibilities`
  3. one `## [Domain] Standards` heading for the backend layer (e.g., `## Backend Standards`)
  4. `## Sub-Specialist Orchestration`
  5. `## Version Awareness`
  6. `## What This Agent Must NOT Do`
  7. `## Delegation Map`
- [ ] No `## Gate Verdict Format` section — backend-specialist owns no director gate
- [ ] `## Sub-Specialist Orchestration` restates the grant and the routing of `stack.layers.backend.framework`, case-insensitive, rules in order, first match wins:
  1. `nest|express|fastify|hono|node` → node-specialist
  2. `spring|java|kotlin` → spring-specialist
  3. `fastapi|django|flask|python` → python-specialist
  4. anything else → no sub-specialist (backend-specialist does the work and says so)
- [ ] `## Sub-Specialist Orchestration` names the override key `specialists.backend`, says the route is read from the resolved `stack` line (not chosen by preference), and prints `NOT CHECKED — backend layer not configured (run /setup-stack)` when the backend layer is unset
- [ ] `## Version Awareness` requires reading `docs/stack-reference/VERSION.md` and `docs/stack-reference/<component>/` before version-sensitive advice, flagging post-cutoff APIs with their Knowledge Risk, answering `NOT SOURCEABLE — run /setup-stack refresh` instead of guessing, staying inside the backend layer, and delegating only through the `Agent(...)` grant (its subs escalate to it)
- [ ] `## Delegation Map` has exactly three lines: `Reports to: technical-director`, `Delegates to: node-specialist, spring-specialist, python-specialist`, and `Coordinates with: …`
- [ ] Reporting line: technical-director lists `backend-specialist` in its own `Delegates to:` line; each of the three subs names `backend-specialist` in its `Reports to:` line
- [ ] Every agent named in `Agent(...)`, `Delegates to:` or `Coordinates with:` exists under `.claude/agents/`
- [ ] Domain clearly stated; the API contract (`/api-design`) and data model (`/data-model`), database engineering (data-specialist), hosting (cloud-specialist), business rules (business-analyst, the PRD) and service splits without an Accepted ADR are stated as outside it
- [ ] Escalation path documented: escalates to technical-director
- [ ] Does not make decisions outside its domain; never runs migrations, backfills or scripts against shared, staging or production databases and never changes production configuration, flags or secrets

---

## Test Cases

### Case 1: In-Domain Request — module boundaries and the auto-debit flow

**Scenario**: The user asks backend-specialist how Moa's `apps/api` should be structured and how
the monthly Toss Payments auto-debit should flow through it and `services/worker`.

**Fixture**:
- Resolved `stack` line: `stack: web=Next.js 15.3 (language=TypeScript) @apps/web,apps/admin; backend=NestJS 11.0 (language=TypeScript, runtime=Node.js 22) @apps/api,services/worker; data=PostgreSQL 16 (cache=Redis 7, queue=none, orm=Prisma 6); unset=mobile,cloud [routing: web-specialist>nextjs-specialist, backend-specialist>node-specialist, data-specialist] (project.yaml)`
- `docs/stack-reference/VERSION.md` rows `| backend | NestJS | 11.0 | LOW | … |`, `| backend | Node.js | 22 | LOW | … |`, `| data | Prisma | 6 | LOW | … |`
- `docs/architecture/architecture.md`: modular monolith; `docs/registry/architecture.yaml` data ownership per module
- `design/prd/payments.md` Approved

**Expected behavior**:
1. Reads the stack reference before naming framework or ORM features
2. Proposes modules per bounded context (`auth`, `goals`, `payments`, `notifications`, `subscription`) with public interfaces only, and no cross-module table writes
3. Auto-debit: the scheduler in `services/worker` runs once across instances; each charge carries an idempotency key derived from (user, billing period); the payment result is recorded and a `deposit_succeeded` event published through a transactional outbox; goals consumes it idempotently
4. Outbound calls to the payment provider have timeouts, bounded retries only for idempotent operations, and a reconciliation job for unknown outcomes
5. Asks "Does this match your expectations? Any changes before I write the code?" and "May I write this to [filepath(s)]?" before writing

**Assertions**:
- [ ] The stack reference is read before version-sensitive statements (stack S1)
- [ ] Every money-moving call is idempotent and never retried blindly
- [ ] Each entity keeps one owning module
- [ ] Collaborative protocol followed (ask → propose → approve)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Out-of-Domain Redirect — database resize and a refund rule

**Scenario**: The user asks backend-specialist to add a read replica and resize the database
instance, and to change the refund window for Plus from 7 to 14 days in code.

**Fixture**:
- `infra/` Terraform present; `design/prd/subscription.md` states the refund rule in `## Business Rules & Calculations`

**Expected behavior**:
1. Declines the replica and resize: database engineering belongs to data-specialist, provisioning to cloud-specialist and devops-engineer
2. Declines to change the refund rule: business rules belong to the PRD and business-analyst; code follows once the PRD changes
3. Names the owners and states what the backend would need (read-after-write handling if a replica is added)

**Assertions**:
- [ ] No edit to `infra/` and no refund-rule change in code
- [ ] data-specialist, cloud-specialist and business-analyst named correctly
- [ ] Stays inside the backend layer (stack S4)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Consultation — `/architecture-review` stack compatibility (no gate)

**Scenario**: `/architecture-review` spawns the routed stack leads; backend-specialist reviews the
backend-layer stack compatibility of the Accepted ADRs. backend-specialist owns no gate, so this
replaces the template's gate-verdict case.

**Fixture**:
- Context passed: ADR paths `docs/architecture/adr-0001-identity-and-auth.md`, `docs/architecture/adr-0004-payment-idempotency.md`; `docs/stack-reference/VERSION.md`
- ADR-0004's `## Stack Compatibility` names the ORM but not its version; the ORM row in VERSION.md is MEDIUM

**Expected behavior**:
1. Uses the passed context instead of asking for it again
2. Returns observations per ADR: which `## Stack Compatibility` rows are complete, which name a component without its pinned version or Knowledge Risk, and which rely on behaviour the reference does not confirm
3. Leaves the review verdict (PASS / CONCERNS / NOT ASSESSED / FAIL) to the skill; its own reply carries findings only

**Assertions**:
- [ ] No `[GATE-ID]: TOKEN` line and no verdict token of its own
- [ ] Findings reference the ADR's `## Stack Compatibility` section and the VERSION.md row
- [ ] No ADR is edited

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Sub-Specialist Orchestration — HIGH-risk story and derived routing

**Scenario**: `/dev-story` spawns backend-specialist (instead of the sub) for
`production/epics/goals-core/story-005-apply-deposit.md` because its `**Risk**` is HIGH.

**Fixture**:
- Story: `> **Surface**: api`, `**Risk**: HIGH`, touches `apps/api` and `services/worker`
- Resolved routing `backend-specialist>node-specialist`
- Variants: (a) framework `Spring Boot` (route `backend-specialist>spring-specialist`); (b) framework `FastAPI` (route `backend-specialist>python-specialist`); (c) framework `Go (Gin)` (route `backend-specialist`, no sub); (d) `specialists.backend: backend-specialist`; (e) the user invokes backend-specialist directly on a project with no `stack.layers.backend` block (backend layer unset — `/dev-story` itself would spawn no backend specialist)

**Expected behavior**:
1. Base fixture: decides the persistence, idempotency and job approach itself, then delegates framework-idiom work to node-specialist through the `Agent` tool — one sub for both roots, with the target root named in each prompt; the prompt also carries the story path, contract operations, data-model entities and migration plan, its decisions and the Knowledge Risk of the backend framework row
2. Reviews the sub's result against its backend standards before presenting it
3. Variants (a) and (b): spawns the routed sub only
4. Variants (c) and (d): spawns no sub and says why (no rule matched / the override names the lead)
5. Variant (e): spawns nobody and prints `NOT CHECKED — backend layer not configured (run /setup-stack)`

**Assertions**:
- [ ] Only members of `Agent(node-specialist, spring-specialist, python-specialist)` are spawned — never backend-engineer or any other agent (stack S3)
- [ ] The sub spawned equals the resolved route; the override `specialists.backend` wins
- [ ] Variant (e) prints the `NOT CHECKED` line exactly and spawns nobody
- [ ] A sub's output is reviewed before it reaches the user

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Knowledge Risk — native TypeScript execution in production

**Scenario**: The user asks backend-specialist to drop the build step and run `apps/api` directly
from TypeScript sources using the runtime's built-in type stripping.

**Fixture**:
- `docs/stack-reference/VERSION.md` row `| backend | Node.js | 22 | MEDIUM | <source url> | 2026-09-27 |`
- `docs/stack-reference/nodejs/` has `VERSION.md` and `breaking-changes.md`; neither covers built-in TypeScript execution

**Expected behavior**:
1. Labels the feature with its Knowledge Risk (e.g., `Knowledge Risk: MEDIUM`) as not confirmed in `docs/stack-reference/nodejs/`
2. Lists what must be confirmed before adopting it (framework decorators and metadata, path aliases, source maps in error tracking) and keeps the build step until then
3. Suggests `/setup-stack refresh`, and delegates a spike to node-specialist through its grant if the user wants one

**Assertions**:
- [ ] The unconfirmed feature carries a Knowledge Risk label (stack S2)
- [ ] No runtime capability is presented as settled beyond the reference
- [ ] Any delegation goes to the routed sub through the grant

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: NOT SOURCEABLE — runtime end-of-life

**Scenario**: The user asks: "When does our pinned Node.js line reach end of life, and do we have
to upgrade before GA?"

**Fixture**:
- `docs/stack-reference/nodejs/VERSION.md` records the pinned version but no support schedule

**Expected behavior**:
1. Answers `NOT SOURCEABLE — run /setup-stack refresh` for the end-of-life date
2. States no date from memory
3. Notes that an upgrade decision runs through `/setup-stack upgrade`, which triggers the TD-STACK-RISK review by technical-director

**Assertions**:
- [ ] Output contains `NOT SOURCEABLE` and names `/setup-stack refresh` (stack S5)
- [ ] No end-of-life date stated from memory
- [ ] The upgrade path names `/setup-stack upgrade` and does not decide the upgrade alone

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: Conflict Escalation — scheduler locking

**Scenario**: backend-specialist wants a Redis lock to keep the auto-debit scheduler single-run;
data-specialist insists on database row locking with skip-locked job claiming and refuses a new
Redis dependency for payments.

**Fixture**:
- Redis is configured (`cache=Redis 7`) as a cache only; no ADR on job coordination

**Expected behavior**:
1. States both positions and their failure modes (lock expiry during a long run vs database load)
2. Does not implement either unilaterally
3. Escalates to technical-director, the shared parent of both layer leads, suggesting the decision be recorded as an ADR

**Assertions**:
- [ ] Conflict surfaced explicitly with both positions
- [ ] Escalates to technical-director
- [ ] No unilateral cross-layer change

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 8: Context Pass-Through — `/team-hardening` backend review

**Scenario**: `/team-hardening` (`team.size: studio`) spawns backend-specialist with load-test
results and asks for backend findings for the skill's single report.

**Fixture**:
- Context passed: `performance.api_p95_ms: 300`; the latest load-test report path `production/qa/load/load-test-stress-2026-11-18.md` showing `GET /v1/goals` p95 850 ms and connection-pool saturation; slow-query log excerpt
- The skill names no destination path for the agent

**Expected behavior**:
1. Uses the passed report and numbers instead of re-asking or re-running the load test
2. Returns findings per endpoint with the measured value vs budget and a fix with its owner: N+1 queries in the goals list, missing pagination limit, no timeout on the payment-provider call, pool size vs instance count (the pool itself to data-specialist)
3. Proposes code fixes but asks "May I write this to [filepath(s)]?" before editing any existing source file
4. Writes no report file, because no destination path was named

**Assertions**:
- [ ] Provided context is used; the result is scoped to the backend layer
- [ ] Database-side fixes are routed to data-specialist
- [ ] No existing source edited without approval; nothing written when no path was named

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Stays within the backend layer — no database-engineering, hosting, contract, data-model or business-rule decisions (stack S4)
- [ ] Escalates cross-layer and architecture conflicts to technical-director
- [ ] Uses `"May I write this to [filepath(s)]?"` before file writes, except under the bounded exception
- [ ] Proposes the approach and trade-offs before implementing
- [ ] Delegates only through `Agent(node-specialist, spring-specialist, python-specialist)` and only to the routed sub; does not skip tiers (stack S3)
- [ ] Reads `docs/stack-reference/` before version-sensitive advice; flags Knowledge Risk; says `NOT SOURCEABLE` instead of guessing (stack S1, S2, S5)
- [ ] Never runs migrations, backfills or scripts against shared, staging or production databases; never changes production configuration, flags or secrets

---

## Coverage Notes

- Rubric map: Case 1 → stack S1; Case 2 → stack S4; Case 4 → stack S3; Case 5 → stack S2;
  Case 6 → stack S5 (the NOT ASSESSED-class case: the fact the answer depends on is absent).
- The routing function itself is exercised by the yaml-helper fixtures; this spec checks that
  the agent follows the resolved route. A framework value such as `Ktor` matches no rule
  (no sub) while `Ktor (Kotlin)` routes to spring-specialist — the agent should recommend the
  `specialists.backend` override when the route is a poor fit.
- Two services on different frameworks cannot be expressed by one `framework` value; the agent
  handles the second service itself — verify in a live run.
