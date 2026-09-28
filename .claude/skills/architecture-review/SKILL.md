---
name: architecture-review
description: "Traceability matrix PRD requirements to ADRs; cross-ADR conflicts; stack compatibility. PASS/CONCERNS/NOT ASSESSED/FAIL."
argument-hint: "[focus: full | coverage | consistency | stack | rtm | single-prd design/prd/<feature>.md]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Write, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/architecture-review/../../hooks/yaml-helper.sh" resolve_config *)
model: opus
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow,stack,surfaces,compliance`

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).


# Architecture Review

The architecture review validates that the complete body of architectural decisions
covers every product requirement, is internally consistent, and correctly targets
the component versions the project has pinned. It is the quality gate between
Architecture and Validation.

**Argument modes:**
- **No argument / `full`**: Full review — all phases
- **`coverage`**: Traceability only — which PRD requirements have no ADR
- **`consistency`**: Cross-ADR conflict detection only
- **`stack`**: Stack compatibility audit only
- **`single-prd [path]`**: Review architecture coverage for one specific PRD
- **`rtm`**: Requirements Traceability Matrix — extends the standard matrix
  to include story file paths and test file paths; outputs
  `docs/architecture/requirements-traceability.md` with the full
  PRD requirement → ADR → Story → Test chain. Use in the Build phase when
  stories and tests exist.

This skill spawns **no director gate**. The routed stack leads it consults in
Phase 5 are consultants: they return findings, not a gate verdict, and the
review's verdict stays this skill's own.

---

**`workflow`** (see `.claude/docs/workflow-modes.md`):
- `full` — full traceability matrix across every MVP PRD and every ADR.
- `standard` — reduced scope: architecture doc + critical (Foundation-layer) ADRs
  only; the full traceability index is recommended, not required.
- `minimal` — not applicable (no architecture doc required). Say so before doing
  anything else, and run only if the user asks for a review anyway.

## Phase 1: Load Everything

### Phase 1a — L0: Summary Scan (fast, low tokens)

**Freshness check before any scan.** Locate the latest prior report — Glob
`docs/architecture/architecture-review-*.md` and take the newest — then:

```
Bash: bash .claude/scripts/review-receipts.sh check "[latest-report]" docs/architecture/adr-*.md design/prd/*.md
```

- **Any `UNRESOLVED`** — check this FIRST; it disqualifies every option
  below. One of the two globs matched no file, so that whole document class
  was never examined and the comparison covered less than it appears to.
  Say which pattern came back unresolved and stop: an ADR or PRD directory
  that is empty, renamed or misspelled is a finding about the project, not a
  reason to stand on a prior report. Never read a set of `UNCHANGED` lines as
  "everything is current" while an `UNRESOLVED` line is present — the set
  compared was not the set requested.
- **Everything `UNCHANGED`** (and no `UNRESOLVED`) — nothing this review
  reads has changed since that report; re-running reproduces it. Surface the
  prior report's date and verdict and offer via `AskUserQuestion`: `[A] Stand
  on the prior report (Recommended)` / `[B] Re-run the full review anyway` —
  `guided` proceeds with [A] and notes it; `autonomous` logs via
  `log_decision` and stands on the prior report.
- **Some `CHANGED`/`NEW`** — name them, then scope instead of re-running
  everything: recommend `/architecture-review single-prd design/prd/<feature>.md`
  (single-PRD mode) for just the changed features. A full re-run stays available
  on request, and structural changes (a `NEW` ADR, a deleted file) warrant one.
- **`RECEIPT: NONE`** — no prior report, or one written before receipts
  existed. Proceed with the full review; this run's report will carry the
  first stamps.

Before reading any full document, use Grep to extract `## Summary` sections
from all PRDs and ADRs:

```
Grep pattern="## Summary" glob="design/prd/*.md" output_mode="content" -A 4
Grep pattern="## Summary" glob="docs/architecture/adr-*.md" output_mode="content" -A 3
```

**Fail open on a missing Summary.** Establish the denominator: glob
`design/prd/*.md` and count **N**. A scan matching fewer than N means those PRDs
predate `## Summary` (`/write-prd` emits it, but older PRDs lack it) — never
treat an absent Summary as a feature out of scope. A zero-match scan means "no PRD
carries a Summary yet", not "nothing to review": full-read the unmatched set.

For `single-prd [path]` mode: use the target PRD's summary to identify which
ADRs reference the same feature (Grep ADRs for the feature slug and the PRD path),
then load only those ADRs' sections per Phase 1b. Skip unrelated PRDs entirely.

For `stack` mode: load ADR sections only — PRDs are not needed for stack checks.
In practice this is the `## Stack Compatibility` scan alone.

For `coverage` or `full` mode: proceed to Phase 1b for the full in-scope set.
**This is a section load, not a full-file load** — see below for why, and for the
narrow cases that still justify escalating to a whole document.

### Phase 1b — L1/L2: Targeted Section Load

Load the sections the later phases actually consume — **not whole files**. This
skill reads the two largest document sets in the project (every PRD *and* every
ADR); at realistic sizes a full load of both exhausts the context window before
Phase 2 starts, and most of what it loads is narrative this skill never uses.

**Establish the denominator first.** Glob `design/prd/*.md` and count **N_prd**;
glob `docs/architecture/adr-*.md` and count **N_adr**. Report both. A section
scan matching fewer than the denominator means those documents lack the section —
**never treat an absent section as an absent document.** The scan narrows the
*read* set; it never shrinks the *in-scope* set.

### Design Documents

Phase 2 extracts *technical requirements* — data and ownership, latency and
availability targets, security and privacy rules, cross-feature communication,
persistence and consistency, third-party integrations, client and surface needs.
Those live in a known set of PRD sections; Overview, Goals & Non-Goals and User
Value are product framing and yield none.

```
Grep pattern="^## (Functional Requirements|Business Rules & Calculations|Dependencies|Non-Functional Requirements|Configuration & Flags|API & Data Impact|Acceptance Criteria)" glob="design/prd/*.md" output_mode="content" -A 40
```

Headings are matched exactly as `.claude/docs/templates/prd.md` spells them.
`## API & Data Impact` is a non-contract section — absent in many PRDs, and its
absence is not a finding. Full-read a single PRD only when a scanned section
cross-references material outside itself, or when a PRD matched zero sections
(it predates the template — read it whole and say so).

- `design/product/feature-map.md` — the authoritative list of features (its
  `| Feature | Category | Layer | Tier | Status | PRD | Depends On |` table); read
  whole (small, and it is an index)

### Architecture Documents

Phases 3–5 need the traceability table, the decision itself, stack claims,
the dependency edges, the SLO budget and the security stance — not Context,
Consequences, Alternatives, Migration Plan or Validation Criteria, which explain
*why* a decision was made.

```
Grep pattern="^## (Status|Decision|PRD Requirements Addressed|Stack Compatibility|ADR Dependencies|Performance & SLO Implications|Security & Privacy Implications)" glob="docs/architecture/adr-*.md" output_mode="content" -A 30
```

Interpret against **N_adr**, and distinguish the two zero-match cases — they are
not the same finding:

| Result | Meaning | Action |
|---|---|---|
| N_adr matches | Normal. | Proceed on the scanned sections. |
| Some ADRs match, some do not | Those ADRs are missing sections. | Record each as a **structural gap** in the Phase 7 report — a missing `## PRD Requirements Addressed` is itself a traceability finding. |
| **0 matches, N_adr > 0** | **Malformed ADRs**, not "no architecture". | "[N_adr] ADRs found, none carries a scannable section — run `/architecture-decision retrofit [file]` on each." Do **not** report zero coverage; that would read as a design failure when it is a format failure. |

Escalate to a full read of one ADR only when judging a conflict needs its
reasoning (Phase 4) — that is a per-ADR decision, not a blanket load.

- `docs/architecture/architecture.md` if it exists
- `docs/ops/slo.md` if it exists — the journey SLOs Phase 4 checks budget
  allocations against
- `docs/registry/architecture.yaml` if it exists — the registered stances
  (`data_ownership`, `interfaces`, `slo_budgets`, `technology_decisions`,
  `forbidden_patterns`) Phase 4 uses as its conflict baseline

### Stack Reference
- `docs/stack-reference/VERSION.md` — the Pinned Components table (component,
  version, Knowledge Risk)
- For each component the in-scope ADRs name in `**Stack Components**`:
  `docs/stack-reference/<component-slug>/VERSION.md`, and — for Knowledge Risk
  MEDIUM/HIGH components — `breaking-changes.md` and `deprecated-apis.md` in the
  same folder
- **Only the module docs the in-scope ADRs actually name** — take the union of
  each ADR's `**References Consulted**` and `**Post-Cutoff APIs Used**` rows
  (already captured by the `## Stack Compatibility` scan above) and read those
  files. Reading every `modules/` folder loads subsystems the project may not
  use at all. If no ADR names any module, read none and note it: Phase 5
  cannot cross-check stack claims that were never made.

### Project Standards
- `project.yaml` — `naming.*` and `performance.*` (read with Read; these keys have
  no `resolve_config` label)
- `docs/architecture/tech-radar.md` — adopted libraries (`## Adopt`) and what the
  project must not use (`## Hold`, `## Forbidden Patterns`)

Report a count: "Loaded [N] PRDs, [M] ADRs, stack: [the resolved `stack` line]."

**Also read `docs/consistency-failures.md`** if it exists. Extract entries with
Domain matching the features under review (Architecture, Stack, or any PRD domain
being covered). Surface recurring patterns as a "Known conflict-prone areas" note
at the top of the Phase 4 conflict detection output.

---

## Phase 2: Extract Technical Requirements from Every PRD

### Pre-load the TR Registry

Before extracting any requirements, read `docs/architecture/tr-registry.yaml`
if it exists. Index existing entries by `id` and by normalized `requirement`
text (lowercase, trimmed). This prevents ID renumbering across review runs.
This skill is the registry's **only writer**; every other skill reads it.

For each requirement you extract, the matching rule is:
1. **Exact/near match** to an existing registry entry for the same feature →
   reuse that entry's TR-ID unchanged. Update the `requirement` text in the
   registry only if the PRD wording changed (same intent, clearer phrasing) —
   add a `revised: [date]` field.
2. **No match** → assign a new ID: next available `TR-[feature]-NNN` for that
   feature, starting from the highest existing sequence + 1. The feature slug is
   the PRD stem (`design/prd/goals.md` → `TR-goals-NNN`).
3. **Ambiguous** (partial match, intent unclear) → ask the user:
   > "Does '[new requirement text]' refer to the same requirement as
   > `TR-[feature]-NNN: [existing text]'`, or is it a new requirement?"
   User answers: "Same requirement" (reuse ID) or "New requirement" (new ID).

For any requirement with `status: deprecated` in the registry — skip it.
It was removed from the PRD intentionally.

For each PRD, read it and extract all **technical requirements** — things the
architecture must provide for the feature to work. A technical requirement is any
statement that implies a specific architectural decision. Requirements from
`## Functional Requirements` and `## Business Rules & Calculations` are
`type: functional`; requirements from `## Non-Functional Requirements` are
`type: nfr` with an `nfr_category` (`performance`, `availability`, `security`,
`privacy`, `accessibility`, `localization`).

Categories to extract:

| Category | Example |
|----------|---------|
| **Data & ownership** | "A savings goal has a target amount, a due date and a running balance; only its owner can see it" → data model + ownership ADR |
| **Performance & SLO** | "The goal list loads with p95 < 300 ms at 1,000 requests/s" → caching / query-path ADR |
| **Availability & reliability** | "Auto-debit runs on schedule even if the app is closed; a failed charge retries within 72 hours" → background jobs & retry ADR |
| **Security & privacy** | "Only the goal owner can read deposits; bank account numbers are masked to the last 4 digits" → authorization + data classification ADR |
| **Cross-feature communication** | "Reaching a goal sends a push and a 알림톡" → event / queue ADR (publisher and consumers) |
| **Consistency & state** | "A deposit is applied exactly once even when Toss Payments retries its webhook" → idempotency ADR |
| **Third-party integration** | "Auto-debit charges a Toss Payments billing key" → payments integration ADR |
| **Client & surface requirements** | "Goals work on web, iOS and Android; the mobile app shows the last synced goals offline" → API style / client sync ADR |
| **Configuration & flags** | "The new progress ring ships behind `goals.v2-progress-ring` at a percentage rollout" → feature-flag ADR |

For each PRD, produce a structured list:

```
PRD: design/prd/[feature].md
Feature: [feature name]
Technical Requirements:
  TR-[feature]-001: [requirement text] → Type: functional · Domain: [API/Data/Auth/etc]
  TR-[feature]-002: [requirement text] → Type: nfr (performance) · Domain: [...]
```

`Domain` uses the ADR `**Domain**` vocabulary — `API | Data | Auth | Security |
Frontend | Mobile | Infra | Messaging | Observability | Integrations | ML` — so a
gap can be matched to the ADR that should close it.

This becomes the **requirements baseline** — the complete set of what the
architecture must cover.

---

## Phase 3: Build the Traceability Matrix

For each technical requirement extracted in Phase 2, search the ADRs:

1. Use the ADRs **already loaded in Phase 1b** — do not re-read them. Extract each
   ADR's `## PRD Requirements Addressed` table (`| PRD | Requirement (TR-ID) | How addressed |`)
   from what is already in context. (If Phase 1b ran in a mode that did not load
   every ADR, `Grep pattern="## PRD Requirements Addressed" glob="docs/architecture/adr-*.md" output_mode="content" -A 15`
   fills the gap without a full re-read.)
2. Check if it explicitly references the requirement (its TR-ID) or its PRD
3. Check if the ADR's decision text implicitly covers the requirement
4. Mark coverage status:

| Status | Meaning |
|--------|---------|
| ✅ **Covered** | An **Accepted** ADR explicitly addresses this requirement |
| 🟡 **Covered (Proposed)** | An ADR addresses it, but that ADR is still `Proposed` |
| ⚠️ **Partial** | An ADR partially covers this, or coverage is ambiguous |
| ❌ **Gap** | No ADR addresses this requirement |
| ❓ **Not assessed** | The ADR is unreadable, or has no `## Status` section |

> **Read each ADR's `## Status` before marking coverage — an unaccepted decision
> is not coverage.** If `✅` meant only that *an ADR addresses this*, with no
> status qualification, a requirement covered entirely by `Proposed` ADRs would
> count as covered and this review could return **PASS: All requirements
> covered** over an architecture nobody had accepted. Four skills downstream
> (`create-control-manifest`, `create-epics`, `create-stories`, `gate-check`)
> require `Accepted`, so a PASS on that basis sends work forward that every one
> of them will refuse.
>
> `🟡` is **not** a pass state: it caps the verdict at **CONCERNS**, and names the
> route out — `/architecture-decision accept ADR-NNNN`. That route is the only
> thing that moves an ADR to `Accepted`; without it, grading `Proposed` as
> covered would be the only option, which is why it must never be graded so.

Foundational ADRs (identity & auth, primary data store, API style, deployment
topology, observability) often answer no single PRD requirement; their
`## PRD Requirements Addressed` reads "Foundational — no PRD requirement.
Enables: …". That is not a gap in the ADR — trace the requirements they enable
through the `Enables` list instead.

Build the full matrix:

```
## Traceability Matrix

| Requirement ID | PRD | Feature | Type | Requirement | ADR Coverage | Status |
|---------------|-----|---------|------|-------------|--------------|--------|
| TR-goals-001 | goals.md | Goals | functional | Only the goal owner can read or change a goal | ADR-0001 | ✅ |
| TR-goals-002 | goals.md | Goals | nfr (performance) | Goal list p95 < 300 ms | — | ❌ GAP |
| TR-payments-001 | payments.md | Payments | functional | Deposit applied exactly once per Toss Payments webhook | ADR-0004 | 🟡 |
```

Count the totals: X covered, P covered-but-Proposed, Y partial, Z gaps.

---

## Phase 3b: Story and Test Linkage (RTM mode only)

*Skip this phase unless the argument is `rtm` or `full` with stories present.*

This phase extends the Phase 3 matrix to include the story that implements
each requirement and the test that verifies it — producing the full
Requirements Traceability Matrix (RTM).

### Step 3b-1 — Load stories

Glob `production/epics/*/story-*.md` to establish the denominator (EPIC.md
files never match). Then collect the fields with **targeted section greps, not a
full read of each story** — the same two-grep form `/test-evidence-review` uses
for this identical extraction:

```
Grep pattern="## Test Evidence" glob="production/epics/*/story-*.md" output_mode="content" -A 8
Grep pattern="TR-" glob="production/epics/*/story-*.md" output_mode="content"
```

- **TR-ID** — from the second grep (the story's `**Requirement**:` field).
- **Test file path** — under `## Test Evidence`, captured by the first grep's `-A 8`.
- **Status and Type** — from the story header; add
  `Grep pattern="^> \*\*(Status|Type)\*\*"` if not already captured.
- **Story path and title** — from the file name and path; no read at all.

Full-read a story only when its Test Evidence section is missing or ambiguous.

### Step 3b-2 — Load test files

Read `testing.patterns` from `project.yaml` (a flow list of globs, e.g.
`[apps/*/src/**/*.test.ts, tests/**]`; it has no `resolve_config` label). Glob
those patterns. When the key is unset, use the `tests/**` convention —
`tests/unit/`, `tests/integration/`, `tests/contract/`, `tests/e2e/` — and say
so in the report: `testing.patterns unset — tests/** convention used`.
Build an index: feature → [test file paths].

For each test file path from Step 3b-1, confirm via Glob whether the file
actually exists. Note MISSING if the stated path does not exist.

### Step 3b-3 — Build the extended RTM

For each TR-ID in the Phase 3 matrix, add:
- **Story**: the story file path(s) that reference this TR-ID (may be multiple)
- **Test File**: the test file path stated in the story's Test Evidence section
- **Test Status**: COVERED (test file exists) / MISSING (path stated but not
  found) / NONE (no test path stated — expected only for a `UI` story evidenced
  by screenshots or a `Config` story evidenced by the smoke check; for a
  `Logic`, `Integration` or `E2E` story say so in the row) / NO STORY
  (requirement has no story yet — expected until `/create-stories` runs)

Story Types map 1:1 to the `testing.strict` keys `logic`, `integration`, `ui`,
`e2e` and `config` (evidence rules in `.claude/docs/coding-standards.md`).

Extended matrix format:

```
## Requirements Traceability Matrix (RTM)

| TR-ID | PRD | Requirement | ADR | Story | Test File | Test Status |
|-------|-----|-------------|-----|-------|-----------|-------------|
| TR-goals-001 | goals.md | Owner-only access | ADR-0001 | goals-core/story-001-create-goal.md | apps/api/src/goals/goals.authz.test.ts | COVERED |
| TR-goals-003 | goals.md | Progress ring states | ADR-0006 | goals-core/story-004-progress-ring.md | — | NONE (UI — screenshots) |
| TR-payments-001 | payments.md | Exactly-once deposit | ADR-0004 | — | — | NO STORY |
```

RTM coverage summary:
- COVERED: [N] — requirements with ADR + story + passing test
- MISSING test: [N] — story exists but test file not found
- NO STORY: [N] — requirements with ADR but no story yet
- NO ADR: [N] — requirements without architectural coverage (from Phase 3 gaps)
- Full chain complete (COVERED): [N/total] ([%])

---

## Phase 4: Cross-ADR Conflict Detection

Compare every ADR against every other ADR — and against every `active` entry of
`docs/registry/architecture.yaml` when it exists — to detect contradictions. A
conflict between an ADR and a registered stance is reported exactly like an
ADR-vs-ADR conflict. A conflict exists when:

- **Data ownership conflict**: Two ADRs claim to be the owner (the only writer) of
  the same entity or field — e.g. both the goals ADR and the payments ADR write
  `goal.balance`
- **Integration contract conflict**: ADR-A assumes the payments module exposes a
  synchronous `POST /v1/deposits`, but ADR-B defines deposits as asynchronous
  events with a webhook confirmation
- **SLO budget conflict**: ADR-A allocates N ms of the deposit journey's p95 to the
  Toss Payments call, ADR-B allocates M ms to fraud checks; together they exceed
  the journey SLO in `docs/ops/slo.md` (or `performance.api_p95_ms`)
- **Dependency cycle**: ADR-A says module X must be deployed (or migrated) before
  Y; ADR-B says Y before X
- **Architecture pattern conflict**: ADR-A sends notifications through a queue
  (publisher → consumer); ADR-B calls the notification provider synchronously
  from the same request path
- **Source-of-truth conflict**: Two ADRs define authority over the same state
  (e.g. both the subscription ADR and the payments ADR claim to be the source of
  truth for a user's plan entitlement)
- **Security & privacy conflict**: ADR-A keeps refresh tokens in web
  `localStorage`; ADR-B's `## Security & Privacy Implications` assumes httpOnly
  cookies — or two ADRs classify the same PII field with different retention

For each conflict found:

```
## Conflict: [ADR-NNNN] vs [ADR-MMMM]
Type: [Data ownership / Integration / SLO budget / Dependency / Pattern / Source of truth / Security & privacy]
ADR-NNNN claims: [...]
ADR-MMMM claims: [...]
Impact: [What breaks if both are implemented as written]
Resolution options:
  1. [Option A]
  2. [Option B]
```

### ADR Dependency Ordering

After conflict detection, analyse the dependency graph across all ADRs.

**Build the graph deterministically — do not trace it by hand:**

```
Bash: bash .claude/scripts/adr-dep-graph.sh
```

It collects every `Depends On` edge, runs Kahn's algorithm, and emits
`ADRS:` / `EDGES:` / `NO_DEPS_SECTION:` / `CYCLE:`. A model tracing A→B→C→A across
a dozen ADRs eventually misses an edge; the algorithm cannot. It reports
observations, not a verdict — you apply the meaning below.

**`NO_DEPS_SECTION` is load-bearing**: it makes "no cycles because the graph is
clean" distinguishable from "no cycles because half the ADRs declare no
dependencies". Report the second case as a structural gap, never as a clean graph.

Then interpret:

1. **Topological sort**: the emitted order — ADRs with no
   dependencies come first (Foundation), ADRs that depend on those come next, etc.
2. **Flag unresolved dependencies**: cross the `EDGES:` list against the `## Status`
   values already scanned in Phase 1b. If ADR-A depends on an ADR that is still
   `Proposed` or does not exist, flag it:
   ```
   ⚠️  ADR-0005 depends on ADR-0002 — but ADR-0002 is still Proposed.
       ADR-0005 cannot be safely implemented until ADR-0002 is Accepted.
   ```
3. **Cycle detection**: every `CYCLE:` line the script emitted is a
   `DEPENDENCY CYCLE` — report each one. Do not re-derive them by hand:
   ```
   🔴 DEPENDENCY CYCLE: ADR-0003 → ADR-0006 → ADR-0003
      This cycle must be broken before either can be implemented.
   ```
4. **Output recommended implementation order**:
   ```
   ### Recommended ADR Implementation Order (topologically sorted)
   Foundation (no dependencies):
     1. ADR-0001: [title]
     2. ADR-0003: [title]
   Depends on Foundation:
     3. ADR-0002: [title] (requires ADR-0001)
     4. ADR-0005: [title] (requires ADR-0003)
   Feature layer:
     5. ADR-0004: [title] (requires ADR-0002, ADR-0005)
   ```

---

## Phase 5: Stack Compatibility Cross-Check

Across all ADRs, check for stack consistency against `docs/stack-reference/`:

### Version Consistency
- Do all ADRs that name a component in `**Stack Components**` agree with each other
  and with the pinned version in `docs/stack-reference/VERSION.md`?
- If any ADR was written for an older component version, flag it as potentially stale
- A component an ADR relies on that has no Pinned Components row (or reads
  `NOT DETERMINED`) is Knowledge Risk HIGH until `/setup-stack` pins it — flag it

### Post-Cutoff API Consistency
- Collect all `**Post-Cutoff APIs Used**` rows from all ADRs
- For each, verify against the relevant `docs/stack-reference/<component-slug>/` doc
- Check that no two ADRs make contradictory assumptions about the same post-cutoff API
- A claim no stack-reference file covers is `NOT SOURCEABLE — <API> is not covered
  by docs/stack-reference/<component-slug>/` — never confirm it from memory

### Deprecated API Check
- Grep all ADRs for API names listed in each component's `deprecated-apis.md`
- Flag any ADR referencing a deprecated API
- Flag any ADR that adopts a library or pattern the tech radar lists under `## Hold`
  or `## Forbidden Patterns`

### Missing Stack Compatibility Sections
- List all ADRs that are missing the `## Stack Compatibility` section entirely
- These are blind spots — their stack assumptions are unknown

Output format:
```
### Stack Audit Results
Stack: [the resolved `stack` line]
ADRs with Stack Compatibility section: X / Y total

Deprecated API References:
  - ADR-0002: uses [deprecated API] — deprecated since [version]

Stale Version References:
  - ADR-0001: written for [component + older version] — pinned version is [version]

Post-Cutoff API Conflicts:
  - ADR-0004 and ADR-0007 both use [API] with incompatible assumptions

Tech Radar Conflicts:
  - ADR-0005: adopts [library] — listed under ## Hold in docs/architecture/tech-radar.md
```

---

### Stack Specialist Consultation

After completing the stack audit above, spawn the **routed stack leads** via
`Agent` for a domain-expert second opinion:
- Resolve the leads from the `[routing: …]` part of the resolved `stack` line:
  each entry is `<lead>` or `<lead>><sub>`; spawn the **lead** (`web-specialist`,
  `mobile-specialist`, `backend-specialist`, `data-specialist`,
  `cloud-specialist`) — it may delegate to its routed sub through its own grant.
  If a lead's reply carries `NOT CONSULTED — <sub> (nested spawn unavailable)` or
  a `<sub>: <task>` hand-off, spawn that sub yourself with the task, or carry the
  NOT CONSULTED line into the report's stack audit — never drop it.
- Spawn only the leads of layers the in-scope ADRs touch: a layer whose component
  an ADR names in `**Stack Components**`, or whose `**Domain**` maps to it
  (Frontend → web, Mobile → mobile, API / Auth / Messaging / Integrations / ML →
  backend, Data → data, Infra / Observability → cloud). Issue all `Agent` calls
  before waiting for any result.
- For each layer an ADR relies on that the `stack` line lists under `unset=`,
  record `NOT CHECKED — <layer> layer not configured (run /setup-stack)`.
- If the whole stack is unset (`stack: unset — run /setup-stack`), skip this
  consultation **and record `Stack validation: NOT ASSESSED — stack unset (run /setup-stack)`
  in this run's output.** A skipped check that says nothing is indistinguishable
  from a check that passed; the reader cannot tell stack guidance was never sought.
- Spawn each lead with: the ADRs of its layer that contain stack-specific
  decisions or `**Post-Cutoff APIs Used**` rows, the `docs/stack-reference/`
  paths for its components, and the Phase 5 audit findings. Ask them to:
  1. Confirm or challenge each audit finding — specialists may know of framework
     nuances not captured in the reference docs
  2. Identify stack-specific anti-patterns in the ADRs that the audit may have
     missed (e.g., relying on a framework's default fetch caching for per-user
     data, N+1 queries hidden behind ORM relations, request-scoped providers on a
     hot path, auth tokens in unencrypted mobile storage)
  3. Flag ADRs that make assumptions about framework or runtime behaviour that
     differ from the actual pinned version

Incorporate additional findings under `### Stack Specialist Findings` in the Phase 5 output. These feed into the final verdict — specialist-identified issues carry the same weight as audit-identified issues.

---

## Phase 5b: Design Revision Flags (Architecture → PRD Feedback)

For each **HIGH RISK stack finding** from Phase 5, and each constraint an
Accepted ADR records, check whether any PRD makes an assumption that the verified
stack reality contradicts.

Specific cases to check:

1. **Post-cutoff API behaviour differs from training-data assumptions**: If an ADR
   records a verified API behaviour that differs from the default LLM assumption,
   check all PRDs that reference the related feature. Look for functional
   requirements written around the old (assumed) behaviour.

2. **Known platform or vendor limitations in ADRs**: If an ADR records a known
   limitation (e.g. "iOS does not guarantee when a background task runs",
   "a 알림톡 message must use a template Kakao has approved"), check PRDs that
   design behaviour around the affected capability.

3. **Deprecated API conflicts**: If Phase 5 flagged a deprecated API used in an ADR,
   check whether any PRD contains requirements that assume the deprecated API's behaviour.

For each conflict found, record it in the PRD Revision Flags table:

```
### PRD Revision Flags (Architecture → Product Feedback)
These PRD assumptions conflict with verified stack behaviour or accepted ADRs.
The PRD should be revised before its feature enters implementation.

| PRD | Assumption | Reality (from ADR/stack-reference) | Action |
|-----|-----------|-------------------------------------|--------|
| goals.md | "The savings reminder fires at exactly 09:00 from a background task on the device" | iOS does not guarantee background execution — ADR-0006 schedules the reminder as a server-sent push | Revise PRD |
```

If no revision flags are found, write: "No PRD revision flags — all PRD assumptions
are consistent with verified stack behaviour."

Before asking, display the proposed change inline — show the current feature-map row for each flagged PRD and the proposed updated row side by side so the user can see exactly what will change.

Then use `AskUserQuestion`:
- "I found [N] PRD revision flag(s). May I write this to `design/product/feature-map.md`?"
  - [A] Yes — apply all [N] updates to the feature map now
  - [B] Show me the full diff first, then ask again
  - [C] No — leave the feature map unchanged for now

If [A]: apply the updates. The `Status` column value must be exactly `Needs Revision` — no parentheticals
(other skills match that exact string and parentheticals break the match). The
PRD's own `> **Status**:` line moves to `Needs Revision` when its author revises
it (`/write-prd`); this skill does not edit PRDs.
If [B]: display the complete proposed feature-map table, then re-ask with `AskUserQuestion`.

---

## Phase 6: Architecture Document Coverage

**If `docs/architecture/architecture.md` does not exist, say so in the report** —
`Architecture document coverage: NOT ASSESSED — no docs/architecture/architecture.md`
— and carry it into the Phase 7 verdict per the trigger list below. Phase 5
already models this for the stack consultation (*"A skipped check that says
nothing is indistinguishable from a check that passed"*); this phase is the one
that did not. Silently producing no Phase 6 findings reads as an architecture
document that was checked and found clean, which is the opposite of what
happened.

If it exists, validate it against PRDs:

- Does every feature from `design/product/feature-map.md` appear in the
  architecture's layers and modules?
- Does the data flow section cover all cross-feature communication defined in PRDs?
- Do the API boundaries support all integration requirements from PRDs
  (including third-party services named under `### External Services`)?
- Are there modules or services in the architecture doc that have no
  corresponding PRD (orphaned architecture)?

---

## Phase 7: Output the Review Report

```
# Architecture Review Report

> **Verdict**: [PASS | CONCERNS | NOT ASSESSED | FAIL]

Date: [date]
Stack: [the resolved `stack` line]
PRDs Reviewed: [N]
ADRs Reviewed: [M]

[output of: Bash: bash .claude/scripts/review-receipts.sh hash docs/architecture/adr-*.md design/prd/*.md
 — one Reviewed-Content-Hash line per file reviewed; Phase 1a's freshness
 check reads these on the next run to skip or scope an unchanged re-review]

---

### Traceability Summary
Total requirements: [N]
✅ Covered: [X]
🟡 Covered (Proposed): [P]
⚠️ Partial: [Y]
❌ Gaps: [Z]

### Coverage Gaps (no ADR exists)
For each gap:
  ❌ TR-[id]: [PRD] → [feature] → [requirement]
     Suggested ADR: "/architecture-decision [suggested title]"
     Domain: [API/Data/Auth/etc]
     Knowledge Risk: [LOW/MEDIUM/HIGH]

### Cross-ADR Conflicts
[List all conflicts from Phase 4]

### ADR Dependency Order
[Topologically sorted implementation order from Phase 4 — dependency ordering section]
[Unresolved dependencies and cycles if any]

### PRD Revision Flags
[PRD assumptions that conflict with verified stack behaviour — from Phase 5b]
[Or: "None — all PRD assumptions consistent with verified stack behaviour"]

### Stack Compatibility Issues
[List all stack issues from Phase 5, including Stack Specialist Findings and
 every NOT CHECKED / NOT CONSULTED / NOT ASSESSED line the consultation recorded]

### Architecture Document Coverage
[List missing features and orphaned architecture from Phase 6]

---

### Verdict: [PASS / NOT ASSESSED / CONCERNS / FAIL]

PASS: All requirements covered by **Accepted** ADRs, no conflicts, stack consistent
NOT ASSESSED: The review could not be performed over its stated scope — name why
CONCERNS: Some gaps, partial coverage, or coverage resting on `Proposed` ADRs,
      but no blocking conflicts
FAIL: Critical gaps (Foundation/Core layer requirements uncovered),
      or blocking cross-ADR conflicts detected

**`NOT ASSESSED` ranks above PASS and below CONCERNS and FAIL.** Emit it when:

- **No ADRs exist, or none could be read.** Zero requirements traced is not full
  coverage — it is an untraced architecture, and a matrix of `❌ Gap` rows at
  least says so while an empty matrix says nothing.
- **The requirement source is missing** — no `tr-registry.yaml` and no PRD
  requirements to trace *from*. A review with no left-hand column cannot report
  coverage; it can only report that it had nothing to compare.
- **An ADR is unreadable or has no `## Status`**, so its rows are `❓` and their
  coverage is unknown rather than absent.
- **Phase 6 could not run** — no `docs/architecture/architecture.md`. This does
  not by itself force NOT ASSESSED for the whole review (ADR traceability is the
  primary scope and can still be complete), but it must appear as a named
  `NOT ASSESSED` **line item** in the report rather than as absent findings. Emit
  the overall NOT ASSESSED verdict only if Phase 6 was the review's stated scope.
- **The stack could not be checked in `stack` mode** — the stack is unset, or no
  in-scope ADR has a `## Stack Compatibility` section. In the other modes this is
  a named line item, not the overall verdict.

Do not resolve any of these to PASS on the grounds that no gap was *found*. No
gap was looked for.

### Blocking Issues (must resolve before PASS)
[List items that must be resolved — FAIL verdict only]

### Required ADRs
[Prioritised list of ADRs to create, most foundational first]
```

The `> **Verdict**:` line directly under the H1 carries the same token as the
`### Verdict:` section — `/gate-check` parses the line, so write it every time.

---

## Phase 8: Write and Update Traceability Index

Show the report, the traceability index and the registry changes inline first,
then use `AskUserQuestion` for the write approval, listing every file and what
changes:
- "Review complete. May I write this to `docs/architecture/architecture-review-YYYY-MM-DD.md`,
  `docs/architecture/requirements-traceability.md` and `docs/architecture/tr-registry.yaml`?"
  - [A] Write all three files (review report + traceability index + TR registry)
  - [B] Write review report only — `docs/architecture/architecture-review-YYYY-MM-DD.md`
  - [C] Don't write anything yet — I need to review the findings first

When Phase 4 found `🔴 CONFLICT` entries and `docs/consistency-failures.md`
exists, name that append in the same question (see Reflexion Log Update).

### Traceability Index (`docs/architecture/requirements-traceability.md`)

Write the index from `.claude/docs/templates/architecture-traceability.md` — copy
its headings byte-for-byte; the template is the single source of the index format.
Fill it from Phase 3 (matrix, gaps by layer, conflicts, the ADR → PRD reverse
index, superseded requirements). The `/gate-check validation` gate reads this file
for **zero Foundation-layer gaps**, so the layer of every gap comes from the
feature map's `Layer` column, never from a guess.

Carry into the index's `## Superseded Requirements` table the
`## Superseded Requirements` rows of every `docs/architecture/change-impact-*.md`
report written since the last architecture review (dated after the newest
`docs/architecture/architecture-review-*.md`; every report when there is none) —
`/propagate-prd-change` records them there and never edits the traceability matrix
or the TR registry. Map each row: `Requirement (TR-ID)` → `Req ID`, `PRD` → `PRD`,
`Changed To` → `Change`, `ADRs Affected` → `Affected ADR`, `Resolution` → `Status`.
Rows already in the existing index's table are kept, so a rewrite never drops them.

When Phase 3b did not run, the Story and Test columns read `—` and
`## Document Status` records `**Chain Linked**: no — run /architecture-review rtm`.
A blank chain column must never read as "no story needed".

### RTM Output (rtm mode only)

For `rtm` mode, use `AskUserQuestion`:
- "May I write this to `docs/architecture/requirements-traceability.md` with the full chain linked?"
  - [A] Yes — write to `docs/architecture/requirements-traceability.md`
  - [B] Not yet — show me the full RTM data first, then ask again

The RTM is the same index with its chain columns filled: Story, Test and Test
Status come from Phase 3b, `## Chain Coverage` carries the RTM coverage summary
(COVERED / MISSING test / NO STORY / NO ADR and the full-chain %), and
`**Chain Linked**` reads `yes — /architecture-review rtm [date]`. Append a
`## History` row with the date and full-chain %.

### TR Registry Update

Also ask: "May I write this to `docs/architecture/tr-registry.yaml` — the new
requirement IDs from this review?"

If yes:
- **Append** any new TR-IDs that weren't in the registry before this review, each
  with `feature`, `prd` (the PRD path), `requirement`, `type` (`functional` or
  `nfr`), `nfr_category` (for `nfr` only), `created`, `revised` and `status`
- **Update** `requirement` text and `revised` date for any entries whose PRD
  wording changed (ID stays the same)
- **Mark** `status: deprecated` for any registry entries whose PRD requirement
  no longer exists (confirm with user before marking deprecated)
- **Never** renumber or delete existing entries
- Update the `last_updated` and `version` fields at the top

This ensures all future story files can reference stable TR-IDs that persist
across every subsequent architecture review.

### Reflexion Log Update

After writing the review report, append any 🔴 CONFLICT entries found in Phase 4
to `docs/consistency-failures.md` (if the file exists — the write was named in
the Phase 8 approval question):

```markdown
### [YYYY-MM-DD] — /architecture-review — 🔴 CONFLICT
**Domain**: Architecture / [specific domain e.g. Data Ownership, SLO Budget, Security & Privacy]
**Documents involved**: [ADR-NNNN] vs [ADR-MMMM]
**What happened**: [specific conflict — what each ADR claims]
**Resolution**: [how it was or should be resolved]
**Pattern**: [generalised lesson for future ADR authors in this domain]
```

Only append CONFLICT entries — do not log GAP entries (missing ADRs are expected
before the architecture is complete). Do not create the file if missing — only
append when it already exists.

### Session State Update

After writing all approved files, silently append to
`production/session-state/active.md`:

    ## Session Extract — /architecture-review [date]
    - Verdict: [PASS / CONCERNS / NOT ASSESSED / FAIL]
    - Requirements: [N] total — [X] covered, [Y] partial, [Z] gaps
    - New TR-IDs registered: [N, or "None"]
    - PRD revision flags: [comma-separated PRD names, or "None"]
    - Top ADR gaps: [top 3 gap titles from the report, or "None"]
    - Report: docs/architecture/architecture-review-YYYY-MM-DD.md

If `active.md` does not exist, create it with this block as the initial content.
Confirm in conversation: "Session state updated."

---

## Phase 9: Handoff

After completing the review and writing approved files, present:

1. **Immediate actions**: List the top 3 ADRs to create (highest-impact gaps first,
   Foundation layer before Feature layer)
2. **Pre-gate checklist**: Check whether these exist via Glob and mark each ✅, ❌
   or N/A. The three conditional items take their condition from the resolved
   lines: *Backend* = `backend=` or `data=` on the `stack` line, or `api` in
   `platform.surfaces`; *PII* = `handles_pii=true` on the `compliance` line; *UI* =
   `web`, `ios` or `android` in `platform.surfaces`. A condition known false ⇒
   `N/A — <condition> not configured`, which does not block. An unset condition is
   not false: keep the item and mark it `(condition unset — /gate-check validation asks)`:
   - A test runner per configured layer (`tests/unit/`, `tests/integration/`,
     `tests/contract/` or the `testing.patterns` locations) — if ❌: run `/test-setup`
   - A CI workflow (`.github/workflows/*.yml` or `*.yaml`, `.gitlab-ci.yml`,
     `bitbucket-pipelines.yml`, `azure-pipelines.yml`) — if ❌: run `/test-setup`
   - `docs/ops/slo.md` — if ❌: run `/create-architecture`
   - An API contract in `docs/api/` and `docs/data/data-model.md` (*Backend*) — if ❌:
     run `/api-design` / `/data-model`
   - `docs/security/threat-model.md` (*PII*) — if ❌: run `/security-audit threat-model`
   - `design/accessibility-requirements.md` (*UI*) — if ❌: run `/ux-design accessibility`
   - `docs/architecture/tech-radar.md` — if ❌: run `/setup-stack`
   Present ❌ items as required steps before gate-check. Do not offer `/gate-check`
   as an option if any item is ❌ — offer the missing skill to run instead.
3. **Rerun trigger**: "Re-run `/architecture-review` after each new ADR is written
   to verify coverage improves"

Then close with `AskUserQuestion` tailored to the pre-gate checklist state:
- If ADR gaps remain or any pre-gate item is ❌:
  - "Architecture review complete. What would you like to do next?"
    - [A] Write a missing ADR — open a fresh session and run `/architecture-decision [title]`
    - [B] Run `/test-setup` — required before gate-check (only show if test infrastructure or CI is ❌)
    - [C] Run the missing Architecture-phase skill (`/create-architecture`, `/api-design`, `/data-model`, `/security-audit threat-model`, `/ux-design accessibility` or `/setup-stack` — only the ones whose item is ❌)
    - [D] Stop here for this session
- If all pre-gate checklist items are ✅ or N/A and no blocking ADR gaps remain:
  - "Architecture review complete. All pre-gate items confirmed. What would you like to do next?"
    - [A] Run `/gate-check validation`
    - [B] Write a missing ADR — open a fresh session and run `/architecture-decision [title]`
    - [C] Stop here for this session

---

## Error Recovery Protocol

**First, verify the artifact.** If the return contract named a path, check the
path exists before treating the phase as done — **a named artifact that is not
on disk is a failed phase, however fluent the response reads.** An agent can
burn a full phase and return a plausible preamble having written nothing, which
is neither BLOCKED nor an error nor "fails to complete", so the trigger below
never fires. Resume it naming the unmet contract; the context is
usually still there.

If any spawned agent returns BLOCKED, errors, or fails to complete: **surface it
immediately, don't proceed past a dependency it blocks, and always produce a
partial report** (retry scope here = fewer PRDs / `single-prd`). Full procedure:
`.claude/docs/error-recovery-protocol.md`.

---

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and
`autonomous` modes, see `.claude/docs/automation-modes.md` — the rules below
describe what collaborative mode requires, not universal behavior.

1. **Read silently** — do not narrate every file read
2. **Show the matrix** — present the full traceability matrix before asking for
   anything; let the user see the state
3. **Don't guess** — if a requirement is ambiguous, ask: "Is [X] a technical
   requirement or a product preference?"
4. **Draft before approval** — always show the content that will be written (the
   report, the traceability index, the registry entries, the feature-map row)
   inline in the conversation before requesting approval. Never ask to write
   something the user has not yet seen.
5. **Use `AskUserQuestion` for write approvals** — plain text "May I?" is not
   sufficient. Use the structured tool with labeled options [A]/[B]/[C] so the
   user can choose between "write now", "show full draft first", and "not yet".
   Multi-file changesets must list every file and what changes, then ask once
   with grouped options — not a separate plain-text question per file.
6. **Non-blocking** — the verdict is advisory; the user decides whether to continue
   despite CONCERNS or even FAIL findings
