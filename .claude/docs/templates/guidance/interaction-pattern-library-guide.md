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
