# Interaction Pattern Library: [Product Name]

> Authoring guidance: `.claude/docs/templates/guidance/interaction-pattern-library-guide.md` (load per-section as you author — do not read entirely).

> **Status**: Draft | Stable | Under Revision
> **Author**: [product-designer]
> **Last Updated**: [YYYY-MM-DD]
> **Version**: [1.0]
> **Surfaces**: [From `platform.surfaces` — `web` | `ios` | `android`]
> **UI Frameworks**: [Per surface, from `stack.layers` in `project.yaml` — e.g., web: Next.js + the component library; iOS: SwiftUI; Android: Jetpack Compose; or one cross-platform framework]
> **Component Library**: [Where the components live and their names — e.g., `packages/ui`, Storybook URL]
> **Related Documents**:
> - `design/brand/design-language.md` — tokens, components and states, typography, iconography, motion
> - `design/accessibility-requirements.md` — the accessibility target and requirement matrix
> - `design/ux/app-shell.md` — global navigation, banners and global states
> - `design/ux/<screen>.md` — individual screen specs that reference patterns

> **Why this document exists**: Every screen spec should be able to say "uses
> Button (Primary)" or "uses Form & Inline Validation" rather than re-specifying
> hover states, pressed feedback, focus behavior, keyboard handling and screen
> reader announcements from scratch. This library is the single source of truth for
> reusable interaction behaviors. When a screen spec references a pattern name, the
> engineer looks it up here. When the behavior changes, it changes here and applies
> everywhere.
>
> This is a living document. Patterns are added as new screens are designed — do
> not design a new interaction without checking here first. If a new pattern is
> needed, add it here (or propose it to the product-designer) before the second
> screen that would use it is specced.
>
> **Status definitions**:
> - **Draft**: Interaction specified but not yet implemented or validated
> - **Stable**: Implemented, tested, and validated in at least one released screen
> - **Deprecated**: Being phased out — existing uses will be migrated, do not use in new screens

---

## How to Use This Library

**If you are designing a screen**: Browse the Pattern Catalog Index below before
inventing new interactions. When a pattern fits, reference it by name in the screen
spec (e.g., "The confirm button uses Button (Primary); the amount field uses Form &
Inline Validation"). When no pattern fits, propose a new one — document it here
alongside or before the screen spec that introduces it.

**If you are implementing a screen**: When a screen spec says "use [PatternName],"
find it in this document for the complete specification. The implementation notes
name the component-library component per surface. The accessibility section
contains the requirements that are non-negotiable.

**If you are reviewing a screen spec**: Verify that all interactive elements
reference a pattern from this library or include their own full interaction
specification. "Standard button" or "the usual way" is not a valid reference.

**If you are updating a pattern**: Changing a Stable pattern affects every screen
that uses it. Before changing, audit all usages (search screen specs for the pattern
name), determine the impact, get approval from the product-designer, and update this
document before or simultaneously with any implementation change.

---

## Pattern Catalog Index

> Add a row here every time a new pattern is added to this document.
> The "Used In" column is the usages audit trail — update it when new screens
> adopt the pattern.

| Pattern Name | Category | Description | Used In (Screens) | Status |
|-------------|----------|-------------|------------------|--------|
| Button (Primary) | Input | Main call-to-action. High visual weight. One per screen or sheet. | [Goal create, Sign-up, Checkout] | Draft |
| Button (Secondary) | Input | Alternative action or cancel. Lower visual weight than Primary. | [All dialogs, settings] | Draft |
| Button (Destructive) | Input | Irreversible action. Requires confirmation before execution. | [Delete goal, Delete account, Cancel subscription] | Draft |
| Toggle / Switch | Input | Binary on/off setting that applies immediately. | [Notification settings, privacy settings] | Draft |
| Slider | Input | Continuous value selection where relative position matters. | [Monthly amount suggestion] | Draft |
| Dropdown / Select | Input | Selection from a discrete list of options. | [Bank selection, language, sort order] | Draft |
| List Item | Layout / Input | Selectable row in a vertically scrolling list. | [Goal list, deposit history, settings list] | Draft |
| Card / Grid Item | Layout / Input | Selectable card in a responsive grid. | [Goal templates, plan comparison] | Draft |
| Modal Dialog / Bottom Sheet | Feedback / Layout | Blocking overlay requiring an explicit decision (dialog on web, sheet on mobile). | [Edit goal, confirmation prompts] | Draft |
| Confirmation Dialog | Feedback / Layout | Specific modal for destructive or money-moving confirmation. | [Delete goal, Pause auto-debit, Cancel Plus] | Draft |
| Toast / Snackbar | Feedback | Non-blocking temporary message, optionally with one action (Undo). | [Goal saved, Copied] | Draft |
| Tooltip | Feedback | Contextual information on hover or focus, supplementing a visible label. | [Fee explanations, chart values] | Draft |
| Progress Bar | Feedback / Layout | Linear progress indicator. | [Goal progress, file upload, multi-step forms] | Draft |
| Input Field | Input | Text entry control with a visible label. | [Goal name, email, search] | Draft |
| Tab Bar (in-page) / Segmented Control | Navigation | Section switching within one screen. | [Goal detail: Overview / History] | Draft |
| Scroll Container | Layout | Scrollable region with visible affordance. | [Deposit history, terms text] | Draft |
| Form & Inline Validation | Service-Specific | Labeled fields, validation on blur and submit, error summary. | [Sign-up, goal create, profile] | Draft |
| Data Table | Service-Specific | Sortable, responsive table with row actions. | [Admin console: users, payments] | Draft |
| Search / Filter / Sort | Service-Specific | Query, facet filters and sort with URL-reflected state. | [Deposit history, admin console] | Draft |
| Pagination / Infinite Scroll | Service-Specific | Loading more results with cursor pagination. | [Deposit history, notification inbox] | Draft |
| Date & Time Picker | Service-Specific | Date / time entry with a typed alternative. | [Target date, debit day] | Draft |
| File Upload | Service-Specific | Select, validate, upload with progress and retry. | [Profile photo, support attachments] | Draft |
| Payment Sheet | Service-Specific | Amount, payment method and confirmation for a charge or billing registration. | [Plus checkout, auto-debit registration] | Draft |
| OTP / Identity Verification | Service-Specific | One-time code entry and vendor identity verification (본인인증) handoff. | [Sign-up, payment method change] | Draft |
| Permission Prompt | Service-Specific | Pre-permission explanation before an OS permission, and the denied state. | [Push notifications, camera for ID scan] | Draft |
| Pull-to-Refresh | Service-Specific | Manual refresh of a list or feed on touch surfaces. | [Home, goal list, inbox] | Draft |
| Route Push | Navigation | Forward navigation to a new route or screen. | [All drill-downs] | Draft |
| Back | Navigation | Browser Back, iOS swipe-back, Android system back. | [All screens] | Draft |
| Route Replace | Navigation | Replace the current route without adding history. | [Sign-in → Home, flow completion] | Draft |
| Deep Link Landing | Navigation | Opening a specific item from a link, push or email with a synthesized back stack. | [Push and 알림톡 links, shared URLs] | Draft |
| Modal Open / Close | Navigation | Overlay presentation that dims the underlying screen. | [All dialogs and sheets] | Draft |
| Tab Switch | Navigation | Same-screen content switch between tabs. | [All tabbed screens] | Draft |
| Focus Management | Navigation | Rules for where focus goes when routes, dialogs and content change. | [All screens] | Draft |
| Escape / Cancel | Navigation | Universal cancel behavior across surfaces and input methods. | [All screens] | Draft |
| Loading State | Feedback | Skeletons and progress indicators. | [All data-driven screens] | Draft |
| Empty State | Feedback | First-use and no-results presentations. | [No goals, no search results] | Draft |
| Error State | Feedback | Inline, region and full-screen errors. | [Validation, network, server errors] | Draft |
| Offline State | Feedback | Cached content, queued actions and reconnection. | [All screens that read data] | Draft |
| Banner | Feedback | Persistent inline or global message that needs attention. | [Payment failed, maintenance scheduled] | Draft |
| Success Confirmation | Feedback | How completed actions are confirmed. | [Goal created, settings saved] | Draft |
| Optimistic UI | Feedback | Showing assumed success before the server confirms, with rollback. | [Toggle settings, mark as read] | Draft |

---

## Standard Control Patterns

> Full reference specifications for every pattern in this section (state tables
> with timing values, accessibility requirements, implementation notes) are in
> `.claude/docs/templates/guidance/interaction-pattern-library-guide-standard-controls.md` —
> load only the pattern(s) currently being specified.

---

#### Button (Primary)

**Category**: Input
**Status**: Draft
**When to Use**: [The single most important action on a screen or sheet — at most one visible at a time]
**When NOT to Use**: [Alternative/secondary actions; destructive actions; anything not the screen's primary intent]

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Haptic |
|-------|--------|-------|----------|----------|--------|
| [Default / Hovered / Focused / Pressed / Disabled / Loading] | [Visual treatment — tokens] | [Enter / Space · click · tap · screen-reader activate] | [Response] | [Duration + easing token] | [Light impact on mobile, if any] |

**Accessibility**: [Keyboard, pointer, touch and screen-reader requirements; disabled buttons explain why nearby; loading state announced]

**Implementation Notes**: [Component-library component per surface; prevents double submit while loading]

---

#### Button (Secondary)

**Category**: Input
**Status**: Draft
**When to Use**: [Alternative or cancel action — lower visual weight than Primary]
**When NOT to Use**: [Destructive actions; the screen's most important action]

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Haptic |
|-------|--------|-------|----------|----------|--------|
| [State] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] | [Haptic] |

**Accessibility**: [Same baseline as Button (Primary); note the cancel mapping (Esc) in dialogs]

**Implementation Notes**: [Consistent Primary/Secondary order per platform convention]

---

#### Button (Destructive)

**Category**: Input
**Status**: Draft
**When to Use**: [Irreversible actions that delete user data, end a subscription or move money]
**When NOT to Use**: [Actions that can be undone — prefer an Undo toast; actions that are merely consequential]

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Haptic |
|-------|--------|-------|----------|----------|--------|
| [State] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] | [Haptic] |

> **Critical rule**: A Button (Destructive) NEVER executes its action directly.
> It always triggers a Confirmation Dialog. There are no exceptions.

**Accessibility**: [The accessible name states the specific action — "Delete goal", not "Delete"]

**Implementation Notes**: [Component-library component per surface]

---

#### Toggle / Switch

**Category**: Input
**Status**: Draft
**When to Use**: [Binary settings that take effect immediately and whose current state must be visible at a glance]
**When NOT to Use**: [More than two options; changes that need a Save button; choices needing explanation — use a checkbox or radio group]

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Haptic |
|-------|--------|-------|----------|----------|--------|
| [State] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] | [Haptic] |

**Accessibility**: [Switch role and on/off state announced; state label visible, not color-only; the setting's effect is saved and confirmed]

**Implementation Notes**: [Optimistic update with rollback on failure — see Optimistic UI]

---

#### Slider

**Category**: Input
**Status**: Draft
**When to Use**: [Continuous value selection where range and relative position matter]
**When NOT to Use**: [Precise value entry such as money amounts — offer a text field; short discrete lists; binary state]

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Haptic |
|-------|--------|-------|----------|----------|--------|
| [State] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] | [Haptic] |

**Accessibility**: [Arrow / Page Up / Page Down / Home / End on web; adjustable action for screen readers; the numeric value is always displayed; a typed alternative exists (2.5.7)]

**Implementation Notes**: [Component-library component per surface]

---

#### Dropdown / Select

**Category**: Input
**Status**: Draft
**When to Use**: [Selection from a discrete list of about 3–15 options; only the selection visible at rest]
**When NOT to Use**: [Binary choices; long lists — use a searchable picker; when comparing options matters]

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Haptic |
|-------|--------|-------|----------|----------|--------|
| [State] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] | [Haptic] |

**Accessibility**: [Native select or combobox/listbox pattern; expanded/collapsed announced; type-ahead]

**Implementation Notes**: [Native picker on mobile where it fits]

---

#### List Item

**Category**: Layout / Input
**Status**: Draft
**When to Use**: [A selectable row in a vertically scrolling list]
**When NOT to Use**: [Multi-column data with sorting — use Data Table; non-selectable content rows]

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Haptic |
|-------|--------|-------|----------|----------|--------|
| [State] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] | [Haptic] |

**Accessibility**: [List semantics and position ("3 of 12"); swipe actions duplicated as visible buttons or a menu; minimum row height]

**Implementation Notes**: [Virtualized for long lists; scroll focused rows into view]

---

#### Card / Grid Item

**Category**: Layout / Input
**Status**: Draft
**When to Use**: [A selectable card in a responsive grid that reflows by breakpoint]
**When NOT to Use**: [Single-column content; dense data — use List Item or Data Table]

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Haptic |
|-------|--------|-------|----------|----------|--------|
| [Default / Hovered / Focused / Selected / Pressed / Disabled] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] | [Haptic] |

**Accessibility**: [One focus stop per card (not one per inner element unless they are separate actions); the card's accessible name summarizes it]

**Implementation Notes**: [Columns per breakpoint from the design language]

---

#### Modal Dialog / Bottom Sheet

**Category**: Feedback / Layout
**Status**: Draft
**When to Use**: [A decision or short task that must be resolved before continuing — centered dialog on web `md`/`lg`, bottom sheet on compact mobile]
**When NOT to Use**: [Non-blocking information; long forms (use a route); content the user needs to compare with the screen behind]

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Haptic |
|-------|--------|-------|----------|----------|--------|
| [Opening / Active / Dismissing (confirmed) / Dismissing (cancelled) / Cannot dismiss] | [Visual treatment] | [Input trigger — Esc, browser Back, Android back, swipe down, tap outside] | [Response] | [Duration + easing] | [Haptic] |

> **Focus trap rule**: While a dialog or sheet is open, focus stays within it, and
> focus returns to the trigger element on close.

**Accessibility**: [Dialog role with an accessible title; Esc cancels; background content inert; reduced-motion presentation]

**Implementation Notes**: [Native sheet on iOS and Android where it fits; browser Back closes a web dialog that has its own URL]

---

#### Confirmation Dialog

**Category**: Feedback / Layout
**Status**: Draft
**When to Use**: [Confirming a destructive or money-moving action — always triggered by Button (Destructive) or a payment commit]
**When NOT to Use**: [Non-destructive confirmations; dialogs with more than two actions]

> **Label rule**: The confirm button is labeled with the specific action ("Cancel
> Plus", "Delete goal"), never a generic "OK" or "Yes".

**Structure**:
- Title: [Brief, action-describing — "Cancel your Plus subscription?"]
- Body: [One sentence stating the consequence and what happens to money or data — "You keep Plus until 14 Nov 2026. No further charges."]
- Confirm button: [Button (Destructive) — labeled with the specific action]
- Cancel button: [Button (Secondary) — "Keep Plus"]
- Default focus: [Cancel — the safer default]

**Accessibility**: [Inherits Modal Dialog; alert-dialog role; default focus on Cancel is required]

**Implementation Notes**: [Component-library component per surface]

---

#### Toast / Snackbar

**Category**: Feedback
**Status**: Draft
**When to Use**: [Brief, non-blocking confirmation of something the user just did, optionally with one action (Undo)]
**When NOT to Use**: [Decisions; errors requiring action (use inline error or Banner); anything the user must not miss]

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Haptic |
|-------|--------|-------|----------|----------|--------|
| [Entering / Displayed / Auto-dismiss / Manual dismiss / Replaced by newer] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] | [Haptic] |

**Accessibility**: [Announced as a status message without moving focus; a toast with an action stays until dismissed or gives at least enough time to reach it; never the only channel for actionable information]

**Implementation Notes**: [One at a time — queue rules live in `design/ux/app-shell.md` § Notifications & Banners]

---

#### Tooltip

**Category**: Feedback
**Status**: Draft
**When to Use**: [Supplementary information about a visible label or icon]
**When NOT to Use**: [Information required to complete an action; touch-only contexts without hover or focus — use an info button that opens a popover]

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Haptic |
|-------|--------|-------|----------|----------|--------|
| [Hidden / Hover trigger / Focus trigger / Appearing / Displayed / Hiding] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] | [—] |

**Accessibility**: [Reachable by keyboard focus; dismissible with Esc; hoverable; persistent until dismissed (1.4.13); contrast per target]

**Implementation Notes**: [Repositions at viewport edges]

---

#### Progress Bar

**Category**: Feedback / Layout
**Status**: Draft
**When to Use**: [Linear progress toward a defined endpoint — goal progress, upload, multi-step form]
**When NOT to Use**: [Unknown duration — use an indeterminate indicator; values with no endpoint]

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Haptic |
|-------|--------|-------|----------|----------|--------|
| [Default / Value increasing / Complete / At zero / Indeterminate] | [Visual treatment] | [—] | [Response] | [Duration + easing] | [—] |

**Accessibility**: [Progressbar role with value and text ("₩350,000 of ₩1,000,000, 35 %"); numeric label visible; reduced-motion fill]

**Implementation Notes**: [Component-library component per surface]

---

#### Input Field

**Category**: Input
**Status**: Draft
**When to Use**: [Text entry — names, email, amounts, search]
**When NOT to Use**: [Selecting from known options; entering a date when a picker with a typed alternative fits better]

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Haptic |
|-------|--------|-------|----------|----------|--------|
| [Default / Hovered / Focused / Typing / Value present / Limit reached / Clear / Validation error / Validated / Disabled / Read-only] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] | [Haptic] |

**Accessibility**: [Visible label (placeholder is not a label); `autocomplete` / content-type hints; error text associated with the field; paste allowed]

**Implementation Notes**: [Correct keyboard per field — numeric for amounts with thousands separators, email, tel, one-time-code]

---

#### Tab Bar (in-page) / Segmented Control

**Category**: Navigation
**Status**: Draft
**When to Use**: [Dividing one screen's content into 2–5 sections, one visible at a time]
**When NOT to Use**: [Top-level navigation between destinations — that is the app shell's tab bar; content needing simultaneous visibility]

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Haptic |
|-------|--------|-------|----------|----------|--------|
| [Inactive / Active / Hovered / Focused / Activated] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] | [Haptic] |

**Accessibility**: [ARIA tabs pattern on web (tablist / tab / tabpanel, arrow keys between tabs); selected state beyond color]

**Implementation Notes**: [Selected tab reflected in the URL on web when shareable]

---

#### Scroll Container

**Category**: Layout
**Status**: Draft
**When to Use**: [Content exceeding the visible area of its region]
**When NOT to Use**: [Nested scroll regions on mobile; content better paginated]

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Haptic |
|-------|--------|-------|----------|----------|--------|
| [Content fits / Scrollable / Scrolling / Keyboard scroll / Boundary / Focus follows scroll] | [Visual treatment] | [Input trigger] | [Response] | [Duration + easing] | [—] |

**Accessibility**: [Keyboard-scrollable (focusable region with a name when it has no focusable children); focused items scrolled into view and not obscured]

**Implementation Notes**: [Scroll padding for sticky headers and bottom bars]

---

## Service-Specific Patterns

> Full reference specifications for every pattern in this section are in
> `.claude/docs/templates/guidance/interaction-pattern-library-guide-service-specific.md` —
> load only the pattern(s) currently being specified.

---

#### Form & Inline Validation

**Category**: Service-Specific
**Status**: Draft
**When to Use**: [Any screen that collects input the server validates — sign-up, goal create, profile, checkout]

**States**:

| State | Visual | Notes |
|-------|--------|-------|
| [Pristine / Focused / Valid / Invalid (on blur) / Submitting / Server error / Submitted] | [Visual treatment] | [Validate on blur and on submit, not on every keystroke; keep input after an error; on submit, move focus to an error summary] |

**Accessibility**: [Visible labels; errors in text next to the field and in a summary; `aria-invalid` / error association; no redundant entry within a flow]

**Implementation Notes**: [Client validation mirrors the API's rules — the API remains the authority; error messages come from the ux-writer]

---

#### Data Table

**Category**: Service-Specific
**Status**: Draft
**When to Use**: [Comparing records across several attributes — admin console, statements, reports]

**States**:

| State | Visual | Notes |
|-------|--------|-------|
| [Loading / Populated / Empty / Filtered-empty / Row selected / Row action pending / Error] | [Visual treatment] | [Sticky header; sort state shown per column; row actions in a menu] |

**Accessibility**: [Table semantics with header cells; sort state announced; responsive behaviour on `sm` (card list or horizontal scroll with a visible affordance)]

**Implementation Notes**: [Server-side sort and pagination for large sets — matches the `## API Data` of the screen]

---

#### Search / Filter / Sort

**Category**: Service-Specific
**Status**: Draft
**When to Use**: [Narrowing a list the user cannot scan — history, admin lists, catalogs]

**States**:

| State | Visual | Notes |
|-------|--------|-------|
| [Idle / Typing (debounced) / Results / No results / Filters applied / Error] | [Visual treatment] | [State reflected in the URL on web; active filters visible and removable; result count shown] |

**Accessibility**: [Search landmark; result count announced as a status message; filter controls reachable without a pointer]

**Implementation Notes**: [Debounce input; Korean IME composition must finish before querying]

---

#### Pagination / Infinite Scroll

**Category**: Service-Specific
**Status**: Draft
**When to Use**: [Lists larger than one page — cursor pagination from the API]

**States**:

| State | Visual | Notes |
|-------|--------|-------|
| [First page / Loading more / End of list / Load-more error] | [Visual treatment] | [Infinite scroll for feeds; numbered pages or "Load more" when users need to return to a position or reach a footer] |

**Accessibility**: [A "Load more" button as the keyboard and screen-reader path even when scrolling loads automatically; new items announced; focus kept in place]

**Implementation Notes**: [Page size and cursor parameters match the screen's `## API Data`]

---

#### Date & Time Picker

**Category**: Service-Specific
**Status**: Draft
**When to Use**: [Choosing dates or times — target date, debit day, appointment]

**States**:

| State | Visual | Notes |
|-------|--------|-------|
| [Closed / Open / Date selected / Invalid date / Disabled dates] | [Visual treatment] | [Typed input always available; disabled dates explain why] |

**Accessibility**: [Keyboard grid navigation on web; native pickers on mobile; typed alternative; locale date format ("2026. 10. 14." for `ko-KR`)]

**Implementation Notes**: [Store dates as ISO 8601; show in the user's time zone; say which time zone applies to debits]

---

#### File Upload

**Category**: Service-Specific
**Status**: Draft
**When to Use**: [Attaching files — profile photo, support attachments, documents]

**States**:

| State | Visual | Notes |
|-------|--------|-------|
| [Empty / Selecting / Validating / Uploading (progress) / Uploaded / Failed / Removed] | [Visual treatment] | [Type and size limits stated up front; retry per file] |

**Accessibility**: [Button-based selection (drag and drop is an addition, never the only way); progress announced; errors in text]

**Implementation Notes**: [Direct-to-storage upload with a signed URL where the architecture says so; strip image metadata when privacy requires it]

---

#### Payment Sheet

**Category**: Service-Specific
**Status**: Draft
**When to Use**: [Charging the user or registering a payment method for recurring billing — subscription checkout, auto-debit registration]

**States**:

| State | Visual | Notes |
|-------|--------|-------|
| [Review (amount, method, renewal date) / Method selection / Vendor handoff / Processing / Succeeded / Declined / Cancelled / Timed out] | [Visual treatment] | [Amount, currency, renewal date and cancellation terms shown before commit; the commit button repeats the amount — "Pay ₩4,900"] |

**Accessibility**: [Amounts announced with currency; review step before a financial commitment (3.3.4); the vendor flow's accessibility recorded as a third-party limitation if it falls short]

**Implementation Notes**: [Payment-provider SDK or widget per surface (e.g., Toss Payments); store billing rules for in-app purchases; idempotency key on the charge; never render card data in the product's own fields unless the architecture allows it]

---

#### OTP / Identity Verification

**Category**: Service-Specific
**Status**: Draft
**When to Use**: [One-time code entry (SMS / email / authenticator) and identity verification through a vendor (본인인증 / PASS)]

**States**:

| State | Visual | Notes |
|-------|--------|-------|
| [Code sent / Entering / Verifying / Invalid code / Expired / Resend available / Locked out / Vendor handoff / Vendor cancelled / Verified] | [Visual treatment] | [Timer visible with an easy resend; lockout states the wait time] |

**Accessibility**: [One field (not one per digit) or a correctly grouped set; one-time-code autofill; paste allowed; the timer is announced sparingly, not every second]

**Implementation Notes**: [Rate limits come from the API; the vendor flow's return and cancel states are designed, not left to the vendor]

---

#### Permission Prompt

**Category**: Service-Specific
**Status**: Draft
**When to Use**: [Before an OS permission request — notifications, camera, photos, location, contacts]

**States**:

| State | Visual | Notes |
|-------|--------|-------|
| [Pre-permission explanation / System prompt / Granted / Denied / Denied permanently (settings path) / Limited (e.g., approximate location, selected photos)] | [Visual treatment] | [Ask in context, after the user sees the benefit — never at first launch] |

**Accessibility**: [The explanation is a normal screen or sheet with a clear decline option; the denied state explains what still works]

**Implementation Notes**: [Re-check status on return from system settings; one ask per context]

---

#### Pull-to-Refresh

**Category**: Service-Specific
**Status**: Draft
**When to Use**: [Refreshing a list or feed on touch surfaces]

**States**:

| State | Visual | Notes |
|-------|--------|-------|
| [Idle / Pulling / Threshold reached / Refreshing / Refreshed / Failed] | [Visual treatment] | [Content stays visible while refreshing] |

**Accessibility**: [A visible or menu refresh action for keyboard, pointer and screen-reader users; completion announced]

**Implementation Notes**: [Platform-native control where available]

---

## Navigation Patterns

> Full reference specifications for this section and the next are in
> `.claude/docs/templates/guidance/interaction-pattern-library-guide-navigation-feedback.md` —
> load only the pattern(s) currently being specified.

---

#### Route Push / Back / Replace

**Category**: Navigation
**Status**: Draft

These three patterns define how screens enter and leave the navigation history.

| Pattern | Trigger | Animation | History Behavior | Focus Behavior |
|---------|---------|-----------|------------------|----------------|
| [Push / Back / Replace] | [Trigger] | [Platform default on iOS and Android; web: none or a short fade] | [Browser history / navigation stack] | [Focus moves to the new heading; Back restores the previous focus] |

**Back inputs**: [Browser Back (web), edge swipe-back (iOS), system and predictive back (Android) — never blocked except for an unsaved-changes confirmation]

**Motion reduction**: [Fallback behavior]

**Implementation Notes**: [Router and navigation library per surface; scroll position restored on Back]

---

#### Deep Link Landing

**Category**: Navigation
**Status**: Draft

| Link Source | Lands On | Synthesized Back Stack | Signed-Out Behavior | Unknown / Deleted Target |
|-------------|----------|------------------------|---------------------|--------------------------|
| [Push / 알림톡 / email / shared URL] | [The specific item] | [Tab → list → item] | [Sign in, then resume] | [Not-found state with a way home] |

---

#### Focus Management

**Category**: Navigation
**Status**: Draft

> Focus management is the most common keyboard and screen-reader failure in web and
> app UIs. These rules must be implemented consistently.

| Rule | Description |
|------|-------------|
| [Route change / dialog open / dialog close / content removed / error on submit / async result / Tab order / focus visibility and not obscured] | [Rule description] |

---

#### Escape / Cancel

**Category**: Navigation
**Status**: Draft

> The "go back / cancel" action is the most-used navigation input. It must be
> consistent across every screen with no exceptions.

| Surface | Input | Behavior |
|---------|-------|----------|
| [web / ios / android] | [Esc · browser Back · swipe-back · system back · swipe down on a sheet] | [Behavior] |

**Rules**: [Never override "go back / cancel"; every screen defines its cancel behavior explicitly in its UX spec; unsaved input is confirmed, never silently discarded]

---

## Feedback and Loading Patterns

---

#### Loading State

**Category**: Feedback
**Status**: Draft

| Scope | Pattern | Notes |
|-------|---------|-------|
| [Full screen (initial) / Region / Component inline / Background revalidation] | [Skeleton matching the final layout / inline spinner / none] | [Minimum display time to avoid flicker] |

**Accessibility**: [Busy state exposed; completion announced when it changes what the user can do]

---

#### Empty State

**Category**: Feedback
**Status**: Draft

> Every empty list and grid must have a designed empty state. The empty state is
> not an error — it is a starting point.

| Location | Empty State Content | Notes |
|----------|--------------------|-------|
| [Location] | [Illustration or icon + message + one primary action, or how to widen a search] | [Notes] |

**Rule**: Every empty state includes a message and either an action or a way to change the query.

---

#### Error State

**Category**: Feedback
**Status**: Draft

| Error Type | Pattern | Tone |
|-----------|---------|------|
| [Input validation / Operation failed / Server error / Not found / Rate limited / Partial failure] | [Inline / region / full screen / Banner] | [Tone guidance from the voice-and-tone guide] |

**Principle**: Error messages are never the user's fault. They say what happened and what to do next, and they keep the user's input.

---

#### Offline State

**Category**: Feedback
**Status**: Draft

| Situation | What the User Sees | What Still Works | On Reconnect |
|-----------|--------------------|------------------|--------------|
| [Lost connection while browsing / while submitting / app opened offline] | [Offline indicator from the app shell; cached content marked] | [Reads from cache; queued writes where allowed] | [Sync; surface conflicts] |

---

#### Banner

**Category**: Feedback
**Status**: Draft

| Scope | Placement | Dismissible? | Notes |
|-------|-----------|--------------|-------|
| [Inline (one screen) / Global (app shell slot)] | [Placement] | [Only when not blocking] | [Priority and queue rules for global banners live in `design/ux/app-shell.md`] |

---

#### Success Confirmation

**Category**: Feedback
**Status**: Draft

| Action Weight | Pattern | Notes |
|---------------|---------|-------|
| [Light (setting changed) / Medium (item created) / Heavy (payment, account deletion)] | [Inline check / Toast / Confirmation screen with a receipt] | [Money-moving actions always get a confirmation screen or receipt] |

---

#### Optimistic UI

**Category**: Feedback
**Status**: Draft

| Use When | Rollback Behavior | Never Use For |
|----------|-------------------|---------------|
| [Low-risk, high-frequency actions — toggles, mark as read, reorder] | [Revert and show an inline error or toast with retry] | [Payments, deletions, anything with legal or financial effect] |

---

## Animation Standards

> These timing values apply to ALL patterns in this library, as defaults under the
> motion tokens of the design language. When a pattern says "150 ms ease-out," the
> easing is defined here. On iOS and Android, prefer the platform's native
> navigation and sheet transitions over re-specifying them. Haptics and
> notification sounds are defined in the design language, not here.

| Animation Type | Duration (ms) | Easing Function | Notes |
|---------------|--------------|----------------|-------|
| Button hover / focus enter | 80 | ease-out | Fast — snappy, not sluggish |
| Button hover / focus exit | 60 | ease-in | Slightly faster exit than entry |
| Button press | 60 | ease-in | Immediate feedback |
| Route transition (web) | 0–150 | ease-out | None or a short fade; never block input |
| Route push / back (mobile) | Platform default | Platform default | Use the native navigation transition |
| Modal dialog open | 200 | ease-out | Fades and scales from center |
| Modal dialog close | 150 | ease-in | Closes faster than it opens |
| Bottom sheet present / dismiss | Platform default (about 250–350) | Platform default | Follows the drag velocity when swiped |
| Toast enter | 200 | ease-out | Slides in from the toast area edge |
| Toast exit | 200 | ease-in | |
| Tab / segmented control switch | 150 | ease-in-out | Content cross-fades |
| Tooltip appear | 120 | ease-out | After a 300–400 ms hover delay; immediately on focus |
| Tooltip disappear | 80 | ease-in | |
| Progress bar fill | 300 | ease-out | Value changes animate smoothly |
| Skeleton shimmer | Loop, about 1200 per cycle | linear | Replaced by a static skeleton under reduced motion |
| Success check | 250 | ease-out | Once; never loops |

**Motion reduction overrides**: When reduced motion is on (`prefers-reduced-motion`
on web, Reduce Motion on iOS, Remove animations on Android — see
`design/accessibility-requirements.md`), slide and scale animations are replaced
with fades or instant changes, fade durations are halved, and looping animations
(skeleton shimmer, indeterminate spinners, pulsing indicators) become static
equivalents.

---

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| [Does the Toss Payments widget expose accessible names for its fields on iOS, or do we record it as a third-party limitation?] | [product-designer, accessibility-specialist] | [Before the payment sheet is implemented] | [Unresolved] |
| [Cursor pagination with "Load more" or automatic infinite scroll for deposit history? Depends on whether users need to reach the footer.] | [product-designer] | [Before the history screen spec is approved] | [Unresolved] |
| [Do we use native bottom sheets on both iOS and Android, or one cross-platform sheet component? Verify with the frontend-engineer and mobile-engineer.] | [product-designer, mobile-engineer] | [Before the first sheet is implemented] | [Unresolved] |
| [How many global banners may queue before the oldest is dropped? Needs a usability session.] | [product-designer] | [First usability session] | [Unresolved] |
| [Add question] | [Owner] | [Deadline] | [Resolution] |
