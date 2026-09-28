# Skill Test Spec: /project-stage-detect

## Skill Summary

`/project-stage-detect` answers "where are we?". It runs on the Haiku model. It takes
the stage from the shared estimator — `bash .claude/scripts/stage-estimate.sh`, whose
four lines are `STAGE:`, `SOURCE:` (`project.yaml` or `estimated`), `ESTIMATE:` and
`EVIDENCE:` — and inventories every catalogued artifact with one
`bash .claude/scripts/artifact-check.sh` call (no `--phase`: all phases), applying each
step's `tiers=` and `when=` fields against the resolved `workflow`, `platform.surfaces`,
`stack`, `compliance`, `release.distribution` and `localization.locales`. It then covers
nine areas — Product, UX & Design Language, Code (per resolved root), Architecture &
API, Data, Security & Privacy, Ops & Observability, Tests & CI, Release — writing
`NOT CHECKED — <reason>` for any area it could not check.

It always compares the configured stage with the estimate and says so when they
disagree; it never writes the stage (only `/gate-check` does, on PASS plus explicit
confirmation). Gaps are surfaced per the workflow tier and turned into clarifying
questions. The report follows `.claude/docs/templates/project-stage-report.md` and is
written to `production/project-stage-report-YYYY-MM-DD.md` after approval, with
`> **Verdict**: <TOKEN>` directly under its H1: `PASS`, `CONCERNS`, `FAIL` or
`NOT ASSESSED`, precedence **FAIL > CONCERNS > NOT ASSESSED > PASS**.

---

## Static Assertions (Structural)

Verified automatically by `/skill-test static` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`; `name: project-stage-detect` equals the directory `.claude/skills/project-stage-detect/` and the catalog entry `project-stage-detect`
- [ ] `description` is exactly "Where are we? Stage (via stage-estimate.sh), gaps and next steps."; `model: haiku`
- [ ] Bootstrap: the first body line is `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys workflow,automation,surfaces,compliance,distribution,stack,code_roots` `` — this key string exactly
- [ ] `allowed-tools` grants `Bash(bash "*/.claude/skills/project-stage-detect/../../hooks/yaml-helper.sh" resolve_config *)` — the skill's own directory name
- [ ] The line after the bootstrap block is exactly ``Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] The automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") follows that line verbatim
- [ ] `allowed-tools` is exactly: `Read, Glob, Grep, Bash, Write` + the grant (no `Edit`, `Agent` or `AskUserQuestion`)
- [ ] Has ≥2 phase headings (`### 1. Scan Key Directories` … `### 6. Request Approval Before Writing`)
- [ ] Contains the seven stage values `Discovery`, `Definition`, `Architecture`, `Validation`, `Build`, `Hardening`, `Launch`
- [ ] Contains the verdict tokens `PASS`, `CONCERNS`, `FAIL`, `NOT ASSESSED` and the precedence **FAIL > CONCERNS > NOT ASSESSED > PASS**
- [ ] Contains "May I write this to `production/project-stage-report-YYYY-MM-DD.md`?"
- [ ] Output at the exact path `production/project-stage-report-YYYY-MM-DD.md`, from `.claude/docs/templates/project-stage-report.md`, with `> **Verdict**:` directly under the H1
- [ ] No stage ladder of its own and no stage-to-phase mapping table; no `!` injection other than the bootstrap line; no `file:line` citations
- [ ] Has a next-step handoff naming current skills (`/map-features`, `/reverse-document`, `/api-design`, `/data-model`, `/prototype report`, `/sprint-plan`, `/milestone-review`, `/adopt`, `/gate-check <next-phase>`)

---

## Director Gate Checks

None. `/project-stage-detect` is a diagnostic utility: `review_mode` is not in its keys
and it has no `Agent` tool. No director gates apply.

---

## Test Cases

### Case 1: Configured stage agrees with the artifacts — PASS

**Fixture:**
- `project.yaml`: `project.stage: Build`, `modes.rigor: standard`, backend and web layers configured with roots `apps/api` and `apps/web`
- `stage-estimate.sh` prints `STAGE: Build`, `SOURCE: project.yaml`, `ESTIMATE: Build`
- `design/prd/goals.md`, `docs/architecture/adr-0001-identity-and-auth.md`, `docs/api/openapi.yaml`, `production/epics/goals-core/story-001-create-goal.md`, `production/sprint-status.yaml` with a story `in-progress`, `production/walking-skeleton/report-2026-09-15.md`

**Input:** `/project-stage-detect`

**Expected behavior:**
1. Runs `stage-estimate.sh` and `artifact-check.sh` (no `--phase`) and keeps all four estimator lines
2. Covers the nine areas; counts source files per resolved root, skipping `node_modules`, `.next`, `dist` and the other dependency or build directories
3. Configured and estimated stage agree; no required gap blocks Build
4. Shows the summary, gaps and next steps, then asks "May I write this to `production/project-stage-report-YYYY-MM-DD.md`?"
5. Writes the report with `> **Verdict**: PASS` under the H1 and `**Stage Source**: project.yaml — <EVIDENCE clause>`

**Assertions:**
- [ ] The stage is taken from `stage-estimate.sh`, not re-derived
- [ ] Every one of the nine area headings is present in the report
- [ ] The verdict line reads exactly `> **Verdict**: PASS`
- [ ] Nothing is written before approval; `project.yaml` is never written

---

### Case 2: No stage recorded — estimated stage

**Fixture:**
- No `project.stage`; `stage-estimate.sh` prints `STAGE: Validation`, `SOURCE: estimated`, `ESTIMATE: Validation`, `EVIDENCE: production/epics/goals-core/EPIC.md exists`
- Epics and a first sprint plan exist; no story is in progress

**Input:** `/project-stage-detect`

**Expected behavior:**
1. Reports the stage as Validation with `**Stage Source**: estimated — production/epics/goals-core/EPIC.md exists`
2. Recommends recording the stage through `/gate-check` with a **target** phase argument, not by writing it here

**Assertions:**
- [ ] The report says the stage is estimated and quotes the `EVIDENCE:` clause
- [ ] Any `/gate-check` suggestion names a target phase (e.g. `/gate-check build`)
- [ ] No stage value is written anywhere by this skill

---

### Case 3: NOT ASSESSED — The scans cannot run

**Fixture:**
- `.claude/docs/workflow-catalog.yaml` is unreadable, so `artifact-check.sh` exits with an error
- The block prints `code_roots: unresolved — NOT CHECKED (set stack.layers.<layer>.root via /setup-stack)`

**Input:** `/project-stage-detect`

**Expected behavior:**
1. The artifact inventory could not be produced; the skill does not hand-glob a substitute and call it complete
2. The Code area reads `NOT CHECKED — no code root resolved (set stack.layers.<layer>.root via /setup-stack)`; it never falls back to scanning `src/` or the whole repository
3. The report verdict is `NOT ASSESSED` (unless a known FAIL or CONCERNS finding outranks it) and says which scan could not run

**Assertions:**
- [ ] Verdict is NOT ASSESSED with the reason stated, not PASS
- [ ] Every area that could not be checked is written `NOT CHECKED — <reason>`, never left out
- [ ] An errored script run is never reported as an empty (clean) inventory

---

### Case 4: Discrepancy — Configured Launch, artifacts say Validation

**Fixture:**
- `project.stage: Launch`; `stage-estimate.sh` prints `SOURCE: project.yaml`, `ESTIMATE: Validation`
- Epics and a first sprint plan exist; 2 source files; no release checklist; no `production/releases/*/release-record.md`

**Input:** `/project-stage-detect`

**Expected behavior:**
1. Reports the configured stage (Launch) and the estimate (Validation) and states that they disagree
2. Suggests the configured stage may be stale or that work exists outside the repository
3. Verdict is CONCERNS

**Assertions:**
- [ ] The disagreement is stated explicitly, with the artifacts behind the estimate
- [ ] The configured value is not silently overridden and not rewritten
- [ ] Verdict is CONCERNS (FAIL only if a critical gap also blocks the current phase)

---

### Case 5: Mode Variant — `workflow: minimal`, surfaces unset

**Fixture:**
- No `modes.rigor` (resolves `workflow: minimal`); `design/product/one-pager.md` exists; `stack.pinned_on: 2026-09-20`
- The block prints `platform.surfaces: (unset -- ask which surfaces ship)`

**Input:** `/project-stage-detect`

**Expected behavior:**
1. Absent PRDs, design language, UX specs and ADRs are not flagged as gaps — a one-pager plus a pinned stack is the normal state, and code is the expected next step
2. The UX & Design Language area is not marked `N/A — no UI surface` (surfaces are unset, not empty); its `when=ui` steps are OPTIONAL "(required at standard,full)" by tier, so they are not gaps
3. Follow-up suggestions do not include authoring optional docs (no `/reverse-document` for an absent PRD)

**Assertions:**
- [ ] A step reported OPTIONAL "(required at …)" is never listed as a gap
- [ ] Unset surfaces are treated as unknown, never as "no UI"
- [ ] Steps the `minimal` tier does not require are reported OPTIONAL "(required at <tiers>)", naming the tiers that do

---

### Case 6: Role filter — `backend`

**Fixture:**
- A configured Moa project with `apps/api` present and no `docs/api/` contract

**Input:** `/project-stage-detect backend`

**Expected behavior:**
1. Recommendations focus on architecture docs, ADRs, the API contract, the data model and migration plans, contract and integration tests
2. The missing contract becomes a clarifying question: "`apps/api` exists but there is no API contract in `docs/api/`. Is the contract kept somewhere else, or should we run `/api-design`?"

**Assertions:**
- [ ] The role filter narrows the recommendations; the completeness overview still covers all nine areas
- [ ] Gaps are phrased as questions, not bare "missing file" lines

---

### Case 7: Director Gate Check — No gate; detection is advisory

**Fixture:**
- Any project state

**Input:** `/project-stage-detect`

**Expected behavior:**
1. Completes detection and presents the findings
2. No director agent is spawned; no gate IDs appear
3. The only write is the report, after approval

**Assertions:**
- [ ] No director gate is invoked
- [ ] The only file written is `production/project-stage-report-YYYY-MM-DD.md`, after "May I write"

---

## Protocol Compliance

- [ ] Runs `stage-estimate.sh` and `artifact-check.sh` before any judgement
- [ ] Always reports the configured stage and the estimate and flags disagreement
- [ ] Asks clarifying questions about gaps instead of listing missing files
- [ ] Uses "May I write this to `production/project-stage-report-YYYY-MM-DD.md`?" before the write, per the automation prelude
- [ ] Writes nothing under `production/session-logs/`; never writes `project.stage`, `modes.review_mode` or any knob `modes.rigor` fronts
- [ ] Ends with a next-step recommendation appropriate to the stage and tier

---

## Category Rubric (`utility`)

- `utility U1` — the static checks above pass: bootstrap line and grant exact, `--keys` exact, plain follow-on line, automation prelude, "May I write" before the write, output path exact with its verdict line
- `utility U2` — not applicable (no director gate)
- The NOT ASSESSED case is Case 3 (missing input: the catalog scan and the code roots)

---

## Coverage Notes

- The Hardening and Launch stages follow the same compare-and-report logic as Cases 1 and 4; not fixture-tested
  separately.
- `tiers_error=` / `when_error=` catalog defects are named in the report; not fixture-tested here.
- Line-count estimates per root are rough scale only and are not asserted.
