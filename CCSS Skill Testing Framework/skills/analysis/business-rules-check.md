# Skill Spec: /business-rules-check

> **Category**: analysis
> **Priority**: low
> **Spec written**: 2026-09-28

## Skill Summary

`/business-rules-check` checks that the product's money and policy rules are
consistent, computable and hard to abuse. It reads every place the product states
them — PRD `## Business Rules & Calculations` sections (and rules stated elsewhere in
a PRD), `design/product/pricing-model.md`, the `plans`, `rules` and `constants`
sections of `design/registry/entities.yaml`, and config tables — builds a rule
inventory, and spawns `business-analyst` and `monetization-strategist` in parallel to
analyse seven domains: pricing ladder, limits and quotas, fees/rounding/tax (money in
integer minor units — KRW has none; VAT-inclusive display), promotions and stacking,
the credits economy (issuance and redemption), refunds and cancellation, and abuse
vectors. Each region in `compliance.regions` adds its checklist from
`.claude/docs/compliance/<region>.md`. It writes
`production/qa/business-rules/business-rules-check-<scope>-YYYY-MM-DD.md` with the
verdict line `PASS | CONCERNS | FAIL | NOT ASSESSED` (precedence FAIL > CONCERNS >
NOT ASSESSED > PASS). A pricing PRD with no pricing model is CONCERNS with a pointer
to `/write-prd <feature>`. It is the optional Hardening catalog step
`business-rules-check`, edits no source document and spawns no director gate.

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`); `name: business-rules-check` equals the skill directory, the catalog `name` and this spec's basename
- [ ] `description` is "Pricing ladder, limits/quotas, fees & rounding, promotion stacking, credits economy, refund rules, abuse vectors."
- [ ] Bootstrap: the first body line is `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,compliance` `` — exactly these two labels
- [ ] `allowed-tools` grants `Bash(bash "*/.claude/skills/business-rules-check/../../hooks/yaml-helper.sh" resolve_config *)` with this skill's own directory name
- [ ] The line after the bootstrap block is exactly ``Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.`` (plain variant)
- [ ] The automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") follows that line verbatim
- [ ] `allowed-tools` is exactly: `Read, Glob, Grep, Write, Agent, AskUserQuestion` plus the grant — membership exact, order free; no `Bash` beyond the grant, no `Edit`
- [ ] `model: sonnet`; no `disable-model-invocation` and no `isolation` flag
- [ ] 2+ phase headings found
- [ ] Verdict keywords present exactly: `PASS`, `CONCERNS`, `FAIL`, `NOT ASSESSED`, with precedence **FAIL > CONCERNS > NOT ASSESSED > PASS**; finding severities `Critical`, `High`, `Medium`, `Low` are defined in a table
- [ ] "May I write this to `production/qa/business-rules/business-rules-check-<scope>-YYYY-MM-DD.md`?" appears before the report write
- [ ] Output at that exact path, with `<scope>` = the feature slug, `pricing`, the file stem or `full`; the report template has `> **Verdict**: <TOKEN>` directly under its H1 and one blank line
- [ ] The report template has `## Sources`, `## Rule Inventory`, `## Findings`, `## Domain Summary`, `## Regional Checklist`, `## Recommendations`, `## Not Checked`
- [ ] The PRD section is located with the tolerant heading form (optional numeric prefix, case-insensitive) for `Business Rules & Calculations`, and the pricing model is read by its seven `##` headings from `.claude/docs/templates/pricing-model.md`
- [ ] No `!` injection other than the bootstrap line; no `file:line` citations of other files
- [ ] Next steps close with `AskUserQuestion` naming current skills only (`/write-prd`, `/propagate-prd-change`, `/consistency-check`, `/security-audit`, `/quick-spec`, `/bug-report`)

---

## Director Gate Checks

**N/A.** No director gate at any review mode; `review_mode` is not among the keys.
`business-analyst` and `monetization-strategist` are consultants spawned with a return
contract ("Do not write any file. Return only …"); their rows feed the findings table,
and the verdict comes from the Phase 4 scoring rules (analysis AN4).

---

## Test Cases

### Case 1: Happy Path — Moa subscription rules agree everywhere

**Fixture** (assumed project state):
- `design/prd/subscription.md` `## Business Rules & Calculations`: Plus ₩4,900/month VAT included; annual ₩49,000; Free plan limited to 3 active goals; worked example "20% launch coupon on ₩4,900 → ₩3,920"
- `design/product/pricing-model.md` states the same prices, limit and coupon; `## Refunds & Cancellation` defines mid-period cancellation and store-purchase refunds handled by the store
- `design/registry/entities.yaml`: plans `free`, `plus`; constants `plus_monthly_price: 4900` (KRW per month, VAT included) and `free_active_goal_limit: 3`
- `config/plans.json` carries `4900` and `3`
- `project.yaml`: `compliance.regions: [kr]`; `.claude/docs/compliance/kr.md` exists

**Input**: `/business-rules-check subscription`

**Expected behavior**:
1. Announces the scope; reads the registry's `plans`, `rules` and `constants` before any PRD
2. Builds the rule inventory with the value from every source; recomputes the coupon example
3. Spawns `business-analyst` and `monetization-strategist` in parallel, each briefed inline with the inventory and the resolved `compliance` line
4. Lists each applicable `kr` item from `## Commerce & Payments` as `resolved (where)`, `open — needs <who>` or `N/A (why)`
5. No finding above Low → verdict `PASS`; asks "May I write this to `production/qa/business-rules/business-rules-check-subscription-YYYY-MM-DD.md`?"

**Assertions**:
- [ ] Both agents are spawned before either result is awaited
- [ ] `## Rule Inventory` shows `plus_monthly_price` with the same value in registry, PRD, pricing model and config, marked consistent
- [ ] The report's verdict line reads `> **Verdict**: PASS`
- [ ] `## Sources` records each source as FOUND or ABSENT

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure — a worked example contradicts its rounding rule

**Fixture**:
- As Case 1, but the rule says "discounted prices are rounded up to the nearest KRW 10" while the worked example states "15% off ₩4,900 → ₩4,165"
- `design/product/pricing-model.md` lists the annual price as ₩47,000; the PRD and `config/plans.json` say ₩49,000

**Input**: `/business-rules-check pricing`

**Expected behavior**:
1. Recomputes the example (₩4,165 → ₩4,170 under the stated rule) and records the contradiction
2. Records the annual price disagreement between sources as a charged-amount conflict
3. Rates both Critical (charges the wrong amount on a normal path) → verdict `FAIL`
4. Recommends fixing the source through `/write-prd subscription`, then `/propagate-prd-change design/prd/subscription.md`

**Assertions**:
- [ ] Verdict is `FAIL`; each finding has an ID (`BR-NN`), domain, severity, evidence and recommendation
- [ ] The evidence shows the recomputed example, not only "rounding mismatch"
- [ ] The file name uses the scope `pricing`
- [ ] No PRD, pricing model or registry file is edited by the skill

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: NOT ASSESSED — no rules written anywhere

**Fixture**:
- `design/prd/` is empty; no `design/product/pricing-model.md`
- `design/registry/entities.yaml` has no entries; no `config/**` tables
- `compliance.regions: [kr]`

**Input**: `/business-rules-check`

**Expected behavior**:
1. Lists each input as `FOUND` or `ABSENT`
2. Every required input is absent → stops with `NOT ASSESSED — NO DATA` as the whole verdict
3. Names what is missing and that `/write-prd` produces PRDs and the pricing model

**Assertions**:
- [ ] Verdict is `NOT ASSESSED` with the missing inputs named, never `PASS`
- [ ] No rule inventory row is invented; "nothing contradicted nothing" is not reported as consistency
- [ ] The regional checklist is not marked resolved for rules that do not exist

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Mode Variant — `compliance.regions` unset vs explicitly none

**Fixture**:
- The Case 1 project
- Run A: `compliance.regions` absent from `project.yaml` (the bootstrap prints `regions=(unset -- ask)`)
- Run B: `compliance.regions: []` (the bootstrap prints `regions=none`)

**Input**: `/business-rules-check subscription` (two runs)

**Expected behavior**:
1. Run A: asks with `AskUserQuestion` which regions the product sells in (`kr` / `eu` / `us` / none); if no answer, the regional checklist is `NOT ASSESSED — compliance.regions unset` and the verdict cannot be `PASS`
2. Run B: no regional items; the report header says the regions are none (explicit)

**Assertions**:
- [ ] Unset regions are asked about, never treated as `[]`
- [ ] Run B does not ask and states the explicit none
- [ ] Run A without an answer yields `NOT ASSESSED` (no higher finding present), with the reason in `## Not Checked`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Edge Case — pricing PRD without a pricing model, store refund promise, agent blocked

**Fixture**:
- `design/prd/subscription.md` defines Plus, the annual price and a referral credit, but `design/product/pricing-model.md` does not exist
- The PRD's `## Edge Cases` promises "Moa refunds App Store subscriptions directly within 7 days" (a rule outside `## Business Rules & Calculations`)
- `monetization-strategist` returns BLOCKED

**Input**: `/business-rules-check subscription`

**Expected behavior**:
1. Flags the absent pricing model as CONCERNS with a pointer to `/write-prd subscription`
2. Flags the store-refund promise (the store grants in-app refunds; the product revokes the entitlement) and the rule stated outside the contract section
3. Surfaces the blocked agent, runs its domains itself and writes `monetization-strategist not consulted — <reason>` in the report

**Assertions**:
- [ ] Verdict is at least `CONCERNS`; the absent pricing model is named in `## Sources` as ABSENT
- [ ] The blocked agent is reported, not silently skipped
- [ ] Referral credit issuance is checked for idempotency and caps (abuse vector with control and detection signal)

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses "May I write this to `<path>`?" before the report write; asks before overwriting a same-day report of the same scope
- [ ] Presents findings before requesting approval
- [ ] Ends with the `AskUserQuestion` next-step widget
- [ ] Does not auto-create files without user approval; edits no PRD, pricing model or registry (fixes go through their owning skills)
- [ ] Writes no evidence, reports or plans under `production/session-logs/` (gitignored)
- [ ] Never writes `modes.review_mode` or any other knob that `modes.rigor` fronts
- [ ] analysis AN1 — Phases 1–4 only read (Read, Glob, Grep) and consult; nothing is written before Phase 5
- [ ] analysis AN2 — findings are a table with a severity per row, plus a per-domain summary table
- [ ] analysis AN3 — the only write is the report, gated behind "May I write"
- [ ] analysis AN4 — no director gate; agent rows are findings for human review
- [ ] Observation vs verdict: the rule inventory records what each source says; regional deadlines, fees and thresholds are cited only from the compliance file or a dated source (`NOT SOURCEABLE — <what>` otherwise); a domain with no rules is `NOT ASSESSED`, not clean

---

## Coverage Notes

- Legal conclusions are out of scope: the spec checks that regional items are listed
  with a status and a source, not that the skill's reading of a law is correct.
- Values held only in a remote config or feature-flag service must be reported as
  `NOT CHECKED — <key> lives in <service>`; no fixture here exercises that path.
- Rules hard-coded in application source are found by `/code-review` and
  `/tech-debt`, not by this skill (it reads documents and config only).
