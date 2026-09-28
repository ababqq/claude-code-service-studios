# Incident INC-YYYYMMDD-NN: [Short title — what users experience]

> **Verdict**: [NOT ASSESSED / RESOLVED / RESOLVED — POSTMORTEM REQUIRED]
> **Detected**: [YYYY-MM-DD HH:MM UTC] ([YYYY-MM-DD HH:MM KST])
> **Resolved**: [YYYY-MM-DD HH:MM UTC (YYYY-MM-DD HH:MM KST) / ONGOING]
> **Next Update**: [HH:MM UTC (HH:MM KST) / none — resolved]
> **Postmortem**: [production/incidents/postmortems/INC-YYYYMMDD-NN.md / required — not started / not required (SEV3/SEV4)]

<!-- Written and updated by /incident (open, update, resolve). The verdict stays
NOT ASSESSED while the incident is OPEN or MITIGATED; /incident resolve sets
RESOLVED, or RESOLVED — POSTMORTEM REQUIRED for SEV1/SEV2.

Machine-contract text stays English exactly as spelled here: every heading, the
bold field labels, SEV and status tokens, the INC-/BUG- IDs and paths. Write the
body in the team's conversation language; customer-facing drafts in the locale
they ship in.

Never put personal data in this record: no names of customers, emails, phone
numbers, account IDs, card or resident registration numbers, raw log lines or
payloads. Use counts, percentages, cohorts and pseudonymous references
(e.g. "tenant T-0142"). -->

## Summary

[Two or three sentences from the user's point of view: what users could not do,
since when, on which surfaces, and where things stand now. Example: "Since 08:40 KST,
Moa users on iOS and Android cannot create savings goals; web is unaffected. The
`goals.v2-progress-ring` flag was turned off at 09:05 KST and goal creation has
recovered; we are monitoring."]

## Severity

**Severity**: [SEV1 / SEV2 / SEV3 / SEV4]

| Level | Definition |
|---|---|
| `SEV1` | Full outage, data loss, or confirmed security/privacy breach affecting users |
| `SEV2` | Major degradation or a core journey broken for many users |
| `SEV3` | Partial/minor degradation with workaround |
| `SEV4` | No user impact (near miss, internal-only) |

SEV1 and SEV2 require a postmortem. The Incident Commander sets the level; it is
never lowered automatically. When in doubt between two levels, the higher one
applies until evidence supports lowering it.

**Rationale**: [evidence for the level — affected journeys, share of users, data or
money at risk]

| Time (UTC) | Time (KST) | Level | Decided by | Reason |
|---|---|---|---|---|
| [HH:MM] | [HH:MM] | [SEV2] | [Incident Commander] | [initial classification] |

## Roles

Roles are held by **people**. Agents advise the Incident Commander; they never hold
a role, run a command against production, or publish a message.

| Role | Person | Since (UTC / KST) | Responsibility |
|---|---|---|---|
| Incident Commander | [name] | [HH:MM / HH:MM] | Owns decisions, severity and the mitigation order; delegates everything else |
| Comms Lead | [name] | [HH:MM / HH:MM] | Approves and publishes every internal and customer message; keeps the update cadence |
| Scribe | [name] | [HH:MM / HH:MM] | Keeps the timeline current; records decisions and who made them |

In a small team one person may hold two roles, but the Incident Commander is always
named.

**Advisors**: [sre-engineer (mitigation and verification) · backend-engineer /
devops-engineer (diagnosis) · security-engineer (security or privacy incident) ·
customer-success-manager (communication drafts)]

**Escalated to**: [service owner, vendor support case number, privacy officer
(개인정보 보호책임자) for incidents involving personal data, executives — or "none"]

## Status

**Status**: [OPEN / MITIGATED / RESOLVED]

| Status | Meaning |
|---|---|
| `OPEN` | Users are affected and no mitigation has taken effect yet |
| `MITIGATED` | User impact has stopped or is contained (rollback, flag off, failover); the cause may still be present |
| `RESOLVED` | Service is restored and verified against the guardrail metrics for the agreed watch window; follow-ups are filed |

| Time (UTC) | Time (KST) | From → To | Evidence |
|---|---|---|---|
| [HH:MM] | [HH:MM] | — → OPEN | [how the incident was declared] |

## Customer Impact

| Dimension | Value |
|---|---|
| Users affected | [count or % of active users; segments and plans (e.g. Free / Plus)] |
| Tenants affected (B2B) | [count / "n/a"] |
| Regions | [kr / eu / us / all] |
| Surfaces | [web / ios / android / api — app versions when only some are affected] |
| Journeys affected | [critical user journeys from `docs/ops/slo.md`] |
| Impact window | [impact start → mitigated → resolved, UTC and KST] |
| Data impact | [none / delayed / incorrect / lost / exposed — personal data involved: yes / no / unknown] |
| Financial impact | [failed or duplicated payments and debits, refunds owed, credits issued — or "none known"] |
| SLO and error budget | [SLOs breached; share of the error budget consumed] |
| Support load | [tickets, app-store reviews, social mentions attributed to the incident] |

`unknown` is a valid answer while the incident is open; replace it before resolving.

## Timeline

Append-only. Every row carries UTC and KST (UTC+9). Record what was observed, what
was decided, what a human ran, and what was sent — not interpretations.

| Time (UTC) | Time (KST) | Event | Evidence / Source | By |
|---|---|---|---|---|
| [YYYY-MM-DD HH:MM] | [YYYY-MM-DD HH:MM] | Impact starts (backfilled once known) | [dashboard, first failing request] | — |
| [HH:MM] | [HH:MM] | Detected via [alert <name> / customer report / internal] | [alert link, ticket] | [person] |
| [HH:MM] | [HH:MM] | Incident declared, [SEV2], Incident Commander assigned | — | [Incident Commander] |
| [HH:MM] | [HH:MM] | Mitigation proposed: [option] | [Mitigation table row] | [advisor] |
| [HH:MM] | [HH:MM] | Mitigation run by [person]: [command or console action] | [output, pipeline run] | [person] |
| [HH:MM] | [HH:MM] | Status → MITIGATED | [guardrail metric back under threshold] | [Incident Commander] |
| [HH:MM] | [HH:MM] | [Customer update published on status page] | [link] | [Comms Lead] |
| [HH:MM] | [HH:MM] | Status → RESOLVED | [watch window passed] | [Incident Commander] |

## Mitigation

Mitigate first, diagnose second. Every option below is run by a **human**; the
record holds the exact command or console action, its blast radius, the expected
result and how to undo it.

| # | Option | Command or console action (for a human) | Blast radius | Expected result | Undo | State |
|---|---|---|---|---|---|---|
| 1 | [Flag kill switch — turn `goals.v2-progress-ring` off] | [exact command or console path] | [who is affected by the change] | [goal-creation error rate < 0.5% within 5 min] | [turn the flag back on] | [proposed / approved / run by <person> at HH:MM UTC / verified / rejected] |
| 2 | [Roll back to the previous release per the rollout plan's `## Rollback Plan`] | [ ] | [ ] | [ ] | [ ] | [ ] |
| 3 | [Scale out / fail over / disable a third-party integration / rate-limit] | [ ] | [ ] | [ ] | [ ] | [ ] |

Mobile binaries cannot be rolled back: mitigate on the server (flags, API
compatibility, remote configuration) and ship a fix through `/hotfix`.

**Hypotheses under investigation**:

| Hypothesis | Evidence for | Evidence against | Next check | Owner |
|---|---|---|---|---|
| [The 2.4.0 deploy changed the goals API response shape] | [ ] | [ ] | [ ] | [ ] |

## Communications

Drafts come from customer-success-manager; the Comms Lead approves and a human
publishes. Customer-facing text is written in the locale(s) the product ships in.

| Time (UTC) | Time (KST) | Channel | Audience | Locale | Drafted by | Published by | Text or link |
|---|---|---|---|---|---|---|---|
| [HH:MM] | [HH:MM] | [status page] | [all users] | [ko-KR] | customer-success-manager | [person] | [link or quoted text] |
| [HH:MM] | [HH:MM] | [in-app banner / customer email / API consumer notice / internal channel] | [ ] | [ ] | [ ] | [ ] | [ ] |

**Update cadence**: [the team's committed interval for this severity — e.g. every
30 minutes for SEV1, every 60 minutes for SEV2 — and the next update time in the
header]

**Regulatory and contractual notifications** (security or privacy incidents; only
for the regions in `compliance.regions`):

| Region | Item (from `.claude/docs/compliance/<region>.md`) | Applies? | Status | Owner | Source |
|---|---|---|---|---|---|
| [kr] | [PIPA (개인정보 보호법) breach notification to data subjects and the regulator] | [yes / no / to verify] | [to verify / notified at HH:MM UTC / not applicable — reason] | [privacy officer] | [(Source: <url>, retrieved YYYY-MM-DD) — required for any deadline or threshold] |

State no deadline, fine or threshold unless it carries a source line.

## Resolution

- **What restored service**: [the mitigation, and whether the underlying fix is live —
  link the hotfix record `production/hotfixes/hotfix-YYYY-MM-DD-<slug>.md`, or
  "permanent fix pending"]
- **Verification**: [guardrail metrics back within SLO for the watch window of
  [N] minutes; synthetic checks green; backlogs drained; no duplicated side effects —
  evidence links]
- **Trigger (as understood now)**: [one or two sentences; causal analysis belongs to
  the postmortem]
- **Final customer impact**: [numbers from `## Customer Impact`, now without
  `unknown`]
- **Resolved at**: [YYYY-MM-DD HH:MM UTC (YYYY-MM-DD HH:MM KST)]

## Follow-ups

| Item | Type | Tracking | Owner | Due |
|---|---|---|---|---|
| [Blameless postmortem] | postmortem | [`/postmortem INC-YYYYMMDD-NN` — required for SEV1/SEV2] | [ ] | [ ] |
| [Permanent fix for the defect] | hotfix / bug | [`/hotfix BUG-NNNN` or `production/qa/bugs/BUG-NNNN.md`] | [ ] | [ ] |
| [Alert fired late — tighten the burn-rate window] | monitoring | [`/tech-debt` entry] | [ ] | [ ] |
| [Runbook lacked the flag kill-switch step] | runbook | [`/incident runbook <alert-slug>`] | [ ] | [ ] |
| [Refunds or credits for affected users] | customer | [support macro, owner] | [ ] | [ ] |

---

*Filed at `production/incidents/INC-YYYYMMDD-NN.md` by `/incident`. The ID uses the
UTC date of detection and a two-digit daily sequence (`INC-20261104-01`).*
