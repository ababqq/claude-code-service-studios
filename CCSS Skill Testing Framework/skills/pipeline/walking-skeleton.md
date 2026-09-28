# Skill Spec: /walking-skeleton

> **Category**: pipeline
> **Priority**: high
> **Spec written**: 2026-09-28

## Skill Summary

`/walking-skeleton [journey-name]` is "Sprint 0": the thinnest **real** end-to-end
implementation of one critical user journey through every configured layer (UI → API →
DB, plus the cloud layer that hosts it), with observability and a feature flag, on a
feature branch in the resolved code roots, deployed to **staging** by the CI/CD pipeline.
It is production code — never a prototype: no `prototypes/` directory, no worktree
isolation, no prototype header. Phases: pick the journey (from `docs/ops/slo.md`
`## Critical User Journeys` or a PRD) and state the validation question and time-box;
per-layer plan by `tech-lead` (no writes); implementation by the routed engineers
(`backend-engineer`, `frontend-engineer`, `mobile-engineer`, `platform-engineer` for the
flag SDK); pipeline and staging deploy proposed by `devops-engineer` and **run by a
human**; observability hook-up by `sre-engineer`; a rehearsed rollback; a flag toggled on
staging without a redeploy; the five-item validation checklist of the Validation → Build
gate; the report `production/walking-skeleton/report-YYYY-MM-DD.md` from
`.claude/docs/templates/walking-skeleton-report.md`; and, only when a usability session
ran on the skeleton, **PD-USER-VALIDATION**. Required at `standard` and `full`; once built,
its validation rules bind at every tier. Its output is the artifact of catalog step
`validation.walking-skeleton` (`production/walking-skeleton/report-*.md`).

Verdicts (first matching rule wins): **NOT VALIDATED** (any applicable item NO) →
**NOT ASSESSED** (no NO, an applicable item could not be checked) → **VALIDATED** (every
applicable item YES). A run that stops before Phase 8 (a Phase 0 stop, `Stop` at Phase 1 or
2, a stop at the Phase 3 midpoint) writes no report and ends **NOT ASSESSED**.

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`); `name: walking-skeleton` equals the skill directory, the catalog `name` and this spec's basename
- [ ] `description` is exactly "Real thin end-to-end path deployed to staging via CI/CD with rollback and flag rehearsal; VALIDATED / NOT VALIDATED / NOT ASSESSED."; `argument-hint: "[journey-name] [--review full|lean|solo]"`; `model: sonnet`
- [ ] No `isolation:` key and no `disable-model-invocation` key
- [ ] Bootstrap: the first body line is exactly `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,automation_always_ask,stack,code_roots,surfaces,workflow` `` and `allowed-tools` grants `Bash(bash "*/.claude/skills/walking-skeleton/../../hooks/yaml-helper.sh" resolve_config *)`
- [ ] The line after the bootstrap block is exactly `` Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`. ``
- [ ] Automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") present verbatim right after that line
- [ ] `allowed-tools` is exactly: `Read, Glob, Grep, Write, Edit, Bash, Agent, AskUserQuestion` plus the grant
- [ ] ≥2 phase headings (`## Phase 0: Resolve Configuration and Load Context` … `## Phase 11: Summary and Next Steps`)
- [ ] Verdict keywords present exactly: `VALIDATED`, `NOT VALIDATED`, `NOT ASSESSED`; an unchecked item is `—` with Evidence `NOT ASSESSED — <reason>`; the line `NOT CHECKED — no code root resolved (set stack.layers.<layer>.root via /setup-stack)` present
- [ ] The five validation items are those of the Validation → Build gate: (1) deployed to staging by the CI/CD pipeline, (2) one critical user journey passes end to end on staging (UI → API → DB), (3) health endpoint, logs and at least one metric/trace visible, (4) the staging deploy rolled back once and redeployed, (5) a feature flag toggled on staging without a redeploy — standard and full only
- [ ] "May I write this to `<path>`?" before every file the skill writes: "May I write this to `production/walking-skeleton/report-YYYY-MM-DD.md`?", "May I write this to `production/qa/evidence/walking-skeleton-<journey-slug>/`?"; "May I run `<command>`?" before a scaffolder command
- [ ] Output at the exact path `production/walking-skeleton/report-YYYY-MM-DD.md` with `> **Verdict**: VALIDATED | NOT VALIDATED | NOT ASSESSED` directly under its H1; report headings `## Journey`, `## Layers Touched`, `## Pipeline & Deploy`, `## Observability`, `## Validation`, `## Follow-ups`
- [ ] PD-USER-VALIDATION review-mode check carries the lean suffix sentence; the spawn has `Pass: report path (usability report, prototype REPORT.md or walking-skeleton report) · hypotheses tested · target segment · brief path`; the reply is parsed as `[PD-USER-VALIDATION]: TOKEN`
- [ ] No `!` injection other than the bootstrap line; no `file:line` citations of other files
- [ ] Next-step handoff names `/gate-check build`, `/create-epics`, `/create-stories`, `/sprint-plan`, `/dev-story`, `/test-setup`, `/architecture-decision`, `/create-architecture`, `/usability-report`

---

## Director Gate Checks

One gate, and only when a usability session ran on the skeleton: **PD-USER-VALIDATION** —
`product-director`, Domain "User evidence", verdicts `APPROVE / CONCERNS / REJECT`
(Phase 10). With no session the skill notes "PD-USER-VALIDATION not applicable — no
usability session on the skeleton" in every mode. The gate never changes the skeleton's
own verdict (delivery path vs. user value); a disagreement is said explicitly.

- **Full mode**: spawn with the `Pass:` line above; the prompt tells the agent to read
  `.claude/docs/director-gates/pd-user-validation.md`.
- **Lean mode**: skip every gate whose ID does not end in `-PHASE-GATE` —
  `[PD-USER-VALIDATION] skipped — Lean mode`, recorded in the report header.
- **Solo mode**: `[PD-USER-VALIDATION] skipped — Solo mode`, recorded in the report header.

---

## Test Cases

Fixtures use the Moa example: journey "sign up with Kakao → create a savings goal → see it
on the home screen" in `docs/ops/slo.md` `## Critical User Journeys`; stack line
`stack: web=Next.js 15.3 @apps/web,apps/admin; mobile=React Native (Expo) 0.79 @apps/mobile; backend=NestJS 11.0 @apps/api,services/worker; data=PostgreSQL 16; cloud=AWS @infra [routing: …] (project.yaml)`;
flag `goals.v2-progress-ring`; `.github/workflows/ci.yml` written by `/test-setup`.

### Case 1: Happy Path — journey validated on staging

**Fixture** (assumed project state):
- Architecture, contract (`docs/api/openapi.yaml`), data model and `0003-savings-goal.md` migration plan exist; staging exists; review mode `lean`
- The human runs the push, pipeline, staging deploy, rollback, redeploy and the flag toggle when asked, and confirms each

**Input:** `/walking-skeleton sign-up-to-first-goal`

**Expected behavior:**
1. Phase 0 loads context, writes the session checkpoint (`Task: Walking skeleton — <journey>`); Phase 1 states the validation question and time-box (1–2 weeks) and asks `Proceed with this journey (Recommended)` / `Pick a thinner journey` / `Change the surfaces` / `Stop`
2. Phase 2: `tech-lead` returns a per-layer plan with no file writes; surfaces map to roots (`apps/web` and `apps/api` — asking which of the two web roots and which of the two backend roots — `apps/mobile`, migrations dir); proposes branch `feat/walking-skeleton-<journey-slug>` without creating it
3. Phase 3: data and API first, then web and mobile in parallel on disjoint roots; `platform-engineer` wires the flag SDK; migration writing prompts as `db_migrations`; local typecheck, tests and run-and-observe first
4. Phases 4–7: `devops-engineer` proposes pipeline changes (CI workflow edits prompt as `infra_changes`) and the rollback per layer; `sre-engineer` verifies health, logs by correlation ID and a metric or trace; the human runs every staging action; results are recorded with UTC and KST timestamps
5. Phase 8: the E2E test runs against the staging `BASE_URL`; captures go to `production/qa/evidence/walking-skeleton-<journey-slug>/` after "May I write"; all five items YES
6. Phase 9: fills the template and asks "May I write this to `production/walking-skeleton/report-YYYY-MM-DD.md`?"; Phase 10 notes no usability session; Phase 11 closes with `/gate-check build — run the Validation → Build gate (Recommended when VALIDATED)`

**Assertions:**
- [ ] Code is written only in the resolved roots — never under `prototypes/`, never in a worktree
- [ ] No agent pushes, deploys, applies IaC or toggles a flag itself; each such step is a proposed command a human runs
- [ ] Every validation result carries its evidence (pipeline run, E2E run, capture path, link)
- [ ] The report carries `> **Verdict**: VALIDATED` directly under its H1 and every template section filled with observations
- [ ] The skill never commits, pushes or merges

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — NOT VALIDATED

**Fixture:**
- Case 1 fixture, except the staging deploy was run by hand from a laptop, and rolling the API back also required a database rollback

**Expected behavior:**
1. Item 1 is NO (a manual deploy does not satisfy it, however quick); item 4 is recorded with the database-rollback finding
2. Verdict **NOT VALIDATED**; the summary maps each NO to its fix (item 1 → `/test-setup` or the devops-engineer's pipeline changes; item 4 → the rollback method) and says to re-run `/walking-skeleton`

**Assertions:**
- [ ] Any applicable NO gives NOT VALIDATED, whatever the other items say
- [ ] The report states that the Validation → Build gate fails a built skeleton with any applicable NO at every tier
- [ ] The closing widget offers `Fix the failing items and re-run /walking-skeleton (Recommended when NOT VALIDATED)`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: NOT ASSESSED — items that could not be checked; no code root

**Fixture:**
- (3a) Case 1 fixture, but the observability tool is not reachable from the session and the human has not yet run the rollback
- (3b) The `code_roots` line reads `code_roots: unresolved — NOT CHECKED (set stack.layers.<layer>.root via /setup-stack)`
- (3c) The `stack` line reads `stack: unset — run /setup-stack`

**Expected behavior:**
1. (3a) Items 3 and 4 get Result `—` and Evidence `NOT ASSESSED — <reason>`; with no NO, the verdict is **NOT ASSESSED**, and the summary lists what would make each item checkable
2. (3b) Prints `NOT CHECKED — no code root resolved (set stack.layers.<layer>.root via /setup-stack)`, writes no code and stops with Verdict **NOT ASSESSED**
3. (3c) Stops with Verdict **NOT ASSESSED**: a skeleton needs a pinned stack

**Assertions:**
- [ ] An item nobody could check is never written as YES, and never as NO
- [ ] 3a's report carries `> **Verdict**: NOT ASSESSED`
- [ ] 3b and 3c write no code and no report, name `/setup-stack`, and end with Verdict NOT ASSESSED — never VALIDATED

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Mode Variant — the flag item and the workflow tier

**Fixture:**
- (4a) The resolved block prints `workflow: standard (rigor:standard)`; a flag is wired
- (4b) The resolved block prints `workflow: minimal (rigor:minimal)`
- (4c) No config block resolved; a flag is wired
- Mobile is configured; its store build cannot be rolled back

**Expected behavior:**
1. (4a) Item 5 is applicable and attempted
2. (4b) Item 5 is recorded as N/A from the resolved `workflow` line, without asking the user
3. (4c) The tier is unknown, so item 5 counts as applicable and is attempted
4. The report says the mobile rollback path is server-side (the flag and API compatibility)

**Assertions:**
- [ ] Item 5 N/A comes only from a resolved `workflow: minimal`; an unknown tier counts as applicable
- [ ] A staging flag toggle is not treated as a production deploy
- [ ] The mobile build is distributed internally by the pipeline (EAS internal distribution, TestFlight internal testing or a Play internal track) and points at the staging API

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Edge Case — midpoint checkpoint and scope creep

**Fixture:**
- At the midpoint of the time-box the journey does not yet run end to end locally
- The user asks to add the Toss Payments auto-debit screen to the skeleton

**Expected behavior:**
1. The skill stops and surfaces the blocker, says whether the scope is too large or an architectural assumption is wrong, and offers: a thinner journey, an ADR revision via `/architecture-decision`, or continuing with the risk named
2. Adding a screen is a `scope_changes` decision and prompts even in autonomous mode when that category is in `automation_always_ask`

**Assertions:**
- [ ] "Cut screens and polish, never layers" — the skill proposes cutting scope, not skipping the database or the pipeline
- [ ] The session checkpoint records the day's work for the report's effort log

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Director Gate — full mode (usability session ran)

**Fixture:**
- Case 1 fixture; review mode `full`; a usability session on the skeleton was structured by `/usability-report` into `production/qa/usability/`
- PD-USER-VALIDATION returns REJECT ("participants did not understand the goal progress")

**Expected behavior:**
1. Phase 10 asks `A usability session ran on the skeleton — review it` / `No usability session — skip`; the user picks the first
2. Spawns `product-director` with the `Pass:` line (report path, hypotheses as written before the session, participants' segment, `design/product/product-brief.md`)
3. Parses `[PD-USER-VALIDATION]: TOKEN`; REJECT is blocking for feature sprints building on the journey

**Assertions:**
- [ ] The skeleton's own verdict stays VALIDATED; the VALIDATED-with-REJECT disagreement is said explicitly
- [ ] CONCERNS → `AskUserQuestion` with `Revise flagged items` / `Accept and proceed` / `Discuss further`
- [ ] The outcome line `> **Product Director Review (PD-USER-VALIDATION)**: …` is added to the report header after "May I write this to `production/walking-skeleton/report-YYYY-MM-DD.md`?"
- [ ] A first line that does not parse is treated as CONCERNS-class; the parent never reads the gate file

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: Director Gate — lean mode (usability session ran)

**Fixture:**
- Case 6 fixture; review mode `lean`

**Expected behavior:**
1. PD-USER-VALIDATION is skipped

**Assertions:**
- [ ] No `product-director` spawn
- [ ] The report header records `[PD-USER-VALIDATION] skipped — Lean mode`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 8: Director Gate — solo mode (usability session ran)

**Fixture:**
- Case 6 fixture; review mode `solo`

**Expected behavior:**
1. No director gates spawn

**Assertions:**
- [ ] In solo mode: no director gates spawn
- [ ] The report header records `[PD-USER-VALIDATION] skipped — Solo mode`

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Question → Options → Decision → Draft → Approval at every phase: the journey, the plan, each pipeline change, the report
- [ ] "May I write this to `<path>`?" before the report, the captures and the checkpoint; engineers and `devops-engineer` ask for their own files
- [ ] Humans run everything that touches shared environments; production is never touched (`production_deploys` never applies here)
- [ ] Evidence is retained under `production/walking-skeleton/` and `production/qa/evidence/`, never only under `production/session-logs/`
- [ ] Never writes `modes.review_mode` or any knob `modes.rigor` fronts
- [ ] Ends with a recommended next step matching the verdict

---

## Coverage Notes

- Pipeline rubric mapping: P1 (report template headings and verdict line — Case 1), P2
  (data and API before UI — Case 1), P3 (May-I-write per artifact — Cases 1, 6), P4
  (PD-USER-VALIDATION per review mode — Cases 6–8), P5 (architecture, contract, data
  model, SLO journeys and CI workflow read before code — Case 1).
- Scaffolding a `missing` root with the framework's official scaffolder (after
  "May I run `<command>`?") is not fixture-tested.
- API-only products (no UI step) and web-only products follow Case 1 with fewer layers;
  not fixture-tested separately.
