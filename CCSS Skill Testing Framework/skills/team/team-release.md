# Skill Spec: /team-release

> **Category**: team
> **Priority**: medium
> **Spec written**: 2026-09-28

## Skill Summary

Executes a release that has already been prepared: the release checklist says the
candidate is ready (`GO`), the rollout plan says how it is exposed stage by stage
(`READY TO ROLL OUT`), and this skill walks those stages with the release team,
recording every phase and stage in `production/releases/<version>/release-record.md`.
Phase 1 confirms scope and reads the release inputs; Phase 2 identifies the release
candidate and asks before setting `project.version`; Phase 3 runs the quality gate in
parallel (qa-lead, devops-engineer, security-engineer when the release touches sign-in,
payments or personal data); Phase 4 checks localization, guardrails and analytics;
Phase 5 makes the go/no-go recommendation; Phase 6 walks each rollout stage — every
stage a `production_deploys` decision that a human runs; Phase 7 closes the record. It
never runs a deploy, promotion, store submission, migration or production flag change
itself. The record's verdict line is `COMPLETED | HALTED | ROLLED BACK | NOT ASSESSED`; a
stop in Phase 1, before the record exists, ends the run NOT ASSESSED.
It spawns no director gate at any review mode.

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`); `name` is `team-release`, equal to the directory `.claude/skills/team-release/` and the catalog `name`
- [ ] Bootstrap: the first body line is `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,automation_always_ask,team.size,distribution` `` and `allowed-tools` grants `Bash(bash "*/.claude/skills/team-release/../../hooks/yaml-helper.sh" resolve_config *)`
- [ ] `--keys` is exactly `review_mode,automation,automation_always_ask,team.size,distribution`
- [ ] The line after the bootstrap block is exactly: ``Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] Automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") present verbatim right after that line
- [ ] `allowed-tools` is exactly: `Read, Glob, Grep, Write, Edit, Bash, Agent, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskUpdate` plus the bootstrap grant
- [ ] 2+ phase headings found (`## Phase 0: Resolve Config`, `### Phase 1: Release Planning` … `### Phase 7: Post-Release`)
- [ ] Verdict keywords present, exactly: `COMPLETED`, `HALTED`, `ROLLED BACK`, `NOT ASSESSED`; agents return `GO | NO-GO | NOT ASSESSED — <reason>`
- [ ] "May I write this to `production/releases/<version>/release-record.md`?" (Phase 1) and "May I write this to `project.yaml`?" for `project.version` (Phase 2, at every automation mode) appear before the corresponding writes
- [ ] Outputs at the exact paths: `production/releases/<version>/release-record.md` and `project.yaml` (`project.version` only — never `project.stage`); the record template has `> **Verdict**: [COMPLETED | HALTED | ROLLED BACK | NOT ASSESSED]` directly under its H1 `# Release Record: [version]`
- [ ] The record's headings are exactly `## Shipped`, `## Preflight`, `## Quality Gate`, `## Readiness Sign-offs`, `## Go/No-Go`, `## Rollout Stages`, `## Timeline`, `## Communications`, `## Outcome`, with timestamps in UTC and KST
- [ ] Contains verbatim: "Team skills spawn only the gates `.claude/docs/director-gates.md` § Gate Index lists this skill under (Spawned by column), after the review-mode check (lean suffix rule); team-size scoping never removes a director gate."
- [ ] States that the gate list is empty and the pipeline runs the same in `full`, `lean` and `solo`; the production readiness verdict is read from the rollout plan, not re-run
- [ ] Active set per `team.size` is listed (`individual`: `release-manager`; `small`: + `qa-lead`, `devops-engineer`, `sre-engineer`; `studio`: + `security-engineer`, `customer-success-manager`, `localization-lead`, `delivery-manager`, `analytics-engineer`) and announced before Phase 1
- [ ] States that every rollout stage is a `production_deploys` decision that prompts at every automation mode, and that a narrowed `automation_always_ask` list omitting it is announced and prompted anyway
- [ ] Has an Error Recovery Protocol section (a phase whose entries are not in the record is a failed phase) and a File Write Protocol section naming the two things the skill writes
- [ ] No `!` injection other than the bootstrap line; no `file:line` citations of other files
- [ ] Next steps name current skills: `/retrospective release <version>`, `/incident open`, `/hotfix`, `/postmortem <INC-id>`

---

## Director Gate Checks

- **Full mode**: no gate spawns — the skill's gate list is empty
- **Lean mode**: no gate spawns; the lean sentence ("skip every gate whose ID does not end in `-PHASE-GATE`") has nothing to skip
- **Solo mode**: no gate spawns
- **Review-mode exempt**: not applicable — `/team-release` resolves `review_mode`
- **N/A**: the production readiness review (SR-PRODUCTION-READINESS) belongs to `/rollout-plan`, which runs it at every review mode; Phase 1 reads the verdict that plan recorded under `## Production Readiness Review`

---

## Test Cases

Quoted prompts, option labels and verdict tokens below are the canonical English text
of `SKILL.md`; at run time the model renders them in the user's conversation language.

### Case 1: Happy Path — Moa 1.4.0 rolls out on web and stores

**Fixture** (assumed project state):
- `production/releases/1.4.0/release-checklist.md` has `> **Verdict**: GO`
- `production/releases/1.4.0/rollout-plan.md` has `> **Verdict**: READY TO ROLL OUT`, with production readiness READY under `## Production Readiness Review`
- `production/releases/1.4.0/release-notes.md` exists; `docs/CHANGELOG.md` has `## [1.4.0] - 2026-11-04`
- An earlier release record with `> **Verdict**: COMPLETED` exists (this is not the first public release)
- Resolved block: `release.distribution: web+stores (project.yaml)`, `team.size: small`, `review_mode: lean`, `automation: collaborative`

**Input:** `/team-release 1.4.0`

**Expected behavior:**
1. Phase 0 announces `Active set (team.size: small): release-manager, qa-lead, devops-engineer, sre-engineer.` and names the five `studio` agents as not spawned
2. Phase 1 reads each input's `> **Verdict**:` line, confirms the shipped PRD and story paths, and creates the record with `> **Verdict**: NOT ASSESSED` after "May I write this to `production/releases/1.4.0/release-record.md`?"
3. Phase 2 identifies the candidate (tag, commit, image digest, iOS build number, Android `versionCode`); the tag commands are prepared for a human; `project.version: 1.3.2 → 1.4.0` is shown and "May I write this to `project.yaml`?" asked
4. Phase 3: `qa-lead` and `devops-engineer` run in parallel; each returns its verdict line and an entry; the skill appends the entries one at a time after both returned
5. Phase 5: GO recommended; the user makes the call
6. Phase 6 walks the stages of the rollout plan (staging → web and API canary 5% → flag `goals.v2-progress-ring` 25% → 100% → iOS phased release and Android staged rollout); each stage prompt reads "Stage [N] of [M] — [what]. Run the steps above yourself, then tell me the result."; after "[A] Ran it — succeeded; start the dwell and record it", `sre-engineer` compares guardrails with halt thresholds
7. Phase 7 writes `## Outcome` and replaces the verdict line with `COMPLETED` after asking

**Assertions:**
- [ ] The release checklist verdict `GO` and the rollout plan verdict `READY TO ROLL OUT` are read before anything is recorded
- [ ] No deploy, tag push, store submission or flag change is executed by the skill — each is prepared as commands for a human
- [ ] Every Phase 6 stage prompts, with the stage owner from `## Go/No-Go per Stage` recorded as "Decided by"
- [ ] Parallel Phase 3 agents return entries; only this skill writes the record, one entry at a time, and re-reads it
- [ ] `project.version` is the only `project.yaml` key written, after asking; `project.stage` is never written
- [ ] The final record verdict is `COMPLETED`; the next step is `/retrospective release 1.4.0`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — Unresolved S1 bug makes it NO-GO

**Fixture:**
- Inputs as in Case 1 for version `1.5.0`
- `production/qa/bugs/BUG-0057.md` has `**Severity**: S1-Critical` and `**Status**: Fixed — Pending Verification` (auto-debit retried twice on timeout)

**Input:** `/team-release 1.5.0`

**Expected behavior:**
1. Phase 3: `qa-lead` counts unresolved bugs with the denominator ("scanned 58 bug files: 1 unresolved S1, 0 unresolved S2") and returns `qa-lead: NO-GO`
2. Phase 5 surfaces "GO/NO-GO: NO-GO — [rationale]" immediately
3. `AskUserQuestion`: fix the blocker and re-run the affected phase / defer the release / override NO-GO with documented rationale
4. Phase 6 is skipped entirely — no tag, no staging or production deploy, no store submission, `customer-success-manager` not spawned
5. The user defers: the record's verdict becomes `HALTED` (halted before Stage 1); a partial report covers Phases 1–5 and why Phase 6 was skipped

**Assertions:**
- [ ] `Fixed — Pending Verification` counts as unresolved (not only `Open`)
- [ ] The NO-GO names the bug and the quality-gate result
- [ ] Phase 6 does not run on NO-GO
- [ ] Deferral records `HALTED`; choosing to fix and re-run keeps `NOT ASSESSED`
- [ ] An override requires the user's written justification, embedded as "**Override Justification**:" in `## Go/No-Go` before Phase 6
- [ ] An override never covers a release checklist that is not `GO` or a rollout plan that is `NOT READY`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: NOT ASSESSED — Missing release inputs and unset distribution

**Fixture:**
- `production/releases/1.4.0/release-checklist.md` does NOT exist
- `production/releases/1.4.0/rollout-plan.md` does NOT exist
- No earlier `COMPLETED` release record; no `production/gate-checks/gate-launch-*.md`
- Resolved block prints `release.distribution: (unset -- ask how this release ships)`

**Input:** `/team-release 1.4.0`

**Expected behavior:**
1. Phase 0 asks how this release ships before Phase 1 — it never walks every track
2. Phase 1: the missing release checklist is a stop — "run `/release-checklist 1.4.0`"; nothing is deployed, no record is written, and the run verdict is NOT ASSESSED
3. Had the checklist been `GO`, the missing rollout plan would be asked about: `[A] Stop and run /rollout-plan (Recommended)` / `[B] Proceed as a single-stage release`, with [B] recorded as `NOT CHECKED — no rollout plan; single stage, rollback per the release checklist's Rollback Path`
4. For a first public release the absent gate record is reported as `Launch gate: NOT ASSESSED — no gate-check record found`, with the offer to run `/gate-check launch` first

**Assertions:**
- [ ] Unset `release.distribution` leads to a question, not to every track
- [ ] An absent release checklist stops the run and names `/release-checklist <version>`; the run verdict is NOT ASSESSED (a Phase 1 stop, before the record exists), never HALTED
- [ ] A missing rollout plan is never silently treated as single-stage — it is asked about and recorded with the NOT CHECKED line
- [ ] A missing launch gate record is NOT ASSESSED and is not treated as a pass

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Mode Variant — Autonomous automation, individual team, any review mode

**Fixture:**
- Inputs as in Case 1
- Resolved block: `automation: autonomous`, `automation_always_ask` lists `scope_changes, file_deletions, db_migrations` (no `production_deploys`), `team.size: individual`, `review_mode: full`

**Input:** `/team-release 1.4.0`

**Expected behavior:**
1. Phase 0 announces `release-manager` alone and names the other eight agents as not spawned, consulted through it
2. Phase 0 says the resolved always-ask list omits `production_deploys` and that every stage will prompt anyway
3. Phases advance without prompts where autonomous allows, but every Phase 6 stage prompts and the `project.version` write is asked
4. No gate spawns in `full` (nor would it in `lean` or `solo`)

**Assertions:**
- [ ] Every rollout stage prompts at `autonomous`, even with `production_deploys` missing from the list
- [ ] The `project.version` change (`version_bumps`) is asked at every automation mode
- [ ] The collapse to `release-manager` is announced
- [ ] The pipeline is identical at `full`, `lean` and `solo` — no gate is spawned

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Edge Case — Halt threshold crossed during the iOS phased release

**Fixture:**
- Release 1.4.0 in Phase 6, Stage 4: iOS phased release at 2%
- The rollout plan's halt threshold is crash-free sessions < 99.5%; the human reports 99.2%

**Input:** continuation of `/team-release 1.4.0`

**Expected behavior:**
1. `sre-engineer` compares the reading with the threshold after the dwell and reports the breach
2. `AskUserQuestion`: `[A] Roll back per the rollback plan (steps for a human)` / `[B] Hold at the current exposure and investigate — /incident open when users are affected` / `[C] Accept and continue — written justification required`
3. The skill states that a mobile binary cannot be rolled back: pause the phased release, turn the server-side kill switch off, ship a fixed build through `/hotfix`
4. A timeline entry is recorded, e.g. "2026-11-04 01:30 UTC / 10:30 KST — Stage 4: iOS phased release 2% → paused. …"
5. A rollback executed ends the release as `ROLLED BACK`; a stop at partial exposure ends it as `HALTED`

**Assertions:**
- [ ] The halt decision is the user's, offered with the three options
- [ ] Mobile "rollback" is described as pause + kill switch + fixed build, not a binary rollback
- [ ] Timeline entries are append-only, with UTC and KST
- [ ] The final verdict distinguishes `ROLLED BACK` (exposure reversed) from `HALTED` (stopped short, not reverted)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Security and localization readiness at `studio`

**Fixture:**
- Release 1.6.0 changes sign-in (Apple login added) and ships in `ko-KR` and `en-US` (`localization.locales: [ko-KR, en-US]`)
- `production/qa/localization-qa-*.md` for this release is missing; 12 strings of the new sign-in screen are untranslated in `en-US`
- Resolved `team.size: studio`

**Input:** `/team-release 1.6.0`

**Expected behavior:**
1. Phase 3 spawns `qa-lead`, `devops-engineer` and `security-engineer` in parallel (the release touches sign-in)
2. `security-engineer` checks the latest `production/security/security-audit-*.md` for open Critical or High findings, new dependency advisories and secrets in the diff
3. Phase 4 `localization-lead` reports the 12 untranslated strings and the missing localization QA report, and returns NO-GO for `en-US`
4. Phase 5 does not recommend GO while the locale gap is unresolved; the user fixes or explicitly waives it, and a waiver is recorded

**Assertions:**
- [ ] `security-engineer` is spawned when the release changes sign-in, payments or personal data — never silently skipped
- [ ] Localization completeness is checked against `localization.locales` read from `project.yaml`, with the count of missing strings
- [ ] With two or more locales, the localization QA report is required
- [ ] The skill never fabricates translations to unblock itself

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: Resume and No Argument

**Fixture (variant A):** `production/releases/1.4.0/release-record.md` has `> **Verdict**: NOT ASSESSED`; `## Rollout Stages` has three stages with decisions and a fourth without one

**Fixture (variant B):** no argument; `project.version: 1.4.0` in `project.yaml`

**Fixture (variant C):** no argument; no `project.version`, no milestone, no open record

**Input:** `/team-release 1.4.0` (A) · `/team-release` (B, C)

**Expected behavior:**
1. Variant A: resumes at the first stage row without a recorded decision; completed phases are not repeated unless the release candidate changed
2. Variant B: "No version argument provided — inferred 1.4.0 from project.version. Proceeding." then confirms with `AskUserQuestion`
3. Variant C: asks "What version should be released? (SemVer, e.g. 1.4.0)" — never a hard-coded version

**Assertions:**
- [ ] A record with a final verdict is closed: shipping again means a new version, and the skill asks
- [ ] An open record resumes where it stopped
- [ ] An inferred version is confirmed before proceeding; an undiscoverable one is asked for

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses "May I write this to `<path>`?" before creating the record and before changing `project.version`; later record additions are shown and approved through the phase or stage widget
- [ ] Presents each phase's findings before requesting a decision
- [ ] Ends with next steps (`/retrospective release <version>`; `/incident open`, `/hotfix`, `/postmortem <INC-id>` when production breaks)
- [ ] Does not auto-create files without user approval; spawned agents write nothing
- [ ] Never executes a production-changing command (deploy, promote, store upload, migration, production flag change); commands are handed to a human
- [ ] Writes no evidence, reports or plans under `production/session-logs/` (gitignored)
- [ ] Never writes `modes.review_mode` or any other knob that `modes.rigor` fronts, and never writes `project.stage`

---

## Coverage Notes

- The `next` argument (MAJOR / MINOR / PATCH proposed from `## [Unreleased]` in
  `docs/CHANGELOG.md`) is asserted by the skill text but not given a fixture.
- `enterprise` and `internal` distributions change which tracks the rollout walks; they
  follow the same stage mechanics as Case 1.
- Phase 7 post-release watching (24 and 72 hours per the rollout plan) is covered
  implicitly by Case 1; it has no blocking failure mode beyond `/incident open`.
