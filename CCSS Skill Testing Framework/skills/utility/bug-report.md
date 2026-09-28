# Skill Test Spec: /bug-report

## Skill Summary

`/bug-report` files a structured bug report for a web, mobile or API product. It has
four modes: **Description** (a report from the user's description), **Analyze**
(`analyze <path>` — reads code and files one report per potential bug), **Verify**
(`verify <BUG-ID>` — confirms that a deployed fix resolved the bug) and **Close**
(`close <BUG-ID>` — writes the closure record of a verified bug).

Every report is written to `production/qa/bugs/BUG-NNNN.md` — four digits, no slug,
numbered as the highest existing number plus one — after a "May I write this to
`<path>`?" ask. The report carries a Classification block (Category, Feature, Surface,
Story, Frequency, Regression), a service **Environment** block (environment, build or
version, browser/device/OS, account and feature flags, locale and network, request or
trace ID) and the shared severity/priority/status ladder that `/bug-triage`, `/team-qa`,
`/hotfix`, the phase gates and session-start parse:

- `**Severity**: [S1-Critical / S2-Major / S3-Minor / S4-Trivial]`
- `**Priority**: [P1-Fix this sprint / P2-Fix soon / P3-Backlog / P4-Won't fix]`
- Status values `Open | In Progress | Fixed — Pending Verification | Verified Fixed | Closed | Won't Fix`

Filing ends with **COMPLETE** (written) or **BLOCKED** (the user declined the write).
Verify mode ends with exactly one outcome — `Verified Fixed`, `Still Present` or
`Cannot Verify` — and `Cannot Verify` is the skill's could-not-assess value: after the
approved Verification Log write the run ends
`Verdict: **NOT ASSESSED** — the fix could not be observed; <the manual check that would settle it>`
and the status stays `Fixed — Pending Verification`. Analyze Mode on a path with no
readable source file stops with `Verdict: **NOT ASSESSED** — nothing analysed at <path>`,
never "no bugs found". No director gates apply.

---

## Static Assertions (Structural)

Verified automatically by `/skill-test static` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] `name: bug-report` equals the directory `.claude/skills/bug-report/` and the catalog entry name
- [ ] First body line is exactly `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation` `` — `--keys` is exactly `automation`
- [ ] `allowed-tools` grants `Bash(bash "*/.claude/skills/bug-report/../../hooks/yaml-helper.sh" resolve_config *)` (this skill's own directory)
- [ ] The line after the bootstrap block is exactly ``Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] The automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") follows that line verbatim
- [ ] `allowed-tools` is exactly `Read, Glob, Grep, Bash, Write, Edit` plus the bootstrap grant — no `Agent`, no `AskUserQuestion`
- [ ] Has ≥2 phase headings (`## Phase 1: Parse Arguments` … `## Phase 4: Next Steps`)
- [ ] Contains verdict keywords COMPLETE, BLOCKED and NOT ASSESSED, and the three verification outcomes `Verified Fixed`, `Still Present`, `Cannot Verify`
- [ ] Contains the ladder strings exactly as above, the six status values, and the definition **Unresolved** = Status ∈ {`Open`, `In Progress`, `Fixed — Pending Verification`}
- [ ] Contains "May I write this to `production/qa/bugs/BUG-NNNN.md`?" before filing and "May I write this to `production/qa/bugs/<BUG-ID>.md`?" before the verify and close updates
- [ ] Output path is exactly `production/qa/bugs/BUG-NNNN.md` (no slug, no date); no other artifact path is written
- [ ] No `!` injection other than the bootstrap line; no `file:line` citation of another file
- [ ] Has a next-step handoff naming current skills (`/bug-triage`, `/hotfix <BUG-ID>`, `/incident`, `/bug-report verify <BUG-ID>`, `/bug-report close <BUG-ID>`)

---

## Director Gate Checks

None. `/bug-report` is an operational QA utility: it spawns no agent and no director
gate, and `review_mode` is not among its keys.

---

## Test Cases

### Case 1: Happy Path — Payment bug from a description, full report filed

**Fixture:**
- Canonical product Moa; `production/qa/bugs/` holds `BUG-0001.md` … `BUG-0011.md`
- `design/prd/payments.md` exists; the webhook handler lives under `apps/api/src/payments/`

**Input:** `/bug-report Auto-debit deposit recorded twice after the Toss Payments webhook retried on staging`

**Expected behavior:**
1. Skill parses what broke (duplicate deposit), where (`api` surface, the deposit webhook) and when (a webhook retry)
2. Skill greps the codebase for the webhook route and the deposit handler and lists the likely affected files
3. Skill asks for the Environment fields the description does not give (build or deploy id, request ID / trace ID of the webhook delivery)
4. Skill drafts the report: Severity `S1-Critical` (payment/billing failure), Priority `P1-Fix this sprint`, `**Status**: Open`, Feature `payments`, Surface `api`, Environment `staging`
5. Skill takes the next number and asks "May I write this to `production/qa/bugs/BUG-0012.md`?"
6. File is written on approval; verdict is COMPLETE

**Assertions:**
- [ ] File name is `BUG-0012.md` — highest existing number + 1, zero-padded to four digits, no slug
- [ ] Severity and Priority lines use the exact ladder strings (`S1-Critical`, `P1-Fix this sprint`)
- [ ] The Environment block is present with all six fields; unknown fields read `[unknown]`, never a guessed value
- [ ] Evidence lines redact tokens, cookies, card numbers and personal data
- [ ] "May I write this to `production/qa/bugs/BUG-0012.md`?" is asked before the write
- [ ] Verdict is COMPLETE
- [ ] Next steps offer `/bug-triage`; `/hotfix BUG-0012` is offered only for an S1/S2 bug in production (and `/incident` for an ongoing outage) — this one was found on staging

---

### Case 2: Minimal Input — Skill collects the environment instead of guessing

**Fixture:**
- No bug files exist yet
- User provides only: "Sometimes the goal progress ring shows 0%"

**Input:** `/bug-report Sometimes the goal progress ring shows 0%`

**Expected behavior:**
1. Skill identifies what the description lacks: reproduction steps, expected vs actual result, surface, build/version, browser/device/OS, flag state (`goals.v2-progress-ring`)
2. Skill asks for the missing Environment and reproduction fields
3. User answers some fields and says the build number is unknown
4. Skill drafts the report with `[unknown]` for the build and Frequency `Sometimes (10-50%)`
5. Skill asks "May I write this to `production/qa/bugs/BUG-0001.md`?" and writes on approval

**Assertions:**
- [ ] The first bug of a project is `BUG-0001.md`
- [ ] Follow-up questions cover the Environment block, not only the reproduction steps
- [ ] A field the user cannot supply is written `[unknown]` — not invented, not dropped
- [ ] Verdict is COMPLETE after the approved write

---

### Case 3: Analyze Mode — Service failure classes found in code

**Fixture:**
- `apps/api/src/goals/goals.controller.ts` loads a goal by id without checking the caller owns it, and its list endpoint queries each goal's deposits inside a loop

**Input:** `/bug-report analyze apps/api/src/goals/goals.controller.ts`

**Expected behavior:**
1. Skill reads the target file
2. Skill identifies an authorization bug (BOLA/IDOR — `GET /goals/{id}` can return another user's goal) and an N+1 query in the list endpoint
3. Skill drafts one report per potential bug with the trigger scenario and recommended fix, Environment `[not reproduced — found by code analysis]`, Frequency `Unknown`
4. Skill assigns consecutive numbers and asks "May I write this to `production/qa/bugs/BUG-NNNN.md`?" per report

**Assertions:**
- [ ] The authorization bug is classified by impact — a privacy breach is `S1-Critical`
- [ ] Environment and Frequency carry the code-analysis values, not a fabricated environment
- [ ] Each potential bug is its own `BUG-NNNN.md`, numbered consecutively
- [ ] No file is written without approval

---

### Case 4: NOT ASSESSED — Verify with no way to observe the fix (`Cannot Verify`)

**Fixture:**
- `production/qa/bugs/BUG-0007.md` exists: Surface `ios`, `**Status**: Fixed — Pending Verification`
- The reproduction needs a physical iOS device; no automated test covers the scenario; the root-cause code path was rewritten, so a grep neither confirms nor refutes the fix

**Input:** `/bug-report verify BUG-0007`

**Expected behavior:**
1. Skill reads the bug file and its reproduction steps and environment
2. Skill checks the code path, looks for a related test where `testing.patterns` says tests live (else `tests/`) and finds none
3. Skill cannot establish the result and reports the outcome `Cannot Verify`, naming the manual check that would settle it (a run on an iOS device with the fixed build)
4. Skill asks "May I write this to `production/qa/bugs/BUG-0007.md`?" and appends a `## Verification Log` line
5. After the approved write, the run ends `Verdict: **NOT ASSESSED** — the fix could not be observed; <the manual check that would settle it>` (here: a run on an iOS device with the fixed build)

**Assertions:**
- [ ] Outcome is `Cannot Verify` — never `Verified Fixed` without observed evidence
- [ ] `**Status**` stays `Fixed — Pending Verification`; the note records why verification was not possible
- [ ] The Verification Log line names the environment/build checked and the missing evidence
- [ ] The run ends with the line `Verdict: **NOT ASSESSED** — the fix could not be observed; …` naming the manual check — never COMPLETE
- [ ] The bug remains unresolved for every reader of the Unresolved definition

---

### Case 5: Close Mode Guard — Close requires `Verified Fixed`

**Fixture:**
- `production/qa/bugs/BUG-0009.md` has `**Status**: Fixed — Pending Verification`

**Input:** `/bug-report close BUG-0009`

**Expected behavior:**
1. Skill reads the bug file and checks its status
2. Skill stops with: "Bug BUG-0009 must be Verified Fixed before it can be closed. Run `/bug-report verify BUG-0009` first."
3. No closure record is written

**Assertions:**
- [ ] Close refuses any status other than `Verified Fixed`
- [ ] No write tool is called
- [ ] `/bug-report verify BUG-0009` is named as the next step
- [ ] After a later successful verify, close appends a `## Closure Record` and sets `**Status**: Closed` only after "May I write this to `production/qa/bugs/BUG-0009.md`?"

---

### Case 6: Verify Mode — `Still Present` reopens the bug

**Fixture:**
- `production/qa/bugs/BUG-0012.md` (from Case 1) has `**Status**: Fixed — Pending Verification`
- Re-issuing the recorded webhook twice against staging still records two deposits

**Input:** `/bug-report verify BUG-0012`

**Expected behavior:**
1. Skill re-runs the reproduction against staging with Bash — never a mutating request against production
2. Skill runs the related test with `commands.test` from `project.yaml` when it is set
3. Outcome is `Still Present`; skill asks "May I write this to `production/qa/bugs/BUG-0012.md`?"
4. On approval, `**Status**` is set back to `Open` and a Verification Log line is appended

**Assertions:**
- [ ] Outcome is exactly one of the three tokens — here `Still Present`
- [ ] Status returns to `Open`
- [ ] Because the bug is S1, `/hotfix BUG-0012` is suggested when it is in production; otherwise it is handed back to the owner of the fix
- [ ] No request is issued against a production environment

---

### Case 7: Director Gate Check — No gate; bug reporting is operational

**Fixture:**
- Any bug description provided

**Input:** `/bug-report [description]`

**Expected behavior:**
1. Skill creates and writes the bug report
2. No agents or director gates are spawned
3. No gate IDs appear in output

**Assertions:**
- [ ] No director gate is invoked and no gate skip note appears
- [ ] The verdict is COMPLETE (or BLOCKED on a declined write) without any gate check

---

### Case 8: NOT ASSESSED — Analyze Mode on a path with no readable source file

**Fixture:**
- `apps/api/src/payments/` does not exist (the module was renamed); nothing matches the path

**Input:** `/bug-report analyze apps/api/src/payments/`

**Expected behavior:**
1. Skill tries to read the target and finds no readable source file at the path
2. Skill stops with `Verdict: **NOT ASSESSED** — nothing analysed at apps/api/src/payments/`

**Assertions:**
- [ ] The output never says "no bugs found" or implies the code is clean
- [ ] No bug report is drafted and no write is proposed
- [ ] The verdict is NOT ASSESSED naming the path, never COMPLETE

---

## Protocol Compliance

- [ ] Uses the severity, priority and status strings exactly as `/bug-triage` parses them
- [ ] Collects the Environment block and leaves unknown fields `[unknown]` rather than guessing
- [ ] Asks "May I write this to `<path>`?" before filing, before a verify update and before a close
- [ ] Writes only under `production/qa/bugs/`; never under `production/session-logs/`
- [ ] Never marks a bug `Verified Fixed` or `Closed` without the verification evidence the mode requires
- [ ] Never issues a mutating request against production during verification
- [ ] Ends with the next-step handoff for the mode it ran

---

## Coverage Notes

- Duplicate detection is not part of this skill's contract; `/bug-triage` surfaces
  clusters (same feature, same surface, same story) instead.
- A user who insists on a severity lower than the impact suggests is not
  fixture-tested; the skill states that severity is impact and priority is
  scheduling, and records the reason for a lowered priority.
- Numbering races (two sessions filing at once) are not tested; the next number is
  derived from a glob of `production/qa/bugs/BUG-*.md` at write time.
- `Won't Fix` is set by `/bug-triage` with the user's approval, not by this skill.
