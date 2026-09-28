---
name: review-all-prds
description: "Holistic cross-PRD review: contradictions, conflicting limits/metrics, cognitive load, principle drift."
argument-hint: "[full | consistency | product-theory | since-last-review]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/review-all-prds/../../hooks/yaml-helper.sh" resolve_config *)
model: opus
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow,feature_overrides`

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).


# Review All PRDs

This skill reads every feature PRD together and performs reviews that cannot be done one PRD at a time:

1. **Cross-PRD Consistency** — dependencies that point one way only, rule contradictions, conflicting limits,
   prices and metric definitions, stale references, and two PRDs claiming the same flag or config value.
2. **Product Holism** — problems that only appear when all features are seen at once: features that deliver no
   stated principle, cognitive load that piles up across flows, business rules that can be exploited together, a credits
   or pricing economy that does not balance, and scope that drifts past the brief's anti-goals or another PRD's
   non-goals.
3. **Cross-Feature Scenarios** — walking a real user moment through every feature it touches, to find undefined
   behaviour at the boundaries.

**This is distinct from `/prd-review`**, which reviews one PRD for completeness and implementability, and from
`/consistency-check`, which scans PRDs against the glossary registry value by value. This skill reviews the
*relationships* between PRDs.

**When to run:**
- After all MVP-tier PRDs are individually approved (`/prd-review`)
- After any PRD is significantly revised once implementation has started (`since-last-review`)
- Before `/create-architecture` begins — an architecture built on inconsistent PRDs inherits the inconsistencies

**Output:** `design/prd/reviews/prd-cross-review-YYYY-MM-DD.md` — the report the Definition → Architecture gate looks
for (required at `full`, recommended at `standard`). Verdicts: **PASS** / **CONCERNS** / **FAIL** / **NOT ASSESSED**.

**Language.** The report's headings, table headers and verdict tokens stay in English exactly as written in Phase 5;
the findings are written in the user's conversation language.

**Argument modes:**

**Focus:** `$ARGUMENTS[0]` (blank = `full`)

- **No argument / `full`**: consistency, product holism and scenario walkthroughs
- **`consistency`**: Cross-PRD consistency checks only (Phase 2 — faster)
- **`product-theory`**: Product holism checks only (Phase 3)
- **`since-last-review`**: only the PRDs changed since the last cross-PRD review, plus every PRD on either end of
  their dependency edges (Phase 1a)

A focused run names the phases it did not run in its report — a `consistency` report is not a full cross-review, and
says so.

---

**`workflow`** per PRD (per `.claude/docs/workflow-modes.md`): each PRD is validated against its effective tier — the
project value, overridden per feature by the `feature_overrides` row for that PRD's stem when the block lists one.

- **`full`** — all eleven contract sections are expected in every PRD; a missing one that a check needs is reported.
- **`standard`** — the eight required sections (Overview, Goals & Non-Goals, Functional Requirements, Edge Cases,
  Dependencies, Non-Functional Requirements, Success Metrics & Instrumentation, Acceptance Criteria) plus Business
  Rules & Calculations when the feature defines a numeric or policy rule; User Value and Configuration & Flags are
  advisory, so their absence is surfaced as advisory only.
- **`minimal`** — PRDs are not expected (the one-pager is the design record) and this skill is not applicable. If two
  or more PRDs were written voluntarily, review them with every section check advisory, and say so in the report.

## Phase 1: Load Everything

### Phase 1a — L0: Summary Scan (fast, low tokens)

**Establish the denominator first:** `Glob` `design/prd/*.md` and count **N**. Only files directly under
`design/prd/` are PRDs — review logs and earlier cross-reviews live in `design/prd/reviews/` and are never in the
review set; drop any match under `reviews/` that a `Grep` glob returns.

Before reading any full document, use Grep to extract the `## Summary` sections:

```
Grep pattern="^##+\s+([0-9]+[.)]\s+)?Summary" glob="design/prd/*.md" output_mode="content" -A 5
```

**Fail open on a missing Summary.** A scan matching fewer than N means those PRDs predate `## Summary` — never treat
an absent Summary as a feature out of scope. A zero-match scan means "no PRD carries a Summary yet", not "nothing to
review". This review is holistic and loads its in-scope PRDs regardless (Phase 1c); the Summary scan only builds the
manifest and narrows `since-last-review`, it never shrinks the review set.

Display a manifest to the user:
```
Found [N] PRDs. Summaries:
  • auth.md — [summary text]
  • goals.md — [summary text]
  ...
```

For `since-last-review` mode, compute the scope deterministically instead of reasoning through git history:

```
Bash: bash .claude/scripts/review-scope.sh since-last-review
```

It prints `PRIOR_REVIEW:`, a `CHANGED:` list, and a `DEPS` list of dependency edges in both directions:
`auth.md -> design/prd/x.md` (the changed PRD names x.md in its `## Dependencies`) and
`auth.md <- design/prd/goals.md` (goals.md names the changed PRD). The in-scope set is every existing `CHANGED` PRD
plus every PRD named on a `DEPS` line — both directions, because the PRD that depends on a changed one is the one most
likely to be stale now. A `CHANGED` path marked `(deleted)` is itself a finding: every PRD on its `<-` lines now holds
a stale reference. A `-> … (not found)` edge is a stale reference too. If `PRIOR_REVIEW: NONE`, a full review is
required; fall back to `full` mode and say so.

Show the user which PRDs are in scope before doing any full reads.

### Phase 1b — Registry Pre-Load (fast baseline)

Before full-reading any PRD, check the glossary registry:

```
Read path="design/registry/entities.yaml"
```

If it exists and has entries, use it as a **pre-built conflict baseline**: known entities, plans, rules, constants
and events, each with its authoritative value and its owning PRD (`source:`). In Phase 2, grep PRDs for registered
names first — this is faster than reading every PRD in full before knowing what to look for.

If the registry is empty or absent: proceed without it, and note in the report: "Glossary registry is empty —
consistency checks rely on PRD reads only. Run `/consistency-check` after this review to add cross-PRD facts to the
registry."

### Phase 1c — L1/L2: Section Load

Read whole (small, and every part is used), when they exist:

1. `design/product/product-brief.md` — principles and anti-goals, success metrics (North Star and guardrails), MVP
   scope, non-goals (at `minimal`: `design/product/one-pager.md`)
2. `design/product/feature-map.md` — the authoritative feature list, layers, tiers, statuses and dependencies
3. `design/product/tracking-plan.md` — which PRD owns which event
4. `design/product/pricing-model.md` — plans, prices, entitlements, credits
5. `design/product/user-journey.md` — the lifecycle stages and moments of value the scenario walkthroughs follow

Then, for **every in-scope PRD**, load the sections this review actually consumes — **not the whole file**:

```
Grep pattern="^##+\s+([0-9]+[.)]\s+)?(Goals & Non-Goals|User Value|Functional Requirements|Business Rules & Calculations|Dependencies|Non-Functional Requirements|Configuration & Flags|Success Metrics & Instrumentation|Acceptance Criteria)" glob="design/prd/*.md" output_mode="content" -A 40
```

That list is not a guess — it is exactly the union the Parallel Execution contract below enumerates: Phase 2 needs
Dependencies, Functional Requirements, Business Rules & Calculations, Non-Functional Requirements, Configuration &
Flags, Success Metrics & Instrumentation and Acceptance Criteria; Phase 3 needs User Value, Goals & Non-Goals,
Functional Requirements, Business Rules & Calculations and Success Metrics & Instrumentation. Overview is restated by
the Summary already scanned in Phase 1a, and Edge Cases feeds no checklist item here (`/prd-review` owns per-PRD
completeness); Phase 4 reads a PRD's Edge Cases only when a scenario turns on it. Loading more puts content in three
context windows — this one and both sub-agents' — that no checklist item reads.

**Escalate to a full read of one PRD** when a scanned section cross-references material outside itself, when a
section runs past the 40-line window, or when a PRD matched **zero** sections — that PRD predates the template, and a
zero-match there means "unstructured", not "empty". Never let a zero-match silently drop a feature: the scan narrows
the *read*, it never shrinks the *review set*.

Report: "Loaded [N] PRDs covering [M] features. Principles: [list]. Anti-goals: [list]."

If fewer than 2 PRDs exist, stop with **NOT ASSESSED** and write no report:
> "Cross-PRD review requires at least 2 PRDs. Write more PRDs first (`/write-prd <feature>`), then re-run
> `/review-all-prds`."

No report is written in that case: a report file is what the Definition → Architecture gate looks for, and a review
that compared nothing must not satisfy it.

---

### Parallel Execution

Phase 2 (Consistency) and Phase 3 (Product Holism) are independent — they read the same PRD inputs but produce
separate findings. Spawn both as parallel `Agent` calls simultaneously rather than waiting for Phase 2 to finish
before starting Phase 3. Collect both results before Phase 4 and the report.

Spawn both as `product-manager` sub-agents (`subagent_type: product-manager`) — cross-PRD consistency and product
coherence are that role's domain.

**When spawning the Phase 2 and Phase 3 agents, always pass:**
- The loaded PRD **content** each phase needs — **not file paths**. Paste the sections; the sub-agent has its own
  context and cannot see Phase 1's results, so a path forces a full re-read (and contradicts the "do not re-read"
  rule below). Pass only the phase's slice: Phase 2 needs each PRD's Dependencies, Functional Requirements, Business
  Rules & Calculations, Non-Functional Requirements, Configuration & Flags, Success Metrics & Instrumentation and
  Acceptance Criteria, plus the pricing-model and tracking-plan rows; Phase 3 needs each PRD's User Value, Goals &
  Non-Goals, Functional Requirements, Business Rules & Calculations and Success Metrics & Instrumentation, plus the
  brief's principles, anti-goals, non-goals, success metrics and MVP scope, and the user-journey stages.
- The full registry contents if loaded in Phase 1b (paste the registry text, not the path).
- The feature-map rows (feature, layer, tier, status, depends on).
- The checklist items assigned to that phase (Phase 2 gets 2a–2f; Phase 3 gets 3a–3f).
- The instruction to return findings in the Phase 5 shapes, each citing the PRD, section and text involved.

Do not rely on a sub-agent to re-read these files — it has its own context window and cannot access Phase 1 results
unless they are explicitly passed in the `Agent` prompt.

---

## Phase 2: Cross-PRD Consistency

Work through every pair and group of PRDs to find contradictions and gaps.

### 2a: Dependency Bidirectionality

Each PRD's `## Dependencies` table has a `Direction` column (`depends on` / `depended on by`). For every row, check
that the other PRD lists the reverse edge:
- If goals.md lists `design/prd/auth.md` as `depends on`, auth.md must list goals.md as `depended on by`.
- If goals.md lists `design/prd/notifications.md` as `depended on by`, notifications.md must list goals.md as
  `depends on`.
- The feature map's `Depends On` column must agree with both.

```
⚠️  Dependency Asymmetry
goals.md lists: depends on → design/prd/payments.md
payments.md does NOT list goals.md as depended on by
→ One of these documents has a stale Dependencies section
```

### 2b: Rule Contradictions

For each rule, constraint or behaviour defined in any PRD, check whether another PRD defines a contradicting rule for
the same situation. Categories to scan:
- **Limits and quotas**: goals.md caps Free users at 3 goals; subscription.md lists "up to 5 goals" under Free.
- **Eligibility**: who may do what — onboarding.md lets a user set up auto-debit before identity verification;
  payments.md requires verification first.
- **State transitions**: what happens to a goal when the subscription lapses — goals.md says "archived",
  subscription.md says "read-only until renewal".
- **Timing**: payments.md confirms an auto-debit asynchronously via webhook; goals.md assumes the balance updates
  when the user taps "Deposit".
- **Money and rounding**: two PRDs round the same fee differently (to KRW 1 vs KRW 10), or disagree on the time zone
  a "daily" limit resets in.
- **Ownership of an action**: both payments.md and notifications.md send the "deposit failed" message.

```
🔴 Rule Contradiction
goals.md (Business Rules & Calculations): "Free plan: at most 3 active goals"
subscription.md (Functional Requirements): "A user who downgrades to Free keeps all active goals"
→ These rules directly contradict for a Plus user with 5 goals who downgrades. Which PRD is authoritative?
```

### 2c: Stale References

**Start from each PRD's `## Dependencies` table.** It is the document's own declaration of what it relies on, written
by `/write-prd` with a `PRD` column that `.claude/scripts/review-scope.sh` parses. For each row, confirm the target
PRD exists and that what the `Nature` column says this PRD relies on (a rule, a state, an event, a flag) is still
present in the target under that name.

A table that is absent, or still holding the template's placeholder rows, is itself reportable: say the PRD declares
no dependencies and that the prose scan below was the only check applied. Do not treat an absent table as "no
dependencies" — it far more often means the section was never authored.

**Then scan the prose regardless**, table or no table: a declared table catches what the author remembered, and the
scan catches what they did not. For every cross-document reference (PRD A mentions a rule, state, event, plan or
limit from PRD B), verify the referenced element still exists in PRD B with the same name and behaviour. If PRD A was
written before PRD B and assumed something PRD B later specified differently, flag PRD A as holding a stale reference.

```
⚠️  Stale Reference
notifications.md (written first): "Send the reminder when the goal enters the `at_risk` state defined in goals.md"
goals.md (revised later): defines `behind_schedule`; there is no `at_risk` state
→ notifications.md references a state that no longer exists
```

### 2d: Configuration and Flag Ownership Conflicts

Two PRDs should not both claim to own the same flag, config value or limit. Scan every `## Configuration & Flags`
section and flag duplicates or overlaps:

```
⚠️  Ownership Conflict
payments.md Configuration & Flags: "payments.auto-debit-retry-count — default 2"
goals.md Configuration & Flags: "goals.missed-deposit-retries — default 3"
→ Two keys control the same retry behaviour. Which one owns it? Expect either a double retry or a silent override.
```

### 2e: Conflicting Limits, Prices and Metrics

- **Values that cross a boundary**: when one feature's output is another's input, is the range compatible? A goal
  target of up to KRW 100,000,000 in goals.md against a per-debit ceiling of KRW 2,000,000 in payments.md means the
  largest goals can never be reached on schedule — intended?
- **Prices and entitlements** stated in more than one place (PRDs and `design/product/pricing-model.md`) must agree.
- **Metric definitions**: the same metric defined two ways ("active user" = signed in within 30 days in one PRD,
  made a deposit within 30 days in another) makes every dashboard that combines them wrong.
- **Events**: the same event name with different triggers or properties, or a tracking-plan row whose `Owner PRD`
  disagrees with the PRD that defines the event.
- **Non-functional limits**: rate limits, timeouts or latency budgets that one PRD sets and another's behaviour
  cannot fit inside.

Flag incompatibilities as CONCERNS unless they make a rule impossible to satisfy (then blocking):

```
⚠️  Limit Mismatch
goals.md: maximum goal target = KRW 100,000,000
payments.md: maximum single auto-debit = KRW 2,000,000, at most one per month per goal
→ A goal above KRW 24,000,000 cannot be reached within 12 months. Is that intended? If not, one ceiling changes.
```

### 2f: Acceptance Criteria Cross-Check

Scan the Acceptance Criteria across all PRDs for criteria that cannot both pass:
- subscription.md: "Given a Free user with 3 active goals, when they create a goal, then creation is blocked"
- onboarding.md: "Given a new user, when they finish onboarding, then 4 suggested goals are created and active"

---

## Phase 3: Product Holism

Review all PRDs together through product theory and the brief. These issues cannot be caught per PRD because they
need every feature in view at once.

### 3a: Value Delivery vs Principles

Every feature should serve at least one product principle; a feature that serves none is scope creep by design. For
each PRD, compare its `> **Implements Principle**:` line and its `## User Value` with the brief's principles:

```
⚠️  Principle Drift
leaderboard.md: User Value — "compete with friends on who saves the most"
Principles: "Saving happens without willpower", "Your money, visible at a glance", "Trust over engagement"
→ The leaderboard serves none of the three and pulls against "Trust over engagement". Add a principle that covers it,
  redesign it to serve an existing one, or cut it.
```

Also look for **competing core journeys**: when several features each describe themselves as "the main reason users
come back", users cannot tell what the product is for. One core journey should carry the value proposition, with the
others feeding it.

### 3b: Cognitive Load Across Flows

Count what the user must decide or provide at each step of the core journeys — per PRD this looks fine; together it
often does not. Flag a first session that asks for more than a handful of decisions before the first moment of value,
or a single step that stacks prompts:

```
⚠️  Cognitive Load Risk
First session before the first deposit (onboarding.md, auth.md, payments.md, notifications.md, subscription.md):
  1. Choose a sign-in method (Kakao / Naver / Apple / email)
  2. Name a goal, 3. target amount, 4. target date
  5. Link an account for auto-debit (identity verification)
  6. Push permission, 7. marketing-message consent, 8. night-time message consent
  9. Choose Free or Plus
→ 9 decisions and 3 system prompts before any value. Which can move after the first deposit?
```

### 3c: Business-Rule Abuse Paths

A rule that is safe in its own PRD can be exploited in combination with another. Look for:
- **Self-dealing**: referral credit earned by referring a second account of one's own (new email, Apple's private
  relay addresses, a second phone number).
- **Trial and promotion resets**: a free trial or first-deposit bonus that restarts after account deletion and
  re-registration.
- **Stacking**: coupon + promotion + referral credit applying together when each PRD assumed it applied alone.
- **Refund after use**: a refund path that returns the payment but leaves the credit or entitlement it bought.
- **Timing gaps**: cancelling a subscription the day before renewal while keeping period benefits that another PRD
  grants per month; limits counted per device in one PRD and per account in another.
- **Duplicate side effects**: a webhook redelivery that credits a reward twice because only one PRD defines
  idempotency.

```
🔴 Abuse Path
referral.md: "Referrer and referee each receive KRW 5,000 credit after the referee's first deposit"
auth.md: "Sign in with Apple accepts private relay e-mail addresses; one account per Apple ID"
payments.md: "The first deposit may be KRW 1,000"
→ One person can farm KRW 5,000 per KRW 1,000 deposited using additional Apple IDs. Add a verified-identity rule
  or a minimum first deposit, and name the PRD that owns it.
```

### 3d: Credits and Pricing Economy

Run only when a PRD defines credits, points, rewards, coupons or usage metering; otherwise record
"N/A — no PRD defines credits or metered usage". For each unit, map its **issuance** (how users get it) and
**redemption** (how they spend it or how it expires). A balance is a ledger: balance = Σ issued − Σ redeemed −
Σ expired, and it is never negative (`/business-rules-check` owns that invariant). Redemption therefore cannot
outrun issuance. The risks are in the rates, the values and the outstanding liability:

| Condition | Sign | Risk |
|-----------|------|------|
| **Issuance, no redemption** | Balances only grow | An unbounded liability on the books; users stop valuing it |
| **Redemption, no issuance** | One PRD redeems a unit that no PRD issues | The redemption feature is dead on arrival |
| **Issuance ≫ redemption** | Surplus accumulates | Discounts become the price; margin erodes |
| **Reward out of reach** | At the stated earn rate, the cheapest redemption takes longer than a plausible usage window | Users feel baited and stop engaging with the programme |
| **Breakage unstated or unsourced** | The cost model counts on credit lapsing unused, with no rate or no source for the rate | The real cost of the programme is unknown until redemptions arrive |
| **Redemption value ≥ margin** | One redemption is worth as much as the margin on the purchase it discounts, or more | Every redeemed transaction loses money |
| **Unbounded issuance, no cap** | No per-account cap where issuance has no natural limit | One account, or one 3c abuse path, holds an unbounded balance |
| **Positive feedback** | More credit → cheaper plan → more credit | Runaway cost per active user |
| **No expiry policy** | Nothing ever lapses | Liability never clears; expiry later becomes a trust problem |

Check the result against `design/product/pricing-model.md` when it exists (`## Usage Metering & Credits`,
`## Promotions & Coupons`, `## Refunds & Cancellation`).

### 3e: Scope Drift vs Anti-Goals and Non-Goals

- Flag any feature that does what a brief anti-goal or `## Non-Goals` item rules out.
- Flag any PRD that introduces what another PRD's `## Goals & Non-Goals` explicitly excludes (goals.md: "No social
  features in the MVP"; sharing.md, tier MVP: "Share a goal with a friend").
- Flag MVP-tier PRDs whose scope exceeds the brief's `## MVP Scope`.

```
🔴 Anti-Goal Violation
Anti-goal: "We will not use streaks or loss-framed nudges to drive engagement"
challenges.md: "A 30-day deposit streak; breaking it resets progress and sends a 'Don't lose your streak!' push"
→ This feature directly violates a stated anti-goal.
```

### 3f: User Value Coherence

The value propositions across features should add up to one product identity. Conflicting promises confuse users
and marketing alike:

```
⚠️  Value Conflict
goals.md: "Save without thinking about it — automatic deposits, no daily check-ins"
challenges.md: "Open the app every day to keep your streak alive"
insights.md: "Deep weekly analysis of every transaction"
→ Three features promise three different relationships with the product. Do they serve one identity from
  different angles, or do they genuinely conflict?
```

---

## Phase 4: Cross-Feature Scenario Walkthrough

Walk through the product from the user's side to find problems that only appear where several features act at once —
things static analysis of individual PRDs cannot surface. Skipped in `consistency` and `product-theory` modes (say so
in the report).

### 4a: Identify Key Multi-Feature Moments

Using the user journey (when it exists) and the loaded PRDs, identify the 3–5 most important moments where several
features activate together. Look specifically for:

- **Money + messaging**: a payment succeeds, fails or is retried, and several features notify or recalculate
- **Plan changes + limits**: an upgrade, downgrade, lapse or refund while the user is above a plan limit
- **Identity + everything**: sign-in method changes, account deletion with an active auto-debit or pending credit,
  a device change mid-flow
- **Chains of 3+ features**: a user action that triggers feature A, which feeds B, which triggers C — the highest-risk
  paths

List each scenario with a one-line description before proceeding.

### 4b: Walk Through Each Scenario

For each scenario, step through the sequence explicitly:

1. **Trigger** — what user action or system event starts it (a tap, a webhook, a scheduled job)?
2. **Activation order** — which features act, in what sequence, synchronously or asynchronously?
3. **Data flow** — what does each feature output, and is it a valid input for the next?
4. **User experience** — what does the user see at each step, on each surface (app, web, push, 알림톡, email)?
5. **Failure modes** — are any of these present?
   - **Race conditions**: two features changing the same state at once
   - **Feedback loops**: feature A amplifies B, which re-amplifies A, with no cap
   - **Broken state transitions**: a feature assumes a state another step may have changed ("subscription active"
     after a step that could have lapsed it)
   - **Contradictory messaging**: two features reacting to one event with conflicting or duplicate messages
   - **Compounding limits**: two limits tightening at the same moment, multiplying the intended restriction
   - **Double-dipping**: two features rewarding the same trigger
   - **Undefined behaviour**: no PRD specifies what happens in this combined state

```
Example walkthrough:
Scenario: the monthly auto-debit fails on the day a Plus user's downgrade to Free takes effect

Trigger: Toss Payments reports the auto-debit as failed (webhook)
→ payments.md: marks the debit failed, schedules a retry in 24 h (retry 1 of 2)
→ notifications.md: sends push + 알림톡 "Your deposit didn't go through"
→ goals.md: recalculates progress; the goal is now behind schedule → sends its own "You're falling behind" push
  ⚠️  Contradictory messaging: two messages for one event, and no PRD says which feature owns the user message
→ subscription.md: the downgrade to Free applies at period end — the same day
  ⚠️  Undefined behaviour: the retry runs after the downgrade. Free allows 3 goals and the user has 5; goals.md does
  not say which goals keep their auto-debit, and payments.md retries all 5.
```

### 4c: Flag Scenario Issues

For each problem found, set a severity:

- **BLOCKER**: undefined behaviour, a broken state transition, money moved or messages sent incorrectly — the
  experience is broken or incoherent in this scenario
- **WARNING**: compounding limits, uncapped feedback loops, double-dipping — the experience works but produces
  unintended outcomes
- **INFO**: minor ordering ambiguity or messaging overlap — worth noting, unlikely to reach users

Each finding cites the scenario, the features involved, the step where the issue occurs and the failure mode.

---

## Phase 5: Output the Review Report

```markdown
# Cross-PRD Review — [YYYY-MM-DD]

> **Verdict**: [PASS | CONCERNS | FAIL | NOT ASSESSED]

Focus: [full | consistency | product-theory | since-last-review] · PRDs reviewed: [N] of [M] present
Features covered: [list]
Phases run: [Consistency, Product Holism, Scenarios — name every phase not run and why]
Registry: [loaded — N entries | empty — PRD reads only]

## Consistency Issues

### Blocking (must resolve before architecture begins)
🔴 [Issue title]
[Which PRDs are involved, what the contradiction is, what needs to change]

### Warnings (should resolve, but won't block)
⚠️  [Issue title]
[Which PRDs are involved, what the concern is]

## Product Issues

### Blocking
🔴 [Issue title]
[What the problem is, which PRDs are involved, recommendation]

### Warnings
⚠️  [Issue title]
[What the concern is, which PRDs are affected, recommendation]

## Cross-Feature Scenario Issues

Scenarios walked: [N] — [scenario names]

### Blockers
🔴 [Scenario name] — [Features involved]
[Step where the failure occurs, failure mode, what must be resolved]

### Warnings
⚠️  [Scenario name] — [Features involved]
[Unintended outcome, recommendation]

### Info
ℹ️  [Scenario name] — [Features involved]
[Minor ordering ambiguity or note]

## PRDs Flagged for Revision

| PRD | Reason | Type | Priority |
|-----|--------|------|----------|
| design/prd/subscription.md | Rule contradiction with goals.md (Free-plan goal limit) | Consistency | Blocking |
| design/prd/notifications.md | Stale reference to a goal state that no longer exists | Consistency | Blocking |
| design/prd/leaderboard.md | Serves no product principle | Product | Warning |

## Not Assessed
[Each phase or PRD that could not be reviewed, and the input it needed — or "None"]

## Required Actions (FAIL only)
[What must change in which PRD before re-running]
```

The `> **Verdict**:` line sits directly under the H1 — `/gate-check` reads it there.

**Verdicts:**
- **PASS** — no blocking issue and no warning that needs resolving before architecture (INFO notes allowed).
- **CONCERNS** — warnings that should be resolved or explicitly accepted, none blocking.
- **FAIL** — one or more blocking issues must be resolved before architecture begins.
- **NOT ASSESSED** — the review could not cover what it claims to (below).

**`NOT ASSESSED` — a cross-review is only as wide as what it could read.** Rank: **above PASS**, **below CONCERNS and
FAIL**. This skill's whole value is comparing features *against each other*, so it is unusually easy for it to look
thorough while covering a fraction of the surface. Emit it when any of:

- **A whole review phase that this focus includes did not run.** A parallel phase that returned nothing has to be
  distinguished from one that returned no findings; if a spawned agent produced no findings section, that phase is
  NOT ASSESSED, not clean — an agent can return a fluent sentence, report nothing, and consume a phase.
- **The product principles are undefined** (no brief, or a brief without `## Product Principles & Anti-Goals`), so
  principle drift has no reference to drift from.
- **A PRD is present but empty** (headings only, or all placeholders). Present is not the same as reviewable, and a
  stub contradicts nothing.

(Fewer than two readable PRDs stops the skill in Phase 1c without a report.) Report the covered set explicitly either
way: `PRDs reviewed: [N] of [M] present`. A cross-review that silently skipped half the features is
indistinguishable from one that found them consistent.

---

## Phase 6: Write Report and Flag PRDs

Use `AskUserQuestion` for write permission:
- Prompt: "May I write this review to `design/prd/reviews/prd-cross-review-YYYY-MM-DD.md`?"
- Options: `[A] Yes — write the report` / `[B] No — skip`

If a report with today's date already exists, say so and ask whether to replace it — there is one report per day,
and the newest by name is the next run's baseline.

> **`YYYY-MM-DD` means ISO 8601, e.g. `prd-cross-review-2026-10-19.md`. This is not a style preference.**
> `.claude/scripts/review-scope.sh` picks the prior review with `sort | tail -1`, so lexical order IS chronological
> order only for ISO dates. Written as `oct-19-2026` or `19-10-2026`, the wrong file is chosen as the baseline, the
> changed set is computed from it, and PRDs modified since the real last review silently escape the next one.

If any PRDs are flagged for revision, use a second `AskUserQuestion`:
- Prompt: "May I write this to `design/product/feature-map.md`? It marks these PRDs as needing revision:
  [list of flagged PRDs]"
- Options: `[A] Yes — update the feature map` / `[B] No — leave as-is`
- If yes: Read the feature map in full, set each flagged feature's `Status` cell to `Needs Revision`, and write it back
  with nothing else changed — show the changed rows first. Do NOT append parentheticals to the status value: other
  skills match `Needs Revision` as an exact string. The PRD's own `> **Status**:` line is set when the PRD is revised
  and re-reviewed (`/prd-review` offers it); name that pending step in the summary.

### Session State Update

After writing the report (and updating the feature map if approved), silently append to
`production/session-state/active.md`:

    ## Session Extract — /review-all-prds [date]
    - Verdict: [PASS / CONCERNS / FAIL / NOT ASSESSED]
    - PRDs reviewed: [N of M present]
    - Phases not run: [names, or "None"]
    - Flagged for revision: [comma-separated list, or "None"]
    - Blocking issues: [N — brief one-line descriptions, or "None"]
    - Recommended next: [the Phase 7 hand-off, condensed to one line]
    - Report: design/prd/reviews/prd-cross-review-[date].md   ← only if the user approved the write
    - Report: (not written — user declined at [date])          ← only if the user declined the write

Use the line that matches the user's answer to the write-permission widget. If `active.md` does not exist, create it
with this block as the initial content. Confirm in conversation: "Session state updated."

---

## Phase 7: Handoff

After all file writes are complete, use `AskUserQuestion` for a closing widget.

Before building options, check project state:
- Are any PRDs in the "PRDs Flagged for Revision" table? → offer `/prd-review` for each
- Read `design/product/feature-map.md` for the next `Not Started` MVP feature → offer `/write-prd`
- Do ADRs already cite a flagged PRD in `## PRD Requirements Addressed`? → offer `/propagate-prd-change`
- Is the verdict PASS or CONCERNS? → offer `/create-architecture`, and `/gate-check architecture` on PASS

**Option pool** (only include options that apply):
- `[_] Run /prd-review design/prd/<flagged>.md — address the flagged issues` (one per flagged PRD)
- `[_] Run /write-prd <next-feature> — next in the feature map` (name the actual feature)
- `[_] Run /propagate-prd-change design/prd/<flagged>.md — ADRs were written against it` (when that applies)
- `[_] Run /consistency-check — add cross-PRD facts to the glossary registry` (when the registry was empty)
- `[_] Run /create-architecture — begin architecture (verdict is PASS or CONCERNS)`
- `[_] Run /gate-check architecture — Definition → Architecture` (verdict is PASS)
- `[_] Stop here`

Assign letters A, B, C… only to included options. Mark the most pipeline-advancing option as `(recommended)`.

In collaborative and guided modes, never end the skill with plain text — always close with this widget. In
autonomous mode, print the verdict and recommended next step, then record via `log_decision` (no widget).

---

## Error Recovery Protocol

**First, verify the result.** A spawned phase agent returns findings, not files — check that each returned a findings
section for every checklist item it was given before treating the phase as done. **A phase whose findings are
missing is a failed phase, however fluent the response reads.** An agent can burn a full phase and return a plausible
preamble having reported nothing, which is neither BLOCKED nor an error nor "fails to complete", so the trigger below
never fires. Resume it naming the missing items; the context is usually still there.

If any spawned agent returns BLOCKED, errors, or fails to complete: **surface it immediately, don't proceed past a
dependency it blocks, and always produce a partial report** (retry scope here = fewer PRDs, or a single focus mode).
Full procedure: `.claude/docs/error-recovery-protocol.md`.

---

## Collaborative Protocol

**In `collaborative` mode (the default).** For `guided` and `autonomous` modes, see
`.claude/docs/automation-modes.md`. In `autonomous` mode the PASS / CONCERNS / FAIL / NOT ASSESSED verdict is still
printed and logged — only the closing hand-off widget is skipped.

1. **Read silently** — load all in-scope PRDs before presenting anything
2. **Show everything** — present the full consistency, product and scenario analysis before asking for any action
3. **Distinguish blocking from advisory** — not every issue needs to block architecture; be clear about which do
4. **Don't make product decisions** — flag contradictions and options, but never unilaterally decide which PRD is
   "right"
5. **Ask before writing** — confirm before writing the report or updating the feature map
6. **Be specific** — every issue cites the exact PRD, section and text involved; no vague warnings
