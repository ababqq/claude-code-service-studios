# Skill Test Spec: /architecture-decision

## Skill Summary

`/architecture-decision` creates, retrofits or accepts an Architecture Decision Record. A new ADR is drafted from
`.claude/docs/templates/architecture-decision-record.md` — every heading, its order and every bold field label kept
exactly (`## Status`, `## Date`, `## Last Verified`, `## Decision Makers`, `## Summary`, `## Stack Compatibility`,
`## ADR Dependencies`, `## Context`, `## Decision`, `## Alternatives Considered`, `## Consequences`, `## Risks`,
`## Performance & SLO Implications`, `## Security & Privacy Implications`, `## Cost Implications`,
`## Migration Plan`, `## Validation Criteria`, `## PRD Requirements Addressed`, `## Related`) — after a registry check
of `docs/registry/architecture.yaml` and a confirm/adjust round on assumptions. `## Stack Compatibility` is filled
from `docs/stack-reference/` (components with pinned versions, Domain, Layer, Knowledge Risk, references consulted).
The ADR is written to `docs/architecture/adr-NNNN-<slug>.md` with `## Status` **`Proposed`** — always, for a new ADR.

The routed stack lead(s) for the ADR's Domain and `tech-lead` validate the draft; then, under the review-mode rules,
the director reviews run in parallel: **TD-ADR** (`technical-director`, always), **TD-STACK-RISK**
(`technical-director`, once per component with Knowledge Risk HIGH or MEDIUM) and **SE-SECURITY-REVIEW**
(`security-engineer`, when the Domain is `Auth`, `Security` or `Data`). Outcomes — or the review-mode skip notes — are
recorded in `## Decision Makers`. New stances are appended to `docs/registry/architecture.yaml` after approval.

`accept <ADR-id>` is the only path that moves an ADR from `Proposed` to `Accepted`: it refuses when dependencies are
absent, `UNKNOWN` or not Accepted, requires the review records, always asks the user, then unblocks the stories whose
header matches `^> \*\*Status\*\*: Blocked` and name the ADR, and proposes `docs/architecture/tech-radar.md` entries.
`retrofit <path>` adds missing template sections to an existing ADR without touching existing content.

Assertions quote the canonical English text of `.claude/skills/architecture-decision/SKILL.md`; prompts are rendered
in the user's conversation language at run time (`.claude/docs/coding-standards.md` § Language Policy) and this spec
never asserts the runtime wording.

---

## Static Assertions (Structural)

Verified automatically by `/skill-test static` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] `name: architecture-decision` equals the directory name (`.claude/skills/architecture-decision/`) and this
      spec's basename
- [ ] `argument-hint` is `"[title | retrofit <path> | accept <ADR-id>] [--review full|lean|solo]"`
- [ ] The first body line is exactly
      `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,automation_always_ask,workflow,docs.density,team.size,stack,compliance` ``
      — the `--keys` value is exactly `review_mode,automation,automation_always_ask,workflow,docs.density,team.size,stack,compliance`
- [ ] `allowed-tools` contains the grant naming this skill's own directory:
      `Bash(bash "*/.claude/skills/architecture-decision/../../hooks/yaml-helper.sh" resolve_config *)`
- [ ] `allowed-tools` is exactly the set Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion plus that grant — no
      plain `Bash`, no MCP tool names
- [ ] The line after the bootstrap block is exactly: ``Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] The automation prelude block — from `**Automation mode**: Resolve` to `categories always prompt).` — follows
      that line verbatim
- [ ] The bootstrap line is the only `!` injection in the file; no `file:line` citation of another file
- [ ] `model: sonnet`; no `disable-model-invocation` and no `isolation` key
- [ ] Has ≥2 phase headings (`## 0.` through `## 6.`)
- [ ] Contains the status values `Proposed`, `Accepted`, `Superseded by ADR-NNNN`, `Deprecated`, the gate tokens
      `APPROVE` / `CONCERNS` / `REJECT`, and the PRD-sync result `NOT ASSESSED`
- [ ] Names every output: `docs/architecture/adr-NNNN-<slug>.md`, `docs/registry/architecture.yaml`,
      `docs/architecture/tech-radar.md`
- [ ] Contains "May I write this to `<path>`?" before the ADR write, the `## Decision Makers` records, the registry
      append and the tech radar update
- [ ] States that the ADR is drafted by reading and filling the template — no inline ADR skeleton
- [ ] Carries the three `Pass:` lines verbatim:
      `` Pass: ADR path · Knowledge Risk of the ADR's components (from `docs/stack-reference/VERSION.md`) · related ADR paths `` (TD-ADR),
      `` Pass: component and version change (old → new, or pinned version) · `docs/stack-reference/<component>/` path · ADR paths whose `## Stack Compatibility` names the component `` (TD-STACK-RISK),
      `` Pass: artifact path (contract, data model or ADR) · operations or entities with auth scope and PII classification · resolved `compliance` line · `docs/security/threat-model.md` path (or "none") `` (SE-SECURITY-REVIEW)
- [ ] Names the `architecture_decisions` always-ask category for accepting, superseding or deprecating an ADR
- [ ] Has a next-step handoff at the end (Step 6 widget and the fixed fresh-session `/architecture-review` notice)

---

## Director Gate Checks

Director reviews run in Step 5.5, after the ADR is written as `Proposed` (the reviews need the file on disk). Which
gates apply:

| Gate | Condition | Agent |
|---|---|---|
| TD-ADR | always | `technical-director` |
| TD-STACK-RISK | a `**Stack Components**` entry has Knowledge Risk HIGH or MEDIUM — one spawn per such component | `technical-director` |
| SE-SECURITY-REVIEW | the ADR's Domain is `Auth`, `Security` or `Data` | `security-engineer` |

In `full` mode: every applicable gate spawns in parallel (all `Agent` calls before any result). The strictest class
wins. No gate outcome sets the status to `Accepted` — acceptance is a separate, user-confirmed step (`accept` mode).

In `lean` mode: the lean suffix rule skips every applicable gate (none ends in `-PHASE-GATE`); `## Decision Makers`
records `> [TD-ADR] skipped — Lean mode` and likewise for each gate whose condition held.

In `solo` mode: all gates skipped; notes read `— Solo mode`.

A retrofitted ADR goes through the same reviews before it can be accepted.

---

## Test Cases

### Case 1: Happy Path, Full Mode — new ADR for identity & auth; gates approve, status stays Proposed

**Fixture:**
- Moa; the config block prints `review_mode: full (project.yaml)`, `team.size: individual (rigor:standard)`,
  `stack: web=Next.js 15.3 @apps/web,apps/admin; mobile=React Native (Expo) 0.79 @apps/mobile; backend=NestJS 11.0 @apps/api,services/worker; data=PostgreSQL 16; unset=cloud [routing: web-specialist>nextjs-specialist, mobile-specialist>react-native-specialist, backend-specialist>node-specialist, data-specialist] (project.yaml)`
- `docs/stack-reference/VERSION.md` lists NestJS 11.0 with Knowledge Risk MEDIUM, PostgreSQL 16 LOW
- `docs/architecture/` has no ADR yet; `docs/registry/architecture.yaml` exists with no relevant stance;
  `design/prd/auth.md` exists with `TR-auth-001` registered
- `project.yaml` sets `compliance.regions: [kr]` and `privacy.handles_pii: true`

**Input:** `/architecture-decision identity-and-auth`

**Expected behavior:**
1. Step 1 reads the stack reference, identifies Domain `Auth` and Layer `Foundation`, reads the MEDIUM component's
   folder and displays the STACK KNOWLEDGE GAP WARNING
2. Step 2 assigns `docs/architecture/adr-0001-identity-and-auth.md` (four-digit number, never reused)
3. Step 3a presents the registry stances as locked constraints before design begins
4. Step 4 presents the assumptions via `AskUserQuestion` (problem, 2–3 alternatives, PRD linkage with TR-IDs,
   dependencies, `Status: Proposed`) and waits for confirmation
5. Step 5.1 fills the template: `## Status` `Proposed`, `## Stack Compatibility` from Step 1, `## PRD Requirements Addressed`
   as `| PRD | Requirement (TR-ID) | How addressed |`
6. Step 5.2 spawns the routed stack leads for Domain `Auth` — `backend-specialist`, plus `web-specialist` and
   `mobile-specialist` because client sign-in flows change — and `tech-lead`; at `team.size: small` the routed
   sub-specialist (`node-specialist`) is added, at `studio` an adversarial review by an adjacent-layer lead
7. Step 5.3 reports `PRD sync: checked 1 referenced PRD(s), no naming inconsistencies.`
8. Step 5.4: "ADR draft is complete. May I write this to `docs/architecture/adr-0001-identity-and-auth.md`?"
9. Step 5.5 spawns TD-ADR, TD-STACK-RISK (NestJS 11.0, MEDIUM) and SE-SECURITY-REVIEW (Domain `Auth`) in parallel;
   all return APPROVE
10. Step 5.6 records the three lines in `## Decision Makers` after asking; Step 5.7 offers the registry candidates

**Assertions:**
- [ ] The written ADR's headings are byte-identical to the template, in order, in English
- [ ] `## Status` is `Proposed` even though every gate returned APPROVE
- [ ] TD-ADR, TD-STACK-RISK and SE-SECURITY-REVIEW spawn in parallel (not sequentially)
- [ ] The records read `> **Technical Director Review (TD-ADR)**: APPROVED <date>`,
      `> **Technical Director Review (TD-STACK-RISK)**: APPROVED <date>`,
      `> **Security Engineer Review (SE-SECURITY-REVIEW)**: APPROVED <date>`
- [ ] The SE-SECURITY-REVIEW `compliance` item is the resolved `compliance` line as printed
      (`compliance: regions=kr handles_pii=true (project.yaml)`)
- [ ] `## Security & Privacy Implications` takes the regions and `handles_pii` from that resolved line; had a part
      printed `(unset -- ask)`, the section would record it as "unset — ask", never "none"
- [ ] The closing output includes the fixed notice to run `/architecture-review` in a fresh session and lists the
      stories still `Blocked` pending this ADR — no story is unblocked on authoring

---

### Case 2: Failure Path — TD-ADR returns CONCERNS

**Fixture:**
- ADR draft written as `Proposed`; `review_mode: full (project.yaml)`
- TD-ADR's first reply line is `[TD-ADR]: CONCERNS` ("the refresh-token rotation policy is not specified")

**Input:** `/architecture-decision [topic]`

**Expected behavior:**
1. TD-ADR spawns and returns CONCERNS with specific feedback
2. The concerns are presented via `AskUserQuestion`: `Revise flagged items` / `Accept and proceed` / `Discuss further`
3. The ADR stays `Proposed` in every branch
4. Revising edits the affected sections after "May I write this to `docs/architecture/adr-NNNN-<slug>.md`?"

**Assertions:**
- [ ] The concerns are shown to the user before any decision
- [ ] `## Status` stays `Proposed`; nothing in this run sets it to `Accepted`
- [ ] The outcome is recorded as `REVISED <date>` or `CONCERNS (accepted) <date>`
- [ ] A REJECT-class verdict requires revision and a re-run of that gate; the ADR cannot be accepted while it stands
- [ ] A first line that does not parse, or names another gate, is treated as CONCERNS-class and the missing verdict
      line is named

---

### Case 3: Lean Mode — every applicable gate skipped by the suffix rule; ADR written as Proposed

**Fixture:**
- The config block prints `review_mode: lean (rigor:standard)`
- A new Domain `Data` ADR with a MEDIUM-risk component

**Input:** `/architecture-decision primary-data-store`

**Expected behavior:**
1. Authoring runs as in Case 1 (stack specialists and `tech-lead` still validate — they are not gates)
2. Step 5.5 applies the review-mode check: TD-ADR, TD-STACK-RISK and SE-SECURITY-REVIEW all apply by condition and
   none ends in `-PHASE-GATE`, so all three are skipped
3. `## Decision Makers` records `> [TD-ADR] skipped — Lean mode`, `> [TD-STACK-RISK] skipped — Lean mode`,
   `> [SE-SECURITY-REVIEW] skipped — Lean mode` after "May I write this to …?"

**Assertions:**
- [ ] The SKILL.md review-mode check contains the sentence
      `` `lean` → **skip every gate whose ID does not end in `-PHASE-GATE`**. Note: `[GATE-ID] skipped — Lean mode` ``
- [ ] No director agent is spawned in lean mode
- [ ] The skip notes are recorded in the ADR, where acceptance mode reads them
- [ ] The ADR is written as `Proposed`

---

### Case 4: Edge Case — the proposed decision contradicts a registered stance

**Fixture:**
- `docs/registry/architecture.yaml` `forbidden_patterns` holds `client_computed_charge_amount (ADR-0007)`
- The user proposes that the mobile app computes the monthly auto-debit amount and sends it to the API

**Input:** `/architecture-decision auto-debit-scheduling`

**Expected behavior:**
1. Step 3a presents the existing stances before the collaborative design begins
2. The conflict is surfaced immediately with the options: align with the existing stance, supersede ADR-0007 with an
   explicit replacement, or explain why this case is an exception
3. Step 4 does not start until the conflict is resolved or accepted as an intentional exception

**Assertions:**
- [ ] The registry is read before any existing ADR (registry-scoped reads, never glob-and-read every ADR)
- [ ] No draft is generated while the conflict is unresolved
- [ ] A superseding path records the relationship in `## Related`; the old registry entry is marked
      `status: "superseded_by: ADR-NNNN"` (quoted — an unquoted second colon is not valid YAML) — entries are never
      deleted

---

### Case 5: Acceptance Mode — `accept ADR-0001` unblocks stories only after the user confirms

**Fixture:**
- `docs/architecture/adr-0001-identity-and-auth.md` is `Proposed`, `## ADR Dependencies` reads `**Depends On**: None`,
  and `## Decision Makers` carries the TD-ADR, TD-STACK-RISK and SE-SECURITY-REVIEW record lines
- `production/epics/auth-core/story-002-kakao-login.md` has `> **Status**: Blocked` and names `ADR-0001` in
  `**ADR Governing Implementation**`; its `production/sprint-status.yaml` entry is `status: blocked`

**Input:** `/architecture-decision accept ADR-0001`

**Expected behavior:**
1. The id resolves to exactly one file; the status is `Proposed`; the dependencies are examined, not empty
2. The review records are present (a missing one runs Step 5.5 first)
3. The blocked stories are found by grepping `production/epics/*/story-*.md` for `^> \*\*Status\*\*: Blocked` and the
   ADR id, and paired with their `status: blocked` entries — before the prompt
4. `AskUserQuestion` "Accept ADR-0001 — … ?" lists the files that change (the ADR, the story, the sprint-status entry);
   options `[A] Yes — accept it` / `[B] Not yet — leave it Proposed`
5. On yes: `## Status` → `Accepted`, `## Date` set; the story → `> **Status**: Ready` and `status: ready-for-dev`;
   tech radar entries proposed in the format `- **<name>** — <why> (ADR-0001)` after "May I write this to
   `docs/architecture/tech-radar.md`?"

**Assertions:**
- [ ] The acceptance prompt fires at every automation mode, including `autonomous`
- [ ] Acceptance authority is the user (or `technical-director` on the user's explicit confirmation) — never the skill
- [ ] Stories are matched only under `production/epics/`; a story blocked on another unaccepted ADR stays `Blocked`
- [ ] An ADR that is `Deprecated` or `Superseded by ADR-NNNN` is refused; an already `Accepted` one is reported and
      the run stops
- [ ] For a `Data` or `Infra` ADR, or a component recorded as "not pinned", the run hands off to `/setup-stack refresh`

---

### Case 6: NOT ASSESSED — PRD sync with no PRD to compare, and acceptance with an unexamined dependency list (missing input)

**Fixture:**
- (a) A foundational ADR (`observability`) whose `## PRD Requirements Addressed` reads
  "Foundational — no PRD requirement. Enables: …"
- (b) `accept ADR-0004` where `## ADR Dependencies` is absent

**Input:** (a) `/architecture-decision observability` · (b) `/architecture-decision accept ADR-0004`

**Expected behavior:**
1. (a) Step 5.3 prints `PRD sync: NOT ASSESSED — <reason and files>` — an ADR that names no PRD is not treated as one
   whose PRDs are consistent
2. (b) Acceptance refuses: the dependency section is absent, so the skill cannot tell what the decision rests on, and
   points at `/architecture-decision retrofit <path>`

**Assertions:**
- [ ] (a) The PRD-sync check always reports — found, none found, or NOT ASSESSED; it is never silent
- [ ] (b) An absent, empty or `UNKNOWN` dependency section is never read as "no dependencies"; the ADR stays
      `Proposed` and nothing else changes
- [ ] (b) An ADR depending on a non-Accepted ADR is refused with the dependency named

---

### Case 7: Retrofit Mode — add missing sections without touching existing content

**Fixture:**
- `docs/architecture/adr-0002-primary-data-store.md` exists in another format: a bold `**Status**: Accepted` line,
  no `## Status`, no `## ADR Dependencies`, no `## Stack Compatibility`

**Input:** `/architecture-decision retrofit docs/architecture/adr-0002-primary-data-store.md`

**Expected behavior:**
1. The file and the template are read; `## Status` is reported missing (BLOCKING) — the bold line does not count, and
   its value is offered as the answer
2. The retrofit summary lists present sections (untouched) and missing ones with their severity
3. "Shall I add the [N] missing sections? I will not modify any existing content."
4. Each missing section is inserted with Edit at its template position; `## Date` is added if absent
5. The retrofitted ADR goes through the Step 5.5 reviews before it can be accepted

**Assertions:**
- [ ] No existing section is modified
- [ ] An answer of `Accepted` for Status records what the team decided but remains subject to the acceptance
      authority rule, and the skill says so
- [ ] The closing suggestion is `/architecture-review` in a fresh session

---

### Case 8: Solo Mode — all gates skipped

**Fixture:**
- The config block prints `review_mode: solo (rigor:minimal)` and `workflow: minimal (rigor:minimal)`
- The user writes an ADR voluntarily (not required at `minimal`)

**Input:** `/architecture-decision api-style`

**Expected behavior:**
1. Authoring runs; the ADR is written `Proposed`
2. Step 5.5 skips every applicable gate: `> [TD-ADR] skipped — Solo mode` (and TD-STACK-RISK when a MEDIUM/HIGH
   component is touched) recorded in `## Decision Makers`
3. The closing widget offers `/api-design` because this ADR decided the API style

**Assertions:**
- [ ] No director agent is spawned in solo mode
- [ ] The skip notes read exactly `[<GATE-ID>] skipped — Solo mode`
- [ ] The skill never writes `modes.review_mode` or any other rigor-fronted knob, and never writes the TR registry

---

## Protocol Compliance

- [ ] The ADR is drafted from the template file — every heading and bold field label kept, never written from memory
- [ ] `## Stack Compatibility` is filled from `docs/stack-reference/`; where the reference is silent the ADR says
      `NOT SOURCEABLE — run /setup-stack refresh`
- [ ] "May I write this to `<path>`?" is asked before the ADR, the review records, the registry and the tech radar
- [ ] Applicable gates spawn in parallel in `full` mode; skipped gates are noted by name and mode in `lean`/`solo`
- [ ] `Accepted` is set only in `accept` mode, after the user's confirmation
- [ ] Ends with the Step 6 widget and the fixed fresh-session `/architecture-review` notice

**Authoring rubric** (`CCSS Skill Testing Framework/quality-rubric.md` § `authoring`):

- [ ] A1 — Lightweight single-draft pattern: assumptions confirmed, the complete ADR drafted and approved once
- [ ] A2 — "May I write" once for the ADR, then for each follow-up write (records, registry, tech radar)
- [ ] A3 — Retrofit mode adds only missing sections to an existing ADR
- [ ] A4 — TD-ADR, TD-STACK-RISK and SE-SECURITY-REVIEW run in `full` when their conditions hold, are skipped with
      named notes in `lean` and `solo`
- [ ] A5 — Skeleton headings byte-identical to the template file (`.claude/docs/templates/architecture-decision-record.md`)

---

## Coverage Notes

- ADR numbering (four-digit, highest existing + 1, never reusing Superseded or Deprecated numbers) is not
  independently fixture-tested.
- The `team.size` widening (`small` adds the routed sub-specialist; `studio` adds an adversarial adjacent-layer lead)
  is covered only through Case 1.
- The PRD-sync "found" branch (renamed operations → `PRD SYNC REQUIRED` block and the combined write option) is not
  given its own case.
- `docs.density` changes prose depth only; the structural tables stay whole at every density — not fixture-tested.
