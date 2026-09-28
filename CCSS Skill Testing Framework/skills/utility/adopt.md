# Skill Spec: /adopt

> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-09-28

<!-- Assertions quote the canonical English text of .claude/skills/adopt/SKILL.md —
     prompts, AskUserQuestion option labels, severity tokens, headings — never the
     wording the model uses at run time in the user's conversation language. -->

## Skill Summary

`/adopt` is the brownfield audit. It checks whether the artifacts an existing product
already has — product brief or one-pager, PRDs, the feature map, ADRs, the API
contract, the data model and migrations, stories and `production/sprint-status.yaml`,
tests & CI, SLOs and runbooks, the stack pin and the declared code roots — conform to
the framework's contracts (the headings, bold field labels and paths that skills,
scripts and gates match on). It does not ask *what exists* (that is
`/project-stage-detect`); it asks *will what exists work with the framework's skills*.

It takes an optional audit focus (`full | prds | adrs | api | data | stories | infra`),
reads the tree silently, runs `bash .claude/scripts/stage-estimate.sh` for the stage
and `bash .claude/scripts/prd-structure-check.sh <path>` once per PRD, classifies every
gap as BLOCKING / HIGH / MEDIUM / LOW, and — after approval — writes a numbered,
checkable plan to `docs/adoption-plan-YYYY-MM-DD.md`. Audits that could not run are
written as `NOT CHECKED — <audit>: <reason>` lines and collected in the plan's
`## Not Checked` section. The product is called framework-compatible only when there
are zero BLOCKING and zero HIGH gaps and no in-scope audit is NOT CHECKED; with zero
BLOCKING/HIGH but an audit that did not run, the run reports
`Verdict: **NOT ASSESSED** — <audits> did not run; framework compatibility unknown`
(BLOCKING and HIGH gaps outrank it). It never changes configuration: no `project.yaml` write, no
stage, no review mode. Phase 7 offers exactly one first fix; an in-place correction of
feature-map Status cells takes its own "May I write" approval.

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`); `name: adopt` equals the directory `.claude/skills/adopt/` and the catalog entry `adopt`
- [ ] `description` is exactly "Brownfield audit — do existing artifacts conform to CCSS contracts (PRD sections, feature map, ADR headings, API contract, migrations, tests/CI, runbooks)? Numbered adoption plan."
- [ ] `model: sonnet`; no `disable-model-invocation` and no `isolation` key
- [ ] Bootstrap: the first body line is `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,automation_always_ask,workflow,stack,code_roots,surfaces` `` — this key string exactly (comma-separated, no spaces)
- [ ] `allowed-tools` grants `Bash(bash "*/.claude/skills/adopt/../../hooks/yaml-helper.sh" resolve_config *)` — the skill's own directory name
- [ ] The line after the bootstrap block is exactly ``Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.`` (the plain variant — `review_mode` is not in the keys)
- [ ] The automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") follows that line verbatim
- [ ] `allowed-tools` is exactly: `Read, Glob, Grep, Bash, Write, AskUserQuestion` + the grant (membership exact, order free; no `Edit`, no `Agent`)
- [ ] 2+ phase headings (`## Phase 0: Configuration` through `## Phase 7: Offer First Action`)
- [ ] Severity tokens present exactly: `BLOCKING`, `HIGH`, `MEDIUM`, `LOW`; the skip form `NOT CHECKED — <audit>: <reason>` is defined; the run-level `Verdict: **NOT ASSESSED** — <audits> did not run; framework compatibility unknown` is available (Phase 3) and the summary carries a `Compatibility:` line
- [ ] "May I write this to `docs/adoption-plan-YYYY-MM-DD.md`?" before the plan write, and "May I write this to `design/product/feature-map.md`?" before the Phase 7 in-place fix
- [ ] Outputs at the exact path `docs/adoption-plan-YYYY-MM-DD.md`; the skill states it writes no `project.yaml` key
- [ ] No `!` injection other than the bootstrap line; no `file:line` citations of other files
- [ ] Next-step handoff at the end names current skills with their real argument order (`/architecture-decision retrofit <path>`, `/write-prd`, `/setup-stack`, `/project-stage-detect`, `/gate-check [target-phase]`)

---

## Director Gate Checks

N/A. `/adopt` spawns no director gate and no agent: `review_mode` is not in its keys
and `Agent` is not in its tools. It produces findings for the user to act on.

---

## Test Cases

### Case 1: Happy Path — Brownfield Moa repo at `standard`, full audit

**Fixture** (assumed project state):
- `project.yaml`: `modes.rigor: standard` (resolves `workflow: standard`), `stack.layers.web.framework: Next.js` with `root: [apps/web, apps/admin]`, `stack.layers.backend.framework: NestJS` with `root: [apps/api]`, `stack.pinned_on` unset (the `stack` line carries ` pinned_on=unset`); `platform.surfaces: [web, ios, android]`
- `design/product/product-brief.md` with every section the Discovery → Definition gate reads
- `design/product/feature-map.md` with the header `| Feature | Category | Layer | Tier | Status | PRD | Depends On |`; the `goals` row's Status reads `Needs Revision (see notes)`
- `design/prd/goals.md` (`> **Status**: Draft`) missing `## Acceptance Criteria`; `design/prd/auth.md` complete
- `docs/architecture/adr-0001-identity-and-auth.md` with no `## Status` heading
- `openapi.yaml` at the repository root; nothing in `docs/api/`
- `production/epics/goals-core/story-001-create-goal.md` without `> **Surface**:`
- `stage-estimate.sh` prints `STAGE: Architecture`, `SOURCE: estimated`, `ESTIMATE: Architecture`

**Input:** `/adopt`

**Expected behavior:**
1. Emits `"Scanning project artifacts..."`, then reads silently: runs `bash .claude/scripts/stage-estimate.sh` and keeps its four lines
2. Runs `bash .claude/scripts/prd-structure-check.sh design/prd/goals.md` and `… design/prd/auth.md` — one path per call, never bare
3. Applies the `standard` tier to the PRESENT/ABSENT lists: missing `## Acceptance Criteria` in `goals.md` is a HIGH gap
4. Classifies: feature-map parenthetical Status → BLOCKING; ADR missing `## Status` → BLOCKING; contract outside `docs/api/` → HIGH; stack not pinned → HIGH; story without `> **Surface**:` → MEDIUM
5. Shows the `## Adoption Audit Summary` block and a Gap Preview listing every BLOCKING item as a one-line bullet and HIGH / MEDIUM / LOW as counts
6. Asks via `AskUserQuestion` "May I write this to `docs/adoption-plan-YYYY-MM-DD.md`?" with the options "Yes — write `docs/adoption-plan-YYYY-MM-DD.md`" / "Show me the full plan preview first (don't write yet)" / "Cancel — I'll handle adoption manually"
7. On "Yes", writes the plan; the feature-map Status fix is item 1, and each affected ADR is its own `/architecture-decision retrofit docs/architecture/adr-NNNN-<slug>.md` item
8. Phase 7 offers the feature-map fix first (the highest-priority branch that applies)

**Assertions:**
- [ ] `prd-structure-check.sh` is called once per discovered PRD path, never without an argument
- [ ] Every gap carries exactly one of `BLOCKING`, `HIGH`, `MEDIUM`, `LOW`
- [ ] The plan has the headings `# Adoption Plan`, `## Step 1: Fix Blocking Gaps`, `## Step 2: Fix High-Priority Gaps`, `## Step 3: Bootstrap Infrastructure`, `## Step 4: Medium-Priority Gaps`, `## Step 5: Optional Improvements`, `## Not Checked`, `## What to Expect from Existing Stories`, `## Re-run`, in English exactly
- [ ] The plan header carries `> **Generated**:`, `> **Project stage**:`, `> **Stack**:`, `> **Workflow tier**:`, `> **Framework version**:`, `> **Audit focus**:`
- [ ] Step 3 lists `/setup-stack` → `/architecture-review` → `/create-control-manifest` → `/sprint-plan update` → `/gate-check [target-phase]` in that order
- [ ] The `/gate-check` argument is the **target** phase taken from `ESTIMATE` (here `/gate-check architecture`), never the departure phase
- [ ] Nothing is written before the user picks "Yes"

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Blocked — Fresh project, nothing to adopt

**Fixture:**
- The shipped template: no brief, one-pager, PRD, ADR or contract
- `stage-estimate.sh` prints `ESTIMATE: Discovery`
- The `code_roots` line resolves nothing (no declared, undeclared or detected root)

**Input:** `/adopt`

**Expected behavior:**
1. Phase 1 detects the fresh state
2. Asks via `AskUserQuestion`: "This looks like a fresh project — no existing artifacts found. `/adopt` is for products with work to bring under the framework. What would you like to do?" with the options "Run `/start` — begin guided first-time onboarding" / "My artifacts are in a non-standard location — help me find them" / "Cancel"
3. Stops after the answer, whichever option was picked

**Assertions:**
- [ ] The three option labels match SKILL.md exactly
- [ ] No Phase 2 audit runs and no plan file is written
- [ ] No `project.yaml` write occurs

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: NOT ASSESSED — Code exists but no code root resolves; lint command unset

**Fixture:**
- `apps/api/package.json` and `apps/api/src/goals/` exist
- The resolved block prints `code_roots: unresolved — NOT CHECKED (set stack.layers.<layer>.root via /setup-stack)` and `stack: unset — run /setup-stack`
- `platform.surfaces` unset (`platform.surfaces: (unset -- ask which surfaces ship)`)
- `docs/api/openapi.yaml` exists; `commands.api_lint` is not set in `project.yaml`

**Input:** `/adopt`

**Expected behavior:**
1. Every code-root-dependent audit prints `NOT CHECKED — no code root resolved (set stack.layers.<layer>.root via /setup-stack)`; the skill does not fall back to scanning `src/` or the whole repository
2. The backend condition is unknown (stack and surfaces unset), so the API and data audits still run and their findings carry "(condition unknown — run /setup-stack)"
3. The contract lint prints `NOT CHECKED — commands.api_lint not set`; the plan item is `/api-design review`
4. The 2i table records the unresolved code roots as **BLOCKING** (code present, nothing resolves) and the unset stack as HIGH
5. Every NOT CHECKED line appears in the summary's `Not checked:` line and in the plan's `## Not Checked` section with what would let it run

**Assertions:**
- [ ] No audit that could not run is counted as "no gaps"
- [ ] Unset surfaces or stack are not read as "no backend" (obligation 2 — unset is not false)
- [ ] The summary never states the product is framework-compatible while a BLOCKING or HIGH gap or any NOT CHECKED audit exists; its `Compatibility:` line reads `BLOCKING/HIGH gaps remain` here (gaps outrank NOT ASSESSED)
- [ ] The Phase 7 first action is the code-root branch: `Yes — run /setup-stack next` / `I'll declare them myself`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Mode Variant — `workflow: minimal`

**Fixture:**
- `project.yaml` without `modes.rigor` (resolves `workflow: minimal`)
- `design/product/one-pager.md` missing `## Build Order`
- `stack.pinned_on: 2026-09-20`; `design/prd/goals.md` exists but lacks `## Edge Cases`

**Input:** `/adopt`

**Expected behavior:**
1. The audit is scoped to the one-pager and the stack pin (2a, 2i); PRDs, ADRs and UX specs are not expected
2. The one-pager is checked for `## Pitch`, `## Problem & Target User`, `## Core User Journey`, `## Success Signal`, `## Scope & Non-Goals`, `## Stack`, `## Build Order`; the missing `## Build Order` is a gap
3. The existing PRD is checked advisorily at the `standard` bar: its missing `## Edge Cases` is informational, not a gap

**Assertions:**
- [ ] No "missing PRD / ADR / UX spec" gap is raised at `minimal`
- [ ] The one-pager heading list matches the one in SKILL.md exactly
- [ ] The plan's `> **Workflow tier**:` reads `minimal`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Edge Case — Specs and ADRs outside the framework's paths

**Fixture:**
- `docs/specs/goals-spec.md` and `docs/adr/0003-payments-provider.md` exist; `design/prd/` and `docs/architecture/` are empty
- `prd-structure-check.sh` prints `Not found:` for a candidate path the user named but that was moved

**Input:** `/adopt prds`

**Expected behavior:**
1. `docs/specs/goals-spec.md` is listed as a **PRD candidate**; the skill asks which candidates are feature specs instead of assuming
2. The candidate outside `design/prd/` (and its non-`<feature-slug>.md` name) is a HIGH location gap: invisible to the catalog, the gates and `prd-structure-check.sh`
3. The ADR under `docs/adr/` is an **ADR candidate** to relocate (reported only in a focus that includes ADRs)
4. `Not found:` is reported as "could not audit [path]" — a discovery failure, not a missing-sections finding

**Assertions:**
- [ ] Candidates are confirmed with the user before being audited as PRDs
- [ ] A relocation item names the references that change with the slug (feature-map row, `TR-<slug>-NNN` prefix, stories' `**PRD**:` field)
- [ ] A `Not found:` result never produces an ABSENT-sections gap

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Edge Case — Re-run with a prior plan; configuration stays untouched

**Fixture:**
- `docs/adoption-plan-2026-09-01.md` exists
- `project.yaml` has no `project.stage` and no `modes.review_mode`

**Input:** `/adopt`

**Expected behavior:**
1. Phase 1 notes the most recent prior plan
2. Phase 5 adds: "A previous plan exists at `docs/adoption-plan-2026-09-01.md`. The new plan will reflect current project state — it does not diff against the prior run."
3. The new plan is written to a new dated file after approval
4. `project.yaml` is not written: the plan tells the user that `/gate-check <target-phase>` records `project.stage` on PASS plus explicit confirmation

**Assertions:**
- [ ] The prior plan is referenced, not overwritten or diffed
- [ ] No write to `project.yaml` occurs in any phase — no stage, no `modes.review_mode`, none of the knobs `modes.rigor` fronts
- [ ] The stage-recording step names `/gate-check`, not `/adopt`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: NOT ASSESSED — No gaps found, but an audit did not run

**Fixture:**
- `project.yaml`: `modes.rigor: standard`, stack configured and pinned, code roots declared
- Every audit in scope finds no BLOCKING and no HIGH gap (two MEDIUM gaps)
- `docs/api/openapi.yaml` exists; `commands.api_lint` is not set in `project.yaml`

**Input:** `/adopt`

**Expected behavior:**
1. The contract lint prints `NOT CHECKED — commands.api_lint not set`
2. Phase 3 does not call the product framework-compatible: it reports `Verdict: **NOT ASSESSED** — <audits> did not run; framework compatibility unknown`, naming the api_lint audit
3. The summary's `Not checked:` line lists the audit and its `Compatibility:` line reads `NOT ASSESSED — <audits> did not run`
4. Phase 7 takes the no-BLOCKING/HIGH branch with the first sentence "No blocking gaps found, but [audits] did not run — framework compatibility is NOT ASSESSED."

**Assertions:**
- [ ] "framework-compatible" is never stated while an in-scope audit is NOT CHECKED
- [ ] NOT ASSESSED outranks the compatible statement and is itself outranked by any BLOCKING or HIGH gap
- [ ] The plan's `## Not Checked` section names the audit and what would let it run (`commands.api_lint` set, or `/api-design review`)

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Reads silently and completes the audit before presenting anything
- [ ] Shows the summary and the Gap Preview before asking to write
- [ ] Uses "May I write this to `<path>`?" before the plan write and before any in-place fix
- [ ] Offers one first action (Phase 7), never a batch of fixes; never regenerates existing PRDs, ADRs, contracts or stories
- [ ] Writes no evidence, reports or plans under `production/session-logs/`
- [ ] Never writes `modes.review_mode` or any other knob that `modes.rigor` fronts
- [ ] Follows the automation prelude; categories in `automation_always_ask` always prompt
- [ ] Converses in the user's language; the plan keeps its English headings and bold labels exactly

---

## Category Rubric (`utility`)

- `utility U1` — the static checks above pass: bootstrap line and grant exact, `--keys` exact, rule-2 follow-on line, automation prelude, "May I write" before each write, output path exact
- `utility U2` — not applicable (no director gate)
- The NOT ASSESSED cases are Case 3 (missing input: no resolved code root, no lint command — NOT CHECKED lines beside BLOCKING gaps) and Case 7 (run-level `Verdict: **NOT ASSESSED**` when no gap outranks it)

---

## Coverage Notes

- The per-ADR retrofit, per-PRD `/write-prd` and `/data-model migration <slug>` branches follow the same
  plan-entry shape as Case 1 and are not fixture-tested separately.
- Lint execution depends on the command in `commands.api_lint`; a command that would download a tool asks first
  (not fixture-tested).
- The time estimates in plan entries are advisory and not asserted.
