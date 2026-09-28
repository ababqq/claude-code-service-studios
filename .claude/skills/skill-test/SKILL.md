---
name: skill-test
description: "Validate skills and agents: static linter, spec, category rubric, audit."
argument-hint: "static [skill-name | all] | spec [skill-name | agent-name] | category [skill-name | all] | audit"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash(bash "*/.claude/skills/skill-test/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation`

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

# Skill Test

Validates `.claude/skills/*/SKILL.md` files for structural compliance and
behavioral correctness, and `.claude/agents/*.md` files against their behavioral
specs. No external dependencies — runs entirely within the existing
skill/hook/template architecture.

**Four modes:**

| Mode | Command | Purpose | Token Cost |
|------|---------|---------|------------|
| `static` | `/skill-test static [name\|all]` | Structural linter — 7 compliance checks per skill | Low (~1k/skill) |
| `spec` | `/skill-test spec [name]` | Behavioral verifier — evaluates assertions in the skill's or agent's test spec | Medium (~5k/item) |
| `category` | `/skill-test category [name\|all]` | Category rubric — checks skill against its category-specific metrics | Low (~2k/skill) |
| `audit` | `/skill-test audit` | Coverage report — skills and agents on disk vs the catalog, specs, last test dates | Low (~3k total) |

**Framework paths** (the `spec:` field in `CCSS Skill Testing Framework/catalog.yaml`
is authoritative; these are the conventions it follows):

- Skill specs: `CCSS Skill Testing Framework/skills/[category]/[name].md` — the folder
  is the skill category, singular.
- Agent specs: `CCSS Skill Testing Framework/agents/[folder]/[name].md` — the folder
  is the plural of the agent category: `director → agents/directors/`,
  `lead → agents/leads/`, `specialist → agents/specialists/`, `qa → agents/qa/`,
  `operations → agents/operations/`, `stack → agents/stack/`.
- Rubric: `CCSS Skill Testing Framework/quality-rubric.md`
- Results: `CCSS Skill Testing Framework/results/skill-test-spec-[name]-[date].md`
  (the folder is gitignored and created on the first write)

**Categories:**

- Skill categories (rubric `### \`<category>\`` headings under `## Skill Categories`):
  `gate`, `review`, `authoring`, `readiness`, `pipeline`, `analysis`, `team`,
  `sprint`, `ops`, `utility`.
- Agent categories (catalog `category:` values, singular; rubric headings under
  `## Agent Categories`): `director`, `lead`, `specialist`, `stack`, `qa`,
  `operations`.

---

## Phase 1: Parse Arguments

Determine mode from the first argument:

- `static [name]` → run 7 structural checks on one skill
- `static all` → run 7 structural checks on all skills (Glob `.claude/skills/*/SKILL.md`)
- `spec [name]` → read the skill or agent + its test spec, evaluate assertions.
  `[name]` is a skill when `.claude/skills/[name]/SKILL.md` exists and an agent when
  `.claude/agents/[name].md` exists (names are unique across both)
- `category [name]` → run category-specific rubric from `CCSS Skill Testing Framework/quality-rubric.md`
- `category all` → run category rubric for every skill that has a `category:` in catalog
- `audit` (or no argument) → enumerate skills and agents on disk, diff them against
  the catalog, show coverage

If argument is missing or unrecognized, output usage and stop.

---

## Phase 2A: Static Mode — Structural Linter

For each skill being tested, read its `SKILL.md` fully and run all 7 checks:

### Check 1 — Required Frontmatter Fields
The file must contain all of these in the YAML frontmatter block:
- `name:`
- `description:`
- `argument-hint:`
- `user-invocable:`
- `allowed-tools:`

**FAIL** if any are absent.

### Check 2 — Multiple Phases
The skill must have ≥2 numbered phase headings. Look for patterns like:
- `## Phase N` or `## Phase N:`
- `## N.` (numbered top-level sections)
- At least 2 distinct `##` headings if phases aren't explicitly numbered

**FAIL** if fewer than 2 phase-like headings are found.

### Check 3 — Verdict Keywords

The skill must communicate a clear outcome. Accept any of:

- **Gate / review verdicts** — `PASS`, `FAIL`, `CONCERNS`, `APPROVED`,
  `BLOCKED`, `COMPLETE`, `READY`, `COMPLIANT`, `NON-COMPLIANT`, `NOT ASSESSED`
- **Go / no-go verdicts** — `PROCEED`, `PIVOT`, `KILL`, `GO`, `NO-GO`,
  `VALIDATED`, `NOT VALIDATED`, `SHIPPED`
- **Severity scales** — `CRITICAL`, `HIGH`, `MEDIUM`, `LOW`, `SEV1`–`SEV4`,
  `S1-Critical`…`S4-Trivial`. Audit skills rank findings by severity instead of
  issuing one verdict for the whole run.
- **A report verdict line** — the skill writes `> **Verdict**: <TOKEN>` under a
  report's H1, with its own token list.

**FAIL** if none are present **and** the skill produces an assessment — its
description or body promises a review, audit, check, gate, or readiness
judgement.

**WARN** (never FAIL) if none are present and the skill's output is an artifact
or a value rather than a judgement. `/settings` is the reference case: it prints
and writes configuration and has no verdict to give. Do not invent one to
satisfy this check.

> The narrow earlier list (gate verdicts only, hard FAIL) failed skills for
> reasons that were not their fault — `/prototype` and `/walking-skeleton`
> advertise `PROCEED`/`PIVOT`/`KILL` and `VALIDATED`/`NOT VALIDATED` in their own
> descriptions, `/adopt` and `/security-audit` rank by severity, and `/settings`
> has no verdict by design. It misfired on 7% of the corpus, and a linter that
> cries wolf that often stops being read.

### Check 4 — Collaborative Protocol Language
The skill must contain ask-before-write language. Look for:
- `"May I write"` (canonical form)
- `"before writing"` or `"approval"` near file-write instructions
- `"ask"` + `"write"` in close proximity (within same section)

**WARN** if absent (some read-only skills legitimately skip this).
**FAIL** if `allowed-tools` includes `Write` or `Edit` but no ask-before-write language is found.

### Check 5 — Next-Step Handoff
The skill must end with a recommended next action or follow-up path. Look for:
- A final section mentioning another skill (e.g., `/story-done`, `/gate-check`)
- "Recommended next" or "next step" phrasing
- A "Follow-Up" or "After this" section

**WARN** if absent.

### Check 6 — Fork Context Complexity
If frontmatter contains `context: fork`, the skill should have ≥5 phase headings
(`##` level or numbered Phase N headers). Fork context is for complex multi-phase
skills; simple skills should not use it.

**WARN** if `context: fork` is set but fewer than 5 phases found.

### Check 7 — Argument Hint Plausibility
`argument-hint` must be non-empty. If the skill body mentions multiple modes
(e.g., "Mode A | Mode B"), the hint should reflect them. Cross-reference the
hint against the first phase's "Parse Arguments" section.

**WARN** if hint is `""` or if documented modes don't match hint.

---

### Static Mode Output Format

For a single skill:
```
=== Skill Static Check: /[name] ===

Check 1 — Frontmatter Fields:    PASS
Check 2 — Multiple Phases:       PASS (7 phases found)
Check 3 — Verdict Keywords:      PASS (PASS, FAIL, CONCERNS)
Check 4 — Collaborative Protocol: PASS ("May I write" found)
Check 5 — Next-Step Handoff:     WARN (no follow-up section found)
Check 6 — Fork Context Complexity: PASS (8 phases, context: fork set)
Check 7 — Argument Hint:         PASS

Verdict: WARNINGS (1 warning, 0 failures)
Recommended: Add a "Follow-Up Actions" section at the end of the skill.
```

For `static all`, produce a summary table then list any non-compliant skills:
```
=== Skill Static Check: All [M] Skills ===

Skill                  | Result       | Issues
-----------------------|--------------|-------
gate-check             | COMPLIANT    |
prd-review             | COMPLIANT    |
story-readiness        | WARNINGS     | Check 5: no handoff
...

Summary: [N] COMPLIANT, [N] WARNINGS, [N] NON-COMPLIANT, [N] NOT ASSESSED
Aggregate Verdict: N WARNINGS / N FAILURES / N NOT ASSESSED
```

**`NOT ASSESSED` is a per-skill result here, not only an aggregate line.** A skill
whose file could not be read or parsed, or whose checks could not run, is reported
as `NOT ASSESSED` with the reason — never omitted from the table and never counted
as COMPLIANT. Ranked **above COMPLIANT**, **below WARNINGS and NON-COMPLIANT**.

**And state the denominator.** `All [M] Skills` in the header must be the number
actually examined, not the number that exist: report `[N] of [M] skills checked`
whenever they differ. `[M]` is the count the Glob returned — never a number written
into this file. A summary whose counts silently sum to less than its own title is
the failure this skill is supposed to catch in others.

---

## Phase 2B: Spec Mode — Behavioral Verifier

### Step 1 — Locate Files

For a skill: find it at `.claude/skills/[name]/SKILL.md` and look up the spec path
in the `skills:` section of `CCSS Skill Testing Framework/catalog.yaml` — use the
`spec:` field for the matching entry.

For an agent: find it at `.claude/agents/[name].md` and look up the spec path in
the `agents:` section of the same catalog. Note the entry's `category:` — Step 3
evaluates that agent category's rubric metrics too.

If either is missing:
- Missing skill or agent: "'[name]' not found in `.claude/skills/` or `.claude/agents/`."
- Missing spec path in catalog: "No spec path set for '[name]' in catalog.yaml."
- Spec file not found at path: "Spec file missing at [path]. Run `/skill-test audit`
  to see coverage gaps."

### Step 2 — Read Both Files

Read the skill or agent file and the test spec file completely.

### Step 3 — Evaluate Assertions

For each **Test Case** in the spec:

1. Read the **Fixture** description (assumed state of project files)
2. Read the **Expected behavior** steps
3. Read each **Assertion** checkbox

For each assertion, evaluate whether the skill's (or agent's) written instructions,
if followed correctly given the fixture state, would satisfy it. This is a
Claude-evaluated reasoning check, not code execution.

Mark each assertion:
- **PASS** — the instructions clearly satisfy this assertion
- **PARTIAL** — the instructions partially address it, but with ambiguity
- **FAIL** — the instructions would NOT satisfy this assertion given the fixture
- **NOT ASSESSED** — the assertion could not be evaluated at all: it names a
  fixture state the spec never defines, depends on runtime behavior no static
  read can settle, or references a file or section that does not exist. Rank it
  **above PASS** (an assertion nobody could evaluate has not been satisfied) and
  **below PARTIAL and FAIL** (an ambiguity somebody identified is more actionable
  than one nobody could reach). Do not resolve an unevaluable assertion to PASS
  because the skill "probably" handles it — that judgement is what the spec exists
  to replace.

For **Protocol Compliance** assertions (always present):
- Check whether the skill requires "May I write" before file writes
- Check whether the skill presents findings before requesting approval
- Check whether the skill ends with a recommended next step
- Check whether the skill avoids auto-creating files without approval

For an **agent** spec, also evaluate:
- The spec's **Static Assertions** (file, frontmatter fields, body headings in the
  canonical agent order, escalation path, domain boundary) against the agent file
- The metrics of the agent's category from the rubric's `## Agent Categories`
  section (e.g. `### \`stack\`` for a stack agent), each marked PASS / FAIL / WARN
  with the gap quoted. They are reported under `Category Metrics:` and count toward
  the overall verdict — agent catalog entries carry no `last_category` fields.

**Overall verdict** — the worst case result, with precedence
**FAIL > PARTIAL > NOT ASSESSED > PASS**. A run in which any assertion was
`NOT ASSESSED` and none failed is `NOT ASSESSED`, not `PASS`.

### Step 4 — Build Report

```
=== Skill Spec Test: /[name] ===
Date: [date]
Spec: CCSS Skill Testing Framework/skills/[category]/[name].md

Case 1: [Happy Path — name]
  Fixture: [summary]
  Assertions:
    [PASS] [assertion text]
    [FAIL] [assertion text]
       Reason: The skill's Phase 3 says "..." but the fixture state means "..."
  Case Verdict: FAIL

Case 2: [Edge Case — name]
  ...
  Case Verdict: PASS

Protocol Compliance:
  [PASS] Uses "May I write" before file writes
  [PASS] Presents findings before asking approval
  [WARN] No explicit next-step handoff at end

Overall Verdict: FAIL (1 case failed, 1 warning)
```

For an agent, the header reads `=== Agent Spec Test: [name] ===`, the `Spec:` line
points at `CCSS Skill Testing Framework/agents/[folder]/[name].md`, and the report
adds `Static Assertions:` before the cases and `Category Metrics: ([category])` after
them.

### Step 5 — Offer to Write Results

"May I write these results to `CCSS Skill Testing Framework/results/skill-test-spec-[name]-[date].md`
and update `CCSS Skill Testing Framework/catalog.yaml`?"

If yes:
- Write the results file (path above). The file starts with
  an H1 and, directly under it after one blank line, the verdict line:
  ```markdown
  # Skill Spec Test: /[name]

  > **Verdict**: [PASS | PARTIAL | FAIL | NOT ASSESSED]
  ```
  (`# Agent Spec Test: [name]` for an agent), followed by the report of Step 4.
- Update the entry for `[name]` in `CCSS Skill Testing Framework/catalog.yaml` (the
  `skills:` or the `agents:` section):
  - `last_spec: [date]`
  - `last_spec_result: PASS|PARTIAL|FAIL|NOT ASSESSED`

  Change only those two fields; never add fields to an entry.

---

## Phase 2D: Category Mode — Rubric Evaluation

### Step 1 — Locate Skill and Category

Find skill at `.claude/skills/[name]/SKILL.md`.
Look up `category:` field in `CCSS Skill Testing Framework/catalog.yaml`.

If skill not found: "Skill '[name]' not found."
If no `category:` field: "No category assigned for '[name]' in catalog.yaml.
Add `category: [name]` to the skill entry first."
If the category has no `### \`[category]\`` heading in the rubric: report
`NOT ASSESSED — no rubric section for category '[category]'` for that skill.

For `category all`: collect all skills with a `category:` field and process each.
`category: utility` skills are evaluated against U1 (static checks pass) and U2
(gate mode correct if applicable) only — skip to the static mode for U1.

Agents are not evaluated in this mode: their category metrics run inside
`/skill-test spec [agent-name]` (Phase 2B).

### Step 2 — Read Rubric Section

Read `CCSS Skill Testing Framework/quality-rubric.md`.
Extract the section matching the skill's category under `## Skill Categories` — the
headings `### \`gate\`` through `### \`utility\`` (e.g., `### \`gate\``, `### \`ops\``).
The `## Agent Categories` headings (`### \`director\`` through `### \`operations\``,
including `### \`stack\``) are read only by spec mode for agents (Phase 2B). Metric IDs
are scoped to their category heading — the skill category `ops` and the agent category
`operations` both number from `O`, `specialist` and `stack` both from `S` — so a metric
is always named together with its category (the report header carries it).

### Step 3 — Read Skill

Read the skill's `SKILL.md` fully.

### Step 4 — Evaluate Rubric Metrics

For each metric in the category's rubric table:
1. Check whether the skill's written instructions clearly satisfy the criterion
2. Mark PASS, FAIL, or WARN
3. For FAIL/WARN, identify the exact gap in the skill text (quote the relevant section
   or note its absence)

### Step 5 — Output Report

```
=== Skill Category Check: /[name] ([category]) ===

Metric G1 — Review mode read:              PASS
Metric G2 — Panel width:                   FAIL
  Gap: Section 4b spawns only DM-PHASE-GATE at workflow full; PD-PHASE-GATE,
       TD-PHASE-GATE, DD-PHASE-GATE absent, and the omitted directors are not named
Metric G3 — Lean mode: PHASE-GATE only:    PASS
Metric G4 — Solo mode: no directors:       PASS
Metric G5 — No auto-advance:               PASS

Verdict: FAIL (1 failure, 0 warnings)
Fix: Apply the panel-width table in Section 4b (1 / 2 / 4 directors by
     `modes.workflow`), omit DD-PHASE-GATE when no UI surface is configured, and
     list every omitted director under "Name the omissions".
```

### Step 6 — Offer to Update Catalog

"May I update `CCSS Skill Testing Framework/catalog.yaml` to record this category check
(`last_category`, `last_category_result`) for [name]?"

---

## Phase 2C: Audit Mode — Coverage Report

### Step 1 — Read Catalog

Read `CCSS Skill Testing Framework/catalog.yaml`. If missing, note that catalog doesn't exist
yet (first-run state) — every skill and agent on disk is then reported as uncataloged.

### Step 2 — Enumerate All Skills and Agents

Derive both lists from disk — never from the catalog alone, or anything added
since the catalog was last edited ships outside coverage:

- Glob `.claude/skills/*/SKILL.md` — the skill name is the directory name.
- Glob `.claude/agents/*.md` — the agent name is the file stem.

Then diff each list against the catalog's `skills:` and `agents:` sections:

- **UNCATALOGED** — on disk, no catalog entry
- **ORPHAN ENTRY** — catalog entry with no skill directory or agent file
- **NO SPEC** — catalog entry whose `spec:` file does not exist
- **MISPLACED SPEC** — `spec:` path outside the folder its category maps to
  (skills: `skills/[category]/`; agents: the plural folder map above)
- **UNKNOWN CATEGORY** — a `category:` value with no rubric heading

### Step 3 — Build Skill Coverage Table

For each skill:
- Check if a spec file exists (use the `spec:` path from catalog, or glob `CCSS Skill Testing Framework/skills/*/[name].md`)
- Look up `last_static`, `last_static_result`, `last_spec`, `last_spec_result`,
  `last_category`, `last_category_result`, `category` from catalog (or mark as
  "never" / "—" if not in catalog)
- Priority comes from catalog `priority:` field (critical/high/medium/low)

### Step 3b — Build Agent Coverage Table

For each agent found on disk (Step 2):
- Check if a spec file exists (use the `spec:` path from catalog, or glob `CCSS Skill Testing Framework/agents/*/[name].md`)
- Look up `last_spec`, `last_spec_result`, `category` from catalog

### Step 4 — Output Report

```
=== Skill Test Coverage Audit ===
Date: [date]

SKILLS ([N] on disk, [M] in catalog)
Specs written: [N] ([P]%) | Never static tested: [N] | Never category tested: [N]

Skill                  | Cat      | Has Spec | Last Static | S.Result | Last Cat | C.Result | Priority
-----------------------|----------|----------|-------------|----------|----------|----------|----------
gate-check             | gate     | YES      | never       | —        | never    | —        | critical
prd-review             | review   | YES      | never       | —        | never    | —        | critical
...

AGENTS ([N] on disk, [M] in catalog)
Agent specs written: [N] ([P]%)

Agent                  | Category   | Has Spec | Last Spec   | Result
-----------------------|------------|----------|-------------|--------
product-director       | director   | YES      | never       | —
technical-director     | director   | YES      | never       | —
...

Catalog drift:
  UNCATALOGED:      [names, or "none"]
  ORPHAN ENTRY:     [names, or "none"]
  NO SPEC:          [names, or "none"]
  MISPLACED SPEC:   [names, or "none"]
  UNKNOWN CATEGORY: [names, or "none"]

Top 5 Priority Gaps (skills with no spec, critical/high priority):
(none if all specs are written)

Skill coverage:  [N]/[M] specs ([P]%)
Agent coverage:  [N]/[M] specs ([P]%)
```

Every count is derived from the Globs and the catalog read in this run; the
denominators are the on-disk counts, so an uncataloged item lowers coverage
instead of disappearing from it.

No file writes in audit mode.

Offer: "Would you like to run `/skill-test static all` to check structural
compliance across all skills? `/skill-test category all` to run category rubric
checks? Or `/skill-test spec [name]` to run a specific behavioral test?"

---

## Phase 3: Recommended Next Steps

After any mode completes, offer contextual follow-up:

- After `static [name]`: "Run `/skill-test spec [name]` to validate behavioral
  correctness if a test spec exists."
- After `static all` with failures: "Address NON-COMPLIANT skills first. Run
  `/skill-test static [name]` individually for detailed remediation guidance, or
  `/skill-improve [name]` to run the fix-and-retest loop."
- After `spec [name]` PASS: "Update `CCSS Skill Testing Framework/catalog.yaml` to record this
  pass date. Consider running `/skill-test audit` to find the next spec gap."
- After `spec [name]` FAIL: "Review the failing assertions and update the skill
  (or agent) or the test spec to resolve the mismatch."
- After `audit`: "Start with UNCATALOGED items and the critical-priority gaps. Use
  the spec templates at `CCSS Skill Testing Framework/templates/skill-test-spec.md`
  and `CCSS Skill Testing Framework/templates/agent-test-spec.md` to create new specs."
