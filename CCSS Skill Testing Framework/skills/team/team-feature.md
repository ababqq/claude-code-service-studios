# Skill Spec: /team-feature

> **Category**: team
> **Priority**: medium
> **Spec written**: 2026-09-28

## Skill Summary

Orchestrates a feature squad from PRD to validated build for one feature. Phase 1
(Define) checks the PRD and its acceptance criteria with `product-manager`; Phase 2
(UX delta) runs `/ux-design` through `product-designer` only when screens are added or
changed; Phase 3 (Contract) has `tech-lead` update the API contract through
`/api-design` and the data model and migration plan through `/data-model`, both invoked
with `--review <resolved review_mode>`, and split the work per surface; Phase 4
(Implement) spawns one stream per surface in parallel — `backend-engineer` (`api`),
`frontend-engineer` (`web`), `mobile-engineer` (`ios` / `android` / `mobile`) — each writing
in the root the resolved `code_roots` line gives its layer; Phase 5
(Integrate) proves the contract and the critical journey with contract and E2E tests;
Phase 6 (Validate) has `qa-engineer` write and walk test cases and file bugs as
`production/qa/bugs/BUG-NNNN.md`; Phase 7 (Sign-off) is a spoken status report with no
artifact: COMPLETE / NEEDS WORK / BLOCKED / NOT ASSESSED. The skill spawns no director
gate itself; the gates its sub-skills own apply the same review mode.

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`); `name` is `team-feature`, equal to the directory `.claude/skills/team-feature/` and the catalog `name`
- [ ] Bootstrap: the first body line is `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,automation_always_ask,team.size,surfaces,stack,code_roots` `` and `allowed-tools` grants `Bash(bash "*/.claude/skills/team-feature/../../hooks/yaml-helper.sh" resolve_config *)`
- [ ] `--keys` is exactly `review_mode,automation,automation_always_ask,team.size,surfaces,stack,code_roots`
- [ ] The line after the bootstrap block is exactly: ``Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] Automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") present verbatim right after that line
- [ ] `allowed-tools` is exactly: `Read, Glob, Grep, Write, Edit, Bash, Agent, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskUpdate` plus the bootstrap grant
- [ ] 2+ phase headings found — the seven pipeline phases in order: `### Phase 1: Define (PRD & acceptance criteria check)`, `### Phase 2: UX delta (…)`, `### Phase 3: Contract (API & data delta)`, `### Phase 4: Implement (parallel per surface)`, `### Phase 5: Integrate (contract tests + E2E)`, `### Phase 6: Validate (qa-engineer)`, `### Phase 7: Sign-off (spoken status report, no artifact)`, after `## Phase 0: Resolve Config`
- [ ] Phase 2 carries the skip line verbatim: `UX delta: skipped — no screens added or changed`
- [ ] Verdict keywords present, exactly: `COMPLETE`, `NEEDS WORK`, `BLOCKED`, `NOT ASSESSED`; Phase 1 returns `READY` or `GAPS`
- [ ] The orchestrator's only own write is guarded by "May I write this to `design/prd/<feature>.md`?"; engineers changing source ask "May I write this to [path]?" per file
- [ ] Outputs per phase at the fixed destinations: `design/ux/<slug>.md` (via `/ux-design`), the contract under `docs/api/` and `docs/api/changes/api-change-YYYY-MM-DD.md` (via `/api-design`), `docs/data/data-model.md` and `docs/data/migrations/NNNN-<slug>.md` (via `/data-model`), `tests/contract/<feature>/…`, `tests/e2e/<journey>/…`, `production/qa/evidence/<story-slug>/`, `production/qa/test-cases/<feature>-cases.md`, `production/qa/bugs/BUG-NNNN.md`; Phase 7 writes no report file
- [ ] Contains verbatim: "Team skills spawn only the gates `.claude/docs/director-gates.md` § Gate Index lists this skill under (Spawned by column), after the review-mode check (lean suffix rule); team-size scoping never removes a director gate."
- [ ] Phase 0 contains the lean sentence verbatim ("`lean` → **skip every gate whose ID does not end in `-PHASE-GATE`**. Note: `[GATE-ID] skipped — Lean mode`"), the default statement verbatim ("Unset on an unconfigured project: `modes.rigor` defaults to `minimal`, which resolves `review_mode` to `solo`."), and states that the skill spawns no gate itself and passes `--review <resolved review_mode>` to `/api-design` and `/data-model`
- [ ] Active set per `team.size` is listed (`individual`: `backend-engineer`, or `frontend-engineer` when the Surface is `web` only; `small`: `product-manager` → `product-designer` → `tech-lead` → `backend-engineer` ∥ `frontend-engineer` ∥ `mobile-engineer` → `qa-engineer`; `studio`: + routed stack sub-specialists, `security-engineer`, an adversarial review pass) and announced before Phase 1
- [ ] Phase 0 states that the resolved `code_roots` line gives each Phase 4 stream its root (`.claude/docs/code-root-resolution.md` § Surfaces and roots) and `data=` (`stack.layers.data.migrations_dir`) for migration files; a layer with no resolved root gets no stream — reported as a blocker, never written into a guessed directory
- [ ] Names the always-ask categories it reaches — `schema_changes`, `db_migrations`, `scope_changes` — and checks each against the resolved `automation_always_ask` line
- [ ] Without an argument, prints "Usage: `/team-feature [feature-slug | design/prd/<feature>.md]` — …" and stops without spawning subagents or reading files
- [ ] Has an Error Recovery Protocol section and a File Write Protocol section (sub-agents under the bounded exception, engineers asking per file, sub-skills asking before writing)
- [ ] No `!` injection other than the bootstrap line; no `file:line` citations of other files
- [ ] The closing `AskUserQuestion` names current skills (`/story-done <story-path>`, `/code-review <path>`, `/business-rules-check <feature-slug>`, `/team-ui <screen>`, `/smoke-check sprint`)

---

## Director Gate Checks

- **Full mode**: `/team-feature` spawns no gate; `/api-design` (SE-SECURITY-REVIEW) and `/data-model` (SE-SECURITY-REVIEW) run with `--review full` and spawn their own gate
- **Lean mode**: no gate spawns here; the sub-skills receive `--review lean` and write their own `[SE-SECURITY-REVIEW] skipped — Lean mode` notes into the artifacts they review
- **Solo mode**: no gate spawns here; the sub-skills receive `--review solo` and note `[SE-SECURITY-REVIEW] skipped — Solo mode`
- **Review-mode exempt**: not applicable
- **N/A**: the skill's gate list is empty; team-size scoping never removes a gate a sub-skill owns

---

## Test Cases

Quoted prompts, option labels and verdict tokens below are the canonical English text
of `SKILL.md`; at run time the model renders them in the user's conversation language.

### Case 1: Happy Path — Moa savings goals across web, iOS and API

**Fixture** (assumed project state):
- `design/prd/goals.md` exists with `> **Status**: Approved`, testable Given/When/Then acceptance criteria, flag `goals.v2-progress-ring` (key, default off, owner, removal date) and success-metric events
- Stories under `production/epics/goals-core/` name `design/prd/goals.md`; their `> **Surface**:` headers are `api`, `web` and `ios`
- Resolved block: `review_mode: full`, `team.size: small`, `automation: collaborative`, `platform.surfaces: web, ios, api (project.yaml)`, a `stack:` line with web, mobile and backend configured, and a `code_roots:` line with `web=apps/web; mobile=apps/mobile; backend=apps/api; data=apps/api/prisma/migrations`
- A staging environment is running; `commands.test` and `commands.e2e` are set in `project.yaml`

**Input:** `/team-feature goals`

**Expected behavior:**
1. Phase 0 announces the `small` active set and names the `studio` additions as not spawned
2. Phase 1: `product-manager` returns READY with no gaps; `AskUserQuestion` "PRD check: READY. Proceed to the UX and contract deltas?" → `[A] Proceed`
3. Phase 2: the progress ring changes a screen, so `product-designer` runs `/ux-design goal-detail`, which writes `design/ux/goal-detail.md` after asking
4. Phase 3: `tech-lead` runs `/api-design update goals --review full` and `/data-model migration goal-progress-snapshot --review full`; each contract change prompts as `schema_changes`, the migration as `db_migrations`; work split per surface; `AskUserQuestion` → `[A] Proceed — spawn the implementation streams for [surfaces]`
5. Phase 4: `backend-engineer`, `frontend-engineer` and `mobile-engineer` are spawned in one message; each brief carries its stories, its code root (`apps/api`, `apps/web`, `apps/mobile`), the contract delta, the ADR summary and the flag key; each asks "May I write this to [path]?" per file; `git diff --stat` and `commands.test` run afterwards
6. Phase 5: `qa-engineer` writes contract tests under `tests/contract/goals/` and the E2E journey under `tests/e2e/create-goal/`, runs `commands.e2e` against staging, keeps traces in `production/qa/evidence/<story-slug>/`
7. Phase 6: test cases to `production/qa/test-cases/goals-cases.md`; manual cases walked 3–4 per question; no bugs
8. Phase 7 reports, in conversation, the results of every phase and every `NOT CHECKED` line; status COMPLETE; no report file

**Assertions:**
- [ ] The active set is announced before any spawn
- [ ] No implementation stream starts before the contract delta is approved in Phase 3
- [ ] The Phase 4 streams are issued in parallel, one per surface in scope
- [ ] `/api-design` and `/data-model` are invoked with `--review <resolved review_mode>`
- [ ] New behaviour ships dark behind the named flag on every surface
- [ ] Phase 7 is spoken only — no sign-off file is written
- [ ] The closing widget recommends `/story-done <story-path>` when COMPLETE

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — PRD absent, then a Proposed ADR

**Fixture:**
- `design/prd/payments.md` does NOT exist
- (variant) the PRD exists, but the story's governing ADR `docs/architecture/adr-0004-payment-provider.md` is `Proposed`

**Input:** `/team-feature payments`

**Expected behavior:**
1. Phase 1 stops and asks: `[A] Run /write-prd <feature> first, then re-run /team-feature (Recommended)` / `[B] The change is small — run /quick-spec instead` / `[C] Proceed from my description — acceptance criteria are written in this phase`
2. With [C], `product-manager` drafts Given/When/Then criteria and the sign-off carries `NOT CHECKED — PRD absent (criteria drafted in /team-feature)`
3. Variant: the Proposed ADR blocks implementation — "do not implement; run `/architecture-decision` first"; status BLOCKED, naming Phase 4 and the ADR

**Assertions:**
- [ ] A missing PRD is never silently replaced by inference from the slug
- [ ] Option [C] leaves the NOT CHECKED line in the sign-off
- [ ] A Proposed ADR stops implementation and routes to `/architecture-decision`
- [ ] A BLOCKED run names the phase and the blocker and still produces a partial report

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: NOT ASSESSED — No running environment for E2E

**Fixture:**
- As Case 1, but no local stack or staging environment is available to run the journey
- (variant) the same, plus an unresolved `S1-Critical` bug filed in Phase 6

**Input:** `/team-feature goals`

**Expected behavior:**
1. Phase 5 records `NOT CHECKED — E2E (no running environment)`; the journey is not reported as passing
2. Phase 7 reports status **NOT ASSESSED** — implemented, but the evidence that would verify it could not be produced — and says which
3. Variant: the unresolved S1 bug makes the status **NEEDS WORK**, not NOT ASSESSED (a known failure outranks an unknown)

**Assertions:**
- [ ] The missing environment produces the exact NOT CHECKED line
- [ ] The status is NOT ASSESSED, never COMPLETE, when E2E could not run
- [ ] An unresolved S1 bug outranks the unassessed E2E: NEEDS WORK
- [ ] Every `NOT CHECKED` line appears verbatim in the Phase 7 report

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Mode Variant — `team.size` individual versus studio

**Fixture:**
- Same as Case 1
- Variant A: `team.size: individual`; the feature's stories are all `web`
- Variant B: `team.size: studio`; the `stack` line routes `web-specialist>nextjs-specialist`, `mobile-specialist>react-native-specialist`, `backend-specialist>node-specialist`

**Input:** `/team-feature goals`

**Expected behavior (variant A):**
1. Announcement: `frontend-engineer` runs the pipeline (Surface `web` only); the other agents are named as not spawned and consulted through it

**Expected behavior (variant B):**
1. Phase 3 spawns the routed sub-specialists with the contract delta and work split; their notes are folded into the split before Phase 4
2. Phase 5 spawns `security-engineer` over the diff in parallel with the tests: authorization per operation (can user A read or change user B's goal?), input validation, secrets, PII in logs and payloads; Critical or High findings block sign-off
3. Phase 6 spawns a fresh `tech-lead` for the adversarial pass (duplicate submissions, concurrent edits, partial failure, expired sessions, a Moa auto-debit scheduled at 00:00 KST, offline-then-online); each reproducible break becomes a bug

**Assertions:**
- [ ] At `individual` the runner is `frontend-engineer` only when the Surface is `web` only, else `backend-engineer`
- [ ] The collapse is announced, not silent
- [ ] At `studio` the stack sub-specialists come from the `stack` line's routing
- [ ] The adversarial reviewer is briefed only with the acceptance criteria, edge cases and diff

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Edge Case — Unset surfaces, out-of-squad stories, unset stack layer

**Fixture:**
- The `surfaces` line prints the unset form
- The feature has a story with `> **Surface**: admin` and another with `> **Surface**: android` while `platform.surfaces` (once answered) is `web, ios, api`
- The `stack` line lists `unset=mobile,cloud`; `commands.test` is not set in `project.yaml`
- The `code_roots` line has no `mobile=` root, and one story has `> **Surface**: ios`

**Input:** `/team-feature goals`

**Expected behavior:**
1. The skill asks which surfaces this feature ships on before Phase 1 ends — it never assumes "web only"
2. The `android` story outside `platform.surfaces` is surfaced as a finding
3. The `admin` story is listed in the Phase 4 plan with `/dev-story <story-path>` as its route; it is not implemented by this squad
4. `NOT CHECKED — mobile layer not configured (run /setup-stack)` is recorded where a mobile specialist would have been consulted
5. The `ios` story gets no implementation stream: `no code root resolved for mobile (set stack.layers.mobile.root via /setup-stack)` is reported as a blocker, and no code is written for it
6. After Phase 4: `NOT CHECKED — unit tests (commands.test unset)`

**Assertions:**
- [ ] Unset surfaces lead to a question, not an assumption
- [ ] `admin`, `infra` and `analytics` stories are handed to `/dev-story`, not implemented here
- [ ] Each skipped check prints its NOT CHECKED line
- [ ] `commands.test` is read from `project.yaml` with Read
- [ ] A surface whose layer has no resolved code root is never implemented into a guessed directory

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Usage — No argument

**Fixture:**
- Any project state

**Input:** `/team-feature` (no argument)

**Expected behavior:**
1. Outputs "Usage: `/team-feature [feature-slug | design/prd/<feature>.md]` — name the feature the squad should take from PRD to validated build (e.g., `goals`, `design/prd/payments.md`)."
2. Stops without spawning subagents or reading files

**Assertions:**
- [ ] No agent is spawned and no file is read
- [ ] The usage text follows the `argument-hint` format with examples
- [ ] No status token is emitted

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: Always-ask decisions in autonomous mode

**Fixture:**
- As Case 1, with `automation: autonomous` and `automation_always_ask` listing `scope_changes`, `schema_changes`, `db_migrations`
- `product-manager` proposes dropping one acceptance criterion

**Input:** `/team-feature goals`

**Expected behavior:**
1. Phase transitions advance without prompts, but dropping the criterion prompts (`scope_changes`)
2. The contract change prompts (`schema_changes`) and the migration plan prompts (`db_migrations`)
3. Engineers still propose deploy, migration and flag commands for the user to run

**Assertions:**
- [ ] Each listed always-ask category prompts at `autonomous`
- [ ] The categories are checked against the resolved `automation_always_ask` line, not a remembered list
- [ ] No command that changes production, shared infrastructure, a shared database or secrets is run by an agent

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses "May I write this to `design/prd/<feature>.md`?" before PRD edits; engineers ask per source file; sub-skills ask before writing
- [ ] Presents the PRD check, the contract delta and the work split before requesting approval
- [ ] Ends with the closing `AskUserQuestion` of next steps
- [ ] Does not auto-create files without user approval; agents write new artifacts only at the destinations the skill named (bounded exception)
- [ ] Any BLOCKED agent is surfaced immediately and a partial report is produced
- [ ] Writes no evidence, reports or plans under `production/session-logs/` (gitignored)
- [ ] Never writes `modes.review_mode` or any other knob that `modes.rigor` fronts

---

## Coverage Notes

- Phase 2 skipped because no screen changes (`UX delta: skipped — no screens added or
  changed`) and Phase 3 with no contract change (`Contract delta: none`) are asserted by the
  skill text but not given fixtures.
- A feature with no stories (offer `/create-epics` and `/create-stories` before Phase 4) is
  covered by the Phase 1 text; Phase 4 cannot start without stories.
- Bug numbering (glob `BUG-*.md`, pre-assign the next four-digit numbers before parallel
  filing) follows the same rule as `/team-qa` and is not re-tested here.
