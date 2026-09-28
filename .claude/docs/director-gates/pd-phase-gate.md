> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# PD-PHASE-GATE — Product Readiness at Phase Transition

Agent: `product-director` | Model tier: Opus | Domain: Product readiness

**Trigger**: Spawned by `/gate-check` in parallel with the other `-PHASE-GATE` gates,
whenever the panel width that `/gate-check` Section 4b resolves includes
`product-director`. It assesses problem/solution evidence, whether metrics are
defined, and whether scope still traces to the value proposition.

**Context to pass**:
- target phase
- gate reference file path
- artifact-check output for the departure phase
- brief path
- feature map path (or "none")

**Prompt**:
> "Review the project's readiness to enter [target phase] from a product
> perspective. Read the gate reference file at the path given — it is the checklist
> for this transition, and the only gate reference file you read — then the brief, and the
> feature map if one was passed. Use the artifact-check output as observations of
> what exists on disk; do not re-derive them. Assess:
>
> 1. **Problem and solution evidence, proportional to the phase** — entering
>    Definition, the problem is evidenced and every riskiest assumption has a test;
>    entering Architecture, the MVP PRDs trace to the principles and value
>    proposition; entering Validation or Build, architecture and API choices have not
>    traded away user value, and user evidence exists on the core flow; entering
>    Hardening or Launch, the MVP features deliver what the PRDs promised.
> 2. **Metrics defined** — a North Star and at least one guardrail in the brief; each
>    MVP PRD with a metric that has a baseline and target; before Launch, the events
>    those metrics need are in the tracking plan and a dashboard exists to read them.
> 3. **Scope traceable to the value proposition** — every MVP feature maps to a job
>    and a principle; no silent scope growth since the feature map was approved.
> 4. **Decisions deferred past their last responsible moment** — for Moa, entering
>    Build with the Plus plan's price and entitlements still undecided while
>    `subscription` is an MVP feature.
> 5. **Launch-facing product readiness** (entering Launch only) — Terms of Service and
>    Privacy Policy, support channels and help-center content for the core journeys,
>    store listing claims that match the product.
>
> Return READY, CONCERNS [list], or NOT READY [blockers — name the missing artifact
> or decision and why it matters at this phase]."

**Verdicts**: READY / CONCERNS / NOT READY

The first line of the reply is exactly `[PD-PHASE-GATE]: <TOKEN>` with one token
from the line above; `/gate-check` parses it. Findings follow the first line.

**Special handling**:
- Advisory: this verdict feeds `/gate-check`, which applies the strictest verdict of
  the panel and decides nothing on its own. Never propose writing `project.stage`.
- "none" for the feature map is expected when entering Definition; from Architecture
  on, a missing feature map is a finding (at the `minimal` workflow tier the
  one-pager replaces both brief and feature map — judge the one-pager instead).
- Items the artifact-check output reports as `NO_CHECK` or `UNKNOWN` are not
  evidence of absence: check them by reading the files, or report them as
  `NOT CHECKED — <reason>`.
