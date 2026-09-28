---
name: adopt
description: "Brownfield audit — do existing artifacts conform to CCSS contracts (PRD sections, feature map, ADR headings, API contract, migrations, tests/CI, runbooks)? Numbered adoption plan."
argument-hint: "[focus: full | prds | adrs | api | data | stories | infra]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Write, AskUserQuestion, Bash(bash "*/.claude/skills/adopt/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,automation_always_ask,workflow,stack,code_roots,surfaces`

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

# Adopt — Brownfield Framework Adoption

This skill audits an existing product's artifacts for **format compliance** with
the framework's contracts — the headings, fields and paths that skills, scripts and
gates match on — then produces a prioritised, checkable adoption plan.

**This is not `/project-stage-detect`.**
`/project-stage-detect` answers: *what exists, and what stage does it add up to?*
`/adopt` answers: *will what exists actually work with the framework's skills?*

A product can have PRDs, ADRs, an OpenAPI file and stories — and every
format-sensitive skill will still fail silently or produce wrong results if those
artifacts are in the wrong place or the wrong internal shape: a PRD whose headings
`prd-structure-check.sh` cannot find, an ADR with no `## Status`, a contract outside
`docs/api/`, a story without `> **Surface**:`.

**Output:** `docs/adoption-plan-YYYY-MM-DD.md` — a persistent, checkable adoption
plan. It is the only file this skill writes on its own authority (Phase 7 may, with
a separate approval, correct feature-map status cells in place).

**Argument modes:**

**Audit focus:** `$ARGUMENTS[0]` (blank = `full`)

- **No argument / `full`**: Complete audit — every artifact type below
- **`prds`**: product brief / one-pager, PRD sections and the feature map (2a, 2b)
- **`adrs`**: ADR format compliance only (2c)
- **`api`**: API contract presence, location and lint (2d)
- **`data`**: data model and migrations versus plans (2e)
- **`stories`**: story and sprint-status format compliance (2f)
- **`infra`**: tests & CI, SLOs & runbooks, registries, manifest, stack pin and
  config (2g, 2h, 2i)

---

## Phase 0: Configuration

Use the resolved block above as-is:

- **`workflow`** (per `.claude/docs/workflow-modes.md`) scopes the Phase 2 audit and
  the Phase 3 severity: `full` audits every doc type at full structure; `standard`
  audits only the required docs and sections (optional sections are informational,
  not gaps); `minimal` is a one-pager format check plus the stack pin — PRDs, ADRs
  and UX specs are not expected, and any that exist are checked advisorily at the
  `standard` bar.
- **`stack`** — which layers are configured, whether `pinned_on` is set, and the
  specialist routing. `stack: unset — run /setup-stack` is itself a finding (2i).
- **`code_roots`** — where code, tests and executable migrations live. An
  `unresolved` line means every code-root-dependent audit prints
  `NOT CHECKED — no code root resolved (set stack.layers.<layer>.root via /setup-stack)`;
  `undeclared=` roots are audited too and reported with
  `WARN: undeclared code roots: <dirs> — declare them with /setup-stack`.
  Never fall back to scanning `src/` or the whole repo.
- **`platform.surfaces`** — together with `stack`, decides whether the product has
  a **backend** (a `backend=` or `data=` layer on the `stack` line, or `api` in
  `platform.surfaces`). The API contract and data audits (2d, 2e) run when that is
  true **or unknown**; unknown findings carry "(condition unknown — run
  /setup-stack)". Unset is not "no backend".
- **`automation`, `automation_always_ask`** — every question and every write below
  follows the automation prelude; categories in `automation_always_ask` always
  prompt, even in `autonomous` mode.

Read from `project.yaml` with Read (these keys have no config-block label):
`framework.version`, `testing.patterns`, `commands.test`, `commands.e2e`,
`commands.lint`, `commands.typecheck`, `commands.api_lint`, `naming.*`,
`performance.*`, `workflow_overrides.edge_cases`, `workflow_overrides.config_flags`.

**This skill never changes configuration.** It does not write `project.yaml` — no
stage, no review mode, none of the knobs `modes.rigor` fronts. Review depth follows
`modes.rigor` and is changed only through `/settings`; the project stage is recorded
by `/gate-check` (Phase 4 bootstrap step).

---

## Phase 1: Detect Project State

Emit one line before reading: `"Scanning project artifacts..."` — this confirms the
skill is running during the silent read phase.

Then read silently before presenting anything else.

### Stage

```
Bash: bash .claude/scripts/stage-estimate.sh
```

Keep its four lines (`STAGE:`, `SOURCE:`, `ESTIMATE:`, `EVIDENCE:`). `STAGE` is the
authoritative phase when `SOURCE: project.yaml`; otherwise it is the estimate. When
the two differ, say so — a recorded stage the tree does not support is itself worth
a line in the plan. Do not carry a stage ladder of your own.

### Existence check
- Product brief `design/product/product-brief.md`, or the one-pager
  `design/product/one-pager.md` (the `minimal` tier's record)
- Feature map `design/product/feature-map.md`
- PRDs: `design/prd/*.md` (depth 1 only — `design/prd/reviews/` holds review logs).
  A brownfield product's specs are not guaranteed to live there: also Glob likely
  homes (`docs/prd/**/*.md`, `docs/specs/**/*.md`, `specs/**/*.md`, `**/*-prd.md`)
  and list them as **PRD candidates** — ask the user which are feature specs rather
  than assuming.
- ADRs: `docs/architecture/adr-*.md`; ADRs kept elsewhere (`doc/adr/`, `docs/adr/`,
  `docs/decisions/`) are **ADR candidates** to relocate
- API contract: the catalog's `architecture.api-design` globs — `docs/api/openapi*.yaml`,
  `docs/api/openapi*.json`, `docs/api/*.graphql`, `docs/api/*.proto`,
  `docs/api/asyncapi*.yaml`. Contracts elsewhere (`openapi.yaml` at the root,
  `swagger.json`, a `*.graphql` schema inside a backend root) are **contract
  candidates** to relocate
- Data: `docs/data/data-model.md`, plans `docs/data/migrations/*.md`, and the files
  under the `data=` root of the `code_roots` line
- Stories `production/epics/*/story-*.md`, epics `production/epics/*/EPIC.md`,
  `production/sprint-status.yaml`
- Tests & CI: test files where `testing.patterns` says tests live (else `tests/**`
  and co-located `*.test.*` / `*.spec.*`), and the CI files of the catalog
  `architecture.test-setup` step (`.github/workflows/*.yml`, `.gitlab-ci.yml`, …)
- Ops: `docs/ops/slo.md`, runbooks `docs/ops/runbooks/*.md`
- Stack reference `docs/stack-reference/VERSION.md`
- Glob `docs/adoption-plan-*.md` — note the filename of the most recent prior plan if any exist

If the project appears fresh — `ESTIMATE: Discovery` with no brief, one-pager, PRD,
ADR or contract, and the `code_roots` line resolves nothing (no declared, undeclared
or detected root) — use `AskUserQuestion`:
- "This looks like a fresh project — no existing artifacts found. `/adopt` is for
  products with work to bring under the framework. What would you like to do?"
  - "Run `/start` — begin guided first-time onboarding"
  - "My artifacts are in a non-standard location — help me find them"
  - "Cancel"

Then stop — do not proceed with the audit regardless of which option the user picks
(each option leads to a different skill or manual investigation).

Report: "Detected stage: [STAGE] ([SOURCE]; estimate [ESTIMATE] — [EVIDENCE]).
Found: [N] PRDs (+[n] candidates), [M] ADRs, [K] contract files, [P] stories,
[R] runbooks."

---

## Phase 2: Format Audit

For each artifact type in scope (based on the audit focus **and the resolved
workflow tier**), check not just that the file exists but that it contains the
internal structure the framework requires. At `minimal`, scope the audit to the
one-pager and the stack pin (2a, 2i) — do not audit for PRDs, ADRs or UX specs
(they are not expected).

An audit that could not run is recorded as `NOT CHECKED — <audit>: <reason>` and
goes into the plan's `## Not Checked` section. It is never counted as "no gaps".

### 2a: Product Brief and PRD Format Audit

**Brief** — at `standard`/`full`, check `design/product/product-brief.md` for the
sections the Discovery → Definition gate reads: `## Problem Statement`,
`## Target Users & Jobs-to-be-Done`, `## Value Proposition`,
`## Product Principles & Anti-Goals`, `## Success Metrics`, `## Riskiest Assumptions`,
`## MVP Scope`. At `minimal`, check `design/product/one-pager.md` for `## Pitch`,
`## Problem & Target User`, `## Core User Journey`, `## Success Signal`,
`## Scope & Non-Goals`, `## Stack`, `## Build Order`. No brief but a working product
⇒ HIGH at `standard`/`full`, fixed by `/reverse-document brief <path>`.

**PRDs — gather section presence deterministically; do not read PRDs to count
headings.** For each PRD and PRD candidate discovered in Phase 1, pass its path
explicitly to the structure-check script:

```
Bash: bash .claude/scripts/prd-structure-check.sh [path-to-prd]
```

**Pass paths one at a time; do not invoke it bare.** The no-argument form sweeps
`design/prd/` only, and a brownfield product's PRDs are not guaranteed to live
there — pass whatever paths Phase 1 found. The script prints a `PRESENT:` list and,
when applicable, an `ABSENT:` list per file. It reports **presence only** and makes
no REQUIRED/ADVISORY judgment (that is the tier logic below). Its heading match is
tolerant — any heading level from `##`, case-insensitive, an optional `3. ` or `3) `
prefix — so do not flag a numbered heading as missing.

If the script prints `Not found:` for a path or errors, that is a **discovery
failure, not a format gap** — report it as "could not audit [path]" and do not
count it as a missing-sections finding.

**Then apply the workflow tier** resolved above to each file's PRESENT/ABSENT
lists. Which sections are **required** (a miss = gap) vs **advisory** (a miss =
informational):
- **`full`** — all 11 sections are required.
- **`standard`** — the 8 required (Overview, Goals & Non-Goals, Functional
  Requirements, Edge Cases, Dependencies, Non-Functional Requirements, Success
  Metrics & Instrumentation, Acceptance Criteria) + Business Rules & Calculations
  for any feature that defines a numeric or policy rule — prices, fees, limits,
  quotas, rate limits, eligibility thresholds, time windows, rounding (the feature's
  Category is a hint, not the test); User Value and Configuration & Flags are
  advisory. `workflow_overrides.config_flags: true` makes Configuration & Flags
  required.
- **`minimal`** — PRDs are not expected; the one-pager is the record. Any PRD
  that does exist is checked at the `standard` bar, advisorily
  (`workflow_overrides.edge_cases: true` makes its Edge Cases required).

The script's 11 canonical labels, in template order, are: Overview, Goals &
Non-Goals, User Value, Functional Requirements, Business Rules & Calculations,
Edge Cases, Dependencies, Non-Functional Requirements, Configuration & Flags,
Success Metrics & Instrumentation, Acceptance Criteria.

A section reported PRESENT can still be an empty heading. For each PRD, also
record with a targeted grep (not a full read):
- Placeholder-only sections — a body that is still a bracketed template placeholder
  (`[...]`) or empty marks a present-but-unwritten section.
- The `**Status**:` header field — `Grep pattern="^>?[[:space:]]*\*\*Status\*\*:"`.
  Valid values: `Draft`, `In Review`, `Needs Revision`, `Approved`, `Implemented`.
- The `## Dependencies` table header `| Feature | PRD | Direction | Nature |` —
  `review-scope.sh` extracts dependency edges from it; a free-form dependency list
  means change propagation silently misses those edges (MEDIUM).

> **The `>?` is load-bearing, and so are `Draft`/`Implemented`.** Both emitters
> write this field inside a blockquote — `.claude/docs/templates/prd.md` and
> `/write-prd` produce `> **Status**: …` — so an anchor of `^\*\*Status\*\*:`
> matches nothing and reports *every* template-compliant PRD as missing its
> Status. The template's own value list offers `Draft` and `Implemented`, so both
> must count as valid.

**Location and naming.** A PRD candidate outside `design/prd/`, or a PRD file whose
name is not `<feature-slug>.md` (kebab-case, no `-prd` suffix), is invisible to the
catalog, the gates and `prd-structure-check.sh` (HIGH). The slug is also the
feature-map row, the `TR-<slug>-NNN` prefix and the stories' `**PRD**:` field, so a
rename is planned together with those references.

### 2b: Feature Map Audit

If `design/product/feature-map.md` exists:

1. **Parenthetical status values** — Grep for any Status cell containing
   parentheses: `"Needs Revision ("`, `"In Review ("`, etc.
   These break exact-string matching in `/gate-check`, `/create-stories`,
   `/write-prd` and `/architecture-review`. **BLOCKING.**

2. **Valid status values** — check that Status column values are only from:
   `Not Started`, `Drafting`, `In Review`, `Needs Revision`, `Approved`, `Implemented`.
   Flag any unrecognised value (BLOCKING — the same exact-match readers).

3. **Column contract** — the main table header must be exactly
   `| Feature | Category | Layer | Tier | Status | PRD | Depends On |`. Readers
   select columns by name, so a missing, renamed or reordered column is HIGH — there
   is one contract for this table, and no separate index with its own Layer column.

4. **Cell values** — `Layer` ∈ `Foundation | Core | Feature | Presentation`;
   `Tier` ∈ `MVP | Beta | GA | Later`; `PRD` is `design/prd/<slug>.md` or `—`;
   `Depends On` lists feature slugs that exist as rows, or `—` (MEDIUM each).

5. **PRD ↔ map status parity** — each PRD's `> **Status**:` maps 1:1 to its row
   (`Draft` ↔ `Drafting`; `In Review`, `Needs Revision`, `Approved`, `Implemented`
   are the same word; `Not Started` = no PRD yet). A mismatch is MEDIUM.

No feature map at `standard`/`full` while PRDs exist ⇒ HIGH, fixed by
`/map-features` (it updates an existing map and never discards a row's Status or PRD).

### 2c: ADR Format Audit

For each ADR file found (and each ADR candidate), map its headings with one grep —
`Grep pattern="^## (Status|ADR Dependencies|Stack Compatibility|PRD Requirements Addressed|Security & Privacy Implications|Performance & SLO Implications)"` —
and check for these critical sections:

| Section | Impact if missing |
|---|---|
| `## Status` | **BLOCKING** — `/story-readiness` and `/create-epics` cannot tell Accepted from Proposed, so the ADR status check silently passes everything |
| `## ADR Dependencies` | HIGH — `adr-dep-graph.sh` lists the ADR under `NO_DEPS_SECTION`; ordering and cycle checks in `/architecture-review` and the Architecture → Validation gate go blind |
| `## Stack Compatibility` | HIGH — post-cutoff API and version risk is unknown |
| `## PRD Requirements Addressed` | MEDIUM — traceability matrix loses coverage |
| `## Security & Privacy Implications` | MEDIUM — the control manifest loses the security and privacy rules it derives from ADRs |
| `## Performance & SLO Implications` | LOW — not pipeline-critical |

For each ADR, record: which sections present, which missing, and the current Status
value if the Status section exists. Valid values: `Proposed`, `Accepted`,
`Superseded by ADR-NNNN`, `Deprecated`. An ADR outside `docs/architecture/`, or not
named `adr-NNNN-<slug>.md`, is invisible to the catalog and the gates (HIGH).

### 2d: API Contract Audit

Runs when the product has a backend (known or unknown — Phase 0). At `minimal`, a
missing contract is informational.

- **Present in `docs/api/`** — lint it. If `commands.api_lint` is set in
  `project.yaml`, run it with Bash (ask first when the command would download or
  install a tool). Report the error and warning counts. A lint that cannot start is
  `NOT CHECKED — api_lint could not run: <reason>`; an unset command is
  `NOT CHECKED — commands.api_lint not set`, and the plan item is
  `/api-design review` (it lints, or runs its structural self-check).
- **Only candidates outside `docs/api/`** — HIGH: the catalog step, the gates and
  `/api-design` look only in `docs/api/`. Plan the move (and any code-generation
  path that points at the old location).
- **No contract at all** with a backend — HIGH at `standard`/`full`:
  `/api-design new`, documenting the operations the code already serves before
  designing new ones. An operation that is not in the contract does not ship, so
  until it exists `/story-done` cannot check contract drift.
- **Change records** — `docs/api/changes/api-change-*.md` absent while a contract
  exists: LOW (the next change writes the first record).

### 2e: Data Model and Migration Audit

Runs when the product has a backend (known or unknown).

- `docs/data/data-model.md` absent with a data layer or migrations present — HIGH at
  `standard`/`full`: `/data-model`.
- **Migrations versus plans** — list the migration files under the `data=` root of
  the `code_roots` line and the plans in `docs/data/migrations/NNNN-<slug>.md`. A
  file maps to a plan through its `-- Plan:` header comment or the plan's
  `**Migration Files**` line. Migrations already applied to production before
  adoption need no retroactive plan — ask the user where that history ends, and
  count only the files after it. Pending files with no plan are MEDIUM
  (`/data-model migration <slug>`); the destructive-operation scan belongs to
  `/data-model review`, which the plan schedules rather than re-implements.
- **Migrations directory undeclared** — migration directories exist
  (`**/migrations/`, `prisma/migrations/`, `db/migrate/`, `alembic/versions/`) but
  the `code_roots` line shows no `data=` root: HIGH, `/setup-stack` sets
  `stack.layers.data.migrations_dir` (the push reminder, `/data-model` and the
  migration evidence floor of `/story-done` all read it).

### 2f: Story Format Audit

For each story file found:

- **`> **Status**:`** — present and one of `Ready`, `In Progress`, `In Review`,
  `Complete`, `Blocked`? (HIGH — sprint tracking and `/story-done` read it)
- **`> **Type**:`** — one of `Logic`, `Integration`, `UI`, `E2E`, `Config`? (MEDIUM —
  it decides the required test evidence)
- **`> **Surface**:`** — present? (MEDIUM — `/dev-story` routes the engineer and the
  code root from it)
- **`> **Manifest Version**:`** — present in story header? (LOW — auto-passes if absent)
- **TR-ID reference** — does the story contain a `TR-[a-z0-9-]+-[0-9]+` ID? (MEDIUM — no staleness tracking)
- **ADR reference** — does the story reference at least one ADR (`ADR-[0-9]{4}`)?
- **`**API Contract**`, `**Migration**`, `**Feature Flag**`** — present (a value or
  `None`)? (LOW — the readiness check asks for them)
- **Acceptance criteria** — does the story have a checkbox list (`- [ ]`)?

If `production/sprint-status.yaml` exists, every `status:` value must be one of
`backlog`, `ready-for-dev`, `in-progress`, `review`, `done`, `blocked`. Any other
value — a variant spelling or casing included — is HIGH: `/help`, `/sprint-status`
and the Build step check match these words exactly.

### 2g: Tests & CI Audit

- **CI workflow** — none of the catalog `architecture.test-setup` files exist: HIGH
  at `standard`/`full` (the Architecture → Validation gate requires it), fixed by
  `/test-setup`.
- **Test runners per configured layer** — for each resolved root, is there a runner
  config (`vitest.config.*`, `jest.config.*`, `playwright.config.*`, `pytest.ini` or
  a `[tool.pytest` section, JUnit/XCTest targets) and at least one test? Presence
  only; absent for a layer with code is MEDIUM.
- **Commands and patterns** — `testing.patterns`, `commands.test`, `commands.e2e`,
  `commands.lint`, `commands.typecheck` unset in `project.yaml`: MEDIUM each —
  `/smoke-check`, `/story-done` and the CI workflow reuse them (`/test-setup` or
  `/settings` records them).
- **Contract and E2E coverage** — a contract exists but no contract tests
  (`tests/contract/` or the `testing.patterns` equivalent): MEDIUM. `docs/ops/slo.md`
  names critical user journeys with no E2E test: MEDIUM.

### 2h: SLO and Runbook Audit

- **`docs/ops/slo.md`** — absent, or without `## Critical User Journeys`: HIGH at
  `standard`/`full` (the Architecture → Validation gate requires the journeys),
  written by `/create-architecture` with the SRE consult.
- **Runbooks** — every paging alert named under `## Dashboards & Alerts` in
  `docs/ops/slo.md` needs `docs/ops/runbooks/<alert-slug>.md`. Missing ones are
  MEDIUM, and HIGH once the stage is `Hardening` or later (the launch gate requires
  a runbook for every paging alert). Runbooks kept elsewhere (a wiki, `runbooks/`,
  `ops/`) are relocation or link candidates — ask which is the source of truth.
  Fix: `/incident runbook <alert-slug>`.
- **Runbook shape** — runbooks in `docs/ops/runbooks/` missing any of `## Alert`,
  `## Impact`, `## Diagnosis`, `## Mitigation`, `## Escalation`, `## Verification`,
  `## Related`: LOW per runbook.

### 2i: Infrastructure and Configuration Audit

| Artifact | Path / source | Impact if missing |
|---|---|---|
| Code roots | `code_roots` line resolves the directories that hold code | **BLOCKING** when code exists but nothing resolves — `/dev-story` writes no code and every code scan prints NOT CHECKED; MEDIUM for `undeclared=` roots |
| Stack configured | `stack` line (not `stack: unset`) | HIGH — specialist routing, ADR stack checks and every backend condition are blind |
| Stack pinned | `stack` line without `pinned_on=unset`, and `docs/stack-reference/VERSION.md` with a Pinned Components row per configured component | HIGH — version-risk checks in ADRs and the Architecture → Validation gate cannot run |
| Surfaces | `platform.surfaces` set | MEDIUM — every UI/API condition in the catalog and the gates reads "unknown" |
| TR registry | `docs/architecture/tr-registry.yaml` | HIGH — no stable requirement IDs |
| Control manifest | `docs/architecture/control-manifest.md` | HIGH at `full`, MEDIUM otherwise — no layer rules for stories |
| Manifest version stamp | In manifest header: `Manifest Version:` | MEDIUM — staleness checks blind |
| Tech radar | `docs/architecture/tech-radar.md` | MEDIUM — Hold and forbidden patterns are not enforced in code review |
| Sprint status | `production/sprint-status.yaml` | MEDIUM — `/sprint-status` falls back to markdown |
| Project stage | `project.stage` in `project.yaml` | MEDIUM — the stage is re-estimated on every run instead of recorded |
| Architecture traceability | `docs/architecture/requirements-traceability.md` | MEDIUM — no persistent matrix |
| Naming conventions | `naming.*` in `project.yaml` | MEDIUM — API paths, fields, tables and events drift |
| Performance budgets | `performance.*` in `project.yaml` | MEDIUM — perf and load checks have nothing to measure against |

---

## Phase 3: Classify and Prioritise Gaps

Organise every gap found across all audits into four severity tiers:

**BLOCKING** — Will cause framework skills to silently produce wrong results *right now*.
Examples: ADR missing `## Status`, feature-map parenthetical or unrecognised status
values, code present but no code root resolved.

**HIGH** — Will cause stories to be generated with missing safety checks, or
infrastructure bootstrapping will fail.
Examples: ADRs missing `## Stack Compatibility`, PRDs missing `## Acceptance Criteria`
(stories can't be generated from them), a backend with no API contract in
`docs/api/`, the stack not pinned, `tr-registry.yaml` missing.

**MEDIUM** — Degrades quality and pipeline tracking but does not break functionality.
Examples: PRDs missing `## Business Rules & Calculations` for a feature with prices or
limits, stories missing TR-IDs, pending migrations without a plan,
`sprint-status.yaml` missing.

**LOW** — Retroactive improvements that are nice-to-have but not urgent.
Examples: Stories missing Manifest Version stamps, ADRs missing
`## Performance & SLO Implications`, runbooks missing `## Related`.

Count totals per tier. If zero BLOCKING and zero HIGH gaps **and no in-scope audit
is `NOT CHECKED`**: report that the product is framework-compatible and only advisory
improvements remain. If zero BLOCKING and zero HIGH gaps but an audit is
`NOT CHECKED`, the run has not established compatibility: report
`Verdict: **NOT ASSESSED** — <audits> did not run; framework compatibility unknown`
instead — never "framework-compatible". BLOCKING and HIGH gaps outrank it: a run with
them reports its gap counts, not NOT ASSESSED. `NOT CHECKED` audits are always listed
next to the counts.

---

## Phase 4: Build the Adoption Plan

Compose a numbered, ordered action plan. Ordering rules:
1. BLOCKING gaps first (must fix before any pipeline skill runs reliably)
2. HIGH gaps next, configuration and infrastructure before PRD/ADR content
   (bootstrapping needs correct formats and resolved code roots)
3. MEDIUM gaps ordered: PRD gaps before ADR gaps before API/data gaps before story
   gaps (stories depend on PRDs, ADRs and the contract)
4. LOW gaps last

For each gap, produce a plan entry with:
- A clear problem statement (one sentence, no jargon)
- The exact command to fix it, if a skill handles it
- Manual steps if it requires direct editing
- A time estimate (rough: 5 min / 30 min / 1 session)
- A checkbox `- [ ]` for tracking

**Special case — feature-map status values:**
This is always the first item if present. Show the exact values that need changing
and the exact replacement text. Offer to fix this immediately after writing the plan
(Phase 7).

**Special case — ADRs missing Status field:**
For each affected ADR, the fix is:
`/architecture-decision retrofit docs/architecture/adr-NNNN-<slug>.md`
List each ADR as a separate checkable item.

**Special case — PRDs missing sections:**
For each affected PRD, list which sections are missing and the fix:
`/write-prd design/prd/<feature>.md` — it fills only the missing sections and never
overwrites existing content. A PRD candidate outside `design/prd/` is moved first;
code with no PRD at all is `/reverse-document prd <root>/<module>`.

**Special case — contract, data and ops gaps:**
`/api-design new` (no contract) or `/api-design review` (lint an existing one);
`/data-model` (no model), `/data-model migration <slug>` (a pending change without a
plan), `/data-model review` (destructive-operation scan); `/test-setup` (CI and
runners); `/create-architecture` (SLO doc); `/incident runbook <alert-slug>` (one per
missing runbook).

**Infrastructure bootstrap ordering** — always present in this sequence:
1. Run `/setup-stack` → configures and pins the stack and declares the code roots
   (everything after this reads them)
2. Fix ADR formats (the registry depends on reading ADR Status fields)
3. Run `/architecture-review` → bootstraps `tr-registry.yaml` and the traceability matrix
4. Run `/create-control-manifest` → creates the manifest with its version stamp
5. Run `/sprint-plan update` (or `/sprint-plan new` when no sprint plan exists) →
   creates `sprint-status.yaml`
6. Run `/gate-check <target-phase>` → on PASS and your explicit confirmation, it
   records `project.stage` in `project.yaml`. The argument is the **target** phase:
   the phase the tree already looks like (`ESTIMATE` from Phase 1, lowercased — e.g.
   `/gate-check build`), so the gate into it verifies the product really meets it.
   An estimate of `Discovery` has no gate into it — leave `project.stage` unset (the
   estimator reports Discovery) or let `/start` record it.

**Existing stories** — note explicitly:
> "Existing stories continue to work with all framework skills — the newer format
> checks auto-pass when the fields are absent. They won't benefit from TR-ID
> staleness tracking, contract drift checks or manifest version checks until they're
> regenerated. This is intentional: do not regenerate stories that are already in
> progress."

---

## Phase 5: Present Summary and Ask to Write

Present a compact summary before writing:

```
## Adoption Audit Summary
Stage: [STAGE] ([SOURCE]; estimate [ESTIMATE])
Stack: [pinned YYYY-MM-DD / configured, NOT PINNED / NOT CONFIGURED]
Code roots: [resolved list / NOT RESOLVED] [+ undeclared: …]
PRDs audited: [N] ([X] compliant, [Y] with gaps, [Z] candidates outside design/prd/)
ADRs audited: [N] ([X] compliant, [Y] with gaps)
API contract: [location, lint result / missing / N/A — no backend / condition unknown]
Migrations: [N] files, [M] plans ([K] pending without a plan)
Stories audited: [N]
Tests & CI: [CI file / missing] · runbooks [N of M paging alerts]
Not checked: [list, or "none"]
Compatibility: [framework-compatible | NOT ASSESSED — <audits> did not run | BLOCKING/HIGH gaps remain]

Gap counts:
  BLOCKING: [N] — framework skills will malfunction without these fixes
  HIGH:     [N] — unsafe to run /create-stories or /story-readiness
  MEDIUM:   [N] — quality degradation
  LOW:      [N] — optional improvements

Estimated remediation: [X blocking items × ~Y min each = roughly Z hours]
```

Before asking to write, show a **Gap Preview**:
- List every BLOCKING gap as a one-line bullet describing the actual problem
  (e.g. `feature-map.md: 3 rows have parenthetical status values`,
  `adr-0002-primary-datastore.md: missing ## Status section`). No counts — show the
  actual items.
- Show HIGH / MEDIUM / LOW as counts only (e.g. `HIGH: 4, MEDIUM: 2, LOW: 1`).

This gives the user enough context to judge scope before committing to writing the file.

If a prior adoption plan was detected in Phase 1, add a note:
> "A previous plan exists at `docs/adoption-plan-[prior-date].md`. The new plan will
> reflect current project state — it does not diff against the prior run."

Use `AskUserQuestion`:
- "May I write this to `docs/adoption-plan-YYYY-MM-DD.md`?"
  - "Yes — write `docs/adoption-plan-YYYY-MM-DD.md`"
  - "Show me the full plan preview first (don't write yet)"
  - "Cancel — I'll handle adoption manually"

If the user picks "Show me the full plan preview", output the complete plan as a
fenced markdown block. Then ask again with the same three options.

---

## Phase 6: Write the Adoption Plan

If approved, write `docs/adoption-plan-YYYY-MM-DD.md` with this structure (headings
and bold labels in English exactly as below; body text in the user's conversation
language):

```markdown
# Adoption Plan

> **Generated**: [date]
> **Project stage**: [STAGE] ([SOURCE]; estimate [ESTIMATE] — [EVIDENCE])
> **Stack**: [stack line summary, or "Not configured — run /setup-stack"]
> **Workflow tier**: [workflow]
> **Framework version**: [framework.version from project.yaml, or "not recorded"]
> **Audit focus**: [full | prds | adrs | api | data | stories | infra]

Work through these steps in order. Check off each item as you complete it.
Re-run `/adopt` anytime to check remaining gaps.

---

## Step 1: Fix Blocking Gaps

[One sub-section per blocking gap with problem, fix command, time estimate, checkbox]

---

## Step 2: Fix High-Priority Gaps

[One sub-section per high gap]

---

## Step 3: Bootstrap Infrastructure

### 3a. Configure and pin the stack, declare code roots
Run `/setup-stack`
**Time**: 1 session
- [ ] `stack.pinned_on` set; every code root declared under `stack.layers.<layer>.root`

### 3b. Register existing requirements (creates tr-registry.yaml)
Run `/architecture-review` — even if ADRs already exist, this run bootstraps
the TR registry from your existing PRDs and ADRs.
**Time**: 1 session (review can be long for large codebases)
- [ ] docs/architecture/tr-registry.yaml created

### 3c. Create control manifest
Run `/create-control-manifest`
**Time**: 30 min
- [ ] docs/architecture/control-manifest.md created

### 3d. Create sprint tracking file
Run `/sprint-plan update` (or `/sprint-plan new`)
**Time**: 5 min (if a sprint plan already exists as markdown)
- [ ] production/sprint-status.yaml created

### 3e. Record the project stage
Run `/gate-check [target-phase]` — the phase the tree looks like
**Time**: 5 min
- [ ] `project.stage` in `project.yaml` written by the gate (PASS + your confirmation)

---

## Step 4: Medium-Priority Gaps

[One sub-section per medium gap]

---

## Step 5: Optional Improvements

[One sub-section per low gap]

---

## Not Checked

[Every audit that could not run, with its reason and what would let it run — or "None"]

---

## What to Expect from Existing Stories

Existing stories continue to work with all framework skills. Newer format checks
(TR-ID validation, contract drift, manifest version staleness) auto-pass when the
fields are absent — so nothing breaks. They won't benefit from staleness tracking
until regenerated. Do not regenerate stories that are in progress or done.

---

## Re-run

Run `/adopt` again after completing Step 3 to verify all blocking and high gaps
are resolved. The new run will reflect the current state of the project.
```

---

## Phase 7: Offer First Action

After writing the plan, don't stop there. Pick the single highest-priority gap
and offer to handle it immediately using `AskUserQuestion`. Choose the first
branch that applies:

**If feature-map Status cells are parenthetical or unrecognised:**
Use `AskUserQuestion`:
- "The most urgent fix is `design/product/feature-map.md` — [N] rows have status
  values (e.g. `Needs Revision (see notes)`) that break /gate-check,
  /create-stories and /architecture-review right now. I can fix these in place."
  - "Fix it now — correct the Status cells in feature-map.md"
  - "I'll fix it myself"
  - "Done — leave me with the plan"

If the user picks the fix: read the whole file, change **only** the Status cells,
show every changed row before and after, then ask
"May I write this to `design/product/feature-map.md`?" and write the full file only
on yes. Nothing else in the file changes.

**If ADRs are missing `## Status` (and no feature-map issue):**
Use `AskUserQuestion`:
- "The most urgent fix is adding `## Status` to [N] ADR(s): [list filenames].
  Without it, /story-readiness silently passes all ADR checks. Start with
  [first affected filename]?"
  - "Yes — retrofit [first affected filename] now (`/architecture-decision retrofit docs/architecture/[first affected filename]`)"
  - "Retrofit all [N] ADRs one by one"
  - "I'll handle ADRs myself"

**If code exists but no code root resolves (and no blocking issue above):**
Use `AskUserQuestion`:
- "The most urgent gap is that no code root is declared, so `/dev-story` will not
  write code and every code scan reports NOT CHECKED. Run `/setup-stack` to declare
  [the directories found, e.g. apps/web, apps/api]?"
  - "Yes — run /setup-stack next"
  - "I'll declare them myself"

**If PRDs are missing Acceptance Criteria (and no blocking issues above):**
Use `AskUserQuestion`:
- "The most urgent gap is missing Acceptance Criteria in [N] PRD(s):
  [list filenames]. Without them, /create-stories can't generate stories.
  Start with [highest-priority PRD filename]?"
  - "Yes — fill [PRD filename] now (`/write-prd design/prd/<feature>.md`)"
  - "Do all [N] PRDs one by one"
  - "I'll handle PRDs myself"

**If no BLOCKING or HIGH gaps exist:**
Use `AskUserQuestion` (when Phase 3 reported `NOT ASSESSED`, the first sentence reads
"No blocking gaps found, but [audits] did not run — framework compatibility is NOT
ASSESSED." instead):
- "No blocking gaps — this product is framework-compatible. What next?"
  - "Walk me through the medium-priority improvements"
  - "Run /project-stage-detect for a broader health check"
  - "Run /gate-check [target-phase] to record the stage"
  - "Done — I'll work through the plan at my own pace"

> **Adoption plan saved to `docs/adoption-plan-YYYY-MM-DD.md`.** Re-run `/adopt` at any time to re-check remaining gaps as you complete them.

---

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and
`autonomous` modes, see `.claude/docs/automation-modes.md` — the rules below
describe what collaborative mode requires, not universal behavior.

1. **Read silently** — complete the full audit before presenting anything
2. **Show the summary first** — let the user see scope before asking to write
3. **Ask before writing** — "May I write this to `<path>`?" before creating the
   adoption plan and before any in-place fix
4. **Offer, don't force** — the plan is advisory; the user decides what to fix and when
5. **One action at a time** — after handing off the plan, offer one specific next step,
   not a list of six things to do simultaneously
6. **Never regenerate existing artifacts** — only fill gaps in what exists;
   do not rewrite PRDs, ADRs, contracts or stories that already have content
7. **Never change configuration** — stage, review mode and stack settings are set
   by `/gate-check`, `/settings` and `/setup-stack`, not by this audit
