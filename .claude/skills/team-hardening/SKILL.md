---
name: team-hardening
description: "Hardening pass: performance, reliability, security quick-audit, accessibility audit, UI consistency, regression."
argument-hint: "[feature, area or release] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, Agent, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskUpdate, Bash(bash "*/.claude/skills/team-hardening/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,team.size,performance.enforce,accessibility,surfaces,stack`

Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

# Team Hardening

If no argument is provided, output usage guidance and exit without spawning any agents:
> Usage: `/team-hardening [feature, area or release]` — e.g. `goals`, `payments`,
> `release 1.0.0`, or `all` for the whole product. Do not use `AskUserQuestion` here;
> output the guidance directly.

When this skill is invoked with an argument, orchestrate the hardening team through a
structured pipeline and produce **one** report:

| Output | Path |
|--------|------|
| Hardening report — the single file; every agent's notes live inside it | `production/qa/hardening-YYYY-MM-DD.md` |
| New defects (only with approval, Phase 4) | `production/qa/bugs/BUG-NNNN.md` |

The report has exactly these sections: `## Performance`, `## Reliability`,
`## Security (quick)`, `## Accessibility`, `## UI Consistency`, `## Regression`,
`## Blockers`. Its verdict (exact tokens): `READY | READY WITH CONDITIONS | NOT READY |
NOT ASSESSED`. The Hardening → Launch gate requires this report with READY or READY
WITH CONDITIONS.

**Decision Points:** At each phase transition, use `AskUserQuestion` to present
the user with the subagents' proposals as selectable options. Write the agents' full
analysis in conversation, then capture the decision with concise labels.
In `collaborative` mode, the user must approve before moving to the next phase.
In `guided` mode the pipeline advances automatically unless a phase is BLOCKED;
in `autonomous` mode it runs end to end, recording each phase outcome via
`log_decision`. Decisions in `automation_always_ask` categories
(`is_always_ask_category` helper) always prompt regardless of mode. See
`.claude/docs/automation-modes.md`.

---

## Phase 0: Resolve Config

Use the resolved block above; do not re-derive its values.

**`review_mode`.** Team skills spawn only the gates `.claude/docs/director-gates.md` § Gate Index lists this skill under (Spawned by column), after the review-mode check (lean suffix rule); team-size scoping never removes a director gate.
The Gate Index lists `/team-hardening` under no gate: **no director gate runs at any review mode.**

Review-mode check (for any gate the run reaches):
- `full` → spawn as normal
- `lean` → **skip every gate whose ID does not end in `-PHASE-GATE`**. Note: `[GATE-ID] skipped — Lean mode`
- `solo` → skip all gates. Note: `[GATE-ID] skipped — Solo mode`

Beyond that check, `review_mode` decides only whether the adversarial review pass runs (Phase 5, `studio`
only): `full` → it runs; `lean` or `solo` → it is skipped and the report says
`Adversarial review skipped — <Mode> mode`.

**`automation`** drives the Decision Points note above.

**`team.size`** decides which agents are active (orthogonal to review-mode depth). When
it is unset, `modes.rigor` supplies it (`minimal` and `standard` → `individual`, `full`
→ `studio`).

| `team.size` | Active set |
|-------------|------------|
| `individual` | `performance-engineer` runs the pipeline. Sections outside its domain are covered by it as the nearest core agent — the mechanical checks (test suites, scanners, axe, header checks) plus the current reports of the dedicated skills — each carrying the note `covered by performance-engineer — <specialist> not spawned at team.size individual`; a check that needs the specialist's judgment (a manual screen-reader pass, a design-language review) is listed under `Not checked` with the specialist named |
| `small` | `performance-engineer` ∥ `sre-engineer` ∥ `security-engineer` (quick audit) ∥ `accessibility-specialist` → `qa-engineer` (regression; also covers UI Consistency through the visual-regression suite, with the note `design-engineer not spawned at team.size small`) |
| `studio` | `small` + `design-engineer` (UI Consistency), the routed stack leads for every configured layer, and the adversarial review pass |

A non-core agent needed at `individual` routes through the nearest active core agent with
an informational note. **"Phase gate" means any phase that ends in an `AskUserQuestion`
decision point before the pipeline advances** — not every phase. Apply the test
literally: if the phase below has no decision point, it is not a gate, and an agent
restricted to "phase gates only" is not spawned for it. This active-set scoping applies
throughout the pipeline below: any phase that names an agent outside the active set
routes through the nearest core agent rather than spawning it. (A phase gate in this
sense is unrelated to gate IDs ending in `-PHASE-GATE`.)

**Announce the active set before Phase 1 — never let the collapse be silent.**
Before spawning anything, state in one line which agents this run will actually
spawn, and which the pipeline below names but will **not** spawn at the resolved
`team.size`. For example:

> `Active set (team.size: <resolved>): <the agents listed for that size above>.`
> `Not spawned this run: <every other agent this pipeline names> — covered by`
> `<nearest active core agent> or marked NOT ASSESSED. Raise team.size (or modes.rigor) to widen.`

Fill it from the table directly above and the agents this file's own pipeline names —
not from an example. The pipeline below reads as a multi-agent fan-out, and at
`individual` it is one agent. **The collapse is correct**: `team.size` is rigor-fronted
and the narrow set is the token lever. What must never happen is that nothing says so,
so a reader cannot distinguish a correctly collapsed run from a broken pipeline — the
per-agent routing note fires at routing time and never states the shape of the run as a
whole. **A constraint that is enforced but never surfaced is indistinguishable, to the
person reading the output, from one that was never enforced.** The same line goes into
the report header.

**`performance.enforce`** scores `## Performance`: a budget breach is a Blocker
(`block`), a Condition (`warn`), or recorded and not scored (`off` — the section says
`Budgets not scored — performance.enforce: off`). It is locally overridable, so use the
resolved line.

**`accessibility`** — the line `accessibility.target: <v>` sets the audit level
(`wcag-a`, `wcag-aa`, `wcag-aaa` — WCAG 2.2). `(unset -- ask; unset is not none)` ⇒ ask
with `AskUserQuestion` which target applies; without an answer, `## Accessibility` is
`NOT ASSESSED — accessibility.target unset`. `none` ⇒ `## Accessibility` is
`N/A — accessibility.target: none` (the regional standards listed in
`design/accessibility-requirements.md`, if any, are still named in the section).

**Surfaces and stack layers** — from the resolved `platform.surfaces` and `stack` lines:
the UI sections (Accessibility and UI Consistency) apply only when web, ios or android
ships (unset ⇒ ask, never assume "no UI"); a layer listed under `unset=` is not
configured (`stack: unset — run /setup-stack` ⇒ no layer is); the `[routing: …]` part
names the `studio` stack leads.

---

## Team Composition

- **performance-engineer** — budgets against measurements (API latency and error rate,
  Core Web Vitals, bundle size, cold start, crash-free sessions), profiling, capacity
- **sre-engineer** — SLOs and alerts per critical journey, runbooks, on-call, backup and
  restore, resilience to dependency failure, rollback
- **security-engineer** — the quick security audit: secrets, dependency vulnerabilities,
  security headers
- **accessibility-specialist** — audit against `accessibility.target` on the critical
  journeys, automated and manual
- **design-engineer** (`studio`) — UI consistency against the design language and the
  component library; visual regression
- **qa-engineer** — regression and exploratory testing on the critical journeys, bug
  drafts; at `studio`, a second instance runs the adversarial review
- **Stack leads** (`studio`, one per configured layer) — `web-specialist`,
  `mobile-specialist`, `backend-specialist`, `data-specialist`, `cloud-specialist`: the
  layer-specific hardening checks listed in Phase 2. A layer that is not configured gets
  `NOT CHECKED — <layer> layer not configured (run /setup-stack)`.

## How to Delegate

Use the `Agent` tool to spawn each team member as a subagent:
- `subagent_type: performance-engineer` — performance budgets and measurements
- `subagent_type: sre-engineer` — reliability
- `subagent_type: security-engineer` — quick security audit
- `subagent_type: accessibility-specialist` — accessibility audit
- `subagent_type: design-engineer` — UI consistency (`studio`)
- `subagent_type: qa-engineer` — regression, exploratory testing, adversarial review
- `subagent_type: web-specialist` / `mobile-specialist` / `backend-specialist` /
  `data-specialist` / `cloud-specialist` — layer checks (`studio`)

**Brief each agent — do not dump context.** Read the shared inputs **once** (Phase 1) and
pass a distilled brief inline: the lines each agent actually needs, never a file path for
a document you have already read (an agent handed a path re-reads the whole file). Pass a
path only for a document you have not read and only that agent needs.

**End every agent prompt with a return contract:** "Do not write any file — this
pipeline has one report, and the orchestrator writes it; your notes go inside it, never
in a separate file. Return **only** (1) the body of your section in the format below,
(2) a ≤5-bullet summary of decisions, (3) any BLOCKED/CONCERNS items, one line each. Do
not restate the documents you read."

Section body format (every agent, every section):

```markdown
**Status**: [OK | CONDITIONS | BLOCKERS | NOT ASSESSED — <reason> | N/A — <reason>]
**By**: [agent] [routing note, when routed]

| # | Finding | Class | Evidence | Owner | Due |
|---|---------|-------|----------|-------|-----|
| P-1 | [..] | [Blocker / Condition / Note] | [command run and result, report path, screenshot or trace] | [role] | [date or —] |

Evidence used: [artifact paths with their dates and verdicts; commands run]
Not checked: [each skipped check with its reason]
```

Launch independent agents in parallel (Phase 2 is one parallel fan-out); collect every
result before Phase 3.

Track the pipeline with tasks: `TaskCreate` one task per report section in Phase 1,
`TaskUpdate` each as its section returns or blocks, and `TaskList` before Phase 6 — a
section still open at consolidation is `NOT ASSESSED — <agent> did not return`.

---

## Pipeline

### Phase 1: Scope and Inputs

The orchestrator reads the shared inputs once and records each as `FOUND` or `ABSENT`,
with its date:

- scope: the features, area or release in the argument (`release <version>` → the PRDs
  and stories shipped in it; `all` → every MVP-tier feature in
  `design/product/feature-map.md`);
- `docs/ops/slo.md` — `## Critical User Journeys`, `## SLIs & SLOs`,
  `## Dashboards & Alerts`, `## On-call`, `## Error Budget Policy`;
- `performance.*` budgets in `project.yaml` (read with Read, each key spelled in full);
- the newest reports: `production/qa/perf/perf-profile-*.md`,
  `production/qa/perf/bundle-audit-*.md`, `production/qa/load/load-test-*.md`,
  `production/security/security-audit-*.md`, `production/qa/smoke-*.md`,
  `production/qa/qa-plan-*.md`, `production/qa/feature-audit-*.md`, and the UX review
  records in `design/ux/reviews/`;
- `docs/ops/runbooks/`, `design/accessibility-requirements.md`,
  `design/brand/design-language.md`, `design/ux/interaction-patterns.md`,
  `tests/regression-suite.md`;
- bugs in `production/qa/bugs/` whose `**Status**:` is unresolved (`Open`,
  `In Progress`, `Fixed — Pending Verification`), by severity;
- the build under test (release candidate version or commit) and the environment
  (staging URL; store test builds).

An artifact older than the build under test is **stale**: an agent may cite it, but
must say so, and re-measure what the verdict depends on.

Announce the active set, create the section tasks, then `AskUserQuestion`:
`Proceed with this scope and active set` / `Adjust the scope` / `Stop`.

### Phase 2: Parallel Assessment

Spawn the active agents in parallel, each with its brief and the section format above.
At `individual`, spawn `performance-engineer` once with every section's brief.

**performance-engineer → `## Performance`**
- Compare every `performance.*` budget in scope with the newest measurements (perf
  profile, bundle audit, load test); re-measure stale rows the verdict depends on,
  following the `/perf-profile` method (production builds, staging or local, never
  production load).
- Unset budget or no measurement ⇒ `NOT ASSESSED — <budget> (unset | unmeasured)`,
  never a pass. Breaches are classed per `performance.enforce`.
- Mobile: cold start and crash-free sessions from the beta or store test build.

**sre-engineer → `## Reliability`**
- Every critical journey has an SLO and an alert on it; every paging alert has a
  runbook in `docs/ops/runbooks/`; an on-call rota exists (`## On-call`).
- Dependencies in the request path (payment gateway, KakaoTalk 알림톡 / SMS / push
  providers, identity verification, OAuth providers) have timeouts, bounded retries
  with backoff, idempotency on payment calls, and a defined degraded mode.
- Backups were actually restored (a restore performed, not only scheduled), with the
  recovery time observed; the rollback path of this release is rehearsed; kill-switch
  flags exist for risky features; capacity headroom from the load-test report.
- Blockers: a critical journey without an alert, a paging alert without a runbook, no
  tested restore (when a backend exists), no rollback path.

**security-engineer → `## Security (quick)`**
- The quick audit scope only: secrets in the repository and build output (a secret
  scanner when installed, else targeted patterns — report the location, never the
  value), dependency vulnerabilities (`pnpm audit` / `npm audit`, `pip-audit`,
  `osv-scanner`, or the ecosystem's equivalent), security headers on staging (CSP,
  HSTS, `X-Content-Type-Options`, `Referrer-Policy`, frame-ancestors).
- Reuse a current `production/security/security-audit-quick-*.md` or `-full-*.md` report
  when it covers this build.
- Open Critical or High findings are Blockers. Say in the section that this is not an
  audit record: the Launch gate requires the `/security-audit` report itself.

**accessibility-specialist → `## Accessibility`** (UI surfaces only)
- Automated: axe results on the key screens (reuse `NN-<state>-axe.json` evidence under
  `production/qa/evidence/` when current; else run axe through Playwright on staging);
  platform scanners on mobile (Xcode Accessibility Inspector, Android Accessibility
  Scanner). Automated tools catch only part of the failures — say so.
- Manual on every critical journey: keyboard only, a screen reader (VoiceOver, TalkBack,
  or NVDA on web), text scaling to 200 % / dynamic type, contrast, and the criteria
  WCAG 2.2 added at or below the committed level — target size (minimum), focus not
  obscured, dragging movements, accessible authentication (allow paste and autofill in
  one-time-code fields), redundant entry, consistent help.
- A failure at the committed level on a critical journey is a Blocker; elsewhere a
  Condition.

**design-engineer → `## UI Consistency`** (`studio`; UI surfaces only)
- Implemented screens against `design/brand/design-language.md` (tokens only, no
  one-off colours or spacing; components from the library) and
  `design/ux/interaction-patterns.md`; loading, empty, error and offline states; dark
  mode where the design language defines it; the visual-regression baselines current
  for this build.
- Reuse the UX review records in `design/ux/reviews/` (their design-director review
  outcome lines); a screen shipped without a review record is a Condition.

**Stack leads** (`studio`, per configured layer; their notes go into `## Performance`
or `## Reliability`, tagged with the layer)
- `web-specialist` — caching and CDN headers, server-rendering error handling and
  error boundaries, public source maps, image and font configuration.
- `mobile-specialist` — release build configuration (shrinking, signing), crash and
  ANR rates from the beta, permission prompts, deep links, the force-update path,
  offline and sync conflicts.
- `backend-specialist` — connection pools, timeouts, background job retries and
  dead-letter handling, graceful shutdown.
- `data-specialist` — slow queries, index health, backups and point-in-time recovery,
  the state of each migration's expand and contract phases.
- `cloud-specialist` — autoscaling limits and service quotas, drift between the
  infrastructure code and what runs, cost anomalies, zone redundancy.

When all have returned, present every section and `AskUserQuestion`:
`Accept the Blocker / Condition classification` / `Reclassify (say which)` / `Stop`.
A check listed under `Not checked` may be carried as a Condition — "<check> not yet
performed" with an owner and a due date before launch — only when the user explicitly
accepts it here; otherwise its section stays `NOT ASSESSED`.

### Phase 3: Remediation (optional)

For each Blocker, `AskUserQuestion`:
- `Fix now` — the owning agent drafts the change (files and diff summary); the user
  approves that change set; the agent applies it; Phase 4 re-verifies it. Only for
  small, contained fixes (a header, a timeout, a missing alert rule) — anything larger
  becomes a bug or a story.
- `File a bug` — drafted in Phase 4 and written after approval; the finding stays a
  Blocker until the fix is verified.
- `Accept as a condition` — an explicit reclassification by the user, with an owner and
  a due date before launch.
- `Descope` — run `/scope-check`, record the decision, and remove the finding from this
  release's scope only when the scope change is approved.

Launch with an unresolved Blocker is not an option this skill offers: a Blocker that is
neither fixed nor reclassified keeps the verdict at NOT READY.

### Phase 4: Regression and Verification

Delegate to **qa-engineer** (`performance-engineer` at `individual`, with its routing
note):
- Run the automated suites — `commands.test` and `commands.e2e` from `project.yaml`
  (read with Read) — against the build under test; unset commands ⇒
  `NOT ASSESSED — commands.test / commands.e2e unset (run /test-setup)`.
- Every critical journey in `docs/ops/slo.md` has a passing E2E test; the newest smoke
  report covers this build with PASS or PASS WITH WARNINGS.
- Fixed bugs listed in `tests/regression-suite.md` still have their regression tests.
- Re-verify each Phase 3 fix.
- Exploratory charter on the critical journeys: network loss and slow networks,
  backgrounding the app mid-flow, session expiry, double submit, the same account on two
  devices, the day and month boundary in Asia/Seoul, locale switch, permission denial
  (push, camera), a deep link into a screen that needs sign-in, parity between web and
  the store builds.
- At `small`, also `## UI Consistency` through the visual-regression suite, when one
  exists (else `NOT ASSESSED — design-engineer not spawned at team.size small; no
  visual-regression suite`).
- Unresolved bugs: an unresolved `S1-Critical` is a Blocker; an unresolved `S2-Major` is
  a Condition that must close before launch.
- New defects are returned as **bug drafts** (title; `**Severity**: [S1-Critical /
  S2-Major / S3-Minor / S4-Trivial]`; `**Priority**: [P1-Fix this sprint / P2-Fix soon /
  P3-Backlog / P4-Won't fix]`; `**Status**: Open`; environment and build; steps to
  reproduce; expected and actual; evidence).

The orchestrator then offers `Write the bug reports` / `Hand them to /bug-report` /
`Skip`. Writing: find the highest existing `BUG-NNNN` in `production/qa/bugs/`, number
the drafts from the next one (four digits), and ask
"May I write these to `production/qa/bugs/BUG-NNNN.md` … `BUG-NNNN.md`?" before writing them.

### Phase 5: Adversarial Review (`studio`, `review_mode: full`)

Spawn a fresh **qa-engineer** with the consolidated draft (inline). Brief: *"Try to
falsify READY. For each section: is the evidence measured rather than assumed, current
for this build, taken on staging or better, and does it cover every critical journey?
Return each challenge with the evidence that would settle it."* Each challenge the user
accepts becomes a Blocker or a Condition. At `lean` or `solo`, write
`Adversarial review skipped — <Mode> mode`; below `studio`, write
`Adversarial review not run — team.size <resolved>`.

### Phase 6: Consolidate and Write

**Verdict** (precedence **NOT READY > NOT ASSESSED > READY WITH CONDITIONS > READY**;
`N/A` sections do not count):

| Verdict | When |
|---------|------|
| `NOT READY` | At least one Blocker in any section |
| `NOT ASSESSED` | No Blocker, but at least one in-scope section is `NOT ASSESSED` |
| `READY WITH CONDITIONS` | Every in-scope section assessed, no Blocker, at least one Condition — each with an owner and a due date |
| `READY` | Every in-scope section assessed, no Blocker, no Condition |

Assemble the report and ask: "May I write this to `production/qa/hardening-YYYY-MM-DD.md`?"
If a report for today exists, ask before replacing it (a rerun after fixes supersedes it;
git keeps the earlier one).

```markdown
# Hardening Report: [scope]

> **Verdict**: [READY | READY WITH CONDITIONS | NOT READY | NOT ASSESSED]

> **Date**: [YYYY-MM-DD]
> **Scope**: [feature | area | release <version> | all]
> **Build**: [release candidate version / commit SHA — web, iOS build, Android build]
> **Environment**: [staging URL; store test tracks]
> **Team size**: [resolved line] — active: [agents]; not spawned: [agents, with how each section was covered]
> **Review mode**: [resolved] — adversarial review: [ran | skipped — <Mode> mode | not run — team.size <v>]
> **Enforcement**: performance.enforce = [warn | block | off]
> **Accessibility target**: [resolved line]
> **Generated by**: /team-hardening

## Performance

[section body from performance-engineer, plus stack-lead notes tagged by layer]

## Reliability

[section body from sre-engineer, plus stack-lead notes tagged by layer]

## Security (quick)

[section body from security-engineer — not an audit record; see /security-audit]

## Accessibility

[section body from accessibility-specialist]

## UI Consistency

[section body from design-engineer, or qa-engineer at small]

## Regression

[section body from qa-engineer — suites run, journeys covered, bugs filed]

## Blockers

| # | Section | Blocker | Owner | Resolution path |
|---|---------|---------|-------|-----------------|

### Conditions

| # | Section | Condition | Owner | Due |
|---|---------|-----------|-------|-----|

### Adversarial Review

[challenges and their resolution — or the skip / not-run line]
```

After writing, verify the file exists, that the verdict line sits directly under the H1,
and that all seven `##` sections are present — a section missing from the written file is
a failed phase, not an empty result.

### Phase 7: Sign-off and Next Steps

Report the verdict, the Blockers and the Conditions in the conversation, then
`AskUserQuestion` with the options that apply:

- READY or READY WITH CONDITIONS:
  - `/release-checklist <version>` — the per-release checklist (Recommended)
  - `/rollout-plan <version>` — staged rollout with the production readiness review
  - `/launch-checklist <version>` — first public launch
  - `/gate-check launch`
- NOT READY:
  - `/bug-report` or `/dev-story <story>` — fix the Blockers, then rerun `/team-hardening`
  - `/scope-check` — when a Blocker is better descoped
- NOT ASSESSED — run what was missing:
  - `/perf-profile`, `/bundle-audit` or `/load-test` (performance evidence)
  - `/security-audit full` (the audit record the Launch gate requires at `workflow`
    `standard` and `full`) — or `/security-audit quick`, which satisfies it only at
    `minimal`
  - `/ux-design accessibility` or `/ux-review` (accessibility target and review records)
  - `/create-architecture` (SLO document) or `/incident runbook <alert-slug>` (missing runbooks)
  - `/test-setup` (no test commands) or `/smoke-check` (no current smoke report)
- `Stop here`

---

## Error Recovery Protocol

**First, verify the return.** An agent's return contract is its section body. A reply
without one — however fluent the preamble — is a failed phase: it is neither BLOCKED nor
an error nor "cannot complete", so the trigger below never fires. Resume the agent
naming the unmet contract; the context is usually still there. The same holds for this
skill's one named artifact: **a report path that is not on disk after the write is a
failed phase.**

If any spawned agent returns BLOCKED, errors, or cannot complete: **surface it
immediately, don't proceed past a dependency it blocks, and always produce a partial
report** — its section is `NOT ASSESSED — <agent> blocked: <reason>`. Full procedure:
`.claude/docs/error-recovery-protocol.md`.

Common blockers:
- No SLO document → `## Reliability` is NOT ASSESSED; redirect to `/create-architecture`
- No staging environment or build → live checks are NOT ASSESSED; say which
- A fix needs an architectural change → do not improvise it; run `/architecture-decision`
- An ADR a fix depends on is still Proposed → do not implement; run `/architecture-decision`
- Conflicting instructions between an ADR and a story → surface the conflict, do not guess

## File Write Protocol

This orchestrator writes the hardening report and, with approval, the bug reports —
each after asking "May I write this to `<path>`?". Subagents return content and write
no notes files: the single report holds every agent's notes. A `Fix now` change is
applied by its agent only after the user has approved that exact change set in
Phase 3.

> **The bounded exception, for completeness.** `CLAUDE.md` requires an agent to ask
> "May I write this to [filepath]?" before Write/Edit. A subagent spawned by an
> orchestrator may write **without** asking only when all three are true: (1) the path is
> one the orchestrator named in the prompt, so the user approved the destination when
> they approved the phase; (2) it is a new artifact under `production/`, `docs/` or
> `tests/`, never an edit to existing source or config; (3) the phase that produced it is
> itself gated by an `AskUserQuestion` before the pipeline advances. Outside those three,
> the agent must ask. This skill names no per-agent path, so no subagent uses the
> exception here — which is how the report stays a single file.

## Output

One report at `production/qa/hardening-YYYY-MM-DD.md` with the seven sections and the
verdict line, plus any approved bug reports. The conversation summary names the verdict,
each Blocker and Condition with its owner, the sections that were `NOT ASSESSED` or
covered by a routed agent, and the next step.

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and `autonomous`
modes, see `.claude/docs/automation-modes.md` and the Decision Points note above.

- **Every phase ends in a decision** — scope and active set (Phase 1), classification
  (Phase 2), each Blocker (Phase 3), bug reports (Phase 4), the report (Phase 6).
- **Evidence over assurance** — a section is assessed only from measurements, runs and
  current reports; "looks fine" is not evidence, and an unchecked item is never a pass.
- **No silent collapse** — the active set, every routed section and every skipped check
  are named in the conversation and in the report.
- **Code changes only with approval of the exact change set**; nothing is deployed by
  this skill.
- Ask "May I write this to `<path>`?" before writing the report and before writing bug
  reports.
