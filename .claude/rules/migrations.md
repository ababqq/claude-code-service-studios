---
paths:
  - "**/migrations/**"
  - "**/db/migrate/**"
  - "**/alembic/versions/**"
  - "**/flyway/**"
---

# Migration Rules

These paths hold executable migrations (the data layer's `stack.layers.data.migrations_dir`) and the migration
plans under `docs/data/migrations/`. Plans are written by `/data-model migration <slug>` from
`.claude/docs/templates/migration-plan.md`; `/data-model review` audits the files against the plans.

- **Expand / contract only.** Every change that is not purely additive is split into Expand (additive: new
  nullable columns, new tables, new indexes, constraints added `NOT VALID`), Migrate (dual-write and backfill) and
  Contract (drops, renames, `NOT NULL`, type narrowing). A migration file belongs to exactly one phase.
- **Reversible.** Every Expand and Migrate migration has a working down migration (or the tool's equivalent) that
  was run in the dry run. A Contract migration that cannot be reversed says so in its plan's
  `## Rollback per Phase` and names the backup or point-in-time recovery it relies on.
- **No destructive change in the release that stops using a column.** Drop or rename only after every service,
  job and tool reading the old shape is deployed — and, for mobile, after the minimum supported app version no
  longer reads it. Renames are "add new, dual-write, backfill, switch reads, drop old" — never `RENAME COLUMN` on a
  live table.
- **Batched backfills.** Data changes run as batched, idempotent, resumable jobs ordered by primary key, with a
  pause between batches — never one `UPDATE` over a large table and never inside the schema migration's
  transaction.
- **Lock budget.** Set a lock-wait limit before DDL (PostgreSQL `SET lock_timeout`); build indexes concurrently
  (`CREATE INDEX CONCURRENTLY`, outside a transaction); validate constraints separately (`VALIDATE CONSTRAINT`); on
  MySQL prefer `ALGORITHM=INSTANT` / `INPLACE` or an online schema-change tool. A step above the plan's
  `## Lock & Duration Budget` needs a mitigation written in the plan.
- **Plan file linked.** Every migration file names its plan in a header comment
  (`-- Plan: docs/data/migrations/NNNN-<slug>.md`) and the plan lists the file in `**Migration Files**`. A
  destructive statement without a Contract phase in a plan fails `/data-model review`.
- **Dry-run evidence (migration floor).** A story whose `**Migration**` is not `None` needs
  `production/qa/evidence/<story-slug>/migration-dry-run.log` — Expand applied and rolled back on a disposable
  database — at every `qa.level`; absent ⇒ BLOCKING. Dry runs use a local container or a throwaway database seeded
  without production data, never a shared or production database.
- **Agents never run migrations against shared databases.** Staging and production migrations run in the deploy
  pipeline; `db_migrations` is an always-ask category and the settings deny list blocks destructive database CLIs.
- **Generated migrations are reviewed as SQL.** ORM-generated files (Prisma, TypeORM, Drizzle, Django, Alembic
  autogenerate) are read line by line before commit — generators emit drops and renames silently.
- **No personal data in migrations.** No real emails, phone numbers or account numbers in seed or backfill
  statements; backfill logs record row IDs, never values.

## Examples

**Correct** (PostgreSQL — Expand phase of `docs/data/migrations/0003-goal-target-date.md`):

```sql
-- Plan: docs/data/migrations/0003-goal-target-date.md (phase: Expand)
SET lock_timeout = '2s';
ALTER TABLE goals ADD COLUMN target_date date NULL;
-- The index is built in a separate, non-transactional migration:
-- CREATE INDEX CONCURRENTLY goals_user_id_target_date_idx ON goals (user_id, target_date);
```

**Incorrect**:

```sql
ALTER TABLE goals RENAME COLUMN deadline TO target_date;      -- VIOLATION: breaks every deployed reader and older app versions
ALTER TABLE goals ALTER COLUMN target_date TYPE date
  USING to_date(target_date, 'YYYY.MM.DD');                    -- VIOLATION: table rewrite under an exclusive lock; no batching
CREATE INDEX goals_target_date_idx ON goals (target_date);     -- VIOLATION: blocks writes; use CONCURRENTLY
-- VIOLATION: no plan reference, no lock_timeout, no down migration
```
