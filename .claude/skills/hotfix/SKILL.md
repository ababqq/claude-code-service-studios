---
name: hotfix
description: "Emergency fix: mitigate first (flag, revert or server-side), fix forward on trunk or patch the store build, verify, record, link the incident."
argument-hint: "<BUG-id | INC-id> [--surface web|api|ios|android]"
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/hotfix/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys stack,code_roots,surfaces,distribution`

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.

> **Explicit invocation only**: This skill runs only when the user types `/hotfix`. Do not start it because a bug is
> being discussed.

# Hotfix

A defect is hurting users in production and cannot wait for the next sprint. This skill runs the emergency path
without skipping the parts that keep an emergency from becoming a second one: **mitigate first** (a flag, a revert or
a server-side change stops the harm), then the **minimal fix**, approved before it is written, reviewed and verified,
shipped through the fastest safe route for the surface — fix forward on trunk for web and API, a patch build from the
release tag for iOS and Android — and a record that links the bug or incident, the mitigation, the fix, the approvals
and the verification.

**The skill writes code and records; people change production.** Merging to trunk (which deploys), promoting a
deploy, changing a production flag, running a migration and submitting a store build are `production_deploys` and
`db_migrations` actions: the skill prepares the exact commands and a person runs them. The project's settings deny
list blocks the common deploy, infrastructure and store-submission commands for agents anyway.

**Always collaborative.** Every question is asked and every write is approved, whatever `modes.automation` says — a
production emergency is listed among the exemptions in `.claude/docs/automation-modes.md`.

**Review-mode exemption.** `/hotfix`, `/rollout-plan` and `/incident` are release-critical: every agent and gate they name runs at every `review_mode`. They do not resolve `review_mode`.

### When this path applies

| Linked record | Hotfix path | Otherwise |
|---|---|---|
| Bug `production/qa/bugs/BUG-NNNN.md` with `**Severity**: S1-Critical` or `S2-Major` | yes | `S3-Minor` / `S4-Trivial` ⇒ the normal flow (`/bug-triage`, then `/dev-story`) |
| Incident `production/incidents/INC-YYYYMMDD-NN.md` with `**Severity**: SEV1` or `SEV2` | yes | `SEV3` ⇒ usually the normal flow — ask; `SEV4` ⇒ the normal flow |

### Output

| Path | Written |
|---|---|
| `production/hotfixes/hotfix-YYYY-MM-DD-<slug>.md` | Phase 2 (opened), updated through Phase 9 |

`YYYY-MM-DD` is the date the hotfix is opened; `<slug>` is a short kebab-case name (`goal-create-500`). The Launch
`hotfix` step finds records through `production/hotfixes/hotfix-*.md`. With approval, the skill also updates the
linked bug file's fix record and appends timeline rows to the linked incident record.

### Verdicts

`SHIPPED` · `MITIGATED — FIX PENDING` · `NOT ASSESSED`

- `SHIPPED` — the fix is live on every affected surface (deployed to production for web/API; released to users for
  iOS/Android), post-deploy verification shows the defect gone, and the fix is on trunk.
- `MITIGATED — FIX PENDING` — users are protected by the mitigation, but the permanent fix is not live yet (awaiting
  store review, awaiting its phased release, scheduled as a follow-up) or is live without its verification complete.
- `NOT ASSESSED` — the outcome could not be verified: no mitigation or fix is confirmed in production, the QA step
  returned `NOT ASSESSED` and the user decided to ship anyway, or post-deploy evidence is unavailable.

### Agents

| Agent | Role | When |
|---|---|---|
| `sre-engineer` | Mitigation options with exact commands, guardrails for the fix's rollout, post-deploy verification | every run |
| `tech-lead` | Sign-off: correctness, side effects, minimality | every run |
| `qa-engineer` | Targeted regression, the regression test for the defect, QA scope for the release | every run |
| `security-engineer` | Review of the fix and the disclosure; containment | security fixes |
| `product-manager` | Sign-off on customer-visible behaviour changes | when the fix is customer-visible |
| `release-manager` | Store-path advice for the patch build: patch version and build number, expedited review, phased release or release to all, merging the tag branch back to trunk | ios / android hotfixes (Phase 7) |

All run at every review mode. `delivery-manager` is **informed** — the record's `## Approvals` names it with the
sprint impact — and is not asked to approve.

---

## Phase 0: Parse Arguments and Resolve Context

1. **Linked record.** The argument is `BUG-NNNN` or `INC-YYYYMMDD-NN`.
   - `BUG-NNNN` ⇒ read `production/qa/bugs/BUG-NNNN.md` (`**Severity**:`, `**Status**:`, reproduction steps,
     environment block, surface). Grep `production/incidents/` for the bug ID to find a linked incident.
   - `INC-YYYYMMDD-NN` ⇒ read `production/incidents/<INC-id>.md` (`**Severity**:`, `**Status**:`,
     `## Customer Impact`, `## Mitigation`, `## Timeline`).
   - No argument or no such file ⇒ ask: `Users are affected right now — /incident open first (Recommended)` /
     `No active incident — /bug-report first` / `Stop`. A hotfix always links a record; without one there is nothing
     to verify against.
2. **Surface.** `--surface` when given; else the bug's environment block or the incident's `## Customer Impact`
   surfaces, checked against the resolved `platform.surfaces` line. Several surfaces ⇒ each gets its own path in
   Phase 3 and Phase 7. `platform.surfaces` unset and nothing in the record ⇒ ask; never assume all surfaces.
3. **Distribution.** The ios/android path needs *Stores* (`release.distribution` ∈ `stores`, `web+stores`);
   `enterprise` or `internal` ⇒ the distribution channel's own update path (managed app store, internal track), asked
   for. Unset ⇒ ask how this release ships.
4. **Stack and code roots.** The resolved `stack` line tells which layer the defect lives in; the `code_roots` line
   tells where its code is. `code_roots: unresolved` ⇒ print
   `NOT CHECKED — no code root resolved (set stack.layers.<layer>.root via /setup-stack)`: the skill writes no code
   (Phases 4–5 become a written proposal for a person to implement) and still keeps the record. A `WARN: undeclared
   code roots` line ⇒ include those roots in the search and repeat the warning.
5. **Project facts read with Read** from `project.yaml`: `project.version` (the version being patched — with the
   linked record's environment block, it fills the record's `**Release**` line),
   `commands.test` and `commands.smoke` (targeted verification), `testing.patterns` (where the regression test goes),
   `platform.min_os.*` (mobile), and the `stack.layers` entries for the affected layer.
6. **Git.** `git rev-parse --is-inside-work-tree` — not a repository ⇒ note "Not a git repository — branch and merge
   steps are manual" and continue.

---

## Phase 1: Qualify

State the severity from the linked record and the rationale (see "When this path applies"). Confirm:

- Prompt: "The linked record is **[S1-Critical / S2-Major / SEVn]** — [one-line impact]. Proceed as a hotfix?"
- Options: `Yes — S1-Critical / SEV1` / `Yes — S2-Major / SEV2` / `No — use the normal flow`

"No" ⇒ stop without writing a record: "Not a hotfix — use `/bug-triage` to schedule it, then `/dev-story`."

A security defect (authorization bypass, injection, exposed data, leaked secret) is flagged now: `security-engineer`
joins Phase 3 and Phase 6, and exploit details stay out of every public text (commit message, release notes,
customer messages) until the fix is live.

---

## Phase 2: Open the Record

Draft the record — before any fix, so the audit trail starts with the emergency, not after it:

```markdown
# Hotfix: [short description of what users experience]

> **Verdict**: NOT ASSESSED
> **Linked**: [BUG-NNNN] [INC-YYYYMMDD-NN]
> **Severity**: [S1-Critical / S2-Major] [SEV1 / SEV2]
> **Surface**: [web / api / ios / android]
> **Release**: [version that shipped the defect] → [patch version | none — fix forward on trunk without a version]
> **Opened**: [YYYY-MM-DD HH:MM UTC] ([HH:MM KST])

## Problem
[What is broken and for whom — from the linked record; no personal data]

## Mitigation
[Option chosen, command a person ran, when, verified by what — or "none needed — <reason>"]

## Root Cause
[To be filled in Phase 4]

## Fix
[To be filled in Phase 5 — files changed, what the change does, what it deliberately leaves alone]

## Verification
[Tests run, regression test added, QA scope and result, post-deploy checks]

## Approvals
- [ ] tech-lead — correctness, side effects, minimality
- [ ] qa-engineer — targeted regression
- [ ] security-engineer — (security fixes only)
- [ ] product-manager — (customer-visible changes only)
- Informed: delivery-manager — [sprint impact]

## Rollout & Rollback
[Route per surface, stages, guardrails, rollback per stage — commands for a person]

## Trunk & Release Branches
[Where the fix is: trunk / release branch / hotfix branch — verified, or NOT VERIFIED with what was not checked]

## Follow-ups
[Bug verification, incident update, postmortem, tech debt]
```

Get the time for the record with `date -u '+%Y-%m-%d %H:%M'` and `TZ=Asia/Seoul date '+%H:%M'`. Ask: "May I write
this to `production/hotfixes/hotfix-YYYY-MM-DD-<slug>.md`?" — creating the directory if needed.

---

## Phase 3: Mitigate First

Stop the harm before fixing the cause. Spawn `sre-engineer` (and `security-engineer` for a security defect) with the
record path, the linked record, the surface, and the current rollout plan
`production/releases/<version>/rollout-plan.md` (its `## Rollback Plan`) when one exists. Ask for ranked options,
each with the exact command or console action **for a person**, blast radius, expected result and undo.

**web / api**

1. **Kill switch or flag off** (e.g. turn `goals.v2-progress-ring` off) — fastest, narrowest.
2. **Revert through the normal pipeline** — revert the offending commit on trunk and let CI/CD deploy it, or redeploy
   the previous release artifact per the rollout plan's `## Rollback Plan`. Never a hand-edited production server.
3. **Server-side containment** — rate-limit or disable the failing operation, degrade a failing integration, scale.

**ios / android** — installed binaries cannot be rolled back; mitigate **on the server, immediately**:

1. **Flag or remote configuration** to switch off the failing feature for affected app versions.
2. **API compatibility** — serve the response shape the affected app versions expect (a compatibility shim on the
   server) until the patched build is adopted.
3. **Force-update prompt** for affected versions — a last resort, once the patched build is live in the store.

If mitigation already happened in `/incident`, record what was done and skip to Phase 4. Otherwise ask which option a
person should run, hand over the command block, and wait — **do not run it**. When the person confirms it ran, have
sre-engineer check the result against the expected output and the guardrail metrics. Update `## Mitigation`; for a
linked incident, also draft the timeline rows. Ask: "May I write this to
`production/hotfixes/hotfix-YYYY-MM-DD-<slug>.md`?" and, for the incident, "May I write this to
`production/incidents/<INC-id>.md`?"

With users protected, the fix can be done carefully rather than fast.

---

## Phase 4: Branch, Investigate and Propose

**Branch** (ask before creating it):

- **web / api** — a short-lived branch from trunk: `hotfix/<slug>` from `main` (or the trunk branch the project
  uses). The fix goes forward through trunk; there is no separate production branch to patch.
- **ios / android** — a branch from the tag of the release users have: `hotfix/<patch-version>-<slug>` from
  `v<version>` (e.g. `hotfix/2.4.1-goal-create-500` from `v2.4.0`), so the patch build contains only the fix.

- Prompt: "Create branch `hotfix/<name>` from `<base-ref>`?"
- Options: `Yes — create the branch` / `Use a different base ref` / `Skip — I'll create it myself`

Only on "Yes" run `git switch -c hotfix/<name> <base-ref>` (or with the base the user gives).

**Investigate** within the resolved code roots: reproduce from the linked record's steps, read the code path, the
recent commits touching it (`git log -p -- <path>`), and the release record of the version that introduced it. Draft
the minimal fix: which files change, what the change does, what it deliberately leaves alone. **No refactoring, no
cleanup, no feature work** alongside a hotfix — each extra line is extra risk shipped under time pressure.

Present the root cause and the proposed change, then ask: "May I implement this fix?" **Do not modify any code before
this approval** — an emergency flow earns its audit trail by approving the change before it exists, not after. For a
security fix, security-engineer reviews the approach before implementation.

If the fix needs more than about four hours or touches architecture, say so: keep the mitigation in place, escalate
to `technical-director` through the user, and consider recording `MITIGATED — FIX PENDING` with the fix planned
through the normal flow.

---

## Phase 5: Implement

After approval only:

1. Make the approved minimal change.
2. Add a **regression test** that fails without the fix and passes with it, at the level the defect lives (unit,
   integration, contract or E2E), following `testing.patterns`.
3. Run the targeted tests — `commands.test` scoped to the affected module, and `commands.smoke` when set. Report the
   results as observed; a test that could not run is a `NOT CHECKED — <reason>` line, never a pass.
4. Update `## Root Cause`, `## Fix` and `## Verification` in the record. Ask: "May I write this to
   `production/hotfixes/hotfix-YYYY-MM-DD-<slug>.md`?"

Committing is the user's decision: offer the commit message (conventional `fix:` with the BUG or INC ID in the body;
no exploit details for a security fix) and commit only when the user says so.

---

## Phase 6: Review, Sign-off and QA

Spawn in parallel (issue every `Agent` call before waiting), each with the record path, the diff and the test
results; ask each to start its reply with `APPROVE`, `CONCERNS` or `REJECT` on the first line:

- `tech-lead` — correctness, side effects, minimality, that the regression test proves the fix.
- `qa-engineer` — run or specify the targeted regression for the affected journey and adjacent ones (use Grep to
  list callers of the changed code), and recommend the QA scope: **smoke check sufficient** (`/smoke-check`) or a
  **targeted QA pass** (`/team-qa` scoped to the affected feature).
- `security-engineer` — security fixes only: the fix closes the hole, the disclosure plan, secrets to rotate (by a
  person).
- `product-manager` — only when users will see a behaviour change: the change is acceptable and the customer message
  is right.

Every required sign-off must be `APPROVE` before shipping. `CONCERNS` ⇒ show them and ask: `Revise` / `Accept and
proceed` / `Discuss further`. `REJECT` ⇒ do not ship; return to Phase 4.

**QA re-entry.** Run the scope qa-engineer recommended — `/smoke-check`, or a targeted `/team-qa` pass. **If the QA
step returns `NOT ASSESSED`, it did not run — treat it as unmet, not as met.** `/smoke-check` returns it when the
suite never executed and `/team-qa` when a cycle produced no executed evidence. A `NOT ASSESSED` result is not a pass
from either skill, and under time pressure the permissive reading is the one that will feel reasonable — which is
exactly why it is written down here. Either obtain the missing result (the verdict names what would make it
runnable) or take the decision to the user explicitly, as a decision to ship an unverified hotfix, recorded in
`## Verification` — never as a gate that quietly cleared.

Tick the approvals in the record. Ask: "May I write this to `production/hotfixes/hotfix-YYYY-MM-DD-<slug>.md`?"

---

## Phase 7: Ship — Commands for a Person

> **STOP — shipping is a person's action, and it is confirmed explicitly, unconditionally.** Merging to trunk
> deploys; submitting a build reaches every user who updates. Before handing over the commands, use
> `AskUserQuestion`:
>
> - Prompt: "Hotfix approved and verified. Hand over the ship commands?"
> - Options: `Yes — give me the commands` / `Hold — keep the mitigation, ship later` / `Stop here`
>
> This holds whatever `modes.automation` and `modes.review_mode` say.

Draft the route per surface into `## Rollout & Rollback`, with each command, its expected result and its rollback:

**web / api — fix forward through the expedited pipeline**

1. Push the branch and open a pull request; fast review by the tech-lead who signed off.
2. Merge to trunk; CI runs the full required checks — an expedited pipeline shortens waits, never skips tests.
3. Deploy through the normal pipeline to staging, smoke, then production with compressed canary stages from the
   current rollout plan (e.g. 5% for 10 minutes, then 100%) and the same guardrails.
4. Remove the mitigation (flag back on, compatibility shim scheduled for removal) only after Phase 8 verification.

**ios / android — patch build from the release tag**

Spawn `release-manager` for the store path; it advises, a person submits.

1. Bump the patch version and the build number (`CFBundleVersion` / `versionCode` always increase).
2. Build from the hotfix branch; smoke on TestFlight / the internal testing track.
3. Submit for review, requesting expedited review where the store offers one; the server-side mitigation stays in
   place during review.
4. Choose the release: phased release / staged rollout, or release to all users at once when the defect is severe and
   the fix is small — the user's decision, recorded with the reason.
5. Keep the server mitigation until adoption of the patched version is high enough; the force-update prompt for
   affected versions is the last resort.

For a hotfix inside an ongoing rollout, record the stage the rollout was halted at and how it resumes.

**Trunk and release branches — not verified unless you verify it.** After the merge, confirm the fix commit is on
trunk and on every open release branch or tag line that still ships (`git branch --contains <sha>`, `git tag
--contains <sha>`), and state the result in `## Trunk & Release Branches`. A mobile hotfix branched from a tag must be
merged back into trunk; a fix that is not on trunk comes back in the next release — the most common hotfix
regression. Anything not checked is written `NOT VERIFIED — <what was not checked>`.

---

## Phase 8: Verify in Production

When the person confirms the ship commands ran:

1. **Guardrails.** Spawn `sre-engineer` to check the guardrail metrics and the SLI of the affected journey for the
   watch window, on each shipped surface.
2. **The defect is gone.** Update the linked bug file with a fix record and move its status — ask: "May I write this
   to `production/qa/bugs/BUG-NNNN.md`?"

   ```markdown
   ## Fix Record
   **Fixed in**: [hotfix/<name> — commit <sha>; release <patch-version>]
   **Fixed date**: [YYYY-MM-DD]
   **Hotfix record**: production/hotfixes/hotfix-YYYY-MM-DD-<slug>.md
   ```

   and set `**Status**: Fixed — Pending Verification` in its header. Confirmation of the fix goes through
   `/bug-report verify BUG-NNNN` (outcome `Verified Fixed`, then `/bug-report close BUG-NNNN`; `Still Present` ⇒
   re-open the hotfix, keep or restore the mitigation, escalate).
3. **Incident.** For a linked incident, draft the timeline rows (fix shipped, verified) — ask before writing to
   `production/incidents/<INC-id>.md` — and point to `/incident resolve <INC-id>` when recovery is verified.

---

## Phase 9: Verdict and Record

Set the verdict (Verdicts section): `SHIPPED`, `MITIGATED — FIX PENDING` or `NOT ASSESSED`, with the reasons —
surfaces live, verification evidence, trunk status. Complete `## Follow-ups` (bug verification, incident resolution,
postmortem, flag or shim removal, tech debt the minimal fix left behind) and ask: "May I write this to
`production/hotfixes/hotfix-YYYY-MM-DD-<slug>.md`?"

Print a summary:

```
## Hotfix: <slug>

Verdict:      <SHIPPED | MITIGATED — FIX PENDING | NOT ASSESSED>
Linked:       <BUG-NNNN> <INC-YYYYMMDD-NN>
Mitigation:   <what protects users, and whether it is still on>
Fix:          <one line> — surfaces: <web/api/ios/android>, release <patch-version>
QA:           <smoke PASS | targeted QA APPROVED | NOT ASSESSED — whose decision it was to ship>
Approvals:    tech-lead <✓> · qa-engineer <✓> · security-engineer <✓ | n/a> · product-manager <✓ | n/a>
Trunk:        <verified on trunk and release lines | NOT VERIFIED — what was not checked>
Informed:     delivery-manager — <sprint impact>
```

### Rules

- The hotfix is the **minimum** change that fixes the defect — no cleanup, no refactoring, no features.
- Mitigation comes first; the rollback path is written down before anything ships.
- The fix always lands on trunk; mobile fixes are also built from the release tag.
- Every SEV1/SEV2 incident behind a hotfix gets a blameless postmortem.
- A fix larger than about four hours of work, or one that touches architecture, is escalated to
  `technical-director` while the mitigation holds.

---

## Phase 10: Close

Close with `AskUserQuestion`, offering only what applies:

- linked to an incident: `/postmortem <INC-id>` (recommended for SEV1/SEV2) · `/incident resolve <INC-id>` (when the
  incident is not resolved yet) · `/bug-report verify BUG-NNNN` · stop here;
- not linked to an incident: `/retrospective release <version>`, where `<version>` is the release that shipped the
  defect (the record's `**Release**` line), not the patch — release mode requires
  `production/releases/<version>/release-record.md`, which `/team-release` wrote for that release, and reads this
  record as a hotfix referencing that version; a patch version has a release record only if it went through
  `/team-release`. Glob for the record first; none ⇒ still offer it, saying the retrospective will ask for the release
  data by hand · `/bug-report verify BUG-NNNN` · when the fix shipped as a patch version, `/changelog <patch-version>`
  then `/release-notes <patch-version>` — release notes are written from the `## [<patch-version>]` section of
  `docs/CHANGELOG.md`, so offer `/release-notes` alone only when that section already exists · stop here;
- verdict `MITIGATED — FIX PENDING`: `/hotfix <BUG-id | INC-id>` again when the fix can ship · `/incident update
  <INC-id>` · stop here.

---

## Collaborative Protocol

1. **Question → Options → Decision → Draft → Approval** at every step, compressed for an emergency but never skipped.
2. **"May I write this to `<path>`?"** before every write — the hotfix record, the bug file, the incident record —
   and **"May I implement this fix?"** before any code changes.
3. **People change production.** Merges that deploy, production flag changes, migrations and store submissions are
   commands handed to a person; the skill never runs them, in any automation or review mode.
4. **Every named agent runs.** Sign-offs and QA are not skipped for speed; a `NOT ASSESSED` result is surfaced as a
   decision for the user, never read as a pass.
5. **Verify, then claim.** Trunk presence, post-deploy health and the bug's `Verified Fixed` status are checked, not
   assumed; what was not checked is written `NOT VERIFIED` or `NOT CHECKED`.
6. **No commits without the user's instruction.**
7. **The next step is offered, never taken.** Phase 10 recommends `/postmortem <INC-id>` when an incident is linked,
   otherwise `/retrospective release <version>` for the release that shipped the defect, and waits for the user's
   choice.
