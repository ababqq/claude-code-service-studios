> Authoring guidance for interaction-pattern-library.md. Load only the part covering the section currently being authored — not the whole file at once.

> Covers: **Standard Control Patterns** — full reference specifications for Button (Primary/Secondary/Destructive), Toggle, Slider, Dropdown / Select, List Item, Grid Item, Modal Dialog, Confirmation Dialog, Toast / Notification, Tooltip, Progress Bar, Input Field, Tab Bar, Scroll Container.

## Standard Control Patterns

State tables use four input methods — **keyboard**, **pointer** (mouse,
trackpad), **touch** and **screen reader** — and a **Feedback** column for haptics
(iOS, Android) and screen-reader announcements. Colors, durations and easing come
from the design language (`design/brand/design-language.md` — `## 2. Color System`,
`## 7. Motion & Feedback`); the values below are worked examples. Implementation
notes name common stacks; follow the project's own stack reference in
`docs/stack-reference/` where it differs. Examples use **Moa**, a subscription
savings app (web, iOS, Android).

---

#### Button (Primary)

**Category**: Input
**Status**: Draft
**When to Use**: The single most important action on a screen. "Create goal,"
"Continue," "Start Plus," "Save." There should be at most one Primary button
visible at a time. It answers "what does the user most likely want to do here?"
**When NOT to Use**: Alternative or secondary actions; destructive actions that
require confirmation before an irreversible consequence; any action that is not
the primary intent of the screen.

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Feedback |
|-------|--------|-------|----------|----------|----------|
| Default | Full-opacity fill, `color.action.primary`. Label centered. | — | — | — | — |
| Hovered (pointer) | Fill shifts to the hover token; cursor becomes a pointer | Pointer over element | Transition from Default | 80ms ease-out | — |
| Focused (keyboard) | Focus ring visible (2px, offset 2px, `color.border.focus`, 3:1 against adjacent colors) | Tab | Transition from Default | 80ms ease-out | Screen reader: "[Label], button" |
| Pressed | Fill darkens; optional scale 0.98 | Click / Enter / Space / tap | Action fires on release (pointer, touch) or keydown (Enter). Scale on press. | 60ms ease-in press; 80ms ease-out release | Haptic: light impact on iOS/Android for commit actions only |
| Disabled | 40% opacity, no pointer cursor, no hover state | — | No response | — | Screen reader: "dimmed" / "disabled" |
| Loading (post-press) | Label replaced by a spinner plus visually hidden "Saving…"; width stays fixed | — | Prevents double submission | Duration of the request | Screen reader: announce completion or error |

**Accessibility**:
- Keyboard: Tab to focus, Enter or Space to activate. Reachable in the screen's
  logical tab order.
- Touch: minimum target 44 × 44 pt (iOS HIG) / 48 × 48 dp (Material); on the web
  at least 24 × 24 CSS px (WCAG 2.2 SC 2.5.8) — use 44 px for primary actions.
- Screen reader: accessible name matches the visible label (SC 2.5.3 Label in
  Name). Role: button. Disabled state exposed. Prefer a disabled state with a
  reason shown nearby over a silently disabled button.
- Color: Primary is distinguished from Secondary by weight (fill vs outline),
  not by hue alone.

**Implementation Notes**: [Web: a native `<button type="button|submit">` — never a
clickable `div`; disable double submit with the loading state, not by removing
the button. SwiftUI: `Button` with `.buttonStyle` from the component library;
`.disabled()` exposes state automatically. Compose: `Button` with the theme's
colors; `enabled = false` for disabled. React Native: `Pressable` with
`accessibilityRole="button"` and `accessibilityState={{ disabled, busy }}`.]

---

#### Button (Secondary)

**Category**: Input
**Status**: Draft
**When to Use**: Alternative or cancel action. "Back," "Cancel," "Skip,"
"Maybe later." Lower visual weight than Primary — it recedes rather than competes.
**When NOT to Use**: Destructive actions (use Button (Destructive)). The most
important action on the screen (use Button (Primary)).

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Feedback |
|-------|--------|-------|----------|----------|----------|
| Default | Outlined (border only, transparent fill) or tonal fill | — | — | — | — |
| Hovered (pointer) | Background fill appears at low opacity; border strengthens | Pointer over | Transition from Default | 80ms ease-out | — |
| Focused (keyboard) | Focus ring, same specification as Primary | Tab | Transition from Default | 80ms ease-out | Screen reader: "[Label], button" |
| Pressed | Fill opacity increases | Click / Enter / Space / tap | Action fires on release | 60ms ease-in | — |
| Disabled | 40% opacity | — | No response | — | State exposed |

**Accessibility**: Same requirements as Button (Primary). In a dialog with
Primary and Secondary buttons, Esc maps to the Secondary (cancel) action.

**Implementation Notes**: [Same as Button (Primary). Position Secondary
consistently across the product: on the web to the left of Primary in a
right-aligned button row; on mobile full-width, stacked below Primary. Follow
the platform order where the design language's `## 8. Platform Adaptation` says so
— consistency across screens matters more than per-screen preference.]

---

#### Button (Destructive)

**Category**: Input
**Status**: Draft
**When to Use**: Any action that is irreversible or ends something the user pays
for or relies on: "Delete account," "Cancel subscription," "Remove payment
method," "Delete goal," "Discard changes." The visual treatment signals the
consequence before the user presses.
**When NOT to Use**: Actions that can be undone (prefer doing them immediately
with an Undo snackbar), or actions that are consequential but reversible.

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Feedback |
|-------|--------|-------|----------|----------|----------|
| Default | Outlined or filled with `color.feedback.danger`; label names the action. Optional warning icon. | — | — | — | — |
| Hovered / Focused | Same behavior as Button (Primary) with the danger color | Pointer / Tab | — | 80ms | Screen reader: "[Label], button" plus the consequence description |
| Pressed (first press) | Does NOT execute the action. Opens the Confirmation Dialog pattern. | Click / Enter / Space / tap | Trigger Confirmation Dialog | 100ms | Haptic: warning on iOS/Android |
| — | The Confirmation Dialog handles the actual execution | — | — | — | — |
| Disabled | 40% opacity | — | No response | — | State exposed |

> **Critical rule**: A Button (Destructive) NEVER executes its action directly.
> It always triggers a Confirmation Dialog. A user who presses it by accident must
> always get one more chance to back out. "I deleted my account by mistake" and
> "I cancelled my subscription without meaning to" are the support tickets and
> store reviews this rule prevents.

**Service-specific rules**:
- **Delete account**: re-authenticate (password, passkey or a fresh one-time code)
  before the confirmation; state what is deleted, what is kept and for how long
  (retention required by law, e.g. payment records), and whether an active
  subscription is cancelled with it.
- **Cancel subscription**: show when access ends ("Plus stays active until
  October 31") and what happens to data; offer alternatives (downgrade, pause) at
  most once, without obstructing the path. Making cancellation harder than
  sign-up is a dark pattern and, in several markets, a legal risk.

**Accessibility**: The consequence is part of the accessible description:
"Delete account, button — this cannot be undone." Use `aria-describedby` on the
web, `accessibilityHint` on iOS, a semantics description on Android.

**Implementation Notes**: [The destructive button passes the action to the
Confirmation Dialog; it does not hold the execution logic itself, so a bug in the
dialog cannot execute the action accidentally. The server enforces the same rule:
a destructive endpoint requires an explicit confirmation token or a recent
re-authentication, never only a client-side dialog.]

---

#### Toggle

**Category**: Input
**Status**: Draft
**When to Use**: Binary on/off settings that take effect immediately and whose
current state must be visible at a glance. "Push notifications: On/Off,"
"Dark mode: On/Off," "Face ID sign-in: On/Off," "Marketing messages: On/Off."
**When NOT to Use**: Selections from more than two options (use Dropdown or a
segmented control). One-off actions (use Button). Settings that take effect only
after a Save button (use a checkbox in a form). Consent that must be recorded with
its date and version — a marketing-consent toggle still needs the consent record
on the server.

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Feedback |
|-------|--------|-------|----------|----------|----------|
| Off / Default | Track: muted fill. Thumb: leading edge. | — | — | — | — |
| Hovered (pointer) | Track brightens slightly. Cursor: pointer. | Pointer over | Transition | 60ms | — |
| Focused (keyboard) | Focus ring around the whole toggle (track + thumb) | Tab | — | 60ms | Screen reader: "[Label], switch, off" |
| Activated | Thumb slides to the trailing edge; track fill becomes the active color | Click / Space / tap | State changes and persists (optimistic, with rollback on failure) | 150ms ease-in-out | Haptic: selection; screen reader announces "on" |
| Deactivated | Thumb slides back; track reverts | Same inputs | State change | 150ms ease-in-out | Haptic: selection |
| Pending (server-backed) | Toggle shows the new state; a small progress indicator appears after 500ms | — | Rolls back with an inline error if the request fails | Until response | Error announced |
| Disabled | 40% opacity. Current state still visible. | — | No response | — | State exposed |

**Accessibility**:
- Keyboard: Space toggles; a switch built on a `<button>` also toggles with
  Enter. Do not require arrow keys.
- Screen reader: role "switch". The accessible name does NOT include the state —
  the state is announced separately. Correct: name "Push notifications", state
  "on". Incorrect: name "Push notifications on".
- The state is visible without relying on thumb position or color alone — the
  design language defines a check mark or a state label for the on track.

**Implementation Notes**: [Web: `<button role="switch" aria-checked>` or
`<input type="checkbox" role="switch">`, with a visible `<label>`. SwiftUI:
`Toggle`. Compose: `Switch` inside a row with `Modifier.toggleable(role =
Role.Switch)` so the whole row is the target. When reduced motion is requested,
snap to the final state instead of sliding.]

---

#### Slider

**Category**: Input
**Status**: Draft
**When to Use**: Choosing a value from a continuous range where approximate values
are acceptable and the relative position itself is informative. In-app text size
preview, image crop zoom, a price-range filter paired with numeric inputs.
**When NOT to Use**: Exact values — especially money. A savings amount or a
transfer amount is an Input Field, never a slider. Short discrete lists (use a
segmented control or Dropdown). Binary state (use Toggle).

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Feedback |
|-------|--------|-------|----------|----------|----------|
| Default | Track, fill up to the thumb, thumb, current value label | — | — | — | — |
| Hovered (pointer) | Thumb enlarges slightly | Pointer over | — | 60ms | — |
| Focused (keyboard) | Focus ring on the thumb | Tab | — | 60ms | Screen reader: "[Label], slider, [value]" |
| Dragging (pointer, touch) | Thumb follows; fill and value label update live | Drag | onChange fires continuously; commit on release | Real time | Haptic: selection tick at each step (mobile) |
| Keyboard step | Thumb moves one step | Arrow keys | Step change; fires onChange | Instant | Screen reader announces the new value |
| Keyboard large step | Larger step (10% of the range) | Page Up / Page Down | Large step | Instant | Announces value |
| Min / Max | Thumb at the end | Home / End | Jump to bound | Instant | Announces value |
| Disabled | 40% opacity, value visible | — | No response | — | State exposed |

**Accessibility**:
- Every slider shows its numeric value; relative position alone excludes users who
  cannot perceive it.
- Screen reader: role "slider", value announced on every change; min and max
  exposed. On iOS/Android, swipe up/down adjusts by one step.
- Dragging must not be the only way to set the value (WCAG 2.2 SC 2.5.7 Dragging
  Movements): keyboard steps, and for ranges a paired numeric input.

**Implementation Notes**: [Web: `<input type="range">` styled, or an accessible
slider primitive with `aria-valuenow/min/max/valuetext` (valuetext carries units:
"200%"). SwiftUI: `Slider` with `.accessibilityValue`. Compose: `Slider` with
`steps` and semantics `stateDescription`.]

---

#### Dropdown / Select

**Category**: Input
**Status**: Draft
**When to Use**: Choosing one option from a discrete list of about 3–15 options
where only the selected value needs to be visible at rest. Language, country,
notification frequency, the day of the month for an auto-debit.
**When NOT to Use**: Binary choices (use Toggle). Two or three options that users
compare (use a segmented control or radio group — options stay visible). Long
lists such as banks or card issuers (use a searchable list or a bottom sheet with
search; Korean bank pickers commonly show a logo grid of the most-used banks plus
search).

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Feedback |
|-------|--------|-------|----------|----------|----------|
| Closed / Default | Label, current value, chevron-down icon | — | — | — | — |
| Hovered (pointer) | Row background tint | Pointer over | — | 60ms | — |
| Focused (keyboard) | Focus ring on the control | Tab | — | 60ms | Screen reader: "[Label], [value], collapsed" |
| Opening | List opens below (or above near the viewport bottom); selected option highlighted; focus moves into the list. Mobile: a bottom sheet or the native picker. | Click / Enter / Space / Alt+Down / tap | Open list | 100ms ease-out | Screen reader: "expanded" |
| Option active | Option highlighted | Arrow keys / pointer | — | 60ms | Screen reader: "[Option], 3 of 12" |
| Option selected | List closes; control shows the new value; onChange fires | Enter / click / tap | Select and close | 80ms | Haptic: selection (mobile) |
| Dismissed | List closes; value unchanged; focus returns to the control | Esc / click outside / swipe down (sheet) | Dismiss | 80ms | — |
| Disabled | 40% opacity | — | — | — | State exposed |

**Accessibility**:
- Keyboard: Up/Down move through options; Enter selects; Esc dismisses; typing a
  character jumps to the first matching option (typeahead).
- Screen reader: a native `<select>` or the ARIA combobox/listbox pattern; the
  expanded state and the option position are announced.
- The open list never covers the control that opened it on small screens — use a
  bottom sheet instead.

**Implementation Notes**: [Web: prefer the native `<select>` for simple lists (it
gives mobile browsers their native picker); use an accessible combobox primitive
only when options need rich content or search. SwiftUI: `Picker` with the menu
style, or a sheet for long lists. Compose: `ExposedDropdownMenuBox`, or a
`ModalBottomSheet` with a list.]

---

#### List Item

**Category**: Layout / Input
**Status**: Draft
**When to Use**: One row in a vertical list: a transaction in the savings history,
a notification in the inbox, a settings row, a goal in the goal list. The list is
the container; this is the row.
**When NOT to Use**: Two-dimensional layouts (use Grid Item). Non-interactive
rows (remove the hover, focus and pressed states). Dense, multi-column,
sortable data for operators (use the Data Table pattern in
`.claude/docs/templates/guidance/interaction-pattern-library-guide-service-specific.md`).

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Feedback |
|-------|--------|-------|----------|----------|----------|
| Default | Full-width row: leading icon or avatar (optional), primary text, secondary text, trailing value or chevron | — | — | — | — |
| Hovered (pointer) | Row background tint | Pointer over | — | 60ms | — |
| Focused (keyboard) | Focus ring on the row | Tab or arrow keys (within a listbox) | — | 60ms | Screen reader reads the row as one item |
| Pressed | Brief highlight (ripple on Android, highlight on iOS), then navigates or acts | Click / Enter / tap | Navigation or action | 80ms | — |
| Selected (persistent) | Selection indicator (check, leading bar) distinct from focus | — | Rendered state | — | Screen reader: "selected" |
| Swipe actions (mobile, optional) | Revealed actions (e.g. "Mark as read," "Delete") | Swipe | Reveal; full swipe executes non-destructive actions only | 150ms | Haptic at the commit threshold |
| Disabled | 40% opacity | — | — | — | State exposed |

**Accessibility**:
- The row is read as one item: "Auto-debit, September 25, 50,000 won, completed"
  — not four separate elements. Merge descendants on native platforms.
- Swipe actions are also available without swiping: a context menu, a long-press
  menu or custom accessibility actions (VoiceOver actions rotor, TalkBack actions).
- Row height at least 48 dp / 44 pt on touch.

**Implementation Notes**: [Web: a `<ul>` of `<li>` with one `<a>` or `<button>`
covering the row; avoid nested interactive elements. SwiftUI: `List` rows with
`.accessibilityElement(children: .combine)` and `.swipeActions` plus
`.accessibilityAction`. Compose: `LazyColumn` items with `Modifier.clickable` and
`semantics(mergeDescendants = true)`; `SwipeToDismissBox` with
`customActions`. Long lists are virtualized (react-window or TanStack Virtual,
`LazyColumn`, `FlashList`).]

---

#### Grid Item

**Category**: Layout / Input
**Status**: Draft
**When to Use**: A selectable cell in a two-dimensional grid: goal cards on the
home screen, a template gallery ("Travel," "Emergency fund," "New phone"), a photo
picker, a bank-logo grid.
**When NOT to Use**: Single-column content (use List Item). Tabular data with
columns that mean the same thing in every row (use Data Table).

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Feedback |
|-------|--------|-------|----------|----------|----------|
| Default | Card or tile: image or icon, title, supporting text or value | — | — | — | — |
| Hovered (pointer) | Elevation or border change; optional quick actions appear | Pointer over | — | 80ms | — |
| Focused (keyboard) | Focus ring on the card | Tab / arrow keys (grid pattern) | — | 60ms | Screen reader: card title and key value |
| Pressed | Brief highlight, then opens the detail | Click / Enter / tap | Navigate | 80ms | — |
| Selected (multi-select) | Check badge + border; distinct from focus | Space / tap in select mode | Toggle selection | Instant | Screen reader: "selected"; count announced |
| Reordering | Card lifts; neighbors shift | Long-press + drag (touch), drag (pointer) | Reorder | 150ms | Haptic on lift and drop |
| Empty slot | Dashed outline with "Add goal" | — | Opens creation | — | — |
| Locked (plan-gated) | Lock badge with the plan name ("Plus") | — | Opens the upgrade explanation, not an error | — | Screen reader: "[Title], requires Plus" |

**Accessibility**:
- Reordering by drag has a non-drag alternative (SC 2.5.7): "Move up / Move down"
  actions or a reorder mode with buttons.
- Card content is one accessible element with one action; secondary actions are
  separate buttons with their own names.
- If arrow-key navigation is offered, the grid role and position are exposed.

**Implementation Notes**: [Web: a list of cards (`<ul>`) with a single link per
card is usually better than an ARIA grid; use the grid pattern only for true 2D
keyboard navigation. Reordering: an accessible drag-and-drop library with
keyboard support (e.g. dnd-kit). SwiftUI: `LazyVGrid` with `.draggable` /
`.dropDestination` plus accessibility actions. Compose: `LazyVerticalGrid`.]

---

#### Modal Dialog

**Category**: Feedback / Layout
**Status**: Draft
**When to Use**: A decision or acknowledgment that must be resolved before the
user can continue: "Your session is about to expire," "Leave without saving?",
a blocking error. Background content is inert.
**When NOT to Use**: Non-blocking information (use Toast / Notification or an
inline message). Long forms or multi-step tasks (use a full screen or, on mobile,
a sheet). Marketing interruptions.

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Feedback |
|-------|--------|-------|----------|----------|----------|
| Opening | Scrim fades in; dialog fades and scales from 0.96 to 1.0 in the center (mobile: may be a bottom sheet) | Triggered by code or user action | Focus moves to the dialog title or first control | 200ms ease-out | Screen reader: dialog title announced |
| Active | Background inert; focus trapped in the dialog | Tab / Shift+Tab cycle inside | — | — | — |
| Confirmed | Dialog closes | Primary button | Execute action; focus returns to the trigger | 150ms | — |
| Cancelled | Dialog closes | Secondary button / Esc / scrim click (if allowed) / system back | No action; focus returns to the trigger | 150ms | — |
| Not dismissible | No cancel path; only resolution options | — | — | — | — |

> **Focus trap rule**: While a modal dialog is open, Tab and Shift+Tab cycle only
> within the dialog, and assistive technology cannot reach the background. When
> the dialog closes, focus returns to the element that opened it — not to the top
> of the page. (WCAG 2.2 SC 2.4.3 Focus Order; the dialog must not become a
> keyboard trap — SC 2.1.2 — because Esc or a close button always leaves it.)

**Accessibility**:
- Role dialog (or alertdialog for urgent decisions); an accessible name from the
  visible title — every dialog has a title.
- Esc triggers cancel; system back (Android) and swipe-down on an iOS sheet do the
  same.
- Reduced motion: no scale; fade only.

**Implementation Notes**: [Web: the native `<dialog>` element with `showModal()`
gives focus trapping, the inert background and Esc for free; otherwise an
accessible dialog primitive. Set `inert` on the rest of the page for custom
dialogs. SwiftUI: `.alert` / `.confirmationDialog` for simple decisions,
`.sheet` for content. Compose: `AlertDialog` / `ModalBottomSheet`.]

---

#### Confirmation Dialog

**Category**: Feedback / Layout
**Status**: Draft
**When to Use**: Confirming a destructive or money-moving action. Always triggered
by Button (Destructive) or by the final step of a payment. Exactly two actions:
confirm (labelled with the specific action) and cancel.
**When NOT to Use**: Non-destructive confirmations ("Are you sure you want to
save?" — just save). Errors that need no decision. Dialogs with more than two
actions.

> **Label rule**: The confirm button names the action — "Delete account," "Cancel
> subscription," "Remove card" — never "OK" or "Yes." A user skimming the dialog
> should be able to tell what the button does from the button alone.

**Structure**:
- Title: the action as a question — "Cancel your Plus subscription?", not "Are you
  sure?"
- Body: the consequence in one or two sentences — "Plus stays active until
  October 31. Your goals and history stay; auto-save rules beyond 3 goals pause."
- Confirm button: Button (Destructive) — "Cancel subscription."
- Cancel button: Button (Secondary) — "Keep Plus."
- Default focus: the cancel button (the safer default).
- High-stakes variants: account deletion adds re-authentication before this
  dialog; bulk deletion in the admin console asks the operator to type the
  record count or the word shown.

**Accessibility**: Inherits Modal Dialog. Role alertdialog so screen readers
announce the urgency; the body is the dialog's description; default focus on
Cancel is a requirement, not a preference.

**Implementation Notes**: [Implement as a parameterized Modal Dialog (title,
body, confirm label, destructive flag). The destructive action executes only in
the confirm handler; the server independently validates the request. SwiftUI:
`.confirmationDialog` with `role: .destructive` and `role: .cancel`. Compose:
`AlertDialog` with the destructive color on the confirm button.]

---

#### Toast / Notification

**Category**: Feedback
**Status**: Draft
**When to Use**: Brief, non-blocking confirmation that needs no decision: "Saved,"
"Link copied," "Goal archived." On Android and the web a **snackbar** variant adds
one action — "Undo" or "Retry."
**When NOT to Use**: Information that requires a decision (use Modal Dialog).
Errors the user must act on to continue (use an inline message or a global
banner — see the app shell's `## Notifications & Banners`). Anything the user
must not miss — toasts are easy to miss by design.

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Feedback |
|-------|--------|-------|----------|----------|----------|
| Entering | Slides up from the bottom (above the tab bar on mobile) or appears top-right on wide web | Triggered by code | — | 200ms ease-out | Screen reader: message announced politely |
| Displayed | Icon, message, optional action ("Undo"), optional close | Pointer hover or keyboard focus pauses the timer | Pause auto-dismiss | — | — |
| Auto-dismiss | Fades out | Timer expires (4s default; 6s or more with an action; never under 4s) | Removed | 200ms ease-in | — |
| Action | Performs Undo / Retry | Click / tap / keyboard | Execute; toast closes | — | Screen reader announces the result |
| Manual dismiss | Closes | Close button / swipe | Removed | 150ms | — |
| Queue | Next toast waits until the current one closes | New toast while one is shown | FIFO, one at a time on mobile | — | — |

**Accessibility**:
- Announced without moving focus: a polite live region (`role="status"`) on the
  web; `UIAccessibility.post(notification: .announcement, …)` / the SwiftUI
  announcement API on iOS; a live-region semantics node on Android (Compose
  `liveRegion`), rather than the older imperative announcement call.
- An action inside a toast must be reachable by keyboard and screen reader before
  the toast disappears — pause the timer on focus, and make every action also
  available elsewhere (the undo of a deletion also exists as "Restore" in the
  archive).
- Reduced motion: fade only.

**Implementation Notes**: [Web: a single toast region mounted once in the app
shell; a headless toast library with a live region. iOS has no system toast —
build it in the component library. Android: `Snackbar` via `SnackbarHostState`
in Compose. Keep toasts below dialogs and above content in the layering scale the
design language defines.]

---

#### Tooltip

**Category**: Feedback
**Status**: Draft
**When to Use**: Supplementary information about a visible element — the meaning
of an icon-only button in the admin console, the definition of "auto-debit day,"
how a fee is calculated.
**When NOT to Use**: Information required to complete a task — put it in the label
or helper text. Touch-first surfaces: there is no hover on a phone, so use an info
button that opens a bottom sheet ("수수료 안내" — fee details) instead.

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Feedback |
|-------|--------|-------|----------|----------|----------|
| Hidden | — | — | — | — | — |
| Hover trigger | — | Pointer enters the element | Start a 400ms delay | — | — |
| Focus trigger | — | Element receives keyboard focus | Start a 300ms delay | — | — |
| Appearing | Tooltip fades in near the element, flipping at viewport edges | Delay elapses | Show | 120ms ease-out | Screen reader reads it as the element's description |
| Displayed | Short text, max width ~280px | Pointer can move onto the tooltip without it closing | Stays visible | — | — |
| Hiding | Fades out | Pointer leaves / focus moves / Esc | Hide | 80ms ease-in | — |

**Accessibility**:
- Content on hover or focus is dismissible (Esc), hoverable and persistent
  (WCAG 2.2 SC 1.4.13).
- The tooltip text is the trigger's accessible description (`aria-describedby`);
  for icon-only buttons, the accessible *name* is set on the button itself, not
  only in the tooltip.
- Contrast 4.5:1 like body text.

**Implementation Notes**: [Web: an accessible tooltip primitive, or the Popover
API for richer content. iOS: `.help()` on iPad/Mac pointer; on iPhone use an info
button with a popover or sheet. Android: `TooltipBox` for long-press on icon
buttons; a bottom sheet for explanations.]

---

#### Progress Bar

**Category**: Feedback / Layout
**Status**: Draft
**When to Use**: Linear progress toward a defined end: progress toward a savings
goal ("310,000원 of 500,000원"), onboarding steps (2 of 4), file upload progress.
Moa's circular progress ring (flag `goals.v2-progress-ring`) follows the same
rules.
**When NOT to Use**: Values without an end point. Short waits under about one
second (show nothing). Unknown-duration loading of content areas (use a skeleton —
see Loading State in the navigation and feedback guidance).

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Feedback |
|-------|--------|-------|----------|----------|----------|
| Default | Track, fill, value label ("62%" and the amounts) | — | — | — | — |
| Value increasing | Fill animates to the new value | Value changes | Smooth fill | 300ms ease-out | — |
| Complete | Fill full; completion treatment (check, color) plus text ("Goal reached") | Value reaches 100% | Completion event | 200ms | Haptic: success (mobile); announced |
| Indeterminate | Looping segment | Unknown duration | — | Loop | Screen reader: "in progress", no value |
| Error (uploads) | Fill stops; error color plus an icon and a Retry action | Failure | — | — | Error announced |

**Accessibility**:
- Role progressbar with value, min and max; `aria-valuetext` carries the human
  wording ("310,000 won of 500,000 won, 62 percent").
- Announce significant milestones (every 25%, completion), not every change.
- Never rely on fill color alone — the numeric label is always present.
- Reduced motion: the value jumps instead of animating; indeterminate loops become
  a static "in progress" indicator.

**Implementation Notes**: [Web: `<progress>` or `role="progressbar"`. SwiftUI:
`ProgressView(value:total:)` with `.accessibilityValue`. Compose:
`LinearProgressIndicator(progress = { … })` / `CircularProgressIndicator` with
`semantics { progressBarRangeInfo = … }`.]

---

#### Input Field

**Category**: Input
**Status**: Draft
**When to Use**: Free text or precise values: email, name, a savings amount, a
phone number, a search query, a one-time code (see the OTP pattern in the
service-specific guidance for the code-entry specifics).
**When NOT to Use**: Choosing from known options (use Dropdown / Select or a
list). Dates (use the Date & Time Picker pattern).

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Feedback |
|-------|--------|-------|----------|----------|----------|
| Default | Visible label above the field; helper text below if needed; empty field | — | — | — | — |
| Hovered (pointer) | Border strengthens | Pointer over | — | 60ms | — |
| Focused | Border in the focus color, caret visible; mobile shows the right keyboard | Tab / click / tap | Keyboard opens (mobile) | Instant | Screen reader: "[Label], text field, [helper text]" |
| Typing | Characters appear; formatting applied without moving the caret | Keyboard | Value updates | Immediate | — |
| Value present | Clear button (×) where useful (search) | — | — | — | — |
| Limit reached | Counter shows "20/20"; further input rejected | Input at limit | Reject | — | Screen reader: limit announced |
| Error | Error border + icon + message below the field | On blur or submit (see Form & Inline Validation) | Show error | Instant | Error announced; `aria-invalid` |
| Valid (where useful) | Success icon for fields users worry about (password rules met) | On validation | — | Instant | — |
| Disabled / read-only | Disabled: 40% opacity; read-only: no border, text selectable | — | — | — | State exposed |

**Service-specific field rules**:
- **Amounts (KRW)**: numeric keyboard (`inputmode="numeric"`), thousands
  separators while typing (`12,000`), the unit after the value (`원`), no decimal
  places (KRW has no minor unit), quick-add chips ("+1만," "+5만," "+10만") next to
  the field rather than a slider.
- **Phone numbers (Korea)**: numeric keyboard, formatted `010-1234-5678` as typed,
  stored in E.164 (`+821012345678`).
- **Email**: `type="email"`, `autocomplete="email"`, no automatic capitalization.
- **Never collect a resident registration number (주민등록번호)** unless a law
  requires it — identity verification services return what is needed instead.

**Accessibility**:
- A visible label is required; the placeholder is an example, never the label
  (WCAG 2.2 SC 3.3.2).
- `autocomplete` values for personal data (SC 1.3.5).
- Errors are text, linked to the field, announced (SC 3.3.1).
- Paste is always allowed — including in password and code fields (SC 3.3.8).

**Implementation Notes**: [Web: `<label for>` + `<input>`; `aria-describedby`
pointing at helper and error text; format amounts with `Intl.NumberFormat('ko-KR')`
without fighting the caret (format on a controlled value, keep the raw digits).
SwiftUI: `TextField` with `.keyboardType(.numberPad)` and `.textContentType`.
Compose: `OutlinedTextField` with `KeyboardOptions(keyboardType =
KeyboardType.Number)` and a `VisualTransformation` for separators.]

---

#### Tab Bar

**Category**: Navigation
**Status**: Draft
**When to Use**: Switching between sibling views of one screen: History "All /
Deposits / Withdrawals," Goal detail "Overview / Rules / History," admin user
detail "Profile / Payments / Notifications." On iOS a segmented control is the
native equivalent for 2–4 short options.
**When NOT to Use**: Top-level app navigation (that is the app shell's tab bar —
`design/ux/app-shell.md`). More than about 5 sections (use a list or a sidebar).
Content users need to see side by side.

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Feedback |
|-------|--------|-------|----------|----------|----------|
| Inactive tab | Label (and optional count) | — | — | — | — |
| Active tab | Label with an active indicator (underline, fill) and stronger weight | — | Panel shows this tab's content | — | Screen reader: "selected" |
| Hovered (pointer) | Subtle background | Pointer over | — | 60ms | — |
| Focused (keyboard) | Focus ring on the tab | Tab into the tab list; arrow keys move between tabs | — | 60ms | Screen reader: "[Label], tab, 2 of 3" |
| Activated | Indicator moves; panel content switches | Click / tap / Enter / Space (or on arrow focus, if automatic activation) | Switch panel; URL or state updates | 150ms | Haptic: selection (mobile) |
| Swipe (mobile, optional) | Panels swipe horizontally | Horizontal swipe | Switch tab | 250ms | — |

**Accessibility**:
- The ARIA tabs pattern: `tablist` / `tab` / `tabpanel`; Left/Right arrows move
  between tabs, Tab moves into the panel; Home/End jump to the first/last tab.
- The active tab is distinguishable by more than color (indicator shape, weight).
- On the web, each tab that represents a meaningful view is reflected in the URL
  (`?tab=deposits`) so back and refresh restore it.

**Implementation Notes**: [Web: an accessible tabs primitive; choose automatic
activation only when panels render instantly. SwiftUI: `Picker` with
`.pickerStyle(.segmented)` for short options. Compose: `PrimaryTabRow` / `Tab`
(Material 3) with a `HorizontalPager` when swipe is supported.]

---

#### Scroll Container

**Category**: Layout
**Status**: Draft
**When to Use**: Content longer than its viewport: the savings history, the
notifications inbox, terms and privacy texts, a long settings screen. The page
itself is the default scroll container; nested scroll regions are the exception.
**When NOT to Use**: Nested scroll areas inside a scrolling page on mobile (they
trap touch scrolling). Data an operator needs to compare across pages (use Data
Table pagination).

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Feedback |
|-------|--------|-------|----------|----------|----------|
| Content fits | No scroll indicator | — | — | — | — |
| Scrollable | Platform scroll indicator; optional fade edges | — | — | — | — |
| Scrolling | Content moves | Wheel / trackpad / touch / keyboard (Space, Page Down, arrows) | Native scrolling | Native | — |
| Focus follows | A focused element scrolls into view, clear of sticky headers and bottom bars | Tab to an off-screen element | Scroll into view | Smooth, or instant under reduced motion | — |
| Scroll to top | Tapping the status bar (iOS) or re-tapping the active tab returns to the top | — | Scroll to top | Smooth | — |
| Scroll restoration | Returning via back restores the previous position | Back navigation | Restore | Instant | — |
| End reached | End-of-list state or the next page loads (see Pagination / Infinite Scroll) | — | — | — | — |

**Accessibility**:
- A scrollable region that is not the page must be keyboard focusable
  (`tabindex="0"` with a label) so keyboard users can scroll it.
- Sticky headers and bottom bars never hide the focused element (WCAG 2.2 SC 2.4.11)
  — use `scroll-padding` on the web.
- Fade edges are only a hint; the scroll indicator stays.

**Implementation Notes**: [Web: rely on document scrolling; restore scroll
position on back (the router's scroll restoration); virtualize very long lists.
SwiftUI: `ScrollView` / `List` with `ScrollViewReader` for programmatic scrolling.
Compose: `LazyColumn` with `rememberLazyListState` saved across navigation.]

---
