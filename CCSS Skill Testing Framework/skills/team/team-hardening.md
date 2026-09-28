# Skill Spec: /team-hardening

> **Category**: team
> **Priority**: medium
> **Spec written**: 2026-09-28

## Skill Summary

Orchestrates a hardening pass for a feature, an area, a release or the whole product and
produces **one** report, `production/qa/hardening-YYYY-MM-DD.md`, with exactly seven
sections — `## Performance`, `## Reliability`, `## Security (quick)`, `## Accessibility`,
`## UI Consistency`, `## Regression`, `## Blockers` — and the verdict
`READY | READY WITH CONDITIONS | NOT READY | NOT ASSESSED`. Phase 1 reads the shared
inputs once and records each as FOUND or ABSENT; Phase 2 fans out in parallel
(`performance-engineer` ∥ `sre-engineer` ∥ `security-engineer` ∥
`accessibility-specialist`, plus `design-engineer` and the stack leads at `studio`), each
returning a section body — no agent writes a file; Phase 3 offers remediation per
Blocker; Phase 4 has `qa-engineer` run regression and return bug drafts; Phase 5 runs an
adversarial review at `studio` and `review_mode: full`; Phase 6 applies the verdict
precedence `NOT READY > NOT ASSESSED > READY WITH CONDITIONS > READY` and writes the
report; Phase 7 hands off. `performance.enforce` scores budget breaches,
`accessibility.target` sets the audit level, the resolved `platform.surfaces` line decides
whether the UI sections apply (unset ⇒ ask), and the `stack` line names the `studio` stack
leads (an `unset=` layer gets a NOT CHECKED line). No director gate runs at any review mode.

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`); `name` is `team-hardening`, equal to the directory `.claude/skills/team-hardening/` and the catalog `name`
- [ ] Bootstrap: the first body line is `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,team.size,performance.enforce,accessibility,surfaces,stack` `` and `allowed-tools` grants `Bash(bash "*/.claude/skills/team-hardening/../../hooks/yaml-helper.sh" resolve_config *)`
- [ ] `--keys` is exactly `review_mode,automation,team.size,performance.enforce,accessibility,surfaces,stack`
- [ ] The line after the bootstrap block is exactly: ``Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] Automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") present verbatim right after that line
- [ ] `allowed-tools` is exactly: `Read, Glob, Grep, Write, Edit, Bash, Agent, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskUpdate` plus the bootstrap grant
- [ ] 2+ phase headings found (`## Phase 0: Resolve Config`, `### Phase 1: Scope and Inputs` … `### Phase 7: Sign-off and Next Steps`)
- [ ] Verdict keywords present, exactly: `READY`, `READY WITH CONDITIONS`, `NOT READY`, `NOT ASSESSED`; section status values `OK | CONDITIONS | BLOCKERS | NOT ASSESSED — <reason> | N/A — <reason>`
- [ ] "May I write this to `production/qa/hardening-YYYY-MM-DD.md`?" appears before the report write, and "May I write these to `production/qa/bugs/BUG-NNNN.md` … `BUG-NNNN.md`?" before any bug report write
- [ ] Output at the exact path `production/qa/hardening-YYYY-MM-DD.md` (single file; per-agent notes live inside it) with `> **Verdict**: [READY | READY WITH CONDITIONS | NOT READY | NOT ASSESSED]` directly under its H1 `# Hardening Report: [scope]`, and the seven `##` sections in the order above
- [ ] New defects use `production/qa/bugs/BUG-NNNN.md` (four digits) with the exact ladder strings `**Severity**: [S1-Critical / S2-Major / S3-Minor / S4-Trivial]` and `**Priority**: [P1-Fix this sprint / P2-Fix soon / P3-Backlog / P4-Won't fix]`
- [ ] Contains verbatim: "Team skills spawn only the gates `.claude/docs/director-gates.md` § Gate Index lists this skill under (Spawned by column), after the review-mode check (lean suffix rule); team-size scoping never removes a director gate."
- [ ] States that for `/team-hardening` that column is empty — no director gate runs at any review mode — and that `review_mode` decides only whether the adversarial review pass runs (`full` → it runs; `lean` or `solo` → `Adversarial review skipped — <Mode> mode`)
- [ ] Active set per `team.size` is given as a table (`individual`: `performance-engineer`; `small`: `performance-engineer` ∥ `sre-engineer` ∥ `security-engineer` ∥ `accessibility-specialist` → `qa-engineer`; `studio`: + `design-engineer`, routed stack leads, adversarial review) and announced before Phase 1; the same line goes into the report header
- [ ] Without an argument, outputs "Usage: `/team-hardening [feature, area or release]` — …" directly (no `AskUserQuestion`) and exits without spawning agents
- [ ] Has an Error Recovery Protocol section (a report path that is not on disk after the write is a failed phase) and a File Write Protocol section
- [ ] No `!` injection other than the bootstrap line; no `file:line` citations of other files
- [ ] Phase 7 next steps name current skills (`/release-checklist <version>`, `/rollout-plan <version>`, `/launch-checklist <version>`, `/gate-check launch`, `/bug-report`, `/dev-story <story>`, `/scope-check`, `/perf-profile`, `/bundle-audit`, `/load-test`, `/security-audit full`, `/security-audit quick`, `/ux-design accessibility`, `/ux-review`, `/create-architecture`, `/incident runbook <alert-slug>`, `/test-setup`, `/smoke-check`)

---

## Director Gate Checks

- **Full mode**: no gate spawns; at `studio` the adversarial review pass (a fresh `qa-engineer`) runs
- **Lean mode**: no gate spawns; the adversarial review is skipped — `Adversarial review skipped — Lean mode`
- **Solo mode**: no gate spawns; `Adversarial review skipped — Solo mode`
- **Review-mode exempt**: not applicable
- **N/A**: the skill's gate list is empty; the Hardening → Launch gate of `/gate-check` reads this report's verdict line (READY or READY WITH CONDITIONS)

---

## Test Cases

Quoted prompts, option labels and verdict tokens below are the canonical English text
of `SKILL.md`; at run time the model renders them in the user's conversation language.

### Case 1: Happy Path — Moa 1.0.0 hardening, READY WITH CONDITIONS

**Fixture** (assumed project state):
- `docs/ops/slo.md` names the critical journeys (sign-in with Kakao, create goal, auto-debit deposit) with SLOs, alerts and an on-call rota; each paging alert has a runbook under `docs/ops/runbooks/`
- `project.yaml` sets `performance.api_p95_ms: 300`, `performance.lcp_ms: 2500`, `performance.crash_free_pct: 99.5`
- Current reports exist for the build under test: `production/qa/perf/perf-profile-api-2026-12-01.md`, `production/qa/load/load-test-load-2026-12-01.md`, `production/security/security-audit-quick-2026-12-02.md`, `production/qa/smoke-2026-12-02.md` (PASS)
- `design/accessibility-requirements.md` exists; one unresolved `S2-Major` bug
- Resolved block: `team.size: small`, `review_mode: lean`, `performance.enforce: warn (default)`, `accessibility.target: wcag-aa (project.yaml)`, `platform.surfaces: web, ios, android, api (project.yaml)`, `stack: web=Next.js 15.3 @apps/web; mobile=React Native (Expo) 0.79 @apps/mobile; backend=NestJS 11.0 @apps/api; unset=data,cloud [routing: web-specialist>nextjs-specialist, mobile-specialist>react-native-specialist, backend-specialist>node-specialist] (project.yaml)`

**Input:** `/team-hardening release 1.0.0`

**Expected behavior:**
1. Phase 0 announces the `small` active set; `design-engineer` and the stack leads are named as not spawned, with UI Consistency covered by `qa-engineer` through the visual-regression suite
2. Phase 1 records every input FOUND or ABSENT with its date; one task per section is created; `AskUserQuestion`: `Proceed with this scope and active set`
3. Phase 2 spawns the four agents in one message; each returns a section body with `**Status**`, a findings table with Class (Blocker / Condition / Note) and evidence, `Evidence used:` and `Not checked:`
4. The classification is presented; `AskUserQuestion`: `Accept the Blocker / Condition classification`
5. Phase 4: `qa-engineer` runs `commands.test` and `commands.e2e`, confirms every critical journey has a passing E2E test and the smoke report covers this build; the unresolved S2 bug is a Condition
6. Phase 5: `Adversarial review not run — team.size small`
7. Phase 6: verdict READY WITH CONDITIONS; report written after "May I write this to `production/qa/hardening-2026-12-03.md`?"; the file is re-read to confirm the verdict line and all seven sections
8. Phase 7 recommends `/release-checklist 1.0.0`

**Assertions:**
- [ ] The active set is announced before any spawn and repeated in the report header
- [ ] Phase 2 agents are spawned in parallel, and all return before Phase 3
- [ ] No agent writes a file; every section lives in the single report
- [ ] Every Condition has an owner and a due date
- [ ] The verdict follows the precedence and is READY WITH CONDITIONS here
- [ ] The written report is verified on disk (verdict line under the H1, seven sections)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — Blockers keep the verdict at NOT READY

**Fixture:**
- As Case 1, but the auto-debit failure alert pages on-call with no runbook in `docs/ops/runbooks/`, and the security quick audit lists an open High finding (session tokens not rotated after password change)

**Input:** `/team-hardening release 1.0.0`

**Expected behavior:**
1. `sre-engineer` classes the missing runbook as a Blocker; `security-engineer` classes the open High finding as a Blocker and states the section is not an audit record
2. Phase 3 asks per Blocker: `Fix now` / `File a bug` / `Accept as a condition` / `Descope`
3. The user files a bug for the token finding and does nothing for the runbook
4. Phase 6: verdict **NOT READY**; `## Blockers` lists both with owner and resolution path
5. Phase 7 offers `/bug-report` or `/dev-story <story>` then a rerun, and `/scope-check`

**Assertions:**
- [ ] A paging alert without a runbook and an open Critical or High security finding are Blockers
- [ ] "Launch with an unresolved Blocker" is not an option: an unfixed, unreclassified Blocker keeps NOT READY
- [ ] A `Fix now` change is applied only after the user approves that exact change set, and is re-verified in Phase 4
- [ ] Reclassifying a Blocker as a Condition requires the user's explicit choice with an owner and due date

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: NOT ASSESSED — Unset accessibility target and missing SLO document

**Fixture:**
- `docs/ops/slo.md` does NOT exist
- Resolved block prints `accessibility.target: (unset -- ask; unset is not none)`; the user gives no answer
- Resolved block prints `platform.surfaces: web, ios, api (project.yaml)` (UI surfaces ship, so `## Accessibility` is in scope)
- `performance.lcp_ms` is not set in `project.yaml`; `commands.e2e` is not set
- No Blocker anywhere

**Input:** `/team-hardening goals`

**Expected behavior:**
1. `## Reliability` is `NOT ASSESSED` (no SLO document), redirecting to `/create-architecture`
2. `## Accessibility` is `NOT ASSESSED — accessibility.target unset`
3. `## Performance` records `NOT ASSESSED — performance.lcp_ms (unset)` for that budget — never a pass
4. `## Regression` records `NOT ASSESSED — commands.test / commands.e2e unset (run /test-setup)` for the missing command
5. Verdict: **NOT ASSESSED** (no Blocker, but in-scope sections were not assessed)
6. Phase 7 lists what to run: `/create-architecture`, `/ux-design accessibility`, `/test-setup`

**Assertions:**
- [ ] Unset `accessibility.target` is asked about and, unanswered, yields NOT ASSESSED — never treated as `none`
- [ ] An unset budget or a missing measurement is NOT ASSESSED, never a pass
- [ ] The overall verdict is NOT ASSESSED, not READY
- [ ] A `Not checked` item becomes a Condition only when the user explicitly accepts it in Phase 2

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Mode Variant — `team.size` individual versus studio with full review

**Fixture:**
- Same inputs as Case 1
- Variant A: `team.size: individual`
- Variant B: `team.size: studio`, `review_mode: full`; `project.yaml` configures web, mobile and backend layers but no data or cloud layer — the block's `stack` line is Case 1's (`unset=data,cloud`, routing `web-specialist>nextjs-specialist, mobile-specialist>react-native-specialist, backend-specialist>node-specialist`)

**Input:** `/team-hardening release 1.0.0`

**Expected behavior (variant A):**
1. `performance-engineer` is spawned once with every section's brief; sections outside its domain carry `covered by performance-engineer — <specialist> not spawned at team.size individual`; judgment checks (manual screen-reader pass, design-language review) go under `Not checked` with the specialist named

**Expected behavior (variant B):**
1. `design-engineer` writes `## UI Consistency` against `design/brand/design-language.md` and the pattern library, reusing the UX review records in `design/ux/reviews/`
2. `web-specialist`, `mobile-specialist` and `backend-specialist` add layer notes tagged by layer; data and cloud get `NOT CHECKED — <layer> layer not configured (run /setup-stack)`
3. Phase 5 spawns a fresh `qa-engineer` briefed to "Try to falsify READY."; accepted challenges become Blockers or Conditions

**Assertions:**
- [ ] At `individual` the routed coverage is stated per section, never silent
- [ ] At `studio` each unconfigured layer prints its NOT CHECKED line
- [ ] The adversarial review runs only at `studio` with `review_mode: full`
- [ ] No director gate is spawned in any variant

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Edge Case — Enforcement modes, `accessibility.target: none`, stale evidence

**Fixture:**
- `performance.api_p95_ms: 300`; the newest measurement is 340 ms
- Variant A: `performance.enforce: block`; Variant B: `warn`; Variant C: `off`
- `accessibility.target: none (project.yaml)`
- `production/qa/perf/perf-profile-api-2026-10-02.md` predates the release candidate
- A hardening report for today already exists

**Input:** `/team-hardening release 1.0.0`

**Expected behavior:**
1. The p95 breach is a Blocker (A), a Condition (B), or recorded and not scored with `Budgets not scored — performance.enforce: off` (C)
2. `## Accessibility` is `N/A — accessibility.target: none`, naming any regional standards listed in `design/accessibility-requirements.md`
3. The stale perf profile is cited as stale; `performance-engineer` re-measures the rows the verdict depends on (staging or local, never production load)
4. Before writing, the skill asks before replacing today's report

**Assertions:**
- [ ] `performance.enforce` is taken from the resolved line and classes breaches accordingly
- [ ] `none` yields N/A, which does not count toward the verdict
- [ ] Stale artifacts are labelled stale and re-measured where the verdict depends on them
- [ ] An existing report for today is replaced only after asking

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Usage — No argument

**Fixture:**
- Any project state

**Input:** `/team-hardening` (no argument)

**Expected behavior:**
1. Outputs "Usage: `/team-hardening [feature, area or release]` — e.g. `goals`, `payments`, `release 1.0.0`, or `all` for the whole product." directly, without `AskUserQuestion`
2. Exits without spawning agents

**Assertions:**
- [ ] No agent is spawned and no report is written
- [ ] The usage text gives the argument forms with examples
- [ ] No verdict is emitted

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: Bug drafts from regression

**Fixture:**
- `production/qa/bugs/` holds `BUG-0001.md` … `BUG-0014.md`
- Phase 4 exploratory testing finds two defects: backgrounding the app mid-deposit loses the confirmation state (S2-Major); the goal list shows yesterday's date just after midnight Asia/Seoul (S3-Minor)

**Input:** continuation of `/team-hardening release 1.0.0`

**Expected behavior:**
1. `qa-engineer` returns two bug drafts (title, severity and priority from the ladders, `**Status**: Open`, environment and build, steps, expected and actual, evidence)
2. The orchestrator offers `Write the bug reports` / `Hand them to /bug-report` / `Skip`
3. Writing numbers them `BUG-0015` and `BUG-0016` and asks "May I write these to `production/qa/bugs/BUG-0015.md` … `BUG-0016.md`?"

**Assertions:**
- [ ] Bug numbers continue from the highest existing four-digit number
- [ ] Drafts are written only after the combined "May I write" approval
- [ ] The unresolved S2 is a Condition that must close before launch; an unresolved S1 would be a Blocker

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses "May I write this to `<path>`?" before the report and before bug reports
- [ ] Presents the scope, the active set and the classification before requesting approval
- [ ] Ends with verdict-specific next steps
- [ ] Does not auto-create files without user approval; subagents return content and write no notes files
- [ ] Any BLOCKED agent is surfaced immediately; its section becomes `NOT ASSESSED — <agent> blocked: <reason>` and a partial report is produced
- [ ] Nothing is deployed and no production load is generated by this skill
- [ ] Writes no evidence, reports or plans under `production/session-logs/` (gitignored)
- [ ] Never writes `modes.review_mode` or any other knob that `modes.rigor` fronts

---

## Coverage Notes

- `all` scope (every MVP-tier feature in `design/product/feature-map.md`) follows the same
  pipeline as a release scope.
- Mobile-specific checks (cold start and crash-free sessions from the beta or store test
  build; Xcode Accessibility Inspector and Android Accessibility Scanner) are asserted by
  the skill text and covered implicitly by Case 1.
- The `TaskList` check before Phase 6 (a section still open is
  `NOT ASSESSED — <agent> did not return`) is covered by the Error Recovery Protocol
  assertion rather than a dedicated fixture.
