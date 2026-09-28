# Skill Spec: /hotfix

> **Category**: ops
> **Priority**: low
> **Spec written**: 2026-09-28

## Skill Summary

`/hotfix` runs the emergency path for a defect that is hurting users in
production. It takes a linked record — `BUG-NNNN` (`production/qa/bugs/`) or
`INC-YYYYMMDD-NN` (`production/incidents/`) — and an optional
`--surface web|api|ios|android`. It qualifies the severity, opens the record
`production/hotfixes/hotfix-YYYY-MM-DD-<slug>.md` before any fix, **mitigates
first** (a flag or kill switch, a revert through the normal pipeline, or a
server-side change — proposed as exact commands for a person), then investigates
and proposes the minimal fix, implements it only after approval with a regression
test, gets sign-off from `tech-lead` (plus `product-manager` when the fix is
customer-visible, `security-engineer` for security fixes) and a targeted
regression from `qa-engineer`, and hands the ship commands to a person: fix
forward on trunk through the expedited pipeline for web and API; a patch build
from the release tag, expedited store review and a phased release for iOS and
Android, with `release-manager` advising on the store path. `sre-engineer` verifies
in production; `delivery-manager` is informed.
The verdict is SHIPPED / MITIGATED — FIX PENDING / NOT ASSESSED. The skill is
always collaborative, review-mode-exempt and explicitly invoked only; it never
changes production itself. Hand-off: `/postmortem <INC-id>` when linked to an
incident, otherwise `/retrospective release <version>` for the release that shipped the
defect.

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`); `name: hotfix` equals the skill directory and the catalog `name`; `model: sonnet`
- [ ] `argument-hint` is `"<BUG-id | INC-id> [--surface web|api|ios|android]"`; frontmatter carries `disable-model-invocation: true` and no `isolation`
- [ ] Bootstrap: the first body line is `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys stack,code_roots,surfaces,distribution` `` and `allowed-tools` grants `Bash(bash "*/.claude/skills/hotfix/../../hooks/yaml-helper.sh" resolve_config *)`
- [ ] The line after the bootstrap block is exactly: ``Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] No automation prelude, and neither `automation` nor `review_mode` is among the keys (always collaborative, review-mode-exempt)
- [ ] `allowed-tools` is exactly: Read, Glob, Grep, Write, Edit, Bash, Agent, AskUserQuestion, plus the grant (membership exact, order free)
- [ ] 2+ phase headings found
- [ ] Verdict keywords present, exactly: `SHIPPED`, `MITIGATED — FIX PENDING`, `NOT ASSESSED`
- [ ] "May I write this to `production/hotfixes/hotfix-YYYY-MM-DD-<slug>.md`?" before each write of the record, and "May I implement this fix?" before any code change
- [ ] Outputs at the exact path `production/hotfixes/hotfix-YYYY-MM-DD-<slug>.md`; the record's H1 is followed, after one blank line, by `> **Verdict**: <TOKEN>`
- [ ] Severity tokens are exact: `S1-Critical`, `S2-Major`, `S3-Minor`, `S4-Trivial` for bugs and `SEV1`–`SEV4` for incidents
- [ ] Contains the review-mode exemption sentence verbatim (see Case 6)
- [ ] No `!` injection other than the bootstrap line; no `file:line` citations of other files
- [ ] Next-step handoff section present at end (Phase 10), naming skills by their current names

---

## Director Gate Checks

- **Review-mode exempt**: the skill contains "`/hotfix`, `/rollout-plan` and `/incident` are release-critical: every agent and gate they name runs at every `review_mode`. They do not resolve `review_mode`." Every agent it names — `sre-engineer`, `tech-lead`, `qa-engineer`, `security-engineer` (security fixes), `product-manager` (customer-visible fixes), `release-manager` (ios/android store path) — runs at every review mode.
- **N/A**: `/hotfix` spawns no director gate. Sign-offs are agent replies whose first line is `APPROVE`, `CONCERNS` or `REJECT`, not gate verdicts.

---

## Test Cases

### Case 1: Happy Path — web/API hotfix linked to an incident

**Fixture** (assumed project state):
- `production/qa/bugs/BUG-0042.md`: `**Severity**: S1-Critical`, `**Status**: Open` — creating a savings goal returns HTTP 500 for Plus users since release 2.4.0; surface `api`, `web`
- `production/incidents/INC-20261104-01.md`: `**Severity**: SEV2`, `**Status**: OPEN`, references BUG-0042
- `platform.surfaces: [web, ios, android, api]`; `release.distribution: web+stores`; `stack.layers.backend.root: apps/api`; `commands.test` and `commands.smoke` set
- `production/releases/2.4.0/rollout-plan.md` exists with a `## Rollback Plan`; flag `goals.v2-progress-ring` is the kill switch

**Expected behavior**:
1. Phase 1 confirms "The linked record is **S1-Critical** … Proceed as a hotfix?"
2. Phase 2 drafts the record (`> **Verdict**: NOT ASSESSED`, Linked, Severity, Surface, Opened in UTC and KST) and asks "May I write this to `production/hotfixes/hotfix-YYYY-MM-DD-goal-create-500.md`?"
3. Phase 3 spawns `sre-engineer` for ranked mitigations; turning `goals.v2-progress-ring` off is handed to a person, who runs it; sre-engineer verifies against guardrails; the incident gets timeline rows after "May I write this to `production/incidents/INC-20261104-01.md`?"
4. Phase 4 asks "Create branch `hotfix/goal-create-500` from `main`?", investigates in `apps/api`, presents the root cause and minimal change, and asks "May I implement this fix?"
5. Phase 5 adds a regression test and runs the targeted tests; Phase 6 spawns `tech-lead` and `qa-engineer` in parallel — both `APPROVE`; `/smoke-check` PASS
6. Phase 7 asks "Hotfix approved and verified. Hand over the ship commands?" and hands over PR → merge to trunk → staging → compressed canary → 100%
7. Phase 8: sre-engineer confirms the defect is gone; BUG-0042 gets a `## Fix Record` and `**Status**: Fixed — Pending Verification` after "May I write"
8. Verdict SHIPPED; the closing widget recommends `/postmortem INC-20261104-01`

**Assertions**:
- [ ] The record is opened before any fix, and every later update asks "May I write" again
- [ ] Mitigation comes before the fix, and the mitigation command is run by a person — the skill never runs it
- [ ] No code changes before "May I implement this fix?" is approved; the change is minimal (no refactoring, no cleanup, no feature work)
- [ ] The sign-off agents are spawned in one parallel batch and every required sign-off is `APPROVE` before shipping
- [ ] The fix is confirmed on trunk (`git branch --contains <sha>`) and the result stated in `## Trunk & Release Branches`
- [ ] The bug moves to `Fixed — Pending Verification`, not `Verified Fixed`; confirmation goes through `/bug-report verify BUG-0042`
- [ ] Final record verdict line reads `> **Verdict**: SHIPPED`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — security fix rejected at sign-off

**Fixture**:
- `production/qa/bugs/BUG-0051.md`: `**Severity**: S1-Critical` — `GET /v1/goals/{id}` returns another user's goal (BOLA)
- Mitigation already recorded in `production/incidents/INC-20261110-01.md`
- The proposed fix checks ownership in one handler only; `tech-lead` replies `REJECT` (two other handlers share the flaw); `security-engineer` replies `CONCERNS`

**Expected behavior**:
1. Phase 1 flags the security defect: `security-engineer` joins Phase 3 and Phase 6; exploit details stay out of commit messages, release notes and customer messages
2. Phase 6: `REJECT` ⇒ the skill does not ship and returns to Phase 4
3. `CONCERNS` from security-engineer is shown with `Revise` / `Accept and proceed` / `Discuss further`

**Assertions**:
- [ ] No ship commands are handed over after a `REJECT`
- [ ] The offered commit message (conventional `fix:` with the BUG ID in the body) contains no exploit details
- [ ] The skill does not merge, deploy or commit on its own; committing is the user's decision
- [ ] The verdict is never `SHIPPED` while the rejected fix is not live; with the mitigation holding, the record may close as `MITIGATED — FIX PENDING`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: NOT ASSESSED — the verification never ran

**Fixture**:
- As Case 1, but `commands.smoke` is unset and the targeted test run cannot start; `qa-engineer` recommends a smoke check, and `/smoke-check` returns `NOT ASSESSED` (the suite never executed)
- The user decides to ship anyway; after the person runs the commands, post-deploy guardrail data is unavailable

**Expected behavior**:
1. Phase 5 reports the targeted tests as a `NOT CHECKED — <reason>` line, never a pass
2. Phase 6 treats the QA `NOT ASSESSED` as unmet and puts the decision to the user explicitly: shipping an unverified hotfix, recorded in `## Verification`
3. Phase 8 cannot confirm the defect is gone
4. Verdict NOT ASSESSED, naming the missing verification

**Assertions**:
- [ ] Verdict is NOT ASSESSED, with the reason stated (QA returned NOT ASSESSED; post-deploy evidence unavailable)
- [ ] No SHIPPED verdict is produced for an unverified fix
- [ ] A `NOT ASSESSED` QA result is never read as a pass; the user's decision to ship anyway is written in the record
- [ ] With `code_roots: unresolved` (variant), the skill prints `NOT CHECKED — no code root resolved (set stack.layers.<layer>.root via /setup-stack)`, writes no code and still keeps the record

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Mode Variant — iOS patch build from the release tag

**Fixture**:
- `production/incidents/INC-20261104-02.md`: `**Severity**: SEV1` — the iOS app 2.4.0 crashes on launch for users with a linked bank account
- `release.distribution: web+stores`; `platform.surfaces: [web, ios, android, api]`

**Input**: `/hotfix INC-20261104-02 --surface ios`

**Expected behavior**:
1. Phase 3 mitigates on the server immediately — a flag or remote configuration to switch off the failing feature for 2.4.0, or an API compatibility shim — because installed binaries cannot be rolled back
2. Phase 4 asks to create `hotfix/2.4.1-<slug>` from the tag `v2.4.0`
3. Phase 7 spawns `release-manager` for store-path advice, then hands over: bump the patch version and build number (`CFBundleVersion` always increases), TestFlight smoke, submission with expedited review, phased release or release to all — the user's decision, recorded with the reason
4. While the build awaits store review, the verdict is MITIGATED — FIX PENDING

**Assertions**:
- [ ] Mitigation for iOS acts on the server; a force-update prompt is offered only as a last resort once the patched build is live
- [ ] The branch is cut from the release tag users have, and merging back into trunk is verified or written `NOT VERIFIED — <what was not checked>`
- [ ] Store submission is a command for a person; the skill never submits a build
- [ ] `release-manager` is consulted on the store path; a person submits the build
- [ ] Verdict is `MITIGATED — FIX PENDING` until the fix is live and verified; the closing widget offers `/hotfix INC-20261104-02` again and `/incident update INC-20261104-02`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Edge Case — not a hotfix, or nothing to link

**Fixture A**:
- `production/qa/bugs/BUG-0060.md`: `**Severity**: S3-Minor`

**Fixture B**:
- `/hotfix` with no argument

**Fixture C**:
- `production/qa/bugs/BUG-0061.md`: `**Severity**: S2-Major`, no surface in its environment block; `platform.surfaces` unset

**Expected behavior**:
1. A: the qualify question offers `No — use the normal flow`; on it the skill stops with "Not a hotfix — use `/bug-triage` to schedule it, then `/dev-story`." and writes no record
2. B: the skill asks `Users are affected right now — /incident open first (Recommended)` / `No active incident — /bug-report first` / `Stop`
3. C: the skill asks which surfaces are affected

**Assertions**:
- [ ] An S3-Minor or S4-Trivial bug is routed to the normal flow and no hotfix record is written
- [ ] A hotfix always links a record; without one nothing is written
- [ ] Unset `platform.surfaces` is never read as "all surfaces"; the skill asks
- [ ] Unset `release.distribution` (for a mobile path) is asked, never assumed

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Review-Mode Exemption — sign-offs run in solo mode

**Fixture**:
- As Case 1
- Review mode: `solo` in `project.yaml` (`modes.review_mode: solo`)

**Expected behavior**:
1. The skill does not resolve `review_mode`
2. `sre-engineer`, `tech-lead` and `qa-engineer` all run; nothing is skipped for the mode

**Assertions**:
- [ ] SKILL.md contains verbatim: "`/hotfix`, `/rollout-plan` and `/incident` are release-critical: every agent and gate they name runs at every `review_mode`. They do not resolve `review_mode`."
- [ ] `review_mode` is not among the skill's `--keys`
- [ ] tech-lead sign-off and the qa-engineer regression run despite `solo`; no `[GATE-ID] skipped — Solo mode` note appears

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: Always Collaborative — autonomous mode changes nothing

**Fixture**:
- As Case 1; `project.yaml` sets `modes.automation: autonomous`

**Expected behavior**:
1. The skill carries no automation prelude and never resolves `modes.automation`
2. Every question and every write is asked, including "May I implement this fix?" and the Phase 7 STOP: "Hotfix approved and verified. Hand over the ship commands?"
3. Production-changing steps — merging to trunk (which deploys), promoting a deploy, a production flag change, a migration, a store submission — are handed to a person as commands

**Assertions**:
- [ ] SKILL.md states that the skill is always collaborative, and `automation` is not among the keys
- [ ] The Phase 7 confirmation holds "whatever `modes.automation` and `modes.review_mode` say"
- [ ] The skill never executes a production-mutating command (e.g. `vercel --prod`, `kubectl apply`, `eas submit`, `fastlane deliver` — all on the settings deny list); it proposes each with expected result and rollback
- [ ] No commit is made without the user's instruction

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 8: Hand-off — a hotfix not linked to an incident

**Fixture**:
- `production/qa/bugs/BUG-0057.md`: `**Severity**: S2-Major` — the monthly goal summary email shows last month's balance; web only; no incident references it
- `production/releases/2.4.0/release-record.md` exists (written by `/team-release` for the release that shipped the defect)
- The hotfix record carries `> **Release**: 2.4.0 → 2.4.1`; the fix ships as release 2.4.1; verdict SHIPPED

**Expected behavior**:
1. Phase 0 greps `production/incidents/` for BUG-0057 and finds no linked incident
2. Phase 10 offers `/retrospective release 2.4.0` (the version that shipped the defect), `/bug-report verify BUG-0057`, and `/changelog 2.4.1` then `/release-notes 2.4.1` — or `/release-notes 2.4.1` alone when `docs/CHANGELOG.md` already has `## [2.4.1]`

**Assertions**:
- [ ] The recommended hand-off is `/retrospective release <version>`, not `/postmortem`, when no incident is linked
- [ ] With a linked incident (Case 1), the recommended hand-off is `/postmortem <INC-id>`
- [ ] The next step is offered, never taken

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses "May I write this to `<path>`?" before every write — the hotfix record, the bug file, the incident record — and "May I implement this fix?" before any code change
- [ ] Presents the mitigation options, the root cause and the proposed change before requesting approval
- [ ] Ends with a recommended next step (`/postmortem <INC-id>` when linked, else `/retrospective release <version>`)
- [ ] Does not auto-create files without user approval
- [ ] Writes no evidence, reports or plans under `production/session-logs/` (gitignored)
- [ ] Never writes `modes.review_mode` or any other knob that `modes.rigor` fronts (`/settings` is the one exception)
- [ ] Never executes a command that changes production, shared infrastructure, a shared database or secrets

---

## Coverage Notes

- A hotfix inside an ongoing staged rollout (record the halted stage and how it
  resumes) is not fixture-tested.
- Android (`versionCode`, Play staged rollout) follows the iOS path of Case 4.
- The escalation to `technical-director` for a fix larger than about four hours of
  work is not tested.
- Enterprise or internal distribution channels (the channel's own update path,
  asked for) are not tested.
