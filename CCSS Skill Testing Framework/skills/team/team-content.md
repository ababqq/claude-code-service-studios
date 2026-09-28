# Skill Spec: /team-content

> **Category**: team
> **Priority**: medium
> **Spec written**: 2026-09-28

## Skill Summary

Orchestrates content design for one product area: voice and tone, microcopy, errors and
empty states, notification templates (push / email / SMS / 알림톡), help-center articles
and store text. The voice is settled first (Phase 2 writes
`design/brand/voice-and-tone.md` from `.claude/docs/templates/voice-and-tone.md` when it
is absent or the argument is `voice`); `ux-writer` drafts the copy deck
`design/content/<area>.md` or the article `design/content/help-center/<slug>.md`
(Phase 3); a Consent & Channel Check runs against `.claude/docs/compliance/<region>.md`
for every region in `compliance.regions` before any message template or marketing copy
is approved (Phase 4); the DD-CONTENT-VOICE gate reviews voice and terminology after the
drafts and before localization, subject to the review mode (Phase 5); localization and
accessibility readiness run in parallel (Phase 6); support readiness follows (Phase 7).
Every output lives under `design/`, outside the bounded write exception, so agents
return drafts and this skill writes each file after asking. The skill ends COMPLETE,
BLOCKED or NOT ASSESSED (a required check could not run: an unaccepted missing compliance
reference, or regions / locales left unset).

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`); `name` is `team-content`, equal to the directory `.claude/skills/team-content/` and the catalog `name`
- [ ] Bootstrap: the first body line is `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,team.size,compliance` `` and `allowed-tools` grants `Bash(bash "*/.claude/skills/team-content/../../hooks/yaml-helper.sh" resolve_config *)`
- [ ] `--keys` is exactly `review_mode,automation,team.size,compliance`
- [ ] The line after the bootstrap block is exactly: ``Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] Automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") present verbatim right after that line
- [ ] `allowed-tools` is exactly: `Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskUpdate` plus the bootstrap grant — no unrestricted `Bash`
- [ ] 2+ phase headings found (`## Phase 0: Resolve Config`, `### Phase 1: Context` … `### Phase 7: Support readiness (customer-success-manager)`, including `### Phase 4: Consent & Channel Check` and `### Phase 5: Voice review (DD-CONTENT-VOICE)`)
- [ ] Verdict keywords present: `COMPLETE`, `BLOCKED`, `NOT ASSESSED`, with the line `Precedence: BLOCKED > NOT ASSESSED > COMPLETE.`; the lines `NOT CHECKED — .claude/docs/compliance/<region>.md absent` and `Consent & Channel Check: not applicable — no messages or marketing copy in scope` are available
- [ ] "May I write this to `design/brand/voice-and-tone.md`?", "May I write this to `design/content/<area>.md`?" (or `design/content/help-center/<slug>.md`) and "May I write this to `design/content/support-macros.md`?" appear before the corresponding writes; the gate outcome line and each status change are also written only after "May I write this to `<path>`?"
- [ ] Outputs at the exact paths: `design/brand/voice-and-tone.md`, `design/content/<area>.md`, `design/content/help-center/<slug>.md`; the voice guide keeps the template headings `## Voice Attributes`, `## Tone by Context`, `## Terminology`, `## Do / Don't`, `## Korean Style Notes`
- [ ] The copy deck shape carries `> **Status**: Draft | Approved`, `> **Source Locale**:`, `## Strings`, `## Message Templates`, `## Store Listing` and `## Consent & Channel Check`
- [ ] Contains verbatim: "Team skills spawn only the gates `.claude/docs/director-gates.md` § Gate Index lists this skill under (Spawned by column), after the review-mode check (lean suffix rule); team-size scoping never removes a director gate."
- [ ] Phase 0 names DD-CONTENT-VOICE in its review-mode check and contains the lean sentence verbatim: "`lean` → **skip every gate whose ID does not end in `-PHASE-GATE`**. Note: `[GATE-ID] skipped — Lean mode`"
- [ ] Contains the default statement verbatim: "Unset on an unconfigured project: `modes.rigor` defaults to `minimal`, which resolves `review_mode` to `solo`."
- [ ] Active set per `team.size` is listed (`individual`: `ux-writer`; `small`: `ux-writer` → `localization-lead` → `customer-success-manager`; `studio`: + `accessibility-specialist`) and announced before Phase 1 together with whether DD-CONTENT-VOICE will run; `design-director` is outside the active set at every size
- [ ] Without an argument the skill prints the usage line beginning "Usage: `/team-content [voice | <area> | help-center <slug>]`" and exits without spawning agents or using `AskUserQuestion`
- [ ] `localization.locales` is read from `project.yaml` with Read (no config label carries it); unset is asked about, not treated as "single locale"
- [ ] Has an Error Recovery Protocol section and a File Write Protocol section stating that no agent in this pipeline writes a file
- [ ] No `!` injection other than the bootstrap line; no `file:line` citations of other files
- [ ] The closing `AskUserQuestion` prompt is "Content for [area]: [COMPLETE / BLOCKED / NOT ASSESSED]. What next?" and names current skills (`/localize extract`, `/localize brief`, `/team-content <next-area>`, `/team-ui <screen>`, `/team-growth <campaign>`)

---

## Director Gate Checks

The skill spawns one gate, **DD-CONTENT-VOICE** (owner `design-director`), in Phase 5 —
after the copy drafts (Phase 3) and the Consent & Channel Check (Phase 4), before
localization (Phase 6). The spawn names `.claude/docs/director-gates/dd-content-voice.md`
for the agent to read first, passes
`Pass: content file paths under review · `design/brand/voice-and-tone.md` path · `design/registry/entities.yaml` path · `localization.locales` value (or "unset")`,
and parses the first line as `[DD-CONTENT-VOICE]: TOKEN` (`APPROVE` / `CONCERNS` / `REJECT`).

- **Full mode**: DD-CONTENT-VOICE spawns at every `team.size`
- **Lean mode**: skip every gate whose ID does not end in `-PHASE-GATE` — note `[DD-CONTENT-VOICE] skipped — Lean mode` (no gate of this skill runs)
- **Solo mode**: no gates — note `[DD-CONTENT-VOICE] skipped — Solo mode`
- **Review-mode exempt**: not applicable
- The outcome line `> **Design Director Review (DD-CONTENT-VOICE)**: APPROVED [date] / CONCERNS (accepted) [date] / REVISED [date]` — or the skip note — is written into each reviewed file's header after "May I write"

---

## Test Cases

Quoted prompts, option labels and verdict tokens below are the canonical English text
of `SKILL.md`; at run time the model renders them in the user's conversation language.
Customer-facing copy in the fixtures is written in the locale it ships in.

### Case 1: Happy Path — Moa notification templates for Korea

**Fixture** (assumed project state):
- `design/brand/voice-and-tone.md` and `design/registry/entities.yaml` exist
- `design/prd/payments.md` defines the auto-debit flow and its failure states
- `project.yaml`: `localization.locales: [ko-KR, en-US]`
- Resolved block: `review_mode: full`, `team.size: small`, `compliance: regions=kr handles_pii=true (project.yaml)`
- `.claude/docs/compliance/kr.md` exists

**Input:** `/team-content notifications`

**Expected behavior:**
1. Phase 0 announces `Active set (team.size: small): ux-writer, localization-lead, customer-success-manager.`, names `accessibility-specialist` as not spawned, and says DD-CONTENT-VOICE will run
2. Phase 1 reports every input as present or ABSENT
3. Phase 2 is skipped (the voice guide exists and the argument is not `voice`)
4. Phase 3: `ux-writer` drafts the templates — for each: channel, purpose (**informational** or **advertising**), trigger, audience, variables, deep link, send-time rules, fallback channel, consent; the failed auto-debit push is calm and actionable; the deck is written with `> **Status**: Draft` after "May I write this to `design/content/notifications.md`?"
5. Phase 4 lists the `kr` items of `## Marketing Messages & Consent` (prior opt-in for advertising messages, separate night-time consent, periodic consent confirmation, working unsubscribe path, sender identification; 알림톡 for informational messages only); the user confirms each; the result is recorded under `## Consent & Channel Check` after "May I write"
6. Phase 5: DD-CONTENT-VOICE → `[DD-CONTENT-VOICE]: APPROVE`; outcome recorded; `AskUserQuestion` "Copy reviewed. Approve it for localization and support?" → `[A] Approve — set Status: Approved`
7. Phase 6: `localization-lead` checks keys, ICU plurals (Korean `other` only; English `one` and `other`), particles after variables, `#{variable}` 알림톡 slots, expansion headroom
8. Phase 7: `customer-success-manager` drafts macros; written after "May I write this to `design/content/support-macros.md`?" and listed as `not yet voice-reviewed`
9. Verdict COMPLETE; the closing widget recommends `/localize extract`

**Assertions:**
- [ ] The active set and the gate's run/skip status are announced before any spawn
- [ ] Every template states whether it is informational or advertising and which consent it depends on
- [ ] The Consent & Channel Check runs before any template is approved, and every item is confirmed or explicitly accepted
- [ ] DD-CONTENT-VOICE runs after the drafts and the consent check, before localization
- [ ] Each file under `design/` is written by this skill after its own "May I write" — no agent writes a file
- [ ] Macros drafted after the gate are listed as `not yet voice-reviewed`
- [ ] The verdict is COMPLETE and the next step names `/localize extract`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — A promotional 알림톡 and an unconfirmed night-time consent

**Fixture:**
- As Case 1, but one draft is a 알림톡 template announcing a Plus-plan discount, and another is a promotional push scheduled at 21:30 KST
- The user neither confirms nor accepts the night-time consent item

**Input:** `/team-content notifications`

**Expected behavior:**
1. Phase 4 reclassifies the 알림톡 promotion as advertising and moves it to a channel that has advertising consent
2. The night-time consent item is neither confirmed nor accepted, so the templates it covers stay `Draft`
3. The pipeline cannot approve those templates; the output reports the blocking item
4. Verdict: `BLOCKED — [reason]` naming the unconfirmed consent item

**Assertions:**
- [ ] A 알림톡 template with promotional content is never approved as 알림톡
- [ ] An item neither confirmed nor accepted blocks approval of the templates it covers
- [ ] The affected templates keep `> **Status**: Draft`
- [ ] The verdict is BLOCKED with the reason, and a partial report is produced
- [ ] The skill states that the check is a checklist against the reference, not legal advice

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: NOT ASSESSED — Compliance reference missing, regions and locales unset

**Fixture (variant A):** resolved `compliance: regions=kr,eu …`; `.claude/docs/compliance/eu.md` does NOT exist

**Fixture (variant B):** the resolved `compliance` line prints the unset form for regions; `project.yaml` has no `localization.locales`

**Input:** `/team-content goals-reminders`

**Expected behavior (variant A):**
1. Phase 4 records `NOT CHECKED — .claude/docs/compliance/eu.md absent`
2. The `eu`-covered templates stay Draft until the user accepts that gap explicitly

**Expected behavior (variant B):**
1. Phase 0/1 says `localization.locales: unset` and asks which locales this copy ships in
2. Phase 4 asks which regions apply — it does not proceed on an assumption and does not treat unset as "none"

**Assertions:**
- [ ] A missing compliance reference produces the exact NOT CHECKED line, never a silent pass
- [ ] Templates covered by an unchecked region cannot be approved without an explicit acceptance
- [ ] Variant A: without an explicit acceptance the run verdict is NOT ASSESSED, never COMPLETE
- [ ] Unset regions are asked about; unset is not `[]`
- [ ] Unset `localization.locales` is asked about; it is not assumed to be a single locale
- [ ] Variant B: if the regions or locales question goes unanswered, the run verdict is NOT ASSESSED, naming each unset value
- [ ] A BLOCKED condition in the same run outranks NOT ASSESSED (precedence BLOCKED > NOT ASSESSED > COMPLETE)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Mode Variant — `voice`, `help-center` and `team.size: individual`

**Fixture:**
- Variant A: `design/brand/voice-and-tone.md` does NOT exist; resolved `team.size: individual`
- Variant B: voice guide exists; resolved `team.size: studio`

**Input:** `/team-content voice` (A) · `/team-content help-center cancel-auto-debit` (B)

**Expected behavior (variant A):**
1. Announcement: `ux-writer` alone; `localization-lead`, `customer-success-manager` and `accessibility-specialist` consulted through it
2. Phase 2 drafts every template section of the voice guide, keeping the headings exactly; written after "May I write this to `design/brand/voice-and-tone.md`?"
3. The guide goes to Phase 5 as the content under review; for `voice` the pipeline ends after Phase 5

**Expected behavior (variant B):**
1. Phase 3 drafts a question-first article: the short answer, steps per surface, what to do when it does not work, the contact path
2. Phase 4 records `Consent & Channel Check: not applicable — no messages or marketing copy in scope`
3. Phase 6 spawns `localization-lead` and `accessibility-specialist` in parallel

**Assertions:**
- [ ] The collapse to `ux-writer` at `individual` is announced
- [ ] The `voice` argument ends after the voice review; the other arguments continue to Phases 6–7
- [ ] Pure interface copy and articles record the not-applicable consent line instead of skipping silently
- [ ] Phase 6 agents are spawned together when both are in the active set

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Edge Case — Voice declined and a term outside the registry

**Fixture:**
- `design/brand/voice-and-tone.md` does NOT exist and the user declines Phase 2
- The draft calls the Plus plan "Premium", while `design/registry/entities.yaml` lists the plan as `Plus`
- An already approved 알림톡 template's wording needs to change

**Input:** `/team-content payment-errors`

**Expected behavior:**
1. The gate caps at CONCERNS with `NOT CHECKED — voice`, and the sign-off says so
2. The "Premium" term is surfaced as a contradiction with the registry — resolved through `/consistency-check` or the owning PRD, never renamed silently
3. The approved 알림톡 template change is flagged as needing re-submission for template review rather than edited in place

**Assertions:**
- [ ] A declined voice guide is reported as `NOT CHECKED — voice`, not as reviewed
- [ ] Registry contradictions are surfaced, not absorbed
- [ ] Approved 알림톡 wording is not edited directly

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Director Gate — full mode (CONCERNS)

**Fixture:**
- Drafts written for `design/content/goals.md`; one empty-state string blames the user ("You forgot to set a goal")
- Review mode: `full`

**Input:** `/team-content goals`

**Expected behavior:**
1. Phase 5 spawns `design-director`; the prompt tells it to read `.claude/docs/director-gates/dd-content-voice.md` first; `Pass:` carries the content file path, `design/brand/voice-and-tone.md`, `design/registry/entities.yaml` and `localization.locales` (`[ko-KR, en-US]`)
2. First line `[DD-CONTENT-VOICE]: CONCERNS`
3. The flagged strings are shown with suggested rewrites; `AskUserQuestion`: `Revise flagged items` / `Accept and proceed` / `Discuss further`
4. Revised drafts are rewritten after "May I write" and may be re-reviewed; the outcome line is recorded in the deck header

**Assertions:**
- [ ] In full mode DD-CONTENT-VOICE spawns with the gate file path and its four Context items
- [ ] A CONCERNS-class verdict is surfaced via AskUserQuestion (revise / accept / discuss)
- [ ] A REJECT-class verdict keeps the drafts out of localization until resolved and re-reviewed
- [ ] A first line that does not parse is handled as CONCERNS-class, never as approval

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: Director Gate — lean mode

**Fixture:**
- Same project state as Case 6
- Review mode: `lean`

**Input:** `/team-content goals`

**Expected behavior:**
1. The Phase 0 announcement says DD-CONTENT-VOICE will be skipped
2. Phase 5 writes `[DD-CONTENT-VOICE] skipped — Lean mode` into the deck header, where the verdict line would go, after "May I write"
3. The approval question and Phases 6–7 continue

**Assertions:**
- [ ] Output contains `[DD-CONTENT-VOICE] skipped — Lean mode`
- [ ] No gate spawns (DD-CONTENT-VOICE does not end in `-PHASE-GATE`)
- [ ] The skip note is recorded in the reviewed file's header

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 8: Director Gate — solo mode (unconfigured default)

**Fixture:**
- Same project state as Case 6
- `project.yaml` sets neither `modes.review_mode` nor `modes.rigor`

**Input:** `/team-content goals`

**Expected behavior:**
1. `review_mode` resolves to `solo` through the rigor default
2. Phase 5 writes `[DD-CONTENT-VOICE] skipped — Solo mode` into the deck header

**Assertions:**
- [ ] In solo mode no director gate spawns
- [ ] Output contains `[DD-CONTENT-VOICE] skipped — Solo mode`
- [ ] Nothing is written to `modes.review_mode`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 9: Usage — No argument

**Fixture:**
- Any project state

**Input:** `/team-content` (no argument)

**Expected behavior:**
1. The skill prints the usage guidance — `voice`, `<area>` (e.g. `onboarding`, `goals`, `payment-errors`, `notifications`, `store-listing`, `support-macros`), `help-center <slug>` — directly, without `AskUserQuestion`
2. It exits without spawning any agent

**Assertions:**
- [ ] No agent is spawned and no file is read or written
- [ ] The usage text gives the three argument forms with examples
- [ ] No verdict is emitted

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses "May I write this to `<path>`?" before every write — voice guide, each copy deck, each article, the consent record, the gate outcome line and each status change
- [ ] Presents drafts, consent items and gate findings before requesting approval
- [ ] Ends with the closing `AskUserQuestion` of next steps
- [ ] Does not auto-create files without user approval; agents return drafts inline
- [ ] Phase 6 agents are spawned in parallel; any BLOCKED agent is surfaced immediately with a partial report
- [ ] Writes no evidence, reports or plans under `production/session-logs/` (gitignored)
- [ ] Never writes `modes.review_mode` or any other knob that `modes.rigor` fronts

---

## Coverage Notes

- Store-listing copy (`store-listing` area) follows the same Phase 3 path; the field limits
  come from `.claude/agents/localization-lead.md` and are not re-asserted here.
- `regions=none` (`Consent & Channel Check: no regions configured (compliance.regions: [])`,
  with an opt-out still confirmed for every message stream) is asserted by the skill text but
  not given a fixture.
- `guided` and `autonomous` automation modes are covered by the automation prelude static
  assertion.
