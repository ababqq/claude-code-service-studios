---
name: write-prd
description: "Section-by-section PRD authoring for one feature; cross-references dependencies, the glossary registry and the tracking plan."
argument-hint: "<feature-name> [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskUpdate, Bash(bash "*/.claude/skills/write-prd/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,docs.density,feature_overrides,accessibility`

Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

# Write PRD

This skill writes the product requirements document for **one feature** — `design/prd/<feature>.md` — one section at
a time, with the user deciding every section and the right specialists consulted for each. It arrives informed: it
reads the product brief, the feature map, the PRDs this feature depends on and the glossary registry before it asks
anything, so the PRD neither contradicts an earlier decision nor invents a number another PRD already fixed.

The PRD is the contract the rest of the pipeline builds from: `/architecture-review` traces its requirements to
ADRs, `/api-design` and `/data-model` start from its API & Data Impact, `/create-stories` embeds its acceptance
criteria, `/scope-check` compares delivered work against its Non-Goals, and `/retrospective release <version>`
judges the shipped feature against its success metrics.

### Outputs

| Path | What is written |
|------|-----------------|
| `design/prd/<feature>.md` | The PRD, from `.claude/docs/templates/prd.md` — skeleton first, then each approved section |
| `design/product/feature-map.md` (status) | The feature's row: `Status` `Not Started` → `Drafting` (skeleton) → `In Review` (authoring done) and its `PRD` path; the Progress Tracker counts |
| `design/registry/entities.yaml` | New cross-feature entities, plans, rules, constants and events; `referenced_by` additions |
| `design/product/tracking-plan.md` (append events) | The events of `## Success Metrics & Instrumentation`, `Owner PRD` = this PRD; created from `.claude/docs/templates/tracking-plan.md` when absent |
| `design/product/pricing-model.md` (when the PRD defines plans/prices/credits) | Plans, prices, entitlements, credits or promotions this PRD defines; created from `.claude/docs/templates/pricing-model.md` when absent |

Also updated: `production/session-state/active.md` (the checkpoint, after every section), and — only to add a missing
reverse row, asking first — the `## Dependencies` table of a dependency's PRD (Section G).

### What this skill never does

- **Write a section the user has not approved** (collaborative), or present a whole PRD as a finished draft.
- **Translate or rename a heading.** Every `#`, `##` and `###` heading and every `> **Field**:` label comes from the
  template, in English, exactly — `prd-structure-check.sh`, the commit hook and the gates match on them. The body is
  written in the user's conversation language.
- **Silently contradict** a registered value, an approved dependency PRD or the brief.
- **Invent a baseline, a price or a limit.** An unknown number is `NOT DETERMINED — <reason>` and a question for the
  user.
- **Run the review in this session.** `/prd-review` needs an independent context (Phase 5f).
- **Add rows to the feature map.** `/map-features` owns the feature set; this skill only moves its own row's status
  and PRD path.

---

## Phase 1: Parse Arguments and Resolve the Tier

A feature name, or the path of an existing PRD, is **required**.

**No argument:**

1. If `design/product/feature-map.md` exists, read it and take the first row of its `## PRD Authoring Order` whose
   feature still has `Status` `Not Started` in the `## Features` table (fall back to the first MVP row with
   `Not Started`). Use `AskUserQuestion`:
   - Prompt: "The next feature in your authoring order is **<feature>** (<tier> · <layer>). Write its PRD now?"
   - Options: `[A] Yes — write <feature>` / `[B] Pick a different feature` / `[C] Stop here`
   - [A] proceed with that feature; [B] ask which feature (plain text); [C] exit.
2. If there is no feature map, stop with:
   > "Usage: `/write-prd <feature-name>` — e.g. `/write-prd goals`.
   > To fill the missing sections of an existing PRD: `/write-prd design/prd/<feature>.md`.
   > No feature map found. At the standard and full workflow tiers run `/map-features` first to decompose the brief
   > into features and get the authoring order." — verdict `NOT ASSESSED — no feature named`.

**Feature slug.** Normalise the name to kebab-case (`savings goals` → `savings-goals`). The slug is the PRD stem, the
feature-map `Feature` value, the `workflow_overrides.feature_overrides` key, the `TR-<slug>-NNN` prefix and the
`**PRD**:` field of every story — choosing it is a **major** decision: when the feature map already lists the feature,
use its slug exactly; otherwise confirm the slug with the user before anything is written.

**Fill mode.** If the argument is a path to an existing `design/prd/*.md`, or `design/prd/<slug>.md` already exists:

1. Read the PRD.
2. Find which contract headings are present. A section is present when a line matches
   `^##+[[:space:]]+([0-9]+[.)][[:space:]]+)?<heading>` case-insensitively (prefix match, optional `3. ` / `3) `
   numbering) — the same rule `prd-structure-check.sh` applies (`.claude/docs/workflow-modes.md` § PRD Required
   Sections per Tier). Use Grep with `-i`.
3. Find which present sections hold only a placeholder (`[To be designed]`, an empty body, a single stub line).
4. Present, before doing anything else:
   ```
   ## Fill: <Feature Name>
   File: design/prd/<feature>.md    Status: <status>    Effective tier: <tier>

   Sections already written (will not be touched):
   ✓ <section>

   Required at this tier and missing or incomplete (will be authored):
   ✗ <section> — missing heading
   ✗ <section> — placeholder only

   Not required at this tier (available to add):
   · <section>
   ```
   A section absent from the file is a gap **only when the tier requires it**; otherwise list it as available.
5. Ask: "Shall I fill the <N> missing sections? I will not modify any existing content."
6. If yes, continue with Phase 2 as normal; in Phase 3 insert only the missing headings (each at its contract
   position, with a `[To be designed]` body — asking first), and in Phase 4 walk only the missing or placeholder
   sections. **Never overwrite existing section content**: Edit replaces only a placeholder body or an empty body.
7. If the PRD's `> **Status**:` is `Approved` or `Implemented`, filling it is a revision of an approved contract. Say
   so; after writing, recommend `/propagate-prd-change design/prd/<feature>.md`, and move the status back to
   `In Review` only with the user's agreement.

**Effective tier.** Look the slug up in the resolved `feature_overrides` line: `<slug>=<tier>` there wins; otherwise
use the resolved `workflow` value. A `feature_overrides` key naming this feature is healthy even though
`design/prd/<slug>.md` does not exist yet — this skill is what creates it. Never report it as an orphan key, and never
refuse the tier it names. Record the effective tier and its source (`feature_overrides` or `workflow`) for the
summary.

**Required sections per effective tier** (`.claude/docs/workflow-modes.md` § PRD Required Sections per Tier):

| Tier | Required | Conditional | Advisory (offered, not required) |
|------|----------|-------------|----------------------------------|
| `full` | all eleven contract sections | — | — |
| `standard` | Overview, Goals & Non-Goals, Functional Requirements, Edge Cases, Dependencies, Non-Functional Requirements, Success Metrics & Instrumentation, Acceptance Criteria | Business Rules & Calculations — required when the feature defines **any numeric or policy rule**: prices, fees, limits, quotas, rate limits, eligibility thresholds, time windows, rounding | User Value; Configuration & Flags (required when `workflow_overrides.config_flags: true`) |
| `minimal` | none — the one-pager is the design record; this PRD is voluntary | — | every section; Edge Cases becomes required when `workflow_overrides.edge_cases: true` |

- `## Summary` and its `> **Quick reference**` line are written at **every** tier (Phase 5-pre) — they are not one of
  the eleven, and the tiered-loading readers (`/review-all-prds`, `/create-epics`, `/architecture-review`) depend on
  them.
- **The Business Rules test is the content, not the category.** The feature map's `Category` is a hint — `Payments`,
  `Billing` and `Domain` features almost always qualify — but an `Account` feature with a data-export rate limit or a
  `Notifications` feature with a quiet-hours window qualifies too. If any requirement states a quantity or a policy
  threshold, the section is required at `standard`.
- `workflow_overrides.edge_cases` and `workflow_overrides.config_flags` have no resolved label: read them from
  `project.yaml` with Read now. They only ever add a requirement.
- At `minimal`, tell the user the PRD is optional at this workflow tier and recommend the eight `standard` sections
  as the useful subset; the user chooses which to author.
- Fill mode fills whatever the tier requires and is missing; it never removes a section that exists.

**`docs.density`** controls the *depth* of each section; the tier controls *which* sections exist. `terse` = bullet
points, 2–5 lines per section, no rationale or preamble; `balanced` = paragraphs with light rationale; `thorough` =
full prose with rationale, examples and alternatives considered. Apply it to every section. The mandated structures —
the Business Rules variable table, the Dependencies table, Given/When/Then criteria, metric baselines and targets —
are correctness requirements at every density: `terse` trims the prose around them, never the structure.

**Review mode.** An inline `--review full|lean|solo` overrides the resolved `review_mode` for this run. It governs the
consultant spawns of Phase 4 and the PD-PRD-ALIGN gate of Phase 5b. The gate definitions live in
`.claude/docs/director-gates/`; the spawned agent reads its own gate file — never read it in this session (pattern:
`.claude/docs/director-gates.md` § Invocation Pattern).

---

## Phase 2: Gather Context (Read Phase)

Read everything relevant **before** asking the user anything. This is the skill's advantage over ad-hoc writing.

### 2a. Required reads

> **At a `minimal` project tier** read `design/product/one-pager.md` in place of the brief and **skip the feature-map
> read** — neither `product-brief.md` nor `feature-map.md` is written at `minimal`. Author from the one-pager's
> `## Core User Journey`, `## Scope & Non-Goals` and `## Build Order`.
>
> **This branch keys on the PROJECT tier, not this feature's effective tier.** The two differ whenever
> `workflow_overrides.feature_overrides` raises one feature above a `minimal` project — the configuration the
> override exists for ("one deep feature in a light project"). The brief and the feature map are absent because the
> *project* is `minimal`; raising *this feature* to `standard` or `full` does not create them. So on a `minimal`
> project take this branch even for an overridden feature. The effective tier still governs everything downstream —
> the required set, the skeleton, the section walk and the self-check. Only the required *reads* follow the project
> tier.
>
> **Then derive `Category`, `Layer` and `Tier` from the one-pager, once, here** — later steps (consultant routing,
> the Business Rules hint, the Quick reference, the PD-PRD-ALIGN context) are keyed on the feature map you skipped:
> - `Category` — one of the recommended values in `.claude/docs/templates/feature-map.md` § Categories, from what the
>   one-pager says the feature does.
> - `Layer` — `Foundation` if other features depend on it, else `Feature`.
> - `Tier` — `MVP` if `## Build Order` lists it, else `Later`.
>
> Carry them for the rest of the run and **mark them inferred** in the Quick reference ("Tier: `MVP` (inferred from
> the one-pager — no feature map at this tier)"). Do **not** write a feature map to hold them: `/map-features` owns
> that file.

- **Product brief**: read `design/product/product-brief.md`. If it is missing, stop:
  > "No product brief found. Run `/brainstorm` first." — verdict `NOT ASSESSED — no product brief`.
- **Feature map**: read `design/product/feature-map.md`. If it is missing, stop:
  > "No feature map found. Run `/map-features` first to decompose the brief into features." — verdict
  > `NOT ASSESSED — no feature map`.
- **The feature's row**: find the slug in the `## Features` table. If it is not listed, say so and ask:
  - Options: `[A] Add it with /map-features <feature> first (Recommended)` / `[B] Write it off-map — tier and layer
    asked now, feature-map update skipped` / `[C] Stop`
- **Glossary registry**: read `design/registry/entities.yaml` if it exists. Collect the **live** entries this feature
  owns or uses — `source: design/prd/<feature>.md`, or the PRD path listed under `referenced_by:` — plus every entry
  whose name the brief or the dependency PRDs attach to this feature. Match entries under the live section keys only
  (`entities:`, `plans:`, `rules:`, `constants:`, `events:`); the shipped file carries fully formed **commented**
  examples (`free_active_goal_limit`, plan `plus`), and a grep that returns comment lines would present invented
  values as locked facts. Hold the live entries as **known facts** this PRD must not contradict.
- **Reflexion log**: read `docs/consistency-failures.md` if it exists and extract entries whose domain matches this
  feature's category — recurring conflict patterns to show under "Past conflicts" in 2e.

### 2b. Dependency reads

From the feature map: **upstream** = the features in this row's `Depends On`; **downstream** = the rows whose
`Depends On` names this feature. For each one that already has a PRD, read **only the sections that carry the
cross-feature contract**, not the whole file:

```
Grep pattern="^## (Dependencies|Business Rules & Calculations|Edge Cases|Configuration & Flags|API & Data Impact)" path="design/prd/<dep>.md" output_mode="content" -A 20
```

Use the registry first — its `plans`, `rules` and `constants` carry the owned values with their `source:`; the
section grep fills what the registry does not hold. Do **not** glob-and-read `design/prd/*.md` hunting for
"related" features: there is no deterministic proxy for relatedness, and it is the read the registry exists to
replace. A known overlap is a dependency — treat it as one.

### 2c. Optional reads

- `design/prd/<feature>.md` — resume, never restart (fill mode, Phase 1).
- `design/product/personas/*.md` and `design/product/user-journey.md` — persona and journey context for User Value.
- `design/product/tracking-plan.md` — existing events, so this PRD reuses names instead of minting near-duplicates.
- `design/product/pricing-model.md` — when the feature touches plans, prices, credits or promotions.
- `project.yaml` → `naming.events` (event naming convention) and `localization.locales`: neither has a resolved label,
  so read them with Read. Unset is recorded as unset, never assumed.

### 2d. Surfaces this feature ships on

Which of `web`, `ios`, `android` and `api` (an externally consumed API) does **this feature** touch? Derive it from the
brief (or one-pager) and the feature's description, and confirm it with the user in 2e — a feature can be web-only in a
product that also ships apps (an admin console), or API-only. The answer routes the Non-Functional Requirements
consultants (Phase 4) and scopes the screen states in Functional Requirements.

### 2e. Present the context summary

> **Writing PRD: <Feature Name>** (`design/prd/<feature>.md`)
> - Tier: <MVP | Beta | GA | Later> · Layer: <layer> · Category: <category> (from the feature map, or inferred)
> - Effective workflow tier: <tier> (<source>) — required sections: <list>
> - Surfaces: <web, ios, android, api — as confirmed>
> - Depends on: <features, noting which have PRDs and their status>
> - Depended on by: <features, noting which have PRDs>
> - Decisions to respect: <key constraints from dependency PRDs>
> - Principle served: <the brief's product principle this feature implements>
> - **Known cross-feature facts (registry):**
>   - <entity>: <definition> (owned by <source PRD>)
>   - <plan>: <entitlements, price constant> (owned by <source PRD>)
>   - <rule>: variables=<list>, output=<range> (owned by <source PRD>)
>   - <constant>: <value> <unit> (owned by <source PRD>)
>   - <event>: <kind>, trigger=<…> (owned by <source PRD>)
>   *(These values are locked. If this PRD needs a different value, surface the conflict before writing — never use a
>   different number silently.)*
> - Past conflicts in this domain: <from the reflexion log, or omit>

Omit the registry block when nothing is relevant. For every upstream dependency without a PRD, warn:
> "<dependency> has no PRD yet. We will have to assume its interface. Write it first, or define the expected contract
> here and mark it provisional."

### 2f. Constraints pre-check

Surface the constraints that will shape the requirements before the user starts deciding them:

1. **Stack reference** — if `docs/stack-reference/VERSION.md` exists, read the Pinned Components rows for the
   components this feature will lean on (the payment SDK, the push provider, the web framework) and their Knowledge
   Risk. A component with MEDIUM or HIGH risk is named as a knowledge gap to verify before an ADR commits to it. If the
   file does not exist, say so by name — "no stack reference yet (`docs/stack-reference/VERSION.md`); constraints not
   checked against pinned versions" — and carry that line into the summary. A silent skip is indistinguishable from a
   check that found nothing.
2. **Existing ADRs** — find the relevant ADRs without reading every ADR:
   ```
   Grep pattern="\*\*Domain\*\*" glob="docs/architecture/adr-*.md" output_mode="content"
   ```
   Read only the ADRs whose Domain matches this feature (Auth for sign-in, Data for new entities, Integrations for a
   third party, Messaging for events) — their `## Decision` and `## Stack Compatibility` sections.
3. **External approvals** — third parties whose review gates the feature (payment-provider merchant review, KakaoTalk
   알림톡 template approval, App Store / Google Play review of subscriptions or account deletion). Name them now so
   Dependencies and Edge Cases account for them.

Present:

```
## Constraints Brief: <Feature Name>
Stack reference: <pinned components relevant here, with Knowledge Risk> | not available — <reason>
ADRs that constrain this feature: ADR-NNNN <decision> — means <implication> | none yet
Knowledge gaps to verify: <component — MEDIUM/HIGH risk> | none
External approvals: <list> | none
```

Then `AskUserQuestion`:
- "Any constraints to add before we begin, or proceed with these noted?"
  - Options: `Proceed with these noted` / `Add a constraint first` / `Pause — I need to check something`
- "Ready to start writing <feature>?"
  - Options: `Yes, let's go` / `Show me more context first` / `Write a dependency's PRD first`

---

## Phase 3: Create the Skeleton

Once the user confirms, create the PRD file **immediately** with every heading of the template and a placeholder
body, so each approved section has a fixed place to land.

**The skeleton is byte-identical in headings and order to `.claude/docs/templates/prd.md`** — every `#`, `##` and
`###` heading, in the same order, at every tier. The template, `prd-structure-check.sh`, the commit hook and this
skeleton encode one contract; if you ever change one, change all of them in the same commit. Sections the tier does
not require keep their heading: Phase 4 either authors them or replaces the placeholder with a one-line note saying why
they were not authored — never an empty body, never a deleted heading.

```markdown
# [Feature Name]

> **Status**: Draft
> **Owner**: <user or role> with product-manager
> **Last Updated**: <today>
> **Last Verified**: <today>
> **Implements Principle**: <principle from the brief>
> **Feature Map Tier**: <MVP | Beta | GA | Later>

## Summary

[To be designed]

> **Quick reference** — Layer: `[Foundation | Core | Feature | Presentation]` · Tier: `[MVP | Beta | GA | Later]` · Key deps: `[feature slugs or "None"]`

## Overview

[To be designed]

## Goals & Non-Goals

### Goals

[To be designed]

### Non-Goals

[To be designed]

## User Value

[To be designed]

## Functional Requirements

### Core Rules

[To be designed]

### User Flows & States

[To be designed]

### Interactions with Other Features

[To be designed]

## Business Rules & Calculations

[To be designed]

## Edge Cases

[To be designed]

## Dependencies

[To be designed]

### External Services

[To be designed]

## Non-Functional Requirements

### Performance

[To be designed]

### Availability & Reliability

[To be designed]

### Security & Privacy

[To be designed]

### Accessibility

[To be designed]

### Localization

[To be designed]

## Configuration & Flags

### Feature Flags

[To be designed]

### Config Values & Limits

[To be designed]

## Success Metrics & Instrumentation

### Metrics

[To be designed]

### Events

[To be designed]

### Dashboards

[To be designed]

## Acceptance Criteria

[To be designed]

## UI Requirements

[To be designed]

## API & Data Impact

[To be designed]

## Open Questions

[To be designed]
```

**Header values.** `> **Status**:` is `Draft` (it maps to the feature-map `Drafting`). `> **Feature Map Tier**:` comes
from the feature map (or the inferred tier). Keep the placeholder Quick reference line until Phase 5-pre fills it.

Ask: "May I write this to `design/prd/<feature>.md`?" — and, in the same approval, "May I write this to
`design/product/feature-map.md`?" to move the feature's row from `Not Started` to `Drafting` with `PRD` set to
`design/prd/<feature>.md` (skip the second question when there is no feature map or the feature is off-map; say
which).

If the user declines the skeleton, stop:
> "Verdict: **NOT ASSESSED** — skeleton creation declined; no PRD was written. Every later phase writes into the
> skeleton. Re-run `/write-prd <feature>` when ready."

After writing, create one task per section to author (TaskCreate) so progress stays visible, and update
`production/session-state/active.md` (Glob first: Write when absent, Edit when present). Overwrite — never append to —
the two machine-read blocks:
- `<!-- STATUS -->`: `Feature: <feature>` · `Task: PRD — skeleton created`
- `<!-- CHECKPOINT -->`: current task "Writing PRD <feature>", next step "<first section>", files in progress
  `design/prd/<feature>.md`

---

## Phase 4: Section-by-Section Authoring

Walk the sections in contract order. **Author every section the effective tier requires** (Phase 1). For each section
the tier does not require:

- **Advisory at `standard`** (User Value, Configuration & Flags) and **conditional** Business Rules & Calculations —
  ask once whether to author it. When the user declines, replace the placeholder with one line:
  `> Not authored — advisory at the standard workflow tier.` For Business Rules & Calculations with no numeric or
  policy rule: `> Not applicable — this feature defines no numeric or policy rule (prices, fees, limits, quotas, rate
  limits, eligibility thresholds, time windows, rounding).`
- **At `minimal`** — offer the standard set; each declined section gets `> Not authored — optional at the minimal
  workflow tier.`

The non-contract sections are offered after Success Metrics & Instrumentation and drafted **before** Acceptance
Criteria (so the criteria can cover them), even though they sit after it in the file: UI Requirements, then API & Data
Impact. Open Questions comes last.

### The section cycle

```
Context  →  Questions  →  Options  →  Decision  →  Draft  →  Approval  →  Write
```

1. **Context** — state what the section must contain and surface the decisions from dependency PRDs and the registry
   that constrain it.
2. **Questions** — ask what only the user can answer. `AskUserQuestion` for constrained choices, conversation for
   open exploration.
3. **Options** — where the section is a product choice (not just documentation), present 2–4 approaches with pros and
   cons, explain the reasoning in conversation, then capture the choice with `AskUserQuestion`.
4. **Decision** — the user picks or gives their own direction.
5. **Draft** — write the section in conversation. Mark every assumption about a dependency without a PRD as
   provisional.
6. **Approval** — per the resolved automation mode:
   - **`collaborative`**: in the **same response** as the draft, `AskUserQuestion` — "Approve the <Section> section?"
     Options: `[A] Approve — write it to file` / `[B] Make changes — describe what to fix` / `[C] Start over`.
     A draft without the widget leaves the user at a blank prompt with no path forward — the draft and the widget
     always appear together.
   - **`guided`**: write the section right after the draft with a one-line summary of what was decided — the
     multi-section authoring rule of `.claude/docs/automation-modes.md` (no per-section confirmation). Product choices
     inside the section that are **major** (a limit, a price, anything that gates downstream work) are still asked.
   - **`autonomous`**: write the section and call `log_decision` with decision point
     `Approve <Section> section`, chosen `[A] Approve`, category `minor` — and one entry for each framing or option
     choice made while drafting it.
7. **Write** — Edit the file. `old_string` is the section's whole skeleton block — from its `##` heading down to the
   line before the next `##` heading, sub-headings and placeholders included — and `new_string` is the same headings
   with the approved content. Never match `[To be designed]` alone: every section uses the same placeholder and Edit
   needs a unique match. Confirm the write.
8. **Registry conflict check** — after Functional Requirements and after Business Rules & Calculations: scan what was
   just written for entity names, plan names, rule names, constants and event names that the registry holds. For each
   match compare the values. A difference is surfaced **before** the next section starts:
   > "Registry conflict: <name> is registered by <source PRD> as <registry value>. This section just wrote <new value>.
   > Which is correct?"
   A name not in the registry that another PRD will need is a registration candidate for Phase 5c.

After each write: TaskUpdate the section's task to completed and refresh the session-state `<!-- STATUS -->`
(`Task: PRD — <section> written`) and `<!-- CHECKPOINT -->` (next step: the next section).

### Consultants and review mode

Each section names its consultants (§ Consultant routing below). **Apply the review mode before every consultant
spawn:**

- `solo` → spawn no consultant. Draft the section yourself and add to the draft: "<agents> not consulted — Solo mode.
  Review manually before implementation."
- `lean` → consult only for the two sections with the highest implementation risk — **Business Rules & Calculations**
  and **Acceptance Criteria**; draft the others without agents, with the same note naming who was skipped.
- `full` → spawn as described.

When several consultants serve one section, spawn them in parallel — issue every `Agent` call before waiting for any
result. Give each: the feature name and slug, the brief's value proposition and principles, the confirmed surfaces,
the dependency excerpts and registry facts from Phase 2, the sections already approved, the section being worked on and
the specific question. Consultants return analysis and proposals; **they write no files** — this session owns every
write. Present their output to the user; where two consultants disagree, show both positions and let the user decide
with `AskUserQuestion`.

---

### Section A: Overview

**Goal**: one paragraph a new team member can read cold — what the feature is, who uses it, what it does for them,
why the product needs it.

**Framing (ask before drafting)** — one multi-tab `AskUserQuestion`; derive the recommended option for each tab first
and append `(Recommended)` to it:
- Tab "Framing" — "How should the overview frame this feature?" `[A] As a capability other features build on` /
  `[B] Through what the user can now do` / `[C] Both`. Recommend by Category: user-facing (`Domain`, `Onboarding`,
  `Payments`, `Billing`, `Notifications`, `Search`, `Collaboration`, `Reporting`, `Support`) → `[B]`; internal
  (`Identity` plumbing, `Analytics`, `Compliance`, `Integration`) → `[C]`; `Admin` → `[B]` for the operating team.
  When Layer and Category disagree, **Category wins** — a user-facing feature stays user-facing wherever it sits in
  the dependency graph.
- Tab "ADR ref" — "Reference an existing ADR?" `[A] Yes — cite it for the technical approach` / `[B] No — keep the
  PRD at behaviour level`. Recommend `[A]` when 2f found an ADR naming this feature, else `[B]`.

How the user gets the feature's value — directly, or through the features it enables — is Section C's framing
question, not an Overview tab. Every feature has a user value; never offer "no user value" as an option.

In `collaborative` the widget always appears — never answer these yourself and auto-draft. In `guided` and
`autonomous` these are **minor** framing decisions: select the recommended options, state them in one line and proceed.
The same applies to every "ask before drafting" widget in this walk.

**Questions**: What is this feature in one sentence? How does the user meet it — actively, passively, automatically?
What would the product lose without it?

**Behaviour, not implementation.** If implementation questions come up ("a queue or a cron job?"), note them as
"→ ADR" and move on — the PRD describes behaviour; `/architecture-decision` records how it is built.

**Cross-reference**: the description agrees with the feature's row and the brief. Flag differences.

**Consultant**: `product-manager`.

---

### Section B: Goals & Non-Goals

**Goal**: the scope contract. `### Goals` — outcomes that trace to the brief's value proposition, MVP scope or a
success metric. `### Non-Goals` — concrete capabilities explicitly out of scope (Korean teams: 제외 범위), each saying
where it lives instead (a later tier, another PRD, never). `/scope-check` compares delivered work against this list.

**Questions**: Which brief outcome does this feature move? What will users ask for that we are deliberately not
building now? What does the feature map place in a later tier that a reader might assume is included?

**Cross-reference**: no goal crosses an anti-goal in the brief; no non-goal contradicts the brief's MVP scope; tier
coherence with the feature map (an MVP PRD whose goals need a `Later` feature is scope creep).

**Consultant**: `product-manager`.

---

### Section C: User Value

**Goal**: who this serves and which job it does — persona, Job-to-be-Done ("When <situation>, I want to <motivation>,
so I can <outcome>"), user stories, and the success moment the user notices.

**Framing (ask before drafting)**: "Is this something the user engages with directly, or infrastructure they
experience indirectly?" `[A] Direct` / `[B] Indirect` / `[C] Both`. Recommend by Category, with the Category lists of
Section A: user-facing → `[A]`; internal → `[B]`; `Admin` → `[A]` (the operating team is the user). Never assume the
answer. Either way, the section names a persona, a job and a success moment.

**Questions**: Which persona from the brief (or `design/product/personas/`) is this for? What is their workaround
today? What evidence do we have — interviews, support tickets, funnel data? What moment tells the user it worked?

**Cross-reference**: the persona and job come from the brief — never invented here. The success moment is observable
by the user ("sees the first automatic deposit land in the goal"), not an internal event.

**Consultant**: `product-manager` — ask for 2–3 candidate framings of the job and the success moment, and present them
alongside the draft.

---

### Section D: Functional Requirements

**Goal**: an unambiguous specification an engineer can implement and a tester can check without asking. Usually the
largest section; three sub-sections:

1. `### Core Rules` — numbered, one observable behaviour per item ("The user can pause an active goal; paused goals
   skip scheduled auto-debits"), so `/architecture-review` can trace each to a `TR-<feature>-NNN`. Policy detail —
   limits, fees, eligibility — is referenced by rule name and specified in Business Rules & Calculations.
2. `### User Flows & States` — every flow step by step and every state with its valid transitions, as a table
   (`| State | Entry Condition | Exit Condition | What the User Sees |`). For each screen on the confirmed surfaces,
   name the loading, empty, error, offline, permission-denied and signed-out states; for API-only capabilities, the
   error responses. Link UX specs (`design/ux/<slug>.md`) instead of describing layout.
3. `### Interactions with Other Features` — for each dependency in both directions, what data or event flows in, what
   flows out, and which feature owns it.

**Questions**: Walk me through a typical use, step by step. Where does the user decide something? What can the user
**not** do — constraints matter as much as capabilities. What happens when they are signed out, offline or lack
permission?

**Consultants**: `product-manager` and `business-analyst`, in parallel. `business-analyst` catches missing states,
unhandled transitions and policies hiding in flow prose.

**Cross-reference**: every interaction matches what the dependency PRD says; a value or rule a dependency defines is
referenced, not restated differently. Then run the registry conflict check (cycle step 8).

---

### Section E: Business Rules & Calculations

**Goal**: every numeric or policy rule — prices, fees, limits, quotas, rate limits, eligibility thresholds, time
windows, rounding — specified so that two engineers implement the same result.

**Completion steering — begin every rule with this exact structure:**

```
**Rule: <rule_name>**

`<rule_name> = <expression>`   (or a decision table for a policy rule)

| Symbol | Type | Unit | Range | Source | Description |
|--------|------|------|-------|--------|-------------|
| <name> | int / decimal / bool / enum / date | KRW, days, requests… | <min–max or set> | registry constant / config key / feature flag / user input / derived | <meaning> |

- **Rounding**: <currency, mode (floor / ceil / half-up / half-even), and when it applies — per line or on the total>
- **Output range**: <bounds, clamped or unbounded, and why>
- **Example**: <worked example with real numbers, every step shown>
- **Boundary cases**: <zero, exactly at the limit, maximum, first/last day of a period, concurrent requests, retries>
```

Never write `[Rule TBD]` or describe a calculation in prose without the variable table — a rule without defined
variables cannot be implemented without guessing. The columns match `.claude/docs/templates/prd.md` and the
`business-analyst` rule format exactly; the `Source` column is what carries "business values come from config or flags,
never hardcoded" into the PRD — a variable sourced from a config key is tunable, one marked `constant` is a deliberate
exception, and the distinction is invisible without it. Money is integer KRW (KRW has no minor unit) unless the PRD
states another currency; every price says whether VAT (부가세) is included; days are Asia/Seoul calendar days unless
stated.

**Questions**: What does the feature calculate or limit? Who is eligible, and when? What happens at the edges of a
period, on a plan change, on a refund? Which values must operations be able to change without a release?

**Consultants**: `business-analyst` always — ask for the rules with variable tables, output ranges and boundary cases.
When the feature defines plans, prices, credits, promotions or coupons, also `monetization-strategist` — ask it to
validate price points, entitlements, promotion stacking and refund rules, and to name store-billing constraints for
in-app digital purchases. Present the proposals with `AskUserQuestion`; the user decides; this session writes. Never
invent a price, fee or limit without the specialists' reasoning — a user without pricing expertise cannot evaluate raw
numbers alone.

**Cross-reference**: a rule a dependency PRD owns is cited by name, not reinvented. Then run the registry conflict
check (cycle step 8).

**Pricing model.** When this section (or Functional Requirements) defines plans, prices, credits or promotions, ask:
"May I create/update `design/product/pricing-model.md`?" — creating it from `.claude/docs/templates/pricing-model.md`
when absent (every template heading kept, in order), filling only the headings this PRD informs (`## Plans & Price
Points`, `## Entitlements`, `## Usage Metering & Credits`, `## Promotions & Coupons`, `## Taxes & Currency`,
`## Refunds & Cancellation`, `## Abuse Vectors`), with `monetization-strategist` consulted. A price, plan or
entitlement is a **major** decision — asked in `collaborative` and `guided`; in `autonomous` follow
`.claude/docs/automation-modes.md` § The Pattern Skills Apply at Each AskUserQuestion Site. Never change a price
already recorded there silently — surface it as a conflict with the PRD that set it. Declined ⇒ say so in the summary; `/business-rules-check` reports a pricing PRD
without a pricing model as CONCERNS.

---

### Section F: Edge Cases

**Goal**: unusual situations resolved explicitly, so they do not become incidents.

**Completion steering — each case as a table row** (`| Scenario | Expected Behavior | Rationale |`) or as:
- **If <condition>**: <exact outcome>. <rationale when not obvious>

Examples (adapt to this feature):
- **If the payment provider delivers the same settlement webhook twice**: the second is acknowledged and ignored; the
  amount is applied once (idempotency key = the provider's payment key).
- **If two devices edit the same record at once**: the second write is rejected with a conflict and the client
  refreshes; nothing is silently overwritten.

Never "handle appropriately" — each case names the exact condition and the exact resolution. A case without a
resolution is an open question, not a specification; move it to Open Questions with an owner.

**Questions**: What happens at zero, at the maximum, out of range? When two rules apply at once? When the network
drops mid-request, a retry arrives late, or a third party is down? At a plan change mid-period, an account deletion
with money in flight, a time-zone or month boundary? What would an abuser try?

**Consultants**: `business-analyst` and `qa-lead`, in parallel — give them the approved Functional Requirements and
Business Rules and ask for the cases the rules and states imply that the draft missed. Present their findings and ask
which to include.

**Cross-reference**: a floor, cap or ordering rule a dependency defines that this feature could violate is flagged.

---

### Section G: Dependencies

**Goal**: every feature connection, with direction and nature, as the exact table:

```markdown
| Feature | PRD | Direction | Nature |
|---|---|---|---|
| auth | `design/prd/auth.md` | depends on | hard — sign-in required |
```

`Direction` is `depends on` or `depended on by`; `Nature` starts with `hard` (cannot work without it) or `soft`
(degrades without it), then says what flows. Tools extract the `design/prd/*.md` paths from this table to derive
review scope — keep the header byte-exact and write a PRD path in every row, even for a PRD not written yet. Third
parties go under `### External Services` (`| Service | Used For | Failure Mode | Owning Feature |`) — not parsed.

Pre-fill the rows from the feature map (Phase 2b), then ask: Are dependencies missing? For each, what exactly flows?
Hard or soft?

**Consultant**: `tech-lead` — ask it to confirm data ownership (one owning feature per entity) and flag synchronous
chains that should be events.

**Cross-reference — bidirectional.** When this PRD says `depends on auth`, `design/prd/auth.md` must list this feature
as `depended on by`, and the feature map's `Depends On` for this row must name `auth`. For each one-directional edge:
- the other PRD exists → offer to add the missing reverse row to its `## Dependencies` table, and nothing else in that
  file: "May I write this to `design/prd/<other>.md`?" — declined edges are listed in the summary for correction;
- the other PRD does not exist yet → nothing to write: its own `/write-prd` run pre-fills the row from the feature map
  (Phase 2b);
- the feature map's `Depends On` disagrees with this table → list it in the summary for `/map-features <feature>`;
  this skill never edits the map's dependency columns.

---

### Section H: Non-Functional Requirements

**Goal**: the measurable needs this feature adds on top of the product-wide SLOs, one sub-section each:
`### Performance` (latency percentiles, Core Web Vitals, app start — cite `performance.*` budgets in `project.yaml`
where they apply), `### Availability & Reliability` (availability target, retry and idempotency guarantees, degraded
mode), `### Security & Privacy` (PII fields and classification, authorization per operation — acting on another
user's resource must fail without revealing it exists — retention and deletion, audit needs, consent basis),
`### Accessibility` (the resolved `accessibility.target` line — unset ⇒
`NOT DETERMINED — accessibility.target unset (run /ux-design accessibility)`, never none — and what it means for this
feature's screens), `### Localization` (locales, formats, text-length limits). "Fast" and "secure" are not requirements: every item has a number or a named
standard, or `NOT DETERMINED — <what would decide it>`.

**Consultants**, in parallel, by the surfaces confirmed in 2d: `backend-engineer` (api or any server-side behaviour),
`frontend-engineer` (web), `mobile-engineer` (ios, android); always `security-engineer` and `accessibility-specialist`.
Ask each for the requirements its area needs and the numbers it would commit to. The security engineer applies the
regional checklists the project configures (`.claude/docs/compliance/`).

---

### Section I: Configuration & Flags

**Goal**: everything product or operations can change without a release, with safe ranges.
`### Feature Flags` — `| Flag | Default | Owner | Removal Date | Purpose |` (flag keys like `goals.v2-progress-ring`;
every release flag has a removal date). `### Config Values & Limits` — `| Key | Value | Safe Range | Owner | Effect of
Increase | Effect of Decrease |`.

**Questions**: Which values should be changeable without a code change? What breaks when each is set too high or too
low? Which values interact (changing A makes B irrelevant)? How is the feature rolled out — which flag, which
audiences first?

**Consultant**: `platform-engineer` — derive the config keys from Business Rules & Calculations' variable table and
propose the flag plan.

**Cross-reference**: a value a dependency already exposes is pointed to, not duplicated.

---

### Section J: Success Metrics & Instrumentation

**Goal**: how we will know the feature worked. `### Metrics` — `| Metric | Type | Baseline | Target | Window | Source |`
with at least one metric (primary) tied to the brief's North Star or a guardrail, each with a baseline and a target;
the guardrails this feature could hurt. `### Events` — `| Event | Trigger | Properties | PII |`, named per
`naming.events` (unset ⇒ propose `object_action` in snake_case, past tense, and confirm). `### Dashboards` — where the
metrics are watched, by whom.

At `standard`, at least one metric with a baseline and a target is required; event detail may be `TBD`. A baseline no
one has measured is `NOT DETERMINED — <reason>` — never an invented number. Vanity counts (page views, sign-ups
without activation) do not qualify as the primary metric.

**Consultant**: `analytics-engineer` — ask for the metric definitions (grain, window, filters), the events with typed
properties, and which properties carry personal data.

**Tracking plan.** After this section is approved, ask: "May I append these events to
`design/product/tracking-plan.md`?" When the file is absent, create it from `.claude/docs/templates/tracking-plan.md`
(the four headings and the Events table header byte-exact) with the naming convention filled. Append one row per new
event: `Owner PRD` = `design/prd/<feature>.md`, `Status` = `Planned`. An event name that already exists with another
`Owner PRD` is **not** re-added — reuse it, say so in this PRD, and make it a registry `events` candidate (Phase 5c).
Personal data in a property is marked in the `PII` column with the consent basis recorded under
`### Security & Privacy`. Declined ⇒ the summary says "tracking plan not updated".

---

### Non-contract sections: UI Requirements, API & Data Impact, Open Questions

Never required at any tier and never checked. Offer them after Section J with one `AskUserQuestion`:
- "Which of the optional sections should we write?" — options `All of them` / `UI Requirements and API & Data Impact`
  / `Open Questions only` / `Skip — I'll add these later`.
- Recommend `All of them` when the feature has a UI surface or introduces an operation, an entity or an event;
  `Open Questions only` otherwise. `autonomous` needs a marked recommendation to choose.

**UI Requirements** — `| Screen / Component | States | UX Spec |`. Consultants: `product-designer` and `ux-writer`, in
parallel (flows and states; microcopy that fixes terminology). When the section has real UI content, output:

> **UX flag — <Feature Name>**: this feature has UI requirements. Run `/ux-design` for each screen or flow before
> `/create-epics` — stories cite `design/ux/<slug>.md`, not the PRD, for layout and states.

**API & Data Impact** — operations, entities owned, events published and consumed, migrations. Consultant:
`tech-lead`. When it names operations or entities, output:

> **Contract flag — <Feature Name>**: `/api-design` and `/data-model` start from this section in the Architecture
> phase; entity ownership here must match `docs/registry/architecture.yaml` once it exists.

**Open Questions** — `| Question | Owner | Deadline | Resolution |`: everything raised and not resolved, each with an
owner and a date. Declined optional sections get `> Not authored — optional section.`

---

### Section K: Acceptance Criteria

**Goal**: testable conditions that prove the feature works as specified.

**Completion steering — each criterion as Given/When/Then:**
- **GIVEN** <initial state>, **WHEN** <action or trigger>, **THEN** <observable outcome>.

Include at least one criterion per core rule (Section D) and per business rule (Section E), at least one negative case
and one authorization case (acting on another user's resource fails without revealing it exists), and criteria for the
edge cases a tester can reproduce. Criteria that need a deployed environment say which one (staging). No unmeasurable
adjectives — replace "fast" with the threshold from Non-Functional Requirements. Every criterion must be verifiable by
a tester who has not read the PRD.

> **When Business Rules & Calculations was not authored** (no numeric or policy rule at `standard`), the criteria come
> from Functional Requirements alone — say so in one line rather than silently writing fewer. **If that section was
> skipped but Functional Requirements states a quantity** — a limit, a price, a window — that is the Phase 1 content
> test being met after the fact: stop, tell the user Business Rules & Calculations is required for this feature, and
> author it before finalising the criteria. A criterion cannot verify a number the PRD never defines.
>
> **That escalation applies at `standard` only.** At `full` the section is always authored, so the case cannot arise.
> At `minimal` nothing is required: state the value inline in `### Core Rules` so it stays testable, and move on.

**Consultant**: `qa-lead` — give it the approved Functional Requirements, Business Rules, Edge Cases and UI
Requirements and ask whether every criterion is independently testable and every rule is covered. Surface gaps and
untestable criteria to the user.

**Questions**: What is the minimum set of tests that proves this works? What would a tester check first? Which
criteria need staging, a real device or a real payment sandbox?

---

## Phase 5: Validate, Review and Record

### 5-pre. Author the Summary

Write `## Summary` and its `> **Quick reference**` line now — after the requirements exist, so the summary distils
real content. This runs **at every tier**.

- **Summary body**: 2–3 sentences — what the feature is, what it does for the user, why it exists. A reader who has
  not seen the PRD learns whether it matters to their task.
- **Quick reference**: `Layer` and `Tier` from the feature map (or marked inferred); `Key deps` from the Dependencies
  table just written (feature slugs, or `None`).

Replace the Summary placeholder and the placeholder Quick reference line with one Edit (cycle step 7).

### 5a. Self-check

Read the PRD back **from the file** — the file is the source of truth, not the conversation. Verify:

- The header block is complete; `> **Status**:` is `Draft`.
- `## Summary` and the Quick reference are filled.
- Every heading of the template is present, in order, spelled exactly (the Phase 1 heading rule).
- Every section **required at the effective tier** has real content — no `[To be designed]` left. Never verify against
  a fixed count: below `full` a correct PRD authors fewer than eleven.
- Every section not authored carries its one-line reason instead of a placeholder.
- Business rules each have a variable table and a worked example; edge cases each have a resolution; the Dependencies
  table has the exact header and a PRD path per row; Non-Functional Requirements names performance, availability,
  security & privacy and accessibility; at least one metric has a baseline and a target (or a `NOT DETERMINED` baseline
  with a reason); acceptance criteria are Given/When/Then with a negative and an authorization case.

**Verdict of the run** (reported in the summary — the PRD itself carries no verdict line; its state is
`> **Status**:`), precedence INCOMPLETE > NOT ASSESSED > DRAFT COMPLETE:

- `DRAFT COMPLETE` — every section the effective tier requires has real content, the Summary is filled, and every
  other section carries content or its one-line reason.
- `INCOMPLETE — MISSING <sections>` — one or more required sections are still placeholders (the session stopped, the
  user deferred them, or PD-PRD-ALIGN returned a REJECT-class verdict that was not resolved — then the sections it
  named are listed).
- `NOT ASSESSED` — the required set could not be determined or checked: no feature was named and there is no feature
  map to take one from (Phase 1), the brief or feature map is missing (Phase 2a), the skeleton was declined, the file
  could not be read back, or the Business Rules content test was left undecided. Name the reason.

An `INCOMPLETE` or `NOT ASSESSED` PRD stays `Draft` and its feature-map row stays `Drafting`; skip to 5e.

### 5b. PD-PRD-ALIGN — product director alignment

**Review mode check** — apply before spawning PD-PRD-ALIGN (`--review` overrides the resolved `review_mode`):
- `full` → spawn as normal.
- `lean` → **skip every gate whose ID does not end in `-PHASE-GATE`**. Note: `[GATE-ID] skipped — Lean mode`
  PD-PRD-ALIGN does not end in `-PHASE-GATE`, so lean skips it: record `[PD-PRD-ALIGN] skipped — Lean mode`.
- `solo` → skip all gates. Note: `[PD-PRD-ALIGN] skipped — Solo mode`.

A skipped gate is written into the PRD header where its review line would go —
`> [PD-PRD-ALIGN] skipped — Lean mode` (or `— Solo mode`) — so the record shows the mode was applied, and the summary
names the omission: "PD-PRD-ALIGN not consulted — <Mode> mode; `--review full` runs it."

When it runs, spawn `product-director` via `Agent`:
- Gate: **PD-PRD-ALIGN** — the prompt instructs the agent to read `.claude/docs/director-gates/pd-prd-align.md` first
  (do not read it or paste it yourself).
- Pass: PRD path · product brief path (or one-pager path) · feature-map row for the feature (tier, status) · brief success metrics
- Fill them from Phases 2–5a: `design/prd/<feature>.md`; `design/product/product-brief.md` (at a `minimal` project,
  `design/product/one-pager.md`); the row as `<feature> — Tier <tier>, Status <status>` (off-map or `minimal`: "none —
  Tier <tier> inferred"); the brief's `## Success Metrics` North Star and guardrails (one-pager: `## Success Signal`).
- Await the verdict before continuing.

Parse the first line of the reply as `[PD-PRD-ALIGN]: TOKEN`, TOKEN one of `APPROVE`, `CONCERNS`, `REJECT`, and map
it with the verdict classes of `.claude/docs/director-gates.md` (`## Standard Verdict Format`):

- **APPROVE-class** (`APPROVE`) → continue to 5c.
- **CONCERNS-class** (`CONCERNS`) → present the concerns via `AskUserQuestion`: `Revise flagged sections` /
  `Accept and proceed` / `Discuss further`. Revising re-runs the section cycle for the named sections only, then 5a.
- **REJECT-class** (`REJECT`) → present the blockers. The named sections are redesigned with the user (the section
  cycle) and the gate is spawned again; if the user stops instead, the verdict is `INCOMPLETE — MISSING <those
  sections>` and the PRD stays `Draft`.
- A first line that does not parse, or names another gate, is not an approval — treat it as CONCERNS-class and say the
  verdict line was missing.

Record the outcome in the PRD header, directly under `> **Feature Map Tier**:` (ask first):
`> **Product Director Review (PD-PRD-ALIGN)**: APPROVED <date>` / `CONCERNS (accepted) <date>` / `REVISED <date>`.

### 5c. Update the glossary registry

Scan the finished PRD for cross-feature facts:
- **entities** — domain terms another feature or the UI copy will use (definition, Korean term, terms to avoid)
- **plans** — plans, credit packs, entitlements
- **rules** — named calculations or policies another feature consumes or cites
- **constants** — limits, prices, quotas, windows another PRD must agree with
- **events** — domain events another feature consumes, and analytics events another PRD cites

Register only what crosses a feature boundary (a value only this PRD uses stays in this PRD).

**First check the registry exists** — 2a read it "if it exists", and a grep against a missing file returns nothing,
which looks exactly like "nothing registered yet":
- **Absent** — say so and ask: "`design/registry/entities.yaml` does not exist. May I create it with these <N>
  entries?" (create it with the five sections `entities`, `plans`, `rules`, `constants`, `events` and the grep-contract
  header). Declined ⇒ skip 5c and say the registry was not written — never treat the skip as a clean pass.
- **Present but empty** — every section is `[]`, and the only matches are comment lines. Register the candidates, and
  say which state you found: "registry exists and is empty — all <N> entries are new". Match live entries under a
  section key, never a commented example.
- **Present** — for each candidate:
  ```
  Grep pattern="^  - name: <candidate>$" path="design/registry/entities.yaml"
  ```

Present:
```
Registry candidates from this PRD:
  NEW (not yet registered):
    - <name> [entity]: <definition>
    - <name> [plan]: entitlements=<…>, monthly_price_constant=<…>
    - <name> [rule]: variables=<list>, output=<range>
    - <name> [constant]: <value> <unit>
    - <name> [event]: <kind>, trigger=<…>
  ALREADY REGISTERED (referenced_by will gain this PRD):
    - <name> [constant]: value=<N> ← matches the registry ✅
```

Ask: "May I write this to `design/registry/entities.yaml`?" — <N> new entries and `referenced_by` additions (for an
absent file the wording is *create*, and there is nothing to merge). Append new entries in the grep-contract format
(two spaces then `- name:`; `source: design/prd/<feature>.md`; `referenced_by:` as a block list including this PRD;
`status: active`; `added:` today). Never change an existing value or attribute without surfacing it as a conflict
first; never delete an entry.

### 5d. Update status

When the verdict is `DRAFT COMPLETE` and PD-PRD-ALIGN is resolved (or skip-noted):

- **PRD** — `> **Status**: Draft` → `In Review`, and `> **Last Updated**:` to today.
- **Feature map** — **first check it exists.** It is never written at a `minimal` project, and an off-map feature has
  no row. Absent or off-map ⇒ one line ("no `design/product/feature-map.md` at this workflow tier; nothing to update")
  and continue — never create a feature map or add a row here; `/map-features` owns both. Present ⇒ set this row's
  `Status` to `In Review` and `PRD` to `design/prd/<feature>.md`, and update the `## Progress Tracker` counts.

Ask: "May I write this to `design/prd/<feature>.md`?" and "May I write this to `design/product/feature-map.md`?" as one
listed changeset. The two statuses always move together (`Draft` ↔ `Drafting`, `In Review` ↔ `In Review`) — never
update one without the other.

### 5e. Update session state

Overwrite the `<!-- STATUS -->` block (`Feature: <feature>`, `Task: PRD — <In Review | Draft>`) and the
`<!-- CHECKPOINT -->` block in `production/session-state/active.md`: current task "PRD <feature>", next step (the
review hand-off, or the first missing section), files in progress. In the narrative below the checkpoint record the
sections actually authored, **by name** — never a fixed count — and the key decisions.

### 5f. Summary and review hand-off

```
PRD — <Feature Name>
====================
File:             design/prd/<feature>.md   Status: <In Review | Draft>
Effective tier:   <tier> (<source>)   Surfaces: <list>
Sections written: <names>
Not authored:     <section — reason> | none
Provisional:      <assumptions about dependencies without a PRD> | none
Conflicts:        <registry or dependency conflicts found, and how resolved> | none
PD-PRD-ALIGN:     <APPROVED | CONCERNS (accepted) | REVISED> <date> | skipped — <Mode> mode
Registry:         <n> new, <n> referenced_by updates | not written — <reason>
Tracking plan:    <n> events appended | not updated — <reason>
Pricing model:    created | updated | not applicable | declined
Feature map:      <row → In Review> | not updated — <reason>
Not checked:      <every NOT CHECKED or not-consulted line of this run> | none

Verdict: <DRAFT COMPLETE | INCOMPLETE — MISSING <sections> | NOT ASSESSED>
```

Then the hand-off:

> **To review this PRD, open a fresh Claude Code session and run:**
> `/prd-review design/prd/<feature>.md`
>
> **Never run `/prd-review` in the same session as `/write-prd`.** The reviewer must be independent of the authoring
> context; run here it inherits the whole design conversation, and independent critique is impossible.

Never offer to run `/prd-review` inline — always direct the user to a fresh session.

### 5g. Next steps

`AskUserQuestion` — "What's next?" — offering the options that apply:
- `/consistency-check` — verify this PRD's values against the registry and the other PRDs (recommended before the next
  feature)
- `/write-prd <next feature>` — the next `Not Started` row in the PRD Authoring Order, when one remains (or
  `/map-features next`)
- `/write-prd <feature>` — resume the missing sections (verdict `INCOMPLETE`)
- `/propagate-prd-change design/prd/<feature>.md` — when this run revised an Approved or Implemented PRD
- `/review-all-prds` — when the MVP PRDs are all written
- `/gate-check architecture` — when every MVP PRD is written and reviewed (Definition phase)
- `/create-epics` or `/create-stories` — in the Launch phase, when this PRD specifies the next release's feature and
  has been reviewed
- Stop here for this session

---

## Consultant routing

| Section | Consultants (spawned per the review-mode rules of Phase 4) |
|---------|-----------------------------------------------------------|
| Overview · Goals & Non-Goals · User Value | `product-manager` |
| Functional Requirements | `product-manager` + `business-analyst` |
| Business Rules & Calculations | `business-analyst` (+ `monetization-strategist` when the feature defines plans, prices, credits or promotions) |
| Edge Cases | `business-analyst` + `qa-lead` |
| Dependencies | `tech-lead` |
| Non-Functional Requirements | `backend-engineer` / `frontend-engineer` / `mobile-engineer` per the feature's surfaces + `security-engineer` + `accessibility-specialist` |
| Configuration & Flags | `platform-engineer` |
| Success Metrics & Instrumentation | `analytics-engineer` |
| UI Requirements | `product-designer` + `ux-writer` |
| API & Data Impact | `tech-lead` |
| Acceptance Criteria | `qa-lead` |

When delegating via `Agent`: provide the feature, the brief summary, the dependency excerpts and registry facts, the
approved sections, the section in progress and the question needing expert input. The agent returns analysis; this
session presents it with `AskUserQuestion`; the user decides; this session writes. Agents never write the PRD.

---

## Recovery and Resume

If the session is interrupted (compaction, crash, new session):

1. Read `production/session-state/active.md` — the checkpoint names the feature and the next section.
2. Read `design/prd/<feature>.md` — sections with real content are done; `[To be designed]` sections are not.
3. Run `/write-prd <feature>` — fill mode resumes at the next incomplete section; nothing already approved is
   re-discussed.

This is why every approved section is written immediately: it survives any disruption.

## Context Window Awareness

This is a long-running skill. After each section write, if the status line shows context at or above 70 %, append:

> **Context is approaching the limit (≥70 %).** Your progress is saved — every approved section is in
> `design/prd/<feature>.md`. When you are ready, open a fresh Claude Code session and run `/write-prd <feature>`; it
> detects the completed sections and resumes at the next one.

---

## Collaborative Protocol

**In `collaborative` mode (the default).** For `guided` and `autonomous`, the per-mode rules of
`.claude/docs/automation-modes.md` apply — the "Never" lines below describe what collaborative mode requires.

1. **Question → Options → Decision → Draft → Approval** for every section.
2. **`AskUserQuestion` at every decision point** (Explain → Capture):
   - Phase 1: which feature, the slug, filling an existing PRD
   - Phase 2: surfaces, constraints, ready to start
   - Phase 3: "May I write this to `design/prd/<feature>.md`?" (skeleton + feature-map row)
   - Phase 4: framing widgets, options, each section's approval; the pricing model and tracking plan writes
   - Phase 5: gate concerns, registry write, status write, next steps — **not** "run the review?": 5f forbids offering
     `/prd-review` inline.
3. **"May I write this to `<path>`?"** before the skeleton, every section write and every other file.
4. **Incremental writing** — each section is written as soon as it is approved.
5. **Session state** after every section write.
6. **Cross-referencing** — every section checks dependency PRDs and the registry for conflicts.
7. **Specialist routing** — complex sections get expert input, presented for the user's decision, never written
   silently.

**Never** auto-generate the whole PRD and present it as a finished draft.
**Never** write a section without approval.
**Never** contradict an approved PRD or a registered value without flagging the conflict.
**Always** show where each decision came from — the brief, a dependency PRD, the registry, a consultant or the user.

## Recommended Next Steps

- `/prd-review design/prd/<feature>.md` in a **fresh session** — independent review of this PRD
- `/consistency-check` — this PRD's values against the registry and the other PRDs
- `/map-features next` — pick the next `Not Started` feature in authoring order
- `/review-all-prds` — once the MVP PRDs are written
- `/gate-check architecture` — when every MVP PRD is written and reviewed
