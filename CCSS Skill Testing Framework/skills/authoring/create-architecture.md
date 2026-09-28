# Skill Spec: /create-architecture

> **Category**: authoring
> **Priority**: low
> **Spec written**: 2026-09-28

## Skill Summary

`/create-architecture` produces `docs/architecture/architecture.md` — the whole-system blueprint that turns the
product record (product brief, feature map, MVP PRDs; the one-pager at `minimal`) into layers and modules
(`Foundation / Core / Feature / Presentation`), a deployment topology with its environments (local, preview,
staging, production), data flow, integrations, a security model, observability and NFR budgets — plus, drafted with
`sre-engineer`, `docs/ops/slo.md` from `.claude/docs/templates/slo.md` (`## Critical User Journeys`,
`## SLIs & SLOs`, `## Error Budget Policy`, `## Dashboards & Alerts`, `## On-call`). It builds a Technical
Requirements Baseline from the PRDs (reusing registered `TR-<feature>-NNN` IDs), audits existing ADRs, lists the
required ADRs with the Foundation-layer ones marked critical, writes the approved `performance.*` budgets to
`project.yaml`, and closes with the TD-ARCHITECTURE (`technical-director`) and TL-FEASIBILITY (`tech-lead`) gates
under the review-mode rules. Modes: full walkthrough (default / `full`), `section <name>` and `tdd <feature>` — an
optional per-feature technical design at `docs/architecture/tdd-<feature>.md` from
`.claude/docs/templates/technical-design-document.md`, never a gate artifact. Document verdict: `COMPLETE` /
`INCOMPLETE` / `NOT ASSESSED`, precedence INCOMPLETE > NOT ASSESSED > COMPLETE. It never writes or accepts ADRs, the
API contract, the data model, the threat model or the TR registry.

Assertions quote the canonical English text of `.claude/skills/create-architecture/SKILL.md`; prompts are rendered in
the user's conversation language at run time (`.claude/docs/coding-standards.md` § Language Policy) and this spec
never asserts the runtime wording.

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] `name: create-architecture` equals the directory name (`.claude/skills/create-architecture/`) and this spec's
      basename
- [ ] `argument-hint` is `"[full | section <name> | tdd <feature>] [--review full|lean|solo]"`
- [ ] The first body line is exactly
      `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,docs.density,stack,surfaces,team.size,compliance,distribution` ``
      — the `--keys` value is exactly `review_mode,automation,workflow,docs.density,stack,surfaces,team.size,compliance,distribution`
- [ ] `allowed-tools` contains the grant naming this skill's own directory:
      `Bash(bash "*/.claude/skills/create-architecture/../../hooks/yaml-helper.sh" resolve_config *)`
- [ ] `allowed-tools` is exactly the set Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion plus that grant — no
      plain `Bash` (the skill runs no command; `team.size` comes from the bootstrap block), no MCP tool names
- [ ] The line after the bootstrap block is exactly: ``Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] The automation prelude block — from `**Automation mode**: Resolve` to `categories always prompt).` — follows
      that line verbatim
- [ ] The bootstrap line is the only `!` injection in the file; no `file:line` citation of another file
- [ ] `model: sonnet`; no `disable-model-invocation` and no `isolation` key
- [ ] ≥2 phase headings (Phase 1 through Phase 17)
- [ ] The document verdict tokens are spelled exactly: `COMPLETE`, `INCOMPLETE`, `NOT ASSESSED`, and the verdict line
      `> **Verdict**:` sits directly under the document's H1
- [ ] Every output is named: `docs/architecture/architecture.md`, `docs/ops/slo.md`,
      `docs/architecture/tdd-<feature>.md`, `project.yaml` (`performance.*` only)
- [ ] "May I write this to `<path>`?" appears before every write — the skeleton and each section, `docs/ops/slo.md`,
      `project.yaml`, the technical design, and `production/session-state/active.md`
- [ ] The TD-ARCHITECTURE spawn carries this `Pass:` line verbatim:
      `` Pass: `docs/architecture/architecture.md` path · `docs/ops/slo.md` path · resolved `stack` line · MVP PRD paths ``
- [ ] The TL-FEASIBILITY spawn carries this `Pass:` line verbatim:
      `` Pass: `docs/architecture/architecture.md` path · resolved `stack` line · resolved `team.size` ``
- [ ] Each spawn prompt tells the agent to read its own gate file (`.claude/docs/director-gates/td-architecture.md`,
      `.claude/docs/director-gates/tl-feasibility.md`), and the parent parses the first reply line as `[GATE-ID]: TOKEN`
- [ ] The unset-layer line is spelled `NOT CHECKED — <layer> layer not configured (run /setup-stack)`
- [ ] Next-step handoff at the end (Phase 17 summary template and closing `AskUserQuestion`)

---

## Director Gate Checks

Two gates run in Phase 14, on the finished document, spawned **in parallel**:

- **TD-ARCHITECTURE** (`technical-director`) — tokens `APPROVE` / `CONCERNS` / `REJECT`.
- **TL-FEASIBILITY** (`tech-lead`) — tokens `FEASIBLE` / `CONCERNS` / `INFEASIBLE`.

- **Full mode**: both spawn; the strictest class wins across the two.
- **Lean mode**: the lean suffix rule skips both (neither ends in `-PHASE-GATE`); the header records
  `> [TD-ARCHITECTURE] skipped — Lean mode` and `> [TL-FEASIBILITY] skipped — Lean mode`.
- **Solo mode**: both skipped with `— Solo mode` notes.
- **N/A**: `tdd <feature>` spawns no gate (its `tech-lead` review is a consultation). `section <name>` offers to re-run
  Phase 14 after a major revision (module map, topology, security model or SLOs).

Not gates, and never skipped by `review_mode` (the user may skip them): the Phase 9 stack lead review and the Phase 10b
`sre-engineer` SLO consultation.

---

## Test Cases

### Case 1: Happy Path — full walkthrough for Moa at `standard`

**Fixture** (assumed project state):
- Moa; the config block prints `review_mode: full (project.yaml)`, `workflow: standard (rigor:standard)`,
  `docs.density: balanced (rigor:standard)`,
  `stack: web=Next.js 15.3 @apps/web,apps/admin; mobile=React Native (Expo) 0.79 @apps/mobile; backend=NestJS 11.0 @apps/api,services/worker; data=PostgreSQL 16; unset=cloud [routing: web-specialist>nextjs-specialist, mobile-specialist>react-native-specialist, backend-specialist>node-specialist, data-specialist] (project.yaml)`,
  `platform.surfaces: web, ios, android, api (project.yaml)`
- `docs/stack-reference/VERSION.md` lists the pinned components with their Knowledge Risk (NestJS 11.0 MEDIUM)
- `design/product/product-brief.md`, `design/product/feature-map.md` (MVP rows `auth`, `goals`, `payments`) and the
  three MVP PRDs exist; `docs/architecture/tr-registry.yaml` registers `TR-goals-001`
- `project.yaml` has no `performance.*` keys; no `docs/architecture/architecture.md`, no `docs/ops/slo.md`

**Input:** `/create-architecture`

**Expected behavior:**
1. Phase 2 loads context silently: the stack reference (only the touched component folders), the feature map, the
   brief, and the PRDs by section grep with the denominator counted first; the Technical Requirements Baseline reuses
   `TR-goals-001` and numbers the rest provisionally; the Knowledge Risk inventory is displayed
2. Phase 3 maps features to modules per layer with one owning module per entity; on approval the skeleton is created
   after "May I write this to `docs/architecture/architecture.md`?" — every Phase 13 heading, this section filled,
   the others `TBD`
3. Phases 4–8 (topology & environments, data flow, integrations such as Kakao/Naver/Apple login, Toss Payments
   billing keys and 알림톡, security model, observability) are each presented, approved and Edited in after asking
4. Phase 9 spawns `web-specialist`, `mobile-specialist`, `backend-specialist` and `data-specialist` in parallel and
   prints `NOT CHECKED — cloud layer not configured (run /setup-stack)`
5. Phase 10a proposes budgets (web: the Core Web Vitals "good" thresholds with their source); the user decides every
   number; "May I write this to `project.yaml`?" writes only the approved `performance.*` keys
6. Phase 10b spawns `sre-engineer` with `.claude/docs/templates/slo.md`; the five sections are reviewed; "May I write
   this to `docs/ops/slo.md`?"
7. Phase 11 audits ADRs, maps every baseline requirement to coverage, and lists the required ADRs — identity & auth,
   primary data store, API style, deployment topology & environments, observability, secrets management — Foundation
   first, critical marked
8. Phase 14 spawns TD-ARCHITECTURE and TL-FEASIBILITY in parallel (both APPROVE-class); outcomes go into the header
9. Phase 13/17: `> **Verdict**: COMPLETE`; the summary follows the Phase 17 template exactly, lists the top three ADRs
   to write and the Gate-Check Readiness list for `/gate-check validation`

**Assertions:**
- [ ] The skeleton is written right after the Phase 3 approval, not at the end
- [ ] Every entity has exactly one owning module, checked against `docs/registry/architecture.yaml` `data_ownership`
- [ ] The SLO document keeps the template's five headings exactly
- [ ] An unset budget the user leaves open stays unset and is listed as an open question — never invented
- [ ] The skill never writes `docs/architecture/tr-registry.yaml`, an ADR, the contract, the data model or the threat
      model; `performance.enforce` is changed only through `/settings`
- [ ] Every PRD that contributed no requirement is reported, never dropped silently
- [ ] `performance.*`, `platform.browsers` and `platform.min_os.*` are read from `project.yaml` with Read;
      `release.distribution` and `compliance` come from the resolved block, and a part printed unset is an open
      question — never "none" or "no"

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: NOT ASSESSED — no stack, no feature map (missing input)

**Fixture:**
- (a) The config block prints `stack: unset — run /setup-stack`
- (b) The stack is configured, `workflow: standard (rigor:standard)`, but `design/product/feature-map.md` does not exist

**Input:** `/create-architecture`

**Expected behavior:**
1. (a) Phase 2a stops: "No stack is configured. Run `/setup-stack` first. …"
2. (b) Phase 2b stops: "No feature map found. Run `/map-features` first. …"
3. In both, the document is not written and the verdict `NOT ASSESSED` appears only in the run summary

**Assertions:**
- [ ] No file is written, no gate is spawned
- [ ] The verdict is `NOT ASSESSED`, never `COMPLETE`
- [ ] A present-but-empty or template-only input counts as absent
- [ ] At `workflow: minimal` the skill reads `design/product/one-pager.md` in place of the brief and feature map and
      stops only when that is absent too

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Mode Variant — `section slo` revises the SLO document

**Fixture:**
- `docs/architecture/architecture.md` (Version 2) and `docs/ops/slo.md` exist; the user adds the journey
  `auto-debit-run` after a PRD change

**Input:** `/create-architecture section slo`

**Expected behavior:**
1. Only the Phase 2 context the section needs is loaded; Phase 10b runs with `sre-engineer`
2. The current and proposed sections are shown side by side; "May I write this to `docs/ops/slo.md`?" and then the
   `## NFR Budgets` section of the architecture document after asking
3. Version becomes 3, Last Updated is set and the verdict is re-derived; because SLOs changed, the skill offers to run
   Phase 14 again (the review-mode check applies)

**Assertions:**
- [ ] `section <name>` without an existing architecture document says so and offers the full walkthrough instead
- [ ] An unknown section name lists the valid names and asks — the skill never guesses
- [ ] `docs/ops/slo.md` is never overwritten silently

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Mode Variant — `tdd goals` writes an optional technical design

**Fixture:**
- `design/prd/goals.md` exists; `docs/architecture/tdd-goals.md` does not
- Variant: `/create-architecture tdd referrals` with no `design/prd/referrals.md`

**Input:** `/create-architecture tdd goals`

**Expected behavior:**
1. The PRD sections, the owning modules, the ADRs naming the PRD, the contract and data model entries, the tracking
   events and the SLO journeys are loaded
2. The skeleton copies `.claude/docs/templates/technical-design-document.md` — its twelve headings exactly, in order —
   with every section `TBD`, after "May I write this to `docs/architecture/tdd-goals.md`?"
3. Sections are drafted and Edited in one by one; a new or changed operation is sent to `/api-design`, a new column to
   `/data-model`; a choice binding other features is listed under `## Alternatives` with `/architecture-decision`
4. A `tech-lead` review is offered as a consultation; the document stays `Draft`
5. Variant: the skill stops and points at `/write-prd referrals`

**Assertions:**
- [ ] No gate is spawned in `tdd` mode, and the technical design is never treated as a gate artifact
- [ ] The technical design's headings match the template byte for byte
- [ ] The closing widget offers `/create-stories <epic-slug>`, `/api-design update <resource>`,
      `/data-model migration <slug>` and `/architecture-decision`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Edge Case — unpinned stack and a section left `TBD`

**Fixture:**
- The `stack` line ends with ` pinned_on=unset`; the user continues anyway
- The user defers `## Integrations` ("decide after the payment vendor call") and ends the session after Phase 12

**Input:** `/create-architecture`

**Expected behavior:**
1. Phase 2a says the Architecture gate expects a pinned stack, offers `/setup-stack` first, and on continue lists the
   unpinned components as open questions
2. With a required section still `TBD`, the verdict line is `> **Verdict**: INCOMPLETE`
3. The Phase 17 summary lists the deferred section and every `NOT CHECKED` line

**Assertions:**
- [ ] A required section left `TBD` yields `INCOMPLETE`, never `COMPLETE`
- [ ] The verdict line is updated after "May I write this to `docs/architecture/architecture.md`?"
- [ ] Every HIGH or MEDIUM Knowledge Risk component the document does not address appears in `## Open Questions`
- [ ] The Phase 17 Gate-Check Readiness list carries the `/setup-stack refresh` item (`stack.pinned_on` set and a
      `docs/stack-reference/VERSION.md` row for every configured component — required at every tier)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Review Mode — `full`, TL-FEASIBILITY returns INFEASIBLE

**Fixture:**
- Case 1 state at Phase 14; `review_mode: full (project.yaml)`
- TD-ARCHITECTURE replies `[TD-ARCHITECTURE]: APPROVE`; TL-FEASIBILITY replies `[TL-FEASIBILITY]: INFEASIBLE`
  (separate services for every feature are beyond a two-engineer team)

**Input:** `/create-architecture`

**Expected behavior:**
1. Both gates are spawned in parallel — both `Agent` calls before either result; each prompt tells the agent to read
   its gate file first
2. TD-ARCHITECTURE Pass items: `docs/architecture/architecture.md`; `docs/ops/slo.md`; the `stack` line as printed;
   the MVP PRD paths
3. TL-FEASIBILITY Pass items: the document path; the `stack` line; the `team.size` line as the bootstrap block printed it
4. `INFEASIBLE` is REJECT-class: the blockers are presented, the named sections revised with the user and the gate
   re-run; until then the verdict is `INCOMPLETE`
5. Both assessments are shown side by side

**Assertions:**
- [ ] The strictest class wins: one REJECT-class verdict overrides the APPROVE-class one
- [ ] CONCERNS-class offers `Revise flagged items` / `Accept and proceed` / `Discuss further`
- [ ] An unparseable first line is CONCERNS-class with a note that the verdict line was missing
- [ ] Outcomes are recorded as `> **Technical Director Review (TD-ARCHITECTURE)**: APPROVED <date>` and
      `> **Tech Lead Review (TL-FEASIBILITY)**: <outcome> <date>` after asking

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: Review Mode — `lean` skips both gates by the suffix rule

**Fixture:**
- Case 1 state; the config block prints `review_mode: lean (rigor:standard)`

**Input:** `/create-architecture`

**Expected behavior:**
1. Phase 9 (stack lead review) and Phase 10b (`sre-engineer`) still run — they are consultations
2. Phase 14 skips TD-ARCHITECTURE and TL-FEASIBILITY; the header records `> [TD-ARCHITECTURE] skipped — Lean mode`
   and `> [TL-FEASIBILITY] skipped — Lean mode`
3. With every required section written and the SLO document present, the verdict is `COMPLETE`

**Assertions:**
- [ ] The SKILL.md review-mode check contains the sentence
      `` `lean` → **skip every gate whose ID does not end in `-PHASE-GATE`**. Note: `[GATE-ID] skipped — Lean mode` ``
- [ ] No `technical-director` or `tech-lead` gate spawn in lean mode
- [ ] The skip notes are in the document header, and the Phase 17 summary shows `skipped — Lean mode` for each gate

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 8: Review Mode — `solo`

**Fixture:**
- The config block prints `review_mode: solo (rigor:minimal)` and `workflow: minimal (rigor:minimal)`; the user runs
  the skill voluntarily with `design/product/one-pager.md` present

**Input:** `/create-architecture`

**Expected behavior:**
1. The skill says the architecture document is not required at `minimal` and reads the one-pager's
   `## Core User Journey`, `## Stack` and `## Build Order`
2. Phase 14 skips both gates with `[TD-ARCHITECTURE] skipped — Solo mode` and `[TL-FEASIBILITY] skipped — Solo mode`

**Assertions:**
- [ ] No gate agent is spawned in solo mode
- [ ] The skill never writes `project.stage`, any `modes.*` key or any rigor-fronted knob
- [ ] Topology and environments are described, never applied — no deploy, provisioning or migration is run

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses "May I write this to `<path>`?" before every write; a multi-file change lists every file and asks once
- [ ] Presents the Knowledge Risk inventory, the requirements baseline and each section proposal before asking for
      approval; never asks approval for a section the user has not seen
- [ ] Ends with the Phase 17 summary and a closing `AskUserQuestion` offering only the steps that apply
- [ ] Announces every skip — each unset layer, each skipped consultation or gate — as a `NOT CHECKED` or skip line
- [ ] Never edits the repository-root `CLAUDE.md`; never commits

**Authoring rubric** (`CCSS Skill Testing Framework/quality-rubric.md` § `authoring`):

- [ ] A1 — Section-by-section cycle: each architecture section is proposed, approved and written before the next
- [ ] A2 — "May I write" before the skeleton and each section write
- [ ] A3 — Retrofit: an existing architecture document is updated section by section or re-versioned after showing
      the differences, never overwritten silently; an existing technical design offers section updates
- [ ] A4 — TD-ARCHITECTURE and TL-FEASIBILITY run in `full`, are skipped with named notes in `lean` and `solo`
- [ ] A5 — Skeleton headings byte-identical to the template file: `docs/ops/slo.md` keeps the five headings of
      `.claude/docs/templates/slo.md`, a technical design the twelve headings of
      `.claude/docs/templates/technical-design-document.md`; the architecture skeleton carries every heading of the
      Phase 13 structure

---

## Coverage Notes

- The architecture document's structure is defined inline in the skill (Phase 13) rather than in a template file;
  A5 is asserted against that structure for the architecture document.
- Integration-specific content (Kakao, Naver, Apple login; Toss Payments; APNs/FCM; 알림톡) and regional compliance
  topics depend on the product and are asserted only as items to verify, never as legal facts.
- The HIGH-risk prompt (`[A] Proceed` / `[B] Let me check the stack reference first` / `[C] Show me …`) is not given
  its own case.
