---
name: create-architecture
description: "Architecture blueprint: layers, topology & environments, data flow, integrations, observability, SLOs; optional per-feature technical design."
argument-hint: "[full | section <name> | tdd <feature>] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/create-architecture/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,docs.density,stack,surfaces,team.size,compliance,distribution`

Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).


# Create Architecture

This skill produces `docs/architecture/architecture.md` — the whole-system blueprint
that turns the approved product record (product brief, feature map, MVP PRDs) into
layers and modules, a deployment topology with its environments, data flow,
integrations, a security model, observability and NFR budgets — and, together with
`sre-engineer`, `docs/ops/slo.md`, the critical user journeys and their SLOs. It sits
between Definition and the ADRs, and must exist before epics and sprints are planned.

**Distinct from `/architecture-decision`**: ADRs record individual point decisions.
This skill creates the whole-system blueprint that gives ADRs their context and names
the ADRs still to be written. The API contract (`/api-design`), the data model
(`/data-model`) and the threat model (`/security-audit threat-model`) are separate
artifacts; this document points at them and never duplicates them.

See `.claude/docs/director-gates.md` for the full check pattern. Individual gate definitions live in `.claude/docs/director-gates/<gate-id>.md` — the spawned agent reads its own gate file; do not read it in the parent session.

### Outputs

| Path | What is written | Mode |
|------|-----------------|------|
| `docs/architecture/architecture.md` | The architecture document (structure in Phase 13) | default / `full`, `section <name>` |
| `docs/ops/slo.md` | Critical user journeys, SLIs & SLOs, error budget policy, dashboards & alerts, on-call — from `.claude/docs/templates/slo.md`, drafted with `sre-engineer` | default / `full`, `section slo` |
| `docs/architecture/tdd-<feature>.md` | A per-feature technical design from `.claude/docs/templates/technical-design-document.md` — optional, never a gate artifact | `tdd <feature>` |
| `project.yaml` (`performance.*` only) | The NFR budgets agreed in Phase 10, when the user approves writing them | default / `full`, `section nfr` |

### Configuration this skill applies

**`workflow`** (see `.claude/docs/workflow-modes.md`):
- `full` — every section at full depth: module ownership with interfaces, every
  integration, full ADR audit and traceability coverage, an SLO for every critical
  user journey.
- `standard` — every section, simplified: the layer map, the topology and
  environments, the security model and observability in brief, and the required
  ADRs with the **critical** (Foundation-layer) ones marked — the Validation gate
  requires those. In `docs/ops/slo.md` the critical user journeys are required; SLO
  numbers are recommended.
- `minimal` — not required. The one-pager is the design record; the skill can still
  be run voluntarily, and then reads `design/product/one-pager.md` for its context.

**`docs.density`** — it controls per-section *depth*, where `workflow`
controls which sections exist. `modes.rigor` sets both together; set
`docs.density` explicitly to vary depth alone: `terse` = diagrams + decision
bullets, no essays; `balanced` = diagrams + a paragraph of reasoning per choice;
`thorough` = full prose with rationale, trade-offs and the alternatives considered
per section. Apply it to every section you author; tables stay whole at every
density.

**`stack`** — the configured layers (`web`, `mobile`, `backend`, `data`, `cloud`),
their frameworks, versions and paths, and the specialist routing
(`<lead>><sub>`). The **routed stack leads** this skill consults are the leads of the
configured layers (`web-specialist`, `mobile-specialist`, `backend-specialist`,
`data-specialist`, `cloud-specialist`). A layer listed under `unset=` has no
specialist: print `NOT CHECKED — <layer> layer not configured (run /setup-stack)`.
Data and cloud may stay unset until their Foundation ADRs are accepted — the
architecture then lists those ADRs as required instead of assuming a component.

**`surfaces`** — which clients ship (`web`, `ios`, `android`, and `api` for an
externally consumed API). They decide the client side of the topology, the
multi-client rules and which NFR budgets apply. An unset `platform.surfaces` is
asked, never assumed.

**Read from `project.yaml` with Read at run time**: the `performance.*` budgets,
`platform.browsers`, `platform.min_os.ios` and `platform.min_os.android` (they have no
`resolve_config` label). `release.distribution` and `compliance` (regions,
`handles_pii`) come from the resolved block; an unset part is an open question for
this document — never "none" or "no".

### What this skill never does

- **Write or accept ADRs.** It names the decisions and their priority; every ADR is
  written with `/architecture-decision` and accepted only through
  `/architecture-decision accept`.
- **Write the API contract, the data model or the threat model** — it points to
  `/api-design`, `/data-model` and `/security-audit threat-model`.
- **Write `docs/architecture/tr-registry.yaml`.** The requirement IDs in its baseline
  reuse registered IDs; `/architecture-review` is the only writer of the registry.
- **Write** `project.stage`, any `modes.*` key, or the six knobs `modes.rigor` fronts
  (`modes.review_mode`, `modes.workflow`, `docs.density`, `qa.level`,
  `modes.story_granularity`, `team.size`).
- **Run deploys, provisioning or migrations**, or record credentials. Topology and
  environments are described, never applied.
- **Edit the repository-root `CLAUDE.md`.**

---

## Phase 1: Parse Arguments

| Argument | Mode |
|----------|------|
| *(none)* or `full` | Full guided walkthrough — Phases 2–14, then Phase 17 |
| `section <name>` | Revise one part of an existing architecture — Phase 15, then Phase 17. `<name>` ∈ `layers`, `topology`, `data-flow`, `integrations`, `security`, `observability`, `nfr`, `slo`, `adrs`, `open-questions` |
| `tdd <feature>` | Per-feature technical design — Phase 16 (it closes with its own next steps) |

`--review full|lean|solo` may follow any mode; it overrides the resolved `review_mode`
for this run (it only matters where this skill spawns a gate — Phase 14).

An unknown mode or section name: list the valid ones and ask; never guess.

---

## Phase 2: Load Context

Load context silently — do not narrate file reads. Every absence below has a branch;
a file that exists but is empty, or still holds only template placeholders, counts
as absent. Present-but-empty is the case that most looks like present.

### 2a. Stack context (critical)

1. Read `docs/stack-reference/VERSION.md` → the model knowledge cutoff, the pin date,
   and the Pinned Components table (Layer, Component, Version, Knowledge Risk,
   Source, Retrieved).
2. Read **only the component folders the architecture touches** — not every folder
   under `docs/stack-reference/`. Glob `docs/stack-reference/*/VERSION.md` to learn
   what exists, then:
   - MEDIUM or HIGH Knowledge Risk components: `VERSION.md` and, where they exist,
     `breaking-changes.md`, `deprecated-apis.md` and `current-best-practices.md`;
   - LOW components: `VERSION.md` and `deprecated-apis.md` if present.

   **If it is unclear whether a component matters, read it** — a missed stack
   constraint is far more expensive here than a redundant read, because this is
   where those constraints get baked into the architecture.
3. If the `stack` line reads `stack: unset — run /setup-stack`, stop:
   > "No stack is configured. Run `/setup-stack` first. Architecture cannot be
   > written without knowing which frameworks and versions you are targeting."
4. If the `stack` line carries ` pinned_on=unset`, say so: the Architecture gate
   expects a pinned stack. Offer `/setup-stack` first; continue if the user prefers,
   and list the unpinned components as open questions.

### 2b. Product context and the Technical Requirements Baseline

**Check each file exists before reading it.** At `standard` and `full`:

- **`design/product/feature-map.md` absent** — stop:
  > "No feature map found. Run `/map-features` first. An architecture written
  > without it invents modules for features nobody mapped, and every ADR, epic and
  > story downstream inherits that invention."
- **`design/product/product-brief.md` absent** — stop and point at `/brainstorm`.

At `minimal`, read `design/product/one-pager.md` in their place (its
`## Core User Journey`, `## Stack` and `## Build Order` sections); if that is absent
too, stop — there is no product record to architect against.

Then:

1. From the feature map's main table (`| Feature | Category | Layer | Tier | Status | PRD | Depends On |`),
   take every feature, its Layer, Tier and PRD path. The **MVP PRDs** are the PRD
   paths on rows whose Tier is `MVP`; an MVP feature without a PRD is reported and
   listed as an open question — never silently dropped.
2. From the brief: product principles & anti-goals, success metrics, MVP scope.
3. `design/product/user-journey.md` when it exists — the candidates for the critical
   user journeys of Phase 10.
4. **Every PRD in `design/prd/*.md`** — extract technical requirements from the
   sections that carry them, **not from whole files**. Establish the denominator
   first (glob `design/prd/*.md`, count **N**, and note which are MVP), then:
   ```
   Grep pattern="^## (Functional Requirements|Business Rules & Calculations|Edge Cases|Dependencies|Non-Functional Requirements|Success Metrics & Instrumentation|API & Data Impact)" glob="design/prd/*.md" output_mode="content" -A 40
   ```
   Overview, Goals & Non-Goals and User Value are product framing and imply no
   architecture; the scanned set is where rules, limits, failure modes, cross-feature
   contracts and NFRs live.

   Full-read a PRD when it matched **zero** sections (it predates the template — a
   zero-match means "unstructured", never "no requirements") or when a scanned
   section refers to material outside itself. **Never treat an absent section as an
   absent requirement**: report any PRD that contributed nothing, rather than letting
   it drop silently out of the baseline.

   For each, extract:
   - Entities and state the feature implies, and which feature owns them
   - Operations the clients need (reads, writes, searches, bulk actions)
   - Performance, availability and scale constraints, stated or implied
   - Security and privacy needs: who may do what, personal data, retention
   - Consistency needs (money movement, counters, idempotent retries)
   - Background and scheduled work, third-party callbacks and webhooks
   - Cross-feature communication (synchronous call or event)
   - Instrumentation: the events the feature emits

Build a **Technical Requirements Baseline** — a flat list of every extracted
requirement. Reuse the ID from `docs/architecture/tr-registry.yaml` wherever the
requirement is already registered; number the rest `TR-<feature-slug>-NNN` after the
highest registered number for that feature and mark them provisional —
`/architecture-review` registers them and is the only writer of the registry.

```
## Technical Requirements Baseline
Extracted from [N] PRDs ([M] MVP) | [X] total requirements ([Y] provisional IDs)

| Req ID | PRD | Tier | Requirement | Type | Domain |
|--------|-----|------|-------------|------|--------|
| TR-goals-001 | goals.md | MVP | A user creates a savings goal with a target amount and date | functional | Data |
| TR-goals-002 | goals.md | MVP | Goal list loads in ≤ 300 ms p95 | nfr | API |
| TR-payments-003 | payments.md | MVP | A scheduled debit is charged at most once per period, even on retry | functional | Integrations |
```

Type is `functional` or `nfr`; Domain uses the ADR vocabulary (`API`, `Data`, `Auth`,
`Security`, `Frontend`, `Mobile`, `Infra`, `Messaging`, `Observability`,
`Integrations`, `ML`). This baseline feeds every later phase: by the end of the
session, every MVP requirement is covered by an architectural section or an ADR to
write.

### 2c. What is already decided

- `docs/architecture/architecture.md` — if it exists in a full run, say so (its
  version and date) and ask: update it section by section, or write a new version
  after showing the differences. Never overwrite it silently.
- ADRs — to learn **what has already been decided and in which domain**, scan the
  headers; do not full-read every ADR to produce a list of numbers and domains:
  ```
  Grep pattern="^## (Status|Summary)" glob="docs/architecture/adr-*.md" output_mode="content" -A 4
  Grep pattern="\*\*(Domain|Layer|Stack Components)\*\*" glob="docs/architecture/adr-*.md" output_mode="content"
  ```
  List the ADRs found with their status, domain and layer. Full-read a specific ADR
  only when a decision this session would collide with it and you need its reasoning.
- `docs/registry/architecture.yaml` — `data_ownership`, `interfaces`, `slo_budgets`,
  `technology_decisions`, `forbidden_patterns`: binding stances this architecture
  must not contradict.
- `docs/architecture/tech-radar.md` — the Adopt ring, and the Hold and Forbidden
  Patterns rings as constraints.
- When they exist: `docs/api/` (the contract), `docs/data/data-model.md`,
  `docs/security/threat-model.md`, `docs/ops/slo.md`.

### 2d. Knowledge Risk inventory

Display:

```
## Stack Knowledge Risk Inventory
Stack: [the resolved stack line]
Model knowledge cutoff: [from docs/stack-reference/VERSION.md]

### HIGH risk components (verify against the stack reference before deciding)
- [Component + version]: [key changes from breaking-changes.md, with sources]

### MEDIUM risk components (verify key APIs)
- [Component + version]: [key changes]

### LOW risk components
- [Component + version]: [no significant post-cutoff changes recorded]

### Unpinned or unconfigured
- [layer or component]: [becomes a required ADR or an open question]

### Requirements that touch HIGH/MEDIUM components
- [TR-ID] → [component] → [risk]
```

When any component is HIGH, use `AskUserQuestion`:
- Prompt: "One or more stack components are HIGH risk — the model's knowledge may be unreliable for them. Architectural recommendations touching them should be cross-checked with the stack reference before being acted on. How would you like to proceed?"
- Options:
  - `[A] Proceed — flag HIGH risk components throughout the document`
  - `[B] Let me check the stack reference first — pause here`
  - `[C] Show me which components are HIGH risk and why`

---

## Phase 3: Layers & Modules

Map every feature of the feature map into modules and every module into a layer. The
layer vocabulary is the one ADRs, epics and stories carry —
`Foundation / Core / Feature / Presentation`. The platform the product runs on sits
below it and is not a layer value:

```
┌───────────────────────────────────────────────────────────────┐
│  PRESENTATION  web app, admin console, iOS/Android app shells, │  ← screens, navigation,
│                BFF endpoints where a client needs its own shape│    client state
├───────────────────────────────────────────────────────────────┤
│  FEATURE       goals, notifications, subscription, onboarding  │  ← feature workflows
├───────────────────────────────────────────────────────────────┤
│  CORE          ledger & deposits, payments orchestration,      │  ← domain rules the
│                entitlements                                    │    features share
├───────────────────────────────────────────────────────────────┤
│  FOUNDATION    identity & auth, data access, outbox & queue,   │  ← must exist before
│                config & flags, observability, secrets          │    anything else
└───────────────────────────────────────────────────────────────┘
   platform: cloud provider, managed database, CDN, app stores, third parties
```

(The example is Moa — a savings app on web, iOS, Android and API. Use the product's
own features.)

1. **Module style** — propose a proportionate style: for an early-stage team a
   **modular monolith** (one deployable API with strict module boundaries) plus a
   **worker** for scheduled and async work is usually right; separate services only
   where a second team, a different scaling profile or an isolation requirement
   exists today. If the style is not yet decided by an ADR, it becomes part of the
   "deployment topology & environments" Foundation ADR (Phase 11).
2. **Module ownership** — one table per layer:

   | Module | Layer | Owns (entities, state) | Exposes (operations, events) | Consumes | Lives in | Stack |
   |--------|-------|------------------------|------------------------------|----------|----------|-------|
   | goals | Feature | savings_goal, deposit | GET/POST /v1/goals · event `goals.deposit.recorded` | identity (current user), payments events | `apps/api/src/modules/goals` | NestJS 11.0, Prisma 6 |

   Every entity has exactly one owning module; check each against the
   `data_ownership` stances of `docs/registry/architecture.yaml`. "Lives in" is the
   path inside the layer's configured root from the `stack` line.
3. **Dependency diagram** — an ASCII graph of module dependencies. No cycles; nothing
   in Foundation depends on a layer above it; Feature modules talk to each other
   through operations or events, never through each other's tables.
4. **Stack awareness check** — for each Foundation and Core module that uses a HIGH
   or MEDIUM risk component, show the relevant excerpt of the stack reference inline:
   ```
   [Component + version] — Knowledge Risk HIGH
       Verified against: docs/stack-reference/<component>/breaking-changes.md
       Behaviour confirmed: [yes / NEEDS VERIFICATION]
   ```

Present the layer map and the ownership tables and ask for approval. On approval,
**create the document skeleton immediately** — every section heading of the
Phase 13 structure, this section filled, the others marked `TBD` — after
"May I write this to `docs/architecture/architecture.md`?". Writing the skeleton now
means an interrupted session loses at most one section.

---

## Phase 4: Deployment Topology & Environments

1. **Runtime topology** — an ASCII diagram from clients to data: web (SSR or static,
   behind a CDN), iOS and Android apps, the admin console, the edge (CDN, WAF), the API
   (containers or serverless functions), the worker, the primary database (and replica),
   cache, queue, object storage, and the third parties — with the trust boundaries.
2. **Environments**:

   | Environment | Purpose | Deployed by | Data | Config & secrets | Feature flags | Access |
   |-------------|---------|-------------|------|------------------|---------------|--------|
   | local | development | developer | seed data | `.env` from the example file, no real secrets | local defaults | developers |
   | preview | one per pull request | CI | seed data | per-environment store | per preview | team |
   | staging | production-like verification, load tests, the walking skeleton | CI/CD pipeline | synthetic or anonymised | per-environment store | staging values | team |
   | production | users | CI/CD pipeline only | real | per-environment store, least privilege | production values | on-call, audited |

   Staging mirrors production's topology at smaller scale; production is changed
   only through the pipeline; no production credential exists outside production.
   Mobile preview and staging builds point at staging (internal testing tracks,
   TestFlight).
3. **Release path per surface** — web and API: continuous deploy through the
   pipeline with flags for exposure; iOS and Android: store builds with phased
   release, over-the-air updates only within what the store policies allow (see the
   mobile stack reference), a minimum supported app version and a force-update path.
   Database changes follow expand → migrate → contract around application deploys —
   planned per change with `/data-model migration <slug>`.
4. **Regions and data residency** — the hosting region(s) and where personal data is
   stored. For each region in `compliance.regions`, cross-border transfer is a topic
   to verify in `.claude/docs/compliance/<region>.md` — never state a legal rule as
   fact here.
5. **Capacity, backup and recovery** — expected load at launch and at 10×; scaling
   approach; backups, a restore that is actually tested, and the recovery point and
   recovery time objectives.
6. **Cost** — an order-of-magnitude monthly estimate at MVP scale with the largest
   cost drivers named; figures carry a pricing source or say `NOT DETERMINED`.

Present, approve, then Edit the section in after "May I write this to
`docs/architecture/architecture.md`?".

---

## Phase 5: Data Flow

Define how data moves between modules in the scenarios that matter. Cover at minimum:

1. **Request path** — client → edge → API → module → database: how the authenticated
   user and tenant reach the domain layer, where input is validated, the correlation
   ID that follows the request.
2. **Event path** — how modules communicate without tight coupling: the outbox (or
   equivalent) that makes "write + publish" atomic, the queue, the publisher and
   consumers of each event, idempotent consumers, retry with backoff, dead-letter
   handling, event versioning.
3. **Third-party callbacks** — webhooks and redirects (payment results, social
   login): signature verification, replay protection, idempotent handling, what
   happens when the callback never arrives.
4. **Scheduled work** — jobs (e.g. Moa's auto-debit run): scheduling, locking so one
   run executes at a time, resumable batches, reconciliation.
5. **Client state and sync** — caching on web and mobile, optimistic updates,
   offline behaviour on mobile, conflict resolution, what the server always
   recomputes (amounts, entitlements).
6. **Data lifecycle** — analytics events from the tracking plan to their
   destination; account deletion reaching every store that holds personal data.

Use ASCII sequence diagrams where helpful. For each flow name: the data, the caller
and callee (or publisher and consumers), synchronous call or event, the consistency
it needs (strong for money movement, eventual where users tolerate it), the
idempotency mechanism, and the owning module.

Get approval per scenario, then Edit the section in after "May I write this to
`docs/architecture/architecture.md`?".

---

## Phase 6: Integrations

One row per third party:

| Integration | Purpose | Direction | Protocol | Credentials | Timeouts & retries | Failure mode & fallback | Personal data shared | Sandbox for staging | Exit plan | Tech radar ring |
|-------------|---------|-----------|----------|-------------|--------------------|-------------------------|----------------------|---------------------|-----------|-----------------|

Typical rows for a Korean consumer product: Kakao Login, Naver Login and Sign in
with Apple; Toss Payments (billing keys for auto-debit, payment webhooks); push
through APNs and FCM; KakaoTalk informational messages (알림톡) through a messaging
vendor; transactional email; analytics; error and crash reporting. When
`compliance.regions` includes `kr`, the consent and message-type topics of
`.claude/docs/compliance/kr.md` are listed as items to verify — for example, that
알림톡 carries informational messages only.

An integration that is not on the tech radar's Adopt or Trial ring is a decision to
make: list it as a required ADR (Domain `Integrations`) rather than adopting it here.

Present, approve, then Edit the section in after "May I write this to
`docs/architecture/architecture.md`?".

---

## Phase 7: Security Model

1. **Authentication** — sessions or tokens; access-token lifetime, refresh-token
   rotation and revocation; social login and account linking (never by matching email
   alone); step-up verification for sensitive actions (changing the debit account,
   exporting data, deleting the account).
2. **Authorization** — object-level ownership checks on every operation that takes
   an ID; roles for admin and support operations; property-level rules (clients can
   never set `ownerId`, `plan` or `role`).
3. **Trust boundaries** — the diagram of Phase 4 with each boundary named: what
   crosses it and how it is verified.
4. **Secrets** — where secrets live (a managed secret store per environment), who and
   what can read them, how they rotate. Secrets management is a Foundation ADR.
5. **Encryption** — in transit everywhere; at rest for databases, backups and object
   storage; field-level for `Sensitive-PII`.
6. **Personal data** — which modules hold personal data, the classification scheme
   (`Public`, `Internal`, `Confidential`, `PII`, `Sensitive-PII` — detailed per field
   by `/data-model`), retention and the deletion path, and no personal data in logs,
   analytics events or error reports. `handles_pii` printed `(unset -- ask)` on the
   resolved `compliance` line is an open question.
7. **Admin console** — SSO with MFA, least-privilege roles, an audit log of every
   admin action.
8. **Abuse controls** — rate limits per user and per IP; protection of the flows
   attackers automate (sign-up rewards, OTP and SMS pumping, enumeration).
9. **Regional compliance** — for each region in `compliance.regions`, the topics of
   `.claude/docs/compliance/<region>.md` that shape the architecture, as items to
   verify; `regions=none` (the user set `[]`) means the user chose none; a part
   printed `(unset -- ask)` is asked.
10. **Threat model** — when the product handles personal data,
    `/security-audit threat-model` is required before Validation; recommended
    otherwise. This section is its input, not its replacement.

Present, approve, then Edit the section in after "May I write this to
`docs/architecture/architecture.md`?".

---

## Phase 8: Observability

- **The three signals** — logs, metrics and traces, with one correlation ID across
  web, mobile, API and worker (OpenTelemetry or the stack's equivalent — check the
  stack reference for the pinned SDK).
- **Logs** — structured, levelled, with personal data redacted at the source;
  retention per environment; the audit log kept apart from application logs.
- **Metrics** — request rate, errors and duration per operation; queue depth and lag,
  dead-letter count; job success and duration; the business signals the success
  metrics need.
- **Client telemetry** — real-user monitoring of Core Web Vitals on web; crash and
  hang reporting on mobile (crash-free sessions).
- **Alerting** — on SLO burn rate, not on raw thresholds; which alerts page is decided
  with `sre-engineer` in Phase 10 and recorded in `docs/ops/slo.md`.
- **Dashboards** — one per critical user journey, plus one per module's dependencies.

Observability is a Foundation ADR. Present, approve, then Edit the section in after
"May I write this to `docs/architecture/architecture.md`?".

---

## Phase 9: Stack Lead Review

Before the budgets and ADR list are settled, spawn the **routed stack lead of each
configured layer** via `Agent`, in parallel (issue every call before waiting for any
result) — `web-specialist`, `mobile-specialist`, `backend-specialist`,
`data-specialist`, `cloud-specialist`, as the `stack` line configures them. This is a
consultation, not a director gate: `review_mode` does not skip it — the user may.

Give each lead the sections drafted so far that touch its layer, the component
versions from the `stack` line and the `docs/stack-reference/` paths read in 2a, and
ask it to:

1. Flag decisions that fight the pinned frameworks rather than use them
2. Flag APIs or patterns that changed or were deprecated after the model's knowledge
   cutoff (from the stack reference, with the file)
3. Name missing pieces its layer needs (for mobile: push, deep links, offline storage,
   minimum OS; for web: rendering mode and caching; for backend: jobs, transactions,
   module boundaries; for data: indexes, connection limits, migrations; for cloud:
   networking, IAM, environments)

For each layer under `unset=`, print
`NOT CHECKED — <layer> layer not configured (run /setup-stack)`.

A **blocking** finding (wrong API, unsupported pattern) revises the affected section
with the user before continuing; **minor** findings become open questions.

---

## Phase 10: NFR Budgets and SLOs

### 10a. NFR budgets

Read the `performance.*` keys of `project.yaml` and show the budgets that apply to the
resolved surfaces:

| Surface | Keys |
|---------|------|
| `api` or any backend | `performance.api_p95_ms`, `performance.error_rate_pct`, `performance.availability_pct` |
| `web` | `performance.lcp_ms`, `performance.inp_ms`, `performance.cls`, `performance.bundle_kb` |
| `ios`, `android` | `performance.cold_start_ms`, `performance.crash_free_pct` |

For each unset key, propose a value with its reasoning — for web, the "good"
Core Web Vitals thresholds at p75 (LCP ≤ 2500 ms, INP ≤ 200 ms, CLS ≤ 0.1; Source:
https://web.dev/articles/vitals) are a common starting point; for API and mobile,
derive from the PRDs' `## Non-Functional Requirements` and the topology. The user
decides every number. Show the block, then ask "May I write this to `project.yaml`?"
and write only the `performance.*` keys the user approved; a key the user leaves open
stays unset and is listed as an open question (the Validation gate reports unset
budgets as CONCERNS). `performance.enforce` is changed only through `/settings`.

### 10b. SLO document — with `sre-engineer`

Spawn `sre-engineer` via `Agent` (a consultation; `review_mode` does not skip it) with:
the template path `.claude/docs/templates/slo.md`; the candidate journeys (from
`design/product/user-journey.md`, the PRDs' success metrics and the brief's MVP
scope — at `minimal`, the one-pager's `## Core User Journey`); the budgets of 10a; the
topology, data flow and observability sections; and the integrations whose
availability bounds a journey. Ask for a draft of all five sections of the template:
`## Critical User Journeys`, `## SLIs & SLOs`, `## Error Budget Policy`,
`## Dashboards & Alerts` and `## On-call`.

Review the draft with the user section by section:

- **Critical User Journeys** — three to seven user-visible outcomes, each with a
  kebab-case name other files refer to (the walking skeleton, E2E stories, load-test
  scenarios and runbooks use these names). Required at `standard` and `full`.
- **SLIs & SLOs** — an SLI as good events ÷ valid events and where it is measured;
  targets from 10a; the error budget each implies (99.9% over 30 days is about
  43 minutes). At `full` every journey has an SLO; at `standard` numbers are
  recommended and a journey may carry `TBD — measured on staging in Validation`.
- **Error Budget Policy**, **Dashboards & Alerts** (every paging alert names its runbook
  path `docs/ops/runbooks/<alert-slug>.md`, written later with
  `/incident runbook <alert-slug>`), **On-call** — drafted now; a part that cannot be
  decided yet says `TBD — <what is missing> (needed before Hardening)` rather than
  being dropped.

Keep the template's five headings exactly. If `docs/ops/slo.md` exists, show the
differences and update it; never overwrite silently. Ask "May I write this to
`docs/ops/slo.md`?", then write. Record the journeys and budgets in the architecture
document's `## NFR Budgets` section (Edit, after asking).

---

## Phase 11: ADR Audit, Traceability and Required ADRs

### 11a. ADR audit

Review every existing ADR from 2c against the architecture built in Phases 3–10 and
the Technical Requirements Baseline:

- [ ] Has a `## Stack Compatibility` section, with `**Stack Components**` versions that
      match `docs/stack-reference/VERSION.md`?
- [ ] Post-cutoff APIs flagged, and none listed in a component's `deprecated-apis.md`?
- [ ] Has `## ADR Dependencies`, `## PRD Requirements Addressed` and
      `## Security & Privacy Implications`?
- [ ] Conflicts with the layer, ownership, topology or security decisions of this
      session?
- [ ] Still valid for the pinned versions?

| ADR | Status | Stack Compat | Versions | PRD Linkage | Conflicts | Valid |
|-----|--------|--------------|----------|-------------|-----------|-------|
| ADR-0001: [title] | Proposed | yes / no | yes / no | yes / no | none / [conflict] | yes / re-validate |

An ADR missing sections is fixed with `/architecture-decision retrofit <path>`.

### 11b. Traceability coverage

Map every baseline requirement to the ADRs whose `## PRD Requirements Addressed` table
or decision text covers it, or to the architecture section that settles it without a
separate decision:

| Req ID | Requirement | Covered by | Status |
|--------|-------------|------------|--------|
| TR-goals-001 | Create a savings goal | ADR-0003 | covered |
| TR-payments-003 | At most one charge per period | — | GAP |

Count: X covered, Y gaps. Each gap becomes a required ADR or an open question.

### 11c. Required ADRs

List every decision made in Phases 3–10 that has no ADR yet, plus the uncovered
requirements, grouped by layer — Foundation first. Always check the Foundation
areas: **identity & auth, primary data store, API style, deployment topology &
environments, observability, secrets management**. Foundation-layer ADRs are the
**critical** ones — mark them, because at `standard` the Validation gate requires
exactly the ADRs this document marks critical.

| # | Decision | Layer | Critical | Domain | Covers | ADR | Status |
|---|----------|-------|----------|--------|--------|-----|--------|
| 1 | Identity & auth | Foundation | yes | Auth | TR-auth-001, TR-auth-002 | — | to write |
| 2 | Primary data store | Foundation | yes | Data | TR-goals-001 | — | to write |
| 3 | Payment orchestration and idempotency | Core | no | Integrations | TR-payments-003 | — | to write |

Status is `to write`, `Proposed` or `Accepted`. A decision on a layer that is not
configured yet (the primary data store, the cloud provider) is written as an ADR
first; once it is accepted, `/setup-stack refresh` pins its components.

Present all three parts, approve, then Edit `## ADR Audit` and `## Required ADRs` in
after "May I write this to `docs/architecture/architecture.md`?".

---

## Phase 12: Principles and Open Questions

- **Architecture Principles** — three to five principles that govern every technical
  decision in this product, derived from the product principles, the PRDs and the
  tech radar. For Moa, for example: contract first; one owning module per entity; the
  server computes money and entitlements; every async step is idempotent; managed
  services before self-hosting until a measured need says otherwise.
- **Open Questions** — decisions deferred, with what they block:

  | ID | Question | Blocks | Owner | Resolution path | Needed by |
  |----|----------|--------|-------|-----------------|-----------|
  | OQ-01 | [question] | [module, ADR or journey] | [role] | [ADR / PRD update / spike] | [phase or date] |

  Every HIGH or MEDIUM Knowledge Risk component the document does not address, every
  unset budget and every unresolved stack lead finding appears here.

Present, approve, then Edit both sections in after "May I write this to
`docs/architecture/architecture.md`?".

---

## Phase 13: Document Structure and Verdict

The architecture document, as written and kept by this skill:

```markdown
# [Product Name] — Architecture

> **Verdict**: [COMPLETE | INCOMPLETE | NOT ASSESSED]
> **Status**: [Draft | In Review | Approved]
> **Version**: [N]
> **Last Updated**: [YYYY-MM-DD]
> **Stack**: [the resolved stack line, verbatim]
> **Surfaces**: [the resolved platform.surfaces line]
> **PRDs Covered**: [paths — MVP first]
> **ADRs Referenced**: [ADR ids]
> **SLO Document**: `docs/ops/slo.md`
> **Technical Director Review (TD-ARCHITECTURE)**: [APPROVED | CONCERNS (accepted) | REVISED] [YYYY-MM-DD]
> **Tech Lead Review (TL-FEASIBILITY)**: [APPROVED | CONCERNS (accepted) | REVISED] [YYYY-MM-DD]

## Stack & Knowledge Risk
[Condensed from the 2d inventory — HIGH/MEDIUM components and their implications]

## Technical Requirements Baseline
[From 2b]

## Layers & Modules
[From Phase 3]

## Deployment Topology & Environments
[From Phase 4]

## Data Flow
[From Phase 5]

## Integrations
[From Phase 6]

## Security Model
[From Phase 7]

## Observability
[From Phase 8]

## NFR Budgets
[From Phase 10 — the budgets per surface and the critical user journeys, pointing to docs/ops/slo.md]

## ADR Audit
[From 11a and 11b]

## Required ADRs
[From 11c — Foundation first, critical marked]

## Architecture Principles
[From Phase 12]

## Open Questions
[From Phase 12]
```

**Verdict** (the line directly under the H1; precedence INCOMPLETE > NOT ASSESSED >
COMPLETE):

- **COMPLETE** — every section the resolved `workflow` requires is written (not `TBD`),
  `docs/ops/slo.md` exists with its critical user journeys, and TD-ARCHITECTURE and
  TL-FEASIBILITY each returned an APPROVE-class verdict, had their concerns accepted
  or revised, or were skipped by review mode with the skip note recorded.
- **INCOMPLETE** — a required section is still `TBD`, the SLO document was not
  written, or a gate returned a REJECT-class verdict that has not been revised.
- **NOT ASSESSED** — the run stopped before anything could be assessed (no stack, no
  product record); the document is not written and the verdict appears only in the
  run summary.

Before and after the gates, update the Verdict, Version and Last Updated lines —
each update after "May I write this to `docs/architecture/architecture.md`?".

---

## Phase 14: Sign-off — TD-ARCHITECTURE and TL-FEASIBILITY

Once every section is written, run the two gates on the document.

**Review mode check** — apply before spawning TD-ARCHITECTURE and TL-FEASIBILITY
(`--review` overrides the resolved `review_mode`):
- `full` → spawn as normal.
- `lean` → **skip every gate whose ID does not end in `-PHASE-GATE`**. Note: `[GATE-ID] skipped — Lean mode`
  Neither TD-ARCHITECTURE nor TL-FEASIBILITY ends in `-PHASE-GATE`, so lean skips both:
  record `[TD-ARCHITECTURE] skipped — Lean mode` and `[TL-FEASIBILITY] skipped — Lean mode`.
- `solo` → skip all gates. Note: `[GATE-ID] skipped — Solo mode`

When they run, spawn both **in parallel** — issue both `Agent` calls before waiting
for either result. Each prompt instructs the agent to read its gate file first (do
not read it or paste it yourself):

- **TD-ARCHITECTURE** → `technical-director`, gate file `.claude/docs/director-gates/td-architecture.md`
  - Pass: `docs/architecture/architecture.md` path · `docs/ops/slo.md` path · resolved `stack` line · MVP PRD paths
  - Fill: both paths (say "absent" for `docs/ops/slo.md` if it was not written); the
    `stack` line as the bootstrap printed it; the MVP PRD paths from 2b.
- **TL-FEASIBILITY** → `tech-lead`, gate file `.claude/docs/director-gates/tl-feasibility.md`
  - Pass: `docs/architecture/architecture.md` path · resolved `stack` line · resolved `team.size`
  - Fill: the path; the `stack` line; the `team.size` line — both as the bootstrap
    printed them.

Parse the first line of each reply as `[GATE-ID]: TOKEN` — TD-ARCHITECTURE returns
`APPROVE`, `CONCERNS` or `REJECT`; TL-FEASIBILITY returns `FEASIBLE`, `CONCERNS` or
`INFEASIBLE` — and map it with the verdict classes of `.claude/docs/director-gates.md`
(`## Standard Verdict Format`):

- **APPROVE-class** (`APPROVE`, `FEASIBLE`) → proceed.
- **CONCERNS-class** (`CONCERNS`) → present the concerns via `AskUserQuestion`:
  `Revise flagged items` / `Accept and proceed` / `Discuss further`.
- **REJECT-class** (`REJECT`, `INFEASIBLE`) → present the blockers. Revise the named
  sections with the user (each write asked) and re-run that gate; until then the
  Verdict is INCOMPLETE.
- A first line that does not parse, or names another gate, is not an approval —
  treat it as CONCERNS-class and say the verdict line was missing.

The strictest class wins across the two: one REJECT-class verdict overrides an
APPROVE-class one, and one CONCERNS-class verdict caps the result at CONCERNS. Show
both assessments side by side.

**Record the outcomes** in the document header — show the lines, then ask "May I
write this to `docs/architecture/architecture.md`?":

```markdown
> **Technical Director Review (TD-ARCHITECTURE)**: APPROVED 2026-10-05
> **Tech Lead Review (TL-FEASIBILITY)**: CONCERNS (accepted) 2026-10-05
```

A gate skipped by review mode leaves its skip note on its line instead —
`> [TD-ARCHITECTURE] skipped — Lean mode` (or `— Solo mode`) — so the record shows the
mode was applied. Then set the Verdict line (Phase 13).

Then continue with Phase 17.

---

## Phase 15: `section <name>`

Revise one part of an existing architecture. `docs/architecture/architecture.md` must
exist — if it does not, say so and offer the full walkthrough instead.

| `<name>` | Runs | Writes |
|----------|------|--------|
| `layers` | Phase 3 | `## Layers & Modules` |
| `topology` | Phase 4 | `## Deployment Topology & Environments` |
| `data-flow` | Phase 5 | `## Data Flow` |
| `integrations` | Phase 6 | `## Integrations` |
| `security` | Phase 7 | `## Security Model` |
| `observability` | Phase 8 | `## Observability` |
| `nfr` | Phase 10a | `## NFR Budgets`, `project.yaml` `performance.*` |
| `slo` | Phase 10b | `docs/ops/slo.md`, `## NFR Budgets` |
| `adrs` | Phase 11 | `## ADR Audit`, `## Required ADRs` |
| `open-questions` | Phase 12 | `## Architecture Principles`, `## Open Questions` |

Load only the Phase 2 context the section needs. Show the current section and the
proposed one side by side; ask "May I write this to <path>?" before each write.
Increase the Version, set Last Updated, and re-derive the Verdict.

A change to the module map, the topology, the security model or the SLOs is a major
revision: offer to run Phase 14 again (the review-mode check applies). Then run
Phase 17.

---

## Phase 16: `tdd <feature>`

A per-feature technical design at `docs/architecture/tdd-<feature>.md`, from
`.claude/docs/templates/technical-design-document.md`. It is optional and never a gate
artifact: write one when a feature is complex enough that several surfaces need a
shared plan before stories are written.

1. **Resolve the feature.** `design/prd/<feature>.md` must exist — if not, stop and
   point at `/write-prd <feature>`. Read its `## Functional Requirements`,
   `## Business Rules & Calculations`, `## Edge Cases`, `## Dependencies`,
   `## Non-Functional Requirements`, `## Configuration & Flags` and
   `## Success Metrics & Instrumentation` sections.
2. **Load its architecture context.** The modules owning the feature in
   `docs/architecture/architecture.md`; the ADRs whose `## PRD Requirements Addressed`
   names the PRD (Grep the PRD path across `docs/architecture/adr-*.md`); the
   operations and entities in `docs/api/` and `docs/data/data-model.md`; its events in
   `design/product/tracking-plan.md`; the journeys it serves in `docs/ops/slo.md`; the
   stack reference of the components it touches (2a rules).
3. **Existing design.** If `docs/architecture/tdd-<feature>.md` exists, offer to update
   specific sections rather than rewriting it.
4. **Skeleton first.** Copy the template — its twelve headings exactly, in order — with
   the header block filled and every section `TBD`, after "May I write this to
   `docs/architecture/tdd-<feature>.md`?".
5. **Section by section.** Draft each section, show it, and Edit it in after asking.
   - `## Stack & Dependency Surface` — consult the routed stack lead(s) of the layers
     the feature touches (unset layer ⇒ the `NOT CHECKED` line); every post-cutoff API
     names its reference file; assumptions not yet proven stay in
     **Unverified Assumptions**, which keeps the design out of `Approved`.
   - `## API Contract` and `## Data Model & Migrations` reference the contract and
     the data model; a new or changed operation goes to `/api-design`, a new entity or
     column to `/data-model`.
   - A choice that binds other features belongs in an ADR — list it under
     `## Alternatives` with `/architecture-decision` as the next step.
6. **Tech lead review.** Offer a review by `tech-lead` via `Agent` (a consultation, not
   a gate): implementability, missing interfaces, test strategy, rollout safety.
   Incorporate its findings with the user.
7. The document stays `Draft` until the user moves it to `In Review` or `Approved`.

Close with `AskUserQuestion`: `/create-stories <epic-slug>` for the feature's epic,
`/api-design update <resource>`, `/data-model migration <slug>`,
`/architecture-decision "<title>"` for a decision the design surfaced, or stop.

---

## Phase 17: Summary, Verdict and Next Steps

**Step 1 — Session checkpoint.** Ask "May I write this to
`production/session-state/active.md`?" and record: the artifacts written, the gate
verdicts, the blockers, the required ADRs remaining, and the next step.

**Step 2 — Output the summary** using exactly this template (no freeform prose, no
rephrasing of section titles):

---

## Architecture — [COMPLETE | INCOMPLETE | NOT ASSESSED]

`docs/architecture/architecture.md` v[N] — TD-ARCHITECTURE: [APPROVED / CONCERNS (accepted) / REVISED / skipped — <Mode> mode]; TL-FEASIBILITY: [same]. [One sentence on what the architecture covers.]
`docs/ops/slo.md` — [N] critical user journeys, [N] SLOs, [N] paging alerts ([written | updated | not written — reason]).
Budgets: [written to project.yaml: <keys> | unchanged | unset: <keys>]
Not checked: [every NOT CHECKED line of this run, or "none"]

---

## Run These ADRs Next

**1. `/architecture-decision "[Title]"` → ADR-[NNNN]**
[Layer, critical or not. One sentence: what it defines and what it unblocks.]

**2. `/architecture-decision "[Title]"` → ADR-[NNNN]**
[One sentence.]

**3. `/architecture-decision "[Title]"` → ADR-[NNNN]**
[One sentence.]

List the top 3 from `## Required ADRs` in priority order — critical Foundation ones
first. If fewer than 3 remain, list only what's outstanding.

---

## Gate-Check Readiness

> **Required before `/gate-check validation`** (items whose condition is known false
> are omitted):
> - [ ] `/setup-stack refresh` — `stack.pinned_on` set and a `docs/stack-reference/VERSION.md` row for every configured component (required at every tier)
> - [ ] Write ADRs: [required ADR titles still to write — at `standard`, the critical ones]
> - [ ] `/api-design` — the initial API contract (when a backend, data layer or `api` surface is configured)
> - [ ] `/data-model` — the data model with classification and migration strategy (same condition)
> - [ ] `/security-audit threat-model` — required when the product handles personal data
> - [ ] `/ux-design accessibility` — commits `accessibility.target` (when a UI surface ships)
> - [ ] `/test-setup` — test runners per layer and the CI workflow
> - [ ] `/architecture-review` — in a fresh session, after the ADRs are written
> - [ ] `docs/architecture/tech-radar.md` exists (`/setup-stack` seeds it)
>
> Run `/gate-check validation` when all boxes are checked.

If nothing is blocking, write instead:
> No blockers — run `/gate-check validation` now.

---

## Open Questions to Watch

| ID | Summary | Priority | Resolution Path |
|----|---------|----------|-----------------|
| OQ-XX | [short description] | High / Medium / Low | [ADR, PRD update or spike that resolves it] |

Omit this section entirely if there are no open questions.

---

**Step 3 — Next steps.** Close with `AskUserQuestion`, offering only the steps that
apply:

- `/architecture-decision "<first required ADR>"` — Foundation-layer ADRs first
- `/api-design` — the initial contract (backend, data layer or `api` surface)
- `/data-model` — entities, classification and the migration strategy (same condition)
- `/security-audit threat-model` — trust boundaries and threats (required with personal data)
- `/ux-design accessibility` — the accessibility target (UI surfaces)
- `/test-setup` — test runners and the CI workflow
- `/architecture-review` — in a fresh session, once the required ADRs are written;
  it registers the requirement IDs and builds the traceability matrix
- `/create-control-manifest` — once the ADRs are Accepted (required at `full`)
- `/setup-stack refresh` — after an ADR that decides data or cloud components is Accepted
- `/create-architecture tdd <feature>` — a technical design for a complex feature (optional)
- `/gate-check validation` — when the readiness list is complete

---

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and
`autonomous` modes, see `.claude/docs/automation-modes.md` — the rules below
describe what collaborative mode requires, not universal behavior.

This skill follows the collaborative design principle at every phase:

1. **Load context silently** — do not narrate file reads
2. **Present findings** — show the knowledge risk inventory, the requirements
   baseline and each section proposal
3. **Ask before deciding** — present options for each architectural choice;
   never make a binding architectural decision without user input. If the user is
   unsure, present 2-4 options with pros and cons before asking them to decide
4. **Draft before approval** — show the content inline before asking to write it.
   Never ask approval for a section the user has not yet seen
5. **"May I write this to `<path>`?" before every write** — use `AskUserQuestion`
   with labeled options (write now / show the full draft first / not yet). For a
   multi-file change, list every file and what changes, then ask once for the set
6. **Incremental writing** — create the skeleton first and write each approved
   section immediately; do not accumulate everything and write at the end. This
   survives session crashes
7. **Skips announce themselves** — every consultation or gate that did not run, and
   every layer that is not configured, appears in the summary as a `NOT CHECKED` or
   skip line
8. **No commits** — committing is the user's decision
