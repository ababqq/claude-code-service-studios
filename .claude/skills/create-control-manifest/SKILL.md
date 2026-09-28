---
name: create-control-manifest
description: "Flat must/never rules per layer from Accepted ADRs and the tech radar."
argument-hint: "[update — regenerate from current ADRs] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/create-control-manifest/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,stack`

Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).


# Create Control Manifest

The Control Manifest is a flat, actionable rules sheet for engineers. It
answers "what do I do?" and "what must I never do?" — organized by architectural
layer, extracted from all Accepted ADRs, the tech radar, and the stack reference
docs. Where ADRs explain *why*, the manifest tells you *what*.

**Output:** `docs/architecture/control-manifest.md`

**When to run:** After `/architecture-review` passes and ADRs are in Accepted
status. Re-run whenever new ADRs are accepted, existing ADRs are revised, or the
tech radar changes.

**Readers:** `/create-stories` embeds the manifest's `Manifest Version` in every
story; `/story-readiness` compares that embedded date with this file to catch
stories written against stale rules; `/dev-story` implements against it.

---

## 1. Load All Inputs

### ADRs
**Establish the denominator first.** Glob `docs/architecture/adr-*.md`. Call the
count **N**. If N is 0: "No ADRs found — run `/architecture-decision` before
building a control manifest." Stop. Verdict: **NOT ASSESSED** — no ADRs to build from.

**Resolve status without reading the ADRs** — the filter must precede the read,
not follow it:
```
Grep pattern="^## Status" glob="docs/architecture/adr-*.md" output_mode="content" -A 3
```
Interpret against N:

| Result | Meaning | Action |
|---|---|---|
| **N matches, some read `Accepted`** | Normal. | The Accepted set is **A**; proceed with A. |
| **N matches, none `Accepted`** | Genuinely no Accepted ADRs. | "[N] ADRs found, none Accepted. A manifest built from Proposed ADRs would encode decisions that may still change." Ask whether to proceed with Proposed or stop; stopping ends with Verdict: **NOT ASSESSED** — no Accepted ADRs to build from. **Do not silently emit an empty manifest.** |
| **Fewer than N match** | Some ADRs have no `## Status` section — their acceptance is unknown. | They are not in A. Name each in the preview and the manifest header as `NOT CHECKED — <file> has no ## Status section (run /architecture-decision retrofit <file>)`; proceed with A. |
| **0 matches, N > 0** | **Malformed ADRs — not an empty Accepted set.** `## Status` is BLOCKING-if-missing. | "[N] ADRs found, none has a `## Status` section — acceptance cannot be determined. Run `/architecture-decision retrofit <file>` on each." **Stop** with Verdict: **NOT ASSESSED** — no ADR status could be read. Do not treat all ADRs as Accepted; do not emit a manifest. |

`Superseded by ADR-NNNN` and `Deprecated` ADRs are never in A — their rules
would contradict the ADR that replaced them.

- Note the ADR number and title for every rule sourced.

### Project Config
- Read `naming.*` and `performance.*` from `project.yaml` with Read (these keys have
  no `resolve_config` label). A key that is absent is written into the manifest as
  `NOT SET — naming.<key>` / `NOT SET — performance.<key>`, never filled with a
  convention or a budget the project did not choose. `/setup-stack` sets `naming.*`;
  `/create-architecture` and `/settings` set `performance.*`.

### Tech Radar
- Read `docs/architecture/tech-radar.md`: `## Adopt` lists the approved libraries
  and services; every `## Hold` and `## Forbidden Patterns` entry becomes a
  **Never** rule. Each entry already carries its source (`ADR-NNNN` or
  `Source: <url>`) — keep it on the rule.
- If the radar does not exist, record
  `NOT CHECKED — tech radar absent (run /setup-stack)` in the preview and the
  manifest header. Do not substitute rules from memory.

### Stack Reference
- The resolved `stack` line names each configured component and version; read
  `docs/stack-reference/VERSION.md` for the pinned version and Knowledge Risk of
  each.
- Read `docs/stack-reference/<component-slug>/deprecated-apis.md` for each
  component that has one — these become forbidden API entries
- Read `docs/stack-reference/<component-slug>/current-best-practices.md` if it exists
- If the stack line reads `stack: unset — run /setup-stack`, record
  `NOT CHECKED — stack unset (run /setup-stack)` in the preview and under the
  manifest's `### Forbidden APIs` heading, in place of the stack-sourced rules, and
  continue with the ADR and radar rules.

Report: "Loaded [N] Accepted ADRs, stack: [the resolved `stack` line]."

---

## 2. Extract Rules from Each ADR

Read **only these five sections** per Accepted ADR — not the whole file. Context,
Consequences, Migration Plan and Validation Criteria explain *why* a decision was
made; the manifest records *what to do*, so they are not needed here:
```
Grep pattern="^## (Decision|Alternatives Considered|Performance & SLO Implications|Security & Privacy Implications|Stack Compatibility)" glob="docs/architecture/adr-*.md" output_mode="content" -A 30
```
Filter the results to the Accepted set **A** resolved above. If a section is
absent for a given ADR, note it per ADR and continue; if a section is absent
across **all** of A, report "No Accepted ADR contains a `[section]` section — the
manifest's [category] rules will be empty. Verify this is intended." Escalate to
a full read of one ADR only when its scanned sections cross-reference material
outside them (e.g. a Decision that says "subject to the constraints in Context").

For each Accepted ADR, extract:

### Required Patterns (from the `## Decision` section)
- Every "must", "should", "required to", "always" statement in the Decision body
  — including any `### Implementation Guidelines` sub-heading when the ADR has one
  (the ADR template emits it; older ADRs state mandates directly in `## Decision`).
  Never scan for `### Implementation Guidelines` alone — it is absent from many
  retrofitted ADRs, and scanning for it yields an empty Required Patterns
  section on a manifest that should have been full.
- Every specific pattern or approach mandated

### Forbidden Approaches (from "Alternatives Considered" sections)
- Every alternative that was explicitly rejected — *why* it was rejected becomes
  the rule ("never use X because Y")
- Any anti-patterns explicitly called out

### Performance & SLO Guardrails (from "Performance & SLO Implications")
- Latency budgets: "`GET /v1/goals` p95 ≤ 300 ms", "this job must finish within
  the 02:00–04:00 KST window"
- Error and query budgets: "error rate ≤ 0.5% per endpoint", "no more than 3
  queries per request on list endpoints"
- Client budgets the ADR sets: initial JS per route, mobile cold start

### Security & Privacy Rules (from "Security & Privacy Implications" — each becomes a Never/Always rule)
- Authorization: "Always check resource ownership server-side on every goals
  endpoint" (BOLA/IDOR)
- Data handling: "Never log email addresses, phone numbers or bank account
  numbers", "Always mask account numbers to the last 4 digits in API responses"
- Secrets and tokens: "Never store refresh tokens in web `localStorage`"
- Retention and consent rules the ADR states, with their periods

### Stack API Constraints (from "Stack Compatibility")
- Post-cutoff APIs that require verification
- Verified behaviours that differ from default LLM assumptions
- APIs or configuration options that behave differently in the pinned version

### Layer Classification
Classify each rule by the architectural layer of the module it governs:
- **Foundation**: identity & auth, the primary data store and migrations, API
  style and gateway, deployment topology and environments, observability,
  secrets, shared SDKs and libraries
- **Core**: the core domain modules and their persistence (for Moa: goals,
  payments), background jobs and queues, integrations with payment and
  notification providers
- **Feature**: secondary features, experiments, admin console workflows,
  notification content, ML and recommendation features
- **Presentation**: web and mobile UI, app shell and navigation, design tokens
  and components, client state and caching, client-side analytics, accessibility

If an ADR spans multiple layers, duplicate the rule into each relevant layer.

---

## 3. Add Global Rules

Combine rules that apply to all layers:

### From project config (`project.yaml`):
- Naming conventions — `naming.*`: files, classes, components, variables,
  constants, API paths, API fields, DB tables, DB columns, env vars, events
- Performance budgets — `performance.*`: `api_p95_ms`, `error_rate_pct`,
  `availability_pct`, `lcp_ms`, `inp_ms`, `cls`, `bundle_kb`, `cold_start_ms`,
  `crash_free_pct`

### From deprecated-apis.md:
- Deprecated APIs → Forbidden API entries, **filtered for relevance to this
  project**. Do not copy the deprecation table wholesale.
  > Each entry must apply to what this project actually builds. A component's
  > `deprecated-apis.md` mixes subsystems: a row about a server-rendering API
  > means nothing to routes that render only on the client, and a row about a
  > native-module API means nothing to an app that ships no native modules.
  > Emitting such a row unqualified gives every engineer a global rule about
  > something they never touch. If you cannot tell whether an entry applies —
  > a subsystem, a platform or a package the project may not include — either
  > scope the rule ("in the web layer, for server-rendered routes: ...") or omit it
  > and note it as unresolved. A manifest of rules that do not apply is one nobody
  > reads, and `/create-stories` consumes this file.

### From current-best-practices.md (if available):
- Stack-recommended patterns → Required entries

### From the tech radar:
- `## Adopt` entries → Approved Libraries
- `## Hold` entries → "Never adopt [name] in new code — [why]" rules
- `## Forbidden Patterns` entries → copy directly as Never rules, with their source

---

## 4. Present Rules Summary Before Writing

Before writing the manifest, present a summary to the user:

```
## Control Manifest Preview
Stack: [the resolved `stack` line]
ADRs covered: [list ADR numbers]
Tech radar: [date read, or NOT CHECKED — tech radar absent (run /setup-stack)]
Total rules extracted:
  - Foundation layer: [N] required, [M] forbidden, [P] guardrails, [S] security & privacy
  - Core layer: [N] required, [M] forbidden, [P] guardrails, [S] security & privacy
  - Feature layer: ...
  - Presentation layer: ...
  - Global: [N] naming conventions, [M] forbidden APIs, [P] approved libraries, [H] tech-radar Never rules
```

Use `AskUserQuestion`:
- Prompt: "Does this rule summary look complete?"
- Options:
  - `[A] Yes — looks good, run the director review and write the manifest`
  - `[B] Add rules — I have additional rules to include before writing`
  - `[C] Remove rules — some extracted rules should be dropped`
  - `[D] Stop here — I need to review the ADRs first`

---

## 4b. Director Gate — Technical Review

**Review mode check** — apply before spawning TD-MANIFEST, using the resolved
`review_mode` (an inline `--review` overrides it for this run):
- `solo` → skip all gates. Note: `[TD-MANIFEST] skipped — Solo mode`. Proceed to Phase 5.
- `lean` → **skip every gate whose ID does not end in `-PHASE-GATE`**. Note: `[GATE-ID] skipped — Lean mode`
  TD-MANIFEST does not end in `-PHASE-GATE`, so it is skipped: note
  `[TD-MANIFEST] skipped — Lean mode`. Proceed to Phase 5.
- `full` → spawn as normal.

The skip note goes into the manifest header in place of the review line (Phase 5
format), so a reader can tell the review was skipped by mode rather than passed.

**Write the draft the gate reads.** The gate reads the manifest draft from disk,
while `docs/architecture/control-manifest.md` is written (or, on `update`,
replaced) only after the review resolves. Ask "May I write this to
`production/session-state/control-manifest-draft.md`?" and write the full draft
(the Phase 5 format) there — a gitignored working copy, overwritten on every run.
That path is the manifest draft path passed below.

Spawn `technical-director` via `Agent` using gate **TD-MANIFEST**. The `Agent`
prompt instructs the agent to read `.claude/docs/director-gates/td-manifest.md`
first — do not read the gate file or paste it into the prompt.

Pass: manifest draft path · Accepted ADR paths · `docs/architecture/tech-radar.md` path

Parse the first line of the reply as `[TD-MANIFEST]: TOKEN` and map the token to
its class (`.claude/docs/director-gates.md` § Standard Verdict Format):
- **APPROVE-class** (`APPROVE`) → proceed to Phase 5
- **CONCERNS-class** (`CONCERNS`) → surface the flagged rules via `AskUserQuestion`
  with options: `Revise flagged rules` / `Accept and proceed` / `Discuss further`
- **REJECT-class** (`REJECT`) → do not write the manifest; fix the flagged rules,
  re-present the summary, and re-run the review on the revised draft
- **First line missing, malformed, or a token not on the gate's Verdicts line** →
  not an approval: show the full reply as CONCERNS-class and say the verdict line
  was missing

Record the outcome in the manifest header:
`> **Technical Director Review (TD-MANIFEST)**: APPROVED [date] / CONCERNS (accepted) [date] / REVISED [date]`.

---

## 5. Write the Control Manifest

Use `AskUserQuestion`:
- Prompt: "May I write this to `docs/architecture/control-manifest.md`?"
- Options:
  - `[A] Yes — write to docs/architecture/control-manifest.md`
  - `[B] Show me the full draft first, then ask again`
  - `[C] Not yet — I want to make more changes`

Format:

```markdown
# Control Manifest

> **Stack**: [components + pinned versions from the resolved `stack` line]
> **Last Updated**: [date]
> **Manifest Version**: [date]
> **ADRs Covered**: [ADR-NNNN, ADR-MMMM, ...]
> **Status**: [Active — regenerate with `/create-control-manifest update` when ADRs change]
> **Technical Director Review (TD-MANIFEST)**: [APPROVED YYYY-MM-DD | CONCERNS (accepted) YYYY-MM-DD | REVISED YYYY-MM-DD | [TD-MANIFEST] skipped — Lean mode | [TD-MANIFEST] skipped — Solo mode]

`Manifest Version` is the date this manifest was generated. Story files embed
this date when created. `/story-readiness` compares a story's embedded version
to this field to detect stories written against stale rules. Always matches
`Last Updated` — they are the same date, serving different consumers.

This manifest is an engineer's quick-reference extracted from all Accepted ADRs,
the tech radar, and the stack reference docs. For the reasoning behind each
rule, see the referenced ADR.

---

## Foundation Layer Rules

*Applies to: identity & auth, data store & migrations, API style, deployment topology & environments, observability, secrets*

### Required Patterns
- **[rule]** — source: [ADR-NNNN]
- **[rule]** — source: [ADR-NNNN]

### Forbidden Approaches
- **Never [anti-pattern]** — [brief reason] — source: [ADR-NNNN]

### Performance & SLO Guardrails
- **[endpoint / job / screen]**: [budget, e.g. p95 ≤ N ms] — source: [ADR-NNNN]

### Security & Privacy Rules
- **Always [rule]** / **Never [rule]** — source: [ADR-NNNN]

---

## Core Layer Rules

*Applies to: core domain modules and their persistence, background jobs and queues, payment and notification integrations*

### Required Patterns
...

### Forbidden Approaches
...

### Performance & SLO Guardrails
...

### Security & Privacy Rules
...

---

## Feature Layer Rules

*Applies to: secondary features, experiments, admin console workflows, notification content, ML features*

### Required Patterns
...

### Forbidden Approaches
...

### Performance & SLO Guardrails
...

### Security & Privacy Rules
...

---

## Presentation Layer Rules

*Applies to: web and mobile UI, app shell, design tokens & components, client state, client analytics, accessibility*

### Required Patterns
...

### Forbidden Approaches
...

### Performance & SLO Guardrails
...

### Security & Privacy Rules
...

---

## Global Rules (All Layers)

### Naming Conventions
| Element | Convention | Example |
|---------|-----------|---------|
| Files | [from naming.files in project.yaml, or NOT SET] | [example] |
| Components | [from naming.components, or NOT SET] | [example] |
| Classes | [from naming.classes, or NOT SET] | [example] |
| Variables | [from naming.variables, or NOT SET] | [example] |
| Constants | [from naming.constants, or NOT SET] | [example] |
| API paths | [from naming.api_paths, or NOT SET] | [example] |
| API fields | [from naming.api_fields, or NOT SET] | [example] |
| DB tables | [from naming.db_tables, or NOT SET] | [example] |
| DB columns | [from naming.db_columns, or NOT SET] | [example] |
| Env vars | [from naming.env_vars, or NOT SET] | [example] |
| Events | [from naming.events, or NOT SET] | [example] |

### Performance Budgets
| Target | Value |
|--------|-------|
| API p95 latency | [from performance.api_p95_ms in project.yaml, or NOT SET] |
| Error rate | [from performance.error_rate_pct, or NOT SET] |
| Availability | [from performance.availability_pct, or NOT SET] |
| LCP (p75) | [from performance.lcp_ms, or NOT SET] |
| INP (p75) | [from performance.inp_ms, or NOT SET] |
| CLS (p75) | [from performance.cls, or NOT SET] |
| Initial JS per route (gzip) | [from performance.bundle_kb, or NOT SET] |
| Mobile cold start | [from performance.cold_start_ms, or NOT SET] |
| Crash-free sessions | [from performance.crash_free_pct, or NOT SET] |

### Approved Libraries
- [library] — approved for [purpose] — source: [ADR-NNNN | tech radar ## Adopt]

### Forbidden Patterns (tech radar)
- **Never adopt [name] in new code** — [why] — source: tech radar `## Hold` ([ADR-NNNN | Source: url])
- **Never [pattern]** — [why] — source: tech radar `## Forbidden Patterns` ([ADR-NNNN | Source: url])

### Forbidden APIs ([component + version])
These APIs are deprecated or unverified for [component + version]:
- `[api name]` — deprecated since [version] / unverified post-cutoff
- Source: `docs/stack-reference/[component-slug]/deprecated-apis.md`

### Cross-Cutting Constraints
- [constraint that applies everywhere, regardless of layer]
```

Layers with no rule of a given kind keep the heading with `none — no Accepted ADR
states one` under it: an omitted heading reads as "not looked for".

---

## 6. Suggest Next Steps

After writing the manifest:

- If epics/stories don't exist yet: "Run `/create-epics layer: foundation` then `/create-stories [epic-slug]` — engineers
  can now use this manifest when writing story implementation notes."
- If this is a regeneration (manifest already existed): "Updated. Recommend
  notifying the team of changed rules — especially any new Forbidden entries.
  Stories created before today carry an older `Manifest Version`;
  `/story-readiness` will flag them."

---

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and
`autonomous` modes, see `.claude/docs/automation-modes.md` — the rules below
describe what collaborative mode requires, not universal behavior.

1. **Load silently** — read all inputs before presenting anything
2. **Show the summary first** — let the user see the scope before writing
3. **Ask before writing** — always confirm before creating or overwriting the manifest. On write: Verdict: **COMPLETE** — control manifest written. On decline: Verdict: **BLOCKED** — user declined write. When Phase 1 stops — no ADRs found, no ADR `## Status` readable, or the user stops when none is Accepted: Verdict: **NOT ASSESSED** — nothing was built.
4. **Source every rule** — never add a rule that doesn't trace to an ADR, the
   tech radar, or a stack reference doc
5. **No interpretation** — extract rules as stated in ADRs; do not paraphrase
   in ways that change meaning
