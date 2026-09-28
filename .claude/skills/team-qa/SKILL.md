---
name: team-qa
description: "Full QA cycle: strategy, cases, execution, bugs, sign-off."
argument-hint: "[sprint | feature: <feature-slug>] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/team-qa/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,team.size,qa.level,testing.strict,project.stage`

Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

When this skill is invoked, orchestrate the QA team through a structured testing cycle.

**Decision Points:** At each phase transition, use `AskUserQuestion` to present
the user with the subagent's proposals as selectable options. Write the agent's
full analysis in conversation, then capture the decision with concise labels.
In `collaborative` mode, the user must approve before moving to the next phase.
In `guided` mode the pipeline advances automatically unless a phase is BLOCKED;
in `autonomous` mode it runs end to end, recording each phase outcome via
`log_decision`. Decisions in `automation_always_ask` categories
(`is_always_ask_category` helper) always prompt regardless of mode. See
`.claude/docs/automation-modes.md`.

**Outputs:**

| Path | Phase | Written by |
|------|-------|------------|
| `production/qa/qa-plan-<sprint>-YYYY-MM-DD.md` | 3 | this skill, after "May I write" |
| `production/qa/test-cases/<feature>-cases.md` | 4 | `qa-engineer` (path named in its prompt) |
| `production/qa/bugs/BUG-NNNN.md` | 5 | `qa-engineer` (path named in its prompt) |
| `production/qa/evidence/<story-slug>/` (evidence record) | 5 | this skill, after "May I write" |
| `production/qa/qa-signoff-<sprint>-YYYY-MM-DD.md` | 6 | this skill, after "May I write" |

`<sprint>` is the sprint id (`sprint-07`), or the feature slug for `feature:` scope.

## Phase 0: Resolve Config

The block at the top of this skill resolved `review_mode`, `automation`, `team.size`, `qa.level`,
`testing.strict` and `project.stage`.

`review_mode` sets gate depth. This skill spawns one gate, **QL-TEST-COVERAGE**, in Phase 5b; apply the
review-mode check before spawning it (`--review` overrides the resolved value):
- `full` → spawn as normal
- `lean` → **skip every gate whose ID does not end in `-PHASE-GATE`**. Note: `[GATE-ID] skipped — Lean mode`
  QL-TEST-COVERAGE does not end in `-PHASE-GATE`, so lean skips it: record `[QL-TEST-COVERAGE] skipped — Lean mode`.
- `solo` → skip all gates. Note: `[QL-TEST-COVERAGE] skipped — Solo mode`

Unset on an unconfigured project: `modes.rigor` defaults to `minimal`, which resolves `review_mode` to `solo`.

`automation` drives the Decision Points note above. See the Decision Points note above and
`.claude/docs/automation-modes.md` for how each mode changes pipeline behavior.

**`team.size`**: which agents are active (orthogonal to review_mode gate-depth and workflow docs).
- **`individual`**: `qa-engineer` only — strategy, cases, bug reports and the sign-off draft route through
  it; `qa-lead` is spawned only for the QL-TEST-COVERAGE gate, and only when `review_mode` runs it.
- **`small`**: `qa-lead` → `qa-engineer` pipeline (as documented).
- **`studio`**: `qa-lead` → `qa-engineer` (one spawn per feature) + `accessibility-specialist` (accessibility
  pass of UI and E2E stories in Phase 5).
Team skills spawn only the gates `.claude/docs/director-gates.md` § Gate Index lists this skill under (Spawned by column), after the review-mode check (lean suffix rule); team-size scoping never removes a director gate. A non-core agent needed at `individual` routes through the nearest active core agent with an informational note. **"Phase gate" means any phase that ends in an `AskUserQuestion` decision point before the pipeline advances** — not every phase. Apply the test literally: if the phase below has no decision point, it is not a gate, and an agent restricted to "phase gates only" is not spawned for it. This active-set scoping applies throughout the pipeline below: any phase that names an agent outside the active set routes through the nearest core agent rather than spawning it.

Unset on an unconfigured project, `modes.rigor` defaults to `minimal`, which resolves `team.size` to
`individual`.

**Announce the active set before Phase 1 — never let the collapse be silent.**
Before spawning anything, state in one line which agents this run will actually
spawn, and which the pipeline below names but will **not** spawn at the resolved
`team.size`. For example:

> `Active set (team.size: <resolved>): <the agents listed for that size above>.`
> `Not spawned this run: <every other agent this pipeline names> — consulted`
> `through <nearest active core agent>. Raise team.size (or modes.rigor) to widen.`

Fill it from the `team.size` list directly above and the agents this file's own
pipeline names — not from an example. Both sets differ per orchestrator.

The pipeline below reads as a multi-agent fan-out and at the shipped default it
is one or two agents — `team-release` names nine agents and at `individual` runs
`release-manager` alone; `team-content` names four and at the same size runs
`ux-writer` alone. **The collapse
is correct**: `team.size` is rigor-fronted and the narrow default is the token
lever, measured at roughly 10x. What was wrong is that nothing said so, so a reader
could not distinguish a correctly-collapsed run from a broken pipeline, and the
per-agent "routes through the nearest core agent with an informational note" rule
above fires at routing time and never states the shape of the run as a whole.

This is the same rule as the skipped-check reporting elsewhere in this file: **a constraint that is enforced but never surfaced is
indistinguishable, to the person reading the output, from one that was never
enforced.**

## Team Composition

- **qa-lead** — QA strategy, test plan generation, story classification, the QL-TEST-COVERAGE gate, sign-off report
- **qa-engineer** — Test case writing, bug report writing, exploratory and manual QA documentation
- **accessibility-specialist** (`studio` only) — accessibility pass of UI and E2E stories: keyboard and
  focus order, screen reader (VoiceOver / TalkBack), contrast, target size, text scaling, axe results

## How to Delegate

Use the `Agent` tool to spawn each team member as a subagent:
- `subagent_type: qa-lead` — Strategy, planning, classification, the coverage gate, sign-off
- `subagent_type: qa-engineer` — Test case writing and bug report writing
- `subagent_type: accessibility-specialist` — Accessibility pass (`studio` only)

**Brief each agent — do not dump context.** Read the shared inputs **once** and pass a distilled brief inline: the lines each agent actually needs, never a file path for a document you have already read (an agent handed a path re-reads the whole file). Pass a path only for a document you have not read and only that agent needs.

**End every agent prompt with a return contract:** "Write your full output to `[path]` — that named path is your write authorisation under the bounded exception below, so write it without a separate approval prompt. Return **only** (1) the path written, (2) a ≤5-bullet summary of decisions, (3) any BLOCKED/CONCERNS items, one line each. Do not restate the documents you read." Without it, an agent returns everything it read back into this session.

> **Why this does not violate the Collaboration Protocol.** `CLAUDE.md` requires an agent to ask "May I write this to [filepath]?" before Write/Edit. A subagent spawned here writes **without** asking, and that is a deliberate, bounded exception rather than an oversight — the same call already made for `consistency-check` appending to `active.md`. The exception holds only when all three are true: (1) the path is one **you** named in the prompt, so the user approved the destination when they approved the phase; (2) it is a new artifact under `production/`, `docs/` or `tests/`, never an edit to existing source or config; (3) the phase that produced it is itself gated by an `AskUserQuestion` before the pipeline advances. Outside those three, the agent must ask. **Do not "fix" this by asking per subagent** — a prompt per agent per phase makes an orchestrator unusable, which is why the exception exists.

Launch independent qa-engineer tasks in parallel where possible (e.g., one per feature in Phase 4, or several bug reports in Phase 5 with pre-assigned numbers).

## Pipeline

### Phase 1: Load Context

Before doing anything else, gather the full scope:

1. Detect the current sprint or feature scope from the argument:
   - If argument is a sprint identifier (e.g., `sprint-03`): Glob `production/sprints/` for files matching `*[sprint-identifier]*.md`. Read the matched file. If multiple match, use the most recently modified.
   - If argument is `feature: <feature-slug>`: glob `production/epics/*/story-*.md` and keep the stories whose `**PRD**:` line names `design/prd/<feature-slug>.md`
   - If no argument: read `production/session-state/active.md` and `production/sprint-status.yaml` (if present) to infer the active sprint; report the inferred sprint before proceeding. If neither file names one, ask with `AskUserQuestion` which sprint or feature QA should cover — never guess.

2. Take `project.stage` from the resolved block (`not set` ⇒ report "stage: not set").

3. Count stories found and report to the user:
   > "QA cycle starting for [sprint/feature]. Found [N] stories. Current stage: [stage]. Ready to begin QA strategy?"

   **Zero stories ⇒ stop.** Report `NOT ASSESSED — no stories in scope`, name the scope searched and
   the path that was empty, and route to `/sprint-plan` or `/create-stories`. A QA cycle over nothing
   produces a sign-off that looks like a clean one.

### Phase 2: QA Strategy (qa-lead)

Spawn `qa-lead` via `Agent` to review all in-scope stories and produce a QA strategy.

Prompt the qa-lead to:
- Read each story file
- Classify each story by type: **Logic** / **Integration** / **UI** / **E2E** / **Config** (the story's `> **Type**:` header is authoritative when present)
- Identify which stories require automated test evidence vs. manual QA, and which carry a `**Migration**` (the migration dry-run log is required at every `qa.level`)
- Flag any stories with missing acceptance criteria or missing test evidence that would block QA
- Estimate manual QA effort (number of test sessions needed, per surface)
- **Before assessing smoke status, check for an existing smoke check report**: Glob `production/qa/smoke-*.md` and read the most recently modified file (if found). If a report exists, take its verdict from its `> **Verdict**:` line and its findings directly — do not re-interview the user — and note the environment it ran against (staging or local). If no report exists, or its verdict line is missing or unreadable, the smoke status is **NOT ASSESSED** — never PASS WITH WARNINGS — and the note reads: "No usable smoke check report — run `/smoke-check sprint` before proceeding." Produce a smoke check status: **PASS** / **PASS WITH WARNINGS [list]** / **FAIL [list of failures]** / **NOT ASSESSED [reason]**
- Produce a strategy summary table and smoke check result:

  | Story | Type | Surface | Automated Required | Manual Required | Blocker? |
  |-------|------|---------|--------------------|-----------------|----------|

  **Smoke Check**: [PASS / PASS WITH WARNINGS / FAIL / NOT ASSESSED] — [source: `production/qa/smoke-YYYY-MM-DD.md` or "no report found"] — [details if not PASS]

If the smoke check result is **FAIL**, the qa-lead must list the failures prominently. QA cannot proceed past the strategy phase with a failed smoke check.

Present the qa-lead's full strategy to the user, then use `AskUserQuestion`:

```
question: "QA Strategy Review"
options:
  - "Looks good — proceed to test plan"
  - "Adjust story types before proceeding"
  - "Skip blocked stories and proceed with the rest"
  - "Smoke check failed or not assessed — run /smoke-check sprint, then re-run /team-qa"
  - "Cancel — resolve blockers first"
```

If smoke check **FAIL**: do not proceed to Phase 3. Surface the failures from the smoke check report and stop. The user must fix them, re-run `/smoke-check sprint`, and then re-run `/team-qa`.
If smoke check **NOT ASSESSED**: surface it — "No usable smoke check report — smoke status NOT ASSESSED. Recommend running `/smoke-check sprint` before QA." The user may proceed with test cases and manual QA, but the sign-off verdict cannot be APPROVED or APPROVED WITH CONDITIONS unless a PASS or PASS WITH WARNINGS smoke report exists when Phase 6 re-checks it.
If smoke check **PASS WITH WARNINGS**: note the warnings for the sign-off report and continue.
If blockers are present: list them explicitly. The user may choose to skip blocked stories or cancel the cycle.

### Phase 3: Test Plan Generation

Using the strategy from Phase 2, produce a structured test plan document from
`.claude/docs/templates/test-plan.md` — the same headings `/qa-plan` writes, so
`/smoke-check` finds `## Smoke Test Scope` and `/create-stories` finds
`## Automated Tests Required` in either file. Fill `> **Generated by**:` with
`/team-qa`. If a `/qa-plan` report for this sprint already exists, start from it
rather than re-deriving the per-story test content.

The test plan should cover:
- **Scope**: sprint/feature name, story count, dates, surfaces, test environment (header block)
- **Story Classification Table**: from Phase 2 strategy (`## Story Coverage Summary`)
- **Automated Test Requirements**: which stories need test files, expected paths per `testing.patterns` or under `tests/` (`## Automated Tests Required`)
- **Manual QA Scope**: which stories need manual walkthrough per surface and what to validate (`## Manual QA Checklist`)
- **Smoke scope, usability or beta needs, non-functional checks and the Definition of Done**: the template's remaining sections
- After the template's sections, three cycle sections:
  - `## Out of Scope` — what is explicitly not being tested this cycle and why
  - `## Entry Criteria` — what must be true before QA can begin. Always include: (1) a smoke check report with verdict PASS or PASS WITH WARNINGS exists at `production/qa/smoke-*.md` and names the environment it ran against, (2) the build under test is deployed to the test environment and boots (health endpoint 200, app launches), (3) all Must Have stories have `status: in-progress`, `review` or `done` in `production/sprint-status.yaml`. Add any sprint-specific criteria beyond these.
  - `## Exit Criteria` — what constitutes a completed QA cycle (every story PASS, PASS WITH NOTES, or FAIL with a bug filed; the coverage gate run or its skip recorded)

Ask: "May I write this to `production/qa/qa-plan-<sprint>-YYYY-MM-DD.md`?"

Write only after receiving approval.

### Phase 4: Test Case Writing (qa-engineer)

> **Smoke check** is performed as part of Phase 2 (QA Strategy). If the smoke check returned FAIL in Phase 2, the cycle was stopped there. This phase only runs when the Phase 2 smoke check was PASS, PASS WITH WARNINGS, or NOT ASSESSED with the user's explicit decision to proceed.

Group the stories requiring manual QA (UI, E2E surfaces without automated coverage, Integration without automated tests) by feature — the slug of each story's `**PRD**:` line.

Spawn `qa-engineer` via `Agent` once per feature (run in parallel where possible), providing:
- The story file paths of that feature
- The relevant section of the QA plan for those stories
- The PRD acceptance criteria and edge cases for the feature being tested (if available)
- Instructions to write detailed test cases covering all acceptance criteria, per surface
- **The output path: `production/qa/test-cases/<feature>-cases.md`.** Name it
  explicitly in the prompt, one per feature.

> **Why the path is stated here rather than left to the orchestrator.** The
> bounded write exception above holds only when "the path is one **you** named in
> the prompt". This is the phase that spawns agents *in parallel*, so it is where
> an unnamed destination does the most damage: each agent improvises its own, and
> two runs file the same artifact in two places. The phase reads correctly right
> up until two agents need somewhere to put their output.

Each test-case file uses the qa-engineer's test case format: one heading per story
(or area), and under it one `### Test Case: [ID] — [Short name]` block per case with
the four labeled fields:
- **Precondition**: account, data, feature-flag and device state required before testing begins (seeded test accounts only — never real personal data)
- **Steps**: numbered, unambiguous actions
- **Expected Result**: what should happen
- **Pass Criteria**: a measurable, binary condition

followed by two execution lines left blank for the tester: **Actual Result** and
**Pass/Fail**.

Present the test cases to the user for review before execution. Group by story.

Use `AskUserQuestion` per story group (batched 3-4 at a time):

```
question: "Test cases ready for [Story Group]. Review before manual QA begins?"
options:
  - "Approved — begin manual QA for these stories"
  - "Revise test cases for [story name]"
  - "Skip manual QA for [story name] — not ready"
```

### Phase 5: Manual QA Execution

Walk through each story in the approved manual QA list.

Batch stories into groups of 3-4 and use `AskUserQuestion` for each:

```
question: "Manual QA — [Story Title]\n[brief description of what to test, surface and environment]"
options:
  - "PASS — all acceptance criteria verified"
  - "PASS WITH NOTES — minor issues found (describe after)"
  - "FAIL — criteria not met (describe after)"
  - "BLOCKED — cannot test yet (reason)"
```

After each FAIL result: use `AskUserQuestion` to collect the failure description (what broke, surface, environment and build, account and flags, request or trace id if seen), then spawn `qa-engineer` via `Agent` to write a formal bug report following the `/bug-report` template — exact ladder strings `**Severity**: [S1-Critical / S2-Major / S3-Minor / S4-Trivial]` and `**Priority**: [P1-Fix this sprint / P2-Fix soon / P3-Backlog / P4-Won't fix]`, `**Status**: Open`, and the service environment block.

**Bug report naming: `production/qa/bugs/BUG-NNNN.md`** — four digits, no slug; the same file name `/bug-report` writes, so `/bug-report verify <BUG-ID>` and `/bug-triage` find it. Before spawning, glob `production/qa/bugs/BUG-*.md`, take the highest number, add one (first bug: `BUG-0001`), and name that exact path in the prompt. When several bug reports are spawned in parallel, pre-assign consecutive numbers so no two agents write the same file.

**After each PASS or PASS WITH NOTES on a UI or E2E story, write the
evidence record** into the story's evidence directory
`production/qa/evidence/<story-slug>/`, from
`.claude/docs/templates/test-evidence.md` (file name as that template's location
line gives it: `evidence.md`, `<story-slug>` = the story file name without `.md`),
carrying its sign-off rows intact and its `> **Verdict**:` line equal to the
`Run result:` token. If `/dev-story` already wrote `evidence.md`, read it and write it
back with the manual QA results added — never drop what it recorded. Ask
"May I write this to `production/qa/evidence/<story-slug>/evidence.md`?" first. The screenshots the
tester took — each state touched, desktop and mobile viewport or device — go into
the same directory and are referenced from the record (for web, the run-and-observe
capture script `tests/e2e/capture.spec.ts` produces them); `/story-done` checks for
retained images and traces, not just the write-up.

> **This is not optional bookkeeping — it is the artifact the next skill gates
> on.** `/story-done` globs `production/qa/evidence/<story-slug>/` for UI and E2E
> stories and reads the sign-off rows; `/test-evidence-review` and the
> QL-TEST-COVERAGE gate read the same directory. Write anywhere else and a story
> can pass a full manual QA cycle here, then be told by `/story-done` that no
> evidence exists. UI and E2E gates are **BLOCKING by default**, so that is a
> deadlock — QA passed, story cannot close. It is a merely confusing flag only
> where `testing.strict.ui` or `testing.strict.e2e` has been explicitly set to
> `false`. (The five `testing.strict` keys are `logic`, `integration`, `ui`, `e2e`
> and `config`.) Never write evidence under `production/session-logs/` — it is
> gitignored, so it is not evidence.
>
> Leave the sign-off rows **unchecked** unless the sign-off actually happened in
> this session. An evidence file with pre-ticked approvals is worse than none: it
> converts a missing signature into a recorded one.

**Accessibility pass (`studio` only).** After manual QA of each feature's UI and
E2E stories, spawn `accessibility-specialist` via `Agent` with the story paths, the
evidence directories and the `> **Target**:` line of
`design/accessibility-requirements.md` (absent ⇒ "target not set"). It reviews the
axe results in the evidence (`NN-<state>-axe.json`), walks keyboard and focus order,
and gives the user a short screen-reader checklist (VoiceOver / TalkBack) to run. It
writes no file, so its return contract names no path: it returns only a PASS / FAIL
line per story, a ≤5-bullet summary of findings, and any BLOCKED items. Each failure
is collected and filed as a bug exactly like a FAIL above. At `individual` and `small`, say so in
the results: "accessibility pass not run — accessibility-specialist is not in the
active set; only the axe results in the evidence were checked."

After collecting all results, summarize:
- Stories PASS: [count]
- Stories PASS WITH NOTES: [count]
- Stories FAIL: [count] — bugs filed: [IDs]
- Stories BLOCKED: [count]

### Phase 5b: Test Coverage Review (QL-TEST-COVERAGE)

Immediately before the sign-off phase, apply the review-mode check of Phase 0 to
**QL-TEST-COVERAGE**. When it is skipped, carry the note —
`[QL-TEST-COVERAGE] skipped — Lean mode` (or `— Solo mode`) — into the sign-off
report where the gate's review line would go, and name the omission in the summary:
"QL-TEST-COVERAGE not consulted — <Mode> mode; `--review full` runs it."

When it runs, spawn `qa-lead` via `Agent` (at every `team.size` — team-size scoping
never removes a director gate):
- Gate: **QL-TEST-COVERAGE** — the prompt instructs the agent to read
  `.claude/docs/director-gates/ql-test-coverage.md` first (do not read it or paste it yourself).
- Pass: story path(s) or sprint id · test file paths · evidence directory paths · resolved `testing.strict` and `qa.level` lines
- Fill them from Phases 1–5: the sprint id (or the story paths for `feature:` scope);
  the test files named in the QA plan that exist on disk; the
  `production/qa/evidence/<story-slug>/` directories of the stories in scope. Pass the resolved `testing.strict` and `qa.level` lines as printed.
- Await the verdict before continuing.

Parse the first line of the reply as `[QL-TEST-COVERAGE]: TOKEN`, TOKEN one of
`ADEQUATE`, `GAPS`, `INADEQUATE`, and map it with the verdict classes of
`.claude/docs/director-gates.md` (`## Standard Verdict Format`):

- **APPROVE-class** (`ADEQUATE`) → continue to Phase 6; record
  `> **QA Lead Review (QL-TEST-COVERAGE)**: APPROVED [date]` in the sign-off report.
- **CONCERNS-class** (`GAPS`) → present the gaps via `AskUserQuestion`:
  `Revise flagged items` / `Accept and proceed` / `Discuss further`. Revising means
  the missing tests or evidence are produced and the gate is spawned again (record
  `REVISED [date]`); accepting records `CONCERNS (accepted) [date]` and each gap
  becomes a condition in the sign-off report.
- **REJECT-class** (`INADEQUATE`) → present the blockers. Do not sign off on them:
  either the missing coverage is produced and the gate is spawned again, or Phase 6
  runs with the blockers listed and the sign-off verdict is NOT APPROVED.
- A first line that does not parse, or names another gate, is not an approval —
  treat it as CONCERNS-class and say the verdict line was missing.

### Phase 6: QA Sign-Off Report

Re-check the smoke report first: glob `production/qa/smoke-*.md` again and read the
newest file's `> **Verdict**:` line (a report may have been produced since Phase 2).

Spawn `qa-lead` via `Agent` to draft the sign-off report using all results from Phases 2–5b (at `individual`, route it through `qa-engineer` with the informational note). The agent returns the draft; this skill writes the file after the user approves it, so the prompt names no output path.

The sign-off report format:

```markdown
# QA Sign-Off Report: [Sprint/Feature]

> **Verdict**: [APPROVED | APPROVED WITH CONDITIONS | NOT APPROVED | NOT ASSESSED]
> **Date**: [YYYY-MM-DD]
> **Scope**: [sprint id or feature slug] — [N] stories
> **Environment**: [staging URL or preview deploy; build / app version under test]
> **Smoke Check**: [PASS | PASS WITH WARNINGS | FAIL | NOT ASSESSED] — [`production/qa/smoke-YYYY-MM-DD.md` or "no report found"]
> **QA Lead Review (QL-TEST-COVERAGE)**: [APPROVED [date] | CONCERNS (accepted) [date] | REVISED [date]] — or the skip note `[QL-TEST-COVERAGE] skipped — Lean mode` / `— Solo mode`

## Test Coverage Summary

| Story | Type | Surface | Auto Test | Manual QA | Result |
|-------|------|---------|-----------|-----------|--------|
| [title] | Logic | api | PASS | — | PASS |
| [title] | UI | web, ios | — | PASS | PASS |
| [title] | E2E | web | PASS | PASS WITH NOTES | PASS WITH NOTES |

## Bugs Found

| ID | Story | Severity | Priority | Status |
|----|-------|----------|----------|--------|
| BUG-0001 | [story] | S2-Major | P1-Fix this sprint | Open |

## Conditions

[list what must be fixed before the build advances, or "None"]

## Next Step

[guidance based on verdict]
```

**Status values** (`**Status**:` line): `Open | In Progress | Fixed — Pending Verification | Verified Fixed | Closed | Won't Fix`.

**Unresolved** = Status ∈ {`Open`, `In Progress`, `Fixed — Pending Verification`}. `Verified Fixed`,
`Closed` and `Won't Fix` are resolved. Every bug count below uses this definition — never `Open` alone.

Verdict rules:

**Precondition, checked first.** APPROVED and APPROVED WITH CONDITIONS both
require that **every story in scope produced executed evidence** — a test that
ran, or a manual case that was walked — and a smoke report with verdict PASS or
PASS WITH WARNINGS. If any story is BLOCKED, unexecuted, or has no evidence, or
the smoke status is NOT ASSESSED, the verdict is **NOT ASSESSED** — unless a known
failure already decides it: an unresolved S1/S2 bug or a story FAIL without a
documented workaround makes it **NOT APPROVED**, because a known failure is more
actionable than an unknown and must not be buried behind it.

- **NOT ASSESSED — NO EVIDENCE**: One or more stories produced no executed
  evidence (BLOCKED, tests not written, cases not walked), or the smoke status is
  NOT ASSESSED, and no known failure applies. This is **not** a pass and **not** a
  fail; it means QA did not happen. Say which stories and why.
- **APPROVED**: All stories PASS or PASS WITH NOTES; no unresolved S1/S2 bugs; the coverage gate ADEQUATE or skipped with its note
- **APPROVED WITH CONDITIONS**: Unresolved S3/S4 bugs, PASS WITH NOTES issues documented, or accepted QL-TEST-COVERAGE gaps; no unresolved S1/S2 bugs
- **NOT APPROVED**: Any unresolved S1/S2 bug; or stories FAIL without documented workaround; or a QL-TEST-COVERAGE INADEQUATE verdict that was not resolved

> **Why the precondition exists.** The three rules below it assume
> every story resolves to PASS or FAIL. A sprint where nothing was executed
> trips none of the NOT APPROVED conditions and **vacuously satisfies "no
> unresolved S1/S2 bugs"** — because zero executed tests means zero observed
> failures. Read literally, and without this precondition, the rules let a
> completely untested build reach APPROVED — a `qa-lead` reaching NOT APPROVED on
> intent would find the letter of the rules did not support it. A
> sign-off asserts verified quality; without this precondition the rules cannot
> tell "verified good" from "never looked".

Next step guidance by verdict:
- NOT ASSESSED: "QA did not run to completion. Produce the missing evidence — write the Logic, Integration and E2E tests, walk the manual cases, run `/smoke-check sprint` — then re-run `/team-qa`. Do not advance the build on this verdict."
- APPROVED: "Build is ready for the next phase. Run `/gate-check hardening` (from Build) or `/gate-check launch` (from Hardening) to validate advancement."
- APPROVED WITH CONDITIONS: "Resolve conditions before advancing. S3/S4 bugs may be deferred to a later sprint — record them with `/bug-triage`."
- NOT APPROVED: "Resolve S1/S2 bugs and re-run `/team-qa` or targeted manual QA before advancing. Verify each fix with `/bug-report verify <BUG-ID>`."

Ask: "May I write this to `production/qa/qa-signoff-<sprint>-YYYY-MM-DD.md`?"

Write only after receiving approval.

## Error Recovery Protocol

**First, verify the artifact.** If the return contract named a path, check the
path exists before treating the phase as done — **a named artifact that is not
on disk is a failed phase, however fluent the response reads.** An agent can
burn a full phase and return a plausible preamble having written nothing, which
is neither BLOCKED nor an error nor "cannot complete", so the trigger below
never fires. Resume it naming the unmet contract; the context is
usually still there.

If any spawned agent returns BLOCKED, errors, or cannot complete: **surface it
immediately, don't proceed past a dependency it blocks, and always produce a
partial report.** Full procedure: `.claude/docs/error-recovery-protocol.md`.

Common blockers:
- Input file missing (story not found, PRD absent) → redirect to the skill that creates it
- ADR status is Proposed → do not implement; run `/architecture-decision` first
- Scope too large → split into two stories via `/create-stories`
- Conflicting instructions between ADR and story → surface the conflict, do not guess
- Test environment down or the build not deployed → the affected stories are BLOCKED, not FAIL

## Output

A summary covering: stories in scope, smoke check result, manual QA results, bugs filed (with IDs and severities), the QL-TEST-COVERAGE outcome (verdict or skip note), and the final APPROVED / APPROVED WITH CONDITIONS / NOT APPROVED / NOT ASSESSED verdict.

Verdict: **COMPLETE** — QA cycle finished.
Verdict: **NOT ASSESSED** — the cycle could not assess its scope: no stories in scope (the Phase 1 stop, no sign-off report written), or the sign-off verdict is NOT ASSESSED (a story without executed evidence, or no PASS / PASS WITH WARNINGS smoke report); name each.
Verdict: **BLOCKED** — smoke check failed or critical blocker prevented cycle completion; partial report produced.

Precedence: BLOCKED > NOT ASSESSED > COMPLETE.

## Session State Update

After the final phase completes (sign-off report written, or a BLOCKED or NOT ASSESSED stop reached), silently append to `production/session-state/active.md`:

```
<!-- QA RUN: [date] | Sprint: [sprint identifier or "ad-hoc"] | Verdict: [APPROVED/APPROVED WITH CONDITIONS/NOT APPROVED/NOT ASSESSED/BLOCKED] | Report: production/qa/qa-signoff-[sprint]-[date].md -->
```
