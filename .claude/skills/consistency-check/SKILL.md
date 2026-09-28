---
name: consistency-check
description: "Scan PRDs against the glossary registry for contradictions (entities, plans, rules, constants, events)."
argument-hint: "[full | since-last-review | entity:<name> | plan:<name> | rule:<name>]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, AskUserQuestion, Bash(bash "*/.claude/skills/consistency-check/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow`

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).


# Consistency Check

Detects cross-document inconsistencies by comparing all PRDs against the glossary registry
(`design/registry/entities.yaml`). Uses a grep-first approach: reads the registry once, then targets only the PRD
sections that mention registered names — no full document reads unless a conflict needs investigation.

**This skill is the write-time safety net.** It catches what `/write-prd`'s per-section checks may have missed and
what `/review-all-prds`'s holistic review catches too late.

**When to run:**
- After writing each new PRD (before moving to the next feature)
- Before `/review-all-prds` (so that skill starts with a clean baseline)
- Before `/create-architecture` (inconsistencies poison downstream ADRs, API contracts and data models)
- On demand: `/consistency-check entity:<name>`, `plan:<name>` or `rule:<name>` to check one registry entry

**Output:** Conflict report (in the conversation) + optional registry corrections in `design/registry/entities.yaml`
+ conflict history appended to `docs/consistency-failures.md` (a gitignored runtime log, not a deliverable).

**Language.** Registry keys, section names and verdict tokens stay in English exactly as written here; findings are
written in the user's conversation language.

---

**`workflow`** (see `.claude/docs/workflow-modes.md`):
- `full` — full glossary-registry cross-check against all PRD sections.
- `standard` — cross-check against the required PRD sections only (Overview, Goals & Non-Goals, Functional
  Requirements, Edge Cases, Dependencies, Non-Functional Requirements, Success Metrics & Instrumentation, Acceptance
  Criteria, and Business Rules & Calculations wherever a PRD has it); User Value and Configuration & Flags are scanned
  only when a registered name appears nowhere else.
- `minimal` — not meaningful: PRDs are not expected (the one-pager is the design record). If no PRD exists, report
  **NOT ASSESSED** — nothing to check — and stop; PRDs written voluntarily are checked as at `standard`.

## Phase 1: Parse Arguments and Load Registry

**Modes:**
- No argument / `full` — check all registered entries against all PRDs
- `since-last-review` — check only PRDs changed since the last cross-PRD review report (plus the PRDs on either end of
  their dependency edges)
- `entity:<name>` — check one domain term across all PRDs
- `plan:<name>` — check one plan across all PRDs
- `rule:<name>` — check one business rule across all PRDs

**Load the registry:**

```
Read path="design/registry/entities.yaml"
```

If the file does not exist or has no entries, stop with **NOT ASSESSED**:
> "Glossary registry is empty. Run `/write-prd` to write PRDs — the registry is populated as each PRD's sections are
> approved. Nothing to check yet."

An empty registry is not a clean result: nothing was compared, so this run cannot say PASS.

Build five lookup tables from the registry (fields as the registry records them — the comment above each section of
the file lists them):
- **entity_map**: `{ name → { source, definition, term_ko, avoid, referenced_by } }` — domain terms
- **plan_map**: `{ name → { source, display_name, price constants, entitlements, referenced_by } }`
- **rule_map**: `{ name → { source, variables, output range, unit, rounding, referenced_by } }`
- **constant_map**: `{ name → { source, value, unit, referenced_by } }`
- **event_map**: `{ name → { source, trigger, properties, referenced_by } }`

Entries with `status: deprecated` are loaded too: a PRD that still uses a deprecated entry is a finding.

Count total registered entries. Report:
```
Registry loaded: [N] entities, [N] plans, [N] rules, [N] constants, [N] events
Scope: [full | since-last-review | entity:name | plan:name | rule:name]
```

A named entry (`entity:`, `plan:`, `rule:`) that the registry does not contain stops the run with
**NOT ASSESSED** — "no registry entry named `<name>`" — and lists the closest names.

---

## Phase 2: Locate In-Scope PRDs

```
Glob pattern="design/prd/*.md"
```

Every file directly under `design/prd/` is a feature PRD — there is nothing to exclude. Review logs and cross-PRD
reports live in `design/prd/reviews/`, which is not a PRD location: drop any path under `reviews/` that a `Grep` glob
returns.

For `since-last-review` mode, compute the scope deterministically:

```
Bash: bash .claude/scripts/review-scope.sh since-last-review
```

It prints `PRIOR_REVIEW:`, the `CHANGED:` PRDs since the most recent `design/prd/reviews/prd-cross-review-*.md`, and
the `DEPS` edges of each changed PRD in both directions. The scope is the existing `CHANGED` PRDs plus every PRD named
on a `DEPS` line. With `PRIOR_REVIEW: NONE`, or when the script exits non-zero, fall back to `full` and say so
(naming the error in the second case).

Report the in-scope PRD list before scanning.

---

## Phase 3: Grep-First Conflict Scan

For each registered entry, grep every in-scope PRD for the entry's name (and, for entities, its `term_ko` and every
term on its `avoid` list). Do NOT do full reads — extract only the matching lines and their immediate context
(-C 3 lines).

This is the core optimization: instead of reading 10 PRDs × 400 lines each (4,000 lines), you grep 50 registered
names × 10 PRDs (50 targeted searches, each returning ~10 lines on a hit).

### 3a: Entity Scan

For each entity in entity_map:

```
Grep pattern="[entity_name]" glob="design/prd/*.md" output_mode="content" -C 3
```

For each PRD hit, compare how the PRD uses the term with the registry entry:
- the meaning — the PRD's usage matches the registered `definition`
- the wording — the PRD uses the registered term, not a term on the entry's `avoid` list (a PRD that says "savings
  plan" where the registry fixed "goal" is splitting one concept into two)
- the states and key attributes the PRD attributes to it

**Conflict detection:**
- Registry defines `[entity]` as `[definition A]`. PRD uses `[entity]` to mean `[definition B]`. → **CONFLICT**
- PRD uses a term on `[entity]`'s `avoid` list for the same concept. → **CONFLICT**
- PRD mentions `[entity]` but states nothing comparable. → **NOTE** (no conflict, just unverifiable)

### 3b: Plan Scan

For each plan in plan_map, grep all in-scope PRDs for the plan name and its display name. Extract:
- the price and billing period stated near it (resolve the registry's price constants through constant_map)
- the entitlements and limits attributed to it
- trial or promotion terms stated for it

Compare against the registry entry:
- A PRD states a different price, period or entitlement for the plan → **CONFLICT**
- A PRD grants an entitlement the plan does not list → **CONFLICT**

### 3c: Rule Scan

For each rule in rule_map, grep all in-scope PRDs for the rule name. Extract:
- variable names mentioned near the rule
- output range, cap, unit or rounding stated

Compare against the registry entry:
- Different variable names → **CONFLICT**
- Output range, unit or rounding stated differently → **CONFLICT**

### 3d: Constant Scan

For each constant in constant_map, grep all in-scope PRDs for the constant name. Extract:
- any numeric value mentioned near the name, with its unit (KRW amount, days, count, percentage)

Compare against the registry value:
- Different number, or the same number in a different unit → **CONFLICT**

### 3e: Event Scan

For each event in event_map, grep all in-scope PRDs for the event name. Extract:
- the trigger described near it
- the properties listed for it

Compare against the registry entry:
- A different trigger for the same event name → **CONFLICT**
- Different or missing required properties → **CONFLICT**

---

## Phase 4: Deep Investigation (Conflicts Only)

For each conflict found in Phase 3, do a targeted full-section read of the conflicting PRD to get precise context:

```
Read path="design/prd/[conflicting_prd].md"
```
(Or use Grep with wider context if the file is large.)

Confirm the conflict with full context. Determine:
1. **Which PRD is correct?** Check the `source:` field in the registry — the source PRD is the authoritative owner.
   Any other PRD that contradicts it is the one that needs updating.
2. **Is the registry itself out of date?** If the source PRD was updated after the registry entry was written (check
   `git log -1 --format=%cs -- design/prd/<source>.md` against the entry's `revised:` or `added:` date), the registry
   may be stale.
3. **Is this a genuine product change?** If the conflict represents an intentional decision, the resolution is:
   update the source PRD, update the registry, then fix all other PRDs (and, when ADRs rely on the source PRD, run
   `/propagate-prd-change` on it).

For each conflict, classify:
- **🔴 CONFLICT** — the same named entity, plan, rule, constant or event with different values or meanings in
  different PRDs. Must resolve before architecture begins.
- **⚠️ STALE REGISTRY** — the source PRD's value changed but the registry was not updated. The registry needs updating;
  other PRDs may be correct already.
- **ℹ️ UNVERIFIABLE** — the name is mentioned but no comparable attribute is stated. Not a conflict; just noting the
  reference.

---

## Phase 5: Output Report

```
## Consistency Check Report
Date: [date]
Registry entries checked: [N entities, N plans, N rules, N constants, N events]
PRDs scanned: [N] ([list names])
Tier: [full | standard] — sections scanned: [all | required sections]

---

### Conflicts Found (must resolve before architecture)

🔴 [Entity/Plan/Rule/Constant/Event Name]
   Registry (source: [prd]): [attribute] = [value]
   Conflict in [other_prd].md: [attribute] = [different_value]
   → Resolution needed: [which doc to change and to what]

---

### Stale Registry Entries (registry behind the PRD)

⚠️ [Entry Name]
   Registry says: [value] (written [date])
   Source PRD now says: [new value]
   → Update the registry entry to match the source PRD, then check the referenced_by PRDs.

---

### Unverifiable References (no conflict, informational)

ℹ️ [prd].md mentions [name] but states no comparable attributes.
   No conflict detected. No action required.

---

### Clean Entries (no issues found)

✅ [N] registry entries verified across all in-scope PRDs with no conflicts.

---

Verdict: PASS | CONFLICTS FOUND | NOT ASSESSED
```

**Verdict:**
- **PASS** — no conflicts. The registry and the PRDs agree on every checked value.
- **CONFLICTS FOUND** — one or more conflicts detected. List the resolution steps.
- **NOT ASSESSED** — nothing could be compared: the registry is empty, no PRD is in scope, or the named entry does not
  exist. Name which. It outranks PASS and never outranks CONFLICTS FOUND.

---

## Phase 6: Registry Corrections

If stale registry entries were found, ask:
> "May I write this to `design/registry/entities.yaml`? It fixes the [N] stale entries listed above."

For each stale entry:
- Update the value / attribute field
- Set `revised:` to today's date
- Add a YAML comment with the old value: `# was: [old_value] before [date]`

If names were found in PRDs that are not in the registry yet, ask:
> "Found [N] entities, plans, rules, constants or events used in PRDs that aren't in the registry yet. May I write
> this to `design/registry/entities.yaml` to add them?"

Only add entries that appear in more than one PRD (true cross-feature facts). Each new entry starts with two spaces and
`- name:` under its section, names its owning PRD in `source:` (`design/prd/<slug>.md`) and lists the other PRDs as a
block under `referenced_by:` — the indentation is a grep contract, never reformat the file.

**Never delete registry entries.** Set `status: deprecated` if an entry is removed from all PRDs.

After writing: Verdict: **COMPLETE** — consistency check finished.
If conflicts remain unresolved: Verdict: **BLOCKED** — [N] conflicts need manual resolution before architecture
begins.

### 6b: Append to Reflexion Log

If any 🔴 CONFLICT entries were found (whether or not they were resolved), ask
"May I write this to `docs/consistency-failures.md`?" and record each conflict there: one row in the summary table and
one entry appended at the end of the file:

```markdown
### [YYYY-MM-DD] — /consistency-check — 🔴 CONFLICT
**Domain**: [feature domain(s) involved]
**Documents involved**: [source PRD] vs [conflicting PRD]
**What happened**: [specific conflict — name, attribute, differing values]
**Resolution**: [how it was fixed, or "Unresolved — manual action needed"]
**Pattern**: [generalised lesson, e.g. "The Free-plan goal limit was restated in onboarding.md instead of referencing
the registry constant — always check entities.yaml before writing a number another PRD owns"]
```

If `docs/consistency-failures.md` does not exist, create it with this header before appending:

```markdown
# Consistency Failure Log

<!-- Maintained by /consistency-check. Do not edit manually. -->
<!-- One entry per detected conflict, in chronological order. -->

| Date | PRD A | PRD B | Conflict Type | Status |
|------|-------|-------|---------------|--------|
```

Then append the new conflict entries. Never skip logging — a missing file is not a reason to lose conflict history.
The file is gitignored runtime state: it records what this skill found, it is never evidence for a gate.

---

## Phase 7: Session State and Closing

Silently append to `production/session-state/active.md` (create the file if it does not exist):

```
<!-- CONSISTENCY-CHECK: [date] | PRDs checked: [N] | Conflicts found: [N] | Log: docs/consistency-failures.md -->
```

> **Point at `docs/consistency-failures.md` — the file Phase 6 actually appends to.** A breadcrumb is a pointer left
> for a future session to follow. One that names a file nothing writes sends that session looking for conflict history
> it will never find, and nothing errors along the way. Never invent a report filename here.

Then close with an `AskUserQuestion` widget:

- **Prompt**: "Consistency check complete — [N] conflicts found. What next?"
- **Options**:
  - `[A] Fix the highest-priority conflict now`
  - `[B] Run /prd-review on the most conflicted PRD`
  - `[C] Run /review-all-prds — holistic cross-PRD review` (when ≥2 PRDs exist)
  - `[D] Stop here — conflicts are logged in docs/consistency-failures.md`

Fixing a conflict edits a PRD: show the old and new text and ask "May I write this to `design/prd/<prd>.md`?" first.

In collaborative and guided modes, never end the skill with plain text — always close with this widget. In autonomous
mode, print the findings and recommended next step, then record via `log_decision` (no widget).

---

## Recovery / Reference

- **If PASS**: Run `/review-all-prds` for the holistic cross-PRD review, or `/create-architecture` if all MVP PRDs are
  complete.
- **If CONFLICTS FOUND**: Fix the flagged PRDs, then re-run `/consistency-check` to confirm resolution. If the source
  PRD itself changed and ADRs rely on it, run `/propagate-prd-change design/prd/<source>.md`.
- **If STALE REGISTRY**: Update the registry (Phase 6), then re-run to verify.
- **If NOT ASSESSED**: Write or approve PRDs with `/write-prd` so the registry has entries, then re-run.
- Run `/consistency-check` after writing each new PRD to catch issues early, not at architecture time.
