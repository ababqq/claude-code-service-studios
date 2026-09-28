---
name: api-design
description: "Contract-first API design: guidelines, OpenAPI/GraphQL/proto/AsyncAPI contract, UX reconciliation, lint, breaking-change check."
argument-hint: "[new | update <resource> | reconcile | review | breaking-check] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/api-design/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,automation_always_ask,workflow,stack,surfaces,compliance`

Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

# API Design

This skill designs the product's API **contract first**: the rules every operation follows
(`docs/api/api-guidelines.md`), the machine-readable contract itself, and the record of every change to it. Code,
client SDKs, contract tests and stories are built against the contract — an operation that is not in the contract
does not ship.

It runs at three points of the pipeline:

- **Architecture** — `new`: the **initial** contract, covering the Foundation and Core resources (auth/session,
  account, the core domain entity). Gate-validation requires it at `standard` and `full` when the product has a
  backend.
- **Validation** — `reconcile`: the contract is checked against the key UX specs' `## API Data` sections
  (screen-driven operations, pagination, aggregation endpoints) and updated **before** epics are created.
  Gate-build requires the record this mode writes (`> **Mode**: reconcile`, its "no change" record included) at
  `full` when the product has a backend and a UI; it is recommended at `standard`.
- **Any time after** — `update <resource>` for a planned change, `breaking-check` before a release, `review` for an
  audit.

### Modes

| Mode | When | Phases | Writes |
|---|---|---|---|
| `new` | No contract exists (default when none is found) | 0 → 1 → 2 → 3 → 4 → 5 → 6 → 7 → 9 | guidelines, contract (developer guides for a Public API) |
| `update <resource>` | Add or change one resource (a PRD changed, a new feature) | 0 → 1 → 2 (if a rule changes) → 3 → 4 → 5 → 6 → 7 → 8 → 9 | contract, change record, guidelines (if changed) |
| `reconcile` | Validation: key UX specs exist | 0 → 1 → 3R → 4 (if anything changes) → 5 → 6 → 7 (if the contract changed) → 8 → 9 | change record **always**, contract when changes are approved |
| `review` | Audit an existing contract | 0 → 1 → 5 → 6 → 7 → 9 | nothing (report in conversation) |
| `breaking-check` | Before merging or releasing a contract change | 0 → 1 → 5 → 6 → 8 → 9 | change record when the contract differs from `HEAD` |

### Outputs

| Path | Written by | Notes |
|---|---|---|
| `docs/api/api-guidelines.md` | Phase 2 | from `.claude/docs/templates/api-guidelines.md` |
| `docs/api/openapi.yaml` | Phase 4 | OpenAPI 3.1, from `.claude/docs/templates/openapi-skeleton.yaml` — the default style |
| `docs/api/schema.graphql` · `docs/api/<service>.proto` · `docs/api/asyncapi.yaml` | Phase 4 | instead of, or next to, `openapi.yaml` when the API-style ADR chose GraphQL, gRPC or events |
| `docs/api/changes/api-change-YYYY-MM-DD.md` | Phase 8 | change table, rationale, BREAKING plan; a second record on the same day gets the suffix `-2`, `-3` |
| `docs/api/guides/<slug>.md` | Phase 7 | developer guides — Public API only (`api` in `platform.surfaces`) |

The catalog's Architecture step finds the contract through the globs `docs/api/openapi*.yaml`,
`docs/api/openapi*.json`, `docs/api/*.graphql`, `docs/api/*.proto` and `docs/api/asyncapi*.yaml`; its Validation step
finds the change record through `docs/api/changes/api-change-*.md`.

### Verdicts

`CONTRACT READY` · `NEEDS REVISION` · `BREAKING CHANGE — ACTION REQUIRED` · `NOT ASSESSED`

Precedence when several apply: **BREAKING CHANGE — ACTION REQUIRED > NEEDS REVISION > NOT ASSESSED > CONTRACT READY**.
A run that could not assess part of its scope never reports `CONTRACT READY`; a known problem is never hidden
behind `NOT ASSESSED`.

### What this skill never does

- Write handler code, generated clients, contract tests or database migrations (`/dev-story`, `/data-model`).
- Decide the API style on its own at `standard` or `full` — that is an ADR (`/architecture-decision`).
- Choose between a version bump and a deprecation for a BREAKING change — that decision is always the user's.
- Put real personal data, tokens, keys or production credentials in a contract, example or guide.
- Install a linter or diff tool. It runs `commands.api_lint` when configured and tools already present.

---

## Phase 0: Parse Arguments and Resolve Context

**0a. Mode.** Read the first argument: `new`, `update <resource>`, `reconcile`, `review` or `breaking-check`, plus an
optional `--review full|lean|solo` that overrides the resolved `review_mode` for this run. No argument:

- no contract under `docs/api/` (none of the catalog globs above match) ⇒ `new`, announced;
- a contract exists ⇒ ask with `AskUserQuestion`: `Update a resource` / `Reconcile with the UX specs` /
  `Review the contract` / `Breaking-change check`.

`update`, `reconcile`, `review` and `breaking-check` need an existing contract; without one, stop and say
"No contract under `docs/api/` — run `/api-design new` first." `new` with a contract already present asks whether
the user meant `update` — it never overwrites a contract.

**0b. Backend condition.** The product has an API to design when the *Backend* condition holds:
`stack.layers.backend.framework` set, **or** `stack.layers.data.database` set, **or** `api` in `platform.surfaces`.
Read it from the config block above — the `stack` line (`backend=` / `data=` entries versus the `unset=` list) and
the `platform.surfaces` line.

- **Known false** — the stack is configured, `backend` and `data` are both in `unset=`, and `platform.surfaces` is
  set without `api`. Print exactly
  `NOT ASSESSED — no backend layer, data layer or api surface configured` and stop. Suggest `/setup-stack` if the
  configuration is wrong.
- **Unknown** — `stack: unset — run /setup-stack`, or `platform.surfaces` unset while backend and data are unset.
  Unset is not "no backend": continue, and print
  `Backend condition unknown (stack or surfaces unset) — proceeding; run /setup-stack to record it.`
- **True** — continue.

**0c. Tier.** `workflow` decides how strict the prerequisites are (see `.claude/docs/workflow-modes.md`):

- `standard` / `full` — the Architecture step is required; Phase 1 requires an **Accepted** API-style ADR.
- `minimal` — the step is optional (the skill still runs when asked); the API style is chosen in Phase 1 without
  an ADR and recorded in the guidelines' `**API Style**` line as "no ADR — minimal tier".

**0d. Values without a config label.** Read these from `project.yaml` with Read (they have no `resolve_config` label;
`project.local.yaml` is not consulted for them):

- `naming.api_paths`, `naming.api_fields` — path and field casing. Unset ⇒ propose `kebab-case` paths and
  `camelCase` fields in Phase 2 and record the choice in the guidelines (never write `naming.*` from here).
- `commands.api_lint` — the lint command for Phase 5 (a string, or an OS map with `default` / `linux` / `macos` /
  `windows` entries: use the entry for the current OS, else `default`).
- `localization.locales` — supported locales for the guidelines' `## Internationalization`.

**0e. Automation.** Contract writes belong to the `schema_changes` category. It is in the default
`automation_always_ask` list shown in the config block, so every contract write prompts in every mode unless the
user removed it. Independently of the list, a BREAKING change is a Major decision
(`.claude/docs/automation-modes.md` `## Major vs Minor Decision Classification`), and the version-bump-or-deprecation
choice is never made by the skill — without the user's decision the verdict stays
`BREAKING CHANGE — ACTION REQUIRED`.

**0f. Agents this run may use** (announce the list; a skipped one is named, never silent):

| Agent | Phase | Condition |
|---|---|---|
| `tech-lead` | 3 (resource model), 7 (developer guides) | always |
| routed backend sub-specialist, or `backend-specialist` | 3 (implementability, framework idioms) | backend layer configured — read `backend-specialist>…` from the `[routing: …]` part of the `stack` line; unset ⇒ `NOT CHECKED — backend layer not configured (run /setup-stack)` |
| `security-engineer` via **SE-SECURITY-REVIEW** | 7 | review-mode check (Phase 7a) |
| `frontend-engineer` (web) and/or `mobile-engineer` (ios, android) | 7 (consumer review) | `workflow` is `full`, per `platform.surfaces`; offered at `standard` |
| `ux-writer` | 7 (developer guides) | Public API — `api` in `platform.surfaces` |

---

## Phase 1: Load Context

Read what exists; name what does not. Read long documents by section (`Grep` the `^## ` headings first), never a
speculative read of every file.

1. **PRDs** — `design/prd/*.md`: `## Functional Requirements`, `## Non-Functional Requirements` (security & privacy,
   performance), `## Business Rules & Calculations` (limits, fees, rounding the API must enforce) and the non-contract
   `## API & Data Impact` when present. At `minimal`, read `design/product/one-pager.md` instead.
2. **Architecture** — `docs/architecture/architecture.md` (layers, clients, BFF or not, environments) and
   `docs/registry/architecture.yaml` (`interfaces`, `data_ownership` — the contract must not contradict a registered
   stance).
3. **API-style ADR** — Grep `docs/architecture/adr-*.md` for ADRs whose `## Stack Compatibility` `**Domain**` is
   `API` or whose `## Decision` names the API style, and read their `## Status`.
   - `standard` / `full`, **no Accepted ADR decides the style** ⇒ STOP:
     "The API style (REST/OpenAPI, GraphQL, gRPC, events) is a Foundation decision and has no Accepted ADR. Run
     `/architecture-decision api-style` — or, if the ADR exists as Proposed, `/architecture-decision accept ADR-NNNN`
     — then re-run `/api-design`." Write nothing.
   - `minimal` — ask with `AskUserQuestion`: `OpenAPI 3.1 (REST) — recommended` / `GraphQL` / `gRPC (protobuf)` /
     `AsyncAPI (events only)`.
4. **Data model** — `docs/data/data-model.md`: entities, field classification (`PII`, `Sensitive-PII`), ownership.
   Absent ⇒ note `Data model: not yet written — PII flags in the contract come from the PRDs and are re-checked by
   /data-model`.
5. **Guidelines and contract** — `docs/api/api-guidelines.md` and the existing contract(s), when present.
6. **Traceability** — `docs/architecture/tr-registry.yaml`: the `TR-<feature>-NNN` IDs each operation implements.
7. **Threat model** — `docs/security/threat-model.md` (path passed to the security review; absent is `"none"`).
8. **Stack reference** — for the backend framework and any codegen tool the team uses, `docs/stack-reference/VERSION.md`
   and `docs/stack-reference/<component>/`. Version-sensitive advice without a reference is `NOT SOURCEABLE — run
   /setup-stack refresh`, never a guess.

Present a short context summary — sources read, sources missing, the API style and where it was decided, the
consumers (`platform.surfaces`), whether this is a **Public API** (`api` in `platform.surfaces`), and the resolved
`compliance` line — before any drafting.

---

## Phase 2: Guidelines

Runs on the first run (`new`) and in `update` when the change needs a rule changed. Skipped with a one-line note
when the guidelines exist and no rule changes.

Draft `docs/api/api-guidelines.md` from `.claude/docs/templates/api-guidelines.md`, one section at a time, each
presented with the recommended default and the alternatives, and approved before the next:

1. `## Versioning` — scheme; BREAKING / NON-BREAKING classes; mobile version skew (minimum supported app version).
2. `## Resource Naming` — `naming.api_paths` / `naming.api_fields`, IDs, enum values, `operationId` style.
3. `## Error Model` — RFC 9457 problem details, the status-code table, the stable `code` extension.
4. `## Pagination` — cursor by default; limits.
5. `## Filtering & Sorting` — allowlists; unknown filter ⇒ 400.
6. `## Idempotency Keys` — which operations require the header; retention window; replay rules.
7. `## Rate Limits` — classes, keys, headers; business-flow abuse caps (OTP and SMS pumping, sign-up rewards).
8. `## Auth Scopes` — schemes per consumer; the scope catalog; object-, property- and function-level rules.
9. `## Deprecation` — window, `Deprecation` / `Sunset` headers, communication. **For a Public API the window is a
   number** — Phase 6 checks deprecations against it.
10. `## Timestamps & Timezones` — RFC 3339 UTC; business dates in a named timezone (`Asia/Seoul` for Korea).
11. `## Money & Currency` — integer minor units + ISO 4217 code; **KRW has no minor unit**; server-side computation.
12. `## Internationalization` — `Accept-Language`, codes not text, NFC, E.164 phones, Korean addresses.

Keep every template heading exactly as spelled (English); write the body in the user's conversation language. When
`compliance.regions` includes a region, the security-relevant rules (consent before marketing messages, data export
and deletion operations) name the matching topics in `.claude/docs/compliance/<region>.md` as items to verify — never
as legal facts with numbers.

Ask: "May I write this to `docs/api/api-guidelines.md`?" In `update` mode, show the diff of the changed section only.

---

## Phase 3: Resource Modelling (`new`, `update <resource>`)

Section by section with approval: **one table per PRD feature** (for `update`, the named resource only).

**Scope of `new`.** The initial contract covers the Foundation and Core resources — auth/session, account, and the
core domain entity (for Moa: sessions with email, Kakao, Naver and Apple sign-in; the account (`/me`, consents,
account deletion); savings goals). Say which features are left for later `update` runs or for `reconcile`, so the
first contract stays reviewable.

For each feature, derive the operations from its PRD's `## Functional Requirements` and acceptance criteria, then
present:

| Operation (`operationId`) | Method + path | Auth scope | Request schema | Response schema | Errors (`code`) | Idempotent? | PII fields | TR-IDs |
|---|---|---|---|---|---|---|---|---|
| `listGoals` | `GET /v1/goals` | `goals:read` (owner) | — (query: `cursor`, `limit`, `status`) | `GoalList` | — | yes (safe) | `name`, `targetAmount`, `savedAmount`, `targetDate` | TR-goals-001 |
| `createGoal` | `POST /v1/goals` | `goals:write` | `CreateGoalRequest` | `Goal` (201) | `GOAL_LIMIT_REACHED`, `VALIDATION_FAILED` | `Idempotency-Key` required | `name`, `targetAmount`, `targetDate` | TR-goals-002 |

Rules applied while drafting (from the guidelines):

- Every operation has an auth scope and an ownership rule; anonymous operations say why.
- Every list is paginated; every unsafe operation that moves money or has an external side effect requires
  `Idempotency-Key`.
- **PII fields** are the fields the data model classifies `PII` or `Sensitive-PII` (or, before the data model exists,
  the PRD's `## Non-Functional Requirements` names). They are marked `x-data-classification` in the contract.
  A field nobody classified is flagged `unclassified`, never assumed `Internal`.
- An operation with no TR-ID is either traced to a requirement now or listed as "untraced" for
  `/architecture-review` — never silently accepted.
- Protected fields (`ownerId`, `plan`, `role`, balances) are never writable by the client.

**Consult before approval (parallel).** Spawn both `Agent` calls before waiting for either:

- `tech-lead` — resource boundaries versus `docs/registry/architecture.yaml` `data_ownership`, naming against the
  guidelines, operations that belong to another module, N+1 and chatty-client risks.
- The routed backend sub-specialist (for example `node-specialist` for NestJS, `spring-specialist` for Spring Boot,
  `python-specialist` for FastAPI or Django), or `backend-specialist` when no sub is routed — how the handlers stay
  honest to the contract in this framework (contract-first code generation, or code-first with a CI diff against
  the contract), validation libraries, and anything the framework makes awkward. It consults
  `docs/stack-reference/<component>/` for version-specific answers.

Present their findings next to the table; disagreements go to the user, never resolved silently. Then approve the
table (`AskUserQuestion`: `Approve` / `Revise` / `Discuss`) and move to the next feature.

---

## Phase 3R: UX Reconciliation (`reconcile`)

Validation-phase check that the contract serves the screens as specified.

1. **UI condition.** `platform.surfaces` has none of `web`, `ios`, `android` (known, not unset) ⇒ there are no screens
   to reconcile: say "No UI surface — nothing to reconcile" and stop without writing. Unset surfaces ⇒ ask.
2. **Read the screen specs.** Every `design/ux/*.md` whose H1 starts `# UX Spec:` (never `design/ux/reviews/`). Flow
   specs (`# User Flow:`), the app shell and the interaction pattern library carry no `## API Data` section — a
   flow's operations sit in the `## API Data` of its steps' screen specs — so they are not read here. No screen spec
   at all ⇒ stop: "No UX specs yet — run `/ux-design` for the key screens, then `/api-design reconcile`." Write
   nothing.
3. **Collect every operation** each screen spec's `## API Data` table names — columns
   `| Operation | Endpoint (Owning) | Called When | Data Used on Screen | Pagination | Auth | Contract Status |`,
   `Contract Status` one of `in contract`, `proposed`, `mismatch` (the author's claim; step 4 classifies from the
   contract itself) — plus the **Writes**, **Aggregation**, **Freshness** and **Realtime** lines under the table
   (Writes carry the idempotency expectation; Aggregation names CHATTY candidates). A screen spec without the section
   is listed as `NOT CHECKED — <spec path> has no ## API Data section` — the run cannot then report `CONTRACT READY`.
4. **Compare with the contract** and classify each reference:

| Status | Meaning | Typical resolution |
|---|---|---|
| MATCH | the operation exists and returns what the screen needs | none |
| MISSING | the screen needs an operation the contract lacks | add it (Phase 4) |
| MISMATCH | shape differs: missing field, wrong pagination, a field the screen needs is not exposed | add an optional field / parameter (NON-BREAKING) or revise the spec |
| CHATTY | the screen needs several round trips for one view | aggregation or backend-for-frontend operation, or embed a summary |
| UNUSED | a contract operation no screen or known consumer calls | keep (partners, jobs) or mark for removal later — never removed here |

5. Propose the contract changes as a Phase 3 table (new and changed operations only) and consult `tech-lead` and the
   routed backend sub-specialist on it as in Phase 3. Approved changes go through Phases 4–7. A change the user
   rejects stays in the record as an open item with the spec it affects.
6. **No differences** ⇒ nothing to write to the contract, but Phase 8 still writes the change record — a "no change"
   record is the evidence that reconciliation ran.

---

## Phase 4: Write the Contract

**Style and file** (from the ADR, or the Phase 1 choice at `minimal`):

| Style | File | Starting point and conventions |
|---|---|---|
| OpenAPI 3.1 (REST) — default | `docs/api/openapi.yaml` | Copy `.claude/docs/templates/openapi-skeleton.yaml`: keep `components` (security schemes, `Problem`, `Cursor`, `Limit`, `IdempotencyKey`, shared responses and headers), replace the example `/goals` paths with the approved operations, fill `info` and `servers` (local, staging). |
| GraphQL | `docs/api/schema.graphql` | SDL with Relay-style connections for lists (`first`/`after`, `pageInfo`), input types per mutation, a `clientMutationId` or idempotency argument on money-moving mutations, errors as typed results or `extensions.code` matching the guidelines' codes, `@deprecated(reason:)` with the sunset date. |
| gRPC | `docs/api/<service>.proto` | `proto3`, versioned package (`moa.goals.v1`), `google.rpc.Status` with `ErrorInfo.reason` as the stable code, page tokens for lists, `reserved` for every removed field number or name. |
| Events | `docs/api/asyncapi.yaml` | AsyncAPI 3.0: channels, operations (send/receive), message schemas with a schema version, the publisher and consumer of each message, delivery guarantee and idempotency key (event ID). |

A product can have more than one (REST for clients plus AsyncAPI for events); each file follows its own row.

**Writing rules:**

- Descriptions are single-line double-quoted strings (`\n` for a line break) — the data-file hooks fall back to a
  line-based check when PyYAML is not installed.
- Examples are synthetic: `example.com` addresses, obviously fake phone numbers, generated IDs; no real tokens or
  keys (`validate-commit` blocks known key formats).
- Every operation carries `operationId`, `security`, `x-requirements` (TR-IDs), at least one 4xx and one 5xx
  response using the shared problem responses, and request/response examples.
- `x-data-classification` on every field the data model (or the PRD) classifies `PII` or `Sensitive-PII`.
- A `new` contract starts at `info.version: 0.1.0`; later versions follow the guidelines' `## Versioning`.

Show the full draft (or, for `update` / `reconcile`, the diff), then ask:
"May I write this to `docs/api/openapi.yaml`?" (or the chosen file). This write is the `schema_changes` category.
After the write, the `validate-data-files` hook parses the file; an `Invalid YAML` message means fix it before any
other step.

---

## Phase 5: Lint

1. **`commands.api_lint` set** — run it with Bash (for example `npx @redocly/cli lint docs/api/openapi.yaml`,
   `npx @stoplight/spectral-cli lint docs/api/openapi.yaml`, `buf lint`, `asyncapi validate docs/api/asyncapi.yaml`).
   Report errors and warnings with their rule IDs; errors make the verdict at least `NEEDS REVISION`. A command that
   cannot start (tool missing, network needed) is reported as `NOT CHECKED — api_lint could not run: <reason>` and
   the structural self-check below becomes the lint result.
2. **No linter configured** — say `commands.api_lint is not set (set it with /settings or /setup-stack)` and offer
   the **structural self-check** (`AskUserQuestion`: `Run the self-check` / `Skip`). It reads the contract and checks:
   - every operation has a unique `operationId`, a `security` entry (or `security: []` with a stated reason), at least
     one 4xx and one 5xx response, and request/response examples;
   - error responses use `application/problem+json` and the shared `Problem` schema;
   - list operations take `cursor`/`limit` (or the style's equivalent) and state a default sort;
   - money-moving or side-effecting unsafe operations require `Idempotency-Key`;
   - every `$ref` resolves; paths and fields follow the guidelines' naming;
   - fields classified `PII` / `Sensitive-PII` in `docs/data/data-model.md` carry `x-data-classification`
     (`NOT CHECKED — no data model` when it does not exist);
   - no secrets, real personal data or credentialed URLs in examples and `servers`.
3. **No linter and the self-check declined** ⇒ lint is `NOT ASSESSED` and so is the run's verdict unless a failure
   outranks it.

---

## Phase 6: Breaking-Change Check

1. **Baseline.** `git show HEAD:<contract path>` via Bash. The file is new (not in `HEAD`) ⇒ "first version — no
   baseline; breaking-change check N/A" and skip the rest of this phase. The working tree equals `HEAD` (already committed) ⇒
   say so and ask which commit to compare against; without an answer the check is `NOT ASSESSED`.
2. **Diff and classify** every change as `BREAKING` or `NON-BREAKING`:
   - **BREAKING**: removed operation, field or parameter; type or format change; a new **required** request field or
     parameter; enum narrowing in a request; a response field made optional or nullable; stricter validation;
     changed auth scope, status code, error `code`, default value or pagination order.
   - **NON-BREAKING**: new operation; new optional request field or parameter; new response field; enum widening in a
     request; relaxed validation.
   - **Watch list** (NON-BREAKING by rule, always listed): a new enum value in a response and a new error `code` —
     generated mobile clients that switch exhaustively may break.
   - Style specifics: GraphQL — a removed field or type, a changed field type, a new required argument, nullable →
     non-null on an input; proto — a changed field number or type, a removed field without `reserved`; AsyncAPI —
     the JSON Schema rules above applied to message payloads.
   - When a diff tool is already installed (`oasdiff`, `buf breaking`, `graphql-inspector diff`), offer to run it and
     reconcile its result with the table; never install one.
3. **Any BREAKING change** — `schema_changes` always-ask, and a decision per change with `AskUserQuestion`:
   - `Version bump` — a new major version (`/v2/...` or a new `Api-Version` date) alongside the old one;
   - `Deprecate and keep both` — the old shape stays with `deprecated: true`, `Deprecation` and `Sunset` headers;
   - `Make it non-breaking` — revise (keep the old field, add an optional new one) and return to Phase 4;
   - `Coordinated change` — only when every consumer deploys together with the API (a web client served from the
     same deploy, no mobile app, no partner). Not offered when `api`, `ios` or `android` is in `platform.surfaces`.
   **Public API** (`api` in `platform.surfaces`): a deprecation must carry a `Sunset` date at least the window stated
   in `docs/api/api-guidelines.md` `## Deprecation` away, and the release notes need an `## API / Developers` entry
   (`/release-notes`) — both are recorded in the change record. A BREAKING change left without a decision keeps the
   verdict at `BREAKING CHANGE — ACTION REQUIRED`.

---

## Phase 7: Review

### 7a. SE-SECURITY-REVIEW

**Review mode check** — apply before spawning SE-SECURITY-REVIEW (`--review` overrides the resolved `review_mode`):

- `full` → spawn as normal.
- `lean` → **skip every gate whose ID does not end in `-PHASE-GATE`**. Note: `[GATE-ID] skipped — Lean mode`
  SE-SECURITY-REVIEW does not end in `-PHASE-GATE`, so lean skips it: record `[SE-SECURITY-REVIEW] skipped — Lean mode`.
- `solo` → skip all gates. Note: `[SE-SECURITY-REVIEW] skipped — Solo mode`.

A skipped review is recorded where the verdict line would go (Phase 8), and the summary names it:
"SE-SECURITY-REVIEW not consulted — <Mode> mode; `--review full` runs it, or run `/security-audit api` later."

When it runs, spawn `security-engineer` via `Agent`:

- Gate: **SE-SECURITY-REVIEW** — the prompt instructs the agent to read
  `.claude/docs/director-gates/se-security-review.md` first (do not read it or paste it yourself).
- Pass: artifact path (contract, data model or ADR) · operations or entities with auth scope and PII classification · resolved `compliance` line · `docs/security/threat-model.md` path (or "none")
- Fill them from this run: the contract path; the operation table of Phase 3 / 3R (operation, method + path, auth
  scope, PII fields) — for `review`, every operation; the `compliance` line of the config block; the threat model
  path, or "none".

Parse the first line of the reply as `[SE-SECURITY-REVIEW]: TOKEN` (the brackets are literal), TOKEN one of `APPROVE`,
`CONCERNS`, `REJECT`, and map it with the verdict classes of `.claude/docs/director-gates.md` (`## Standard Verdict Format`):

- **APPROVE-class** (`APPROVE`) → continue. Record `APPROVED <date>`.
- **CONCERNS-class** (`CONCERNS`) → present the findings with `AskUserQuestion`: `Revise flagged items` /
  `Accept and proceed` / `Discuss further`. Revising returns to Phase 4 for the affected operations and re-runs
  Phases 5–6; record `REVISED <date>` or `CONCERNS (accepted) <date>`.
- **REJECT-class** (`REJECT`) → present the blockers (an operation without object-level authorization, a
  money-moving webhook without verification …). Offer to revise now (Phase 3 → 4 for the affected operations, then
  spawn the gate again). Unresolved ⇒ verdict `NEEDS REVISION`, no further writes except the change record, and the
  review line reads `pending — REJECT findings unresolved <date>`.
- A first line that does not parse, or names another gate, is not an approval — treat it as CONCERNS-class and say
  the verdict line was missing.

### 7b. Consumer review (`workflow: full`; offered at `standard`)

Spawn, in parallel, `frontend-engineer` when `web` is in `platform.surfaces` and `mobile-engineer` when `ios` or
`android` is. Ask each to review the contract as its client: round trips per screen, payload size, pagination fit
for infinite scroll, fields needed for offline sync (`updatedAt`, `ETag`), error codes mappable to UI states,
nullability, ergonomics of the generated client (their stack's generator), and — for mobile — behaviour of shipped
app versions under each change (version skew). Their findings are advice, not gate verdicts: present them and let
the user decide what goes back to Phase 3.

### 7c. Developer guides (Public API only)

When `api` is in `platform.surfaces`, offer developer guides (`AskUserQuestion`: `Draft guides now` / `Later`).
`ux-writer` drafts, `tech-lead` reviews for accuracy against the contract. Typical set:
`docs/api/guides/getting-started.md`, `authentication.md`, `pagination-and-errors.md`, `idempotency.md`,
`webhooks.md`, `deprecations.md`. Each guide uses only synthetic examples. Ask
"May I write this to `docs/api/guides/<slug>.md`?" per guide (or once for the listed set).

---

## Phase 8: Change Record

Written by `update` and `breaking-check` (when the contract differs from `HEAD`), and **always** by `reconcile` —
including a "no change" record. `new` writes no change record: the first contract is its own baseline, and the
Validation step's glob must stay unmatched until reconciliation actually runs.

Path: `docs/api/changes/api-change-YYYY-MM-DD.md` (today's date; if that file exists, the suffix `-2`, `-3`, …).

```markdown
# API Change: YYYY-MM-DD

> **Verdict**: <CONTRACT READY | NEEDS REVISION | BREAKING CHANGE — ACTION REQUIRED | NOT ASSESSED>
> **Mode**: <update <resource> | reconcile | breaking-check>
> **Contract**: `docs/api/openapi.yaml` (info.version <old> → <new>)
> **Baseline**: `HEAD` <short commit> | <commit the user named> | none — first version
> **Security Engineer Review (SE-SECURITY-REVIEW)**: <APPROVED YYYY-MM-DD | CONCERNS (accepted) YYYY-MM-DD | REVISED YYYY-MM-DD | pending — REJECT findings unresolved YYYY-MM-DD | not run — contract unchanged | not run — breaking-check mode>

## Summary
<two or three sentences: what changed and why>

## Changes
| # | Operation / schema | Change | Class | Consumers affected | Rationale | TR-ID / UX spec |
|---|---|---|---|---|---|---|
<or: "No change — every operation referenced by the reviewed UX specs exists in the contract and matches.">

## UX Reconciliation
<reconcile only: | UX spec | Operation from `## API Data` | Status (MATCH / MISSING / MISMATCH / CHATTY / UNUSED) | Resolution |>
<plus one `NOT CHECKED — <spec path> has no ## API Data section` line per spec without the section>

## Breaking Changes & Plan
<each BREAKING change: decision (version bump / deprecate and keep both / coordinated change), Sunset date and window
check for a Public API, the `## API / Developers` release-notes entry to add, minimum app version affected — or "None">

## Checks
- Lint: <tool and result | structural self-check result | NOT ASSESSED — no linter, self-check declined>
- Breaking-change check: <result | N/A — first version | NOT ASSESSED — <reason>>
- Consumer review: <frontend-engineer / mobile-engineer findings | not run — workflow <tier>>
- Skipped: <every NOT CHECKED line of this run>

## Follow-ups
<stories to create or update (`**API Contract**` field), contract tests, `/data-model` changes, guide updates>
```

When review mode skipped the gate, the fifth header line is the skip note instead —
`> [SE-SECURITY-REVIEW] skipped — Lean mode` (or `— Solo mode`). `not run — contract unchanged` is for a
`reconcile` with no differences (nothing new to review); `not run — breaking-check mode` names that this mode has no
review phase — run `/api-design review` when the changed operations need one.

For `new` (no change record) and `review`, the review outcome is recorded in the contract's own header comment,
the line starting `# Security Engineer Review (SE-SECURITY-REVIEW):` (`#` for YAML and GraphQL, `//` for proto).

**Verdict** (precedence as above):

- `BREAKING CHANGE — ACTION REQUIRED` — a BREAKING change without a decision, or a Public API deprecation whose
  `Sunset` is inside the guidelines' window.
- `NEEDS REVISION` — lint errors; a self-check failure; an unresolved SE REJECT; CONCERNS the user chose to revise
  later; MISSING or MISMATCH operations left open in `reconcile`.
- `NOT ASSESSED` — lint neither ran nor was replaced by the self-check; a screen spec without `## API Data`; no baseline
  when one was needed. A run that stops early — Phase 0 (no contract for a mode that needs one, no backend layer,
  data layer or api surface), Phase 1 (no Accepted API-style ADR at `standard` / `full`) or Phase 3R (no UI surface,
  no screen spec) — writes nothing and ends with `Verdict: NOT ASSESSED — <the stop message>`.
- `CONTRACT READY` — everything above ran and passed (a gate skipped by review mode is recorded, not a failure).

Ask: "May I write this to `docs/api/changes/api-change-YYYY-MM-DD.md`?" In `review` mode nothing is written; the
same sections are reported in the conversation, and the review outcome line is written into the contract header only
if the user agrees ("May I write this to `docs/api/openapi.yaml`?").

---

## Phase 9: Close

Print the verdict line `Verdict: <TOKEN>`, the files written, and every `NOT CHECKED` line. Then close with
`AskUserQuestion`, offering only what applies:

- after `new` (Architecture): `/data-model` (entities, classification and migrations for the resources just
  designed) · `/api-design update <resource>` (the next feature) · `/security-audit threat-model` (when
  `privacy.handles_pii` is true or unset and `docs/security/threat-model.md` does not exist) ·
  `/architecture-review` in a fresh session · stop here;
- after `reconcile` (Validation): `/create-epics` (epics now see the reconciled contract) · `/ux-design <screen>`
  for specs that lacked `## API Data` · stop here;
- after `update` or `breaking-check` with BREAKING changes: `/release-notes` (the `## API / Developers` entry) ·
  `/rollout-plan` (deprecation and version rollout) · `/create-stories` (implementation and contract-test stories) ·
  stop here;
- after `review`: `/api-design update <resource>` for each operation that needs revision · stop here.

---

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and `autonomous` modes see
`.claude/docs/automation-modes.md`; the resolved `automation_always_ask` categories (`schema_changes` by default) and
every BREAKING decision prompt in all modes.

1. **Question → Options → Decision → Draft → Approval** for every guideline section and every feature's resource
   table. Recommend a default, name the alternatives, and let the user decide.
2. **"May I write this to `<path>`?"** before every write — guidelines, contract, change record, guides, the review
   line in the contract header. A multi-file write is approved as one listed changeset.
3. **Agents advise; the user decides.** `tech-lead`, the backend specialist, the consumer reviewers and
   `security-engineer` findings are shown side by side; conflicts are surfaced, never resolved silently.
4. **Unset is not "no".** An unset `platform.surfaces`, `compliance` or `privacy.handles_pii` is a question to ask,
   never a reason to skip a check.
5. **Skips announce themselves.** A skipped gate, consult, lint or UX spec appears as a `NOT CHECKED` line in the
   summary and in the change record.
6. **No commits.** Committing the contract is the user's decision.
7. **The next step is offered, never taken.** The closing widget (Phase 9) recommends the next skill — `/data-model`
   after `new`, `/create-epics` after `reconcile`, `/release-notes` after a BREAKING change — and waits for the
   user's choice.
