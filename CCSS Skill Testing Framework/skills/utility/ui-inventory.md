# Skill Spec: /ui-inventory

> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-09-28

## Skill Summary

`/ui-inventory` keeps the two lists UI work is planned against. The **screen
inventory** (`design/inventory/screen-inventory.md`) lists every route and screen per
UI surface — web, iOS, Android (`api` is not a UI surface) — with route or navigation
placement, deep link, auth state, owning feature and tier, UX spec and status
(`Needed` · `Specced` · `Reviewed` · `Implemented`), plus the shared components and the
coverage gaps; it is the coverage source for `/ux-design`. The **media manifest**
(`design/inventory/media-manifest.md`) lists every icon, illustration, app icon, store
screenshot, OG image and notification asset with a sequential project-wide `ASSET-NNN`
ID, a spec and a production brief.

Both are derived from the design documents — feature map, PRD UI sections (by section
grep), one-pager, user journey, app shell, design language and the retained design
handoff records (`design/handoff/*/HANDOFF.md`, their `## Screens & States`) — and
confirmed with the user before anything is written. Arguments: `[surface:<web|ios|android> | feature:<name> | media] [--review full|lean|solo]`.
`review_mode` scales the **specialists** it consults (`product-designer`,
`design-engineer`); it spawns no director gate. Every platform- or store-mandated value
carries `Source: <url>, retrieved YYYY-MM-DD` or `NOT SOURCEABLE — <reason>`. Neither
file carries a verdict — they are lists, not judgements; missing inputs are named in a
`> **Sources**:` line and skipped specialists in a `> **Specialists**:` line.

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`); `name: ui-inventory` equals the skill directory and the catalog `name`
- [ ] Bootstrap: the first body line is exactly `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,surfaces` `` and `allowed-tools` grants `Bash(bash "*/.claude/skills/ui-inventory/../../hooks/yaml-helper.sh" resolve_config *)`
- [ ] `--keys` is exactly `review_mode,automation,surfaces`
- [ ] The line after the bootstrap block is exactly the `--review` variant: ``Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] Automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") present verbatim right after that line
- [ ] `allowed-tools` is exactly: `Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion` plus the bootstrap grant — no plain `Bash`
- [ ] `argument-hint` is `"[surface:<web|ios|android> | feature:<name> | media] [--review full|lean|solo]"`
- [ ] 2+ phase headings found (`## Phase 0: Parse Arguments and Surfaces` … `## Phase 5: Close`)
- [ ] States the single default sentence verbatim: "Unset on an unconfigured project: `modes.rigor` defaults to `minimal`, which resolves `review_mode` to `solo`."
- [ ] Unassessable values use the defined lines `NOT SOURCEABLE — <reason>` and `NOT DETERMINED — design language section 6 not written`; no verdict token is claimed for the lists
- [ ] "May I write this to `design/inventory/screen-inventory.md`?" and "May I write this to `design/inventory/media-manifest.md`?" before each write
- [ ] Outputs at the exact paths `design/inventory/screen-inventory.md` and `design/inventory/media-manifest.md`; no UX spec is written
- [ ] No `!` injection other than the bootstrap line; no `file:line` citations of other files
- [ ] Next-step handoff present at end (closing `AskUserQuestion`), naming current skills: `/ux-design`, `/ux-design shell`, `/design-language`, `/ui-inventory media`, `/ux-review`, `/team-content`

---

## Director Gate Checks

- **N/A**: `/ui-inventory` spawns no director gate at any review mode — `review_mode`
  only decides which specialists run:
  - `full` — `product-designer` and `design-engineer` in parallel
  - `lean` — `product-designer` only; shared components and formats derived by the skill and marked "design-engineer not consulted — lean mode"
  - `solo` — no specialists; every platform- or store-mandated media value is `NOT SOURCEABLE — not looked up (solo mode; rerun with --review lean or full)`
  Specialists are not gates, so no `[GATE-ID] skipped` note is ever written; Case 4
  asserts the per-mode specialist behaviour instead.

---

## Test Cases

Fixtures use the canonical product Moa (web + iOS + Android + API) with the features
`auth`, `onboarding`, `goals`, `payments`, `notifications`, `subscription`, `admin-console`.

### Case 1: Happy Path — Full screen inventory at `review_mode: full`

**Fixture** (assumed project state):
- `platform.surfaces: [web, ios, android, api]`; `review_mode` resolves to `full`
- `design/product/feature-map.md` (table `| Feature | Category | Layer | Tier | Status | PRD | Depends On |`), PRDs with `## UI Requirements` or `### User Flows & States`, `design/product/user-journey.md`, `design/ux/app-shell.md`, `design/brand/design-language.md`; `design/ux/goal-detail.md` exists
- `design/inventory/screen-inventory.md` does not exist

**Input**: `/ui-inventory`

**Expected behavior**:
1. Phase 1 reads the sources before asking anything — PRD UI content by section grep, the design language by its sections 5, 6 and 8 — and presents the context summary
2. Phase 2 derives screens per surface (features by tier, shell destinations and global states, journey stages), and asks about commonly forgotten screens (password reset, consents with marketing consent separate, 본인인증 before a first auto-debit, notification preferences, subscription cancellation, account deletion, receipts, error pages, maintenance and force-update, admin operator screens) instead of adding them
3. `product-designer` and `design-engineer` are spawned in parallel; their drafts come back inline
4. The user confirms the list; Phase 3 asks "May I write this to `design/inventory/screen-inventory.md`?"

**Assertions**:
- [ ] One section per configured UI surface in the order Web, iOS, Android; no `api` section
- [ ] Rows carry slug, route or navigation, auth, feature with PRD path, tier, deep link (or `—` with the reason), UX spec and status; `goal-detail` is `Specced`
- [ ] `> **Sources**:` and `> **Specialists**:` lines are present
- [ ] No screen the documents do not imply is added without the user's confirmation
- [ ] Specialists never write under `design/`; the skill writes after approval

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — API-only product and a feature without a PRD

**Fixture**:
- A second product whose `platform.surfaces` is `[api]`
- Separately, Moa with no `design/prd/referrals.md`

**Input**: `/ui-inventory surface:api`, then `/ui-inventory feature:referrals`

**Expected behavior**:
1. `surface:api` explains that `api` has no screens and stops; with no argument on the API-only product, `media` (developer portal social previews) or `Stop here` is offered
2. `feature:referrals` asks: `Describe the feature's screens now` / `Stop — write the PRD first with /write-prd referrals` / `Stop here`

**Assertions**:
- [ ] No screen inventory is written for a product without UI surfaces
- [ ] A missing PRD is never guessed around silently
- [ ] No write tool is called before a confirmed list

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: NOT ASSESSED — Nothing to inventory yet

**Fixture**:
- No `design/product/feature-map.md`, no PRD, no `design/product/one-pager.md`, no `design/product/user-journey.md`

**Input**: `/ui-inventory`

**Expected behavior**:
1. Phase 1 names every missing source
2. The skill stops: "There is nothing to inventory yet. Run `/map-features` and `/write-prd` (or `/brainstorm` for a one-pager at the `minimal` tier) first."
3. No file is written

**Assertions**:
- [ ] No inventory is compiled from nothing — the skill stops instead of writing an empty list that reads like full coverage
- [ ] The missing inputs and the skills that produce them are named
- [ ] No write tool is called

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Mode Variant — `lean` and `solo` specialist behaviour

**Fixture**:
- Same sources as Case 1; `design/brand/design-language.md` has section 6

**Input**: `/ui-inventory media --review lean`, then `/ui-inventory media --review solo`

**Expected behavior**:
1. `lean`: only `product-designer` runs; formats and variants are derived from sections 6 and 8 of the design language and marked "design-engineer not consulted — lean mode"
2. `solo`: no specialist runs; every platform- or store-mandated value (icon sizes, screenshot dimensions, file limits) is `NOT SOURCEABLE — not looked up (solo mode; rerun with --review lean or full)` and briefs come from section 6 alone
3. The `--review` argument overrides the resolved mode for the run

**Assertions**:
- [ ] The manifest's `> **Specialists**:` line names who ran and who was skipped, with the mode
- [ ] No store-mandated value is stated from memory in `solo`
- [ ] No director gate is spawned and no gate skip note appears in any mode

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Edge Case — Media IDs, shared assets and a missing design-language section

**Fixture**:
- `design/inventory/media-manifest.md` exists with `ASSET-001` … `ASSET-014`; `ASSET-012` is the goals empty-state illustration
- The notifications inbox needs an empty-state illustration
- In a second project, the design language has no section 6

**Input**: `/ui-inventory media`

**Expected behavior**:
1. The skill greps `ASSET-[0-9]+` and starts new assets at `ASSET-015`
2. The inbox reuses `ASSET-012` — `notifications-inbox` is added to its `Used By` instead of a duplicate
3. In the second project, every asset's style is `NOT DETERMINED — design language section 6 not written` and `/design-language` is offered at the close; the skill does not fail
4. The new rows and blocks are appended with Edit and the Progress Summary recounted, after "May I write this to `design/inventory/media-manifest.md`?"

**Assertions**:
- [ ] IDs are sequential across the project, never per category, never reused or renumbered
- [ ] Shared assets are referenced, not duplicated
- [ ] Platform- and store-mandated values carry a URL and retrieval date, or `NOT SOURCEABLE`
- [ ] Store text is not treated as media — it is routed to `/team-content`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Edge Case — Unset surfaces and a scoped refresh

**Fixture**:
- `platform.surfaces` is unset (resolved line `platform.surfaces: (unset -- ask which surfaces ship)`)
- In a second run, `design/inventory/screen-inventory.md` exists and a new `design/ux/goal-create.md` spec has a review record

**Input**: `/ui-inventory`, then `/ui-inventory surface:ios`

**Expected behavior**:
1. Unset surfaces are asked about — not read as "web only" — and `/setup-stack` is named as the place that records them
2. The scoped run edits only the iOS section (and the shared components it touches) with Edit; `goal-create` moves to `Reviewed`; no row is deleted without the user's agreement

**Assertions**:
- [ ] Unset surfaces are a question
- [ ] Scoped runs never rewrite other surfaces' sections
- [ ] `Implemented` is set only when the user confirms it — the skill does not read code

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: Edge Case — Screens from design handoff records

**Fixture**:
- Case 1 state, plus `design/handoff/goal-detail/HANDOFF.md` (`> **Verdict**: RETAINED`, `> **Tool**: figma`,
  `> **Backs**: design/ux/goal-detail.md`) whose `## Screens & States` lists `goal-detail` (default, empty, error) and
  a `goal-share-card` frame that no PRD, shell destination or journey stage names
- `design/handoff/design-system/HANDOFF.md` exists (tokens and components only)
- `design/handoff/goal-create-flow/HANDOFF.md` has `> **Verdict**: NOT ASSESSED`

**Input**: `/ui-inventory`

**Expected behavior**:
1. Phase 1 globs `design/handoff/*/HANDOFF.md`, reads each record's `> **Verdict**:`, `> **Tool**:`, `> **Backs**:`
   lines and `## Screens & States`, skips the `design-system` record, and the context summary counts the records read
2. `goal-detail` is confirmed by the record (record path noted); `goal-share-card` is asked about, never added by default
3. The `goal-create-flow` screens are listed as unverified, never as confirmed
4. The `> **Sources**:` line names the design handoff records read

**Assertions**:
- [ ] No frame the documents do not imply is added without the user's confirmation
- [ ] No Figma MCP tool, Claude Design connector or `Artifact` call is made; `allowed-tools` and `--keys` are unchanged
- [ ] No image generator is called

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses "May I write this to `<path>`?" before every write to the two inventory files
- [ ] Presents the grouped list (and each asset spec) before requesting approval
- [ ] Ends with the closing `AskUserQuestion` offering only the steps that apply
- [ ] Does not auto-create files without user approval; never calls an image generator or other external service — reading the retained `design/handoff/*/HANDOFF.md` records is a local read, and the skill never fetches a Figma or Claude Design link itself
- [ ] Writes no evidence, reports or plans under `production/session-logs/`
- [ ] Never writes `modes.review_mode` or any other knob that `modes.rigor` fronts
- [ ] Surfaces every specialist disagreement instead of picking one silently; a blocked specialist is named and a partial result is kept

---

## Coverage Notes

- Specialist lookups of platform and store requirements (Apple Human Interface
  Guidelines, App Store Connect Help, Android developer documentation, Play Console
  Help, Open Graph) need a live run; this spec checks the sourcing rule, not the values.
- The `feature:<name>` scope with an existing PRD follows Case 1 limited to that
  feature's rows and is not tested separately.
- Error recovery when `product-designer` is blocked (compile from documents; every
  mandated media value `NOT SOURCEABLE — product-designer blocked`) is not
  fixture-tested.
