# Skill Spec: /security-audit

> **Category**: analysis
> **Priority**: low
> **Spec written**: 2026-09-28

## Skill Summary

`/security-audit` is the product's single security and privacy skill, owned by
`security-engineer`. **Audit modes** (`full`, the default; `quick`; and the targeted
`privacy`, `api`, `mobile`, `deps`) review code, configuration, dependencies and
privacy practice against the OWASP Top 10, the OWASP API Security Top 10, OWASP MASVS
(with an `ios` or `android` surface), secrets and security headers, dependency CVEs /
SBOM / licenses, IaC and CI/CD, logging, personal-data handling (PII inventory,
consent including marketing-message consent, retention, erasure, cross-border
transfer) and the checklist of each region in `compliance.regions`
(`.claude/docs/compliance/<region>.md`). Every category starts from a derived inventory
and reports `checked <N> <unit>, <M> findings` or `NOT ASSESSED — <reason>`. Findings
are rated `Critical | High | Medium | Low`; the report
`production/security/security-audit-<mode>-YYYY-MM-DD.md` carries the verdict line
`PASS | CONCERNS | FAIL | NOT ASSESSED` (precedence FAIL > CONCERNS > NOT ASSESSED >
PASS). `quick` = secrets + dependency CVEs + security headers only. **`threat-model`
mode** writes only `docs/security/threat-model.md` (STRIDE per trust boundary, from
`.claude/docs/templates/threat-model.md`) — no audit report, so it never satisfies the
Hardening `security-audit` step, which needs a `full` or `quick` report. Reading
secrets or personal-data samples is the `secrets_access` / `pii_data_access`
always-ask category. The skill never scans or probes production, never auto-fixes,
and spawns no director gate.

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`); `name: security-audit` equals the skill directory, the catalog `name` and this spec's basename
- [ ] `argument-hint` is exactly `"[full | quick | threat-model | privacy | api | mobile | deps]"`
- [ ] Bootstrap: the first body line is `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,automation_always_ask,surfaces,stack,compliance,code_roots` `` — exactly these six labels
- [ ] `allowed-tools` grants `Bash(bash "*/.claude/skills/security-audit/../../hooks/yaml-helper.sh" resolve_config *)` with this skill's own directory name
- [ ] The line after the bootstrap block is exactly ``Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.`` (plain variant)
- [ ] The automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") follows that line verbatim
- [ ] `allowed-tools` is exactly: `Read, Glob, Grep, Write, Bash, Agent, AskUserQuestion` plus the grant — membership exact, order free; no `Edit`, no MCP tool names
- [ ] `model: sonnet`; no `disable-model-invocation` and no `isolation` flag
- [ ] 2+ phase headings found
- [ ] Verdict keywords present exactly: `PASS`, `CONCERNS`, `FAIL`, `NOT ASSESSED`, with precedence **FAIL > CONCERNS > NOT ASSESSED > PASS**; severities `Critical`, `High`, `Medium`, `Low`; finding statuses `Open`, `Accepted Risk`, `Out of Scope`, `Resolved`; no verdict family other than these four tokens
- [ ] "May I write this to `production/security/security-audit-<mode>-YYYY-MM-DD.md`?" before an audit report, and "May I write this to `docs/security/threat-model.md`?" before the threat model
- [ ] Outputs at exactly those paths; audit modes `full`, `quick`, `privacy`, `api`, `mobile`, `deps` each name their file; the audit template has `> **Verdict**: <TOKEN>` directly under its H1 and one blank line; the threat model has no verdict line
- [ ] The threat model is drafted with the template headings `## Scope & Assets`, `## Trust Boundaries`, `## Data Flow`, `## Threats (STRIDE)`, `## Mitigations`, `## Data Classification Summary`, `## Residual Risks`, `## Review`
- [ ] The skill names `secrets_access` and `pii_data_access` (always-ask) and `external_calls` for online advisory databases, and requests `automation_always_ask` in its keys
- [ ] The closing text for a clean `full` or `quick` run contains "Include this path when running `/gate-check launch`."
- [ ] No `!` injection other than the bootstrap line; no `file:line` citations of other files
- [ ] Next steps close with `AskUserQuestion` naming current skills only (`/bug-report`, `/dev-story`, `/hotfix`, `/security-audit`, `/setup-stack`, `/data-model`, `/api-design`, `/launch-checklist`, `/release-checklist`, `/gate-check launch`, `/tech-debt`, `/architecture-decision`, `/gate-check validation`)

---

## Director Gate Checks

**N/A.** `/security-audit` spawns no director gate, and `review_mode` is not among its
keys. It spawns `security-engineer` (three parallel instances for `full`, one per
group; one for every other mode) as the auditor; the instances return findings and
coverage lines, and the verdict is computed by the skill from the verdict table
(analysis AN4). Risk acceptance of a Critical or High finding is asked of the user and
the technical-director role via `AskUserQuestion` — it is a recorded decision, not a
gate.

---

## Test Cases

### Case 1: Happy Path — `full` audit of Moa with no blocking findings

**Fixture** (assumed project state):
- `platform.surfaces: [web, ios, android, api]`; `compliance.regions: [kr]`; `privacy.handles_pii: true`
- Code roots `apps/web`, `apps/mobile`, `apps/api`, `services/worker`, `infra`; lockfiles committed; `docs/api/openapi.yaml`, `docs/data/data-model.md` (`## Data Classification`), `docs/architecture/architecture.md`, `docs/security/threat-model.md` exist
- `gitleaks`, `pnpm audit` and `osv-scanner` are installed; the user supplies a staging URL for the header check
- Every operation scopes objects by session identity; webhooks are authenticated and idempotent; only two Low findings exist

**Input**: `/security-audit full`

**Expected behavior**:
1. Announces the plan (mode, categories in and out of scope with reasons, surfaces, stack, code roots, regions, previous report, agents)
2. Presents the Phase 1 inventory with counts before any scan; asks once with `AskUserQuestion` for the scanner run list, naming which commands contact an external service
3. Spawns three `security-engineer` instances in parallel (groups A, B, C) and merges their findings
4. Lists every item of the six `kr` checklist sections with a status; scored items `Met` or `N/A`
5. Verdict `PASS`; asks "May I write this to `production/security/security-audit-full-YYYY-MM-DD.md`?"; closes with "No blocking security findings. Report written to `production/security/`. Include this path when running `/gate-check launch`."

**Assertions**:
- [ ] Every category's coverage line has a denominator (`checked <N> <unit>, <M> findings`) or `N/A — <condition> not configured`
- [ ] The report header names the commit, the standards with their source (or `NOT SOURCEABLE — edition not confirmed`) and each tool with its version or `NOT CHECKED — <reason>`
- [ ] The verdict line reads `> **Verdict**: PASS`; open Low findings are still listed
- [ ] No secret value or real personal-data record appears in the conversation or the report

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure — BOLA and an unauthenticated payment webhook

**Fixture**:
- As Case 1, but `GET /v1/goals/{goalId}` loads a goal by ID without scoping it to the caller
- The Toss Payments auto-debit webhook handler in `apps/api` accepts callbacks without an authenticity check or replay protection
- A previous report `production/security/security-audit-full-2026-08-30.md` exists with findings `SEC-001` … `SEC-004`

**Input**: `/security-audit full`

**Expected behavior**:
1. Rates the BOLA finding Critical (the Severity table's own example: another user's goal and deposits are reachable) and the webhook finding High by the Severity table ("missing webhook authenticity checks"), raised one level to Critical because the flaw exposes money movement and is reachable without authentication — each raised finding says why
2. Carries earlier findings forward by `SEC-NNN` ID (Resolved / Open / Accepted Risk) and numbers new ones after the highest existing ID
3. Offers risk acceptance only through `AskUserQuestion` naming the technical-director role and the user, with reason and review date; never accepts on anyone's behalf
4. Verdict `FAIL`; after writing, offers `/bug-report` per open Critical/High finding (`S1-Critical` for a personal-data or money breach); closes with "Critical security findings must be resolved before any public release. …"

**Assertions**:
- [ ] Verdict is `FAIL` with each finding's severity, status, reference (e.g. `API1:2023`, `CWE-639`), location, redacted evidence, impact, remediation and verification
- [ ] The re-audit keeps `SEC-001` … `SEC-004` IDs
- [ ] The skill proposes the fix (`/dev-story`, or `/hotfix` when live) and changes no code, configuration or lockfile
- [ ] No exploit payload is sent to production or a third-party system

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: NOT ASSESSED — stack unset, no code roots, no data model

**Fixture**:
- `project.yaml` after `/start` only: the bootstrap prints `stack: unset — run /setup-stack` and `code_roots: unresolved — NOT CHECKED (set stack.layers.<layer>.root via /setup-stack)`
- No `docs/data/data-model.md`, no API contract, no lockfile
- `compliance.regions: [kr]`, `privacy.handles_pii: true`

**Input**: `/security-audit full`

**Expected behavior**:
1. Prints the unresolved code roots line; code-dependent categories become `NOT ASSESSED`; stack-specific checks are `NOT CHECKED — stack not configured (run /setup-stack)`
2. The PII inventory is `NOT ASSESSED — data model missing (run /data-model)`; the dependency category has no lockfile to check
3. With no finding, the verdict is `NOT ASSESSED`; `## Not Assessed` names each category and item with what closes it
4. The closing widget offers `/setup-stack`, `/data-model`, `/api-design`, re-running with scanners installed, or stopping

**Assertions**:
- [ ] Verdict is `NOT ASSESSED`, never `PASS` from zero hits over zero files
- [ ] Every missing input is named with the skill that produces it
- [ ] Unset stack is treated as unknown, not empty — PASS is unreachable for the run

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Mode Variant — `quick` before a release, and a targeted `api` run

**Fixture**:
- The Case 1 project at `modes.workflow: minimal`
- Run B: the API contract changed yesterday

**Input**: `/security-audit quick` (Run A), `/security-audit api` (Run B)

**Expected behavior**:
1. Run A: covers only 1 Secrets, 2 Dependency CVEs and 3 Transport & security headers; `## Regional Compliance` reads `N/A — not covered by quick mode`; writes `production/security/security-audit-quick-YYYY-MM-DD.md`
2. Run B: covers categories 3–8 for the operation inventory; writes `production/security/security-audit-api-YYYY-MM-DD.md` and says "This targeted report does not satisfy the Hardening `security-audit` step — run `/security-audit full` (or `quick` at `minimal` workflow) for that."

**Assertions**:
- [ ] Run A stops the dependency category after CVEs (no SBOM or license review)
- [ ] Each run writes only its own mode's file
- [ ] Run B checks every operation of the contract (coverage `checked <N>/<M> operations`), not a grep sample

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Mode Variant — `threat-model` in the Architecture phase

**Fixture**:
- `docs/architecture/architecture.md`, `docs/data/data-model.md` and `docs/api/openapi.yaml` exist; no `docs/security/threat-model.md` yet
- `compliance.regions: [kr]`

**Input**: `/security-audit threat-model`

**Expected behavior**:
1. Reads the inputs by section and names any that are missing
2. Spawns `security-engineer` with the input paths, the `stack`, `platform.surfaces` and `compliance` lines, the `kr` compliance path and the template path
3. Runs the derivation checks: every trust boundary in the threat table; each STRIDE letter a row or "not applicable because …"; every client-boundary operation covered; every PII field quoted in `## Data Classification Summary`
4. Reviews section by section, then asks "May I write this to `docs/security/threat-model.md`?"

**Assertions**:
- [ ] Only `docs/security/threat-model.md` is written — no audit report and no verdict line
- [ ] The drafted headings match the template's eight `##` headings in order
- [ ] Residual risks name an acceptor (the technical-director role and the user) with date and review trigger
- [ ] The closing widget offers `/architecture-decision`, `/api-design`, `/data-model`, `/gate-check validation` or stopping

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Edge Case — unset regions, unset PII flag, missing scanner, secrets boundary

**Fixture**:
- `compliance.regions` and `privacy.handles_pii` unset (the bootstrap prints `compliance: regions=(unset -- ask) handles_pii=(unset -- ask)`)
- `gitleaks` and `trufflehog` are not installed; `apps/web/.env.production` is tracked by git
- `automation_always_ask` contains the default list (including `secrets_access` and `pii_data_access`); `modes.automation: autonomous`
- Run B: `platform.surfaces: [web, api]` and the argument `mobile`

**Input**: `/security-audit full` (Run A), `/security-audit mobile` (Run B)

**Expected behavior**:
1. Run A: asks which regions the product serves and whether it handles personal data — unset is not `[]` and not `false`; if unanswered, the regional section is `NOT ASSESSED — compliance.regions unset`
2. Records `NOT CHECKED — gitleaks: missing` (and trufflehog), falls back to the manual secrets method, and offers the install command for the user to run — never installs silently
3. Reports the tracked `.env.production` by existence only; reading its content would be `secrets_access`, which prompts even in autonomous mode
4. Run B: reports `N/A — no mobile surface configured`, writes nothing, ends with `Verdict: NOT ASSESSED — mobile mode has nothing to audit`, and offers another mode

**Assertions**:
- [ ] A missing scanner is never treated as a clean result
- [ ] The `.env` content is never read or printed
- [ ] Run B writes no report and its verdict is NOT ASSESSED, never PASS
- [ ] Deadlines, fines or thresholds in regional items appear only with `(Source: <url>, retrieved YYYY-MM-DD)`, else `NOT SOURCEABLE — confirm with counsel`

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Uses "May I write this to `<path>`?" before every write (audit report or threat model) and "May I run this?" before any command that contacts an external service or targets a running environment
- [ ] Presents the summary (verdict, severity counts, coverage lines, Critical and High findings) before requesting approval
- [ ] Ends with the `AskUserQuestion` next-step widget offering only what applies
- [ ] Does not auto-create files without user approval; never commits
- [ ] Writes no evidence, reports or plans under `production/session-logs/` (gitignored)
- [ ] Never writes `modes.review_mode` or any other knob that `modes.rigor` fronts
- [ ] analysis AN1 — scanning uses Read, Glob, Grep and read-only scanner runs (no `fix` variants, no IaC apply, no active checks against production)
- [ ] analysis AN2 — findings are structured entries with severity and status, plus summary tables per severity and per category
- [ ] analysis AN3 — the report or threat model is written only after "May I write"; remediation is proposed for `/dev-story`, `/hotfix` or a human
- [ ] analysis AN4 — no director gate; `security-engineer` instances return findings and coverage lines
- [ ] Observation vs verdict: every category result states its denominator or `NOT ASSESSED — <reason>`; framework-specific patterns come from `docs/stack-reference/` or are marked `NOT SOURCEABLE — run /setup-stack refresh`, which makes PASS unreachable; the verdict follows the verdict table only

---

## Coverage Notes

- This is not a penetration test; the spec checks that the report recommends an
  independent test when money movement, health data or enterprise SSO is in scope,
  not the quality of the findings themselves.
- Scanner flags differ between versions; the spec checks that the skill reads the
  installed tool's `--help` rather than any particular flag.
- `privacy` and `deps` modes are not exercised by their own fixture; they reuse the
  category definitions covered by Cases 1, 2 and 4.
