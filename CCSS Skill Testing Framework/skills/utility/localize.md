# Skill Test Spec: /localize

## Skill Summary

`/localize` runs the internationalization pipeline of a web, mobile and API product.
Modes: `scan` (hardcoded strings and i18n anti-patterns, including CJK ones — read-only),
`extract` (new keys for the source-locale message catalogs), `validate` (completeness,
placeholders, ICU plural/select forms, length limits, store listing fields — read-only),
`status` (coverage matrix — read-only), `brief` (translator brief), `cultural-review`,
`rtl-check`, `freeze` (string freeze) and `qa` (localization QA before a locale ships).

Every mode starts from three inputs: the locales in `localization.locales` (read from
`project.yaml` — unset means ask, never "one locale"), the resolved `code_roots` line
(unresolved ⇒ `NOT CHECKED — no code root resolved (set stack.layers.<layer>.root via /setup-stack)`
and no code scan), and the message catalogs the configured surfaces use (next-intl /
FormatJS / i18next JSON, iOS String Catalogs, Android `strings.xml`, Flutter ARB, backend
bundles for email, push and 알림톡 text).

Outputs: records under `production/localization/` (translator brief, cultural review,
RTL check, `freeze-status.md`), the source-locale catalog diff written by `extract`, and
— in `qa` mode — `production/qa/localization-qa-YYYY-MM-DD.md` with the verdict line
directly under its H1. Verdicts: `extract` ends **COMPLETE**; `status` without a catalog
is **NOT ASSESSED — no message catalog found**; `qa` returns **PASS / PASS WITH
CONDITIONS / FAIL / NOT ASSESSED** per locale and overall (worst locale wins, ranked
FAIL > NOT ASSESSED > PASS WITH CONDITIONS > PASS); no subcommand is **FAIL — missing
required subcommand**. The skill spawns `localization-lead` and `ux-writer` as
specialists; no director gates apply.

---

## Static Assertions (Structural)

Verified automatically by `/skill-test static` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] `name: localize` equals the directory `.claude/skills/localize/` and the catalog entry name
- [ ] First body line is exactly `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,surfaces,compliance,code_roots,stack` `` — `--keys` is exactly `automation,surfaces,compliance,code_roots,stack`
- [ ] `allowed-tools` grants `Bash(bash "*/.claude/skills/localize/../../hooks/yaml-helper.sh" resolve_config *)` (this skill's own directory)
- [ ] The line after the bootstrap block is exactly ``Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] The automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") follows that line verbatim
- [ ] `allowed-tools` is exactly `Read, Glob, Grep, Write, Agent, AskUserQuestion` plus the bootstrap grant — no `Edit`, and no plain `Bash` (no mode runs a shell command)
- [ ] `argument-hint` lists `scan|extract|validate|status|brief|cultural-review|rtl-check|freeze|qa` and no voice-over mode
- [ ] Has ≥2 phase headings (`## Phase 1: Inputs`, the `## Phase 2x` modes, `## Phase 3: Rules and Next Steps`)
- [ ] Contains verdict keywords COMPLETE, PASS, PASS WITH CONDITIONS, FAIL and NOT ASSESSED
- [ ] Contains "May I write" before every write: the catalog diff, `production/localization/translator-brief-[locale]-[date].md`, `production/localization/cultural-review-[date].md`, `production/localization/rtl-check-[date].md`, `production/localization/freeze-status.md`, and "May I write this localization QA report to `production/qa/localization-qa-YYYY-MM-DD.md`?"
- [ ] Outputs at the exact paths `production/localization/…` (translator brief, cultural review, RTL check, `freeze-status.md`) and `production/qa/localization-qa-YYYY-MM-DD.md` (`qa` mode); the only other write is the `extract` diff into a source-locale catalog under a resolved code root
- [ ] The QA report template carries `> **Verdict**: [PASS / PASS WITH CONDITIONS / FAIL / NOT ASSESSED]` directly under its H1
- [ ] No output path under `production/session-logs/`; no `!` injection other than the bootstrap line; no `file:line` citation of another file
- [ ] Has a next-step handoff naming current skills (`/gate-check launch`, `/team-content <area>`)

---

## Director Gate Checks

None. `/localize` is a pipeline utility. It spawns `localization-lead` (cultural review,
QA) and `ux-writer` (source wording, translator tone) as specialists — they are not
director gates, and `review_mode` is not among its keys.

---

## Test Cases

### Case 1: Scan — Hardcoded strings and CJK anti-patterns, read-only

**Fixture:**
- Canonical product Moa; `project.yaml` has `localization.locales: [ko-KR, en-US]` and `stack.layers.web.root: [apps/web, apps/admin]`
- `apps/web/app/goals/new/page.tsx` renders `"저장했어요!"` as a literal and builds `` `${goalName}을 만들었어요` `` by concatenation; the submit handler ignores IME composition

**Input:** `/localize scan`

**Expected behavior:**
1. Skill takes the roots from the resolved `code_roots` line and scans them (and prints the `WARN: undeclared code roots: …` line when the label reports any)
2. Skill reports the literal outside a localization function, the concatenated message, the Korean particle hardcoded after a variable, and the Enter-to-submit handler that ignores `isComposing`
3. Each finding carries its file path and line number
4. No file is written

**Assertions:**
- [ ] Findings include the CJK anti-patterns because a CJK locale is configured
- [ ] Positional placeholders and concatenation are reported as needing one parameterized ICU message
- [ ] No write tool is called in scan mode

---

### Case 2: Extract — Diff into the source-locale catalog, ux-writer for engineer-written text

**Fixture:**
- Source locale confirmed as `ko-KR`; catalog `apps/web/messages/ko-KR.json` exists
- The code references three keys not yet in the catalog; one of them has text an engineer wrote, with no approved copy deck under `design/content/`
- `production/localization/freeze-status.md` does not exist

**Input:** `/localize extract`

**Expected behavior:**
1. Skill proposes keys in the form `<feature>.<screen-or-context>.<element>` (e.g. `goals.create.submit_button`), each with a translator `context` (where it appears, max length, placeholder meaning)
2. Skill spawns `ux-writer` for the engineer-written key; the agent returns wording and context inline and writes no file
3. Skill shows the diff and asks "May I write these new entries to `apps/web/messages/ko-KR.json`?" — one question per catalog
4. Only the new entries are written; existing keys keep their values and order; verdict is COMPLETE

**Assertions:**
- [ ] Keys are namespaced by meaning, never by position
- [ ] Every new entry has a `context` with placeholder meaning (`{goalName}` = the goal name the user chose)
- [ ] The write is a diff, not a full replacement of the catalog
- [ ] Verdict is COMPLETE after the approved write

---

### Case 3: NOT ASSESSED — No message catalog found

**Fixture:**
- `localization.locales: [ko-KR, en-US]`; the web root resolves, but no `messages/`, `locales/`, `i18n/`, `*.xcstrings`, `strings.xml` or `*.arb` catalog exists under any code root

**Input:** `/localize status`

**Expected behavior:**
1. Skill looks for catalogs by the formats the resolved `surfaces` need and finds none
2. The whole status output is `NOT ASSESSED — no message catalog found`
3. No coverage matrix is printed

**Assertions:**
- [ ] Verdict is NOT ASSESSED with the reason stated
- [ ] No matrix of zeros and no pre-filled `100%` source-locale row appears
- [ ] Each surface without a catalog is named
- [ ] No file is written (status is read-only)

---

### Case 4: Validate — Missing keys, placeholders, plurals and store limits

**Fixture:**
- `apps/web/messages/en-US.json` lacks four keys that exist in `ko-KR.json`; one English string drops `{amount}`; one plural message defines only `other` for `en`
- `platform.surfaces: [web, ios, android]`

**Input:** `/localize validate`

**Expected behavior:**
1. Skill reads every catalog found in Phase 1
2. Skill reports the four missing keys by name for `en-US`, the placeholder mismatch, and the missing `one` plural category that `en` needs (`ko` needs `other` only)
3. Skill checks each locale's App Store and Google Play listing text against the store field limits for the `ios` and `android` surfaces
4. Results are grouped by locale and severity; no file is written

**Assertions:**
- [ ] Missing keys are listed explicitly and attributed to their locale
- [ ] CLDR plural categories are checked per locale, not one rule for all
- [ ] Missing translations are never filled from the source language
- [ ] No write tool is called in validate mode

---

### Case 5: QA — Report under `production/qa/`, worst locale decides

**Fixture:**
- `localization.locales: [ko-KR, en-US]`; the translations are delivered; `en-US` has a BLOCKING overflow on the auto-debit confirmation button; no iOS build exists for the `en-US` pass
- `compliance.regions: [kr]`

**Input:** `/localize qa`

**Expected behavior:**
1. Skill spawns `localization-lead` with the locales, the screens in scope (UX specs under `design/ux/` or `design/inventory/screen-inventory.md`), the latest validate report, the cultural review, and the resolved `compliance` and `surfaces` lines
2. Skill writes one `## Localization QA Verdict — [Locale]` block per locale; the iOS pass for `en-US` could not run and is NOT ASSESSED with its reason
3. The overall verdict is the worst locale verdict by FAIL > NOT ASSESSED > PASS WITH CONDITIONS > PASS
4. Skill asks "May I write this localization QA report to `production/qa/localization-qa-YYYY-MM-DD.md`?"

**Assertions:**
- [ ] The report path is `production/qa/localization-qa-YYYY-MM-DD.md` — not under `production/localization/` and never under `production/session-logs/`
- [ ] `> **Verdict**:` sits directly under the H1
- [ ] A locale whose checks could not run is NOT ASSESSED, never PASS
- [ ] The report lands where `/gate-check launch` looks for it when two or more locales ship (`production/qa/localization-qa-*.md`, the catalog `localize-qa` glob)

---

### Case 6: Mode Variant — Missing subcommand and unset locales

**Fixture:**
- `localization.locales` is absent from `project.yaml`

**Input:** `/localize` (no subcommand), then `/localize validate`

**Expected behavior:**
1. With no subcommand the skill outputs usage and stops: FAIL — missing required subcommand
2. In validate mode, unset locales are asked about ("which locales ship?") before any check runs

**Assertions:**
- [ ] No subcommand ⇒ usage and FAIL, with nothing read or written
- [ ] Unset `localization.locales` is a question — not treated as a single locale
- [ ] The source locale is confirmed with the user and stated in the output

---

### Case 7: Edge Case — RTL check with no RTL locale; freeze with violations

**Fixture:**
- `localization.locales: [ko-KR, en-US, ja-JP]`
- `production/localization/freeze-status.md` shows `**Status**: ACTIVE`; a later extract finds two new keys

**Input:** `/localize rtl-check`, then `/localize extract`

**Expected behavior:**
1. RTL check stops with `NOT CHECKED — no RTL locale configured`
2. Extract appends the two new keys to `## Post-Freeze Changes` after "May I write this to `production/localization/freeze-status.md`?" and warns that they are freeze violations needing release-manager and product-manager approval

**Assertions:**
- [ ] The skipped RTL check announces itself by name
- [ ] Freeze violations are recorded in the freeze file, not silently accepted
- [ ] Every write is preceded by its own "May I write" question

---

### Case 8: Director Gate Check — No gate; specialists only

**Fixture:**
- Catalogs and locales configured

**Input:** `/localize cultural-review`

**Expected behavior:**
1. Skill spawns `localization-lead` via `Agent` for the cultural review (money colours, number and holiday sensitivities, regulated claims per `.claude/docs/compliance/<region>.md`)
2. No director gate is spawned; findings use BLOCKING / ADVISORY / NOTE

**Assertions:**
- [ ] No director gate is invoked and no gate skip note appears
- [ ] "May I write this cultural review report to `production/localization/cultural-review-[date].md`?" precedes the write

---

## Protocol Compliance

- [ ] Reads locales from `project.yaml` and asks when unset
- [ ] Skips the code scan with a `NOT CHECKED` line when no code root resolves
- [ ] Never auto-translates: new or missing keys stay empty or go to translators
- [ ] Keeps catalog edits to diffs of new entries; never rewrites existing translations
- [ ] Asks "May I write" before every file it creates or updates
- [ ] Writes the QA report under `production/qa/`; nothing under `production/session-logs/`
- [ ] Ends with the recommended workflow and next steps

---

## Coverage Notes

- Store listing length limits come from the table in
  `.claude/agents/localization-lead.md` (§ Store listings and notification
  templates); this spec does not restate the limits.
- `brief` mode and `freeze lift` are not fixture-tested separately; both follow the
  same ask-before-write rule as Case 7.
- Machine and LLM translation quality is outside this skill's automated checks; the
  rule that a fluent reviewer post-edits before shipping is asserted only as text.
