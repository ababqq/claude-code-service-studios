> Gate definition, loaded by `/gate-check` for the TARGET PHASE ONLY.
> Never load the other five — one gate applies per invocation.


# Gate: Discovery → Definition


**Required Artifacts:**
- [ ] `design/product/product-brief.md` exists, has content, and carries the `##` sections
      `Problem Statement`, `Target Users & Jobs-to-be-Done`, `Value Proposition`,
      `Product Principles & Anti-Goals`, `Success Metrics`, `Riskiest Assumptions` and
      `MVP Scope` (written by `/brainstorm` at `standard`/`full`)
- [ ] Each product principle states the trade-off it decides — a decision test
      ("when fast sign-up conflicts with complete KYC data, we choose fast sign-up and
      collect the rest at the first transfer"), not a slogan

**Recommended (not blocking):**
- [ ] `## Brand Direction Anchor` section in the product brief (only if *UI*). The heading
      is optional: the user may defer brand direction to `/design-language`, which runs
      DD-BRAND-DIRECTION when the brief has no anchor.
- [ ] Concept prototype `prototypes/*-concept/REPORT.md` with verdict PROCEED
      (`/prototype`) — skipping it means PRDs may be written for a bet nobody has tested.
      Acceptable when the riskiest assumption is proven by other means (interviews,
      a fake door, existing usage data).
- [ ] Stack pinned — `stack.pinned_on` set by `/setup-stack` (the resolved `stack` line
      carries no `pinned_on=unset`)

**Quality Checks:**
- [ ] The brief has been reviewed — a `/prd-review` log in `design/product/reviews/`
      whose latest verdict is not MAJOR REVISION NEEDED
- [ ] A North Star metric and at least one guardrail metric are defined in `## Success Metrics`
- [ ] The target segment is named concretely ("salaried 25–34-year-olds in Korea who
      save toward a goal by manual transfer each payday", not "young people")
- [ ] Each riskiest assumption has a test — a prototype, interviews, a fake door, or data
- [ ] Non-goals are listed (brief `## Non-Goals`, or one-pager `## Scope & Non-Goals`
      at `minimal`)

**Conditions** (resolved by `/gate-check` Phase 1):
- *UI* = `platform.surfaces` ∩ {web, ios, android} ≠ ∅. Unset ⇒ MANUAL CHECK NEEDED
  (ask), never "no UI". Known false ⇒ the Brand Direction Anchor item is reported
  `N/A — UI not configured` and is not scored.

## Workflow tier reductions

The checklist above is the **`full` baseline**. At lower tiers apply the
reduction for the resolved tier. Every item above is named in each tier line
below with its status (required / recommended / dropped / conditional).
Reductions only ever *relax* a requirement — `workflow_overrides` is the
only thing that adds one.

- **`full`** — **required**: product brief with the seven sections; principles
  stated as decision tests; brief reviewed (not MAJOR REVISION NEEDED); North Star
  plus a guardrail metric; concrete target segment; a test for each riskiest
  assumption; non-goals listed in the brief. **Recommended**: Brand Direction Anchor
  (**conditional** — *UI*); concept prototype with PROCEED; stack pinned.
  **Dropped**: the one-pager (the product brief is the record at this tier).
- **`standard`** — **required**: product brief with the seven sections; brief
  reviewed (not MAJOR REVISION NEEDED); North Star plus a guardrail metric; concrete
  target segment; non-goals listed in the brief. **Recommended**: principles stated
  as decision tests; a test for each riskiest assumption; concept prototype with
  PROCEED; stack pinned. **Dropped**: Brand Direction Anchor; the one-pager.
- **`minimal`** — the gate target is **`design/product/one-pager.md`**, not the
  product brief. **Required**: the one-pager exists with `## Pitch`,
  `## Problem & Target User`, `## Core User Journey`, `## Success Signal`,
  `## Scope & Non-Goals`, `## Stack` and `## Build Order` filled (`/brainstorm`
  writes it at this tier); non-goals listed (its `## Scope & Non-Goals`).
  **Recommended**: stack pinned. **Dropped**: the product brief and its seven
  sections; principles stated as decision tests; Brand Direction Anchor; concept
  prototype; brief review; North Star plus a guardrail metric; concrete target
  segment; a test for each riskiest assumption. A one-pager with real content
  under every heading satisfies every required item of this tier.
