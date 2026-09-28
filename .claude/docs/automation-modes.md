# Automation Modes — Shared Skill Pattern

This document defines the standard `modes.automation` pattern for every skill
that uses `AskUserQuestion` or writes files. Skills reference this document
instead of embedding the full mode-handling rules inline — eliminating drift
when the pattern needs updating.

**Scope**: every skill whose `resolve_config --keys` includes `automation` —
authoring, review, team orchestration, implementation and utility skills alike.
The always-collaborative skills (§ Exemptions — Skills That Ignore the
Automation Setting) are the only skills that ask or write and never resolve it.

**Companion spec**: `.claude/docs/effects-map.md`
sections `modes.automation` and `modes.automation_always_ask` are the source of
truth for behavior. This document is the implementation pattern.

> **Do not read `effects-map.md` during a skill run** — it is a large reference
> for authoring the spec rather than a runtime input, and **this document is
> self-sufficient** for deciding what to ask and what to proceed on. If a case
> genuinely is not covered here, read only its `modes.automation` section, never
> the file.

> **Stable headings.** Skills cite this document by heading — for example
> `.claude/docs/automation-modes.md` § The Three Modes or § Universal Rules per
> Mode › Guided — never by line number. A heading here is renamed only together
> with every skill that cites it.

---

## How to Use This Document

In any skill, add a single resolution step at startup and reference the
mode-aware AskUserQuestion pattern below at each gated site.

**Startup prelude** (every skill with `automation` in its `--keys` carries this
block verbatim, directly after the line that follows its bootstrap block):

```markdown
**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).
```

The value is already resolved by the skill's bootstrap line
(`resolve_config --keys …,automation,…` prints `automation: <value> (<source>)`),
which applies the whole chain: `project.local.yaml` (the key is on the local
whitelist) → `project.yaml` → the terminal default `collaborative`. An invalid
value never wins — it is reported in the notes line and the chain continues.
Use the printed value as-is; do not re-read the YAML files.

**At each AskUserQuestion site**, follow the pattern table in § Universal
Rules per Mode below. The skill author labels each decision as **major** or
**minor** (per the classification matrix in § Major vs Minor Decision
Classification) so the pattern can apply the right rule.

---

## The Three Modes

| Mode | Speed | Control | What changes |
|------|-------|---------|--------------|
| `collaborative` | Slowest | Full — every decision is the user's | Default. Q→O→D→Draft→Approval strictly followed. |
| `guided` | Balanced | High — major decisions are the user's, minor ones proceed automatically | AI states recommendation and proceeds for minor decisions. AskUserQuestion reserved for major decisions. |
| `autonomous` | Fastest | Low — AI decides, logs, and proceeds | No AskUserQuestion (except `automation_always_ask` categories). All decisions logged. |

**Default**: `collaborative`. New projects start here.

**Set by**: `/start`, `/settings`. It is locally overridable, so one developer
can run `guided` from `project.local.yaml` while the team default stays
`collaborative`.

---

## Universal Rules per Mode

### Collaborative

- `AskUserQuestion` called for every multi-option decision
- 2–4 options presented with pros/cons for every product, design and technical choice
- Full draft shown and approved before every file write
- "May I write this to [filepath]?" asked before every write
- Section-by-section approval in multi-section authoring skills
- Multi-file changes require explicit approval

### Guided

- `AskUserQuestion` called for **major decisions only** (see classification below)
- Minor decisions: AI states recommendation inline and proceeds — e.g.
  > *"Going with a module-local helper in the goals module rather than a shared package — nothing else uses it yet. Continuing unless you want to change direction."*
- Draft shown briefly before writing — proceeds after a short summary, does not wait for explicit "yes"
- "May I write?" asked for **new files only** — updates to existing files proceed directly
- Still presents options for major decisions but caps at 2 choices with a clear recommendation
- Multi-section authoring: writes each approved section immediately, no per-section confirmation

### Autonomous

- No `AskUserQuestion` calls **except** for categories in the resolved
  `automation_always_ask` list
- No draft review
- No "May I write?" prompts — writes directly
- Picks the recommended option for every decision without presenting alternatives
- All decisions logged via `log_decision` (helper in yaml-helper.sh) to
  `production/session-logs/decision-log.md`
- User reviews decision log post-session to audit choices made

---

## Major vs Minor Decision Classification

Skills label each gated decision as **major** or **minor** before applying
the mode rules.

### Major — always use AskUserQuestion in guided mode

| Decision type | Example |
|---------------|---------|
| Choosing a feature name or document path | "Should this feature be `goals` or `savings-goals`? The name becomes the PRD stem and the TR-ID prefix." |
| Mutually exclusive design directions | "SSR or SPA for the web app?" · "REST or GraphQL for the public API?" |
| Any choice that gates downstream work | Stack choice, API style, identity provider, architecture approach |
| Scope changes | "Cut Naver login from the MVP or slip the launch date?" |
| Any decision that can't be changed without significant rework | Pricing model (freemium cap vs free trial), primary data store, multi-tenancy model |

### Minor — AI recommends and proceeds in guided mode

| Decision type | Example |
|---------------|---------|
| Which section to work on next | "Moving to Edge Cases next" |
| Optional section inclusion | "Adding an `## API & Data Impact` section — this feature touches the payments contract" |
| Formatting and structure choices | Heading levels, table vs prose |
| Adding detail to an already-decided direction | Sub-options within an approved approach |
| Next-step routing after a phase completes | "Running /prd-review now" |

---

## `automation_always_ask` Categories

Even in `autonomous` mode, certain decision categories ALWAYS trigger
`AskUserQuestion`. The configured list lives at
`modes.automation_always_ask` in `project.yaml` (locally overridable).

### Default list

When the key is unset, the list is `scope_changes`, `file_deletions`,
`schema_changes`, `production_deploys`, `db_migrations`, `infra_changes`,
`secrets_access`, `pii_data_access`, `billing_changes`. Nothing is written to
`project.yaml` for this default — it lives in yaml-helper
(`_yaml_helper_always_ask_default`).

Setting the key **replaces** this list; it does not extend it. A project that
wants `architecture_decisions` on top of the defaults lists all ten (flow style,
as `/settings` writes lists):

```yaml
modes:
  automation_always_ask: [scope_changes, file_deletions, schema_changes, production_deploys, db_migrations, infra_changes, secrets_access, pii_data_access, billing_changes, architecture_decisions]
```

### Recognized categories

**This table is the set you may configure, NOT the set that always asks.** Only
the categories actually listed in `modes.automation_always_ask` — the nine
defaults above, unless the project overrides them — interrupt an `autonomous`
run. The other rows do nothing until a project opts into them. Read the resolved
list from the bootstrap block (label `automation_always_ask`) rather than
assuming a row here is active; a real run logged two `architecture_decisions` as
rule violations on a project where that category was never configured.

| Category | Covers |
|---|---|
| `scope_changes` | adding/removing features or stories from an approved plan |
| `file_deletions` | deleting any tracked file |
| `schema_changes` | API/contract or config-file schema changes (OpenAPI, GraphQL, protobuf, AsyncAPI, JSON Schema, registry schemas) |
| `architecture_decisions` | accepting, superseding or deprecating an ADR |
| `version_bumps` | changing `project.version`, a pinned stack version, or a dependency major version |
| `external_calls` | calling third-party services or APIs from a skill |
| `production_deploys` | any deploy or rollout stage beyond preview/staging; a flag change in production |
| `db_migrations` | any database schema change or data migration/backfill (writing or running it) |
| `infra_changes` | IaC plan/apply, CI/CD workflow changes, DNS, CDN, scaling, staging environment changes |
| `secrets_access` | reading, creating or rotating secrets/keys |
| `pii_data_access` | querying or exporting personal data; log samples containing PII |
| `billing_changes` | prices, plans, entitlements, payment configuration, pricing experiments |

**Overlaps prompt.** One decision can fall into several categories — a
migration that drops a column the public API still returns is both
`db_migrations` and `schema_changes`; raising the Plus plan price in production
is both `billing_changes` and `production_deploys`. It prompts when **any** of
its categories is in the resolved list.

**Staging is not production — but it is still infrastructure.** A preview
deploy or a staging flag toggle is not `production_deploys`; changing the
staging environment itself is `infra_changes`, and writing or running any
migration is `db_migrations`, whatever database it targets.

### Helper: `is_always_ask_category`

```bash
is_always_ask_category <category>
```

Returns 0 if the named category is in `modes.automation_always_ask` (or in the
default list when the key is unset), 1 otherwise. Hooks and scripts use it;
skills read the same answer from their bootstrap block. Use it at every
decision point that falls into a category of the table above.

---

## Exemptions — Skills That Ignore the Automation Setting

These skills always behave as `collaborative` regardless of the setting:

| Skill | Why always collaborative |
|-------|--------------------------|
| `gate-check` | stage transitions |
| `hotfix` | production emergency |
| `incident` | production emergency |
| `rollout-plan` | production exposure |
| `setup-stack` | stack pins and live sources |
| `start` | runs before configuration |
| `settings` | changes the automation settings themselves |

These skills do NOT add the automation prelude described above and never
resolve `automation`. They keep the Q→O→D→Draft→Approval protocol exactly.

Review mode is a separate axis: `/hotfix`, `/rollout-plan` and `/incident` are
also exempt from `modes.review_mode` (every gate they name runs at every mode —
`.claude/docs/director-gates.md`). Being always collaborative says nothing about
review gates, and vice versa.

---

## Decision Log Format (Autonomous Mode)

When `autonomous` mode skips an `AskUserQuestion`, the skill calls
`log_decision` to write a structured entry. Format per entry:

```markdown
## [timestamp] — [skill-name]

**Decision point:** [what was being decided]
**Options considered:** [list of options that would have been presented]
**Chosen:** [what was picked]
**Reason:** [one-line rationale]
**Category:** [scope_changes | file_deletions | schema_changes | … | billing_changes, or "minor"]
```

Written to `production/session-logs/decision-log.md` (append-only, never
truncated, created if absent). The user reviews the log post-session to
audit choices made.

**Decisions only, never evidence.** `production/session-logs/` is gitignored:
test results, screenshots, dry-run logs and reports written there vanish on the
next clone and never count as evidence. Evidence goes under
`production/qa/…`; the decision log records only what was chosen and why.

### Helper: `log_decision`

```bash
log_decision "<skill-name>" "<decision-point>" "<options>" "<chosen>" "<reason>" "<category>"
```

Wraps the format above. Skills call this at every decision point in
autonomous mode, including ones where the chosen value differs from
the recommended default (so the audit trail is complete).

### What to log, and at what granularity

These rules keep autonomous logs consistent across runs:

- **Log every decision that would have shown an `AskUserQuestion` widget** —
  including option/framing choices, not only final approvals. The
  framing/options decisions (which approach, which business rule, which edge
  cases) are usually the most informative entries; do not log only the
  rote "approve this section" steps.
- **Collapse a single multi-tab widget into ONE entry.** List each tab's
  choice under **Chosen** rather than emitting one entry per tab.
- **Do NOT log conversational answers the model synthesizes for itself**
  (e.g. internal Q&A while drafting a section) — only log what would have
  been an explicit user decision.
- **Do NOT emit a separate entry for routine "may I write?" file gates** —
  fold the write into the decision it implements (autonomous mode writes
  directly anyway).

### Categorizing data-file writes

The most common categorization mistake is treating a data-file append as a
`schema_changes` decision:

- **Appending facts to a registry or index** — e.g. a new entity in
  `design/registry/entities.yaml`, a row in `design/product/feature-map.md`, an
  event in `design/product/tracking-plan.md` — is **`minor`**. It adds data
  without altering a structure.
- **`schema_changes`** means editing a *structure*: an API contract under
  `docs/api/`, a JSON Schema, the section layout of a registry, or the key
  structure of `project.yaml`. Changing the contract headings of a template
  (PRD, ADR, story, control manifest) is the same kind of change — scripts and
  gates match on those headings — so it is `schema_changes` too. These are
  always-ask by default.
- **When genuinely unsure** between `minor` and an always-ask category,
  prefer the always-ask category and prompt — failing safe.

---

## The Pattern Skills Apply at Each AskUserQuestion Site

```
At each decision point in this skill:

1. Classify the decision: major or minor (see § Major vs Minor Decision
   Classification above).
2. Check whether the decision falls into a category of § Recognized
   categories that the resolved `automation_always_ask` list contains
   (default: the nine categories of § Default list).
3. Apply the mode rule:

   collaborative:           AskUserQuestion always.
   guided + major:          AskUserQuestion with capped options + recommendation.
   guided + minor:          State recommendation inline, proceed.
   autonomous + always_ask: AskUserQuestion (regardless of mode).
   autonomous + other:      Pick recommended, log via log_decision, proceed.
```

This is the contract. Skills that follow this pattern produce
consistent behavior across all three automation modes.
