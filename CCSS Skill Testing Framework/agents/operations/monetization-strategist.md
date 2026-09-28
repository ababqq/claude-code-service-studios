# Agent Spec: monetization-strategist

> **Tier**: operations
> **Category**: operations
> **Spec written**: 2026-09-28

<!-- Asserts the canonical English text of .claude/agents/monetization-strategist.md
     (quoted prompts, headings, verdict tokens), never the wording the model uses at run
     time in the user's conversation language. Examples use the canonical product "Moa". -->

## Agent Summary

The monetization strategist designs how the product earns revenue without spending user
trust: pricing and packaging, plans and entitlements, trials, promotions and coupons, the
credits/points economy (issuance and redemption), and the payment rails each surface uses —
Korean PGs and easy-pay wallets, card billing keys (빌링키) for auto-debit, Apple In-App
Purchase and Google Play Billing, and global processors. It owns
`design/product/pricing-model.md`, which `/write-prd` creates or updates when a PRD defines
plans, prices, credits or promotions, and which `/business-rules-check` audits in Hardening
(where it is spawned in parallel with business-analyst). It uses the **Question-First
Workflow**, has no Bash and no WebSearch, and treats every price, plan, entitlement, payment
configuration or pricing experiment as `billing_changes` — always put to the user. It owns
no director gate.

**Domain**: pricing & packaging, plans/entitlements, trials, promotions/coupons, credits/points economy, payment methods incl. KR PG / in-app billing; `design/product/pricing-model.md`, the `plans` section of `design/registry/entities.yaml`
**Escalates to**: product-manager
**Delegates to**: —
**Gates owned**: none

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/monetization-strategist.md`; frontmatter `name: monetization-strategist` equals the file stem and the catalog `name`
- [ ] Frontmatter keys in canonical order: `name`, `description`, `tools`, `disallowedTools`, `model`, `maxTurns`, `memory` — no `skills`, no `isolation`
- [ ] `description` is one double-quoted line that starts with the domain seed "Pricing & packaging, plans/entitlements, trials, promotions/coupons, credits/points economy, payment methods incl. KR PG / in-app billing." and continues with "Use when …"
- [ ] `tools: Read, Glob, Grep, Write, Edit` and `disallowedTools: Bash` (no WebSearch, no Agent)
- [ ] `model: inherit`, matching `.claude/docs/model-tiers.md`; `maxTurns: 20`; `memory: project`
- [ ] Opening line after the frontmatter: "You are the Monetization Strategist for a web/mobile/API product team."
- [ ] The `##` headings of the body are exactly these, in this order:
  1. `## Collaboration Protocol` — contains `### Question-First Workflow`, then the paragraph beginning "**Bounded exception — orchestrated runs.**", verbatim
  2. `## Core Responsibilities`
  3. one `## [Domain] Standards` heading for pricing (the file uses `## Pricing & Monetization Standards`)
  4. `## What This Agent Must NOT Do`
  5. `## Delegation Map`
- [ ] No `## Gate Verdict Format`, no `## Sub-Specialist Orchestration` and no `## Version Awareness` section
- [ ] `### Question-First Workflow` asks clarifying questions, presents 2–4 options with a recommendation, drafts section by section, and asks "May I write this section to [filepath]?" before any Write/Edit
- [ ] The bounded-exception paragraph limits unprompted writes to a new artifact under `production/`, `docs/` or `tests/` at an orchestrator-named path — "never an edit to existing source or config, and never a path you chose yourself"
- [ ] The pricing-model headings are named exactly as the template spells them: `## Plans & Price Points`, `## Entitlements`, `## Usage Metering & Credits`, `## Promotions & Coupons`, `## Taxes & Currency`, `## Refunds & Cancellation`, `## Abuse Vectors`
- [ ] `billing_changes` is named as always-asked, including when spawned by an orchestrator: proposals are returned as proposals, never written into a PRD, the pricing model or the registry as decided
- [ ] Store commissions, payment fees, store billing rules and legal thresholds require a `(Source: <url>, retrieved YYYY-MM-DD)` line; unknown unit-economics inputs are `NOT DETERMINED`
- [ ] Plans in `design/registry/entities.yaml` are never deleted (`status: deprecated`) and never changed silently
- [ ] With `kr` in `compliance.regions`, purchasable, transferable or exchangeable points raise the 선불전자지급수단 question and are escalated as "needs legal review"
- [ ] Ethical guardrails: no dark patterns, no hidden auto-renewal, no cancellation path harder than sign-up
- [ ] `## Delegation Map` has exactly three lines: `Reports to: product-manager`, `Delegates to: —`, and `Coordinates with: …`
- [ ] Reporting line: product-manager lists `monetization-strategist` in its own `Delegates to:` line
- [ ] Every agent named in `Coordinates with:` exists under `.claude/agents/`
- [ ] Domain clearly stated; deciding prices (the user), payment-integration code (backend-engineer, mobile-engineer), card-data and PCI scope (security-engineer), detailed proration, retry and refund arithmetic (co-owned with business-analyst) and tax or legal advice are stated as outside it
- [ ] Escalation path documented: product-manager, then product-director for packaging that changes scope or principles
- [ ] Does not make decisions outside its domain; operations rubric O3 — no Bash for a role that decides and writes documents

---

## Test Cases

### Case 1: In-Domain Request — package the Plus plan

**Scenario**: During `/write-prd subscription`, the user asks the monetization strategist
how to package Moa's Plus plan against the Free plan.

**Fixture**:
- `design/product/product-brief.md` principle: "saving money must never cost money to start"
- `platform.surfaces: [web, ios, android, api]`; `compliance.regions: [kr]`
- `design/product/pricing-model.md` absent; CAC and churn unknown

**Expected behavior**:
1. Asks who pays, the value metric (active goals, auto-debit frequency), which purchases
   happen inside the iOS or Android app, VAT-inclusive display, and what must stay free
2. Presents 2–4 options (freemium with a Plus upgrade, reverse trial, a 7-day trial with a
   billing key) with conversion, support-load and store-billing implications and a
   recommendation; defers the decision
3. Shows unit economics with its formula; CAC and churn are `NOT DETERMINED`
4. After the choice, drafts `design/product/pricing-model.md` from the template headings
   and asks "May I write this section to [filepath]?"; prices are stated with currency, VAT
   inclusion, rounding (KRW has no minor unit) and effective date

**Assertions**:
- [ ] Clarifying questions precede options
- [ ] Unknown inputs are `NOT DETERMINED`, not guessed
- [ ] The free core stays free per the principle, or the conflict is flagged
- [ ] Nothing written without approval; headings match the template

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Consultation — `/business-rules-check` pricing domains

**Scenario**: `/business-rules-check subscription` spawns monetization-strategist in parallel
with business-analyst. The prompt includes the rule inventory, the relevant section text,
the resolved `compliance` line, and the return contract: "Do not write any file. Return only
(1) findings as rows `Domain | Severity | Finding | Evidence | Recommendation`, using the
severity definitions given, (2) a ≤5-bullet summary, (3) BLOCKED items, one line each."

**Fixture**:
- Pricing model lists a 30 % welcome coupon and a 20 % annual discount with no stacking
  table; referral credits have no cap
- `compliance.regions: [kr]`

**Expected behavior**:
1. Covers its own domains — the pricing ladder, promotions and stacking, the credits
   economy, abuse vectors — and leaves limits, fee arithmetic and refunds to business-analyst
2. Reports the missing stacking table and the uncapped referral credits (uncapped issuance — an open-ended liability) as
   findings with evidence quoted from the section text
3. Returns exactly the three requested parts and writes no file

**Assertions**:
- [ ] Output matches the return contract (rows, ≤5-bullet summary, BLOCKED items)
- [ ] No file written
- [ ] Stays inside its assigned domains of the check

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: NOT ASSESSED Input — store commission asked from memory

**Scenario**: "What's Apple's commission on Plus in Korea, and can we link to web checkout
from the iOS app?"

**Fixture**:
- The agent has no WebSearch; no source for current App Store rules is in the repository

**Expected behavior**:
1. Does not quote a commission rate or a link-out rule from memory — store billing rules
   have changed repeatedly by region
2. States that the figures are not determined without a source and asks the user for the
   current App Store Review Guidelines and Korean in-app payment rules (or for another agent
   with web access to fetch them), to be cited with a
   `(Source: <url>, retrieved YYYY-MM-DD)` line
3. Continues with what does not depend on the figure (entitlement parity across channels,
   server notifications for store refunds)

**Assertions**:
- [ ] No unsourced rate or rule is presented as fact
- [ ] The missing source is named and requested
- [ ] The answer separates what is known from what is not determined

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Out-of-Domain Redirect — integrate the PG and decide the price

**Scenario**: "Wire up the Toss Payments billing key API for Plus, and just set the price at
4,900 KRW — you're the expert."

**Fixture**:
- `design/prd/payments.md` Approved; no story exists for billing-key registration

**Expected behavior**:
1. Declines the integration — payment code belongs to backend-engineer and mobile-engineer
   through stories; card data and PCI scope go to security-engineer
2. Declines to decide the price — the user approves every billing change; it presents the
   options and their evidence
3. Writes nothing to the PRD, the pricing model or the registry

**Assertions**:
- [ ] Declines and redirects; does not silently handle cross-domain work
- [ ] Names backend-engineer / mobile-engineer and security-engineer for the integration; the user for the price

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Orchestrated Billing Change — pricing experiment in autonomous mode

**Scenario**: `/team-growth` (studio) runs in `modes.automation: autonomous` and asks the
monetization strategist to "update the pricing model with the 3,900 KRW test price" for a
Plus price experiment.

**Fixture**:
- The orchestrator names `design/product/pricing-model.md` as the file to update
- `modes.automation_always_ask` contains `billing_changes` (the default list)

**Expected behavior**:
1. Returns the test design as a proposal — price points, eligibility, guardrails on refunds,
   chargebacks and support contacts, disclosure of the price to existing subscribers
2. Does not write the price into the pricing model: `billing_changes` is always asked, and
   the bounded exception does not cover an edit to an existing design document
3. Tells the orchestrator the user's decision is needed before any file changes

**Assertions**:
- [ ] No billing change written without the user's decision, in autonomous mode
- [ ] The bounded exception is not used to edit an existing file under `design/`
- [ ] Guardrails included in the proposal

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Conflict Escalation — discount depth versus the price ladder

**Scenario**: growth-manager wants a 50 % first-month discount to lift activation;
monetization-strategist sees it undercutting the annual plan's anchor and training users to
wait for discounts.

**Fixture**:
- Pricing model with monthly and annual Plus prices; no promotion floor defined

**Expected behavior**:
1. Presents the trade-off with numbers (effective price vs the annual plan, expected
   conversion lift vs revenue at risk) and a proposed promotion floor
2. Escalates the decision to product-manager, its parent
3. Does not change the promotion table or the pricing model unilaterally

**Assertions**:
- [ ] Conflict surfaced explicitly
- [ ] Escalation goes to product-manager
- [ ] No unilateral pricing change

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Stays within declared domain — designs pricing, never decides it, never implements payment code
- [ ] Escalates conflicts to product-manager
- [ ] Uses "May I write this section to [filepath]?" before file writes, except under the bounded exception; billing changes always go to the user
- [ ] Presents options and unit economics before requesting approval
- [ ] Does not skip tiers in the delegation hierarchy
- [ ] Every rate, fee, commission or legal threshold carries a source line or is marked `NOT DETERMINED`

---

## Coverage Notes

- Payment-rail recommendations (Korean PGs, easy-pay wallets, store billing, merchant of
  record) are checked for sourcing discipline, not for the correctness of current commercial
  terms, which change over time.
- The 선불전자지급수단 question is asserted as an escalation ("needs legal review"), never as a
  legal conclusion.
- Runtime replies are in the user's conversation language; assertions check structure,
  tokens and the canonical English prompts in the agent file.
