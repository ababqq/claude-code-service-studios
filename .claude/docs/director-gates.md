# Director Gates — Shared Review Pattern

Index of all director, lead and specialist review gates. Skills reference gate IDs
from this index instead of embedding prompts inline — eliminating drift when prompts
need updating. Each gate's full definition (Trigger, Context to pass, Prompt,
Verdicts) lives in its own file under `.claude/docs/director-gates/`, named after the
gate ID in lowercase.

**Scope**: every phase (Discovery → Launch); the three Opus directors
(`product-director`, `technical-director`, `delivery-manager`), `design-director`, and
the lead and specialist agents that own a gate (`tech-lead`, `qa-lead`,
`security-engineer`, `sre-engineer`). Any skill, team orchestrator or workflow may
invoke these gates, and every gate is wired to at least one named skill (the
**Spawned by** column below) — a gate that no skill spawns is a defect, not a spare.

**When a skill spawns an agent for a gate, it must NOT read the gate definition
file itself. Include the gate definition file path in the `Agent` prompt and instruct
the agent to read it first, then pass only the context items that gate's row
requires (see [Context to Pass](#context-to-pass)). Gate definitions are read by the
spawned agent, in the agent's own context window.**

---

## Gate Index

Agent by prefix: `PD-` product-director (Opus) · `TD-` technical-director (Opus) · `DM-` delivery-manager (Opus) · `DD-` design-director · `TL-` tech-lead (Sonnet) · `QL-` qa-lead · `SE-` security-engineer · `SR-` sre-engineer.

Gates owned by `design-director`, `qa-lead`, `security-engineer` and `sre-engineer`
run at the model the spawning session uses (`inherit`). The owning agent's frontmatter
`model:` is authoritative; each gate file's header repeats the tier for convenience.
Definition files below are in `.claude/docs/director-gates/`.

| Gate ID | Title | Owner | Verdicts | Spawned by | Definition file |
|---------|-------|-------|----------|------------|-----------------|
| PD-PRINCIPLES | Product Principles Stress Test | product-director | APPROVE / CONCERNS / REJECT | `/brainstorm` | pd-principles.md |
| PD-PRD-ALIGN | PRD Principles & Value Alignment | product-director | APPROVE / CONCERNS / REJECT | `/write-prd` | pd-prd-align.md |
| PD-FEATURE-MAP | Feature Map Value Check | product-director | APPROVE / CONCERNS / REJECT | `/map-features` | pd-feature-map.md |
| PD-USER-VALIDATION | User Validation Review | product-director | APPROVE / CONCERNS / REJECT | `/usability-report`, `/prototype`, `/walking-skeleton` (only when a usability session runs on the skeleton) | pd-user-validation.md |
| PD-PHASE-GATE | Product Readiness at Phase Transition | product-director | READY / CONCERNS / NOT READY | `/gate-check` | pd-phase-gate.md |
| TD-DOMAIN-BOUNDARY | Domain & Service Boundary Review | technical-director | APPROVE / CONCERNS / REJECT | `/map-features` | td-domain-boundary.md |
| TD-FEASIBILITY | Technical Feasibility of Early Risks | technical-director | VIABLE / CONCERNS / HIGH RISK | `/brainstorm` | td-feasibility.md |
| TD-ARCHITECTURE | Architecture Sign-off | technical-director | APPROVE / CONCERNS / REJECT | `/create-architecture` | td-architecture.md |
| TD-ADR | ADR Review Before Accepted | technical-director | APPROVE / CONCERNS / REJECT | `/architecture-decision` | td-adr.md |
| TD-STACK-RISK | Stack Version Risk Review | technical-director | APPROVE / CONCERNS / REJECT | `/architecture-decision` (Knowledge Risk HIGH or MEDIUM), `/setup-stack` (`upgrade` mode) | td-stack-risk.md |
| TD-PHASE-GATE | Technical Readiness at Phase Transition | technical-director | READY / CONCERNS / NOT READY | `/gate-check` | td-phase-gate.md |
| TD-MANIFEST | Control Manifest Review | technical-director | APPROVE / CONCERNS / REJECT | `/create-control-manifest` | td-manifest.md |
| TD-CHANGE-IMPACT | PRD Change Impact Review | technical-director | APPROVE / CONCERNS / REJECT | `/propagate-prd-change` | td-change-impact.md |
| DM-SCOPE | Scope & Timeline Validation | delivery-manager | REALISTIC / CONCERNS / UNREALISTIC | `/brainstorm`, `/map-features` | dm-scope.md |
| DM-SPRINT | Sprint Plan Feasibility | delivery-manager | REALISTIC / CONCERNS / UNREALISTIC | `/sprint-plan` | dm-sprint.md |
| DM-MILESTONE | Milestone Risk Assessment | delivery-manager | ON TRACK / AT RISK / OFF TRACK | `/milestone-review` | dm-milestone.md |
| DM-EPIC | Epic Structure Feasibility | delivery-manager | REALISTIC / CONCERNS / UNREALISTIC | `/create-epics` | dm-epic.md |
| DM-PHASE-GATE | Delivery Readiness at Phase Transition | delivery-manager | READY / CONCERNS / NOT READY | `/gate-check` | dm-phase-gate.md |
| DD-BRAND-DIRECTION | Brand Direction | design-director | OPTIONS / STRONG / CONCERNS | `/design-language` (when the brief has no `## Brand Direction Anchor`), `/brainstorm` (optional, `full` + UI surface) | dd-brand-direction.md |
| DD-DESIGN-LANGUAGE | Design Language Sign-off | design-director | APPROVE / CONCERNS / REJECT | `/design-language` | dd-design-language.md |
| DD-PHASE-GATE | Design & UX Readiness at Phase Transition | design-director | READY / CONCERNS / NOT READY | `/gate-check` (omitted when no UI surface is configured) | dd-phase-gate.md |
| DD-UI-CONSISTENCY | UI Consistency Review | design-director | APPROVE / CONCERNS / REJECT | `/ux-review`, `/team-ui` | dd-ui-consistency.md |
| DD-CONTENT-VOICE | Content Voice & Terminology Consistency | design-director | APPROVE / CONCERNS / REJECT | `/team-content` | dd-content-voice.md |
| TL-FEASIBILITY | Implementation Feasibility | tech-lead | FEASIBLE / CONCERNS / INFEASIBLE | `/create-architecture` | tl-feasibility.md |
| TL-CODE-REVIEW | Story Code Review | tech-lead | APPROVE / CONCERNS / REJECT | `/story-done` | tl-code-review.md |
| QL-STORY-READY | Acceptance-Criteria Testability | qa-lead | ADEQUATE / GAPS / INADEQUATE | `/create-stories`, `/story-readiness` | ql-story-ready.md |
| QL-TEST-COVERAGE | Test Coverage Review | qa-lead | ADEQUATE / GAPS / INADEQUATE | `/story-done`, `/team-qa` | ql-test-coverage.md |
| SE-SECURITY-REVIEW | Security & Privacy Design Review | security-engineer | APPROVE / CONCERNS / REJECT | `/api-design`, `/data-model`, `/architecture-decision` (ADR Domain `Auth`, `Security` or `Data`) | se-security-review.md |
| SR-PRODUCTION-READINESS | Production Readiness Review | sre-engineer | READY / CONCERNS / NOT READY | `/rollout-plan` (review-mode-exempt: runs at every mode) | sr-production-readiness.md |

---

## Review Modes

Review intensity controls whether gates run.

**Global config**: `modes.review_mode` — one word: `full`, `lean`, or `solo`. It is
a personal-experience knob, so it may live in `project.local.yaml` as well as in
`project.yaml`. Only `/settings` writes it: `/settings modes.review_mode=<value>`, or
`/settings --local modes.review_mode=<value>` for your own checkout. When neither file
sets it, `modes.rigor` supplies it (`minimal`→`solo`, `standard`→`lean`,
`full`→`full`).

Unset on an unconfigured project: `modes.rigor` defaults to `minimal`, which resolves `review_mode` to `solo`.

**Per-run override**: any gate-using skill accepts `--review [full|lean|solo]`,
overriding the resolved value for that run only.

| Mode | What runs |
|------|-----------|
| `full` | Every gate active — every workflow step reviewed |
| `lean` | Phase gates only — gates whose ID ends in `-PHASE-GATE` (in practice, the `/gate-check` panel); every per-skill gate is skipped |
| `solo` | No gates anywhere (hackathons, throwaway prototypes, maximum speed) |

**Review-mode exemption**:

> `/hotfix`, `/rollout-plan` and `/incident` are release-critical: every agent and gate they name runs at every `review_mode`. They do not resolve `review_mode`.

Of the three, only `/rollout-plan` spawns a gate (SR-PRODUCTION-READINESS), so a
production readiness verdict is recorded for every rollout plan whatever the mode.

---

## Invocation Pattern (copy into any skill)

**MANDATORY: apply the review mode before every gate spawn** (the three
review-mode-exempt skills above skip this check and spawn as normal).

The value is already resolved — a gate-using skill lists `review_mode` in the
`--keys` of its bootstrap line (`yaml-helper.sh resolve_config`, with the matching
`allowed-tools` grant — see `.claude/docs/config-resolution.md`) and reads
`review_mode` from the emitted block. Do **not** re-derive it here. The chain
(`project.local.yaml` → `project.yaml` → `modes.rigor` expansion), its defaults and
its failure modes are specified in `.claude/docs/config-resolution.md`.

An inline `--review [mode]` argument, if the skill accepts one, overrides the
resolved value for that run.

Apply the resolved mode:
- `solo` → **skip all gates**. Note: `[GATE-ID] skipped — Solo mode`
- `lean` → **skip every gate whose ID does not end in `-PHASE-GATE`**. Note: `[GATE-ID] skipped — Lean mode`
- `full` → spawn as normal

Write the skip note into the artifact the gate would have reviewed, where its
verdict line would otherwise go. The note is the evidence that the mode was applied:
a gate reference item that asks for "<GATE-ID> outcome recorded" accepts it in place
of a verdict line, and `/gate-check` reports that item as `NOT CHECKED` rather than
scoring it.

The suffix rule is derived, not enumerated: a gate is kept or skipped by `lean` the
moment it exists, and no skill carries a hand-written list of the gates `lean` keeps.

> **Phase-gate panel width is a second, independent axis.** `review_mode` decides
> whether the `-PHASE-GATE` gates run at all; `modes.workflow` decides how many
> directors sit on the panel. The width rule, its rationale and the only copy of its
> table live in `/gate-check` Section 4b (`.claude/skills/gate-check/SKILL.md`), the
> only skill that spawns `-PHASE-GATE` gates — read it there. Every other gate in
> this index has a single owner and is unaffected. Width never softens a verdict:
> the escalation rule below applies unchanged to whoever ran.

```
# Apply the review-mode check, then:
Spawn `[agent-name]` via `Agent`:
- Gate: [GATE-ID] — the `Agent` prompt instructs the agent to read
  `.claude/docs/director-gates/[gate-id].md` FIRST (the parent must not read it)
- Pass: [the gate's Context to pass items, verbatim, filled in at run time]
- Parse the first line of the reply as `[GATE-ID]: TOKEN`, map TOKEN to its class
  (Standard Verdict Format below) and handle all three classes.
- Await the verdict before proceeding.
```

For parallel spawning (several gates at one point): apply the mode check per gate,
then spawn all surviving agents simultaneously — issue all `Agent` calls before
waiting for any result; collect all verdicts before proceeding.

---

## Context to Pass

The gate file's `Domain:` header and its `**Context to pass**` bullets, and every
spawning skill's `Pass:` line, use exactly these values. Items in `<>` are filled at
run time. "Resolved `<label>` line" means the line the skill's `resolve_config` block
printed for that label, copied as printed (including `unset` forms — unset is not
"none"). "Path (or "none")" means: pass the path if the file exists, else the word
`none`.

| Gate | Domain | Context to pass (one bullet each) |
|---|---|---|
| PD-PRINCIPLES | Product strategy, principles, positioning | brief path (draft) · drafted principles & anti-goals text · target users & JTBD summary · named alternatives |
| PD-PRD-ALIGN | Product strategy, PRD alignment | PRD path · product brief path (or one-pager path) · feature-map row for the feature (tier, status) · brief success metrics |
| PD-FEATURE-MAP | Product scope & value | feature map path · product brief path · MVP scope text |
| PD-USER-VALIDATION | User evidence | report path (usability report, prototype REPORT.md or walking-skeleton report) · hypotheses tested · target segment · brief path |
| PD-PHASE-GATE | Product readiness | target phase · gate reference file path · artifact-check output for the departure phase · brief path · feature map path (or "none") |
| TD-DOMAIN-BOUNDARY | Architecture, domain boundaries, data ownership | feature map path · brief path · `docs/registry/architecture.yaml` path (or "none") · resolved `stack` line |
| TD-FEASIBILITY | Technical feasibility & vendor risk | one-line concept "<category> service on <surfaces> using <stack>" · riskiest assumptions list · resolved `stack` line (or "unset") · resolved `compliance` line |
| TD-ARCHITECTURE | Architecture, NFR/SLO, security model | `docs/architecture/architecture.md` path · `docs/ops/slo.md` path · resolved `stack` line · MVP PRD paths |
| TD-ADR | Architecture decisions, stack risk | ADR path · Knowledge Risk of the ADR's components (from `docs/stack-reference/VERSION.md`) · related ADR paths |
| TD-STACK-RISK | Stack versions, upgrade and EOL risk | component and version change (old → new, or pinned version) · `docs/stack-reference/<component>/` path · ADR paths whose `## Stack Compatibility` names the component |
| TD-PHASE-GATE | Technical readiness | target phase · gate reference file path · artifact-check output for the departure phase · resolved `stack` and `code_roots` lines |
| TD-MANIFEST | Engineering rules | manifest draft path · Accepted ADR paths · `docs/architecture/tech-radar.md` path |
| TD-CHANGE-IMPACT | Change impact | changed PRD path · summary of the PRD diff · impact report draft path |
| DM-SCOPE | Scope & schedule | MVP scope text (brief, one-pager or feature map path) · resolved `team.size` · target milestone/date (or "none given") |
| DM-SPRINT | Sprint feasibility | sprint plan draft path · velocity of previous sprints (or "none") · story paths in the sprint |
| DM-MILESTONE | Milestone risk | milestone review draft path · milestone definition path · `production/sprint-status.yaml` path · unresolved S1/S2 count |
| DM-EPIC | Epic structure | `production/epics/index.md` path · EPIC.md paths · `docs/architecture/architecture.md` path |
| DM-PHASE-GATE | Delivery readiness | target phase · gate reference file path · artifact-check output for the departure phase · `production/risk-register/` path (or "none") |
| DD-BRAND-DIRECTION | Brand & visual direction | brief path · product principles text · target users · resolved `surfaces` line |
| DD-DESIGN-LANGUAGE | Design language | `design/brand/design-language.md` path · resolved `accessibility` line · resolved `surfaces` line · brief path |
| DD-PHASE-GATE | Design & UX readiness | target phase · gate reference file path · artifact-check output for the departure phase · resolved `surfaces` line · design-language path (or "none") |
| DD-UI-CONSISTENCY | UI consistency | UX spec path or implemented screen list · design-language path · `design/ux/interaction-patterns.md` path · resolved `accessibility` line |
| DD-CONTENT-VOICE | Content voice & terminology | content file paths under review · `design/brand/voice-and-tone.md` path · `design/registry/entities.yaml` path · `localization.locales` value (or "unset") |
| TL-FEASIBILITY | Implementation feasibility | `docs/architecture/architecture.md` path · resolved `stack` line · resolved `team.size` |
| TL-CODE-REVIEW | Code review | story path · changed file list · API contract path (or "none") · governing ADR path |
| QL-STORY-READY | Testability | story path · PRD path · resolved `testing.strict` line |
| QL-TEST-COVERAGE | Test coverage | story path(s) or sprint id · test file paths · evidence directory paths · resolved `testing.strict` and `qa.level` lines |
| SE-SECURITY-REVIEW | Application security & privacy | artifact path (contract, data model or ADR) · operations or entities with auth scope and PII classification · resolved `compliance` line · `docs/security/threat-model.md` path (or "none") |
| SR-PRODUCTION-READINESS | Production readiness & reliability | rollout-plan path · `docs/ops/slo.md` path · runbook paths · latest load-test report path (or "none") · release-checklist path |

`localization.locales` has no `resolve_config` label: the spawning skill reads it
from `project.yaml` with Read at run time and passes the value (or "unset").

---

## Standard Verdict Format

Every gate returns exactly one token from its own **Verdicts** line, as the first
line of the agent's reply:

```
[GATE-ID]: TOKEN
```

— for example `[PD-PRD-ALIGN]: CONCERNS` or `[DM-MILESTONE]: AT RISK`. The square
brackets are part of the line an agent emits: `[DM-EPIC]: REALISTIC`. To a parser
they are optional: `DM-EPIC: REALISTIC` parses the same as `[DM-EPIC]: REALISTIC`.
Findings follow on the next lines. The spawning skill parses the first line and maps the
token to one of three classes; skills must handle all three:

| Class | Tokens |
|---|---|
| APPROVE-class (proceed) | APPROVE, READY, VIABLE, REALISTIC, ON TRACK, FEASIBLE, ADEQUATE, STRONG |
| CONCERNS-class (surface via AskUserQuestion: revise / accept / discuss) | CONCERNS, AT RISK, GAPS |
| REJECT-class (blocking) | REJECT, NOT READY, HIGH RISK, UNREALISTIC, OFF TRACK, INFEASIBLE, INADEQUATE |
| Selection (not a verdict) | OPTIONS — present the directions, the user selects, then treat as APPROVE-class |

| Class | Meaning | Default action |
|-------|---------|----------------|
| **APPROVE-class** | No blocking issues. Proceed. | Continue the workflow |
| **CONCERNS-class [list]** | Issues present but not blocking. | Surface to user via `AskUserQuestion` — options: `Revise flagged items` / `Accept and proceed` / `Discuss further` |
| **REJECT-class [blockers]** | Blocking issues. Do not proceed. | Surface blockers to user. Do not write files or advance stage until resolved. |
| **Selection (OPTIONS)** | Several valid directions; the choice is the user's. | Present the directions via `AskUserQuestion`; record the chosen one; continue as APPROVE-class |

A reply whose first line does not parse — missing, malformed, or a token that is not
on that gate's **Verdicts** line — is not an approval. Surface the full reply to the
user as CONCERNS-class and say that the verdict line was missing.

**Escalation rule**: When several gates are spawned in parallel, apply the strictest
class — one REJECT-class verdict overrides every APPROVE-class verdict, and one
CONCERNS-class verdict caps the result at CONCERNS.

---

## Recording Gate Outcomes

After a gate resolves, record the verdict in the reviewed document's status header:

```markdown
> **[Director] Review ([GATE-ID])**: APPROVED [date] / CONCERNS (accepted) [date] / REVISED [date]
```

`[Director]` is the owning agent's role title — for example
`> **Product Director Review (PD-PRD-ALIGN)**: CONCERNS (accepted) 2026-10-14` in
`design/prd/goals.md`. When the resolved review mode skipped the gate, the skip note
(`[GATE-ID] skipped — Lean mode` / `— Solo mode`) goes in the same place instead.
Review-mode-exempt skills always record a verdict line.

For `-PHASE-GATE` gates, `/gate-check` records the panel verdicts in its report,
`production/gate-checks/gate-<target>-YYYY-MM-DD.md`.

---

## Parallel Gate Protocol

At checkpoints needing several gates at once (most common at `/gate-check`):

```
Spawn in parallel (issue all `Agent` calls before waiting for any result):
product-director → PD-PHASE-GATE, technical-director → TD-PHASE-GATE, delivery-manager → DM-PHASE-GATE, design-director → DD-PHASE-GATE
(at the width `/gate-check` §4b resolves)

Collect every verdict, then apply the escalation rule:
- Any REJECT-class (NOT READY) → overall verdict minimum FAIL
- Any CONCERNS-class → overall verdict minimum CONCERNS
- All APPROVE-class (READY) → eligible for PASS (still subject to artifact checks)
```

---

## Adding New Gates

1. Assign a gate ID: `[OWNER-PREFIX]-[DESCRIPTIVE-SLUG]`. Prefixes: `PD-` `TD-` `DM-`
   `DD-` `TL-` `QL-` `SE-` `SR-`; add a new one when a new agent owns a gate
   (`growth-manager` → `GM-`). The prefix names the owner — never reuse a prefix for
   a different agent. End an ID in `-PHASE-GATE` only if `/gate-check` spawns it on
   its panel: the `lean` suffix rule keys on that suffix.
2. Create `.claude/docs/director-gates/[gate-id].md` (lowercase), starting with the
   standard "> Gate definition..." header note and the
   `Agent: … | Model tier: … | Domain: …` line, with all five fields: Trigger,
   Context to pass, Prompt, Verdicts (with the `[GATE-ID]: TOKEN` first-line
   contract), special handling notes.
3. Take the verdict tokens from the class table in Standard Verdict Format. A new
   token is added to that table, with its class, before any skill parses it.
4. Add the gate's rows to the Gate Index, Context to Pass and Gate Coverage by Stage
   tables above.
5. Add the gate and its tokens to the owning agent's `## Gate Verdict Format` section.
6. Wire it into at least one skill: the skill names the gate ID in its review-mode
   check, copies the Context items verbatim into its `Pass:` line, parses the first
   line of the reply, and has `review_mode` in its `--keys` plus `Agent` and
   `AskUserQuestion` in `allowed-tools`. Reference gates by ID only — never copy the
   prompt text into the skill. A gate that no skill spawns is deleted, not kept.
7. There is no review-mode list to update: `lean` keeps or skips the new gate by its
   suffix.

---

## Gate Coverage by Stage

| Stage | Required gates | Optional gates |
|---|---|---|
| Discovery | PD-PRINCIPLES | TD-FEASIBILITY, DM-SCOPE, DD-BRAND-DIRECTION (full + UI), PD-USER-VALIDATION (/prototype), TD-STACK-RISK (/setup-stack upgrade) |
| Definition | TD-DOMAIN-BOUNDARY, PD-FEATURE-MAP, DM-SCOPE, PD-PRD-ALIGN (per PRD) | TD-CHANGE-IMPACT (on PRD revision) |
| Architecture | TD-ARCHITECTURE, TL-FEASIBILITY, TD-ADR (per ADR), SE-SECURITY-REVIEW (per API contract / data model), TD-MANIFEST (full) | TD-STACK-RISK |
| Validation | DD-DESIGN-LANGUAGE, DM-EPIC, QL-STORY-READY (per story), DM-SPRINT, PHASE-GATEs via /gate-check | DD-BRAND-DIRECTION (brief without anchor), PD-USER-VALIDATION, DD-UI-CONSISTENCY, SE-SECURITY-REVIEW (contract update) |
| Build | TL-CODE-REVIEW (per story), QL-TEST-COVERAGE (per story), QL-STORY-READY, DM-SPRINT (per sprint) | DM-MILESTONE, DD-UI-CONSISTENCY, DD-CONTENT-VOICE, TD-CHANGE-IMPACT |
| Hardening | QL-TEST-COVERAGE (/team-qa), PD-USER-VALIDATION (/usability-report), SR-PRODUCTION-READINESS (/rollout-plan) | DM-MILESTONE |
| Launch | PHASE-GATEs via /gate-check (on entry), SR-PRODUCTION-READINESS (per rollout plan) | DM-MILESTONE, DD-CONTENT-VOICE |

"Required" here means the stage's normal workflow reaches the gate; whether it
actually spawns is still decided by the review mode (a skipped gate leaves its skip
note). What `/gate-check` demands at each transition is defined by its gate reference
files, not by this table.
