# Skill Test Spec: /reverse-document

## Skill Summary

`/reverse-document` generates a missing product or architecture document from what
already exists: `prd` → a feature PRD at `design/prd/<feature>.md` (from
`.claude/docs/templates/prd-from-implementation.md`), `architecture` → an ADR at
`docs/architecture/adr-NNNN-<slug>.md` (from
`.claude/docs/templates/architecture-doc-from-code.md`), `brief` → a product brief from
a prototype or the product as built (from
`.claude/docs/templates/product-brief-from-prototype.md`). It locates the path against
the resolved code roots, resolves the workflow tier for the target feature (its
`feature_overrides` row, else `workflow`), analyzes the implementation, asks about
intent before drafting, and stops when there is not enough implementation to infer
from.

Every document carries a provenance stamp (the "Reverse-documented from
implementation" banner, or the ADR's `> **Origin**:` line under `## Summary`) and marks
unconfirmed intent `INTENT UNKNOWN — inferred from implementation, not confirmed`. The
product brief is never overwritten by default: with an existing
`design/product/product-brief.md` the target is
`design/product/product-brief-from-code-YYYY-MM-DD.md`, and replacing the brief takes an
explicit "May I overwrite `design/product/product-brief.md`?". Verdicts: **COMPLETE**
(document generated), **BLOCKED** (user declined write) and **NOT ASSESSED** (Phase 3b: not
enough implementation to document).

---

## Static Assertions (Structural)

Verified automatically by `/skill-test static` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`; `name: reverse-document` equals the directory `.claude/skills/reverse-document/` and the catalog entry `reverse-document`
- [ ] `description` is exactly "Generate a missing PRD, ADR or product brief from existing code or prototypes."; `argument-hint` is `"<prd|architecture|brief> <path>"`
- [ ] Bootstrap: the first body line is `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys workflow,feature_overrides,automation,code_roots` `` — this key string exactly
- [ ] `allowed-tools` grants `Bash(bash "*/.claude/skills/reverse-document/../../hooks/yaml-helper.sh" resolve_config *)` — the skill's own directory name
- [ ] The line after the bootstrap block is exactly ``Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] The automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") follows that line verbatim
- [ ] `allowed-tools` is exactly: `Read, Glob, Grep, Write, Edit, Bash, AskUserQuestion` + the grant
- [ ] Has ≥2 phase headings (`## Phase 1: Parse Arguments` … `## Phase 8: Flag Follow-Up Work`)
- [ ] Contains the verdict keywords `COMPLETE`, `BLOCKED` and `NOT ASSESSED`
- [ ] Contains "May I write this to [output path]?" before writing, and "May I overwrite `design/product/product-brief.md`?" for the brief
- [ ] Outputs at the exact paths `design/prd/<feature>.md`, `docs/architecture/adr-NNNN-<slug>.md`, `design/product/product-brief.md` (only when absent) or `design/product/product-brief-from-code-YYYY-MM-DD.md`
- [ ] The three template paths are named in the Phase 5 table; headings are copied byte-for-byte from the template
- [ ] No `!` injection other than the bootstrap line; no `file:line` citations of other files
- [ ] Has a next-step handoff naming current skills (`/prd-review`, `/business-rules-check`, `/architecture-review`, `/architecture-decision accept`, `/map-features`)

---

## Director Gate Checks

None. `/reverse-document` is a documentation utility: `review_mode` is not in its keys
and it has no `Agent` tool. Review happens afterwards through `/prd-review` or
`/architecture-decision accept`.

---

## Test Cases

### Case 1: Well-Structured Module — PRD for Moa `goals` at `standard`

**Fixture:**
- `modes.rigor: standard` (resolves `workflow: standard`); no `feature_overrides` row for `goals`
- The block prints `code_roots: … backend=apps/api,services/worker …`
- `apps/api/src/goals/` implements goal creation, pause/resume (`active → paused → completed`), a 1,000,000 KRW daily deposit cap, an auto-debit retry policy (3 retries over 72 hours) and the flag `goals.v2-progress-ring`
- `design/product/feature-map.md` has a `goals` row (Tier `MVP`)

**Input:** `/reverse-document prd apps/api/src/goals`

**Expected behavior:**
1. Names the layer (`backend`) from the code roots and maps the path to the feature slug `goals`
2. Presents BEHAVIOURS IMPLEMENTED, BUSINESS RULES DISCOVERED, CONFIGURATION & FLAGS FOUND and UNCLEAR INTENT AREAS, and waits for the user's answers
3. Drafts from `prd-from-implementation.md` at the `standard` tier: the 8 required sections + `## Business Rules & Calculations` (the deposit cap and retries are numeric rules) + `## Implementation Notes`
4. Fills `> **Feature Map Tier**: MVP` from the feature-map row and stamps the provenance banner under the `>` preamble with the path, date and `git rev-parse --short HEAD`
5. Asks "May I write this to `design/prd/goals.md`?"; writes with `> **Status**: Draft`
6. Reports COMPLETE and flags follow-up work (`/prd-review design/prd/goals.md`, `/business-rules-check`, `/architecture-review`)

**Assertions:**
- [ ] User Value and Configuration & Flags are skipped at `standard` (unless `workflow_overrides.config_flags: true`)
- [ ] The provenance banner is present and names the commit
- [ ] The `## Dependencies` table uses `| Feature | PRD | Direction | Nature |`
- [ ] "May I write" is asked with the exact output path; Verdict is COMPLETE

---

### Case 2: Unanswered Intent — Carried into the document, not resolved

**Fixture:**
- Same module as Case 1; the user answers none of the UNCLEAR INTENT AREAS questions
- The module defines no configuration flag

**Input:** `/reverse-document prd apps/api/src/goals`

**Expected behavior:**
1. The draft carries each unanswered item verbatim as an open question marked `INTENT UNKNOWN — inferred from implementation, not confirmed`
2. An empty findings section says `none found in the source` under its heading — never omitted, never filled from what a feature like this usually has
3. The write still asks "May I write this to `design/prd/goals.md`?"

**Assertions:**
- [ ] No inferred intent is presented as settled
- [ ] Empty sections say `none found in the source`
- [ ] The rows of each findings section match what the source contains (shapes, not quotas)

---

### Case 3: NOT ASSESSED — Not enough implementation to document

**Fixture:**
- `apps/api/src/referrals/` holds an empty controller and a TODO — zero behaviours, zero business rules, zero configuration values

**Input:** `/reverse-document prd apps/api/src/referrals`

**Expected behavior:**
1. The Phase 3b sufficiency check counts the signals and stops before drafting
2. Says "`apps/api/src/referrals` does not contain enough implementation to reverse-document." with the counts, and points to `/write-prd [feature]` (which asks rather than infers)

**Assertions:**
- [ ] No document is drafted or written
- [ ] The counts of behaviours, business rules and configuration values are shown
- [ ] No COMPLETE verdict is produced; the gap is not filled with invented content
- [ ] The run ends with `Verdict: **NOT ASSESSED** — not enough implementation to document ([N] behaviours, [N] business rules, [N] configuration values).` with the counts filled in

---

### Case 4: Architecture — ADR for goal events via a transactional outbox

**Fixture:**
- `apps/api/src/goals/events/` implements a transactional outbox to the notifications worker
- `docs/architecture/adr-0001-identity-and-auth.md` … `adr-0003-payments-provider.md` exist
- `docs/stack-reference/VERSION.md` has rows for NestJS and PostgreSQL but none for the queue client

**Input:** `/reverse-document architecture apps/api/src/goals/events`

**Expected behavior:**
1. Drafts from `architecture-doc-from-code.md`; the number is the next free one (`adr-0004-…`)
2. `## Status` reads `Proposed`; `> **Origin**: Reverse-documented from apps/api/src/goals/events on [YYYY-MM-DD]` sits under `## Summary` with the banner's last three lines
3. `## Stack Compatibility` stamps NestJS and PostgreSQL from `VERSION.md`; the queue client has no row ⇒ `NOT DETERMINED`, Knowledge Risk HIGH
4. `## PRD Requirements Addressed` cites only TR-IDs that already exist in `docs/architecture/tr-registry.yaml` (e.g. `TR-goals-001`), or says `none yet — run /architecture-review after the PRD exists`
5. Asks "May I write this to `docs/architecture/adr-0004-<slug>.md`?"; the first follow-up is `/architecture-decision accept ADR-0004`

**Assertions:**
- [ ] The status is a valid `## Status` value (`Proposed`), never a custom status
- [ ] No TR-ID is invented
- [ ] Missing version rows read `NOT DETERMINED`, never a remembered version

---

### Case 5: Brief — An approved brief already exists

**Fixture:**
- `design/product/product-brief.md` exists (Status `Approved`)
- `prototypes/goal-nudges-concept/REPORT.md` has `> **Verdict**: PROCEED`

**Input:** `/reverse-document brief prototypes/goal-nudges-concept`

**Expected behavior:**
1. Drafts from `product-brief-from-prototype.md`; `## Prototype Evidence` cites `prototypes/goal-nudges-concept/REPORT.md`
2. Because the brief exists, asks "May I write this to `design/product/product-brief-from-code-[date].md`?" — the dated file for the user to merge
3. Replacing `design/product/product-brief.md` happens only after a yes to "May I overwrite `design/product/product-brief.md`?"

**Assertions:**
- [ ] A general approval of the draft never overwrites the existing brief
- [ ] In `autonomous` mode the dated file is written and the decision logged; the brief is never overwritten
- [ ] The follow-up names merging by hand and `/prd-review design/product/product-brief.md`

---

### Case 6: Mode Variant — `minimal` tier with a per-feature override

**Fixture:**
- No `modes.rigor` (resolves `workflow: minimal`); the block prints `feature_overrides: payments=full`

**Input:** `/reverse-document prd apps/api/src/goals`, then `/reverse-document prd apps/api/src/payments`

**Expected behavior:**
1. For `goals` (tier `minimal`): generates no PRD, says so and stops, offering to update the one-pager's `## Core User Journey` and `## Build Order` by hand or `/settings workflow_overrides.feature_overrides.goals=standard`
2. For `payments` (override `full`): generates all 11 contract sections from `## Overview` to `## Acceptance Criteria`, plus `## Implementation Notes`

**Assertions:**
- [ ] The tier is resolved per feature from the config block, not assumed
- [ ] No PRD file is written for `goals` at `minimal`
- [ ] The `payments` PRD has the 11 sections in template order

---

### Case 7: Edge Case — Code roots unresolved

**Fixture:**
- The block prints `code_roots: unresolved — NOT CHECKED (set stack.layers.<layer>.root via /setup-stack)`
- `server/goals/` holds a working module

**Input:** `/reverse-document prd server/goals`

**Expected behavior:**
1. Prints `NOT CHECKED — no code root resolved (set stack.layers.<layer>.root via /setup-stack)` for the layer mapping
2. Analyzes the path as given and says in the draft that it lies outside every resolved root

**Assertions:**
- [ ] The skipped layer mapping announces itself
- [ ] The analysis still runs on the given path

---

### Case 8: Director Gate Check — No gate; reverse-document is a utility

**Fixture:**
- Any module with enough implementation

**Input:** `/reverse-document prd apps/api/src/goals`

**Expected behavior:**
1. Generates and, after approval, writes the document
2. No director agents are spawned; no gate IDs appear

**Assertions:**
- [ ] No director gate is invoked and no gate skip message appears
- [ ] Verdict is COMPLETE, or BLOCKED when the user declines the write

---

## Protocol Compliance

- [ ] Reads the implementation before generating any content
- [ ] Asks about intent before drafting; never presents inferred intent as confirmed
- [ ] Uses "May I write this to `<path>`?" before creating any output file, per the automation prelude
- [ ] Never overwrites an existing product brief without the explicit overwrite question
- [ ] Writes nothing under `production/session-logs/`; never writes `project.yaml`
- [ ] Ends with COMPLETE or BLOCKED and a follow-up list (NOT ASSESSED only from the Phase 3b stop, before anything is drafted); never auto-executes the follow-ups

---

## Category Rubric (`utility`)

- `utility U1` — the static checks above pass: bootstrap line and grant exact, `--keys` exact, plain follow-on line, automation prelude, "May I write" before each write, output paths exact
- `utility U2` — not applicable (no director gate)
- The NOT ASSESSED case is Case 3 (missing input: no implementation to infer from)

---

## Coverage Notes

- UI flows under a mobile or web root route to `prd-from-implementation.md` like Case 1; the screen spec itself
  belongs to `/ux-design` and is not generated here.
- The `guided`-mode path (present the diff and proceed for an existing file, except the brief) is not
  fixture-tested separately.
- Multi-path arguments are not part of the `<type> <path>` contract and are not tested.
