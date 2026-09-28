---
name: qa-plan
description: "QA plan per sprint or feature using the `templates/test-plan.md` headings."
argument-hint: "[sprint | feature: <feature-slug> | story: <path>]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, Bash(bash "*/.claude/skills/qa-plan/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow,qa.level,feature_overrides,accessibility`

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

# QA Plan

This skill generates a structured QA plan for a sprint, feature, or individual
story. It reads all in-scope story files and the PRDs they reference, classifies
each story by test type, and produces a plan that tells engineers exactly what
to automate, what to verify manually, what the smoke test scope is, which
non-functional checks apply, and when to bring in usability or beta participants.

Run this before a sprint begins so the team knows upfront what testing work
is required. A test plan written after implementation is a retrospective, not a
plan.

**Output:** `production/qa/qa-plan-<sprint-slug>-YYYY-MM-DD.md` — `<sprint-slug>` is the sprint id
`sprint-NN`, the sprint file's name without `.md` (`production/sprints/sprint-03.md` →
`production/qa/qa-plan-sprint-03-2026-10-05.md`; `/sprint-plan` finds the plan by that number), or
for `feature:` / `story:` scope the feature slug or story slug.

**Structure:** the plan is built from `.claude/docs/templates/test-plan.md` — the single source of the
plan's headings. Never reproduce an inline skeleton here: `/smoke-check` reads the plan's
`## Smoke Test Scope` and `/create-stories` reads `## Automated Tests Required`, so the headings must be
the template's, byte for byte.

---

**Workflow tier**: resolve per the PRD's feature as each is read (per
`.claude/docs/workflow-modes.md`): the `feature_overrides` entry for that PRD stem
(`workflow_overrides.feature_overrides.<prd-stem>`) if the resolved block lists one, else the project
`workflow` value. It sets how many PRD sections the test plan is mined from — see Phase 2.

**`qa.level`**: at `minimal`, produce only a minimal smoke-and-manual plan — no automated tests are
required, so `## Automated Tests Required` keeps its heading and says so, and the test-file and
evidence rows of the Definition of Done are dropped; at `standard`, a full plan per story type; at
`full`, also add per-feature coverage targets (every acceptance criterion and every PRD edge case mapped
to a named test or manual check). Two floors survive every `qa.level`: the smoke check and the
migration dry-run log. Distinct axis from `workflow` (which sets how many PRD sections are mined).

**`testing.strict`**: this skill does not resolve it. The plan states the default gate level per type
(`.claude/docs/coding-standards.md`) and names the five override keys — `testing.strict.logic`,
`testing.strict.integration`, `testing.strict.ui`, `testing.strict.e2e`, `testing.strict.config`;
`/story-done` and `/smoke-check` apply the resolved values.

## Phase 1: Parse Scope

**Argument:** `$ARGUMENTS` (blank = ask user via AskUserQuestion)

Determine scope from the argument:

- **`sprint`** — read the most recent file in `production/sprints/`, extract
  every story file path referenced. If `production/sprint-status.yaml` exists,
  use it as the primary story list and fall back to the sprint plan for story
  metadata.
- **`feature: <feature-slug>`** — glob `production/epics/*/story-*.md` and keep
  the stories whose `**PRD**:` line names `design/prd/<feature-slug>.md`, or whose
  file path or title contains the slug. Also check the `EPIC.md` of each epic
  directory those stories live in.
- **`story: <path>`** — validate that the path exists and load that single file.
- **No argument** — use `AskUserQuestion`:
  - "What is the scope for this QA plan?"
  - Options: "Current sprint", "Specific feature (enter feature slug)",
    "Specific story (enter path)", "Full epic"

After resolving scope, report: "Building QA plan for [N] stories in [scope]."

If a story file path is referenced but the file does not exist, note it as
MISSING and continue with the remaining stories. Do not fail the entire plan
for one missing file.

> **If the resolved scope contains ZERO stories, stop — do not build a plan.**
> Report `NOT ASSESSED — no stories in scope`, naming which scope was searched
> and which path was empty, and route:
> - no file in `production/sprints/` → "No sprint plan found. Run `/sprint-plan new`."
> - a sprint plan exists but references no stories → "Sprint plan `[path]` lists no
>   stories. Run `/create-stories [epic-slug]`."
> - `feature:`/`story:` scope matched nothing → name the glob that came back empty.
>
> **The N=0 guard is mandatory.** Without it an empty scope reports "Building QA
> plan for 0 stories" and continues into Phase 4, producing a plan document with
> empty tables — and **a QA plan for zero stories looks exactly like a completed
> QA plan.** This skill gates the hand-off to manual QA, so a false-clean here
> sends a build to QA on the strength of a plan that tested nothing.
>
> Note the shape, because this skill already had the harder half of the rule.
> Phase 2 states **"Never treat an absent section as an absent story"** — the
> sophisticated inner case, correctly handled. The outer boundary, no stories at
> all, had nothing. The same shape appears in `/story-readiness`, where `NOT ASSESSED`
> existed for per-story failures and the empty scope could not reach it.
>
> The rule at the top of this block still stands: one missing file among several
> is MISSING-and-continue. This is the different case where there is no *several*.

---

## Phase 2: Load Inputs

Establish the denominator first — glob the in-scope story files and count **N** —
then collect the fields below with **targeted section greps, not a full read of
each story**. A QA plan needs each story's type, surface, contract fields and
acceptance criteria; it does not need its implementation notes, out-of-scope
boundaries or ADR rationale, and reading N stories whole to reach a few fields is
where this phase's cost lives:

```
Grep pattern="^## Acceptance Criteria" glob="production/epics/*/story-*.md" output_mode="content" -A 15
Grep pattern="^> \*\*(Type|Status|Surface|Estimate)\*\*" glob="production/epics/*/story-*.md" output_mode="content"
Grep pattern="^\*\*(PRD|Requirement|API Contract|Migration|Feature Flag|Analytics Events)\*\*" glob="production/epics/*/story-*.md" output_mode="content"
Grep pattern="^## Dependencies" glob="production/epics/*/story-*.md" output_mode="content" -A 8
```

(Scope the globs to the sprint plan's story paths in `sprint` mode.) From those:

- **Story title** and story ID — from the file name and path; no read at all
- **Story Type** field — from the header grep (`> **Type**: Logic`)
- **Surface** — from the header grep (`web`, `ios`, `android`, `mobile`, `api`,
  `admin`, `infra`, `analytics`; first = primary)
- **Acceptance criteria** — the complete numbered/bulleted list, from the first grep
- **PRD / TR-ID reference** — from the `**PRD**:` and `**Requirement**:` lines
- **API Contract, Migration, Feature Flag, Analytics Events** — from the contract
  grep; they decide contract tests, the migration floor, flag-on/flag-off cases and
  event verification
- **Dependencies** — from the `## Dependencies` grep
- **Estimate** — from the header grep if present
- **Implementation files** and **Stack Notes** — only needed for stories whose
  test plan actually turns on them; full-read those individual stories

**Never treat an absent section as an absent story.** If a story matched no
`## Acceptance Criteria`, full-read that one and say so — a story with no
testable criteria is a QA finding in its own right, not a story to skip.

After reading stories, load supporting context once (not per story):

- `design/product/feature-map.md` — to understand feature tiers (MVP / Beta / GA /
  Later) and which PRDs are `Approved`
- For each unique PRD referenced across all stories: mine test material per that
  feature's workflow tier (resolved above), with a section grep — do not load the
  full PRD text:
  - at `full`: `## Acceptance Criteria`, `## Edge Cases`,
    `## Business Rules & Calculations`, `## Functional Requirements`
    (`### User Flows & States`), `## Non-Functional Requirements`,
    `## Configuration & Flags` and `## Success Metrics & Instrumentation`;
  - at `standard`: `## Acceptance Criteria`, `## Edge Cases` and
    `## Non-Functional Requirements` always, plus `## Business Rules & Calculations`
    for any feature that defines numeric or policy rules (prices, fees, limits,
    quotas, eligibility thresholds, time windows, rounding);
  - at `minimal`: there are normally no PRDs — the stories' acceptance criteria are
    the source, and `design/product/one-pager.md` `## Core User Journey` feeds the
    smoke scope; a PRD written voluntarily is mined for `## Acceptance Criteria` only.

  These sections contain the testable requirements, the rules to verify, and the
  boundary conditions tests must cover. If an Edge Cases section is absent (or not
  expected at minimal), note per PRD: "No Edge Cases section found — edge case
  coverage will be inferred from acceptance criteria only."
- `docs/ops/slo.md` `## Critical User Journeys` (fallback
  `design/product/user-journey.md`) — the journeys E2E stories close and the smoke
  scope protects (if the file exists)
- `docs/architecture/control-manifest.md` — scan for forbidden patterns that
  automated tests should guard against (if the file exists)
- `project.yaml` with Read, for the `performance.*` budgets and `testing.patterns`
  (they have no `resolve_config` label). Unset `testing.patterns` ⇒ plan test paths
  under the `tests/**` convention and say so in the plan; unset budgets ⇒ the
  Non-Functional Checks target cell reads "budget unset — set `performance.*`",
  never an invented number.
- `design/accessibility-requirements.md` — the requirements behind the
  accessibility row of the Non-Functional Checks, whose target is the resolved
  `accessibility.target` (bootstrap block above). Absent file ⇒ note "no
  accessibility requirements doc — run `/ux-design accessibility`"; a
  `> **Target**:` line that differs from the resolved value is flagged in the row,
  never silently preferred

If no PRD is referenced in a story, note it as a gap but do not block the plan.
The story will be classified using acceptance criteria alone.

---

## Phase 3: Classify Each Story

For each story, assign a Story Type:

- **If the story already has a `> **Type**:` field in its header**: accept it as-is. Do NOT re-classify or validate against the criteria below — the Type was set at story creation (`/create-stories`, reviewed by qa-lead) and is authoritative. Record it as-is.
- **If the `> **Type**:` field is missing**: infer the type from the acceptance criteria using the table below, and note in the report that the type was inferred (not declared). Flag this as a gap — the story should have its Type declared explicitly before implementation begins.

| Story Type | Classification Indicators |
|---|---|
| **Logic** | Acceptance criteria reference calculations or business rules (fees, KRW rounding, limits, eligibility thresholds), validators, state transitions (a goal moving `active → paused → completed`), permission rules evaluated in code, or any testable computation with no I/O |
| **Integration** | Criteria involve an API handler with the database, queue consumers, webhooks (e.g., Toss Payments deposit webhook), third-party adapters (Kakao / Naver / Apple login), persistence round-trips, idempotency and retries, cache invalidation, or conformance to the contract in `docs/api/` |
| **UI** | Criteria reference screens, components, forms and validation messages, navigation, visual states (loading, empty, error, offline, success), responsive breakpoints, or any user-facing interface element |
| **E2E** | The journey-closing story of an epic: its criteria are a full critical user journey across UI → API → database named in `docs/ops/slo.md` `## Critical User Journeys` (or `design/product/user-journey.md`) |
| **Config** | Changes are limited to feature flags, environment config, or pricing / limit tables — no new code logic is involved |

**Mixed stories** (e.g., a story that adds both a business rule and the screen that
shows it): assign the primary type based on which acceptance criteria carry the
highest implementation risk, and note the secondary type. Mixed Logic+Integration
or UI+E2E combinations are the most common.

**Any type with a migration**: a story whose `**Migration**` is not `None` also
carries the migration floor — `production/qa/evidence/<story-slug>/migration-dry-run.log`
(Expand applied and rolled back on a disposable database) at every `qa.level`. List
these stories under the template's **Migration stories** line.

After classifying all stories, produce a classification summary table in
conversation before proceeding to Phase 4. This gives the user visibility into
how tests will be allocated.

---

## Phase 4: Generate Test Plan

Read `.claude/docs/templates/test-plan.md` and fill every section of it for the
stories in scope. Keep every heading exactly as the template spells it; write the
body in the user's conversation language.

**Header block** — fill `> **Generated by**:` with `/qa-plan`; derive
`> **Surfaces in scope**:` from the stories' `**Surface**` fields; ask for the test
environment only if the sprint plan and smoke reports do not name it (leave
"[to confirm]" rather than guess a URL).

**`## Story Coverage Summary`** — one row per story, with Type (Logic / Integration
/ UI / E2E / Config), Surface, the automated test required and the manual
verification required; the totals line; the **Migration stories** line; and the
gate-level paragraph as the template words it.

**`## Automated Tests Required`** — one `###` block per Logic, Integration and E2E
story:
- **Test file path** — where `testing.patterns` says tests live (co-located, e.g.
  `apps/api/src/goals/goal-plan.test.ts`), else `tests/unit/<feature>/`,
  `tests/integration/<feature>/`, `tests/contract/<feature>/` or
  `tests/e2e/<journey>/`.
- **What to test** — the specific rule from the PRD's
  `## Business Rules & Calculations`; each named state transition or decision
  branch; each side effect that should or should not occur; for Integration
  stories the `**API Contract**` operation against `docs/api/`, the authorization
  negative case (another user's resource is refused) and idempotency where a
  webhook or retry is involved; for E2E stories the journey steps and the
  environment they run against.
- **Edge cases to cover** — zero/minimum inputs, maximum/boundary inputs, invalid
  or missing input, and every edge case the PRD's `## Edge Cases` names (duplicate
  webhook, network loss mid-request, expired token, month-end dates, KST/UTC day
  boundary).
- **Estimated test count**.
- If no business rule was found in the referenced PRD for a Logic story, write:
  *No business rule found in the referenced PRD — test cases must be derived from
  acceptance criteria directly. Review the PRD's Business Rules & Calculations
  section before writing tests.*

*(At `qa.level: minimal`, keep the heading and write under it only: "Not required
at `qa.level: minimal` — manual and smoke verification only." Blank the Story
Coverage Summary's "Automated Test Required" cells the same way.)*

**`## Manual QA Checklist`** — one `###` block per UI story, and per E2E story for
the surfaces the automated run does not cover:
- **Verification method** — manual step-through per surface, screenshot review, or
  an exploratory session with a charter.
- **Evidence location** — `production/qa/evidence/<story-slug>/`.
- **Who must sign off** — product-designer, qa-lead or tech-lead, as the story needs.
- **States to capture** — loading, empty, error, offline, success; desktop
  (1280×800) and mobile (390×844) viewport, or device screenshots.
- Checklist items: every acceptance criterion translated into a concrete,
  falsifiable manual check.

*If any criterion uses subjective language ("feels fast", "looks clean", "intuitive"),
it must be supplemented with a specific benchmark (a p95 target, a named state,
task success in a usability session) or a usability protocol note.*

**`## Smoke Test Scope`** — keep the template's build-and-boot, sign-in,
integrations, migrations and non-functional items, and replace the bracketed items
with the core journey this sprint introduces or changes and the features with
regression risk from this sprint's changes. Smoke tests are run via `/smoke-check`;
it reads this list.

**`## Usability / Beta Requirements`** — one row per story whose acceptance
criteria need user evidence (a new onboarding step, a payment sheet, a changed core
journey): the research question, method, minimum participants and target segment.
Results go through `/usability-report` into `production/qa/usability/` — never
`production/session-logs/`, which is gitignored and so never evidence. If none:
*No usability or beta sessions required for this sprint.*

**`## Non-Functional Checks`** — fill each row from the PRDs'
`## Non-Functional Requirements`, the `performance.*` budgets read in Phase 2 and
the resolved `accessibility.target` (unset ⇒ the accessibility row reads
`NOT DETERMINED — accessibility.target unset`); a row that does not apply stays,
marked *N/A — [reason]*.

**`## Definition of Done — This Sprint`** — keep the template's rows. At
`qa.level: minimal` drop the test-file and retained-evidence rows (only
acceptance-criteria verification, the migration floor and the smoke check remain).
List the stories requiring usability or beta sign-off before close.

When generating content, use the actual story titles, PRD business-rule text, and
acceptance criteria extracted in Phase 2. Do not use placeholder text — every
test entry should reflect the real requirements of these specific stories.

---

## Phase 5: Write Output

Show the complete plan in conversation (or a summary if the plan is very long),
then ask two questions together using `AskUserQuestion`:

```
question: "May I write this to production/qa/qa-plan-<sprint-slug>-YYYY-MM-DD.md? Choose output options:"
multiSelect: true
options:
  - "Write QA plan to production/qa/qa-plan-<sprint-slug>-YYYY-MM-DD.md"
  - "Also back-fill test case specs into each story file's ## QA Test Cases section (Recommended — enables /dev-story and /code-review traceability)"
```

If "Write QA plan" is selected: write the plan file exactly as generated — do not truncate.

If "Also back-fill story files" is selected: for each Logic, Integration and E2E story in scope, edit the story file at its path. Find the `## QA Test Cases` section and replace its content with the test case specs generated in Phase 4 for that story. If a story has no `## QA Test Cases` section, append it before `## Test Evidence`. For UI stories, write the manual verification steps instead of test specs. Selecting this option is the approval — "May I write this to `<story path>`?" — for exactly the in-scope story files listed in the plan; any other file needs its own ask.

After writing:

"QA plan written to `production/qa/qa-plan-<sprint-slug>-YYYY-MM-DD.md`.

Next steps:
- Share this plan with the team before sprint implementation begins
- Once all sprint stories are implemented, run `/smoke-check sprint` to gate QA hand-off — not yet, only after implementation is complete
- For Logic, Integration and E2E stories, create the test files at the listed paths
  before marking stories done — `/story-done` checks for them
- For the full QA cycle (cases, execution, bugs, sign-off), run `/team-qa sprint`"

Silently append to `production/session-state/active.md` (create the file if it does not exist):

```
<!-- QA-PLAN: [date] | Scope: [sprint/feature/story identifier] | Plan written: production/qa/qa-plan-[identifier]-[date].md -->
```

---

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and
`autonomous` modes, see `.claude/docs/automation-modes.md` — the rules below
describe what collaborative mode requires, not universal behavior.

- **Never write the plan without asking** — Phase 5 requires explicit approval.
- **Classify conservatively**: when a story is ambiguous between Logic and
  Integration, classify it as Integration — it requires both unit and
  integration tests.
- **Do not invent test cases** beyond what acceptance criteria and PRD business
  rules support. If a rule is absent from the PRD, flag it rather than guessing.
- **Do not invent numbers**: budgets come from `performance.*`, the accessibility
  target from the resolved `accessibility.target`; unset stays visibly unset.
- **Usability requirements are advisory**: the user decides whether a usability
  or beta session is warranted for borderline UI stories. Flag the case; do not mandate.
- Use `AskUserQuestion` for scope selection when no argument is provided.
  Keep all other phases non-interactive — present findings, then ask once to
  approve the write.
