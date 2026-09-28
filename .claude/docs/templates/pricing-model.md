# Pricing Model: [Product Name]

> **Status**: Draft | In Review | Approved | Live
> **Owner**: [monetization-strategist, with business-analyst for rules and refunds]
> **Last Updated**: [YYYY-MM-DD]
> **Last Verified**: [YYYY-MM-DD — when the live configuration was last compared with this document]
> **Currencies**: [e.g. KRW (no minor unit) — USD (2 decimals) if sold abroad]
> **Regions**: [values of `compliance.regions`, e.g. `kr`]
> **Defining PRDs**: [e.g. `design/prd/subscription.md`, `design/prd/payments.md`]
> **Registry**: plans, rules and constants below are mirrored in `design/registry/entities.yaml` (`plans`, `rules`, `constants`)

<!-- Created by /write-prd when a PRD defines plans, prices, credits or promotions;
     updated by /write-prd when those PRDs change; read by /business-rules-check.
     One document per product. Every number here must match the owning PRD's
     "## Business Rules & Calculations" section and the registry entry that carries
     it — /business-rules-check reports any mismatch.
     Keep the seven "##" headings exactly as written (they are matched by skills);
     write the body in the team's working language.
     Regional legal items (refund windows, prepaid-means classification, tax
     receipts) come only from .claude/docs/compliance/<region>.md for the regions
     in compliance.regions — never from memory. Numbers in [brackets] below are
     illustrative placeholders, not recommendations. -->

## Plans & Price Points

[Every plan the product sells, on every channel it is sold through. A price shown to
customers is written exactly as displayed (tax-inclusive where the region requires it).]

| Plan | Registry plan · price constant | Display price | Billing period | Channel | Trial | Available in | Status |
|------|---------------|---------------|----------------|---------|-------|--------------|--------|
| Free | `free` · — | ₩0 | — | — | — | [kr] | [Live] |
| Plus (monthly) | `plus` · `plus_monthly_price` | [₩4,900 / month, VAT incl.] | monthly, renews on the start date | [card or bank auto-debit via the PG (web) · App Store · Google Play] | [e.g. 14 days, once per account] | [kr] | [Draft] |
| Plus (annual) | `plus` · `plus_annual_price` | [₩49,000 / year, VAT incl.] | annual | [same channels] | [none] | [kr] | [Draft] |

### Ladder Rules

- [Each higher plan includes every entitlement of the plan below it — no plan is
  strictly worse than a cheaper one.]
- [Annual discount: state it one way and show the arithmetic, e.g. ₩4,900 × 12 =
  ₩58,800 a year at the monthly price; ₩49,000 = ₩4,900 × 10, so "2 months free" and
  "16.7 % off" describe the same price — marketing copy must use a claim that matches.]
- [In-app prices: store price points and the store's commission mean the in-app list
  price may differ from the web price — record both and the reason.]

### Price Changes & Grandfathering

- [How existing subscribers are treated when a price changes: grandfathered until
  [date], or migrated at their next renewal after notice.]
- [Notice and consent requirements for price increases per region — from the regional
  compliance reference, with its source.]
- [Store-managed subscriptions follow the store's price-change flow; name it.]

## Entitlements

[What each plan unlocks, where it is enforced, and what happens at the boundaries.
A limit that is not enforced server-side is not a limit.]

| Entitlement | Free | Plus | Enforced where | Limit semantics | Reset window (timezone) | On downgrade |
|-------------|------|------|----------------|-----------------|-------------------------|--------------|
| Active savings goals | [3] | [unlimited] | [API: create-goal operation] | [a 4th create is rejected with a problem+json error] | [—] | [existing goals stay; creating a new one is blocked until under the limit] |
| Auto-debit rules per goal | [1] | [5] | [API] | [≤ limit] | [—] | [extra rules paused, not deleted] |
| Goal insights report | [—] | [✓] | [API + UI] | [—] | [monthly, 1st 00:00 Asia/Seoul] | [access ends at period end] |

- **Source of truth for the current plan**: [billing service record / store receipt
  validation — never the client].
- **Grace behaviour**: [what a user keeps while a payment is being retried].

## Usage Metering & Credits

### Metered Usage

[Only when something is counted and billed or limited by usage.]

| Meter | Unit | Counted when | Aggregation window (timezone) | Idempotency key | Source of truth |
|-------|------|--------------|-------------------------------|-----------------|-----------------|
| [Goal insight exports] | [export] | [export file delivered, not requested] | [calendar month, Asia/Seoul] | [export request ID] | [billing ledger table] |

### Credits (issuance / redemption)

[Points, credits or rewards the product issues. Every issuance channel and every
redemption or expiry path is listed — the balance must be explainable from these rows.]

| Credit | Issued by | Amount | Expiry | Redeemable for | Cap per account | Transferable | Cash-out |
|--------|-----------|--------|--------|----------------|-----------------|--------------|----------|
| [Moa points] | [goal completed · referral that converts to a paid plan] | [500 · 1,000 points] | [12 months after issue] | [discount on Plus renewal, 1 point = ₩1] | [10,000 points] | [No] | [No] |

- **Balance invariant**: balance = Σ issued − Σ redeemed − Σ expired, never negative.
- **Issuance is idempotent** per triggering event (a retried "goal completed" event does
  not issue twice).
- **Redemption order**: [earliest-expiring first].
- **Refund interaction**: [points used on a refunded payment are restored / forfeited].
- **Liability and breakage**: [how outstanding points are accounted for; expected breakage
  and its source].
- **Regulatory classification**: [whether these credits can count as a regulated prepaid
  payment instrument in a configured region — for `kr`, the prepaid electronic payment
  means (선불전자지급수단) question of the Electronic Financial Transactions Act listed in
  `.claude/docs/compliance/kr.md` § Commerce & Payments. Record the answer and who
  confirmed it (legal counsel, PG), or `NOT DETERMINED — needs legal review`.]

## Promotions & Coupons

| Promotion | Type | Value | Eligibility | Stacks with | Limit | Valid | Funding |
|-----------|------|-------|-------------|-------------|-------|-------|---------|
| [WELCOME] | [percentage off first payment] | [50 %] | [accounts with no previous paid plan, identity-verified phone] | [points: yes · referral: no] | [once per verified identity] | [2026-11-01 – 2026-12-31] | [marketing budget] |
| [Referral] | [points] | [1,000 points to referrer when the referee pays] | [referee is a new verified identity] | [WELCOME: no] | [20 referrals per account per year] | [always] | [growth budget] |

### Stacking Rules

1. [Order of application, e.g. percentage discounts → fixed discounts → points.]
2. [Floor: the charged amount never goes below ₩0 (or a stated minimum charge).]
3. [At most one coupon per payment; promotions marked "no" above never combine.]
4. [Rounding applied once, after all discounts — see Taxes & Currency.]

### Worked Example

[One end-to-end example per stacking path, with every intermediate value:
Plus monthly ₩4,900 − 50 % WELCOME = ₩2,450 − 1,000 points = ₩1,450 charged
(rounding rule: none needed — already a whole won).]

## Taxes & Currency

- **Display**: [prices shown to consumers are VAT-inclusive in `kr`; state the rule for
  each region sold in].
- **Tax split**: [how the tax-inclusive price is split into supply value and VAT, the
  rounding direction, and which system issues the receipt (the PG, the store, the
  company's own invoicing) — confirm with the PG or the accountant; do not assume].
- **Currency and minor units**: [KRW has no minor unit — store amounts as integer won;
  USD has 2 decimals — store integer cents. Never use floating point for money.]
- **Rounding**: [mode (half-up / half-even / down), precision (e.g. KRW 10 for
  percentage discounts), and where it is applied (per line / per invoice) — once].
- **Foreign exchange**: [none | rate source, when the rate is fixed, who bears the
  difference].
- **Store channels**: [App Store / Google Play set the customer price and collect tax in
  many regions; the product receives proceeds after commission — record which figures
  reports use].
- **Receipts**: [consumer receipts, and B2B invoices where applicable, per the regional
  compliance reference].

## Refunds & Cancellation

| Case | Channel | Rule | Amount refunded | Entitlement afterwards | Source |
|------|---------|------|-----------------|------------------------|--------|
| Cancel monthly plan mid-period | web (PG) | [renewal stops; no partial refund] | [₩0] | [Plus until period end] | [PRD `subscription`] |
| Withdrawal before any use | web (PG) | [per the regional compliance reference] | [full] | [ends immediately] | [`.claude/docs/compliance/kr.md` § Commerce & Payments] |
| Cancel annual plan | web (PG) | [pro-rata by unused full months, minus the annual discount] | [formula with a worked example] | [ends immediately] | [PRD] |
| In-app purchase refund | App Store / Google Play | [the store decides; the product cannot refund store purchases itself] | [—] | [revoked on the store's refund notification] | [store documentation] |
| Failed auto-debit | web (PG) | [retry schedule, grace period, then downgrade to Free] | [—] | [Plus during grace; Free after] | [PRD `payments`] |
| Refund of a discounted payment | any | [refund the amount actually paid, never the list price; points used are restored or forfeited per Credits] | [amount paid] | [..] | [PRD] |

- **Cancellation path**: [where users cancel — at least as easy as signing up, where a
  configured region requires it].
- **Chargebacks and disputes**: [effect on entitlements and on credits].

## Abuse Vectors

[How someone could extract value the pricing did not intend, and what stops them.]

| Vector | Example | Control | Detection signal | Residual risk |
|--------|---------|---------|------------------|---------------|
| Trial farming | [new accounts with fresh e-mail addresses to repeat the trial] | [one trial per verified identity / payment method] | [trials per payment method or device] | [..] |
| Referral self-dealing | [referring one's own second account] | [reward only when the referee pays; identity dedupe] | [referrer and referee share a device or payment method] | [..] |
| Coupon enumeration | [guessing codes] | [non-sequential codes; rate limit on redemption] | [failed redemptions per account or IP] | [..] |
| Double redemption race | [two parallel requests redeem the same coupon or points] | [idempotency key + row lock or unique constraint] | [duplicate redemptions in the ledger] | [..] |
| Refund-and-keep | [refund a payment and keep the entitlement or points] | [entitlement revoked on refund; points clawed back] | [refunds per account] | [..] |
| Region or channel arbitrage | [buying in a cheaper channel or region] | [price parity rules; region checks] | [..] | [..] |
| Limit bypass | [parallel creates past a plan limit] | [limit enforced in one transaction server-side] | [accounts above their limit] | [..] |
