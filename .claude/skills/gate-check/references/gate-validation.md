> Gate definition, loaded by `/gate-check` for the TARGET PHASE ONLY.
> Never load the other five — one gate applies per invocation.


# Gate: Architecture → Validation


**Required Artifacts:**
- [ ] Stack pinned: `stack.pinned_on` set **and** `docs/stack-reference/VERSION.md` has a
      Pinned Components row for every configured component whose Version is sourced,
      `n/a (managed service)`, or `NOT DETERMINED — accepted by user YYYY-MM-DD`.
      Accepted gaps are CONCERNS, listed by component name.
- [ ] Architecture document exists at `docs/architecture/architecture.md`
- [ ] Foundation-layer ADRs in `docs/architecture/` (`adr-*.md`): at least 3 covering
      identity & auth, the primary data store, the API style, deployment topology &
      environments, and observability
- [ ] Initial API contract in `docs/api/` (OpenAPI, GraphQL, protobuf or AsyncAPI — any
      of `openapi*.yaml`, `openapi*.json`, `*.graphql`, `*.proto`, `asyncapi*.yaml`)
      covering the Foundation/Core resources: auth/session, account and the core domain
      entity (only if *Backend*)
- [ ] `docs/data/data-model.md` with its data classification and the expand/contract
      migration strategy (only if *Backend*)
- [ ] Threat model `docs/security/threat-model.md` (only if *PII*; written by
      `/security-audit threat-model`)
- [ ] Architecture traceability index exists at `docs/architecture/requirements-traceability.md`
- [ ] `/architecture-review` has been run (a report `docs/architecture/architecture-review-*.md` exists)
- [ ] `design/accessibility-requirements.md` exists with `accessibility.target` committed —
      its `> **Target**:` header line matches the resolved `accessibility.target`. Any
      committed value counts, `none` included; unset does not (only if *UI*)
- [ ] Test framework initialized — a runner config per configured layer and at least one
      example test — and a CI workflow (any of `.github/workflows/*.yml`,
      `.github/workflows/*.yaml`, `.gitlab-ci.yml`, `bitbucket-pipelines.yml`,
      `azure-pipelines.yml`)
- [ ] `docs/ops/slo.md` with `## Critical User Journeys` and an SLO for each journey in
      `## SLIs & SLOs`
- [ ] Tech radar exists at `docs/architecture/tech-radar.md`

**Recommended (not blocking):**
- [ ] Threat model `docs/security/threat-model.md` even without *PII* — every product
      has trust boundaries (sessions, payment callbacks, admin console, webhooks)

**Quality Checks:**
- [ ] All ADRs have `## Stack Compatibility`, `## ADR Dependencies` and
      `## PRD Requirements Addressed` sections
- [ ] No ADR relies on an API listed in `docs/stack-reference/<component>/deprecated-apis.md`,
      and all ADRs agree on the pinned component versions (no stale version references)
- [ ] Every HIGH/MEDIUM knowledge-risk component (per `docs/stack-reference/VERSION.md`)
      is addressed in the architecture document or flagged as an open question
- [ ] The traceability matrix has **zero Foundation-layer gaps** (every Foundation
      requirement has ADR coverage before Validation)
- [ ] `performance.*` budgets are set in `project.yaml` for the configured surfaces
      (web: `lcp_ms`, `inp_ms`, `cls`, `bundle_kb`; API/backend: `api_p95_ms`,
      `error_rate_pct`, `availability_pct`; iOS/Android: `cold_start_ms`,
      `crash_free_pct`) — unset budgets are CONCERNS, never FAIL
- [ ] Every PII field in the data model has a classification, a retention rule and a
      deletion path (only if *PII*)
- [ ] Secrets management (where secrets live, who can read them, how they rotate) is
      decided in an ADR
- [ ] No circular ADR dependencies (the ADR Circular Dependency Check below)

**ADR Circular Dependency Check**: run the deterministic graph builder rather than
reading every ADR to trace the graph by hand — a manual trace across a dozen ADRs
eventually misses an edge; the script cannot:
```
Bash: bash .claude/scripts/adr-dep-graph.sh
```
It prints `ADRS`, `EDGES` (one `adr-A -> adr-B` per Depends-On reference),
`NO_DEPS_SECTION` (ADRs with no Depends On), and a `CYCLE:` line per node in any
dependency cycle.
- **Any `CYCLE:` lines → FAIL**: "Circular ADR dependency: [the nodes on the
  `CYCLE:` lines]. Neither can reach Accepted while the cycle exists. Remove one
  'Depends On' edge to break the cycle."
- No `CYCLE:` lines → this check passes. But the acyclic result is only as
  trustworthy as the dependency sections are complete: if `NO_DEPS_SECTION` lists
  many ADRs, surface that as a CONCERNS note rather than a clean pass.

**Stack Validation** (read `docs/stack-reference/VERSION.md` first):
- [ ] ADRs that touch post-cutoff APIs are flagged with Knowledge Risk: HIGH/MEDIUM
      in their `## Stack Compatibility` table
- [ ] The `/architecture-review` stack audit shows no deprecated API usage

**Conditions** (resolved by `/gate-check` Phase 1):
- *UI* = `platform.surfaces` ∩ {web, ios, android} ≠ ∅. Unset ⇒ MANUAL CHECK NEEDED
  (ask), never "no UI".
- *Backend* = `stack.layers.backend.framework` set, or `stack.layers.data.database`
  set, or `api` ∈ `platform.surfaces`.
- *PII* = `privacy.handles_pii: true`. Unset ⇒ ask (unset is not false).

An item whose condition is known false is reported as
`N/A — <condition> not configured` (e.g. `N/A — Backend not configured`) and is not
scored. The threat-model item switches between required and recommended on *PII*;
it is never N/A.

## Workflow tier reductions

The checklist above is the **`full` baseline**. At lower tiers apply the
reduction for the resolved tier. Every item above is named in each tier line
below with its status (required / recommended / dropped / conditional).
Reductions only ever *relax* a requirement — `workflow_overrides` is the
only thing that adds one.

- **`full`** — **required**: stack pinned with complete VERSION.md rows;
  architecture document; at least 3 Foundation-layer ADRs covering the five
  areas; tech radar; traceability index; architecture review report; test
  framework and CI workflow; `docs/ops/slo.md` with journeys and an SLO per
  journey; the three ADR sections; no deprecated APIs and agreed versions;
  HIGH/MEDIUM knowledge-risk components addressed; zero Foundation-layer
  traceability gaps; `performance.*` budgets set (unset ⇒ CONCERNS); secrets
  management decided in an ADR; no circular ADR dependencies; the Stack Validation
  block. **Conditional** (required when the condition holds): initial API contract
  and data model (*Backend*); threat model (*PII*); PII classification, retention
  and deletion path (*PII*); accessibility requirements with the target committed
  (*UI*). **Recommended**: the threat model when *PII* is false. Nothing is dropped.
- **`standard`** — **required**: stack pinned with complete VERSION.md rows;
  architecture document; ADRs reduced to the **critical ones** — the
  Foundation-layer ADRs the architecture document marks critical; architecture
  review report; test framework and CI workflow; `docs/ops/slo.md` with its
  `## Critical User Journeys` section (SLO numbers recommended); the three ADR
  sections; no deprecated APIs and agreed versions; secrets management decided in
  an ADR; no circular ADR dependencies; the Stack Validation block.
  **Conditional** (required when the condition holds): initial API contract and
  data model (*Backend*); threat model (*PII*); PII classification, retention and
  deletion path (*PII*); accessibility requirements with the target committed
  (*UI*). **Recommended**: traceability index; zero Foundation-layer traceability
  gaps; HIGH/MEDIUM knowledge-risk components addressed; `performance.*` budgets
  set; tech radar; the threat model when *PII* is false. Nothing is dropped.
- **`minimal`** — only **stack pinned with complete VERSION.md rows** is required
  (the minimal floor). **Dropped**: architecture document; Foundation-layer ADRs;
  initial API contract; data model; threat model (with or without *PII*);
  traceability index; architecture review report; accessibility requirements;
  test framework and CI workflow; `docs/ops/slo.md`; tech radar; the three ADR
  sections; deprecated APIs and agreed versions; knowledge-risk components;
  Foundation-layer traceability gaps; `performance.*` budgets (`performance.enforce`
  still applies independently — the `/gate-check` rule); PII classification;
  secrets management ADR; circular ADR dependencies; the Stack Validation block.
