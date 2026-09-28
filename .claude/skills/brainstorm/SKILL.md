---
name: brainstorm
description: "Guided product discovery: problem, JTBD, users, alternatives, value proposition, business model, principles, metrics, riskiest assumptions."
argument-hint: "[open | <problem space> | pitch] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, WebSearch, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/brainstorm/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,docs.density,workflow,surfaces,stack,compliance,team.size`

Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

# Product Discovery

This skill turns a problem space — or no idea at all — into a written product bet the
rest of the pipeline can build on: who has the problem, what they use today, why a new
product is worth switching to, how it makes money, the principles that will settle
future arguments, how success is measured, which assumptions could sink it and how to
test them, and the smallest product that tests the bet with real users.

The AI is a **facilitator**, not the author of the user's product. Explore together,
bring techniques and evidence, draft on request — the decisions are the user's.

### Outputs

| Path | When | Template |
|------|------|----------|
| `design/product/product-brief.md` | `workflow` = `standard` or `full` | `.claude/docs/templates/product-brief.md` |
| `design/product/one-pager.md` | `workflow` = `minimal` | `.claude/docs/templates/one-pager.md` |
| `design/product/personas/<slug>.md` | optional, `standard`/`full` (drafted by `ux-researcher`) | `.claude/docs/templates/persona.md` |
| `design/product/pitch.md` | `pitch` mode | `.claude/docs/templates/pitch-document.md` |
| `project.yaml` | `project.name`, `project.category` only — asked first | — |

The brief and the one-pager are the two tier alternatives of the Discovery step
`product-brief`: `/gate-check definition` reads the brief at `standard`/`full` and the
one-pager at `minimal`.

### What this skill never does

- **Write any other `project.yaml` key.** Never `project.stage`, `stack.*` or
  `modes.*`, and never one of the six knobs `modes.rigor` fronts (`modes.review_mode`,
  `modes.workflow`, `docs.density`, `qa.level`, `modes.story_granularity`,
  `team.size`) — a written value would shadow the rigor expansion.
- **Invent evidence.** Market sizes, competitor facts and user numbers come from a
  source fetched in this run (`Source: <url>, retrieved YYYY-MM-DD`), from files on
  disk, or from the user — otherwise they are written as a labelled hypothesis or
  `NOT SOURCEABLE — <what was searched>`. Interview findings cite participant IDs,
  never names.
- **Read a gate definition file.** The spawned agent reads it; this skill passes the
  path and the context items (`.claude/docs/director-gates.md`).
- **Choose the stack.** Technology preferences the user mentions are recorded as
  input for `/setup-stack`, which pins them from live sources.

---

## Phase 0: Configuration, Mode and Resume

### 0a. Parse the arguments

| `$ARGUMENTS` | Mode |
|---|---|
| `open` or empty | Open exploration — start from the person and the problems they notice |
| `pitch` | **Pitch Mode** (section at the end) — needs an existing brief or one-pager |
| anything else | A problem space or a concept hint (e.g. `small clinics' phone bookings`, `a savings app that saves on payday`) |

`--review full|lean|solo` may follow any mode; it overrides the resolved
`review_mode` for every gate this run.

**Fast path.** When the hint or the user's first answer already states a clear
concept — who it is for, the problem, what the product does — do not re-explore it.
Phases 1–4 become confirmation steps: draft each section from what the user said,
show it, and ask what to correct. Spend the time on principles, metrics, riskiest
assumptions and scope, where a clear concept is usually thinnest.

### 0b. Tier branch — check `workflow` first

- **`minimal`** → run the **One-Pager Flow** below and stop. Output:
  `design/product/one-pager.md`.
- **`standard` / `full`** → run Phases 1–12. Output:
  `design/product/product-brief.md`. `full` adds the optional brand direction step
  (Phase 6) when a UI surface ships.

Announce it in one line: "Workflow tier `[value]` — this run writes `[path]`."

### 0c. Depth — `docs.density`

`workflow` decides which document exists; `docs.density` decides how deep each
section goes. Apply it to every section you draft:

- `terse` — principle and brief bullets; one line per table cell.
- `balanced` — principles and brief with short rationale.
- `thorough` — principles and brief with extensive rationale and the alternatives
  considered for each decision.

### 0d. Surfaces

The resolved `surfaces` line says where the product ships (`web`, `ios`, `android`,
`api`). A **UI surface** is any of `web`, `ios`, `android`. When the line is unset,
the answer is unknown — never "no UI". Ask the user when a step depends on it (the
one-line concept for TD-FEASIBILITY, Phase 6); keep the answer for this run only —
`platform.surfaces` is written by `/setup-stack`.

### 0e. Gate context lines

TD-FEASIBILITY needs the resolved `stack` and `compliance` lines, DM-SCOPE the
`team.size` line, and the one-pager's `## Stack` section the `stack` line — all printed
by the block above. Use them as printed, including their unset forms:
`stack: unset — run /setup-stack` is "unset", and a compliance part printed
`(unset -- ask)` is an open question, never "no obligations". No block ⇒ pass "unset",
`(unset -- ask)` and "unresolved" and say so in the summary.

### 0f. Resume, don't restart

Before asking anything:

- If the output file for this tier exists, read it. Ask with `AskUserQuestion`:
  `Refine the existing [brief / one-pager]` / `Start a new one` (a new one replaces
  the file — confirm with "May I overwrite `[path]`?" before any write). When refining,
  jump to the first phase whose section is missing, thin or `NOT DETERMINED`, and let
  the user pick the others to revisit.
- If the *other* tier's file exists (a one-pager on a project now at `standard`),
  read it and use it as the starting draft.
- Read `design/product/personas/*.md`, and the verdict lines of
  `prototypes/*-concept/REPORT.md` and `production/qa/usability/*.md` — existing
  evidence is used, not re-asked.
- Read `project.name` and `project.category` from `project.yaml`; if set, use them
  as the working name and category.

### 0g. Facilitation rules

- **Explain, then capture.** Write the analysis in conversation first; then use
  `AskUserQuestion` with concise labels to capture the decision.
- **Open answers stay open.** Questions whose answer is free text — "tell me about the
  last time this happened", "which apps do you use for this today" — are asked as
  plain text, never as `AskUserQuestion` with preset options.
- **A single choice is a plain list.** Use `prompt` + `options`; use tabs only when
  several independent fields are captured at once.
- **Past behaviour over opinions.** "When did this last happen and what did you do?"
  beats "Would you use an app that…?" — people are reliably poor predictors of their
  own future behaviour.
- **Withhold judgement while exploring**; converge only when a phase asks for a
  decision. Build on the user's ideas ("yes, and…") rather than replacing them.
- **Section approval** follows the automation mode: `collaborative` approves each
  section; `guided` asks only for the major decisions marked below and states the
  rest inline; `autonomous` picks the recommended option and records it with
  `log_decision`.

---

## Director Gates in This Skill

| Gate | Owner | Where | Condition |
|------|-------|-------|-----------|
| PD-PRINCIPLES | `product-director` | Phase 5 (One-Pager Flow: step M7) | always offered |
| DD-BRAND-DIRECTION | `design-director` | Phase 6 | only at `full` with a UI surface, and only when the user wants brand direction now |
| TD-FEASIBILITY | `technical-director` | Phase 9, in parallel with DM-SCOPE (M7) | always offered |
| DM-SCOPE | `delivery-manager` | Phase 9, in parallel with TD-FEASIBILITY (M7) | always offered |

Every spawn follows `.claude/docs/director-gates.md`:

1. **Apply the review-mode check** written at the spawn point, first.
2. **Spawn the owner via `Agent`.** The prompt tells the agent to read
   `.claude/docs/director-gates/<gate-id>.md` first; the parent never reads it. The
   `Pass:` line lists the gate's context items, filled in at run time.
3. **Parse the first line of the reply as `[GATE-ID]: TOKEN`** and map TOKEN to its
   class (`.claude/docs/director-gates.md` § Standard Verdict Format):
   - **APPROVE-class** (`APPROVE`, `VIABLE`, `REALISTIC`, `STRONG`) → continue.
   - **CONCERNS-class** (`CONCERNS`) → present the findings, then `AskUserQuestion`:
     `Revise flagged items` / `Accept and proceed` / `Discuss further`.
   - **REJECT-class** (`REJECT`, `HIGH RISK`, `UNREALISTIC`) → present the blockers.
     Do not write the affected section or move past the phase until the content is
     revised and the gate re-run. If the user stops here, the run ends INCOMPLETE and
     the draft keeps its last approved state.
   - **Selection** (`OPTIONS`, DD-BRAND-DIRECTION only) → present the directions, the
     user selects, then continue as APPROVE-class.
   - A first line that does not parse, names another gate, or carries a token not on
     that gate's verdict line is not an approval: treat it as CONCERNS-class and say
     the verdict line was missing.
4. **Record the outcome** in the draft's status block, one line per gate:
   `> **Product Director Review (PD-PRINCIPLES)**: APPROVED <YYYY-MM-DD>` — or
   `CONCERNS (accepted)`, or `REVISED` after a re-run on revised content. When the
   review mode skipped the gate, write its skip note there instead (for example
   `> [PD-PRINCIPLES] skipped — Solo mode`) — it is the evidence the mode was applied.

---

## One-Pager Flow (`workflow: minimal`)

A hackathon-to-seed-sized session: capture the load-bearing thinking on one page, then
get to code. Keep the prompting light — a handful of exchanges, not fifteen. Author
from `.claude/docs/templates/one-pager.md`; its seven headings are a contract.

**M1. Pitch** — from the hint (or one open question if there is none), propose **2–3
one-line pitches**, each a different angle on the problem (a different segment, a
different job, a different mechanism). Capture the choice with `AskUserQuestion`:
the pitches, `Combine elements`, `Something else — I'll describe it`. **This choice
is asked in every automation mode**: which product the user wants to build has no
defensible automatic default.

**M2. Problem & Target User** — who, concretely; what goes wrong for them today, in
their words; what they use today (including "doing nothing").

**M3. Core User Journey** — 3–5 steps from first open to the moment of value, and what
brings the user back.

**M4. Success Signal** — one measurable signal that the product works; it is what
every story's acceptance criteria trace back to.

**M5. Scope & Non-Goals** — the short "in" list (push back past about seven items),
the "not now" list, and optionally one principle the team will not trade away.

**M6. Stack and Build Order** — `## Stack`: when the resolved `stack` line (0e)
shows a pinned stack, restate it in one line; otherwise record the user's preference
as a proposal and name `/setup-stack` as the next step. `## Build Order`: the sequence
to build the scope, riskiest or most valuable item first; each item becomes a story.

**M7. Draft and review.** Show the filled one-pager in full. Ask "May I write this to
`design/product/one-pager.md`?" and write it (Status `Draft`, directories created as
needed). Then the gates, in parallel, each after its own review-mode check:

**Review mode check** — apply to PD-PRINCIPLES, TD-FEASIBILITY and DM-SCOPE, each separately
before its spawn (`--review` overrides the resolved `review_mode`):
- `full` → spawn as normal.
- `lean` → **skip every gate whose ID does not end in `-PHASE-GATE`**. Note: `[GATE-ID] skipped — Lean mode`
- `solo` → skip all gates. Note: `[GATE-ID] skipped — Solo mode`

At the `minimal` tier the review mode usually resolves to `solo`, so the usual outcome
is three skip notes in the one-pager's status block — the record that the mode was
applied. When gates run, spawn the surviving ones simultaneously:

- `product-director` — gate **PD-PRINCIPLES**
  - Pass: brief path (draft) · drafted principles & anti-goals text · target users & JTBD summary · named alternatives
  - Fill: `design/product/one-pager.md`; the `## Scope & Non-Goals` principle line and
    "not now" list; `## Problem & Target User`; the alternatives it names.
- `technical-director` — gate **TD-FEASIBILITY**
  - Pass: one-line concept "<category> service on <surfaces> using <stack>" · riskiest assumptions list · resolved `stack` line (or "unset") · resolved `compliance` line
  - Fill: the concept line; the first `## Build Order` item and anything the user
    called uncertain; the 0e lines.
- `delivery-manager` — gate **DM-SCOPE**
  - Pass: MVP scope text (brief, one-pager or feature map path) · resolved `team.size` · target milestone/date (or "none given")
  - Fill: `design/product/one-pager.md`; the 0e `team.size` line; the date the user
    gave, or "none given".

Handle each verdict as in § Director Gates in This Skill, revise the one-pager with the
user where needed, and record the outcomes.

**M8. Finalize** — show what changed since the draft; ask "May I write this to
`design/product/one-pager.md`?"; set Status `Approved` when the user confirms the
content is final. Then run Phase 11 (project name and category) and Phase 12 (summary
and next steps), and stop.

---

## Phase 1: Problem & Evidence

Understand the problem before any solution. Ask conversationally, not as a checklist:

- **The moment it hurts** — "Tell me about the last time you (or someone you know)
  ran into this. What happened? What did you do?" (plain text)
- **Who else** — "Who has this problem worst? Who has it but doesn't care?"
- **Cost** — money, time, stress, risk; how often it recurs.
- **Workarounds** — what people already do, pay for or build themselves (a strong
  signal: people who hack a workaround have a real problem).
- **Why now** — what changed (regulation, a platform or payment rail, behaviour,
  cost of a technology) that makes this solvable or urgent now.
- **Evidence** — what the user already has: interviews, support tickets, analytics,
  their own experience. Rate each high / medium / low confidence.

**When evidence is thin** (the usual case at this point), say so plainly and carry it
forward as a riskiest assumption (Phase 8) — do not smooth it over. Offer a quick
market-context search with `WebSearch` if the user wants it; cite each fact with its
source and retrieval date.

**Open mode** (no hint): start from the person, not the product — which problems do
they keep noticing at work or in daily life, which customers do they understand
unusually well, what have they built workarounds for? Collect 3–5 problem candidates,
then ask with `AskUserQuestion` which one to pursue.

Synthesize a **Problem Statement** draft (template section of the same name). Read it
back and ask the user to correct it.

---

## Phase 2: Users & Jobs-to-be-Done

- **Primary segment** — concrete enough that a recruiter could screen for it. Push
  back on "everyone", "young people", "SMBs".
- **Jobs-to-be-Done** — 2–5 job statements in the form "When [situation], I want to
  [motivation], so I can [expected outcome]", tagged functional / emotional / social,
  each with its evidence.
- **Forces of progress** — push (away from today's way), pull (toward a new way),
  anxiety (about switching), habit (keeping them in place). Anxiety and habit are
  where products that look obviously better lose.
- **Secondary segments and who this is not for.**

**Personas (offer at `standard` and `full`).** Ask with `AskUserQuestion`:
`Draft personas now` / `Later` / `Not needed`. On "now", spawn `ux-researcher` via
`Agent` with the segment, the job statements, the forces and the evidence gathered so
far; ask it to **return** one persona draft per distinct segment in the headings of
`.claude/docs/templates/persona.md`, citing evidence by participant ID and labelling
unsupported statements `Hypothesis:` — and not to write files itself. Show each draft,
then ask "May I write this to `design/product/personas/<slug>.md`?" (`<slug>` =
kebab-case of the persona name). Link the written personas in the brief's
`### Personas`.

Record the section draft for `## Target Users & Jobs-to-be-Done`.

---

## Phase 3: Alternatives & Positioning

- List every alternative the segment uses today, **including doing nothing** and
  non-product workarounds (a spreadsheet, a group chat, a manual transfer, an agency).
- For each: what users hire it for, where it falls short, how this product would
  differ.
- **Competitor scan (optional)** — with the user's agreement, use `WebSearch` for
  direct and adjacent products in the target market (for the Korean market include
  the incumbents' own apps and the super-apps). Cite each fact with its source and
  retrieval date; mark anything unverifiable `NOT SOURCEABLE`.
- Draft a **positioning statement**: "For [target segment] who [need], [product] is a
  [market category] that [key benefit]. Unlike [best alternative], we [primary
  differentiator]." Test it: if the differentiator also describes the main
  alternative, it is not a differentiator.

---

## Phase 4: Value Proposition & Business-Model Hypothesis

### 4a. Generate candidate bets

Unless the fast path applies, generate **2–3 distinct bets** — each a different answer
to "what would make the segment switch?". Useful techniques:

- **Outcome-first** — pick the job's most underserved outcome and design backward from
  it.
- **10× on one dimension** — radically better on the one attribute the segment cares
  most about (effort, speed, trust, price), acceptable on the rest.
- **Unbundle or rebundle** — take one job out of a heavy incumbent, or combine jobs
  users currently stitch together across products.
- **Service first** — deliver the value by hand (concierge) and automate what proves
  valuable.
- **Shift-enabled** — build on a recent change in regulation, platform capability or
  payment rails (name the change and its source).
- **Cross-market analog** — a model proven in another market or category, adapted to
  this segment (state what differs locally — payments, identity, messaging channels,
  regulation).

For each bet present: **working name** · **one-line value proposition** · **target
segment** · **core user journey** (3–5 steps) · **success moment** · **business-model
sketch** · **why now** · **biggest risk**.

Then capture the choice with a plain-list `AskUserQuestion`:

```
AskUserQuestion(
  prompt: "Which bet do you want to develop? You can pick one, combine elements, or ask for fresh directions.",
  options: [
    "Bet 1 — [name]",
    "Bet 2 — [name]",
    "Bet 3 — [name]",
    "Combine elements across bets",
    "Generate fresh directions"
  ]
)
```

**This choice is asked in every automation mode.** Which product the user wants to
build has no defensible automatic default; the site overrides the mode the same way
the always-ask categories do.

### 4b. Value proposition

Draft `## Value Proposition` for the chosen bet: the value hypothesis ("We believe
[segment] will [behaviour] because [value]; we will know when [signal]"), pains
relieved, gains created, the success moment, and why this team.

### 4c. Business-model hypothesis

Work through the template's table: revenue model, price point, who pays, key costs,
acquisition channels, unit economics targets, constraints. Everything here is a
hypothesis with a confidence and a test. Name regulatory questions that change the
model (for example whether the product holds customer money) as open questions — this
skill does not give legal conclusions.

### 4d. Create the draft brief

The gates from Phase 5 on review the brief on disk, so create it now. Show the drafted
sections (`## Elevator Pitch` through `## Business Model Hypothesis`) and ask "May I
write this to `design/product/product-brief.md`?". Write it from
`.claude/docs/templates/product-brief.md` with Status `Draft`, the filled sections,
and the remaining sections left as the template's placeholders. From here on, each
approved section is written into this file as the phase that produces it completes —
so the draft on disk is always the latest approved state. In `collaborative` mode ask
"May I write this section to `design/product/product-brief.md`?" before each update;
in `guided` mode updates to this existing file proceed after a short summary; in
`autonomous` mode they are written directly and logged.

---

## Phase 5: Product Principles & Anti-Goals

Collaboratively define **3–5 product principles**. Each principle has:

- a **name** and a **one-sentence definition**;
- a **decision test** — "When [X] conflicts with [Y], we choose [X] — even though it
  costs [Z]" — so two people who disagree about a feature can settle it by citing
  the principle;
- the **job it serves** from Phase 2.

Quality bar: a principle nobody could violate ("user first", "simple and fast")
carries no weight; a principle every alternative already follows is table stakes, not
positioning; a set where every principle points the same way resolves no real
trade-off. Principles should create productive tension with each other, with a
priority order when they collide.

Then define **3+ anti-goals** — what the product will never become, even if asked —
each naming the principle it protects ("We will not [thing] because it would
compromise [principle]"). Anti-goals must rule out things a reasonable team would be
tempted to build, not strawmen.

**Confirmation** — present the full set, then `AskUserQuestion`:
`Lock these in` / `Rename or reframe one` / `Swap one out` / `Something else`.
- **`collaborative`** — revise and ask again until the user picks `Lock these in`.
- **`guided`** — principles are a major decision: ask once, apply the chosen revision,
  then lock without a second round.
- **`autonomous`** — do not ask; lock the drafted set and record it with
  `log_decision`, listing the alternatives considered (an unasked question has no
  "until" to wait for).

**Review mode check** — apply before spawning PD-PRINCIPLES (`--review` overrides the
resolved `review_mode`):
- `full` → spawn as normal.
- `lean` → **skip every gate whose ID does not end in `-PHASE-GATE`**. Note: `[GATE-ID] skipped — Lean mode`
- `solo` → skip all gates. Note: `[GATE-ID] skipped — Solo mode`

PD-PRINCIPLES does not end in `-PHASE-GATE`, so `lean` and `solo` skip it: write
`> [PD-PRINCIPLES] skipped — Lean mode` (or `— Solo mode`) into the brief's status
block and continue.

When it runs, spawn `product-director` via `Agent`:
- Gate: **PD-PRINCIPLES** — the prompt instructs the agent to read
  `.claude/docs/director-gates/pd-principles.md` first.
- Pass: brief path (draft) · drafted principles & anti-goals text · target users & JTBD summary · named alternatives
- Fill: `design/product/product-brief.md`; the principles and anti-goals exactly as
  locked; the segment and job statements from Phase 2; the alternatives from Phase 3.

Parse `[PD-PRINCIPLES]: TOKEN` (APPROVE / CONCERNS / REJECT) and handle it per
§ Director Gates in This Skill. On CONCERNS the agent suggests rewrites — show them
side by side with the locked text before the user chooses. On REJECT the principles do
not constrain decisions yet: rewrite them with the user and re-run the gate before
Phase 6.

Write `## Product Principles & Anti-Goals` and the review line into the brief.

---

## Phase 6: Brand Direction Anchor (optional)

The brief's `## Brand Direction Anchor` is optional; when it is absent,
`/design-language` runs brand direction itself later. Offer this step only when all
of these hold — otherwise omit the section (heading included), delete the template's
DD-BRAND-DIRECTION review line, and say why in one line:

- `workflow` is `full` (at `standard`: "Brand direction is set in `/design-language`.");
- the product has a UI surface — from the `surfaces` line, or, when it is unset, from
  asking the user "Will people use this through a web or mobile interface?" (an `api`-
  only product: "No UI surface — no brand direction needed.");
- the user wants it now — ask with `AskUserQuestion`: `Set brand direction now` /
  `Defer to /design-language`.

**Review mode check** — apply before spawning DD-BRAND-DIRECTION (`--review` overrides
the resolved `review_mode`):
- `full` → spawn as normal.
- `lean` → **skip every gate whose ID does not end in `-PHASE-GATE`**. Note: `[GATE-ID] skipped — Lean mode`
- `solo` → skip all gates. Note: `[GATE-ID] skipped — Solo mode`

When skipped, write the skip note (`> [DD-BRAND-DIRECTION] skipped — Lean mode`) into
the brief's status block and omit the section: brand directions come from the
design director, and `/design-language` will ask for them when the brief has no
anchor.

When it runs, spawn `design-director` via `Agent`:
- Gate: **DD-BRAND-DIRECTION** — the prompt instructs the agent to read
  `.claude/docs/director-gates/dd-brand-direction.md` first.
- Pass: brief path · product principles text · target users · resolved `surfaces` line
- Fill: `design/product/product-brief.md`; the locked principles; the primary segment
  and personas; the `surfaces` line as resolved, or the user's answer marked "(asked
  in this run)".

Parse `[DD-BRAND-DIRECTION]: TOKEN` (OPTIONS / STRONG / CONCERNS):
- **OPTIONS** — present the 2–3 directions with `AskUserQuestion`: one option per
  named direction, `Combine elements across directions`, `Describe my own direction`.
- **STRONG** — present the dominant direction with the runner-up; the user still
  chooses.
- **CONCERNS** — the principles do not differentiate a brand yet: offer to revise the
  named principle (re-running PD-PRINCIPLES if it changes), accept and defer the
  anchor to `/design-language`, or discuss. A gate that ran keeps its review line even
  when the anchor is deferred and the section omitted.

Write the chosen direction into `## Brand Direction Anchor` (direction, brand rule,
personality, color philosophy, typography direction, platform stance, rejected
directions) and record the review line.

---

## Phase 7: Success Metrics

- **North Star metric** — one metric that captures value *delivered* to users, not
  activity (for a savings product: users with a successful automatic transfer this
  week, not app opens). Give its exact definition (event or query), baseline (for a
  new product: "none — new product"), target and date, and data source.
- **Guardrail metrics** — at least one: what must not get worse while the North Star
  rises (payment failure rate, opt-out or unsubscribe rate, support contacts per
  1,000 active users, refund rate, crash-free sessions).
- **Input metrics** (optional) — leading indicators per lifecycle stage: acquisition,
  activation (the success moment), retention (D1 / D7 / D30), monetization.

Targets are hypotheses; label them so. Offer `WebSearch` benchmarks only with sources.
Write `## Success Metrics`.

---

## Phase 8: Riskiest Assumptions & Tests

List the beliefs that would sink the product if wrong, across the four risks:

- **Value** — will the segment want it enough to switch?
- **Usability** — can they figure it out and trust it?
- **Feasibility** — can we build and operate it — including third parties (payment
  providers, identity providers, messaging channels, app store review)?
- **Viability** — does it work for the business — costs, pricing, regulation?

Rank by impact × uncertainty. For each, name the **cheapest test** that would retire
it — a clickable prototype, interviews, a fake door, a concierge run, existing data, a
vendor call, a sandbox spike — and its pass signal. Every assumption gets a test (the
Discovery → Definition gate checks this at `full`). Set Status `Untested` unless
evidence on disk already answers it (link it).

Recommend `/prototype` for the top assumption when it is a value or usability risk.
Write `## Riskiest Assumptions`.

---

## Phase 9: MVP Scope & Non-Goals

- **MVP scope** — the smallest product that tests the value hypothesis with real users
  and can be released to them. Each capability traces to a job or an assumption; push
  back on capabilities that trace to neither. Note the work outside feature code that
  early teams forget: sign-up and account deletion, consent and privacy notices,
  support tooling, analytics instrumentation, app store and payment-provider review
  lead times.
- **Target** — ask for a milestone and date (plain text); "none given" is a valid
  answer.
- **After the MVP** — one line per later tier (Beta, GA, Later); `/map-features`
  formalizes them.
- **Non-goals** — what is out of this release and why ("not now"; anti-goals are
  "never").

Show the scope; confirm it with `AskUserQuestion` (`Looks right` / `Cut more` /
`Add something` / `Something else`) — a major decision in `guided` mode.

**Review mode check** — apply to TD-FEASIBILITY and to DM-SCOPE, each separately before
its spawn (`--review` overrides the resolved `review_mode`):
- `full` → spawn as normal.
- `lean` → **skip every gate whose ID does not end in `-PHASE-GATE`**. Note: `[GATE-ID] skipped — Lean mode`
- `solo` → skip all gates. Note: `[GATE-ID] skipped — Solo mode`

Neither ID ends in `-PHASE-GATE`: under `lean` or `solo` write both skip notes into the
brief's status block and continue.

When they run, spawn both in parallel — issue both `Agent` calls before waiting for
either:

- `technical-director` — gate **TD-FEASIBILITY** (the agent reads
  `.claude/docs/director-gates/td-feasibility.md` first)
  - Pass: one-line concept "<category> service on <surfaces> using <stack>" · riskiest assumptions list · resolved `stack` line (or "unset") · resolved `compliance` line
  - Fill: the concept line from the category, the surfaces (resolved or asked) and the
    stack (or "an undecided stack"); the Phase 8 table; the 0e lines as printed.
- `delivery-manager` — gate **DM-SCOPE** (the agent reads
  `.claude/docs/director-gates/dm-scope.md` first)
  - Pass: MVP scope text (brief, one-pager or feature map path) · resolved `team.size` · target milestone/date (or "none given")
  - Fill: `design/product/product-brief.md` plus the scope text; the 0e `team.size`
    line; the target, or "none given".

Parse `[TD-FEASIBILITY]: TOKEN` (VIABLE / CONCERNS / HIGH RISK) and
`[DM-SCOPE]: TOKEN` (REALISTIC / CONCERNS / UNREALISTIC). Apply the escalation rule:
the strictest class decides the next action, and each gate's line is recorded
separately.

- **HIGH RISK** — the assumption that fails goes to the top of `## Riskiest
  Assumptions` with the director's cheapest test; revise the concept or the scope with
  the user, then re-run TD-FEASIBILITY.
- **UNREALISTIC** — present both options the director gives: the cut list and a date
  that fits the current scope. Revise scope or target with the user, then re-run
  DM-SCOPE.
- **CONCERNS** from either — the standard revise / accept / discuss question.

Write `## MVP Scope`, `## Non-Goals` and the review lines into the brief.

---

## Phase 10: Finalize the Brief

1. **Completeness pass** — every section of the template has real content or an
   explicit `NOT DETERMINED — <what would answer it>`; `## Open Questions` collects
   every open item raised during the run (owner, how it will be answered, by when).
   The seven sections `/gate-check definition` requires — `## Problem Statement`,
   `## Target Users & Jobs-to-be-Done`, `## Value Proposition`,
   `## Product Principles & Anti-Goals`, `## Success Metrics`,
   `## Riskiest Assumptions`, `## MVP Scope` — must not be left as placeholders.
2. **Status block** — Owner, Last Updated, Category, Workflow Tier, and one review
   line (or skip note) per gate that applied. Status stays `Draft` until
   `/prd-review` has reviewed the brief.
3. **Headings** — exactly the template's, in order, in English; body in the user's
   conversation language. Remove the template's guidance comments and unused example
   rows.
4. Show the complete brief (or, in `guided` mode, a summary of what changed since the
   last approved write) and ask "May I write this to
   `design/product/product-brief.md`?".

---

## Phase 11: Project Name and Category

Propose the two values the rest of the framework reads:

- `project.name` — the product's working name (`/onboard` and `/release-notes` use it).
- `project.category` — a short market category such as `B2C fintech (subscription
  savings)` or `B2B SaaS (clinic scheduling)` (`/setup-stack` and the settings
  guidance use it).

If both are already set to these values, skip this phase. Otherwise show the lines
that will change (old → new where a value exists) and ask — in every automation mode,
because `project.yaml` is the team's shared configuration — "May I set `project.name`
and `project.category` in `project.yaml`?"

On yes: Read `project.yaml`, then Edit it — add the two keys inside the existing
`project:` block, or create that block directly after the `framework:` block. Change
nothing else. Re-read the file and confirm both values are present; say so in one
line. On no: leave `project.yaml` untouched and say that `/settings` can set them later.

---

## Phase 12: Summary, Verdict and Next Steps

```
Product Discovery — [brief | one-pager]
=======================================
Product:        [name] — [category]
Bet:            [one-line value proposition]
Segment:        [primary segment]
Principles:     [names] (one-pager: [the principle line or "none"])
North Star:     [metric] · guardrails: [metrics]   (one-pager: success signal)
Top risk:       [assumption] → test: [test]
MVP:            [n capabilities] · target: [date or "none given"]
Gates:          PD-PRINCIPLES [outcome] · DD-BRAND-DIRECTION [outcome | not applicable — reason] · TD-FEASIBILITY [outcome] · DM-SCOPE [outcome]
Written:        [paths written this run]
Not checked:    [every NOT SOURCEABLE item, unset input and skipped step, or "none"]

Verdict: [COMPLETE | INCOMPLETE | NOT ASSESSED]
```

- **COMPLETE** — the brief (or one-pager) is written with every required section
  filled or explicitly `NOT DETERMINED`, and no REJECT-class gate verdict is
  unresolved.
- **INCOMPLETE** — the run stopped before the final write, or a REJECT-class verdict
  is unresolved. Name what is missing; the draft on disk is the resume point for the
  next `/brainstorm` run.
- **NOT ASSESSED** — nothing could be produced because a required input is missing:
  `pitch` with neither a brief nor a one-pager (Pitch Mode step 1). Name the input and
  `/brainstorm`.

Precedence: INCOMPLETE > NOT ASSESSED > COMPLETE.

Then close with `AskUserQuestion` offering the next steps for the resolved tier — only
the ones that apply, in this order:

**`standard` / `full`**
1. `/setup-stack` — when the stack is not pinned yet: choose and pin the stack layers
   already decided.
2. `/prd-review design/product/product-brief.md` — review the brief (the Discovery →
   Definition gate requires a review at these tiers).
3. `/prototype` — test the top riskiest assumption before writing PRDs (recommended
   when it is a value or usability risk).
4. `/gate-check definition` — once the brief is reviewed and the stack is pinned.
5. `/map-features` — decompose the brief into features, dependencies and MVP / Beta /
   GA / Later tiers.

**`minimal`**
1. `/setup-stack` — when the stack is not pinned yet.
2. `/create-stories` — turn the one-pager's `## Build Order` into stories.
3. `/dev-story` — implement the first story.
4. `/prototype` — optional, when the first Build Order item is really a question.

**Any tier**: `/brainstorm pitch` — turn the brief into an investor or stakeholder
pitch.

---

## Pitch Mode (`/brainstorm pitch`)

Writes `design/product/pitch.md` from `.claude/docs/templates/pitch-document.md` using
the brief. It spawns no director gate.

1. **Source** — read `design/product/product-brief.md`; at `minimal`, or when no brief
   exists, `design/product/one-pager.md`. With neither, stop: "There is no brief to
   pitch from — run `/brainstorm` first. Verdict: NOT ASSESSED — no brief or one-pager
   to pitch from." When the brief is `Draft` and has not been
   reviewed, say so; the pitch inherits its gaps.
2. **Audience** — ask who the pitch is for (seed investors, an accelerator, an internal
   investment committee, a partner); it changes emphasis, not facts.
3. **Evidence** — read `prototypes/*-concept/REPORT.md` (verdict lines and results) and
   `production/qa/usability/*.md` for traction. Ask the user for traction figures and
   team details that are not on disk.
4. **Market** — size TAM / SAM / SOM bottom-up (people who could buy × what they would
   pay), with the user's agreement to search: every input carries
   `(Source: <url>, retrieved YYYY-MM-DD)` or is labelled `Assumption:`. Never present
   an unsourced number as fact.
5. **Draft** section by section at the resolved `docs.density`: Problem, Solution,
   Why Now, Market, Traction, Business Model, Team, The Ask. Where the brief and the
   pitch would disagree, fix the brief first.
6. Show the pitch and ask "May I write this to `design/product/pitch.md`?". Summarize
   with the verdict (COMPLETE, or INCOMPLETE with the missing sections), then offer
   next steps: `/prd-review design/product/product-brief.md` if the brief is
   unreviewed, `/prototype` to add traction evidence.

---

## Context Window Awareness

This is a long, multi-phase skill. From Phase 4d on, the approved state lives in the
draft brief on disk, so progress survives a new session. If context reaches or exceeds
70%, append this notice to the current response before continuing:

> **Context is approaching the limit (≥70%).** The approved sections are saved in
> `design/product/product-brief.md` (Status: Draft). Open a fresh session and run
> `/brainstorm` again — it resumes from the first missing section.

---

## Collaborative Protocol

1. **Question → Options → Decision → Draft → Approval** at every phase; the user owns
   every product decision, the AI brings techniques, evidence and drafts.
2. **"May I write this to `<path>`?"** before every write — the draft brief, each
   section update (per the automation mode), each persona, the one-pager, the pitch —
   and "May I set `project.name` and `project.category` in `project.yaml`?" before the
   configuration write.
3. **Evidence over assertion** — sourced facts, participant IDs, confidence levels;
   `NOT SOURCEABLE` and `NOT DETERMINED` instead of plausible guesses.
4. **Skips announce themselves** — a gate skipped by review mode leaves its skip note
   in the artifact and a line in the summary; a step that did not apply (brand
   direction at `standard`, no UI surface) is named with its reason.
5. **No auto-execution** — next steps are offered, never run.
6. **No commits** — committing is the user's decision.
7. **Language** — converse in the user's conversation language; in every file written,
   template headings, bold field labels, verdict tokens, IDs and paths stay in English
   exactly as the template spells them (root `CLAUDE.md` § Language Policy).
