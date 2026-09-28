# [Feature Name]

> **Status**: Draft | In Review | Needs Revision | Approved | Implemented
> **Owner**: [role or person]
> **Last Updated**: [YYYY-MM-DD]
> **Last Verified**: [YYYY-MM-DD — when this doc was last confirmed accurate]
> **Implements Principle**: [product principle from the brief]
> **Feature Map Tier**: MVP | Beta | GA | Later

## Summary

[2–3 sentences: what this feature is, what it does for the user, and why it exists. Written for tiered context
loading — a skill scanning 20 PRDs uses this section to decide whether to read further.]

> **Quick reference** — Layer: `[Foundation | Core | Feature | Presentation]` · Tier: `[MVP | Beta | GA | Later]` · Key deps: `[feature slugs or "None"]`

<!--
TEMPLATE NOTES — delete this comment block in a real PRD.

File: design/prd/<feature-slug>.md (kebab-case, no "-prd" suffix). The slug is the PRD
stem, the feature-map Feature value, the workflow_overrides.feature_overrides key, the
TR-<slug>-NNN prefix and the **PRD**: field of stories. Example used below: Moa, a
Korean B2C subscription savings app; feature "goals" (savings goals), file
design/prd/goals.md.

Contract: the eleven sections from Overview to Acceptance Criteria are matched by
.claude/scripts/prd-structure-check.sh, the commit hook, /write-prd, /prd-review and
the phase gates. Keep every heading exactly as spelled here, in this order. Never
translate, rename or merge one; a numeric prefix ("3. " or "3) ") is tolerated.
Write the body text in the team's conversation language.

Required sections per workflow tier (modes.workflow, or
workflow_overrides.feature_overrides.<slug> for this feature):
  full     - all eleven.
  standard - eight required: Overview, Goals & Non-Goals, Functional Requirements,
             Edge Cases, Dependencies, Non-Functional Requirements,
             Success Metrics & Instrumentation, Acceptance Criteria.
             Business Rules & Calculations is required whenever the feature defines
             any numeric or policy rule (prices, fees, limits, quotas, rate limits,
             eligibility thresholds, time windows, rounding) - the content decides,
             never the feature's category.
             Advisory: User Value, Configuration & Flags
             (workflow_overrides.config_flags: true makes Configuration & Flags required).
  minimal  - none; design/product/one-pager.md is the design record. A PRD written
             voluntarily requires Edge Cases only when workflow_overrides.edge_cases is true.
A section the tier does not require keeps its heading with a one-line note saying why
it was not authored - never an empty body, never a deleted heading.

UI Requirements, API & Data Impact and Open Questions are never required and never
checked; they follow the contract block.

Status mirrors the feature-map row 1:1: Draft <-> Drafting, In Review, Needs Revision,
Approved and Implemented carry the same word on both sides; "Not Started" in the
feature map means no PRD exists yet.
-->

## Overview

[One paragraph a new team member can read cold: what the feature is, who uses it, what it does for them and why the
product needs it. Behaviour, not implementation — "which queue or framework" questions become ADRs, noted here as
"→ ADR" and left for `/architecture-decision`.

Example (goals): Savings goals let a Moa user name something they are saving for, set a target amount and date, and
have Moa move money toward it automatically. It is the reason the product exists: without goals, auto-debit is a
transfer with no purpose and the user has no progress to come back to.]

## Goals & Non-Goals

### Goals

[Each goal traces to the brief's value proposition, MVP scope or a success metric. State outcomes, not features.

- Example: A new user can create a first goal and authorise its automatic deposit in one session.
- Example: Users see their progress without doing arithmetic — every goal shows saved amount, percentage and the
  projected completion date.]

### Non-Goals

[Explicitly out of scope for this PRD (Korean teams: 제외 범위). `/scope-check` compares delivered work against this
list, so name concrete capabilities, and say where each one lives instead (a later tier, another PRD, never).

- Example: Shared family goals — `Later` tier, a separate PRD.
- Example: Custom deposit schedules beyond weekly and daily — `Later`.
- Example: Investment products of any kind — never (anti-goal in the brief).]

## User Value

[Who this is for and what job it does, from the brief's target users and jobs-to-be-done — never invented here.

**Persona**: [name or segment from `design/product/personas/` or the brief — e.g. "first-jobber saving for a
deposit on a jeonse flat"]

**Job-to-be-Done**: When [situation], I want to [motivation], so I can [expected outcome].
Example: When I get paid, I want part of my salary to move into savings before I spend it, so I can reach my target
without relying on willpower.

**User stories**:
- As a [persona], I want [capability] so that [benefit].

**Success moment**: [the moment the user notices the value — observable, not an internal event. Example: "sees the
first automatic deposit land in the goal and the progress ring move".]]

## Functional Requirements

### Core Rules

[Numbered, one observable behaviour per item, precise enough to implement and test without questions.
`/architecture-review` traces each item to a TR-ID (`TR-goals-001`, …). Policy detail — limits, fees, eligibility,
calculations — lives in Business Rules & Calculations and is referenced here by name.

1. Example: A signed-in user can create a goal with a name (1–30 characters), a target amount and a target date.
2. Example: Creating a goal is blocked when the user already holds the plan's maximum number of active goals
   (rule `active_goal_limit`).
3. Example: The user can pause an active goal; paused goals skip scheduled auto-debits until resumed.]

### User Flows & States

[Every flow step by step, and every state the feature can be in with its valid transitions. For each screen name
the loading, empty, error, offline, permission-denied and signed-out states; for API-only capabilities name the
error responses instead. Link the UX spec (`design/ux/<slug>.md`) rather than describing layout.]

| State | Entry Condition | Exit Condition | What the User Sees |
|-------|-----------------|----------------|--------------------|
| [e.g. `active`] | [goal created and first debit authorised] | [paused, completed or deleted] | [progress ring, next debit date] |
| [e.g. `paused`] | [user pauses] | [user resumes or deletes] | [paused badge, no upcoming debit] |
| [e.g. `completed`] | [saved amount reaches target] | [user archives] | [completion screen] |

### Interactions with Other Features

[For each dependency in both directions: what data or event flows in, what flows out, and which feature owns it.
Example: goals reads the user's entitlements from `subscription`; `payments` publishes `payment_settled`, and goals
updates progress from it — goals never writes a payment record.]

## Business Rules & Calculations

[Every numeric or policy rule: prices, fees, limits, quotas, rate limits, eligibility thresholds, time windows,
rounding. For each rule: a named expression, the variable table, rounding, output range, a worked example with real
numbers, and boundary cases. Values that appear in more than one PRD are registered in
`design/registry/entities.yaml` (`plans`, `rules`, `constants`) and cited by name. Plans, prices, credits and
promotions are also recorded in `design/product/pricing-model.md`.]

**Rule: [rule name — e.g. `suggested_debit_amount`]**

```
suggested_debit_amount = ceil((target_amount - saved_amount) / remaining_debits / 10) × 10
```

| Symbol | Type | Unit | Range | Source | Description |
|--------|------|------|-------|--------|-------------|
| target_amount | int | KRW | 10,000–100,000,000 | user input | amount the user wants to save |
| saved_amount | int | KRW | 0–target_amount | derived | sum of settled deposits into this goal |
| remaining_debits | int | debits | 1–520 | derived | scheduled debit dates from the next one up to the target date (Asia/Seoul) |
| suggested_debit_amount | int | KRW | 0–target_amount | derived | amount proposed per debit |

- **Rounding**: up to the nearest KRW 10, applied once to the result (KRW has no minor unit).
- **Output range**: 10 KRW to `target_amount` while the goal is open; clamped to 0 once the target is reached.
- **Example**: target 1,000,000 KRW, saved 250,000 KRW, 26 weekly debits left → 750,000 / 26 = 28,846.15 →
  **28,850 KRW**.
- **Boundary cases**: no debit date left before the target date → no suggestion, and the user is asked to extend the
  date; saved amount at or above the target → 0 and the goal completes.

**Rule: [policy rule name — e.g. `active_goal_limit`]** — policy rules use the same shape, with a decision table
where a formula does not fit:

| Plan | Active goal limit | Source |
|------|-------------------|--------|
| Free | `free_active_goal_limit` (registry constant) | `design/registry/entities.yaml` |
| Plus | unlimited | `design/product/pricing-model.md` |

## Edge Cases

[Each case names the exact condition and the exact outcome — "handle gracefully" is not a specification. Include the
failure modes of a networked service: network loss, partial failure, concurrency, retries, duplicate delivery,
time-zone and calendar boundaries, plan changes mid-period, account deletion.]

| Scenario | Expected Behavior | Rationale |
|----------|-------------------|-----------|
| [e.g. the payment provider delivers the same `payment_settled` webhook twice] | [progress updates once; the second delivery is acknowledged and ignored (idempotency key = the provider's payment key)] | [providers deliver at least once] |
| [e.g. the auto-debit fails for insufficient balance] | [goal stays `active`; one retry the next business day; an encouraging message, no red badge] | [principle "encourage, never shame"] |
| [e.g. the user downgrades from Plus to Free while holding more active goals than Free allows] | [existing goals stay active; creating a new goal is blocked until the count is under the limit] | [never take away progress the user already has] |
| [e.g. the app loses network while creating a goal] | [the client retries with the same idempotency key; no duplicate goal] | [mobile networks drop requests mid-flight] |

## Dependencies

[Every feature this one depends on or that depends on it, as PRD paths. Dependencies are bidirectional: when this
PRD says it depends on `auth`, `design/prd/auth.md` lists this feature as `depended on by`. Keep the exact header —
tools extract the `design/prd/*.md` paths from this table. `Direction` is `depends on` or `depended on by`; `Nature`
starts with `hard` (cannot work without it) or `soft` (degrades without it), then says what flows.]

| Feature | PRD | Direction | Nature |
|---|---|---|---|
| auth | `design/prd/auth.md` | depends on | hard — sign-in required |
| payments | `design/prd/payments.md` | depends on | hard — creates the auto-debit mandate; progress comes from `payment_settled` |
| notifications | `design/prd/notifications.md` | depends on | soft — milestone and failed-debit messages |
| onboarding | `design/prd/onboarding.md` | depended on by | hard — onboarding ends by creating the first goal |

### External Services

[Third parties this feature relies on — not parsed by any tool.]

| Service | Used For | Failure Mode | Owning Feature |
|---------|----------|--------------|----------------|
| [e.g. Toss Payments] | [auto-debit (billing key) and settlement webhooks] | [webhook delayed or duplicated; debit declined] | [payments] |

## Non-Functional Requirements

[Measurable needs this feature adds on top of the product-wide SLOs. Every item gets a number or a named standard;
"fast" and "secure" are not requirements.]

### Performance

[e.g. goal list API p95 ≤ 300 ms at 1,000 req/s; goals screen LCP ≤ 2.5 s (p75) on a mid-range Android device over 4G.
Cite `performance.*` budgets in `project.yaml` where they apply.]

### Availability & Reliability

[e.g. goal creation available 99.9 % monthly; a failed debit is retried and never double-charged.]

### Security & Privacy

[PII fields and their classification, authorization rules per operation (a user can only read and change their own
goals — acting on another user's goal returns 404, not 403), retention and deletion (goals are deleted with the
account), audit needs, and the consent basis for each personal-data use.]

### Accessibility

[Target from `accessibility.target` (e.g. WCAG 2.2 AA; KWCAG 2.2 for Korea): screen-reader labels for the progress
ring, target sizes, contrast of progress colours, reduced motion for celebrations.]

### Localization

[Locales from `localization.locales` (e.g. `ko-KR`, `en-US`); KRW formatting, Asia/Seoul dates, pluralization and
text-length limits for goal names.]

## Configuration & Flags

[Everything operations or product can change without a code change, with safe ranges and what breaks at the extremes.
Business values come from config or flags — never hardcoded.]

### Feature Flags

| Flag | Default | Owner | Removal Date | Purpose |
|------|---------|-------|--------------|---------|
| [e.g. `goals.v2-progress-ring`] | [off] | [product-manager] | [YYYY-MM-DD] | [progressive rollout of the new progress ring] |

### Config Values & Limits

| Key | Value | Safe Range | Owner | Effect of Increase | Effect of Decrease |
|-----|-------|------------|-------|--------------------|--------------------|
| [e.g. `goals.debit_retry_delay_hours`] | [24] | [12–72] | [payments on-call] | [slower recovery of missed deposits] | [more declines on the same empty account] |

## Success Metrics & Instrumentation

[The metric(s) this feature moves, tied to the brief's North Star or guardrails, each with a baseline and a target —
`NOT DETERMINED — <reason>` until a baseline is measured, never an invented number. Event names follow
`naming.events` in `project.yaml`; after this section is approved the events are appended to
`design/product/tracking-plan.md` with this PRD as their `Owner PRD`.]

### Metrics

| Metric | Type | Baseline | Target | Window | Source |
|--------|------|----------|--------|--------|--------|
| [e.g. share of new users with a funded goal within 7 days] | [primary] | [NOT DETERMINED — no data before launch] | [40 %] | [7 days after sign-up] | [warehouse model] |
| [e.g. auto-debit failure rate] | [guardrail] | [—] | [≤ 3 %] | [weekly] | [payments dashboard] |

### Events

| Event | Trigger | Properties | PII |
|-------|---------|------------|-----|
| [e.g. `goal_created`] | [server commits a new goal] | [goal_id, target_amount_krw, target_date, source] | [No] |
| [e.g. `goal_limit_reached`] | [creation blocked by `active_goal_limit`] | [plan, active_goal_count] | [No] |

### Dashboards

[Where the metrics are watched and who watches them.]

## Acceptance Criteria

[Given/When/Then, one behaviour per criterion, observable from outside the code and testable by someone who has not
read this PRD. At least one criterion per core rule and per business rule, at least one negative case and one
authorization case. Criteria that need a deployed environment say which one (staging).]

- [ ] **GIVEN** a Free-plan user with fewer active goals than `free_active_goal_limit`, **WHEN** they submit a valid
      goal, **THEN** the goal is created with status `active` and `goal_created` is recorded once.
- [ ] **GIVEN** a Free-plan user at `free_active_goal_limit`, **WHEN** they submit a new goal, **THEN** no goal is
      created, the Plus upgrade sheet is shown and `goal_limit_reached` is recorded with `plan=free`.
- [ ] **GIVEN** user A signed in, **WHEN** A requests user B's goal by ID, **THEN** the API returns 404 and reveals
      nothing about the goal.
- [ ] **GIVEN** the same `payment_settled` webhook delivered twice (staging), **WHEN** both are processed, **THEN**
      the goal's saved amount increases once.

## UI Requirements

[Screens and components this feature adds or changes, the states each must show, and the UX spec that will define
them (`design/ux/<slug>.md`, written with `/ux-design`). Name what the user must see and when — layout belongs to the
UX spec.]

| Screen / Component | States | UX Spec |
|--------------------|--------|---------|
| [e.g. Goal detail] | [loading, active, paused, completed, error, offline] | [`design/ux/goal-detail.md`] |

## API & Data Impact

[Operations, entities, events and migrations this feature introduces or changes — the input `/api-design` and
`/data-model` start from. Name them; the contract itself lives in `docs/api/`.]

- **Operations**: [e.g. `POST /goals`, `GET /goals`, `PATCH /goals/{goalId}` (pause/resume)]
- **Entities owned**: [e.g. `Goal` — owned by goals; `Deposit` is read from payments events, never written here]
- **Events published / consumed**: [e.g. publishes `goal_completed`; consumes `payment_settled`]
- **Migrations**: [e.g. new `goals` table; no change to existing tables]

## Open Questions

[Anything not yet decided. Each question has an owner and a deadline.]

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|------------|
