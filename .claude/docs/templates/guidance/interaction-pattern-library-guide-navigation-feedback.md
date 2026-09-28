> Authoring guidance for interaction-pattern-library.md. Load only the part covering the section currently being authored — not the whole file at once.

> Covers: **Navigation Patterns** (Screen Push / Pop / Replace — including browser history and deep links; Focus Management; Escape / Cancel — including the browser back button, iOS swipe-back and Android system back) and **Feedback and Loading Patterns** (Loading State, Empty State, Error State — including toasts and snackbars as feedback) — full reference specifications.

Examples use **Moa**, a subscription savings app on the web, iOS and Android, and
its web admin console. Durations and easing come from the design language's
`## 7. Motion & Feedback`; the values below are worked examples.

## Navigation Patterns

---

#### Screen Push / Pop / Replace

**Category**: Navigation
**Status**: Draft

These three patterns define how screens enter and leave the navigation history —
the in-app stack on iOS and Android, the browser history on the web.

| Pattern | Trigger | Animation | History Behavior | Focus Behavior |
|---------|---------|-----------|------------------|----------------|
| Push | Navigate deeper (open a goal, open a transaction, open a settings sub-page) | Mobile: new screen slides in from the trailing edge (iOS) or with the platform's shared-axis transition (Android). Web: no slide; content swaps. | Previous screen stays in the stack; on the web a new history entry (`history.pushState` / the router's `push`) | Focus moves to the new screen's heading (web) or first element (native screen readers do this for native navigation) |
| Pop (Back) | Back button, system back, swipe-back, browser back, Esc where applicable | Reverse of Push | Current entry removed; previous screen restored with its scroll position and form state | Focus returns to the element that triggered the Push (the tapped row), or the heading if it no longer exists |
| Replace | Navigate to a peer, redirect after sign-in, move from a finished flow to its result | Cross-fade | Current entry replaced (`history.replaceState` / router `replace`) — back does not return to it | Focus moves to the new screen's heading |

**Replace is the right choice when going back would be wrong**: after sign-in (back
must not return to the login form), after completing a payment (back must not
resubmit or show the checkout again), when a filter or sort changes on a list
(each keystroke must not create a history entry — replace the URL query instead).

**Browser history rules (web)**:
- Every screen and every meaningful view state (tab, filters, page, selected
  item in a master–detail layout) has a URL, so back, refresh and a shared link
  all restore it.
- The browser back button follows what the user perceives as "a page": opening a
  modal dialog does not push an entry by default; a full-screen modal flow on
  mobile web may push one so that back closes it.
- Forms with unsaved input warn on navigation (`beforeunload` for leaving the
  site, an in-app confirmation for in-app routes) — only when there is real input
  to lose.
- Scroll position is restored on back; it is reset to the top on push.

**Deep links**:
- Every linkable screen has a custom-scheme link and a universal link (iOS) /
  App Link (Android) on the same path as the web route:
  `moa://goals/{goalId}` and `https://moa.example/goals/{goalId}`. When the app
  is not installed, the web route opens.
- A deep link builds a **synthetic back stack**: opening a transaction from a
  "자동이체 실패" (auto-debit failed) push lands on the transaction detail with the
  History list and Home beneath it, so back walks up the hierarchy instead of
  exiting the app.
- A deep link into a signed-in screen while signed out goes to sign-in first and
  continues to the target afterwards (`/login?next=/goals/g_123`).
- A deep link to something that no longer exists (a deleted goal) lands on the
  parent list with an explanation, not an error screen.
- Links are never trusted: the screen loads the object through the API with the
  user's permissions (a link to someone else's goal is a 404, not a leak).

**Animation durations**: Push/Pop: platform defaults on native (do not
reimplement them); web content swap 150ms cross-fade or none. Replace: 150ms fade
out + 150ms fade in.

**Motion reduction**: Slides become fades; web transitions become instant.

**Implementation Notes**: [Web: the framework router (Next.js App Router, React
Router, etc.) with `push` / `replace`; scroll restoration enabled; announce the
route change (see Focus Management). iOS: `NavigationStack` with a path bound to
state so deep links can set the full path at once. Android: Navigation Compose
with deep-link destinations and `TaskStackBuilder` / the navigation library's
back-stack synthesis for links opened from notifications. React Native: React
Navigation linking config with the same path structure as the web routes.]

---

#### Focus Management

**Category**: Navigation
**Status**: Draft

> Focus management is the most common keyboard and screen-reader failure in web
> apps, and single-page apps make it worse: a client-side route change swaps the
> content without the page load that screen readers rely on. A user must never be
> left unable to see where focus is, or with focus on something that no longer
> exists.

| Rule | Description |
|------|-------------|
| Screen open (route change, web) | Move focus to the new page's main heading (`h1` with `tabindex="-1"`) or to `main`; update `document.title`; the title or heading is announced. Do not leave focus on the link that was activated. |
| Screen open (native) | Native navigation moves VoiceOver/TalkBack focus to the new screen; custom transitions must post a screen-changed notification to do the same. |
| Screen close / pop | Focus returns to the element that triggered the navigation (the row that was tapped). If it no longer exists, focus goes to the nearest preceding element or the heading. |
| Modal open | Focus moves into the dialog and is trapped there. See Modal Dialog in the standard controls guidance. |
| Modal close | Focus returns to the element that opened it. |
| Element disabled while focused | Focus moves to the next available element; never to the top of the page. |
| Element removed while focused | (e.g. deleting a list row) Focus moves to the next row, or the previous one if it was last, or the list heading if the list is now empty. |
| Inline content change | Content that appears after an action (validation errors, a loaded section) does not steal focus unless the user must act on it; announce it instead. |
| Tab order | Follows the visual reading order (left to right, top to bottom; for Korean and English the same). Never use positive `tabindex` values. |
| Focus is always visible | A focus indicator is visible on every element reached by keyboard (WCAG 2.2 SC 2.4.7) and is not hidden behind sticky headers, bottom bars or banners (SC 2.4.11). `:focus-visible` shows it for keyboard users without showing it on every mouse click. |
| Skip link | The first focusable element on every web page skips to the main content ("본문 바로가기"). |

---

#### Escape / Cancel

**Category**: Navigation
**Status**: Draft

> "Go back / cancel" is the most-used navigation input. Each surface has its own
> physical form of it, and users expect each one to work the way their platform
> works. Every screen spec defines what back does on that screen.

| Surface / input | Input | Behavior |
|-----------------|-------|----------|
| Web — keyboard | Esc | Closes the top-most overlay (menu, popover, dialog, sheet). Never navigates the page back. |
| Web — browser back button / gesture | Back button, `Alt+←` / `⌘[`, trackpad swipe | Goes to the previous history entry (see Screen Push / Pop / Replace for what creates entries). An open full-screen modal flow that pushed an entry closes. Unsaved input prompts a confirmation. |
| iOS — back button | "‹ [Previous title]" in the navigation bar | Pops the stack. |
| iOS — swipe-back | Swipe from the leading screen edge | Pops the stack interactively; the user can cancel mid-gesture. Keep it working — do not disable it on normal screens, and do not place horizontal carousels or sliders flush against the leading edge. |
| iOS — sheets | Swipe down / close button | Dismisses; with unsaved input, the sheet refuses the swipe and asks to discard (`interactiveDismissDisabled` + a confirmation). |
| Android — system back | Back gesture from either screen edge, or the back button in three-button navigation | Closes the top-most overlay, then pops the stack; on a tab's root, goes to the start destination; on the start destination, leaves the app. **Predictive back**: the system shows a preview of where back will go — register back handling through the platform callback API so the preview is correct, and never intercept back on normal screens. |
| Android — up button | "←" in the top app bar | Goes to the logical parent screen (which may differ from back after a deep link). |
| Screen reader | VoiceOver two-finger "Z" scrub; TalkBack back gesture | Same as the platform's back. Custom overlays must honor it (`accessibilityPerformEscape` on iOS). |

**Rules**:
- Back never does something other than "go back / cancel". It never submits,
  never deletes and never moves forward.
- A step that cannot be abandoned (a payment already submitted and waiting for
  the provider's result) handles back by showing why the user must wait — it does
  not silently navigate away, and it does not trap the user forever (show a way
  out once the result is known or after a timeout, with the status explained).
- Leaving a form with unsaved input asks "Discard changes?" with "Discard" /
  "Keep editing" — only when there is input to lose.
- Every screen spec states its back behavior explicitly, including after a deep
  link.

---

## Feedback and Loading Patterns

**Choosing the feedback channel** — the patterns below cover states of a screen
or a component. Transient confirmations of an action use a **toast** ("저장했어요"
— saved) or, when there is one useful follow-up, a **snackbar** with a single
action ("Undo" after archiving a goal, "Retry" after a failed refresh). Both are
specified in Toast / Notification in the standard controls guidance; the rules
that decide between channels are:

| The user needs to… | Channel |
|--------------------|---------|
| Know an action worked, no follow-up | Toast (4s), or nothing when the result is visible on screen |
| Be able to reverse what they just did | Snackbar with "Undo" (6s or more; paused on focus); the action is performed immediately and reversed on Undo |
| Retry something that failed without leaving the screen | Snackbar with "Retry", or an inline error with a retry button when the failed content occupies a region |
| Fix an input | Inline message at the field (never a toast) |
| Know about a problem that affects the whole product | Global banner (app shell `## Notifications & Banners`) |
| Decide before continuing | Modal Dialog |

Toasts and snackbars never carry information that exists nowhere else, never
hold the only path to an action, and never announce by stealing focus.

---

#### Loading State

**Category**: Feedback
**Status**: Draft

| Scope | Pattern | Notes |
|-------|---------|-------|
| First load of a screen | Skeleton of the screen's layout (header, cards, list rows in their final sizes) | Layout does not shift when content arrives (Cumulative Layout Shift). No blank white screen. |
| Region / component | Skeleton or a small spinner in the region; the rest of the screen stays usable | Each region loads and fails independently (partial data). |
| Button-triggered action | The button's Loading state (spinner, disabled, fixed width) | Prevents double submission. |
| Background refresh | No indicator under about 1s; then a subtle indicator (pull-to-refresh spinner, "Updating…" label) | Showing spinners for fast operations is more disruptive than waiting. |
| Optimistic update | Show the result immediately (toggle flips, row archived); roll back with a snackbar if the server rejects it | Only for actions that almost always succeed and are cheap to reverse — never for payments or transfers. |
| Long operation (export, large upload) | Progress Bar with real progress; the user may leave and is notified on completion | State the expected time if known. |
| Server-driven wait (payment confirmation) | A dedicated waiting state with what is happening ("결제 확인 중이에요" — confirming your payment) and what not to do ("do not close this screen") | Poll or subscribe for the result; time out into a clear status, never an endless spinner. |

**Accessibility**: Announce the start of a long load politely ("Loading your
history") and its completion ("24 transactions loaded"); skeletons are hidden from
assistive technology (`aria-busy="true"` on the region while loading); spinners
have a text alternative; reduced motion replaces shimmer with a static skeleton.

---

#### Empty State

**Category**: Feedback
**Status**: Draft

> Empty states are the first thing a new user sees in almost every feature, and
> they are routinely left undesigned. They are the difference between "this is
> where my goals will live" and "did something break?". Every list, table and
> grid has a designed empty state. An empty state is not an error — it is a
> starting point.

| Location | Empty State Content | Notes |
|----------|---------------------|-------|
| Goals (first use) | Illustration (decorative). "아직 목표가 없어요" (no goals yet). Sub-message: what a goal does for the user. Primary action: "목표 만들기" (Create goal). | First-use empty states sell the feature and offer exactly one next step. |
| History (no transactions yet) | "첫 자동이체는 10월 25일이에요" (your first auto-debit is on October 25) — when the next event is known, say it. | Specific beats generic. |
| Notifications inbox | "새 알림이 없어요" (no new notifications). Link to notification settings. | Not an illustration-heavy state; users check this often. |
| Search / filter with no results | "'여행'에 대한 결과가 없어요" (no results for 'travel'). Actions: clear filters, change the period. | Mirror the query back; offer the way to widen it. Distinct from first-use. |
| Admin console table with no rows | "No users match these filters" with the active filters listed and "Clear filters". | Operators need to know it is the filter, not missing data. |
| Permission-limited | "Plus 플랜에서 목표를 3개 이상 만들 수 있어요" (create more than 3 goals on Plus) with the upgrade path | Gated is not empty — say why, and what unlocks it. |

**Rule**: Every empty state has a message and either a sub-message or an action.
A blank container with no explanation is never acceptable. First-use, no-results,
filtered-empty and gated states are different states with different copy.

**Accessibility**: The empty-state message is real text in the reading order, not
only an illustration; announce "No results" when a search returns nothing.

---

#### Error State

**Category**: Feedback
**Status**: Draft

| Error Type | Pattern | Tone |
|-----------|---------|------|
| Input validation (form field) | Inline message below the field, error icon, error border; on submit also an error summary at the top that links to each field. See Form & Inline Validation in the service-specific guidance. | Specific and neutral — "휴대폰 번호 11자리를 입력해 주세요" (enter all 11 digits), not "Invalid input". |
| Recoverable operation failed (save, refresh) | Snackbar with "Retry" for background actions; inline error with a retry button when a region failed to load; the user's input is always preserved. | Calm and actionable — "저장하지 못했어요. 다시 시도해 주세요." (couldn't save — please try again). |
| Network offline | Global offline banner (app shell `## Global States`) plus disabled actions that need the network, with the reason. | Explains what still works. |
| Session expired (401) | Re-authentication sheet or redirect with `next=`, preserving unsaved work. | Never "Error 401". |
| Permission denied (403) | Explain the role or plan that is needed and how to get it. | Not an error tone — a gate. |
| Not found (404) | Screen with a way back (parent list, home); for deep links see Screen Push / Pop / Replace. | "이 목표를 찾을 수 없어요" (we can't find this goal). |
| Conflict (409) / stale data | "This was changed elsewhere" with the options to reload or review. | Never silently overwrite. |
| Rate limited (429) | Tell the user when they can try again ("잠시 후 다시 시도해 주세요" — try again shortly), and disable the action until then. | |
| Server error (5xx) / unknown | Region-level error with retry; full-screen only when nothing can render. Include a support reference (request ID) the user can copy. | Reassuring — acknowledge, give agency, never blame the user. |
| Payment declined | Inline on the payment step with the reason the provider returned in plain language and the next step (another card, check the limit) | Specific, private (no card details in the message), no alarm. |

**Principles**:
- Error messages are never the user's fault. They say what happened and what to do
  next. Remove "invalid" and raw codes from user-facing messages; log the codes.
- Preserve what the user entered. Losing a filled form to an error is the most
  common reason users abandon.
- Every error state has a way forward — retry, an alternative, or support.
- No personal data, tokens or stack traces in error messages.

**Accessibility**: Errors are announced (live region or focus to the error
summary on submit), identified in text rather than color alone (WCAG 2.2 SC
3.3.1, 1.4.1), and suggestions are given where known (SC 3.3.3).

---
