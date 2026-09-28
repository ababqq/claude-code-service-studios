# Agent Spec: backend-engineer

> **Tier**: specialists
> **Category**: specialist
> **Spec written**: 2026-09-28

<!-- Asserts the canonical English text of .claude/agents/backend-engineer.md (quoted prompts,
     headings, verdict tokens), never the wording the model uses at run time in the user's
     conversation language. Examples use the canonical product "Moa". -->

## Agent Summary

The backend engineer turns PRD functional requirements, business rules and the API
contract into server-side code: domain logic, REST/GraphQL handlers, persistence and
expand/contract migrations, background jobs and webhooks, idempotent payment flows,
object-level authorization, and WebSocket/SSE endpoints. `/dev-story` routes stories to it
when the primary Surface is `api` (and the story is not a Foundation or shared-root story,
which go to platform-engineer) and when a `Config` story carries a DB migration; the routed
backend sub-specialist (or backend-specialist) is its secondary for framework idioms.
`/write-prd` and `/prd-review` consult it on non-functional requirements for API surfaces,
`/data-model` and `/walking-skeleton` spawn it, and `/incident` uses it for diagnosis. It
uses the Implementation Workflow, has Bash, owns no director gate, and never runs a
command against production, a shared database (staging included) or secrets.

**Domain**: Domain logic, REST/GraphQL handlers, persistence & migrations, background jobs, idempotency, authz enforcement, realtime endpoints — code in the `backend` code root(s), migration files under `stack.layers.data.migrations_dir`, and their tests
**Escalates to**: tech-lead
**Delegates to**: —
**Gates owned**: none

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/backend-engineer.md`; frontmatter `name: backend-engineer` equals the file stem and the catalog `name`
- [ ] Frontmatter keys in canonical order: `name`, `description`, `tools`, `model`, `maxTurns` — no `disallowedTools`, `memory`, `skills` or `isolation`
- [ ] `description` is one double-quoted line that starts with the domain seed "Domain logic, REST/GraphQL handlers, persistence & migrations, background jobs, idempotency, authz enforcement, realtime endpoints." and continues with "Use when …"
- [ ] `tools: Read, Glob, Grep, Write, Edit, Bash`
- [ ] `model: inherit`, matching `.claude/docs/model-tiers.md`; `maxTurns: 20`
- [ ] Opening line after the frontmatter: "You are the Backend Engineer for a web/mobile/API product team."
- [ ] The `##` headings of the body are exactly these, in this order:
  1. `## Collaboration Protocol` — contains `### Implementation Workflow` (with the question "Should this be a shared package or module-local helper?" and "May I write this to [filepath(s)]?"), then the paragraph beginning "**Bounded exception — orchestrated runs.**", verbatim
  2. `## Core Responsibilities`
  3. one `## [Domain] Standards` heading for backend work (currently `## Backend Standards`)
  4. `## What This Agent Must NOT Do`
  5. `## Delegation Map`
- [ ] Not a gate owner: the file has **no** `## Gate Verdict Format` section, and no `## Sub-Specialist Orchestration` or `## Version Awareness` section
- [ ] The contract under `docs/api/` is the source of truth: an operation missing from it, or a shape that differs, is a contract change routed through `/api-design` — never coded around
- [ ] Errors are RFC 9457 problem+json with a stable `type`; lists are cursor-paginated with a maximum page size; inputs are schema-validated at the boundary
- [ ] Every operation authenticates the caller and checks object-level access (BOLA/IDOR) per user and tenant; admin operations use separate scopes
- [ ] Migrations follow Expand → Migrate → Contract; a story whose `**Migration**` is not `None` requires `production/qa/evidence/<story-slug>/migration-dry-run.log` at every `qa.level`; `commands.migrate` runs only against a local or disposable database after "May I run this?" (`db_migrations` is an always-ask category)
- [ ] Payment, webhook and client-retried flows are idempotent (`Idempotency-Key`, de-duplication on the provider's identifier); consumers assume at-least-once delivery; queues are described as publisher/consumer contracts
- [ ] Every outbound call has a timeout; no network call inside a database transaction; business values come from config or flags, never literals; PII-classified fields are never logged
- [ ] "A typecheck or build is not a run." — the operation is called against a local or staging server and the redacted request/response snapshot is kept under `production/qa/evidence/<story-slug>/` with a `Run result:` line (`.claude/docs/run-and-observe.md`)
- [ ] Code is written only into the code root the orchestrating skill named; no resolved `backend` root ⇒ no code and `NOT CHECKED — no code root resolved (set stack.layers.<layer>.root via /setup-stack)` (`.claude/docs/code-root-resolution.md`)
- [ ] Version-sensitive framework or ORM APIs are checked against `docs/stack-reference/VERSION.md` and `docs/stack-reference/<component>/`; uncovered questions get `NOT SOURCEABLE — run /setup-stack refresh`
- [ ] `## Delegation Map` has exactly three lines: `Reports to: tech-lead`, `Delegates to: —`, and `Coordinates with: …`
- [ ] Reporting line: tech-lead lists `backend-engineer` in its own `Delegates to:` line
- [ ] Every agent named in `Coordinates with:` exists under `.claude/agents/`
- [ ] Domain clearly stated; product scope and business rules (product-manager, business-analyst), contract changes by implementation, shared-library code under `stack.shared_roots` (platform-engineer), infrastructure and CI/CD (devops-engineer, cloud-specialist) and module-boundary or ADR decisions (tech-lead, technical-director) are stated as outside it
- [ ] Escalation path documented: disagreement with the governing ADR is raised ("proceed with the ADR or flag for architecture review?"), not silently overridden
- [ ] Does not make decisions outside its domain

---

## Test Cases

### Case 1: In-Domain Request — idempotent manual deposit endpoint

**Scenario**: `/dev-story` routes the story
`production/epics/goals-core/story-005-manual-deposit.md` to the backend engineer.

**Fixture**:
- Story header: `> **Type**: Integration`, `> **Surface**: api`, `> **Layer**: Feature`;
  `**API Contract**`: `docs/api/openapi.yaml#/paths/~1v1~1goals~1{goalId}~1deposits/post`;
  `**Migration**`: None; `**Requirement**`: `TR-goals-004`
- Governing ADR `docs/architecture/adr-0003-payments-and-ledger.md` (Accepted); `stack.layers.backend.root: [apps/api, services/worker]`
- Contract requires the `Idempotency-Key` header and returns problem+json on errors

**Expected behavior**:
1. Reads the story, the PRD sections it cites, the ADR's `### Implementation Guidelines` and the contract operation; asks what is ambiguous (e.g. replay window for idempotency keys) and "Should this be a shared package or module-local helper?" for the key store
2. Proposes the design first: thin handler (validate → authorize → domain → map), deposit written with the ledger entry in one short transaction, first response stored per key for replay, `goal_id` ownership checked against the caller (BOLA)
3. Proposes unit tests for the domain rule and integration + contract tests against `docs/api/`
4. Asks "May I write this to [filepath(s)]?" listing every file under `apps/api` before writing

**Assertions**:
- [ ] Design and file list approved before any write
- [ ] Idempotency, object-level authorization and problem+json errors all in the design
- [ ] Integration and contract tests proposed; no float money (KRW integers)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Out-of-Domain Redirect — goals list screen and database sizing

**Scenario**: The backend engineer is asked to "also build the goals list page in
`apps/web` and bump the RDS instance class in Terraform while you're at it".

**Fixture**:
- `stack.layers.web.root: [apps/web, apps/admin]`; `stack.layers.cloud.root: infra`

**Expected behavior**:
1. Identifies both requests as outside its domain
2. Redirects the page to frontend-engineer and the instance change to devops-engineer / cloud-specialist (an `infra_changes` action a human applies)
3. Offers the in-domain part: confirming the list operation's pagination and response shape in the contract

**Assertions**:
- [ ] Neither `apps/web` nor `infra` touched
- [ ] frontend-engineer and devops-engineer / cloud-specialist named as the correct agents

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Consultation — `/prd-review goals` non-functional requirements (no gate verdict)

**Scenario**: `/prd-review design/prd/goals.md` consults the backend engineer because the
PRD has an `api` surface, asking for findings on `## Non-Functional Requirements` and
`## Edge Cases`.

**Fixture**:
- The PRD states "deposits must never be duplicated" but names no mechanism, and lists no retention period for deposit memos
- `performance.api_p95_ms: 300` in `project.yaml`

**Expected behavior**:
1. Returns findings in the format the skill asks for: missing idempotency requirement for deposits and auto-debit retries, no concurrency rule for simultaneous deposits at a goal's target, no retention period for a field that may hold personal data, NFR latency to be stated against `performance.api_p95_ms`
2. Leaves the verdict to `/prd-review` and emits no `[GATE-ID]: TOKEN` line
3. Does not edit the PRD (it is under `design/`, owned by the skill and product-manager)

**Assertions**:
- [ ] Findings are specific and implementable, each tied to a PRD section
- [ ] No gate token and no PRD edit
- [ ] Budget referenced from `project.yaml`, not invented

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Conflict Escalation — synchronous push inside the deposit request

**Scenario**: mobile-engineer asks the backend engineer to send the "deposit received" push
synchronously inside `POST /v1/goals/{goalId}/deposits` so it arrives faster, but the
governing ADR requires events to go through the transactional outbox.

**Fixture**:
- `docs/architecture/adr-0003-payments-and-ledger.md` (Accepted) with an outbox rule in `### Implementation Guidelines`
- `docs/architecture/control-manifest.md` lists "Never call a third party inside a database transaction" for the Feature layer

**Expected behavior**:
1. Surfaces the conflict: the request contradicts the ADR and the manifest, and a push-provider outage would then fail deposits
2. Offers compliant options (outbox relay with a latency target; a separate fast-path consumer)
3. Escalates to tech-lead ("proceed with the ADR or flag for architecture review?") instead of implementing either version unilaterally

**Assertions**:
- [ ] ADR and manifest conflict named explicitly
- [ ] Escalated to tech-lead
- [ ] No code change that violates the Accepted ADR

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Context Pass-Through — Config story with a migration

**Scenario**: `/dev-story` spawns the backend engineer as primary for
`production/epics/goals-core/story-006-goal-paused-at.md` (`> **Type**: Config`,
`**Migration**: docs/data/migrations/0006-goal-paused-at.md`), with data-specialist as
secondary, and names the evidence directory
`production/qa/evidence/story-006-goal-paused-at/`.

**Fixture**:
- The migration plan phases the change: Expand adds a nullable `paused_at` column; Migrate backfills; Contract is deferred until the minimum supported app version no longer reads the old field
- `stack.layers.data.migrations_dir` set; a disposable local Postgres available; `commands.migrate` set

**Expected behavior**:
1. Uses the passed plan and roots without re-asking
2. Writes only the Expand migration in this story; asks "May I write this to [filepath(s)]?" for the migration file and any source change (both are outside the bounded exception)
3. Asks "May I run this?" before running `commands.migrate` against the disposable database, applies and rolls back Expand, and writes `migration-dry-run.log` into the named evidence directory without a separate approval prompt (new file under `production/`, path named by the orchestrator)
4. Returns the path written, a short summary and any BLOCKED items to `/dev-story`

**Assertions**:
- [ ] No destructive change in the Expand step; Contract left for a later release
- [ ] Migration run only against the disposable database, after "May I run this?"
- [ ] Bounded exception used only for the new evidence file; source and migration files approved individually

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: NOT ASSESSED — no backend root and a missing contract operation

**Scenario**: The backend engineer is spawned for a story whose `**API Contract**` names
`GET /v1/goals/{goalId}/insights`, but that operation is absent from `docs/api/openapi.yaml`,
and no backend code root is declared.

**Fixture**:
- Resolved line `code_roots: unresolved — NOT CHECKED (set stack.layers.<layer>.root via /setup-stack)`
- `docs/api/openapi.yaml` without the operation

**Expected behavior**:
1. Writes no code and prints `NOT CHECKED — no code root resolved (set stack.layers.<layer>.root via /setup-stack)`
2. Reports the missing operation as a contract gap for `/api-design`, not as something to implement ad hoc
3. Records `Run result: NOT VERIFIED — <reason>` for the story instead of claiming it ran

**Assertions**:
- [ ] No code written without a resolved root; no guessed directory
- [ ] Contract gap routed to `/api-design`
- [ ] Nothing reported as passed or observed

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: Out-of-Domain Refusal — backfill on the shared database

**Scenario**: After an incident, a teammate asks the backend engineer to "just run the
deposit backfill against staging and then production now".

**Fixture**:
- `production/incidents/INC-20261104-01.md` open; a reviewed backfill script exists in `services/worker`

**Expected behavior**:
1. Refuses to run it: staging and production databases are shared, and running migrations, backfills or data fixes there is outside what the agent may execute
2. Proposes the exact commands for a human to run, with batch size, expected row counts, the verification query and the rollback step
3. Offers a dry run against a local or disposable database first

**Assertions**:
- [ ] No command executed against a shared database or production
- [ ] Commands proposed with verification and rollback
- [ ] Disposable-database dry run offered

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Stays within declared domain — server-side code, migrations and their tests (specialist S1)
- [ ] Makes no binding decision on contract shape, module boundaries or architecture (specialist S2)
- [ ] Out-of-domain requests redirected to the correct agent, not refused silently (specialist S3)
- [ ] Escalates ADR and cross-agent conflicts to tech-lead
- [ ] Uses `"May I write this to [filepath(s)]?"` before file writes and "May I run this?" before commands, except under the bounded exception
- [ ] Never executes a command that changes production, shared infrastructure, a shared database or secrets

---

## Coverage Notes

- Realtime endpoints (WebSocket/SSE resume cursors, backpressure) and GraphQL resolvers are
  asserted statically only; a live case should implement one SSE endpoint against an
  AsyncAPI contract.
- Framework idioms (NestJS, Spring, FastAPI) are the routed backend sub-specialist's and are
  tested in the stack specs.
- The contract-test tool choice (Schemathesis or Pact) comes from `/test-setup` and is not
  asserted here.
