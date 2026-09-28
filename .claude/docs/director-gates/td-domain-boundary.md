> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# TD-DOMAIN-BOUNDARY — Domain & Service Boundary Review

Agent: `technical-director` | Model tier: Opus | Domain: Architecture, domain boundaries, data ownership

**Trigger**: Spawned by `/map-features` once features, layers and dependencies are
agreed and before PRD authoring begins — it validates bounded contexts, data
ownership and sync-versus-async coupling before teams invest in PRDs written against
those boundaries.

**Context to pass**:
- feature map path
- brief path
- `docs/registry/architecture.yaml` path (or "none")
- resolved `stack` line

**Prompt**:
> "Review this feature decomposition from an architectural perspective before PRD
> authoring begins. Read the feature map and the brief at the paths given, and the
> architecture registry if one exists. Check:
>
> 1. **Bounded contexts** — does each feature own one distinct concern with minimal
>    overlap? Flag features that claim the same concept (for Moa: `goals` and
>    `payments` both claiming the 'deposit' record) and god-features doing too much
>    (an `account` feature that owns sign-in, profile, subscription state and
>    notification preferences).
> 2. **Data ownership** — every core entity has exactly one owning feature that
>    writes it; others read through an API or react to events. For Moa: `payments`
>    owns the auto-debit mandate and payment transactions; `goals` owns goals and
>    derives progress from 'payment settled' events — it never writes a transaction.
>    Cross-check the `data_ownership` section of the registry when one exists.
> 3. **Coupling** — where does a request need a synchronous answer (an authorisation
>    check) and where should it be an event ('payment settled' → goal progress →
>    push / 알림톡)? Flag request paths that chain synchronous calls across three or
>    more features, flows that need a distributed transaction (and whether an outbox
>    or saga is planned), and webhook-driven flows that must be idempotent because
>    payment providers deliver at least once.
> 4. **Layering** — Foundation features (identity, accounts, data access,
>    observability) never depend on Core or Feature-layer ones; no cycles; the
>    dependency order is implementable in sequence.
> 5. **Deployment shape** — given the resolved stack, recommend module boundaries
>    inside a modular monolith for a small team unless a boundary has a genuinely
>    different scaling, availability or compliance need (isolating payment
>    processing to narrow the regulated scope; a separate worker for notification
>    fan-out). Do not recommend separate services by default.
> 6. **External boundaries** — each third party (Kakao / Naver / Apple login, the
>    payment provider, the 알림톡 vendor, push providers) sits behind an adapter
>    owned by exactly one feature.
>
> Return APPROVE (boundaries are sound — proceed to PRD authoring), CONCERNS
> [specific boundary issues to resolve inside the PRDs' `## Dependencies` and
> `## API & Data Impact` sections], or REJECT [the feature structure will cause
> ownership conflicts or tight coupling and must be restructured before any PRD is
> written]."

**Verdicts**: APPROVE / CONCERNS / REJECT

The first line of the reply is exactly `[TD-DOMAIN-BOUNDARY]: <TOKEN>` with one token
from the line above; the spawning skill parses it. Findings follow the first line.

**Special handling**:
- A registry passed as "none" is normal before the Architecture phase: derive
  ownership from the feature map and recommend the `data_ownership` entries to create
  later.
- If the resolved `stack` line reads `stack: unset — run /setup-stack`, assess the
  boundaries stack-agnostically and report
  `NOT CHECKED — deployment shape (stack not configured)`; do not recommend a
  framework.
