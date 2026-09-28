---
name: perf-profile
description: "Measure against performance.* budgets and produce ranked optimization recommendations."
argument-hint: "[surface:<web|ios|android|api> | route:<path> | full]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash, Agent, Bash(bash "*/.claude/skills/perf-profile/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys performance.enforce,automation,surfaces,stack,code_roots`

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

# Performance Profile

Measures the product against its committed `performance.*` budgets — API latency
and error rate, Core Web Vitals and per-route bundle size on the web, cold start and
crash-free sessions on mobile — for one surface, one route or the whole product, and
turns what it finds into ranked, measurable optimization recommendations.

| Output | Path |
|--------|------|
| Profile report (with the verdict line) | `production/qa/perf/perf-profile-<scope>-YYYY-MM-DD.md` |

**When to run:** in Hardening before `/gate-check launch` (the gate reads the newest
report), after a performance fix (rerun the same scope and compare), and whenever
`/team-hardening`, `/load-test` or a user complaint points at a slow journey.

**What this skill is not:** it is not a load test — throughput, saturation and soak
behaviour belong to `/load-test`, whose report this skill reads. Route-level bundle
composition, images, fonts and app size are audited in depth by `/bundle-audit`;
this skill reads the newest bundle-audit report for the `performance.bundle_kb` row
and measures that row itself only when no current report exists.

Verdict vocabulary (exact): `PASS | CONCERNS | FAIL | NOT ASSESSED`.

---

## Insufficient input — check this before producing any report

**If the inputs this skill needs do not exist, the answer is "could not run" —
not a filled-in report.** Check first, and stop if the check fails.

1. List the inputs this skill reads (budgets in `project.yaml`, prior perf-profile,
   bundle-audit and load-test reports, monitoring exports, lab tool output,
   source code in the resolved code roots).
2. For each, record `FOUND` or `ABSENT` — not "assumed present".
3. If any input required for a section is ABSENT, that section is
   **`NOT ASSESSED — NO DATA`**. Do not estimate it, do not infer it from an
   adjacent artifact, and do not leave a mandated cell to be filled by whoever
   reads the template next.
4. If **every** required input is ABSENT, stop and report
   **`NOT ASSESSED — NO DATA`** as the whole verdict, naming what was missing and
   which skill or setting produces it.

**A verdict of `NOT ASSESSED` is a success.** It is the correct, useful answer to
"what does the data say?" when there is no data. The failure mode this prevents is
specific: report templates whose verdict enum had no "could not run" state produced
**false clean passes** — a bundle audit returning PASS on a project with no build
output and no budget, and a performance profile reporting comfortable headroom
against a 2.5-second LCP budget with zero measurements and no budget ever set.

**Absence of evidence is never evidence of absence.** A scan that finds no slow
queries because no code root resolved has not verified anything. Say which of the
two happened — a reader cannot tell from a green result.

---

## Phase 0: Resolve Configuration

Read the resolved block above; do not re-derive any of its values.

**`performance.enforce`** decides what a budget breach *means* in this run. It does
not change which budgets are measured — every budget in scope is measured the same
way at every value:

| Value | Effect on this profile |
|-------|------------------------|
| `warn` | A breach is a finding: it makes the verdict **CONCERNS**. `/gate-check` surfaces it as CONCERNS, not a blocker. |
| `block` | A breach is a failure: it makes the verdict **FAIL**. Say so explicitly in the report — `/gate-check` treats a breach as a blocker at the `hardening` and `launch` gates. |
| `off` | Budgets are informational. Measure and record every value and every breach, but do not score breaches; the report says `Budgets not scored — performance.enforce: off` instead of staying silent. |

The value is locally overridable (`/settings --local performance.enforce=block`), so
use the resolved line, never a direct read of `project.yaml` — a teammate's stricter
local setting is meant to bite on their machine only. If the notes line reports an
invalid value that was dropped, repeat that note in the report header.

**`surfaces`** selects the metric families (Phase 2). If the line says
`platform.surfaces: (unset -- ask which surfaces ship)`, ask the user in plain text
which surfaces ship before profiling — unset is not "web only". Without an answer,
profile only what the argument names and mark every other family
`NOT ASSESSED — platform.surfaces unset`.

**`stack`** selects the measurement tooling (Phase 3). A layer printed under
`unset=` gets no stack-specific profiler: its rows say
`NOT CHECKED — <layer> layer not configured (run /setup-stack)`.

**`code_roots`** lists the directories the static review walks. When the line says
`code_roots: unresolved — NOT CHECKED …`, print that line in the report under
`### Not Checked`, skip the static review, and keep going with measurements —
static findings are candidates, never measurements, so their absence does not stop
a measured profile. If the line lists `undeclared=` roots, include them in the
review and print `WARN: undeclared code roots: <dirs> — declare them with /setup-stack`.

---

## Phase 1: Determine Scope

Parse the argument:

| Argument | Scope | `<scope>` in the file name |
|----------|-------|----------------------------|
| `surface:web` / `surface:ios` / `surface:android` / `surface:api` | Every budget of that surface | `web` / `ios` / `android` / `api` |
| `route:<path>` — a web route (`/goals/[id]`) or an API path (`/v1/goals`) | That route's web metrics, or that operation's latency and error rate | `route-` + the path in kebab-case (`route-goals-id`, `route-v1-goals`) |
| `full` or no argument | Every configured surface | `full` |

A surface named in the argument but absent from a set `platform.surfaces` is
reported as `N/A — <surface> not configured` and the run stops for that surface
(profiling a surface the product does not ship produces numbers nobody owns). When
that leaves nothing in scope, the run ends there with no report and
`Verdict: NOT ASSESSED — nothing to profile (<surface> not configured)`.

Announce the scope in one line before measuring:
`Profiling <scope> — surfaces: <list> — enforcement: <value>`.

---

## Phase 2: Load the Budgets

**Read the committed budgets from `project.yaml` with Read** — they are the project's
record of what it agreed to. None of them has a `resolve_config` label, and
`project.local.yaml` is not consulted for them. Spell each key out in full; a loop
that builds `performance.<leaf>` leaves the full dotted keys spelled nowhere, and the
dead-settings audit (which matches the full dotted key) then reports keys this skill
reads as unused.

| Surface | Budget keys read | Metric and statistic |
|---------|------------------|----------------------|
| api | `performance.api_p95_ms` | Server-side latency, p95, per operation or per critical journey |
| api | `performance.error_rate_pct` | Share of requests failing (5xx and timeouts; 4xx excluded unless the SLO says otherwise) |
| api | `performance.availability_pct` | Availability over the SLO window — measured by monitoring, never by a profile run |
| web | `performance.lcp_ms` | Largest Contentful Paint, p75 |
| web | `performance.inp_ms` | Interaction to Next Paint, p75 |
| web | `performance.cls` | Cumulative Layout Shift, p75 |
| web | `performance.bundle_kb` | Initial JavaScript per route, gzip |
| ios, android | `performance.cold_start_ms` | Cold start to first usable screen |
| ios, android | `performance.crash_free_pct` | Crash-free sessions, per release |

Then read `docs/ops/slo.md` if it exists: `## Critical User Journeys` names the
journeys to profile first, and `## SLIs & SLOs` may carry per-journey targets. When a
per-journey target differs from the `project.yaml` budget, record both in `## Budgets`
and flag the inconsistency — never pick one silently.

**A metric with no committed budget is `NOT ASSESSED — budget unset`, not a pass.**
Do not measure against a placeholder, and do not substitute a published threshold
(for example the Core Web Vitals "good" thresholds on web.dev) as if the project had
chosen it. You may *suggest* such a threshold as a starting point, citing its source,
and name how to commit one: `/settings performance.lcp_ms=<n>`, or `/create-architecture`,
which records budgets alongside `docs/ops/slo.md`.

---

## Phase 3: Gather Measurements

Brief `performance-engineer` via `Agent` once scope and budgets are known. Pass a
distilled brief inline — never a path to a file you have already read:

- scope and surfaces; the `## Budgets` table from Phase 2 (key, value or `unset`);
- the resolved `stack` and `code_roots` lines, as printed;
- the newest `production/qa/perf/perf-profile-*.md`, `production/qa/perf/bundle-audit-*.md`
  and `production/qa/load/load-test-*.md` (paths and dates only, so it can judge staleness);
- `commands.run`, `commands.build` and `commands.test` from `project.yaml` (read with Read);
- the critical journeys from `docs/ops/slo.md`, if any.

End the prompt with the return contract: *"Do not write any file — this skill writes
the report. Return only (1) the Measurements rows in the table format below, each with
the exact command or data source that produced it, (2) up to 10 ranked
recommendations in the format below, (3) any BLOCKED or NOT ASSESSED items, one line
each with the reason."* If the agent returns BLOCKED or errors, run the phase yourself
and write `performance-engineer not consulted — <reason>` in `## Scope`.

### 3a. Evidence ladder (strongest first)

Use the strongest evidence available for each metric and record which rung it came from.

1. **Field data** the user supplies or the repo already holds — real-user monitoring
   (the `web-vitals` library feeding the APM or analytics tool; CrUX for public origins
   with enough traffic), APM exports (Datadog, Grafana/Prometheus, New Relic, Sentry,
   an OpenTelemetry backend), mobile field metrics (Firebase Crashlytics or Sentry
   release health for crash-free sessions; Android vitals in Play Console; Xcode
   Organizer launch times on iOS). This skill **reads exports it is given; it never
   queries a production system itself**.
2. **Lab measurements** run now with Bash against a local production build or a
   staging/preview deployment:
   - **web** — Lighthouse (CLI or Lighthouse CI) for LCP and CLS on the production
     build (`commands.build`, then the production server — a dev server's numbers are
     not representative). **INP is an interaction metric**: a navigation run has none.
     Measure it in the field, or in a Lighthouse user-flow timespan around a scripted
     interaction; never report Total Blocking Time as INP.
   - **android** — cold start on a release build: force-stop the app, then
     `adb shell am start -W` and read `TotalTime`; repeat at least 10 times and report
     the median and the spread. Jetpack Macrobenchmark (`StartupTimingMetric`) is the
     reliable in-repo option when present.
   - **ios** — Instruments (App Launch template) or an XCTest
     `XCTApplicationLaunchMetric` on a release build and a physical device.
   - **React Native / Flutter** — measure release builds only (Hermes bytecode for
     React Native; `--profile`/`--release` for Flutter); debug builds are several
     times slower and invalidate the row.
   - **api** — the newest load-test report is the source for p95 and error rate under
     load. A handful of local requests is not a p95: without a load-test report or APM
     data, the latency row is `NOT ASSESSED — no percentile data (run /load-test)`.
3. **Static review** of the resolved code roots — produces *candidates*, never a
   Measurements cell (Phase 3b).

Record for every measurement: environment (`local`, `preview`, `staging`, or
`production (field data)`), build (commit SHA or app version and build number),
device or emulation profile as the tool names it, network profile, sample size or
window, and the date. Prefer a mid-range Android device (Galaxy A-series class) over a
flagship for mobile and mobile-web rows — that is where budgets are usually breached.

### 3b. Static review targets (candidates to confirm)

Walk the resolved code roots for the surfaces in scope. Each finding names a path and
a function, component or route — never a line number (line numbers go stale).

- **API / backend** — N+1 queries (ORM calls inside loops or per-item resolvers);
  filters and sorts on unindexed columns (confirm with `EXPLAIN (ANALYZE, BUFFERS)` on a
  staging copy or a local database seeded to realistic volume, never on production);
  unbounded list endpoints without pagination; synchronous third-party calls in the
  request path without timeouts (payment, KakaoTalk 알림톡 or push providers, OAuth
  userinfo); missing caching of hot reads; oversized JSON payloads; connection-pool
  sizes against expected concurrency.
- **web** — heavy libraries pulled into the initial route bundle; client components
  or hydration where static or server rendering would do; unoptimized or lazily loaded
  LCP images (the LCP image should load eagerly with high fetch priority);
  render-blocking fonts, including full Korean web fonts without subsetting; layout
  shifts from images, ads or banners without reserved size; long tasks in input
  handlers; third-party tags.
- **mobile** — work on the main thread before the first screen (synchronous storage
  reads, SDK initialisation that could be deferred); large JS bundles in React Native;
  image decoding on the UI thread; unnecessary re-renders in list screens.

Profilers to confirm a candidate, by `stack`: Node.js — `node --cpu-prof` and the
DevTools inspector; JVM — JDK Flight Recorder or async-profiler; Python — py-spy or
pyinstrument; PostgreSQL — `pg_stat_statements` plus `EXPLAIN (ANALYZE, BUFFERS)`.
A candidate that was not confirmed stays in `### Requires Measurement` with its
expected impact marked `estimated`.

---

## Phase 4: Compare and Score

Build `## Breaches` from measured values only. Each budget row gets exactly one status:

- `OK` — measured, within budget (headroom = budget − measured, shown only for measured rows);
- `BREACH` — measured, over budget;
- `NOT ASSESSED — <reason>` — budget unset, or no measurement at the required statistic;
- `N/A — <surface> not configured`.

**Verdict** (precedence **FAIL > CONCERNS > NOT ASSESSED > PASS**):

| Verdict | When |
|---------|------|
| `FAIL` | At least one `BREACH` and `performance.enforce` is `block` |
| `CONCERNS` | At least one `BREACH` under `warn`; or a per-journey SLO contradicts a `project.yaml` budget |
| `NOT ASSESSED` | No scored breach, but at least one in-scope row is `NOT ASSESSED` (a budget unset or a metric unmeasured) — the scope has not been shown to be within budget |
| `PASS` | Every in-scope row is `OK` or `N/A`, with at least one measured row |

Under `off`, breaches are listed but not scored: the verdict is computed as if they
were `OK`, and the report header says so. A row measured only in the lab where the
budget is a field percentile (p75 LCP, p75 INP) is scored, but its statistic column
says `lab` — do not present a single lab run as a p75.

---

## Phase 5: Ranked Recommendations and Decisions

Rank recommendations by **(expected gain against a breached or tightest budget) ÷
effort**, breaches first. Each recommendation carries:

- **Target metric** and the budget row it moves;
- **Location** — path plus function, component or route;
- **Expected gain** — a number with `measured` (confirmed by a profiler or an A/B lab
  run) or `estimated` (static reasoning only);
- **Effort** (S / M / L) and **Risk** (Low / Med / High);
- **Approach** — how to implement it;
- **Verify with** — the exact measurement that will show the gain (rerun this skill
  with the same scope, a Lighthouse run, a load-test profile).

For every recommendation rated M or L that addresses a `BREACH`, present these options
in plain text and wait for the user's reply before writing (in `guided` and
`autonomous` modes follow `.claude/docs/automation-modes.md`; an undecided item is
recorded as `Decision: open`):

- **A) Schedule the fix** — `/quick-spec` for a small change, or a story via
  `/create-stories`, then `/sprint-plan`;
- **B) Reduce scope** — `/scope-check` to weigh the feature against its budget;
- **C) Accept for this release** — recorded in the report as
  `Accepted — <owner>, <target date>`; the breach stays in `## Breaches`;
- **D) Escalate to an architecture decision** — `/architecture-decision` (for example
  moving an aggregation off the request path, or adding a read replica or cache).

Record each decision in the recommendation's `Decision` field.

---

## Phase 6: Write the Report

Ask: "May I write this to `production/qa/perf/perf-profile-<scope>-YYYY-MM-DD.md`?"
Create `production/qa/perf/` if absent. If a report for the same scope and date exists,
ask before overwriting it.

A profile that lives only in the conversation is gone when the session ends and can
never be compared with the next run — name the destination, and keep every
`NOT ASSESSED` row in the written file: a profile whose gaps are edited out on the way
to disk reads, later, as a complete measurement. Raw tool output (Lighthouse JSON,
profiler dumps) is not committed by this skill; the report carries every number the
verdict depends on, with the command that produced it, so the run can be repeated.

```markdown
# Performance Profile: [scope]

> **Verdict**: [PASS | CONCERNS | FAIL | NOT ASSESSED]

> **Date**: [YYYY-MM-DD]
> **Enforcement**: performance.enforce = [warn | block | off] ([source]) [— Budgets not scored, when off]
> **Build**: [commit SHA / app version (build number)]
> **Environments**: [local | preview | staging | production (field data)]
> **Generated by**: /perf-profile

## Scope

- Argument: [surface:web | route:/goals/[id] | full]
- Surfaces profiled: [list] — not profiled: [list with reason]
- Stack: [resolved `stack` line]
- Code roots: [resolved `code_roots` line]
- Consulted: performance-engineer [or "not consulted — <reason>"]

## Budgets

| Surface | Metric | Key | Budget | Source |
|---------|--------|-----|--------|--------|
| api | Latency p95 | `performance.api_p95_ms` | [value or unset] | project.yaml |
| web | LCP p75 | `performance.lcp_ms` | [value or unset] | project.yaml |
| web | Goals journey p95 | — | [value] | docs/ops/slo.md — [differs from project.yaml: yes/no] |

## Measurements

| Surface | Metric | Value | Statistic | Sample / window | Method & tool | Environment | Build |
|---------|--------|-------|-----------|-----------------|---------------|-------------|-------|
| web | LCP `/goals` | [e.g. 2,140 ms] | [p75 field / lab median of 5] | [n or 28-day window] | [command or export] | [staging] | [sha] |

## Breaches

| Metric | Budget | Measured | Over by | Status | Scored as |
|--------|--------|----------|---------|--------|-----------|
| [metric] | [budget] | [value] | [delta] | [OK / BREACH / NOT ASSESSED — reason / N/A] | [FAIL / CONCERNS / not scored] |

## Ranked Recommendations

1. **[Title]** — Target: [metric / budget row]
   - Location: `[path]` — [function, component or route]
   - Expected gain: [number] ([measured | estimated])
   - Effort: [S/M/L] · Risk: [Low/Med/High]
   - Approach: [how]
   - Verify with: [measurement]
   - Decision: [scheduled — /quick-spec | scope — /scope-check | Accepted — owner, date | ADR — /architecture-decision | open]

### Requires Measurement

- [Static candidate not yet confirmed — the measurement that would confirm it]

### Not Checked

- [Every skipped family, layer or root, with its reason — e.g. `NOT CHECKED — mobile layer not configured (run /setup-stack)`]
```

After writing, verify the file exists and that the verdict line sits directly under
the H1. Then print a summary: the verdict, the top three breaches or hotspots, the
headroom of the tightest measured budget, and every `NOT ASSESSED` row with the skill
or setting that would close it.

---

## Phase 7: Next Steps

Close with the next steps that apply, as a short list:

- Breaches needing an architectural change → `/architecture-decision`.
- Fixes to schedule → `/quick-spec` or `/create-stories`, then `/sprint-plan`.
- API percentiles missing or stale → `/load-test load --target staging`.
- `performance.bundle_kb` row `NOT ASSESSED` or bundle composition unclear → `/bundle-audit`.
- Budgets unset → `/settings performance.<key>=<value>` (or `/create-architecture`).
- After fixes → rerun `/perf-profile <same scope>` and compare with this report.
- Ready to assess the phase → `/gate-check hardening` or `/gate-check launch` (both
  read the newest report).

---

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and `autonomous`
modes, see `.claude/docs/automation-modes.md`.

- **Measure before recommending** — a recommendation without a measured or clearly
  labelled estimated gain is not actionable. Static review finds candidates; runtime
  measurement confirms them.
- **Never fabricate a number** — an unmeasured cell is `NOT ASSESSED`, never a guess,
  and never a published threshold standing in for an unset budget.
- **Profile what users run** — production builds, release app builds, representative
  devices and networks; say so when a row falls short of that.
- **Never load or probe production** — field data comes only from exports the user
  provides; lab runs target local, preview or staging environments.
- Ask "May I write this to `<path>`?" before every write; this skill writes only its
  report.
