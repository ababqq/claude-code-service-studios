---
name: gate-check
description: "Ready to advance to the target phase? PASS/CONCERNS/NOT ASSESSED/FAIL with blockers and required artifacts."
argument-hint: "[target-phase: definition | architecture | validation | build | hardening | launch] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/gate-check/../../hooks/yaml-helper.sh" resolve_config *)
model: opus
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,workflow,qa.level,testing.strict,performance.enforce,team.size,project.stage,feature_overrides,surfaces,stack,compliance,accessibility,distribution,code_roots`

Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.


# Phase Gate Validation

This skill validates whether the project is ready to advance into a target phase.
It checks for required artifacts, quality standards, and blockers.

**Distinct from `/project-stage-detect`**: That skill is diagnostic ("where are we?").
This skill is prescriptive ("are we ready to advance?" with a formal verdict).

## Production Stages (7)

The project progresses through these stages (the `project.stage` values; the
workflow-catalog phase id is always the lowercase stage):

1. **Discovery** — Frame the problem, the users and the bet: product brief (or the one-pager at `minimal`), stack pinned for the layers already decided
2. **Definition** — Decompose the product into features (feature map) and specify each MVP feature in a PRD
3. **Architecture** — Architecture and SLOs, ADRs, the initial API contract, data model, threat model, accessibility foundations, test and CI scaffold
4. **Validation** — Prove the path: design language, key UX specs, usability on prototypes, API contract reconciled with the UX, epics and stories, the first sprint, and a walking skeleton deployed to staging through CI ("Sprint 0")
5. **Build** — Sprint-based delivery: pick, implement, verify and close stories
6. **Hardening** — Beta and stabilization: performance, load, security, accessibility, usability, QA sign-off, runbooks, release preparation
7. **Launch** — Go-live and continuous delivery. **Terminal**: there is no gate after it; every later release is recorded under `production/releases/<version>/`, not gated

**When a gate passes** and the user confirms, Section 6 writes the new stage to
`project.stage` in `project.yaml` — the single stage record. The status line,
`/help` and `.claude/scripts/stage-estimate.sh` read it on their next run.

---

## 1. Parse Arguments

**Target phase:** `$ARGUMENTS[0]` — the phase being entered, one of `definition`,
`architecture`, `validation`, `build`, `hardening`, `launch` (blank = derive it,
see "No argument" below). `--review full|lean|solo` overrides the resolved
`review_mode` for this run.

- `discovery` is the start phase — no gate leads into it. Say so and stop.
- Any other value is not a phase gate: stop, list the six valid targets, and ask
  which one was meant. Never guess a target from a near-miss spelling.

The **departure phase** — the phase being left, whose catalog steps are the work
that must be complete — is derived from the target through the Section 2 table.
It is **never** taken from `project.stage`, and it is never empty.

Note: in `solo` mode every director spawn of the Section 4b panel is skipped —
gate-check becomes artifact and quality checks only. In `lean` mode the panel runs at the width `modes.workflow` sets (§4b).
`review_mode` is resolved `--review` → `project.local.yaml` → `project.yaml` →
the `modes.rigor` expansion. Unset on an unconfigured project: `modes.rigor` defaults to `minimal`, which resolves `review_mode` to `solo`.

**`workflow`** (per `.claude/docs/workflow-modes.md`):

`gate-check` runs project-wide, so it uses the project-level `workflow` for the
gate's overall artifact checklist (the loaded gate file), AND consults
`workflow_overrides.feature_overrides.<feature>` per feature when validating MVP
PRDs — a feature pinned to a higher tier must meet that tier's section set
before the gate passes, regardless of the project-level workflow (see Section 2b,
"Per-feature overrides").

> **gate-check honors `workflow` but is exempt from `automation`.** The artifact
> checklist changes per tier; the collaborative prompting protocol (Collaborative
> Protocol section) always applies — a phase gate is a deliberate human
> checkpoint, never auto-run.

**`qa.level`**: controls test enforcement at phase gates, where `workflow`
controls which artifacts are required. `modes.rigor` sets both together; set
`qa.level` explicitly to vary enforcement alone. At `minimal`, no per-story test
gates apply — the test items (each gate file names them in its **Test items**
block) become non-required and the Section 3 `testing.strict` check is a no-op;
the smoke report stays the floor (Section 2b). At `standard`, Logic and
Integration tests (contract tests included) must pass. At `full`, the E2E suite
for the critical user journeys joins them.

**`team.size`**: does not change how many directors spawn at a phase gate — panel
width is `workflow`'s axis (Section 4b). This value affects only the
**specialist depth within each director's review**.
`individual` uses the core specialist set; `small` the standard set; `studio`
adds the routed stack sub-specialists. It never skips a director — skipping
directors is `review_mode`'s job. Both `review_mode` and `team.size` are fronted
by `modes.rigor` — one rigor choice sets both — and each still overrides that
axis when set explicitly (a full-rigor project gets the `studio` set; lighter
tiers get `individual`).

**Conditions.** The gate reference files mark some items as conditional. Resolve
every condition the target gate uses here, from the block above (and
`localization.locales`, read from `project.yaml` with Read — it has no
`resolve_config` label):

- *UI* = `platform.surfaces` ∩ {web, ios, android} ≠ ∅. Unset ⇒ MANUAL CHECK NEEDED (ask), never "no UI".
- *Backend* = `stack.layers.backend.framework` set, or `stack.layers.data.database` set, or `api` ∈ `platform.surfaces` (the `stack` line lists `backend=` / `data=` when set; `unset=` names the layers that are not).
- *Public API* = `api` ∈ `platform.surfaces` (an externally consumed API: public or partner).
- *PII* = `privacy.handles_pii: true` (the `compliance` line's `handles_pii=`). Unset ⇒ ask (unset ≠ false).
- *Stores* = `release.distribution` ∈ {`stores`, `web+stores`}. Unset ⇒ ask.
- *Regions* = `compliance.regions` list (the `compliance` line's `regions=`); unset ⇒ ask; `regions=none` (`[]`) ⇒ no regional items.
- *Multi-locale* = `localization.locales` has ≥2 entries; unset ⇒ ask.

An item whose condition is known false is reported as
`N/A — <condition> not configured` and is not scored. Ask about every unset condition the target gate
uses in one `AskUserQuestion` before Section 3; an unanswered condition stays a
MANUAL CHECK NEEDED item. The answers hold for this run only — never write them
to `project.yaml` (`/setup-stack` owns those keys; suggest it).

- **With argument**: `/gate-check build` — validate readiness for that specific phase
- **No argument**: run the shared stage estimator, then **confirm with the user before running**:

  ```
  Bash: bash .claude/scripts/stage-estimate.sh
  ```

  It prints `STAGE:`, `SOURCE:`, `ESTIMATE:` and `EVIDENCE:`. Lowercase the
  `STAGE:` value to get its catalog phase id (`Validation` → `validation`); the
  target is that phase's `next_phase` — the Section 2 row whose departure phase it
  is. If `STAGE:` is `Launch`, stop with:
  "Launch is terminal — no further phase gate; use /release-checklist, /rollout-plan and /retrospective release <version>."

  Use `AskUserQuestion`:
  - Prompt: "Detected stage: **[STAGE]** (`SOURCE: [project.yaml | estimated]` — [EVIDENCE]). Running the gate into **[Target]** ([STAGE] → [Target]). Is this correct?"
    When `SOURCE: project.yaml` and `ESTIMATE` differs from `STAGE`, show both — the recorded stage may lag the tree.
  - Options:
    - `[A] Yes — run this gate`
    - `[B] No — pick a different gate` (if selected, show a second widget listing all gate options: Discovery → Definition, Definition → Architecture, Architecture → Validation, Validation → Build, Build → Hardening, Hardening → Launch)

  Do not skip this confirmation step when no argument is provided.

---

## 2. Phase Gate Definitions

Each gate's checklist — required artifacts, quality checks, and its workflow-tier
reductions — lives in its own file, named for the phase the gate leads into.
**Read only the row for the target phase; never load the others.**

| From → To (target) | Reference file | Departure phase (`--phase`) |
|---|---|---|
| Discovery → Definition (`definition`) | `.claude/skills/gate-check/references/gate-definition.md` | `discovery` |
| Definition → Architecture (`architecture`) | `.claude/skills/gate-check/references/gate-architecture.md` | `definition` |
| Architecture → Validation (`validation`) | `.claude/skills/gate-check/references/gate-validation.md` | `architecture` |
| Validation → Build (`build`) | `.claude/skills/gate-check/references/gate-build.md` | `validation` |
| Build → Hardening (`hardening`) | `.claude/skills/gate-check/references/gate-hardening.md` | `build` |
| Hardening → Launch (`launch`) | `.claude/skills/gate-check/references/gate-launch.md` | `hardening` |

Each file states the `full` baseline first, then names every item with its
status at `full`, `standard` and `minimal`. Apply the tier resolved in Section 1.

## 2b. Workflow Tier Adjustment

Each gate file carries its own tier reductions (see Section 2). Two rules apply
across all of them:

> **How to apply:** run the loaded gate's checklist, then apply that file's tier
> reduction for the tier resolved in Section 1. **dropped** = not checked at this
> tier; **recommended** = absent surfaces as CONCERNS, never a Blocker;
> **conditional** = the item carries a condition (Section 1) and is `N/A` when
> that condition is known false; items not named keep their baseline status.
> Reductions only ever *relax* a requirement — the only thing that adds one is
> `workflow_overrides` (below).
>
> **`qa.level` (Section 1) further relaxes the test items independently of the
> tier:** at `qa.level: minimal` the per-story test items become non-required at
> every workflow tier (so even `workflow: full` does not require them); the
> Section 3 `testing.strict` check is then a no-op.
>
> **The smoke check is excluded from that relaxation, and is the floor.**
> `qa.level` relaxes *per-story test evidence*; a smoke check is **build health**,
> not story evidence, and the two are already held apart on exactly this basis in
> `.claude/docs/coding-standards.md` ("`/smoke-check` is a build-health gate, not
> a per-story evidence gate ... This divergence is intentional"). So a gate file
> that requires a smoke report keeps requiring it at every `qa.level`.
>
> Without that exclusion the Build → Hardening gate would rest on the S1 bug
> count alone at `rigor: minimal`: `minimal` reduces it to the smoke check and the
> bug count, `qa.level` would then drop the smoke check too, and one `modes.rigor`
> setting fires both. A gate that closes Build on "no S1 bug is open" has not
> asked whether the build even boots.

> **A gate with no required artifacts left must say so, and may not return
> PASS.** After applying the tier reduction and the `qa.level` relaxation, count
> what remains required. If the count is zero, report
> **NOT ASSESSED** naming both reducers and the gate — *"<From> → <To> at
> `workflow: <tier>` + `qa.level: <level>` leaves no required artifact; this
> gate verified nothing"* — rather than a PASS earned by having nothing to check.
> (Every shipped gate file keeps at least one required item at `minimal` — the
> smoke floor, the S1 count, the one-pager, the stack pin — or declares itself
> not applicable. A gate file edited later could lose them; this rule still
> holds.)
> Per `.claude/rules/skill-authoring.md` obligation 1, a run that could not
> assess its scope has not established that the scope is good, and obligation 3
> requires the emptiness to be visible in the output rather than inferable from
> a silent green.
>
> The one exception is a gate its reference file declares **not applicable** at
> the resolved tier (the Definition → Architecture gate at `minimal`): it returns
> PASS with the file's note, and that note is the visible statement that nothing
> was checked. It is a declared tier design, not an empty checklist.
>
> **`performance.enforce` is likewise independent of the tier, and a tier
> reduction never suppresses it.** The performance check in Section 3 runs at
> every workflow tier, and `block` makes a breach a Blocker at every workflow
> tier. Do **not** read a gate file's "dropped" performance item as dropping it:
> `off` is the only thing that makes budgets informational, and it is a
> deliberate choice the user makes on the same key.
>
> Without this, `performance.enforce: block` would be **inert on every
> `rigor: minimal` project** — the `minimal` line of the Build → Hardening gate
> drops the performance item, and a literal reading of that line would drop the
> budget check with it. A setting that only works because agents disregard a
> rule is not wired.

### Per-feature overrides (`workflow_overrides.feature_overrides`)

Independent of the project-level tier above, and applied **only** where a gate
validates MVP PRDs (the PRD structure check of the Definition → Architecture
gate). For each feature, resolve its effective tier:

1. If the block's `feature_overrides` lists `<feature>` → that tier
2. Else the project-level `workflow`

**Before applying any of them, check the block the other way round: does every
KEY match a feature?** `<feature>` is the PRD filename stem
(`.claude/docs/workflow-modes.md`), so for each key in `feature_overrides`, look
for `design/prd/<key>.md`. Any key with no matching stem is reported, naming the
key and listing the stems that do exist:

> `feature_overrides key 'savings-goal' matches no PRD in design/prd/. Available stems: auth, onboarding, goals, payments. This override is doing nothing.`

Surface it as a **CONCERNS**-level finding, not a Blocker — the project is still
gateable, but an override the user believes is in force and is not is exactly how
a documented escape hatch silently stops working. Run this check at the
Definition → Architecture gate and at every later gate.

> **This is the one site that performs the check.** `.claude/docs/workflow-modes.md`
> says *"a key that matches no feature is an error, not a no-op"*, and this is the
> only skill that implements it — the story skills resolve only in the
> feature → override direction, so an orphan key is never looked up and never
> noticed. `/gate-check` is the right home: it already resolves the whole block,
> and it is the project-wide audit rather than a per-story one. `/write-prd` must
> not run it: before a PRD's first draft its key matches no stem by design.

Validate each PRD against its own effective tier's section set:

- A feature pinned **higher** than the project (e.g.
  `feature_overrides.payments: full` on a `standard` project) **blocks the gate** until that feature's PRD
  meets the higher bar (payments → all 11 contract sections). This is the one case
  where a per-feature setting makes the gate *stricter* than the project tier.
- A feature pinned **lower** (e.g. `onboarding: minimal`) relaxes only that
  feature — its PRD is checked at the lower tier; every other feature stays at the
  project level. A feature pinned **`minimal` imposes no PRD section requirement
  at all** (`minimal` = "the one-pager replaces PRDs" —
  `.claude/docs/workflow-modes.md`): it never blocks the gate on a missing or
  incomplete PRD. Do not invent an "acceptance-criteria-only" floor for it — there
  is none.

> **Additive overrides (the only things that make the gate stricter).**
> - `workflow_overrides.design_language_strict: true` forces the complete
>   (9-section) design language at the Validation → Build gate regardless of tier
>   (on projects with a *UI* surface).
> - `workflow_overrides.edge_cases: true` and
>   `workflow_overrides.config_flags: true` force those PRD sections required when validating PRD completeness,
>   additive on top of the resolved tier (`edge_cases` makes `## Edge Cases`
>   required on PRDs whose effective tier is `minimal`; at `standard`,
>   `config_flags: true` makes the otherwise-advisory `## Configuration & Flags`
>   section blocking). These never relax — a `false` value is the default/no-op,
>   never a way to drop a section the tier already requires.

---

## 3. Run the Gate Check

**Before running artifact checks**, read `docs/consistency-failures.md` if it exists.
Extract entries whose Domain matches the target phase (e.g., for the
Definition → Architecture gate pull entries in any PRD domain — Payments,
Subscription, Notifications; for the Architecture → Validation gate pull entries
in Architecture, API, Data or Security). Carry these as context — recurring
conflict patterns in the target domain warrant increased scrutiny on those
specific checks.

For each item in the target gate:

### Artifact Checks

**Resolve existence and counts deterministically — do not open files to find out
what exists:**

```
Bash: bash .claude/scripts/artifact-check.sh --phase [departure-phase]
```

Pass the **departure phase** from the Section 2 table (its steps are the work
that must be complete): `definition` for the Definition → Architecture gate,
`validation` for the Validation → Build gate, and so on. Derive it from the
target, never from `project.stage`, and never pass it empty — the script exits 2
on an empty or unknown phase id.

It reads `.claude/docs/workflow-catalog.yaml` — which already encodes each step's
`glob`, `pattern`, `min_count` and `any_of` — and reports per step:

| status | Meaning |
|---|---|
| `PRESENT` | glob matched, `min_count` met, `pattern` found where specified |
| `ABSENT` | nothing matched |
| `SHORT` | matched but fewer than `min_count` (`count=` and `min=` given) |
| `PATTERN_MISS` | files exist but none contains the required marker |
| `NO_CHECK` | the step declares no artifact — **not detectable from disk** |
| `UNKNOWN` | the check itself could not run (e.g. `grep` unavailable) — not satisfied |

It emits observations, never a verdict: **you** apply the workflow tier and the
required/optional split from Section 2. An `ABSENT` required artifact is a
blocker at `full` and frequently not one at `minimal`; the script does not know
that and does not decide it. Each `STEP:` line also carries `tiers=` and `when=`
from the catalog — ignore both: the gate reference file is authoritative for this
skill.

If the script exits non-zero, or prints `STEPS: 0` for the departure phase, the
catalog could not be evaluated: every artifact item of the gate is unassessed, not
clean (Section 5, NOT ASSESSED).

**`NO_CHECK` is not `PRESENT`.** The header prints a `NO_CHECK:` count before any
row precisely so this cannot be skimmed past. Those steps were *scanned*, not
*satisfied* — carry each into Section 4 (Collaborative Assessment) and ask, or
mark MANUAL CHECK NEEDED. A gate that reports PASS because most of its checklist
was undetectable is the failure mode this count exists to prevent.

**Existence is not adequacy.** The script cannot tell a real document from a
template skeleton. So: for any artifact the verdict actually turns on, spot-read
it and confirm it has real content — the same escalation rule the
`prd-structure-check.sh` step below uses. Do not spot-read artifacts the verdict
does not turn on. Where a gate item names a verdict (GO, READY TO ROLL OUT,
VALIDATED, APPROVED …), read it from the artifact's `> **Verdict**:` line under
its H1.

> **A smoke report is always an artifact the verdict turns on — spot-reading it
> is mandatory, not discretionary.** At `minimal` it is frequently the *only*
> required artifact, so the whole gate rests on one file that nothing generated
> and nothing verifies. Check its claims against the repo, and raise any that the
> tree contradicts:
>
> - It reports a passing automated suite → the test locations (`testing.patterns`
>   in `project.yaml`, else `tests/**`) must actually contain test files and the
>   project must have a runner (`commands.test`). "24 passed, 0 failed" in a repo
>   with no test files and no runner is a finding, not evidence.
> - It marks a critical journey PASS → the code for that journey must exist in the
>   resolved code roots. A PASS on "sign in with Kakao" with no Kakao OAuth code
>   anywhere is a finding.
> - It carries no date, or predates the newest commit touching the code roots →
>   say so; a stale smoke report describes a build that no longer exists.
> - It does not name its environment (staging or local) → say so; the gate files
>   state which environment each tier accepts.
>
> Report a contradiction at the same level the artifact was required at: a
> Blocker where the smoke check is required, CONCERNS where it is recommended.
> This was found by handing a gate a one-page fabricated smoke report on a
> two-file repo; it cleared on existence plus a verdict-line grep.

For code checks, use the resolved code roots (the `code_roots` line): verify the
directory structure and file counts per root. Include roots marked `undeclared`
and print `WARN: undeclared code roots: <dirs> — declare them with /setup-stack`.
If the line reads `code_roots: unresolved`, print
`NOT CHECKED — no code root resolved (set stack.layers.<layer>.root via /setup-stack)`
and skip the scan — a required code check that could not run is NOT ASSESSED,
never "zero findings".

**Definition → Architecture gate — cross-PRD review check**:
Use `Glob('design/prd/reviews/prd-cross-review-*.md')` to find the `/review-all-prds` report.
If no file matches: at `full` mark the "cross-PRD review report exists" artifact as
**FAIL** and surface it prominently ("No `/review-all-prds` report found in
`design/prd/reviews/`. Run `/review-all-prds` before advancing to Architecture."); at
`standard` the report is recommended, so mark it **CONCERNS**, not a blocker; at
`minimal` this gate is not applicable (see the gate file). If a file is found, read
the newest one and check its verdict line: a FAIL verdict means the cross-PRD
consistency check failed and must be resolved before advancing. A NOT ASSESSED
verdict means the report names phases or PRDs it could not review (its
`## Not Assessed` section) — score the item NOT ASSESSED, never PASS.

**Gate-outcome items.** An item "<GATE-ID> outcome recorded" is satisfied by the
recorded verdict line (`> **[Director] Review (<GATE-ID>)**: …`) — `[Director]` is
the owning agent's role title (e.g. `Design Director`), not a literal, so match the
item on `Review (<GATE-ID>)**:` — **or**, when the
resolved `review_mode` skips that gate, by the literal skip note
`[<GATE-ID>] skipped — <Mode> mode` in the same artifact. In the skip case print
`NOT CHECKED — <GATE-ID> skipped (<mode> mode)` and do **not** score the item:
review mode is an explicit user choice, and the skip note is the evidence it was
applied. Review-mode-exempt skills (`/hotfix`, `/rollout-plan`, `/incident`)
always record a verdict, so a skip note is never valid for their gates.

**Unresolved bugs** (bug items of the Build → Hardening and Hardening → Launch
gates): a bug file `production/qa/bugs/BUG-NNNN.md` is unresolved when its
`**Status**:` is `Open`, `In Progress` or `Fixed — Pending Verification`; its
severity is its `**Severity**:` value (`S1-Critical`, `S2-Major`, `S3-Minor`,
`S4-Trivial`). Count with `Grep` over those two lines — never by `Open` alone.

### Quality Checks
- For test checks: Run the test suite via `Bash` with `commands.test` (and
  `commands.e2e` for E2E) read from `project.yaml` with Read — the `commands.*`
  keys carry no `resolve_config` label.
  **If no runner is configured, that is `NOT ASSESSED`, not a silent skip** — see
  the trigger in the verdict section. A gate that ran no tests found no test
  failures, which is not the same as passing.
  A test failure's effect on the verdict depends on the `testing.strict` block
  **resolved in Phase 1** (`resolve_config` merges `project.local.yaml` over
  `project.yaml`; reading the file directly would drop a local override), per
  test type:
  - **Logic** — unit test failures, gated by `testing.strict.logic`.
  - **Integration** — integration and contract test failures, gated by `testing.strict.integration`.
  - **E2E** — E2E failures on the critical user journeys, gated by `testing.strict.e2e`.
  - For each type: take `testing.strict.<type>` from that block; use it only
    if its value is `true` or `false` (case-insensitive). If it is `unset` or
    holds any other value, default to `true` (Logic, Integration and E2E are
    BLOCKING by default — `.claude/docs/coding-standards.md`). Surface any
    unrecognized value to the user.
  - At a strict (`true`) gate level, failures of that type are **Blockers**
    (verdict FAIL). At an advisory (`false`) level, they are **Concerns**
    (verdict minimum CONCERNS, not FAIL) — list them under Recommendations, not
    Blockers.
- For PRD review checks, gather section presence **deterministically** — do not
  read the PRDs to count headings:

  ```
  Bash: bash .claude/scripts/prd-structure-check.sh
  ```

  It prints a `PRESENT:` / `ABSENT:` pair per PRD in `design/prd/`. It reports
  presence only and makes no REQUIRED/ADVISORY judgment.

  Then apply each PRD's **effective tier** (Section 2b, per-feature resolution) to
  those lists — all 11 contract sections at `full`; at `standard` the 8 required
  sections (Overview, Goals & Non-Goals, Functional Requirements, Edge Cases,
  Dependencies, Non-Functional Requirements, Success Metrics & Instrumentation,
  Acceptance Criteria) plus `## Business Rules & Calculations` whenever the feature
  defines a numeric or policy rule (prices, fees, limits, quotas, rate limits,
  eligibility thresholds, time windows, rounding), with User Value and
  Configuration & Flags advisory; no section at `minimal`. A missing *required*
  section blocks; a missing section that is optional at the effective tier is
  advisory. A section reported PRESENT can still fail review if it is an empty
  heading — spot-read any section the verdict actually turns on.
- For performance checks: read the budgets (`performance.api_p95_ms`,
  `performance.error_rate_pct`, `performance.availability_pct`,
  `performance.lcp_ms`, `performance.inp_ms`, `performance.cls`,
  `performance.bundle_kb`, `performance.cold_start_ms`,
  `performance.crash_free_pct`) from `project.yaml` with Read, and compare them
  against measured data in the newest `production/qa/perf/perf-profile-*.md`,
  `production/qa/perf/bundle-audit-*.md` and `production/qa/load/load-test-*.md`
  reports. What a breach *means* is set by `performance.enforce`, taken from the
  Phase 1 resolved block (it is locally overridable, so do not read the file for
  this one):
  - `warn` (default) — breaches are **CONCERNS**, never Blockers.
  - `block` — breaches are **Blockers** from the Build → Hardening gate onward.
  - `off` — budgets are informational; do not surface breaches in the verdict (say so in one line).

  Only these three values are recognized. Surface anything else to the user and
  fall back to `warn` rather than guessing.
- For localization checks (*Multi-locale*): `Grep` for hardcoded user-facing
  strings in the resolved code roots, using the extensions the `code_roots` line
  lists. **If the code roots are unresolved, report the `NOT CHECKED` line above
  rather than zero hits.**

### Cross-Reference Checks
- Compare the MVP PRDs in `design/prd/` against implementations in the resolved code roots
- Check that every module the architecture document names has corresponding code in its declared root
- Verify sprint plans reference real story paths in `production/epics/`
- Verify every API operation a key UX spec's `## API Data` section references exists in the contract under `docs/api/`

---

## 4. Collaborative Assessment

For items that can't be automatically verified, **ask the user**:

- "I can't automatically verify that the core user journey delivers the value proposition. Has it been through a usability session?"
- "No usability report found in `production/qa/usability/`. Has informal testing with target users been done?"
- "Performance measurements aren't available. Would you like to run `/perf-profile`?"
- "`platform.surfaces` is unset, so I can't tell whether this product has a UI. Which surfaces ship — web, ios, android, api?"

**Never assume PASS for unverifiable items.** Mark them as MANUAL CHECK NEEDED.

---

## 4b. Director Panel Assessment

The panel is set by **two independent axes**, both resolved in Phase 1: `review_mode`
decides *whether* the panel runs, `workflow` decides *how wide* it is.

**Axis 1 — `review_mode` decides whether any director spawns.** This skill spawns
the phase-gate panel only: PD-PHASE-GATE, TD-PHASE-GATE,
DM-PHASE-GATE and DD-PHASE-GATE, each at the seat the width table below gives
it. Apply the resolved mode (`--review` overrides it) to each gate before
spawning:
- `full` → spawn as normal.
- `lean` → **skip every gate whose ID does not end in `-PHASE-GATE`**. Note: `[GATE-ID] skipped — Lean mode`
  Every gate of this panel ends in `-PHASE-GATE`, so the panel runs — phase gates
  are the purpose of lean mode.
- `solo` → skip all gates, note `[GATE-ID] skipped — Solo mode` for each seat the
  width would have filled. Note in output: "Director Panel skipped — Solo mode.
  Gate verdict based on artifact and quality checks only." Proceed to Section 5.

**Axis 2 — `workflow` decides the panel width.** Three of the four directors run
on Opus, so a fixed four-director panel costs a weekend hackathon exactly what it
costs a thirty-feature fintech product. The gate still runs at every tier; only
its breadth scales. This table is the single source for panel width — other docs
point here instead of copying it:

| `workflow` | Panel | Directors |
|---|---|---|
| `minimal` | 1 | `delivery-manager` |
| `standard` | 2 | `technical-director`, `delivery-manager` |
| `full` | 4 | `product-director`, `technical-director`, `delivery-manager`, `design-director` |

`delivery-manager` is in every panel — scope and schedule readiness is the one
judgment no tier makes optional. `technical-director` joins at `standard` because
that is the first tier requiring architecture artifacts. `product-director` and
`design-director` join at `full`, the only tier requiring the full design
language and UX spec set for them to assess.

**When no *UI* surface is configured** (known, not unset), DD-PHASE-GATE is
omitted and listed under "Name the omissions":
"design-director omitted — no UI surface".
When `platform.surfaces` is unset and the user did not answer the
Section 1 question, keep the seat — unset is not "no UI", and DD-PHASE-GATE assesses
it normally. The gate definition returns READY with the note
"no UI surface — nothing to assess" only when it is spawned anyway on surfaces
known to hold no UI.

> **Width is not the same as strictness.** A narrower panel does not soften the
> verdict: the escalation rule in `.claude/docs/director-gates.md` is unchanged —
> the strictest verdict returned by *whoever ran* still wins. Do not infer PASS
> from a perspective that was never consulted.

Before generating the final verdict, spawn the directors for the resolved width as **parallel subagents** via `Agent` using the parallel gate protocol from `.claude/docs/director-gates.md`. Issue all the `Agent` calls simultaneously — do not wait for one before starting the next. Pass each agent only its gate file path plus the `Pass:` items below; the agent reads the gate file itself — do not read it or paste it into the prompt.

**Gate IDs:**

1. **`product-director`** — gate **PD-PHASE-GATE** (`.claude/docs/director-gates/pd-phase-gate.md`)
   Pass: target phase · gate reference file path · artifact-check output for the departure phase · brief path · feature map path (or "none")
2. **`technical-director`** — gate **TD-PHASE-GATE** (`.claude/docs/director-gates/td-phase-gate.md`)
   Pass: target phase · gate reference file path · artifact-check output for the departure phase · resolved `stack` and `code_roots` lines
3. **`delivery-manager`** — gate **DM-PHASE-GATE** (`.claude/docs/director-gates/dm-phase-gate.md`)
   Pass: target phase · gate reference file path · artifact-check output for the departure phase · `production/risk-register/` path (or "none")
4. **`design-director`** — gate **DD-PHASE-GATE** (`.claude/docs/director-gates/dd-phase-gate.md`)
   Pass: target phase · gate reference file path · artifact-check output for the departure phase · resolved `surfaces` line · design-language path (or "none")

Fill them from this run: the gate reference file path is the Section 2 row; the
brief path is `design/product/product-brief.md` (`design/product/one-pager.md` at
`minimal`); the feature map path is `design/product/feature-map.md`; the
design-language path is `design/brand/design-language.md`; the risk-register
path is `production/risk-register/` when it holds at least one entry. Write
"none" for any that does not exist. (QL-TEST-COVERAGE is not part of this panel:
`/story-done` and `/team-qa` spawn it, and this gate reads their outcome through
the evidence and the QA sign-off.)

**Parse each response's first line** as `[GATE-ID]: TOKEN` (the brackets are
optional: `DM-PHASE-GATE: READY` parses the same), where TOKEN is one of
`READY`, `CONCERNS`, `NOT READY`, and map it with the verdict classes of
`.claude/docs/director-gates.md` (`## Standard Verdict Format`): `READY` is
APPROVE-class, `CONCERNS` is CONCERNS-class, `NOT READY` is REJECT-class. A
response whose first line does not parse, or names another gate, is a director
that did not return a verdict (Section 5, NOT ASSESSED).

**Name the omissions in the output.** Below the Director Panel summary, when the
panel ran narrower than four, state which perspectives did not run and how to get
them — e.g. "Panel: 2 of 4 (`workflow: standard`). Product and Design
perspectives not consulted. Only `modes.workflow: full` seats the full panel
(`/settings modes.workflow=full`, or `modes.rigor=full`); `--review` decides
whether the panel runs, not how wide it is." A silently narrow panel reads as a
clean bill of health from reviewers who never looked.

**Collect every response the resolved width called for, then present the Director Panel summary:**

```
## Director Panel Assessment

Product Director:   [READY / CONCERNS / NOT READY / not in panel / skipped]
  [feedback]

Technical Director: [READY / CONCERNS / NOT READY / not in panel / skipped]
  [feedback]

Delivery Manager:   [READY / CONCERNS / NOT READY / skipped]
  [feedback]

Design Director:    [READY / CONCERNS / NOT READY / not in panel / omitted — no UI surface / skipped]
  [feedback]
```

**Apply to the verdict:**
- Any director returns NOT READY → verdict is minimum FAIL (user may override with explicit acknowledgement)
- Any director returns CONCERNS → verdict is minimum CONCERNS; list each concern so the user can revise, accept or discuss it
- Every director that ran returns READY → eligible for PASS (still subject to artifact and quality checks from Section 3)

---

## 5. Output the Verdict

```
# Gate Check: [From Phase] → [Target Phase]

> **Verdict**: [PASS | CONCERNS | NOT ASSESSED | FAIL]

**Date**: [date]
**Target**: `[target]` · **Departure phase checked**: `[departure]`
**Gate reference**: `.claude/skills/gate-check/references/gate-[target].md`
**Checked by**: gate-check skill
**Resolved**: workflow [tier] · qa.level [level] · review_mode [mode] · performance.enforce [value]
**Conditions**: UI [yes / no / asked] · Backend [...] · PII [...] · Stores [...] · Regions [...] · Multi-locale [...]

## Required Artifacts: [X/Y present]
- [x] production/sprints/sprint-01.md — exists, 3.1KB
- [ ] production/walking-skeleton/report-*.md — MISSING (no walking skeleton report)
- [x] design/ux/ — 5 key-screen specs, app shell and interaction patterns
- N/A — Stores not configured (store records)

## Quality Checks: [X/Y passing]
- [x] Sprint plan references real story paths (12/12 resolve)
- [ ] Every UX `## API Data` operation exists in the contract — `GET /goals/{id}/progress` missing from docs/api/openapi.yaml
- [?] PRDs + architecture + API + epics coherent — MANUAL CHECK NEEDED
- NOT CHECKED — DD-DESIGN-LANGUAGE skipped (lean mode)

## Director Panel
[summary from Section 4b, with the omissions named]

## Blockers
1. **No walking skeleton report** — Run `/walking-skeleton` to deploy the thin
   sign-in → create-goal → save path to staging through CI before entering Build.
2. **Contract gap for the goal progress screen** — Run `/api-design reconcile`
   before stories that call it are picked up.

## Recommendations
- [Priority actions to resolve blockers]
- [Optional improvements that aren't blocking]

## Verdict: [PASS / NOT ASSESSED / CONCERNS / FAIL]
- **PASS**: All required artifacts present, all quality checks passing
- **CONCERNS**: Minor gaps exist but can be addressed during the next phase
- **FAIL**: Critical blockers must be resolved before advancing
- **NOT ASSESSED**: One or more required checks could not be run at all — name
  which, and why, in the Blockers section

Chain-of-Verification: [N] questions checked — verdict [unchanged | revised from X to Y]
```

**`NOT ASSESSED` — when the gate could not look.** Rank: it **outranks PASS**
(a gate that could not check part of its scope has not established the phase is
ready) and **ranks below CONCERNS and FAIL** (a known blocker is more actionable
than an unknown, and demoting it behind an access problem buries it). It is not a
softer FAIL: "I checked and found a blocker" and "I could not check" need
different fixes — one needs work done, the other needs the input produced or made
readable.

**Verdict precedence — first matching rule wins**, evaluated in this order:
**FAIL**, then **CONCERNS**, then **NOT ASSESSED**, then **PASS**. A gate with
both a real blocker and an unassessable check is FAIL: the blocker is the
actionable finding. Stating the order mechanically removes the inference — the
rank sentence above says what outranks what, but only an ordered list says what
to do when two conditions hold at once.

Emit it when any of:

- A **required artifact exists but cannot be assessed** — empty, unreadable, or
  still entirely `[TO BE CONFIGURED]` / template placeholders. Present-but-empty
  is the case that most looks like present. The same holds when
  `artifact-check.sh` could not evaluate the departure phase at all (non-zero
  exit, or `STEPS: 0`).
- A **quality check's input carries no measured data**. Section 3 compares the
  performance budgets against the newest `/perf-profile`, `/bundle-audit` and
  `/load-test` reports — and a report whose `## Budgets` rows are still template
  placeholders, or whose `## Measurements` table is empty, can still render a
  comfortable headroom figure from zero measurements. Placeholder numbers are not
  measurements: a budget nobody set is not a budget that was met. Absent data
  already prompts (Section 4 offers to run `/perf-profile`); this covers data that
  is *present and hollow*, which is the case that looks like a measurement.
- A **test check the tier requires could not be executed** — no test runner is
  configured (`commands.test` unset), or the runner is configured but failed to
  start. Section 3 runs the suite only when a runner is configured, and an
  unconfigured runner produced no failures, so the test check contributed nothing
  to the verdict and the gate could still reach PASS. Meanwhile
  `testing.strict.logic`, `.integration` and `.e2e` all default to `true`, so the
  project's own configuration called those gates BLOCKING. A blocking gate that
  never ran is the unknown this verdict exists to name. Remediation is already
  listed under Follow-Up Actions (`/test-setup`); this is what the verdict does
  with it.

  > **Scope this to tiers that require tests.** At `qa.level: minimal` no test
  > gates apply at all (see the config block above), so a missing runner there is
  > the configured posture, not a hole — firing the trigger would make every
  > `minimal` gate permanently NOT ASSESSED and stop stage advancement, the same
  > over-broad reading the director trigger below warns against. Fires only where
  > the resolved tier actually asked for the test check.
- A **`MANUAL CHECK NEEDED` item the user never resolved**. Section 4 already
  refuses to assume PASS for unverifiable items and marks them this way — and
  this is where an unresolved one goes, instead of landing inside PASS, CONCERNS
  or FAIL anyway. An unanswered condition question (Section 1) is one of these.
- A director the **resolved width was supposed to spawn** did not return — it
  errored, produced no verdict, or its first line did not parse.

  > **Scope this narrowly, and do not read it as "fewer than four directors ran".**
  > Section 4b narrows the panel *by design* — 1 director at `minimal`, 2 at
  > `standard`, 4 at `full`, design-director omitted without a UI surface, and none
  > in `solo` — and that narrowing is a deliberate, announced reduction, not a
  > failure to assess. The broad reading makes every `minimal`, `standard` and
  > `solo` gate permanently NOT ASSESSED, which means the verdict can never be PASS
  > and Section 6 can never advance `project.stage`. **That would break stage
  > advancement for most projects,** since those are the common tiers. The trigger
  > fires only when a director the width *did* call for fails to come back — a
  > hole in the panel you expected, never the panel you deliberately chose.
- A referenced upstream verdict is itself `NOT ASSESSED` — a smoke report, a
  walking skeleton report, a security audit or a load test that says it could not
  assess propagates upward rather than resolving to a pass.

Never resolve an unknown by assuming the permissive reading. If the check could
not run, that fact is the finding.

---

## 5a. Chain-of-Verification

After drafting the verdict in Phase 5, challenge it before finalising.

**Step 1 — Generate 5 challenge questions** designed to disprove the verdict:

> **Tool-action requirement**: At least 2 of the 5 challenge questions below must be answered by re-reading a specific file (Read tool) or re-running a specific check (Grep tool) — not by reflection alone. Mark these with [TOOL ACTION] to indicate a tool was used.

For a **PASS** draft:
- "Which quality checks did I verify by actually reading a file, vs. inferring they passed?"
- "Are there MANUAL CHECK NEEDED items I marked PASS without user confirmation? [TOOL ACTION] Re-scan the checklist for any [?] or MANUAL CHECK items."
- "Did I confirm all listed artifacts have real content, not just empty headers? [TOOL ACTION] Re-read the file and check it has non-placeholder content."
- "Could any blocker I dismissed as minor actually prevent the phase from succeeding?"
- "Which single check am I least confident in, and why?"

For a **CONCERNS** draft:
- "Could any listed CONCERN be elevated to a blocker given the project's current state?"
- "Is the concern resolvable within the next phase, or does it compound over time?"
- "Did I soften any FAIL condition into a CONCERN to avoid a harder verdict?"
- "Are there artifacts I didn't check that could reveal additional blockers?"
- "Do all the CONCERNS together create a blocking problem even if each is minor alone?"

For a **FAIL** draft:
- "Have I accurately separated hard blockers from strong recommendations?"
- "Are there any PASS items I was too lenient about?"
- "Am I missing any additional blockers the user should know about?"
- "Can I provide a minimal path to PASS — the specific 3 things that must change?"
- "Is the fail condition resolvable, or does it indicate a deeper product or architecture problem?"

**Step 2 — Answer each question** independently.
Do NOT reference the draft verdict text — re-check specific files or ask the user.

**Step 3 — Revise if needed:**
- If any answer reveals a missed blocker → upgrade verdict (PASS→CONCERNS or CONCERNS→FAIL)
- If any answer reveals a check that **could not be run** rather than one that
  ran and passed → PASS→NOT ASSESSED. The first two PASS-draft questions above
  ("verified by actually reading a file, vs. inferring", "MANUAL CHECK NEEDED
  items I marked PASS") exist to find exactly this
- If any answer reveals an over-stated blocker → downgrade only if citing specific evidence
- Never revise NOT ASSESSED down to PASS by re-reasoning about the missing input.
  Only obtaining the input clears it
- If answers are consistent → confirm verdict unchanged

**Step 4 — Note the verification** in the final report output:
`Chain-of-Verification: [N] questions checked — verdict [unchanged | revised from X to Y]`

---

## 5b. Save the Report

After Section 5a finalises the verdict, present the full report, then ask:
"May I write this to `production/gate-checks/gate-<target>-YYYY-MM-DD.md`?"
(`<target>` is the target phase id, e.g. `gate-build-2026-11-18.md`.) The file
starts with the `# Gate Check: …` H1 and, directly under it after one blank line,
the line `> **Verdict**: <TOKEN>` with the final token — `/rollout-plan` and
other readers parse that line. If the user overrides a non-PASS verdict and
advances anyway, record that decision and the accepted risks in the report.

---

## 6. Update Stage on PASS

When the verdict is **PASS** and the user confirms they want to advance, write the
new stage to `project.yaml`. The stage value is the target phase's label:
`Definition`, `Architecture`, `Validation`, `Build`, `Hardening` or `Launch`.
Never write the stage on CONCERNS, FAIL or NOT ASSESSED.

**Always ask before writing**: "Gate passed. May I update `project.stage` in `project.yaml` to '<Stage>'?"

### 6.1 Write `project.stage`

Set `project.stage` to the new stage name in `project.yaml` at the repo root.

- **If a `project:` block already exists**: Read `project.yaml` first (the Edit
  tool requires the file to have been read in this session), then use the Edit
  tool to change its `stage:` value (add a `stage:` line to the block when it has
  none).
- **If `project.yaml` exists but has no `project:` block**: Read `project.yaml`
  first, then use the Edit tool to insert the block immediately after the
  `framework:` block (before `modes:` when one exists). Insert exactly (replace
  `<Stage>`):
  ```yaml
  project:
    stage: <Stage>
  ```
- **If `project.yaml` does not exist at all**: do not recreate it from memory —
  it ships with the framework and carries `schema_version` and `framework.*`,
  which this skill must not invent. Tell the user the file is missing, keep the
  gate report, and stop the stage update.

### 6.2 Write nothing else

The write touches `project.stage` only. Never seed any of the six knobs
`modes.rigor` fronts (`modes.review_mode`, `modes.workflow`, `docs.density`,
`qa.level`, `modes.story_granularity`, `team.size`) — an explicit value would
shadow the rigor expansion and pin that knob regardless of the project's rigor.
Never keep a second copy of the stage anywhere else, and never write the
condition answers gathered in Section 1 (`/setup-stack` owns those keys).

### 6.3 Verify the write

Read `project.yaml` again and confirm `project.stage` shows the new stage. Then
run `bash .claude/scripts/stage-estimate.sh` and confirm it prints
`STAGE: <Stage>` with `SOURCE: project.yaml` — the estimator accepts only the
seven stage values, so a mistyped or invalid write shows up as
`SOURCE: estimated`. If either check disagrees, report the discrepancy to the
user and stop — a stage record that does not say what the gate decided corrupts
every later estimate.

### 6.4 Rigor-fit check (advisory — never affects the verdict)

After the stage advance is confirmed, apply the raise trigger in
`.claude/docs/settings-guidance.md` § 4: if the new stage is **Build** (or
later) while the resolved `workflow` line reads `minimal (rigor:minimal)` — the
`rigor: minimal` posture, from the config block above — add one line:

> "You're entering [stage] on `rigor: minimal` — most products at this stage run
> `standard`. Revisit with `/settings modes.rigor=standard`?"

Offer it **once**, here at the gate. Route to `/settings` — never change the
setting yourself.

---

## 7. Closing Next-Step Widget

After the verdict is presented, the report is saved and any stage update is
complete, close with a structured next-step prompt using `AskUserQuestion`.

**Tailor the options to the gate that just ran:**

For **definition PASS**:
```
Gate passed. What would you like to do next?
[A] Run /map-features — decompose the brief into features with MVP / Beta / GA / Later tiers (recommended next step)
[B] Revisit the product brief first — /prd-review design/product/product-brief.md
[C] Stop here for this session
```

> **Note for definition PASS at `minimal`**: there is no feature map or PRD at
> this tier — the one-pager is the design record. Offer `/gate-check architecture`
> instead of `/map-features`; that gate is not applicable at `minimal` and passes
> with a note.

For **architecture PASS**:
```
Gate passed. What would you like to do next?
[A] Run /create-architecture — the architecture blueprint, docs/ops/slo.md and the prioritized ADR list (required first)
[B] Run /architecture-decision [decision] — record the Foundation-layer ADRs (identity & auth, primary data store, API style, deployment topology, observability)
[C] Run /api-design new, /data-model and /test-setup — the initial API contract, the data model, and the test and CI scaffold
[D] Stop here for this session
```

> **Note for architecture PASS**: `/create-architecture` is the required next step
> before writing any ADRs. It produces the architecture document, the SLO doc and
> a prioritized list of ADRs to write. Running `/architecture-decision` without
> this step means writing ADRs without a blueprint — skip it at your own risk.
> `/test-setup` (runners per layer and the CI workflow) closes the Architecture
> phase; the Architecture → Validation gate requires it.

For **validation PASS**:
```
Gate passed. What would you like to do next?
[A] Run /design-language — the design language every UI story builds on (UI surfaces; do this first)
[B] Run /ux-design [screen] — key-screen specs, then /ux-design shell and /ux-design patterns
[C] Run /walking-skeleton — the thin end-to-end path deployed to staging through CI
[D] Stop here for this session
```

> **Note for validation PASS**: the Validation sequence proves the path before the
> sprint loop commits the team:
>
> 1. `/ui-inventory` — screens per surface and media assets (optional; the source of truth for UX spec coverage)
> 2. `/design-language` — the design language (UI surfaces; sections 1–5 at `standard`)
> 3. `/ux-design [screen]` — sign-up/sign-in, onboarding, the core flow, settings/account; then `/ux-design shell` and `/ux-design patterns`; `/ux-review` each key spec
> 4. `/usability-report` — 3–5 target users on a clickable prototype (optional)
> 5. `/api-design reconcile` — reconcile the contract with each key spec's `## API Data` section
> 6. `/create-epics layer: foundation` then `/create-epics layer: core`; `/create-stories [epic-slug]` for each epic
> 7. `/sprint-plan new` — the first sprint
> 8. `/walking-skeleton` — UI → API → DB plus observability and a flag, deployed to staging through CI/CD, rolled back once (can run alongside steps 2–7 as Sprint 0)
>
> **Why prove the path before Build?** Every later gate assumes staging, a
> deployment pipeline, observability and feature flags exist. If the walking
> skeleton shows the architecture cannot carry the core journey, stories written
> against it are partly wrong — find that out in Sprint 0, not Sprint 4.

For **build PASS**:
```
Gate passed. What would you like to do next?
[A] Run /sprint-plan — plan the current sprint from the ready stories
[B] Run /dev-story [story-path] — pick the next ready story and implement it
[C] Stop here for this session
```

For **hardening PASS**:
```
Gate passed. What would you like to do next?
[A] Run /team-hardening — the coordinated performance, reliability, security, accessibility and regression pass
[B] Run /security-audit full — the audit the launch gate requires
[C] Run /load-test — load, stress and soak profiles against staging
[D] Stop here for this session
```

For **launch PASS**:
```
Gate passed. What would you like to do next?
[A] Run /team-release — execute the release train and the rollout plan, recording every stage
[B] After the rollout completes, run /retrospective release <version> — outcomes against each shipped PRD's success metrics
[C] Stop here for this session
```

> **Note for launch PASS**: Launch is terminal — no further phase gate. Every
> subsequent release repeats `/release-checklist` → `/rollout-plan` →
> `/team-release` under `production/releases/<version>/`; those are records, not
> gates.

When the verdict is **not PASS**, offer the remediation skills for the top two
blockers (Section 8), "Re-run `/gate-check <target>` after fixing", and "Stop here".

---

## 8. Follow-Up Actions

Based on the verdict, suggest specific next steps:

- **No product brief (or one-pager)?** → `/brainstorm` to create one
- **Brief not reviewed?** → `/prd-review design/product/product-brief.md`
- **Riskiest assumption untested?** → `/prototype` (clickable, fake door, concierge or code spike)
- **Stack not pinned, or VERSION.md rows unsourced?** → `/setup-stack` (or `/setup-stack refresh` after a Data or Infra ADR)
- **No feature map?** → `/map-features` to decompose the brief into features
- **Missing PRDs?** → `/write-prd [feature]`, `/reverse-document prd [path]` for code that already exists, or delegate to `product-manager`
- **Small change needed?** → `/quick-spec` for a config change, behaviour tweak or small enhancement (bypasses the full PRD pipeline)
- **PRDs not reviewed?** → `/prd-review design/prd/[feature].md`
- **PRDs not cross-reviewed?** → `/review-all-prds` (run after all MVP PRDs are individually approved)
- **Cross-PRD consistency issues?** → fix the flagged PRDs, then re-run `/review-all-prds`
- **No architecture document or SLO doc?** → `/create-architecture` for the full blueprint and `docs/ops/slo.md`
- **Missing ADRs?** → `/architecture-decision` for individual decisions
- **ADRs missing `## Stack Compatibility` or `## PRD Requirements Addressed`?** → `/architecture-decision retrofit <path>` for each such ADR
- **No API contract, or a UX spec calls an operation the contract lacks?** → `/api-design` (`new` in Architecture, `reconcile` in Validation)
- **No data model or migration plan?** → `/data-model` (`model`, `migration <slug>`)
- **No threat model?** → `/security-audit threat-model`
- **No traceability index or architecture review?** → `/architecture-review`
- **Missing control manifest?** → `/create-control-manifest` (requires Accepted ADRs)
- **No accessibility requirements doc?** → `/ux-design accessibility` (commits `accessibility.target`)
- **No test framework or CI workflow?** → `/test-setup` to scaffold runners per layer and the CI workflow
- **No design language?** → `/design-language`
- **No screen inventory?** → `/ui-inventory`
- **No UX specs?** → `/ux-design [screen name]`, `/ux-design shell` for the app shell, `/ux-design patterns` for the interaction pattern library, or `/team-ui [feature]` for the full pipeline
- **UX specs not reviewed?** → `/ux-review [file]` or `/ux-review all`
- **No user journey map?** → `/ux-design journey` (writes `design/product/user-journey.md`)
- **No usability evidence?** → `/usability-report` (usability, beta or interview)
- **Missing epics?** → `/create-epics layer: foundation` then `/create-epics layer: core`
- **Missing stories for an epic?** → `/create-stories [epic-slug]` (run after each epic is created)
- **Stories not implementation-ready?** → `/story-readiness` to validate stories before engineers pick them up
- **No sprint plan?** → `/sprint-plan new`
- **No walking skeleton?** → `/walking-skeleton`
- **No risk register?** → author `production/risk-register/<risk-slug>.md` from `.claude/docs/templates/risk-register-entry.md` (`/sprint-plan` offers one)
- **Tests failing?** → delegate to `tech-lead` or `qa-engineer`
- **No smoke report?** → `/smoke-check`
- **No QA plan for the current sprint?** → `/qa-plan sprint` to generate one before implementation begins
- **Unresolved S1/S2 bugs?** → `/bug-triage`, then fix through `/dev-story`
- **Implementation coverage unknown?** → `/feature-audit` (planned versus implemented)
- **Performance unknown?** → `/perf-profile`; bundle and app size → `/bundle-audit`; capacity → `/load-test`
- **Pricing, limits or promotions inconsistent?** → `/business-rules-check`
- **No hardening report?** → `/team-hardening`
- **No security audit?** → `/security-audit full` (`quick` suffices at `minimal`)
- **No QA sign-off?** → `/team-qa`
- **No runbooks for the paging alerts?** → `/incident runbook [alert-slug]`
- **Not localized, or no localization QA?** → `/localize scan`, then `/localize qa`
- **No release notes?** → `/changelog [version]` (writes the `## [<version>]` section of `docs/CHANGELOG.md`), then `/release-notes [version]`
- **No release checklist, rollout plan or launch checklist?** → `/release-checklist`, `/rollout-plan`, `/launch-checklist`
- **Need a quick sprint check?** → `/sprint-status` for current sprint progress snapshot

---

## Collaborative Protocol

This skill follows the collaborative design principle:

1. **Scan first**: Check all artifacts and quality gates
2. **Ask about unknowns**: Don't assume PASS for things you can't verify — unset conditions included
3. **Present findings**: Show the full checklist with status
4. **User decides**: The verdict is a recommendation — the user makes the final call
5. **Get approval**: "May I write this to `production/gate-checks/gate-<target>-YYYY-MM-DD.md`?" before the report, and the Section 6 question before the stage write
6. **Never auto-fix**: If required artifacts are missing, report the FAIL verdict and
   name the skill to run (e.g. "run `/test-setup`"). Do NOT create missing files or
   re-run the gate automatically. Creating files to manufacture a PASS defeats the
   gate's purpose.

**Never** block a user from advancing — the verdict is advisory. Document the risks
and let the user decide whether to proceed despite concerns.
