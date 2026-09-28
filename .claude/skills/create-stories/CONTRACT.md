# /create-stories — Handoff Contract

## Role in Pipeline
Decomposes a single epic into implementable story files by tracing PRD acceptance
criteria through ADR decisions, manifest rules, the API contract, migration plans,
feature flags and tracking-plan events — sits between `/create-epics` and
`/story-readiness` + `/dev-story`, and runs QL-STORY-READY on each story it writes.

## Inputs Required

### Files That Must Exist
| File | Required Fields / Sections | Read-Only? |
|------|---------------------------|-----------|
| Resolved config block (`--keys review_mode,automation,workflow,docs.density,story_granularity,feature_overrides,testing.strict,code_roots`) | `workflow` (per the epic's PRD stem via `feature_overrides`), `story_granularity` (AC load per story), `docs.density` (prose depth), `review_mode` (QL-STORY-READY), `automation`, `testing.strict` (QL-STORY-READY context), `code_roots` (the target root named in `**Stack Notes**` when a layer has several) | Yes |
| `production/epics/<epic-slug>/EPIC.md` | `> **Layer**:`, `> **PRD**:` path, `> **Architecture Module**:`, `## Governing ADRs` table, `## PRD Requirements` table with TR-IDs, `## Non-Functional Requirements`, `## API Operations`, `## Owned Entities`, `## Rollout & Flags` | Yes (only its Stories section is updated) |
| `design/prd/<feature-slug>.md` | The tier's required sections, especially `## Acceptance Criteria`, `## Business Rules & Calculations`, `## Edge Cases`, `## Non-Functional Requirements`, `## Configuration & Flags`, `## Success Metrics & Instrumentation` | Yes |
| `docs/architecture/adr-NNNN-<slug>.md` (all governing ADRs) | `## Status`, `## Summary`, `## Decision` (`### Implementation Guidelines`), `## Stack Compatibility` (`**Stack Components**`, `**Knowledge Risk**`), `## Last Verified` / `## Date` | Yes |
| `docs/architecture/control-manifest.md` | `## <Layer> Layer Rules` (required patterns, forbidden patterns, guardrails), `Manifest Version:` date in header | Yes |
| `docs/architecture/tr-registry.yaml` | All TR-IDs `TR-<feature-slug>-NNN` for the epic's feature, with stable `id` values | Yes |
| API contract named in the epic (`docs/api/openapi.yaml` or the GraphQL / proto / AsyncAPI file) | The operations the stories implement or call | Yes |
| `docs/data/migrations/NNNN-<slug>.md` named in the epic | `## Change`, `## Status` | Yes |
| `design/product/tracking-plan.md` | `## Events` rows owned by the epic's PRD | Yes (if exists) |
| `design/ux/<slug>.md` | States and `## API Data` of the screens the UI stories implement | Yes (if exist) |
| `docs/stack-reference/VERSION.md` | Pinned components and Knowledge Risk | Yes |
| `project.yaml` | `testing.patterns` (read with Read; no `resolve_config` label) | Yes |
| `production/qa/qa-plan-*.md` (most recent) | `## Automated Tests Required` — the heading from `.claude/docs/templates/test-plan.md` | Yes (if exists) |
| `design/product/one-pager.md` (`minimal` only) | `## Pitch`, `## Core User Journey`, `## Success Signal`, `## Scope & Non-Goals`, `## Build Order` | Yes |

### Preconditions
- At `standard`/`full`: `/create-epics` has been run and the target `EPIC.md` has `> **Status**: Ready`; the EPIC.md contains a populated `## PRD Requirements` table (not empty)
- At `full`: all governing ADRs listed in the EPIC.md exist as files; at `standard`: every critical (Foundation-layer) ADR exists
- At `minimal`: no epic is required — the skill synthesizes `production/epics/<slug>/EPIC.md` from `design/product/one-pager.md`
- Foundation epics have stories created before Core epics are started; Core before Feature; Feature before Presentation

## Outputs Produced

### Files Written
| File | Guaranteed Fields / Sections | Notes |
|------|------------------------------|-------|
| `production/epics/<epic-slug>/story-NNN-<slug>.md` | The story header contract below; `**Control Manifest Rules (this layer)**`; `## Acceptance Criteria`, `## Implementation Notes`, `## Out of Scope`, `## QA Test Cases`, `## Test Evidence`, `## Dependencies` | Created per story (e.g. `production/epics/goals-core/story-001-create-goal.md`); matched by the catalog glob `production/epics/*/story-*.md` |
| `production/epics/<epic-slug>/EPIC.md` | `## Stories` table replacing the "Not yet created" placeholder | Updated in place (at `minimal`: created as the implicit epic) |
| `production/epics/index.md` | The epic's `Stories` column | Updated in place when the index exists |

Story header contract (exact — shared with `/dev-story`, `/story-done` and `/story-readiness`):

```markdown
# Story NNN: [title]

> **Epic**: [epic name]
> **Status**: Ready
> **Layer**: [Foundation / Core / Feature / Presentation]
> **Type**: [Logic | Integration | UI | E2E | Config]
> **Surface**: [web | ios | android | mobile | api | admin | infra | analytics] (comma list allowed; first = primary)
> **Estimate**: [hours or t-shirt size]
> **Manifest Version**: [date from control-manifest.md header]
> **Last Updated**: [set by /dev-story when implementation begins]

**PRD**: `design/prd/[feature-slug].md`
**Requirement**: `TR-[feature-slug]-NNN`
**ADR Governing Implementation**: [ADR-NNNN: title]
**ADR Decision Summary**: [1-2 sentences]
**ADR Version**: [ADR `## Last Verified` date, else `## Date`, else `unversioned`]
**Stack**: [component + version] | **Risk**: [LOW / MEDIUM / HIGH]
**Stack Notes**: [from the ADR's Stack Compatibility section; target root when the layer has several]
**API Contract**: [`docs/api/openapi.yaml#/paths/...` or None]
**Migration**: [`docs/data/migrations/NNNN-slug.md` or None]
**Feature Flag**: [flag key or None]
**Analytics Events**: [event names from the tracking plan or None]
**ML**: [yes — only for stories implementing an ML/LLM capability; omit otherwise]
```

### Output Guarantees
- Every story file carries the header contract above, field for field; `**ML**:` appears only on stories implementing an ML/LLM capability
- Every story file contains a `TR-[feature-slug]-NNN` reference as its `**Requirement**` (or `TR-[feature-slug]-???` with a warning if the registry has no match; `Build Order item N` at `minimal`)
- Every story file contains an `**ADR Governing Implementation**:` line referencing at least one ADR, or an explicit `N/A — [reason]` note (`N/A (minimal — no ADRs)` at `minimal`)
- Every story file has a `> **Status**:` field — `Ready`, or `Blocked` with a `BLOCKED:` note when the governing ADR is `Proposed`, a needed operation is not in the contract, a schema change has no migration plan, or QL-STORY-READY returned INADEQUATE and the criteria were not revised
- Every story file has a `> **Type**:` field — one of: Logic, Integration, UI, E2E, Config
- Every story file has a `> **Surface**:` field with values from `web`, `ios`, `android`, `mobile`, `api`, `admin`, `infra`, `analytics`, primary first
- Every story file has a `> **Manifest Version**:` field matching the date from `docs/architecture/control-manifest.md`'s header at time of writing (`N/A (minimal — no control manifest)` at `minimal`)
- Every story file has `**API Contract**`, `**Migration**`, `**Feature Flag**` and `**Analytics Events**` fields — a value or `None`, never omitted
- Every story file has a `## Test Evidence` section stating the expected evidence location for its type (Logic: unit test per `testing.patterns` or `tests/unit/`; Integration: `tests/integration/` or `tests/contract/`; UI: `production/qa/evidence/[story-slug]/`; E2E: `tests/e2e/[journey]/` + `production/qa/evidence/[story-slug]/`; Config: `production/qa/smoke-*.md`) and, when `**Migration**` is not `None`, the migration floor `production/qa/evidence/[story-slug]/migration-dry-run.log`; whether missing evidence blocks is decided by `testing.strict.logic`, `.integration`, `.ui`, `.e2e` and `.config` at `/story-done`
- Every story file has a `## Acceptance Criteria` section with at least one checkbox item copied from the PRD, and an NFR budget or a "No NFR impact — [reason]" note
- Every story file has a `## QA Test Cases` section whose first line is the QL-STORY-READY review line (`> **QA Lead Review (QL-STORY-READY)**: APPROVED | CONCERNS (accepted) | REVISED [date]`) or its skip note (`> [QL-STORY-READY] skipped — Lean mode` / `— Solo mode`)
- Every story file has a `## Dependencies` section (may say "None" but is never omitted)
- The EPIC.md `## Stories` table has one row per story including `#`, `Story` title, `Type`, `Status`, and `ADR` — never a duplicate row for an existing number
- Stories with a `Proposed` ADR have `> **Status**: Blocked` and a note: `BLOCKED: ADR-NNNN is Proposed — run /architecture-decision to advance it`
- Every story file has a `**Stack**` and a `**Risk**` field. `Risk` comes from the governing ADR's `**Knowledge Risk**`, or at `minimal` from `docs/stack-reference/VERSION.md`; when that file is missing or assigns no level, `Risk` is **`NOT ASSESSED (no VERSION.md risk rating)`** — never a guessed level
- **`NOT ASSESSED` is an emittable value of the `Risk` field**, and downstream readers must handle it. `/dev-story` treats it as HIGH when deciding whether to spawn the stack specialist: an unknown risk is not a low one
- A run that stops on a missing required input (no epic under `production/epics/`, no `design/product/one-pager.md` at `minimal`, a referenced ADR file missing — any at `full`, a critical one at `standard`) writes no story file and ends with the run verdict `NOT ASSESSED`, naming the input and the skill that creates it

## Director Gate
- **QL-STORY-READY** (`qa-lead`, `.claude/docs/director-gates/ql-story-ready.md`), spawned once per written story, in parallel
- Pass: story path · PRD path · resolved `testing.strict` line
- Tokens: `ADEQUATE` (APPROVE-class; the reply also carries the story's test-case block) / `GAPS` (CONCERNS-class) / `INADEQUATE` (REJECT-class); the first reply line is parsed as `[QL-STORY-READY]: TOKEN`
- Review mode: `full` spawns; `lean` skips every gate whose ID does not end in `-PHASE-GATE` (so QL-STORY-READY is skipped); `solo` skips all gates

## Immutability Rules
- READS but does NOT modify: the epic's PRD, all ADR files, `docs/architecture/tr-registry.yaml`, `docs/architecture/control-manifest.md`, the API contract, migration plans, `design/product/tracking-plan.md`, UX specs, `docs/stack-reference/VERSION.md`, `project.yaml`, QA plans
- MODIFIES: `production/epics/<epic-slug>/story-NNN-<slug>.md` (creates; rewrites to embed QL-STORY-READY results), `production/epics/<epic-slug>/EPIC.md` (updates Stories section only; creates it at `minimal`), `production/epics/index.md` (Stories column only)

## Hard Constraints (Never Violate)
- Never start implementation — this skill stops at the story file level
- Never invent acceptance criteria — all criteria must come from the PRD (or the one-pager at `minimal`)
- Never invent implementation notes — all guidance must come from the referenced ADR
- Never reference an API operation that is not in the contract, or a migration plan that does not exist, as if it did
- Never write story files without presenting the full story list for approval first
- Never mark a story `Ready` if its governing ADR has `Status: Proposed`
- Never omit the `Manifest Version` field — downstream readiness checks depend on it
- Never reuse a story number (NNN) that already exists in the epic directory
- Never write a story file anywhere but directly inside `production/epics/<epic-slug>/` with the `story-NNN-<slug>.md` name

## Downstream Skill Expects
**Next skill:** /story-readiness (then /dev-story)

It will read:
- Each `story-NNN-<slug>.md` file — specifically: `> **Status**:`, `> **Type**:`, `> **Surface**:`, `> **Manifest Version**:` (header), `**PRD**`, `**Requirement**` (TR-ID), `**ADR Governing Implementation**`, `**Stack Notes**`, `**API Contract**`, `**Migration**`, `**Feature Flag**`, `**Analytics Events**`, `## Acceptance Criteria`, `## Implementation Notes` (UX spec link), `## Test Evidence` section, `## Dependencies` section
- `docs/architecture/control-manifest.md` — to compare its `Manifest Version:` against the story's embedded version
- The referenced ADR file — to verify its `Status:` field is still `Accepted`
- The referenced contract operation and migration plan — to verify they exist

It assumes:
- `Manifest Version` in the story header is a date string that can be compared against the manifest's current `Manifest Version:` date
- `TR-[feature-slug]-NNN` IDs are resolvable in `docs/architecture/tr-registry.yaml`
- The ADR referenced by name in `**ADR Governing Implementation**:` exists as a file in `docs/architecture/` (pattern: `adr-NNNN-<slug>.md`)
- `> **Status**: Ready` means the story is a candidate for assignment (not in progress, not blocked)
- `## Acceptance Criteria` contains checkbox items that are directly testable
- `## Test Evidence` specifies an exact file path or evidence directory where proof will be stored

## Known Fragile Points
- If the story file format (header field names, section names, checkbox syntax) changes, `/story-readiness` will silently skip checks for fields it cannot parse — stories may pass readiness that should fail
- If `control-manifest.md` is regenerated with a new `Manifest Version:` date after stories are written, all existing stories will show a stale manifest version and fail the readiness manifest check — every story in the epic will need its `Manifest Version` updated
- If a governing ADR is renumbered or its file is renamed after stories are written, the `**ADR Governing Implementation**:` reference in story files will point to a missing file and `/story-readiness` will BLOCK those stories
- If `/api-design` renames or removes an operation after stories are written, the `**API Contract**` reference goes stale and `/story-readiness` flags the story
- If `tr-registry.yaml` deprecates or supersedes a TR-ID that is already embedded in story files, `/story-readiness` will flag those stories as NEEDS WORK
- `testing.patterns` unset leaves test paths on the `tests/` convention; a stack that co-locates tests will then show paths `/story-done` does not find until the story's Test Evidence section is corrected
