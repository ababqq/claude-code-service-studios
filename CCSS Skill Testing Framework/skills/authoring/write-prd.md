# Skill Spec: /write-prd

> **Category**: authoring
> **Priority**: high
> **Spec written**: 2026-09-28

## Skill Summary

`/write-prd` writes the product requirements document for **one feature**, `design/prd/<feature>.md`, one section at
a time. It reads the product brief (or the one-pager on a `minimal` project), the feature map, the PRDs this feature
depends on and the glossary registry before asking anything; creates a skeleton whose headings are byte-identical, in
order, to `.claude/docs/templates/prd.md`; then walks the eleven contract sections (`## Overview`,
`## Goals & Non-Goals`, `## User Value`, `## Functional Requirements`, `## Business Rules & Calculations`,
`## Edge Cases`, `## Dependencies`, `## Non-Functional Requirements`, `## Configuration & Flags`,
`## Success Metrics & Instrumentation`, `## Acceptance Criteria`) plus the non-contract `## UI Requirements`,
`## API & Data Impact` and `## Open Questions`, consulting routed specialists per section. The effective tier comes
from `feature_overrides` (`<slug>=<tier>`) or `workflow`. Side outputs: the feature-map row (`Not Started` →
`Drafting` → `In Review`), `design/registry/entities.yaml` (append), `design/product/tracking-plan.md` (append events)
and `design/product/pricing-model.md` (when the PRD defines plans, prices, credits or promotions). It spawns the
PD-PRD-ALIGN gate (`product-director`) under the review-mode rules. Run verdicts: `DRAFT COMPLETE` /
`INCOMPLETE — MISSING <sections>` / `NOT ASSESSED`, precedence INCOMPLETE > NOT ASSESSED > DRAFT COMPLETE; the PRD
itself carries no verdict line — its state is `> **Status**:`. The review hand-off is `/prd-review` in a **fresh**
session.

Assertions quote the canonical English text of `.claude/skills/write-prd/SKILL.md`; prompts are rendered in the
user's conversation language at run time (`.claude/docs/coding-standards.md` § Language Policy) and this spec never
asserts the runtime wording.

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] `name: write-prd` equals the directory name (`.claude/skills/write-prd/`) and this spec's basename
- [ ] `argument-hint` is `"<feature-name> [--review full|lean|solo]"`
- [ ] The first body line is exactly
      `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,docs.density,feature_overrides,accessibility` ``
      — the `--keys` value is exactly `review_mode,automation,workflow,docs.density,feature_overrides,accessibility`
- [ ] `allowed-tools` contains the grant naming this skill's own directory:
      `Bash(bash "*/.claude/skills/write-prd/../../hooks/yaml-helper.sh" resolve_config *)`
- [ ] `allowed-tools` is exactly the set Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, TaskCreate, TaskGet,
      TaskList, TaskUpdate plus that grant — no plain `Bash`, no MCP tool names
- [ ] The line after the bootstrap block is exactly: ``Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] The automation prelude block — from `**Automation mode**: Resolve` to `categories always prompt).` — follows
      that line verbatim
- [ ] The bootstrap line is the only `!` injection in the file; no `file:line` citation of another file
- [ ] `model: sonnet`; no `disable-model-invocation` and no `isolation` key
- [ ] ≥2 phase headings (Phase 1 through Phase 5)
- [ ] The run verdict tokens are spelled exactly: `DRAFT COMPLETE`, `INCOMPLETE — MISSING <sections>`, `NOT ASSESSED`
- [ ] Every output is named: `design/prd/<feature>.md`, `design/product/feature-map.md`,
      `design/registry/entities.yaml`, `design/product/tracking-plan.md`, `design/product/pricing-model.md`
- [ ] "May I write this to `<path>`?" appears before the skeleton and each other file write; the side outputs use the
      canonical prompts "May I append these events to `design/product/tracking-plan.md`?" and
      "May I create/update `design/product/pricing-model.md`?"
- [ ] The skill states that the skeleton is byte-identical in headings and order to `.claude/docs/templates/prd.md`
- [ ] The `## Dependencies` table header is spelled `| Feature | PRD | Direction | Nature |`
- [ ] The PD-PRD-ALIGN spawn carries this `Pass:` line verbatim:
      `Pass: PRD path · product brief path (or one-pager path) · feature-map row for the feature (tier, status) · brief success metrics`
- [ ] The spawn prompt tells `product-director` to read `.claude/docs/director-gates/pd-prd-align.md` itself, and the
      parent parses the first reply line as `[PD-PRD-ALIGN]: TOKEN`
- [ ] Next-step handoff at the end (5f: `/prd-review` in a fresh session; 5g: closing `AskUserQuestion`)

---

## Director Gate Checks

The skill spawns one director gate, **PD-PRD-ALIGN** (`product-director`), in Phase 5b — after the self-check (5a)
and before the registry and status updates. `--review full|lean|solo` overrides the resolved `review_mode`.

- **Full mode**: PD-PRD-ALIGN spawns with the four Context items; every section's consultants are spawned.
- **Lean mode**: the lean suffix rule skips PD-PRD-ALIGN (`[PD-PRD-ALIGN] skipped — Lean mode`, written into the PRD
  header where the review line goes). Consultants run only for Business Rules & Calculations and Acceptance Criteria;
  the other drafts carry a note naming who was not consulted.
- **Solo mode**: PD-PRD-ALIGN skipped (`[PD-PRD-ALIGN] skipped — Solo mode`); no consultant is spawned and each draft
  says "<agents> not consulted — Solo mode. Review manually before implementation."
- **N/A**: a run that ends `NOT ASSESSED` or `INCOMPLETE` before 5b spawns no gate.

The review outcome line goes directly under `> **Feature Map Tier**:`:
`> **Product Director Review (PD-PRD-ALIGN)**: APPROVED <date>` / `CONCERNS (accepted) <date>` / `REVISED <date>`.

---

## Test Cases

### Case 1: Happy Path — `/write-prd goals` at `standard`, full review

**Fixture** (assumed project state):
- Moa; the config block prints `review_mode: full (project.yaml)`, `automation: collaborative (default)`,
  `workflow: standard (rigor:standard)`, `docs.density: balanced (rigor:standard)`, `feature_overrides: none`,
  `accessibility.target: wcag-aa (project.yaml)`
- `design/product/product-brief.md` and `design/product/feature-map.md` exist; the `goals` row is
  `| goals | Domain | Feature | MVP | Not Started | — | auth, subscription |`
- `design/prd/auth.md` and `design/prd/subscription.md` are `Approved`; `design/registry/entities.yaml` registers the
  constant `free_active_goal_limit` (value 3, `source: design/prd/subscription.md`)
- `design/product/tracking-plan.md` does not exist; the user converses in Korean

**Input:** `/write-prd goals`

**Expected behavior:**
1. Phase 1 resolves the effective tier `standard` (source `workflow`); Phase 2 reads the brief, the feature map, the
   registry (live entries only, never commented examples) and the dependency sections of `auth.md` and
   `subscription.md` by grep, then presents the context summary with the locked registry facts
2. Phase 3 asks "May I write this to `design/prd/goals.md`?" and, in the same approval, "May I write this to
   `design/product/feature-map.md`?" (row → `Drafting`, `PRD` = `design/prd/goals.md`); one task per section is
   created with TaskCreate; `production/session-state/active.md` STATUS and CHECKPOINT blocks are overwritten
3. Phase 4 walks the sections in contract order with the section cycle; Business Rules & Calculations is required
   because the feature states a limit; each rule starts with the `**Rule: <rule_name>**` structure and its variable
   table (`| Symbol | Type | Unit | Range | Source | Description |`)
4. Consultants follow the routing table — e.g. `backend-engineer`, `frontend-engineer`, `mobile-engineer`,
   `security-engineer` and `accessibility-specialist` for Non-Functional Requirements, spawned in parallel
5. After Success Metrics & Instrumentation: "May I append these events to `design/product/tracking-plan.md`?" — the
   file is created from `.claude/docs/templates/tracking-plan.md`; each row has `Owner PRD` = `design/prd/goals.md`
6. 5-pre writes `## Summary` and the Quick reference; 5a reads the file back; 5b spawns PD-PRD-ALIGN (APPROVE)
7. 5c proposes registry candidates; 5d moves `> **Status**: Draft` → `In Review` and the feature-map row to
   `In Review` as one listed changeset
8. 5f prints `Verdict: DRAFT COMPLETE` and the fresh-session hand-off to `/prd-review design/prd/goals.md`

**Assertions:**
- [ ] The skeleton's `#`, `##` and `###` headings are byte-identical, in order, to `.claude/docs/templates/prd.md`
      at every tier — sections the tier does not require keep their heading
- [ ] Headings and `> **Field**:` labels stay in English; the section bodies are written in Korean
- [ ] No section is written before the user approves it (collaborative); the draft and the approval widget appear in
      the same response
- [ ] The `## Dependencies` table has the exact header and a PRD path in every row
- [ ] `### Accessibility` states the resolved `accessibility.target` line (`wcag-aa`) and what it means for the
      feature's screens; had the line printed unset, the sub-section would read
      `NOT DETERMINED — accessibility.target unset (run /ux-design accessibility)` — never none
- [ ] The PRD status and the feature-map status move together (`Draft` ↔ `Drafting`, `In Review` ↔ `In Review`)
- [ ] `/prd-review` is never offered inline — only in a fresh session

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: NOT ASSESSED — no product brief (missing input)

**Fixture:**
- `workflow: standard (rigor:standard)`; `design/product/product-brief.md` does not exist;
  `design/product/feature-map.md` exists
- Variant: the brief exists but the user declines the skeleton in Phase 3

**Input:** `/write-prd goals`

**Expected behavior:**
1. Phase 2a stops with "No product brief found. Run `/brainstorm` first." and the verdict
   `NOT ASSESSED — no product brief`
2. Variant: the skill stops with "Verdict: **NOT ASSESSED** — skeleton creation declined; no PRD was written."

**Assertions:**
- [ ] No file is written, no gate is spawned, no consultant is spawned
- [ ] The verdict is `NOT ASSESSED` with the reason named — never `DRAFT COMPLETE` or `INCOMPLETE`
- [ ] A missing feature map at `standard` stops the same way with `NOT ASSESSED — no feature map` and points at
      `/map-features`
- [ ] `/write-prd` with no argument and no feature map stops with the usage message and the verdict
      `NOT ASSESSED — no feature named`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Retrofit — fill mode on an existing PRD

**Fixture:**
- `design/prd/goals.md` exists with `> **Status**: Approved`; `## Edge Cases` holds only `[To be designed]` and
  `## Non-Functional Requirements` is missing; one heading is written `## 3) Functional Requirements`

**Input:** `/write-prd design/prd/goals.md`

**Expected behavior:**
1. Fill mode detects present sections with the tolerant rule (case-insensitive, prefix match, optional `3. ` / `3) `
   numbering) — `## 3) Functional Requirements` counts as present
2. The Fill summary lists sections already written (not touched), required-and-missing ones and optional ones
3. "Shall I fill the <N> missing sections? I will not modify any existing content."
4. Missing headings are inserted at their contract position with a placeholder (asking first); only missing or
   placeholder sections are authored
5. Because the PRD was `Approved`, the skill says this revises an approved contract, recommends
   `/propagate-prd-change design/prd/goals.md` and moves the status back to `In Review` only with the user's agreement

**Assertions:**
- [ ] Existing section content is never overwritten — Edit replaces only a placeholder or an empty body
- [ ] A section absent from the file is reported as a gap only when the effective tier requires it
- [ ] The closing widget offers `/propagate-prd-change design/prd/goals.md`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Mode Variant — `feature_overrides` raises one feature on a `minimal` project; pricing model

**Fixture:**
- The config block prints `workflow: minimal (rigor:minimal)`, `review_mode: solo (rigor:minimal)` and
  `feature_overrides: payments=full`; `design/prd/payments.md` does not exist yet
- `design/product/one-pager.md` exists; no product brief and no feature map (neither is written at `minimal`)
- The feature defines the Plus plan price (KRW 4,900 per month, VAT included) and a first-month coupon

**Input:** `/write-prd payments`

**Expected behavior:**
1. The effective tier is `full` (source `feature_overrides`); the key naming a PRD that does not exist yet is healthy
   and never reported as an orphan
2. The required *reads* follow the project tier: the one-pager is read in place of the brief and the feature-map read
   is skipped; `Category`, `Layer` and `Tier` are derived once from the one-pager and marked inferred in the Quick
   reference
3. All eleven contract sections are required (effective tier `full`)
4. Business Rules & Calculations consults `business-analyst` and `monetization-strategist`; then "May I create/update
   `design/product/pricing-model.md`?" — created from `.claude/docs/templates/pricing-model.md` with every template
   heading kept

**Assertions:**
- [ ] The skill never writes a feature map on a `minimal` project (5d says so in one line and continues)
- [ ] The pricing model is created only after the explicit question; a price already recorded there is never changed
      silently
- [ ] Money is integer KRW and the price states whether VAT is included
- [ ] Solo mode applies to consultants and the gate (see Case 8) independently of the effective tier

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Edge Case — registry conflict surfaced before the next section

**Fixture:**
- Case 1 state; while drafting Business Rules & Calculations the user writes a free-plan limit of 5 active goals,
  while the registry holds `free_active_goal_limit` = 3 from `design/prd/subscription.md`

**Input:** `/write-prd goals`

**Expected behavior:**
1. The registry conflict check after Business Rules & Calculations compares values and finds the difference
2. The skill says: "Registry conflict: free_active_goal_limit is registered by design/prd/subscription.md as 3. This
   section just wrote 5. Which is correct?" — before Edge Cases starts
3. The user decides; the skill never changes the registered value without surfacing it as a conflict

**Assertions:**
- [ ] The conflict is surfaced before the next section is drafted
- [ ] Registry writes (5c) only append entries or `referenced_by` values; nothing is deleted
- [ ] An upstream dependency without a PRD is flagged provisional, never assumed

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Review Mode — `full`, PD-PRD-ALIGN returns CONCERNS

**Fixture:**
- Case 1 state at Phase 5b; `review_mode: full (project.yaml)`
- The gate's first reply line is `[PD-PRD-ALIGN]: CONCERNS` (Goals do not trace to the brief's success metrics)

**Input:** `/write-prd goals`

**Expected behavior:**
1. The spawn prompt instructs `product-director` to read `.claude/docs/director-gates/pd-prd-align.md` first
2. Pass items: `design/prd/goals.md`; `design/product/product-brief.md`; `goals — Tier MVP, Status Drafting`; the
   brief's `## Success Metrics` North Star and guardrails
3. The concerns are presented with `Revise flagged sections` / `Accept and proceed` / `Discuss further`; revising
   re-runs the section cycle for the named sections only, then 5a
4. The outcome is recorded under `> **Feature Map Tier**:` after asking

**Assertions:**
- [ ] The first reply line is parsed as `[PD-PRD-ALIGN]: TOKEN`; an unparseable line is CONCERNS-class
- [ ] The skill does not move the status to `In Review` past an unresolved CONCERNS-class or REJECT-class verdict
- [ ] A REJECT the user does not resolve ends as `INCOMPLETE — MISSING <the named sections>` with the PRD left `Draft`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: Review Mode — `lean` skips PD-PRD-ALIGN by the suffix rule

**Fixture:**
- Case 1 state; the config block prints `review_mode: lean (rigor:standard)`

**Input:** `/write-prd goals`

**Expected behavior:**
1. Consultants are spawned only for Business Rules & Calculations and Acceptance Criteria; every other draft carries
   the note naming the agents not consulted
2. Phase 5b applies the lean suffix rule; PD-PRD-ALIGN does not end in `-PHASE-GATE` and is skipped
3. `> [PD-PRD-ALIGN] skipped — Lean mode` is written into the PRD header where the review line goes, and the summary
   says "PD-PRD-ALIGN not consulted — Lean mode; `--review full` runs it."

**Assertions:**
- [ ] The SKILL.md review-mode check contains the sentence
      `` `lean` → **skip every gate whose ID does not end in `-PHASE-GATE`**. Note: `[GATE-ID] skipped — Lean mode` ``
- [ ] No `product-director` spawn in lean mode
- [ ] The skip note is in the artifact, so a later `/gate-check` can see the mode was applied
- [ ] A gate skipped by review mode does not prevent `DRAFT COMPLETE`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 8: Review Mode — `solo`

**Fixture:**
- The config block prints `review_mode: solo (rigor:minimal)`; `workflow: minimal (rigor:minimal)`; the user writes
  a voluntary PRD for `notifications` from the one-pager

**Input:** `/write-prd notifications`

**Expected behavior:**
1. The skill says a PRD is optional at `minimal` and recommends the eight `standard` sections; the user chooses
2. No consultant is spawned; each draft carries "<agents> not consulted — Solo mode. Review manually before
   implementation."
3. Phase 5b skips the gate: `> [PD-PRD-ALIGN] skipped — Solo mode` in the header
4. Declined sections carry `> Not authored — optional at the minimal workflow tier.`

**Assertions:**
- [ ] No gate agent and no consultant is spawned in solo mode
- [ ] The skip note reads exactly `[PD-PRD-ALIGN] skipped — Solo mode`
- [ ] The skill never writes `modes.review_mode` or any other rigor-fronted knob

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 9: Edge Case — session stops with required sections unwritten

**Fixture:**
- Case 1 state; the user stops after Dependencies, leaving Non-Functional Requirements, Success Metrics &
  Instrumentation and Acceptance Criteria as placeholders

**Input:** `/write-prd goals`

**Expected behavior:**
1. 5a reads the file back and finds required sections still `[To be designed]`
2. The verdict is `INCOMPLETE — MISSING Non-Functional Requirements, Success Metrics & Instrumentation, Acceptance Criteria`
3. The PRD stays `Draft`, the feature-map row stays `Drafting`, and the skill skips to 5e (session state)
4. The closing widget offers `/write-prd goals` to resume

**Assertions:**
- [ ] Verification counts the sections the effective tier requires — never a fixed number
- [ ] `INCOMPLETE` outranks `NOT ASSESSED` and `DRAFT COMPLETE`
- [ ] A later run of `/write-prd goals` resumes at the next incomplete section without re-discussing approved ones

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses "May I write this to `<path>`?" before the skeleton, every section write and every other file
- [ ] Presents the context summary, the constraints brief and each drafted section before asking for approval
- [ ] Ends with the fresh-session review hand-off and a closing `AskUserQuestion`; never runs `/prd-review` inline
- [ ] Does not auto-create files; never adds rows to the feature map (`/map-features` owns the feature set)
- [ ] Never invents a baseline, a price or a limit — an unknown number is `NOT DETERMINED — <reason>`
- [ ] Never commits

**Authoring rubric** (`CCSS Skill Testing Framework/quality-rubric.md` § `authoring`):

- [ ] A1 — Section-by-section cycle (Context → Questions → Options → Decision → Draft → Approval → Write)
- [ ] A2 — "May I write" per section in `collaborative`; `guided` and `autonomous` follow
      `.claude/docs/automation-modes.md` (major decisions such as a limit or a price are still asked in `guided`)
- [ ] A3 — Retrofit: fill mode detects an existing PRD and authors only missing or placeholder sections
- [ ] A4 — PD-PRD-ALIGN runs in `full`, is skipped with a named note in `lean` and `solo`
- [ ] A5 — Skeleton headings byte-identical to the template file (`.claude/docs/templates/prd.md`), at every tier

---

## Coverage Notes

- `guided` and `autonomous` automation paths (`log_decision` entries per section) are covered only by A2.
- The bidirectional Dependencies edit of another PRD (reverse row only, asked first) is not given its own case.
- The Business Rules escalation from Acceptance Criteria (a quantity stated in Functional Requirements after the
  section was skipped at `standard`) is covered structurally, not fixture-tested.
- The context-window notice at ≥70 % depends on the runtime status line and is outside a static read.
