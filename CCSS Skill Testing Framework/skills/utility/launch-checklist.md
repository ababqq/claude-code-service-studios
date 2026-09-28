# Skill Spec: /launch-checklist

> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-09-28

## Skill Summary

`/launch-checklist` assembles one readiness record for the first public (GA) launch —
or a later major launch such as a new market, platform or paid tier — across every
department that must be ready on launch day. It reads the evidence earlier skills
produced (release checklist, rollout plan, security audits, smoke check, QA sign-off,
hardening, load and performance reports, usability evidence, localization QA, bugs,
SLOs, runbooks, tracking plan, help center), consults `sre-engineer` and
`security-engineer` in parallel as consultants (never as director gates, at every
review mode), and scopes every conditional item from the resolved `rigor`,
`project.stage`, `release.distribution`, `platform.surfaces`, `compliance` and
`accessibility.target` values. Unset values are questions; items whose input is absent
are `[?]`.

The departments are the exact `##` headings `## Product`, `## Engineering & SRE`,
`## Security & Privacy`, `## Legal`, `## Support`, `## Go-to-Market`, `## Analytics` and
`## Sign-offs`; regional items come from `.claude/docs/compliance/<region>.md` for each
configured region. Output: `production/releases/<version>/launch-checklist.md` with
`> **Verdict**: GO | NO-GO | NOT ASSESSED` directly under its H1 (precedence NO-GO >
NOT ASSESSED > GO). `dry-run` builds the checklist in the conversation with a
provisional verdict and writes nothing.

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`); `name: launch-checklist` equals the skill directory and the catalog `name`
- [ ] Bootstrap: the first body line is exactly `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys rigor,project.stage,distribution,surfaces,compliance,accessibility,automation` `` and `allowed-tools` grants `Bash(bash "*/.claude/skills/launch-checklist/../../hooks/yaml-helper.sh" resolve_config *)`
- [ ] `--keys` is exactly `rigor,project.stage,distribution,surfaces,compliance,accessibility,automation` — no `review_mode`
- [ ] The line after the bootstrap block is exactly ``Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] Automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") present verbatim right after that line
- [ ] `allowed-tools` is exactly: `Read, Glob, Grep, Write, Agent, AskUserQuestion` plus the bootstrap grant — no `Edit`, no plain `Bash`
- [ ] `argument-hint` is `"[version] [dry-run]"`
- [ ] 2+ phase headings found (`## Phase 0: Parse Arguments and Resolve Scope` … `## Phase 7: Next Steps`)
- [ ] Verdict keywords present, exactly: `GO`, `NO-GO`, `NOT ASSESSED`; item markers `[x]`, `[ ]`, `[~]`, `[?]` and `N/A — <condition> not configured`
- [ ] The eight department headings above appear in the checklist template in that order
- [ ] "May I write this to `production/releases/<version>/launch-checklist.md`?" before the single write
- [ ] Output at the exact path `production/releases/<version>/launch-checklist.md`, with `> **Verdict**: [GO | NO-GO | NOT ASSESSED]` directly under its H1
- [ ] No `!` injection other than the bootstrap line; no `file:line` citations of other files
- [ ] Next-step handoff present at end (closing `AskUserQuestion`), naming current skills: `/rollout-plan`, `/release-checklist`, `/smoke-check`, `/team-qa`, `/team-hardening`, `/security-audit`, `/load-test`, `/incident runbook`, `/team-content`, `/release-notes`, `/localize qa`, `/usability-report`, `/bug-triage`, `/gate-check launch`, `/team-release`

---

## Director Gate Checks

- **N/A**: `/launch-checklist` spawns no director gate at any review mode, and
  `review_mode` is not among its keys. The production readiness review
  (SR-PRODUCTION-READINESS) lives in `/rollout-plan`; this checklist reads its verdict.
  `sre-engineer` and `security-engineer` are consultants that run on every invocation
  whatever `modes.review_mode` says — Case 6 asserts this.

---

## Test Cases

Fixtures use the canonical product Moa (web + iOS + Android + API, Korean market).

### Case 1: Happy Path — GA launch of Moa 1.0.0 returns GO

**Fixture** (assumed project state):
- `project.yaml`: `project.version: 1.0.0`, `project.stage: Hardening`, `modes.rigor: standard`, `release.distribution: web+stores`, `platform.surfaces: [web, ios, android, api]`, `compliance.regions: [kr]`, `privacy.handles_pii: true`, `accessibility.target: wcag-aa`, `localization.locales: [ko-KR, en-US]`
- `production/releases/1.0.0/release-checklist.md` (`> **Verdict**: GO`) and `rollout-plan.md` (`> **Verdict**: READY TO ROLL OUT`, with the line under `## Production Readiness Review`)
- Newest reports with passing verdicts: `production/qa/smoke-*.md` PASS on the release candidate, `qa-signoff-*.md` APPROVED, `hardening-*.md` READY, `production/security/security-audit-full-*.md` without open Critical/High, `production/qa/localization-qa-*.md` PASS, `production/qa/load/load-test-*.md` PASS
- 23 bug files, none unresolved S1/S2; `docs/ops/slo.md` with an SLO per critical journey; one runbook per paging alert

**Expected behavior**:
1. Phase 0 announces the scope in one block: version, rigor, stage, distribution, surfaces, regions, `handles_pii`, accessibility target, locales, and which conditional blocks are in or out
2. Phase 1 reads each report's `> **Verdict**:` line and states denominators (`checked 23 bug files, 0 unresolved S1/S2`, `6 paging alerts, 6 runbooks`)
3. Phase 2 spawns `sre-engineer` and `security-engineer` in parallel; neither writes a file
4. Phase 3 fills every department block; Phase 4 lists every item of `.claude/docs/compliance/kr.md` under `### Regional Compliance: kr`
5. Phase 5 asks who signs each department; Phase 6 asks "May I write this to `production/releases/1.0.0/launch-checklist.md`?"

**Assertions**:
- [ ] Every `[x]` names its evidence (a path with its verdict line, a URL, or a person and date)
- [ ] Both consultants are spawned before either result is awaited, and the block headers record the consult date
- [ ] The regional list is derived from the whole `kr` file, not a chosen subset
- [ ] Sign-offs are recorded only as the user states them
- [ ] `> **Verdict**: GO` sits directly under the H1 of the written file
- [ ] The closing widget offers `/gate-check launch` and then `/team-release`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure / Blocked — Launch-gate floors cannot be accepted

**Fixture**:
- Same as Case 1, except `production/qa/bugs/BUG-0012.md` is `S1-Critical` with `**Status**: Fixed — Pending Verification`, and the newest smoke report on the release candidate is `PASS WITH WARNINGS`
- The user asks to accept both items for launch

**Expected behavior**:
1. The "No unresolved S1 or S2 bugs" item stays `[ ]` — `Fixed — Pending Verification` is unresolved
2. The smoke item stays `[ ]` with the verdict quoted — PASS WITH WARNINGS does not satisfy it
3. The skill refuses `[~]` for both: gate floors are never accepted
4. Verdict NO-GO; the closing widget offers `/bug-triage` (open S1/S2 bug), `/smoke-check` (no PASS on the release candidate) and a re-run of `/launch-checklist 1.0.0`

**Assertions**:
- [ ] Verdict is NO-GO
- [ ] Neither floor item is written `[~]` even when the user asks
- [ ] `### Blocking Items` lists both with owner and target date
- [ ] Nothing is written before "May I write this to `production/releases/1.0.0/launch-checklist.md`?"

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: NOT ASSESSED — Missing security audit and unset distribution

**Fixture**:
- No file matches `production/security/security-audit-*.md`
- `release.distribution` is absent from `project.yaml` (the resolved line reads `release.distribution: (unset -- ask how this release ships)`) and the user cannot answer this session
- Every other blocking item is `[x]`

**Expected behavior**:
1. The security audit item is `[?]` — a missing report is not a passing report
2. Every distribution-dependent item is `[?]` with `NOT ASSESSED — release.distribution unset`; the skill never emits every track
3. The file carries the legend line `[?] = not assessed — the input to this check was absent`
4. `### Not Assessed` names each missing input and the skill that produces it (`/security-audit full`, `/setup-stack`)

**Assertions**:
- [ ] Verdict is NOT ASSESSED — no blocking item is open, at least one is `[?]`
- [ ] No GO is produced while any blocking item is `[?]`
- [ ] Unset distribution is not treated as `web` or as "all tracks"
- [ ] `[?]` and `[ ]` are never merged

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Mode Variant — `dry-run` and `rigor: minimal`

**Fixture**:
- Same evidence as Case 1; `modes.rigor: minimal`; `project.stage: Build`

**Input**: `/launch-checklist 1.0.0 dry-run`

**Expected behavior**:
1. The earlier stage is announced ("Most launch evidence will not exist yet") and `dry-run` is recommended; the user continues
2. Items marked *(blocking: standard, full)* are written *(recommended)* at `minimal`
3. No sign-offs are requested; the skill prints `Provisional verdict (dry run): <TOKEN>` and writes no file

**Assertions**:
- [ ] No write tool is called in `dry-run`
- [ ] The rigor downgrade applies only to the marked items; floor items (smoke PASS, no unresolved S1/S2, security audit without open Critical) stay blocking
- [ ] The closing widget offers running `/launch-checklist 1.0.0` without `dry-run`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Edge Case — Explicit "none" values and contradictions

**Fixture**:
- `compliance.regions: []`, `release.distribution: internal`, `accessibility.target: none`, `platform.surfaces: [web]`
- A later edit changes regions to `[kr]` while `accessibility.target` stays `none`

**Expected behavior**:
1. With `regions: []`, the checklist writes `Regional compliance: none — compliance.regions is [] (explicitly none)`
2. With `internal`, public go-to-market items are `N/A — internal distribution`; the employee notice and internal support path replace them
3. With `none`, the accessibility item is `N/A — accessibility.target is none (decided)`
4. With `[kr]` and `none`, the contradiction with the region's `## Accessibility` items is written as an open item naming it

**Assertions**:
- [ ] `[]` (explicitly none) and unset produce different output
- [ ] Every skipped item announces its condition; no conditional item is dropped silently
- [ ] Contradictions are open items, never resolved silently
- [ ] Any deadline, fine or threshold entered for a regional item carries `(Source: <url>, retrieved YYYY-MM-DD)` or reads `NOT SOURCEABLE — confirm with counsel`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Consultants Run at Every Review Mode — no director gate

**Fixture**:
- Same as Case 1; `modes.review_mode: solo` set in `project.local.yaml`

**Expected behavior**:
1. The skill does not resolve `review_mode` and does not branch on it
2. `sre-engineer` and `security-engineer` are still spawned in Phase 2
3. No director gate is spawned and no `[GATE-ID] skipped` note appears

**Assertions**:
- [ ] Both consultants run despite `solo`
- [ ] No gate ID (SR-PRODUCTION-READINESS or any other) is spawned by this skill
- [ ] A consult that fails leaves its block marked `sre-engineer consult incomplete — <reason>` (or `security-engineer …`) and offers a re-run

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses "May I write this to `<path>`?" before the single write; writes nothing in `dry-run`
- [ ] Presents each department block before requesting approval
- [ ] Ends with the closing `AskUserQuestion` widget recommending the next skill and waiting
- [ ] Does not auto-create files without user approval; never commits
- [ ] Writes no evidence, reports or plans under `production/session-logs/`
- [ ] Never writes `modes.review_mode` or any other knob that `modes.rigor` fronts
- [ ] Records sign-offs and acceptances only as the user states them — never on someone's behalf, and in `autonomous` mode sign-off lines stay `pending`

---

## Coverage Notes

- The B2B, `enterprise` and `api` conditional items follow the same scoping rule as
  Case 5 and are not fixture-tested one by one. *B2B* is what the user confirms in
  Phase 0; `project.category` is free text that only prompts the question, never the
  condition itself.
- Regional item content comes from `.claude/docs/compliance/<region>.md`; this spec
  checks that the list is derived from the file, not what each law requires.
- Reuse of the latest audit's `## Regional Compliance` statuses (`Met` → `[x]`,
  `Gap` → `[ ]`, `Accepted` → `[~]`) is exercised only implicitly in Case 1.
- Carrying forward sign-offs from an existing checklist (Phase 0c) needs a live
  re-run to verify.
