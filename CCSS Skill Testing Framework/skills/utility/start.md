# Skill Spec: /start

> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-09-28

<!-- Assertions quote the canonical English text of .claude/skills/start/SKILL.md —
     prompts, AskUserQuestion option labels, verdict tokens, headings — never the
     wording the model uses at run time in the user's conversation language. -->

## Skill Summary

`/start` is first-time onboarding. It gathers context silently (configuration, product,
architecture, prototype and delivery artifacts, source manifests), then asks where the
user is starting from — A) no product idea yet, B) a problem space, C) a clear product
concept, D) an existing product or codebase — and routes to the immediate next step:
`/brainstorm open`, `/brainstorm <their words>`, `/brainstorm <their concept>` then
`/setup-stack`, or `/adopt` after running `bash .claude/scripts/stage-estimate.sh`.

It then sets exactly three settings in `project.yaml` — `project.stage` (`Discovery`
for A–C; the estimator's `STAGE:` for D), `modes.rigor` (one "what are you building?"
question: hackathon / prototype → `minimal`, seed-stage product team → `standard`,
regulated or enterprise → `full`, seeded from `.claude/docs/settings-guidance.md` § 2–3)
and `modes.automation` — with one "May I write this to `project.yaml`?" approval, and
never any of the six knobs `modes.rigor` fronts. It shows the path for the chosen rigor
and hands off with a single line. It runs before configuration exists, so it has no
bootstrap and is always collaborative. Verdicts: **COMPLETE**, or **NOT ASSESSED** when option D's
`stage-estimate.sh` cannot run.

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`); `name: start` equals the directory `.claude/skills/start/` and the catalog entry `start`
- [ ] `description` is exactly "First-time onboarding: where are you (A–D), then route to the right workflow."; `model: sonnet`; no `disable-model-invocation` and no `isolation` key
- [ ] Bootstrap: **none** — no `!` injection, no `resolve_config --keys` line and no `yaml-helper.sh` grant (the keys cell is empty); no rule-2 follow-on line
- [ ] No automation prelude (always-collaborative; `.claude/docs/automation-modes.md` § Exemptions — Skills That Ignore the Automation Setting)
- [ ] `allowed-tools` is exactly: `Read, Glob, Grep, Write, Edit, AskUserQuestion, Bash(bash .claude/scripts/stage-estimate.sh*)` (no plain `Bash`, no `Agent`)
- [ ] 2+ phase headings (`## Phase 1: Detect Project State` … `## Phase 9: Hand Off`)
- [ ] Verdict keywords present: `COMPLETE` and `NOT ASSESSED`
- [ ] Contains "May I write this to `project.yaml`?" — one approval for the whole change
- [ ] Output: `project.yaml`, keys `project.stage`, `modes.rigor`, `modes.automation` only; states that `/start` never writes `modes.review_mode`, `modes.workflow`, `docs.density`, `qa.level`, `modes.story_granularity`, `team.size`
- [ ] The Phase 2 prompt begins "Welcome to Claude Code Service Studios!" and the four option labels are `A) No product idea yet`, `B) A problem space`, `C) A clear product concept`, `D) An existing product or codebase`
- [ ] The rigor option labels are `Hackathon / prototype / side project`, `Seed-stage product team`, `Regulated or enterprise (fintech, health, B2B with SLAs)`, mapped to `minimal`, `standard`, `full`; the recommended option is first with ` (Recommended)` appended
- [ ] The automation options are `Collaborative`, `Guided`, `Autonomous`, mapped to `collaborative`, `guided`, `autonomous`
- [ ] Contains verbatim: "Unset on an unconfigured project: `modes.rigor` defaults to `minimal`, which resolves `review_mode` to `solo`."
- [ ] No `file:line` citations of other files; next-step handoff names current skills (`/brainstorm`, `/setup-stack`, `/adopt`, `/project-stage-detect`, `/reverse-document`, `/help`, `/settings`)

---

## Director Gate Checks

N/A. `/start` spawns no director gate and no agent: it has no keys and no `Agent` tool.

---

## Test Cases

### Case 1: Happy Path — Option C, a clear concept (Moa)

**Fixture** (assumed project state):
- The shipped `project.yaml` (no `project.stage`, no `modes:` block); no product artifacts; no manifests

**Input:** `/start` → `C) A clear product concept` → "Moa: a subscription savings app for first-job workers in Korea — web, iOS and Android; it moves money to a savings goal on payday; we are a seed-stage team of four" → the recommended rigor → `Collaborative`

**Expected behavior:**
1. Phase 1 gathers context silently and shows none of it unprompted
2. Phase 2 asks the welcome question with the four options and waits
3. Phase 3 plays the concept back in one sentence and names the immediate next steps `/brainstorm <their concept>` then `/setup-stack`, without describing which document `/brainstorm` produces
4. Phase 4 decides `project.stage: Discovery`
5. Phase 5 seeds the recommendation from the concept signals (moving money, seed stage), puts it first with ` (Recommended)`, says why in the user's words, and explains that `modes.rigor` drives six settings
6. Phase 6 recommends `Collaborative` for a user new to the framework
7. Phase 7 shows the exact lines, asks "May I write this to `project.yaml`?", adds the `project:` block after `framework:` and the `modes:` block at the end, re-reads the file and verifies each value is in its enum and no fronted knob was added
8. Phase 8 prints the one path for the chosen rigor and asks "Would you like to start with [recommended first step]?"; Phase 9 replies with the single line "Type `[skill command]` to begin."

**Assertions:**
- [ ] `project.yaml` gains exactly `project.stage`, `modes.rigor` and `modes.automation`
- [ ] The path printed matches the rigor chosen in Phase 5 (not the rigor recommended)
- [ ] The next skill is recommended, never run
- [ ] Verdict: COMPLETE

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Declined write — Settings stay in the conversation

**Fixture:**
- As Case 1

**Input:** `/start` → `A) No product idea yet` → rigor and automation answered → "no" to the write question

**Expected behavior:**
1. Phase 3 names `/brainstorm open` as the next step
2. Phase 7 keeps the values in the conversation, says the settings are not saved and that re-running `/start` asks again
3. Continues with Phase 8 and hands off

**Assertions:**
- [ ] `project.yaml` is unchanged
- [ ] The skill does not claim the settings were saved
- [ ] The COMPLETE verdict states the settings were explicitly declined

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Edge Case — `project.yaml` is missing

**Fixture:**
- `project.yaml` does not exist at the repository root

**Input:** `/start` → `B) A problem space` → "small clinics drowning in phone bookings" → rigor and automation answered

**Expected behavior:**
1. Phase 7 says the framework's shipped configuration file is missing
2. Offers to create a minimal file containing `schema_version: 1` and the `project:` and `modes:` blocks; restoring the shipped `project.yaml` (see `UPGRADING.md`) is named as the way to bring the rest back
3. Writes only after "May I write this to `project.yaml`?"

**Assertions:**
- [ ] No `framework:` block or framework version is invented
- [ ] The missing file is named before anything is written
- [ ] The verification step still checks the three values and the absence of fronted knobs
- [ ] Verdict is COMPLETE — a missing `project.yaml` is created on approval, not treated as a missing input

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Mode Variant — Option D, an existing product

**Fixture:**
- `apps/api/package.json`, `apps/web/package.json`, `design/prd/goals.md` and `docs/architecture/adr-0001-identity-and-auth.md` exist
- `bash .claude/scripts/stage-estimate.sh` prints `STAGE: Architecture`, `SOURCE: estimated`, `ESTIMATE: Architecture`, `EVIDENCE: docs/architecture/adr-0001-identity-and-auth.md exists`

**Input:** `/start` → `D) An existing product or codebase`

**Expected behavior:**
1. Runs `bash .claude/scripts/stage-estimate.sh` through its grant and shares what Phase 1 found and the estimate
2. Explains why the next step is an audit and names `/adopt`; mentions `/setup-stack`, `/project-stage-detect` and `/reverse-document` as what the plan will likely include
3. Phase 4 decides `project.stage: Architecture` (the `STAGE:` line)

**Assertions:**
- [ ] The stage comes from the script's `STAGE:` line, not from the skill's own reading of the tree
- [ ] The immediate next step is `/adopt`
- [ ] The Phase 8 path is not printed again for D (the path was given in Phase 3)

**Variant 4b — the estimator cannot run:** same fixture, but `bash .claude/scripts/stage-estimate.sh` exits non-zero (or prints no `STAGE:` line).

- [ ] `stage-estimate.sh` exits non-zero → the error is named, no `project.stage` is written, `/project-stage-detect` is recommended, and the verdict is NOT ASSESSED

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Edge Case — Returning user; recorded stage and fronted knob

**Fixture A:** `project.stage: Build`, `modes.rigor: standard`, `modes.automation: guided`, and `design/product/product-brief.md` exists.
**Fixture B:** `project.stage: Build` and `modes.review_mode: full` are set explicitly; `modes.rigor` is unset; the user picks option A.

**Input:** `/start`

**Expected behavior:**
1. A: skips onboarding with "You're already set up: stage `Build`, rigor `standard`, automation `guided`, …" and points to `/help`; writes nothing
2. B: keeps the recorded stage (never moves it), says in one sentence that option A contradicts a project at `Build` and asks whether they meant D
3. B: reports once that `modes.review_mode` is set explicitly so `modes.rigor` does not change it, and does not remove it

**Assertions:**
- [ ] A recorded `project.stage` is never changed by `/start`
- [ ] A pre-existing fronted knob is reported, not removed or rewritten
- [ ] A returning user gets no write

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Always Collaborative — `autonomous` already set

**Fixture:**
- `project.yaml` has `modes.automation: autonomous` and no `modes.rigor`

**Input:** `/start` → `B) A problem space`

**Expected behavior:**
1. Phase 6 shows "Automation is set to `autonomous`." and does not ask again
2. Phase 5 still asks the rigor question, and Phase 7 still asks "May I write this to `project.yaml`?" and waits

**Assertions:**
- [ ] SKILL.md carries no automation prelude and resolves no settings through `yaml-helper.sh`
- [ ] No question is skipped or decided-and-logged because of `autonomous`
- [ ] Only the unset keys (`project.stage`, `modes.rigor`) are written

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: Edge Case — Option D on an empty template

**Fixture:**
- The shipped template: no artifacts, no manifests, no source files anywhere

**Input:** `/start` → `D) An existing product or codebase`

**Expected behavior:**
1. Says "It looks like a fresh template with no product artifacts or code yet. Would A, B or C fit better?"
2. Routes by the answer

**Assertions:**
- [ ] `/adopt` is not recommended for an empty repository
- [ ] If source files exist outside the probed patterns, the skill says what it found rather than calling the repository greenfield

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Asks first; Phase 1 findings inform the questions and never replace them
- [ ] Presents options with trade-offs; recommendations are labelled
- [ ] "May I write this to `project.yaml`?" before the single write, showing the exact lines
- [ ] Always collaborative: no automation prelude, every question asked in every mode
- [ ] Writes nothing under `production/session-logs/`; never writes `modes.review_mode` or any other knob that `modes.rigor` fronts
- [ ] Hands off with one line and never runs the next skill

---

## Category Rubric (`utility`)

- `utility U1` — the static checks above pass: no bootstrap line, grant or follow-on line (no keys), no automation prelude, "May I write" before the write, output exact (`project.yaml`, three keys)
- `utility U2` — not applicable (no director gate)
- The NOT ASSESSED case is Case 4b (missing input: `stage-estimate.sh` cannot run for option D)

---

## Coverage Notes

- The mismatch trigger (a payments product on `minimal`, a weekend hackathon on `full`) follows
  `.claude/docs/settings-guidance.md` § 4; it is said once and not re-asked — not fixture-tested separately.
- "Settings exist but no product record" follows the Case 6 pattern (questions for set keys are skipped).
- The `full` path text is asserted only as "everything in `standard` plus …"; the exact step list is not.
