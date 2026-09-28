> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# DD-BRAND-DIRECTION — Brand Direction

Agent: `design-director` | Model tier: inherit | Domain: Brand & visual direction

**Trigger**: Spawned by `/design-language` in its first phase when the product brief
has no `## Brand Direction Anchor`, and optionally by `/brainstorm` at the `full`
workflow tier when a UI surface is configured, after the product principles are
drafted (the user may defer it to `/design-language`). It derives 2–3 distinct
brand and UI directions from the principles; the user selects one.

**Context to pass**:
- brief path
- product principles text
- target users
- resolved `surfaces` line

**Prompt**:
> "Based on these product principles and target users, propose 2–3 distinct brand and
> UI directions. Read the brief at the path given for positioning and alternatives.
> For each direction provide:
>
> 1. **A name** and a **one-line brand rule** that could guide every UI decision (for
>    Moa: 'Calm money — nothing on screen raises the heart rate unless money is
>    actually at risk', or 'Progress you can feel — every screen shows how close the
>    goal is').
> 2. **Personality and tone targets** — three adjectives and one 'but not' (warm, but
>    not childish); these feed the voice-and-tone profile later.
> 3. **Color philosophy** — what color means in this product, including cultural
>    conventions of the target market (in Korean finance interfaces red commonly
>    signals a rise, not an error), and headroom for the contrast the accessibility
>    target will demand.
> 4. **Typography direction** — a Hangul-first UI typeface paired with Latin and
>    numerals that read well in amounts and dates.
> 5. **Shape, density and imagery** — rounded or crisp, airy or information-dense,
>    illustration or photography, per surface.
> 6. **Motion and feedback character** — how success, progress and errors feel.
> 7. **Platform stance** — brand-forward custom components versus following iOS
>    Human Interface Guidelines and Material conventions on each configured surface,
>    and what that costs to build and maintain.
>
> Be specific — avoid generic descriptions ('modern, clean, friendly'). One direction
> should directly serve the most important principle. Recommend the direction that
> best serves the principles and target users, and explain why and what it risks."

**Verdicts**: OPTIONS / STRONG / CONCERNS

- **OPTIONS** — several valid directions; the user selects. This is a selection, not
  a verdict: the spawning skill presents the directions, records the chosen one, and
  then treats the outcome as APPROVE-class.
- **STRONG** — one direction is clearly dominant; present it together with the
  runner-up so the user can still choose.
- **CONCERNS** — the principles do not give enough direction to differentiate a brand
  yet; say which principle or positioning statement must be sharpened first.

The first line of the reply is exactly `[DD-BRAND-DIRECTION]: <TOKEN>` with one token
from the line above; the spawning skill parses it. The directions follow the first
line.

**Special handling**:
- The chosen direction is recorded by the spawning skill — in the brief's
  `## Brand Direction Anchor` (from `/brainstorm`) or in `## 1. Brand Principles` of
  the design language (from `/design-language`). Never write either file yourself.
- If the resolved `surfaces` line shows no UI surface (`api` only), reply CONCERNS
  and say that a UI brand direction does not apply; offer a developer-facing identity
  (documentation portal, naming and error-message tone) only if asked.
- If the `surfaces` line is unset, propose directions for web and mobile, and mark
  item 7 `NOT CHECKED — surfaces unset`.
