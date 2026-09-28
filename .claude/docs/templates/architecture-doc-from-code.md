# ADR-[NNNN]: [Title]

<!--
TEMPLATE for a reverse-documented ADR at docs/architecture/adr-NNNN-<slug>.md,
written by /reverse-document architecture <path> when the implementation already
exists and the decision was never recorded.

It uses exactly the headings of .claude/docs/templates/architecture-decision-record.md,
in the same order, so every ADR reader (/architecture-review,
/create-control-manifest, /create-epics, /create-stories, /dev-story, /adopt,
.claude/scripts/adr-dep-graph.sh) parses it like any other ADR. Do not add,
rename, number or translate headings; use bold labels, lists and tables inside a
section instead.

What differs from a forward ADR:
- `## Status` is always `Proposed`. Reverse-documenting describes what the code
  does; it does not decide that it should keep doing it. The team accepts it
  through `/architecture-decision accept ADR-NNNN` like any other ADR.
- The `> **Origin**:` blockquote under `## Summary` records that the ADR was
  written after the fact and from which path, followed in the same blockquote by
  the three provenance lines /reverse-document writes. It is the only provenance
  marker — the status stays one of the four ADR status values.
- Every statement is marked as observed in code, clarified by the user, or
  inferred. An inference the user has not confirmed is labelled "(inferred)"; an
  intent question the user left unanswered is carried as
  `INTENT UNKNOWN — inferred from implementation, not confirmed`.
- Keep bold field labels, status tokens, IDs and paths in English. Write the
  prose in the user's conversation language.
-->

## Status

Proposed

> **Who may move this to `Accepted`: the user, or `technical-director` on the
> user's explicit confirmation. No other agent, and no skill on its own.** The
> route is `/architecture-decision accept ADR-NNNN`. Until then, stories whose
> governing ADR is this one stay `Blocked`.

## Date

[YYYY-MM-DD — when this ADR was reverse-documented]

## Last Verified

[YYYY-MM-DD — when this ADR was last confirmed to match the code at the source
path and the pinned stack in `docs/stack-reference/VERSION.md`]

## Decision Makers

[Who made the original decision, if known — "unknown (inferred from code)"
otherwise — and who clarified it during reverse-documentation. Example:
"backend team (original, 2025); tech-lead (clarified rationale); written by
/reverse-document"]

## Summary

> **Origin**: Reverse-documented from [path] on [YYYY-MM-DD]
> This records what the code **does**; intent marked `INTENT UNKNOWN` below was
> inferred, not confirmed by the author. Where this document and the code
> disagree, do not assume the document is the requirement.

[2 sentences: what problem the implementation solves and the approach the code
takes. Written for tiered context loading — name the capability, the problem and
the approach. Example: "Moa's payments module charges saved billing keys through
Toss Payments from a nightly worker job. Each charge carries an idempotency key
derived from the subscription and billing period, so a retried job never charges
twice."]

**Implementation status**: [Deployed | Partial | Planned]

## Stack Compatibility

| Field | Value |
|-------|-------|
| **Stack Components** | [Components the implementation uses, with versions from the lockfile or manifest, checked against `docs/stack-reference/VERSION.md` — note any drift, e.g. `Prisma 5.22 (pinned: Prisma 6)`] |
| **Domain** | [API / Data / Auth / Security / Frontend / Mobile / Infra / Messaging / Observability / Integrations / ML] |
| **Layer** | [Foundation / Core / Feature / Presentation] |
| **Knowledge Risk** | [LOW — in training data / MEDIUM — near cutoff, verify / HIGH — post-cutoff, must verify] — from the Pinned Components table; a component with no row counts as HIGH |
| **References Consulted** | [Paths under `docs/stack-reference/` read while documenting] |
| **Post-Cutoff APIs Used** | [Post-cutoff APIs the code calls, found by reading it — or "None"] |
| **Verification Required** | [Behaviours to confirm before other work builds on this — e.g. "deprecated API in use; confirm it survives the next minor upgrade" — or "None"] |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | [ADR-NNNN this implementation relies on, or "None"] |
| **Enables** | [ADR-NNNN that builds on it, or "None"] |
| **Blocks** | [Epic/Story name that cannot start until this ADR is Accepted, or "None"] |
| **Ordering Note** | [Any sequencing constraint — e.g. "document before the payments refactor epic starts"] |

## Context

### Problem Statement

[What problem did this implementation solve? Mark each point: (observed),
(clarified by user) or (inferred).]

### Current State

[What the code does today, with its locations:]

- `[path/to/module]` — [what is there]
- `[path/to/other]` — [what is there]

[Patterns used (repository, outbox, saga, BFF …), dependencies introduced,
concurrency and transaction handling, and how it is tested today — unit,
integration, contract, E2E, with the test paths.]

### Constraints

- [Constraints at the time of the original decision, as far as they can be
  recovered — stack, deadline, team, vendor, compliance]

### Requirements

- [Requirements the implementation satisfies, with TR-IDs where a PRD exists]

## Decision

[The approach as implemented, described so a new engineer understands it without
reading the code first.]

**Clarified rationale** (from the user):

- [Reason 1 — why this approach was chosen]
- [Reason 2 — what problem it solves]

### Architecture

```
[ASCII diagram of the components as implemented — clients, API modules, workers,
data stores, queues, third parties — with the direction of each call or event.]
```

### Key Interfaces

```
[The interfaces other code relies on today — API operations (method + path),
events (name + version + publisher and consumers), module functions, flags.]
```

### Implementation Guidelines

[The rules existing and future code must follow to stay consistent with this
decision, stated as "must / must never". Where the code already violates one,
say so and list it under Risks.]

## Alternatives Considered

[Alternatives the original authors likely weighed, confirmed with the user where
possible. Always include the status quo before the implementation. Mark each
"(inferred)" or "(clarified by user)".]

**Alternative 1: [Name]**

- **Description**: [What this alternative would have been]
- **Pros**: [Advantages]
- **Cons**: [Disadvantages]
- **Rejection Reason**: [Why it was not chosen — clarified or inferred]

**Alternative 2: [Status quo before the implementation]**

- **Description**: [What "doing nothing" would have meant]
- **Rejection Reason**: [Why the problem needed solving]

## Consequences

### Positive

- [Benefits the implementation delivers, with evidence — e.g. "no duplicate
  charges since the idempotency key was added (payments incident log)"]

### Negative

- [Trade-offs accepted — limitations, maintenance burden, lock-in]

### Neutral

- [Side effects and observations that are neither good nor bad]

## Risks

| Risk | Probability | Impact | Mitigation | Owner |
|------|------------|--------|-----------|-------|
| [Known issue found during analysis] | [Low / Medium / High] | [Low / Medium / High] | [Fix or monitoring] | [role] |

**Open questions left by reverse-documentation**:

1. [What is unclear about the decision or the code] — needs clarification from
   [role]; impact if unresolved: [consequence]

## Performance & SLO Implications

| Metric | Measured | Budget / SLO | Source of the measurement |
|--------|----------|--------------|---------------------------|
| [e.g. p95 latency of POST /v1/payments/charges] | [value or NOT DETERMINED] | [`performance.api_p95_ms` or the SLO in `docs/ops/slo.md`] | [dashboard, load-test report or profile path] |

- **Critical user journeys affected**: [journeys from `docs/ops/slo.md`, or "None"]
- **Known bottlenecks**: [observed or suspected, with evidence]

## Security & Privacy Implications

- **Authentication and authorization**: [how the code checks who may call what —
  and where it does not]
- **Trust boundaries**: [third-party callbacks, webhooks and client input the
  code handles, and how each is verified]
- **Personal data**: [fields the code stores or moves, each classified `Public`,
  `Internal`, `Confidential`, `PII` or `Sensitive-PII`, with retention and the
  deletion path as implemented — or "No personal data touched"]
- **Secrets**: [keys and tokens the code uses and where they come from]
- **Regional compliance**: [items to verify from `.claude/docs/compliance/<region>.md`
  for each configured region, or "none configured" / "unset — ask"]
- **Threat model**: [flows to add to `docs/security/threat-model.md`, or "no change"]

## Cost Implications

| Cost item | Current (monthly) | Pricing basis |
|-----------|-------------------|---------------|
| [e.g. payment gateway fees, queue, managed database] | [amount or NOT DETERMINED] | [invoice, pricing page URL with retrieval date, or NOT DETERMINED] |

- **Lock-in and exit cost**: [what replacing it would take]

## Migration Plan

[Follow-up work to bring the implementation and this record into line, if any —
missing tests, a deprecated API to replace, a refactor. Data changes follow
expand → migrate → contract (`docs/data/migrations/NNNN-<slug>.md`). Write
"None — the implementation matches this record" when nothing is needed.]

1. [Step 1]
2. [Step 2]

**Rollback plan**: [How the current implementation is rolled back today if a
deploy of it fails — or "NOT DETERMINED — no rollback path found in code or
pipeline", which is itself a Risk]

## Validation Criteria

[Evidence that the implementation works as recorded, and what would show it has
stopped working.]

- [ ] [e.g. "contract tests cover every operation in Key Interfaces"]
- [ ] [e.g. "no duplicate-charge incident in the last 90 days"]

## PRD Requirements Addressed

| PRD | Requirement (TR-ID) | How addressed |
|-----|---------------------|---------------|
| [e.g. `design/prd/payments.md`] | [e.g. `TR-payments-003`] | [how the implementation satisfies it] |

> If no PRD exists for this capability, write:
> "Foundational — no PRD requirement. Enables: [the features that depend on it]"
> — and consider `/reverse-document prd <path>` for the missing PRD.

## Related

- [Related ADRs — depends on, influenced, superseded]
- [Code paths — primary implementation and related modules]
- [Contracts and documents — `docs/api/openapi.yaml`, `docs/data/data-model.md`, runbooks]

*This ADR was generated by `/reverse-document architecture [path]`.*
