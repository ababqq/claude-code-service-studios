# Skill Spec: /rollout-plan

> **Category**: ops
> **Priority**: low
> **Spec written**: 2026-09-28

## Skill Summary

`/rollout-plan [version] [--feature <flag-key>]` writes the progressive-delivery
plan for how a version is exposed to production traffic, at
`production/releases/<version>/rollout-plan.md`, from
`.claude/docs/templates/rollout-plan.md`. It checks the premise first — the
release checklist (`production/releases/<version>/release-checklist.md`), the
newest `production/gate-checks/gate-launch-*.md` (absence is a note, not a stop),
migration plans, flags, `docs/ops/slo.md`, unresolved bugs, the latest security
audit, load test and runbooks — then drafts, section by section, with
`release-manager`, `devops-engineer`, `qa-lead` and `customer-success-manager`:
`## Scope`, `## Strategy per Surface` (flag percentages and canary stages with
dwell times for web and API; App Store phased release, Play staged rollout,
minimum supported version, force-update policy and the server compatibility
window for mobile), `## Migration Ordering` (expand before deploy, contract
after), `## Guardrail Metrics & Halt Thresholds` (error rate, p95, crash-free %,
one business KPI, automatic halt conditions), `## Rollback Plan` (per stage;
mobile binaries cannot roll back), `## Communication Plan`,
`## Go/No-Go per Stage` and `## Production Readiness Review`. The draft is
written, then `sre-engineer` runs **SR-PRODUCTION-READINESS** — at every review
mode — and its outcome is recorded in the plan. The verdict is READY TO ROLL OUT /
NOT READY / NOT ASSESSED (precedence NOT READY > NOT ASSESSED > READY TO ROLL
OUT). The skill is always collaborative, review-mode-exempt and explicitly
invoked only; it writes a plan and never executes a rollout. After the rollout
completes, the hand-off is `/retrospective release <version>`.

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`); `name: rollout-plan` equals the skill directory and the catalog `name`; `model: sonnet`
- [ ] `argument-hint` is `"[version] [--feature <flag-key>]"`; frontmatter carries `disable-model-invocation: true` and no `isolation`
- [ ] Bootstrap: the first body line is `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys distribution,surfaces,performance.enforce,compliance` `` and `allowed-tools` grants `Bash(bash "*/.claude/skills/rollout-plan/../../hooks/yaml-helper.sh" resolve_config *)`
- [ ] The line after the bootstrap block is exactly: ``Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] No automation prelude, and neither `automation` nor `review_mode` is among the keys (always collaborative, review-mode-exempt)
- [ ] `allowed-tools` is exactly: Read, Glob, Grep, Write, Edit, Bash, Agent, AskUserQuestion, plus the grant (membership exact, order free)
- [ ] 2+ phase headings found
- [ ] Verdict keywords present, exactly: `READY TO ROLL OUT`, `NOT READY`, `NOT ASSESSED`, with the precedence NOT READY > NOT ASSESSED > READY TO ROLL OUT stated
- [ ] "May I write this to `production/releases/<version>/rollout-plan.md`?" before the draft, every revision and the verdict
- [ ] Outputs at the exact path `production/releases/<version>/rollout-plan.md` (`<version>` semver; mobile build numbers inside the file); the plan's H1 is followed, after one blank line, by `> **Verdict**: <TOKEN>`
- [ ] The plan's headings are exactly `## Scope`, `## Strategy per Surface`, `## Migration Ordering`, `## Guardrail Metrics & Halt Thresholds`, `## Rollback Plan`, `## Communication Plan`, `## Go/No-Go per Stage`, `## Production Readiness Review`, from the template
- [ ] The SR-PRODUCTION-READINESS spawn passes the gate file path `.claude/docs/director-gates/sr-production-readiness.md` (read by the agent, not by the skill) and the gate's Context bullets (`.claude/docs/director-gates.md` § Context to Pass) on the verbatim line ``Pass: rollout-plan path · `docs/ops/slo.md` path · runbook paths · latest load-test report path (or "none") · release-checklist path``, and parses the first line as `[SR-PRODUCTION-READINESS]: TOKEN` with TOKEN ∈ READY / CONCERNS / NOT READY
- [ ] Contains the review-mode exemption sentence verbatim (see Case 6)
- [ ] No `!` injection other than the bootstrap line; no `file:line` citations of other files
- [ ] Next-step handoff section present at end (Phase 9), naming skills by their current names

---

## Director Gate Checks

- **Review-mode exempt**: the skill contains "`/hotfix`, `/rollout-plan` and `/incident` are release-critical: every agent and gate they name runs at every `review_mode`. They do not resolve `review_mode`." SR-PRODUCTION-READINESS runs on every plan, and its outcome is always recorded under `## Production Readiness Review` — a skip note never appears there.
- **Gate handling**: `READY` (APPROVE-class) proceeds; `CONCERNS` (CONCERNS-class) is surfaced with `Revise flagged items` / `Accept and proceed` / `Discuss further`; `NOT READY` (REJECT-class) keeps the plan from saying `READY TO ROLL OUT`; an unparseable first line is shown as CONCERNS-class, never taken as an approval.
- **Recorded outcome**: `> **Site Reliability Engineer Review (SR-PRODUCTION-READINESS)**: APPROVED <date>` (or `CONCERNS (accepted)`, `REVISED`, `NOT READY`), followed by the gate's first line.

---

## Test Cases

### Case 1: Happy Path — first public release of Moa 1.0.0

**Fixture** (assumed project state):
- `release.distribution: web+stores`; `platform.surfaces: [web, ios, android, api]`; `performance.enforce: block`; `compliance: regions=kr handles_pii=true`
- `project.yaml`: `performance.error_rate_pct`, `performance.api_p95_ms`, `performance.crash_free_pct`, `performance.lcp_ms` set; `localization.locales: [ko-KR]`; `platform.min_os.ios` and `platform.min_os.android` set
- `production/releases/1.0.0/release-checklist.md` with `> **Verdict**: GO`; `docs/ops/slo.md` with every section; runbooks for every paging alert; a load-test report; no unresolved S1 or S2 bug
- `docs/data/migrations/0007-goal-progress.md` (Expand → Migrate → Contract); flag `goals.v2-progress-ring` default off
- `stage-estimate.sh` prints `STAGE: Hardening`; `sre-engineer` replies `[SR-PRODUCTION-READINESS]: READY`

**Input**: `/rollout-plan 1.0.0`

**Expected behavior**:
1. Phase 1 reads every premise input and builds the inputs-checked table; no launch gate record exists yet — a note in `## Scope`, not a stop
2. Phase 2: "Here is what version 1.0.0 exposes to users. Is the scope right?" — `Approve the scope`
3. Phase 3 spawns `release-manager`, `devops-engineer`, `qa-lead` and `customer-success-manager` in one parallel batch
4. Phase 4 drafts each section and asks before the next: web/API stages internal → canary → 25% → 50% → 100%; App Store phased release and Play staged rollout planned from store approval; Expand before the deploy, Contract deferred while old app versions still read the old shape; guardrails with thresholds from `project.yaml` and one business KPI (auto-debit success rate); a rollback row per stage
5. Phase 5 writes the draft with `> **Verdict**: NOT ASSESSED` and `## Production Readiness Review` reading "pending — SR-PRODUCTION-READINESS runs next", after "May I write this to `production/releases/1.0.0/rollout-plan.md`?"
6. Phase 6 spawns `sre-engineer` for SR-PRODUCTION-READINESS; the reply `READY` is recorded
7. Phase 7: "The plan's verdict is **READY TO ROLL OUT** because … Record it?" then "May I write this to `production/releases/1.0.0/rollout-plan.md`?"
8. Phase 9 offers `/launch-checklist 1.0.0` and `/gate-check launch`

**Assertions**:
- [ ] The plan is written from `.claude/docs/templates/rollout-plan.md` with the eight exact headings
- [ ] The draft is on disk before the gate runs (the gate reads the plan from disk)
- [ ] Every stage has a named owner, entry criteria and a rollback row; every guardrail has a threshold
- [ ] With `performance.enforce: block`, a guardrail breach is an automatic halt; any SEV1 or SEV2 incident opened during the rollout window always halts it
- [ ] `## Production Readiness Review` carries `> **Site Reliability Engineer Review (SR-PRODUCTION-READINESS)**: APPROVED <date>` and a `**Gate reply**:` line quoting `[SR-PRODUCTION-READINESS]: READY`
- [ ] The final verdict line reads `> **Verdict**: READY TO ROLL OUT`
- [ ] Customer-facing text in the communication plan is written in `ko-KR`, and promotional launch messages are checked against `.claude/docs/compliance/kr.md` `## Marketing Messages & Consent`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — NOT READY

**Fixture**:
- As Case 1, except `production/qa/bugs/BUG-0042.md` is `**Severity**: S1-Critical`, `**Status**: In Progress`
- The rollback of the API canary stage has never been rehearsed on staging, and `sre-engineer` replies `[SR-PRODUCTION-READINESS]: NOT READY`
- The migration plan schedules its Contract phase inside this rollout while app 0.9.x (still above the minimum supported version) reads the old column

**Expected behavior**:
1. Phase 1 counts BUG-0042 as unresolved (Status `In Progress`) and caps the verdict at NOT READY
2. Phase 4b flags the Contract phase as a blocker
3. Phase 6 shows the gate's blockers and asks `Revise the plan and re-run the review` / `Record the plan as NOT READY` / `Stop`
4. On `Record the plan as NOT READY`: the outcome is recorded with the token `NOT READY`, and the verdict is NOT READY

**Assertions**:
- [ ] Verdict is NOT READY (not NOT ASSESSED) when a known blocker is open — a blocker is never hidden behind NOT ASSESSED
- [ ] An unresolved bug is one whose `**Status**:` is `Open`, `In Progress` or `Fixed — Pending Verification`, counted with its `**Severity**:` — never by `Open` alone
- [ ] The plan never says `READY TO ROLL OUT` after a `NOT READY` gate reply
- [ ] Phase 9 offers the skills that close the named gaps (`/bug-triage`, `/data-model migration <slug>`, …) and `/rollout-plan 1.0.0` again

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: NOT ASSESSED — the premise is missing

**Fixture**:
- `production/releases/1.1.0/` holds no `release-checklist.md`
- `docs/ops/slo.md` does not exist
- `performance.error_rate_pct` is unset, and the user declines to set a halt threshold for the error rate

**Input**: `/rollout-plan 1.1.0`

**Expected behavior**:
1. Phase 1 records `Release checklist: NOT ASSESSED — no record found` and recommends `/release-checklist 1.1.0` first; drafting may continue
2. Phase 1 records `NOT CHECKED — SLOs (no docs/ops/slo.md)`
3. The error-rate guardrail row reads `NOT ASSESSED — no threshold`
4. With no blocker found, the verdict is capped at NOT ASSESSED

**Assertions**:
- [ ] Verdict is NOT ASSESSED, naming each missing input
- [ ] No `READY TO ROLL OUT` is produced for a plan that could not be assessed
- [ ] An unset budget is not a threshold of zero and not a default: it is asked for
- [ ] Unset `release.distribution` (variant) makes the skill ask how this release ships — it never emits every track
- [ ] A `NOT ASSESSED` smoke, QA or checklist input is never read as `GO`, `PASS` or `PASS WITH WARNINGS`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Mode Variant — a flag's own exposure in a later release

**Fixture**:
- `stage-estimate.sh` prints `STAGE: Launch`; `production/releases/1.2.0/rollout-plan.md` exists with verdict READY TO ROLL OUT
- `goals.v2-progress-ring` shipped dark in 1.2.0

**Input**: `/rollout-plan 1.2.0 --feature goals.v2-progress-ring`

**Expected behavior**:
1. `## Scope` names only that flag; the stages are flag stages
2. The flag's stages are added to the existing plan as their own table under `## Strategy per Surface`; the skill shows what changes and asks "May I write this to `production/releases/1.2.0/rollout-plan.md`?" before editing
3. SR-PRODUCTION-READINESS runs again on the changed plan
4. Phase 9 (Launch stage) offers `/team-release` to execute the stages and `/retrospective release 1.2.0` once the rollout has completed

**Assertions**:
- [ ] The existing plan is edited in place after approval, never overwritten silently
- [ ] The hand-off after the rollout completes is `/retrospective release <version>`
- [ ] Execution is handed to `/team-release`, which records every stage in `production/releases/<version>/release-record.md` — this skill does not

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Edge Case — mobile cannot roll back

**Fixture**:
- As Case 1; the 1.0.0 iOS and Android builds change how goals sync offline
- The 25th of the month (a common payday in Korea — auto-debit peak) falls inside the planned 50% stage

**Expected behavior**:
1. `## Rollback Plan` rows for iOS and Android name the server flag or kill switch, API compatibility, and an expedited fix through `/hotfix` — not a binary rollback
2. `## Strategy per Surface` records the minimum supported app version, the force-update policy and the server compatibility window
3. The stage crossing the 25th is moved or made an explicit Go/No-Go decision

**Assertions**:
- [ ] No plan row claims an installed mobile binary can be rolled back
- [ ] A stage without a rollback row is a blocker (NOT READY)
- [ ] Every rollback row states its trigger, action, command for a human, time to effect, data considerations and whether it was rehearsed (date and evidence)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Review-Mode Exemption — the readiness review runs in solo mode

**Fixture**:
- As Case 1
- Review mode: `solo` in `project.yaml` (`modes.review_mode: solo`)

**Expected behavior**:
1. The skill does not resolve `review_mode`
2. SR-PRODUCTION-READINESS spawns exactly as in Case 1 and its outcome is recorded

**Assertions**:
- [ ] SKILL.md contains verbatim: "`/hotfix`, `/rollout-plan` and `/incident` are release-critical: every agent and gate they name runs at every `review_mode`. They do not resolve `review_mode`."
- [ ] `review_mode` is not among the skill's `--keys`
- [ ] SR-PRODUCTION-READINESS runs despite `solo`; no `[SR-PRODUCTION-READINESS] skipped — Solo mode` note appears anywhere in the plan

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: Always Collaborative — autonomous mode changes nothing

**Fixture**:
- As Case 1; `project.yaml` sets `modes.automation: autonomous`

**Expected behavior**:
1. The skill carries no automation prelude and never resolves `modes.automation`
2. The scope question, every section approval and every write are asked
3. Every deploy, production flag change, migration and store action in the plan is a command for a person, executed stage by stage through `/team-release`

**Assertions**:
- [ ] SKILL.md states that the skill is always collaborative, and `automation` is not among the keys
- [ ] "May I write this to `production/releases/1.0.0/rollout-plan.md`?" is asked even under `autonomous`
- [ ] The skill never executes a production-mutating command (e.g. `kubectl apply`, `helm upgrade`, `eas submit`, `fastlane supply` — all on the settings deny list)
- [ ] No commit is made without the user's instruction

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 8: Edge Case — CONCERNS and an unparseable gate reply

**Fixture**:
- As Case 1; the first `sre-engineer` reply begins "Overall the plan looks solid…" (no `[SR-PRODUCTION-READINESS]: TOKEN` first line)
- After a re-run, the reply is `[SR-PRODUCTION-READINESS]: CONCERNS` (the on-call rota has one person for the first 48 h)

**Expected behavior**:
1. The unparseable reply is shown in full as CONCERNS-class, and the skill says the verdict line was missing
2. The CONCERNS reply is surfaced with `Revise flagged items` / `Accept and proceed` / `Discuss further`
3. On `Accept and proceed`: recorded as `CONCERNS (accepted)`, with the accepted concern listed under `## Scope` with an owner; the verdict may be READY TO ROLL OUT

**Assertions**:
- [ ] A reply without a parseable first line is never treated as an approval
- [ ] Accepted concerns are recorded, never dropped ("Deferred is not forgotten")
- [ ] The skill does not auto-advance past a CONCERNS-class verdict without the user's choice

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses "May I write this to `<path>`?" before every write — the draft, every revision, the verdict
- [ ] Presents the scope, every drafted section and the verdict reasoning before requesting approval
- [ ] Ends with a recommended next step (`/launch-checklist <version>` and `/gate-check launch` in Hardening; `/team-release` and, after the rollout completes, `/retrospective release <version>` in Launch)
- [ ] Does not auto-create files without user approval
- [ ] Writes no evidence, reports or plans under `production/session-logs/` (gitignored)
- [ ] Never writes `modes.review_mode` or any other knob that `modes.rigor` fronts (`/settings` is the one exception)
- [ ] Never executes a deploy, a production flag change, a migration or a store submission; unset distribution, surfaces, regions or budgets are asked, never assumed

---

## Coverage Notes

- `enterprise` (ring deployment by tenant) and `internal` distributions are not
  fixture-tested.
- `performance.enforce: warn` (the stage owner decides, recorded) and `off`
  (informational, stated in the plan) are asserted only through Case 1's `block`
  counterpart.
- An open Critical or High security finding (named; the user decides whether it
  blocks the rollout) is not tested.
- The `REVISED` recording token (plan revised in response, review not re-run) is
  not tested.
