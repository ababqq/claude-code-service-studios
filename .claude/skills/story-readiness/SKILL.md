---
name: story-readiness
description: "Is a story implementation-ready? READY / NEEDS WORK / BLOCKED / NOT ASSESSED."
argument-hint: "[story-file-path | all | sprint] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, AskUserQuestion, Agent, Bash(bash "*/.claude/skills/story-readiness/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,qa.level,testing.strict,feature_overrides,design`

Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).


# Story Readiness

This skill validates that a story file contains everything an engineer needs
to begin implementation — no mid-sprint product or design interruptions, no
guessing, no ambiguous acceptance criteria, and no contract, migration or flag
decided on the fly. Run it before assigning a story.

**This skill is read-only.** It has no Write or Edit access and never edits story
files. It reports findings and asks whether the user wants help filling gaps; the
story file stays untouched unless the user approves a drafted fix and applies it.

**Output:** Verdict per story (READY / NEEDS WORK / BLOCKED / NOT ASSESSED) with a specific
gap list for each non-ready story.

> **`NOT ASSESSED` is not a synonym for `BLOCKED`.** `BLOCKED` is a
> finding about the story — a Proposed ADR, an unresolved dependency — and it
> tells the reader exactly what to clear. Use `NOT ASSESSED` when the story could
> not be evaluated at all: the file is unreadable or unparseable, or a referenced
> ADR or PRD cannot be located, so the checks below cannot run.
> Collapsing that into `BLOCKED` reports a blocker that does not exist and hides
> the one that does — the reader chases a phantom ADR instead of a missing file.
> `READY` must never be reachable for a story that was not actually evaluated.
>
> **Precedence — first matching rule wins**, in this order: **BLOCKED**, then
> **NEEDS WORK**, then **NOT ASSESSED**, then **READY**. `NOT ASSESSED` outranks
> `READY` (a story that could not be evaluated has not been shown ready) and
> ranks **below** both failure verdicts (a known blocker is more actionable than
> an unknown, and demoting it behind an access problem buries it). A story with
> both a real blocker and an unevaluable check is `BLOCKED` — the blocker is the
> actionable finding. This half of the rank has to be stated: the rule above
> establishes only that `READY` is unreachable, which would leave the ordering
> against `BLOCKED` to inference.

---

## Phase 0: Resolve Review Mode


See `.claude/docs/director-gates.md` for the full check pattern and mode definitions. Individual gate definitions live in `.claude/docs/director-gates/<gate-id>.md` — the spawned agent reads its own gate file; do not read it in the parent session.


**Resolve the workflow tier per story** (per `.claude/docs/workflow-modes.md`):
for the feature a story belongs to (**the PRD stem** of its `**PRD**:` path —
`design/prd/goals.md` → `goals`; the `[feature-slug]` segment of a
`TR-[feature-slug]-NNN` ID is a fallback alias only), use the `feature_overrides`
row for that feature if the block lists one, else the project value (also for a
quick-spec story whose `**PRD**:` reads `None — quick spec`). When
validating multiple stories (`all` / `sprint` scope), resolve **per story** —
different features may sit at different tiers. The tier sets which checklist
sections block — see the note in Section 3.

**`qa.level`**: controls whether a test requirement is
validated. At `minimal`, the "Test evidence requirement is clear" item
auto-passes (no requirement validated); at `standard`, validate the per-type test
requirement (strictness from `testing.strict`); at `full`, also validate a
coverage target. Distinct axis from `workflow`. The migration floor ignores
`qa.level` — see Definition of Done.

**`design`**: the `design.tool` line decides the design-reference half of the
**Design link present** item (Section 3). `claude-design` or `figma` → UI and E2E
stories also need a `Design reference:` line backed by a local handoff record.
`none` → the UX spec link alone passes
(`Design reference: none — markdown spec only` is the expected line).
**Unset is not `none`**: when the line reads
`design.tool: (unset -- ask; unset is not none)` and a UI or E2E story is in
scope, ask once per run with `AskUserQuestion` — "Which design tool does this
project use?" — options `claude-design` / `figma` / `none` / `Not decided`. The answer applies to this run
only (this skill writes nothing; the report says `design.tool unset — treated as
<answer> for this run; record it with /settings`). `Not decided`, or no answer,
leaves the sub-check unrun: print
`Design reference: NOT CHECKED — design.tool unset (record it with /settings)` on
each UI and E2E story, which then cannot be READY (it is at best NOT ASSESSED).

---

## 1. Parse Arguments

**Scope:** `$ARGUMENTS[0]` (blank = ask user via AskUserQuestion)

- **Specific path** (e.g., `/story-readiness production/epics/goals-core/story-001-create-goal.md`):
  validate that single story file.
- **`sprint`**: read the current sprint plan from `production/sprints/` (most
  recent file), extract every story path it references, validate each one.
- **`all`**: glob `production/epics/*/story-*.md` (story files only — `EPIC.md`
  and the index never match), validate every story file found.
- **No argument**: ask the user which scope to validate.

If no argument is given, use `AskUserQuestion`:
- "What would you like to validate?"
  - Options: "A specific story file", "All stories in the current sprint",
    "All stories in production/epics/", "Stories for a specific epic"

Report the scope before proceeding: "Validating [N] story files."

> **If the scope resolves to ZERO story files, stop and report
> `NOT ASSESSED — no stories in scope`.** Name which scope was searched and
> which path was empty (`production/epics/*/story-*.md`, the sprint file's story
> list, or the specific path given), and route: `/create-epics layer: <layer>` then
> `/create-stories [epic-slug]`.
>
> **The zero-scope path is mandatory.** Without it an empty glob falls through
> to the Section 5 aggregate template and renders `Ready: 0 /
> Needs Work: 0 / Blocked: 0` above an empty list — **indistinguishable from
> "I checked every story and none needed work"**. It is the core failure of this
> framework exactly: a scan that finds nothing because there was nothing to
> scan, reported the same way as a clean result. Three zeros read as a healthy
> sprint.
>
> Note what made this survive: `NOT ASSESSED` was already in this skill's
> vocabulary, but the body scoped it to **per-story** evaluation failures (an
> unreadable or unparseable file, a missing referenced ADR). The verdict existed;
> the case that most needs it had no route to it. It is a recurring shape — a
> correct fix that did not reach one surface.
>
> **A zero-story sprint scope is not the same as an absent sprint file.** If
> `production/sprints/` has no file at all, say that instead — "no sprint plan
> found" and "the sprint plan lists no stories" send the reader to different
> fixes, and Section 7 already draws that distinction for the handoff block.

---

## 2. Load Supporting Context

Before checking any stories, load reference documents once (not per-story):

- `design/product/feature-map.md` — to know which features have Approved PRDs
  (its `Status` and `PRD` columns)
- `docs/architecture/control-manifest.md` — story-readiness needs only the header
  `Manifest Version:` date (its manifest check is existence + version, not the rule
  bodies), so grep it (`Grep pattern="Manifest Version" path="docs/architecture/control-manifest.md"`)
  rather than a full read. If the file does not exist, note it as missing once; do not
  re-flag per story.
- `docs/architecture/tr-registry.yaml` — index all entries by `id`. Used to
  validate TR-IDs in stories. If the file does not exist, note it once; TR-ID
  checks will auto-pass for all stories (registry predates stories, so missing
  registry means stories are from before TR tracking was introduced).
- All ADR status fields — resolve these with **one scan, not one read per ADR**.
  A `Status:` value is a single line; reading whole ADR files to find it costs the
  entire architecture corpus, and in `all` scope that multiplies across every
  story in the repo:
  ```
  Grep pattern="^## Status" glob="docs/architecture/adr-*.md" output_mode="content" -A 3
  ```
  Establish the denominator first (glob `docs/architecture/adr-*.md`, count **N**)
  and interpret against it: **0 matches with N > 0 means malformed ADRs, not
  "no Accepted ADRs"** — report "run `/architecture-decision retrofit [file]`"
  rather than failing every story's ADR check. Never treat an unreadable status as
  a failed one. Cache the resulting map; do not re-scan per story.
- The API contract files present — Glob `docs/api/openapi*.yaml`,
  `docs/api/schema.graphql`, `docs/api/*.proto`, `docs/api/asyncapi.yaml` once;
  per story, grep only the operation it references.
- `docs/data/migrations/*.md` — Glob once; per story, read only the plan it
  references (its `## Status` section).
- `design/product/tracking-plan.md` — the `## Events` table, once (if the file
  exists).
- `design/ux/*.md` — Glob once, to resolve the UX spec links of UI and E2E stories.
- `design/handoff/*/HANDOFF.md` — Glob once, to resolve the design-reference records
  UI and E2E stories name; per story, read only the record its `Design reference:`
  line names, and only its `> **Verdict**:` line
  (`Grep pattern="^> \*\*Verdict\*\*:" path="design/handoff/<slug>/HANDOFF.md" output_mode="content"`).
  Records are local files; a remote design URL (Figma, Claude Design, an artifact)
  is never fetched by this skill.
- `docs/stack-reference/VERSION.md` — the Knowledge Risk of each pinned
  component, to judge the Stack notes item.
- The current sprint file (if scope is `sprint`) — to identify Must Have /
  Should Have priority for escalation decisions

---

## 3. Story Readiness Checklist

For each story file, evaluate every item below. A story is READY only if all
items pass or are explicitly marked N/A with a stated reason.

> **Workflow tier adjustment** (resolved in Phase 0, per the story's feature). The
> full checklist below is the `full` baseline:
> - **`full`** — every item is blocking (TR registry + ADR + control manifest
>   fully validated).
> - **`standard`** — **Design Completeness** and **Scope Clarity** stay blocking.
>   In **Architecture Completeness**, only a **critical (Foundation-layer) ADR**
>   that is missing or `Proposed` BLOCKS; a missing non-critical ADR, or an absent
>   "ADR referenced" note, is **advisory** (NEEDS WORK note, not BLOCKED). The
>   TR-ID and manifest items are advisory. The **API Contract**, **Migration** and
>   **Feature Flag** items stay as written — the Validation → Build gate requires
>   those fields at `standard`.
> - **`minimal`** — **acceptance-criteria check only**: evaluate Design
>   Completeness and Scope Clarity. Treat the entire **Architecture Completeness**
>   section as N/A — do not flag missing ADR / TR-ID / manifest / contract / plan
>   references. The migration floor in Definition of Done still applies.

### Design Completeness

- [ ] **PRD requirement referenced**: The story includes a `design/prd/` path
  (its `**PRD**:` field — `design/product/one-pager.md` at `minimal`) and quotes or
  links a specific requirement, acceptance criterion, or business rule from that
  document — not just the filename. A link to the document without tracing to a
  specific requirement does not pass. A quick-spec Small Feature story carries
  `**PRD**: None — quick spec` and `**Requirement**: None — quick spec`; it passes
  this item when its body has a `Source spec: design/quick-specs/<file>.md` line
  (missing line → NEEDS WORK; fix: run `/quick-spec [description]` and add it).
- [ ] **Requirement is self-contained**: The acceptance criteria in the story
  are understandable without opening the PRD. An engineer should not need to
  read a separate document to understand what DONE means.
- [ ] **Acceptance criteria are testable**: Each criterion is a specific,
  observable condition — not "implement X" or "the feature works correctly".
  Bad example: "Implement goal creation." Good example: "Given a signed-in user
  with no goals, when they submit a goal of 1,000,000원 due in 12 months, then
  `POST /v1/goals` returns 201 and the goal list shows it at 0% progress."
- [ ] **No acceptance criteria require judgment calls**: Criteria like
  "feels fast", "looks clean" or "intuitive" are not testable without a defined
  benchmark and must be replaced with specific observable conditions for every
  story type. For UI stories, a visual criterion passes when it names the states
  to capture (e.g. empty, loading, error, filled — per viewport or device) and
  the evidence location `production/qa/evidence/<story-slug>/` (`<story-slug>` = the
  story file name without `.md`, as `.claude/docs/coding-standards.md` defines it).
  NEEDS WORK if the criterion is purely subjective with no state list or evidence
  path.
- [ ] **Design link present** *(UI and E2E stories; N/A when the story's
  `**Surface**` is only `api`, `infra` or `analytics`)*: The story cites the UX
  spec it implements (`design/ux/<slug>.md`, in Implementation Notes or the
  acceptance criteria) and that file exists. Missing link or missing file →
  NEEDS WORK. Fix: add the `UX spec:` line, or run `/ux-design [screen]` first.
  **Design reference** (same stories), by the `design.tool` resolved in Phase 0:
  - `claude-design` or `figma` → the story's `## Implementation Notes` also has a
    `Design reference:` line whose first token is `claude-design` or `figma` and
    which names a record `design/handoff/<slug>/HANDOFF.md` that exists, with
    `> **Verdict**: RETAINED` or `> **Verdict**: LINK ONLY`. Missing line, a line
    reading `none — …` or `NOT CHECKED — …`, a missing record, or a record whose
    verdict is `NOT ASSESSED` (or does not parse) → NEEDS WORK: an unverified
    design is never a match. Fix: `/design-handoff --for <slug>` when no record
    exists (then copy the UX spec's `> **Design Source**:` line into the story),
    `/design-handoff refresh <slug>` when the record is `NOT ASSESSED`.
  - `none` → the UX spec link alone passes;
    `Design reference: none — markdown spec only` is the expected line, and its
    absence on an older story is not a gap.
  - unset → as Phase 0 says: ask; never treat it as `none`. Unanswered →
    `Design reference: NOT CHECKED — design.tool unset (record it with /settings)`,
    and the story cannot be READY.
  Whatever `design.tool` says, a `Design reference:` line that names a record is
  checked the same way — a named record that is missing is a broken link.
- [ ] **Analytics events listed**: The `**Analytics Events**` field is present —
  event names or `None`. Each named event appears in
  `design/product/tracking-plan.md` `## Events`. An event missing from the plan,
  or events named while no tracking plan exists → NEEDS WORK. Fix: run
  `/write-prd` for the story's feature to append the event, or correct the name.

### Architecture Completeness

> The `BLOCKED` / fail outcomes in this section are the `full` baseline. Apply the
> tier note above: at `standard` only a missing/Proposed **critical** ADR BLOCKS
> (other ADR, TR-ID and manifest items advisory); at `minimal` treat this entire
> section as N/A.

- [ ] **ADR referenced or N/A stated**: The story references at least one ADR,
  OR explicitly states "No ADR applies" with a brief reason.
  A story with no ADR reference and no explicit N/A note fails this check.
- [ ] **ADR is Accepted (not Proposed)**: For each referenced ADR, check its
  `Status:` field using the cached ADR statuses loaded in Section 2.
  - If `Status: Accepted` → pass.
  - If `Status: Proposed` → **BLOCKED**: the ADR may change before it is accepted,
    and the story's implementation guidance could be wrong.
    Fix: `BLOCKED: ADR-NNNN is Proposed — wait for acceptance before implementing.`
  - If the ADR file does not exist → **BLOCKED**: referenced ADR is missing.
  - Auto-pass if story has an explicit "No ADR applies" N/A note.
- [ ] **TR-ID is valid and active**: If the story contains a `TR-[feature-slug]-NNN`
  reference, look it up in the TR registry loaded in Section 2.
  - If the ID exists and `status: active` → pass.
  - If the ID exists and `status: deprecated` or `status: "superseded-by: ..."` →
    NEEDS WORK: the requirement was removed or replaced.
    Fix: update the story to reference the current requirement ID or remove if no longer applicable.
  - If the ID does not exist in the registry → NEEDS WORK: ID was not registered
    (story may predate registry, or registry needs an `/architecture-review` run).
  - Auto-pass if the story has no TR-ID reference OR if the registry does not exist.
- [ ] **Manifest version is current**: If the story has a `Manifest Version:` date
  in its header AND `docs/architecture/control-manifest.md` exists:
  - If story version matches current manifest `Manifest Version:` → pass.
  - If story version is older than current manifest → NEEDS WORK: new rules may
    apply. Fix: review changed manifest rules, update story if any forbidden/required
    entries changed, then update the story's `Manifest Version:` to current.
  - Auto-pass if either the story has no `Manifest Version:` field OR the manifest
    does not exist.
- [ ] **Stack notes present**: For any stack component the story touches whose
  Knowledge Risk is MEDIUM or HIGH (from the ADR's `## Stack Compatibility` or
  `docs/stack-reference/VERSION.md`), `**Stack Notes**` carries implementation
  notes or a verification requirement for its post-cutoff APIs. `**Risk**` is
  present; `NOT ASSESSED (no VERSION.md risk rating)` is an acceptable value
  (downstream treats it as HIGH). If the story clearly touches no framework API
  (e.g. it is a pure flag or pricing-table change), "N/A — no stack API involved"
  is acceptable.
- [ ] **Control manifest rules noted**: Relevant layer rules from the control
  manifest are referenced, OR "N/A — manifest not yet created" is stated.
  This item auto-passes if `docs/architecture/control-manifest.md` does not
  exist yet (do not penalize stories written before the manifest was created).
- [ ] **API Contract referenced**: The `**API Contract**` field is present. A story
  that implements or calls an API operation names it as a contract reference
  (`docs/api/openapi.yaml#/paths/...`, or the GraphQL / proto / AsyncAPI
  equivalent); `None` is valid only when the story calls no API.
  - Field absent → NEEDS WORK.
  - Contract file exists but the operation is not in it → NEEDS WORK. Fix: run
    `/api-design update <resource>`, or correct the reference.
  - The referenced contract file does not exist → **BLOCKED**: the operation's
    shape is the implementation contract for every consumer.
- [ ] **Migration referenced**: The `**Migration**` field is present —
  `docs/data/migrations/NNNN-<slug>.md` or `None`. A story whose criteria or notes
  change stored data shape (new table or column, type change, backfill) must name
  a plan.
  - Field absent, or a schema-changing story with `None` → NEEDS WORK.
  - The referenced plan does not exist → **BLOCKED**. Fix: run
    `/data-model migration <slug>`.
  - The plan exists: note which phase the story implements (Expand, Migrate or
    Contract) and that phase's state in the plan's `## Status`.
- [ ] **Feature Flag declared**: The `**Feature Flag**` field is present — a flag
  key or `None`. A named key appears in the PRD's `## Configuration & Flags` with
  its default, owner and removal date; a behaviour the PRD puts behind a flag is
  not left at `None`. Otherwise → NEEDS WORK.

### Scope Clarity

- [ ] **Estimate present**: The story includes a size estimate (hours,
  points, or a t-shirt size). A story with no estimate cannot be planned.
- [ ] **Surface declared**: The story's `> **Surface**:` holds one or more of
  `web`, `ios`, `android`, `mobile`, `api`, `admin`, `infra`, `analytics`, primary
  first. `/dev-story` routes the story to an engineer by it, so a missing or
  unknown value → NEEDS WORK.
- [ ] **In-scope / Out-of-scope boundary stated**: The story states what
  it does NOT include, either in an explicit Out of Scope section or in
  language that makes the boundary unambiguous. Without this, scope creep
  during implementation is likely.
- [ ] **Story dependencies listed**: If this story depends on other stories
  being DONE first, those story IDs are listed. If there are no dependencies,
  "None" is explicitly stated (not just omitted).

### Open Questions

- [ ] **No unresolved design questions**: The story does not contain text
  flagged as "UNRESOLVED", "TBD", "TODO", "?", or equivalent markers in
  any acceptance criterion, implementation note, or rule statement.
- [ ] **Dependency stories are not Blocked**: For each story listed as a
  dependency, check that the file exists and that its `> **Status**:` is not
  `Blocked`. A story that depends on a Blocked or missing story is BLOCKED, not
  just NEEDS WORK.

### Asset References Check

- [ ] **Referenced assets exist**: Scan the story text for media and static-asset
  paths (paths under `design/inventory/`, `design/brand/`, `public/` or an
  `assets/` directory, or file extensions `.png`, `.jpg`, `.jpeg`, `.webp`,
  `.avif`, `.svg`, `.gif`, `.lottie`, `.woff2`, `.mp4`).
  - For each asset path found: use Glob to check whether the file exists.
  - If any referenced asset does not exist: **NEEDS WORK** — note the missing
    path(s). (The story references assets that have not been created yet.
    Either remove the reference, create a placeholder, or mark it as an
    explicit dependency on an asset story — `/ui-inventory media` lists them.)
  - If all referenced assets exist: note "Referenced assets verified:
    [count] found."
  - If no asset paths are referenced in the story: note "No asset references
    found in story — skipping asset check." This item auto-passes.
  - This is an existence-only check. Do not validate file format or content.

### Definition of Done

- [ ] **Minimum testable acceptance criteria by story type**:
  - Logic / Integration stories: at least 3
  - UI stories: at least 2
  - E2E stories: at least 2 (the critical journey end to end, plus one failure or
    recovery path)
  - Config stories: at least 1
  Apply the threshold matching the story's `Type:` field. If the story has fewer than the minimum, mark as NEEDS WORK.
- [ ] **NFR budget noted if applicable**: If this story touches a request path, a
  query, a background job, a screen's load or interaction, or the shipped bundle,
  it states the budget it must hold — p95 latency or error rate from
  `docs/ops/slo.md`, Core Web Vitals (LCP, INP, CLS), bundle size, or mobile cold
  start — taken from the PRD's `## Non-Functional Requirements`, with the
  environment it is measured in; or a "No NFR impact — [reason]" note is present.
- [ ] **Story Type declared**: The story includes a `Type:` field in its header
  identifying the test category (Logic / Integration / UI / E2E / Config).
  Without this, test evidence requirements cannot be enforced at story close.
  Fix: Add `> **Type**: [Logic | Integration | UI | E2E | Config]` to the story header.
- [ ] **Test evidence requirement is clear** *(auto-pass at `qa.level: minimal` — no
  test evidence is required, so this item never blocks)*: If the Story Type is set,
  the story includes a `## Test Evidence` section stating where evidence will be stored
  (test file path for Logic, Integration and E2E; evidence directory
  `production/qa/evidence/<story-slug>/` for UI and E2E; the smoke report for Config).
  Resolve this item's gate level from the `testing.strict` block **resolved in
  Phase 0** — not by reading `project.yaml`, which would ignore a developer's
  locally-overridden value. Map the Story Type to a key (Logic→`logic`,
  Integration→`integration`, UI→`ui`, E2E→`e2e`, Config→`config`) and take
  `testing.strict.<key>`; use it only if its value is `true` or `false`
  (case-insensitive). If the key is `unset` or holds any other value, default to
  strict for Logic, Integration, UI and E2E, and advisory for Config. Surface any
  unrecognized value to the user.
  - At a **strict** gate level, a missing `## Test Evidence` section marks the
    story **NEEDS WORK**.
  - At an **advisory** gate level, a missing section is listed as a gap but does
    not by itself downgrade the verdict from READY.
  Fix: Add `## Test Evidence` with the expected evidence location for the story's type.
- [ ] **Migration floor named** *(never auto-passed — applies at every `qa.level`
  and regardless of `testing.strict.config`)*: If the story's `**Migration**` is
  not `None` (any Type), its `## Test Evidence` names
  `production/qa/evidence/<story-slug>/migration-dry-run.log` — the Expand phase
  applied and rolled back on a disposable database — as required evidence. Absent →
  NEEDS WORK: `/story-done` treats a missing dry-run log as blocking.

---

## 4. Verdict Assignment

Assign one of four verdicts per story, using the precedence stated at the top
(BLOCKED, then NEEDS WORK, then NOT ASSESSED, then READY):

**READY** — All checklist items pass, have explicit N/A justifications, or are
advisory-level gaps (a checklist item whose gate level resolved to advisory via
`testing.strict`, or an item the resolved tier makes advisory). Advisory gaps are
still listed under Gaps in the output. The story can be assigned immediately.

**NEEDS WORK** — One or more checklist items fail, but all dependency stories
exist and are not Blocked. The story can be fixed before assignment.

**BLOCKED** — One or more dependency stories are missing or Blocked, a
referenced ADR is Proposed or missing, a referenced contract file or migration
plan does not exist, OR a critical design question (flagged UNRESOLVED in a
criterion or rule) has no owner. The story cannot be assigned until the blocker is
resolved. Note: a story that is BLOCKED may also have NEEDS WORK items — list both.

**NOT ASSESSED** — The story could not be evaluated: the file is unreadable or
unparseable, or its PRD cannot be located, so the checklist could not run — or,
for a UI or E2E story, `design.tool` is unset and was not answered, so the
design-reference check could not run. Name which input was missing.
(`**PRD**: None — quick spec` with a `Source spec:` line
is not a missing PRD — the quick spec is its source.)

In `full` review mode the QL-STORY-READY gate (Phase 8) runs on every READY or
NEEDS WORK story **before** the report is printed; its outcome can move a READY
story to NEEDS WORK, never the other way.

---

## 5. Output Format

This report is shown in the conversation; the skill writes no file.

### Single story output

```
## Story Readiness: [story title]

> **Verdict**: [READY / NEEDS WORK / BLOCKED / NOT ASSESSED]

File: [path]
QL-STORY-READY: [token, or "[QL-STORY-READY] skipped — Lean mode" / "— Solo mode", or "not run — story BLOCKED"]

### Passing Checks (N/[total])
[list passing items briefly]

### Gaps
- [Checklist item]: [exact description of what is missing or wrong]
  Fix: [specific text needed to resolve this gap]

### Blockers (if BLOCKED)
- [What is blocking]: [story ID, ADR, contract, migration plan or design question that must resolve first]
```

### Multiple story aggregate output

```
## Story Readiness Summary — [scope] — [date]

Ready:        [N] stories
Needs Work:   [N] stories
Blocked:      [N] stories
Not Assessed: [N] stories

### Ready Stories
- [story title] ([path])

### Needs Work
- [story title]: [primary gap — one line]
- [story title]: [primary gap — one line]

### Blocked Stories
- [story title]: Blocked by [story ID / ADR / contract / migration plan / design question]

### Not Assessed
- [story title]: [which input could not be read]

---
[Full detail for each non-ready story follows, using the single-story format]
```

### Sprint escalation

If the scope is `sprint` and any Must Have stories are NEEDS WORK, BLOCKED or
NOT ASSESSED, add a prominent warning at the top of the output:

```
WARNING: [N] Must Have stories are not implementation-ready.
[List them with their primary gap or blocker.]
Resolve these before the sprint begins or replan with `/sprint-plan update`.
```

---

## 6. Collaborative Protocol

This skill is read-only. It never writes or edits files — it has no Write or Edit
access.

After reporting findings, offer:

"Would you like help filling in the gaps for any of these stories? I can
draft the missing sections for your approval."

If the user says yes for a specific story, draft only the missing sections
in conversation, as ready-to-paste text. Do not use Write or Edit tools — the
story file stays untouched unless the user approves the draft and applies it
(or re-runs `/create-stories` for the epic).

**Redirect rules:**
- If a story file does not exist at all: "This story file is missing entirely.
  Run `/create-epics layer: <layer>` then `/create-stories [epic-slug]` to generate stories from the PRD, ADRs and API contract."
- If a story has no PRD reference and the work appears small: "This story has
  no PRD reference. If the change is small (under ~4 hours), run
  `/quick-spec [description]`, then reference the spec in the story body with a
  `Source spec: design/quick-specs/<file>.md` line. A quick-spec Small Feature
  story carries `**PRD**: None — quick spec` and
  `**Requirement**: None — quick spec`, and is ready on this item once the
  `Source spec:` line exists."
- If a story's scope has grown beyond its original sizing: "This story appears
  to have expanded in scope. Consider splitting it or escalating to the
  delivery-manager before implementation begins."
- If a story needs an operation the contract lacks, or a schema change without a
  plan: route to `/api-design update <resource>` or `/data-model migration <slug>`.

---

## 7. Next-Story Handoff

After completing a single-story readiness check (not `all` or `sprint` scope):

1. Read the current sprint file from `production/sprints/` (most recent).
2. Find stories that are:
   - `> **Status**: Ready` (sprint-status `ready-for-dev`) or not yet started
   - Not the story just checked
   - Not blocked by incomplete dependencies
   - In the Must Have or Should Have tier

If any are found, surface up to 3:

```
### Other Ready Stories in This Sprint

1. [Story name] — [1-line description] — Est: [X hrs]
2. [Story name] — [1-line description] — Est: [X hrs]

Run `/story-readiness [path]` to validate before starting.
```

If no sprint file exists, or no other ready stories are found, say which — `Next ready stories: no sprint file found` or `Next ready stories: none ready in [sprint]` — rather than omitting the section. The two mean different things (nothing to read versus nothing ready) and an omitted section reads as neither.

---

## Phase 8: Director Gate — Story Readiness Review

Apply the review mode resolved in Phase 0 before spawning QL-STORY-READY
(`--review` overrides the resolved `review_mode`):

- `full` → spawn as normal.
- `lean` → **skip every gate whose ID does not end in `-PHASE-GATE`**. Note: `[GATE-ID] skipped — Lean mode`
  QL-STORY-READY does not end in `-PHASE-GATE`, so lean skips it: report
  `[QL-STORY-READY] skipped — Lean mode` on the story's `QL-STORY-READY:` line.
- `solo` → skip all gates. Note: `[GATE-ID] skipped — Solo mode`

Run it for each story whose checklist verdict is READY or NEEDS WORK. A story that is
BLOCKED or NOT ASSESSED is not reviewed for testability until that clears — its
report line says `QL-STORY-READY: not run — story BLOCKED` (or `— story NOT ASSESSED`).
For several stories, spawn in parallel — issue every `Agent` call before waiting
for any result.

Spawn `qa-lead` via `Agent` using gate **QL-STORY-READY**. The prompt instructs the
agent to read `.claude/docs/director-gates/ql-story-ready.md` first — do not read
it or paste it yourself.

- Pass: story path · PRD path · resolved `testing.strict` line
- Fill: the story file path; the PRD path from the story's `**PRD**:` field
  (`design/product/one-pager.md` at `minimal`; the `Source spec:` path when the
  field reads `None — quick spec`); the `testing.strict` line exactly as the block
  above printed it.

Parse the first line of the reply as `[QL-STORY-READY]: TOKEN`
(`QL-STORY-READY: TOKEN` without the brackets parses the same), and map the token
with the verdict classes of `.claude/docs/director-gates.md`
(`## Standard Verdict Format`):
- **APPROVE-class** (`ADEQUATE`) → story is cleared on testability; the checklist
  verdict stands.
- **CONCERNS-class** (`GAPS`) → surface the specific gaps and the gate's rewrites to
  the user via `AskUserQuestion`: options `Revise flagged items` /
  `Accept and proceed` / `Discuss further`. Revise → draft the rewritten criteria in
  conversation for the user to apply; a READY story becomes NEEDS WORK until they
  are applied. Accept → the verdict stands, and the gaps stay listed.
- **REJECT-class** (`INADEQUATE`) → surface the blockers: the criteria are too vague
  to build or test against, so the story cannot be READY — report it as NEEDS WORK
  with the gate's findings as its gaps, and offer drafted rewrites.
- A first line that does not parse, or names another gate, is not an approval —
  treat it as CONCERNS-class and say the verdict line was missing.

**Recording the outcome** belongs in the story's status record — the review line at
the top of its `## QA Test Cases` section. This skill does not write it: show the
line for the user to add, e.g.
`> **QA Lead Review (QL-STORY-READY)**: CONCERNS (accepted) [date]`
(`APPROVED [date]` for ADEQUATE; `REVISED [date]` after the rewrites were applied
and the gate re-run).

---

## Recommended Next Steps

- Run `/dev-story [story-path]` to begin implementation once the story is READY
- Run `/story-readiness sprint` to check all stories in the current sprint at once
- Run `/create-stories [epic-slug]` if a story file is missing entirely
