> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# PD-PRD-ALIGN — PRD Principles & Value Alignment

Agent: `product-director` | Model tier: Opus | Domain: Product strategy, PRD alignment

**Trigger**: Spawned by `/write-prd` after the PRD for one feature is authored —
every section the resolved workflow tier requires is written — and before the
feature-map row moves from `Drafting` to `In Review`; again after a substantive
revision. It checks that the PRD serves the product principles, the target users'
jobs and the brief's success metrics, adds no scope beyond the brief, and states
Goals & Non-Goals consistent with the brief.

**Context to pass**:
- PRD path
- product brief path (or one-pager path)
- feature-map row for the feature (tier, status)
- brief success metrics

**Prompt**:
> "Review this feature PRD for alignment with the product brief before it goes to
> review. Read the PRD and the brief (or one-pager) at the paths given. Check:
>
> 1. **Principles** — the `> **Implements Principle**:` header names a principle that
>    exists in the brief. No functional requirement, business rule or configuration
>    contradicts a principle or crosses an anti-goal. Example: a Moa
>    `design/prd/goals.md` that adds a 'you missed your deposit' push with a red
>    badge contradicts 'encourage, never shame'.
> 2. **User value** — the persona and job in `## User Value` come from the brief's
>    target users and jobs-to-be-done, and the success moment is something the user
>    would notice ('sees the first automatic deposit land in the goal'), not an
>    internal event.
> 3. **Goals & Non-Goals** — each goal traces to the brief's value proposition or MVP
>    scope; the non-goals do not contradict the brief's non-goals; nothing in scope is
>    something the brief explicitly excludes.
> 4. **Scope against the tier** — the requirements match the feature-map tier. An
>    MVP-tier PRD that specifies shared family goals, or custom deposit schedules the
>    feature map places in `Later`, is scope creep even if every line is well
>    written.
> 5. **Success metrics** — `## Success Metrics & Instrumentation` names at least one
>    metric that moves a brief success metric (the North Star or a guardrail) with a
>    baseline and a target. Vanity counts (page views, sign-ups without activation)
>    do not qualify. Guardrails the feature could hurt are named (for Moa `payments`:
>    auto-debit failure rate, refund requests, unsubscribe rate).
> 6. **Status consistency** — the PRD `> **Status**:` and the feature-map row status
>    agree (`Draft` ↔ `Drafting`, `In Review` ↔ `In Review`, `Needs Revision` ↔
>    `Needs Revision`, `Approved` ↔ `Approved`, `Implemented` ↔ `Implemented`).
>
> Return APPROVE (the PRD serves the brief), CONCERNS [the specific sections with
> issues and the fix for each], or REJECT [principle violations or scope beyond the
> brief that must be redesigned before this feature is implementable]."

**Verdicts**: APPROVE / CONCERNS / REJECT

The first line of the reply is exactly `[PD-PRD-ALIGN]: <TOKEN>` with one token from
the line above; the spawning skill parses it. Findings follow the first line.

**Special handling**:
- At the `standard` workflow tier `## User Value` and `## Configuration & Flags` are
  advisory: their absence is a CONCERNS item at most, never grounds for REJECT.
  Judge the sections the tier requires; do not re-run the structural check
  (`/prd-review` owns section completeness).
- A PRD compared against a one-pager (a PRD written voluntarily at `minimal`) is
  checked against `## Problem & Target User`, `## Core User Journey`,
  `## Success Signal` and `## Scope & Non-Goals` instead of the brief sections.
- A missing brief success metric is a finding against the brief, not the PRD: report
  it and note that item 5 is `NOT CHECKED — brief has no success metrics`.
