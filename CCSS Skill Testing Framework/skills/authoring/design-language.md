# Skill Spec: /design-language

> **Category**: authoring
> **Priority**: low
> **Spec written**: 2026-09-28

## Skill Summary

`/design-language` authors `design/brand/design-language.md` — the visual and interaction source of truth for every
UI surface — from `.claude/docs/templates/design-language.md`, whose nine numbered `##` headings are a contract:
`## 1. Brand Principles`, `## 2. Color System`, `## 3. Typography`, `## 4. Layout, Spacing & Grid`,
`## 5. Components & States`, `## 6. Iconography & Illustration`, `## 7. Motion & Feedback`,
`## 8. Platform Adaptation`, `## 9. Content & Voice`. It starts from the brief's optional `## Brand Direction Anchor`;
without one it runs the DD-BRAND-DIRECTION gate (`design-director`, verdict `OPTIONS` ⇒ the user selects a
direction). Section 1 is drafted alone by `product-designer`; sections 2–5 and 6–9 are each drafted in one
`product-designer` call and checked in parallel by `design-engineer` and `accessibility-specialist`, then presented,
approved and written one section at a time. It optionally writes `design/brand/tokens.json` (W3C Design Tokens format)
and closes with the DD-DESIGN-LANGUAGE sign-off, spawned as `design-director`. Tier: `full` = all nine sections;
`standard` = sections 1–5 when a UI surface exists; `workflow_overrides.design_language_strict: true` forces all
nine. Verdict tokens: `COMPLETE` / `PARTIAL — SECTIONS <n>-<m>` / `NOT ASSESSED`, precedence
PARTIAL > NOT ASSESSED > COMPLETE, carried on the document's verdict line. The resolved `design` line names the design
source (`claude-design` / `figma` / `none`; unset ⇒ asked in Phase 2, never read as `none`), recorded in the header's
`> **Design Source**:` line; for `claude-design` or `figma` the tokens and components in
`design/handoff/design-system/HANDOFF.md` are passed to the specialists as existing values to adopt or reconcile, and
the document stays the source of intent.

Assertions quote the canonical English text of `.claude/skills/design-language/SKILL.md`; prompts are rendered in the
user's conversation language at run time (`.claude/docs/coding-standards.md` § Language Policy) and this spec never
asserts the runtime wording.

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] `name: design-language` equals the directory name (`.claude/skills/design-language/`) and this spec's basename
- [ ] `argument-hint` is `"[--review full|lean|solo]"`
- [ ] The first body line is exactly
      `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,docs.density,surfaces,accessibility,design` ``
      — the `--keys` value is exactly `review_mode,automation,workflow,docs.density,surfaces,accessibility,design`
- [ ] `allowed-tools` contains the grant naming this skill's own directory:
      `Bash(bash "*/.claude/skills/design-language/../../hooks/yaml-helper.sh" resolve_config *)`
- [ ] `allowed-tools` is exactly the set Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion plus that grant — no
      plain `Bash`, no MCP tool names
- [ ] The line after the bootstrap block is exactly: ``Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] The automation prelude block — from `**Automation mode**: Resolve` to `categories always prompt).` — follows
      that line verbatim
- [ ] The bootstrap line is the only `!` injection in the file; no `file:line` citation of another file
- [ ] `model: sonnet`; no `disable-model-invocation` and no `isolation` key
- [ ] ≥2 phase headings (Phase 0 through Phase 7)
- [ ] The verdict tokens are spelled exactly: `COMPLETE`, `PARTIAL — SECTIONS <n>-<m>`, `NOT ASSESSED`
- [ ] The nine section headings are listed exactly as the template spells them
- [ ] Both outputs are named: `design/brand/design-language.md` and `design/brand/tokens.json`
- [ ] Phase 5 offers exactly `Generate design/brand/tokens.json from sections 2–4`, `Reconcile with Figma variables`
      (only for a `figma` source whose design-system record lists variables) and
      `Skip — tokens live in Figma variables or code`
- [ ] "What this skill never does" lists writing `design.*` or anything under `design/handoff/` (`/design-handoff`,
      `/setup-stack` and `/settings` write it) and writing to Figma or Claude Design
- [ ] The bundled `/design`, `/design-sync`, `/design-login` and Figma's plugin skills are named only conditionally
      ("if … present in the session") and never appear in the Phase 7 next-step list; no Figma MCP tool, `Artifact`
      or `Skill` in `allowed-tools`
- [ ] "May I write this to `<path>`?" appears before every write to `design/brand/design-language.md` and
      `design/brand/tokens.json`
- [ ] The DD-BRAND-DIRECTION spawn carries this `Pass:` line verbatim:
      `` Pass: brief path · product principles text · target users · resolved `surfaces` line ``
- [ ] The DD-DESIGN-LANGUAGE spawn carries this `Pass:` line verbatim:
      `` Pass: `design/brand/design-language.md` path · resolved `accessibility` line · resolved `surfaces` line · brief path ``
- [ ] Each spawn prompt tells `design-director` to read its own gate file
      (`.claude/docs/director-gates/dd-brand-direction.md`, `.claude/docs/director-gates/dd-design-language.md`), and
      the parent parses the first reply line as `[GATE-ID]: TOKEN`
- [ ] Next-step handoff at the end (Phase 7 closing `AskUserQuestion` and the Recommended Next Steps section)

---

## Director Gate Checks

Two design-director gates, both owned by `design-director`:

- **DD-BRAND-DIRECTION** — Phase 1b, only when the brief has no `## Brand Direction Anchor` (or the user chooses
  `Start fresh`). Tokens: `OPTIONS` (selection — the user picks; then APPROVE-class), `STRONG` (APPROVE-class; the
  user still confirms), `CONCERNS` (CONCERNS-class).
- **DD-DESIGN-LANGUAGE** — Phase 6, after the scoped sections are written; never for the `Tokens only` scope.
  Tokens: `APPROVE` / `CONCERNS` / `REJECT`.

- **Full mode**: both gates spawn when their conditions hold.
- **Lean mode**: the lean suffix rule skips both (neither ends in `-PHASE-GATE`): `[DD-BRAND-DIRECTION] skipped — Lean mode`,
  `[DD-DESIGN-LANGUAGE] skipped — Lean mode`, each written into its header line.
- **Solo mode**: both skipped: `[DD-BRAND-DIRECTION] skipped — Solo mode`, `[DD-DESIGN-LANGUAGE] skipped — Solo mode`.
- **N/A**: DD-BRAND-DIRECTION when the brief's anchor is used — the header records
  `not run — direction taken from the brief's anchor`.

The director's sign-off is recorded separately and never changes the completeness verdict token.

---

## Test Cases

### Case 1: Happy Path — all nine sections at `full`, built on the brief's anchor

**Fixture** (assumed project state):
- Moa; the config block prints `review_mode: full (project.yaml)`, `workflow: full (rigor:full)`,
  `docs.density: thorough (rigor:full)`, `platform.surfaces: web, ios, android, api (project.yaml)`,
  `accessibility.target: wcag-aa (project.yaml)`, `design.tool: none (project.yaml)`
- `design/product/product-brief.md` has `## Brand Direction Anchor` ("Calm confidence — money feels in control");
  `design/accessibility-requirements.md` has `> **Target**: wcag-aa` and lists KWCAG 2.2 for `kr`
- `project.yaml` sets `localization.locales: [ko-KR, en-US]` and `performance.bundle_kb: 170`
- No `design/brand/design-language.md`; the user converses in Korean

**Input:** `/design-language`

**Expected behavior:**
1. Phase 0 reads the brief by heading (not a full read), the accessibility target and the locales; this is a fresh
   authoring session
2. Phase 1a presents the anchor; `Build directly on this anchor`; the header records DD-BRAND-DIRECTION as
   `not run — direction taken from the brief's anchor`
3. Phase 2 asks Scope (`All nine sections` marked Recommended because the tier is `full`) and References (free text)
4. Section 1 is drafted by `product-designer`, locked, and "May I write this to `design/brand/design-language.md`?"
   creates the file: H1, `> **Verdict**: PARTIAL — SECTIONS 1-1`, the header block, section 1, and the other eight
   headings exactly as the template spells them, each with only `[To be designed]`
5. Sections 2–5: one `product-designer` draft (Hangul-first font stack such as Pretendard with system fallbacks,
   `word-break: keep-all`, tabular numerals for amounts, red signalling a rise in Korean finance UIs, never color
   alone); `design-engineer` and `accessibility-specialist` check it in parallel; each section is presented, approved
   and written before the next, and the verdict line advances to `PARTIAL — SECTIONS 1-<n>`
6. Sections 6–9 follow the same pattern; section 9 is a pointer to `design/brand/voice-and-tone.md` plus UI copy rules
7. Phase 5 offers `design/brand/tokens.json`; Phase 6 spawns DD-DESIGN-LANGUAGE (APPROVE) →
   `> **Design Director Review (DD-DESIGN-LANGUAGE)**: APPROVED [date]` and `> **Status**: Approved`
8. Phase 7 sets `> **Verdict**: COMPLETE`, reports, and offers `/ui-inventory`, `/ux-design shell`, `/ux-design patterns`

**Assertions:**
- [ ] The nine `##` headings are byte-identical to the template, numbered and in order, never translated — the body
      is in Korean
- [ ] Unauthored sections hold only `[To be designed]` — no template example tables copied in
- [ ] `design-engineer` and `accessibility-specialist` are spawned in parallel (both calls before either result)
- [ ] The skill never drafts a section itself — every section comes from a specialist
- [ ] Section 9 defines no voice attributes or tone; any such content is moved out and the user is pointed to
      `/team-content`
- [ ] The verdict line sits directly under the H1 and one blank line

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: NOT ASSESSED — accessibility target unset (missing input)

**Fixture:**
- Case 1 state, except the config block prints `accessibility.target: (unset -- ask; unset is not none)` and
  `design/accessibility-requirements.md` does not exist
- The user chooses `Continue — check against wcag-aa as a working bar, recorded as not checked against a committed target`
- Variant: no product brief and no one-pager exist

**Input:** `/design-language`

**Expected behavior:**
1. Phase 0 does not assume a level; it offers `Stop and decide the target with /ux-design accessibility first (Recommended)`
   or the working-bar option
2. On continue, every contrast row carries `NOT CHECKED — accessibility.target unset` and the `> **Not Checked**:`
   header line says so
3. With all nine sections written, the verdict is `NOT ASSESSED` — never `COMPLETE`
4. Variant: the skill stops with "No product brief found. Run `/brainstorm` first …", writes nothing and reports
   `Verdict: NOT ASSESSED — <the reason>` in the conversation

**Assertions:**
- [ ] Unset is never read as `none`; the target is never written by this skill (`/ux-design accessibility` owns it)
- [ ] As the document's verdict, `NOT ASSESSED` is used only when all nine sections are written; a missing section
      makes the verdict `PARTIAL` (PARTIAL outranks NOT ASSESSED)
- [ ] A Phase 0 stop (no brief or one-pager, `Stop here` for API-only surfaces, `Stop and decide the target …`) creates
      no document and reports `Verdict: NOT ASSESSED — <the reason>` in the conversation only
- [ ] The Not Checked reasons appear in the document header and in the Phase 7 report

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Mode Variant — `standard` tier authors the foundation only

**Fixture:**
- `workflow: standard (rigor:standard)`, `review_mode: full (project.yaml)` (explicit), a UI surface configured;
  `workflow_overrides.design_language_strict` absent from `project.yaml`

**Input:** `/design-language`

**Expected behavior:**
1. Phase 2 marks `Foundation — sections 1–5` as Recommended and says why ("Sections 1–5 are what `standard`
   requires; 6–9 are available if you want them.")
2. Sections 1–5 are authored; DD-DESIGN-LANGUAGE runs after section 5
3. The verdict is `PARTIAL — SECTIONS 1-5`; the report says the tier's requirement is met, so PARTIAL is not read as
   a failure; `> **Sections Deferred**:` names 6–9

**Assertions:**
- [ ] With `workflow_overrides.design_language_strict: true` the recommended scope becomes all nine sections
- [ ] At `minimal` the skill says the document is not required and offers sections 1–5 rather than defaulting to nine
- [ ] `Tokens only` is offered only when sections 2–4 are complete, and it skips the director sign-off

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Edge Case — retrofit an existing document; API-only surfaces

**Fixture:**
- (a) `design/brand/design-language.md` exists: sections 1–4 complete, `## 5. Components & States` holds
  `[To be designed]`, and section 2 is headed `## 2. Colour Palette` (renamed)
- (b) The config block prints `platform.surfaces: api (project.yaml)`

**Input:** `/design-language`

**Expected behavior:**
1. (a) The status table is built from two greps (headings; placeholder and NOT CHECKED markers) without reading the
   whole document; a genuinely ambiguous section is read by its line range only
2. (a) `## 2. Colour Palette` is reported as Missing and its content offered for a move under `## 2. Color System`;
   only Empty, Placeholder and Missing sections are authored; complete sections are not touched
3. (b) The skill says the design language applies to UI surfaces and offers `Stop here (Recommended)` /
   `Continue anyway — for a developer portal or docs site I will add as a web surface`

**Assertions:**
- [ ] Existing complete content is never rewritten
- [ ] A heading that deviates from the template counts as Missing — the gate does not find it otherwise
- [ ] (b) The skill never writes `platform.surfaces`; it names `/setup-stack` as the place to record a web surface

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Director Gate — `full`, no anchor: DD-BRAND-DIRECTION returns OPTIONS

**Fixture:**
- `review_mode: full (project.yaml)`; the brief has no `## Brand Direction Anchor`
- The gate's first reply line is `[DD-BRAND-DIRECTION]: OPTIONS` with three directions

**Input:** `/design-language`

**Expected behavior:**
1. The spawn prompt tells `design-director` to read `.claude/docs/director-gates/dd-brand-direction.md` first
2. Pass items: the brief path; the `## Product Principles & Anti-Goals` text; the
   `## Target Users & Jobs-to-be-Done` text; the resolved `platform.surfaces` line as printed
3. The directions are presented with one option each plus `Combine elements — I'll describe how` and
   `Describe my own direction`; the chosen one is APPROVE-class and the header records `APPROVED [date]`
4. The direction, its source and the alternatives not chosen go into `### Direction Record` of section 1

**Assertions:**
- [ ] `OPTIONS` is treated as a selection, not a verdict; the skill never picks for the user
- [ ] The brief is never edited — the direction is recorded only in the design language
- [ ] A REJECT-class or unknown token, or an unparseable first line, is surfaced as CONCERNS-class with the note that
      the verdict line was missing or invalid

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Director Gate — `full`, DD-DESIGN-LANGUAGE returns REJECT

**Fixture:**
- Case 1 state at Phase 6; the gate's first reply line is `[DD-DESIGN-LANGUAGE]: REJECT` (brand green fails 4.5:1 as
  button text in dark mode)

**Input:** `/design-language`

**Expected behavior:**
1. The spawn goes to `design-director` — the design director, never another director — with the Pass items
   (`design/brand/design-language.md`, the resolved `accessibility` and `surfaces` lines as printed, the brief path)
2. The blockers are surfaced; no review line is recorded and `> **Status**: Draft` stays
3. `AskUserQuestion`: `Revise the blocking sections now` / `Stop here — resume later with the Resume scope`

**Assertions:**
- [ ] A REJECT-class verdict never sets `> **Status**: Approved`
- [ ] CONCERNS offers `Revise flagged items` / `Accept and proceed` / `Discuss further`; accepting records
      `CONCERNS (accepted) [date]`, an APPROVE after revision records `REVISED [date]`
- [ ] The completeness verdict token is not changed by the director's outcome

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: Review Mode — `lean` skips both gates by the suffix rule

**Fixture:**
- The config block prints `review_mode: lean (rigor:standard)`; the brief has no anchor

**Input:** `/design-language`

**Expected behavior:**
1. Phase 1b skips DD-BRAND-DIRECTION (`[DD-BRAND-DIRECTION] skipped — Lean mode` in the header line) and asks where
   the direction comes from: `Describe the direction myself` / `Have product-designer draft 2–3 directions (authoring, not a director review)` /
   `Rerun with --review full to get the director's directions`
2. Phase 6 skips DD-DESIGN-LANGUAGE and writes `[DD-DESIGN-LANGUAGE] skipped — Lean mode` into its header line after
   "May I write this to `design/brand/design-language.md`?"

**Assertions:**
- [ ] The SKILL.md review-mode checks contain the sentence
      `` `lean` → **skip every gate whose ID does not end in `-PHASE-GATE`**. Note: `[GATE-ID] skipped — Lean mode` ``
- [ ] No `design-director` spawn in lean mode; a `product-designer` draft of directions is labelled authoring, not a
      director review
- [ ] The skip notes are in the document, so `/gate-check` reports the item as not checked instead of scoring it

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 8: Review Mode — `solo`

**Fixture:**
- The config block prints `review_mode: solo (rigor:minimal)` and `workflow: minimal (rigor:minimal)`; the one-pager
  exists, no brief

**Input:** `/design-language`

**Expected behavior:**
1. The one-pager is used in place of the brief (no principles section — recorded as such); the skill says the
   document is not required at `minimal`
2. Both gates are skipped: `[DD-BRAND-DIRECTION] skipped — Solo mode`, `[DD-DESIGN-LANGUAGE] skipped — Solo mode`

**Assertions:**
- [ ] No gate agent is spawned; the notes read exactly as above
- [ ] Specialist drafting and checks still run (they are authoring, not gates)
- [ ] The skill never writes `modes.review_mode`, `accessibility.target`, `platform.surfaces`, `design.*` or any
      `modes.*` key

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 9: Design Source — Figma library and Claude Design design system with a retained record

**Fixture:**
- Case 1 state, except the config block prints
  `design.tool: figma file_url=https://www.figma.com/design/AbC123/Moa (project.yaml)`
- `design/handoff/design-system/HANDOFF.md` exists with `> **Verdict**: RETAINED`, `> **Tool**: figma` and a
  `## Tokens & Components` section listing Figma variables (`color/green/500 = #1FA66B`, `space/4 = 16`, light and dark
  modes) and library components (`Button`, `TextField`, `AmountInput`)
- Variant: the config block prints `design.tool: claude-design project_url=https://claude.ai/design/p/moa-ds (project.yaml)`,
  the record has `> **Tool**: claude-design` and its tokens come from retained bundle CSS under
  `design/handoff/design-system/bundle/`; the repo has a React component library in `packages/ui`

**Input:** `/design-language`

**Expected behavior:**
1. Phase 0 reads the resolved `design` line and the record's `> **Verdict**:`, `> **Retrieved**:` and
   `> **Not Checked**:` lines; Phase 2 shows the design source in the session context and does not ask for it
2. Before the sections 2–5 draft, the main session reads the record's `## Tokens & Components` with Read and passes
   the values and the record path to `product-designer` as existing values to adopt or reconcile — no agent is asked
   to call the Figma MCP server, the Claude Design connector or the Artifact tool
3. The `design-engineer` check flags every variable or token that cannot map into the primitive → semantic →
   component tiers and lists each existing value the draft changed; a departure is shown to the user with
   `AskUserQuestion`, never resolved silently
4. The header's `> **Design Source**:` line starts with `figma — ` (variant: `claude-design — `) and names
   `design/handoff/design-system/HANDOFF.md`
5. Phase 5 offers `Reconcile with Figma variables`; `design-engineer` reports drift counts per family (in the
   document only, in Figma only, same name with a different value or mode); the document wins; pushing tokens to Figma
   variables is named as an external write through Figma's own skill, approved by the user, never done by this skill
6. Variant: `Reconcile with Figma variables` is not offered; the skill says the user may run the bundled
   `/design-sync` (with `/design-login`), if present in the session, to push `packages/ui` to Claude Design — as an
   external write the user runs, not a next step

**Assertions:**
- [ ] The document stays the source of intent — no Figma or Claude Design value is adopted without the user seeing it
- [ ] The first token of the `> **Design Source**:` line is exactly `figma` or `claude-design`
- [ ] The skill never writes `design.*`, anything under `design/handoff/`, or to Figma or Claude Design
- [ ] The DD-DESIGN-LANGUAGE `Pass:` line is unchanged — the gate reads the Design Source line from the document

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 10: NOT CHECKED — declared design source with no retained record

**Fixture:**
- Case 9 state (`design.tool: figma …`), except `design/handoff/design-system/HANDOFF.md` does not exist
- The user answers `Continue without it` to the import offer
- Variant A: the config block prints `design.tool: none (project.yaml)`
- Variant B: the config block prints `design.tool: (unset -- ask; unset is not none)`

**Input:** `/design-language`

**Expected behavior:**
1. Before the sections 2–5 draft the skill offers
   `Import the design system first — /design-handoff --for design-system, then rerun /design-language (Recommended)` /
   `Continue without it`
2. On continue, the header's `> **Not Checked**:` line carries
   `NOT CHECKED — external design not retained (https://www.figma.com/design/AbC123/Moa)` and the same line stands on
   its own at the end of section 2
3. With all nine sections written, the verdict is `NOT ASSESSED` — never `COMPLETE`; Phase 7 reports the design source
   as not checked and offers `/design-handoff --for design-system`
4. Variant A: no import offer, no reconcile step and no design-source `NOT CHECKED` line; the header reads
   `> **Design Source**: none — markdown spec only …`; the verdict can be `COMPLETE`
5. Variant B: Phase 2 adds the `Design source` tab (`Claude Design — a design-system project` /
   `Figma — a library file` / `None — this document and tokens.json only`); the answer applies to this run only and
   the skill names `/design-handoff`, `/setup-stack` or `/settings` as the place that records it

**Assertions:**
- [ ] The line is spelled exactly `NOT CHECKED — external design not retained (<url>)`
- [ ] A declared source that could not be read never reads as a match, and caps the verdict below `COMPLETE`
- [ ] `none` writes no design-source `NOT CHECKED` line; unset is asked, never treated as `none`

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses "May I write this to `<path>`?" before every write to `design/brand/design-language.md` and
      `design/brand/tokens.json`; specialists never write under `design/` themselves
- [ ] Presents each specialist draft and every disagreement between `product-designer`, `design-engineer` and
      `accessibility-specialist` to the user; never resolves a conflict silently
- [ ] Ends with a recommended next step (Phase 7) and always includes `Stop here`
- [ ] Announces every skip — a skipped gate, a specialist that did not run (`NOT CHECKED — <agent> did not run: <reason>`)
- [ ] Writes to Figma and uploads to Claude Design are external writes, always proposed and approved by the user,
      never made by this skill
- [ ] Never commits

**Authoring rubric** (`CCSS Skill Testing Framework/quality-rubric.md` § `authoring`):

- [ ] A1 — Section-by-section cycle: batching is in the delegation only; the user sees, approves and commits one
      section at a time
- [ ] A2 — "May I write" per section write
- [ ] A3 — Retrofit: an existing document is detected and only incomplete sections are authored
- [ ] A4 — DD-BRAND-DIRECTION and DD-DESIGN-LANGUAGE run in `full`, are skipped with named notes in `lean` and `solo`
- [ ] A5 — Skeleton headings byte-identical to the template file: the nine `##` headings of
      `.claude/docs/templates/design-language.md`, exactly as spelled, in order

---

## Coverage Notes

- The tokens file content (W3C Design Tokens groups, `$type`, aliases, light and dark values) depends on the spawned
  `design-engineer` and is asserted only for the approval and read-back steps.
- The Error Recovery path (a drafting agent BLOCKED → `Retry` / describe the section myself / `Stop here`) is not given
  its own case.
- Platform adaptation content (iOS Human Interface Guidelines, Material 3, web conventions) is outside what a static
  read of the skill can verify.
