---
name: security-audit
description: "Security & privacy audit (OWASP Top 10, API Top 10, MASVS, secrets, headers, deps/SBOM, IaC, PII, regional checklists) and threat modeling."
argument-hint: "[full | quick | threat-model | privacy | api | mobile | deps]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/security-audit/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,automation_always_ask,surfaces,stack,compliance,code_roots`

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

# Security Audit

Every shipped service handles something worth stealing or abusing: accounts, personal data, money, admin power,
or simply the availability of the journeys users depend on. This skill does two jobs with one security owner, the
`security-engineer`:

1. **Threat modeling** (`threat-model` mode, Architecture phase) — STRIDE per trust boundary, built from the
   architecture, the data model and the API contract, written to `docs/security/threat-model.md`.
2. **Audits** (every other mode, from Build onward) — a systematic review of the code, configuration, dependencies
   and privacy practices against OWASP Top 10, the OWASP API Security Top 10, OWASP MASVS, secrets and security
   headers, supply chain (dependency CVEs, SBOM, licenses), infrastructure-as-code, personal-data handling and the
   regional checklists of the configured regions — written as a prioritised, verdict-bearing report.

**Where it sits in the workflow**

- **Architecture** — the catalog step `threat-model` runs `/security-audit threat-model`. The Validation gate
  requires `docs/security/threat-model.md` when the product handles personal data (`privacy.handles_pii: true`)
  at `standard` and `full`, recommends it there without personal data, and drops it at `minimal`.
- **Hardening** — the catalog step `security-audit` needs a `full` or `quick` report. The Launch gate requires a
  `full` audit with no open Critical or High findings at `standard` and `full`, and a `quick` (or `full`) audit
  with no open Critical findings at `minimal`.
- **Any time** — `api` after an API contract change, `deps` after dependency upgrades or a published advisory,
  `privacy` when a PRD adds personal data or a new processor, `mobile` before a store submission, `quick` before
  every release, and any mode after a security incident or a security bug report.

This is not a penetration test. It covers the common, checkable failure classes of web, mobile and API services;
a regulated or high-value launch (money movement, health data, enterprise SSO) should add an independent
penetration test by a human specialist, and the report says so when that applies.

### Modes

| Mode | Covers (categories in Phase 4) | Writes |
|---|---|---|
| `full` (default) | 1–13 as applicable + the regional checklists (Phase 5) | `production/security/security-audit-full-YYYY-MM-DD.md` |
| `quick` | 1 Secrets · 2 Dependency CVEs only · 3 Transport & security headers | `production/security/security-audit-quick-YYYY-MM-DD.md` |
| `privacy` | 12 Privacy & personal data · the personal-data part of 11 · the `## Privacy & Data Protection` and `## Marketing Messages & Consent` sections of each regional checklist | `production/security/security-audit-privacy-YYYY-MM-DD.md` |
| `api` | 3 (API headers, CORS) · 4 · 5 · 6 · 7 · 8 | `production/security/security-audit-api-YYYY-MM-DD.md` |
| `mobile` | 9 MASVS · the mobile parts of 1 (secrets in the app bundle) and 4 (token storage) | `production/security/security-audit-mobile-YYYY-MM-DD.md` |
| `deps` | 2 in full: CVEs, SBOM, licenses, lockfiles, tech-radar Hold and Forbidden entries, CI action pinning | `production/security/security-audit-deps-YYYY-MM-DD.md` |
| `threat-model` | Phase 9 only — no audit categories | `docs/security/threat-model.md` **only** |

`threat-model` writes no audit report, so it never satisfies the Hardening `security-audit` step; `privacy`, `api`,
`mobile` and `deps` reports are targeted audits and do not satisfy it either — only `full` or `quick` does.

### Verdicts (audit modes)

| Verdict | When |
|---|---|
| `FAIL` | At least one `Open` finding rated Critical or High. |
| `CONCERNS` | No `FAIL` condition, and at least one of: an `Open` Medium finding; a Critical or High finding in `Accepted Risk`; a scored regional checklist item that is `Gap`. |
| `NOT ASSESSED` | No `FAIL` or `CONCERNS` condition, but part of the required scope could not be assessed: a category with no code to audit, no code root resolved, a required input missing, neither a scanner nor a manual method available, a pattern set marked `NOT SOURCEABLE`, or a scored regional item `NOT ASSESSED` (Phase 5). |
| `PASS` | Every required category assessed with sourced methods; no open Critical, High or Medium finding; no accepted Critical or High; every scored regional item `Met`, `Accepted` or `N/A`. Open Low findings may remain and are listed. |

Precedence: **FAIL > CONCERNS > NOT ASSESSED > PASS**. `NOT ASSESSED` outranks `PASS` — a scope nobody could look
at is not a clean scope — but never a known problem, which is more actionable than an unknown. Whatever the verdict,
the Summary and `## Not Assessed` name every category and item that was not assessed, so a `CONCERNS` report never
hides a blind spot. The report carries its verdict directly under the H1: `> **Verdict**: <TOKEN>`. `PASS` is never
reachable by having nothing to look at: a scan with zero hits counts only when its denominator (files, operations,
packages, fields checked) is printed next to it.

### Severity

| Level | Definition (service examples) |
|---|---|
| **Critical** | Exploitable now, at scale, with no or ordinary user privileges: another user's personal data or money is reachable (BOLA on `GET /v1/goals/{goalId}`), account takeover, remote code execution, SQL injection, a production secret in the repository or in a client bundle, a client-supplied amount trusted for a charge, an unauthenticated admin function. |
| **High** | Exploitable with a precondition (a specific role, a victim action, an internal position): privilege escalation, stored XSS in an authenticated area, missing webhook authenticity checks, a reachable dependency CVE with a known exploit, personal data sent to a third party without a basis, marketing messages sent without the consent the configured region requires. |
| **Medium** | A plausible weakness with limited impact or a missing defence layer: no rate limit on sign-in or OTP endpoints, missing CSP or HSTS, verbose errors with stack traces, overly broad CORS without credentials, an unreachable dependency CVE, retention not enforced. |
| **Low** | Hardening with no direct exploit path: missing `Permissions-Policy`, outdated but unaffected libraries, informational header leaks. |

Finding status: `Open` · `Accepted Risk` (a named owner — the technical-director role together with the user —
accepted it, with the date, the reason and a review date) · `Out of Scope` (with the reason) · `Resolved` (fixed
since the previous report of this mode, verified by the evidence named). A finding that is a personal-data or money
breach is `S1-Critical` when filed with `/bug-report`.

### What this skill never does

- Print, copy or store a secret value, token or real personal-data record — in the conversation, the report or a
  fixture. Scanners run with redaction; findings cite file, line or operation plus a redacted excerpt.
- Read `.env` files, secret stores, production logs or database rows. Reading, creating or rotating secrets is the
  `secrets_access` always-ask category, and querying or exporting personal data or reading log samples that contain
  it is `pii_data_access` (`.claude/docs/automation-modes.md` § `automation_always_ask` Categories) — both prompt in
  every mode unless the user removed them, and even then this skill reports on their presence, never their content.
- Scan, fuzz, brute-force or send exploit payloads to production or to any third-party system. Active checks run
  only against a local or staging target the user names, and only after "May I run this?".
- Change code, configuration, lockfiles or infrastructure: no `npm audit fix`, no auto-remediation, no IaC apply.
  Fixes are proposed and implemented through `/dev-story` or `/hotfix`.
- Install scanners without asking, or treat a missing scanner as a clean result.
- State a legal deadline, fine or threshold without `(Source: <url>, retrieved YYYY-MM-DD)`, or give legal advice.

---

## Phase 0: Parse Arguments and Resolve Scope

**0a. Mode.** The first argument is one of `full`, `quick`, `threat-model`, `privacy`, `api`, `mobile`, `deps`. No
argument ⇒ `full`, announced as: "Running a full audit. For the Architecture-phase threat model run
`/security-audit threat-model`." An unknown argument ⇒ show the mode table and ask.

**0b. Surfaces.** Read the `platform.surfaces` line.
- Listed surfaces decide the conditional categories: `web` ⇒ browser headers, CSP and cookies; `ios` / `android` ⇒
  MASVS; `api` ⇒ an externally consumed (public or partner) API, which adds API key management, developer-facing
  rate limits and inventory to category 7. The API Security Top 10 applies to the product's own client-facing API
  too — `api` mode never needs the `api` surface, only a backend (0c).
- `(unset -- ask which surfaces ship)` ⇒ ask. Unset is not "none": if the question cannot be asked, every
  surface-conditional category stays in scope and is `NOT ASSESSED` where its inputs are missing.
- `mobile` mode on a project whose surfaces are known and include neither `ios` nor `android` ⇒ say
  `N/A — no mobile surface configured`, write nothing, end with
  `Verdict: NOT ASSESSED — mobile mode has nothing to audit`, and offer another mode.

**0c. Stack.** Read the `stack` line. The backend and data components decide which framework-specific checks apply
(query building, ORM raw-query APIs, authorization middleware); the web and mobile frameworks decide the client
checks. For framework- and version-specific security APIs the security-engineer reads
`docs/stack-reference/<component>/` first; when the reference does not cover a pattern, the check is written
`NOT SOURCEABLE — run /setup-stack refresh` rather than filled from memory (Phase 4, "Pattern lists"). A line reading
`stack: unset — run /setup-stack` is unknown, not empty: continue with the language-level checks only and name the
stack-specific checks `NOT CHECKED — stack not configured (run /setup-stack)`; `PASS` is then unreachable for the
run.

**0d. Code roots.** Read the `code_roots` line — every directory it names (declared, `workspace` and `detected`
roots; never `missing` ones) is in scope. Undeclared roots are scanned too and announced with
`WARN: undeclared code roots: <dirs> — declare them with /setup-stack`. A line reading `code_roots: unresolved` ⇒
print `NOT CHECKED — no code root resolved (set stack.layers.<layer>.root via /setup-stack)`; code-dependent
categories become `NOT ASSESSED` and only configuration, contract and dependency checks that do not need a code
root continue. `threat-model` mode does not need code roots.

Read from `project.yaml` with Read (no config label): `stack.package_manager` (selects the dependency tool in
Phase 2), `stack.monorepo`, and `commands.run` / `commands.dev` (only to tell the user how to start a local target
for the header check — the skill does not start servers without asking).

**0e. Compliance.** Read the `compliance` line.
- `handles_pii=true` ⇒ category 12 is required in `full`; `handles_pii=false` ⇒ category 12 still runs as a
  *PII-absence check* (sign-in emails, phone numbers, device identifiers and IP addresses in logs are personal
  data — a contradiction becomes a finding recommending `/settings privacy.handles_pii=true`); `(unset -- ask)` ⇒
  ask. Unset is not `false`.
- `regions=<list>` ⇒ Phase 5 loads `.claude/docs/compliance/<region>.md` for **each listed region and no other**.
  `regions=none` ⇒ skip Phase 5 and write `Regional checklists: none — compliance.regions is [] (explicitly
  none)`. `(unset -- ask)` ⇒ ask which regions the product serves; if it cannot be asked, write
  `NOT ASSESSED — compliance.regions unset` for the regional section.

**0f. Automation.** Read the `automation_always_ask` line. `secrets_access` and `pii_data_access` govern the
boundaries above. Scanner runs that query online advisory databases or download rule packs are `external_calls`
(prompts when that category is in the list). Nothing in this skill deploys, migrates or changes infrastructure.

**0g. Previous reports.** Glob `production/security/security-audit-<mode>-*.md` (and `-full-*` for any mode) and
note the newest. A re-audit carries each earlier finding forward by its `SEC-NNN` ID and marks it `Resolved`,
still `Open`, or `Accepted Risk`; a same-day report of the same mode is updated in place only after asking.

**0h. Commit under audit.** Run `git rev-parse --short HEAD` and `git status --porcelain` (read-only). The report
names the commit; uncommitted changes are listed as "working tree — uncommitted changes included".

**0i. Announce the plan** in one block: mode, categories in scope and out of scope with reasons, surfaces, stack,
code roots, regions, the previous report, and the agents that will run (Phase 3).

---

## Phase 1: Coverage Inventory — Establish the Denominators

A security scan searches for something bad, so a zero-hit result is ambiguous by construction: it means either
"searched and found none" or "there was nothing to search". **Every category therefore starts from a derived
inventory, and every result line reads `checked <N> <unit>, <M> findings` or `NOT ASSESSED — <reason>`.** Never a
bare tick. Derive; do not enumerate from memory (obligation 5):

| Inventory | Derived from | Used by |
|---|---|---|
| API operations | the contract under `docs/api/` (`openapi*.yaml` paths × methods, GraphQL operations, proto service methods, AsyncAPI channels); no contract ⇒ route declarations found in the backend roots, marked "derived from code — contract absent" | 4, 5, 6, 7, 8 |
| Entities and fields with their classification | `docs/data/data-model.md` `## Data Classification`; absent ⇒ ORM schema files in the backend roots, marked "unclassified" | 12, 11, 5 |
| Source files | every in-scope code root, pruning build and dependency directories | 1, 6, 11, 13 |
| Dependency manifests and lockfiles | every root with `package.json`, `pyproject.toml`, `requirements*.txt`, `build.gradle(.kts)`, `pom.xml`, `go.mod`, `pubspec.yaml`, `Podfile.lock`, `Cargo.toml` | 2 |
| Infrastructure and pipeline files | the cloud root, `**/*.tf`, `**/k8s/**`, `**/helm/**`, `**/Dockerfile*`, `.github/workflows/*.yml` | 10 |
| Mobile configuration | `Info.plist`, `PrivacyInfo.xcprivacy`, entitlements, `AndroidManifest.xml`, network-security config, `app.json` / `app.config.*` (Expo), Flutter platform folders | 9 |
| Third-party processors and SDKs | dependency list + `docs/architecture/architecture.md` integrations + `docs/registry/architecture.yaml` `interfaces` | 12, 7 (unsafe consumption) |
| Threat model | `docs/security/threat-model.md` (threats `Open`, mitigations `Missing`) | all — each open threat becomes a check |

Present the inventory with its counts before any scan. **Insufficient implementation**: when a mode's categories
have nothing to check (no source files and no contract for `api`; no lockfile for `deps`; no mobile code for
`mobile`), the verdict is `NOT ASSESSED`; name what is missing and the skill that produces it (`/dev-story`,
`/api-design`, `/test-setup`). A zero-finding scan over three files is not a clean bill of health.

---

## Phase 2: Scanner Preflight and Runs

**2a. Preflight** (read-only): `command -v` for each candidate tool below and `<tool> --version` for those found.
Tool flags differ between versions — read the installed tool's `--help` before composing a command; never run a
flag recalled from memory.

| Purpose | Candidate tools (one available tool per purpose is enough; more may run) | Requirement |
|---|---|---|
| Secrets in the working tree and git history | `gitleaks`, `trufflehog` | redaction on; report file, line, rule and commit — never the value |
| Dependency CVEs | the package manager's audit (`pnpm audit`, `npm audit`, `yarn npm audit`), `pip-audit`, `osv-scanner` (any ecosystem with a lockfile), `govulncheck`, the Gradle or Maven dependency-check plugin when the build already configures it | JSON output; report only, never the `fix` variants |
| SBOM and licenses | `syft`, `cdxgen`, or the package manager's own SBOM command | CycloneDX or SPDX to stdout; summarised in the report, not committed |
| Static analysis | `semgrep` with a rule pack the user approves | local run; rule download is an external call |
| IaC and containers | `checkov`, `trivy config`, `hadolint` | misconfiguration only; no cloud credentials used |
| GitHub Actions | `zizmor`, `actionlint` | workflow files only |
| Security headers | `curl -sS -I <url>` | a local or staging URL the user supplies — never production |

**2b. Ask once for the run list** with `AskUserQuestion`: every command, what it reads, whether it contacts an
external service (npm registry, OSV, PyPI, rule registries, vulnerability-database downloads), and its expected
runtime. Options: `Run all` / `Run only the offline tools` / `Choose per tool` / `Skip scanners — manual review only`.
A missing tool is offered as an install command for the **user** to run (installing software changes their machine);
it is never installed silently.

**2c. Run** the approved commands with Bash, from the repository root or the relevant code root, with a timeout.
Keep raw output in the conversation only in summarised, redacted form (counts per rule or severity, file and line
references). A tool that is missing, fails or times out is recorded as
`NOT CHECKED — <tool>: <missing | failed: reason | timed out>`, and its category falls back to the manual method of
Phase 4; when no manual method exists for that check, the category is `NOT ASSESSED`.

---

## Phase 3: Spawn the Security Engineer

Spawn `security-engineer` via `Agent`. For `full`, spawn **three instances in parallel**, one per group, and merge
their findings; for every other audit mode, spawn one instance with the mode's categories.

| Group (`full`) | Categories |
|---|---|
| A — Identity, access and API | 4 Authentication · 5 Authorization · 6 Input & injection · 7 API surface · 8 Business-flow abuse & payments |
| B — Platform and supply chain | 1 Secrets · 2 Dependencies · 3 Transport & headers · 10 IaC & CI/CD · 11 Logging & errors |
| C — Data, clients and regions | 9 Mobile · 12 Privacy · 13 Model-backed features · Phase 5 regional checklists |

Pass to each instance:
- the mode, its categories, and the category definitions of Phase 4 that apply;
- the resolved `platform.surfaces`, `stack`, `code_roots` and `compliance` lines exactly as printed;
- the Phase 1 inventory (operations, fields, files, manifests, processors) with counts;
- the redacted scanner summaries of Phase 2 and the list of `NOT CHECKED` tools;
- paths: `docs/architecture/architecture.md`, the API contract under `docs/api/`, `docs/data/data-model.md`,
  `docs/security/threat-model.md`, `docs/architecture/tech-radar.md`, ADRs whose Domain is `Auth`, `Security` or
  `Data`, `docs/ops/slo.md` — each marked "none" when absent;
- for group C (and `privacy` mode): the compliance file paths selected in 0e;
- the previous report path (or "none") so findings keep their `SEC-NNN` IDs;
- the instruction: "Return findings in the format of Phase 7 — severity, status, reference, location, redacted
  evidence, impact, remediation, verification and effort — and one coverage line per category
  (`checked <N> <unit>, <M> findings` or `NOT ASSESSED — <reason>`). Do not print secret values or personal data.
  Do not run commands against production or third-party systems. Framework-specific patterns come from
  `docs/stack-reference/`; otherwise write `NOT SOURCEABLE — run /setup-stack refresh`."

Collect every instance's result before Phase 6. If an instance fails or returns without coverage lines, its
categories are `NOT ASSESSED — agent run incomplete`; offer to re-run that group.

---

## Phase 4: Audit Categories

Each category lists what to verify, how, and the references a finding cites. Standards are named by the edition the
report header records (Phase 7): the OWASP API Security Top 10 2023 (`API1`–`API10`), OWASP MASVS v2 (`MASVS-*`),
CWE IDs, and the OWASP Top 10 edition the project confirms. When an edition cannot be confirmed, the header says
`NOT SOURCEABLE — edition not confirmed` and findings cite the category name and CWE instead of an edition number
(an unconfirmed edition affects citations only, not the verdict).

**Pattern lists.** The grep patterns below are language-level starting points, not a complete set, and a hit is a
place to review, not a finding. Framework-specific sinks (ORM raw-query APIs, template escaping switches, security
middleware options) come from `docs/stack-reference/<component>/` for the pinned version; an API name recalled from
memory can be wrong for the pinned version, and a grep for a name that does not exist returns zero hits that read as
a pass. When the reference does not cover them, the category's coverage line says
`NOT SOURCEABLE — <component> security APIs not covered by docs/stack-reference/<component>/`: the manual review of
the inventory still runs, but `PASS` is unreachable for the run until the reference is extended with
`/setup-stack refresh`. Coverage of access control and input handling comes from the **operation inventory** —
every operation is reviewed — never from grep alone.

### 1. Secrets and keys
- Secrets in the working tree **and** git history (scanner of Phase 2; fallback: Grep for private-key headers,
  `AKIA[0-9A-Z]{16}`, `password\s*[:=]`, `secret`, `api[_-]?key`, `token` assignments, then review each hit).
- Secrets shipped to clients: anything readable by a browser or an app binary is public — check public-prefixed
  environment variables (`NEXT_PUBLIC_`, `EXPO_PUBLIC_`, `VITE_`), bundled config files, mobile resources and
  `google-services.json` / `GoogleService-Info.plist` restrictions.
- `.env*` files tracked by git (existence only — the content is not read), `.gitignore` coverage, CI secrets
  referenced in workflow logs, secrets in container images or IaC variables.
- Secret management: per-environment secret store, rotation procedure, CI using OIDC federation rather than
  long-lived cloud keys, service identities with least privilege.
- A live-looking production secret found anywhere ⇒ Critical, reported immediately in the conversation (path and
  rule only) with the rotation step for a **human** to perform — the skill never tests whether the key works.
- References: CWE-798, CWE-312; OWASP Top 10 (cryptographic failures / security misconfiguration).

### 2. Dependencies, SBOM and licenses
- Known vulnerabilities per ecosystem (Phase 2 tools); for each Critical or High advisory: is the vulnerable
  function reachable from product code, is a fixed version available, is it a direct or transitive dependency.
  Unreachable ⇒ usually Medium, with the reasoning.
- `quick` stops here. `deps` and `full` continue:
- Lockfiles committed for every manifest; CI installs with the frozen-lockfile mode of `stack.package_manager`.
- SBOM generated (component count, format); licenses reviewed — copyleft in distributed binaries (mobile apps,
  SDKs), AGPL in network services, unknown or missing licenses.
- `docs/architecture/tech-radar.md`: every dependency in `## Hold` or `## Forbidden Patterns` that is still in
  use is a finding; a radar entry without a source or ADR is noted.
- Supply-chain hygiene: GitHub Actions pinned to full commit SHAs, minimal `permissions`, no secrets exposed to
  forked pull requests, `pull_request_target` never checking out untrusted code; install scripts and new
  dependencies checked for typosquatting and maintenance.
- References: OWASP Top 10 (vulnerable components / software supply chain); CWE-1104, CWE-1395.

### 3. Transport and security headers
- TLS everywhere (redirect HTTP to HTTPS), HSTS once HTTPS is stable, no mixed content.
- Browser headers on a local or staging URL (Phase 2) **and** in framework configuration: Content-Security-Policy
  (nonce- or hash-based, `object-src 'none'`, `base-uri`, `frame-ancestors`), `X-Content-Type-Options: nosniff`,
  `Referrer-Policy`, `Permissions-Policy`; cookies `Secure; HttpOnly; SameSite` (prefer the `__Host-` prefix for
  session cookies).
- CORS: explicit origin allow-list, never a wildcard with credentials; CSRF protection for cookie-authenticated
  state changes.
- API responses: no sensitive data in URLs (logged by proxies), `Cache-Control: no-store` on personal data.
- No URL supplied and no header configuration found ⇒ `NOT ASSESSED — no reachable target (start the app with
  commands.run, or give a staging URL)`.
- References: CWE-319, CWE-693, CWE-1021; OWASP Top 10 (security misconfiguration).

### 4. Authentication and sessions
- OAuth/OIDC: Authorization Code with PKCE for SPAs and apps, `state` and `nonce` validated; social login (Kakao,
  Naver, Apple, Google): ID token signature, `iss`, `aud`, `exp`, `nonce` verified where issued, otherwise the
  profile fetched server-side; accounts linked only on a verified identifier.
- Passwords (if any): a memory-hard hash per the OWASP Password Storage Cheat Sheet, breached-password check, no
  length truncation; passkeys where supported; MFA or step-up for admin and money-moving actions.
- Sessions and tokens: short-lived access tokens, rotating refresh tokens with reuse detection, revocation on
  logout and password change; JWT algorithm allow-listed (never `none`); tokens in Keychain / Keystore-backed storage
  on mobile, never in plain preferences or web `localStorage` for long-lived credentials.
- Brute force and enumeration: rate limits on sign-in, sign-up, password reset and OTP endpoints; uniform responses
  that do not reveal whether an account exists; SMS and 알림톡 OTP pumping controls.
- References: API2:2023; OWASP Top 10 (authentication failures); CWE-287, CWE-307, CWE-384, CWE-613.

### 5. Authorization — object, function and property level
For **every** operation in the inventory, record: auth required (yes/no), required scope or role, and the
object-level rule (who may access which object). Then verify in the handler code:
- Object level (API1 BOLA / IDOR): the query is scoped by the session identity or tenant — an ID in the path or
  body is never enough; existence-sensitive objects return 404 rather than 403.
- Function level (API5 BFLA): admin and internal operations sit behind separate roles and routes; the admin console
  has separate authentication with MFA and an audit log of personal-data views.
- Property level (API3 BOPLA): explicit response schemas (no whole-entity serialization) and explicit writable-field
  lists (no mass assignment of `role`, `plan`, `balance`, `tenantId`).
- Multi-tenancy: tenant derived from the session, never from the request; row-level security where the database
  supports it.
- Negative authorization tests exist for sensitive operations (cross-user read and write).
- Coverage line: `checked <N>/<M> operations`. An operation with no auth decision recorded in the contract is
  itself a finding.
- References: API1, API3, API5:2023; OWASP Top 10 (broken access control); CWE-639, CWE-285, CWE-915.

### 6. Input handling, injection and SSRF
- Validation at the boundary against the contract schema; unknown fields rejected on writes; size limits.
- Injection: parameterized queries or safe ORM APIs only; no string-built SQL, shell commands, LDAP or template
  rendering from user input. Language-level review points — TypeScript/JavaScript: `eval(`, `new Function(`,
  `child_process`, `dangerouslySetInnerHTML`, `.innerHTML`, `v-html`; Python: `eval(`, `exec(`, `pickle.loads`,
  `yaml.load(`, `subprocess` with `shell=True`, `os.system(`; Java/Kotlin: `Runtime.getRuntime().exec`,
  `ProcessBuilder`, string-concatenated queries, `ObjectInputStream`. Framework raw-query and escaping APIs: from the
  stack reference (see "Pattern lists").
- Output encoding by context; rich text through an allow-list sanitizer.
- SSRF (API7): server-side fetches of user-supplied URLs (link previews, webhooks, image import) go through an
  egress allow-list; link-local and cloud metadata addresses blocked.
- File upload: type and size limits, content sniffing, private storage with short-lived signed URLs, malware scanning
  where files are shared between users.
- Deserialization and parsers: untrusted data never deserialized into executable types; XML parsers with external
  entities disabled.
- References: API7:2023; OWASP Top 10 (injection); CWE-89, CWE-78, CWE-79, CWE-918, CWE-434, CWE-502.

### 7. API surface
- API4 unrestricted resource consumption: pagination limits, request size, query complexity or depth limits for
  GraphQL, per-client rate limits and quotas, timeouts on expensive operations, cost caps on paid third-party calls
  (SMS, 알림톡, LLM).
- API8 security misconfiguration: debug endpoints, GraphQL introspection and API explorers disabled or protected in
  production, error bodies in problem+json without stack traces, unneeded HTTP methods rejected.
- API9 inventory: every deployed route exists in the contract (routes found in code but not in the contract are
  findings); deprecated versions have a sunset plan; staging and preview hosts are not publicly indexed.
- API10 unsafe consumption: responses from third-party APIs (payment provider, identity providers, messaging vendors)
  are validated and bounded; webhooks from them are authenticated the way each provider documents (signature, or a
  server-side re-query by ID) and handled idempotently with replay protection.
- With the `api` surface (public or partner API): API key issuance, scoping, rotation and revocation; per-key rate
  limits; developer documentation that states auth and rate limits.
- References: API4, API8, API9, API10:2023.

### 8. Abuse of business flows and payments
- API6 sensitive business flows: sign-up, promotion redemption, referral rewards, free-trial creation, goal and
  deposit creation, payouts — abuse limits per account, device and payment method, designed with the
  business-analyst and monetization-strategist (`production/qa/business-rules/` reports are read when present).
- Money: the server computes every amount from its own records; the client never sends a price that is trusted;
  idempotency keys on every charge, refund and payout; payment results confirmed server-side before any balance or
  entitlement changes; reconciliation against the payment provider exists.
- Card data: never handled directly — the provider's hosted fields, widget or SDK keep it out of the product's
  systems; billing keys and payment tokens stored encrypted, server-side only, never logged.
- Entitlements (plans, credits) are checked on the server for every protected operation, not only in the UI.
- References: API6:2023; CWE-840, CWE-841, CWE-472.

### 9. Mobile (MASVS) — only with an `ios` or `android` surface
- MASVS-STORAGE: tokens and personal data only in Keychain / Keystore-backed storage; no sensitive data in logs,
  backups, the clipboard or app-switcher snapshots.
- MASVS-CRYPTO: platform crypto APIs; no hard-coded keys.
- MASVS-AUTH: biometrics unlock a Keychain/Keystore-bound key, not a boolean; server-side session checks.
- MASVS-NETWORK: platform transport security on (no global ATS exceptions, no `usesCleartextTraffic`), certificate
  pinning only with a rotation plan.
- MASVS-PLATFORM: every deep link and intent validated; exported Android components justified; WebViews with no
  sensitive JavaScript bridges; permissions requested in context and justified.
- MASVS-CODE: minimum supported OS and forced-update path for vulnerable versions; debug flags off in release builds;
  third-party SDKs inventoried.
- MASVS-RESILIENCE: root/jailbreak and tamper detection treated as signals, never as the only control.
- MASVS-PRIVACY: the iOS privacy manifest, the App Store privacy details and the Google Play Data safety form match
  what the app and its SDKs actually collect.
- Static review of configuration and source is the default; binary analysis (e.g. MobSF) runs only on a build the
  user provides.
- References: OWASP MASVS v2 and the MASTG test cases.

### 10. Infrastructure as code, CI/CD and cloud configuration — only when the inventory has such files
- Storage buckets and databases not publicly reachable; security groups and firewall rules without open
  administrative ports; encryption at rest; backups enabled; logging on for control-plane actions.
- IAM: no wildcard actions or resources on production roles; separate roles per service; break-glass access audited.
- Containers: non-root users, pinned base images, no secrets in layers, read-only filesystems where possible;
  Kubernetes without privileged pods or host mounts.
- Pipelines: production deploys only from protected branches through the pipeline, environment protection rules,
  OIDC to the cloud, secrets masked, third-party actions pinned (shared with category 2).
- References: OWASP Top 10 (security misconfiguration); CWE-732, CWE-250.

### 11. Logging, error handling and monitoring
- Security events logged with actor and target IDs: sign-in success and failure, MFA and password changes, role
  changes, admin views of personal data, payment-method changes.
- No tokens, passwords, card data, identity numbers or unnecessary personal data in logs, analytics events, crash
  reports or model prompts — redaction happens in the logger, not by convention.
- Errors: generic messages to clients; stack traces and SQL only in server logs.
- Alerts exist for authentication spikes, authorization failures and unusual export volume, wired with the
  sre-engineer (`docs/ops/slo.md` `## Dashboards & Alerts`).
- References: OWASP Top 10 (logging and monitoring failures); CWE-532, CWE-209, CWE-778.

### 12. Privacy and personal data
- **PII inventory**: every field classified `PII` or `Sensitive-PII` in the data model has a purpose, a lawful basis,
  a retention period, a deletion path and a protection (encryption, tokenisation, masking); fields found in code but
  missing from the model are findings. Data model absent ⇒ `NOT ASSESSED — data model missing (run /data-model)`
  for this part.
- **Consent**: versioned consent records (text version, time, channel); required and optional consents separated;
  **marketing-message consent** collected separately from terms, per channel (email, SMS, push, messaging apps),
  with the night-time and periodic-confirmation rules of the configured regions; withdrawal as easy as consent.
- **Rights**: access/export, correction, deletion and in-app account deletion that reach replicas, analytics,
  processors and backups on a documented schedule; consent withdrawal and marketing opt-out honoured everywhere.
- **Retention and erasure**: jobs that enforce the retention periods exist and are tested; legal-hold exceptions
  documented with their source.
- **Processors and cross-border transfer**: every processor and SDK receiving personal data is listed with the data
  sent, the purpose and the processing region; transfers outside the users' region are disclosed and have a basis.
- **Disclosure consistency**: the privacy policy, the App Store privacy details, the Google Play Data safety form and
  the cookie/consent banner all match the inventory.
- Model prompts, analytics and crash reports carry no personal data without a basis; pseudonymous IDs for analytics.
- References: the configured regions' `## Privacy & Data Protection` items (Phase 5); CWE-359.

### 13. Model-backed features — only when LLM or ML features exist (ADR Domain `ML`, `ml-engineer` stories, or model SDKs in the inventory)
- Model output treated as untrusted input; prompt injection from user and retrieved content considered; tool and
  data permissions limited to the feature's need.
- No personal data in prompts or provider logs without a basis; provider data-retention settings recorded.
- Cost and rate limits on model calls (links to API4).
- References: OWASP Top 10 for LLM Applications (edition confirmed at run time).

---

## Phase 5: Regional Compliance Checklists — `full` and `privacy` only

For each region selected in 0e, Read `.claude/docs/compliance/<region>.md`. **List every item** of the sections the
mode uses (derive coverage — never pick a subset): `full` lists all six sections; `privacy` lists
`## Privacy & Data Protection` and `## Marketing Messages & Consent`.

**Scored sections** — the ones that decide this audit's verdict — are `## Privacy & Data Protection`,
`## Security Certification` and `## Marketing Messages & Consent`, plus the payment-security items of
`## Commerce & Payments` (card data, auto-debit authorization, stored value). The remaining items of
`## Commerce & Payments`, `## Accessibility` and `## Integration Notes` are still listed with a status, marked
`not scored — carried to /launch-checklist`, because they need business or legal confirmation rather than a
security review. For each item record one status:

| Status | Meaning |
|---|---|
| `Met` | Evidence found (code, configuration, document or a user confirmation naming who confirmed and when) |
| `Gap` | Checked and not met — a scored item is also raised as a finding with a severity in Phase 6 |
| `Accepted` | Not met, and a named owner accepted it with date and reason |
| `N/A` | Does not apply, with a one-line reason (e.g. "no location data collected") |
| `NOT ASSESSED` | Needs a fact the audit cannot observe (applicability thresholds, contracts, registrations); the question to answer is written next to it |

- Ask the user the applicability questions the checklist raises (e.g. "Are in-app credits stored value?",
  "Is the service in scope of mandatory ISMS?") and record the answer with its source when a number is involved.
- An unscored item that nobody could confirm stays `NOT ASSESSED` with its question and does not change the audit
  verdict; `/launch-checklist` carries it forward and decides it there.
- Never state a deadline, fine or threshold without `(Source: <url>, retrieved YYYY-MM-DD)`; unsourced ⇒
  `NOT SOURCEABLE — confirm with counsel`.

---

## Phase 6: Classify Findings and Decide the Verdict

1. **Merge** the agent results and the Phase 2 scanner summaries; deduplicate (one finding per root cause, listing
   every location); carry forward IDs from the previous report; number new findings `SEC-NNN` after the highest
   existing ID.
2. **Rate** each finding with the Severity table. Raise one level when the flaw exposes money movement or
   `Sensitive-PII`, or when it is reachable without authentication; say why in the finding.
3. **Status**: `Open` by default. For every Critical or High finding the team wants to accept, ask with
   `AskUserQuestion` who accepts (the technical-director role and the user), the reason, and the review date;
   record it — the skill never accepts risk on anyone's behalf.
4. **Coverage**: one line per category of the mode — assessed with its denominator, `N/A — <condition> not
   configured`, or `NOT ASSESSED — <reason>`.
5. **Verdict** by the table and precedence at the top: `FAIL > CONCERNS > NOT ASSESSED > PASS`. List every
   category and regional item that was not assessed — and every `NOT SOURCEABLE` pattern set — under
   `## Not Assessed`, whatever the verdict.
6. **Remediation order**: Critical first, then High ordered by exposure (unauthenticated before authenticated,
   money and `Sensitive-PII` before other data), then quick wins.

---

## Phase 7: Draft the Report

Present the summary (verdict, severity counts, coverage lines, Critical and High findings) in the conversation first.
The full report uses this structure:

```markdown
# Security Audit: [mode] — [Product Name]

> **Verdict**: [PASS | CONCERNS | FAIL | NOT ASSESSED]

**Date**: [YYYY-MM-DD]
**Mode**: [full | quick | privacy | api | mobile | deps]
**Commit**: [short SHA] [— working tree with uncommitted changes, if any]
**Scope**: surfaces [..]; code roots [..]; stack [..]; regions [.. | none | unset — asked]; handles_pii [true | false | unset — asked]
**Standards**: OWASP Top 10 [edition] ([source]) · OWASP API Security Top 10 2023 ([source]) · OWASP MASVS [version] ([source]) · CWE — or `NOT SOURCEABLE — edition not confirmed`
**Tools**: [tool version — ran | NOT CHECKED — reason], one per tool
**Audited by**: security-engineer via /security-audit
**Previous report**: [path | none]

## Summary

| Severity | Open | Accepted Risk | Resolved since previous |
|---|---|---|---|
| Critical | [N] | [N] | [N] |
| High | [N] | [N] | [N] |
| Medium | [N] | [N] | [N] |
| Low | [N] | [N] | [N] |

| # | Category | Coverage | Findings |
|---|---|---|---|
| [1] | [Secrets and keys] | [checked 412 files and 1,280 commits, 1 finding \| N/A — reason \| NOT ASSESSED — reason] | [SEC-001] |

[Two to five sentences: overall posture, the most important risk, what blocks launch, what was not assessed.]
[When money movement, health data or enterprise SSO is in scope: recommend an independent penetration test.]

## Findings

### SEC-001: [Title]
- **Severity**: [Critical | High | Medium | Low]
- **Status**: [Open | Accepted Risk | Out of Scope | Resolved]
- **Category**: [category name]
- **Reference**: [API1:2023 BOLA · CWE-639 · MASVS-STORAGE …]
- **Location**: `[path]` line [N] · [operation, e.g. `GET /v1/goals/{goalId}`] · [resource]
- **Evidence (redacted)**: [what was observed — never a secret value or real personal data]
- **Impact**: [who can do what to whom]
- **Remediation**: [the specific change]
- **Verification**: [the test or check that proves the fix — e.g. negative authorization test: cross-user read returns 404]
- **Effort**: [Low | Medium | High]
- **Owner**: [role or name]

[repeat, Critical first]

## Regional Compliance

### [region] — `.claude/docs/compliance/[region].md`

| Section | Item | Law/standard | Scored | Status | Evidence, question or owner |
|---|---|---|---|---|---|
| [Privacy & Data Protection] | [Cross-border transfer] | [Personal Information Protection Act (개인정보 보호법)] | [yes \| not scored — carried to /launch-checklist] | [Met \| Gap \| Accepted \| N/A \| NOT ASSESSED] | [...] |

## Dependency Inventory

| Package | Version | Ecosystem | Direct / transitive | Advisory | Severity | Reachable | Fixed in | License |
|---|---|---|---|---|---|---|---|---|

## Accepted Risk

| Finding | Severity | Accepted by | Date | Reason | Review by |
|---|---|---|---|---|---|

## Not Assessed

- [category or item] — [reason] — [what closes it: input, tool or skill]

## Remediation Priority

1. [SEC-NNN] — [one line] — effort [Low/Medium/High] — [/dev-story | /hotfix | configuration change by a human]

## Re-Audit Trigger

Re-run `/security-audit [mode]` after the Critical and High findings are remediated, after any change to
authentication, authorization, payments or personal-data handling, and before each release (`quick`).
```

Sections that do not apply to the mode (e.g. `## Regional Compliance` in `quick`, `## Dependency Inventory` in
`mobile`) are written with one line: `N/A — not covered by <mode> mode`.

---

## Phase 8: Write the Report

Ask: "May I write this to `production/security/security-audit-<mode>-YYYY-MM-DD.md`?" Write only after approval. If
a report of the same mode already exists for today, ask whether to update it in place.

Then offer, per Open Critical or High finding, to file it with `/bug-report` (a personal-data or money breach is
`S1-Critical`). Never commit — committing is the user's decision.

---

## Phase 9: Threat Model (`threat-model` mode)

Output: `docs/security/threat-model.md`, from `.claude/docs/templates/threat-model.md`. This mode writes **only**
that file — no audit report, no verdict line; the document's `## Review` section records who reviewed it and when.

**9a. Inputs.** Read, by section (`Grep` the `^## ` headings first), and name every one that is missing:
`docs/architecture/architecture.md` (components, topology, environments, integrations),
`docs/data/data-model.md` (`## Data Classification`, `## Ownership`, `## Retention & Deletion`), the API contract
under `docs/api/` (operations and security schemes), `docs/registry/architecture.yaml` (`data_ownership`,
`interfaces`), ADRs whose Domain is `Auth`, `Security` or `Data`, `docs/ops/slo.md` (`## Critical User Journeys` —
availability assets), and the `## Non-Functional Requirements` of MVP PRDs. Architecture document missing ⇒ say that
`/create-architecture` should come first and offer to build the model from an interview instead; sections built
without an input say `NOT ASSESSED — <input> missing`.

**9b. Existing model.** If `docs/security/threat-model.md` exists, ask: `Update in place` (default — keep threat
and mitigation IDs, add a `## Review` row) / `Rebuild from the template` (the old file is overwritten only after a
second confirmation).

**9c. Draft with the security-engineer.** Spawn `security-engineer` with the input paths (or "none"), the
`stack`, `platform.surfaces` and `compliance` lines, the compliance file paths selected in 0e, and the template path.
Ask it to draft, in order: `## Scope & Assets`, `## Trust Boundaries`, `## Data Flow` (Mermaid flowchart with
numbered flows), `## Threats (STRIDE)`, `## Mitigations`, `## Data Classification Summary`, `## Residual Risks`,
`## Review`.

**9d. Derivation checks** before showing the draft (obligation 5):
- every trust boundary appears in the threat table, and each of the six STRIDE letters is either a threat row or a
  one-line "not applicable because …";
- every operation of the contract that crosses the client boundary is covered by at least one threat row for
  spoofing, tampering, information disclosure and elevation of privilege (grouping operations with the same rule is
  allowed and stated);
- every `PII` / `Sensitive-PII` field of the data model is in `## Data Classification Summary`; the summary quotes
  the model and never re-classifies;
- every third party in the architecture appears as a boundary or is listed as out of scope with a reason;
- regional topics come only from the configured regions' files.

**9e. Review section by section.** Present each section; for each: approve, revise, or discuss (Question → Options →
Decision → Draft → Approval). Risk ratings and mitigation owners are the user's decisions; residual risks need a
named acceptor (the technical-director role and the user) with date and review trigger.

**9f. Write.** Ask: "May I write this to `docs/security/threat-model.md`?" Write only after approval. If the session
must stop early, offer to write the approved sections with the remaining ones marked `NOT ASSESSED — not yet
reviewed`.

**9g. Summary** in the conversation: boundaries (N), threats by risk (Open / Mitigated / Accepted), mitigations
`Missing` (N), and the inputs that were missing.

---

## Phase 10: Close

Print `Verdict: <TOKEN>` (audit modes) or the Phase 9 summary (threat model), the file written, and every
`NOT CHECKED` and `NOT ASSESSED` line.

- `full` or `quick` with no open Critical or High finding: "No blocking security findings. Report written to
  `production/security/`. Include this path when running `/gate-check launch`."
- Any open Critical finding: "Critical security findings must be resolved before any public release. Do not proceed
  to `/launch-checklist` or `/gate-check launch` until they are fixed and a re-audit confirms it."
- A targeted mode (`privacy`, `api`, `mobile`, `deps`): "This targeted report does not satisfy the Hardening
  `security-audit` step — run `/security-audit full` (or `quick` at `minimal` workflow) for that."

Then close with `AskUserQuestion`, offering only what applies:

- after `FAIL`: `/bug-report` for each Open Critical/High finding · `/dev-story` for the fix stories (or `/hotfix`
  when the flaw is live in production) · re-run `/security-audit <mode>` after the fixes · stop here;
- after `NOT ASSESSED`: the skill that closes the gap (`/setup-stack` for an unset stack or code roots, `/data-model`
  for a missing data model, `/api-design` for a missing contract) · re-run with scanners installed · stop here;
- after `CONCERNS` or `PASS` in `full` / `quick`: `/launch-checklist` · `/release-checklist` · `/gate-check launch`
  (in a fresh session) · `/tech-debt` for accepted Medium and Low findings · stop here;
- after `threat-model`: `/architecture-decision` for mitigations that need a decision (e.g. secrets management) ·
  `/api-design` to record auth scope and object-level rules per operation · `/data-model` for classification gaps ·
  `/gate-check validation` when the rest of the Architecture phase is done · stop here.

---

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and `autonomous` modes see
`.claude/docs/automation-modes.md`; `secrets_access` and `pii_data_access` prompt in every mode.

1. **Question → Options → Decision → Draft → Approval** — the scope (Phase 0), the scanner run list (Phase 2), every
   risk acceptance (Phase 6) and every threat-model section (Phase 9) are decided by the user.
2. **"May I write this to `<path>`?"** before every write — the audit report or the threat model. "May I run this?"
   before every command that contacts an external service or targets a running environment.
3. **Never assume a pattern is safe.** Flag it and let the user decide; an unverified control is not a control.
4. **Unset is not "no".** Unset surfaces, regions or `handles_pii` are questions to ask, never permissive defaults.
5. **Skips announce themselves.** Every skipped tool, category or checklist item appears as a `NOT CHECKED` or
   `NOT ASSESSED` line with its reason — a scan that could not look is not a scan that found nothing.
6. **Accepted risk is a valid outcome** when a named owner accepts it with a reason and a review date. Findings in a
   money-moving or personal-data path are held to a higher bar: a High there is treated like a Critical when deciding
   what must be fixed before launch.
7. **Production and secrets are out of reach.** Commands that would change production, shared infrastructure, a
   shared database or secrets are proposed for a human to run, with blast radius and rollback.
8. **No commits.** Committing is the user's decision.
9. **The next step is offered, never taken.** The closing widget (Phase 10) recommends the next skill and waits for
   the user's choice.
