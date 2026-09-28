---
name: story-done
description: "Verify acceptance criteria and evidence, PRD/ADR/API deviations, code review; close the story."
argument-hint: "[story-file-path] [--review full|lean|solo]"
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, AskUserQuestion, Agent, Bash(bash "*/.claude/skills/story-done/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,story_granularity,qa.level,testing.strict,feature_overrides,code_roots`

Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).


# Story Done

This skill closes the loop between design and implementation. Run it at the end of
implementing any story. It ensures every acceptance criterion is verified before the
story is marked done, that the evidence the story type requires is on disk, that PRD,
ADR and API-contract deviations are explicitly documented rather than silently
introduced, that code review happens rather than being forgotten, and that the story
file and the sprint status reflect actual completion.

**Output:** the updated story file (`> **Status**: Complete` + `## Completion
Notes`), the story's entry in `production/sprint-status.yaml` set to `status: done`,
and the next story surfaced.

---

## Phase 1: Find the Story

See `.claude/docs/director-gates.md` for the full check pattern. Individual gate
definitions live in `.claude/docs/director-gates/<gate-id>.md` — the spawned agent
reads its own gate file; do not read it in the parent session.

**Workflow tier**: resolved per the story's feature (per
`.claude/docs/workflow-modes.md`) — **the PRD filename stem** of the story's
`**PRD**:` path (`design/prd/<stem>.md` → `<stem>`), with the `<feature-slug>`
segment of its `TR-<feature-slug>-NNN` ID accepted only as a fallback when the story
has no `**PRD**:` line: use the `feature_overrides` entry for that stem if the block
lists one, else the project `workflow` value. It governs which Phase 4 deviation
checks run — see Phase 4.

**Workflow companion — `modes.story_granularity`** (resolved above — supplied by
`modes.rigor` unless set explicitly): cadence expectation only — story-done fires
**every 3–5 days** at `coarse`, **every 1–2 days** at `balanced`, **multiple
times a day** at `fine`. It does not change any completion check.

**`qa.level`**: controls whether test *evidence is required*, where `testing.strict`
controls whether a gap blocks and `workflow` controls which documents exist.
`modes.rigor` sets `qa.level` and `workflow` together; set either explicitly to vary
it alone. `testing.strict` is not fronted by `rigor` at all. At `minimal`, no
per-story evidence is required → skip the per-type Test Evidence Requirement check
(Phase 3), the >50%-untested traceability escalation, and the Phase 4b QA gate; the
acceptance-criteria verification still runs, and so do the **migration floor** and
the **run result** check — `qa.level` never waives those. At `standard`, the story's
own type requires evidence; at `full`, every type does. `testing.strict` then decides
whether missing or failing evidence blocks.

**Code roots**: the `code_roots` line lists where the story's code can live. Every
code scan below (hardcoded values, hardcoded strings, PII in logs, contract drift)
runs over those roots. If the line reads `code_roots: unresolved — NOT CHECKED …`,
each such check reports
`NOT CHECKED — no code root resolved (set stack.layers.<layer>.root via /setup-stack)`
instead of zero hits. If undeclared roots are listed, include them and print
`WARN: undeclared code roots: <dirs> — declare them with /setup-stack`.

**If a file path is provided** (e.g.,
`/story-done production/epics/goals-core/story-001-create-goal.md`): read that file
directly.

**If no argument is provided:**

1. Check `production/session-state/active.md` for the currently active story.
2. If not found there, read `production/sprint-status.yaml` and collect the entries
   with `status: in-progress` or `status: review`; if that file is absent, read the
   most recent file in `production/sprints/` and look for stories marked In Progress.
3. If several are found, use `AskUserQuestion`:
   - "Which story are we completing?"
   - Options: the in-progress story file names.
4. If no story can be found, ask the user for the path.

---

## Phase 2: Read the Story

Read the full story file. Extract and hold in context:

- **Story name and ID**
- **PRD requirement TR-ID(s)** (e.g., `TR-goals-001`) and the `**PRD**:` path
- **Manifest Version** from the header (e.g., `2026-10-02`)
- **ADR reference(s)**
- **Acceptance Criteria** — the complete list (every checkbox item)
- **Story Type** — `> **Type**:` (`Logic | Integration | UI | E2E | Config`)
- **Surface** — `> **Surface**:` (comma list, first value primary)
- **API Contract**, **Migration**, **Feature Flag**, **Analytics Events** — the
  story's `**…**:` fields (`None` means none)
- **Stack notes** — `**Stack**:`, `**Risk**:`, `**Stack Notes**:`
- **Definition of Done** — if present, the story-level DoD
- **Estimated vs actual scope** — if an estimate was noted

**Changed files.** Take the list from the `/dev-story` session extract ("Files
changed") in `production/session-state/active.md`; else from `git status --porcelain`
and `git diff --name-only` (read-only) restricted to the code roots, the migrations
directory and the test locations; else ask the user. Record where the list came from
— the code review and the deviation checks run over it.

Also read:
- `docs/architecture/tr-registry.yaml` — grep the story's TR-IDs
  (`Grep pattern="id: <each TR-ID>" path="docs/architecture/tr-registry.yaml" output_mode="content" -A 8`
  — enough to reach the entry's `status:` after the optional `type:` / `nfr_category:`),
  not a full read. The *current* `requirement` text of each entry is the source of
  truth for what the PRD requires — do not use requirement text quoted in the story
  (it may be stale).
- The PRD — just the `## Acceptance Criteria` and the rules of this requirement in
  `## Functional Requirements` / `## Business Rules & Calculations`, plus the
  `## Configuration & Flags` row of the story's flag. Use it to cross-check that the
  registry text is still accurate.
- The referenced ADR(s) — **just the `## Decision` and `## Consequences` sections,
  never an unbounded full read.** Map headings first
  (`Grep pattern="^## " path="docs/architecture/[adr-file].md" output_mode="content" -n`),
  then bounded-`Read` only those two spans. This is the same content Phase 4 check 3
  needs — hold it here, do not re-read it there.
- `docs/architecture/control-manifest.md` header — the current `Manifest Version:`
  date (Phase 4 staleness check).
- The API contract operation the story names, the migration plan's `## Status`
  section, and the story's events in the `## Events` table of
  `design/product/tracking-plan.md` — each only when the story's field is not `None`.
- The evidence directory `production/qa/evidence/<story-slug>/` (`<story-slug>` = the
  story file name without `.md`) — list it; read `evidence.md` if present.

---

## Phase 3: Verify Acceptance Criteria

For each acceptance criterion, attempt verification by one of three methods.

### Automatic verification (run without asking)

- **File existence check**: `Glob` for the files the story said would be created.
- **Test pass check**: when `commands.test` is set in `project.yaml` (read it with
  Read), run the story's own test files through it via `Bash` (scoped to those files
  when the runner accepts a path) and record pass/fail per criterion. When it is
  unset, print `NOT CHECKED — test results (commands.test unset)` — existence is then
  all this skill can establish for those criteria.
- **No hardcoded values check**: `Grep` the changed files under the code roots for
  numeric literals in domain code that belong in configuration or the pricing model —
  prices, fees, limits, quotas, time windows (`15000`, `0.029`, `30 * 24 * 60`).
- **No hardcoded strings check**: `Grep` the changed UI files under the code roots for
  user-facing strings that belong in localization resources. **If no code root
  resolves, report
  `NOT CHECKED — no code root resolved (set stack.layers.<layer>.root via /setup-stack)`
  rather than zero hits.**
- **Dependency check**: if a criterion says "depends on X", check that X exists.

### Manual verification with confirmation (use `AskUserQuestion`)

- Criteria about subjective qualities ("the confirmation feels trustworthy", "the
  progress ring animation is smooth")
- Criteria about behaviour only a running environment shows ("the 알림톡 arrives
  after the first auto-debit", "the goal list refreshes after pull-to-refresh")
- Performance criteria ("p95 under 300 ms") — ask whether it was measured or accept
  as assumed

Batch up to 4 manual verification questions into a single `AskUserQuestion` call:

```
question: "Does [criterion]?"
options: "Yes — passes", "No — fails", "Not tested yet"
```

### Unverifiable (flag without blocking)

- Criteria that need a deployed environment or a third-party sandbox not reachable
  from here — mark `DEFERRED — requires staging environment`
- Criteria about comprehension or trust that only real users can settle — mark
  `DEFERRED — requires usability session`

### Test-Criterion Traceability

After the pass/fail/deferred check above, map each acceptance criterion to the test
or evidence that covers it:

1. Is there a test — unit, integration, contract, E2E, or a confirmed manual check —
   that directly verifies this criterion?
   - **Unit / integration / contract tests**: search where `testing.patterns` places
     them (co-located `*.test.ts`, `tests/unit/<feature>/`,
     `tests/integration/<feature>/`, `tests/contract/<feature>/`) for a test whose
     name matches the criterion's subject (`Glob` and `Grep`)
   - **E2E tests**: `tests/e2e/<journey>/`
   - **Manual confirmation**: a "Yes — passes" answer above counts as a manual test
   - **Retained evidence**: if the criterion names something on screen or in an API
     response and a retained capture under `production/qa/evidence/<story-slug>/`
     shows it (the `Run result: OBSERVED` from `/dev-story` Phase 6 step 4), count it
     as covered — put the path in the Test column. A visual criterion verified by
     looking is not UNTESTED; without this row every UI story reads as >50% untested
     and false-escalates.

2. Produce a traceability table:

```
| Criterion | Test | Status |
|-----------|------|--------|
| AC-1: [criterion text] | apps/api/src/goals/goals.service.test.ts › rejects a past target date | COVERED |
| AC-2: [criterion text] | Manual confirmation | COVERED |
| AC-3: [criterion text] | production/qa/evidence/story-001-create-goal/02-validation-error-mobile.png | COVERED |
| AC-4: [criterion text] | — | UNTESTED |
```

3. Apply these escalation rules (skip entirely at `qa.level: minimal` — no evidence is
   required, so untested criteria never escalate):

   - **>50% of criteria UNTESTED**: escalate to **BLOCKING** — coverage is
     insufficient to confirm the story is done. The Phase 6 verdict cannot be COMPLETE
     until coverage improves.
   - **Some (≤50%) UNTESTED**: remain ADVISORY — does not block, but must appear in the
     Completion Notes.
   - **All COVERED**: no action beyond including the table in the report.

4. For any ADVISORY untested criteria, add to the Completion Notes in Phase 7:
   `"Untested criteria: [AC-N list]. Recommend adding tests in a follow-up story."`

### Test Evidence Requirement

**First apply `qa.level` (resolved in Phase 1).** At `minimal`, no per-type evidence
is required — skip the per-type checks below (the verdict rests on acceptance-criteria
verification), **but still run the migration floor and the run-result check at the
end of this subsection**. At `standard`, require evidence for the story's own type. At
`full`, require evidence for every story type. Only when evidence is required does the
`testing.strict` resolution below apply.

**Resolve the gate level for this story's type.** A gate level is either BLOCKING (a
gap prevents the COMPLETE verdict in Phase 6) or ADVISORY (a gap is noted in the
Completion Notes but does not block). Resolve it from the `testing.strict` line
**already resolved in the block at the top of this skill** — not by reading
`project.yaml` yourself:

1. Map the Story Type to a `testing.strict` key — `Logic`→`logic`,
   `Integration`→`integration`, `UI`→`ui`, `E2E`→`e2e`, `Config`→`config`. Take
   `testing.strict.<key>` from that resolved line. `true` (case-insensitive) →
   BLOCKING; `false` → ADVISORY; `unset` → the default in the table below.
2. A value other than `true`/`false` never reaches you: `resolve_config` drops an
   enum-invalid value and names it on its `notes:` line — surface that note to the
   user.

> **Use that resolved line, never `project.yaml` directly.** The five
> `testing.strict.*` keys are on the `/settings --local` whitelist, so a developer can
> set `testing.strict.logic=false` in `project.local.yaml` for fast WIP commits.
> Reading `project.yaml` alone silently ignores that file: the setting is accepted,
> displayed by `/settings`, and has no effect. The `resolve_config` block at the top of
> this skill already merges local over base.

| Story Type | Covers | Required Evidence | Location | Default Gate Level | `testing.strict` key |
|---|---|---|---|---|---|
| **Logic** | domain rules, calculations, validators, state machines | Automated unit test — must pass | per `testing.patterns` (co-located) or `tests/unit/<feature>/` | BLOCKING | `testing.strict.logic` |
| **Integration** | API handler + DB, queue consumers, third-party adapters, **contract tests** against `docs/api/` | Integration or contract test — must pass | `tests/integration/<feature>/`, `tests/contract/<feature>/` (or per `testing.patterns`) | BLOCKING | `testing.strict.integration` |
| **UI** | screens, components, visual states (incl. visual regression) | Component test and/or retained screenshots of each state touched (desktop + mobile viewport, or device) | `production/qa/evidence/<story-slug>/` | BLOCKING | `testing.strict.ui` |
| **E2E** | a critical user journey across UI → API → DB | Automated E2E test (Playwright / Cypress / Detox / Maestro) passing against a running environment, with trace/screenshot | `tests/e2e/<journey>/` + `production/qa/evidence/<story-slug>/` | BLOCKING | `testing.strict.e2e` |
| **Config** | feature flags, env config, pricing/limit tables | Smoke check pass | `production/qa/smoke-YYYY-MM-DD.md` | ADVISORY (`/smoke-check` unset ⇒ BLOCKING, intentional exception kept) | `testing.strict.config` |

**Migration floor.** A story whose `**Migration**` is not `None` (any Type) requires
`production/qa/evidence/<story-slug>/migration-dry-run.log` — Expand applied and
rolled back on a disposable database — **at every `qa.level` and regardless of
`testing.strict.config`**. Absent ⇒ BLOCKING.

The **Default Gate Level** column applies when `testing.strict` reports `unset` for
the type (the common case). UI and E2E default to BLOCKING because the rendered
screen and the working journey are what the user gets; set `testing.strict.ui` or
`testing.strict.e2e` to `false` for an advisory gate.

> **Exception — `/smoke-check`.** The ADVISORY default for **Config** above governs
> *per-story evidence* gates, which is what this skill checks. `/smoke-check` is a
> build-health gate, not a per-story evidence gate, so its own unset default for
> `testing.strict.config` is **BLOCKING** — see `.claude/skills/smoke-check/SKILL.md`.
> The divergence is intentional; do not "fix" either side to match the other.

> **This subsection checks that evidence EXISTS.** Each check below is a `Glob` or a
> `Grep`. Whether a test *passes* comes from the Test pass check in Automatic
> verification — which runs only when `commands.test` is set. Say which half you
> verified: "Test file present at `<path>`" is the claim this subsection can make;
> "tests pass" is a claim only when the Test pass check ran and passed. When nothing
> ran, pass/fail is established later by `/smoke-check` (before QA hand-off) and
> `/gate-check` (at a phase gate), both of which execute a suite.

**For Logic stories**: read the story's `## Test Evidence` section for the exact
required path and `Glob` it. If absent, also search where `testing.patterns` places
unit tests, then `tests/unit/<feature>/`. If no test file is found:
- Flag at the resolved gate level: "Logic story has no unit test file. Story requires
  it at `[exact-path-from-Test-Evidence]`. Create and run the test before marking this
  story Complete."

**For Integration stories**: `Glob` the exact `## Test Evidence` path first, then
`tests/integration/<feature>/` and `tests/contract/<feature>/` (or per
`testing.patterns`). If none is found: flag at the resolved gate level (same rule as
Logic). A story with an `**API Contract**` needs a contract test for its operation.

**For UI stories**: look for component tests for the states the story touched, and
for retained screenshots (`*.png`, `*.jpg`) in `production/qa/evidence/<story-slug>/`
— desktop and mobile viewport for web, or device captures for mobile.
- Neither found: flag at the resolved gate level — "No UI evidence found. Capture each
  state this story touched (`.claude/docs/run-and-observe.md`) into
  `production/qa/evidence/<story-slug>/`, or add component tests for them, before
  closing."
- `evidence.md` exists but no capture is retained beside it: flag at the resolved gate
  level — "Evidence record found at `[path]` but no screenshot is retained. A described
  check is an assertion, not evidence."
- If `evidence.md` carries a sign-off table, Grep for unchecked rows
  (`| .* | .* | .* | \[ \] Approved`). Unchecked sign-offs: flag at the resolved gate
  level — "[N] sign-off(s) still pending in `[path]`. Note: on a one-person team, one
  person may sign every role."
- Captures present (and any sign-offs complete): "UI evidence found — gate satisfied."

**For E2E stories**: `Glob` the E2E test under `tests/e2e/<journey>/` and its retained
trace or screenshots in `production/qa/evidence/<story-slug>/`. Either missing: flag
at the resolved gate level. An E2E test that exists but has never been run against a
running environment is not yet evidence — say so.

**For Config stories**: check for a `production/qa/smoke-*.md` report (prefer one dated
on or after the story's `> **Last Updated**:`). If none: flag at the resolved gate
level — "No smoke check report found. Run `/smoke-check`."

**Migration floor (every story, every `qa.level`)**: if `**Migration**` is not `None`,
`Glob` `production/qa/evidence/<story-slug>/migration-dry-run.log`. Absent: **BLOCKING**
— "Migration story without a dry-run log. Run the Expand phase against a disposable
database and roll it back (`/dev-story` Phase 6 step 5) before closing." This does not
consult `testing.strict`.

**Run result (every story, every `qa.level`)**: read the `Run result:` line — from
`production/qa/evidence/<story-slug>/evidence.md`, else from the `/dev-story` session
extract in `production/session-state/active.md`, else from the story's
`## Completion Notes`. The line and its three tokens are defined in
`.claude/docs/run-and-observe.md`.
- `OBSERVED` with a retained path: note it (and confirm the path exists).
- `N/A — <reason>`: accept only if the reason names why nothing is observable — "it's a
  Logic story" is not a reason.
- `NOT VERIFIED — <reason>` on a UI or E2E story, or on any story whose acceptance
  criteria name something on screen or in an API response: flag at the resolved gate
  level for the story's type.
- No `Run result:` line at all: flag as ADVISORY — "the implementation summary carries
  no run result; confirm the product was started and looked at before closure."

The retained capture **is** the `Run result: OBSERVED` from `/dev-story` Phase 6 step 4;
its absence means the run was `NOT VERIFIED` or never happened. The run is not waived at
`qa.level: minimal`. Evidence under `production/session-logs/` does not count — that
path is gitignored and never evidence.

**If no Story Type is set**: flag as **ADVISORY** — "Story Type not declared. Add
`> **Type**: [Logic | Integration | UI | E2E | Config]` to the story header to enable
test evidence gate enforcement."

Any BLOCKING test evidence gap prevents the COMPLETE verdict in Phase 6.

---

## Phase 4: Check for Deviations

Compare the implementation against the design documents.

> **Workflow tier adjustment** (resolved in Phase 1, per the story's feature). Checks
> 1 (PRD rules) and 3 (ADR constraints) below are the `full` baseline:
> - **`full`** — run both: full PRD traceability against the current TR text + the
>   ADR constraints check.
> - **`standard`** — run the PRD rules check against the **standard required sections**
>   (Overview, Goals & Non-Goals, Functional Requirements, Edge Cases, Dependencies,
>   Non-Functional Requirements, Success Metrics & Instrumentation, Acceptance
>   Criteria, plus Business Rules & Calculations when present); run the ADR
>   constraints check only where a **critical ADR** (Foundation layer) governs the
>   story.
> - **`minimal`** — **acceptance-criteria check only**: skip checks 1 and 3 (no PRD/ADR
>   traceability expected).
>
> Checks 2, 4 and 5 run at every tier as written. Checks 6–10 run at every tier
> whenever the story's field names something (a contract, a migration, a flag,
> events); check 9 always runs. This adjustment governs only the Phase 4 *deviation*
> checks. The test-evidence gates (Phase 3, Phase 4b) are governed by `qa.level` and
> `testing.strict`, not `workflow`.

Run these checks automatically:

1. **PRD rules check**: Using the current requirement text from `tr-registry.yaml`
   (looked up by the story's TR-ID), check that the implementation reflects what the
   PRD requires now — not what it required when the story was written. `Grep` the
   changed files for the entities, rules and field names the current requirement
   mentions.

2. **Manifest version staleness check**: Compare the story's `> **Manifest Version**:`
   with the `Manifest Version:` date in the current
   `docs/architecture/control-manifest.md` header.
   - Match → pass silently.
   - Story older → flag as ADVISORY:
     `ADVISORY: Story was written against manifest v[story-date]; current manifest is v[current-date]. New rules may apply. Run /story-readiness to check.`
   - The story carries `> **Manifest-Note**:` → carry the note into the deviations as
     accepted; do not re-check.
   - `control-manifest.md` does not exist → skip this check and say so.

3. **ADR constraints check**: Use the ADR's `## Decision` section already loaded in
   Phase 2 — do not read the ADR file again. Check for forbidden patterns from
   `docs/architecture/control-manifest.md` (if it exists) and from the
   `## Forbidden Patterns` of `docs/architecture/tech-radar.md` (if it exists). `Grep`
   for patterns explicitly forbidden in the ADR.

4. **Hardcoded values check**: `Grep` the changed files for numeric literals in domain
   logic that should be configuration (prices, fees, limits, quotas, time windows).

5. **Scope check**: Did the implementation touch files outside the story's stated scope
   (the files it named, inside its `## Out of Scope` boundary)?

6. **API contract drift** (`**API Contract**` ≠ `None`): the operation the story uses
   exists in the contract and matches the implementation — method and path, status
   codes, required request fields, response fields and types, the error model,
   pagination. A missing operation, a different status code, a missing required field
   or a type mismatch is **BLOCKING** (a client built from the contract breaks); a
   response field the contract does not declare is **ADVISORY** (declare it through
   `/api-design` or remove it).

7. **Migration plan phase state** (`**Migration**` ≠ `None`): the plan's `## Status`
   records the phase this story implemented (Expand written and dry-run evidence
   retained). The executable migration only adds or backfills — a drop or rename of
   something the running app still reads, inside an Expand story, is **BLOCKING**. A
   `## Status` not updated to the story's state is **ADVISORY**.

8. **Flag default recorded** (`**Feature Flag**` ≠ `None`): the flag's default is
   recorded — in the PRD's `## Configuration & Flags` row and in the flag definition
   the code reads — and the two agree. No recorded default, or a disagreement, is
   **BLOCKING**: a flag whose default nobody recorded can ship switched on by accident.
   Flag off must restore the previous behaviour; if the story's tests do not show it,
   that is **ADVISORY**.

9. **No PII in new log statements**: `Grep` the added lines of the changed files for
   logging calls (`console.log`, `logger.`, `log.`, `Log.d`, `print(`, `NSLog`,
   `Timber.`) that interpolate personal data — email, phone number, name, account
   number, resident registration number, card data, access tokens, request bodies
   dumped whole. Any hit is **BLOCKING**: log the entity ID, not the value.

10. **Tracking events present** (`**Analytics Events**` ≠ `None`): each event the story
    names exists in the `## Events` table of `design/product/tracking-plan.md`. An event
    missing from the tracking plan is **ADVISORY** ("add it to the tracking plan before
    release"). An event in the plan but not emitted anywhere in the changed files is
    **ADVISORY** unless an acceptance criterion names it, in which case the criterion
    fails (Phase 3).

For each deviation found, categorize:

- **BLOCKING** — implementation contradicts the PRD, the ADR or the contract, or breaks
  a privacy or migration rule (must fix before marking complete)
- **ADVISORY** — implementation drifts slightly from spec but is functionally
  equivalent (document; the user decides)
- **OUT OF SCOPE** — files were touched beyond the story's stated boundary (flag for
  awareness — may be valid or scope creep)

---

## Phase 4b: QA Coverage Gate

**Skip this phase at `qa.level: minimal`** (resolved in Phase 1) — no per-story
evidence is required, so there is no coverage to review. Note: "QL-TEST-COVERAGE
skipped — qa.level minimal." The migration floor was already checked in Phase 3.
Proceed to Phase 5.

**Skip for a `Config` story with no code and no migration** — there are no tests to
review. Note: "QL-TEST-COVERAGE skipped — Config story without code."

**Review mode check** — apply before spawning QL-TEST-COVERAGE:
- `solo` → skip all gates. Note: `[QL-TEST-COVERAGE] skipped — Solo mode`
- `lean` → **skip every gate whose ID does not end in `-PHASE-GATE`**. Note: `[GATE-ID] skipped — Lean mode` (here: `[QL-TEST-COVERAGE] skipped — Lean mode`)
- `full` → spawn as normal

Spawn `qa-lead` via `Agent` using gate **QL-TEST-COVERAGE**. The `Agent` prompt tells
the agent to read `.claude/docs/director-gates/ql-test-coverage.md` first (this session
does not read it).

Pass: story path(s) or sprint id · test file paths · evidence directory paths · resolved `testing.strict` and `qa.level` lines

Filled in at run time: this story's path; the test file paths found in Phase 3 (or
"none found"); `production/qa/evidence/<story-slug>/`; the `testing.strict:` and
`qa.level:` lines of the block above, copied as printed (including `unset`).

Parse the first line of the reply as `[QL-TEST-COVERAGE]: TOKEN` and map the token to
its class (`.claude/docs/director-gates.md` § "Standard Verdict Format"):
- **ADEQUATE** (APPROVE-class) → proceed to Phase 5
- **GAPS** (CONCERNS-class) → flag as **ADVISORY** and surface via `AskUserQuestion`
  (`Revise flagged items` / `Accept and proceed` / `Discuss further`): "QA lead
  identified coverage gaps: [list]. The story can complete, but the gaps should be
  addressed in a follow-up story."
- **INADEQUATE** (REJECT-class) → flag as **BLOCKING**: "QA lead: critical logic, a
  critical journey or the migration floor is untested. Verdict cannot be COMPLETE until
  coverage improves. Specific gaps: [list]."
- A first line that does not parse, or a token not on the gate's Verdicts line → treat
  as CONCERNS-class and say the verdict line was missing.

---

## Phase 5: Tech Lead Code Review Gate

**Review mode check** — apply before spawning TL-CODE-REVIEW:
- `solo` → skip all gates. Note: `[TL-CODE-REVIEW] skipped — Solo mode`
- `lean` → **skip every gate whose ID does not end in `-PHASE-GATE`**. Note: `[GATE-ID] skipped — Lean mode` (here: `[TL-CODE-REVIEW] skipped — Lean mode`)
- `full` → spawn as normal

**At `full`** — spawn `tech-lead` via `Agent` using gate **TL-CODE-REVIEW**. The
`Agent` prompt tells the agent to read `.claude/docs/director-gates/tl-code-review.md`
first (this session does not read it).

Pass: story path · changed file list · API contract path (or "none") · governing ADR path

Filled in at run time: this story's path; the changed file list from Phase 2; the
contract file the story's `**API Contract**` names (or "none"); the governing ADR's
path (or "none" when the story references no ADR).

Parse the first line of the reply as `[TL-CODE-REVIEW]: TOKEN` and map it to its class:
- **APPROVE** (APPROVE-class) → proceed to Phase 6.
- **CONCERNS** (CONCERNS-class) → surface via `AskUserQuestion`:
  `Revise flagged issues` / `Accept and proceed` / `Discuss further`. Accepted concerns
  are ADVISORY deviations.
- **REJECT** (REJECT-class) → a **BLOCKING** deviation: do not present a COMPLETE
  verdict until the issues are resolved.
- A first line that does not parse → CONCERNS-class, with the missing verdict line
  named.

**When the review mode skipped TL-CODE-REVIEW** (`lean` or `solo`), code review is not
skipped — it moves inline. Run the `/code-review` checklist yourself over the changed
files and record, in the report and the Completion Notes:

`Code review: inline checklist (TL-CODE-REVIEW skipped — <Mode> mode)`

(`<Mode>` is `Lean` or `Solo`.) The checklist:

1. **Contract conformance** — handlers match the contract operation (covered by Phase 4
   check 6; carry its findings).
2. **Authorization** — every new or changed operation checks the caller may act on this
   specific resource, not only that they are signed in; admin operations check roles;
   no mass assignment of fields such as `ownerId` or `plan`.
3. **Input validation** — request bodies, query parameters, webhooks and messages are
   schema-validated at the boundary.
4. **Data access** — no N+1 queries in loops; new queries have indexes; multi-write
   operations run in a transaction.
5. **Idempotency, timeouts, retries** — money-moving and webhook handlers are
   idempotent; outbound calls have timeouts and bounded retries.
6. **Pagination** — list endpoints paginate.
7. **Secrets and PII** — no secrets, keys or tokens in code, config or fixtures; no
   personal data in logs (Phase 4 check 9).
8. **Errors and operability** — errors logged with correlation IDs; the flag works as a
   kill switch.
9. **Tests** — assertions check behaviour; deterministic; no skipped tests.

A committed secret or a missing authorization check is **BLOCKING**; other findings
are ADVISORY unless they contradict the ADR or the contract.

**If the inline checklist cannot run** — the changed file list cannot be determined,
or the files cannot be read — print `NOT CHECKED — code review` and **cap the verdict
at COMPLETE WITH NOTES**: without a review the story cannot be COMPLETE.

If the story has no implementation files yet (run before coding is done), skip this
phase and note: "TL-CODE-REVIEW skipped — no implementation files found. Run after
implementation is complete."

---

## Phase 6: Present the Completion Report

Before updating any files, present the full report:

```markdown
## Story Done: [Story Name]
**Story**: [file path]
**Date**: [today]

### Acceptance Criteria: [X/Y passing]
- [x] [Criterion 1] — auto-verified (test passes)
- [x] [Criterion 2] — confirmed
- [ ] [Criterion 3] — FAILS: [reason]
- [?] [Criterion 4] — DEFERRED: requires staging environment

### Test-Criterion Traceability
| Criterion | Test | Status |
|-----------|------|--------|
| AC-1: [text] | [test file › test name] | COVERED |
| AC-2: [text] | Manual confirmation | COVERED |
| AC-3: [text] | — | UNTESTED |

### Test Evidence
**Story Type**: [Logic | Integration | UI | E2E | Config | Not declared]
**Required evidence**: [unit test | integration or contract test | component test and/or screenshots of each state | E2E test + trace/screenshot | smoke check pass]
**Evidence found**: [YES — `[path]` | NO — BLOCKING | NO — ADVISORY]
**Test results**: [N passed via commands.test | NOT CHECKED — test results (commands.test unset)]
**Migration dry-run**: [`production/qa/evidence/<story-slug>/migration-dry-run.log` | MISSING — BLOCKING | N/A — no migration]
**Run result**: [the Run result line, or "none recorded — ADVISORY"]

### Deviations
[NONE] OR:
- BLOCKING: [description] — [PRD/ADR/contract reference]
- ADVISORY: [description] — user accepted / flagged for tech debt

### Contract, Migration, Flag, Privacy, Events
- API contract: [matches | drift: … | N/A]
- Migration plan: [Status updated | …| N/A]
- Flag default: [recorded (off) | not recorded — BLOCKING | N/A]
- PII in logs: [none found | [file] — BLOCKING | NOT CHECKED — no code root resolved (…)]
- Tracking events: [all in tracking plan | missing: … | N/A]

### Code Review
[TL-CODE-REVIEW: APPROVE | CONCERNS (accepted) | REJECT] OR
[Code review: inline checklist (TL-CODE-REVIEW skipped — <Mode> mode) — findings: …] OR
[NOT CHECKED — code review]

### Scope
[All changes within stated scope] OR:
- Extra files touched: [list] — [note whether valid or scope creep]

### Verdict: COMPLETE / COMPLETE WITH NOTES / NOT ASSESSED / BLOCKED
```

**Verdict definitions:**
- **COMPLETE**: all criteria pass, no blocking deviations, code review done
- **COMPLETE WITH NOTES**: all criteria pass, advisory deviations documented — or code
  review could not run (`NOT CHECKED — code review`, which caps the verdict here)
- **NOT ASSESSED**: one or more acceptance criteria could not be evaluated at all —
  name which, and why
- **BLOCKED**: failing criteria or blocking deviations must be resolved first

**`NOT ASSESSED` — the story nobody could verify.** Rank: it **outranks COMPLETE and
COMPLETE WITH NOTES** (a review that could not evaluate a criterion has not shown the
criterion is met) and **ranks below BLOCKED** (a criterion known to fail is more
actionable than one nobody could check, and demoting it would bury it). It is not a
gentler BLOCKED: "this acceptance criterion fails" and "I could not tell whether it
passes" send the reader to different fixes.

**Verdict precedence — first matching rule wins**, evaluated in this order:
**BLOCKED**, then **NOT ASSESSED**, then **COMPLETE WITH NOTES**, then **COMPLETE**. A
run with both a failing criterion and an unassessable one is BLOCKED. Stating the order
mechanically, rather than leaving it to be inferred from the rank sentence, is what
keeps two reviewers from grading the same story differently.

Emit NOT ASSESSED when any of:

- An acceptance criterion **cannot be evaluated at all** — it names no observable
  outcome, so no evidence could settle it either way.
  > **Not the same as Phase 3's `DEFERRED`.** A criterion that is evaluable but needs a
  > staging run or a usability session is `DEFERRED`, it does **not** block, and Phase 3
  > keeps ownership of it. This trigger is for a criterion no session could ever settle
  > as written. If Phase 3 already marked it DEFERRED, that classification stands and
  > this trigger does not fire.
- The **test evidence is present but unreadable or unclassifiable** — corrupt, empty,
  or of a type that cannot be determined.
  > **Absent evidence is Phase 3's, not this trigger's.** Phase 3 resolves a missing
  > file through `testing.strict`: BLOCKING types produce **BLOCKED**, ADVISORY types
  > produce **COMPLETE WITH NOTES**. Both outrank or are already decided, so re-routing
  > "absent" here would silently override an explicit advisory ruling. *Unreadable* is
  > the genuinely unassessable case, and it is the only one this trigger claims.
- **`/test-evidence-review` returned `NOT ASSESSED`** for this story — applicable only
  when that skill was actually run against it, which this skill does not do itself. It
  propagates: that skill's whole point is that "could not check" is not "checked and
  fine", and collapsing its unknown into a COMPLETE here would undo the distinction one
  skill downstream. `coding-standards.md` marks Logic, Integration, UI and E2E evidence
  BLOCKING, so this is the path where an unverifiable story would otherwise acquire a
  verdict saying somebody verified it.
- A **deviation's severity cannot be determined** because the PRD, ADR or contract it
  would be judged against is missing.

A `NOT ASSESSED` verdict takes the same Phase 7 path as BLOCKED: do not automatically
proceed; list what could not be checked and what would make it checkable. Closing
anyway remains the user's explicit call, and Phase 7 always asks for it.

If the verdict is **BLOCKED**: do not *automatically* proceed to Phase 7. List what
must be fixed and offer to help fix the blocking items. This is the default path, not
an absolute stop — the user may still explicitly ask to close the story anyway despite
the blockers. That request is what routes to Phase 7's menu below, and Phase 7's
always-prompt rule is exactly what stands between that request and a silent close in
autonomous mode. Do not treat "do not automatically proceed" as "Phase 7 is now
unreachable" — it is reachable, on request, and gated when reached.

---

## Phase 7: Update Story Status

**Reached one of two ways**: normally, immediately after a COMPLETE or COMPLETE WITH
NOTES verdict in Phase 6; or, after a BLOCKED **or NOT ASSESSED** verdict, only if the
user explicitly asks to close the story despite the blockers (Phase 6 does not advance
here on its own in either case).

**Automation note**: This is the story-completion gate. Closing a story whose verdict is
BLOCKED (failing acceptance criteria or blocking deviations) **or NOT ASSESSED**
(criteria nobody could evaluate) — the "Accept deviations as-is and close anyway" option
— changes what the approved plan counts as done, so this gate **always prompts via
`AskUserQuestion`, regardless of `modes.automation`**: autonomous mode must NOT silently
close a BLOCKED or NOT ASSESSED story, even when the user's own request is what got you
here. For a COMPLETE or COMPLETE WITH NOTES verdict, autonomous mode may pick "Close the
story (Recommended)" and record it via `log_decision`.

Use `AskUserQuestion` before writing anything — this is the "May I write this to
`[story-path]` and `production/sprint-status.yaml`?" approval for both files:
- Prompt: "Verification complete. How do you want to proceed?"
- Options:
  - `Close the story — update the story file and production/sprint-status.yaml, log notes (Recommended)`
  - `Close and log advisory deviations as tech debt in docs/tech-debt-register.md`
  - `There are issues I want to fix first — don't close yet`
  - `Accept deviations as-is and close anyway`

If "Close", "Close and log tech debt", or "Accept deviations": edit the story file.
If "Close and log tech debt": after updating the story file, also append the advisory
deviations to `docs/tech-debt-register.md` — ask "May I write this to
`docs/tech-debt-register.md`?" first.
If "Fix first": stop here and list what the user flagged. Do not write any files.

1. Set `> **Status**: Complete`.
2. Set `> **Last Updated**:` to today (`YYYY-MM-DD`); add the line after
   `> **Status**:` if it is missing.
3. Add a `## Completion Notes` section at the bottom:

```markdown
## Completion Notes
**Completed**: [date]
**Verdict**: [COMPLETE / COMPLETE WITH NOTES / NOT ASSESSED / BLOCKED]
**Criteria**: [X/Y passing] ([any deferred items listed])
**Deviations**: [None] or [list of advisory deviations]
**Test Evidence**: [Logic: test at path | UI: captures in production/qa/evidence/<story-slug>/ | Config: smoke report path | waived at qa.level: minimal]
**Migration Dry-Run**: [production/qa/evidence/<story-slug>/migration-dry-run.log | N/A — no migration]
**Run Result**: [the Run result line]
**Code Review**: [TL-CODE-REVIEW: APPROVE | CONCERNS (accepted) | Code review: inline checklist (TL-CODE-REVIEW skipped — <Mode> mode) | NOT CHECKED — code review]
```

   When the story is closed over a BLOCKED or NOT ASSESSED verdict, add
   `**Override**: closed by user decision on [date] — [what failed, or which criteria
   were never evaluated]` so the gap is recoverable later rather than closed over.

4. If the user chose "Close and log tech debt": append each advisory deviation to
   `docs/tech-debt-register.md` in this format:
   ```
   - **[date]** ([story title]): [deviation description] — tracked from [story file path]
   ```
   Create the file with a `# Tech Debt Register` heading if it does not exist.

5. **Update `production/sprint-status.yaml`** (if it exists — covered by the approval
   above):
   - Find the entry whose `file:` is this story's path (or whose `id:` matches)
   - Set `status: done` and `completed: [today's date]`
   - Update the top-level `updated:` field
   - If the file or the entry does not exist, say so in one line —
     `Sprint status not updated: production/sprint-status.yaml absent` or
     `Sprint status not updated: no entry for [story-path]` — never skip silently.

6. **Suggest a git commit**: output a ready-to-use command covering the implementation
   files, the evidence and the story file:

```
Suggested commit:
git add [changed files] production/qa/evidence/<story-slug>/ [story-file-path] production/sprint-status.yaml
git commit -m "feat: [story title] ([TR-ID])" -m "Story: [story-file-path]"
```

The `validate-commit.sh` hook runs its checks (staged secrets, config validity, PRD
sections) when the commit is made.

### Session State Update

After updating the story file, append to `production/session-state/active.md` (the
session checkpoint):

    ## Session Extract — /story-done [date]
    - Verdict: [COMPLETE / COMPLETE WITH NOTES / NOT ASSESSED / BLOCKED]
    - Story: [story file path] — [story title]
    - Code review: [gate verdict | inline checklist | NOT CHECKED]
    - Tech debt logged: [N items, or "None"]
    - Next recommended: [next ready story title and path, or "None identified"]

If `active.md` does not exist, create it with this block as the initial content.
Confirm in conversation: "Session state updated."

---

## Phase 8: Surface the Next Story

After completion, help the developer keep momentum:

1. Read `production/sprint-status.yaml` and the current sprint plan in
   `production/sprints/`.
2. Find stories that are:
   - `status: ready-for-dev` (story `> **Status**: Ready`)
   - Not blocked by other incomplete stories
   - In the Must Have or Should Have tier

Present:

```
### Next Up
The following stories are ready to pick up:
1. [Story name] — [1-line description] — Est: [X hrs]
2. [Story name] — [1-line description] — Est: [X hrs]

Run `/story-readiness [path]` to confirm a story is implementation-ready
before starting.
```

If no more Must Have stories remain in this sprint (all are Complete or Blocked):

```
### Sprint Close-Out Sequence

All Must Have stories are complete. Run these in order:

1. `/smoke-check sprint` — verify the critical journeys still work end to end
2. `/team-qa sprint` — full QA cycle: test case execution, bug triage, sign-off report
   (recommended every sprint; it is a row of the sprint's Definition of Done)
3. `/retrospective sprint-[N]` — what went well, what didn't, action items for the next sprint
4. `/gate-check` — only if this sprint closes a phase (see below)
5. `/sprint-plan new` — plan the next sprint with velocity data and retrospective action items

Build → Hardening (`/gate-check hardening`) needs the smoke report (PASS or PASS WITH
WARNINGS) and the unresolved S1/S2 bug counts, not QA sign-off. QA sign-off is a
Hardening exit criterion: do not run `/gate-check launch` until `/team-qa` returns
APPROVED or APPROVED WITH CONDITIONS.
```

If there are Should Have stories still unstarted, surface them alongside the close-out
sequence so the user can choose: close the sprint now, or pull in more work first.

If no more stories are ready but Must Have stories are still In Progress (not Complete):
"No more stories ready to start — [N] Must Have stories still in progress. Continue
implementing those before sprint close-out."

Close with `AskUserQuestion`:
- Prompt: "What next?"
- Options (only those that apply):
  - `/story-readiness [next-story-path] — check the next story (Recommended)`
  - `/dev-story [next-story-path] — implement the next story`
  - `/smoke-check sprint — start the sprint close-out`
  - `Stop here`

---

## Collaborative Protocol

**In `collaborative` mode.** For `guided` and `autonomous` modes, see
`.claude/docs/automation-modes.md` — the rules below describe collaborative behaviour.
The BLOCKED / NOT ASSESSED override close (Phase 7) always prompts regardless of mode.

- **Never mark a story complete without user approval** — Phase 7 requires an explicit
  "yes" before any file is edited.
- **Never auto-fix failing criteria** — report them and ask what to do.
- **Deviations are facts, not judgments** — present them neutrally; the user decides
  whether they are acceptable.
- **BLOCKED and NOT ASSESSED verdicts are advisory** — the user can override and mark
  complete anyway; document the risk explicitly if they do. For NOT ASSESSED, the
  documented risk is that the criterion was never evaluated, not that it failed —
  record which criteria those were, so the gap is recoverable later rather than closed
  over.
- **Code review never silently disappears** — at `full` the tech lead reviews; at `lean`
  and `solo` the inline checklist runs and says so; when neither can run, the report
  says `NOT CHECKED — code review` and the verdict cannot be COMPLETE.
- Use `AskUserQuestion` for gate concerns and for batching manual criteria
  confirmations.

---

## Recommended Next Steps

- Run `/story-readiness [next-story-path]` to validate the next story before starting
  implementation
- If all Must Have stories are complete: run `/smoke-check sprint` → `/team-qa sprint` →
  `/retrospective sprint-[N]`, then `/gate-check` only if the sprint closes a phase
  (QA sign-off is checked by `/gate-check launch`, not `/gate-check hardening`)
- If tech debt was logged: track it via `/tech-debt` to keep the register current
