# Skill Spec: /postmortem

> **Category**: ops
> **Priority**: medium
> **Spec written**: 2026-09-28

## Skill Summary

`/postmortem <INC-id>` turns a resolved incident record into a **blameless
postmortem** at `production/incidents/postmortems/INC-YYYYMMDD-NN.md`, written
from `.claude/docs/templates/incident-postmortem.md` with the sections Summary,
Impact, Timeline, Detection & Response metrics (time to detect / mitigate /
resolve), Contributing Factors (causal analysis, 5 whys), What Went Well, What
Went Poorly, Where We Got Lucky, Action Items (owner, priority, due, type
`prevent | detect | mitigate`) and Runbook Changes. It reads the incident record
and its linked evidence (hotfix records, the rollout plan and release record,
`docs/ops/slo.md`, runbooks, linked bugs, ADRs, earlier postmortems), spawns
`sre-engineer` and `tech-lead` in parallel for drafts, drafts section by section,
and runs a **blameless check** that flags person-blaming phrasing and names
attached to errors and proposes system-focused rewrites. Action items are routed
to `/bug-report`, `/tech-debt` or `/incident runbook` (asked per item). The verdict
is COMPLETE / INCOMPLETE — MISSING <sections>, or run-level NOT ASSESSED when there is no
incident record. It is required for every SEV1 and
SEV2 incident. Unlike the other ops skills, it honours `modes.automation` for its
questions — but asks "May I write" before every write in every mode. It spawns no
director gate.

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`); `name: postmortem` equals the skill directory and the catalog `name`; `model: sonnet`
- [ ] `argument-hint` is `"<INC-id>"`; no `disable-model-invocation`, no `isolation`
- [ ] Bootstrap: the first body line is `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation` `` and `allowed-tools` grants `Bash(bash "*/.claude/skills/postmortem/../../hooks/yaml-helper.sh" resolve_config *)`
- [ ] The line after the bootstrap block is exactly: ``Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] The automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") follows that line verbatim
- [ ] `allowed-tools` is exactly: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, plus the grant (membership exact, order free — no plain Bash)
- [ ] 2+ phase headings found
- [ ] Verdict keywords present, exactly: `COMPLETE` and `INCOMPLETE — MISSING <sections>` (the skill's could-not-complete token, naming the missing sections); `NOT ASSESSED` as the run-level verdict of the Phase 0 stop (never written into a postmortem file)
- [ ] "May I write this to `production/incidents/postmortems/<INC-id>.md`?" and "May I write this to `production/incidents/<INC-id>.md`?" before each write
- [ ] Outputs at the exact path `production/incidents/postmortems/INC-YYYYMMDD-NN.md` (the incident's ID); the postmortem's H1 is followed, after one blank line, by `> **Verdict**: <TOKEN>`
- [ ] The section headings are those of `.claude/docs/templates/incident-postmortem.md`, in its order
- [ ] Severity tokens are exact: `SEV1`–`SEV4` for the incident; follow-up defects are routed to `/bug-report` (S-ladder severity, set there); action-item priorities on the `P1-Fix this sprint` / `P2-Fix soon` / `P3-Backlog` ladder
- [ ] No `!` injection other than the bootstrap line; no `file:line` citations of other files
- [ ] Next-step handoff section present at end (Phase 7), naming skills by their current names

---

## Director Gate Checks

- **Full / Lean / Solo mode**: not applicable — `review_mode` is not among the keys and the skill states there is no director gate in it.
- **N/A**: `sre-engineer` and `tech-lead` return drafts in their replies; they write no file and assign no blame. Their drafts are not gate verdicts.

---

## Test Cases

### Case 1: Happy Path — a complete postmortem for a SEV2

**Fixture** (assumed project state):
- `production/incidents/INC-20261104-01.md`: `**Severity**: SEV2`, `**Status**: RESOLVED`, `> **Verdict**: RESOLVED — POSTMORTEM REQUIRED`; full `## Timeline` in UTC and KST (impact start 00:40 UTC, detected 00:52, mitigated 01:31, resolved 02:05); `## Customer Impact` with final numbers
- `production/hotfixes/hotfix-2026-11-04-auto-debit-retry.md` references the INC-id; `production/releases/2.4.0/rollout-plan.md` and `release-record.md` exist; `docs/ops/slo.md` and `docs/ops/runbooks/auto-debit-failure-rate.md` exist
- No file under `production/incidents/postmortems/` yet

**Input**: `/postmortem INC-20261104-01`

**Expected behavior**:
1. Phase 1 reads the record and the linked evidence with Read, Glob and Grep only, and asks for values it cannot observe ("Can you give me <value> from <source>?")
2. Phase 2 spawns `sre-engineer` and `tech-lead` in one parallel batch, instructed to write blameless and to write no file
3. Phase 3 drafts section by section in the template's order, asking for approval before the next
4. Detection & Response metrics are computed from the timeline — time to detect 12 min, to mitigate 51 min, to resolve 85 min — showing the timestamps used
5. Action items are specific, owned and dated, each typed `prevent`, `detect` or `mitigate`
6. Phase 4 blameless check finds nothing to flag; verdict COMPLETE
7. "May I write this to `production/incidents/postmortems/INC-20261104-01.md`?", then the offer to link it from the incident record ("May I write this to `production/incidents/INC-20261104-01.md`?")
8. Phase 6 asks per action item where it is tracked; Phase 7 closes with `/incident runbook <alert-slug>` for each runbook change

**Assertions**:
- [ ] The postmortem is written from `.claude/docs/templates/incident-postmortem.md` with every template heading present
- [ ] Both agent drafts come back in replies; neither agent writes a file
- [ ] The metrics are computed from recorded timestamps, not estimated
- [ ] The saved file's H1 is followed by `> **Verdict**: COMPLETE`
- [ ] The incident record's `> **Postmortem**:` header line and `## Follow-ups` table are updated only after their own approval
- [ ] The skill does not create bug or tech-debt entries itself; it records the chosen route in each item's `Tracking` cell after "May I write"

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — the incident is not resolved yet

**Fixture**:
- `production/incidents/INC-20261110-01.md`: `**Severity**: SEV1`, `**Status**: MITIGATED`

**Input**: `/postmortem INC-20261110-01`

**Expected behavior**:
1. Phase 0 checks the premise and says a postmortem written before resolution misses the end of the story
2. The skill asks `Resolve first (/incident resolve <INC-id>)` (Recommended) / `Draft now and finish after resolution` / `Stop`
3. On `Stop`: nothing is written. On `Draft now`: the draft ends with `INCOMPLETE — MISSING <sections>` until it is completed

**Assertions**:
- [ ] The skill does not silently draft a postmortem for an unresolved incident
- [ ] A draft written now never carries `COMPLETE`
- [ ] Resolving is recommended through `/incident resolve <INC-id>`, not done by this skill

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: NOT ASSESSED — no incident record

**Fixture**:
- `production/incidents/INC-20261201-03.md` does not exist

**Input**: `/postmortem INC-20261201-03`

**Expected behavior**:
1. Phase 0 cannot read the record
2. The skill stops: "No incident record `production/incidents/<INC-id>.md` — run `/incident open` to create one, or give the correct ID. Verdict: NOT ASSESSED — no incident record."
3. Nothing is drafted or written

**Assertions**:
- [ ] The missing input is named (the incident record path) together with the skill that produces it (`/incident open`)
- [ ] No postmortem file is written and no COMPLETE verdict is produced for an incident nobody recorded
- [ ] The run ends with Verdict NOT ASSESSED
- [ ] A value that nobody can supply during a real run (e.g. an unknown impact start) is written `NOT DETERMINED — <reason>`, and the three impact-based metrics read `NOT DETERMINED — impact start unknown` — never estimated silently

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Mode Variant — autonomous questions, approved writes

**Fixture**:
- As Case 1; `project.yaml` sets `modes.automation: autonomous`

**Expected behavior**:
1. Questions follow the resolved `modes.automation` (the prelude is present): the skill may proceed through section drafting per `.claude/docs/automation-modes.md`
2. Every write still asks first: the postmortem and the incident record

**Assertions**:
- [ ] SKILL.md states that every write asks first in every mode — a postmortem is a record about people's work, and its blameless rewrites need a human's approval
- [ ] "May I write this to `production/incidents/postmortems/<INC-id>.md`?" is asked even under `autonomous`
- [ ] The output under `autonomous` differs from Case 1 only in the questions the mode lets the skill skip, never in the writes

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Edge Case — the blameless check

**Fixture**:
- As Case 1, but the tech-lead draft of Contributing Factors contains "Minji deployed the broken build", "Root cause: human error", and "If they had just checked the dashboard, this would not have happened"

**Expected behavior**:
1. Phase 4 lists each flagged phrase with a system-focused rewrite (e.g. "The 2.4.0 build reached 25% of traffic; the canary guardrail did not include the iOS goal-creation error rate")
2. The skill asks "I found [N] phrases that attach the failure to people. Apply the rewrites?" with `Apply all rewrites (Recommended)` / `Review each` / `Keep as written`
3. On `Keep as written`, a note is recorded under `## What Went Poorly` that the review chose to keep that wording

**Assertions**:
- [ ] A name attached to an error, blame verbs, "human error" as a cause and counterfactual hindsight are all flagged
- [ ] Names may appear only in `> **Authors**:` and as action-item owners
- [ ] A kept phrase is recorded, not hidden — the check announces itself

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Edge Case — action items that do not hold up

**Fixture**:
- As Case 1, but the drafted action items are: "Be more careful with deploys" (no owner), "Improve monitoring" (no due date), and no item of type `detect` or `mitigate` exists
- `production/incidents/postmortems/INC-20261104-01.md` already exists with `> **Verdict**: INCOMPLETE — MISSING Contributing Factors, Action Items`

**Expected behavior**:
1. Phase 0 reads the existing postmortem and asks `Complete the missing sections` / `Revise the whole document` / `Stop`
2. Vague items are rewritten into checkable ones ("page on goal-creation error-budget burn at 14.4× over 1 h"); items without an owner or due date are not accepted
3. A SEV1/SEV2 postmortem without any `detect` or `mitigate` item prompts: "Nothing would make this faster to notice or smaller next time?"
4. When every section has content, the verdict becomes COMPLETE

**Assertions**:
- [ ] The verdict names the empty sections by heading text while any remain (`INCOMPLETE — MISSING Contributing Factors, Action Items`); placeholder text in brackets counts as empty
- [ ] An existing postmortem is completed or revised, never overwritten without asking
- [ ] Every accepted action item has an owner, a due date, a type and a priority

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses "May I write this to `<path>`?" before every write — the postmortem and the incident record — in every automation mode
- [ ] Presents each drafted section before requesting approval (Question → Options → Decision → Draft → Approval)
- [ ] Ends with a recommended next step (`/incident runbook <alert-slug>`, `/bug-report`, `/tech-debt`, `/postmortem <INC-id>` again when incomplete, `/retrospective release <version>` when the incident came from a release)
- [ ] Does not auto-create files without user approval; commits nothing
- [ ] Writes no evidence, reports or plans under `production/session-logs/` (gitignored)
- [ ] Never writes `modes.review_mode` or any other knob that `modes.rigor` fronts (`/settings` is the one exception)
- [ ] Shows both views when `sre-engineer` and `tech-lead` read the incident differently — never merges them silently

---

## Coverage Notes

- The no-argument listing of owed postmortems (incidents whose verdict is
  `RESOLVED — POSTMORTEM REQUIRED` with no postmortem file) is not tested.
- SEV3 and SEV4 incidents (postmortem optional — the skill asks whether to
  continue) are not tested.
- A repeat incident found through earlier postmortems ("a repeat is a finding in
  itself") is not fixture-tested.
- `ops` O2 (never mutates production) holds trivially here: the skill
  has no plain `Bash` and runs no commands.
