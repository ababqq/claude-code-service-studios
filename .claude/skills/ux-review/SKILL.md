---
name: ux-review
description: "Validate a UX spec, app shell or pattern library. APPROVED / NEEDS REVISION / MAJOR REVISION NEEDED / NOT ASSESSED."
argument-hint: "[file-path | all | shell | patterns] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/ux-review/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,accessibility,surfaces`

Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

## Overview

Validates UX design documents before they enter the implementation pipeline.
Acts as the quality gate between UX Design and Visual Design / Implementation in
the `/team-ui` pipeline, and writes one review record per document to
`design/ux/reviews/<spec-stem>-ux-review-YYYY-MM-DD.md`.

**Run this skill:**
- After completing a UX spec, the app shell or the pattern library with `/ux-design`
- Before handing off to the `frontend-engineer`, `mobile-engineer` or `design-engineer`
- Before the Validation → Build gate (`/gate-check build`), which requires every
  key-screen UX spec to have a `/ux-review` record in `design/ux/reviews/` with the
  verdict APPROVED, or NEEDS REVISION explicitly accepted
- After major revisions to a UX spec

**Verdict levels:**
- **APPROVED** — spec is complete, consistent, and implementation-ready
- **NOT ASSESSED** — one or more review dimensions had no criterion to check
  against, or the spec could not be read; name which
- **NEEDS REVISION** — specific gaps found; fix before handoff but not a full redesign
- **MAJOR REVISION NEEDED** — fundamental issues with scope, user need, or
  completeness; needs significant rework

**`NOT ASSESSED` ranks above APPROVED and below the two revision verdicts.** A
review that could not evaluate a dimension has not shown the spec is
implementation-ready; but a gap somebody found is more actionable than one nobody
could look for, so it must not displace them. Emit it when the spec file cannot
be read, when a checklist dimension has no source of truth to compare against, or
when the accessibility target is uncommitted (below).

The four review dimensions are **Completeness**, **PRD Alignment**,
**Accessibility** and **Pattern Library**. The DD-UI-CONSISTENCY gate (Phase 4a) is
a separate design-director opinion whose outcome is recorded alongside them.

---

## Phase 1: Parse Arguments

- **Specific file path** (e.g., `/ux-review design/ux/goal-detail.md`): validate
  that one document
- **`all`**: find every `design/ux/*.md` (the directory's top level — records in
  `design/ux/reviews/` are never reviewed) and validate each
- **`shell`**: validate `design/ux/app-shell.md` specifically
- **`patterns`**: validate `design/ux/interaction-patterns.md` specifically
- **`--review full|lean|solo`**: overrides the resolved `review_mode` for this run
- **No argument**: ask the user which spec to validate

Identify each document's type from its H1: `# UX Spec:` → Phase 3A;
`# User Flow:` → Phase 3A (flow checklist); `# App Shell:` → Phase 3B;
`# Interaction Pattern Library:` → Phase 3C. A file under `design/ux/` that is none of
these is reported as `NOT ASSESSED — not a UX spec, flow, shell or pattern library`.
`design/accessibility-requirements.md` is not reviewed here — it is the criterion
the others are reviewed against.

For `all`, output a summary table first (file | verdict | primary issue) then
full detail for each.

If the resolved `surfaces` line lists no `web`, `ios` or `android`, report
`NOT ASSESSED — no UI surface configured (platform.surfaces has no web, ios or android)`
and stop.

---

## Phase 2: Load Cross-Reference Context

Before validating any spec, load:

1. **Surfaces and input methods**: the resolved `surfaces` line. Derive the input
   methods the spec must cover — `web`: keyboard, pointer, touch (mobile browsers)
   and screen reader, breakpoints `sm` / `md` / `lg`; `ios` / `android`: touch and
   screen reader, plus keyboard and pointer when the spec claims tablet or foldable
   support, size classes compact / regular. This is the authoritative source for the
   Input Method Coverage checks in Phase 3A — not the spec's own header. If
   `surfaces` is unset, fall back to the spec's `> **Surfaces**:` header and state in
   the record that the coverage check ran against the spec's own claim, not the
   configuration.
2. **The accessibility target**: the resolved `accessibility` line, and the
   `> **Target**:` line of `design/accessibility-requirements.md` (if it exists) with
   its requirement matrix and `## Regional Standards` section. If the two values
   differ, review against the value in `project.yaml` and record the mismatch as an
   ADVISORY issue pointing to `/ux-design accessibility` — this spec cannot fix it,
   but the Architecture → Validation gate checks that the two match.
3. The interaction pattern library at `design/ux/interaction-patterns.md` (if it
   exists)
4. The PRDs referenced in the spec's header (read their `## UI Requirements`
   sections, and the accessibility and localization items of their
   `## Non-Functional Requirements`)
5. The user journey map at `design/product/user-journey.md` (if it exists) for
   context-arrival validation
6. The design language at `design/brand/design-language.md` (if it exists) —
   component, token and breakpoint names
7. The app shell at `design/ux/app-shell.md` (if it exists) — the global states and
   regions screen specs inherit
8. The API contract under `docs/api/` (`openapi*.yaml`, `openapi*.json`,
   `*.graphql`, `*.proto`, `asyncapi*.yaml`) and the tracking plan at
   `design/product/tracking-plan.md` (if they exist) — for the `## API Data` and
   `## Analytics Events` checks

---

## Phase 3A: UX Spec Validation Checklist

Run all checks against a `ux-spec.md`-based document.

### Completeness (required sections)

- [ ] Document header present with Status, Author, Surfaces, Route / Deep Link and
  Accessibility Target
- [ ] Purpose & User Need — has a user-perspective need statement (not
  system-perspective)
- [ ] User Context on Arrival — describes the user's state and prior activity
- [ ] Navigation Position — shows where the screen sits, its presentation, and its
  routes and deep links per surface
- [ ] Entry & Exit Points — all entry sources and exit destinations documented
- [ ] Layout Specification — wireframe, breakpoints for every covered surface
  (`sm` / `md` / `lg`; compact / regular), component inventory table present
- [ ] Auth & Permission State — signed-out, not-the-owner and session-expiry
  behaviour at minimum; plan, role, step-up and OS-permission states where they apply
- [ ] States & Variants — at minimum: loading, empty, populated, error and offline
  states documented
- [ ] Interaction Map — covers all input methods of the covered surfaces
- [ ] Data Requirements — every displayed data element has a source and an owning
  service
- [ ] API Data — the `## API Data` heading is spelled exactly; every operation has
  its owning endpoint, when it is called and its pagination; each is marked
  `in contract`, `proposed` or `mismatch`
- [ ] Analytics Events — every tracked action has an event or an explicit "no event"
- [ ] Transitions & Animation — a transition type for each entry and exit
  (native push or modal, or "none" for a web route change), a motion token or
  "instant" for each in-screen state change, and a reduced-motion replacement
  for each animation that exists
- [ ] Input Method Completeness Checklist — filled for every covered surface
- [ ] Screen-Level Accessibility Requirements — screen-level requirements present
- [ ] Localization Considerations — max character counts for text elements
- [ ] Acceptance Criteria — at least 5 specific testable criteria
- [ ] Open Questions — an Approved-status spec has none

### Quality Checks

**User Need Clarity**
- [ ] Purpose is written from the user's perspective, not the system's
- [ ] The user's goal on arrival is unambiguous ("The user arrives wanting to ___")
- [ ] The context on arrival is specific (not just "they opened the goals list")

**Completeness of States**
- [ ] Error states are documented — recoverable and blocking — not just the happy path
- [ ] Empty states are documented (first use and no results)
- [ ] Loading state is documented if the screen fetches data (skeleton for content regions)
- [ ] Offline behaviour states which reads work from cache and which actions queue or disable
- [ ] Any state with a timer or auto-dismiss is documented with its duration

**Auth & Permissions**
- [ ] A signed-out deep link returns the user to this route after sign-in
- [ ] A resource the user does not own shows the not-found state, not a "forbidden" disclosure
- [ ] Session expiry preserves the user's input
- [ ] OS permissions are asked in context with a pre-permission explanation, and the
  denied state is designed

**Input Method Coverage**
- [ ] If `web` is covered: keyboard-only operation is fully specified, with a focus
  order and no keyboard trap
- [ ] Pointer: hover states defined; targets at least 24×24 CSS px; no hover-only
  information
- [ ] Touch: targets follow platform size (44×44 pt iOS, 48×48 dp Android); no
  gesture conflicts with system back gestures; every gesture has a visible alternative
- [ ] Screen reader: names, roles and states for every control; announcements for
  asynchronous results
- [ ] Every drag interaction has a single-pointer alternative

**Data Architecture**
- [ ] No data element has "UI" listed as the owner (the UI must not own server state)
- [ ] Update triggers are specified for all live data (not just "realtime" — what
  triggers the update?)
- [ ] Null handling is specified for all data elements (what shows when data is
  unavailable?)

**API Data**
- [ ] Every server-sourced row of `## Data Requirements` maps to an operation in
  `## API Data`
- [ ] Every list has a pagination style and page size — no unbounded fetch
- [ ] Every write states its retry expectation (idempotent or not)
- [ ] Operations marked `in contract` exist in the contract under `docs/api/`
  (check by `operationId` or method + path); a missing one is BLOCKING
- [ ] `proposed` and `mismatch` rows are ADVISORY here, with the next step
  `/api-design reconcile` — the Validation → Build gate checks that every operation
  exists in the contract by then

**Accessibility** (against the committed target — see Phase 4b for the no-target rule)
- [ ] The target from `design/accessibility-requirements.md` is matched or exceeded
- [ ] Any target other than `none`: no color-only indicators; text alternatives for
  meaningful images and icons
- [ ] `wcag-a` and above: keyboard operable with no trap, meaningful focus order,
  labels on every input, errors identified in text, name/role/value for custom
  controls, help in a consistent place, no redundant entry within a flow
- [ ] `wcag-aa` and above: contrast ratios specified (4.5:1 text, 3:1 large text and
  non-text UI) in both themes; 200 % text and 320 CSS px reflow; focus visible and
  not obscured by sticky elements; targets at least 24×24 CSS px; status messages
  announced; sign-in without a cognitive test
- [ ] `wcag-aaa`: the AAA criteria the requirements document lists as in scope
- [ ] `none`: no conformance check — blockers found are still listed as ADVISORY
- [ ] The regional standards in the requirements document's `## Regional Standards`
  section are addressed where they add items beyond the target

**PRD Alignment**
- [ ] Every PRD `## UI Requirements` item referenced in the header is addressed in this spec
- [ ] No UI element changes server state without a corresponding PRD requirement
- [ ] No PRD `## UI Requirements` item is missing from this spec (cross-check the
  referenced PRD sections)

**Pattern Library Consistency**
- [ ] All interactive components reference the pattern library (or note they are
  new patterns)
- [ ] No pattern behavior is re-specified from scratch if it already exists in
  the pattern library
- [ ] Any new patterns invented in this spec are flagged for addition to the
  pattern library

**Analytics**
- [ ] Event names reuse the tracking plan or follow the `naming.events` convention
  as proposals
- [ ] No event property carries personal data without a justification

**Localization**
- [ ] Character limits are present for all text-heavy elements
- [ ] Layout-critical text is flagged for expansion in the longest configured locale
- [ ] Numbers, currency and dates use locale formatting (KRW without minor units)

**Acceptance Criteria Quality**
- [ ] Criteria are specific enough for a QA engineer who hasn't seen the design docs
- [ ] Performance criterion present (Core Web Vitals budgets on web; time to
  interactive on mobile)
- [ ] Breakpoint criterion present (renders correctly at each covered breakpoint)
- [ ] No criterion requires reading another document to evaluate

### Flow specs (`user-flow.md`)

For a `# User Flow:` document, run these instead of the Completeness list above
(the quality checks for PRD alignment, accessibility and analytics still apply):

- [ ] Header present with Status, Surfaces, Related PRDs, Screen Specs and Success Metric
- [ ] Entry Points & Deep Links — every entry with its link, the state it carries in
  and signed-out behaviour
- [ ] Critical Path — a flowchart and a step table naming each step's screen spec
  and operations
- [ ] Every critical-path screen that calls the API has its own screen spec with an
  `## API Data` section (BLOCKING when missing — the Build gate reads operations from
  screen specs)
- [ ] Branches & Optional Paths — every third-party step has a designed return and
  cancel state
- [ ] Decision Points — system decisions cite where their rule is defined
- [ ] Error & Recovery Paths — network loss, timeout, validation, session expiry,
  duplicate submission and server error covered; input preserved; writes retry
  without duplicating
- [ ] Exit & Success Criteria — measurable success criteria tied to a PRD metric and
  binary acceptance criteria
- [ ] Analytics Events — the funnel is defined in order

---

## Phase 3B: App Shell Validation Checklist

Run all checks against an `app-shell.md`-based document.

### Completeness

- [ ] Navigation Model — navigation principle, top-level destinations, information
  inventory covering ALL global elements from PRDs with `## UI Requirements`, Back
  behaviour per surface, deep link → back stack mapping
- [ ] Global Regions per Breakpoint — regions defined for every covered surface and
  breakpoint, with safe areas and keyboard behaviour
- [ ] Persistent Elements — every element with its region, visibility rule, data
  source operation, states and accessible name
- [ ] Global States — covers at minimum: signed out, session expired, step-up
  authentication, offline, maintenance, force-update; each triggerable on staging
- [ ] Notifications & Banners — every channel with priority, duration and queue
  behaviour; where each notification lands; when push permission is asked
- [ ] Accessibility — skip link and landmarks (web), route-change focus and
  announcement, tab semantics (mobile), reduced motion, 200 % text
- [ ] Each section ends with its acceptance criteria; the header's Open Questions
  count is zero for an Approved shell

### Quality Checks

- [ ] Mobile tab bars have at most five destinations
- [ ] No sticky region, banner or toast covers the focused element or a screen's
  primary action
- [ ] Every information item in any PRD's `## UI Requirements` is either in the shell
  or explicitly categorized as On Demand or Not in the Shell
- [ ] Badges and unread states have non-color indicators
- [ ] Global banners have queue/priority behavior defined; nothing actionable
  auto-dismisses in under 5 seconds
- [ ] Force-update never blocks a supported version; maintenance retries on an
  interval, not in a tight loop
- [ ] Push permission is asked after a moment of value, never at first launch

### PRD Alignment

- [ ] Every PRD whose `## UI Requirements` names a global element (badge, banner,
  account entry point, search) is represented in the shell (or its absence is
  justified); every screen in `design/inventory/screen-inventory.md` is reachable
  from the navigation model

---

## Phase 3C: Pattern Library Validation Checklist

- [ ] Pattern catalog index is current (matches actual patterns in document)
- [ ] All standard control patterns are specified: button variants, toggle / switch,
  slider, dropdown / select, list item, card / grid item, modal dialog / bottom sheet,
  confirmation dialog, toast / snackbar, tooltip, progress bar, input field, tab bar
  / segmented control, scroll container
- [ ] All service-specific patterns needed by current UX specs are present under
  `## Service-Specific Patterns` (forms and inline validation, data table,
  search / filter / sort, pagination / infinite scroll, date and time picker, file
  upload, payment sheet, OTP / identity verification, permission prompt,
  pull-to-refresh — as the specs use them)
- [ ] Each pattern has: When to Use, When NOT to Use, full state specification,
  accessibility spec covering keyboard, pointer, touch and screen reader, and
  implementation notes naming the component-library component
- [ ] Animation Standards table present, with the reduced-motion overrides
- [ ] No conflicting behaviors between patterns (e.g., Back and Esc behave the same
  in dialogs and sheets; destructive confirmation is consistent; errors use inline
  messages or banners, not toasts)

---

## Phase 4: Output the Verdict

### 4a: Design Director Review (DD-UI-CONSISTENCY)

After the checklists and before the record is written, apply the review mode, then
spawn the gate. The gate is not spawned for a document that could not be read.

**Review-mode check** — use the resolved `review_mode` (a `--review` argument
overrides it for this run):
- `solo` → **skip all gates**. Note: `[DD-UI-CONSISTENCY] skipped — Solo mode`
- `lean` → **skip every gate whose ID does not end in `-PHASE-GATE`**. Note: `[GATE-ID] skipped — Lean mode`
  — DD-UI-CONSISTENCY is therefore skipped: note `[DD-UI-CONSISTENCY] skipped — Lean mode`
- `full` → spawn as normal

Write the skip note in the record where the gate outcome line would go (4b). A
skipped gate is reported by name — never omitted.

**Spawn** `design-director` via `Agent`:
- Gate: DD-UI-CONSISTENCY — the `Agent` prompt instructs the agent to read
  `.claude/docs/director-gates/dd-ui-consistency.md` FIRST (do not read it yourself)
- Pass: UX spec path or implemented screen list · design-language path · `design/ux/interaction-patterns.md` path · resolved `accessibility` line
  - UX spec path or implemented screen list → the reviewed document's path
    (the shell or pattern library path when that is what is reviewed)
  - design-language path → `design/brand/design-language.md`, or `none` when it does
    not exist
  - `design/ux/interaction-patterns.md` path → that path, or `none` when it does not
    exist
  - resolved `accessibility` line → copied exactly as the bootstrap block printed it,
    including the unset form
- Parse the first line of the reply as `[DD-UI-CONSISTENCY]: TOKEN` (APPROVE /
  CONCERNS / REJECT) and map the token to its class
  (`.claude/docs/director-gates.md` § Standard Verdict Format). A reply whose first
  line does not parse is treated as CONCERNS-class, with the note that the verdict
  line was missing.

For `all`, apply the mode check once, then spawn one gate per document in parallel
(issue all `Agent` calls before waiting for any result) and collect every verdict
before writing records.

**Handling the three classes**:
- **APPROVE-class** → proceed. Outcome line: `APPROVED [date]`.
- **CONCERNS-class** → surface the findings with `AskUserQuestion` — options:
  "Revise flagged items", "Accept and proceed", "Discuss further". Accepted: the
  findings are listed as ADVISORY issues and the outcome line is
  `CONCERNS (accepted) [date]`. Revise: the findings become BLOCKING issues (the
  verdict is at most NEEDS REVISION) and the outcome line is `CONCERNS [date] —
  revision requested`; a later `/ux-review` of the revised document records
  `REVISED [date]` once the gate returns APPROVE-class.
- **REJECT-class** → the findings are BLOCKING issues and the verdict cannot be
  APPROVED (NEEDS REVISION, or MAJOR REVISION NEEDED when the findings are
  fundamental). The record is still written — it is the evidence of the review.
  Outcome line: `REJECT [date]`.

### 4b: Write the Review Record

Assemble the record, show it in conversation, then ask:
"May I write this to `design/ux/reviews/<spec-stem>-ux-review-YYYY-MM-DD.md`?"

`<spec-stem>` is the reviewed file's name without `.md` (`goal-detail`,
`app-shell`, `interaction-patterns`). For `all`, list every record path and ask once
for the whole set — a multi-file write is approved as one changeset. If a record with
the same path exists, ask before replacing it. This skill never edits the document it
reviews.

```markdown
# UX Review: [Document Name]

> **Verdict**: APPROVED | NEEDS REVISION | MAJOR REVISION NEEDED | NOT ASSESSED
> **Date**: [YYYY-MM-DD]
> **Reviewer**: ux-review skill
> **Document**: [file path]
> **Surfaces**: [resolved surfaces line — or the spec header, marked "assumed from the spec"]
> **Accessibility Target**: [resolved accessibility line; requirements document Target line]
> **Design Director Review (DD-UI-CONSISTENCY)**: [APPROVED [date] / CONCERNS (accepted) [date] / CONCERNS [date] — revision requested / REJECT [date] / REVISED [date] — or the skip note, e.g. `[DD-UI-CONSISTENCY] skipped — Lean mode`]

## Completeness: [X/Y sections present]
- [x] Purpose & User Need
- [ ] States & Variants — MISSING: offline state not documented

## Quality Issues: [N found]
1. **[Issue title]** [BLOCKING / ADVISORY]
   - What's wrong: [specific description]
   - Where: [section name]
   - Fix: [specific action to take]

## PRD Alignment: [ALIGNED / GAPS FOUND / NOT ASSESSED]
- PRD [path] UI Requirements — [X/Y requirements covered]
- Missing: [list any uncovered PRD requirements]

## Accessibility: [COMPLIANT / GAPS / NON-COMPLIANT / NOT ASSESSED / N/A — target is none]
- Target: [value]
- [list specific accessibility findings]

## Pattern Library: [CONSISTENT / INCONSISTENCIES FOUND / NOT ASSESSED]
- [findings]

## API Data Check: [N in contract · N proposed · N mismatch · N missing from the contract]
- [findings; next step `/api-design reconcile` when any row is proposed or mismatch]

## Summary
**Blocking issues**: [N] — must be resolved before implementation
**Advisory issues**: [N] — recommended but not blocking
**Dimensions not assessed**: [N] — [name each, and what would make it checkable]

[For APPROVED]: This spec is ready for handoff to `/team-ui` Phase 2
(Visual Design).

[For NOT ASSESSED]: [N] of the four review dimensions could not be evaluated:
[name them]. The spec may well be sound — this review cannot say either way for
those dimensions. [For each: the one input that would make it checkable.]
Handoff to `/team-ui` is not recommended on this result.

[For NEEDS REVISION]: Address the [N] blocking issues above, then re-run
`/ux-review`.

[For MAJOR REVISION NEEDED]: The spec has fundamental gaps in [areas].
Recommend returning to `/ux-design` to rework [sections].
```

The `> **Verdict**:` line sits directly under the H1 and one blank line, with
exactly one token — `/gate-check` reads it.

> **If `design/accessibility-requirements.md` is absent, or its target is not
> committed, there is no criterion for the Accessibility dimension.** Report
> `Accessibility: NOT ASSESSED — no committed target (design/accessibility-requirements.md absent)`
> (or `— accessibility.target unset`) and do NOT report it as COMPLIANT — a check
> compared against an absent standard passes the way an assertion that can never
> fail passes. The same rule lives in `/team-ui` and is mirrored here so the two
> cannot drift. If the spec's own header states a target, carry it forward as an
> **assumption** and say plainly that it was assumed rather than committed.
> Recommend `/ux-design accessibility` to commit the target.
>
> A target of `none` **is** committed — a recorded decision, not a gap. There is no
> conformance claim to check, so report
> `Accessibility: N/A — target is none (recorded decision; no conformance claim)`,
> list any blockers you found as ADVISORY issues, and leave the dimension out of the
> verdict. Never report COMPLIANT against `none`.

**NEEDS REVISION accepted.** After a NEEDS REVISION verdict — before the record is
written, so the one approved write carries the answer — ask with
`AskUserQuestion` whether to proceed anyway — options: "Revise first
(recommended)", "Accept the risk and proceed". If the user accepts, add the line
`> **Risk Accepted**: [YYYY-MM-DD] — NEEDS REVISION accepted by the user; the
blocking issues below remain open` to the record's header block (below the verdict
line; the verdict token stays NEEDS REVISION). This is the explicit acceptance the
Validation → Build gate looks for. Never record an acceptance the user did not give.

---

## Phase 5: Collaborative Protocol

This skill never edits or writes the document it reviews. Its only writes are the
review records under `design/ux/reviews/`, each after "May I write this to
`<path>`?".

After delivering the verdict:
- For **APPROVED**: suggest running `/team-ui` to begin implementation coordination
- For **NOT ASSESSED**: name the missing input per dimension and offer to help
  produce it (`/ux-design accessibility` for an uncommitted target, the PRD path
  for absent UI requirements, `/ux-design patterns` for an absent pattern library,
  `/setup-stack` for unset surfaces). Do not re-run the review against the same
  missing inputs and report a different verdict — only new inputs change this one
- For **NEEDS REVISION**: offer to help fix specific gaps ("Would you like help
  drafting the missing offline state with `/ux-design`?") — but do not auto-fix; wait
  for user instruction
- For **MAJOR REVISION NEEDED**: suggest returning to `/ux-design` with the
  specific sections to rework
- When `## API Data` has `proposed` or `mismatch` rows: suggest `/api-design reconcile`

Never block the user from proceeding — the verdict is advisory. Document risks,
present findings, let the user decide whether to proceed despite concerns. A user
who chooses to proceed with a NEEDS REVISION spec takes on the documented risk, and
the record says so (Phase 4b).

Close with `AskUserQuestion` offering the next steps that apply:
- `/ux-design [section or screen]` — fix the blocking issues
- `/ux-review [file]` — re-review after revisions
- `/api-design reconcile` — when API Data rows are proposed or mismatch
- `/team-ui` — when the verdict is APPROVED
- `/gate-check build` — when every key-screen spec has a record with APPROVED or an
  accepted NEEDS REVISION
