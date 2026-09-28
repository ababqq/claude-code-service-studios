# /gate-check — Handoff Contract

## Role in Pipeline
Validates whether the project is ready to advance into a target phase by auditing the departure phase's required artifacts and the gate's quality checks, producing a PASS / NOT ASSESSED / CONCERNS / FAIL verdict (NOT ASSESSED outranks PASS — a gate that could not check part of its scope has not established readiness; see SKILL.md's verdict section for the precedence order), and — on PASS with user confirmation — writing the new stage name to `project.stage` in `project.yaml`, the single stage record.

## Inputs Required

### Files That Must Exist
| File | Required Fields / Sections | Read-Only? |
|------|---------------------------|-----------|
| `project.yaml` (`project.stage`) | Recorded stage. With no argument, `bash .claude/scripts/stage-estimate.sh` reports it (or an estimate when it is unset or invalid) and the target is that stage's `next_phase` | Yes — written only by Section 6 |
| Resolved config block (`--keys review_mode,workflow,qa.level,testing.strict,performance.enforce,team.size,project.stage,feature_overrides,surfaces,stack,compliance,accessibility,distribution,code_roots`) | `modes.workflow` (no terminal default — resolved from `modes.rigor` (default `minimal`)) selects the per-gate checklist tier; `workflow_overrides.feature_overrides.*` resolved per MVP PRD; `review_mode` decides whether the director panel runs (unset on an unconfigured project: `modes.rigor` defaults to `minimal`, which resolves `review_mode` to `solo`); the `surfaces`, `stack`, `compliance`, `distribution` and `accessibility` lines supply the gate conditions; `code_roots` supplies the implementation roots | Yes |
| `project.yaml` keys read with Read (no `resolve_config` label) | `performance.*` budgets; `commands.test`, `commands.e2e`; `testing.patterns`; `localization.locales` (*Multi-locale*); `project.version` (release paths at the launch gate); `workflow_overrides.design_language_strict`, `workflow_overrides.edge_cases`, `workflow_overrides.config_flags` | Yes |
| `.claude/skills/gate-check/references/gate-<target>.md` | The one gate definition for the target phase — Required / Recommended / Quality lists and the exhaustive `## Workflow tier reductions` | Yes |
| `.claude/docs/workflow-catalog.yaml` (through `bash .claude/scripts/artifact-check.sh --phase <departure>`) | Per-step artifact observations for the departure phase; `tiers=` and `when=` are ignored — the gate reference file is authoritative | Yes |
| `docs/consistency-failures.md` | Domain-tagged entries surfaced as increased-scrutiny context (read if exists; skip if absent) | Yes |

### Phase-specific inputs (subset read depending on target gate)
| Target (gate) | Departure phase (`--phase`) | Key files checked |
|---|---|---|
| `definition` (Discovery → Definition) | `discovery` | `design/product/product-brief.md` (`standard`/`full`) or `design/product/one-pager.md` (`minimal`); `design/product/reviews/*-review-log.md`; `prototypes/*-concept/REPORT.md` (recommended); `stack.pinned_on` |
| `architecture` (Definition → Architecture) | `definition` | `design/product/feature-map.md`; MVP PRDs `design/prd/*.md` via `bash .claude/scripts/prd-structure-check.sh`; `design/prd/reviews/*-review-log.md`; `design/prd/reviews/prd-cross-review-*.md`; `workflow_overrides.feature_overrides` keys |
| `validation` (Architecture → Validation) | `architecture` | `docs/stack-reference/VERSION.md` and `docs/stack-reference/<component>/deprecated-apis.md`; `docs/architecture/architecture.md`; `docs/architecture/adr-*.md` (and `bash .claude/scripts/adr-dep-graph.sh`); the `docs/api/` contract; `docs/data/data-model.md`; `docs/security/threat-model.md`; `docs/architecture/requirements-traceability.md`; `docs/architecture/architecture-review-*.md`; `design/accessibility-requirements.md`; runner configs and the CI workflow; `docs/ops/slo.md`; `docs/architecture/tech-radar.md` |
| `build` (Validation → Build) | `validation` | `production/sprints/sprint-*.md`; `production/epics/*/EPIC.md` and `production/epics/*/story-*.md`; ADR `## Status` lines; `docs/architecture/control-manifest.md`; `design/brand/design-language.md`; `design/ux/*.md` (incl. `app-shell.md`, `interaction-patterns.md`); `design/ux/reviews/*-ux-review-*.md`; `production/walking-skeleton/report-*.md`; `production/qa/usability/*.md`; `docs/api/changes/api-change-*.md`; `design/product/one-pager.md` `## Build Order` (`minimal`) |
| `hardening` (Build → Hardening) | `build` | Resolved code roots; test files per `testing.patterns`; `production/qa/smoke-*.md`; `production/qa/qa-plan-*.md`; `production/qa/bugs/BUG-*.md` and `production/qa/bug-triage-*.md`; `docs/data/migrations/*.md`; `docs/ops/slo.md`; `production/qa/perf/*.md`; `production/qa/feature-audit-*.md` (when present) |
| `launch` (Hardening → Launch) | `hardening` | `production/releases/<version>/release-checklist.md`, `rollout-plan.md`, `launch-checklist.md`, `release-notes.md`; `production/security/security-audit-full-*.md` (`quick` at `minimal`); `production/qa/smoke-*.md`; `production/qa/qa-signoff-*.md`; `production/qa/hardening-*.md`; `production/qa/load/load-test-*.md`; `production/qa/usability/*.md`; `docs/ops/runbooks/*.md`; `docs/ops/slo.md`; `.claude/docs/compliance/<region>.md`; `production/qa/localization-qa-*.md`; `production/qa/bugs/BUG-*.md` |

### Preconditions
- The target phase argument must be one of: `definition`, `architecture`, `validation`, `build`, `hardening`, `launch` (`discovery` is the start phase and has no gate). If omitted, the target is the `next_phase` of the `STAGE:` printed by `bash .claude/scripts/stage-estimate.sh`, confirmed with the user; `STAGE: Launch` stops with "Launch is terminal — no further phase gate; use /release-checklist, /rollout-plan and /retrospective release <version>."
- The departure phase passed to `artifact-check.sh --phase` is derived from the target (the catalog phase whose `next_phase` is the target) — never from `project.stage`, and never empty
- The skill does not require any prior skill to have run in the same session, but it will surface missing prerequisites (e.g., missing ADRs, a missing walking skeleton report) as blockers in the verdict

## Outputs Produced

### Files Written
| File | Guaranteed Fields / Sections | Notes |
|------|------------------------------|-------|
| `production/gate-checks/gate-<target>-YYYY-MM-DD.md` | `# Gate Check: <From> → <To>` H1, then `> **Verdict**: <PASS \| CONCERNS \| NOT ASSESSED \| FAIL>` after one blank line; resolved tier and conditions; full checklist with per-item status (incl. `N/A — <condition> not configured` and `NOT CHECKED — <GATE-ID> skipped (<mode> mode)` lines); Director Panel summary with omissions named; Blockers; Recommendations; Chain-of-Verification note | written only after the user approves ("May I write this to `production/gate-checks/gate-<target>-YYYY-MM-DD.md`?") |
| `project.yaml` (`project.stage`) | New stage name (`Definition` … `Launch`) | written ONLY when the verdict is PASS AND the user explicitly confirms; never written on CONCERNS, FAIL or NOT ASSESSED; re-read and verified after the write |

### Output Guarantees
- The gate report always contains: the verdict line under the H1, the artifact checklist (with file sizes or "MISSING"), quality check results, the list of blockers (empty if PASS), recommendations, and the Chain-of-Verification note
- `project.stage` is updated to the new stage name only on a confirmed PASS — never speculatively — and verified afterwards (Read, then `stage-estimate.sh` shows `SOURCE: project.yaml`)
- Any item that cannot be automatically verified is marked `MANUAL CHECK NEEDED` and the user is asked before the verdict is finalized; an unset gate condition is asked, never read as false
- The director panel width comes from the table in SKILL.md Section 4b — the only copy of that table

## Immutability Rules
- READS but does NOT modify: everything in `design/product/`, all PRDs in `design/prd/` and their review logs, UX specs in `design/ux/`, `design/brand/design-language.md`, all ADRs in `docs/architecture/`, `docs/architecture/control-manifest.md`, `docs/architecture/tr-registry.yaml`, the API contract in `docs/api/`, `docs/data/`, `docs/ops/`, `docs/stack-reference/`, all story files in `production/epics/`, all sprint files in `production/sprints/`, everything under `production/qa/`, `production/releases/`, `production/security/` and `production/walking-skeleton/`, source files in the resolved code roots (Grep only), test files (run via Bash)
- MODIFIES: `project.yaml` (`project.stage` only, on PASS + user confirmation only), `production/gate-checks/[report].md` (new file, with user approval)
- Does NOT modify story files, ADRs, PRDs, UX specs, release records, or any source/test code; never writes the six knobs `modes.rigor` fronts or any condition key (`platform.surfaces`, `privacy.handles_pii`, `release.distribution`, `compliance.regions`, `localization.locales` belong to `/setup-stack`)

## Hard Constraints (Never Violate)
- Never writes `project.stage` unless the verdict is PASS and the user has explicitly confirmed advancement
- Never writes the stage on a CONCERNS, FAIL or NOT ASSESSED verdict under any circumstances
- Never auto-advances stage — even a PASS verdict requires explicit user confirmation before the file is written
- Never assumes PASS for items that cannot be automatically verified — always marks them `MANUAL CHECK NEEDED` and asks the user
- Never blocks the user from advancing — the verdict is advisory; if the user overrides, document the risks explicitly in the gate report
- Always runs Chain-of-Verification (5 challenge questions, at least 2 answered with a tool) after drafting the verdict before finalizing it
- If a walking skeleton was built and any applicable Walking Skeleton Validation item is NO at the Validation → Build gate, the verdict is FAIL regardless of all other checks — and regardless of workflow tier (tier reductions relax what must *exist*, never what must *work*)
- Workflow-tier reductions only ever *relax* a requirement (required → recommended, or dropped); they never add one. The additive exceptions are `workflow_overrides`: a feature pinned via `feature_overrides` to a higher tier than the project blocks the gate until that one feature's PRD meets the higher section set; `design_language_strict: true` forces the complete design language; `edge_cases` / `config_flags` force their PRD sections
- `qa.level` relaxes per-story test items only; the smoke report is the floor at every tier; `performance.enforce` applies independently of the tier; zero remaining required items ⇒ NOT ASSESSED, never PASS (the one exception is a gate its reference file declares not applicable at the tier, which passes with that file's note)
- The director panel is the four `*-PHASE-GATE` gates only, spawned in parallel with the gate file path plus their Context items, each response parsed from its first line `[GATE-ID]: TOKEN`. QL-TEST-COVERAGE is **not** spawned by `/gate-check` — `/story-done` and `/team-qa` spawn it
- gate-check honors `modes.workflow` but is exempt from `modes.automation` — the collaborative prompting protocol always applies; a phase gate is never auto-run

## Downstream Skill Expects
**Next skill (on PASS):** varies by gate

| Gate passed (target) | Enabled downstream skill |
|---|---|
| `definition` (Discovery → Definition) | `/map-features` |
| `architecture` (Definition → Architecture) | `/create-architecture` (first), then `/architecture-decision`, `/api-design`, `/data-model`, `/test-setup` |
| `validation` (Architecture → Validation) | `/design-language`, `/ux-design`, `/walking-skeleton` (then `/api-design reconcile`, `/create-epics`, `/create-stories`, `/sprint-plan`) |
| `build` (Validation → Build) | `/sprint-plan`, `/dev-story`, `/story-readiness`, `/story-done` |
| `hardening` (Build → Hardening) | `/team-hardening`, `/security-audit`, `/load-test` |
| `launch` (Hardening → Launch) | `/team-release`, `/retrospective release <version>` |

- `/rollout-plan` reads the latest `production/gate-checks/gate-launch-*.md` and parses its `> **Verdict**:` line (absence is a note there, not a stop)
- The status line, `/help`, `/project-stage-detect`, `detect-gaps.sh`, `/rollout-plan` and `/team-release` read `project.stage` (through `stage-estimate.sh` or the resolved config) — the stage this skill writes is the one they report
- Launch is terminal: after the launch gate, each release is recorded under `production/releases/<version>/` by `/release-checklist`, `/rollout-plan` and `/team-release` — records, not gates

## Known Fragile Points
- `project.stage` in `project.yaml` is the single authoritative stage record — if it is manually edited to a wrong value outside of `/gate-check`, `/help` and the status line report the wrong phase; `stage-estimate.sh` still prints its `ESTIMATE:` so `detect-gaps.sh` can warn when the tree looks two or more phases ahead
- The Build → Hardening gate runs the test suite via Bash with `commands.test`. If that command is not configured or fails to start, the test check yields `NOT ASSESSED`, which outranks PASS — so the gate cannot advance a stage on the strength of a suite that never ran. Without the `NOT ASSESSED` branch this masks silent test regressions: an unconfigured runner simply contributes nothing to the verdict
- The Validation → Build gate has a hard Walking Skeleton Validation block; items the report does not settle (e.g., "the staging deploy was rolled back once") require a user response via `AskUserQuestion` — if the user answers without checking staging, a false PASS is possible
- Gate conditions (*UI*, *PII*, *Stores*, *Regions*, *Multi-locale*) that are unset are asked on every run — the answers are never persisted here; until `/setup-stack` records the keys, the same questions come back
- Gate report files in `production/gate-checks/` are not validated for completeness by any downstream skill; a partial report written due to a session interruption will look identical to a complete one (only its verdict line is parsed)
- `docs/consistency-failures.md` is optional context that adjusts scrutiny but does not change the formal checklist; if this file exists but is stale, the increased-scrutiny signals may point at resolved issues
