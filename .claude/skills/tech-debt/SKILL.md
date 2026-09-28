---
name: tech-debt
description: "Track, categorize (incl. Security, Infra, Observability) and prioritize technical debt."
argument-hint: "[scan|add|prioritize|report]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, AskUserQuestion, Bash(bash "*/.claude/skills/tech-debt/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,code_roots`

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

## Phase 1: Parse Subcommand

Determine the mode from the argument:

- `scan` — Scan the codebase for tech debt indicators
- `add` — Add a new tech debt entry manually
- `prioritize` — Re-prioritize the existing debt register
- `report` — Generate a summary report of current debt status

If no subcommand is provided, output usage and stop. Verdict: **FAIL** — missing required subcommand.

### Categories

Every entry carries exactly one category:

- **Architecture Debt**: Wrong abstractions, missing patterns, coupling issues, a
  module owning data it should not (compare `docs/registry/architecture.yaml`)
- **Code Quality Debt**: Duplication, complexity, naming, missing types, suppressed
  lint or type errors
- **Test Debt**: Missing tests, flaky or skipped tests, untested edge cases, missing
  contract tests for an API operation a client uses
- **Documentation Debt**: Missing docs, outdated docs, undocumented APIs, runbooks
  out of date
- **Dependency Debt**: Outdated packages, deprecated APIs, version conflicts,
  runtimes approaching end of life, libraries on the tech radar's `## Hold` ring
- **Performance Debt**: Known slow paths, N+1 queries, missing indexes, unbounded
  list endpoints, bundle bloat, mobile cold-start regressions
- **Security Debt**: Dependencies with published vulnerabilities, disabled or
  weakened security checks, authorization enforced only in the client, secrets
  handled outside the secrets manager, weak crypto, missing rate limits
- **Infra Debt**: Resources created by hand instead of in IaC, staging drifted from
  production, CI steps skipped or allowed to fail, manual deploy or rollback steps,
  pinned base images past their support window
- **Observability Debt**: Endpoints or jobs without structured logs, metrics or
  traces; SLOs without alerts; alerts without runbooks; personal data in logs

---

## Phase 2A: Scan Mode

**Establish what to scan.** Use the `code_roots` line above:
- Scan every listed root whose source is `project.yaml`, `workspace` or `detected`;
  skip `missing` roots. For `undeclared=… (workspace)` roots, scan them and print
  `WARN: undeclared code roots: <dirs> — declare them with /setup-stack`.
- Restrict the scan to the extensions the line lists, and prune dependency and build
  output directories (`node_modules`, `.next`, `dist`, `build`, `out`, `coverage`,
  `Pods`, `DerivedData`, `.gradle`, `.dart_tool`, `.venv`, `__pycache__`,
  `.terraform`, `vendor`, `target`).
- When the line reads `code_roots: unresolved`, there is nothing to scan: go to the
  denominator check below.

Search the resolved roots for debt indicators:

- `TODO` comments (count and categorize)
- `FIXME` comments (these are bugs disguised as debt)
- `HACK` comments (workarounds that need proper solutions)
- `@deprecated` markers and calls to APIs marked deprecated in
  `docs/stack-reference/<component>/deprecated-apis.md`
- Suppressions: `eslint-disable`, `@ts-ignore`, `@ts-expect-error`, `# type: ignore`,
  `# noqa`, `@SuppressWarnings`, `//nolint`
- Skipped tests: `it.skip`, `describe.skip`, `xit`, `test.fixme`, `@Disabled`,
  `@pytest.mark.skip`
- Duplicated code blocks (similar patterns in multiple files)
- Files over 500 lines (potential god objects)
- Functions over 50 lines (potential complexity)

Then read `docs/architecture/tech-radar.md`: every library under `## Hold` and every
pattern under `## Forbidden Patterns` that the scan finds in the roots is a debt
entry (Dependency Debt for a Hold library, Architecture or Security Debt for a
forbidden pattern), citing the radar entry and its ADR. No radar ⇒ print
`NOT CHECKED — tech radar (no docs/architecture/tech-radar.md; /setup-stack seeds it)`
rather than implying the code is radar-clean.

Categorize each finding with the categories above.

**Before presenting anything, establish that there was something to scan.**
Count the source files the scan actually covered. If that count is **zero** —
no code root resolved, or the resolved roots hold no source files — report:

> **NOT ASSESSED — no source files to scan.** The resolved code roots contain no
> code (or none resolved: `NOT CHECKED — no code root resolved (set stack.layers.<layer>.root via /setup-stack)`),
> so "no debt indicators found" would be a statement about an empty search, not
> about the codebase. Run this once implementation is under way.

and stop. Do not write to the register and do not emit a COMPLETE verdict.

The distinction is the whole point of the scan: **zero findings over 400 files
is a clean codebase; zero findings over zero files is no information at all.**
Rendering both as "COMPLETE — scan findings written to register" reads as the
first. State the denominator whenever findings are reported — files scanned per
root — including when it is large and the count is genuinely zero.

Present the findings to the user.

Ask: "May I write these findings to `docs/tech-debt-register.md`?"

If yes, update the register (append new entries, do not overwrite existing ones). Verdict: **COMPLETE** — scan findings written to register.

If no, stop here. Verdict: **BLOCKED** — user declined write.

---

## Phase 2B: Add Mode

Ask the user for the description, affected files, why the debt was accepted
(deadline, prototype, missing information), and the impact if left unfixed (plain
text prompts).

Then collect the **category** with two `AskUserQuestion` calls. First the area:
- Prompt: "Which area does this tech debt belong to?"
- Options:
  - `[A] Code — architecture, code quality, tests, documentation`
  - `[B] Platform — dependencies, performance, security`
  - `[C] Operations — infrastructure, observability`

Then the category within that area:
- **Code**: `[A] Architecture Debt — wrong abstractions, coupling, data ownership` ·
  `[B] Code Quality Debt — duplication, complexity, naming, missing types` ·
  `[C] Test Debt — missing, flaky or skipped tests; missing contract tests` ·
  `[D] Documentation Debt — missing/outdated docs, undocumented APIs`
- **Platform**: `[A] Dependency Debt — outdated packages, deprecated APIs, EOL runtimes` ·
  `[B] Performance Debt — slow paths, N+1 queries, bundle bloat` ·
  `[C] Security Debt — vulnerable dependencies, weakened checks, missing rate limits`
- **Operations**: `[A] Infra Debt — manual resources, environment drift, skipped CI steps` ·
  `[B] Observability Debt — missing logs/metrics/traces, alerts without runbooks`

Then use `AskUserQuestion` to collect the **estimated fix effort**:
- Prompt: "What is the estimated effort to fix this item?"
- Options:
  - `[A] S — Small (under 1 day)`
  - `[B] M — Medium (1–3 days)`
  - `[C] L — Large (3–7 days)`
  - `[D] XL — Extra Large (over 1 week)`

Present the complete new entry to the user.

Ask: "May I append this entry to `docs/tech-debt-register.md`?"

If yes, append the entry. Verdict: **COMPLETE** — entry added to register.

If no, stop here. Verdict: **BLOCKED** — user declined write.

---

## Phase 2C: Prioritize Mode

Read the debt register at `docs/tech-debt-register.md`. No register ⇒ report
`NOT ASSESSED — no docs/tech-debt-register.md; run /tech-debt scan first` and stop —
there is nothing to re-sort, and an empty priority list is not a prioritized backlog.

Score each item by: `(impact_if_unfixed × frequency_of_encounter) / fix_effort`

Security Debt with a known exploitable vulnerability in a reachable code path is not
scored like the rest: list it first and recommend `/bug-report` (it is a defect,
usually S1-Critical or S2-Major) and `/security-audit deps` rather than a slot in the
debt backlog.

Re-sort the register by priority score and recommend which items to include in the next sprint.

Present the re-prioritized register to the user.

Ask: "May I write the re-prioritized register back to `docs/tech-debt-register.md`?"

If yes, write the updated file. Verdict: **COMPLETE** — register re-prioritized and saved.

If no, stop here. Verdict: **BLOCKED** — user declined write.

---

## Phase 2D: Report Mode

Read the debt register. Generate summary statistics:

- Total items by category
- Total estimated fix effort
- Items added vs resolved since last report
- Trending direction (growing / stable / shrinking)

Flag any items that have been in the register for more than 3 sprints.

No register ⇒ report `NOT ASSESSED — no docs/tech-debt-register.md; run /tech-debt scan first` and stop, not an empty summary (no COMPLETE verdict).

Output the report to the user. This mode is read-only — no files are written. Verdict: **COMPLETE** — debt report generated.

---

## Phase 3: Next Steps

- Run `/sprint-plan update` (or `/sprint-plan new`) to schedule high-priority debt items into a sprint.
- Run `/tech-debt report` at the start of each sprint to track debt trends over time.
- Run `/security-audit deps` when Security Debt includes vulnerable dependencies.

### Debt Register Format

```markdown
## Technical Debt Register
Last updated: [Date]
Total items: [N] | Estimated total effort: [T-shirt sizes summed]

| ID | Category | Description | Files | Effort | Impact | Priority | Added | Sprint |
|----|----------|-------------|-------|--------|--------|----------|-------|--------|
| TD-001 | [Cat] | [Description, and why it was accepted] | [files] | [S/M/L/XL] | [Low/Med/High/Critical] | [Score] | [Date] | [Sprint to fix or "Backlog"] |
```

### Rules
- Tech debt is not inherently bad — it is a tool. The register tracks conscious decisions.
- Every debt entry must explain WHY it was accepted (deadline, prototype, missing info)
- "Scan" should run at least once per sprint to catch new debt
- Items older than 3 sprints without action should either be fixed or consciously accepted with a documented reason
