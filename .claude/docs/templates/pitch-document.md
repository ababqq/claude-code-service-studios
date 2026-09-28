# Pitch: [Product Name]

> **Version**: [draft number]
> **Date**: [YYYY-MM-DD]
> **Audience**: [seed investors / accelerator / internal investment committee / partner]
> **Source brief**: [`design/product/product-brief.md` or `design/product/one-pager.md`]

> [The hook — one sentence that makes the reader want the next paragraph.]

<!--
`/brainstorm pitch` writes this file to `design/product/pitch.md` from the product
brief (or the one-pager at `minimal`). The brief stays the source of truth: when
the two disagree, fix the brief first and regenerate the pitch.

Structure follows the problem → solution → why now → market → traction → business
model → team → ask order most seed investors in Silicon Valley and Korea expect; the
sections map one-to-one onto slides if the team builds a deck from it.

SOURCING RULE — every market number, growth rate, competitor fact and traction
figure carries `(Source: <url or internal report path>, retrieved YYYY-MM-DD)` or is
labelled `Assumption:`. A number without either is removed, not softened. Traction
comes only from evidence on disk (prototype reports, usability reports, analytics
readouts) or figures the user supplies.

Examples use Moa, a B2C subscription savings app for the Korean market; numbers in
the examples are placeholders, not facts. Delete these comments before sharing.
-->

---

## Problem

[Who has the problem, how often, how painful, and what it costs them — in two or
three sentences, with the strongest evidence you have (quotes by participant ID,
data with its source).]

*Example (Moa)*: "Salaried people set savings goals and plan to transfer money on
payday; within a few months most skip a transfer and abandon the goal. 7 of 9
interviewees described exactly this (P1–P9)."

---

## Solution

[What the product does, shown through the core user journey and its success
moment — not a feature list. Link a prototype or a short screen recording if one
exists.]

### Differentiation vs Alternatives

| Alternative | Why users choose it today | Why they will switch |
|---|---|---|
| [A bank's installment savings product] | [...] | [...] |
| [Doing nothing] | [...] | [...] |

---

## Why Now

[What changed that makes this possible or urgent now — regulation, a platform or
payment rail, user behaviour, the cost of a key technology — each change sourced.]

---

## Market (TAM / SAM / SOM)

[Bottom-up first: count the users who could buy, times what they would pay.
Top-down industry totals only as a cross-check.]

| Layer | Definition | Calculation | Value | Source |
|---|---|---|---|---|
| **TAM** | [everyone with the problem] | [number of people × annual price] | [...] | [...] |
| **SAM** | [the part reachable with this product, channels and regions] | [TAM × share in the target segment and region] | [...] | [...] |
| **SOM** | [what the team can realistically win in 3 years] | [SAM × achievable share, justified by channel capacity] | [...] | [...] |

*Example (Moa, structure only)*: TAM = salaried workers in Korea × share who save
toward a goal × Plus price × 12; SAM = the 25–39 segment reachable through app
store search and referrals; SOM = SAM × a share justified by the acquisition plan.
Every input comes from a cited statistic or is labelled `Assumption:`.

---

## Traction

[Evidence that the problem is real and the solution works — in order of strength:
revenue and retention, active usage, waitlist or fake-door conversion, prototype
and usability results, interview findings. State sample sizes; label small samples
as directional.]

| Signal | Value | Period | Evidence |
|---|---|---|---|
| [fake-door sign-up rate] | [...] | [...] | [`prototypes/<name>-concept/REPORT.md`] |
| [usability task success on the core journey] | [...] | [...] | [`production/qa/usability/…`] |

[If there is no traction yet, say so and show the plan: the riskiest assumptions
and the tests that will answer them in the next 8–12 weeks.]

---

## Business Model

| Element | Plan |
|---|---|
| **Revenue model** | [subscription / usage / transaction fee / B2B seats — e.g. Free and Plus plans] |
| **Pricing** | [price points and what each includes — hypothesis until tested] |
| **Unit economics** | [target CAC, ARPU, gross margin, payback period — current value or target] |
| **Key costs** | [payment fees, per-message notification costs, infrastructure, support] |
| **Constraints** | [regulation, platform fees, market norms that shape the model] |

### Go-to-Market
[First channel and why it fits the segment (app store search, content, referrals,
partnerships, sales-led for B2B); the first 1,000 users plan; launch markets.]

---

## Team

| Name | Role | Why this person for this problem |
|---|---|---|
| [...] | [...] | [domain experience, prior products, unfair advantage] |

[Key hires the plan depends on, and advisors if relevant.]

---

## The Ask

- **What we are asking for**: [amount and instrument (e.g. a SAFE, RCPS
  (상환전환우선주), common equity), a partnership, a pilot customer, feedback]
- **What it buys**: [the milestones it funds — e.g. public launch, a retention
  target, break-even on a cohort — and the runway in months]
- **Use of funds**: [split by team, marketing, infrastructure, compliance]
- **Next step for the reader**: [a meeting, a pilot, an introduction]
