# Design Directory

When authoring or editing files in this directory, follow these standards. Headings that come from a template are
contracts: keep them in English exactly as the template spells them, and write the body in the conversation language.

## Layout

```text
design/
├── product/                      # product-brief.md (standard/full) | one-pager.md (minimal),
│   │                             # feature-map.md, user-journey.md, tracking-plan.md, pricing-model.md,
│   │                             # pitch.md, personas/<slug>.md, product-brief-from-code-YYYY-MM-DD.md
│   └── reviews/                  # <stem>-review-log.md for the brief or one-pager
├── prd/                          # one PRD per feature: <feature-slug>.md — nothing else at this level
│   └── reviews/                  # <stem>-review-log.md, prd-cross-review-YYYY-MM-DD.md
├── quick-specs/                  # <kebab-title>-YYYY-MM-DD.md
├── ux/                           # UX specs <slug>.md, app-shell.md, interaction-patterns.md
│   └── reviews/                  # <spec-stem>-ux-review-YYYY-MM-DD.md
├── brand/                        # design-language.md, tokens.json, voice-and-tone.md
├── content/                      # copy decks <area>.md, help-center/<slug>.md
├── inventory/                    # screen-inventory.md, media-manifest.md
├── registry/entities.yaml        # glossary & business-fact registry
└── accessibility-requirements.md
```

**Review logs live in `<doc-dir>/reviews/`** — next to the document they review, never beside it. That is why the top
level of `design/prd/` holds PRDs only: every file matching `design/prd/*.md` is a PRD, so the tools that scan PRDs
need no exclusion list.

## Product (`design/product/`)

| File | Written by | Template |
|------|-----------|----------|
| `product-brief.md` | `/brainstorm` (standard/full) | `.claude/docs/templates/product-brief.md` |
| `one-pager.md` | `/brainstorm` (minimal) | `.claude/docs/templates/one-pager.md` |
| `feature-map.md` | `/map-features`; `/write-prd` and `/prd-review` update row status | `.claude/docs/templates/feature-map.md` |
| `user-journey.md` | `/ux-design journey` | `.claude/docs/templates/user-journey.md` |
| `tracking-plan.md` | `/write-prd` (creates, appends events); `/team-growth` (experiments) | `.claude/docs/templates/tracking-plan.md` |
| `pricing-model.md` | `/write-prd` (when a PRD defines plans, prices, credits or promotions) | `.claude/docs/templates/pricing-model.md` |
| `personas/<slug>.md`, `pitch.md` | `/brainstorm` | `persona.md`, `pitch-document.md` |

Review the brief with `/prd-review design/product/product-brief.md`.

## PRDs (`design/prd/`)

One PRD per feature, named after the feature slug (`design/prd/goals.md` — kebab-case, no `-prd` suffix). The slug is
also the feature-map `Feature` value, the `TR-goals-NNN` prefix and the `workflow_overrides.feature_overrides` key.
Author with `/write-prd <feature>`; the template is `.claude/docs/templates/prd.md`.

The header block and `## Summary` (with its `> **Quick reference**` line) come first, then the eleven contract
sections, in order:

1. `## Overview` — what and why, one paragraph
2. `## Goals & Non-Goals` — goals tied to the brief; an explicit out-of-scope list
3. `## User Value` — persona, job-to-be-done, user stories, success moment
4. `## Functional Requirements` — `### Core Rules`, `### User Flows & States`, `### Interactions with Other Features`
5. `## Business Rules & Calculations` — every price, fee, limit, quota, eligibility threshold, time window and rounding
   rule, with variables, units, rounding and a worked example
6. `## Edge Cases` — exact outcomes, including network loss, partial failure, concurrency and retries
7. `## Dependencies` — the table `| Feature | PRD | Direction | Nature |`, bidirectional, plus `### External Services`
8. `## Non-Functional Requirements` — performance, availability, security & privacy, accessibility, localization
9. `## Configuration & Flags` — feature flags (key, default, owner, removal date), config values and limits
10. `## Success Metrics & Instrumentation` — metrics with baseline and target; events for the tracking plan
11. `## Acceptance Criteria` — testable Given/When/Then

Optional and never checked: `## UI Requirements`, `## API & Data Impact`, `## Open Questions`.

**How many are required depends on the workflow tier** (the feature's
`workflow_overrides.feature_overrides.<slug>` value when set, else `modes.workflow`):

- `full` — all eleven.
- `standard` — eight: Overview, Goals & Non-Goals, Functional Requirements, Edge Cases, Dependencies,
  Non-Functional Requirements, Success Metrics & Instrumentation, Acceptance Criteria — plus Business Rules &
  Calculations whenever the feature defines a numeric or policy rule. User Value and Configuration & Flags are
  advisory.
- `minimal` — none: `design/product/one-pager.md` is the design record.

Resolve the tier before flagging a section as missing — see `.claude/docs/workflow-modes.md`. The same list and rule
are stated in `.claude/rules/prd-docs.md`, `.claude/docs/coding-standards.md`, `.claude/docs/workflow-modes.md` and the
commit hook; this file is the copy a session working in `design/` reads first, so it must agree with them.

**Feature map**: `design/product/feature-map.md` — `/write-prd` moves the feature's row from `Not Started` to
`Drafting` when the skeleton is created and to `In Review` when authoring is done; after an APPROVED verdict
`/prd-review` offers to set `Approved` on this row and on the PRD's `> **Status**:` line, asking first.

**Registry**: `design/registry/entities.yaml` holds the domain terms, plans, rules, constants and events that more
than one PRD uses. Read it before naming or quantifying something; never delete an entry (`status: deprecated`).

**Build order**: Foundation → Core → Feature → Presentation, MVP tier first (the feature map's PRD Authoring Order).

**Validation**: run `/prd-review design/prd/<feature>.md` in a fresh session after authoring each PRD, and
`/review-all-prds` once a set of related PRDs is written. `/consistency-check` compares PRDs against the registry.
After a PRD is Approved, change it through `/propagate-prd-change`.

## Quick Specs (`design/quick-specs/`)

Lightweight specs for a config change, a behaviour tweak or a small enhancement, each with a rollout note. Author with
`/quick-spec`.

## UX (`design/ux/`)

- Screen and flow specs: `design/ux/<slug>.md`
- App shell (navigation, global regions and states): `design/ux/app-shell.md`
- Interaction pattern library: `design/ux/interaction-patterns.md`
- Accessibility requirements: `design/accessibility-requirements.md`

Author with `/ux-design`. Validate with `/ux-review` before implementation with `/team-ui`.

> **Accessibility requirements sit outside `design/ux/` on purpose.** They are a project-wide standard every screen
> spec consults, not a spec for one screen, and they must not count toward the number of UX specs a gate looks for.
> The workflow catalog, the phase gates and `/architecture-review` check `design/accessibility-requirements.md` at that
> exact path. Do not move it under `design/ux/` — every one of those checks would stop matching. `/ux-design` states
> the same rule in its `accessibility` mode.

## Brand, Content and Inventory

- `design/brand/design-language.md` (and optional `tokens.json`) — author with `/design-language`.
- `design/brand/voice-and-tone.md` and copy decks under `design/content/` — author with `/team-content`. Voice has one
  source of truth: the design language points to the voice-and-tone file rather than restating it.
- `design/inventory/screen-inventory.md` and `media-manifest.md` — author with `/ui-inventory`.

## Citations

Cite another file by its path and heading (`.claude/docs/workflow-modes.md` § PRD Required Sections per Tier), never
by line number — line numbers go stale with the next edit.
