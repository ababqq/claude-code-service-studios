> Section-authoring guidance, loaded by `/ux-design` for the ACTIVE MODE ONLY.
> Never load the other two — one mode applies per invocation.

# Section Guidance — App Shell Mode

The app shell (`design/ux/app-shell.md`, from `.claude/docs/templates/app-shell.md`)
is the global UI every screen sits inside. Shell design follows a different order
from screen specs: begin with the navigation model and the information inventory,
and do not touch regions or layout until both are approved.

Use the surfaces and breakpoints resolved in Phase 2h. Examples use Moa, a
subscription savings app (web + iOS + Android); replace them with the product's own.

---

#### Section A: Navigation Model

**Step 1 — Navigation principle.** Ask the user to describe, in 1–2 sentences, how
people should move through the product. Offer framing examples:
- "Few destinations, deep items — a tab bar of 3–5 destinations on mobile and a top
  navigation on web; everything else is a drill-down that Back undoes." (consumer
  apps such as a savings app or a bank)
- "Workspace-first — a persistent side navigation listing projects or objects, with
  a global search and a command palette." (B2B SaaS, admin consoles)
- "Single task — minimal chrome; the flow is the product, and navigation appears
  only after completion." (checkout, booking, form-heavy services)
- "Content feed — one primary feed with secondary destinations behind a profile or
  menu." (community and content products)

This principle is the constraint for every later shell decision. If a proposed
element conflicts with it, surface the conflict.

**Step 2 — Information inventory** (complete this before any layout; do not skip it):
Pull every global element from the PRDs' `## UI Requirements` sections gathered in
Phase 2c — badges, banners, account entry points, search, help — and from
`design/inventory/screen-inventory.md` for the destinations. Present the full list:
"These are all the things your features say must be visible beyond a single screen."

Then categorize each item with the user:

| Category | Description |
|----------|-------------|
| **Always Visible** | In the shell on every screen that shows it — the user needs it for navigation or trust |
| **Contextual** | Appears in the shell only when relevant (payment failed, maintenance scheduled, unread count > 0) |
| **On Demand** | Reached through a menu or a destination (settings, help center, legal) |
| **Not in the Shell** | Belongs to one screen — move it to that screen's spec |

Use `AskUserQuestion` to step through items in groups of 3–4, not all at once. This
is the most consequential shell decision — do not rush it.

**Conflict check**: if the principle says "minimal chrome" but the Always Visible
list keeps growing, surface it:
> "The Always Visible list has [N] items. That conflicts with the minimal-chrome
> principle. Options: move items to On Demand, revise the principle, or show the
> full shell only after the first task is complete."

**Step 3 — Top-level destinations and Back.** Agree the destinations (mobile tab
bars hold at most five), the default landing destination for signed-in and
signed-out users, and Back behaviour per surface: browser history on web, edge
swipe-back on iOS, system and predictive back on Android. Then the deep-link →
back-stack mapping: every notification, email and 알림톡 link lands on the specific
item with a stack that makes Back feel natural.

---

#### Section B: Global Regions per Breakpoint

Only after the navigation model is approved, design the regions.

Base the regions on:
- Which items are Always Visible (they drive the permanent regions)
- Where attention goes on each breakpoint — content first; on compact mobile the
  thumb zone at the bottom of the screen
- The breakpoints and size classes in the design language (web `sm` / `md` / `lg`;
  mobile compact / regular). If the design language has not defined widths, record
  `[TBD — design language]` and an open question; never invent them.

Offer 2–3 region arrangements for the smallest and the widest breakpoint, with
rationale based on the navigation principle and the categorization from Section A.
Then record, per region: surface, breakpoint, position, contents, stickiness and
when it hides (keyboard open, full-screen flows such as checkout).

Always cover: safe areas (notch, Dynamic Island, home indicator, Android navigation
bar), the on-screen keyboard, foldables and split screen when Android is a surface,
and reflow at 320 CSS px and 200 % text on web.

---

#### Section C: Persistent Elements

For each element that appears on more than one screen, specify:
- Element name and the region it lives in
- When it is visible (signed in / out, plan, breakpoint)
- Its data source — the operation that feeds it (the shell never owns data) — and
  what triggers an update
- Its states (none, count, 99+, error) and its accessible name including state
  ("Notifications, 3 unread")

Work element by element. Reference the pattern library if the element reuses a
pattern (badge, menu, banner). Help and chat launchers must sit in the same relative
place on every screen that offers them (WCAG 3.2.6 Consistent Help). Cookie consent
on web, where a region in `compliance.regions` requires it, is a persistent element
too — it must never cover the focused element.

---

#### Section D: Global States

Product-wide states that wrap or replace every screen. Walk each with the user; for
each record the trigger, what the shell shows, what still works, the exit and who
owns the switch.

Minimum set:
- **Auth** — signed out (public shell, where sign-in returns the user), session
  expired (re-authentication without losing input), step-up authentication before
  sensitive actions (payment method change, account deletion)
- **Offline** — the indicator, which screens read from cache, which writes queue,
  how conflicts surface on reconnect
- **Maintenance** — triggered by a flag or a marked 503 from the API; shows the
  expected end and a status page link; retries on an interval, never in a tight loop
- **Force-update** — triggered when the app version is below the minimum supported
  version in remote config; blocking, with a store link; plus the dismissible
  soft-update variant

Ask for any product-specific states (account suspended, region unavailable, plan
expired). Every state must be triggerable on staging — by flag, remote config or a
test account — so QA can verify it; note how.

---

#### Section E: Notifications & Banners

Inventory every channel the product uses to tell the user something — toasts and
snackbars, inline and global banners, the in-app inbox, push, email, SMS, 알림톡 —
with trigger, position, duration, priority, how many can show at once and queue
behaviour.

**Questions to ask**:
- "Which messages can interrupt, and which must wait?"
- "What happens when two banners want the same slot?"
- "Where does each push, email and 알림톡 link land?" (the specific item, never Home)
- "When do we ask for push permission?" (after the first moment of value, with a
  pre-permission explanation — never at first launch)

Write the queue rules (priority, merge, timing). Nothing actionable auto-dismisses in
under 5 seconds; toasts never cover the primary action. Channel and consent rules
for marketing messages come from `.claude/docs/compliance/<region>.md` for each
region in `compliance.regions` — for `kr`, 알림톡 carries informational messages
only, and advertising messages need prior opt-in; record the rule, do not
interpret the law. Message copy is drafted and marked for the ux-writer.

---

#### Section F: Accessibility

Cross-reference `design/accessibility-requirements.md` (target and requirement
matrix), then walk this checklist for the shell:
- Web: a skip link as the first focusable element; header, navigation, main and
  footer landmarks; one `h1` per route
- Route changes: document title updated, focus moved to a predictable place,
  the change announced
- Mobile: tab items expose name, selected state and position; screen titles are
  announced on push
- No sticky header, tab bar, banner, toast or cookie notice obscures the focused
  element (WCAG 2.4.11)
- Badges and unread states are not color-only; contrast holds in light and dark
  themes
- Reduced-motion replacements for every shell animation (tab switch, banner entry,
  sheet presentation)
- 200 % text: the tab bar keeps its labels (or accessible names), the header
  collapses into a menu, nothing essential truncates
- Keyboard / pointer / touch / screen-reader behaviour for each shell element (the
  template's table)

If no accessibility target has been committed, note the gap as an "Open:" line in
this section and in the header's Open Questions count ("Accessibility target not yet
committed — run `/ux-design accessibility`"), then continue without stopping. Never
assume a level.

---

#### Acceptance criteria in every section

The shell template has no separate acceptance section: each of the six sections
ends with its own **Acceptance criteria** checklist. Before approving a section,
confirm each criterion is binary and verifiable by a QA engineer on staging, and
add any the section's decisions created (a new global state needs a criterion that
triggers it).
