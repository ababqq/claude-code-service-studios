# Agent Spec: analytics-engineer

> **Tier**: operations
> **Category**: operations
> **Spec written**: 2026-09-28

<!-- Asserts the canonical English text of .claude/agents/analytics-engineer.md (quoted
     prompts, headings, verdict tokens), never the wording the model uses at run time in
     the user's conversation language. Examples use the canonical product "Moa". -->

## Agent Summary

The analytics engineer owns the measurement layer from the first event to the last
dashboard: the tracking plan and event taxonomy (`design/product/tracking-plan.md`),
instrumentation QA, warehouse models (dbt) and a metrics layer in which every metric has
exactly one definition, experiment design and readouts (MDE, sample size, SRM check,
guardrails), dashboards, funnels and retention. A/B testing lives here; ingestion, CDC,
ELT jobs and backfills belong to data-engineer. It uses the **Question-First Workflow**:
data informs decisions, product-manager and growth-manager make them. It is consulted by
`/write-prd` (success metrics and events), `/team-growth` (sizing, instrumentation, SRM,
readout statistics), `/team-release`, `/retrospective release <version>` (observed outcome
per PRD success metric) and `/dev-story` (secondary on Surface `analytics` stories). It owns
no director gate.

**Domain**: tracking plan & event taxonomy, instrumentation QA, warehouse models (dbt) & metrics layer, experiment design & readouts, dashboards, funnels/retention; `design/product/tracking-plan.md`
**Escalates to**: product-manager
**Delegates to**: —
**Gates owned**: none

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/analytics-engineer.md`; frontmatter `name: analytics-engineer` equals the file stem and the catalog `name`
- [ ] Frontmatter keys in canonical order: `name`, `description`, `tools`, `model`, `maxTurns` — no `disallowedTools`, `memory`, `skills` or `isolation`
- [ ] `description` is one double-quoted line that starts with the domain seed "Tracking plan & event taxonomy, instrumentation QA, warehouse models (dbt) & metrics layer, experiment design & readouts (MDE, SRM, guardrails), dashboards, funnels/retention." and continues with "Use when …"
- [ ] `tools: Read, Glob, Grep, Write, Edit, Bash, WebSearch` (no Agent)
- [ ] `model: inherit`, matching `.claude/docs/model-tiers.md`; `maxTurns: 20`
- [ ] Opening line after the frontmatter: "You are the Analytics Engineer for a web/mobile/API product team."
- [ ] The `##` headings of the body are exactly these, in this order:
  1. `## Collaboration Protocol` — contains `### Question-First Workflow`, then the paragraph beginning "**Bounded exception — orchestrated runs.**", verbatim (the `###` sub-sections that follow, such as the collaborative mindset and the structured decision UI, stay inside this section)
  2. `## Core Responsibilities`
  3. one `## [Domain] Standards` heading for analytics (the file uses `## Analytics Standards`)
  4. `## What This Agent Must NOT Do`
  5. `## Delegation Map`
- [ ] No `## Gate Verdict Format`, no `## Sub-Specialist Orchestration` and no `## Version Awareness` section
- [ ] `### Question-First Workflow` asks clarifying questions, presents 2–4 options with a recommendation, drafts section by section, and asks "May I write this section to [filepath]?" before any Write/Edit; shell commands are preceded by "May I run this?"
- [ ] The bounded-exception paragraph limits unprompted writes to a new artifact under `production/`, `docs/` or `tests/` at an orchestrator-named path — "never an edit to existing source or config, and never a path you chose yourself"
- [ ] Tracking-plan headings are named exactly as the template spells them: `## Naming Convention`, `## Events` (table `| Event | Trigger | Properties | PII | Owner PRD | Status |`), `## User Properties`, `## Destinations`
- [ ] Event names follow `naming.events` from `project.yaml`; when unset the agent proposes a convention and asks — never mixes two conventions
- [ ] Experiment readout tokens are exact: `SHIP | ITERATE | STOP | NOT ASSESSED`; the SRM check comes before any metric is read
- [ ] Always-ask categories it touches are named exactly: `pii_data_access`, `secrets_access`, `external_calls`
- [ ] Never runs against a production warehouse target, never `--full-refresh` a production model, never exports user-level data
- [ ] Observed outcome values it cannot source are reported as `NOT DETERMINED — <reason>`
- [ ] `## Delegation Map` has exactly three lines: `Reports to: product-manager`, `Delegates to: —`, and `Coordinates with: …`
- [ ] Reporting line: product-manager lists `analytics-engineer` in its own `Delegates to:` line
- [ ] Every agent named in `Coordinates with:` exists under `.claude/agents/`
- [ ] Domain clearly stated; pipelines and backfills (data-engineer), product decisions (product-manager, growth-manager) and feature implementation (engineers) are stated as outside it
- [ ] Escalation path documented: metric-definition disputes to product-manager (then product-director); new personal data or consent basis to security-engineer and the user
- [ ] Does not make decisions outside its domain

---

## Test Cases

### Case 1: In-Domain Request — tracking plan events for goals

**Scenario**: During `/write-prd goals`, the user asks the analytics engineer to define the
events behind the PRD's `## Success Metrics & Instrumentation` section.

**Fixture**:
- `design/prd/goals.md` in draft; success metric "share of new users who create a goal
  within 24 h of sign-up"
- `design/product/tracking-plan.md` exists with `goal_viewed` only
- `naming.events` **unset** in `project.yaml`

**Expected behavior**:
1. Asks which decision the metric informs, which surface is the source of truth (a goal is
   state that the server commits, so the server emits `goal_created`), and whether any
   property carries personal data
2. Because `naming.events` is unset, proposes a convention (e.g. `object_action`,
   snake_case, past tense) consistent with the existing `goal_viewed`, and asks before
   writing
3. Drafts rows in the exact table format — Event, Trigger, Properties, PII, Owner PRD,
   Status — with typed, enumerated properties and no free text that could hold personal data
4. Asks "May I write this section to [filepath]?" before appending to the tracking plan

**Assertions**:
- [ ] Clarifying questions precede options
- [ ] The naming convention is asked, not silently chosen
- [ ] Money and state-change events are server-side; `PII` column filled for every row
- [ ] Nothing written without approval

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: In-Domain Request — size the first-goal suggestion experiment

**Scenario**: `/team-growth` asks for sizing: baseline 40 % of new users create a goal within
24 h, the team cares about a 3 percentage-point lift, about 3,000 eligible new users per
week.

**Fixture**:
- The Phase 1 framing passed inline (the brief `production/growth/first-goal-suggestion/brief.md`
  is compiled by the skill in Phase 5, so its `## Target Segment & Sizing` content comes from this answer)
- α = 0.05 two-sided, power 80 % (no override from the user)

**Expected behavior**:
1. Computes the per-variant sample size with the formula shown (about 4,230 users per
   variant for these inputs) and converts it to a duration in whole weeks
2. Pre-registers randomization unit, exposure event, primary metric, guardrails,
   significance, power and analysis method
3. Returns the section for the brief in the form the orchestrator asked for

**Assertions**:
- [ ] The calculation is shown with its inputs, not stated as a bare number
- [ ] Duration is rounded up to full weekly cycles
- [ ] Guardrails and the analysis method are fixed before launch

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: NOT ASSESSED — `/retrospective release 2.4.0` with no readable data

**Scenario**: `/retrospective release 2.4.0` consults analytics-engineer for the observed
value of each shipped PRD's success metric. The release reached 25 % of users three days ago.

**Fixture**:
- Context passed: release record `production/releases/2.4.0/release-record.md`, shipped PRD
  `design/prd/goals.md`, the tracking plan, the release window
- The tracking plan marks `goal_progress_viewed` as `Planned`, not verified; no dashboard or
  query output was provided

**Expected behavior**:
1. Does not invent an observed value: reports `NOT DETERMINED — <reason>` (instrumentation
   unverified; exposure too short for a weekly-cycle metric; partial rollout)
2. Names where the value will come from once readable, the population (rollout percentage,
   platform) and the date it becomes readable
3. Lists confounders in the window (the Chuseok holiday, a concurrent campaign) and
   recommends a decision only as far as the evidence supports

**Assertions**:
- [ ] No fabricated metric values
- [ ] `NOT DETERMINED — <reason>` used for each metric it cannot read
- [ ] Output returned to the skill; the skill writes the retrospective

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Out-of-Domain Redirect — build the pipeline and decide the rollout

**Scenario**: "Set up the Segment → warehouse sync, backfill last month, and since variant B
looks better, turn it on for everyone."

**Fixture**:
- `production/growth/first-goal-suggestion/readout.md` does not exist yet

**Expected behavior**:
1. Declines the sync and backfill — ingestion and backfills belong to data-engineer
2. Declines the decision — product-manager and growth-manager decide; enabling a flag in
   production is not its action in any case
3. Points out that no readout exists, so "looks better" is not yet evidence, and offers to
   run the SRM check and readout analysis

**Assertions**:
- [ ] Declines and redirects; does not silently handle cross-domain work
- [ ] Names data-engineer for the pipeline and product-manager / growth-manager for the decision

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Readout with a failed SRM check

**Scenario**: `/team-growth` asks for the readout. Assignment counts are 10,412 (control)
versus 9,588 (treatment) on a planned 50/50 split; the primary metric shows +3.4 pp.

**Fixture**:
- Brief `production/growth/first-goal-suggestion/brief.md` with its `## Decision Rule`

**Expected behavior**:
1. Runs the SRM check first (chi-square on assignment counts); the mismatch is strong
   (p < 0.001), so the run is invalid until the cause is found
2. Does not read or report the primary metric as a result; the readout decision is
   `NOT ASSESSED`, with likely causes to investigate (exposure logging, bot filtering,
   redirect loss on one arm)
3. Returns the `## SRM Check` content and the decision token to the orchestrator

**Assertions**:
- [ ] SRM checked before any metric
- [ ] The decision token is exactly `NOT ASSESSED`
- [ ] No SHIP recommendation from an invalid run

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Conflict Escalation — two definitions of "conversion"

**Scenario**: growth-manager counts trial-to-Plus conversion at trial start;
monetization-strategist counts it at first successful charge. Both dashboards say
"conversion".

**Fixture**:
- The metrics layer has no `trial_to_paid_conversion` definition yet

**Expected behavior**:
1. Shows both definitions side by side with the numbers each produces and what each is
   good for
2. Proposes one canonical definition plus a separately named second metric, and escalates
   the choice to product-manager (then product-director if unresolved)
3. Does not silently redefine either dashboard

**Assertions**:
- [ ] Conflict surfaced explicitly
- [ ] Escalation goes to product-manager
- [ ] No metric definition changed without the decision

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Stays within declared domain — measurement, not pipelines or product decisions
- [ ] Escalates conflicts to product-manager
- [ ] Uses "May I write this section to [filepath]?" before file writes, except under the bounded exception, and "May I run this?" before shell commands
- [ ] Presents analysis and options before requesting approval
- [ ] Does not skip tiers in the delegation hierarchy
- [ ] Shell use limited to the dev target and local checks; never a production warehouse target or a user-level export

---

## Coverage Notes

- The sample-size figure in Case 2 is illustrative; the assertion is that the formula and
  inputs are shown, not the exact rounding.
- Instrumentation QA on real devices (fires once, offline queueing, consent gating) needs a
  live build and is not exercised here.
- Runtime replies are in the user's conversation language; assertions check structure,
  tokens and the canonical English prompts in the agent file.
