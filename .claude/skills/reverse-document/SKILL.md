---
name: reverse-document
description: "Generate a missing PRD, ADR or product brief from existing code or prototypes."
argument-hint: "<prd|architecture|brief> <path>"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, AskUserQuestion, Bash(bash "*/.claude/skills/reverse-document/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys workflow,feature_overrides,automation,code_roots`

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

# Reverse Documentation

This skill analyzes existing implementation (code, prototypes, services) and generates
the missing product or architecture document for it. Use this when:
- You built a feature without writing a PRD first
- You inherited a codebase without documentation
- You prototyped an idea and need to formalize what it proved
- You need to document the "why" behind existing code

---

## Workflow

## Phase 1: Parse Arguments

**Format**: `/reverse-document <type> <path>`

**Type options**:
- `prd` → Generate a PRD for one feature (`design/prd/<feature>.md`)
- `architecture` → Generate an Architecture Decision Record (`docs/architecture/adr-NNNN-<slug>.md`)
- `brief` → Generate a product brief from a prototype or from the product as built

**Path**: Directory or file to analyze
- `apps/api/src/goals/` → the goals module of the API
- `packages/auth/src/session.ts` → a specific file
- `prototypes/goal-nudges-concept/` → a prototype directory

**Locate the path against the code roots.** The `code_roots` line above lists
each layer's roots (e.g. `web=apps/web,apps/admin; backend=apps/api,services/worker; shared=packages`).
Name the layer the path belongs to — it decides which `docs/stack-reference/`
component an ADR stamps and which PRD sections carry the evidence. A path under
`prototypes/` is a prototype, not a code root. A path outside every resolved root
is still analyzed, and the draft says so. When the line reads
`code_roots: unresolved`, print
`NOT CHECKED — no code root resolved (set stack.layers.<layer>.root via /setup-stack)`
for the layer mapping, and analyze the path as given.

**Resolve the workflow tier** for the target feature: map `<path>` to a feature
slug (the PRD stem — `apps/api/src/goals/` → `goals`), then use the
`feature_overrides` row for that feature if the block above lists one, else the
project `workflow` value. It sets how much document is generated — see Phase 5.
Semantics of each tier are in `.claude/docs/workflow-modes.md`.

> **Resolve the tier — do not assume it.** "Resolve the tier per
> `workflow-modes.md`" with no bootstrap names a resolution it gives no way to
> perform: that document defines what each tier *means*, but it cannot say what
> *this project* is set to. The consequence is large here — at `full` this skill
> writes an 11-section PRD and at `minimal` no PRD at all, so a wrong tier
> produces the wrong artifact entirely.

**Examples**:
```bash
/reverse-document prd apps/api/src/goals
/reverse-document architecture apps/api/src/auth
/reverse-document brief prototypes/goal-nudges-concept
```

## Phase 2: Analyze Implementation

**Read and understand the code/prototype**:

**For PRDs:**
- Identify user-facing behaviour: routes and screens, API endpoints, state
  transitions (e.g. a goal moving `active → paused → completed`)
- Extract business rules and calculations (fees, limits, quotas, rounding,
  eligibility, time windows) with their units
- Find configuration and flags (flag keys and defaults, env-driven limits)
- Detect edge cases handled in code (retries, idempotency keys, concurrency
  guards, timeouts, offline and error states)
- Map dependencies (which other features' modules it calls; third-party services)
- Note non-functional evidence (caching, rate limits, PII handling, retention jobs)
  and the analytics events it emits

**For ADRs:**
- Identify patterns (modular monolith, repository, transactional outbox, CQRS,
  event bus, BFF)
- Understand technical decisions (session and token model, data store, caching,
  job queue, API style, deployment)
- Map dependencies and coupling
- Assess performance characteristics
- Assess the security and privacy posture (authorization checks, secrets, PII)
- Find constraints and trade-offs
- Read the components and versions the code depends on (manifests, lockfiles)
  and compare them with `docs/stack-reference/VERSION.md`

**For product briefs (prototype or product analysis):**
- Identify the core user journey the prototype or product serves
- Extract the value hypothesis it tested and the evidence it produced
  (`REPORT.md`, `SPIKE-NOTE.md`, analytics, session notes)
- Note what worked vs what didn't
- Find technical feasibility insights
- Document the target user, their job-to-be-done and the success moment

## Phase 3: Ask Clarifying Questions

**DO NOT** just describe the code. **ASK** about intent:

**PRD questions**:
- "I see a daily deposit cap of 1,000,000 KRW enforced in the deposit service. Was this for:
  - Abuse and fraud control?
  - A payment-provider limit?
  - Or something else?"
- "Pausing a goal seems central. Is it part of the core user journey, or a supporting feature?"
- "Auto-debit retries 3 times over 72 hours. Intentional policy, or a provider default that needs revisiting?"

**Architecture questions**:
- "You're using a transactional outbox for goal events. Was this chosen for:
  - At-least-once delivery to notifications?
  - Decoupling from the push provider?
  - Or inherited from existing code?"
- "Refresh tokens are stored server-side and rotated on every use. Security requirement, or legacy?"

**Brief questions**:
- "The prototype puts automatic round-up saving ahead of manual deposits. Is that the intended value proposition?"
- "Participants tapped the fake-door 'Plus' plan far more than expected. Signal, or an accident of placement?"

## Phase 3b: Sufficiency Check — is there enough here to document?

**Run this before Phase 4, and stop here if it fails.** This skill infers a
document from an implementation, so when the implementation is thin there is
nothing to infer *from* — and the template below will happily accept invented
content, because every section of it is mandatory.

Count what Phase 2 actually found:

| Signal | What counts |
|---|---|
| Behaviours | A named user-facing behaviour or endpoint with observable rules — not a stub, not an empty handler |
| Business rules | An expression or rule computing or limiting a value (a price, fee, limit, eligibility threshold) from inputs |
| Values | A configuration constant, limit or flag with a use site |

**If all three counts are zero, or the target path holds fewer than ~20 lines of
non-boilerplate code, stop and say so:**

> "`[path]` does not contain enough implementation to reverse-document.
> Found: [N] behaviours, [N] business rules, [N] configuration values.
> Reverse-documentation infers requirements from behaviour; with no behaviour to read,
> anything I produce would be invention wearing the format of a PRD.
> If the requirements exist only in your head, `/write-prd [feature]` is the skill
> that captures them — it asks rather than infers."

Stop. Verdict: **NOT ASSESSED** — not enough implementation to document ([N] behaviours, [N] business rules, [N] configuration values).

**Do not proceed on a partial count by filling the rest.** A path with two
behaviours and no business rules gets a document with two behaviours and an explicit
`BUSINESS RULES DISCOVERED: none found in the source` — see Phase 4.

## Phase 4: Present Findings

Before drafting, show what you discovered:

```
I've analyzed [path]/. Here's what I found:

BEHAVIOURS IMPLEMENTED:
- [behaviour-a] with [property] (e.g. an idempotency key, a retry window)
- [behaviour-b] (e.g. a state transition between two statuses)
- [limit] rule (enforced on [action], resets on [condition])
- [status] lifecycle (moves through [states], triggers [effect])

BUSINESS RULES DISCOVERED:
- [Output] = [rule using discovered variables, units and rounding]
- [Secondary output] = [rule]

CONFIGURATION & FLAGS FOUND:
- [flag or config key] — default [value], used in [place]

UNCLEAR INTENT AREAS:
1. [Limit] — abuse control or provider constraint?
2. [Behaviour] — core journey or supporting feature?
3. [Retry policy] — intentional or needs revisiting?

Before I draft the document, could you clarify these points?
```

> **Every section above may be empty, and an empty one must say so.** Write
> `none found in the source` under the heading — never omit the heading (which
> reads as "not looked for") and never populate it from what a feature like this
> usually has. The bracketed rows are *shapes*, not quotas: a source with one
> behaviour yields one row, not four.
>
> This matters more here than in a report, because the output of this skill is not
> a report — it is a **product or architecture document**, and `/prd-review`,
> `/create-epics` and `/create-stories` will read it as a statement of authored
> intent. A fabricated business rule in a PRD does not stay a documentation error;
> it becomes a requirement, and then a story, and then code written to satisfy it.

Wait for user to clarify intent before drafting.

**If the user does not answer the `UNCLEAR INTENT AREAS` questions, do not draft
the resolved version anyway.** Those questions exist because **code cannot tell
you why** — it records what was built, never what was intended, and the gap
between them is the entire content of a product document. Unanswered items are
carried into the draft verbatim as open questions, in the document, marked
`INTENT UNKNOWN — inferred from implementation, not confirmed`. An inferred
intent presented as a settled one is the failure mode of this whole skill.

## Phase 5: Draft Document Using Template

Based on type, use the matching template — copy its headings byte-for-byte; the
template is the single source of the document's structure:

| Type | Template | Output Path |
|------|----------|-------------|
| `prd` | `.claude/docs/templates/prd-from-implementation.md` | `design/prd/<feature>.md` |
| `architecture` | `.claude/docs/templates/architecture-doc-from-code.md` | `docs/architecture/adr-NNNN-<slug>.md` |
| `brief` | `.claude/docs/templates/product-brief-from-prototype.md` | `design/product/product-brief.md` when none exists; otherwise `design/product/product-brief-from-code-YYYY-MM-DD.md` (Phase 6) |

**The `prd` output scales with the workflow tier** (resolved in Phase 1):
- **`full`** — generate all 11 contract sections, from `## Overview` to
  `## Acceptance Criteria`, plus the template's `## Implementation Notes`.
- **`standard`** — generate the 8 required sections (Overview, Goals & Non-Goals,
  Functional Requirements, Edge Cases, Dependencies, Non-Functional Requirements,
  Success Metrics & Instrumentation, Acceptance Criteria; + Business Rules &
  Calculations when the recovered feature defines any numeric or policy rule —
  prices, fees, limits, quotas, rate limits, eligibility thresholds, time windows,
  rounding) plus `## Implementation Notes`. Skip User Value and Configuration &
  Flags — unless `workflow_overrides.config_flags: true` in `project.yaml` forces
  Configuration & Flags.
- **`minimal`** — generate **no PRD**: at `minimal` the one-pager
  (`design/product/one-pager.md`) is the design record and PRDs are not produced.
  Say so and stop, offering two routes: update the one-pager's
  `## Core User Journey` and `## Build Order` by hand, or give this one feature a
  higher tier with `/settings workflow_overrides.feature_overrides.<feature>=standard`
  and re-run.

(`architecture` and `brief` outputs are tier-independent.)

**Fields the draft fills from what the repo already records — never invented:**
- **PRD** — `> **Feature Map Tier**:` from the feature's row in
  `design/product/feature-map.md` (ask when the feature has no row);
  `> **Implements Principle**:` from the product brief, else
  `INTENT UNKNOWN — inferred from implementation, not confirmed`; the
  `## Dependencies` table (`| Feature | PRD | Direction | Nature |`) lists the
  other features the code calls or is called by, each with its PRD path
  (`design/prd/auth.md`, or `—` when that feature has no PRD yet), and third
  parties go under `### External Services`.
- **ADR** — the number is the next free `NNNN` after the highest
  `docs/architecture/adr-*.md`; `## Stack Compatibility` stamps each component with
  the version and Knowledge Risk from `docs/stack-reference/VERSION.md` (no row ⇒
  `NOT DETERMINED`, Knowledge Risk HIGH); `## PRD Requirements Addressed` cites
  TR-IDs only as they already exist in `docs/architecture/tr-registry.yaml` —
  `/architecture-review` is the only skill that assigns them. With no PRD for the
  area, write "Foundational — no PRD requirement. Enables: …" or leave the table
  empty with `none yet — run /architecture-review after the PRD exists`.
- **Brief** — `## Prototype Evidence` cites the prototype's `REPORT.md` or
  `SPIKE-NOTE.md` by path; a claim with no evidence file is marked
  `INTENT UNKNOWN — inferred from implementation, not confirmed`.

**Draft structure**:
- Capture **what exists** (behaviours, rules, patterns, implementation)
- Document **why it exists** (intent clarified with user)
- Identify **what's missing** (edge cases not handled, gaps in the requirements)
- Flag **follow-up work** (business-rules checks, missing features)

### Stamp the provenance — required, at the top of every document this skill writes

A document produced here lands at the same path, in the same format, as one a
product manager or engineer wrote by hand, and **every downstream consumer treats
the two identically**. `/prd-review` checks it for completeness, `/create-epics`
derives epics from it, `/create-stories` turns its lines into acceptance
criteria. Nothing anywhere asks where it came from.

The difference is not cosmetic: an authored PRD states **intent**, and this one
states **observed behaviour plus inference**. When they disagree, the code is
what needs changing in the first case and the document in the second — and a
reader cannot tell which they are holding unless the document says.

Emit this banner immediately below the document's header — for a PRD, directly
under the `>` preamble block; for a brief, directly under the title:

```markdown
> **Reverse-documented from implementation** — generated by `/reverse-document`
> from `[path]` on `[date]`, at commit `[short-sha]`.
> This records what the code **does**; intent marked `INTENT UNKNOWN` below was
> inferred, not confirmed by the author. Where this document and the code
> disagree, do not assume the document is the requirement.
```

For an ADR, the provenance is the template's origin line under `## Summary` —
`> **Origin**: Reverse-documented from [path] on [YYYY-MM-DD]` — followed by the
banner's last three lines in the same blockquote. Take `[short-sha]` from
`git rev-parse --short HEAD`.

Keep the banner on revision. If a human later confirms the intent and adopts the
document as authored design, removing it is their explicit act — not a
side effect of the next edit.

## Phase 6: Show Draft and Request Approval

**Collaborative protocol**:
```
I've drafted the [feature-name] PRD based on your code and clarifications.

[Show key sections: Overview, Functional Requirements, Business Rules & Calculations, open INTENT UNKNOWN items]

ADDITIONS I MADE:
- Documented [behaviour] as "[intent]" per your clarification
- Added edge cases not in code (e.g., what if the deposit webhook arrives before the goal exists?)
- Flagged a business-rule concern: [rule] at [boundary condition]

SECTIONS MARKED AS INCOMPLETE:
- "[Feature] interaction with [other-feature]" (not fully implemented yet)
- "[Variant or plan]" (only [subset] implemented so far)

May I write this to [output path]?
```

Use the output path of the type in the prompt: `design/prd/[feature].md` for a
PRD, `docs/architecture/adr-[NNNN]-[slug].md` for an ADR, and the brief path
chosen below.

**The product brief is never overwritten by default.** Before asking about a
`brief`, check whether `design/product/product-brief.md` exists:
- **Absent** — ask "May I write this to `design/product/product-brief.md`?"
- **Present** — the default target is
  `design/product/product-brief-from-code-YYYY-MM-DD.md`, for the user to merge by
  hand: ask "May I write this to `design/product/product-brief-from-code-[date].md`?"
  Replacing the existing brief takes a separate, explicit
  "May I overwrite `design/product/product-brief.md`?" and a yes to that exact
  question — a general approval of the draft is not one. This holds at every
  automation mode: `guided` still asks it, and `autonomous` never overwrites — it
  writes the dated file and logs the decision.

**At `collaborative`** — wait for approval; the user may request changes before
writing. **At `guided`** — this is a *new* file, so `.claude/docs/automation-modes.md`
(§ Universal Rules per Mode → Guided) still has it asked ("May I write?" is asked
for new files only); if the target already exists, present the diff and proceed
without waiting for an explicit "yes" — except the product brief, which follows
the overwrite rule above. **At `autonomous`** — write and log the decision.

> **Keep this line scoped to its mode.** The skill header defers every file
> write to `automation-modes.md`, so an unconditional "wait for approval" here
> collides with it at both `guided` and `autonomous`.

## Phase 7: Write Document with Metadata

When approved, write the file. The metadata lives in the template's own fields —
never in a separate front-matter block or a status value the template does not
define. A reverse-documented ADR whose status reads anything other than one of
the `## Status` values is malformed: `/architecture-review`, `/create-control-manifest`
and `/create-stories` look for exactly those values and read anything else as
unreadable:

- **PRD** — `> **Status**: Draft` in the preamble (the document is unreviewed until
  `/prd-review` moves it on), the provenance banner under the preamble, then the
  tier's sections.
- **ADR** — `## Status` reads `Proposed` on its own line (acceptance goes through
  `/architecture-decision accept ADR-[NNNN]`, which runs the ADR review), and the
  `> **Origin**:` line sits under `## Summary`.
- **Brief** — the provenance banner under the title, then the product-brief
  sections and `## Prototype Evidence`.

```markdown
# [Feature Name]

> **Status**: Draft
> **Owner**: [role or person]
> **Last Updated**: [YYYY-MM-DD]
> **Last Verified**: [YYYY-MM-DD]
> **Implements Principle**: [principle from the brief, or INTENT UNKNOWN — inferred from implementation, not confirmed]
> **Feature Map Tier**: [MVP | Beta | GA | Later]

> **Reverse-documented from implementation** — generated by `/reverse-document`
> from `[path]` on `[date]`, at commit `[short-sha]`.
> ...

## Summary

[Rest of document...]
```

## Phase 8: Flag Follow-Up Work

After writing, suggest next steps:

```
✅ Written to design/prd/goals.md

FOLLOW-UP RECOMMENDED:
1. Run /prd-review design/prd/goals.md — confirm the recovered requirements and move Status past Draft
2. Run /business-rules-check on the deposit cap and the auto-debit retry policy
3. Record the outbox-based goal events as an ADR: /reverse-document architecture apps/api/src/goals/events
4. Run /architecture-review so the PRD's requirements receive TR-IDs
5. Implement missing edge cases:
   - Deposit webhook arriving before the goal is created
   - Goal paused while an auto-debit is in flight
6. Add the feature to design/product/feature-map.md with /map-features if it has no row

Would you like me to tackle any of these now?
```

For an ADR, the first follow-up is `/architecture-decision accept ADR-[NNNN]`;
for a brief written to the dated file, it is merging it into
`design/product/product-brief.md` by hand and then `/prd-review design/product/product-brief.md`.

---

## Template Selection Logic

| If analyzing... | Use template... | Because... |
|----------------|-----------------|------------|
| A feature module in a code root (`apps/api/src/goals/`, `apps/web/app/(app)/goals/`) | prd-from-implementation.md | Feature behaviour → PRD |
| Shared or cross-cutting code (`packages/auth/`, `apps/api/src/common/`) | architecture-doc-from-code.md | Cross-cutting decisions → ADR |
| `prototypes/*` | product-brief-from-prototype.md | Experiments → product brief |
| Integration adapters and infrastructure (`apps/api/src/integrations/toss-payments/`, `infra/`) | architecture-doc-from-code.md | Technical systems → ADR |
| UI flows (`apps/mobile/src/screens/onboarding/`) | prd-from-implementation.md | UI/UX behaviour → PRD (the screen spec itself belongs to `/ux-design`) |

---

## Example Session: Reverse-Document a Feature

```
User: /reverse-document prd apps/api/src/goals

Agent: I'll analyze your goals implementation to draft its PRD.
       [Reads code, discovers behaviours, business rules, flags]

Agent: I've analyzed apps/api/src/goals/. Here's what I found:
       [Shows behaviours, business rules, unclear areas]

       Before drafting, could you clarify:
       1. The 1,000,000 KRW daily deposit cap — abuse control or provider limit?
       2. Is pausing a goal part of the core journey?
       3. Auto-debit retries 3 times over 72 hours — intentional?

User: 1. Abuse control — our fraud team asked for it
      2. Yes, pausing is core — people pause when money is tight
      3. It's the provider default; we want 2 retries over 48 hours

Agent: That clarifies the intent. Let me draft the PRD at the standard tier.
       [Shows draft with clarified intent]

       May I write this to design/prd/goals.md?

User: Yes, write it.

Agent: ✅ Written to design/prd/goals.md
       ✅ Status: Draft, provenance banner stamped at commit 3f2a91c
       ✅ Flagged the retry policy (code: 3 over 72 h, intent: 2 over 48 h)

       Next steps:
       - Change the retry policy in code to match the confirmed intent
       - Run /business-rules-check on the deposit cap and retries
       - Run /prd-review design/prd/goals.md
```

---

## Collaborative Protocol

This skill follows the collaborative design principle:

1. **Analyze First**: Read code, understand implementation
2. **Question Intent**: Ask about "why", not just "what"
3. **Present Findings**: Show discoveries, highlight unclear areas
4. **User Clarifies**: Separate intent from accidents
5. **Draft Document**: Create doc based on reality + intent
6. **Show Draft**: Display key sections, explain additions
7. **Get Approval**: "May I write this to [filepath]?" On approval: Verdict: **COMPLETE** — document generated. On decline: Verdict: **BLOCKED** — user declined write. **NOT ASSESSED** comes only from the Phase 3b sufficiency stop, before anything is drafted.
8. **Flag Follow-Up**: Suggest related work, don't auto-execute

**Never assume intent. Always ask before documenting "why".**
