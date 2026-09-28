# /story-readiness — Handoff Contract

## Role in Pipeline
Validates that a story file contains everything an engineer needs to begin
implementation and produces a READY / NEEDS WORK / BLOCKED / NOT ASSESSED verdict — sits between
`/create-stories` and `/dev-story`, acting as a blocking gate before any code is written.
In `full` review mode it also runs QL-STORY-READY on each evaluable story.

## Inputs Required

### Files That Must Exist
| File | Required Fields / Sections | Read-Only? |
|------|---------------------------|-----------|
| Resolved config block (`--keys review_mode,automation,workflow,qa.level,testing.strict,feature_overrides`) | `workflow` per story (via `feature_overrides` on the story's PRD stem), `qa.level`, `testing.strict` (`logic`, `integration`, `ui`, `e2e`, `config`), `review_mode` (QL-STORY-READY), `automation` | Yes |
| `production/epics/<epic-slug>/story-NNN-<slug>.md` | Header fields (`> **Status**`, `> **Layer**`, `> **Type**`, `> **Surface**`, `> **Estimate**`, `> **Manifest Version**`), `**PRD**`, `**Requirement**` (TR-ID), `**ADR Governing Implementation**`, `**Stack**` / `**Risk**`, `**Stack Notes**`, `**API Contract**`, `**Migration**`, `**Feature Flag**`, `**Analytics Events**`, `**Control Manifest Rules (this layer)**`, `## Acceptance Criteria`, `## Implementation Notes`, `## Out of Scope`, `## Test Evidence`, `## Dependencies` | Yes |
| `docs/architecture/control-manifest.md` | `Manifest Version:` date in header | Yes (if exists) |
| `docs/architecture/tr-registry.yaml` | `id`, `status` fields per TR entry | Yes (if exists) |
| `docs/architecture/adr-NNNN-<slug>.md` (all ADRs referenced in stories) | `## Status` | Yes |
| API contract (`docs/api/openapi*.yaml`, `docs/api/schema.graphql`, `docs/api/*.proto`, `docs/api/asyncapi.yaml`) | The operation each story references | Yes (if exists) |
| `docs/data/migrations/NNNN-<slug>.md` | `## Status` of the plan a story references | Yes (if referenced) |
| `design/prd/<feature-slug>.md` | `## Configuration & Flags` (flag check), `## Non-Functional Requirements` (NFR budget source) | Yes |
| `design/product/tracking-plan.md` | `## Events` | Yes (if exists) |
| `design/ux/<slug>.md` | Existence of the UX spec a UI or E2E story links | Yes (if linked) |
| `docs/stack-reference/VERSION.md` | Knowledge Risk per pinned component | Yes (if exists) |
| `design/product/feature-map.md` | Which features have Approved PRDs | Yes |

### Preconditions
- The story file being validated was produced by `/create-stories` (or follows the same format)
- For `sprint` scope: a sprint file exists in `production/sprints/` with story path references
- For `all` scope: `production/epics/` exists and contains files matching `production/epics/*/story-*.md`

## Outputs Produced

### Files Written
None. This skill has no Write or Edit access and produces no file modifications under any circumstance: the report is shown in the conversation, and a story file stays untouched unless the user approves a drafted fix and applies it.

### Definition of Ready (checked per story)
- PRD requirement traced (a specific criterion or rule, not just the filename); acceptance criteria self-contained, testable and free of judgment calls
- **Design link**: UI and E2E stories cite an existing UX spec `design/ux/<slug>.md`
- **Analytics event list**: `**Analytics Events**` present; each named event exists in `design/product/tracking-plan.md`
- ADR referenced and `Accepted`; TR-ID active; manifest version current; stack notes for MEDIUM/HIGH-risk components; control manifest rules noted
- `**API Contract**` present; the referenced operation exists in the contract (`None` only when the story calls no API)
- `**Migration**` present; a schema-changing story names a plan that exists
- `**Feature Flag**` present; a named key is defined in the PRD's `## Configuration & Flags`
- `**Surface**` present with values from `web`, `ios`, `android`, `mobile`, `api`, `admin`, `infra`, `analytics`
- Estimate, scope boundary and dependencies stated; no unresolved questions; dependency stories exist and are not Blocked; referenced assets exist
- **NFR budget** stated (or "No NFR impact — [reason]") for stories touching a request path, query, job, screen or bundle
- Story Type declared (Logic / Integration / UI / E2E / Config); test evidence location stated at the gate level `testing.strict.<type>` resolves to (unset: strict for `logic`, `integration`, `ui`, `e2e`; advisory for `config`)
- **Migration floor named in the DoD**: a story whose `**Migration**` is not `None` names `production/qa/evidence/<story-slug>/migration-dry-run.log` (`<story-slug>` = the story file name without `.md`) — at every `qa.level`, regardless of `testing.strict.config`

### Output Guarantees
- A verdict of READY, NEEDS WORK, BLOCKED or NOT ASSESSED is produced for every story file evaluated, as `> **Verdict**: <TOKEN>` under the story's report heading. `NOT ASSESSED` is not a synonym for `BLOCKED`: BLOCKED names a real, listable obstacle, while NOT ASSESSED means the story could not be evaluated at all. An empty scope yields `NOT ASSESSED — no stories in scope`, never a `Ready: 0 / Needs Work: 0 / Blocked: 0` summary over an empty list
- Precedence: BLOCKED, then NEEDS WORK, then NOT ASSESSED, then READY — first match wins
- Every non-READY verdict includes a specific gap list with fix instructions for each failing checklist item
- Every BLOCKED verdict names the specific blocker (missing or Blocked dependency story path, Proposed or missing ADR, missing contract file or migration plan, or unresolved design question marker)
- For `sprint` scope: a sprint-level escalation warning is prepended if any Must Have story is not READY
- Every story report carries a `QL-STORY-READY:` line — the gate token, the skip note (`[QL-STORY-READY] skipped — Lean mode` / `— Solo mode`), or `not run — story BLOCKED` / `— story NOT ASSESSED`
- The skill offers to draft missing sections in conversation but never uses Write or Edit tools

## Director Gate
- **QL-STORY-READY** (`qa-lead`, `.claude/docs/director-gates/ql-story-ready.md`), spawned per story whose checklist verdict is READY or NEEDS WORK, before the report is printed
- Pass: story path · PRD path · resolved `testing.strict` line
- Tokens: `ADEQUATE` (APPROVE-class) / `GAPS` (CONCERNS-class — revise / accept / discuss) / `INADEQUATE` (REJECT-class — the story cannot be READY); the first reply line is parsed as `[QL-STORY-READY]: TOKEN`
- Review mode: `full` spawns; `lean` skips every gate whose ID does not end in `-PHASE-GATE` (so QL-STORY-READY is skipped); `solo` skips all gates
- The outcome line (`> **QA Lead Review (QL-STORY-READY)**: …`) is shown for the user to add to the story's `## QA Test Cases` section; this skill does not write it

## Immutability Rules
- READS but does NOT modify: story files, `docs/architecture/control-manifest.md`, `docs/architecture/tr-registry.yaml`, all ADR files, the API contract, migration plans, PRDs, `design/product/tracking-plan.md`, UX specs, `design/product/feature-map.md`, sprint files, any referenced asset files (existence-only Glob checks)
- MODIFIES: nothing

## Hard Constraints (Never Violate)
- Never use Write or Edit tools under any circumstances
- Never draft corrections directly into files — offer drafts in conversation only
- Never mark a story READY if its governing ADR has `Status: Proposed`
- Never mark a story READY if a dependency story file is missing or has `> **Status**: Blocked`
- Never mark a story READY if its referenced contract file or migration plan does not exist
- Never mark a story READY after QL-STORY-READY returned INADEQUATE
- Never auto-pass the migration floor — `qa.level: minimal` waives test evidence, not the dry-run log
- Never re-read the same ADR file multiple times in one run — cache ADR statuses after the first read
- Never penalize a story for missing `Manifest Version` if `control-manifest.md` does not exist
- Never penalize a story for missing TR-ID if `tr-registry.yaml` does not exist

## Downstream Skill Expects
**Next skill:** /dev-story

It will rely on this skill's verdict as follows:
- If verdict is READY: `/dev-story` proceeds with implementation using the story file as its source of truth
- If verdict is NEEDS WORK, BLOCKED or NOT ASSESSED: `/dev-story` must not be run until the story is corrected and re-validated
- `/dev-story` reads the same story fields this skill validates — a READY verdict is an implicit guarantee that those fields are present, parseable, and internally consistent:
  - `> **Type**:` field is set to a valid story type (Logic, Integration, UI, E2E, Config)
  - `> **Surface**:` field holds valid values, primary first — `/dev-story` routes by it
  - `## Acceptance Criteria` contains specific, testable checkbox items
  - `## Test Evidence` specifies a concrete evidence path, and the migration dry-run log when `**Migration**` is not `None`
  - The governing ADR exists and has `Status: Accepted`
  - `**API Contract**` resolves to an existing operation (or is `None`), and `**Migration**` to an existing plan (or is `None`)
  - `Manifest Version` matches the current control manifest
  - `TR-ID` in `**Requirement**` is present and resolves in `docs/architecture/tr-registry.yaml` (when the registry exists)
  - `## Dependencies` section is present (may say "None")
  - `## Out of Scope` section is present (checked for existence; `/dev-story` uses it to enforce implementation boundaries)

## Known Fragile Points
- If `control-manifest.md` is regenerated with a new `Manifest Version:` date, every story that embeds the old date will fail the manifest version check — a bulk update of all story `Manifest Version` fields is required before stories can pass readiness again
- If an ADR is silently renamed or moved after stories reference it by ID, the ADR file-existence check will BLOCK those stories even though the decision content is unchanged
- The manifest version comparison is a string date match, not a semantic version comparison — if the date format changes (e.g., from `2026-01-15` to `Jan 15 2026`), all stories will fail the check regardless of actual currency
- The API Contract check greps the referenced path or operation name; a contract split into several files, or a reference written in a different style (`operationId` vs JSON pointer), can miss a real operation — the check then reports NEEDS WORK, never READY
- Asset existence checks use Glob — on Windows, path separator mismatches (`\` vs `/`) may cause a Glob miss that incorrectly flags an asset as missing
- The TR-ID status check auto-passes if the registry does not exist, which means stories written before TR tracking was introduced will always pass this check even if they contain invalid or placeholder IDs like `TR-[feature-slug]-???`
- For `sprint` scope, the skill depends on sprint file formatting to extract story paths — if the sprint file format changes, story paths may not be parsed and the scope silently reduces to zero stories validated
