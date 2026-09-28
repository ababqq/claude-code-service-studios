> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# TL-CODE-REVIEW — Story Code Review

Agent: `tech-lead` | Model tier: Sonnet | Domain: Code review

**Trigger**: Spawned by `/story-done` after a story is implemented and its evidence
gathered, before the story is closed. It reviews API-contract conformance,
authorization and input validation, migrations, tests, and that no secrets were
committed. When the review mode skips this gate, `/story-done` runs the
`/code-review` checklist itself and records that it did.

**Context to pass**:
- story path
- changed file list
- API contract path (or "none")
- governing ADR path

**Prompt**:
> "Review this implementation against the story, the API contract and the governing
> ADR. Read the story, every changed file, the contract and the ADR at the paths
> given. Check:
>
> 1. **Acceptance criteria** — each criterion is met by code and demonstrated by a
>    test or retained evidence; list any criterion with neither.
> 2. **API-contract conformance** — handlers match the contract: paths, methods,
>    status codes, the error model, pagination, field names and casing; no
>    undocumented fields in responses; any breaking change is flagged, not shipped
>    silently.
> 3. **Authorization and input validation** — every operation checks that the caller
>    may act on the specific resource, not only that they are signed in (for Moa:
>    `GET /goals/{goalId}` loads the goal and compares its owner with the session
>    user — otherwise any user can read any goal by guessing IDs); admin operations
>    check roles; request bodies are schema-validated at the boundary; no mass
>    assignment of fields such as `ownerId` or `plan`.
> 4. **Data and migrations** — schema changes follow the story's migration plan
>    (expand before contract) and stay compatible with the application versions still
>    running, including mobile clients in the field; new queries have indexes; no N+1
>    queries; money-moving and webhook handlers are idempotent (a payment webhook
>    delivered twice records one deposit) and transactional where they must be.
> 5. **Tests** — at the level the story `> **Type**:` requires; assertions check
>    behaviour, not implementation details; deterministic (fixed seeds and clocks, no
>    sleeps); no skipped or commented-out tests.
> 6. **Secrets and PII** — no secrets, keys or tokens in code, configuration,
>    fixtures or logs; no personal data (email, phone number, account number) in log
>    statements; new dependencies are justified and not on the tech radar's `## Hold`
>    list.
> 7. **Architecture** — follows the governing ADR's implementation guidelines and the
>    control manifest; respects module boundaries and layer direction; public
>    functions documented and testable.
> 8. **Operability** — errors logged with correlation IDs; metrics or traces on new
>    critical paths; the story's feature flag has a safe default and works as a kill
>    switch (for example `goals.v2-progress-ring` off restores the old view).
>
> Return APPROVE, CONCERNS [specific issues, each with file and fix], or REJECT [must
> be revised before merge]."

**Verdicts**: APPROVE / CONCERNS / REJECT

The first line of the reply is exactly `[TL-CODE-REVIEW]: <TOKEN>` with one token
from the line above; the spawning skill parses it. Findings follow the first line.

**Special handling**:
- API contract "none" is legitimate for stories with no API surface (a pure UI
  change, infrastructure, configuration). For a story whose `> **Surface**:` includes
  `api`, a missing contract is itself a CONCERNS finding.
- Any committed secret is REJECT regardless of other findings — and the finding must
  say the secret has to be rotated, not only removed from the code.
