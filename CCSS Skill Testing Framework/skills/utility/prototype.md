# Skill Spec: /prototype

> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-09-28

<!-- Assertions quote the canonical English text of .claude/skills/prototype/SKILL.md —
     prompts, AskUserQuestion option labels, verdict tokens, headings — never the
     wording the model uses at run time in the user's conversation language. -->

## Skill Summary

`/prototype` builds the cheapest test of the riskiest assumption — in a day, in front
of real target users within a week, then thrown away — and records what it proved. It
states a falsifiable hypothesis (behaviour, metric, threshold) **before** building,
picks one of four paths (`clickable`, `fake-door`, `concierge`, `code`), builds under
`prototypes/<name>-concept/` (code through the `prototyper` agent), has `ux-researcher`
return the session plan and synthesis, and writes `REPORT.md` from
`.claude/docs/templates/prototype-report.md` with the verdict line
`> **Verdict**: PROCEED | PIVOT | KILL | NOT ASSESSED` directly under the H1. A PIVOT
adds `PIVOT-NOTE.md`. The recommendation is reviewed by PD-USER-VALIDATION when the
review mode runs it; the gate never changes the verdict by itself.

Two more modes: `--spike` answers one technical or design question in about four hours
and writes `prototypes/<name>-spike-YYYY-MM-DD/SPIKE-NOTE.md` (verdict YES / NO /
PARTIAL / NOT ASSESSED, no phase-gate implications); `report <prototype-dir>` writes
the missing `REPORT.md` for an existing prototype directory. The skill declares
`isolation: worktree`, never uses real personal data or production keys, never
collects real payments, and never deploys — a preview deploy is proposed as a command
for the user to run.

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`); `name: prototype` equals the directory `.claude/skills/prototype/` and the catalog entry `prototype`
- [ ] `description` is exactly "Concept prototype to test the riskiest assumption — clickable, fake-door, concierge or code spike. PROCEED/PIVOT/KILL."
- [ ] `argument-hint` is `"[concept-description] [--path clickable|code|fake-door|concierge] [--review full|lean|solo] [--spike] | report <prototype-dir>"`; `model: sonnet`
- [ ] `isolation: worktree` is set; no `disable-model-invocation` key
- [ ] Bootstrap: the first body line is `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation` `` — this key string exactly
- [ ] `allowed-tools` grants `Bash(bash "*/.claude/skills/prototype/../../hooks/yaml-helper.sh" resolve_config *)` — the skill's own directory name
- [ ] The line after the bootstrap block is exactly ``Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] The automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") follows that line verbatim
- [ ] `allowed-tools` is exactly: `Read, Glob, Grep, Write, Edit, Bash, Agent, AskUserQuestion` + the grant
- [ ] 2+ phase headings (`## Phase 1: Parse Arguments and Choose the Mode` … `## Phase 10: Act on the Verdict`, plus ``## Spike Mode (`--spike`)`` and ``## Report Mode (`report <prototype-dir>`)``)
- [ ] Verdict tokens present exactly: `PROCEED`, `PIVOT`, `KILL`, `NOT ASSESSED`; spike tokens `YES`, `NO`, `PARTIAL`; gate tokens `APPROVE`, `CONCERNS`, `REJECT`
- [ ] "May I write this to `<path>`?" before every write — `production/session-state/active.md`, `prototypes/<name>-concept/session-plan.md`, `prototypes/<name>-concept/REPORT.md`, `prototypes/<name>-concept/PIVOT-NOTE.md`, `prototypes/<name>-spike-YYYY-MM-DD/SPIKE-NOTE.md`, `[dir]/REPORT.md` — and "May I create `prototypes/<name>-concept/` and write [file list]?" before the build
- [ ] Outputs at the exact paths `prototypes/<name>-concept/` (incl. `REPORT.md`, `PIVOT-NOTE.md`), `prototypes/<name>-spike-YYYY-MM-DD/SPIKE-NOTE.md`, `REPORT.md` in an existing directory (`report` mode); every report carries `> **Verdict**:` directly under its H1
- [ ] `prototyper` is spawned only where code is built (the `code` path, and a `--spike` built as code); `ux-researcher` returns the session plan and the synthesis, and this session writes them
- [ ] `--spike` spawns no director gate; `report <prototype-dir>` never replaces an existing record without "May I overwrite …?"
- [ ] Never uses real personal data or production keys (synthetic fixtures, sandbox or test credentials only)
- [ ] Writes no `prototypes/index.md` and no `prototypes/GRAVEYARD.md` — the history is derived from the `REPORT.md` and `PIVOT-NOTE.md` records
- [ ] No `!` injection other than the bootstrap line; no `file:line` citations of other files
- [ ] Next-step handoff at the end names current skills (`/prd-review`, `/gate-check definition`, `/map-features`, `/create-stories`, `/reverse-document brief`, `/brainstorm`, `/prototype report`)

---

## Director Gate Checks

- **Gate**: PD-USER-VALIDATION (owner `product-director`), Phase 9, after `REPORT.md` is written with a PROCEED, PIVOT or KILL verdict; also after `report` mode reaches one of those verdicts
- **Full mode**: spawns; the prompt tells the agent to read `.claude/docs/director-gates/pd-user-validation.md` first; ``Pass: report path (usability report, prototype REPORT.md or walking-skeleton report) · hypotheses tested · target segment · brief path``
- **Lean mode**: skip every gate whose ID does not end in `-PHASE-GATE` — note `[GATE-ID] skipped — Lean mode`; PD-USER-VALIDATION is skipped
- **Solo mode**: no gates — note `[GATE-ID] skipped — Solo mode`
- **NOT ASSESSED report**: nothing to review — review line `> [PD-USER-VALIDATION] not run — verdict NOT ASSESSED`
- **Spike mode**: no gate (no verdict class to review)

---

## Test Cases

### Case 1: Happy Path — Clickable prototype of Moa's payday auto-debit, PROCEED

**Fixture** (assumed project state):
- `modes.rigor: standard` (resolves `review_mode: lean`); `design/product/product-brief.md` with `## Riskiest Assumptions` row 1: "users will authorise an automatic payday transfer in their first session"
- No `prototypes/*-concept/` directory yet

**Input:** `/prototype payday auto-debit onboarding --path clickable`

**Expected behavior:**
1. Phase 2 reads the brief and Globs `prototypes/*-concept/REPORT.md` and `PIVOT-NOTE.md` (none)
2. Phase 3 writes the hypothesis with a behaviour, a metric and a threshold — e.g. "at least 4 of 5 target participants complete authorisation without help"
3. Phase 5 confirms the plan with `AskUserQuestion` (`Build it` / `Adjust the plan` / `Stop here`), then asks "May I write this to `production/session-state/active.md`?" for the checkpoint
4. Phase 6 asks "May I create `prototypes/payday-autodebit-concept/` and write [file list]?"; every file starts with the `PROTOTYPE - NOT FOR PRODUCTION` header, the question and the date
5. Phase 7 spawns `ux-researcher` to **return** a session plan; "May I write this to `prototypes/payday-autodebit-concept/session-plan.md`?"; the debrief questions are asked one at a time in plain text
6. Phase 8 fills every template section and writes `REPORT.md` with `> **Verdict**: PROCEED`; the lean skip note is written in place of the review line in the same write
7. Phase 10 prints the summary block (including `Worktree:`) and offers the PROCEED next steps via `AskUserQuestion`

**Assertions:**
- [ ] The hypothesis and threshold are decided before the build
- [ ] Fixtures are synthetic; participants appear only as P1, P2, …
- [ ] `REPORT.md` headings are `## Hypothesis`, `## Path`, `## Method`, `## Results`, `## Verdict`, `## Next Step`, in English
- [ ] The summary ends `Verdict: PROCEED` and names the worktree branch and the paths written
- [ ] No production code imports from `prototypes/`, and the prototype imports nothing from the product

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Blocked — The concept is too vague to test

**Fixture:**
- No brief; the user offers "an app people like"

**Input:** `/prototype an app people like`

**Expected behavior:**
1. Phase 3 cannot state a falsifiable hypothesis (no behaviour, no threshold)
2. The skill stops at Phase 3 and narrows the question with the user

**Assertions:**
- [ ] No directory is created and no file is written
- [ ] No verdict is produced — a prototype without a question is not built

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: NOT ASSESSED — No target-segment sessions were run

**Fixture:**
- `prototypes/plus-shared-goals-concept/` built; only the builder's own walkthrough was done; the planned minimum was 5 participants

**Input:** `/prototype plus shared goals` (continuing at Phase 7)

**Expected behavior:**
1. The builder's walkthrough surfaces blockers but is not evidence for PROCEED
2. `REPORT.md` is written with `> **Verdict**: NOT ASSESSED`, naming the missing evidence and how to get it
3. The review line is `> [PD-USER-VALIDATION] not run — verdict NOT ASSESSED`; the summary prints `NOT CHECKED — PD-USER-VALIDATION (no PROCEED / PIVOT / KILL to review)`
4. The next step offered is: run the missing sessions, then `/prototype report prototypes/plus-shared-goals-concept`

**Assertions:**
- [ ] Verdict is NOT ASSESSED with the missing evidence named — never PROCEED
- [ ] The gate is not spawned for a NOT ASSESSED report
- [ ] Thin evidence is not rounded up to a directional PROCEED

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Mode Variant — `--spike` on a billing-key integration

**Fixture:**
- A Toss Payments sandbox account exists (test credentials in a local `.env`, never committed)

**Input:** `/prototype --spike can we charge a saved billing key on the 25th of each month`

**Expected behavior:**
1. Asks for the question as one sentence ("Give me one sentence: can we [do X] using [approach Y]?")
2. Asks "May I create `prototypes/billing-key-charge-spike-YYYY-MM-DD/` and write [file list]?"; code is built through `prototyper` with the same header and data rules
3. Hard cap of about four hours; asks "Did the spike answer the question — YES, NO or PARTIAL, and why in one sentence?"
4. Writes `SPIKE-NOTE.md` after "May I write this to `prototypes/billing-key-charge-spike-YYYY-MM-DD/SPIKE-NOTE.md`?" with `> **Verdict**:` and the headings `## Question`, `## Approach`, `## Result`, `## Evidence`, `## Next Action`

**Assertions:**
- [ ] No PROCEED / PIVOT / KILL verdict and no PD-USER-VALIDATION spawn
- [ ] Evidence redacts tokens; no production key is requested, printed or pasted
- [ ] `NOT ASSESSED` is used if the sandbox could not be reached or the time box ran out before a result

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Edge Case — Third PIVOT on the same concept

**Fixture:**
- `prototypes/payday-autodebit-concept/PIVOT-NOTE.md` and `prototypes/payday-autodebit-v2-concept/PIVOT-NOTE.md` exist; this run's evidence partly meets the threshold

**Input:** `/prototype payday auto-debit v3`

**Expected behavior:**
1. Phase 2 starts from the latest PIVOT-NOTE's revised hypothesis and counts the PIVOTs in the chain
2. The new directory takes a fresh slug with the `-concept` suffix last (`payday-autodebit-v3-concept`)
3. On a third PIVOT, KILL is put on the table explicitly ("Is this still the right idea, or the sunk-cost trap?")
4. `PIVOT-NOTE.md` is written after "May I write this to `prototypes/payday-autodebit-v3-concept/PIVOT-NOTE.md`?"

**Assertions:**
- [ ] Earlier directories are never overwritten
- [ ] The KILL soundness checklist is applied before a KILL (two or more boxes)
- [ ] The history is derived from existing reports, not from a separate index

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Director Gate — full mode

**Fixture:**
- Same as Case 1, with `--review full`
- `product-director` replies `[PD-USER-VALIDATION]: CONCERNS` (the sample skewed to one age band)

**Input:** `/prototype payday auto-debit onboarding --path clickable --review full`

**Expected behavior:**
1. Phase 9 spawns `product-director` with the gate file path and the four-item `Pass:` line
2. Parses the first line as `[PD-USER-VALIDATION]: TOKEN`; CONCERNS is surfaced via `AskUserQuestion`: `Revise flagged items` / `Accept and proceed` / `Discuss further`
3. On `Accept and proceed`, the review line becomes `> **Product Director Review (PD-USER-VALIDATION)**: CONCERNS (accepted) <YYYY-MM-DD>` after "May I write this to `prototypes/payday-autodebit-concept/REPORT.md`?"
4. If the gate disagrees with the verdict (REJECT on a PROCEED), the conflict is surfaced with `Keep [verdict]` / `Change to [suggested verdict]` / `Run more sessions first`

**Assertions:**
- [ ] The parent never reads the gate file itself
- [ ] A CONCERNS-class verdict is surfaced via AskUserQuestion (revise / accept / discuss)
- [ ] The gate never changes the report's verdict by itself; neither side is silently kept
- [ ] An unparseable first line is treated as CONCERNS-class and named

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: Director Gate — lean mode

**Fixture:**
- Same as Case 1 (`review_mode: lean`)

**Input:** `/prototype payday auto-debit onboarding --path clickable`

**Expected behavior:**
1. PD-USER-VALIDATION does not end in `-PHASE-GATE`, so it is skipped
2. Phase 8 writes `> [PD-USER-VALIDATION] skipped — Lean mode` as the review line, so the report needs no second write

**Assertions:**
- [ ] Output contains `[PD-USER-VALIDATION] skipped — Lean mode`
- [ ] No `Agent` call is made for the gate; the summary's `Review:` line reports the skip

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 8: Director Gate — solo mode

**Fixture:**
- No `modes.rigor` (resolves `review_mode: solo`)

**Input:** `/prototype payday auto-debit onboarding --path fake-door`

**Expected behavior:**
1. No director gate spawns
2. The report's review line is `> [PD-USER-VALIDATION] skipped — Solo mode`

**Assertions:**
- [ ] Output contains `[PD-USER-VALIDATION] skipped — Solo mode`
- [ ] The fake-door follow-up says plainly the feature does not exist yet; no payment details are collected

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 9: Mode Variant — `report` for an unrecorded prototype directory

**Fixture:**
- `prototypes/goal-nudges/` (no `-concept` suffix) holds an `index.html` with a `// Question:` header and no `REPORT.md`

**Input:** `/prototype report prototypes/goal-nudges`

**Expected behavior:**
1. Reconstructs `## Hypothesis` and `## Path` from the files and marks the hypothesis "written after the fact"
2. Asks for the evidence in plain text; anything nobody can supply is `NOT DETERMINED — <reason>`
3. Writes after "May I write this to `prototypes/goal-nudges/REPORT.md`?"; with no usable evidence the verdict is NOT ASSESSED
4. Tells the user the directory would need to be renamed to `prototypes/goal-nudges-concept/` to be counted by `/gate-check` and `/help` — and does not rename it

**Assertions:**
- [ ] An existing `REPORT.md` is overwritten only after "May I overwrite `[dir]/REPORT.md`?" (default no)
- [ ] The directory is never renamed by the skill
- [ ] The product brief is not touched (`/reverse-document brief [dir]` is named for that)

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses "May I write this to `<path>`?" before every write
- [ ] Presents the hypothesis, path and plan for approval before building
- [ ] Ends with a recommended next step (AskUserQuestion) and never runs it; deploy commands are proposed, never run
- [ ] Writes no evidence under `production/session-logs/` (the session checkpoint in `production/session-state/active.md` is not evidence)
- [ ] Never writes `modes.review_mode` or any other knob that `modes.rigor` fronts
- [ ] Converses in the user's language; `REPORT.md` headings, verdict tokens, IDs and paths stay in English

---

## Category Rubric (`utility`)

- `utility U1` — the static checks above pass: bootstrap line and grant exact, `--keys` exact, `--review` follow-on line, automation prelude, "May I write" before each write, output paths exact with the verdict line
- `utility U2` — gate mode correct for PD-USER-VALIDATION (Cases 6–8)
- The NOT ASSESSED case is Case 3 (missing input: no target-segment sessions)

---

## Coverage Notes

- The `concierge` path and the `code` fix loop (two hours without a runnable state ⇒ stop) follow the Case 1 and
  Case 4 patterns; not fixture-tested separately.
- Worktree isolation depends on the host honouring `isolation: worktree`; the spec asserts only that the summary
  names the branch and the paths the user must bring over.
- The Korean advertising-consent rules for fake-door traffic (prior opt-in, separate night-time consent) are not
  asserted; Case 8 asserts only the honest "not available yet" follow-up and that no payment details are collected.
