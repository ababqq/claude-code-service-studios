---
name: project-stage-detect
description: "Where are we? Stage (via stage-estimate.sh), gaps and next steps."
argument-hint: "[optional: role filter — pm | designer | frontend | backend | mobile | sre | security | data]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Write, Bash(bash "*/.claude/skills/project-stage-detect/../../hooks/yaml-helper.sh" resolve_config *)
model: haiku
# Read-only diagnostic skill — no specialist agent delegation needed
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys workflow,automation,surfaces,compliance,distribution,stack,code_roots`

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

# Project Stage Detection

This skill scans your project to determine its current development stage, completeness
of artifacts, and gaps that need attention. It's especially useful when:
- Starting with an existing product or codebase
- Onboarding to a codebase
- Checking what's missing before a milestone (MVP, Private Beta, Public Beta, GA)
- Understanding "where are we?"

**Output:** `production/project-stage-report-YYYY-MM-DD.md` (after approval, step 6).

---

## Workflow

> **Resolve the tier — do not assume it.** Saying "surface gaps per the **resolved** workflow
> tier" without resolving it — no bootstrap, no helper call — leaves
> the tier as whatever the model assumed. The tier decides what counts as a gap
> at all: at `full` every missing doc is one; at `minimal` none of them are,
> because a one-pager plus a pinned stack is the normal state and code is the
> expected next step. Guessing high tells a hackathon project it is missing PRDs,
> a design language and ADRs — the exact "process feels mismatched to my project"
> experience `modes.rigor` exists to prevent. A missing bootstrap is invisible to a
> static read — the config block simply does not render — so verify it by running.

**`workflow`** (per `.claude/docs/workflow-modes.md`). The tier governs
which absent documents count as gaps (step 3) — below `full`, optional docs are
not flagged.

**`platform.surfaces`, `stack`, `compliance`, `release.distribution`** — decide
the `when=` conditions of catalog steps (step 1). **`code_roots`** — the roots the
Code area scans. `localization.locales` has no config-block label: read it from
`project.yaml` with Read (absent key ⇒ unset).

### 1. Scan Key Directories

**Start with the two deterministic passes.** The first answers "what stage does
the tree look like"; the second answers "what exists" for every catalogued
artifact, in one call each:

```
Bash: bash .claude/scripts/stage-estimate.sh
Bash: bash .claude/scripts/artifact-check.sh
```

`stage-estimate.sh` prints four lines — `STAGE:`, `SOURCE:` (`project.yaml` or
`estimated`), `ESTIMATE:` and `EVIDENCE:`. Keep all four for step 2; they are the
project's single stage ladder (the status line, `/help` and `/gate-check` read the
same script), so never replace them with a ladder of your own.

`artifact-check.sh` with no `--phase` reports every phase, so a single call covers
the whole project: per step, `PRESENT` / `ABSENT` / `SHORT` (with `count=` and
`min=`) / `PATTERN_MISS` / `NO_CHECK`, plus `tiers=` and `when=`. Use it instead of
hand-globbing each artifact below, and treat its `NO_CHECK` total as the honest
bound on what existence checks can tell you.

It reports observations only — this skill still decides what those observations
imply, and it applies `tiers=` and `when=` to every `required=true` step:

- **Tier** — `tiers=all`, or a list containing the resolved `workflow` ⇒ the tier
  requires it; otherwise report the step as **OPTIONAL** "(required at <tiers>)".
- **Condition** (only when the tier requires it) — `when=always` ⇒ REQUIRED. For
  the others: `ui` = `platform.surfaces` contains `web`, `ios` or `android`;
  `backend` = the `stack` line shows a `backend=` or `data=` layer, or
  `platform.surfaces` contains `api`; `pii` = `compliance` shows `handles_pii=true`;
  `stores` = `release.distribution` is `stores` or `web+stores`; `multi-locale` =
  `localization.locales` has two or more entries. Known true ⇒ REQUIRED. Known
  false (every input set, none true) ⇒ **OPTIONAL** "(required when <cond>)".
  Unknown (an input it depends on is unset) ⇒ **REQUIRED** "(when <cond> —
  unknown; run /setup-stack)". Unset is not false; a layer listed under `unset=`
  on a configured `stack` line is known to be absent, not unknown.
- A step carrying `tiers_error=` or `when_error=` is a catalog defect — name it in
  the report instead of trusting that field.

Then analyze what the scripts cannot: content quality, counts they do not track,
and the judgement calls. Cover every area below; an area that could not be checked
is written `NOT CHECKED — <reason>`, never left out.

**Product** (`design/product/`, `design/prd/`):
- Product brief (`design/product/product-brief.md`) or, at `minimal`, the one-pager
  (`design/product/one-pager.md`)
- Feature map (`design/product/feature-map.md`): count features per Tier (MVP /
  Beta / GA / Later) and per Status; compare with the PRDs present
- PRDs: count `design/prd/*.md`; section presence per PRD with
  `bash .claude/scripts/prd-structure-check.sh` (it reports presence only — the
  tier decides which absences matter); PRD `> **Status**:` values
- Tracking plan (`design/product/tracking-plan.md`), pricing model
  (`design/product/pricing-model.md`) when the product charges
- Concept prototypes: directories under `prototypes/` — those with `REPORT.md`
  (concept) or `SPIKE-NOTE.md` (spike) versus neither

**UX & Design Language** (`design/ux/`, `design/brand/`) — `N/A — no UI surface`
only when `platform.surfaces` is set and has no `web`, `ios` or `android`:
- Design language (`design/brand/design-language.md`) and its sections
- UX specs in `design/ux/`, the app shell (`design/ux/app-shell.md`) and interaction
  patterns (`design/ux/interaction-patterns.md`); reviews in `design/ux/reviews/`
- Accessibility requirements (`design/accessibility-requirements.md`) and its
  `> **Target**:` line

**Code** (per resolved root — the `code_roots` line):
- For each root, count source files with Glob using the extensions the
  `code_roots` line prints, skipping dependency and build output (`node_modules`,
  `.next`, `dist`, `build`, `Pods`, `.gradle`, `.venv`, `vendor`, `target`)
- Identify major features (directories with 5+ files) and common module layouts
  (`modules/`, `features/`, `domain/`, `api/`, `components/`, `screens/`)
- Estimate lines of code (rough scale)
- Undeclared roots (`undeclared=` on the `code_roots` line) are scanned too and
  reported with the line `WARN: undeclared code roots: <dirs> — declare them with /setup-stack`
- `code_roots: unresolved` ⇒ the area is
  `NOT CHECKED — no code root resolved (set stack.layers.<layer>.root via /setup-stack)`;
  never fall back to scanning `src/` or the whole repo

**Architecture & API** (`docs/architecture/`, `docs/api/`):
- `docs/architecture/architecture.md`; count ADRs (`docs/architecture/adr-*.md`)
  and their `## Status` values (Accepted / Proposed)
- Control manifest, tech radar (`docs/architecture/tech-radar.md`), traceability
  (`docs/architecture/requirements-traceability.md`)
- API contract (`docs/api/openapi*.yaml`, `docs/api/*.graphql`, `docs/api/*.proto`,
  `docs/api/asyncapi*.yaml`) and change records in `docs/api/changes/`

**Data** (`docs/data/`):
- Data model (`docs/data/data-model.md`); migration plans in `docs/data/migrations/`
  compared with the files under the `data=` root of the `code_roots` line

**Security & Privacy**:
- Threat model (`docs/security/threat-model.md`); audits in `production/security/`
  (latest mode and verdict line)
- `handles_pii` and `regions` from the `compliance` line — unset parts are reported
  as "unset — ask", never as "no personal data"

**Ops & Observability** (`docs/ops/`, `production/incidents/`):
- SLO doc (`docs/ops/slo.md`) and its `## Critical User Journeys`
- Runbooks in `docs/ops/runbooks/`; incidents and postmortems in `production/incidents/`

**Tests & CI**:
- Count test files (where `testing.patterns` in `project.yaml` says tests live, else
  `tests/**`); which suites exist (unit, integration, contract, E2E, load)
- CI workflow (`.github/workflows/*.yml` or another CI file the catalog lists)
- Latest smoke report (`production/qa/smoke-*.md`) and its verdict line

**Release** (`production/`):
- Epics and stories (`production/epics/`), sprint plans (`production/sprints/`),
  `production/sprint-status.yaml`, milestone definitions (`production/milestones/`)
- Walking skeleton report (`production/walking-skeleton/report-*.md`)
- Releases (`production/releases/<version>/`) and their `release-record.md`
  verdicts

### 2. Classify Project Stage

Take the stage from `stage-estimate.sh` (step 1): `STAGE` is `project.stage` from
`project.yaml` when it is set and valid (`SOURCE: project.yaml`), otherwise the
estimate (`SOURCE: estimated`). The ladder itself lives in the script header — do
not restate or re-derive it here.

> **Always compare, even when a stage is configured.** The script computes
> `ESTIMATE` even when `project.stage` is set. The configured value is authoritative
> for what the stage *is*; it is not evidence that the artifacts support it. Report
> both, and when they disagree say so explicitly:
>
> > "Configured stage: **Launch**. Observed artifacts indicate
> > **Validation** (epics and a first sprint plan, no story in progress, 2 source
> > files, no release checklist, no release record). These disagree — the
> > configured stage may be stale, or work exists outside this repo."
>
> Reading config and reporting it back is not detection. This skill's own
> description promises "where are we?", and a stage detector that cannot
> contradict its input is the one thing it must never be.

Quote the `EVIDENCE:` clause in the report's `**Stage Source**` line; when the
clause says a check was skipped (for example the source count, because no code
root resolved), carry that into the report too.

### 3. Collaborative Gap Identification

**Surface gaps per the resolved workflow tier:**
- **`full`** — flag every missing doc type (PRDs, design language, UX specs, ADRs,
  API contract, data model, threat model, SLOs, runbooks) as a gap.
- **`standard`** — flag only required docs: missing PRDs for built MVP features,
  missing critical (Foundation-layer) ADRs, and the steps `artifact-check.sh`
  reports as REQUIRED after the tier and condition rules of step 1. Do NOT flag an
  absent design language unless UI stories exist, and do NOT flag non-core UX specs.
- **`minimal`** — a `design/product/one-pager.md` + a pinned stack is the normal
  state. Do NOT flag absent PRDs, design language, UX specs, or ADRs as gaps; the
  expected next step is code (the one-pager's `## Build Order` is the plan).

A step reported OPTIONAL "(required at …)" or "(required when …)" is never a gap.
A step reported REQUIRED "(when … — unknown; run /setup-stack)" is a gap *and* a
configuration question — ask it.

**DO NOT** just list missing files. Instead, **ask clarifying questions** (only
for gaps the tier above says to surface):

- "I see payment code (`apps/api/src/modules/payments/`) but no `design/prd/payments.md`. Was this built first, or should we reverse-document it?"
- "You have 15 ADRs but no architecture overview. Should I create one to help new contributors?"
- "`apps/api` exists but there is no API contract in `docs/api/`. Is the contract kept somewhere else, or should we run `/api-design`?"
- "No sprint plans in `production/sprints/`. Are you tracking work elsewhere (Jira, Linear, GitHub Projects)?"
- "I found a product brief but no feature map. Have you decomposed the product into features yet, or should we run `/map-features`?"
- "`prototypes/` has 3 directories with neither `REPORT.md` nor `SPIKE-NOTE.md`. Were these experiments, or do they need a report?"
- "`platform.surfaces` is unset, so I can't tell whether the UX steps apply. Which surfaces ship — web, iOS, Android, a public API?"

### 4. Generate Stage Report

Use template: `.claude/docs/templates/project-stage-report.md` — keep its headings
and bold field labels exactly; write the body in the user's conversation language.

**Verdict line.** Directly under the report's H1 and one blank line, write
`> **Verdict**: <TOKEN>` — the stage confidence:
- `PASS` — clearly detected: the configured stage (or the estimate) and the
  artifacts agree, and no required gap blocks the current phase
- `CONCERNS` — ambiguous signals: the configured stage and the estimate disagree,
  or conditions are unknown because settings are unset
- `FAIL` — critical gaps block progress in the current phase
- `NOT ASSESSED` — the scans could not run (a script errored or the catalog did
  not parse), so no stage can be stated with any confidence

Precedence when several apply: **FAIL > CONCERNS > NOT ASSESSED > PASS**.

**Report structure** (the template carries the full form):
```markdown
# Project Stage Analysis Report

> **Verdict**: [PASS | CONCERNS | FAIL | NOT ASSESSED]

**Generated**: [date]
**Stage**: [Discovery | Definition | Architecture | Validation | Build | Hardening | Launch]
**Stage Source**: [project.yaml | estimated] — [EVIDENCE clause]

## Completeness Overview
### Product
### UX & Design Language
### Code
### Architecture & API
### Data
### Security & Privacy
### Ops & Observability
### Tests & CI
### Release

## Gaps Identified (with Clarifying Questions)
1. [Gap description + clarifying question]
2. [Gap description + clarifying question]

## Recommended Next Steps
[Priority-ordered list based on stage and role]
```

### 5. Role-Filtered Recommendations (Optional)

If user provided a role argument (e.g., `/project-stage-detect backend`):

**pm**:
- Focus on brief, feature map, PRD completeness and success metrics
- Tracking plan and PRD ↔ implementation gaps

**designer**:
- Focus on design language, UX specs, app shell, accessibility requirements
- Usability evidence (`production/qa/usability/`) and prototype reports

**frontend** / **mobile**:
- Focus on the web or mobile roots, UX specs for built screens, API contract
  coverage of the screens, E2E and visual evidence

**backend**:
- Focus on architecture docs, ADRs, API contract, data model and migration plans,
  contract and integration tests

**sre**:
- Focus on SLOs, dashboards and alerts, runbooks, CI/CD, rollout and release records

**security**:
- Focus on threat model, security audits, PII handling and regional compliance

**data**:
- Focus on tracking plan, event instrumentation, data model ownership and retention

**General** (no role):
- Holistic view of all gaps
- Highest-priority items across domains

### 6. Request Approval Before Writing

**Collaborative protocol**:
```
I've analyzed your project. Here's what I found:

[Show summary]

Gaps identified:
1. [Gap 1 + question]
2. [Gap 2 + question]

Recommended next steps:
- [Priority 1]
- [Priority 2]
- [Priority 3]

May I write this to `production/project-stage-report-YYYY-MM-DD.md`?
```

Wait for user approval before creating the file.

---

## Example Usage

```bash
# General project analysis
/project-stage-detect

# Backend-focused analysis
/project-stage-detect backend

# Designer-focused analysis
/project-stage-detect designer
```

---

## Follow-Up Actions

After generating the report, suggest relevant next steps — **only for gaps the
resolved workflow tier surfaces** (step 3). At `standard`/`minimal`, do not
suggest authoring optional docs (e.g. don't suggest `/reverse-document` for an
absent PRD at `minimal`, where code is the expected next step):

- **Brief exists but no feature map?** → `/map-features` to decompose into features
- **Missing PRDs for built features?** → `/reverse-document prd <root>/<module>`
- **Missing architecture docs?** → `/architecture-decision` or `/reverse-document architecture <root>`
- **Backend without an API contract or data model?** → `/api-design` or `/data-model`
- **Prototypes without a report?** → `/prototype report prototypes/<name>`
- **No sprint plan?** → `/sprint-plan`
- **Approaching milestone?** → `/milestone-review`
- **Existing artifacts that may not match the framework's contracts?** → `/adopt`
- **Next stage requirements look met?** → `/gate-check <next-phase>` (the target
  phase — e.g. `/gate-check build` from Validation; none after Launch)

---

## Collaborative Protocol

This skill follows the collaborative design principle:

1. **Question First**: Ask about gaps, don't assume
2. **Present Options**: "Should I create X, or is it tracked elsewhere?"
3. **User Decides**: Wait for direction
4. **Show Draft**: Display report summary
5. **Get Approval**: "May I write this to `production/project-stage-report-YYYY-MM-DD.md`?"

**Never** silently write files. **Always** show findings and ask before creating artifacts.
