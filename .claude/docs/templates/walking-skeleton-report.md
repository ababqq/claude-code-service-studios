# Walking Skeleton Report: [Journey Name]

> **Verdict**: [VALIDATED | NOT VALIDATED | NOT ASSESSED]
> **Date**: [YYYY-MM-DD]
> **Journey**: [critical user journey, e.g. "Sign up with Kakao → create a savings goal → see it on the home screen"]
> **Journey Source**: [`docs/ops/slo.md` § Critical User Journeys | `design/prd/<feature>.md`]
> **Branch**: [feature branch, e.g. `feat/walking-skeleton-create-goal`]
> **Commit**: [SHA deployed to staging]
> **Staging URL**: [web and API base URLs; mobile internal build ID]
> **Elapsed**: [N working days, start → end]

<!-- Verdict rule: VALIDATED = every applicable item in ## Validation is YES.
     NOT VALIDATED = any applicable item is NO (gate-build then FAILS at every tier).
     NOT ASSESSED = an item could not be checked (Result "—", reason in Evidence).
     A NO outranks an unknown; an unknown outranks YES.
     When the PD-USER-VALIDATION gate ran, add its line to this header block:
     > **Product Director Review (PD-USER-VALIDATION)**: APPROVED [date] / CONCERNS (accepted) [date] / REVISED [date]
     When the review mode skipped it: [PD-USER-VALIDATION] skipped — Lean mode / — Solo mode -->

---

## Journey

[The one critical user journey this skeleton carries end to end, as numbered steps
through every configured layer. Thinnest possible: one screen per step, the happy
path plus one error path, no polish.]

1. [Step — surface — screen or operation — e.g. "web · `/signup` · Kakao OAuth callback creates the user"]
2. [Step — e.g. "web · `/goals/new` → `POST /v1/goals` → `goals` row in PostgreSQL"]
3. [Step — e.g. "web · `/` lists the goal from `GET /v1/goals`"]

### Scope

- **In**: [layers and components the journey crosses]
- **Deliberately stubbed**: [e.g. "payment provider sandbox not wired — out of the journey"]
- **Cut from the original scope**: [what was dropped to keep the path thin, and why]

---

## Layers Touched

| Layer | Surface | Code root | Framework (pinned version) | What was built | Engineer |
|-------|---------|-----------|----------------------------|----------------|----------|
| web | web | `apps/web` | [Next.js 15.x] | [sign-up page, goal form, home list] | frontend-engineer |
| mobile | ios, android | `apps/mobile` | [React Native (Expo) 0.xx] | [or "not in this skeleton — reason"] | mobile-engineer |
| backend | api | `apps/api` | [NestJS 11.x] | [`POST /v1/goals`, `GET /v1/goals`, `/healthz`] | backend-engineer |
| data | — | `apps/api/prisma/migrations` | [PostgreSQL 16] | [`users`, `goals` tables — Expand-only migration] | backend-engineer |
| cloud | — | `infra` | [AWS / Terraform 1.x] | [staging service, database, secrets wiring] | devops-engineer |

**API contract operations exercised**: [`POST /v1/goals`, `GET /v1/goals` in `docs/api/openapi.yaml`]
**Feature flag**: [`goals.v2-progress-ring` — provider, default off]
**Tests added**: [unit / contract / E2E test paths]

---

## Pipeline & Deploy

| Item | Value |
|------|-------|
| CI workflow | [`.github/workflows/ci.yml` — jobs lint, typecheck, test, e2e] |
| Deploy workflow / job | [e.g. `deploy-staging` job, run #[N]] |
| Pipeline run | [URL or run ID] |
| Artifact | [image digest / build ID / web deployment ID] |
| Mobile build | [internal distribution build ID pointing at staging — or "not in this skeleton"] |
| Migrations on staging | [Expand applied by the pipeline at [time] — or "none"] |
| Deployed by | [pipeline — never "by hand"] |
| Rollback method | [e.g. redeploy previous artifact via the pipeline / `kubectl rollout undo` / promote previous deployment] |

**Rollback rehearsal**:

| Step | Time (UTC / KST) | Result |
|------|------------------|--------|
| Rolled back to [previous artifact] | [hh:mm / hh:mm] | [health 200, journey still works / broke at …] |
| Redeployed [current artifact] | [hh:mm / hh:mm] | [health 200, journey passes] |

---

## Observability

| Signal | Where | Evidence |
|--------|-------|----------|
| Health endpoint | [`GET https://api.staging…/healthz` → 200 with version] | [response / link] |
| Logs | [tool + query, e.g. CloudWatch Logs Insights by correlation ID] | [link] |
| Metric or trace | [e.g. request rate / p95 for `POST /v1/goals`; one trace UI → API → DB] | [link] |
| Error tracking | [e.g. Sentry project for web and api — or "not yet"] | [link] |
| Dashboards / alerts created | [names — or "none yet — follow-up"] | [link] |

---

## Validation

The five walking-skeleton items of the Validation → Build gate. Result is `YES`, `NO` or
`N/A`; an item that could not be checked has Result `—` and its Evidence starts with
`NOT ASSESSED — <reason>`.

| # | Item | Result | Evidence |
|---|------|--------|----------|
| 1 | Deployed to staging by the CI/CD pipeline (not by hand) | [YES / NO] | [pipeline run] |
| 2 | One critical user journey passes end to end on staging (UI → API → DB) | [YES / NO] | [E2E run / captures in `production/qa/evidence/…`] |
| 3 | Health endpoint, logs and at least one metric/trace visible in the observability tool | [YES / NO] | [links] |
| 4 | The staging deploy was rolled back once and redeployed successfully | [YES / NO] | [rollback rehearsal above] |
| 5 | A feature flag was toggled on staging without a redeploy — standard and full only | [YES / NO / N/A] | [flag, provider, before/after observation — N/A only at `minimal`] |

### Usability Session (optional)

[Only when a usability session ran on the skeleton: participants (segment, device),
tasks, outcome, link to the `/usability-report` file, and the PD-USER-VALIDATION
outcome. Otherwise: "No usability session on the skeleton."]

---

## Follow-ups

- **Gaps to close** (every NO or `—` above): [item — owner — how it will be fixed]
- **Architecture surprises**: [assumption that broke — ADR to write or revise via `/architecture-decision`]
- **Stories to create**: [work the skeleton exposed — via `/create-stories`]
- **Tech debt taken on deliberately**: [what and why]

### Effort & Velocity

| Day | Completed |
|-----|-----------|
| Day 1 | [what was built] |
| Day 2 | [what was built] |
| … | … |

[What the elapsed time says about the real delivery rate — feed it into `/sprint-plan`.]

---

> *Walking-skeleton code is production code: it lives on a feature branch in the
> resolved code roots, follows the control manifest and is reviewed and merged like any
> other change. It is never a throwaway prototype and never lives under `prototypes/`.*
