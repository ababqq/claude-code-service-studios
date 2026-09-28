# Skill Test Spec: /create-control-manifest

> **Category**: pipeline
> **Priority**: high
> **Spec written**: 2026-09-28

## Skill Summary

`/create-control-manifest` turns every **Accepted** ADR, the tech radar and the stack
reference into one flat rules sheet for engineers — `docs/architecture/control-manifest.md`
— organised by architectural layer (`## Foundation Layer Rules`, `## Core Layer Rules`,
`## Feature Layer Rules`, `## Presentation Layer Rules`) plus `## Global Rules (All Layers)`.
It establishes the ADR denominator and resolves each ADR's `## Status` with one grep
before reading anything, reads only five ADR sections, takes naming conventions and
budgets from `naming.*` and `performance.*` in `project.yaml`, and turns the tech radar's
`## Hold` and `## Forbidden Patterns` into Never rules. It previews the rule counts,
applies the review mode to its one gate, **TD-MANIFEST** (technical-director), and asks
"May I write" before writing. Its `Manifest Version` date is what `/create-stories`
embeds in each story and what `/story-readiness` compares against. Its output is the
artifact of catalog step `validation.control-manifest` (required at `full`).

Verdicts: **COMPLETE** (manifest written) / **BLOCKED** (write declined) / **NOT ASSESSED** (no ADRs,
no ADR `## Status` readable, or the user stops when none is Accepted — Phase 1 stops). An input the
skill could not assess is named with its `NOT CHECKED — <reason>` or `NOT SET — <key>`
line — never filled from memory.

---

## Static Assertions (Structural)

Verified automatically by `/skill-test static` — no fixture needed.

- [ ] Frontmatter has `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`; `name: create-control-manifest` equals the directory name, the catalog `name` and this spec's basename
- [ ] `description` is exactly "Flat must/never rules per layer from Accepted ADRs and the tech radar."
- [ ] `argument-hint` offers `update` and `[--review full|lean|solo]`; `model: sonnet`; no `disable-model-invocation` and no `isolation` key
- [ ] First body line is exactly `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,stack` `` — the `--keys` value is exactly `review_mode,automation,stack`
- [ ] `allowed-tools` is exactly `Read, Glob, Grep, Write, Agent, AskUserQuestion` plus the grant `Bash(bash "*/.claude/skills/create-control-manifest/../../hooks/yaml-helper.sh" resolve_config *)` — no `Edit`, no plain `Bash`, no MCP tool name
- [ ] The line after the bootstrap block is exactly `` Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`. ``
- [ ] The automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") follows that line verbatim
- [ ] ≥2 numbered phase headings (`## 1. Load All Inputs` … `## 6. Suggest Next Steps`)
- [ ] Verdict keywords `COMPLETE`, `BLOCKED` and `NOT ASSESSED` present; the could-not-assess lines `NOT CHECKED — tech radar absent (run /setup-stack)` and `NOT CHECKED — stack unset (run /setup-stack)` present
- [ ] "May I write this to `docs/architecture/control-manifest.md`?" present (Phase 5), and "May I write this to `production/session-state/control-manifest-draft.md`?" before the gate draft
- [ ] Output path `docs/architecture/control-manifest.md` matches the glob of catalog step `validation.control-manifest` exactly
- [ ] The ADR section grep is exactly `^## (Decision|Alternatives Considered|Performance & SLO Implications|Security & Privacy Implications|Stack Compatibility)` — every heading it names exists in `.claude/docs/templates/architecture-decision-record.md`
- [ ] Per-layer manifest sections are `### Required Patterns`, `### Forbidden Approaches`, `### Performance & SLO Guardrails`, `### Security & Privacy Rules`; layer headings keep the `## <Layer> Layer Rules` form
- [ ] TD-MANIFEST review-mode check carries the lean suffix sentence "**skip every gate whose ID does not end in `-PHASE-GATE`**"; the spawn has `` Pass: manifest draft path · Accepted ADR paths · `docs/architecture/tech-radar.md` path ``; the reply is parsed as `[TD-MANIFEST]: TOKEN`
- [ ] Only one `!` injection (the bootstrap); no `file:line` citation of another file
- [ ] Next-step handoff names `/create-epics` and `/create-stories`; nothing names a retired skill

---

## Director Gate Checks

One gate: **TD-MANIFEST** — `technical-director`, Domain "Engineering rules", verdicts
`APPROVE / CONCERNS / REJECT`. It runs after the user approves the rule summary (Phase 4,
option `[A]`) and before the manifest is written.

- **Full mode**: the draft is written to `production/session-state/control-manifest-draft.md`
  (after "May I write"), then TD-MANIFEST spawns with
  `` Pass: manifest draft path · Accepted ADR paths · `docs/architecture/tech-radar.md` path ``.
  The prompt tells the agent to read `.claude/docs/director-gates/td-manifest.md`; the
  parent never reads it.
- **Lean mode**: skip every gate whose ID does not end in `-PHASE-GATE` — TD-MANIFEST is
  skipped; the note `[TD-MANIFEST] skipped — Lean mode` replaces the review line in the
  manifest header.
- **Solo mode**: TD-MANIFEST skipped — note `[TD-MANIFEST] skipped — Solo mode` in the
  same place.
- `--review full|lean|solo` overrides the resolved `review_mode` for one run.

---

## Test Cases

Fixtures use the Moa example product: Accepted ADRs
`docs/architecture/adr-0001-identity-and-auth.md`, `adr-0002-primary-data-store.md`,
`adr-0003-api-style.md`, `adr-0004-deployment-topology.md`; stack NestJS 11.0 +
Next.js 15.3 + PostgreSQL 16.

### Case 1: Happy Path — four Accepted ADRs, radar and budgets present

**Fixture:**
- The four ADRs above, each with `## Status` → `Accepted` and the five scanned sections
- `docs/architecture/tech-radar.md` with `## Adopt` (Prisma), `## Hold` (a legacy session library) and `## Forbidden Patterns` ("refresh tokens in web localStorage — ADR-0001")
- `docs/stack-reference/VERSION.md` pins the configured components; `project.yaml` sets `naming.api_paths`, `naming.db_tables`, `performance.api_p95_ms: 300`
- No `docs/architecture/control-manifest.md`; review mode `lean` (gate behaviour is Cases 6–8)

**Input:** `/create-control-manifest`

**Expected behavior:**
1. Globs `docs/architecture/adr-*.md` (N = 4) and resolves all statuses with one `^## Status` grep before reading any ADR body
2. Reads only the five sections via the section grep; classifies each rule into Foundation / Core / Feature / Presentation
3. Reads `naming.*` and `performance.*` from `project.yaml` with Read; turns radar `## Hold` and `## Forbidden Patterns` entries into Never rules carrying their source
4. Shows the `## Control Manifest Preview` (stack line, ADRs covered, per-layer counts) and asks "Does this rule summary look complete?"
5. Skips TD-MANIFEST (lean) and asks "May I write this to `docs/architecture/control-manifest.md`?"
6. Writes the manifest and reports Verdict **COMPLETE**

**Assertions:**
- [ ] The status grep runs before any ADR is read in full; the denominator N is stated
- [ ] Every rule carries `source: ADR-NNNN` or its tech-radar source; nothing is added from memory
- [ ] The Never rule "refresh tokens in web localStorage" appears under the Forbidden Patterns (tech radar) block with source `ADR-0001`
- [ ] Header carries `> **Stack**:`, `> **Last Updated**:`, `> **Manifest Version**:` (same date), `> **ADRs Covered**:`, `> **Status**:` and the TD-MANIFEST review line (here the Lean skip note)
- [ ] Global Rules show `performance.api_p95_ms` = 300 and every unset budget as `NOT SET`
- [ ] A layer with no rule of a kind keeps the heading with `none — no Accepted ADR states one`
- [ ] Nothing is written before the "May I write" answer; verdict **COMPLETE** after the write

---

### Case 2: Failure Path — no ADRs, or ADRs without `## Status`

**Fixture (2a):** `docs/architecture/` exists; `adr-*.md` matches nothing.

**Fixture (2b):** three ADRs exist, none has a `## Status` heading (status grep returns 0 matches, N = 3).

**Input:** `/create-control-manifest`

**Expected behavior:**
1. (2a) "No ADRs found — run `/architecture-decision` before building a control manifest." — stop with Verdict NOT ASSESSED
2. (2b) "[3] ADRs found, none has a `## Status` section — acceptance cannot be determined. Run `/architecture-decision retrofit <file>` on each." — stop with Verdict NOT ASSESSED

**Assertions:**
- [ ] No manifest and no draft file is written in either variant
- [ ] 2b does not treat the ADRs as Accepted and does not treat the set as empty
- [ ] Each message names the skill that fixes the input (`/architecture-decision`)
- [ ] No TD-MANIFEST spawn; both variants end with Verdict NOT ASSESSED

---

### Case 3: NOT ASSESSED — tech radar, stack and naming inputs missing

**Fixture:**
- Two Accepted ADRs
- No `docs/architecture/tech-radar.md`
- The resolved `stack` line reads `stack: unset — run /setup-stack`
- `project.yaml` has no `naming.*` and no `performance.*` keys

**Input:** `/create-control-manifest`

**Expected behavior:**
1. The preview's `Tech radar:` line and the manifest header record `NOT CHECKED — tech radar absent (run /setup-stack)`
2. Stack-sourced rules (deprecated APIs, stack best practices) are replaced by `NOT CHECKED — stack unset (run /setup-stack)` in the preview and under the manifest's `### Forbidden APIs` heading; the ADR rules still build
3. Every naming row and budget row reads `NOT SET — naming.<key>` / `NOT SET — performance.<key>`

**Assertions:**
- [ ] Both `NOT CHECKED` lines appear in the preview **and** in the written manifest
- [ ] No naming convention, budget or forbidden API is filled from a default or from memory
- [ ] Unset keys are never rendered as "none" or as an empty table that reads clean
- [ ] The manifest is still offered for writing (the gaps are named, not hidden)

---

### Case 4: Mode Variant — `update` regenerates an existing manifest

**Fixture:**
- `docs/architecture/control-manifest.md` exists with `> **Manifest Version**: 2026-10-02`
- ADR-0005 was accepted since; stories under `production/epics/goals-core/` embed `2026-10-02`

**Input:** `/create-control-manifest update`

**Expected behavior:**
1. Rebuilds from the current Accepted set (ADR-0005 included) and previews it
2. Asks "May I write this to `docs/architecture/control-manifest.md`?" before overwriting
3. Sets `Manifest Version` and `Last Updated` to today; the next-step text says stories created earlier carry an older `Manifest Version` and `/story-readiness` will flag them

**Assertions:**
- [ ] The file is never overwritten without the "May I write" answer
- [ ] `Manifest Version` is a date equal to `Last Updated` (no counter)
- [ ] The regeneration note recommends telling the team about new Forbidden entries

---

### Case 5: Edge Case — mixed and non-Accepted statuses

**Fixture (5a):** ADR-0001 `Superseded by ADR-0004`; ADR-0002, ADR-0003, ADR-0004 `Accepted`; ADR-0005 `Proposed`.

**Fixture (5b):** four ADRs, all `Proposed`.

**Fixture (5c):** four ADRs; three `Accepted`; `adr-0004-<slug>.md` has no `## Status` section (the status grep returns 3 matches, N = 4).

**Expected behavior:**
1. (5a) The Accepted set is ADR-0002..0004; the Superseded ADR-0001 and the Proposed ADR-0005 contribute no rule
2. (5b) "[4] ADRs found, none Accepted. A manifest built from Proposed ADRs would encode decisions that may still change." — asks whether to proceed with Proposed or stop; stopping ends with Verdict NOT ASSESSED — no Accepted ADRs to build from
3. (5c) The preview and the manifest header carry `NOT CHECKED — docs/architecture/adr-0004-<slug>.md has no ## Status section (run /architecture-decision retrofit docs/architecture/adr-0004-<slug>.md)`; the run proceeds with the three Accepted ADRs

**Assertions:**
- [ ] `> **ADRs Covered**:` and the preview's `ADRs covered:` list only ADR-0002..0004 in 5a
- [ ] `Superseded by ADR-NNNN` and `Deprecated` ADRs are never in the Accepted set
- [ ] 5b never silently emits an empty manifest; a stop there is NOT ASSESSED, never COMPLETE
- [ ] 5c never counts the status-less ADR as Accepted and does not stop the run — `> **ADRs Covered**:` lists only the three Accepted ADRs

---

### Case 6: Director Gate — full mode

**Fixture:**
- Case 1 fixture; review mode `full` (`modes.rigor: full`, or `--review full` on any project)

**Expected behavior:**
1. After option `[A] Yes — looks good, run the director review and write the manifest`, asks "May I write this to `production/session-state/control-manifest-draft.md`?" and writes the draft
2. Spawns `technical-director` for TD-MANIFEST with `` Pass: manifest draft path · Accepted ADR paths · `docs/architecture/tech-radar.md` path ``
3. Parses the first line `[TD-MANIFEST]: TOKEN` and maps it to its class

**Assertions:**
- [ ] APPROVE → proceeds to Phase 5; header records `> **Technical Director Review (TD-MANIFEST)**: APPROVED [date]`
- [ ] CONCERNS → `AskUserQuestion` with `Revise flagged rules` / `Accept and proceed` / `Discuss further`; accepting records `CONCERNS (accepted) [date]`
- [ ] REJECT → the manifest is not written; flagged rules are fixed, the summary re-presented and the review re-run
- [ ] A missing or malformed first line is treated as CONCERNS-class, never as approval
- [ ] The parent session never reads `.claude/docs/director-gates/td-manifest.md`

---

### Case 7: Director Gate — lean mode

**Fixture:** Case 1 fixture; review mode `lean`.

**Expected behavior:**
1. TD-MANIFEST does not end in `-PHASE-GATE`, so it is skipped; the skill goes straight to Phase 5

**Assertions:**
- [ ] No `technical-director` spawn and no draft file under `production/session-state/`
- [ ] The manifest header's review line is `[TD-MANIFEST] skipped — Lean mode`
- [ ] Verdict can still be **COMPLETE** — the skip is recorded, not scored

---

### Case 8: Director Gate — solo mode

**Fixture:** Case 1 fixture; review mode `solo` (the unconfigured default: `modes.rigor` defaults to `minimal`, which resolves `review_mode` to `solo`).

**Expected behavior:**
1. All gates skipped

**Assertions:**
- [ ] No director gate spawns
- [ ] The manifest header's review line is `[TD-MANIFEST] skipped — Solo mode`

---

## Protocol Compliance

- [ ] Loads all inputs silently; shows the rule summary before any write
- [ ] "May I write this to `<path>`?" before the draft and before the manifest
- [ ] Every rule traces to an ADR, the tech radar or a stack reference doc; rules are extracted, not paraphrased into new meaning
- [ ] Never writes `modes.review_mode` or any other knob `modes.rigor` fronts
- [ ] Writes nothing under `production/session-logs/`
- [ ] Ends with the next-step handoff: `/create-epics layer: foundation`, then `/create-stories [epic-slug]`

---

## Coverage Notes

- Pipeline rubric mapping: P1 (output schema — Case 1 header and layer sections), P2
  (layer classification Foundation → Presentation — Case 1), P3 (May-I-write per file —
  Cases 1, 4, 6), P4 (gate per review mode — Cases 6–8), P5 (reads ADRs, radar and stack
  reference before writing — Cases 1, 3).
- The `deprecated-apis.md` relevance filter (scope a row to the subsystem it applies to,
  or omit it as unresolved) is exercised only implicitly by Case 1; a dedicated fixture
  would need a mixed-subsystem deprecation table.
- Verdicts are COMPLETE / BLOCKED / NOT ASSESSED; an unassessable input surfaces as a named
  `NOT CHECKED` / `NOT SET` line (Case 3, still COMPLETE); no ADRs or unreadable statuses stop
  with NOT ASSESSED (Case 2), and so does a stop when no ADR is Accepted (Case 5b).
