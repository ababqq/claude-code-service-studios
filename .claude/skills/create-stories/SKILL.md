---
name: create-stories
description: "Break one epic into stories embedding TR-ID, ADR guidance, API contract, migration, flag and acceptance criteria."
argument-hint: "[epic-slug | epic-path] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/create-stories/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,docs.density,story_granularity,feature_overrides,testing.strict,code_roots`

Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).


# Create Stories

A story is a single implementable behaviour — small enough to complete in one
focused session, self-contained, and fully traceable to a PRD requirement, an ADR
decision and, where it touches them, the API operation, migration plan, feature
flag and analytics events it ships with. Stories are what engineers pick up. Epics
are what architects define.

**Run this skill per epic**, not per layer. Run it for Foundation epics first,
then Core, and so on — matching the dependency order.

**Output:** `production/epics/<epic-slug>/story-NNN-<slug>.md` files — directly
inside the epic directory, so the catalog's `production/epics/*/story-*.md` glob
finds them (an `EPIC.md` alone never counts as a story).

**Previous step:** `/create-epics layer: <layer>`
**Next step after stories exist:** `/story-readiness [story-path]` then `/dev-story [story-path]`

---

## 1. Parse Argument


See `.claude/docs/director-gates.md` for the full check pattern. Individual gate definitions live in `.claude/docs/director-gates/<gate-id>.md` — the spawned agent reads its own gate file; do not read it in the parent session.


**`workflow`** for this epic's feature (per `.claude/docs/workflow-modes.md`) —
use the `feature_overrides` row for `<feature>` if the block lists one, else the
project value. `<feature>` is the PRD stem named in the epic's `> **PRD**:` field
(`design/prd/goals.md` → `goals`). When the epic's module serves several PRDs,
use the highest tier among their rows — a feature pinned higher keeps its higher
bar. The tier sets which prerequisites block — see the note in Step 2.

**`story_granularity`** — it sets each story's AC load: **5–10 ACs covering a
whole feature** at `coarse`, **2–4 ACs covering one task** at `balanced`, **1 AC**
at `fine` (the story name is the AC restatement). Group or split ACs into stories
to hit the target. When nothing sets it, `modes.rigor` supplies it (`minimal` →
`coarse`).

**`docs.density`** — it controls the *depth* of each story's prose (context,
implementation notes, ADR summary), not the AC count (that is
`story_granularity`) and never the AC text itself. `modes.rigor` sets it
alongside `workflow`; set `docs.density` explicitly to vary story prose alone:
`terse` = notes as bullets, no preamble; `balanced` = short context paragraph +
notes; `thorough` = full context, implementation guidance, and ADR rationale. The
embedded TR-ID reference, ADR Version stamp, the `**API Contract**`,
`**Migration**`, `**Feature Flag**` and `**Analytics Events**` fields, and the
acceptance criteria are structural and are never trimmed by density.

**`code_roots`** — used only for the story's `**Stack Notes**`: when the layer the
story's primary Surface maps to (`.claude/docs/code-root-resolution.md` § "Surfaces
and roots") lists several roots on the `code_roots` line, name the one the story
targets there — `/dev-story` asks when neither the note nor the file list names it.
One root, or `code_roots: unresolved — …`, adds nothing to the note.

- `/create-stories [epic-slug]` — e.g. `/create-stories goals-core`
- `/create-stories production/epics/goals-core/EPIC.md` — full path also accepted
- No argument — at `minimal` there are no epics yet (Option A): skip to Step 2's
  `minimal` branch and synthesize the epic from `design/product/one-pager.md`. At
  `standard`/`full`, ask "Which epic would you like to break into stories?" and
  Glob `production/epics/*/EPIC.md` to list available epics with their status.

  > **If that glob returns nothing at `standard`/`full`, stop — do not build a
  > question with no options.** Report:
  > "No epics found under `production/epics/`. Run `/create-epics layer: foundation`
  > first — an epic is what this skill decomposes." The run ends with
  > **Verdict: NOT ASSESSED** — no story files written.
  >
  > **The zero-epic path is load-bearing.** Asking which epic *and* globbing to
  > list them leaves an `AskUserQuestion` with nothing to offer when the glob is
  > empty. Route to `/create-epics` instead — it is named as **Previous step**
  > in this skill's own header.
  >
  > Note what this skill guarded and what it did not. Step 2's ADR validation is
  > thorough: three tiers, each with its own stop condition, and an explicit
  > message naming the missing file. That is the **deepest** input. The **first**
  > input — does an epic exist at all — went unchecked. Guarding the far end of a
  > chain while leaving the near end open is the shape to watch for.
  >
  > At `minimal` this does not apply: there are deliberately no epics, and the
  > branch above synthesizes one from the one-pager.

---

## 2. Load Everything for This Epic

> **`minimal` tier — synthesize the epic from the one-pager** (Option A). At
> `minimal` there is no `/create-epics` step and no `EPIC.md`. Instead:
> 1. Read `design/product/one-pager.md` in full (it is one page). If it is absent,
>    report "No `design/product/one-pager.md` — run `/brainstorm` first" and stop
>    with **Verdict: NOT ASSESSED** — no story files written.
> 2. Synthesize an implicit epic: write a lightweight
>    `production/epics/<slug>/EPIC.md` (ask "May I write this to
>    `production/epics/<slug>/EPIC.md`?"), where `<slug>` is the product name from
>    the one-pager's title, slugified (`mvp` if untitled) — goal = its `## Pitch`,
>    scope = its `## Scope & Non-Goals`, ordering = its `## Build Order`. Keep it
>    terse; this is the container `/dev-story` and `/sprint-status` expect.
> 3. Generate **one coarse story per `## Build Order` item** (Step 3+), in Build
>    Order sequence, each traced to the one-pager (not a PRD/TR-ID). Leave stories
>    unblocked on ADR grounds — none exist at this tier.
> Skip the PRD, control-manifest, TR-registry, and ADR reads below (none exist at
> `minimal`), then continue to Step 3 with the synthesized epic. Read
> `docs/stack-reference/VERSION.md`, and `docs/api/` or `docs/data/migrations/`
> when they exist — the mapping in Step 6 uses them.

For `standard`/`full` (a `/create-epics` epic exists), read in full (these are small):

- `production/epics/<epic-slug>/EPIC.md` — epic overview, governing ADRs, PRD
  requirements, non-functional requirements, API operations, owned entities,
  rollout & flags, stack risk
- The epic's PRD (`design/prd/<feature-slug>.md`) — at `full` read all 11
  sections; at `standard` the 8 required sections (+ conditional
  `## Business Rules & Calculations`); at `minimal` the PRD may not exist — work
  from the epic + acceptance criteria. Always prioritise `## Acceptance Criteria`,
  `## Business Rules & Calculations`, `## Edge Cases`,
  `## Non-Functional Requirements`, `## Configuration & Flags` and
  `## Success Metrics & Instrumentation` where present.
- `docs/architecture/control-manifest.md` — grep only this epic's layer (`Grep pattern="^## <Layer> Layer Rules" path="docs/architecture/control-manifest.md" output_mode="content" -A 40`) plus the header Manifest Version date, not a full read of all layers
- `docs/architecture/tr-registry.yaml` — grep only this feature's entries (`Grep pattern="id: TR-<feature-slug>-" path="docs/architecture/tr-registry.yaml" output_mode="content" -A 8`), not the whole cross-feature registry
- The operations named in the epic's `## API Operations` — grep each in the
  contract it cites (`docs/api/openapi.yaml`, or the GraphQL / proto / AsyncAPI
  file) to confirm it exists and to take its exact contract reference
- The migration plans named in the epic's `## Owned Entities` — their `## Change`
  and `## Status` sections
- `design/product/tracking-plan.md` — the `## Events` rows whose Owner PRD is this
  epic's PRD
- `design/ux/*.md` — the UX specs of the screens and flows this epic's UI work
  implements (Glob, then read the relevant ones' states, `## API Data` and
  `> **Design Source**:` header line — the story's `Design reference:` line is
  copied from it)
- `docs/stack-reference/VERSION.md` — pinned components and Knowledge Risk (the
  story's `**Stack**` and `**Risk**` when the ADR is silent)
- `project.yaml` — `testing.patterns` (read with Read; it has no `resolve_config`
  label) to name each story's test path the way this stack lays tests out

**Load each governing ADR by section — never with an unbounded full read.** A
substantial ADR exceeds the 25k-token `Read` cap, and a capped read's only
recovery is paging through the remainder — the most expensive possible way to
read a file (measured at 103k tokens on a 34k-token ADR vs ~54k for targeted
reads of the same file). Per ADR:

1. **Map the headings** (cheap — line numbers only):
   ```
   Grep pattern="^## |^### Implementation Guidelines" path="docs/architecture/[adr-file].md" output_mode="content" -n
   ```
2. **Bounded-read exactly the sections this skill consumes**, using the line
   numbers from the map to set `Read(offset, limit)` spans that end where the
   next section begins:
   - `## Summary` and `## Decision` (including its `### Implementation
     Guidelines` subsection) — these feed the story's ADR Decision Summary
     and Implementation Notes.
   - `## Stack Compatibility` — feeds the story's Stack, Risk, and Stack
     Notes fields. (Stack Notes is a *story* field derived from this
     section — it is not an ADR section name; do not search for one.)
3. **Capture the `## Last Verified` date**:
   ```
   Grep pattern="^## (Last Verified|Date)" path="docs/architecture/[adr-file].md" output_mode="content" -A 1
   ```
   Use `Last Verified`, falling back to `Date`, then to `unversioned` if both
   are absent. This becomes the story's `ADR Version` stamp — `/dev-story`
   uses it to decide whether it can trust this story's distilled summary
   instead of re-opening the ADR.

Skip Context, Alternatives Considered, Consequences, Risks, and any
Amendments Log unless a section you loaded explicitly cross-references one of
their entries — then take only the referenced entry with one more bounded
read. If the heading map comes back empty (a nonstandard ADR predating the
template), fall back to one full `Read` — and if that read truncates at the
cap, do **not** page through the remainder; grep for the story-relevant
content directly and flag the ADR for `/architecture-decision retrofit [file]`.

**ADR existence validation** (tier-gated — resolved in Step 1): After reading the governing ADRs list from the epic, confirm each referenced ADR file exists on disk.

- **`full`** — if **any** referenced ADR file cannot be found, **stop immediately** before decomposing any story.
- **`standard`** — stop only if a **critical (Foundation-layer) ADR** is missing; for a missing non-critical ADR, **warn and continue** (the story embeds the ADR reference and is set `> **Status**: Blocked` until the ADR exists).
- **`minimal`** — no ADR requirement; do **not** stop. Embed any ADR references that do exist; otherwise decompose against the one-pager + acceptance criteria and leave stories unblocked on ADR grounds.

When stopping (full / standard-critical):

> "Epic references [ADR-NNNN: title] but `docs/architecture/[adr-file].md` was not found.
> Check the filename in the epic's Governing ADRs list, or run `/architecture-decision`
> to create it. Cannot create stories until all referenced ADR files are present."

Either stop ends the run with **Verdict: NOT ASSESSED** — no story files written.
At `full`, do not proceed to Step 3 until all referenced ADR files are confirmed present.

Report: "Loaded epic [name], PRD [path], [N] governing ADRs [ADR status], [manifest status], API contract [path | none], [K] migration plans." State the **actual** situation for the resolved tier — e.g. "all confirmed present, control manifest v[date]" at full; "M present, K missing non-critical (embedded + Blocked)" at standard; "no ADRs / manifest required" at minimal. Do not assert "all confirmed present" if any referenced ADR was missing, or name a manifest version when none exists.

---

## 3. Classify Stories by Type

**Story Type Classification** — assign each story a type based on its acceptance criteria:

| Story Type | Assign when criteria reference... |
|---|---|
| **Logic** | Domain rules, calculations, validators, state machines — the PRD's `## Business Rules & Calculations` (fees, limits, rounding, eligibility, schedules) |
| **Integration** | An API handler with its database, queue consumers, third-party adapters (payment provider, social login, push), **contract tests** against `docs/api/` |
| **UI** | Screens, components, visual states (loading, empty, error, offline), forms and validation messages, visual regression |
| **E2E** | The journey-closing story of an epic: its acceptance criteria are a full critical user journey named in `docs/ops/slo.md` `## Critical User Journeys` (or `design/product/user-journey.md`), across UI → API → database |
| **Config** | Feature flags, environment config, pricing and limit tables — no new code logic |

Mixed stories: assign the type that carries the highest implementation risk.
The type determines what test evidence is required before `/story-done` can close the story.

**Surface** — assign each story its `**Surface**` from what it changes: `web`,
`ios`, `android`, `mobile` (one cross-platform story for both apps, when
`docs/stack-reference/VERSION.md` pins React Native or Flutter), `api`, `admin`,
`infra` or `analytics`. A comma list is allowed; the first value is the primary
one, and `/dev-story` routes the story by it.

---

## 4. Decompose the PRD into Stories

For each PRD acceptance criterion:

1. Group related criteria that require the same core implementation
2. Each group = one story
3. Order stories contract-first: data and migrations, then the API operations
   (Integration/Logic), then the UI per surface — web and mobile can proceed in
   parallel once the operation they call exists — then edge cases, and the E2E
   journey-closing story last

**Story sizing rule:** size each story to the resolved `modes.story_granularity`
target (above). The "~2-4 hours / one focused session" heuristic is the
`balanced` target — at `coarse` a story spans a whole feature (5–10 ACs,
multi-day), at `fine` a story is a single AC. Split or group criteria to hit the
resolved target, not a fixed session length.

For each story, determine:
- **PRD requirement**: which acceptance criterion(ia) does this satisfy?
- **TR-ID**: look up in `tr-registry.yaml`. Use the stable ID of an entry with `status: active`; for a `status: "superseded-by: TR-<feature>-NNN"` entry use the ID it names, and never embed a `deprecated` one (`/story-readiness` flags both as NEEDS WORK). If no match, use `TR-[feature-slug]-???` and warn.
- **Governing ADR**: which ADR governs how to implement this?
  - `Status: Accepted` → embed normally
  - `Status: Proposed` → set story `> **Status**: Blocked` with note: "BLOCKED: ADR-NNNN is Proposed — run `/architecture-decision` to advance it"
  - **Multiple ADRs apply**: List all governing ADRs in the story's `**ADR Governing Implementation**:` field. Designate the one most directly controlling the implementation pattern as primary (first in the list). Others are listed as secondary references.
  - **No ADR applies at all**: Write `ADR: N/A — [brief reason, e.g. "pure flag configuration, no architectural pattern required"]` in the story's ADR field. Do NOT leave the field blank — a blank ADR field means "not checked", not "not applicable".
- **Story Type** and **Surface**: from Step 3
- **Stack risk**: from the ADR's `**Knowledge Risk**` row
- **API Contract**: the operation the story implements or calls, as a contract
  reference (`docs/api/openapi.yaml#/paths/~1v1~1goals/post`), or `None` when it
  calls no API. An operation the story needs that is not in the contract →
  `> **Status**: Blocked` with "BLOCKED: operation [name] is not in the API
  contract — run `/api-design update <resource>`".
- **Migration**: the plan the story implements (`docs/data/migrations/NNNN-<slug>.md`)
  or `None`. A story that changes stored data shape with no plan →
  `> **Status**: Blocked` with "BLOCKED: schema change without a migration plan —
  run `/data-model migration <slug>`".
- **Feature Flag**: the flag key from the PRD's `## Configuration & Flags` (e.g.
  `goals.v2-progress-ring`) when the behaviour ships behind one, else `None`.
- **Analytics Events**: the tracking-plan events the story must emit (e.g.
  `goal_created`), else `None`. An event the PRD names that is missing from
  `design/product/tracking-plan.md` is a warning: run `/write-prd` to append it.
- **ML**: `yes` only for a story that implements an ML/LLM capability; omit the
  field otherwise.

---

## 5. Present Stories for Review

Before writing any files, present the full story list:

```
## Stories for Epic: [name]

Story 001: [title] — Integration — api — ADR-NNNN
  Covers: TR-[feature-slug]-001 ([1-line summary of requirement])
  API: POST /v1/goals · Migration: docs/data/migrations/NNNN-[slug].md · Flag: None
  Test required: [integration or contract test path, per testing.patterns]

Story 002: [title] — Logic — api — ADR-MMMM
  Covers: TR-[feature-slug]-002, TR-[feature-slug]-003
  Test required: [unit test path, per testing.patterns]

Story 003: [title] — UI — web, mobile — ADR-NNNN
  Covers: TR-[feature-slug]-004 · Flag: goals.v2-progress-ring · Events: goal_viewed
  Evidence required: production/qa/evidence/[story-slug]/ (component test and/or each state)

Story 004: [title] — E2E — web — journey "[journey name]"
  Covers: TR-[feature-slug]-001..004
  Test required: tests/e2e/[journey]/ + production/qa/evidence/[story-slug]/

[N stories total: N Logic, N Integration, N UI, N E2E, N Config · K Blocked]
```

Use `AskUserQuestion`:
- Prompt: "May I write these [N] stories to `production/epics/<epic-slug>/`?"
- Options: `[A] Yes — write all [N] stories` / `[B] Not yet — I want to review or adjust first`

---

## 6. Write Story Files

For each story, write `production/epics/<epic-slug>/story-NNN-<slug>.md`. Number
from the highest existing `story-NNN` in the directory + 1 — never reuse a number.

> **At `minimal` tier the traceability inputs do not exist** (no PRD, ADR,
> TR registry, or control manifest). Fill the template from the one-pager instead —
> apply this mapping exactly, so every run is deterministic rather than improvised:
> - **PRD** → `design/product/one-pager.md`
> - **Requirement** → `Build Order item N` (the item this story implements — NOT a `TR-[feature-slug]-NNN` ID)
> - **ADR Governing Implementation / ADR Decision Summary / ADR Version** → `N/A (minimal — no ADRs)`
> - **Manifest Version** and **Control Manifest Rules (this layer)** → `N/A (minimal — no control manifest)`
> - **Stack** and **Risk** → read `docs/stack-reference/VERSION.md`. **Stack** is the
>   pinned component + version of the layer the story's primary Surface runs on.
>   **Risk** is the Knowledge Risk that file assigns that component. If the file is
>   missing or assigns no level, write `NOT ASSESSED (no VERSION.md risk rating)` —
>   never guess a level.
>
>   > **This field is load-bearing and had no rule, so it was improvised.**
>   > `/dev-story` spawns the stack specialist as a mandatory secondary reviewer
>   > when the story's stack risk is HIGH (from the ADR or VERSION.md). At
>   > `minimal` there is no ADR, so `VERSION.md` is the *only* source — and nothing
>   > here told this skill to read it. A story written with an invented
>   > `Risk: MEDIUM` against a `VERSION.md` rating of HIGH silently disables the
>   > specialist review — the one check that catches a framework API or default
>   > that changed after the model's training cutoff. Treat `NOT ASSESSED` as HIGH
>   > for the spawn decision: an unknown risk is not a low one.
> - **Stack Notes** → `none (no ADR stack-compatibility analysis at minimal)`, followed by the target root when the `code_roots` rule in Step 1 applies
> - **API Contract** → the operation reference when `docs/api/` holds a contract that has it, else `None`
> - **Migration** → the plan path when `docs/data/migrations/` has one for this item, else `None`
> - **Feature Flag** → the flag key when the one-pager names one, else `None`
> - **Analytics Events** → the event the one-pager's `## Success Signal` names, else `None`
> - **UX spec** and **Design reference** (`## Implementation Notes`) → filled exactly as at every other tier: the UX spec in `design/ux/` that backs this item and the reference copied from its `> **Design Source**:` line; with no such UX spec, or a spec without that line, write `Design reference: NOT CHECKED — <reason>` — never `none`, which is a recorded choice, not a default
> - The Acceptance-Criteria source line → "From `design/product/one-pager.md` (the **`## Core User Journey`** and **`## Success Signal`** sections + the Build Order item this story implements), scoped to this story" — derive concrete, testable ACs from what the user wrote there rather than inventing them from a bare Build Order line
> - The **`## QA Test Cases`** section → on any run where the QL-STORY-READY / qa-lead gate is skipped (`lean`/`solo` review mode — the `minimal` rigor default resolves to `solo`) no qa-lead specs are authored; write the skip note as its first line and "*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*" rather than improvising test cases.
> - Any **Test Evidence / DoD** line is governed by `qa.level`, not this template — at `qa.level: minimal` it is **waived** (advisory, never "must exist and pass"). The migration floor is the exception: it applies at every `qa.level`.

```markdown
# Story NNN: [title]

> **Epic**: [epic name]
> **Status**: Ready
> **Layer**: [Foundation / Core / Feature / Presentation]
> **Type**: [Logic | Integration | UI | E2E | Config]
> **Surface**: [web | ios | android | mobile | api | admin | infra | analytics] (comma list allowed; first = primary)
> **Estimate**: [hours or t-shirt size]
> **Manifest Version**: [date from control-manifest.md header]
> **Last Updated**: [set by /dev-story when implementation begins]

**PRD**: `design/prd/[feature-slug].md`
**Requirement**: `TR-[feature-slug]-NNN`
**ADR Governing Implementation**: [ADR-NNNN: title]
**ADR Decision Summary**: [1-2 sentences]
**ADR Version**: [ADR `## Last Verified` date, else `## Date`, else `unversioned`]
**Stack**: [component + version] | **Risk**: [LOW / MEDIUM / HIGH]
**Stack Notes**: [from the ADR's Stack Compatibility section; target root when the layer has several]
**API Contract**: [`docs/api/openapi.yaml#/paths/...` or None]
**Migration**: [`docs/data/migrations/NNNN-slug.md` or None]
**Feature Flag**: [flag key or None]
**Analytics Events**: [event names from the tracking plan or None]
**ML**: [yes — only for stories implementing an ML/LLM capability; omit otherwise]

*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**Control Manifest Rules (this layer)**:
- Required: [relevant required pattern]
- Forbidden: [relevant forbidden pattern]
- Guardrail: [relevant performance or security guardrail]

---

## Acceptance Criteria

*From PRD `design/prd/[feature-slug].md` `## Acceptance Criteria`, scoped to this story:*

- [ ] [criterion 1 — Given / When / Then, directly from the PRD]
- [ ] [criterion 2]
- [ ] [NFR criterion — the budget this story must hold, from the PRD's `## Non-Functional Requirements` or `docs/ops/slo.md`, and the environment it is measured in (e.g. "`POST /v1/goals` p95 ≤ 300 ms on staging")]
- [ ] [analytics criterion when **Analytics Events** is not None — e.g. "emits `goal_created` with the properties the tracking plan lists"]

*NFR budget: [the budget above — or "No NFR impact — [reason]"]*

---

## Implementation Notes

*Derived from ADR-NNNN Implementation Guidelines:*

[Specific, actionable guidance from the ADR. Do not paraphrase in ways that
change meaning. This is what the engineer reads instead of the ADR.]

- UX spec: `design/ux/[screen-or-flow].md` — [the states this story implements] *(UI and E2E stories; write "N/A — no user-facing surface" otherwise)*
- Design reference: [none — markdown spec only | claude-design — <locator> · record `design/handoff/<slug>/HANDOFF.md` | figma — <node URL> · record `design/handoff/<slug>/HANDOFF.md`] — [the frames / screens for the states this story implements] *(UI and E2E stories; write "N/A — no user-facing surface" otherwise)*

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- [Story NNN+1]: [what it handles]

---

## QA Test Cases

[review line — see Step 6b]

*Written by qa-lead at story creation. The engineer implements against these — do not invent new test cases during implementation. (On runs where the QL-STORY-READY gate is skipped — `lean`/`solo` review mode — no qa-lead specs exist; see the mapping note above.)*

**[For Logic / Integration / E2E stories — automated test specs]:**

- **AC-1**: [criterion text]
  - Given: [precondition]
  - When: [action]
  - Then: [assertion]
  - Edge cases: [boundary values / failure states — network loss, duplicate request, expired session]

**[For UI stories — component test and manual verification steps]:**

- **AC-1**: [criterion text]
  - Setup: [how to reach the state — route, account, flag values]
  - Verify: [what to look for, per viewport or device]
  - Pass condition: [unambiguous pass description]

---

## Test Evidence

*Governed by `qa.level`: at `qa.level: minimal` the evidence below is **waived** (advisory, never "must exist and pass") — except the migration floor, which applies at every `qa.level`. Whether a missing item blocks `/story-done` is decided per type by `testing.strict` (`logic`, `integration`, `ui`, `e2e`, `config`).*

**Story Type**: [type]
**Required evidence**:
- Logic: unit test per `testing.patterns` (co-located with the code it tests) or under `tests/unit/[feature]/` — must exist and pass (`/story-done` checks that it EXISTS; pass/fail is established by `/gate-check` and `/smoke-check`, both later)
- Integration: integration or contract test under `tests/integration/[feature]/` or `tests/contract/[feature]/` (or per `testing.patterns`) — must pass
- UI: component test and/or retained screenshots of each state touched (desktop + mobile viewport, or device) in `production/qa/evidence/[story-slug]/`
- E2E: automated E2E test (Playwright / Cypress / Detox / Maestro) under `tests/e2e/[journey]/`, passing against a running environment, with its trace or screenshots in `production/qa/evidence/[story-slug]/`
- Config: smoke check pass (`production/qa/smoke-*.md`)
- Migration (any Type, when **Migration** is not None): `production/qa/evidence/[story-slug]/migration-dry-run.log` — Expand applied and rolled back on a disposable database; required at every `qa.level` and regardless of `testing.strict.config`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: [Story NNN-1 must be DONE, or "None"]
- Unlocks: [Story NNN+1, or "None"]
```

The `## QA Test Cases` review line depends on the resolved review mode: when
QL-STORY-READY is skipped, write the skip note and the N/A text now; in `full`
mode write `*Pending QL-STORY-READY — Step 6b fills this section.*` and let Step 6b
replace it with the recorded outcome and the specs.

`[story-slug]` in the evidence paths is the story file name without `.md`
(`story-001-create-goal`) — the `<story-slug>` of `.claude/docs/coding-standards.md`;
write the concrete path into each story.

The `Design reference:` line is copied from the `> **Design Source**:` line of the
UX spec named on the `UX spec:` line — its first token (`none`, `claude-design` or
`figma`) and its record path unchanged — then narrowed to the frames or screens of
the states this story implements. Copy the locator and the record path only, never
the text of a pasted handoff prompt. When the UX spec has no `> **Design Source**:`
line, write
`Design reference: NOT CHECKED — <spec> has no Design Source line (run /ux-design <slug>)`
— never `none`: `none` is a recorded choice, and an unrecorded source is not one.
The line is a bullet, not a header field; the story header contract is unchanged.

Omit the `**ML**:` line for every story that does not implement an ML/LLM
capability. Test file names follow the convention `testing.patterns` records
(`*.test.ts`, `*.spec.ts`, `test_*.py`, `*Test.kt` …); when it is unset, use the
`tests/` paths above and say so once in the Step 7 summary.

### Also update `production/epics/<epic-slug>/EPIC.md`

Replace the "Stories: Not yet created" line with a populated table (ask "May I
write this to `production/epics/<epic-slug>/EPIC.md`?"):

```markdown
## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [title] | Integration | Ready | ADR-NNNN |
| 002 | [title] | Logic | Ready | ADR-MMMM |
```

When the table already exists, add rows for the new stories only — never a second
row for a number already listed.

### Also update `production/epics/index.md`

Find the row in the index table matching this epic (by epic name or slug). Ask "May I write this to `production/epics/index.md`?", then update its `Stories` column from `Not yet created` to `[N] stories` (where N is the count now in the epic directory). If the index file does not exist, say so in one line — `Epics index not updated: production/epics/index.md absent` — and continue. Do not skip silently: the index is what a reader consults to learn which epics have stories, so an un-updated one keeps reporting `Not yet created` for work that now exists, and nothing else would ever reveal the gap.

---

## 6b. QA Lead Story Readiness Gate

QL-STORY-READY reviews a written story — its Context is the story path — so it runs
on the files Step 6 wrote, before any of them is offered for implementation.

**Review mode check** — apply before spawning QL-STORY-READY (`--review` overrides
the resolved `review_mode`):
- `full` → spawn as normal.
- `lean` → **skip every gate whose ID does not end in `-PHASE-GATE`**. Note: `[GATE-ID] skipped — Lean mode`
  QL-STORY-READY does not end in `-PHASE-GATE`, so lean skips it: record
  `[QL-STORY-READY] skipped — Lean mode`.
- `solo` → skip all gates. Note: `[GATE-ID] skipped — Solo mode`

When skipped, the skip note (`> [QL-STORY-READY] skipped — Lean mode`, or
`— Solo mode`) is the review line of each story's `## QA Test Cases` section —
Step 6 writes it there — and the section carries the N/A text of the mapping note.
Proceed to Step 7.

In `full` mode, spawn one `qa-lead` **per story** via `Agent`, in parallel — issue
every call before waiting for any result. Each prompt instructs the agent to read
`.claude/docs/director-gates/ql-story-ready.md` first (do not read it or paste it
yourself):

- Pass: story path · PRD path · resolved `testing.strict` line
- Fill: the story file path; the PRD path from the story's `**PRD**:` field (at
  `minimal`: `design/product/one-pager.md`); and the `testing.strict` line
  exactly as the block above printed it.
- Return: ask, in the same prompt, that an **ADEQUATE** reply also carries the
  story's test-case block (formats below) after its findings — one Given / When /
  Then per acceptance criterion for Logic, Integration and E2E stories, or
  component-test and manual verification steps for UI stories. A single call per
  story returns **both** the verdict and the specs — do not spawn `qa-lead` a
  second time to generate specs.

Parse the first line of each reply as `[QL-STORY-READY]: TOKEN`
(`QL-STORY-READY: TOKEN` without the brackets parses the same), and map the token
with the verdict classes of `.claude/docs/director-gates.md`
(`## Standard Verdict Format`):

- **APPROVE-class** (`ADEQUATE`) → embed the returned specs into the story's
  `## QA Test Cases` section.
- **CONCERNS-class** (`GAPS`) → present the gate's rewrites, then use
  `AskUserQuestion`: `Revise flagged items` / `Accept and proceed` /
  `Discuss further`. Revise → rewrite the flagged acceptance criteria as proposed
  (show the change, ask before writing) and re-run the gate for that story only.
  Accept → the story keeps its criteria and carries no specs until a later run
  reaches ADEQUATE: `*Test cases not yet defined — run /qa-plan to generate them.*`
- **REJECT-class** (`INADEQUATE`) → present the blockers. Untestable criteria cannot
  be implemented correctly: revise the story's acceptance criteria with the user and
  re-run the gate for it. If the user stops there, set that story's
  `> **Status**: Blocked` with "BLOCKED: QL-STORY-READY INADEQUATE — acceptance
  criteria must be revised before implementation" (ask before writing).
- A first line that does not parse, or names another gate, is not an approval —
  treat it as CONCERNS-class and say the verdict line was missing.

Across the epic, the strictest class wins for the run summary: one REJECT-class
story is reported as such even when every other story is ADEQUATE.

**Prefer an existing QA plan when one already covers a story** — this substitutes for the qa-lead's specs, it does not add a spawn. Glob `production/qa/qa-plan-*.md` for the most recent file; if it holds test specs for stories in this epic (match titles/slugs in its `## Automated Tests Required` section — the heading comes from `.claude/docs/templates/test-plan.md`) that differ from the qa-lead's, use `AskUserQuestion` (Use QA-plan specs / Use qa-lead specs / Skip and leave `*Test cases not yet defined — run /qa-plan to generate them.*`). Either way no additional `qa-lead` spawn occurs.

The spec block formats — Logic / Integration / E2E:

```
Test: [criterion text]
  Given: [precondition]
  When: [action]
  Then: [expected result / assertion]
  Edge cases: [boundary values or failure states to test]
```

For UI stories, produce component-test and manual verification steps instead:
```
Manual check: [criterion text]
  Setup: [how to reach the state — route, account, flag values, viewport or device]
  Verify: [what to look for]
  Pass condition: [unambiguous pass description]
```

**Record the outcome** as the review line at the top of each story's
`## QA Test Cases` section, together with the embedded specs — show the changes,
then ask "May I write this to `production/epics/<epic-slug>/story-NNN-<slug>.md`?"
(one approval may cover the whole set when the user prefers):

```markdown
> **QA Lead Review (QL-STORY-READY)**: APPROVED [date]
```

(`CONCERNS (accepted) [date]` when GAPS was accepted; `REVISED [date]` when a
revision was re-run to ADEQUATE.)

These test case specs are embedded directly into each story's `## QA Test Cases` section. The engineer implements against these cases. The engineer does not write tests from scratch — QA has already defined what "done" looks like.

---

## 7. After Writing

Use `AskUserQuestion` to close with context-aware next steps:

Check:
- Are there other epics in `production/epics/` without stories yet? List them.
- Is this the last epic? If so, include `/sprint-plan` as an option.
- Are any stories Blocked (Proposed ADR, operation missing from the contract,
  schema change without a plan, INADEQUATE criteria)? List them with the command
  that clears each.

Widget:
- Prompt: "[N] stories written to `production/epics/<epic-slug>/`. What next?"
- Options (include all that apply):
  - `[A] Start implementing — run /story-readiness [first-story-path]` (Recommended)
  - `[B] Create stories for [next-epic-slug] — run /create-stories [slug]` (only if other epics have no stories yet)
  - `[C] Plan the sprint — run /sprint-plan new` (only if all epics have stories)
  - `[D] Stop here for this session`

Note in output: "Work through stories in order — each story's `Depends on:` field tells you what must be DONE before you can start it."

---

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and
`autonomous` modes, see `.claude/docs/automation-modes.md` — the rules below
describe what collaborative mode requires, not universal behavior.

1. **Read before presenting** — load all inputs silently before showing the story list
2. **Ask once** — present all stories for the epic in one summary, not one at a time
3. **Warn on blocked stories** — flag any story with a Proposed ADR, an operation missing from the contract or a schema change without a migration plan before writing
4. **Ask before writing** — get approval for the full story set before writing files, and again before embedding gate results
5. **No invention** — acceptance criteria come from PRDs, implementation notes from ADRs, rules from the manifest, operations from the contract, events from the tracking plan
6. **Never start implementation** — this skill stops at the story file level

After writing, declining, or stopping on a missing input:

- **Verdict: COMPLETE** — [N] stories written to `production/epics/<epic-slug>/`. Run `/story-readiness` → `/dev-story` to begin implementation.
- **Verdict: BLOCKED** — user declined. No story files written.
- **Verdict: NOT ASSESSED** — a required input is missing (no epic under `production/epics/`, no `design/product/one-pager.md` at `minimal`, or a referenced ADR file missing — any at `full`, a critical (Foundation-layer) one at `standard`); no story files written. Name the missing input and the skill that creates it (`/create-epics`, `/brainstorm`, `/architecture-decision`).
