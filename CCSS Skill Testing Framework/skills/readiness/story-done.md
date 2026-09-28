# Skill Test Spec: /story-done

> **Category**: readiness
> **Priority**: critical
> **Spec written**: 2026-09-28

## Skill Summary

`/story-done` closes the loop between design and implementation — the Definition of
Done. Run at the end of a story, it reads the story file (header contract, acceptance
criteria, `**API Contract**`, `**Migration**`, `**Feature Flag**`, `**Analytics Events**`),
the current TR requirement text, the governing ADR's `## Decision` and `## Consequences`,
the manifest version, the contract operation, the migration plan status, the tracking
plan and the evidence directory `production/qa/evidence/<story-slug>/`. It verifies each
acceptance criterion (automatic, confirmed with the user, or `DEFERRED`), maps criteria to
tests, applies the per-type evidence gate (`testing.strict.logic`, `.integration`, `.ui`,
`.e2e`, `.config`, relaxed by `qa.level`), and always enforces the **migration floor** and
the **run result**. Deviation checks cover PRD rules, manifest staleness, ADR constraints,
hardcoded values, scope, API contract drift, migration phase state, flag default, PII in
new log statements, tracking events and — ADVISORY only — design reference drift (captures
compared with the story's `design/handoff/<slug>/screens/`; reference images never count as
evidence). Code review never disappears: **TL-CODE-REVIEW**
at `full`, otherwise an inline `/code-review` checklist; **QL-TEST-COVERAGE** reviews
coverage at `full`. With approval it sets `> **Status**: Complete`, appends
`## Completion Notes`, sets the story's `production/sprint-status.yaml` entry to
`status: done`, and surfaces the next ready story. `disable-model-invocation: true`.

Verdicts (precedence first-match): **BLOCKED** → **NOT ASSESSED** →
**COMPLETE WITH NOTES** → **COMPLETE**.

---

## Static Assertions (Structural)

Verified automatically by `/skill-test static` — no fixture needed.

- [ ] Frontmatter has `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`; `name: story-done` equals the directory, the catalog `name` and this spec's basename
- [ ] `description` is exactly "Verify acceptance criteria and evidence, PRD/ADR/API deviations, code review; close the story."
- [ ] `disable-model-invocation: true` present; no `isolation` key; `model: sonnet`; `argument-hint` offers `[story-file-path]` and `[--review full|lean|solo]`
- [ ] First body line is exactly `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,story_granularity,qa.level,testing.strict,feature_overrides,code_roots` ``
- [ ] `allowed-tools` is exactly `Read, Glob, Grep, Bash, Write, Edit, AskUserQuestion, Agent` plus `Bash(bash "*/.claude/skills/story-done/../../hooks/yaml-helper.sh" resolve_config *)`
- [ ] The line after the bootstrap block is exactly `` Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`. ``, followed verbatim by the automation prelude block
- [ ] ≥5 phase headings (`## Phase 1: Find the Story` … `## Phase 8: Surface the Next Story`, incl. `## Phase 4b: QA Coverage Gate` and `## Phase 5: Tech Lead Code Review Gate`)
- [ ] Verdict line `### Verdict: COMPLETE / COMPLETE WITH NOTES / NOT ASSESSED / BLOCKED` and the precedence BLOCKED, then NOT ASSESSED, then COMPLETE WITH NOTES, then COMPLETE
- [ ] The evidence table has the five types `Logic`, `Integration`, `UI`, `E2E`, `Config` with keys `testing.strict.logic` … `testing.strict.config`; Config's default is ADVISORY with the `/smoke-check` BLOCKING exception kept
- [ ] The migration floor names `production/qa/evidence/<story-slug>/migration-dry-run.log`, "at every `qa.level` and regardless of `testing.strict.config`", absent ⇒ BLOCKING
- [ ] The UI evidence check states that files under `design/handoff/` are design references and never count as evidence
- [ ] Phase 4 has check 11 **Design reference drift** — ADVISORY, never BLOCKING unless an acceptance criterion names the look, `Design reference: NOT CHECKED — <reason>` when it cannot run — and the tier sentence reads "Checks 6–11 run at every tier whenever the story's field names something (a contract, a migration, a flag, events, a design reference); check 9 always runs."
- [ ] The report's `### Contract, Migration, Flag, Privacy, Events` block has a `- Design reference:` line
- [ ] The run-result check reads the `Run result:` line (`OBSERVED | NOT VERIFIED | N/A`) and is not waived at `qa.level: minimal`
- [ ] The inline code-review line is exactly `Code review: inline checklist (TL-CODE-REVIEW skipped — <Mode> mode)`, and `NOT CHECKED — code review` caps the verdict at COMPLETE WITH NOTES
- [ ] Code scans report `NOT CHECKED — no code root resolved (set stack.layers.<layer>.root via /setup-stack)` when `code_roots` is unresolved
- [ ] Write prompts present: the Phase 7 approval "May I write this to `[story-path]` and `production/sprint-status.yaml`?" (as the closing `AskUserQuestion`) and "May I write this to `docs/tech-debt-register.md`?"
- [ ] Outputs: the story file (`> **Status**: Complete`, `> **Last Updated**:`, `## Completion Notes` with `**Verdict**:`) and `production/sprint-status.yaml` (`status: done`, `completed:`, `updated:`) — matching catalog step `build.story-done`
- [ ] Both gates' review-mode checks carry the lean suffix sentence; spawns have `` Pass: story path(s) or sprint id · test file paths · evidence directory paths · resolved `testing.strict` and `qa.level` lines `` (QL-TEST-COVERAGE) and `Pass: story path · changed file list · API contract path (or "none") · governing ADR path` (TL-CODE-REVIEW); replies are parsed as `[GATE-ID]: TOKEN`
- [ ] Only one `!` injection; no `file:line` citation; handoffs name `/story-readiness`, `/dev-story`, `/smoke-check sprint`, `/team-qa sprint`, `/retrospective sprint-[N]`, `/gate-check`, `/sprint-plan new`, `/tech-debt`

---

## Director Gate Checks

Two gates, both `-PHASE-GATE`-free, so both are skipped outside `full`:

- **QL-TEST-COVERAGE** — `qa-lead`, Domain "Test coverage", verdicts
  `ADEQUATE / GAPS / INADEQUATE` (Phase 4b). Also skipped at `qa.level: minimal`
  ("QL-TEST-COVERAGE skipped — qa.level minimal.") and for a `Config` story with no code
  and no migration.
- **TL-CODE-REVIEW** — `tech-lead`, Domain "Code review", verdicts
  `APPROVE / CONCERNS / REJECT` (Phase 5).
- **Full mode**: both spawn; each prompt tells the agent to read its gate file
  (`.claude/docs/director-gates/ql-test-coverage.md`, `tl-code-review.md`).
- **Lean mode**: skip every gate whose ID does not end in `-PHASE-GATE` — notes
  `[QL-TEST-COVERAGE] skipped — Lean mode` and `[TL-CODE-REVIEW] skipped — Lean mode`;
  code review moves inline.
- **Solo mode**: same with `— Solo mode`.

---

## Test Cases

Fixtures use the Moa example story `production/epics/goals-core/story-001-create-goal.md`
(Type Integration, Surface `api`, `TR-goals-001`, `ADR-0006`,
`` **API Contract**: `docs/api/openapi.yaml#/paths/~1v1~1goals/post` ``,
`` **Migration**: `docs/data/migrations/0003-savings-goal.md` ``,
`**Feature Flag**: goals.v2-progress-ring`, `**Analytics Events**: goal_created`), code under
`apps/api`.

### Case 1: Happy Path — everything verified at `full`

**Fixture:**
- `qa.level: standard`, `modes.workflow: full`; review mode `full`; `commands.test` set
- Contract test `apps/api/src/goals/goals.contract.test.ts` passes; `production/qa/evidence/story-001-create-goal/` holds `evidence.md` (`Run result: OBSERVED — 201 with the new goal`), `01-createGoal.json` and `migration-dry-run.log`
- The handler matches the contract; the migration plan `## Status` records Expand applied; the flag default `off` is recorded in the PRD and the flag definition; `goal_created` is in the tracking plan; no personal data in new log calls
- `production/sprint-status.yaml` has an entry with `file:` = the story path and `status: in-progress`
- QL-TEST-COVERAGE returns ADEQUATE; TL-CODE-REVIEW returns APPROVE

**Input:** `/story-done production/epics/goals-core/story-001-create-goal.md`

**Expected behavior:**
1. Reads the story, greps `id: TR-goals-001` for the current requirement text, bounded-reads ADR-0006 `## Decision` and `## Consequences`
2. Verifies each criterion (runs the story's tests through `commands.test`), builds the traceability table, applies the Integration evidence gate, the migration floor and the run-result check
3. Runs deviation checks 1–11 — all clean (check 11 N/A: no design reference on an `api` story); runs QL-TEST-COVERAGE then TL-CODE-REVIEW
4. Presents the full `## Story Done:` report with Verdict **COMPLETE**
5. Asks the Phase 7 question ("Verification complete. How do you want to proceed?") and, on `Close the story — update the story file and production/sprint-status.yaml, log notes (Recommended)`, updates both files
6. Suggests a commit and surfaces the next ready story

**Assertions:**
- [ ] Requirement text comes from `docs/architecture/tr-registry.yaml`, not the story's quoted text
- [ ] Criteria are listed with pass / FAILS / DEFERRED status and a traceability table (COVERED / UNTESTED)
- [ ] The report's `### Contract, Migration, Flag, Privacy, Events` block shows each of the six lines (the design reference line reads `N/A — none or no user-facing surface`)
- [ ] `## Completion Notes` carries `**Verdict**: COMPLETE`, `**Migration Dry-Run**:`, `**Run Result**:` and `**Code Review**: TL-CODE-REVIEW: APPROVE`
- [ ] `production/sprint-status.yaml` entry becomes `status: done` with `completed:` and the top-level `updated:` — hyphenated status values only
- [ ] No file is edited before the Phase 7 answer

---

### Case 2: Blocked Path — contract drift and a PRD rule deviation

**Fixture:**
- The handler returns `200` where the contract declares `201`, and omits the required `targetDate` field
- The PRD's `## Business Rules & Calculations` says "Free plan: at most 3 active goals"; the changed file has `MAX_ACTIVE_GOALS_FREE = 5`

**Input:** `/story-done production/epics/goals-core/story-001-create-goal.md`

**Expected behavior:**
1. Check 6 (API contract drift) flags the status code and the missing required field as **BLOCKING**
2. Check 1 (PRD rules) flags the limit mismatch as **BLOCKING** (contradicts the PRD)
3. Verdict **BLOCKED**; lists what must be fixed and offers help; does not proceed to Phase 7 on its own
4. If the user explicitly asks to close anyway, Phase 7 still prompts (in every automation mode) and the notes gain `**Override**: closed by user decision on [date] — …`

**Assertions:**
- [ ] Each deviation is classified BLOCKING / ADVISORY / OUT OF SCOPE and cites the PRD, ADR or contract it contradicts
- [ ] A response field the contract does not declare would be ADVISORY, not BLOCKING
- [ ] The story is not marked Complete without an explicit user decision
- [ ] Autonomous mode never silently closes a BLOCKED story

---

### Case 3: NOT ASSESSED — a criterion nobody can evaluate, unreadable evidence, no code root

**Fixture (3a):**
- Story `production/epics/goals-core/story-004-goal-list.md`: one criterion reads "The goal screen feels trustworthy" (no observable outcome)
- `production/qa/evidence/story-004-goal-list/evidence.md` exists but is empty
- Contrast criterion: "the 알림톡 arrives after the first auto-debit" (evaluable, but only on staging)

**Fixture (3b):** the same story, with the `code_roots` line reading `code_roots: unresolved — NOT CHECKED …`.

**Input:** `/story-done production/epics/goals-core/story-004-goal-list.md`

**Expected behavior:**
1. (3a) The unevaluable criterion and the unreadable evidence give Verdict **NOT ASSESSED**, naming which criterion and which file, and what would make them checkable
2. (3a) The 알림톡 criterion is `DEFERRED — requires staging environment` — evaluable later, not NOT ASSESSED, not blocking
3. (3b) The hardcoded-value, hardcoded-string and PII-in-logs scans report `NOT CHECKED — no code root resolved (set stack.layers.<layer>.root via /setup-stack)` instead of zero hits

**Assertions:**
- [ ] NOT ASSESSED outranks COMPLETE and COMPLETE WITH NOTES and ranks below BLOCKED
- [ ] An absent evidence file is decided by `testing.strict` (BLOCKED or COMPLETE WITH NOTES), not re-routed to NOT ASSESSED
- [ ] NOT ASSESSED takes the BLOCKED path: no automatic Phase 7; closing anyway always prompts and records which criteria were never evaluated
- [ ] A scan that could not run is never reported as clean

---

### Case 4: Mode Variant — `qa.level: minimal` still enforces the floors

**Fixture:**
- `qa.level: minimal`; story Type Logic with no unit test file
- `**Migration**` is not `None`, and no `migration-dry-run.log` exists
- `evidence.md` says `Run result: N/A — Logic story`

**Input:** `/story-done production/epics/goals-core/story-002-goal-limits.md`

**Expected behavior:**
1. The per-type evidence check and the >50%-untested escalation are skipped; the note "QL-TEST-COVERAGE skipped — qa.level minimal." appears
2. The migration floor still runs: the missing log is **BLOCKING** ("Migration story without a dry-run log. …")
3. The run result `N/A — Logic story` is not accepted as a reason ("it's a Logic story" is not a reason) and is flagged

**Assertions:**
- [ ] Verdict is **BLOCKED** because of the migration floor, not because of the missing unit test
- [ ] `**Test Evidence**:` in the notes reads "waived at qa.level: minimal"
- [ ] The migration floor never consults `testing.strict`

---

### Case 5: Edge Case — no argument

**Fixture:**
- `production/session-state/active.md` names no active story
- `production/sprint-status.yaml` has two entries: one `status: in-progress`, one `status: review`

**Input:** `/story-done`

**Expected behavior:**
1. Checks `production/session-state/active.md`, then `production/sprint-status.yaml` for `in-progress` and `review` entries
2. Asks "Which story are we completing?" with both story file names
3. If nothing is found anywhere, asks the user for the path

**Assertions:**
- [ ] The skill never picks a story silently when several match
- [ ] The confirmed story is named before verification starts

---

### Case 6: Director Gate — full mode

**Fixture:** Case 1 fixture; QL-TEST-COVERAGE returns INADEQUATE ("the journey's error path is untested"); on a second run TL-CODE-REVIEW returns CONCERNS.

**Expected behavior:**
1. Phase 4b spawns `qa-lead` for QL-TEST-COVERAGE with its `Pass:` line; Phase 5 spawns `tech-lead` for TL-CODE-REVIEW with its `Pass:` line (changed file list from the `/dev-story` session extract, else read-only `git status --porcelain` / `git diff --name-only`)
2. Parses each first line `[GATE-ID]: TOKEN`

**Assertions:**
- [ ] INADEQUATE → BLOCKING: "Verdict cannot be COMPLETE until coverage improves"
- [ ] GAPS → ADVISORY via `AskUserQuestion` `Revise flagged items` / `Accept and proceed` / `Discuss further`
- [ ] TL REJECT → BLOCKING deviation; TL CONCERNS → `AskUserQuestion` `Revise flagged issues` / `Accept and proceed` / `Discuss further`, accepted concerns become ADVISORY
- [ ] A first line that does not parse is CONCERNS-class with the missing verdict line named
- [ ] The parent never reads either gate file

---

### Case 7: Director Gate — lean mode

**Fixture:** Case 1 fixture; review mode `lean`.

**Expected behavior:**
1. QL-TEST-COVERAGE and TL-CODE-REVIEW are skipped
2. The `/code-review` checklist runs inline over the changed files: contract conformance, object-level authorization, input validation, data access (N+1, indexes, transactions), idempotency / timeouts / retries, pagination, secrets and PII, errors and operability, tests

**Assertions:**
- [ ] Output carries `[QL-TEST-COVERAGE] skipped — Lean mode` and `[TL-CODE-REVIEW] skipped — Lean mode`
- [ ] The report and `## Completion Notes` carry exactly `Code review: inline checklist (TL-CODE-REVIEW skipped — Lean mode)`
- [ ] A committed secret or a missing authorization check found by the checklist is BLOCKING
- [ ] If the changed files cannot be determined, the report says `NOT CHECKED — code review` and the verdict is capped at COMPLETE WITH NOTES

---

### Case 8: Director Gate — solo mode

**Fixture:** Case 1 fixture; review mode `solo`.

**Assertions:**
- [ ] No director gate spawns
- [ ] Output carries `[QL-TEST-COVERAGE] skipped — Solo mode` and `[TL-CODE-REVIEW] skipped — Solo mode`
- [ ] Code review still happens: `Code review: inline checklist (TL-CODE-REVIEW skipped — Solo mode)`

---

### Case 9: Design Tool — reference images and design drift

**Fixture:**
- Story `production/epics/goals-core/story-004-goal-detail-web.md`: Type UI, Surface `web`, no acceptance criterion names the look; its `## Implementation Notes` has
  ``- Design reference: figma — https://www.figma.com/design/<fileKey>/Moa?node-id=12-34 · record `design/handoff/goal-detail/HANDOFF.md` — empty, filled, error``
- `design/handoff/goal-detail/HANDOFF.md` with `> **Verdict**: RETAINED` and `screens/01-empty.png`, `02-filled.png`, `03-error.png`
- (9a) `production/qa/evidence/story-004-goal-detail-web/` holds real captures `01-empty-desktop.png` … `03-error-mobile.png`; the error capture places the retry button below the fold where the reference shows it inline
- (9b) the evidence directory holds only copies of the three reference screens
- (9c) as 9a, but the record's verdict is `> **Verdict**: NOT ASSESSED` (no `screens/`)

**Input:** `/story-done production/epics/goals-core/story-004-goal-detail-web.md`

**Expected behavior:**
1. (9a) The UI gate is satisfied by the captures; check 11 lists the retry-button position as **ADVISORY** drift → at most COMPLETE WITH NOTES, never BLOCKED on that ground
2. (9b) The reference copies are not captures: "Reference image `[path]` found in the evidence directory; it is a design reference, not a capture of the running product." — flagged at the UI gate level (BLOCKING by default) → **BLOCKED**
3. (9c) Check 11 prints `Design reference: NOT CHECKED — <reason>`; the verdict is unchanged by it

**Assertions:**
- [ ] No file under `design/handoff/` ever counts as UI evidence
- [ ] Design drift never becomes BLOCKING while no acceptance criterion names the look
- [ ] No remote design URL is fetched; the record and screens are read as local files

---

## Protocol Compliance

- [ ] Presents the full report (criteria, traceability, evidence, deviations, code review, scope) before asking anything that writes
- [ ] Never marks a story Complete without the Phase 7 approval; closing over BLOCKED or NOT ASSESSED always prompts, in every automation mode
- [ ] "May I write this to `docs/tech-debt-register.md`?" before logging advisory deviations
- [ ] Never auto-fixes failing criteria; deviations are presented as facts, the user decides
- [ ] Evidence under `production/session-logs/` never counts; nothing is written there
- [ ] Ends by surfacing the next ready story, or the sprint close-out sequence (`/smoke-check sprint` → `/team-qa sprint` → `/retrospective sprint-[N]` → `/gate-check` → `/sprint-plan new`)

---

## Coverage Notes

- Readiness rubric mapping: RD1 (criteria, evidence, eleven deviation checks, code review —
  Cases 1–3, 9), RD2 (four verdicts and precedence — Cases 1–4), RD3 (BLOCKED for contract,
  PRD and migration-floor breaks — Cases 2, 4), RD4 (TL-CODE-REVIEW and QL-TEST-COVERAGE
  per review mode — Cases 6–8), RD5 (next-story surfacing — Case 1).
- The UI evidence sub-checks (captures beside `evidence.md`, pending sign-off rows) and the
  E2E "never run against a running environment" note are not fixture-tested here.
- Stories with several TR-IDs or several ADRs are not tested explicitly.
