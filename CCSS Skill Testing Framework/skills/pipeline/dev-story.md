# Skill Spec: /dev-story

> **Category**: pipeline
> **Priority**: high
> **Spec written**: 2026-09-28

## Skill Summary

`/dev-story` implements one story. It resolves the workflow tier per story (the PRD stem
of `**PRD**:` via `feature_overrides`), checks that the files the story depends on exist
(TR registry, governing ADR, control manifest, tech radar, the story's API contract and
migration plan), trusts the story's distilled ADR summary when its `**ADR Version**`
matches the ADR's `## Last Verified`, and reads only the story's layer of the control
manifest. It maps the story's `> **Surface**:` to a code root from the `code_roots` line
(writing no code when nothing resolves), marks the story `in-progress` in
`production/sprint-status.yaml` and `> **Status**: In Progress` in the story, and routes
it: the first matching row of the Surface/Type routing table picks the primary engineer;
the `[routing: …]` list on the `stack` line picks the stack sub-specialist (the layer
lead when the story's Risk is HIGH). Specialists consult without writing; engineers write
code and tests in the resolved root(s). Always-ask categories (`db_migrations`,
`schema_changes`, `billing_changes`, `secrets_access`, `pii_data_access`,
`infra_changes`, `file_deletions`, `scope_changes`) prompt whatever the automation mode
when the resolved `automation_always_ask` list contains them; production deploys never
happen here. Phase 6 verifies the agents finished, runs
typecheck/lint/tests, runs the product and looks at it per surface
(`.claude/docs/run-and-observe.md`), dry-runs any migration on a disposable database, and
retains evidence under `production/qa/evidence/<story-slug>/`. It spawns no director
gate — code review is `/code-review`, and TL-CODE-REVIEW belongs to `/story-done`.
`disable-model-invocation: true`.

Outcome tokens: `Implementation Complete` / `INCOMPLETE` / story **BLOCKED**; the run is
reported as exactly one line `Run result: OBSERVED | NOT VERIFIED | N/A — <reason>`, which
is also the `> **Verdict**:` token of `production/qa/evidence/<story-slug>/evidence.md`.

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`); `name: dev-story` equals the skill directory, the catalog `name` and this spec's basename
- [ ] `description` is exactly "Implement a story: ADR guidance, routed engineer and stack specialist, code and tests, run-and-observe."; `argument-hint: "[story-path]"`; `model: sonnet`
- [ ] `disable-model-invocation: true` present; no `isolation` key
- [ ] Bootstrap: the first body line is exactly `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,automation_always_ask,workflow,story_granularity,qa.level,testing.strict,feature_overrides,stack,code_roots,surfaces` `` and `allowed-tools` grants `Bash(bash "*/.claude/skills/dev-story/../../hooks/yaml-helper.sh" resolve_config *)`
- [ ] `review_mode` is **not** among the keys; the line after the bootstrap block is exactly the plain variant `` Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`. ``
- [ ] Automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") present verbatim right after that line
- [ ] `allowed-tools` is exactly: `Read, Glob, Grep, Write, Edit, Bash, Agent, AskUserQuestion` plus the grant — no MCP tool name
- [ ] ≥2 phase headings (`## Phase 0: Resolve Configuration` … `## Phase 8: Next Steps`)
- [ ] Outcome keywords present exactly: `Implementation Complete`, `INCOMPLETE`, `BLOCKED`, and the three `Run result:` tokens `OBSERVED`, `NOT VERIFIED`, `N/A`; the could-not-assess lines `NOT CHECKED — no code root resolved (set stack.layers.<layer>.root via /setup-stack)`, `NOT CHECKED — <layer> layer not configured (run /setup-stack)` and `Run result: NOT VERIFIED — no capture script (run /test-setup)` present
- [ ] "May I write this to `<path>`?" before each write: "May I write this to `production/sprint-status.yaml` and `[story-path]`?", "May I write this to `[config path]`?", "May I write this to `production/qa/evidence/<story-slug>/migration-dry-run.log`?", "May I write this to `production/qa/evidence/<story-slug>/evidence.md`?"; engineers ask "May I write this to [path]?" for each file
- [ ] Outputs at the exact paths: code and tests in the resolved code roots; `production/qa/evidence/<story-slug>/…`; `production/sprint-status.yaml` with `status: in-progress` (hyphenated — the enum is `backlog | ready-for-dev | in-progress | review | done | blocked`); `evidence.md` carries `> **Verdict**: <OBSERVED | NOT VERIFIED | N/A>` directly under its H1
- [ ] The routing table has these rows in order (Config without code → none; Config with migration → `backend-engineer` + `data-specialist`; `infra` → `devops-engineer` + `cloud-specialist`; `analytics` → `data-engineer` + `analytics-engineer`; `admin` → `internal-tools-engineer`; ML → `ml-engineer`; `web` → `frontend-engineer`; `ios`/`android`/`mobile` → `mobile-engineer`; `api` + Foundation or shared roots → `platform-engineer`; `api` → `backend-engineer`)
- [ ] No `!` injection other than the bootstrap line; no `file:line` citations of other files
- [ ] Next-step handoff at the end names `/code-review` and `/story-done` (and `/smoke-check sprint`, `/team-qa sprint`)

---

## Director Gate Checks

- **N/A**: `/dev-story` spawns no director gate. `review_mode` is not requested and has no
  effect; implementation agents (engineers and stack specialists) are not gates. Review of
  the change happens in `/code-review` and in `/story-done` (TL-CODE-REVIEW,
  QL-TEST-COVERAGE).

---

## Test Cases

Fixtures use the Moa example: story `production/epics/goals-core/story-001-create-goal.md`
(Type Integration, Surface `api`, Layer Core, `TR-goals-001`, `ADR-0006`,
`` **API Contract**: `docs/api/openapi.yaml#/paths/~1v1~1goals/post` ``,
`` **Migration**: `docs/data/migrations/0003-savings-goal.md` ``,
`**Feature Flag**: goals.v2-progress-ring`, `**Analytics Events**: goal_created`); stack line
`stack: web=Next.js 15.3 @apps/web,apps/admin; backend=NestJS 11.0 @apps/api,services/worker; data=PostgreSQL 16; unset=mobile,cloud [routing: web-specialist>nextjs-specialist, backend-specialist>node-specialist, data-specialist] (project.yaml)`.

### Case 1: Happy Path — an Integration story on the API

**Fixture** (assumed project state):
- `modes.workflow: standard`, `qa.level: standard`; `code_roots: web=apps/web,apps/admin; backend=apps/api,services/worker; data=apps/api/prisma/migrations (project.yaml); …`
- ADR-0006 `## Last Verified` equals the story's `**ADR Version**`; the manifest date equals the story's `> **Manifest Version**:`
- `docs/stack-reference/VERSION.md` rates NestJS `LOW`; `commands.typecheck`, `commands.lint`, `commands.test`, `commands.run`, `commands.migrate` set; Docker available
- `production/sprint-status.yaml` has an entry whose `file:` is the story path

**Expected behavior:**
1. Phase 2 confirms the TR registry, ADR, manifest, radar, contract and migration plan exist; greps `^## Last Verified` (dates match → trusts the story, does not read the ADR); greps `^## Core Layer Rules`; greps the `createGoal` operation; reads the plan's `## Expand`, `## Rollback per Phase`, `## Status`
2. Maps Surface `api` to root `apps/api` (asking which root when the story's `**Stack Notes**` names none), then asks "May I write this to `production/sprint-status.yaml` and `[story-path]`?" and sets `status: in-progress`, `updated:`, `> **Status**: In Progress`, `> **Last Updated**:`
3. Announces `Routing: backend-engineer (Surface api) + node-specialist (backend layer, Risk LOW); root apps/api`, spawns `node-specialist` for guidance with no file writes, then `backend-engineer` with the brief (file paths, ADR summary inline, contract pointer, Expand phase, flag and events, `naming.*`, `performance.api_p95_ms`, test requirement)
4. Writing the migration file triggers the `db_migrations` always-ask prompt
5. Phase 6: runs typecheck, lint and the story's tests; calls `POST /v1/goals` locally and retains `NN-createGoal.json` (tokens and PII redacted); dry-runs the Expand migration on a disposable database and rolls it back; writes `migration-dry-run.log` and `evidence.md` after their "May I write" prompts
6. Prints `## Implementation Complete: [Story Title]`, appends the session extract, and closes with the Phase 8 widget

**Assertions:**
- [ ] The ADR is not re-read when the version stamps match
- [ ] Code is written only under `apps/api` and the migration only under `apps/api/prisma/migrations`
- [ ] `production/sprint-status.yaml` shows `status: in-progress` — never the underscore spelling
- [ ] The summary shows the exact commands that ran and their results, `Run result: OBSERVED — …` with the retained path, and `**Migration dry-run**:` with the log path
- [ ] `evidence.md` sits at `production/qa/evidence/story-001-create-goal/evidence.md` with `> **Verdict**: OBSERVED` under its H1
- [ ] The Phase 8 options are `/code-review [changed files] — review the implementation (Recommended)`, `/story-done [story-path] — verify the acceptance criteria and close the story`, `Stop here`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — a referenced ADR is Proposed, or the contract is missing

**Fixture:**
- (2a) `modes.workflow: standard`; the story references `ADR-0008`, whose `## Status` is `Proposed`
- (2b) any tier; the story's `**API Contract**` points at `docs/api/openapi.yaml`, which does not exist

**Expected behavior:**
1. (2a) The story is set BLOCKED in the session state; the skill routes to `/architecture-decision`
2. (2b) Stops: "Contract [path] not found. Run `/api-design` first — the contract comes before the handler."
3. No engineer or specialist is spawned

**Assertions:**
- [ ] Skill stops early and does not produce code
- [ ] The blocker names the ADR or the missing contract path and the skill that fixes it
- [ ] The story is not marked In Progress and `production/sprint-status.yaml` is not touched
- [ ] At `standard`, a story that references no ADR is **not** blocked on ADR grounds

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: NOT ASSESSED — no code root, and no capture script

**Fixture:**
- (3a) The `code_roots` line reads `code_roots: unresolved — NOT CHECKED (set stack.layers.<layer>.root via /setup-stack)`
- (3b) A UI story `story-003-goal-list-web.md` (Surface `web`); `apps/web` resolves; `tests/e2e/capture.spec.ts` does not exist

**Expected behavior:**
1. (3a) Prints `NOT CHECKED — no code root resolved (set stack.layers.<layer>.root via /setup-stack)` and stops — no code is written anywhere, even though the web framework resolves a specialist
2. (3b) The engineer implements the screen; Phase 6 step 4 reports `Run result: NOT VERIFIED — no capture script (run /test-setup)`

**Assertions:**
- [ ] 3a writes no file and spawns no engineer; the reason and the fix (`/setup-stack`) are named
- [ ] 3a never falls back to a guessed directory such as `src/`
- [ ] 3b states that `NOT VERIFIED` is a blocker at the default gate level for UI and that retained captures are required in `production/qa/evidence/<story-slug>/` before `/story-done`
- [ ] Neither variant claims the look of the product was verified

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Mode Variant — `minimal` tier and `qa.level: minimal`

**Fixture:**
- `modes.rigor` unset (`minimal`): no TR registry, no ADRs, no control manifest; `production/sprint-status.yaml` absent
- Story (from `/create-stories` minimal mapping) with `**PRD**: design/product/one-pager.md`, Type Logic, `**Migration**: docs/data/migrations/0001-goals.md`

**Expected behavior:**
1. The missing registry, ADR and manifest do not block; one line before spawning: `Briefing omits: TR registry (absent), control manifest (absent) — implementing against acceptance criteria + one-pager.`
2. The brief tells the engineer "Do not write a test file for this story — test evidence is waived at `qa.level: minimal`."
3. Prints `Sprint status not updated: production/sprint-status.yaml absent` and still updates the story header
4. The summary carries the waiver line "*Test evidence: **waived** at `qa.level: minimal` — no test was required or written for this story.*"; the migration dry-run still runs

**Assertions:**
- [ ] The test requirement is omitted explicitly, not silently
- [ ] The run-and-observe step and the migration dry-run are not waived
- [ ] Skipped inputs are named to both the agent and the user

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Edge Case — multi-surface story with HIGH stack risk

**Fixture:**
- Story `story-006-goal-progress-ring.md`: Type UI, `> **Surface**: web, api`, `**Feature Flag**: goals.v2-progress-ring`
- `docs/stack-reference/VERSION.md` rates Next.js `HIGH` (post-cutoff APIs); NestJS `LOW`
- Nested spawning is unavailable: `web-specialist` replies with `NOT CONSULTED — nextjs-specialist (nested spawn unavailable)` and the hand-off line `nextjs-specialist: <task>`

**Expected behavior:**
1. The first Surface (`web`) picks the row: `frontend-engineer` primary
2. Because the web Risk is HIGH, the layer lead `web-specialist` is spawned instead of `nextjs-specialist`
3. The additional Surface `api` adds only its row's primary agent, `backend-engineer`, as a secondary (`node-specialist` is not added)
4. The provider (the API change) is implemented first, the consumer (the web screen) second, on disjoint roots
5. The skill parses the lead's reply and spawns `nextjs-specialist` itself with the hand-off task and the story context

**Assertions:**
- [ ] The routing line names primary, secondaries, the matched row and the roots
- [ ] Risk comes from `VERSION.md` (a missing row or `NOT DETERMINED` would count as HIGH), not from the story card alone
- [ ] One writer per file: each engineer writes only in its own root
- [ ] New behaviour sits behind `goals.v2-progress-ring`; flag off restores today's behaviour
- [ ] A lead reply carrying `NOT CONSULTED — <sub> (nested spawn unavailable)` or `<sub>: <task>` is acted on: the skill spawns the named sub, or the NOT CONSULTED line appears in the Phase 6 summary

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Config story — no agent, always-ask category

**Fixture:**
- Story Type Config, no code: raise the Plus plan's goal limit in `apps/api/config/plans.json`
- `modes.automation: autonomous`; `automation_always_ask` contains `billing_changes`

**Expected behavior:**
1. No engineer or specialist is spawned (Config path)
2. The plan-table edit is a `billing_changes` decision → `AskUserQuestion` despite `autonomous`
3. Asks "May I write this to `[config path]`?" and records every value changed, from what, to what

**Assertions:**
- [ ] Environment configuration never receives a secret value
- [ ] A flag's production state is never changed here — only its repository default
- [ ] `Run result: N/A — <reason>` is used only when nothing is observable, and the reason says why

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: Edge Case — the engineer stops at its turn limit

**Fixture:**
- `backend-engineer` returns after hitting its turn limit; `goals.service.ts` calls a function that was never defined

**Expected behavior:**
1. Phase 6 treats the story as **INCOMPLETE** and runs `commands.typecheck`, which fails
2. The headline says INCOMPLETE, lists what exists, names the breakage and offers to resume the agent

**Assertions:**
- [ ] "Implementation Complete" is not printed
- [ ] The story's status is not advanced
- [ ] The Phase 8 widget includes `Resume the engineer — finish what is INCOMPLETE`

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses "May I write this to `<path>`?" before every file the skill writes (status fields, Config-story configuration, evidence); engineers ask for their own files
- [ ] Loads the context before any code: story, TR entry, ADR summary, manifest layer, tech radar, contract, migration plan, stack routing
- [ ] Never runs a command that changes production, shared infrastructure, a shared database or secrets; production deploys and production flag changes go to `/rollout-plan` and a human
- [ ] Only `/story-done` writes `Complete`; this skill writes `in-progress`
- [ ] Writes no evidence under `production/session-logs/`; never writes `modes.review_mode` or any other knob `modes.rigor` fronts
- [ ] Ends with a recommended next step: `/code-review [files]`, then `/story-done [story-path]`

---

## Coverage Notes

- Pipeline rubric mapping: P1 (story header fields read; `production/sprint-status.yaml`
  and evidence schema — Case 1), P2 (Foundation shared code routes to `platform-engineer`;
  not fixture-tested), P3 (May-I-write per file — Cases 1, 6), P4 (no gate — N/A by
  design), P5 (reads ADR summary, manifest, contract and plan before writing — Case 1).
  Catalog pair: `build.implement` / `launch.implement` look for
  `status: in-progress|review|done` in `production/sprint-status.yaml`.
- The ADR-version mismatch widget ("Story was written against ADR v[story-date]. The ADR
  is now v[current-date]. …") and the manifest-version mismatch widget are not
  fixture-tested; both are mechanically similar to Case 1's freshness check.
- Mobile run-and-observe (`xcrun simctl`, `adb`, Maestro/ARTEMIS flows) and the
  `analytics`, `infra` and `admin` routing rows need a live device or configured layers
  and are not covered here.
