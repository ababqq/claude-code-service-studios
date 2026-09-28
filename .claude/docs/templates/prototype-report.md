# Concept Prototype Report: [Concept Name]

> **Verdict**: [PROCEED | PIVOT | KILL | NOT ASSESSED]
> **Product Director Review (PD-USER-VALIDATION)**: [APPROVED | CONCERNS (accepted) | REVISED] [YYYY-MM-DD]
> **Date**: [YYYY-MM-DD]
> **Directory**: `prototypes/[name]-concept/`
> **Brief**: [`design/product/product-brief.md` | `design/product/one-pager.md` | none]
> **Assumption tested**: [row # of the brief's `## Riskiest Assumptions`, or the assumption in one line]

<!--
`/prototype` writes this file to `prototypes/<name>-concept/REPORT.md`. It is the
record of the prototype — the code beside it is throwaway, the evidence is not.

MACHINE CONTRACT
- The `> **Verdict**:` line sits directly under the H1 after one blank line, with
  exactly one token: PROCEED, PIVOT, KILL, or NOT ASSESSED when the evidence
  supports none of the three (name the missing evidence under `## Verdict`).
  `/gate-check definition` reads it: a concept prototype with verdict PROCEED is a
  recommended Discovery artifact.
- Replace the review line with the recorded PD-USER-VALIDATION outcome
  (`.claude/docs/director-gates.md` § Recording Gate Outcomes) or with the skip note
  `> [PD-USER-VALIDATION] skipped — Solo mode` / `— Lean mode`.
- Keep the six `##` headings exactly as spelled, in this order. Write the body in
  the team's language.

EVIDENCE RULES
- Record what was observed — counts, rates, time, quotes with participant IDs —
  separately from what it means.
- State sample sizes. Five usability sessions find usability problems; they do not
  prove demand. Small samples are labelled directional.
- No real personal data in this file: participant IDs only; recordings and contact
  details stay in the team's approved research store.

Examples use Moa, a B2C subscription savings app for the Korean market; numbers are
illustrative. Delete these comments when the report is written.
-->

## Hypothesis

[A falsifiable statement with a behaviour and a metric, written before the
sessions ran:]

> We believe [target segment] will [observable behaviour] when [condition]. We will
> know this is true when [metric] reaches [threshold] across [n participants /
> visits / days].

- **Risk type**: [Value | Usability | Feasibility | Viability]
- **Why this assumption first**: [why it is the riskiest — what fails if it is wrong]
- **Written down before the sessions**: [yes — date | no — interpreted after the fact
  (weaker evidence)]

*Example (Moa)*: "We believe salaried 25–34-year-olds will authorise an automatic
payday transfer in their first session when the screen shows exactly when and how
much will move. We will know this is true when at least 4 of 5 participants
complete authorisation without help."

## Path

- **Path**: [clickable | code | fake-door | concierge]
- **Why this path**: [what kind of question it answers best for this hypothesis]
- **What this path cannot tell us**: [e.g. a clickable prototype says nothing about
  real payment failures; a fake door says nothing about retention]
- **What was built**: [files in this directory, sandbox accounts used, preview URL
  if any (noindex, torn down after the sessions)]
- **Shortcuts taken on purpose**: [hard-coded data, faked steps, skipped screens]

## Method

- **Participants / traffic**: [segment, how recruited, screener, n; for a fake door:
  channel, audience, impressions]
- **Consent and data handling**: [how consent was collected; where recordings live
  (never in the repository); participant IDs used here]
- **Tasks or scenario**: [the tasks given, or the offer shown, or the service run by
  hand]
- **Measures**: [task success, time on task, errors, SEQ; click-through and sign-up
  rate; continuation after N days; for code: success rate, latency, error modes]
- **Time box**: [build time, session period] — [kept | exceeded, and why]

## Results

### Participants

| ID | Segment fit | Device / surface | Notes |
|---|---|---|---|
| P1 | [yes / partial] | [iOS app via Expo Go / web / …] | [...] |

### Measures

| Measure | Result | Threshold | Met? |
|---|---|---|---|
| [task success: authorise the payday transfer] | [3 of 5] | [≥ 4 of 5] | [no] |
| [fake-door click-through] | [...] | [...] | [...] |
| [conversion to waitlist sign-up] | [...] | [...] | [...] |

### Observations
- [What participants did — with IDs: "P2 and P4 stopped at the account-connection
  step and asked whether the app could withdraw more than the goal amount"]
- [Quotes, verbatim, with IDs]
- [Surprises — good or bad]

**Hypothesis outcome**: [SUPPORTED | REFUTED | INCONCLUSIVE] — [one sentence with
the evidence]

## Verdict

**[PROCEED | PIVOT | KILL | NOT ASSESSED]** — [the recommendation in one paragraph,
reasoned from the results above, not from how the team feels about the idea.]

- **PROCEED** — the value hypothesis held; what the PRDs must carry over from this
  prototype: [confirmed assumptions, numbers observed, copy that worked].
- **PIVOT** — what almost worked and what to change; the revised hypothesis is in
  `PIVOT-NOTE.md` in this directory.
- **KILL** — the specific signal that ends this direction, what worked and is worth
  carrying to the next concept, and what to try differently next time.
- **NOT ASSESSED** — the evidence supports none of the three; name what is missing
  (sessions not run, no traffic, sandbox unavailable) and how to get it.

[When PD-USER-VALIDATION disagrees with this verdict, record the disagreement and
the user's decision here — neither side is silently kept.]

## Next Step

- **Brief update**: [set the status of the tested row in `## Riskiest Assumptions`
  to Validated / Invalidated]
- **Next skill**: [PROCEED → `/prd-review design/product/product-brief.md`, then
  `/gate-check definition` and `/map-features` (at `minimal`: `/create-stories`);
  no brief yet → `/reverse-document brief prototypes/[name]-concept`;
  PIVOT → `/prototype [revised concept]`; KILL → `/brainstorm open`;
  NOT ASSESSED → run the missing sessions, then `/prototype report prototypes/[name]-concept`]
- **Throwaway reminder**: production code is written from scratch in the code roots;
  nothing here is imported or refactored into it.
