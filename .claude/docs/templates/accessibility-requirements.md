# Accessibility Requirements: [Product Name]

> **Target**: [accessibility.target value — `none` | `wcag-a` | `wcag-aa` | `wcag-aaa`]
> **Standard**: [WCAG 2.2 Level A | AA | AAA — derived from the target; `none` = no conformance claim]
> **Regional Standards**: [From `compliance.regions` — KWCAG 2.2 and the mobile app accessibility guideline (`kr`), the European Accessibility Act (`eu`), ADA / Section 508 (`us`); `regions=none` ⇒ none]
> **Surfaces**: [From `platform.surfaces` — `web` | `ios` | `android`]
> **Status**: Draft | Committed | Audited
> **Author**: [product-designer + accessibility-specialist]
> **Last Updated**: [YYYY-MM-DD]
> **Accessibility Consultant**: [Name and organization, or "None engaged"]
> **Linked Documents**: `design/product/feature-map.md`, `design/brand/design-language.md`, `design/ux/app-shell.md`, `design/ux/interaction-patterns.md`

> Authoring guidance: `.claude/docs/templates/guidance/accessibility-requirements-guide.md` (load per-section as you author — do not read entirely).

> **Why this document exists**: Per-screen accessibility annotations belong in UX
> specs. This document records the project-wide commitment — the target level, the
> regional standards that apply, the requirement matrix per surface, the test plan
> and the audit history. It is written once in the Architecture phase by
> `/ux-design accessibility` (product-designer with the accessibility-specialist)
> and updated as features are added and audits complete. If a feature conflicts
> with a commitment made here, this document wins — change the feature, not the
> commitment, unless the product owner approves a recorded revision.
>
> **The `> **Target**:` line is a contract.** It is the first line of the header,
> it must equal `accessibility.target` in `project.yaml`, and the Architecture →
> Validation gate checks that the two match. `none` is a recorded decision;
> an unset target is an unanswered question, never `none`.
>
> **When to update**: after each `/gate-check`, after any accessibility audit, and
> whenever a feature is added to `design/product/feature-map.md`.

---

## Target & Scope

**Target**: [`wcag-aa` — WCAG 2.2 Level AA]

**Rationale**: [3–5 sentences: who the users are (including older users, low-vision and screen-reader users in the target segment), what the regions in `compliance.regions` expect, what the surfaces demand, what the team can sustain, and the cost of a lower target. See the guide for the reasoning checklist and a worked example.]

**What the target means for this product**:

| Target | Conformance Bar (WCAG 2.2) |
|--------|----------------------------|
| `none` | No conformance claim. Blockers found are still reported; a region with accessibility obligations makes this a recorded risk (see `## Known Intentional Limitations`) |
| `wcag-a` | Every Level A success criterion |
| `wcag-aa` | Every Level A and AA success criterion |
| `wcag-aaa` | Level A and AA, plus the AAA criteria listed in this document as in scope (W3C does not recommend requiring AAA for entire products) |

**In scope**: [Surfaces, flows and content covered by the claim — e.g., "All signed-in and public screens on web, iOS and Android; transactional emails."]

**Out of scope / third-party content**: [Embedded or redirected third-party UI the team does not control — payment widgets, social-login pages, identity-verification (본인인증) vendor flows, maps — with what the team does about each (vendor accessibility statement requested, accessible alternative path, recorded limitation).]

**Commitments beyond the target**: [Criteria adopted above the target level — e.g., "2.4.13 Focus Appearance (AAA) for the whole product", "3:1 contrast for all focus indicators".]

**Native apps**: WCAG 2.2 success criteria are applied to iOS and Android apps as described in W3C's WCAG2ICT guidance; platform conventions (Apple Human Interface Guidelines, Material Design) supplement them.

---

## Requirement Matrix

> Organized by the four WCAG principles — Perceivable, Operable, Understandable,
> Robust. One column per surface in `platform.surfaces`; delete the columns of
> surfaces the product does not ship. A row whose Level is above the target is
> required only when `## Target & Scope` lists it as a commitment. Status values:
> Not Started | In Progress | Met | Partially Met | Not Met | N/A.

### Perceivable

| Requirement | WCAG 2.2 | Level | Web | iOS | Android | How Verified | Status |
|-------------|----------|-------|-----|-----|---------|--------------|--------|
| Meaningful images and icons have text alternatives; decorative ones are hidden from assistive technology | 1.1 Non-text Content | A | `alt`; `aria-hidden` / empty `alt` for decorative | `accessibilityLabel`; not an accessibility element when decorative | `contentDescription`; not important for accessibility when decorative | Automated scan + screen-reader pass | Not Started |
| Prerecorded video (onboarding, help) has captions | 1.2.2 Captions (Prerecorded) | A | Caption track | Caption track | Caption track | Manual | N/A |
| Headings, lists, tables and form labels are programmatic | 1.3.1 Info and Relationships | A | Semantic HTML, `<label>`, `th` with scope | Header trait on section titles | Heading semantics | Automated + manual | Not Started |
| Reading order matches the visual order | 1.3.2 Meaningful Sequence | A | DOM order | Accessibility element order | Traversal order | Screen-reader pass | Not Started |
| Content works in portrait and landscape | 1.3.4 Orientation | AA | — | No orientation lock | No orientation lock | Manual | Not Started |
| Personal-data fields identify their purpose (name, email, tel, one-time code) | 1.3.5 Identify Input Purpose | AA | `autocomplete` | `textContentType` | Autofill hints | Code review | Not Started |
| Color is never the only way information is conveyed (status, errors, charts) | 1.4.1 Use of Color | A | Icon / text with color | Same | Same | Manual + grayscale check | Not Started |
| Text contrast ≥ 4.5:1 (3:1 for large text), in light and dark themes | 1.4.3 Contrast (Minimum) | AA | Token pairs | Token pairs | Token pairs | Automated contrast check on design tokens + screens | Not Started |
| Text resizes to 200 % without loss of content or function | 1.4.4 Resize Text | AA | Browser zoom | Dynamic Type (including accessibility sizes) | Font scale | Manual at max size | Not Started |
| Content reflows at 320 CSS px without two-dimensional scrolling (data tables excepted) | 1.4.10 Reflow | AA | Responsive layout | — | — | Manual | Not Started |
| UI components, focus indicators and meaningful graphics ≥ 3:1 against adjacent colors | 1.4.11 Non-text Contrast | AA | Tokens | Tokens | Tokens | Automated + manual | Not Started |
| Text spacing overrides do not break layout | 1.4.12 Text Spacing | AA | CSS override test | — | — | Manual | Not Started |
| Hover or focus content is dismissible, hoverable and persistent | 1.4.13 Content on Hover or Focus | AA | Tooltips, popovers | — | — | Manual | Not Started |
| [Add requirement] | [SC] | [Level] | [Web] | [iOS] | [Android] | [Method] | [Status] |

### Operable

| Requirement | WCAG 2.2 | Level | Web | iOS | Android | How Verified | Status |
|-------------|----------|-------|-----|-----|---------|--------------|--------|
| Every function works from a keyboard, with no keyboard trap | 2.1.1 Keyboard; 2.1.2 No Keyboard Trap | A | Tab / arrow keys | Hardware keyboard and Full Keyboard Access where supported | Hardware keyboard / D-pad navigation where supported | Keyboard-only pass | Not Started |
| Single-character shortcuts can be turned off or remapped | 2.1.4 Character Key Shortcuts | A | Shortcut settings | — | — | Code review | N/A |
| Time limits warn and can be extended (session timeout, one-time-code expiry with easy resend) | 2.2.1 Timing Adjustable | A | Session warning dialog | Same | Same | Manual | Not Started |
| Auto-advancing content (carousels, banners) can be paused | 2.2.2 Pause, Stop, Hide | A | Pause control | Same | Same | Manual | Not Started |
| Nothing flashes more than three times per second | 2.3.1 Three Flashes or Below Threshold | A | — | — | — | Manual | Not Started |
| A skip link bypasses repeated navigation | 2.4.1 Bypass Blocks | A | "Skip to content" | — | — | Keyboard pass | Not Started |
| Every route and screen has a descriptive title | 2.4.2 Page Titled | A | `<title>` per route | Navigation title | Screen title / pane title | Screen-reader pass | Not Started |
| Focus order preserves meaning | 2.4.3 Focus Order | A | Tab order | Focus order | Traversal order | Keyboard + screen-reader pass | Not Started |
| Link purpose is clear from the link text or its context | 2.4.4 Link Purpose (In Context) | A | Link text | Same | Same | Manual | Not Started |
| Headings and labels describe their topic or purpose | 2.4.6 Headings and Labels | AA | — | — | — | Manual | Not Started |
| Keyboard focus is visible | 2.4.7 Focus Visible | AA | Focus ring token | Focus effect | Focus indicator | Keyboard pass | Not Started |
| The focused element is never fully hidden by sticky headers, bottom bars, banners or sheets | 2.4.11 Focus Not Obscured (Minimum) | AA | Scroll padding | — | — | Keyboard pass | Not Started |
| Multipoint or path gestures have a single-pointer alternative | 2.5.1 Pointer Gestures | A | — | Buttons for swipe actions | Same | Manual | Not Started |
| Actions fire on release and can be cancelled by moving away | 2.5.2 Pointer Cancellation | A | Default controls | Same | Same | Manual | Not Started |
| The accessible name contains the visible label | 2.5.3 Label in Name | A | — | — | — | Voice control pass | Not Started |
| Motion-triggered actions (shake to undo) have a UI alternative and can be disabled | 2.5.4 Motion Actuation | A | — | Setting | Setting | Manual | N/A |
| Every drag has a single-pointer alternative (e.g., reordering goals) | 2.5.7 Dragging Movements | AA | Move controls | Same | Same | Manual | Not Started |
| Targets are at least 24×24 CSS px (platform guidance: 44×44 pt iOS, 48×48 dp Android) | 2.5.8 Target Size (Minimum) | AA | Component sizes | Component sizes | Component sizes | Automated + manual | Not Started |
| [Add requirement] | [SC] | [Level] | [Web] | [iOS] | [Android] | [Method] | [Status] |

### Understandable

| Requirement | WCAG 2.2 | Level | Web | iOS | Android | How Verified | Status |
|-------------|----------|-------|-----|-----|---------|--------------|--------|
| Page language is set (`lang="ko"` for Korean; screen-reader pronunciation depends on it) | 3.1.1 Language of Page | A | `lang` attribute | App localization | App locale | Automated | Not Started |
| Passages in another language are marked | 3.1.2 Language of Parts | AA | `lang` on the element | Attributed language | Locale span | Manual | Not Started |
| Focus or input never triggers an unexpected change of context | 3.2.1 On Focus; 3.2.2 On Input | A | — | — | — | Manual | Not Started |
| Navigation and repeated components are consistent across screens | 3.2.3 Consistent Navigation; 3.2.4 Consistent Identification | AA | App shell | App shell | App shell | Review against `design/ux/app-shell.md` | Not Started |
| Help (chat, FAQ link, contact) appears in the same relative place on every screen that offers it | 3.2.6 Consistent Help | A | App shell | App shell | App shell | Review | Not Started |
| Errors are identified in text, next to the cause, with a suggestion | 3.3.1 Error Identification; 3.3.3 Error Suggestion | A / AA | Inline error + summary | Same | Same | Manual | Not Started |
| Inputs have visible labels and instructions (placeholder is not a label) | 3.3.2 Labels or Instructions | A | — | — | — | Manual | Not Started |
| Financial and legal submissions (payments, auto-debit, account deletion) can be reviewed, confirmed or reversed | 3.3.4 Error Prevention (Legal, Financial, Data) | AA | Review step | Same | Same | Manual | Not Started |
| Information already entered in a flow is not asked for again | 3.3.7 Redundant Entry | A | Prefill | Same | Same | Manual | Not Started |
| Sign-in needs no cognitive test: paste allowed, password managers and passkeys supported, no puzzle without an alternative | 3.3.8 Accessible Authentication (Minimum) | AA | Auth screens | Same | Same | Manual | Not Started |
| [Add requirement] | [SC] | [Level] | [Web] | [iOS] | [Android] | [Method] | [Status] |

### Robust

| Requirement | WCAG 2.2 | Level | Web | iOS | Android | How Verified | Status |
|-------------|----------|-------|-----|-----|---------|--------------|--------|
| Every control exposes name, role, state and value; custom controls use platform semantics | 4.1.2 Name, Role, Value | A | Native elements or ARIA per the WAI-ARIA Authoring Practices | Accessibility traits / actions | Semantics / roles | Automated + screen-reader pass | Not Started |
| Status messages (saved, failed, results count, async confirmations) are announced without moving focus | 4.1.3 Status Messages | AA | Live regions | Accessibility announcements | Live regions / announcements | Screen-reader pass | Not Started |
| [Add requirement] | [SC] | [Level] | [Web] | [iOS] | [Android] | [Method] | [Status] |

### Beyond WCAG (platform expectations)

| Requirement | Web | iOS | Android | Status |
|-------------|-----|-----|---------|--------|
| Reduced motion honored | `prefers-reduced-motion` | Reduce Motion | Remove animations | Not Started |
| Dark mode meets the same contrast ratios as light mode | `prefers-color-scheme` | Dark appearance | Dark theme | Not Started |
| Haptics are never the only feedback | — | Haptics + visual | Haptics + visual | Not Started |
| [Add requirement] | [Web] | [iOS] | [Android] | [Status] |

---

## Regional Standards

> One row per region in `compliance.regions`. The items come from the
> `## Accessibility` section of `.claude/docs/compliance/<region>.md` — a checklist
> of what to verify, not legal advice. Never state a deadline, penalty or threshold
> here unless it is followed by `(Source: <url>, retrieved YYYY-MM-DD)`.
> `compliance.regions: []` ⇒ write "None — no regional standard applies
> (`regions=none`)". Unset ⇒ ask; do not leave the section empty.

| Region | Law / Standard | Applies To | Relationship to the Target | Verify At | Status |
|--------|----------------|------------|----------------------------|-----------|--------|
| `kr` | [장애인차별금지법; KWCAG 2.2 (한국형 웹 콘텐츠 접근성 지침); the mobile app accessibility guideline] | [Web and apps offered in Korea] | [Items to check beyond the WCAG target, from `compliance/kr.md`] | [The official body named in `compliance/kr.md`] | [Not Started] |
| `eu` | [European Accessibility Act and its harmonised standard] | [Consumer e-commerce and banking services in the EU, per `compliance/eu.md`] | [Items] | [Official source named in `compliance/eu.md`] | [Not Started] |
| `us` | [ADA (Title III); Section 508 for federal procurement] | [Per `compliance/us.md`] | [Items] | [Official source named in `compliance/us.md`] | [Not Started] |

---

## Platform Accessibility APIs

| Surface | API / Assistive Technology | What the Product Exposes | Status | Notes |
|---------|----------------------------|--------------------------|--------|-------|
| web | Semantic HTML + WAI-ARIA; NVDA / JAWS (Windows), VoiceOver (macOS, iOS Safari), TalkBack (Chrome on Android) | Names, roles, states, live regions, landmarks | Not Started | Prefer native elements over ARIA; test the component library once, then each screen |
| ios | UIAccessibility / SwiftUI accessibility modifiers; VoiceOver, Voice Control, Switch Control, Dynamic Type | Labels, traits, custom actions, rotor headings, announcements | Not Started | Cross-platform frameworks map their accessibility props onto these — verify on device |
| android | Android accessibility framework / Compose semantics; TalkBack, Switch Access, font scale | Content descriptions, roles, state descriptions, live regions | Not Started | Same |
| [Surface] | [API / AT] | [What is exposed] | [Status] | [Notes] |

---

## Per-Feature Accessibility Matrix

> One row per feature in `design/product/feature-map.md`. When a feature is added
> to the feature map, add a row here; a feature with an unaddressed concern cannot
> be marked Approved. See the guide for example rows.

| Feature | Perceivable Concerns | Operable Concerns | Understandable Concerns | Robust Concerns | Addressed | Notes |
|---------|----------------------|-------------------|-------------------------|-----------------|-----------|-------|
| [e.g., `goals`] | [Progress ring needs a text value] | [Reorder goals by drag needs buttons] | [Target-date picker needs a typed alternative] | [Custom ring exposes a value] | [Partially] | [—] |
| [Add feature from the feature map] | | | | | | |

---

## Accessibility Test Plan

| Area | Test Method | Test Cases | Pass Criteria | Responsible | Status |
|------|------------|------------|---------------|-------------|--------|
| Automated checks | axe-core in component tests and in the E2E suite (e.g., Playwright), run in CI | Every route and every component story | Zero violations at the target level; new violations fail the build | frontend-engineer | Not Started |
| Contrast | Contrast checker on design-token pairs, then on screenshots in light and dark themes | All text / background and non-text pairs | Ratios per the target | design-engineer | Not Started |
| Keyboard | Manual keyboard-only pass | Critical journeys: sign-up, onboarding, the core flow, settings, payment | Every action reachable; focus visible and not obscured; no trap | qa-engineer | Not Started |
| Screen readers | Manual passes with VoiceOver (iOS, macOS), TalkBack, NVDA | Critical journeys | Every control named; state changes announced; order logical | accessibility-specialist | Not Started |
| Text scaling & reflow | 200 % zoom / largest Dynamic Type / max font scale; 320 CSS px width | Critical journeys | No loss of content or function; amounts and errors never truncated | qa-engineer | Not Started |
| Reduced motion | Platform setting on | All animated transitions | Replacements as specified | qa-engineer | Not Started |
| Regional checklist | Items from `## Regional Standards` | Per region | Each item Met or a recorded limitation | accessibility-specialist | Not Started |
| User testing | Sessions with users of assistive technology | Core flow | Participants complete the flow without assistance | ux-researcher | Not Started |

---

## Known Intentional Limitations

> Every entry here is a risk — assess it honestly. A limitation that conflicts with a
> regional standard is escalated to the product owner, not silently accepted.

| Feature / Content | Requirement Not Met | Why Not Included | Risk / Impact | Mitigation / Alternative Path | Review Date |
|-------------------|---------------------|------------------|---------------|-------------------------------|-------------|
| [Add any intentionally excluded requirement] | | | | | |

---

## Audit History

| Date | Auditor | Type (automated / manual / third-party) | Scope | Findings Summary | Status |
|------|---------|------------------------------------------|-------|------------------|--------|
| [Add a row for each audit] | | | | | |

---

## External Resources

| Resource | URL | Relevance |
|----------|-----|-----------|
| WCAG 2.2 | https://www.w3.org/TR/WCAG22/ | The success criteria this document cites |
| How to Meet WCAG (Quick Reference) | https://www.w3.org/WAI/WCAG22/quickref/ | Techniques and failures per success criterion |
| WAI-ARIA Authoring Practices Guide | https://www.w3.org/WAI/ARIA/apg/ | Accessible patterns for custom web widgets |
| Apple Human Interface Guidelines — Accessibility | https://developer.apple.com/design/human-interface-guidelines/accessibility | iOS conventions: VoiceOver, Dynamic Type, target sizes |
| Android accessibility | https://developer.android.com/guide/topics/ui/accessibility | TalkBack, semantics, touch target guidance |
| axe-core | https://github.com/dequelabs/axe-core | Automated checks in CI |
| Regional checklists | `.claude/docs/compliance/<region>.md` | The regional items in `## Regional Standards` and where to verify them |

---

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| [Add question] | [Owner] | [Deadline] | [Resolution] |
