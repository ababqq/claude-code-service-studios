---
name: propagate-prd-change
description: "A PRD changed — find stale ADRs, API contract operations, data model entities, tracking events and stories."
argument-hint: "[design/prd/<feature>.md] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/propagate-prd-change/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,feature_overrides`

Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).


# Propagate PRD Change

When a PRD changes, the work written against it may no longer be valid: the **ADRs** that decided how to build it, the
**API contract operations** that expose it, the **data-model entities** that store it, the **tracking-plan events**
that measure it, and the **stories** that implement it. This skill diffs the PRD, finds every affected artifact,
classifies each one, has the technical director review the assessment (TD-CHANGE-IMPACT), and records the resolutions
in a change-impact report.

**Usage:** `/propagate-prd-change design/prd/goals.md`

### Outputs

| Path | What is written |
|------|-----------------|
| `docs/architecture/change-impact-YYYY-MM-DD-<prd-stem>.md` | The change-impact report: the change summary, every affected artifact with its classification, the resolution decided for each, the superseded requirements and the open items. Written as a draft before the TD-CHANGE-IMPACT review and completed after resolution; the rule-12 `> **Verdict**:` line sits under its H1 |

This is the only file the skill writes. It never edits an ADR, the API contract, the data model, the tracking plan, a
story or the TR registry — each has an owning skill, and the report names which one to run for each follow-up.

Verdicts: **COMPLETE** / **INCOMPLETE** / **NOT ASSESSED**.

**Language.** The report's headings, status values and verdict tokens stay in English exactly as written in Step 6;
the analysis is written in the user's conversation language.

---

**Workflow tier** — resolve it for the **changed PRD's feature** (per `.claude/docs/workflow-modes.md`): use the
`feature_overrides` row for that PRD's stem if the block lists one, else the project `workflow` value. (A feature
pinned `minimal` has no ADRs written against it even on a `standard` project, so its change has no cascade.) The tier
scopes the cascade:

| Artifact | `full` | `standard` | `minimal` |
|---|---|---|---|
| ADRs | every ADR | Foundation-layer (critical) ADRs plus any ADR that cites the changed PRD | not applicable |
| API contract operations | checked | checked | not applicable |
| Stories citing the PRD | checked | checked | not applicable |
| Downstream PRDs (glossary registry) | checked | checked | not applicable |
| Data-model entities | checked | `NOT CHECKED — data model (full tier only)` | not applicable |
| Tracking-plan events | checked | `NOT CHECKED — tracking plan (full tier only)` | not applicable |

At `standard` the two NOT CHECKED lines are printed in the report — a category this tier does not cover is named, not
silently absent. At `minimal`, report "No architecture cascade at `minimal` workflow — the one-pager is the design
record; the PRD change needs no impact analysis." (verdict **NOT ASSESSED**) and stop without writing anything.

---

## 1. Validate Argument

A PRD path argument is **required**. If missing, stop with **NOT ASSESSED**:
> "Usage: `/propagate-prd-change design/prd/<feature>.md`
> Provide the path to the PRD that changed."

The path must be a PRD directly under `design/prd/` — a review log under `design/prd/reviews/` or a product document
under `design/product/` is not a feature PRD (a changed brief is re-reviewed with `/prd-review`, and its features are
re-checked with `/review-all-prds`); say so and stop with **NOT ASSESSED**. If the file does not exist, stop with
**NOT ASSESSED**:
> "[path] not found. Check the path and try again."

---

## 2. Diff the PRD Against Its Previous Version

**Ask git what changed — do not read two whole documents and compare them by eye.** Reading the current PRD in full
*and* the committed version, then diffing them mentally, puts two entire documents in context to find what is usually
a handful of lines — and a model comparing two long documents will eventually miss an edit. Git cannot.

```bash
git diff HEAD -- design/prd/<stem>.md
```

If that is empty, the change may already be committed — widen to the commit that last touched it:

```bash
git diff HEAD~1 HEAD -- design/prd/<stem>.md
```

- **The file has no git history** (never committed): check first whether anything cites it — the Step 4 scans for
  `design/prd/<stem>.md` and `TR-<stem>-`. Nothing cites it → report "No previous version and nothing written against
  it — this is a new PRD, not a revision. Nothing to propagate." (verdict **COMPLETE**, nothing written). Something
  cites it → there is no baseline to diff against: ask the user which sections changed and what they said before; with
  no answer, stop with **NOT ASSESSED** ("no baseline — commit the PRD before revising it").
- **The diff is empty and the file has history**: report that plainly — "no uncommitted or last-commit changes to
  `design/prd/<stem>.md`" — and ask which revision to propagate from, offering the last few commits
  (`git log --oneline -5 -- design/prd/<stem>.md`). An empty diff is not "no impact"; it means nothing changed *here*.

**Map every hunk to its section** — git's hunk headers do not name Markdown sections, so derive them:

- list the current file's headings with line numbers (`Grep pattern="^##+ " path="design/prd/<stem>.md"
  output_mode="content" -n`); a hunk whose `+start,count` range begins at line L belongs to the last heading at or
  above L;
- a hunk that only removes lines is mapped with the previous version's headings
  (`git show <base>:design/prd/<stem>.md | grep -n '^##'`).

From the mapped hunks:
- Identify the sections that changed and how (a rule added, removed or modified; a limit or price changed; a state
  added; a flag renamed; a metric or event changed; an acceptance criterion rewritten).
- Read the surrounding section from the current PRD **only** where a hunk is too small to interpret on its own (a
  changed number whose meaning depends on the rule above it). That is a targeted read of one section, not the document.
- Sections with no hunk are unchanged — by construction, not by inspection.

---

## 3. Produce the Change Summary

From the mapped hunks:

```
## Change Summary: design/prd/<stem>.md
Date of revision: [today] · Diff base: [commit, or "working tree vs HEAD"]

Changed sections:
- [Section name]: [what changed — rule added / removed / modified, limit changed, state added, flag renamed, event renamed]

Unchanged sections:
- [Section name]

Key changes likely to affect built or planned work:
- [Change 1 — e.g. "Free-plan goal limit 3 → 5 (Business Rules & Calculations)"]
- [Change 2]
```

**Downstream PRDs via the glossary registry.** If `design/registry/entities.yaml` exists, it already records which
other PRDs depend on this feature's facts — compute the affected set from it rather than re-reading every PRD:

```
Grep pattern="source: design/prd/<stem>.md" path="design/registry/entities.yaml" output_mode="content" -A 6
```

For each entity, plan, rule, constant or event this PRD **owns** whose value the diff changed, its `referenced_by:`
list is the set of downstream PRDs that may now be inconsistent — report them under "Downstream PRDs". **If the
registry does not exist or has no entries** (it ships as a stub until `/write-prd` populates it), say so and skip this
part — the rest of the cascade still runs.

---

## 4. Load the Affected Artifacts

Scan first, read later: every category below starts with a **denominator** (what exists) and a **scan** (what cites
this PRD), and only Step 5 reads the matches in full. A category whose input does not exist yet (no API contract
before Architecture, no tracking plan) is reported as "N/A — `<path>` does not exist yet", which is neither an impact
nor a clean result.

### 4a. ADRs

Glob the in-scope ADRs (per the tier table: at `standard`, the Foundation-layer set is
`Grep pattern="\*\*Layer\*\*.*Foundation" glob="docs/architecture/adr-*.md" output_mode="files_with_matches"`, plus
any ADR the scans below match). Call the count **N**. If N is 0: "No ADRs in `docs/architecture/` — no ADR cascade."

**Scan the requirement tables — do not full-read the ADRs at this step:**
```
Grep pattern="## PRD Requirements Addressed" glob="docs/architecture/adr-*.md" output_mode="content" -A 15
```
**Recall net — an ADR may cite the PRD or its requirement IDs in prose without tabling them:**
```
Grep pattern="design/prd/<stem>\.md|TR-<stem>-" glob="docs/architecture/adr-*.md" output_mode="files_with_matches"
```
Take the **union** of the ADRs whose table rows name this PRD and the recall-net matches as the affected set **M**.
This turns N full reads into N short scans; Step 5 full-reads only the M.

Interpret the result — a zero-match scan is **never** "no impact" by default:

| Result | Meaning | Action |
|---|---|---|
| **M ≥ 1** | Normal. | Proceed. The N − M non-matching ADRs are *out of scope for this cascade* — do not describe them as verified unaffected. |
| **Both scans 0, N > 0** | Ambiguous — either no ADR relies on this PRD, or the ADRs lack requirement tables. | Run `Grep pattern="## PRD Requirements Addressed" glob="docs/architecture/adr-*.md" output_mode="files_with_matches"`. If that is **also** empty: "[N] ADRs found, none contains a `## PRD Requirements Addressed` section — traceability cannot be computed (`/gate-check validation` requires the section in every ADR). Run `/architecture-decision retrofit <path>`." The ADR category is **NOT ASSESSED**. If it is **non-empty**: the tables exist and genuinely none cites this PRD — "No ADR relies on design/prd/<stem>.md — no ADR impact." |

**Requirement IDs.** Read the entries of `docs/architecture/tr-registry.yaml` whose `prd:` is `design/prd/<stem>.md`
(read-only — `/architecture-review` is its single writer) and `docs/architecture/requirements-traceability.md` if it
exists. A TR-ID whose requirement text the diff changed or removed is a **superseded requirement** (Step 8).

### 4b. API contract operations

Find the contract: `docs/api/openapi*.yaml`, `docs/api/schema.graphql`, `docs/api/*.proto`, `docs/api/asyncapi.yaml`.
None → "N/A — no API contract yet". Otherwise collect the operations this PRD drives, from three sources:
1. the PRD's `## API & Data Impact` section, current and previous version (the diff shows both);
2. the `**API Contract**:` fields (`docs/api/openapi.yaml#/paths/...`) of the stories found in 4e;
3. a grep of the contract for the feature's resources, tags and operation IDs (`/goals`, `tags: [goals]`,
   `operationId: createGoal`).

### 4c. Data-model entities (`full`)

In `docs/data/data-model.md`, the entities this PRD defines or changes (`## Entities`, `## Ownership`,
`## Data Classification`, `## Retention & Deletion`), the `data_ownership` rows of `docs/registry/architecture.yaml`,
and the migration plans in `docs/data/migrations/` that name the feature. At `standard`, print
`NOT CHECKED — data model (full tier only)`.

### 4d. Tracking-plan events (`full`)

In `design/product/tracking-plan.md`, the `## Events` rows whose `Owner PRD` is `design/prd/<stem>.md`. At `standard`,
print `NOT CHECKED — tracking plan (full tier only)`.

### 4e. Stories

```
Grep pattern="^\*\*PRD\*\*: .*design/prd/<stem>\.md" glob="production/epics/*/story-*.md" output_mode="files_with_matches"
```

For each match, read its header block: `> **Status**:`, `**Requirement**:` (TR-ID), `**API Contract**:`,
`**Migration**:`, `**Feature Flag**:`, `**Analytics Events**:`, and its acceptance criteria. Check its
`production/sprint-status.yaml` entry too — a story `in-progress` right now is the most urgent to reach.

Report: "Scanned [N] ADRs — [M] rely on design/prd/<stem>.md ([X] via the requirements table, [Y] via prose only).
Contract operations: [n]. Entities: [n | NOT CHECKED]. Events: [n | NOT CHECKED]. Stories: [n] ([k] not Complete).
Downstream PRDs: [n | registry empty]."

---

## 5. Impact Analysis

**ADRs.** Now read each ADR in the affected set **M** for its reasoning, not just its table — judging whether a
decision is still valid needs the ADR's `## Context` and `## Decision` (and `## Consequences`), not scan output.
**Do not attempt the judgement below from scan output.**

Check size first (`Bash: wc -c "docs/architecture/<adr-file>.md"`):
- **Under ~50KB** — one full `Read` is fine and cheapest at this size.
- **~50KB or larger** — map headings first
  (`Grep pattern="^## " path="docs/architecture/<adr-file>.md" output_mode="content" -n`), then bounded-`Read` only
  `## Context`, `## Decision` and `## Consequences`. An unbounded `Read` on a large ADR hits the read cap, and the only
  way forward is paging through the whole remainder — most of it content this analysis never uses.

For each affected ADR, compare its `## PRD Requirements Addressed` rows against the changed sections:

1. **Locate the requirement** in the current PRD — does it still exist?
2. **Compare** what the PRD said when the ADR was written with what it says now.
3. **Assess the decision** — is it still valid?

| Status | Meaning |
|--------|---------|
| ✅ **Still Valid** | The change does not affect what this ADR decided |
| ⚠️ **Needs Review** | The change may affect this ADR — human judgement needed |
| 🔴 **Likely Superseded** | The change contradicts what this ADR assumed |

```
### ADR-NNNN: [title]
Status: [Still Valid / Needs Review / Likely Superseded]

What the ADR assumed about this PRD:
  "[relevant quote from its PRD Requirements Addressed section or Context]"

What the PRD now says:
  "[relevant quote from the current PRD]"

Assessment:
  [Whether the decision is still valid, and why]

Recommended action:
  [Keep as-is | Revise in place | Supersede with a new ADR]
```

**API contract operations** — classify each: **Unaffected** · **Additive** (new optional field, new operation — no
client breaks) · **Breaking** (a removed or renamed field, a changed type, a tightened validation, a changed auth
scope or error semantics). A breaking change needs a new version or a deprecation window: mobile clients already in
users' hands keep calling the old shape until they update.

**Data-model entities** — **Unaffected** · **Additive** (expand only: a nullable column, a new table) · **Migration
needed** (a rename, a type change, a backfill or a contract phase — plan it expand/contract) · **Classification
change** (a new personal-data field brings consent, retention and deletion obligations).

**Tracking-plan events** — **Unaffected** · **Added** · **Renamed or removed** (every dashboard, funnel and experiment
readout on the old name breaks silently) · **Properties changed**.

**Stories** — **Unaffected** · **Needs update** (acceptance criteria, TR-ID, contract, migration, flag or events no
longer match) · **Blocked** (it depends on a Likely Superseded ADR or a breaking contract change) · **Follow-up
needed** (a Complete story whose shipped behaviour the change alters).

**Downstream PRDs** — each PRD on a changed fact's `referenced_by:` list: **Consistent** · **Needs re-check**.

---

## 6. Draft the Change-Impact Report

Present the full impact report to the user before asking for any action, then ask:
"May I write this to `docs/architecture/change-impact-YYYY-MM-DD-<prd-stem>.md`? This is the draft the technical
director reviews; resolutions are added after the review."

`YYYY-MM-DD` is today's ISO date and `<prd-stem>` the PRD's file stem (`change-impact-2026-11-02-goals.md`). If that
file already exists (a second run today), show its verdict and ask whether to replace it.

```markdown
# PRD Change Impact: design/prd/<stem>.md — YYYY-MM-DD

> **Verdict**: INCOMPLETE

PRD: `design/prd/<stem>.md` · Tier: [full | standard] ([source]) · Diff base: [commit, or "working tree vs HEAD"]
Not checked: [the NOT CHECKED lines of the tier, or "None"]

## Change Summary
[Step 3]

## ADR Impact
[One entry per affected ADR (Step 5), grouped: Likely Superseded, Needs Review, Still Valid.
 "Scanned N, M rely on this PRD" — or the NOT ASSESSED line of Step 4a]

## API Contract Impact
| Operation | Classification | What changes |
|-----------|----------------|--------------|

## Data Model Impact
| Entity | Classification | What changes |
|--------|----------------|--------------|

## Tracking Plan Impact
| Event | Classification | What changes |
|-------|----------------|--------------|

## Story Impact
| Story | Status | Classification | What changes |
|-------|--------|----------------|--------------|

## Downstream PRDs
[PRD — the registry fact it references — Consistent / Needs re-check]

## Superseded Requirements
| Date | PRD | Requirement (TR-ID) | Changed To | ADRs Affected | Resolution |
|------|-----|---------------------|------------|---------------|------------|

## Resolutions
| Artifact | Status | Decision | Follow-up |
|----------|--------|----------|-----------|

## Open Items
[Deferred items, unresolved concerns — or "None"]
```

The draft carries `> **Verdict**: INCOMPLETE` because nothing has been resolved yet. If the user declines the draft
write, the review below receives the draft inline instead, and Step 9 asks again.

---

## 6b. Director Gate — Technical Impact Review

**Review mode check** — apply before spawning TD-CHANGE-IMPACT (`--review` overrides the resolved `review_mode`):

- `full` → spawn as normal.
- `lean` → **skip every gate whose ID does not end in `-PHASE-GATE`**. Note: `[GATE-ID] skipped — Lean mode`
  TD-CHANGE-IMPACT does not end in `-PHASE-GATE`, so lean skips it: record `[TD-CHANGE-IMPACT] skipped — Lean mode`.
- `solo` → skip all gates. Note: `[TD-CHANGE-IMPACT] skipped — Solo mode`.

A skipped review is written into the report where the review line goes (Step 9), and the summary names the omission:
"TD-CHANGE-IMPACT not consulted — <Mode> mode; `--review full` runs it."

When it runs, spawn `technical-director` via `Agent`:

- Gate: **TD-CHANGE-IMPACT** — the prompt instructs the agent to read `.claude/docs/director-gates/td-change-impact.md`
  first (do not read it or paste it yourself).
- Pass: changed PRD path · summary of the PRD diff · impact report draft path
- Fill them as: `design/prd/<stem>.md`; the Step 3 Change Summary; `docs/architecture/change-impact-YYYY-MM-DD-<prd-stem>.md`
  (or "not written — the draft follows inline", with the draft pasted into the prompt).

Parse the first line of the reply as `[TD-CHANGE-IMPACT]: TOKEN`, TOKEN one of `APPROVE`, `CONCERNS`, `REJECT`, and map
it with the verdict classes of `.claude/docs/director-gates.md` (`## Standard Verdict Format`):

- **APPROVE-class** (`APPROVE`) → proceed to Step 7. Record `APPROVED [date]`.
- **CONCERNS-class** (`CONCERNS`) → surface the specific ADRs, operations, entities, events or stories flagged; use
  `AskUserQuestion` with options `Revise the impact assessment` / `Accept with noted concerns` / `Discuss further`.
  Revising re-runs Steps 4–6 for the flagged items and records `REVISED [date]`; accepting records
  `CONCERNS (accepted) [date]` and copies the concerns into `## Open Items`.
- **REJECT-class** (`REJECT`) → do not proceed to resolution. Re-analyze (Steps 4–6) with what the director says was
  missed, then offer the review again. Until a review returns APPROVE-class or accepted CONCERNS, the report stays
  INCOMPLETE.
- A first line that does not parse, or names another gate, is not an approval — treat it as CONCERNS-class and say the
  verdict line was missing.

---

## 7. Resolution Workflow

For each ADR marked Needs Review or Likely Superseded, ask in turn:
> "ADR-NNNN ([title]) — [status]. What would you like to do?"
> Options:
> - "Supersede — a replacement ADR will be written" — follow-up `/architecture-decision <new decision title>`; the
>   old ADR's `## Status` becomes `Superseded by ADR-NNNN` when the replacement exists (that skill records it — this
>   one does not edit ADRs)
> - "Revise in place (minor revision)" — record exactly which sections and fields to revise; the ADR's owner edits it,
>   then `/architecture-review` re-validates coverage
> - "Keep as-is (the change doesn't affect this decision)" — record why
> - "Defer (revisit later)" — becomes an open item

Then resolve the other categories, one question per category listing its affected items (collaborative mode asks per
item when the user prefers):

- **API operations** — Breaking: "Version or deprecate — `/api-design update <resource>`, then
  `/api-design breaking-check`"; Additive: "`/api-design update <resource>`"; or Keep / Defer.
- **Data-model entities** — "Plan the change — `/data-model` (expand/contract migration plan; a classification change
  goes through its privacy review)"; or Keep / Defer.
- **Tracking-plan events** — "Update `design/product/tracking-plan.md` with the analytics engineer — rename with a
  transition period so dashboards and experiment readouts move before the old name stops firing"; or Keep / Defer.
- **Stories** — Needs update / Blocked: "Update the story before it is picked up, then `/story-readiness <story-path>`";
  Follow-up needed: "New story — `/create-stories <epic-slug>`"; or Keep / Defer. An `in-progress` story is named
  first, with the note that its implementer should pause on the changed behaviour.
- **Downstream PRDs** — "Re-check — `/consistency-check`, then `/prd-review <path>` for each PRD that needs revision".

Record every decision in the `## Resolutions` table. Nothing else is edited here.

---

## 8. Superseded Requirements

List every TR-ID from Step 4a whose requirement the diff changed or removed in the report's
`## Superseded Requirements` table, with the ADRs affected and the resolution decided in Step 7.

The TR registry (`docs/architecture/tr-registry.yaml`) and the traceability matrix
(`docs/architecture/requirements-traceability.md`) are **not** edited here: the registry is append-only with a single
writer, `/architecture-review`, which also maintains the matrix. Recommend `/architecture-review` as a follow-up so the
superseded requirements reach the matrix and new requirements get IDs.

---

## 9. Write the Change-Impact Report

Update the draft with the resolutions, the open items and the review record, then ask:
"May I write this to `docs/architecture/change-impact-YYYY-MM-DD-<prd-stem>.md`?"

Directly under the verdict line, add the review record:
`> **Technical Director Review (TD-CHANGE-IMPACT)**: APPROVED [date]` (or `CONCERNS (accepted) [date]` /
`REVISED [date]`), or, when review mode skipped the gate, the skip note `> [TD-CHANGE-IMPACT] skipped — Lean mode`
(or `— Solo mode`) — so the report shows which mode was applied.

**Verdict** (the `> **Verdict**:` line under the H1):
- **COMPLETE** — every affected item has a recorded decision other than Defer, and TD-CHANGE-IMPACT returned
  APPROVE-class, its concerns were accepted, or review mode skipped it.
- **INCOMPLETE** — any item deferred or undecided, a REJECT-class review not yet resolved, or the user stopped before
  resolution. `## Open Items` lists what remains.
- **NOT ASSESSED** — the impact could not be computed: no baseline to diff against, or the ADR category could not be
  traced (Step 4a) and nothing else was assessable. Name what was missing and which skill produces it.

If the user declines the write: "Verdict: INCOMPLETE — change-impact report not written (user declined)."

---

## 10. Follow-Up Actions

Close with `AskUserQuestion`, offering only the follow-ups the resolutions produced (the most urgent first; mark it
`(recommended)`):

- **ADRs to supersede**: "Run `/architecture-decision <title>` to write the replacement ADR, then re-run
  `/propagate-prd-change design/prd/<stem>.md` to verify coverage."
- **ADRs to revise in place**: list the specific sections to update in each, then `/architecture-review`.
- **API contract**: `/api-design update <resource>`, then `/api-design breaking-check` for breaking changes.
- **Data model**: `/data-model`.
- **Stories**: `/story-readiness <story-path>` for each story that needs an update; `/create-stories <epic-slug>` for
  follow-up stories.
- **Downstream PRDs**: `/consistency-check`, then `/prd-review <path>`.
- **Many ADRs affected** or superseded requirements recorded: `/architecture-review` to bring the traceability matrix
  up to date.
- `Stop here`.

In collaborative and guided modes, never end the skill with plain text — always close with this widget. In autonomous
mode, print the verdict and the follow-ups, then record them via `log_decision`.

---

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and `autonomous` modes, see
`.claude/docs/automation-modes.md` — the rules below describe what collaborative mode requires, not universal
behaviour.

1. **Read silently** — compute the full impact before presenting anything
2. **Show the full report first** — let the user see the scope before asking for any action
3. **Ask per ADR** — don't batch ADR decisions; each affected ADR may need different treatment
4. **Ask before writing** — "May I write this to `<path>`?" before the draft and before the final report
5. **Non-destructive** — this skill writes only the change-impact report; ADRs, the contract, the data model, the
   tracking plan, stories and the TR registry change through their owning skills
