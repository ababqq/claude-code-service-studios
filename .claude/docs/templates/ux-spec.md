# UX Spec: [Screen Name]

> Authoring guidance: `.claude/docs/templates/guidance/ux-spec-guide.md` (load per-section as you author — do not read entirely).

> **Status**: Draft | In Review | Approved | Implemented
> **Author**: [Name or agent — e.g., product-designer]
> **Last Updated**: [YYYY-MM-DD]
> **Screen ID**: [Identifier used in code, routes and tickets — e.g., `GoalDetailScreen`, `goal-detail`]
> **Surfaces**: [The subset of `platform.surfaces` this spec covers — `web` | `ios` | `android`]
> **Route / Deep Link**: [e.g., web `/goals/:goalId` · app `moa://goals/{goalId}` · universal / app link `https://moa.example/goals/{goalId}`]
> **Journey Stage(s)**: [From `design/product/user-journey.md` — e.g., Onboarding / Activation, Habit]
> **Related PRDs**: [The PRD sections that generated this screen — e.g., `design/prd/goals.md` § UI Requirements]
> **Related ADRs**: [Decisions that constrain this screen — e.g., `docs/architecture/adr-0001-identity-and-auth.md`]
> **Related UX Specs**: [Parent, sibling and flow specs — e.g., `design/ux/goal-create.md`, and the app shell `design/ux/app-shell.md`]
> **Accessibility Target**: [The committed `accessibility.target` from `design/accessibility-requirements.md` — `none` | `wcag-a` | `wcag-aa` | `wcag-aaa` — plus the regional standards listed there]
> **Design Source**: [none — markdown spec only | claude-design — <locator> · record `design/handoff/<slug>/HANDOFF.md` | figma — <node URL> · record `design/handoff/<slug>/HANDOFF.md` — the first token is exactly `none`, `claude-design` or `figma`; the record is written by `/design-handoff`]

> **Note — Scope boundary**: This template covers one screen — a page, a modal, a
> bottom sheet or a settings panel — on every surface it ships on. Global UI that
> persists across screens (navigation bar, tab bar, account menu, global banners,
> maintenance and force-update states) belongs in the app shell
> (`app-shell.md` → `design/ux/app-shell.md`); reference it here instead of
> re-specifying it. A multi-screen task (sign-up, checkout, goal creation) is
> mapped with `user-flow.md`, and each screen on its critical path that calls the
> API gets its own spec from this template.

---

## Purpose & User Need

**What user need does this screen serve?**

[One paragraph — the real need from the user's perspective, not the system function. "The user wants to see whether this month's auto-debit went through and how close they are to the goal" — not "displays goal entity". See the guide's section of the same name for good and bad examples.]

**The user goal** (what the user wants to accomplish here):

[One sentence, specific enough to write an acceptance criterion for.]

**The product goal** (what the product needs to communicate or capture):

[One sentence — e.g., "Reassure the user the savings plan is working and surface the next scheduled debit before it happens."]

---

## User Context on Arrival

| Question | Answer |
|----------|--------|
| What was the user just doing? | [Prior activity or trigger — e.g., tapped a push notification "₩50,000 saved toward Travel"] |
| What is their state of mind? | [Calm / in a hurry / anxious about money / curious] |
| What cognitive load are they carrying? | [High / low + what they are tracking] |
| What information do they already have? | [Known context on arrival] |
| What are they most likely trying to do? | [Primary use case] |
| What are they worried about? | [Risks and anxieties to design against — e.g., "Did I get charged twice?"] |

**Experience target for this screen**:

[One sentence describing how the user should feel while using this screen — e.g., "In control of their money, never surprised by a charge."]

---

## Navigation Position

**Screen hierarchy** (use indentation to show parent–child relationships; the top level is defined by `design/ux/app-shell.md`):

```
[Top-level destination — e.g., Goals tab]
  └── [Parent screen — e.g., Goal list]
        └── [This screen — e.g., Goal detail]
              ├── [Child — e.g., Edit goal (bottom sheet)]
              └── [Child — e.g., Pause auto-debit (confirmation dialog)]
```

**Presentation**: [Full page | Modal dialog | Bottom sheet | Side panel / drawer | Full-screen modal (mobile)]

> If this screen is modal: document every dismiss path — Esc, browser Back, Android
> system Back, iOS swipe-down on a sheet, tap outside — and what happens to unsaved
> input on each. A modal that cannot be dismissed is high-friction — justify it.

**Routes and deep links**:

| Surface | Route / Link | Parameters | Auth Required? | Back Stack on Deep-Link Entry | Notes |
|---------|--------------|------------|----------------|-------------------------------|-------|
| [web] | [`/goals/:goalId`] | [`goalId` — opaque ID] | [Yes] | [Browser history as-is; in-app Back goes to `/goals`] | [Shareable URL? Query params reflected, e.g. `?tab=history`] |
| [ios / android] | [`moa://goals/{goalId}` · `https://moa.example/goals/{goalId}`] | [`goalId`] | [Yes] | [Synthesized: Goals tab → Goal list → this screen] | [Unknown or deleted ID → not-found state] |

**Reachability — all entry points**:

| Entry Point | Triggered By | Notes |
|-------------|--------------|-------|
| [Entry point] | [Trigger — navigation, push notification, email link, 알림톡 button, search result] | [Notes] |

---

## Entry & Exit Points

> Every entry point must have a corresponding exit point. Empty cells are a sign
> that design work is unfinished. See the guide's section of the same name for
> worked examples.

**Entry table**:

| Trigger | Source Screen / State | Transition Type | Data Passed In | Notes |
|---------|----------------------|-----------------|----------------|-------|
| [Trigger] | [Source] | [Push / modal / replace / deep link] | [Route params, state] | [Notes] |

**Exit table**:

| Exit Action | Destination | Transition Type | Data Returned / Committed | Notes |
|-------------|-------------|-----------------|---------------------------|-------|
| [Exit action] | [Destination] | [Transition] | [What was saved server-side, what is discarded] | [Irreversible? Confirmation required?] |

---

## Layout Specification

### Wireframe

> With an external Design Source (claude-design or figma), the drawing may be
> replaced by the line "external: see Design Source — screens listed from the
> handoff record", followed by one line per breakpoint naming the retained screen
> under `design/handoff/<slug>/screens/` (or the frame / node locator for a
> `LINK ONLY` record). Keep the **Hierarchy** line below either way — reviewers
> without the design tool read the layout from it. A record whose verdict is
> `NOT ASSESSED`, or no record, never replaces the drawing.

```
[Draw the layout for the smallest breakpoint first, then the widest, using ASCII art.
 Suggested characters:
 ┌ ┐ └ ┘ │ ─    for borders
 ╔ ╗ ╚ ╝ ║ ═    for emphasized / modal borders
 [ ]              for interactive elements (buttons, inputs)
 { }              for content areas (lists, cards, images)
 ...              for scrollable content
 ●                for the element that receives focus on open

 See the guide's Layout Specification section for a completed example.]
```

**Hierarchy**: [A short text description of the layout, region by region in priority order — kept with an ASCII wireframe and with an external Design Source alike]

### Breakpoints

> Breakpoint widths and size classes come from the design language
> (`design/brand/design-language.md`); do not invent values here. Include only the
> surfaces this spec covers.

| Surface | Breakpoint / Size Class | Width Range | Layout | Elements Hidden, Moved or Collapsed |
|---------|------------------------|-------------|--------|-------------------------------------|
| web | `sm` | [from the design language — e.g., < 640 CSS px] | [Single column; primary action sticky at the bottom] | [Side summary moves below the list] |
| web | `md` | [e.g., 640–1023 CSS px] | [Layout] | [Changes] |
| web | `lg` | [e.g., ≥ 1024 CSS px] | [Two panes: list + detail] | [Changes] |
| ios / android | compact | [Phone portrait] | [Layout] | [Changes] |
| ios / android | regular | [Tablet, unfolded foldable, landscape] | [Layout] | [Changes] |

**Reflow and text scaling**: [What happens at 320 CSS px width and at 200 % text size (browser zoom, iOS Dynamic Type accessibility sizes, Android font scale) — what wraps, what truncates, what must never truncate (amounts, dates, error text).]

**Safe areas**: [Notch, home indicator, Android navigation bar, on-screen keyboard — which elements move above the keyboard.]

### Component Inventory

> List every discrete UI component on this screen. This table drives the
> implementation task list — each row becomes a component to build or reuse from
> the component library.

| Component Name | Type | Region | Purpose | Required? | Reuses Existing Component or Pattern? |
|----------------|------|--------|---------|-----------|---------------------------------------|
| [Component] | [Type] | [Region] | [Purpose] | [Yes/No] | [Yes — component library name or pattern name from `design/ux/interaction-patterns.md`, or No — new (flag it)] |

**Primary focus element on open**: [The element that receives focus when the screen opens — including deep-link entry and the empty state]

---

## Auth & Permission State

> Who can see this screen, in which state, and what happens at each boundary. The
> app shell defines the global signed-out and session-expired behaviour; this
> section records what is specific to this screen.

| State | Condition | What the Screen Shows | Actions Allowed | Redirect / Recovery |
|-------|-----------|-----------------------|-----------------|---------------------|
| Signed out | [No session — e.g., a deep link opened after sign-out] | [Nothing — redirect] | [—] | [Sign in, then return to this route with its parameters] |
| Signed in — owner | [Resource belongs to the user] | [Full screen] | [All] | [—] |
| Signed in — not the owner | [Resource belongs to someone else, or does not exist] | [Not-found state — never reveal that the resource exists] | [Back / Home] | [—] |
| Plan-gated | [e.g., Free plan opening a Plus-only feature] | [Preview + upgrade explanation] | [Upgrade, dismiss] | [Upgrade flow returns here] |
| Role-gated | [e.g., admin console viewer vs editor] | [Read-only controls hidden or disabled with a reason] | [Read] | [Request access] |
| Session expired mid-action | [Token refresh fails while the user is editing] | [Re-authentication sheet over the screen] | [Re-authenticate, cancel] | [Input preserved; the action resumes after sign-in] |
| Step-up required | [Sensitive action — e.g., changing the auto-debit account] | [PIN / biometric / 본인인증 prompt] | [Verify, cancel] | [Cancel keeps the previous value] |
| OS permission — [notifications / camera / photos / location] | [Not asked / granted / denied] | [Pre-permission explanation before the system prompt; denied state with a path to system settings] | [Continue without, open settings] | [Re-check on return from settings] |

---

## States & Variants

> Document every state before implementation — at minimum loading, empty,
> populated, error and offline. The states table is also the test matrix for QA.
> With an external Design Source, the Notes column names each state's screen from
> the handoff record, and a state the design lacks is still specified here (the spec
> wins on behaviour). See the guide's section of the same name for a worked example.

| State Name | Trigger | What Changes Visually | What Changes Behaviorally | Notes |
|------------|---------|-----------------------|---------------------------|-------|
| Loading | [First fetch in flight] | [Skeleton matching the populated layout — not a spinner for content regions] | [What stays interactive] | [Minimum display time to avoid flicker] |
| Empty — first use | [No data yet] | [Value explanation + one primary action — e.g., "Create your first goal"] | [—] | [—] |
| Empty — no results | [Search or filter returns nothing] | [What was searched, how to widen it] | [Clear filters] | [—] |
| Populated | [Data loaded] | [—] | [—] | [—] |
| Partial data | [One of several requests failed] | [Failed region shows an inline error; others render] | [Retry the failed region only] | [—] |
| Error — recoverable | [Validation error, 4xx, timeout] | [Inline message next to the cause] | [Input preserved; retry] | [Message from the ux-writer] |
| Error — blocking | [5xx, contract mismatch, not found] | [Full-screen error with a way out] | [Retry / go home / contact support] | [—] |
| Offline | [No connectivity] | [Cached data marked as possibly stale; offline indicator from the app shell] | [Which actions queue, which are disabled] | [How sync conflicts surface on reconnect] |
| Refreshing | [Pull-to-refresh / background revalidation] | [Refresh indicator; content stays visible] | [—] | [—] |
| Success confirmation | [Action completed] | [Toast / inline confirmation] | [Announced to screen readers] | [—] |
| [Other] | [Trigger] | [Visual changes] | [Behavioral changes] | [Notes] |

---

## Interaction Map

> Cover every input method for the surfaces this spec targets: keyboard, pointer,
> touch and screen reader. Gaps in this table are bugs waiting to happen. See the
> guide's section of the same name.

### Navigation Inputs

| Input | Surface | Action | Visual Response | Haptic | Notes |
|-------|---------|--------|-----------------|--------|-------|
| [Tab / Shift+Tab · arrow keys · pointer click · tap · swipe · screen-reader swipe right / double-tap] | [web / ios / android] | [Action] | [Visual response] | [Haptic, if any — never the only feedback] | [Notes] |

### Action Inputs

| Input | Surface | Context (What Must Be Focused) | Action | Response | Animation | Haptic | Notes |
|-------|---------|-------------------------------|--------|----------|-----------|--------|-------|
| [Input] | [Surface] | [Focus context] | [Action] | [Response] | [Animation + timing] | [Haptic] | [Notes] |

### State-Specific Behaviors

| State | Input Restriction | Reason |
|-------|-------------------|--------|
| [State — e.g., submitting] | [Which inputs are disabled — e.g., the submit button, to prevent a duplicate charge] | [Why] |

---

## Data Requirements

> UI reads data; it does not own it. UI calls operations; it does not write server
> state directly. Every displayed data element needs a source operation and an
> owning service or module. See the guide's section of the same name.

| Data Element | Source (Operation or Local State) | Update Trigger | Owner (Service / Module) | Format | Null / Missing Handling |
|--------------|-----------------------------------|----------------|--------------------------|--------|-------------------------|
| [Data element] | [An operation from `## API Data`, or device-local state] | [On open / on refresh / push / polling interval — a specific trigger, not "realtime"] | [Owning service — never the UI] | [Type and display format — e.g., KRW amount, no minor units: "12,500원"] | [What shows when data is unavailable] |

> **Rule**: This screen never writes directly to any store listed above. Every user
> action that changes server state calls an operation listed in `## API Data`; the
> owning service updates its data and the screen re-reads it.

---

## API Data

> Read by `/api-design reconcile` and by the Validation → Build gate: every
> operation listed here must exist in the API contract under `docs/api/`, or be
> reconciled into it. List what the screen needs; the tech-lead owns the contract,
> so operations missing from it are marked `proposed`, never invented as final.

| Operation | Endpoint (Owning) | Called When | Data Used on Screen | Pagination | Auth | Contract Status |
|-----------|-------------------|-------------|---------------------|------------|------|-----------------|
| [`operationId` — e.g., `getGoal`] | [`GET /v1/goals/{goalId}` — or the GraphQL / gRPC operation; owning service] | [On open; on pull-to-refresh] | [Fields rendered] | [none] | [Signed-in owner] | [in contract / proposed / mismatch] |
| [e.g., `listGoalDeposits`] | [`GET /v1/goals/{goalId}/deposits`] | [On open; on scroll end] | [Date, amount, status per row] | [Cursor — `limit=20`, `cursor`; newest first] | [Signed-in owner] | [proposed] |

**Writes**: [State-changing operations the screen triggers and their retry expectation — e.g., `POST /v1/goals/{goalId}/pause` sent with an `Idempotency-Key` so a retry after a timeout never pauses twice.]

**Aggregation**: [If first paint needs several resources, say whether one aggregated operation is proposed instead of several calls — `/api-design reconcile` decides.]

**Freshness**: [Cache and revalidation behaviour — e.g., show cached data, revalidate on focus; refetch after any write on this screen.]

**Realtime**: [Polling interval, server-sent events, WebSocket, push-triggered refresh — or "none".]

---

## Analytics Events

> Event names follow the `naming.events` convention and the event table in
> `design/product/tracking-plan.md`; a new event is proposed there, not invented
> here. See the guide's section of the same name for a worked example.

| User Action | Event | Properties | PII? | Tracking-Plan Status |
|-------------|-------|------------|------|----------------------|
| [Opens the screen] | [`goal_detail_viewed`] | [`goal_id`, `entry_point`] | [No] | [existing / proposed] |
| [Action] | [Event] | [Properties — IDs and enums, never names, emails, phone numbers or account numbers] | [No / Yes — justify] | [Status] |

---

## Transitions & Animation

> State the transition type for each entry and exit — the platform's native push
> or modal on iOS and Android; "none" is a valid answer for a web route change —
> and, for each in-screen state change, either its motion token or "instant".
> Give reduced-motion behavior (`prefers-reduced-motion` on web, Reduce Motion on
> iOS, Remove animations on Android) only for the animations that exist. See the
> guide's section of the same name.

| Transition | Trigger | Direction / Type | Duration (ms) | Easing | Interruptible? | Under Reduced Motion |
|------------|---------|------------------|---------------|--------|----------------|----------------------|
| [Screen enter / exit / in-screen transition] | [Trigger] | [Native push / modal / none / instant / type] | [ms — from the design language; platform default; — for none or instant] | [Easing token] | [Yes/No] | [Replaced by a fade / instant; — when nothing animates] |

---

## Input Method Completeness Checklist

> Fill this checklist before marking the spec as Approved. Any unchecked item that
> applies to a covered surface blocks implementation start.

**Keyboard** (web; tablets and desktops with a hardware keyboard)
- [ ] All interactive elements are reachable using Tab, Shift+Tab and arrow keys alone
- [ ] Tab order follows the visual reading order within each region
- [ ] Every action achievable by pointer or touch is also achievable by keyboard
- [ ] Focus is always visible and never hidden under a sticky header, bottom bar, cookie banner or bottom sheet
- [ ] Focus stays inside an open modal or sheet and returns to its trigger on close
- [ ] Esc closes or cancels without discarding unsaved input silently
- [ ] Single-key shortcuts (if any) can be turned off or remapped

**Pointer**
- [ ] Hover and pressed states defined for all interactive elements
- [ ] Hit targets are at least 24×24 CSS px (primary actions larger)
- [ ] No information is available only on hover; hover content can be dismissed and hovered
- [ ] Every drag interaction has a single-pointer alternative (e.g., "Move up / Move down" for reordering)
- [ ] Scroll behavior defined in all scrollable regions

**Touch** (mobile web, iOS, Android)
- [ ] Touch targets follow platform size — 44×44 pt on iOS, 48×48 dp on Android
- [ ] Gestures do not conflict with system gestures (iOS edge swipe-back, Android back gesture, pull-to-refresh vs. scroll)
- [ ] Every gesture has a visible control alternative
- [ ] Primary actions are reachable one-handed on compact layouts
- [ ] Orientation is not locked unless essential
- [ ] Long-press behavior defined if used

**Screen reader** (VoiceOver on iOS and macOS, TalkBack, NVDA / JAWS)
- [ ] Every control exposes a name, role and value; icon-only buttons have labels
- [ ] Reading order matches visual order; headings and landmarks structure the screen
- [ ] Asynchronous results (saved, failed, deposit confirmed) are announced without moving focus
- [ ] Focus moves to new content that requires attention (dialog, error summary) and returns afterwards
- [ ] Custom controls (sliders, segmented controls, charts) expose adjustable actions or a text equivalent

---

## Screen-Level Accessibility Requirements

> Project-wide commitments live in `design/accessibility-requirements.md` — consult
> it before filling this section so you do not duplicate or contradict them. This
> section records what is specific to this screen, measured against the target in
> the header (`accessibility.target`, WCAG 2.2).

**Text contrast requirements for this screen** (both light and dark themes):

| Text Element | Background Context | Required Ratio | Current Ratio | Pass? |
|--------------|-------------------|----------------|---------------|-------|
| [Text element] | [Background — theme] | [4.5:1 body text, 3:1 large text and non-text UI at `wcag-aa`] | [TBD] | [ ] |

**Color-independent communication**:

| Element | Where Color Carries Meaning | Non-Color Indicator |
|---------|-----------------------------|---------------------|
| [e.g., deposit status] | [Green = succeeded, red = failed] | [Icon + text label "Failed"] |

**Focus order** (numbered sequence):

[Numbered focus sequence covering every interactive element, including where focus lands on open, after an error and after a dialog closes — see the guide's section of the same name for an example]

**Screen reader announcements for key state changes**:

| State Change | Announcement Text | Announcement Timing |
|--------------|------------------|---------------------|
| [e.g., goal saved] | ["Goal saved"] | [After the save operation succeeds; polite] |

**Authentication and timing**: [If this screen signs the user in, verifies identity or runs a timer: paste allowed into password and one-time-code fields, password managers and passkeys supported, no puzzle without an alternative, session timeouts warn and can be extended, one-time-code timers offer an easy resend.]

**Cognitive load assessment**:

[Count the concurrent pieces of information the user must track on this screen, compare against the 7±2 limit and state mitigations — see the guide's section of the same name for an example]

---

## Localization Considerations

**General rules for this screen**:
- Every text element tolerates the expansion of the longest locale in `localization.locales` — verify with pseudo-localization, not by eye
- Korean text breaks between words, not inside them (`word-break: keep-all` on web; check line breaking on iOS and Android)
- Numbers, currency, dates and relative times use locale formatting — KRW has no minor units ("12,500원"); a `ko-KR` date reads "2026. 10. 14."
- Plurals and gendered forms use ICU message syntax; never concatenate strings
- Right-to-left layout is required only when a locale in `localization.locales` needs it — document which elements mirror
- No text in images — all text comes from localization strings

| Text Element | Base-Locale Length | Max Characters | Expansion Budget | Line / Overflow Behavior | Risk |
|--------------|-------------------|----------------|------------------|--------------------------|------|
| [Text element] | [chars] | [max chars] | [%] | [Wrap / truncate with full text available / shrink — never truncate amounts] | [Low/Medium/High] |

---

## Acceptance Criteria

> Write criteria a QA engineer can verify independently, without asking the designer
> what they meant. Every criterion is binary — pass or fail, not subjective.

**Performance**
- [ ] Web: the route meets the Core Web Vitals budgets in `project.yaml` (`performance.lcp_ms`, `performance.inp_ms`, `performance.cls`, p75) on the reference device and network [specify]
- [ ] Mobile: the screen is interactive within [X] ms of navigation on the reference device [specify]
- [ ] Scrolling a fully populated list shows no visible jank on the reference device

**Layout & Rendering**
- [ ] Displays correctly (no overlap, cutoff or horizontal scroll) at every breakpoint in `### Breakpoints`
- [ ] Content reflows at 320 CSS px width and at 200 % text size without loss of content or function
- [ ] No text overflow or truncation in the base locale within the defined max-character bounds
- [ ] No text overflow or truncation in the longest locale [specify]
- [ ] Every state in `## States & Variants` renders correctly, in light and dark themes

**Input**
- [ ] All interactive elements are reachable and operable by keyboard alone (web)
- [ ] All interactive elements are operable by pointer and by touch on the covered surfaces
- [ ] All interactive elements are reachable and operable with VoiceOver and TalkBack (and NVDA on web)
- [ ] No action requires a gesture or simultaneous input that is not documented in `## Interaction Map`

**Auth & Permissions**
- [ ] A signed-out deep link to this screen returns here, with its parameters, after sign-in
- [ ] A user who does not own the resource sees the not-found state
- [ ] Session expiry during an edit preserves the user's input after re-authentication

**API & Data**
- [ ] The screen calls exactly the operations listed in `## API Data`, at the documented moments (verify in the network log)
- [ ] Lists are paginated as documented — no unbounded fetch
- [ ] Retrying a write after a timeout does not duplicate it
- [ ] Offline behaviour matches `## States & Variants`

**Analytics**
- [ ] Each event in `## Analytics Events` fires once per action with the documented properties (verify in the analytics debugger)
- [ ] No event property contains personal data unless the tracking plan marks it as PII and justifies it

**Accessibility**
- [ ] All text and non-text contrast meets the ratios in `## Screen-Level Accessibility Requirements`, in both themes
- [ ] No information relies on color alone
- [ ] Documented state changes are announced by the screen reader
- [ ] Reduced motion replaces animated transitions as documented
- [ ] An automated accessibility scan (e.g., axe) reports no violations at the target level

**Localization**
- [ ] No text element overflows its container in any locale in `localization.locales`
- [ ] All display text comes from localization strings — no hardcoded text
- [ ] Numbers, currency and dates are formatted per locale

---

## Open Questions

> Track unresolved design questions here. Each question has an owner and a deadline.
> An Approved spec has zero open questions — resolve each or document the deferral
> rationale.

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| [Add question] | [Owner] | [Deadline] | [Resolution] |
