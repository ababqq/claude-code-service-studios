# Project Stage Analysis Report

> **Verdict**: [PASS | CONCERNS | FAIL | NOT ASSESSED]

**Generated**: [DATE]
**Stage**: [Discovery | Definition | Architecture | Validation | Build | Hardening | Launch]
**Stage Source**: [project.yaml | estimated] — `bash .claude/scripts/stage-estimate.sh` printed `ESTIMATE: [value]` because [EVIDENCE line]
**Analysis Scope**: [Full project | Specific role: pm / designer / frontend / backend / mobile / sre / security / data]

---

## Executive Summary

[1-2 paragraph overview of project state, primary gaps, and recommended priority]

**Current Focus**: [What the project is actively working on]
**Blocking Issues**: [Critical gaps preventing progress]
**Next Phase Gate**: [`/gate-check <next-phase>` — or "none: Launch is terminal"]

---

## Completeness Overview

Every area reports what was found on disk. An area that could not be checked says
`NOT CHECKED — <reason>`; it never reads as empty-and-fine.

### Product
- **Status**: [complete / partial / missing / NOT CHECKED — reason]
- **Found**:
  - Product brief: [`design/product/product-brief.md` | one-pager `design/product/one-pager.md` | missing]
  - Feature map: [`design/product/feature-map.md` — N features, N MVP | missing]
  - PRDs: [N] in `design/prd/` ([N] Approved, [N] Drafting / In Review, [N] Implemented)
  - Tracking plan: [`design/product/tracking-plan.md` | missing]
  - Concept prototypes: [N] in `prototypes/` ([N] with `REPORT.md`, [N] spikes with `SPIKE-NOTE.md`)
- **Key Gaps**:
  - [ ] [Missing doc 1 + why it matters]
  - [ ] [Missing doc 2 + why it matters]

### UX & Design Language
- **Status**: [complete / partial / missing / N/A — no UI surface / NOT CHECKED — reason]
- **Found**:
  - Design language: [`design/brand/design-language.md` — sections present | missing]
  - UX specs: [N] in `design/ux/` (app shell [yes/no], interaction patterns [yes/no])
  - UX reviews: [N] in `design/ux/reviews/`
  - Accessibility requirements: [`design/accessibility-requirements.md` — target | missing]
- **Key Gaps**:
  - [ ] [Missing spec or review + impact]

### Code
- **Status**: [per root below / NOT CHECKED — no code root resolved (set stack.layers.<layer>.root via /setup-stack)]
- **Roots** (from `resolve_code_roots`):

  | Root | Layer | Source | Source files | Notes |
  |------|-------|--------|--------------|-------|
  | `[apps/web]` | [web] | [project.yaml / missing / workspace / detected] | [N] | [brief status] |

  [WARN: undeclared code roots: <dirs> — declare them with /setup-stack]
- **Major Features Identified**:
  - ✅ [Feature 1] (`[root]/[path]/`) — [brief status]
  - ⚠️  [Feature 2] (`[root]/[path]/`) — [issue or incomplete]
- **Key Gaps**:
  - [ ] [Missing feature implementation + impact]

### Architecture & API
- **Status**: [complete / partial / missing / NOT CHECKED — reason]
- **Found**:
  - Architecture: [`docs/architecture/architecture.md` | missing]
  - ADRs: [N] in `docs/architecture/` ([N] Accepted, [N] Proposed)
  - Control manifest: [`docs/architecture/control-manifest.md` | missing]
  - Tech radar: [`docs/architecture/tech-radar.md` | missing]
  - API contract: [`docs/api/openapi.yaml` / `schema.graphql` / `<service>.proto` / `asyncapi.yaml` | missing | N/A — no backend]
- **Coverage**:
  - ✅ [Decision area 1] — documented
  - ⚠️  [Decision area 2] — undocumented but implemented
  - ❌ [Decision area 3] — neither documented nor decided
- **Key Gaps**:
  - [ ] [Missing ADR or contract + why it's needed]

### Data
- **Status**: [complete / partial / missing / N/A — no data layer / NOT CHECKED — reason]
- **Found**:
  - Data model: [`docs/data/data-model.md` | missing]
  - Migration plans: [N] in `docs/data/migrations/` (phases pending / applied)
- **Key Gaps**:
  - [ ] [Missing classification, retention or migration plan + impact]

### Security & Privacy
- **Status**: [complete / partial / missing / NOT CHECKED — reason]
- **Found**:
  - Threat model: [`docs/security/threat-model.md` | missing]
  - Security audits: [N] in `production/security/` (latest mode and verdict)
  - Personal data: [`privacy.handles_pii` value | unset — ask] · regions: [`compliance.regions` value | unset — ask]
- **Key Gaps**:
  - [ ] [Missing review or control + risk]

### Ops & Observability
- **Status**: [complete / partial / missing / NOT CHECKED — reason]
- **Found**:
  - SLOs: [`docs/ops/slo.md` — critical user journeys defined yes/no | missing]
  - Runbooks: [N] in `docs/ops/runbooks/`
  - Incidents: [N] in `production/incidents/` ([N] with postmortems)
- **Key Gaps**:
  - [ ] [Missing SLO, alert or runbook + impact]

### Tests & CI
- **Status**: [complete / partial / missing / NOT CHECKED — reason]
- **Found**:
  - Test files: [N] (where `testing.patterns` says tests live, else `tests/**`)
  - Suites: unit [yes/no] · integration [yes/no] · contract [yes/no] · E2E [yes/no] · load [yes/no]
  - CI workflow: [`.github/workflows/ci.yml` | other | missing]
  - Latest smoke check: [`production/qa/smoke-*.md` verdict | none]
- **Key Gaps**:
  - [ ] [Missing test area + risk]

### Release
- **Status**: [complete / partial / missing / N/A — pre-Build / NOT CHECKED — reason]
- **Found**:
  - Epics and stories: [N] epics in `production/epics/`, [N] stories
  - Sprints: [N] plans in `production/sprints/`; `production/sprint-status.yaml` [present | missing]
  - Milestones: [N] definitions in `production/milestones/`
  - Walking skeleton: [`production/walking-skeleton/report-*.md` — verdict | missing]
  - Releases: [N] in `production/releases/` (latest version and its `release-record.md` verdict)
- **Key Gaps**:
  - [ ] [Missing delivery or release artifact + impact]

---

## Stage Classification Rationale

**Why [Stage]?**

[Explain why the project is classified at this stage based on indicators found. When
the configured `project.stage` and the estimate disagree, say both and which
artifacts cause the difference.]

**Indicators for this stage**:
- [Indicator 1 that matches this stage]
- [Indicator 2 that matches this stage]

**Next stage requirements** (from `.claude/skills/gate-check/references/gate-<next-phase>.md`):
- [ ] [Requirement 1 to reach next stage]
- [ ] [Requirement 2 to reach next stage]
- [ ] [Requirement 3 to reach next stage]

---

## Gaps Identified (with Clarifying Questions)

### Critical Gaps (block progress)

1. **[Gap Name]**
   - **Impact**: [Why this blocks progress]
   - **Question**: [Clarifying question before assuming solution]
   - **Suggested Action**: [What could be done, pending clarification]

### Important Gaps (affect quality/velocity)

2. **[Gap Name]**
   - **Impact**: [Why this matters]
   - **Question**: [Clarifying question]
   - **Suggested Action**: [Proposed solution]

### Nice-to-Have Gaps (hardening/best practices)

3. **[Gap Name]**
   - **Impact**: [Minor but valuable]
   - **Question**: [Clarifying question]
   - **Suggested Action**: [Optional improvement]

---

## Recommended Next Steps

### Immediate Priority (Do First)
1. **[Action 1]** — [Why it's priority 1]
   - Suggested skill: `/[skill-name]` or manual work
   - Estimated effort: [S/M/L]

2. **[Action 2]** — [Why it's priority 2]
   - Suggested skill: `/[skill-name]`
   - Estimated effort: [S/M/L]

### Short-Term (This Sprint/Week)
3. **[Action 3]** — [Why it's important soon]
4. **[Action 4]** — [Why it's important soon]

### Medium-Term (Next Milestone)
5. **[Action 5]** — [Future need]
6. **[Action 6]** — [Future need]

---

## Role-Specific Recommendations

[If role filter was used, provide role-specific guidance]

### For [Role]:
- **Focus areas**: [What this role should prioritize]
- **Blockers**: [What's blocking this role's work]
- **Next tasks**:
  1. [Task 1]
  2. [Task 2]

---

## Follow-Up Skills to Run

Based on gaps identified, consider running:

- `/reverse-document <prd|architecture|brief> <path>` — [For which gap]
- `/architecture-decision` — [For which gap]
- `/api-design` or `/data-model` — [If the contract or data model is missing]
- `/sprint-plan` — [If delivery planning is missing]
- `/milestone-review` — [If approaching a milestone date]
- `/onboard <role>` — [If a new contributor is joining]
- `/adopt` — [If existing artifacts need auditing against the framework's contracts]
- `/gate-check <next-phase>` — [When the next stage requirements look met]

---

## Appendix: File Counts by Directory

```
design/
  product/       [N] files
  prd/           [N] PRDs
  ux/            [N] specs
  brand/         [N] files

[code root]/     [N] source files   (one line per resolved root)

docs/
  architecture/  [N] ADRs
  api/           [N] contract files
  data/          [N] files
  ops/           [N] files (runbooks: [N])

production/
  epics/         [N] epics, [N] stories
  sprints/       [N] plans
  milestones/    [N] definitions
  qa/            [N] reports
  releases/      [N] versions

tests/           [N] test files
prototypes/      [N] directories
```

---

**End of Report**

*Generated by `/project-stage-detect` skill*
