# /dev-story — Handoff Contract

## Role in Pipeline
Bridges planning and code for a single story: loads its full context (story file, TR registry entry, ADR summary and freshness, control-manifest layer rules, tech radar, API contract operation, migration plan, flag and tracking events, stack risk), routes it by the story's `> **Type**:` and `> **Surface**:` to the right engineer and stack specialist, drives implementation and tests into the resolved code roots, runs and observes the product, and leaves the story `In Progress` and ready for `/code-review` then `/story-done`.

## Configuration Consumed
Bootstrap `--keys` (exact): `automation,automation_always_ask,workflow,story_granularity,qa.level,testing.strict,feature_overrides,stack,code_roots,surfaces`.
- `workflow` + `feature_overrides` — the tier per story, keyed by the PRD stem of `**PRD**:` (fallback: the `TR-<feature-slug>-NNN` segment)
- `qa.level` — whether the brief carries a test requirement; never waives the run or the migration floor
- `testing.strict` — the five per-type keys `logic`, `integration`, `ui`, `e2e`, `config` (`true` BLOCKING, `false` ADVISORY, `unset` → the per-type default of `.claude/docs/coding-standards.md`)
- `stack` — configured layers and the `[routing: …]` list; `code_roots` — where code is written; `surfaces` — `platform.surfaces` cross-check
- `automation_always_ask` — the categories that prompt in every automation mode
- Read from `project.yaml` at run time (no label): `naming.*`, `commands.*`, `testing.patterns`, `performance.*`

## Inputs Required

### Files That Must Exist
| File | Required Fields / Sections | Read-Only? |
|------|---------------------------|-----------|
| `production/epics/<epic-slug>/story-NNN-<slug>.md` (the story) | `> **Status**: Ready`, `> **Type**:`, `> **Surface**:`, `> **Layer**:`, `> **Manifest Version**:`, `**PRD**:`, `**Requirement**:`, `**ADR Governing Implementation**:`, `**ADR Decision Summary**:`, `**ADR Version**:`, `**Stack**:` / `**Risk**:`, `**Stack Notes**:`, `**API Contract**:`, `**Migration**:`, `**Feature Flag**:`, `**Analytics Events**:`, `## Acceptance Criteria`, `## Implementation Notes`, `## Out of Scope`, `## Test Evidence`, `## Dependencies` | **Partially mutable.** Sets `> **Status**: In Progress` and `> **Last Updated**:` before spawning any agent; may update `**ADR Version**` / `> **Manifest Version**:` (and add `> **Manifest-Note**:`) after the user chooses to. Everything else is read-only |
| `docs/architecture/tr-registry.yaml` | Entry matching the story's TR-ID with current `requirement` and `prd:` | Yes — required at `full` only |
| `docs/architecture/adr-NNNN-<slug>.md` (the governing ADR) | `## Last Verified` (freshness check); on mismatch `## Decision`, `## Stack Compatibility` (incl. the `**Domain**` row), `## ADR Dependencies`, `## Security & Privacy Implications`, `## Migration Plan` | Yes — required at `full`; at `standard`/`minimal` only when the story references one |
| `docs/architecture/control-manifest.md` | Header date; `## <Layer> Layer Rules` | Yes — WARN when absent |
| `docs/architecture/tech-radar.md` | `## Forbidden Patterns`, `## Hold` | Yes — WARN when absent |
| API contract named by `**API Contract**` (e.g. `docs/api/openapi.yaml`) | The operation the pointer names | Yes — required when the field is not `None`, at every tier |
| `docs/data/migrations/NNNN-<slug>.md` named by `**Migration**` | `## Expand`, `## Rollback per Phase`, `## Status`, `## Lock & Duration Budget` | Yes — required when the field is not `None`, at every tier |
| `design/prd/<feature-slug>.md` | `## Functional Requirements`, `## Business Rules & Calculations`, `## Edge Cases`, `## Configuration & Flags` (flag default) | Yes |
| `design/product/tracking-plan.md` | `## Events` rows for the story's events | Yes |
| `docs/stack-reference/VERSION.md` | `## Pinned Components` row of the primary surface's component (`Knowledge Risk`) | Yes |
| `project.yaml` | `naming.*`, `commands.*`, `testing.patterns`, `performance.*` | Yes |
| `production/session-state/active.md` | Active story when no argument is given | No — session extract appended |

### Preconditions
- The story is `> **Status**: Ready` (validated by `/story-readiness`)
- A referenced ADR is `Accepted` — `Proposed` is a blocker, directed to `/architecture-decision`
- Every `## Dependencies` story is `Complete`, or the user accepts the risk explicitly
- At least one code root resolves for the story's Surface (§ Routing contract below); nothing resolved ⇒ no code is written
- `**API Contract**` / `**Migration**`, when not `None`, point at files that exist

## Routing Contract
Evaluated top to bottom; first match wins. The first `> **Surface**:` value picks the row; each additional surface adds its row's primary agent as a secondary.

| Story context | Primary agent | Secondary (always, for code stories) |
|---|---|---|
| Type `Config` with no code (flags, env, pricing tables) | none — Config path | — |
| Type `Config` with a DB migration (`**Migration**` ≠ None) | backend-engineer | data-specialist |
| Surface `infra` | devops-engineer | cloud-specialist |
| Surface `analytics` (pipelines, warehouse, metrics layer) | data-engineer | analytics-engineer |
| Surface `admin` | internal-tools-engineer | routed web sub-specialist (or web-specialist) |
| ADR Domain `ML` or story field `**ML**: yes` | ml-engineer | routed backend sub-specialist (or backend-specialist) |
| Surface `web` | frontend-engineer | routed web sub-specialist (or web-specialist); + platform-engineer when the story's files are under `stack.shared_roots` |
| Surface `ios`, `android` or `mobile` | mobile-engineer | routed mobile sub-specialist(s) (or mobile-specialist); + platform-engineer when the story's files are under `stack.shared_roots` |
| Surface `api` **and** (Layer `Foundation` **or** the story's files are under `stack.shared_roots`) | platform-engineer | routed backend sub-specialist (or backend-specialist) |
| Surface `api` | backend-engineer | routed backend sub-specialist (or backend-specialist) |

- The routed sub-specialist comes from the `[routing: …]` list of the `stack` line; an unconfigured layer spawns none and prints `NOT CHECKED — <layer> layer not configured (run /setup-stack)`.
- **Risk HIGH ⇒ the layer lead replaces the sub.** Risk = the `docs/stack-reference/VERSION.md` Pinned Components row of the primary surface's component (web/admin → web framework, ios/android/mobile → mobile framework, api → backend framework); no row or `NOT DETERMINED` ⇒ HIGH; VERSION.md wins over the story's `**Risk**`.
- A lead that returns `NOT CONSULTED — <sub> (nested spawn unavailable)` or a `<sub>: <task>` hand-off gets that sub spawned by /dev-story, or the NOT CONSULTED line carried into the Phase 6 summary.

**Surface → code root** (roots from `resolve_code_roots` via the `code_roots` line):

| Surface | Root used |
|---|---|
| `web` | the `web` root; several ⇒ the one `**Stack Notes**` or the file list names, else ask |
| `ios`, `android`, `mobile` | the `mobile` root (same multi-root rule) |
| `api` | the `backend` root (same multi-root rule) |
| `admin` | the `web` root whose last path segment contains `admin`, if exactly one; else ask — never guess |
| `infra` | the `cloud` root |
| `analytics` | ask; the answer is recorded in the story's `**Stack Notes**` |
| migrations (`**Migration**` ≠ None) | `stack.layers.data.migrations_dir` |
| Layer `Foundation` shared code | the first `shared` root, else ask |

Only an `app` root ⇒ used for every surface. Only `detected`/`undeclared` roots ⇒ ask and suggest `/setup-stack`. Nothing resolved ⇒ `NOT CHECKED — no code root resolved (set stack.layers.<layer>.root via /setup-stack)` and no code is written.

## Outputs Produced

### Files Written
| File | Guaranteed Fields / Sections | Notes |
|------|------------------------------|-------|
| Source files under the resolved code root(s) | Doc-commented public APIs; contract-conformant handlers; authorization on every new endpoint; no hardcoded business values, secrets or PII in logs; follows the ADR guidance, the manifest layer rules and the tech radar | written by the routed engineer agent(s), each asking "May I write" per file |
| Executable migration under `stack.layers.data.migrations_dir` | The story's phase (Expand unless the story says otherwise), backward compatible with running versions | written by the engineer after the `db_migrations` always-ask check |
| Test files per `testing.patterns` (or `tests/unit/<feature>/`, `tests/integration/<feature>/`, `tests/contract/<feature>/`, `tests/e2e/<journey>/`) | At least one test per acceptance criterion; names describe `scenario → expected`; deterministic | not written at `qa.level: minimal`, and the summary says so |
| `production/qa/evidence/<story-slug>/…` | Captures `NN-<state>-desktop.png` / `NN-<state>-mobile.png` / `NN-<state>-axe.json` (web), `NN-<state>-ios.png` / `NN-<state>-android.png`, `NN-<operation>.json` (redacted), `migration-dry-run.log`, `evidence.md` (from `.claude/docs/templates/test-evidence.md`, `> **Verdict**: <OBSERVED \| NOT VERIFIED \| N/A>` under its H1) | `<story-slug>` = the story file name without `.md`; never under `production/session-logs/` |
| `production/sprint-status.yaml` | The story's entry `status: in-progress`; top-level `updated:` | only when the file and the entry exist — otherwise a one-line "not updated" note |
| The story file | `> **Status**: In Progress`, `> **Last Updated**:` | after "May I write" |
| Configuration files (Config stories only) | The values the acceptance criteria name, with from/to recorded | written by this skill after "May I write"; `billing_changes` / `secrets_access` always-ask checks apply |
| `production/session-state/active.md` | `## Session Extract — /dev-story [date]` block | appended (created if absent) |

### Output Guarantees
- The implementation summary states a **verification** result — what ran (`commands.typecheck`, `commands.lint`, `commands.test`) and its outcome; an unset command or missing toolchain is `NOT VERIFIED — <reason>`, never an inference that the code is fine
- The summary states exactly one **run result** line: `Run result: OBSERVED — <what was seen>` with a retained path, `Run result: NOT VERIFIED — <reason>`, or `Run result: N/A — <reason>` (pure Logic/Config with nothing observable). No web capture script ⇒ `Run result: NOT VERIFIED — no capture script (run /test-setup)`. `NOT VERIFIED` is a blocker at the default gate level for UI and E2E. The run is **not waived at `qa.level: minimal`**. Procedure: `.claude/docs/run-and-observe.md`
- A story with `**Migration**` ≠ `None` gets `migration-dry-run.log` (Expand applied and rolled back on a disposable database) or an explicit `Migration dry-run: NOT VERIFIED — <reason>`
- At `qa.level: minimal` no test file is written and the summary prints the waiver line; a waived run and a forgotten one never produce the same artifact
- The routing line names the matched row, the agents and the root(s); a layer with no specialist prints its `NOT CHECKED` line
- `NOT ASSESSED` is an accepted inbound value of the story's `**Risk**`; it counts as HIGH for the lead-instead-of-sub decision
- **Completion is not assumed.** An agent that stopped early, or code that fails to build, makes the story **INCOMPLETE** with the breakage named; `Implementation Complete` is not emitted and the status is not advanced

## Immutability Rules
- READS but does NOT modify: `project.yaml`, `docs/architecture/tr-registry.yaml`, ADR files, PRDs in `design/prd/`, `docs/architecture/control-manifest.md`, `docs/architecture/tech-radar.md`, the API contract under `docs/api/`, migration plans under `docs/data/migrations/`, `design/product/tracking-plan.md`, `docs/stack-reference/VERSION.md`
- MODIFIES: files under the resolved code roots and the migrations directory (via engineer agents), test files (via engineer agents), Config-story configuration (directly, after approval), `production/qa/evidence/<story-slug>/**`, the story's entry in `production/sprint-status.yaml`, the story header fields listed above, `production/session-state/active.md` (append)
- Writes only the `In Progress` status (story) and `in-progress` (sprint status). Advancing a story to `Complete` / `done` belongs to `/story-done` alone

## Hard Constraints (Never Violate)
- Never marks a story `Complete` or `done`, and never writes a status value with an underscore — the sprint-status enum is `backlog | ready-for-dev | in-progress | review | done | blocked`
- Never writes code when no code root resolves for the story's Surface — prints the `NOT CHECKED — no code root resolved …` line instead
- Never implements a story whose referenced ADR is `Proposed`
- Never edits the API contract, a PRD or an ADR; a needed contract change is surfaced for `/api-design`
- Never uses a `## Forbidden Patterns` entry of the tech radar, or newly introduces a `## Hold` entry
- Never runs a migration or a deploy against production, staging or any shared database, and never creates, rotates or commits a secret; the migration dry-run targets a disposable database only, and API snapshots on staging use a test account
- Never changes a feature flag's production state; `production_deploys` decisions go to `/rollout-plan` or a human
- Never writes evidence under `production/session-logs/`
- Never marks a Logic, Integration, UI or E2E story implemented at `qa.level: standard`/`full` without the test file declared in `## Test Evidence`
- Never touches files outside the story's `## Out of Scope` boundary without explicit user approval

## Downstream Skill Expects
**Next skills:** `/code-review` (the changed files), then `/story-done`
- `/story-done` reads the story file (`> **Type**:`, `> **Surface**:`, `**Migration**:`, `**API Contract**:`, `**Feature Flag**:`, `**Analytics Events**:`, `## Acceptance Criteria`, `## Test Evidence`)
- It reads the `Run result:` line from `production/qa/evidence/<story-slug>/evidence.md`, else from the session extract, else from `## Completion Notes`
- It assumes the test file declared in `## Test Evidence` exists (Logic, Integration, UI component tests, E2E) and that captures and `migration-dry-run.log` are under `production/qa/evidence/<story-slug>/`
- It assumes source files under the resolved roots match the criteria, so Grep-based deviation checks (contract drift, PII in logs, hardcoded values) can run
- `/sprint-status` and `/help` read `status: in-progress` from `production/sprint-status.yaml`

## Known Fragile Points
- A story whose embedded `> **Manifest Version**:` differs from the manifest header may meet new rules; the skill surfaces this, but proceeding with old rules produces non-compliant code
- The test path in `## Test Evidence` must be exact — `/story-done` checks that literal path first
- A stale `requirement` in the TR registry can diverge from the PRD; the registry is authoritative, but a visible discrepancy is flagged
- A declared-but-missing root (`missing`) is created only after the user agrees; creating it silently would scatter an app outside the workspace
- The routed specialist depends on `stack.layers.<layer>.framework`; a framework string the routing rules do not recognise yields the lead alone, which is correct but slower
- A Config story that actually needs code must not claim "no code" — it then skips the engineer and the specialist; `/story-done` still sees `> **Type**: Config` and applies the smoke-check evidence rule
