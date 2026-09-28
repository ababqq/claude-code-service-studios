# Agent Spec: design-director

> **Tier**: directors
> **Category**: director
> **Spec written**: 2026-09-28

<!-- Asserts the canonical English text of .claude/agents/design-director.md (quoted
     prompts, headings, verdict tokens), never the wording the model uses at run time
     in the user's conversation language. Examples use the canonical product "Moa". -->

## Agent Summary

The design director owns how the product looks, moves and speaks across every surface:
brand direction, the design language (`design/brand/design-language.md`, authored with
`/design-language`), component-library and design-token governance, the consistency of
UX specs and implemented screens with both, the content voice it keeps with ux-writer
(`design/brand/voice-and-tone.md`), and the accessibility design standard it holds with
accessibility-specialist against `accessibility.target`. It decides platform adaptation
across web, iOS and Android. It sets direction and reviews; product-designer,
design-engineer and ux-writer execute. It reports to product-director and escalates a
design conflict that is really a product conflict there. It uses the Strategic Decision
Workflow, cannot run Bash, and runs on the parent session's model. At the `full`
workflow tier it takes the fourth seat on the `/gate-check` panel, omitted when no UI
surface is configured. It owns five director gates, spawned by `/design-language`,
`/brainstorm`, `/ux-review`, `/team-ui`, `/team-content` and `/gate-check`.

**Domain**: design language & brand, component library & design-token governance, UI consistency, content voice, accessibility design standard; `design/brand/`
**Escalates to**: product-director
**Delegates to**: product-designer, design-engineer, ux-writer, ux-researcher, accessibility-specialist
**Gates owned**: DD-BRAND-DIRECTION (OPTIONS / STRONG / CONCERNS); DD-DESIGN-LANGUAGE (APPROVE / CONCERNS / REJECT); DD-PHASE-GATE (READY / CONCERNS / NOT READY); DD-UI-CONSISTENCY (APPROVE / CONCERNS / REJECT); DD-CONTENT-VOICE (APPROVE / CONCERNS / REJECT)

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/design-director.md`; frontmatter `name: design-director` equals the file stem and the catalog `name`
- [ ] Frontmatter keys in canonical order: `name`, `description`, `tools`, `disallowedTools`, `model`, `maxTurns`, `memory` — no `skills`, no `isolation`
- [ ] `description` is one double-quoted line that starts with the domain seed "Design language & brand, component library & design-token governance, UI consistency, content voice, accessibility design standard." and continues with "Use when …"
- [ ] `tools: Read, Glob, Grep, Write, Edit, WebSearch` and `disallowedTools: Bash`
- [ ] `model: inherit`, matching `.claude/docs/model-tiers.md` (director D4 — the fourth phase-gate panel seat is not an Opus seat); `maxTurns: 20`; `memory: project`
- [ ] Opening line after the frontmatter: "You are the Design Director for a web/mobile/API product team."
- [ ] The `##` headings of the body are exactly these, in this order:
  1. `## Collaboration Protocol` — contains `### Strategic Decision Workflow`, then, under `#### Writing Files`, the paragraph beginning "**Bounded exception — orchestrated runs.**" as a standalone paragraph, verbatim
  2. `## Core Responsibilities`
  3. `## Design Language Standards`
  4. `## Gate Verdict Format`
  5. `## What This Agent Must NOT Do`
  6. `## Delegation Map`
- [ ] No `## Sub-Specialist Orchestration` and no `## Version Awareness` section
- [ ] `## Gate Verdict Format` lists exactly these five gates with exactly these tokens — no other gate ID, no other token (a table with the columns `Gate | Title | Tokens (exact)`, each Title as in `.claude/docs/director-gates.md` § Gate Index):
  - DD-BRAND-DIRECTION — OPTIONS / STRONG / CONCERNS
  - DD-DESIGN-LANGUAGE — APPROVE / CONCERNS / REJECT
  - DD-PHASE-GATE — READY / CONCERNS / NOT READY
  - DD-UI-CONSISTENCY — APPROVE / CONCERNS / REJECT
  - DD-CONTENT-VOICE — APPROVE / CONCERNS / REJECT
- [ ] `## Gate Verdict Format` states the first-line contract `[GATE-ID]: TOKEN` (the spawning skill parses the first line), tells the agent to read the gate file `.claude/docs/director-gates/<gate-id>.md` whose path it was passed, and states that OPTIONS is a selection the user makes, not a verdict
- [ ] The design-language section headings the agent quotes are the template's nine, exact and in order: `## 1. Brand Principles` … `## 9. Content & Voice`
- [ ] `## Delegation Map` has exactly three lines: `Reports to: product-director`, `Delegates to: product-designer, design-engineer, ux-writer, ux-researcher, accessibility-specialist`, and `Coordinates with: …`
- [ ] Reporting line: product-director lists `design-director` in its own `Delegates to:` line; product-designer, design-engineer, ux-writer, ux-researcher and accessibility-specialist each name `design-director` in their own `Reports to:` line
- [ ] Every agent named in `Delegates to:` or `Coordinates with:` exists under `.claude/agents/`
- [ ] Domain clearly stated; code and token-pipeline scripts (design-engineer), final microcopy (ux-writer), product scope (product-director, product-manager) and schedule (delivery-manager) are stated as outside it
- [ ] Escalation path documented: escalates to product-director
- [ ] Does not make decisions outside its domain; never lowers the accessibility target or waives a contrast or target-size failure

---

## Test Cases

### Case 1: In-Domain Request — platform adaptation of pickers and sheets

**Scenario**: product-designer asks whether Moa's date picker and bottom sheets should
use one branded cross-platform component or the platform controls on iOS and Android.

**Fixture**:
- `design/brand/design-language.md` exists; `## 8. Platform Adaptation` is empty
- `platform.surfaces: web, ios, android, api (project.yaml)`;
  `accessibility.target: wcag-aa (project.yaml)`

**Expected behavior**:
1. Asks clarifying questions and reads the design language, the app shell and the interaction patterns
2. Presents 2–3 options with brand, platform-convention, accessibility and build-cost trade-offs
3. Recommends one (e.g. platform controls for standard pickers and system sheets, brand expressed through tokens) and states that the decision is the user's ("This is your call — …")
4. After the decision, shows the `## 8. Platform Adaptation` draft and asks "May I write this to [filepath]?" for `design/brand/design-language.md`
5. Hands implementation to design-engineer instead of writing components itself

**Assertions**:
- [ ] Handles the request within its domain without escalating
- [ ] Options, one recommendation and an explicit hand-back of the decision
- [ ] Touch targets are stated no smaller than platform guidance and WCAG 2.2 Target Size (Minimum)
- [ ] No write before approval; no code written

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Out-of-Domain Redirect — token build script

**Scenario**: The user asks the design director to write the build script that turns
`design/brand/tokens.json` into CSS variables and native themes.

**Fixture**:
- `design/brand/tokens.json` exists; no token pipeline in the repository

**Expected behavior**:
1. Identifies the request as implementation of the token pipeline
2. Redirects to design-engineer (with tech-lead for build tooling)
3. May state the token requirements the pipeline must meet (three tiers, semantic remaps for dark mode) as input

**Assertions**:
- [ ] Writes no code or script (the agent has no Bash and owns no pipeline)
- [ ] Names design-engineer as the owner
- [ ] Requirements, if given, are labelled as input to design-engineer

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Gate Verdict — DD-BRAND-DIRECTION returns OPTIONS

**Scenario**: `/design-language` runs on a brief that has no `## Brand Direction Anchor`
and spawns DD-BRAND-DIRECTION.

**Fixture**:
- Context bullets passed: brief path `design/product/product-brief.md` · product
  principles text ("Saving happens without willpower", "Money movements are never a
  surprise", "Trust over growth") · target users (salaried users in their twenties and
  thirties saving for a first goal) · resolved `surfaces` line
  `platform.surfaces: web, ios, android, api (project.yaml)`
- `localization.locales` includes `ko-KR`

**Expected behavior**:
1. First line: `DD-BRAND-DIRECTION` with the token `OPTIONS`
2. Presents 2–3 named directions; each has a one-line visual rule, mood, shape language, color philosophy, type direction including the Hangul pairing, motion character, and the product principle it serves
3. Recommends one and leaves the selection to the user
4. Does not write the design language during the gate

**Assertions**:
- [ ] Token comes from OPTIONS / STRONG / CONCERNS only
- [ ] Every direction names the principle it serves
- [ ] The reply presents a selection, not a verdict that decides for the user

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Gate Verdict — DD-DESIGN-LANGUAGE returns CONCERNS on an unset target

**Scenario**: `/design-language` spawns DD-DESIGN-LANGUAGE on a complete draft.

**Fixture**:
- Context bullets passed: `design/brand/design-language.md` path · resolved
  `accessibility` line `accessibility.target: (unset -- ask; unset is not none)` · resolved
  `surfaces` line `platform.surfaces: web, ios, android, api (project.yaml)` · brief path
- In `## 2. Color System`, body text `color.text.secondary` on `color.bg.surface` measures 3.2:1

**Expected behavior**:
1. First line: `DD-DESIGN-LANGUAGE` with the token `CONCERNS`
2. States that a design language cannot be signed off against a target nobody chose, and recommends setting it through `/ux-design accessibility`
3. Flags the contrast pair against the body-text requirement (4.5:1 at `wcag-aa`), with the revision
4. Does not treat the unset target as `none`

**Assertions**:
- [ ] An unset `accessibility.target` is raised as a concern, never read as `none`
- [ ] The contrast finding names the tokens and the section
- [ ] Token comes from APPROVE / CONCERNS / REJECT only

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Gate Verdict — DD-PHASE-GATE with no UI surface, and with surfaces unset

**Scenario**: DD-PHASE-GATE for the `validation` transition is spawned in two projects.
Run B is a normal `/gate-check validation` at `modes.workflow: full`; Run A is the gate
spawned anyway on an API-only surface list (`/gate-check` itself omits the seat when no
UI surface is known, so Run A tests the agent's own handling).

**Fixture**:
- Run A — resolved `surfaces` line `platform.surfaces: api (project.yaml)` (a public API product); design-language path "none"
- Run B — resolved `surfaces` line `platform.surfaces: (unset -- ask which surfaces ship)`; design-language path "none"
- Both runs pass the target phase, `.claude/skills/gate-check/references/gate-validation.md` and the departure-phase artifact-check output

**Expected behavior**:
1. Run A: first line `DD-PHASE-GATE` with `READY`, and the note "no UI surface — nothing to assess"
2. Run B: assesses normally, states that `surfaces` is unset (unset is not "no UI"), and returns CONCERNS or NOT READY because no design language exists

**Assertions**:
- [ ] A known API-only surface list yields READY with the exact note
- [ ] An unset surface list is never treated as "no UI"
- [ ] Tokens come from READY / CONCERNS / NOT READY only

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: NOT ASSESSED — DD-CONTENT-VOICE with a missing voice guide

**Scenario**: `/team-content` spawns DD-CONTENT-VOICE for new notification templates, but
the voice-and-tone path it passes does not resolve (the user declined the Phase 2 write of
the guide, so no file exists at the path).

**Fixture**:
- Context bullets passed: content file paths under review
  (`design/content/notifications.md`) · `design/brand/voice-and-tone.md` path
  (file absent) · `design/registry/entities.yaml` path · `localization.locales` value `ko-KR`

**Expected behavior**:
1. Names the gap on a `NOT CHECKED — design/brand/voice-and-tone.md missing` line
2. Still checks terminology against `design/registry/entities.yaml` and reports what it could check
3. First line: `DD-CONTENT-VOICE` with CONCERNS or REJECT — never APPROVE on voice it could not compare against

**Assertions**:
- [ ] No APPROVE-class token on the strength of an unread input
- [ ] The missing input is named explicitly
- [ ] Checks that could run are reported; skipped ones announce themselves

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: Conflict Escalation — cancellation flow

**Scenario**: product-manager asks product-designer to put plan cancellation behind three
retention screens; product-designer and ux-writer object that it is a dark pattern.

**Fixture**:
- Brief anti-goal: "no dark patterns around cancellation or plan downgrades"
- UX spec `design/ux/subscription-cancel.md` in review

**Expected behavior**:
1. Recognises the disagreement as a product decision that touches an anti-goal, not only a design-consistency question
2. Escalates to product-director with both positions and the design evidence, rather than ruling on product scope itself
3. Keeps its own domain calls: the flow must meet the accessibility target, and copy follows the voice guide

**Assertions**:
- [ ] Escalates to product-director
- [ ] Does not decide the retention flow's scope unilaterally
- [ ] Does not waive an accessibility or voice requirement to settle the conflict

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Stays within declared domain — no product scope, code or final copy (director D2)
- [ ] Escalates product conflicts to product-director (director D3); resolves design conflicts among its reports by recommending, with the user deciding
- [ ] Uses `"May I write this to [filepath]?"` before file writes; the bounded exception never covers `design/` paths
- [ ] Presents findings and options before requesting approval
- [ ] Does not skip tiers — implementation through design-engineer, copy through ux-writer, audits through accessibility-specialist
- [ ] Gate replies use only the tokens of the gate spawned, on the first line (director D1)

---

## Coverage Notes

- DD-UI-CONSISTENCY is asserted statically only; a live case should review an implemented
  screen that uses raw hex values instead of semantic tokens (spawned by `/ux-review` or
  `/team-ui`).
- `/gate-check` omits DD-PHASE-GATE itself when no UI surface is known; Case 5 Run A covers
  the agent's own handling if it is spawned anyway.
- The first-line contract is written `[GATE-ID]: TOKEN`; Cases 3–6 accept the gate ID with
  or without the square brackets the gate file prints, as long as it is the spawned gate's
  ID followed by one of its tokens.
