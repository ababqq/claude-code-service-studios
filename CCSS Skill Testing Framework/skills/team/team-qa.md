# Skill Spec: /team-qa

> **Category**: team
> **Priority**: medium
> **Spec written**: 2026-09-28

## Skill Summary

Orchestrates the QA team through a structured testing cycle for one sprint or one
feature. Phase 0 resolves `review_mode`, `automation`, `team.size`, `qa.level`,
`testing.strict` and `project.stage` and announces the active set; Phase 1 loads the stories in scope; Phase 2 has `qa-lead` classify every
story (Logic / Integration / UI / E2E / Config) and read the newest smoke report;
Phase 3 writes the QA plan from `.claude/docs/templates/test-plan.md`; Phase 4 spawns
`qa-engineer` once per feature, in parallel, to write test cases; Phase 5 walks manual
QA with the user, files bugs through `qa-engineer` as `production/qa/bugs/BUG-NNNN.md`
and writes evidence records for UI and E2E stories (plus an accessibility pass at
`studio`); Phase 5b spawns the QL-TEST-COVERAGE gate immediately before sign-off,
subject to the review mode; Phase 6 writes the sign-off report with the verdict
APPROVED / APPROVED WITH CONDITIONS / NOT APPROVED / NOT ASSESSED. The orchestrator
itself ends COMPLETE (cycle finished), NOT ASSESSED (no stories in scope, or a sign-off
verdict of NOT ASSESSED) or BLOCKED (smoke FAIL or a critical blocker), with the precedence
BLOCKED > NOT ASSESSED > COMPLETE and always with a partial report.

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`); `name` is `team-qa`, equal to the directory `.claude/skills/team-qa/` and the catalog `name`
- [ ] Bootstrap: the first body line is `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,team.size,qa.level,testing.strict,project.stage` `` and `allowed-tools` grants `Bash(bash "*/.claude/skills/team-qa/../../hooks/yaml-helper.sh" resolve_config *)`
- [ ] `--keys` is exactly `review_mode,automation,team.size,qa.level,testing.strict,project.stage` — no other label, no spaces
- [ ] The line after the bootstrap block is exactly: ``Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] Automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") present verbatim right after that line
- [ ] `allowed-tools` is exactly: `Read, Glob, Grep, Write, Agent, AskUserQuestion` plus the bootstrap grant — no `Edit`, no unrestricted `Bash`, no Task tools
- [ ] 2+ phase headings found (`## Phase 0: Resolve Config`, `### Phase 1: Load Context` … `### Phase 6: QA Sign-Off Report`, including `### Phase 5b: Test Coverage Review (QL-TEST-COVERAGE)`)
- [ ] Verdict keywords present, exactly as the skill defines them: sign-off `APPROVED`, `APPROVED WITH CONDITIONS`, `NOT APPROVED`, `NOT ASSESSED`; smoke status `PASS`, `PASS WITH WARNINGS`, `FAIL`, `NOT ASSESSED`; orchestrator `COMPLETE`, `NOT ASSESSED`, `BLOCKED`, with the line `Precedence: BLOCKED > NOT ASSESSED > COMPLETE.`
- [ ] "May I write this to `production/qa/qa-plan-<sprint>-YYYY-MM-DD.md`?" (Phase 3), "May I write this to `production/qa/evidence/<story-slug>/evidence.md`?" (Phase 5) and "May I write this to `production/qa/qa-signoff-<sprint>-YYYY-MM-DD.md`?" (Phase 6) each appear before the corresponding write
- [ ] Outputs at the exact paths: `production/qa/qa-plan-<sprint>-YYYY-MM-DD.md`, `production/qa/test-cases/<feature>-cases.md`, `production/qa/bugs/BUG-NNNN.md`, `production/qa/qa-signoff-<sprint>-YYYY-MM-DD.md`; the sign-off report template has `> **Verdict**: [APPROVED | APPROVED WITH CONDITIONS | NOT APPROVED | NOT ASSESSED]` directly under its H1 `# QA Sign-Off Report: [Sprint/Feature]`
- [ ] Bug files are named `production/qa/bugs/BUG-NNNN.md` (four digits, no slug) and carry the exact ladder strings `**Severity**: [S1-Critical / S2-Major / S3-Minor / S4-Trivial]` and `**Priority**: [P1-Fix this sprint / P2-Fix soon / P3-Backlog / P4-Won't fix]`
- [ ] The QA plan is built from `.claude/docs/templates/test-plan.md` (so `## Automated Tests Required` and `## Smoke Test Scope` are present for `/create-stories` and `/smoke-check`)
- [ ] Contains verbatim: "Team skills spawn only the gates `.claude/docs/director-gates.md` § Gate Index lists this skill under (Spawned by column), after the review-mode check (lean suffix rule); team-size scoping never removes a director gate."
- [ ] Phase 0 names QL-TEST-COVERAGE in its review-mode check and contains the lean sentence verbatim: "`lean` → **skip every gate whose ID does not end in `-PHASE-GATE`**. Note: `[GATE-ID] skipped — Lean mode`"
- [ ] Contains the default statement verbatim: "Unset on an unconfigured project: `modes.rigor` defaults to `minimal`, which resolves `review_mode` to `solo`."
- [ ] Active set per `team.size` is listed (`individual`: `qa-engineer` only, with `qa-lead` spawned only for QL-TEST-COVERAGE; `small`: `qa-lead` → `qa-engineer`; `studio`: + `accessibility-specialist`) and announced before Phase 1 with the line template `Active set (team.size: <resolved>): …` / `Not spawned this run: …`
- [ ] Has an Error Recovery Protocol section stating that a named artifact that is not on disk is a failed phase
- [ ] No `!` injection other than the bootstrap line; no `file:line` citations of other files
- [ ] Next-step guidance differs by sign-off verdict and names current skills (`/smoke-check sprint`, `/gate-check hardening`, `/gate-check launch`, `/bug-triage`, `/bug-report verify <BUG-ID>`)

---

## Director Gate Checks

The skill spawns one gate, **QL-TEST-COVERAGE** (owner `qa-lead`), in Phase 5b —
immediately before the Sign-off phase. The spawn names
`.claude/docs/director-gates/ql-test-coverage.md` for the agent to read first, passes
`Pass: story path(s) or sprint id · test file paths · evidence directory paths · resolved `testing.strict` and `qa.level` lines`,
and parses the reply's first line as `[QL-TEST-COVERAGE]: TOKEN` with TOKEN one of
`ADEQUATE`, `GAPS`, `INADEQUATE`.

- **Full mode**: QL-TEST-COVERAGE spawns, at every `team.size` (at `individual` the `qa-lead` is spawned for the gate only)
- **Lean mode**: skip every gate whose ID does not end in `-PHASE-GATE` — note `[QL-TEST-COVERAGE] skipped — Lean mode` (no gate of this skill runs)
- **Solo mode**: no gates — note `[QL-TEST-COVERAGE] skipped — Solo mode`
- **Review-mode exempt**: not applicable — `/team-qa` resolves `review_mode`
- The skip note is carried into the sign-off report header where the gate's review line would go

---

## Test Cases

Quoted prompts, option labels and verdict tokens below are the canonical English text
of `SKILL.md`; at run time the model renders them in the user's conversation language.

### Case 1: Happy Path — Sprint passes QA, gate ADEQUATE, APPROVED

**Fixture** (assumed project state):
- `production/sprints/sprint-07.md` lists 4 Moa stories: `production/epics/goals-core/story-001-create-goal.md` (Logic, `api`), `story-002-goal-list-api.md` (Integration, `api`), `story-003-goal-list-screen.md` (UI, `web`), `story-004-create-goal-journey.md` (E2E, `web`)
- `production/qa/smoke-2026-11-02.md` exists with `> **Verdict**: PASS` and names the staging environment
- No files in `production/qa/bugs/`
- Resolved block: `review_mode: full`, `team.size: small`, `automation: collaborative`

**Input:** `/team-qa sprint-07`

**Expected behavior:**
1. Phase 0 announces `Active set (team.size: small): qa-lead, qa-engineer.` and names `accessibility-specialist` as not spawned
2. Phase 1 reports "QA cycle starting for sprint-07. Found 4 stories. Current stage: [stage]. Ready to begin QA strategy?" (stage from the resolved `project.stage` line, or "stage: not set")
3. Phase 2 spawns `qa-lead`; the strategy table classifies all 4 stories by `> **Type**:` and Surface; the smoke status is PASS, taken from the report's `> **Verdict**:` line without re-interviewing the user; `AskUserQuestion` "QA Strategy Review" → "Looks good — proceed to test plan"
4. Phase 3 writes the QA plan from `.claude/docs/templates/test-plan.md` after "May I write this to `production/qa/qa-plan-sprint-07-YYYY-MM-DD.md`?"
5. Phase 4 spawns `qa-engineer` once per feature (here one: `goals`), naming `production/qa/test-cases/goals-cases.md` in the prompt; test cases are approved per story group
6. Phase 5 walks the UI and E2E stories; both PASS; the evidence record for each goes to `production/qa/evidence/<story-slug>/` after "May I write"
7. Phase 5b spawns `qa-lead` for QL-TEST-COVERAGE; first line `[QL-TEST-COVERAGE]: ADEQUATE`
8. Phase 6 re-checks the smoke report, drafts the sign-off report, and writes it after "May I write this to `production/qa/qa-signoff-sprint-07-YYYY-MM-DD.md`?"; `> **Verdict**: APPROVED`; header records `> **QA Lead Review (QL-TEST-COVERAGE)**: APPROVED [date]`

**Assertions:**
- [ ] The active set is announced before any agent is spawned
- [ ] The strategy table classifies all 4 stories with the five-type vocabulary (Logic / Integration / UI / E2E / Config)
- [ ] The smoke status is read from the newest `production/qa/smoke-*.md` verdict line, and its environment is noted
- [ ] The QA plan and the sign-off report are each written only after their own "May I write" approval
- [ ] The test-case path `production/qa/test-cases/goals-cases.md` is named in the `qa-engineer` prompt
- [ ] QL-TEST-COVERAGE is spawned immediately before Phase 6, with the four Context items on its `Pass:` line
- [ ] The sign-off report has `> **Verdict**: APPROVED` directly under its H1 and a Test Coverage Summary row for every story
- [ ] Orchestrator verdict is COMPLETE; next step names `/gate-check hardening` (from Build) or `/gate-check launch` (from Hardening)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — Smoke check FAIL stops the cycle

**Fixture:**
- `production/sprints/sprint-08.md` lists 3 stories
- The newest smoke report `production/qa/smoke-2026-11-16.md` has `> **Verdict**: FAIL` with two failures (health endpoint returns 503 on staging; Kakao sign-in callback errors)

**Input:** `/team-qa sprint-08`

**Expected behavior:**
1. Phases 0–1 run normally
2. Phase 2: `qa-lead` reads the smoke report; smoke status FAIL, with both failures listed prominently
3. The skill surfaces the failures and stops: no Phase 3, 4, 5, 5b or 6
4. The user is told to fix them, re-run `/smoke-check sprint`, then re-run `/team-qa`

**Assertions:**
- [ ] Smoke FAIL halts the pipeline in Phase 2 — no QA plan, test cases, gate spawn or sign-off report
- [ ] Both failures are shown explicitly, not summarized as "smoke failed"
- [ ] Remediation names `/smoke-check sprint` and a `/team-qa` re-run
- [ ] Orchestrator verdict is BLOCKED (not COMPLETE), and a partial report is produced
- [ ] No "May I write" prompt for a sign-off report is issued

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: NOT ASSESSED — No smoke report

**Fixture:**
- `production/sprints/sprint-09.md` lists 3 stories (UI `web`, UI `ios`, Logic `api`)
- No file matches `production/qa/smoke-*.md`
- Resolved block: `review_mode: lean`, `team.size: small`

**Input:** `/team-qa sprint-09`

**Expected behavior:**
1. Phase 2: no smoke report exists, so the smoke status is **NOT ASSESSED** with the note "No usable smoke check report — run `/smoke-check sprint` before proceeding."
2. `AskUserQuestion` offers "Smoke check failed or not assessed — run /smoke-check sprint, then re-run /team-qa"; the user chooses to proceed with test cases and manual QA
3. Manual QA passes for all stories
4. Phase 6 re-checks `production/qa/smoke-*.md` — still none
5. Sign-off verdict is **NOT ASSESSED**, with the reason (no PASS or PASS WITH WARNINGS smoke report); next step: "QA did not run to completion. … Do not advance the build on this verdict."

**Assertions:**
- [ ] A missing smoke report is NOT ASSESSED — never PASS WITH WARNINGS
- [ ] The sign-off verdict is NOT ASSESSED (not APPROVED, not APPROVED WITH CONDITIONS) because the precondition "a smoke report with verdict PASS or PASS WITH WARNINGS" is unmet
- [ ] The reason names the missing input and the skill that produces it (`/smoke-check sprint`)
- [ ] Phase 6 re-checks the smoke report before deciding (a report produced mid-cycle would count)
- [ ] The orchestrator verdict is NOT ASSESSED too (the sign-off verdict is NOT ASSESSED), never COMPLETE

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Mode Variant — `team.size` collapses and widens the active set

**Fixture:**
- Same stories as Case 1, smoke PASS
- Variant A: resolved `team.size: individual`, `review_mode: full`
- Variant B: resolved `team.size: studio`, `review_mode: full`

**Input:** `/team-qa sprint-07`

**Expected behavior (variant A):**
1. Announcement: active set `qa-engineer`; `qa-lead` and `accessibility-specialist` named as not spawned, consulted through `qa-engineer`
2. Strategy, cases, bug reports and the sign-off draft route through `qa-engineer`
3. Phase 5b still spawns `qa-lead` for QL-TEST-COVERAGE (team-size scoping never removes a director gate)
4. The results say "accessibility pass not run — accessibility-specialist is not in the active set; only the axe results in the evidence were checked."

**Expected behavior (variant B):**
1. Announcement: active set `qa-lead`, `qa-engineer` (one spawn per feature), `accessibility-specialist`
2. After manual QA of the UI and E2E stories, `accessibility-specialist` reviews the axe results (`NN-<state>-axe.json`), keyboard and focus order, and returns a PASS / FAIL line per story; each failure is filed as a bug

**Assertions:**
- [ ] The announcement lists exactly the agents of the resolved size and names every other pipeline agent as not spawned
- [ ] At `individual` the QL-TEST-COVERAGE gate is still spawned (with `qa-lead`) when `review_mode` runs it
- [ ] At `individual` and `small` the missing accessibility pass is stated in the results, never silently dropped
- [ ] At `studio` the accessibility pass runs and its failures become bug reports

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Edge Case — Mixed results with an S1 bug and a BLOCKED story

**Fixture:**
- `production/sprints/sprint-10.md` lists 4 stories; smoke PASS
- `production/qa/bugs/` already holds `BUG-0001.md` and `BUG-0002.md`
- Manual QA results: Story A (Logic) automated PASS; Story B (UI) PASS WITH NOTES (label truncates at 200% text size); Story C (E2E, auto-debit journey) FAIL — the app crashes after confirming the first deposit; Story D (Integration, Toss Payments webhook) BLOCKED — sandbox credentials not issued

**Input:** `/team-qa sprint-10`

**Expected behavior:**
1. After the FAIL on Story C, `AskUserQuestion` collects the failure description (surface, environment and build, account and flags, request or trace id)
2. The skill globs `production/qa/bugs/BUG-*.md`, assigns `BUG-0003`, and spawns `qa-engineer` naming `production/qa/bugs/BUG-0003.md`; the report carries `**Severity**: S1-Critical`, a priority from the ladder, `**Status**: Open` and the service environment block
3. Result summary: PASS 1, PASS WITH NOTES 1, FAIL 1 (BUG-0003), BLOCKED 1
4. Sign-off verdict: **NOT APPROVED** — an unresolved S1 bug decides it even though Story D produced no evidence
5. Next step: "Resolve S1/S2 bugs and re-run `/team-qa` or targeted manual QA before advancing. Verify each fix with `/bug-report verify <BUG-ID>`."

**Assertions:**
- [ ] The bug file is `production/qa/bugs/BUG-0003.md` — the next four-digit number, no slug — written by `qa-engineer`, not by the orchestrator
- [ ] All 4 stories appear in the Test Coverage Summary; Story D is listed as BLOCKED, not dropped
- [ ] The known failure (unresolved S1) outranks the unknown (BLOCKED story): the verdict is NOT APPROVED, not NOT ASSESSED
- [ ] "Unresolved" counts `Open`, `In Progress` and `Fixed — Pending Verification`, never `Open` alone
- [ ] Orchestrator verdict is still COMPLETE (the cycle finished); the sign-off verdict is NOT APPROVED

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Director Gate — full mode (GAPS accepted)

**Fixture:**
- Same as Case 1, but the E2E story has no retained trace in `production/qa/evidence/story-004-create-goal-journey/`
- Review mode: `full`

**Input:** `/team-qa sprint-07`

**Expected behavior:**
1. Phase 5b spawns `qa-lead`; the prompt tells it to read `.claude/docs/director-gates/ql-test-coverage.md` first; the `Pass:` line carries the sprint id, the test file paths, the evidence directories and the `testing.strict: logic=<v> integration=<v> ui=<v> e2e=<v> config=<v> (unset = each skill applies its own default)` and `qa.level: <v> (<source>)` lines as the bootstrap block printed them
2. First line `[QL-TEST-COVERAGE]: GAPS`
3. `AskUserQuestion`: `Revise flagged items` / `Accept and proceed` / `Discuss further`; the user accepts
4. The sign-off header records `CONCERNS (accepted) [date]`; the gap becomes a condition; verdict APPROVED WITH CONDITIONS

**Assertions:**
- [ ] In full mode QL-TEST-COVERAGE spawns with the gate file path and the four Context items — the parent does not read or paste the gate file
- [ ] `testing.strict` and `qa.level` are passed as the resolved block printed them, never invented
- [ ] A CONCERNS-class verdict (`GAPS`) is surfaced via AskUserQuestion (revise / accept / discuss)
- [ ] An accepted gap becomes a condition; the skill does not auto-advance past a CONCERNS-class or REJECT-class verdict
- [ ] A first line that does not parse is treated as CONCERNS-class, not as approval

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: Director Gate — lean mode

**Fixture:**
- Same project state as Case 1
- Review mode: `lean`

**Input:** `/team-qa sprint-07`

**Expected behavior:**
1. Phase 5b applies the review-mode check: QL-TEST-COVERAGE does not end in `-PHASE-GATE`, so it is skipped
2. The sign-off header carries `[QL-TEST-COVERAGE] skipped — Lean mode` where the gate's review line would go
3. The summary says "QL-TEST-COVERAGE not consulted — Lean mode; `--review full` runs it."
4. The sign-off verdict is decided without the gate: APPROVED (the rules allow "the coverage gate ADEQUATE or skipped with its note")

**Assertions:**
- [ ] Output contains `[QL-TEST-COVERAGE] skipped — Lean mode`
- [ ] No gate spawns (none of this skill's gates ends in `-PHASE-GATE`)
- [ ] The omission is named in the summary with the `--review full` route

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 8: Director Gate — solo mode (unconfigured default)

**Fixture:**
- Same project state as Case 1
- `project.yaml` sets neither `modes.review_mode` nor `modes.rigor` (the block shows `review_mode: solo (rigor:minimal)`)

**Input:** `/team-qa sprint-07`

**Expected behavior:**
1. `review_mode` resolves to `solo` through the rigor default
2. QL-TEST-COVERAGE is skipped; the sign-off header carries `[QL-TEST-COVERAGE] skipped — Solo mode`

**Assertions:**
- [ ] In solo mode no director gate spawns
- [ ] Output contains `[QL-TEST-COVERAGE] skipped — Solo mode`
- [ ] The skill never writes `modes.review_mode` (or any other rigor-fronted knob) to reach this outcome

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 9: No Argument — Infers the active sprint or asks

**Fixture (variant A):** `production/sprint-status.yaml` has `sprint: 11`; `production/session-state/active.md` mentions sprint-11

**Fixture (variant B):** neither file exists

**Input:** `/team-qa`

**Expected behavior:**
1. Variant A: reads both files, reports the inferred sprint before proceeding, then runs as `/team-qa sprint-11`
2. Variant B: asks with `AskUserQuestion` which sprint or feature QA should cover — never guesses

**Assertions:**
- [ ] No hard-coded sprint name is used
- [ ] Both state files are read before asking (variant A), and the inference is reported
- [ ] Absent state files lead to a question, not an error or a guess (variant B)

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses "May I write this to `<path>`?" before the QA plan, each evidence record and the sign-off report
- [ ] Presents the strategy, the test cases and the sign-off draft before requesting approval
- [ ] Ends with verdict-specific next steps
- [ ] Does not auto-create files without user approval; `qa-engineer` writes test cases and bug files only at paths the skill named (bounded exception: new artifact under `production/`, phase gated by `AskUserQuestion`)
- [ ] Independent `qa-engineer` spawns in Phase 4 (one per feature) and parallel bug reports in Phase 5 (pre-assigned numbers) are issued together
- [ ] Any BLOCKED agent is surfaced immediately and a partial report is always produced
- [ ] Writes no evidence, reports or plans under `production/session-logs/` (gitignored)
- [ ] Never writes `modes.review_mode` or any other knob that `modes.rigor` fronts
- [ ] The orchestrator verdict (COMPLETE / NOT ASSESSED / BLOCKED) stays distinct from the sign-off verdict (APPROVED / APPROVED WITH CONDITIONS / NOT APPROVED / NOT ASSESSED)

---

## Coverage Notes

- The `feature: <feature-slug>` scope (stories selected by their `**PRD**:` line naming
  `design/prd/<feature-slug>.md`) follows the same Phase 1 logic and is not given its own
  case; `<sprint>` in the output names becomes the feature slug.
- Zero stories in scope (`NOT ASSESSED — no stories in scope`, routed to `/sprint-plan` or
  `/create-stories`; orchestrator verdict NOT ASSESSED, no sign-off report) is asserted by the
  skill text but not given a fixture here.
- The REJECT-class path (`INADEQUATE` → missing coverage produced and the gate re-spawned,
  or sign-off NOT APPROVED) mirrors Case 6 and is covered by its "does not auto-advance"
  assertion.
- `guided` and `autonomous` automation modes change when decision points prompt; they are
  covered by the automation prelude static assertion, not by separate cases.
