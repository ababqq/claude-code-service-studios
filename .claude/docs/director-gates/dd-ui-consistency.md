> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# DD-UI-CONSISTENCY — UI Consistency Review

Agent: `design-director` | Model tier: inherit | Domain: UI consistency

**Trigger**: Spawned by `/ux-review` when a UX spec, the app shell or the pattern
library is validated, before the review record is written, and by `/team-ui` after
its Review phase, before polish. It checks that the spec or the implementation
conforms to the design language and the interaction pattern library.

**Context to pass**:
- UX spec path or implemented screen list
- design-language path
- `design/ux/interaction-patterns.md` path
- resolved `accessibility` line

**Prompt**:
> "Review this UI for consistency with the design language and the interaction
> pattern library. Read the spec (or the implemented screens and their evidence
> screenshots under `production/qa/evidence/`), the design language and the pattern
> library at the paths given. Check:
>
> 1. **Tokens and components** — only design tokens (no one-off colors, spacing or
>    type sizes) and only library components; any new component is justified and
>    proposed for the library rather than built as a one-off.
> 2. **Patterns** — navigation, forms and validation, errors, empty states, loading
>    and skeletons, toasts versus banners, pull-to-refresh and confirmation of
>    destructive or money-moving actions follow `design/ux/interaction-patterns.md`.
>    For Moa: cancelling an automatic debit uses the standard confirmation sheet and
>    states the date of the next debit that will no longer happen.
> 3. **States** — every screen covers loading, empty, error, offline and
>    permission-denied states, and signed-out or expired-session behaviour.
> 4. **Platform conventions** — each surface follows its platform's navigation and
>    control conventions where the design language says it should.
> 5. **Accessibility against the target** — accessible names and roles, focus order,
>    contrast in both themes, target size, Dynamic Type and font scaling, screen
>    reader announcements for asynchronous results (a deposit confirmed).
> 6. **Copy** — follows the UI copy rules of the design language; product terms match
>    the glossary.
> 7. **Spec versus implementation** (from `/team-ui`) — what was built matches the
>    approved spec; deviations are listed with their screenshots.
>
> Return APPROVE, CONCERNS [specific adjustments], or REJECT [consistency or
> accessibility violations that must be resolved before this UI proceeds]."

**Verdicts**: APPROVE / CONCERNS / REJECT

The first line of the reply is exactly `[DD-UI-CONSISTENCY]: <TOKEN>` with one token
from the line above; the spawning skill parses it. Findings follow the first line.

**Special handling**:
- If the pattern library does not exist yet, review against the design language
  alone, report `NOT CHECKED — pattern library absent (run /ux-design patterns)`, and
  cap the verdict at CONCERNS.
- An unset accessibility target is undecided, not `none`: check the basics (names,
  focus order, contrast at the `wcag-aa` level as a reference) and flag the unset
  target.
