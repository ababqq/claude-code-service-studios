# Skill Test Spec: /consistency-check

## Skill Summary

`/consistency-check` scans all PRDs in `design/prd/` against the glossary registry
(`design/registry/entities.yaml`, sections
`entities | plans | rules | constants | events`) for cross-document contradictions.
It is grep-first: it loads the registry once, greps every in-scope PRD for each
registered name (and, for entities, the
`term_ko` and the `avoid` terms), and full-reads a PRD section only to confirm a
conflict. Findings are classified 🔴 CONFLICT, ⚠️ STALE REGISTRY or ℹ️ UNVERIFIABLE,
and the conversation report ends with `Verdict: PASS | CONFLICTS FOUND | NOT ASSESSED`.
Arguments: `[full | since-last-review | entity:<name> | plan:<name> | rule:<name>]`;
`since-last-review` takes its scope from
`bash .claude/scripts/review-scope.sh since-last-review`.

The scan is read-only. After it, with approval, the skill corrects stale registry
entries or adds cross-PRD facts in `design/registry/entities.yaml` (never deleting an
entry), and appends every 🔴 CONFLICT to `docs/consistency-failures.md` — a gitignored
runtime log, never gate evidence. After corrections the skill closes with
**COMPLETE**, or **BLOCKED** when conflicts remain unresolved. It has no director
gates and does not resolve `review_mode`.

---

## Static Assertions (Structural)

Verified automatically by `/skill-test static` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] `name: consistency-check` equals the skill directory, the catalog `name` and this spec's basename
- [ ] First body line is `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow` `` — exactly these two labels
- [ ] `allowed-tools` grants `Bash(bash "*/.claude/skills/consistency-check/../../hooks/yaml-helper.sh" resolve_config *)` with this skill's own directory name
- [ ] The line after the bootstrap block is exactly ``Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] The automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") follows that line verbatim
- [ ] `allowed-tools` is exactly: `Read, Glob, Grep, Write, Edit, Bash, AskUserQuestion` plus the grant — membership exact, order free
- [ ] `argument-hint` is exactly `"[full | since-last-review | entity:<name> | plan:<name> | rule:<name>]"`
- [ ] Has ≥2 phase headings
- [ ] Phase 3 has the five scans `### 3a: Entity Scan`, `### 3b: Plan Scan`, `### 3c: Rule Scan`, `### 3d: Constant Scan` and `### 3e: Event Scan` — entities, plans, rules, constants and events
- [ ] In-scope PRDs come from the glob `design/prd/*.md` with no exclusion list (every file directly under `design/prd/` is a feature PRD); `since-last-review` narrows the scope with `bash .claude/scripts/review-scope.sh since-last-review`, falling back to `full` (and saying so) on `PRIOR_REVIEW: NONE` or a non-zero exit
- [ ] Contains verdict keywords: PASS, CONFLICTS FOUND, NOT ASSESSED (scan verdict) and COMPLETE, BLOCKED (after corrections)
- [ ] Every write is preceded by "May I write this to `<path>`?" — `design/registry/entities.yaml`, `docs/consistency-failures.md`, and `design/prd/<prd>.md` when a conflict is fixed (the session-state breadcrumb is the one silent append — see Coverage Notes)
- [ ] Outputs only `docs/consistency-failures.md` (runtime, gitignored) and `design/registry/entities.yaml` (updates), plus a PRD edit the user approves; no verdict-bearing report file is written
- [ ] No `!` injection other than the bootstrap line; no `file:line` citations
- [ ] Has a next-step handoff at the end naming current skills (`/prd-review`, `/review-all-prds`, `/create-architecture`, `/propagate-prd-change`, `/write-prd`)

---

## Director Gate Checks

No director gates — this skill spawns no gate agents, and `review_mode` is not among
its keys. Consistency checking is a mechanical scan; its findings go to the user, not
to a director.

---

## Test Cases

### Case 1: Happy Path — 4 PRDs agree with the registry

**Fixture:**
- `design/prd/` contains `auth.md`, `onboarding.md`, `goals.md`, `subscription.md`
- `design/registry/entities.yaml` has entity `goal`, plans `free` and `plus`, rule `suggested_debit_amount`, constants `free_active_goal_limit: 3` and `plus_monthly_price: 4900`, event `goal_created`
- Every PRD that mentions these names states the registered value, meaning and properties

**Input:** `/consistency-check`

**Expected behavior:**
1. Loads the registry once and reports `Registry loaded: [N] entities, [N] plans, [N] rules, [N] constants, [N] events` and the scope
2. Globs `design/prd/*.md` (paths under `design/prd/reviews/` are not PRDs) and lists the in-scope PRDs before scanning
3. Greps each registered name across the PRDs (targeted lines with context, no full reads)
4. Finds no conflict; the report shows the clean-entries count
5. Verdict: PASS

**Assertions:**
- [ ] The registry is read before any PRD
- [ ] The report lists the PRDs scanned and the tier line (`full | standard`)
- [ ] Verdict is PASS when no conflict exists
- [ ] No file is written except the session-state breadcrumb
- [ ] Closes with the `AskUserQuestion` widget ("Consistency check complete — [N] conflicts found. What next?")

---

### Case 2: Failure Path — a PRD restates a registered constant with another value

**Fixture:**
- Registry constant `free_active_goal_limit: 3`, `source: design/prd/subscription.md`
- `design/prd/goals.md` says "Free users can keep up to 5 active goals"
- `design/prd/onboarding.md` calls a goal a "savings plan", a term on the `goal` entity's `avoid` list

**Input:** `/consistency-check`

**Expected behavior:**
1. The constant scan finds the mismatch; the entity scan finds the avoided term
2. Phase 4 reads the conflicting section of `goals.md` to confirm, and treats the registry `source:` PRD as authoritative
3. The report lists both under "Conflicts Found" with the registry value, the conflicting value and the file to change
4. Verdict: CONFLICTS FOUND
5. Asks "May I write this to `docs/consistency-failures.md`?" and appends one entry per conflict

**Assertions:**
- [ ] Verdict is CONFLICTS FOUND (not PASS)
- [ ] Each conflict names both PRD files and both values
- [ ] The resolution names `goals.md` as the file to change (the source PRD is `subscription.md`)
- [ ] The skill does NOT edit `goals.md` unless the user picks "Fix the highest-priority conflict now" and approves "May I write this to `design/prd/goals.md`?"
- [ ] The failure log entry uses the `### [YYYY-MM-DD] — /consistency-check — 🔴 CONFLICT` shape

---

### Case 3: Partial Path — registry behind its source PRD

**Fixture:**
- `design/prd/subscription.md` now states Plus at ₩5,900 per month (changed after the registry entry was written)
- Registry `plus_monthly_price: 4900`, `source: design/prd/subscription.md`
- No other PRD restates the price

**Input:** `/consistency-check`

**Expected behavior:**
1. Phase 4 compares the source PRD's last change date with the entry's `revised:` (or `added:`) date
2. Classifies the finding as ⚠️ STALE REGISTRY (the source PRD changed, the registry did not)
3. Asks "May I write this to `design/registry/entities.yaml`? It fixes the [N] stale entries listed above."
4. On approval updates the value, sets `revised:` to today and adds a `# was: 4900 before [date]` comment
5. Closes with COMPLETE

**Assertions:**
- [ ] The finding is STALE REGISTRY, not CONFLICT
- [ ] The registry write happens only after approval
- [ ] No registry entry is deleted; the two-space `  - name:` indentation is preserved
- [ ] The registry corrections are followed by COMPLETE (or BLOCKED if conflicts remain)

---

### Case 4: NOT ASSESSED — empty registry, no PRDs in scope, or unknown entry

**Fixture:**
- `design/registry/entities.yaml` has no entries (fresh project), or
- `design/prd/` is empty, or
- The argument is `entity:wallet` and the registry has no entry named `wallet`

**Input:** `/consistency-check` (or `/consistency-check entity:wallet`)

**Expected behavior:**
1. Empty registry: stops with NOT ASSESSED — "Glossary registry is empty. Run `/write-prd` to write PRDs — the registry is populated as each PRD's sections are approved. Nothing to check yet."
2. Unknown entry: stops with NOT ASSESSED — "no registry entry named `wallet`" — and lists the closest names
3. No findings table is presented as clean

**Assertions:**
- [ ] Verdict is NOT ASSESSED with the reason named (empty registry, no PRD in scope, or unknown entry)
- [ ] The verdict is never PASS when nothing was compared
- [ ] The recommended next action is `/write-prd`
- [ ] Nothing is written to the registry or the failure log

---

### Case 5: Mode Variant — `since-last-review` and the `minimal` tier

**Fixture:**
- `design/prd/reviews/prd-cross-review-2026-09-01.md` exists; since then only `design/prd/auth.md` changed, and `goals.md` lists `design/prd/auth.md` in its `## Dependencies` table
- Run B: `modes.workflow` resolves to `minimal` and `design/prd/` is empty (the one-pager is the design record)

**Input:** `/consistency-check since-last-review` (Run A), `/consistency-check` (Run B)

**Expected behavior:**
1. Run A: runs `bash .claude/scripts/review-scope.sh since-last-review`; scope = the `CHANGED` PRDs plus every PRD on a `DEPS` line (`auth.md`, `goals.md`); with `PRIOR_REVIEW: NONE`, or when the script exits non-zero, it would fall back to `full` and say so (naming the error in the second case)
2. Run B: reports NOT ASSESSED — nothing to check — and stops

**Assertions:**
- [ ] Run A's in-scope list includes `goals.md` through the dependency edge
- [ ] Run A reports the scope before scanning
- [ ] Run B does not treat an empty `design/prd/` at `minimal` as PASS

---

### Case 6: Director Gate — no gate spawned; review mode has no effect

**Fixture:**
- `design/prd/` contains ≥2 PRDs; the registry has entries
- `modes.review_mode: full` in `project.yaml`

**Input:** `/consistency-check`

**Expected behavior:**
1. Runs the scan exactly as in Case 1
2. No director gate agent is spawned at any point

**Assertions:**
- [ ] No director gate agent is spawned
- [ ] `review_mode` is not among the resolved keys
- [ ] Output contains no gate or gate-skipped entries
- [ ] Review mode has no effect on this skill's behavior

---

## Protocol Compliance

- [ ] Loads the registry, then greps the in-scope PRDs before producing the report
- [ ] Phases 1–5 are read-only (Read, Glob, Grep and the `review-scope.sh` call)
- [ ] The report is shown in full before any write is proposed
- [ ] Scan verdict is one of exactly: PASS, CONFLICTS FOUND, NOT ASSESSED; NOT ASSESSED outranks PASS and never outranks CONFLICTS FOUND
- [ ] Registry and failure-log writes gated by "May I write" approval; never deletes a registry entry (`status: deprecated` instead)
- [ ] Writes no evidence, reports or plans under `production/session-logs/`; the failure log is labelled runtime state, not gate evidence
- [ ] Never writes `modes.review_mode` or any other knob that `modes.rigor` fronts
- [ ] Ends with the `AskUserQuestion` widget and a next-step handoff appropriate to the verdict
- [ ] analysis AN1–AN4: read-only scan; structured findings (🔴 / ⚠️ / ℹ️ sections with the values side by side); writes gated; no director gates

---

## Coverage Notes

- This skill checks named-fact consistency between PRDs and the registry. Holistic
  cross-PRD review (principle drift, cognitive load, conflicting metrics) belongs to
  `/review-all-prds`.
- Detection relies on registered names; a fact that two PRDs restate under different
  names is found only once one of them is registered.
- The session-state breadcrumb (`<!-- CONSISTENCY-CHECK: … | Log: docs/consistency-failures.md -->`
  appended to `production/session-state/active.md`) is the session checkpoint, not a
  report; the spec checks only that it points at the file Phase 6 writes.
- The catalog step `consistency-check` has no artifact to detect (the failure log is
  gitignored), so `/help` shows it as a repeatable optional step.
