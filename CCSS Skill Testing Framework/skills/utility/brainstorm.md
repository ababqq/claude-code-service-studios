# Skill Spec: /brainstorm

> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-09-28

<!-- Assertions quote the canonical English text of .claude/skills/brainstorm/SKILL.md —
     prompts, AskUserQuestion option labels, verdict tokens, headings — never the
     wording the model uses at run time in the user's conversation language. -->

## Skill Summary

`/brainstorm` is guided product discovery. From no idea (`open`), a problem space or a
clear concept, it facilitates — never authors — the product bet: problem & evidence →
users & Jobs-to-be-Done (optional personas drafted by `ux-researcher`) → alternatives &
positioning → value proposition & business-model hypothesis → **Product Principles &
Anti-Goals** (PD-PRINCIPLES) → optional **Brand Direction Anchor** (DD-BRAND-DIRECTION,
only at `full` with a UI surface) → success metrics (North Star + guardrails) →
riskiest assumptions & tests → MVP scope (TD-FEASIBILITY and DM-SCOPE in parallel) →
write → "May I set `project.name` and `project.category` in `project.yaml`?".

The resolved `workflow` tier picks the document: `design/product/one-pager.md` at
`minimal` (the One-Pager Flow, M1–M8), `design/product/product-brief.md` at
`standard`/`full`. Optional outputs: `design/product/personas/<slug>.md` and, in `pitch`
mode, `design/product/pitch.md`. Facts come from a source fetched in the run, from disk
or from the user — otherwise they are written as a hypothesis or `NOT SOURCEABLE`. The
run ends with `Verdict: COMPLETE` or `Verdict: INCOMPLETE` — or `Verdict: NOT ASSESSED` when a
required input is missing (`pitch` with neither a brief nor a one-pager).

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`); `name: brainstorm` equals the directory `.claude/skills/brainstorm/` and the catalog entry `brainstorm`
- [ ] `description` is exactly "Guided product discovery: problem, JTBD, users, alternatives, value proposition, business model, principles, metrics, riskiest assumptions."
- [ ] `argument-hint` is `"[open | <problem space> | pitch] [--review full|lean|solo]"`; `model: sonnet`; no `disable-model-invocation` and no `isolation` key
- [ ] Bootstrap: the first body line is `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,docs.density,workflow,surfaces,stack,compliance,team.size` `` — this key string exactly
- [ ] `allowed-tools` grants `Bash(bash "*/.claude/skills/brainstorm/../../hooks/yaml-helper.sh" resolve_config *)` — the skill's own directory name
- [ ] The line after the bootstrap block is exactly ``Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] The automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") follows that line verbatim
- [ ] `allowed-tools` is exactly: `Read, Glob, Grep, Write, Edit, WebSearch, Agent, AskUserQuestion` + the grant (membership exact; no plain `Bash`, no `WebFetch`)
- [ ] 2+ phase headings (`## Phase 0` … `## Phase 12`, plus ``## One-Pager Flow (`workflow: minimal`)`` and ``## Pitch Mode (`/brainstorm pitch`)``)
- [ ] Verdict tokens present exactly: `COMPLETE`, `INCOMPLETE`, `NOT ASSESSED`; gate tokens `APPROVE`, `CONCERNS`, `REJECT`, `VIABLE`, `HIGH RISK`, `REALISTIC`, `UNREALISTIC`, `OPTIONS`, `STRONG`
- [ ] "May I write this to `<path>`?" before every write (brief, each section update per automation mode, each persona, one-pager, pitch) and "May I set `project.name` and `project.category` in `project.yaml`?" before the configuration write
- [ ] Outputs at the exact paths `design/product/product-brief.md`, `design/product/one-pager.md`, `design/product/personas/<slug>.md`, `design/product/pitch.md`; `project.yaml` only for `project.name` and `project.category`
- [ ] Each spawn's `Pass:` line equals the gate's Context bullets (`.claude/docs/director-gates.md` § Context to Pass) and the first reply line is parsed as `[GATE-ID]: TOKEN`
- [ ] No `!` injection other than the bootstrap line; no `file:line` citations of other files
- [ ] `### 0e. Gate context lines` uses the `stack`, `compliance` and `team.size` lines of the bootstrap block — no run-time `resolve_config` call
- [ ] Next-step handoff at the end names current skills (`/setup-stack`, `/prd-review`, `/prototype`, `/gate-check definition`, `/map-features`; at `minimal` `/create-stories`, `/dev-story`)

---

## Director Gate Checks

| Gate | Owner | Spawned at | Condition |
|---|---|---|---|
| PD-PRINCIPLES | product-director | Phase 5 (One-Pager Flow M7) | always offered |
| DD-BRAND-DIRECTION | design-director | Phase 6 | `full` tier, a UI surface, and the user wants brand direction now |
| TD-FEASIBILITY | technical-director | Phase 9 (M7), in parallel with DM-SCOPE | always offered |
| DM-SCOPE | delivery-manager | Phase 9 (M7), in parallel with TD-FEASIBILITY | always offered |

- **Full mode**: every gate above spawns when its condition holds; each prompt tells the agent to read `.claude/docs/director-gates/<gate-id>.md` first (the parent never reads it)
- **Lean mode**: skip every gate whose ID does not end in `-PHASE-GATE` — note `[GATE-ID] skipped — Lean mode`. None of the four ends in `-PHASE-GATE`, so all four are skipped
- **Solo mode**: no gates — note `[GATE-ID] skipped — Solo mode`
- Unset on an unconfigured project: `modes.rigor` defaults to `minimal`, which resolves `review_mode` to `solo`

---

## Test Cases

### Case 1: Happy Path — Moa at `standard`, problem-space hint

**Fixture** (assumed project state):
- `project.yaml`: `modes.rigor: standard` (resolves `workflow: standard`, `review_mode: lean`, `docs.density: balanced`); `platform.surfaces` unset; `modes.automation: collaborative`
- No `design/product/` files; no `project.name`

**Input:** `/brainstorm a savings app that saves on payday`

**Expected behavior:**
1. Announces "Workflow tier `standard` — this run writes `design/product/product-brief.md`."
2. Uses the `stack`, `compliance` and `team.size` lines the bootstrap block printed
3. Runs Phases 1–4; open questions (e.g. "Tell me about the last time…") are plain text, choices use `AskUserQuestion`
4. Phase 4d: shows the drafted sections and asks "May I write this to `design/product/product-brief.md`?"; writes the file from `.claude/docs/templates/product-brief.md` with Status `Draft`
5. Phases 5 and 9 apply the review-mode check: `lean` skips PD-PRINCIPLES, TD-FEASIBILITY and DM-SCOPE and writes their skip notes into the brief's status block
6. Phase 6 is not offered at `standard`: "Brand direction is set in `/design-language`." — the `## Brand Direction Anchor` section and its review line are omitted
7. Phase 10 checks the seven sections `/gate-check definition` requires are not placeholders, then asks "May I write this to `design/product/product-brief.md`?"
8. Phase 11 asks "May I set `project.name` and `project.category` in `project.yaml`?", edits only those two keys inside the `project:` block and re-reads the file
9. Phase 12 prints the summary with `Verdict: COMPLETE` and closes with `AskUserQuestion` offering the `standard / full` next steps

**Assertions:**
- [ ] Brief headings are the template's, in order, in English (`## Problem Statement`, `## Target Users & Jobs-to-be-Done`, `## Value Proposition`, `## Product Principles & Anti-Goals`, `## Success Metrics`, `## Riskiest Assumptions`, `## MVP Scope`, …)
- [ ] The status block holds `> [PD-PRINCIPLES] skipped — Lean mode`, `> [TD-FEASIBILITY] skipped — Lean mode`, `> [DM-SCOPE] skipped — Lean mode`
- [ ] `project.yaml` gains only `project.name` and `project.category` — never `project.stage`, `stack.*`, `modes.*` or any of the six knobs `modes.rigor` fronts
- [ ] Every riskiest assumption has a named test; `/prototype` is recommended for a top value or usability risk
- [ ] The summary's `Not checked:` line lists each NOT SOURCEABLE item and skipped step, or "none"

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Blocked — TD-FEASIBILITY returns HIGH RISK

**Fixture:**
- `modes.rigor: full` (`review_mode: full`); a brief draft through Phase 8 on disk
- The riskiest assumption: auto-debit on payday through Toss Payments without a billing-key agreement
- `technical-director` replies `[TD-FEASIBILITY]: HIGH RISK`; `delivery-manager` replies `[DM-SCOPE]: REALISTIC`

**Input:** `/brainstorm` (resuming the draft)

**Expected behavior:**
1. Phase 9 spawns TD-FEASIBILITY and DM-SCOPE in parallel (both `Agent` calls issued before waiting)
2. The strictest class decides: HIGH RISK is REJECT-class — the failing assumption moves to the top of `## Riskiest Assumptions` with the director's cheapest test
3. `## MVP Scope` is not finalized; the concept or scope is revised with the user and TD-FEASIBILITY is re-run
4. If the user stops here, the run ends `Verdict: INCOMPLETE` and the draft keeps its last approved state

**Assertions:**
- [ ] The skill does not move past Phase 9 on an unresolved REJECT-class verdict
- [ ] Each gate's line is recorded separately (DM-SCOPE's APPROVED line is kept)
- [ ] The summary names what is missing; `COMPLETE` is not printed

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: NOT ASSESSED — `pitch` with no brief or one-pager

**Fixture:**
- Neither `design/product/product-brief.md` nor `design/product/one-pager.md` exists

**Input:** `/brainstorm pitch`

**Expected behavior:**
1. Pitch Mode step 1 finds no source document
2. Stops with "There is no brief to pitch from — run `/brainstorm` first. Verdict: NOT ASSESSED — no brief or one-pager to pitch from."

**Assertions:**
- [ ] The stop names the missing input and the skill that produces it
- [ ] `design/product/pitch.md` is not written and no gate is spawned
- [ ] No `COMPLETE` verdict is produced for the pitch; no market number is invented to fill the gap
- [ ] The run ends `Verdict: NOT ASSESSED — no brief or one-pager to pitch from.` (NOT ASSESSED ranks below INCOMPLETE and above COMPLETE)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Mode Variant — `minimal` One-Pager Flow

**Fixture:**
- `project.yaml` without `modes.rigor` (resolves `workflow: minimal`, `review_mode: solo`)

**Input:** `/brainstorm payday savings for first-job workers`

**Expected behavior:**
1. Announces "Workflow tier `minimal` — this run writes `design/product/one-pager.md`."
2. M1 proposes 2–3 one-line pitches and asks via `AskUserQuestion` with the pitches, `Combine elements`, `Something else — I'll describe it` — asked in every automation mode
3. M2–M6 fill `## Problem & Target User`, `## Core User Journey`, `## Success Signal`, `## Scope & Non-Goals`, `## Stack`, `## Build Order`
4. M7 asks "May I write this to `design/product/one-pager.md`?" (Status `Draft`), then applies the review-mode check: three `Solo mode` skip notes
5. M8 finalizes after "May I write this to `design/product/one-pager.md`?", then runs Phases 11 and 12

**Assertions:**
- [ ] No `design/product/product-brief.md` is written
- [ ] The one-pager's seven headings match `.claude/docs/templates/one-pager.md`
- [ ] `## Stack` records a preference as a proposal and names `/setup-stack` when the stack is not pinned
- [ ] Next steps are the `minimal` list (`/setup-stack`, `/create-stories`, `/dev-story`, optional `/prototype`)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Edge Case — Resume an existing brief; unsourced market facts

**Fixture:**
- `design/product/product-brief.md` exists with Phases 1–5 filled and `## Success Metrics` still a placeholder
- The user asks for a market size; no source is fetched in the run

**Input:** `/brainstorm`

**Expected behavior:**
1. Phase 0f reads the brief and asks `Refine the existing brief` / `Start a new one`; a new one requires "May I overwrite `[path]`?" before any write
2. On refine, jumps to the first missing or thin section (`## Success Metrics`)
3. The requested market size is written as a labelled hypothesis or `NOT SOURCEABLE — <what was searched>`, never as fact
4. Existing evidence (`design/product/personas/*.md`, verdict lines of `prototypes/*-concept/REPORT.md`, `production/qa/usability/*.md`) is read, not re-asked

**Assertions:**
- [ ] The brief is not replaced without the explicit overwrite question
- [ ] Every fact carries `Source: <url>, retrieved YYYY-MM-DD` or is labelled hypothesis / `NOT SOURCEABLE`
- [ ] Interview findings cite participant IDs, never names

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Director Gate — full mode

**Fixture:**
- `modes.rigor: full` (resolves `workflow: full`, `review_mode: full`); `platform.surfaces: [web, ios, android]`; `compliance.regions: [kr]`
- The user wants brand direction now

**Input:** `/brainstorm payday savings`

**Expected behavior:**
1. Phase 5 spawns `product-director` for **PD-PRINCIPLES** with `Pass: brief path (draft) · drafted principles & anti-goals text · target users & JTBD summary · named alternatives`; the prompt tells the agent to read `.claude/docs/director-gates/pd-principles.md` first
2. Phase 6 spawns `design-director` for **DD-BRAND-DIRECTION** with ``Pass: brief path · product principles text · target users · resolved `surfaces` line``; on `OPTIONS` the user picks via `AskUserQuestion` (one option per direction, `Combine elements across directions`, `Describe my own direction`)
3. Phase 9 spawns **TD-FEASIBILITY** (``Pass: one-line concept "<category> service on <surfaces> using <stack>" · riskiest assumptions list · resolved `stack` line (or "unset") · resolved `compliance` line``) and **DM-SCOPE** (``Pass: MVP scope text (brief, one-pager or feature map path) · resolved `team.size` · target milestone/date (or "none given")``) in parallel
4. `[DM-SCOPE]: CONCERNS` is surfaced via `AskUserQuestion`: `Revise flagged items` / `Accept and proceed` / `Discuss further`
5. Each outcome is recorded, e.g. `> **Product Director Review (PD-PRINCIPLES)**: APPROVED 2026-10-02`, or `CONCERNS (accepted)` / `REVISED`

**Assertions:**
- [ ] Each first reply line is parsed as `[GATE-ID]: TOKEN` and mapped to its class; an unparseable line is treated as CONCERNS-class and named
- [ ] The parent never reads a gate file itself
- [ ] A CONCERNS-class verdict is surfaced via AskUserQuestion (revise / accept / discuss)
- [ ] The skill does not auto-advance past a CONCERNS-class or REJECT-class verdict

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: Director Gate — lean mode

**Fixture:**
- Same as Case 6, run with `--review lean`

**Input:** `/brainstorm payday savings --review lean`

**Expected behavior:**
1. Each spawn point applies the review-mode check; `lean` skips every gate whose ID does not end in `-PHASE-GATE`
2. The brief's status block receives `> [PD-PRINCIPLES] skipped — Lean mode`, `> [DD-BRAND-DIRECTION] skipped — Lean mode`, `> [TD-FEASIBILITY] skipped — Lean mode`, `> [DM-SCOPE] skipped — Lean mode`
3. The skipped DD-BRAND-DIRECTION leaves `## Brand Direction Anchor` omitted (brand direction moves to `/design-language`)

**Assertions:**
- [ ] Output contains `[GATE-ID] skipped — Lean mode` for each of the four gates
- [ ] No `Agent` call is made for a director gate
- [ ] The summary's `Gates:` line reports each skip

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 8: Director Gate — solo mode

**Fixture:**
- `modes.rigor: standard` with `--review solo`

**Input:** `/brainstorm payday savings --review solo`

**Expected behavior:**
1. No director gate spawns
2. The status block receives `> [PD-PRINCIPLES] skipped — Solo mode`, `> [TD-FEASIBILITY] skipped — Solo mode`, `> [DM-SCOPE] skipped — Solo mode`; DD-BRAND-DIRECTION is not applicable at `standard` and the summary says why

**Assertions:**
- [ ] Output contains `[GATE-ID] skipped — Solo mode` for each gate that applied
- [ ] Personas may still be drafted by `ux-researcher` (a consultation, not a gate) when the user asks

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses "May I write this to `<path>`?" before every file write and the `project.yaml` question before the configuration write
- [ ] Presents each drafted section before requesting approval; section approval follows the automation mode
- [ ] Which bet or pitch to develop is asked in every automation mode
- [ ] Ends with a recommended next step (AskUserQuestion) and never runs it
- [ ] Writes no evidence, reports or plans under `production/session-logs/`
- [ ] Never writes `modes.review_mode` or any other knob that `modes.rigor` fronts
- [ ] Converses in the user's language; file headings, bold labels, verdict tokens, IDs and paths stay in English

---

## Category Rubric (`utility`)

- `utility U1` — the static checks above pass: bootstrap line and grant exact, `--keys` exact, `--review` follow-on line, automation prelude, "May I write" before each write, output paths exact
- `utility U2` — gate mode correct: `review_mode` from the config block (`--review` overrides), lean suffix rule, solo skip notes (Cases 6–8)
- The NOT ASSESSED case is Case 3 (missing input: no brief to pitch from)

---

## Coverage Notes

- The `guided` and `autonomous` variants of Phase 5 (ask once / lock and `log_decision`) are not fixture-tested.
- UNREALISTIC from DM-SCOPE follows the Case 2 shape (cut list or later date, then re-run).
- Web searches depend on network access; a run without it must mark facts `NOT SOURCEABLE` (Case 5).
