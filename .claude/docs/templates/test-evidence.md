# Test Evidence: [Story Title]

> **Verdict**: [OBSERVED | NOT VERIFIED | N/A]
> **Story**: `[production/epics/<epic-slug>/story-NNN-<slug>.md]`
> **Story Type**: [Logic | Integration | UI | E2E | Config]
> **Surface**: [web | ios | android | mobile | api | admin | infra | analytics]
> **Date**: [YYYY-MM-DD]
> **Tester**: [who performed the test — person or agent]
> **Build / Commit**: [version or release candidate · git SHA · iOS/Android build number]

**Gate level**: `testing.strict.[logic | integration | ui | e2e | config]` —
[BLOCKING | ADVISORY] ([set in project.yaml / project.local.yaml | unset ⇒ the
skill's default]). Logic, Integration, UI and E2E default to BLOCKING; Config
defaults to ADVISORY. A story with a migration also needs the migration dry-run log
below at every `qa.level`, whatever this line says.

---

## What Was Tested

[One paragraph describing the behaviour that was validated, and on which
environment. Include the acceptance criteria numbers from the story that this
evidence covers.]

**Acceptance criteria covered**: [AC-1, AC-2, AC-3]

---

## Environment

| Field | Value |
|---|---|
| **Environment** | [local \| preview \| staging] |
| **URL / API base** | [https://staging.example.com · https://api.staging.example.com — never a production URL] |
| **Build** | [web deploy ID or version · API version · mobile build number] |
| **Commit** | [git SHA the environment was running — confirm it matches the story's branch] |
| **Data** | [seeded fixture set / factories used, e.g. `tests/helpers/backend/goals.factory.ts`] |

### Test Account & Flags

| Field | Value |
|---|---|
| **Test account** | [role and test account ID — e.g. `member (test user #3)`; never a real person's data, never a password] |
| **Feature flags** | [flag key → state on this environment, e.g. `goals.v2-progress-ring: on (100%)`] |
| **Locale / timezone** | [e.g. `ko-KR`, `Asia/Seoul`] |
| **Third-party mode** | [sandbox / mocked — e.g. `Toss Payments test keys`, `Kakao login mocked`] |

---

## Browser / Device Matrix

| Surface | Browser or OS / Device | Viewport | Result | Notes |
|---|---|---|---|---|
| web | [Chrome 1xx / macOS] | 1280×800 | PASS / FAIL | |
| web | [Safari / iPhone] | 390×844 | PASS / FAIL | |
| ios | [iOS version · device or simulator] | — | PASS / FAIL | |
| android | [Android version · device or emulator] | — | PASS / FAIL | |

Delete the rows for surfaces the story does not touch; add a row per extra
browser `platform.browsers` requires.

---

## Acceptance Criteria Results

| # | Criterion (from story) | Result | Evidence | Notes |
|---|----------------------|--------|----------|-------|
| AC-1 | [exact criterion text] | PASS / FAIL | `[file or test name]` | [any observations] |
| AC-2 | [exact criterion text] | PASS / FAIL | | |
| AC-3 | [exact criterion text] | PASS / FAIL | | |

---

## Screenshots / Traces

All files live in `production/qa/evidence/<story-slug>/`, beside this document.

**The file must actually be on disk.** UI and E2E gates are BLOCKING by default,
and `/story-done` and `/test-evidence-review` glob for the files — a filename
listed here with no file beside it does not satisfy the gate. Evidence under
`production/session-logs/` (gitignored) never counts.

| # | Filename | What It Shows | Acceptance Criterion |
|---|----------|--------------|----------------------|
| 1 | `01-[state]-desktop.png` | [brief description of what is visible] | AC-1 |
| 2 | `01-[state]-mobile.png` | | AC-1 |
| 3 | `[journey]-trace.zip` | [Playwright trace of the E2E run] | AC-2 |
| 4 | `02-[operation].json` | [API request/response snapshot — PII and tokens redacted] | AC-3 |

Web screenshots come from the capture script (`tests/e2e/capture.spec.ts`,
`NN-<state>-desktop.png` 1280×800 and `NN-<state>-mobile.png` 390×844); device
screenshots from the simulator or emulator. *If video: note the timestamp and what
it demonstrates.*

**Design reference** *(optional — only when the story's `Design reference:` line names a
record)*: compared with `design/handoff/<slug>/screens/` — [matches | divergences listed
under `## Observations` | `Design reference: NOT CHECKED — <reason>`]. Reference images
stay under `design/handoff/`; they are never copied here and never count as captures.

---

## Accessibility (axe)

| File | Critical | Serious | Moderate | Minor | Target |
|---|---|---|---|---|---|
| `01-[state]-axe.json` | [n] | [n] | [n] | [n] | [accessibility.target, e.g. `wcag-aa`] |

[List each critical or serious violation with its rule ID and the element, and
whether it is fixed, accepted (with the reason) or ticketed (`BUG-NNNN`). No axe
file ⇒ write `NOT CHECKED — no axe results (@axe-core/playwright not installed, or
not a web surface)`.]

---

## Migration Dry-Run

Required when the story's `**Migration**` is not `None` — at every `qa.level`,
regardless of `testing.strict.config`. Absent ⇒ BLOCKING.

- **Migration plan**: `[docs/data/migrations/NNNN-<slug>.md]`
- **Log**: `migration-dry-run.log` (in this directory)
- **What it shows**: [the Expand phase applied and rolled back on a disposable
  database — database engine and version, duration, locks taken]

[If the story has no migration: *Not applicable — `**Migration**: None`.*]

---

## Run Result

[Exactly one line, copied from the implementation summary of `/dev-story`. Its token is
also the `> **Verdict**:` line under the H1 — `/dev-story` fills both.]

`Run result: OBSERVED — [what was on screen or returned, one line]`

[or `Run result: NOT VERIFIED — <reason>`, or `Run result: N/A — <reason>` for a
pure Logic or Config story with nothing observable.]

---

## Observations

[Anything noteworthy that didn't cause a FAIL but should be recorded. Examples:
a layout that wraps awkwardly at 360 px, a slow first load on staging, copy that
reads oddly in one locale, a console warning. These become candidates for
Hardening work.]

- [Observation 1]
- [Observation 2]

If nothing notable: *No significant observations.*

---

## Sign-Off

The sign-off table is optional: keep it when the story needs a named reviewer
before it closes, and delete this section otherwise. `/story-done` and `/test-evidence-review`
check its `[ ] Approved` rows only when the table exists. When kept, every row
must be approved before the story can be marked Complete via `/story-done`. UI
stories keep the product designer's row. E2E stories keep the QA row, signing off
the journey as a whole.

**Solo developers**: all sign-offs may be by the same person in each role. The
intent is that someone deliberately reviews the evidence before marking complete —
not that three separate people must participate.

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Engineer (implemented) | | | [ ] Approved |
| Product Designer (UI stories) | | | [ ] Approved |
| QA Lead / QA Engineer | | | [ ] Approved |

**Any sign-off can be marked "Deferred — [reason]"** if the person is
unavailable. Deferred sign-offs must be resolved before the story advances
past the sprint review.

---

*Template: `.claude/docs/templates/test-evidence.md`*
*Used for: UI and E2E story evidence records, and the evidence of any story with a migration*
*Location: `production/qa/evidence/<story-slug>/evidence.md` (`<story-slug>` = the story file name without `.md`)*
