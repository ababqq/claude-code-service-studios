# Product Brief: [Product Name]

> **Status**: Draft | In Review | Approved
> **Owner**: [product-manager, or the person accountable for this bet]
> **Last Updated**: [YYYY-MM-DD]
> **Category**: [the `project.category` value — e.g. "B2C fintech (subscription savings)"]
> **Workflow Tier**: [standard | full]
> **Product Director Review (PD-PRINCIPLES)**: [APPROVED | CONCERNS (accepted) | REVISED] [YYYY-MM-DD]
> **Technical Director Review (TD-FEASIBILITY)**: [APPROVED | CONCERNS (accepted) | REVISED] [YYYY-MM-DD]
> **Delivery Manager Review (DM-SCOPE)**: [APPROVED | CONCERNS (accepted) | REVISED] [YYYY-MM-DD]
> **Design Director Review (DD-BRAND-DIRECTION)**: [APPROVED | CONCERNS (accepted) | REVISED] [YYYY-MM-DD]

<!--
WHAT THIS IS
The product brief is the Discovery-phase record of the bet at the `standard` and
`full` workflow tiers. `/brainstorm` writes it to `design/product/product-brief.md`
(at `minimal` it writes `design/product/one-pager.md` from
`.claude/docs/templates/one-pager.md` instead). `/prd-review` reviews it,
`/map-features` decomposes its MVP Scope into features, every PRD's
`> **Implements Principle**:` line points at one of its principles, and
`/gate-check definition` reads it.

MACHINE CONTRACT — do not rename, translate, reorder or number the `##` headings.
`/gate-check definition` checks seven of them by exact name: Problem Statement,
Target Users & Jobs-to-be-Done, Value Proposition, Product Principles & Anti-Goals,
Success Metrics, Riskiest Assumptions, MVP Scope. Keep headings, bold labels,
tokens and IDs in English; write the body in the team's conversation language.
`###` sub-headings inside a section are free.

REVIEW LINES
Replace each review line in the status block with the recorded outcome
(format: `.claude/docs/director-gates.md` § Recording Gate Outcomes) or with the
gate's skip note — for example `> [TD-FEASIBILITY] skipped — Lean mode`. Delete the
DD-BRAND-DIRECTION line when the brand step did not apply (`standard` tier, no UI
surface, or direction deferred to `/design-language`); keep its skip note when the
review mode skipped it.

EVIDENCE RULE
Every claim about users or the market carries its evidence (interviews with
participant IDs, data with its source, `Source: <url>, retrieved YYYY-MM-DD`) or is
labelled a hypothesis. Where nothing is known yet, write
`NOT DETERMINED — <what would answer it>` instead of a plausible guess.

EXAMPLES
Examples use Moa — a B2C subscription savings app (web + iOS + Android + API) for
the Korean market with the features auth, onboarding, goals, payments,
notifications, subscription and admin-console. Every number in them is
illustrative. Replace every example with your product's facts and delete these
comments when the brief is written.
-->

## Elevator Pitch

> [One or two sentences someone outside the team understands in ten seconds:
> "For [target segment] who [situation / struggle], [Product] is a [category]
> that [key benefit]. Unlike [primary alternative], it [one differentiator]."]

*Example (Moa)*: "For salaried people in Korea who mean to save toward a goal every
payday but keep skipping the transfer, Moa is a savings app that moves the money
automatically on payday and shows every goal filling up. Unlike a bank's
installment savings product, goals can be paused, resized and split without
cancelling anything."

---

## Problem Statement

[The problem in the user's words, before any solution. Answer:]

- **Who has it**: [the segment, concretely]
- **When it bites**: [the situation or trigger]
- **How often and how badly**: [frequency, cost in money / time / stress]
- **What they do today**: [the workaround — detail it under Alternatives & Positioning]
- **Why now**: [what changed — regulation, platform, behaviour, cost — that makes
  this solvable or urgent now]
- **Evidence**: [interviews (n, participant IDs), analytics, support tickets,
  search or survey data — each with its source and a confidence of high / medium /
  low]

*Example (Moa)*: "People who set a savings goal plan to move money on payday, and by
the third month most have skipped at least one transfer; the goal quietly dies and
they feel they 'are bad with money'. Evidence: 7 of 9 interviewees (P1–P9) described
a goal abandoned within four months (medium confidence — one recruitment channel)."

---

## Target Users & Jobs-to-be-Done

### Primary Segment
[Name the segment concretely enough that a recruiter could screen for it — not
"young people" but "salaried 25–34-year-olds in Korea who save toward a goal by
manual transfer each payday".]

### Jobs-to-be-Done

| Job statement ("When …, I want to …, so I can …") | Type (functional / emotional / social) | Current workaround | Evidence |
|---|---|---|---|
| [When I get paid, I want part of it set aside before I can spend it, so I can reach my goal without relying on willpower] | functional | [manual transfer on payday] | [P2, P4, P7] |

### Forces of Progress
- **Push** (what pushes users away from today's way): [...]
- **Pull** (what attracts them to the new way): [...]
- **Anxiety** (what worries them about switching): [e.g. "an app debiting my
  account automatically", "being locked in like an installment savings product"]
- **Habit** (what keeps them where they are): [...]

### Secondary Segments and Who This Is Not For
- **Secondary**: [adjacent segment that may also adopt, and what differs for them]
- **Not for**: [who we are deliberately not serving, and why — being clear here
  prevents features for users we do not want]

### Personas
[Optional. Link the persona files `/brainstorm` wrote with ux-researcher, e.g.
`design/product/personas/payday-saver.md`, or write "none".]

---

## Alternatives & Positioning

| Alternative (incl. "doing nothing") | What users hire it for | Where it falls short | How we differ |
|---|---|---|---|
| [A bank's installment savings product] | [forced discipline, interest] | [rigid term, penalty to break, one goal per product] | [goals can pause and resize without cancelling] |
| [The savings feature inside a super-app] | [convenience — already installed] | [...] | [...] |
| [A spreadsheet or memo app] | [...] | [...] | [...] |
| [Doing nothing — manual payday transfer] | [free, flexible] | [depends on willpower every month] | [...] |

**Positioning statement**: [For [target segment] who [need], [Product] is a
[market category] that [key benefit]. Unlike [best alternative], we [primary
differentiator].]

**Market facts**: [Only sourced facts — each followed by
`(Source: <url>, retrieved YYYY-MM-DD)` — or `NOT SOURCEABLE — <what was searched>`.]

---

## Value Proposition

- **Value hypothesis (desirability)**: [We believe [segment] will [behaviour]
  because [value]; we will know when [observable signal].]
- **Pains relieved**: [...]
- **Gains created**: [...]
- **Success moment**: [the first moment the user experiences the value — the
  "aha" the onboarding must reach, e.g. "the first automatic payday transfer
  completes and the goal ring moves without the user doing anything"]
- **Why us**: [the capability, insight or distribution the team has that the
  alternatives lack]

---

## Business Model Hypothesis

| Element | Hypothesis | Confidence | How we will test it |
|---|---|---|---|
| **Revenue model** | [subscription / usage / transaction fee / B2B seat / ads — e.g. Free and Plus plans] | [H/M/L] | [...] |
| **Price point** | [e.g. Plus at KRW 3,900 per month — illustrative] | [...] | [fake-door price test, interviews] |
| **Who pays** | [user / employer / partner] | [...] | [...] |
| **Key costs** | [payment fees, per-message notification costs, infrastructure, support] | [...] | [...] |
| **Acquisition channels** | [organic app store search, referrals, content, partnerships] | [...] | [...] |
| **Unit economics** | [target CAC, ARPU, gross margin, payback period] | [...] | [...] |
| **Constraints on the model** | [regulation, platform fees, market norms — e.g. whether holding customer money makes the product a regulated payment service in the target region] | [...] | [question for counsel, vendor call] |

[Detailed plans, entitlements and credits are specified later in
`design/product/pricing-model.md`, which `/write-prd` creates when a PRD defines
plans or prices.]

---

## Product Principles & Anti-Goals

[3–5 principles. A principle is a decision rule the team will use to settle real
disagreements — not a slogan. Each must be falsifiable (a plausible decision could
fail it), state the trade-off it decides, differentiate the product from the
alternatives above, and serve a job from Target Users & Jobs-to-be-Done.]

### Principle 1: [Name]
[One sentence defining the principle.]

- **Decision test**: [When [X] conflicts with [Y], we choose [X] — even though it
  costs [Z].]
- **Serves job**: [the job statement it protects]

*Example (Moa)*: **Saving happens without remembering** — the user never has to
act for a planned transfer to happen. *Decision test*: when a manual "deposit now"
button would raise engagement, we keep automatic payday transfers as the primary
flow — even though daily opens will be lower. *Serves job*: "set money aside before
I can spend it".

### Principle 2: [Name]
[Definition]

- **Decision test**: [...]
- **Serves job**: [...]

### Principle 3: [Name]
[Definition]

- **Decision test**: [...]
- **Serves job**: [...]

*Example (Moa)*: **Trust over conversion** — no dark patterns anywhere money or
consent is involved. *Decision test*: when a pre-checked marketing consent box or a
hidden cancel path would lift Free → Plus upgrades, we choose the honest flow even
though the upgrade rate is lower.

### Anti-Goals
[What this product will not become, even if asked. Anti-goals are permanent
("never"); Non-Goals below are about this release ("not now"). Each names the
principle it protects.]

- **Not [thing]**: [why — the principle it would compromise]

*Example (Moa)*: **Not an investment product** — returns and market risk would
break "Trust over conversion" and put the product in a different regulatory
category. **No social leaderboards** — comparing savings amounts shames users who
save less. **No notifications that shame a missed transfer.**

---

## Brand Direction Anchor

<!--
OPTIONAL SECTION. Omit it entirely — heading included — when the product has no UI
surface (`platform.surfaces` is `api` only) or when the team defers brand direction
to `/design-language`. `/design-language` looks for this heading; when it is
absent, it runs DD-BRAND-DIRECTION itself before writing the design language.
`/brainstorm` offers this step only at the `full` tier with a UI surface.
-->

- **Direction**: [name of the chosen direction, e.g. "Calm money"]
- **Brand rule**: [one line that can settle any UI decision — e.g. "nothing on
  screen raises the heart rate unless money is actually at risk"]
- **Personality**: [three adjectives and one "but not" — e.g. calm, warm, precise,
  but not childish]
- **Color philosophy**: [what color means in this product, including market
  conventions — in Korean finance interfaces red commonly signals a rise, not an
  error — and headroom for the contrast the accessibility target will demand]
- **Typography direction**: [a Hangul-first UI typeface paired with Latin and
  numerals that read well in amounts and dates]
- **Platform stance**: [brand-forward custom components, or platform conventions
  (Human Interface Guidelines, Material) on each surface — and the maintenance cost]
- **Rejected directions**: [the other directions offered, and why they lost]

---

## Success Metrics

### North Star Metric

| Metric | Definition (exact event or query) | Baseline | Target (by when) | Source |
|---|---|---|---|---|
| [e.g. weekly active savers] | [users with ≥1 successful automatic transfer in the last 7 days] | [none — new product] | [e.g. 5,000 by the end of the beta] | [product analytics] |

[Why this metric captures delivered value, not just activity.]

### Guardrail Metrics
[Metrics that must not get worse while the North Star goes up. At least one.]

| Metric | Threshold | Why it guards the North Star |
|---|---|---|
| [automatic transfer failure rate] | [< 2% of attempts] | [growth that fails payments destroys trust] |
| [notification opt-out rate] | [...] | [...] |
| [support contacts per 1,000 active users] | [...] | [...] |

### Input Metrics
[Optional. Leading indicators per lifecycle stage — acquisition, activation,
retention, monetization — e.g. sign-up → first goal created → auto-debit
authorised → first transfer completed; D1 / D7 / D30 retention; Free → Plus
conversion. Event names follow `naming.events` once `/setup-stack` sets it.]

---

## Riskiest Assumptions

[The beliefs that, if wrong, sink the product. Cover the four risks — **Value**
(will they want it), **Usability** (can they use it), **Feasibility** (can we build
and operate it, incl. third parties), **Viability** (does it work for the business:
cost, pricing, regulation). Every assumption gets a test.]

| # | Assumption | Risk | Confidence | Impact if wrong | Test (prototype, interviews, fake door, concierge, data, vendor call, spike) | Pass signal | Status |
|---|---|---|---|---|---|---|---|
| 1 | [Users will authorise automatic debit from their salary account in the first session] | Value / Usability | [low] | [no transfers → no value] | [clickable prototype with 5 target users via `/prototype`] | [≥ 4 of 5 complete authorisation without help] | Untested |
| 2 | [The payment provider approves recurring debit for a savings use case] | Feasibility | [...] | [...] | [vendor call + sandbox spike] | [...] | Untested |

**Status** values: `Untested`, `Testing`, `Validated`, `Invalidated`. Update the
row when a `prototypes/<name>-concept/REPORT.md`, a usability report or a data
readout answers it.

---

## MVP Scope

[The smallest product that tests the value hypothesis with real users and can be
released to them. Each capability traces to a job or an assumption.]

| Capability | Why it is in the MVP (job / assumption #) | Notes |
|---|---|---|
| [Sign-up and sign-in (email, Kakao, Naver, Apple)] | [prerequisite] | [...] |
| [Create a goal with amount and date] | [job 1] | [...] |
| [Automatic payday transfer] | [assumption 1] | [...] |
| [Transfer result notification] | [trust — Principle 3] | [...] |

- **Target**: [milestone and date, or "none given"]
- **Team**: [who builds it; the assumptions the timeline depends on]
- **After the MVP**: [one line per later tier — Beta, GA, Later; `/map-features`
  formalizes the tiers in `design/product/feature-map.md`]

---

## Non-Goals

[What is deliberately out of scope for this release, and why. `/scope-check` and
each PRD's `## Goals & Non-Goals` compare against this list.]

- [e.g. No web-based goal creation in the MVP — mobile first; web shows balances only]
- [e.g. No Plus plan at MVP — pricing is tested with a fake door first]
- [e.g. No shared goals between users]

---

## Open Questions

| Question | Owner | How we will answer it | By when |
|---|---|---|---|
| [Can the product avoid holding customer money by debiting into a partner account?] | [product-manager + counsel] | [legal consultation; see `.claude/docs/compliance/kr.md`] | [YYYY-MM-DD] |
