# Agent Spec: python-specialist

> **Tier**: stack
> **Category**: stack
> **Spec written**: 2026-09-28

<!-- Asserts the canonical English text of .claude/agents/python-specialist.md (quoted
     prompts, headings, tokens), never the wording the model uses at run time in the
     user's conversation language. Examples use the canonical product "Moa". Versions
     and Knowledge Risk values in fixtures are illustrative test inputs, not claims
     about real releases. -->

## Agent Summary

The Python specialist is the backend layer's sub-specialist for Python backends: FastAPI routers
and Django apps, SQLAlchemy or the Django ORM with Alembic or Django migrations, async
correctness, and Celery (or the ADR's task queue) tasks and schedules, plus dependency locking,
typing and linting. backend-specialist routes work to it when `stack.layers.backend.framework`
matches `fastapi|django|flask|python`, and decides the module boundaries, persistence and job
patterns it implements; `/dev-story` names it as the secondary agent on `api` stories and on ML
stories (where ml-engineer is primary) under that route (a consult: it returns guidance and the
engineers write), `/code-review` sends it the files under the backend roots, and `/api-design`
consults it on implementability. It uses the Implementation Workflow,
runs on Sonnet, has Bash but no `Agent` grant and no web search, and owns no director gate. It
reads `docs/stack-reference/` before version-sensitive advice and answers
`NOT SOURCEABLE — run /setup-stack refresh` where the reference is silent. Model training,
evaluation and prompt logic, contract and data-model changes, business rules and anything run
against shared databases are outside it.

**Domain**: Python backends in the backend roots — FastAPI, Django; SQLAlchemy / Django ORM; Alembic or Django migrations; Celery
**Escalates to**: backend-specialist
**Delegates to**: —
**Gates owned**: none

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/python-specialist.md`; frontmatter `name: python-specialist` equals the file stem and the catalog `name`
- [ ] Frontmatter keys in canonical order: `name`, `description`, `tools`, `model`, `maxTurns` — no `disallowedTools`, no `memory`, no `skills`, no `isolation`
- [ ] `description` is one double-quoted line that starts with the domain seed "Python backends: FastAPI, Django; SQLAlchemy / Django ORM; Celery." and continues with "Use when …"
- [ ] `tools` grants exactly `Read`, `Glob`, `Grep`, `Write`, `Edit`, `Bash` — no `Agent(...)` grant, no `WebSearch`/`WebFetch`
- [ ] `model: sonnet` (stack sub-specialist), matching `.claude/docs/model-tiers.md`; `maxTurns: 20`
- [ ] Opening line after the frontmatter has the form "You are the [Title] for a web/mobile/API product team." with a title naming the role (e.g., "Python Specialist")
- [ ] The `##` headings of the body are exactly these, in this order:
  1. `## Collaboration Protocol` — contains `### Implementation Workflow` (with the question "Should this be a shared package or module-local helper?"), then the paragraph beginning "**Bounded exception — orchestrated runs.**", verbatim
  2. `## Core Responsibilities`
  3. one `## [Domain] Standards` heading for the language stack (e.g., `## Python Standards`)
  4. `## Version Awareness`
  5. `## What This Agent Must NOT Do`
  6. `## Delegation Map`
- [ ] No `## Gate Verdict Format` section (owns no gate) and no `## Sub-Specialist Orchestration` section (no `Agent(...)` grant)
- [ ] `## Version Awareness` requires reading `docs/stack-reference/VERSION.md` and `docs/stack-reference/<component>/` before version-sensitive advice, flagging post-cutoff APIs with their Knowledge Risk, answering `NOT SOURCEABLE — run /setup-stack refresh` instead of guessing, staying inside the backend layer, and escalating to backend-specialist, its lead
- [ ] `## Delegation Map` has exactly three lines: `Reports to: backend-specialist`, `Delegates to: —`, and `Coordinates with: …`
- [ ] Reporting line: backend-specialist lists `python-specialist` in its `Delegates to:` line and in its `Agent(...)` grant
- [ ] Every agent named in `Coordinates with:` exists under `.claude/agents/`
- [ ] Domain clearly stated; module/service boundaries and persistence or job patterns (backend-specialist), model training, evaluation and prompt logic (ml-engineer), the API contract and data model, business rules, and production configuration, flags or secrets are stated as outside it
- [ ] Escalation path documented: escalates to backend-specialist
- [ ] Does not make decisions outside its domain; never runs migrations, tasks or scripts against shared, staging or production databases

---

## Test Cases

### Case 1: In-Domain Request — goals router on FastAPI

**Scenario**: backend-engineer asks python-specialist how to implement the goals endpoints for a
Moa variant built on FastAPI with SQLAlchemy.

**Fixture**:
- `stack.layers.backend.framework: FastAPI`, language Python, root `apps/api`; resolved routing `backend-specialist>python-specialist`
- `docs/stack-reference/VERSION.md` rows for FastAPI, Python and SQLAlchemy with Knowledge Risk LOW; `docs/stack-reference/fastapi/VERSION.md` present
- Contract operations `GET /v1/goals`, `POST /v1/goals`; migration plan `docs/data/migrations/0003-goals.md`

**Expected behavior**:
1. Reads the stack reference before naming APIs or settings
2. Proposes: a router per bounded context with typed request and response models matching the contract; authentication and ownership as dependencies, the user never taken from the body; one async database session per request with explicit transaction scope; bounded cursor pagination
3. Proposes an Alembic migration following the plan and integration tests against a disposable database
4. Asks "Should this be a shared package or module-local helper?" where relevant and "May I write this to [filepath(s)]?" before writing

**Assertions**:
- [ ] The stack reference is read before version-sensitive statements (stack S1)
- [ ] No blocking I/O inside async handlers; sessions are request-scoped
- [ ] Ownership is enforced at the boundary
- [ ] Collaborative protocol followed (ask → propose → approve)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Out-of-Domain Redirect — prompt tuning and a cancellation fee

**Scenario**: The user asks python-specialist to rewrite the prompt and evaluation set for Moa's
"savings tips" LLM feature, and to set the early-cancellation fee for Plus.

**Fixture**:
- ADR Domain `ML` for the savings-tips feature; `design/prd/subscription.md` owns fees

**Expected behavior**:
1. Declines prompt and evaluation work: it belongs to ml-engineer; python-specialist implements the service around it (timeouts, retries, streaming, cost logging)
2. Declines to set a fee: business rules belong to the PRD and business-analyst, pricing to monetization-strategist
3. Names the owners

**Assertions**:
- [ ] No prompt, evaluation or fee change made
- [ ] ml-engineer, business-analyst and monetization-strategist named correctly
- [ ] Stays inside its domain (stack S4)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Consultation — `/code-review` of an ML story's service code (no gate)

**Scenario**: ml-engineer implemented an ML story (`**ML**: yes`); `/code-review apps/api/app/insights production/epics/goals-insights/story-002-savings-tips-endpoint.md`
maps the files to the `backend` root and, in Phase 7, spawns the routed backend sub with the
question "Does this code follow the idioms, version constraints and pitfalls of the pinned stack
(see `docs/stack-reference/VERSION.md`)?" python-specialist owns no gate, so this replaces the
template's gate-verdict case.

**Fixture**:
- Context passed: the backend-layer files under `apps/api/app/insights/`, the governing ADR paths, the contract path `docs/api/openapi.yaml`
- The endpoint calls a synchronous LLM SDK inside an `async` handler, has no timeout, retries on every error, and logs the full prompt including the user's goal names and amounts

**Expected behavior**:
1. Returns findings per file with the line, the quoted code as evidence and the fix: use the async client or run the call off the event loop; set a timeout and bounded retries only on retryable errors; stream or return a fallback on timeout; redact personal data from logs
2. Flags the logging of personal data for security-engineer and the retry cost for ml-engineer
3. Does not edit files during the review; leaves the verdict to `/code-review`, which verifies each finding

**Assertions**:
- [ ] No `[GATE-ID]: TOKEN` line and no gate verdict token in the reply
- [ ] The event-loop block and the PII logging are both identified
- [ ] Findings are per file and actionable

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Conflict Escalation — a second task queue

**Scenario**: backend-engineer wants to add a second, lighter task-queue library for notification
jobs alongside Celery. backend-specialist's job pattern names Celery for all background work.

**Fixture**:
- `docs/architecture/architecture.md` names Celery with Redis as broker; no ADR for a second queue

**Expected behavior**:
1. States the cost of two job systems (two sets of retries, monitoring and deploy units)
2. Shows how the notification jobs fit Celery (separate queue, routing, rate limits)
3. Does not add the library; escalates to backend-specialist, its lead

**Assertions**:
- [ ] Escalates to backend-specialist — does not skip a tier (stack S3)
- [ ] No second task-queue library added
- [ ] Conflict surfaced explicitly

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Context Pass-Through — `/dev-story` secondary consult

**Scenario**: `/dev-story` routes the create-goal story (`> **Surface**: api`) to backend-engineer
and spawns python-specialist first as the routed secondary, asking for framework guidance —
idioms, version-sensitive APIs, pitfalls for this story — and no file writes.

**Fixture**:
- Context passed: story path `production/epics/goals-core/story-001-create-goal.md`, root `apps/api`, ADR summary
- The story's `## Test Evidence` names `tests/integration/goals/test_create_goal.py`; the story also changes the existing `apps/api/app/goals/router.py`

**Expected behavior**:
1. Uses the passed context without re-asking
2. Returns guidance scoped to the story: typed request and response models matching the contract, authentication and ownership as dependencies, a request-scoped async session, and a test named scenario → expected against a disposable database
3. Writes nothing — not the test (the engineer writes it) and not `router.py` (existing source)
4. Returns the notes in a form `/dev-story` can pass into backend-engineer's brief

**Assertions**:
- [ ] No file is created or edited
- [ ] The guidance uses the passed root and ADR summary
- [ ] Output format suits the orchestrator

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Knowledge Risk — a free-threaded runtime for the worker

**Scenario**: The user asks python-specialist to run the Celery workers on the free-threaded
Python build "to use all cores without processes".

**Fixture**:
- `docs/stack-reference/VERSION.md` row for Python with Knowledge Risk HIGH
- `docs/stack-reference/python/breaking-changes.md` mentions the free-threaded build exists (sourced); nothing on library compatibility or production readiness

**Expected behavior**:
1. Cites the sourced fact
2. Labels library compatibility (database driver, Celery, native extensions) and production readiness with their Knowledge Risk (e.g., `Knowledge Risk: HIGH`) as not confirmed in `docs/stack-reference/python/`
3. Keeps the process-based worker model and proposes a measured spike; suggests `/setup-stack refresh`

**Assertions**:
- [ ] Unconfirmed compatibility carries a Knowledge Risk label (stack S2)
- [ ] No readiness claim stated from memory
- [ ] A measurement is proposed instead of an assumed benefit

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: NOT SOURCEABLE — ORM async transaction support

**Scenario**: The user of a Django-based variant asks: "Does the Django ORM in our pinned version
support async transactions, so we can make the deposit view fully async?"

**Fixture**:
- `stack.layers.backend.framework: Django`; `docs/stack-reference/VERSION.md` row for Django `NOT DETERMINED — accepted by user 2026-09-27` (Knowledge Risk HIGH)
- No `docs/stack-reference/django/` folder

**Expected behavior**:
1. Answers `NOT SOURCEABLE — run /setup-stack refresh`
2. States no version capability from memory
3. Keeps the transactional deposit path in synchronous code until the capability is sourced, and says so as version-independent advice

**Assertions**:
- [ ] Output contains `NOT SOURCEABLE` and names `/setup-stack refresh` (stack S5)
- [ ] No framework capability stated from memory
- [ ] The money path is not changed on an unsourced assumption

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Stays within Python backends in the backend layer — no boundary, contract, data-model, business-rule, ML-model or infrastructure decisions (stack S4)
- [ ] Escalates pattern trade-offs and cross-layer questions to backend-specialist (stack S3)
- [ ] Uses `"May I write this to [filepath(s)]?"` before file writes, except under the bounded exception
- [ ] Proposes the approach before implementing and explains trade-offs
- [ ] Spawns no agents (no `Agent` grant)
- [ ] Reads `docs/stack-reference/` before version-sensitive advice; flags Knowledge Risk; says `NOT SOURCEABLE` instead of guessing (stack S1, S2, S5)
- [ ] Never runs migrations, tasks or scripts against shared, staging or production databases; never changes production configuration, flags or secrets

---

## Coverage Notes

- Rubric map: Case 1 → stack S1; Case 2 → stack S4; Case 4 → stack S3; Case 6 → stack S2;
  Case 7 → stack S5 (the NOT ASSESSED-class case: the reference the answer depends on is absent).
- Python frameworks the routing rules do not name (e.g., Litestar) route here only through the
  `specialists.backend` override; that path is covered by the backend-specialist spec.
- ML stories pair this agent with ml-engineer (`/dev-story` names it as the routed backend
  secondary); the split of responsibilities is checked in Cases 2 and 3 and should be
  confirmed in a live `/dev-story` run.
