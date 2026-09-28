# Docs Directory

When authoring or editing files in this directory, follow these standards. Every
document here keeps its template headings, bold field labels, status tokens, IDs
and paths in English exactly as the template spells them; the prose is written in
the user's conversation language.

## Layout

| Path | What lives there | Written by |
|------|------------------|------------|
| `architecture/` | `architecture.md`, `adr-NNNN-<slug>.md`, `architecture-review-YYYY-MM-DD.md`, `requirements-traceability.md`, `tr-registry.yaml`, `control-manifest.md`, `tech-radar.md`, `change-impact-YYYY-MM-DD-<prd-stem>.md`, `tdd-<feature>.md` | `/create-architecture`, `/architecture-decision`, `/architecture-review`, `/create-control-manifest`, `/propagate-prd-change`, `/setup-stack` (tech radar seed) |
| `api/` | `api-guidelines.md` and the contract — `openapi.yaml`, `schema.graphql`, `<service>.proto` or `asyncapi.yaml`; `changes/api-change-YYYY-MM-DD.md`; `guides/<slug>.md` (developer guides, Public API only) | `/api-design` |
| `data/` | `data-model.md`; `migrations/NNNN-<slug>.md` (migration plans — the executable migrations live in the data layer's `migrations_dir`) | `/data-model` |
| `security/` | `threat-model.md` | `/security-audit threat-model` |
| `ops/` | `slo.md`; `runbooks/<alert-slug>.md` | `/create-architecture` (with sre-engineer), `/incident runbook` |
| `registry/` | `architecture.yaml` — binding architectural stances | `/architecture-decision`, `/data-model` (`data_ownership`) |
| `stack-reference/` | `README.md`, `VERSION.md`, `<component-slug>/` reference files | `/setup-stack` |
| `CHANGELOG.md` | The **product's** changelog (Keep a Changelog) — not the framework's history | `/changelog` |
| `tech-debt-register.md` | Technical debt register | `/tech-debt` |
| `adoption-plan-YYYY-MM-DD.md` | Brownfield adoption plans | `/adopt` |
| `consistency-failures.md` | Runtime scratch file (gitignored) | `/consistency-check` |

Human-facing guides also live here: `COLLABORATIVE-DESIGN-PRINCIPLE.md` (English),
`WORKFLOW-GUIDE.md` and `skill-flow-diagrams.md` (Korean).

## Architecture Decision Records (`docs/architecture/`)

Use the ADR template: `.claude/docs/templates/architecture-decision-record.md`. It
is the single source of the ADR heading contract — copy it; never write an ADR
from memory or from another ADR. Reverse-documented ADRs use
`.claude/docs/templates/architecture-doc-from-code.md`, which carries the same
headings plus a `> **Origin**:` line under `## Summary`.

**Required sections:** Title, Status, Summary, Stack Compatibility,
ADR Dependencies, Context, Decision, Consequences, PRD Requirements Addressed

**Status lifecycle:** `Proposed` → `Accepted` → `Superseded by ADR-NNNN` (or `Deprecated`)
- Never skip `Accepted` — stories whose governing ADR is still `Proposed` stay `Blocked`
- Only `/architecture-decision accept ADR-NNNN` moves an ADR to `Accepted`, and
  only on the user's explicit confirmation
- Use `/architecture-decision` to create ADRs through the guided flow
- File names are `adr-NNNN-<slug>.md` at the top level of `docs/architecture/`
  (e.g. `adr-0001-identity-and-auth.md`); numbers are never reused

**Dependency graph:** `bash .claude/scripts/adr-dep-graph.sh` reads the
`**Depends On**` row of each ADR's `## ADR Dependencies` section and prints
observations (`EDGES`, `NO_DEPS_SECTION`, `CYCLE:`); the Validation gate judges them.

**Architecture document:** `docs/architecture/architecture.md` — layers & modules,
deployment topology & environments, data flow, integrations, security model,
observability, NFR budgets, required ADRs and open questions. Written by
`/create-architecture`; ADRs record the individual decisions it calls for.

**Technical designs:** `docs/architecture/tdd-<feature>.md` from
`.claude/docs/templates/technical-design-document.md` — optional, per feature,
never a gate artifact.

**TR Registry:** `docs/architecture/tr-registry.yaml`
- Stable requirement IDs `TR-<feature-slug>-NNN` (e.g. `TR-goals-001`) that link
  PRD requirements to ADRs and stories; each entry names its `prd:`
- Never renumber existing IDs — only append new ones
- Single writer: `/architecture-review`

**Control Manifest:** `docs/architecture/control-manifest.md`
- Flat engineer rules sheet: Required / Forbidden / Guardrails per layer, from
  Accepted ADRs and the tech radar
- Date-stamped `Manifest Version:` in header
- Stories embed this version; `/story-done` checks for staleness

**Tech Radar:** `docs/architecture/tech-radar.md` — `## Adopt`, `## Trial`,
`## Assess`, `## Hold`, `## Forbidden Patterns`; every entry cites an ADR or a
source URL. Seeded by `/setup-stack`, updated by `/architecture-decision` when an
ADR is accepted.

**Validation:** Run `/architecture-review` in a fresh session after completing a
set of ADRs.

## Architecture Registry (`docs/registry/architecture.yaml`)

Binding stances every new ADR is checked against: `data_ownership`,
`interfaces`, `slo_budgets`, `technology_decisions`, `forbidden_patterns`.
Entries are never deleted — a replaced stance is marked
`status: "superseded_by: ADR-NNNN"` (quoted — an unquoted second colon is not
valid YAML).

## API, Data, Security and Ops

- **Contract first**: the contract in `docs/api/` changes before the code that
  implements it. Breaking changes carry a version bump or a deprecation plan
  (`docs/api/api-guidelines.md` `## Deprecation`).
- **Migrations**: every schema change is planned in `docs/data/migrations/` as
  Expand → Migrate → Contract; stories that carry a migration need dry-run
  evidence.
- **SLOs**: `docs/ops/slo.md` names the critical user journeys; every paging
  alert in its `## Dashboards & Alerts` section has a runbook in
  `docs/ops/runbooks/`.
- **No secrets or real personal data** in any document here — examples use
  placeholders.

## Stack Reference (`docs/stack-reference/`)

Sourced, version-pinned notes for each configured stack component. Before using a
version-sensitive framework, runtime or SDK API, read
`docs/stack-reference/VERSION.md` and the component's folder — components released
after the model's knowledge cutoff (Knowledge Risk MEDIUM or HIGH) are where
training data is wrong. If the reference does not cover the question, say
`NOT SOURCEABLE` and suggest `/setup-stack refresh`; never fill the gap from
memory.

Current stack: see `docs/stack-reference/VERSION.md`.
