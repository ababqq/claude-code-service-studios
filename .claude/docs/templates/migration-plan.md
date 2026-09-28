# Migration NNNN: [Title]

> **Verdict**: [SAFE | RISKY — MITIGATION REQUIRED | UNSAFE | NOT ASSESSED]
> **Plan**: `docs/data/migrations/NNNN-[slug].md`
> **Owner**: [backend-engineer or named person] — reviewed by `data-specialist` and `tech-lead`
> **Last Updated**: [YYYY-MM-DD]
> **Data Model**: `docs/data/data-model.md` — [entity or entities affected]
> **Stories**: [`production/epics/<epic-slug>/story-NNN-<slug>.md` … | none yet]
> **Migration Files**: [`<migrations_dir>/<file>` per phase | not drafted]
> **Feature Flag**: [flag key that switches reads or writes to the new shape | None]
> **Store**: [PostgreSQL 16 | MySQL 8.4 | …] (from `stack.layers.data.database`)

<!--
Template: .claude/docs/templates/migration-plan.md, written to docs/data/migrations/NNNN-<slug>.md by
/data-model migration <slug>. The `##` headings are a contract: gate-hardening reads `## Status` (Expand applied
on staging, Contract scheduled), /story-done checks the phase state, /release-checklist and /rollout-plan read
`## Deploy Ordering`. Keep them in English as spelled; the Status tokens are exactly
pending / applied-staging / applied-production. Write the body in the team's language.
Example (Moa) used below: goals.deadline (free-text "YYYY.MM.DD") becomes goals.target_date (date).
-->

## Change

- **What**: [one paragraph — tables, columns, constraints or data that change].
- **Why**: [PRD requirement / ADR / incident — with TR-ID or link].
- **Affected data**: [table — approximate row count and growth; classification of the affected fields from the data
  model; PII or Sensitive-PII involved: yes / no].
- **Readers and writers of the old shape**: [services, jobs, admin tools, analytics pipelines, and each mobile app
  version range that still reads it].
- **Destructive steps**: [none | list — each one appears only in `## Contract`].

Example (Moa): `goals.deadline` (text) is replaced by `goals.target_date` (date, Asia/Seoul calendar). About
180,000 rows. Classification PII (unchanged). Readers: API `listGoals`/`getGoal`, the reminder job, iOS and Android
app versions below 2.4.0 (they read `deadline` through the API field `deadline`).

## Expand

Additive steps only — nothing here may break the currently deployed application or any supported app version.

| # | Step (DDL or code) | Lock taken | Expected duration | Online technique | Migration file |
|---|---|---|---|---|---|
| E1 | [e.g. `ALTER TABLE goals ADD COLUMN target_date date NULL`] | [ACCESS EXCLUSIVE, metadata only] | [< 1 s] | [nullable column, no default rewrite] | [file] |
| E2 | [e.g. `CREATE INDEX CONCURRENTLY … ON goals (user_id, target_date)`] | [SHARE UPDATE EXCLUSIVE] | [minutes] | [concurrent build; outside a transaction] | [file] |

Every DDL migration sets a lock-wait limit first (PostgreSQL: `SET lock_timeout = '[2s]'`) so a blocked
migration fails fast instead of queueing every request behind it.

## Migrate

- **Dual-write**: from application version [vX.Y] (behind flag `[flag key]`), writes update both the old and the
  new shape.
- **Backfill**: [job name] copies or transforms existing rows in batches of [n] rows ordered by primary key, with a
  [pause] between batches, idempotent and resumable from a checkpoint; it never holds a transaction across
  batches. Rows it cannot transform are logged by ID (never by value) for manual repair.
- **Read switch**: reads move to the new shape when the verification queries return zero mismatches — [flag flip
  in staging, then production].
- Example (Moa): parse `deadline` with the formats `YYYY.MM.DD` and `YYYY-MM-DD`; unparseable values stay NULL and
  are listed for support.

## Contract

Removes the old shape — the only phase allowed destructive steps.

- **Preconditions** (all must hold):
  - [ ] Every service, job and tool reading the old shape is deployed on the new shape.
  - [ ] The minimum supported app version (iOS and Android) no longer reads the old shape — [version].
  - [ ] Verification queries return zero mismatches for [period] in production.
  - [ ] A backup or point-in-time recovery window covers the drop.
- **Steps**: [e.g. `ALTER TABLE goals DROP COLUMN deadline`; remove dual-write code; remove the API field after its
  `Sunset` date].
- **Scheduled**: [release version or date — never the release that stops using the column].

## Lock & Duration Budget

| Step | Statement | Lock mode | Lock wait limit | Expected duration | Measured on staging | Within budget |
|---|---|---|---|---|---|---|
| E1 | [statement] | [mode] | [2 s] | [estimate] | [value, date / pending] | [yes / no — mitigation] |
| M1 | backfill batch | row locks only | n/a | [per batch × batches] | [value / pending] | [yes / no] |
| C1 | [statement] | [mode] | [2 s] | [estimate] | [value / pending] | [yes / no] |

Budget defaults come from `docs/data/data-model.md` `## Migration Strategy`; a step above budget names its
mitigation (maintenance window, online schema-change tool, smaller batches).

## Rollback per Phase

| Phase | Rollback | Data loss on rollback | Rehearsed |
|---|---|---|---|
| Expand | [down migration — e.g. drop the new column and index] | none (new column only) | [dry-run log path / pending] |
| Migrate | [turn the flag off; reads return to the old shape; dual-write keeps the old shape current] | none | [staging, date / pending] |
| Contract | [restore from backup or point-in-time recovery — not a simple down migration] | [data written only to the new shape after the drop is kept; the dropped column is restored from backup] | [restore drill, date / pending] |

## Deploy Ordering

| # | Step | Environment | Gate to continue |
|---|---|---|---|
| 1 | Expand migration runs in the deploy pipeline | staging, then production | migration succeeded within the lock budget |
| 2 | Application [vX.Y] with dual-write (flag off) | staging, then production | error rate and latency within SLO |
| 3 | Backfill job | staging, then production | verification queries: zero mismatches |
| 4 | Flag on — reads use the new shape | staging, then production | guardrail metrics unchanged for [period] |
| 5 | Minimum supported app version raised to [version] (force-update path) | stores | old app versions' traffic below [threshold] |
| 6 | Contract migration + removal of dual-write code | staging, then production | preconditions in `## Contract` all checked |

Mobile apps change on the stores' schedule, not the deploy's: the API keeps serving the old field until step 5.
`/rollout-plan` copies this ordering into the release's `## Migration Ordering`.

## Verification Queries

Read-only queries that prove each phase. They return counts or IDs, never personal data, and a human runs them
against shared or production databases — agents never do.

```sql
-- V1 (after backfill): rows not yet backfilled
SELECT count(*) FROM goals WHERE deadline IS NOT NULL AND target_date IS NULL;

-- V2 (before read switch): rows where the two shapes disagree
SELECT count(*) FROM goals
WHERE deadline IS NOT NULL
  AND target_date IS DISTINCT FROM to_date(replace(deadline, '.', '-'), 'YYYY-MM-DD');
```

## Status

| Phase | Status | Staging | Production | Evidence |
|---|---|---|---|---|
| Expand | pending | — | — | `production/qa/evidence/<story-slug>/migration-dry-run.log` (Expand applied and rolled back on a disposable database) |
| Migrate | pending | — | — | [backfill run log / verification query results] |
| Contract | pending | — | — | Scheduled: [release or date] |

Status values: `pending` → `applied-staging` → `applied-production`. Record the date and the release or pipeline
run in the Staging and Production columns when a phase is applied.
