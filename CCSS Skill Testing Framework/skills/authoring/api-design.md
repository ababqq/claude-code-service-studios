# Skill Spec: /api-design

> **Category**: authoring
> **Priority**: high
> **Spec written**: 2026-09-28

## Skill Summary

`/api-design` designs the product's API **contract first**. It writes the rules every operation follows
(`docs/api/api-guidelines.md`, from `.claude/docs/templates/api-guidelines.md`), the machine-readable contract
(`docs/api/openapi.yaml` from `.claude/docs/templates/openapi-skeleton.yaml` by default, or `docs/api/schema.graphql`,
`docs/api/<service>.proto`, `docs/api/asyncapi.yaml` when the API-style ADR chose another style), the record of every
change (`docs/api/changes/api-change-YYYY-MM-DD.md`) and, for a Public API only, developer guides
(`docs/api/guides/<slug>.md`). Modes: `new` (Architecture — the initial contract for the Foundation and Core
resources), `update <resource>`, `reconcile` (Validation — the contract against the key UX specs' `## API Data`
sections), `review` and `breaking-check`. It lints the contract (`commands.api_lint`, or a structural self-check),
classifies every change against `HEAD` as BREAKING or NON-BREAKING, and spawns the SE-SECURITY-REVIEW gate
(`security-engineer`) under the review-mode rules. Verdicts: `CONTRACT READY` / `NEEDS REVISION` /
`BREAKING CHANGE — ACTION REQUIRED` / `NOT ASSESSED`, precedence
BREAKING CHANGE — ACTION REQUIRED > NEEDS REVISION > NOT ASSESSED > CONTRACT READY. Hand-off: `/data-model`, then
`/create-epics` after `reconcile`.

Assertions quote the canonical English text of `.claude/skills/api-design/SKILL.md`. At run time the model renders
quoted prompts in the user's conversation language (`.claude/docs/coding-standards.md` § Language Policy); this spec
never asserts the runtime wording.

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] `name: api-design` equals the directory name (`.claude/skills/api-design/`) and this spec's basename
- [ ] `argument-hint` is `"[new | update <resource> | reconcile | review | breaking-check] [--review full|lean|solo]"`
- [ ] The first body line is exactly
      `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,automation_always_ask,workflow,stack,surfaces,compliance` ``
      — the `--keys` value is exactly `review_mode,automation,automation_always_ask,workflow,stack,surfaces,compliance`
- [ ] `allowed-tools` contains the grant naming this skill's own directory:
      `Bash(bash "*/.claude/skills/api-design/../../hooks/yaml-helper.sh" resolve_config *)`
- [ ] `allowed-tools` is exactly the set Read, Glob, Grep, Write, Edit, Bash, Agent, AskUserQuestion plus that grant
      — no MCP tool names, no TaskCreate/TaskUpdate, no WebSearch/WebFetch
- [ ] The line after the bootstrap block is exactly: ``Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] The automation prelude block — from `**Automation mode**: Resolve` to `categories always prompt).` — follows
      that line verbatim, as `.claude/docs/automation-modes.md` § How to Use This Document spells it
- [ ] The bootstrap line is the only `!` injection in the file; no `file:line` citation of another file
- [ ] `model: sonnet`; no `disable-model-invocation` and no `isolation` key
- [ ] ≥2 phase headings (Phase 0 through Phase 9, plus Phase 3R)
- [ ] The four verdict tokens are spelled exactly: `CONTRACT READY`, `NEEDS REVISION`,
      `BREAKING CHANGE — ACTION REQUIRED`, `NOT ASSESSED`
- [ ] The Phase 0 stop line is spelled exactly: `NOT ASSESSED — no backend layer, data layer or api surface configured`
- [ ] Every output path is named: `docs/api/api-guidelines.md`, `docs/api/openapi.yaml`, `docs/api/schema.graphql`,
      `docs/api/<service>.proto`, `docs/api/asyncapi.yaml`, `docs/api/changes/api-change-YYYY-MM-DD.md`,
      `docs/api/guides/<slug>.md`
- [ ] "May I write this to `<path>`?" appears before each write — the guidelines, the contract, the change record,
      the developer guides and the review line in the contract header
- [ ] The SE-SECURITY-REVIEW spawn carries this `Pass:` line verbatim:
      `` Pass: artifact path (contract, data model or ADR) · operations or entities with auth scope and PII classification · resolved `compliance` line · `docs/security/threat-model.md` path (or "none") ``
- [ ] The spawn prompt tells `security-engineer` to read `.claude/docs/director-gates/se-security-review.md`
      itself, and the parent parses the first reply line as `[SE-SECURITY-REVIEW]: TOKEN`
- [ ] Next-step handoff at the end (Phase 9 closing `AskUserQuestion` naming `/data-model` and `/create-epics`)

---

## Director Gate Checks

The skill spawns one director gate, **SE-SECURITY-REVIEW** (`security-engineer`), in Phase 7a — after the contract
is written, linted and diffed. The review-mode check comes first; `--review full|lean|solo` overrides the resolved
`review_mode` for the run.

- **Full mode**: SE-SECURITY-REVIEW spawns with the four Context items. At `workflow: full` the consumer review by
  `frontend-engineer` (web) and/or `mobile-engineer` (ios, android) also runs in Phase 7b — a consultation, not a
  gate; it is offered at `standard`.
- **Lean mode**: the lean suffix rule — "skip every gate whose ID does not end in `-PHASE-GATE`" — skips
  SE-SECURITY-REVIEW; the note `[SE-SECURITY-REVIEW] skipped — Lean mode` is recorded where the review line would go.
- **Solo mode**: all gates skipped; the note `[SE-SECURITY-REVIEW] skipped — Solo mode` is recorded.
- **N/A**: `breaking-check` mode has no review phase and records `not run — breaking-check mode`; a `reconcile` with
  no differences records `not run — contract unchanged`.

The gate outcome maps through the verdict classes of `.claude/docs/director-gates.md` § Standard Verdict Format:
APPROVE → continue; CONCERNS → `Revise flagged items` / `Accept and proceed` / `Discuss further`; REJECT → revise or
the verdict stays `NEEDS REVISION`; an unparseable first line is CONCERNS-class, never an approval.

---

## Test Cases

### Case 1: Happy Path — `new` writes Moa's initial contract at Architecture

**Fixture** (assumed project state):
- Moa (web + iOS + Android + API, Korean market); the config block prints
  `review_mode: full (project.yaml)`, `automation: collaborative (default)`, `workflow: standard (rigor:standard)`,
  `stack: web=Next.js 15.3 @apps/web,apps/admin; mobile=React Native (Expo) 0.79 @apps/mobile; backend=NestJS 11.0 @apps/api,services/worker; data=PostgreSQL 16; unset=cloud [routing: web-specialist>nextjs-specialist, mobile-specialist>react-native-specialist, backend-specialist>node-specialist, data-specialist] (project.yaml)`,
  `platform.surfaces: web, ios, android, api (project.yaml)`, `compliance: regions=kr handles_pii=true (project.yaml)`
- `docs/architecture/adr-0003-api-style.md` — `## Status` `Accepted`, `**Domain**` `API`, decides OpenAPI 3.1
- `design/prd/auth.md` and `design/prd/goals.md` exist; `docs/data/data-model.md` classifies `goals.name` and
  `goals.target_amount` as `PII`; `docs/architecture/tr-registry.yaml` holds `TR-goals-001` and `TR-goals-002`
- No file under `docs/api/`; `project.yaml` sets `commands.api_lint: npx @redocly/cli lint docs/api/openapi.yaml`
- The user converses in Korean

**Input:** `/api-design`

**Expected behavior:**
1. No contract matches the catalog globs, so the mode is `new`, announced; the Backend condition is true
2. Phase 1 reads the PRDs by section, the API-style ADR, the data model, the TR registry and the threat model path,
   then presents a context summary (Public API: yes — `api` is in `platform.surfaces`) before any drafting
3. Phase 2 drafts `docs/api/api-guidelines.md` from the template one section at a time, each approved before the
   next, then asks "May I write this to `docs/api/api-guidelines.md`?"
4. Phase 3 presents one operation table per feature (auth/session, account, goals), consulting `tech-lead` and
   `node-specialist` in parallel; the user approves each table
5. Phase 4 copies the OpenAPI skeleton, sets `info.version: 0.1.0`, marks `x-data-classification` on the `PII`
   fields, shows the draft and asks "May I write this to `docs/api/openapi.yaml`?"
6. Phase 5 runs `commands.api_lint`; Phase 6 reports "first version — no baseline; breaking-change check N/A"
7. Phase 7a spawns SE-SECURITY-REVIEW (APPROVE); Phase 7b spawns `frontend-engineer` and `mobile-engineer` in
   parallel only if `workflow` is `full` — here it is offered, not forced; Phase 7c offers developer guides
   (`ux-writer` drafts, `tech-lead` reviews) because the API is public
8. No change record is written for `new`; the review outcome goes into the contract header comment line
   `# Security Engineer Review (SE-SECURITY-REVIEW): APPROVED <date>`
9. Phase 9 prints `Verdict: CONTRACT READY` and closes with `AskUserQuestion` offering `/data-model` first

**Assertions:**
- [ ] The guidelines file carries the template's twelve `##` headings byte-identical and in order (`## Versioning`
      … `## Internationalization`), in English, with Korean body text
- [ ] Every operation in the written contract has `operationId`, `security`, `x-requirements` (TR-IDs), at least one
      4xx and one 5xx response and examples; `createGoal` requires `Idempotency-Key`
- [ ] Fields classified `PII` in the data model carry `x-data-classification`; a field nobody classified is flagged
      `unclassified`, never assumed `Internal`
- [ ] `tech-lead` and the routed backend sub (`node-specialist`) are spawned in parallel before any result is awaited
- [ ] No `docs/api/changes/` file is written in `new` mode
- [ ] Each write is preceded by its own "May I write this to `<path>`?" and nothing is written before approval
- [ ] The closing widget offers `/data-model` (and `/security-audit threat-model` when the threat model is absent)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: NOT ASSESSED — no backend layer, data layer or api surface (missing input)

**Fixture:**
- (a) A marketing site: the config block prints
  `stack: web=Next.js 15.3 @apps/web; unset=mobile,backend,data,cloud [routing: web-specialist>nextjs-specialist] (project.yaml)`
  and `platform.surfaces: web (project.yaml)`
- (b) A fresh project: `stack: unset — run /setup-stack` and `platform.surfaces: (unset -- ask which surfaces ship)`

**Input:** `/api-design new`

**Expected behavior:**
1. (a) The Backend condition is known false — the stack is configured, `backend` and `data` are both in `unset=`,
   and the surfaces are set without `api`
2. (a) The skill prints exactly `NOT ASSESSED — no backend layer, data layer or api surface configured`, suggests
   `/setup-stack` if the configuration is wrong, and stops
3. (b) The condition is unknown — unset is not "no backend": the skill prints
   `Backend condition unknown (stack or surfaces unset) — proceeding; run /setup-stack to record it.` and continues
   to Phase 1

**Assertions:**
- [ ] (a) The exact NOT ASSESSED line is printed and no file is written, no agent spawned, no gate run
- [ ] (a) The verdict is `NOT ASSESSED`, never `CONTRACT READY`
- [ ] (b) An unset stack or surfaces value is never read as "no backend" — the run continues with the announced note
- [ ] The skill never writes `platform.surfaces` or `stack.*` itself; the fix is named as `/setup-stack`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Blocked — no Accepted API-style ADR at `standard`

**Fixture:**
- Same as Case 1, except `docs/architecture/adr-0003-api-style.md` has `## Status` `Proposed`
- `workflow: standard (rigor:standard)`

**Input:** `/api-design new`

**Expected behavior:**
1. Phase 1 finds the ADR whose `**Domain**` is `API` and reads its `## Status` — not `Accepted`
2. The skill stops with the message naming the API style as a Foundation decision without an Accepted ADR, and
   routes to `/architecture-decision accept ADR-0003` (or `/architecture-decision api-style` when no ADR exists)
3. Nothing is written

**Assertions:**
- [ ] The skill stops before Phase 2 — no guidelines, no contract, no change record
- [ ] The run ends with `Verdict: NOT ASSESSED — <the stop message>`, never `CONTRACT READY`
- [ ] The routing names `/architecture-decision` (accept mode for the Proposed ADR)
- [ ] At `workflow: minimal` the same fixture does **not** stop: the style is asked with `AskUserQuestion`
      (`OpenAPI 3.1 (REST) — recommended` / `GraphQL` / `gRPC (protobuf)` / `AsyncAPI (events only)`) and recorded in
      the guidelines' `**API Style**` line as "no ADR — minimal tier"

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: NOT ASSESSED — no linter and the self-check declined (missing input)

**Fixture:**
- A contract exists at `docs/api/openapi.yaml`; `commands.api_lint` is absent from `project.yaml`
- The user chooses `update goals` and, in Phase 5, answers `Skip` to the self-check offer

**Input:** `/api-design update goals`

**Expected behavior:**
1. Phase 5 says `commands.api_lint is not set (set it with /settings or /setup-stack)` and offers the structural
   self-check (`Run the self-check` / `Skip`)
2. The user skips; lint is `NOT ASSESSED`
3. Phase 8 writes the change record with `- Lint: NOT ASSESSED — no linter, self-check declined` under `## Checks`
   and the verdict line `> **Verdict**: NOT ASSESSED` (unless a BREAKING change or a revision outranks it)

**Assertions:**
- [ ] Lint that neither ran nor was replaced by the self-check makes the run `NOT ASSESSED`, never `CONTRACT READY`
- [ ] A lint command that cannot start is reported as `NOT CHECKED — api_lint could not run: <reason>` and the
      self-check becomes the lint result
- [ ] The skill never installs a linter or a diff tool
- [ ] The change record's verdict line sits directly under its H1 `# API Change: YYYY-MM-DD` and one blank line

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Mode Variant — `reconcile` at Validation always writes a change record

**Fixture:**
- Contract `docs/api/openapi.yaml` exists; `platform.surfaces: web, ios, android, api (project.yaml)`
- `design/ux/goal-list.md`, `design/ux/goal-detail.md` and `design/ux/sign-in.md` are screen specs (H1 `# UX Spec: …`)
- `design/ux/goal-list.md` has `## API Data` naming `listGoals` (in the contract — MATCH)
- `design/ux/goal-detail.md` has `## API Data` naming `getGoalProgress` (absent from the contract — MISSING)
- `design/ux/sign-in.md` is a screen spec with no `## API Data` section; `design/ux/reviews/` holds review records
- `design/ux/goal-create.md` is a flow spec with H1 `# User Flow: Create a goal` (no `## API Data` section)

**Input:** `/api-design reconcile`

**Expected behavior:**
1. Phase 3R reads every screen spec — `design/ux/*.md` whose H1 starts `# UX Spec:` (never `design/ux/reviews/`; flow
   specs are skipped) — and classifies each referenced operation as MATCH / MISSING / MISMATCH / CHATTY / UNUSED
2. `sign-in.md` is listed as `NOT CHECKED — design/ux/sign-in.md has no ## API Data section`
3. The MISSING operation is proposed as a Phase 3 table, reviewed by `tech-lead` and the routed backend sub, and on
   approval goes through Phases 4–7
4. Phase 8 writes `docs/api/changes/api-change-YYYY-MM-DD.md` with the `## UX Reconciliation` table
5. Phase 9 closes with `/create-epics` offered

**Assertions:**
- [ ] The change record is written even when no difference is found (a "no change" record is the evidence the
      reconciliation ran)
- [ ] A UX spec without `## API Data` prevents `CONTRACT READY`: the run reports `NOT ASSESSED` at best
- [ ] UNUSED operations are never removed in this mode
- [ ] The `# User Flow:` file produces no NOT CHECKED line
- [ ] With no UI surface configured (`platform.surfaces: api`), the skill says "No UI surface — nothing to reconcile"
      and writes nothing; with no UX spec at all it routes to `/ux-design`; both stops end with
      `Verdict: NOT ASSESSED — <the stop message>`
- [ ] The skill states the Validation requirement as the gate does: the reconcile record (`> **Mode**: reconcile`) is
      required at `full` when the product has a backend and a UI, recommended at `standard`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Edge Case — `breaking-check` finds a BREAKING change on a Public API

**Fixture:**
- `HEAD` holds `docs/api/openapi.yaml`; the working tree changes `Goal.targetDate` from `string` to `format: date`
  and adds a response enum value `PAUSED` to `Goal.status`
- `platform.surfaces: web, ios, android, api (project.yaml)`; `docs/api/api-guidelines.md` `## Deprecation` states a
  180-day window

**Input:** `/api-design breaking-check`

**Expected behavior:**
1. Phase 6 diffs against `git show HEAD:docs/api/openapi.yaml`, classifies the type change as BREAKING and the new
   response enum value as NON-BREAKING on the watch list
2. The BREAKING change triggers the `schema_changes` always-ask and a decision per change: `Version bump` /
   `Deprecate and keep both` / `Make it non-breaking` — `Coordinated change` is not offered because `api`, `ios` and
   `android` are in `platform.surfaces`
3. With `Deprecate and keep both`, the plan carries a `Sunset` date at least 180 days away and names the
   `## API / Developers` release-notes entry
4. If the user leaves the decision open, the change record's verdict is `BREAKING CHANGE — ACTION REQUIRED`

**Assertions:**
- [ ] The version-bump-or-deprecation choice is always the user's — the skill never makes it
- [ ] A `Sunset` inside the guidelines' window keeps the verdict at `BREAKING CHANGE — ACTION REQUIRED`
- [ ] The change record (`docs/api/changes/api-change-YYYY-MM-DD.md`) is written after "May I write this to …?"
      with `## Breaking Changes & Plan` filled and the review line `not run — breaking-check mode`
- [ ] The closing widget offers `/release-notes`, `/rollout-plan` and `/create-stories`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: Review Mode — `full` spawns SE-SECURITY-REVIEW

**Fixture:**
- Case 1 state at Phase 7; `review_mode: full (project.yaml)`; `docs/security/threat-model.md` absent
- The gate replies with first line `[SE-SECURITY-REVIEW]: CONCERNS` (no rate limit on `requestPhoneOtp`)

**Input:** `/api-design new`

**Expected behavior:**
1. The spawn prompt tells `security-engineer` to read `.claude/docs/director-gates/se-security-review.md` first; the
   parent does not read or paste it
2. The `Pass:` items are filled: `docs/api/openapi.yaml`; the Phase 3 operation table with auth scopes and PII
   fields; `compliance: regions=kr handles_pii=true (project.yaml)`; `"none"` for the threat model
3. The CONCERNS reply is surfaced with `Revise flagged items` / `Accept and proceed` / `Discuss further`; revising
   returns to Phase 4 for the flagged operations and re-runs Phases 5–6

**Assertions:**
- [ ] The first reply line is parsed as `[SE-SECURITY-REVIEW]: TOKEN`; a line that does not parse is treated as
      CONCERNS-class and named as a missing verdict line
- [ ] The outcome is recorded as `REVISED <date>` or `CONCERNS (accepted) <date>` — never as APPROVED
- [ ] A REJECT that stays unresolved caps the verdict at `NEEDS REVISION` and the review line reads
      `pending — REJECT findings unresolved <date>`
- [ ] The skill does not auto-advance past a CONCERNS-class or REJECT-class verdict

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 8: Review Mode — `lean` skips SE-SECURITY-REVIEW by the suffix rule

**Fixture:**
- `update goals` run; the config block prints `review_mode: lean (rigor:standard)`; no `--review` argument

**Input:** `/api-design update goals`

**Expected behavior:**
1. The Phase 7a review-mode check applies the lean suffix rule: skip every gate whose ID does not end in
   `-PHASE-GATE`
2. SE-SECURITY-REVIEW does not end in `-PHASE-GATE`, so it is skipped; the change record's review line is the note
   `> [SE-SECURITY-REVIEW] skipped — Lean mode`
3. The summary names the omission: "SE-SECURITY-REVIEW not consulted — Lean mode; `--review full` runs it, or run
   `/security-audit api` later."

**Assertions:**
- [ ] The SKILL.md review-mode check contains the sentence
      `` `lean` → **skip every gate whose ID does not end in `-PHASE-GATE`**. Note: `[GATE-ID] skipped — Lean mode` ``
      — the rule, not an enumerated list of gate IDs
- [ ] No `security-engineer` agent is spawned in lean mode
- [ ] The skip note is written into the artifact (the change record header), not only printed
- [ ] A gate skipped by review mode is not a failure: with lint and the diff clean, the verdict can be
      `CONTRACT READY`
- [ ] `/api-design update goals --review full` in the same project spawns the gate (the argument overrides)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 9: Review Mode — `solo` on an unconfigured-rigor project

**Fixture:**
- `modes.rigor` unset: the config block prints `review_mode: solo (rigor:minimal)` and `workflow: minimal (rigor:minimal)`
- `new` run with the style chosen in Phase 1 (minimal tier — no ADR required)

**Input:** `/api-design new`

**Expected behavior:**
1. Phase 7a skips all gates: `[SE-SECURITY-REVIEW] skipped — Solo mode`
2. The consumer review (7b) does not run at `minimal`; it is named as not run in the summary
3. The skip note is recorded in the contract header comment line where the review outcome would go

**Assertions:**
- [ ] No gate agent is spawned; the note reads exactly `[SE-SECURITY-REVIEW] skipped — Solo mode`
- [ ] The skill never writes `modes.review_mode` or any other rigor-fronted knob
- [ ] Every skipped consult appears as a `NOT CHECKED` or skip line in the summary — a skip is never silent

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses "May I write this to `<path>`?" before every write; a multi-file write is approved as one listed changeset
- [ ] Presents the context summary, each guidelines section and each resource table before asking for approval
- [ ] Ends with a recommended next step (Phase 9 `AskUserQuestion`) and never takes it on its own
- [ ] Does not auto-create files without approval; `schema_changes` prompts in every automation mode unless the user
      removed it from `automation_always_ask`
- [ ] Never puts real personal data, tokens, keys or credentialed URLs in a contract, example or guide
- [ ] Never commits; never writes handler code, generated clients, contract tests or migrations

**Authoring rubric** (`CCSS Skill Testing Framework/quality-rubric.md` § `authoring`):

- [ ] A1 — Section-by-section cycle: guidelines sections and per-feature resource tables are each presented and
      approved before the next
- [ ] A2 — "May I write" before each file write (guidelines, contract, change record, each guide)
- [ ] A3 — Retrofit: an existing contract is never overwritten by `new` (the skill asks whether `update` was meant);
      `update` shows the diff of the changed section only
- [ ] A4 — SE-SECURITY-REVIEW runs in `full`, is skipped with a named note in `lean` and `solo`
- [ ] A5 — Skeleton headings byte-identical to the template file: the guidelines keep every `##` heading of
      `.claude/docs/templates/api-guidelines.md` exactly as spelled, and the contract starts from
      `.claude/docs/templates/openapi-skeleton.yaml` (shared `components` kept)

---

## Coverage Notes

- GraphQL, gRPC and AsyncAPI contracts are covered structurally (Phase 4 style table); only the OpenAPI path is
  fixture-tested.
- `review` mode (report in conversation, header review line only with consent) is not given its own case.
- A second change record on the same day (suffix `-2`, `-3`) is not fixture-tested.
- The consumer review's mobile version-skew advice and the developer-guide content depend on the spawned agents and
  are outside what a static read of the skill can verify.
