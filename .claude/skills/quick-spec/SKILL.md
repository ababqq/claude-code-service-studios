---
name: quick-spec
description: "Lightweight spec for a config change, behaviour tweak or small enhancement, with a rollout note."
argument-hint: "[brief description of the change]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, Bash(bash "*/.claude/skills/quick-spec/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation`

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).


# Quick Spec

This is the **lightweight specification path** for changes that do not need a PRD. Authoring a full PRD with
`/write-prd` is the heavyweight path. Use this skill for small, well-scoped work: a configuration change, a behaviour
tweak, a small enhancement to an existing feature, or a standalone feature too small to warrant a PRD (under about a
week of work).

Every quick spec carries a **rollout note** — the flag key, the staged exposure and the rollback — because a small
change that reaches every user at once, with no switch to turn it off, is not small in production. The spec is
written to be **embedded into a story**: its acceptance criteria and story fields are ready to paste.

**Output:** `design/quick-specs/<kebab-title>-YYYY-MM-DD.md`

**When to run:**
- A change is too small for `/write-prd` but too meaningful to implement without a written rationale.
- `/team-growth` hands off experiment variants: each variant that needs product or engineering work gets one quick
  spec, which the variant's story embeds.

Verdicts: **COMPLETE** (spec written) / **REDIRECTED** (the change belongs in a PRD) / **NOT ASSESSED** (the change
could not be specified — say what was missing).

**Language.** The spec's headings and bold field labels stay in English exactly as the formats below spell them; the
content is written in the user's conversation language (user-facing copy in the locale it ships in).

---

## 1. Classify the Change

Read the argument and decide which category the change falls into:

- **Config** — changing values in an existing feature with no behavioural change: limits, thresholds, schedules,
  retry counts, copy strings, a flag's default. The most minimal path. Example: "raise the auto-debit retry count
  from 2 to 3", "send the deposit reminder at 20:00 KST instead of 21:00".
- **Tweak** — a small behaviour change in an existing feature that adds no new states, screens or API operations.
  Example: "let users edit a goal's target date after creation", "show the progress ring in the goal list, not only
  on the goal screen".
- **Enhancement** — a small addition to an existing feature that may add one or two states, one screen or a few
  additive API operations. Example: "add a 'skip this month' option to auto-debit", "add a CSV export of deposit
  history".
- **Small Feature** — a standalone capability small enough to have no PRD and under about a week of work. Example:
  "ask for an app-store review after the third completed goal", "a maintenance banner driven by remote config".

**Redirect to `/write-prd` instead** when the change:
- introduces a feature that belongs in the feature map, or creates significant dependencies between features;
- is likely to take more than a week, or fundamentally alters an existing feature's core rules;
- changes what a customer pays or is charged — prices, fees, billing cycle, plan contents, credits or promotions
  (these belong in the PRD and in `design/product/pricing-model.md`, with the monetization strategist);
- collects a new kind of personal data or changes who may access data — privacy and authorization rules live in a
  PRD's Non-Functional Requirements;
- needs a breaking API change, or a migration that renames, retypes or deletes data (additive operations and
  additive migrations are fine here and are listed in the spec).

If there is no argument, ask the user to describe the change (plain text prompt), then classify it.

**Experiment variants.** When the request names an experiment (or comes from `/team-growth`), read
`production/growth/<experiment-slug>/brief.md` — `## Variants`, `## Flag & Rollout`, `## Primary Metric & Guardrails`,
`## Instrumentation`. The variant's spec takes its flag key, allocation and guardrails from that brief instead of
inventing a rollout, and records the experiment in its header.

Present the inferred classification using `AskUserQuestion`:
- Prompt: "I've classified this as **[inferred type]** — [brief reason]. Is that correct?"
- Options:
  - `[A] Yes — [inferred type] is correct`
  - `[B] Config — changing values only, no behaviour change`
  - `[C] Tweak — small behaviour change in an existing feature`
  - `[D] Enhancement — small addition to an existing feature`
  - `[E] Small Feature — standalone capability, under a week of work`
  - `[F] This is too large — redirect me to /write-prd`

If [F], or a redirect condition above applies: stop. Verdict: **REDIRECTED** — run `/write-prd <feature>` for this
change (name the redirect condition that applied). Otherwise proceed with the selected type.

---

## 2. Context Scan

Before drafting anything, read the relevant context:

- **The feature's PRD** — find it in `design/prd/` (`Glob` the stem, `Grep` the feature name). Read only the sections
  this change touches — usually `## Business Rules & Calculations`, `## Configuration & Flags`,
  `## Functional Requirements` and `## Acceptance Criteria`. A Small Feature has no PRD; say so.
- **The feature map** — if `design/product/feature-map.md` exists, read the feature's row (tier, status, layer). If it
  does not exist, note "No feature map found — skipping the tier check." and continue.
- **Prior quick specs** — check `design/quick-specs/` for specs that touched this feature, and avoid contradicting
  them.
- **Where a value lives** (Config) — the PRD's `## Configuration & Flags` row for it (key, default, owner, removal
  date); a constant in `design/registry/entities.yaml` (`Grep` its name — the `source:` PRD owns it); and the config
  file or remote-config default in the repository that holds it (`Grep` for the key or the current value). A value
  found hardcoded in application code is itself a finding: the spec moves it into configuration first.
- **Flag keys** — reuse the pattern the PRD's `## Configuration & Flags` already uses; the framework's example form is
  `<feature>.<change>` (`goals.v2-progress-ring`).

Report what was found: "Found the PRD at `design/prd/goals.md` — Configuration & Flags lists
`payments.auto-debit-retry-count` (default 2, owner payments). No conflicting quick specs." (or name the conflicts).

If the change still cannot be specified — the description does not say which behaviour or value changes, and neither
the user nor the scan can name the feature it belongs to — stop: Verdict: **NOT ASSESSED** — name what is missing.
Nothing is written; never invent a value, a flag key or a feature.

---

## 3. Draft the Quick Spec

Use the format for the change's category. Every format has `## Rollout`, `## Acceptance Criteria` and
`## Story Embed`.

### The rollout note (all categories)

```markdown
## Rollout

- **Flag**: `[key]` — default [off | current value], owner [role], remove by [YYYY-MM-DD]
  (or "None — a config value, applied by [remote config | deploy]")
- **Staged exposure**: [internal accounts → 1% → 10% → 50% → 100%, holding [time] at each stage]
  (mobile binary changes: App Store phased release / Google Play staged rollout, plus a server-side switch so the
  behaviour can be turned off without shipping a new build)
- **Guardrails**: [metric — threshold that halts the rollout], e.g. payment failure rate, error rate,
  crash-free sessions, support contacts
- **Rollback**: [flag off | revert the config value | redeploy the previous version]; [data written during the
  rollout: how it is reverted, or "forward-only — explain why that is acceptable"]
- **Experiment**: [`production/growth/<experiment-slug>/brief.md` — variant [name], allocation [x%]] (variants only)
```

A single change gets this note; a release that bundles several changes goes through `/rollout-plan`.

### For Config changes

```markdown
# Quick Spec: [Title]

**Type**: Config
**Feature**: [feature name]
**PRD**: `design/prd/[feature].md` — Configuration & Flags (or "None — no PRD")
**Date**: [today]

## Change

| Key / value | Where it lives | Old | New | Rationale |
|-------------|----------------|-----|-----|-----------|
| [key]       | [config file, remote config, PRD row] | [old] | [new] | [why] |

## Range Check

Maps to the PRD's Configuration & Flags row `[key]` (documented range or limit: [range]).
The new value is [within / at the edge of / outside] that range.
[If outside: why the documented range should change — and the PRD update below.]

## Rollout
[the rollout note]

## Acceptance Criteria

- [ ] Given [context], when [action], then [key] = [new value] applies — read from [config source], not hardcoded
- [ ] The behaviour difference is observable in [specific screen, message or API response]
- [ ] No regression in [related behaviour]

## Story Embed
[see below]

## PRD Update Required?
[Yes / No — if yes: which section, and what the update should say]
```

### For Tweak and Enhancement changes

```markdown
# Quick Spec: [Title]

**Type**: [Tweak / Enhancement]
**Feature**: [feature name]
**PRD**: `design/prd/[feature].md`
**Experiment**: `production/growth/[experiment-slug]/brief.md` — variant [name] (variants only; omit otherwise)
**Date**: [today]

## Change Summary

[1-2 sentences: what changes and why.]

## Motivation

[The user problem this solves and its evidence — support contacts, a funnel drop, a usability finding, an
experiment readout. Which product principle does the change serve?]

## Current Behaviour

The PRD says (quoting `design/prd/[feature].md`, [section]):

> [exact quote of the relevant rule or description]

## New Behaviour

[The replacement rule, written with the precision of a PRD's Functional Requirements: an engineer should be able to
implement it from this text alone. New states listed with how they are entered and left; new parameters defined with
their ranges; loading, empty, error and offline states named for any UI it touches.]

## API & Data Impact

[Additive API operations or fields (the owning contract path) · additive migrations (a nullable column, a new table)
· events added to the tracking plan — or "None".]

## Affected Features

| Feature | Impact | Action Required |
|---------|--------|-----------------|
| [feature] | [how it is affected] | [update PRD / update config / no action] |

## Rollout
[the rollout note]

## Acceptance Criteria

- [ ] Given [context], when [action], then [outcome]
- [ ] Given [edge case], when [action], then [outcome]
- [ ] No regression: [the existing behaviour this must not break]

## Story Embed
[see below]

## PRD Update Required?
[Yes / No — if yes: which file, which section, and what the update should say]
```

### For Small Feature changes

A trimmed PRD shape. Include only what the feature needs — skip User Value, full Business Rules & Calculations and a
full Edge Cases section unless the feature specifically requires them.

```markdown
# Quick Spec: [Title]

**Type**: Small Feature
**Scope**: [1-2 sentences: what this feature does and does not do]
**Date**: [today]
**Estimated Implementation**: [days]

## Overview

[One paragraph a new team member could understand: when it appears, what the user does, what it produces.]

## Core Rules

[Unambiguous rules — numbered lists for sequences, bullets for conditions. Precise enough that an engineer can
implement without asking questions.]

## States & Edge Cases

[Only the ones that matter: loading, empty, error, offline, permission denied, repeated trigger.]

## Configuration & Flags

| Key | Default | Range | Owner | Remove by |
|-----|---------|-------|-------|-----------|
| [key] | [value] | [min–max] | [role] | [date or "permanent config"] |

Every value lives in configuration (a flag or a config file), never hardcoded.

## API & Data Impact
[Additive operations, fields, migrations and events — or "None".]

## Rollout
[the rollout note]

## Acceptance Criteria

- [ ] [Functional: does the right thing]
- [ ] [Functional: handles the edge case]
- [ ] [Observable: the event or metric that shows it works]
- [ ] [Regression: does not break an adjacent feature]

## Story Embed
[see below]

## Feature Map

This feature is not in `design/product/feature-map.md`.
[If it should be tracked: suggested layer and tier.]
[If it is too small to track: "Below the feature-map tracking threshold — the quick spec is sufficient."]
```

### Story Embed (all categories)

The block a story copies. It uses the story header fields as they already exist — a quick spec adds no new story
field:

```markdown
## Story Embed

> **Type**: [Config | Logic | Integration | UI | E2E]
> **Surface**: [web | ios | android | mobile | api | admin | infra | analytics]

**PRD**: `design/prd/[feature].md` (Small Feature: "None — quick spec")
**Requirement**: [TR-ID from the PRD, or "None — quick spec"]
**API Contract**: [operation path, or None]
**Migration**: [plan path, or None]
**Feature Flag**: [flag key from the rollout note, or None]
**Analytics Events**: [event names, or None]

Source spec: `design/quick-specs/[kebab-title]-[YYYY-MM-DD].md`
[the acceptance criteria above]
```

`Config` is the story type for a pure value change (its evidence is a smoke-check pass); a Tweak, Enhancement or Small
Feature takes the type of its main work — `Logic` for rules, `Integration` for an API handler or a third-party call,
`UI` for screens, `E2E` when the acceptance criteria are a whole critical journey.

---

## 4. Approval and Filing

Present the draft to the user in full. Then use `AskUserQuestion`:
- Prompt: "Here's the quick spec draft. How do you want to proceed?"
- Options:
  - `[A] Approve — write it as shown`
  - `[B] Revise — I'll describe what to change`
  - `[C] This grew too large — redirect to /write-prd instead`

If [B]: collect the requested changes, revise the draft, and show this widget again.
If [C]: stop. Verdict: **REDIRECTED** — use `/write-prd <feature>` for this change.

If [A]: ask "May I write this to `design/quick-specs/<kebab-title>-YYYY-MM-DD.md`?"

Use today's date in the filename. The title is a kebab-case description of the change (for example
`auto-debit-retry-count-2026-10-12.md`, `goal-skip-month-2026-10-12.md`). If yes, create `design/quick-specs/` if it
does not exist, then write the file. If no, stop: Verdict: **NOT ASSESSED** — the quick spec was not written.

**If the spec says a PRD update is required**, ask separately after writing the quick spec:
"This spec changes rules in [feature]. May I write this to `design/prd/[feature].md` — specifically the [section]
section?"

Show the exact text that would change (old vs. new) before asking. Keep every heading and bold field label exactly as
it is; do not change the PRD's `> **Status**:` line. Do not edit a PRD without explicit approval.

---

## 5. Handoff

After writing the file, output:

```
Quick spec written to: design/quick-specs/[filename].md
Type: [Config / Tweak / Enhancement / Small Feature]
Feature: [feature name]
Flag: [key, or None]
PRD update: [Required — pending approval / Applied / Not required]
```

Verdict: **COMPLETE** — the quick spec is written and ready to embed in a story.

### Pipeline Notes

Quick specs **bypass** `/prd-review` and `/review-all-prds` by design. They are for small, low-risk, well-scoped
changes where the cost of the full review pipeline exceeds the risk of the change itself; the story that embeds the
spec is checked by `/story-readiness`, and the rollout note keeps the change reversible.

Redirect to the full pipeline if any of the following becomes true while drafting:
- The change adds a feature that belongs in the feature map
- The change significantly alters behaviour across features, or a feature's contract with another
- The change touches pricing, billing, personal data or access rules (Step 1)
- Implementation is likely to exceed a week of work

In those cases: "This change has grown beyond quick-spec scope. I recommend `/write-prd <feature>` to specify it in a
PRD."

### Closing

Close with `AskUserQuestion`, offering only the options that apply (mark the first applicable one `(recommended)`):

- `[_] Run /create-stories <epic-slug> — create the story that embeds this spec` (the feature has an epic)
- `[_] Run /story-readiness <story-path> — validate the story that embeds this spec` (the story exists)
- `[_] Run /propagate-prd-change design/prd/<feature>.md — the PRD changed and ADRs rely on it` (a PRD update was
  applied and an ADR's `## PRD Requirements Addressed` cites the PRD)
- `[_] Run /consistency-check — a registered constant changed` (the value is in `design/registry/entities.yaml`)
- `[_] Return to /team-growth — the next variant` (variant specs)
- `[_] Stop here`

In collaborative and guided modes, never end the skill with plain text after the write — always close with this
widget. In autonomous mode, print the next step and record it via `log_decision`.

---

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and `autonomous` modes, see
`.claude/docs/automation-modes.md`.

1. **Classify before drafting** — the category decides the format and the redirect rules; confirm it first.
2. **Quote before changing** — every Tweak or Enhancement quotes the current rule it replaces.
3. **Never skip the rollout note** — a change without a switch and a rollback is not ready to embed.
4. **Ask before writing** — "May I write this to `<path>`?" before the quick spec and before any PRD edit.
5. **Redirect honestly** — when the change outgrows this path, say so and stop; do not squeeze a PRD into a quick
   spec.
