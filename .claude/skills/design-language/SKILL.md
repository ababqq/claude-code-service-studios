---
name: design-language
description: "Author the design language (9 sections) that gates UI production; runs brand direction first when the brief has none."
argument-hint: "[--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/design-language/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,docs.density,surfaces,accessibility,design`

Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

# Design Language

This skill authors `design/brand/design-language.md` — the visual and interaction
source of truth that every UI surface builds on. UX specs, the app shell, the
interaction pattern library, the component library and every icon, illustration
and store screenshot take their colors, type, spacing, component states, motion
and platform rules from it. It is written **before** hi-fi UI production starts,
because a component library built without it gets rebuilt when it arrives.

It starts from the product's own principles: when the brief carries a
`## Brand Direction Anchor`, that anchor is the foundation; when it does not, the
skill runs the brand-direction gate first so the user chooses a direction before
any token is named.

### Outputs

| Path | What is written |
|------|-----------------|
| `design/brand/design-language.md` | The nine sections of `.claude/docs/templates/design-language.md`, written one approved section at a time, with the header block and the verdict line |
| `design/brand/tokens.json` (optional) | The tokens of sections 2, 3, 4 and 7 in the W3C Design Tokens Community Group format (`$value`, `$type`, aliases), for a token pipeline to build CSS, iOS and Android outputs from |

The nine section headings are a contract — `/gate-check` (gate-build), `/ux-review`
and the director gates match them. Copy them from the template exactly and never
translate them: `## 1. Brand Principles`, `## 2. Color System`, `## 3. Typography`,
`## 4. Layout, Spacing & Grid`, `## 5. Components & States`,
`## 6. Iconography & Illustration`, `## 7. Motion & Feedback`,
`## 8. Platform Adaptation`, `## 9. Content & Voice`.

### Verdict

The design language carries the verdict line of this skill directly under its H1
(`> **Verdict**: <TOKEN>`), with one of these tokens:

| Token | Meaning |
|-------|---------|
| `COMPLETE` | All nine sections are complete and nothing in them is left not checked |
| `PARTIAL — SECTIONS <n>-<m>` | Sections n–m are complete; at least one other section is not. `PARTIAL — SECTIONS 1-5` is what the `standard` tier requires |
| `NOT ASSESSED` | All nine sections are written, but something they require could not be verified — the contrast check against an unset accessibility target, a specialist check that did not run, a retrofitted section the user did not confirm. Each reason is listed in the `> **Not Checked**:` header line |

Precedence: **PARTIAL > NOT ASSESSED > COMPLETE**. A known gap is more actionable
than an unverified section, and an unverified section has not established that
the document is complete. When the complete sections are not one contiguous run
(for example 1–5 and 7), the verdict names the run that starts at section 1 and
the `> **Sections Deferred**:` line names the rest.

The verdict is about completeness. The director's sign-off is recorded separately
(Phase 6) and never changes the token.

A run that stops in Phase 0 before anything is written — no brief or one-pager,
`Stop here` for an API-only product, or `Stop and decide the target` for an unset
accessibility target — creates no document and reports
`Verdict: NOT ASSESSED — <the reason>` in the conversation only.

### What this skill never does

- **Draft a section itself.** Every section's content comes from a specialist
  (product-designer, design-engineer, accessibility-specialist); the skill
  frames, merges, presents and writes.
- **Write `accessibility.target`, `platform.surfaces` or any `modes.*` key.**
  The target is decided with `/ux-design accessibility`, surfaces with
  `/setup-stack`, modes with `/settings`. This skill reads the resolved lines and
  asks when one is unset.
- **Write `design.*` or anything under `design/handoff/`.** `/design-handoff`
  retains external designs and writes the `design:` block only when it is unset;
  `/setup-stack` and `/settings` also write it. This skill reads the resolved
  `design` line and the handoff records, and asks when the line is unset.
- **Write to Figma or Claude Design.** Pushing tokens to Figma variables and
  uploading a component library to Claude Design are external writes the user
  runs and approves through Figma's own skill or the bundled `/design-sync`
  (Phase 5); this skill only names them.
- **Edit the product brief.** A brand direction chosen here is recorded in
  `## 1. Brand Principles` of the design language, not in the brief.
- **Define a voice.** `## 9. Content & Voice` points to
  `design/brand/voice-and-tone.md` (owned by `/team-content`) and adds UI copy
  rules only.
- **Read a gate definition file.** The spawned `design-director` reads its own
  gate file; this skill passes the path and the context items only.

---

## Phase 0: Parse Arguments and Context Check

See `.claude/docs/director-gates.md` for the full check pattern. Individual gate
definitions live in `.claude/docs/director-gates/[gate-id].md` — the spawned agent
reads its own gate file; do not read it in the parent session.

**Arguments.** `--review [full|lean|solo]` overrides the resolved `review_mode`
for this run. There are no other arguments — scope is chosen in Phase 2.

**Surfaces.** Read the resolved `platform.surfaces` line.
- Contains `web`, `ios` or `android` → a UI surface exists; continue.
- `api` only → there is no UI surface. Say: "The design language applies to UI
  surfaces; `platform.surfaces` lists `api` only, so the catalog does not require
  it." Use `AskUserQuestion`: `Stop here (Recommended)` /
  `Continue anyway — for a developer portal or docs site I will add as a web surface`.
  On continue, treat the run as `web` and say that `/setup-stack` should record
  the web surface.
- Unset (`platform.surfaces: (unset -- ask which surfaces ship)`) → unset is not
  "no UI". Ask which surfaces ship (`web`, `ios`, `android`, several). Use the
  answer for this run only and name `/setup-stack` as the place that records it.

Every later phase adapts to the surfaces in force: section 8 covers exactly these
surfaces, and the font stack, target sizes and haptics rows cover only them.

**Tier and scope.** `docs.density` controls per-section *depth*, where `workflow`
controls which sections are required. `modes.rigor` sets both together; set
`docs.density` explicitly to vary depth alone. Apply it to every section you
author:
- `terse` — each section a bulleted list of tokens, constraints and references.
- `balanced` — paragraphs explaining each choice.
- `thorough` — full prose, including explorations and the rationale per token family.

`workflow` (see `.claude/docs/workflow-modes.md`):
- `full` — all nine sections required.
- `standard` — sections 1–5 required (a UI surface exists, established above);
  6–9 optional.
- `minimal` — not required. The skill can still be run voluntarily; say so.

Read `workflow_overrides.design_language_strict` from `project.yaml` with Read (it
has no `resolve_config` label). `true` forces all nine sections at any tier.

**Brief.** At `standard` and `full` read `design/product/product-brief.md`; at
`minimal` read `design/product/one-pager.md`. When the tier's document is missing
but the other exists, use the other and say so. When neither exists, stop:
> "No product brief found. Run `/brainstorm` first — the design language is
> derived from the product principles and target users in the brief."

Do not full-read the brief. Grep its headings, then read only these sections:
- H1 (product name), `## Elevator Pitch` (or the one-pager's `## Pitch`)
- `## Target Users & Jobs-to-be-Done` (or `## Problem & Target User`)
- `## Alternatives & Positioning`
- `## Product Principles & Anti-Goals` — the one-pager has none; record
  "no principles section (one-pager)" and derive from the pitch and scope instead
- `## Brand Direction Anchor` — optional; present only when `/brainstorm` recorded
  a direction

**Other inputs** — read when present, never required:
- `design/accessibility-requirements.md` — its `> **Target**:` line and the
  regional standards it lists (KWCAG 2.2 for `kr`, the European Accessibility Act
  for `eu`, ADA / Section 508 for `us`).
- `design/brand/voice-and-tone.md` — section 9 points to it.
- `design/ux/app-shell.md`, `design/ux/interaction-patterns.md`,
  `design/inventory/screen-inventory.md` — existing screens and components the
  design language must cover.
- `design/handoff/design-system/HANDOFF.md` (the design source's tokens and
  components, below) and `design/handoff/brand-directions/HANDOFF.md` (directions
  explored visually in an earlier run).
- `project.yaml`, read with Read: `localization.locales` (which scripts the type
  system must set — Hangul, Latin, others) and `performance.bundle_kb` (the route
  budget web fonts compete with). Neither has a `resolve_config` label.

**Accessibility target.** Read the resolved `accessibility.target` line.
- `wcag-a`, `wcag-aa`, `wcag-aaa` → contrast, focus and target-size checks run
  against that level of WCAG 2.2.
- `none` → a recorded decision: contrast ratios are reported as information, not
  gated. If `design/accessibility-requirements.md` lists a regional standard,
  point out the conflict to the user.
- Unset (`accessibility.target: (unset -- ask; unset is not none)`) → do not
  assume a level. Use `AskUserQuestion`:
  `Stop and decide the target with /ux-design accessibility first (Recommended)` /
  `Continue — check against wcag-aa as a working bar, recorded as not checked against a committed target`.
  On continue, every contrast row carries `NOT CHECKED — accessibility.target unset`,
  the `> **Not Checked**:` line says so, and the verdict cannot be `COMPLETE`.

**Design source.** Read the resolved `design` line — where the design system also
lives outside the repo.
- `design.tool: claude-design …` or `design.tool: figma …` → a Claude Design
  design-system project or a Figma library is declared. Glob
  `design/handoff/design-system/HANDOFF.md` and, when it exists, read its
  `> **Verdict**:`, `> **Retrieved**:` and `> **Not Checked**:` lines now; its
  values are used in Phase 3.
- `design.tool: none` → a recorded decision: this document and `tokens.json` are
  the whole design system record; no reconcile step runs and no design-source
  `NOT CHECKED` line is written.
- Unset (`design.tool: (unset -- ask; unset is not none)`) → never treat it as
  `none`; it is asked in Phase 2.

**Retrofit mode.** Glob `design/brand/design-language.md`. If it exists, build the
status table **without reading the document** — you are about to author only the
incomplete sections, so loading the complete ones is loading exactly what you
will not touch:

```
Grep pattern="^## " path="design/brand/design-language.md" output_mode="content" -n
Grep pattern="\[To be designed\]|\[TBD\]|\[To be written\]|^_?TODO|NOT CHECKED" path="design/brand/design-language.md" output_mode="content" -n
```

- The first grep gives the section headings and their line numbers — the gap
  between consecutive headings is that section's size.
- The second gives placeholder markers and not-checked items, and where they fall.
- A section is **Complete** if it has substantive distance to the next heading and
  no placeholder marker inside it; **Placeholder** if a marker falls in its range;
  **Empty** if consecutive headings sit adjacent; **Missing** if its heading is
  absent. A `NOT CHECKED` marker makes a section **Complete (not checked)**.
- Where the two greps leave a section genuinely ambiguous, read *that section's*
  line range with `Read(offset, limit)` — never the whole file.
- Build and present the table:

```
Section | Status
--------|--------
1. Brand Principles | [Complete / Complete (not checked) / Empty / Placeholder / Missing]
2. Color System | ...
3. Typography | ...
4. Layout, Spacing & Grid | ...
5. Components & States | ...
6. Iconography & Illustration | ...
7. Motion & Feedback | ...
8. Platform Adaptation | ...
9. Content & Voice | ...
```

> "Found an existing design language at `design/brand/design-language.md`. [N]
> sections are complete, [M] need content. I'll work on the incomplete sections
> only — existing content will not be touched."

Only Empty, Placeholder and Missing sections are authored, plus Complete (not
checked) sections when the reason can now be resolved (for example the target has
since been committed). A heading that deviates from the template (renamed,
translated, unnumbered) is reported as Missing and its content offered for a move
under the exact heading — the gate does not find it otherwise.

If the file does not exist, this is a fresh authoring session.

---

## Phase 1: Brand Direction

The direction must be settled before section 1 is drafted; everything else builds
on it. Skip this phase when the retrofit table shows section 1 as Complete — the
direction is already recorded in its `### Direction Record`; say so and continue
with Phase 2.

### 1a. The brief has a `## Brand Direction Anchor`

Present it:
> "Found a brand direction in the brief: '[name] — [one-line rule]'. I'll build
> the design language on it."

Use `AskUserQuestion`: `Build directly on this anchor` / `Revise it before expanding` /
`Start fresh — propose new directions`. `Start fresh` continues with 1b. The
brief's anchor stays untouched either way; a revised or new direction is recorded
in `## 1. Brand Principles` and the header's `> **Brand Direction**:` line. With
the anchor used, the header records DD-BRAND-DIRECTION as
`not run — direction taken from the brief's anchor`. When the anchor carries a
`**Visual reference**` URL other than "none", name it in the presentation and
carry it into the `### Direction Record`'s Visual reference row.

### 1b. No anchor (or the user started fresh) — DD-BRAND-DIRECTION

**Review mode check** — apply before spawning DD-BRAND-DIRECTION:
- `solo` → skip. Note: `[DD-BRAND-DIRECTION] skipped — Solo mode`
- `lean` → **skip every gate whose ID does not end in `-PHASE-GATE`**. Note: `[GATE-ID] skipped — Lean mode`
  DD-BRAND-DIRECTION does not end in `-PHASE-GATE`, so it is skipped:
  `[DD-BRAND-DIRECTION] skipped — Lean mode`
- `full` → spawn as normal.

**When it runs**, spawn `design-director` via `Agent` with gate
**DD-BRAND-DIRECTION** (`.claude/docs/director-gates/dd-brand-direction.md`). The
`Agent` prompt instructs the agent to read that file first; do not read it or
paste it into the prompt.
Pass: brief path · product principles text · target users · resolved `surfaces` line

Fill them from Phase 0: the brief path as read; the text of
`## Product Principles & Anti-Goals` (or "no principles section (one-pager)" plus
the pitch); the `## Target Users & Jobs-to-be-Done` text; the resolved
`platform.surfaces` line copied as printed (or the answer the user gave in
Phase 0, marked as such).

Parse the first line of the reply as `[DD-BRAND-DIRECTION]: TOKEN` and map the
token with `.claude/docs/director-gates.md` § Standard Verdict Format:
- **OPTIONS** (selection, not a verdict) → present the directions (name, brand
  rule, personality, color philosophy, typography, shape and density, motion,
  platform stance) and the director's recommendation. Use `AskUserQuestion`, one
  option per direction plus `Combine elements — I'll describe how` and
  `Describe my own direction`. The chosen one is APPROVE-class; record
  `APPROVED [date]` in the header.

  **Optional — see the directions before choosing.** When the bundled `/design`
  skill is present in the session, add the option
  `Visualise the directions first — /design-handoff new <directions> --for brand-directions`.
  The main session does this, never the `design-director` agent (agents cannot
  reach `/design` or the Artifact tool): it runs `/design-handoff new` with the
  2–3 directions as the brief — through the `Skill` tool if it is present in the
  session, else by asking the user to run it and rerun `/design-language`
  afterwards. `/design-handoff` drafts them with `/design` (publishing a Design
  artifact is an external write — approved first) and retains the result as
  `design/handoff/brand-directions/HANDOFF.md`. Then ask the selection question
  above again, with the record's screens named per direction. The record path goes
  into the `### Direction Record`'s Visual reference row. When `/design` is absent,
  omit the option and say once:
  `NOT CHECKED — /design skill not available in this session (needs artifacts)`.
- **STRONG** (APPROVE-class) → present the dominant direction together with the
  runner-up; the user still confirms the choice with `AskUserQuestion`.
- **CONCERNS** (CONCERNS-class) → the principles do not give enough direction yet.
  Show which principle or positioning statement must be sharpened. Use
  `AskUserQuestion`: `Sharpen the brief's principles first (edit the brief or rerun /brainstorm, then rerun this skill)` /
  `Describe my own direction and proceed` / `Discuss further`. Proceeding records
  `CONCERNS (accepted) [date]`.
- A REJECT-class token, a token that is not on this gate's Verdicts line, or a
  first line that does not parse → not an approval. Surface the full reply as
  CONCERNS-class and say that the verdict line was missing or invalid.

**When it is skipped** (lean or solo), the note goes into the header's
DD-BRAND-DIRECTION line, and the direction still has to come from somewhere. Use
`AskUserQuestion`:
- `Describe the direction myself`
- `Have product-designer draft 2–3 directions (authoring, not a director review)`
- `Rerun with --review full to get the director's directions`

On the second option spawn `product-designer` via `Agent` with the brief sections
from Phase 0 and ask for 2–3 distinct directions in the same seven parts the gate
asks for, one directly serving the most important principle; the user selects
from them as above.

The selected direction, its source and the alternatives not chosen are recorded in
the `### Direction Record` of section 1 when that section is written (Phase 3) —
never in the brief.

---

## Phase 2: Framing

Present the session context (product, surfaces, target, tier, direction, design
source) and ask two questions before authoring anything — three when the `design`
line is unset. Use `AskUserQuestion` with one tab per question:

- Tab **"Scope"** — "Which sections do we author today?"
  Options: `All nine sections` / `Foundation — sections 1–5` /
  `Resume — incomplete sections only` / `Tokens only — tokens.json from the existing sections`

  **Mark the option the resolved tier actually requires as (Recommended), and say
  why** — the tier already decides this and the user should not need the tier
  table to answer:
  - `full`, or `design_language_strict: true` → **All nine sections**.
  - `standard` → **Foundation — sections 1–5**: "Sections 1–5 are what `standard`
    requires; 6–9 are available if you want them."
  - `minimal` → nothing is required. Say so before asking and offer sections 1–5
    as the useful-if-you-want-it option rather than defaulting to nine.
  - Retrofit with incomplete sections → **Resume**.
  - `Tokens only` is offered only when sections 2–4 are complete; it skips
    Phases 3, 4 and 6 and goes straight to Phase 5.

  This is the biggest cost lever in the skill: every authored block carries
  specialist spawns, so authoring nine sections where the tier requires five
  nearly doubles the run for sections nothing downstream checks.
- Tab **"References"** — "Is there anything the design language must start from or
  learn from?" (Free text — do NOT preset options.) Examples to prompt with:
  existing brand assets (logo, colors, a Figma library link), products whose
  design the user admires or wants to avoid (Toss, KakaoBank, Banksalad, Monzo,
  Revolut for a fintech), platform constraints already decided.
- Tab **"Design source"** — asked only when the resolved `design` line is unset
  (unset is not `none`): "Where does the design system live besides this
  document?" Options: `Claude Design — a design-system project` /
  `Figma — a library file` / `None — this document and tokens.json only`. The
  answer applies to this run only — this skill never writes `design.*`; name
  `/design-handoff` (which records it when it imports the source), `/setup-stack`
  or `/settings` as the place that records it. When the line is resolved, show it
  in the session context instead of asking.

The design source (resolved or answered) goes into the header's
`> **Design Source**:` line — first token exactly `none`, `claude-design` or
`figma`, then the project or library URL and the record
`design/handoff/design-system/HANDOFF.md`, then the token direction (set in
Phase 5).

---

## Phase 3: Foundation (Sections 1–5)

These five sections define the system every screen is built from. Author and
write each one before moving to the next.

> **Spawn policy for this phase.** Section 1 is delegated on its own — every other
> section derives from it, and the user must lock it first. Sections 2–5 are then
> drafted in **one** `product-designer` call: color, type, spacing and component
> states are interdependent — a palette chosen without the type scale, or states
> without the palette, contradict each other. The draft is then checked by
> `design-engineer` and `accessibility-specialist` **in parallel** (issue both
> `Agent` calls before waiting for either): one turns it into a buildable token
> architecture, the other measures it against the accessibility target.
>
> **This is not reduced specialist involvement** — every section is still authored
> by a specialist and checked by the two whose domain it touches. Per-section user
> approval and write-to-file-immediately are unchanged.

### Section 1: Brand Principles

Spawn `product-designer` via `Agent`:
- Provide: the selected direction (Phase 1) with its source, the product
  principles and anti-goals, target users and JTBD, positioning, the references
  from Phase 2, the surfaces in force.
- Ask: "Draft section 1 of the design language. Provide: (1) a one-line brand rule
  that could resolve any visual ambiguity; (2) 2–3 principles, each tied to a
  named product principle and each with a design test ('when X is ambiguous,
  this principle says choose Y'); (3) personality — three adjectives and one
  'but not'; (4) the direction record (selected direction, source, alternatives
  not chosen); (5) a reference table — for each reference, the specific technique
  to take and what to avoid so we do not read as a copy. A principle that no
  product principle supports is decoration — drop it."

Present the draft. Use `AskUserQuestion`:
`Lock this in` / `Revise the brand rule` / `Revise a principle` / `Describe my own direction`.

Before writing section 1 of a new file, ask: "May I write this to
`design/brand/design-language.md`?" — create it from
`.claude/docs/templates/design-language.md`: the H1, the verdict line set to
`PARTIAL — SECTIONS 1-1`, the header block filled from Phases 0–2, the
approved section 1, and the other eight section headings exactly as the template
spells them, each with only `[To be designed]` beneath it. Do not copy the
template's example tables or bracketed guidance into sections that have not been
authored — a later retrofit run would read them as content. Each later section
replaces its `[To be designed]` placeholder with Edit, following the template's
`###` structure for that section, after its own "May I write this to
`design/brand/design-language.md`?".

### Sections 2–5: one draft, two checks

**Design source values** — only when the design source is `claude-design` or
`figma`; with `none` skip this step silently (a recorded decision, not a gap).
Before the draft, the main session reads `design/handoff/design-system/HANDOFF.md`
with Read: its `## Tokens & Components` section (the Figma variables — colors,
type, spacing, modes — and library components, or the Claude Design design
system's tokens and components), plus the retained bundle CSS under
`design/handoff/design-system/bundle/` when the section points to it. Agents cannot
reach the Figma MCP server, the Claude Design connector or the Artifact tool, so
they get these values and the record path, never a live link to fetch.
- Record verdict `RETAINED` or `LINK ONLY` → pass the values to the draft and both
  checks below as **existing values to adopt or reconcile**.
- Record verdict `NOT ASSESSED` → the values are unverified, never a match. Offer
  `/design-handoff refresh design-system` the same way as the offer below; on
  continue, carry the record's `> **Not Checked**:` items into this document's
  `> **Not Checked**:` line and handle the source as not retained.
- No record → offer it with `AskUserQuestion`:
  `Import the design system first — /design-handoff --for design-system, then rerun /design-language (Recommended)` /
  `Continue without it`. On continue (and for a `NOT ASSESSED` record), print
  `NOT CHECKED — external design not retained (<url>)` — `<url>` being the
  resolved `project_url` or `file_url`, or `unset` — into the header's
  `> **Not Checked**:` line, and write the same line on its own at the end of
  section 2 when that section is written, so a later retrofit run reads the section
  as Complete (not checked) and reconciles it once the record exists. Like any
  not-checked item, it keeps the verdict below `COMPLETE`.

**Draft** — spawn `product-designer` via `Agent` with the locked section 1, the
surfaces, the accessibility target line, `localization.locales`, the Phase 2
references and the design source values (when passed): "Adopt each existing
value that fits section 1 and the accessibility target; where you change or drop
one, say which and why." Ask for four separately labelled blocks that are
mutually consistent:

1. **Color System** — "Primitive palette with light and dark values; semantic
   tokens (`color.bg.*`, `color.text.*`, `color.action.*`, `color.feedback.*`,
   `color.border.*`) mapped to primitives per theme; theme behaviour (system
   preference, user override, dark-mode elevation, Android dynamic color used or
   overridden); what each semantic color means in this product, including
   cultural conventions of the target market (in Korean finance interfaces red
   commonly signals a rise, not an error); every status also carries an icon,
   label or shape — never color alone."
2. **Typography** — "Font stack per surface with Hangul-first fallbacks (for
   example Pretendard on the web with `"Apple SD Gothic Neo"`, `"Noto Sans KR"`
   and `system-ui` fallbacks); a type scale as tokens; line height suited to
   Hangul; `word-break: keep-all` for Korean text on the web; tabular numerals for
   amounts; behaviour at 200% zoom, iOS Dynamic Type and Android font scale."
3. **Layout, Spacing & Grid** — "Spacing scale, breakpoints `sm`/`md`/`lg` for the
   web and compact/regular for mobile, columns, gutters, margins, max content
   width, safe areas, radius and elevation scales, density per surface."
4. **Components & States** — "Core components with variants; a state matrix
   (default, hover, focus, pressed, disabled, loading, error, empty) for each;
   the focus indicator; minimum target sizes per surface; form validation timing
   and error placement; the confirmation pattern for destructive and
   money-moving actions ('Cancel subscription', never 'OK'), and the amount
   format shown before a payment is confirmed."

**Checks** — spawn both in parallel, each with the four blocks:
- **`design-engineer`**: "Turn this into a buildable token architecture:
  primitive → semantic → component tiers, names that describe purpose, light and
  dark modes, and a transform path to CSS custom properties, iOS and Android.
  Flag any value that cannot be expressed as a token, any component state that
  needs a token the draft lacks, and the font loading and subsetting plan (which
  weights ship, subset strategy, fallback metrics) against the web route budget
  `performance.bundle_kb` [value from `project.yaml`, or 'unset']." With design
  source values: "Also flag every Figma variable or Claude Design token that
  cannot map into the primitive → semantic → component tiers, and list each
  existing value the draft changed (name, source value, draft value)."
- **`accessibility-specialist`**: "Check this draft against the resolved
  accessibility target [line as printed]. Produce the contrast table for every
  foreground/background pair a component can produce, in every theme, with the
  measured ratio and the ratio the target requires (WCAG 2.2: 1.4.3 text, 1.4.11
  non-text and focus indicators); check the focus indicator (2.4.7, 2.4.11), the
  minimum target sizes (2.5.8 — 24 × 24 CSS px; 44 × 44 pt on iOS, 48 × 48 dp on
  Android), text scaling and reflow (1.4.4, 1.4.10), and that no state is
  conveyed by color alone (1.4.1). Where the target is unset, compute the ratios
  against `wcag-aa` as a working bar and mark every row
  `NOT CHECKED — accessibility.target unset`."

**Merge.** Fold both checks into the four blocks. Where a check contradicts the
draft — a brand color that fails contrast as button text, a type scale the font
budget cannot carry, a draft value that departs from the design source — show
both positions and let the user decide with
`AskUserQuestion` (for example `Darken the brand color for text use` /
`Keep it for large text and icons only` / `Discuss`). Never resolve a conflict
silently.

Then present **Section 2** to the user, approve it, and write it to the file
immediately; then section 3, section 4 and section 5 the same way. Do not present
all four at once — the batching is in the delegation, not in the review. After
each write update the verdict line (`PARTIAL — SECTIONS 1-<n>`).

If a check agent did not run or returned BLOCKED, its items in each affected
section are written as `NOT CHECKED — <agent> did not run: <reason>` and added to
the `> **Not Checked**:` line. A section with a not-checked item can be approved
and written, but the document cannot reach `COMPLETE` until it is resolved.

---

## Phase 4: Extended Sections (6–9)

Run this phase when the Phase 2 scope includes sections 6–9. Same pattern: one
`product-designer` draft, then `design-engineer` and `accessibility-specialist`
checks in parallel, then per-section approval and write.

**Draft** — spawn `product-designer` via `Agent` with sections 1–5 as written and
the surfaces. Ask for four labelled blocks:

1. **Iconography & Illustration** — "Icon grid, stroke and corner rules, sizes,
   filled vs outlined meaning, naming, the stance on SF Symbols and Material
   Symbols per surface; illustration style and where illustration is used
   (empty states, onboarding) and where it is not; imagery rules; app icon
   principles. Individual assets are not specified here — they go to
   `design/inventory/media-manifest.md` via `/ui-inventory media`."
2. **Motion & Feedback** — "Duration and easing tokens; what each animation
   becomes under reduced motion; a haptics table per event and surface (iOS
   feedback generators, Android haptic constants, none on the web); notification
   sound — system default or custom, for which notification types; how success,
   progress, waiting and errors feel (skeleton vs spinner, optimistic updates,
   how rare celebration moments are)."
3. **Platform Adaptation** — "For each configured surface: what follows the
   platform (web browser conventions; iOS Human Interface Guidelines — navigation
   bar, tab bar, sheets, swipe-back, Dynamic Type; Android Material 3 — top app
   bar, navigation bar, predictive back, edge-to-edge) and what is deliberately
   custom, with the build and maintenance cost of each divergence."
4. **Content & Voice** — "A pointer to `design/brand/voice-and-tone.md` [exists /
   not written yet] and UI copy rules only: button labels (verb first, specific),
   capitalization, error message structure (what happened, what to do), empty
   state copy, truncation, and formats for amounts (`12,000원` — KRW has no minor
   unit), dates and times per locale in `localization.locales`. Do not define
   voice attributes or tone — that is the voice-and-tone guide's job."

**Checks** — in parallel:
- **`design-engineer`**: motion tokens and their implementation per surface,
  haptics hooks, notification sound constraints (custom sound formats and
  lengths, Android notification channels fixing a sound once created), icon
  delivery (SVG components, SF Symbols, vector drawables).
- **`accessibility-specialist`**: reduced-motion coverage (2.3.3 as a design
  goal), no content flashing more than three times per second (2.3.1), sound and
  haptics never carrying information that is not also on screen, icons that act
  as controls having accessible names, copy rules that keep error messages
  specific (3.3.1, 3.3.3).

Merge, surface conflicts, then present and write sections 6, 7, 8 and 9 one at a
time, each after "May I write this to `design/brand/design-language.md`?".

Section 9 must stay a pointer plus UI copy rules. If the draft adds voice
attributes or tone rules, move them out and tell the user to take them to
`/team-content`, which owns `design/brand/voice-and-tone.md`.

---

## Phase 5: Tokens File (optional)

Offer this when sections 2–4 are complete (and 7 when present), or when the scope
is `Tokens only`. Use `AskUserQuestion`:
- `Generate design/brand/tokens.json from sections 2–4`
- `Reconcile with Figma variables` — offered only when the design source is
  `figma` and `design/handoff/design-system/HANDOFF.md` lists variables in its
  `## Tokens & Components` section; otherwise omitted, and when the source is
  `figma` without such a record, say why (the Phase 3 `NOT CHECKED` line)
- `Skip — tokens live in Figma variables or code`

**Reconcile.** Spawn `design-engineer` via `Agent` with sections 2, 3, 4 and 7 as
written and the record path (the values come from the record — the agent cannot
reach Figma). Ask for the drift between the document's tokens and the Figma
variables: tokens in the document missing from Figma, variables in Figma missing
from the document, and names present in both with a different value or mode.
Present the drift counts per family and each drifted token. The document wins: a
drift is fixed in Figma (or the document is revised first, section by section with
approval), never by adopting the Figma value silently. Then offer to generate
`tokens.json` as below. Pushing the document's tokens into Figma variables is an
external write: say that the user may do it through Figma's own skill (for
example `/figma-generate-library`, if the Figma plugin is present in the session),
proposed and explicitly approved at every automation mode — this skill never
writes to Figma.

**Generate.** Spawn `design-engineer` via `Agent` with sections 2, 3, 4 and 7 as written. Ask
for a single JSON document in the W3C Design Tokens Community Group format:
groups per token family, `$type` on every token or group, `$value`, aliases
(`{color.green.500}`) from semantic to primitive tokens, light and dark values
expressed the way the team's transformer consumes them, and a `$description` on
each semantic token. Ask it to confirm that the JSON parses and that every
semantic token named in the document exists in the file.

Present a summary (token counts per family, any token in the document missing
from the file, any token in the file missing from the document). Ask: "May I
write this to `design/brand/tokens.json`?" After writing, Read the file back and
confirm it is intact. The document stays the source of intent; the file is the
machine form of it. If they ever disagree, the document wins and the file is
regenerated. The same holds for Figma variables and a Claude Design design system:
they are reconciled to the document, never the reverse.

Record the token direction in the header's `> **Design Source**:` line (the
chosen option — `tokens.json` generated, reconciled with Figma variables on
[date], or tokens live in Figma variables or code), after "May I write this to
`design/brand/design-language.md`?".

When the design source is `claude-design` and the repo has a React component
library, say that the user may run the bundled `/design-sync` (with
`/design-login` in a session without a claude.ai login), if it is present in the
session, to push that component library to Claude Design so its designs use the
real components. It is an external write the user runs and approves; this skill
never runs it and it is not a next step.

---

## Phase 6: Design Director Sign-Off — DD-DESIGN-LANGUAGE

Run this after the scoped sections are written (all nine, or 1–5 at `standard`).
It does not run for the `Tokens only` scope — the tokens file restates sections
the gate has already seen.

**Review mode check** — apply before spawning DD-DESIGN-LANGUAGE:
- `solo` → skip. Note: `[DD-DESIGN-LANGUAGE] skipped — Solo mode`
- `lean` → **skip every gate whose ID does not end in `-PHASE-GATE`**. Note: `[GATE-ID] skipped — Lean mode`
  DD-DESIGN-LANGUAGE does not end in `-PHASE-GATE`, so it is skipped:
  `[DD-DESIGN-LANGUAGE] skipped — Lean mode`
- `full` → spawn as normal.

When skipped, write the note into the header's DD-DESIGN-LANGUAGE line (after
"May I write this to `design/brand/design-language.md`?"). `/gate-check` accepts
the note as evidence that the mode was applied and reports the item as not
checked rather than scoring it.

**When it runs**, spawn `design-director` via `Agent` — the design director, never
another director — with gate **DD-DESIGN-LANGUAGE**
(`.claude/docs/director-gates/dd-design-language.md`). The `Agent` prompt
instructs the agent to read that file first; do not read it or paste it into the
prompt.
Pass: `design/brand/design-language.md` path · resolved `accessibility` line · resolved `surfaces` line · brief path

Copy the two resolved lines exactly as the bootstrap block printed them (unset
forms included — unset is not `none`); when the user answered the surfaces
question in Phase 0, pass the printed line and the answer, marked as such.

Parse the first line of the reply as `[DD-DESIGN-LANGUAGE]: TOKEN` and map it with
`.claude/docs/director-gates.md` § Standard Verdict Format:
- **APPROVE** (APPROVE-class) → record
  `> **Design Director Review (DD-DESIGN-LANGUAGE)**: APPROVED [date]` and set
  `> **Status**: Approved`.
- **CONCERNS** (CONCERNS-class) → list each concern with its section. Use
  `AskUserQuestion`: `Revise flagged items` / `Accept and proceed` / `Discuss further`.
  Revising returns to the phase that owns the section, rewrites it with approval,
  then spawns the gate again; an APPROVE after a revision records
  `REVISED [date]`. Accepting records `CONCERNS (accepted) [date]` and
  `> **Status**: Approved`.
- **REJECT** (REJECT-class) → surface the blockers. Do not record a review line and
  keep `> **Status**: Draft` — the gate-build item stays unmet until a later run
  resolves them. Use `AskUserQuestion`: `Revise the blocking sections now` /
  `Stop here — resume later with the Resume scope`.
- A first line that does not parse, names another gate, or carries a token not on
  this gate's Verdicts line → not an approval: surface the full reply as
  CONCERNS-class and say that the verdict line was missing or invalid.

---

## Phase 7: Verdict and Close

Compute the verdict from the section status (Phase 0 table, updated by this run)
with the precedence PARTIAL > NOT ASSESSED > COMPLETE, and update the header block:
`> **Verdict**:`, `> **Last Updated**:`, `> **Sections Deferred**:`,
`> **Not Checked**:`. Ask once: "May I write this to
`design/brand/design-language.md`?" (the header only).

Report in the conversation:

```
Design language: design/brand/design-language.md
Verdict: [COMPLETE | PARTIAL — SECTIONS <n>-<m> | NOT ASSESSED]
Tier: [workflow] — requires [sections 1–5 | all nine | none]  →  [met | not met]
Not checked: [items with reasons, or "none"]
DD-BRAND-DIRECTION: [outcome or skip note]
DD-DESIGN-LANGUAGE: [outcome or skip note]
Tokens: [design/brand/tokens.json written | reconciled with Figma variables — <n> drifts | skipped]
Design source: [none | claude-design — record <path> (<verdict>) | figma — record <path> (<verdict>) | NOT CHECKED — <reason>]
Skipped specialists: [agent — reason, or "none"]
```

`PARTIAL — SECTIONS 1-5` at `standard` is the tier's requirement met — say so, so
the user does not read PARTIAL as a failure.

Before presenting next steps, check project state:
- Does `design/inventory/screen-inventory.md` exist? → `/ui-inventory` has run.
- Does `design/ux/app-shell.md` exist? → the app shell is specced.
- Does `design/ux/interaction-patterns.md` exist? → the pattern library exists.
- How many specs are in `design/ux/*.md` (excluding `app-shell.md` and
  `interaction-patterns.md`)? → key screens specced or not.
- Does `design/brand/voice-and-tone.md` exist? → `/team-content` has run.

Use `AskUserQuestion` for next steps. Include only the options that are genuinely
next:
- `[_] /ui-inventory — list the screens and components per surface the design language must cover` (skip if the screen inventory exists)
- `[_] /ux-design shell — specify the app shell on this design language` (skip if app-shell.md exists)
- `[_] /ux-design patterns — build the interaction pattern library` (skip if interaction-patterns.md exists)
- `[_] /ux-design [key screen] — spec the next key screen (sign-up, onboarding, the core flow, settings)`
- `[_] /ui-inventory media — specify icons, illustrations, store screenshots and OG images from sections 6–8` (include when section 6 is complete)
- `[_] /team-content voice — write the voice-and-tone guide section 9 points to` (skip if voice-and-tone.md exists)
- `[_] /design-handoff --for design-system — retain the Figma library or Claude Design design system the tokens reconcile against` (include only when the design source is `claude-design` or `figma` and `design/handoff/design-system/HANDOFF.md` is missing or `NOT ASSESSED`)
- `[_] /design-language — resume the remaining sections` (include when the verdict is PARTIAL beyond the tier's requirement or NOT ASSESSED)
- `[_] Stop here`

Assign letters A, B, C… only to the options actually included. Mark the most
logical pipeline-advancing option as `(Recommended)`. Always include `Stop here`.

---

## Error Recovery

If a spawned agent returns BLOCKED, errors, or cannot complete:
1. Surface it immediately: "[agent]: BLOCKED — [reason]".
2. A drafting agent (product-designer) blocked → the section cannot be drafted by
   this skill; offer `Retry` / `Describe the section content myself — the
   specialist checks still run` / `Stop here`.
3. A checking agent blocked → write its items as `NOT CHECKED — <agent> did not
   run: <reason>`; the verdict cannot be `COMPLETE`.
4. Never discard approved work because one agent blocked — sections already written
   stay written.

---

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and `autonomous`
modes, see `.claude/docs/automation-modes.md` — the rules below describe what
collaborative mode requires, not universal behaviour.

Every section follows: **Question → Options → Decision → Draft (from the
specialist) → Checks → Approval → Write to file**

- Never draft a section yourself — every section's content comes from a
  specialist. One delegation may cover several sections (2–5 share a draft, as do
  6–9), but no section may be written from the orchestrator's own judgement.
- Write each section to the file immediately after approval — do not batch the
  writes or the approvals. Batching applies only to the delegation call; the user
  still sees, approves and commits one section at a time.
- Ask "May I write this to `<path>`?" before every write to
  `design/brand/design-language.md` and `design/brand/tokens.json`. Specialists
  never write under `design/` themselves — the orchestrator writes after approval.
- Writes to Figma and uploads to Claude Design are external writes: always
  proposed and explicitly approved, at every automation mode, and done by the
  user-run Figma skill or bundled `/design-sync` — never by this skill.
- Surface every disagreement between product-designer, design-engineer and
  accessibility-specialist to the user — never resolve one silently.
- Announce every skip in the output and in the document: a skipped gate, a
  specialist that did not run, a check that could not be made.
- The design language is a constraint document: it narrows future decisions in
  exchange for coherence across web, iOS and Android. Every section should make
  the solution space smaller in a way a design engineer can build.

---

## Recommended Next Steps

After the design language is approved:
- Run `/ui-inventory` to list the screens and shared components per surface, and
  `/ui-inventory media` for icons, illustrations, store screenshots and OG images.
- Run `/ux-design shell` and `/ux-design patterns` so the app shell and the
  pattern library use the tokens and components defined here.
- Run `/ux-design [screen]` for each key screen, then `/ux-review` on each spec.
- Run `/team-content voice` for the voice-and-tone guide that section 9 points to.
- Run `/team-ui` to take specced screens through implementation on the component
  library.
