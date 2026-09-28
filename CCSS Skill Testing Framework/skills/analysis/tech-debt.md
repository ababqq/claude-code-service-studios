# Skill Test Spec: /tech-debt

## Skill Summary

`/tech-debt` tracks, categorizes and prioritizes technical debt in
`docs/tech-debt-register.md`. It has four subcommands: `scan` searches the resolved
code roots (from the `code_roots` line, pruning dependency and build directories) for
`TODO`, `FIXME`, `HACK`, `@deprecated` and calls to deprecated stack APIs,
lint/type suppressions, skipped tests, duplication and oversized files and functions,
and checks the tech radar (`## Hold` libraries and `## Forbidden Patterns` in
`docs/architecture/tech-radar.md`); `add` collects one entry through two
`AskUserQuestion` calls for the category and one for the effort; `prioritize`
re-scores the register by `(impact_if_unfixed × frequency_of_encounter) / fix_effort`,
listing exploitable Security Debt first; `report` summarizes the register in the
conversation. Every entry carries exactly one of nine categories — Architecture, Code
Quality, Test, Documentation, Dependency, Performance, Security, Infra and
Observability Debt. The skill asks before every register write. Verdicts: **COMPLETE**
(written or reported), **BLOCKED** (user declined the write), **FAIL** (missing
subcommand), **NOT ASSESSED** (nothing to scan, or no register to report on or
prioritize). No director gates are invoked.

---

## Static Assertions (Structural)

Verified automatically by `/skill-test static` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] `name: tech-debt` equals the skill directory, the catalog `name` and this spec's basename
- [ ] First body line is `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,code_roots` `` — exactly these two labels
- [ ] `allowed-tools` grants `Bash(bash "*/.claude/skills/tech-debt/../../hooks/yaml-helper.sh" resolve_config *)` with this skill's own directory name
- [ ] The line after the bootstrap block is exactly ``Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] The automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") follows that line verbatim
- [ ] `allowed-tools` is exactly: `Read, Glob, Grep, Write, AskUserQuestion` plus the grant — membership exact, order free; no `Edit`, no `Bash` beyond the grant
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: COMPLETE, BLOCKED, FAIL, NOT ASSESSED
- [ ] Asks before each register write: "May I write these findings to `docs/tech-debt-register.md`?" (scan), "May I append this entry to `docs/tech-debt-register.md`?" (add), "May I write the re-prioritized register back to `docs/tech-debt-register.md`?" (prioritize); report mode writes nothing
- [ ] Output is `docs/tech-debt-register.md` only, in the Debt Register Format (`## Technical Debt Register`, table columns `ID | Category | Description | Files | Effort | Impact | Priority | Added | Sprint`, IDs `TD-NNN`)
- [ ] No `!` injection other than the bootstrap line; no `file:line` citations
- [ ] Has a next-step handoff naming current skills (`/sprint-plan update`, `/sprint-plan new`, `/tech-debt report`, `/security-audit deps`, `/bug-report`)

---

## Director Gate Checks

None. Tech debt tracking is an internal codebase analysis skill; no gates are invoked
and `review_mode` is not among its keys.

---

## Test Cases

### Case 1: Happy Path — scan findings appended to an existing register

**Fixture:**
- The `code_roots` line lists `web=apps/web`, `backend=apps/api` (source `project.yaml`)
- `docs/tech-debt-register.md` exists with `TD-001` and `TD-002`
- `apps/api/src/modules/payments/billing.service.ts` has `// TODO: move retry schedule to config` and `// FIXME: auto-debit retries are not idempotent`; `apps/web/app/goals/page.tsx` has one `// @ts-ignore`; `apps/web/lib/date.ts` imports `moment`, which `docs/architecture/tech-radar.md` lists under `## Hold`

**Input:** `/tech-debt scan`

**Expected behavior:**
1. Scans every listed root, restricted to the extensions the `code_roots` line prints, pruning `node_modules`, `.next`, `dist` and the other build directories
2. Categorizes each finding (e.g. the non-idempotent retry as Code Quality or Security Debt with the reason; `moment` as Dependency Debt citing the radar entry and its ADR)
3. States the denominator — files scanned per root — alongside the findings
4. Asks "May I write these findings to `docs/tech-debt-register.md`?"
5. On approval appends new entries without overwriting `TD-001` and `TD-002`; verdict COMPLETE

**Assertions:**
- [ ] Only the resolved roots are scanned
- [ ] Every finding carries exactly one of the nine categories
- [ ] The files-scanned count is reported with the findings
- [ ] "May I write" prompt appears before any write; existing entries are kept
- [ ] Verdict is COMPLETE

---

### Case 2: Register Doesn't Exist — created on approval, report and prioritize refuse

**Fixture:**
- `docs/tech-debt-register.md` does NOT exist
- The resolved roots contain 4 `TODO`/`FIXME` comments

**Input:** `/tech-debt report` (Run A), `/tech-debt prioritize` (Run A2), then `/tech-debt scan` (Run B)

**Expected behavior:**
1. Run A: reports `NOT ASSESSED — no docs/tech-debt-register.md; run /tech-debt scan first` and stops instead of printing an empty summary
2. Run A2: reports the same `NOT ASSESSED — no docs/tech-debt-register.md; run /tech-debt scan first` line and stops; nothing is scored or written
3. Run B: presents the 4 findings and asks "May I write these findings to `docs/tech-debt-register.md`?"
4. On approval, writes the register in the Debt Register Format starting at `TD-001`; verdict COMPLETE

**Assertions:**
- [ ] Skill does not crash when the register is absent
- [ ] Report and prioritize modes on a missing register yield NOT ASSESSED, never COMPLETE over a zero-item summary or an empty priority list
- [ ] The created register uses the `## Technical Debt Register` header and table columns
- [ ] Verdict is COMPLETE after creation

---

### Case 3: Prioritize — exploitable Security Debt listed first

**Fixture:**
- `docs/tech-debt-register.md` has 6 entries; `TD-004` (Security Debt) records a dependency with a published vulnerability reachable from the sign-in path
- Other entries carry effort S–XL and impact Low–High

**Input:** `/tech-debt prioritize`

**Expected behavior:**
1. Scores each entry by `(impact_if_unfixed × frequency_of_encounter) / fix_effort`
2. Lists `TD-004` first, outside the scoring, and recommends `/bug-report` (usually S1-Critical or S2-Major) and `/security-audit deps`
3. Recommends which entries to include in the next sprint
4. Asks "May I write the re-prioritized register back to `docs/tech-debt-register.md`?"; on approval, verdict COMPLETE

**Assertions:**
- [ ] Priority scores are shown per entry
- [ ] Exploitable Security Debt is routed to a bug, not left as a backlog slot
- [ ] The write happens only after approval

---

### Case 4: NOT ASSESSED — nothing to scan

**Fixture:**
- The bootstrap prints `code_roots: unresolved — NOT CHECKED (set stack.layers.<layer>.root via /setup-stack)` (or the resolved roots hold no source files)
- `docs/tech-debt-register.md` exists with 2 entries

**Input:** `/tech-debt scan`

**Expected behavior:**
1. Counts the source files the scan covered: zero
2. Reports **NOT ASSESSED — no source files to scan.**, with the `NOT CHECKED — no code root resolved (…)` line
3. Stops: writes nothing to the register and emits no COMPLETE verdict

**Assertions:**
- [ ] Verdict is NOT ASSESSED with the reason, not "no debt indicators found"
- [ ] The register is not touched
- [ ] Zero findings over zero files is never presented as a clean codebase

---

### Case 5: Mode Variant — add mode and a missing subcommand

**Fixture:**
- `docs/tech-debt-register.md` exists
- Run A: the user describes "the admin console reads goals straight from the payments schema"
- Run B: no subcommand

**Input:** `/tech-debt add` (Run A), `/tech-debt` (Run B)

**Expected behavior:**
1. Run A: asks in plain text for description, affected files, why the debt was accepted and the impact; then `AskUserQuestion` "Which area does this tech debt belong to?" (`[A] Code …`, `[B] Platform …`, `[C] Operations …`), a second `AskUserQuestion` for the category in that area, and "What is the estimated effort to fix this item?" (S / M / L / XL)
2. Run A: presents the complete entry and asks "May I append this entry to `docs/tech-debt-register.md`?"; verdict COMPLETE
3. Run B: outputs usage and stops; verdict FAIL — missing required subcommand

**Assertions:**
- [ ] The entry records why the debt was accepted
- [ ] The category comes from the two-step question, with the nine categories available
- [ ] Run B writes nothing

---

### Case 6: Gate Compliance — no gate; declined write is BLOCKED

**Fixture:**
- Scan finds 2 new indicators; the register has 3 entries
- `modes.review_mode: full` in `project.yaml`
- The user declines the write

**Input:** `/tech-debt scan`

**Expected behavior:**
1. Scans and presents the findings
2. No director gate is invoked regardless of review mode
3. Asks "May I write these findings to `docs/tech-debt-register.md`?"; the user declines
4. Stops; verdict BLOCKED — user declined write

**Assertions:**
- [ ] No director gate is invoked in any review mode
- [ ] Findings are presented before any write prompt
- [ ] A declined write leaves the register unchanged and yields BLOCKED

---

## Protocol Compliance

- [ ] Reads the register and scans the resolved code roots before compiling (scan mode)
- [ ] Always asks "May I write" before updating the register; appends, never overwrites existing entries
- [ ] Missing tech radar is announced (`NOT CHECKED — tech radar (no docs/architecture/tech-radar.md; /setup-stack seeds it)`), not treated as radar-clean
- [ ] Writes no evidence, reports or plans under `production/session-logs/`
- [ ] Never writes `modes.review_mode` or any other knob that `modes.rigor` fronts
- [ ] No director gates are invoked
- [ ] Verdict is COMPLETE, BLOCKED, FAIL or NOT ASSESSED
- [ ] analysis AN1 — scan uses Read, Glob and Grep only; nothing is written before the approval
- [ ] analysis AN2 — findings and the register are tables with category, effort, impact and priority
- [ ] analysis AN3 — every register write is gated behind "May I write"
- [ ] analysis AN4 — no director gates
- [ ] Observation vs verdict: the files-scanned denominator is stated with the findings; zero files scanned yields NOT ASSESSED

---

## Coverage Notes

- Classification of an untagged `TODO` (which of the nine categories) is a judgement
  the spec does not pin; it checks only that every entry gets exactly one.
- The register is not a verdict-bearing report, so rule-12 (the report verdict line)
  does not apply; report mode prints its summary in the conversation.
- Deprecated stack API detection depends on
  `docs/stack-reference/<component>/deprecated-apis.md` existing for the pinned
  components; no fixture here provides one.
