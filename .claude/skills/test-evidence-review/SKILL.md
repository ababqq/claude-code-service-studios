---
name: test-evidence-review
description: "Evidence quality: assertion coverage, Playwright traces, visual diffs, axe reports, contract verification. ADEQUATE/INCOMPLETE/MISSING/NOT ASSESSED."
argument-hint: "[story-path | sprint | <feature-or-epic-slug>]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash(bash "*/.claude/skills/test-evidence-review/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation`

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

# Test Evidence Review

`/smoke-check` verifies that test files **exist** and **pass**. This skill
goes further — it reviews the **quality** of those tests and evidence records.
A test file that exists and passes may still leave critical behaviour uncovered.
An evidence directory that exists may hold no trace, no screenshot of the state that
matters, no axe results and no sign-off.

**Output:** Summary report (in conversation) + optional `production/qa/evidence-review-YYYY-MM-DD.md`

**When to run:**
- Before the `/team-qa` sign-off
- On any story where test quality is in question
- As part of milestone review for a Logic, Integration and E2E test quality audit

**Strictness.** The gate level per story type comes from `.claude/docs/coding-standards.md`: Logic,
Integration, UI and E2E evidence BLOCKING by default; Config ADVISORY. A project may override each type
with `testing.strict.logic`, `testing.strict.integration`, `testing.strict.ui`, `testing.strict.e2e` or
`testing.strict.config`. This skill does not resolve those keys: it reports against the default levels
and says so in the report — `/story-done` applies the resolved values when it closes a story. It
does not resolve `qa.level` either: every story is reviewed against the evidence its type requires
in `coding-standards.md`, so at `qa.level: minimal` — where per-story evidence is waived — a
`MISSING` here means "no evidence present", and `/story-done` decides whether that blocks. The
**migration floor** is not a `testing.strict` level: a story whose `**Migration**` is not `None`
requires its dry-run log at every `qa.level`, whatever the overrides.

---

## 1. Parse Arguments

**Modes:**
- `/test-evidence-review [story-path]` — review a single story's evidence
- `/test-evidence-review sprint` — review all stories in the current sprint
- `/test-evidence-review <feature-or-epic-slug>` — review all stories of an epic or feature
- No argument — ask which scope: "Single story", "Current sprint", "A feature or epic"

---

## 2. Load Stories in Scope

Based on the argument:

**Single story**: Read the story file directly. Extract: Story Type, Surface, Test
Evidence section, story slug, feature (the `**PRD**:` slug), `**API Contract**` and
`**Migration**` fields.

**Sprint**: Read the most recently modified file in `production/sprints/`; extract
the list of story file paths from the sprint plan.

**Feature or epic**: Glob `production/epics/<slug>/story-*.md`; if that matches
nothing, keep the stories under `production/epics/*/story-*.md` whose `**PRD**:`
line names `design/prd/<slug>.md`.

> **If the resolved scope contains ZERO stories, stop here.** Report
> `NOT ASSESSED — no stories in scope`, name which scope was searched and which
> path was empty, and route: no sprint file → `/sprint-plan new`; a sprint plan
> listing no stories → `/create-stories [epic-slug]`; a `<feature-or-epic-slug>`
> glob that matched nothing → name the glob. Do not continue to Section 3.
>
> **Guard the empty scope, not just the per-story unknown.** The verdict
> vocabulary here — ADEQUATE / INCOMPLETE / MISSING — needs a "could not check"
> value, or an unverifiable story acquires a verdict claiming somebody verified
> it; that is what `NOT ASSESSED` is for. **But giving the per-story unknown a
> home does nothing for the empty-scope unknown.** With no stories
> the Section 6 report renders an empty Summary table and ends
> `BLOCKING items: 0 / ADVISORY items: 0` — which reads as *everything reviewed,
> all fine*. This skill gates story closure, and `coding-standards.md` marks Logic,
> Integration, UI and E2E evidence BLOCKING, so a false-clean closes stories nobody
> reviewed.
>
> This is a recurring shape: the sophisticated inner rule present, the outer
> boundary unguarded. Ask it of any skill that aggregates —
> **what does this emit when the set is empty?**

For the resulting story set, collect the fields below with **targeted section
greps, not a full read of each story**:
```
Grep pattern="## Test Evidence" glob="production/epics/*/story-*.md" output_mode="content" -A 8
Grep pattern="## Acceptance Criteria" glob="production/epics/*/story-*.md" output_mode="content" -A 15
Grep pattern="^> \*\*(Type|Surface)\*\*|^\*\*(PRD|API Contract|Migration)\*\*" glob="production/epics/*/story-*.md" output_mode="content"
```
- **Story Type** (Logic / Integration / UI / E2E / Config) and **Surface** — from the
  header grep; the stated evidence path lives under `## Test Evidence`, so the first
  grep's `-A 8` captures it.
- Acceptance Criteria list — the `## Acceptance Criteria` block from the second grep.
- `**API Contract**` operation and `**Migration**` plan — from the third grep.
- Story slug (from the file name) and feature (from the `**PRD**:` line) — no read.
Full-read a story only when its Test Evidence section is missing or ambiguous.
(In Sprint mode, scope the globs to the sprint plan's story paths.)

Read `testing.patterns` from `project.yaml` (it has no `resolve_config` label). Unset ⇒
search the `tests/**` convention only, and say in the report: "`testing.patterns`
unset — searched `tests/**` only; co-located tests were not searched."

---

## 3. Locate Evidence Files

For each story, find the evidence. `<story-slug>` = the story file name without
`.md`. When reviewing a story, read its evidence record
`production/qa/evidence/<story-slug>/evidence.md` (written from
`.claude/docs/templates/test-evidence.md`) when it exists; its verdict line is
`> **Verdict**: OBSERVED | NOT VERIFIED | N/A`, the token of its `Run result:` line.

Files whose basename contains `example` (written by `/test-setup`) and
`tests/e2e/capture.spec.ts` prove a runner, not the product — do not count them as
coverage.

**Logic stories**: the test files `testing.patterns` matches (co-located, e.g.
`apps/api/src/goals/goal-plan.test.ts`), else `tests/unit/<feature>/`
  - Match by story slug, TR-ID (`TR-<feature>-NNN`) or the rule names the story implements;
    if no file name matches, Grep the candidate files for those strings

**Integration stories**: `tests/integration/<feature>/` and `tests/contract/<feature>/`
(or per `testing.patterns`)
  - Contract verification: the contract-test run's output or report (Schemathesis
    results, Pact verification) when it is retained, and a test that exercises the
    story's `**API Contract**` operation

**UI stories**: `production/qa/evidence/<story-slug>/` — screenshots of each state
(`NN-<state>-desktop.png`, `NN-<state>-mobile.png`, or device screenshots),
`NN-<state>-axe.json`, visual-regression snapshots or diff reports, the evidence
record `evidence.md`; plus component tests per `testing.patterns`

**E2E stories**: `tests/e2e/<journey>/` (Playwright spec, Maestro or Detox flow) and
`production/qa/evidence/<story-slug>/` — the retained Playwright trace (`trace.zip`) or
HTML report, screenshots or video of the run, and the environment it ran against

**Config stories**: Glob `production/qa/smoke-*.md` (any smoke check report)

**Any story with `**Migration**` not `None`**:
`production/qa/evidence/<story-slug>/migration-dry-run.log`

Evidence under `production/session-logs/` never counts — that directory is gitignored,
so what is there is not retained. If evidence is found only there, record it as not
found and name the path it should move to.

Note what was found (path) or not found (gap) for each story.

---

## 4. Review Automated Test Quality (Logic / Integration / E2E)

For each test file found, read it and evaluate:

### Assertion coverage

Count the number of distinct assertions (lines containing the framework's assertion
calls — `expect(` for Vitest, Jest and Playwright; `assert` for pytest; `assertThat` /
`assertEquals` for JUnit; `XCTAssert` for XCTest; `assertVisible` / `assertNotVisible`
for Maestro). Low assertion count is a quality signal — a test that makes only 1
assertion per test function may not cover the range of expected behaviour.

Thresholds:
- **3+ assertions per test function** → normal
- **1-2 assertions per test function** → note as potentially thin
- **0 assertions** (test exists but no asserts) → flag as BLOCKING — the
  test passes vacuously and proves nothing

Also flag tests that are **skipped or focused** (`.skip`, `.only`, `xit`, `test.fixme`,
`@pytest.mark.skip`, `@Disabled`): a skipped test covering an acceptance criterion
leaves that criterion unverified (BLOCKING); a focused `.only` left in the file silently
disables its neighbours (ADVISORY).

### Edge case coverage

For each acceptance criterion in the story that contains a number, threshold,
or "when X happens" conditional: check whether a test function name or
test body references that specific case.

Heuristics:
- Grep test file for "zero", "max", "null", "empty", "min", "invalid",
  "boundary", "edge", "expired", "duplicate", "timeout", "unauthorized",
  "forbidden", "idempotent" — presence of any is a positive signal
- If the PRD's `## Business Rules & Calculations` gives specific bounds (limits,
  rounding, thresholds): check whether tests exercise at minimum/maximum values
- For Integration stories touching a resource by id: check for the authorization
  negative case (another user's resource is refused — BOLA)

### Naming quality

Test names should describe the scenario and the expected result
(`scenario → expected`), in the convention `testing.patterns` records — e.g.
`it('rounds the monthly debit up to the nearest KRW 10')`,
`test_create_goal_rejects_zero_months`.

Flag tests named generically (`test1`, `it('works')`, `testBasic`) as
**naming issues** — they make failures harder to diagnose.

### Business-rule traceability

For Logic stories whose PRD has a `## Business Rules & Calculations` section: check
that the test file contains at least one test whose name or comment references the
rule name, a rule value or the TR-ID. A test that exercises a rule without mentioning
it is harder to maintain when the rule changes.

### Contract verification (Integration)

For a story with an `**API Contract**` operation: a contract or integration test
exercises that operation and validates the response against `docs/api/` (schema-based
or consumer-driven). A handler test that asserts only the status code is thin
coverage of a contract.

### E2E run quality

- A trace, report or screenshots of the latest passing run are retained in the
  story's evidence directory, and the run names its environment (staging URL or
  preview deploy)
- Fixed sleeps (`waitForTimeout`, `sleep`) instead of waiting on a visible state →
  ADVISORY (flake risk)
- Selectors on CSS chains or copy text instead of roles, labels, `data-testid` or
  accessibility ids → ADVISORY

---

## 5. Review Manual and Visual Evidence Quality (UI / E2E)

For each evidence record and directory found, read it and evaluate:

### Criterion linkage

The evidence record should reference each acceptance criterion from the story.
Check: does it contain each criterion (or a clear rephrasing)?
Missing criteria mean a criterion was never verified.

### Sign-off completeness

The sign-off table is optional in the test-evidence template; check it only when
the evidence record carries one. Check each row it carries (typically the
implementing engineer, product-designer for UI states, and qa-lead).

If any row is still `[ ] Approved` or blank: flag as INCOMPLETE — the story cannot
be fully closed without the sign-offs its record asks for. A record with no sign-off
table is not a gap: write `Sign-offs: none — no sign-off table in the record`.

### Screenshot / trace / artefact completeness

For UI stories: Glob `production/qa/evidence/<story-slug>/` for a retained image
(`*.png`, `*.jpg`, `*.webp`) of each state the story touches — desktop and mobile
viewport, or device screenshots for ios / android. A record that describes a visual
check but retains no image is INCOMPLETE — this gate is BLOCKING by default, and a
description is an assertion rather than evidence. When visual regression is used,
the snapshot or diff report for the changed states must be present; an unexplained
diff is an issue.

For E2E stories: require the retained trace or screenshots of the run, plus a
walkthrough sequence (step-by-step interaction log) for any surface walked manually.

**Design reference images are never evidence.** Images under `design/handoff/`
(a handoff record's `screens/` or `bundle/`) show what was designed, not what was
built: they never count toward either rule above. An image in the evidence directory
that is a copy of a file under `design/handoff/` is not a capture either — the state
it stands for is treated as having no retained image, and the report says
`Reference image <path> is a design reference, not a capture`.

### Accessibility results

When an `NN-<state>-axe.json` is present, read it: violations of impact `serious` or
`critical` are issues (BLOCKING when they break an acceptance criterion, else
ADVISORY). When a UI story has no axe results, write
`NOT CHECKED — axe results (no axe report in the evidence directory)` — never read the
absence as a clean accessibility result.

### Run result and environment

The record carries the `Run result:` line with one of its three tokens — `OBSERVED`,
`NOT VERIFIED` or `N/A`. A UI or E2E story whose run result is `NOT VERIFIED` is
INCOMPLETE. The record names the environment and build (URL, commit SHA or app
version and build number), the browser or device matrix, and the test account and
flag states; a result without an environment cannot be reproduced — flag it
INCOMPLETE.

### Redaction

Screenshots, traces and logs must not show real personal data, tokens or card
numbers. Anything visible is flagged ADVISORY with the file path, so it can be
redacted before the evidence is shared.

### Migration dry-run log

For a story whose `**Migration**` is not `None`: `migration-dry-run.log` exists and
shows the Expand phase applied and rolled back on a disposable database. Absent ⇒
MISSING and BLOCKING, at every `qa.level`.

### Date coverage

The evidence record should have a date. If the date is earlier than the story's
last major change (heuristic: compare against sprint start date from the sprint
plan), flag as POTENTIALLY STALE — the evidence may not cover the final
implementation.

---

## 6. Build the Review Report

For each story, assign a verdict:

| Verdict | Meaning |
|---------|---------|
| **ADEQUATE** | Test/evidence exists, passes quality checks, all criteria covered |
| **INCOMPLETE** | Test/evidence exists but has quality gaps (thin assertions, missing sign-offs, no trace, no environment) |
| **MISSING** | No test or evidence found for a story type that requires it |
| **NOT ASSESSED** | The review could not be performed for this story — see below |

> **`NOT ASSESSED` is required, and it is not a softer `MISSING`.**
> The other three verdicts all presume the review actually ran. `MISSING` means
> *I looked and there was nothing there* — a real, reportable failure. It must
> never be used for *I could not look*, which is not a finding about the story
> at all. Use `NOT ASSESSED` when:
>
> - the story's **type cannot be determined**, so the required evidence is
>   unknown (the type→evidence mapping in `.claude/docs/coding-standards.md` is
>   what makes any other verdict meaningful);
> - the evidence path is named but **unreadable or outside this run's scope**;
> - the story file itself could not be parsed.
>
> **Say which of those it was, per story.** A reader cannot act on a bare
> `NOT ASSESSED`, and the whole point of separating it from `MISSING` is that
> the two have different fixes: one needs a test written, the other needs the
> reviewer given access or the story classified.

The overall sprint/feature verdict is the worst story verdict present, and
**`NOT ASSESSED` outranks `ADEQUATE`**: a run that could not assess part of its
scope has not established that the scope is adequate. It does not outrank
`INCOMPLETE` or `MISSING` — a known failure is more actionable than an unknown,
and demoting a real failure behind an access problem would bury it.

> Why this needed saying: evidence review **gates story completion**, and
> `coding-standards.md` makes Logic, Integration, UI and E2E evidence BLOCKING. A verdict
> vocabulary with no way to express "I could not check" forces every unknown
> into one of three claims about the story — which is how a story nobody
> verified acquires a verdict that says somebody did.

```markdown
# Test Evidence Review

> **Verdict**: [ADEQUATE | INCOMPLETE | MISSING | NOT ASSESSED]
> **Date**: [YYYY-MM-DD]
> **Scope**: [single story path | Sprint [N] | [feature or epic slug]]
> **Stories reviewed**: [N]
> **Strictness**: default gate levels of `.claude/docs/coding-standards.md`; `testing.strict` overrides and `qa.level` not resolved here — `/story-done` applies them
> **Test search**: [`testing.patterns` globs | "`testing.patterns` unset — searched `tests/**` only"]

---

## Story-by-Story Results

### [Story Title] — [Type] — [ADEQUATE/INCOMPLETE/MISSING/NOT ASSESSED]

**Test/evidence path**: `[path]` (found) / (not found)

**Automated test quality** *(Logic/Integration/E2E only)*:
- Assertion coverage: [N per function on average] — [adequate / thin / none]
- Skipped or focused tests: [none / list]
- Edge cases: [covered / partial / not found]
- Naming: [consistent / [N] generic names flagged]
- Business-rule traceability: [yes / no — rule names or TR-IDs not referenced in tests]
- Contract verification: [operation covered and schema-validated / status-only / not found / N/A]
- E2E run: [trace retained — environment named / no trace / N/A]

**Manual and visual evidence quality** *(UI/E2E only)*:
- Criterion linkage: [N/M criteria referenced]
- Sign-offs: [Engineer ✓ | Product designer ✗ | QA lead ✗ | none — no sign-off table in the record]
- Artefacts: [screenshots per state and viewport present / missing / N/A]
- Accessibility: [axe: N serious/critical | NOT CHECKED — axe results (no axe report in the evidence directory)]
- Run result: [OBSERVED / NOT VERIFIED / N/A]; environment [named / missing]
- Freshness: [dated [date] — current / potentially stale]

**Migration dry-run log** *(stories with a Migration only)*: [present — Expand applied and rolled back / MISSING]

**Issues**:
- BLOCKING: [description] *(prevents story-done)*
- ADVISORY: [description] *(should fix before release)*

---

## Summary

| Story | Type | Verdict | Issues |
|-------|------|---------|--------|
| [title] | Logic | ADEQUATE | None |
| [title] | Integration | INCOMPLETE | Contract test asserts status only |
| [title] | UI | INCOMPLETE | Mobile viewport screenshots missing; no axe report |
| [title] | E2E | MISSING | No trace or screenshots retained for the staging run |
| [title] | Logic | NOT ASSESSED | Test path outside this run's scope |

**BLOCKING items** (must resolve before story can be closed): [N]
**ADVISORY items** (should address before release): [N]
```

---

## 7. Write Output (Optional)

Present the report in conversation.

Ask: "May I write this to `production/qa/evidence-review-YYYY-MM-DD.md`?"

This is optional — the report is useful standalone. Write only if the user
wants a persistent record.

After the report:

- For BLOCKING items: "These must be resolved before `/story-done` can mark the
  story Complete. Would you like to address any of them now?"
- For thin assertions: "Consider running `/test-helpers` to see
  scaffolded assertion patterns and fixtures for common cases."
- For missing screenshots, traces or axe results on web stories: "Re-run the
  run-and-observe capture (`tests/e2e/capture.spec.ts`, scaffolded by `/test-setup`)
  with `CAPTURE_OUT_DIR=production/qa/evidence/<story-slug>`."
- For missing sign-offs: "Manual sign-off is required from [role]. Share
  `[evidence-path]` with them to complete sign-off."

Verdict: **<ADEQUATE | INCOMPLETE | MISSING | NOT ASSESSED>** — the report's overall verdict (the
worst story verdict; NOT ASSESSED ranks above ADEQUATE and below INCOMPLETE and MISSING).

---

## Collaborative Protocol

- **Report quality issues, do not fix them** — this skill reads and evaluates;
  it does not modify test files or evidence records
- **ADEQUATE means adequate for shipping, not perfect** — avoid nitpicking
  tests that are functioning and comprehensive enough to give confidence
- **BLOCKING vs. ADVISORY distinction is important** — only flag BLOCKING when
  the gap leaves a story criterion genuinely unverified, or the migration floor unmet
- **Ask before writing** — the report file is optional; always confirm before writing
