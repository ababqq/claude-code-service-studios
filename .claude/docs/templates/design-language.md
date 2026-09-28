# Design Language: [Product Name]

> **Verdict**: [COMPLETE | PARTIAL — SECTIONS <n>-<m> | NOT ASSESSED]

> **Status**: Draft | In Review | Approved
> **Owner**: design-director
> **Last Updated**: [YYYY-MM-DD]
> **Brief**: [`design/product/product-brief.md` (or `design/product/one-pager.md`)]
> **Brand Direction**: [direction name — from the brief's `## Brand Direction Anchor`, or selected in `/design-language` on YYYY-MM-DD]
> **Surfaces**: [resolved `platform.surfaces` line, copied as printed — e.g. `web, ios, android`]
> **Accessibility Target**: [resolved `accessibility.target` line, copied as printed — unset is not `none`]
> **Design Source**: [none — markdown spec only | claude-design — <design-system project URL> · record `design/handoff/design-system/HANDOFF.md` | figma — <library file URL> · record `design/handoff/design-system/HANDOFF.md`] — token direction: [this document → `design/brand/tokens.json` | this document, reconciled with Figma variables YYYY-MM-DD | this document only — tokens live in Figma variables or code]
> **Sections Deferred**: [e.g. "6–9 (standard tier)" — or "none"]
> **Not Checked**: [items that could not be verified in this run, each with its reason — or "none"]
> **Design Director Review (DD-BRAND-DIRECTION)**: [APPROVED YYYY-MM-DD | CONCERNS (accepted) YYYY-MM-DD | REVISED YYYY-MM-DD | `[DD-BRAND-DIRECTION] skipped — <Mode> mode` | not run — direction taken from the brief's anchor]
> **Design Director Review (DD-DESIGN-LANGUAGE)**: [APPROVED YYYY-MM-DD | CONCERNS (accepted) YYYY-MM-DD | REVISED YYYY-MM-DD | `[DD-DESIGN-LANGUAGE] skipped — <Mode> mode`]

> **What this document is**: the visual and interaction source of truth for every
> UI surface of the product. UX specs, the app shell, the interaction pattern
> library, the component library and every media asset build on it; a spec or a
> screen that contradicts it is wrong, or this document needs a revision first.
> It is authored and revised with `/design-language`; section 9 points to the
> voice-and-tone guide instead of defining a second voice.
>
> **Tier note**: `full` — all nine sections are required. `standard` — sections
> 1–5 are required when a UI surface (web, iOS, Android) is configured; sections
> 6–9 are optional. `workflow_overrides.design_language_strict: true` forces all
> nine at `standard`. `minimal` — not required (it may still be written). An
> API-only product does not need this document.
>
> **Verdict line**: `COMPLETE` = all nine sections complete and nothing in them
> left not checked. `PARTIAL — SECTIONS <n>-<m>` = sections n–m are complete and
> at least one other section is not (`PARTIAL — SECTIONS 1-5` meets the
> `standard` tier). `NOT ASSESSED` = all nine sections are written but something
> required could not be verified (listed in **Not Checked** above). A known gap
> outranks an unverified one: PARTIAL > NOT ASSESSED > COMPLETE.
>
> **Design Source line**: where the design system also lives outside the repo — a
> Figma library or a Claude Design design-system project, retained in
> `design/handoff/design-system/HANDOFF.md` by `/design-handoff` — and which way the
> tokens flow. This document stays the source of intent: Figma variables and the
> Claude Design design system are reconciled to it, and drift between them is a
> finding. A declared source whose record could not be read puts a `NOT CHECKED — …`
> item on the **Not Checked** line, which keeps the verdict below `COMPLETE`. `none`
> is a recorded decision; an unset `design.tool` is asked, never read as `none`.
>
> Keep every heading below exactly as written — `/gate-check`, `/ux-review` and
> the director gates match on them. Write the body in the team's working
> language; token names, values and file paths stay as they are.

---

## 1. Brand Principles

> The rule every later visual decision is tested against. Derive it from the
> product principles in the brief — a brand principle that no product principle
> supports is decoration.

### Brand Rule

[One line that resolves any visual ambiguity. Example (Moa): "Calm money —
nothing on screen raises the heart rate unless money is actually at risk."]

### Principles

| # | Principle | Serves product principle | Design test ("when X is ambiguous, choose Y") |
|---|-----------|--------------------------|-----------------------------------------------|
| 1 | [e.g. Progress is always visible] | [brief principle it serves] | [e.g. "When a screen could show either a balance or progress toward a goal, show progress"] |
| 2 | | | |
| 3 | | | |

### Personality

[Three adjectives and one "but not" — e.g. "warm, steady, encouraging — but not
childish". These feed `design/brand/voice-and-tone.md`; they do not replace it.]

### Direction Record

| Field | Value |
|-------|-------|
| Selected direction | [name + one-line rule] |
| Source | [brief `## Brand Direction Anchor` / DD-BRAND-DIRECTION on YYYY-MM-DD / described by the user / drafted by product-designer] |
| Alternatives considered | [names of the directions not chosen and why] |
| Visual reference | [record `design/handoff/brand-directions/HANDOFF.md`, the brief anchor's **Visual reference** URL, or "none"] |

### References

| Reference | What we take | What we avoid |
|-----------|--------------|---------------|
| [product, brand or design system] | [a specific technique, not "the general aesthetic"] | [what would make us read as a copy] |

---

## 2. Color System

> Semantic tokens first; raw hex values appear only in the primitive palette.
> Every foreground/background pair a component can produce has a contrast row.

### Primitive Palette

| Token | Light value | Dark value | Notes |
|-------|-------------|------------|-------|
| [color.green.500] | [#hex] | [#hex] | [role in the brand] |

### Semantic Tokens

| Token | Purpose | Light → primitive | Dark → primitive |
|-------|---------|-------------------|------------------|
| `color.bg.surface` | [default screen background] | | |
| `color.text.primary` | [body text] | | |
| `color.action.primary` | [one primary action per screen] | | |
| `color.feedback.danger` | [errors, destructive actions] | | |
| `color.border.focus` | [focus indicator] | | |

### Themes

[Light and dark (and high contrast if committed): how the theme is chosen
(system preference, user override, persistence), how elevation reads in dark
mode, and whether Android dynamic color is used or overridden by the brand.]

### Contrast Against the Accessibility Target

| Foreground token | Background token | Theme | Ratio | Required | Pass |
|------------------|------------------|-------|-------|----------|------|
| `color.text.primary` | `color.bg.surface` | light | [n.n:1] | [4.5:1 at `wcag-aa`] | [yes/no] |

[Required ratios follow `accessibility.target` (WCAG 2.2). Unset target ⇒ write
`NOT CHECKED — accessibility.target unset` here and in **Not Checked**.]

### Color Meaning

[What each semantic color means in this product, cultural conventions of the
target market (in Korean finance interfaces red commonly signals a rise, not an
error), and the rule that color is never the only signal — every status also
has an icon, a label or a shape.]

---

## 3. Typography

### Font Stack per Surface

| Surface | Primary (Hangul + Latin) | Fallbacks | Numerals |
|---------|--------------------------|-----------|----------|
| web | [e.g. Pretendard Variable] | [system-ui, "Apple SD Gothic Neo", "Noto Sans KR", sans-serif] | [tabular for amounts] |
| ios | | | |
| android | | | |

### Type Scale

| Token | Size | Line height | Weight | Letter spacing | Use |
|-------|------|-------------|--------|----------------|-----|
| [font.body.md] | | | | | |

### CJK Typesetting

[Line height suited to Hangul, `word-break: keep-all` for Korean on the web
(with `overflow-wrap: anywhere` for long URLs and IDs), letter-spacing rules,
mixed Hangul/Latin/numeral runs, and how amounts, dates and times align.]

### Font Loading & Subsetting

[Subsetting strategy (unicode-range chunks or a dynamic subset), which weights
ship, preload policy, fallback metrics to avoid layout shift, and the font byte
budget relative to the route budgets `/bundle-audit` measures.]

### Text Scaling

[Behaviour at 200% browser zoom, iOS Dynamic Type sizes and Android font scale:
what reflows, what truncates, what must never clip.]

---

## 4. Layout, Spacing & Grid

### Spacing Scale

| Token | Value | Typical use |
|-------|-------|-------------|
| [space.1] | [4] | |

### Breakpoints & Grid

| Breakpoint | Min width | Columns | Gutter | Margin | Max content width |
|------------|-----------|---------|--------|--------|-------------------|
| `sm` | | | | | |
| `md` | | | | | |
| `lg` | | | | | |

[Mobile size classes (compact / regular), safe areas, orientation support.]

### Radius, Elevation & Density

[Radius scale, elevation or shadow tokens per theme, and information density
per surface — e.g. the admin console denser than the consumer app.]

---

## 5. Components & States

### Core Components

| Component | Variants | Used for | Library status |
|-----------|----------|----------|----------------|
| [Button] | [primary, secondary, destructive, text] | | [planned / built] |

### State Matrix

| Component | Default | Hover | Focus | Pressed | Disabled | Loading | Error | Empty |
|-----------|---------|-------|-------|---------|----------|---------|-------|-------|
| [Button] | | | | | | | — | — |

### Focus, Targets & Forms

[Focus indicator (thickness, offset, color token, contrast against adjacent
colors), minimum target sizes (WCAG 2.2 24 × 24 CSS px; 44 × 44 pt on iOS;
48 × 48 dp on Android), form validation timing and error placement.]

### Confirmation for Destructive and Money-Moving Actions

[When a confirmation is required, how it is labelled ("Cancel subscription",
never "OK"), where re-authentication is required, and the amount format shown
before a payment or transfer is confirmed.]

---

## 6. Iconography & Illustration

[Icon grid, stroke and corner rules, sizes, filled vs outlined meaning, naming
convention, and the stance on SF Symbols / Material Symbols per surface.
Illustration style, where illustration is used (empty states, onboarding) and
where it is not. Photography and imagery rules. App icon principles. Individual
media assets are specified in `design/inventory/media-manifest.md`
(`/ui-inventory media`).]

---

## 7. Motion & Feedback

### Motion Tokens

| Token | Duration | Easing | Use |
|-------|----------|--------|-----|
| [motion.fast] | | | |

### Reduced Motion

[What each animation becomes when the OS or browser requests reduced motion;
nothing flashes more than three times per second.]

### Haptics

| Event | iOS | Android | Web |
|-------|-----|---------|-----|
| [success — goal reached] | [notification success] | [CONFIRM] | [none] |

### Notification Sound

[System default or a custom sound, for which notification types, and the rule
that sound or haptics never carry information that is not also on screen.]

### Feedback Character

[How success, progress, waiting and errors feel — skeleton vs spinner, optimistic
updates, celebration moments and how rare they are.]

---

## 8. Platform Adaptation

| Surface | Follows | Deliberately custom | Notes |
|---------|---------|---------------------|-------|
| web | [browser conventions, the breakpoints of section 4] | | |
| ios | [Human Interface Guidelines: navigation bar, tab bar, sheets, swipe-back] | | |
| android | [Material 3: top app bar, navigation bar, predictive back, edge-to-edge] | | |

[What is shared across surfaces (tokens, component names, copy) and what is
native on purpose, with the build and maintenance cost of each divergence.]

---

## 9. Content & Voice

> Voice has one source of truth: `design/brand/voice-and-tone.md` (maintained
> with `/team-content`). This section only points to it and adds UI copy rules.

**Voice & tone**: see `design/brand/voice-and-tone.md` [or "not written yet —
run `/team-content`"].

### UI Copy Rules

[Button labels (verb first, specific: "Create goal", not "OK"), capitalization,
error message structure (what happened + what to do), empty-state copy, truncation
and line-clamp rules, and formats: amounts (e.g. `12,000원` — KRW has no minor
unit), dates and times per locale, relative time.]
