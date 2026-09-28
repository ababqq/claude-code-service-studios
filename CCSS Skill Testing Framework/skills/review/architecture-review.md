# Skill Test Spec: /architecture-review

> **Category**: review
> **Priority**: critical
> **Spec written**: 2026-09-28

## Skill Summary

`/architecture-review` is an Opus-tier skill that validates the whole body of
architectural decisions against the product requirements. It extracts the
technical requirements of every PRD in `design/prd/` into stable TR-IDs
(`TR-<feature>-NNN`, reusing `docs/architecture/tr-registry.yaml` entries — this
skill is the registry's only writer), builds a traceability matrix from each
ADR's `## PRD Requirements Addressed` table, detects cross-ADR conflicts (data
ownership, integration contracts, SLO budgets, dependency cycles via
`bash .claude/scripts/adr-dep-graph.sh`, source of truth, security & privacy),
cross-checks stack compatibility against `docs/stack-reference/`, and checks the
architecture document's coverage. Modes: `full` (default), `coverage`,
`consistency`, `stack`, `rtm`, `single-prd design/prd/<feature>.md`.

It produces a PASS / CONCERNS / NOT ASSESSED / FAIL verdict and, after
approval, writes `docs/architecture/architecture-review-YYYY-MM-DD.md`,
`docs/architecture/requirements-traceability.md` and appends new IDs to
`docs/architecture/tr-registry.yaml`. It spawns **no director gate**: the routed
stack leads it consults return findings, not gate verdicts.

---

## Static Assertions (Structural)

Verified automatically by `/skill-test static` — no fixture needed — plus the
contract checks below.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] `name: architecture-review` equals the skill directory, the catalog `name` and this spec's basename; `model: opus`
- [ ] First body line is exactly `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow,stack,surfaces,compliance` ``
- [ ] `allowed-tools` grants `Bash(bash "*/.claude/skills/architecture-review/../../hooks/yaml-helper.sh" resolve_config *)` (its own directory name)
- [ ] The line after the bootstrap block is exactly: ``Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.`` (no `review_mode` in the keys)
- [ ] The automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") follows that line verbatim
- [ ] `allowed-tools` is exactly: Read, Glob, Grep, Write, Bash, Agent, AskUserQuestion, plus the grant (membership exact, order free — no Edit); no `disable-model-invocation`, no `isolation`
- [ ] Has ≥2 phase headings
- [ ] Verdict tokens are exactly PASS, CONCERNS, FAIL and NOT ASSESSED, with NOT ASSESSED ranked above PASS and below CONCERNS and FAIL
- [ ] Contains "May I write this to" before every write, including the combined approval for `docs/architecture/architecture-review-YYYY-MM-DD.md`, `docs/architecture/requirements-traceability.md` and `docs/architecture/tr-registry.yaml`
- [ ] The report's H1 is followed, after one blank line, by `> **Verdict**: <TOKEN>`, carrying the same token as its `### Verdict:` section
- [ ] The ADR section scan uses exactly `^## (Status|Decision|PRD Requirements Addressed|Stack Compatibility|ADR Dependencies|Performance & SLO Implications|Security & Privacy Implications)` — headings of `.claude/docs/templates/architecture-decision-record.md`
- [ ] The traceability index is written from `.claude/docs/templates/architecture-traceability.md` with its headings copied byte for byte
- [ ] States that the skill spawns no director gate; no gate ID appears in a spawn instruction
- [ ] No `!` injection other than the bootstrap line; no `file:line` citations of other files
- [ ] Has a next-step handoff at the end (Phase 9), naming skills by their current names

---

## Director Gate Checks

None. `/architecture-review` spawns no director gate in any review mode, and
`review_mode` is not among its keys. In Phase 5 it spawns the **routed stack
leads** (`web-specialist`, `mobile-specialist`, `backend-specialist`,
`data-specialist`, `cloud-specialist` — resolved from the `[routing: …]` part of
the `stack` line) as consultants; their findings feed the verdict, which stays
the skill's own.

---

## Test Cases

### Case 1: Happy Path — every requirement covered by Accepted ADRs

**Fixture:**
- `modes.rigor: full`; `stack` resolves `web=Next.js 15.3 @apps/web; backend=NestJS 11.0 @apps/api; data=PostgreSQL 16; unset=mobile,cloud` with routing `web-specialist>nextjs-specialist, backend-specialist>node-specialist, data-specialist`; `platform.surfaces: [web, api]`; `compliance: regions=kr handles_pii=true`
- `design/prd/goals.md`, `design/prd/auth.md`, `design/prd/payments.md`, each with `## Functional Requirements`, `## Business Rules & Calculations`, `## Non-Functional Requirements` and `## Dependencies`
- `design/product/feature-map.md` lists auth, goals, payments with their Layer column
- Accepted ADRs `docs/architecture/adr-0001-identity-and-auth.md` … `adr-0005-*.md`, each with `## Status`, `## Stack Compatibility`, `## ADR Dependencies` and a `## PRD Requirements Addressed` table naming TR-IDs; no dependency cycle
- `docs/architecture/tr-registry.yaml` already holds `TR-goals-001`; `docs/architecture/architecture.md` and `docs/ops/slo.md` exist
- No prior `docs/architecture/architecture-review-*.md` (`RECEIPT: NONE`)

**Input:** `/architecture-review`

**Expected behavior:**
1. Freshness check with `bash .claude/scripts/review-receipts.sh check …` returns `RECEIPT: NONE`; the full review proceeds
2. Skill reports the denominators ("Loaded 3 PRDs, 5 ADRs, stack: …") and loads sections, not whole files
3. Requirements are extracted; `TR-goals-001` is reused unchanged, new ones take the next sequence number per feature
4. Matrix: every requirement ✅ Covered by an Accepted ADR; `bash .claude/scripts/adr-dep-graph.sh` reports no `CYCLE:`
5. The web, backend and data leads are spawned in parallel with their layers' ADRs; the mobile and cloud layers are recorded `NOT CHECKED — <layer> layer not configured (run /setup-stack)` only if an in-scope ADR relies on them
6. Verdict PASS; report shown; one `AskUserQuestion` lists the three files with options [A] all three / [B] report only / [C] nothing yet

**Assertions:**
- [ ] N_prd and N_adr are reported before any section scan, and a PRD missing `## Summary` is still in scope
- [ ] A requirement matching an existing registry entry keeps its TR-ID; no ID is renumbered or deleted
- [ ] Stack leads are spawned in one parallel batch and only for layers the in-scope ADRs touch
- [ ] Variant — `backend-specialist` replies with `NOT CONSULTED — node-specialist (nested spawn unavailable)` or a `node-specialist: <task>` hand-off: the skill spawns `node-specialist` itself with that task, or carries the `NOT CONSULTED` line into the report's `### Stack Compatibility Issues`; the line is never dropped
- [ ] Verdict is PASS only because every requirement is covered by an **Accepted** ADR, with no conflict and a consistent stack
- [ ] The saved report starts with `# Architecture Review Report` followed by `> **Verdict**: PASS` and carries one `Reviewed-Content-Hash` receipt line per reviewed file
- [ ] `tr-registry.yaml` is appended (with `prd:` paths and `type:`), never rewritten wholesale
- [ ] The handoff offers `/gate-check validation` only when every pre-gate checklist item (test runner and CI workflow, `docs/ops/slo.md`, API contract and data model when there is a backend, threat model when there is PII, accessibility requirements when there is a UI, tech radar) is ✅ or N/A; the *Backend*, *PII* and *UI* conditions come from the resolved `stack`, `compliance` and `surfaces` lines — a condition known false gives `N/A — <condition> not configured`, an unset one keeps the item (`(condition unset — /gate-check validation asks)`)

---

### Case 2: Failure Path — uncovered Foundation requirement and a cross-ADR conflict

**Fixture:**
- As Case 1, except `TR-auth-003` ("sessions are revoked on every device within 60 s of a password change", Layer Foundation) has no ADR
- `adr-0003-goals-domain.md` and `adr-0004-payments-integration.md` both declare themselves the only writer of `goal.balance`
- `docs/consistency-failures.md` exists

**Input:** `/architecture-review`

**Expected behavior:**
1. The matrix marks `TR-auth-003` ❌ GAP
2. Phase 4 reports a Data ownership conflict between ADR-0003 and ADR-0004 in the conflict-entry format (Type, what each ADR claims, Impact, Resolution options)
3. Verdict FAIL (Foundation-layer gap and a blocking conflict)
4. The approval question names the append to `docs/consistency-failures.md`

**Assertions:**
- [ ] Verdict is FAIL (not CONCERNS) for an uncovered Foundation-layer requirement or a blocking cross-ADR conflict
- [ ] The conflict entry names both ADRs and the contested entity, and lists at least two resolution options
- [ ] The skill does NOT resolve the conflict or edit either ADR
- [ ] "Required ADRs" lists `/architecture-decision [title]` for the gap, Foundation layer first
- [ ] Only 🔴 CONFLICT entries are appended to `docs/consistency-failures.md`, and only because the file already exists

---

### Case 3: NOT ASSESSED — no ADRs to trace against

**Fixture:**
- `design/prd/goals.md` and `design/prd/auth.md` exist with requirements
- `docs/architecture/adr-*.md` matches no file

**Input:** `/architecture-review`

**Expected behavior:**
1. Skill establishes the denominators: N_prd = 2, N_adr = 0
2. With zero ADRs, zero requirements are traced — the requirements baseline exists, the right-hand column does not
3. Verdict NOT ASSESSED, naming the missing input and recommending `/architecture-decision`

**Assertions:**
- [ ] Verdict is NOT ASSESSED, with the reason stated (no ADRs exist or none could be read)
- [ ] No PASS verdict is produced: "no gap found" is never read as full coverage
- [ ] A variant with ADR files present but none carrying a scannable section is reported as malformed ADRs ("run `/architecture-decision retrofit [file]`"), not as zero coverage
- [ ] The report still states the covered set (PRDs and ADRs counted) so the reader sees what was compared

---

### Case 4: Partial Path — coverage resting on a Proposed ADR

**Fixture:**
- As Case 1, except `TR-payments-001` ("a deposit is applied exactly once per Toss Payments webhook") is covered only by `adr-0004-payments-integration.md`, whose `## Status` is `Proposed`

**Input:** `/architecture-review coverage`

**Expected behavior:**
1. `TR-payments-001` is marked 🟡 Covered (Proposed)
2. Verdict is capped at CONCERNS, naming the route out: `/architecture-decision accept ADR-0004`

**Assertions:**
- [ ] 🟡 is not a pass state: the verdict is CONCERNS, not PASS
- [ ] Each ADR's `## Status` is read before coverage is marked
- [ ] The output names `/architecture-decision accept ADR-0004`

---

### Case 5: Mode Variant — `stack` mode with the stack unset, and `single-prd`

**Fixture A:**
- `stack` resolves `stack: unset — run /setup-stack`; three ADRs exist

**Fixture B:**
- As Case 1; the target is `design/prd/goals.md`

**Input:** A: `/architecture-review stack` — B: `/architecture-review single-prd design/prd/goals.md`

**Expected behavior:**
1. A: no stack lead is spawned; the output records `Stack validation: NOT ASSESSED — stack unset (run /setup-stack)`; in `stack` mode that is the overall verdict
2. B: the goals PRD's summary selects the ADRs that name the feature or its PRD path; unrelated PRDs are skipped

**Assertions:**
- [ ] A: the overall verdict is NOT ASSESSED in `stack` mode (in `full` mode the same finding is a named line item, not the overall verdict)
- [ ] A: no version claim is confirmed from memory; an uncovered post-cutoff API is written `NOT SOURCEABLE — <API> is not covered by docs/stack-reference/<component-slug>/`
- [ ] B: only ADRs related to `goals` are loaded, and the report says the scope was one PRD

---

### Case 6: Edge Case — an unchanged re-review stands on the prior report

**Fixture:**
- `docs/architecture/architecture-review-2026-10-12.md` exists with receipt lines, verdict CONCERNS
- No ADR or PRD changed since (`review-receipts.sh check` prints only `UNCHANGED` lines)

**Input:** `/architecture-review`

**Expected behavior:**
1. Skill surfaces the prior report's date and verdict
2. Skill asks `[A] Stand on the prior report (Recommended)` / `[B] Re-run the full review anyway`

**Assertions:**
- [ ] The skip is offered only when every line is `UNCHANGED` and no `UNRESOLVED` line is present
- [ ] When some files are `CHANGED` or `NEW`, the skill names them and recommends `single-prd` for the changed features instead of a silent full re-run
- [ ] In `guided` mode [A] proceeds with a note; in `autonomous` mode the decision is logged via `log_decision`

---

### Case 7: Mode Variant — `rtm` links stories and tests

**Fixture:**
- As Case 1, plus `production/epics/goals-core/story-001-create-goal.md` carrying `**Requirement**: TR-goals-001` and a `## Test Evidence` path `apps/api/src/goals/goals.authz.test.ts` that exists
- `TR-payments-001` has no story yet; `testing.patterns` is unset in `project.yaml`

**Input:** `/architecture-review rtm`

**Expected behavior:**
1. Stories are collected with targeted greps, not full reads
2. Test locations fall back to the `tests/**` convention and the report says `testing.patterns unset — tests/** convention used`
3. RTM rows: `TR-goals-001` COVERED; `TR-payments-001` NO STORY
4. Skill asks "May I write this to `docs/architecture/requirements-traceability.md` with the full chain linked?"

**Assertions:**
- [ ] Test Status uses exactly COVERED / MISSING / NONE / NO STORY
- [ ] `**Chain Linked**` reads `yes — /architecture-review rtm [date]` in the written index
- [ ] A `UI` story evidenced by screenshots or a `Config` story evidenced by the smoke check may be NONE; a `Logic`, `Integration` or `E2E` story with no test path is called out in its row

---

### Case 8: Director Gate — none, whatever the review mode

**Fixture:**
- As Case 1; `project.yaml` sets `modes.review_mode: full`

**Input:** `/architecture-review`

**Expected behavior:**
1. The review mode is not resolved — `review_mode` is not among the keys
2. No director gate agent is spawned at any point; only the routed stack leads are consulted
3. The verdict is produced from the review's own phases

**Assertions:**
- [ ] No gate ID (TD-, PD-, DM-, DD-, TL-, QL-, SE-, SR- prefixed) appears as a spawned gate
- [ ] Output contains no `[GATE-ID] skipped — <Mode> mode` notes
- [ ] Stack lead findings are incorporated under `### Stack Specialist Findings` as findings, not as gate verdicts

---

## Protocol Compliance

- [ ] Uses "May I write this to `<path>`?" (through `AskUserQuestion` with labelled options) before writing the report, the traceability index, the TR registry, the feature map (PRD revision flags) or the `docs/consistency-failures.md` append
- [ ] Shows the matrix, the report and every proposed change inline before asking to write
- [ ] Does not edit PRDs or ADRs; PRD revision flags set the feature-map `Status` to exactly `Needs Revision`
- [ ] Verdict is one of exactly PASS, CONCERNS, FAIL, NOT ASSESSED
- [ ] Surfaces a BLOCKED or failed stack consultation immediately and still produces a partial report
- [ ] Writes nothing under `production/session-logs/`; never writes `modes.review_mode` or any other knob `modes.rigor` fronts
- [ ] Ends with a next-step `AskUserQuestion` tailored to the pre-gate checklist state

---

## Coverage Notes

- The phases' extraction categories (data & ownership, performance & SLO,
  availability, security & privacy, cross-feature communication, consistency,
  third-party integration, client & surface, configuration & flags) are not each
  fixture-tested; Cases 1–2 exercise the matrix and conflict paths they share.
- The PRD Revision Flags phase (architecture → product feedback) is covered only
  by the Protocol Compliance write assertion.
- Phase 6 (architecture document coverage) is exercised by Case 1; its
  `Architecture document coverage: NOT ASSESSED — no docs/architecture/architecture.md`
  line item is not separately tested.
- `workflow: minimal` (the skill says it is not applicable before doing anything
  else) is not tested.
