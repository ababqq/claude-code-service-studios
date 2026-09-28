# Skill Spec: /changelog

> **Category**: sprint
> **Priority**: low
> **Spec written**: 2026-09-28

## Skill Summary

`/changelog` keeps the **product's** changelog, `docs/CHANGELOG.md`, in Keep a Changelog
form from the template `.claude/docs/templates/changelog-template.md`. It runs a
provenance check that classifies every commit in the range as Product, Framework /
maintenance or Unclear (the rule is kept identical in `/release-notes`), reads the git
history for the version's range together with the delivery records (sprint plans and
`production/sprint-status.yaml`, closed stories, PRDs and quick specs, verified bugs,
API change records, migration plans, the latest security audit), and writes one version
section with the public categories `### Added`, `### Changed`, `### Deprecated`,
`### Removed`, `### Fixed`, `### Security` and `### Breaking / API`, plus an
`### Internal` part. It also produces a public view without `### Internal`. It never
writes the repository-root `CHANGELOG.md` (the framework's own history). The skill has
no question widget: every question is asked in plain text. Verdicts: CHANGELOG WRITTEN,
COMPLETE, NOT ASSESSED. No director gate.

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`); `name` is `changelog`, equal to the directory `.claude/skills/changelog/` and the catalog `name`
- [ ] Bootstrap: the first body line is `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation` `` and `allowed-tools` grants `Bash(bash "*/.claude/skills/changelog/../../hooks/yaml-helper.sh" resolve_config *)`
- [ ] `--keys` is exactly `automation`
- [ ] The line after the bootstrap block is exactly: ``Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] Automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") present verbatim right after that line
- [ ] `allowed-tools` is exactly: `Read, Glob, Grep, Write, Bash` plus the bootstrap grant — no `Edit`, no `AskUserQuestion`, no `Agent`
- [ ] 2+ phase headings found (`## Phase 1: Parse Arguments` … `## Phase 8: Next Steps`), preceded by `## Provenance check — before reading any history`
- [ ] Verdict keywords present, exactly: `CHANGELOG WRITTEN`, `COMPLETE`, `NOT ASSESSED`
- [ ] "May I write this changelog to `docs/CHANGELOG.md`?" with the options `[A] Yes, insert this entry`, `[B] Yes, overwrite the file entirely`, `[C] No — I'll copy it manually` appears before the write
- [ ] Output at the exact path `docs/CHANGELOG.md`; the skill states it never writes the repository-root `CHANGELOG.md`
- [ ] The version section uses `## [x.y.z] - YYYY-MM-DD` and the categories `### Added`, `### Changed`, `### Deprecated`, `### Removed`, `### Fixed`, `### Security`, `### Breaking / API`, `### Internal`; entries not tied to a version go under `## [Unreleased]`
- [ ] The provenance rule (Product / Framework / maintenance / Unclear, filter per commit, stop only on zero Product commits) is present and states it is kept identical in `/release-notes`
- [ ] No `!` injection other than the bootstrap line; no `file:line` citations of other files
- [ ] Next-step handoff names current skills: `/release-notes [version]`, `/release-checklist [version]`, `/team-release [version]`

---

## Director Gate Checks

- **Full mode**: no gate — changelog compilation is not a delivery gate
- **Lean mode**: no gate
- **Solo mode**: no gate
- **Review-mode exempt**: not applicable
- **N/A**: `review_mode` is not among the skill's keys; the output never references a gate result

---

## Test Cases

Quoted prompts, option labels and verdict tokens below are the canonical English text
of `SKILL.md`; at run time the model renders them in the user's conversation language.

### Case 1: Happy Path — Moa 1.4.0 section, new file

**Fixture** (assumed project state):
- Git tags `v1.3.0` and earlier; no `v1.4.0` tag yet
- 48 commits since `v1.3.0`: 31 Product (goal progress ring, Naver sign-in, a goals bug fix, a session-token security fix), 17 Framework / maintenance (skills, hooks, CI)
- `production/sprint-status.yaml` and closed stories under `production/epics/goals-core/` name `design/prd/goals.md`; `production/qa/bugs/BUG-0042.md` became `Verified Fixed`; `docs/api/changes/api-change-2026-10-20.md` has a BREAKING row
- `docs/CHANGELOG.md` does NOT exist

**Input:** `/changelog 1.4.0`

**Expected behavior:**
1. The provenance check samples `git log --oneline -20`, classifies each commit, and states "31 of 48 commits used; 17 framework or unclear commits excluded"
2. Phase 1 sets the entry to `## [1.4.0] - YYYY-MM-DD` with the range `v1.3.0..HEAD`, asking for the planned date when no record gives one
3. Phase 2 reads the delivery records and states any source not found
4. Phase 3 groups related commits into one entry per change and places each Product commit in exactly one category
5. Phase 4 produces the version entry; Phase 5 the public view (no `### Internal`, no file paths)
6. Phase 7 recommends creating the file from `.claude/docs/templates/changelog-template.md` (header, `## [Unreleased]`, this entry) and asks "May I write this changelog to `docs/CHANGELOG.md`?"
7. After the write: Verdict **CHANGELOG WRITTEN**

**Assertions:**
- [ ] Only Product commits reach public categories; framework commits appear only as `### Internal` lines when they changed the project's own delivery
- [ ] The provenance count is stated so the reader can see the filter ran
- [ ] The breaking API change appears under `### Breaking / API`, saying who is affected and what they must do
- [ ] The plan price change carries old → new values and the effective date
- [ ] No person's name appears in any entry
- [ ] Verdict is CHANGELOG WRITTEN after a successful write

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — Provenance check finds no Product commit

**Fixture:**
- The 20 most recent commits all change `.claude/skills/`, `.claude/hooks/` and CI workflows
- None names a feature found in `design/prd/`, `design/quick-specs/` or `production/epics/`

**Input:** `/changelog 1.4.1`

**Expected behavior:**
1. Every commit is classified Framework / maintenance
2. Zero Product commits → the skill stops with "The git history in this repo does not appear to belong to [product]. …"
3. Verdict **NOT ASSESSED** — [reason]; nothing written

**Assertions:**
- [ ] Zero Product commits stops the run before any entry is drafted
- [ ] A history that merely contains maintenance commits alongside Product commits does not stop the run
- [ ] No customer-facing text is produced from framework commits
- [ ] Nothing is written

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: NOT ASSESSED — Not a git repository; no version known

**Fixture (variant A):** `git rev-parse --is-inside-work-tree` fails (not a git repository)

**Fixture (variant B):** a git repository; no argument; `project.version` is not set in `project.yaml`

**Input:** `/changelog 1.4.0` (A) · `/changelog` (B)

**Expected behavior:**
1. Variant A: the skill says so and stops with verdict **NOT ASSESSED** — there is no history to read; nothing written
2. Variant B: the skill asks which version this is — or whether the entries should go under `## [Unreleased]` — and waits; it does not invent a version number

**Assertions:**
- [ ] A missing git history yields NOT ASSESSED, never an empty changelog written as if complete
- [ ] An unset `project.version` leads to a plain-text question, not a guessed version
- [ ] No file is written in either variant before the answer

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Mode Variant — Sprint argument and no argument

**Fixture:**
- Variant A: `production/sprints/sprint-07.md` exists with its dates
- Variant B: `project.version: 1.4.0` in `project.yaml`

**Input:** `/changelog sprint-7` (A) · `/changelog` (B)

**Expected behavior:**
1. Variant A: the range is the sprint's dates from `production/sprints/sprint-07.md`; a sprint is not a version, so the entries go under `## [Unreleased]`
2. Variant B: `project.version` is read and treated as the version argument, and the skill says so

**Assertions:**
- [ ] A sprint argument never produces a version heading
- [ ] The no-argument path states where the version came from

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Edge Case — No tags; commits without task references

**Fixture:**
- No `v*` tags exist; the repository has 1,800 commits
- Of the commits in range, several lack any task reference (TR-ID, story, BUG, INC, ADR, tracker key or PR number); two have subjects too vague to classify ("tweak", "wip")

**Input:** `/changelog 1.0.0`

**Expected behavior:**
1. With no tags, the range is bounded explicitly with `git log --format='%h %s' -n 100` — never the full log; if 100 commits do not reach far enough, the skill says so and asks for a start ref
2. Commits without a task reference are counted in the `### Internal` metrics line as `[K] without a task reference`
3. The vague commits go to `### Internal` as `Unclassified: [subject] ([hash])` — never guessed into a public category
4. The output states what was not found, e.g. `Sprint records: none for this period — categorised from commit subjects only` when that applies

**Assertions:**
- [ ] The skill does not fall back to the full history when no tags exist
- [ ] Missing task references are counted, not silently dropped
- [ ] Unclassifiable commits never reach a public category
- [ ] Missing delivery records are named in the output

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Existing `docs/CHANGELOG.md` — insert, never duplicate

**Fixture:**
- `docs/CHANGELOG.md` exists with `## [Unreleased]` (two entries this release ships), `## [1.3.0]` and `## [1.2.0]`
- Variant: the file already has a `## [1.4.0]` section

**Input:** `/changelog 1.4.0`

**Expected behavior:**
1. The recommendation defaults to **[A] insert**
2. [A]: the whole file is read, the new section is inserted directly below `## [Unreleased]` (newest first), the two shipped `[Unreleased]` entries move into it, and the whole file is written back; nothing else changes
3. Variant: the difference is shown and the user is asked whether to replace that section — never two sections for one version
4. [B] overwrite warns first that earlier versions will be lost
5. Compare links are added only when `git remote get-url origin` yields a URL they can be built from

**Assertions:**
- [ ] Existing version sections are preserved on insert
- [ ] Entries already under `## [Unreleased]` are not listed twice
- [ ] A duplicate version section is never created
- [ ] No compare URL is invented

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: Gate compliance and declined write

**Fixture:**
- Commits since `v1.3.0`; `project.yaml` sets `modes.review_mode: full`
- The user answers [C] to the write question

**Input:** `/changelog 1.4.0`

**Expected behavior:**
1. No director gate is invoked, whatever the review mode (the skill does not resolve `review_mode`)
2. The entry and the public view are output; nothing is written
3. Verdict **COMPLETE** — changelog generated

**Assertions:**
- [ ] No gate is invoked and no gate result is referenced
- [ ] A declined write yields COMPLETE, not CHANGELOG WRITTEN
- [ ] The skill never writes `modes.review_mode` or any other rigor-fronted knob

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Reads the git history and the delivery records before compiling
- [ ] Asks "May I write this changelog to `docs/CHANGELOG.md`?" before writing, in plain text (no question widget)
- [ ] Presents both the version entry and the public view before asking
- [ ] Ends with next steps naming `/release-notes`, `/release-checklist`, `/team-release`
- [ ] Does not write the repository-root `CHANGELOG.md`
- [ ] Writes no evidence, reports or plans under `production/session-logs/` (gitignored)
- [ ] No sprint file, sprint-status file or milestone record is written

---

## Coverage Notes

- Merge commits, reverts and fixup commits are handled by the "clean up the narrative"
  guideline (a reverted change that never shipped appears nowhere); not given a fixture.
- Non-`v<version>` tag schemes are used when the project tags differently, with the
  bounding tag named; covered by the skill text only.
- `/release-notes` consumes the section written here; the handoff is verified in the
  `/release-notes` spec.
