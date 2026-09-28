> Authoring guidance for interaction-pattern-library.md. Load only the part covering the section currently being authored — not the whole file at once.

# Interaction Pattern Library — Guidance Index

The guidance for this template is split by major section so consumers can load
one part at a time. Read the file matching the section you are currently
authoring — never all three at once.

| Template Section | Guidance File |
|------------------|---------------|
| Standard Control Patterns (Button variants, Toggle, Slider, Dropdown / Select, List Item, Grid Item, Modal Dialog, Confirmation Dialog, Toast / Notification, Tooltip, Progress Bar, Input Field, Tab Bar, Scroll Container) | `.claude/docs/templates/guidance/interaction-pattern-library-guide-standard-controls.md` |
| Service-Specific Patterns (Form & Inline Validation, Data Table, Search / Filter / Sort, Pagination / Infinite Scroll, Date & Time Picker, File Upload, Payment Sheet, OTP / Identity Verification, Permission Prompt, Pull-to-Refresh) | `.claude/docs/templates/guidance/interaction-pattern-library-guide-service-specific.md` |
| Navigation Patterns + Feedback and Loading Patterns (Screen Push / Pop / Replace, Focus Management, Escape / Cancel, Loading State, Empty State, Error State) | `.claude/docs/templates/guidance/interaction-pattern-library-guide-navigation-feedback.md` |

Each guidance file contains the full reference specification for its patterns —
When to Use / When NOT to Use rationale, complete state tables with timing and
feedback values, accessibility requirements for keyboard, pointer, touch and
screen readers, and implementation notes per stack. Use them as the
worked-example source when filling the corresponding skeleton stubs in the
template. The pattern catalog index, the animation and feedback standards, and
the open questions remain in the template itself.

## Header — Component Library

The `> **Component Library**:` line names where the components live. With an
external design tool (`design.tool` claude-design or figma), it also names the
design-side library and the Code Connect mapping, read from the design-system
handoff record `design/handoff/design-system/HANDOFF.md` that `/design-handoff`
writes. Worked example (Moa):

```
> **Component Library**: `packages/ui` (Storybook https://storybook.moa.example) · Figma library
>   https://www.figma.com/design/<fileKey>/Moa-Design-System · Code Connect: Button → `packages/ui/src/button.tsx`,
>   StatusChip → `packages/ui/src/status-chip.tsx` · record `design/handoff/design-system/HANDOFF.md`
```

A screen spec names its own source the same way on its `> **Design Source**:` line —
for Moa's goal detail screen,
`` figma — https://www.figma.com/design/<fileKey>/Moa?node-id=12-345 · record `design/handoff/goal-detail/HANDOFF.md` ``;
with no external tool, `none — markdown spec only`. The library behaviour is decided
here, not in the design file: a design component with no library counterpart is a
gap for the `design-engineer`, and a value with no design-language token is a
request, never a new token.
