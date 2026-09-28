---
name: launch-checklist
description: "GA launch readiness across product, engineering/SRE, security & privacy, legal, support and go-to-market; GO/NO-GO."
argument-hint: "[version] [dry-run]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/launch-checklist/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys rigor,project.stage,distribution,surfaces,compliance,accessibility,automation`

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

# Launch Checklist

The first public launch (GA) — and any later major launch: a new market, a new platform, a paid tier going live —
exposes the company, not only the code. This skill assembles one readiness record across every department that
has to be ready on launch day, reads the evidence the earlier skills produced, consults the `sre-engineer` and the
`security-engineer`, and returns **GO**, **NO-GO** or **NOT ASSESSED**.

Output: `production/releases/<version>/launch-checklist.md`, with the verdict directly under its H1. The Launch gate
(`/gate-check launch`) requires it with verdict GO at `standard` and `full`, reads its `## Engineering & SRE` block,
and reads the Terms of Service and Privacy Policy links recorded in it. Per-release readiness (build, migrations,
flags, rollback) is `/release-checklist`; the staged exposure plan and its production readiness review are
`/rollout-plan`. This checklist does not repeat them — it reads their verdicts.

> **Explicit invocation only**: run this skill only when the user asks for it with `/launch-checklist`. Do not
> auto-invoke it from context.

**Scope the checklist to the project.** Emitting every item for every surface, channel and region trains readers
to skip the list, which defeats it. Every conditional item is either in scope, `N/A — <condition> not configured`
(the condition is known false), or asked about (the condition is unset). An unset value is a question, not a licence
to emit everything — and not the same as a value that says "none".

### Verdicts

| Verdict | When |
|---|---|
| `NO-GO` | At least one blocking item is open (`[ ]`) — including a blocking evidence report whose verdict does not satisfy the item, and a department sign-off still pending. |
| `NOT ASSESSED` | No blocking item is open, but at least one blocking item is `[?]` — its input was absent, so nobody could check it. |
| `GO` | Every blocking item is `[x]` or `[~]` and every required sign-off is recorded. Open recommended items are listed, not blocking. |

Precedence: **NO-GO > NOT ASSESSED > GO**. The file carries `> **Verdict**: <TOKEN>` directly under its H1.

### Item markers

| Marker | Meaning |
|---|---|
| `[x]` | Verified — the evidence is named (a path with its verdict line, a URL, or a person and date who confirmed it) |
| `[ ]` | Open — work remains |
| `[~]` | Accepted — not done, and a named owner accepted launching without it; reason, date and review date recorded |
| `[?]` | Not assessed — the input to this check was absent, so nobody could check it |
| `N/A — <condition> not configured` | The item's condition is known false (e.g. `N/A — Stores not configured`) |

An unticked box says *work remains*; `[?]` says *nobody could check* — only the first is closed by doing the work,
so the two are never merged. Every file that contains a `[?]` carries the legend line
`[?] = not assessed — the input to this check was absent`.

Items that mirror a Launch-gate floor — smoke PASS on the release candidate, no unresolved S1/S2 bugs, a security
audit without open Critical findings — can never be `[~]`: they stay `[ ]` until resolved.

---

## Phase 0: Parse Arguments and Resolve Scope

**0a. Version.** The first argument that is not `dry-run` is the version (semver, e.g. `1.0.0`). Otherwise read
`project.version` from `project.yaml` with Read. Both absent ⇒ if `production/releases/` holds exactly one
directory, propose it; else ask. Mobile build numbers and version codes go inside the file, never in the directory
name.

**0b. Dry run.** `dry-run` ⇒ build the whole checklist in the conversation with a provisional verdict; request no
sign-offs, write no file.

**0c. Existing checklist.** If `production/releases/<version>/launch-checklist.md` exists, read it: recorded
sign-offs, accepted items, URLs and answers are carried forward; every item is re-evaluated against current evidence.
The file is replaced only after asking (Phase 6).

**0d. Resolve the scope** from the config block, announcing each value:

- **`rigor`** — process weight. `minimal`: the catalog marks this step optional and the Launch gate does not require
  the launch checklist at the `minimal` workflow tier; run it when the launch still carries legal, store, payment or
  regional exposure. Items marked *(blocking: standard, full)* are written as *(recommended)*. `standard`: items marked
  *(blocking: full)* are written as *(recommended)*. `full`: every blocking marker applies.
- **`project.stage`** — `Hardening` is the expected stage. `Launch` means a later major launch; continue and say so.
  An earlier stage (`Discovery` … `Build`) ⇒ "Most launch evidence will not exist yet" — recommend `dry-run` and ask
  whether to continue. `not set` ⇒ note it and continue; the checklist reads evidence, not the stage.
- **`release.distribution`** — branch on its five values, never on platform names:
  - `web` — web items in; store items `N/A — Stores not configured`.
  - `stores` or `web+stores` — store items in (App Store and/or Google Play per the surfaces); web items follow
    `platform.surfaces`.
  - `enterprise` — managed distribution to customer organisations (MDM, managed app catalogs, private listings):
    customer security questionnaire, data processing terms and a deployment guide replace the public store listing.
  - `internal` — employees only: public go-to-market items are `N/A — internal distribution`; the employee notice
    and the internal support path replace them.
  - `(unset -- ask how this release ships)` ⇒ ask. If it cannot be asked, every distribution-dependent item is
    `[?]` with `NOT ASSESSED — release.distribution unset`. Never emit every track.
- **`platform.surfaces`** — `web` adds cookie consent, landing page and web accessibility items; `ios` / `android`
  add store listing, privacy details and force-update items (with Stores); `api` (an externally consumed API) adds
  developer documentation, API terms, key issuance and developer support. *UI* = any of `web`, `ios`, `android`.
  Unset ⇒ ask; never assume "no UI".
- **`compliance`** — `regions=<list>` selects `.claude/docs/compliance/<region>.md` for each listed region and no
  other (Phase 4). `regions=none` ⇒ no regional items, written as `Regional compliance: none — compliance.regions is
  [] (explicitly none)`. Unset ⇒ ask. `handles_pii` true ⇒ the personal-data items are in scope; unset ⇒ ask (unset
  is not false).
- **`accessibility.target`** — `wcag-a`, `wcag-aa` or `wcag-aaa` ⇒ the accessibility audit item checks against that
  level (WCAG 2.2). `none` ⇒ an explicit decision: write `N/A — accessibility.target is none (decided)`, and flag it
  when a configured region's `## Accessibility` items apply anyway. Unset ⇒ ask; unset is not `none`.

Read from `project.yaml` with Read (no config label): `project.name`, `project.category` (free text — a hint, never a
condition: when it suggests business customers, ask whether they are onboarded; *B2B* = the user confirmed it),
`localization.locales` (two or more ⇒ *Multi-locale*; unset ⇒ ask), and the `performance.*` budgets (for the
performance item).

**0e. Announce** the scope in one block: version, dry run or not, rigor, stage, distribution, surfaces, regions,
`handles_pii`, accessibility target, locales, and which conditional blocks are in or out and why.

---

## Phase 1: Gather the Evidence

Read what exists; name what does not. Newest file by the date in its name wins. For every verdict-bearing artifact,
read its `> **Verdict**:` line under the H1 — never infer a verdict from prose.

| Evidence | Where | Read |
|---|---|---|
| Release checklist | `production/releases/<version>/release-checklist.md` | verdict; rollback section; store block; regions block |
| Rollout plan | `production/releases/<version>/rollout-plan.md` | verdict; the verdict line under `## Production Readiness Review` |
| Release notes | `production/releases/<version>/release-notes.md` | exists; store sections when Stores |
| Security audits | `production/security/security-audit-full-*.md`, `…-quick-*.md`, `…-privacy-*.md` | verdict; Summary severity table (open Critical/High); `## Regional Compliance` statuses |
| Threat model | `docs/security/threat-model.md` | `## Threats (STRIDE)` open rows; `## Review` date |
| Smoke check | `production/qa/smoke-*.md` | verdict; the environment and build it ran against |
| QA sign-off | `production/qa/qa-signoff-*.md` | verdict |
| Hardening report | `production/qa/hardening-*.md` | verdict; `## Accessibility`; `## Security (quick)`; `## Blockers` |
| Load test | `production/qa/load/load-test-*.md` | verdict; thresholds; tested peak |
| Performance | `production/qa/perf/perf-profile-*.md`, `production/qa/perf/bundle-audit-*.md` | results against `performance.*` |
| Usability / beta | `production/qa/usability/*.md` | count; dates |
| Localization QA | `production/qa/localization-qa-*.md` | verdict (when *Multi-locale*) |
| Feature audit | `production/qa/feature-audit-*.md` | planned vs implemented for MVP features |
| Business rules | `production/qa/business-rules/business-rules-check-*.md` | pricing, promotions and abuse findings |
| Bugs | `production/qa/bugs/BUG-*.md` | `**Severity**:` and `**Status**:` lines — unresolved = `Open`, `In Progress` or `Fixed — Pending Verification` |
| SLOs and on-call | `docs/ops/slo.md` | `## Critical User Journeys`, `## SLIs & SLOs`, `## Error Budget Policy`, `## Dashboards & Alerts` (paging alerts), `## On-call` |
| Runbooks | `docs/ops/runbooks/*.md` | one per paging alert |
| Product | `design/product/product-brief.md` or `one-pager.md`, `design/product/feature-map.md`, `design/prd/*.md` | North Star and guardrails; MVP-tier features; `## Success Metrics & Instrumentation` |
| Pricing | `design/product/pricing-model.md` | plans and prices (paid products) |
| Tracking plan | `design/product/tracking-plan.md` | `## Events` rows owned by launched PRDs and their Status |
| Help center | `design/content/help-center/*.md` | articles per launched feature |
| Milestone | `production/milestones/*.md` | the GA milestone's quality gates |
| API guides | `docs/api/guides/*.md` | developer documentation (with the `api` surface) |

Report the denominators as you go — `checked 23 bug files, 0 unresolved S1/S2`, `6 paging alerts, 5 runbooks` —
never a bare tick. A missing report is not a passing report: an item whose evidence is absent is `[?]` unless the
user supplies the evidence in the conversation (recorded with who and when).

---

## Phase 2: Consult the SRE and the Security Engineer

Spawn both in parallel via `Agent` — they are consultants, not director gates, so they run on every invocation
whatever the review mode. Neither writes a file.

**`sre-engineer`** — for the `## Engineering & SRE` reliability and operations items. Pass: the item list of that
block (Phase 3); the paths of `docs/ops/slo.md`, `docs/ops/runbooks/`, the latest load test, perf-profile and
bundle-audit reports, the rollout plan and the release checklist (each or "none"); the `platform.surfaces` line; the
`performance.*` budgets read in Phase 0; the expected launch traffic if the user gave one. Ask for: one line per item
— `[x]`, `[ ]` or `[?]` with the evidence path or the reason — and the three largest operational risks for the launch
window. Read-only: no commands against any environment.

**`security-engineer`** — for the `## Security & Privacy` items. Pass: the item list of that block; the latest
full, quick and privacy audit paths and the threat model path (each or "none"); `docs/data/data-model.md`; the
`compliance` and `platform.surfaces` lines; the compliance file paths selected in Phase 0; the Terms of Service and
Privacy Policy text when it is in the repository or the user pasted it. Ask for: one line per item with status and
evidence or reason, the privacy-policy consistency check against the data model and the store privacy disclosures,
and the three largest security or privacy risks for the launch.

If a consult fails or returns without per-item lines, its block's items stay as the evidence alone supports, and the
block header says `sre-engineer consult incomplete — <reason>` (or `security-engineer …`); offer to re-run it.

---

## Phase 3: Build the Department Blocks

Fill the template below. For every item: resolve its marker (*blocking* or *recommended*) from `rigor`, resolve its
condition, set its status from the evidence and the consults, and name the evidence. Show each department block to
the user as it is completed; the user may correct a status, supply evidence, or accept an item (`[~]`, with owner,
reason, date and review date — never for the gate floors named above).

```markdown
# Launch Checklist: [Product Name] [version]

> **Verdict**: [GO | NO-GO | NOT ASSESSED]

**Version**: [semver] · build [iOS build number / Android version code, if Stores]
**Target launch**: [YYYY-MM-DD HH:MM KST / PT — or "not set"]
**Generated**: [YYYY-MM-DD] by /launch-checklist · **Updated**: [YYYY-MM-DD]
**Scope**: rigor [..] · stage [..] · distribution [..] · surfaces [..] · regions [.. | none] · handles_pii [..] · accessibility target [..] · locales [..]
**Blocking open**: [N] · **Not assessed**: [N] · **Accepted**: [N] · **Recommended open**: [N]

Legend: `[x]` verified · `[ ]` open — work remains · `[~]` accepted (owner, reason, date) · `[?]` = not assessed — the input to this check was absent · `N/A — <condition> not configured`

## Product

- [ ] Launch scope matches the MVP tier of `design/product/feature-map.md` (or the PRDs of this release); every cut feature is listed with its flag state — evidence: latest feature audit *(blocking)*
- [ ] Every launched PRD's `## Success Metrics & Instrumentation` states a baseline and a target; the brief's North Star and guardrails are named *(blocking: standard, full)*
- [ ] Usability or beta evidence in `production/qa/usability/`: at least 1 session (standard) / 3 sessions covering first run, the core journey and returning use (full) — a beta readout counts *(blocking: standard, full)*
- [ ] Hardening report verdict READY or READY WITH CONDITIONS, each condition listed with its owner *(blocking: standard, full)*
- [ ] Accessibility audit against `accessibility.target` (WCAG 2.2) on every UI surface — evidence: the hardening report's `## Accessibility` or dedicated screen-reader and automated-check results (if *UI*) *(blocking: full)*
- [ ] Localization QA verdict passes for every locale that ships (if *Multi-locale*) *(blocking: standard, full)*
- [ ] Plans and prices configured in the payment provider and stores match `design/product/pricing-model.md` (if paid plans) *(blocking)*
- [ ] Known issues for this release are listed (release notes `## Known Issues`) *(recommended)*
- [ ] The GA milestone's quality gates in `production/milestones/` are met *(recommended)*

## Engineering & SRE

[sre-engineer consulted — YYYY-MM-DD]

### Release readiness
- [ ] Release checklist `production/releases/<version>/release-checklist.md` verdict GO, with its rollback section *(blocking)*
- [ ] Rollout plan `production/releases/<version>/rollout-plan.md` verdict READY TO ROLL OUT, with the verdict line under `## Production Readiness Review` recorded *(blocking: standard, full)*
- [ ] Smoke check PASS on the release candidate (PASS WITH WARNINGS does not satisfy this) *(blocking)*
- [ ] QA sign-off APPROVED or APPROVED WITH CONDITIONS *(blocking: standard, full)*
- [ ] No unresolved S1 or S2 bugs — checked [N] bug files *(blocking)*

### Reliability and operations
- [ ] Load test meets its thresholds (verdict PASS) at or above the expected launch peak *(blocking: full)*
- [ ] Capacity headroom for the launch peak: autoscaling limits, database connections, and third-party quotas (payment provider, email, SMS / 알림톡, model APIs) raised where the load test says so *(blocking: standard, full)*
- [ ] An SLO per critical user journey in `docs/ops/slo.md`, with dashboards and alerts live *(blocking: standard, full)*
- [ ] Error-budget policy defined (`## Error Budget Policy`) *(blocking: full)*
- [ ] A runbook in `docs/ops/runbooks/` for every paging alert — [N] alerts, [N] runbooks *(blocking: standard, full)*
- [ ] On-call rota covers the launch window with primary, secondary and escalation, across the launch time zones (`## On-call`) *(blocking: standard, full)*
- [ ] Backup and restore tested — a restore was actually performed: date, environment, duration (if the product stores server-side data) *(blocking: standard, full)*
- [ ] Rollback rehearsed; for mobile, a server-side kill switch and a minimum-supported-version / force-update path exist (if `ios` or `android`) *(blocking: standard, full)*
- [ ] Performance targets met on every configured surface — newest perf-profile, bundle-audit and load-test results against `performance.*` *(blocking: standard, full)*
- [ ] Transactional messaging deliverable: email sending domains authenticated, SMS sender numbers and messaging sender profiles registered (if the product sends email, SMS, push or 알림톡) *(blocking: standard, full)*
- [ ] Disaster recovery: recovery objectives stated and failover rehearsed *(recommended)*
- [ ] Cost guardrails: budget alerts on cloud and paid APIs for the launch spike *(recommended)*

## Security & Privacy

[security-engineer consulted — YYYY-MM-DD]

- [ ] Security audit without open Critical or High findings — `full` at standard and full rigor; `quick` or `full` without open Critical findings at minimal — path, verdict and the report's `## Not Assessed` list (a required category not assessed makes this item `[?]`) *(blocking)*
- [ ] Threat model `docs/security/threat-model.md` reviewed since the last architecture change, with no Open Critical threat (if *PII*) *(blocking: standard, full)*
- [ ] Terms of Service published — URL: [..] *(blocking: standard, full)*
- [ ] Privacy Policy published — URL: [..] — and consistent with the data model, the SDKs and the store privacy disclosures *(blocking: standard, full)*
- [ ] Consent implemented where the configured regions require it: cookie/tracking consent (web) and marketing-message consent per channel, separate from the terms *(blocking: standard, full)*
- [ ] Personal-data rights work end to end: export, deletion, in-app account deletion, consent withdrawal (if *PII*) *(blocking: standard, full)*
- [ ] Production secrets only in the secret store; no test or staging keys in production configuration; nothing secret in client bundles — per the latest audit *(blocking)*
- [ ] Security-incident and breach-notification readiness: the incident runbook covers security incidents and each configured region's breach-notification items (who notifies whom, deadlines recorded with their source) *(blocking: standard, full)*
- [ ] Admin console behind MFA, role-scoped, with an audit log of personal-data views *(recommended)*
- [ ] Security contact published (`/.well-known/security.txt`) with a vulnerability intake process *(recommended)*
- [ ] Independent penetration test done (recommended when money movement, health data or enterprise SSO is in scope) *(recommended)*

## Legal

- [ ] Open-source license obligations met: attribution shipped (web licenses page, mobile open-source licenses screen); no license conflict open in the latest `deps` or `full` audit *(blocking: standard, full)*
- [ ] Processor and provider contracts in place: data processing terms with every processor; payment provider merchant review and messaging-provider contracts done *(recommended)*
- [ ] Product name, trademarks and domains cleared *(recommended)*

### Regional Compliance: [region] — `.claude/docs/compliance/[region].md`

[One sub-heading per configured region. Every item of the six sections, in file order, with its `Law/standard:` and
the evidence or question. Items of the five requirement sections are *(blocking: standard, full)*; `## Integration
Notes` items are *(recommended)*.]

- [ ] **[Section] — [item title]** — Law/standard: [..] — evidence / question / owner: [..]

## Support

- [ ] Help-center articles published for every launched feature and for account, billing and privacy topics (`design/content/help-center/`) *(blocking: standard, full)*
- [ ] Support channels staffed for the launch window (email, in-app chat, a KakaoTalk channel for Korean users) with response-time targets and an escalation path to on-call (`/incident` severity) *(blocking: standard, full)*
- [ ] Status page or in-app banner ready, with an owner and incident message templates *(blocking: standard, full)*
- [ ] Refund and cancellation procedure matches the terms and the configured regions' commerce items (if paid plans) *(blocking: standard, full)*
- [ ] Saved replies for the expected top issues: sign-in, payment failure, refund, account deletion *(recommended)*
- [ ] App-store review replies: owner and cadence (if *Stores*) *(recommended)*
- [ ] Developer support channel and API status reporting (if `api`) *(recommended)*
- [ ] Account onboarding plan for business customers (if B2B) *(recommended)*

## Go-to-Market

- [ ] Store submission records — privacy details (App Store) / Data safety form (Google Play), the review-guidelines check and the phased-release configuration — recorded in the release checklist's store block (if *Stores*) *(blocking)*
- [ ] Store listings per locale: name, subtitle or short description, keywords, screenshots for every required device size, category, content rating, support and privacy-policy URLs (if *Stores*) *(blocking: standard, full)*
- [ ] Release notes `production/releases/<version>/release-notes.md` drafted *(blocking: standard, full)*
- [ ] Developer documentation, API terms, key issuance and published rate limits (if `api`) *(blocking: standard, full)*
- [ ] Customer security questionnaire answers, data processing terms and a deployment guide (if `enterprise` distribution) *(blocking: standard, full)*
- [ ] Launch communications scheduled (announcement, email, push, social, press) in KST and PT, sent only to recipients with marketing consent *(recommended)*
- [ ] Landing page, search metadata and share images live (if `web`) *(recommended)*
- [ ] Pricing page matches the pricing model and store prices (if paid plans) *(recommended)*
- [ ] Referral and promotion codes configured with the abuse limits of the business-rules check *(recommended)*
- [ ] Sales and support teams briefed; FAQ ready *(recommended)*

## Analytics

- [ ] Every event owned by a launched PRD is `Verified` in `design/product/tracking-plan.md` `## Events` — [N] events, [N] Verified *(blocking: standard, full)*
- [ ] North Star and guardrail dashboards exist and show beta or staging data *(blocking: standard, full)*
- [ ] Tracking respects consent where the configured regions require it, and no event carries personal data outside its recorded basis (the `PII` column) *(blocking: standard, full)*
- [ ] Exposure events for launch flags and experiments *(recommended)*
- [ ] Attribution SDK configured and declared in the store privacy disclosures (if *Stores*) *(recommended)*
- [ ] Launch readout scheduled: `/retrospective release <version>` date and the metrics it compares *(recommended)*

## Sign-offs

[One line per department that has at least one blocking item. A person may sign several departments.]

- [ ] Product — [name] ([role]) — [YYYY-MM-DD] | pending
- [ ] Engineering & SRE — [name] ([role]) — [YYYY-MM-DD] | pending
- [ ] Security & Privacy — [name] ([role]) — [YYYY-MM-DD] | pending
- [ ] Legal — [name] ([role]) — [YYYY-MM-DD] | pending
- [ ] Support — [name] ([role]) — [YYYY-MM-DD] | pending
- [ ] Go-to-Market — [name] ([role]) — [YYYY-MM-DD] | pending
- [ ] Analytics — [name] ([role]) — [YYYY-MM-DD] | pending

### Blocking Items
[Every open `[ ]` blocking item: department, item, owner, target date.]

### Not Assessed
[Every `[?]` blocking item: department, item, the missing input, the skill that produces it.]

### Accepted
[Every `[~]` item: department, item, accepted by, date, reason, review by.]

### Recommended Items Open
[Every open recommended item, one line each.]
```

**Condition rules while filling:**
- A condition that is known false ⇒ the item is written `N/A — <condition> not configured` with no checkbox; it does
  not count.
- A condition that is unset and was not answered ⇒ the item is `[?]`.
- *(blocking: standard, full)* at `rigor: minimal` and *(blocking: full)* at `standard` are written *(recommended)*.
- An evidence report that exists but whose verdict does not satisfy the item (security audit `FAIL`, smoke `FAIL` or
  `NOT ASSESSED`, rollout plan `NOT READY`) ⇒ `[ ]`, with the verdict quoted. A security audit whose verdict is
  `NOT ASSESSED`, or whose `## Not Assessed` list names a required category, ⇒ `[?]` — nobody has looked there yet.

---

## Phase 4: Regional Compliance Items

For each region selected in Phase 0, Read `.claude/docs/compliance/<region>.md` and list **every** item of its six
sections under `## Legal` in a `### Regional Compliance: <region>` sub-heading — derive the list from the file, never
choose a subset.

- **Reuse the audit** where it exists: the latest `full` or `privacy` security audit's `## Regional Compliance`
  statuses map as `Met` → `[x]`, `Gap` → `[ ]`, `Accepted` → `[~]`, `N/A` → `N/A — <reason>`, `NOT ASSESSED` → ask
  the item's question now.
- **Ask** for the items the audit does not cover (commerce disclosures, store billing, accessibility law,
  integration approvals): who confirmed, when, and the evidence. Unanswered ⇒ `[?]`.
- **No numbers without sources**: a deadline, fine or threshold entered for an item carries
  `(Source: <url>, retrieved YYYY-MM-DD)`; otherwise write `NOT SOURCEABLE — confirm with counsel`.
- **Contradictions** are items too: `accessibility.target: none` with a region whose `## Accessibility` items apply,
  or `handles_pii: false` with a region's privacy items evidently in play, is written as an open item naming the
  contradiction.

---

## Phase 5: Sign-offs and Verdict

1. **Count** blocking items by status and list them in the four `###` lists under `## Sign-offs`.
2. **Sign-offs** (skipped in `dry-run`): for each department with at least one blocking item, ask with
   `AskUserQuestion` who signs it (name and role) and whether they sign now. A sign-off is a human decision: the skill
   records only what the user states in this session, never a sign-off on someone's behalf — in `autonomous` mode the
   sign-off lines stay `pending`. Suggested owners: Product — the product owner (product-director role); Engineering &
   SRE — the engineering owner and on-call lead; Security & Privacy — the security owner; Legal — counsel or the
   privacy officer; Support — the support lead (customer-success-manager role); Go-to-Market — the growth or marketing
   owner; Analytics — the analytics owner.
3. **Verdict** by the table and precedence at the top (`NO-GO > NOT ASSESSED > GO`). A pending required sign-off is an
   open blocking item.
4. **Summary** in the conversation: verdict, counts, the blocking items (with owners), the not-assessed items (with
   the skill that closes each), the accepted items, and the consultants' top risks.

---

## Phase 6: Write the Checklist

`dry-run` ⇒ print `Provisional verdict (dry run): <TOKEN>` and stop at Phase 7 without writing.

Otherwise ask: "May I write this to `production/releases/<version>/launch-checklist.md`?" When the file exists,
say what changes (items whose status changed, new sign-offs) before asking. Write only after approval, creating the
directory if needed. Never commit — committing is the user's decision.

---

## Phase 7: Next Steps

Print `Verdict: <TOKEN>` and the path. Then close with `AskUserQuestion`, offering only what applies:

- **NO-GO** — the skill behind each blocking item: `/rollout-plan <version>` (plan missing or not READY) ·
  `/release-checklist <version>` · `/smoke-check` (no PASS on the release candidate) · `/team-qa` (QA sign-off) ·
  `/team-hardening` (hardening report) · `/security-audit full` (audit missing or failing) · `/load-test` ·
  `/incident runbook <alert-slug>` (missing runbooks) · `/team-content help-center <slug>` (help center) · `/release-notes <version>` ·
  `/localize qa` · `/usability-report` · `/bug-triage` (open S1/S2 bugs) · re-run `/launch-checklist <version>` after
  the fixes · stop here;
- **NOT ASSESSED** — the skill that produces each missing input (as above), or supply the evidence and re-run ·
  stop here;
- **GO** — `/gate-check launch` in a fresh session (include this checklist's path) · then `/team-release` to execute
  the release train and rollout plan · stop here;
- **dry run** — run `/launch-checklist <version>` without `dry-run` when the evidence is in place · stop here.

---

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and `autonomous` modes see
`.claude/docs/automation-modes.md`.

1. **Question → Options → Decision → Draft → Approval** — scope (Phase 0), each department block (Phase 3), every
   acceptance and every sign-off (Phase 5) are the user's decisions.
2. **"May I write this to `<path>`?"** before the single write of Phase 6; nothing is written in `dry-run`.
3. **Evidence over assertion.** An item is `[x]` only with named evidence: a path and its verdict line, a URL, or a
   person and date. The consultants' statuses are shown next to the evidence, and conflicts are surfaced, never
   resolved silently.
4. **Unset is not "none".** Unset distribution, surfaces, regions, `handles_pii` or accessibility target are
   questions; `[?]` records the ones nobody could answer.
5. **Skips announce themselves.** Conditional items that do not apply are written `N/A — <condition> not configured`,
   never dropped silently.
6. **Humans sign.** Sign-offs and risk acceptances are recorded only as the user states them.
7. **No commits.** Committing is the user's decision.
8. **The next step is offered, never taken.** The closing widget (Phase 7) recommends the next skill and waits for
   the user's choice.
