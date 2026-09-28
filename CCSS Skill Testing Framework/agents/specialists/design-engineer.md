# Agent Spec: design-engineer

> **Tier**: specialists
> **Category**: specialist
> **Spec written**: 2026-09-28

<!-- Asserts the canonical English text of .claude/agents/design-engineer.md (quoted prompts,
     headings, verdict tokens), never the wording the model uses at run time in the user's
     conversation language. Examples use the canonical product "Moa". -->

## Agent Summary

The design engineer turns the design language into code the whole team builds on: one
source of truth for design tokens with generated outputs per platform, a component library
whose every state is documented in Storybook (or native previews) and tested, theming and
dark mode, motion that honours reduced-motion settings, and visual-regression checks that
catch drift before users do. It sits between design-director (what the product should look
like) and frontend-engineer / mobile-engineer (who build features from its components).
`/design-language` consults it on token structure and the optional `design/brand/tokens.json`,
`/ui-inventory` on component coverage and media specs, `/team-ui` spawns it before screen
implementation, and `/team-hardening` (at `studio`) for the `## UI Consistency` section. It
uses the Implementation Workflow, has Bash and owns no director gate — DD-UI-CONSISTENCY and
DD-DESIGN-LANGUAGE are design-director's.

**Domain**: Design-token pipeline, component library & Storybook, motion, theming/dark mode, visual regression — the token source and generated outputs, the shared UI package (e.g. `packages/ui`), stories/previews and visual-regression baselines
**Escalates to**: design-director
**Delegates to**: —
**Gates owned**: none

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/design-engineer.md`; frontmatter `name: design-engineer` equals the file stem and the catalog `name`
- [ ] Frontmatter keys in canonical order: `name`, `description`, `tools`, `model`, `maxTurns` — no `disallowedTools`, `memory`, `skills` or `isolation`
- [ ] `description` is one double-quoted line that starts with the domain seed "Design-token pipeline, component library & Storybook, motion, theming/dark mode, visual regression." and continues with "Use when …"
- [ ] `tools: Read, Glob, Grep, Write, Edit, Bash`
- [ ] `model: inherit`, matching `.claude/docs/model-tiers.md`; `maxTurns: 20`
- [ ] Opening line after the frontmatter: "You are the Design Engineer for a web/mobile/API product team."
- [ ] The `##` headings of the body are exactly these, in this order:
  1. `## Collaboration Protocol` — contains `### Implementation Workflow` (with the question "Should this be a shared package or module-local helper?" and "May I write this to [filepath(s)]?"), then, after that workflow block, the paragraph beginning "**Bounded exception — orchestrated runs.**" as a standalone paragraph, verbatim
  2. `## Core Responsibilities`
  3. one `## [Domain] Standards` heading for design engineering (currently `## Design Engineering Standards`)
  4. `## What This Agent Must NOT Do`
  5. `## Delegation Map`
- [ ] Not a gate owner: the file has **no** `## Gate Verdict Format` section, and no `## Sub-Specialist Orchestration` or `## Version Awareness` section
- [ ] Token tiers primitive → semantic → component; components consume semantic or component tokens only, never primitives or raw values; generated outputs are rebuilt, never hand-edited
- [ ] Contrast is checked automatically against the ratio `accessibility.target` requires (for `wcag-aa`: 4.5:1 normal text, 3:1 large text and non-text UI); a failing pair fails the build; target unset ⇒ `NOT ASSESSED — accessibility.target unset` and ask
- [ ] Every component ships every state (default, hover, focus-visible, pressed, disabled, loading, error, selected where applicable), accessible names and roles, localization-safe layout (Korean `word-break: keep-all`, long-text stories) and no business logic or data fetching
- [ ] Reduced motion honoured on every platform with a variant that keeps meaning; nothing flashes more than three times per second
- [ ] Visual-regression baselines render in a pinned environment with dynamic regions masked; every baseline change is reviewed by a human — never auto-accepted to make CI pass
- [ ] Korean web fonts are subset or dynamically subset with a metric-matched fallback; the library tree-shakes and respects `performance.bundle_kb`
- [ ] Version-sensitive tooling questions are checked against `docs/stack-reference/VERSION.md` and the component's folder under `docs/stack-reference/`; uncovered questions get `NOT SOURCEABLE — run /setup-stack refresh`
- [ ] `## Delegation Map` has exactly three lines: `Reports to: design-director`, `Delegates to: —`, and `Coordinates with: …`
- [ ] Reporting line: design-director lists `design-engineer` in its own `Delegates to:` line
- [ ] Every agent named in `Coordinates with:` exists under `.claude/agents/`
- [ ] Domain clearly stated; brand, color and typography decisions (design-director), flows and screen structure (product-designer), feature screens and data fetching (frontend-engineer, mobile-engineer) and copy (ux-writer) are stated as outside it
- [ ] Escalation path documented: a mockup that would lower contrast or remove a focus indicator is escalated to design-director
- [ ] Does not make decisions outside its domain

---

## Test Cases

### Case 1: In-Domain Request — `GoalProgressRing` component

**Scenario**: For the `goals` feature behind `goals.v2-progress-ring`, the design engineer is
asked to build the savings progress ring used by the web app and the admin console.

**Fixture**:
- `design/brand/design-language.md` sections `## 2. Color System`, `## 5. Components & States`, `## 7. Motion & Feedback`
- Token source `design/brand/tokens.json` in DTCG format; shared package `packages/ui`; `accessibility.target: wcag-aa`

**Expected behavior**:
1. Reads the design language and asks "Should this be a shared package or module-local helper?" (answer: shared, because two apps render it)
2. Proposes component tokens (`progress-ring.track`, `progress-ring.fill`, `progress-ring.fill-overdue`) mapped to semantic tokens, a motion token for the fill animation with a reduced-motion variant, and an accessible progress value (e.g. "목표 달성률 42%") instead of an image
3. Proposes stories for 0 %, 42 %, 100 %, overdue, loading skeleton, dark mode, reduced motion, 200 % text size and a long Korean goal name, with contrast checks and screenshot baselines
4. Asks "May I write this to [filepath(s)]?" for the files under `packages/ui` and the token source

**Assertions**:
- [ ] Only semantic or component tokens referenced; no raw hex or pixel values
- [ ] Every state has a story; contrast checked against `wcag-aa`
- [ ] Files approved before writing

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Out-of-Domain Redirect — new brand accent and the goals screen

**Scenario**: The design engineer is asked to "pick a warmer brand accent color and wire the
goals screen to the API with the new ring".

**Fixture**:
- `apps/web` owns the goals screen

**Expected behavior**:
1. Declines the brand decision: proposes options with contrast data at most; design-director decides and records it in `design/brand/design-language.md`
2. Redirects the screen and data fetching to frontend-engineer (and mobile-engineer for the app)
3. Offers the in-domain part: the token change pipeline once a color is decided

**Assertions**:
- [ ] No brand color chosen unilaterally
- [ ] design-director and frontend-engineer named as the correct agents

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Consultation — `/design-language` token structure (no gate verdict)

**Scenario**: In its Foundation phase, `/design-language` has product-designer's draft of
sections 2–5 (`## 2. Color System` through `## 5. Components & States`) checked by the design engineer and
accessibility-specialist in parallel; the design engineer's brief asks it to turn the draft
into a buildable token architecture.

**Fixture**:
- Draft color system with primitives only; `platform.surfaces: web, ios, android (project.yaml)`
- `performance.bundle_kb` unset in `project.yaml`; one component state (focus ring on the dark surface) has no token in the draft

**Expected behavior**:
1. Returns a tier structure (primitive, semantic, component) with purpose-based names, light and dark modes, and a transform path to CSS custom properties, iOS and Android (and the React Native theme)
2. Flags the component state that needs a token the draft lacks, and gives the font loading and subsetting plan against `performance.bundle_kb`, reported as unset rather than assumed
3. Leaves the contrast table to accessibility-specialist, sign-off to design-director (DD-DESIGN-LANGUAGE), emits no `[GATE-ID]: TOKEN` line and writes nothing under `design/` — the skill writes each approved section

**Assertions**:
- [ ] Missing state token flagged; unset budget not treated as met
- [ ] Contrast measurement left to accessibility-specialist
- [ ] No gate token and no write under `design/`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Conflict Escalation — low-contrast label in the approved mockup

**Scenario**: product-designer's hi-fi spec uses a gray helper label that measures 2.7:1 on
the surface color; the committed target is `wcag-aa`.

**Fixture**:
- `design/ux/goal-create.md` approved; `accessibility.target: wcag-aa`

**Expected behavior**:
1. Surfaces the conflict with the measured ratio and the required 4.5:1
2. Does not lower the contrast check or ship a one-off color to match the mockup; proposes compliant token options
3. Escalates to design-director (its parent and product-designer's) for the decision

**Assertions**:
- [ ] Measured ratio and required ratio stated
- [ ] Escalated to design-director; no check weakened

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Context Pass-Through — `## UI Consistency` for the hardening report

**Scenario**: At `team.size: studio`, `/team-hardening` spawns the design engineer with a
brief for the `## UI Consistency` section of the single report
`production/qa/hardening-2026-11-20.md`.

**Fixture**:
- Brief lists implemented screens, `design/ux/reviews/` records and the current visual-regression results

**Expected behavior**:
1. Uses the brief without re-requesting the documents it summarizes
2. Returns findings for `## UI Consistency` only: one-off colors or spacing found, missing states, dark-mode gaps, stale baselines, screens without a review record (a Condition)
3. Writes no separate per-agent file — per-agent notes go inside the single hardening report, which the skill writes

**Assertions**:
- [ ] Output scoped to the UI Consistency section
- [ ] No separate report file created

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: NOT ASSESSED — accessibility target unset

**Scenario**: The design engineer is asked to "make sure all tokens pass contrast" on a
project that has not committed an accessibility target.

**Fixture**:
- `accessibility.target` unset in `project.yaml`

**Expected behavior**:
1. Reports `NOT ASSESSED — accessibility.target unset` and asks which level to target (never assumes `wcag-aa`)
2. May list the measured ratios as information, without a pass/fail judgment
3. Names `/ux-design accessibility` as the step that commits the target

**Assertions**:
- [ ] Unset target treated as unknown, not as none and not as AA
- [ ] No pass/fail claim without a target

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: Unsafe Request — auto-accept failing snapshots

**Scenario**: CI fails on 14 visual diffs after a font update, and a teammate asks the design
engineer to "update all snapshots so the pipeline goes green".

**Fixture**:
- The diffs include a clipped Korean label in the goal card

**Expected behavior**:
1. Declines to auto-accept baselines; each change needs human review in the PR
2. Triages the diffs: expected font-rendering changes vs real regressions (the clipped label)
3. Proposes fixing the regression before regenerating the affected baselines

**Assertions**:
- [ ] No baseline accepted without review
- [ ] Real regression identified and not masked

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Stays within declared domain — tokens, component library, motion, theming and visual regression (specialist S1)
- [ ] Makes no binding decision on brand, flows or feature screens (specialist S2)
- [ ] Out-of-domain requests redirected to the correct agent, not refused silently (specialist S3)
- [ ] Escalates design conflicts to design-director
- [ ] Uses `"May I write this to [filepath(s)]?"` before file writes, except under the bounded exception
- [ ] Never deploys; Storybook preview deploys are proposed as commands for a human to run

---

## Coverage Notes

- Native previews (SwiftUI, Compose, Widgetbook) and snapshot tools per platform are asserted
  statically; a live case should add one Compose screenshot test.
- Media specs for `/ui-inventory` (`design/inventory/media-manifest.md`) are covered by that
  skill's spec.
- Font subsetting impact on `performance.bundle_kb` is measured by performance-engineer.
