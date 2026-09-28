# Skill Test Spec: /story-readiness

> **Category**: readiness
> **Priority**: critical
> **Spec written**: 2026-09-28

## Skill Summary

`/story-readiness` checks whether a story file holds everything an engineer needs before
implementation starts — the Definition of Ready. It validates one story, every story of
the current sprint (`sprint`) or every story file (`all`, glob
`production/epics/*/story-*.md`), loading shared context once: the feature map, the
control manifest's `Manifest Version`, the TR registry, all ADR statuses (one
`^## Status` scan), the API contract files, migration plans, the tracking plan, the UX
specs and `docs/stack-reference/VERSION.md`. The checklist covers Design Completeness
(PRD requirement traced, testable criteria, design link, analytics events), Architecture
Completeness (ADR Accepted, TR-ID active, manifest current, stack notes, `**API Contract**`,
`**Migration**`, `**Feature Flag**`), Scope Clarity (estimate, `**Surface**`, boundary,
dependencies), Open Questions, referenced assets and the Definition of Done (minimum
criteria per type, NFR budget, Story Type, test evidence per `testing.strict`, the
migration floor). The workflow tier and `qa.level` relax items; the migration floor is
never relaxed. In `full` review mode **QL-STORY-READY** (qa-lead) reviews testability.

**Read-only**: the skill has no Write or Edit access; the report is shown in the
conversation, and the story file stays untouched unless the user applies a drafted fix.

Verdicts per story (precedence first-match): **BLOCKED** → **NEEDS WORK** →
**NOT ASSESSED** → **READY**.

---

## Static Assertions (Structural)

Verified automatically by `/skill-test static` — no fixture needed.

- [ ] Frontmatter has `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`; `name: story-readiness` equals the directory, the catalog `name` and this spec's basename
- [ ] `description` is exactly "Is a story implementation-ready? READY / NEEDS WORK / BLOCKED / NOT ASSESSED."
- [ ] `argument-hint` offers `[story-file-path | all | sprint]` and `[--review full|lean|solo]`; `model: sonnet`; no `disable-model-invocation`, no `isolation`
- [ ] First body line is exactly `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,qa.level,testing.strict,feature_overrides` ``
- [ ] `allowed-tools` is exactly `Read, Glob, Grep, AskUserQuestion, Agent` plus `Bash(bash "*/.claude/skills/story-readiness/../../hooks/yaml-helper.sh" resolve_config *)` — **no** `Write`, **no** `Edit`
- [ ] The line after the bootstrap block is exactly `` Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`. ``, followed verbatim by the automation prelude block
- [ ] ≥2 phase headings (`## Phase 0: Resolve Review Mode`, `## 1. Parse Arguments` … `## 7. Next-Story Handoff`, `## Phase 8: Director Gate — Story Readiness Review`)
- [ ] All four verdict tokens `READY`, `NEEDS WORK`, `BLOCKED`, `NOT ASSESSED` present, with the precedence stated as BLOCKED, then NEEDS WORK, then NOT ASSESSED, then READY
- [ ] The zero-scope line `NOT ASSESSED — no stories in scope` present
- [ ] The single-story report carries `> **Verdict**: [READY / NEEDS WORK / BLOCKED / NOT ASSESSED]` directly under its heading; the aggregate has `Ready:`, `Needs Work:`, `Blocked:`, `Not Assessed:` counts
- [ ] No "May I write" is required — the skill writes no file and says so ("This skill is read-only.")
- [ ] The DoR items for `**API Contract**`, `**Migration**`, `**Feature Flag**`, `**Surface**`, the NFR budget, the design link and `**Analytics Events**` are present; the DoD carries the migration floor `production/qa/evidence/<story-slug>/migration-dry-run.log`, "never auto-passed — applies at every `qa.level` and regardless of `testing.strict.config`"
- [ ] The test-evidence item maps Logic→`logic`, Integration→`integration`, UI→`ui`, E2E→`e2e`, Config→`config` from the resolved `testing.strict` line (never from `project.yaml` directly)
- [ ] QL-STORY-READY review-mode check carries the lean suffix sentence; the spawn has `` Pass: story path · PRD path · resolved `testing.strict` line ``; the reply is parsed as `[QL-STORY-READY]: TOKEN`
- [ ] Only one `!` injection; no `file:line` citation; handoffs name `/dev-story`, `/create-epics`, `/create-stories`, `/quick-spec`, `/api-design update <resource>`, `/data-model migration <slug>`, `/sprint-plan update`

---

## Director Gate Checks

One gate: **QL-STORY-READY** — `qa-lead`, Domain "Testability", verdicts
`ADEQUATE / GAPS / INADEQUATE`. It runs in Phase 8 only for stories whose checklist
verdict is READY or NEEDS WORK; a BLOCKED or NOT ASSESSED story reports
`QL-STORY-READY: not run — story BLOCKED` (or `— story NOT ASSESSED`). Several stories are
spawned in parallel. The gate can move READY to NEEDS WORK, never the reverse.

- **Full mode**: spawn with the `Pass:` line above; the prompt tells the agent to read
  `.claude/docs/director-gates/ql-story-ready.md`.
- **Lean mode**: skip every gate whose ID does not end in `-PHASE-GATE` —
  `[QL-STORY-READY] skipped — Lean mode` on the story's `QL-STORY-READY:` line.
- **Solo mode**: `[QL-STORY-READY] skipped — Solo mode` on the same line.

---

## Test Cases

Fixtures use the Moa example story `production/epics/goals-core/story-001-create-goal.md`
(Type Integration, Surface `api`, PRD `design/prd/goals.md`, TR `TR-goals-001`,
`ADR-0006`, `` **API Contract**: `docs/api/openapi.yaml#/paths/~1v1~1goals/post` ``,
`` **Migration**: `docs/data/migrations/0003-savings-goal.md` ``,
`**Feature Flag**: goals.v2-progress-ring`, `**Analytics Events**: goal_created`).

### Case 1: Happy Path — a fully ready story

**Fixture:**
- `modes.workflow: full`, `qa.level: standard`; review mode `lean`
- ADR-0006 `## Status` → `Accepted`; `TR-goals-001` exists with `status: active`
- Story `> **Manifest Version**:` equals the manifest header date
- `createGoal` exists in `docs/api/openapi.yaml`; the migration plan exists; the flag has default, owner and removal date in the PRD's `## Configuration & Flags`; `goal_created` is in `design/product/tracking-plan.md` `## Events`
- Story has `> **Estimate**:`, `> **Surface**: api`, `## Out of Scope`, `## Dependencies` ("None"), 3 Given/When/Then criteria, an NFR line "`POST /v1/goals` p95 ≤ 300 ms on staging", and `## Test Evidence` naming the contract test path and `production/qa/evidence/story-001-create-goal/migration-dry-run.log`

**Input:** `/story-readiness production/epics/goals-core/story-001-create-goal.md`

**Expected behavior:**
1. Loads shared context once (ADR statuses by one grep, not one read per ADR)
2. Evaluates every checklist section and the Definition of Done
3. Skips QL-STORY-READY (lean) and prints the single-story report with `> **Verdict**: READY`
4. Offers help filling gaps (none) and surfaces up to three other ready stories from the latest sprint file

**Assertions:**
- [ ] Output lists passing checks per section (Design, Architecture, Scope, Open Questions, Assets, Definition of Done)
- [ ] The contract operation, migration plan, flag row and tracking event are each looked up, not assumed
- [ ] Verdict **READY**; the `QL-STORY-READY:` line reads `[QL-STORY-READY] skipped — Lean mode`
- [ ] No file is written or edited
- [ ] The next-story section appears, or states "Next ready stories: no sprint file found" / "none ready in [sprint]"

---

### Case 2: Blocked Path — Proposed ADR and missing contract file

**Fixture:**
- Story cites `ADR-0008`, whose `## Status` is `Proposed`
- Its `**API Contract**` points at `docs/api/openapi.yaml`, which does not exist

**Input:** `/story-readiness production/epics/goals-core/story-005-archive-goal.md`

**Expected behavior:**
1. The ADR item fails with "BLOCKED: ADR-0008 is Proposed — wait for acceptance before implementing."
2. The contract item fails as BLOCKED (the referenced contract file does not exist)
3. Verdict **BLOCKED**, with the blockers listed and any NEEDS WORK items listed too

**Assertions:**
- [ ] Verdict is BLOCKED — never NEEDS WORK or READY — whatever else passes
- [ ] The report names ADR-0008 and the missing contract path as the blockers
- [ ] QL-STORY-READY is not run: the line reads `QL-STORY-READY: not run — story BLOCKED`

---

### Case 3: NOT ASSESSED — nothing in scope, or an input that cannot be located

**Fixture (3a):** `production/epics/*/story-*.md` matches nothing.

**Input (3a):** `/story-readiness all`

**Fixture (3b):** a story whose `**PRD**:` points at `design/prd/rewards.md`, which does not exist.

**Input (3b):** `/story-readiness production/epics/rewards-core/story-001-earn-points.md`

**Expected behavior:**
1. (3a) Stops and reports `NOT ASSESSED — no stories in scope`, naming the searched glob and routing `/create-epics layer: <layer>` then `/create-stories [epic-slug]`
2. (3b) Verdict **NOT ASSESSED** for that story, naming the PRD that could not be located

**Assertions:**
- [ ] 3a never renders `Ready: 0 / Needs Work: 0 / Blocked: 0` above an empty list
- [ ] 3b is not reported as BLOCKED (no phantom blocker) and never as READY
- [ ] A `sprint` scope with no sprint file says "no sprint plan found" rather than "no stories"

---

### Case 4: Mode Variant — DoR fields missing, with `qa.level: minimal`

**Fixture:**
- `qa.level: minimal`, `modes.workflow: standard`
- Story has no `**API Contract**:` line and no `**Feature Flag**:` line; `> **Surface**:` is missing
- `` **Migration**: `docs/data/migrations/0004-goal-note.md` `` (exists), but `## Test Evidence` does not name the dry-run log

**Input:** `/story-readiness production/epics/goals-core/story-006-goal-note.md`

**Expected behavior:**
1. The "Test evidence requirement is clear" item auto-passes (`qa.level: minimal`)
2. Missing `**API Contract**`, `**Feature Flag**` and `**Surface**` are NEEDS WORK gaps, each with a fix
3. The migration floor item still fails — NEEDS WORK, because `/story-done` treats a missing dry-run log as blocking

**Assertions:**
- [ ] Verdict **NEEDS WORK**, listing the three field gaps and the migration floor gap
- [ ] The migration floor is not waived by `qa.level: minimal`
- [ ] Each gap has a concrete fix line; nothing is written to the story

---

### Case 5: Edge Case — stale manifest version, by tier

**Fixture:**
- Story `> **Manifest Version**: 2026-10-06`; `docs/architecture/control-manifest.md` header `Manifest Version: 2026-11-02`
- Every other item passes

**Input:** `/story-readiness production/epics/goals-core/story-002-goal-limits.md`, first with `modes.workflow: full`, then with `workflow_overrides.feature_overrides.goals: standard` (the block prints `feature_overrides: goals=standard`)

**Expected behavior:**
1. At `full`: the manifest item fails → **NEEDS WORK** ("new rules may apply")
2. At `standard` (per-feature override): the manifest item is advisory → **READY** with the gap still listed under Gaps

**Assertions:**
- [ ] The story's embedded date is compared with the manifest header date
- [ ] The tier is resolved per story from its PRD stem via `feature_overrides`
- [ ] The stale version is never reported as BLOCKED

---

### Case 6: Director Gate — full mode

**Fixture:** Case 1 fixture with review mode `full`; qa-lead returns GAPS ("criterion 3 names no observable result").

**Expected behavior:**
1. Spawns `qa-lead` for QL-STORY-READY with `` Pass: story path · PRD path · resolved `testing.strict` line `` (the line exactly as printed)
2. Parses `[QL-STORY-READY]: TOKEN` (unbracketed form parses the same)

**Assertions:**
- [ ] ADEQUATE → the checklist verdict stands
- [ ] GAPS → `AskUserQuestion` with `Revise flagged items` / `Accept and proceed` / `Discuss further`; Revise drafts rewrites in conversation and the READY story becomes NEEDS WORK until they are applied
- [ ] INADEQUATE → reported as NEEDS WORK with the gate's findings as gaps
- [ ] The skill shows the record line `> **QA Lead Review (QL-STORY-READY)**: …` for the user to add — it does not write it
- [ ] A first line that does not parse is treated as CONCERNS-class

---

### Case 7: Director Gate — lean mode

**Fixture:** Case 1 fixture; review mode `lean`.

**Assertions:**
- [ ] No `qa-lead` spawn
- [ ] The `QL-STORY-READY:` line reads `[QL-STORY-READY] skipped — Lean mode`
- [ ] The verdict rests on the checklist alone

---

### Case 8: Director Gate — solo mode

**Fixture:** Case 1 fixture; review mode `solo`.

**Assertions:**
- [ ] No director gate spawns
- [ ] The `QL-STORY-READY:` line reads `[QL-STORY-READY] skipped — Solo mode`

---

## Protocol Compliance

- [ ] Never uses Write or Edit; drafts fixes in conversation as ready-to-paste text only
- [ ] Presents all check results before the verdict
- [ ] Distinguishes BLOCKED (needs outside action) from NEEDS WORK (author can fix) from NOT ASSESSED (could not evaluate)
- [ ] `sprint` scope puts a warning at the top when Must Have stories are not READY
- [ ] Ends with the next step (fix the gaps, or `/dev-story [story-path]`)

---

## Coverage Notes

- Readiness rubric mapping: RD1 (six checklist dimensions — Case 1), RD2 (four verdicts
  and their precedence — Cases 1–4), RD3 (BLOCKED only for outside action — Case 2), RD4
  (QL-STORY-READY per review mode — Cases 6–8), RD5 (next-story handoff — Case 1).
- The asset-reference check (`design/inventory/`, `public/`, image and font extensions)
  and the Open Questions markers (`TBD`, `TODO`) are not fixture-tested separately.
- Stories with several ADRs are assumed additive (every ADR must be Accepted for READY).
