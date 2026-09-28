# Skill Spec: /[skill-name]

> **Category**: [gate | review | authoring | readiness | pipeline | analysis | team | sprint | ops | utility]
> **Priority**: [critical | high | medium | low]
> **Spec written**: [YYYY-MM-DD]

<!-- Save this spec at `CCSS Skill Testing Framework/skills/[category]/[skill-name].md`
     (the folder is the catalog `category:`). Assert the canonical English text of
     SKILL.md — quoted prompts such as "May I write this to `<path>`?", AskUserQuestion
     option labels, verdict tokens, headings — never the wording the model uses at run
     time in the user's conversation language. -->

## Skill Summary

[One paragraph describing what this skill does, what inputs it takes, and what outputs it produces.]

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`); `name` equals the skill directory and the catalog `name`
- [ ] Bootstrap (skills that resolve config): the first body line is `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys [exact keys]` `` and `allowed-tools` grants `Bash(bash "*/.claude/skills/[skill-name]/../../hooks/yaml-helper.sh" resolve_config *)` with this skill's own directory name. Skills that resolve no config: no bootstrap line and no grant
- [ ] The line after the bootstrap block is exactly the follow-on line of `.claude/docs/config-resolution.md` § The rule — the `--review` variant when `review_mode` is in the keys, the plain variant otherwise
- [ ] Automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") present verbatim right after that line when `automation` is in the keys; absent from the always-collaborative skills (`.claude/docs/automation-modes.md` § Exemptions — Skills That Ignore the Automation Setting)
- [ ] `allowed-tools` is exactly: [tool list — membership exact, order free]
- [ ] 2+ phase headings found
- [ ] Verdict keywords present, exactly as the skill defines them: [e.g., `PASS`, `CONCERNS`, `FAIL`, `NOT ASSESSED`] — `NOT ASSESSED` (or the skill's `NOT CHECKED — <reason>` line) is available
- [ ] If `allowed-tools` includes Write/Edit: "May I write this to `<path>`?" before each write
- [ ] Outputs at the exact paths: [paths]; every report or record with a verdict carries `> **Verdict**: <TOKEN>` directly under its H1
- [ ] No `!` injection other than the bootstrap line; no `file:line` citations of other files
- [ ] Next-step handoff section present at end, naming skills by their current names

---

## Director Gate Checks

[Describe which director gates this skill triggers (if any), and under what review mode conditions.
Gate-spawning skills pass the gate file path plus the gate's Context bullets on a `Pass:` line and
parse the agent's first line as `[GATE-ID]: TOKEN` — `.claude/docs/director-gates.md`.]

- **Full mode**: [gates spawned — e.g., PD-PRD-ALIGN]
- **Lean mode**: skip every gate whose ID does not end in `-PHASE-GATE` — note `[GATE-ID] skipped — Lean mode` ([which gates, if any, still run])
- **Solo mode**: no gates — note `[GATE-ID] skipped — Solo mode`
- **Review-mode exempt** (`/hotfix`, `/rollout-plan`, `/incident` only): [the exemption sentence is present verbatim; every agent and gate the skill names runs at every `review_mode`; the skill does not resolve `review_mode`]
- **N/A**: [if this skill never triggers gates, explain why]

---

## Test Cases

Write at least 4 cases, and always include Case 3 (NOT ASSESSED). A skill that spawns director
gates adds one case per review mode (Cases 6–8); `/hotfix`, `/rollout-plan` and `/incident`
replace Cases 6–8 with the exemption case. Delete the case templates that do not apply.
Fixtures use the framework's example product (Moa — e.g., `design/prd/goals.md`,
`production/epics/goals-core/story-001-create-goal.md`).

### Case 1: Happy Path — [brief name]

**Fixture** (assumed project state):
- [file/condition 1]
- [file/condition 2]

**Expected behavior**:
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Assertions**:
- [ ] [Assertion 1]
- [ ] [Assertion 2]
- [ ] [Assertion 3]

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — [brief name]

**Fixture**:
- [invalid or blocking condition — e.g., a Proposed ADR, a failing check]

**Expected behavior**:
1. [Skill detects the problem]
2. [Skill reports FAIL/BLOCKED]
3. [Skill does NOT proceed]

**Assertions**:
- [ ] Skill stops early and does not produce output
- [ ] Correct error/block message displayed
- [ ] No files written without user approval

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: NOT ASSESSED — [missing input]

**Fixture**:
- [a required input is absent or unreadable — e.g., no PRD at `design/prd/goals.md`, or the stack layer the skill needs is unset]

**Expected behavior**:
1. [Skill detects that it cannot assess the scope]
2. [Skill reports NOT ASSESSED (or its `NOT CHECKED — <reason>` line) naming the missing input]
3. [Skill does NOT resolve the gap to PASS]

**Assertions**:
- [ ] Verdict is NOT ASSESSED (or the named NOT CHECKED line), with the reason stated
- [ ] No PASS-class verdict is produced for the unassessed scope
- [ ] Unset configuration is not treated as false or none

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Mode Variant — [brief name]

**Fixture**:
- [standard project state]
- [specific mode, argument or flag set]

**Expected behavior**:
1. [Behavior differs from happy path because of mode]

**Assertions**:
- [ ] [Mode-specific assertion]
- [ ] [Output differs correctly from Case 1]

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Edge Case — [brief name]

**Fixture**:
- [unusual or boundary condition]

**Expected behavior**:
1. [Skill handles gracefully]

**Assertions**:
- [ ] [Edge case handled without crash or silent failure]
- [ ] [Correct output or message]

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Director Gate — full mode

**Fixture**:
- [project state that triggers a gate check]
- Review mode: `full` (resolved, or `--review full`)

**Expected behavior**:
1. [Gate spawns with the gate file path and a `Pass:` line of its Context bullets]
2. [Skill parses the first line `[GATE-ID]: TOKEN` and maps the token to its verdict class]

**Assertions**:
- [ ] In full mode: [specific gates spawn]
- [ ] A CONCERNS-class verdict is surfaced via AskUserQuestion (revise / accept / discuss)
- [ ] Skill does not auto-advance past a CONCERNS-class or REJECT-class verdict

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: Director Gate — lean mode

**Fixture**:
- [same project state as Case 6]
- Review mode: `lean`

**Expected behavior**:
1. [Every gate whose ID does not end in `-PHASE-GATE` is skipped]

**Assertions**:
- [ ] Output contains `[GATE-ID] skipped — Lean mode` for each skipped gate
- [ ] Only gate IDs ending in `-PHASE-GATE` spawn (none, for most skills)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 8: Director Gate — solo mode

**Fixture**:
- [same project state as Case 6]
- Review mode: `solo`

**Expected behavior**:
1. [No director gates spawn]

**Assertions**:
- [ ] In solo mode: no director gates spawn
- [ ] Output contains `[GATE-ID] skipped — Solo mode` for each gate

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6 (review-mode-exempt skills only): Review-Mode Exemption — [brief name]

**Fixture**:
- [project state that triggers the skill's agents or gate]
- Review mode: `solo` in `project.yaml`

**Expected behavior**:
1. [Skill runs every agent and gate it names regardless of `review_mode`]

**Assertions**:
- [ ] SKILL.md contains verbatim: "`/hotfix`, `/rollout-plan` and `/incident` are release-critical: every agent and gate they name runs at every `review_mode`. They do not resolve `review_mode`."
- [ ] `review_mode` is not among the skill's `--keys`
- [ ] [The named agent or gate — e.g., SR-PRODUCTION-READINESS for `/rollout-plan` — runs despite `solo`]

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses "May I write this to `<path>`?" before any file writes (or is read-only and skips this)
- [ ] Presents findings/draft to user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval
- [ ] Writes no evidence, reports or plans under `production/session-logs/` (gitignored)
- [ ] Never writes `modes.review_mode` or any other knob that `modes.rigor` fronts (`/settings` is the one exception)

---

## Coverage Notes

[Any gaps in coverage, known edge cases not tested, or conditions that would require
a live skill run to verify.]
