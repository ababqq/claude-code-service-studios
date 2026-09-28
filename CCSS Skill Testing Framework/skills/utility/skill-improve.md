# Skill Test Spec: /skill-improve

## Skill Summary

`/skill-improve` runs one test → fix → retest → keep-or-revert loop on a single skill.
It establishes a baseline with `/skill-test static [name]` and — when the skill has a
`category:` in `CCSS Skill Testing Framework/catalog.yaml` — `/skill-test category [name]`,
recording FAILs and WARNs for each. It diagnoses every failing or warning check (static
Checks 1–7 and the category's rubric metrics), shows the combined diagnosis, proposes
targeted before/after fixes that change only what is failing, and asks "May I write
this improved version to `.claude/skills/[name]/SKILL.md`?".

After the write it re-runs the same tests and compares the combined failure count
(static FAILs + category FAILs + static WARNs + category WARNs). A lower count keeps
the change ("Score improved. Changes kept."); the same or a higher count reports
"Combined score did not improve." and asks "May I revert
`.claude/skills/[name]/SKILL.md` using git checkout?" before running
`git checkout -- .claude/skills/[name]/SKILL.md`. A skill that already passes both
exits with "This skill already passes all static and category checks. No improvements
needed." A missing or unknown skill name ends in Phase 1 with
`Verdict: **NOT ASSESSED** — <reason>`. A static or category `/skill-test` run that returns
`NOT ASSESSED` or errors — the baseline or the retest — is never counted as 0 FAILs and 0
WARNs: Phase 6 reports `Verdict: **NOT ASSESSED** — [which run, and why]`, computes no
improved / not-improved result, and keeps or reverts the edit only on the user's explicit
answer to "Keep the edit to `.claude/skills/[name]/SKILL.md`, or revert it with git
checkout?". Its only output is edits to one SKILL.md.

---

## Static Assertions (Structural)

Verified automatically by `/skill-test static` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`; `name: skill-improve` equals the directory `.claude/skills/skill-improve/` and the catalog entry `skill-improve`
- [ ] `description` is exactly "Improve a skill via a static and category test-fix-retest loop; keep or revert on score change."; `argument-hint` is `"[skill-name]"`
- [ ] Bootstrap: the first body line is `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation` `` — this key string exactly
- [ ] `allowed-tools` grants `Bash(bash "*/.claude/skills/skill-improve/../../hooks/yaml-helper.sh" resolve_config *)` — the skill's own directory name
- [ ] The line after the bootstrap block is exactly ``Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] The automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") follows that line verbatim
- [ ] `allowed-tools` is exactly: `Read, Glob, Grep, Write, Bash` + the grant (no `Edit`, `Agent` or `AskUserQuestion`)
- [ ] Has ≥2 phase headings (`## Phase 1: Parse Argument` … `## Phase 7: Next Steps`)
- [ ] Contains the outcome lines "Score improved. Changes kept." and "Combined score did not improve."
- [ ] Contains the verdict keyword `NOT ASSESSED` (`Verdict: **NOT ASSESSED** — <reason>`)
- [ ] Contains "May I write this improved version to `.claude/skills/[name]/SKILL.md`?" before the write and "May I revert `.claude/skills/[name]/SKILL.md` using git checkout?" before the revert
- [ ] Output: edits to one `.claude/skills/[name]/SKILL.md`; catalog and rubric paths read from `CCSS Skill Testing Framework/`
- [ ] No `!` injection other than the bootstrap line; no `file:line` citations of other files
- [ ] Has a next-step handoff (`/skill-test static all`, `/skill-improve [next-name]`, `/skill-test audit`)

---

## Director Gate Checks

None. `/skill-improve` is a meta-utility: `review_mode` is not in its keys and it has no
`Agent` tool. No director gates apply.

---

## Test Cases

### Case 1: Happy Path — Two static failures fixed, change kept

**Fixture:**
- `.claude/skills/tech-debt/SKILL.md` has `Write` in `allowed-tools` but no ask-before-write language (Check 4 FAIL) and no follow-up section (Check 5 WARN)
- Its catalog entry has `category: analysis`; the category baseline is 0 FAILs, 0 WARNs

**Input:** `/skill-improve tech-debt`

**Expected behavior:**
1. Runs `/skill-test static tech-debt` and shows `Static baseline:   1 failures, 1 warnings` with the failing checks named
2. Runs `/skill-test category tech-debt` and shows the category baseline
3. Reads the full SKILL.md and diagnoses Check 4 (Write without ask-before-write) and Check 5 (no next-step section)
4. Shows before/after blocks that change only those gaps; asks "May I write this improved version to `.claude/skills/tech-debt/SKILL.md`?"
5. Records the current content, writes, re-runs both tests and shows the comparison lines
6. Combined count is lower: reports "Score improved. Changes kept." with a summary per dimension

**Assertions:**
- [ ] The baseline is established before any change is proposed
- [ ] Passing sections are not rewritten
- [ ] The comparison shows `Static:` and `Category:` before → after and `Combined change: improved`
- [ ] The change is kept without a revert prompt

---

### Case 2: Regression — Combined score gets worse, revert on confirmation

**Fixture:**
- `.claude/skills/tech-debt/SKILL.md` has one static WARN (Check 5)
- The proposed fix removes the verdict keywords by accident (a new Check 3 FAIL)

**Input:** `/skill-improve tech-debt`

**Expected behavior:**
1. Baseline: 0 FAILs, 1 WARN
2. After the approved write the retest shows 1 FAIL, 0 WARNs — the combined count is not lower
3. Reports "Combined score did not improve.", shows what changed and why it may not have helped
4. Asks "May I revert `.claude/skills/tech-debt/SKILL.md` using git checkout?"; on yes runs `git checkout -- .claude/skills/tech-debt/SKILL.md`

**Assertions:**
- [ ] The retest is compared with the baseline before anything is kept
- [ ] The revert needs the user's confirmation (never automatic)
- [ ] On "no", the file stays as written and the user is told the score did not improve

---

### Case 3: NOT ASSESSED — Missing argument or unknown skill

**Fixture:**
- No `.claude/skills/goal-reminders/` directory

**Input:** `/skill-improve`, then `/skill-improve goal-reminders`

**Expected behavior:**
1. With no argument, prints the usage block (`Usage: /skill-improve [skill-name]`, `Example: /skill-improve tech-debt`) and stops with `Verdict: **NOT ASSESSED** — no skill name given`
2. With an unknown name, stops with "Skill 'goal-reminders' not found." and `Verdict: **NOT ASSESSED** — skill 'goal-reminders' not found`

**Variant — a baseline test that could not run:** `.claude/skills/tech-debt/SKILL.md` exists, but a
baseline `/skill-test` run returns `NOT ASSESSED` (e.g. `/skill-test category tech-debt` reports
`NOT ASSESSED — no rubric section for category '<category>'`). The run's verdict is `NOT ASSESSED`,
naming the baseline that could not run — never "Score improved. Changes kept.", "Combined score did
not improve." or "No improvements needed.".

**Variant — a retest that could not run:** both baselines ran, the user approved the write, and the
Phase 5 `/skill-test static tech-debt` or `/skill-test category tech-debt` retest returns
`NOT ASSESSED` or errors. The comparison shows `Combined change: not assessed (a run could not
complete)`; Phase 6 reports `Verdict: **NOT ASSESSED** — [which run, and why]` and asks "Keep the edit
to `.claude/skills/tech-debt/SKILL.md`, or revert it with git checkout?", then acts on the answer.

**Assertions:**
- [ ] Both stops print the NOT ASSESSED verdict line
- [ ] The two stops run no baseline and propose no fix
- [ ] No file is written or reverted by the two stops
- [ ] No "improved" or "no improvements needed" outcome is claimed for a skill that was never tested
- [ ] Variant: a baseline `/skill-test` run that returns `NOT ASSESSED` makes the verdict `NOT ASSESSED`, never improved / not improved; that baseline is not counted as 0 failures
- [ ] Retest variant: a retest that returns `NOT ASSESSED` or errors makes the verdict `NOT ASSESSED`; no improved / not-improved result is computed from the missing count
- [ ] Retest variant: the edit is kept or reverted only on the user's explicit answer — no automatic keep and no automatic revert

---

### Case 4: Category Baseline — Gate skill with static and category failures

**Fixture:**
- `.claude/skills/gate-check/SKILL.md` has 1 static FAIL and 2 category FAILs against `` ### `gate` `` in `CCSS Skill Testing Framework/quality-rubric.md` (e.g. G2: the director panel is not sized by `modes.workflow`)

**Input:** `/skill-improve gate-check`

**Expected behavior:**
1. Captures both baselines (`Category baseline: 2 failures, 0 warnings  (gate rubric)`)
2. Diagnoses the static failure and each failing metric by quoting the gap in the skill text
3. Asks "May I write this improved version to `.claude/skills/gate-check/SKILL.md`?"; writes; re-runs both tests
4. Keeps or reverts on the combined count

**Assertions:**
- [ ] The category is read from `CCSS Skill Testing Framework/catalog.yaml`, the rubric from `CCSS Skill Testing Framework/quality-rubric.md`
- [ ] The combined count (static + category FAILs and WARNs) decides keep or revert
- [ ] The full combined diagnosis is shown before any change is proposed

---

### Case 5: Already Clean — No improvements needed

**Fixture:**
- `.claude/skills/help/SKILL.md` has 0 static FAILs and WARNs; its category (`utility`) baseline is also clean

**Input:** `/skill-improve help`

**Expected behavior:**
1. Both baselines are 0 FAILs and 0 WARNs
2. Stops with "This skill already passes all static and category checks. No improvements needed."

**Assertions:**
- [ ] No change is proposed and no "May I write" is asked
- [ ] No file is modified

---

### Case 6: Edge Case — No category assigned; the write is declined

**Fixture:**
- A skill whose catalog entry has no `category:` field and one static FAIL

**Input:** `/skill-improve <that skill>` → the user answers "no" to the write question

**Expected behavior:**
1. Phase 2b prints "Category: not yet assigned — skipping category checks." and continues with static checks only
2. After the proposal the user declines; the skill stops

**Assertions:**
- [ ] The skipped category check announces itself
- [ ] Nothing is written on "no"

---

### Case 7: Director Gate Check — No gate; skill-improve is a meta utility

**Fixture:**
- A skill with at least one static failure

**Input:** `/skill-improve tech-debt`

**Expected behavior:**
1. Runs the test-fix-retest loop
2. No director agents are spawned; no gate IDs appear

**Assertions:**
- [ ] No director gate is invoked and no gate skip message appears

---

## Protocol Compliance

- [ ] Always establishes a baseline before proposing any change
- [ ] Shows before/after blocks and the before/after score comparison
- [ ] Asks "May I write this improved version to `.claude/skills/[name]/SKILL.md`?" before the write, per the automation prelude
- [ ] Asks before reverting; never reverts automatically
- [ ] Reports `NOT ASSESSED` when the skill cannot be named or found, or a baseline or retest could not run — never a score outcome
- [ ] Edits only the one SKILL.md; writes nothing under `production/session-logs/`
- [ ] Ends with next steps (`/skill-test static all`, `/skill-improve [next-name]`, `/skill-test audit`)

---

## Category Rubric (`utility`)

- `utility U1` — the static checks above pass: bootstrap line and grant exact, `--keys` exact, plain follow-on line, automation prelude, "May I write" before the write, output exact (one SKILL.md)
- `utility U2` — not applicable (no director gate)
- The NOT ASSESSED case is Case 3 (missing input: no skill name, or no such skill) and its two
  variants (a baseline or a retest `/skill-test` run that returned NOT ASSESSED or errored)

---

## Coverage Notes

- One fix-retest cycle runs per invocation; further iterations need another `/skill-improve` run.
- Behavioral (`spec`-mode) results are not part of the loop — only static and category scores.
- The revert uses `git checkout -- <path>`, so it restores the last committed version, not an uncommitted earlier
  edit; not fixture-tested here.
