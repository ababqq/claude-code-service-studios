---
name: ux-design
description: "Section-by-section UX spec for a screen or flow; modes shell, patterns, accessibility, journey."
argument-hint: "[screen/flow name] | shell | patterns | accessibility | journey"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, Agent, Bash(bash "*/.claude/skills/ux-design/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow,docs.density,stack,surfaces,accessibility,compliance`

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

# UX Design

This skill authors the UX layer of a web and mobile product, section by section:
screen and flow specs, the app shell, the interaction pattern library, the
project-wide accessibility requirements and the user journey map. Specs are what
engineers build from and what the API contract is reconciled against, so each one
must say what happens when the network drops, the list is empty or the session
expires.

**Authoring guidance**: the skeletons below mirror their templates — author from
them directly. When a section needs depth (worked examples, pattern catalogs,
accessibility criteria), the matching guide has it:

| Producing | Template | Guide |
|---|---|---|
| Screen spec | `.claude/docs/templates/ux-spec.md` | `.claude/docs/templates/guidance/ux-spec-guide.md` |
| Flow spec | `.claude/docs/templates/user-flow.md` | — (section guidance in `references/sections-ux-spec.md`) |
| App shell | `.claude/docs/templates/app-shell.md` | `.claude/docs/templates/guidance/app-shell-guide.md` |
| Interaction patterns | `.claude/docs/templates/interaction-pattern-library.md` | `.claude/docs/templates/guidance/interaction-pattern-library-guide.md` (routes to three topic files) |
| Accessibility requirements | `.claude/docs/templates/accessibility-requirements.md` | `.claude/docs/templates/guidance/accessibility-requirements-guide.md` |
| User journey | `.claude/docs/templates/user-journey.md` | — (section guidance in Section 4 below) |

**Load a guide per-section, never whole** — each is organised by section and the
pointers in the templates name the section to read.

**`workflow`** (see `.claude/docs/workflow-modes.md`) — which specs are required
when the product has a UI surface:
- `full` — a UX spec for every screen that gets implemented (the Build → Hardening
  gate checks it), plus the app shell, the pattern library and the accessibility
  requirements.
- `standard` — the key screens the Validation → Build gate names (sign-up/sign-in,
  onboarding, the core flow, settings/account), plus the app shell, the pattern
  library and the accessibility requirements; a spec for every other screen is
  recommended.
- `minimal` — not required. Can still be run voluntarily.

The user journey map is optional at every tier.

**`docs.density`** — it controls per-section *depth*, where `workflow`
controls which screens are specced. `modes.rigor` sets both together; set
`docs.density` explicitly to vary depth alone: `terse` = wireframe descriptions +
interaction bullets; `balanced` = wireframes + paragraph descriptions of flows;
`thorough` = full prose including user-research summaries and alternative flow
considerations. Apply it to every section you author.

**`surfaces`** — the resolved `platform.surfaces` line decides which breakpoints and
input methods every spec covers (Phase 2h). **`accessibility`** — the committed
`accessibility.target` every spec is measured against; `accessibility` mode is the
only writer. **`compliance`** — the regions whose accessibility standards and
consent rules apply (`accessibility` mode, and consent notes in shell and flow
specs). **`stack`** — the web and mobile frameworks, for the pattern library's
`UI Frameworks` line; a layer under `unset=` leaves it `To be designed`. Unset
values are asked, never assumed: unset is not "none".

Keys with no `resolve_config` label — `localization.locales`, `naming.events`,
`performance.*` — are read from `project.yaml` with Read when a section needs them.

## Outputs

| Mode | Writes |
|---|---|
| `[screen/flow name]` | `design/ux/<slug>.md` |
| `shell` | `design/ux/app-shell.md` |
| `patterns` | `design/ux/interaction-patterns.md` |
| `accessibility` | `design/accessibility-requirements.md` and `accessibility.target` in `project.yaml` |
| `journey` | `design/product/user-journey.md` |

Every write is preceded by "May I write this to `<path>`?".

## 1. Parse Arguments & Determine Mode

**First, the UI check.** If the resolved `surfaces` line lists no `web`, `ios` or
`android` (an API-only product), stop with:
> `NOT ASSESSED — no UI surface configured (platform.surfaces has no web, ios or android)`

— except in `journey` mode, which runs for API products too (activation is the
first successful API call). If the product does have a UI, the fix is to record it
with `/setup-stack`. An unset `surfaces` line is not "no UI": continue and ask in
Phase 2h.

Five authoring modes exist based on the argument:

| Argument | Mode | Template | Output file |
|----------|------|----------|-------------|
| `shell` | App shell | `app-shell.md` | `design/ux/app-shell.md` |
| `patterns` | Interaction pattern library | `interaction-pattern-library.md` | `design/ux/interaction-patterns.md` |
| `accessibility` | Project-wide accessibility requirements | `accessibility-requirements.md` | `design/accessibility-requirements.md` + `accessibility.target` in `project.yaml` |
| `journey` | User journey map | `user-journey.md` | `design/product/user-journey.md` |
| Any other value (e.g., `sign-in`, `goal-detail`, `goal-create`) | UX spec for one screen, or for a multi-screen flow | `ux-spec.md` (screen) or `user-flow.md` (flow) | `design/ux/<slug>.md` |
| No argument | Ask the user | — | (see below) |

> **`accessibility` and `journey` are the only modes that write outside
> `design/ux/`.** Their outputs are project-wide documents the per-screen specs
> consult, not specs for one screen. `.claude/docs/workflow-catalog.yaml`, the
> Architecture → Validation gate and `/ux-review` check
> `design/accessibility-requirements.md` at that exact path, and the catalog checks
> `design/product/user-journey.md` at that exact path. Do not "tidy" either under
> `design/ux/`: the catalog counts `design/ux/*.md` as UX specs (at least three are
> required), so a project-wide document there would be miscounted as a key-screen
> spec, and the checks at the real paths would stop matching.

`app-shell` and `interaction-patterns` are reserved slugs — an argument of
`app-shell` means `shell` mode. `reviews` is not a valid slug (that directory holds
`/ux-review` records).

**Screen or flow?** If the name describes a multi-screen task (sign-up, checkout,
goal creation) ask, with `AskUserQuestion`:
- "Is `<name>` one screen or a multi-screen flow?"
  - Options: "One screen (ux-spec.md)", "A flow (user-flow.md) — I'll spec its key screens after", "A flow, and spec its screens now one by one"

**If no argument is provided**, do not fail — ask instead. Use `AskUserQuestion`:
- "What are we designing today?"
  - Options: "A specific screen or flow (I'll name it)", "The app shell", "The interaction pattern library", "Accessibility requirements or the user journey map (I'll say which)"

If the user names a screen or flow, normalize it to kebab-case for the filename
(e.g., "Goal Detail" becomes `goal-detail`).

---

## 2. Gather Context (Read Phase)

Read all relevant context **before** asking the user anything. The skill's value
comes from arriving informed.

### 2a: Required Reads

- **Product brief**: Read `design/product/product-brief.md` (standard/full) or
  `design/product/one-pager.md` (minimal) — target users and jobs-to-be-done, product
  principles, MVP scope. If neither exists, warn:
  > "No product brief found. Run `/brainstorm` first to establish the product's
  > foundation before designing UX."
  > Continue anyway if the user asks.
- **Feature map**: `design/product/feature-map.md` if it exists — the feature slugs
  specs and matrices refer to.

### 2b: User Journey

Read `design/product/user-journey.md` if it exists. For each relevant stage, extract:
- Which lifecycle stage(s) does this screen appear in?
- What is the user's state of mind on arrival?
- What user need is this screen serving in the journey?
- Which moments of value (from the journey map) does this screen deliver?

If the journey map does not exist (and this is not `journey` mode), note the gap and
proceed:
> "No user journey map found at `design/product/user-journey.md`. Designing without
> it means we'll be making assumptions about the user's context. Run
> `/ux-design journey` after this spec is drafted."

Also add to the spec's Open Questions:
> "User journey map not yet created — run `/ux-design journey` to establish the
> user's context for this screen."

### 2c: PRD UI Requirements

Glob `design/prd/*.md` and grep for `UI Requirements` sections. Read any PRD whose
`## UI Requirements` section references this screen by name or area, and its
`## Non-Functional Requirements` (accessibility, localization, performance) and
`## API & Data Impact` sections.

These PRD UI Requirements are the **requirements input** to this spec. Collect them
as a list of constraints the spec must satisfy. At `minimal` there are usually no
PRDs — use the one-pager's `## Core User Journey` and `## Scope & Non-Goals` instead.

If designing the app shell, you need the UI Requirements of **every** PRD — the shell
aggregates the global elements they ask for. Collect them with one scan rather than
opening each PRD:

```
Grep pattern="^#+ .*UI Requirements" glob="design/prd/*.md" output_mode="content" -A 20
```

Establish the denominator first (glob `design/prd/*.md`, count **N**) and check the
match count against it. **A PRD with no UI Requirements section is not a PRD with no
UI needs** — the section is optional in the template and may simply be unwritten.
List the unmatched PRDs and confirm with the user that they are genuinely
without UI before excluding them from the shell's information inventory; a shell
that silently omits a feature's badge, banner or entry point is the exact failure
this aggregation exists to prevent.

### 2d: Existing UX Specs

Glob `design/ux/*.md` and note which screens and flows already have specs. For screens
that will link to or from the current screen, read their navigation and entry/exit
sections to find the entry and exit points this spec must match. If
`design/ux/app-shell.md` exists, read its navigation model and global states — screen
specs reference them instead of re-specifying them. If
`design/inventory/screen-inventory.md` exists, it is the list of screens per surface
that specs must cover.

### 2e: Interaction Pattern Library

If `design/ux/interaction-patterns.md` exists, read the pattern catalog index (the
list of pattern names and their one-line descriptions). Do not read full pattern
details — just the catalog. This tells you which patterns already exist so you can
reference them rather than reinvent them.

### 2f: Design Language

Check for `design/brand/design-language.md`. If found, read its components & states,
layout (breakpoints) and platform adaptation sections. UX layout must use the
components, tokens and breakpoints already committed there. If it is absent, specs
still proceed; breakpoint widths stay `[TBD — design language]`.

### 2g: Accessibility Requirements

Read the resolved `accessibility` line, then check for
`design/accessibility-requirements.md` and read its `> **Target**:` line and
requirement matrix. The spec must satisfy the target committed there.
- Both present and equal → use it.
- They differ, or the document exists but `accessibility.target` is unset → flag the
  mismatch; the Architecture → Validation gate checks that they match. Offer
  `/ux-design accessibility` to reconcile them.
- Neither → the target is not yet committed. In `accessibility` mode that is this
  session's first decision; in every other mode note it as an open question and never
  assume a level.

### 2h: Surfaces, Input Methods & Breakpoints (from the resolved config)

Read the resolved `surfaces` line. Derive, and store for the whole session:

- **`web`** → input methods: keyboard, pointer, touch (mobile browsers), screen
  reader (NVDA / JAWS, VoiceOver on macOS and iOS Safari, TalkBack on Chrome);
  breakpoints `sm` / `md` / `lg` from the design language.
- **`ios`** / **`android`** → input methods: touch and screen reader (VoiceOver,
  TalkBack); keyboard and pointer when tablets, foldables or Chromebooks are in
  scope; size classes compact / regular.
- **`api`** → no UI; ignored here.

If the `surfaces` line is unset, ask once:
> "Surfaces aren't configured yet. Which does this product ship?"
> Options: "Web only", "iOS and Android", "Web + iOS + Android", "Other (I'll describe)"
>
> (Run `/setup-stack` to record `platform.surfaces` so you won't be asked again.)

Store the answer for the rest of this session. Do **not** ask again per section or
per screen.

Also read, with Read from `project.yaml`, `localization.locales` (for the
Localization section; unset ⇒ ask when that section is reached), `naming.events` (for
event names) and the `performance.*` budgets (for acceptance criteria).

**API contract and tracking plan** (screen and flow modes): glob `docs/api/` for the
contract (`openapi*.yaml`, `openapi*.json`, `*.graphql`, `*.proto`, `asyncapi*.yaml`)
and read `design/product/tracking-plan.md` if it exists — `## API Data` and
`## Analytics Events` reuse their names.

### 2i: Present Context Summary

Before any design work, present a brief summary to the user:

> **Designing: [Screen/Flow Name]**
> - Mode: [Screen spec / Flow spec / App shell / Pattern library / Accessibility requirements / User journey]
> - Lifecycle stage(s): [from user-journey.md, or "unknown — no journey map"]
> - PRD requirements feeding this spec: [count and names, or "none found"]
> - Related screens already specced: [list, or "none yet"]
> - Known patterns available: [count, or "no pattern library yet"]
> - Accessibility target: [committed value, or "not yet committed"]
> - Surfaces, input methods and breakpoints: [from Phase 2h]
> - API contract: [path, or "none yet — operations will be marked proposed"]

Then ask: "Anything else I should read before we start, or shall we proceed?"

---

## 2b. Retrofit Mode Detection

Before creating a skeleton, check if the target output file already exists.

Glob the output path resolved in Phase 1 (`design/ux/<slug>.md`, or the mode's fixed
path).

**If the file exists — retrofit mode:**
- Read the file in full
- For each expected section, check whether the body has real content (more than a `[To be designed]` placeholder) or is empty/placeholder
- Present a section status summary to the user (screen-spec example; use the
  sections of the mode's template):

> "Found existing UX spec at `design/ux/[filename].md`. Here's what's already done:
>
> | Section | Status |
> |---------|--------|
> | Purpose & User Need | [Complete / Empty / Placeholder] |
> | User Context on Arrival | ... |
> | Navigation Position | ... |
> | Entry & Exit Points | ... |
> | Layout Specification | ... |
> | Auth & Permission State | ... |
> | States & Variants | ... |
> | Interaction Map | ... |
> | Data Requirements | ... |
> | API Data | ... |
> | Analytics Events | ... |
> | Transitions & Animation | ... |
> | Input Method Completeness Checklist | ... |
> | Screen-Level Accessibility Requirements | ... |
> | Localization Considerations | ... |
> | Acceptance Criteria | ... |
> | Open Questions | ... |
>
> I'll work on the [N] incomplete sections only — existing content will not be overwritten."

- A section the template has and the file lacks (an older spec without `## API Data`,
  for instance) counts as Empty: offer to add it with its exact template heading.
- Skip Section 3 (skeleton creation) — the file already exists
- In Phase 4 (Section Authoring), only work on sections with Status: Empty or Placeholder
- Use `Edit` to fill placeholders in-place rather than creating a new skeleton

**If the file does not exist — fresh authoring mode:**
Proceed to Phase 3 (Create File Skeleton) as normal.

---

## 3. Create File Skeleton

Once the user confirms, **immediately** create the output file with empty section
headers. This ensures incremental writes have a target and work survives interruptions.

Ask: "May I create the skeleton file at `design/ux/[filename].md`?" — except in
`accessibility` mode (`design/accessibility-requirements.md`) and `journey` mode
(`design/product/user-journey.md`), whose paths are deliberately not under
`design/ux/` (see the mode table in Section 1).

Each skeleton's section list mirrors its template in `.claude/docs/templates/` — if
a template gains or loses a section, the skeleton follows it, not the reverse. Copy
every heading exactly: scripts, gates and `/api-design reconcile` match on them
(`## API Data` in particular). Never translate a heading.

---

### Skeleton for UX Spec (screen)

```markdown
# UX Spec: [Screen Name]

> **Status**: Draft
> **Author**: [user + product-designer]
> **Last Updated**: [today's date]
> **Screen ID**: [identifier]
> **Surfaces**: [from Phase 2h]
> **Route / Deep Link**: [To be designed]
> **Journey Stage(s)**: [from context]
> **Related PRDs**: [from Phase 2c]
> **Related ADRs**: [from context, or none]
> **Related UX Specs**: [from Phase 2d]
> **Accessibility Target**: [from Phase 2g, or "not yet committed"]

## Purpose & User Need
[To be designed]

## User Context on Arrival
[To be designed]

## Navigation Position
[To be designed]

## Entry & Exit Points
[To be designed]

## Layout Specification

### Wireframe
[To be designed]

### Breakpoints
[To be designed]

### Component Inventory
[To be designed]

## Auth & Permission State
[To be designed]

## States & Variants
[To be designed]

## Interaction Map

### Navigation Inputs
[To be designed]

### Action Inputs
[To be designed]

### State-Specific Behaviors
[To be designed]

## Data Requirements
[To be designed]

## API Data
[To be designed]

## Analytics Events
[To be designed]

## Transitions & Animation
[To be designed]

## Input Method Completeness Checklist
[To be designed]

## Screen-Level Accessibility Requirements
[To be designed]

## Localization Considerations
[To be designed]

## Acceptance Criteria
[To be designed]

## Open Questions
[To be designed]
```

---

### Skeleton for User Flow

```markdown
# User Flow: [Flow Name]

> **Status**: Draft
> **Author**: [user + product-designer]
> **Last Updated**: [today's date]
> **Flow ID**: [slug]
> **Surfaces**: [from Phase 2h]
> **Journey Stage(s)**: [from context]
> **Related PRDs**: [from Phase 2c]
> **Screen Specs**: [To be designed]
> **Success Metric**: [from the PRD, or To be designed]
> **Accessibility Target**: [from Phase 2g, or "not yet committed"]
> **Open Questions**: [none]

## Entry Points & Deep Links
[To be designed]

## Critical Path
[To be designed]

## Branches & Optional Paths
[To be designed]

## Decision Points
[To be designed]

## Error & Recovery Paths
[To be designed]

## Exit & Success Criteria
[To be designed]

## Analytics Events
[To be designed]
```

---

### Skeleton for App Shell

```markdown
# App Shell: [Product Name]

> **Status**: Draft
> **Author**: [user + product-designer]
> **Last Updated**: [today's date]
> **Product**: [Product name]
> **Surfaces**: [from Phase 2h]
> **Related PRDs**: [every PRD from the Phase 2c aggregation]
> **Screen Inventory**: [path, or none]
> **Accessibility Target**: [from Phase 2g, or "not yet committed"]
> **Design Language**: [path, or none]
> **Open Questions**: [none]

## Navigation Model
[To be designed]

## Global Regions per Breakpoint
[To be designed]

## Persistent Elements
[To be designed]

## Global States
[To be designed]

## Notifications & Banners
[To be designed]

## Accessibility
[To be designed]
```

---

### Skeleton for Interaction Pattern Library

```markdown
# Interaction Pattern Library: [Product Name]

> **Status**: Draft
> **Author**: [user + product-designer]
> **Last Updated**: [today's date]
> **Version**: 1.0
> **Surfaces**: [from Phase 2h]
> **UI Frameworks**: [per surface, from the resolved `stack` line, or To be designed]
> **Component Library**: [To be designed]
> **Related Documents**: [Copy the list verbatim from the template]

## How to Use This Library
[Copy this section verbatim from the template]

## Pattern Catalog Index
[To be designed]

## Standard Control Patterns
[To be designed]

## Service-Specific Patterns
[To be designed]

## Navigation Patterns
[To be designed]

## Feedback and Loading Patterns
[To be designed]

## Animation Standards
[To be designed]

## Open Questions
[To be designed]
```

---

### Skeleton for Accessibility Requirements

Section list mirrors `.claude/docs/templates/accessibility-requirements.md` — if
the template gains or loses a section, this skeleton follows it, not the reverse.

```markdown
# Accessibility Requirements: [Product Name]

> **Target**: [the value committed in the target decision below — never a placeholder]
> **Standard**: [WCAG 2.2 level derived from the target]
> **Regional Standards**: [from the compliance line, or "None — regions=none"]
> **Surfaces**: [from Phase 2h]
> **Status**: Draft
> **Author**: [user + product-designer + accessibility-specialist]
> **Last Updated**: [today's date]
> **Accessibility Consultant**: [To be designed]
> **Linked Documents**: `design/product/feature-map.md`, `design/brand/design-language.md`, `design/ux/app-shell.md`, `design/ux/interaction-patterns.md`

## Target & Scope
[To be designed]

## Requirement Matrix

### Perceivable
[To be designed]

### Operable
[To be designed]

### Understandable
[To be designed]

### Robust
[To be designed]

### Beyond WCAG (platform expectations)
[To be designed]

## Regional Standards
[To be designed]

## Platform Accessibility APIs
[To be designed]

## Per-Feature Accessibility Matrix
[To be designed]

## Accessibility Test Plan
[To be designed]

## Known Intentional Limitations
[To be designed]

## Audit History
[To be designed]

## External Resources
[To be designed]

## Open Questions
[To be designed]
```

> **The target commitment is the gated part.** The Architecture → Validation gate
> requires the file to exist *with `accessibility.target` committed* — its
> `> **Target**:` line equal to the value in `project.yaml` — and the Validation →
> Build gate checks that each key screen spec addresses that target. A skeleton whose
> Target line is still a placeholder satisfies the catalog glob but not the gate.
> So in `accessibility` mode, **decide the target before creating the skeleton**:
>
> 1. If the resolved `accessibility` line is unset, explain the options, then use
>    `AskUserQuestion`:
>    - "Which accessibility target does this product commit to (WCAG 2.2)?"
>    - Options: "`wcag-aa` (Recommended — the level most regional standards and
>      procurement rules build on)", "`wcag-a`", "`wcag-aaa` (specific flows only —
>      W3C does not recommend it product-wide)", "`none` (a recorded decision, e.g. an
>      internal tool)"
>    If a region in the resolved `compliance` line carries accessibility obligations
>    and the choice is `none` or `wcag-a`, say so and have the accessibility-specialist
>    explain the gap before the user confirms.
> 2. Ask "May I write this to `project.yaml`?" showing the exact change — a top-level
>    `accessibility:` block with the single key `target: <value>` (update the value in
>    place if the block exists). Write nothing else to `project.yaml`.
> 3. Create the skeleton with `> **Target**: <value>` as its first header line.
>
> If `accessibility.target` is already set, use it; if it differs from an existing
> document's Target line, surface the mismatch and let the user choose which value
> stands before writing either file.

---

### Skeleton for User Journey

```markdown
# User Journey Map: [Product Name]

> **Status**: Draft
> **Author**: [user + product-manager + product-designer]
> **Last Updated**: [today's date]
> **Primary Persona**: [from the brief or design/product/personas/]
> **Links To**: [brief or one-pager path], `design/product/feature-map.md`, `design/product/tracking-plan.md`
> **North Star Metric**: [from the brief's Success Metrics]
> **Business Model**: [from the brief]

**Journey summary**: [To be designed]

## Lifecycle Stages

### Acquisition
[To be designed]

### Sign-up
[To be designed]

### Onboarding / Activation
[To be designed]

### Habit
[To be designed]

### Retention
[To be designed]

### Monetization
[To be designed]

### Advocacy
[To be designed]

## Moments of Value
[To be designed]

## Drop-off Risks
[To be designed]

### Mitigations this product does not use
[To be designed]

## Metrics per Stage
[To be designed]

### Validation Questions
[To be designed]
```

---

After writing the skeleton, update `production/session-state/active.md` with:
- Task: Designing [screen/flow name] UX spec (or the mode's document)
- Current section: Starting (skeleton created)
- File: the output path resolved in Phase 1

---

## 4. Section-by-Section Authoring

Walk through each section in order. For **each section**, follow this cycle:

```
Context  ->  Questions  ->  Options  ->  Decision  ->  Draft  ->  Approval  ->  Write
```

1. **Context**: State what this section needs to contain and surface any relevant
   constraints from context gathered in Phase 2.
2. **Questions**: Ask what is needed to draft this section. Use `AskUserQuestion`
   for constrained choices, conversational text for open-ended exploration.
3. **Options**: Where design choices exist, present 2-4 approaches with pros/cons.
   Explain reasoning in conversation, then use `AskUserQuestion` to capture the decision.
4. **Decision**: User picks an approach or provides custom direction.
5. **Draft**: Write the section content in conversation for review. Flag provisional
   assumptions explicitly.
6. **Approval**: Use `AskUserQuestion`:
   - "Does this capture the [section name] correctly?"
   - Options: "Yes — write it to the file", "Small changes needed (describe below)", "Major rethink needed"
   Do not proceed to step 7 until the user selects "Yes".
7. **Write**: Use `AskUserQuestion`: "May I write the [section name] section to `[filepath]`?"
   - Options: "Yes, write it", "Wait — one more change"
   Once confirmed, use `Edit` to replace the `[To be designed]` placeholder with approved content.

After writing each section, update `production/session-state/active.md`.

Section bodies are written in the user's conversation language; headings, bold field
labels, status tokens, IDs and paths stay exactly as the template spells them.
User-facing copy drafted inside a spec is marked as a draft for the ux-writer.

---

### Section guidance — read the ONE file for the active mode

Per-section authoring guidance lives in its own file per mode. **When you reach
Phase 4, read only the file matching the mode resolved in Section 1; never load
the other two.**

| Mode | Guidance file |
|------|---------------|
| UX spec — screen or flow | `.claude/skills/ux-design/references/sections-ux-spec.md` |
| App shell | `.claude/skills/ux-design/references/sections-app-shell.md` |
| Interaction Pattern Library | `.claude/skills/ux-design/references/sections-patterns.md` |
| Accessibility Requirements | `.claude/docs/templates/guidance/accessibility-requirements-guide.md` |
| User journey | The journey guidance below (no separate file) |

> The accessibility guidance lives under `templates/guidance/` rather than this
> skill's `references/` because the template it documents
> (`.claude/docs/templates/accessibility-requirements.md`) is consumed by
> `/ux-review` and the gate files too. Same rule applies: load only the part
> covering the section you are authoring, never the whole file.

Apply `docs.density` to whatever that file tells you to author — it controls the
depth of each section, not which sections exist.

**Accessibility mode, in brief** (the guide has the depth):
- **Target & Scope** — the committed target and its rationale; what is in scope;
  third-party UI the team does not control (payment widgets, social-login pages,
  identity-verification vendor flows) and what the team does about each.
- **Requirement Matrix** — POUR-organized, one column per surface in the resolved
  `surfaces` line; rows above the target level only when listed as commitments.
  Spawn the accessibility-specialist to draft the matrix for the surfaces, then
  review it with the user row group by row group.
- **Regional Standards** — one row per region in the resolved `compliance` line,
  from the `## Accessibility` section of `.claude/docs/compliance/<region>.md` (load
  only listed regions). `regions=none` ⇒ write "None — no regional standard applies".
  Unset ⇒ ask which regions apply (`/setup-stack` records `compliance.regions`
  permanently). No deadline, penalty or threshold without `(Source: <url>, retrieved
  YYYY-MM-DD)`.
- **Per-Feature Accessibility Matrix** — one row per feature in the feature map
  (count the features first and check every one has a row).

**Journey mode guidance** (sections of `user-journey.md`):
- **Journey summary** — ask the user to tell the story of one target user from first
  hearing about the product to recommending it, in one paragraph. If it will not fit
  in one paragraph, the value proposition needs work first; say so.
- **Lifecycle Stages** — walk the seven stages in order. For each, ask the user's
  state on arrival, the question they are asking, what the product must deliver, the
  channels and the features involved (feature-map slugs), the success exit and the
  risk if the stage fails. Ask which stages do not apply — B2B products often acquire
  through sales and sign up by invitation; a free product may have no monetization
  stage yet — and mark them "Not applicable — [reason]" rather than filling
  placeholders. For Onboarding / Activation, agree the activation event and its
  target time first, then the activation ramp, the feature introduction order and
  the first failure.
- **Moments of Value** — 5–12 specific moments, each with the event that proves it
  happened; mark the activation moment.
- **Drop-off Risks** — every risk with a measurable signal, a likely cause, a
  mitigation and an owner; then the mitigations the product refuses to use (dark
  patterns).
- **Metrics per Stage** — at least one event-based metric per applicable stage, with
  a baseline (or "unknown — measure first"), a target and a guardrail; then the
  validation questions `/usability-report` sessions will ask.

---

## 5. Cross-Reference Check

Before marking the document as ready for review, run these checks:

**1. PRD requirement coverage**: Does every PRD `## UI Requirements` item that
references this screen have a corresponding element in this spec? (Shell: every
global element from the Phase 2c aggregation.) Present any gaps.

**2. Pattern library alignment**: Are all interaction patterns used in this spec
referenced by name? If a new pattern was invented during this session, flag it for
addition to the pattern library:
Use `AskUserQuestion`:
- "This spec uses [pattern name], which isn't in the pattern library yet. What should we do?"
- Options: "Add it to the pattern library now", "Flag it as a gap and continue", "Skip — this pattern is one-off"

**3. Navigation consistency**: Do the entry/exit points, routes and deep links in
this spec match the navigation map in related specs and the app shell? Is every
route unique? Flag mismatches.

**4. Accessibility coverage**: Does the spec address the target committed in
`design/accessibility-requirements.md`? If no target is committed, record it as an
open question — never report it as covered.

**5. States coverage**: Does every data-dependent element have loading, empty, error
and offline states, and are the auth and permission boundaries defined? Flag any that
don't.

**6. API Data coverage** (screen specs): Does every server-sourced row of
`## Data Requirements` map to an operation in `## API Data`, and is every operation
`in contract`, `proposed` or `mismatch`? Any `proposed` or `mismatch` row means
`/api-design reconcile` is a next step. (Flow specs: does every critical-path screen
that calls the API have a screen spec?)

**7. Analytics coverage**: Does every event reuse a tracking-plan name or follow
`naming.events` as a proposal, with no personal data in its properties?

Which checks apply per mode: screen and flow specs run all seven; the app shell runs
1, 3, 4 and 5; the pattern library runs 2 and 4; accessibility requirements check
that every feature in the feature map has a row in the per-feature matrix and that
the Target line equals `accessibility.target`; the journey map checks that every
applicable stage has a metric and every moment of value has an event. A check that
did not run is listed as `NOT CHECKED — <reason>`, never omitted.

Present the check results:
> **Cross-Reference Check: [Screen Name]**
> - PRD requirements: [N of M covered / all covered]
> - New patterns to add to library: [list or "none"]
> - Navigation mismatches: [list or "none"]
> - Accessibility gaps: [list, "none", or "target not committed"]
> - Missing states: [list or "none"]
> - API Data: [N in contract, N proposed, N mismatch — or "no server data"]
> - Analytics: [N existing, N proposed, PII flags]

---

## 6. Handoff

When all sections are approved and written:

### 6a: Update Session State

Update `production/session-state/active.md` with:
- Task: [screen-name] UX spec (or the mode's document)
- Status: Complete (or In Review)
- File: the output path
- Sections: All written
- Next: [suggestion]

### 6b: Suggest Next Step

Before presenting options, state clearly (screen, flow, shell and pattern modes):

> "This spec should be validated with `/ux-review` before it enters the
> implementation pipeline. The Validation → Build gate requires every key-screen spec
> to have a `/ux-review` record."

Then use `AskUserQuestion`:
- "Run `/ux-review [filename]` now, or do something else first?"
  - Options:
    - "Run `/ux-review` now — validate this spec"
    - "Design another screen first, then review all specs together"
    - "Reconcile the API contract with `/api-design reconcile`" (offer only when `## API Data` has `proposed` or `mismatch` rows)
    - "Stop here for this session"

If the user picks "Design another screen first", add a note: "Reminder: run
`/ux-review` on all completed specs before running `/gate-check build`."

For `accessibility` mode, offer instead: `/design-language` (token contrast checked
against the target), `/ux-design [key screen]`, `/gate-check validation` once the
Architecture phase is complete. For `journey` mode: `/ux-design [key screen]` for the
screens of the activation path, `/write-prd` for features the journey showed are
missing.

### 6c: Cross-Link Related Specs

If other UX specs link to or from this screen, note which ones should reference
this spec. Do not edit those files without asking — just name them.

---

## 7. Recovery & Resume

If the session is interrupted (compaction, crash, new session):

1. Read `production/session-state/active.md` — it records the current document
   and which sections are complete.
2. Read the output file — sections with real content are done; sections with
   `[To be designed]` still need work.
3. Resume from the next incomplete section — no need to re-discuss completed ones.

This is why incremental writing matters: every approved section survives any
disruption.

---

## 8. Specialist Agent Routing

The product-designer's perspective leads this skill. For specific sub-topics,
additional expertise is needed:

| Topic | Coordinate with |
|-------|----------------|
| Screen, flow, shell and pattern drafting | `product-designer` — owns the UX of every mode; spawn it to draft a large section (layout options, state tables, the pattern catalog) for the user to review |
| Microcopy, state copy, error and empty-state messages | `ux-writer` — spec copy is a draft until the ux-writer finalizes it |
| Implementation feasibility on web | `frontend-engineer` — before finalizing breakpoints, the component inventory and realtime or offline behaviour |
| Implementation feasibility on iOS and Android | `mobile-engineer` — before finalizing native transitions, sheets, permissions, deep links and offline behaviour |
| Accessibility target, requirement matrix and screen-level accessibility | `accessibility-specialist` — drafts the matrix and regional rows in `accessibility` mode; reviews focus order and announcements on request |
| Visual treatment | The design language decides; changes to it go through `/design-language`, not this skill |
| API operations | Proposals only — the contract is decided in `/api-design reconcile` |

When delegating to another agent via the `Agent` tool:
- Provide: the mode, the document path, a product summary (brief or one-pager), the
  resolved `surfaces` and `accessibility` lines, and the specific question
- The agent returns analysis to this session
- This session presents the agent's output to the user
- The user decides; this session writes to file
- Agents do NOT write to files directly — this session owns all file writes

---

## Collaborative Protocol

**In `collaborative` mode (the default).** For `guided` and `autonomous` modes,
see the per-mode rules in `.claude/docs/automation-modes.md` — the steps below
describe what collaborative mode requires, not what applies universally.

This skill follows the collaborative design principle at every step:

1. **Question -> Options -> Decision -> Draft -> Approval** for every section
2. **AskUserQuestion** at every decision point (Explain -> Capture pattern):
   - Phase 2: "Ready to start, or need more context?"
   - Phase 3: "May I create the skeleton?" (accessibility mode: the target decision first)
   - Phase 4 (each section): design questions, approach options, draft approval
   - Phase 5: "Run cross-reference check? What's next?"
3. **"May I write this to `<path>`?"** before the skeleton, before each section
   write, and before the `accessibility.target` write to `project.yaml`
4. **Incremental writing**: Each section is written to file immediately after approval
5. **Session state updates**: After every section write

**Aesthetic deference**: When layout or visual choices come down to taste, present
the options and ask. Do not select a layout because it is "standard" — always
confirm. The user decides.

**Conflict surfacing**: When a PRD requirement and the available screen space
conflict, surface the conflict and present resolution options. Never silently drop
a requirement. Never silently expand the layout without flagging it.

**Never** auto-generate the full spec and present it as a fait accompli.
**Never** write a section without user approval.
**Never** contradict an existing approved UX spec without flagging the conflict.
**Never** assume an accessibility target, a surface list or a region list that the
configuration leaves unset.
**Always** show where decisions come from (PRD requirements, the user journey, the
design language, user choices).

Verdict: **COMPLETE** — the document was written and approved section by section.
**NOT ASSESSED** — Phase 1 stopped because no UI surface is configured (every mode
except `journey`).

---

## Recommended Next Steps

- Run `/ux-review [filename]` to validate this spec before it enters the implementation pipeline
- Run `/ux-design [next-screen]` to continue designing remaining screens or flows
- Run `/api-design reconcile` when any `## API Data` row is `proposed` or `mismatch`
- Run `/gate-check build` once all key screens have reviewed UX specs
