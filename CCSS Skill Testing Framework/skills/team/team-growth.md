# Skill Spec: /team-growth

> **Category**: team
> **Priority**: medium
> **Spec written**: 2026-09-28

## Skill Summary

Orchestrates the growth team through a growth experiment or a lifecycle campaign in two
separate invocations. The planning run (Phases 1–6) frames the hypothesis, segment,
primary metric, guardrails, variants and decision rule (`growth-manager`); sizes the
test and defines instrumentation (`analytics-engineer` — baseline, MDE, sample size,
duration, SRM check, exposure event), updating `design/product/tracking-plan.md`; runs
the Consent & Channel Check against `.claude/docs/compliance/<region>.md`; designs the
variants (`product-designer` ∥ `ux-writer`); writes the brief
`production/growth/<experiment-slug>/brief.md` with exact headings and routes each
variant to stories; and lists the rollout steps for a human. The readout run
(`readout <experiment-slug>`, Phase 7) writes
`production/growth/<experiment-slug>/readout.md` with the verdict
`SHIP | ITERATE | STOP | NOT ASSESSED`. The run itself ends COMPLETE (brief or readout
written), NOT ASSESSED (a readout with no brief, an unaccepted missing compliance reference,
or regions left unset) or BLOCKED, with the precedence BLOCKED > NOT ASSESSED > COMPLETE.
Pricing variants are `billing_changes` and flag changes are `production_deploys` — both
always prompt. The skill writes no code and spawns no director gate.

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`); `name` is `team-growth`, equal to the directory `.claude/skills/team-growth/` and the catalog `name`
- [ ] Bootstrap: the first body line is `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,automation_always_ask,team.size,compliance,surfaces` `` and `allowed-tools` grants `Bash(bash "*/.claude/skills/team-growth/../../hooks/yaml-helper.sh" resolve_config *)`
- [ ] `--keys` is exactly `review_mode,automation,automation_always_ask,team.size,compliance,surfaces`
- [ ] The line after the bootstrap block is exactly: ``Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] Automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") present verbatim right after that line
- [ ] `allowed-tools` is exactly: `Read, Glob, Grep, Write, Edit, Bash, Agent, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskUpdate` plus the bootstrap grant
- [ ] 2+ phase headings found (`## Phase 0: Resolve Config`, `### Phase 1: Frame the experiment` … `### Phase 7: Readout` for the `readout <experiment-slug>` run, including `### Phase 3: Consent & Channel Check`)
- [ ] Verdict keywords present, exactly: readout `SHIP`, `ITERATE`, `STOP`, `NOT ASSESSED`; orchestrator `COMPLETE`, `NOT ASSESSED`, `BLOCKED`, with the line `Precedence: BLOCKED > NOT ASSESSED > COMPLETE.` and the closing prompt "[experiment-slug]: [COMPLETE / BLOCKED / NOT ASSESSED]. What next?"
- [ ] "May I write this to `design/product/tracking-plan.md`?", "May I write this to `production/growth/<experiment-slug>/brief.md`?" and "May I write this to `production/growth/<experiment-slug>/readout.md`?" appear before the corresponding writes
- [ ] Outputs at the exact paths: `production/growth/<experiment-slug>/brief.md`, `production/growth/<experiment-slug>/readout.md`, `design/product/tracking-plan.md` (updates)
- [ ] The brief uses exactly these headings, in order: `## Hypothesis`, `## Target Segment & Sizing`, `## Primary Metric & Guardrails`, `## Variants`, `## Instrumentation`, `## Flag & Rollout`, `## Consent & Channel Check`, `## Stories`, `## Decision Rule`
- [ ] The readout has `> **Verdict**: [SHIP | ITERATE | STOP | NOT ASSESSED]` directly under its H1 `# Growth Readout: [experiment name]`, then exactly `## Result`, `## SRM Check`, `## Primary Metric`, `## Guardrails`, `## Segments`, `## Decision`
- [ ] Contains verbatim: "Team skills spawn only the gates `.claude/docs/director-gates.md` § Gate Index lists this skill under (Spawned by column), after the review-mode check (lean suffix rule); team-size scoping never removes a director gate."
- [ ] Phase 0 contains the lean sentence verbatim, the default statement verbatim ("Unset on an unconfigured project: `modes.rigor` defaults to `minimal`, which resolves `review_mode` to `solo`.") and states that the skill spawns no gate itself
- [ ] Active set per `team.size` is listed (`individual`: `growth-manager`; `small`: `growth-manager` → `analytics-engineer` → `product-designer` ∥ `ux-writer` → hand-off of variants as stories; `studio`: + `monetization-strategist`, `customer-success-manager`, `data-engineer`) and announced before Phase 1
- [ ] States that pricing experiments are `billing_changes` and that turning the flag on and every allocation change are `production_deploys` — both prompt in every mode, including `autonomous`; also names `pii_data_access` and `scope_changes`
- [ ] Without an argument, prints "Usage: `/team-growth [experiment or campaign description]` — …" and stops without spawning subagents or reading files
- [ ] Has an Error Recovery Protocol section and a File Write Protocol section (the skill writes the brief, readout and tracking-plan updates itself; agents write no files)
- [ ] No `!` injection other than the bootstrap line; no `file:line` citations of other files
- [ ] The closing `AskUserQuestion` names current skills (`/quick-spec <variant>`, `/create-stories <epic-slug>`, `/sprint-plan`, `/team-content <area>`, `/retrospective release <version>`)

---

## Director Gate Checks

- **Full mode**: no gate spawns — the skill's gate list is empty; any gate-using skill it hands variant work to receives `--review full`
- **Lean mode**: no gate spawns; the lean sentence has nothing to skip here
- **Solo mode**: no gate spawns
- **Review-mode exempt**: not applicable
- **N/A**: experiment decisions are governed by the pre-registered decision rule and the user, not by a director gate

---

## Test Cases

Quoted prompts, option labels and verdict tokens below are the canonical English text
of `SKILL.md`; at run time the model renders them in the user's conversation language.
Numbers in the fixtures are illustrative.

### Case 1: Happy Path — Planning the first-goal-suggestion experiment

**Fixture** (assumed project state):
- `design/product/product-brief.md` (with `## Success Metrics`) and `design/product/user-journey.md` exist
- `design/product/tracking-plan.md` lists `goal_created` and `onboarding_completed`
- No other `production/growth/*/brief.md` targets the empty goals screen
- Resolved block: `team.size: small`, `automation: collaborative`, `compliance: regions=kr handles_pii=true (project.yaml)`, `platform.surfaces: web, ios, android, api (project.yaml)`
- `project.yaml`: `localization.locales: [ko-KR]`

**Input:** `/team-growth suggest a pre-filled first goal on the empty goals screen`

**Expected behavior:**
1. Phase 0 announces the `small` active set and names the `studio` additions as not spawned
2. Phase 1: `growth-manager` frames an A/B experiment — hypothesis with evidence, eligible segment and exclusions (no marketing consent for promotional channels, open payment disputes, internal and test accounts), randomization by user, primary metric (share creating a goal within 24 h of sign-up), guardrails (onboarding abandonment, support contacts per 1,000 users), decision rule written before launch; `AskUserQuestion` → `[A] Proceed`
3. Phase 2: `analytics-engineer` states baseline and MDE, sample size per variant at two-sided α = 0.05 and power 0.8, converted to whole weeks; the arithmetic is cross-checked with a short `python3` calculation shown to the user; the exposure event `experiment_exposed` (with `experiment_key` and `variant`) and its rows are added to the tracking plan with `Status: Planned` after "May I write this to `design/product/tracking-plan.md`?"
4. Phase 3 lists the `kr` items of `## Marketing Messages & Consent`; the user confirms each
5. Phase 4: `product-designer` and `ux-writer` are spawned in one message; `AskUserQuestion` → `[A] Approve`
6. Phase 5 compiles the brief with the nine headings; `## Stories` lists `pending: /quick-spec first-goal-suggestion-web` and the routes by Surface; written after "May I write this to `production/growth/first-goal-suggestion/brief.md`?"
7. Phase 6 lists the rollout steps for a human and states the readout date and `/team-growth readout first-goal-suggestion`
8. Verdict COMPLETE

**Assertions:**
- [ ] The decision rule is recorded before launch, including the guardrail breach that overrides a primary-metric win
- [ ] The sample-size arithmetic is cross-checked with Bash, not asserted from memory
- [ ] Tracking-plan rows are written only after "May I write", with the owning PRD
- [ ] The Consent & Channel Check runs before variant approval
- [ ] The brief uses the nine headings exactly, in order
- [ ] Variants become routed stories; the skill writes no code
- [ ] The experiment slug is reused in the flag key

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — Consent item unconfirmed; promotional 알림톡

**Fixture:**
- A D7 re-engagement campaign (`d7-push-no-deposit`) with a holdout group; one variant is a 알림톡 message offering a first-month discount; `compliance: regions=kr …`
- The user neither confirms nor accepts the separate night-time consent item for pushes sent after 21:00 KST

**Input:** `/team-growth D7 re-engagement push for users with no deposit`

**Expected behavior:**
1. Phase 3 reclassifies the discount message: 알림톡 carries informational messages only, so the promotion moves to a channel with advertising consent
2. The unconfirmed night-time item blocks approval of the brief; the brief stays `> **Status**: Draft`
3. If the block cannot be resolved, the run ends with Verdict: **BLOCKED** and a partial brief listing what is missing

**Assertions:**
- [ ] An item neither confirmed nor accepted blocks the brief's approval
- [ ] Promotional content is never sent as 알림톡
- [ ] The brief stays Draft; the verdict is BLOCKED, not COMPLETE
- [ ] The check is presented as a checklist against the reference, not legal advice, and invents no deadlines or thresholds

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: NOT ASSESSED — Readout with an SRM failure, or without a brief

**Fixture (variant A):** `production/growth/first-goal-suggestion/brief.md` exists (planned 50/50); the user reports 51,200 users in control and 48,300 in treatment; the primary metric shows +4.1 pp

**Fixture (variant B):** no `production/growth/onboarding-checklist/brief.md`

**Input:** `/team-growth readout first-goal-suggestion` (A) · `/team-growth readout onboarding-checklist` (B)

**Expected behavior (variant A):**
1. `analytics-engineer` runs the chi-square SRM check on assignment counts; it fails
2. The result is invalid: the verdict is **NOT ASSESSED**, whatever the metric shows, with the reason named
3. The readout is written after "May I write this to `production/growth/first-goal-suggestion/readout.md`?" with `> **Verdict**: NOT ASSESSED` under its H1; the run verdict is COMPLETE (the readout was written)

**Expected behavior (variant B):**
1. The skill stops: `NOT ASSESSED — no brief at production/growth/onboarding-checklist/brief.md`; the run verdict is NOT ASSESSED and no readout is written

**Assertions:**
- [ ] An SRM failure forces NOT ASSESSED — the metric win is not reported as SHIP
- [ ] A missing brief stops the readout with the exact NOT ASSESSED line, and the run verdict is NOT ASSESSED, never COMPLETE
- [ ] The readout verdict line sits directly under the H1

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Mode Variant — Readout decisions and the guardrail override

**Fixture:**
- `production/growth/first-goal-suggestion/brief.md` with a decision rule: SHIP when the primary metric improves by ≥ 3 pp and no guardrail breaches
- Variant A: +3.4 pp, guardrails flat, planned sample reached, SRM passes
- Variant B: +3.8 pp, but support contacts per 1,000 users breach their threshold

**Input:** `/team-growth readout first-goal-suggestion`

**Expected behavior:**
1. Variant A: verdict **SHIP**; `## Decision` gives the rollout to 100% and the flag-removal story
2. Variant B: verdict **STOP** or **ITERATE** — never SHIP — because a guardrail breach outranks a primary-metric win
3. Segments are pre-declared only; anything else is labelled exploratory and does not drive the decision
4. After the readout, "May I write this to `production/growth/first-goal-suggestion/brief.md`?" sets `> **Status**: Concluded`

**Assertions:**
- [ ] The decision applies the brief's rule, never a rule invented after seeing the data
- [ ] A guardrail breach never yields SHIP
- [ ] The brief's status changes to Concluded only after asking

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Edge Case — Regions unset, no baseline, campaign without holdout

**Fixture:**
- The resolved `compliance` line prints the unset form for regions
- The tracking plan has no history for the primary metric
- The request is a lifecycle campaign with no holdout group

**Input:** `/team-growth weekly savings streak email`

**Expected behavior:**
1. The skill asks which regions the experiment's users are in before Phase 3 — unset is not "none"
2. Phase 2 records `NOT DETERMINED — baseline for <metric>`; the sample size is an estimate from a stated assumption, and the brief says which
3. Phase 1 says a campaign without a holdout cannot be read out: add one, or record that the readout will be NOT ASSESSED
4. With `regions=none` instead, Phase 3 records `Consent & Channel Check: no regions configured (compliance.regions: [])` and still confirms an opt-out and push quiet hours

**Assertions:**
- [ ] Unset regions lead to a question; left unanswered, the run verdict is NOT ASSESSED
- [ ] A missing baseline is written as NOT DETERMINED, never filled with a guess
- [ ] A campaign without a holdout is flagged before launch
- [ ] `regions=none` is recorded, and the in-product basics are still confirmed

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Usage — No argument

**Fixture:**
- Any project state

**Input:** `/team-growth` (no argument)

**Expected behavior:**
1. Outputs the usage line with examples (`goal-suggestion copy on the empty goals screen`, `D7 re-engagement push for users with no deposit`) and the `readout <experiment-slug>` form
2. Stops without spawning subagents or reading files

**Assertions:**
- [ ] No agent is spawned and no file is read
- [ ] Both invocation forms are shown
- [ ] No verdict is emitted

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: Pricing variant under autonomous automation at studio

**Fixture:**
- A trial-length experiment for the Plus plan (7-day vs 14-day free trial)
- Resolved block: `automation: autonomous`, `team.size: studio`, `review_mode: full`

**Input:** `/team-growth 14-day Plus trial versus 7-day`

**Expected behavior:**
1. Announcement adds `monetization-strategist`, `customer-success-manager` and `data-engineer`
2. `monetization-strategist` covers price display (tax-inclusive, currency), what existing subscribers see, refund and cancellation behaviour, iOS and Android store billing constraints, and abuse vectors (trial cycling)
3. The trial variant prompts as `billing_changes` even at `autonomous`
4. Phase 6: turning the flag on in production and each allocation change prompt as `production_deploys`; a human flips the flag
5. No director gate spawns at `full`

**Assertions:**
- [ ] Pricing, trial, promotion and entitlement variants prompt at every automation mode
- [ ] The skill never changes a production flag itself
- [ ] `studio` roles run in parallel with the Phase 4 design work
- [ ] No gate is spawned at any review mode

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses "May I write this to `<path>`?" before the brief, the readout, the brief's status changes and every tracking-plan edit
- [ ] Presents the framing, sizing, consent items and variants before requesting approval
- [ ] Ends with the closing `AskUserQuestion` of next steps
- [ ] Does not auto-create files without user approval; agents return their sections inline and write no files
- [ ] Uses aggregates by default; any user-level query or export is a `pii_data_access` decision
- [ ] Writes no evidence, reports or plans under `production/session-logs/` (gitignored)
- [ ] Never writes `modes.review_mode` or any other knob that `modes.rigor` fronts

---

## Coverage Notes

- Overlapping experiments on the same surface and segment (sequence or split allocation)
  are asserted by the skill text but not given a fixture.
- Retiring events at readout (tracking-plan rows moved to `Deprecated` after "May I write")
  is covered by the Phase 7 text; Case 4 exercises the status change of the brief only.
- Traffic too small to reach the MDE within the allowed duration (raise the MDE, widen the
  segment, or run `/usability-report` instead) is a documented blocker without a fixture.
