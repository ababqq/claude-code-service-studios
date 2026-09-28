# Agent Spec: platform-engineer

> **Tier**: specialists
> **Category**: specialist
> **Spec written**: 2026-09-28

<!-- Asserts the canonical English text of .claude/agents/platform-engineer.md (quoted prompts,
     headings, verdict tokens), never the wording the model uses at run time in the user's
     conversation language. Examples use the canonical product "Moa". -->

## Agent Summary

The platform engineer builds and maintains the shared application libraries every feature
depends on: the data-access layer, caching helpers, the queue and job runner, the
feature-flag and config SDK, logging/tracing/metrics libraries, and the API client SDKs
generated from the contract for web and mobile. It is **not** infrastructure — IaC, CI/CD
and environments belong to devops-engineer and cloud-specialist. `/dev-story` routes a story
to it as primary when the Surface is `api` and the Layer is `Foundation` or the files are
under `stack.shared_roots`, and adds it as a secondary to web and mobile stories touching
shared roots. `/write-prd` consults it on `## Configuration & Flags`, and `/walking-skeleton`
uses it to wire the flag SDK for the staging flag rehearsal. It uses the Implementation
Workflow, has Bash and owns no director gate.

**Domain**: Shared application libraries and SDKs: data-access layer, caching, queue/job runner, feature-flag & config SDK, logging/tracing libraries, API client SDKs; not infrastructure (see devops-engineer, cloud-specialist) — code under `stack.shared_roots` (e.g. `packages`) and api Foundation code
**Escalates to**: tech-lead
**Delegates to**: —
**Gates owned**: none

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/platform-engineer.md`; frontmatter `name: platform-engineer` equals the file stem and the catalog `name`
- [ ] Frontmatter keys in canonical order: `name`, `description`, `tools`, `model`, `maxTurns` — no `disallowedTools`, `memory`, `skills` or `isolation`
- [ ] `description` is one double-quoted line that starts with the domain seed "Shared application libraries and SDKs: data-access layer, caching, queue/job runner, feature-flag & config SDK, logging/tracing libraries, API client SDKs; not infrastructure (see devops-engineer, cloud-specialist)." and continues with "Use when …"
- [ ] `tools: Read, Glob, Grep, Write, Edit, Bash`
- [ ] `model: inherit`, matching `.claude/docs/model-tiers.md`; `maxTurns: 20`
- [ ] Opening line after the frontmatter: "You are the Platform Engineer for a web/mobile/API product team."
- [ ] The `##` headings of the body are exactly these, in this order:
  1. `## Collaboration Protocol` — contains `### Implementation Workflow` (with the question "Should this be a shared package or module-local helper?" and "May I write this to [filepath(s)]?"), then the paragraph beginning "**Bounded exception — orchestrated runs.**", verbatim
  2. `## Core Responsibilities`
  3. one `## [Domain] Standards` heading for shared libraries (currently `## Shared Library Standards`)
  4. `## What This Agent Must NOT Do`
  5. `## Delegation Map`
- [ ] Not a gate owner: the file has **no** `## Gate Verdict Format` section, and no `## Sub-Specialist Orchestration` or `## Version Awareness` section
- [ ] Tenant or owner scoping is built into the data-access layer so a feature cannot forget it; caches keyed by the caller where responses depend on the caller — a cache never leaks one user's data to another
- [ ] The job runner provides retries with backoff and jitter, dead-letter handling, idempotency helpers, an outbox relay and scheduled jobs with a distributed lock; queues are publisher/consumer contracts with versioned message schemas
- [ ] The flag SDK's in-code defaults equal the defaults recorded in the PRD's `## Configuration & Flags`; security- or billing-sensitive flags are evaluated server-side; config is validated against a schema at startup
- [ ] Logging and tracing libraries correlate by request and trace ID and ship a PII and secret redaction filter that is on by default
- [ ] API client SDKs are generated from `docs/api/` and never hand-edited; breaking changes to a shared package need a major version, a deprecation window and a consumer upgrade plan
- [ ] Shared packages never import from `apps/*` or `services/*` and never contain one product area's domain logic; new dependencies are checked against `docs/architecture/tech-radar.md`
- [ ] "A typecheck or build is not a run." — the library is exercised from a real consumer and the observation kept under `production/qa/evidence/<story-slug>/`; pure library Logic stories record `Run result: N/A`
- [ ] Version-sensitive library and runtime APIs are checked against `docs/stack-reference/VERSION.md` and `docs/stack-reference/<component>/`; uncovered questions get `NOT SOURCEABLE — run /setup-stack refresh`
- [ ] `## Delegation Map` has exactly three lines: `Reports to: tech-lead`, `Delegates to: —`, and `Coordinates with: …`
- [ ] Reporting line: tech-lead lists `platform-engineer` in its own `Delegates to:` line
- [ ] Every agent named in `Coordinates with:` exists under `.claude/agents/`
- [ ] Domain clearly stated; infrastructure, IaC, CI/CD and environments (devops-engineer, cloud-specialist), feature logic, vendor choices without an ADR (technical-director) and production flag changes are stated as outside it
- [ ] Escalation path documented: breaking changes and ADR disagreements go to tech-lead
- [ ] Does not make decisions outside its domain

---

## Test Cases

### Case 1: In-Domain Request — typed flag client for the progress ring

**Scenario**: The platform engineer is asked to add the flag `goals.v2-progress-ring` to the
shared flag SDK so web, mobile and API can evaluate it.

**Fixture**:
- Accepted ADR choosing OpenFeature with a hosted provider; SDK in `packages/flags`
- `design/prd/goals.md` `## Configuration & Flags` records `goals.v2-progress-ring`, default `false`, owner product-manager, removal date 2027-01-31
- `stack.shared_roots: [packages]`

**Expected behavior**:
1. Reads the ADR and the PRD row; asks "Should this be a shared package or module-local helper?" only where it is genuinely open (the typed accessor belongs in the shared package)
2. Proposes a typed accessor whose in-code default is `false` (equal to the PRD), a kill switch, server-side evaluation where the flag gates billing-relevant behaviour, and unit tests with a fake provider
3. Asks "May I write this to [filepath(s)]?" for the files under `packages/flags`
4. Does not flip the flag in any environment itself

**Assertions**:
- [ ] Default equals the PRD's recorded default
- [ ] Tests use a fake provider; no network in unit tests
- [ ] Files approved before writing; no flag change made

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Out-of-Domain Redirect — Redis cluster in Terraform and a production flag flip

**Scenario**: The platform engineer is asked to "write the Terraform for the new Redis
cluster, add the deploy job to GitHub Actions, and turn `goals.v2-progress-ring` on in
production".

**Fixture**:
- `stack.layers.cloud.root: infra`; `.github/workflows/ci.yml` exists

**Expected behavior**:
1. Redirects the Terraform to cloud-specialist / devops-engineer and the CI job to devops-engineer (both `infra_changes`, applied by a human)
2. Declines the production flag change: it is a `production_deploys` action; proposes it for a human to perform through the rollout plan
3. Offers the in-domain part: the cache client configuration the new cluster will need

**Assertions**:
- [ ] No IaC, CI workflow or production flag touched
- [ ] devops-engineer / cloud-specialist named; the flag change proposed for a human

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Consultation — `/write-prd goals` configuration and flags (no gate verdict)

**Scenario**: `/write-prd goals` consults the platform engineer for
`## Configuration & Flags`.

**Fixture**:
- Draft PRD lists "a flag for the new ring" and "a limit on active goals for Free" without keys, defaults or owners

**Expected behavior**:
1. Returns a table the skill can use: flag key (`goals.v2-progress-ring`), default, owner, removal date; config values (e.g. the Free active-goal limit as a config value whose source is the registry constant) with type, default and who may tune it
2. Notes which values must be evaluated server-side and which may be exposed to clients
3. Writes nothing (the PRD is under `design/`) and emits no `[GATE-ID]: TOKEN` line

**Assertions**:
- [ ] Every flag has key, default, owner and removal date
- [ ] No PRD edit and no gate token

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Conflict Escalation — domain logic and a breaking change in a shared package

**Scenario**: backend-engineer asks the platform engineer to add goal-specific eligibility
checks to `packages/db` and to change the generated client's `listGoals()` signature in a
way the mobile app 1.3.x cannot compile against.

**Fixture**:
- `packages/api-client` consumed by `apps/web` and `apps/mobile`; mobile pins the previous minor

**Expected behavior**:
1. Declines to put goal eligibility into the shared data-access package (feature logic belongs in the owning module) and says so
2. Surfaces the breaking change: it needs a major version, a deprecation window and a consumer plan
3. Escalates the plan to tech-lead instead of publishing the breaking version

**Assertions**:
- [ ] No feature logic added to a shared package
- [ ] Breaking change escalated to tech-lead with a deprecation proposal

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Context Pass-Through — Foundation cache helpers story

**Scenario**: `/dev-story` routes
`production/epics/platform-foundation/story-002-cache-helpers.md` (`> **Surface**: api`,
`> **Layer**: Foundation`, `> **Type**: Logic`) to the platform engineer as primary with the
routed backend sub-specialist as secondary, and names
`production/qa/evidence/story-002-cache-helpers/`.

**Fixture**:
- Accepted ADR choosing Redis-compatible cache; story acceptance criteria require namespaced, versioned keys, TTL jitter and stampede protection

**Expected behavior**:
1. Uses the passed story, ADR and roots without re-asking
2. Proposes cache-aside helpers keyed by caller where the response depends on the caller, with single-flight protection and concurrency tests
3. Asks before writing the source files under `packages/`; records `Run result: N/A — pure library Logic story` rather than inventing an observation
4. Returns the paths written and a short summary

**Assertions**:
- [ ] No cross-user cache leakage possible by construction
- [ ] Concurrency-sensitive helper tested concurrently
- [ ] `N/A` used only because the story is a pure Logic library story

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: NOT ASSESSED — no shared root and no flag-vendor ADR

**Scenario**: The platform engineer is asked to "set up the feature-flag SDK" for a project
without a declared shared root and without a decision on the flag vendor.

**Fixture**:
- `stack.shared_roots` unset; resolved `code_roots` line lists only `undeclared=packages/common (workspace)`
- No ADR mentions feature flags

**Expected behavior**:
1. Writes no code: asks the user to choose the root and suggests `/setup-stack` to declare `stack.shared_roots`
2. Does not pick a vendor; suggests `/architecture-decision` for the flag vendor
3. Says what is not assessed and why, instead of scaffolding a guess

**Assertions**:
- [ ] No code written in an undeclared root without the user's choice
- [ ] No vendor chosen without an ADR
- [ ] Missing inputs named

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Stays within declared domain — shared libraries and SDKs, never infrastructure (specialist S1)
- [ ] Makes no binding decision on vendors, feature logic or infrastructure (specialist S2)
- [ ] Out-of-domain requests redirected to the correct agent, not refused silently (specialist S3)
- [ ] Escalates breaking changes and ADR conflicts to tech-lead
- [ ] Uses `"May I write this to [filepath(s)]?"` before file writes, except under the bounded exception
- [ ] Never executes a command that changes production, shared infrastructure, a shared database or secrets

---

## Coverage Notes

- Observability library behaviour (redaction filter on by default, trace correlation) is
  asserted statically; a live case should emit a log line containing an email address and
  confirm it is redacted.
- The flag rehearsal of `/walking-skeleton` is covered by that skill's spec.
- Generated SDK drift is checked by contract tests, not by this spec.
