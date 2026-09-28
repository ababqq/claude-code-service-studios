> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# DM-PHASE-GATE — Delivery Readiness at Phase Transition

Agent: `delivery-manager` | Model tier: Opus | Domain: Delivery readiness

**Trigger**: Spawned by `/gate-check` in parallel with the other `-PHASE-GATE` gates,
at the panel width that `/gate-check` Section 4b resolves. It assesses scope,
schedule, the risk register and dependencies.

**Context to pass**:
- target phase
- gate reference file path
- artifact-check output for the departure phase
- `production/risk-register/` path (or "none")

**Prompt**:
> "Review the project's readiness to enter [target phase] from a delivery
> perspective. Read the gate reference file at the path given — it is the checklist
> for this transition, and the only gate reference file you read — and the risk register
> entries if a register exists. Use the artifact-check output as observations of
> what exists on disk; do not re-derive them. Assess:
>
> 1. **Scope** — is the scope for the coming phase realistic for the timeline and
>    capacity? Has it grown since it was last approved?
> 2. **Schedule** — does a plan exist for the coming phase: milestone dates, a first
>    sprint plan entering Build (at the `minimal` workflow tier, the one-pager's
>    `## Build Order` is the plan), a release train and rollout plan entering Launch?
> 3. **Risk register** — the top risks have an owner, a mitigation and a trigger; no
>    stale entries; risks that have materialised are handled as issues.
> 4. **Dependencies** — external ones (vendor contracts and reviews, app store review,
>    legal sign-off, data migrations) and cross-team ones are ordered so the team can
>    execute in sequence; nothing on the critical path waits on an unscheduled
>    decision.
> 5. **First two sprints of the phase** — anything likely to derail them.
>
> Return READY, CONCERNS [list], or NOT READY [blockers — name what is missing and
> why it matters at this phase]."

**Verdicts**: READY / CONCERNS / NOT READY

The first line of the reply is exactly `[DM-PHASE-GATE]: <TOKEN>` with one token
from the line above; `/gate-check` parses it. Findings follow the first line.

**Special handling**:
- Advisory: this verdict feeds `/gate-check`, which applies the strictest verdict of
  the panel and decides nothing on its own. Never propose writing `project.stage`.
- A risk register passed as "none" is not "no risks": list the risks you can see from
  the artifacts, each with a proposed owner, mitigation and trigger, and recommend
  recording them (`/sprint-plan` offers to create an entry). The missing register is
  a recommendation in the findings, never a verdict item: no gate reference file
  requires one, so its absence alone does not lower the verdict at any phase. Judge
  item 3 on the risks you listed — a risk likely to derail the coming phase with no
  mitigation anywhere in the artifacts is a CONCERNS item on its own merits.
- Items the artifact-check output reports as `NO_CHECK` or `UNKNOWN` are not
  evidence of absence: check them by reading the files, or report them as
  `NOT CHECKED — <reason>`.
