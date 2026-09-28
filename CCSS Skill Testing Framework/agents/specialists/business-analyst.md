# Agent Spec: business-analyst

> **Tier**: specialists
> **Category**: specialist
> **Spec written**: 2026-09-28

<!-- Asserts the canonical English text of .claude/agents/business-analyst.md (quoted prompts,
     headings, verdict tokens), never the wording the model uses at run time in the user's
     conversation language. Examples use the canonical product "Moa". -->

## Agent Summary

The business analyst does the 서비스·정책 기획 work of a product team: it turns product
intent into service policy precise enough to implement and test — eligibility, limits and
quotas, fees, refunds and cancellation, object lifecycles as state machines, and
multi-condition policies as decision tables. It owns the PRD section
`## Business Rules & Calculations` and the `rules` / `constants` discipline of
`design/registry/entities.yaml`. `/write-prd` consults it for `## Functional Requirements`
(with product-manager), `## Business Rules & Calculations` and `## Edge Cases` (with
qa-lead); `/prd-review` consults it on rules; `/business-rules-check` spawns it for limits,
fees, rounding and tax arithmetic, and refunds. It uses the Question-First Workflow, has no
Bash, keeps project memory, and owns no director gate. It decides nothing about whether a
feature exists (product-manager), what it costs (monetization-strategist) or how it looks
(product-designer).

**Domain**: Service policy & business rules (서비스·정책 기획): eligibility, limits/quotas, fees, refunds/cancellation, state machines, rule tables — the `## Business Rules & Calculations` section of `design/prd/<feature>.md` and the `rules` / `constants` entries of `design/registry/entities.yaml`
**Escalates to**: product-manager
**Delegates to**: —
**Gates owned**: none

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/business-analyst.md`; frontmatter `name: business-analyst` equals the file stem and the catalog `name`
- [ ] Frontmatter keys in canonical order: `name`, `description`, `tools`, `disallowedTools`, `model`, `maxTurns`, `memory` — no `skills` or `isolation`
- [ ] `description` is one double-quoted line that starts with the domain seed "Service policy & business rules (서비스·정책 기획): eligibility, limits/quotas, fees, refunds/cancellation, state machines, rule tables." and continues with "Use when …"
- [ ] `tools: Read, Glob, Grep, Write, Edit` and `disallowedTools: Bash`
- [ ] `model: inherit`, matching `.claude/docs/model-tiers.md`; `maxTurns: 20`; `memory: project`
- [ ] Opening line after the frontmatter: "You are the Business Analyst for a web/mobile/API product team."
- [ ] The `##` headings of the body are exactly these, in this order:
  1. `## Collaboration Protocol` — contains `### Question-First Workflow` (clarifying questions → 2–4 options with a recommendation → incremental drafting → "May I write this section to [filepath]?"), then the paragraph beginning "**Bounded exception — orchestrated runs.**", verbatim
  2. `## Core Responsibilities`
  3. one `## [Domain] Standards` heading for business rules (currently `## Business Rules Standards`)
  4. `## What This Agent Must NOT Do`
  5. `## Delegation Map`
- [ ] Not a gate owner: the file has **no** `## Gate Verdict Format` section, and no `## Sub-Specialist Orchestration` or `## Version Awareness` section
- [ ] No `### Implementation Workflow` and no implementer question ("Should this be a shared package or module-local helper?") — this role decides before anyone builds
- [ ] The rule output format is mandatory and names all six parts: named expression, variable table (Symbol / Type / Unit / Range / Source / Description), rounding and precision, output range, worked example, boundary cases
- [ ] A lifecycle is specified as a table `From | Event | Guard | To | Side effects`, plus terminal states, invalid transitions with the API error they return, timeouts and an idempotency key for every money-moving or quota-consuming transition
- [ ] Money is an integer amount in the currency's minor unit with an ISO 4217 code (KRW has no minor unit) — never floating point; VAT (부가세) inclusion is stated; business-day boundaries are defined in a named time zone (`Asia/Seoul` for Moa)
- [ ] Every value in a rule is a registry constant, a `## Configuration & Flags` entry with an owner, or a cited legal/partner requirement — never a bare number in prose
- [ ] Registry discipline: reads `design/registry/entities.yaml` sections `entities`, `plans`, `rules`, `constants`, `events`; never deletes an entry (`status: deprecated` instead); proposes a change to a registered value instead of silently contradicting it
- [ ] Regional checks read `.claude/docs/compliance/<region>.md` for each region in `compliance.regions`; unset regions mean ask (unset is not "none"); items are recorded as items to verify, never as legal conclusions, and no deadline, fee cap or threshold is stated without a cited source
- [ ] `## Delegation Map` has exactly three lines: `Reports to: product-manager`, `Delegates to: —`, and `Coordinates with: …`
- [ ] Reporting line: product-manager lists `business-analyst` in its own `Delegates to:` line
- [ ] Every agent named in `Coordinates with:` exists under `.claude/agents/`
- [ ] Domain clearly stated; product direction and priority (product-manager), prices, plans and promotions (monetization-strategist), screens (product-designer), customer-facing copy (ux-writer) and implementation code are stated as outside it
- [ ] Escalation path documented: product intent → product-manager (then product-director); prices → monetization-strategist; cross-service transactions or data-model changes → tech-lead; legal interpretation → the user, flagged "needs legal review"
- [ ] Does not make decisions outside its domain

---

## Test Cases

### Case 1: In-Domain Request — Plus upgrade proration rule

**Scenario**: The product manager asks the business analyst to specify what a Free user
pays when upgrading to Plus in the middle of a billing period.

**Fixture**:
- `design/prd/subscription.md` (Status `Draft`) with `## Business Rules & Calculations` empty
- `design/registry/entities.yaml` registers the constant `plus_monthly_price` (source `design/prd/subscription.md`)
- `design/product/pricing-model.md` exists; `compliance.regions: [kr]`

**Expected behavior**:
1. Asks clarifying questions first: currency and rounding mode, VAT inclusion, the time zone of the period boundary, what happens on the last day of the period and on a retried upgrade request
2. Presents 2–4 options (e.g. prorate by remaining days; charge the full price and restart the period; start Plus at the next renewal) with operating and support costs, recommends one and defers the choice to the user
3. Drafts the chosen rule in the mandatory format: named expression, variable table whose `plus_monthly_price` row cites the registry constant as its Source, rounding stated (integer KRW, floor or half-up, applied once on the total), output range, a worked example with each step, and boundaries (last day of the period, 28–31-day months, concurrent upgrade requests)
4. Asks "May I write this section to [filepath]?" naming `design/prd/subscription.md` before writing the section

**Assertions**:
- [ ] Clarifying questions and options come before any drafted rule
- [ ] All six parts of the rule output format present; no floating-point money; KRW treated as having no minor unit
- [ ] The price is referenced from the registry, not restated as a new number
- [ ] Section written only after approval, one section at a time

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Out-of-Domain Redirect — price change and upgrade screen

**Scenario**: A stakeholder asks the business analyst to "set Plus to 5,900 KRW a month,
design the upgrade screen, and write the upgrade button label".

**Fixture**:
- Same project as Case 1; no pending pricing decision recorded in `design/product/pricing-model.md`

**Expected behavior**:
1. Identifies three out-of-domain parts: the price itself, the screen and the copy
2. Redirects the price to monetization-strategist (and the decision to the product manager and user), the screen to product-designer, the label to ux-writer
3. Offers what is in its domain: the rule consequences of a price change (proration, grandfathering of existing Plus subscribers, the registry constant that would change)
4. Changes no price constant, screen spec or copy

**Assertions**:
- [ ] Declines and redirects instead of silently handling cross-domain work
- [ ] monetization-strategist, product-designer and ux-writer named as the correct agents
- [ ] No registry constant or PRD value changed

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Consultation — `/business-rules-check` limits, fees and refunds (no gate verdict)

**Scenario**: `/business-rules-check payments` spawns the business analyst in parallel with
monetization-strategist, briefing it inline with the rule inventory and the resolved
`compliance` line, and ends with the return contract "Do not write any file. Return only
(1) findings as rows `Domain | Severity | Finding | Evidence | Recommendation` …".

**Fixture**:
- Rule inventory: `max_auto_debit_retries = 2`; refund rule "Plus cancelled within 7 days is refunded in full"; `prorated_upgrade_charge` worked example 4,900 × 12 / 30 = 1,960 KRW
- Resolved line `compliance: regions=kr handles_pii=true (project.yaml)`
- One worked example in the inventory is arithmetically wrong (a rounding step applied per line item in the text and on the total in the example)

**Expected behavior**:
1. Covers its assigned domains only: limits and quotas, fees and rounding and tax arithmetic, refunds and cancellation, and recomputation of every worked example
2. Recomputes each worked example and reports the inconsistent rounding step as a finding with its evidence
3. Lists the `kr` refund and cancellation disclosure items that the rules touch as items to verify, with no stated legal deadline lacking a source
4. Writes no file and returns only the findings rows, a ≤5-bullet summary and BLOCKED items; emits no `[GATE-ID]: TOKEN` line

**Assertions**:
- [ ] Return contract honoured — no file written
- [ ] Every worked example recomputed; the rounding inconsistency found
- [ ] Pricing ladder, promotion stacking, credits economy and abuse vectors left to monetization-strategist
- [ ] No gate verdict token emitted

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Conflict Escalation — referral trial versus first-month coupon

**Scenario**: The business analyst's trial-eligibility decision table grants an extended
Plus trial to referred users, while monetization-strategist has drafted a first-month-free
coupon that the growth plan wants stackable with the referral trial.

**Fixture**:
- Decision table in `design/prd/subscription.md` (Had Plus before × Joined via referral × Identity verified → Trial)
- Pricing model draft with the stackable coupon; no precedence rule anywhere

**Expected behavior**:
1. Shows that the two policies overlap: a referred, verified new user would get the extended trial and then a free first paid month, which the table does not cover
2. Proposes precedence options (no stacking; the longer benefit wins; stack with a cap) and the abuse vector each opens
3. Escalates the decision to product-manager, the shared parent of both roles, instead of editing the coupon or the table unilaterally

**Assertions**:
- [ ] Conflict surfaced explicitly, with the uncovered combination named
- [ ] Escalated to product-manager
- [ ] Neither the pricing model nor the decision table changed without a decision

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Context Pass-Through — `/write-prd goals` business rules

**Scenario**: `/write-prd goals` consults the business analyst on
`## Business Rules & Calculations`, the section being worked on, passing the approved
sections, the registry facts from its Phase 2 and the specific question. `/write-prd`
consultants return analysis and proposals and write no files; the skill owns every write.

**Fixture**:
- Brief passed inline: goal creation flow from `## Functional Requirements`, registered constants `min_goal_amount` and `max_active_goals_free`, the `goals.v2-progress-ring` flag in `## Configuration & Flags`
- `design/prd/goals.md` already exists as the skeleton written by `/write-prd`

**Expected behavior**:
1. Uses the passed constants and flow without re-asking for them
2. Returns rules in the mandatory format (e.g. goal amount ≥ `min_goal_amount`; Free plan active-goal limit; what happens to goals above the limit on a Plus → Free downgrade — read-only, never deleted), with boundary cases (concurrent creation at the limit, retry after timeout, period boundary at 00:00 KST)
3. Writes no file and returns the draft to the skill: `design/prd/goals.md` is an existing file under `design/`, outside the bounded exception, and the skill's brief makes it the writer

**Assertions**:
- [ ] Provided context used rather than re-requested
- [ ] Result scoped to the section it was asked for
- [ ] No file written; the draft is returned to `/write-prd` (the bounded exception covers only new files under `production/`, `docs/` or `tests/`)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: NOT ASSESSED — refund rule without regions or plan price

**Scenario**: The business analyst is asked to "finalize the Plus cancellation and refund
rule today".

**Fixture**:
- `compliance.regions` unset in `project.yaml`
- No `plus_monthly_price` in the registry and no `design/product/pricing-model.md`

**Expected behavior**:
1. Does not treat the unset regions as "no regulation" (unset is not "none"): asks which regions apply and states that the regional check did not run because `compliance.regions` is unset
2. States that the amounts depending on the missing price cannot be determined until the price is registered, instead of inventing a price
3. States no statutory withdrawal period or refund deadline from memory; any requirement it mentions carries a cited source or is listed as an item to verify
4. Drafts only the parts that do not depend on the missing inputs (states and transitions of a cancellation) and says the rule is not ready for approval

**Assertions**:
- [ ] Unset regions treated as unknown, not as none
- [ ] No fabricated price, deadline or legal threshold
- [ ] The missing inputs are named explicitly

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: In-Domain Request — auto-debit run state machine

**Scenario**: The business analyst specifies the lifecycle of a Moa auto-debit run for
`design/prd/payments.md` (Toss Payments recurring billing).

**Fixture**:
- Registered constant `max_auto_debit_retries = 2`; events `auto_debit_succeeded`, `auto_debit_failed` registered
- The PRD's `## Functional Requirements` describes scheduled runs, PG failures and suspension

**Expected behavior**:
1. Writes the lifecycle as a `From | Event | Guard | To | Side effects` table (scheduled → requested → succeeded / retry_scheduled / suspended)
2. Names terminal states, invalid transitions and the problem+json `type` the API returns for them (agreed with tech-lead), timeouts for runs stuck in `requested`, and the idempotency key per attempt (at most one run per goal and run date)
3. Uses the registered retry constant and events instead of new values, and asks before adding any new registry entry

**Assertions**:
- [ ] Table format with guards and side effects
- [ ] Terminal states, invalid transitions, timeouts and idempotency all stated
- [ ] Registered constant and events reused; registry additions proposed, not silently made

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Stays within declared domain — explicitly scopes itself to service policy and business rules (specialist S1)
- [ ] Makes no binding decision on prices, product scope, screens or copy owned by another agent (specialist S2)
- [ ] Out-of-domain requests redirected to the correct agent, not refused silently (specialist S3)
- [ ] Escalates conflicts to product-manager; legal questions go to the user as "needs legal review"
- [ ] Uses `"May I write this section to [filepath]?"` before file writes, except under the bounded exception (never under `design/`)
- [ ] Presents options and reasoning before requesting approval; never runs commands (no Bash)

---

## Coverage Notes

- Promotion stacking, the pricing ladder and the credits economy belong to
  monetization-strategist and are covered in its spec; this spec checks only that the
  business analyst hands them over.
- Registry write mechanics (entry shape, `referenced_by:` block lists) are asserted
  statically; a live run of `/write-prd` or `/consistency-check` exercises them end to end.
- `/prd-review` consultation on rules is not a separate case: its return behaviour matches
  Case 3.
