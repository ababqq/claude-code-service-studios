---
name: prototype
description: "Concept prototype to test the riskiest assumption — clickable, fake-door, concierge or code spike. PROCEED/PIVOT/KILL."
argument-hint: "[concept-description] [--path clickable|code|fake-door|concierge] [--review full|lean|solo] [--spike] | report <prototype-dir>"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/prototype/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
isolation: worktree
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation`

Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

# Concept Prototype

A concept prototype is the **cheapest test of the riskiest assumption** — built in a
day, put in front of real target users within a week, and thrown away. It answers
one question before anyone writes PRDs or production code: *is this worth building?*
Its verdict is **PROCEED**, **PIVOT** or **KILL** — or **NOT ASSESSED** when the
evidence supports none of the three.

**Default use** — in Discovery, after `/brainstorm` has named the riskiest assumptions
and before `/map-features` and the PRDs. **Any time later** — `--spike` answers one
technical or design question in about four hours, with no verdict and no phase-gate
implications. **Already have code for real?** Proving that the production stack works
end to end on staging is the walking skeleton (`/walking-skeleton`), built as
production code — not a prototype.

### Outputs

| Path | Mode | Content |
|------|------|---------|
| `prototypes/<name>-concept/` | concept (default) | The build, the session plan, `REPORT.md` (from `.claude/docs/templates/prototype-report.md`) and, on a PIVOT, `PIVOT-NOTE.md` |
| `prototypes/<name>-spike-YYYY-MM-DD/SPIKE-NOTE.md` | `--spike` | The spike record — question, result YES / NO / PARTIAL, evidence, next action |
| `REPORT.md` in an existing prototype directory | `report <prototype-dir>` | The record for a prototype that has none |

`/gate-check definition` looks for `prototypes/*-concept/REPORT.md` with the verdict
line `> **Verdict**: PROCEED` (a recommended Discovery artifact). Directory rules and
relaxed standards: `.claude/rules/prototype-code.md`.

**Isolation.** This skill declares `isolation: worktree`: where the host honours it,
the build runs in an isolated git worktree, so throwaway code never lands on the
working branch by accident. Files written there stay on the worktree's branch until
the user brings `prototypes/<name>-…/` over — `/help` and `/gate-check` only see the
record once it is in the main working tree. The summary (Phase 10) always names the
branch and the paths written.

### What this skill never does

- **Use real personal data.** Fixtures are synthetic and obviously fake; real
  participants appear only as participant IDs (P1, P2, …). Recordings, contact details
  and concierge data stay in the team's approved research store, never in the
  repository.
- **Use production keys.** Sandbox or test credentials only, from a local `.env` that is
  never committed. It never asks for, prints or pastes a production key or token.
- **Collect real payments** or deploy to a production domain or shared infrastructure.
  A preview deploy for remote sessions is proposed as a command for the user to run,
  marked `noindex`, and torn down after the sessions.
- **Mix prototype and product code.** Prototype code never imports from the product's
  source, and product code never imports from `prototypes/`.
- **Default to PROCEED.** A recommendation follows the evidence; thin evidence is
  NOT ASSESSED or a directional PIVOT, never a PROCEED.

---

## Phase 1: Parse Arguments and Choose the Mode

| `$ARGUMENTS` | Mode |
|---|---|
| `report <prototype-dir>` | **Report Mode** (section near the end) |
| `--spike` (with or without a description) | **Spike Mode** (section near the end) |
| `[concept-description]`, optionally `--path clickable\|code\|fake-door\|concierge` | Concept prototype — Phases 2–10 |
| nothing | Ask below |

`--review full|lean|solo` overrides the resolved `review_mode` for this run.

When no mode flag was given, confirm intent with `AskUserQuestion`:

- **Prompt**: "How would you like to use this session?"
- **Options**:
  - `Prototype the riskiest assumption` — build the cheapest test (≤ 1 day), run it with
    target users, and decide PROCEED / PIVOT / KILL.
  - `Skip — already proven` — interviews, data or a live product already answer it; go
    straight to PRDs.
  - `Spike a technical question` — about four hours, one question, no verdict.

**Skip — already proven**: ask in plain text "What evidence answers the riskiest
assumption?" State it back: "Concept prototype skipped — evidence: [answer]." Write no
file. Suggest recording the evidence in the brief's `## Riskiest Assumptions` status
column (`/brainstorm` resumes the brief for that) and continuing with `/prd-review
design/product/product-brief.md` or `/map-features`. The Discovery → Definition gate
lists the concept prototype as recommended, and accepts the riskiest assumption proven
by other means.

---

## Phase 2: Load Context

1. **The bet** — read `design/product/product-brief.md` (or `design/product/one-pager.md`
   at `minimal`): `## Riskiest Assumptions`, the target segment, the value proposition
   and the principles. With neither, work from the argument and say that the prototype
   will test an unwritten bet — on PROCEED, write the brief next.
2. **What was already tried** — the history is derived from the records, not kept in an
   index: Glob `prototypes/*-concept/REPORT.md` and read each verdict line and
   hypothesis; Glob `prototypes/*-concept/PIVOT-NOTE.md`. When a PIVOT-NOTE belongs to
   this concept, start from its revised hypothesis instead of forming one from scratch,
   and count the PIVOTs in that chain (Phase 10 uses the count).
3. **Evidence that already exists** — `production/qa/usability/*.md` and personas in
   `design/product/personas/` may already answer part of the question; use them.

---

## Phase 3: Define the Hypothesis

**Test the riskiest assumption, not the easiest.** Pick the assumption with the highest
impact-if-wrong × uncertainty, across the four risks: **Value** (will they want it),
**Usability** (can they use and trust it), **Feasibility** (can we build and operate
it, third parties included), **Viability** (does it work for the business). Ask the
user in plain text: "Which assumption, if wrong, sinks this product?" — and compare
with the brief's ranking.

Write the **falsifiable hypothesis** — a behaviour, a metric and a threshold, decided
**before** building:

> "We believe [target segment] will [observable behaviour] when [condition]. We will
> know this is true when [metric] reaches [threshold] across [n participants / visits /
> days]."

- Good: "We believe salaried 25–34-year-olds will authorise an automatic payday
  transfer in their first session when the screen shows exactly when and how much will
  move. We will know when at least 4 of 5 target participants complete authorisation
  without help."
- Good: "We believe at least 8% of Free users who see a 'Plus — shared goals' entry
  will tap it and join the waitlist within two weeks (≥ 300 exposed users)."
- Bad: "Do people like the app?" — no behaviour, no threshold, cannot fail.

**If the concept is too vague to state a hypothesis, stop here** and narrow the
question with the user. A prototype without a question wastes the day.

---

## Phase 4: Choose the Path

If `--path` was given, use it. Otherwise match the path to the kind of question:

| The question is… | Path | Why |
|---|---|---|
| Will they understand it, find their way, trust the step? | **clickable** | Comprehension and flow need a screen, not a backend |
| Will they take the first step — want it, click it, pay for it? | **fake-door** | Measures demand from real behaviour before building anything |
| Is the outcome valuable when delivered? | **concierge** | Delivers the value by hand before automating it |
| Can we build it, does it integrate, is it fast enough? | **code** | Only running code against the real third party answers it |

### Path: clickable

- **Build**: a Figma or ProtoPie prototype the user owns, or — built here — a single
  self-contained `index.html` (all styles and data inline, opens by double-click, no
  server), or a local Vite or Expo app with hard-coded data when touch and gesture feel
  on a real phone matter (Expo Go).
- **Sessions**: moderated think-aloud with target users; per-task success criteria;
  task success, time on task, errors, SEQ after each task. Five participants per
  segment find most usability problems in a formative test — they do not measure rates.
- **Cannot tell you**: real latency, real data edge cases, whether users come back.

### Path: fake-door

- **Build**: a standalone landing page, or an entry point inside an existing product
  (a "Plus" button, a menu item), that leads to an honest "not available yet" page with
  an optional waitlist.
- **Traffic**: existing users (email or push only to users who consented to marketing
  messages — in Korea advertising messages need prior opt-in consent and separate
  consent for night-time sending), a capped ad budget, communities where the segment
  gathers. Decide the minimum sample before launching; below it the read is
  directional.
- **Measures**: impressions → click-through → waitlist sign-up (or pre-order intent);
  price variants for willingness-to-pay.
- **Ethics**: the follow-up says plainly the feature does not exist yet; a waitlist
  collects an email only with explicit consent and a stated deletion date; never
  collect payment details; no dark patterns.
- **Cannot tell you**: retention, satisfaction, whether they keep paying.

### Path: concierge

- **Build**: an operator script, message templates and a checklist for delivering the
  value by hand to 5–15 consenting users for one to three weeks (a person computes the
  weekly savings plan and sends it; a person books the appointment and confirms it).
- **Measures**: continuation (still participating in week 2 / week 4), requests for
  more, manual effort per user (the first cost signal).
- **Wizard of Oz** (the user believes it is automated) is acceptable only for low-stakes
  flows and must be disclosed afterwards; anything that moves money or touches
  sensitive decisions runs as a disclosed concierge.
- **Cannot tell you**: unit economics at scale, automated edge cases.

### Path: code

- **Build**: the thinnest runnable slice against sandboxes and fixtures — the payment
  provider's sandbox, the identity provider's test app, a messaging test sender — built
  by the `prototyper` agent (Phase 6).
- **Measures**: does it work end to end, success and error rates across N runs,
  latency, the failure modes the third party exposes.
- **Loop**: the user runs it, reports what happened; two to four fix rounds are normal.
  Two hours without a runnable state ⇒ stop, shrink the question or switch paths.
- **Cannot tell you**: whether users want it.

Recommend a path with one sentence of reasoning, then capture the choice with
`AskUserQuestion` (options: the four paths, recommended first with ` (Recommended)`).
A path choice is a major decision in `guided` mode.

---

## Phase 5: Plan the Prototype

Present the plan in 3–5 bullets and confirm it before building:

- **Hypothesis and threshold** (Phase 3) and the assumption it retires.
- **Minimum build** — the least that answers the question; everything else is cut
  (settings, account pages, error states, animations, polish — unless one of them *is*
  the question).
- **Participants or traffic** — segment, how they are recruited, n, consent.
- **Measures** — what is recorded, by whom, where (session notes by participant ID;
  analytics events for a fake door).
- **Time box** — build ≤ 1 day; sessions or traffic within about a week.
- **Data and keys** — synthetic fixtures, sandbox credentials from a local `.env`, the
  preview URL plan if sessions are remote.

**Scope rule**: one prototype tests one assumption. If the plan covers more, split it
into two prototypes or cut.

Confirm with `AskUserQuestion`: `Build it` / `Adjust the plan` / `Stop here`.

Then checkpoint the session: ask "May I write this to
`production/session-state/active.md`?" and record the concept name, directory,
hypothesis, path, scope bullets and "Phase 6 — Build", so a new session can resume a
multi-day build.

---

## Phase 6: Build

**Name** — `<name>` is a short kebab-case slug of the concept (`payday-autodebit`,
`plus-shared-goals`); the directory is `prototypes/<name>-concept/`. If it already
exists from an earlier attempt, pick a new slug (`payday-autodebit-v2`) — the `-concept`
suffix always comes last.

Ask: "May I create `prototypes/<name>-concept/` and write [file list]?"

**Every file starts with the prototype header** in its comment syntax
(`<!-- … -->` in HTML, `#` in YAML or Python):

```
// PROTOTYPE - NOT FOR PRODUCTION
// Question: [the hypothesis being tested]
// Date: [YYYY-MM-DD]
```

**Relaxed on purpose**: hard-coded values, copy-paste, one file, faked steps, no tests,
no error handling beyond what the hypothesis needs. **Never relaxed**: the data, keys
and exposure rules above.

By path:

- **clickable** — write `index.html` (or the minimal Vite/Expo app) yourself. For a
  Figma prototype the user builds, write only the session plan (Phase 7) and a
  `prototype-link.md` with the share link.
- **fake-door** — write the page(s) and the analytics event list (`fake-door-events.md`:
  event names, what each proves). Hand the preview deploy command to the user; do not
  run it.
- **concierge** — write `operator-script.md`, `message-templates.md` and
  `checklist.md`.
- **code** — spawn `prototyper` via `Agent`. The prompt carries the hypothesis, the
  path, the scope bullets, the directory, the time box and which sandbox credentials
  exist. The prototyper proposes its build (scope, file list, the commands the user
  will run) and asks before writing — relay the proposal and its questions to the user
  with `AskUserQuestion`; on approval, spawn it again (or continue it, where the host
  supports that) with the approval and the exact file list. Then run the loop: the
  user runs the command, pastes errors or observations, the prototyper fixes. Two
  hours without a runnable state triggers the stop rule.

Update the session checkpoint to "Phase 7 — Sessions" when the build is usable.

---

## Phase 7: Run the Sessions and Collect Evidence

**Session plan** — spawn `ux-researcher` via `Agent` with the hypothesis, the threshold,
the segment, the path and the build. Ask it to **return** a session plan: screener,
tasks with explicit success criteria (or the fake-door exposure plan, or the concierge
schedule), a non-leading discussion guide, the consent script, and what to record.
Show it; ask "May I write this to `prototypes/<name>-concept/session-plan.md`?".

**Running** — the sessions are run by people (the user, the team, the researcher); this
skill waits for the evidence. Recommend: participants who match the segment and have
not seen the product; do not explain or help during a task — confusion is data;
think-aloud for comprehension questions; after the task ask "What was confusing?" rather
than "Did you like it?".

**No external participants available?** Hallway sessions with people outside the team
are weaker but real. A builder's own walkthrough surfaces blockers but is **not**
evidence for PROCEED — a report based only on it is NOT ASSESSED or a directional PIVOT.

**Synthesis** — give `ux-researcher` the raw observations (participant IDs only) and ask
it to return per-task success, measures against the threshold, issues by severity,
verbatim quotes with IDs, and the hypothesis outcome (SUPPORTED / REFUTED /
INCONCLUSIVE), with the sample's limits stated.

**Debrief** — then ask the user these questions **one at a time**, in plain text,
waiting for each answer:

1. "The hypothesis was: [hypothesis]. Did it hold — SUPPORTED, REFUTED or INCONCLUSIVE?
   What did you see?"
2. "What was the moment — if any — where it clearly worked? Be specific."
3. "What was the most confusing or broken moment? Not 'it felt slow' but 'three of five
   stopped at the account-connection step and asked whether the app could withdraw
   more than the goal amount'."
4. "Did anything happen you did not expect — good or bad?"
5. "PROCEED, PIVOT or KILL — and one sentence why?"

A vague answer ("it went fine") gets one follow-up: "What exactly went fine — which
task, which participant?"

---

## Phase 8: Write the Report

Read `.claude/docs/templates/prototype-report.md` and fill every section from the
evidence collected — no generic filler:

- `## Hypothesis` — as written in Phase 3, with the date it was written.
- `## Path` — the path, why, what it cannot tell you, what was built, deliberate
  shortcuts.
- `## Method` — participants or traffic, consent and data handling, tasks or scenario,
  measures, time box kept or exceeded.
- `## Results` — participants table, measures against the threshold, observations and
  quotes by participant ID, the hypothesis outcome.
- `## Verdict` — the recommendation reasoned from the results:
  - **PROCEED** — the threshold was met by target-segment participants with sound
    evidence.
  - **PIVOT** — partly met, or met for a different segment or job than intended;
    something close to working is worth changing and re-testing.
  - **KILL** — refuted by sound evidence, or the Phase 10 kill check applies.
  - **NOT ASSESSED** — the evidence supports none of the three (sessions not run,
    off-segment participants only, sample below the planned minimum, sandbox never
    reached); name the missing evidence and how to get it.
- `## Next Step` — per the verdict (Phase 10).

Directly under the H1, after one blank line, the verdict line:
`> **Verdict**: PROCEED` (or `PIVOT`, `KILL`, `NOT ASSESSED`), followed by the review
line and the remaining status lines. When Phase 9 will not spawn the gate — the review
mode skips it, or the verdict is NOT ASSESSED — write the Phase 9 note in place of the
review line now, so the report needs no second write; otherwise leave the placeholder
for Phase 9 to fill.

Show the report; ask "May I write this to `prototypes/<name>-concept/REPORT.md`?".

---

## Phase 9: User Validation Review (PD-USER-VALIDATION)

**Review mode check** — apply before spawning PD-USER-VALIDATION (`--review` overrides
the resolved `review_mode`):
- `full` → spawn as normal.
- `lean` → **skip every gate whose ID does not end in `-PHASE-GATE`**. Note: `[GATE-ID] skipped — Lean mode`
- `solo` → skip all gates. Note: `[GATE-ID] skipped — Solo mode`

PD-USER-VALIDATION does not end in `-PHASE-GATE`, so `lean` and `solo` skip it: the
report's review line is the skip note `> [PD-USER-VALIDATION] skipped — Lean mode` (or
`— Solo mode`), written in Phase 8; continue. A report whose verdict is NOT ASSESSED
has no recommendation to review: its review line is
`> [PD-USER-VALIDATION] not run — verdict NOT ASSESSED`, and the summary prints
`NOT CHECKED — PD-USER-VALIDATION (no PROCEED / PIVOT / KILL to review)`.

When it runs, spawn `product-director` via `Agent`:
- Gate: **PD-USER-VALIDATION** — the prompt instructs the agent to read
  `.claude/docs/director-gates/pd-user-validation.md` first (do not read it yourself).
- Pass: report path (usability report, prototype REPORT.md or walking-skeleton report) · hypotheses tested · target segment · brief path
- Fill: `prototypes/<name>-concept/REPORT.md`; the hypothesis and threshold; the segment
  from the brief (or as the user stated it); `design/product/product-brief.md`,
  `design/product/one-pager.md`, or "none".

Parse the first line as `[PD-USER-VALIDATION]: TOKEN` (APPROVE / CONCERNS / REJECT) and
map it with `.claude/docs/director-gates.md` § Standard Verdict Format:

- **APPROVE-class** (`APPROVE`) → record
  `> **Product Director Review (PD-USER-VALIDATION)**: APPROVED <YYYY-MM-DD>` and continue.
- **CONCERNS-class** (`CONCERNS`) → present the gaps and the cheapest test that would
  close each, then `AskUserQuestion`: `Revise flagged items` (update the report or run
  more sessions, then re-run the gate → `REVISED`) / `Accept and proceed`
  (`CONCERNS (accepted)`) / `Discuss further`.
- **REJECT-class** (`REJECT`) → the value is not landing. Present the blockers; do not
  act on the verdict (no next-step hand-off as if PROCEED) until the user decides how
  to resolve it.
- A first line that does not parse is not an approval: treat it as CONCERNS-class and
  say the verdict line was missing.

The outcome line replaces the report's review-line placeholder — one update, together
with any verdict change below, after "May I write this to
`prototypes/<name>-concept/REPORT.md`?".

**The gate never changes the report's verdict by itself.** When it disagrees — REJECT
on a PROCEED, APPROVE on a KILL — surface the conflict with `AskUserQuestion`:
`Keep [verdict]` / `Change to [suggested verdict]` / `Run more sessions first`. The
user decides; a change is written to the report (verdict line and `## Verdict`, where
the disagreement and the decision are recorded) after "May I write this to
`prototypes/<name>-concept/REPORT.md`?". Neither side is silently kept.

---

## Phase 10: Act on the Verdict

### PROCEED

The riskiest assumption held. Carry the learning forward:

- The brief's `## Riskiest Assumptions` row becomes `Validated` with a link to the
  report (`/brainstorm` resumes the brief to record it).
- Production code is written from scratch; nothing here is refactored into the product.
- No brief yet (a prototype-first project): `/reverse-document brief
  prototypes/<name>-concept` drafts one from this evidence with
  `.claude/docs/templates/product-brief-from-prototype.md` — it never overwrites an
  existing brief without asking.
- A clickable or fake-door PROCEED says nothing about feasibility: if a feasibility
  risk remains, name the spike that would retire it.

### PIVOT

Capture the carry-forward before routing on. Ask in plain text, one at a time:

1. "What specifically worked that the next version must keep?"
2. "What is the single most important thing to change?"

Draft `PIVOT-NOTE.md`: the original hypothesis, what to keep, what to change, the
revised hypothesis with its threshold, and the suggested path. Ask "May I write this to
`prototypes/<name>-concept/PIVOT-NOTE.md`?". The next `/prototype` run starts from it
(Phase 2).

**Third PIVOT on the same concept** (count from Phase 2): put KILL on the table
explicitly — "Is this still the right idea, or the sunk-cost trap?" A fresh concept
prototyped cleanly usually beats a fourth iteration of a struggling one; two or three
different variants tested side by side beat iterating one to death.

### KILL

Check that the verdict is sound, not end-of-week frustration:

- [ ] Target-segment participants did not complete the core step, or did not take the
      first step, across two or more rounds.
- [ ] No moment of value observed — nobody asked to keep using it, sign-ups stayed
      below the threshold.
- [ ] Three or more PIVOTs with no clear improvement.
- [ ] It only works when the team explains it or guides the user.
- [ ] Viability breaks: unit cost, a third party's terms or regulation make it
      unworkable as designed.

Two or more boxes → the KILL is sound. Zero or one → offer one more focused PIVOT first.

Record the kill in the report's `## Verdict` — the specific reason (not "it was boring"
but "participants never trusted an app to move salary money automatically"), what
worked and is worth carrying to the next concept, what failed, and what to try
differently next time. The history of killed concepts is the set of reports whose
verdict line reads KILL — no separate list to maintain. Update the report with "May I
write this to `prototypes/<name>-concept/REPORT.md`?".

### Summary and next steps

```
Concept Prototype — [name]
==========================
Hypothesis:  [hypothesis] (threshold: [threshold])
Path:        [clickable | code | fake-door | concierge]
Evidence:    [n participants / visits / days] — [key measure vs threshold]
Review:      PD-USER-VALIDATION [outcome | skipped — mode | not run — NOT ASSESSED]
Record:      prototypes/[name]-concept/REPORT.md [+ PIVOT-NOTE.md]
Worktree:    [branch name] — bring prototypes/[name]-concept/ into the main working tree
Not checked: [every NOT CHECKED line of this run, or "none"]

Verdict: [PROCEED | PIVOT | KILL | NOT ASSESSED]
```

Fill `Worktree:` from `git branch --show-current` and `git status --short prototypes/`
(when the run did not happen in a separate worktree, say "main working tree").

Close with `AskUserQuestion` offering the next steps that apply:

- **PROCEED** — `/prd-review design/product/product-brief.md` (review the brief with
  this evidence) → `/gate-check definition` → `/map-features`; at `minimal`:
  `/create-stories`; without a brief: `/reverse-document brief prototypes/<name>-concept`.
- **PIVOT** — `/prototype [revised concept]` (starts from `PIVOT-NOTE.md`), or
  `/brainstorm` when the bet itself needs rethinking.
- **KILL** — `/brainstorm open` or `/brainstorm [new direction]`.
- **NOT ASSESSED** — run the missing sessions, then `/prototype report
  prototypes/<name>-concept`.

---

## Spike Mode (`--spike`)

A spike answers **one** technical or design question in about four hours. No
prerequisites, no phase-gate implications, no PROCEED / PIVOT / KILL — the result
informs a decision; the team makes it.

**When to use**: an integration nobody on the team has done (recurring charges on a
billing key, 알림톡 template variables, deep links from a push notification), a
performance question ("can the list render 1,000 transactions smoothly on a mid-range
Android phone?"), a design question that needs a real device, or a technical approach
before a story commits to it.

1. **Question** — plain text: "Give me one sentence: can we [do X] using [approach Y]?"
2. **Path** — code (default) or clickable, with the Phase 4 widget if unclear.
3. **Scope** — two or three bullets; one question, nothing else.
4. **Build** — directory `prototypes/<name>-spike-YYYY-MM-DD/` (today's date); ask "May
   I create `prototypes/<name>-spike-YYYY-MM-DD/` and write [file list]?"; the same
   header, relaxed standards and never-relaxed data rules as a concept prototype; code
   via `prototyper` as in Phase 6. **Hard cap about four hours** — if it is not
   demonstrable by then, the question is too large: split it and say so.
5. **Decide** — ask: "Did the spike answer the question — YES, NO or PARTIAL, and why in
   one sentence?" Collect the evidence: request/response samples with tokens redacted,
   benchmark numbers with device and conditions, screenshots.
6. **Record** — write `SPIKE-NOTE.md` after "May I write this to
   `prototypes/<name>-spike-YYYY-MM-DD/SPIKE-NOTE.md`?":

   ```markdown
   # Spike: [question in a few words]

   > **Verdict**: [YES | NO | PARTIAL | NOT ASSESSED]
   > **Date**: [YYYY-MM-DD] · **Time spent**: [hours]

   ## Question
   ## Approach
   ## Result
   ## Evidence
   ## Next Action
   ```

   `NOT ASSESSED` when the spike could not run (no sandbox access, the time box ran out
   before any result). `## Next Action`: add a story to the sprint, investigate further,
   abandon the approach, or record the decision as an ADR with
   `/architecture-decision`.
7. **Checkpoint** — update `production/session-state/active.md` (ask first) to clear the
   spike and return to the current work.

**Performance spike** — the question is a number, not a feeling: "can [component]
handle [load or data size] within [budget] on [the smallest planned device or
instance]?" Build only the load (a list with 1,000 rows, a burst of 50 requests per
second against a local endpoint), measure, and record the number with its conditions.
It is a feasibility signal, not a load test — load tests against staging belong to
`/load-test`. A NO here is an architecture or scope constraint worth surfacing before
the PRDs, not during a sprint.

---

## Report Mode (`report <prototype-dir>`)

Completes the record for a prototype directory that has none — the remediation the
session-start gap check suggests for an unrecorded prototype.

1. **Validate** — the directory exists under `prototypes/`. If it already has
   `REPORT.md` (or, for a spike directory, `SPIKE-NOTE.md`), ask "May I overwrite
   `[dir]/REPORT.md`?" — default no; on no, stop.
2. **Spike directories** (`prototypes/<name>-spike-YYYY-MM-DD/`) get `SPIKE-NOTE.md` in
   the Spike Mode format instead of a report.
3. **Reconstruct** — read everything in the directory: the file headers
   (`// Question:`), a README, notes, the code. Draft `## Hypothesis`, `## Path` and
   what was built from them, and mark the hypothesis "written after the fact" — weaker
   evidence.
4. **Ask for the evidence** in plain text: who used it, what they did, what was
   measured, what was decided at the time. Everything nobody can supply is written
   `NOT DETERMINED — <reason>`.
5. **Verdict** from the evidence, as in Phase 8; with no usable evidence the verdict is
   NOT ASSESSED.
6. **Write** — show the report; ask "May I write this to `[dir]/REPORT.md`?".
7. **Directory name** — `/gate-check` and `/help` count only
   `prototypes/*-concept/REPORT.md`. If the directory lacks the `-concept` suffix and was
   a concept prototype, tell the user the directory would need to be renamed to
   `prototypes/<name>-concept/` to be counted; do not rename it yourself.
8. **Review** — run Phase 9 when the verdict is PROCEED, PIVOT or KILL.
9. **The brief is not touched here.** For a product brief drafted from this prototype:
   `/reverse-document brief [dir]`.

---

## Important Constraints

- One prototype tests one assumption; if the scope grows, stop and split the question.
- Time boxes: a concept build takes at most a day; a spike about four hours; two hours
  without a runnable state means shrink or switch paths — say so, never continue
  silently past a time box.
- Prototype code never imports from the product's source, and the product never
  imports from `prototypes/`. On PROCEED, production code is written from scratch.
- Perceived speed on a laptop is not perceived speed on a phone on a mobile network:
  when speed is the question, test on a mid-range device with network throttling
  (browser developer tools, the Android emulator's network profiles, Apple's Network
  Link Conditioner).
- Small samples are directional. Five sessions find usability problems; they do not
  prove demand — say "3 of 5 participants", never "60% of users".
- The verdict is a recommendation to the product manager and the user, reviewed by the
  product director through PD-USER-VALIDATION when the review mode runs it.

---

## Collaborative Protocol

1. **Question → Options → Decision → Draft → Approval** — the hypothesis, the path, the
   plan and the verdict are the user's decisions; this skill brings the method and the
   evidence.
2. **"May I write this to `<path>`?"** before every write — the prototype files, the
   session plan, the session checkpoint, `REPORT.md`, `PIVOT-NOTE.md`, `SPIKE-NOTE.md`.
3. **Evidence over opinion** — observations by participant ID, measures against a
   threshold decided in advance, `NOT DETERMINED` where nothing was observed.
4. **Skips announce themselves** — a gate skipped by review mode leaves its skip note in
   the report and a line in the summary.
5. **No auto-execution** — deploy commands and next skills are offered, never run.
6. **No commits** — committing is the user's decision.
7. **Language** — converse in the user's conversation language; in every file written,
   template headings, bold field labels, verdict tokens, IDs and paths stay in English
   exactly as the template spells them (root `CLAUDE.md` § Language Policy).
