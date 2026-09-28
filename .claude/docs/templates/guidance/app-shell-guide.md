> Authoring guidance for app-shell.md. Load only the part covering the section currently being authored — not the whole file at once.

# App Shell Template — Authoring Guidance

Guidance is organized by the template's sections (`## Navigation Model`,
`## Global Regions per Breakpoint`, `## Persistent Elements`, `## Global States`,
`## Notifications & Banners`, `## Accessibility`). When authoring a section of
`design/ux/app-shell.md`, read only that section's guidance below.

Two worked examples run through every section:

- **Moa consumer app** — a subscription savings app on iOS, Android and the web,
  with a bottom tab bar on phones and a top navigation on wide web screens.
- **Moa admin console** (`apps/admin`) — an operator-facing web app with the
  classic SaaS shell: a collapsible sidebar, a top bar with search and account
  menu, dense tables in the content area.

---

## Before You Start — the Shell's Rule of Necessity

> **Why this comes first**: The app shell is everything that stays on screen while
> the user moves between screens — navigation, persistent controls, global banners.
> It is the part of the product users see in every session, so every element added
> to it costs attention on every screen. Without an explicit rule, elements get
> added one reasonable request at a time ("support wants a chat button", "growth
> wants a promo banner") until the shell crowds out the content. Write the rule
> down so it can be cited when the next request arrives.

**Authoring the shell principle** (one paragraph, a stance rather than a feature
list):

[Example (Moa consumer app): "The shell carries navigation and money-state
warnings only. A payment problem is the one thing allowed to follow the user
across screens; everything else lives on the screen where it matters."

Example (admin console): "Operators work in long sessions across many records.
The shell optimizes for speed: every destination is one click or one keyboard
shortcut away, and the content area gets the width."]

**Authoring the rule of necessity** — complete the sentence "An element earns a
place in the shell when ______":

[Example: "…users would otherwise have to leave their task to find it, or would
miss something that costs them money."]

---

## Navigation Model

> **Why this section exists**: The navigation model decides the top-level
> destinations, how users move between them, where deep links land and what
> "back" means. Every screen spec's Navigation Position section refers to it. A
> model decided screen by screen produces three ways to reach settings and a back
> button that leaves the app from a deep-linked detail screen.

**Worked example — mobile tab-bar shell (Moa consumer app)**:

| Destination | Surface | Placement | Route / tab | Auth | Deep link | Back behaviour |
|-------------|---------|-----------|-------------|------|-----------|----------------|
| Home (홈) | ios, android | Tab 1 (root) | `home` | signed-in | `moa://home` | System back on the root tab: Android leaves the app (predictive back shows home); iOS has no back on a tab root |
| Goals (목표) | ios, android | Tab 2 | `goals` → stack | signed-in | `moa://goals`, `https://moa.example/goals/{goalId}` | Pops the Goals stack; re-tapping the tab pops to its root |
| History (내역) | ios, android | Tab 3 | `history` → stack | signed-in | `moa://history/transactions/{transactionId}` | Opened from a push: back goes to the History list, then Home — never straight out of the app |
| My (내 정보) | ios, android | Tab 4 | `my` → stack (settings, subscription, security) | signed-in | `moa://my/subscription` | Pops the stack |
| Create goal | ios, android | Full-screen modal over tabs | — | signed-in | none (not linkable mid-flow) | Close button + swipe-down (iOS) / back (Android) with a discard confirmation when fields are filled |
| Sign-in / sign-up | all | Outside the shell | `/login` | public | `https://moa.example/login?next=…` | Returns to `next` after success |

**Mobile rules to state explicitly**:
- 3–5 tabs (both the iOS tab bar and the Material navigation bar are designed for
  that range); labels always visible, not icon-only.
- One navigation stack per tab; switching tabs preserves each tab's stack and
  scroll position.
- Flows that must be completed or abandoned (create goal, checkout, 본인인증) are
  modals outside the tab structure, not pushes inside a tab.
- A deep link builds a synthetic back stack (list, then detail) so back never
  exits the app from a detail screen the user did not navigate to.

**Worked example — SaaS web shell (Moa admin console)**:

| Destination | Placement | Route | Auth | Notes |
|-------------|-----------|-------|------|-------|
| Dashboard | Sidebar, first item | `/` | `admin`, `support` | Default landing |
| Users | Sidebar | `/users`, `/users/:userId` | `admin`, `support` | Detail opens in the content area; list filters live in the URL |
| Payments | Sidebar | `/payments` | `admin` | Hidden for `support` (not disabled) |
| Notifications (templates, 알림톡 approval status) | Sidebar | `/notifications/templates` | `admin` | |
| Settings | Sidebar footer | `/settings` | `admin` | |
| Command palette | Global (`⌘K` / `Ctrl+K`) | overlay | all roles | Jumps to any destination or record by ID |

**Web rules to state explicitly**: every destination and every filtered view has
a URL (shareable, bookmarkable, restorable after refresh); the browser back button
follows the user's navigation (filters replace history entries, page-to-page
navigation pushes them); sidebar nesting stops at two levels.

---

## Global Regions per Breakpoint

> **Why this section exists**: Screens are designed inside the regions the shell
> leaves them. Defining the regions per breakpoint — and which ones collapse, move
> or disappear — lets every UX spec lay out only its content area, and prevents
> the classic failure where the desktop layout is squeezed onto a phone. Use the
> breakpoints of the design language (`## 4. Layout, Spacing & Grid`): `sm`, `md`,
> `lg` on the web; compact and regular size classes on mobile.

**Worked example — consumer app**:

| Region | web `sm` | web `md` | web `lg` | mobile compact | mobile regular (tablet) |
|--------|----------|----------|----------|----------------|-------------------------|
| Top bar | 56 px: title + back or logo | 64 px: logo + primary nav | 64 px: logo + primary nav + account | Navigation bar (per screen) | Navigation bar |
| Primary navigation | Bottom tab bar | Top nav | Top nav | Bottom tab bar | Sidebar (iPad) / navigation rail (Android) |
| Content | Full width, 16 px margins | Centered, max 720 px | Centered, max 1080 px | Full width | Split view where a list/detail pair exists |
| Secondary panel | — | — | Right rail (goal summary) | — | Detail pane |
| Global banner slot | Below top bar | Below top bar | Below top bar | Below navigation bar | Below navigation bar |

**Worked example — admin console at `lg` and `sm`**:

```
lg (≥ 1024 px)
┌──────────────┬───────────────────────────────────────────────────┐
│ MOA ADMIN    │ [⌘K Search…]            [Staging]  [🔔 3]  [Kim ▾] │ ← TOP BAR
│              ├───────────────────────────────────────────────────┤
│ ▸ Dashboard  │ [Global banner slot — one banner at a time]        │
│ ▸ Users      ├───────────────────────────────────────────────────┤
│ ▸ Payments   │ Users › 김민지                                      │ ← BREADCRUMB
│ ▸ Notific.   │                                                   │
│              │                 CONTENT AREA                      │
│ ─────────    │          (tables, detail panels, forms)           │
│ ⚙ Settings   │                                                   │
│ « Collapse   │                                                   │
└──────────────┴───────────────────────────────────────────────────┘
  SIDEBAR 240 px (64 px collapsed; state persisted per user)

sm (< 640 px) — operators occasionally check on a phone
┌───────────────────────────────┐
│ [☰]  Users           [🔔] [K] │ ← sidebar becomes a drawer
├───────────────────────────────┤
│ [Global banner slot]          │
├───────────────────────────────┤
│ CONTENT (tables become lists) │
└───────────────────────────────┘
```

**Worked example — regions from an external Design Source** (consumer app). The
header's `> **Design Source**:` line reads
`` figma — https://www.figma.com/design/<fileKey>/Moa?node-id=3-120 · record `design/handoff/app-shell/HANDOFF.md` ``
(for a screen spec the same form names its own record, e.g.
`` figma — https://www.figma.com/design/<fileKey>/Moa?node-id=12-345 · record `design/handoff/goal-detail/HANDOFF.md` ``;
with no external tool it reads `none — markdown spec only`). Cite the retained
screen per breakpoint instead of drawing it, and keep the region table above as the
text description:

```
external: see Design Source — screens listed from the handoff record
- mobile compact: design/handoff/app-shell/screens/shell-compact.png
- web lg:         design/handoff/app-shell/screens/shell-lg.png
- web sm, web md, mobile regular: no frame — open questions for the designer (check 8)
```

The Figma file's 1440 px desktop frame maps to `lg`; it does not add a breakpoint the
design language lacks. The record is reference, not source — the design language
wins on visuals, this document on behaviour.

**Safe areas** — state them per surface: iOS status bar, Dynamic Island and home
indicator; Android edge-to-edge drawing behind system bars with insets applied to
the navigation bar and content; on the mobile web
`viewport-fit=cover` with `env(safe-area-inset-*)` padding on fixed bars.

---

## Persistent Elements

> **Why this section exists**: Each persistent element is on screen for every
> second of every session. This section is the budget: what persists, in which
> region, when it is visible and where its data comes from. An element not listed
> here does not persist — it belongs to a screen.

**Worked example table**:

| Element | Region | Visible when | Data source | Update | Priority | Accessibility |
|---------|--------|--------------|-------------|--------|----------|---------------|
| Tab bar (consumer) | Bottom (compact) | Signed-in, not inside a modal flow | — | — | 1 | Labels visible; selected tab exposed as selected, not by color alone |
| Notification bell + badge | Top bar | Signed-in | `GET /v1/notifications/unread-count` | On focus/resume + push receipt | 3 | Name includes the count ("알림 3개") |
| Account menu | Top bar (`lg`), My tab (mobile) | Signed-in | `GET /v1/me` | On sign-in, profile change | 4 | Menu button pattern; Esc closes |
| Command palette trigger (admin) | Top bar | Always | — | — | 2 | Shortcut announced in the button's name |
| Environment badge | Top bar | Non-production environments only | build config | Build time | 1 in staging | Text "Staging", never color only |
| Help / chat entry | Floating bottom-right (web `lg`), My tab (mobile) | Signed-in, not on payment steps | — | — | 5 | Must not cover content or the focused field; hidden during checkout |

**Visual budget** — write it as hard limits, e.g. "At `sm` the shell may use at
most one top bar and one bottom bar; nothing else floats over content." Every
proposal to add a persistent element states which limit it touches and which
element it displaces or makes contextual.

---

## Global States

> **Why this section exists**: Some states belong to the whole product, not to a
> screen: the user's session expired, the device is offline, the service is in
> maintenance, the app version is no longer supported. If each screen handles them
> on its own, users see five different offline messages and a checkout that fails
> silently. Define each global state once — its trigger, what the shell does, what
> stays usable and how the user leaves it — and every UX spec refers here.

**Worked example table**:

| State | Trigger (source) | Shell behaviour | What stays usable | Exit |
|-------|------------------|-----------------|-------------------|------|
| Signed out / session expired | 401 from the API after refresh-token failure | Mobile: sign-in sheet over the current screen; web: redirect to `/login?next=<current URL>` | Nothing that needs the account; the user's unsaved input is kept locally | Sign in → return to the same screen with input restored |
| Offline | OS connectivity signal + failed request | Global banner "오프라인 상태예요 — 연결되면 자동으로 다시 시도해요" (you're offline — we'll retry when connected) | Cached goals and history read-only; money-moving actions disabled with the reason shown | Connectivity back → banner clears, queued reads refresh |
| Maintenance (scheduled) | Remote config `maintenance.window` | Before: global banner with the window in KST; during: full-screen maintenance state; web served as a static page from the CDN | Help center link | Window ends → app re-checks config on resume |
| Force update | App config endpoint returns `min_supported_version` above the installed version | Blocking screen with a store button; no dismiss | Nothing | Update installed |
| Soft update | `recommended_version` above installed | Dismissible banner once per version | Everything | Dismiss or update |
| Degraded (partial outage) | Status from the API or a feature flag | Banner naming the affected capability ("자동이체 조회가 지연되고 있어요" — auto-debit status is delayed) | Everything else | Flag cleared |
| Account restricted | `GET /v1/me` returns a restriction (verification pending, suspended) | Banner with the one action that resolves it | Read-only access as the policy allows | Restriction lifted |
| Plan-gated | Entitlement check (`subscription` Free vs Plus) | Locked destinations show the upgrade path, not an error | Free features | Upgrade |

**Rules to state**: global states are mutually prioritized (force update >
signed out > maintenance > offline > degraded > restricted); only the highest
applies at once; each state's copy comes from `design/content/` (via
`/team-content`), not from individual screens.

---

## Notifications & Banners

> **Why this section exists**: Every feature wants to tell the user something, and
> without shell-level rules the result is overlapping toasts, three banners
> stacked on one screen, and a payment failure hidden behind a promotion. This
> section is the contract every feature follows: which channel carries which kind
> of message, the priority order and the queue rules. Push and 알림톡 reach the
> user outside the app; they are listed here so in-app and out-of-app messages
> agree.

**Worked example table**:

| Type | Channel | Region | Duration | Max at once | Priority | Dismissible | Also in inbox |
|------|---------|--------|----------|-------------|----------|-------------|---------------|
| Action confirmation ("저장했어요") | Toast / snackbar | Bottom, above the tab bar | 4 s (snackbar with Undo: 6 s) | 1 | Low | Swipe / auto | No |
| Recoverable error ("다시 시도해 주세요") | Snackbar with Retry | Bottom | Until action or 10 s | 1 | Medium | Yes | No |
| Payment failed (auto-debit) | Global banner + push + 알림톡 | Banner slot | Until resolved | 1 banner | Critical — never queued | No — resolves when the payment method is fixed | Yes |
| Verify your email | Global banner | Banner slot | Until done | 1 banner | Medium | Once per session | No |
| Scheduled maintenance | Global banner | Banner slot | From 24 h before | 1 banner | High | Yes (returns next session) | Yes |
| Goal reached | In-app celebration + push | Modal sheet (once) | Until dismissed | 1 | Medium | Yes | Yes |
| New feature announcement | Inbox item only | Inbox | — | — | Low | — | Yes |

**Queue rules — worked example**:
1. One global banner at a time: the highest priority shows; the others wait.
   Critical banners (payment failed, security) are never queued behind anything.
2. Toasts never carry information the user must act on — anything actionable also
   exists on a screen or in the inbox.
3. Identical confirmations within one second merge ("3개 항목을 저장했어요" —
   saved 3 items) instead of stacking.
4. No promotional message uses the global banner slot or interrupts a flow; promotions
   live in the inbox or on the home screen.
5. Push permission is requested after the user has seen value (after creating the
   first goal, with a pre-permission explanation screen), never on first launch.
6. Advertising messages outside the app (push, 알림톡 and 친구톡, email, SMS) follow the
   consent rules of the configured regions — for Korea,
   `.claude/docs/compliance/kr.md` § Marketing Messages & Consent (separate
   advertising consent, night-time sending, unsubscribe path). 알림톡 carries
   informational messages only.

---

## Accessibility

> **Why this section exists**: Shell accessibility failures repeat on every screen.
> A missing skip link, an icon-only tab bar or a banner that covers the focused
> field fails every screen at once. This section holds the shell-level
> requirements; the project-wide commitments live in
> `design/accessibility-requirements.md` (its `> **Target**:` line is the bar).

**Worked example — shell requirements**:

| Requirement | Rule | WCAG 2.2 |
|-------------|------|----------|
| Skip link | First focusable element on the web: "본문 바로가기" (skip to main content) | 2.4.1 |
| Landmarks | `header`, `nav` (labelled "주 메뉴" / "Main"), `main`, `footer`; one `main` per page | 1.3.1 |
| Route change | Focus moves to the new page's `h1`; the page title updates and is announced | 2.4.2, 2.4.3 |
| Tab bar / sidebar | Visible text labels; current item exposed as current/selected, not by color alone | 1.4.1, 4.1.2 |
| Badges | Count included in the accessible name ("알림, 읽지 않음 3개") | 1.1 guideline, 4.1.2 |
| Global banners | Informational banners use a polite live region; blocking states move focus to their heading | 4.1.3 |
| Focus not obscured | Sticky top bar, bottom bar and floating help button never cover the focused element (scroll padding) | 2.4.11 |
| Orientation | No orientation lock unless essential | 1.3.4 |

**Worked example — text scaling matrix** (fill for the shell's own text):

| Element | 100% | 150% | 200% / largest accessibility size | Overflow behaviour |
|---------|------|------|-----------------------------------|--------------------|
| Tab labels | Pass | Pass | [TBD] | Labels wrap to two lines; icons stay; never truncate to icon-only |
| Top bar title | Pass | [TBD] | [TBD] | Truncate with the full title exposed to assistive tech |
| Global banner | Pass | [TBD] | [TBD] | Banner grows; content scrolls beneath it |

**Worked example — motion table**:

| Shell motion | Reduced-motion behaviour |
|--------------|--------------------------|
| Tab switch cross-fade | Instant switch |
| Sidebar collapse animation | Instant |
| Banner slide-in | Appears in place |
| Goal-reached celebration | Static card, no confetti |

---

## Open Questions

The app-shell template has no open-questions table. Write each unresolved shell
decision as an "Open:" line, with an owner and a date, in the section it belongs
to, and keep the count in the header's `> **Open Questions**:` line. An Approved
shell has none. **Worked example lines**:

- In `## Navigation Model`: "Open: four tabs or five — does 'Benefits' (혜택) earn a
  tab or live on Home? — product-manager + product-designer, before the Validation
  gate (usability test on the prototype)."
- In `## Global Regions per Breakpoint`: "Open: iPad — sidebar or tab bar at
  regular width? — product-designer, before the iOS shell story."
- In `## Global Regions per Breakpoint`: "Open: does the web consumer app need the
  bottom tab bar at `sm`, or a top menu? — product-designer, Sprint 2 (analytics
  show most web traffic is mobile)."

Header for this example: `> **Open Questions**: 3`.
