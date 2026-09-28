---
name: changelog
description: "Keep-a-Changelog history from commits and sprint records (internal and public sections)."
argument-hint: "[version|sprint-number]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash, Bash(bash "*/.claude/skills/changelog/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation`

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

This skill keeps the **product's** changelog, `docs/CHANGELOG.md`, in
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) form, using the template
`.claude/docs/templates/changelog-template.md`. Each version section has a public
part (the categories Added, Changed, Deprecated, Removed, Fixed, Security and
`### Breaking / API`) and an internal part (`### Internal`). `/release-notes` reads
the version's section to write customer-facing notes per channel, and
`/team-release` checks that the section exists before a release goes out.

**Never write the repository-root `CHANGELOG.md`.** That file is the framework's
own release history, maintained by the framework's maintainers; the product's
history lives only in `docs/CHANGELOG.md`.

This skill has no question widget: every question below — the version, the
start ref, the write — is asked in plain text, and the skill waits for the answer.

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

**Framework commits still belong in `### Internal`** when they changed the
project's own delivery (a CI job added, a hook tightened) — as internal lines,
never as public entries.

---

## Phase 1: Parse Arguments

Read the argument:

- **A version** (SemVer, e.g. `1.4.0`) → the entry is `## [1.4.0] - YYYY-MM-DD`.
  The range runs from the previous release tag to the tag `v1.4.0`, or to `HEAD`
  when that tag does not exist yet (the usual case while the release is being
  prepared). The date is the planned release date; ask for it when no sprint or
  milestone record gives one, and say that the release step corrects it if the
  release slips.
- **A sprint number** (`sprint-7` or `7`) → the range is the sprint's dates from
  `production/sprints/sprint-07.md`. A sprint is not a version, so its entries go
  under `## [Unreleased]`.
- **No argument** → read `project.version` from `project.yaml`. If it is set, treat
  it as the version above and say so. If it is unset, ask which version this is —
  or whether the entries should go under `## [Unreleased]`. Do not invent a
  version number.

Verify the repository: run `git rev-parse --is-inside-work-tree`. If this is not a
git repository, say so and stop with verdict **NOT ASSESSED** — there is no
history to read.

Find release tags with `git tag --list 'v*' --sort=-v:refname`. Tags follow
`v<version>`; if the project tags differently, use its scheme and say which tag
bounds the range.

---

## Phase 2: Gather Change Data

Read the git log for the range:

```
git log --format='%h %s' [previous-tag]..[v<version> or HEAD]
```

If no tags exist, bound the range explicitly — `git log --format='%h %s' -n 100`.
Do not fall back to the full log: on an established repo that is thousands of
lines for a changelog covering one release, and the oldest of them are the least
relevant. If 100 commits does not reach far enough back, say so and ask for a
start ref rather than widening blindly.

For `Lines added / removed` in the metrics, use `git diff --shortstat [range]`.

Then read the delivery records for the same period — they explain *why* a commit
happened and which feature it belongs to:

- Sprint plans and status: `production/sprints/` for the period, and
  `production/sprint-status.yaml` for stories with `status: done`.
- Stories closed in the period (`production/epics/*/story-*.md`): their `**PRD**`,
  `**Requirement**` (TR-ID), `**API Contract**`, `**Migration**` and
  `**Feature Flag**` fields.
- The PRDs and quick specs those stories implement (`design/prd/*.md`,
  `design/quick-specs/*.md`) — for the feature's name and the user value it states.
- Bug records `production/qa/bugs/BUG-NNNN.md` whose `**Status**:` became
  `Verified Fixed` or `Closed` in the period — the `### Fixed` entries describe their
  user-visible symptom.
- API change records `docs/api/changes/api-change-*.md` in the period — the source
  for `### Breaking / API` and API deprecations.
- Migration plans `docs/data/migrations/*.md` touched in the period — for
  `### Internal`.
- The latest security audit `production/security/security-audit-*.md` — findings
  fixed in the range go under `### Security`, without exploit detail.
- The existing `docs/CHANGELOG.md`, if any — entries already listed under
  `## [Unreleased]` must not be listed twice.

State what was not found rather than skipping it: `Sprint records: none for this
period — categorised from commit subjects only`. A changelog built from commit
subjects alone is weaker, and the reader should know which one they are reading.

---

## Phase 3: Categorize Changes

Categorize every Product commit (after the provenance filter) into exactly one
category. Group related commits into one entry — a feature built across twelve
commits is one `### Added` line, not twelve.

| Category | What goes in it | Typical Conventional Commit signal |
|---|---|---|
| `### Added` | new capabilities users or API consumers can use | `feat:` |
| `### Changed` | changes to existing behaviour, including plan, price, limit and fee changes (old → new, effective date) | `feat:` on an existing feature, `perf:` users notice |
| `### Deprecated` | capabilities or API fields scheduled for removal, with the removal version or `Sunset` date | `deprecate`, API change records |
| `### Removed` | capabilities removed in this version | `feat!:` / `refactor!:` removing something |
| `### Fixed` | user-visible defects that no longer occur | `fix:` |
| `### Security` | security and privacy fixes | `fix(security):`, dependency advisories fixed |
| `### Breaking / API` | changes that break users or API consumers: removed or renamed operations or fields, changed auth, new required parameters, minimum app version raised | `feat!:` / `fix!:` (a bang after the type), a `BREAKING CHANGE:` footer, a BREAKING row in an API change record |
| `### Internal` | refactoring, tooling, CI, infrastructure, test-only changes, framework commits, known issues shipped, deferred items, metrics | `refactor:`, `chore:`, `ci:`, `test:`, `build:`, `docs:` |

A commit whose subject is too vague to classify confidently goes to `### Internal`
as `Unclassified: [subject] ([hash])` — never guessed into a public category.

For each commit, check whether the message contains a task reference — a TR-ID
(`TR-goals-001`), a story (`story-001`), a bug (`BUG-0042`), an incident
(`INC-20261104-01`), an ADR (`ADR-0001`), a tracker key (`GOALS-123`) or a PR/issue
number (`#123`). Count commits that lack any task reference and include the count
in the `### Internal` metrics line as `[K] without a task reference`.

---

## Phase 4: Generate the Version Entry

Fill the template's version section. Leave out a category with no entries;
`### Internal` is always present.

```markdown
## [1.4.0] - 2026-11-04

### Added

- Savings goals show a progress ring with the amount left and the expected completion date (`design/prd/goals.md`, story-003)
- Sign in with Naver (`design/prd/auth.md`, story-012)

### Changed

- Plus plan monthly price changes from KRW 4,900 to KRW 5,900 for new subscriptions from 2026-12-01; existing subscribers keep their price until 2027-03-01 (`design/prd/subscription.md`)

### Fixed

- Goal progress now updates immediately after an automatic transfer (BUG-0042)

### Security

- Session tokens are rotated after a password change (security audit 2026-10-28, finding H-2)

### Breaking / API

- `GET /v1/goals` returns `targetAmount` as an integer in KRW instead of a decimal string; partner integrations must update their parsers before 2026-12-01 (`docs/api/changes/api-change-2026-10-20.md`)

### Internal

- Commit range: `a1b2c3d..f6e5d4c` — 48 commits, 31 customer-facing, 3 without a task reference
- Migrations: `docs/data/migrations/0007-goal-progress-snapshot.md` — Expand and Migrate shipped; Contract scheduled for 1.5.0
- Feature flags: `goals.v2-progress-ring` — production default off
- Refactoring, tooling and infrastructure: auto-debit retry worker moved to a queue-backed job; CI caches pnpm store
- Known issues shipped: BUG-0051 (S3-Minor) — progress ring animation stutters on Android 10 devices
- Deferred to a later version: goal sharing — waiting on the Kakao share review — 1.5.0
- Files changed: 212 · lines +8,410 / −3,120
```

Public entries are written for a reader outside the team: what changed for them,
not how the code changed. References go in parentheses at the end of the line.
People's names never appear — not in public entries and not in `### Internal`
(name roles when ownership matters).

---

## Phase 5: Generate the Public Changelog

Produce the public view of the same version — the categories only, without
`### Internal` and without file-path references — for a public changelog page
(the product's docs site, a help-center "What's new" page, a developer portal).
Many B2B and API products publish exactly this; consumer apps usually publish
channel-specific notes through `/release-notes` instead.

```markdown
## 1.4.0 — 2026-11-04

### Added
- Savings goals now show a progress ring with the amount left and the expected completion date.
- You can sign in with Naver.

### Changed
- The Plus plan's monthly price for new subscriptions changes from KRW 4,900 to KRW 5,900 on 2026-12-01.
  If you already subscribe, your price stays the same until 2027-03-01.

### Fixed
- Goal progress now updates right after an automatic transfer.

### Breaking / API
- `GET /v1/goals` now returns `targetAmount` as an integer in KRW. Update your integration before 2026-12-01.
```

Write the public view in the language the page is published in. When the product
ships in several locales, say that `/release-notes` produces the per-locale,
per-channel versions from this entry.

---

## Phase 6: Output

Output both to the user: the version entry (the working record, internal part
included) and the public view. State the provenance count ("31 of 48 commits used;
17 framework or unclear commits excluded") and every source that was not found
(Phase 2).

---

## Phase 7: Offer File Write

Check whether `docs/CHANGELOG.md` exists, then ask:

> "May I write this changelog to `docs/CHANGELOG.md`?
> [A] Yes, insert this entry (recommended if the file already exists)
> [B] Yes, overwrite the file entirely
> [C] No — I'll copy it manually"

- If the file does not exist, recommend creating it from
  `.claude/docs/templates/changelog-template.md` (header, `## [Unreleased]`, then
  this entry).
- If the file exists, default the recommendation to **[A] insert**.
- **[A] insert**: this skill has no Edit tool, so read the whole file, insert the
  new version section directly below `## [Unreleased]` (newest version first),
  move any `## [Unreleased]` entries that this version ships into the new section,
  and write the whole file back. Nothing else in the file changes. If a
  `## [<version>]` section already exists, show the difference and ask whether to
  replace that section — never keep two sections for one version.
- **[B] overwrite**: write the file with the header, `## [Unreleased]` and the new
  entry only. Warn first that earlier versions in the file will be lost.
- **[C]**: stop here without writing.
- At the bottom, add compare links (`[1.4.0]: <compare URL>`) only when
  `git remote get-url origin` gives a URL the compare link can be built from; never
  invent a URL.

After a successful write: Verdict: **CHANGELOG WRITTEN** — changelog saved to `docs/CHANGELOG.md`.
If the user declines: Verdict: **COMPLETE** — changelog generated.
If the provenance check stopped or there is no git history: Verdict: **NOT ASSESSED** — [reason]; nothing written.

---

## Phase 8: Next Steps

- Use `/release-notes [version]` to turn this section into customer-facing notes per
  channel and locale (`production/releases/<version>/release-notes.md`).
- Use `/release-checklist [version]` before the release goes out; its Scope block
  reads this section.
- `/team-release [version]` checks that the section exists before the release
  executes.

### Guidelines

- Never expose internal code references, file paths or people's names in the
  public view
- Group related changes together rather than listing individual commits
- If a commit message is unclear, check the associated files, story and sprint
  record for context before classifying it
- Plan, price, limit and fee changes always carry old → new values and the
  effective date
- Breaking changes always say who is affected and what they must do
- Known issues are listed honestly in `### Internal`, so `/release-notes` can
  disclose the ones users will notice
- If the git history is messy (merge commits, reverts, fixup commits), clean up
  the narrative rather than listing every commit literally; a reverted change
  that never shipped appears nowhere
