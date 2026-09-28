> Section-authoring guidance, loaded by `/ux-design` for the ACTIVE MODE ONLY.
> Never load the other two — one mode applies per invocation.

# Section Guidance — UX Spec Mode

This file covers both kinds of spec the `[screen/flow name]` mode writes to
`design/ux/<slug>.md`:

- **Screen specs** — `.claude/docs/templates/ux-spec.md`, Sections A–Q below, in
  template order.
- **Flow specs** — `.claude/docs/templates/user-flow.md`, the "Flow Specs" part at
  the end.

Use the surfaces, input methods and breakpoints resolved in Phase 2h throughout —
do not ask the user for them again. Examples use Moa, a subscription savings app
(web + iOS + Android); replace them with the product's own.

---

## Screen Specs (`ux-spec.md`)

#### Section A: Purpose & User Need

This section is the foundation. Every other decision flows from it.

**Questions to ask**:
- "What user goal does this screen serve? What is the user trying to DO here?"
- "What would go wrong if this screen didn't exist or was hard to use?"
- "Complete this sentence: 'The user arrives at this screen wanting to ___.'"
- "What does the product need from this moment — reassurance, a decision, a
  conversion, data?"

Cross-reference the user journey context gathered in Phase 2. The stated purpose
must fit the lifecycle stage and the user's state on arrival. Reject a purpose
written from the system's perspective ("Displays the goal entity") and ask for the
user's ("Check that this month's debit went through").

---

#### Section B: User Context on Arrival

**Questions to ask**:
- "When in the journey does a user first reach this screen?"
- "What were they doing immediately before — and on which surface?"
- "What state of mind should the design assume? (calm, in a hurry, anxious about
  money, curious)"
- "Do users arrive voluntarily, or are they sent here — by a notification, an
  email, an error, a redirect after sign-in?"

Offer to map this against the lifecycle stages if `design/product/user-journey.md`
exists. For money and identity screens, ask explicitly what the user is worried
about — double charges, losing access, sharing personal data — and design against it.

---

#### Section C: Navigation Position

Where does this screen sit in the product's navigation? This is a short orientation
map, not a flow diagram. The top level comes from `design/ux/app-shell.md` when it
exists.

**Questions to ask**:
- "Which top-level destination does this screen live under?"
- "Is it a page, a modal dialog, a bottom sheet or a side panel — and does that
  differ between web and mobile?"
- "Can the user reach it from more than one place?"

Then define **routes and deep links** — every screen that can be linked to needs
them:
- Web: the route pattern and its parameters; which query parameters (tab, filters)
  are reflected in the URL so the state is shareable and Back works.
- Mobile: the custom-scheme link and the universal / app link; the back stack the
  app synthesizes on deep-link entry (e.g., Goals tab → Goal list → Goal detail).
- For each: auth required? What happens with an unknown or deleted ID (not-found
  state, never a crash or a blank screen)?

Present as: "This screen lives at: [top-level] → [parent] → [this screen]", then the
routes table.

---

#### Section D: Entry & Exit Points

Map every way the user can arrive at and leave this screen.

**Questions to ask**:
- "What are all the ways a user can reach this screen?" (navigation, push
  notification, email or 알림톡 link, search result, redirect after sign-in, share link)
- "What can the user do to leave? What happens when they do?" (Back, confirm,
  cancel, timeout, session expiry)
- "Is any exit irreversible — money moved, data deleted, consent given?"

Present as two tables:

| Entry Source | Trigger | User carries this context |
|---|---|---|
| [screen/event] | [how] | [route params, prefilled state] |

| Exit Destination | Trigger | Notes |
|---|---|---|
| [screen/event] | [how] | [what is committed server-side, what is discarded] |

Every entry needs a matching exit. Flag any exit that loses unsaved input without a
confirmation.

---

#### Section E: Layout Specification

This is the largest and most interactive section. Work through it in steps:

**Step 1 — Information hierarchy** (establish this before any layout; it is
conversation, not a template heading):
- Ask the user to list every piece of information this screen must communicate.
- Then rank: "What is the single most important thing the user needs to see first?
  What is second? What can be discovered rather than shown immediately?"
- Present the resulting hierarchy for approval before moving on.

**Step 2 — Breakpoints** (fills `### Breakpoints`):
- For each covered surface, take the breakpoints from the design language — web
  `sm` / `md` / `lg`, mobile compact / regular. If the design language does not
  define widths yet, write the rows with `[from the design language — TBD]` and add
  an open question; never invent pixel values.
- For each breakpoint, propose what changes: columns, what moves, what collapses
  into a menu or sheet, what becomes sticky.
- Offer 2–3 arrangements for the smallest and the widest breakpoint, with rationale
  tied to the information hierarchy. Use `AskUserQuestion`:
  - "Which arrangement fits best?"
  - Options: [the 2–3 named arrangements you just presented] + "None — build a custom arrangement"
- Record reflow at 320 CSS px and behaviour at 200 % text size, and the safe areas
  (notch, home indicator, keyboard). Amounts, dates and error text must never
  truncate.

**Step 3 — Component inventory** (fills `### Component Inventory`):
- For each region, list the UI components it contains. For each component note:
  - Component type (button, list, card, input field, chart, …)
  - Content it displays
  - Whether it is interactive
  - The component-library component or pattern it reuses (reference by name from
    `design/ux/interaction-patterns.md`)
  - Whether it introduces a new pattern (flag it for the pattern library)
- Name the element that receives focus on open, including on deep-link entry and in
  the empty state.

**Step 4 — Wireframe** (fills `### Wireframe`):
- Offer to generate an ASCII wireframe for the smallest and the widest breakpoint.
- Use `AskUserQuestion`: "Want an ASCII wireframe as part of this spec?"
  - Options: "Yes, include one", "No, I'll link a design file instead"
- If yes, produce the wireframe in conversation first. Ask for feedback before
  writing it to file. If a design file exists (Figma or similar), record its link.

---

#### Section F: Auth & Permission State

Who can see this screen and what happens at each boundary. The app shell owns the
global signed-out and session-expired behaviour; this section records what is
specific to this screen.

**Questions to ask** (one at a time):
- "Can a signed-out user reach this screen — by a deep link, a shared URL? Where do
  they go after signing in?"
- "What does a signed-in user see for a resource that is not theirs?" (Default:
  the not-found state — never reveal that someone else's resource exists.)
- "Is anything here gated by plan (Free / Plus) or role (viewer / editor)? What is
  the upgrade or request-access path?"
- "Does any action need step-up verification — PIN, biometrics, 본인인증?"
- "Does the screen need an OS permission (notifications, camera, photos,
  location)? When is it asked, and what does the denied state look like?"
- "If the session expires mid-edit, is the input preserved?"

Present the rows as the template's table. Flag every state change that the API must
enforce (ownership, plan, role) for the `## API Data` section — the UI hides, the
server decides.

---

#### Section G: States & Variants

Guide the user beyond the happy path.

**Questions to ask** (work through these one at a time):
- "What does this screen look like the very first time, when there is no data yet?
  (empty — first use)"
- "What if a search or filter returns nothing? (empty — no results)"
- "Is there a loading wait? What does it show? (loading — skeleton preferred)"
- "What happens when something goes wrong — a validation error, a timeout, a
  server error, a missing resource? (error — recoverable vs blocking)"
- "What if one of several requests fails? (partial data)"
- "What does the screen do offline — show cached data, queue actions, disable
  them? (offline)"
- "Does anything change by lifecycle stage — first visit, trial, cancelled
  subscription?"
- "Does this screen behave differently on any covered surface?"

Present the collected states as the template table for approval. Every state needs
a trigger that QA can reproduce; the table is also the test matrix.

---

#### Section H: Interaction Map

For each interactive component in the component inventory, define:
- The action (click, tap, long-press, swipe, drag, type, scroll)
- The input(s) that trigger it on each covered surface — keyboard (Enter, Space,
  arrows, Esc), pointer (click, hover), touch (tap, swipe, long-press), screen
  reader (swipe to move, double-tap to activate, custom actions)
- The immediate feedback (visual, haptic — never haptic alone)
- The outcome (navigation target, state change, operation called)

State the input methods upfront: "Mapping interactions for: [input methods resolved
in Phase 2h] on [surfaces]." Work through components one at a time rather than
asking for all at once. For navigation actions, verify the target matches an
existing UX spec or note it as a spec dependency. For every gesture, name its
visible alternative. For every destructive or money-moving action, name the
confirmation pattern.

---

#### Section I: Data Requirements

Cross-reference the PRD `## UI Requirements` and `## API & Data Impact` sections
gathered in Phase 2.

For each piece of information the screen displays, ask:
- "Where does this data come from? Which service or module owns it?"
- "Does this screen change it, or only read it?"
- "Is any of it time-sensitive? What triggers an update — opening the screen, a
  push, polling, a write elsewhere?"
- "How is it formatted? (currency without minor units for KRW, dates per locale,
  masked account numbers)"

Flag any case where the UI would need to own or reconcile server state as an
architectural concern. UX specs define what the UI needs; they do not dictate how
the data is delivered — that is the API contract and the architecture.

Present the data requirements as the template table. Every row with a server source
must map to an operation in the next section.

---

#### Section J: API Data

The contract section: `/api-design reconcile` reads it in Validation, and the
Validation → Build gate checks that every operation listed here exists in the API
contract. Spell the heading exactly `## API Data`.

**Steps**:
1. Derive the operations from Section I: one row per operation the screen calls —
   reads on open, reads on refresh or scroll, and every write.
2. Look each one up in the contract under `docs/api/` (OpenAPI, GraphQL, protobuf or
   AsyncAPI). Found ⇒ `in contract`, with its `operationId` and method + path (or
   operation name). Not found ⇒ `proposed`, with the shape the screen needs.
   Found but the screen needs a different shape (missing field, no pagination,
   N calls where one aggregated call would do) ⇒ `mismatch`, with what differs.
3. For every list: the pagination style (cursor preferred), page size and order.
4. For every write: whether a retry after a timeout must be safe (idempotency key)
   and what the user sees while it is pending.
5. Note aggregation, freshness and realtime needs in the lines under the table.

**Rules**:
- The tech-lead owns the contract. Propose; never mark a proposed operation as
  final, and never edit files under `docs/api/` from this skill.
- If no contract exists yet, every row is `proposed` — that is expected in early
  Validation.
- A screen that needs data it cannot get from any listed operation is a gap: add a
  `proposed` row rather than leaving the data element sourceless.
- Any `proposed` or `mismatch` row means the next step includes
  `/api-design reconcile`.

---

#### Section K: Analytics Events

For every user action in the Interaction Map that matters to a metric, name the
event — or note "no event" explicitly.

**Questions to ask**:
- "Which PRD success metric does this screen move? Which events measure it?"
- "Does `design/product/tracking-plan.md` already define these events?" (Reuse the
  name; otherwise propose one following `naming.events`, e.g. `goal_detail_viewed`.)
- "Are there actions that should deliberately NOT fire an event?"

Present as the template table. Properties carry IDs and enums — flag any property
that would carry personal data (names, emails, phone numbers, account numbers) and
ask for a justification; the default answer is to remove it. New events are
proposed to the tracking plan, not written into it by this skill.

---

#### Section L: Transitions & Animation

Specify how the screen enters and exits, and how it responds to state changes.

**Questions to ask**:
- "On iOS and Android, is the platform's native transition enough?" (It usually is.)
- "On web, does the route change animate at all?"
- "Are there in-screen transitions — loading to populated, success, error — that
  need motion?"
- "Which animations must change under reduced motion?"

Minimum required:
- The transition type for each entry and each exit in the Entry & Exit Points
  tables — the platform's native push or modal on iOS and Android; "none" is a
  valid answer for a web route change
- For each in-screen state change, either its motion token or "instant" — many
  service state changes should be instant, and no animation is required
- A reduced-motion replacement only for the animations that exist; a transition
  that is "none" or "instant" needs none

Take durations and easing from the design language's motion tokens and the pattern
library's Animation Standards; do not invent new values here.

---

#### Section M: Input Method Completeness Checklist

Walk the template checklist for each covered surface with the user. Items that do
not apply to a surface (keyboard shortcuts on a phone-only app) are marked N/A with
the reason — never deleted silently. Any unchecked applicable item blocks the spec
from Approved.

---

#### Section N: Screen-Level Accessibility Requirements

Cross-reference `design/accessibility-requirements.md` (target and requirement
matrix) and the resolved `accessibility` line.

Walk through, for this screen:
- Text and non-text contrast in light and dark themes, against the target's ratios
- Color-independent communication (status, errors, charts)
- Focus order, including where focus lands on open, after an error and after a
  dialog closes
- Screen reader announcements for asynchronous results
- Authentication and timing: paste allowed, password managers and passkeys, no
  puzzle without an alternative, timeouts that warn and extend
- Cognitive load: how many things the user must track at once

If no accessibility target has been committed, note the gap in the spec's
`## Open Questions` section:
> "Accessibility target not yet committed — run `/ux-design accessibility`. The
> Validation → Build gate checks each key spec against the committed target."

Then continue to the next section without stopping. Never assume a level.

---

#### Section O: Localization Considerations

Document constraints that affect the screen when text is translated or formatted
for another locale. Read `localization.locales` from `project.yaml`; if it is unset,
ask which locales ship and note the gap.

**Questions to ask**:
- "Which text elements are the longest? What is the maximum character count the
  layout holds?"
- "Is any text layout-critical — a button label that must stay on one line, a tab
  label?"
- "Which elements show numbers, currency, dates or relative times?"

Notes:
- Korean-to-English expansion can be large for short labels; test every label with
  pseudo-localization in the longest locale rather than applying a fixed percentage.
- Korean line breaking: break between words (`word-break: keep-all` on web).
- Right-to-left layout only when a configured locale needs it.

Mark elements where expansion would break the layout as HIGH risk for the
localization-lead.

---

#### Section P: Acceptance Criteria

Write at least 5 specific, testable criteria that a QA engineer can verify without
reading any other design document. These become the pass/fail conditions for
`/story-done`.

**Format**: checkboxes; each criterion verifiable by a person or an automated test:

```
- [ ] Route is interactive within the budget in project.yaml (performance.lcp_ms / performance.inp_ms) on [reference device]
- [ ] [Element] displays correctly at [minimum] and [maximum] values
- [ ] [Navigation action] routes to [destination], and Back returns here
- [ ] Error state appears when [condition] and shows [specific message]
- [ ] Keyboard and screen-reader users reach every interactive element in logical order
- [ ] [Operation] from ## API Data is called once per [trigger] (network log)
```

**Minimum required**:
- 1 performance criterion (web: Core Web Vitals budgets from `performance.*`;
  mobile: time to interactive on the reference device)
- 1 navigation criterion (an entry or exit path, including a deep link)
- 1 error, empty or offline state criterion
- 1 accessibility criterion (per the committed target)
- 1 criterion specific to this screen's core purpose

Use `AskUserQuestion` to confirm:
- "Do these acceptance criteria cover what would make this screen 'done' for your QA process?"
- Options: "Yes — these are solid", "Add one more criterion", "Remove or rephrase one"

---

#### Section Q: Open Questions

Collect every question raised while authoring, each with an owner and a deadline.
An Approved spec has zero open questions — each is resolved or its deferral is
documented.

---

## Flow Specs (`user-flow.md`)

A flow spec maps a multi-screen task. It does not specify layout; each screen on the
critical path that calls the API gets its own screen spec, and that spec's
`## API Data` carries the operations. Work through the seven sections in order.

#### Flow Section 1: Entry Points & Deep Links

**Questions to ask**:
- "Where can this flow start?" (primary action, empty state, settings, push,
  email, 알림톡 button, shared link, redirect after sign-in)
- "What state does each entry carry in — a template, a prefilled amount, a campaign?"
- "What happens when a signed-out user opens the entry link? Where do they resume?"
- "What happens if the user starts again while a draft exists?"

For links that arrive by push, email or 알림톡, note whether the message is
informational or marketing — marketing messages need recorded advertising consent
per `.claude/docs/compliance/<region>.md` for the regions in `compliance.regions`.

#### Flow Section 2: Critical Path

- Agree the shortest successful route first; draw it as a Mermaid flowchart.
- For each step: the screen (and its spec path, or "inline" for trivial steps),
  what the user does, what the system does, the operation(s) called, and an effort
  budget (inputs, taps, seconds).
- Push back on steps that ask for something the product already knows, and on
  payment or identity steps placed before the user has seen the value.

#### Flow Section 3: Branches & Optional Paths

Every alternative route that still reaches success — registering a payment method,
saving a draft, choosing a template — with the condition that triggers it and where
it rejoins the critical path. Third-party steps (payment registration, identity
verification) always get a designed return and cancel state.

#### Flow Section 4: Decision Points

Every fork. For user decisions: the options, the default, and what information is
on screen when they decide. For system decisions (eligibility, limits, plan gates):
the rule and where it is defined — usually the PRD's `## Business Rules &
Calculations`. Never define a business rule here; reference it.

#### Flow Section 5: Error & Recovery Paths

Walk each step through: network loss, timeout, validation error, session expiry,
duplicate submission, server error, rate limiting, and every third-party step being
cancelled or failing. For each: detection, what the user sees, how they recover and
whether their input survives. Retries of writes must never duplicate — name the
idempotency expectation.

#### Flow Section 6: Exit & Success Criteria

- The success exit: the state that means the user got what they came for.
- Other exits (cancel, abandon, save draft): what is kept and what the user is told.
- Measurable success criteria tied to the PRD's success metric (completion rate,
  time to complete, drop-off per step) — the product-manager confirms the targets.
- Binary acceptance criteria a QA engineer can run.

#### Flow Section 7: Analytics Events

The events that define the flow's funnel, in order, using tracking-plan names or
proposed names following `naming.events`. Every critical-path step should be
observable; properties carry IDs and enums only.

**After the flow is written**: list the critical-path screens that call the API and
have no screen spec yet, and offer to spec each one — the Build gate reads
operations from screen specs' `## API Data` sections, not from flow specs.
