# Skill Spec: /bundle-audit

> **Category**: analysis
> **Priority**: low
> **Spec written**: 2026-09-28

## Skill Summary

`/bundle-audit` measures what the product makes users download and checks it
against the committed budget: initial JavaScript and render-blocking CSS per web
route (gzip, scored against `performance.bundle_kb`), images (format, dimensions,
loading, weight), web and app fonts including Korean/CJK subsetting strategy, and
mobile app download and install size from release builds. It also checks
static-asset naming and hygiene (the `naming.files` convention, platform naming
rules, orphaned, missing and duplicate assets). It runs the production build and
size tooling through Bash, briefs `performance-engineer` via `Agent` to rank the
recommendations, and writes one report,
`production/qa/perf/bundle-audit-YYYY-MM-DD.md`, whose verdict line uses
`PASS | CONCERNS | FAIL | NOT ASSESSED` (precedence
FAIL > CONCERNS > NOT ASSESSED > PASS). `performance.enforce` decides what a budget
breach means: `block` ⇒ FAIL, `warn` ⇒ CONCERNS, `off` ⇒ recorded but not scored. It is the optional Hardening
catalog step `bundle-audit`; `/perf-profile` reads its newest report for the
`performance.bundle_kb` row. It spawns no director gate.

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`); `name: bundle-audit` equals the skill directory, the catalog `name` and this spec's basename
- [ ] `description` is the one-line purpose "Per-route JS/CSS, images, fonts (CJK subsetting) and mobile app size against budgets; static-asset naming."
- [ ] Bootstrap: the first body line is `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,performance.enforce,surfaces,stack,code_roots` `` — exactly these five labels, comma-separated, no spaces
- [ ] `allowed-tools` grants `Bash(bash "*/.claude/skills/bundle-audit/../../hooks/yaml-helper.sh" resolve_config *)` with this skill's own directory name
- [ ] The line after the bootstrap block is exactly ``Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.`` (the plain variant — `review_mode` is not in the keys)
- [ ] The automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") follows that line verbatim
- [ ] `allowed-tools` is exactly: `Read, Glob, Grep, Write, Bash, Agent` plus the grant above — membership exact, order free; no `Edit`, no `AskUserQuestion`, no MCP tool names
- [ ] `model: sonnet`; no `disable-model-invocation` and no `isolation` flag
- [ ] 2+ phase headings found (Phase 0 configuration through the next-steps phase)
- [ ] Verdict keywords present exactly as defined: `PASS`, `CONCERNS`, `FAIL`, `NOT ASSESSED`, with the precedence **FAIL > CONCERNS > NOT ASSESSED > PASS**
- [ ] "May I write this to `production/qa/perf/bundle-audit-YYYY-MM-DD.md`?" appears before the report write
- [ ] Output at the exact path `production/qa/perf/bundle-audit-YYYY-MM-DD.md`; the report template carries `> **Verdict**: <TOKEN>` directly under its H1 and one blank line, and the skill re-reads the written file to confirm it
- [ ] Report headings present in the template: `## Scope`, `## Budgets`, `## Measurements`, `## Breaches`, `## Naming & Hygiene`, `## Ranked Recommendations`, `### Not Checked`
- [ ] `performance.bundle_kb`, `commands.build`, `platform.browsers` and `naming.files` are read from `project.yaml` with Read (they have no `resolve_config` label), each key spelled in full
- [ ] No `!` injection other than the bootstrap line; no `file:line` citations of other files
- [ ] Next-step section present at the end, naming current skills only (`/settings`, `/quick-spec`, `/create-stories`, `/sprint-plan`, `/architecture-decision`, `/design-language`, `/ui-inventory`, `/perf-profile`, `/bundle-audit`)

---

## Director Gate Checks

**N/A.** `/bundle-audit` spawns no director gate at any review mode, and `review_mode`
is not among its keys. Its one `Agent` call briefs `performance-engineer` as a
consultant with an inline return contract ("Do not write any file. Return only …");
the skill does not parse a `[GATE-ID]: TOKEN` line and the consultant's answer never
sets the verdict — the Phase 7 scoring table does (analysis AN4).

---

## Test Cases

### Case 1: Happy Path — Moa web routes inside the budget

**Fixture** (assumed project state):
- `project.yaml`: `platform.surfaces: [web, ios, android, api]`; `stack.layers.web.root: [apps/web, apps/admin]` (Next.js); `performance.enforce: warn`; `performance.bundle_kb: 170`; `commands.build: pnpm --filter web build`; `platform.browsers: [defaults, iOS >= 15]`; `naming.files: kebab-case`
- Production build of `apps/web` succeeds; routes `/`, `/onboarding`, `/goals`, `/goals/[id]` load 96–148 kB of initial JavaScript (gzip)
- Web font Pretendard is self-hosted as WOFF2 unicode-range slices with `font-display: swap`; images under `apps/web/public/` are AVIF/WebP with reserved dimensions
- No High hygiene finding; `design/inventory/media-manifest.md` exists

**Input**: `/bundle-audit surface:web`

**Expected behavior**:
1. Resolves config from the bootstrap block; announces the scope (`surface:web`); iOS and Android are listed as not audited because the argument names `web` only
2. Announces and runs `commands.build`, derives the routes from `apps/web/app/**/page.*`, measures initial JavaScript per route in gzip (Brotli transfer size beside it, never mixed in one column) and render-blocking CSS
3. Audits images and fonts, recording the unicode-range strategy for Pretendard
4. Briefs `performance-engineer` with the measurement tables inline; ranks its recommendations by saving ÷ effort
5. Scores every route within 170 kB → verdict `PASS`; asks "May I write this to `production/qa/perf/bundle-audit-YYYY-MM-DD.md`?" and writes after approval

**Assertions**:
- [ ] Every route row carries the measured gzip size and the method used; no size is estimated
- [ ] `## Budgets` names `performance.bundle_kb` with the value 170 read from `project.yaml`
- [ ] The report's first line after the H1 and one blank line is `> **Verdict**: PASS`
- [ ] `## Scope` lists the resolved `stack` and `code_roots` lines and "Consulted: performance-engineer"
- [ ] The summary printed after writing names the three largest routes against the budget

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure — route over budget under `performance.enforce: block`

**Fixture**:
- As Case 1, but `performance.enforce: block`
- `/goals` ships 212 kB of initial JavaScript (gzip): a date library with every locale bundled and a charting library pulled into the initial chunk

**Input**: `/bundle-audit surface:web`

**Expected behavior**:
1. Measures `/goals` at 212 kB against the 170 kB budget
2. Records the breach in `## Breaches` (over by 42 kB, scored as FAIL) and explains the largest modules and their cause
3. Verdict `FAIL`; states that `/gate-check` treats the breach as a blocker at the `hardening` and `launch` gates
4. Recommends lazy-loading the chart and a lighter date library with the expected saving and effort; does not change any dependency itself

**Assertions**:
- [ ] Verdict is `FAIL` and the breach row shows budget, measured value and the overage
- [ ] The recommendation carries an expected saving in kB marked `measured` or `estimated`, effort S/M/L and risk
- [ ] The skill edits no code, lockfile or dependency (it has no `Edit`; it writes only its report)
- [ ] The next steps offer `/quick-spec` or `/create-stories`, and `/architecture-decision` for a dependency swap

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: NOT ASSESSED — no build command, no budget, no code root

**Fixture**:
- `project.yaml` after `/start` only: no `stack.layers.*.root` (the bootstrap prints `code_roots: unresolved — NOT CHECKED (set stack.layers.<layer>.root via /setup-stack)`), no `commands.build`, no `performance.bundle_kb`
- No build output, no media manifest, no earlier `production/qa/perf/bundle-audit-*.md`
- `platform.surfaces` is unset as well (`/start` does not write it); whichever surfaces the user names, every family lacks its inputs

**Input**: `/bundle-audit`

**Expected behavior**:
1. Lists each input as `FOUND` or `ABSENT` before measuring anything
2. Finds every required input absent and stops with `NOT ASSESSED — NO DATA` as the whole verdict
3. Names what is missing and what produces it (`/setup-stack` for code roots and `commands.build`, `/settings performance.bundle_kb=<n>` for the budget)

**Assertions**:
- [ ] Verdict is `NOT ASSESSED` with the reason stated, never `PASS`
- [ ] No size, route or font number appears that was not measured
- [ ] The unresolved code roots line is printed (`NOT CHECKED — …`), not silently skipped
- [ ] Unset `performance.bundle_kb` is not replaced by a published or assumed threshold

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Mode Variant — the same breach under `warn`, `off` and a local override

**Fixture**:
- The Case 2 project (`/goals` at 212 kB, budget 170 kB)
- Run A: `performance.enforce: warn` in `project.yaml`
- Run B: `performance.enforce: off` in `project.yaml`
- Run C: `performance.enforce: warn` in `project.yaml` and `performance.enforce: block` in `project.local.yaml`

**Input**: `/bundle-audit surface:web` (three runs)

**Expected behavior**:
1. Run A: breach scored as CONCERNS → verdict `CONCERNS`
2. Run B: the breach is recorded in `## Breaches` but not scored; the header says `Budgets not scored — performance.enforce: off`; the verdict is computed without it
3. Run C: uses the resolved value (`block` from `project.local.yaml`) → verdict `FAIL`

**Assertions**:
- [ ] The enforcement value comes from the resolved `performance.enforce` line, never a direct read of `project.yaml`
- [ ] Under `off` the breach row stays in the report — it is not deleted
- [ ] The `> **Enforcement**:` header line names the value and its source in every run
- [ ] Verdicts differ from Case 2 only as the enforcement table states

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Edge Case — full Korean font, app size without a budget, unset surfaces

**Fixture**:
- `platform.surfaces` unset (the bootstrap prints `platform.surfaces: (unset -- ask which surfaces ship)`)
- `apps/web` preloads a full static Korean WOFF2 font (about 2 MB) on every route; `apps/admin` uses a static KS X 1001 subset for user-generated goal names
- `apps/mobile` (Expo) release builds exist; no `performance.*` key budgets app size and no NFR states a target
- `apps/mobile/assets/images/Goal Hero.PNG` has no reference in any code root

**Input**: `/bundle-audit full`

**Expected behavior**:
1. Asks in plain text which surfaces ship before auditing; unset is not "web only"
2. Rates the full font blocking first render as a High hygiene finding (verdict at least CONCERNS) and flags the static subset as unsafe for user-generated text
3. Reports app download and install size as informational; cites a store size threshold only with a retrieved source, else `NOT SOURCEABLE — <threshold>`
4. Lists the orphaned, uppercase, space-containing file for manual review and says how the orphan was checked

**Assertions**:
- [ ] Without an answer on surfaces, families outside the argument are `NOT ASSESSED — platform.surfaces unset`
- [ ] The font table records strategy (unicode-range, static subset or system stack) and whether it is preloaded
- [ ] App size is not scored against an invented budget
- [ ] No asset is deleted or renamed by the skill

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses "May I write this to `<path>`?" before the single report write; asks before overwriting a same-day report
- [ ] Presents findings (measurement tables, breaches, ranked recommendations) before requesting approval
- [ ] Ends with a recommended next step
- [ ] Does not auto-create files without user approval
- [ ] Writes no evidence, reports or plans under `production/session-logs/` (gitignored)
- [ ] Never writes `modes.review_mode` or any other knob that `modes.rigor` fronts
- [ ] analysis AN1 — the scan phases only read files and run read-only measurement commands (build, `gzip -9 -c`, `stat`, image and font inspectors, bundletool size queries); nothing is written before Phase 8
- [ ] analysis AN2 — findings are tables with a rating or scoring per row (`## Breaches`, `## Naming & Hygiene`)
- [ ] analysis AN3 — the report write is gated behind "May I write"; removal of orphans and dependency swaps are recommendations only
- [ ] analysis AN4 — no director gate; the consultant returns rankings, not a verdict
- [ ] Observation vs verdict: measurement cells hold observed values or `NOT ASSESSED — <reason>`; the verdict is derived only by the Phase 7 scoring table; every skipped family appears under `### Not Checked`

---

## Coverage Notes

- Exact byte counts depend on the build tooling of the pinned stack; the spec checks
  that sizes are measured, compressed with gzip for the budget row, and sourced, not
  the numbers themselves.
- The skill has no `AskUserQuestion`; its questions (unset surfaces, overwriting a
  same-day report) are plain-text prompts. A live run is needed to confirm it waits
  for the answer.
- iOS app thinning reports and `bundletool` output may be produced by the user and
  handed over; the spec only checks that the report records who produced them.
