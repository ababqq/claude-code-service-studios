# Agent Spec: [agent-name]

> **Tier**: [directors | leads | specialists | qa | operations | stack]
> **Category**: [director | lead | specialist | qa | operations | stack]
> **Spec written**: [YYYY-MM-DD]

<!-- Tier = the spec folder under agents/; Category = the catalog `category:` value.
     Save this spec at `CCSS Skill Testing Framework/agents/[Tier]/[agent-name].md`.
     Assert the canonical English text of the agent file (quoted prompts, headings,
     verdict tokens) — never the wording the model uses at run time in the user's
     conversation language. -->

## Agent Summary

[One paragraph describing this agent's domain, what decisions it owns, and what it
delegates vs. handles directly. Include which director gates it owns (if any) and which
collaboration workflow it uses.]

**Domain**: [what this agent owns — decisions, artifacts, files/directories]
**Escalates to**: [parent agent — e.g., product-director for product conflicts, technical-director for technical ones]
**Delegates to**: [sub-agents this agent typically spawns or hands work to, or "—"]
**Gates owned**: [gate IDs with their exact verdict tokens, or "none"]

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/[name].md`; frontmatter `name` equals the file stem and the catalog `name`
- [ ] Frontmatter keys in canonical order: `name`, `description`, `tools`, `disallowedTools` (only when Bash is denied), `model`, `maxTurns`, then `memory`, `skills`, `isolation` (each only when set)
- [ ] `description` is one double-quoted line: the domain statement followed by "Use when …"
- [ ] `model:` matches `.claude/docs/model-tiers.md`; `tools` / `disallowedTools` match the role
- [ ] Opening line after the frontmatter: "You are the [Title] for a web/mobile/API product team."
- [ ] Body headings follow `.claude/rules/skill-authoring.md` § Agent file skeleton, in this order:
  1. `## Collaboration Protocol` — contains the agent's workflow (`### Strategic Decision Workflow`, `### Question-First Workflow`, `### Implementation Workflow` or `### Operations Workflow`), then the paragraph beginning "**Bounded exception — orchestrated runs.**"
  2. `## Core Responsibilities`
  3. `## [Domain] Standards` (e.g., `## API Standards`)
  4. `## Gate Verdict Format` — gate-owning agents only: each owned gate ID with its exact tokens and the first-line contract `[GATE-ID]: TOKEN`
  5. `## Sub-Specialist Orchestration` — stack layer leads with an `Agent(...)` grant only
  6. `## Version Awareness` — stack agents only
  7. `## What This Agent Must NOT Do`
  8. `## Delegation Map` — three lines: `Reports to:`, `Delegates to:`, `Coordinates with:`
- [ ] Every agent named in `Agent(...)`, `Delegates to:` or `Coordinates with:` exists under `.claude/agents/`
- [ ] Domain clearly stated
- [ ] Escalation path documented
- [ ] Does not make decisions outside its domain

---

## Test Cases

### Case 1: In-Domain Request — [brief name]

**Scenario**: A request that is clearly within this agent's domain.

**Fixture**:
- [relevant project state — e.g., `design/prd/goals.md` Approved, `docs/api/openapi.yaml` present]
- [input provided to agent]

**Expected behavior**:
1. Agent accepts the request
2. Agent produces [specific output type]
3. Agent asks "May I write this to [filepath]?" before writing files (if applicable)

**Assertions**:
- [ ] Agent handles request within its domain without escalating
- [ ] Output format matches expected structure
- [ ] Collaborative protocol followed (ask → draft → approve)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Out-of-Domain Redirect — [brief name]

**Scenario**: A request that falls outside this agent's domain.

**Fixture**:
- [request that belongs to a different agent]

**Expected behavior**:
1. Agent identifies the request is out of domain
2. Agent redirects to the correct agent
3. Agent does NOT attempt to handle it

**Assertions**:
- [ ] Agent declines and redirects (does not silently handle cross-domain work)
- [ ] Correct agent named in redirect

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Gate Verdict — [brief name]

**Scenario**: Agent is invoked as part of a director gate check. For an agent that owns no
gate, replace this case with a consultation case: the agent is spawned by a skill as a
consultant and returns findings in the format that skill asks for.

**Fixture**:
- [project state presented for review]
- [gate ID: e.g., TD-PHASE-GATE — the spawning skill passes the gate file path and the gate's Context bullets]

**Expected behavior**:
1. Agent reads the gate file and the documents named in the context
2. Agent produces one of the gate's exact verdict tokens (e.g., READY / CONCERNS / NOT READY), first line `[GATE-ID]: TOKEN`
3. Agent does not auto-advance on a CONCERNS-class or REJECT-class verdict

**Assertions**:
- [ ] First line of the output is `[GATE-ID]: TOKEN` with a token from the gate's own set
- [ ] Reasoning provided for verdict
- [ ] On a CONCERNS-class or REJECT-class verdict: work is blocked, not silently continued

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Conflict Escalation — [brief name]

**Scenario**: This agent's domain conflicts with another agent's decision.

**Fixture**:
- [conflicting decisions from two agents at same tier]

**Expected behavior**:
1. Agent identifies the conflict
2. Agent escalates to the shared parent (or product-director / technical-director when there is none)
3. Agent does NOT unilaterally resolve cross-domain conflicts

**Assertions**:
- [ ] Conflict surfaced explicitly
- [ ] Correct escalation path followed
- [ ] No unilateral cross-domain changes made

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Context Pass-Through — [brief name]

**Scenario**: Agent receives a task with full context from a parent agent or an
orchestrating skill.

**Fixture**:
- [context block passed from parent]
- [specific sub-task to execute]
- [destination path named by the orchestrator, if any — e.g., `production/qa/evidence/story-001-create-goal/`]

**Expected behavior**:
1. Agent reads and uses the provided context
2. Agent completes the sub-task
3. Agent returns result to parent (does not prompt user unnecessarily)

**Assertions**:
- [ ] Agent uses provided context rather than re-asking for it
- [ ] Result is scoped to the sub-task, not expanded beyond it
- [ ] Output format suitable for parent agent consumption
- [ ] Writes without a separate approval prompt only under the bounded exception (new file under `production/`, `docs/` or `tests/` at an orchestrator-named path); otherwise asks first

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: NOT ASSESSED — [brief name]

**Scenario**: A required input is missing (unset config key, absent artifact, no running
environment, no resolved code root).

**Fixture**:
- [the missing input — e.g., `accessibility.target` unset, no `tests/e2e/capture.spec.ts`]

**Expected behavior**:
1. Agent names the missing input and treats unset as unknown (never as "none" or a pass)
2. Agent reports NOT ASSESSED / NOT CHECKED / NOT VERIFIED with the reason instead of guessing
3. Agent names the step that would supply the input

**Assertions**:
- [ ] No fabricated value, measurement or verdict
- [ ] The missing input and the remedy are named

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Stays within declared domain — no unilateral cross-domain changes
- [ ] Escalates conflicts to correct parent
- [ ] Uses `"May I write this to [filepath]?"` before file writes (or is read-only), except under the bounded exception
- [ ] Presents findings before requesting approval
- [ ] Does not skip tiers in the delegation hierarchy
- [ ] Operations Workflow agents: never executes a command that changes production, shared infrastructure, a shared database or secrets

---

## Coverage Notes

[Any gaps in coverage, known edge cases not tested, or behaviors that require
a live agent invocation to verify.]
