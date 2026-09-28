> Gate definition, loaded by `/gate-check` for the TARGET PHASE ONLY.
> Never load the other five — one gate applies per invocation.


# Gate: Build → Hardening


**Required Artifacts:**
- [ ] All MVP features are implemented — cross-reference the MVP PRDs in `design/prd/`
      with the resolved code roots (a `/feature-audit` report
      `production/qa/feature-audit-*.md`, when one exists, satisfies this)
- [ ] Tests exist for the Logic, Integration (contract tests included) and E2E stories,
      where `testing.patterns` in `project.yaml` says tests live (else `tests/**`)
- [ ] Contract tests exist for every API operation a client uses (only if *Backend*)
- [ ] E2E tests exist for every journey in `docs/ops/slo.md` `## Critical User Journeys`
- [ ] Smoke check has been run with a PASS or PASS WITH WARNINGS verdict — report
      `production/qa/smoke-*.md` — against **staging** (at `minimal`: staging, or local
      when no staging exists; the report says which). **The floor at every tier.**
- [ ] No unresolved S1 bugs (see **Unresolved bugs** below)
- [ ] Every unresolved S2 bug names an owner and a target date (in the bug file or the
      latest `/bug-triage` report `production/qa/bug-triage-*.md`)
- [ ] Every migration plan in `docs/data/migrations/` has its **Expand** phase applied
      on staging and its **Contract** phase scheduled (no plans ⇒ nothing to check;
      say so)

**Recommended (not blocking):**
- [ ] A QA plan `production/qa/qa-plan-*.md` (from `/qa-plan`) covers this sprint or
      this phase — absent ⇒ CONCERNS

**Quality Checks:**
- [ ] The test suite passes — run it via Bash with `commands.test` when it is set;
      no runner configured ⇒ NOT ASSESSED where the tier requires tests
- [ ] Performance is within the `performance.*` budgets, applying `performance.enforce`:
      `block` ⇒ a breach is a blocker, `warn` ⇒ CONCERNS, `off` ⇒ skipped with a note
- [ ] Dashboards and alerts exist for each SLO in `docs/ops/slo.md`
      (`## Dashboards & Alerts`)
- [ ] Every feature flag has a recorded default state
- [ ] Every implemented screen has a corresponding UX spec — no "designed in code"
      screens (only if *UI*)
- [ ] Accessibility compliance is verified against `accessibility.target` (only if *UI*)

**Entry, not exit.** Entering Hardening means feature complete / code freeze. QA
sign-off and the S2 burn-down are **exit** criteria of Hardening and are checked by
the Hardening → Launch gate, not here.

**Test items** (`qa.level: minimal` makes them non-required at every workflow tier):
the Logic/Integration/E2E tests item, the contract tests item, the critical-journey
E2E item, and the test-suite-passes check. The smoke check is **not** a test item —
it is build health and the floor at every `qa.level`.

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

An item whose condition is known false is reported as
`N/A — <condition> not configured` (e.g. `N/A — Backend not configured`) and is not
scored.

## Workflow tier reductions

The checklist above is the **`full` baseline**. At lower tiers apply the
reduction for the resolved tier. Every item above is named in each tier line
below with its status (required / recommended / dropped / conditional).
Reductions only ever *relax* a requirement — `workflow_overrides` is the
only thing that adds one.

- **`full`** — **required**: all MVP features implemented; Logic/Integration/E2E
  tests; E2E tests for every critical journey; smoke check PASS or PASS WITH
  WARNINGS on staging; no unresolved S1 bugs; an owner and target date on every
  unresolved S2 bug; migration Expand phases applied on staging and Contract phases
  scheduled; test suite passing; performance within budgets; dashboards and alerts
  per SLO; flag default states recorded. **Conditional**: contract tests for every
  client-used operation (*Backend*); a UX spec for every implemented screen and
  accessibility compliance verified (*UI*). **Recommended**: QA plan. Nothing is
  dropped.
- **`standard`** — **required**: all MVP features implemented; E2E tests for every
  critical journey; smoke check PASS or PASS WITH WARNINGS on staging; no unresolved
  S1 bugs; an owner and target date on every unresolved S2 bug; migration Expand
  phases applied on staging and Contract phases scheduled; test suite passing;
  performance within budgets; flag default states recorded. **Recommended**:
  Logic/Integration/E2E tests per story; contract tests (**conditional** — *Backend*);
  QA plan; dashboards and alerts per SLO; a UX spec for every implemented screen and
  accessibility compliance verified (both **conditional** — *UI*). Nothing is
  dropped.
- **`minimal`** — **required**: **smoke check PASS or PASS WITH WARNINGS** (staging,
  or local when no staging exists — the floor) and **no unresolved S1 bugs**.
  **Dropped**: all MVP features implemented; Logic/Integration/E2E tests; contract
  tests; critical-journey E2E tests; S2 owners and dates; migration phases; QA plan;
  test suite passing; performance within budgets (`performance.enforce` still applies
  independently — `block` makes a measured breach a blocker even here); dashboards and
  alerts; flag default states; UX spec per screen; accessibility compliance.
  Reductions relax what must *exist*, never what must *work* — a smoke report that
  the tree contradicts is still a blocker.
