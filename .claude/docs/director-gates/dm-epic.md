> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# DM-EPIC — Epic Structure Feasibility

Agent: `delivery-manager` | Model tier: Opus | Domain: Epic structure

**Trigger**: Spawned by `/create-epics` after the epics are defined and before
stories are broken out with `/create-stories`. It checks epic sizing and ordering so
that story breakdown starts from a deliverable structure.

**Context to pass**:
- `production/epics/index.md` path
- EPIC.md paths
- `docs/architecture/architecture.md` path

**Prompt**:
> "Review this epic structure for delivery feasibility before story breakdown begins.
> Read the epic index, each EPIC.md and the architecture document at the paths given.
> Check:
>
> 1. **Epic ↔ module** — each epic maps to one architectural module of the
>    architecture document; no module is split across epics without a reason, and no
>    epic spans unrelated modules.
> 2. **Sizing** — each epic can complete within one milestone; oversized epics should
>    split into two or three focused ones, undersized ones merge.
> 3. **Ordering** — by dependency and layer: Foundation epics (identity & auth, data
>    access, observability) before Core (for Moa: `goals-core`, `payments`) before
>    Feature and Presentation. Can the Core epics start as soon as Foundation
>    completes?
> 4. **Parallelism across surfaces** — with the API contract agreed first, web,
>    mobile and API work can proceed in parallel; epics that serialise them without
>    need are flagged. Mobile work respects the store review cadence.
> 5. **Delivery content** — each epic lists its API operations, owned entities,
>    migrations, feature flags and rollout plan, an NFR table, and its stack risk.
> 6. **Untraced requirements** — MVP PRD requirements that no epic covers.
>
> Return REALISTIC (the epic structure is deliverable), CONCERNS [specific structural
> adjustments before stories are written], or UNREALISTIC [epics must be split,
> merged or reordered — story breakdown cannot begin until resolved]."

**Verdicts**: REALISTIC / CONCERNS / UNREALISTIC

The first line of the reply is exactly `[DM-EPIC]: <TOKEN>` with one token from the
line above; the spawning skill parses it. Findings follow the first line.

**Special handling**:
- At the `minimal` workflow tier an epic may be synthesised from the one-pager's
  `## Build Order` without an architecture document; if the architecture path does
  not exist, report `NOT CHECKED — epic ↔ module mapping (no architecture document)`
  and review ordering and sizing only.
