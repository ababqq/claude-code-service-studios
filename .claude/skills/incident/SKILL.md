---
name: incident
description: "Incident response: SEV classification, roles, mitigation, comms, timeline, resolution; runbook authoring."
argument-hint: "[open <summary> | update <INC-id> | resolve <INC-id> | runbook <alert-slug>]"
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/incident/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys compliance,surfaces,stack`

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.

> **Explicit invocation only**: This skill runs only when the user types `/incident`. Do not start it because a
> conversation mentions an outage.

# Incident Response

Production is broken, or was. This skill keeps the response orderly while people are under pressure: it classifies
the severity, makes sure the human roles are filled, puts **mitigation before diagnosis**, drafts customer
communication, keeps a timeline in UTC and KST, and closes the incident with a verified resolution and filed
follow-ups. Its `runbook` mode writes the runbooks that the next on-call engineer will follow.

**The skill advises and records. It never changes production.** Rollbacks, flag changes, scaling, failovers,
database fixes and secret rotations are proposed as exact commands for a **human** to run, each with its blast
radius, expected result and undo. Those actions belong to the `production_deploys`, `infra_changes`, `db_migrations`
and `secrets_access` categories, and the project's settings deny list blocks the common deploy, infrastructure and
destructive database commands for agents anyway. Read-only commands on the local checkout (`git log`, `date`) are
fine; a read-only query against a production system is run only after "May I run this?" and never exports personal
data.

**Always collaborative.** Every question is asked and every write is approved, whatever `modes.automation` says — a
production emergency is listed among the exemptions in `.claude/docs/automation-modes.md`.

**Review-mode exemption.** `/hotfix`, `/rollout-plan` and `/incident` are release-critical: every agent and gate they name runs at every `review_mode`. They do not resolve `review_mode`.

### Modes

| Mode | When | Writes |
|---|---|---|
| `open <summary>` | Something is broken for users now (or a near miss worth recording) | `production/incidents/INC-YYYYMMDD-NN.md` (new) |
| `update <INC-id>` | Every change during the incident: new facts, mitigation run, status change, message sent | the same record (appended) |
| `resolve <INC-id>` | Service is restored and verified | the same record (Resolution, final impact, follow-ups, verdict) |
| `runbook <alert-slug>` | Hardening, or after a postmortem: write or fix the runbook for one paging alert | `docs/ops/runbooks/<alert-slug>.md` |
| no argument | — | lists records whose `**Status**:` is `OPEN` or `MITIGATED` and asks which to update or resolve; with none, asks `open` or `runbook` |

### Outputs

| Path | Template | Written in |
|---|---|---|
| `production/incidents/INC-YYYYMMDD-NN.md` | `.claude/docs/templates/incident-response.md` | `open`, `update`, `resolve` |
| `docs/ops/runbooks/<alert-slug>.md` | `.claude/docs/templates/runbook.md` | `runbook` |

The incident ID is `INC-` + the **UTC date of detection** (`YYYYMMDD`) + a two-digit sequence for that date:
`INC-20261104-01` is the first incident detected on 2026-11-04 UTC. The Launch `incident` step and `/postmortem` find
records through `production/incidents/INC-*.md`; the Hardening `runbooks` step finds runbooks through
`docs/ops/runbooks/*.md`.

### Severity (incident scheme — separate from the S1–S4 bug ladder)

| Level | Definition |
|---|---|
| `SEV1` | Full outage, data loss, or confirmed security/privacy breach affecting users |
| `SEV2` | Major degradation or a core journey broken for many users |
| `SEV3` | Partial/minor degradation with workaround |
| `SEV4` | No user impact (near miss, internal-only) |

SEV1/SEV2 ⇒ postmortem required. An incident may spawn bugs (`S1-Critical` … `S4-Trivial`) as follow-ups.

### Status and verdicts

- `**Status**:` line of the record: `OPEN` → `MITIGATED` → `RESOLVED`.
- Verdict line under the record's H1: `NOT ASSESSED` while the status is `OPEN` or `MITIGATED`, or when recovery
  could not be verified; `RESOLVED` for a verified SEV3/SEV4 resolution; `RESOLVED — POSTMORTEM REQUIRED` for a
  verified SEV1/SEV2 resolution.
- A runbook carries no verdict.

### Agents

| Agent | Role in this skill | When |
|---|---|---|
| `sre-engineer` | Mitigation options with exact commands, verification against guardrails, runbook drafts | every `open`, `resolve` and `runbook`; `update` when a mitigation is chosen |
| `backend-engineer` | Diagnosis in application code, API behaviour, data and jobs | when the resolved `stack` line has a backend or data layer and the symptom is in the service |
| `devops-engineer` | Diagnosis in deploys, pipeline, infrastructure, configuration, DNS/CDN | when a recent deploy, config or infrastructure change is suspected |
| `security-engineer` | Containment, evidence preservation, breach assessment | any suspected security or privacy incident |
| `customer-success-manager` | Drafts of status-page updates, in-app banners, customer emails, API consumer notices | every `open` with user impact, and each committed update |

Agents are spawned at every review mode (exemption above). They return drafts and findings; they do not write the
record, run commands against production, or publish messages. Humans hold the incident roles.

---

## Phase 0: Parse Arguments and Resolve Context

1. Parse the mode from the argument. An `<INC-id>` must match `INC-[0-9]{8}-[0-9]{2}` and exist under
   `production/incidents/`; otherwise list the existing records (Glob `production/incidents/INC-*.md`, reading each
   record's `**Severity**:` and `**Status**:` lines) and ask which one was meant.
2. Read the resolved block above:
   - `platform.surfaces` — which surfaces could be affected and which channels exist (in-app banner for web and
     mobile, API consumer notice for `api`). Unset ⇒ ask which surfaces are affected; never assume all of them.
   - `stack` — which layers exist, and so which diagnosis advisor fits. `stack: unset` ⇒ ask what runs where.
   - `compliance` — `regions=` for the breach-notification items and `handles_pii=` for whether personal data
     could be involved at all. Unset parts are asked when a security or privacy question arises — unset is not
     "none". `regions=none` means the project explicitly has no regional items.
3. Read `localization.locales` from `project.yaml` with Read (it has no resolved label). Customer-facing drafts are
   written in these locales; unset ⇒ ask which locale(s) customers read.
4. Get the current time for the timeline with Bash: `date -u '+%Y-%m-%d %H:%M'` and
   `TZ=Asia/Seoul date '+%Y-%m-%d %H:%M'`. Every timeline row carries both.

---

## Phase 1: Open — Classify and Staff (`open`)

### 1a. Capture the facts

Ask for what is known, in one short round — do not interrogate a responder in the middle of an outage:

- What do users see, on which surfaces, since when (best estimate of **impact start**, which is often earlier than
  detection)?
- How was it detected (alert name, customer report, internal)?
- What changed recently (deploy, flag, configuration, dependency)? Offer to look: Glob
  `production/releases/*/release-record.md` and read the newest; `git log --since="6 hours ago" --oneline` on the
  local checkout; ask about flag changes.

Unknown is a valid answer; it goes into the record as `unknown` and is revisited in `update`.

### 1b. Severity — ask, never assume

Present the four levels (table above) with a recommended level and the evidence for it. The Incident Commander
decides:

- Prompt: "Which severity applies? I recommend **[SEVn]** because [evidence]."
- Options: `SEV1 — full outage, data loss or confirmed breach` / `SEV2 — core journey broken for many users` /
  `SEV3 — partial degradation with a workaround` / `SEV4 — no user impact (near miss)`

Rules:

- **Never downgrade on your own.** A lower level is recorded only when the Incident Commander decides it, with the
  reason, in the record's severity history. Raising is suggested as soon as evidence supports it.
- When the evidence sits between two levels, recommend the higher one.
- Suspected exposure of personal data, or money moved incorrectly (failed, duplicated or wrong auto-debits and
  payments), is at least a `SEV2` candidate until ruled out.

### 1c. Roles are humans

Ask who holds each role: **Incident Commander**, **Comms Lead**, **Scribe**. In a small team one person may hold two
roles, but the Incident Commander must be named — without one, say so and ask again before continuing. This skill
assists the Scribe; it is not the Scribe.

### 1d. Create the record

Compute the ID: the UTC date of detection, then `NN` = one more than the number of existing
`production/incidents/INC-<date>-*.md` files (Glob), zero-padded to two digits.

Draft the record from `.claude/docs/templates/incident-response.md` with what is known now: `## Summary`,
`## Severity` (with the first severity-history row), `## Roles`, `## Status` (`**Status**: OPEN`), the first
`## Timeline` rows (impact start, detection, declaration), `## Customer Impact` with `unknown` where unknown, and the
verdict line `> **Verdict**: NOT ASSESSED`. Speed matters more than completeness: a minimal record written now beats
a perfect one written after the incident.

Ask: "May I write this to `production/incidents/INC-YYYYMMDD-NN.md`?"

---

## Phase 2: Mitigate First

Restoring service comes before finding the cause. Spawn in parallel (issue every `Agent` call before waiting):

- `sre-engineer` — always. Pass: the record path, the symptom, affected surfaces and journeys, the resolved `stack`
  line, the newest rollout plan (`production/releases/<version>/rollout-plan.md`, its `## Rollback Plan`) and release
  record if they exist, and the runbook for the firing alert (`docs/ops/runbooks/<alert-slug>.md`) if one exists. Ask
  for ranked mitigation options.
- `devops-engineer` — when a deploy, pipeline, configuration or infrastructure change is suspected.
- `backend-engineer` — when the symptom is in application behaviour, API responses, data or background jobs.
- `security-engineer` — for any suspected security or privacy incident (Phase 3).

Present the options as a table — option, exact command or console action **for a human**, blast radius, expected
result, undo — in this preference order unless the evidence says otherwise:

1. **Roll back** per the rollout plan's `## Rollback Plan` (previous deploy, halted phased release).
2. **Flag kill switch** (e.g. turn `goals.v2-progress-ring` off).
3. **Scale** or **shed load**.
4. **Fail over** or **disable a failing integration** (degraded mode).

Mobile binaries cannot be rolled back: for iOS and Android the mitigation acts on the server (flags, remote
configuration, API compatibility) and the fix ships later through `/hotfix`.

Ask the Incident Commander which option to take:

- Prompt: "Which mitigation should a human run first?"
- Options: one per ranked option (recommended one first, marked "(Recommended)") / `None yet — keep diagnosing`

Then hand over the chosen command block and wait. **Do not run it** — not with Bash, not by asking an agent to. When
the human confirms it ran, ask sre-engineer to check the outcome against the expected result and the guardrail
metrics, and draft the timeline rows (proposed, run by `<person>`, verified or not). Ask: "May I write this to
`production/incidents/INC-YYYYMMDD-NN.md`?" When user impact has stopped, propose `**Status**: MITIGATED` — the
Incident Commander confirms it.

Diagnosis continues in parallel with mitigation: keep hypotheses in the `## Mitigation` hypotheses table with the
evidence for and against each and the next check.

---

## Phase 3: Security and Privacy Incidents

When the incident involves unauthorized access, leaked credentials, exposed personal data, fraud or abuse — or
cannot yet be ruled out as one:

1. Spawn `security-engineer` with the record path, the resolved `compliance` line and what is known. Ask for:
   **containment** steps (revoke sessions and tokens, rotate keys, block the abusing path — every one a command for a
   human; reading or rotating secrets is always the human's action), **evidence preservation** (keep logs, snapshots
   and audit trails; do not delete or overwrite them), and a **breach assessment** (was personal data accessed or
   exposed; which categories; how many data subjects). `handles_pii=false` never rules a privacy incident out: if
   personal data turns out to be involved, say so, and suggest correcting `privacy.handles_pii` with `/settings`
   once the incident is resolved.
2. For each region in `compliance.regions`, read `.claude/docs/compliance/<region>.md` and list its items on breach
   and incident notification in the record's `## Communications` regulatory table — for `kr` the PIPA
   (개인정보 보호법) breach-notification items; for `eu` the GDPR personal-data-breach items; for `us` the state
   breach-notification items and, where card data is involved, PCI DSS. Each item is a **checklist to verify**, not
   a fact: never state a deadline, threshold or fine unless it carries `(Source: <url>, retrieved YYYY-MM-DD)`.
   A region file without such an item ⇒ `NOT CHECKED — no breach-notification item in <region>.md` in the table,
   and the privacy officer decides. `compliance.regions` unset ⇒ ask which regions' users are affected;
   `regions=none` ⇒ record "no regional items (compliance.regions: [])".
3. Name the privacy officer (개인정보 보호책임자) or equivalent in `## Roles` → **Escalated to** when personal data may be
   involved.
4. Keep technical details of an unpatched vulnerability out of every customer-facing draft.

---

## Phase 4: Communications

Spawn `customer-success-manager` with the record path, the affected surfaces, the locales from Phase 0 and the
current status. Ask for drafts for the channels that exist:

- **Status page** — component states matching the critical user journeys in `docs/ops/slo.md`.
- **In-app banner** — web and mobile surfaces.
- **Customer email** — when a subset of users was affected in a way they need to act on (e.g. a failed auto-debit).
- **API consumer notice** — when `api` is a surface.
- **Internal update** — support team and stakeholders.

Drafts state what users experience, what they can do, and when the next update comes — never a cause that is not
confirmed, never a fix that is not verified, never blame on a vendor. Customer-facing text is written in the
product's locale(s). Show every draft; the Comms Lead approves, a human publishes. Record each message in
`## Communications` with its time, channel, audience, locale and publisher, and set `> **Next Update**:` to the
committed time. Ask: "May I write this to `production/incidents/INC-YYYYMMDD-NN.md`?"

Offer to close `open` with the next-step widget (Phase 8).

---

## Phase 5: Update (`update <INC-id>`)

Read the record. Ask what changed (new facts, a mitigation run, a status change, a message sent, a severity change),
then draft the additions:

- **Timeline** rows (UTC + KST), append-only — never rewrite earlier rows; a correction is a new row.
- **Status** change with evidence (`OPEN → MITIGATED`, or back to `OPEN` when a mitigation stops working).
- **Severity** change only as the Incident Commander's recorded decision.
- **Customer Impact** refinements (replace `unknown` as numbers arrive).
- **Mitigation** table state changes and new hypotheses.
- **Communications** row and the new `> **Next Update**:` time (Phase 4 for new drafts).

When a new mitigation is on the table, run Phase 2 for it. Ask: "May I write this to
`production/incidents/<INC-id>.md`?"

---

## Phase 6: Resolve (`resolve <INC-id>`)

1. **Verify recovery.** Spawn `sre-engineer` with the record path, the guardrail metrics and the SLOs of the affected
   journeys. Recovery is verified when the SLIs are back within their SLOs for the agreed watch window, synthetic
   checks pass on every affected surface, backlogs are drained, and there are no duplicated side effects (double
   debits, duplicate notifications). If the evidence is not available, say which, keep `**Status**: MITIGATED`, set
   the verdict to `NOT ASSESSED`, and go straight to Phase 8 — resolution is not declared on hope.
2. **Resolution.** Draft `## Resolution`: what restored service, whether the permanent fix is live (link the hotfix
   record, or "permanent fix pending"), verification evidence, the trigger as understood now (analysis belongs to
   the postmortem), resolved time in UTC and KST.
3. **Final customer impact.** Users, tenants, regions and surfaces affected; impact window; data impact (none,
   delayed, incorrect, lost, exposed); financial impact; error budget consumed. No `unknown` remains — an item that
   truly cannot be known is written `NOT DETERMINED — <reason>`.
4. **Follow-ups.** For each, ask where it is tracked: `/bug-report` for a defect (S-ladder), `/tech-debt` for
   structural or monitoring work, `/hotfix <INC-id>` when the permanent fix is still pending, `/incident runbook
   <alert-slug>` when a runbook was missing or wrong. Record each in `## Follow-ups` with owner and due date.
5. **Status and verdict.** `**Status**: RESOLVED`; the Incident Commander confirms. Verdict:
   - SEV1 or SEV2 ⇒ `> **Verdict**: RESOLVED — POSTMORTEM REQUIRED`, and `> **Postmortem**: required — not started`;
   - SEV3 or SEV4 ⇒ `> **Verdict**: RESOLVED` (a postmortem is optional — ask whether the team wants one).
6. Ask: "May I write this to `production/incidents/<INC-id>.md`?" Then draft the final customer message (Phase 4)
   when customers were told about the incident.

---

## Phase 7: Runbook (`runbook <alert-slug>`)

1. Read `docs/ops/slo.md` `## Dashboards & Alerts` and list the paging alerts. Glob `docs/ops/runbooks/*.md` and show
   which alerts have a runbook and which do not — coverage is derived from the SLO document, not remembered. With no
   slug, ask which alert to write next (missing ones first). A slug that is not in the SLO document: ask whether to
   add the alert there first (`/create-architecture` owns `docs/ops/slo.md`) or to write the runbook anyway and note
   the gap. No `docs/ops/slo.md` ⇒ `NOT CHECKED — alert coverage (no docs/ops/slo.md)`, and ask for the alert
   definition directly.
2. Spawn `sre-engineer` to draft the runbook from `.claude/docs/templates/runbook.md`, passing the alert definition,
   the SLO it protects, the resolved `stack` line, `docs/architecture/architecture.md`, the rollout plan's
   `## Rollback Plan`, and any postmortem `## Runbook Changes` rows that name this alert. When the diagnosis steps
   depend on the application or the infrastructure, ask `backend-engineer` or `devops-engineer` to review them.
3. Check the draft: every mitigation has an exact command or console path, blast radius, expected result, undo and
   who may run it; every diagnosis step is read-only; escalation has time boxes; verification checks for duplicated
   side effects; no secret, token or personal data appears.
4. Existing runbook: show the change as a diff of sections, then edit in place. Ask: "May I write this to
   `docs/ops/runbooks/<alert-slug>.md`?"

---

## Phase 8: Close

Print the record path, its `**Status**:` and verdict line (or the runbook path), and every `NOT CHECKED` line. Then
close with `AskUserQuestion`, offering only what applies:

- after `open` or `update`, or a `resolve` that could not verify recovery, while `OPEN` or `MITIGATED`:
  `/incident update <INC-id>` at the next update time ·
  `/hotfix <INC-id>` when a code fix must ship · `/incident resolve <INC-id>` once recovery can be verified · stop
  here;
- after `resolve` with `RESOLVED — POSTMORTEM REQUIRED`: `/postmortem <INC-id>` (recommended) · `/bug-report` for a
  defect follow-up · `/tech-debt` for structural follow-ups · stop here;
- after `resolve` with `RESOLVED`: `/postmortem <INC-id>` (optional) · `/bug-report` · `/tech-debt` · stop here;
- after `runbook`: `/incident runbook <next-alert-slug>` for the next alert without a runbook · stop here.

---

## Collaborative Protocol

1. **Question → Options → Decision → Draft → Approval** at every step, compressed for an emergency: one short round
   of questions, a recommendation with evidence, the Incident Commander's decision, a draft, "May I write".
2. **"May I write this to `<path>`?"** before every write to the incident record or a runbook.
3. **Humans hold the roles and run the commands.** The Incident Commander decides severity, mitigation order and
   status; the Comms Lead publishes; a person runs every command that changes production, shared infrastructure, a
   shared database or secrets. This holds in every automation and review mode.
4. **Severity is never lowered by the skill.** It recommends; the Incident Commander decides, and the decision is
   recorded.
5. **Unset is not "no".** Unset surfaces, regions, personal-data handling or locales are asked, never assumed.
6. **Facts, not guesses.** Unknown values are written `unknown` during the incident and `NOT DETERMINED — <reason>`
   at resolution; a legal deadline without a source line is never stated.
7. **No personal data in the record.** Counts, cohorts and pseudonymous references only.
8. **No commits.** Committing the record is the user's decision.
9. **The next step is offered, never taken.** Phase 8 recommends `/postmortem <INC-id>` for SEV1/SEV2 and waits for
   the user's choice.
