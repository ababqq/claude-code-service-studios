# Skill Test Spec: /create-stories

> **Category**: pipeline
> **Priority**: high
> **Spec written**: 2026-09-28

## Skill Summary

`/create-stories` breaks **one epic** into implementable story files written directly
inside the epic directory — `production/epics/<epic-slug>/story-NNN-<slug>.md` — so the
catalog glob `production/epics/*/story-*.md` finds them (an `EPIC.md` alone never counts).
It reads the EPIC.md, the epic's PRD at the depth the tier requires, the control
manifest's layer section, the epic's TR entries, the contract operations, the migration
plans, the tracking plan, the UX specs and `docs/stack-reference/VERSION.md`, and loads
each governing ADR by bounded sections. Every story carries the story header contract —
`> **Type**:` (`Logic | Integration | UI | E2E | Config`), `> **Surface**:`, the TR-ID,
ADR guidance and `**ADR Version**`, `**API Contract**`, `**Migration**`,
`**Feature Flag**`, `**Analytics Events**` — plus acceptance criteria, an NFR budget, test
evidence per type and the migration floor; `**Stack Notes**` names the target root when the
story's layer lists several on the `code_roots` line. Stories are ordered contract-first. A story
whose ADR is Proposed, whose operation is missing from the contract, or which changes
stored data without a plan is written with `> **Status**: Blocked`. After the stories are
written, the review mode decides whether **QL-STORY-READY** (qa-lead) reviews each one;
an ADEQUATE reply also returns the story's QA test cases. At `minimal` the skill
synthesises the epic from `design/product/one-pager.md`. Its output is the artifact of catalog step
`validation.create-stories`.

Verdicts: **COMPLETE** / **BLOCKED** / **NOT ASSESSED** (a required input is missing: no epic, no
one-pager at `minimal`, or a referenced ADR file missing — any at `full`, a critical one at `standard`).

---

## Static Assertions (Structural)

Verified automatically by `/skill-test static` — no fixture needed.

- [ ] Frontmatter has `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`; `name: create-stories` equals the directory, the catalog `name` and this spec's basename
- [ ] `description` is exactly "Break one epic into stories embedding TR-ID, ADR guidance, API contract, migration, flag and acceptance criteria."
- [ ] `argument-hint` offers `[epic-slug | epic-path]` and `[--review full|lean|solo]`; `model: sonnet`; no `disable-model-invocation`, no `isolation`
- [ ] First body line is exactly `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,docs.density,story_granularity,feature_overrides,testing.strict,code_roots` ``
- [ ] `allowed-tools` is exactly `Read, Glob, Grep, Write, Agent, AskUserQuestion` plus `Bash(bash "*/.claude/skills/create-stories/../../hooks/yaml-helper.sh" resolve_config *)`
- [ ] The line after the bootstrap block is exactly `` Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`. ``, followed verbatim by the automation prelude block
- [ ] ≥2 numbered phase headings (`## 1. Parse Argument` … `## 7. After Writing`, with `## 6b. QA Lead Story Readiness Gate`)
- [ ] Verdict keywords `COMPLETE`, `BLOCKED` and the run-level `NOT ASSESSED`; the could-not-assess value `NOT ASSESSED (no VERSION.md risk rating)` present
- [ ] The story template reproduces the story header contract line for line: `# Story NNN: [title]`, `> **Epic**:`, `> **Status**: Ready`, `> **Layer**:`, `> **Type**: [Logic | Integration | UI | E2E | Config]`, `> **Surface**: [web | ios | android | mobile | api | admin | infra | analytics] (comma list allowed; first = primary)`, `> **Estimate**:`, `> **Manifest Version**:`, `> **Last Updated**:`, then `**PRD**:`, `**Requirement**:`, `**ADR Governing Implementation**:`, `**ADR Decision Summary**:`, `**ADR Version**:`, `**Stack**: … | **Risk**:`, `**Stack Notes**:`, `**API Contract**:`, `**Migration**:`, `**Feature Flag**:`, `**Analytics Events**:`, `**ML**:`
- [ ] Body sections `## Acceptance Criteria`, `## Implementation Notes`, `## Out of Scope`, `## QA Test Cases`, `## Test Evidence`, `## Dependencies` present
- [ ] `## Implementation Notes` has the `- UX spec:` bullet followed directly by `` - Design reference: [none — markdown spec only | claude-design — <locator> · record `design/handoff/<slug>/HANDOFF.md` | figma — <node URL> · record `design/handoff/<slug>/HANDOFF.md`] — [the frames / screens for the states this story implements] *(UI and E2E stories; write "N/A — no user-facing surface" otherwise)* ``; no `**Design …**` bold header field is added
- [ ] Step 2's `design/ux/*.md` read names the `> **Design Source**:` header line; the fallback `Design reference: NOT CHECKED — <spec> has no Design Source line (run /ux-design <slug>)` is present
- [ ] `## Test Evidence` names the five `testing.strict` keys `logic`, `integration`, `ui`, `e2e`, `config` and the migration floor `production/qa/evidence/[story-slug]/migration-dry-run.log` "required at every `qa.level` and regardless of `testing.strict.config`"
- [ ] Write prompts present: "May I write these [N] stories to `production/epics/<epic-slug>/`?", "May I write this to `production/epics/<epic-slug>/EPIC.md`?", "May I write this to `production/epics/index.md`?", "May I write this to `production/epics/<epic-slug>/story-NNN-<slug>.md`?" (gate results)
- [ ] QL-STORY-READY review-mode check carries the lean suffix sentence; the spawn has `` Pass: story path · PRD path · resolved `testing.strict` line ``; replies are parsed as `[QL-STORY-READY]: TOKEN`
- [ ] Only one `!` injection; no `file:line` citation; the handoff names `/story-readiness`, `/dev-story`, `/create-stories [slug]` and `/sprint-plan new`

---

## Director Gate Checks

One gate: **QL-STORY-READY** — `qa-lead`, Domain "Testability", verdicts
`ADEQUATE / GAPS / INADEQUATE`. It runs in Step 6b on the story files Step 6 wrote — one
`qa-lead` per story, all spawned in parallel before any result is awaited.

- **Full mode**: `## QA Test Cases` is first written with
  `*Pending QL-STORY-READY — Step 6b fills this section.*`; Step 6b replaces it with the
  recorded outcome and the specs.
- **Lean mode**: skip every gate whose ID does not end in `-PHASE-GATE` — no spawn;
  `> [QL-STORY-READY] skipped — Lean mode` is the first line of each story's
  `## QA Test Cases`, followed by "*N/A — no qa-lead specs at this tier; implement against
  the Acceptance Criteria above*".
- **Solo mode**: same, with `> [QL-STORY-READY] skipped — Solo mode`.

---

## Test Cases

Fixtures use the Moa example: epic `production/epics/goals-core/EPIC.md` (Layer Core,
PRD `design/prd/goals.md`, governing `ADR-0006`, operations `createGoal` and `listGoals`,
entity `savings_goal` with `docs/data/migrations/0003-savings-goal.md`, flag
`goals.v2-progress-ring`, events `goal_created`, `goal_viewed`).

### Case 1: Happy Path — four stories at `standard`

**Fixture:**
- `modes.workflow: standard`, `modes.story_granularity: balanced`; review mode `lean`
- ADR-0006 `Accepted`, with `## Last Verified` 2026-10-05 and a `## Stack Compatibility` risk of LOW
- `docs/architecture/control-manifest.md` (`Manifest Version` 2026-10-06) and TR entries `TR-goals-001..004`
- `project.yaml` sets `testing.patterns: ["**/*.test.ts", "tests/e2e/**"]`
- The `code_roots` line lists `backend=apps/api,services/worker` (two roots)

**Input:** `/create-stories goals-core`

**Expected behavior:**
1. Loads the epic, the PRD's standard sections, `^## Core Layer Rules` of the manifest, `id: TR-goals-` entries, the contract operations, the migration plan, the tracking plan events and the UX specs; loads ADR-0006 by bounded sections and captures `## Last Verified`
2. Classifies stories and assigns Surfaces, ordered contract-first: migration + `createGoal` (Integration, api) → goal rules (Logic, api) → goal screens (UI, web, mobile) → the journey story (E2E, web) last
3. Presents the full list with type, surface, ADR, API, migration, flag and events, then asks "May I write these [N] stories to `production/epics/goals-core/`?"
4. Writes `story-001-…` … `story-004-…`, then asks "May I write this to `production/epics/goals-core/EPIC.md`?" and fills its `## Stories` table; asks "May I write this to `production/epics/index.md`?" and updates the index row's `Stories` column
5. Records the lean skip note in each `## QA Test Cases`; reports Verdict **COMPLETE**; closes with the next-step widget

**Assertions:**
- [ ] Every story header matches the story header contract exactly (field names, order, `> ` prefixes)
- [ ] `**ADR Version**` is `2026-10-05`; `> **Manifest Version**:` is `2026-10-06`
- [ ] The Integration story names `` **API Contract**: `docs/api/openapi.yaml#/paths/~1v1~1goals/post` `` and `` **Migration**: `docs/data/migrations/0003-savings-goal.md` ``, and its `## Test Evidence` names the migration dry-run log
- [ ] The UI story carries `**Feature Flag**: goals.v2-progress-ring` and `**Analytics Events**: goal_viewed`; `**ML**:` is omitted on every story
- [ ] The `api` stories' `**Stack Notes**` name the target root `apps/api` (the backend layer lists two roots on the `code_roots` line)
- [ ] Test paths follow `testing.patterns`; the E2E story's evidence is `tests/e2e/[journey]/` + `production/qa/evidence/[story-slug]/`
- [ ] Numbering starts after the highest existing `story-NNN` and never reuses a number; the EPIC `## Stories` table and the index row are updated in place (no duplicate rows)
- [ ] Nothing is written before the set-level "May I write" answer; no implementation starts

---

### Case 2: Failure Path — a referenced ADR file is missing at `full`

**Fixture:** `modes.workflow: full`; the epic lists `ADR-0007: Goal progress events`, but no `docs/architecture/adr-0007-*.md` exists.

**Input:** `/create-stories goals-core`

**Expected behavior:**
1. ADR existence validation runs before any decomposition
2. Stops with "Epic references [ADR-0007: Goal progress events] but `docs/architecture/[adr-file].md` was not found. … Cannot create stories until all referenced ADR files are present."

**Assertions:**
- [ ] No story file is written and no question with empty options is asked
- [ ] The message names the missing ADR and routes to `/architecture-decision`
- [ ] At `standard` the same gap on a non-critical ADR warns and continues instead (story embeds the reference with `> **Status**: Blocked`)
- [ ] Verdict is NOT ASSESSED — no story files written

---

### Case 3: NOT ASSESSED — `minimal` tier with no stack rating

**Fixture:**
- `modes.rigor` unset (`minimal`, review mode `solo`); no epics exist
- `design/product/one-pager.md` with a three-item `## Build Order`
- `docs/stack-reference/VERSION.md` absent

**Input:** `/create-stories`

**Expected behavior:**
1. Synthesises the epic from the one-pager and asks "May I write this to `production/epics/<slug>/EPIC.md`?"
2. Generates one coarse story per Build Order item, filled with the exact minimal mapping
3. With no `VERSION.md` to read, writes `**Risk**: NOT ASSESSED (no VERSION.md risk rating)` on every story

**Assertions:**
- [ ] `**PRD**` → `design/product/one-pager.md`; `**Requirement**` → `Build Order item N` (never a `TR-` ID)
- [ ] ADR fields → `N/A (minimal — no ADRs)`; `Manifest Version` and manifest rules → `N/A (minimal — no control manifest)`; `**Stack Notes**` → `none (no ADR stack-compatibility analysis at minimal)`
- [ ] Risk is `NOT ASSESSED (no VERSION.md risk rating)` — no level is guessed (downstream treats it as HIGH)
- [ ] With the one-pager absent it reports "No `design/product/one-pager.md` — run `/brainstorm` first" and stops with Verdict NOT ASSESSED
- [ ] A successful minimal run ends COMPLETE (the Risk field's NOT ASSESSED is input-level)
- [ ] A UI story with no backing UX spec in `design/ux/` carries `Design reference: NOT CHECKED — <reason>`, never `none`

---

### Case 4: Mode Variant — Blocked stories are written and flagged

**Fixture:**
- `modes.workflow: full`; ADR-0006 `Accepted`, ADR-0008 (goal archiving) `Proposed`
- A PRD criterion needs `archiveGoal`, which the contract lacks; another adds a `note` column to `savings_goal` with no migration plan

**Input:** `/create-stories goals-core`

**Expected behavior:**
1. The archiving story gets `> **Status**: Blocked` with "BLOCKED: ADR-0008 is Proposed — run `/architecture-decision` to advance it"
2. The same story also names "BLOCKED: operation [archiveGoal] is not in the API contract — run `/api-design update <resource>`"
3. The note story gets "BLOCKED: schema change without a migration plan — run `/data-model migration <slug>`"
4. The list shows `K Blocked` before the write question

**Assertions:**
- [ ] Blocked stories appear as Blocked in the preview, before writing
- [ ] Blocked stories are still written; the other stories keep `> **Status**: Ready`
- [ ] The closing widget lists each Blocked story with the command that clears it

---

### Case 5: Edge Case — no argument

**Fixture (5a):** `modes.workflow: standard`; `production/epics/*/EPIC.md` matches nothing.

**Fixture (5b):** `modes.workflow: standard`; epics `auth-foundation` and `goals-core` exist.

**Input:** `/create-stories`

**Expected behavior:**
1. (5a) Stops: "No epics found under `production/epics/`. Run `/create-epics layer: foundation` first — an epic is what this skill decomposes."
2. (5b) Asks "Which epic would you like to break into stories?" listing both epics with their status

**Assertions:**
- [ ] 5a never builds an `AskUserQuestion` with no options and writes nothing
- [ ] 5a: Verdict is NOT ASSESSED
- [ ] 5b does not pick an epic silently

---

### Case 6: Director Gate — full mode

**Fixture:** Case 1 fixture with review mode `full`; qa-lead returns ADEQUATE for three stories and GAPS for the UI story.

**Expected behavior:**
1. After Step 6, spawns one `qa-lead` per story in parallel with `` Pass: story path · PRD path · resolved `testing.strict` line ``
2. Passes the `testing.strict` line the bootstrap block printed
3. Parses each `[QL-STORY-READY]: TOKEN`

**Assertions:**
- [ ] ADEQUATE → the returned specs are embedded in `## QA Test Cases` under `> **QA Lead Review (QL-STORY-READY)**: APPROVED [date]`, the review line at the top of that section
- [ ] GAPS → `AskUserQuestion` with `Revise flagged items` / `Accept and proceed` / `Discuss further`; accepting leaves `*Test cases not yet defined — run /qa-plan to generate them.*` and records `CONCERNS (accepted) [date]`
- [ ] INADEQUATE → criteria are revised and the gate re-runs for that story; if the user stops, the story gets `> **Status**: Blocked` with "BLOCKED: QL-STORY-READY INADEQUATE — acceptance criteria must be revised before implementation"
- [ ] One spawn per story returns both verdict and specs — no second `qa-lead` spawn
- [ ] The run summary reports the strictest class across the epic
- [ ] Gate results are embedded only after "May I write this to `production/epics/goals-core/story-NNN-<slug>.md`?"

---

### Case 7: Director Gate — lean mode

**Fixture:** Case 1 fixture; review mode `lean`.

**Assertions:**
- [ ] No `qa-lead` spawn
- [ ] Every story's `## QA Test Cases` starts with `> [QL-STORY-READY] skipped — Lean mode` and the N/A text
- [ ] No test cases are improvised in place of the skipped specs

---

### Case 8: Director Gate — solo mode

**Fixture:** Case 1 fixture; review mode `solo`.

**Assertions:**
- [ ] No director gate spawns
- [ ] Every story's `## QA Test Cases` starts with `> [QL-STORY-READY] skipped — Solo mode`

---

### Case 9: Design Tool — a Figma-designed UI story

**Fixture:**
- Case 1 fixture; `design/ux/goal-detail.md` carries
  ``> **Design Source**: figma — https://www.figma.com/design/<fileKey>/Moa?node-id=12-34 · record `design/handoff/goal-detail/HANDOFF.md` ``
- `design/ux/goal-list.md` predates the header and has no `> **Design Source**:` line

**Input:** `/create-stories goals-core`

**Expected behavior:**
1. Step 2 reads each relevant UX spec's `> **Design Source**:` line
2. The goal-detail UI story's `## Implementation Notes` has the `- UX spec:` bullet naming `design/ux/goal-detail.md` and directly below it
   ``- Design reference: figma — https://www.figma.com/design/<fileKey>/Moa?node-id=12-34 · record `design/handoff/goal-detail/HANDOFF.md` — [frames for the states this story implements]``
3. The goal-list story gets `Design reference: NOT CHECKED — design/ux/goal-list.md has no Design Source line (run /ux-design goal-list)`

**Assertions:**
- [ ] The first token and the record path are copied unchanged from the UX spec; no handoff-prompt text is copied
- [ ] The story header is unchanged — no new bold field; the Integration and Logic stories write `Design reference: N/A — no user-facing surface`
- [ ] A spec with no Design Source line never yields `none — markdown spec only`

---

## Protocol Compliance

- [ ] All inputs load before the story list is shown; the full list is shown before any write
- [ ] The story set is approved once ("May I write these [N] stories …"); EPIC.md, the index and gate results each get their own approval
- [ ] Blocked stories are flagged before writing, not discovered after
- [ ] Acceptance criteria come from the PRD, notes from the ADR, rules from the manifest, operations from the contract, events from the tracking plan — nothing invented
- [ ] Requirement text is not copied into the story (it lives in `docs/architecture/tr-registry.yaml`)
- [ ] Never starts implementation; nothing under `production/session-logs/`; no fronted knob written
- [ ] Ends with `/story-readiness [first-story-path]` → `/dev-story`

---

## Coverage Notes

- Pipeline rubric mapping: P1 (story header contract and body sections — Case 1), P2
  (contract-first order inside the Core layer — Case 1), P3 (set-level story approval plus
  per-file approvals for EPIC.md, the index and gate results — Cases 1, 6; the skill's
  "ask once" rule for the story set is intentional and is what this spec asserts), P4
  (QL-STORY-READY per review mode — Cases 6–8), P5 (inputs read before writing — Case 1).
- The `Design reference:` line (copied from the UX spec's `> **Design Source**:` line) is
  exercised for `figma` and for a spec without the line (Case 9); `claude-design` and `none`
  follow the same copy rule and are not fixture-tested.
- The "prefer an existing QA plan" branch (`## Automated Tests Required` of the latest
  `production/qa/qa-plan-*.md`) is not fixture-tested.
- `story_granularity` targets (5–10 / 2–4 / 1 AC per story) are exercised only at
  `balanced` (Case 1) and `coarse` (Case 3).
