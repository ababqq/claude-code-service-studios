> Gate definition, loaded by `/gate-check` for the TARGET PHASE ONLY.
> Never load the other five — one gate applies per invocation.


# Gate: Hardening → Launch


**Required Artifacts:**
- [ ] Release checklist `production/releases/<version>/release-checklist.md` with
      verdict GO, including a rollback section (`/release-checklist`)
- [ ] Rollout plan `production/releases/<version>/rollout-plan.md` with verdict
      READY TO ROLL OUT and a recorded SR-PRODUCTION-READINESS verdict line under its
      `## Production Readiness Review` (`/rollout-plan` — review-mode-exempt, so the
      verdict is always recorded; a skip note never satisfies this item)
- [ ] Launch checklist `production/releases/<version>/launch-checklist.md` with verdict
      GO (the first public launch; later releases skip it)
- [ ] Security audit `production/security/security-audit-full-*.md` with no open
      Critical or High findings (`/security-audit full`)
- [ ] Smoke check PASS on the release candidate build (`production/qa/smoke-*.md`;
      PASS WITH WARNINGS does not satisfy this item) — **the floor at every tier**
- [ ] QA sign-off `production/qa/qa-signoff-*.md` (from `/team-qa`) with verdict
      APPROVED or APPROVED WITH CONDITIONS
- [ ] Hardening report `production/qa/hardening-*.md` (from `/team-hardening`) with
      verdict READY or READY WITH CONDITIONS
- [ ] Load test report `production/qa/load/load-test-*.md` meeting its thresholds
      (verdict PASS). Under `performance.enforce: warn`, a load-test FAIL from
      breached thresholds, which the report's `> **Enforcement**:` line marks
      advisory, is CONCERNS (the `/gate-check` Section 3 performance rule), not an
      unmet item. Under `off`, thresholds are not scored. A stability failure
      (crash, restart, data error, no recovery) leaves the item unmet at every value
- [ ] Usability or beta sessions in `production/qa/usability/*.md` — at least 3
      (first-run, core journey, returning use; a beta readout counts) — count only
      reports whose `> **Verdict**:` is `ACTIONABLE` or `INCONCLUSIVE`; a
      `NOT ASSESSED` file with `> **Stage**: plan` is a session plan written by
      `/usability-report new`, not a session
- [ ] Runbooks `docs/ops/runbooks/*.md` for every paging alert named in
      `docs/ops/slo.md` `## Dashboards & Alerts`, and an on-call rota in its
      `## On-call` section
- [ ] Terms of Service and Privacy Policy are published, with their links recorded in
      the launch checklist
- [ ] Store submission records — privacy nutrition labels (App Store) / Data safety form
      (Google Play), the review-guidelines check, and the phased release configuration —
      recorded in the release checklist's store block (only if *Stores*)
- [ ] The items of `.claude/docs/compliance/<region>.md` for each region in *Regions* are
      resolved or explicitly accepted
- [ ] Localization QA `production/qa/localization-qa-*.md` (from `/localize qa`) (only
      if *Multi-locale*)
- [ ] Release notes `production/releases/<version>/release-notes.md` drafted
      (`/changelog <version>` writes the `## [<version>]` section of `docs/CHANGELOG.md`
      they are built from, then `/release-notes`)
- [ ] No unresolved S1 or S2 bugs (see **Unresolved bugs** below)

**Recommended (not blocking):**
- [ ] (none at the `full` baseline — the `standard` line below moves items here)

**Quality Checks:**
- [ ] An error-budget policy is defined (`docs/ops/slo.md` `## Error Budget Policy`)
- [ ] Backup and restore have been tested — a restore was actually performed, not
      only scheduled (only if *Backend*)
- [ ] Performance targets are met on every configured surface (`performance.*`
      budgets against the newest perf-profile, bundle-audit and load-test reports;
      `performance.enforce` decides what a breach means)
- [ ] An accessibility audit against `accessibility.target` is done (only if *UI*)
- [ ] Cookie/tracking consent and marketing-message consent are implemented where
      *Regions* require them
- [ ] The launch checklist's `## Engineering & SRE` block is complete (sre-engineer
      consulted)

**`<version>`** is `project.version` in `project.yaml`; when it is unset, use the
only directory under `production/releases/` — ask when there are several. Read every
verdict above from the artifact's `> **Verdict**:` line under its H1.

**Unresolved bugs**: a bug file `production/qa/bugs/BUG-NNNN.md` is unresolved when its
`**Status**:` is `Open`, `In Progress` or `Fixed — Pending Verification`; its severity
is its `**Severity**:` value (`S1-Critical`, `S2-Major`, `S3-Minor`, `S4-Trivial`).
`Verified Fixed`, `Closed` and `Won't Fix` are resolved. Count unresolved bugs by those
two lines, never by `Open` alone.

**Conditions** (resolved by `/gate-check` Phase 1):
- *UI* = `platform.surfaces` ∩ {web, ios, android} ≠ ∅. Unset ⇒ MANUAL CHECK NEEDED
  (ask), never "no UI".
- *Backend* = `stack.layers.backend.framework` set, or `stack.layers.data.database`
  set, or `api` ∈ `platform.surfaces`.
- *Stores* = `release.distribution` ∈ {`stores`, `web+stores`}. Unset ⇒ ask.
- *Regions* = `compliance.regions` list; unset ⇒ ask; `regions=none` (`[]`) ⇒ no
  regional items.
- *Multi-locale* = `localization.locales` has ≥2 entries; unset ⇒ ask.

An item whose condition is known false is reported as
`N/A — <condition> not configured` (e.g. `N/A — Stores not configured`) and is not
scored.

## Workflow tier reductions

The checklist above is the **`full` baseline**. At lower tiers apply the
reduction for the resolved tier. Every item above is named in each tier line
below with its status (required / recommended / dropped / conditional).
Reductions only ever *relax* a requirement — `workflow_overrides` is the
only thing that adds one.

- **`full`** — **required**: release checklist GO with a rollback section; rollout
  plan READY TO ROLL OUT with the SR-PRODUCTION-READINESS verdict; launch checklist
  GO; full security audit with no open Critical/High; smoke PASS on the release
  candidate; QA sign-off; hardening report READY (or READY WITH CONDITIONS); load
  test meeting thresholds; **at least 3** usability/beta sessions; runbooks and the
  on-call rota; Terms of Service and Privacy Policy; release notes; no unresolved
  S1/S2 bugs; error-budget policy; performance targets met; the Engineering & SRE
  block. **Conditional**: store submission records (*Stores*); regional compliance
  items and consent implementation (*Regions*); localization QA (*Multi-locale*);
  backup/restore tested (*Backend*); accessibility audit (*UI*). **Dropped**: the
  quick security audit as a substitute (the full audit is required at this tier).
- **`standard`** — **required**: release checklist GO with a rollback section;
  rollout plan READY TO ROLL OUT with the SR-PRODUCTION-READINESS verdict; launch
  checklist GO; full security audit with no open Critical/High; smoke PASS on the
  release candidate; QA sign-off; hardening report READY (or READY WITH CONDITIONS);
  **at least 1** usability/beta session; runbooks and the on-call rota; Terms of
  Service and Privacy Policy; release notes; no unresolved S1/S2 bugs; performance
  targets met; the Engineering & SRE block. **Conditional** (required when the
  condition holds): store submission records (*Stores*); regional compliance items
  and consent implementation (*Regions*); localization QA (*Multi-locale*);
  backup/restore tested (*Backend*). **Recommended**: load test meeting thresholds;
  error-budget policy; accessibility audit (**conditional** — *UI*). **Dropped**:
  the quick security audit as a substitute.
- **`minimal`** — **required**: **release checklist GO with a rollback section**;
  a security audit in mode **`quick`** (`production/security/security-audit-quick-*.md`)
  **or** `full`, with no open Critical findings; **smoke PASS on the release
  candidate** (the floor); **no unresolved S1/S2 bugs**. **Dropped**: rollout plan
  and the SR-PRODUCTION-READINESS verdict; launch checklist; the full-audit
  requirement (the quick audit replaces it); QA sign-off; hardening report; load test;
  usability/beta sessions; runbooks and on-call rota; Terms of Service and Privacy
  Policy; store submission records; regional compliance items; localization QA;
  release notes; error-budget policy; backup/restore; performance targets
  (`performance.enforce` still applies independently — the `/gate-check` rule);
  accessibility audit; consent implementation; the Engineering & SRE block.
