---
name: data-model
description: "Data model (ownership, classification, retention, indexes) and expand/contract migration plans."
argument-hint: "[model | migration <slug> | review] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/data-model/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,automation_always_ask,workflow,stack,compliance,code_roots`

Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

# Data Model

This skill owns the product's **operational data design**: what the entities are, which module owns each one,
how every field is classified, how long personal data lives and how it is erased, which indexes serve which access
patterns, and how the schema changes safely over time. Its artifacts are what gate-validation checks for a product
with a backend (`docs/data/data-model.md` with data classification and a migration strategy), what gate-hardening
checks before code freeze (every migration's Expand applied on staging, every Contract scheduled), and what a story
with a `**Migration**` field is built against.

A migration is the change with the largest blast radius a service team makes. This skill therefore plans every
non-additive schema change as **Expand → Migrate → Contract**, and holds the **migration floor**: a story whose
`**Migration**` is not `None` (any Type) requires `production/qa/evidence/<story-slug>/migration-dry-run.log` —
Expand applied and rolled back on a disposable database — at every `qa.level` and regardless of
`testing.strict.config`; absent ⇒ BLOCKING.

### Modes

| Mode | When | Phases | Writes |
|---|---|---|---|
| `model` | Architecture: first data model, or an update after PRD or contract changes (default when `docs/data/data-model.md` does not exist) | 0 → 1 → 2 … 10 → 13 | `docs/data/data-model.md`; `project.yaml` `privacy.handles_pii` (asked); `docs/registry/architecture.yaml` `data_ownership` (asked) |
| `migration <slug>` | A schema or data change that is not purely additive, or any change a story will carry as `**Migration**` | 0 → 1 → 11 → 13 | `docs/data/migrations/NNNN-<slug>.md`; optional migration files under `stack.layers.data.migrations_dir`; the dry-run log for a story |
| `review` | Before a release, or when `/adopt` or `detect-gaps` finds migrations without plans | 0 → 1 → 12 → 13 | nothing (report in conversation) |

### Outputs

| Path | Mode | Notes |
|---|---|---|
| `docs/data/data-model.md` | `model` | from `.claude/docs/templates/data-model.md` — nine contract sections |
| `docs/data/migrations/NNNN-<slug>.md` | `migration` | from `.claude/docs/templates/migration-plan.md`; `NNNN` = next four-digit number in `docs/data/migrations/` |
| migration files under `stack.layers.data.migrations_dir` (optional) | `migration` | drafted by `data-specialist` / `backend-engineer`, written only after approval (`db_migrations`) |
| `production/qa/evidence/<story-slug>/migration-dry-run.log` | `migration` | only when a dry run is executed for a story |
| `project.yaml` (`privacy.handles_pii`, ask first) | `model` | only when a field is `PII` / `Sensitive-PII` and the key is unset or contradicts the model |
| `docs/registry/architecture.yaml` (`data_ownership`) | `model` | sync of `## Ownership`, asked; entries are never deleted |

### Verdicts

| Mode | Tokens | Precedence |
|---|---|---|
| `model` | `MODEL READY` · `NEEDS REVISION` · `NOT ASSESSED` | NEEDS REVISION > NOT ASSESSED > MODEL READY |
| `migration` | `SAFE` · `RISKY — MITIGATION REQUIRED` · `UNSAFE` · `NOT ASSESSED` | UNSAFE > RISKY — MITIGATION REQUIRED > NOT ASSESSED > SAFE |
| `review` | `PASS` · `CONCERNS` · `FAIL` · `NOT ASSESSED` | FAIL > CONCERNS > NOT ASSESSED > PASS |

The data model and every migration plan carry their verdict directly under the H1: `> **Verdict**: <TOKEN>`.

### What this skill never does

- Run a migration, a backfill or any query against a shared, staging or production database. Staging and production
  migrations run in the deploy pipeline; verification queries in a plan are run by a human.
- Read `.env` files, secret stores or connection strings to find a database (`secrets_access`).
- Query, sample or export personal data (`pii_data_access`) — the model is designed from PRDs, the contract and the
  schema, never from rows.
- Write `modes.*` keys or any of the six knobs `modes.rigor` fronts; in `project.yaml` it writes only
  `privacy.handles_pii`, and only after asking.
- State a legal retention period as fact. A period that comes from a law carries
  `(Source: <url>, retrieved YYYY-MM-DD)` or is written `NOT SOURCEABLE — confirm with counsel`.

---

## Phase 0: Parse Arguments and Resolve Context

**0a. Mode.** First argument `model`, `migration <slug>` or `review`, plus an optional `--review full|lean|solo`
that overrides the resolved `review_mode`. No argument:

- `docs/data/data-model.md` does not exist ⇒ `model`, announced;
- it exists ⇒ ask with `AskUserQuestion`: `Update the data model` / `Plan a migration` / `Review migrations against
  plans`.

`migration` needs a slug in kebab-case (`goal-target-date`); ask for one if missing. `migration` and `review` without
a data model continue, with the note `Data model not written — plan checks against the model are NOT CHECKED`.

**0b. Server-side data.** Read the `stack` line of the config block. A `backend=` or `data=` entry means the product
has server-side data — continue. When the stack is configured and both `backend` and `data` are in its `unset=`
list, the catalog step may not apply (it is required only when the product has a backend): say so and ask whether
to continue — for example for an on-device store. `stack: unset — run /setup-stack` is unknown, not "no data":
continue with the note `Stack unset — proceeding; run /setup-stack to record the data layer.`

**0c. Tier.** `workflow`: `standard` / `full` — the Architecture step requires the data model; `minimal` — optional,
run on request. The migration floor applies at every tier.

**0d. Stack and roots.**

- Data layer: the `data=` entry of the `stack` line (for example `data=PostgreSQL 16`). The ORM, cache and queue
  components are read from `stack.layers.data` in `project.yaml` with Read when the line does not show them. Data
  layer unset ⇒ `NOT CHECKED — data layer not configured (run /setup-stack)`; store-specific checks (locks, online
  DDL, index types) become `NOT ASSESSED`.
- `code_roots` line: `data=<migrations_dir>` is where executable migrations live; the `backend=` roots are where the
  ORM schema lives (`schema.prisma`, TypeORM or JPA entities, SQLAlchemy or Django models). No code root resolved ⇒
  print `NOT CHECKED — no code root resolved (set stack.layers.<layer>.root via /setup-stack)` and skip the
  brownfield scan. Undeclared roots are included in the scan with the line
  `WARN: undeclared code roots: <dirs> — declare them with /setup-stack`.
- Read from `project.yaml` with Read (no config label): `naming.db_tables`, `naming.db_columns` (unset ⇒ propose
  `snake_case` and record it in the model's header, never in `project.yaml`), `commands.migrate` (the dry-run
  command; a string or an OS map — use the current OS entry, else `default`).

**0e. Compliance.** The `compliance` line gives `regions=` and `handles_pii=`. Each region listed selects
`.claude/docs/compliance/<region>.md` (`## Privacy & Data Protection`, `## Marketing Messages & Consent`) as a
checklist of topics for Phases 4–5. `(unset -- ask)` is an open question — ask it; it never means "no obligations".
`regions=none` means the user chose none: skip the regional topics and say so.

**0f. Automation.** `db_migrations` (drafting or running any migration or backfill) and `pii_data_access` (querying
or exporting personal data) are in the default `automation_always_ask` list: they prompt in every mode unless the
user removed them — and this skill never runs against a shared database or reads personal data whatever the list
says.

**0g. Agents this run may use** (announce the list; a skipped one is named):

| Agent | Where | Condition |
|---|---|---|
| `data-specialist` | model Phases 2, 6, 8; migration Phase 11 | data layer configured; else `NOT CHECKED — data layer not configured (run /setup-stack)` |
| `backend-engineer` | model Phase 7 (transactions, ORM mapping); migration Phase 11 (dual-write, backfill job, migration files) | always |
| `tech-lead` | model Phases 3 and 9 (ownership, consistency); migration Phase 11 (deploy ordering) | always |
| `security-engineer` via **SE-SECURITY-REVIEW** | model Phase 9 | review-mode check (Phase 9b) |

---

## Phase 1: Load Context

Read by section (`Grep` the `^## ` headings first); name every source that is missing.

1. **PRDs** — `design/prd/*.md`: `## Functional Requirements` (entities and states), `## Business Rules &
   Calculations` (amounts, limits, rounding), `## Non-Functional Requirements` (PII fields, retention, authorization
   rules, volumes), `## Success Metrics & Instrumentation` (events that must not carry PII) and the non-contract
   `## API & Data Impact`. At `minimal`: `design/product/one-pager.md`.
2. **Glossary** — `design/registry/entities.yaml` (`entities`, `plans`, `rules`): entity names in the model match it.
3. **Architecture** — `docs/architecture/architecture.md` (modules, services, stores) and the Domain `Data` ADRs
   (Grep `docs/architecture/adr-*.md` for `**Domain**` rows reading `Data`). At `standard` / `full`, no Accepted ADR
   deciding the primary data store is a finding — `Primary data store: no Accepted ADR (run /architecture-decision)`
   — carried into the verdict as NEEDS REVISION unless the user accepts it; it does not stop the run.
4. **Registry** — `docs/registry/architecture.yaml`: `data_ownership` (existing owners — a conflicting claim is
   surfaced before drafting) and `interfaces`.
5. **Contract** — `docs/api/openapi.yaml` (or the style's file): schemas and `x-data-classification` flags, so the
   model and the contract classify the same fields the same way.
6. **Threat model** — `docs/security/threat-model.md` (path for the security review, or "none").
7. **Existing model and plans** — `docs/data/data-model.md`, `docs/data/migrations/*.md`.
8. **Brownfield scan** — when a backend root or the migrations directory has files: the ORM schema and the
   migration history, to reconstruct the current entities before proposing changes. The model then describes what
   exists and marks every intended change as a migration to plan.
9. **Stack reference** — `docs/stack-reference/VERSION.md` and `docs/stack-reference/<component>/` for the database
   and the ORM/migration tool. Version-sensitive claims without a reference are `NOT SOURCEABLE — run /setup-stack
   refresh`.

Present a context summary (sources read and missing, the store, the tool, regions, `handles_pii`, the registry
stances that bind this model) before any drafting.

---

## Model mode — Phases 2 to 10

**How sections are written.** One section at a time: draft → present → approve (`Approve` / `Revise` /
`Discuss`) → write. The first approved section creates `docs/data/data-model.md` from
`.claude/docs/templates/data-model.md` with its verdict line set to `> **Verdict**: NOT ASSESSED` (the model is not
assessed until Phase 10); each later section is written with Edit right after its approval. Each write asks
"May I write this to `docs/data/data-model.md`?". Keep every template heading exactly as spelled (English); write
the body in the user's conversation language. When the file already exists, show and write only the diff of the
sections that change.

## Phase 2: Entities & Relationships

- List the entities the PRDs and the contract need, one row each (entity, table, description, owning module, source
  PRD, TR-IDs), then one field table per entity: type, nullability, default, constraints, classification, notes.
- Types: money as integer minor units or `numeric` (KRW has no minor unit — integer won), instants as
  timezone-aware UTC timestamps, business dates as `date` with the timezone named, identifiers opaque (prefixed
  ULID or UUID) — sequential keys may exist internally but are never an authorization check.
- Invariants become constraints (`CHECK (target_amount > 0)`, one active subscription per user as a partial unique
  index).
- `## Relationships`: a Mermaid `erDiagram` and a table of cardinality, enforcement (foreign key inside a module; ID
  reference across modules) and delete behaviour.
- Consult `data-specialist` on types, constraints and store-specific choices before approval.

## Phase 3: Ownership

- Each entity has exactly **one** owning module or service — its only writer. Readers use the owner's API, events or
  a read replica, never direct writes.
- Compare with `docs/registry/architecture.yaml` `data_ownership`. A conflict is surfaced immediately with options:
  align with the registered owner · supersede it through `/architecture-decision` · record an explicit exception.
  Do not continue past a conflict the user has not resolved.
- Consult `tech-lead` on the boundaries (a module that writes another module's table is a finding).

## Phase 4: Data Classification

- Classify **every** field: `Public | Internal | Confidential | PII | Sensitive-PII` (definitions in the template).
  A field nobody classified stays `unclassified` and keeps the verdict at `NOT ASSESSED` — unset is never read as
  `Internal`.
- Sensitive-PII includes, for the Korean market, 민감정보 and 고유식별정보 (collect a national ID number only where a
  law requires it), identity-verification CI/DI, bank account and card numbers (store the payment gateway's billing
  key, not the number), precise location and health data.
- Build the **PII inventory**: purpose, legal basis or consent, retention, deletion path, protection (field-level
  encryption, tokenisation, masking), and "never in logs or analytics".
- Regional topics from `.claude/docs/compliance/<region>.md` `## Privacy & Data Protection` (purpose limitation,
  pseudonymisation, cross-border transfer for `kr`; lawful basis and data-subject requests for `eu`; CCPA/CPRA
  rights for `us`) are listed as items to verify, never as settled law.

## Phase 5: Retention & Deletion

- One row per data set: retention, trigger, deletion method, exception or legal hold **with its source**.
- The **account erasure path** end to end: grace period, sessions and push tokens revoked, each PII field deleted or
  anonymised, deletion requests to processors (payment gateway, messaging provider, analytics), backups ageing out,
  an audit record without personal data.
- **Consent linkage**: the consent records and which processing depends on which consent. Marketing consent is
  separate from terms acceptance; for `kr`, advertising messages need prior opt-in and separate night-time consent
  (see `.claude/docs/compliance/kr.md` `## Marketing Messages & Consent`), and KakaoTalk 알림톡 carries informational
  messages only.

## Phase 6: Indexes & Access Patterns

- One row per access pattern: the operation (`operationId` from the contract) or job that runs it, the query shape,
  the index, expected rows and rate, and the evidence (`EXPLAIN` plan on production-like volume, or `pending`).
- Cursor-paginated lists need an index ending in the sort key plus the unique tiebreaker. Composite order: equality,
  range, sort. Every index names the access pattern it serves; an access pattern with no index states why a scan is
  acceptable.
- Consult `data-specialist` (partial, covering and expression indexes; write amplification on hot tables; Korean
  full-text search needs a morphological or n-gram analyzer).

## Phase 7: Multi-tenancy, Consistency & Transactions

- `## Multi-tenancy`: the model (per-user ownership for B2C; `tenant_id` + row-level security, schema or database per
  tenant for B2B), how isolation is enforced and tested, how jobs and admin tools are scoped and audited.
- `## Consistency & Transactions`: per operation — tables touched, transaction boundary, isolation, invariant,
  concurrency control. External calls never run inside a database transaction; multi-step flows are sagas with
  compensations; events leave through a transactional outbox; publishers and consumers are idempotent on the event
  ID; idempotency keys are stored under a unique constraint; replica reads only where staleness is acceptable.
- Consult `backend-engineer` on the ORM mapping and transaction handling in the backend framework.

## Phase 8: Migration Strategy

- The tool and its directory (`stack.layers.data.migrations_dir`), file naming, the plan reference in every
  migration file's header comment, the online DDL rules of the store, default lock-wait and statement budgets,
  backfill batch sizes, and deploy ordering (migrations run in the pipeline before the application version that
  needs them — never by hand against a shared database).
- The plan index table (one row per `docs/data/migrations/NNNN-<slug>.md`) and the migration floor statement.
- Consult `data-specialist` on the tool and the store's online-DDL behaviour, citing `docs/stack-reference/`.

## Phase 9: Review

### 9a. Specialist review (parallel)

Spawn both before waiting for either: `data-specialist` (the whole draft: types, constraints, indexes, store
behaviour) and `tech-lead` (ownership, boundaries, consistency, the migration strategy). Show their findings side
by side; disagreements go to the user.

### 9b. SE-SECURITY-REVIEW

**Review mode check** — apply before spawning SE-SECURITY-REVIEW (`--review` overrides the resolved `review_mode`):

- `full` → spawn as normal.
- `lean` → **skip every gate whose ID does not end in `-PHASE-GATE`**. Note: `[GATE-ID] skipped — Lean mode`
  SE-SECURITY-REVIEW does not end in `-PHASE-GATE`, so lean skips it: record `[SE-SECURITY-REVIEW] skipped — Lean mode`.
- `solo` → skip all gates. Note: `[SE-SECURITY-REVIEW] skipped — Solo mode`.

A skipped review is written into the model's header in place of the review line, and the summary names it:
"SE-SECURITY-REVIEW not consulted — <Mode> mode; `--review full` runs it, or run `/security-audit privacy` later."

When it runs, spawn `security-engineer` via `Agent`:

- Gate: **SE-SECURITY-REVIEW** — the prompt instructs the agent to read
  `.claude/docs/director-gates/se-security-review.md` first (do not read it or paste it yourself).
- Pass: artifact path (contract, data model or ADR) · operations or entities with auth scope and PII classification · resolved `compliance` line · `docs/security/threat-model.md` path (or "none")
- Fill them from this run: `docs/data/data-model.md`; the entities with their owner, who may read and write them,
  and each field's classification (from `## Ownership` and the PII inventory); the `compliance` line of the config
  block; the threat model path, or "none".

Parse the first line of the reply as `[SE-SECURITY-REVIEW]: TOKEN` (the brackets are literal), TOKEN one of `APPROVE`,
`CONCERNS`, `REJECT`, and map it with the verdict classes of `.claude/docs/director-gates.md` (`## Standard Verdict Format`):

- **APPROVE-class** (`APPROVE`) → continue; record `APPROVED <date>`.
- **CONCERNS-class** (`CONCERNS`) → present the findings with `AskUserQuestion`: `Revise flagged items` /
  `Accept and proceed` / `Discuss further`. Record `REVISED <date>` or `CONCERNS (accepted) <date>`.
- **REJECT-class** (`REJECT`) → present the blockers (Sensitive-PII without a retention and deletion path, a field
  exposed to a module that must not read it …). Offer to revise the affected sections and spawn the gate again.
  Unresolved ⇒ verdict `NEEDS REVISION`, and the review line reads `pending — REJECT findings unresolved <date>`.
- A first line that does not parse, or names another gate, is not an approval — treat it as CONCERNS-class and say
  the verdict line was missing.

Record the outcome in the model's header line
`> **Security Engineer Review (SE-SECURITY-REVIEW)**: <APPROVED | CONCERNS (accepted) | REVISED> <date>` — or the
skip note `> [SE-SECURITY-REVIEW] skipped — <Mode> mode` in its place.

## Phase 10: Finalize the Model

1. **Verdict**:
   - `NEEDS REVISION` — a `PII` / `Sensitive-PII` field without a retention rule or deletion path; an entity with no
     owner or two writers; an unresolved registry conflict; a list access pattern with neither an index nor a
     justified scan; an unresolved SE REJECT or CONCERNS left to revise; the primary-store ADR missing at
     `standard` / `full` and not accepted as a gap.
   - `NOT ASSESSED` — an `unclassified` field; the data layer not configured (store-specific rules could not be
     checked); a section the user deferred.
   - `MODEL READY` — all nine sections complete and every check above passed (a gate skipped by review mode is
     recorded, not a failure).
   Ask "May I write this to `docs/data/data-model.md`?" to set the verdict line and the review line.
2. **`privacy.handles_pii`** — when any field is `PII` or `Sensitive-PII`:
   - unset ⇒ ask: "May I set `privacy.handles_pii: true` in `project.yaml`?" — on yes, Edit only that key (add the
     `privacy:` block if it is missing); on no, record `handles_pii unset — PII fields exist` as an open item in the
     summary (gates will ask again).
   - `false` ⇒ the model contradicts the project fact: show the PII fields and ask the same question.
3. **Registry sync** — present the `## Ownership` rows as `data_ownership` candidates (new entries; existing entries
   whose owner is unchanged get only a `referenced_by` addition). Follow the field shape of the file's header comment
   and its `data_ownership` example; never delete an entry — a changed owner goes through `/architecture-decision`.
   Ask "May I write this to `docs/registry/architecture.yaml`?"

---

## Phase 11: Migration Plan (`migration <slug>`)

### 11a. Scope and number

- Existing plan with this slug ⇒ ask: `Update phase status` (go to 11h) / `Revise the plan` / `Cancel`.
- New plan: `NNNN` = the highest four-digit prefix in `docs/data/migrations/` + 1 (`0001` for the first).
- Ask which story or stories will carry it (`production/epics/<epic-slug>/story-NNN-<slug>.md`) — "none yet" is
  allowed; the story's `**Migration**` field will point at this plan.

### 11b. The data model comes first

Every column or table the plan adds must already be in `docs/data/data-model.md` with its classification. If not,
stop and update the model first (`/data-model model` — that run carries SE-SECURITY-REVIEW), then return. No data
model at all ⇒ `NOT CHECKED — plan not checked against a data model`, and the plan verdict cannot be `SAFE`.

### 11c. Draft the phases (parallel consult)

Spawn `data-specialist` and `backend-engineer` together (skip `data-specialist` with the NOT CHECKED line when the
data layer is unset):

- `data-specialist` — the DDL per phase for this store and tool, the lock each statement takes, expected duration
  from the table size, online techniques, the lock-wait limit, the rollback per phase, verification queries.
- `backend-engineer` — dual-write code and its flag, the backfill job (batched, idempotent, resumable, throttled),
  the read switch, and which application versions and mobile app versions read the old shape.

Assemble the plan from `.claude/docs/templates/migration-plan.md`:

- **Expand** — additive only. **Migrate** — dual-write, batched backfill, verification queries. **Contract** — only
  after every reader is deployed; for mobile, after the minimum supported app version no longer reads the old shape;
  with a `**Scheduled**:` release or date that is never the release that stops using the column.
- `## Lock & Duration Budget`, `## Rollback per Phase`, `## Deploy Ordering` (including the flag coupling and the
  force-update step when mobile apps read the data), `## Verification Queries` (counts and IDs only, never personal
  data), `## Status` with every phase `pending`.

Then `tech-lead` reviews the deploy ordering and the Contract preconditions.

### 11d. Plan verdict

- `UNSAFE` — a destructive step (drop, rename, type narrowing, `NOT NULL` on existing data) outside `## Contract`; a
  Contract not gated on deployed readers and the minimum app version; a data-changing phase with neither a rollback
  nor a restore path; one unbatched backfill over a large table; any step meant to run by hand against a shared
  database.
- `RISKY — MITIGATION REQUIRED` — a step over the lock or duration budget without a written mitigation; DDL without a
  lock-wait limit; a non-concurrent index build on a large table; a backfill that is not resumable or throttled; no
  verification queries; deploy ordering that ignores shipped mobile app versions when the `stack` line configures
  a mobile layer.
- `NOT ASSESSED` — table sizes or traffic unknown for a step whose locking depends on them; the store not configured;
  the plan not checkable against a data model.
- `SAFE` — none of the above.

### 11e. Write the plan

Ask "May I write this to `docs/data/migrations/NNNN-<slug>.md`?", then offer to add its row to the plan index in
`docs/data/data-model.md` `## Migration Strategy` ("May I write this to `docs/data/data-model.md`?").

### 11f. Migration files (optional)

Offer to draft the executable files (`AskUserQuestion`: `Draft migration files` / `Plan only`). This is the
`db_migrations` category. `backend-engineer` (with `data-specialist` reviewing the SQL) drafts one file per phase in
the tool's format under the `data=` root of the `code_roots` line — for example a timestamped directory with
`migration.sql` for Prisma Migrate, `V<n>__<desc>.sql` for Flyway, a revision with `upgrade()` / `downgrade()` for
Alembic. Each file starts with the plan reference comment (`-- Plan: docs/data/migrations/NNNN-<slug>.md`). Show every
file, then ask "May I write this to `<migrations_dir>/<file>`?" for the listed set, and update the plan's
`**Migration Files**` line. `migrations_dir` unset ⇒ `NOT CHECKED — stack.layers.data.migrations_dir not set (run
/setup-stack)`; the plan is still written.

### 11g. Dry run (optional, explicit confirmation)

The dry run applies the **Expand** migration and rolls it back on a **disposable** database.

1. **Target.** A local container (for example `postgres:16` in Docker) or a throwaway database created for this run
   and seeded without production data. A branch or copy cloned from production is not disposable here — it carries
   production personal data. The skill describes the target from the command and the user's answer; it never reads
   `.env` files, secret stores or connection strings.
2. **Command.** `commands.migrate` from `project.yaml`, plus the rollback from the plan's `## Rollback per Phase`
   (the tool's down migration; for tools without down migrations, such as Prisma Migrate, a down script generated
   with `prisma migrate diff` and applied with `prisma db execute`). `commands.migrate` unset ⇒
   `NOT CHECKED — commands.migrate is not set`; give the user the exact commands to run and offer to record their
   pasted output (`Run by: user`).
3. **Confirm.** Show each command, the database it will touch and the expected result, then ask "May I run this?".
   A target that is not local or disposable — or that the user cannot confirm — is refused. `db_migrations` prompts
   here in every automation mode.
4. **Run** with Bash: apply, check the schema change landed, roll back, check it is gone. Capture exit codes and
   output; redact anything that looks like a credential or a host name before it is written.
5. **Evidence.** For a story: ask "May I write this to `production/qa/evidence/<story-slug>/migration-dry-run.log`?"
   The log records the date (UTC and KST), the plan and migration files, the target description, each command with
   its exit code and output, and the two result lines `Expand applied: yes|no` and `Rolled back: yes|no`. Not for a
   story: nothing is retained — report in the conversation and note in the plan's `## Status` Evidence column
   "dry run <date>, local — not retained; the story's dry run is still required".

A failed apply or rollback makes the plan verdict at least `RISKY — MITIGATION REQUIRED` until the cause is fixed.

### 11h. Update phase status

For an existing plan: ask which phase moved and where (`pending` → `applied-staging` → `applied-production`), the
date, and the pipeline run or release that applied it; the Contract row keeps its `Scheduled:` value until applied.
The skill records what the user reports — it never inspects a shared database to find out. Ask
"May I write this to `docs/data/migrations/NNNN-<slug>.md`?"

---

## Phase 12: Migration Review (`review`)

1. **Inputs.** The migration files under the `data=` root of the `code_roots` line and every plan in
   `docs/data/migrations/`. `migrations_dir` unset or missing ⇒ verdict `NOT ASSESSED` with the line
   `NOT CHECKED — stack.layers.data.migrations_dir not set (run /setup-stack)`.
2. **Map files to plans** — through each file's `-- Plan:` header comment and each plan's `**Migration Files**` line.
3. **Scan each file** for destructive or risky operations in its format — SQL (`DROP TABLE`, `DROP COLUMN`,
   `RENAME COLUMN`, `RENAME TO`, `ALTER COLUMN … TYPE`, `SET NOT NULL`, `TRUNCATE`, `DELETE` without `WHERE`, index
   builds without `CONCURRENTLY`, constraints without `NOT VALID`, DDL without a lock-wait limit), Rails
   (`remove_column`, `rename_column`, `change_column`), Alembic (`op.drop_column`, `op.alter_column(… type_=…)`,
   `op.rename_table`), Django (`RemoveField`, `RenameField`, `AlterField`). A file in a format the skill cannot read
   is listed `NOT CHECKED — <file>: format not recognised`.
4. **Findings and verdict**:
   - `FAIL` — a destructive operation (drop or rename of a column or table, type narrowing) with no Contract phase
     in any plan.
   - `CONCERNS` — a destructive operation in a plan whose Contract preconditions are unchecked; a migration file with
     no plan; a plan naming files that do not exist; a plan whose `## Status` contradicts itself (Contract applied
     before Expand); risky DDL (non-concurrent index, no lock-wait limit, no down migration).
   - `NOT ASSESSED` — nothing could be scanned.
   - `PASS` — every file mapped, nothing destructive outside a planned Contract phase.
5. Report in the conversation: a table (file · phase · plan · findings) and the verdict. Nothing is written; each
   finding names its fix (`/data-model migration <slug>` for a missing plan).

---

## Phase 13: Close

Print `Verdict: <TOKEN>`, the files written, and every `NOT CHECKED` line. A run that stops before its verdict phase
— the user declines to continue at 0b (no backend or data layer configured), or 11b sends a plan back to
`/data-model model` first — prints `Verdict: NOT ASSESSED — <the reason>`. Then close with `AskUserQuestion`, offering
only what applies:

- after `model`: `/api-design` (contract fields and PII flags aligned with this model) · `/security-audit
  threat-model` (when `privacy.handles_pii` is true and `docs/security/threat-model.md` does not exist) ·
  `/data-model migration <slug>` (for the changes the brownfield scan found) · `/architecture-review` in a fresh
  session · stop here;
- after `migration`: `/create-stories` (a story whose `**Migration**` points at this plan) · `/dev-story` for the
  story that implements it · `/rollout-plan` (the release copies `## Deploy Ordering`) · stop here;
- after `review`: `/data-model migration <slug>` for each unplanned destructive change · stop here.

---

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and `autonomous` modes see
`.claude/docs/automation-modes.md`; `db_migrations` and `pii_data_access` prompt in every mode.

1. **Question → Options → Decision → Draft → Approval** for every section of the model and every phase of a plan.
   Each section is written right after its approval — the approvals are not batched.
2. **"May I write this to `<path>`?"** before every write — the model, a plan, a migration file, the dry-run log, the
   registry, and `project.yaml` (only `privacy.handles_pii`, asked as "May I set `privacy.handles_pii: true` in
   `project.yaml`?"). "May I run this?" before every command that touches a database.
3. **Specialists draft, the user decides.** `data-specialist`, `backend-engineer`, `tech-lead` and
   `security-engineer` findings are shown side by side; conflicts are surfaced, never resolved silently.
4. **Unset is not "no".** An unclassified field, an unset `handles_pii`, unset regions or an unknown table size are
   open questions, never permissive defaults.
5. **Skips announce themselves.** A skipped consult, gate, dry run or file appears as a `NOT CHECKED` line in the
   summary.
6. **Shared databases are out of reach.** Proposals for staging and production are commands for a human or the
   pipeline to run, each with its blast radius and rollback.
7. **No commits.** Committing is the user's decision.
8. **The next step is offered, never taken.** The closing widget (Phase 13) recommends the next skill — `/api-design`
   after `model`, `/create-stories` or `/rollout-plan` after `migration`, `/data-model migration <slug>` after a
   `review` finding — and waits for the user's choice.
