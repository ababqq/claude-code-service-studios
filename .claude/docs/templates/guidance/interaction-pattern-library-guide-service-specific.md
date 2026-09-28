> Authoring guidance for interaction-pattern-library.md. Load only the part covering the section currently being authored — not the whole file at once.

> Covers: **Service-Specific Patterns** — full reference specifications for Form & Inline Validation, Data Table, Search / Filter / Sort, Pagination / Infinite Scroll, Date & Time Picker, File Upload, Payment Sheet, OTP / Identity Verification, Permission Prompt, Pull-to-Refresh.

## Service-Specific Patterns

These are the composite patterns web and mobile services build again and again —
and where most of their usability, accessibility, privacy and support-ticket
problems come from. Each specification lists states, the rules that make the
pattern safe for a real service, accessibility for keyboard, pointer, touch and
screen readers, and implementation notes for common stacks (follow
`docs/stack-reference/` where the project's stack differs).

Examples use **Moa**, a subscription savings app for the Korean market (web, iOS,
Android, API) — sign-up with email or Kakao/Naver/Apple, savings goals, Toss
Payments auto-debit, push + 알림톡 notifications, Free and Plus plans — and its web
admin console. Colors, durations and haptics come from the design language
(`design/brand/design-language.md`, `## 2. Color System` and
`## 7. Motion & Feedback`).

---

#### Form & Inline Validation

**Category**: Input / Feedback
**Status**: Draft
**When to Use**: Any form that collects input the service validates: sign-up,
profile, goal creation, payment details, admin edits.
**When NOT to Use**: Single-field inline edits that save immediately (use an
editable field with save/cancel). Search boxes (see Search / Filter / Sort).

**Validation timing** (the most important decision in this pattern):

| Check | When it runs | Why |
|-------|--------------|-----|
| Format (email shape, phone digits) | On blur, not on every keystroke | Errors while the user is still typing are noise |
| Error already shown → fixed | On every keystroke ("reward early") | The error disappears as soon as the input is valid |
| Required fields | On submit | Do not flag empty fields the user has not reached |
| Server-side rules (email already used, goal amount above the plan limit) | On submit, or on blur for slow-to-fix fields (username availability, with debounce) | The server is the authority; the client check is a courtesy |
| Cross-field rules (end date after start date) | On blur of the second field and on submit | |

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Feedback |
|-------|--------|-------|----------|----------|----------|
| Pristine | Labels, helper text, required markers (text "필수" / "(required)", not only `*`) | — | — | — | — |
| Field error | Error icon + message under the field + error border | Blur with invalid value | Show message; keep the value | Instant | `aria-invalid`; message announced when it appears on blur |
| Submitting | Submit button in its Loading state; fields stay visible | Submit | Request sent | Until response | "Saving…" |
| Submit with errors | Error summary at the top listing each error as a link to its field; field messages shown | Submit | Focus moves to the summary | Instant | Summary heading announced with the count ("2개 항목을 확인해 주세요" — check 2 fields) |
| Server field errors | Mapped to the fields they concern | Response with field errors | Same as client errors | Instant | Same |
| Server general error | Inline alert above the submit button; input preserved | 5xx / network | Retry available | — | Announced |
| Success | Navigate to the result, or an inline success message for in-place forms | — | — | — | Toast only when nothing else shows success |

**Service rules**:
- Never clear the user's input on an error. Never disable the submit button to
  signal errors — let the user submit and show what to fix.
- Server errors carry field paths so the client can place them: the API's error
  format (RFC 9457 Problem Details with a per-field `errors` list, as
  `/api-design` sets up) is part of this pattern's contract.
- Long forms autosave drafts locally (never passwords, card data or codes).
- Multi-step forms show the step count ("2 / 4"), keep entered data when going
  back, and validate each step before moving on.
- Error text follows the design language's UI copy rules: what happened and what
  to do, no "invalid", no blame.

**Accessibility**: Visible labels (WCAG 2.2 SC 3.3.2); errors identified in text and
associated with the field (SC 3.3.1, `aria-describedby`); suggestions where known
(SC 3.3.3); review and correction before money-moving submissions (SC 3.3.4);
data already entered is not asked for again (SC 3.3.7); `autocomplete` on personal
fields (SC 1.3.5).

**Implementation Notes**: [Web: a form library with schema validation shared with
the server where the stack allows (e.g. React Hook Form with a Zod schema, the
same schema validating the API input). Native: validation state in the view model;
SwiftUI `.accessibilityValue` / Compose `semantics { error(...) }` for the error.
Map the API's Problem Details `errors[].pointer` to field IDs in one shared
helper.]

---

#### Data Table

**Category**: Layout / Input
**Status**: Draft
**When to Use**: Dense, comparable records with the same columns — the admin
console's users, payments and notification-delivery tables; a B2B customer's
transaction export view.
**When NOT to Use**: Consumer mobile screens (use List Item rows — a table does not
fit a phone). Content where each record needs a rich layout (use cards).

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Feedback |
|-------|--------|-------|----------|----------|----------|
| Default | Header row (sticky), rows, numeric columns right-aligned with tabular numerals, row count ("1–50 of 1,284") | — | — | — | — |
| Loading | Skeleton rows at the final row height | — | — | — | Region `aria-busy` |
| Sort | Header shows the sort direction icon; one sort key by default | Click / Enter on a sortable header | Re-query; sort reflected in the URL | — | `aria-sort` updated and announced |
| Row hover / focus | Row highlight; row actions appear (also always reachable by keyboard) | Pointer / Tab | — | 60ms | — |
| Row open | Opens the detail (route or side panel) | Click / Enter on the primary cell link | Navigate | — | — |
| Selection | Checkbox column; header checkbox selects the page (with an explicit "select all 1,284" option) | Click / Space | Bulk action bar appears with the count | — | "3 selected" announced |
| Bulk action | Actions in the bulk bar; destructive ones use Confirmation Dialog with the count | Click | Execute; progress for long jobs | — | Result announced |
| Empty / filtered-empty / error | See Empty State and Error State in the navigation and feedback guidance | — | — | — | — |
| Narrow viewport (`sm`) | Rows become stacked cards with the key columns; or horizontal scroll with the first column pinned | — | — | — | — |

**Service rules**:
- **PII masking**: personal data is masked by default (`010-****-5678`,
  `kim***@example.com`). Revealing it is a separate action allowed only for
  permitted roles and recorded in an access log. Exports follow the same rule.
- Filters, sort and page live in the URL so an operator can share a view.
- Columns that are sortable are backed by an index on the server (`/data-model`),
  or they are not sortable.
- Time columns show the timezone (`2026-10-25 09:00 KST`), or relative time with
  the absolute time on hover/focus.

**Accessibility**: A real `<table>` with `<th scope>`; `aria-sort` on sorted
headers; the selection checkbox of each row is labelled with the row's name
("Select 김민지"); row actions are buttons with names that include the row
("Refund payment P-10231"). Do not make the whole row a click target without a
focusable link inside it.

**Implementation Notes**: [Web: a headless table library (e.g. TanStack Table)
rendering semantic table markup; server-side sorting and pagination for anything
above a few hundred rows; virtualization only for very large in-memory sets, with
the row count still exposed. Keep column definitions typed from the API contract.]

---

#### Search / Filter / Sort

**Category**: Input / Navigation
**Status**: Draft
**When to Use**: Narrowing a collection: searching transactions by memo, filtering
history by period and type, sorting goals by progress; in the admin console,
finding a user by email, phone or ID.
**When NOT to Use**: Collections short enough to scan (under ~20 items). Global
navigation (use the app shell's command palette or menu).

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Feedback |
|-------|--------|-------|----------|----------|----------|
| Search typing | Search field with clear (×) button | Typing | Query runs after a debounce (~300ms) or on Enter; previous request cancelled | Debounce | Result count announced after results settle |
| Searching | Small inline indicator in the field or results region; previous results stay visible, dimmed | — | — | Until response | `aria-busy` on results |
| Results | Result count ("12건"), matching text highlighted | — | — | — | "12 results" announced politely |
| No results | Empty State (no-results variant) with the query mirrored and a way to widen it | — | — | — | Announced |
| Filter panel | Web `lg`: side panel or filter bar; mobile: bottom sheet with "Apply" and "Reset" | Open control | — | 200ms | — |
| Active filters | Chips above the results ("최근 3개월 ×", "입금 ×"), each removable; "Clear all" | Click chip × | Re-query | — | Change announced |
| Sort | Sort control showing the current order ("최신순" — newest first) | Select | Re-query | — | — |

**Service rules**:
- Search, filters and sort are in the URL on the web (`?q=&type=deposit&from=2026-07-01`)
  and in saved state on mobile, so back and refresh restore them. Typing updates
  the URL with replace, not push.
- On mobile, filters apply when the user taps "Apply" (a sheet with instant
  re-query jumps the list behind it); on the web, filter bars may apply instantly.
- Admin search by phone or email matches normalized forms (`01012345678` finds
  `010-1234-5678`); results mask PII as in Data Table.
- Recent searches stay on the device, can be cleared, and are never used for
  marketing without consent.
- Korean search handles spacing variants and, where the product needs it, initial
  consonant search (초성 검색, "ㅇㅎ" → "여행") — decide explicitly; it is a server
  feature, not a UI trick.

**Accessibility**: The search field has a label (visually hidden if the icon
suffices) and `type="search"` / a search landmark; result updates are announced
without moving focus; filter chips are buttons named "Remove filter: 입금";
the filter sheet is a dialog with a title.

**Implementation Notes**: [Web: URL search params as the single source of filter
state (router hooks), an abortable fetch per query, a server-side query API
(`GET /v1/transactions?q=&type=&from=&to=&sort=-createdAt`). Native: a view model
holding the query state, restored across process death (SavedStateHandle on
Android). Search suggestions follow the combobox pattern on the web.]

---

#### Pagination / Infinite Scroll

**Category**: Navigation / Layout
**Status**: Draft
**When to Use**: Collections too large to load at once. **Infinite scroll** (or
"Load more") for consumer feeds read top-down — savings history, the notifications
inbox. **Numbered pagination** for operator tables where people refer to a
position ("it's on page 3") and need a stable view.
**When NOT to Use**: Infinite scroll where users need the footer, need to compare
positions, or need to return to a specific item reliably without scroll
restoration.

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Feedback |
|-------|--------|-------|----------|----------|----------|
| First page | First N items (e.g. 20) | — | — | — | — |
| Near end (infinite) | Next page requested when the user is ~1 screen from the end | Scroll | Fetch with the cursor | — | — |
| Loading more | Skeleton rows or a spinner row at the end | — | — | Until response | "Loading more" announced politely |
| More loaded | Items appended; scroll position unchanged | — | — | — | "20 more loaded" announced |
| Load more button (accessible alternative) | "더 보기" (show more) button at the end | Click / Enter / tap | Fetch next page; focus moves to the first new item | — | — |
| End of list | "모든 내역을 불러왔어요" (all history loaded) | — | — | — | — |
| Page error | Inline error row with "Retry"; loaded items stay | — | — | — | Announced |
| Numbered pages | Page links, previous/next, page size selector; current page marked | Click / Enter | Navigate; page in the URL | — | `aria-current="page"` |

**Service rules**:
- The API uses cursor-based pagination for feeds (`?cursor=…&limit=20`, the
  response carrying `next_cursor`), which stays correct when new items arrive; page
  numbers are for operator tables only. The contract under `docs/api/` states
  which, and the UX spec's `## API Data` section names it.
- New items that arrive while the user is reading do not shift the list — show a
  "새 내역 3건" (3 new) pill that scrolls to the top when tapped.
- Returning from a detail screen restores the loaded pages and the scroll
  position.
- A list that can grow without bound on the web provides a "Load more" button
  instead of loading automatically when a footer holds needed links.

**Accessibility**: Loading more is announced; keyboard users can reach the end of
the list and the "Load more" button; focus never jumps to the top when items are
appended; numbered pagination is a `nav` landmark labelled "Pagination".

**Implementation Notes**: [Web: an infinite-query data hook (e.g. TanStack Query
`useInfiniteQuery`) with an IntersectionObserver sentinel, plus the button
fallback. iOS: `List` / `LazyVStack` with `.onAppear` on the last rows or a
prefetch threshold. Android: Paging 3 with `LazyColumn`. React Native:
`FlashList`/`FlatList` `onEndReached` with a threshold.]

---

#### Date & Time Picker

**Category**: Input
**Status**: Draft
**When to Use**: Choosing dates and times: the auto-debit day, a goal's target
date, a history period, a notification quiet-hours window, an admin report range.
**When NOT to Use**: Birthdates and other well-known dates — typed fields (with
the format shown) are faster than scrolling a calendar back 30 years. Relative
choices ("every month on the 25th") — offer the recurrence directly.

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Feedback |
|-------|--------|-------|----------|----------|----------|
| Closed | Field showing the value in the locale format ("2026. 10. 25." for ko-KR, "Oct 25, 2026" for en-US) with a calendar button | — | — | — | — |
| Typing (web) | Segmented or masked input accepting typed dates | Keyboard | Parse; validate range on blur | — | Error announced if out of range |
| Open (calendar) | Web: popover calendar; mobile: native picker (wheel or calendar) or a bottom sheet | Click / tap / Alt+Down | Focus to the selected date | 150ms | Dialog title announced |
| Navigate | Arrow keys move by day, Page Up/Down by month, Home/End to week start/end | Keyboard / swipe | — | — | Date announced ("2026년 10월 25일 일요일") |
| Select | Calendar closes; value set | Enter / tap | Commit | — | Haptic: selection (mobile) |
| Range (from–to) | Two fields or one range calendar; presets first: 1개월, 3개월, 6개월, 직접 설정 (custom) | — | End must follow start | — | — |
| Disabled dates | Dimmed with the reason available ("주말에는 출금되지 않아요" — no debits on weekends) | — | Not selectable | — | Reason announced |

**Service rules**:
- **Store instants in UTC; display in the user's timezone** (KST for Moa); a date
  without a time (a goal's target date) is stored as a date, not a midnight
  timestamp — midnight in one zone is the previous day in another.
- A day-of-month choice for recurring debits offers 1–28 (or "last day of the
  month" as its own option) so February does not break the schedule.
- Business-day rules (bank holidays, weekends) are server rules; the picker shows
  their result, it does not re-implement the holiday calendar.
- Ranges have a maximum the API supports (e.g. 1 year for history exports); say it
  before the user picks a longer one.

**Accessibility**: Typed entry is always possible — a calendar-only picker fails
keyboard and screen-reader users; the format is shown in the label or helper
("YYYY. MM. DD."); the calendar follows the ARIA date-picker dialog pattern (grid
with day names as column headers, the selected date with `aria-selected`,
today marked in text as well as color).

**Implementation Notes**: [Web: `<input type="date">` works well on mobile
browsers and is acceptable on desktop for simple cases; use an accessible
date-picker primitive when the design language requires a custom calendar. Use
`Intl.DateTimeFormat` for display. SwiftUI: `DatePicker` (`.graphical` or
`.wheel`); Compose: `DatePicker` / `DateRangePicker` (Material 3) inside
`DatePickerDialog`. Carry dates across the API as ISO 8601 (`2026-10-25`) and
instants with an offset.]

---

#### File Upload

**Category**: Input
**Status**: Draft
**When to Use**: Adding files: a profile photo, a goal cover image, a document for
a support request; in the admin console, a CSV bulk import.
**When NOT to Use**: Taking a photo is the only intent (open the camera directly,
with the Permission Prompt pattern). Text that could be typed.

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Feedback |
|-------|--------|-------|----------|----------|----------|
| Empty | Drop zone (pointer surfaces) with a "파일 선택" (choose file) button; accepted types and max size stated | — | — | — | — |
| Drag over | Drop zone highlighted | Drag a file over | — | 60ms | — |
| Selected / validating | File name, size, thumbnail for images | Choose / drop / camera / photo library | Client checks type and size before uploading | Instant | Errors announced |
| Uploading | Progress Bar with percent; cancel button | — | Upload (resumable for large files) | Real progress | Milestones announced |
| Processing | "Checking the file…" after upload (scan, resize, CSV parse) | — | Server processing | Until done | — |
| Done | Thumbnail or file row with remove/replace | — | — | — | "Uploaded" announced |
| Failed | Error with the reason (too large, unsupported type, network) and Retry | — | Keep the selection for retry | — | Announced |
| CSV import result | Summary: rows accepted, rows rejected with line numbers and reasons, downloadable error report | — | Nothing is applied until the operator confirms | — | — |

**Service rules**:
- Validate type and size on the client for speed and on the server for
  safety; check the file's actual content type, not only its extension.
- Upload directly to object storage with short-lived pre-signed URLs; never
  stream large files through the API server.
- Scan files before they are served to anyone else; serve user uploads from a
  separate domain or with `Content-Disposition` so they cannot run as the app.
- Strip EXIF metadata (including GPS location) from photos before storing them.
- Resize and compress images on the device before upload on mobile to save the
  user's data and time.
- Bulk imports are two-step: validate and preview, then apply after confirmation.

**Accessibility**: The drop zone is never the only way — a real file input button
is always present (WCAG 2.2 SC 2.5.7, 2.1.1); the button's name includes the
accepted types ("Upload receipt (JPG, PNG, PDF, up to 10 MB)"); progress uses the
Progress Bar pattern; errors are text next to the file.

**Implementation Notes**: [Web: `<input type="file" accept>` with a styled label;
drag-and-drop layered on top. iOS: `PhotosPicker` (no photo-library permission
needed for picking) and `fileImporter`. Android: the Photo Picker (no storage
permission needed) and the Storage Access Framework for documents. Uploads via
pre-signed URLs; background upload sessions on mobile for large files.]

---

#### Payment Sheet

**Category**: Input / Flow
**Status**: Draft
**When to Use**: Collecting payment or a payment agreement: starting the Plus
subscription, registering an account or card for Moa's monthly auto-debit, a
one-time top-up of a goal.
**When NOT to Use**: Showing prices (use plan cards) or receipts (use a detail
screen). Anything that would collect raw card numbers into the product's own
forms — card and bank details go through the payment provider's UI or SDK.

**Flow and states**:

| State | Visual | Input | Response | Duration | Feedback |
|-------|--------|-------|----------|----------|----------|
| Review | Amount (`9,900원/월`), what it buys, billing schedule and the next charge date, trial end if any, how to cancel, required agreements (terms of payment, auto-debit consent) as separate checkboxes | — | — | — | Amount read as currency |
| Method | Saved methods first; add new via the provider's widget (card, bank account, easy-pay methods) | Select / add | — | — | — |
| Confirm | Primary button states the action and amount ("9,900원 결제하기" — pay 9,900 won; "자동이체 등록하기" — register auto-debit) | Click / tap | Hand-off to the provider (in-page widget, app switch, 3-D Secure or bank authentication) | — | Haptic on confirm (mobile) |
| Authenticating | Provider's own UI (app switch to a card or bank app, biometric) | — | — | Provider-controlled | Return handled via callback / deep link |
| Waiting for result | "결제 확인 중이에요" (confirming payment) — back is handled, no double submission | — | Server confirms with the provider; the client never decides success | Until confirmed or timeout | — |
| Success | Receipt summary and what happens next (next debit date, Plus active) | — | — | — | Haptic: success; announced |
| Declined / failed | The provider's reason in plain language, the amount not charged, next options (another method, check the limit) | — | Stay on the sheet with input preserved | — | Announced; no card details in the message |
| Unknown result (timeout) | "We're checking your payment" with status to follow by notification; no retry button that could charge twice | — | Server reconciles with the provider | — | — |

**Service rules**:
- **The server is the source of truth.** The client never marks a payment
  successful on its own: the backend confirms the payment with the provider
  (confirm API and/or webhook) and the client reads the result. Every payment
  request carries an idempotency key so retries and double taps cannot charge
  twice.
- **Never touch card data**: the provider's widget or SDK collects it and returns
  a token or billing key; this keeps the product out of the card-data compliance
  scope as far as possible. Log no payment details.
- **Disclosures before commitment** (price, period, renewal, cancellation,
  refunds) follow the commerce checklist of the configured regions —
  `.claude/docs/compliance/<region>.md` § Commerce & Payments.
- **In-app purchase rules**: selling a digital subscription such as Plus inside
  the iOS or Android app is governed by each store's in-app purchase policy and by
  regional rules on alternative payment (for Korea, see
  `.claude/docs/compliance/kr.md` § Commerce & Payments). Decide the channel per
  surface with sourced, current policy — do not assume the web checkout can simply
  be embedded in the app. Moving the user's own money into savings (Moa's
  auto-debit) is not an in-app purchase of digital content.
- Money amounts use the design language's format (`9,900원`, no decimals for KRW);
  VAT inclusion is stated when the rules require it.

**Accessibility**: Required agreements are separate, labelled checkboxes — "agree
to all" may exist but must not be the only control; the amount and schedule are
real text, not images; the provider's widget is tested with screen readers and
its gaps are recorded in `design/accessibility-requirements.md` (Known Intentional
Limitations); the app switch and return are announced ("Returning from the bank
app").

**Implementation Notes**: [Web: the provider's JavaScript payment widget mounted
in the review step; success/fail redirect URLs land on routes that only show the
server-confirmed status. iOS/Android: the provider's mobile SDK or a web view per
its documentation, with app-switch return via universal/app links; Apple Pay and
Google Pay through the provider where supported. Server: confirm or webhook
handler with signature verification and idempotent processing — owned by
`/api-design` and the payments PRD, not by the UI.]

---

#### OTP / Identity Verification

**Category**: Input / Flow
**Status**: Draft
**When to Use**: Verifying a phone number or email with a one-time code; step-up
authentication before a sensitive action (changing the payout account, deleting
the account); legal identity verification (본인인증) where the service must know
who the user is (for example before a first auto-debit agreement, or for
age-restricted services).
**When NOT to Use**: Routine sign-in when passkeys or social login already
authenticate the user. Collecting identity data the service does not need.

**Interaction Specification (one-time code)**:

| State | Visual | Input | Response | Duration | Feedback |
|-------|--------|-------|----------|----------|----------|
| Request | Phone or email field; "인증번호 받기" (send code) | Submit | Code sent; cooldown starts | — | "Code sent to 010-****-5678" announced |
| Code entry | One field (not six separate boxes) with `one-time-code` autofill, numeric keyboard, remaining time ("02:43") | Type / paste / autofill | Auto-submit when complete | Countdown | Remaining time announced at intervals, not every second |
| Verifying | Field disabled with a spinner | — | Server verifies | — | — |
| Wrong code | Error below the field; attempts left ("3회 남았어요" — 3 tries left) | — | Keep the field focused; clear or select the value | — | Announced |
| Expired | "인증번호가 만료됐어요" (code expired) with "다시 받기" (resend) | — | — | — | Announced |
| Resend | Available after the cooldown (the button shows the remaining seconds) | Click / tap | New code; old one invalidated | — | Announced |
| Locked | Too many attempts: when the user can try again, and a support path | — | — | — | Announced |
| Verified | Continue automatically | — | — | — | Haptic: success |

**Identity verification (본인인증)**: the service hands off to an identity
verification provider (PASS app, SMS verification through a carrier-backed
provider) and receives a verification result with stable identifiers (CI/DI)
and the verified name, birthdate and phone — what the service needs, without
collecting a resident registration number (주민등록번호). The UI shows why
verification is needed before starting, handles the app switch and return, and
handles cancellation and failure without losing the user's progress.

**Service rules**:
- Codes are single-use, short-lived, rate-limited per phone/email and per IP, and
  compared in constant time on the server; resend invalidates the previous code.
- Messages do not reveal whether an account exists ("If this email is registered,
  we sent a code").
- SMS codes use a format that platform autofill recognizes (the domain-bound
  format on iOS / the SMS Retriever or User Consent API on Android) so users do not
  have to switch apps.
- 알림톡 can carry informational messages such as verification codes only through an
  approved template; marketing never shares the channel (see
  `.claude/docs/compliance/kr.md` § Marketing Messages & Consent).
- Step-up verification is remembered for a short window so users are not asked
  twice in one flow.

**Accessibility**: One input with `autocomplete="one-time-code"` and paste allowed
(WCAG 2.2 SC 3.3.8 Accessible Authentication); time limits are adjustable or
extendable — resending is always possible (SC 2.2.1); the countdown is not
announced every second; the provider hand-off is announced and returns focus to a
meaningful place.

**Implementation Notes**: [Web: `<input inputmode="numeric" autocomplete="one-time-code">`;
the WebOTP API where supported. iOS: `.textContentType(.oneTimeCode)`. Android:
SMS Retriever API or SMS User Consent API with a Compose text field. Identity
verification through the provider's SDK or web flow, with the result verified on
the server — never trust a client-side "verified" flag.]

---

#### Permission Prompt

**Category**: Flow / Feedback
**Status**: Draft
**When to Use**: Before asking the OS for a sensitive permission: push
notifications (iOS; Android 13 and later), camera (scanning a document), photo
library where the system picker is not enough, contacts (inviting friends),
location, tracking (App Tracking Transparency on iOS); browser notifications on
the web.
**When NOT to Use**: On first launch "just in case". When the system picker
avoids the permission entirely (Photos picker, Android Photo Picker, document
pickers).

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Feedback |
|-------|--------|-------|----------|----------|----------|
| Moment of need | The user does something that needs the permission (turns on goal reminders, taps "Scan receipt") | — | — | — | — |
| Pre-permission explanation | In-app screen or sheet: what the permission enables, in the user's terms ("자동이체 실패를 바로 알려드려요" — we'll tell you right away if an auto-debit fails), with "Allow" and "Not now" | — | "Not now" does not trigger the OS prompt | — | Title announced |
| OS prompt | The system dialog (cannot be styled; shown once per permission on iOS) | Allow / Don't allow | Result returned | — | — |
| Granted | Feature proceeds; a confirmation where useful | — | — | — | — |
| Denied | Feature works without it where possible; explain what is missing and offer "Open settings" | — | Deep link to the app's settings | — | — |
| Previously denied | Do not show the pre-permission screen as if asking anew; show the settings path | — | — | — | — |
| Provisional / partial (where the OS offers it) | Quiet notifications, approximate location, limited photo access — the app works with the partial grant | — | — | — | — |

**Service rules**:
- Ask in context, after the user has seen value — Moa asks for notifications
  after the first goal is created, with a reason tied to that goal.
- OS permission is not marketing consent: push permission lets the app send
  notifications at all; advertising pushes additionally need the separate,
  recorded advertising consent the regional rules require (`.claude/docs/compliance/<region>.md`
  § Marketing Messages & Consent). Keep the two apart in the UI and in the data.
- Store-review rules require the purpose text in the permission request (the iOS
  usage-description strings, the Play policy declarations) to match what the app
  actually does.
- Track grant rates per prompt as a product metric; a low rate means the moment
  or the explanation is wrong.

**Accessibility**: The pre-permission screen is a normal screen with a heading,
text and two buttons; it does not auto-advance into the OS prompt; "Not now" is
as easy to reach as "Allow".

**Implementation Notes**: [iOS: `UNUserNotificationCenter.requestAuthorization`,
`AVCaptureDevice.requestAccess`, `ATTrackingManager` — each after the in-app
explanation; purpose strings in `Info.plist`. Android: the Activity Result API for
runtime permissions (`POST_NOTIFICATIONS`, `CAMERA`), with
`shouldShowRequestPermissionRationale` deciding between explanation and settings.
Web: `Notification.requestPermission()` only from a user gesture; on iOS, web push
works only for web apps added to the Home Screen.]

---

#### Pull-to-Refresh

**Category**: Feedback / Input
**Status**: Draft
**When to Use**: Mobile lists whose content changes on the server while the user
watches — savings history, the notifications inbox, the home feed.
**When NOT to Use**: As the only way to refresh. On desktop web. On screens whose
data updates automatically in real time. Inside forms.

**Interaction Specification**:

| State | Visual | Input | Response | Duration | Feedback |
|-------|--------|-------|----------|----------|----------|
| Pull | Platform indicator appears and follows the pull | Pull down at the top of the list | — | Follows the finger | — |
| Threshold reached | Indicator shows it will refresh on release | — | — | — | Haptic: light impact at the threshold (iOS convention) |
| Refreshing | Indicator spins; list stays visible and scrollable | Release | Fetch the first page | Until response | "Refreshing" announced |
| Done | Indicator retracts; new items appear at the top without jumping the user's position if they scrolled | — | — | 200ms | "Updated" or the count of new items announced |
| Failed | Indicator retracts; snackbar "새로고침하지 못했어요" (couldn't refresh) with Retry; cached content stays | — | — | — | Announced |
| Offline | Indicator retracts immediately; offline banner explains | — | No request | — | — |

**Service rules**:
- Refresh fetches the first page only and merges it; it does not reset loaded
  pages further down (see Pagination / Infinite Scroll).
- On the mobile web, the browser has its own pull-to-refresh; do not add a custom
  one on top — use `overscroll-behavior` to disable the browser's only when the app
  provides its own and never on document-level scrolling.
- Automatic refresh on resume (returning to the app after a while) covers most
  needs; pull-to-refresh is the manual complement.

**Accessibility**: Pull-to-refresh is a gesture; provide an equivalent — a refresh
button in the toolbar or a custom accessibility action ("Refresh") on the list for
VoiceOver and TalkBack users. Announce the result. Reduced motion keeps the
indicator but drops decorative animation.

**Implementation Notes**: [iOS: SwiftUI `.refreshable` or `UIRefreshControl` —
verify with VoiceOver that a refresh action is exposed and add an
`.accessibilityAction(named:)` if it is not. Android: Material 3
`PullToRefreshBox` in Compose. React Native: `RefreshControl` on the list. Web: a
visible refresh button; automatic refresh on window focus via the data-fetching
library.]

---
