---
name: start
description: "First-time onboarding: where are you (A–D), then route to the right workflow."
argument-hint: "[no arguments]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, Bash(bash .claude/scripts/stage-estimate.sh*)
model: sonnet
---

# Guided Onboarding

This skill is the entry point for new users. It does not assume a product idea, a
stack preference or any experience with this framework: it asks where the user is
starting from, sets the three settings that shape everything after it, and routes
to the right next skill.

### What it writes — and only this

| Path | Keys | Why here |
|------|------|----------|
| `project.yaml` | `project.stage` | Anchors the status line, `/help` and `/gate-check` with no argument |
| `project.yaml` | `modes.rigor` | One question that sets how much process the project carries |
| `project.yaml` | `modes.automation` | How often every skill stops to confirm |

No other key and no other file. In particular:

> **`/start` never writes the six knobs `modes.rigor` fronts** — `modes.review_mode`,
> `modes.workflow`, `docs.density`, `qa.level`, `modes.story_granularity`, `team.size`.
> Writing one explicitly pins it and shadows the rigor expansion, so the Phase 5
> question would stop changing it — the same rule stated in the header comment of
> `project.yaml`. The stack (`stack.*`, surfaces, distribution, regions, locales) is
> written by `/setup-stack`; `project.name` and `project.category` by `/brainstorm`;
> everything else by `/settings`.

**Always collaborative.** `/start` runs before any configuration exists, so it
ignores `modes.automation` (it is listed among the exemptions in
`.claude/docs/automation-modes.md`): every question is asked and the write is shown
and approved, whatever mode a returning user has set. It resolves no settings
through `yaml-helper.sh`; it reads `project.yaml` directly.

---

## Phase 1: Detect Project State

Before asking anything, gather context silently. Do **not** show these results
unprompted — they tailor the recommendations and catch a mismatched self-assessment;
they are not the conversation opener.

1. **Config** — Read `project.yaml`. Note whether it exists, and the values (or
   absence) of `project.stage`, `modes.rigor`, `modes.automation`,
   `stack.pinned_on`, `project.name` and `project.category`. Also note whether any
   of the six fronted knobs is set explicitly — Phase 7 reports it.
2. **Product artifacts** — Glob `design/product/product-brief.md`,
   `design/product/one-pager.md`, `design/product/feature-map.md`,
   `design/prd/*.md`.
3. **Architecture artifacts** — Glob `docs/architecture/architecture.md`,
   `docs/architecture/adr-*.md`, and `docs/api/` contracts (`openapi*.yaml`,
   `openapi*.json`, `*.graphql`, `*.proto`, `asyncapi*.yaml`).
4. **Prototypes** — Glob `prototypes/*/`.
5. **Delivery artifacts** — Glob `production/epics/*/EPIC.md`,
   `production/sprints/sprint-*.md`, `production/releases/*/`.
6. **Source code** — Glob for package manifests at the repository root and one
   level under `apps/`, `services/` and `packages/`: `package.json`,
   `pyproject.toml`, `build.gradle`, `build.gradle.kts`, `pom.xml`, `go.mod`,
   `pubspec.yaml`, `Cargo.toml`, `Gemfile`, `composer.json`; plus `ios/`,
   `android/` and `*.xcodeproj`. **Absence of these patterns is not proof of no
   code** — if the repository clearly holds source files elsewhere, say what you
   found rather than calling it greenfield.

Store the findings for Phases 3–8.

**Returning user.** If `project.stage`, `modes.rigor` and `modes.automation` are all
set and a product brief or one-pager exists, skip onboarding — see Edge Cases.

---

## Phase 2: Ask Where the User Is

This is the first thing the user sees. Use `AskUserQuestion` with these options so
the user can click rather than type:

- **Prompt**: "Welcome to Claude Code Service Studios! Before I suggest anything, I'd
  like to understand where you're starting from. Where are you with your product
  right now?"
- **Options**:
  - `A) No product idea yet` — I want to explore problems worth solving and figure
    out what to build.
  - `B) A problem space` — I know the problem or the users I care about (e.g.
    "people who never manage to save", "small clinics drowning in phone bookings"),
    but not the product yet.
  - `C) A clear product concept` — I know who it's for, what it does and roughly how
    it works, but haven't written it down.
  - `D) An existing product or codebase` — There is already code, documents,
    prototypes or a live service, and I want to bring it into this workflow.

Wait for the selection. Do not proceed until the user responds.

---

## Phase 3: Route Based on Answer

Name the **immediate next step only** in this phase. The full path depends on the
rigor chosen in Phase 5, so say: "I'll lay out the full path once I know how much
process you want — two quick questions away."

#### A) No product idea yet

1. Say that starting from zero is completely normal — most products start as a
   problem someone kept noticing.
2. Explain what `/brainstorm` does, **tier-neutrally**: it turns "no idea yet" into a
   written bet the next steps can build from — the problem, who has it, what they
   use today, and what would make a new product worth switching to. `/brainstorm
   open` explores from scratch; `/brainstorm <a few words>` starts from any hint.
   Do not describe what document it produces: that depends on the rigor chosen in
   Phase 5 (a one-pager at `minimal`, a full product brief at `standard`/`full`), and
   two different accounts of the same skill in one `/start` run confuse the user.
3. Next step: `/brainstorm open`.

#### B) A problem space

1. Ask them to describe the problem space in a few words — plain text, not
   `AskUserQuestion` (it is an open answer).
2. Take it as a valid starting point. Do not judge or redirect it.
3. Next step: `/brainstorm <their words>`.

#### C) A clear product concept

1. Ask for one or two sentences — plain text: who it is for, what it does for them,
   and where it runs (web, iOS, Android, a public or partner API).
2. Play it back in one sentence to confirm you understood.
3. Next steps: `/brainstorm <their concept>` — its fast path turns a clear concept
   into the written record quickly, confirming rather than re-exploring what the
   user already knows — then `/setup-stack` to choose and pin the stack.

#### D) An existing product or codebase

1. Run `bash .claude/scripts/stage-estimate.sh`. It prints four lines — `STAGE:`,
   `SOURCE:` (`project.yaml` when a stage is already recorded, `estimated`
   otherwise), `ESTIMATE:` and `EVIDENCE:`. It observes the tree; it does not judge
   it. If it exits non-zero or prints no `STAGE:` line, say so with its error, write
   no `project.stage`, recommend `/project-stage-detect` once the cause is fixed, and
   end with `Verdict: **NOT ASSESSED** — the stage could not be estimated (<error>).`
2. Share what Phase 1 found and what the script estimated, briefly:
   - "I can see [N PRDs / an architecture doc and N ADRs / an API contract /
     source code under apps/ and services/ / N prototypes]…"
   - "The tree looks like the **[ESTIMATE]** stage ([EVIDENCE])."
   - "The stack is [pinned on YYYY-MM-DD / not set up yet]."
3. Explain why the next step is an audit: "Having files is not the same as the
   framework's skills being able to use them. PRDs may miss required sections, ADRs
   may lack the headings later gates read, and code may live in directories no
   configuration declares yet. `/adopt` checks exactly that and writes a numbered
   adoption plan."
4. Next step: `/adopt`. Mention the others as what the plan will likely include:
   `/setup-stack` (when the stack is not pinned), `/project-stage-detect` (a full gap
   inventory by area), and `/reverse-document` for missing PRDs, ADRs or a product
   brief.
5. If Phase 1 found nothing at all, see Edge Cases.

---

## Phase 4: Choose the Initial Stage

Decide the `project.stage` value now; Phase 7 writes it together with the other two
settings.

- **A, B or C**: `Discovery`.
- **D**: the value on the script's `STAGE:` line. When `SOURCE: project.yaml`, that
  stage is already recorded and nothing changes. When the script failed (Phase 3 D
  step 1), there is no value: Phase 7 writes no `project.stage`.
- **Already set** (any option): keep the recorded value and show it. `/start` never
  moves a recorded stage — only `/gate-check` advances it, on a PASS the user
  confirms. If the recorded stage contradicts the chosen option (option A on a
  project at `Build`), say so in one sentence and ask whether they meant D.

Tell the user what the value anchors: "`project.stage` drives the status line,
`/help` and `/gate-check` without an argument. `/gate-check` advances it when a phase
gate passes."

---

## Phase 5: Set Rigor

If `modes.rigor` is already set, show it — "Rigor is set to `[value]`." — and carry
it forward to Phase 8 without asking again.

Otherwise, pick a recommendation first, then ask.

**Seed the recommendation** from what the user described, using the archetype
presets and concept signals in `.claude/docs/settings-guidance.md` § 2–3:

- Payments, lending, insurance, health or medical data, B2B customers with SLAs,
  SOC 2 or ISMS-P, on-prem customers → `full`.
- Hackathon, weekend project, prototype, proof of concept, fake door, side project →
  `minimal`.
- Seed or Series A, paying customers, an app store launch, a small team with one
  clear core journey → `standard`.
- **A problem-space hint still counts as a description.** "Something for small
  clinics' insurance claims" trips the health and regulated signals even though the
  user picked B — seed from the signal, not from the option, and say why in the
  user's own words.
- Nothing to map (option A, or a hint with no signal) → `minimal`, and add: "You can
  raise this after `/brainstorm` once the product is clearer — `/settings` changes it
  anytime." Unset on an unconfigured project: `modes.rigor` defaults to `minimal`, which resolves `review_mode` to `solo`.

Then use `AskUserQuestion`. Put the **recommended** option first and append
` (Recommended)` to its label; the other two follow.

- **Prompt**: "What best describes what you're building? This sets how much process
  the project carries — you can change it anytime with `/settings`."
- **Options** (base labels):
  - `Hackathon / prototype / side project` — A one-page brief, a pinned stack, then
    code: **about four steps to running code.** The trade: there are no PRDs, so
    product and design problems surface in code rather than before it.
  - `Seed-stage product team` — A product brief, a feature map and a PRD per MVP
    feature; architecture with the critical ADRs; an API contract and data model when
    there is a backend; a walking skeleton deployed to staging through CI before the
    sprint loop; director reviews at phase gates only. **Expect a few days of product
    and technical design before the first story** — worth it when a wrong decision is
    expensive to unpick once it is in code.
  - `Regulated or enterprise (fintech, health, B2B with SLAs)` — Everything in the
    seed-stage path plus a cross-PRD review, a control manifest, load tests, every
    director gate, and fine-grained stories with evidence required everywhere. For
    products where a mistake means a regulator, a breach or an SLA credit.

Value mapping (ignore the ` (Recommended)` suffix): `Hackathon / prototype / side
project` → `minimal`, `Seed-stage product team` → `standard`, `Regulated or
enterprise (fintech, health, B2B with SLAs)` → `full`.

Then say: "`modes.rigor: [value]` drives six settings — `modes.workflow` (which
documents are required), `docs.density`, `qa.level`, `modes.story_granularity`,
`modes.review_mode` (how many director reviews run) and `team.size` (how many agents
join team skills). Lighter rigor means fewer documents, fewer reviews and fewer
tokens. `/settings` shows the value each one takes; set one explicitly only to
override just that one."

**Why this is asked here.** Those six knobs change what every skill produces. Asked
once at onboarding the answer is cheap; skipped, every project silently runs at
defaults nobody chose.

---

## Phase 6: Set Automation Mode

If `modes.automation` is already set, show it — "Automation is set to `[value]`." —
and continue without asking.

Otherwise use `AskUserQuestion`. Recommend by working style
(`.claude/docs/settings-guidance.md` § 1): `Collaborative` for anyone new to the
framework or working in a regulated codebase (put it first with ` (Recommended)`);
recommend `Guided` instead when the user has said they already know this workflow.

- **Prompt**: "Last one: how much should I confirm with you as we work?"
- **Options**:
  - `Collaborative` — I ask before each significant step and show every draft before
    writing it. Most control; best while you are learning the workflow.
  - `Guided` — I decide the small things and keep going, but stop for the big calls:
    product and scope decisions, stack and API choices, pricing, anything expensive
    to reverse. Far fewer interruptions without giving up the decisions that matter.
  - `Autonomous` — I proceed and log each decision instead of asking. Fastest, but I
    make every call myself and it costs more tokens; best for well-scoped runs you
    trust.

Value mapping: `Collaborative` → `collaborative`, `Guided` → `guided`,
`Autonomous` → `autonomous`.

Then say: "Set `modes.automation` to `[value]`. `.claude/docs/automation-modes.md`
lists exactly what each mode asks and what it decides alone. `guided` and
`autonomous` still stop for the always-ask categories — by default `scope_changes`,
`file_deletions`, `schema_changes`, `production_deploys`, `db_migrations`,
`infra_changes`, `secrets_access`, `pii_data_access` and `billing_changes`."

**Why this is asked here.** `modes.automation` controls how often every skill stops.
A team that wants to move fast should not discover the setting after fifty approval
prompts.

---

## Phase 7: Write `project.yaml`

1. **Collect the changes** — only the keys that were unset: `project.stage` (Phase
   4), `modes.rigor` (Phase 5), `modes.automation` (Phase 6). If all three were
   already set, say "`project.yaml` already has all three settings — nothing to
   write." and go to Phase 8.
2. **Show the exact lines** that will be added, for example:

   ```yaml
   project:
     stage: Discovery

   modes:
     rigor: standard
     automation: collaborative
   ```

   Placement: the `project:` block directly after the `framework:` block; the
   `modes:` block at the end of the file, after the header comment that explains it.
   If a `project:` or `modes:` block already exists (for example `project.name`
   written by `/brainstorm`), add the missing key inside it — never a second block.
   Nothing else in the file changes: no other key, no reformatting, no removed
   comments, and none of the six fronted knobs.
3. **Ask**: "May I write this to `project.yaml`?" — one approval for the whole change.
   On "no", keep the values in the conversation, say the settings are not saved and
   that re-running `/start` asks again, and continue with Phase 8.
4. **Write** — Read the file first (Edit requires it), then Edit.
   **If `project.yaml` does not exist**, the framework's shipped configuration file
   is missing. Say so, and offer to create a minimal one containing
   `schema_version: 1` and the blocks above. Do not invent a `framework:` block —
   the framework version is not known here; restoring the shipped `project.yaml`
   (see `UPGRADING.md`) brings it back.
5. **Verify** — re-read `project.yaml` and confirm:
   - each written key is present with its value, and each value is valid:
     `project.stage` ∈ `Discovery | Definition | Architecture | Validation | Build |
     Hardening | Launch`, `modes.rigor` ∈ `minimal | standard | full`,
     `modes.automation` ∈ `collaborative | guided | autonomous`;
   - none of the six fronted knobs was added.

   Report the result in one line. If a check fails, say which, and do not claim the
   settings were saved.
6. **Pre-existing fronted knob** — if Phase 1 found one of the six set explicitly
   (from an earlier manual edit), do not remove it. Say once: "`[key]` is set
   explicitly in `project.yaml`, so `modes.rigor` does not change it. Review it with
   `/settings` if that was not intended."

---

## Phase 8: Show the Path, Then Confirm

For options A–C, present the recommended path now — after Phase 5, so it matches the
rigor actually chosen. Print **one** of the three below, using the `modes.rigor`
value from Phase 5; if it is somehow still unset, print the `minimal` path (the
documented default) and say so. Option D users were given their path in Phase 3.

Say first: "Here's your path at `rigor: [value]`. Every skill still runs at any
level — rigor changes what is *required*, not what is *allowed*. At `minimal` you can
still run `/prototype`, `/api-design`, `/ux-design` or anything else the moment you
want it. And if one feature deserves more care — payments, say — raise just that one
with `workflow_overrides.feature_overrides.<feature>` instead of the whole project."

**`minimal` — about four steps to running code:**
- `/brainstorm` — the one-page `design/product/one-pager.md` (it replaces the product
  brief, the feature map and the PRDs at this tier)
- `/setup-stack` — choose and pin the stack layers you have decided
- `/create-stories` — turn the one-pager's `## Build Order` into stories (the
  one-pager is the plan — no separate epic or sprint plan)
- `/dev-story` — the first story in code
- Later: `/smoke-check` before QA hand-off and on the release candidate, then
  `/release-checklist` and `/security-audit quick` before launch (`standard` and
  `full` need `/security-audit full` instead).

**`standard` — the full pipeline:**
- **Discovery**: `/brainstorm` → `/setup-stack` → `/prd-review` on the brief
  (required — the Definition gate checks the review) → `/prototype` for the riskiest
  assumption (optional) → `/gate-check definition`
- **Definition**: `/map-features` → `/write-prd` (one per MVP feature) → `/prd-review`
  (each PRD) → `/gate-check architecture`
- **Architecture**: `/create-architecture` → `/architecture-decision` (the critical
  ADRs) → `/api-design` and `/data-model` (with a backend) → `/security-audit
  threat-model` (with personal data) → `/ux-design accessibility` (with a UI) →
  `/architecture-review` → `/test-setup` → `/setup-stack refresh` (records the data
  and cloud layers once their ADRs are Accepted) → `/gate-check validation`
- **Validation**: with a UI, `/design-language` → `/ux-design shell` →
  `/ux-design patterns` → `/ux-design` for the key screens → `/ux-review`; with a
  backend and a UI, `/api-design reconcile` (recommended); then `/create-epics` →
  `/create-stories` → `/sprint-plan` → `/walking-skeleton` on staging →
  `/gate-check build`
- **Build**: `/dev-story` → `/story-done` for each story, `/smoke-check` →
  `/gate-check hardening`
- **Hardening and Launch**: `/team-hardening`, `/security-audit full`,
  `/usability-report`, `/team-qa`, `/localize qa` (with more than one locale),
  `/incident runbook`, `/changelog <version>` → `/release-notes`, `/smoke-check` on
  the release candidate, `/release-checklist`, `/rollout-plan`, `/launch-checklist` →
  `/gate-check launch` → `/team-release`

**`full` — the full pipeline with every check:**
- Everything in `standard`, plus: brand direction offered inside `/brainstorm`;
  `/review-all-prds` in Definition; at least three Foundation-layer ADRs in
  Architecture; `/create-control-manifest` and `/api-design reconcile` (with a
  backend and a UI) required in Validation; `/load-test` in Hardening; and every
  director gate at every step (`review_mode: full`).

> **Do not present `minimal` as lesser.** It is the documented floor
> (`.claude/docs/workflow-modes.md`): a filled one-pager and a pinned stack before
> code, nothing else demanded up front. Do not oversell it either: with no PRDs,
> product and design problems reach the code before anyone catches them.

**Mismatch.** If the user picked a rigor that contradicts what they described — a
payments product on `minimal`, a weekend hackathon on `full` — apply the mismatch
trigger of `.claude/docs/settings-guidance.md` § 4: say so once, in one sentence,
offer `/settings`, and do not re-ask.

Then use `AskUserQuestion` for the first step. Never run the next skill yourself.

- **Prompt**: "Would you like to start with [recommended first step]?"
- **Options**:
  - `Yes, let's start with [recommended first step]`
  - `I'd like to do something else first`

---

## Phase 9: Hand Off

When the user confirms, reply with a single line: "Type `[skill command]` to begin."
Nothing else — no re-explaining the skill, no encouragement. On "something else",
ask what they have in mind and point to the matching skill, or to `/help`.

Verdict: **COMPLETE** — user oriented, settings written (or explicitly declined), and
handed off to the next step.

The alternative is `Verdict: **NOT ASSESSED** — the stage could not be estimated
(<error>).`, when option D's `stage-estimate.sh` run exits non-zero or prints no
`STAGE:` line (Phase 3 D step 1).

---

## Edge Cases

- **User picks D but the project is empty** — "It looks like a fresh template with no
  product artifacts or code yet. Would A, B or C fit better?"
- **User picks A or B but Phase 1 found code or PRDs** — mention what you found:
  "I noticed [source code under apps/ / N PRDs]. Did you mean D (existing product)?"
- **Returning user** (stage, rigor and automation set; a brief or one-pager exists) —
  skip onboarding: "You're already set up: stage `[stage]`, rigor `[rigor]`,
  automation `[automation]`, and a [product brief / one-pager] at `[path]`.
  Review mode follows rigor unless set explicitly (`minimal`→`solo`,
  `standard`→`lean`, `full`→`full`). Want to pick up where you left off? `/help`
  shows the next step for this stage." Write nothing.
- **Settings exist but no product record** — treat it as a normal run: the Phase 5
  and 6 questions are skipped because the keys are set, and Phase 3 routes as usual.
- **User doesn't fit any option** — let them describe their situation in their own
  words and adapt; route to the closest option.

---

## Collaborative Protocol

`/start` is always collaborative — the rules below apply in every automation mode:

1. **Ask first** — never assume the user's state or intent; Phase 1 findings inform
   the questions, they do not replace them.
2. **Present options** — clear paths with their trade-offs, not mandates.
3. **User decides** — the starting point, the rigor and the automation mode are the
   user's choices; recommendations are labelled as such.
4. **"May I write this to `project.yaml`?"** before the single write, showing the exact
   lines; nothing is written on "no".
5. **No auto-execution** — recommend the next skill; never run it.
6. **No commits** — committing is the user's decision.
