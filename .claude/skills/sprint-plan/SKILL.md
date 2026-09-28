---
name: sprint-plan
description: "Sprint plan from the milestone, completed work and capacity; writes sprint-status.yaml. Never writes modes.review_mode."
argument-hint: "[new|update|status] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/sprint-plan/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,story_granularity,workflow`

Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

---

## Phase 0: Parse Arguments

Extract the mode argument (`new`, `update`, or `status`) and an optional
`--review full|lean|solo`, which overrides the resolved `review_mode` for this run
only.

See `.claude/docs/director-gates.md` for the full check pattern. Individual gate definitions live in `.claude/docs/director-gates/[gate-id].md` — the spawned agent reads its own gate file; do not read it in the parent session.

**`story_granularity`** — it sets how many stories to allocate per sprint, scaled
by velocity: **2–4** at `coarse`, **6–10** at `balanced`, **15–25** at `fine`. Take
the value from the resolved block above; when the project leaves it unset,
`modes.rigor` supplies it.

**`workflow`** — at `minimal` this skill is **optional**: the one-pager's
`## Build Order` (`design/product/one-pager.md`) already is the plan. Say so once,
then plan anyway if the user asked for a sprint.

**Review mode** (resolved above — do not re-resolve it):
- The value in the block is final for this run, including when it came from the
  `modes.rigor` expansion. Unset on an unconfigured project: `modes.rigor` defaults to `minimal`, which resolves `review_mode` to `solo`.
- **This skill never writes `modes.review_mode`** — not to `project.yaml`, not to
  `project.local.yaml`, not on the user's request mid-run. `review_mode` is fronted
  by `modes.rigor`; a skill that seeds it pins the value and silently shadows every
  later rigor change. If the user wants a different depth, point them at the two
  sanctioned routes and continue with the resolved value:
  - this run only: re-run with `--review full|lean|solo`;
  - persistently: `/settings modes.review_mode=<value>` (or
    `/settings --local modes.review_mode=<value>` for their own checkout).
- A skill that decides it cannot run must not have edited config on the way to
  deciding. Nothing in this skill writes configuration, so an early stop in
  Phase 1 leaves the project exactly as it was.

---

## Phase 1: Gather Context

1. **Read the current milestone** from `production/milestones/` **if it exists**.
   The active milestone is the newest `production/milestones/*.md` **excluding**
   `*-review.md` (those are `/milestone-review` reports, not definitions).
   Milestone definitions are authored by hand from
   `.claude/docs/templates/milestone-definition.md` (types MVP, Private Beta,
   Public Beta, GA and their neighbours); no skill writes them. On many projects
   the directory is absent, which is the normal state, not a gap: note "no
   milestone defined — planning against the story backlog alone" and continue.
   Never block sprint planning on it, and never infer a milestone from the sprint
   files.

2. **Read the previous sprint** (if any). `Glob production/sprints/sprint-*.md`;
   the highest number is the previous sprint and the new sprint is the next number,
   written with two digits (`sprint-01.md`, `sprint-02.md`, …). Establish:
   - **Velocity** — completed versus committed stories (and estimate days) for the
     last sprints. Sources, in order: `production/sprint-status.yaml` while its
     `sprint:` is still the previous sprint (stories with `status: done`), then the
     `## Metrics` tables of `production/retrospectives/retro-sprint-*.md`. No
     previous sprint ⇒ velocity is `none` — say so; this is a calibration sprint.
   - **Carryover** — stories of the previous sprint whose status is not `done`.

3. **Find the stories to plan** — this is the actual backlog, and it is the one
   input this phase cannot do without:
   ```
   Glob production/epics/*/story-*.md
   Grep pattern="^> \*\*(Status|Type|Surface|Estimate)\*\*" glob="production/epics/*/story-*.md" output_mode="content"
   ```
   Stories live at `production/epics/[epic-slug]/story-NNN-[slug].md` — that is
   where `/create-stories` writes them and where `/dev-story` looks for them. Plan
   from the ones whose `> **Status**:` is `Ready`. Use the grep rather than reading
   each story: at this stage you need status, type, surface and estimate, not the
   body. Read a story in full only when its dependencies decide the order.

   If the glob returns nothing: "No stories found under `production/epics/`. Run
   `/create-stories` first (at `standard`/`full`, `/create-epics` before it)."
   Do not proceed to invent work items — a sprint plan that references stories
   which do not exist cannot be implemented.
   Verdict: **NOT ASSESSED** — no stories to plan from (a missing required input —
   `/create-epics` and `/create-stories` use the same verdict).

4. **Scan the PRDs** in `design/prd/` for context on the features those stories
   implement (each story's `**PRD**:` field names its PRD). At `workflow: minimal`
   there are no per-feature PRDs — use `design/product/one-pager.md` instead, and
   do not treat the absent PRDs as missing work.

5. **Check the risk register** at `production/risk-register/` **if it exists**.
   Entries are authored from `.claude/docs/templates/risk-register-entry.md`, by
   hand or through the offer in Phase 5 of this skill. If the directory is absent,
   say so once ("no risk register — risks assessed from the sprint contents only")
   rather than skipping risk assessment silently.

6. **Note capacity reducers** the user has not mentioned and ask about them rather
   than assuming zero: public holidays in the sprint window (Seollal and Chuseok
   remove most of a week in Korea; US holidays for distributed teams), planned time
   off, on-call rotation, and release or store-review work that lands in the sprint.

---

## Phase 2: Generate Output

For `new`:

**Generate a sprint plan** from `.claude/docs/templates/sprint-plan.md` and present
it to the user. Read the template and copy its headings **byte for byte** —
`/milestone-review` greps them — and fill every section:

- **Header** — the `> **Delivery Manager Review (DM-SPRINT)**:` line stays
  `pending` until Phase 4 records the outcome or the skip note.
- **Sprint Goal** — one sentence the committed stories add up to (for Moa: "A user
  can create a savings goal and see its progress on web and mobile"), not a list.
- **Milestone Context** — the active milestone and its target date, or "none
  defined".
- **Capacity** — total person-days, minus the reducers of Phase 1 step 6, minus a
  20% buffer for unplanned work (incidents, review feedback, store rejections).
- **Tasks** — one row per story: its ID, title, story file path (verbatim from the
  Glob), owner (the routed engineer for its `**Surface**` — `backend-engineer`,
  `frontend-engineer`, `mobile-engineer` — or a named person), estimate,
  dependencies and acceptance-criteria summary. Must Have = the critical path to
  the sprint goal; Should Have and Nice to Have are cut first. Size the commitment
  to velocity and to the `story_granularity` band above.
- **Carryover** — the Phase 1 carryover stories with reason and new estimate.
- **Risks to This Sprint** and **External Dependencies** — third-party sandbox
  access, an API contract operation a client story needs, a migration's Expand phase
  that must ship first, store review lead time, a pending legal or privacy review.
- **Definition of Done** — copy the template's rows unchanged; they are the sprint's
  shared DoD (flag defaults, tracking events, API contract, migration phase and
  dry-run evidence, observability, accessibility, no PII in logs, QA plan, smoke
  check, QA sign-off).

Do NOT ask to write yet — the gate phases run first and may require revisions
before the files are written: the delivery feasibility gate (Phase 4, spawned only
in `full` review mode — skipped in `lean`/`solo`) and the QA plan check (Phase 5,
all modes).

For `update`:

**Update an existing sprint plan**:

1. Read the most recent sprint plan from `production/sprints/`.
2. Present the current story list with their current statuses from `production/sprint-status.yaml`.
3. Ask the user what to change: stories to add, remove, reprioritize, or re-estimate. Use `AskUserQuestion` to gather changes.
4. Apply the changes and re-present the full revised plan for review.
5. Re-run the delivery feasibility gate (Phase 4) on the revised plan.
6. Write the updated markdown plan and yaml together (same approval as `new` mode).

Note: `update` mode does not reset story statuses. Stories already marked `in-progress`, `review` or `done` keep their status. Only `backlog` and `ready-for-dev` stories can be removed or reprioritized freely; removing an `in-progress` story needs an explicit decision from the user, recorded in the plan's carryover or risks section.

For `status`:

**Generate a status report** in the conversation (nothing is written; for a faster
snapshot use `/sprint-status`). Read `production/sprint-status.yaml` for statuses.

```markdown
# Sprint [N] Status -- [Date]

## Progress: [X/Y stories complete] ([Z%])

### Completed
| Story | Completed By | Notes |
|-------|-------------|-------|

### In Progress
| Story | Owner | Status (in-progress / review) | Blockers |
|-------|-------|-------------------------------|----------|

### Not Started
| Story | Owner | At Risk? | Notes |
|-------|-------|----------|-------|

### Blocked
| Story | Blocker | Owner of Blocker | ETA |
|-------|---------|-----------------|-----|

## Burndown Assessment
[On track / Behind / Ahead]
[If behind: What is being cut or deferred]

## Emerging Risks
- [Any new risks identified this sprint]
```

---

## Phase 3: Prepare Sprint Status File

After generating a new sprint plan, also prepare the `production/sprint-status.yaml` content.
This is the machine-readable source of truth for story status — read by
`/sprint-status`, `/story-done`, `/dev-story` and `/help` without markdown parsing.

**Do not write the yaml yet** — hold it in context. The delivery feasibility gate (Phase 4, `full` review mode only) may revise the story list; the QA plan check (Phase 5) runs in every mode. The yaml is written after Phase 5, in the same approval as the final plan.

For `new`, the file replaces the previous sprint's yaml. Its final state is what
Phase 1 read for velocity and carryover — if the user wants that sprint's data
captured, `/retrospective sprint-<N>` should run before this write; say so.

Format:

```yaml
# Auto-generated by /sprint-plan. Updated by /dev-story and /story-done.
# DO NOT edit manually — use /story-done to update story status.
#
# Status values (exact; the hyphenated form is the only accepted spelling):
#   backlog | ready-for-dev | in-progress | review | done | blocked
# Mapping to the story file's "> **Status**:" line:
#   backlog        ↔  (not scheduled to start this sprint; story file unchanged)
#   ready-for-dev  ↔  Ready
#   in-progress    ↔  In Progress
#   review         ↔  In Review
#   done           ↔  Complete
#   blocked        ↔  Blocked

sprint: [N]
goal: "[sprint goal]"
start: "[YYYY-MM-DD]"
end: "[YYYY-MM-DD]"
generated: "[YYYY-MM-DD]"
updated: "[YYYY-MM-DD]"

stories:
  - id: "[epic-slug-NNN, e.g. goals-core-001]"
    name: "[story name]"
    file: "[production/epics/[epic-slug]/story-NNN-[slug].md]"   # the real path, verbatim from the Glob above
    priority: must-have        # must-have | should-have | nice-to-have
    status: ready-for-dev      # backlog | ready-for-dev | in-progress | review | done | blocked
    owner: ""
    estimate_days: 0
    blocker: ""
    completed: ""
```

Initialize each story from the sprint plan's task tables:
- Must Have stories → `priority: must-have`, `status: ready-for-dev`
- Should Have stories → `priority: should-have`, `status: backlog`
- Nice to Have stories → `priority: nice-to-have`, `status: backlog`
- Carryover stories keep their last status (`in-progress`, `review` or `blocked`)

For `update`: read the existing `sprint-status.yaml`, carry over statuses for
stories that haven't changed, add new stories, remove dropped ones.

---

## Phase 4: Delivery Feasibility Gate

**Review mode check** — apply before spawning DM-SPRINT (`--review` overrides the
resolved `review_mode`):
- `solo` → skip all gates. Note: `[DM-SPRINT] skipped — Solo mode`
- `lean` → **skip every gate whose ID does not end in `-PHASE-GATE`**. Note: `[GATE-ID] skipped — Lean mode`
  DM-SPRINT does not end in `-PHASE-GATE`, so lean skips it: `[DM-SPRINT] skipped — Lean mode`.
- `full` → spawn as normal.

When skipped, the note replaces `pending` in the plan's
`> **Delivery Manager Review (DM-SPRINT)**:` header line, and the summary says:
"DM-SPRINT not consulted — <Mode> mode; `--review full` runs it." Proceed to Phase 5.

**At `full`**, the gate reads the plan from disk, so the draft is written first:
ask "May I write the draft sprint plan to `production/sprints/sprint-NN.md` for the
DM-SPRINT review? (`production/sprint-status.yaml` is not written until the plan is
final.)" If the user declines, stop without writing anything. Verdict: **BLOCKED** —
the DM-SPRINT review needs the draft on disk; re-run when ready, or with
`--review lean` to plan without the per-skill gate.

Spawn `delivery-manager` via `Agent`:
- Gate: **DM-SPRINT** — `.claude/docs/director-gates/dm-sprint.md`. The `Agent`
  prompt instructs the agent to read that file **first**; never read it or paste its
  prompt in this session.
- Pass: sprint plan draft path · velocity of previous sprints (or "none") · story paths in the sprint
- Fill them: `production/sprints/sprint-NN.md`; the Phase 1 velocity figures (for
  example "sprint-02: 9 of 11 committed stories done, 27 of 34 estimate days") or
  `none`; every story file path in the plan's task tables.
- Parse the first line of the reply as `[DM-SPRINT]: TOKEN` and map the token with
  the verdict-class table of `.claude/docs/director-gates.md` (Standard Verdict
  Format). Present the delivery manager's findings.

Handle all three classes:

- **REALISTIC** (APPROVE-class) → proceed to Phase 5.
- **CONCERNS** (CONCERNS-class) → use `AskUserQuestion`:
  - Prompt: "The delivery manager flagged concerns with this sprint plan. How do you want to proceed?"
  - Options:
    - `[A] Accept and proceed — I accept the risk as planned`
    - `[B] Revise — defer the flagged Should Have stories`
    - `[C] Revise — move the sprint dates or capacity`
    - `[D] Discuss further before deciding`

  If [A]: proceed to Phase 5. If [B] or [C]: revise the plan, re-present it, update
  the draft (ask first) and proceed to Phase 5. If [D]: discuss, then ask again.
- **UNREALISTIC** (REJECT-class) → the sprint must be descoped. Surface the stories
  the delivery manager named, revise the selection (defer to Should Have or Nice to
  Have, or to the next sprint), re-present the plan, update the draft (ask first) and
  re-run DM-SPRINT. Do not write `production/sprint-status.yaml` while the latest
  verdict is REJECT-class. If the user stops before the verdict clears:
  Verdict: **BLOCKED** — DM-SPRINT UNREALISTIC unresolved.
- A first line that does not parse (missing, malformed, or a token not on the
  gate's Verdicts line) is not an approval: show the full reply, say the verdict
  line was missing, and handle it as CONCERNS-class.

Record the outcome in the plan's header line, replacing `pending`:
`> **Delivery Manager Review (DM-SPRINT)**: APPROVED [date] / CONCERNS (accepted) [date] / REVISED [date]`.

---

## Phase 5: QA Plan Gate

Before closing the sprint plan, check whether a QA plan exists for this sprint.

`Glob production/qa/qa-plan-*.md` and look for one whose name or header refers to
this sprint number.

**If a QA plan is found**: note it in the sprint plan output — "QA Plan: `[path]`" — and proceed.

**If no QA plan exists**: do not silently proceed. Surface this explicitly:

> "This sprint has no QA plan. A sprint plan without a QA plan means test requirements are undefined — engineers won't know what 'done' looks like from a QA perspective. The Build → Hardening gate reports the missing plan as CONCERNS, and the Hardening → Launch gate requires a QA sign-off report, which is built on one.
>
> Run `/qa-plan sprint` now, before starting any implementation. It takes one session and produces the test case requirements each story needs."

Use `AskUserQuestion`:
- Prompt: "No QA plan found for this sprint. How do you want to proceed?"
- Options:
  - `[A] Run /qa-plan sprint now — I'll do that before starting implementation (Recommended)`
  - `[B] Skip for now — I understand QA sign-off will be blocked until a QA plan exists`

If [B]: add a warning block to the sprint plan document, directly under its
`## Definition of Done` checklist:

```markdown
> ⚠️ **No QA Plan**: This sprint was started without a QA plan. Run `/qa-plan sprint`
> before the last story is implemented. The Hardening → Launch gate requires a QA
> sign-off report, which requires a QA plan.
```

### Write the plan

Ask: "May I write the sprint plan to `production/sprints/sprint-NN.md` and
`production/sprint-status.yaml`?" (At `full` the plan file already holds the
reviewed draft; this write finalizes it.) If yes, write both files (creating
directories as needed). Verdict: **COMPLETE** — sprint plan and status file created.
If no: Verdict: **BLOCKED** — user declined write.

If [A] was chosen above, close with "Sprint plan written. Run `/qa-plan sprint`
next — then begin implementation."

After writing, add:

> **Scope check:** If this sprint includes stories added beyond the original epic scope, run `/scope-check [feature-or-sprint]` to detect scope creep before implementation begins.

### Risk register entry (offer)

For each risk in the plan's `## Risks to This Sprint` table rated High probability
or High impact that has no entry yet under `production/risk-register/`, offer to
record it. Draft the entry from `.claude/docs/templates/risk-register-entry.md`
(category, probability, impact, trigger conditions, prevention and contingency
owners, taken from the plan and the DM-SPRINT findings), show it, and ask: "May I
write this to `production/risk-register/<risk-slug>.md`?" `<risk-slug>` is a
kebab-case summary of the risk (for Moa: `toss-payments-sandbox-access`). A declined
offer changes nothing else in the run.

---

## Phase 6: Next Steps

After the sprint plan is written and QA plan status is resolved:

- `/qa-plan sprint` — **required before implementation begins** — defines test cases per story so engineers implement against QA specs, not a blank slate
- `/story-readiness [story-file]` — validate a story is ready before starting it
- `/dev-story [story-file]` — begin implementing the first story
- `/sprint-status` — check progress mid-sprint
- `/scope-check [feature-or-sprint]` — verify no scope creep before implementation begins
- `/retrospective sprint-<N>` — at the end of the sprint, before the next `/sprint-plan new`

**Review mode configuration:** All gates this workflow reaches (delivery
feasibility here, story readiness in `/story-readiness`, code review and test
coverage in `/story-done`) respect the project review mode, resolved by the
bootstrap block: `--review` flag → `project.local.yaml` → `project.yaml` → the
`modes.rigor` expansion (`minimal`→`solo`, `standard`→`lean`, `full`→`full`).
Unset on an unconfigured project: `modes.rigor` defaults to `minimal`, which resolves `review_mode` to `solo`. The mode is one of:
- `full` — run all director gates as spawned sub-agents
- `lean` — skip every gate whose ID does not end in `-PHASE-GATE` (phase gates only)
- `solo` — skip all gate spawning unconditionally (single developer, no review)

Only `/settings` writes `modes.review_mode`; `/sprint-plan` reads it and never
changes it.
