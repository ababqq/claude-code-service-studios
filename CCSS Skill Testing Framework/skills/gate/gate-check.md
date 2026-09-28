# Skill Test Spec: /gate-check

> **Category**: gate
> **Priority**: critical
> **Spec written**: 2026-09-28

## Skill Summary

`/gate-check` validates whether the project is ready to advance into a target
phase. The argument is the **target** phase (`definition | architecture |
validation | build | hardening | launch`); the departure phase whose catalog
steps must be complete is derived from the target, never from `project.stage`.
The skill loads only the target's reference file
(`.claude/skills/gate-check/references/gate-<target>.md`), runs
`bash .claude/scripts/artifact-check.sh --phase <departure>` for existence,
resolves the gate's conditions (*UI*, *Backend*, *PII*, *Stores*, *Regions*,
*Multi-locale*), applies the `modes.workflow` tier reductions, the `qa.level`
relaxation (the smoke report stays the floor) and `performance.enforce`, asks the
user about everything it cannot verify, runs the director panel at the width
`modes.workflow` sets (when `review_mode` lets it run), and challenges its own
draft with a Chain-of-Verification. It produces a PASS / CONCERNS /
NOT ASSESSED / FAIL verdict (precedence **FAIL > CONCERNS > NOT ASSESSED >
PASS**), writes the report `production/gate-checks/gate-<target>-YYYY-MM-DD.md`
after "May I write", and — only on PASS and explicit user confirmation — writes
`project.stage` in `project.yaml`, then re-reads and verifies it. It governs all
six phase transitions, is always collaborative, and is the most critical
gate-keeping skill in the pipeline.

---

## Static Assertions (Structural)

Verified automatically by `/skill-test static` — no fixture needed — plus the
contract checks below.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] `name: gate-check` equals the skill directory, the catalog `name` and this spec's basename; `model: opus`
- [ ] `argument-hint` is `"[target-phase: definition | architecture | validation | build | hardening | launch] [--review full|lean|solo]"`
- [ ] First body line is exactly `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,workflow,qa.level,testing.strict,performance.enforce,team.size,project.stage,feature_overrides,surfaces,stack,compliance,accessibility,distribution,code_roots` ``
- [ ] `allowed-tools` grants `Bash(bash "*/.claude/skills/gate-check/../../hooks/yaml-helper.sh" resolve_config *)` (its own directory name)
- [ ] The line after the bootstrap block is exactly: ``Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] No automation prelude (no block beginning "**Automation mode**: Resolve `modes.automation`") and `automation` is not in `--keys` — `/gate-check` is always collaborative
- [ ] `allowed-tools` is exactly: Read, Glob, Grep, Write, Edit, Bash, Agent, AskUserQuestion, plus the grant (membership exact, order free); no `disable-model-invocation`, no `isolation`
- [ ] Has ≥2 phase headings (numbered `## N.` sections)
- [ ] Verdict tokens are exactly PASS, CONCERNS, NOT ASSESSED, FAIL, and the precedence is stated as an ordered rule — **FAIL**, then **CONCERNS**, then **NOT ASSESSED**, then **PASS** (first matching rule wins)
- [ ] Contains "May I write this to `production/gate-checks/gate-<target>-YYYY-MM-DD.md`?" and "Gate passed. May I update `project.stage` in `project.yaml` to '<Stage>'?"
- [ ] Outputs are exactly the report `production/gate-checks/gate-<target>-YYYY-MM-DD.md` (its H1 followed, after one blank line, by `> **Verdict**: <TOKEN>`) and `project.stage` in `project.yaml` — no second stage record anywhere else
- [ ] The Section 2 table maps each target to `.claude/skills/gate-check/references/gate-<target>.md` and to its departure phase: definition→`discovery`, architecture→`definition`, validation→`architecture`, build→`validation`, hardening→`build`, launch→`hardening`
- [ ] "Production Stages (7)" lists Discovery, Definition, Architecture, Validation, Build, Hardening, Launch, with Launch marked terminal
- [ ] Section 4b holds the only panel-width table: `minimal` 1 (`delivery-manager`), `standard` 2 (`technical-director`, `delivery-manager`), `full` 4 (`product-director`, `technical-director`, `delivery-manager`, `design-director`), and keeps the "Width is not the same as strictness" and "Name the omissions" blocks
- [ ] The panel gate IDs are exactly PD-PHASE-GATE, TD-PHASE-GATE, DM-PHASE-GATE, DD-PHASE-GATE, each spawned with its gate file path and a `Pass:` line of its Context bullets, and each reply's first line parsed as `[GATE-ID]: TOKEN` with TOKEN ∈ READY / CONCERNS / NOT READY
- [ ] Section 1 contains "In `lean` mode the panel runs at the width `modes.workflow` sets (§4b)." and never claims a fixed full panel in lean mode
- [ ] The review-mode default is stated verbatim: "Unset on an unconfigured project: `modes.rigor` defaults to `minimal`, which resolves `review_mode` to `solo`."
- [ ] QL-TEST-COVERAGE is not spawned by this skill (the text says `/story-done` and `/team-qa` spawn it)
- [ ] Section 5a Chain-of-Verification generates 5 challenge questions, requires at least 2 of them to be answered with a tool action (`[TOOL ACTION]`), never revises NOT ASSESSED down to PASS by re-reasoning, and ends the report with `Chain-of-Verification: [N] questions checked — verdict [unchanged | revised from X to Y]`
- [ ] Tier reductions only relax: `qa.level` relaxes per-story test items but the smoke report stays the floor; `performance.enforce` applies at every tier; a gate left with zero required items reports NOT ASSESSED, never PASS (unless its reference file declares it not applicable at that tier)
- [ ] No `!` injection other than the bootstrap line; no `file:line` citations of other files
- [ ] Has a next-step handoff at the end (Section 7 closing widget and Section 8 Follow-Up Actions), naming skills by their current names
- [ ] Section 3 Cross-Reference Checks carries the external design check (record `design/handoff/<slug>/HANDOFF.md`, `> **Retrieved**:` date against the `/ux-review` record's file-name date, `NOT CHECKED — external design not retained (<url>)`, never calling a Figma MCP tool, the Claude Design connector or the `Artifact` tool); Section 8 contains "**External design changed after review?** → `/ux-review [file]`" and "**Imported design without a record?** → `/design-handoff --for <slug>`"; `CONTRACT.md`'s `build` row lists `design/handoff/*/HANDOFF.md`; `--keys` and `allowed-tools` are unchanged (no `design`, no `automation`, no MCP or host-conditional tool)

---

## Director Gate Checks

The panel is the four `-PHASE-GATE` gates. Two independent axes decide it:
`review_mode` decides **whether** the panel runs; `modes.workflow` decides **how
wide** it is (the Section 4b table — 1 / 2 / 4 directors).

- **Full mode**: the directors of the resolved width spawn in parallel.
- **Lean mode**: skip every gate whose ID does not end in `-PHASE-GATE` — every panel gate ends in `-PHASE-GATE`, so the panel runs at the width `modes.workflow` sets.
- **Solo mode**: no director spawns; each seat the width would have filled is noted `[GATE-ID] skipped — Solo mode`, plus "Director Panel skipped — Solo mode. Gate verdict based on artifact and quality checks only."
- **Always**: DD-PHASE-GATE is omitted when no *UI* surface is configured (known, not unset) and the omission is named ("design-director omitted — no UI surface").

---

## Test Cases

### Case 1: Happy Path — Discovery → Definition passes and the stage advances

**Fixture:**
- `project.yaml` sets `modes.rigor: standard` (resolves `workflow: standard`, `review_mode: lean`) and `platform.surfaces: [web, ios, android, api]`
- `design/product/product-brief.md` exists with real content under `## Problem Statement`, `## Target Users & Jobs-to-be-Done`, `## Value Proposition`, `## Product Principles & Anti-Goals`, `## Success Metrics` (a North Star and a guardrail metric), `## Riskiest Assumptions`, `## MVP Scope` and `## Non-Goals`; the target segment is concrete ("salaried 25–34-year-olds in Korea who save toward a goal by manual transfer each payday")
- `design/product/reviews/product-brief-review-log.md` exists with `> **Verdict**: APPROVED` under its H1
- `stack.pinned_on` is set
- `technical-director` and `delivery-manager` both reply with a first line `[TD-PHASE-GATE]: READY` / `[DM-PHASE-GATE]: READY`

**Input:** `/gate-check definition`

**Expected behavior:**
1. Skill loads only `.claude/skills/gate-check/references/gate-definition.md`
2. Skill runs `bash .claude/scripts/artifact-check.sh --phase discovery`
3. Skill applies the `standard` tier line of the gate file (brief with the seven sections, brief reviewed, North Star plus guardrail, concrete segment and non-goals required; decision-test principles, riskiest-assumption tests, concept prototype and stack pin recommended)
4. Skill reads the brief review verdict from the review log's `> **Verdict**:` line
5. Panel: lean mode keeps every `-PHASE-GATE`; the `standard` width spawns `technical-director` and `delivery-manager` in parallel; the omissions are named
6. Chain-of-Verification runs; verdict PASS
7. Skill presents the report, asks "May I write this to `production/gate-checks/gate-definition-YYYY-MM-DD.md`?", then asks "Gate passed. May I update `project.stage` in `project.yaml` to 'Definition'?"
8. After writing, skill re-reads `project.yaml` and runs `bash .claude/scripts/stage-estimate.sh`, expecting `STAGE: Definition` with `SOURCE: project.yaml`

**Assertions:**
- [ ] `--phase discovery` is passed — the departure phase from the Section 2 row, never empty
- [ ] Only the definition reference file is loaded; the other five are not read
- [ ] Output includes "Required Artifacts" and "Quality Checks" sections with a status per item, and a verdict line with one of PASS / CONCERNS / NOT ASSESSED / FAIL
- [ ] Recommended items that are absent (e.g. no `prototypes/*-concept/REPORT.md`) surface as recommendations, never as Blockers, at `standard`
- [ ] Exactly two directors spawn (TD-PHASE-GATE, DM-PHASE-GATE), in one parallel batch, and the report names the Product and Design perspectives as not consulted
- [ ] The saved report starts with `# Gate Check: Discovery → Definition` followed by `> **Verdict**: PASS`
- [ ] Only `project.stage` is written — no `modes.review_mode`, `modes.workflow`, `docs.density`, `qa.level`, `modes.story_granularity` or `team.size`, and no condition answers
- [ ] The write is re-read and verified with `stage-estimate.sh`; a disagreement is reported and stops the flow
- [ ] The closing widget offers `/map-features` as the recommended next step

---

### Case 2: Failure Path — Architecture → Validation with missing required artifacts

**Fixture:**
- `modes.rigor: full`; `platform.surfaces: [web, ios, android, api]`; `privacy.handles_pii: true`; `stack.layers.backend.framework: NestJS`
- `docs/architecture/adr-0001-identity-and-auth.md` exists (Accepted); `docs/architecture/architecture.md` does NOT exist
- No `docs/security/threat-model.md`, no `docs/architecture/architecture-review-*.md`, no API contract under `docs/api/`

**Input:** `/gate-check validation`

**Expected behavior:**
1. Skill runs `bash .claude/scripts/artifact-check.sh --phase architecture`
2. Required artifacts at `full` are ABSENT: the architecture document, the threat model (required because *PII* is true), the API contract (required because *Backend*), the architecture review report
3. Skill outputs FAIL with a Blockers section naming each missing path and the skill that produces it
4. Skill writes nothing without approval and does not create the missing artifacts

**Assertions:**
- [ ] Verdict is FAIL (not PASS, CONCERNS or NOT ASSESSED) when required artifacts are missing
- [ ] Output names `docs/architecture/architecture.md` and `docs/security/threat-model.md` as missing
- [ ] Blockers name the remediation skills: `/create-architecture`, `/security-audit threat-model`, `/api-design`, `/architecture-review`
- [ ] Skill does NOT create any missing file and does NOT re-run the gate automatically ("Never auto-fix")
- [ ] `project.stage` is not written, and no stage-update question is asked on FAIL

---

### Case 3: NOT ASSESSED — a required check had no input

**Fixture:**
- `modes.rigor: standard`; `qa.level` resolves `standard`
- Every Build → Hardening required artifact is present, including a real `production/qa/smoke-2026-11-18.md` (PASS, run against staging)
- `commands.test` is unset in `project.yaml` (no test runner configured)
- `platform.surfaces` is unset, and the user does not answer the Section 1 condition question

**Input:** `/gate-check hardening`

**Expected behavior:**
1. Skill runs `bash .claude/scripts/artifact-check.sh --phase build`
2. The "test suite passes" check is required at this tier but cannot run — no runner
3. The *UI* condition is unset; skill asks in one `AskUserQuestion` before Section 3; the unanswered question stays MANUAL CHECK NEEDED
4. No blocker is found; verdict is NOT ASSESSED, naming both unassessed items

**Assertions:**
- [ ] Verdict is NOT ASSESSED, with the missing input named (no test runner — `commands.test` unset; *UI* condition unanswered)
- [ ] No PASS verdict is produced for the unassessed scope; Chain-of-Verification never revises NOT ASSESSED down to PASS
- [ ] Unset `platform.surfaces` is not treated as "no UI": UI items stay MANUAL CHECK NEEDED instead of `N/A`
- [ ] The condition answers are never written to `project.yaml` (the skill suggests `/setup-stack`)
- [ ] `project.stage` is not written on NOT ASSESSED; Follow-Up Actions recommend `/test-setup`

---

### Case 4: No Argument — target derived from the shared stage estimator

**Fixture:**
- `project.yaml` sets `project.stage: Validation`
- `bash .claude/scripts/stage-estimate.sh` prints `STAGE: Validation`, `SOURCE: project.yaml`, `ESTIMATE: Build`, `EVIDENCE: sprint-status.yaml has an in-progress story`

**Input:** `/gate-check` (no argument)

**Expected behavior:**
1. Skill runs `bash .claude/scripts/stage-estimate.sh` with the Bash tool (not as a `!` injection)
2. Skill lowercases `STAGE:` to `validation` and takes its `next_phase` as the target: `build`
3. Skill confirms with `AskUserQuestion`, showing both the recorded stage and the differing estimate: options `[A] Yes — run this gate` / `[B] No — pick a different gate`
4. On [A] it runs the Validation → Build gate with `--phase validation`

**Assertions:**
- [ ] The prompt is the canonical "Detected stage: **[STAGE]** (`SOURCE: [project.yaml | estimated]` — [EVIDENCE]). Running the gate into **[Target]** ([STAGE] → [Target]). Is this correct?", filled here with Validation → Build, and shows `ESTIMATE` because it differs from `STAGE`
- [ ] The confirmation step is not skipped when no argument is given; it is a confirmation, not a request to pick a gate
- [ ] [B] shows a second widget listing all six gates (Discovery → Definition … Hardening → Launch)
- [ ] With a fixture where `STAGE:` is `Launch`, the skill stops with "Launch is terminal — no further phase gate; use /release-checklist, /rollout-plan and /retrospective release <version>." and runs no checks

---

### Case 5: Edge Case — the departure phase comes from the target, never from `project.stage`

**Fixture:**
- `project.yaml` sets `project.stage: Definition` (the recorded stage lags the tree)
- Validation artifacts exist (epics, stories, first sprint plan, walking skeleton report)

**Input:** `/gate-check build`, then `/gate-check discovery`, then `/gate-check hardning`

**Expected behavior:**
1. `/gate-check build` runs `bash .claude/scripts/artifact-check.sh --phase validation` and loads `gate-build.md`
2. `/gate-check discovery` says Discovery is the start phase — no gate leads into it — and stops
3. `/gate-check hardning` is not a phase gate: the skill stops, lists the six valid targets and asks which was meant

**Assertions:**
- [ ] `--phase validation` is used for the `build` target although `project.stage` is `Definition` (never `--phase definition`, never an empty `--phase`)
- [ ] `discovery` produces no checklist and no verdict
- [ ] A near-miss spelling is never guessed into a target; the six valid targets are listed
- [ ] If `artifact-check.sh` exits non-zero or prints `STEPS: 0` for the departure phase, every artifact item is reported unassessed (NOT ASSESSED), not clean

---

### Case 6: Director Gate — full mode

**Fixture:**
- `modes.rigor: full` (resolves `workflow: full`, `review_mode: full`); `platform.surfaces: [web, ios, android, api]`
- All Validation → Build required artifacts are present and every quality check passes
- `product-director` replies `[PD-PHASE-GATE]: READY`, `technical-director` `[TD-PHASE-GATE]: READY`, `delivery-manager` `[DM-PHASE-GATE]: CONCERNS` (sprint 1 capacity), `design-director` `[DD-PHASE-GATE]: READY`

**Input:** `/gate-check build`

**Expected behavior:**
1. Skill reads `review_mode: full` from its resolved block and `workflow: full` for the width
2. The `full` width seats all four panel directors; they spawn as parallel subagents, each given only its gate file path (`.claude/docs/director-gates/pd-phase-gate.md` …) and its `Pass:` line
3. Each reply's first line is parsed as `[GATE-ID]: TOKEN`; the CONCERNS reply sets the verdict to at least CONCERNS
4. The Director Panel summary lists all four with their tokens and feedback

**Assertions:**
- [ ] Exactly PD-PHASE-GATE, TD-PHASE-GATE, DM-PHASE-GATE and DD-PHASE-GATE spawn, in one parallel batch (not sequentially)
- [ ] Each `Pass:` line carries the gate's Context bullets (`.claude/docs/director-gates.md` § Context to Pass): target phase · gate reference file path · artifact-check output for the departure phase, plus brief path and feature map path (PD), the resolved `stack` and `code_roots` lines (TD), the `production/risk-register/` path or "none" (DM), the resolved `surfaces` line and design-language path or "none" (DD)
- [ ] The parent does not read or paste the gate files into the prompts
- [ ] A CONCERNS reply makes the verdict at least CONCERNS and each concern is listed for revise / accept / discuss; a NOT READY reply would make it at least FAIL
- [ ] A reply whose first line does not parse is a director that did not return a verdict (NOT ASSESSED), never an approval
- [ ] `project.stage` is not written on CONCERNS

---

### Case 7: Director Gate — lean mode

**Fixture:**
- `modes.rigor: standard` (resolves `workflow: standard`, `review_mode: lean`); `platform.surfaces: [web, ios, android, api]`
- Validation → Build artifacts present; `design/brand/design-language.md` carries the literal skip note `[DD-DESIGN-LANGUAGE] skipped — Lean mode` instead of a recorded verdict line
- `technical-director` and `delivery-manager` reply READY

**Input:** `/gate-check build`

**Expected behavior:**
1. Skill applies the lean rule — skip every gate whose ID does not end in `-PHASE-GATE` — and finds every panel gate ends in `-PHASE-GATE`
2. The `standard` width spawns TD-PHASE-GATE and DM-PHASE-GATE; PD and DD are "not in panel"
3. The DD-DESIGN-LANGUAGE outcome item reads `NOT CHECKED — DD-DESIGN-LANGUAGE skipped (lean mode)` and is not scored
4. Verdict follows the artifact and quality checks plus the two READY replies

**Assertions:**
- [ ] SKILL.md states the lean rule as the suffix sentence "`lean` → **skip every gate whose ID does not end in `-PHASE-GATE`**. Note: `[GATE-ID] skipped — Lean mode`" and enumerates no list of gate IDs for it
- [ ] Only gate IDs ending in `-PHASE-GATE` run; no panel gate receives a `skipped — Lean mode` note
- [ ] Panel width comes from `modes.workflow` (2 at `standard`), not from `review_mode`; the report names the omitted Product and Design perspectives and how to seat them (`modes.workflow: full`)
- [ ] The DD-DESIGN-LANGUAGE skip note is accepted as evidence the review mode was applied and is not scored as missing

---

### Case 8: Director Gate — solo mode

**Fixture:**
- An unconfigured project: `project.yaml` has no `modes:` block and no `project.local.yaml` exists, so `modes.rigor` defaults to `minimal` and `review_mode` resolves `solo`
- `design/product/one-pager.md` exists with `## Pitch`, `## Problem & Target User`, `## Core User Journey`, `## Success Signal`, `## Scope & Non-Goals`, `## Stack` and `## Build Order` filled

**Input:** `/gate-check definition`

**Expected behavior:**
1. Skill resolves `review_mode: solo` from its block (no other file is read for the mode)
2. No director spawns; the `minimal` width's seat is noted `[DM-PHASE-GATE] skipped — Solo mode`
3. Output says "Director Panel skipped — Solo mode. Gate verdict based on artifact and quality checks only."
4. The `minimal` tier line applies (the one-pager is the gate target); a verdict is still produced

**Assertions:**
- [ ] No director gates are spawned in solo mode
- [ ] Each seat the width would have filled is noted `[GATE-ID] skipped — Solo mode`
- [ ] The verdict rests on artifact and quality checks only, and the narrow panel alone does not make the verdict NOT ASSESSED
- [ ] On PASS the stage question is still asked before `project.stage` is written

---

### Case 9: Edge Case — panel width and named omissions

**Fixture A:**
- `modes.rigor: minimal` (`workflow: minimal`), run with `--review lean`

**Fixture B:**
- `modes.rigor: full`; `platform.surfaces: [api]` (known: no UI surface)

**Fixture C:**
- `modes.rigor: full`; `platform.surfaces` unset; the user leaves the Section 1 question unanswered

**Input:** `/gate-check validation` under each fixture

**Expected behavior:**
1. A: one director — `delivery-manager` (DM-PHASE-GATE); the report names the three perspectives not consulted
2. B: PD-PHASE-GATE, TD-PHASE-GATE and DM-PHASE-GATE spawn; DD-PHASE-GATE is omitted and listed as "design-director omitted — no UI surface"
3. C: the design-director seat is kept — unset is not "no UI"

**Assertions:**
- [ ] Width follows `modes.workflow` per Section 4b (1 / 2 / 4); `--review` changes whether the panel runs, never its width
- [ ] DD-PHASE-GATE is omitted only when the no-UI answer is known, and the omission is named in the report
- [ ] A deliberately narrow panel (by tier, by the no-UI omission) never triggers NOT ASSESSED by itself — only a director the width called for that failed to return does

---

### Case 10: Always Collaborative — the automation setting is ignored

**Fixture:**
- `project.yaml` sets `modes.automation: autonomous` and `modes.rigor: standard`
- The Discovery → Definition gate would PASS (fixture of Case 1)

**Input:** `/gate-check definition`

**Expected behavior:**
1. Skill carries no automation prelude and never resolves `modes.automation`
2. Every question — condition questions, MANUAL CHECK NEEDED items, the report write, the stage write — is asked; none is logged and auto-approved
3. The stage update waits for the user's explicit confirmation

**Assertions:**
- [ ] `automation` is not among the `--keys`, and SKILL.md states "**gate-check honors `workflow` but is exempt from `automation`.**"
- [ ] "May I write this to `production/gate-checks/gate-<target>-YYYY-MM-DD.md`?" (here `gate-definition-…`) is asked even under `autonomous`
- [ ] `project.stage` is never written without the answer to "Gate passed. May I update `project.stage` in `project.yaml` to '<Stage>'?" (here `Definition`)
- [ ] The verdict is advisory: the user may advance despite CONCERNS, and an override is recorded with the accepted risks in the report

---

### Case 11: Build gate — external design sources (retained, stale, not retained)

**Fixture:**
- `modes.rigor: full` (resolves `workflow: full`); `platform.surfaces: [web, ios, android, api]`; every other Validation → Build item passes
- `design/ux/goal-detail.md` has `> **Design Source**: figma — https://www.figma.com/design/<fileKey>/Moa?node-id=12-34 · record `design/handoff/goal-detail/HANDOFF.md``, and its `### Wireframe` cites the record's screens instead of ASCII (a text hierarchy is kept); its record is `RETAINED` with `> **Retrieved**: 2026-11-02`; `design/ux/reviews/goal-detail-ux-review-2026-11-05.md` is APPROVED
- Variant A (stale): the same record has `> **Retrieved**: 2026-11-09`
- Variant B (not retained): `design/ux/onboarding.md` declares `> **Design Source**: claude-design — https://claude.ai/design/p/<PROJECT_ID>?file=Onboarding.dc.html · record `design/handoff/onboarding/HANDOFF.md``, and that record has `> **Verdict**: NOT ASSESSED`
- Variant C: `modes.rigor: minimal` with variant B's files

**Input:** `/gate-check build`

**Expected behavior:**
1. The UX specs item counts `design/ux/goal-detail.md` although its wireframe is the cited external design; no external design is counted in place of a missing spec file
2. Base fixture: the external design sources item passes (RETAINED, retrieved 2026-11-02 ≤ the review's file-name date 2026-11-05)
3. Variant A: the item is unmet — the design changed after the review, so the review is stale; Follow-Up Actions name `/ux-review design/ux/goal-detail.md`
4. Variant B: the item prints `NOT CHECKED — external design not retained (https://claude.ai/design/p/<PROJECT_ID>?file=Onboarding.dc.html)` and is never PASS; at `full` the verdict is at best NOT ASSESSED; Follow-Up Actions name `/design-handoff --for onboarding` when the record is missing
5. Variant C: the item is dropped at `minimal` and not scored
6. In no variant does the skill call a Figma MCP tool, the Claude Design connector or the `Artifact` tool

**Assertions:**
- [ ] The review date is taken from the record file name `<spec-stem>-ux-review-YYYY-MM-DD.md`, not from a header field
- [ ] A `NOT ASSESSED` or missing record is never scored PASS and carries the exact NOT CHECKED line
- [ ] The new item is named in all three `## Workflow tier reductions` lines of `gate-build.md` (conditional at `full`, recommended at `standard`, dropped at `minimal`)
- [ ] The verdict is decided from files on disk only

---

## Protocol Compliance

- [ ] Uses "May I write this to `production/gate-checks/gate-<target>-YYYY-MM-DD.md`?" before saving the report
- [ ] Presents the full checklist report before asking for any write approval
- [ ] Never writes `project.stage` without explicit confirmation; re-reads `project.yaml` after writing and verifies with `stage-estimate.sh`
- [ ] Passes `artifact-check.sh` the departure phase derived from the target (never `project.stage`, never empty)
- [ ] Never assumes PASS for an unverifiable item — it is MANUAL CHECK NEEDED, and an unresolved one leads to NOT ASSESSED
- [ ] Never auto-creates missing artifacts to manufacture a PASS
- [ ] Writes nothing under `production/session-logs/`; never writes `modes.review_mode` or any other knob `modes.rigor` fronts
- [ ] Ends with a closing `AskUserQuestion` widget tailored to the gate (Section 7) and Follow-Up Actions per verdict (Section 8)

---

## Coverage Notes

- The full item lists of the six gates live in
  `.claude/skills/gate-check/references/gate-<target>.md`; this spec samples the
  Discovery → Definition, Architecture → Validation, Validation → Build and
  Build → Hardening gates and does not re-enumerate the reference files.
- The Walking Skeleton Validation block of the Validation → Build gate (built and
  any applicable item NO ⇒ FAIL at every tier) needs a deployed staging context
  and is not fixture-tested here.
- The Hardening → Launch gate (release records, store submission, regional
  compliance items) is not covered; it follows the same pattern with more
  conditional items.
- The external design sources item of the Validation → Build gate is covered by
  Case 11; the other gates have no design-source item.
- The per-feature override check (`feature_overrides` keys with no matching
  `design/prd/<stem>.md` ⇒ CONCERNS) and the smoke-report spot-read rule are
  exercised only indirectly.
- The rigor-fit line (entering Build or later on `rigor: minimal`) is advisory
  and never affects the verdict; it is not asserted.
