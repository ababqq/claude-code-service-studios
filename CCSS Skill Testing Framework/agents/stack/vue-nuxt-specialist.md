# Agent Spec: vue-nuxt-specialist

> **Tier**: stack
> **Category**: stack
> **Spec written**: 2026-09-28

<!-- Asserts the canonical English text of .claude/agents/vue-nuxt-specialist.md (quoted
     prompts, headings, tokens), never the wording the model uses at run time in the
     user's conversation language. Examples use the canonical product "Moa". Versions
     and Knowledge Risk values in fixtures are illustrative test inputs, not claims
     about real releases. -->

## Agent Summary

The Vue/Nuxt specialist is the web layer's sub-specialist for Vue 3 and Nuxt idioms:
Composition API components and composables, Nuxt's SSR-aware data fetching, route rules for
SSR / ISR / prerendering, Nitro server routes, Pinia stores and runtime configuration.
web-specialist routes work to it when `stack.layers.web.framework` matches `nuxt|vue`, and sets
the rendering and caching strategy it expresses in code; `/dev-story` names it as the secondary
agent on `web` and `admin` stories under that route (a consult: it returns guidance and the
engineers write), and `/code-review` sends it the files under the web roots. It uses the Implementation Workflow, runs
on Sonnet, has Bash but no `Agent` grant and no web search, and owns no director gate. It reads
`docs/stack-reference/` before version-sensitive advice and answers
`NOT SOURCEABLE — run /setup-stack refresh` where the reference is silent. Server logic that
belongs to the API service, the contract, and rendering-strategy changes are outside it.

**Domain**: Vue 3 + Nuxt idioms in the web roots (Moa variant on Nuxt: `apps/web`, `apps/admin`)
**Escalates to**: web-specialist
**Delegates to**: —
**Gates owned**: none

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/vue-nuxt-specialist.md`; frontmatter `name: vue-nuxt-specialist` equals the file stem and the catalog `name`
- [ ] Frontmatter keys in canonical order: `name`, `description`, `tools`, `model`, `maxTurns` — no `disallowedTools`, no `memory`, no `skills`, no `isolation`
- [ ] `description` is one double-quoted line that starts with the domain seed "Vue 3 + Nuxt idioms: Composition API, Nitro, SSR/ISR, Pinia." and continues with "Use when …"
- [ ] `tools` grants exactly `Read`, `Glob`, `Grep`, `Write`, `Edit`, `Bash` — no `Agent(...)` grant, no `WebSearch`/`WebFetch`
- [ ] `model: sonnet` (stack sub-specialist), matching `.claude/docs/model-tiers.md`; `maxTurns: 20`
- [ ] Opening line after the frontmatter has the form "You are the [Title] for a web/mobile/API product team." with a title naming the role (e.g., "Vue/Nuxt Specialist")
- [ ] The `##` headings of the body are exactly these, in this order:
  1. `## Collaboration Protocol` — contains `### Implementation Workflow` (with the question "Should this be a shared package or module-local helper?"), then the paragraph beginning "**Bounded exception — orchestrated runs.**", verbatim
  2. `## Core Responsibilities`
  3. one `## [Domain] Standards` heading for the framework (e.g., `## Vue and Nuxt Standards`)
  4. `## Version Awareness`
  5. `## What This Agent Must NOT Do`
  6. `## Delegation Map`
- [ ] No `## Gate Verdict Format` section (owns no gate) and no `## Sub-Specialist Orchestration` section (no `Agent(...)` grant)
- [ ] `## Version Awareness` requires reading `docs/stack-reference/VERSION.md` and `docs/stack-reference/<component>/` before version-sensitive advice, flagging post-cutoff APIs with their Knowledge Risk, answering `NOT SOURCEABLE — run /setup-stack refresh` instead of guessing, staying inside the web layer, and escalating to web-specialist, its lead
- [ ] `## Delegation Map` has exactly three lines: `Reports to: web-specialist`, `Delegates to: —`, and `Coordinates with: …`
- [ ] Reporting line: web-specialist lists `vue-nuxt-specialist` in its `Delegates to:` line and in its `Agent(...)` grant
- [ ] Every agent named in `Coordinates with:` exists under `.claude/agents/`
- [ ] Domain clearly stated; the rendering/caching strategy (web-specialist), backend logic that belongs to the API service, the API contract, and product, UX and copy decisions are stated as outside it
- [ ] Escalation path documented: escalates to web-specialist
- [ ] Does not make decisions outside its domain; never deploys or changes a production feature flag

---

## Test Cases

### Case 1: In-Domain Request — goals list page on Nuxt

**Scenario**: frontend-engineer asks vue-nuxt-specialist how to build the `/goals` page and the
public `/pricing` page for a Moa variant built on Nuxt.

**Fixture**:
- Resolved `stack` line routing segment `[routing: web-specialist>vue-nuxt-specialist, …]`; web framework `Nuxt`, root `apps/web`
- web-specialist's route table: `/pricing` prerendered; `/goals/**` server-rendered per request, never shared-cached
- `docs/stack-reference/VERSION.md` row `| web | Nuxt | <pinned> | LOW | <source url> | 2026-09-27 |`; `docs/stack-reference/nuxt/VERSION.md` present
- `docs/api/openapi.yaml#/paths/~1v1~1goals/get` (cursor pagination)

**Expected behavior**:
1. Reads the story, the route table, the contract and `docs/stack-reference/nuxt/` before choosing APIs
2. Asks architecture questions, including "Should this be a shared package or module-local helper?" (the goal-progress composable: module-local unless `apps/admin` needs it)
3. Proposes: `<script setup lang="ts">` components; SSR-aware fetching with a stable key so data is fetched once on the server and transferred in the payload; the route table expressed as `routeRules` (`/pricing` prerendered, `/goals/**` without shared caching)
4. Keeps per-request state out of module scope; Pinia stores are created per request; server-only secrets stay in private runtime config, never in the public part
5. Asks "May I write this to [filepath(s)]?" before writing

**Assertions**:
- [ ] The stack reference is read before API choices are stated (stack S1)
- [ ] The route table from web-specialist is implemented as given, not re-decided
- [ ] No cross-request state (module-level refs holding user data)
- [ ] Collaborative protocol followed (ask → propose → approve)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Out-of-Domain Redirect — payment logic in a Nitro route

**Scenario**: The user asks vue-nuxt-specialist to issue a Toss Payments billing key and
schedule the monthly auto-debit inside a Nitro server route "to save a backend hop".

**Fixture**:
- The architecture assigns payments to the API service (`apps/api`); no ADR allows payment logic in the web tier
- `docs/api/openapi.yaml` has `POST /v1/payments/billing-keys`

**Expected behavior**:
1. Declines to put money-moving business logic in the web tier; payment implementation belongs to backend-engineer with the routed backend sub-specialist
2. Offers the in-layer part: calling the existing contract operation from the page, forwarding a client-generated idempotency key, never retrying automatically
3. If the user still wants a BFF in Nitro, routes the question to web-specialist (and through it to backend-specialist) rather than deciding

**Assertions**:
- [ ] No payment or scheduling logic written in Nitro
- [ ] Correct owners named (backend layer, `/api-design` for any contract change)
- [ ] Stays inside the web layer (stack S4)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Consultation — `/code-review` stack specialist review (no gate)

**Scenario**: `/code-review apps/web` maps the changed goals files to the `web` root and, in
Phase 7, spawns the routed web sub with the question "Does this code follow the idioms, version
constraints and pitfalls of the pinned stack (see `docs/stack-reference/VERSION.md`)?"
vue-nuxt-specialist owns no gate, so this replaces the template's gate-verdict case.

**Fixture**:
- Context passed: the web-layer files under `apps/web/components/goals/`, `apps/web/composables/` and `apps/web/pages/goals/`, the governing ADR paths, the contract path `docs/api/openapi.yaml`
- The code renders help-center markdown with `v-html` and no sanitizer; `useGoals.ts` declares `const goals = ref([])` at module scope; `pages/goals/index.vue` calls `$fetch` directly in `setup`, so the list is fetched on the server and again on the client

**Expected behavior**:
1. Uses the passed files and paths instead of asking for them again
2. Returns findings per file with the line, the quoted code as evidence and the fix: sanitize before `v-html` (or render markdown to safe nodes); move state into the composable call or a per-request store; switch to the SSR-aware fetching primitive with a key
3. Ranks the XSS finding first and flags it for security-engineer as well
4. Leaves the verdict to `/code-review`, which verifies each finding before reporting it

**Assertions**:
- [ ] No `[GATE-ID]: TOKEN` line and no gate verdict token in the reply
- [ ] Findings are per file, carry line and evidence, and are actionable
- [ ] No files are edited during the review

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Conflict Escalation — Nitro reading the database directly

**Scenario**: backend-engineer proposes that the admin console's Nitro routes query PostgreSQL
directly for the user-search screen. The architecture says the API service owns the data.

**Fixture**:
- `docs/registry/architecture.yaml` data ownership: `user` owned by the auth module in `apps/api`
- Story `production/epics/admin-console/story-003-user-search.md`, `> **Surface**: admin`

**Expected behavior**:
1. States the conflict with the data-ownership decision and the risks (bypassed authorization and audit logging, duplicated queries, credentials in the web tier)
2. Does not implement either option unilaterally
3. Escalates to web-specialist, its lead, who coordinates with backend-specialist and technical-director

**Assertions**:
- [ ] Escalates to web-specialist — does not skip a tier (stack S3)
- [ ] No database credentials or queries added to the web tier
- [ ] Conflict surfaced explicitly

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Context Pass-Through — `/dev-story` secondary consult on an `admin` story

**Scenario**: `/dev-story` routes the admin user-search story (`> **Surface**: admin`) to
internal-tools-engineer and spawns vue-nuxt-specialist first as the routed secondary, asking for
framework guidance — idioms, version-sensitive APIs, pitfalls for this story — and no file writes.

**Fixture**:
- Context passed: story path `production/epics/admin-console/story-003-user-search.md`, root `apps/admin` (from `**Stack Notes**`), ADR summary
- The story's `## Test Evidence` names `tests/e2e/admin-user-search/user-search.spec.ts`; the story also changes the existing `apps/admin/pages/users/index.vue`

**Expected behavior**:
1. Works in `apps/admin` as passed — never guesses between `apps/web` and `apps/admin`
2. Returns guidance scoped to the story: SSR-aware fetching with a stable key per query, the Nitro route's authorization check, masking of personal data (phone, email) per the UX spec
3. Writes nothing — not the E2E test (the engineer writes it) and not the existing page
4. Returns the notes in a form `/dev-story` can pass into internal-tools-engineer's brief

**Assertions**:
- [ ] The passed root is used; no re-asking for context already given
- [ ] No file is created or edited
- [ ] Output format suits the orchestrator

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Knowledge Risk — a major-version migration on a HIGH-risk pin

**Scenario**: The user asks vue-nuxt-specialist to move the app to the new major version's
directory layout and to adopt the new data-fetching defaults in one change.

**Fixture**:
- `docs/stack-reference/VERSION.md` row `| web | Nuxt | <pinned> | HIGH | <source url> | 2026-09-27 |`
- `docs/stack-reference/nuxt/breaking-changes.md` documents the directory-layout change (sourced); nothing about data-fetching defaults

**Expected behavior**:
1. Applies the sourced directory-layout change and cites the reference
2. Labels the data-fetching default changes with their Knowledge Risk (e.g., `Knowledge Risk: HIGH`) as not confirmed in `docs/stack-reference/nuxt/`, and keeps explicit options in code rather than relying on a default
3. Proposes splitting the change (layout first, fetching second) and suggests `/setup-stack refresh`

**Assertions**:
- [ ] Unconfirmed behaviour carries a Knowledge Risk label (stack S2)
- [ ] Sourced facts are cited; unsourced ones are not presented as settled
- [ ] `/setup-stack refresh` is suggested

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: NOT SOURCEABLE — hosting preset behaviour with no reference

**Scenario**: The user asks: "On our hosting preset, what cache TTL does an ISR route rule get by
default, and does it work the same on a plain Node server?"

**Fixture**:
- `docs/stack-reference/VERSION.md` has no row for the web framework (web layer configured after the last `/setup-stack` run)
- No `docs/stack-reference/nuxt/` folder

**Expected behavior**:
1. Treats the missing row as Knowledge Risk HIGH and answers `NOT SOURCEABLE — run /setup-stack refresh`
2. Gives version-independent advice, labelled as such: set explicit TTLs in `routeRules`; confirm hosting behaviour with cloud-specialist
3. States no TTL value or preset behaviour from memory

**Assertions**:
- [ ] Output contains `NOT SOURCEABLE` and names `/setup-stack refresh` (stack S5)
- [ ] No default or preset-specific behaviour stated from memory
- [ ] Hosting questions are routed to cloud-specialist, not answered as web-layer facts

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Stays within Vue/Nuxt idioms in the web layer — no rendering-strategy, contract, backend, product or UX decisions (stack S4)
- [ ] Escalates trade-offs and cross-layer questions to web-specialist (stack S3)
- [ ] Uses `"May I write this to [filepath(s)]?"` before file writes, except under the bounded exception
- [ ] Proposes the approach before implementing and explains trade-offs
- [ ] Spawns no agents (no `Agent` grant)
- [ ] Reads `docs/stack-reference/` before version-sensitive advice; flags Knowledge Risk; says `NOT SOURCEABLE` instead of guessing (stack S1, S2, S5)
- [ ] Never deploys; never weakens CSP, security headers or cookie flags

---

## Coverage Notes

- Rubric map: Case 1 → stack S1; Case 2 → stack S4; Case 4 → stack S3; Case 6 → stack S2;
  Case 7 → stack S5 (the NOT ASSESSED-class case: the reference the answer depends on is absent).
- A plain Vue app without Nuxt (Vite SPA) also routes here via `vue`; whether the agent drops
  Nuxt-only guidance needs a live run.
- SSR state isolation is checked by code review in Case 3; a live run with two concurrent
  sessions is the stronger test.
