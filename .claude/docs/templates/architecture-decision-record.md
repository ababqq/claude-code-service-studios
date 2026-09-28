# ADR-[NNNN]: [Title]

<!--
TEMPLATE for docs/architecture/adr-NNNN-<slug>.md. /architecture-decision copies
this file; it is the single source of the ADR heading contract. Readers that
match these headings: /architecture-review, /create-control-manifest,
/create-epics, /create-stories, /story-readiness, /dev-story, /story-done,
/propagate-prd-change, /adopt, .claude/scripts/adr-dep-graph.sh (the
Depends On row of ADR Dependencies) and the Validation and Build gates.

- Keep every heading exactly as spelled and in this order. Do not add, rename,
  number or translate headings; use bold labels, lists and tables inside a
  section instead (alternatives, risks and costs below already do).
- Keep bold field labels, status tokens, IDs and paths in English. Write the
  prose in the user's conversation language.
- Replace every [bracketed placeholder]. A field with nothing to record says
  "None" (or "NOT DETERMINED — <reason>" when it could not be found out);
  it is never left blank.
-->

## Status

[Proposed | Accepted | Superseded by ADR-NNNN | Deprecated]

> **Who may move this to `Accepted`: the user, or `technical-director` on the
> user's explicit confirmation. No other agent, and no skill on its own.**
> Stated here because every consumer of this field enforces the *consequences*
> of acceptance (stories whose governing ADR is still `Proposed` stay `Blocked`;
> epics and the control manifest require `Accepted`), so something has to say
> who may produce it. `technical-director` is the role `coordination-rules.md`
> already escalates technical conflicts to, and an ADR is exactly that decision
> made durable.
>
> This does **not** relax the rule that `Accepted` is never set without explicit
> user confirmation — it narrows *which agent* may set it once that confirmation
> exists. An agent that believes an ADR is ready says so and escalates; it does
> not edit this field. The route is `/architecture-decision accept ADR-NNNN`.

## Date

[YYYY-MM-DD — when this ADR was written; `/architecture-decision accept` sets it
to the date the decision was accepted]

## Last Verified

[YYYY-MM-DD — when this ADR was last confirmed accurate against the pinned stack
(`docs/stack-reference/VERSION.md`) and the PRDs it serves. Update this date when
you re-read and confirm it is still correct, even if nothing changed. Stories copy
it as their `**ADR Version**`, so a newer date tells `/story-done` the story was
written against an older decision.]

## Decision Makers

[Who decided — roles or names, e.g. "tech-lead (author), technical-director, the
product owner"]

[Review records — one line per gate that ran, written by `/architecture-decision`;
a gate skipped by review mode leaves its skip note on the same line instead:]
> **Technical Director Review (TD-ADR)**: [APPROVED | CONCERNS (accepted) | REVISED] [YYYY-MM-DD]
> **Technical Director Review (TD-STACK-RISK)**: [only when a component's Knowledge Risk is HIGH or MEDIUM]
> **Security Engineer Review (SE-SECURITY-REVIEW)**: [only when Domain is Auth, Security or Data]

## Summary

[2 sentences: what problem this ADR solves, and what was decided. Written for
tiered context loading — a skill scanning 20 ADRs uses this to decide whether
to read the full decision. Be specific: name the capability, the problem and the
chosen approach. Example: "Moa needs one account identity across email, Kakao,
Naver and Apple sign-in on web, iOS and Android. We adopt a managed identity
provider with short-lived access tokens and rotating refresh tokens, and link a
social login to an existing account only after the user proves ownership of both."]

## Stack Compatibility

| Field | Value |
|-------|-------|
| **Stack Components** | [Each component this decision relies on, with the version pinned in `docs/stack-reference/VERSION.md` — e.g. `NestJS 11.0, PostgreSQL 16, Redis 7`. A component this ADR introduces before it is pinned: `<name> — not pinned (run /setup-stack refresh after acceptance)`] |
| **Domain** | [API / Data / Auth / Security / Frontend / Mobile / Infra / Messaging / Observability / Integrations / ML] |
| **Layer** | [Foundation / Core / Feature / Presentation] |
| **Knowledge Risk** | [LOW — in training data / MEDIUM — near cutoff, verify / HIGH — post-cutoff, must verify] — the highest risk among the Stack Components, taken from the Pinned Components table; a component not pinned yet counts as HIGH |
| **References Consulted** | [Paths read before deciding, all under `docs/stack-reference/` — e.g. `docs/stack-reference/nestjs/VERSION.md`, `docs/stack-reference/nestjs/breaking-changes.md`] |
| **Post-Cutoff APIs Used** | [APIs or features from versions released after the model's knowledge cutoff that this decision depends on, each with the reference file that confirms it — or "None"] |
| **Verification Required** | [Concrete behaviours to prove against the pinned versions before the first story ships — e.g. "refresh-token rotation revokes the old token family on reuse, tested against the staging identity tenant" — or "None"] |

> **Note**: If Knowledge Risk is MEDIUM or HIGH, this ADR must be re-validated when
> the project upgrades any listed component — `/setup-stack upgrade` lists it as
> "re-validation required". If the decision no longer holds on the new version,
> write a new ADR that supersedes this one; do not edit the decision in place.

> **`Layer` is the ADR's own layer, not the referencing epic's — and it is a
> different taxonomy from `Domain`.** Several readers branch on whether an ADR is
> *critical (Foundation-layer)*: `/create-epics`, `/create-stories`,
> `/architecture-decision` and the Validation gate. At `standard`,
> `/create-stories` **stops** for a missing critical ADR and only **warns** for a
> non-critical one, so this row decides whether a run halts. Inferring the layer
> from the referencing epic gives the wrong answer whenever a Foundation-layer ADR
> is referenced by a Core-layer epic — the common case.
>
> The vocabulary is the same `Foundation / Core / Feature / Presentation` that
> epics and stories already carry — do not invent a fifth value, and do not reuse
> a `Domain` value here. `Domain` says *what part of the system this touches*;
> `Layer` says *how early in the build it must exist*. Identity & auth, the
> primary data store, the API style, deployment topology & environments,
> observability and secrets management are Foundation.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | [ADR-NNNN (must be Accepted before this can be implemented), or "None"] |
| **Enables** | [ADR-NNNN (this ADR unlocks that decision), or "None"] |
| **Blocks** | [Epic/Story name — cannot start until this ADR is Accepted, or "None"] |
| **Ordering Note** | [Any sequencing constraint that isn't captured above] |

## Context

### Problem Statement

[What problem are we solving? Why must this decision be made now? What is the
cost of not deciding — which stories, epics or other ADRs wait on it?]

### Current State

[How does the product work today? For a new product: what exists (walking
skeleton, prototype, nothing) and which assumption the team is currently running
on. For a change: what is wrong with the current approach, with evidence —
incident, load-test result, cost report, audit finding.]

### Constraints

- [Stack constraints — pinned versions, framework idioms, managed-service limits]
- [Platform constraints — App Store / Google Play rules, browser support
  (`platform.browsers`), minimum OS versions]
- [Team constraints — size, skills, on-call capacity]
- [Timeline constraints — milestone, launch date, dependencies]
- [Compliance constraints — the topics of `.claude/docs/compliance/<region>.md`
  for each configured region, or "none configured"]
- [Budget constraints — monthly spend ceiling, vendor contracts]

### Requirements

- [Functional requirement, with its TR-ID where one exists — e.g. `TR-goals-001`]
- [Performance requirement — specific and measurable, tied to a
  `performance.*` budget or an SLO in `docs/ops/slo.md`]
- [Availability and consistency requirement — e.g. "a deposit is never recorded
  twice; strong consistency for money movement"]
- [Security and privacy requirement — who may call what; which personal data]
- [Scalability requirement — expected load at launch and at 10×]

## Decision

[The specific technical decision, described in enough detail for an engineer to
implement it without further clarification.]

### Architecture

```
[ASCII diagram of the components this decision creates or changes — clients,
edge/CDN, API modules, workers, data stores, queues, third parties — with the
direction of each call or event and the trust boundaries.]
```

### Key Interfaces

```
[The contracts this decision creates, which implementers must respect:
- API operations: method + path + auth scope, with the contract reference
  (e.g. docs/api/openapi.yaml#/paths/~1v1~1goals)
- Events: name + version + schema reference + publisher and consumers
  (e.g. goals.deposit.recorded v1, published by the goals module through the outbox)
- Module interfaces: the functions or services other modules may call
- Configuration and feature flags this decision introduces]
```

### Implementation Guidelines

[Specific guidance for the engineer implementing this decision — the rules a
`/create-control-manifest` or `/dev-story` run follows. State mandates as
"must / must never" so they extract cleanly, e.g. "Every handler that takes a
`goalId` must check that the goal belongs to the caller." / "Clients must never
compute a charge amount; the server computes it from the plan catalog."]

## Alternatives Considered

[At least two options a competent team would seriously consider — including
"keep the current approach" when one exists. One block per alternative:]

**Alternative 1: [Name]**

- **Description**: [How this approach would work]
- **Pros**: [What is good about this approach]
- **Cons**: [What is bad about this approach]
- **Estimated Effort**: [Relative effort compared to the chosen approach]
- **Rejection Reason**: [Why this was not chosen]

**Alternative 2: [Name]**

[Same structure as above]

## Consequences

### Positive

- [Good outcomes of this decision]

### Negative

- [Trade-offs and costs we are accepting — lock-in, operating load, complexity]

### Neutral

- [Changes that are neither good nor bad, just different]

## Risks

| Risk | Probability | Impact | Mitigation | Owner |
|------|------------|--------|-----------|-------|
| [e.g. identity provider outage blocks every sign-in] | [Low / Medium / High] | [Low / Medium / High] | [e.g. cached session validation for existing sessions; status-page alert] | [role] |

## Performance & SLO Implications

| Metric | Before | Expected After | Budget / SLO |
|--------|--------|---------------|--------------|
| API p95 latency on the affected operations | [X] ms | [Y] ms | `performance.api_p95_ms` = [Z] ms |
| Error rate | [X]% | [Y]% | `performance.error_rate_pct` = [Z]% |
| Availability of the affected journeys | [X]% | [Y]% | `performance.availability_pct` / SLO in `docs/ops/slo.md` |
| Web LCP / INP (p75), if a web surface is affected | [X] ms | [Y] ms | `performance.lcp_ms` / `performance.inp_ms` |
| Mobile cold start / crash-free sessions, if a mobile surface is affected | [X] | [Y] | `performance.cold_start_ms` / `performance.crash_free_pct` |
| Capacity — requests/s, database load, queue lag | [X] | [Y] | [target] |

- **Critical user journeys affected**: [journey names from `docs/ops/slo.md`
  `## Critical User Journeys`, or "None"]
- **Error budget impact**: [e.g. "adds a synchronous call to the identity
  provider on every token refresh — its availability now bounds sign-in"]

## Security & Privacy Implications

- **Authentication and authorization**: [what changes in who can call what —
  object-level ownership checks, roles, scopes, step-up verification]
- **Trust boundaries**: [new boundaries or crossings — third-party callbacks,
  webhooks, client-supplied values the server must not trust]
- **Personal data**: [fields created, read or moved, each classified `Public`,
  `Internal`, `Confidential`, `PII` or `Sensitive-PII`, with retention and the
  deletion path — or "No personal data touched"]
- **Secrets**: [keys, tokens or certificates introduced; where they are stored
  and how they rotate — or "None"]
- **Regional compliance**: [items to verify from `.claude/docs/compliance/<region>.md`
  for each region in `compliance.regions`; "none configured" when the list is
  explicitly empty; "unset — ask" when it is unset]
- **Threat model**: [flows or trust boundaries to add to
  `docs/security/threat-model.md`, or "no change"]

## Cost Implications

| Cost item | MVP scale (monthly) | 10× scale (monthly) | Pricing basis |
|-----------|---------------------|---------------------|---------------|
| [e.g. managed identity provider — monthly active users] | [amount] | [amount] | [pricing page URL, retrieved YYYY-MM-DD — or NOT DETERMINED] |

- **Largest cost driver**: [what grows fastest with usage]
- **Lock-in and exit cost**: [what it takes to replace this component or vendor]
- **Operating cost**: [on-call load, upgrades, maintenance the team takes on]

## Migration Plan

[If this changes existing behaviour, code or data: the step-by-step plan. Data
changes follow expand → migrate → contract, planned in
`docs/data/migrations/NNNN-<slug>.md`; client changes state the compatibility
window for mobile app versions that cannot be updated at once. For a new
product with nothing to migrate, write "None — greenfield".]

1. [Step 1 — what changes, what breaks, how to verify]
2. [Step 2]
3. [Step 3]

**Rollback plan**: [How to revert if this decision proves wrong — flag off,
redeploy the previous version, dual-write window, data restore — and the point
after which rollback is no longer possible]

## Validation Criteria

[How we will know this decision was correct after implementation.]

- [ ] [Measurable criterion — e.g. "p95 of POST /v1/goals ≤ 300 ms on staging under the load-test profile"]
- [ ] [Functional criterion — e.g. "contract tests cover every operation in Key Interfaces"]
- [ ] [Operational criterion — e.g. "the rollback plan was rehearsed on staging"]

## PRD Requirements Addressed

<!-- This section is MANDATORY. Every ADR traces back to at least one PRD
     requirement, or states that it is a foundational decision with no PRD
     requirement. Traceability is audited by /architecture-review. -->

| PRD | Requirement (TR-ID) | How addressed |
|-----|---------------------|---------------|
| [e.g. `design/prd/goals.md`] | [e.g. `TR-goals-001` — "a user can create a savings goal with a target amount and date"] | [e.g. "goals module owns the goal aggregate; POST /v1/goals is idempotent per Idempotency-Key"] |

> If this is a foundational decision with no direct PRD requirement, write:
> "Foundational — no PRD requirement. Enables: [the features or ADRs this
> decision unlocks or constrains]"

## Related

- [Related ADRs — note whether this supersedes, depends on, or constrains each]
- [Contracts and documents — `docs/api/openapi.yaml`, `docs/data/data-model.md`,
  `docs/security/threat-model.md`, `docs/ops/slo.md`, the tech radar entry]
- [Implementation paths once built]
