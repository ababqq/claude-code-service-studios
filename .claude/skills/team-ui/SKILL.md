---
name: team-ui
description: "UI pipeline for web and mobile: spec, visual design, implementation, review, polish."
argument-hint: "[screen, flow or UI feature description] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, Agent, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskUpdate, Bash(bash "*/.claude/skills/team-ui/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,team.size,surfaces,accessibility,stack,code_roots`

Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

If no argument is provided, output usage guidance and exit without spawning any agents:
> Usage: `/team-ui [screen, flow or UI feature description]` — e.g. `create goal screen`, `onboarding flow`, or `shell` for the app shell.

Do not use `AskUserQuestion` here; output the guidance directly.

When this skill is invoked with an argument, orchestrate the UI team through a structured pipeline.

**Decision Points:** At each phase transition, use `AskUserQuestion` to present
the user with the subagent's proposals as selectable options. Write the agent's
full analysis in conversation, then capture the decision with concise labels.
In `collaborative` mode, the user must approve before moving to the next phase.
In `guided` mode the pipeline advances automatically unless a phase is BLOCKED;
in `autonomous` mode it runs end to end, recording each phase outcome via
`log_decision`. Decisions in `automation_always_ask` categories
(`is_always_ask_category` helper) always prompt regardless of mode. See
`.claude/docs/automation-modes.md`.

Track each phase as a task (`TaskCreate` at the start, `TaskUpdate` when it resolves).

## Phase 0: Resolve Config

The block at the top of this skill resolved `review_mode`, `automation`, `team.size`,
`surfaces`, `accessibility`, `stack` and `code_roots`.

`review_mode` sets gate depth. This skill spawns one gate, **DD-UI-CONSISTENCY**, in Phase 4b.
**Review mode check** — apply before spawning DD-UI-CONSISTENCY (`--review` overrides the
resolved value):
- `full` → spawn as normal
- `lean` → **skip every gate whose ID does not end in `-PHASE-GATE`**. Note: `[GATE-ID] skipped — Lean mode`
  DD-UI-CONSISTENCY does not end in `-PHASE-GATE`, so lean skips it: record `[DD-UI-CONSISTENCY] skipped — Lean mode`.
- `solo` → skip all gates. Note: `[DD-UI-CONSISTENCY] skipped — Solo mode`

Unset on an unconfigured project: `modes.rigor` defaults to `minimal`, which resolves `review_mode` to `solo`.

`automation` drives the Decision Points note above. See the Decision Points note above and
`.claude/docs/automation-modes.md` for how each mode changes pipeline behavior.

**`surfaces`** decides which implementation streams exist: `web` → `frontend-engineer`;
`ios` / `android` → `mobile-engineer`. The unset form means the surfaces are unknown — ask
which surfaces this UI ships on before Phase 1b; never assume web only. A resolved list with
no UI surface (only `api`) means there is nothing for this pipeline to build: say so and stop.

**`code_roots`** gives where Phase 3 writes: the `web=` root for `web`, the `mobile=` root
for `ios` / `android` (`.claude/docs/code-root-resolution.md` § Surfaces and roots; several
roots ⇒ the one the story names, else ask). A surface whose layer has no resolved root is not
implemented: report
`no code root resolved for <layer> (set stack.layers.<layer>.root via /setup-stack)` as a
blocker — never write into a guessed directory.

**`accessibility`** carries `accessibility.target`. Phase 1a reads it together with the
`> **Target**:` line of `design/accessibility-requirements.md`; unset is undecided, never
`none`.

**`team.size`**: which agents are active (orthogonal to review_mode gate-depth and workflow docs).
- **`individual`**: `frontend-engineer` or `mobile-engineer` — the engineer for the UI's
  primary surface (the first surface the spec names). Other agents consulted via this one,
  not spawned separately.
- **`small`**: the documented pipeline — `product-designer` → `design-engineer` →
  `frontend-engineer` / `mobile-engineer` → `accessibility-specialist`.
- **`studio`**: the `small` pipeline + `ux-writer` + the routed stack sub-specialists for the
  web and mobile layers.
Team skills spawn only the gates `.claude/docs/director-gates.md` § Gate Index lists this skill under (Spawned by column), after the review-mode check (lean suffix rule); team-size scoping never removes a director gate. A non-core agent needed at `individual` routes through the nearest active core agent with an informational note. **"Phase gate" means any phase that ends in an `AskUserQuestion` decision point before the pipeline advances** — not every phase. Apply the test literally: if the phase below has no decision point, it is not a gate, and an agent restricted to "phase gates only" is not spawned for it. This active-set scoping applies throughout the pipeline below: any phase that names an agent outside the active set routes through the nearest core agent rather than spawning it.

`design-director` is not part of the active set at any size: it is spawned only for
DD-UI-CONSISTENCY, and only when the review-mode check keeps that gate.

Unset on an unconfigured project, `modes.rigor` defaults to `minimal`, which resolves
`team.size` to `individual`.

**Announce the active set before Phase 1a — never let the collapse be silent.**
Before spawning anything, state in one line which agents this run will actually
spawn, and which the pipeline below names but will **not** spawn at the resolved
`team.size`. For example:

> `Active set (team.size: <resolved>): <the agents listed for that size above>.`
> `Not spawned this run: <every other agent this pipeline names> — consulted`
> `through <nearest active core agent>. Raise team.size (or modes.rigor) to widen.`

Fill it from the `team.size` list directly above and the agents this file's own
pipeline names — not from an example. Both sets differ per orchestrator. Add whether
DD-UI-CONSISTENCY will run or be skipped at the resolved `review_mode`.

The pipeline below reads as a multi-agent fan-out and at the shipped default it
is one or two agents — `team-release` names nine agents and at `individual` runs
`release-manager` alone; `team-content` names four and at the same size runs
`ux-writer` alone. **The collapse is correct**: `team.size` is rigor-fronted and the
narrow default is the token lever, measured at roughly 10x. What was wrong is that
nothing said so, so a reader could not distinguish a correctly-collapsed run from a
broken pipeline, and the per-agent "routes through the nearest core agent with an
informational note" rule above fires at routing time and never states the shape of
the run as a whole.

This is the same rule as the skipped-check reporting elsewhere in this file: **a constraint that is enforced but never surfaced is
indistinguishable, to the person reading the output, from one that was never
enforced.**

## Team Composition
- **product-designer** — User flows, screen states, interaction patterns, platform conventions (web, iOS HIG, Material), accessibility intent
- **design-engineer** — Visual treatment from the design language: design tokens, component library mapping, theming and dark mode, motion, visual regression
- **frontend-engineer** — Web implementation: screens, components, data fetching, forms, routing, web accessibility
- **mobile-engineer** — iOS / Android implementation: screens, navigation, platform components, dynamic type, offline states
- **accessibility-specialist** — Audits accessibility compliance at Phase 4
- **ux-writer** (`studio`) — Microcopy for every state of the screen, in the voice of `design/brand/voice-and-tone.md`
- **routed stack sub-specialists** (`studio`) — Validate the implementation against framework idioms for the web and mobile layers
- **design-director** (gate only) — DD-UI-CONSISTENCY after Phase 4

**Routing the stack sub-specialists (`studio`).** Spawn what the resolved `stack` line's
routing names for the web and mobile layers (`<lead>><sub>`; the lead when no sub is named).
A layer listed under `unset=` (every layer, when the line reads `stack: unset — run /setup-stack`)
spawns nobody and prints
`NOT CHECKED — <layer> layer not configured (run /setup-stack)`.

**Templates used by this pipeline:**
- `ux-spec.md` — Standard screen UX specification
- `user-flow.md` — Multi-screen flow specification
- `app-shell.md` — App shell (global UI) specification
- `interaction-pattern-library.md` — Reusable interaction patterns
- `accessibility-requirements.md` — Committed accessibility target and requirements

## How to Delegate

Use the `Agent` tool to spawn each team member as a subagent:
- `subagent_type: product-designer` — User flows, screen states, interaction patterns
- `subagent_type: design-engineer` — Visual treatment, tokens, components, theming
- `subagent_type: frontend-engineer` — Web implementation
- `subagent_type: mobile-engineer` — iOS / Android implementation
- `subagent_type: [routed stack sub-specialist]` — Framework-specific UI pattern validation (e.g., nextjs-specialist, react-native-specialist, ios-specialist)
- `subagent_type: accessibility-specialist` — Accessibility compliance audit
- `subagent_type: ux-writer` — Microcopy for every state (`studio`)
- `subagent_type: design-director` — DD-UI-CONSISTENCY gate only

**Brief each agent — do not dump context.** Read the shared inputs **once** and pass a distilled brief inline: the lines each agent actually needs, never a file path for a document you have already read (an agent handed a path re-reads the whole file). Pass a path only for a document you have not read and only that agent needs.

**End every agent prompt with a return contract:** "Write your full output to `[path]` — that named path is your write authorisation under the bounded exception below, so write it without a separate approval prompt. Return **only** (1) the path written, (2) a ≤5-bullet summary of decisions, (3) any BLOCKED/CONCERNS items, one line each. Do not restate the documents you read." Without it, an agent returns everything it read back into this session.

The routed stack sub-specialists (Phase 3, `studio`) write no file — they return their implementation notes inline, and this skill passes them into the implementing engineer's brief.

> **Why this does not violate the Collaboration Protocol.** `CLAUDE.md` requires an agent to ask "May I write this to [filepath]?" before Write/Edit. A subagent spawned here writes **without** asking, and that is a deliberate, bounded exception rather than an oversight — the same call already made for `consistency-check` appending to `active.md`. The exception holds only when all three are true: (1) the path is one **you** named in the prompt, so the user approved the destination when they approved the phase; (2) it is a new artifact under `production/`, `docs/` or `tests/`, never an edit to existing source or config; (3) the phase that produced it is itself gated by an `AskUserQuestion` before the pipeline advances. Outside those three, the agent must ask. **Do not "fix" this by asking per subagent** — a prompt per agent per phase makes an orchestrator unusable, which is why the exception exists.

Launch independent agents in parallel where the pipeline allows it (e.g., Phase 4 review agents can run simultaneously; so can the web and mobile streams of Phase 3).

## Pipeline

### Phase 1a: Context Gathering

Before designing anything, read and synthesize:
- `design/product/product-brief.md` (or `design/product/one-pager.md`) — target users and the value the screen serves; the resolved `surfaces` line gives the platforms
- `design/product/user-journey.md` — the user's state and context when they reach this screen
- All PRD `## UI Requirements` sections relevant to this feature (`design/prd/*.md`)
- `design/ux/interaction-patterns.md` — existing patterns to reuse (not reinvent)
- `design/accessibility-requirements.md` — committed accessibility target (its `> **Target**:` line, e.g. `wcag-aa`)

**Report the status of every document above before designing anything.** Phase 1a
reads five inputs; for a long time only the pattern library was guarded, and the
other four could be absent without anything noticing. List each as
present or ABSENT.

**`design/accessibility-requirements.md` is the one that must not pass silently.**
It carries the committed accessibility target, which **Phase 3 implements against**
and **Phase 4 gates on** ("verify compliance against the committed accessibility
target … flag any violations as blockers"). If the file is missing there is no committed
target, so that gate has no criterion and would pass while checking nothing — a gate made
of an absent standard, the same shape as an assertion that can never fail. When it
is absent:
- Say so here, and carry it forward: **Phase 4 must report
  `Accessibility: NOT ASSESSED — no committed target (design/accessibility-requirements.md absent)`
  and must NOT report the accessibility gate as passed.**
- The product-designer states which target they designed against as an explicit
  assumption, so a later reader can see it was assumed rather than committed. When the
  resolved `accessibility` line names a target, that is the assumption to state; when it
  prints the unset form, the assumption is the user's answer to "which WCAG 2.2 level?".
- Recommend `/ux-design accessibility` to establish the target.

The same applies when the file exists but commits no target (no `> **Target**:` line) and
the resolved `accessibility` line prints the unset form: Phase 4 reports
`Accessibility: NOT ASSESSED — no committed target (design/accessibility-requirements.md absent)`
(or `— accessibility.target unset`, the form for a file without a target), never COMPLIANT.
The same rule is mirrored in `/ux-review` so the two cannot drift.

A target of `none` **is** committed — a recorded decision, not a gap. There is no
conformance claim to check: Phase 4 reports
`Accessibility: N/A — target is none (recorded decision; no conformance claim)`, lists
any accessibility findings as ADVISORY rather than blockers, and never reports COMPLIANT
against `none`.

Absence of `design/product/product-brief.md`, `design/product/user-journey.md` or
`design/ux/app-shell.md` is not blocking, but name each missing one in the brief you
pass to the product-designer so they design knowing what context they lack, rather
than inferring it.

**If `design/ux/interaction-patterns.md` does not exist**, surface the gap immediately:
> "interaction-patterns.md does not exist — no existing patterns to reuse."

Then use `AskUserQuestion` with options:
- (a) Run `/ux-design patterns` first to establish the pattern library, then continue
- (b) Proceed without the pattern library — the implementing engineer will treat all patterns created as new and add each to a new `design/ux/interaction-patterns.md` at completion

Do NOT invent or assume patterns from the feature name or PRD alone. If the user chooses (b), explicitly instruct the implementing engineer in Phase 3 to treat all patterns as new and document them in `design/ux/interaction-patterns.md` when implementation is complete. Note the pattern library status (created / absent / updated) in the final summary report.

Summarize the context in a brief for the product-designer: what the user is doing, what they need, what constraints apply (surfaces, breakpoints, auth and permission state), and which existing patterns are relevant.

### Phase 1b: UX Spec Authoring

Invoke `/ux-design [feature name]` skill OR delegate directly to product-designer to produce `design/ux/[feature-name].md` following the `ux-spec.md` template (a multi-screen flow uses `user-flow.md`).

If designing the app shell, use the `app-shell.md` template instead of `ux-spec.md`.

> **Notes on special cases:**
> - For the app shell specifically, invoke `/ux-design` with `argument: shell` (e.g., `/ux-design shell`).
> - For the interaction pattern library, run `/ux-design patterns` once at project start and update it whenever new patterns are introduced during later phases.

Output: `design/ux/[feature-name].md` with all required spec sections filled — every state (loading, empty, error, offline, permission-denied, signed-out), each breakpoint or device class, and the `## API Data` operations the screen calls.

At `studio`, spawn **ux-writer** for the copy of every state the spec names, in the voice of `design/brand/voice-and-tone.md`; the copy goes into the spec through `/ux-design`.

### Phase 1c: UX Review

After the spec is complete, invoke `/ux-review design/ux/[feature-name].md`.

**Gate**: Do not proceed to Phase 2 until the verdict is APPROVED. If the verdict is NEEDS REVISION or MAJOR REVISION NEEDED, the product-designer must address the flagged issues and re-run the review. The user may explicitly accept a NEEDS REVISION risk and proceed, but this must be a conscious decision — present the specific concerns via `AskUserQuestion` before asking whether to proceed. A NOT ASSESSED verdict is not an approval: resolve the reason the review names and re-run it.

### Phase 2: Visual Design

Delegate to **design-engineer** (with the product-designer's hi-fi decisions):
- Review the full UX spec (flows, states, interaction patterns, accessibility notes) — not just the wireframe images
- Apply visual treatment from the design language (`design/brand/design-language.md`): semantic color tokens, typography (including the CJK font stack and line height), spacing, components and their states, motion
- Check that visual design preserves accessibility compliance: verify color contrast ratios in both light and dark themes, and confirm color is never the only indicator of state (shape, text, or icon must reinforce it)
- Map every element to an existing library component or token; specify any new component or token precisely (variants, states, token names) for the component library rather than as a one-off
- Specify all media asset requirements: icons, illustrations, images — with precise sizes, formats and density variants — for `/ui-inventory` to record
- Ensure consistency with existing implemented UI screens
- Output: visual design notes (token and component mapping, new components, asset needs) — returned inline; this skill adds them to the UX spec after "May I write this to `design/ux/[feature-name].md`?"

If `design/brand/design-language.md` does not exist, say so: the visual design is recorded as provisional (`NOT CHECKED — design language absent (run /design-language)`), and DD-UI-CONSISTENCY reviews against the pattern library alone.

### Phase 3: Implementation

Before implementation begins (`studio`), spawn the **routed stack sub-specialist** for each layer in scope (routing as described under Team Composition) to review the UX spec and visual design notes for framework-specific implementation guidance:
- Which framework primitives should be used for this screen? (e.g., server vs client components in Next.js App Router, React Navigation stack vs tabs in React Native, `NavigationStack` in SwiftUI, Material 3 components in Jetpack Compose)
- Any framework-specific gotchas for the proposed layout or interaction patterns (hydration, list virtualization, keyboard avoidance, safe areas)?
- Recommended component structure for the framework?
- Output: implementation notes to hand off to the implementing engineer before they begin

If the layer is not configured, skip this step. **Record `NOT CHECKED — <layer> layer not configured (run /setup-stack)` in this run's output.** A skipped check that says nothing is indistinguishable from a check that passed; the reader cannot tell stack guidance was never sought.

Delegate to **frontend-engineer** (`web`) and **mobile-engineer** (`ios` / `android`), in parallel when both surfaces are in scope:
- Implement the UI following the UX spec and visual design notes, in the surface's root from the resolved `code_roots` line
- **Use patterns from `design/ux/interaction-patterns.md`** — do not reinvent patterns that are already specified. If a pattern almost fits but needs modification, note the deviation and flag it for product-designer review.
- **UI NEVER owns business rules** — prices, limits, eligibility and entitlements come from the API; the UI renders server state and sends intents, and reconciles any optimistic update with the response
- All text through the localization system — no hardcoded user-facing strings
- Support keyboard, pointer, touch and screen reader (VoiceOver, TalkBack, NVDA) input
- Implement accessibility features per the committed target in `design/accessibility-requirements.md`
- Wire data fetching to the operations in the spec's `## API Data`, with the loading, empty, error and offline states the spec defines
- Only design tokens and library components — no one-off colors, spacing or type sizes
- Ask "May I write this to [path]?" before each source file you create or change — source edits are outside the bounded exception
- **If any new interaction pattern is created during implementation** (i.e., something not already in the pattern library), add it to `design/ux/interaction-patterns.md` before marking implementation complete
- Output: implemented UI feature, with screenshots of each state at each breakpoint or device class under `production/qa/evidence/<story-slug>/`

Capture the web states with the capture script when `/test-setup` installed it, the app
running, one run per state (procedure: `.claude/docs/run-and-observe.md`):
`CAPTURE_URL=<route> CAPTURE_STATE=<state> CAPTURE_OUT_DIR=production/qa/evidence/<story-slug> npx playwright test tests/e2e/capture.spec.ts`.
No `tests/e2e/capture.spec.ts` ⇒ `NOT CHECKED — web capture (no capture script; run /test-setup)`,
and the screenshots come from the engineer's manual run instead. Mobile states are captured
on a simulator or device by the mobile-engineer.

### Phase 4: Review (parallel)

Delegate in parallel:
- **product-designer**: Verify implementation matches the spec's flows, states and interaction details. Test keyboard-only navigation and focus order on web, and touch plus VoiceOver / TalkBack on mobile. Check accessibility features function correctly.
- **design-engineer**: Verify visual consistency with the design language — tokens, components, both themes. Check at the smallest and largest supported breakpoints and device sizes, and at the largest text size.
- **accessibility-specialist**: Verify compliance against the committed accessibility target documented in `design/accessibility-requirements.md`. Flag any violations as blockers. **If that file is absent (or commits no target) there is no committed target, so this gate has no criterion: report `Accessibility: NOT ASSESSED — no committed target (design/accessibility-requirements.md absent)` (or `— accessibility.target unset` when the file exists without a target) and do NOT report the gate as passed or COMPLIANT**. Carry forward whatever target Phase 1a recorded as assumed, and say plainly that it was assumed. **If the committed target is `none`**, report `Accessibility: N/A — target is none (recorded decision; no conformance claim)` and list the violations found as ADVISORY, not blockers.

All three review streams must report before proceeding to Phase 4b.

### Phase 4b: UI Consistency Review (DD-UI-CONSISTENCY)

Apply the review mode check from Phase 0. When the gate is skipped, write the skip note
(`[DD-UI-CONSISTENCY] skipped — Lean mode` / `— Solo mode`) into the UX spec's header, where
the verdict line would go, after "May I write this to `design/ux/[feature-name].md`?".

When it runs, spawn `design-director` via `Agent`:
- Gate: DD-UI-CONSISTENCY — the `Agent` prompt instructs the agent to read
  `.claude/docs/director-gates/dd-ui-consistency.md` FIRST (do not read it yourself)
- Pass: UX spec path or implemented screen list · design-language path · `design/ux/interaction-patterns.md` path · resolved `accessibility` line
- Parse the first line of the reply as `[DD-UI-CONSISTENCY]: TOKEN` and map the token to its
  class:
  - **APPROVE-class** (`APPROVE`) → proceed to Phase 5.
  - **CONCERNS-class** (`CONCERNS`) → present the adjustments and use `AskUserQuestion`:
    `Revise flagged items` / `Accept and proceed` / `Discuss further`. Accepted concerns are
    listed in the summary report.
  - **REJECT-class** (`REJECT`) → surface the violations; do not proceed to Phase 5 until the
    implementing engineer has resolved them and the gate is re-run.
  - A first line that does not parse, or a token not on the gate's Verdicts line, is not an
    approval: surface the full reply as CONCERNS-class and say the verdict line was missing.

Record the outcome in the UX spec's header after "May I write this to
`design/ux/[feature-name].md`?":
`> **Design Director Review (DD-UI-CONSISTENCY)**: APPROVED [date] / CONCERNS (accepted) [date] / REVISED [date]`.

### Phase 5: Polish

- Address all review feedback
- Verify animations are skippable and respect the user's reduced-motion setting (`prefers-reduced-motion`, iOS Reduce Motion, Android "Remove animations")
- Confirm haptics and sounds follow the design language's `## 7. Motion & Feedback` (no ad-hoc feedback)
- Test at every supported breakpoint (`sm` / `md` / `lg` on web; compact and regular size classes on mobile), in both themes, and at the largest text size
- **Verify `design/ux/interaction-patterns.md` is up to date** — if any new patterns were introduced during this feature's implementation, confirm they have been added to the library
- **Confirm all global elements respect the app shell** defined in `design/ux/app-shell.md` (navigation model, persistent elements, global states such as offline, maintenance and force-update)

## Quick Reference — When to Use Which Skill

- `/ux-design` — Author a new UX spec for a screen, flow, or the app shell from scratch
- `/ux-review` — Validate a completed UX spec before implementation
- `/team-ui [feature]` — Full pipeline from spec through polish (calls `/ux-design` and `/ux-review` internally)
- `/quick-spec` — Small UI changes that don't need a full new UX spec

## Error Recovery Protocol

**First, verify the artifact.** If the return contract named a path, check the
path exists before treating the phase as done — **a named artifact that is not
on disk is a failed phase, however fluent the response reads.** An agent can
burn a full phase and return a plausible preamble having written nothing, which
is neither BLOCKED nor an error nor "cannot complete", so the trigger below
never fires. Resume it naming the unmet contract; the context is
usually still there.

If any spawned agent returns BLOCKED, errors, or cannot complete: **surface it
immediately, don't proceed past a dependency it blocks, and always produce a
partial report.** Full procedure: `.claude/docs/error-recovery-protocol.md`.

Common blockers:
- Input file missing (story not found, PRD absent) → redirect to the skill that creates it
- ADR status is Proposed → do not implement; run `/architecture-decision` first
- The spec calls an operation the API contract lacks → `/api-design reconcile` before Phase 3
- Scope too large → split into two stories via `/create-stories`
- Conflicting instructions between ADR and story → surface the conflict, do not guess

## File Write Protocol

All file writes (UX specs, interaction pattern library updates, implementation files) are
delegated to sub-agents and sub-skills, except the review records this skill adds to the UX
spec. The three follow **different** rules:

- **Sub-agents spawned via `Agent`** follow the **bounded exception** documented above
  under "Why this does not violate the Collaboration Protocol" — the path is one you
  named, the artifact is new under `production/`, `docs/` or `tests/` (evidence
  screenshots), and the phase is gated by an `AskUserQuestion`. A sub-agent does **not**
  prompt per write inside those bounds; outside them it must ask — implementation files
  and anything under `design/` are outside them, so the implementing engineers ask per file.
- **Sub-skills** (`/ux-design`, `/ux-review`) are not sub-agents and the exception does not
  reach them. They follow the normal Collaboration Protocol and ask before writing.
- **This orchestrator** writes only into the UX spec — the visual design notes, the
  DD-UI-CONSISTENCY outcome or skip note — each after "May I write this to
  `design/ux/[feature-name].md`?".

## Output

A summary report covering: UX spec status, UX review verdict, visual design status, implementation status per surface, accessibility compliance, input method support, DD-UI-CONSISTENCY outcome (or its skip note), interaction pattern library update status, every `NOT CHECKED` line, and any outstanding issues.

Verdict: **COMPLETE** — UI feature delivered through full pipeline (UX spec → visual → implementation → review → polish).
Verdict: **NOT ASSESSED** — the pipeline ran to the end, but a required check could not: Phase 4 reported `Accessibility: NOT ASSESSED — no committed target (design/accessibility-requirements.md absent)`, or a required review printed a `NOT CHECKED` line; name each.
Verdict: **BLOCKED** — pipeline halted; surface the blocker and its phase before stopping.

Precedence: BLOCKED > NOT ASSESSED > COMPLETE — never COMPLETE while accessibility is NOT ASSESSED.

## Next Steps

- Run `/ux-review` on the final spec if not yet approved.
- Run `/code-review` on the UI implementation before closing stories.
- Run `/ui-inventory` to record new screens, components and media assets.
- Run `/team-hardening` for a performance, accessibility and UI-consistency hardening pass.
