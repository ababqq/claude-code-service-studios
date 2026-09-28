# Skill Test Spec: /ux-review

## Skill Summary

`/ux-review` validates a UX design document before it enters the implementation pipeline: a screen spec
(`# UX Spec:`), a flow spec (`# User Flow:`), the app shell (`# App Shell:`) or the interaction pattern library
(`# Interaction Pattern Library:`). It checks five review dimensions — **Completeness**, **PRD Alignment**,
**Accessibility** (against the committed `accessibility.target` and the `> **Target**:` line of
`design/accessibility-requirements.md`), **Pattern Library** and **Design Source Parity** (the document's
`> **Design Source**:` line against its handoff record `design/handoff/<slug>/HANDOFF.md` and retained screens:
`MATCHES | DRIFT FOUND | NOT ASSESSED | N/A — none`) — plus the `## API Data` operations against the
contract under `docs/api/` and the analytics events against the tracking plan. Input methods and breakpoints come from
the resolved `platform.surfaces` line. After the checklists it spawns the DD-UI-CONSISTENCY gate (`design-director`)
under the review-mode rules, then writes one review record per document to
`design/ux/reviews/<spec-stem>-ux-review-YYYY-MM-DD.md` with the verdict line directly under its H1. It never edits
the document it reviews.

Verdicts: `APPROVED` / `NEEDS REVISION` / `MAJOR REVISION NEEDED` / `NOT ASSESSED`. `NOT ASSESSED` ranks above
APPROVED and below the two revision verdicts: it is emitted when the spec cannot be read, when a dimension has no
criterion to check against, when the accessibility target is uncommitted, or when a declared claude-design or figma
source has no readable record. A NEEDS REVISION the user accepts is
recorded with a `> **Risk Accepted**:` line — the explicit acceptance the Validation → Build gate looks for.

Assertions quote the canonical English text of `.claude/skills/ux-review/SKILL.md`; prompts are rendered in the user's
conversation language at run time (`.claude/docs/coding-standards.md` § Language Policy) and this spec never asserts
the runtime wording.

---

## Static Assertions (Structural)

Verified automatically by `/skill-test static` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] `name: ux-review` equals the directory name (`.claude/skills/ux-review/`) and this spec's basename
- [ ] `argument-hint` is `"[file-path | all | shell | patterns] [--review full|lean|solo]"`
- [ ] The first body line is exactly
      `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,accessibility,surfaces,design` ``
      — the `--keys` value is exactly `review_mode,automation,accessibility,surfaces,design`
- [ ] `allowed-tools` contains the grant naming this skill's own directory:
      `Bash(bash "*/.claude/skills/ux-review/../../hooks/yaml-helper.sh" resolve_config *)`
- [ ] `allowed-tools` is exactly the set Read, Glob, Grep, Write, Agent, AskUserQuestion plus that grant — no `Edit`
      (the reviewed document is never edited), no plain `Bash`, no MCP tool names, no `Artifact` or `Skill` (live
      design tools are named conditionally, rule 15)
- [ ] Contains the sentence starting `The five review dimensions are **Completeness**, **PRD Alignment**,` and the
      dimension values `MATCHES`, `DRIFT FOUND`, `NOT ASSESSED`, `N/A — none` for **Design Source Parity**
- [ ] The line after the bootstrap block is exactly: ``Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] The automation prelude block — from `**Automation mode**: Resolve` to `categories always prompt).` — follows
      that line verbatim
- [ ] The bootstrap line is the only `!` injection in the file; no `file:line` citation of another file
- [ ] `model: sonnet`; no `disable-model-invocation` and no `isolation` key
- [ ] Has ≥2 phase headings (Phase 1 through Phase 5)
- [ ] Contains the verdict keywords `APPROVED`, `NEEDS REVISION`, `MAJOR REVISION NEEDED`, `NOT ASSESSED`
- [ ] Names the output: `design/ux/reviews/<spec-stem>-ux-review-YYYY-MM-DD.md`
- [ ] Contains "May I write this to `design/ux/reviews/<spec-stem>-ux-review-YYYY-MM-DD.md`?" before each record write
- [ ] The DD-UI-CONSISTENCY spawn carries this `Pass:` line verbatim:
      `` Pass: UX spec path or implemented screen list · design-language path · `design/ux/interaction-patterns.md` path · resolved `accessibility` line ``
- [ ] The spawn prompt tells `design-director` to read `.claude/docs/director-gates/dd-ui-consistency.md` first, and
      the parent parses the first reply line as `[DD-UI-CONSISTENCY]: TOKEN`
- [ ] Has a next-step handoff (`/ux-design` for revision, `/ux-review` re-run, `/api-design reconcile`, `/team-ui`,
      `/gate-check build`)

---

## Director Gate Checks

One gate, **DD-UI-CONSISTENCY** (`design-director`, tokens `APPROVE` / `CONCERNS` / `REJECT`), in Phase 4a — after the
checklists, before the record is written. It is not spawned for a document that could not be read. For `all`, the
mode check is applied once and one gate per document is spawned in parallel.

- **Full mode**: the gate spawns; its outcome is recorded in the record header line
  `> **Design Director Review (DD-UI-CONSISTENCY)**: …`.
- **Lean mode**: the lean suffix rule skips it (the ID does not end in `-PHASE-GATE`); the header line carries
  `[DD-UI-CONSISTENCY] skipped — Lean mode`.
- **Solo mode**: skipped; `[DD-UI-CONSISTENCY] skipped — Solo mode`.

The gate outcome shapes the verdict: CONCERNS accepted → ADVISORY issues; CONCERNS with revision requested → BLOCKING
issues (verdict at most NEEDS REVISION); REJECT → BLOCKING issues, never APPROVED.

---

## Test Cases

### Case 1: Happy Path — complete screen spec, full mode, APPROVED

**Fixture:**
- Moa; the config block prints `review_mode: full (project.yaml)`, `accessibility.target: wcag-aa (project.yaml)`,
  `platform.surfaces: web, ios, android, api (project.yaml)`, `design.tool: none (project.yaml)`
- `design/ux/goal-detail.md` (`# UX Spec: Goal Detail`, `> **Design Source**: none — markdown spec only`) has every
  template section populated: loading, empty,
  populated, error and offline states; keyboard, pointer, touch and screen-reader coverage; contrast specified for both
  themes; `## API Data` rows `in contract` that exist in `docs/api/openapi.yaml`; ≥5 testable acceptance criteria
- `design/accessibility-requirements.md` (`> **Target**: wcag-aa`), `design/ux/interaction-patterns.md` and
  `design/brand/design-language.md` exist
- The gate replies `[DD-UI-CONSISTENCY]: APPROVE`

**Input:** `/ux-review design/ux/goal-detail.md`

**Expected behavior:**
1. The H1 identifies a screen spec → Phase 3A checklist; context is loaded from the surfaces line, the accessibility
   target, the pattern library, the PRD `## UI Requirements`, the design language, the app shell, the contract and the
   tracking plan
2. All checks pass
3. Phase 4a spawns `design-director` with the Pass items: `design/ux/goal-detail.md`,
   `design/brand/design-language.md`, `design/ux/interaction-patterns.md`, and the `accessibility` line as printed
4. The record is shown, then "May I write this to `design/ux/reviews/goal-detail-ux-review-YYYY-MM-DD.md`?"
5. The record's header reads `> **Verdict**: APPROVED` and
   `> **Design Director Review (DD-UI-CONSISTENCY)**: APPROVED [date]`; the handoff suggests `/team-ui`

**Assertions:**
- [ ] All five dimensions are checked and reported with a per-dimension status; Design Source Parity is `N/A — none`
- [ ] The verdict line sits directly under the H1 and one blank line, with exactly one token
- [ ] The reviewed spec is not modified
- [ ] Verdict is `APPROVED`

---

### Case 2: Screen-Level Accessibility Section Empty — NEEDS REVISION

**Fixture:**
- As Case 1, but `## Screen-Level Accessibility Requirements` holds only `[To be designed]`

**Input:** `/ux-review design/ux/goal-detail.md`

**Expected behavior:**
1. The Completeness check fails for that section; the Accessibility dimension reports `GAPS`
2. The record lists specific items to add (screen-reader names and announcements, focus order, contrast per theme)
   as BLOCKING issues with where and how to fix
3. Verdict `NEEDS REVISION`; the handoff points back to `/ux-design goal-detail`
4. Before the record is written, `AskUserQuestion`: "Revise first (recommended)" / "Accept the risk and proceed"

**Assertions:**
- [ ] `NEEDS REVISION` is returned (not APPROVED or MAJOR REVISION NEEDED)
- [ ] Specific missing content items are listed
- [ ] If the user accepts the risk, the record is written with `> **Risk Accepted**: [YYYY-MM-DD] — NEEDS REVISION
      accepted by the user; the blocking issues below remain open` below the verdict line, and the token stays
      `NEEDS REVISION` — the question comes before the one approved record write (the skill has no `Edit`)
- [ ] No acceptance is recorded that the user did not give

---

### Case 3: States Incomplete — NEEDS REVISION

**Fixture:**
- `design/ux/goal-list.md` documents only loading and populated states; empty and offline states are missing, and a
  toast auto-dismisses without a stated duration

**Input:** `/ux-review design/ux/goal-list.md`

**Expected behavior:**
1. The States & Variants check fails: the missing states are named explicitly (empty — first use and no results;
   offline — which reads work from cache and which actions queue or disable)
2. The undocumented timer is flagged
3. Verdict `NEEDS REVISION`; the handoff suggests `/ux-design goal-list`

**Assertions:**
- [ ] Each missing state is named in the record
- [ ] A fixable gap does not produce `MAJOR REVISION NEEDED`
- [ ] The record is written only after "May I write this to …?"

---

### Case 4: File Not Found — NOT ASSESSED with remediation

**Fixture:**
- `design/ux/goal-history.md` does not exist

**Input:** `/ux-review design/ux/goal-history.md`

**Expected behavior:**
1. The spec cannot be read; the review reports `NOT ASSESSED` and names the path
2. The DD-UI-CONSISTENCY gate is not spawned for a document that could not be read
3. The skill suggests `/ux-design goal-history` to create the spec first

**Assertions:**
- [ ] The message names the missing file with its full path
- [ ] No gate agent is spawned
- [ ] The verdict is `NOT ASSESSED` — never APPROVED
- [ ] `/ux-design goal-history` is suggested as the remediation

---

### Case 5: NOT ASSESSED — no committed accessibility target (missing input)

**Fixture:**
- As Case 1, but the config block prints `accessibility.target: (unset -- ask; unset is not none)` and
  `design/accessibility-requirements.md` does not exist; the spec header claims `> **Accessibility Target**: wcag-aa`
- Every other dimension passes

**Input:** `/ux-review design/ux/goal-detail.md`

**Expected behavior:**
1. The Accessibility dimension has no criterion: the record reports
   `Accessibility: NOT ASSESSED — no committed target (design/accessibility-requirements.md absent)`
2. The spec's own header target is carried forward only as an **assumption**, said plainly
3. Verdict `NOT ASSESSED`; `/ux-design accessibility` is recommended to commit the target
4. Variant: a committed target of `none` reports
   `Accessibility: N/A — target is none (recorded decision; no conformance claim)`, lists blockers as ADVISORY and
   leaves the dimension out of the verdict

**Assertions:**
- [ ] The dimension is never reported COMPLIANT against an absent standard
- [ ] `NOT ASSESSED` outranks APPROVED but does not displace a revision verdict when blocking issues exist
- [ ] Re-running against the same missing inputs does not report a different verdict

---

### Case 6: Mode Variant — `all` reviews every top-level spec

**Fixture:**
- `design/ux/` holds `goal-detail.md`, `goal-list.md`, `app-shell.md` and `interaction-patterns.md`;
  `design/ux/reviews/` holds earlier records; `review_mode: full (project.yaml)`

**Input:** `/ux-review all`

**Expected behavior:**
1. Only the top level of `design/ux/` is reviewed — `design/ux/reviews/` is never reviewed
2. Each file is routed by its H1 (3A, 3B for the shell, 3C for the pattern library)
3. The mode check is applied once; one DD-UI-CONSISTENCY gate per document is spawned in parallel and every verdict is
   collected before records are written
4. A summary table (file | verdict | primary issue) comes first, then full detail
5. Every record path is listed and approved once as a changeset

**Assertions:**
- [ ] All `Agent` calls are issued before any result is awaited
- [ ] `design/accessibility-requirements.md` is not reviewed — it is the criterion
- [ ] An existing record at the same path is replaced only after asking

---

### Case 7: Review Mode — `full`, DD-UI-CONSISTENCY returns REJECT

**Fixture:**
- As Case 1; the gate replies `[DD-UI-CONSISTENCY]: REJECT` (the spec re-specifies the confirmation dialog instead of
  using the pattern library's destructive-confirmation pattern, and uses colors outside the design language)

**Input:** `/ux-review design/ux/goal-detail.md`

**Expected behavior:**
1. The findings become BLOCKING issues; the verdict cannot be APPROVED (NEEDS REVISION, or MAJOR REVISION NEEDED when
   fundamental)
2. The record is still written — it is the evidence of the review — with the outcome line `REJECT [date]`
3. A CONCERNS reply instead offers "Revise flagged items" / "Accept and proceed" / "Discuss further"; accepted →
   `CONCERNS (accepted) [date]` with ADVISORY issues; revise → `CONCERNS [date] — revision requested`

**Assertions:**
- [ ] The first reply line is parsed as `[DD-UI-CONSISTENCY]: TOKEN`; an unparseable line is CONCERNS-class with a
      note that the verdict line was missing
- [ ] A REJECT-class verdict never results in `APPROVED`
- [ ] The skill does not auto-fix the spec; it offers help and waits for instruction

---

### Case 8: Review Mode — `lean` skips DD-UI-CONSISTENCY by the suffix rule

**Fixture:**
- As Case 1; the config block prints `review_mode: lean (rigor:standard)`

**Input:** `/ux-review design/ux/goal-detail.md`

**Expected behavior:**
1. The checklists run; Phase 4a skips the gate: `[DD-UI-CONSISTENCY] skipped — Lean mode`
2. The skip note is written in the record where the gate outcome line would go
3. With every check passing, the verdict is `APPROVED`

**Assertions:**
- [ ] The SKILL.md review-mode check contains the sentence
      `` `lean` → **skip every gate whose ID does not end in `-PHASE-GATE`**. Note: `[GATE-ID] skipped — Lean mode` ``
- [ ] No `design-director` spawn in lean mode
- [ ] The skipped gate is reported by name — never omitted
- [ ] `--review full` on the same project spawns the gate

---

### Case 9: Review Mode — `solo`

**Fixture:**
- As Case 1; the config block prints `review_mode: solo (rigor:minimal)`

**Input:** `/ux-review design/ux/goal-detail.md`

**Expected behavior:**
1. Phase 4a skips all gates: `[DD-UI-CONSISTENCY] skipped — Solo mode`, written in the record header
2. The verdict comes from the five dimensions alone

**Assertions:**
- [ ] No gate agent is spawned in solo mode
- [ ] The skip note reads exactly `[DD-UI-CONSISTENCY] skipped — Solo mode`
- [ ] The skill never writes `modes.review_mode`

---

### Case 10: Design Source Parity — Figma record: MATCHES, DRIFT FOUND, NOT ASSESSED, stale review

**Fixture:**
- As Case 1, but the config block prints
  `design.tool: figma file_url=https://www.figma.com/design/<fileKey>/Moa (project.yaml)` and the spec's header reads
  `` > **Design Source**: figma — https://www.figma.com/design/<fileKey>/Moa?node-id=12-345 · record `design/handoff/goal-detail/HANDOFF.md` ``
- `design/handoff/goal-detail/HANDOFF.md` has `> **Verdict**: RETAINED` and `> **Retrieved**: 2026-10-12`; its
  `## Screens & States` has a retained screen for every state and breakpoint of the spec; `### Wireframe` reads
  "external: see Design Source — screens listed from the handoff record" with a text hierarchy description
- `design/ux/reviews/goal-detail-ux-review-2026-10-05.md` exists (an earlier APPROVED review)
- Variant A: the record has no screen for the offline state, and a screen for a "promo banner" state the spec lacks
- Variant B: the record has `> **Verdict**: NOT ASSESSED`, and the Figma MCP server's tools are not present in the
  session; every other dimension passes
- Variant C: as Variant B, but the Accessibility section is empty (a BLOCKING Completeness gap)

**Input:** `/ux-review design/ux/goal-detail.md`

**Expected behavior:**
1. Phase 2 loads the Design Source line and Reads the record and its retained screens; the header-completeness item
   requires Design Source (the `design` line is figma); the external wireframe is accepted because the record is
   RETAINED and a text hierarchy description is kept
2. The record reports `## Design Source Parity: MATCHES`; its header carries
   `> **Design Source**:` with the record's verdict and retrieved date; the earlier 2026-10-05 review is named as stale
   (the record was retrieved after it)
3. Variant A: `DRIFT FOUND` — the missing offline screen and the unmatched promo-banner screen are BLOCKING issues;
   verdict `NEEDS REVISION` at most
4. Variant B: `Design Source Parity: NOT ASSESSED — external design not retained (<url>)` plus
   `NOT CHECKED — Figma MCP tools not present in this session`; the verdict is `NOT ASSESSED`, never APPROVED; the
   external wireframe does not satisfy the Layout Specification item; `/design-handoff --for goal-detail` (or
   `refresh goal-detail`) is recommended
5. Variant C: the Completeness gap yields `NEEDS REVISION`, which outranks the parity `NOT ASSESSED`

**Assertions:**
- [ ] The Figma file is never fetched by an agent; the skill reads the record with Read and names any live tool only
      conditionally
- [ ] `NOT ASSESSED` parity never reads as `MATCHES`, and blocks APPROVED
- [ ] `DRIFT FOUND` caps the verdict at NEEDS REVISION
- [ ] The stale-review comparison uses the review record's file-name date against the handoff record's
      `> **Retrieved**:` date
- [ ] The reviewed spec is not modified

---

## Protocol Compliance

- [ ] Checks the five dimensions and reports each separately, with a per-section checklist before the verdict
- [ ] Checks states (loading, empty, error, offline) and input methods for every covered surface
- [ ] Never edits or writes the document it reviews; its only writes are review records, each after "May I write"
- [ ] Issues specific, actionable feedback when the verdict is not APPROVED
- [ ] Never blocks the user from proceeding — the verdict is advisory and an accepted risk is recorded
- [ ] Ends with a closing `AskUserQuestion` offering the next steps that apply

**Authoring rubric** (`CCSS Skill Testing Framework/quality-rubric.md` § `authoring`; `/ux-review` is the category's
review-shaped member):

- [ ] A1–A3 — N/A as authoring metrics: the skill does not author or retrofit the reviewed document; its record is
      assembled, shown and approved once per document (or once per `all` changeset)
- [ ] A4 — DD-UI-CONSISTENCY runs in `full`, is skipped with a named note in `lean` and `solo`
- [ ] A5 — The record's fixed shape is kept exactly: `# UX Review: [Document Name]`, the `> **Verdict**:` line
      directly under it, the header labels (including `> **Design Source**:`), and the `## Completeness`,
      `## Quality Issues`, `## PRD Alignment`, `## Accessibility`, `## Pattern Library`, `## Design Source Parity`,
      `## API Data Check` and `## Summary` headings (the skill has no template
      file under `.claude/docs/templates/`; the format block in Phase 4b is the template)

---

## Coverage Notes

- MAJOR REVISION NEEDED for structurally absent sections or a missing core flow is covered only through Case 7's
  REJECT branch.
- The flow-spec checklist (a critical-path screen without its own `## API Data` spec is BLOCKING) is not given its own
  case.
- The design-language consistency check (component, token and breakpoint names) depends on the gate agent's reading
  and is not fixture-tested beyond Case 7.
- An unset `design` line with no Design Source line in the document (the skill asks once per run; "None" ⇒
  `N/A — none`) is not fixture-tested. Claude Design sources follow the same path as Figma in Case 10.
- When `platform.surfaces` is unset, input coverage is checked against the spec's own `> **Surfaces**:` header and the
  record says so — not fixture-tested.
