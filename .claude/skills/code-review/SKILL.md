---
name: code-review
description: "Architectural code review with service concerns: authz, validation, N+1, transactions, idempotency, timeouts, pagination, PII in logs."
argument-hint: "[path-to-file-or-directory] [story-path]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/code-review/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,stack,code_roots`

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

# Code Review

An architectural review of service code: does it follow the governing ADRs and the
tech radar, conform to the API contract, enforce authorization on every operation,
survive retries, concurrency and partial failure, keep secrets and personal data out
of the repo and the logs, and stay testable? The **Service Review Checklist** in
Phase 5 is the core of this skill — `/story-done` runs that same checklist inline
over a story's changed files when review mode skips the tech-lead code review.

This skill is read-only — it reports in the conversation and writes no files.

---

## Insufficient input — check this before producing any report

**If the inputs this skill needs do not exist, the answer is "could not run" —
not a filled-in report.** Check first, and stop if the check fails.

1. List the inputs this skill reads (the target source files, the story file when
   given, governing ADRs, the API contract, migration plans, the tech radar).
2. For each, record `FOUND` or `ABSENT` — not "assumed present".
3. If any input required for a section is ABSENT, that section is
   **`NOT ASSESSED — NO DATA`**. Do not estimate it, do not infer it from an
   adjacent artifact, and do not leave a mandated cell to be filled by whoever
   reads the template next.
4. If **every** required input is ABSENT — above all, the target files — stop and
   report **`NOT ASSESSED — NO DATA`** as the whole verdict, naming what was missing
   and which skill produces it.

**A verdict of `NOT ASSESSED` is a success.** It is the correct, useful answer to
"what does the data say?" when there is no data. The failure mode this prevents is
specific and has been observed in practice: report templates whose verdict
enum had no "could not run" state produced **false clean passes** — an audit
returning COMPLIANT on a project with nothing to audit and no standards, and a
performance profile reporting ample headroom against a latency budget with zero
traces and no budget ever set.

**Absence of evidence is never evidence of absence.** A scan that finds no
matches because there are no files to scan has not verified anything. Say which of
the two happened — a reader cannot tell from a green result.

---

## Phase 0: Configuration

Use the resolved block above as-is:

- **`code_roots`** — every target file is placed in its root and layer
  (`web`, `mobile`, `backend`, `data`, `cloud`, `shared`, `undeclared`). A file
  under no resolved root is reviewed, but its layer is reported as `unknown` and
  no stack specialist is routed for it. `code_roots: unresolved` ⇒ print
  `NOT CHECKED — no code root resolved (set stack.layers.<layer>.root via /setup-stack)`
  once, then review the named files without layer routing.
- **`stack`** — the configured layers and the `[routing: …]` list (for example
  `web-specialist>nextjs-specialist, backend-specialist>node-specialist, data-specialist`)
  that Phase 7 spawns from. `stack: unset — run /setup-stack` ⇒ Phase 7 prints
  `Stack specialist review: NOT ASSESSED — stack unset (run /setup-stack)`.
- **`automation`** — governs the closing question in Phase 9; this skill has no
  write to confirm.

---

## Phase 1: Load Target Files

Arguments: `/code-review [path-to-file-or-directory] [story-path]`, for example
`/code-review apps/api/src/modules/goals production/epics/goals-core/story-001-create-goal.md`.

1. Read the target file(s) in full. For a directory, Glob the source files under it
   (skip `node_modules`, build output and generated clients) and list them before
   reading; if the list is long, confirm the scope with the user first.
2. Read `CLAUDE.md` and `.claude/docs/coding-standards.md` for the project's
   coding standards.
3. Read the path-scoped rules in `.claude/rules/` whose `paths:` match the targets —
   for example `api-code.md` for routes and controllers, `domain-logic.md` for
   domain modules, `migrations.md` for migration files, `ui-code.md` for screens and
   components, `mobile-code.md`, `infra-code.md`, `test-standards.md`. The review
   applies them; it does not restate them.
4. If a story path was given, read its header fields: `> **Layer**:`, `> **Type**:`,
   `> **Surface**:`, `**ADR Governing Implementation**`, `**API Contract**`,
   `**Migration**`, `**Feature Flag**`, `**Analytics Events**`, and its
   `## Acceptance Criteria`.

---

## Phase 2: Identify Stack Specialists

Map each target file to its layer through the `code_roots` line, then take the
routed agent for that layer from the `stack` line's `[routing: …]` list:

- `web` root → the routed web sub-specialist (e.g. `nextjs-specialist`), or
  `web-specialist` when no sub is routed
- `mobile` root → the routed mobile sub-specialist(s) (e.g. `react-native-specialist`,
  or `ios-specialist` + `android-specialist` for native apps), or `mobile-specialist`
- `backend` root → the routed backend sub-specialist (e.g. `node-specialist`,
  `spring-specialist`, `python-specialist`), or `backend-specialist`
- `data` root (migrations), or files that are mostly queries and schema →
  `data-specialist`
- `cloud` root, IaC, Dockerfiles, CI workflows → `cloud-specialist`
- `shared` root → the specialist of the layer that consumes the package; cross-layer
  or unclear → the layer lead

A layer that the `stack` line lists under `unset=` gets no specialist; record
`NOT CHECKED — <layer> layer not configured (run /setup-stack)` for its files. A
skipped specialist that says nothing is indistinguishable from one that reviewed
the code and found nothing.

---

## Phase 3: ADR Compliance Check

Search for ADR references in, in priority order:
1. The story file (if provided) — `**ADR Governing Implementation**`
2. Header comments at the top of the implementation files
3. Commit messages referencing these files (`git log --oneline -- [file]`)

Look for patterns like `ADR-NNNN` or `docs/architecture/adr-NNNN-`.

If no ADR references found, note: "No ADR references found — ADR compliance check skipped. For full ADR compliance review, provide the story path: `/code-review [files] [story-path]`."

For each referenced ADR, load **only the sections this check needs — never an unbounded full read.** A substantial ADR exceeds the 25k-token `Read` cap, and a capped read's only recovery is paging the remainder — the most expensive way to read a file (measured ~103k vs ~54k tokens on a 34k-token ADR). Use the same pattern as `/dev-story` and `/create-stories`:

1. **Map the headings** (cheap — line numbers only): `Grep pattern="^## " path="[adr-file]" output_mode="content" -n`
2. **Bounded-read only `## Decision`, `## Consequences` and `## Security & Privacy Implications`**, using the line numbers to set `Read(offset, limit)` spans that end where the next heading begins. If the heading map is empty (a nonstandard ADR predating the template), fall back to one full `Read`; if that truncates at the cap, grep for the decision/consequence content directly rather than paging the remainder.

From those sections, classify any deviation:

- **ARCHITECTURAL VIOLATION** (BLOCKING): Uses a pattern explicitly rejected in the ADR
- **ADR DRIFT** (WARNING): Meaningfully diverges from the chosen approach without using a forbidden pattern
- **MINOR DEVIATION** (INFO): Small difference from ADR guidance that doesn't affect overall architecture

An ADR whose `## Status` is still `Proposed` governs nothing yet — say so; code built
on it is flagged ADR DRIFT until the ADR is Accepted.

---

## Phase 4: Tech Radar and Control Manifest

1. **Tech radar** — read `docs/architecture/tech-radar.md` (`## Hold` and
   `## Forbidden Patterns`; `## Adopt` and `## Trial` for context).
   - The code uses a **Forbidden Pattern** → ARCHITECTURAL VIOLATION (BLOCKING).
   - The code **starts new use** of a `## Hold` entry → ADR DRIFT (WARNING), citing
     the entry's ADR.
   - A **new dependency** (a manifest diff: `package.json`, `pyproject.toml`,
     `build.gradle`, `pubspec.yaml`, …) that is not on the radar → INFO, with the
     suggestion to record it through `/architecture-decision`.
   - File absent ⇒ `NOT CHECKED — docs/architecture/tech-radar.md absent (seeded by /setup-stack)`.
2. **Control manifest** — if `docs/architecture/control-manifest.md` exists, check
   the rules of the targets' architecture layer (`## <Layer> Layer Rules` — the
   story's `> **Layer**:`, else the Foundation / Core / Feature / Presentation layer
   the module belongs to): a "Never" rule broken is BLOCKING; a Required Pattern or
   "Always" rule missed is WARNING. Absent ⇒ note it and continue.

---

## Phase 5: Service Review Checklist

**This is the checklist `/story-done` runs inline when TL-CODE-REVIEW is skipped.**
Keep every item answerable from the changed files plus the contract, the migration
plan and the story. For each item record PASS, a finding with file and line, or
`N/A — <why>` (an item never silently disappears).

1. **API contract conformance** — each new or changed handler matches its operation
   in `docs/api/` (the story's `**API Contract**`): method and path, request and
   response schemas, status codes, error format (problem+json where the API
   guidelines say so), pagination parameters. An operation that is not in the
   contract does not ship: undocumented endpoint → BLOCKING. No contract in
   `docs/api/` ⇒ `NOT CHECKED — no API contract (run /api-design)`.
2. **Authorization on every operation** — object-level: the caller may act on *this*
   resource, scoped in the query (`where ownerId = :userId` / tenant ID), not only
   "is signed in" (BOLA/IDOR); function-level: admin and back-office operations check
   roles; no mass assignment of protected fields (`ownerId`, `role`, `plan`,
   `balance`); no trust in client-supplied user or tenant IDs. A missing authorization
   check → BLOCKING.
3. **Input validation at the boundary** — request bodies, query and path parameters,
   headers, file uploads, webhooks (signature verified before parsing) and queue
   messages are schema-validated (zod / class-validator / Pydantic / Bean Validation)
   with size and length limits and allow-lists for enums.
4. **Data access** — no N+1 queries (lazy relations inside loops: Prisma `include`,
   JPA fetch joins, Django `select_related`/`prefetch_related`); new query predicates
   have supporting indexes; no unbounded `SELECT`; multi-write operations run in one
   transaction; read-modify-write paths use an atomic update, optimistic version or
   row lock instead of racing.
5. **Idempotency** — money-moving handlers (charges, refunds, auto-debit
   callbacks), webhook handlers and retried jobs are idempotent: an `Idempotency-Key`
   or natural key with a unique constraint, or a dedupe record; queue consumers
   tolerate at-least-once delivery.
6. **Timeouts and retries** — every outbound call (payment gateway, identity
   provider, push or messaging provider, internal service) sets a timeout; retries
   are bounded with exponential backoff and jitter and are applied only to
   idempotent operations; a failing dependency degrades the feature instead of the
   request thread pool.
7. **Pagination** — list endpoints paginate (cursor-based for feeds and large
   tables), enforce a maximum page size and use a stable sort order.
8. **Secrets** — no secrets, API keys, tokens, private keys or connection strings in
   code, config, fixtures or test snapshots; they come from the environment or the
   secret manager. A committed secret → BLOCKING (and it must be rotated, not only
   removed).
9. **Personal data in logs and telemetry** — no PII (email, phone number, name,
   address, resident registration number, payment card data, access tokens) in log
   statements, error messages, analytics events or trace attributes; fields the data
   model classifies as personal are redacted or hashed.
10. **Migrations (expand/contract)** — a schema change follows its plan in
    `docs/data/migrations/` (the story's `**Migration**`): additive Expand first; no
    destructive change (drop, rename, type narrowing) in the release that stops using
    the column; backfills batched; the migration file references its plan; a down
    migration or a documented rollback exists.
11. **Feature flags** — new user-facing behaviour sits behind the flag the story
    names (e.g. `goals.v2-progress-ring`); the default state is recorded; turning
    the flag off is a working kill switch (no half-migrated state); stale flags
    carry a removal date.
12. **Errors and operability** — errors are logged once, structured, with the
    request or correlation ID; exceptions are not swallowed; new endpoints and jobs
    emit the metrics and traces the SLO doc relies on; user-facing error text comes
    from the copy deck, not from exception messages.
13. **Tests** — assertions check behaviour, not implementation details; tests are
    deterministic (no real clock, network or unseeded randomness); no skipped or
    focused tests left in; new operations have an integration or contract test.

**Severity**: a committed secret or a missing authorization check is **BLOCKING**;
an undocumented operation, a destructive migration outside a planned Contract phase
or a non-idempotent payment handler is **BLOCKING**; other findings are
**WARNING** unless they contradict an ADR or the contract, and style-level notes are
**INFO**.

---

## Phase 6: Engineering Standards and Architecture

**Standards** (per `.claude/docs/coding-standards.md`):
- [ ] Public functions, classes and exported modules have doc comments
- [ ] Cyclomatic complexity under 10 per function
- [ ] No function exceeds 40 lines (excluding data declarations)
- [ ] Dependencies are injected (no module-level singletons holding request or user state)
- [ ] Business values (prices, fees, limits, quotas, timeouts) come from config or flags, not literals
- [ ] Modules expose interfaces (not concrete class dependencies) at their boundaries

**Architecture:**
- [ ] Correct dependency direction (domain ← application ← adapters/transport; the domain does not import the web framework, ORM or SDKs)
- [ ] No circular dependencies between modules or packages
- [ ] Proper layer separation (views and screens hold no business rules; server state is not duplicated in client stores without a sync strategy)
- [ ] Cross-module communication through the module's public API or events, not by reaching into another module's tables
- [ ] Consistent with established patterns in the codebase

**SOLID:**
- [ ] Single Responsibility: Each class or module has one reason to change
- [ ] Open/Closed: Extendable without modification
- [ ] Liskov Substitution: Subtypes substitutable for base types
- [ ] Interface Segregation: No fat interfaces
- [ ] Dependency Inversion: Depends on abstractions, not concretions

---

## Phase 7: Specialist Reviews (Parallel)

Spawn all applicable specialists simultaneously via `Agent` — do not wait for one before starting the next.

> **Verify every specialist finding before reporting it. Do not pass findings
> through unchecked.** For each finding, record in the report:
>
> - **File and line** it refers to.
> - **Evidence** — the quoted code, or the concrete input/state that triggers it.
> - **Confidence** — `VERIFIED` (you checked it yourself) or `UNVERIFIED —
>   specialist claim` (you could not).
>
> A finding you could not verify is reported as unverified or dropped, never
> promoted to a defect on the strength of confident phrasing.
>
> **Why this is mandatory.** Agents are reliable when deriving and unreliable when
> diagnosing existing code. Measured in practice: three separate agents
> produced three different **wrong** claims about the same six-line function,
> every one fluent enough to pass a skim — including a spawned specialist here
> alleging a float-precision bug that enumerating the inputs disproves. Without
> this step the parent review is a laundering channel: a guess enters as a
> specialist finding and leaves as a reviewed defect.

### Stack Specialists

For each layer with target files and a routed specialist (Phase 2), spawn that
specialist with: the files of its layer, the governing ADR paths, the contract path
(or "none"), and the question "Does this code follow the idioms, version
constraints and pitfalls of the pinned stack (see `docs/stack-reference/VERSION.md`)?"
Specialists stay inside their layer; a layer lead may delegate to its subs.
A lead that returns `NOT CONSULTED — <sub> (nested spawn unavailable)` or a
`<sub>: <task>` hand-off gets that sub spawned by this skill with the files of its
layer, or the NOT CONSULTED line copied into the review — a skipped sub is never
silent.

### QA Testability Review

For Logic, Integration and E2E stories, also spawn `qa-engineer` via `Agent` in
parallel with the stack specialists. Pass:
- The implementation files being reviewed
- The story's `## QA Test Cases` section, if present
- The story's `## Acceptance Criteria`

Ask the qa-engineer to evaluate:
- [ ] Are the seams tests need exposed (injectable clients, clock, IDs) rather than hidden behind module state?
- [ ] Do the story's QA test cases and acceptance criteria map to testable code paths?
- [ ] Are any acceptance criteria untestable as implemented (e.g., hardcoded values, no seam for a third-party call)?
- [ ] Does the implementation introduce new edge cases (retries, partial failure, concurrency) not covered by the existing tests?
- [ ] Are there observable side effects (events emitted, messages sent, rows written) that should have a test but don't?

For UI stories: qa-engineer reviews whether the states the acceptance criteria name
(loading, empty, error, offline) are reachable and capturable as evidence.

### Security Review (when auth or personal-data code is touched)

Spawn `security-engineer` via `Agent` in parallel when the targets touch
authentication or session handling (sign-in, token issue or refresh, OAuth or
social-login callbacks such as Kakao, Naver or Apple), authorization middleware or
policies, password, OTP or identity-verification flows, payment or billing code,
file upload and download, or fields the data model classifies as personal. Pass the
files, the contract path, `docs/data/data-model.md` (or "none") and
`docs/security/threat-model.md` (or "none"), and ask for authorization, input
validation, secrets and personal-data findings with evidence. When none of these is
touched, record `Security review: not required — no auth or personal-data code touched`.

Collect all specialist findings before producing output.

---

## Phase 8: Output Review

```
## Code Review: [File/Module Name]

### Stack Specialist Findings: [NOT ASSESSED — stack unset / CLEAN / ISSUES FOUND]
[Findings per layer, each VERIFIED or UNVERIFIED; NOT CHECKED lines for unconfigured layers; NOT CONSULTED lines for subs a lead could not reach]

### Security Review: [not required / CLEAN / ISSUES FOUND]
[security-engineer findings with evidence]

### Testability: [N/A — Config story / TESTABLE / GAPS / BLOCKING]
[qa-engineer findings: seams, coverage gaps, untestable paths, new edge cases]
[If BLOCKING: implementation must expose [X] before the tests in the story can run]

### ADR Compliance: [NOT ASSESSED / NO ADRS FOUND / COMPLIANT / DRIFT / VIOLATION]
[List each ADR checked, result, and any deviations with severity]

### Tech Radar & Manifest: [NOT CHECKED — reason / COMPLIANT / DRIFT / VIOLATION]
[Forbidden patterns, Hold entries, off-radar dependencies, manifest rules]

### Service Review Checklist: [X/13 passing, N N/A]
[One line per item: PASS / finding with file and line / N/A — why]

### Standards & Architecture: [NOT ASSESSED / CLEAN / MINOR ISSUES / VIOLATIONS FOUND]
[Standards failures, architectural concerns and SOLID violations with line references]

### Positive Observations
[What is done well -- always include this section]

### Required Changes
[Must-fix items before approval — ARCHITECTURAL VIOLATIONs and BLOCKING checklist findings always appear here]

### Suggestions
[Nice-to-have improvements]

### Verdict: [NOT ASSESSED / APPROVED / APPROVED WITH SUGGESTIONS / CHANGES REQUIRED]
```

**Verdict rules** — `CHANGES REQUIRED` when any BLOCKING finding or ARCHITECTURAL
VIOLATION stands; `APPROVED WITH SUGGESTIONS` when only WARNING/INFO findings
remain; `APPROVED` when nothing remains; `NOT ASSESSED` when the target files could
not be read. A review in which a required part could not run (no contract, no
specialist for a configured layer) names that part as NOT CHECKED and cannot be
plain `APPROVED` — it is at best `APPROVED WITH SUGGESTIONS` with the gap listed.

This skill is read-only — no files are written.

---

## Phase 9: Next Steps

Use `AskUserQuestion`:
- Prompt: "Code review complete — verdict: [NOT ASSESSED / APPROVED / APPROVED WITH SUGGESTIONS / CHANGES REQUIRED]. How would you like to proceed?"
- Options (adjust based on verdict):
  - If APPROVED or APPROVED WITH SUGGESTIONS:
    - `[A] Run /story-done to close the story`
    - `[B] Stop here`
  - If CHANGES REQUIRED:
    - `[A] Fix the issues and re-run /code-review`
    - `[B] Run /story-done anyway with noted exceptions`
    - `[C] Stop here`
  - If NOT ASSESSED:
    - `[A] Point me at the files to review`
    - `[B] Stop here`

If an ARCHITECTURAL VIOLATION is found:
- If the violation contradicts an **existing ADR**: fix the implementation to comply with `docs/architecture/[adr-file].md`. If the design has legitimately changed, run `/architecture-decision` to *supersede* the existing ADR with an explicit replacement — do not create a competing one.
- If **no ADR exists** for the pattern that was violated: run `/architecture-decision` to document the correct approach before fixing the code.

If the code implements an operation the contract lacks, run `/api-design update <resource>`
before merging; a schema change without a plan goes to `/data-model migration <slug>`.

---

## Collaborative Protocol

- **Report, never rewrite.** This skill proposes changes; it does not edit code.
  Fixes happen in `/dev-story` or by the user.
- **Evidence over assertion.** Every finding carries a file, a line and the code or
  input that triggers it; unverified specialist claims are labelled as such.
- **Skips announce themselves.** An unconfigured layer, a missing contract, a missing
  tech radar or an unrouted specialist appears as a `NOT CHECKED` line — never as a
  clean section.
- **The user decides.** The closing question offers the next skill; nothing runs
  without the user's choice.
