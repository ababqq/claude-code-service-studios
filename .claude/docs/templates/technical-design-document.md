# Technical Design: [Feature Name]

> **Status**: Draft | In Review | Approved
> **Feature**: [feature slug — e.g. `goals`]
> **PRD**: `design/prd/[feature-slug].md`
> **Governing ADRs**: [ADR-NNNN, ADR-NNNN — or "None"]
> **Author**: [role or person]
> **Reviewer**: tech-lead
> **Last Updated**: [YYYY-MM-DD]

<!--
TEMPLATE for docs/architecture/tdd-<feature>.md, written by
/create-architecture tdd <feature>.

A technical design is optional and per feature: write one when a feature is
complex enough that engineers on several surfaces need a shared plan before the
stories are written. It is never a gate artifact. It sits between the PRD (what
and why) and the stories (the work): it may refer to Accepted ADRs, the API
contract and the data model, but it does not replace them — a decision that
binds other features belongs in an ADR, and an operation or entity belongs in
the contract or the data model.

Keep these twelve headings exactly as spelled and in this order; use bold
labels, lists and tables inside a section instead of adding headings. Keep bold
field labels, IDs and paths in English and write the prose in the user's
conversation language.
-->

## Summary

[2–3 sentences: what this design builds, for which surfaces, and the main
technical approach. Example: "Adds automatic deposits to Moa savings goals on
web, iOS and Android. A nightly worker job charges each active auto-debit
mandate through Toss Payments and records the deposit on the goal; clients read
progress through the existing goals endpoints."]

## Context & Goals

**Why now**: [the PRD requirements this design implements, with TR-IDs — e.g.
`TR-goals-004`, `TR-goals-005`]

**Goals**:

- [Technical goal — e.g. "a deposit is recorded exactly once per mandate and
  period, even when the job retries"]

**Non-goals**:

- [What this design deliberately does not cover — e.g. "changing the debit
  schedule from the admin console"]

**Assumptions**: [what must be true — accepted ADRs, existing modules, vendor
capabilities confirmed in the stack reference]

## Design

[The design itself, precise enough to split into stories.]

**Components**:

| Component | Responsibility | Owns | Lives in |
|-----------|----------------|------|----------|
| [e.g. goals module] | [records deposits, computes progress] | [goal, deposit] | [e.g. `apps/api/src/modules/goals`] |

**Flow**:

```
[ASCII sequence or flow diagram — clients, API, workers, data stores, third
parties — with the direction of each call or event and where it is async.]
```

**States and transitions**: [state machine of the main entity, if any — e.g.
mandate `pending → active → paused → cancelled`, with who triggers each move]

**Failure handling**: [timeouts, retries with backoff, idempotency keys,
dead-letter handling, partial failure between steps, user-visible error states]

**Concurrency and consistency**: [transactions, locking, ordering guarantees,
what is strongly and what is eventually consistent]

## Stack & Dependency Surface

| Field | Value |
|-------|-------|
| **Stack Components** | [components and versions from `docs/stack-reference/VERSION.md` — e.g. `NestJS 11.0, Prisma 6, PostgreSQL 16`] |
| **Libraries and SDKs Added** | [name, purpose and tech radar ring for each new dependency — or "None"] |
| **Post-Cutoff APIs Used** | [with the reference file under `docs/stack-reference/` that confirms each — or "None"] |
| **Unverified Assumptions** | [API behaviours assumed but not yet proven against the pinned versions — or "None"] |
| **Knowledge Risk** | [LOW / MEDIUM / HIGH — the highest among the components above] |

> **Rule**: while **Unverified Assumptions** lists anything, this design cannot
> move to `Approved` — prove each assumption on a local or staging environment
> first, or record it as an open question.

## NFRs

| Requirement | Target | Source | How it is verified |
|-------------|--------|--------|--------------------|
| [e.g. p95 of GET /v1/goals/{goalId}] | [e.g. ≤ 300 ms] | [`performance.api_p95_ms` / PRD `## Non-Functional Requirements`] | [load-test profile, perf profile] |
| [e.g. availability of the deposit journey] | [SLO] | [`docs/ops/slo.md`] | [SLO dashboard] |
| [e.g. accessibility of the new screens] | [`accessibility.target`] | [PRD] | [axe report, screen-reader pass] |

## API Contract

[The operations this feature adds or changes, referenced into the contract —
never a second copy of it. New or changed operations are designed with
`/api-design`.]

| Operation | Method + path | Auth scope | Change | Contract reference |
|-----------|---------------|------------|--------|--------------------|
| [e.g. create auto-debit mandate] | [POST /v1/goals/{goalId}/mandates] | [owner of the goal] | [new] | [`docs/api/openapi.yaml#/paths/...`] |

**Events**: [name, version, schema reference, publisher and consumers — or "None"]

**Compatibility**: [breaking or non-breaking; for mobile clients, the oldest
app version that must keep working]

## Data Model & Migrations

[Entities and fields this feature adds or changes, referenced into
`docs/data/data-model.md` — designed with `/data-model`.]

| Entity | Change | Classification | Owner module | Migration plan |
|--------|--------|----------------|--------------|----------------|
| [e.g. mandate] | [new table] | [Confidential — billing key reference, never the card number] | [payments] | [`docs/data/migrations/NNNN-<slug>.md`] |

**Migration phases**: [expand → migrate → contract, and how each phase is
ordered against the application deploy — or "None"]

## Rollout & Flags

| Flag | Default | Owner | Removal date |
|------|---------|-------|--------------|
| [e.g. `goals.auto-debit`] | [off] | [product-manager] | [YYYY-MM-DD] |

**Rollout**: [stages per surface — internal users, percentage steps, mobile
phased release — and the guardrail metrics that halt it; the full plan is
written per release with `/rollout-plan`]

**Kill switch and rollback**: [how the feature is turned off without a deploy,
and what happens to data written while it was on]

## Observability

- **Logs**: [structured events added, with the fields — never personal data]
- **Metrics**: [counters, histograms and the SLI they feed]
- **Traces**: [spans across client, API and worker; correlation ID propagation]
- **Dashboards and alerts**: [what is added to `docs/ops/slo.md`
  `## Dashboards & Alerts`, and whether any alert pages]
- **Analytics events**: [events from `design/product/tracking-plan.md` this
  feature emits]

## Security & Privacy

- **Authorization**: [object-level checks for every operation that takes an ID;
  roles for admin operations]
- **Personal data**: [fields, classification, retention, deletion path]
- **Trust boundaries**: [webhooks and third-party callbacks and how each is
  verified; client values the server recomputes]
- **Secrets**: [keys introduced and where they are stored]
- **Abuse**: [rate limits, automation of the flow by attackers, enumeration]

## Alternatives

**[Alternative name]** — [how it would work; why it was not chosen]

**[Alternative name]** — [how it would work; why it was not chosen]

[A choice that binds other features belongs in an ADR — write it with
`/architecture-decision` and link it here.]

## Open Questions

| Question | Owner | Needed by | Resolution path |
|----------|-------|-----------|-----------------|
| [e.g. how are failed debits retried within the billing period?] | [product-manager] | [before story breakdown] | [PRD update / ADR / spike] |
