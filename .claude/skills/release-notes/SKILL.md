---
name: release-notes
description: "Customer-facing release notes per channel from `docs/CHANGELOG.md`."
argument-hint: "[version] [--style brief|detailed|full]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash, AskUserQuestion, Bash(bash "*/.claude/skills/release-notes/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,distribution,surfaces`

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

# Release Notes

This skill turns one version's section of the product changelog into
**customer-facing** release notes for every channel the release reaches, in every
locale the product ships in. It writes one file,
`production/releases/<version>/release-notes.md`, from the template
`.claude/docs/templates/release-notes.md`.

| Channel section | When it is written | Limit |
|---|---|---|
| `## In-App / Web` | always — the in-app "What's new" screen and the web changelog page | — |
| `## App Store` | only with *Stores* (`release.distribution` is `stores` or `web+stores`) | 4000 characters per locale |
| `## Google Play` | only with *Stores* | 500 characters per language |
| `## API / Developers` | only with *Public API* (`api` in `platform.surfaces`) | — |

**The source is `docs/CHANGELOG.md`**, the section `## [<version>]` written by
`/changelog`. This skill never reads `production/releases/<version>/changelog.md` —
nothing writes that file. The git history is read only to confirm which changes are
customer-facing (the provenance check below), never as a substitute for the
changelog.

**Language.** Headings, the header labels and the `> **Locale**:` lines stay in
English exactly as the template spells them. Everything under them is written in
the locale of its block — one block per entry of `localization.locales`, whatever
language the conversation is in. Customer copy ships in the language the customer
reads.

**Verdicts**: `COMPLETE` (every applicable channel written for every locale, within
limits) · `NOT ASSESSED` (the file was written, but a channel or locale could not be
completed — each gap is named on the file's `**Gaps**` line) · `BLOCKED` (nothing
written: no changelog section, a failed provenance check, or no version).

## Provenance check — before reading any history

**Confirm the history you are about to read belongs to THIS product.** Run this
before Phase 2 and stop if it fails.

1. Sample the recent log with Bash: `git log --oneline -20`.
2. **Classify every commit in the range, one at a time**, into exactly one of:
   - **Product** — changes what the product's users or API consumers experience
     or depend on: features, screens and copy, API behaviour, plans and prices,
     notifications, performance or reliability they notice, security and privacy
     fixes, and a bug in any of those.
   - **Framework / maintenance** — changes CCSS itself or the project's tooling:
     subjects naming skills, hooks, agents, rules, the skill testing framework,
     CI workflows, or the framework's own docs. **Excluded from customer-facing
     text, but not a reason to stop.**
   - **Unclear** — treat as framework. A commit you cannot confidently place is
     not one to write customer-facing text from.
3. Then decide from the counts:
   - **At least one Product commit** → proceed, using **only** those. Say how many
     of how many you used, so the reader can see the filter ran.
   - **Zero Product commits** → stop, using the message below.

> **Filter per commit; do not stop on a repo that merely contains maintenance
> work.** Every project built on this framework accumulates commits touching
> hooks, CI and skills — the product repo *is* the framework repo. Listing such
> subjects as a hard stop fires on virtually every real project and contradicts
> step 2 whenever a history is mostly the product's. The danger was never that
> such commits *exist*; it is that they get **rendered as customer-facing copy**.
> Excluding them addresses that exactly, and a repo-level stop does not.
>
> This rule is kept identical in `/changelog` and `/release-notes` on purpose —
> the two read the same history for different audiences, and they must not
> disagree about whose history it is. Change both together.

Corroborate before you proceed, cheaply: the Product commits should name features
that appear in `design/prd/`, `design/quick-specs/` or `production/epics/`. If they
name a product those directories never mention, that is the real wrong-history
signal — stop.

If **no** commit in the range is this product's, say so and stop:

> "The git history in this repo does not appear to belong to [product]. The recent
> commits describe [what they actually describe]. I cannot write customer-facing
> text from it — point me at the right history, or supply the change list directly."

**Why this is a hard stop, not a warning.** This exact failure is real, not
hypothetical: a batch of framework-internal commits produced customer-facing copy
reading *"Fixed an issue where progress from your last session could be lost on
launch"* — a session-hook timeout rendered as a product fix for a feature the
product did not have. It was fluent, plausible, and entirely false. A reader
cannot tell the difference; only this check can.

**How the check applies here.** The range is the version's range: the previous
release tag to `v<version>`, or to `HEAD` when that tag does not exist yet (list tags
with `git tag --list 'v*' --sort=-v:refname`). A changelog entry is customer-facing only when at
least one commit behind it is a Product commit; an entry backed only by framework or
unclear commits is left out of the notes and listed in Phase 7 as excluded.
`### Internal` is never customer-facing, whatever its commits are.

---

## Phase 0: Resolve Channels and Locales

Resolve which channels and locales apply. **Unset is a question, never a licence to
emit everything:**

- **`release.distribution`** (block above). `stores` or `web+stores` ⇒ App Store and
  Google Play sections. `web`, `enterprise` or `internal` ⇒ no store sections; name
  the omission on the `**Channels**` line (`App Store, Google Play — omitted:
  release.distribution is 'web'`). **Unset ⇒ ask how this release ships** — do not
  write store sections "just in case", and do not drop them silently.
- **`platform.surfaces`** (block above). `api` listed ⇒ `## API / Developers`.
  **Unset ⇒ ask which surfaces ship.** An internal backend that only your own apps
  call is not the `api` surface and gets no developer section.
- **`localization.locales`** — read from `project.yaml` (no config label carries it).
  One locale block per entry, in the listed order. **Unset ⇒ ask which locales
  ship**; never default to the conversation language.
- **`project.name`** — read from `project.yaml` for the H1; unset ⇒ ask.

`internal` distribution: the notes are for employees or testers; say so in the
header and keep the same structure.

---

## Phase 1: Parse Arguments

- **`version`** — the release version (SemVer, e.g. `1.4.0`). No argument → read
  `project.version` from `project.yaml` and confirm it with the user. Neither →
  ask. Never guess a version.
- **`--style`** — `brief` (one line per item), `detailed` (one line plus one sentence
  of context per item, and a Highlights sentence — the default), or `full`
  (detailed, plus a short note from the team under `## Highlights` explaining the
  biggest change, before → after values for every plan, limit or price change, and
  links to help-center articles).

With the version known, run the provenance check above over the version's range.

---

## Phase 2: Gather Change Data

1. **The changelog section.** Read `docs/CHANGELOG.md` and find the heading
   `## [<version>] - YYYY-MM-DD`. Take its public categories (`### Added`,
   `### Changed`, `### Deprecated`, `### Removed`, `### Fixed`, `### Security`,
   `### Breaking / API`) and, for context only, its `### Internal` block (known
   issues shipped, deferred items).

   **If the section does not exist** — the file is absent, or it has no heading for
   this version (entries still sitting under `## [Unreleased]` do not count):

   > "No changelog section for [version] in `docs/CHANGELOG.md`. Run
   > `/changelog [version]` first to write it, then re-run `/release-notes [version]`
   > — or give me the change list directly."

   Unless the user supplies a change list, the verdict is **BLOCKED** — stop here
   without generating notes. A change list the user supplies is used as the source
   instead, and the header's `**Source**` line says so.

2. **Context for wording**, read when present:
   - the PRDs named in the entries (`design/prd/<feature>.md`) — the feature's name
     and the user value it states, so the notes describe the benefit the PRD
     promised;
   - bug records named in `### Fixed` (`production/qa/bugs/BUG-NNNN.md`) — the
     symptom users saw;
   - API change records named in `### Breaking / API`
     (`docs/api/changes/api-change-*.md`), developer guides (`docs/api/guides/`) and
     `docs/api/api-guidelines.md` `## Deprecation` — for `## API / Developers` and
     `Sunset` dates;
   - `design/product/pricing-model.md` — plan names, prices and entitlements for
     `## Changes to Plans & Pricing`;
   - unresolved bugs that ship (`production/qa/bugs/BUG-NNNN.md` whose `**Status**:`
     is `Open`, `In Progress` or `Fixed — Pending Verification`) — candidates for
     `## Known Issues`;
   - `production/releases/<version>/release-checklist.md` `## Scope`, when it
     exists — to confirm the notes cover what actually ships;
   - sprint records in `production/sprints/` for the period — context for why a
     change was made.

3. **Provenance.** Using the check run in Phase 1, mark each changelog entry
   customer-facing or excluded.

---

## Phase 3: Voice and Template

**Template** — always `.claude/docs/templates/release-notes.md`. Its headings are a
contract: `## Highlights`, `## New`, `## Improved`, `## Fixed`, `## Security`,
`## Changes to Plans & Pricing`, `## Deprecations`, `## Known Issues`,
`## In-App / Web`, `## App Store`, `## Google Play`, `## API / Developers`, in that
order, inside every locale block. Never translate or rename a heading.

**Voice** — before drafting:

1. Read `design/brand/voice-and-tone.md` when it exists: `## Tone by Context`
   (release notes usually follow the success tone; billing changes follow the
   billing tone), `## Terminology` and `## Do / Don't`, and `## Korean Style Notes`
   for `ko-KR` blocks (존댓말 level, spacing).
2. Read `design/registry/entities.yaml` for the product's official names — plan
   names, feature names, currency formats. The notes use exactly these names.
3. If no voice guide exists, ask which register to use and recommend one:
   for a consumer app, a warm, plain register (in Korean, 해요체 — "목표 진행률을 한눈에
   볼 수 있어요"); for B2B, finance or public-sector products, a formal register (in
   Korean, 합니다체). Default wording principles either way: user benefit first,
   concrete, no hype, no internal vocabulary.

---

## Phase 4: Categorize and Translate

Map the customer-facing changelog entries to the content sections:

| Changelog category | Release-notes section |
|---|---|
| `### Added` | `## New` |
| `### Changed` — behaviour | `## Improved` |
| `### Changed` — plans, prices, limits, entitlements, fees | `## Changes to Plans & Pricing` (before → after, effective date, who is affected) |
| `### Deprecated`, `### Removed` | `## Deprecations` (what is retired, when, what to use instead) |
| `### Fixed` | `## Fixed` |
| `### Security` | `## Security` (no exploit detail) |
| `### Breaking / API` | `## API / Developers`; plus a plain-language line under `## Improved` or `## Deprecations` when end users notice it |
| `### Internal` known issues users will notice | `## Known Issues` |
| the one or two most valuable changes | `## Highlights` |

Translate developer language into the customer's:

- "Move auto-debit retry to a queue-backed job with exponential backoff" →
  ko-KR "자동이체가 일시적으로 실패해도 더 안정적으로 다시 시도해요" · en-US "Automatic
  transfers now retry more reliably after a temporary failure"
- "Fix N+1 query on `GET /v1/goals`" → "목표 목록이 더 빨리 열려요" · "Your goals list
  opens faster"
- "Handle null state in Kakao login callback" → "카카오 로그인 후 앱이 멈추던 문제를
  고쳤어요" · "Fixed an issue where the app could freeze after signing in with Kakao"
- Leave out changes users cannot notice.
- Keep exact values for plan, price, limit and fee changes (KRW 4,900 → KRW 5,900,
  effective 2026-12-01).
- Security entries say what is safer, never how the weakness worked; agree the
  wording and timing with security-engineer when the fix is not yet deployed
  everywhere.

---

## Phase 5: Generate the Notes

Fill the template once per locale, in the order of `localization.locales`.

**Content sections** (`## Highlights` … `## Known Issues`): write per `--style`.
A section with nothing in it carries the single line "None in this release." in the
block's language — the heading stays, so a reviewer can see it was considered.

**Channel sections** — built from the content sections of the same block:

- `## In-App / Web` — the Highlights sentence, three to five bullets, and a link to
  the help-center article when one exists.
- `## App Store` (only with *Stores*) — the "What's New in This Version" text:
  plain text, no markdown, at most **4000 characters** for the locale. Check the
  current App Store Review Guidelines on metadata before submission (for example, no
  mention of other mobile platforms).
- `## Google Play` (only with *Stores*) — plain text, at most **500 characters** for
  the language. Play Console takes every language in one field as
  `<ko-KR>…</ko-KR>` blocks; show that combined form in the conversation so it can
  be pasted, and keep one language per section in the file.
- `## API / Developers` (only with *Public API*) — breaking changes with the
  affected operations and migration steps, new operations and fields, deprecations
  with their `Sunset` dates, the API version, and links to `docs/api/guides/`.

**Count characters, not bytes.** Korean text is three bytes per character in UTF-8,
so a byte count overstates it threefold. Count with Bash, e.g.
`printf '%s' "$TEXT" | LC_ALL=en_US.UTF-8 wc -m` or
`python3 -c 'import sys; print(len(sys.stdin.read()))'`, and write the count under
each store section (`Character count: 412 / 500`). Over the limit ⇒ shorten, never
truncate mid-sentence. If the count could not be run, write
`Character count: NOT ASSESSED — [reason]` and list the section on `**Gaps**`.

**A locale you cannot write well.** When the user wants a human translator or the
localization team to write a locale, leave that block's sections as
`NOT ASSESSED — awaiting translation ([owner])`, list it on `**Gaps**`, and say so
in the summary. Never ship machine-literal text as if it were reviewed, and never
fill one locale's block with another locale's text.

---

## Phase 6: Review Output

Check every block for:

- no internal jargon, ticket IDs, sprint numbers, commit hashes, file paths or
  people's names;
- plan, price, limit and fee changes carry before → after values and the effective
  date, and name who is affected;
- fixes describe what users experienced, not the technical cause;
- nothing promised with a date that has not been decided ("coming soon" at most);
- the voice matches `design/brand/voice-and-tone.md` (or the register agreed in
  Phase 3) and the names match `design/registry/entities.yaml`;
- every block is written in its own locale — no untranslated lines left over;
- store sections are within their limits, and appear only with *Stores*;
- `## API / Developers` appears only with *Public API*, and every breaking change
  has a migration path.

---

## Phase 7: Save the Notes

Present the notes with: a count of entries per section and locale, the channels
written and omitted (with the reason), the character counts of the store sections,
and the changelog entries excluded by the provenance check or as internal (for the
user to confirm nothing customer-facing was dropped).

Ask: "May I write this to `production/releases/<version>/release-notes.md`?"

If yes, write the file, creating `production/releases/<version>/` if needed. If the
file already exists, show what changes and ask before replacing it. This is the
only file this skill writes — publishing to the stores, the website or the in-app
screen is a human action.

---

## Phase 8: Next Steps

Report the verdict:

- **COMPLETE** — release notes written for every applicable channel and locale.
- **NOT ASSESSED** — release notes written with gaps: [each channel or locale gap,
  and what closes it].
- **BLOCKED** — nothing written: [no changelog section | provenance check stopped |
  no version].

Then use `AskUserQuestion`:

- Prompt: "Release notes for [version] are saved. What's next?"
- Options (offer only what applies):
  - `[A] /smoke-check — smoke the release candidate build first (the release checklist and the launch gate need its PASS)`
  - `[B] /release-checklist [version] — confirm the release is ready (its Release Notes block reads this file)`
  - `[C] /team-content voice — have ux-writer write the voice-and-tone guide these notes follow (offered when Phase 3 found none)`
  - `[D] /localize brief — brief the translators for the locales listed as gaps`
  - `[E] /team-release [version] — execute the release`
  - `[F] Stop here`

---

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and `autonomous`
modes see `.claude/docs/automation-modes.md`.

1. **Question → Options → Decision → Draft → Approval.** The register, the
   Highlights and anything touching plans or prices are decided with the user before
   the full draft is written.
2. **"May I write this to `<path>`?"** before the one write this skill makes.
3. **Unset is a question.** Unset `release.distribution`, `platform.surfaces`,
   `localization.locales` or `project.name` is asked about — never answered by
   writing every channel, dropping channels silently, or defaulting to the
   conversation language.
4. **Skips announce themselves.** Omitted channels are named on the `**Channels**`
   line, incomplete locales on the `**Gaps**` line, excluded changelog entries in the
   summary.
5. **No publishing, no commits.** Posting the notes to App Store Connect, Play
   Console, the website or the app, and committing the file, are the user's actions.
