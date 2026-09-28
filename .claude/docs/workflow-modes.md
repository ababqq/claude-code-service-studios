# Workflow Modes — Shared Skill Pattern

This document defines `modes.workflow` and `workflow_overrides` — how much
product and technical documentation is REQUIRED before code can begin — for
every skill that authors, reviews, gates, or plans against project artifacts.
Skills reference this document instead of embedding the tier tables inline.

**Companion spec**: `.claude/docs/effects-map.md`
sections `modes.workflow` and `workflow_overrides` are the source of
truth for behavior. This document is the implementation pattern.

> **Do not read `effects-map.md` during a skill run.** It is a large reference
> for *authoring and changing the spec*, not a runtime input. **This document is
> self-sufficient** for resolving the tier and applying it: the resolution chain,
> the three tiers, the required sections, and the override rules are all here.
> If you hit a case this document genuinely does not cover, read only the one
> `effects-map.md` section for the knob in question — never the file.

**Related shared docs**: `.claude/docs/automation-modes.md` (how skills prompt),
`.claude/docs/director-gates.md` (which reviewers spawn). `workflow` is
orthogonal to both — it controls *what artifacts must exist*, not *how the
skill prompts* or *who reviews*.

> **Stable headings.** Skills cite this document by heading — for example
> `.claude/docs/workflow-modes.md` § What `<feature>` is — one derivation,
> everywhere — never by line number.

---

## How to Use This Document

A skill that authors, reviews, or gates a product or technical artifact
resolves the effective workflow tier at startup, then applies the
required-section / required-artifact set for that tier.

**Resolution (per skill):**

```
Resolve the workflow tier (store the result; see scope note below):
1. If the resolution is for a named feature AND
   `workflow_overrides.feature_overrides.<feature>` is set → use that tier
2. Else read `modes.workflow` from `project.yaml` → use that value
3. Else → use the tier implied by `modes.rigor`
   (`minimal`→`minimal`, `standard`→`standard`, `full`→`full`;
    `rigor` itself defaults to `minimal`)
```

`modes.workflow` has **no terminal default** — step 3 is the `rigor` expansion,
not a hardcoded `standard`. A skill that hardcodes `standard` (or any other
tier) as its fallback ignores `rigor: minimal` and `rigor: full` entirely.

### What `<feature>` is — one derivation, everywhere

**`<feature>` is the PRD filename stem**: `design/prd/goals.md` → `goals`. That
is the key to write under `workflow_overrides.feature_overrides`, and every
skill must derive it the same way.

By contract the stem is also the feature slug in the feature map, the prefix of
the feature's TR-IDs (`TR-goals-001`) and the `**PRD**:` field of its stories.
When a hand-edited file breaks that equality, **the stem wins**: accept the
TR-ID prefix only as a fallback match when the PRD stem yields nothing, and say
that the two disagree.

> **Why the order matters.** Deriving the key from the TR-ID first gives one
> feature two different override keys whenever its PRD was renamed after its
> requirements were registered (`design/prd/savings-goals.md` with requirements
> `TR-goals-NNN`). The documented remedy for a missing PRD section — "set
> `workflow_overrides.feature_overrides.savings-goals: full`" — is then looked
> up under `goals`, finds nothing, and the skill continues at the project tier
> **silently**. The escape hatch exists and cannot be reached.

**A key that matches no feature is an error, not a no-op.** If
`workflow_overrides.feature_overrides` contains a key that resolves to no PRD
stem in `design/prd/`, say so — naming the unmatched key and the stems
available. Silently ignoring it hides the mistake above.

> **Checked where PRDs are expected to already exist — not by the skill that
> writes them.** `/gate-check` is the single implementing site (see
> `.claude/skills/gate-check/SKILL.md` § Per-feature overrides): from the
> Definition → Architecture gate onward, an orphan key is reported as CONCERNS,
> because by then every in-scope PRD should be on disk.
>
> `/write-prd` **creates** `design/prd/<feature>.md`, so before its first run
> the override key matches no stem *by definition* — that is the healthy case,
> not an error. It must not report the key as orphaned, and must not refuse to
> apply the tier it names. The same holds for any other authoring skill running
> before the PRD exists. Applying this rule there would fire on exactly the
> configuration it was written to protect.

---

Step 1 (the per-feature override) applies to skills that act on a named feature:
- **Single-feature, resolve once per run**: `write-prd`, `prd-review`,
  `dev-story`, `story-done`, `create-stories`, `propagate-prd-change`,
  `reverse-document` (one PRD, story or epic per invocation).
- **Multi-feature, resolve once per item**: `story-readiness` (per story across
  `all`/`sprint` scope), `review-all-prds` (per PRD), `qa-plan` and
  `regression-suite` audit (per PRD/feature). These do NOT freeze a single tier
  for the run — different features in one run may resolve to different tiers.

Skills that operate project-wide (`gate-check`, `create-epics`) use the
project-level `workflow` plus consider per-feature overrides where the tier
table says so.

> **"Critical ADR" (used in the tier tables):** an ADR governing a
> **Foundation-layer** module — identity & auth, the primary data store, API
> style, deployment topology & environments, observability, secrets management:
> the decisions everything else depends on. At `standard`, only critical ADRs are
> required/blocking (the architecture doc marks which ones); non-critical ADRs
> are advisory. When in doubt about an ADR's layer, treat it as critical (fail
> safe toward requiring it).

`modes.workflow` reads via **`resolve_config --keys workflow`** (or
`resolve_setting modes.workflow`), which applies the whole chain including the
`rigor` expansion. Do **not** use `get_effective_yaml_key modes.workflow`: it
reads the two YAML files only, so on a project that sets `modes.rigor` and not
`modes.workflow` it returns **empty** while the effective tier is whatever rigor
implies. (`project.local.yaml` is not allowed to override workflow — it is locked
to `project.yaml` per the whitelist — so the only sources are `project.yaml` and
the expansion.) Per-feature overrides read via
**`resolve_config --keys feature_overrides`**, which prints
`feature_overrides: <stem>=<tier> …` (or `none`); pass the feature as the
positional argument (`resolve_config --keys feature_overrides goals`) to get the
effective tier for that one feature as `workflow[goals]: …`.

---

## The Three Tiers

| Tier | Token/time cost | Required before code | Best for |
|------|----------------|---------------------|----------|
| `full` | High | All 11 PRD sections per feature, product brief, feature map, full architecture with an SLO per critical journey, all Foundation ADRs, API contract and data model (with a backend), threat model (with PII), test & CI scaffold, design language (all 9 sections) and UX specs per key screen (with a UI), control manifest, walking skeleton on staging | Regulated or enterprise products (fintech, health, B2B with SLAs), larger teams, learning the full pipeline |
| `standard` | Balanced | 8 PRD sections per feature + conditional Business Rules & Calculations, product brief, feature map, one architecture doc, critical ADRs, API contract and data model (with a backend), threat model (with PII), test & CI scaffold, design language sections 1–5 and key UX specs (with a UI), walking skeleton on staging | Seed-stage product teams — several interacting features, or a design someone else implements |
| `minimal` | Low | One-page `design/product/one-pager.md` + stack pinned (its `## Build Order` section is the plan — no separate sprint plan) | Hackathons, prototypes, small scope, design already in your head |

**Default**: none of its own — `modes.workflow` follows `modes.rigor`. Unset on an unconfigured project: `modes.rigor` defaults to `minimal`, which resolves `review_mode` to `solo`. The same expansion resolves `workflow` to `minimal`.
**Set by**: `/settings` (explicitly); otherwise it follows `modes.rigor`, which
`/start` sets. When to raise rigor: `.claude/docs/settings-guidance.md`
§ 2. Archetype → rigor presets. **Locked to `project.yaml`** (not locally
overridable — divergence would change which artifacts must exist on disk).

> **Permissive, not restrictive.** `workflow` controls what is REQUIRED, not
> what is ALLOWED. Any skill can run at any tier. The setting changes what
> `gate-check` enforces and what completeness checks validate — never what the
> user can invoke.

> **`minimal` floor.** Even at minimal, a pinned stack (`stack.pinned_on` set)
> and a filled **`design/product/one-pager.md`** are required before code
> starts. The one-pager's **`## Build Order`** section is the plan: the
> Validation → Build gate's minimal floor is "`## Build Order` has at least one
> item", and there is no separate `/sprint-plan` step at this tier. Everything
> else can be skipped.
>
> Later gates keep floors of their own at every tier — tier reductions relax
> what must *exist*, never what must *work*: a smoke check report before
> Hardening; a release checklist with verdict GO, a quick (or full) security
> audit, a passing smoke check on the release candidate and no unresolved S1/S2
> bugs before Launch. A walking skeleton that was built must pass its validation
> at every tier.

> **The one-pager is a real artifact at `minimal`: `design/product/one-pager.md`.**
> `/brainstorm` writes it from the one-page template
> (`.claude/docs/templates/one-pager.md`) when the effective tier is `minimal`,
> in place of the full `design/product/product-brief.md` (from
> `.claude/docs/templates/product-brief.md`) it writes at `standard`/`full`. The
> two are distinct files for distinct tiers: any check, gate, or glob for the
> `minimal` product artifact must target **`design/product/one-pager.md`**;
> `product-brief.md` remains the `standard`/`full` brief.

---

## PRD Required Sections per Tier

The 11 contract sections of `.claude/docs/templates/prd.md`, in order: Overview,
Goals & Non-Goals, User Value, Functional Requirements, Business Rules &
Calculations, Edge Cases, Dependencies, Non-Functional Requirements,
Configuration & Flags, Success Metrics & Instrumentation, Acceptance Criteria.

> **Headings are exact contracts.** There are no alias headings. A section is
> present when its `##` heading matches the contract text — case-insensitive,
> as a prefix, with an optional numeric prefix (`## 3. ` or `## 3) `). That is
> the one regex `bash .claude/scripts/prd-structure-check.sh` and the commit
> hook share; skills that detect or validate section presence (`prd-review`,
> `gate-check`, `adopt`, `project-stage-detect`) use the script rather than
> their own pattern. Never translate a heading — the check stops finding it.

| Tier | Required PRD sections |
|------|----------------------|
| `full` | All 11 |
| `standard` | **8 required**: Overview, Goals & Non-Goals, Functional Requirements, Edge Cases, Dependencies, Non-Functional Requirements, Success Metrics & Instrumentation (at least one metric with baseline and target; event detail may be `TBD`), Acceptance Criteria. **Conditional**: Business Rules & Calculations — required when the feature defines any numeric or policy rule (prices, fees, limits, quotas, rate limits, eligibility thresholds, time windows, rounding); optional only when it defines none. The feature map `Category` column is a hint, not the test. **Advisory**: User Value, Configuration & Flags. |
| `minimal` | None — `design/product/one-pager.md` replaces PRDs. A PRD may still be authored voluntarily. |

> **Edge Cases is required at `standard`** — including failure modes: network
> loss, partial failure, concurrency, retries. Skipping it produces "what happens
> when the Toss Payments webhook arrives twice?" debt during implementation.

> **Design language is conditional below `full`.** At `standard` it is required
> only when a UI surface is configured, and then sections 1–5. At `full`, all 9
> sections are required (again only with a UI surface).
> `workflow_overrides.design_language_strict: true` forces all 9 at `standard`.

---

## `workflow_overrides`

This key holds two mechanisms with **different directional rules**. Read the one
you are using — conflating them is a known and easy mistake.

```yaml
workflow_overrides:
  # --- the three boolean FLAGS: additive, stricter-only ---
  edge_cases: false              # force Edge Cases required (no-op at standard/full; relevant for PRDs written voluntarily at minimal)
  config_flags: false            # force Configuration & Flags required (relevant at standard, no-op at full)
  design_language_strict: false  # force all 9 design-language sections (relevant at standard, no-op at full)

  # --- feature_overrides: replaces a tier, BOTH directions ---
  feature_overrides: {}          # per-feature tier overrides (see below)
```

**The three boolean flags are additive on top of the chosen `workflow` level —
they make requirements STRICTER, never looser.** Each one only ever forces a
requirement *on*; setting a flag cannot opt out of a requirement the tier
imposes. There is no value of `edge_cases`, `config_flags` or
`design_language_strict` that removes anything. The flags have no
`resolve_config` label: read them from `project.yaml` at run time
(`project.local.yaml` is never consulted for them).

**`feature_overrides` is not a flag and is not additive.** It *replaces* the
effective tier for one named feature, in **either** direction — see the next
section. A loosening override genuinely loosens: on a `full` project,
`feature_overrides.admin-console: minimal` drops that feature's required
sections to zero. That is the intended design (it is what makes "one trivial
internal feature inside a serious product" expressible), but it means an
override is **not** a safe no-op — do not leave one in place assuming the
stricter-only rule protects you.

### Per-feature overrides

```yaml
workflow_overrides:
  feature_overrides:
    payments: full            # payments PRD requires all 11 sections regardless of project workflow
    admin-console: minimal    # internal admin console needs no PRD (minimal = no required sections)
```

`feature_overrides` is a map of `prd-stem: workflow_level`. The named feature
uses the override tier; all other features use the project-level `workflow`.
A skill acting on a named feature resolves its effective tier via step 1 of the
resolution chain above.

---

## Effective-Tier Resolution Worked Example

Project has `modes.workflow: standard`, `workflow_overrides.feature_overrides.payments: full`.

- `/write-prd payments` → effective tier **full** → requires all 11 sections
- `/write-prd goals` → no override → effective tier **standard** → 8 sections +
  Business Rules & Calculations (goals defines a per-plan limit on active goals,
  so the conditional section is required)
- `/gate-check architecture` (Definition → Architecture) → requires the payments
  PRD at 11 sections AND every other MVP PRD at 8 (+ conditional) before passing

---

## Per-Skill Behavior (the working summary — sufficient at runtime)

**Authoring** — branch on the effective tier for required sections (and, for
`brainstorm`, for which product artifact is produced —
`design/product/one-pager.md` at `minimal` vs `design/product/product-brief.md`
at `standard`/`full`):
`brainstorm`, `write-prd`, `design-language`, `create-architecture`,
`ux-design`, `map-features`, `architecture-decision`, `api-design`,
`data-model`.

**Review/validation** — validate against the effective tier; missing
*required* sections block, missing *optional* sections warn:
`prd-review`, `review-all-prds`, `architecture-review`, `consistency-check`,
`feature-audit`.

**Gate enforcement** — `gate-check` uses a different artifact checklist per
stage per tier (the highest-visibility impact). Each gate's own checklist and
tier reductions live in `.claude/skills/gate-check/references/gate-<target>.md`
(named for the phase the gate leads into), and `/gate-check` loads only the one
gate it is running — that is the right place to look, not `effects-map.md`.

**Planning/implementation** — adjust artifact prerequisites:
`create-epics`, `create-stories`, `sprint-plan`, `dev-story`,
`story-readiness`, `story-done`, `qa-plan`, `regression-suite`,
`walking-skeleton` (validation item 5 binds at `standard`/`full` only).

**Support** — adjust "what's missing" expectations so optional docs aren't
flagged as gaps: `project-stage-detect`, `adopt`, `reverse-document`,
`propagate-prd-change`, `help`, `setup-stack` (which product artifact gives it
context).

---

## Workflow Change Mid-Project

When `workflow` changes via `/settings`, emit an informational note:

> "Workflow changed from [old] to [new]. Run `/project-stage-detect` to see
> which artifacts are now required or optional. No automatic migration —
> existing files stay in place."

No documents are auto-deleted, auto-generated, or blocked. The setting only
affects *new* enforcement going forward.

---

## Companion Settings

These are separate settings that compose with `workflow`. The summaries below
are what a skill needs at runtime; `effects-map.md` carries the exhaustive
per-skill tables for spec authors, and is not worth loading to apply a knob.

> **All four below are fronted by `modes.rigor`** (`docs.density`,
> `modes.story_granularity`, `qa.level`, `team.size` — along with `workflow` itself,
> and `modes.review_mode`, for six fronted knobs total). One question at `/start`
> sets all of them; setting any explicitly overrides just that one and leaves its
> siblings on the rigor level. No template, skill or onboarding step seeds any of
> the six into `project.yaml` — only `/settings` writes them, on request.
> `team.size` and `modes.review_mode` are the two that also stay overridable from
> `project.local.yaml` (they are personal-experience knobs, not on-disk artifacts).

- **`docs.density`** (`terse` | `balanced` | `thorough`) — `workflow` controls
  *which sections exist*; `density` controls *how deep each section goes*.
  `rigor` sets the two together; override `docs.density` alone to get
  `full` + `terse` = "all 11 sections, each compact."
- **`modes.story_granularity`** (`coarse` | `balanced` | `fine`) — how big
  each story is and how many per epic/sprint.
- **`qa.level`** (`minimal` | `standard` | `full`) — what test evidence is
  required to mark stories Done. Composes with `testing.strict`:
  `qa.level` = is evidence required; `testing.strict` = do failures block, per
  story type — `testing.strict.logic`, `testing.strict.integration`,
  `testing.strict.ui`, `testing.strict.e2e`, `testing.strict.config` (each
  `true` | `false`; unset = each skill applies its own default, and
  `/smoke-check` treats an unset `config` as blocking). Two floors ignore
  `qa.level`: the smoke report, and the migration dry-run log for any story whose
  `**Migration**` field is not `None`.
- **`team.size`** (`individual` | `small` | `studio`) — which agents are active by
  default. Different axis from workflow: workflow controls *what docs are
  required*, team.size controls *which agents exist to make them*.
