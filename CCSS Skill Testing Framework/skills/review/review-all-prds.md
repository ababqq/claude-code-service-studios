# Skill Spec: /review-all-prds

> **Category**: review
> **Priority**: critical
> **Spec written**: 2026-09-28

## Skill Summary

`/review-all-prds` is an Opus-tier skill that reads every feature PRD in
`design/prd/` together and reviews what no single-PRD review can see. Phase 2
(cross-PRD consistency) checks bidirectional dependencies, rule contradictions,
stale references, configuration and flag ownership, conflicting limits, prices,
metric definitions and events, and acceptance criteria that cannot both pass.
Phase 3 (product holism) checks value delivery against the brief's principles,
cognitive load across flows, business-rule abuse paths, the credits and pricing
economy, scope drift against anti-goals and PRD Non-Goals, and user-value
coherence. Phases 2 and 3 run as parallel `product-manager` subagents that receive
the loaded content, not paths. Phase 4 walks multi-feature user moments. Focus
modes: `full` (default), `consistency`, `product-theory`, `since-last-review`
(scope from `bash .claude/scripts/review-scope.sh since-last-review`). The
verdict is PASS / CONCERNS / FAIL / NOT ASSESSED, written after approval to
`design/prd/reviews/prd-cross-review-YYYY-MM-DD.md` — the report the
Definition → Architecture gate looks for. It runs in the main working tree (no
`isolation` key — it must read uncommitted PRDs) and spawns no director gate.

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`); `name: review-all-prds` equals the skill directory and the catalog `name`; `model: opus`
- [ ] Frontmatter carries no `isolation` key and no `disable-model-invocation`
- [ ] Bootstrap: the first body line is `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow,feature_overrides` `` and `allowed-tools` grants `Bash(bash "*/.claude/skills/review-all-prds/../../hooks/yaml-helper.sh" resolve_config *)`
- [ ] The line after the bootstrap block is exactly: ``Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] The automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") follows that line verbatim
- [ ] `allowed-tools` is exactly: Read, Glob, Grep, Write, Bash, Agent, AskUserQuestion, plus the grant (membership exact, order free — no Edit)
- [ ] 2+ phase headings found
- [ ] Verdict keywords present, exactly: `PASS`, `CONCERNS`, `FAIL`, `NOT ASSESSED`, with NOT ASSESSED ranked above PASS and below CONCERNS and FAIL
- [ ] "May I write this review to `design/prd/reviews/prd-cross-review-YYYY-MM-DD.md`?" before the report, and "May I write this to `design/product/feature-map.md`?" before flagging PRDs
- [ ] Outputs at the exact path `design/prd/reviews/prd-cross-review-YYYY-MM-DD.md` (ISO 8601 date); the report's H1 `# Cross-PRD Review — [YYYY-MM-DD]` is followed, after one blank line, by `> **Verdict**: <TOKEN>`
- [ ] PRD sections are matched by the contract headings of `.claude/docs/templates/prd.md`, and each PRD is judged against its effective tier (`feature_overrides` entry, else the project `workflow`)
- [ ] No `!` injection other than the bootstrap line; no `file:line` citations of other files
- [ ] Next-step handoff section present at end (Phase 7), naming skills by their current names

---

## Director Gate Checks

- **Full / Lean / Solo mode**: not applicable — `review_mode` is not among the keys and no director gate is spawned or skipped in any mode.
- **N/A**: this skill is the holistic review; its Phase 2 and Phase 3 subagents are `product-manager` consultants that return findings, not gate verdicts.

---

## Test Cases

### Case 1: Happy Path — a consistent MVP set

**Fixture** (assumed project state):
- `modes.rigor: standard`
- `design/prd/auth.md`, `onboarding.md`, `goals.md`, `payments.md` — each with the `standard` sections and a Dependencies table whose edges are listed on both ends
- `design/product/product-brief.md` with principles, anti-goals, success metrics, MVP scope and non-goals; `design/product/feature-map.md` agreeing with the PRDs
- `design/registry/entities.yaml` with the plans, rules and constants the PRDs use; no contradictions anywhere

**Expected behavior**:
1. Skill globs `design/prd/*.md` (N = 4; nothing under `reviews/` counts) and shows the Summary manifest
2. The registry is pre-loaded as the conflict baseline
3. Phase 2 and Phase 3 are spawned as parallel `product-manager` subagents, each given its slice of PRD content, the registry text and the feature-map rows
4. Phase 4 walks 3–5 multi-feature moments (e.g. a failed Toss Payments auto-debit on the day a Plus → Free downgrade applies) and finds nothing blocking
5. Verdict PASS; the skill asks to write the report; the closing widget offers `/create-architecture` and `/gate-check architecture`

**Assertions**:
- [ ] Both review phases are spawned in one parallel batch (not sequentially), and both receive pasted content, not file paths
- [ ] The report states `PRDs reviewed: 4 of 4 present` and names the phases run
- [ ] Output includes the findings structure (Consistency Issues, Product Issues, Cross-Feature Scenario Issues, PRDs Flagged for Revision, Not Assessed) even when empty
- [ ] Verdict is PASS when no blocking issue and no warning needing resolution exist
- [ ] The report is written only after approval, at `design/prd/reviews/prd-cross-review-YYYY-MM-DD.md` with the verdict line under the H1

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — a rule contradiction between two PRDs

**Fixture**:
- As Case 1, plus `design/prd/subscription.md`
- `goals.md` (Business Rules & Calculations): "Free plan: at most 3 active goals"
- `subscription.md` (Functional Requirements): "A user who downgrades to Free keeps all active goals"

**Expected behavior**:
1. Phase 2b reports a 🔴 Rule Contradiction naming both PRDs, the sections and the quoted rules
2. Verdict FAIL; "Required Actions" says what must change in which PRD
3. A second question asks "May I write this to `design/product/feature-map.md`? It marks these PRDs as needing revision: [list of flagged PRDs]"

**Assertions**:
- [ ] Verdict is FAIL (not CONCERNS) for a contradiction that makes a rule impossible to satisfy
- [ ] Both PRD paths and the contradicting rules are quoted, not summarised as "conflict found"
- [ ] The skill does NOT decide which PRD is right and does NOT edit either PRD
- [ ] The feature-map `Status` cell becomes exactly `Needs Revision` (no parenthetical), with nothing else in the map changed, only after approval
- [ ] The closing widget offers `/prd-review design/prd/subscription.md` (and the other flagged PRD)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: NOT ASSESSED — too few PRDs to compare

**Fixture A**:
- `design/prd/goals.md` is the only PRD

**Fixture B**:
- Four PRDs exist, but `design/product/product-brief.md` has no `## Product Principles & Anti-Goals` section

**Expected behavior**:
1. A: skill stops with NOT ASSESSED — "Cross-PRD review requires at least 2 PRDs. Write more PRDs first (`/write-prd <feature>`), then re-run `/review-all-prds`." — and writes no report
2. B: principle drift has no reference to drift from; the Product Holism scope is NOT ASSESSED; with no blocking issue or warning elsewhere the verdict is NOT ASSESSED, and the report's `## Not Assessed` section names the missing principles

**Assertions**:
- [ ] A: no report file is written, so the Definition → Architecture gate cannot be satisfied by a review that compared nothing
- [ ] B: verdict is NOT ASSESSED (not PASS), naming the missing input
- [ ] A present-but-empty PRD (headings only) is reported as not reviewable, never as consistent
- [ ] NOT ASSESSED never outranks a CONCERNS or FAIL finding made elsewhere in the same run

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Mode Variant — `since-last-review` scope

**Fixture**:
- `design/prd/reviews/prd-cross-review-2026-10-19.md` exists
- Since then only `design/prd/auth.md` changed; `design/prd/goals.md` lists `design/prd/auth.md` in its `## Dependencies` table

**Expected behavior**:
1. Skill runs `bash .claude/scripts/review-scope.sh since-last-review`
2. Output has `PRIOR_REVIEW:`, `CHANGED: auth.md` and a `DEPS` line `auth.md <- design/prd/goals.md`
3. In-scope set = auth.md plus goals.md (both directions of every dependency edge); the skill shows the set before any full read

**Assertions**:
- [ ] `goals.md` is in scope although it did not change
- [ ] A `CHANGED` path marked `(deleted)` or a `-> … (not found)` edge is reported as a stale reference
- [ ] With `PRIOR_REVIEW: NONE`, the skill falls back to `full` and says so
- [ ] The report's Focus line reads `since-last-review` and `PRDs reviewed: [N] of [M] present` shows the narrower set

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Mode Variant — a focused run names what it skipped

**Fixture**:
- As Case 1

**Expected behavior**:
1. `/review-all-prds consistency` runs Phase 2 only
2. The report's "Phases run" line names Product Holism and Scenarios as not run, with the reason (focus `consistency`)

**Assertions**:
- [ ] A `consistency` report says it is not a full cross-review
- [ ] Phase 4 (scenarios) is skipped in `consistency` and `product-theory` modes, and the report says so

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Edge Case — a phase agent returns no findings

**Fixture**:
- As Case 1; the Phase 3 subagent returns a fluent preamble with no findings section for its checklist items 3a–3f

**Expected behavior**:
1. The skill checks each returned phase for a findings section per assigned checklist item
2. Phase 3 is treated as a failed phase: resumed naming the missing items, or reported as NOT ASSESSED
3. The skill still produces a partial report

**Assertions**:
- [ ] A phase that returned nothing is NOT ASSESSED, not clean
- [ ] Verdict is NOT ASSESSED when no FAIL or CONCERNS finding exists elsewhere
- [ ] The report's `## Not Assessed` section names the phase and the checklist items missing

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: Edge Case — abuse paths and the credits economy

**Fixture**:
- `design/prd/referral.md`: "Referrer and referee each receive KRW 5,000 credit after the referee's first deposit"
- `design/prd/auth.md`: "Sign in with Apple accepts private relay e-mail addresses; one account per Apple ID"
- `design/prd/payments.md`: "The first deposit may be KRW 1,000"
- No PRD defines an expiry for referral credit

**Expected behavior**:
1. Phase 3c reports a 🔴 Abuse Path combining the three rules and asks which PRD owns the fix (verified identity or a minimum first deposit)
2. Phase 3d maps credit issuance and redemption and flags the missing expiry policy

**Assertions**:
- [ ] The abuse path cites all three PRDs and the rules involved
- [ ] In a variant where no PRD defines credits or metered usage, 3d records "N/A — no PRD defines credits or metered usage" instead of silence
- [ ] A blocking abuse path makes the verdict FAIL

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 8: Edge Case — tiers and report naming

**Fixture**:
- `modes.rigor: standard`; `feature_overrides.payments: full`; `design/prd/goals.md` lacks `## User Value`; `design/prd/payments.md` lacks `## Configuration & Flags`
- A report `design/prd/reviews/prd-cross-review-2026-11-02.md` already exists for today

**Expected behavior**:
1. The missing User Value in goals.md is surfaced as advisory (standard); the missing Configuration & Flags in payments.md is reported as missing (effective tier `full`)
2. Before writing, the skill says today's report exists and asks whether to replace it

**Assertions**:
- [ ] Each PRD is judged against its own effective tier, and advisory gaps are not reported as blocking
- [ ] The report file name uses an ISO 8601 date, so `review-scope.sh` picks the right baseline next time
- [ ] At `workflow: minimal` the skill says it is not applicable and reviews voluntarily written PRDs with every section check advisory

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses "May I write this review to `design/prd/reviews/prd-cross-review-YYYY-MM-DD.md`?" and "May I write this to `design/product/feature-map.md`? …" (through `AskUserQuestion`) before the report and before the feature-map update
- [ ] Presents the full consistency, product and scenario analysis before asking for any action
- [ ] Ends with a recommended next step: flagged PRDs → `/prd-review design/prd/<flagged>.md`; PASS or CONCERNS → `/create-architecture`; PASS → `/gate-check architecture`
- [ ] Does not auto-create files without user approval; does not edit PRDs
- [ ] Writes no evidence, reports or plans under `production/session-logs/` (gitignored)
- [ ] Never writes `modes.review_mode` or any other knob that `modes.rigor` fronts (`/settings` is the one exception)
- [ ] Surfaces a BLOCKED or failed phase agent immediately and still produces a partial report

---

## Coverage Notes

- The cognitive-load (3b), scope-drift (3e) and value-coherence (3f) checks are not
  individually fixture-tested; they share the finding shape of Cases 2 and 7.
- The Phase 4 severity levels (BLOCKER / WARNING / INFO) are asserted only through
  the verdict they produce.
- `review` R2 names `prd-structure-check.sh`; this skill evaluates
  the tier-required sections from its own section scan of the same contract
  headings — `/prd-review` is the skill that runs the script per PRD.
