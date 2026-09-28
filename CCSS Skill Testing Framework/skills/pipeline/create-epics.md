# Skill Test Spec: /create-epics

> **Category**: pipeline
> **Priority**: high
> **Spec written**: 2026-09-28

## Skill Summary

`/create-epics` turns approved PRDs, the architecture, the API contract and the data
model into epics — **one per architectural module** — written to
`production/epics/<epic-slug>/EPIC.md`, and keeps the master index
`production/epics/index.md`. It processes features in layer order (Foundation → Core →
Feature → Presentation) and, inside a layer, in `Depends On` order from
`design/product/feature-map.md`. Each epic carries its governing ADRs, the PRD
requirements with ADR coverage (TR-IDs from `docs/architecture/tr-registry.yaml`), a
non-functional requirements table, the API operations it implements, the entities it
owns with their classification and migration plans, its rollout and flags, its Stack
Risk and a Definition of Done. Gaps are flagged before writing — untraced requirements,
operations missing from the contract, schema changes without a migration plan — and
every input that does not exist is named (`NOT CHECKED — …`, `NOT SOURCED — …`,
`NOT ASSESSED (no VERSION.md risk rating)`). After the epics are written, the review
mode decides whether **DM-EPIC** (delivery-manager) reviews the structure before any
story is broken out. At `minimal` the skill is optional and decomposes the one-pager's
`## Build Order`. Its output is the artifact of catalog step `validation.create-epics`
(`production/epics/*/EPIC.md`).

Verdicts: **COMPLETE** / **BLOCKED** / **NOT ASSESSED** (a required input is missing: no one-pager at
`minimal`, no PRDs, no eligible feature in scope, or the contract / data model `full` requires).

---

## Static Assertions (Structural)

Verified automatically by `/skill-test static` — no fixture needed.

- [ ] Frontmatter has `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`; `name: create-epics` equals the directory, the catalog `name` and this spec's basename
- [ ] `description` is exactly "Epics from PRDs, architecture and the API contract — one per module — with untraced requirements."
- [ ] `argument-hint` offers `[feature-slug | layer: foundation|core|feature|presentation | all]` and `[--review full|lean|solo]`; `model: sonnet`; no `disable-model-invocation`, no `isolation`
- [ ] First body line is exactly `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,docs.density,story_granularity,feature_overrides` ``
- [ ] `allowed-tools` is exactly `Read, Glob, Grep, Write, Agent, AskUserQuestion` plus `Bash(bash "*/.claude/skills/create-epics/../../hooks/yaml-helper.sh" resolve_config *)`
- [ ] The line after the bootstrap block is exactly `` Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`. ``, followed verbatim by the automation prelude block
- [ ] ≥2 numbered phase headings (`## 1. Parse Arguments` … `## 6. Gate-Check Reminder`, with `## 5b. Delivery Manager Epic Structure Gate`)
- [ ] Verdict keywords `COMPLETE`, `BLOCKED` and the run-level `NOT ASSESSED`; the could-not-assess forms `NOT CHECKED — API operations (no contract under docs/api/)`, `NOT SOURCED — <what>` and `NOT ASSESSED (no VERSION.md risk rating)` present
- [ ] "May I write this to `production/epics/<epic-slug>/EPIC.md`?" and "May I write this to `production/epics/index.md`?" present
- [ ] EPIC.md template carries `> **Layer**:`, `> **PRD**:`, `> **Architecture Module**:`, `> **Status**: Ready`, `> **Stories**:`, `> **Stack Risk**:` and the sections `## Overview`, `## Governing ADRs`, `## PRD Requirements`, `## Non-Functional Requirements`, `## API Operations`, `## Owned Entities`, `## Rollout & Flags`, `## Stack Risk`, `## Definition of Done`, `## Next Step`
- [ ] The epic Definition of Done names the migration floor (`production/qa/evidence/` dry-run log at every `qa.level`) and the five `testing.strict` keys `logic`, `integration`, `ui`, `e2e`, `config`
- [ ] Output paths `production/epics/<epic-slug>/EPIC.md` (glob `production/epics/*/EPIC.md` of catalog step `validation.create-epics`) and `production/epics/index.md`
- [ ] DM-EPIC review-mode check carries the lean suffix sentence; the spawn has `` Pass: `production/epics/index.md` path · EPIC.md paths · `docs/architecture/architecture.md` path ``; the reply is parsed as `[DM-EPIC]: TOKEN`
- [ ] Only one `!` injection; no `file:line` citation; the handoff names `/create-stories [epic-slug]` and `/gate-check build`

---

## Director Gate Checks

One gate: **DM-EPIC** — `delivery-manager`, Domain "Epic structure", verdicts
`REALISTIC / CONCERNS / UNREALISTIC`. It reviews the **written** structure (its Context
is the index and EPIC.md paths), so it runs in Step 5b — after all epics of the requested
scope are written and before any story is created.

- **Full mode**: DM-EPIC spawns with the `Pass:` line above; the prompt tells the agent to
  read `.claude/docs/director-gates/dm-epic.md`.
- **Lean mode**: skip every gate whose ID does not end in `-PHASE-GATE` — DM-EPIC is
  skipped; `[DM-EPIC] skipped — Lean mode` becomes the review line of
  `production/epics/index.md`.
- **Solo mode**: skipped — `[DM-EPIC] skipped — Solo mode` in the same place.

---

## Test Cases

Fixtures use the Moa example product: feature `goals` (PRD `design/prd/goals.md`,
`> **Status**: Approved`), module `goals-core` in `docs/architecture/architecture.md`,
TR-IDs `TR-goals-001..004`, operation `createGoal` (`POST /v1/goals`) in
`docs/api/openapi.yaml`, entity `savings_goal` in `docs/data/data-model.md`, journey
"Create a savings goal" in `docs/ops/slo.md`.

### Case 1: Happy Path — one Core-layer epic at `standard`

**Fixture:**
- `modes.workflow: standard`; review mode `lean` (gate behaviour is Cases 6–8)
- `design/product/feature-map.md` lists `goals` (Layer Core, Tier MVP, Status Approved)
- Every PRD has `## Summary`; critical (Foundation) ADRs Accepted; `ADR-0006` governs goals and covers TR-goals-001..004 in its `## PRD Requirements Addressed`
- `docs/data/migrations/0003-savings-goal.md` plans the `savings_goal` table; the PRD's `## Configuration & Flags` lists `goals.v2-progress-ring`

**Input:** `/create-epics goals`

**Expected behavior:**
1. Globs `design/prd/*.md` (denominator N), scans `^## Summary`, and full-reads only the in-scope PRD
2. Reads each in-scope ADR by bounded sections (`PRD Requirements Addressed`, `Decision`, `Stack Compatibility`), the TR entries `id: TR-goals-`, the contract operations, the data model ownership, the migration plan and `docs/ops/slo.md`
3. Reports what was loaded, then presents the epic summary and asks "Shall I create Epic: [name]?" (`[A] Yes, create it` / `[B] Skip this epic` / `[C] Pause — …`)
4. Asks "May I write this to `production/epics/goals-core/EPIC.md`?", writes it, then asks "May I write this to `production/epics/index.md`?" and writes the index row
5. Skips DM-EPIC (lean) and records the skip note; reports Verdict **COMPLETE** and hands off to `/create-stories goals-core`

**Assertions:**
- [ ] The epic is written to `production/epics/goals-core/EPIC.md` — a directory per epic slug, never a layer directory
- [ ] `## PRD Requirements` lists TR-goals-001..004 with ADR coverage; `## API Operations` shows `createGoal` with its contract reference; `## Owned Entities` shows `savings_goal`, its classification and `docs/data/migrations/0003-savings-goal.md`
- [ ] `## Non-Functional Requirements` rows each name a source (`docs/ops/slo.md`, the PRD, `design/accessibility-requirements.md`)
- [ ] `## Rollout & Flags` lists `goals.v2-progress-ring` with default, owner and removal date
- [ ] The index table header is `| Epic | Layer | Feature | PRD | Stories | Status |`; the row reads `Not yet created` / `Ready`
- [ ] Each file gets its own "May I write" — the epic is never written before the answer
- [ ] No story file is created

---

### Case 2: Failure Path — no feature PRDs

**Fixture:** `modes.workflow: standard`; `design/prd/` holds no `*.md` at depth 1.

**Input:** `/create-epics all`

**Expected behavior:**
1. The denominator glob returns 0
2. Reports "No PRDs found in `design/prd/` — run `/write-prd` first" and stops

**Assertions:**
- [ ] No EPIC.md and no index is written
- [ ] The message names `/write-prd`
- [ ] Verdict is **NOT ASSESSED** — no epic written (no PRDs is a missing input), never COMPLETE with zero epics
- [ ] DM-EPIC is not spawned

---

### Case 3: NOT ASSESSED — contract and stack rating missing at `standard`

**Fixture:**
- Case 1 fixture, but no contract under `docs/api/` (no `openapi.yaml`, `schema.graphql`, `*.proto` or `asyncapi.yaml`)
- `ADR-0006` has no `**Knowledge Risk**` row and `docs/stack-reference/VERSION.md` rates no component
- One PRD NFR ("goal list loads fast") has no budget in the PRD, the architecture or `docs/ops/slo.md`

**Input:** `/create-epics goals`

**Expected behavior:**
1. The load report and the epic's `## API Operations` carry `NOT CHECKED — API operations (no contract under docs/api/)` — at `standard` this is recorded, not a stop
2. `> **Stack Risk**:` and `## Stack Risk` read `NOT ASSESSED (no VERSION.md risk rating)`
3. The unsourced budget row reads `NOT SOURCED — goal list load budget`

**Assertions:**
- [ ] No Stack Risk level is guessed; no budget is invented
- [ ] The `NOT CHECKED` line appears both in the report and inside the affected epic
- [ ] The epic can still be written — the gaps are named in it
- [ ] Run verdict is COMPLETE — at `standard` the missing contract is recorded, not a stop

**Variant 3b — the same gap at `full`:** `modes.workflow: full`; `docs/architecture/architecture.md` names backend modules; every other `full` input (TR registry, control manifest, data model) is present; still no contract under `docs/api/`.

- [ ] The run stops and routes to `/api-design` with Verdict NOT ASSESSED — no epic written

---

### Case 4: Mode Variant — `minimal` tier decomposes the one-pager

**Fixture:**
- `modes.rigor` unset (`minimal`); `design/product/one-pager.md` with a four-item `## Build Order`
- No PRDs, ADRs, TR registry, control manifest or feature map

**Input:** `/create-epics all` (with no argument the skill first asks "Which layer or feature would you like to create epics for?")

**Expected behavior:**
1. Skips the PRD/ADR loads, reads the one-pager in full and groups the Build Order items into epics
2. Fills the template from the one-pager: **PRD** → `design/product/one-pager.md`; Governing ADRs → `N/A (minimal — no ADRs)`; PRD Requirements rows `Build Order item N` with ADR Coverage `N/A`; NFRs → `NOT CHECKED — no NFR budgets at minimal (the one-pager has none)`
3. Derives layer order from `## Build Order` and does not send the user to `/map-features`

**Assertions:**
- [ ] No PRD, ADR, TR-registry or manifest is required, and none is demanded
- [ ] The untraced-requirement check is skipped at this tier
- [ ] With the one-pager absent it reports "No `design/product/one-pager.md` — run `/brainstorm` first" and stops with Verdict NOT ASSESSED — no epic written

---

### Case 5: Edge Case — gaps flagged before writing; existing epic updated in place

**Fixture:**
- Otherwise the Case 1 fixture, with the `full` inputs present (11-section Approved PRD, TR registry, control manifest, contract, data model)
- `modes.workflow: full`; TR-goals-003 has no Accepted ADR; the reconcile record in `docs/api/changes/api-change-2026-10-20.md` needs `archiveGoal`, which is not in the contract; `savings_goal` needs a new column and no plan covers it
- `production/epics/goals-core/EPIC.md` and its index row already exist

**Input:** `/create-epics goals`

**Expected behavior:**
1. Warns about the untraced requirement (stories for it will be Blocked; run `/architecture-decision`)
2. Warns that `archiveGoal` is not in the contract (run `/api-design update <resource>`)
3. Warns that the schema change has no plan in `docs/data/migrations/` (run `/data-model migration <slug>`)
4. On approval, rewrites the epic after "May I write" and updates the existing index row

**Assertions:**
- [ ] All three warnings appear before the "Shall I create Epic" question
- [ ] `## PRD Requirements` marks TR-goals-003 `❌ No ADR`; `## API Operations` marks `archiveGoal` `❌ not in contract`
- [ ] The index keeps one row for `goals-core` — no duplicate row
- [ ] The existing EPIC.md is not overwritten without the "May I write" answer

---

### Case 6: Director Gate — full mode

**Fixture:** Case 1 fixture with review mode `full` (or `--review full`).

**Expected behavior:**
1. After the epics of the scope are written, spawns `delivery-manager` for DM-EPIC with `` Pass: `production/epics/index.md` path · EPIC.md paths · `docs/architecture/architecture.md` path ``
2. Parses `[DM-EPIC]: TOKEN` (the unbracketed `DM-EPIC: TOKEN` parses the same)

**Assertions:**
- [ ] REALISTIC → proceeds to Step 6; the index review line directly under the `# Epics Index` H1 reads `> **Delivery Manager Review (DM-EPIC)**: APPROVED [date]`, written after "May I write this to `production/epics/index.md`?"
- [ ] CONCERNS → `AskUserQuestion` "The delivery manager raised concerns about the epic structure. How do you want to proceed?" with `[A] Accept and proceed …`, `[B] Revise flagged items …`, `[C] Discuss further …`
- [ ] UNREALISTIC → story breakdown cannot begin; epics are revised (each rewrite asked) and DM-EPIC re-runs; stopping unresolved gives Verdict **BLOCKED**
- [ ] A first line that does not parse, or names another gate, is treated as CONCERNS-class
- [ ] The parent never reads `.claude/docs/director-gates/dm-epic.md`

---

### Case 7: Director Gate — lean mode

**Fixture:** Case 1 fixture; review mode `lean`.

**Assertions:**
- [ ] No `delivery-manager` spawn
- [ ] `production/epics/index.md` carries `> [DM-EPIC] skipped — Lean mode` as its review line (after "May I write")
- [ ] Verdict can be **COMPLETE**

---

### Case 8: Director Gate — solo mode

**Fixture:** Case 1 fixture; review mode `solo`.

**Assertions:**
- [ ] No director gate spawns
- [ ] The index review line is `> [DM-EPIC] skipped — Solo mode`

---

## Protocol Compliance

- [ ] One epic at a time: each epic definition is presented before it is created
- [ ] "May I write this to `<path>`?" before each EPIC.md and before the index
- [ ] Epic content comes only from PRDs, ADRs, the contract, the data model, the SLO document and the architecture doc; an unsourced value is `NOT SOURCED` / `NOT CHECKED`
- [ ] Never creates stories; never writes `modes.review_mode` or another fronted knob; nothing under `production/session-logs/`
- [ ] Ends with `/create-stories [epic-slug]` per epic and, once Foundation and Core exist, `/gate-check build`

---

## Coverage Notes

- Pipeline rubric mapping: P1 (EPIC.md and index schema — Case 1), P2 (layer order and
  `Depends On` order — Cases 1, 4), P3 (May-I-write per epic and for the index — Cases 1,
  5), P4 (DM-EPIC per review mode — Cases 6–8), P5 (PRDs, ADRs, contract and data model
  read before writing — Cases 1, 3).
- The `full`-tier stop when the architecture names backend modules and the contract is
  absent is Variant 3b (route to `/api-design`); the parallel data-model stop (route to
  `/data-model`) is not fixture-tested separately. Case 3 covers the `standard` behaviour.
- `docs.density` changes only prose depth; its effect on EPIC.md prose is not asserted.
