# Architecture Traceability Index

<!-- Living document — written to docs/architecture/requirements-traceability.md by
     /architecture-review after each review run. Do not edit manually unless
     correcting an error. Requirement IDs come from docs/architecture/tr-registry.yaml,
     which /architecture-review alone assigns — never invent one here.

     The chain this index traces, left to right:
       PRD requirement (## Functional Requirements / ## Non-Functional Requirements)
         → TR-ID (tr-registry.yaml)
         → ADR (its ## PRD Requirements Addressed table)
         → story (its **Requirement** field)
         → test (the story's ## Test Evidence path, or the story type's evidence) -->

## Document Status

- **Last Updated**: [YYYY-MM-DD]
- **Stack**: [the resolved `stack` line, e.g. web=Next.js 15.3; backend=NestJS 11.0; data=PostgreSQL 16]
- **PRDs Indexed**: [N]
- **ADRs Indexed**: [M]
- **Chain Linked**: [yes — /architecture-review rtm YYYY-MM-DD | no — run /architecture-review rtm]
- **Last Review**: [link to docs/architecture/architecture-review-[date].md]

## Coverage Summary

| Status | Count | Percentage |
|--------|-------|-----------|
| ✅ Covered (Accepted ADR) | [X] | [%] |
| 🟡 Covered (Proposed ADR) | [P] | [%] |
| ⚠️ Partial | [Y] | [%] |
| ❌ Gap | [Z] | [%] |
| **Total** | **[N]** | |

`🟡` is not a pass state: coverage by a `Proposed` ADR moves to ✅ only through
`/architecture-decision accept ADR-NNNN`.

---

## Traceability Matrix

<!-- One row per technical requirement extracted from a PRD.
     A "technical requirement" is any PRD statement that implies a specific
     architectural decision: data and ownership, latency and availability targets,
     security and privacy rules, cross-feature communication, persistence and
     consistency, third-party integrations, client and surface needs.
     Type: functional (from ## Functional Requirements or ## Business Rules &
     Calculations) | nfr (from ## Non-Functional Requirements, with its category).
     Layer: the feature's Layer column in design/product/feature-map.md.
     Story / Test / Test Status: filled when the chain is linked (rtm mode);
     otherwise "—". Test Status: COVERED | MISSING | NONE | NO STORY. -->

| Req ID | PRD | Feature | Layer | Type | Requirement Summary | ADR(s) | Status | Story | Test | Test Status | Notes |
|--------|-----|---------|-------|------|---------------------|--------|--------|-------|------|-------------|-------|
| TR-[feature]-001 | [design/prd/feature.md] | [feature name] | [Foundation/Core/Feature/Presentation] | [functional] | [one-line summary] | [ADR-NNNN] | ✅ | [story path or —] | [test path or —] | [COVERED] | |
| TR-[feature]-002 | [design/prd/feature.md] | [feature name] | [layer] | [nfr (performance)] | [one-line summary] | — | ❌ GAP | — | — | NO STORY | Needs `/architecture-decision [title]` |

---

## Chain Coverage

<!-- Filled in rtm mode only. When the chain is not linked, write
     "NOT ASSESSED — chain not linked (run /architecture-review rtm)". -->

| Status | Count | % |
|--------|-------|---|
| COVERED — full chain complete (PRD → TR-ID → ADR → story → test) | [N] | [%] |
| MISSING test — story exists, test file not found | [N] | [%] |
| NONE — no test path; UI or Config story evidenced outside tests | [N] | [%] |
| NO STORY — ADR exists, not yet broken into stories | [N] | [%] |
| NO ADR — architectural gap | [N] | [%] |
| **Total requirements** | **[N]** | **100%** |

---

## Known Gaps

Requirements with no ADR coverage, prioritised by layer (Foundation first):

### Foundation Layer Gaps (BLOCKING — must resolve before coding)
- [ ] TR-[id]: [requirement] — PRD: [file] — Suggested ADR: "[title]"

### Core Layer Gaps (must resolve before the relevant feature is built)
- [ ] TR-[id]: [requirement] — PRD: [file] — Suggested ADR: "[title]"

### Feature Layer Gaps (should resolve before the feature's sprint)
- [ ] TR-[id]: [requirement] — PRD: [file] — Suggested ADR: "[title]"

### Presentation Layer Gaps (can defer to implementation)
- [ ] TR-[id]: [requirement] — PRD: [file] — Suggested ADR: "[title]"

---

## Cross-ADR Conflicts

<!-- Pairs of ADRs (or an ADR and a docs/registry/architecture.yaml entry) that
     make contradictory claims. Must be resolved. -->

| Conflict ID | ADR A | ADR B | Type | Status |
|-------------|-------|-------|------|--------|
| CONFLICT-001 | ADR-NNNN | ADR-MMMM | Data ownership | 🔴 Unresolved |

---

## ADR → PRD Coverage (Reverse Index)

<!-- For each ADR, which PRD requirements does it address? Foundational ADRs
     list what they enable instead. -->

| ADR | Title | Status | PRD Requirements Addressed | Knowledge Risk |
|-----|-------|--------|---------------------------|----------------|
| ADR-0001 | Identity and auth | Accepted | TR-auth-001, TR-goals-001 | MEDIUM |

---

## Superseded Requirements

<!-- Requirements that existed in a PRD when an ADR was written, but the PRD
     has since changed. The ADR may need updating. -->

| Req ID | PRD | Change | Affected ADR | Status |
|--------|-----|--------|-------------|--------|
| TR-[id] | [file] | [what changed] | ADR-NNNN | 🔴 ADR needs update |

---

## History

| Date | Covered % | Full Chain % | Notes |
|------|-----------|--------------|-------|
| [date] | [%] | [% or —] | Initial index |

---

## How to Use This Document

**When writing a new ADR**: Add it to the "ADR → PRD Coverage" table and mark
the requirements it satisfies as ✅ (Accepted) or 🟡 (Proposed) in the matrix.

**When a PRD changes**: run `/propagate-prd-change design/prd/<feature>.md`. It
records superseded requirements in its change-impact report; `/architecture-review`
carries them into the Superseded Requirements table.

**When running `/architecture-review`**: The skill will update this document
automatically with the current state; `/architecture-review rtm` also links
stories and tests.

**Gate check**: The Architecture → Validation gate (`/gate-check validation`)
requires this document to exist and to have zero Foundation Layer Gaps at the
`full` workflow tier; at `standard` both are recommended.
