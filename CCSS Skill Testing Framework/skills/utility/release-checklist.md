# Skill Spec: /release-checklist

> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-09-28

## Skill Summary

`/release-checklist` writes one checklist per release — the first public release and
every release after it — answering one question for one version: is this release
candidate safe to put in front of users, and can it be taken back? It resolves the
version (argument, else `project.version`, else ask), identifies what ships since the
previous completed release (stories, PRDs, quick specs, fixed bugs, changelog
section), reads the evidence reports' verdict lines, and fills the blocks of
`.claude/docs/templates/release-checklist-template.md`: Build & CI Artifact, Database
Migrations, Feature Flags, Environment Config & Secrets, Observability, **Rollback Path
(required at every tier)**, Web (when `web` is a surface), Stores (when
`release.distribution` is `stores` or `web+stores`), Regions (per `compliance.regions`),
Localization, Release Notes and Sign-offs.

Scoping follows two separate axes — `platform.surfaces` (what ships) and
`release.distribution` (how it reaches users) — and unset values are questions: an
unset distribution is never treated as `web` and never answered by emitting every
track. Output: `production/releases/<version>/release-checklist.md` with
`> **Verdict**: GO | NO-GO | NOT ASSESSED` directly under its H1 (precedence NO-GO >
NOT ASSESSED > GO). `/rollout-plan`, `/team-release` and `/gate-check launch` read it.
The skill runs no command, deploys nothing and never reads a secret value.

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`); `name: release-checklist` equals the skill directory and the catalog `name`
- [ ] Bootstrap: the first body line is exactly `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys rigor,project.stage,distribution,surfaces,compliance,automation` `` and `allowed-tools` grants `Bash(bash "*/.claude/skills/release-checklist/../../hooks/yaml-helper.sh" resolve_config *)`
- [ ] `--keys` is exactly `rigor,project.stage,distribution,surfaces,compliance,automation` — no `review_mode`
- [ ] The line after the bootstrap block is exactly ``Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] Automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") present verbatim right after that line
- [ ] `allowed-tools` is exactly: `Read, Glob, Grep, Write, AskUserQuestion` plus the bootstrap grant — no `Bash`, `Edit` or `Agent`
- [ ] `argument-hint` is `"[version]"`
- [ ] 2+ phase headings found (`## Phase 0: Resolve the Version` … `## Phase 6: Next Steps`)
- [ ] Verdict keywords present, exactly: `GO`, `NO-GO`, `NOT ASSESSED`
- [ ] Reads `.claude/docs/templates/release-checklist-template.md` (no inline skeleton that could drift)
- [ ] Contains the omission lines `Stores: omitted — release.distribution is 'web'`, `Web: omitted — web is not in platform.surfaces` and `Regions: omitted — compliance.regions is [] (explicitly none)`
- [ ] "May I write this to `production/releases/<version>/release-checklist.md`?" before the only write
- [ ] Output at the exact path `production/releases/<version>/release-checklist.md` with `> **Verdict**:` directly under its H1
- [ ] No `!` injection other than the bootstrap line; no `file:line` citations of other files
- [ ] Next-step handoff present at end, naming current skills: `/rollout-plan`, `/release-notes`, `/launch-checklist`, `/team-release`, `/bug-triage`

---

## Director Gate Checks

- **N/A**: `/release-checklist` spawns no agent and no director gate, and
  `review_mode` is not among its keys. Its Sign-offs block records decisions made by
  the people who hold the roles (release owner; qa-lead, release-manager, tech-lead at
  `standard`; plus sre-engineer — and product-manager and security-engineer when their
  areas changed — at `full`); the production readiness review is run by
  `/rollout-plan`, which reads this file.

---

## Test Cases

Fixtures use the canonical product Moa (web + iOS + Android + API, Korean market).

### Case 1: Happy Path — Subsequent release 1.3.0 returns GO

**Fixture** (assumed project state):
- `project.yaml`: `project.stage: Launch`, `modes.rigor: standard`, `release.distribution: web+stores`, `platform.surfaces: [web, ios, android, api]`, `compliance.regions: [kr]`, `localization.locales: [ko-KR, en-US]`, `platform.min_os.ios` and `platform.min_os.android` set
- `production/releases/1.2.0/release-record.md` has `> **Verdict**: COMPLETED`
- Stories done since 1.2.0 include `production/epics/goals-core/story-001-create-goal.md` with `**Migration**` `docs/data/migrations/0003-goals-table.md` and `**Feature Flag**` `goals.v2-progress-ring`
- Newest reports on this release candidate: smoke PASS, QA sign-off APPROVED, security audit PASS, localization QA PASS; the migration plan's verdict is `SAFE` with Expand `applied-staging`; `production/releases/1.3.0/release-notes.md` exists

**Input**: `/release-checklist 1.3.0`

**Expected behavior**:
1. Phase 1 derives "subsequent release" from the completed 1.2.0 record, builds `## Scope` and confirms it with the user
2. Phase 2 reads each report's `> **Verdict**:` line and states denominators (`scanned 31 bug files: 0 unresolved S1, 0 unresolved S2`)
3. Phase 3 fills every block, including a Rollback Path per surface in Scope (web redeploy of the previous build with exact steps; mobile: halt the phased/staged rollout, server-side kill switch, expedited fixed build) and the `kr` items this release touches
4. The flag row records its production default and kill switch; config keys and secrets are listed by name and presence only
5. Phase 5 asks "May I write this to `production/releases/1.3.0/release-checklist.md`?"

**Assertions**:
- [ ] `> **Verdict**: GO` sits directly under the H1
- [ ] Every count states its denominator
- [ ] No secret value is read, printed or recorded
- [ ] Store items that depend on current policy say "verify in App Store Connect / Play Console at submission time" instead of stating the rule from memory
- [ ] The closing widget offers `/rollout-plan 1.3.0` and `/team-release 1.3.0`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — Rollback Path and other non-acceptable blockers

**Fixture**:
- Same as Case 1, except the Rollback Path for `api` says only "redeploy", and a Contract-phase migration ships while the supported iOS app version still reads the old column
- The user asks to accept both as exceptions

**Expected behavior**:
1. Both items are blockers
2. Phase 4 offers Fix / Accept / Leave for ordinary blockers, but refuses acceptance for these: an empty Rollback Path (or "redeploy" with no steps) and a Contract phase ahead of old readers are never acceptable
3. Verdict NO-GO

**Assertions**:
- [ ] Verdict is NO-GO at every rigor tier
- [ ] Neither item is recorded as an accepted exception
- [ ] An unresolved S1 bug or a smoke `FAIL` on the release candidate would be refused as exceptions the same way
- [ ] The file is written only after the "May I write" question

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: NOT ASSESSED — Unset distribution and no bug records

**Fixture**:
- `release.distribution` is absent (resolved line `release.distribution: (unset -- ask how this release ships)`); the user cannot answer
- `production/qa/bugs/` does not exist and the user does not name another tracker
- No other blocker

**Expected behavior**:
1. The Stores block reads `NOT ASSESSED — release.distribution unset`
2. The bug count reads `NOT ASSESSED — no bug records found` — never a bare `0`
3. Phase 4 offers "I'll provide the evidence now" / "Accept the gap — owner required" / "Leave it NOT ASSESSED"; the user leaves both
4. Verdict NOT ASSESSED; `## Decision` names each item and what would make it checkable

**Assertions**:
- [ ] Verdict is NOT ASSESSED — not GO while an in-scope item could not be checked
- [ ] Unset distribution is not treated as `web` and does not emit every store track
- [ ] An absent report is never a pass for the items it feeds
- [ ] A report whose own verdict is `NOT ASSESSED` is not read as passing either

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Mode Variant — `rigor: minimal`, web-only distribution

**Fixture**:
- `modes.rigor: minimal`, `release.distribution: web`, `platform.surfaces: [web, api]`, `compliance.regions: []`
- No `production/qa/qa-signoff-*.md`; no CI workflow file; the candidate was built locally

**Expected behavior**:
1. Observability is the reduced block (health endpoint, error tracking with the release tag, an error-rate and latency view); `docs/ops/slo.md` is not required
2. Sign-offs name the release owner only
3. The Stores block is the single line `Stores: omitted — release.distribution is 'web'`; Regions is `Regions: omitted — compliance.regions is [] (explicitly none)`
4. The Rollback Path is still required and filled
5. The QA sign-off item reads `N/A — QA sign-off not required at minimal`
6. The CI items of Build & CI Artifact read `N/A — CI workflow not configured (optional at minimal); built from <where>`; the tag, commit and immutable artifact IDs are still recorded

**Assertions**:
- [ ] The Rollback Path is never dropped at `minimal`
- [ ] Each omitted block keeps its heading with its one omission line
- [ ] Release notes are recommended (not required) without *Stores* at `minimal`
- [ ] A missing QA sign-off is N/A, not NOT ASSESSED
- [ ] No CI is not a "not built by CI" blocker at `minimal`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Edge Case — Surfaces and distribution disagree; enterprise distribution

**Fixture**:
- `platform.surfaces: [web, ios]` with `release.distribution: web`
- In a second run, `release.distribution: enterprise` for the iOS app

**Expected behavior**:
1. The contradiction (an `ios` surface with `web` distribution) is asked about — one of the two values is stale — rather than resolved by choosing
2. With `enterprise`, there is no public Stores block (one omission line) and the private distribution item of Build & CI Artifact applies (Apple Business Manager custom app, Managed Google Play private app or a customer-hosted package, customer admins told the change window)

**Assertions**:
- [ ] The Web block follows surfaces; the Stores block follows distribution
- [ ] A contradiction is surfaced to the user, not silently resolved
- [ ] `internal` distribution marks customer-facing items `N/A — internal distribution`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Edge Case — Evidence about another build; first public release smoke rule

**Fixture**:
- `project.stage: Hardening`; no completed release record exists (first public release)
- The newest smoke report is `PASS WITH WARNINGS` and predates the current release candidate

**Expected behavior**:
1. The skill says the smoke evidence is about a different build
2. On a first public release, `PASS WITH WARNINGS` is not a passing smoke verdict — `/gate-check launch` requires `PASS`
3. The first-submission store items (app records, content rating questionnaire, privacy policy URL) are included, and `/launch-checklist` is pointed to for launch readiness

**Assertions**:
- [ ] Stale evidence is named as stale, not counted
- [ ] The smoke item is not satisfied by PASS WITH WARNINGS on a first public release
- [ ] The closing reminder says `/gate-check launch` reads this file and requires GO with a rollback section

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses "May I write this to `<path>`?" before the one write this skill makes
- [ ] Confirms the Scope with the user before filling the blocks; every blocker and gap is the user's decision
- [ ] Ends with the closing `AskUserQuestion` offering the next skill
- [ ] Does not auto-create files without user approval; never commits
- [ ] Writes no evidence, reports or plans under `production/session-logs/`
- [ ] Never writes `modes.review_mode` or any other knob that `modes.rigor` fronts
- [ ] Runs no command, deploys nothing, runs no migration and reads no secret value

---

## Coverage Notes

- Regional items are selected from `.claude/docs/compliance/<region>.md` by what the
  release touches; a missing region file is `NOT ASSESSED — .claude/docs/compliance/<region>.md not found`.
  The legal substance of each item is not asserted here.
- Numbers such as deadlines or fines must carry `(Source: <url>, retrieved YYYY-MM-DD)`;
  that rule is asserted only through the regional block text.
- Updating an existing checklist for a new release candidate (Phase 0) needs a live
  re-run to verify the carried-over decisions.
