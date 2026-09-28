---
name: team-content
description: "Content design: voice & tone, microcopy, notifications (push/email/SMS/알림톡), help center, store text, with a consent & channel check."
argument-hint: "[voice | <area> | help-center <slug>] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskUpdate, Bash(bash "*/.claude/skills/team-content/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,team.size,compliance`

Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

If no argument is provided, output usage guidance and exit without spawning any agents:
> Usage: `/team-content [voice | <area> | help-center <slug>]` — `voice` writes or revises the voice-and-tone guide; `<area>` writes the copy deck for one product area (e.g., `onboarding`, `goals`, `payment-errors`, `notifications`, `store-listing`, `support-macros`); `help-center <slug>` writes one help-center article (e.g., `help-center cancel-auto-debit`). Do not use `AskUserQuestion` here; output the guidance directly.

When this skill is invoked with an argument, orchestrate the content team through a
structured pipeline: the voice is settled first, the copy is drafted against it, messages
pass a consent & channel check, the design director reviews voice and terminology, and only
then does the copy go to localization and support.

**Decision Points:** At each phase transition, use `AskUserQuestion` to present
the user with the subagent's proposals as selectable options. Write the agent's
full analysis in conversation, then capture the decision with concise labels.
In `collaborative` mode, the user must approve before moving to the next phase.
In `guided` mode the pipeline advances automatically unless a phase is BLOCKED;
in `autonomous` mode it runs end to end, recording each phase outcome via
`log_decision`. Decisions in `automation_always_ask` categories
(`is_always_ask_category` helper) always prompt regardless of mode. See
`.claude/docs/automation-modes.md`.

**Outputs:**

| Path | Phase | Written by |
|------|-------|------------|
| `design/brand/voice-and-tone.md` | 2 | this skill, after "May I write" (from `.claude/docs/templates/voice-and-tone.md`) |
| `design/content/<area>.md` (copy deck) | 3, updated in 5–7 | this skill, after "May I write" |
| `design/content/help-center/<slug>.md` | 3, updated in 5–7 | this skill, after "May I write" |

Every output lives under `design/`, which the bounded write exception never covers, so the
agents return drafts inline and **this skill** writes each file after asking.

Track each phase as a task (`TaskCreate` at the start, `TaskUpdate` when it resolves).

## Phase 0: Resolve Config

The block at the top of this skill resolved `review_mode`, `automation`, `team.size` and
`compliance`.

`review_mode` sets gate depth. This skill spawns one gate, **DD-CONTENT-VOICE**, in Phase 5.
**Review mode check** — apply before spawning DD-CONTENT-VOICE (`--review` overrides the
resolved value):
- `full` → spawn as normal
- `lean` → **skip every gate whose ID does not end in `-PHASE-GATE`**. Note: `[GATE-ID] skipped — Lean mode`
  DD-CONTENT-VOICE does not end in `-PHASE-GATE`, so lean skips it: record `[DD-CONTENT-VOICE] skipped — Lean mode`.
- `solo` → skip all gates. Note: `[DD-CONTENT-VOICE] skipped — Solo mode`

Unset on an unconfigured project: `modes.rigor` defaults to `minimal`, which resolves `review_mode` to `solo`.

`automation` drives the Decision Points note above. See the Decision Points note above and
`.claude/docs/automation-modes.md` for how each mode changes pipeline behavior.

**`compliance`** drives the Consent & Channel Check (Phase 4). `regions=none` means the user
declared no regional obligations; the unset form means the regions are unknown — ask, and
never treat unset as "none".

**`localization.locales`** has no `resolve_config` label: read it from `project.yaml` with
Read. It decides which locales Phase 6 prepares and is passed to DD-CONTENT-VOICE. Unset ⇒
say so (`localization.locales: unset`) and ask which locales this copy ships in; unset is not
"single locale".

**`team.size`**: which agents are active (orthogonal to review_mode gate-depth and workflow docs).
- **`individual`**: `ux-writer` only — localization readiness, support readiness and
  accessibility are consulted through it, not spawned separately.
- **`small`**: the documented pipeline — `ux-writer` → `localization-lead` →
  `customer-success-manager`.
- **`studio`**: the `small` pipeline + `accessibility-specialist`.
Team skills spawn only the gates `.claude/docs/director-gates.md` § Gate Index lists this skill under (Spawned by column), after the review-mode check (lean suffix rule); team-size scoping never removes a director gate. A non-core agent needed at `individual` routes through the nearest active core agent with an informational note. **"Phase gate" means any phase that ends in an `AskUserQuestion` decision point before the pipeline advances** — not every phase. Apply the test literally: if the phase below has no decision point, it is not a gate, and an agent restricted to "phase gates only" is not spawned for it. This active-set scoping applies throughout the pipeline below: any phase that names an agent outside the active set routes through the nearest core agent rather than spawning it.

`design-director` is not part of the active set at any size: it is spawned only for
DD-CONTENT-VOICE, and only when the review-mode check keeps that gate.

Unset on an unconfigured project, `modes.rigor` defaults to `minimal`, which resolves
`team.size` to `individual`.

**Announce the active set before Phase 1 — never let the collapse be silent.**
Before spawning anything, state in one line which agents this run will actually
spawn, and which the pipeline below names but will **not** spawn at the resolved
`team.size`. For example:

> `Active set (team.size: <resolved>): <the agents listed for that size above>.`
> `Not spawned this run: <every other agent this pipeline names> — consulted`
> `through <nearest active core agent>. Raise team.size (or modes.rigor) to widen.`

Fill it from the `team.size` list directly above and the agents this file's own
pipeline names — not from an example. Both sets differ per orchestrator. Add whether
DD-CONTENT-VOICE will run or be skipped at the resolved `review_mode`.

The pipeline below reads as a multi-agent fan-out and at the shipped default it
is one or two agents — `team-release` names nine agents and at `individual` runs
`release-manager` alone; this skill names four and at the same size runs `ux-writer`
alone. **The collapse is correct**: `team.size` is rigor-fronted and the narrow
default is the token lever, measured at roughly 10x. What was wrong is that nothing
said so, so a reader could not distinguish a correctly-collapsed run from a broken
pipeline, and the per-agent "routes through the nearest core agent with an
informational note" rule above fires at routing time and never states the shape of
the run as a whole.

This is the same rule as the skipped-check reporting elsewhere in this file: **a constraint that is enforced but never surfaced is
indistinguishable, to the person reading the output, from one that was never
enforced.**

## Team Composition

- **ux-writer** — Lead author: the voice-and-tone guide, microcopy, errors and empty states,
  onboarding, notification templates (push / email / SMS / 알림톡), help-center articles,
  store text
- **localization-lead** — String keys, translator context, ICU placeholders and plurals,
  length limits, Korean particles and CJK typography, store-listing localization
- **customer-success-manager** — Support readiness: help-center accuracy against what ships,
  support macros, the questions users will actually ask
- **accessibility-specialist** (`studio`) — Accessible names, link and button text, alt
  text, error identification, screen-reader announcements, plain-language level
- **design-director** (gate only) — DD-CONTENT-VOICE: voice, tone and terminology
  consistency before localization

## How to Delegate

Use the `Agent` tool to spawn each team member as a subagent:
- `subagent_type: ux-writer` — Voice and tone, copy drafts, templates, articles
- `subagent_type: localization-lead` — Localization readiness of the approved copy
- `subagent_type: customer-success-manager` — Support readiness and macros
- `subagent_type: accessibility-specialist` — Accessibility review of the copy (`studio`)
- `subagent_type: design-director` — DD-CONTENT-VOICE gate only

**Brief each agent — do not dump context.** Read the shared inputs **once** and pass a distilled brief inline: the lines each agent actually needs, never a file path for a document you have already read (an agent handed a path re-reads the whole file). Pass a path only for a document you have not read and only that agent needs.

**End every agent prompt with a return contract:** "Write your full output to `[path]` — that named path is your write authorisation under the bounded exception below, so write it without a separate approval prompt. Return **only** (1) the path written, (2) a ≤5-bullet summary of decisions, (3) any BLOCKED/CONCERNS items, one line each. Do not restate the documents you read." Without it, an agent returns everything it read back into this session.

**Substitute the destination for `[path]` — and here the agent does not write it.** This
skill's destinations are fixed, and all of them are under `design/`:

| Agent | Destination (written by this skill after "May I write") |
|---|---|
| ux-writer (voice) | `design/brand/voice-and-tone.md` |
| ux-writer (copy) | `design/content/<area>.md` |
| ux-writer (article) | `design/content/help-center/<slug>.md` |
| customer-success-manager (macros) | `design/content/support-macros.md` |

`design/` is outside the bounded exception, so each agent's return contract replaces "(1)
the path written" with "(1) the full draft for `<destination>`", and this skill asks before
writing it. The gate agent (design-director) writes nothing.

> **The destination is not a free choice.** `design/brand/voice-and-tone.md` is read by
> the DD-CONTENT-VOICE gate, `/design-language` (its `## 9. Content & Voice` points to it),
> `/release-notes`, `/localize` and the agents that write copy; `design/content/` is where
> the gate, `/localize`, `/feature-audit` and `/launch-checklist` look for copy decks and
> articles. Content written anywhere else is invisible to all of them.

> **Why this does not violate the Collaboration Protocol.** `CLAUDE.md` requires an agent to ask "May I write this to [filepath]?" before Write/Edit. A subagent spawned here writes **without** asking, and that is a deliberate, bounded exception rather than an oversight — the same call already made for `consistency-check` appending to `active.md`. The exception holds only when all three are true: (1) the path is one **you** named in the prompt, so the user approved the destination when they approved the phase; (2) it is a new artifact under `production/`, `docs/` or `tests/`, never an edit to existing source or config; (3) the phase that produced it is itself gated by an `AskUserQuestion` before the pipeline advances. Outside those three, the agent must ask. **Do not "fix" this by asking per subagent** — a prompt per agent per phase makes an orchestrator unusable, which is why the exception exists.

Launch independent agents in parallel where the pipeline allows it (Phase 6's
localization-lead and accessibility-specialist run simultaneously).

## Pipeline

### Phase 1: Context

Read, once, and **report the status of every input before drafting anything** — present or
ABSENT:
- `design/brand/voice-and-tone.md` — the voice. ABSENT ⇒ Phase 2 runs first, whatever the
  argument.
- `design/registry/entities.yaml` — product terms (`entities`, `plans`, `rules`,
  `constants`, `events`). ABSENT ⇒ terminology is checked against the voice guide's
  `## Terminology` only; say so.
- The PRDs of the area (`design/prd/<feature>.md` — `## Functional Requirements`,
  `## Edge Cases`, `## UI Requirements`) and the UX specs under `design/ux/` that need copy.
- The existing copy deck `design/content/<area>.md` or article, when revising.
- `design/product/tracking-plan.md` rows for message sends (notification areas only).
- `localization.locales` from `project.yaml`.

Absence of a PRD or UX spec is not blocking, but name each missing one in the ux-writer's
brief so the copy is written knowing what context it lacks, rather than inferring states
from the area name.

### Phase 2: Voice & tone (when the guide is absent, or the argument is `voice`)

Delegate to **ux-writer** with the product brief's `## Product Principles & Anti-Goals` and
`## Target Users & Jobs-to-be-Done`, the design language's `## 1. Brand Principles` when it
exists, and the template `.claude/docs/templates/voice-and-tone.md`. The draft fills every
template section — `## Voice Attributes`, `## Tone by Context` (success, error, empty,
onboarding, billing, incident), `## Terminology`, `## Do / Don't`, `## Korean Style Notes`
(존댓말 level, spacing) — keeping the headings exactly as the template spells them.

Present the draft, then ask "May I write this to `design/brand/voice-and-tone.md`?" Write
only on approval. For the argument `voice`, continue at Phase 5 with the guide as the
content under review; otherwise continue at Phase 3.

### Phase 3: Copy drafts (ux-writer)

Delegate to **ux-writer** for the area:
- **Microcopy** — every label, button, helper text, confirmation and toast, keyed
  (`goals.create.submit_button`), with the screen and state it appears in.
- **Errors and empty states** — each error the backend can return for the area mapped to a
  message that says what happened and what to do next; each empty state names the value and
  one action. For Moa: a failed auto-debit is calm and actionable — which goal, what
  happens next, one button to retry — never alarming or blaming.
- **Notification templates** — per template: channel (push, email, SMS/LMS, 알림톡), purpose
  **informational** or **advertising**, trigger, audience, variables, deep link, send-time
  rules, fallback channel and the consent it depends on.
- **Store text** (`store-listing` area) — App Store and Google Play fields within the limits
  in the table under `### Store listings and notification templates` in
  `.claude/agents/localization-lead.md`; no claim the product does not keep.
- **Help-center article** (`help-center <slug>`) — question-first title, the short answer,
  steps per surface, what to do when it does not work, and the contact path.

Each draft names the locale it is written in (the source locale, one of
`localization.locales`) and carries a translator context note per string. A copy deck uses
this shape — sections the area does not need are omitted, never left empty:

```markdown
# Copy Deck: [area]

> **Status**: Draft | Approved
> **Source Locale**: [locale]
> **Last Updated**: [YYYY-MM-DD]

## Strings
| Key | Screen / State | Text | Max Length | Translator Context |
|---|---|---|---|---|

## Message Templates
| Template | Channel | Purpose | Trigger | Variables | Deep Link | Fallback | Consent |
|---|---|---|---|---|---|---|---|

## Store Listing
| Store | Field | Limit | Text |
|---|---|---|---|

## Consent & Channel Check
```

A help-center article is prose: the question as its H1, the same three header lines, then
the short answer, the steps per surface, what to do when it does not work, and the contact
path.

Present the drafts, then ask "May I write this to `design/content/<area>.md`?" (or
`design/content/help-center/<slug>.md`) and write it with `> **Status**: Draft`. The drafts
must be on disk for the Phase 5 review; a Draft is not an approval.

### Phase 4: Consent & Channel Check

Runs **before** any push / email / SMS / 알림톡 template, campaign or marketing copy is
approved. When the area contains none of these (pure interface copy, a help-center
article), record
`Consent & Channel Check: not applicable — no messages or marketing copy in scope` and
continue.

Otherwise, for each region in the resolved `compliance` line, read
`.claude/docs/compliance/<region>.md` and list its applicable items —
`## Marketing Messages & Consent` always, `## Privacy & Data Protection` when a template
carries personal data. For `kr` that includes: prior opt-in for advertising messages,
separate consent for night-time sending, periodic confirmation of that consent, a working
unsubscribe path and sender identification in every advertising message; and **KakaoTalk
알림톡 carries informational messages only** — a template with promotional content is
reclassified as advertising and moved to a channel that has advertising consent. Each item is
marked by the user as **confirmed** (how it is met) or **explicitly accepted** (with the
reason). An item neither confirmed nor accepted blocks approval of the templates it covers.

- **Regions unset** ⇒ ask which regions apply; do not proceed on an assumption.
- **`regions=none`** ⇒ record
  `Consent & Channel Check: no regions configured (compliance.regions: [])` and still
  confirm an opt-out for every message stream.
- A compliance file missing for a configured region ⇒
  `NOT CHECKED — .claude/docs/compliance/<region>.md absent`; the templates stay Draft until
  the user accepts that gap explicitly.

Record the result in the copy deck under `## Consent & Channel Check` (per region: item —
confirmed (how) | accepted (why)) after asking "May I write this to
`design/content/<area>.md`?". This is a checklist against the reference, not legal advice.

### Phase 5: Voice review (DD-CONTENT-VOICE)

Apply the review mode check from Phase 0. When the gate is skipped, write the skip note
(`[DD-CONTENT-VOICE] skipped — Lean mode` / `— Solo mode`) into each reviewed file's header,
where the verdict line would go, after "May I write this to `<path>`?".

When it runs, spawn `design-director` via `Agent`:
- Gate: DD-CONTENT-VOICE — the `Agent` prompt instructs the agent to read
  `.claude/docs/director-gates/dd-content-voice.md` FIRST (do not read it yourself)
- Pass: content file paths under review · `design/brand/voice-and-tone.md` path · `design/registry/entities.yaml` path · `localization.locales` value (or "unset")
- Parse the first line of the reply as `[DD-CONTENT-VOICE]: TOKEN` and map the token to its
  class:
  - **APPROVE-class** (`APPROVE`) → proceed.
  - **CONCERNS-class** (`CONCERNS`) → present the flagged strings with the suggested rewrites
    and use `AskUserQuestion`: `Revise flagged items` / `Accept and proceed` /
    `Discuss further`. Revised drafts are rewritten after "May I write" and may be re-reviewed.
  - **REJECT-class** (`REJECT`) → surface the blockers; do not approve the drafts or send them
    to localization until they are resolved and the gate re-run.
  - A first line that does not parse, or a token not on the gate's Verdicts line, is not an
    approval: surface the full reply as CONCERNS-class and say the verdict line was missing.

Record the outcome in each reviewed file's header after "May I write this to `<path>`?":
`> **Design Director Review (DD-CONTENT-VOICE)**: APPROVED [date] / CONCERNS (accepted) [date] / REVISED [date]`.

Use `AskUserQuestion`:
- Prompt: "Copy reviewed. Approve it for localization and support?"
- Options: `[A] Approve — set Status: Approved` / `[B] Revise first` / `[C] Stop here`

On [A], set `> **Status**: Approved` after "May I write this to `<path>`?". For the argument
`voice`, the pipeline ends here.

### Phase 6: Localization readiness (localization-lead ∥ accessibility-specialist)

Delegate in parallel — issue both `Agent` calls before waiting for either (the second only at
`studio`):
- **localization-lead**: keys namespaced by meaning; one message per sentence with named
  placeholders and ICU plurals and selects (Korean has only the CLDR `other` category,
  English `one` and `other`); Korean particles after variables (을/를, 이/가) rephrased or
  handled by a particle helper, never hardcoded; a context note and a maximum length for
  every constrained slot; dates, numbers and currency left to CLDR formatting; expansion
  headroom for the longest locale; 알림톡 variables only in approved `#{variable}` slots.
  For each locale in `localization.locales` beyond the source, list what translation and
  review the copy needs — this phase prepares the copy; `/localize` runs the pipeline.
- **accessibility-specialist** (`studio`): accessible names for icon-only buttons, link and
  button text that makes sense out of context, error messages that identify the field and
  the fix, alt text for meaningful images, screen-reader announcements for asynchronous
  results (a deposit confirmed), and reading level.

Fold the findings into the copy deck after "May I write this to `design/content/<area>.md`?".
A change to the approved wording goes back to the ux-writer, not into the deck directly.

### Phase 7: Support readiness (customer-success-manager)

Delegate to **customer-success-manager** with the approved copy and the PRD's edge cases:
- Check the help-center article (or the area's error and empty-state copy) against what
  users will actually ask and what the product actually does; flag promises support cannot
  keep.
- Draft or update the support macros for the area's likely tickets, destined for
  `design/content/support-macros.md`.
- Name the VOC and app-review signals to watch after release.

Write the macros after "May I write this to `design/content/support-macros.md`?". Macros
drafted here were not part of the Phase 5 review: list them in the sign-off as
`not yet voice-reviewed` so the next `/team-content support-macros` run covers them.

## Error Recovery Protocol

**First, verify the artifact.** If the return contract named a path, check the
path exists before treating the phase as done — **a named artifact that is not
on disk is a failed phase, however fluent the response reads.** An agent can
burn a full phase and return a plausible preamble having written nothing, which
is neither BLOCKED nor an error nor "cannot complete", so the trigger below
never fires. Resume it naming the unmet contract; the context is
usually still there.

If any spawned agent returns BLOCKED, errors, or cannot complete: **surface it
immediately, don't proceed past a dependency it blocks, and always produce a
partial report.** Full procedure: `.claude/docs/error-recovery-protocol.md`.

Common blockers:
- Voice-and-tone guide absent and the user declines Phase 2 → the gate caps at CONCERNS
  (`NOT CHECKED — voice`); say so in the sign-off
- A term in the copy is missing from, or contradicts, `design/registry/entities.yaml` →
  surface it; `/consistency-check` or the owning PRD resolves it — do not rename silently
- A Consent & Channel item neither confirmed nor accepted → the affected templates stay Draft
- An approved 알림톡 template's wording must change → it needs re-submission for template
  review; flag it rather than editing the approved text

## File Write Protocol

Every file this pipeline produces is under `design/`, which the bounded exception never
covers. Agents return drafts inline; **this skill** writes each file itself, and only after
asking "May I write this to `<path>`?" — for the voice guide, each copy deck, each article,
the consent record, the gate outcome line and each status change. No agent in this pipeline
writes a file.

## Output

A summary covering: the voice guide's status, the copy decks and articles written with
their Status, the Consent & Channel result per region, the DD-CONTENT-VOICE outcome (or its
skip note), localization readiness per locale, accessibility findings (`studio`), support
readiness, and content listed as `not yet voice-reviewed`.

Verdict: **COMPLETE** — content approved and ready for localization.

Verdict: **NOT ASSESSED** — a required check could not run: a region's
`.claude/docs/compliance/<region>.md` is absent and the gap was not explicitly accepted (the
covered templates stay Draft), or the regions or locales stayed unset because the question
went unanswered; name each.

If the pipeline stops because a dependency is unresolved (a REJECT verdict, an unconfirmed
consent item, a missing term decision):

Verdict: **BLOCKED** — [reason]

Precedence: BLOCKED > NOT ASSESSED > COMPLETE.

Close with `AskUserQuestion`:
- Prompt: "Content for [area]: [COMPLETE / BLOCKED / NOT ASSESSED]. What next?"
- Options (those that apply):
  - `/localize extract — move the approved strings into the message catalogs (Recommended when COMPLETE)`
  - `/localize brief — prepare translator context for the other locales`
  - `/team-content <next-area> — the next area's copy deck`
  - `/team-ui <screen> — wire the copy into a screen's UI pass`
  - `/team-growth <campaign> — when the templates belong to a lifecycle campaign`
  - `Stop here`

## Collaborative Protocol

**Applies in `collaborative` mode.** For `guided` and `autonomous` modes, see
`.claude/docs/automation-modes.md`.

- **Question → Options → Decision → Draft → Approval** at every phase transition.
- **Voice first** — no copy is drafted against a voice that has not been written down.
- **Consent before approval** — no message template or marketing copy is approved before its
  Consent & Channel items are confirmed or accepted.
- **Customer-facing copy is written in the locale it ships in**, whatever the conversation
  language; headings and field labels stay as the templates spell them.
