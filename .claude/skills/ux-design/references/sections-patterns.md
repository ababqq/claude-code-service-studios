> Section-authoring guidance, loaded by `/ux-design` for the ACTIVE MODE ONLY.
> Never load the other two — one mode applies per invocation.

# Section Guidance — Interaction Pattern Library Mode

The pattern library (`design/ux/interaction-patterns.md`, from
`.claude/docs/templates/interaction-pattern-library.md`) is additive and
catalog-driven, not linear. Examples use Moa, a subscription savings app
(web + iOS + Android); replace them with the product's own.

#### Phase 1: Catalog Existing Patterns

Glob `design/ux/*.md` (excluding `interaction-patterns.md` and `app-shell.md`) and
read the Component Inventory and Interaction Map sections of each screen spec, and
the Critical Path of each flow spec. Extract every interaction pattern used.

Present the extracted list: "Based on existing UX specs, these patterns are already
in use in the product:"
- [Pattern name]: used in [screen], [screen]
- [etc.]

Ask: "Are there patterns you know exist but aren't in existing specs yet? List any
additional ones now." Also check `design/brand/design-language.md` — every
interactive component in its components & states section needs a pattern entry that
defines its behaviour.

---

#### Phase 2: Formalize Each Pattern

For each pattern (existing or new), document:

```markdown
#### [Pattern Name]

**Category**: Navigation / Input / Feedback / Data Display / Modal / Overlay / Service-Specific / [other]
**Status**: Draft
**Used In**: [list of screens]

**Description**: [One paragraph explaining what this pattern is and when to use it]

**Specification**:
- [Component behavior per state — default, hover, focus, pressed, disabled, loading, error]
- [Input mapping — keyboard, pointer, touch, screen reader]
- [Visual and haptic feedback — haptics never the only feedback]
- [Accessibility requirements for this pattern, at the committed target]

**When to Use**: [Conditions where this pattern is appropriate]
**When NOT to Use**: [Conditions where another pattern is more appropriate]

**Implementation Notes**: [The component-library component per surface — plus its Code Connect mapping (Figma component → repo component) when the design-system handoff record lists one]

**Reference**: [A screen under `design/handoff/<slug>/screens/`, the Figma component or node link, or the Claude Design design-system component — each from a handoff record — or an ASCII example, if available]
```

When `design.tool` is claude-design or figma, read
`design/handoff/design-system/HANDOFF.md` (if it exists) for the header's
`> **Component Library**:` line — the Figma library or Claude Design design-system
link and the Code Connect mappings — and its `## Tokens & Components` for each
pattern's component. The record is reference, not source: behaviour is decided here,
and a design component with no library counterpart is a gap for the
`design-engineer`, not a pattern. No record ⇒ write the line without the link and
note `NOT CHECKED — external design not retained (<url>)` as an open question
(`/design-handoff` imports it). This session reads the record with Read; live
design tools are used only conditionally (Phase 2i of the skill).

Work through patterns in groups. Use `AskUserQuestion`:
- "How do you want to work through these patterns?"
- Options: "Draft the first batch from existing specs (faster)", "Define them one by one (more control)", "Start with the most-used pattern first"

**Service-specific patterns.** The template's `## Service-Specific Patterns` section
holds the patterns most service products need beyond standard controls. For each
one the product uses, make sure the entry answers the questions below — they are
where specs most often stay vague:

| Pattern | What the entry must pin down |
|---------|------------------------------|
| Form & Inline Validation | When validation runs (on blur and on submit, not per keystroke); where errors appear (next to the field and in a summary that receives focus on submit); that input survives errors; that client rules mirror the API, which stays the authority; keyboard type and `autocomplete` per field |
| Data Table | Column priority per breakpoint (what collapses on `sm`); sort and its announcement; row actions; server-side sort and pagination for large sets; selection and bulk actions |
| Search / Filter / Sort | Debounce and IME handling (Korean composition must finish before querying); URL-reflected state on web; visible, removable active filters; the result count announced; the no-results state |
| Pagination / Infinite Scroll | Cursor pagination and page size, matched to each screen's `## API Data`; "Load more" as the keyboard and screen-reader path even with automatic loading; whether users must reach a footer or return to a position |
| Date & Time Picker | The typed alternative; locale date format; the time zone that applies (debit days in KST); disabled dates with a reason |
| File Upload | Type and size limits stated up front; per-file progress, retry and removal; button-based selection with drag and drop as an addition |
| Payment Sheet | Amount, currency, renewal date and cancellation terms shown before commit; the commit label repeats the amount; declined, cancelled and timed-out states; idempotent retries; the provider SDK or widget per surface and store billing rules for in-app purchases |
| OTP / Identity Verification | One field with one-time-code autofill and paste; resend timing and lockout states; the vendor handoff for 본인인증 with designed return and cancel states |
| Permission Prompt | The pre-permission explanation shown in context after the benefit is visible; the denied and permanently-denied states with a settings path; re-checking on return |
| Pull-to-Refresh | The non-gesture refresh path for keyboard, pointer and screen-reader users; content stays visible while refreshing |

The reference specifications for these patterns are in
`.claude/docs/templates/guidance/interaction-pattern-library-guide-service-specific.md`
— load only the pattern being specified.

Regional rules (consent checkboxes, marketing-message opt-in, commerce disclosures)
affect several of these patterns. When a pattern touches them, cite the item from
`.claude/docs/compliance/<region>.md` for the regions in `compliance.regions`; do not
restate the law.

---

#### Phase 3: Identify Gaps

After cataloging known patterns, ask:
- "Are there screens or interactions planned that would need patterns not yet in
  this library?" (Check the PRDs' `## UI Requirements` and the screen inventory.)
- "Are there any patterns in existing specs that feel inconsistent with each other
  and should be consolidated?" (Common ones: two different confirmation styles for
  destructive actions; toasts used for errors on some screens and banners on
  others; different Back behaviour in dialogs and sheets.)

Document gaps in the Open Questions table for follow-up, each with an owner.
