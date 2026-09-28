> Authoring guidance for ux-spec.md. Load only the part covering the section currently being authored — not the whole file at once.

# UX Specification Template — Authoring Guidance

Guidance is organized by the template's sections: each `##` heading below has the
same name as the `ux-spec.md` section it serves (`## Header Block` covers the `>`
lines under the H1). When authoring a section of a UX spec, read only that
section's guidance below.

**One worked example runs through every section**: Moa's **Savings History** —
a list of the user's savings transactions (auto-debit deposits, manual top-ups,
withdrawals, failed debits) and the transaction detail it opens. Moa is a
subscription savings app for the Korean market on the web, iOS and Android, with
Toss Payments auto-debit and push + 알림톡 notifications. The spec's file is
`design/ux/savings-history.md`.

---

## Header Block

> **Why the header matters**: The header links the spec to everything it depends
> on and everything that depends on it. `/ux-review`, `/api-design reconcile` and
> the gates read it; a spec without its PRD link cannot be traced to a
> requirement, and a spec without its surfaces cannot be checked for coverage.

**Worked example**:

```
> **Status**: Draft
> **Author**: product-designer
> **Last Updated**: 2026-10-06
> **Screen ID**: `savings-history` — Savings History (list + transaction detail)
> **Surfaces**: web, ios, android
> **Route / Deep Link**: `/history`, `/history/transactions/:transactionId` ·
>   `moa://history/transactions/{transactionId}` · `https://moa.example/history/transactions/{transactionId}`
> **Journey Stage(s)**: Habit, Retention
> **Related PRDs**: `design/prd/payments.md` § UI Requirements, `design/prd/goals.md`
> **Related ADRs**: `docs/architecture/adr-0001-identity-and-auth.md`
> **Related UX Specs**: `design/ux/app-shell.md` (History tab), `design/ux/goal-detail.md`
> **Accessibility Target**: wcag-aa (from `design/accessibility-requirements.md`)
> **Design Source**: figma — https://www.figma.com/design/<fileKey>/Moa?node-id=48-210 · record `design/handoff/savings-history/HANDOFF.md`
```

**Design Source** — the first token is exactly `none`, `claude-design` or `figma`
and follows `design.tool` in `project.yaml`. With `none`, write
`none — markdown spec only`: this spec is the whole design record. With an external
tool, give the node-specific locator (the Figma `?node-id=` URL, or the Claude Design
`…?file=<FILE>.dc.html` / Design artifact URL) and the handoff record
`/design-handoff` wrote for this spec — for Moa's goal detail screen:
`` figma — https://www.figma.com/design/<fileKey>/Moa?node-id=12-345 · record `design/handoff/goal-detail/HANDOFF.md` ``.
The record under `design/handoff/<slug>/` is a reference snapshot, not the source:
the design language wins on visuals, this spec wins on behaviour. `design.tool`
unset is not `none` — ask, and leave the line `[To be designed]` until it is
decided.

Use the slug the screen inventory (`design/inventory/screen-inventory.md`) gives
the screen, so the inventory's `UX Spec` column finds this file.

---

## Purpose & User Need

> **Why this section exists**: Every screen must justify itself from the user's
> side. Screens designed from the system's side ("display the transactions table")
> become data dumps; screens designed from the user's side ("let me confirm my
> money moved as planned") become calm and purposeful. Write this before any
> layout — it is the filter every later decision is checked against.

**Authoring the user need** (one paragraph — the real human need, not the system
function):

Example — weak: "Shows the list of transactions."
Example — strong: "Users hand Moa a monthly auto-debit and then stop thinking
about it — until something looks wrong. The history exists so they can confirm, in
seconds, that their money moved as planned, and understand and fix it when it did
not. It is a trust screen first and a record second."

**Authoring the user goal** (one sentence, testable):
"Confirm the status of the latest auto-debit within one tap from the History tab,
and fix a failed one without leaving the screen."

**Authoring the business goal** (one sentence — what the product needs from this
screen): "Recover failed auto-debits before the user churns, and reduce 'where is
my money?' support tickets."

---

## User Context on Arrival

> **Why this section exists**: The same screen feels different to a user who opened
> it calmly from a tab and to one who tapped a "자동이체 실패" (auto-debit failed)
> push notification. Document who arrives, from where, in what state, so the
> design answers the anxious arrival first. Whether they are signed in and what
> they are allowed to do belongs in `## Auth & Permission State`.

**Worked example answers**:

| Question | Answer |
|----------|--------|
| What was the user just doing? | Most often: tapped the History tab after payday; second: tapped an auto-debit-failed push or 알림톡 button link |
| What is their emotional state? | Calm when checking; anxious when a debit failed — "did I lose money? will I be charged twice?" |
| What cognitive load are they carrying? | Low when checking; high after a failure notification (away from the app's context, maybe mid-commute) |
| What information do they already have? | From a notification: goal name and amount only |
| What are they most likely trying to do? | See whether this month's debit went through; fix a failed one |
| What are they afraid of? | Losing money, a double charge, retrying and not knowing whether it worked |

**Emotional design target** (one sentence): "Reassured — the user sees immediately
whether anything needs them, and anything that does is one clear action away."

---

## Navigation Position

> **Why this section exists**: A screen that does not know its place in the
> navigation cannot define back behavior, deep-link landing or which shell region
> it lives in. If a screen is reachable from many places, that complexity is
> resolved here, in design — not in implementation. The route and the deep links
> are part of the position: every screen that can be linked to has a web route and
> a mobile deep link on the same path.

**Worked example**:

| Surface | Position | Route / deep link | Back behavior |
|---------|----------|-------------------|---------------|
| ios, android | History tab (tab 3) root → push detail | `moa://history`, `moa://history/transactions/{transactionId}` | Detail pops to the list; from a push, the synthetic stack is Home → History → Detail |
| web `lg` | Top nav "내역" → list with detail in a right pane | `/history`, `/history/transactions/:transactionId` (selects the row, opens the pane) | Browser back closes the pane (the detail URL was pushed) |
| web `sm`/`md` | List page → detail page | same routes | Browser back returns to the list with scroll restored |
| any | Also reachable from Goal detail ("전체 내역" — full history) with the goal filter preset | `/history?goalId=g_123` | Back returns to the goal |

Five entry points is manageable; a sixth ("history from settings") would be a
navigation smell — resolve it in the app shell instead.

---

## Entry & Exit Points

> **Why this section exists**: Entry and exit are the screen's contract with the
> rest of the product. Every entry defines what data arrives with it; every exit
> defines what is committed or passed on. Undefined transitions become bugs — the
> user lands on a blank detail, or a retry fires twice. Empty cells mean the design
> work is unfinished.

**Worked example — entries**:

| Trigger | Source | Transition | Data passed in | Notes |
|---------|--------|------------|----------------|-------|
| Tap History tab | App shell | Tab switch | none | Restores the previous filter and scroll position |
| Tap "자동이체 실패" push | OS notification | Deep link, synthetic back stack | `transactionId` | Opens the detail directly; if the session expired, sign-in first, then continue |
| Tap the 알림톡 button link | KakaoTalk | Universal link / App Link; web fallback when the app is not installed | `transactionId` | Web fallback shows the same detail after sign-in |
| "전체 내역" on Goal detail | `goal-detail` | Push | `goalId` filter | Goal filter chip preset and removable |
| Web direct URL / bookmark | Browser | Page load | route params, query filters | Filters restored from the query string |

**Worked example — exits**:

| Exit action | Destination | Transition | Data returned / committed | Notes |
|-------------|-------------|------------|---------------------------|-------|
| Back from detail | List | Pop | none | Focus returns to the row that was opened |
| "다시 시도" (retry) on a failed debit | Same detail, updated | In place | Retry request with an idempotency key | Stays on screen until the server confirms |
| "결제 수단 변경" (change payment method) | Payment method screen | Push | `returnTo` = this detail | After change, returns here and offers retry |
| "영수증 보기" (view receipt) | Receipt (provider page or in-app) | Push / external | `transactionId` | External page announced as leaving the app |
| Tab switch | Other tab | Tab switch | none | List state preserved |

---

## Layout Specification

> **Why this section exists**: The layout is the hand-off between design and
> implementation. It does not need to be pixel-perfect; it must communicate
> hierarchy, grouping and proportion — per breakpoint. Specify the web breakpoints
> `sm` / `md` / `lg` and the mobile size classes compact / regular from the design
> language's `## 4. Layout, Spacing & Grid`, and name the components from its
> `## 5. Components & States`. A layout drawn only for a desktop monitor is not a
> layout for a service whose users are mostly on phones.

**Worked example — wireframe, mobile compact (list and detail)**:

```
┌──────────────────────────────┐   ┌──────────────────────────────┐
│ 내역                    [⚙︎] │   │ ‹ 내역                        │
├──────────────────────────────┤   ├──────────────────────────────┤
│ [전체 ▾] [최근 3개월 ▾]       │   │        ⚠ 자동이체 실패         │ ← STATUS HERO
│ ⚠ 1건의 자동이체가 실패했어요 › │ ← ATTENTION BANNER (only if any failed)
├──────────────────────────────┤   │        50,000원               │
│ 10월 25일                     │   │   여행 자금 · 10월 25일 09:00  │
│ ● 여행 자금   자동이체  50,000원│   │ 잔액 부족으로 출금되지 않았어요 │ ← REASON (plain language)
│ ⚠ 비상금     실패     50,000원 │   │ [ 다시 시도 ]  (primary)       │
│ 10월 1일                      │   │ [ 결제 수단 변경 ]             │
│ ● 여행 자금   추가입금 100,000원│   ├──────────────────────────────┤
│ ...                          │   │ 결제 수단   국민은행 ••1234     │
│ [ 더 보기 ]                   │   │ 거래 번호   T-20261025-0042    │ ← copyable
├──────────────────────────────┤   │ 영수증 보기 ›                  │
│ 홈   목표   [내역]   내 정보   │   └──────────────────────────────┘
└──────────────────────────────┘
```

**Worked example — web `lg`**: list (max 440 px) on the left, detail pane on the
right; the attention banner spans the list; filters in a bar above the list.

**Worked example — the same wireframe from an external Design Source** (the header
reads `` figma — … · record `design/handoff/savings-history/HANDOFF.md` ``, verdict
RETAINED):

```
external: see Design Source — screens listed from the handoff record
- compact: design/handoff/savings-history/screens/list-compact.png, detail-failed-compact.png
- web lg:  design/handoff/savings-history/screens/list-detail-lg.png
- web md:  no frame — listed as an open question for the designer (check 8)
```

**Hierarchy**: status of the latest debit first (attention banner when any failed),
then the dated transaction list, then filters; on the detail, the status hero, the
amount and the reason, then the recovery actions, then the reference data. The
Hierarchy line stays even when screens are cited — a reviewer without Figma access
reads the layout from it. A frame width the design language does not define (the
file's 1280 px desktop frame) is mapped to `lg`, never added as a new breakpoint.

**Worked example — zones per breakpoint**:

| Zone | `sm` / compact | `md` | `lg` / regular | Scroll | Overflow |
|------|----------------|------|----------------|--------|----------|
| Filter bar | Two filter buttons opening sheets | Inline filter bar | Inline filter bar | No | Chips wrap |
| Attention banner | Full width, only when a failed item exists | same | Above the list | No | Two lines max |
| Transaction list | Full width, grouped by date | Full width, centered 720 px | Left pane 440 px | Yes (page) | Rows never truncate the amount; goal name truncates |
| Detail | Separate screen | Separate page | Right pane | Yes (pane) | Wraps |

**Worked example — component inventory**:

| Component | Type | Zone | Purpose | Reuses existing? |
|-----------|------|------|---------|------------------|
| Filter button + sheet | Dropdown / Select (sheet on mobile) | Filter bar | Type and period filters | Yes — pattern library |
| Attention banner | Inline banner | Top | Surfaces failed debits | Yes — `Banner` (warning) |
| Transaction row | List Item | List | One transaction | New — `TransactionRow` (amount, status chip, goal) |
| Status chip | Badge | Row, detail | Completed / pending / failed / cancelled — icon + text | Yes — `StatusChip` |
| Load more | Button (Secondary) | List end | Pagination fallback | Yes |
| Retry | Button (Primary) with Loading state | Detail | Retry a failed debit | Yes |
| Copyable value | Text + copy button | Detail | Transaction number | Yes — `CopyField` |

**Primary focus on open**: the list heading ("내역"); when opened on a detail from a
notification, the detail's status heading.

---

## Auth & Permission State

> **Why this section exists**: Most service screens are reached by people in
> different auth states — signed out after tapping a notification, on a plan that
> does not include the feature, holding someone else's link. The app shell defines
> the global signed-out and session-expired behavior; this section records what is
> specific to this screen, so no boundary is left for the implementation to guess.
> Never reveal that a resource exists to someone who may not see it.

**Worked example table**:

| State | Condition | What the screen shows | Actions allowed | Redirect / recovery |
|-------|-----------|-----------------------|-----------------|---------------------|
| Signed out | Push, 알림톡 or email link opened after sign-out or on a new device | Nothing — redirect | — | Sign in, then land on the linked detail with its `transactionId` |
| Signed in — owner | The transactions belong to the user | Full list and detail | All | — |
| Signed in — not the owner | A transaction URL belonging to another user, or a deleted one | Detail not-found state | Back to the list | — (same response as "missing", so IDs cannot be probed) |
| Plan-gated | Free plan (up to 3 goals) | History of every goal, including archived ones — history is never plan-gated | All | — |
| Session expired mid-action | Token refresh fails while a retry is in flight | App-shell re-authentication sheet over the detail | Re-authenticate, cancel | The server keeps the idempotency key; after sign-in the detail shows the retry's real outcome |
| Step-up required | None on this screen — changing the payment method asks for 본인인증 on its own screen | — | — | — |
| OS permission | None requested here — push permission is asked during onboarding | — | — | — |

Write "none" rows explicitly, as above: an empty row reads as unfinished; a "none"
row reads as decided.

---

## States & Variants

> **Why this section exists**: A screen is a set of states, not one picture.
> Services ship with broken empty states, invisible errors and blank screens when
> the network drops, because only the happy path was designed. Document every
> state: loading, empty (first use and no results), populated, error, offline,
> partial data, permission, session expiry, and the states specific to this screen.
> The table is also QA's test matrix.

**Worked example table**:

| State | Trigger | Visual change | Behavior change | Notes |
|-------|---------|---------------|-----------------|-------|
| Loading (first) | List request in flight | Skeleton rows grouped under two date headers | Filters disabled | Skeleton rows match the final row height (no layout shift) |
| Empty — first use | No transactions yet | "첫 자동이체는 10월 25일이에요" with the goal name | No filters shown | Uses the next scheduled debit from the API |
| Empty — filtered | Filters return nothing | "조건에 맞는 내역이 없어요" + "필터 초기화" (reset filters) | — | Distinct copy from first use |
| Populated | Items returned | Date-grouped rows | All interactions | Default state |
| Has failures | ≥1 failed debit in the last 30 days | Attention banner above the list | Banner links to the oldest unresolved failure | Banner disappears when all are resolved |
| Pending item | Debit in progress (bank processing) | "처리 중" (processing) chip | No retry | Resolves via refresh or push |
| Loading more | Next page requested | Skeleton rows at the end | — | |
| Error — list | List request failed | Inline error with "다시 시도" in the list region | Retry | Cached list shown if available, with its age |
| Partial — goal filter options | Goals request failed | Goal filter disabled with a hint | Rest of the screen works | |
| Offline | No connection | App-shell offline banner; cached list, "10:42 기준" (as of 10:42) | Retry and pull-to-refresh disabled | |
| Session expired | 401 | App-shell global state: re-authentication sheet | Returns to the same list or detail | |
| Detail — not found | Deleted, or not the user's | "내역을 찾을 수 없어요" with a link to the list | — | Same response for "someone else's" as for "missing" (no enumeration) |
| Detail — retrying | Retry requested | Retry button in Loading state; status "다시 시도 중" | Back allowed; no second retry | Server holds the idempotency key |
| Detail — retry succeeded | Server confirms | Status becomes completed; success haptic; banner updates | — | Push confirmation also sent |
| Detail — retry failed | Provider declines again | Reason in plain language + "결제 수단 변경" | Retry limited (e.g. 3 per day, server rule) | |

---

## Interaction Map

> **Why this section exists**: This is the source of truth for what every input
> does on this screen, for every input method: **keyboard**, **pointer** (mouse,
> trackpad), **touch** and **screen reader**. Gaps here are bugs waiting to
> happen, and it is the input to the accessibility review — an action reachable
> only by swipe or hover fails the keyboard and screen-reader columns.

**Worked example — navigation inputs**:

| Input | Surface | Action | Response | Notes |
|-------|---------|--------|----------|-------|
| Tab / Shift+Tab | web | Move through filter buttons → banner → rows → Load more | Visible focus ring | Rows are single tab stops |
| Arrow Up/Down | web (list focused) | Optional roving focus between rows | Focus moves | Only if implemented as a listbox; plain links are fine |
| Pointer hover | web | Row highlight | — | Hover never reveals information that is unavailable otherwise |
| Click / tap row | all | Open detail | Push (mobile), pane (web `lg`), page (web `sm`/`md`) | |
| Swipe from leading edge / system back | ios / android | Back to the list | Pop | Never disabled on this screen |
| Screen reader swipe | ios, android | Move between rows; each row read as one element | "비상금, 실패, 5만 원, 10월 25일" | Merge row contents; amount read as currency |
| Pull down at top | ios, android | Refresh first page | Pull-to-Refresh pattern | Also a "Refresh" accessibility action |

**Worked example — action inputs**:

| Input | Context | Action | Response | Feedback |
|-------|---------|--------|----------|----------|
| Enter / click / tap "다시 시도" | Failed detail | Retry the auto-debit | Loading state → result | Haptic success/error; result announced |
| Enter / click / tap "결제 수단 변경" | Failed detail | Change payment method | Push to payment methods with `returnTo` | — |
| Click / tap copy button | Detail | Copy transaction number | Toast "복사했어요" | Announced politely |
| Enter / tap filter button | List | Open filter sheet / menu | Sheet (mobile), menu (web) | Sheet title announced |
| Esc | web, sheet or menu open | Close without applying | Focus returns to the filter button | — |

**State-specific restrictions**:

| State | Restriction | Reason |
|-------|-------------|--------|
| Loading (first) | Filters disabled | No data to filter yet |
| Retrying | Retry disabled; back allowed | Prevent double charge attempts; server is authoritative |
| Offline | Retry, refresh disabled with the reason shown | Actions need the network |

---

## Data Requirements

> **Why this section exists**: A UI reads data; it does not own it. Every value on
> screen needs a source — an operation from `## API Data` or device-local state —
> an owning service, a trigger that refreshes it, a display format and a rule for
> when it is missing. A value with no owner gets cached forever or recomputed on
> the client; a value with no missing-rule becomes a blank or "undefined" on
> screen.

**Worked example table**:

| Data element | Source | Update trigger | Owner | Format | Null / missing handling |
|--------------|--------|----------------|-------|--------|-------------------------|
| Transaction rows (date, goal, type, status, amount) | `listTransactions` | On open, filter change, pull-to-refresh, scroll end, after a retry | payments | KRW integer shown as "50,000원"; dates in KST, grouped by day | Request fails → list error state (cached list with its age if any); 401 → session expired |
| Next scheduled debit (empty state) | `getGoalSchedule` | On open when the list is empty | goals | "10월 25일", amount in KRW | Missing → generic first-use copy |
| Goal filter options | `listGoals` | First open of the goal filter | goals | Goal names | Request fails → goal filter disabled (partial state) |
| Transaction detail | `getTransaction` | Every detail open | payments | Payment method masked ("국민은행 ••1234"); transaction number copyable | 404 → not-found state (also for other users' IDs) |
| Receipt link | `receipt_url` field of `getTransaction` (provider-hosted page) | With the detail | payments | External link, announced as leaving the app | Missing → link hidden |
| Active filters | Local state (the URL query on the web) | User changes a filter | this screen | — | None → all transactions, last 3 months |

---

## API Data

> **Why this section exists**: A UI reads data and requests changes; it does not
> own either. This section lists every operation the screen calls — the endpoint
> that owns it, when it is called, the fields the screen uses, how it paginates,
> who may call it and whether the contract already has it. `/api-design reconcile`
> reads this section to check the contract under `docs/api/`, and the
> Validation → Build gate checks that every operation named here exists in the
> contract. An operation that is not here does not get built into the API on time.
> Keep the template's columns and the four notes lines — they are what reconcile
> reads.

**Worked example table**:

| Operation | Endpoint (Owning) | Called When | Data Used on Screen | Pagination | Auth | Contract Status |
|-----------|-------------------|-------------|---------------------|------------|------|-----------------|
| `listTransactions` | `GET /v1/transactions?goalId=&type=&status=&from=&to=&cursor=&limit=20` — payments (`design/prd/payments.md`) | On open; filter change; pull-to-refresh; scroll end | Date, goal name, type, status, amount per row; `next_cursor` | Cursor (`next_cursor`), 20 per page, newest first | Signed-in owner | proposed |
| `getGoalSchedule` | `GET /v1/goals/{goalId}/schedule` — goals (`design/prd/goals.md`) | On open, only when the list is empty | Next debit date and amount | none | Signed-in owner | proposed |
| `listGoals` | `GET /v1/goals?fields=id,name&status=all` — goals | First open of the goal filter | Goal id and name | none (≤ 50 per user) | Signed-in owner | in contract |
| `getTransaction` | `GET /v1/transactions/{transactionId}` — payments | Every detail open | Status, amount, goal, failure reason, masked payment method, transaction number, `receipt_url` | none | Signed-in owner (404 for anyone else) | proposed |
| `retryTransaction` | `POST /v1/transactions/{transactionId}/retry` — payments | "다시 시도" on a failed debit | New status | none | Signed-in owner | proposed |

**Writes**: `retryTransaction` carries an `Idempotency-Key` header created when the
user taps retry and reused if the request times out, so a retry never charges
twice. 409 (retry in progress) → retrying state; 422 (not retryable) → reason
shown; 429 → "try again later". A success refetches the list and the detail.

**Aggregation**: none proposed — first paint needs only `listTransactions`; the
goal options load when the filter opens and the schedule only for the empty state.

**Freshness**: list stale after 30 s, refetched on focus and after a retry; detail
refetched on every open; goal options cached for the session; schedule cached with
the goal.

**Realtime**: none — a debit-result push refetches the list when the app returns
to the foreground; otherwise pull-to-refresh.

**Rules to state for every screen**:
- The payment method arrives **masked** from the API (`account_last4`, bank name);
  the UI never receives full account or card numbers.
- Amounts arrive as integers in KRW (no floating point, no minor unit); the UI
  formats them.
- Timestamps arrive as ISO 8601 instants with an offset; the UI displays KST (or
  the user's timezone).

---

## Analytics Events

> **Why this section exists**: Two kinds of events leave a screen. **Actions**
> change state through the API (listed in `## API Data`); **analytics events**
> measure whether the screen does its job. Analytics events follow the naming
> convention in `project.yaml` `naming.events` (for Moa `object_action`, snake_case),
> are appended to `design/product/tracking-plan.md` with their properties and PII
> classification, and connect to the PRD's `## Success Metrics & Instrumentation`.
> Specify them now — added after launch, they have no baseline.

**Worked example table**:

| User action | Event | Properties | PII | Measures |
|-------------|-------|------------|-----|----------|
| Opens the list | `transaction_list_viewed` | `entry_point` (tab, goal_detail, deep_link), `has_failures` | none | Reach; share of visits with a failure |
| Applies a filter | `transaction_filter_applied` | `type`, `period` | none | Whether filters are used at all |
| Opens a detail | `transaction_detail_viewed` | `status`, `type`, `entry_point` (list, push, alimtalk) | none — IDs only, no amounts | Notification-to-detail conversion |
| Taps retry | `auto_debit_retry_tapped` | `transaction_id`, `attempt` | pseudonymous ID | Recovery funnel start |
| Retry outcome | `auto_debit_retry_completed` (server-side) | `result` (succeeded, declined), `decline_code` | none | Recovery rate — the PRD's success metric |

Never put amounts, account details, names or free text in analytics properties
unless the tracking plan classifies them and a consent basis exists.

---

## Transitions & Animation

> **Why this section exists**: Transitions communicate hierarchy and causality —
> a push says "deeper", a fade says "somewhere else". Use the platform's native
> transitions on iOS and Android (users know them; reimplementations feel wrong)
> and the design language's motion tokens everywhere else. Plan reduced motion
> from the start.

**Worked example table**:

| Transition | Trigger | Type | Duration / token | Interruptible | Reduced motion |
|------------|---------|------|------------------|---------------|----------------|
| List → detail (mobile) | Tap row | Native push | Platform default | Yes (swipe-back) | Platform handles it |
| List → detail page (web `sm`/`md`) | Click row | None — the route changes, content swaps | — | — | — (nothing animates) |
| Detail pane (web `lg`) | Select row | Cross-fade pane content | `motion.fast` | Yes — a new selection cancels | Instant swap |
| Filter sheet | Tap filter | Sheet slide up | Platform default / `motion.medium` | Yes | Fade |
| New items pill | New transactions arrive | Pill slides in at the top | `motion.fast` | — | Appears in place |
| Retry → success | Server confirms | Status chip changes; success check | `motion.medium` + haptic success | No | Chip changes instantly; haptic kept (haptics are not motion) |

---

## Input Method Completeness Checklist

> **Why this section exists**: Completeness is not optional: a flow that needs a
> swipe, a hover or a drag excludes people and fails accessibility law in several
> markets. Fill the checklist before the spec is Approved; an unchecked item blocks
> implementation.

**Worked example (Savings History)**:

- [x] Every action is reachable with a keyboard alone on the web (filters, rows, retry, copy, load more)
- [x] Every action is reachable with VoiceOver, TalkBack and a desktop screen reader (NVDA or 센스리더)
- [x] No action depends on hover; hover only highlights
- [x] Every gesture has a button or accessibility-action equivalent (pull-to-refresh → Refresh action; swipe-back → back button)
- [x] Touch targets ≥ 44 pt (iOS) / 48 dp (Android); ≥ 24 × 24 CSS px on the web
- [x] Works at 200% browser zoom and at the largest Dynamic Type / font scale without clipping amounts
- [x] Works in portrait and landscape

---

## Screen-Level Accessibility Requirements

> **Why this section exists**: Project-wide commitments live in
> `design/accessibility-requirements.md` — its `> **Target**:` line is the bar.
> This section records only what is specific to this screen: the contrast of its
> own color pairs, its focus order, what it announces and where its cognitive load
> sits. Retrofitting these after build is expensive; specify them now.

**Worked example — contrast**:

| Element | Foreground / background token | Required (wcag-aa) | Pass? |
|---------|------------------------------|--------------------|-------|
| Amount text | `color.text.primary` / `color.bg.surface` | 4.5:1 | [verify in both themes] |
| "실패" chip text | `color.feedback.danger` text / `color.feedback.danger-subtle` bg | 4.5:1 | [verify] |
| Chip icon | danger icon / subtle bg | 3:1 | [verify] |
| Attention banner text | `color.text.primary` / `color.feedback.warning-subtle` | 4.5:1 | [verify] |

**Worked example — color is never the only signal**: the failed status has the ⚠
icon and the word "실패"; pending has "처리 중"; amounts of withdrawals carry a
minus sign ("−50,000원"), not only a different color.

**Worked example — focus order** (web, list): skip link → top nav → page heading
"내역" → type filter → period filter → attention banner link → first date heading
(not focusable) → rows in order → "더 보기" → footer. Detail pane: status heading →
retry → change method → copy → receipt link.

**Worked example — screen-reader announcements**:

| State change | Announcement | Timing |
|--------------|--------------|--------|
| List loaded | "내역 24건" (24 transactions) | When loading completes |
| Filter applied | "필터 적용됨, 3건" (filter applied, 3 results) | After results settle |
| More loaded | "20건 더 불러왔어요" (20 more loaded) | After append |
| Retry started | "다시 시도하는 중" (retrying) | On press |
| Retry result | "자동이체가 완료됐어요" (auto-debit completed) / the decline reason | When the server confirms |
| Copied | "거래 번호를 복사했어요" (transaction number copied) | On copy |

**Cognitive load**: the list asks the user to track date, goal, type, status and
amount per row — five streams, acceptable because status is the only one that needs
action, and the attention banner lifts failures out of the list so the user does
not have to scan for them.

---

## Localization Considerations

> **Why this section exists**: UI built for one language breaks in the next. The
> locales come from `localization.locales` in `project.yaml` (Moa: `ko-KR`,
> `en-US`). English strings usually run longer than Korean ones, amounts and dates
> change format per locale, and right-to-left layouts are needed only if an RTL
> locale is configured. Give every text element a length budget and an overflow
> rule, and let `/localize` extract the strings.

**Worked example table**:

| Text element | ko-KR baseline | en-US | Max | Overflow | Risk |
|--------------|----------------|-------|-----|----------|------|
| Screen title | "내역" (2 chars) | "History" | 16 | — | Low |
| Status chip | "실패" | "Failed" | 12 | Never truncate — chip grows | Medium |
| Type label | "자동이체" | "Auto-debit" | 14 | Truncate with the full text exposed to assistive tech | Medium |
| Failure reason | "잔액 부족으로 출금되지 않았어요" | "Not withdrawn — insufficient balance" | 80 | Wraps | Low |
| Amount | "50,000원" | "₩50,000" | — | Never truncates; layout gives amounts priority | High |
| Date header | "10월 25일" | "Oct 25" | — | — | Low |

Plurals and counts use ICU message format ("{count}건", "{count, plural, one {# transaction} other {# transactions}}");
never concatenate translated fragments.

---

## Acceptance Criteria

> **Why this section exists**: Acceptance criteria are the definition of done a
> QA engineer can verify without asking the designer what was meant. Each one is
> binary and specific to this screen; together they cover the states, the entry
> points and the accessibility commitments above. Stories created from this spec
> copy them.

**Worked example criteria**:

- [ ] Given a failed auto-debit, when the user taps its push notification while signed out, then after sign-in the detail opens with History and Home beneath it in the back stack.
- [ ] Given the user taps "다시 시도" twice quickly, then exactly one retry request reaches the server (one idempotency key) and the button shows its loading state.
- [ ] Given a transaction ID that belongs to another user, when it is opened by URL, then the not-found state is shown and no data about it is returned.
- [ ] Given 45 transactions, when the user scrolls to the end, then pages load 20 at a time, the end-of-list message appears after the last page, and "더 보기" works with a keyboard alone.
- [ ] Given the device is offline, when the user opens History, then the cached list is shown with its timestamp and retry is disabled with the reason visible.
- [ ] The failed status is identifiable without color (icon + "실패"), verified in both themes.
- [ ] VoiceOver and TalkBack read each row as one element in the order goal, status, amount, date.
- [ ] Amounts are never truncated at the largest Dynamic Type size or at 200% browser zoom.
- [ ] `transaction_detail_viewed` fires with `entry_point=push` when opened from a notification, and carries no amount or account data.

---

## Open Questions

> Track unresolved design questions with an owner and a deadline. An Approved spec
> has none open — each is decided or explicitly deferred with a reason.

**Worked example questions**:

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|------------|
| How many retries per day does the provider allow before the account is flagged? | backend-engineer | Before the payments epic | Pending — check the provider contract; the UI limit follows the server rule |
| Should withdrawals from a goal appear here or only on Goal detail? | product-manager | Sprint 3 | Pending — PRD `## Functional Requirements` decides |
| Does the admin console need the same list with PII masking, or a separate table spec? | product-designer | Before admin epic | Pending — likely a separate Data Table spec |
| Is the receipt provider-hosted page accessible with 센스리더? | accessibility-specialist | Before Hardening | Pending — record in Known Intentional Limitations if not |
