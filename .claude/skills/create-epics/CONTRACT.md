# /create-epics — Handoff Contract

## Role in Pipeline
Translates approved PRDs, the architecture, its ADRs and the API contract into one
EPIC.md file per architectural module, defining scope, ADR governance, NFR budgets,
API operations, owned entities, the rollout & flag plan, stack risk and requirement
traceability — sits between architecture review / `/api-design reconcile` and story
decomposition (`/create-stories`), and runs the DM-EPIC gate on the result.

## Inputs Required

### Files That Must Exist
| File | Required Fields / Sections | Read-Only? |
|------|---------------------------|-----------|
| Resolved config block (`--keys review_mode,automation,workflow,docs.density,story_granularity,feature_overrides`) | `workflow` (project tier; `feature_overrides` per PRD stem), `review_mode` (DM-EPIC), `story_granularity` (expected stories per epic), `docs.density` (prose depth), `automation` | Yes |
| `design/product/feature-map.md` | Main table `\| Feature \| Category \| Layer \| Tier \| Status \| PRD \| Depends On \|` — feature list, layer, tier, status, dependency order | Yes |
| `design/prd/<feature-slug>.md` | `## Summary` (Quick reference: Layer, Tier, Key deps), `## Functional Requirements`, `## Non-Functional Requirements`, `## Configuration & Flags`, `## Acceptance Criteria` (the tier's required sections: 11 at `full`, 8 + conditional `## Business Rules & Calculations` at `standard`) | Yes |
| `docs/architecture/architecture.md` | Module ownership, API boundaries, NFR budgets | Yes |
| `docs/architecture/adr-NNNN-<slug>.md` (all governing ADRs) | `## Status`, `## PRD Requirements Addressed`, `## Decision`, `## Stack Compatibility` (`**Knowledge Risk**` row) | Yes |
| `docs/architecture/control-manifest.md` | `Manifest Version:` date in header | Yes |
| `docs/architecture/tr-registry.yaml` | TR-IDs `TR-<feature-slug>-NNN` with `prd`, requirement text, `status` | Yes |
| API contract — `docs/api/openapi.yaml` (or `docs/api/schema.graphql`, `docs/api/<service>.proto`, `docs/api/asyncapi.yaml`) + latest `docs/api/changes/api-change-*.md` | Operations per module (`operationId` + method/path, or the style's equivalent); the reconcile record of operations the UX specs need | Yes (required at `full` when the architecture names backend modules; else `NOT CHECKED` in the epic) |
| `docs/data/data-model.md` (+ `docs/registry/architecture.yaml` when present) | `## Ownership`, `## Data Classification`; `data_ownership`, `interfaces` | Yes (same rule as the contract) |
| `docs/data/migrations/NNNN-<slug>.md` | `## Change`, `## Status` for plans touching owned entities | Yes (if exist) |
| `docs/ops/slo.md` | `## Critical User Journeys`, `## SLIs & SLOs` — NFR budget source | Yes (if exists) |
| `docs/stack-reference/VERSION.md` | Pinned components, versions, Knowledge Risk | Yes |
| `design/product/one-pager.md` (`minimal` only) | `## Build Order`, `## Core User Journey`, `## Scope & Non-Goals` | Yes |

### Preconditions
- At `full`: `/create-control-manifest` has been run and `docs/architecture/control-manifest.md` exists; `/architecture-review` has passed (at minimum Foundation and Core ADRs are Accepted); `/api-design reconcile` has run when the product has UI and a backend
- At `standard`: critical (Foundation-layer) ADRs are Accepted; the manifest is read if present
- At `minimal`: the skill is optional (`/create-stories` synthesizes the epic from the one-pager); if run, only `design/product/one-pager.md` is required
- All in-scope PRDs have `> **Status**: Approved` (or `Implemented`) and the matching feature-map `Status`
- The target layer's PRDs are stable — do not run for the Feature layer until Core is nearly complete

## Outputs Produced

### Files Written
| File | Guaranteed Fields / Sections | Notes |
|------|------------------------------|-------|
| `production/epics/<epic-slug>/EPIC.md` | Header `> **Layer**`, `> **PRD**` path(s), `> **Architecture Module**`, `> **Status**: Ready`, `> **Stories**`, `> **Stack Risk**`; `## Overview`, `## Governing ADRs` table, `## PRD Requirements` table with TR-IDs and ADR coverage, `## Non-Functional Requirements` table, `## API Operations` table, `## Owned Entities` table, `## Rollout & Flags`, `## Stack Risk`, `## Definition of Done`, `## Next Step` | Created per approved epic (e.g. `production/epics/goals-core/EPIC.md` for Moa's goals module) |
| `production/epics/index.md` | DM-EPIC review line under the H1; `Last Updated`, `Stack`; table columns `Epic`, `Layer`, `Feature`, `PRD`, `Stories`, `Status` | Created or updated in place (one row per epic slug) |

### Output Guarantees
- Every EPIC.md contains a `## Governing ADRs` table with at least one row (or a documented note if none apply — `N/A (minimal — no ADRs)` at `minimal`)
- Every EPIC.md contains a `## PRD Requirements` table where each row has a `TR-ID` and an `ADR Coverage` cell (either `ADR-NNNN ✅` or `❌ No ADR`); at `minimal` the rows are `Build Order item N`
- Every EPIC.md contains `## Non-Functional Requirements`, `## API Operations` and `## Owned Entities` — filled from their sources, or carrying a `NOT CHECKED — <input> absent` / `NOT SOURCED — <what>` line; never an invented value and never a silently empty table
- An operation the epic needs that is not in the contract is listed in `## API Operations` with status `❌ not in contract`
- `## Rollout & Flags` lists each flag with key, default, owner and removal date from the PRD's `## Configuration & Flags`
- `> **Stack Risk**` is `LOW`, `MEDIUM`, `HIGH` or `NOT ASSESSED (no VERSION.md risk rating)` — never a guessed level
- `## Definition of Done` names the evidence per story type (Logic, Integration, UI, E2E, Config) and the migration floor; whether missing evidence blocks is left to `testing.strict.logic`, `.integration`, `.ui`, `.e2e` and `.config` at `/story-done`
- The `> **PRD**:` field in the EPIC.md header is a valid relative path to the source PRD(s) (`design/product/one-pager.md` at `minimal`)
- The `> **Layer**:` field is one of: Foundation, Core, Feature, Presentation
- The `> **Status**:` field is set to `Ready`
- The `> **Stories**:` field reads `Not yet created — run /create-stories [epic-slug]`
- Untraced requirements (TR-IDs with no ADR) are flagged in the PRD Requirements table with `❌ No ADR`
- `production/epics/index.md` has exactly one row for every epic written in this run
- The DM-EPIC outcome is recorded in `production/epics/index.md` as `> **Delivery Manager Review (DM-EPIC)**: APPROVED | CONCERNS (accepted) | REVISED [date]`, or the skip note `> [DM-EPIC] skipped — Lean mode` / `— Solo mode`
- A run that stops on a missing required input (no `design/product/one-pager.md` at `minimal`, no PRDs in `design/prd/`, no eligible feature in the requested scope, or the API contract / data model required at `full`) writes no EPIC.md and no index row and ends with the run verdict `NOT ASSESSED`, naming the input and the skill that creates it

## Director Gate
- **DM-EPIC** (`delivery-manager`, `.claude/docs/director-gates/dm-epic.md`), spawned after the epics and the index are written, before any story is created
- Pass: `production/epics/index.md` path · EPIC.md paths · `docs/architecture/architecture.md` path
- Tokens: `REALISTIC` (APPROVE-class) / `CONCERNS` (CONCERNS-class) / `UNREALISTIC` (REJECT-class); the first reply line is parsed as `[DM-EPIC]: TOKEN`
- Review mode: `full` spawns; `lean` skips every gate whose ID does not end in `-PHASE-GATE` (so DM-EPIC is skipped); `solo` skips all gates

## Immutability Rules
- READS but does NOT modify: `design/product/feature-map.md`, all PRD files, `design/product/one-pager.md`, `docs/architecture/architecture.md`, all ADR files matching `docs/architecture/adr-NNNN-<slug>.md`, `docs/architecture/control-manifest.md`, `docs/architecture/tr-registry.yaml`, the API contract and change records under `docs/api/`, `docs/data/`, `docs/registry/architecture.yaml`, `docs/ops/slo.md`, `docs/stack-reference/VERSION.md`
- MODIFIES: `production/epics/<epic-slug>/EPIC.md` (creates; rewrites only on a DM-EPIC revision, each write approved), `production/epics/index.md` (creates or updates)

## Hard Constraints (Never Violate)
- Never create story files — this skill stops at the epic level
- Never invent content not sourced from PRDs, ADRs, the API contract, the data model, the SLO document or the architecture doc
- Never skip the per-epic approval prompt before writing
- Never write an EPIC.md without first presenting the epic definition to the user
- Never mark a TR-ID as covered by an ADR unless that ADR's `## Status` is `Accepted`
- Never mark an API operation `in contract` unless it was found in the contract file
- Never create epics for a layer whose dependency layer is not yet substantially complete
- Never treat an unparseable DM-EPIC reply as approval (it is CONCERNS-class)

## Downstream Skill Expects
**Next skill:** /create-stories

It will read:
- `production/epics/<epic-slug>/EPIC.md` — specifically: `> **Layer**:`, `> **PRD**:` path, `> **Architecture Module**:`, the full `## Governing ADRs` table (ADR IDs and summaries), the full `## PRD Requirements` table (TR-IDs and ADR coverage status), `## API Operations` (contract references), `## Owned Entities` (migration plan paths), `## Rollout & Flags` (flag keys) and `## Non-Functional Requirements` (budgets for the stories' NFR criteria)
- `production/epics/index.md` — to enumerate available epics when no argument is given

It assumes:
- The `> **PRD**:` path in EPIC.md resolves to a readable file
- Every ADR listed in `## Governing ADRs` exists as a file and has an `Accepted` status
- TR-IDs in `## PRD Requirements` match entries in `docs/architecture/tr-registry.yaml`
- Every contract reference in `## API Operations` with status `in contract` resolves in the contract file
- The epic slug used in the directory name matches the slug referenced in `index.md`
- `> **Status**: Ready` with `> **Stories**: Not yet created` means stories have NOT yet been created (it will replace that line with a `## Stories` table)

## Known Fragile Points
- If the EPIC.md template structure changes (section names, header field names, table column order), `/create-stories` will silently fail to parse governance data and may produce incomplete or incorrect stories
- If `tr-registry.yaml` is regenerated with renumbered IDs after EPIC.md files are written, the TR-IDs in existing EPIC.md files become stale and mislead `/create-stories`
- If an ADR is retroactively changed from `Accepted` to `Proposed` after the epic is written, the EPIC.md will still show it as governing — `/create-stories` will embed it without a Blocked flag
- If the API contract changes after the epic is written (an operation renamed or removed by `/api-design`), the `## API Operations` references go stale; `/story-readiness` catches the missing operation per story, not per epic
- If `design/product/feature-map.md` layer assignments change after epics are created, the `> **Layer**:` field in existing EPIC.md files will be incorrect and `/create-stories` will use the wrong layer context
- An EPIC.md written while DM-EPIC returned UNREALISTIC and the user stopped keeps `> **Status**: Ready`; only the index's missing review line and the skill's BLOCKED verdict record that the structure was not accepted
