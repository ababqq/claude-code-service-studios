---
name: release-checklist
description: "Per-release checklist (build, migrations, flags, config/secrets, observability, rollback, web and store blocks, regions). GO/NO-GO."
argument-hint: "[version]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, AskUserQuestion, Bash(bash "*/.claude/skills/release-checklist/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys rigor,project.stage,distribution,surfaces,compliance,automation`

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

# Release Checklist

Every release gets one checklist — the first public launch and every release after
it. The checklist answers one question for one version: **is this release candidate
safe to put in front of users, and can we take it back if it is not?** It writes
`production/releases/<version>/release-checklist.md` from the template
`.claude/docs/templates/release-checklist-template.md`, with the verdict line
`> **Verdict**: GO | NO-GO | NOT ASSESSED` directly under its H1.

Who reads it:

- `/rollout-plan` — builds the staged rollout on this checklist's Rollback Path,
  flags and migrations;
- the production readiness review (run by `/rollout-plan`) — checks that the
  Rollback Path is complete and no blocker is open;
- `/team-release` — will not start a rollout without a GO;
- `/gate-check launch` — requires this file with verdict GO and a rollback section,
  at every workflow tier.

> **Explicit invocation only**: This skill should only run when the user explicitly
> requests it with `/release-checklist`. Do not auto-invoke based on context matching.

## Verdicts

Precedence **NO-GO > NOT ASSESSED > GO** — a known blocker is more actionable than
an unknown, and an unknown is not a pass:

- **NO-GO** — at least one blocker: an in-scope item failed and the user did not
  accept it as an exception (see Phase 4 for what can never be accepted).
- **NOT ASSESSED** — no blocker, but at least one in-scope item could not be
  checked (missing report, unanswered question, unreadable record). The file names
  each one and what would make it checkable.
- **GO** — every in-scope item is checked, or explicitly accepted by the user with a
  named owner.

## Scope this checklist to the project

Emitting every item for every track trains the reader to skip the list, which
defeats the gate. Scope with the resolved values above:

- **`project.stage`** — `Hardening`: normally the first public release; include the
  first-submission items (store app records, content rating questionnaire, privacy
  policy URL) and point to `/launch-checklist` for launch readiness beyond this
  release. `Launch`: a subsequent release; scope store and regional items to what
  changed since the previous release. An earlier stage: a release checklist is
  unusual there — ask whether this is an internal or beta release (proceed, and say
  so in the header) or premature (stop). **Unset**: do not guess a stage; derive the
  release type from the release history (Phase 1) and say
  `project.stage: unset — release type derived from production/releases/`.
- **`modes.rigor`** — at `minimal`, drop items whose only justification is process
  weight this project has opted out of (the table in Phase 3 says which). **The
  Rollback Path is never dropped** — it is required at every tier.
- **`release.distribution`** — decides the **Stores** block and the private or
  internal distribution items. Branch on the five values this key takes, not on
  surface names; `.claude/docs/effects-map.md` (`## release.distribution`) holds
  what each value means:
  - `web` — no Stores block. Emit exactly one line in its place:
    `Stores: omitted — release.distribution is 'web'`.
  - `stores` — the Stores block (App Store and Google Play).
  - `web+stores` — the Stores block, and the Web block when `web` is a surface.
  - `enterprise` — no public Stores block (one omission line); the private
    distribution item of Build & CI Artifact applies (Apple Business Manager custom
    app, Managed Google Play private app, or a customer-hosted package, with
    customer admins told the change window).
  - `internal` — no Stores block (one omission line); the internal-track item of
    Build & CI Artifact applies, and customer-facing items (release notes, regional
    customer notices) are marked `N/A — internal distribution`.
  - **Unset** — **ask how this release ships** before emitting any store item. An
    unset value is a question, not a licence to emit every track. If the user cannot
    answer, the Stores block reads `NOT ASSESSED — release.distribution unset` and
    the verdict cannot be GO. **Unset is not `web`**: `web` is a decision, unset is a
    missing one, and they must not produce the same output.
- **`platform.surfaces`** — decides the **Web** block (`web` listed) and whether the
  Release Notes block expects an API / Developers section (`api` listed). `web` not
  listed ⇒ emit exactly one line: `Web: omitted — web is not in platform.surfaces`.
  **Unset ⇒ ask which surfaces ship**; never assume "no web".
- **`compliance.regions`** — decides the **Regions** block: one table section per
  listed region. `regions=none` (the key is `[]`) ⇒ emit exactly one line:
  `Regions: omitted — compliance.regions is [] (explicitly none)`. **Unset ⇒ ask**;
  unset is not "none".

> **Two axes, never one.** `platform.surfaces` says *what* ships (web, ios, android,
> api); `release.distribution` says *how it reaches users* (web deploys, public
> stores, private distribution, internal tracks). They agree most of the time and
> are still different lists: an `ios` surface distributed `enterprise` gets no App
> Store block, and a `web` surface never implies `web` distribution for the apps
> beside it. Emit the Web block from surfaces and the Stores block from
> distribution. When the two contradict each other (e.g. `ios` in surfaces but
> distribution `web`), ask — one of the two is stale — rather than choosing.

If an item cannot be scoped because the config is absent and the user does not
answer, mark it **`NOT ASSESSED — <key> unset`**. Do not silently include it, and do
not silently drop it.

---

## Phase 0: Resolve the Version

Read the argument for the version (SemVer, e.g. `1.4.0`). No argument → read
`project.version` from `project.yaml` and confirm it with the user. Neither → ask.
Never invent a version. The directory is `production/releases/<version>/`; mobile
build numbers and version codes go inside the file, never in the directory name.

If `production/releases/<version>/release-checklist.md` already exists, read it and
ask: update it for the current release candidate (Recommended when the candidate
changed), or keep it and stop.

---

## Phase 1: Identify What Ships

Build the `## Scope` block — everything later is scoped to it.

- **Release type.** Glob `production/releases/*/release-record.md`. No record with
  `> **Verdict**: COMPLETED` for an earlier version ⇒ **first public release**;
  otherwise **subsequent release**, and the latest completed record is the
  **previous release**.
- **Stories.** `production/sprint-status.yaml` entries with `status: done` that
  shipped after the previous release, and their story files
  (`production/epics/*/story-*.md`) — read each story's `**PRD**`, `> **Surface**:`,
  `**API Contract**`, `**Migration**`, `**Feature Flag**` and `**Analytics Events**`
  fields.
- **PRDs and quick specs** those stories implement (`design/prd/*.md`,
  `design/quick-specs/*.md`).
- **Bug fixes**: `production/qa/bugs/BUG-NNNN.md` whose `**Status**:` is
  `Verified Fixed` or `Closed` since the previous release.
- **Changelog**: `docs/CHANGELOG.md` — the `## [<version>] - YYYY-MM-DD` section if it
  exists (absent ⇒ recommend `/changelog <version>`; the checklist can still proceed).
- **Deferred items**: anything planned for this version that is not done.

Show the Scope to the user and confirm it before filling the blocks: a checklist
scoped to the wrong list checks the wrong migrations and flags.

---

## Phase 2: Read the Evidence

Read each report's verdict from its `> **Verdict**:` line directly under its H1.
Take the newest file of each kind; if the newest one predates the release candidate,
say so — evidence about a different build is not evidence about this one.

| Evidence | Path | Passing verdicts | Feeds |
|---|---|---|---|
| Smoke check on the release candidate | `production/qa/smoke-*.md` | `PASS`; `PASS WITH WARNINGS` only with every warning listed and accepted — never on a first public release, where `/gate-check launch` requires `PASS` | Build & CI Artifact |
| QA sign-off | `production/qa/qa-signoff-*.md` | `APPROVED`, `APPROVED WITH CONDITIONS` | Build & CI Artifact |
| Security audit | `production/security/security-audit-*.md` | `PASS`; `CONCERNS` with no open Critical or High finding | Build & CI Artifact |
| Migration plans in Scope | `docs/data/migrations/NNNN-<slug>.md` | `SAFE`; `RISKY — MITIGATION REQUIRED` with the mitigation done | Database Migrations |
| Load test (when the release changes a peak path) | `production/qa/load/load-test-*.md` | `PASS` | Observability |
| Performance profile (web routes changed) | `production/qa/perf/perf-profile-*.md` | `PASS`, `CONCERNS` accepted | Web |
| Localization QA (two or more locales) | `production/qa/localization-qa-*.md` | its passing verdict | Localization |
| Release notes | `production/releases/<version>/release-notes.md` | present (it carries no verdict) | Release Notes |

A report that is **absent** is `NOT ASSESSED — no <report> found` for the items it
feeds, never a pass. A verdict of `NOT ASSESSED` in the report is not a pass either:
it means nobody looked, and the warnings value means somebody looked and saw
something minor — do not read one as the other.

**QA sign-off at `minimal`.** `/gate-check launch` drops the QA sign-off at the
`minimal` tier, so this checklist does not require one there. Absent at `minimal` ⇒
the item reads `N/A — QA sign-off not required at minimal` and is not scored; present
⇒ its verdict is read and recorded as at any other tier. At `standard` and `full` an
absent sign-off is `NOT ASSESSED — no QA sign-off found`.

**Unresolved bugs.** A bug file `production/qa/bugs/BUG-NNNN.md` is **unresolved**
when its `**Status**:` is `Open`, `In Progress` or `Fixed — Pending Verification`;
its severity is its `**Severity**:` value (`S1-Critical`, `S2-Major`, `S3-Minor`,
`S4-Trivial`). `Verified Fixed`, `Closed` and `Won't Fix` are resolved. Count by those
two lines — never by `Open` alone, which misses a fix nobody verified.

> **State the denominator with every count.** `0` means either "searched and found
> none" or "there was nothing to search", and on a release gate those are opposite
> findings. Report `scanned [N] bug files: [a] unresolved S1, [b] unresolved S2` —
> or, when `production/qa/bugs/` does not exist or is empty,
> **`NOT ASSESSED — no bug records found`**, and ask whether bugs are tracked
> somewhere else (an issue tracker). The user's answer is recorded with its source.
> A bare `0` is not a result. The same rule applies to every other count in the
> file (flags, migrations, config keys).
>
> `/launch-checklist` counts the same way and is often run beside this one. Keep the
> two consistent: changing the rule in one and not the other leaves a route to the
> same misleading `0`.

---

## Phase 3: Fill the Blocks

Copy the template and fill every block. Each block below lists its sources and
what turns an item into a blocker. The rigor column says which blocks shrink.

| Block | `minimal` | `standard` | `full` |
|---|---|---|---|
| Scope | required | required | required |
| Build & CI Artifact (incl. verification of this candidate) | required — QA sign-off `N/A` when absent; the CI items a recorded note when the repo has no CI workflow | required | required |
| Database Migrations | required when a migration ships | same | same |
| Feature Flags | required when a flag ships | same | same |
| Environment Config & Secrets | required | required | required |
| Observability | reduced: health endpoint, error tracking with the release tag, an error-rate and latency view | full block | full block |
| Rollback Path | **required** | **required**; rehearsal recommended | **required**; rehearsal required |
| Web | when `web` is a surface | same | same |
| Stores | with *Stores* | same | same |
| Regions | per listed region | same | same |
| Localization | strings complete for every locale | + localization QA with two or more locales | same |
| Release Notes | recommended (required with *Stores*: the stores show update text) | required | required |
| Sign-offs | release owner | + qa-lead, release-manager, tech-lead | + sre-engineer; product-manager and security-engineer when their areas changed |

**Build & CI Artifact** — the candidate's tag, commit and CI run; immutable artifact
IDs (image digest, web build ID, iOS build number, Android `versionCode`); the smoke,
QA sign-off and security audit verdicts from Phase 2; unresolved bugs from Phase 2.
Blockers: the candidate was not built by CI from the tagged commit; smoke `FAIL`;
any unresolved S1; an unresolved S2 in a journey this release touches; an open
Critical or High security finding. This is stricter than the Hardening → Launch gate at
`minimal`, which requires only no open Critical finding: the checklist blocks on an open
High at every tier.

At `minimal` a project may have no CI at all — `/test-setup` is optional at that tier
and `/gate-check validation` drops the CI workflow. Glob the CI files `/test-setup`
recognises (`.github/workflows/*.yml`, `.github/workflows/*.yaml`, `.gitlab-ci.yml`,
`bitbucket-pipelines.yml`, `azure-pipelines.yml`). None at `minimal` ⇒ the two CI
items read `N/A — CI workflow not configured (optional at minimal); built from <where>`
and are not scored, and "not built by CI" is not a blocker; the candidate's tag,
commit and immutable artifact IDs are still recorded. A CI workflow that exists but
did not build this candidate is a blocker at every tier.

**Database Migrations** — one row per migration plan named by a story in Scope, with
the phase state from the plan's `## Status` table (`pending`, `applied-staging`,
`applied-production` per Expand / Migrate / Contract) and the plan's verdict.
Blockers: Expand not yet applied on staging; a Contract phase shipping with, or
ahead of, code that still reads the old shape (including supported mobile app
versions); no rollback for a phase; plan verdict `UNSAFE`. The checklist never runs
a migration — it records who will run each one and when.

**Feature Flags** — one row per flag named by a story in Scope: default per
environment, Stage 1 targeting, kill switch, owner, removal target. Blockers: a new
flag with no recorded production default; a risky path (sign-in, payments,
auto-debit, notifications) with no kill switch.

**Environment Config & Secrets** — new config keys and secrets **by name and
presence only**; this skill never reads, prints or records a secret value, and
never opens key stores or credential files. Live-mode integrations (payment
provider, webhooks with signature verification, APNs and FCM, 알림톡 sender and
templates), OAuth redirect URIs (Kakao, Naver, Apple), and credentials expiring in
the rollout window. Blocker: a key the release needs is missing in production.

**Observability** — from `docs/ops/slo.md` (`## Critical User Journeys`,
`## Dashboards & Alerts`, `## On-call`) and `docs/ops/runbooks/`. At `minimal` the
reduced items apply and `docs/ops/slo.md` is not required. At `standard`/`full`, an
absent `docs/ops/slo.md` is `NOT ASSESSED — no SLO document (run
/create-architecture)`. Blocker: no way to see the rollout guardrails (error rate,
p95 latency, crash-free sessions, one business KPI) while the release rolls out.

**Rollback Path** — per surface in Scope: the mechanism, the exact steps a human
runs, time to roll back, data implications, rehearsal; the trigger, owner and
executor; the mobile compatibility window and force-update policy. Mobile binaries
cannot be rolled back — their path is halting the phased or staged rollout, a
server-side kill switch and an expedited fixed build. **An empty Rollback Path, or
one that says "redeploy" with no steps, is NO-GO at every tier and cannot be
accepted as an exception.**

**Web** (only when `web` is a surface) — CDN and cache invalidation, SEO and meta
(canonical, robots, sitemap, Open Graph, redirects), cookie consent for new cookies
and trackers, security headers for new third-party origins, Core Web Vitals on
changed routes (latest perf profile), browser support per `platform.browsers`
(read from `project.yaml`).

**Stores** (only with *Stores*) — iOS: marketing version and build number (never
reused), signing, minimum iOS per `platform.min_os.ios`, privacy nutrition labels and
privacy manifest, App Review Guidelines check for changed features (sign-in options,
account deletion, payments), export compliance, TestFlight, phased or manual
release. Android: `versionName` / `versionCode`, Play App Signing, `minSdk` per
`platform.min_os.android` and the target API level Play currently requires, Data
safety form, policy check, internal track and staged rollout percentage. Both:
"What's new" per locale from the release notes, screenshots where the UI changed,
first-submission items for a first public release, server compatibility with older
app versions. `platform.min_os.*` are read from `project.yaml`; unset ⇒ ask. Store
rules change several times a year: an item that depends on a current policy says
"verify in App Store Connect / Play Console at submission time" rather than stating
the rule from memory.

**Regions** (per listed region) — read `.claude/docs/compliance/<region>.md` for each
region in `compliance.regions` and list only the items this release touches, with
the checklist section they come from (`## Privacy & Data Protection`,
`## Security Certification`, `## Commerce & Payments`,
`## Marketing Messages & Consent`, `## Accessibility`, `## Integration Notes`).
Typical triggers: a new personal-data field (`kr`: privacy policy and consent under
PIPA), a new marketing push, email, SMS or 알림톡 campaign (`kr`: advertising-message
opt-in and separate night-time consent; `eu`: ePrivacy consent; `us`: CAN-SPAM and
TCPA), a new app permission (`kr`: permission-access notice, 접근권한 안내), a payment
or refund change (`kr`: 전자상거래법 disclosures, 전자금융거래법 review), a new tracker
on the web (`eu`: cookie consent). Each item is resolved, or accepted by the user
with an owner. **Never state a deadline, fine or threshold as fact** unless it is
followed by `(Source: <url>, retrieved YYYY-MM-DD)`; the regional files are topic
checklists, not legal advice. A region whose file is missing is
`NOT ASSESSED — .claude/docs/compliance/<region>.md not found`.

**Localization** — `localization.locales` read from `project.yaml` (unset ⇒ ask):
strings complete per locale for changed screens and notification templates, no new
hard-coded strings, localization QA with two or more locales, CJK line breaking and
truncation, locale formats.

**Release Notes** — `production/releases/<version>/release-notes.md` present (from
`/release-notes`), covering In-App / Web, the store sections with *Stores*, and an
API / Developers section when `api` is a surface; breaking API changes and
deprecations announced with `Sunset` dates; plan and price changes announced before
they take effect.

**Sign-offs** — the roles of the rigor column above. These are the people who hold
the roles; this skill records their decisions, it does not make them.

For every item, write one of: a ticked box with its evidence, an unticked box with
a blocker note, `NOT ASSESSED — <reason>`, or `N/A — <condition> not configured`
(`N/A — <item> not required at <tier>` for a tier reduction named above).
A block that does not apply keeps its heading and carries its one omission line.

---

## Phase 4: Decide the Verdict

Collect the `## Decision` block: blockers, accepted exceptions, not-assessed items,
not-applicable items.

Present every blocker and every not-assessed item to the user with `AskUserQuestion`,
one question per item or a grouped question when there are many:

- Blocker options: `[A] Fix it, then re-run /release-checklist` ·
  `[B] Accept as an exception — owner and revisit date required` ·
  `[C] Leave it as a blocker (verdict NO-GO)`
- Not-assessed options: `[A] I'll provide the evidence now` ·
  `[B] Accept the gap — owner required` · `[C] Leave it NOT ASSESSED`

**Never acceptable as an exception**: an unresolved S1 bug; an empty Rollback Path;
a Contract-phase migration shipping ahead of code that still reads the old shape;
smoke `FAIL` on the release candidate. These stay blockers until fixed.

Apply the precedence: any remaining blocker ⇒ **NO-GO**; else any remaining
not-assessed item ⇒ **NOT ASSESSED**; else **GO**. Write the verdict into the line
directly under the H1.

---

## Phase 5: Save the Checklist

Present the checklist with: the verdict; the number of items checked, accepted, not
assessed and not applicable (with the denominator); every blocker; and every block
that was omitted with its reason.

Ask: "May I write this to `production/releases/<version>/release-checklist.md`?"

If yes, write the file, creating `production/releases/<version>/` if needed. This is
the only file this skill writes.

---

## Phase 6: Next Steps

Use `AskUserQuestion`:

- Prompt: "Release checklist for [version]: [GO | NO-GO | NOT ASSESSED]. What's next?"
- Options (offer only what applies):
  - `[A] /rollout-plan [version] — stage the rollout on this checklist (standard/full)`
  - `[B] /release-notes [version] — draft the customer-facing notes`
  - `[C] /launch-checklist [version] — launch readiness across departments (first public release)`
  - `[D] /team-release [version] — execute the release (GO only)`
  - `[E] /bug-triage — work down the blocking bugs (NO-GO)`
  - `[F] Stop here`

On a first public release still in `Hardening`, remind the user that
`/gate-check launch` reads this file and requires verdict GO with a rollback
section.

---

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and `autonomous`
modes see `.claude/docs/automation-modes.md`.

1. **Question → Options → Decision → Draft → Approval.** Scope is confirmed before
   the blocks are filled; every blocker and gap is decided by the user.
2. **"May I write this to `<path>`?"** before the one write this skill makes.
3. **Unset is a question.** Unset `release.distribution`, `platform.surfaces`,
   `compliance.regions`, `localization.locales` or `platform.min_os.*` is asked
   about — never answered by emitting every track, or by dropping a block.
4. **Skips announce themselves.** Omitted blocks carry one line saying why;
   unassessable items say `NOT ASSESSED — <reason>`; every count has a denominator.
5. **This skill checks; people decide and act.** It runs no command, deploys
   nothing, reads no secret value, and never marks a blocker resolved on its own.
6. **No commits.** Committing the checklist is the user's decision.
