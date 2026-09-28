> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# TD-ADR — ADR Review Before Accepted

Agent: `technical-director` | Model tier: Opus | Domain: Architecture decisions, stack risk

**Trigger**: Spawned by `/architecture-decision` after an ADR is authored or
retrofitted, before its `## Status` moves to `Accepted`. It checks that stack
versions are stamped, PRD requirements are linked and the alternatives are real.

**Context to pass**:
- ADR path
- Knowledge Risk of the ADR's components (from `docs/stack-reference/VERSION.md`)
- related ADR paths

**Prompt**:
> "Review this Architecture Decision Record before it is accepted. Read the ADR and
> the related ADRs at the paths given. Check:
>
> 1. **Problem and context** — `## Context` states the problem, the current state,
>    the constraints and the requirements clearly enough that a new engineer could
>    re-derive why a decision was needed.
> 2. **Alternatives are real** — `## Alternatives Considered` has at least two options
>    a competent team would seriously consider, each rejected for a stated reason.
>    For `docs/architecture/adr-0001-identity-and-auth.md`: a managed identity
>    provider versus a library-based in-house session service, each evaluated for
>    Kakao / Naver / Apple login, token refresh on mobile, and account deletion.
>    Strawmen do not count.
> 3. **Consequences are honest** — negative consequences, lock-in and operating cost
>    are stated, not only benefits.
> 4. **Stack versions stamped** — `## Stack Compatibility` names each component with a
>    pinned version that matches `docs/stack-reference/VERSION.md`, the Domain, the
>    Layer and the Knowledge Risk; References Consulted point under
>    `docs/stack-reference/`; Post-Cutoff APIs Used are listed and Verification
>    Required says how they will be checked.
> 5. **PRD requirements linked** — `## PRD Requirements Addressed` maps TR-IDs (for
>    example `TR-goals-001`) to how the decision addresses them, or states
>    'Foundational — no PRD requirement. Enables: …'.
> 6. **Dependencies coherent** — `## ADR Dependencies` (Depends On / Enables / Blocks)
>    agrees with the related ADRs; no cycle; no contradiction with an Accepted ADR.
> 7. **Implications and plan** — `## Performance & SLO Implications`,
>    `## Security & Privacy Implications` and `## Cost Implications` are specific;
>    `## Migration Plan` carries a rollback plan; `## Validation Criteria` are
>    measurable.
> 8. **Knowledge Risk** — for HIGH or MEDIUM components, the post-cutoff APIs the
>    decision relies on are verified against the stack reference rather than
>    assumed.
>
> Return APPROVE, CONCERNS [specific gaps], or REJECT [the decision is
> underspecified or rests on unsound technical assumptions]."

**Verdicts**: APPROVE / CONCERNS / REJECT

The first line of the reply is exactly `[TD-ADR]: <TOKEN>` with one token from the
line above; the spawning skill parses it. Findings follow the first line.

**Special handling**:
- A component with Knowledge Risk HIGH or MEDIUM also triggers TD-STACK-RISK in
  `/architecture-decision`; an ADR in Domain `Auth`, `Security` or `Data` also
  triggers SE-SECURITY-REVIEW. Stay on decision quality here and defer version and
  security depth to those gates when they run.
- Review, never edit: the ADR moves to `Accepted` only through
  `/architecture-decision`, after the user approves.
