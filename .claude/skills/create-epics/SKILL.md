---
name: create-epics
description: "Epics from PRDs, architecture and the API contract — one per module — with untraced requirements."
argument-hint: "[feature-slug | layer: foundation|core|feature|presentation | all] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/create-epics/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,docs.density,story_granularity,feature_overrides`

Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).


# Create Epics

An epic is a named, bounded body of work that maps to one architectural module.
It defines **what** needs to be built — the PRD requirements it carries, the
non-functional budgets it must hold, the API operations it exposes, the entities
it owns, and the migrations and feature flags it ships behind — and **who owns it
architecturally**. It does not prescribe implementation steps — that is the job of
stories.

**Run this skill once per layer** as you approach that layer in development.
Do not create Feature layer epics until Core is nearly complete — the design
will have changed.

**Output:** `production/epics/<epic-slug>/EPIC.md` + `production/epics/index.md`

**Next step after each epic:** `/create-stories [epic-slug]`

**When to run:** After `/create-control-manifest` and `/architecture-review` pass
(at `full`), and after `/api-design reconcile` has aligned the API contract with
the key UX specs. At `standard`, critical ADRs + a control manifest suffice. At
`minimal`, this skill is **optional and not part of the path** — `/create-stories`
synthesizes the epic from `design/product/one-pager.md` itself (Option A). If run
anyway, it decomposes directly from the one-pager's `## Build Order` with no
PRD/ADR/manifest prerequisite.

> **At `minimal`, this skill is optional — `/create-stories` synthesizes the epic**
> (Option A). At that tier `/create-stories` reads `design/product/one-pager.md`
> directly, writes a lightweight implicit `production/epics/<slug>/EPIC.md`, and
> generates stories from the `## Build Order` list — so the path is `/brainstorm` →
> `/create-stories` → `/dev-story`, with no separate `/create-epics` or
> `/sprint-plan` step. **At `standard`/`full` an epic IS required**:
> `/create-stories` reads `production/epics/<epic-slug>/EPIC.md`, and skipping this
> skill there leaves `/dev-story` with no story to implement — a dead end, not a
> shortcut.

---

## 1. Parse Arguments


See `.claude/docs/director-gates.md` for the full check pattern. Individual gate definitions live in `.claude/docs/director-gates/<gate-id>.md` — the spawned agent reads its own gate file; do not read it in the parent session.


**`workflow`** (per `.claude/docs/workflow-modes.md`):

create-epics runs project-wide: it uses the project-level tier for its
prerequisite expectations and consults
`workflow_overrides.feature_overrides.<prd-stem>` per feature when reading each
in-scope PRD (the `feature_overrides` line of the block above). See "Workflow tier
adjustment" in Step 2.

**`story_granularity`** — it sizes the epic's story breakdown: expect **3–5**
child stories per epic at `coarse`, **5–10** at `balanced`, **10–20** at `fine`.
When nothing sets it, `modes.rigor` supplies it (`minimal` → `coarse`).

**`docs.density`** — it controls the *depth* of each epic's written scope and
rationale, not the story count (that is `story_granularity`). `modes.rigor` sets
it alongside `workflow`; set `docs.density` explicitly to vary epic prose alone:
`terse` = scope as bullets, one-line rationale; `balanced` = a scope paragraph
with light rationale; `thorough` = full scope prose with governing-ADR rationale
and risk discussion. The EPIC.md tables (PRD requirements, governing ADRs,
non-functional requirements, API operations, owned entities, rollout & flags) are
structural and stay whole at every density.

**Modes:**
- `/create-epics all` — process all features in layer order
- `/create-epics layer: foundation` — Foundation layer only (identity & auth, data access, observability)
- `/create-epics layer: core` — Core layer only
- `/create-epics layer: feature` — Feature layer only
- `/create-epics layer: presentation` — Presentation layer only
- `/create-epics [feature-slug]` — the epic for the module that owns one feature (e.g. `/create-epics goals`)
- No argument — ask: "Which layer or feature would you like to create epics for?"

---

## 2. Load Inputs

> **`minimal` tier** — skip Steps 2a and 2b. Read `design/product/one-pager.md` in
> full (it is one page) and decompose against its `## Build Order`,
> `## Core User Journey` and `## Scope & Non-Goals`. Do not require PRDs, ADRs, the
> TR registry, the control manifest or the feature map. If the one-pager is absent,
> report "No `design/product/one-pager.md` — run `/brainstorm` first" and stop with
> **Verdict: NOT ASSESSED** — no epic written.
> Read `docs/api/` and `docs/data/data-model.md` only if they exist. Then continue
> to Step 3.

### Step 2a — Summary scan (fast, fail-open)

**Establish the denominator first.** Glob `design/prd/*.md`. That directory holds
only feature PRDs at depth 1 — review logs live in `design/prd/reviews/` and the
product-level documents in `design/product/` — so there is no exclusion list to
apply. Call the count **N**. If N is 0, there are no feature PRDs — report "No
PRDs found in `design/prd/` — run `/write-prd` first" and stop with
**Verdict: NOT ASSESSED** — no epic written.

Scan for Summary sections:

```
Grep pattern="^## Summary" glob="design/prd/*.md" output_mode="content" -A 5
```

Interpret the **M** matches against N. These are three different outcomes, and
a zero-match scan is **never** the same as "nothing in scope":

| Result | Meaning | Action |
|---|---|---|
| **M = N** | Every PRD has a Summary. | For `layer:`/`[feature-slug]` modes, use the Summary Quick reference (Layer/Tier/Key deps) to pick the in-scope set; skip full-reading the rest. |
| **0 < M < N** | Partial adoption — older PRDs predate `## Summary`. | Scope the M by their Summaries; determine the scope of the **N − M** unmatched from `design/product/feature-map.md` (Layer/Tier) and full-read those. |
| **0 matches, N > 0** | Expected for PRDs written before `/write-prd` emitted `## Summary`, or reverse-documented ones. | Determine scope for **all N** from `design/product/feature-map.md` and full-read the in-scope set. This is the pre-optimization behaviour — correct, only more expensive. Note once: "No `## Summary` sections found across [N] PRDs — scoping from `design/product/feature-map.md` instead of Summary." |

**Never treat an absent `## Summary` as an absent feature.** The scan narrows the
*read* set when it succeeds; it never shrinks the *in-scope* set. In `all` mode
every feature is in scope regardless of Summary, so the scan is a convenience
only — never a filter.

### Step 2b — Full document load (in-scope features only)

Using the Step 2a grep results, identify which features are in scope. Read full
documents **only for in-scope features** — do not read PRDs or ADRs for
out-of-scope features or layers.

Read for in-scope features:

- `design/product/feature-map.md` — authoritative feature list (main table
  `| Feature | Category | Layer | Tier | Status | PRD | Depends On |`): layer, tier,
  status, dependencies
- In-scope PRDs only (`> **Status**: Approved` — or `Implemented` for a
  brownfield feature — filtered by Step 2a results). Read `## Functional Requirements`,
  `## Non-Functional Requirements`, `## Configuration & Flags`,
  `## Acceptance Criteria` and the non-contract `## API & Data Impact` in full;
  the rest only as needed.
- `docs/architecture/architecture.md` — module ownership and API boundaries.
  Map its headings first (`Grep pattern="^## " … -n`) and read the layers-and-modules
  section plus its NFR budgets section, not the whole document.
- Accepted ADRs **whose domains cover in-scope features only** — skip ADRs for
  unrelated domains entirely. For each in-scope ADR, load only the "PRD
  Requirements Addressed", "Decision", and "Stack Compatibility" sections —
  never an unbounded full read:
  ```
  Grep pattern="^## (PRD Requirements Addressed|Decision|Stack Compatibility)" path="docs/architecture/[adr-file].md" output_mode="content" -n
  ```
  then `Read(offset, limit)` bounded to each match through the next `## `
  heading (or to end of file for the last match). This matters most on a
  large ADR — measured at 47k tokens this way vs. 103k for an unbounded
  read of the same size file.
- `docs/architecture/control-manifest.md` — manifest version date from header
- `docs/architecture/tr-registry.yaml` — for tracing requirements to ADR coverage
  (grep `id: TR-<feature-slug>-` per in-scope feature, not the whole registry)
- The API contract — whichever of `docs/api/openapi.yaml`, `docs/api/schema.graphql`,
  `docs/api/*.proto` or `docs/api/asyncapi.yaml` exists — grep the operations that
  belong to each in-scope module (OpenAPI `operationId` and path, GraphQL
  `Query`/`Mutation` fields, `rpc` names, AsyncAPI channels). Also read the most
  recent `docs/api/changes/api-change-*.md` — the `/api-design reconcile` record of
  what the key UX specs need from the contract.
- `docs/data/data-model.md` — the `## Ownership` and `## Data Classification`
  sections for the entities each module owns, and `docs/registry/architecture.yaml`
  (`data_ownership`, `interfaces`) when present
- `docs/data/migrations/*.md` — the migration plans that touch those entities
  (their `## Change` and `## Status` sections)
- `docs/ops/slo.md` — `## Critical User Journeys` and `## SLIs & SLOs`, the source
  of the epic's NFR budgets
- `docs/stack-reference/VERSION.md` — pinned stack components, versions and their
  Knowledge Risk

Report: "Loaded [N] PRDs, [M] ADRs, API contract [path | none], data model
[present | absent], stack: [components + versions from VERSION.md | not pinned]."

If the requested scope holds no eligible feature — no feature in the named layer or
slug, or none of its PRDs is `Approved` (or `Implemented`) — say which, name the
skill that clears it (`/write-prd` for a missing PRD, `/prd-review` for one not yet
Approved), and stop with **Verdict: NOT ASSESSED** — no epic written.

An input that does not exist is named, never silently skipped — e.g.
`NOT CHECKED — API operations (no contract under docs/api/)`. That line goes into
the affected epic's section as well as this report.

> **Workflow tier adjustment** (resolved in Step 1; per-feature via
> `feature_overrides`). The inputs above are the `full` baseline:
> - **`full`** — every in-scope PRD must be Approved with all 11 contract
>   sections; TR registry + control manifest are required inputs; untraced
>   requirements (Step 4) are flagged before proceeding. When the architecture
>   names backend modules, the API contract and the data model are required
>   inputs — if either is absent, stop and route to `/api-design` or `/data-model`
>   with **Verdict: NOT ASSESSED** — no epic written.
> - **`standard`** — PRDs need the 8 required sections (+ conditional
>   `## Business Rules & Calculations`) approved; only **critical
>   (Foundation-layer) ADRs** are expected; the control manifest is read if
>   present, not required. A missing contract or data model is recorded in the
>   epic as `NOT CHECKED`, not a stop. A feature pinned higher via
>   `feature_overrides` must still meet its higher bar.
> - **`minimal`** — decompose against `design/product/one-pager.md` + its
>   `## Build Order`. Do not require PRDs, ADRs, the TR registry, or the
>   manifest; skip the untraced-requirement gate. If run, the epic is still
>   produced — but note `/create-stories` also synthesizes one from the one-pager
>   when this skill is skipped (the default `minimal` path).

---

## 3. Processing Order

Process in dependency-safe layer order:
1. **Foundation** (no dependencies — identity & auth, the primary data store and
   data access, API conventions, observability)
2. **Core** (depends on Foundation — the product's core domain, e.g. Moa's goals
   and auto-debit payments)
3. **Feature** (depends on Core)
4. **Presentation** (depends on Feature + Core)

Within each layer, use the order from `design/product/feature-map.md` — a feature
comes after every feature in its `Depends On` column.

> **At `minimal` there is no `design/product/feature-map.md`** — `/map-features` is
> not required at that tier, so nothing has produced one. Derive the layer split
> and ordering from `design/product/one-pager.md` instead: its **`## Build Order`**
> section names what must exist first. Do not stop, and do not send the user to
> `/map-features` to satisfy an ordering hint — the tier deliberately skips it.

---

## 4. Define Each Epic

For each feature, map it to an architectural module from `architecture.md`. One
module that serves several features is **one** epic listing every PRD it carries;
one feature split across two modules becomes two epics, each naming the part it
owns. The epic slug is the module slug (e.g. `goals-core` for Moa's goals module).

At `minimal`, group the `## Build Order` items that belong together (same layer, or
the same part of the product) into one epic each; a small MVP is often a single
epic. Each item becomes a scope line — there are no TR-IDs at this tier.

Check ADR coverage against the TR registry **per the resolved tier** (Step 1):
- **`full`** — trace every TR-ID; warn on each untraced requirement (below).
- **`standard`** — only **critical (Foundation-layer) ADRs** are expected; trace
  those. Treat untraced non-critical requirements as informational (list them, do
  not block or emit the Blocked-story warning).
- **`minimal`** — skip this check entirely (no TR registry / ADR expected).

- **Traced requirements**: TR-IDs that have an Accepted ADR covering them (its
  `## PRD Requirements Addressed` table names the TR-ID)
- **Untraced requirements**: TR-IDs with no ADR — warn before proceeding (full only)

Then collect the epic's delivery content:

- **Non-functional requirements** — every budget the module must hold: latency and
  error-rate SLOs from `docs/ops/slo.md` for the journeys it serves, the PRDs'
  `## Non-Functional Requirements` (performance, availability, security & privacy,
  accessibility, localization), and the architecture's NFR budgets. A budget with
  no source is written as `NOT SOURCED — <what>`, never invented.
- **API operations** — the contract operations this module implements, plus the
  operations the PRDs or the reconcile record need that are **not** in the
  contract yet.
- **Owned entities** — from the data model's ownership: the entities this module
  is the single writer of, with their classification (`Public`, `Internal`,
  `Confidential`, `PII`, `Sensitive-PII`) and the migration plan that creates or
  changes each one.
- **Rollout & flags** — the flags from the PRDs' `## Configuration & Flags` (key,
  default, owner, removal date) and the rollout constraints: migrations run
  Expand-first before the application deploy; mobile work waits on store review and
  ships behind a flag or a phased release.
- **Stack Risk** — the highest `**Knowledge Risk**` among the governing ADRs'
  components (their `## Stack Compatibility` table), cross-checked against
  `docs/stack-reference/VERSION.md`. With no rating from the governing ADRs and none in
  VERSION.md, write `NOT ASSESSED (no VERSION.md risk rating)` — never guess a level.

Present to user before writing anything:

```
## Epic: [Epic Name]

**Layer**: [Foundation / Core / Feature / Presentation]
**PRD**: design/prd/[feature-slug].md [, more when the module serves several features]
**Architecture Module**: [module name from architecture.md]
**Governing ADRs**: [ADR-NNNN, ADR-MMMM]
**Stack Risk**: [LOW / MEDIUM / HIGH / NOT ASSESSED — highest risk among governing ADRs]
**PRD Requirements Covered by ADRs**: [N / total]
**Untraced Requirements**: [list TR-IDs with no ADR, or "None"]
**NFR Budgets**: [N rows; unsourced ones named]
**API Operations**: [N in contract; K missing: operation names — or NOT CHECKED line]
**Owned Entities**: [entity (classification) list, or "None"]
**Migrations**: [plan paths, or "None"]
**Flags**: [flag keys, or "None"]
```

If there are untraced requirements:
> "⚠️ [N] requirements in [feature] have no ADR. The epic can be created, but
> stories for these requirements will be marked Blocked until ADRs exist.
> Run `/architecture-decision` first, or proceed with placeholders."

If operations are missing from the contract:
> "⚠️ [K] operations this epic needs are not in the API contract: [names]. Stories
> for them cannot reference an operation that does not exist yet. Run
> `/api-design update <resource>` first, or proceed and those stories are marked
> Blocked until the contract has them."

If an owned entity needs a schema change and no plan covers it:
> "⚠️ [entity] needs a schema change but no plan exists in `docs/data/migrations/`.
> Run `/data-model migration <slug>` before its stories are implemented."

Use `AskUserQuestion`:
- Prompt: "Shall I create Epic: [name]?"
- Options:
  - `[A] Yes, create it`
  - `[B] Skip this epic`
  - `[C] Pause — I need to write ADRs, contract operations or migration plans first`

---

## 5. Write Epic Files

After approval, ask: "May I write this to `production/epics/<epic-slug>/EPIC.md`?"

After user confirms, write:

### `production/epics/<epic-slug>/EPIC.md`

```markdown
# Epic: [Epic Name]

> **Layer**: [Foundation / Core / Feature / Presentation]
> **PRD**: `design/prd/[feature-slug].md` [comma list when the module serves several features]
> **Architecture Module**: [module name]
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories [epic-slug]`
> **Stack Risk**: [LOW / MEDIUM / HIGH / NOT ASSESSED]

## Overview

[1 paragraph describing what this epic implements, derived from the PRD Overview
and the architecture module's stated responsibilities]

## Governing ADRs

| ADR | Decision Summary | Stack Risk |
|-----|-----------------|------------|
| ADR-NNNN: [title] | [1-line summary] | LOW/MEDIUM/HIGH |

## PRD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-[feature-slug]-001 | [requirement text from registry] | ADR-NNNN ✅ |
| TR-[feature-slug]-002 | [requirement text] | ❌ No ADR |

## Non-Functional Requirements

| NFR | Budget / Target | Source | Verified by |
|-----|-----------------|--------|-------------|
| [e.g. `POST /v1/goals` latency] | [p95 ≤ 300 ms] | [`docs/ops/slo.md` — journey "Create a savings goal"] | [load test on staging] |
| [e.g. goal list first paint (web)] | [LCP p75 ≤ 2.5 s] | [PRD `## Non-Functional Requirements`] | [UI story evidence] |
| [e.g. goal form accessibility] | [WCAG 2.2 AA] | [`design/accessibility-requirements.md`] | [UI story evidence + axe report] |

## API Operations

| Operation | Method & Path | Contract Reference | Consumers | Status |
|-----------|---------------|--------------------|-----------|--------|
| [createGoal] | [POST /v1/goals] | [`docs/api/openapi.yaml#/paths/~1v1~1goals/post`] | [web, ios, android] | in contract |
| [operation the PRD or a UX spec needs] | — | — | — | ❌ not in contract |

## Owned Entities

| Entity | Classification | Migration Plan |
|--------|----------------|----------------|
| [savings_goal] | [Confidential] | [`docs/data/migrations/NNNN-[slug].md` or "None"] |

## Rollout & Flags

| Flag | Default | Owner | Removal Date |
|------|---------|-------|--------------|
| [`goals.v2-progress-ring`] | [off] | [owner] | [YYYY-MM-DD] |

[Rollout constraints for this epic: migration ordering (Expand before the
application deploy, Contract only after every reader — including the minimum
supported app version — has moved), store review lead time for mobile work, and
which flags gate which behaviour. Each release's staged rollout is planned by
`/rollout-plan`.]

## Stack Risk

[The highest Knowledge Risk among the governing ADRs' components, and for each
MEDIUM/HIGH component what the stories must verify against
`docs/stack-reference/<component>/` — or `NOT ASSESSED (no VERSION.md risk rating)`.]

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from the epic's PRDs are verified
- All Logic, Integration and E2E stories have passing tests at the paths their
  Test Evidence sections name (Logic per `testing.patterns` or `tests/unit/`,
  Integration and contract tests under `tests/integration/` and `tests/contract/`,
  E2E under `tests/e2e/`)
- All UI and E2E stories have retained evidence in `production/qa/evidence/`
- All Config stories are covered by a passing smoke check (`production/qa/smoke-*.md`)
- Every story whose `**Migration**` is not `None` has its migration dry-run log in
  `production/qa/evidence/` — at every `qa.level`
- The budgets in Non-Functional Requirements are met, or a deviation is recorded
- Every operation in API Operations exists in the contract and matches what shipped

Whether a missing piece of evidence blocks a story is decided per story type by
`testing.strict` (`logic`, `integration`, `ui`, `e2e`, `config`) when `/story-done`
closes it.

## Next Step

Run `/create-stories [epic-slug]` to break this epic into implementable stories.
```

At `minimal`, fill the same template from the one-pager: **PRD** →
`design/product/one-pager.md`; Governing ADRs → `N/A (minimal — no ADRs)`; PRD
Requirements → one row per `## Build Order` item (`Build Order item N` in the
TR-ID column, ADR Coverage `N/A`); Non-Functional Requirements →
`NOT CHECKED — no NFR budgets at minimal (the one-pager has none)` unless the user
states one; API Operations and Owned Entities from `docs/api/` and the data model
when they exist, else `N/A (minimal — no contract / data model)`.

### Update `production/epics/index.md`

Ask "May I write this to `production/epics/index.md`?", then create or update the
master index:

```markdown
# Epics Index

> **Delivery Manager Review (DM-EPIC)**: [recorded in Step 5b]

Last Updated: [date]
Stack: [components + versions from docs/stack-reference/VERSION.md, or "not pinned"]

| Epic | Layer | Feature | PRD | Stories | Status |
|------|-------|---------|-----|---------|--------|
| [name] | Foundation | [feature-slug] | [PRD path] | Not yet created | Ready |
```

Update an existing row for the same epic slug instead of appending a second one.

---

## 5b. Delivery Manager Epic Structure Gate

DM-EPIC reviews the written structure — its Context is the index path and the
EPIC.md paths — so it runs after Step 5 and before any story is broken out.

**Review mode check** — apply before spawning DM-EPIC (`--review` overrides the
resolved `review_mode`):
- `full` → spawn as normal.
- `lean` → **skip every gate whose ID does not end in `-PHASE-GATE`**. Note: `[GATE-ID] skipped — Lean mode`
  DM-EPIC does not end in `-PHASE-GATE`, so lean skips it: record
  `[DM-EPIC] skipped — Lean mode`.
- `solo` → skip all gates. Note: `[GATE-ID] skipped — Solo mode`

When skipped, write the skip note as the review line of `production/epics/index.md`
(`> [DM-EPIC] skipped — Lean mode`, or `— Solo mode`), ask before writing, and
proceed to Step 6.

After all epics for the current layer are written (Step 5 completed for all
in-scope features), spawn `delivery-manager` via `Agent` using gate **DM-EPIC**. The
prompt instructs the agent to read `.claude/docs/director-gates/dm-epic.md` first —
do not read it or paste it yourself.

- Pass: `production/epics/index.md` path · EPIC.md paths · `docs/architecture/architecture.md` path
- Fill: the index path; every EPIC.md path written or updated in this run; the
  architecture path (pass it even when the file is absent at `minimal` — the gate
  reports its own `NOT CHECKED` line).

Parse the first line of the reply as `[DM-EPIC]: TOKEN` (`DM-EPIC: TOKEN` without
the brackets parses the same), and map the token with the verdict classes of
`.claude/docs/director-gates.md` (`## Standard Verdict Format`):

- **APPROVE-class** (`REALISTIC`) → present the assessment and proceed to Step 6.
- **CONCERNS-class** (`CONCERNS`) → present the concerns, then use `AskUserQuestion`:
  - Prompt: "The delivery manager raised concerns about the epic structure. How do you want to proceed?"
  - Options:
    - `[A] Accept and proceed — I accept the delivery manager's concerns`
    - `[B] Revise flagged items — split, merge or reorder epics as recommended`
    - `[C] Discuss further — I want to reconsider the scope`
- **REJECT-class** (`UNREALISTIC`) → present the blockers. Story breakdown cannot
  begin until they are resolved: offer to revise the epic boundaries (split
  overscoped epics, merge underscoped ones, reorder by dependency), rewrite the
  affected EPIC.md files and the index — each write asked — and re-run the gate.
- A first line that does not parse, or names another gate, is not an approval —
  treat it as CONCERNS-class and say the verdict line was missing.

If [A]: proceed to Step 6.
If [B]: revise the epic definitions from Step 4, rewrite the affected files (ask
before each write), and re-run DM-EPIC.
If [C]: discuss, then stop or revise. If the user stops with the structure
unresolved — or stops on an UNREALISTIC verdict — Verdict: **BLOCKED** — epic
structure not accepted; do not run `/create-stories` until it is.

**Record the outcome** as the review line of `production/epics/index.md` — show the
line, then ask "May I write this to `production/epics/index.md`?":

```markdown
> **Delivery Manager Review (DM-EPIC)**: APPROVED [date]
```

(`CONCERNS (accepted) [date]` for [A]; `REVISED [date]` when a revision was
re-run to REALISTIC.)

---

## 6. Gate-Check Reminder

After writing all epics for the requested scope:

- **Foundation + Core complete**: These are required for the Validation → Build
  gate. Run `/gate-check build` to check readiness.
- **Reminder**: Epics define scope. Stories define implementation steps. Run
  `/create-stories [epic-slug]` for each epic before engineers can pick up work.

---

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and
`autonomous` modes, see `.claude/docs/automation-modes.md` — the rules below
describe what collaborative mode requires, not universal behavior.

1. **One epic at a time** — present each epic definition before asking to create it
2. **Warn on gaps** — flag untraced requirements, operations missing from the
   contract and schema changes without a migration plan before proceeding
3. **Ask before writing** — per-epic approval before writing any file
4. **No invention** — all content comes from PRDs, ADRs, the API contract, the data
   model, the SLO document and the architecture doc; an unsourced value is written
   as `NOT SOURCED` or `NOT CHECKED`, never filled in
5. **Never create stories** — this skill stops at the epic level

After all requested epics are processed, or the run stops on a missing input:

- **Verdict: COMPLETE** — [N] epic(s) written. Run `/create-stories [epic-slug]` per epic.
- **Verdict: BLOCKED** — user declined all epics, or the DM-EPIC verdict was left
  unresolved.
- **Verdict: NOT ASSESSED** — a required input is missing (no
  `design/product/one-pager.md` at `minimal`, no PRDs in `design/prd/`, no eligible
  feature in the requested scope, or the API contract / data model this tier
  requires); no epic written. Name the missing input and the skill that creates it
  (`/brainstorm`, `/write-prd`, `/prd-review`, `/api-design`, `/data-model`).
