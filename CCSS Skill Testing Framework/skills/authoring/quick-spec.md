# Skill Spec: /quick-spec

> **Category**: authoring
> **Priority**: low
> **Spec written**: 2026-09-28

## Skill Summary

`/quick-spec` is the lightweight specification path for changes that do not need a PRD: a **Config** change (values
only), a **Tweak** (small behaviour change, no new states, screens or operations), an **Enhancement** (a small
addition — one or two states, one screen, a few additive operations) or a **Small Feature** (standalone, no PRD,
under about a week of work). It classifies the change and confirms the class with the user, scans the feature's PRD
(`## Configuration & Flags`, `## Business Rules & Calculations`, `## Functional Requirements`,
`## Acceptance Criteria`), the feature map and earlier quick specs, and drafts the category's format. Every format
carries a **rollout note** (`## Rollout` — flag, staged exposure, guardrails, rollback), `## Acceptance Criteria` and a
`## Story Embed` block a story can copy using the existing story fields. It writes
`design/quick-specs/<kebab-title>-YYYY-MM-DD.md`, and edits the PRD only after a separate explicit approval. Changes to
pricing or billing, new kinds of personal data, access rules, breaking API changes, non-additive migrations, feature-map
features and work over a week are **redirected** to `/write-prd`. It spawns no agents and no director gates. Run
verdicts: `COMPLETE` / `REDIRECTED` / `NOT ASSESSED`.

Assertions quote the canonical English text of `.claude/skills/quick-spec/SKILL.md`; prompts are rendered in the
user's conversation language at run time (`.claude/docs/coding-standards.md` § Language Policy) and this spec never
asserts the runtime wording.

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] `name: quick-spec` equals the directory name (`.claude/skills/quick-spec/`) and this spec's basename
- [ ] `argument-hint` is `"[brief description of the change]"`
- [ ] The first body line is exactly
      `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation` ``
      — the `--keys` value is exactly `automation`
- [ ] `allowed-tools` contains the grant naming this skill's own directory:
      `Bash(bash "*/.claude/skills/quick-spec/../../hooks/yaml-helper.sh" resolve_config *)`
- [ ] `allowed-tools` is exactly the set Read, Glob, Grep, Write, Edit, AskUserQuestion plus that grant — no `Agent`,
      no plain `Bash`, no MCP tool names
- [ ] The line after the bootstrap block is exactly: ``Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.``
      (the variant without `--review`, because `review_mode` is not among the keys)
- [ ] The automation prelude block — from `**Automation mode**: Resolve` to `categories always prompt).` — follows
      that line verbatim
- [ ] The bootstrap line is the only `!` injection in the file; no `file:line` citation of another file
- [ ] `model: sonnet`; no `disable-model-invocation` and no `isolation` key
- [ ] ≥2 phase headings (`## 1. Classify the Change` through `## 5. Handoff`)
- [ ] The verdict tokens are spelled exactly: `COMPLETE`, `REDIRECTED`, `NOT ASSESSED`
- [ ] The output path is named: `design/quick-specs/<kebab-title>-YYYY-MM-DD.md`
- [ ] "May I write this to `design/quick-specs/<kebab-title>-YYYY-MM-DD.md`?" appears before the spec write, and a
      separate "May I write this to `design/prd/[feature].md` …?" before any PRD edit
- [ ] The four categories are named exactly `Config`, `Tweak`, `Enhancement` and `Small Feature`, with the format
      headings `### For Config changes`, `### For Tweak and Enhancement changes` and `### For Small Feature changes`
- [ ] Every category format contains `## Rollout`, `## Acceptance Criteria` and `## Story Embed`
- [ ] The Story Embed block uses only existing story fields (`> **Type**:`, `> **Surface**:`, `**PRD**:`,
      `**Requirement**:`, `**API Contract**:`, `**Migration**:`, `**Feature Flag**:`, `**Analytics Events**:`) and the
      Type values `Config | Logic | Integration | UI | E2E`
- [ ] Next-step handoff at the end (the closing `AskUserQuestion` of `### Closing`)

---

## Director Gate Checks

None. `/quick-spec` has no `review_mode` key and no `Agent` tool: it spawns no director gate and no specialist. Quick
specs bypass `/prd-review` and `/review-all-prds` by design; the story that embeds the spec is checked by
`/story-readiness`, and the rollout note keeps the change reversible.

- **Full mode**: N/A
- **Lean mode**: N/A
- **Solo mode**: N/A
- **N/A**: the change is small and reversible by construction; anything that needs review is redirected to
  `/write-prd`, whose run carries PD-PRD-ALIGN.

---

## Test Cases

### Case 1: Happy Path — Config change with a rollout note

**Fixture** (assumed project state):
- Moa; the config block prints `automation: collaborative (default)`
- `design/prd/payments.md` `## Configuration & Flags` lists `payments.auto-debit-retry-count` (default 2, safe range
  1–5, owner payments)
- `design/product/feature-map.md` has the `payments` row; `design/quick-specs/` holds no spec touching payments
- The user converses in Korean

**Input:** `/quick-spec raise the auto-debit retry count from 2 to 3`

**Expected behavior:**
1. Step 1 infers **Config** and confirms it with `AskUserQuestion` (`[A] Yes — Config is correct` … `[F] This is too large — redirect me to /write-prd`)
2. Step 2 reports what it found — the PRD row, the feature-map row, no conflicting quick specs
3. Step 3 drafts the Config format: `## Change` table (key, where it lives, old 2, new 3, rationale), `## Range Check`
   (within 1–5), `## Rollout` (no flag — a config value applied by remote config; staged exposure; guardrail: payment
   failure rate; rollback: revert the value), `## Acceptance Criteria`, `## Story Embed` (`> **Type**: Config`),
   `## PRD Update Required?`
4. Step 4 shows the full draft, then `[A] Approve — write it as shown` / `[B] Revise` / `[C] This grew too large —
   redirect to /write-prd instead`
5. On approval: "May I write this to `design/quick-specs/auto-debit-retry-count-2026-10-12.md`?"
6. Step 5 prints the hand-off block and `Verdict: **COMPLETE**`, then closes with `AskUserQuestion`

**Assertions:**
- [ ] The headings and bold field labels of the written spec are exactly those of the Config format, in English; the
      content is in Korean
- [ ] The file name is kebab-case with today's date
- [ ] The rollout note is present — a spec without a switch and a rollback is not ready to embed
- [ ] The Story Embed adds no new story field
- [ ] The closing widget offers only applicable options (e.g. `/create-stories <epic-slug>`, `/consistency-check` when
      the value is a registered constant) and always `Stop here`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: NOT ASSESSED — the change cannot be specified (missing input)

**Fixture:**
- No argument; asked to describe the change, the user says "make reminders better" and cannot name the behaviour,
  the value or the feature it belongs to
- No PRD and no config row can be found for "reminders"

**Input:** `/quick-spec`

**Expected behavior:**
1. With no argument, the skill asks the user to describe the change (plain text prompt), then tries to classify it
2. The description does not identify a category, a feature or a value to change; the context scan finds nothing
3. After the Step 2 report the skill stops with `Verdict: **NOT ASSESSED**` and says what was missing (the
   behaviour to change, and the feature or value it applies to)

**Assertions:**
- [ ] No file is written
- [ ] The verdict is `NOT ASSESSED` with the missing input named — never `COMPLETE`, and not `REDIRECTED` (nothing
      showed the change is too large)
- [ ] The skill does not invent a value, a flag key or a feature
- [ ] Variant: a user who answers no to "May I write this to `design/quick-specs/<kebab-title>-YYYY-MM-DD.md`?" ends
      the run with `Verdict: **NOT ASSESSED** — the quick spec was not written`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Redirect — a price change belongs in a PRD

**Fixture:**
- The request changes what a customer pays; `design/prd/subscription.md` defines the Plus plan

**Input:** `/quick-spec raise the Plus plan from KRW 4,900 to KRW 5,900 per month`

**Expected behavior:**
1. Step 1 matches a redirect condition — it changes what a customer pays (prices belong in the PRD and in
   `design/product/pricing-model.md`, with the monetization strategist)
2. The skill stops: `Verdict: **REDIRECTED**` — run `/write-prd subscription`, naming the condition that applied

**Assertions:**
- [ ] No quick spec is written and no PRD is edited
- [ ] The redirect names the condition (pricing) and the exact next command
- [ ] The same redirect applies to a new kind of personal data, a change to who may access data, a breaking API
      change, and a migration that renames, retypes or deletes data; additive operations and additive migrations stay
      in quick-spec scope and are listed under `## API & Data Impact`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Mode Variant — an experiment variant handed off by `/team-growth`

**Fixture:**
- `production/growth/goal-reminder-timing/brief.md` exists with `## Variants`, `## Flag & Rollout`,
  `## Primary Metric & Guardrails` and `## Instrumentation`; variant B sends the deposit reminder at 20:00 KST

**Input:** `/quick-spec experiment goal-reminder-timing variant B — reminder at 20:00 KST`

**Expected behavior:**
1. The brief's four sections are read; the change is a **Tweak** of `notifications`
2. The Tweak format's header carries `**Experiment**: production/growth/goal-reminder-timing/brief.md — variant B`
3. `## Rollout` takes the flag key, the allocation and the guardrails from the brief instead of inventing a rollout,
   and its `**Experiment**:` line names the variant and allocation
4. `## Current Behaviour` quotes the rule it replaces from `design/prd/notifications.md`
5. The closing widget offers `Return to /team-growth — the next variant`

**Assertions:**
- [ ] The flag key, allocation and guardrails match the growth brief exactly
- [ ] Every Tweak quotes the current rule before replacing it
- [ ] One quick spec per variant; a release bundling several changes is pointed to `/rollout-plan`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Edge Case — hardcoded value found, PRD update needed

**Fixture:**
- The deposit-reminder hour is hardcoded in `apps/api/src/modules/notifications/reminder.scheduler.ts`; the PRD's
  `## Configuration & Flags` has no row for it
- The user approves the quick spec, then is asked about the PRD update

**Input:** `/quick-spec send the deposit reminder at 20:00 KST instead of 21:00`

**Expected behavior:**
1. The context scan reports the hardcoded value as a finding: the spec first moves the value into configuration
2. `## PRD Update Required?` says yes — `## Configuration & Flags` needs the new key
3. After the quick spec is written, the skill asks separately: "This spec changes rules in notifications. May I write
   this to `design/prd/notifications.md` — specifically the Configuration & Flags section?", showing the old and new
   text first

**Assertions:**
- [ ] The PRD is not edited without that explicit approval
- [ ] The PRD edit keeps every heading and bold field label and does not change the PRD's `> **Status**:` line
- [ ] When the PRD update is applied and an ADR's `## PRD Requirements Addressed` cites the PRD, the closing widget
      offers `/propagate-prd-change design/prd/notifications.md`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Director Gate Check — none spawned

**Fixture:**
- Any quick spec run (Case 1 state)

**Input:** `/quick-spec raise the auto-debit retry count from 2 to 3`

**Expected behavior:**
1. The skill classifies, drafts and writes without spawning any agent
2. No gate ID and no skip note appear in the output

**Assertions:**
- [ ] No `Agent` call is made — the tool is not in `allowed-tools`
- [ ] No director gate is spawned or noted
- [ ] The verdict is `COMPLETE`, `REDIRECTED` or `NOT ASSESSED` — no gate verdict

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses "May I write this to `<path>`?" before the quick spec and before any PRD edit
- [ ] Classifies before drafting and presents the full draft before asking for approval
- [ ] Ends with the hand-off block and a closing `AskUserQuestion` in `collaborative` and `guided`; in `autonomous`
      prints the next step and records it via `log_decision`
- [ ] Redirects honestly when the change outgrows this path — never squeezes a PRD into a quick spec
- [ ] Never commits

**Authoring rubric** (`CCSS Skill Testing Framework/quality-rubric.md` § `authoring`):

- [ ] A1 — Single-draft pattern appropriate to a lightweight skill: the complete spec is drafted, shown and approved
      (`[B] Revise` loops back to the widget)
- [ ] A2 — "May I write" once for the complete spec, and separately for the PRD edit
- [ ] A3 — Exempt: the skill always creates a new dated file; earlier quick specs for the feature are read to avoid
      contradicting them
- [ ] A4 — N/A: no director gate is defined for this skill
- [ ] A5 — Skeleton headings byte-identical to the format: the skill has no template file under
      `.claude/docs/templates/`; the headings of the written spec are exactly those of the category's format in
      `## 3. Draft the Quick Spec`, including `## Rollout`, `## Acceptance Criteria` and `## Story Embed`

---

## Coverage Notes

- The Small Feature format (trimmed PRD shape with `## Feature Map` note) is covered structurally, not fixture-tested.
- `guided` and `autonomous` behaviour follows `.claude/docs/automation-modes.md` and is covered only by the protocol
  assertion.
- Mobile binary changes (App Store phased release / Google Play staged rollout plus a server-side switch) are part of
  the rollout note text and are not given their own case.
