# /story-done — Handoff Contract

## Role in Pipeline
Closes the implementation loop for a single story by verifying every acceptance criterion, checking the evidence its type requires (including the migration floor and the run result), detecting PRD, ADR and API-contract deviations, running code review (the TL-CODE-REVIEW gate, or the inline `/code-review` checklist when the review mode skips it) and the QL-TEST-COVERAGE gate, and — after user approval — setting the story to `> **Status**: Complete` with a `## Completion Notes` section and its `production/sprint-status.yaml` entry to `status: done`.

## Configuration Consumed
Bootstrap `--keys` (exact): `review_mode,automation,workflow,story_granularity,qa.level,testing.strict,feature_overrides,code_roots`.
- `review_mode` (`--review` overrides) — whether TL-CODE-REVIEW and QL-TEST-COVERAGE spawn: `full` spawns; `lean` skips every gate whose ID does not end in `-PHASE-GATE`; `solo` skips all gates
- `workflow` + `feature_overrides` — the tier per story (PRD stem of `**PRD**:`), governing deviation checks 1 and 3
- `qa.level` — whether per-type evidence is required; never waives the migration floor or the run-result check
- `testing.strict` — the five per-type keys `logic`, `integration`, `ui`, `e2e`, `config` (`true` BLOCKING, `false` ADVISORY, `unset` → the default column below); always read from the resolved line, which merges `project.local.yaml`
- `code_roots` — the roots every code scan covers; unresolved ⇒ `NOT CHECKED — no code root resolved (set stack.layers.<layer>.root via /setup-stack)` per scan
- `story_granularity` — cadence expectation only; `automation` — the prelude's mode rules
- Read from `project.yaml` at run time (no label): `commands.test`, `testing.patterns`

## Inputs Required

### Files That Must Exist
| File | Required Fields / Sections | Read-Only? |
|------|---------------------------|-----------|
| `production/epics/<epic-slug>/story-NNN-<slug>.md` (the story) | `> **Status**:` (expected `In Progress`, or `Ready` if `/dev-story` was skipped — `/dev-story` sets `In Progress`, and `/story-done` is the only skill that writes `Complete`), `> **Type**:`, `> **Surface**:`, `> **Manifest Version**:`, `**PRD**:`, `**Requirement**:` (TR-IDs), ADR reference, `**API Contract**:`, `**Migration**:`, `**Feature Flag**:`, `**Analytics Events**:`, `## Acceptance Criteria`, `## Test Evidence` path | No — status, `> **Last Updated**:` and `## Completion Notes` written after approval |
| `docs/architecture/tr-registry.yaml` | Entry per TR-ID with current `requirement` text | Yes |
| `design/prd/<feature-slug>.md` | `## Acceptance Criteria`; the requirement's rules in `## Functional Requirements` / `## Business Rules & Calculations`; the flag row of `## Configuration & Flags` | Yes |
| `docs/architecture/adr-NNNN-<slug>.md` (referenced ADR) | `## Decision`, `## Consequences` (bounded reads only) | Yes |
| `docs/architecture/control-manifest.md` | `Manifest Version:` header date, forbidden patterns | Yes (absent ⇒ staleness check skipped and named) |
| `docs/architecture/tech-radar.md` | `## Forbidden Patterns` | Yes (absent ⇒ that part of check 3 named as skipped) |
| API contract named by `**API Contract**` | The operation the story uses | Yes (only when the field is not `None`) |
| `docs/data/migrations/NNNN-<slug>.md` named by `**Migration**` | `## Status` | Yes (only when the field is not `None`) |
| `design/product/tracking-plan.md` | `## Events` rows for the story's events | Yes (only when `**Analytics Events**` is not `None`) |
| `production/session-state/active.md` | Active story path and the `/dev-story` extract (changed files, run result) | No — session extract appended |

### Evidence Checked (presence checked, not pre-required — absence triggers the gate)
| Story Type | Covers | Required Evidence | Location | Default Gate Level | `testing.strict` key |
|---|---|---|---|---|---|
| **Logic** | domain rules, calculations, validators, state machines | Automated unit test — must pass | per `testing.patterns` (co-located) or `tests/unit/<feature>/` | BLOCKING | `testing.strict.logic` |
| **Integration** | API handler + DB, queue consumers, third-party adapters, **contract tests** against `docs/api/` | Integration or contract test — must pass | `tests/integration/<feature>/`, `tests/contract/<feature>/` (or per `testing.patterns`) | BLOCKING | `testing.strict.integration` |
| **UI** | screens, components, visual states (incl. visual regression) | Component test and/or retained screenshots of each state touched (desktop + mobile viewport, or device) | `production/qa/evidence/<story-slug>/` | BLOCKING | `testing.strict.ui` |
| **E2E** | a critical user journey across UI → API → DB | Automated E2E test (Playwright / Cypress / Detox / Maestro) passing against a running environment, with trace/screenshot | `tests/e2e/<journey>/` + `production/qa/evidence/<story-slug>/` | BLOCKING | `testing.strict.e2e` |
| **Config** | feature flags, env config, pricing/limit tables | Smoke check pass | `production/qa/smoke-YYYY-MM-DD.md` | ADVISORY (`/smoke-check` unset ⇒ BLOCKING, intentional exception kept) | `testing.strict.config` |

- **Migration floor**: a story whose `**Migration**` is not `None` (any Type) requires `production/qa/evidence/<story-slug>/migration-dry-run.log` — Expand applied and rolled back on a disposable database — at every `qa.level` and regardless of `testing.strict.config`. Absent ⇒ BLOCKING.
- **Run result**: the `Run result: OBSERVED | NOT VERIFIED | N/A` line (tokens unchanged; `.claude/docs/run-and-observe.md`) is read from `production/qa/evidence/<story-slug>/evidence.md`, else the `/dev-story` session extract, else `## Completion Notes`. `NOT VERIFIED` on a UI or E2E story, or on any story whose criteria name something observable, is flagged at the type's resolved gate level; a missing line is ADVISORY. Not waived at `qa.level: minimal`.
- `<story-slug>` = the story file name without `.md`. Evidence under `production/session-logs/` (gitignored) never counts.

### Preconditions
- The story is findable by argument path, in `production/session-state/active.md`, or as an `in-progress`/`review` entry of `production/sprint-status.yaml`
- Implementation has been attempted — this skill does not implement; it verifies
- For Logic, Integration, UI and E2E stories the evidence above must **exist** before a COMPLETE verdict is possible, unless `testing.strict.<key>` is explicitly `false` for that type, in which case the gap is recorded as a warning but does not block
- **Tests run only when `commands.test` is set.** Then the story's own test files run through it and pass/fail is recorded per criterion; when it is unset the report says `NOT CHECKED — test results (commands.test unset)` and the evidence gate is existence only. Pass/fail of the full suite is established by `/smoke-check` and `/gate-check`

## Gates Spawned
| Gate | Owner | Tokens (class) | Spawned when | `Pass:` line |
|---|---|---|---|---|
| QL-TEST-COVERAGE (`.claude/docs/director-gates/ql-test-coverage.md`) | qa-lead | ADEQUATE (APPROVE-class) / GAPS (CONCERNS-class) / INADEQUATE (REJECT-class) | `review_mode: full`, `qa.level` not `minimal`, story not a Config story without code or migration | story path(s) or sprint id · test file paths · evidence directory paths · resolved `testing.strict` and `qa.level` lines |
| TL-CODE-REVIEW (`.claude/docs/director-gates/tl-code-review.md`) | tech-lead | APPROVE (APPROVE-class) / CONCERNS (CONCERNS-class) / REJECT (REJECT-class) | `review_mode: full` and implementation files exist | story path · changed file list · API contract path (or "none") · governing ADR path |

- Skip notes: `[GATE-ID] skipped — Lean mode` / `[GATE-ID] skipped — Solo mode`; the lean rule is the suffix rule (skip every gate whose ID does not end in `-PHASE-GATE`), never a list of IDs.
- Each reply's first line is parsed as `[GATE-ID]: TOKEN`; an unparseable first line is handled as CONCERNS-class.
- **When TL-CODE-REVIEW is skipped** the skill runs the `/code-review` checklist inline over the changed files and records `Code review: inline checklist (TL-CODE-REVIEW skipped — <Mode> mode)`. When that cannot run it prints `NOT CHECKED — code review` and the verdict is capped at COMPLETE WITH NOTES.
- `/gate-check` never spawns QL-TEST-COVERAGE; only `/story-done` and `/team-qa` do.

## Verdicts Emitted
`COMPLETE` / `COMPLETE WITH NOTES` / `NOT ASSESSED` / `BLOCKED`.

`NOT ASSESSED` outranks `COMPLETE` — one or more acceptance criteria could not be evaluated at all, which is not the same as evaluating them and finding them met. Precedence is `BLOCKED`, then `NOT ASSESSED`, then `COMPLETE WITH NOTES`, then `COMPLETE`; see the verdict section of `SKILL.md`. `NOT CHECKED — code review` caps the verdict at `COMPLETE WITH NOTES`. The verdict is recorded in the report and as `**Verdict**:` in `## Completion Notes`.

## Deviation Checks
1 PRD rules (tier-dependent) · 2 manifest staleness · 3 ADR constraints + tech-radar forbidden patterns (tier-dependent) · 4 hardcoded values · 5 scope · 6 API contract drift (missing operation / status / required field / type mismatch ⇒ BLOCKING; undeclared response field ⇒ ADVISORY) · 7 migration plan phase state (drop or rename inside an Expand story ⇒ BLOCKING; `## Status` not updated ⇒ ADVISORY) · 8 flag default recorded (none or disagreeing ⇒ BLOCKING) · 9 no PII in new log statements (any hit ⇒ BLOCKING) · 10 tracking events present in `design/product/tracking-plan.md` (missing ⇒ ADVISORY). Checks 6–10 run at every tier whenever the story's field names something; check 9 always runs.

## Outputs Produced

### Files Written
| File | Guaranteed Fields / Sections | Notes |
|------|------------------------------|-------|
| The story file | `> **Status**: Complete`, `> **Last Updated**:`, `## Completion Notes` (date, verdict, criteria count, deviations, test evidence, migration dry-run, run result, code review; `**Override**` line when closed over BLOCKED / NOT ASSESSED) | after explicit user approval |
| `production/sprint-status.yaml` | the story's entry `status: done`, `completed: [date]`; top-level `updated:` | covered by the same approval; a missing file or entry is reported in one line |
| `docs/tech-debt-register.md` | Advisory deviation entries | appended only with user approval ("May I write this to `docs/tech-debt-register.md`?") |
| `production/session-state/active.md` | `## Session Extract — /story-done [date]` block: verdict, story path, code review, tech debt count, next recommended story | appended (created if absent) |

### Output Guarantees
- `> **Status**: Complete` and `status: done` are written only after explicit user approval; for a BLOCKED or NOT ASSESSED verdict the close always prompts, in every automation mode
- `## Completion Notes` always contains the completion date, the verdict, the criteria pass count, the deviation summary, the test evidence (or the `qa.level: minimal` waiver), the migration dry-run (or N/A), the run result and the code-review record
- Code review is never silently absent: a gate verdict, the inline-checklist line, or `NOT CHECKED — code review`
- Every skipped check names itself (`NOT CHECKED — …`, `[GATE-ID] skipped — <Mode> mode`, `QL-TEST-COVERAGE skipped — qa.level minimal`)
- Session state always records the final verdict and the next recommended story path

## Immutability Rules
- READS but does NOT modify: `docs/architecture/tr-registry.yaml`, ADRs (`## Decision` + `## Consequences` only), PRDs, `docs/architecture/control-manifest.md`, `docs/architecture/tech-radar.md`, the API contract, migration plans, `design/product/tracking-plan.md`, source files under the code roots (Grep only), test files (run via `commands.test` when set; never edited), evidence files
- MODIFIES: the story file (status, last-updated, completion notes), `production/sprint-status.yaml` (the story's entry), `production/session-state/active.md` (append), `docs/tech-debt-register.md` (append, only with approval)
- Does NOT write to the code roots, tests or `production/qa/evidence/` under any circumstances

## Hard Constraints (Never Violate)
- Never sets `> **Status**: Complete` or `status: done` without explicit user approval
- Never marks a Logic, Integration, UI or E2E story Complete on missing evidence when its resolved gate level is BLOCKING — BLOCKING by default and whenever `testing.strict.<key>` is `true`; ADVISORY only under an explicit `false`. A written description of a visual check is not a substitute for the capture
- Never marks a story with `**Migration**` ≠ `None` Complete without `migration-dry-run.log` unless the user explicitly overrides a BLOCKED verdict — the floor does not consult `qa.level` or `testing.strict.config`
- Never counts evidence under `production/session-logs/`
- Never reads the gate definition files in the parent session; passes only the path and the `Pass:` items
- Never auto-fixes failing acceptance criteria — reports them and asks
- Never proceeds automatically to Phase 7 when the verdict is BLOCKED or NOT ASSESSED; an explicit user request routes there and still prompts
- Never silently overrides a BLOCKED verdict — an override is documented in `## Completion Notes`

## Downstream Skill Expects
**Next skills:** `/story-readiness` (next story), or the sprint close-out `/smoke-check sprint` → `/team-qa sprint` → `/retrospective sprint-<N>` → `/gate-check` (only when the sprint closes a phase; QA sign-off is a Hardening exit criterion read by `/gate-check launch`, not by `/gate-check hardening`)
- `/sprint-status`, `/help`, `/milestone-review` and `.claude/scripts/stage-estimate.sh` read `status: done` from `production/sprint-status.yaml`
- `/team-qa` reads story files with `> **Status**: Complete`, their `## Completion Notes` and the evidence directories, and may spawn QL-TEST-COVERAGE over the whole sprint
- `/gate-check` reads story files and evidence and runs the suite itself when `commands.test` is set — a `Complete` status is never evidence that tests passed; an unconfigured runner is `NOT ASSESSED` there rather than a silent skip
- It assumes every Complete story whose type resolved to BLOCKING has its evidence on disk; under an explicit `testing.strict.<key>: false` a story may be Complete with the gap documented in `## Completion Notes`

## Known Fragile Points
- The story's `## Test Evidence` path must match what `/dev-story` wrote; a mismatch triggers a false BLOCKING result even if the test exists under a slightly different name (the broader `testing.patterns` search mitigates it)
- A missing `> **Type**:` makes test-evidence enforcement ADVISORY only
- The manifest staleness check is skipped when `docs/architecture/control-manifest.md` does not exist; the skip is named in the report
- The changed file list comes from the `/dev-story` extract or read-only git; when neither is available the user is asked, and when it cannot be established code review is `NOT CHECKED`
- The >50% UNTESTED escalation can be tripped by criteria that legitimately need a staging run or a usability session — mark them `DEFERRED` explicitly rather than leaving them unchecked
- Contract-drift and PII checks are Grep-based: they find what they look for in the changed files and nothing else; `NOT CHECKED` when no code root resolves
