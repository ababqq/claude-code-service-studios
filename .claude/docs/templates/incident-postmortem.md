# Postmortem INC-YYYYMMDD-NN: [Short title — what users experienced]

> **Verdict**: [COMPLETE / INCOMPLETE — MISSING <sections>]
> **Incident**: `production/incidents/INC-YYYYMMDD-NN.md`
> **Severity**: [SEV1 / SEV2 / SEV3 / SEV4]
> **Impact Window**: [YYYY-MM-DD HH:MM UTC → YYYY-MM-DD HH:MM UTC] ([KST equivalents])
> **Authors**: [people who own this document; drafts by sre-engineer and tech-lead]
> **Review Meeting**: [YYYY-MM-DD, attendees by role / not held yet]

<!-- Written by `/postmortem <INC-id>` to `production/incidents/postmortems/<INC-id>.md`.
Required for SEV1 and SEV2 incidents; optional below.

BLAMELESS. This document explains how the system — code, tooling, process,
incentives, information available at the time — allowed the incident. It never
attaches a person's name to an error and never ends an analysis at "human error".
People acted reasonably on what they knew; the question is why the system made the
wrong action easy or the right information hard to see. Write "the deploy pipeline
allowed a migration to run before its readers were deployed", not "X ran the
migration too early". Names appear only in Authors and as action-item owners.

The verdict is COMPLETE when every section below has content (a section may say
"None — <reason>"); otherwise INCOMPLETE — MISSING <the empty sections>.
Headings stay in English exactly as spelled; write the body in the team's
language. No personal data of users anywhere in this document. -->

## Summary

[Three to five sentences: what happened, who was affected, how long, how it was
mitigated and resolved, and the one or two most important changes that follow.]

## Impact

| Dimension | Value |
|---|---|
| Users affected | [count or %; segments and plans] |
| Tenants affected (B2B) | [count / "n/a"] |
| Regions and surfaces | [kr / eu / us; web / ios / android / api, app versions] |
| Journeys affected | [critical user journeys from `docs/ops/slo.md`] |
| Duration | [impact start → mitigated → resolved] |
| Data impact | [none / delayed / incorrect / lost / exposed; personal data involved?] |
| Financial impact | [failed or duplicated payments, refunds, credits issued] |
| Error budget | [share of the SLO error budget consumed; budget status after the incident] |
| Support load | [tickets, app-store reviews, social mentions] |
| Regulatory or contractual notifications | [made / not required — reason; link to the incident's `## Communications`] |

## Timeline

Condensed from the incident record — the events that matter for understanding the
incident, including what happened **before** detection (the change, the first
failing requests). UTC and KST on every row.

| Time (UTC) | Time (KST) | Event | Decision or observation |
|---|---|---|---|
| [YYYY-MM-DD HH:MM] | [YYYY-MM-DD HH:MM] | [Release 2.4.0 reaches 25% of traffic] | [ ] |
| [HH:MM] | [HH:MM] | [Impact starts] | [ ] |
| [HH:MM] | [HH:MM] | [Detected via <alert / customer report>] | [ ] |
| [HH:MM] | [HH:MM] | [Mitigation run: <what>] | [why this option was chosen] |
| [HH:MM] | [HH:MM] | [MITIGATED] | [ ] |
| [HH:MM] | [HH:MM] | [RESOLVED] | [ ] |

## Detection & Response metrics

| Metric | From → To | Duration |
|---|---|---|
| Time to detect | impact start → detected | [mm min / NOT DETERMINED — reason] |
| Time to mitigate | impact start → MITIGATED | [ ] |
| Time to resolve | impact start → RESOLVED | [ ] |
| Time to engage | detected → Incident Commander assigned | [ ] |

- **How it was detected**: [alert <name> / synthetic check / customer report /
  internal user] — would an alert have fired without the human report?
- **Alert quality**: [actionable? linked runbook? paged the right rotation?]
- **Runbook used**: [`docs/ops/runbooks/<alert-slug>.md` / none existed / existed but
  did not cover this case]

## Contributing Factors

Complex failures have several contributing factors, not one root cause. Separate
the **trigger** (what started it) from the **conditions** that let it become an
incident and the **defences** that did not catch it.

- **Trigger**: [e.g. a response-shape change in `GET /goals` shipped in 2.4.0]
- **Conditions**: [e.g. iOS 2.3.x decodes the field strictly; the contract test
  covered only the web client]
- **Defences that did not catch it**: [code review, contract tests, canary stage,
  guardrail metrics, alerting — and why each missed it]

**5 whys** (one chain per important factor; stop at a cause the team can change):

1. Why did [users fail to create goals]? — Because [ ].
2. Why [ ]? — Because [ ].
3. Why [ ]? — Because [ ].
4. Why [ ]? — Because [ ].
5. Why [ ]? — Because [ ].

## What Went Well

- [e.g. the kill-switch flag restored goal creation within five minutes of the
  decision]

## What Went Poorly

- [e.g. the first customer update went out 50 minutes after detection]

## Where We Got Lucky

- [Factors that limited impact by chance rather than design — each is a hidden risk
  and usually earns an action item. e.g. "the incident started outside the 25th
  auto-debit batch window"]

## Action Items

Every item is specific, owned and dated. Type is one of `prevent` (stop it
happening again), `detect` (notice it sooner), `mitigate` (limit or shorten the
impact next time). Priority uses the bug priority ladder: `P1-Fix this sprint`,
`P2-Fix soon`, `P3-Backlog`.

| # | Action | Type | Owner | Priority | Due | Tracking | Status |
|---|---|---|---|---|---|---|---|
| 1 | [Add a consumer contract test for the iOS client of `GET /goals`] | prevent | [person or role] | [P1-Fix this sprint] | [YYYY-MM-DD] | [`production/qa/bugs/BUG-NNNN.md` / tech-debt register entry / story path] | [open / done] |
| 2 | [Page on goal-creation error-budget burn, not only on 5xx rate] | detect | [ ] | [ ] | [ ] | [ ] | [ ] |
| 3 | [Add the kill-switch step to the runbook] | mitigate | [ ] | [ ] | [ ] | [ ] | [ ] |

## Runbook Changes

| Runbook | Change | Status |
|---|---|---|
| [`docs/ops/runbooks/<alert-slug>.md`] | [what to add or correct] | [proposed / applied through `/incident runbook <alert-slug>`] |

[or "None — <why no runbook needs to change>"]
