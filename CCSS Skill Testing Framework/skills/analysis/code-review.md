# Skill Spec: /code-review

> **Category**: analysis
> **Priority**: low
> **Spec written**: 2026-09-28

## Skill Summary

`/code-review` performs an architectural review of service code named by path
(optionally with a story file): ADR compliance from the governing ADRs' `## Decision`,
`## Consequences` and `## Security & Privacy Implications` sections, the tech radar
(`## Hold`, `## Forbidden Patterns`) and the control manifest
(`## <Layer> Layer Rules`), and a 13-item **Service Review Checklist** — API contract conformance,
authorization on every operation (BOLA/IDOR, function level, mass assignment), input
validation, data access (N+1, indexes, transactions), idempotency, timeouts and
retries, pagination, secrets, personal data in logs, expand/contract migrations,
feature flags, errors and operability, tests. Each file is placed in its layer via the
resolved `code_roots` line and routed to the stack specialist named by the `stack`
line's routing list; `qa-engineer` reviews testability for Logic, Integration and E2E
stories, and `security-engineer` joins when authentication, payment or personal-data
code is touched. A layer lead that reports `NOT CONSULTED — <sub> (nested spawn
unavailable)` or returns a `<sub>: <task>` hand-off gets that sub spawned by the skill
with its layer's files, or the NOT CONSULTED line copied into the review — a skipped
sub is never silent. Specialist findings are verified before they are reported. The
report stays in the conversation — the skill writes no file — and ends with
`### Verdict: [NOT ASSESSED / APPROVED / APPROVED WITH SUGGESTIONS / CHANGES REQUIRED]`.
`/story-done` runs the same Phase 5 checklist inline when review mode skips
TL-CODE-REVIEW. `/code-review` itself spawns no director gate.

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`); `name: code-review` equals the skill directory, the catalog `name` and this spec's basename
- [ ] `description` is "Architectural code review with service concerns: authz, validation, N+1, transactions, idempotency, timeouts, pagination, PII in logs."
- [ ] Bootstrap: the first body line is `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,stack,code_roots` `` — exactly these three labels
- [ ] `allowed-tools` grants `Bash(bash "*/.claude/skills/code-review/../../hooks/yaml-helper.sh" resolve_config *)` with this skill's own directory name
- [ ] The line after the bootstrap block is exactly ``Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.`` (plain variant)
- [ ] The automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") follows that line verbatim
- [ ] `allowed-tools` is exactly: `Read, Glob, Grep, Bash, Agent, AskUserQuestion` plus the grant — membership exact, order free; no `Write`, no `Edit`
- [ ] `model: sonnet`; no `disable-model-invocation` and no `isolation` flag
- [ ] 2+ phase headings found, including `## Phase 5: Service Review Checklist` with 13 numbered items, opened by the sentence "This is the checklist `/story-done` runs inline when TL-CODE-REVIEW is skipped."
- [ ] Stack specialists are routed from the `stack` line's `[routing: …]` list (Phase 2), and unresolved code roots print one `NOT CHECKED` line before a review without layer routing
- [ ] `security-engineer` is spawned only under `### Security Review (when auth or personal-data code is touched)`
- [ ] `### Stack Specialists` (Phase 7) states that a lead returning `NOT CONSULTED — <sub> (nested spawn unavailable)` or a `<sub>: <task>` hand-off "gets that sub spawned by this skill with the files of its layer, or the NOT CONSULTED line copied into the review — a skipped sub is never silent."
- [ ] Verdict keywords present exactly: `NOT ASSESSED`, `APPROVED`, `APPROVED WITH SUGGESTIONS`, `CHANGES REQUIRED`; deviation classes `ARCHITECTURAL VIOLATION`, `ADR DRIFT`, `MINOR DEVIATION`; checklist severities `BLOCKING`, `WARNING`, `INFO`
- [ ] Output: report in the conversation, no file — the skill states "This skill is read-only" and contains no "May I write" prompt because it writes nothing
- [ ] Every finding in the output format carries file and line, evidence, and a confidence of `VERIFIED` or `UNVERIFIED — specialist claim`
- [ ] No `!` injection other than the bootstrap line; no `file:line` citations of other files (findings cite reviewed code, which is output, not a citation)
- [ ] Next steps close with `AskUserQuestion` naming current skills only (`/story-done`, `/code-review`, `/architecture-decision`, `/api-design update <resource>`, `/data-model migration <slug>`)

---

## Director Gate Checks

**N/A.** `/code-review` spawns no director gate at any review mode, and `review_mode`
is not among its keys. TL-CODE-REVIEW belongs to `/story-done`; this skill's Phase 5
checklist is what `/story-done` runs inline when that gate is skipped. The agents it
spawns (routed stack specialists, `qa-engineer`, `security-engineer`) are reviewers
whose findings the skill verifies — none returns a `[GATE-ID]: TOKEN` line (analysis
AN4).

---

## Test Cases

### Case 1: Happy Path — create-goal handler with story, contract and ADR

**Fixture** (assumed project state):
- `project.yaml`: `stack.layers.backend` = NestJS 11 with `root: [apps/api]`; the bootstrap `stack` line routes `backend-specialist>node-specialist`
- `production/epics/goals-core/story-001-create-goal.md`: `> **Type**: Integration`, `> **Surface**: api`, `**ADR Governing Implementation**: ADR-0001`, `**API Contract**: POST /v1/goals (createGoal)`, `**Migration**: None`, `**Feature Flag**: goals.v2-progress-ring`
- `docs/api/openapi.yaml` defines `createGoal`; `docs/architecture/adr-0001-identity-and-auth.md` is Accepted; `docs/architecture/tech-radar.md` exists
- `apps/api/src/modules/goals/` validates the body with zod, scopes the insert to the session user, paginates `GET /v1/goals` with a cursor and a maximum page size, and has an integration test

**Input**: `/code-review apps/api/src/modules/goals production/epics/goals-core/story-001-create-goal.md`

**Expected behavior**:
1. Lists and reads the target files, reads the story header fields and the path-scoped rules that match
2. Maps the files to the `backend` layer and routes them to `node-specialist`
3. Reads only the `## Decision`, `## Consequences` and `## Security & Privacy Implications` spans of ADR-0001 (heading map first, bounded reads)
4. Spawns `node-specialist` and `qa-engineer` in parallel; records `Security review: not required — no auth or personal-data code touched`
5. Answers all 13 checklist items (PASS, finding or `N/A — <why>`); verdict `APPROVED` or `APPROVED WITH SUGGESTIONS`

**Assertions**:
- [ ] Specialists are spawned in one parallel batch, and all findings are collected before output
- [ ] The Service Review Checklist line reads `[X/13 passing, N N/A]`, with no item silently missing
- [ ] `### Positive Observations` is present
- [ ] No file is written; the closing `AskUserQuestion` offers `/story-done`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure — BOLA, unauthenticated payment webhook, PII in logs

**Fixture**:
- `apps/api/src/modules/goals/goals.controller.ts`: `GET /v1/goals/:goalId` loads the goal by ID without an owner or tenant condition
- `apps/api/src/modules/payments/auto-debit.webhook.ts`: handles the Toss Payments auto-debit callback without verifying authenticity and without an idempotency key or dedupe record
- `apps/api/src/modules/payments/billing.service.ts` logs `user.phone` and the billing key on failure

**Input**: `/code-review apps/api/src/modules/goals apps/api/src/modules/payments`

**Expected behavior**:
1. Spawns `security-engineer` in parallel with the routed stack specialist because payment and personal-data code is touched
2. Flags the missing object-level authorization, the non-idempotent payment handler and the PII in logs with file, line and evidence
3. Lists every BLOCKING item under `### Required Changes`; verdict `CHANGES REQUIRED`
4. Closing `AskUserQuestion` offers fix and re-run, `/story-done` with noted exceptions, or stop

**Assertions**:
- [ ] Missing authorization and the non-idempotent payment handler are rated BLOCKING
- [ ] Each finding shows `VERIFIED` or `UNVERIFIED — specialist claim`; an unverified claim is not promoted to a defect
- [ ] Verdict is `CHANGES REQUIRED`
- [ ] The skill proposes changes but edits no code

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: NOT ASSESSED — the target files do not exist

**Fixture**:
- `apps/api/src/modules/goal` does not exist (the module is `goals`)
- No story path is given

**Input**: `/code-review apps/api/src/modules/goal`

**Expected behavior**:
1. Lists the inputs as `FOUND` or `ABSENT`; the target files are absent
2. Stops and reports `NOT ASSESSED — NO DATA`, naming the missing path
3. Spawns no specialist; the closing `AskUserQuestion` offers "[A] Point me at the files to review"

**Assertions**:
- [ ] Verdict is `NOT ASSESSED` with the missing input named
- [ ] No checklist item is marked PASS and no `APPROVED` verdict is produced
- [ ] No agent is spawned for an empty scope

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Mode Variant — stack unset and code roots unresolved

**Fixture**:
- `project.yaml` has no `stack.layers.*`: the bootstrap prints `stack: unset — run /setup-stack` and `code_roots: unresolved — NOT CHECKED (set stack.layers.<layer>.root via /setup-stack)`
- `apps/web/app/goals/page.tsx` exists and is otherwise clean

**Input**: `/code-review apps/web/app/goals/page.tsx`

**Expected behavior**:
1. Prints the unresolved code roots `NOT CHECKED` line once, then reviews the named file without layer routing (layer `unknown`)
2. Prints `Stack specialist review: NOT ASSESSED — stack unset (run /setup-stack)`; spawns no stack specialist
3. Runs the checklist and ADR checks it can; the verdict cannot be plain `APPROVED` — at best `APPROVED WITH SUGGESTIONS` with the gap listed

**Assertions**:
- [ ] Both skipped parts appear as named lines in the output
- [ ] The verdict is not `APPROVED`
- [ ] Unset stack is not read as "no specialist needed"

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Edge Case — no ADR reference, no contract, Proposed ADR, Hold library

**Fixture**:
- `apps/api/src/modules/notifications/` sends 알림톡 reminders; no story path is given and no header or commit references an ADR
- `docs/api/` has no contract
- A second module cites `docs/architecture/adr-0004-notification-queue.md`, whose `## Status` is Proposed
- The code starts new use of a library listed under `## Hold` in `docs/architecture/tech-radar.md`

**Input**: `/code-review apps/api/src/modules/notifications apps/api/src/modules/reminders`

**Expected behavior**:
1. Prints "No ADR references found — ADR compliance check skipped. For full ADR compliance review, provide the story path: `/code-review [files] [story-path]`." for the first module
2. Flags code built on the Proposed ADR as ADR DRIFT until it is Accepted
3. Checklist item 1 reads `NOT CHECKED — no API contract (run /api-design)`
4. New use of the Hold library is ADR DRIFT (WARNING), citing the radar entry's ADR

**Assertions**:
- [ ] Each skipped check is a named line, never a clean section
- [ ] The outbound provider call is checked for a timeout and bounded retries (checklist item 6)
- [ ] The verdict reflects the NOT CHECKED contract item (not plain `APPROVED`)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Edge Case — a layer lead cannot spawn its sub (nested spawn unavailable)

**Fixture**:
- The bootstrap `stack` line routes `web-specialist>nextjs-specialist, backend-specialist>node-specialist`; the `code_roots` line reads `web=apps/web; backend=apps/api; shared=packages`
- `packages/ui/src/goal-card.tsx` is a shared component whose consuming layer is unclear, so Phase 2 routes it to the layer lead `web-specialist`
- `web-specialist` runs without the `Agent` tool: its reply carries its own findings, `NOT CONSULTED — nextjs-specialist (nested spawn unavailable)` and the hand-off `nextjs-specialist: check the server/client component boundary in goal-card.tsx`

**Input**: `/code-review packages/ui/src/goal-card.tsx`

**Expected behavior**:
1. Places the file in the `shared` root and routes it to `web-specialist` (cross-layer or unclear → the layer lead)
2. Parses the lead's reply for the `NOT CONSULTED` line and the `<sub>: <task>` hand-off
3. Spawns `nextjs-specialist` itself with the files of its layer and the hand-off task — or, if it does not, copies `NOT CONSULTED — nextjs-specialist (nested spawn unavailable)` into `### Stack Specialist Findings`
4. Verifies the sub's findings like any specialist's before reporting them

**Assertions**:
- [ ] The sub the lead could not reach is either spawned by `/code-review` or named by its `NOT CONSULTED — <sub> (nested spawn unavailable)` line in the review — never dropped silently
- [ ] Findings from both the lead and the sub carry file, line, evidence and `VERIFIED` / `UNVERIFIED — specialist claim`
- [ ] No file is written

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Read-only: no Write or Edit anywhere; the report lives in the conversation
- [ ] Presents findings before offering next steps
- [ ] Ends with the `AskUserQuestion` next-step widget (options adjusted to the verdict)
- [ ] Does not auto-create files
- [ ] Writes no evidence, reports or plans under `production/session-logs/` (gitignored)
- [ ] Never writes `modes.review_mode` or any other knob that `modes.rigor` fronts
- [ ] analysis AN1 — the review reads files and runs read-only commands only (`git log --oneline -- [file]`)
- [ ] analysis AN2 — findings are structured per section with a severity (BLOCKING / WARNING / INFO) and the checklist gives one line per item
- [ ] analysis AN3 — code changes are proposed, never applied; fixes go through `/dev-story` or the user
- [ ] analysis AN4 — no director gate is spawned during or after the review
- [ ] Observation vs verdict: every finding carries file, line and evidence; specialist claims are labelled `VERIFIED` or `UNVERIFIED — specialist claim`; the verdict follows the stated verdict rules only; a required part that could not run is `NOT CHECKED` and caps the verdict below `APPROVED`

---

## Coverage Notes

- Rule-12 (the report verdict line) does not apply: the skill writes no report file.
  The conversation report ends with `### Verdict: …`.
- Directory targets with many files trigger a scope confirmation; the spec does not
  exercise a scope large enough to require it.
- The bounded ADR read (heading map, then `Read(offset, limit)` spans) is checked from
  the written instructions; token savings need a live run to observe.
- Whether a layer lead can spawn its sub depends on the runtime (nested spawning);
  Case 6 fixes the lead's reply in the fixture instead of exercising that.
