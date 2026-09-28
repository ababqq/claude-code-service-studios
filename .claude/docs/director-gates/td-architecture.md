> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# TD-ARCHITECTURE — Architecture Sign-off

Agent: `technical-director` | Model tier: Opus | Domain: Architecture, NFR/SLO, security model

**Trigger**: Spawned by `/create-architecture` after the architecture document and
the SLO document are drafted, and after any major architecture revision. It signs
off NFR/SLO coverage, the security model, data ownership and consistency, the
multi-client design and the environments before ADRs are accepted and code is
written.

**Context to pass**:
- `docs/architecture/architecture.md` path
- `docs/ops/slo.md` path
- resolved `stack` line
- MVP PRD paths

**Prompt**:
> "Review this architecture for technical soundness. Read the architecture document,
> the SLO document and the MVP PRDs at the paths given. Check:
>
> 1. **NFR and SLO coverage** — every MVP PRD's `## Non-Functional Requirements`
>    (performance, availability, security & privacy, accessibility, localization) is
>    met by an architectural decision or listed as an open question. The critical
>    user journeys in the SLO document have SLIs and SLOs consistent with the
>    `performance.*` budgets, and the topology can meet them — 99.9% monthly
>    availability leaves about 43 minutes of error budget, which a single-instance
>    database with manual failover cannot credibly promise.
> 2. **Security model** — authentication (sessions or tokens, refresh and revocation,
>    social login and account linking), authorization per resource (object-level
>    ownership checks, admin roles), trust boundaries, secrets management, encryption
>    in transit and at rest, PII flows and PII-free logs; the admin console behind
>    SSO/MFA with an audit log.
> 3. **Data ownership and consistency** — one owning module per entity, consistent
>    with the `data_ownership` section of `docs/registry/architecture.yaml`; the
>    consistency model per flow (strong for money movement, eventual for
>    notifications); idempotency keys; an outbox or equivalent for events; verified,
>    idempotent webhook handling; an expand/contract approach to schema migrations.
> 4. **Multi-client** — web, iOS, Android and admin share one API contract; versioning
>    and backward compatibility for mobile clients that cannot be force-updated
>    immediately; a minimum supported app version and force-update policy; BFF only
>    where a client genuinely needs a different shape.
> 5. **Environments** — dev, staging, prod and preview deployments; staging parity
>    with production; configuration and feature flags per environment; deploys only
>    through the CI/CD pipeline; seed data; no production credentials outside
>    production.
> 6. **Observability** — logs, metrics and traces (the three signals) with
>    correlation IDs across web, mobile, API and workers; alerting on SLO burn rate.
> 7. **Stack risk and Foundation decisions** — every HIGH or MEDIUM Knowledge Risk
>    component is addressed or flagged as an open question; the Foundation-layer
>    decisions (identity & auth, primary data store, API style, deployment topology &
>    environments, observability) are each identified as an ADR to write or accept.
> 8. **Cost** — an order-of-magnitude monthly estimate at MVP scale, with the largest
>    cost drivers named.
>
> Return APPROVE, CONCERNS [list], or REJECT [blockers that must be resolved before
> ADRs are accepted and coding starts]."

**Verdicts**: APPROVE / CONCERNS / REJECT

The first line of the reply is exactly `[TD-ARCHITECTURE]: <TOKEN>` with one token
from the line above; the spawning skill parses it. Findings follow the first line.

**Special handling**:
- A passed path that does not exist is reported, not assumed: mark the checks that
  depend on it `NOT CHECKED — <path> absent` and do not return APPROVE on evidence
  you could not read.
- Recommend proportionate architecture. For an early-stage team, a managed platform
  and a modular monolith are usually the right answer; call out designs whose
  operational load exceeds what the team can run.
