# /architecture-decision — Handoff Contract

## Role in Pipeline
Authors a new Architecture Decision Record (ADR) by guiding a collaborative design session, cross-referencing the stack reference library (`docs/stack-reference/`) and the existing architectural stances, and writing an ADR from the single template `.claude/docs/templates/architecture-decision-record.md` to `docs/architecture/` — then retrofits older ADRs to that template and, in acceptance mode, moves an ADR to `Accepted`, which unblocks the stories and epics that depend on the decision.

Two checks inside the run emit `NOT ASSESSED` / `NOT CHECKED` rather than passing
silently, and a reader of the resulting ADR should expect them: **stack
validation** for a consulted layer that is not configured
(`NOT CHECKED — <layer> layer not configured (run /setup-stack)`), and **PRD
sync** when the referenced PRDs cannot be read or the ADR names none
(`PRD sync: NOT ASSESSED — <reason>`). A skipped check that says nothing is
indistinguishable from a check that passed.

## Inputs Required

### Files That Must Exist
| File | Required Fields / Sections | Read-Only? |
|------|---------------------------|-----------|
| `.claude/docs/templates/architecture-decision-record.md` | The ADR heading contract (listed under Outputs) — copied for every new ADR and used as the heading list in retrofit mode | Yes |
| `docs/stack-reference/VERSION.md` | The `**LLM Knowledge Cutoff**` and `**Stack Pinned**` rows, and the `## Pinned Components` table (Layer, Component, Version, Knowledge Risk, Source, Retrieved) — the Knowledge Risk of every component the decision touches | Yes |
| `docs/stack-reference/<component>/` | `VERSION.md`; for MEDIUM/HIGH components also `breaking-changes.md`, `deprecated-apis.md`, `current-best-practices.md` where they exist | Yes |
| `docs/registry/architecture.yaml` | Existing stances in `data_ownership`, `interfaces`, `slo_budgets`, `technology_decisions`, `forbidden_patterns` — checked for conflicts before the design begins | No — appended in Step 5.7 |
| `docs/architecture/tech-radar.md` | `## Hold` and `## Forbidden Patterns` read as locked constraints; `## Adopt`, `## Trial`, `## Assess` updated at acceptance | No — updated in acceptance mode |
| `docs/architecture/` (existing ADRs) | Scanned to determine the next sequential ADR number and related ADRs | Yes (except the ADR being retrofitted or accepted, and an ADR superseded at acceptance) |
| `docs/architecture/architecture.md` | The required-ADR list (layer, critical or not, requirements covered) — optional; drives the closing options | Yes |
| `docs/architecture/tr-registry.yaml` | TR-IDs (`TR-<feature-slug>-NNN`) for `## PRD Requirements Addressed` | Yes — single writer is `/architecture-review` |
| `design/prd/<feature>.md` (PRDs relevant to the decision) | `## Functional Requirements`, `## Business Rules & Calculations`, `## Edge Cases`, `## Dependencies`, `## Non-Functional Requirements` | Yes, unless the user approves a PRD sync update |
| `project.yaml` | `performance.*` budgets (read with Read) | Yes |

### Config keys (bootstrap `resolve_config`)
`review_mode`, `automation`, `automation_always_ask`, `workflow`, `docs.density`,
`team.size`, `stack`, `compliance`. The `stack` line supplies the configured layers
and the specialist routing (`<lead>><sub>`); the `compliance` line fills
`## Security & Privacy Implications` and is passed to SE-SECURITY-REVIEW as printed.

### Preconditions
- A stack should be configured (`docs/stack-reference/VERSION.md` with component rows). If none is, the skill prompts to run `/setup-stack` first — except for a decision that chooses the data store or the cloud provider, whose components are recorded as "not pinned"
- The title or subject of the decision must be provided by the user before Step 1 proceeds (if no argument is given, the skill asks)
- If in **retrofit mode** (`retrofit <path>` argument), the target ADR file must already exist on disk
- If in **acceptance mode** (`accept <ADR-id>`), exactly one `docs/architecture/adr-NNNN-*.md` must match the id, with a `## Status` and a `## ADR Dependencies` section
- Any conflict with a registered architectural stance in `docs/registry/architecture.yaml` must be resolved or explicitly accepted as an exception before the ADR is drafted (Step 3a is a BLOCKING gate)

## Outputs Produced

### Files Written
| File | Guaranteed Fields / Sections | Notes |
|------|------------------------------|-------|
| `docs/architecture/adr-NNNN-<slug>.md` | Every heading of the template, exactly and in order: `# ADR-[NNNN]: [Title]`, `## Status`, `## Date`, `## Last Verified`, `## Decision Makers`, `## Summary`, `## Stack Compatibility`, `## ADR Dependencies`, `## Context` (`### Problem Statement`, `### Current State`, `### Constraints`, `### Requirements`), `## Decision` (`### Architecture`, `### Key Interfaces`, `### Implementation Guidelines`), `## Alternatives Considered`, `## Consequences` (`### Positive`, `### Negative`, `### Neutral`), `## Risks`, `## Performance & SLO Implications`, `## Security & Privacy Implications`, `## Cost Implications`, `## Migration Plan` (with its `**Rollback plan**:` line), `## Validation Criteria`, `## PRD Requirements Addressed`, `## Related` | created after the user approves ("May I write this to `docs/architecture/adr-NNNN-<slug>.md`?"); review record lines added to `## Decision Makers` after a separate approval |
| `docs/registry/architecture.yaml` | New stance entries in `data_ownership`, `interfaces`, `slo_budgets`, `technology_decisions`, `forbidden_patterns`; existing entries marked `status: "superseded_by: ADR-NNNN"` (quoted) if overridden | appended after separate user approval ("May I write this to `docs/registry/architecture.yaml` — N new stances?") |
| `docs/architecture/tech-radar.md` | Entries in `## Adopt`, `## Trial`, `## Assess`, `## Hold`, `## Forbidden Patterns`, each `- **<name>** — <why> (ADR-NNNN)`, no version in `<name>` | acceptance mode only, after "May I write this to `docs/architecture/tech-radar.md`?" |
| `production/epics/<epic-slug>/story-NNN-<slug>.md` | `> **Status**: Blocked` → `> **Status**: Ready` | acceptance mode only; stories blocked pending this ADR, inside the approved acceptance changeset |
| `production/sprint-status.yaml` | `status: blocked` → `status: ready-for-dev` for those stories | acceptance mode only, same changeset |
| `design/prd/<feature>.md` | Renamed interface names aligned with the ADR | only when the user picks "Write ADR + update PRD" after a PRD sync warning |

### Output Guarantees
- The ADR number is the next sequential integer after the highest existing `adr-NNNN-*` filename in `docs/architecture/`; numbers are never reused
- The ADR is a filled copy of the template — never an inline or remembered skeleton — so every reader matches the same headings
- `## Status` is always present and set to `Proposed` on creation; only acceptance mode sets `Accepted`
- `## Stack Compatibility` always carries the rows `**Stack Components**`, `**Domain**`, `**Layer**`, `**Knowledge Risk**`, `**References Consulted**`, `**Post-Cutoff APIs Used**`, `**Verification Required**`, populated from `docs/stack-reference/` — never from training data alone when a component carries MEDIUM or HIGH risk
- `## PRD Requirements Addressed` is always present (a table `| PRD | Requirement (TR-ID) | How addressed |`, or "Foundational — no PRD requirement. Enables: …")
- `## ADR Dependencies` is always present with `**Depends On**`, `**Enables**`, `**Blocks**`, `**Ordering Note**` (fields set to "None" if no ordering constraints exist; never a defaulted "None" when the scan was inconclusive)
- Stack specialist validation (Step 5.2) runs before the file is written for every configured layer the Domain routes to; blocking issues cause the Decision section to be revised before saving
- Director reviews (Step 5.5) apply the review-mode check: TD-ADR always, TD-STACK-RISK when a component's Knowledge Risk is HIGH or MEDIUM, SE-SECURITY-REVIEW when the Domain is `Auth`, `Security` or `Data`; each outcome or skip note is recorded in `## Decision Makers`

## Immutability Rules
- READS but does NOT modify: all other ADR files in `docs/architecture/` (in retrofit mode existing sections are never touched), `docs/architecture/tr-registry.yaml`, `docs/stack-reference/**`, `project.yaml`, `.claude/docs/templates/architecture-decision-record.md`
- MODIFIES: `docs/architecture/adr-NNNN-<slug>.md` (new file; missing sections inserted in retrofit mode; Status, Date and review lines in acceptance mode), `docs/registry/architecture.yaml` (append only; existing entries get `status: "superseded_by: ADR-NNNN"`, never deleted or rewritten), `docs/architecture/tech-radar.md` (acceptance mode), story files and `production/sprint-status.yaml` (acceptance mode, Blocked → Ready only), the superseded ADR's `## Status` (acceptance mode)
- In retrofit mode: inserts only the missing sections, at their template positions — never modifies any section that is already present in the target ADR file

## Hard Constraints (Never Violate)
- Never sets `Accepted` without explicit user confirmation — the default on creation is always `Proposed`
- **Acceptance route: `/architecture-decision accept ADR-NNNN`** — the only path that sets `Accepted`. It refuses when a dependency is not itself Accepted, when the dependency section is absent or UNKNOWN, or while a REJECT-class director verdict stands, and it prompts for confirmation regardless of `modes.automation`. Accepting, superseding or deprecating an ADR is the `architecture_decisions` always-ask category. Without this route acceptance would be enforced by many skills, owned per the authority below, and reachable by nobody.
- **Acceptance authority: the user, or `technical-director` on the user's explicit confirmation — no other agent, and not this skill on its own.** Recorded here because every consumer enforces the consequences of acceptance, and without this line nothing would say who can produce it. This narrows *who* may set the field; it does not relax the confirmation rule above.
- Never assigns an ADR number that is already in use — always scan `docs/architecture/` first and use the next sequential number
- Never proceeds past the architectural stance conflict check (Step 3a) if a conflict exists — surface the conflict and require resolution or explicit exception acknowledgment before drafting
- Never references APIs listed in `docs/stack-reference/<component>/deprecated-apis.md` in the Decision or Key Interfaces sections
- Never writes the ADR file without asking: "May I write this to `docs/architecture/adr-NNNN-<slug>.md`?"
- Never writes to `docs/registry/architecture.yaml` or `docs/architecture/tech-radar.md` without a separate ask
- Never unblocks a story at authoring time — only acceptance does, and only stories whose header matches `^> \*\*Status\*\*: Blocked` and that name this ADR
- Never writes `docs/architecture/tr-registry.yaml` (single writer: `/architecture-review`)
- In retrofit mode: never modifies any existing section — only inserts absent sections

## Downstream Skill Expects
**Next skills:** `/api-design`, `/data-model`, `/architecture-review`, `/setup-stack refresh` (after an ADR that decides data or cloud components is accepted), `/create-control-manifest`, `/create-epics`, `/create-stories`, `/dev-story`

### `/create-epics` reads ADRs expecting:
- `## Status` field — value must be `Accepted` for epics to reference it
- `## PRD Requirements Addressed` table — used to link epics to PRD traceability
- `## Stack Compatibility` section — its `**Layer**` and `**Knowledge Risk**` rows (Stack Risk per epic)

### `/create-stories` reads ADRs expecting:
- `### Implementation Guidelines` — the concrete "must / must never" patterns engineers follow; stories embed them as ADR guidance
- `## ADR Dependencies` table — stories referencing a `Depends On` ADR that is still `Proposed` are set `> **Status**: Blocked`
- `## Stack Compatibility` — `**Stack Components**` and `**Knowledge Risk**` become the story's `**Stack**` / `**Risk**` line; `**Layer**` decides whether a missing ADR is critical
- `## Last Verified` (else `## Date`) — copied as the story's `**ADR Version**`

### `/dev-story` reads ADRs expecting:
- `## Decision` (full text, verbatim — not summarized)
- `### Implementation Guidelines` (verbatim)
- `## Stack Compatibility` (post-cutoff API risks, verification required)
- `## ADR Dependencies` (to detect if this ADR's dependencies are unresolved)
- `## Last Verified` (compared with the story's `**ADR Version**`)

### `/architecture-review` reads ADRs expecting:
- The headings `## Status`, `## Decision`, `## PRD Requirements Addressed`, `## Stack Compatibility`, `## ADR Dependencies`, `## Performance & SLO Implications`, `## Security & Privacy Implications` (it flags gaps)
- `## Status` is set (required for the coverage matrix)
- `## Stack Compatibility` is stamped with the pinned component versions

### `/create-control-manifest` reads Accepted ADRs expecting:
- `## Decision`, `## Alternatives Considered`, `## Performance & SLO Implications`, `## Security & Privacy Implications`, `## Stack Compatibility`

### `.claude/scripts/adr-dep-graph.sh` expects:
- A `## ADR Dependencies` section whose `**Depends On**` row names `ADR-NNNN` ids (or "None")

## Known Fragile Points
- If the ADR number scan misses a file (e.g., a file in a subdirectory of `docs/architecture/` or with a non-standard naming pattern), a duplicate number can be assigned — all ADR files must follow the `adr-NNNN-<slug>.md` naming convention at the top level of `docs/architecture/`
- Acceptance finds blocked stories by the header line `> **Status**: Blocked` plus the ADR id; a story blocked with a hand-edited header in another form (e.g. `Status: Blocked` without the blockquote and bold) is not found and must be unblocked by hand — the skill reports the stories it found, so a missing one is visible
- The `## PRD Requirements Addressed` table is populated based on what the user tells the skill during the collaborative session; if the user does not know which PRDs motivated the decision, this table may be incomplete — `/create-epics` and `/gate-check` both rely on this linkage for traceability
- Stack specialist validation is skipped for every consulted layer that is not configured. A decision that chooses a new layer's components (primary data store, cloud provider) therefore has no specialist check until `/setup-stack refresh` configures the layer; TD-STACK-RISK (HIGH for a not-pinned component) is the remaining check
- `docs/registry/architecture.yaml` is append-only by design; if a stance entry becomes permanently invalid (not superseded by another ADR), it must be manually removed — there is no cleanup mechanism
- In retrofit mode, if the existing ADR has sections present but empty (e.g., a `## Status` heading with no value), the skill treats the section as present and does not fill it — an empty Status is effectively invisible to downstream skills like `/story-readiness`
