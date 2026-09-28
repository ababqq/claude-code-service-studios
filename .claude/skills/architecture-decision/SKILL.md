---
name: architecture-decision
description: "Create, retrofit or accept an ADR: context, alternatives, consequences, stack compatibility, PRD requirements addressed."
argument-hint: "[title | retrofit <path> | accept <ADR-id>] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/architecture-decision/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,automation_always_ask,workflow,docs.density,team.size,stack,compliance`

Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).


When this skill is invoked:

## 0. Parse Arguments — Detect Retrofit / Acceptance Mode


See `.claude/docs/director-gates.md` for the full check pattern. Individual gate definitions live in `.claude/docs/director-gates/<gate-id>.md` — the spawned agent reads its own gate file; do not read it in the parent session.

**Always-ask category**: accepting, superseding or deprecating an ADR is the
`architecture_decisions` category of `.claude/docs/automation-modes.md`. It
prompts whenever the resolved `automation_always_ask` list contains it — and the
acceptance prompt in acceptance mode fires at every automation mode regardless
(see step 6 there).

**`team.size`**: which agents validate this ADR (orthogonal to review_mode/workflow).
- **`individual`**: `technical-director` (through its gates) + `tech-lead` + the
  routed stack lead(s) for the ADR's Domain.
- **`small`**: + the routed sub-specialist where the `stack` line's routing names
  one (e.g. `backend-specialist>node-specialist` adds `node-specialist`).
- **`studio`**: + an adversarial review by a second stack lead from an adjacent
  layer (for a Data decision `backend-specialist`; for an Infra decision
  `backend-specialist` or `data-specialist`; for an API decision `web-specialist`
  or `mobile-specialist` as a consumer).
Any non-core agent needed at `individual` routes through the nearest active core agent with a note.

**Routing by Domain** — the Domain row of `## Stack Compatibility` decides which
layers' leads validate the decision (Step 5.2); the lead and sub-specialist of
each layer come from the routing part of the resolved `stack` line:

| Domain | Layers consulted |
|--------|------------------|
| `API` | backend |
| `Data` | data, backend |
| `Auth` | backend; web and mobile when client sign-in flows change |
| `Security` | backend |
| `Frontend` | web |
| `Mobile` | mobile |
| `Infra` | cloud |
| `Messaging` | data, backend |
| `Observability` | cloud, backend |
| `Integrations` | backend |
| `ML` | backend |

A layer the `stack` line lists under `unset=` has no specialist: print
`NOT CHECKED — <layer> layer not configured (run /setup-stack)` for it. That is
expected when this ADR is the decision that *chooses* the layer (the primary data
store, the cloud provider): data and cloud may stay unset until their Foundation
ADRs are accepted, and acceptance mode hands off to `/setup-stack refresh`.

**`docs.density`** — it controls the *depth* of the ADR's prose sections, not
which sections the template emits (that is fixed). `modes.rigor` sets it
alongside `workflow`; set `docs.density` explicitly to vary ADR verbosity alone:
`terse` = decision + alternatives as bullets, one line of rationale each;
`balanced` = paragraph per section with light rationale; `thorough` =
full prose with trade-offs and worked rationale in Decision, Alternatives, and
Consequences. Apply it to the prose sections; the Stack Compatibility, ADR
Dependencies, and PRD Requirements Addressed tables are structural and stay whole
at every density.

**`workflow`** (see `.claude/docs/workflow-modes.md`):
- `full` — every ADR on the required-ADR list of `docs/architecture/architecture.md` must be completed.
- `standard` — critical ADRs only (the Foundation-layer ADRs the architecture document marks critical).
- `minimal` — not required. Can still be run voluntarily.

**If the argument starts with `retrofit` followed by a file path**
(e.g., `/architecture-decision retrofit docs/architecture/adr-0001-identity-and-auth.md`):

Enter **retrofit mode**:

1. Read the existing ADR file completely, and read
   `.claude/docs/templates/architecture-decision-record.md` for the heading list.
2. Identify which template sections are present by scanning headings:
   - `## Status` — **BLOCKING if missing**: `/story-readiness` cannot check ADR acceptance
   - `## ADR Dependencies` — HIGH if missing: dependency ordering breaks
   - `## Stack Compatibility` — HIGH if missing: post-cutoff risk unknown
   - `## PRD Requirements Addressed` — MEDIUM if missing: traceability lost
   - `## Security & Privacy Implications` — MEDIUM if missing: authorization and personal-data effects unrecorded
   - `## Performance & SLO Implications` — LOW if missing
   - any other template heading — LOW if missing

   A status recorded outside a `## Status` section (a bold `**Status**:` line or
   a front-matter field, as other ADR formats write it) does not count: the
   section is missing, and the recorded value is offered as the answer.
3. Present to the user:
   ```
   ## Retrofit: [ADR title]
   File: [path]

   Sections already present (will not be touched):
   ✓ Status: [current value, or "MISSING — will add"]
   ✓ [section]

   Missing sections to add:
   ✗ Status — BLOCKING (stories cannot validate ADR acceptance without this)
   ✗ ADR Dependencies — HIGH
   ✗ Stack Compatibility — HIGH
   ```
4. Ask: "Shall I add the [N] missing sections? I will not modify any existing content."
5. If yes:
   - For **Status**: ask the user — "What is the current status of this decision?"
     Options: "Proposed", "Accepted", "Deprecated", "Superseded by ADR-NNNN".
     An answer of "Accepted" records what the team already decided; it is still
     subject to the authority rule of acceptance mode — say so.
   - For **ADR Dependencies**: ask — "Does this decision depend on any other ADR?
     Does it enable or block any other ADR or epic?" Accept "None" for each field.
   - For **Stack Compatibility**: read the stack reference (same as Step 1 below)
     and ask the user to confirm the Domain and the Layer. Then generate the table
     with verified data.
   - For **PRD Requirements Addressed**: ask — "Which PRDs motivated this decision?
     Which requirement in each does this ADR address?" Offer the TR-IDs found in
     `docs/architecture/tr-registry.yaml` for those PRDs.
   - For **Security & Privacy Implications** and **Performance & SLO Implications**:
     derive a draft from the Decision section and Step 1, then confirm.
   - For any other missing section: ask, or write `NOT DETERMINED — <reason>`.
   - Insert each missing section with the Edit tool at its template position
     (after the nearest preceding template heading present in the file).
   - **Never modify any existing section.** Only add or fill absent sections.
6. After adding all missing sections, add the ADR's `## Date` section if it is absent.
7. A retrofitted ADR goes through the director reviews of Step 5.5 before it can
   be accepted — the same gates, conditions and review-mode check.
8. Suggest: "Run `/architecture-review` in a fresh session to re-validate coverage
   now that this ADR has its Status and Dependencies fields."

**If the argument starts with `accept` followed by an ADR id**
(e.g., `/architecture-decision accept ADR-0005`):

Enter **acceptance mode**. This is the *only* path in the framework that moves an
ADR from `Proposed` to `Accepted`. Authoring always produces `Proposed`
(Step 5), while
`/create-control-manifest`, `/create-epics`, `/create-stories` and `/gate-check`
all require `Accepted` — so without this mode the pipeline had a state it could
enter and never leave.

1. **Resolve the id to a file, then read it.** Glob
   `docs/architecture/adr-NNNN-*.md` for the given number. If **no** file matches,
   or **more than one** does, stop and say which — do not pick one. If the file
   has no `## Status` section, stop and say so; a missing Status is exactly what
   retrofit mode is for.
2. **Check the current status.** If it is already `Accepted`, say so and stop.
   If it is `Deprecated` or `Superseded by ADR-NNNN`, refuse: reviving a superseded
   decision is a new ADR, not a status edit.
3. **Check its dependencies first.** Read `## ADR Dependencies`.

   **If that section is absent, empty, or reads `UNKNOWN`, do not read it as
   "no dependencies" — refuse and say which:**
   > "ADR-0005's dependency section is [absent / UNKNOWN], so I cannot tell what
   > this decision rests on. An empty dependency list and an unexamined one look
   > identical here, and only one of them is safe to accept. Run
   > `/architecture-decision retrofit <path>` to establish it."

   A dependency check reading a field that defaults to empty is the vacuous-pass
   shape this gate exists to prevent — the check would examine nothing and report
   clean.

   If it depends on any ADR that is not itself `Accepted`, **refuse and name them**:
   > "ADR-0005 depends on ADR-0002, which is still Proposed. Accept ADR-0002
   > first — an accepted decision resting on an unaccepted one is not a decision,
   > it is a deferral with a different label."
   This is the same dependency rule `/architecture-review` already flags; here it
   is enforced rather than reported.
4. **Check the director review.** Read `## Decision Makers` for the record line of
   TD-ADR — `> **Technical Director Review (TD-ADR)**: APPROVED …`,
   `CONCERNS (accepted) …` or `REVISED …`, or the skip note
   `> [TD-ADR] skipped — <Mode> mode`. The same applies to TD-STACK-RISK and
   SE-SECURITY-REVIEW when their conditions hold for this ADR (Step 5.5). If a
   required line is absent, run Step 5.5 now, before anything else in this mode.
   A REJECT-class verdict refuses acceptance: the ADR stays `Proposed` until it is
   revised and reviewed again.
5. **Find the stories this will unblock, BEFORE the prompt in step 6.** Grep
   `production/epics/*/story-*.md` — the one place stories live — for files
   whose header matches `^> \*\*Status\*\*: Blocked` **and** that contain this
   ADR's id (`ADR-NNNN`, case-insensitive — usually in
   `**ADR Governing Implementation**`). Then read `production/sprint-status.yaml`
   and pair each such story with its entry whose `status: blocked`.
   > **Stories live only under `production/epics/`.** A flat top-level stories
   > directory does not exist and no skill creates one — never write or match a
   > path outside `production/epics/`. `/dev-story` matches entries *by file
   > path*, so a story recorded under any other path silently fails to match and
   > never gets picked up. That pairing is what "blocked pending this
   > ADR" means — a story blocked for an unrelated reason will not name it.
   A story that also names another ADR which is still not `Accepted` stays
   `Blocked`; list it with that ADR. Feed the count into step 6's prompt so it
   reads *"3 stories become Ready"* rather than a generic claim: **the user is
   being asked to authorise an effect, and should be shown the effect.** If none
   match, say "no stories are waiting on this" — that is useful information, not
   an empty result to omit.
6. **Confirm with the user, always.** Per `CONTRACT.md`, acceptance authority is
   **the user, or `technical-director` on the user's explicit confirmation — no
   other agent, and never this skill on its own.** Use `AskUserQuestion`:
   - Prompt: "Accept ADR-NNNN — [title]? This is what unblocks stories and epics
     that depend on it." — followed by the list of files this changes: the ADR,
     the stories and sprint-status entries of step 5, and an ADR this one
     supersedes (step 7).
   - Options: `[A] Yes — accept it` / `[B] Not yet — leave it Proposed`
   **This prompt fires regardless of `modes.automation`, including `autonomous`.**
   Acceptance is the decision the whole architecture pipeline gates on; it is not
   a step to be inferred.
7. On confirmation, `Edit` the `## Status` line to `Accepted`. Set the date in the
   ADR's `## Date` section to the acceptance date; **if that section is absent,
   add it** — retrofit mode already owns this shape, and acceptance must not fail
   on a record that predates the field. If this ADR's `## Related` section says it
   supersedes an ADR, set that ADR's `## Status` to `Superseded by ADR-NNNN` in the
   same approved changeset, and mark its entries in `docs/registry/architecture.yaml`
   `status: "superseded_by: ADR-NNNN"` (quoted — an unquoted second colon is not
   valid YAML).
8. Then set each story found in step 5 from `> **Status**: Blocked` to
   `> **Status**: Ready`, and its `production/sprint-status.yaml` entry from
   `status: blocked` to `status: ready-for-dev`. Unblocking is a consequence of
   acceptance, never of authoring — see Step 6's note below.
9. **Tech radar.** Propose the entries this decision puts on
   `docs/architecture/tech-radar.md`, in its exact entry format
   `- **<name>** — <why> (ADR-NNNN)`: the chosen components under `## Adopt` (or
   `## Trial` with the bounded scope named in `<why>`); an `## Assess` entry this
   decision adopts moves to its new ring; components or patterns it retires go to
   `## Hold`; code patterns its Implementation Guidelines forbid go to
   `## Forbidden Patterns`. Never put versions in entry names — versions live in
   `docs/stack-reference/VERSION.md`, so an upgrade never leaves the radar stale.
   Show the diff and ask "May I write this to `docs/architecture/tech-radar.md`?"
   If the file does not exist, offer to create it from
   `.claude/docs/templates/tech-radar.md` with this ADR's entries only.
10. **Stack follow-up.** If the ADR's Domain is `Data` or `Infra`, or its
    `**Stack Components**` row lists a component as "not pinned", the pinned stack
    no longer covers what was decided: hand off to `/setup-stack refresh`, which
    configures the layer, pins the versions from live sources and writes the
    stack reference.
11. Report what moved: the ADR, its new date, every story that became Ready, every
    story still Blocked and why, the superseded ADR (if any), the tech radar
    entries, and the `/setup-stack refresh` hand-off when step 10 applies.

If NOT in retrofit or acceptance mode, proceed to Step 1 below (normal ADR authoring).

**No-argument guard**: If no argument was provided (title is empty), ask before
running Step 1:

> "What technical decision are you documenting? Please provide a short title
> (e.g., `identity-and-auth`, `primary-data-store`, `api-style`)."

Use the user's response as the title, then proceed to Step 1.

---

## 1. Load Stack Context (ALWAYS FIRST)

Before doing anything else, establish the stack environment:

1. Read `docs/stack-reference/VERSION.md` to get:
   - The model knowledge cutoff (`| **LLM Knowledge Cutoff** |`) and the pin date
     (`| **Stack Pinned** |`)
   - The Pinned Components table — one row per component: Layer, Component,
     Version, Knowledge Risk (LOW / MEDIUM / HIGH), Source, Retrieved

2. Identify the **Domain** of this architecture decision from the title or
   user description — one of `API`, `Data`, `Auth`, `Security`, `Frontend`,
   `Mobile`, `Infra`, `Messaging`, `Observability`, `Integrations`, `ML` — and its
   **Layer** (`Foundation`, `Core`, `Feature` or `Presentation`). Identity & auth,
   the primary data store, the API style, deployment topology & environments,
   observability and secrets management are Foundation.

3. List the **components** the decision touches: the Pinned Components rows of
   the layers the Domain routes to, plus any component the decision introduces
   (a candidate that is not configured yet is recorded as "not pinned" and counts
   as Knowledge Risk HIGH).

4. For each touched component with Knowledge Risk MEDIUM or HIGH, read its folder
   under `docs/stack-reference/` (glob `docs/stack-reference/*/VERSION.md` and
   match the `**Component**` row): `VERSION.md`, and where they exist
   `breaking-changes.md`, `deprecated-apis.md` and `current-best-practices.md`.
   For LOW components, `VERSION.md` and `deprecated-apis.md` (if present) are
   enough.

5. Flag every changed or deprecated API in those files that falls in this
   decision's area — none of them may appear in the Decision or Key Interfaces
   sections.

6. **Display a knowledge gap warning** before proceeding if any touched component
   carries MEDIUM or HIGH risk:

   ```
   STACK KNOWLEDGE GAP WARNING
   Components: [e.g. NestJS 11.0 — HIGH; PostgreSQL 16 — LOW]
   Domain: [e.g. Auth]
   Model knowledge cutoff: [from VERSION.md]

   Verified from docs/stack-reference/:
   - [Change 1 relevant to this decision] (Source: <url>, retrieved YYYY-MM-DD)
   - [Change 2]

   This ADR will be cross-referenced against the stack reference.
   Proceed with sourced information only — do NOT rely solely on training data.
   Where the reference is silent: NOT SOURCEABLE — run /setup-stack refresh.
   ```

   If the `stack` line reads `stack: unset — run /setup-stack` and
   `docs/stack-reference/VERSION.md` has no component rows, prompt: "No stack is
   configured. Run `/setup-stack` first, or tell me which components this decision
   concerns." A decision that chooses the data store or the cloud provider may
   proceed on a partly configured stack — its components are recorded as
   "not pinned".

---

## 2. Determine the next ADR number

Glob `docs/architecture/adr-*.md` (top level of `docs/architecture/` only). The
next number is the highest `NNNN` plus one, zero-padded to four digits — never a
number already used, including those of Superseded and Deprecated ADRs. The slug
is the title in kebab-case: `docs/architecture/adr-0001-identity-and-auth.md`.

---

## 3. Gather context

### 3a: Architecture Registry Check (BLOCKING gate) — do this FIRST

Read `docs/registry/architecture.yaml`. Extract entries relevant to this ADR's
domain and decision (grep by module name, entity, event, operation or domain
keyword) across its sections `data_ownership`, `interfaces`, `slo_budgets`,
`technology_decisions` and `forbidden_patterns`. Run this before reading any
existing ADR — the registry exists specifically so a new ADR's author does not
need to open prior ADRs to learn their binding facts (data ownership, interface
contracts, forbidden patterns). Read the `## Hold` and `## Forbidden Patterns`
sections of `docs/architecture/tech-radar.md` as well, when it exists.

Present any relevant stances to the user **before** the collaborative design
begins, as locked constraints:

```
## Existing Architectural Stances (must not contradict)

Data Ownership:
  savings_goal → owned by the goals module (ADR-0003)
  Interface: GET/POST /v1/goals (docs/api/openapi.yaml)
  → If this ADR reads or writes goals, it goes through these operations.

Interfaces:
  deposit_recorded → event goals.deposit.recorded v1, published through the outbox (ADR-0006)
  → If this ADR reacts to deposits, it consumes this event; it does not poll the table.

Forbidden Patterns:
  ✗ client_computed_charge_amount (ADR-0007)
  ✗ cross_module_table_write (ADR-0002)
  → The proposed approach must not use these patterns.
```

If the user's proposed decision would contradict any registered stance, surface
the conflict immediately:

> "Conflict: This ADR proposes [X], but ADR-[NNNN] established that [Y] is
> the accepted pattern for this purpose. Proceeding without resolving this will
> produce contradictory ADRs and inconsistent stories.
> Options: (1) Align with the existing stance, (2) Supersede ADR-[NNNN] with
> an explicit replacement, (3) Explain why this case is an exception."

Do not proceed to Step 4 (collaborative design) until any conflict is resolved
or explicitly accepted as an intentional exception.

### 3b: Existing ADRs and Related PRDs — registry-scoped, never unbounded

The registry (3a) covers *what* prior decisions bind — not always *why*. If the
registry surfaced a directly relevant ADR and its reasoning matters here (not
just its stated facts), read that specific ADR — never glob-and-read every
ADR in `docs/architecture/` on the chance one is relevant:

1. **Map its headings first** (cheap):
   ```
   Grep pattern="^## " path="docs/architecture/[adr-file].md" output_mode="content" -n
   ```
2. **Under ~50KB** — one full `Read` is fine; per-call overhead exceeds the
   savings from bounded reads at this size.
3. **~50KB or larger** — bounded-read only `## Context`, `## Decision`, and
   `## Consequences` (the sections that carry reasoning, not just facts) via
   `Read(offset, limit)` from the heading map.

If `docs/architecture/architecture.md` exists, read its required-ADR entry for this
decision (layer, critical or not, the requirements it covers) — that entry is
why this ADR is being written.

Read PRDs only when the registry, the architecture document or the ADR list names
them as directly relevant, and only the sections that carry architectural
requirements (`Grep pattern="^## (Functional Requirements|Business Rules & Calculations|Edge Cases|Dependencies|Non-Functional Requirements)" ... -A 40`)
— never a speculative full read of `design/prd/*.md` looking for anything that
might relate. Take their TR-IDs from `docs/architecture/tr-registry.yaml`.

Skip 3b entirely if the registry already answers everything this decision
needs — most ADRs will.

---

## 4. Guide the decision collaboratively

Before asking anything, derive the skill's best guesses from the context already
gathered (PRDs read, stack reference loaded, existing ADRs scanned). Then present
a **confirm/adjust** prompt using `AskUserQuestion` — not open-ended questions.

**Derive assumptions first:**
- **Problem**: Infer from the title + PRD context what decision needs to be made
- **Alternatives**: Propose 2-3 concrete options from the stack reference + PRD requirements
- **Dependencies**: Scan existing ADRs for upstream dependencies. **If the scan is
  inconclusive, present `UNKNOWN — scan inconclusive, please confirm`, never
  `None`.** The two are not interchangeable: `None` asserts that nothing upstream
  constrains this decision, and a user confirming a prefilled list cannot tell an
  assertion from a guess. This field is load-bearing — `/architecture-review`
  flags unaccepted dependencies, `/dev-story` reads it, and the acceptance route
  in Step 0 **refuses to accept an ADR whose dependencies are not themselves
  Accepted**. A dependency list that defaulted to empty makes that check pass
  while examining nothing. `UNKNOWN` must be resolved during the confirm/adjust
  prompt; it is a prompt state, never a value written to the file
- **PRD linkage**: Extract which PRDs and TR-IDs the title directly relates to
- **Status**: Always `Proposed` for new ADRs — never ask the user what the status is

**Scope of assumptions tab**: Assumptions cover only: problem framing, alternative approaches, upstream dependencies, PRD linkage, and status. Schema and data design questions (e.g., "Should a deposit be recorded in the request or by the worker?", "Should the billing-key reference live in the mandate table or in the vault?") are NOT assumptions — they are design decisions belonging to a separate step after the assumptions are confirmed. Do not include them in the assumptions AskUserQuestion widget.

**After assumptions are confirmed**, if the ADR involves schema or data design choices, use a separate multi-tab `AskUserQuestion` to ask each design question independently before drafting.

**Present assumptions with `AskUserQuestion`:**

```
Here's what I'm assuming before drafting:

Problem: [one-sentence problem statement derived from context]
Alternatives I'll consider:
  A) [option derived from the stack reference]
  B) [option derived from PRD requirements]
  C) [option from common patterns]
PRDs driving this: [list derived from context, with TR-IDs]
Dependencies: [upstream ADRs if any, "None", or "UNKNOWN — scan inconclusive, please confirm"]
Status: Proposed

[A] Proceed — draft with these assumptions
[B] Change the alternatives list
[C] Adjust the PRD linkage
[D] Add a performance or SLO budget constraint
[E] Something else needs changing first
```

Do not generate the ADR until the user confirms assumptions or provides corrections.

**After the stack specialist and director reviews return** (Steps 5.2 and 5.5),
if unresolved decisions remain, present each one as a separate `AskUserQuestion`
with the proposed options as choices plus a free-text escape:

```
Decision: [specific unresolved point]
[A] [option from specialist review]
[B] [alternative option]
[C] Different approach — I'll describe it
```

**ADR Dependencies** — derive from existing ADRs, then confirm:
- Does this decision depend on any other ADR not yet Accepted?
- Does it unlock or unblock any other ADR or epic?
- Does it block any specific epic from starting?

Record answers in the **ADR Dependencies** section. Write "None" for each field if no constraints apply.

---

## 5. Generate the ADR

5.1. **Draft from the template.** Read
`.claude/docs/templates/architecture-decision-record.md` and fill it in. It is the
single source of the ADR format: keep every heading, its order and every bold
field label exactly as the template spells them; never write the skeleton from
memory or copy it from another ADR. Drop the template's leading instruction
comment; keep everything else. Fill it as follows:

- **`## Status`**: `Proposed` — always, for a new ADR.
- **`## Date`** and **`## Last Verified`**: today.
- **`## Decision Makers`**: the roles involved; the review record lines are added
  in Step 5.6.
- **`## Stack Compatibility`**: from Step 1 — every touched component with its
  pinned version, the Domain, the Layer, the highest Knowledge Risk among the
  components, the reference files actually read, the post-cutoff APIs used and
  the verification required.
- **`## ADR Dependencies`**: from Step 4.
- **`## Performance & SLO Implications`**: budgets from the `performance.*` keys of
  `project.yaml` (read with Read) and the journeys of `docs/ops/slo.md` when it
  exists; an unset budget is written "unset" and raised as an open point, never
  invented.
- **`## Security & Privacy Implications`**: the regions and `handles_pii` of the
  resolved `compliance` line — a part printed `(unset -- ask)` is "unset — ask",
  never "none".
- **`## Cost Implications`**: figures the user gives or a pricing source they
  point to; otherwise `NOT DETERMINED`.
- **`## PRD Requirements Addressed`**: one row per requirement, with its TR-ID from
  `docs/architecture/tr-registry.yaml`. A requirement that has no TR-ID yet is
  quoted and marked "TR-ID pending — `/architecture-review` assigns it"; this skill
  never writes the TR registry. A foundational decision writes
  "Foundational — no PRD requirement. Enables: …".

5.2. **Stack Specialist Validation** — Before saving, spawn the routed stack lead(s)
for the ADR's Domain (the **Routing by Domain** table in Step 0; lead and
sub-specialist from the resolved `stack` line; widened by `team.size`) and
`tech-lead` via `Agent` to validate the drafted ADR:
   - For each consulted layer the `stack` line lists under `unset=`, skip its
     specialist and **record `Stack validation: NOT CHECKED — <layer> layer not
     configured (run /setup-stack)` in this run's output.** A skipped check that
     says nothing is indistinguishable from a check that passed; the reader cannot
     tell stack guidance was never sought.
   - Spawn each stack specialist with: the ADR's Stack Compatibility section,
     Decision section, Key Interfaces, and the `docs/stack-reference/` paths read in
     Step 1. Ask them to:
     1. Confirm the proposed approach is idiomatic for the pinned framework versions
     2. Flag any APIs or patterns that are deprecated or changed after the model's
        knowledge cutoff
     3. Identify stack-specific risks or gotchas not captured in the current draft
   - Spawn `tech-lead` with the same sections, asking whether engineers can build
     it as written: missing interfaces (error model, pagination, event versioning,
     how the authenticated user reaches the domain layer), test strategy, and
     day-to-day operability.
   - If a specialist identifies a **blocking issue** (wrong API, deprecated approach,
     version incompatibility): revise the Decision and Stack Compatibility sections
     accordingly, then confirm the changes with the user before proceeding
   - If the specialists find **minor notes** only: incorporate them into the ADR's
     `## Risks` table

5.3. **PRD Sync Check** — Before presenting the write approval, scan every PRD
named in `## PRD Requirements Addressed` for naming inconsistencies with the ADR's
Key Interfaces and Decision sections (renamed operations, events, fields, entities
or states). If any are found, surface them as a **prominent warning block**
immediately before the write approval — not as a footnote:

```
PRD SYNC REQUIRED
[prd-filename].md uses names this ADR has renamed:
  [old_name] → [new_name_from_adr]
  [old_name_2] → [new_name_2_from_adr]
The PRD must be updated before or alongside writing this ADR to prevent
engineers reading the PRD from implementing the wrong interface.
```

**This check has three outcomes, not two.** The two above are "found" and "none
found"; the third is **could not check**, and it must never render like a clean
result.

- **None found** — print one line, do not stay silent:
  `PRD sync: checked [N] referenced PRD(s), no naming inconsistencies.`
  A silent pass is indistinguishable from a check that never ran, and this one
  guards against engineers implementing the wrong interface from a stale PRD.
- **Could not check** — the ADR has no `PRD Requirements Addressed` section, it
  names no PRDs (a foundational decision), or a named PRD does not exist on disk.
  Print:
  `PRD sync: NOT ASSESSED — [which reason, and which files]`
  Do **not** treat an ADR that references no PRDs as one whose PRDs are
  consistent. Nothing was compared.

Only the warning block itself is conditional; the check always reports.

5.4. **Write approval** — Use `AskUserQuestion`:

If PRD sync issues were found:
- "ADR draft is complete. May I write this to `docs/architecture/adr-NNNN-<slug>.md` and the PRD(s) listed above?"
  - [A] Write ADR + update PRD in the same pass
  - [B] Write ADR only — I'll update the PRD manually
  - [C] Not yet — I need to review further

If no PRD sync issues:
- "ADR draft is complete. May I write this to `docs/architecture/adr-NNNN-<slug>.md`?"
  - [A] Write ADR to `docs/architecture/adr-NNNN-<slug>.md`
  - [B] Not yet — I need to review further

If yes to any write option, write the file, creating the directory if needed.
For option [A] with PRD update: also update the PRD file(s) to use the new names.
The ADR is written as `Proposed`, so writing it before the director reviews
unblocks nothing; the reviews need the file on disk to read it.

5.5. **Director reviews** — gates TD-ADR, TD-STACK-RISK and SE-SECURITY-REVIEW.

**Review mode check** — apply before spawning TD-ADR, TD-STACK-RISK and
SE-SECURITY-REVIEW (`--review` overrides the resolved `review_mode`):
- `full` → spawn as normal.
- `lean` → **skip every gate whose ID does not end in `-PHASE-GATE`**. Note: `[GATE-ID] skipped — Lean mode`
  None of the three ends in `-PHASE-GATE`, so lean skips all three and records
  `[TD-ADR] skipped — Lean mode` (and likewise for each gate whose condition held).
- `solo` → skip all gates. Note: `[GATE-ID] skipped — Solo mode`

Which gates apply to this ADR:

| Gate | Condition | Agent |
|------|-----------|-------|
| TD-ADR | always | `technical-director` |
| TD-STACK-RISK | a component in `**Stack Components**` has Knowledge Risk HIGH or MEDIUM (one spawn per such component) | `technical-director` |
| SE-SECURITY-REVIEW | the ADR's Domain is `Auth`, `Security` or `Data` | `security-engineer` |

Spawn every applicable gate that survives the mode check **in parallel** — issue
all `Agent` calls before waiting for any result. Each prompt instructs the agent
to read its gate file first (the parent must not read it):

- **TD-ADR** → `technical-director`, gate file `.claude/docs/director-gates/td-adr.md`
  - Pass: ADR path · Knowledge Risk of the ADR's components (from `docs/stack-reference/VERSION.md`) · related ADR paths
  - Fill: the path written in 5.4; each component with its Knowledge Risk row; the
    ADRs named in `## ADR Dependencies`, `## Related` and the registry stances of
    3a (or "none").
- **TD-STACK-RISK** → `technical-director`, gate file `.claude/docs/director-gates/td-stack-risk.md`
  - Pass: component and version change (old → new, or pinned version) · `docs/stack-reference/<component>/` path · ADR paths whose `## Stack Compatibility` names the component
  - Fill: `<Component> <pinned version>` (or "not pinned"); the component's folder
    (say "absent" when it does not exist); the other ADRs whose `**Stack Components**`
    row names it, found with Grep, plus this ADR.
- **SE-SECURITY-REVIEW** → `security-engineer`, gate file `.claude/docs/director-gates/se-security-review.md`
  - Pass: artifact path (contract, data model or ADR) · operations or entities with auth scope and PII classification · resolved `compliance` line · `docs/security/threat-model.md` path (or "none")
  - Fill: the ADR path; the operations and entities from `### Key Interfaces` and
    `## Security & Privacy Implications`, each with its auth scope and
    classification; the resolved `compliance` line as printed; the threat model path
    or `none`.

Parse the first line of each reply as `[GATE-ID]: TOKEN` (TOKEN one of `APPROVE`,
`CONCERNS`, `REJECT` for all three gates; the brackets are literal — for example
`[SE-SECURITY-REVIEW]: CONCERNS`) and map it with the verdict classes of
`.claude/docs/director-gates.md` (`## Standard Verdict Format`):

- **APPROVE-class** (`APPROVE`) → continue.
- **CONCERNS-class** (`CONCERNS`) → present the concerns via `AskUserQuestion`:
  `Revise flagged items` / `Accept and proceed` / `Discuss further`.
- **REJECT-class** (`REJECT`) → present the blockers. Revise the Decision,
  Alternatives or Stack Compatibility sections (Edit, after "May I write this to
  `docs/architecture/adr-NNNN-<slug>.md`?") and re-run that gate; the ADR stays
  `Proposed` and cannot be accepted while a REJECT stands.
- A first line that does not parse, or names another gate, is not an approval —
  treat it as CONCERNS-class and say the verdict line was missing.

With several gates, the strictest class wins: one REJECT-class verdict overrides
every APPROVE-class verdict, and one CONCERNS-class verdict caps the result at
CONCERNS.

5.6. **Record the outcomes** in the ADR's `## Decision Makers` section, one line per
gate that applied (show them, then ask "May I write this to
`docs/architecture/adr-NNNN-<slug>.md`?"):

```markdown
> **Technical Director Review (TD-ADR)**: APPROVED 2026-10-02
> **Technical Director Review (TD-STACK-RISK)**: CONCERNS (accepted) 2026-10-02
> **Security Engineer Review (SE-SECURITY-REVIEW)**: REVISED 2026-10-02
```

A gate skipped by review mode leaves its skip note on its line instead —
`> [TD-ADR] skipped — Lean mode` (or `— Solo mode`) — so the record shows the mode
was applied. Acceptance mode reads these lines.

5.7. **Update Architecture Registry**

Scan the written ADR for new architectural stances that should be registered:
- Data it claims ownership of (`data_ownership`: entity → owning module or service)
- Interface contracts it defines (`interfaces`: REST/GraphQL/gRPC operations,
  events, queues, webhooks, with a `schema_ref`)
- SLO or latency budgets it claims (`slo_budgets`)
- Technology choices it makes explicitly, and what it rules out
  (`technology_decisions`)
- Patterns it bans (`forbidden_patterns` — from Implementation Guidelines
  "must never" rules or Consequences → Negative)

Present candidates:
```
Registry candidates from this ADR:
  NEW data ownership:        savings_goal → goals module
  NEW interface:             goals.deposit.recorded v1 (event via outbox; schema_ref docs/api/asyncapi.yaml)
  NEW SLO budget:            POST /v1/goals p95 ≤ 300 ms (journey create-goal)
  NEW technology decision:   identity = managed identity provider (not: in-house session service)
  NEW forbidden pattern:     client-computed charge amount (server computes from the plan catalog)
  EXISTING (referenced_by update only): account → identity module ✅
```

**Registry append logic**: When writing to `docs/registry/architecture.yaml`, do NOT assume sections are empty. The file may already have entries from previous ADRs written in this session. Before each Edit call:
1. Read the current state of `docs/registry/architecture.yaml`
2. Find the correct section (`data_ownership`, `interfaces`, `slo_budgets`, `technology_decisions`, `forbidden_patterns`)
3. Append the new entry AFTER the last existing entry in that section — do not try to replace a `[]` placeholder that may no longer exist
4. If the section has entries already, use the closing content of the last entry as the `old_string` anchor, and append the new entry after it

**BLOCKING — do not write to `docs/registry/architecture.yaml` without explicit user approval.**

Ask using `AskUserQuestion`:
- "May I write this to `docs/registry/architecture.yaml` — [N] new stances?"
  - Options: "Yes — update the registry", "Not yet — I want to review the candidates", "Skip registry update"

Only proceed if the user selects yes. If yes: append new entries. Never modify existing entries — if a stance is
changing, set the old entry to `status: "superseded_by: ADR-[NNNN]"` (quoted — an unquoted
second colon is not valid YAML) and add the new entry.

Tech radar changes this decision implies are listed in the closing output and
written at acceptance (acceptance mode, step 9) — a `Proposed` decision does not
move the radar.

---

## 6. Closing Next Steps

After the ADR is written (and registry optionally updated), close with `AskUserQuestion`.

Before generating the widget:
1. Read the required-ADR list of `docs/architecture/architecture.md` (when it exists)
   and glob `docs/architecture/adr-*.md` — which required ADRs are still unwritten?
   Foundation-layer ones marked critical come first.
2. Check whether this ADR decided the API style or the primary data store — the
   contract and the data model can then be designed.
3. List ALL remaining required ADRs as individual options — not just the next one or two.

Widget format:
```
ADR-[NNNN] written (Proposed) and registry updated. What would you like to do next?
[1] Write [next-required-adr] — [layer, critical or not, what it unblocks]
[2] Write [another-required-adr] — [brief description]  (include ALL remaining ones)
[N] /architecture-decision accept ADR-[NNNN] — once the review is settled
[N+1] /api-design — design the API contract (when this ADR decided the API style)
[N+2] /data-model — model the data (when this ADR decided the primary data store)
[N+3] /setup-stack refresh — after an ADR that decides data or cloud components is Accepted
[N+4] Stop here for this session
```

Show only the options that apply. If there are no remaining required ADRs, offer
the acceptance, contract and data-model options that apply and "Stop here", and
suggest running `/architecture-review` in a fresh session.

**Always include this fixed notice in the closing output (do NOT omit it):**

> To validate ADR coverage against your PRDs, open a **fresh Claude Code session**
> and run `/architecture-review`.
>
> **Never run `/architecture-review` in the same session as `/architecture-decision`.**
> The reviewing agent must be independent of the authoring context to give an unbiased
> assessment. Running it here would invalidate the review.

**Do NOT unblock stories here.** This ADR is `Proposed` — Step 5 guarantees it,
and a story blocked *pending this decision* is still pending it. Unblocking on
authoring is how the deadlock stayed invisible: it defeated the guard at the
moment the guard became relevant, so the pipeline appeared to flow while running
on decisions nobody had accepted.

Instead, tell the user what is now waiting on acceptance:

> "ADR-NNNN is written and `Proposed`. [N] stories remain `Blocked` pending it.
> Run `/architecture-decision accept ADR-NNNN` when the decision is settled —
> that is what moves them to `Ready`."

List the blocked stories by path so the cost of leaving it Proposed is visible.
(Acceptance has consequences enforced across many skills and an authority
recorded in only a few, so the route between them must stay explicit.)
