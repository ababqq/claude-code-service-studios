# Skill Test Spec: /bug-triage

## Skill Summary

`/bug-triage` turns the unresolved bug backlog into a prioritised, sprint-assigned
action list. It reads `production/qa/bugs/BUG-*.md` (the only bug file format
`/bug-report` and `/team-qa` write) and cross-checks the `## Bugs Found` tables of
`production/qa/qa-signoff-*.md`. It separates **severity** (impact) from **priority**
(scheduling) using the same ladder strings `/bug-report` writes:

- `**Severity**: [S1-Critical / S2-Major / S3-Minor / S4-Trivial]`
- `**Priority**: [P1-Fix this sprint / P2-Fix soon / P3-Backlog / P4-Won't fix]`

A bug is **unresolved** when its `**Status**:` is `Open`, `In Progress` or
`Fixed — Pending Verification`; a missing or unknown status counts as unresolved and is
flagged `STATUS UNREADABLE`. Modes: `sprint`, `full`, `trend` (no argument = `sprint`
when a sprint plan exists, else `full`). The skill assigns P1/P2 bugs to the sprint,
gives every unresolved S1/S2 bug an owner and a target date (or `UNASSIGNED`), flags
systemic clusters by feature, surface and story, and computes trends.

The report is written to `production/qa/bug-triage-YYYY-MM-DD.md` after a "May I write
this to `<path>`?" ask. Verdicts: **COMPLETE** (report written), **BLOCKED** (the user
declined the write) and **NOT ASSESSED** (no bug records could be read, so there was
nothing to triage — never a report claiming zero unresolved bugs). No director gates
apply.

---

## Static Assertions (Structural)

Verified automatically by `/skill-test static` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] `name: bug-triage` equals the directory `.claude/skills/bug-triage/` and the catalog entry name
- [ ] First body line is exactly `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation` `` — `--keys` is exactly `automation`
- [ ] `allowed-tools` grants `Bash(bash "*/.claude/skills/bug-triage/../../hooks/yaml-helper.sh" resolve_config *)` (this skill's own directory)
- [ ] The line after the bootstrap block is exactly ``Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] The automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") follows that line verbatim
- [ ] `allowed-tools` is exactly `Read, Glob, Grep, Write, Edit` plus the bootstrap grant — no `Bash` beyond the grant, no `Agent`
- [ ] Has ≥2 phase headings (`## 1. Parse Arguments` … `## 6. Write and Gate`)
- [ ] Contains verdict keywords COMPLETE, BLOCKED and NOT ASSESSED
- [ ] Contains the severity and priority ladder strings exactly as `/bug-report` writes them, the six status values and the Unresolved definition
- [ ] Contains "May I write this to `production/qa/bug-triage-YYYY-MM-DD.md`?" and, for Won't Fix decisions, "May I write this to `production/qa/bugs/<BUG-ID>.md`?"
- [ ] Output path is exactly `production/qa/bug-triage-YYYY-MM-DD.md`; bug files are edited only for user-approved Won't Fix decisions
- [ ] No `!` injection other than the bootstrap line; no `file:line` citation of another file
- [ ] Has a next-step handoff naming current skills (`/sprint-status`, `/smoke-check`, `/bug-report`)

---

## Director Gate Checks

None. `/bug-triage` is an advisory QA utility. It spawns no agent and no director
gate; qa-lead rules on disputed severities outside the skill.

---

## Test Cases

### Case 1: Happy Path — Sprint triage of a mixed backlog

**Fixture:**
- Canonical product Moa; `production/sprints/sprint-07.md` is the newest sprint plan
- `production/qa/bugs/` contains:
  - `BUG-0003.md` — `S1-Critical`, `P1-Fix this sprint`, `Open`, Feature `payments`, Surface `api`
  - `BUG-0004.md` — `S2-Major`, `P2-Fix soon`, `In Progress`, Feature `goals`, Surface `ios`
  - `BUG-0005.md` — `S3-Minor`, `P3-Backlog`, `Fixed — Pending Verification`, Feature `notifications`
  - `BUG-0006.md` — `S4-Trivial`, `P3-Backlog`, `Open`, Feature `onboarding`
  - `BUG-0002.md` — `S2-Major`, `Verified Fixed`

**Input:** `/bug-triage sprint`

**Expected behavior:**
1. Skill globs `production/qa/bugs/BUG-*.md` and keeps the four unresolved bugs; `BUG-0002` counts only in the trend metrics (resolved this sprint)
2. Skill reads sprint-07 for scope and capacity
3. Skill fills the P1, P2 and P3/P4 tables with the exact ladder strings; every unresolved S1/S2 bug has an owner and a target date or `UNASSIGNED`
4. Skill presents the report and asks "May I write this to `production/qa/bug-triage-YYYY-MM-DD.md`?"
5. On approval the report is written; verdict is COMPLETE

**Assertions:**
- [ ] "Unresolved bugs processed" is 4 — `Fixed — Pending Verification` counts, `Verified Fixed` does not
- [ ] `BUG-0003` appears in the P1 table with an owner or `UNASSIGNED`, never an invented owner
- [ ] The Severity mix line lists S1-Critical … S4-Trivial counts
- [ ] The report is written only after approval; verdict is COMPLETE
- [ ] Because an S1 bug is present, the after-write message names `/sprint-status` when it is unassigned

---

### Case 2: NOT ASSESSED — No bug records found

**Fixture:**
- `production/qa/bugs/` does not exist (or is empty); no `qa-signoff-*.md` lists a `BUG-NNNN`

**Input:** `/bug-triage`

**Expected behavior:**
1. Skill globs `production/qa/bugs/BUG-*.md` and finds nothing
2. Skill reports "Verdict: **NOT ASSESSED** — no bug records found in `production/qa/bugs/`", asks whether bugs are tracked elsewhere (an issue tracker) or not yet filed, and stops
3. No triage report is written

**Assertions:**
- [ ] Verdict is NOT ASSESSED, naming the searched glob
- [ ] No report stating "0 unresolved bugs" (or COMPLETE) is produced — an empty backlog read and an unreadable one are not the same result
- [ ] No write tool is called
- [ ] `/bug-report` is named as the way to file a bug

---

### Case 3: Data Issues — Unreadable status, label mismatch, sign-off ID without a file

**Fixture:**
- `BUG-0010.md` has no `**Status**:` line
- `BUG-0011.md` has `**Severity**: High` (not a ladder string)
- `production/qa/qa-signoff-sprint-07-2026-11-02.md` lists `BUG-0014` under `## Bugs Found`; no `BUG-0014.md` exists

**Input:** `/bug-triage full`

**Expected behavior:**
1. `BUG-0010` is treated as unresolved and flagged `STATUS UNREADABLE`
2. `BUG-0011` is flagged `LABEL MISMATCH` with the text found (`High`) so it can be corrected with `/bug-report`
3. `BUG-0014` is listed as `NO FILE` — never silently dropped
4. All three appear under `## Data Issues`

**Assertions:**
- [ ] An unknown status is never read as resolved
- [ ] The mismatched label is quoted, not silently mapped to a ladder value
- [ ] `NO FILE` IDs from sign-off reports are listed
- [ ] The rest of the backlog is triaged normally

---

### Case 4: Systemic Issues — Surface cluster and regression in a completed story

**Fixture:**
- Three unresolved bugs on Surface `android` (auto-debit screen, notification permission, deep link) with no matching bugs on `ios` or `web`
- `BUG-0015.md` names `production/epics/goals-core/story-001-create-goal.md`, whose header is `> **Status**: Complete`

**Input:** `/bug-triage full`

**Expected behavior:**
1. The deviation check flags "Surface-specific defect cluster on android — check the platform layer, device matrix or store build"
2. `BUG-0015` is flagged as a regression in a completed story that should be re-opened in sprint tracking
3. The trend analysis names `android` as the surface hot spot and counts 1 regression

**Assertions:**
- [ ] The surface cluster is reported under `## Systemic Issues Flagged`
- [ ] The regression is detected from the story status (`> **Status**: Complete` or `status: done` in `production/sprint-status.yaml`)
- [ ] After writing, the skill suggests re-opening the story and running `/smoke-check`
- [ ] Trend findings are observations; no work is blocked on them alone

---

### Case 5: Mode Variant — `trend` reads header fields only

**Fixture:**
- `production/qa/bugs/` contains 30 bug files

**Input:** `/bug-triage trend`

**Expected behavior:**
1. Skill computes volume, severity mix, feature and surface hot spots, age and regressions from the bolded header fields (a Grep of `**Severity**`, `**Priority**`, `**Status**`, `**Feature**`, `**Surface**`, `**Category**`, `**Reported**`)
2. No bug body is read for re-evaluation and no bug is assigned to a sprint

**Assertions:**
- [ ] No sprint assignment happens in `trend` mode
- [ ] Header fields are matched in their bolded `**field**` form
- [ ] No bug file is modified

---

### Case 6: Won't Fix — Only with the user's approval, one file at a time

**Fixture:**
- `BUG-0006.md` (`S4-Trivial`) is proposed as a P4 candidate during review

**Input:** `/bug-triage full`

**Expected behavior:**
1. Skill surfaces `BUG-0006` as a P4 candidate and asks "Are these acceptable as Won't Fix?"
2. The user approves; skill asks "May I write this to `production/qa/bugs/BUG-0006.md`?"
3. On approval it sets `**Priority**: P4-Won't fix` and `**Status**: Won't Fix`; nothing else in the file changes

**Assertions:**
- [ ] No bug is marked Won't Fix without the user's explicit approval
- [ ] Only the two fields change in the bug file
- [ ] The triage report lists the bug under P3/P4 with disposition Won't Fix

---

### Case 7: Director Gate Check — No gate; triage is advisory

**Fixture:**
- `production/qa/bugs/` contains any number of reports

**Input:** `/bug-triage`

**Expected behavior:**
1. Skill produces the triage report
2. No agents or director gates are spawned

**Assertions:**
- [ ] No director gate is invoked and no gate skip note appears
- [ ] The verdict comes from the write outcome (COMPLETE / BLOCKED) or the missing-input rule (NOT ASSESSED), never from a gate

---

## Protocol Compliance

- [ ] Reads every `production/qa/bugs/BUG-*.md` before building the tables
- [ ] Counts unresolved bugs by the single Unresolved definition, never by `Open` alone
- [ ] Presents severity as a recommendation and priority as a team decision
- [ ] Never auto-assigns to a sprint at capacity — overflow is flagged for the sprint owner
- [ ] Never closes a bug or marks it Won't Fix without the user's approval
- [ ] Asks "May I write this to `<path>`?" before the report and before each bug-file edit
- [ ] Writes nothing under `production/session-logs/`

---

## Coverage Notes

- Duplicate detection by title similarity is not part of this skill's contract;
  clusters by feature, surface and story replace it.
- Capacity overflow ("Priority overflow — consider pulling from sprint") is not
  fixture-tested separately; it follows from the sprint plan's capacity note.
- The Build → Hardening gate reads owners and target dates for unresolved S2 bugs;
  this spec checks that the report carries them (or `UNASSIGNED`), not the gate itself.
