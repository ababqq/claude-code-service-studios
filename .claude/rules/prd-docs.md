---
paths:
  - "design/prd/**"
  - "design/product/**"
---

# PRD and Product Document Rules

## PRDs (`design/prd/<feature-slug>.md`)

- Start every PRD from `.claude/docs/templates/prd.md`: the header block (`> **Status**:`, `> **Owner**:`,
  `> **Last Updated**:`, `> **Last Verified**:`, `> **Implements Principle**:`, `> **Feature Map Tier**:`), then
  `## Summary` with its `> **Quick reference**` line, then the eleven contract sections in this order and with this
  exact heading text: Overview, Goals & Non-Goals, User Value, Functional Requirements, Business Rules & Calculations,
  Edge Cases, Dependencies, Non-Functional Requirements, Configuration & Flags, Success Metrics & Instrumentation,
  Acceptance Criteria. `## UI Requirements`, `## API & Data Impact` and `## Open Questions` are optional and never
  checked.
- **Headings are contracts.** `prd-structure-check.sh`, the commit hook, `/write-prd`, `/prd-review` and the phase
  gates match them (case-insensitive, prefix, optional `3. ` or `3) ` numbering). Never translate, rename, merge or
  reorder one; write the body in the conversation language.
- **How many sections are required depends on the workflow tier** — the feature's
  `workflow_overrides.feature_overrides.<slug>` value when set, else `modes.workflow`:
  - `full` — all eleven.
  - `standard` — eight: Overview, Goals & Non-Goals, Functional Requirements, Edge Cases, Dependencies,
    Non-Functional Requirements, Success Metrics & Instrumentation, Acceptance Criteria; plus Business Rules &
    Calculations when the feature defines a numeric or policy rule. User Value and Configuration & Flags are
    advisory (`workflow_overrides.config_flags: true` makes Configuration & Flags required).
  - `minimal` — none; `design/product/one-pager.md` is the design record. A PRD written voluntarily requires Edge
    Cases only when `workflow_overrides.edge_cases: true`.
  Resolve the tier before calling a section missing — see `.claude/docs/workflow-modes.md`.
- **Business rules are decided by content, not by the feature's category.** Any price, fee, limit, quota, rate limit,
  eligibility threshold, time window or rounding anywhere in the PRD makes `## Business Rules & Calculations`
  required at `standard`. Each rule has a named expression, a variable table
  (`| Symbol | Type | Unit | Range | Source | Description |`), rounding, output range, a worked example with real
  numbers and boundary cases. Money is integer KRW (no minor unit) unless the PRD says otherwise, and every price
  says whether VAT is included.
- Business values are configuration, not code: every limit, price and time window is either a registry constant or a
  `## Configuration & Flags` entry with its safe range.
- Edge cases state the exact condition and the exact outcome — "handle gracefully" is not a specification — and cover
  network loss, partial failure, concurrency, retries and duplicate webhook delivery.
- `## Dependencies` uses the exact table `| Feature | PRD | Direction | Nature |` with `design/prd/<slug>.md` paths and
  `Direction` ∈ `depends on | depended on by`. Dependencies are bidirectional: when `goals` depends on `auth`,
  `design/prd/auth.md` lists `goals` as `depended on by`. Third parties go under `### External Services`.
- `## Non-Functional Requirements` names performance, availability, security & privacy (PII fields, authorization per
  operation, retention) and accessibility needs with numbers or named standards — never "fast" or "secure".
- `## Success Metrics & Instrumentation` names at least one metric with a baseline and a target; an unknown baseline
  is `NOT DETERMINED — <reason>`, never an invented number.
- Acceptance criteria are Given/When/Then and testable by someone who has not read the PRD; they include at least one
  negative case and one authorization case.
- No hand-waving: "intuitive", "seamless" and "delightful" are not requirements.
- PRD `> **Status**:` and the feature-map row move together: `Draft` ↔ `Drafting`; `In Review`, `Needs Revision`,
  `Approved` and `Implemented` are the same word on both sides.
- File name is the feature slug, kebab-case, no `-prd` suffix. Only PRDs live at the top of `design/prd/`; review logs
  go in `design/prd/reviews/`.
- Write PRDs incrementally: create the skeleton first, then fill one section at a time with approval between
  sections, writing each approved section to the file immediately so decisions survive a lost session.
- After a PRD is `Approved`, a change goes through `/propagate-prd-change` so affected ADRs, API operations, data-model
  entities, tracking events and stories are found.

## Glossary registry (`design/registry/entities.yaml`)

- A domain term, plan, rule, constant or event that appears in more than one PRD is registered, with `source:` = the
  owning PRD path. Read the registry before naming or quantifying one, and use the registered value.
- Never contradict a registered value silently: surface the conflict and name the PRDs in `referenced_by:`.
- Never delete an entry — set `status: deprecated`. Keep the grep contract: entries start with two spaces and
  `- name:`, `referenced_by:` is a block list.

## Product documents (`design/product/`)

- The product brief (`product-brief.md`), one-pager (`one-pager.md`), feature map (`feature-map.md`), tracking plan
  (`tracking-plan.md`) and pricing model (`pricing-model.md`) keep their template headings exactly — templates live
  in `.claude/docs/templates/`. Review logs for the brief go in `design/product/reviews/`.
- The feature map's main table header is exactly `| Feature | Category | Layer | Tier | Status | PRD | Depends On |`;
  Layer ∈ `Foundation | Core | Feature | Presentation`; Tier ∈ `MVP | Beta | GA | Later`; Status ∈
  `Not Started | Drafting | In Review | Needs Revision | Approved | Implemented`. Never add a column.
- Every analytics event a PRD introduces is appended to `tracking-plan.md` with the PRD as `Owner PRD`; events are
  deprecated there, never deleted. Personal data in an event is marked in the `PII` column with its consent basis.
- Plans, prices, credits and promotions a PRD defines are recorded in `pricing-model.md` and in the registry's
  `plans` and `constants` sections.
