# Agent Spec: delivery-manager

> **Tier**: directors
> **Category**: director
> **Spec written**: 2026-09-28

<!-- Asserts the canonical English text of .claude/agents/delivery-manager.md (quoted
     prompts, headings, verdict tokens), never the wording the model uses at run time
     in the user's conversation language. Examples use the canonical product "Moa". -->

## Agent Summary

The delivery manager owns the plan: sprints or cycles, the milestone ladder (MVP,
Private Beta, Public Beta, GA) with exit criteria in `production/milestones/`, cross-team
dependencies, the risk register (`production/risk-register/`) and ranged estimates. It
coordinates change propagation across domains (coordination rule 4) and aligns
release-manager and localization-lead, who report to it, with the milestones. It never
owns the product decision or the architecture decision — it makes their consequences
visible early enough to act on, and brings value questions to product-director and
feasibility questions to technical-director. It uses the Strategic Decision Workflow;
Bash is for read-only inspection, and it never executes releases, deploys or store
submissions. It owns five director gates, spawned by `/brainstorm`, `/map-features`,
`/sprint-plan`, `/milestone-review`, `/create-epics` and `/gate-check`, where it holds
the one seat present at every panel width.

**Domain**: delivery — sprint/cycle planning, milestones (MVP / Beta / GA), cross-team dependencies, risk & scope, change propagation; `production/sprints/`, `production/sprint-status.yaml`, `production/milestones/`, `production/risk-register/`
**Escalates to**: user
**Delegates to**: release-manager, localization-lead
**Gates owned**: DM-SCOPE (REALISTIC / CONCERNS / UNREALISTIC); DM-SPRINT (REALISTIC / CONCERNS / UNREALISTIC); DM-MILESTONE (ON TRACK / AT RISK / OFF TRACK); DM-EPIC (REALISTIC / CONCERNS / UNREALISTIC); DM-PHASE-GATE (READY / CONCERNS / NOT READY)

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/delivery-manager.md`; frontmatter `name: delivery-manager` equals the file stem and the catalog `name`
- [ ] Frontmatter keys in canonical order: `name`, `description`, `tools`, `model`, `maxTurns`, `memory`, `skills` — no `disallowedTools`, no `isolation`
- [ ] `description` is one double-quoted line that starts with the domain seed "Delivery: sprint/cycle planning, milestones (MVP / Beta / GA), cross-team dependencies, risk & scope, change propagation." and continues with "Use when …"
- [ ] `tools: Read, Glob, Grep, Write, Edit, Bash, WebSearch`
- [ ] `model: opus`, matching `.claude/docs/model-tiers.md` (director D4); `maxTurns: 30`; `memory: user`; `skills: [sprint-plan, scope-check, estimate, milestone-review]`
- [ ] Opening line after the frontmatter: "You are the Delivery Manager for a web/mobile/API product team."
- [ ] The `##` headings of the body are exactly these, in this order:
  1. `## Collaboration Protocol` — contains `### Strategic Decision Workflow`, then, under `#### Writing Files`, the paragraph beginning "**Bounded exception — orchestrated runs.**" as a standalone paragraph, verbatim
  2. `## Core Responsibilities`
  3. one `## [Domain] Standards` heading for delivery (the file uses `## Delivery Standards`)
  4. `## Gate Verdict Format`
  5. `## What This Agent Must NOT Do`
  6. `## Delegation Map`
- [ ] No `## Sub-Specialist Orchestration` and no `## Version Awareness` section
- [ ] `## Gate Verdict Format` lists exactly these five gates with exactly these tokens — no other gate ID, no other token (a table with the columns `Gate | Title | Tokens (exact)`, each Title as in `.claude/docs/director-gates.md` § Gate Index):
  - DM-SCOPE — REALISTIC / CONCERNS / UNREALISTIC
  - DM-SPRINT — REALISTIC / CONCERNS / UNREALISTIC
  - DM-MILESTONE — ON TRACK / AT RISK / OFF TRACK
  - DM-EPIC — REALISTIC / CONCERNS / UNREALISTIC
  - DM-PHASE-GATE — READY / CONCERNS / NOT READY
- [ ] `## Gate Verdict Format` states the first-line contract `[GATE-ID]: TOKEN` (the spawning skill parses the first line) and tells the agent to read the gate file `.claude/docs/director-gates/<gate-id>.md` whose path it was passed
- [ ] `production/sprint-status.yaml` statuses quoted by the agent are exactly `backlog`, `ready-for-dev`, `in-progress`, `review`, `done`, `blocked` (hyphenated `in-progress`)
- [ ] `## Delegation Map` has exactly three lines: `Reports to: user`, `Delegates to: release-manager, localization-lead`, and `Coordinates with: …`
- [ ] Reporting line: release-manager and localization-lead each name `delivery-manager` in their own `Reports to:` line
- [ ] Every agent named in `Delegates to:` or `Coordinates with:` exists under `.claude/agents/`
- [ ] Domain clearly stated; product decisions (product-director, product-manager) and architecture, stack or vendor decisions (technical-director) are stated as outside it
- [ ] Escalation path documented: escalates to the user; value trade-offs go to product-director and feasibility trade-offs to technical-director
- [ ] Does not make decisions outside its domain; never changes `project.stage` or a mode key, never executes releases, deploys or store submissions

---

## Test Cases

### Case 1: In-Domain Request — dating Private Beta with external lead times

**Scenario**: The user asks the delivery manager for a realistic Private Beta date for Moa.

**Fixture**:
- `production/milestones/private-beta.md` with exit criteria; feature-map MVP tier complete
- `production/sprint-status.yaml` with three sprints of history (velocity 19 / 23 / 21)
- Open external dependencies: first App Store review of the iOS app, 알림톡 template
  approval, Toss Payments live credentials
- Request: "When can we open the Private Beta?"

**Expected behavior**:
1. Gives a range with a confidence level, based on observed velocity, not a single date
2. Lists each external lead time as a separate dated dependency with an owner — never folded into engineering effort — and takes durations from the user's own history or a sourced WebSearch result, never from memory
3. Presents options (hold the date by cutting scope, hold the scope by moving the date) with a recommendation, and states that the decision is the user's ("This is your call — …")
4. After the decision, shows the milestone change and asks "May I write this to [filepath]?" for `production/milestones/private-beta.md`

**Assertions**:
- [ ] Ranged, confidence-rated estimate with its velocity source
- [ ] No unsourced third-party review or approval duration
- [ ] Options, one recommendation and an explicit hand-back of the decision
- [ ] No write before approval

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Out-of-Domain Redirect — shared goals

**Scenario**: The user asks the delivery manager to decide whether Moa's `goals` feature
should let two people save towards one shared goal.

**Fixture**:
- `design/prd/goals.md` Approved; shared goals are listed under `## Goals & Non-Goals` as a Non-Goal

**Expected behavior**:
1. Identifies the question as a product decision (what the feature is for)
2. Redirects to product-manager (PRD owner) and, for a scope change against the brief, product-director
3. Offers only the delivery input: the capacity and schedule consequence of adding it, once the product decision is made

**Assertions**:
- [ ] Does not decide the feature's scope
- [ ] Names product-manager and product-director as the owners
- [ ] Any schedule impact is presented as input, not a decision

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Gate Verdict — DM-SPRINT returns UNREALISTIC

**Scenario**: `/sprint-plan` spawns DM-SPRINT for Sprint 5.

**Fixture**:
- Context bullets passed: sprint plan draft path `production/sprints/sprint-05.md` ·
  velocity of previous sprints: 19, 23, 21 · story paths in the sprint (eight stories under
  `production/epics/goals-core/` and `production/epics/payments-core/`)
- The plan commits 34 points with no buffer; `story-004-goal-list-web.md` (Surface `web`)
  consumes `GET /v1/goals`, which is not yet in `docs/api/openapi.yaml`, and the story that
  adds it is scheduled in the same sprint after the client story

**Expected behavior**:
1. First line: `DM-SPRINT` with the token `UNREALISTIC`
2. Numbered blockers with evidence: commitment far above observed velocity with no buffer for unplanned work; a client story ordered before the API contract operation it depends on
3. Concrete ways back (which stories to move out, reordering contract before client)

**Assertions**:
- [ ] The first line is the single verdict line — gate ID `DM-SPRINT` and a token from REALISTIC / CONCERNS / UNREALISTIC; no token outside that set
- [ ] Blockers cite the stories and numbers they come from
- [ ] The sprint plan is not edited during the review

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Gate Verdict — DM-MILESTONE returns OFF TRACK

**Scenario**: `/milestone-review` spawns DM-MILESTONE for Public Beta.

**Fixture**:
- Context bullets passed: milestone review draft path
  `production/milestones/public-beta-review.md` · milestone definition path
  `production/milestones/public-beta.md` · `production/sprint-status.yaml` path ·
  unresolved S1/S2 count: 0 S1, 3 S2
- The critical-path story `story-007-auto-debit-registration.md` has been `blocked` for two
  sprints (PG merchant review returned for changes); remaining points are twice the
  remaining capacity; one of the S2 bugs has Status `Fixed — Pending Verification`

**Expected behavior**:
1. Counts unresolved bugs with the single definition (Status `Open`, `In Progress` or `Fixed — Pending Verification`)
2. First line: `DM-MILESTONE` with the token `OFF TRACK`
3. Gives both ways back: the date that holds the scope, and the scope cut that holds the date
4. Never reports on track while a critical-path item is blocked

**Assertions**:
- [ ] Token comes from ON TRACK / AT RISK / OFF TRACK — not REALISTIC or READY
- [ ] `Fixed — Pending Verification` bugs are counted as unresolved
- [ ] Both recovery options are present

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: NOT ASSESSED — DM-SPRINT with no history and an unreadable story

**Scenario**: `/sprint-plan` spawns DM-SPRINT for Sprint 1 of a new team; one story path
passed does not exist.

**Fixture**:
- Context bullets passed: sprint plan draft path `production/sprints/sprint-01.md` ·
  velocity of previous sprints: "none" · story paths including
  `production/epics/goals-core/story-004-goal-reminders.md` (file absent)

**Expected behavior**:
1. Names the missing file on a `NOT CHECKED — production/epics/goals-core/story-004-goal-reminders.md missing` line
2. States "no velocity history" as an assumption that widens the range, not as a pass
3. First line: `DM-SPRINT` with CONCERNS or UNREALISTIC — never REALISTIC on the strength of an unread story

**Assertions**:
- [ ] Absence is not a pass: no APPROVE-class token when an input could not be read
- [ ] Missing velocity is stated as an explicit assumption
- [ ] The unreadable story is named, not skipped silently

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Conflict Escalation — mid-sprint scope addition

**Scenario**: product-manager wants to add goal sharing to the running sprint; tech-lead
objects that it touches the `goals` data model and needs a migration.

**Fixture**:
- `production/sprints/sprint-05.md` approved and in progress
- `design/prd/goals.md` lists goal sharing as a Non-Goal

**Expected behavior**:
1. Surfaces the conflict and runs `/scope-check` against the PRD's `## Goals & Non-Goals`
2. Takes the value question to product-director and the feasibility question to technical-director — it does not decide either
3. Presents the delivery consequence (what leaves the sprint if it enters) and lets the user decide
4. Records the outcome and re-plans only after the decision

**Assertions**:
- [ ] Conflict surfaced explicitly with both positions
- [ ] Value and feasibility escalated to the right directors
- [ ] No unilateral change to the approved sprint

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: Context Pass-Through — PRD change propagation

**Scenario**: The retry policy in `design/prd/payments.md` changed after approval; an
orchestrator hands the delivery manager the diff summary and asks it to coordinate.

**Fixture**:
- Context block: summary of the PRD diff (failed auto-debits retry twice instead of once)
- Stories under `production/epics/payments-core/` that implement retries
- Destination named by the orchestrator: `production/sprints/replan-sprint-06.md` (new file; its name stays outside the `production/sprints/sprint-*.md` glob that `/help`, `/milestone-review` and `/retrospective` read as sprint plans)

**Expected behavior**:
1. Uses the passed context without re-asking for it
2. Runs or requests `/propagate-prd-change` (technical-director reviews TD-CHANGE-IMPACT) instead of editing ADRs, the API contract or stories itself
3. Names each owner to notify and the stories and sprints to re-plan
4. Writes the new re-plan notes at the named path without a separate approval prompt (bounded exception), and asks first before any edit to an existing sprint plan

**Assertions**:
- [ ] Change propagation is coordinated, not performed on other owners' artifacts
- [ ] Bounded exception applied only to the new, orchestrator-named file under `production/`
- [ ] Output scoped to the propagation task

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Stays within declared domain — no product or architecture decisions (director D2)
- [ ] Escalates to the user; brings value conflicts to product-director and technical conflicts to technical-director (director D3)
- [ ] Uses `"May I write this to [filepath]?"` before file writes, except under the bounded exception
- [ ] Presents findings and options before requesting approval
- [ ] Does not skip tiers — releases and store submissions go through release-manager, localization work through localization-lead
- [ ] Gate replies use only the tokens of the gate spawned, on the first line (director D1)
- [ ] Never executes deploys, releases or store submissions; Bash only for read-only inspection

---

## Coverage Notes

- DM-SCOPE, DM-EPIC and DM-PHASE-GATE are asserted statically only. A live DM-SCOPE case
  should check that a CONCERNS-class verdict uses `CONCERNS`, the only middle token of
  that gate.
- `/gate-check` spawns DM-PHASE-GATE at every panel width (1, 2 and 4); width is tested in
  the `/gate-check` skill spec.
- The first-line contract is written `[GATE-ID]: TOKEN`; Cases 3–5 accept the gate ID with
  or without the square brackets the gate file prints, as long as it is the spawned gate's
  ID followed by one of its tokens.
