> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# TD-CHANGE-IMPACT — PRD Change Impact Review

Agent: `technical-director` | Model tier: Opus | Domain: Change impact

**Trigger**: Spawned by `/propagate-prd-change` after the change-impact report draft
is produced and before the resolution workflow begins — before any ADR, API contract
operation, data model entity, tracking event or story is revised. It checks which
ADRs, API operations, data model entities and tracking events a PRD change really
affects.

**Context to pass**:
- changed PRD path
- summary of the PRD diff
- impact report draft path

**Prompt**:
> "Review this change-impact assessment before anything is revised. Read the changed
> PRD and the impact report draft at the paths given; the diff summary tells you what
> changed. Check:
>
> 1. **ADR classification** — is any ADR under-classified, marked as still valid when
>    the change contradicts its assumptions? Example: `design/prd/goals.md` now allows
>    goals shared with a family member, so the ADR that decided owner-only access to
>    goals no longer holds.
> 2. **API contract** — operations whose request or response shape, auth scope,
>    pagination or semantics change. Breaking changes need a new version or a
>    deprecation path; mobile clients already in the field keep calling the old shape.
> 3. **Data model** — entities and fields added, renamed or retyped; migrations that
>    need an expand/contract plan; PII classification changes (a new personal-data
>    field brings consent, retention and deletion obligations).
> 4. **Tracking plan** — events added, renamed or removed, and the metrics and
>    dashboards that silently break when an event is renamed.
> 5. **Stories** — in-flight or ready stories whose acceptance criteria, TR-IDs or
>    `**API Contract**` / `**Migration**` fields are now stale.
> 6. **Cascades** — decisions that depend on the ones already flagged, feature flags
>    and configuration, business rules recorded in `design/registry/entities.yaml`.
> 7. **Recommended actions** — architecturally sound and ordered (contract and
>    migration before implementation).
>
> Return APPROVE, CONCERNS [the specific ADRs, operations, entities, events or
> stories to revisit], or REJECT [the assessment must be redone before resolution
> begins — say what was missed]."

**Verdicts**: APPROVE / CONCERNS / REJECT

The first line of the reply is exactly `[TD-CHANGE-IMPACT]: <TOKEN>` with one token
from the line above; the spawning skill parses it. Findings follow the first line.

**Special handling**:
- An artifact that does not exist yet (no API contract before Architecture, no
  tracking plan) is out of scope for this change — say so rather than flagging it.
