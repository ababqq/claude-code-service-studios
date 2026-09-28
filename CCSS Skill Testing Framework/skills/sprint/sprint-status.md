# Skill Spec: /sprint-status

> **Category**: sprint
> **Priority**: medium
> **Spec written**: 2026-09-28

## Skill Summary

`/sprint-status` is a fast, read-only sprint snapshot (Haiku tier). It finds the sprint
plan (the argument's sprint number, or the most recently modified file in
`production/sprints/`), computes days remaining, reads story status from
`production/sprint-status.yaml` — the authoritative source — or falls back to the story
files' `> **Status**:` lines with a warning, detects stale in-progress stories with one
grep over `> **Last Updated**:`, and assesses burndown as **On Track**, **At Risk** or
**Behind** by comparing completion % with time consumed % — or **NOT ASSESSED** when no
sprint file or no sprint dates exist (a STALE story still raises it to At Risk; order
Behind > At Risk > NOT ASSESSED > On Track). It places escalation flags at
the top (SPRINT AT RISK, all Must Haves complete, missing story files), stays under about
50 lines, makes at most one recommendation, never asks to write, and never writes a
file. The resolved `code_roots` line bounds an optional implementation-evidence hint. No
director gate.

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`); `name` is `sprint-status`, equal to the directory `.claude/skills/sprint-status/` and the catalog `name`; `model: haiku` is kept
- [ ] Bootstrap: the first body line is `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys story_granularity,code_roots` `` and `allowed-tools` grants `Bash(bash "*/.claude/skills/sprint-status/../../hooks/yaml-helper.sh" resolve_config *)`
- [ ] `--keys` is exactly `story_granularity,code_roots`
- [ ] The line after the bootstrap block is exactly: ``Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] No automation prelude (`automation` is not among the keys) and no `AskUserQuestion`
- [ ] `allowed-tools` is exactly: `Read, Glob, Grep` plus the bootstrap grant — no `Write`, `Edit`, unrestricted `Bash` or `Agent`
- [ ] 2+ numbered section headings found (`## 1. Find the Sprint` … `## 6. Fast Escalation Rules`)
- [ ] Verdict keywords present, exactly: `On Track`, `At Risk`, `Behind`, `NOT ASSESSED` (the output heading `### Burndown: [On Track / At Risk / Behind / NOT ASSESSED]`), with the could-not-assess lines `Burndown: NOT ASSESSED — no sprint file found.` and "Burndown: NOT ASSESSED — sprint dates not found." and the order Behind > At Risk > NOT ASSESSED > On Track; story statuses `DONE`, `IN PROGRESS`, `IN REVIEW`, `BLOCKED`, `NOT STARTED`, `MISSING`, `STALE`
- [ ] No "May I write" language — the skill is read-only and says so ("**This skill is read-only.**")
- [ ] Output is a report in the conversation only (no file path is written)
- [ ] The yaml mapping reads `done` → DONE, `in-progress` → IN PROGRESS, `review` → IN REVIEW, `blocked` → BLOCKED, `ready-for-dev` and `backlog` → NOT STARTED — the hyphenated `in-progress` spelling
- [ ] The stale-story grep is the single pattern ``\*{0,2}(Last Updated|Updated|last-updated|updated_at)\*{0,2}[[:space:]]*:`` over `production/epics/**/story-*.md`, so the `> **Last Updated**:` header form matches
- [ ] With an unresolved `code_roots` line the hint is skipped with `NOT CHECKED — no code root resolved (set stack.layers.<layer>.root via /setup-stack)`
- [ ] No `!` injection other than the bootstrap line; no `file:line` citations of other files
- [ ] Handoffs name current skills: `/sprint-plan new`, `/sprint-plan update`, `/story-readiness sprint`, `/story-readiness [path]`, `/milestone-review`, `/retrospective`

---

## Director Gate Checks

- **Full mode**: no gate
- **Lean mode**: no gate
- **Solo mode**: no gate
- **Review-mode exempt**: not applicable
- **N/A**: a read-only snapshot; `review_mode` is not among the keys, and no review-mode file or setting is read

---

## Test Cases

Quoted prompts, labels and verdict tokens below are the canonical English text of
`SKILL.md`; at run time the model renders them in the user's conversation language.

### Case 1: Happy Path — Mixed sprint, Behind, with a named blocker

**Fixture** (assumed project state):
- `production/sprints/sprint-03.md` is the most recently modified sprint plan
- `production/sprint-status.yaml`: `sprint: 3`, `start: "2026-10-05"`, `end: "2026-10-16"`, 8 stories — 3 `done`, 2 `in-progress`, 1 `review`, 1 `blocked` (blocker: "Toss Payments sandbox credentials not issued"), 1 `ready-for-dev`
- Today is 2026-10-12 (about 64% of sprint time consumed); the in-progress stories were stamped `> **Last Updated**: 2026-10-10`

**Input:** `/sprint-status`

**Expected behavior:**
1. Section 1 picks `sprint-03.md` and reports which file was found
2. Section 2 computes total days, elapsed, remaining and % time consumed
3. Section 3 reads the yaml directly (no markdown scan); `review` displays as IN REVIEW and counts as in progress
4. Section 4: completion 3 / 8 = 37.5%, about 26 points behind time consumed → **Behind** (more than 25 points)
5. Section 5 prints the status table (not truncated), the burndown line, `### Must-Haves at Risk`, `### Emerging Risks` and one `### Recommendation`
6. The blocked story is named with its blocker

**Assertions:**
- [ ] `production/sprint-status.yaml` is read as the source of truth when present
- [ ] The yaml's `in-progress` and `review` values are mapped to IN PROGRESS and IN REVIEW
- [ ] The burndown verdict follows the thresholds (within 10 points On Track; 10–25 At Risk; more than 25 Behind)
- [ ] The blocked story and its blocker are named
- [ ] Exactly one recommendation; no file is written

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: All Must Haves complete

**Fixture:**
- `production/sprint-status.yaml` for sprint 3: every `must-have` story `done`; two `should-have` stories `backlog`

**Input:** `/sprint-status 3`

**Expected behavior:**
1. The argument finds `production/sprints/sprint-03.md` (`sprint-03.md`, `sprint-3.md` or similar)
2. The completion flag is placed at the top: "All Must Haves complete. Team can pull from Should Have backlog."
3. The Should Have stories are shown as NOT STARTED

**Assertions:**
- [ ] The completion flag appears above the status table
- [ ] `backlog` stories display as NOT STARTED
- [ ] No file is written and no approval is asked

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: NOT ASSESSED — No sprint files, no dates, no code root

**Fixture (variant A):** `production/sprints/` does not exist

**Fixture (variant B):** a sprint plan without start or end dates and no yaml; the `code_roots` line reads `code_roots: unresolved — NOT CHECKED (set stack.layers.<layer>.root via /setup-stack)`

**Input:** `/sprint-status`

**Expected behavior (variant A):**
1. Reports "No sprint files found. Start a sprint with `/sprint-plan new`." and `Burndown: NOT ASSESSED — no sprint file found.`, then stops

**Expected behavior (variant B):**
1. Section 2 notes "Sprint dates not found — burndown assessment skipped."
2. The burndown line reads "Burndown: NOT ASSESSED — sprint dates not found." (no in-progress story is STALE, so nothing raises it to At Risk)
3. The implementation-evidence hint is skipped with `NOT CHECKED — no code root resolved (set stack.layers.<layer>.root via /setup-stack)`

**Assertions:**
- [ ] With no sprint files the skill stops with guidance and `Burndown: NOT ASSESSED — no sprint file found.` instead of inventing a sprint
- [ ] Missing dates produce the NOT ASSESSED burndown line, never a confident On Track
- [ ] An unresolved code root prints the NOT CHECKED line rather than scanning a guessed directory

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Mode Variant — No yaml, markdown fallback and missing story files

**Fixture:**
- `production/sprints/sprint-03.md` references 6 story files; `production/sprint-status.yaml` does not exist
- One referenced story file `production/epics/goals-core/story-006-goal-share.md` does not exist; one inline task has no file

**Input:** `/sprint-status`

**Expected behavior:**
1. Section 3 falls back to markdown: each story's `> **Status**:` line maps `Complete` → DONE, `In Progress` → IN PROGRESS, `In Review` → IN REVIEW, `Blocked` → BLOCKED, `Ready` → NOT STARTED
2. The missing file is classified MISSING; the inline task is scanned in the sprint plan itself
3. The missing-stories flag appears at the top: "NOTE: 1 story files referenced in the sprint plan are missing. Run `/story-readiness sprint` to validate story file coverage."
4. The bottom note reads "⚠ No `sprint-status.yaml` found — status inferred from markdown. Run `/sprint-plan update` to generate one."

**Assertions:**
- [ ] The fallback is announced, not silent
- [ ] A missing story file is MISSING, not NOT STARTED without comment
- [ ] The missing-stories flag names `/story-readiness sprint`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Edge Case — Stale in-progress story

**Fixture:**
- As Case 1, but one `in-progress` story has `> **Last Updated**: 2026-10-06` (6 days before today) and another has no date line at all
- Completion is within 10 points of time consumed

**Input:** `/sprint-status`

**Expected behavior:**
1. One grep over `production/epics/**/story-*.md` resolves every date — no read per story
2. The 6-day-old story is flagged **STALE** (more than 4 days) and listed under `### Attention Needed`
3. The undated story is "no timestamp — cannot check staleness" ("never stamped"), with no age computed
4. The burndown verdict is raised to at least **At Risk** with the reason "At Risk — 1 story(ies) with no progress in 6 days."

**Assertions:**
- [ ] The `> **Last Updated**:` header form matches the stale-story pattern
- [ ] STALE is distinct from BLOCKED
- [ ] An undated story is not reported as stale
- [ ] A stale story escalates On Track to At Risk

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Critical flag — Must Haves at risk late in the sprint

**Fixture:**
- 70% of sprint time consumed; two `must-have` stories are `blocked` and one is `ready-for-dev`

**Input:** `/sprint-status`

**Expected behavior:**
1. The critical flag appears at the top, above the status table: "SPRINT AT RISK: 3 Must Have stories are not complete with 30% of sprint time remaining. Recommend replanning with `/sprint-plan update`."
2. `### Must-Haves at Risk` lists the three stories

**Assertions:**
- [ ] The flag fires when Must Haves are BLOCKED or NOT STARTED with less than 40% of the time remaining
- [ ] The recommendation points to `/sprint-plan update`; the skill proposes no scope cuts itself

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: Gate compliance — read-only at every review mode

**Fixture:**
- As Case 1; `project.yaml` sets `modes.review_mode: full`

**Input:** `/sprint-status`

**Expected behavior:**
1. No director gate is invoked; `review_mode` is not resolved
2. No "May I write" prompt; no `AskUserQuestion`; the report is produced without user interaction

**Assertions:**
- [ ] No gate is invoked at any review mode
- [ ] No file is written — not the sprint plan, not `production/sprint-status.yaml`, not a story file
- [ ] Story statuses are never changed by this skill

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Read-only: does not use Write or Edit, and does not ask for approval
- [ ] Presents the status table before the burndown verdict
- [ ] Ends with one concrete recommendation, or "Sprint is on track — no action needed."
- [ ] Reads the hyphenated `in-progress` value from `production/sprint-status.yaml` and never rewrites the file
- [ ] Writes nothing under `production/session-logs/` or anywhere else
- [ ] Never writes `modes.review_mode` or any other knob that `modes.rigor` fronts

---

## Coverage Notes

- `story_granularity` changes only the grain of the burndown read (feature-sized at
  `coarse`, task-sized at `balanced`, AC-sized at `fine`); it is covered by the bootstrap
  assertion, not a dedicated case.
- The implementation-evidence hint with a resolved `code_roots` line (a fast grep of the
  roots for the story's feature slug) is a hint, not a status, and is not given a fixture.
- Several sprint plans modified on the same day are resolved by "most recently modified";
  the tie case is not tested.
