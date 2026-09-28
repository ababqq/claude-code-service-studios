---
name: business-rules-check
description: "Pricing ladder, limits/quotas, fees & rounding, promotion stacking, credits economy, refund rules, abuse vectors."
argument-hint: "[feature-slug | pricing | <path-to-file> | full]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/business-rules-check/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,compliance`

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

# Business Rules Check

Checks that the product's money and policy rules are consistent, computable and hard
to abuse: the pricing ladder, limits and quotas, fees and rounding (including currencies
without a minor unit such as KRW, and VAT-inclusive display), promotion and coupon
stacking, the credits economy (issuance and redemption), refund and cancellation rules,
and abuse vectors. It reads the rules where the product defines them — PRD
`## Business Rules & Calculations` sections, the pricing model, the glossary registry
and config tables — and compares every source with every other.

| Output | Path |
|--------|------|
| Report (with the verdict line) | `production/qa/business-rules/business-rules-check-<scope>-YYYY-MM-DD.md` |

**When to run:** in Hardening (catalog step `business-rules-check`), before a pricing
or plan change ships, after a PRD that defines prices, limits or refunds is revised, and
when usability or support evidence shows users confused by what they pay.

This skill checks documents and configuration. It does not change prices, plans or
promotions, and it does not read application source — rules hard-coded in source are
found by `/code-review` and `/tech-debt`.

Verdict vocabulary (exact): `PASS | CONCERNS | FAIL | NOT ASSESSED`.

---

## Insufficient input — check this before producing any report

**If the inputs this skill needs do not exist, the answer is "could not run" —
not a filled-in report.** Check first, and stop if the check fails.

1. List the inputs this skill reads (PRD business-rules sections, the pricing model,
   the registry, config tables, regional compliance references, prior reports).
2. For each, record `FOUND` or `ABSENT` — not "assumed present".
3. If any input required for a section is ABSENT, that section is
   **`NOT ASSESSED — NO DATA`**. Do not estimate it, do not infer it from an
   adjacent artifact, and do not leave a mandated cell to be filled by whoever
   reads the template next.
4. If **every** required input is ABSENT, stop and report
   **`NOT ASSESSED — NO DATA`** as the whole verdict, naming what was missing and
   which skill produces it (`/write-prd` for PRDs and the pricing model).

**A verdict of `NOT ASSESSED` is a success.** It is the correct, useful answer to
"what does the data say?" when there is no data. The failure mode this prevents is
specific: report templates whose verdict enum had no "could not run" state produced
**false clean passes** — a check returning a healthy result on a product with no
written rules, because nothing contradicted nothing.

**Absence of evidence is never evidence of absence.** Finding no contradiction because
only one source exists has not verified anything. Say which of the two happened.

---

## Phase 0: Resolve Configuration

The resolved `compliance` line carries `compliance.regions`:

- `regions=kr,…` → the regional items of each listed region are checked (Phase 3h);
- `regions=none` (an explicit `[]`) → no regional items; say so in the report;
- `(unset -- ask)` → ask with `AskUserQuestion` which regions the product sells in
  (`kr` / `eu` / `us` / none). Unset is not "none" — without an answer, the regional
  checklist is `NOT ASSESSED — compliance.regions unset`.

The `handles_pii` part of the line is not used by this skill.

---

## Phase 1: Scope

| Argument | Scope | `<scope>` in the file name |
|----------|-------|----------------------------|
| `<feature-slug>` (e.g. `subscription`) | That PRD, plus every PRD, registry entry and pricing-model row it shares a rule with | the slug |
| `pricing` | `design/product/pricing-model.md` and every PRD it cites | `pricing` |
| `<path-to-file>` (a PRD, the pricing model or a config table) | That file and the sources it shares rules with | the file's stem |
| `full` or no argument | Every source below | `full` |

Announce the scope in one line before reading.

---

## Phase 2: Gather the Rules

**Registry first.** If `design/registry/entities.yaml` exists, read its `plans`,
`rules` and `constants` sections before any PRD — they hold the cross-PRD named values
already distilled, each with its owning PRD in `source:`:

```
Grep pattern="^  - name:" path="design/registry/entities.yaml" output_mode="content" -A 6
```

Keep the entries that sit under `plans:`, `rules:` or `constants:`. An entry with
`status: deprecated` that a current PRD still references is a finding (Medium). If the
registry does not exist or has no entries (it starts empty until `/write-prd` fills
it), skip this step and rely on the PRDs — the check is unchanged, only more expensive.

**PRD business-rules sections.** Find which PRDs carry the section, with the tolerant
heading form every reader of the PRD contract uses (optional numeric prefix,
case-insensitive):

```
Grep pattern="^##+[[:space:]]+([0-9]+[.)][[:space:]]+)?Business Rules & Calculations" glob="design/prd/*.md" -i output_mode="files_with_matches"
```

Establish the denominator: Glob `design/prd/*.md`. For each in-scope PRD, read
`## Business Rules & Calculations`, `## Configuration & Flags` (limits exposed to
operations), `## Edge Cases` (refund, retry and downgrade cases) and
`## Acceptance Criteria` (worked examples to recompute). **Fail open:** a PRD without the
section is still in scope — grep it for money and limit language
(`₩|KRW|USD|%|price|plan|limit|quota|refund|coupon|promotion|point|credit|환불|쿠폰|포인트|요금`)
and report any rule stated outside the contract section (Medium: a rule outside
`## Business Rules & Calculations` is invisible to every reader of that section).

**Pricing model.** Read `design/product/pricing-model.md` (written by `/write-prd` from
`.claude/docs/templates/pricing-model.md`): `## Plans & Price Points`,
`## Entitlements`, `## Usage Metering & Credits`, `## Promotions & Coupons`,
`## Taxes & Currency`, `## Refunds & Cancellation`, `## Abuse Vectors`. **If it is absent
while any PRD defines plans, prices, credits or promotions, that is CONCERNS** — point to
`/write-prd <feature>` for the PRD that defines them.

**Config tables.** Glob `config/**/*.{json,yaml,yml}` and any path a PRD's
`## Configuration & Flags` names (plan tables, limit tables, promotion definitions).
Values held only in a remote configuration or feature-flag service are
`NOT CHECKED — <key> lives in <service>; provide an export to compare`.

**Build the rule inventory**: one row per named rule or value (plan price, limit,
fee, rounding rule, promotion value, credit amount, refund rule), with its value in
every source that states it. A value stated in two sources that disagree is a finding
whose severity depends on what it affects (Phase 4).

---

## Phase 3: Analyze

Spawn **`business-analyst`** and **`monetization-strategist`** via `Agent` in parallel
(issue both calls before waiting). Brief each inline with the rule inventory and the
relevant section text — never a path to a file you have already read — plus the
resolved `compliance` line. End each prompt with the return contract: *"Do not write any
file. Return only (1) findings as rows `Domain | Severity | Finding | Evidence |
Recommendation`, using the severity definitions given, (2) a ≤5-bullet summary,
(3) BLOCKED items, one line each."*

- `business-analyst` owns 3b limits and quotas, 3c fees, rounding and tax arithmetic,
  3f refunds and cancellation, and the recomputation of every worked example.
- `monetization-strategist` owns 3a the pricing ladder, 3d promotions and stacking,
  3e the credits economy and 3g abuse vectors.

If an agent is BLOCKED or errors, surface it, run its domains yourself, and write
`<agent> not consulted — <reason>` in the report.

### 3a. Pricing ladder

- Each higher plan includes every entitlement of the plan below; no plan is strictly
  dominated by a cheaper one.
- Monthly and annual prices agree with the stated discount (recompute it); the same
  plan's price agrees across the pricing model, the PRD, the registry and config.
- Channel differences (web payment gateway vs App Store / Google Play) are intentional
  and recorded; store-managed subscriptions follow the store's price-change flow.
- Grandfathering and price-change notice are defined.

### 3b. Limits and quotas

- The same limit has the same value everywhere (PRD, pricing model, registry, config,
  the API's documented rate limits).
- Boundary semantics are explicit (`≤` vs `<`; is the 3rd goal allowed on Free?).
- Reset windows name their timezone — a monthly quota that resets at UTC midnight resets
  at 09:00 in Korea; for a Korean product say `Asia/Seoul`.
- Downgrade and over-limit states are defined (what happens to the 5th goal when Plus
  lapses?), and every paid limit is enforced server-side.

### 3c. Fees, rounding and tax

- **Money is integer minor units** — KRW has no minor unit (whole won), USD has two
  decimals. A rule or example implying fractional won, or floating-point arithmetic, is
  a finding.
- Rounding mode, precision (e.g. to KRW 10 after a percentage discount) and **where** it
  is applied (per line or per invoice, once) are stated — and the worked examples obey
  them. Recompute every example from its rule.
- Tax: consumer prices displayed tax-inclusive where the region requires it; the split
  of a tax-inclusive price into supply value and tax, and its rounding direction, is
  stated and matches the receipt issuer (the payment gateway, the store, or the company's
  invoicing). An unstated split is Medium, not a guess.
- Percentage fees (payment gateway, store commission) and who bears them are consistent
  with reported revenue figures.

### 3d. Promotions and stacking

- Order of application is stated (percentage before fixed, before points, …), the charge
  has a floor (never below zero, or a minimum charge), and "stacks with" is symmetric
  between promotions.
- Eligibility is testable: what counts as a "new user" — account, verified identity,
  payment method or device?
- Limits per account and per identity; expiry and time zone of the validity window.
- Refunding a discounted payment refunds the amount actually paid; the promotion's
  reuse after a refund is defined.
- Promotions delivered as messages (push, e-mail, SMS, KakaoTalk) carry the consent
  requirements of the configured regions (3h).

### 3e. Credits economy (issuance / redemption)

- Every issuance channel and every redemption or expiry path is listed; the balance
  invariant holds: balance = Σ issued − Σ redeemed − Σ expired, never negative.
- Issuance is idempotent per triggering event; redemption order is defined (earliest
  expiry first); caps per account exist where issuance is unbounded.
- The rate of issuance against redemption does not create a growing outstanding
  liability; breakage assumptions are stated with a source.
- Transferability and cash-out are explicit; where a configured region regulates prepaid
  instruments, the classification question is answered or listed as open (3h).

### 3f. Refunds and cancellation

- Each case has a rule, an amount (with a worked example) and the entitlement afterwards:
  mid-period cancellation, annual-plan cancellation, withdrawal before use, failed
  auto-debit (retry schedule, grace period, downgrade), refunds after promotions or
  points, chargebacks.
- In-app purchases: the store, not the product, grants refunds; the product revokes the
  entitlement on the store's refund notification — a rule that promises the product will
  refund a store purchase itself is a finding.
- The subscription lifecycle is a complete state machine (trialing → active → past-due →
  canceled / expired, and back), with no state lacking an exit.

### 3g. Abuse vectors

For each rule that grants value, ask how it could be extracted more than intended:
trial farming across accounts, referral self-dealing, coupon enumeration, parallel
requests redeeming the same coupon or points twice, refund-and-keep, region or channel
arbitrage, limits bypassed by concurrent requests. Each vector needs a control and a
detection signal; a vector with no control that extracts unbounded value is Critical.
Controls that need engineering (idempotency keys, row locks, rate limits) go to
`/security-audit` as well.

### 3h. Regional checklist (only for the regions resolved in Phase 0)

For each region, read `.claude/docs/compliance/<region>.md` — its
`## Commerce & Payments` section, and `## Marketing Messages & Consent` when promotions
are messaged. For `kr` this covers, among others, cancellation and refund disclosures
under the E-Commerce Act (전자상거래법), whether points or credits are prepaid
electronic payment means (선불전자지급수단) under the Electronic Financial Transactions
Act (전자금융거래법), and in-app payment rules. List each item that applies to a rule in
scope as `resolved (where)`, `open — needs <who>` or `N/A (why)`. Deadlines, fees and
thresholds come only from the compliance file or from a source cited with its retrieval
date — never from memory; an item that needs a number nobody sourced is
`NOT SOURCEABLE — <what>`. A missing region file is
`NOT CHECKED — .claude/docs/compliance/<region>.md not found`.

---

## Phase 4: Score

**Severity of each finding:**

| Severity | Meaning |
|----------|---------|
| Critical | Charges, refunds or credits the wrong amount on a normal path (a worked example contradicts its rule; sources disagree on a charged amount), or an uncontrolled abuse vector with unbounded value |
| High | A wrong money or entitlement outcome on an edge path (downgrade, retry, refund after a promotion); a paid limit not enforced server-side; a rule contradicting an applicable regional item |
| Medium | Ambiguity that will be implemented inconsistently (rounding, timezone, boundary unstated); a rule outside the contract section; a deprecated registry value in use; a weakly controlled abuse vector; an open regional item |
| Low | Clarity and documentation |

**Verdict** (precedence **FAIL > CONCERNS > NOT ASSESSED > PASS**):

- `FAIL` — any Critical or High finding;
- `CONCERNS` — any Medium finding, or the pricing model is absent while a PRD defines
  pricing;
- `NOT ASSESSED` — nothing above, but a domain in scope could not be checked (no rules
  written for it, sources unavailable, regions unset), or the whole scope has no rules;
- `PASS` — every domain in scope checked against at least two agreeing sources (or one
  source with recomputed examples), no finding above Low.

---

## Phase 5: Write the Report

Present the findings, then ask: "May I write this to
`production/qa/business-rules/business-rules-check-<scope>-YYYY-MM-DD.md`?" Create the
directory if absent; ask before overwriting a same-day report for the same scope.

```markdown
# Business Rules Check: [scope]

> **Verdict**: [PASS | CONCERNS | FAIL | NOT ASSESSED]

> **Date**: [YYYY-MM-DD]
> **Scope**: [feature slug | pricing | path | full]
> **Regions**: [resolved compliance line — or "none (explicit)"]
> **Consulted**: [business-analyst, monetization-strategist — or "<agent> not consulted — <reason>"]
> **Generated by**: /business-rules-check

## Sources

| Source | Path | Status | Notes |
|--------|------|--------|-------|
| Registry | `design/registry/entities.yaml` | [FOUND / ABSENT] | [plans: n, rules: n, constants: n] |
| Pricing model | `design/product/pricing-model.md` | [FOUND / ABSENT] | |
| PRD | `design/prd/[slug].md` | [FOUND] | [section present: yes/no] |
| Config | `config/[file]` | [FOUND] | |

## Rule Inventory

| Rule / value | Registry name | PRD | Pricing model | Config | Consistent |
|--------------|---------------|-----|---------------|--------|------------|
| Plus monthly price | [plus_monthly_price] | [₩4,900] | [₩4,900] | [4900] | [yes] |

## Findings

| ID | Domain | Severity | Finding | Evidence | Recommendation |
|----|--------|----------|---------|----------|----------------|
| BR-01 | [Pricing ladder / Limits & quotas / Fees, rounding & tax / Promotions & stacking / Credits economy / Refunds & cancellation / Abuse vectors] | [Critical / High / Medium / Low] | [..] | [sources and the recomputed example] | [..] |

## Domain Summary

| Domain | Checked | Sources | Highest severity |
|--------|---------|---------|------------------|
| Pricing ladder | [yes / NOT ASSESSED — reason] | [..] | [..] |

## Regional Checklist

| Region | Item (from the compliance reference) | Applies to | Status | Evidence |
|--------|--------------------------------------|------------|--------|----------|

## Recommendations

1. [Highest-severity fix first — which document changes, and the skill that changes it]

## Not Checked

- [Every source, domain or region not checked, with its reason]
```

After writing, confirm the file exists and the verdict line sits directly under the H1.

---

## Phase 6: Fix and Verify

`AskUserQuestion`:
- Prompt: "Business rules check complete. What next?"
- Options:
  - `Walk through the highest-severity finding now`
  - `Stop here — I'll review the report`

If walking through a finding: name the source document to change and the skill that
changes it — this skill edits no PRD, pricing model or registry. A PRD or pricing-model
change goes through `/write-prd <feature>`; after any PRD change, run
`/propagate-prd-change design/prd/<feature>.md` before committing so ADRs, the API
contract, stories and the tracking plan follow; registry drift goes through
`/consistency-check`. Then offer to rerun `/business-rules-check <same scope>` to verify
that no new contradiction was introduced.

### Next steps

Use `AskUserQuestion` with the options that apply:

- `/write-prd <feature>` — fix the rule at its source (Recommended for Critical/High)
- `/propagate-prd-change design/prd/<feature>.md` — after a PRD changed
- `/consistency-check` — registry values drifting from PRDs
- `/security-audit` — abuse vectors that need engineering controls
- `/quick-spec` — a small config or limit change with a rollout note
- `/bug-report` — implemented behaviour contradicts the documented rule
- `Stop here`

---

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and `autonomous`
modes, see `.claude/docs/automation-modes.md`.

- **Recompute, don't trust** — every worked example is recomputed from its rule; a
  number that cannot be recomputed is a finding.
- **Regional facts are sourced** — only from `.claude/docs/compliance/<region>.md` or a
  cited, dated source; this report is not legal advice and says so when an item needs
  counsel.
- **Report, don't edit** — fixes happen in the source documents through their owning
  skills.
- Ask "May I write this to `<path>`?" before writing; this skill writes only its report.
