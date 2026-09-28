# Skill Spec: /data-model

> **Category**: authoring
> **Priority**: high
> **Spec written**: 2026-09-28

## Skill Summary

`/data-model` owns the product's operational data design. In `model` mode it writes `docs/data/data-model.md` from
`.claude/docs/templates/data-model.md` one approved section at a time — entities and relationships (Mermaid ER),
ownership per bounded context (synced to `docs/registry/architecture.yaml` `data_ownership`), a classification of
every field as `Public | Internal | Confidential | PII | Sensitive-PII`, retention and the erasure path, consent
linkage, indexes per access pattern, multi-tenancy, consistency and transactions, and the migration strategy — and
spawns the SE-SECURITY-REVIEW gate under the review-mode rules. When a field is `PII` or `Sensitive-PII` and
`privacy.handles_pii` is unset, it asks "May I set `privacy.handles_pii: true` in `project.yaml`?". In
`migration <slug>` mode it plans `docs/data/migrations/NNNN-<slug>.md` from `.claude/docs/templates/migration-plan.md`
as **Expand → Migrate → Contract**, optionally drafts migration files under `stack.layers.data.migrations_dir`
(`db_migrations`, always asked) and runs a dry run only on a disposable database after explicit confirmation. In
`review` mode it audits the migrations directory against the plans. Verdicts: model `MODEL READY | NEEDS REVISION |
NOT ASSESSED`; migration `SAFE | RISKY — MITIGATION REQUIRED | UNSAFE | NOT ASSESSED`; review
`PASS | CONCERNS | FAIL | NOT ASSESSED`.

The skill holds the **migration floor**: a story whose `**Migration**` is not `None` requires
`production/qa/evidence/<story-slug>/migration-dry-run.log` at every `qa.level`. It never runs anything against a
shared, staging or production database and never reads personal data.

Assertions quote the canonical English text of `.claude/skills/data-model/SKILL.md`; quoted prompts are rendered in
the user's conversation language at run time (`.claude/docs/coding-standards.md` § Language Policy) and this spec
never asserts the runtime wording.

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] `name: data-model` equals the directory name (`.claude/skills/data-model/`) and this spec's basename
- [ ] `argument-hint` is `"[model | migration <slug> | review] [--review full|lean|solo]"`
- [ ] The first body line is exactly
      `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,automation_always_ask,workflow,stack,compliance,code_roots` ``
      — the `--keys` value is exactly `review_mode,automation,automation_always_ask,workflow,stack,compliance,code_roots`
- [ ] `allowed-tools` contains the grant naming this skill's own directory:
      `Bash(bash "*/.claude/skills/data-model/../../hooks/yaml-helper.sh" resolve_config *)`
- [ ] `allowed-tools` is exactly the set Read, Glob, Grep, Write, Edit, Bash, Agent, AskUserQuestion plus that grant
      — no MCP tool names
- [ ] The line after the bootstrap block is exactly: ``Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] The automation prelude block — from `**Automation mode**: Resolve` to `categories always prompt).` — follows
      that line verbatim
- [ ] The bootstrap line is the only `!` injection in the file; no `file:line` citation of another file
- [ ] `model: sonnet`; no `disable-model-invocation` and no `isolation` key
- [ ] ≥2 phase headings (Phase 0 through Phase 13)
- [ ] The verdict tokens are spelled exactly per mode: `MODEL READY` · `NEEDS REVISION` · `NOT ASSESSED`;
      `SAFE` · `RISKY — MITIGATION REQUIRED` · `UNSAFE` · `NOT ASSESSED`; `PASS` · `CONCERNS` · `FAIL` · `NOT ASSESSED`
- [ ] Every output is named: `docs/data/data-model.md`, `docs/data/migrations/NNNN-<slug>.md`, migration files under
      `stack.layers.data.migrations_dir`, `production/qa/evidence/<story-slug>/migration-dry-run.log`,
      `project.yaml` (`privacy.handles_pii`), `docs/registry/architecture.yaml` (`data_ownership`)
- [ ] "May I write this to `<path>`?" appears before each file write, "May I set `privacy.handles_pii: true` in
      `project.yaml`?" before the only `project.yaml` edit, and "May I run this?" before every database command
- [ ] The SE-SECURITY-REVIEW spawn carries this `Pass:` line verbatim:
      `` Pass: artifact path (contract, data model or ADR) · operations or entities with auth scope and PII classification · resolved `compliance` line · `docs/security/threat-model.md` path (or "none") ``
- [ ] The migration floor sentence is present (dry-run log required at every `qa.level`, regardless of
      `testing.strict.config`; absent ⇒ BLOCKING)
- [ ] The unresolved-root line is spelled `NOT CHECKED — no code root resolved (set stack.layers.<layer>.root via /setup-stack)`
- [ ] Next-step handoff at the end (Phase 13 closing `AskUserQuestion`)

---

## Director Gate Checks

The skill spawns one director gate, **SE-SECURITY-REVIEW** (`security-engineer`), in `model` mode Phase 9b — after
the specialist review of the whole draft. `migration` and `review` modes spawn no gate: a plan that adds a column
sends the user back to `/data-model model` first (11b), and that run carries the gate.

- **Full mode**: SE-SECURITY-REVIEW spawns with the four Context items filled from the model (entities with owner,
  readers/writers and each field's classification).
- **Lean mode**: the lean suffix rule skips it; the model header carries `> [SE-SECURITY-REVIEW] skipped — Lean mode`
  in place of the review line.
- **Solo mode**: skipped; `> [SE-SECURITY-REVIEW] skipped — Solo mode`.
- **N/A**: `migration <slug>` and `review` modes.

Consultations that are not gates (`data-specialist`, `backend-engineer`, `tech-lead`) run in every mode; an unset
data layer skips `data-specialist` with `NOT CHECKED — data layer not configured (run /setup-stack)`.

---

## Test Cases

### Case 1: Happy Path — `model` for Moa, section by section, MODEL READY

**Fixture** (assumed project state):
- Moa at Architecture; the config block prints `review_mode: full (project.yaml)`, `workflow: standard (rigor:standard)`,
  `stack: web=Next.js 15.3 @apps/web,apps/admin; mobile=React Native (Expo) 0.79 @apps/mobile; backend=NestJS 11.0 @apps/api,services/worker; data=PostgreSQL 16; unset=cloud [routing: web-specialist>nextjs-specialist, mobile-specialist>react-native-specialist, backend-specialist>node-specialist, data-specialist] (project.yaml)`,
  `compliance: regions=kr handles_pii=(unset -- ask) (project.yaml)`,
  `code_roots: web=apps/web,apps/admin; mobile=apps/mobile; backend=apps/api,services/worker; data=apps/api/prisma/migrations (project.yaml); extensions: ts tsx js jsx mjs cjs vue svelte sql`
- `docs/architecture/adr-0002-primary-data-store.md` is `Accepted` (Domain `Data`); `design/prd/auth.md`,
  `design/prd/goals.md`, `design/prd/payments.md` exist; `docs/api/openapi.yaml` flags `x-data-classification`
- No `docs/data/data-model.md`; `docs/registry/architecture.yaml` has no `data_ownership` entries

**Input:** `/data-model`

**Expected behavior:**
1. Mode `model` is announced (no data model yet); the agents list is announced (`data-specialist`,
   `backend-engineer`, `tech-lead`, SE-SECURITY-REVIEW)
2. Phase 1 reads by section and presents a context summary naming the store, the ORM, regions and the unset
   `handles_pii` as an open question
3. The first approved section creates `docs/data/data-model.md` from the template with
   `> **Verdict**: NOT ASSESSED`; each later section is written with Edit right after its approval
4. Phase 4 classifies every field — billing keys from Toss Payments, not card numbers; `phone_number` `PII`;
   `ci` (identity-verification CI) `Sensitive-PII` — and builds the PII inventory
5. Phase 5 writes the account erasure path end to end and the consent linkage (marketing consent separate from
   terms acceptance; 알림톡 informational messages only), listing the `kr` topics as items to verify
6. Phase 9a spawns `data-specialist` and `tech-lead` in parallel; Phase 9b spawns SE-SECURITY-REVIEW (APPROVE)
7. Phase 10 sets the verdict `MODEL READY`, asks "May I set `privacy.handles_pii: true` in `project.yaml`?", then
   offers the `data_ownership` sync ("May I write this to `docs/registry/architecture.yaml`?")
8. Phase 13 prints `Verdict: MODEL READY` and offers `/api-design` first

**Assertions:**
- [ ] The file's nine `##` headings are byte-identical to the template, in order (`## Entities` …
      `## Migration Strategy`), in English, whatever the conversation language
- [ ] No section is written before it is approved; approvals are not batched
- [ ] The `project.yaml` edit touches only `privacy.handles_pii` and happens only after the explicit question
- [ ] The registry sync adds entries and `referenced_by` values only — it never deletes or silently changes an owner
- [ ] A legal retention period carries `(Source: <url>, retrieved YYYY-MM-DD)` or `NOT SOURCEABLE — confirm with counsel`
- [ ] The verdict line `> **Verdict**: MODEL READY` sits directly under the H1 and one blank line

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: NOT ASSESSED — an unclassified field and an unset data layer (missing input)

**Fixture:**
- (a) Case 1 state, but the user defers the classification of `goals.memo` ("decide later")
- (b) The config block prints `stack: web=Next.js 15.3 @apps/web; backend=NestJS 11.0 @apps/api; unset=mobile,data,cloud [...] (project.yaml)`

**Input:** `/data-model model`

**Expected behavior:**
1. (a) The field stays `unclassified`; Phase 10 cannot reach `MODEL READY` and sets `NOT ASSESSED`, naming the field
2. (b) Phase 0 prints `NOT CHECKED — data layer not configured (run /setup-stack)`; `data-specialist` is skipped with
   that line; store-specific rules (locks, online DDL, index types) are `NOT ASSESSED`

**Assertions:**
- [ ] An unclassified field is never read as `Internal`; the verdict is `NOT ASSESSED`, not `MODEL READY`
- [ ] The skipped specialist and the unchecked store rules appear in the summary by name — nothing is skipped silently
- [ ] `NOT ASSESSED` does not hide a known problem: a `PII` field without a deletion path in the same run makes the
      verdict `NEEDS REVISION` (it outranks `NOT ASSESSED`)
- [ ] A run that stops before its verdict phase — the user declines to continue at 0b (`backend` and `data` both in
      `unset=`), or 11b sends a plan back to `/data-model model` — prints `Verdict: NOT ASSESSED — <the reason>`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Mode Variant — `migration goal-target-date` plans Expand → Migrate → Contract

**Fixture:**
- `docs/data/data-model.md` already lists `goals.target_date` (`date`, `PII`) and the old `goals.deadline` text column
- A mobile layer is configured; the minimum supported app version still reads `deadline`
- `project.yaml` sets `commands.migrate: pnpm prisma migrate deploy`; the story
  `production/epics/goals-core/story-004-goal-target-date.md` will carry the plan

**Input:** `/data-model migration goal-target-date`

**Expected behavior:**
1. 11a numbers the plan (`0001` when the folder is empty) and asks which story will carry it
2. 11b confirms every added column is already in the data model with its classification
3. 11c spawns `data-specialist` and `backend-engineer` together; `tech-lead` then reviews deploy ordering
4. The plan has **Expand** (additive only), **Migrate** (dual-write, batched resumable backfill, verification
   queries with counts only) and **Contract** gated on every reader being deployed and on the minimum supported app
   version no longer reading `deadline`, with a `**Scheduled**:` release
5. "May I write this to `docs/data/migrations/0001-goal-target-date.md`?"; then the optional migration files
   (`db_migrations` prompts in every automation mode) under `apps/api/prisma/migrations`, each file starting with
   `-- Plan: docs/data/migrations/0001-goal-target-date.md`
6. The optional dry run: the target is a local disposable container; each command is shown with the database it
   touches and "May I run this?" is asked; the log is written to
   `production/qa/evidence/story-004-goal-target-date/migration-dry-run.log` with `Expand applied: yes` and
   `Rolled back: yes`

**Assertions:**
- [ ] The migration plan's `##` headings are byte-identical to `.claude/docs/templates/migration-plan.md`
      (`## Change` … `## Status`) and every phase starts `pending`
- [ ] A destructive step appears only under `## Contract`
- [ ] The plan verdict is `SAFE` only when no UNSAFE or RISKY condition applies and the plan was checked against the
      data model
- [ ] The dry-run log is written only for a story; a run not tied to a story retains nothing and notes it in
      `## Status`
- [ ] Credentials and host names are redacted before anything is written

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Edge Case — UNSAFE plan and a non-disposable dry-run target

**Fixture:**
- The drafted plan drops `goals.deadline` in the **Expand** phase
- For the dry run the user proposes "the staging branch database cloned from production"

**Input:** `/data-model migration drop-goal-deadline`

**Expected behavior:**
1. 11d classifies the plan `UNSAFE` — a destructive step outside `## Contract`
2. The dry run is refused: a copy cloned from production carries production personal data and is not disposable
3. The skill proposes the fix (move the drop to Contract, gate it on deployed readers and the minimum app version)
   and waits for the user

**Assertions:**
- [ ] Verdict `UNSAFE`; the plan can still be written, with the verdict line under its H1
- [ ] No command is run against a shared, staging or production database, whatever the automation mode
- [ ] The skill never reads `.env` files, secret stores or connection strings to find the target (`secrets_access`)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Mode Variant — `review` finds a drop without a Contract phase

**Fixture:**
- `apps/api/prisma/migrations/20261020_drop_deadline/migration.sql` contains `ALTER TABLE goals DROP COLUMN deadline;`
  and no `-- Plan:` header; no plan in `docs/data/migrations/` has a Contract phase for it
- A second project variant: `stack.layers.data.migrations_dir` is not set

**Input:** `/data-model review`

**Expected behavior:**
1. Phase 12 maps files to plans through the `-- Plan:` header and the plans' `**Migration Files**` lines
2. The unplanned `DROP COLUMN` yields `FAIL`; the file without a plan is a `CONCERNS` finding
3. The report is a table (file · phase · plan · findings) in the conversation; nothing is written
4. Variant: `NOT CHECKED — stack.layers.data.migrations_dir not set (run /setup-stack)` and verdict `NOT ASSESSED`

**Assertions:**
- [ ] A destructive operation with no Contract phase in any plan is `FAIL`, never `CONCERNS`
- [ ] `review` writes no file
- [ ] Each finding names its fix (`/data-model migration <slug>` for the missing plan)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Review Mode — `full`, SE-SECURITY-REVIEW returns REJECT

**Fixture:**
- Case 1 state at Phase 9b; `review_mode: full (project.yaml)`; `docs/security/threat-model.md` absent
- The gate's first reply line is `[SE-SECURITY-REVIEW]: REJECT` — `ci` (Sensitive-PII) has no retention rule or
  deletion path

**Input:** `/data-model model`

**Expected behavior:**
1. The spawn prompt instructs `security-engineer` to read `.claude/docs/director-gates/se-security-review.md` first
2. Pass items: `docs/data/data-model.md`; the entities with owner, readers and writers and each field's
   classification; the resolved `compliance` line; `"none"` for the threat model
3. The blockers are presented and the affected sections offered for revision; the gate is spawned again after
   revising
4. If the user stops instead, the verdict is `NEEDS REVISION` and the header review line reads
   `pending — REJECT findings unresolved <date>`

**Assertions:**
- [ ] The first reply line is parsed as `[SE-SECURITY-REVIEW]: TOKEN`; an unparseable line is CONCERNS-class
- [ ] A REJECT-class verdict never leads to `MODEL READY`
- [ ] CONCERNS are surfaced with `Revise flagged items` / `Accept and proceed` / `Discuss further` and recorded as
      `REVISED <date>` or `CONCERNS (accepted) <date>`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: Review Mode — `lean` skips SE-SECURITY-REVIEW by the suffix rule

**Fixture:**
- Case 1 state; the config block prints `review_mode: lean (rigor:standard)`

**Input:** `/data-model model`

**Expected behavior:**
1. Phase 9b applies the lean suffix rule; SE-SECURITY-REVIEW does not end in `-PHASE-GATE` and is skipped
2. The model header carries `> [SE-SECURITY-REVIEW] skipped — Lean mode` in place of the review line
3. The summary says "SE-SECURITY-REVIEW not consulted — Lean mode; `--review full` runs it, or run
   `/security-audit privacy` later."
4. The Phase 9a specialist review still runs

**Assertions:**
- [ ] The SKILL.md review-mode check contains the sentence
      `` `lean` → **skip every gate whose ID does not end in `-PHASE-GATE`**. Note: `[GATE-ID] skipped — Lean mode` ``
- [ ] No `security-engineer` spawn in lean mode; `data-specialist` and `tech-lead` are still consulted
- [ ] The skip is recorded in the artifact and does not by itself prevent `MODEL READY`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 8: Review Mode — `solo` on a project with no rigor set

**Fixture:**
- The config block prints `review_mode: solo (rigor:minimal)` and `workflow: minimal (rigor:minimal)`
- The user runs the (optional at `minimal`) model for an early build

**Input:** `/data-model model`

**Expected behavior:**
1. Phase 0 says the step is optional at `minimal`; the run proceeds on request
2. Phase 9b skips all gates: `> [SE-SECURITY-REVIEW] skipped — Solo mode` in the header
3. The migration floor still applies (it is tier-independent)

**Assertions:**
- [ ] The note reads exactly `[SE-SECURITY-REVIEW] skipped — Solo mode`; no gate agent is spawned
- [ ] The skill never writes `modes.review_mode`, `modes.workflow` or any other rigor-fronted knob
- [ ] The migration floor statement is not relaxed by the tier

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses "May I write this to `<path>`?" before every write, the dedicated `privacy.handles_pii` question before the
      only `project.yaml` edit, and "May I run this?" before every database command
- [ ] Presents the context summary and each drafted section before asking for approval
- [ ] Ends with a recommended next step (Phase 13) and never takes it on its own
- [ ] Does not auto-create files; `db_migrations` and `pii_data_access` prompt in every automation mode
- [ ] Never queries, samples or exports personal data; verification queries use counts and IDs only
- [ ] Never commits

**Authoring rubric** (`CCSS Skill Testing Framework/quality-rubric.md` § `authoring`):

- [ ] A1 — Section-by-section cycle: each model section is drafted, presented, approved and then written
- [ ] A2 — "May I write" per section write, per plan, per migration file set, for the dry-run log and the registry
- [ ] A3 — Retrofit: an existing model is updated by showing and writing only the diff of the changed sections; an
      existing plan offers `Update phase status` / `Revise the plan` / `Cancel`
- [ ] A4 — SE-SECURITY-REVIEW runs in `full`, is skipped with a named note in `lean` and `solo`
- [ ] A5 — Skeleton headings byte-identical to the template file: the model's nine `##` headings match
      `.claude/docs/templates/data-model.md` and a plan's `##` headings match `.claude/docs/templates/migration-plan.md`

---

## Coverage Notes

- `11h` (update phase status `pending` → `applied-staging` → `applied-production`) is covered only by A3; the skill
  records what the user reports and never inspects a shared database.
- Brownfield reconstruction from an existing ORM schema is not fixture-tested.
- Format-specific scanning in `review` (Rails, Alembic, Django operations) is covered structurally; only the SQL path
  is fixture-tested.
- Undeclared code roots (`WARN: undeclared code roots: <dirs> — declare them with /setup-stack`) are asserted by the
  static check of the unresolved-root line only.
