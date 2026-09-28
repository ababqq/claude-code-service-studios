---
name: prd-review
description: "Review one PRD or the product brief for completeness, consistency and implementability."
argument-hint: "[design/prd/<feature>.md | design/product/product-brief.md | design/product/one-pager.md] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/prd-review/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,feature_overrides`

Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).


# PRD Review

This skill reviews **one** product document before anyone builds from it:

- a **feature PRD** — `design/prd/<feature>.md`, the common case;
- the **product brief** — `design/product/product-brief.md` (`standard` / `full`);
- the **one-pager** — `design/product/one-pager.md` (`minimal`, where it replaces the brief and the PRDs).

It checks four things: **completeness** against the section contract of the document's tier, **internal
consistency** (rules, edge cases and acceptance criteria agree with each other), **cross-document consistency**
(the brief's principles and non-goals, the feature map, the glossary registry, the PRDs it depends on) and
**implementability** (could an engineer build and test it without guessing?). It ends with a verdict and a review
log that `/gate-check` reads.

**This is distinct from `/review-all-prds`**, which reviews the *relationships* between all PRDs at once, and from
`/consistency-check`, which scans every PRD against the glossary registry. Run this one per document.

### Outputs

| Path | What is written |
|------|-----------------|
| `<doc-dir>/reviews/<stem>-review-log.md` | The review log — `design/prd/reviews/<stem>-review-log.md` for a PRD, `design/product/reviews/<stem>-review-log.md` for the brief or the one-pager. Append-only history of reviews, with the rule-12 `> **Verdict**:` line under its H1 holding the latest verdict and a content-hash receipt per entry |
| The PRD's `> **Status**:` line and its row in `design/product/feature-map.md` | Only when offered and approved in Phase 5 (`Approved` or `Needs Revision`, kept 1:1) |

Verdicts: **APPROVED** / **NEEDS REVISION** / **MAJOR REVISION NEEDED** / **NOT ASSESSED**.

**Language.** Every heading, bold field label, status value and verdict token in the review log stays in English
exactly as written below; the findings and summaries are written in the user's conversation language.

---

## Phase 0: Parse Arguments and Resolve the Tier

### 0a. Which document

The first argument is the document path. With no argument, find candidates and ask with `AskUserQuestion`:

- feature-map rows (`design/product/feature-map.md`) whose `Status` is `In Review` or `Needs Revision`;
- PRDs whose `> **Status**:` line reads `In Review` (`Grep pattern="^> \*\*Status\*\*: In Review" glob="design/prd/*.md"`);
- the brief or the one-pager, when `design/product/reviews/` holds no log for it yet.

Classify the path:

| Path | Kind | Review log |
|------|------|------------|
| `design/prd/<stem>.md` (directly under `design/prd/`) | PRD | `design/prd/reviews/<stem>-review-log.md` |
| `design/product/product-brief.md` | Product brief | `design/product/reviews/product-brief-review-log.md` |
| `design/product/one-pager.md` | One-pager | `design/product/reviews/one-pager-review-log.md` |

Anything else is not this skill's input — stop with **NOT ASSESSED** and name the right tool: a UX spec →
`/ux-review`; an ADR → `/architecture-review`; a quick spec (`design/quick-specs/…`) → quick specs are reviewed
inside the story that embeds them (`/story-readiness`); a file under a `reviews/` folder is a review output, not a
document to review. If the path does not exist, stop with **NOT ASSESSED** and name the skill that writes it: PRDs
come from `/write-prd <feature>`, the brief and the one-pager from `/brainstorm`.

### 0b. Review mode

`review_mode` comes from the block above (`--review full|lean|solo` overrides it). Unset on an unconfigured project:
`modes.rigor` defaults to `minimal`, which resolves `review_mode` to `solo`.

- **`full`** — Phases 1–5 plus the consultant review of Phase 3b: domain consultants in parallel, then a
  `product-manager` senior synthesis.
- **`lean`** — Phases 1–5 as a single-session analysis; no agents.
- **`solo`** — Phases 1–5 as a single-session analysis; no agents; the closing widget of Phase 5d is replaced by a
  one-line recommended next step, so a skill that runs this review inside its own flow keeps control.

A skipped consultant review is named in the output ("Consultants: none — lean mode"), never left implicit.

### 0c. Workflow tier

**For a PRD** — the effective tier is the `feature_overrides` entry for `<stem>` when the block lists one, else the
project `workflow` value. Name the source in the output ("tier `full` from feature_overrides"). Read the two
`workflow_overrides` flags from `project.yaml` with Read (they have no `resolve_config` label):
`workflow_overrides.edge_cases` and `workflow_overrides.config_flags`. An absent flag is unset — it forces nothing,
and it is not `false` either; say "unset" if the verdict turns on it.

| # | Section (`## …`) | `full` | `standard` | `minimal` (voluntary PRD) |
|---|---|---|---|---|
| 1 | Overview | REQUIRED | REQUIRED | advisory |
| 2 | Goals & Non-Goals | REQUIRED | REQUIRED | advisory |
| 3 | User Value | REQUIRED | advisory | advisory |
| 4 | Functional Requirements | REQUIRED | REQUIRED | advisory |
| 5 | Business Rules & Calculations | REQUIRED | **conditional** — REQUIRED when the feature defines any numeric or policy rule (prices, fees, limits, quotas, rate limits, eligibility thresholds, time windows, rounding), else advisory | advisory |
| 6 | Edge Cases | REQUIRED | REQUIRED | advisory — REQUIRED when `workflow_overrides.edge_cases: true` |
| 7 | Dependencies | REQUIRED | REQUIRED | advisory |
| 8 | Non-Functional Requirements | REQUIRED | REQUIRED | advisory |
| 9 | Configuration & Flags | REQUIRED | advisory — REQUIRED when `workflow_overrides.config_flags: true` | advisory |
| 10 | Success Metrics & Instrumentation | REQUIRED | REQUIRED (≥1 metric with baseline and target; event detail may be `TBD`) | advisory |
| 11 | Acceptance Criteria | REQUIRED | REQUIRED | advisory |

At `minimal` no PRD is expected — the one-pager is the design record. A PRD written anyway is reviewed against the
eight `standard` sections, advisorily, and the output says so.

**For the product brief** (`standard` / `full`):

- REQUIRED: `## Problem Statement`, `## Target Users & Jobs-to-be-Done`, `## Value Proposition`,
  `## Product Principles & Anti-Goals`, `## Success Metrics`, `## Riskiest Assumptions`, `## MVP Scope` (the seven
  sections `/gate-check definition` checks) and `## Non-Goals`.
- Advisory: `## Elevator Pitch`, `## Alternatives & Positioning`, `## Business Model Hypothesis`, `## Open Questions`.
- `## Brand Direction Anchor` is optional: recommended at `full` when the product has a UI, never a finding at
  `standard`, and absent by design when direction was deferred to `/design-language`.
- At `minimal` the one-pager is the record; a brief is reviewed advisorily.

**For the one-pager** (`minimal`): all seven headings are REQUIRED — `## Pitch`, `## Problem & Target User`,
`## Core User Journey`, `## Success Signal`, `## Scope & Non-Goals`, `## Stack`, `## Build Order` (the build order is
the plan at this tier, so it needs at least one item). At `standard` / `full` the brief is the expected document:
review the one-pager advisorily and recommend `/brainstorm` to write the brief.

---

## Phase 1: Load Documents

**Freshness check first — a re-review of an unchanged document costs a full review and reproduces the same
verdict.** Run, for a PRD:

```
Bash: bash .claude/scripts/review-receipts.sh check "design/prd/reviews/<stem>-review-log.md" "design/prd/<stem>.md" "design/registry/entities.yaml"
```

and for the brief or the one-pager (no registry — product documents do not own registry facts):

```
Bash: bash .claude/scripts/review-receipts.sh check "design/product/reviews/<stem>-review-log.md" "design/product/<stem>.md"
```

The registry is in the PRD check because this review consults it for cross-document facts — an unchanged PRD
reviewed against a *changed* registry can reach different conclusions, so the skip is only safe when **every**
listed line reads `UNCHANGED` (an absent registry simply does not appear in the output and does not block the skip).
An `UNRESOLVED:` line disqualifies the skip: the set compared was not the set asked for.

- **All `UNCHANGED`** and the log's latest `## Review —` entry carries a verdict — surface it: *"This document is
  byte-identical to its last review on [date] (verdict: [verdict])."* If that verdict was APPROVED, offer via
  `AskUserQuestion`: `[A] Use the prior verdict (Recommended)` / `[B] Re-review anyway` — `guided` proceeds with [A]
  and notes it; `autonomous` logs via `log_decision` and uses the prior verdict. If it was NEEDS REVISION or MAJOR
  REVISION NEEDED, say so plainly: the document has not changed since it failed review — the prior findings stand;
  revising the document is the next step, not re-reviewing it. Offer to display the prior findings from the log.
  **Exception:** a NEEDS REVISION entry followed by a `## Revision — [date] — Accepted as-is` note (5c option [C])
  means the user already accepted those findings for this exact content — say so, with both dates, and offer the
  same `[A]` / `[B]` choice as for APPROVED.
- **Only the registry line reads `CHANGED`** (document `UNCHANGED`) — the prior verdict stands except for
  cross-document facts: re-verify the PRD's registry-sourced values against the new registry and re-issue the
  verdict; escalate to a full re-review only if a conflict appears.
- **Target document `CHANGED` or `NEW`, or `RECEIPT: NONE`** — proceed with the full review below. **Do not offer a
  partial or delta re-review that skips reading or re-analyzing unchanged sections.** Measured against full reviews,
  section-scoped re-reviews — including one with an explicit forced whole-document scan and one gated on a thorough
  prior review — each caught a third of the real defects a full review found on the same document, and the most
  careful variant cost more tokens than the full review. "Unchanged since last review" only means byte-identical to
  what was reviewed then; it says nothing about whether that prior pass was complete.

Read the target document in full.

**Prior review.** If the review log exists, read its most recent entry — the verdict and the blocking items listed.
This run is a re-review: track whether each prior blocking item was addressed.

### 1a. PRD inputs

**For cross-document facts, prefer the registry over sibling PRDs.** If `design/registry/entities.yaml` exists
**and lists entries for this feature**, grep it — these are the established facts (entities, plans, rules, constants,
events) this PRD must not contradict, and they replace reading sibling PRDs to rediscover them:

```
Grep pattern="source: design/prd/<stem>.md" path="design/registry/entities.yaml" output_mode="content" -A 6
Grep pattern="design/prd/<stem>.md" path="design/registry/entities.yaml" output_mode="content" -B 8
```

The first finds entries this feature **owns** — the `-A 6` context includes their `referenced_by:` block. The second
finds entries that **reference** this feature — `referenced_by:` is a block sequence (the key and its paths are on
separate lines), so match the path with `-B 8` context to see the owning entry, not a `referenced_by.*name`
one-liner (which never matches the block form).

**If the registry does not exist, or lists no entry for this feature** — it ships as a stub until `/write-prd` has
populated it — fall back to reading the PRDs this one names in its `## Dependencies` table. Bound the read to those,
not to everything "related". Do not glob-read all of `design/prd/`.

**Dependency graph.** The `## Dependencies` section is a table (`| Feature | PRD | Direction | Nature |`, Direction
`depends on` or `depended on by`). For every row:

1. `Glob` the PRD path — flag any that does not exist yet (a broken reference downstream authors will hit).
2. Check the other end: `Grep` that PRD's `## Dependencies` section for `design/prd/<stem>.md` with the opposite
   direction. A one-way edge is a finding against whichever side is stale.
3. Compare with the feature map: the row for this feature in `design/product/feature-map.md` — its `Depends On`
   slugs, `Tier` and `PRD` path must agree with the PRD's table and its `> **Feature Map Tier**:` line.

**Brief alignment.** Read `design/product/product-brief.md` (`## Product Principles & Anti-Goals`,
`## Success Metrics`, `## MVP Scope`, `## Non-Goals`) — or the one-pager's `## Scope & Non-Goals` at `minimal`. The
PRD's `> **Implements Principle**:` must name a principle that exists there; its goals must serve the brief's
metrics; its scope must stay inside the MVP scope when its tier is `MVP`; nothing in it may do what an anti-goal or
non-goal rules out. If neither the brief nor the one-pager exists, the alignment check cannot run — say so, and it
counts toward NOT ASSESSED (Phase 4).

**Companion documents** (read only the rows that concern this PRD, and only if the file exists):
`design/product/tracking-plan.md` (`## Events` rows whose `Owner PRD` is this PRD — they must match
`## Success Metrics & Instrumentation`), `design/product/pricing-model.md` (when the PRD defines plans, prices,
credits or promotions), `naming.events` in `project.yaml` (the event-naming convention, read with Read).

### 1b. Brief and one-pager inputs

Read the prototype evidence the brief cites (`prototypes/*-concept/REPORT.md`, verdict and hypothesis) and any
personas under `design/product/personas/`. Read `design/product/feature-map.md` if it already exists — a revised
brief can orphan features the map already lists.

---

## Phase 2: Completeness Check

### Step 2a — gather section presence deterministically

For a PRD (no document read needed for this step):

```
Bash: bash .claude/scripts/prd-structure-check.sh design/prd/<stem>.md
```

It prints a `PRESENT:` list and, when applicable, an `ABSENT:` list of the eleven contract sections. It reports
**presence only** and makes no REQUIRED/ADVISORY judgment — that is Step 2b's job. Its heading match is tolerant
(case-insensitive, numbered headings such as `## 2) Goals & Non-Goals` count), so do not re-flag a numbered heading.

For the brief or the one-pager, list its headings (`Grep pattern="^##+\s" path="<doc>" output_mode="content"`) and
compare them with the Phase 0c list — exact heading text, because `/gate-check` matches on it.

Also check the PRD preamble: `## Summary` present with the `> **Quick reference**` line (skills scanning many PRDs
decide from it whether to read further — advisory when missing); `> **Status**:` one of `Draft | In Review |
Needs Revision | Approved | Implemented`; `> **Feature Map Tier**:` one of `MVP | Beta | GA | Later`.

### Step 2b — apply the tier

Using the Step 2a lists, evaluate against the Phase 0c table. **Mark each section REQUIRED or ADVISORY per the
resolved tier.** A missing REQUIRED section blocks approval; a missing ADVISORY section is surfaced as a
recommendation but does not block.

A section reported PRESENT can still fail review if it is an empty heading or template placeholder text — spot-read
every section the verdict actually turns on.

- [ ] **Overview** — what and why, one paragraph.
- [ ] **Goals & Non-Goals** — goals tied to the brief's success metrics; an explicit out-of-scope list
      (`/scope-check` compares delivered work against it, so "TBD" here disables scope control).
- [ ] **User Value** — persona, job-to-be-done, user stories, the success moment.
- [ ] **Functional Requirements** — `### Core Rules`, `### User Flows & States`,
      `### Interactions with Other Features`; unambiguous enough to implement.
- [ ] **Business Rules & Calculations** — every rule with variables, units, rounding and a worked example. Decide
      "does this feature define a numeric or policy rule?" from the Functional Requirements content, never from the
      feature's Category in the feature map.
- [ ] **Edge Cases** — including failure modes: network loss, partial failure, concurrency, retries.
- [ ] **Dependencies** — the table, bidirectional, plus `### External Services` for third parties.
- [ ] **Non-Functional Requirements** — performance, availability, security & privacy (PII fields, authorization
      rules, retention), accessibility, localization.
- [ ] **Configuration & Flags** — each flag with key, default, owner and removal date; config values and limits
      exposed to operations.
- [ ] **Success Metrics & Instrumentation** — metric(s) moved with baseline and target; events.
- [ ] **Acceptance Criteria** — testable Given/When/Then.

---

## Phase 3: Consistency and Implementability

**Internal consistency** (PRD):
- Do the business rules produce the values the requirements and acceptance criteria describe? Work one example
  through ("monthly fee = plan price × seats, rounded to KRW 10": does the AC's expected amount match?).
- Do edge cases contradict the core rules? Does every state in `### User Flows & States` have a way in and a way out,
  and is every terminal state named?
- Are the dependencies bidirectional (Phase 1a)? Do the preamble's Status and Tier match the feature map?
- Does every flag in `## Configuration & Flags` appear where the behaviour it gates is described, with a removal
  date (a flag without one becomes permanent configuration)?
- Does every event in `## Success Metrics & Instrumentation` follow the `naming.events` convention and match the
  tracking-plan rows this PRD owns?

**Implementability:**
- Could an engineer implement each rule without guessing? Look for missing units, rounding, currencies and time
  zones (a "daily" limit resets at KST midnight or UTC midnight?), month-end and leap-day behaviour.
- Are there hand-wave passages ("handled appropriately", "standard retry logic")?
- Are failure paths specified where money or messages move: idempotency of payment and auto-debit retries,
  double-submit, webhook redelivery, a third party that times out after it succeeded, offline edits on mobile?
- Are the NFRs measurable (p95 latency, availability target, error rate) rather than adjectives? Are PII fields
  named with an authorization rule for each operation that touches them?
- Is every acceptance criterion independently testable, and does it say which environment it needs?

**Cross-document consistency:**
- Does any value contradict a registry fact (entity, plan, rule, constant, event)? The entry's `source:` PRD is
  authoritative; a PRD that restates it differently is the one to change.
- Does it conflict with a rule in a PRD it depends on, or create an unintended interaction with one?
- Does it serve the principle it claims, and stay clear of the brief's anti-goals and non-goals?

**For the product brief** — is the problem backed by evidence (interviews, data, a prototype)? Is the target segment
named concretely ("salaried 25–34-year-olds in Korea who save toward a goal by manual transfer each payday", not
"young people")? Are the alternatives real, including doing nothing or a spreadsheet? Does each principle state the
trade-off it decides, so it can settle a real argument? Are the North Star and at least one guardrail metric
defined? Does each riskiest assumption have a test (prototype, interviews, fake door, data)? Is the MVP scope the
smallest thing that tests the value proposition, and are non-goals listed?

**For the one-pager** — are all seven sections filled, does the core user journey end in the success signal, and does
`## Build Order` hold at least one concrete item?

---

## Phase 3b: Consultant Review (full mode only)

**Skip this phase in `lean` or `solo` mode** — and say so in the output.

**This phase is MANDATORY in full mode.** Do not skip it.

**Before spawning any agents**, print this notice:
> "Full review: spawning consultants in parallel. This typically takes 8–15 minutes. Use `--review lean` for a
> faster single-session analysis."

### Step 1 — Identify every domain the document touches

Using the document **already loaded in Phase 1** — do not re-read it — identify every domain present. A PRD often
touches several at once; be thorough. Decide the engineering consultants from what the document itself specifies
(its UI Requirements, Functional Requirements and API & Data Impact sections), not from assumptions about which apps
exist.

| If the document contains… | Spawn |
|---------------------------|-------|
| Business rules: eligibility, limits and quotas, state machines, refunds or cancellation | `business-analyst` |
| Prices, plans, trials, promotions or coupons, credits or points, payment methods | `monetization-strategist` |
| Server-side behaviour: API operations, persistence, background jobs, webhooks, third-party calls | `backend-engineer` |
| Web UI: screens, forms, routing, SEO or rendering needs | `frontend-engineer` |
| iOS or Android behaviour: push, deep links, offline, permissions, store rules | `mobile-engineer` |
| Personal data, authentication, authorization, payment data, consent | `security-engineer` |
| Success metrics, events, funnels, experiments | `analytics-engineer` |
| Screens, flows, states, copy-bearing UI | `product-designer` |
| Acceptance criteria | `qa-lead` |
| Latency, throughput, availability or app-size budgets | `performance-engineer` |

`product-manager` always takes part — as the senior reviewer of Step 3, not in the parallel batch. For the brief the
usual set is `monetization-strategist` (business model), `analytics-engineer` (metrics) and `product-designer` (when
the product has a UI or a brand direction anchor), plus `security-engineer` when the product handles sensitive data.

### Step 2 — Spawn all relevant consultants in parallel

**CRITICAL: `Agent` in this skill spawns a SUBAGENT — a separate independent Claude session with its own context
window. It is NOT task tracking. Do NOT simulate consultant perspectives internally. Do NOT reason through domain
views yourself. You MUST issue actual `Agent` calls. A simulated review is not a consultant review.**

Issue all `Agent` calls simultaneously (`subagent_type` = the agent name). Do NOT spawn one at a time. Pass the
document path, the text of the sections the consultant needs, and the structural findings so far.

**Prompt each consultant adversarially:**
> "Here is the PRD for [feature] and the main review's structural findings so far. Your job is NOT to validate this
> document — your job is to find problems. Challenge it from your domain expertise. What is wrong, underspecified,
> likely to fail in production, or missing entirely? Be specific and critical. Disagreement with the main review is
> welcome."

**Additional instructions per consultant:**

- **`business-analyst`**: Plug boundary values into every rule in `## Business Rules & Calculations` — 0, 1, the
  maximum, maximum + 1, negative amounts, the rounding boundary, month-end and leap day, a KST-midnight crossing.
  Report any rule whose output goes degenerate (negative balance, division by zero, double charge) and any state
  transition without a trigger, guard or outcome.
- **`monetization-strategist`**: Check the price ladder, plan limits against entitlements, trial-to-paid conversion,
  promotion stacking, proration on upgrade and downgrade, and the refund and cancellation policy against App Store /
  Google Play subscription rules and regional consumer-protection rules. Compare with
  `design/product/pricing-model.md` when it exists.
- **`security-engineer`**: For every operation, who may read or change whose data (BOLA/IDOR)? List each personal-data
  field with its classification, retention and deletion path, and flag consent, secrets or logging gaps.
- **`analytics-engineer`**: Each metric needs a baseline, a target and a data source. Events must follow the
  `naming.events` convention in `project.yaml` and carry properties and a PII flag; flag any event that duplicates
  one another PRD owns in `design/product/tracking-plan.md`.
- **`qa-lead`**: Review every acceptance criterion. Flag any that is not independently testable — "works correctly",
  "is fast", "is user-friendly" are not criteria. Suggest concrete Given/When/Then rewrites and name the criteria
  that need a deployed environment.
- **`performance-engineer`**: Are the NFR budgets measurable and consistent with `docs/ops/slo.md` when it exists
  (p95 latency, error rate, availability, mobile start-up time and app size)?
- **`product-designer`**: Do the flows cover loading, empty, error, offline and permission-denied states? Are
  accessibility needs and every piece of copy-bearing UI named?
- **`backend-engineer`, `frontend-engineer`, `mobile-engineer`**: Implementability — idempotency keys on retries,
  concurrency and double-submit, pagination, timeouts, partial third-party failure, offline edits and sync
  conflicts, token refresh, push-permission denial, deep links, force-update.

### Step 3 — Senior review

After all consultants respond, spawn `product-manager` as the **senior reviewer**:
- Provide: the document, all consultant findings, any disagreements between them, and the brief's principles and
  success metrics.
- Ask: "Anchor to `## User Value` and `## Goals & Non-Goals` (for the brief: the Problem Statement and Value
  Proposition). Does this document deliver the stated value within the brief's principles and MVP scope? Synthesise
  the consultants' findings: which matter most, do you agree with them, and what is your overall verdict?"
- The product-manager's synthesis becomes the **final verdict** in Phase 4.

### Step 4 — Surface disagreements

If consultants disagree with each other or with the product-manager, do NOT silently pick one view. Present the
disagreement explicitly in Phase 4 so the user can adjudicate.

Mark every finding with its source: `[business-analyst]`, `[security-engineer]`, `[product-manager]` etc.

**A consultant that returns nothing is not a clean result.** If an agent errors, returns BLOCKED, or returns no
findings section, name it in the output — "`security-engineer`: NOT CHECKED — no report returned" — and carry the
gap into the verdict (Phase 4). See `.claude/docs/error-recovery-protocol.md`.

---

## Phase 4: Output Review

Present the review in the conversation:

```
## PRD Review: [Document Title]
Document: [path] · Kind: [PRD | Product brief | One-pager] · Tier: [full | standard | minimal] ([source])
Review mode: [full | lean | solo] · Consultants: [list, or "none — lean mode" / "none — solo mode"]
Re-review: [Yes — prior verdict was X on YYYY-MM-DD / No — first review]

### Completeness: [X/N required sections present, where N is the count REQUIRED at this document's tier]
[List only missing sections that are REQUIRED at this tier. List advisory gaps separately as "advisory at
`standard`" — do not list them as missing.]

### Dependency Graph
- ✓ design/prd/auth.md — exists; lists goals as `depended on by`
- ⚠ design/prd/notifications.md — exists, but does not list goals back
- ✗ design/prd/payments.md — NOT FOUND (no PRD yet)

### Required Before Implementation
[Numbered list — blocking issues only. Each item tagged with its source.]

### Recommended Revisions
[Numbered list — important but not blocking. Source-tagged.]

### Consultant Disagreements
[Any case where consultants disagreed with each other or with the main review. Present both sides.]

### Nice-to-Have
[Minor improvements, low priority.]

### Senior Verdict [product-manager]
[full mode: the synthesis. lean / solo: "Not run — <mode> mode".]

### Scope Signal
Rough scope signal: [S | M | L | XL] (delivery-manager should verify before sprint planning)

### Verdict: [APPROVED / NEEDS REVISION / MAJOR REVISION NEEDED / NOT ASSESSED]
```

> **N is not 11 unless the tier is `full`.** The Phase 0c table is authoritative: 11 at `full`, 8 at `standard`
> (+ Business Rules & Calculations when the feature defines a numeric or policy rule, + Configuration & Flags when
> `workflow_overrides.config_flags: true`), 0 at `minimal`. Reporting a `standard` PRD as "8/11, missing User Value
> and Configuration & Flags" warns about sections that project's own configuration says it does not need, which
> trains the reader to ignore the review.

**Scope signal** — from the dependency count, the number of business rules, the features touched, and whether new
ADRs, API operations or migrations are needed:
- **S** — one feature, no business rules, no new ADR, API operation or migration, fewer than 3 dependencies
- **M** — 1–2 business rules or a few new API operations, one additive migration, 3–6 dependencies
- **L** — cross-feature behaviour, 3+ business rules, a new third-party integration, may need an ADR
- **XL** — cross-cutting (identity, payments, permissions), 5+ dependencies, several ADRs or a breaking API change

**Choosing the verdict:**
- **APPROVED** — no blocking item remains; advisory items may.
- **NEEDS REVISION** — blocking items exist, and each can be fixed inside the current design.
- **MAJOR REVISION NEEDED** — the design itself has to change: a REQUIRED section that carries core behaviour is
  missing, the document contradicts the brief's principles or a fact another PRD owns, or its rules cannot be
  implemented as written.
- **NOT ASSESSED** — the review could not actually be performed.

> **`NOT ASSESSED` when the review could not actually be performed.** The other three verdicts are all claims about
> the document's quality, so each one asserts that the document was read and judged. Use `NOT ASSESSED` instead when
> the target document is absent, unreadable, or empty of the sections being reviewed, or when a document it depends
> on is missing so the criteria cannot be applied (no brief or one-pager to check alignment against; in `full` mode, a
> consultant whose domain the verdict turns on returned nothing). **Name what was unavailable and which skill
> produces it.**
>
> `APPROVED` is the dangerous default here: a review that could not find its input has not approved anything, and
> this verdict is consumed downstream as a sign-off. `NOT ASSESSED` outranks `APPROVED` in any aggregate — it does
> not outrank the two revision verdicts, because a known problem is more actionable than an unknown one.

Phase 4 writes nothing.

---

## Phase 5: Records and Next Steps

Use `AskUserQuestion` for every closing interaction. Never plain text (except the `solo` closing line of 5d).

### 5a. Review log (every mode, every verdict)

The review log is the artifact `/gate-check` reads, so it is offered on every run — including `solo` and
NOT ASSESSED. It is written **before** any revision in 5c, so its content-hash receipt describes the version that
was actually reviewed; a document revised afterwards reads `CHANGED` on the next run and gets a full review.

- **APPROVED** — use one `AskUserQuestion` with `multiSelect: true` to batch the tracking updates:
  - Prompt: "Verdict: APPROVED. I can update the tracking records now. Select any you'd like me to complete:"
  - Options (PRD): `Append this review to design/prd/reviews/<stem>-review-log.md` ·
    `Set the PRD's > **Status** to Approved` · `Set the feature-map row for <feature> to Approved`
  - Option (brief or one-pager): `Append this review to design/product/reviews/<stem>-review-log.md` only.
  - Selecting an option is the approval to write that path. Execute every selected action before moving on.
- **NEEDS REVISION / MAJOR REVISION NEEDED** — ask separately:
  - "May I write this to `<doc-dir>/reviews/<stem>-review-log.md`? It appends this review, so future re-reviews can
    track what changed." Options: `[A] Yes — append to review log` / `[B] No — skip`
  - PRD only: "May I write this to `design/prd/<stem>.md` and `design/product/feature-map.md`? It sets the PRD's
    `> **Status**` and its feature-map row to `Needs Revision`." Options: `[A] Yes — update both` /
    `[B] No — leave them as-is`. The two values move together — PRD `Status` and the
    feature-map `Status` are kept 1:1 (`Draft` ↔ `Drafting`, `In Review`, `Needs Revision`, `Approved`,
    `Implemented`).
- **NOT ASSESSED** — offer the log only, with the same prompt.

A new log file starts with this header; an existing one keeps it:

```markdown
# Review Log: [Document Title]

> **Verdict**: [the latest entry's verdict]

Review history for `[target-doc-path]` — one entry per `/prd-review` run, newest last.
```

Append one entry per run:

```markdown
## Review — [YYYY-MM-DD] — Verdict: [APPROVED / NEEDS REVISION / MAJOR REVISION NEEDED / NOT ASSESSED]
Tier: [full | standard | minimal] · Review mode: [full | lean | solo]
Scope signal: [S/M/L/XL]
Consultants: [list, or none — <mode> mode]
Blocking items: [count] | Recommended: [count]
Summary: [2-3 sentences — the product-manager synthesis in full mode]
Prior verdict resolved: [Yes / No / First review]
Findings:
- [BLOCKING] [section]: [one-line finding]
- [RECOMMENDED] [section]: [one-line finding]
[output of: Bash: bash .claude/scripts/review-receipts.sh hash "<target-doc-path>" — plus "design/registry/entities.yaml" for a PRD when the registry file exists]
```

With every append, set the `> **Verdict**:` line under the H1 to this entry's verdict, so the line always equals the
latest entry — `/gate-check` reads that line (a PRD whose log ends in MAJOR REVISION NEEDED blocks the Definition →
Architecture gate).

Findings rules: one line per finding, named by the section it lives in; write `- none` when the verdict carried no
findings. The findings are documentation for a human reader of the revision history, not a mechanism this skill
reads back — a delta re-review that skipped re-analyzing unchanged sections was measured and rejected (Phase 1).

The hash line is the receipt Phase 1 reads on the next run to detect a byte-identical re-review — the one form of
skip that is actually safe, because the input is provably the same. Always include it, whatever the verdict: an
unchanged document that previously failed review is exactly the case where skipping a redundant re-review saves the
most (the prior findings stand verbatim).

### 5b. After APPROVED

If the user did not select the status updates in 5a, offer them once more in the final widget. When the PRD is
approved and its feature-map row moves to `Approved`, nothing else changes — the feature map's other columns are
`/map-features`' to maintain.

### 5c. Revise now (NEEDS REVISION or MAJOR REVISION NEEDED)

Options:
- `[A] Revise the document now — address the blocking items together`
- `[B] Stop here — revise in a separate session`
- `[C] Accept as-is — you judge every blocking item deferrable` (offered only when the verdict
  was NEEDS REVISION; a MAJOR REVISION NEEDED document is revised and re-reviewed before it is approved)

**If the user selects [C]:** the user is overruling the review's blocking items. That is a product decision, so it
is the user's alone: in autonomous mode never choose [C] — take [B] and record it via `log_decision`. Get a one-line
reason for each blocking item. If the 5a review entry was skipped, offer it again first, because an acceptance note
with no review above it does not record what was accepted. Then ask "May I write this to
`<doc-dir>/reviews/<stem>-review-log.md`?" and append:

```markdown
## Revision — [YYYY-MM-DD] — Accepted as-is
Accepted: [each blocking item → the user's reason it can stand]
```

Add no hash line. The document is unchanged, so the review entry's receipt still describes it, and any later edit
reads `CHANGED` and gets a full review. The `> **Verdict**:` line stays at NEEDS REVISION. For a PRD, then offer
to set the PRD `Status` and its feature-map row to `Approved`, as in 5a, since `/create-epics` takes only Approved
PRDs. Continue to 5d.

**If the user selects [A]:** work through the blocking items, asking for product decisions only where you cannot
resolve an item from the document and the existing docs alone. Group all decision questions into a single multi-tab
`AskUserQuestion` before making any edits — do not interrupt mid-revision for each blocker. Show each change, then
ask "May I write this to `<target-doc-path>`?" before editing. Keep every template heading and bold field label
exactly as it is.

After all revisions, show a summary table (blocker → fix applied) and use `AskUserQuestion` for a
**post-revision widget**:

- Prompt: "Revisions complete — [N] blockers resolved. What next?"
- If context usage is above ~50%, add: "(Recommended: /clear before re-review — this session has used X% context.
  A full re-review spawns several agents and needs clean context.)"
- Options:
  - `[A] Re-review in a new session — run /prd-review <path> after /clear`
  - `[B] Accept the revisions and mark Approved — skip the re-review` (offered only when the verdict was NEEDS
    REVISION; a MAJOR REVISION NEEDED document is re-reviewed before it is approved)
  - `[C] Move to the next feature — /write-prd <next-feature>`
  - `[D] Stop here`

On [B], ask "May I write this to `<doc-dir>/reviews/<stem>-review-log.md`?" and append a revision note (no hash line
— the next review must be a full one):

```markdown
## Revision — [YYYY-MM-DD] — Accepted without re-review
Resolved: [each blocking item → the fix applied]
```

The `> **Verdict**:` line stays at the reviewed verdict (NEEDS REVISION); then offer the PRD `Status` and feature-map
updates to `Approved` as in 5a.

In collaborative and guided modes, never end the revision flow with plain text — always close with this widget. In
autonomous mode, summarize the outcome and record it via `log_decision`.

### 5d. Final closing widget

Once the record widgets are answered, check project state and show one final `AskUserQuestion`. In `solo` mode, print
the verdict and the single most pipeline-advancing next step instead of the widget.

Before building options, read:
- `design/product/feature-map.md` — any other feature whose Status is `In Review` or `Needs Revision`, and the next
  `Not Started` feature of tier MVP in map order;
- the count of `design/prd/*.md` files.

**Options for a PRD** (only those that apply):
- `[_] Run /prd-review design/prd/<other>.md — <feature> is still In Review / Needs Revision`
- `[_] Run /consistency-check — verify this PRD's values against the glossary registry` (when ≥1 other PRD exists)
- `[_] Run /review-all-prds — holistic cross-PRD review` (when ≥2 PRDs exist)
- `[_] Run /write-prd <next-feature> — next in the feature map` (name the actual feature)
- `[_] Run /propagate-prd-change design/prd/<stem>.md — the PRD changed after ADRs were written against it` (when
  this was a re-review and an ADR's `## PRD Requirements Addressed` cites this PRD)
- `[_] Stop here`

**Options for the brief or the one-pager:**
- `[_] Run /gate-check definition — Discovery → Definition` (when APPROVED)
- `[_] Run /setup-stack — pin the stack` (when `project.yaml` has no `pinned_on:` value)
- `[_] Run /prototype — test the riskiest assumption` (when a riskiest assumption has no test yet)
- `[_] Run /brainstorm — revise the brief` (MAJOR REVISION NEEDED)
- `[_] Stop here`

Assign letters A, B, C… only to included options. Mark the most pipeline-advancing option as `(recommended)`.

In collaborative and guided modes, never end the skill with plain text after file writes — always close with this
widget (`solo` excepted, as above). In autonomous mode, print the next step and record it via `log_decision`.

---

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and `autonomous` modes, see
`.claude/docs/automation-modes.md` — the rules below describe what collaborative mode requires.

1. **Read silently** — load the document and its context before presenting anything.
2. **Show the full review first** — the user sees every finding and the verdict before any write is offered.
3. **Distinguish blocking from advisory** — mark each finding REQUIRED-tier or advisory; never inflate an advisory gap
   into a blocker at a tier that does not require it.
4. **Don't make product decisions** — surface contradictions and options; the user decides which document is right.
5. **Ask before writing** — "May I write this to `<path>`?" before the review log, every status change and every
   revision.
6. **Be specific** — every finding names its section and quotes or paraphrases the text involved.
