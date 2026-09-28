# Skill Test Spec: /skill-test

## Skill Summary

`/skill-test` validates `.claude/skills/*/SKILL.md` files and `.claude/agents/*.md` files
in four modes:

- **static** (`static [name | all]`): a structural linter — 7 checks per skill
  (frontmatter fields, multiple phases, verdict keywords, ask-before-write language,
  next-step handoff, fork-context complexity, argument-hint plausibility). Result per
  skill: COMPLIANT / WARNINGS / NON-COMPLIANT / NOT ASSESSED.
- **spec** (`spec [skill-name | agent-name]`): evaluates every assertion of the item's
  spec (path from the `spec:` field in `CCSS Skill Testing Framework/catalog.yaml`) as
  PASS / PARTIAL / FAIL / NOT ASSESSED, overall precedence
  **FAIL > PARTIAL > NOT ASSESSED > PASS**; for agents it also evaluates the spec's
  Static Assertions and the agent category's rubric metrics.
- **category** (`category [name | all]`): scores a skill against its category section
  of `CCSS Skill Testing Framework/quality-rubric.md` (PASS / FAIL / WARN per metric);
  `utility` skills are evaluated against U1 and U2 only.
- **audit**: derives skills and agents from disk by Glob, diffs them against the
  catalog (UNCATALOGED, ORPHAN ENTRY, NO SPEC, MISPLACED SPEC, UNKNOWN CATEGORY) and
  reports coverage with on-disk denominators. No writes.

Its outputs are `CCSS Skill Testing Framework/results/skill-test-spec-[name]-[date].md`
(gitignored, verdict line under the H1) and the catalog's `last_*` fields — each after
approval, and never a new field in an entry.

---

## Static Assertions (Structural)

Verified automatically by `/skill-test static` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`; `name: skill-test` equals the directory `.claude/skills/skill-test/` and the catalog entry `skill-test`
- [ ] `description` is exactly "Validate skills and agents: static linter, spec, category rubric, audit."; `argument-hint` is `"static [skill-name | all] | spec [skill-name | agent-name] | category [skill-name | all] | audit"`
- [ ] Bootstrap: the first body line is `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation` `` — this key string exactly
- [ ] `allowed-tools` grants `Bash(bash "*/.claude/skills/skill-test/../../hooks/yaml-helper.sh" resolve_config *)` — the skill's own directory name
- [ ] The line after the bootstrap block is exactly ``Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] The automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") follows that line verbatim
- [ ] `allowed-tools` is exactly: `Read, Glob, Grep, Write` + the grant (no plain `Bash`, no `Edit`, `Agent` or `AskUserQuestion`)
- [ ] Has ≥2 phase headings (`## Phase 1: Parse Arguments`, `## Phase 2A` … `## Phase 2D`, `## Phase 3: Recommended Next Steps`)
- [ ] Contains the verdicts `COMPLIANT`, `WARNINGS`, `NON-COMPLIANT`, `NOT ASSESSED` (static); `PASS`, `PARTIAL`, `FAIL`, `NOT ASSESSED` (spec); `PASS`, `FAIL`, `WARN` (category)
- [ ] Contains "May I write these results to `CCSS Skill Testing Framework/results/skill-test-spec-[name]-[date].md` and update `CCSS Skill Testing Framework/catalog.yaml`?" and "May I update `CCSS Skill Testing Framework/catalog.yaml` to record this category check (`last_category`, `last_category_result`) for [name]?"
- [ ] Outputs: `CCSS Skill Testing Framework/results/skill-test-spec-[name]-[date].md` with `> **Verdict**:` directly under its H1, and the catalog `last_*` fields only
- [ ] Framework paths all live under `CCSS Skill Testing Framework/`; the agent folder map is `director → agents/directors/`, `lead → agents/leads/`, `specialist → agents/specialists/`, `qa → agents/qa/`, `operations → agents/operations/`, `stack → agents/stack/`
- [ ] The skill categories are listed as `gate`, `review`, `authoring`, `readiness`, `pipeline`, `analysis`, `team`, `sprint`, `ops`, `utility`; agent categories `director`, `lead`, `specialist`, `stack`, `qa`, `operations`
- [ ] No literal skill or agent count is written into the file (counts come from Glob); no `!` injection other than the bootstrap line; no `file:line` citations
- [ ] Has a next-step handoff (`/skill-test spec [name]`, `/skill-improve [name]`, `/skill-test audit`, the two spec templates)

---

## Director Gate Checks

None. `/skill-test` is a meta-utility: `review_mode` is not in its keys and it has no
`Agent` tool. No director gates apply.

---

## Test Cases

### Case 1: Static Mode — Well-formed skill, COMPLIANT

**Fixture:**
- `.claude/skills/brainstorm/SKILL.md` has all frontmatter fields, numbered phases, verdict keywords (`COMPLETE`, `INCOMPLETE`), "May I write" language, a next-step section and an argument hint that matches its modes

**Input:** `/skill-test static brainstorm`

**Expected behavior:**
1. Reads the SKILL.md fully and runs the 7 checks
2. Prints `=== Skill Static Check: /brainstorm ===` with one line per check
3. Verdict: COMPLIANT

**Assertions:**
- [ ] Exactly 7 checks are reported, each with its result
- [ ] Verdict is COMPLIANT
- [ ] No file is written in static mode

---

### Case 2: Static Mode — `Write` without ask-before-write language

**Fixture:**
- `.claude/skills/tech-debt/SKILL.md` lists `Write` in `allowed-tools` and contains no "May I write" or equivalent

**Input:** `/skill-test static tech-debt`

**Expected behavior:**
1. Check 4 FAILs: `Write` in `allowed-tools` with no ask-before-write language
2. The other checks are shown with their own results
3. Verdict: NON-COMPLIANT, with a recommendation

**Assertions:**
- [ ] Check 4 is FAIL with the mismatch explained
- [ ] Verdict is NON-COMPLIANT
- [ ] Passing checks are shown, not only the failure

---

### Case 3: NOT ASSESSED — Spec file missing; rubric section missing; unevaluable assertion

**Fixture:**
- `.claude/skills/goal-reminders/SKILL.md` exists, but its catalog entry points at a `spec:` path that does not exist
- A catalog entry whose `category:` has no `` ### `<category>` `` heading in the rubric
- A spec assertion that names a fixture state the spec never defines

**Input:** `/skill-test spec goal-reminders`; `/skill-test category <that skill>`; `/skill-test spec <skill with the unevaluable assertion>`

**Expected behavior:**
1. Spec mode stops with "Spec file missing at [path]. Run `/skill-test audit` to see coverage gaps."
2. Category mode reports `NOT ASSESSED — no rubric section for category '[category]'` for that skill
3. The unevaluable assertion is marked NOT ASSESSED; a run with no FAIL or PARTIAL and at least one NOT ASSESSED is `NOT ASSESSED`, not `PASS`

**Assertions:**
- [ ] Missing inputs are named with their path
- [ ] NOT ASSESSED ranks above PASS and below PARTIAL and FAIL
- [ ] No unevaluable assertion is resolved to PASS because the skill "probably" handles it

---

### Case 4: Spec Mode — `gate-check` against its spec

**Fixture:**
- `.claude/skills/gate-check/SKILL.md` exists; the catalog `skills:` entry points at `CCSS Skill Testing Framework/skills/gate/gate-check.md`

**Input:** `/skill-test spec gate-check`

**Expected behavior:**
1. Reads the SKILL.md and the spec fully
2. Marks each assertion PASS / PARTIAL / FAIL / NOT ASSESSED, with a reason for every non-PASS, and evaluates the Protocol Compliance block
3. Prints `=== Skill Spec Test: /gate-check ===` with per-case verdicts and the overall verdict
4. Asks "May I write these results to `CCSS Skill Testing Framework/results/skill-test-spec-gate-check-[date].md` and update `CCSS Skill Testing Framework/catalog.yaml`?"
5. On yes, writes the results file starting `# Skill Spec Test: /gate-check`, blank line, `> **Verdict**: <TOKEN>`, and sets only `last_spec` and `last_spec_result` in the entry

**Assertions:**
- [ ] Every case of the spec is evaluated, each with its own verdict
- [ ] The overall verdict follows FAIL > PARTIAL > NOT ASSESSED > PASS
- [ ] The catalog entry gains no new field; only the two fields change

---

### Case 5: Spec Mode — An agent (`sre-engineer`)

**Fixture:**
- `.claude/agents/sre-engineer.md` exists; the catalog `agents:` entry has `category: operations` and a `spec:` under `CCSS Skill Testing Framework/agents/operations/`

**Input:** `/skill-test spec sre-engineer`

**Expected behavior:**
1. Resolves the name to the agent file and the catalog `agents:` entry
2. Evaluates the spec's Static Assertions (frontmatter, body headings in the canonical agent order, escalation path, domain boundary), the cases, and the `` ### `operations` `` rubric metrics under `Category Metrics: (operations)`
3. Prints `=== Agent Spec Test: sre-engineer ===`; on approval writes `# Agent Spec Test: sre-engineer` with the verdict line and updates `last_spec` / `last_spec_result`

**Assertions:**
- [ ] The agent's category metrics count toward the overall verdict
- [ ] Agent entries are never given `last_category` fields

---

### Case 6: Audit Mode — Skills and agents derived from disk

**Fixture:**
- One skill directory on disk has no catalog entry; one catalog entry has no directory; one entry's `spec:` file is missing

**Input:** `/skill-test audit`

**Expected behavior:**
1. Globs `.claude/skills/*/SKILL.md` and `.claude/agents/*.md` and diffs both lists against the catalog
2. Prints the skill and agent coverage tables and `Catalog drift:` with `UNCATALOGED`, `ORPHAN ENTRY`, `NO SPEC`, `MISPLACED SPEC`, `UNKNOWN CATEGORY` (each a list or "none")
3. Coverage percentages use the on-disk counts as denominators
4. Offers `/skill-test static all`, `/skill-test category all` or `/skill-test spec [name]`

**Assertions:**
- [ ] Agents are enumerated from disk, not only from the catalog
- [ ] Every count is derived in the run; an uncataloged item lowers coverage instead of disappearing
- [ ] No file is written in audit mode

---

### Case 7: Category Mode — Gate skill and a utility skill

**Fixture:**
- `CCSS Skill Testing Framework/quality-rubric.md` has `` ### `gate` `` (G1–G5) and `` ### `utility` `` (U1, U2)
- `.claude/skills/gate-check/SKILL.md` (category `gate`) and `.claude/skills/help/SKILL.md` (category `utility`)

**Input:** `/skill-test category gate-check`, then `/skill-test category help`

**Expected behavior:**
1. For `gate-check`, reads the `gate` section and marks G1–G5 PASS / FAIL / WARN, quoting the gap for each FAIL or WARN
2. For `help`, evaluates U1 (static checks pass) and U2 (gate mode, if applicable) only
3. Asks "May I update `CCSS Skill Testing Framework/catalog.yaml` to record this category check (`last_category`, `last_category_result`) for [name]?"

**Assertions:**
- [ ] Metrics are read from the rubric, never hard-coded in the skill
- [ ] Each FAIL or WARN names the exact gap
- [ ] The catalog is updated only after approval

---

### Case 8: Edge Case — `static all` with an unreadable skill

**Fixture:**
- One `.claude/skills/*/SKILL.md` cannot be parsed (broken frontmatter)

**Input:** `/skill-test static all`

**Expected behavior:**
1. The unreadable skill is a table row with `NOT ASSESSED` and its reason
2. The header states `[N] of [M] skills checked` when they differ; `[M]` is the Glob count
3. The summary line counts COMPLIANT, WARNINGS, NON-COMPLIANT and NOT ASSESSED separately

**Assertions:**
- [ ] The unreadable skill is never omitted or counted as COMPLIANT
- [ ] The denominator is derived from the Glob, not written into the skill

---

### Case 9: Director Gate Check — No gate; skill-test is a meta utility

**Fixture:**
- Any skill with a spec

**Input:** `/skill-test spec prd-review`

**Expected behavior:**
1. Runs the behavioral check
2. No director agents are spawned; no gate IDs appear as spawn instructions

**Assertions:**
- [ ] No director gate is invoked

---

## Protocol Compliance

- [ ] Static mode runs exactly the 7 structural checks
- [ ] Spec mode evaluates each case of the spec individually and records NOT ASSESSED honestly
- [ ] Audit mode covers skills and agents derived from disk
- [ ] Category mode reads the rubric section for the item's category
- [ ] Writes only the results file and the catalog `last_*` fields, each after "May I write" / "May I update", per the automation prelude; nothing under `production/session-logs/`
- [ ] Suggests `/skill-improve` when issues are found

---

## Category Rubric (`utility`)

- `utility U1` — the static checks above pass: bootstrap line and grant exact, `--keys` exact, plain follow-on line, automation prelude, ask-before-write for the results file and the catalog, outputs exact
- `utility U2` — not applicable (no director gate)
- The NOT ASSESSED case is Case 3 (missing input: spec file, rubric section, or fixture definition)

---

## Coverage Notes

- The skill can test itself; the static case for its own SKILL.md is not fixture-tested separately.
- Check 3 (verdict keywords) WARNs rather than FAILs for skills whose output is a value, not a judgement —
  `/settings` is the reference case; not fixture-tested here.
- Results files live in a gitignored folder; the catalog `last_*` fields are the tracked record.
