> Gate definition, loaded by `/gate-check` for the TARGET PHASE ONLY.
> Never load the other five — one gate applies per invocation.


# Gate: Definition → Architecture


**Required Artifacts:**
- [ ] Feature map exists at `design/product/feature-map.md` with at least the MVP
      features enumerated — main table header
      `| Feature | Category | Layer | Tier | Status | PRD | Depends On |`, with the MVP
      features on rows whose Tier is `MVP`
- [ ] Every MVP-tier feature has a PRD at `design/prd/<feature>.md` and a `/prd-review`
      log at `design/prd/reviews/<feature>-review-log.md` whose latest verdict is not
      MAJOR REVISION NEEDED
- [ ] A cross-PRD review report `design/prd/reviews/prd-cross-review-*.md` exists
      (from `/review-all-prds`)
- [ ] Stack pinned — `stack.pinned_on` set by `/setup-stack`. Only the configured
      layers count: data and cloud layers may stay unset until their Foundation ADRs
      are accepted (`/setup-stack refresh` records them then)

**Recommended (not blocking):**
- [ ] (none at the `full` baseline — the `standard` line below moves items here)

**Quality Checks:**
- [ ] Every MVP PRD contains the required sections of its effective tier — run
      `bash .claude/scripts/prd-structure-check.sh` and apply the tier per PRD
      (`workflow_overrides.feature_overrides.<feature>` when set, else the project
      tier): `full` = all 11 contract sections; `standard` = the 8 required sections
      plus `## Business Rules & Calculations` whenever the feature defines a numeric
      or policy rule (prices, fees, limits, quotas, rate limits, eligibility
      thresholds, time windows, rounding)
- [ ] The `/review-all-prds` verdict is not FAIL, and every issue it flagged is
      resolved or explicitly accepted
- [ ] Feature dependencies are bidirectionally consistent — the feature map's
      `Depends On` column and each PRD's `## Dependencies` table
      (`| Feature | PRD | Direction | Nature |`) agree in both directions
- [ ] The MVP tier is defined, and no stale PRD references are flagged (earlier PRDs
      updated to reflect decisions made in later ones)
- [ ] Every MVP PRD's `## Non-Functional Requirements` names its performance,
      availability, security & privacy and accessibility needs
- [ ] Every MVP PRD's `## Success Metrics & Instrumentation` has at least one metric
      with a baseline and a target
- [ ] Every `workflow_overrides.feature_overrides.<stem>` key matches a
      `design/prd/<stem>.md` — an orphan key is CONCERNS, naming the key and the
      stems that exist (checked at this gate and at every later gate)

## Workflow tier reductions

The checklist above is the **`full` baseline**. At lower tiers apply the
reduction for the resolved tier. Every item above is named in each tier line
below with its status (required / recommended / dropped / conditional).
Reductions only ever *relax* a requirement — `workflow_overrides` is the
only thing that adds one.

- **`full`** — **required**: feature map with the MVP features; every MVP PRD
  with a `/prd-review` log not ending in MAJOR REVISION NEEDED; cross-PRD review
  report; stack pinned; all 11 PRD sections per PRD; `/review-all-prds` not FAIL
  with flagged issues resolved or accepted; bidirectional dependencies; MVP tier
  defined with no stale references; NFRs named in every MVP PRD; at least one
  metric with baseline and target per MVP PRD; no orphan `feature_overrides` key.
  Nothing is recommended or dropped at this tier.
- **`standard`** — **required**: feature map with the MVP features; every MVP PRD
  with a `/prd-review` log not ending in MAJOR REVISION NEEDED; stack pinned; the
  8 standard PRD sections per PRD (+ `## Business Rules & Calculations`,
  **conditional** on the feature defining a numeric or policy rule); bidirectional
  dependencies; MVP tier defined with no stale references; NFRs named in every MVP
  PRD; at least one metric with baseline and target per MVP PRD; no orphan
  `feature_overrides` key. **Recommended**: cross-PRD review report;
  `/review-all-prds` not FAIL with flagged issues resolved or accepted (checked only
  when a report exists). Nothing is dropped.
- **`minimal`** — **gate not applicable** — no gate between the one-pager and the
  architecture; every item above is **dropped** (feature map, MVP PRDs and their
  review logs, cross-PRD review report, stack pinned, PRD sections, the
  `/review-all-prds` verdict, bidirectional dependencies, MVP tier and stale
  references, NFRs, success metrics, orphan `feature_overrides` keys). PASS with a
  note (see below).

> **`minimal` "not applicable" gate.** The Definition → Architecture gate has no
> meaning at `minimal` (no feature map or PRDs exist by design). Return a PASS
> verdict with the note: *"No definition gate at minimal workflow — the one-pager
> is the design record; advancing brief → architecture."* The Section 6 stage write
> still applies on user confirmation. Do NOT flag absent PRDs as blockers.
