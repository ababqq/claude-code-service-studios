> Authoring guidance for accessibility-requirements.md. Load only the part covering the section currently being authored — not the whole file at once.

# Accessibility Requirements Template — Authoring Guidance

Guidance is organized by the template's sections: each `##` heading below has the
same name as the `design/accessibility-requirements.md` section it serves
(`## Target & Scope` also covers the `> **Target**:` line of the header block, and
`## Requirement Matrix` has one `###` per WCAG principle, as in the template).
When authoring a section, read only that heading's guidance. The requirement
matrix rows, the platform API table, the test plan and the external resources
live in the template — they are the requirement catalog, not guidance.

The examples use **Moa**, a subscription savings app for the Korean market (web,
iOS, Android, API) with sign-up via email or Kakao/Naver/Apple, savings goals,
Toss Payments auto-debit and push + 알림톡 notifications.

---

## Target & Scope

> **Why the target comes first**: Accessibility is not a feature list you add
> later — it is a conformance level every screen is designed to. Stating the level
> up front gives design, engineering and QA one bar to build and test against, and
> it prevents scope drift in both directions ("we'll fix it after launch" and "we
> must support everything everywhere"). The first line of the header block is
> `> **Target**: <accessibility.target value>`; `/ux-design accessibility` writes
> the same value to `accessibility.target` in `project.yaml`, which
> `/design-language`, `/ux-review`, `/team-ui`, `/team-hardening`,
> `/launch-checklist` and `/gate-check` read.

**Choosing the value** (WCAG 2.2 levels):

| Value | When it is the right commitment |
|-------|---------------------------------|
| `wcag-aa` | The default for consumer and B2B products. It is the level most accessibility laws, public procurement rules and enterprise buyers reference, and the level the Korean, EU and US standards in `compliance.regions` map to. |
| `wcag-a` | Only as a stated interim step with a date for AA — Level A alone leaves out contrast, focus visibility and target size, the barriers users hit most. |
| `wcag-aaa` | For specific flows, not whole products: W3C does not recommend requiring AAA product-wide because some content cannot meet it. Name the flows. |
| `none` | A recorded decision, e.g. an internal prototype that will never reach users. Say why and when it will be revisited. |

`accessibility.target` unset is **not** `none` — it is an unanswered question.
Skills that read it report `NOT ASSESSED` until it is answered.

**Authoring the commitment rationale** (3–5 sentences — explain, do not just name
the level):

[Consider who the users are and which barriers the product creates, which regions
the product ships in and what their standards require, which surfaces ship, what
the team can build and test, and what a lower level would cost real users.

Example (Moa): "Moa moves users' money every month, so every user must be able to
set up, check and stop an auto-debit without help. We commit to `wcag-aa` on web,
iOS and Android. We ship in Korea (`compliance.regions: [kr]`), where KWCAG 2.2
and the mobile app accessibility guideline apply and where the 장애인차별금지법
covers digital services; KWCAG maps to the WCAG AA criteria we already target.
The riskiest flows are sign-up with 본인인증, the Toss Payments auto-debit
agreement and cancelling a subscription — those three get manual screen-reader
passes on every release, not only automated checks."]

**In scope beyond the level / explicitly out of scope** — examples:

- In scope: "Enhanced contrast (7:1) for amounts and dates on the transfer
  confirmation screen — users misreading an amount is the costliest failure we have."
- Out of scope: "Sign-language video for onboarding — not planned for v1; tracked
  in Known Intentional Limitations with its mitigation."

---

## Regional Standards

> **Why regions are listed separately**: WCAG is the technical baseline; laws and
> national standards decide who is obliged, how conformance is shown and what
> happens when it is missing. Load only the regions in `compliance.regions` —
> their topic checklists are in the `## Accessibility` section of
> `.claude/docs/compliance/<region>.md`. Those files are checklists of what to
> verify, not legal advice: never write a deadline, penalty or threshold here
> without a cited source (`Source: <url>, retrieved YYYY-MM-DD`).

| Region | What to record | Where to verify |
|--------|----------------|-----------------|
| `kr` | KWCAG 2.2 (한국형 웹 콘텐츠 접근성 지침 2.2) for the web, the mobile app accessibility guideline (모바일 애플리케이션 콘텐츠 접근성 지침) for iOS and Android, whether the 장애인차별금지법 obligation applies to this service, and whether the team will seek the web accessibility quality certification mark (웹 접근성 품질인증) | the standards body and certification bodies named in `.claude/docs/compliance/kr.md` |
| `eu` | The European Accessibility Act and its harmonised standard (EN 301 549) for the services in scope — e-commerce and consumer banking services are named categories | `.claude/docs/compliance/eu.md` |
| `us` | ADA exposure for public-facing services, Section 508 when selling to US federal agencies (a VPAT / Accessibility Conformance Report is usually requested by buyers) | `.claude/docs/compliance/us.md` |

**Korea-specific notes worth writing down** (they change design and test plans):
- Screen-reader coverage in Korea includes 센스리더 (Sense Reader) on Windows
  alongside NVDA and JAWS, and VoiceOver and TalkBack on phones. Test with the ones
  the users actually use.
- Identity verification (본인인증) and payment agreements often run in a third-party
  web view (a PASS app hand-off, a PG's agreement page). Its accessibility is part
  of the user's flow even though the team does not own it — record the provider,
  test it, and record the gap as a Known Intentional Limitation when it fails.
- `compliance.regions` unset ⇒ ask; do not assume Korea because the team is Korean.

---

## Requirement Matrix

The template's matrix already lists the WCAG 2.2 A and AA rows with one column
per surface; the guidance below explains why each principle matters and shows
Moa rows written as concrete design and implementation rules. Add a row for every
commitment above the target that `## Target & Scope` lists.

### Perceivable

> **Why this principle is first**: Most barriers users report are perceivable:
> text they cannot read against its background, meaning carried only by color,
> content that breaks when enlarged. They are also the cheapest to prevent — they
> are decided in the design language's color and type sections before any screen
> exists. Retrofitting contrast after a component library ships means changing
> every screen.

**Worked example rows** (Moa, `wcag-aa`, all surfaces):

| Requirement | WCAG 2.2 SC | Surface | Design / implementation rule | Verified by |
|-------------|-------------|---------|------------------------------|-------------|
| Body text contrast 4.5:1, large text 3:1 | 1.4.3 | all | Every semantic text/background pair in `design/brand/design-language.md` §2 meets the ratio in light and dark themes | token contrast check in CI + manual spot check |
| UI components and focus indicators 3:1 | 1.4.11 | all | Input borders, toggle tracks, the progress ring and `color.border.focus` meet 3:1 against adjacent colors | token check + axe |
| Never color alone | 1.4.1 | all | A failed auto-debit shows an error icon and the word "실패" (Failed), not only red text | UX review |
| Text resizes to 200% without loss | 1.4.4 | web | No fixed-height text containers; amounts wrap rather than clip | manual zoom pass |
| Reflow at 320 CSS px | 1.4.10 | web | Transaction table becomes a list below `sm`; no horizontal scroll except the chart | Playwright at 320 px |
| Dynamic Type / font scale | 1.4.4 (platform equivalent) | ios, android | Layouts tested at the largest accessibility text size; tab labels truncate, amounts never do | manual device pass |
| Images of text avoided | 1.4.5 | all | Plan names and prices are live text, not baked into promo images | UX review |
| Non-text content has alternatives | Guideline 1.1 | all | Goal illustrations are decorative (hidden from assistive tech); the bank logo in a payment method row has the bank name as its label | axe + screen-reader pass |

---

### Operable

> **Why this principle decides architecture**: Keyboard access, focus handling and
> touch targets are properties of the component library and the router, not of
> individual screens. A modal without a focus trap or a custom select without
> keyboard support is copied into every screen that uses it. Specify them once
> here and in the pattern library, and test them at the component level.

**Worked example rows**:

| Requirement | WCAG 2.2 SC | Surface | Rule | Verified by |
|-------------|-------------|---------|------|-------------|
| Everything works from a keyboard, no traps | 2.1.1, 2.1.2 | web | Goal creation, the auto-debit agreement and subscription cancellation complete with keyboard only | Playwright keyboard-only E2E |
| Focus visible | 2.4.7 | all | A 2 px focus ring in `color.border.focus` with a 2 px offset on every interactive element; never `outline: none` without a replacement | axe + manual pass |
| Focus not obscured | 2.4.11 | web, mobile web | The sticky bottom CTA bar and the cookie/consent banner never cover the focused field — scroll padding equals their height | manual pass at `sm` |
| Target size at least 24 × 24 CSS px | 2.5.8 | web | Icon buttons (copy account number, info "i") get a 24 × 24 px hit area even when the glyph is 16 px; inline links in body text are exempt | automated target-size check + review |
| Platform touch targets | platform guidelines | ios, android | 44 × 44 pt (iOS HIG) and 48 × 48 dp (Material) — stricter than 2.5.8, so the platform value applies on native | design review |
| Dragging has an alternative | 2.5.7 | all | Reordering goals by drag also has "Move up / Move down" actions | manual pass |
| Timing adjustable | 2.2.1 | all | The 본인인증 SMS code timer (typically a few minutes) can be extended or restarted without losing entered data; session expiry warns before signing out | manual pass |
| Focus order and route changes | 2.4.3 | web | After a client-side route change focus moves to the new page's main heading and the title is announced | Playwright + screen reader |

---

### Understandable

> **Why forms get the most rows**: In a service, the understandable principle is
> mostly about forms — sign-up, identity verification, payment details, settings.
> Form errors are where users abandon, and where a screen-reader user can end up
> not knowing that anything went wrong. For money-moving actions WCAG adds an
> explicit error-prevention requirement.

**Worked example — form errors** (Moa sign-up and payment method):

| Requirement | WCAG 2.2 SC | Rule |
|-------------|-------------|------|
| Error identified in text | 3.3.1 | "휴대폰 번호 11자리를 입력해 주세요" (enter all 11 digits of your phone number) next to the field, linked with `aria-describedby`; the field gets `aria-invalid="true"`. A red border alone is not an error message. |
| Labels, not placeholders | 3.3.2 | Every field has a visible label; the placeholder `010-1234-5678` is an example, not the label. |
| Suggestion | 3.3.3 | "이메일 주소에 @가 없어요" (the email address has no @), not "Invalid input". |
| Error prevention for financial commitments | 3.3.4 | The auto-debit agreement shows amount, date, account and cancellation terms on a review step before submission, and the user can go back and change them. |
| Error summary on submit | 3.3.1 (pattern) | On submit with errors: focus moves to an error summary listing each error as a link to its field; the count is announced. |
| Redundant entry | 3.3.7 | The billing name entered at sign-up is prefilled at checkout, not asked again. |
| Accessible authentication | 3.3.8 | Paste is allowed in password and one-time-code fields; one-time codes support platform autofill (`autocomplete="one-time-code"` on the web, the platform's SMS code autofill on iOS and Android); no puzzle CAPTCHA without an alternative. |
| Consistent help | 3.2.6 | The "도움말" (help) entry sits in the same place on every screen of the payment flow. |
| Input purpose | 1.3.5 | `autocomplete` values on name, email, phone and address fields so browsers and password managers can fill them. |

**Other understandable rows**: page language set (`lang="ko"` with `lang="en"` on
English passages), consistent navigation between screens of the shell, no change
of context on focus (selecting a bank does not submit the form).

---

### Robust

> **Why robust is about using the platform**: Assistive technology understands
> native controls. Every custom control — a styled select, a segmented control,
> a bottom sheet — has to rebuild name, role, value and state by hand, and every
> rebuild is a place to get it wrong. Prefer native elements and well-tested
> accessible component primitives; write a row here for each custom control.

**Worked example rows**:

| Requirement | WCAG 2.2 SC | Rule |
|-------------|-------------|------|
| Name, role, value | 4.1.2 | The custom auto-debit day picker exposes role, the selected day as its value and "1 of 28" position; toggles expose on/off state separately from their label ("Push notifications", state "on"). |
| Status messages announced | 4.1.3 | "저장했어요" (saved) toasts and "3건의 결과" (3 results) counts use a polite live region on the web and the platform announcement API on iOS and Android — without moving focus. |
| Native first | — | Use `<button>`, `<a href>`, `<input type="checkbox">`, `<dialog>` before ARIA; `UIButton`/SwiftUI `Button`; Compose `Button` with `Role`. Record every exception. |

---

## Platform Accessibility APIs

> **Why this section exists**: Each surface exposes accessibility through a
> different API, and each stack maps its components onto that API differently.
> Recording which API and which screen readers each surface is tested with turns
> "accessible" into something QA can reproduce.

**Worked example table**:

| Surface | API / technology | Screen readers and tools tested | Notes |
|---------|------------------|---------------------------------|-------|
| web | HTML semantics + WAI-ARIA (APG patterns for custom widgets) | NVDA + Chrome, 센스리더 + Chrome/Edge, VoiceOver + Safari; axe-core in Playwright | React components from an accessible primitive library; no `div` buttons |
| ios | UIAccessibility / SwiftUI accessibility modifiers; Dynamic Type | VoiceOver; Accessibility Inspector | `accessibilityLabel` on icon-only buttons; amounts read as currency, not digits |
| android | Android accessibility framework / Compose semantics; font scale | TalkBack; Accessibility Scanner | `contentDescription` and `Role` on custom controls; merge descendants on list rows |
| React Native (if used) | `accessibilityRole`, `accessibilityLabel`, `accessibilityState` | VoiceOver + TalkBack | Test both platforms — RN maps props differently on each |

Record the stack's own specifics from `docs/stack-reference/` rather than from
memory; where the stack reference has nothing, write `NOT SOURCEABLE` and check
the platform documentation.

---

## Per-Feature Accessibility Matrix

> **Why a per-feature view**: Accessibility is a property of every feature, not a
> settings page. This matrix shows which features carry which barriers and whether
> each is addressed. When a feature is added to `design/product/feature-map.md`, a
> row is added here; a feature with an unaddressed barrier should not be marked
> Approved in the feature map.

**Worked example rows**:

| Feature | Perceivable | Operable | Understandable | Robust | Addressed | Notes |
|---------|-------------|----------|----------------|--------|-----------|-------|
| auth | Social-login buttons meet contrast in both themes | Kakao/Naver/Apple buttons reachable by keyboard; 본인인증 hand-off returns focus | Error messages per field; paste allowed in code fields | Social SDK buttons expose names | Partial | Third-party 본인인증 page not yet tested with 센스리더 |
| goals | Progress ring has a text value ("62% · 310,000원 of 500,000원") | Drag-to-reorder has button alternatives | Goal amount field formats as the user types without moving the cursor | Ring exposed as a progress indicator with value | Yes | |
| payments | Amounts in tabular numerals, 4.5:1 | Agreement flow keyboard-complete | Review step before commit (3.3.4) | PG web view announced as leaving the app | Partial | PG agreement page accessibility owned by the vendor |
| notifications | Badge counts not color-only | Inbox rows ≥ 48 dp | Plain-language titles | Announcements for new items off | Not Started | |

---

## Accessibility Test Plan

> **Why accessibility is tested separately**: Functional QA checks that a feature
> works; accessibility testing checks that it works for people using assistive
> technology. A form can pass QA and still announce nothing when it fails. Plan
> three layers: automated checks (fast, but they find only the machine-detectable
> part of the issues — a passing axe run is not conformance), manual expert passes
> (keyboard, screen reader, zoom, text size), and sessions with disabled
> participants on the riskiest flows.

**Worked example**:

| Layer | What | When | Owner |
|-------|------|------|-------|
| Automated | axe-core in component tests and Playwright E2E on every PR; token contrast check in the design-token build | CI, every PR | design-engineer, qa-engineer |
| Manual | Keyboard-only and screen-reader passes (VoiceOver, TalkBack, NVDA or 센스리더) on sign-up, goal creation, auto-debit agreement, cancellation | every release candidate | accessibility-specialist |
| Participants | Usability sessions with screen-reader and low-vision users on the payment flow (`/usability-report`) | before public beta | ux-researcher |
| Certification (kr, optional) | Web accessibility quality certification audit | before GA if pursued | accessibility-specialist |

---

## Known Intentional Limitations

> **Why document what is not included**: An undocumented omission surfaces as a
> complaint, a failed procurement review or a legal letter. A documented one shows
> it was a decision, names who is affected and states the mitigation. Every row is
> a risk — assess it honestly and give it a review date.

**Worked example rows**:

| Limitation | Criterion / standard | Why not included | Who is affected | Mitigation | Review by |
|------------|----------------------|------------------|-----------------|------------|-----------|
| The PG's card-registration page fails 2.4.7 (no visible focus) | WCAG 2.4.7 | Vendor-owned page; issue reported to the vendor | Keyboard and low-vision users on the web | Offer bank-account auto-debit (fully accessible) as the default method; support line in the help center | next vendor release |
| Charts on the insights screen have no sonification | beyond AA | Not required at AA; data table provided instead | Screen-reader users who prefer audio graphs | Every chart has an equivalent data table | Beta retro |

---

## Audit History

> **Why keep a history**: Conformance is not certified once. Platforms change,
> features add barriers, and standards evolve. A dated history shows due diligence
> and makes regressions visible between audits.

**Worked example rows**:

| Date | Auditor | Type | Scope | Findings summary | Status |
|------|---------|------|-------|------------------|--------|
| 2026-10-20 | accessibility-specialist | Internal manual audit | Sign-up, goals, payments on web and iOS against `wcag-aa` | 14 checks passed, 3 open: focus hidden behind sticky CTA at `sm`; code-field paste blocked on Android; toast not announced on iOS | In Progress |
| 2026-11-12 | External auditor | Certification pre-audit (kr) | Web, KWCAG 2.2 | 2 findings on table headers in transaction history | Findings addressed |

---

## Open Questions

**Worked example questions**:

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|------------|
| Does the 본인인증 provider's hand-off page support VoiceOver on iOS and 센스리더 on the web? | accessibility-specialist | Before the auth epic starts | Unresolved — test with the provider's sandbox |
| Will we pursue the web accessibility quality certification mark before GA? | product-director | Before the Hardening gate | Unresolved |
| Does our chart library expose data tables automatically, or do we build them? | frontend-engineer | During architecture | Unresolved — check `docs/stack-reference/` |
