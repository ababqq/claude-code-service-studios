# Release Checklist: [version]

> **Verdict**: [GO | NO-GO | NOT ASSESSED]

**Release candidate**: [tag `v[version]` · commit `[short SHA]` · CI run [link or ID]]
**Surfaces**: [web, ios, android, api] (`platform.surfaces`)
**Distribution**: [web | stores | web+stores | enterprise | internal] (`release.distribution`)
**Regions**: [kr, eu, us | none] (`compliance.regions`)
**Locales**: [ko-KR, en-US] (`localization.locales`)
**Stage**: [Hardening | Launch | …] · **Rigor**: [minimal | standard | full] · **Release type**: [first public release | subsequent release]
**Prepared**: [YYYY-MM-DD] by `/release-checklist`
**Previous release**: [`production/releases/[previous-version]/release-record.md` | none]

<!--
How to fill this template (read by /release-checklist; delete these comments in the written file):
- The verdict line stays directly under the H1. Precedence: NO-GO > NOT ASSESSED > GO.
  GO needs every in-scope item checked or explicitly accepted with a named owner.
- Keep every `##` heading. A block whose condition is false keeps its heading and carries exactly one
  omission line (the bracketed line under Web, Stores and Regions), so the reader sees it was
  considered. Never delete a block silently.
- An item that could not be checked is written `NOT ASSESSED — [reason]`, never left unticked and never
  ticked. An unticked box with no note is not allowed in the written file.
- Every count states its denominator: "scanned 37 bug files: 0 unresolved S1, 1 unresolved S2".
- Record names and presence of config and secrets only — never a secret value.
-->

---

## Scope

What ships in this version. Everything below is scoped to this list.

| Item | Path | Surface |
|---|---|---|
| PRD | `design/prd/[feature-slug].md` | [web, ios, android, api] |
| Story | `production/epics/[epic-slug]/story-NNN-[slug].md` (status `done`) | [web] |
| Quick spec | `design/quick-specs/[kebab-title]-YYYY-MM-DD.md` | [api] |
| Bug fix | `production/qa/bugs/BUG-NNNN.md` (`Verified Fixed`) | [ios] |

**Changelog section**: `docs/CHANGELOG.md` `## [x.y.z] - YYYY-MM-DD` [present | absent — run `/changelog [version]`]
**Deferred from this version**: [items moved to a later version, with the reason]

---

## Build & CI Artifact

- [ ] Release candidate built by the CI pipeline from the tagged commit — not from a workstation
- [ ] CI green on that commit: lint, typecheck, unit, integration, contract, E2E ([run link])
- [ ] Artifacts identified immutably — container image digest `sha256:[…]` · web build ID `[…]` ·
      iOS build `[CFBundleVersion]` · Android `versionCode` `[n]`
- [ ] The artifact verified on staging is the one promoted to production (promote, never rebuild)
- [ ] Dependency changes since the previous release reviewed (lockfile diff); no new Critical/High
      advisories open — latest security audit `production/security/security-audit-[mode]-YYYY-MM-DD.md`
      verdict [PASS | CONCERNS | FAIL | NOT ASSESSED]
- [ ] Debug menus, verbose logging, test endpoints and staging API hosts disabled in the production build
- [ ] Source maps / dSYMs / R8 mapping files uploaded to error tracking for this build
- [ ] (enterprise) Private distribution channel prepared — Apple Business Manager custom app, Managed
      Google Play private app, or the customer-hosted package — and customer admins told the change window
- [ ] (internal) Internal track only — TestFlight internal group / Play internal testing / internal
      deploy target; no customer-facing communication

<!-- minimal rigor with no CI workflow in the repo (/test-setup is optional at minimal): the first two items read
     `N/A — CI workflow not configured (optional at minimal); built from [where]` and are not scored; the tag,
     commit and artifact IDs are still recorded. A CI workflow that exists but did not build this candidate
     is a blocker at every tier. -->

### Verification of this candidate

- [ ] Smoke check on the release candidate: `production/qa/smoke-YYYY-MM-DD.md` verdict
      [PASS | PASS WITH WARNINGS | FAIL | NOT ASSESSED], environment [staging | local]
- [ ] QA sign-off: `production/qa/qa-signoff-[sprint]-YYYY-MM-DD.md` verdict [APPROVED | APPROVED WITH CONDITIONS | …]
      — at `minimal`, when none exists: `N/A — QA sign-off not required at minimal`
- [ ] Unresolved bugs — scanned [N] files in `production/qa/bugs/`: [a] unresolved S1, [b] unresolved S2
      (unresolved = `**Status**:` `Open`, `In Progress` or `Fixed — Pending Verification`)
  - Zero unresolved S1 — no exceptions
  - Zero unresolved S2 in the journeys this release touches; any other S2 is listed below with an owner
    and a target date, accepted by the user

| Bug | Severity | Journey affected | Why it may ship | Owner | Target date | Accepted by |
|---|---|---|---|---|---|---|
| BUG-NNNN | S2-Major | [journey] | [outside this release's changes — reason] | [role] | YYYY-MM-DD | [user] |

---

## Database Migrations

[None in this release — no story in Scope has `**Migration**` other than None.]

| Plan | Phases shipping in this release | Status per phase (`pending` / `applied-staging` / `applied-production`) | Plan verdict | Lock & duration budget met on staging | Rollback per phase |
|---|---|---|---|---|---|
| `docs/data/migrations/NNNN-[slug].md` | [Expand / Migrate / Contract] | Expand `applied-staging` · Migrate `pending` · Contract `pending` | [SAFE / RISKY — MITIGATION REQUIRED / UNSAFE / NOT ASSESSED] | [yes — measured [n] s on staging-sized data] | [yes] |

- [ ] Expand phases applied on staging and scheduled for production **before** the deploy that needs them
- [ ] No Contract phase ships with, or ahead of, code that still reads the old shape — including every
      supported mobile app version (see the Rollback Path compatibility window)
- [ ] Backfills are idempotent, batched and resumable; runtime measured on staging-sized data
- [ ] A restore point is taken before any destructive step; its ID is recorded in the release record
- [ ] Each production migration run has a named human owner and a scheduled time
- [ ] Dry-run evidence retained under `production/qa/evidence/` (never in `production/session-logs/`)

---

## Feature Flags

[None in this release — no story in Scope has `**Feature Flag**` other than None.]

| Flag | Default — production | Default — staging | Stage 1 targeting | Kill switch | Owner | Removal target |
|---|---|---|---|---|---|---|
| `goals.v2-progress-ring` | off | on | internal users, then 5% | yes — tested on staging | [role] | [version or date] |

- [ ] Every new or changed flag has a recorded default per environment
- [ ] Every risky path (sign-in, payments, auto-debit, notifications) sits behind a kill switch that was
      toggled on staging without a redeploy
- [ ] Targeting rules match Stage 1 of the rollout plan
- [ ] Flags fully rolled out in earlier releases are scheduled for removal

---

## Environment Config & Secrets

- [ ] New environment variables and config keys exist in production and staging (names listed below —
      never values)
- [ ] Secrets live in the secret manager — not in the repository, CI logs or client bundles (no server
      secret in a `NEXT_PUBLIC_` / `EXPO_PUBLIC_` / `VITE_` variable)
- [ ] Third-party integrations point at live mode where the release needs it: payment provider live keys
      (e.g. Toss Payments), webhooks registered for the production URL with signature verification on,
      APNs key and FCM credentials for production, 알림톡 templates approved for the production sender
- [ ] OAuth redirect URIs and allowed origins include the production domains and app schemes
      (Kakao, Naver, Apple sign-in; CORS)
- [ ] Staging ↔ production config diffed; intended differences listed below
- [ ] Certificates, signing keys and API keys that expire within the rollout window are renewed

| Key (name only) | Production | Staging | Note |
|---|---|---|---|
| `[ENV_VAR_NAME]` | present | present | [new in this release] |

---

## Observability

- [ ] Dashboards exist for each SLO in `docs/ops/slo.md` that covers a journey this release changes
- [ ] Burn-rate alerts page a human, and every paging alert has a runbook in `docs/ops/runbooks/`
- [ ] Rollout guardrails are visible in real time: error rate, p95 latency, crash-free sessions, and one
      business KPI (Moa: auto-debit success rate)
- [ ] Error tracking tags this release version; deploy markers appear on the dashboards
- [ ] New endpoints and jobs emit logs, metrics and traces; no personal data in new log lines
- [ ] Tracking events of the shipped PRDs exist in `design/product/tracking-plan.md` and were seen on staging
- [ ] The on-call rota covers the whole rollout window (KST, with UTC in the record)

<!-- minimal rigor: health endpoint, error tracking with the release tag, and an error-rate / latency view
     are enough; per-SLO dashboards and burn-rate alerts are not required. -->

---

## Rollback Path

**Required at every rigor tier.** A checklist whose Rollback Path is empty or says "redeploy" without the
steps is NO-GO.

| Surface | Mechanism | Steps for a human (command or console path) | Time to roll back | Data implications | Rehearsed |
|---|---|---|---|---|---|
| Web / API | redeploy previous artifact `[digest or deployment ID]`; turn the flag off | [exact command or console path] | [minutes] | [expand-only migrations stay] | [staging, YYYY-MM-DD] |
| Database | Expand phases are backward compatible; restore point `[ID]` before destructive steps | [steps] | [minutes] | [data written since the restore point] | [yes / no] |
| iOS / Android | binaries cannot be rolled back — halt the phased/staged rollout, kill-switch flag, expedited fixed build | [steps] | [hours to days — store review] | [none] | [flag toggle rehearsed] |

- **Trigger**: [halt thresholds that trigger a rollback — from the rollout plan when it exists]
- **Owner**: [role that decides] · **Executor**: [human who runs the steps]
- **Compatibility window**: the API stays compatible with app versions ≥ [minimum supported version];
  force-update policy: [none | soft prompt | hard block below version x.y.z]
- [ ] Rollback rehearsed on staging for this release or its predecessor (required at `full`, recommended
      at `standard`)

---

## Web

[Web: omitted — web is not in platform.surfaces]

- [ ] CDN and cache: hashed static assets; HTML cache headers checked; purge / invalidation plan for
      `[paths]`; service-worker update strategy (PWA only)
- [ ] SEO and meta: titles and descriptions, canonical URLs, no `noindex` leaking from staging, sitemap,
      Open Graph images for new pages, redirects for changed routes
- [ ] Cookie consent: the consent banner / CMP covers every cookie, SDK and tracker added in this release
- [ ] Security headers (CSP, HSTS) updated for any new third-party origin
- [ ] Changed routes within the Core Web Vitals budget (latest `production/qa/perf/perf-profile-*.md`)
- [ ] Browser support per `platform.browsers`

---

## Stores

[Stores: omitted — release.distribution is '[web | enterprise | internal]']

### iOS — App Store

- [ ] Marketing version `[x.y.z]` and build number `[n]` — never reused, even for a rejected build
- [ ] Signed with the distribution certificate and profile (or EAS / Xcode Cloud managed credentials)
- [ ] Minimum iOS version matches `platform.min_os.ios`
- [ ] Privacy nutrition labels match this release's data collection; privacy manifest declares
      required-reason APIs and bundled SDK manifests
- [ ] App Review Guidelines checked for changed features — sign-in options, in-app account deletion,
      in-app purchase / external payment links; review notes and a demo account supplied
- [ ] Export compliance answered
- [ ] TestFlight build tested by the internal group
- [ ] Release mode set: phased release for automatic updates | manual release at [time KST]

### Android — Google Play

- [ ] `versionName` `[x.y.z]` and `versionCode` `[n]` — strictly increasing
- [ ] App Bundle signed through Play App Signing
- [ ] `minSdk` matches `platform.min_os.android`; target API level meets Play's current requirement
      (verify in Play Console at submission time)
- [ ] Data safety form matches this release's data collection
- [ ] Policy check for changed features — permission declarations, payments, account deletion
- [ ] Internal testing track verified; staged rollout percentage for production set

### Both stores

- [ ] "What's new" text per locale taken from `production/releases/[version]/release-notes.md`
- [ ] Screenshots and previews updated where the UI changed
- [ ] (first public release) App record, content rating questionnaire, privacy policy URL, support URL,
      category — complete in both consoles
- [ ] Server compatible with the previous app versions still in use (see Rollback Path)

---

## Regions

[Regions: omitted — compliance.regions is [] (explicitly none)]

For each region in `compliance.regions`, list the items of `.claude/docs/compliance/<region>.md` that this
release touches. Each item is resolved, or explicitly accepted by the user with an owner. No deadline,
fine or threshold is written as fact without `(Source: <url>, retrieved YYYY-MM-DD)`.

| Region | Checklist section | Item | Why this release touches it | Status |
|---|---|---|---|---|
| kr | Privacy & Data Protection | privacy policy (개인정보 처리방침) and consent updated | new personal-data field `[field]` | [resolved / accepted — owner / open] |
| kr | Marketing Messages & Consent | advertising-message opt-in and separate night-time consent | new marketing push campaign | [status] |
| eu | Privacy & Data Protection | cookie / tracking consent covers the new SDK | new analytics SDK on web | [status] |

---

## Localization

- [ ] Every locale in `localization.locales` has complete strings for the changed screens, emails, push and
      알림톡 templates — no fallback-language leakage
- [ ] No new hard-coded user-facing strings (latest `/localize` scan or localization QA report)
- [ ] Localization QA `production/qa/localization-qa-YYYY-MM-DD.md` covers this release (required when
      two or more locales ship)
- [ ] CJK checks on changed screens: line breaking, truncation, font fallback
- [ ] Dates, numbers and currency formatted per locale (KRW has no minor unit)

---

## Release Notes

- [ ] `production/releases/[version]/release-notes.md` drafted by `/release-notes` from `docs/CHANGELOG.md`
      `## [x.y.z]` section
- [ ] Channels covered: In-App / Web · App Store and Google Play (with *Stores*) · API / Developers
      (when `api` is in `platform.surfaces`)
- [ ] Breaking API changes and deprecations announced with their `Sunset` dates per `docs/api/api-guidelines.md`
- [ ] Customer-visible plan, price or entitlement changes announced before they take effect, following the
      regional items above

---

## Sign-offs

| Role | Required at | Name | Decision | Date |
|---|---|---|---|---|
| Release owner | every tier | | [GO / NO-GO] | |
| qa-lead | standard, full | | | |
| release-manager | standard, full | | | |
| tech-lead | standard, full | | | |
| sre-engineer | full | | | |
| product-manager | full; any tier when the release changes plans or prices | | | |
| security-engineer | any tier when the release changes sign-in, payments or personal data | | | |

---

## Decision

**Blockers** (each makes the verdict NO-GO):
- [item — block — what resolves it — owner]

**Accepted exceptions** (the user accepted the risk; each has an owner):
- [item — reason — owner — revisit by]

**Not assessed** (each makes the verdict NOT ASSESSED unless a blocker exists):
- `NOT ASSESSED — [item]: [reason and what would make it checkable]`

**Not applicable**:
- `N/A — [condition] not configured` · `N/A — [item] not required at [tier]`

**Next**: [`/rollout-plan [version]` · `/release-notes [version]` · `/launch-checklist [version]` (first public release) · `/team-release [version]`]
