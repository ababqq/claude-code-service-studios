# Skill Spec: /map-features

> **Category**: pipeline
> **Priority**: high
> **Spec written**: 2026-09-28

## Skill Summary

`/map-features` turns the product brief (`design/product/product-brief.md`; the one-pager
on a voluntary `minimal` run) into the feature map `design/product/feature-map.md`, built
from `.claude/docs/templates/feature-map.md`. It enumerates explicit features and the
implicit ones a service always needs — walked through a service checklist (identity &
auth, onboarding, core domain, notifications, payments & billing, subscriptions and
entitlements, permissions/RBAC & workspaces, search, settings & account incl. data
export and account deletion, admin/back-office, reporting, analytics & instrumentation,
consent & privacy, support/help) — names each with a slug (the future PRD stem, TR-ID
prefix and `feature_overrides` key), maps hard and soft dependencies, assigns layers
(Foundation / Core / Feature / Presentation), resolves cycles, assigns tiers
(MVP / Beta / GA / Later), orders PRD authoring and lists high-risk features. The
`## Features` table header is a fixed contract:
`| Feature | Category | Layer | Tier | Status | PRD | Depends On |`. After the map is
written, three gates review it in parallel — **TD-DOMAIN-BOUNDARY**,
**PD-FEATURE-MAP**, **DM-SCOPE** — subject to the review mode. It then hands off to
`/write-prd` (`next` or `<feature-name>` modes) without duplicating PRD authoring.
Its output is the artifact of catalog step `definition.map-features` (required at
`standard` and `full`).

Verdicts (reported in conversation; precedence BLOCKED > NOT ASSESSED > COMPLETE):
**COMPLETE** / **BLOCKED** / **NOT ASSESSED**. The feature map itself carries no verdict
line — its state is its `> **Status**:` line and the director review lines.

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`); `name: map-features` equals the skill directory, the catalog `name` and this spec's basename
- [ ] `description` is exactly "Decompose the brief into features, dependencies and MVP / Beta / GA / Later tiers; create the feature map."; `argument-hint: "[next | feature-name] [--review full|lean|solo]"`; `model: sonnet`; no `disable-model-invocation`, no `isolation`
- [ ] Bootstrap: the first body line is exactly `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,docs.density,team.size,stack` `` and `allowed-tools` grants `Bash(bash "*/.claude/skills/map-features/../../hooks/yaml-helper.sh" resolve_config *)`
- [ ] The line after the bootstrap block is exactly `` Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`. ``
- [ ] Automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") present verbatim right after that line
- [ ] `allowed-tools` is exactly: `Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskUpdate` plus the grant
- [ ] ≥2 phase headings (`## Phase 1: Parse Arguments and Read the Brief` … `## Phase 9: Next Steps`)
- [ ] Verdict keywords present exactly: `COMPLETE`, `BLOCKED`, `NOT ASSESSED`, with the NOT ASSESSED form `NOT ASSESSED — no product brief to decompose`
- [ ] "May I write this to `design/product/feature-map.md`?" before each write of the map
- [ ] Output at the exact path `design/product/feature-map.md` (glob of catalog step `definition.map-features`); the `## Features` header is exactly `| Feature | Category | Layer | Tier | Status | PRD | Depends On |`, with Layer ∈ `Foundation | Core | Feature | Presentation`, Tier ∈ `MVP | Beta | GA | Later`, Status ∈ `Not Started | Drafting | In Review | Needs Revision | Approved | Implemented`
- [ ] The review-mode check names all three gates and carries the lean suffix sentence; `Pass:` lines are exactly `` feature map path · brief path · `docs/registry/architecture.yaml` path (or "none") · resolved `stack` line `` (TD-DOMAIN-BOUNDARY), `feature map path · product brief path · MVP scope text` (PD-FEATURE-MAP), `` MVP scope text (brief, one-pager or feature map path) · resolved `team.size` · target milestone/date (or "none given") `` (DM-SCOPE); replies are parsed as `[GATE-ID]: TOKEN`
- [ ] No `!` injection other than the bootstrap line; no `file:line` citations (no script line numbers)
- [ ] Next-step handoff names `/write-prd`, `/map-features next`, `/prototype`, `/prd-review`, `/review-all-prds`, `/gate-check architecture`

---

## Director Gate Checks

Three gates review the **written** draft before any PRD is authored, spawned in parallel
(all `Agent` calls issued before any result is awaited); the strictest verdict decides.
Each prompt tells the agent to read its own gate file first.

- **Full mode**: TD-DOMAIN-BOUNDARY (`technical-director`, `APPROVE / CONCERNS / REJECT`),
  PD-FEATURE-MAP (`product-director`, `APPROVE / CONCERNS / REJECT`), DM-SCOPE
  (`delivery-manager`, `REALISTIC / CONCERNS / UNREALISTIC`) all spawn.
- **Lean mode**: skip every gate whose ID does not end in `-PHASE-GATE` — none of the three
  does, so all three are skipped: `[TD-DOMAIN-BOUNDARY] skipped — Lean mode`,
  `[PD-FEATURE-MAP] skipped — Lean mode`, `[DM-SCOPE] skipped — Lean mode`, each written
  into the map header where its review line would go.
- **Solo mode**: all three skipped with `[<GATE-ID>] skipped — Solo mode`.
- The `stack` and `team.size` lines come from the bootstrap block and are passed as printed
  (the unset stack form is exactly `stack: unset — run /setup-stack`).

---

## Test Cases

Fixtures use the Moa example: `design/product/product-brief.md` whose
`## Value Proposition` and `## MVP Scope` name savings goals and Toss Payments
auto-debit, and whose `## Business Model Hypothesis` names a paid Plus plan.

### Case 1: Happy Path — new feature map from a standard-tier brief

**Fixture** (assumed project state):
- `modes.workflow: standard`; review mode `lean` (gate behaviour is Cases 6–8)
- The Moa brief above; no `design/product/feature-map.md`; `design/prd/` empty

**Expected behavior:**
1. Reads the brief; creates one task per phase (TaskCreate)
2. Enumerates explicit features (`goals`, `payments`) and inferred ones from the service checklist (`auth`, `notifications`, `subscription`, `admin-console`, `settings-account`, `onboarding`), explaining each inference with a Moa example; asks "Are features missing from this list?", "Should any be combined or split?", "Are there features listed that this product does NOT need?"
3. Maps dependencies and layers (`auth` Foundation; `payments`, `notifications` Core; `goals`, `subscription` Feature; `onboarding`, `admin-console` Presentation), resolves the goals ↔ payments cycle through a `payment_settled` event, confirms the order
4. Assigns tiers with reasoning, asks for the MVP target milestone, orders PRD authoring (MVP Foundation first), lists high-risk features (payment-provider merchant review, 알림톡 template approval)
5. Presents the summary and asks "May I write this to `design/product/feature-map.md`?"
6. Writes the map; records the three lean skip notes in its header; updates the session checkpoint; prints the summary block ending `Verdict: COMPLETE`

**Assertions:**
- [ ] The `## Features` header is exactly the contract header — no column added (no `Why` or priority column)
- [ ] Every new row has `Status` `Not Started` and `PRD` `—`; `Depends On` holds slugs or `—`
- [ ] No MVP feature depends on a Beta, GA or Later feature
- [ ] Slug choice is presented as a major decision before the write
- [ ] The map is not written before the "May I write" answer
- [ ] The summary's `Next PRD:` names `/write-prd auth` (first MVP Foundation row)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — the user declines the write

**Fixture:**
- Case 1 fixture; the user answers "no" to "May I write this to `design/product/feature-map.md`?"

**Expected behavior:**
1. The feature map is not written; Phase 6 is skipped (the gates review a written map)
2. Verdict **BLOCKED** — the feature map was not written; the skill reports in Phase 7 (session checkpoint `Task: Feature map — not written`) and stops

**Assertions:**
- [ ] No feature map file exists after the run
- [ ] No director gate is spawned (gates review the written draft)
- [ ] The summary names the reason for BLOCKED

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: NOT ASSESSED — no brief to decompose

**Fixture:**
- Neither `design/product/product-brief.md` nor `design/product/one-pager.md` exists

**Expected behavior:**
1. Reports "No product brief found. Run `/brainstorm` first, then come back to decompose it into features."
2. Verdict `NOT ASSESSED — no product brief to decompose`

**Assertions:**
- [ ] Verdict is NOT ASSESSED with the missing input named — never COMPLETE, never an empty map
- [ ] Nothing is written and no gate is spawned
- [ ] The next step named is `/brainstorm`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Mode Variant — resume an existing map with `next`

**Fixture:**
- `design/product/feature-map.md` exists: `auth` Approved (`design/prd/auth.md`), `subscription` Drafting (`design/prd/subscription.md`, `> **Feature Map Tier**: Beta`), the rest Not Started
- The brief was revised; the user moves `subscription` from Beta to MVP

**Input:** `/map-features`, then `/map-features next`

**Expected behavior:**
1. Reads the map and asks "The feature map lists <N> features (<M> with an Approved PRD, <K> Not Started). What would you like to do?" with `Add or update features` / `Write the next PRD` / `Review and revise tiers`
2. On update, carries every row's `Status` and `PRD` over exactly and asks before rewriting
3. `next` picks the first `## PRD Authoring Order` row whose feature is `Not Started` and hands it to `/write-prd <slug>`

**Assertions:**
- [ ] Existing `Status` / `PRD` values are never overwritten; no row with an existing PRD is deleted
- [ ] `design/prd/subscription.md` is listed under `Stale PRD tiers:` for the user to fix — the PRD is not edited here
- [ ] The hand-off does not duplicate the `/write-prd` workflow

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Edge Case — voluntary run at `minimal` with `docs.density: thorough`

**Fixture:**
- `modes.rigor` unset (`minimal`), `docs.density: thorough` set explicitly
- Only `design/product/one-pager.md` exists

**Expected behavior:**
1. Reads the one-pager (`## Core User Journey`, `## Scope & Non-Goals`, `## Build Order`) as the source and says so
2. Writes per-feature rationale and relationship analysis into `## Overview` and the layer notes
3. `> **Source Brief**:` names `design/product/one-pager.md`

**Assertions:**
- [ ] The table header is unchanged — density never adds a column
- [ ] The skill states the map is not required at `minimal` (the one-pager's `## Build Order` replaces it) but completes the voluntary run
- [ ] In `full` review mode PD-FEATURE-MAP would receive the one-pager path and its `## Scope & Non-Goals` text, and say so

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Director Gate — full mode

**Fixture:**
- Case 1 fixture; review mode `full` (or `--review full`); `stack.*` unset; no `docs/registry/architecture.yaml`
- PD-FEATURE-MAP returns CONCERNS (MVP misses data export), TD-DOMAIN-BOUNDARY returns APPROVE, DM-SCOPE returns UNREALISTIC for the stated date

**Expected behavior:**
1. After the write, spawns the three gates in parallel with their `Pass:` lines; TD-DOMAIN-BOUNDARY receives `none` for the registry and `stack: unset — run /setup-stack`; DM-SCOPE receives `team.size` with its source and the target date (or `none given`)
2. Parses each `[GATE-ID]: TOKEN`; the strictest (UNREALISTIC) decides

**Assertions:**
- [ ] REJECT-class → the blockers are presented, the map is revised (asking again before rewriting) and **only** the rejecting gate is re-spawned; DM-SCOPE offers the cut list or a date that fits
- [ ] CONCERNS-class → `AskUserQuestion` `Revise the map` / `Accept and record the concerns` / `Discuss further`; accepted concerns become `> **Product Director Note** (<tier>): …` beneath the `## Tiers` table
- [ ] Outcome lines sit directly under `> **Source Brief**:` — `> **Technical Director Review (TD-DOMAIN-BOUNDARY)**: APPROVED <date>`, `> **Product Director Review (PD-FEATURE-MAP)**: …`, `> **Delivery Manager Review (DM-SCOPE)**: …`
- [ ] Stopping with UNREALISTIC unresolved gives Verdict **BLOCKED**
- [ ] A first line that does not parse is treated as CONCERNS-class; the parent never reads a gate file

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: Director Gate — lean mode

**Fixture:**
- Case 1 fixture; review mode `lean`

**Expected behavior:**
1. All three gates are skipped

**Assertions:**
- [ ] Output and map header contain `[TD-DOMAIN-BOUNDARY] skipped — Lean mode`, `[PD-FEATURE-MAP] skipped — Lean mode` and `[DM-SCOPE] skipped — Lean mode`
- [ ] The summary names each omission: "<GATE-ID> not consulted — Lean mode; `--review full` runs it."
- [ ] Verdict can be **COMPLETE** (skip-noted gates count as resolved)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 8: Director Gate — solo mode

**Fixture:**
- Case 1 fixture; review mode `solo`

**Expected behavior:**
1. No director gates spawn

**Assertions:**
- [ ] In solo mode: no director gates spawn
- [ ] Output and map header contain `[TD-DOMAIN-BOUNDARY] skipped — Solo mode`, `[PD-FEATURE-MAP] skipped — Solo mode` and `[DM-SCOPE] skipped — Solo mode`

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses "May I write this to `design/product/feature-map.md`?" before every write of the map (guided mode may update an existing map after presenting the summary; autonomous writes and logs via `log_decision`)
- [ ] Presents the enumeration, the dependencies and the tiers for validation before writing
- [ ] Ends with a recommended next step (`/write-prd <first feature in authoring order>`)
- [ ] Never writes a PRD and never starts one without the user's confirmation
- [ ] Writes nothing under `production/session-logs/`; never writes `modes.review_mode` or any knob `modes.rigor` fronts
- [ ] Every skipped gate is written into the map and named in the summary

---

## Coverage Notes

- Pipeline rubric mapping: P1 (template sections and the column contract — Case 1), P2
  (layers and MVP-first authoring order — Case 1), P3 (May-I-write before each map write
  — Cases 1, 4), P4 (three gates per review mode — Cases 6–8), P5 (brief and existing map
  read before writing — Cases 1, 4).
- The `<feature-name>` single-feature path (one row added to an existing map, then a
  hand-off) follows the Case 4 pattern and is not fixture-tested separately.
- `guided` and `autonomous` enumeration loops (ask once / `log_decision`) are stated in
  the skill but not fixture-tested.
