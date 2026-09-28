# Skill Spec: /prd-review

> **Category**: review
> **Priority**: critical
> **Spec written**: 2026-09-28

## Skill Summary

`/prd-review` reviews **one** product document before anyone builds from it: a
feature PRD `design/prd/<stem>.md`, the product brief
`design/product/product-brief.md`, or the one-pager `design/product/one-pager.md`.
It resolves the document's effective tier (the `feature_overrides` entry for the
PRD stem, else the project `workflow`), gathers section presence with
`bash .claude/scripts/prd-structure-check.sh <path>` and judges it against the
tier's required set of the PRD section contract (11 sections at `full`, the 8
`standard` sections plus the conditional `## Business Rules & Calculations`, none
at `minimal`), then checks internal consistency, cross-document consistency (the
brief's principles and non-goals, the feature map, the glossary registry, the
PRDs it depends on) and implementability. In `full` review mode it spawns domain
consultants in parallel and a `product-manager` senior synthesis; in `lean` and
`solo` it runs as a single-session analysis. The verdict is APPROVED /
NEEDS REVISION / MAJOR REVISION NEEDED / NOT ASSESSED, recorded after approval in
the review log `<doc-dir>/reviews/<stem>-review-log.md` (`design/prd/reviews/…`
for a PRD, `design/product/reviews/…` for the brief or the one-pager), which
`/gate-check` reads. After APPROVED it offers to set the PRD's
`> **Status**: Approved` and the feature-map row `Approved`. It spawns no director
gate.

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`); `name: prd-review` equals the skill directory and the catalog `name`; `model: sonnet`
- [ ] Bootstrap: the first body line is `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,feature_overrides` `` and `allowed-tools` grants `Bash(bash "*/.claude/skills/prd-review/../../hooks/yaml-helper.sh" resolve_config *)`
- [ ] The line after the bootstrap block is exactly: ``Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] The automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") follows that line verbatim
- [ ] `allowed-tools` is exactly: Read, Glob, Grep, Write, Edit, Bash, Agent, AskUserQuestion, plus the grant (membership exact, order free); no `disable-model-invocation`, no `isolation`
- [ ] 2+ phase headings found
- [ ] Verdict keywords present, exactly: `APPROVED`, `NEEDS REVISION`, `MAJOR REVISION NEEDED`, `NOT ASSESSED`
- [ ] "May I write this to `<doc-dir>/reviews/<stem>-review-log.md`?" (and "May I write this to `<target-doc-path>`?" before a revision) present before each write
- [ ] Outputs at the exact paths: `design/prd/reviews/<stem>-review-log.md` for a PRD, `design/product/reviews/<stem>-review-log.md` for the brief or the one-pager; a new log starts with `# Review Log: [Document Title]` followed, after one blank line, by `> **Verdict**: <TOKEN>` holding the latest entry's verdict
- [ ] Section presence for a PRD comes from `bash .claude/scripts/prd-structure-check.sh design/prd/<stem>.md`; the section names are exactly the 11 contract headings of `.claude/docs/templates/prd.md`
- [ ] No `!` injection other than the bootstrap line; no `file:line` citations of other files
- [ ] Next-step handoff section present at end (Phase 5d), naming skills by their current names

---

## Director Gate Checks

- **Full mode**: no director gate. `review_mode` controls review depth only — domain consultants spawn in parallel (Phase 3b), then `product-manager` as senior reviewer.
- **Lean mode**: no director gate; single-session analysis, no agents; output says "Consultants: none — lean mode".
- **Solo mode**: no director gate; single-session analysis; the closing widget is replaced by a one-line recommended next step.
- **N/A**: the skill is the review — it never delegates its verdict to a director gate, so no gate ID is spawned or skipped in any mode.

---

## Test Cases

### Case 1: Happy Path — a `standard` PRD with every required section

**Fixture** (assumed project state):
- `modes.rigor: standard` (resolves `workflow: standard`, `review_mode: lean`); no `feature_overrides` entry for `goals`
- `design/prd/goals.md` has the preamble (`> **Status**: In Review`, `> **Feature Map Tier**: MVP`, `> **Implements Principle**: Saving happens without willpower`), `## Summary` with the Quick reference line, and real content under Overview, Goals & Non-Goals, Functional Requirements, Business Rules & Calculations (goal target ≤ KRW 100,000,000; Free plan ≤ 3 active goals), Edge Cases, Dependencies, Non-Functional Requirements, Success Metrics & Instrumentation and Acceptance Criteria
- `design/prd/auth.md` lists goals as `depended on by`; the feature-map row for goals agrees with the PRD's Dependencies table and tier
- `design/product/product-brief.md` names the principle; `design/registry/entities.yaml` agrees with the PRD's plan limits

**Expected behavior**:
1. Freshness check with `bash .claude/scripts/review-receipts.sh check "design/prd/reviews/goals-review-log.md" "design/prd/goals.md" "design/registry/entities.yaml"` returns `RECEIPT: NONE` — full review
2. `prd-structure-check.sh` reports the sections PRESENT; Step 2b marks each REQUIRED or ADVISORY for `standard`
3. Consistency and implementability checks pass (one business-rule example worked through against an acceptance criterion)
4. Verdict APPROVED; one `AskUserQuestion` with `multiSelect: true` — "Verdict: APPROVED. I can update the tracking records now. Select any you'd like me to complete:" — offers appending to the review log, setting the PRD Status to Approved, and setting the feature-map row to Approved

**Assertions**:
- [ ] Completeness reads "9/9" — the 8 `standard` sections plus Business Rules & Calculations, required here because the feature defines numeric rules — never "N/11": User Value and Configuration & Flags are advisory at `standard` and are not listed as missing
- [ ] The review names its tier and the tier's source (the `feature_overrides` entry for the stem, else the project `workflow` value)
- [ ] Output includes a Dependency Graph block checking both ends of every Dependencies row and the feature-map row
- [ ] Verdict is APPROVED only after the document was read and judged
- [ ] The review log entry carries `## Review — [YYYY-MM-DD] — Verdict: APPROVED`, the tier, the review mode, the findings (or `- none`) and a `review-receipts.sh hash` line; the `> **Verdict**:` line under the H1 equals the latest entry
- [ ] Selecting an option is the approval for that path; nothing unselected is written

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — MAJOR REVISION NEEDED

**Fixture**:
- As Case 1, but `design/prd/goals.md` has no `## Business Rules & Calculations` although its Functional Requirements define a monthly auto-debit limit and KRW rounding, and it has no `## Acceptance Criteria`
- Its Functional Requirements let Free users keep 5 active goals, while `design/registry/entities.yaml` records the plan limit (source `design/prd/subscription.md`) as 3

**Expected behavior**:
1. `prd-structure-check.sh` lists the two sections under `ABSENT:`
2. Business Rules & Calculations is REQUIRED because the feature defines numeric rules (decided from the Functional Requirements content, not from the feature's Category)
3. The registry contradiction is flagged: the entry's `source:` PRD is authoritative
4. Verdict MAJOR REVISION NEEDED; the skill asks "May I write this to `<doc-dir>/reviews/<stem>-review-log.md`? It appends this review, so future re-reviews can track what changed." (here `design/prd/reviews/goals-review-log.md`) and, separately, whether to set the PRD `> **Status**` and its feature-map row to `Needs Revision`

**Assertions**:
- [ ] Verdict is MAJOR REVISION NEEDED (not NEEDS REVISION): required sections carrying core behaviour are missing and a fact another PRD owns is contradicted
- [ ] Each missing REQUIRED section is named, and each finding names its section and quotes the text involved
- [ ] The PRD Status and the feature-map row move together (`Needs Revision` ↔ `Needs Revision`), only after approval
- [ ] The document itself is not edited unless the user selects `[A] Revise the document now — address the blocking items together` and approves "May I write this to `<target-doc-path>`?" (here `design/prd/goals.md`)
- [ ] The post-revision widget does not offer `[B] Accept the revisions and mark Approved — skip the re-review` for a MAJOR REVISION NEEDED document

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: NOT ASSESSED — the document or its reference is missing

**Fixture A**:
- `/prd-review design/prd/referrals.md` — the file does not exist

**Fixture B**:
- `design/prd/goals.md` exists, but neither `design/product/product-brief.md` nor `design/product/one-pager.md` exists

**Expected behavior**:
1. A: skill stops with NOT ASSESSED and names the skill that writes the document (`/write-prd referrals`)
2. B: the brief-alignment check cannot run; the skill says so and the verdict is NOT ASSESSED, naming the brief as the missing input and `/brainstorm` as the skill that writes it; the review log is offered with the same prompt

**Assertions**:
- [ ] Verdict is NOT ASSESSED in both fixtures, with the missing input named
- [ ] No APPROVED verdict is produced — a review that could not find its input approved nothing
- [ ] NOT ASSESSED is not presented as a gentler MAJOR REVISION NEEDED; the remedy named is producing the input
- [ ] A path that is not a PRD, the brief or the one-pager (e.g. `design/ux/goal-create.md`) also stops with NOT ASSESSED and names the right tool (`/ux-review`)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Mode Variant — `full` review mode spawns consultants

**Fixture**:
- As Case 1, run with `--review full`
- The PRD touches pricing (Plus plan price), personal data (linked bank account) and push notifications

**Expected behavior**:
1. Skill prints the notice "Full review: spawning consultants in parallel. This typically takes 8–15 minutes. Use `--review lean` for a faster single-session analysis."
2. Consultants spawn in one parallel batch as real `Agent` calls — at least `monetization-strategist`, `security-engineer`, `backend-engineer`, `mobile-engineer`, `analytics-engineer` and `qa-lead` for this PRD
3. Then `product-manager` runs as senior reviewer; its synthesis is the final verdict
4. Disagreements between consultants are presented, each finding tagged with its source

**Assertions**:
- [ ] Consultants are spawned as subagents, never simulated in the main session
- [ ] `product-manager` is not in the parallel batch; it synthesises after every consultant has returned
- [ ] A consultant that returns nothing is named ("`security-engineer`: NOT CHECKED — no report returned") and carried into the verdict
- [ ] Under `lean`, the same PRD gets "Consultants: none — lean mode" and no `Agent` call; under `solo`, the closing widget becomes a one-line next step

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Edge Case — per-feature tier and re-review receipts

**Fixture**:
- `modes.rigor: standard`; `workflow_overrides.feature_overrides.payments: full`
- `design/prd/payments.md` has the 8 `standard` sections but no `## User Value` and no `## Configuration & Flags`
- `design/prd/reviews/goals-review-log.md` exists with a receipt, latest verdict NEEDS REVISION, and `design/prd/goals.md` is byte-identical since

**Expected behavior**:
1. `/prd-review design/prd/payments.md`: the effective tier is `full` (from `feature_overrides`); User Value and Configuration & Flags are REQUIRED and missing ⇒ blocking
2. `/prd-review design/prd/goals.md`: every receipt line reads `UNCHANGED`; the skill says the document has not changed since it failed review, the prior findings stand, and revising is the next step

**Assertions**:
- [ ] The payments review names "tier `full` from feature_overrides" and requires all 11 sections
- [ ] The unchanged goals PRD is not re-reviewed as if new, and no partial or delta re-review that skips unchanged sections is offered
- [ ] For an unchanged document whose prior verdict was APPROVED, the offer is `[A] Use the prior verdict (Recommended)` / `[B] Re-review anyway`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Mode Variant — reviewing the product brief

**Fixture**:
- `modes.rigor: standard`; `design/product/product-brief.md` exists with every required section; principles state their trade-offs; a North Star and a guardrail metric are defined
- `design/product/reviews/` holds no log yet

**Expected behavior**:
1. The brief's REQUIRED set is the seven sections `/gate-check definition` checks plus `## Non-Goals`; Elevator Pitch, Alternatives & Positioning, Business Model Hypothesis and Open Questions are advisory; `## Brand Direction Anchor` is never a finding at `standard`
2. Verdict APPROVED; the only record offered is the log `design/product/reviews/product-brief-review-log.md`
3. The closing widget offers `/gate-check definition` (and `/setup-stack` when the stack is not pinned)

**Assertions**:
- [ ] Brief headings are compared by exact text, because `/gate-check` matches on it
- [ ] The review log path is `design/product/reviews/product-brief-review-log.md`
- [ ] No PRD Status or feature-map update is offered for the brief

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: Mode Variant — 5c [C] Accept as-is

**Fixture**:
- `modes.rigor: standard`, `modes.automation: collaborative`
- `/prd-review design/prd/goals.md` has just reached NEEDS REVISION with two blocking items; the 5a review entry (with its hash line) was written to `design/prd/reviews/goals-review-log.md`
- At 5c the user picks `[C] Accept as-is — you judge every blocking item deferrable`

**Expected behavior**:
1. The skill asks for a one-line reason per blocking item
2. Asks "May I write this to `design/prd/reviews/goals-review-log.md`?"
3. Appends `## Revision — [YYYY-MM-DD] — Accepted as-is` with an `Accepted:` line per blocking item (item → the user's reason) and no hash line
4. The log's `> **Verdict**:` line stays NEEDS REVISION
5. Offers to set the PRD `Status` and its feature-map row to `Approved`
6. A later `/prd-review design/prd/goals.md` on the byte-identical PRD names both dates (the review and the acceptance) and offers `[A] Use the prior verdict (Recommended)` / `[B] Re-review anyway`

**Assertions**:
- [ ] `[C]` is not offered for MAJOR REVISION NEEDED
- [ ] Autonomous mode never picks `[C]`: it takes `[B]` and logs it via `log_decision`
- [ ] The acceptance note carries no hash line
- [ ] Any later edit to the PRD reads `CHANGED` and gets a full review

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses "May I write this to `<path>`?" before the review log, every status change and every revision (or the multi-select approval for APPROVED tracking updates)
- [ ] Presents the full review and verdict before any write is offered (Phase 4 writes nothing)
- [ ] Ends with a recommended next step or follow-up action (`/prd-review` for other In Review PRDs, `/consistency-check`, `/review-all-prds`, `/write-prd <next-feature>`, `/propagate-prd-change`, `/gate-check definition`)
- [ ] Does not auto-create files without user approval
- [ ] Writes no evidence, reports or plans under `production/session-logs/` (gitignored)
- [ ] Never writes `modes.review_mode` or any other knob that `modes.rigor` fronts (`/settings` is the one exception)
- [ ] Never inflates an advisory gap into a blocker at a tier that does not require it

---

## Coverage Notes

- The consultant routing table (business-analyst, monetization-strategist,
  backend-engineer, frontend-engineer, mobile-engineer, security-engineer,
  analytics-engineer, product-designer, qa-lead, performance-engineer) is sampled in
  Case 4, not exhaustively.
- The one-pager review (`minimal`) and a voluntary PRD at `minimal` (reviewed
  advisorily against the eight `standard` sections) are not tested.
- The scope signal (S / M / L / XL) is advisory and not asserted.
- Registry-only changes (the document `UNCHANGED`, the registry `CHANGED`) re-verify
  only registry-sourced values; not tested here.
