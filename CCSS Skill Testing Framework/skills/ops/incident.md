# Skill Spec: /incident

> **Category**: ops
> **Priority**: high
> **Spec written**: 2026-09-28

## Skill Summary

`/incident` keeps incident response orderly while people are under pressure.
Modes: `open <summary>`, `update <INC-id>`, `resolve <INC-id>` and
`runbook <alert-slug>`. `open` captures the facts, asks the Incident Commander to
classify the severity (`SEV1`–`SEV4`; the skill recommends, never downgrades on its
own), makes sure the human roles are filled (Incident Commander, Comms Lead,
Scribe), and creates `production/incidents/INC-YYYYMMDD-NN.md` from
`.claude/docs/templates/incident-response.md`. Mitigation comes before diagnosis:
`sre-engineer` (with `devops-engineer` or `backend-engineer` for diagnosis) ranks
options — rollback per the rollout plan, flag kill switch, scale, failover — and
the skill hands each to a **human** as an exact command; it never runs a
production-changing command. Security and privacy incidents spawn
`security-engineer` and surface the breach-notification items of
`.claude/docs/compliance/<region>.md` as checklists to verify.
`customer-success-manager` drafts status-page, in-app, email and API-consumer
messages. `update` appends timeline rows in UTC and KST; `resolve` verifies
recovery, records final customer impact and follow-ups (`/bug-report`,
`/tech-debt`), and sets the verdict — `RESOLVED`, or `RESOLVED — POSTMORTEM
REQUIRED` for SEV1/SEV2 with a hand-off to `/postmortem <INC-id>` (`NOT ASSESSED`
while recovery is unverified). `runbook` writes `docs/ops/runbooks/<alert-slug>.md`
from `.claude/docs/templates/runbook.md` with sre-engineer. The skill is always
collaborative, review-mode-exempt and explicitly invoked only.

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`); `name: incident` equals the skill directory and the catalog `name`; `model: sonnet`
- [ ] `argument-hint` is `"[open <summary> | update <INC-id> | resolve <INC-id> | runbook <alert-slug>]"`; frontmatter carries `disable-model-invocation: true` and no `isolation`
- [ ] Bootstrap: the first body line is `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys compliance,surfaces,stack` `` and `allowed-tools` grants `Bash(bash "*/.claude/skills/incident/../../hooks/yaml-helper.sh" resolve_config *)`
- [ ] The line after the bootstrap block is exactly: ``Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] No automation prelude, and neither `automation` nor `review_mode` is among the keys (always collaborative, review-mode-exempt)
- [ ] `allowed-tools` is exactly: Read, Glob, Grep, Write, Edit, Bash, Agent, AskUserQuestion, plus the grant (membership exact, order free)
- [ ] 2+ phase headings found
- [ ] Verdict keywords present, exactly: `RESOLVED`, `RESOLVED — POSTMORTEM REQUIRED`, `NOT ASSESSED`; record status tokens `OPEN`, `MITIGATED`, `RESOLVED`
- [ ] Severity tokens are exactly `SEV1`, `SEV2`, `SEV3`, `SEV4` (incidents), with follow-up bugs on the `S1-Critical` … `S4-Trivial` ladder
- [ ] "May I write this to `production/incidents/INC-YYYYMMDD-NN.md`?" (and `production/incidents/<INC-id>.md` in `update` / `resolve`) and "May I write this to `docs/ops/runbooks/<alert-slug>.md`?" before each write
- [ ] Outputs at the exact paths `production/incidents/INC-YYYYMMDD-NN.md` (ID = `INC-` + UTC date of detection + a two-digit sequence) and `docs/ops/runbooks/<alert-slug>.md`; the record's H1 is followed, after one blank line, by `> **Verdict**: <TOKEN>`; a runbook carries no verdict
- [ ] Contains the review-mode exemption sentence verbatim (see Case 6)
- [ ] No `!` injection other than the bootstrap line; no `file:line` citations of other files
- [ ] Next-step handoff section present at end (Phase 8), naming skills by their current names

---

## Director Gate Checks

- **Review-mode exempt**: the skill contains "`/hotfix`, `/rollout-plan` and `/incident` are release-critical: every agent and gate they name runs at every `review_mode`. They do not resolve `review_mode`." Every agent it names — `sre-engineer`, `backend-engineer`, `devops-engineer`, `security-engineer`, `customer-success-manager` — runs at every review mode when its trigger applies.
- **N/A**: `/incident` spawns no director gate; the agents return drafts and findings, never a gate verdict, and never write the record, run commands against production, or publish messages.

---

## Test Cases

### Case 1: Happy Path — open a SEV2 and mitigate first

**Fixture** (assumed project state):
- `platform.surfaces: [web, ios, android, api]`; `stack` has backend and data layers; `compliance: regions=kr handles_pii=true`; `localization.locales: [ko-KR]`
- The 2.4.0 rollout is at its 25% stage; `production/releases/2.4.0/rollout-plan.md` has a `## Rollback Plan`; `docs/ops/runbooks/auto-debit-failure-rate.md` exists
- No incident recorded yet for 2026-11-04 (UTC)

**Input**: `/incident open auto-debits failing for goals since 09:40 KST`

**Expected behavior**:
1. Phase 0 gets the time with `date -u '+%Y-%m-%d %H:%M'` and `TZ=Asia/Seoul date '+%Y-%m-%d %H:%M'`
2. Phase 1 asks one short round of questions (impact start, detection, recent changes) and offers to read the newest release record and `git log --since="6 hours ago" --oneline`
3. Severity: "Which severity applies? I recommend **SEV2** because …" with the four `SEV` options; money moved incorrectly makes it at least a SEV2 candidate
4. The skill asks who holds Incident Commander, Comms Lead and Scribe
5. ID `INC-20261104-01` (one more than the count of `production/incidents/INC-20261104-*.md`); the record is drafted from the template with `**Status**: OPEN` and `> **Verdict**: NOT ASSESSED`; "May I write this to `production/incidents/INC-YYYYMMDD-NN.md`?"
6. Phase 2 spawns `sre-engineer`, `devops-engineer` (a rollout stage is in progress) and `backend-engineer` (the symptom is in payment behaviour) in one parallel batch; options are shown as a table (command for a human, blast radius, expected result, undo), rollback per the rollout plan first
7. The Incident Commander picks the rollback; a person runs it; sre-engineer verifies; timeline rows (UTC + KST) are drafted and written after approval
8. Phase 4: `customer-success-manager` drafts a status-page update and an in-app banner in `ko-KR`; the Comms Lead approves, a human publishes

**Assertions**:
- [ ] The Incident Commander decides the severity; the skill only recommends, with evidence
- [ ] The humans hold the roles; the skill assists the Scribe and is not the Scribe
- [ ] The record is written from `.claude/docs/templates/incident-response.md` with the first `## Timeline` rows (impact start, detection, declaration) carrying both UTC and KST
- [ ] Mitigation options are proposed as exact commands for a human; the skill does not run them with Bash or through an agent
- [ ] Customer drafts state what users experience, what they can do and when the next update comes — never an unconfirmed cause or unverified fix — and are written in the product locale
- [ ] `**Status**: MITIGATED` is proposed only when user impact has stopped, and the Incident Commander confirms it

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — no Incident Commander, and a mitigation that did not work

**Fixture**:
- `/incident open goal list times out`
- The user answers the roles question without naming an Incident Commander
- Later, the rollback a person ran leaves the error rate above the guardrail

**Expected behavior**:
1. The skill says an Incident Commander must be named and asks again before continuing
2. After the rollback, sre-engineer's check shows the guardrail still breached; the timeline row records the mitigation as not verified
3. `**Status**` stays `OPEN`; the next ranked option is offered

**Assertions**:
- [ ] The skill does not continue past the roles step without a named Incident Commander
- [ ] An unverified mitigation never moves the status to `MITIGATED`
- [ ] Timeline rows are append-only: a correction is a new row, never an edit of an earlier one

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: NOT ASSESSED — recovery cannot be verified

**Fixture**:
- `production/incidents/INC-20261104-01.md`: `**Severity**: SEV2`, `**Status**: MITIGATED`
- The SLI data for the affected journey is not available (no dashboard access, no numbers supplied)

**Input**: `/incident resolve INC-20261104-01`

**Expected behavior**:
1. Phase 6 spawns `sre-engineer` to verify recovery against the SLOs, synthetic checks, backlogs and duplicated side effects
2. The evidence is not available: the skill says which, keeps `**Status**: MITIGATED`, sets the verdict to `NOT ASSESSED`, drafts no resolution, and goes straight to the Phase 8 closing widget

**Assertions**:
- [ ] Verdict is NOT ASSESSED, naming the missing evidence
- [ ] No `RESOLVED` verdict is produced — resolution is not declared on hope
- [ ] The status stays `MITIGATED`; the closing widget offers `/incident resolve INC-20261104-01` once recovery can be verified
- [ ] An `<INC-id>` that does not match `INC-[0-9]{8}-[0-9]{2}` or has no record makes the skill list existing records and ask, never guess

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Mode Variant — resolve a SEV2 and hand off to the postmortem

**Fixture**:
- As Case 3, but sre-engineer confirms the SLIs are back within their SLOs for the watch window, synthetic checks pass on every affected surface, the retry backlog is drained and no auto-debit was duplicated
- Final impact: 3,120 users in Korea, 71 minutes, 1,480 delayed auto-debits (none lost or duplicated)

**Input**: `/incident resolve INC-20261104-01`

**Expected behavior**:
1. `## Resolution` is drafted (what restored service, the permanent fix linked or "permanent fix pending", resolved time in UTC and KST)
2. Final customer impact contains no `unknown`; anything unknowable is written `NOT DETERMINED — <reason>`
3. Each follow-up is routed with the user: `/bug-report`, `/tech-debt`, `/hotfix INC-20261104-01`, `/incident runbook <alert-slug>`
4. `**Status**: RESOLVED`; `> **Verdict**: RESOLVED — POSTMORTEM REQUIRED`; `> **Postmortem**: required — not started`
5. Closing widget recommends `/postmortem INC-20261104-01`

**Assertions**:
- [ ] A SEV1 or SEV2 resolution gets exactly `RESOLVED — POSTMORTEM REQUIRED`; a SEV3 or SEV4 resolution gets `RESOLVED` and the postmortem is offered as optional
- [ ] "May I write this to `production/incidents/INC-20261104-01.md`?" is asked before the resolution is written
- [ ] The hand-off to `/postmortem <INC-id>` is offered, never started automatically
- [ ] No personal data enters the record — counts, cohorts and pseudonymous references only

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Mode Variant — runbook authoring

**Fixture**:
- `docs/ops/slo.md` `## Dashboards & Alerts` lists three paging alerts; `docs/ops/runbooks/` holds a runbook for one of them

**Input**: `/incident runbook goal-create-error-budget-burn`

**Expected behavior**:
1. Phase 7 derives coverage from the SLO document (which alerts have runbooks and which do not)
2. `sre-engineer` drafts from `.claude/docs/templates/runbook.md`, given the alert definition, the SLO it protects, the `stack` line, the architecture document and the rollout plan's `## Rollback Plan`
3. The skill checks the draft: every mitigation has an exact command or console path, blast radius, expected result, undo and who may run it; diagnosis steps are read-only; escalation has time boxes; no secret, token or personal data appears
4. "May I write this to `docs/ops/runbooks/goal-create-error-budget-burn.md`?"

**Assertions**:
- [ ] Coverage is derived from `docs/ops/slo.md`, not remembered
- [ ] With no `docs/ops/slo.md`, the skill prints `NOT CHECKED — alert coverage (no docs/ops/slo.md)` and asks for the alert definition
- [ ] The runbook carries no verdict line
- [ ] The closing widget offers `/incident runbook <next-alert-slug>` for the next alert without a runbook

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Review-Mode Exemption — responders run in solo mode

**Fixture**:
- As Case 1
- Review mode: `solo` in `project.yaml` (`modes.review_mode: solo`)

**Expected behavior**:
1. The skill does not resolve `review_mode`
2. `sre-engineer`, the diagnosis advisor and `customer-success-manager` run as in Case 1

**Assertions**:
- [ ] SKILL.md contains verbatim: "`/hotfix`, `/rollout-plan` and `/incident` are release-critical: every agent and gate they name runs at every `review_mode`. They do not resolve `review_mode`."
- [ ] `review_mode` is not among the skill's `--keys`
- [ ] `sre-engineer` runs despite `solo`; no `[GATE-ID] skipped — Solo mode` note appears

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: Always Collaborative — autonomous mode, security incident

**Fixture**:
- `project.yaml` sets `modes.automation: autonomous`; `compliance.regions: [kr, eu]`; `privacy.handles_pii: false`
- Logs show a leaked API key used to list other users' goals

**Input**: `/incident open leaked partner API key used to read goals`

**Expected behavior**:
1. No automation prelude; every question and write is asked
2. Phase 3 spawns `security-engineer`: containment (revoke sessions and tokens, rotate keys — each a command for a human), evidence preservation, breach assessment
3. For `kr` and `eu`, the skill reads `.claude/docs/compliance/kr.md` and `eu.md` and lists their breach-notification items in `## Communications` as checklists to verify
4. `handles_pii=false` does not rule the privacy incident out; the skill suggests correcting `privacy.handles_pii` with `/settings` after resolution
5. The privacy officer is named under `## Roles` → **Escalated to**

**Assertions**:
- [ ] SKILL.md states that the skill is always collaborative, and `automation` is not among the keys
- [ ] Reading or rotating secrets is always a human's action; the skill never executes a production-mutating command and respects the settings deny list
- [ ] No deadline, threshold or fine is stated unless it carries `(Source: <url>, retrieved YYYY-MM-DD)`; a region file without the item gives `NOT CHECKED — no breach-notification item in <region>.md`
- [ ] Unset `compliance.regions` is asked; `regions=none` records "no regional items (compliance.regions: [])"
- [ ] Technical details of the unpatched vulnerability stay out of every customer-facing draft
- [ ] The severity is never lowered by the skill; a suspected personal-data exposure starts as at least a SEV2 candidate

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses "May I write this to `<path>`?" before every write to the incident record or a runbook
- [ ] Presents drafts (record, mitigation table, customer messages, runbook) before requesting approval
- [ ] Ends with a recommended next step (`/incident update`, `/hotfix <INC-id>`, `/incident resolve`, `/postmortem <INC-id>` after a SEV1/SEV2 resolution, `/incident runbook <next-alert-slug>`)
- [ ] Does not auto-create files without user approval; commits nothing
- [ ] Writes no evidence, reports or plans under `production/session-logs/` (gitignored)
- [ ] Never writes `modes.review_mode` or any other knob that `modes.rigor` fronts (`/settings` is the one exception)
- [ ] Never runs a command that changes production, shared infrastructure, a shared database or secrets; unset surfaces, regions, personal-data handling and locales are asked, never assumed

---

## Coverage Notes

- `update` is exercised through Cases 2 and 3; severity raises and the
  `> **Next Update**:` commitment are not separately tested.
- The no-argument listing (records whose status is `OPEN` or `MITIGATED`) is not tested.
- SEV4 near misses (no user impact) follow the Case 4 resolution path with the
  plain `RESOLVED` verdict.
- A read-only production query run only after "May I run this?" is not tested.
