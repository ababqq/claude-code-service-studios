# Skill Spec: /release-notes

> **Category**: sprint
> **Priority**: low
> **Spec written**: 2026-09-28

## Skill Summary

`/release-notes` turns one version's section of the product changelog —
`## [<version>]` in `docs/CHANGELOG.md`, written by `/changelog` — into customer-facing
release notes for every channel the release reaches, in every locale the product ships
in. It writes one file, `production/releases/<version>/release-notes.md`, from the
template `.claude/docs/templates/release-notes.md`: content sections (`## Highlights`
… `## Known Issues`) and channel sections — `## In-App / Web` always, `## App Store`
(≤ 4000 characters per locale) and `## Google Play` (≤ 500 characters per language)
only with store distribution, `## API / Developers` only with the `api` surface — one
block per entry of `localization.locales`. It runs the same provenance check as
`/changelog`, never reads `production/releases/<version>/changelog.md`, asks instead of
guessing when distribution, surfaces, locales or the product name are unset, and
publishes nothing. Verdicts: COMPLETE, NOT ASSESSED (written with named gaps), BLOCKED
(nothing written). No director gate.

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`); `name` is `release-notes`, equal to the directory `.claude/skills/release-notes/` and the catalog `name`
- [ ] Bootstrap: the first body line is `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,distribution,surfaces` `` and `allowed-tools` grants `Bash(bash "*/.claude/skills/release-notes/../../hooks/yaml-helper.sh" resolve_config *)`
- [ ] `--keys` is exactly `automation,distribution,surfaces`
- [ ] The line after the bootstrap block is exactly: ``Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] Automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") present verbatim right after that line
- [ ] `allowed-tools` is exactly: `Read, Glob, Grep, Write, Bash, AskUserQuestion` plus the bootstrap grant — no `Edit`, no `Agent`
- [ ] 2+ phase headings found (`## Phase 0: Resolve Channels and Locales` … `## Phase 8: Next Steps`), with `## Provenance check — before reading any history` before them
- [ ] Verdict keywords present, exactly: `COMPLETE`, `NOT ASSESSED`, `BLOCKED`
- [ ] "May I write this to `production/releases/<version>/release-notes.md`?" appears before the only write
- [ ] Output at the exact path `production/releases/<version>/release-notes.md`; the source is `docs/CHANGELOG.md` `## [<version>]`, and the skill states it never reads `production/releases/<version>/changelog.md`
- [ ] The template headings are named as a contract, in order: `## Highlights`, `## New`, `## Improved`, `## Fixed`, `## Security`, `## Changes to Plans & Pricing`, `## Deprecations`, `## Known Issues`, `## In-App / Web`, `## App Store`, `## Google Play`, `## API / Developers`; the header lines `**Channels**` and `**Gaps**` name omissions and gaps
- [ ] The provenance rule (Product / Framework / maintenance / Unclear, filter per commit, stop only on zero Product commits) is present and states it is kept identical in `/changelog`
- [ ] No `!` injection other than the bootstrap line; no `file:line` citations of other files
- [ ] The closing `AskUserQuestion` names current skills with their real arguments, release-candidate smoke first: `/smoke-check`, `/release-checklist [version]`, `/team-content voice`, `/localize brief`, `/team-release [version]` (never a bare `/team-content` or `/localize`, which only print usage)

---

## Director Gate Checks

- **Full mode**: no gate
- **Lean mode**: no gate
- **Solo mode**: no gate
- **Review-mode exempt**: not applicable
- **N/A**: `review_mode` is not among the skill's keys; the voice guide the notes follow comes from `/team-content voice`, not from a gate here

---

## Test Cases

Quoted prompts, option labels and verdict tokens below are the canonical English text
of `SKILL.md`; at run time the model renders them in the user's conversation language.
Customer copy in the fixtures is written in the locale of its block.

### Case 1: Happy Path — Moa 1.4.0 on web and both stores, two locales

**Fixture** (assumed project state):
- `docs/CHANGELOG.md` has `## [1.4.0] - 2026-11-04` with `### Added` (goal progress ring, Naver sign-in), `### Changed` (Plus plan KRW 4,900 → KRW 5,900 for new subscriptions from 2026-12-01), `### Fixed` (BUG-0042), `### Security`, `### Internal` (one known issue users will notice)
- Resolved block: `release.distribution: web+stores (project.yaml)`, `platform.surfaces: web, ios, android (project.yaml)`
- `project.yaml`: `project.name: Moa`, `localization.locales: [ko-KR, en-US]`
- `design/brand/voice-and-tone.md` and `design/registry/entities.yaml` exist

**Input:** `/release-notes 1.4.0`

**Expected behavior:**
1. Phase 0 resolves the channels (In-App / Web, App Store, Google Play; no API / Developers because `api` is not a surface, named on the `**Channels**` line) and the two locales
2. The provenance check runs over `v1.3.0..HEAD` and marks each changelog entry customer-facing or excluded
3. Phase 3 reads the voice guide (`## Tone by Context`, `## Terminology`, `## Do / Don't`, `## Korean Style Notes` for `ko-KR`) and the registry names
4. Phase 4 maps categories to sections: the price change goes to `## Changes to Plans & Pricing` with before → after, effective date and who is affected; the known issue to `## Known Issues`
5. Phase 5 fills one block per locale in the order `ko-KR`, `en-US`; store sections are plain text within their limits with `Character count: N / 4000` and `N / 500` written under each
6. Phase 7 presents counts, channels and exclusions, then asks "May I write this to `production/releases/1.4.0/release-notes.md`?"
7. Verdict **COMPLETE**; the closing widget offers `/smoke-check` on the release candidate first, then `/release-checklist 1.4.0`; `/team-content voice` is not offered because the voice guide exists

**Assertions:**
- [ ] The source is the `## [1.4.0]` section of `docs/CHANGELOG.md`
- [ ] One block per locale, in the listed order, each written in its own locale; headings stay in English exactly as the template spells them
- [ ] Store sections appear only because distribution is `web+stores`, each within its limit with its character count
- [ ] Customer copy contains no ticket IDs, file paths, sprint numbers, commit hashes or people's names
- [ ] The only write happens after "May I write"; publishing is left to a human

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — No changelog section for the version

**Fixture:**
- `docs/CHANGELOG.md` exists but has no `## [1.5.0]` heading; the 1.5.0 changes still sit under `## [Unreleased]`
- `production/releases/1.5.0/changelog.md` exists (stale, written by hand)

**Input:** `/release-notes 1.5.0`

**Expected behavior:**
1. Phase 2 finds no section for 1.5.0 — `[Unreleased]` entries do not count
2. The skill says: "No changelog section for 1.5.0 in `docs/CHANGELOG.md`. Run `/changelog 1.5.0` first to write it, then re-run `/release-notes 1.5.0` — or give me the change list directly."
3. Unless the user supplies a change list, verdict **BLOCKED** — nothing written
4. The stale `production/releases/1.5.0/changelog.md` is never read

**Assertions:**
- [ ] `[Unreleased]` entries are not treated as the version's section
- [ ] The skill never falls back to `production/releases/<version>/changelog.md` or to raw git history as a substitute
- [ ] BLOCKED writes nothing
- [ ] A change list the user supplies is used instead, and the header's `**Source**` line says so

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: NOT ASSESSED — Unset distribution, a locale awaiting translation

**Fixture:**
- `docs/CHANGELOG.md` has `## [1.4.0]`
- Resolved block prints `release.distribution: (unset -- ask how this release ships)`
- `localization.locales: [ko-KR, en-US, ja-JP]`; the user wants the localization team to write `ja-JP`

**Input:** `/release-notes 1.4.0`

**Expected behavior:**
1. Phase 0 asks how this release ships — it neither writes store sections "just in case" nor drops them silently
2. After the answer (`web+stores`), the `ja-JP` block's sections read `NOT ASSESSED — awaiting translation ([owner])`, and `ja-JP` is listed on `**Gaps**`
3. The file is written after "May I write"; verdict **NOT ASSESSED** — release notes written with gaps, each gap and what closes it named
4. The closing widget offers `/localize brief` to brief the translators for the gap locale

**Assertions:**
- [ ] Unset `release.distribution` leads to a question, never to every channel or to none
- [ ] An incomplete locale is named on `**Gaps**`, never filled with another locale's text or unreviewed machine-literal text
- [ ] The verdict is NOT ASSESSED, not COMPLETE, when any channel or locale has a gap

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Mode Variant — Style and channel selection

**Fixture:**
- `docs/CHANGELOG.md` has `## [2.0.0]` including `### Breaking / API` (`GET /v1/goals` returns `targetAmount` as an integer in KRW)
- Variant A: `release.distribution: web`, `platform.surfaces: web, api`, `--style brief`
- Variant B: `release.distribution: stores`, `platform.surfaces: ios, android`, `--style full`

**Input:** `/release-notes 2.0.0 --style brief` (A) · `/release-notes 2.0.0 --style full` (B)

**Expected behavior (variant A):**
1. No store sections; `**Channels**` reads e.g. "App Store, Google Play — omitted: release.distribution is 'web'"
2. `## API / Developers` lists the breaking change with affected operations, migration steps and the `Sunset` date where one applies
3. Content sections use one line per item

**Expected behavior (variant B):**
1. Store sections are written; no `## API / Developers` (no `api` surface)
2. `full` style adds a short team note under `## Highlights`, before → after values for every plan, limit or price change, and help-center links

**Assertions:**
- [ ] Omitted channels are named on the `**Channels**` line with the reason
- [ ] `## API / Developers` appears only with the `api` surface, and every breaking change has a migration path
- [ ] The style changes the depth of the content sections, not the heading set

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Edge Case — Korean store text counted in characters

**Fixture:**
- The `ko-KR` Google Play draft is 520 characters (about 1,500 bytes in UTF-8)

**Input:** `/release-notes 1.4.0`

**Expected behavior:**
1. Characters are counted with Bash (`printf '%s' "$TEXT" | LC_ALL=en_US.UTF-8 wc -m` or a `python3` length check), not bytes
2. 520 > 500: the text is shortened — never truncated mid-sentence — and the count written as `Character count: 4xx / 500`
3. Had the count failed to run: `Character count: NOT ASSESSED — [reason]`, and the section listed on `**Gaps**`
4. The combined Play Console form (`<ko-KR>…</ko-KR>` blocks) is shown in the conversation; the file keeps one language per section

**Assertions:**
- [ ] Limits are checked in characters, not bytes
- [ ] Over-limit text is shortened, not cut
- [ ] A count that could not run is NOT ASSESSED and listed as a gap

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Provenance — Framework-only entries and `### Internal`

**Fixture:**
- The `## [1.4.0]` section's `### Changed` contains one entry whose commits all touch `.claude/hooks/` (a session-hook timeout)
- `### Internal` lists refactoring and CI changes

**Input:** `/release-notes 1.4.0`

**Expected behavior:**
1. The hook-only entry is backed only by framework commits, so it is left out of the notes and listed in Phase 7 as excluded
2. `### Internal` is never customer-facing, whatever its commits are (only its known issues users will notice feed `## Known Issues`)
3. Phase 7 shows the excluded entries for the user to confirm nothing customer-facing was dropped

**Assertions:**
- [ ] An entry is customer-facing only when at least one commit behind it is a Product commit
- [ ] The provenance rule text matches `/changelog` (the two must not disagree about whose history it is)
- [ ] Exclusions are listed, not silently dropped

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: No version and no director gate

**Fixture:**
- No argument; `project.version` is not set; `project.yaml` sets `modes.review_mode: full`

**Input:** `/release-notes`

**Expected behavior:**
1. The skill asks for the version — it never guesses one
2. No director gate runs at any review mode
3. If the user gives no version, verdict **BLOCKED** — nothing written (no version)

**Assertions:**
- [ ] An unknown version leads to a question
- [ ] No gate is invoked
- [ ] The skill never writes `modes.review_mode` or any other rigor-fronted knob

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses "May I write this to `production/releases/<version>/release-notes.md`?" before the one write; an existing file is replaced only after showing what changes
- [ ] Decides the register, the Highlights and anything touching plans or prices with the user before the full draft
- [ ] Ends with the closing `AskUserQuestion` of next steps
- [ ] Unset `release.distribution`, `platform.surfaces`, `localization.locales` or `project.name` is asked about
- [ ] Publishing to App Store Connect, Play Console, the website or the app, and committing the file, are left to the user
- [ ] Writes no evidence, reports or plans under `production/session-logs/` (gitignored); no sprint file, sprint-status file or milestone record is written

---

## Coverage Notes

- Security entries (what is safer, never how the weakness worked; wording and timing agreed
  with security-engineer when the fix is not yet deployed everywhere) are asserted by the
  skill text; Case 1 includes a `### Security` entry without a dedicated fixture for timing.
- An existing release-notes file for the version (show the change, ask before replacing)
  follows the Phase 7 text and is not given its own case.
- `internal` distribution (notes for employees or testers, same structure) is covered by
  Phase 0 only.
