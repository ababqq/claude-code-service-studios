# App Shell: [Product Name]

> Authoring guidance: `.claude/docs/templates/guidance/app-shell-guide.md` (load per-section as you author — do not read entirely).

> **Status**: Draft | In Review | Approved | Implemented
> **Author**: [Name or agent — e.g., product-designer]
> **Last Updated**: [YYYY-MM-DD]
> **Product**: [Product name — this is a single document per product, written to `design/ux/app-shell.md`]
> **Surfaces**: [Every surface in `platform.surfaces` with a UI — `web` | `ios` | `android`]
> **Related PRDs**: [Every PRD whose `## UI Requirements` names a global element — e.g., `design/prd/notifications.md`, `design/prd/subscription.md`, `design/prd/auth.md`]
> **Screen Inventory**: [`design/inventory/screen-inventory.md` — the destinations the navigation model must reach]
> **Accessibility Target**: [The committed `accessibility.target` from `design/accessibility-requirements.md`]
> **Design Language**: [`design/brand/design-language.md` — the components and tokens the shell is built from]
> **Design Source**: [none — markdown spec only | claude-design — <locator> · record `design/handoff/app-shell/HANDOFF.md` | figma — <node URL> · record `design/handoff/app-shell/HANDOFF.md` — the shell frames per breakpoint; the record is written by `/design-handoff`]
> **Open Questions**: [none — or the count; each is written as an "Open:" line in the section it belongs to, with an owner and a date]

> **Note — Scope boundary**: The app shell is the global UI that persists across
> screens — navigation, global regions, persistent elements, product-wide states and
> the notification system. A single page, dialog or settings panel belongs in
> `ux-spec.md`; a multi-screen task belongs in `user-flow.md`. The test: if it
> appears on more than one screen and behaves the same everywhere, it belongs here,
> and every screen spec references it instead of re-specifying it.

---

## Navigation Model

**Navigation principle** — [One paragraph: how users move through the product and why. e.g., "Three top-level destinations reachable in one tap from anywhere; everything else is a drill-down that Back undoes. The account area is a destination, not a menu."]

**Top-level destinations**:

| Destination | Purpose | Web Placement | Mobile Placement | Badge / Count | Default Landing? |
|-------------|---------|---------------|------------------|---------------|------------------|
| [Home] | [Today's savings status] | [Top navigation] | [Tab 1] | [—] | [Yes — signed in] |
| [Goals] | [All savings goals] | [Top navigation] | [Tab 2] | [—] | [—] |
| [Account] | [Profile, subscription, settings, help] | [Account menu] | [Tab 3] | [Dot when action is needed] | [—] |
| [Destination] | [Purpose] | [Placement] | [Placement] | [Badge] | [—] |

**Information inventory** — every global element the PRDs' `## UI Requirements` ask for, and where it lives:

| Element | Source PRD | Always Visible | Contextual (Shown When Relevant) | On Demand (Menu / Screen) | Not in the Shell (Screen-Level) | Reasoning |
|---------|------------|----------------|----------------------------------|---------------------------|---------------------------------|-----------|
| [Notification inbox] | [`design/prd/notifications.md`] | [ ] | [ ] | [ ] | [ ] | [Why this category] |

**Back behavior**:

| Surface | Back Input | Behavior | Exceptions |
|---------|-----------|----------|------------|
| web | [Browser Back / in-app back link] | [Browser history — every meaningful state has a URL] | [Unsaved-changes confirmation] |
| ios | [Edge swipe-back / navigation bar back button] | [Pops the stack of the current tab] | [Never blocked except on unsaved changes] |
| android | [System / predictive back] | [Pops the stack; at a tab root, returns to the default tab, then exits] | [Same] |

**Deep links → back stack**: [For each deep-link pattern, the stack the app synthesizes so Back feels natural — e.g., `moa://goals/{goalId}` → Goals tab → Goal list → Goal detail. Notification and email links land on the specific item, never on Home.]

**Acceptance criteria**:
- [ ] Every top-level destination is reachable in one action from every screen that shows the shell
- [ ] Back behaves as documented on every covered surface, including after deep-link entry
- [ ] Mobile tab bars have at most five destinations

---

## Global Regions per Breakpoint

> Breakpoint widths and size classes come from the design language; do not invent
> values here. Include only the surfaces this product ships.

```
[Draw the shell regions for each breakpoint. Customize to the product's layout.]

 web — lg                                      web — sm / mobile — compact
 ┌──────────────────────────────────────────┐  ┌──────────────────────┐
 │ [HEADER] logo · nav · search · bell · me │  │ [TOP BAR] title · ⋯  │
 ├──────────┬───────────────────────────────┤  ├──────────────────────┤
 │ [SIDE    │ [GLOBAL BANNER SLOT]          │  │ [GLOBAL BANNER SLOT] │
 │  NAV]    │                               │  │                      │
 │          │ [CONTENT]                     │  │ [CONTENT]            │
 │          │                               │  │                      │
 │          │                   [TOAST AREA]│  │ [TOAST AREA]         │
 └──────────┴───────────────────────────────┘  ├──────────────────────┤
                                               │ [TAB BAR] ⌂  ◎  ☺    │
                                               └──────────────────────┘
```

| Region | Surface | Breakpoint / Size Class | Position | Contents | Sticky? | Hidden When |
|--------|---------|------------------------|----------|----------|---------|-------------|
| [Header] | [web] | [`md`, `lg`] | [Top] | [Logo, top-level nav, search, notification bell, account menu] | [Yes] | [Full-screen flows such as checkout] |
| [Tab bar] | [ios, android, web `sm`] | [compact] | [Bottom, above the home indicator] | [Top-level destinations] | [Yes] | [Keyboard open; modal flows] |
| [Global banner slot] | [all] | [all] | [Below the header / top bar] | [One banner at a time — see `## Notifications & Banners`] | [No] | [—] |
| [Region] | [Surface] | [Breakpoint] | [Position] | [Contents] | [Yes/No] | [Condition] |

**Safe areas and system UI**: [Notch and Dynamic Island, home indicator, Android navigation bar and gesture area, on-screen keyboard, split-screen and foldable postures.]

**Content width**: [Maximum content width per web breakpoint and how it centers — from the design language.]

**Acceptance criteria**:
- [ ] No two global regions overlap at any breakpoint of any covered surface
- [ ] Sticky regions never cover the focused element or the primary action of a screen
- [ ] The shell reflows at 320 CSS px width and at 200 % text size without hiding navigation

---

## Persistent Elements

> One row per element that appears on more than one screen. Each element's content
> comes from an operation the owning service exposes — the shell never owns data.

| Element | Region | Visible When | Data Source (Operation) | Update Trigger | States | Accessibility Name |
|---------|--------|--------------|-------------------------|----------------|--------|--------------------|
| [Notification bell] | [Header / Account tab] | [Signed in] | [`GET /v1/notifications/unread-count`] | [On focus; after push receipt] | [None / count / 99+] | ["Notifications, 3 unread"] |
| [Account menu] | [Header] | [Signed in] | [`GET /v1/me`] | [On sign-in; after profile edit] | [Default / plan badge] | ["Account"] |
| [Help / chat launcher] | [Same place on every screen that offers help] | [Signed in and out] | [—] | [—] | [Available / offline hours] | ["Help"] |
| [Cookie consent (web, where required)] | [Bottom of the viewport] | [Until the user chooses] | [Consent store] | [—] | [Unset / chosen] | ["Cookie settings"] |
| [Element] | [Region] | [Condition] | [Operation] | [Trigger] | [States] | [Name] |

**Acceptance criteria**:
- [ ] Each persistent element renders its loading, empty and error states without shifting the layout
- [ ] Help appears in the same relative place on every screen that offers it
- [ ] Every persistent element has an accessible name that includes its current state (e.g., the unread count)

---

## Global States

> Product-wide states that override or wrap every screen. At minimum: auth (signed
> out, session expired, step-up), offline, maintenance and force-update.

| State | Trigger / Detection | What the Shell Shows | What Still Works | Exit / Recovery | Owner of the Switch |
|-------|---------------------|----------------------|------------------|-----------------|---------------------|
| Signed out | [No session] | [Public shell: sign-in and sign-up entry points] | [Public pages, help] | [Sign in → return to the requested route] | [Auth service] |
| Session expired | [Token refresh fails] | [Re-authentication sheet over the current screen] | [Reading what is on screen] | [Re-authenticate → resume with input preserved] | [Auth service] |
| Step-up authentication | [Sensitive action — payment method, withdrawal, account deletion] | [PIN / biometric / 본인인증 prompt] | [Everything else] | [Verified → the action continues; cancelled → nothing changed] | [Auth service] |
| Offline | [Connectivity lost] | [Offline indicator; cached screens marked as possibly stale] | [Cached reads; queued writes where the screen spec allows] | [Reconnect → sync, then surface conflicts] | [Client] |
| Maintenance | [Server maintenance flag or 503 with a maintenance marker] | [Maintenance screen with the expected end time and a status page link] | [Help, status page] | [Automatic retry on an interval; manual retry] | [Operations — feature flag / remote config] |
| Force-update | [App version below the minimum supported version from remote config] | [Blocking update screen with a store link] | [Nothing else] | [Update → relaunch] | [Release manager — remote config] |
| Soft update | [Newer version available, current still supported] | [Dismissible banner] | [Everything] | [Update later] | [Release manager — remote config] |
| [State] | [Trigger] | [What shows] | [What works] | [Recovery] | [Owner] |

**Acceptance criteria**:
- [ ] Every global state can be triggered on staging (flag, remote config or test account) so QA can verify it
- [ ] No global state loses the user's unsaved input
- [ ] Force-update never blocks a user whose version is still supported
- [ ] The maintenance screen never shows a raw error, and its retry does not hammer the API

---

## Notifications & Banners

> Every channel the product uses to tell the user something, with its priority and
> queue behavior. Copy comes from the ux-writer; consent and channel rules for
> marketing messages come from `.claude/docs/compliance/<region>.md` for the regions
> in `compliance.regions`.

| Type | Trigger | Surface & Position | Duration | Priority | Max Simultaneous | Queue Behavior | Dismissible? | Announced to Screen Readers? |
|------|---------|--------------------|----------|----------|------------------|----------------|--------------|------------------------------|
| [Toast / snackbar] | [Action result — "Goal saved"] | [Toast area] | [4–10 s; longer with an action] | [Low] | [1] | [Newest replaces; never stacks] | [Yes] | [Yes — polite] |
| [Global banner] | [Payment failed, account needs attention, maintenance scheduled] | [Global banner slot] | [Until resolved or dismissed] | [High] | [1] | [Highest priority shows; others wait] | [Only when not blocking] | [Yes] |
| [In-app inbox item] | [Server-side event] | [Notification inbox] | [Persistent] | [—] | [—] | [Newest first] | [Mark as read] | [Count announced on the bell] |
| [Push notification] | [Server-side event] | [OS] | [OS] | [—] | [—] | [Collapse key per topic] | [OS] | [OS] |
| [Email / SMS / 알림톡] | [Server-side event] | [Outside the app] | [—] | [—] | [—] | [—] | [—] | [—] |
| [Type] | [Trigger] | [Position] | [Duration] | [Priority] | [N] | [Rule] | [Yes/No] | [Yes/No] |

**Queue rules**:
1. [Priority rule — e.g., a blocking banner (payment failed) always preempts an informational one]
2. [Merge rule — e.g., identical toasts within 2 s merge into one]
3. [Timing rule — toasts that carry an action stay until dismissed; nothing actionable auto-dismisses in under 5 s]

**Where notifications land**: [Every push, email and 알림톡 link opens the specific item with a synthesized back stack — never Home.]

**Push permission**: [When the product asks for notification permission — after the first moment of value, with a pre-permission explanation, never at first launch — and what the denied state looks like.]

**Acceptance criteria**:
- [ ] At most one global banner and one toast are visible at a time
- [ ] Toasts never cover the primary action or the focused element
- [ ] Every notification type lands on its documented destination
- [ ] Marketing messages are sent only to users with a recorded advertising consent for that channel

---

## Accessibility

> Shell-level requirements only — the project standard is
> `design/accessibility-requirements.md`, and screen-level requirements live in each
> screen spec.

**Structure and navigation**:
- [Web: a "Skip to content" link as the first focusable element; landmarks for header, navigation, main and footer; one `h1` per route]
- [Route change: the document title updates, focus moves to the new page heading (or stays predictable), and the change is announced]
- [Mobile: tab bar items expose selected state and position ("Goals, tab, 2 of 3, selected"); screen titles are announced on push]

**Focus and obscuring**: [Sticky headers, tab bars, banners, toasts and cookie notices never cover the focused element; focus order goes header → banner → content → tab bar.]

**Motion**: [What the shell animates (tab switch, banner entry, sheet presentation) and what replaces it under reduced motion.]

**Text scaling**: [What happens at 200 % text: the tab bar keeps labels (larger tab bar or icon + accessible label), the header collapses into a menu, nothing essential is truncated.]

**Color and contrast**: [Badge, selected-tab and banner colors meet the target's contrast ratios in light and dark themes; unread and error states are not signalled by color alone.]

| Shell Element | Keyboard | Pointer | Touch | Screen Reader | Notes |
|---------------|----------|---------|-------|---------------|-------|
| [Tab bar / top navigation] | [Tab reaches every item; arrow keys within the list] | [Hover and pressed states] | [Targets ≥ 44 pt / 48 dp] | [Name, selected state, position] | [—] |
| [Element] | [Keyboard] | [Pointer] | [Touch] | [Screen reader] | [Notes] |

**Acceptance criteria**:
- [ ] The skip link and landmarks exist on every web route
- [ ] Every route change is announced and leaves focus in a predictable place
- [ ] No shell element obscures the focused element on any breakpoint
- [ ] An automated accessibility scan of the shell reports no violations at the target level
