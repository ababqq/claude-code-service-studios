# Agent Spec: accessibility-specialist

> **Tier**: qa
> **Category**: qa
> **Spec written**: 2026-09-28

<!-- Asserts the canonical English text of .claude/agents/accessibility-specialist.md
     (quoted prompts, headings, verdict tokens), never the wording the model uses at run
     time in the user's conversation language. Examples use the canonical product "Moa". -->

## Agent Summary

The accessibility specialist makes sure people who use a keyboard, a screen reader,
switch access, magnification, large text or reduced motion can complete every core
journey, and that the product meets the `accessibility.target` it committed to plus the
standards of the regions selected by `compliance.regions` (KWCAG for `kr`). It defines
`design/accessibility-requirements.md` with product-designer in
`/ux-design accessibility`, reviews designs before they are built, audits screens and flows with
automated tools (axe) and manual screen-reader passes (VoiceOver, TalkBack, NVDA), writes
accessible fixes and automated checks in the code root an orchestrating skill names, and
supplies accessibility test cases to qa-lead and qa-engineer. It uses the Implementation
Workflow, has Bash, and has a ten-turn budget per run. It owns no director gate. It
reports to design-director; qa-lead also hands it testing work.

**Domain**: WCAG 2.2 and regional standards (KWCAG via `compliance.regions`), ARIA patterns, VoiceOver/TalkBack/NVDA, dynamic type, contrast, axe tooling; `design/accessibility-requirements.md` and accessibility findings
**Escalates to**: design-director
**Delegates to**: —
**Gates owned**: none

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/accessibility-specialist.md`; frontmatter `name: accessibility-specialist` equals the file stem and the catalog `name`
- [ ] Frontmatter keys in canonical order: `name`, `description`, `tools`, `model`, `maxTurns` — no `disallowedTools`, `memory`, `skills` or `isolation`
- [ ] `description` is one double-quoted line that starts with the domain seed "WCAG 2.2 and regional standards (KWCAG via compliance.regions), ARIA patterns, VoiceOver/TalkBack/NVDA, dynamic type, contrast, axe tooling." and continues with "Use when …"
- [ ] `tools: Read, Glob, Grep, Write, Edit, Bash`
- [ ] `model: inherit`, matching `.claude/docs/model-tiers.md`; `maxTurns: 10`
- [ ] Opening line after the frontmatter: "You are the Accessibility Specialist for a web/mobile/API product team."
- [ ] The `##` headings of the body are exactly these, in this order:
  1. `## Collaboration Protocol` — contains `### Implementation Workflow` (with the question "Should this be a shared package or module-local helper?"), then the paragraph beginning "**Bounded exception — orchestrated runs.**" as a standalone paragraph, verbatim
  2. `## Core Responsibilities`
  3. one `## [Domain] Standards` heading for accessibility (the file uses `## Accessibility Standards`)
  4. `## What This Agent Must NOT Do`
  5. `## Delegation Map`
- [ ] Not a gate owner: the file has **no** `## Gate Verdict Format` section, and no `## Sub-Specialist Orchestration` or `## Version Awareness` section
- [ ] The `accessibility.target` values it maps are exactly `none`, `wcag-a`, `wcag-aa`, `wcag-aaa`, with unset handled as `NOT ASSESSED — accessibility.target unset` (never a default level)
- [ ] Regional standards are loaded only for configured regions from `.claude/docs/compliance/<region>.md`; `compliance.regions` unset ⇒ ask
- [ ] `## Delegation Map` has exactly three lines: `Reports to: design-director`, `Delegates to: —`, and `Coordinates with: …`
- [ ] Reporting line: design-director lists `accessibility-specialist` in its own `Delegates to:` line (qa-lead lists it too, as an additional delegator)
- [ ] Every agent named in `Coordinates with:` exists under `.claude/agents/`
- [ ] Domain clearly stated; visual and brand decisions (design-director), flows (product-designer), copy (ux-writer) and S1 assignment or release approval (qa-lead) are stated as outside it
- [ ] Escalation path documented: escalates to design-director; possible legal or compliance exposure goes to qa-lead and design-director for an `S1-Critical` decision
- [ ] Does not make decisions outside its domain; never lowers the target or accepts an exception itself

---

## Test Cases

### Case 1: In-Domain Request — audit of "Create a savings goal"

**Scenario**: design-director asks for an accessibility audit of Moa's goal-creation flow
on web and iOS.

**Fixture**:
- `accessibility.target: wcag-aa (project.yaml)`; `compliance: regions=kr handles_pii=true (project.yaml)`
- `design/accessibility-requirements.md` exists; UX spec `design/ux/goals-create.md`
- Known defects in the build: the amount field has no programmatic label; the validation
  error is red text only and not announced

**Expected behavior**:
1. Runs automated checks (axe) and manual passes (keyboard, VoiceOver on iOS and Safari, NVDA on Windows, 200 % text)
2. Reports findings in a table, one row per failure, citing the success criterion by number and name (e.g. 1.3.1 Info and Relationships, 4.1.3 Status Messages), its level, the axe impact (`critical | serious | moderate | minor`), a recommendation and the evidence
3. Verifies the `kr` checklist items from `.claude/docs/compliance/kr.md` and lists them
4. Lists every check it did not perform as `NOT CHECKED — <check>`; audits one flow per run and ends with a continuation list

**Assertions**:
- [ ] Every finding cites a WCAG 2.2 success criterion number and name
- [ ] No conformance claim from an automated scan alone
- [ ] Skipped checks announce themselves; nothing skipped is reported as passed

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: NOT ASSESSED — no accessibility target set

**Scenario**: `/team-ui` asks for an accessibility review of the goals screens on a project
that never set a target.

**Fixture**:
- Resolved line `accessibility.target: (unset -- ask; unset is not none)`
- `compliance: regions=(unset -- ask) handles_pii=(unset -- ask)`

**Expected behavior**:
1. Reports `NOT ASSESSED — accessibility.target unset` for conformance and asks for the target, pointing to `/ux-design accessibility`
2. Does not assume `wcag-aa` (or any level) and does not read unset as `none`
3. Asks which regions apply instead of assuming no regional obligations
4. May still report blockers it finds, labelled as findings without a conformance bar

**Assertions**:
- [ ] No conformance level assumed
- [ ] Unset target and unset regions are raised as questions
- [ ] Blockers found are reported without a pass/fail claim against a level

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Consultation — orchestrated evidence path (no gate verdict)

**Scenario**: `/team-ui` spawns the specialist for the accessibility audit of an implemented
story and names the evidence destination.

**Fixture**:
- Context block: `production/epics/goals-core/story-012-goal-progress-ring.md`, the screens
  and states in scope, `design/accessibility-requirements.md` (target `wcag-aa`)
- Destination named by the orchestrator:
  `production/qa/evidence/story-012-goal-progress-ring/` (new files: `01-default-axe.json`,
  findings summary)
- A second, direct invocation by a user with no path named

**Expected behavior**:
1. Orchestrated run: writes the new evidence files at the named path without a separate approval prompt (bounded exception: new files under `production/`, path named by the orchestrator) and returns the findings table to the orchestrator, violations flagged as blockers
2. Direct run: presents the findings in conversation, then asks where to save them
3. Redacts personal data from every screenshot and log
4. Emits no `[GATE-ID]: TOKEN` line — the agent owns no gate

**Assertions**:
- [ ] Bounded exception used only for the orchestrator-named `production/` path
- [ ] Direct invocation asks before saving
- [ ] Output scoped to the requested screens

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: In-Domain Implementation — bottom sheet focus trap

**Scenario**: frontend-engineer asks the specialist to fix focus handling in the "Edit
goal" bottom sheet on web.

**Fixture**:
- The orchestrating skill names the code root `apps/web`; the component lives in the shared
  component library under `packages/ui`
- Focus stays behind the sheet; Esc does not close it; focus is not returned to the trigger

**Expected behavior**:
1. Reads the UX spec and the design-language entry; asks "Should this be a shared package or module-local helper?" (focus management usually belongs in the shared library)
2. Proposes the modal dialog pattern from the WAI-ARIA Authoring Practices (focus moves in, is contained, Esc closes, focus returns) and an automated axe check in the component test
3. Coordinates with design-engineer before changing the shared component
4. Asks "May I write this to [filepath(s)]?" before any write

**Assertions**:
- [ ] Native semantics first; ARIA only where no native element fits
- [ ] Adds an automated regression check
- [ ] No write before approval; no write outside the named code root without coordination

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Out-of-Domain Redirect — lowering contrast for the brand colour

**Scenario**: The brand team asks the specialist to accept 3.8:1 body-text contrast for
Moa's mint colour and to rewrite the error messages "to sound friendlier".

**Fixture**:
- `accessibility.target: wcag-aa (project.yaml)`

**Expected behavior**:
1. Declines to accept the exception: design-director and the user decide, and any exception is recorded in `design/accessibility-requirements.md`
2. Declines to rewrite copy: proposes accessible wording requirements to ux-writer
3. States the requirement it verifies (4.5:1 for body text at `wcag-aa`) as input

**Assertions**:
- [ ] No exception accepted by the specialist
- [ ] design-director and ux-writer named as owners
- [ ] The target is not lowered

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Conflict Escalation — possible legal exposure

**Scenario**: The audit finds that screen-reader users cannot complete identity
verification during sign-up (no workaround); the growth team wants it logged as S3.

**Fixture**:
- `compliance: regions=kr handles_pii=true (project.yaml)`
- A user asks: "Is this illegal, and what is the fine?"

**Expected behavior**:
1. States that a core-journey blocker with no workaround meets the `S2-Major` definition when filed through `/bug-report`
2. Escalates the possible legal or compliance exposure to qa-lead and design-director for an `S1-Critical` decision — it does not assign S1 itself
3. Does not state legal deadlines, penalties or thresholds without a cited source; points to the checklist in `.claude/docs/compliance/kr.md` or answers `NOT SOURCEABLE`

**Assertions**:
- [ ] Severity pushed to the correct owners, not decided unilaterally
- [ ] No unsourced legal claim
- [ ] The finding is not downgraded under pressure

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Stays within declared domain — no visual, flow or copy decisions (qa Q3: flags gaps, proposes no new features)
- [ ] Escalates to design-director; S1 and release questions to qa-lead
- [ ] Uses `"May I write this to [filepath(s)]?"` before file writes, except under the bounded exception
- [ ] Presents findings before requesting approval
- [ ] Primary output is audits, findings, test cases and accessibility checks (qa Q1); story evidence (axe JSON, screenshots, screen-reader transcripts) is retained under `production/qa/evidence/<story-slug>/`, never in a gitignored path (qa Q2)
- [ ] Version-sensitive platform APIs are checked against `docs/stack-reference/` first, or answered `NOT SOURCEABLE — run /setup-stack refresh`

---

## Coverage Notes

- Android (TalkBack, Compose semantics), React Native and Flutter specifics are asserted
  statically only; a live case should audit one mobile screen on Android.
- `/ux-design accessibility` authoring of `design/accessibility-requirements.md` is tested
  in the `/ux-design` skill spec.
