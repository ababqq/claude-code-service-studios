# Skill Spec: /feature-audit

> **Category**: analysis
> **Priority**: low
> **Spec written**: 2026-09-28

## Skill Summary

`/feature-audit` compares what the product planned with what the code implements,
across seven families of planned items: PRD functional requirements (through their
`TR-<feature>-NNN` IDs and the stories that implement them), screens and routes (the
screen inventory and UX specs), API operations (the contract in `docs/api/`),
analytics events (the tracking plan), feature flags (PRD `## Configuration & Flags`),
notification templates (push, e-mail, SMS, 알림톡) and locales
(`localization.locales`). The planned set depends on the resolved `workflow` tier
(`full`: MVP, Beta and GA features; `standard`: MVP; `minimal`: the one-pager's
`## Build Order` and `## Core User Journey`), or on a `[feature-slug]` argument. It
searches only the resolved code roots, marks each planned item `IMPLEMENTED`,
`PARTIAL`, `MISSING` or `NOT CHECKED — <reason>`, lists unplanned implementation as
drift (not a gap), and writes `production/qa/feature-audit-YYYY-MM-DD.md` with the
verdict line `COMPLETE | GAPS | NOT ASSESSED` (precedence GAPS > NOT ASSESSED >
COMPLETE). `--summary` prints the summary and writes nothing. The written report
satisfies the Build → Hardening gate's "all MVP features implemented" item; the skill
is the optional Hardening catalog step `feature-audit` and spawns no agent or gate.

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`); `name: feature-audit` equals the skill directory, the catalog `name` and this spec's basename
- [ ] `description` is "Planned (PRD requirements, screens, endpoints, events, flags, notification templates, locales) versus implemented."
- [ ] Bootstrap: the first body line is `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys workflow,automation,code_roots` `` — exactly these three labels
- [ ] `allowed-tools` grants `Bash(bash "*/.claude/skills/feature-audit/../../hooks/yaml-helper.sh" resolve_config *)` with this skill's own directory name
- [ ] The line after the bootstrap block is exactly ``Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.`` (plain variant)
- [ ] The automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") follows that line verbatim
- [ ] `allowed-tools` is exactly: `Read, Glob, Grep, Write` plus the grant — membership exact, order free; no `Edit`, `Bash`, `Agent` or `AskUserQuestion`
- [ ] `model: sonnet`; no `disable-model-invocation` and no `isolation` flag
- [ ] 2+ phase headings found
- [ ] Verdict keywords present exactly: `COMPLETE`, `GAPS`, `NOT ASSESSED`, with precedence **GAPS > NOT ASSESSED > COMPLETE**; item statuses `IMPLEMENTED`, `PARTIAL`, `MISSING`, `NOT CHECKED`; feature statuses `DONE`, `IN PROGRESS`, `EARLY`, `NOT STARTED`
- [ ] "May I write this to `production/qa/feature-audit-YYYY-MM-DD.md`?" appears before the report write
- [ ] Output at that exact path; the report template has `> **Verdict**: <TOKEN>` directly under its H1 and one blank line, and the skill re-reads the file to confirm it
- [ ] The report template has `## Summary`, `## Coverage by Feature`, `## HIGH PRIORITY Gaps`, `## Per-Feature Breakdown`, `## Unplanned Implementation`, `## Not Checked`, `## Recommendation`
- [ ] The feature map is read by its exact column header `| Feature | Category | Layer | Tier | Status | PRD | Depends On |`; PRD sections are located with the tolerant heading form (optional numeric prefix, case-insensitive)
- [ ] `localization.locales` and `testing.patterns` are read from `project.yaml` with Read (no `resolve_config` label); with `testing.patterns` unset, contract tests are looked for under `tests/contract/` and the report states `testing.patterns unset — using the tests/** convention`
- [ ] No `!` injection other than the bootstrap line; no `file:line` citations of other files
- [ ] Next-step section present at the end, naming current skills only (`/create-stories`, `/quick-spec`, `/create-epics`, `/sprint-plan`, `/api-design update <resource>`, `/write-prd`, `/localize`, `/feature-audit`, `/gate-check hardening`)

---

## Director Gate Checks

**N/A.** `/feature-audit` spawns no director gate and no agent (it has no `Agent`
tool), and `review_mode` is not among its keys. `/gate-check hardening` reads its
written report; the audit itself never decides the gate (analysis AN4).

---

## Test Cases

### Case 1: Happy Path — every MVP item implemented at `standard`

**Fixture** (assumed project state):
- `modes.workflow` resolves to `standard`; code roots `web=apps/web`, `mobile=apps/mobile`, `backend=apps/api`, `shared=packages`
- `design/product/feature-map.md` lists MVP features `auth`, `onboarding`, `goals`; `payments` is `GA`
- For each MVP PRD: every `TR-` ID in `docs/architecture/tr-registry.yaml` has a `done` story in `production/sprint-status.yaml`; every screen in `design/inventory/screen-inventory.md` has a route file on each listed surface; every contract operation has a handler and a contract test under `tests/contract/`; every tracking-plan event is emitted; the flag `goals.v2-progress-ring` is evaluated; the 알림톡 template key is referenced; `localization.locales: [ko, en]` with key parity

**Input**: `/feature-audit`

**Expected behavior**:
1. Resolves the tier; announces the planned set = MVP features
2. Builds the planned set per family (denominator: Glob `design/prd/*.md`), then scans only the resolved roots with the extensions the `code_roots` line lists
3. Marks every item `IMPLEMENTED`; `payments` is out of scope at `standard`
4. Verdict `COMPLETE`; asks "May I write this to `production/qa/feature-audit-YYYY-MM-DD.md`?" and writes after approval

**Assertions**:
- [ ] `## Coverage by Feature` shows per-family counts (`implemented/planned`) for each MVP feature
- [ ] The report states once that a code search shows something was built, not that it behaves as specified, pointing to `/smoke-check`, `/team-qa` and `/regression-suite`
- [ ] The verdict line reads `> **Verdict**: COMPLETE`
- [ ] 알림톡 templates are marked `approval: not verifiable here` rather than approved

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure — contract test missing, event never emitted, MVP feature not started

**Fixture**:
- As Case 1, but `POST /v1/goals/{goalId}/deposits` (`createDeposit`) has a handler in `apps/api` and no contract test
- The tracking-plan event `goal_deposit_completed` (Owner PRD `design/prd/goals.md`) is emitted nowhere
- The feature map also lists `notifications` as MVP; none of its stories is `done` and no code references its templates
- `apps/api` serves `GET /v1/goals/export`, which is not in `docs/api/openapi.yaml`

**Input**: `/feature-audit`

**Expected behavior**:
1. Marks `createDeposit` `PARTIAL` (handler alone), the event `MISSING`, and `notifications` `NOT STARTED`
2. Flags `notifications` HIGH PRIORITY (MVP tier)
3. Lists `GET /v1/goals/export` under `## Unplanned Implementation` as contract drift, not as a gap
4. Verdict `GAPS`; recommends `/create-stories`, `/api-design update goals`, `/write-prd goals`

**Assertions**:
- [ ] Verdict is `GAPS`
- [ ] The `## Per-Feature Breakdown` row for `createDeposit` names the evidence looked for
- [ ] Drift is listed separately and does not change the verdict
- [ ] The skill changes no plan and no code

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: NOT ASSESSED — code roots unresolved

**Fixture**:
- Feature map and MVP PRDs exist
- `project.yaml` declares no `stack.layers.*.root`; the bootstrap prints `code_roots: unresolved — NOT CHECKED (set stack.layers.<layer>.root via /setup-stack)`

**Input**: `/feature-audit`

**Expected behavior**:
1. Still builds the planned set (useful on its own)
2. Marks every implementation family `NOT CHECKED — no code root resolved (set stack.layers.<layer>.root via /setup-stack)`
3. Verdict `NOT ASSESSED`, never `GAPS` computed from zero hits and never a percentage from nothing

**Assertions**:
- [ ] Verdict is `NOT ASSESSED` with the reason in `## Not Checked`
- [ ] No item is marked `MISSING` because a search had nowhere to look
- [ ] No completion percentage is presented for the unscanned families

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Mode Variant — `minimal` tier, `full` tier and `--summary`

**Fixture**:
- Run A: `modes.workflow` resolves to `minimal`; no PRDs; `design/product/one-pager.md` has `## Build Order` and `## Core User Journey`
- Run B: `modes.workflow` resolves to `full`; the feature map has MVP, Beta, GA and Later features
- Run C: the Case 1 project with `--summary`

**Input**: `/feature-audit` (Runs A, B), `/feature-audit --summary` (Run C)

**Expected behavior**:
1. Run A: the planned set is the one-pager's Build Order items and journey steps; families with no plan behind them are `NOT CHECKED — no plan at minimal workflow`
2. Run B: MVP, Beta and GA features are audited; Later features are listed as not scored
3. Run C: prints the Summary and Coverage by Feature tables, writes nothing, and ends with "Run `/feature-audit` without `--summary` to write the report — the Build → Hardening gate reads the written report, not this summary."

**Assertions**:
- [ ] The planned set follows the resolved tier, not an assumed one
- [ ] Run C writes no file and asks no "May I write"
- [ ] Run A treats `none planned` and `NOT CHECKED` as different states

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Edge Case — unknown feature slug, PRD with no countable plan, unset locales

**Fixture**:
- `design/prd/share-goal.md` does not exist
- `design/prd/admin-console.md` has no `Functional Requirements`, `Configuration & Flags`, `Success Metrics & Instrumentation` or `Acceptance Criteria` heading
- `localization.locales` is unset; `docs/architecture/tr-registry.yaml` is absent

**Input**: `/feature-audit share-goal` (Run A), `/feature-audit` (Run B)

**Expected behavior**:
1. Run A: stops with `NOT ASSESSED — no PRD for share-goal (run /write-prd share-goal)`
2. Run B: lists `admin-console.md` under `### Unplanned or Unspecified` instead of scoring it complete; locales are `NOT CHECKED — localization.locales unset (set it via /setup-stack or /localize)`; requirements are matched by PRD with the note `TR registry absent — requirements matched by PRD, not by ID`

**Assertions**:
- [ ] Run A writes no report and names the producing skill
- [ ] A PRD without countable requirements is never counted as `DONE`
- [ ] Unset locales are not read as "no locales planned"

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses "May I write this to `<path>`?" before the report write; asks before overwriting today's report
- [ ] Presents the coverage table and HIGH PRIORITY gaps before requesting approval
- [ ] Ends with a recommended next step
- [ ] Does not auto-create files without user approval
- [ ] Writes no evidence, reports or plans under `production/session-logs/` (gitignored)
- [ ] Never writes `modes.review_mode` or any other knob that `modes.rigor` fronts
- [ ] analysis AN1 — Phases 0–3 only read (Read, Glob, Grep); nothing is written before Phase 4
- [ ] analysis AN2 — findings are tables per feature and per family, with HIGH PRIORITY flags
- [ ] analysis AN3 — the report is the only write, gated behind "May I write"; `--summary` writes nothing
- [ ] analysis AN4 — no director gate and no agent
- [ ] Observation vs verdict: each item's status is an observation with the evidence looked for; percentages exclude `NOT CHECKED` families, which are listed; the verdict follows the three stated rules only

---

## Coverage Notes

- Behaviour correctness is out of scope by design — the skill proves presence in code,
  not function; the spec checks that the report says so.
- Framework-specific route and screen conventions (Next.js `app/**/page.*`, Expo
  Router, SwiftUI, Compose) are listed in the skill; a live run is needed to confirm the
  searches find them on a real tree.
- The GAPS > NOT ASSESSED precedence differs from the PASS-family skills on purpose: a
  known gap is more actionable than an unknown.
