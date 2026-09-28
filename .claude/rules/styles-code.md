---
paths:
  - "**/*.css"
  - "**/*.scss"
  - "**/styles/**"
  - "**/tokens/**"
  - "**/theme/**"
---

# Styles Code Rules

These paths hold stylesheets, design tokens and theme definitions for web and mobile. The design language
(`design/brand/design-language.md`) decides what things look like; the token source (`design/brand/tokens.json`,
W3C Design Tokens format) is its machine-readable form; styles consume tokens and nothing else. The `design-engineer`
agent owns the token pipeline.

## Tokens only

- **No magic values.** Colors, spacing, font sizes, line heights, radii, shadows, z-index layers, breakpoints,
  durations and easings come from tokens. No raw hex, `rgb()`/`hsl()`, pixel spacing or ad-hoc durations outside the
  token source — including Tailwind arbitrary values (`bg-[#12b886]`, `p-[13px]`) and inline `style` objects.
- **Three tiers, used in order**: primitive tokens (`color.green.500`, `space.4`) are referenced only by semantic
  tokens; semantic tokens (`color.bg.surface`, `color.text.danger`, `color.border.focus`) are what components and
  screens use; component tokens (`button.primary.bg`, `progress-ring.fill`) exist only where a component needs its
  own knob.
- **Generated files are not edited.** CSS custom properties, SCSS maps, the Tailwind theme and native theme files
  (Swift, Kotlin/Compose, Dart) are built from the token source and carry a "generated — do not edit" header; change
  the source and rebuild.
- A value the design language lacks is a request to the `design-engineer` / `design-director`, not a new literal.

## Responsive breakpoints

- Mobile-first: base styles target the smallest supported width, and breakpoint tokens (the design language's
  `### Breakpoints & Grid`) add layout at larger widths. Custom properties cannot be used inside media query
  conditions, so breakpoints reach stylesheets through the token build (SCSS variables, `@custom-media`, or the
  Tailwind `screens` generated from tokens) — never as hand-typed pixel values.
- Prefer container queries for components whose layout depends on their container rather than the viewport.
- Content reflows at 320 CSS px width without horizontal scrolling (WCAG 2.2 SC 1.4.10) and survives 200% text
  zoom; no fixed heights on text containers.
- Use logical properties (`margin-inline-start`, `padding-block`) so a right-to-left locale does not need a second
  stylesheet.
- Korean text: `word-break: keep-all` for body copy so words are not split mid-word, with `overflow-wrap: anywhere`
  as the escape hatch for long URLs and account numbers. Web fonts for CJK are subset and loaded with
  `font-display: swap` (checked by `/bundle-audit`).

## Dark mode and theming

- Every semantic color token has a light and a dark value; themes switch by swapping semantic tokens
  (`prefers-color-scheme` plus the user's in-app override, e.g. `[data-theme='dark']`), with `color-scheme` set so
  form controls and scrollbars follow.
- Never derive dark mode with `filter: invert()` or by darkening light values in code. Images, illustrations and
  charts have dark variants or transparent backgrounds; elevation in dark mode uses surface tokens, not shadows
  alone.
- Honour `forced-colors: active` (Windows high contrast): do not remove borders or outlines that carry meaning.

## Contrast

- Text and UI colors meet the ratio `accessibility.target` requires — for WCAG 2.2 AA, 4.5:1 for body text, 3:1 for
  large text, and 3:1 for component boundaries, icons and focus indicators (SC 1.4.3 and 1.4.11) — in **both**
  themes. The design language's `### Contrast Against the Accessibility Target` table records the checked pairs; a
  new foreground/background pair is added there before it ships.
- `accessibility.target` unset ⇒ ask; unset is not `none`.
- Color is never the only carrier of meaning (errors, statuses, chart series): pair it with an icon, text or
  pattern (SC 1.4.1).
- Focus is always visible: style `:focus-visible` with the focus token; `outline: none` without a replacement is a
  defect. Sticky headers and bottom bars must not cover the focused element (`scroll-padding`, SC 2.4.11).

## Reduced motion

- Durations and easings come from motion tokens. Non-essential motion — parallax, auto-advancing carousels,
  celebratory animations, large transitions — runs only under `@media (prefers-reduced-motion: no-preference)`;
  under `reduce`, state changes still happen, instantly or as a short fade.
- Animate `transform` and `opacity`, not layout properties (`width`, `top`, `height`), to keep interactions smooth
  and INP within `performance.inp_ms`.
- Anything that moves for more than a moment has a pause control (SC 2.2.2).

## Structure

- Styles are scoped (CSS Modules, utility classes, or the component-styling approach the ADR chose); global rules
  live only in the reset/base layer. Use cascade layers (`@layer reset, base, components, utilities`) instead of
  specificity battles; `!important` only inside utilities.
- File names follow `naming.files`; class naming follows the one methodology the ADR chose.

## Examples

**Correct** (CSS — Moa goal card; semantic tokens, reduced-motion guard, visible focus):

```css
.goal-card {
  padding: var(--space-4);
  border-radius: var(--radius-md);
  background: var(--color-bg-surface);
  color: var(--color-text-primary);
  word-break: keep-all;
}

.goal-card:focus-visible {
  outline: var(--focus-ring-width) solid var(--color-border-focus);
  outline-offset: var(--focus-ring-offset);
}

@media (prefers-reduced-motion: no-preference) {
  .progress-ring__fill {
    transition: stroke-dashoffset var(--motion-duration-slow) var(--motion-easing-standard);
  }
}
```

**Incorrect**:

```css
.goal-card {
  padding: 13px;                      /* VIOLATION: magic spacing */
  background: #ffffff;                /* VIOLATION: raw color; breaks dark mode */
  color: #9e9e9e;                     /* VIOLATION: raw color that fails 4.5:1 on white */
}
.goal-card:focus { outline: none; }   /* VIOLATION: focus removed with no replacement */
@media (max-width: 767px) { ... }     /* VIOLATION: hand-typed breakpoint, desktop-first */
.progress-ring__fill {
  transition: width 1.2s ease-in;     /* VIOLATION: animates layout, ignores reduced motion, ad-hoc duration */
}
```
