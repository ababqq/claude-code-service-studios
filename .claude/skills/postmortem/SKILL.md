---
name: postmortem
description: "Blameless postmortem for an incident: timeline, impact, contributing factors, action items."
argument-hint: "<INC-id>"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/postmortem/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation`

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

# Blameless Postmortem

An incident is resolved; now the team learns from it. This skill turns the incident record into a **blameless
postmortem**: what happened and when, who was affected and how badly, how quickly it was detected, mitigated and
resolved, which factors combined to cause it, what went well, what went poorly, where the team got lucky — and a
short list of owned, dated action items that make the next incident less likely, shorter or smaller.

**Blameless** is the method, not a tone. The document explains how the system — code, tests, pipeline, alerts,
process, information available at the time — made the failure possible and the right action hard. It never
attaches a person's name to an error and never stops at "human error". People who were on call must be able to read
it and recognize a fair account.

**When it is required**: every `SEV1` and `SEV2` incident (the incident record's verdict is
`RESOLVED — POSTMORTEM REQUIRED`). For `SEV3` and `SEV4` it is optional — the team decides.

**Automation and writes.** Questions follow the resolved `modes.automation` (prelude above), but **every write asks
first in every mode**: a postmortem is a record about people's work, and its blameless rewrites need a human's
approval. There is no director gate in this skill.

### Output

| Path | Template |
|---|---|
| `production/incidents/postmortems/INC-YYYYMMDD-NN.md` (the incident's ID) | `.claude/docs/templates/incident-postmortem.md` |

The Launch `postmortem` step finds it through `production/incidents/postmortems/INC-*.md`. With the user's approval
the skill also updates the incident record's `> **Postmortem**:` header line and its `## Follow-ups` table.

### Sections (exact headings, from the template)

`## Summary` · `## Impact` · `## Timeline` · `## Detection & Response metrics` (time to detect / mitigate / resolve)
· `## Contributing Factors` (causal analysis, 5 whys) · `## What Went Well` · `## What Went Poorly` ·
`## Where We Got Lucky` · `## Action Items` (owner, priority, due, type `prevent | detect | mitigate`) ·
`## Runbook Changes`

### Verdicts

- `COMPLETE` — every section has content; a section may say `None — <reason>` (e.g. no runbook needs to change).
- `INCOMPLETE — MISSING <sections>` — the named sections are empty or still hold template placeholders, e.g.
  `INCOMPLETE — MISSING Contributing Factors, Action Items`.
- `NOT ASSESSED` — run-level only, printed in the conversation when Phase 0 cannot read the incident record; nothing
  is drafted or written (a postmortem file never carries it).

### Agents

| Agent | Drafts | Never |
|---|---|---|
| `sre-engineer` | Timeline, Detection & Response metrics, detection and alerting factors, Where We Got Lucky, Runbook Changes | writes the file, assigns blame |
| `tech-lead` | Contributing Factors on the change, code, test and review side; engineering action items | writes the file, assigns blame |

---

## Phase 0: Parse Arguments and Load the Incident

1. The argument is an incident ID matching `INC-[0-9]{8}-[0-9]{2}`. No argument: Glob `production/incidents/INC-*.md`,
   read each record's `**Severity**:` line, `**Status**:` line and verdict line, and list the records whose verdict
   is `RESOLVED — POSTMORTEM REQUIRED` and that have no file under `production/incidents/postmortems/` — the owed
   postmortems. Ask which one to write.
2. Read `production/incidents/<INC-id>.md`. Missing ⇒ stop: "No incident record `production/incidents/<INC-id>.md` —
   run `/incident open` to create one, or give the correct ID. Verdict: NOT ASSESSED — no incident record."
3. Check the premise:
   - `**Status**:` is `OPEN` or `MITIGATED` ⇒ say so. A postmortem written before resolution misses the end of the
     story. Ask: `Resolve first (/incident resolve <INC-id>)` (Recommended) / `Draft now and finish after resolution`
     / `Stop`. A draft written now ends with the verdict `INCOMPLETE — MISSING <sections>` until it is completed.
   - `**Severity**:` is `SEV3` or `SEV4` ⇒ a postmortem is optional; ask whether to continue.
4. `production/incidents/postmortems/<INC-id>.md` already exists ⇒ read it and ask: `Complete the missing sections`
   / `Revise the whole document` / `Stop`. Its current verdict line tells which sections are missing.

---

## Phase 1: Gather the Evidence

Read, with Read/Glob/Grep only:

- the incident record — every section, especially `## Timeline`, `## Customer Impact`, `## Mitigation` (options
  run and hypotheses), `## Communications`, `## Resolution`, `## Follow-ups`;
- hotfix records linked to the incident — Grep `production/hotfixes/` for the INC-id;
- the release involved, if any — `production/releases/<version>/rollout-plan.md` (guardrails, halt thresholds,
  rollback plan) and `release-record.md` (stages executed and decisions);
- `docs/ops/slo.md` — the SLOs and error-budget policy of the affected journeys;
- runbooks for the alerts that fired — `docs/ops/runbooks/<alert-slug>.md`;
- bugs linked to the incident — Grep `production/qa/bugs/` for the INC-id;
- ADRs and architecture sections for the components involved — `docs/architecture/`;
- earlier postmortems — Grep `production/incidents/postmortems/` for the same component or alert (a repeat is a
  finding in itself).

Anything the skill cannot observe (dashboards, logs, vendor reports) is asked for: "Can you give me <value> from
<source>?" A value nobody can supply is written `NOT DETERMINED — <reason>`; it is never estimated silently.

---

## Phase 2: Expert Drafts

Spawn in parallel (issue both `Agent` calls before waiting for either):

- `sre-engineer` — pass the incident record path, the SLO document path, the runbook paths and the rollout plan path
  (or "none"). Ask for: the condensed timeline including what happened before detection; the four metrics of
  `## Detection & Response metrics`; how the incident was detected and whether an alert would have fired without a
  human report; alert and runbook quality; where the team got lucky; runbook changes.
- `tech-lead` — pass the incident record path, the hotfix record paths, the rollout plan and release record paths,
  and the relevant ADR paths. Ask for: the trigger, the conditions that let it become an incident and the defences
  that did not catch it (review, tests, contract tests, canary stage, guardrails); a 5-whys chain for each important
  factor; engineering action items.

Instruct both: blameless language, no person's name attached to any error, no "human error" as an end point; return
drafts in the reply and write no file.

---

## Phase 3: Draft Section by Section

Draft in the template's order, showing each section and asking for approval or corrections before the next
(Question → Options → Decision → Draft → Approval):

1. **Summary** — three to five sentences; last.
2. **Impact** — from the incident's final `## Customer Impact`; add the error budget consumed.
3. **Timeline** — condensed; UTC and KST on every row; include the change that preceded impact.
4. **Detection & Response metrics** — computed from the timeline: time to detect = detected − impact start; time to
   mitigate = `MITIGATED` − impact start; time to resolve = `RESOLVED` − impact start; time to engage = Incident
   Commander assigned − detected. Show the timestamps used. Impact start unknown ⇒ `NOT DETERMINED — impact start
   unknown` for the three impact-based metrics.
5. **Contributing Factors** — trigger, conditions, defences that did not catch it; one 5-whys chain per important
   factor; stop each chain at a cause the team can change. When the two drafts disagree, show both and let the user
   decide — never merge them silently.
6. **What Went Well** / **What Went Poorly** / **Where We Got Lucky** — concrete observations, each tied to a
   timeline row or an artifact.
7. **Action Items** — each specific, owned and dated, with type `prevent`, `detect` or `mitigate` and a priority from
   the bug priority ladder (`P1-Fix this sprint`, `P2-Fix soon`, `P3-Backlog`). Check the set: a SEV1/SEV2 postmortem
   without any `detect` or `mitigate` item is asked about ("Nothing would make this faster to notice or smaller next
   time?"); an item without an owner or due date is not accepted; vague items ("be more careful", "improve
   monitoring") are rewritten into checkable ones ("page on goal-creation error-budget burn at 14.4× over 1 h").
8. **Runbook Changes** — one row per runbook to add or change, or `None — <reason>`.

---

## Phase 4: Blameless Check

Before writing, scan the whole draft and list every flagged phrase with a system-focused rewrite:

| Pattern | Example | Rewrite toward |
|---|---|---|
| A name or role attached to an error | "Minji deployed the broken build" | "The 2.4.0 build reached 25% of traffic; the canary guardrail did not include the iOS goal-creation error rate" |
| Blame verbs and judgements | "forgot", "failed to", "careless", "should have known", "didn't bother" | what information or safeguard was missing at that moment |
| "Human error" or "operator error" as a cause | "Root cause: human error" | why the system made the error easy and its effect large |
| Counterfactual hindsight | "If they had just checked the dashboard…" | what the dashboard showed, and whether anyone was prompted to look |

Names may appear only in `> **Authors**:` and as action-item owners. Present the list:

- Prompt: "I found [N] phrases that attach the failure to people. Apply the rewrites?"
- Options: `Apply all rewrites (Recommended)` / `Review each` / `Keep as written`

"Keep as written" is recorded under `## What Went Poorly` as a note that the review chose to keep that wording — the
check announces itself rather than disappearing.

---

## Phase 5: Verdict and Write

Set the verdict: `COMPLETE` when every section of the template has content; otherwise
`INCOMPLETE — MISSING <sections>` naming the empty sections by heading text. Placeholder text in brackets counts as
empty.

Ask: "May I write this to `production/incidents/postmortems/<INC-id>.md`?"

Then offer to link it from the incident record — the `> **Postmortem**:` header line becomes the postmortem path and
each action item is added to the record's `## Follow-ups` table. Ask: "May I write this to
`production/incidents/<INC-id>.md`?"

---

## Phase 6: Route the Action Items

For each action item, ask where it is tracked — one question per item, with a recommendation:

- a defect in the product ⇒ `/bug-report` (it becomes `production/qa/bugs/BUG-NNNN.md`, S-ladder severity);
- structural, reliability or monitoring work ⇒ `/tech-debt` (the register entry);
- a runbook addition or correction ⇒ `/incident runbook <alert-slug>`;
- a feature-level change ⇒ `/quick-spec` for a small change, or the next PRD for a larger one;
- already tracked ⇒ record the existing reference.

This skill does not create those entries itself; it records the chosen route in each item's `Tracking` cell (after
"May I write") and lists them in the closing widget.

---

## Phase 7: Close

Print the postmortem path, its verdict line, and every `NOT DETERMINED` value. Then close with `AskUserQuestion`,
offering only what applies:

- `/incident runbook <alert-slug>` — for each runbook change (recommended when any exists);
- `/bug-report` — for action items routed as defects;
- `/tech-debt` — for action items routed as structural work;
- `/postmortem <INC-id>` again later — when the verdict is `INCOMPLETE — MISSING <sections>`;
- `/retrospective release <version>` — when the incident came from a release and that release's retrospective has
  not run yet;
- stop here.

---

## Collaborative Protocol

1. **Question → Options → Decision → Draft → Approval** for every section. Recommend, show the alternatives, let the
   user decide.
2. **"May I write this to `<path>`?"** before every write — the postmortem and the incident record — in every
   automation mode.
3. **Blameless by construction.** Agents are instructed blameless; Phase 4 checks the draft anyway; a kept phrase is
   recorded, not hidden.
4. **Evidence over memory.** Every timeline row, metric and factor points to the incident record, a linked artifact
   or a value the user supplied. `NOT DETERMINED — <reason>` is a legitimate answer; a guess is not.
5. **Disagreement is shown.** When sre-engineer and tech-lead read the incident differently, both views reach the
   user.
6. **No commits.** Committing the postmortem is the user's decision.
7. **The next step is offered, never taken.** Phase 7 recommends the runbook and tracking follow-ups and waits for
   the user's choice.
