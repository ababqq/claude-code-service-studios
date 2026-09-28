> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# DD-DESIGN-LANGUAGE — Design Language Sign-off

Agent: `design-director` | Model tier: inherit | Domain: Design language

**Trigger**: Spawned by `/design-language` after the design language is drafted,
before UI production (hi-fi UX specs, the component library) builds on it. It
reviews tokens, components and their states, contrast against
`accessibility.target`, and platform adaptation.

**Context to pass**:
- `design/brand/design-language.md` path
- resolved `accessibility` line
- resolved `surfaces` line
- brief path

**Prompt**:
> "Review this design language for completeness and internal consistency before UI
> production begins. Read the design language and the brief at the paths given.
> Check:
>
> 1. **Tokens** — semantic color tokens (components never reference raw hex values),
>    light and dark themes, and scales for spacing, typography, radius and elevation,
>    named so a pipeline can emit them for CSS, iOS and Android.
> 2. **Contrast against the accessibility target** — for `wcag-aa`: 4.5:1 for body
>    text, 3:1 for large text, 3:1 for UI components, focus indicators and meaningful
>    graphics (WCAG 2.2 success criteria 1.4.3 and 1.4.11), minimum target size
>    24 × 24 CSS px (2.5.8); for `wcag-aaa`, the enhanced ratios. Check both themes
>    and every semantic state color, not just the brand palette.
> 3. **Components and states** — each core component defines default, hover, focus,
>    pressed, disabled, loading, error and empty states; forms show validation
>    timing and error placement; destructive and money-moving actions have a
>    confirmation pattern; amounts follow one format (for Moa: `12,000원`, no decimal
>    places for KRW).
> 4. **Typography** — a font stack with Hangul fallbacks, line-height suited to
>    Hangul, `word-break: keep-all` for Korean text on web, font subsetting to keep
>    bundles small, and support for Dynamic Type and Android font scaling.
> 5. **Platform adaptation** — for each configured surface: web breakpoints;
>    iOS navigation, sheets and haptics per the Human Interface Guidelines; Android
>    top app bar, predictive back and edge-to-edge per Material 3; what is shared and
>    what is deliberately native.
> 6. **Motion and feedback** — durations and easing, reduced-motion behaviour,
>    haptics and notification sound.
> 7. **Content and voice** — section 9 points to `design/brand/voice-and-tone.md` and
>    adds only UI copy rules; it does not define a second voice.
> 8. **Coherence** — the language follows from the brief's principles and the chosen
>    brand direction; no two sections contradict each other; a design engineer could
>    build the component library from this document without further briefing.
>
> Return APPROVE (ready to gate UI production), CONCERNS [specific sections needing
> clarification], or REJECT [fundamental inconsistencies that must be resolved
> before UI production begins]."

**Verdicts**: APPROVE / CONCERNS / REJECT

The first line of the reply is exactly `[DD-DESIGN-LANGUAGE]: <TOKEN>` with one token
from the line above; the spawning skill parses it. Findings follow the first line.

**Special handling**:
- At the `standard` workflow tier only sections 1–5 are required (unless
  `workflow_overrides.design_language_strict` is set). Sections 6–9 marked as
  deferred are not a finding; review what is present.
- An `accessibility.target: (unset -- ask; unset is not none)` line means the target
  is undecided, not `none`. Report `NOT CHECKED — contrast (accessibility target
  unset; decide it with /ux-design accessibility)` and cap the verdict at CONCERNS.
- Check only the surfaces the `surfaces` line lists; an unset line means ask — do not
  assume web only.
- Read the document's `> **Design Source**:` header line. When its first token is
  `figma` or `claude-design`, drift between that source — the Figma variables or the
  Claude Design design system recorded in `design/handoff/design-system/HANDOFF.md` —
  and the document's tokens is a finding (name the token, both values and the
  section). The document remains authoritative: the fix is to reconcile the source
  to the document, or to revise the document first, never to adopt the source's
  value silently. A `NOT CHECKED — …` item for the design source in the
  `> **Not Checked**:` line is carried into the findings as not checked, never read
  as a match. `none` means there is no external source — no finding.
