---
name: bug-report
description: "Structured bug report with a service environment block, or code analysis for potential bugs. Reproduction steps, severity."
argument-hint: "[description] | analyze <path> | verify <BUG-ID> | close <BUG-ID>"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Bash(bash "*/.claude/skills/bug-report/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation`

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

Bug files live at `production/qa/bugs/BUG-NNNN.md` — four digits, no slug. `/team-qa` files bugs under
the same name, and `/bug-triage`, `/hotfix`, the phase gates and session-start read them, so the file
name, the ladder strings and the status values below are a contract: copy them exactly.

## Phase 1: Parse Arguments

Determine the mode from the argument:

- No keyword → **Description Mode**: generate a structured bug report from the provided description
- `analyze <path>` → **Analyze Mode**: read the target file(s) and identify potential bugs
- `verify <BUG-ID>` → **Verify Mode**: confirm a reported fix actually resolved the bug
- `close <BUG-ID>` → **Close Mode**: mark a verified bug as closed with resolution record

If no argument is provided, ask the user for a bug description before proceeding.

---

## Severity, Priority and Status

These definitions are shared, word for word, with `/bug-triage`. Severity is impact; priority is
scheduling. Never lower a severity to fit a release date — lower the priority and record why.

`**Severity**: [S1-Critical / S2-Major / S3-Minor / S4-Trivial]`

- **S1-Critical**: outage, data loss/corruption, security or privacy breach, payment/billing failure, legal/compliance violation.
- **S2-Major**: a core journey broken for a user segment with no workaround, or severe degradation.
- **S3-Minor**: workaround exists.
- **S4-Trivial**: cosmetic.

`**Priority**: [P1-Fix this sprint / P2-Fix soon / P3-Backlog / P4-Won't fix]`

- **P1-Fix this sprint**: blocks QA, blocks a release, or is a regression from the last sprint.
- **P2-Fix soon**: should be resolved before the next milestone.
- **P3-Backlog**: worth fixing, no active blocking impact.
- **P4-Won't fix**: accepted risk or out of scope for the current product scope — set only with the user's approval.

**Status values** (`**Status**:` line): `Open | In Progress | Fixed — Pending Verification | Verified Fixed | Closed | Won't Fix`.

**Unresolved** = Status ∈ {`Open`, `In Progress`, `Fixed — Pending Verification`}. Every count of open
bugs — in gates, the `/team-qa` sign-off, `/release-checklist`, `/milestone-review` and session-start —
uses this definition.

> **These labels must match `/bug-triage`'s tables exactly** — it parses the
> Severity, Priority and Status fields out of the files you write. P4 is the
> easiest to get wrong: a "wishlist" reading ("would be nice someday") and
> `P4-Won't fix` ("accepted risk, not doing it") mean opposite things, and nothing
> at runtime surfaces a disagreement between the file that writes the field and the
> skill that reads it. If you change this ladder, change
> `.claude/skills/bug-triage/SKILL.md` in the same commit.

Production incidents use the separate `SEV1`–`SEV4` scheme of `/incident`; an incident may spawn
S-ladder bugs as follow-ups.

---

## Phase 2A: Description Mode

1. **Parse the description** for key information: what broke, where (surface, screen or endpoint), when, how to reproduce it, and what the expected behavior is.

2. **Search the codebase** for related files using Grep/Glob to add context (affected feature, likely handlers, components, jobs or migrations). Search for the route, operation id, error message or event name the description mentions.

3. **Collect the environment.** A bug without an environment cannot be reproduced. Ask for any field of the Environment block the description does not give; leave `[unknown]` rather than guess.

4. **Draft the bug report**:

```markdown
# Bug Report

## Summary
**Title**: [Concise, descriptive title]
**ID**: BUG-NNNN
**Severity**: [S1-Critical / S2-Major / S3-Minor / S4-Trivial]
**Priority**: [P1-Fix this sprint / P2-Fix soon / P3-Backlog / P4-Won't fix]
**Status**: Open
**Reported**: [YYYY-MM-DD]
**Reporter**: [name or role]

## Classification
- **Category**: [Functional / UI / API / Data / Performance / Security / Privacy / Crash / Accessibility / Localization / Integration]
- **Feature**: [feature slug — `design/prd/<feature>.md`]
- **Surface**: [web | ios | android | mobile | api | admin | infra | analytics]
- **Story**: [`production/epics/<epic-slug>/story-NNN-<slug>.md`, or "None"]
- **Frequency**: [Always / Often (>50%) / Sometimes (10-50%) / Rare (<10%)]
- **Regression**: [Yes/No/Unknown -- was this working before?]

## Environment
- **Environment**: [local / preview URL / staging URL / production]
- **Build / Version**: [web commit SHA or deploy id; app version and build number; API version]
- **Browser / Device / OS**: [browser and version, or device model and OS version]
- **Account & Feature Flags**: [test account or tenant id — never personal data; flag states, e.g. `goals.v2-progress-ring` on]
- **Locale & Network**: [e.g. ko-KR, Wi-Fi / cellular / offline]
- **Request ID / Trace ID**: [request id header, trace id from the tracing backend, error-tracker event id — or "none captured"]

## Reproduction Steps
**Preconditions**: [Account, data and flag state required before starting]

1. [Exact step 1]
2. [Exact step 2]
3. [Exact step 3]

**Expected Result**: [What should happen]
**Actual Result**: [What actually happens — include the HTTP status and error code for API bugs]

## Technical Context
- **Likely affected files**: [List of files based on codebase search]
- **Related features**: [What other features, services or third parties might be involved]
- **Possible root cause**: [If identifiable from the description]

## Evidence
- **Logs**: [Relevant log lines — redact tokens, cookies, card numbers and personal data]
- **Screenshots / recordings**: [paths under `production/qa/evidence/`, or attachments]
- **Request / response**: [redacted request and response snapshot, or HAR excerpt]

## Related Issues
- [Links to related bugs, incidents (`INC-YYYYMMDD-NN`), PRDs or ADRs]

## Notes
[Any additional context or observations]
```

Example for the canonical Moa product: *"Auto-debit deposit recorded twice after the Toss Payments
webhook retried"* — Severity `S1-Critical` (payment/billing failure), Priority `P1-Fix this sprint`,
Feature `payments`, Surface `api`, Environment `staging`, Request ID from the webhook delivery log.

---

## Phase 2B: Analyze Mode

1. **Read the target file(s)** specified in the argument. When `<path>` matches no readable source
   file, stop with `Verdict: **NOT ASSESSED** — nothing analysed at <path>` — never "no bugs found":
   nothing was looked at, so no claim about the code can be made.

2. **Identify potential bugs** — the service failure classes first, then the general ones:
   - **Authorization**: an operation that loads a resource by id without checking the caller owns it
     (BOLA/IDOR — e.g., `GET /goals/{id}` returning another user's goal); admin-only actions reachable
     without a role check; trusting a user id from the request body instead of the session
   - **Input validation**: unvalidated or unbounded input (amounts, page sizes, free text), missing
     schema validation at the API boundary
   - **Data access**: N+1 queries inside list endpoints or resolvers; missing transactions around
     multi-row writes; missing indexes on the filtered columns; unbounded queries without pagination
   - **Concurrency and idempotency**: races on payment webhooks (the same event processed twice with no
     idempotency key or unique constraint), check-then-act on balances, lost updates without optimistic
     locking, duplicate job execution on retry
   - **Resilience**: outbound calls without timeouts or retries with backoff; errors swallowed in
     `catch` blocks or unhandled promise rejections; partial failure leaving inconsistent state
   - **Money and time**: floating-point arithmetic for currency; rounding that does not match the PRD's
     business rules; KST/UTC day boundaries; month-end dates
   - **Privacy**: personal data or tokens written to logs, analytics payloads or error-tracker context
   - **General**: null/undefined dereferences, off-by-one errors, resource leaks (unclosed connections
     or streams), incorrect state transitions

3. **For each potential bug**, generate a bug report using the template above, with the likely trigger scenario and recommended fix filled in. Set **Environment** to `[not reproduced — found by code analysis]`, **Frequency** to `Unknown`, and choose the severity for the impact if it triggers.

---

## Phase 2C: Verify Mode

Read `production/qa/bugs/<BUG-ID>.md`. Extract the reproduction steps, environment and expected result.

Verify expects `**Status**: Fixed — Pending Verification` (the fix is merged and deployed to the environment you verify on). If the status is still `Open` or `In Progress`, ask whether the fix is in before verifying.

1. **Re-run reproduction steps** — use Grep/Glob to check whether the root cause code path still exists as described. If the fix removed or changed it, note the change. For an API bug, re-issue the reproduction request against local or staging via Bash (never a mutating request against production), and compare status and body with the expected result.
2. **Run the related test** — if the bug's feature has a test file (where `testing.patterns` in `project.yaml` says tests live, else `tests/`), run it via Bash — with `commands.test` from `project.yaml` when set — and report pass/fail. Note whether a regression test for this exact scenario exists.
3. **Check for regression** — grep the codebase for any new occurrence of the pattern that caused the bug.

Produce a verification outcome — exactly one of:

- **Verified Fixed** — reproduction steps no longer produce the bug; related tests pass
- **Still Present** — bug reproduces as described; fix did not resolve the issue
- **Cannot Verify** — automated checks inconclusive; manual verification on the environment or device is required

Ask: "May I write this to `production/qa/bugs/<BUG-ID>.md`?" — the status change and a verification note:

- `Verified Fixed` → set `**Status**: Verified Fixed`
- `Still Present` → set `**Status**: Open` and suggest `/hotfix <BUG-ID>` when it is an S1/S2 bug in production, otherwise hand it back to the owner of the fix
- `Cannot Verify` → leave `**Status**: Fixed — Pending Verification`; the note records why and what manual check would settle it

The verification note is appended to the bug file:

```markdown
## Verification Log
- [YYYY-MM-DD] — [Verified Fixed | Still Present | Cannot Verify] — [environment and build verified on] — [evidence: test run, request id, screenshot path] — [reason, for Cannot Verify]
```

A `Cannot Verify` outcome ends, after the approved Verification Log write, with
`Verdict: **NOT ASSESSED** — the fix could not be observed; <the manual check that would settle it>`.
Cannot Verify is not a pass: the bug stays unresolved until a later verify run observes the fix.

---

## Phase 2D: Close Mode

Read `production/qa/bugs/<BUG-ID>.md`. Confirm Status is `Verified Fixed` before closing. If status is anything else, stop: "Bug [ID] must be Verified Fixed before it can be closed. Run `/bug-report verify <BUG-ID>` first."

Append a closure record to the bug file:

```markdown
## Closure Record
**Closed**: [YYYY-MM-DD]
**Resolution**: Fixed — [one-line description of what was changed]
**Fix commit / PR**: [if known]
**Verified by**: qa-engineer
**Closed by**: [user]
**Regression test**: [test file path, or "Manual verification"]
**Status**: Closed
```

Update the top-level `**Status**: Verified Fixed` field to `**Status**: Closed`.

Ask: "May I write this to `production/qa/bugs/<BUG-ID>.md`?" (marks it Closed)

After closing, check `production/qa/bug-triage-*.md` — if the bug appears in a triage report, note: "Bug [ID] is referenced in the triage report. Run `/bug-triage` to refresh the unresolved bug count."

---

## Phase 3: Save Report

Present the completed bug report(s) to the user.

Choose the file name: glob `production/qa/bugs/BUG-*.md`, take the highest number and add one, zero-padded to four digits (the first bug is `BUG-0001`). Several reports from one Analyze run take consecutive numbers.

Ask: "May I write this to `production/qa/bugs/BUG-NNNN.md`?"

If yes, write the file, creating the directory if needed. Verdict: **COMPLETE** — bug report filed.

If no, stop here. Verdict: **BLOCKED** — user declined write.

---

## Phase 4: Next Steps

After saving, suggest based on mode:

**After filing (Description/Analyze mode):**
- Run `/bug-triage` to prioritize alongside the other unresolved bugs
- If S1 or S2 and in production: run `/hotfix <BUG-ID>` for the emergency fix workflow (an ongoing outage is an incident first: `/incident`)

**After fixing the bug (developer sets `**Status**: Fixed — Pending Verification` once the fix is deployed):**
- Run `/bug-report verify <BUG-ID>` — confirm the fix actually works before closing
- Never mark a bug closed without verification — a fix that doesn't verify is still unresolved

**After verify returns Verified Fixed:**
- Run `/bug-report close <BUG-ID>` — write the closure record and update status
- Run `/bug-triage` to refresh the unresolved bug count and remove it from the active list
