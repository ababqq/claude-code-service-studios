---
name: team-growth
description: "Growth experiment or lifecycle campaign: hypothesis, sizing, instrumentation, variants as stories, rollout, readout."
argument-hint: "[experiment or campaign description | readout <experiment-slug>] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, Agent, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskUpdate, Bash(bash "*/.claude/skills/team-growth/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,automation_always_ask,team.size,compliance,surfaces`

Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**Argument check:** If no argument is provided, output:
> "Usage: `/team-growth [experiment or campaign description]` — describe the growth experiment or lifecycle campaign to plan (e.g., `goal-suggestion copy on the empty goals screen`, `D7 re-engagement push for users with no deposit`). `/team-growth readout <experiment-slug>` writes the readout of an experiment that has finished running."
Then stop immediately without spawning any subagents or reading any files.

When this skill is invoked with a description, orchestrate the growth team through the
planning pipeline (Phases 1–6) and write the experiment brief. When it is invoked as
`readout <experiment-slug>`, skip to Phase 7 and write the readout. An experiment is planned
before it runs and read out after it has run for its planned duration — the two are
separate invocations, weeks apart.

**Decision Points:** At each phase transition, use `AskUserQuestion` to present
the user with the subagent's proposals as selectable options. Write the agent's
full analysis in conversation, then capture the decision with concise labels.
In `collaborative` mode, the user must approve before moving to the next phase.
In `guided` mode the pipeline advances automatically unless a phase is BLOCKED;
in `autonomous` mode it runs end to end, recording each phase outcome via
`log_decision`. Decisions in `automation_always_ask` categories
(`is_always_ask_category` helper) always prompt regardless of mode. See
`.claude/docs/automation-modes.md`.

**Always-ask categories this pipeline reaches** (check each against the resolved
`automation_always_ask` line):
- **Pricing experiments are `billing_changes`** — any variant that changes a price, plan,
  trial length, entitlement, promotion or payment method prompts in every mode, including
  `autonomous`.
- `production_deploys` — turning the experiment flag on in production, and every change to
  its allocation (Phase 6). A human flips the flag; this skill never does.
- `pii_data_access` — any query or export of user-level data for sizing or the readout.
  Aggregates are enough for both; ask before touching anything else.
- `scope_changes` — adding a variant to a story that is already in an approved sprint.

**Outputs:**

| Path | Phase | Written by |
|------|-------|------------|
| `production/growth/<experiment-slug>/brief.md` | 5 | this skill, after "May I write" |
| `design/product/tracking-plan.md` (updates) | 2 | this skill, after "May I write" |
| `production/growth/<experiment-slug>/readout.md` | 7 (`readout` mode) | this skill, after "May I write" |

`<experiment-slug>` is kebab-case and names the change (`first-goal-suggestion`,
`d7-push-no-deposit`). Reuse it in the experiment's flag key, so the brief, the flag and the
readout can each be found from the others.

Track each phase as a task (`TaskCreate` at the start, `TaskUpdate` when it resolves) so the
readout run weeks later can see what was planned.

## Phase 0: Resolve Config

The block at the top of this skill resolved `review_mode`, `automation`,
`automation_always_ask`, `team.size`, `compliance` and `surfaces`.

`review_mode` sets gate depth for every gate this run reaches:
- `full` → spawn as normal
- `lean` → **skip every gate whose ID does not end in `-PHASE-GATE`**. Note: `[GATE-ID] skipped — Lean mode`
- `solo` → skip all gates. Note: `[GATE-ID] skipped — Solo mode`

This skill spawns no gate itself — `.claude/docs/director-gates.md` § Gate Index lists no gate under `/team-growth` (Spawned by column). Pass
`--review <resolved review_mode>` to any gate-using skill it hands variant work to.

Unset on an unconfigured project: `modes.rigor` defaults to `minimal`, which resolves `review_mode` to `solo`.

`automation` drives the Decision Points note above. See the Decision Points note above and
`.claude/docs/automation-modes.md` for how each mode changes pipeline behavior.

**`compliance`** drives the Consent & Channel Check (Phase 3). `regions=none` means the
user declared no regional obligations — the check still records that it ran and why nothing
applied. The unset form means the regions are unknown: ask which regions the experiment's
users are in before Phase 3 — unset is not "none".

**`surfaces`** decides where variants can live (web, iOS, Android, API) and therefore how
variant stories are routed in Phase 5. Unset ⇒ ask which surfaces this experiment touches.

**`team.size`**: which agents are active (orthogonal to review_mode gate-depth and workflow docs).
- **`individual`**: `growth-manager` runs the pipeline; sizing, instrumentation, variant
  design and copy are consulted through it, not spawned separately.
- **`small`**: the documented pipeline — `growth-manager` → `analytics-engineer` (tracking,
  MDE, SRM, guardrails) → `product-designer` ∥ `ux-writer` → hand-off of variants as stories.
- **`studio`**: the `small` pipeline + `monetization-strategist` (pricing, promotion and
  entitlement variants), `customer-success-manager` (support readiness, macros, VOC
  signals) and `data-engineer` (event pipelines, exposure logging, backfills for the readout).
Team skills spawn only the gates `.claude/docs/director-gates.md` § Gate Index lists this skill under (Spawned by column), after the review-mode check (lean suffix rule); team-size scoping never removes a director gate. A non-core agent needed at `individual` routes through the nearest active core agent with an informational note. **"Phase gate" means any phase that ends in an `AskUserQuestion` decision point before the pipeline advances** — not every phase. Apply the test literally: if the phase below has no decision point, it is not a gate, and an agent restricted to "phase gates only" is not spawned for it. This active-set scoping applies throughout the pipeline below: any phase that names an agent outside the active set routes through the nearest core agent rather than spawning it.

Unset on an unconfigured project, `modes.rigor` defaults to `minimal`, which resolves
`team.size` to `individual`.

**Announce the active set before Phase 1 — never let the collapse be silent.**
Before spawning anything, state in one line which agents this run will actually
spawn, and which the pipeline below names but will **not** spawn at the resolved
`team.size`. For example:

> `Active set (team.size: <resolved>): <the agents listed for that size above>.`
> `Not spawned this run: <every other agent this pipeline names> — consulted`
> `through <nearest active core agent>. Raise team.size (or modes.rigor) to widen.`

Fill it from the `team.size` list directly above and the agents this file's own
pipeline names — not from an example. Both sets differ per orchestrator.

The pipeline below reads as a multi-agent fan-out and at the shipped default it
is one or two agents — `team-release` names nine agents and at `individual` runs
`release-manager` alone; `team-content` names four and at the same size runs
`ux-writer` alone. **The collapse is correct**: `team.size` is rigor-fronted and the
narrow default is the token lever, measured at roughly 10x. What was wrong is that
nothing said so, so a reader could not distinguish a correctly-collapsed run from a
broken pipeline, and the per-agent "routes through the nearest core agent with an
informational note" rule above fires at routing time and never states the shape of
the run as a whole.

This is the same rule as the skipped-check reporting elsewhere in this file: **a constraint that is enforced but never surfaced is
indistinguishable, to the person reading the output, from one that was never
enforced.**

## Team Composition

- **growth-manager** — Owns the experiment: hypothesis, segment, primary metric, variants,
  decision rule, lifecycle journeys (push / email / 알림톡), experiment roadmap
- **analytics-engineer** — Baseline, MDE, sample size and duration, SRM check, guardrails,
  exposure and variant events, readout statistics
- **product-designer** — Variant screens and states (onboarding steps, paywall, empty states)
- **ux-writer** — Variant copy and message templates in the voice of
  `design/brand/voice-and-tone.md`, per locale
- **monetization-strategist** (`studio`) — Pricing, trial, promotion and entitlement
  variants; price display and refund implications
- **customer-success-manager** (`studio`) — Support readiness: macros, help-center notes,
  VOC and app-review signals to watch while the experiment runs
- **data-engineer** (`studio`) — Exposure logging and event ingestion, warehouse tables the
  readout reads, backfills

## How to Delegate

Use the `Agent` tool to spawn each team member as a subagent:
- `subagent_type: growth-manager` — Framing, variants, decision rule, lifecycle journeys
- `subagent_type: analytics-engineer` — Sizing, instrumentation, SRM and guardrails, readout statistics
- `subagent_type: product-designer` — Variant screens and states
- `subagent_type: ux-writer` — Variant copy and message templates
- `subagent_type: monetization-strategist` — Pricing and promotion variants (`studio`)
- `subagent_type: customer-success-manager` — Support readiness (`studio`)
- `subagent_type: data-engineer` — Exposure logging and readout data (`studio`)

**Brief each agent — do not dump context.** Read the shared inputs **once** and pass a distilled brief inline: the lines each agent actually needs, never a file path for a document you have already read (an agent handed a path re-reads the whole file). Pass a path only for a document you have not read and only that agent needs.

**End every agent prompt with a return contract:** "Write your full output to `[path]` — that named path is your write authorisation under the bounded exception below, so write it without a separate approval prompt. Return **only** (1) the path written, (2) a ≤5-bullet summary of decisions, (3) any BLOCKED/CONCERNS items, one line each. Do not restate the documents you read." Without it, an agent returns everything it read back into this session.

**Substitute a real path for `[path]`.** In this pipeline the agents' working notes are not
separate artifacts — the brief is the one record — so each agent returns its section
inline under the same return contract with "(1) the path written" replaced by "the brief
section you drafted", and **this skill** compiles the brief and the readout and writes them
after asking. That keeps a single file per experiment where `/help` and the readout run
look for it (`production/growth/<experiment-slug>/`).

> **Why this does not violate the Collaboration Protocol.** `CLAUDE.md` requires an agent to ask "May I write this to [filepath]?" before Write/Edit. A subagent spawned here writes **without** asking, and that is a deliberate, bounded exception rather than an oversight — the same call already made for `consistency-check` appending to `active.md`. The exception holds only when all three are true: (1) the path is one **you** named in the prompt, so the user approved the destination when they approved the phase; (2) it is a new artifact under `production/`, `docs/` or `tests/`, never an edit to existing source or config; (3) the phase that produced it is itself gated by an `AskUserQuestion` before the pipeline advances. Outside those three, the agent must ask. **Do not "fix" this by asking per subagent** — a prompt per agent per phase makes an orchestrator unusable, which is why the exception exists.

Launch independent agents in parallel where the pipeline allows it (Phase 4's
product-designer and ux-writer run simultaneously; at `studio` so do the three added roles).

## Pipeline

### Phase 1: Frame the experiment

Read, once: `design/product/product-brief.md` (`## Success Metrics`) or
`design/product/one-pager.md` (`## Success Signal`), `design/product/user-journey.md`
(`## Drop-off Risks`, `## Metrics per Stage`) when it exists, the PRDs of the features the
experiment touches, and every existing `production/growth/*/brief.md` (to avoid overlapping
experiments on the same surface and segment).

Delegate to **growth-manager**:
- **Kind** — an A/B (or multivariate) experiment, or a lifecycle campaign (a CRM journey
  with a holdout group). A campaign without a holdout cannot be read out: say so and add
  one, or record that the readout will be NOT ASSESSED.
- **Hypothesis** — "Because [evidence], we believe [change] for [segment] will move
  [metric] by at least [MDE], measured by [event], without harming [guardrails]." Evidence
  is a funnel number, a usability finding or VOC, never a hunch presented as data.
- **Target segment** — who is eligible, who is excluded (users without marketing consent
  for a promotional channel, users in an open payment dispute or support escalation,
  internal and test accounts), and the randomization unit (user, not session or device, for
  anything a user sees twice).
- **Primary metric and guardrails** — one primary metric; guardrails that must not degrade
  (unsubscribe or push opt-out rate, crash-free sessions, refund and chargeback rate,
  support tickets per 1,000 users, D7 retention for an activation test).
- **Variants** — control plus one or two treatments, each described by what the user sees.
- **Decision rule** — written before launch: what result ships, iterates or stops,
  including the guardrail breach that overrides a primary-metric win.
- **Overlap** — experiments already running on the same surface or segment, and how
  allocation keeps them independent.

Moa example (`first-goal-suggestion`; numbers illustrative): *"Because a large share of new
users who finish sign-up never create a goal, we believe suggesting a pre-filled first goal
('비상금 100만원') to new users will raise the share who create a goal within 24 h of sign-up
by at least 3 percentage points, measured by `goal_created`, without raising onboarding
abandonment or support contacts."*

Use `AskUserQuestion`:
- Prompt: "Hypothesis, segment, metric and decision rule ready. Proceed to sizing?"
- Options: `[A] Proceed` / `[B] Revise the framing` / `[C] Stop here`

### Phase 2: Sizing & instrumentation (analytics-engineer)

Delegate to **analytics-engineer** (brief: the Phase 1 framing, the tracking plan's
`## Events` rows for the metrics involved):
- **Baseline and MDE** — the primary metric's current value and the smallest effect worth
  detecting. No sourced baseline ⇒ `NOT DETERMINED — baseline for <metric>`; the sample size
  below is then an estimate from a stated assumption, and the brief says which.
- **Sample size and duration** — per variant, at the stated significance level and power
  (default two-sided α = 0.05, power 0.8 unless the decision rule says otherwise), converted
  into days from eligible traffic; whole weeks, to cover weekday and payday cycles. Cross-
  check the arithmetic with Bash (a short `python3` two-proportion calculation, shown to the
  user) before accepting it.
- **SRM check** — the expected allocation ratio and the test used at readout (chi-square on
  assignment counts); an SRM failure invalidates the result.
- **Guardrail thresholds** — the degradation that stops the experiment early, and who is
  paged.
- **Instrumentation** — the events the metrics need, taken from the tracking plan by name;
  the exposure event (`experiment_exposed` with `experiment_key` and `variant`, fired where
  the user actually sees the variant, not at assignment); any new event, with trigger,
  properties and PII classification.
- **Stopping and peeking** — fixed-horizon by default; a sequential method only when
  declared in the decision rule before launch.

New or changed events go into `design/product/tracking-plan.md` `## Events` with
`Status: Planned` and the owning PRD. Show the rows and ask "May I write this to
`design/product/tracking-plan.md`?" before editing it. No tracking plan exists ⇒ offer to
create it from `.claude/docs/templates/tracking-plan.md` (same question), or record the events
only in the brief and flag `NOT CHECKED — tracking plan absent`.

**`studio` only** — spawn **data-engineer** in parallel: where exposure and the metric
events land, the warehouse tables and the join the readout will use, and whether a
backfill is needed for the baseline.

### Phase 3: Consent & Channel Check

Runs **before** any campaign, push / email / SMS / 알림톡 template or marketing copy is
approved — the variant work in Phase 4 depends on its outcome.

For each region in the resolved `compliance` line, read `.claude/docs/compliance/<region>.md`
and list its applicable items — `## Marketing Messages & Consent` always;
`## Commerce & Payments` for pricing, trial or promotion variants;
`## Privacy & Data Protection` for new data collection or profiling. For `kr` that includes: prior opt-in for advertising messages,
separate consent for night-time sending, periodic confirmation of that consent, a working
unsubscribe path and sender identification in every advertising message; and **KakaoTalk
알림톡 carries informational messages only** — promotional content goes through a channel
that has advertising consent. Each item is marked by the user as **confirmed** (how it is
met: the consent flag the segment filters on, the unsubscribe link, the template category)
or **explicitly accepted** (with the reason). An item neither confirmed nor accepted blocks
the brief's approval.

- **Regions unset** ⇒ ask which regions apply; do not proceed on an assumption.
- **`regions=none`** ⇒ record
  `Consent & Channel Check: no regions configured (compliance.regions: [])` and still
  confirm the in-product basics: an opt-out for every message stream and quiet hours for
  push.
- A compliance file that is missing for a configured region ⇒
  `NOT CHECKED — .claude/docs/compliance/<region>.md absent`; the brief cannot be approved
  until the user accepts that gap explicitly.

This is a checklist against the reference, not legal advice; the reference states no
deadlines or thresholds, and neither does this skill.

### Phase 4: Variant design (product-designer ∥ ux-writer)

Delegate in parallel — issue both `Agent` calls before waiting for either:
- **product-designer**: each treatment's screens and states, reusing
  `design/ux/interaction-patterns.md`; how the variant degrades when the flag service is
  unreachable (control is the fallback).
- **ux-writer**: each treatment's copy and message templates in the voice of
  `design/brand/voice-and-tone.md`, per locale in `localization.locales` (read from
  `project.yaml`); push titles within platform truncation; the advertising label and
  unsubscribe line where Phase 3 requires them; 알림톡 templates written as informational
  messages for template approval.

**`studio` only**, in parallel:
- **monetization-strategist** for any pricing, trial, promotion or entitlement variant:
  price display (tax-inclusive, currency), what existing subscribers see, refund and
  cancellation behaviour, store billing constraints on iOS and Android, and abuse vectors
  (coupon stacking, trial cycling). Every such variant is a `billing_changes` decision.
- **customer-success-manager**: the macros and help-center notes support needs from the
  first exposure, and the VOC and app-review signals to watch while the experiment runs.

Use `AskUserQuestion`:
- Prompt: "Variants ready. Approve them for the brief?"
- Options: `[A] Approve` / `[B] Revise [variant]` / `[C] Drop a variant` / `[D] Stop here`

### Phase 5: Brief and variant stories

Compile the brief yourself from Phases 1–4 — do not re-spawn an agent to re-send what this
session already holds. Use these headings exactly, in this order (skills and readers match
on them):

```markdown
# Growth Experiment Brief: [experiment name]

> **Kind**: experiment | lifecycle campaign
> **Status**: Draft | Approved | Running | Concluded
> **Owner**: growth-manager
> **Last Updated**: [YYYY-MM-DD]

## Hypothesis
## Target Segment & Sizing
[eligibility, exclusions, randomization unit; baseline, MDE, sample size per variant, duration]
## Primary Metric & Guardrails
## Variants
## Instrumentation
[events from the tracking plan by name, exposure event, new events and their tracking-plan status]
## Flag & Rollout
[flag key, allocation per variant, ramp (e.g. 5% → 50/50), kill switch, start and end dates]
## Consent & Channel Check
[per region: item — confirmed (how) | accepted (why); or the NOT CHECKED line]
## Stories
[one line per variant work item: Surface, route, story path — or "pending: <command>"]
## Decision Rule
```

**Variants become routed stories — this skill writes no code.** For each work item, name the
Surface and the route:
- **a new change** (a variant screen, copy, template or pricing table behind the flag) →
  `/quick-spec` writes the spec and its story embed, `/create-stories <epic-slug>` creates the
  story, and `/dev-story <story-path>` implements it, routed by the story's Surface (`web` →
  frontend-engineer, `ios` / `android` / `mobile` → mobile-engineer, `api` →
  backend-engineer, `admin` → internal-tools-engineer);
- **an addition to a story that is still open** (the screen the variant changes is being
  built this sprint) → `/dev-story <story-path>` on that story, with the variant and its flag
  added to its acceptance criteria after the user approves the change (a `scope_changes`
  decision).

Pass `/quick-spec` the experiment slug and variant name. It reads `## Variants`,
`## Flag & Rollout`, `## Primary Metric & Guardrails` and `## Instrumentation` from
`production/growth/<experiment-slug>/brief.md` and writes one spec per variant to
`design/quick-specs/`.

Record each in `## Stories` as `pending: <command>` until the story exists, then its path.

Ask "May I write this to `production/growth/<experiment-slug>/brief.md`?" and write it on
approval with `> **Status**: Draft`, or `Approved` when the user approves the plan in the
same step. Approval requires every Consent & Channel item to be confirmed or accepted.

### Phase 6: Rollout

List the rollout steps for a human to run: create the flag with the key and allocation in
the brief (off in production), verify exposure logging on staging, then turn it on in
production at the first ramp step. **Turning the flag on, and every allocation change, is a
`production_deploys` decision** — the user runs it and confirms; this skill never changes a
production flag. Record the start date in `## Flag & Rollout` after asking "May I write this
to `production/growth/<experiment-slug>/brief.md`?" and set `> **Status**: Running`.

State the readout date (start + planned duration) and the command to run then:
`/team-growth readout <experiment-slug>`.

### Phase 7: Readout (`readout <experiment-slug>`)

Read `production/growth/<experiment-slug>/brief.md`. Absent ⇒ stop:
`NOT ASSESSED — no brief at production/growth/<experiment-slug>/brief.md`.

Delegate to **analytics-engineer** with the brief's sizing, metrics, guardrails and decision
rule, and the aggregated results the user provides (or the queries to run —
`pii_data_access` applies to anything below aggregate level):
- **SRM Check** — observed assignment counts against the planned ratio. **SRM failure ⇒
  the result is invalid and the verdict is NOT ASSESSED**, whatever the metric shows.
- **Primary Metric** — effect size with confidence interval per treatment, against the MDE.
- **Guardrails** — each guardrail's change and whether it breached its threshold.
- **Segments** — pre-declared segments only (platform, new vs returning, plan); anything
  else is labelled exploratory and does not drive the decision.
- **Result** — one paragraph a non-analyst can act on.

Apply the brief's decision rule — never a rule invented after seeing the data:
- **SHIP** — the treatment met the rule and no guardrail breached; roll it out to 100% and
  schedule the flag's removal.
- **ITERATE** — directional or mixed result; name the next hypothesis.
- **STOP** — no effect at the planned sample size, or a guardrail breached; revert to
  control and remove the flag.
- **NOT ASSESSED** — the result cannot be trusted or read: SRM failure, the planned sample
  size or duration not reached, exposure or metric events broken, data unavailable, or a
  campaign run without a holdout. Name the reason.

A guardrail breach outranks a primary-metric win: breached ⇒ STOP or ITERATE, never SHIP.

Write the readout with the verdict line directly under the H1:

```markdown
# Growth Readout: [experiment name]

> **Verdict**: [SHIP | ITERATE | STOP | NOT ASSESSED]

## Result
## SRM Check
## Primary Metric
## Guardrails
## Segments
## Decision
[the decision rule applied, the rollout or revert steps, the flag cleanup story]
```

Ask "May I write this to `production/growth/<experiment-slug>/readout.md`?" and write it on
approval; then ask "May I write this to `production/growth/<experiment-slug>/brief.md`?" to
set `> **Status**: Concluded`. Tracking-plan rows for events the experiment retired move to
`Deprecated` after "May I write this to `design/product/tracking-plan.md`?".

## Error Recovery Protocol

**First, verify the artifact.** If the return contract named a path, check the
path exists before treating the phase as done — **a named artifact that is not
on disk is a failed phase, however fluent the response reads.** An agent can
burn a full phase and return a plausible preamble having written nothing, which
is neither BLOCKED nor an error nor "cannot complete", so the trigger below
never fires. Resume it naming the unmet contract; the context is
usually still there.

If any spawned agent returns BLOCKED, errors, or cannot complete: **surface it
immediately, don't proceed past a dependency it blocks, and always produce a
partial report.** Full procedure: `.claude/docs/error-recovery-protocol.md`.

Common blockers:
- No metric baseline and no way to measure one → run the instrumentation first; plan the
  experiment after a baseline week
- Eligible traffic too small to reach the MDE within the longest duration the decision rule
  allows → raise the MDE, widen the segment, or run a qualitative test (`/usability-report`)
  instead
- An overlapping experiment on the same surface and segment → sequence them or split
  allocation; never let two experiments claim the same users silently
- A Consent & Channel item neither confirmed nor accepted → the brief stays `Draft`

If a BLOCKED state is unresolvable, end with Verdict: **BLOCKED** instead of COMPLETE.

## File Write Protocol

This skill compiles and writes the brief, the readout and the tracking-plan updates itself,
each after asking "May I write this to `<path>`?". `design/product/tracking-plan.md` is under
`design/`, which the bounded exception never covers. Agents return their sections inline and
write no files in this pipeline; variant code is written later by `/dev-story` under its own
protocol.

## Output

A summary covering: hypothesis and kind, segment and sizing, primary metric and guardrails,
variants, Consent & Channel result per region, variant stories and their routes, rollout
steps and the readout date — or, in `readout` mode, the readout verdict and the decision.

Verdict: **COMPLETE** — brief written (planning run) or readout written (`readout` run),
whatever the readout's own verdict.
Verdict: **NOT ASSESSED** — a required input or check could not be had: a `readout` run with
no brief (`NOT ASSESSED — no brief at production/growth/<experiment-slug>/brief.md`), a
region's `.claude/docs/compliance/<region>.md` absent and the gap not explicitly accepted (the
brief stays Draft), or the regions stayed unset because the question went unanswered; name
each.
Verdict: **BLOCKED** — a phase could not complete; the partial brief lists what is missing.

Precedence: BLOCKED > NOT ASSESSED > COMPLETE.

Close with `AskUserQuestion`:
- Prompt: "[experiment-slug]: [COMPLETE / BLOCKED / NOT ASSESSED]. What next?"
- Options (those that apply):
  - `/quick-spec <variant> — start the first variant story (Recommended after a planning run)`
  - `/create-stories <epic-slug> — create the variant stories from the quick specs`
  - `/sprint-plan — schedule the variant stories`
  - `/team-content <area> — when a lifecycle campaign needs a full content pass`
  - `/retrospective release <version> — after a SHIP rolls out`
  - `Stop here`

## Collaborative Protocol

**Applies in `collaborative` mode.** For `guided` and `autonomous` modes, see
`.claude/docs/automation-modes.md`; the always-ask categories prompt in every mode.

- **Question → Options → Decision → Draft → Approval** at every phase transition.
- **The decision rule is written before launch** and is the only rule the readout applies.
- **Consent before copy** — no promotional message, template or campaign is approved
  before its Consent & Channel items are confirmed or accepted.
- **Humans change production** — flag creation, allocation and rollout are run by the user.
- **Aggregates by default** — no user-level export without an explicit, logged approval.
