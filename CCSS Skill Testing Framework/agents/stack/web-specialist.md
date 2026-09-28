# Agent Spec: web-specialist

> **Tier**: stack
> **Category**: stack
> **Spec written**: 2026-09-28

<!-- Asserts the canonical English text of .claude/agents/web-specialist.md (quoted prompts,
     headings, tokens), never the wording the model uses at run time in the user's
     conversation language. Examples use the canonical product "Moa". Versions and
     Knowledge Risk values in fixtures are illustrative test inputs, not claims about
     real releases. -->

## Agent Summary

The web specialist leads the web layer of the stack: which web framework the product uses,
how each route renders (SSG / ISR / SSR / CSR / React Server Components or the framework's
equivalent), routing and locale URLs, the data-fetching and caching model, build tooling and
environment discipline, and browser security headers. It drafts options for web ADRs, reviews
web-layer stack compatibility, and takes HIGH-risk `web` and `admin` stories itself. Framework
idiom work goes to exactly two sub-specialists through its `Agent(...)` grant —
nextjs-specialist and vue-nuxt-specialist — selected by the derived routing of
`stack.layers.web.framework`, never by preference. It uses the Implementation Workflow, runs
at the `inherit` model tier, has Bash but no web search, and owns no director gate. Before any
version-sensitive advice it reads `docs/stack-reference/`; what the reference does not cover
it answers with `NOT SOURCEABLE — run /setup-stack refresh`. Hosting and CDN provisioning,
the API contract and product/UX decisions sit outside it.

**Domain**: web framework choice, per-route rendering strategy, routing, data fetching & caching, build tooling, security headers for the `web` layer roots (Moa: `apps/web`, `apps/admin`)
**Escalates to**: technical-director
**Delegates to**: nextjs-specialist, vue-nuxt-specialist
**Gates owned**: none

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/web-specialist.md`; frontmatter `name: web-specialist` equals the file stem and the catalog `name`
- [ ] Frontmatter keys in canonical order: `name`, `description`, `tools`, `model`, `maxTurns` — no `disallowedTools`, no `memory`, no `skills`, no `isolation`
- [ ] `description` is one double-quoted line that starts with the domain seed "Web layer lead: framework choice, rendering (SSR/SSG/CSR/RSC), routing, data fetching & caching, build tooling, security headers." and continues with "Use when …"
- [ ] `tools` grants exactly `Read`, `Glob`, `Grep`, `Write`, `Edit`, `Bash` plus `Agent(nextjs-specialist, vue-nuxt-specialist)` — no `WebSearch`/`WebFetch`, and the `Agent(...)` grant names exactly these two members
- [ ] `model: inherit` (stack layer lead), matching `.claude/docs/model-tiers.md`; `maxTurns: 20`
- [ ] Opening line after the frontmatter has the form "You are the [Title] for a web/mobile/API product team." with a title naming the role (e.g., "Web Specialist")
- [ ] The `##` headings of the body are exactly these, in this order:
  1. `## Collaboration Protocol` — contains `### Implementation Workflow` (with the question "Should this be a shared package or module-local helper?"), then the paragraph beginning "**Bounded exception — orchestrated runs.**", verbatim
  2. `## Core Responsibilities`
  3. one `## [Domain] Standards` heading for the web layer (e.g., `## Web Standards`)
  4. `## Sub-Specialist Orchestration`
  5. `## Version Awareness`
  6. `## What This Agent Must NOT Do`
  7. `## Delegation Map`
- [ ] No `## Gate Verdict Format` section — web-specialist owns no director gate
- [ ] `## Sub-Specialist Orchestration` restates the grant `Agent(nextjs-specialist, vue-nuxt-specialist)` and the routing of `stack.layers.web.framework`, case-insensitive, rules in order, first match wins:
  1. `next|react` → nextjs-specialist
  2. `nuxt|vue` → vue-nuxt-specialist
  3. anything else → no sub-specialist (web-specialist does the work and says so)
- [ ] `## Sub-Specialist Orchestration` names the override key `specialists.web`, says the route is read from the resolved `stack` line (not chosen by preference), and prints `NOT CHECKED — web layer not configured (run /setup-stack)` when the web layer is unset
- [ ] `## Sub-Specialist Orchestration` covers a session without the `Agent` tool: the sub is never skipped silently — the agent applies the sub's standards itself or returns a `<sub>: <task>` hand-off, and states `NOT CONSULTED — <sub> (nested spawn unavailable)`
- [ ] `## Version Awareness` requires reading `docs/stack-reference/VERSION.md` and `docs/stack-reference/<component>/` before version-sensitive advice, flagging post-cutoff APIs with their Knowledge Risk, answering `NOT SOURCEABLE — run /setup-stack refresh` instead of guessing, staying inside the web layer, and delegating only through the `Agent(...)` grant (its subs escalate to it)
- [ ] `## Delegation Map` has exactly three lines: `Reports to: technical-director`, `Delegates to: nextjs-specialist, vue-nuxt-specialist`, and `Coordinates with: …`
- [ ] Reporting line: technical-director lists `web-specialist` in its own `Delegates to:` line; nextjs-specialist and vue-nuxt-specialist each name `web-specialist` in their `Reports to:` line
- [ ] Every agent named in `Agent(...)`, `Delegates to:` or `Coordinates with:` exists under `.claude/agents/`
- [ ] Domain clearly stated; product and UX decisions (product-manager, product-designer), the API contract (`/api-design`), hosting, DNS and CDN provisioning (cloud-specialist, devops-engineer) are stated as outside it
- [ ] Escalation path documented: escalates to technical-director
- [ ] Does not make decisions outside its domain; never deploys to production or changes a production feature flag

---

## Test Cases

### Case 1: In-Domain Request — per-route rendering and caching for Moa

**Scenario**: The user asks web-specialist to decide how Moa's web routes render and cache:
marketing home, `/pricing`, help-center articles, the signed-in `/goals` dashboard and
`/goals/:goalId`.

**Fixture**:
- `design/prd/goals.md` Approved; `docs/architecture/architecture.md` draft without a route table
- Resolved `stack` line: `stack: web=Next.js 15.3 (language=TypeScript) @apps/web,apps/admin; backend=NestJS 11.0 (language=TypeScript, runtime=Node.js 22) @apps/api,services/worker; data=PostgreSQL 16 (cache=Redis 7, queue=none, orm=Prisma 6); unset=mobile,cloud [routing: web-specialist>nextjs-specialist, backend-specialist>node-specialist, data-specialist] (project.yaml)`
- `docs/stack-reference/VERSION.md` row `| web | Next.js | 15.3 | LOW | <source url> | 2026-09-27 |`; `docs/stack-reference/nextjs/VERSION.md` present
- `project.yaml`: `performance.lcp_ms: 2500`, `performance.bundle_kb` unset

**Expected behavior**:
1. Reads `docs/stack-reference/VERSION.md` and `docs/stack-reference/nextjs/` before stating any framework default, and names what it read
2. Proposes a route table, not a project-wide default: marketing, pricing and help-center pages static or incrementally regenerated; `/goals` and `/goals/:goalId` rendered on the server per request with client interactivity only at the leaves
3. States that every session-reading route sends `private, no-store` (or the framework equivalent) and is never cached at a shared cache or CDN — a cached savings balance served to another user is a privacy breach
4. Notes that `performance.bundle_kb` is unset and does not invent a budget
5. Asks "Does this match your expectations? Any changes before I write the code?" and, before writing, "May I write this to [filepath(s)]?" (e.g., the route-table section of `docs/architecture/architecture.md`)

**Assertions**:
- [ ] The stack reference is read before any version-sensitive statement (stack S1)
- [ ] Rendering is decided per route with a stated reason for each
- [ ] Personalized routes are never placed in a shared cache
- [ ] An unset budget is reported as unset, not filled with a number
- [ ] Collaborative protocol followed (ask → propose → approve)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Out-of-Domain Redirect — CDN provisioning and a contract field

**Scenario**: A frontend engineer asks web-specialist to add a CloudFront cache behaviour and
a WAF rule in `infra/`, and to add a `progressPercent` field to `GET /v1/goals` in
`docs/api/openapi.yaml` "because the dashboard needs it".

**Fixture**:
- `infra/` Terraform present; `docs/api/openapi.yaml` current
- The web layer's CSP and cache-header requirements are documented in the architecture

**Expected behavior**:
1. Declines to edit `infra/`: hosting, CDN and WAF provisioning belong to cloud-specialist (design and review) and devops-engineer (pipelines and rollout)
2. Declines to edit the contract: API changes go through `/api-design`, owned with tech-lead and the backend layer
3. Contributes what is inside its layer — the cache keys and headers the web routes need, and whether a BFF or aggregation endpoint would avoid N client calls — as input to those owners

**Assertions**:
- [ ] No edit to `infra/` or `docs/api/openapi.yaml`
- [ ] cloud-specialist (or devops-engineer) and `/api-design` are named as the owners
- [ ] The web-layer requirement is still stated, not dropped (stack S4)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Consultation — `/architecture-decision` web ADR input (no gate)

**Scenario**: `/architecture-decision` (Step 5.2, Stack Specialist Validation) spawns
web-specialist as the routed stack lead for the drafted
`docs/architecture/adr-0005-web-rendering-and-caching.md` (Domain `Frontend`, Status `Proposed`).
web-specialist owns no gate, so this replaces the template's gate-verdict case.

**Fixture**:
- Context passed: the draft's `## Stack Compatibility`, Decision and Key Interfaces sections · the `docs/stack-reference/` paths the skill read in Step 1 (`VERSION.md`, `nextjs/`)
- The Decision caches the `/pricing` page with a caching API that `docs/stack-reference/nextjs/deprecated-apis.md` lists as deprecated in the pinned version (sourced)
- `docs/architecture/tech-radar.md` lists Next.js under `## Adopt`

**Expected behavior**:
1. Uses the passed sections and paths instead of asking for them again
2. Answers the skill's three questions: whether the approach is idiomatic for the pinned version; which APIs or patterns are deprecated or changed after the knowledge cutoff (citing `docs/stack-reference/nextjs/`); which stack-specific risks the draft does not capture
3. Marks the deprecated caching API as a blocking issue (wrong or deprecated API) with the sourced replacement, and keeps minor notes separate so the skill can put them in the ADR's `## Risks` table
4. Returns its findings to the skill; the skill revises and writes the ADR. Leaves `## Status` alone — only technical-director (with the user) accepts an ADR

**Assertions**:
- [ ] No `[GATE-ID]: TOKEN` line and no gate verdict token (APPROVE / REJECT / READY …) in the reply
- [ ] Blocking issues and minor notes are distinguished; each version claim cites `docs/stack-reference/` or carries its Knowledge Risk
- [ ] The ADR's `## Status` is not changed and the ADR file is not written by the agent
- [ ] Output is scoped to the web layer and suitable for the parent skill

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Sub-Specialist Orchestration — HIGH-risk story and derived routing

**Scenario**: `/dev-story` spawns web-specialist (instead of the sub) for
`production/epics/goals-core/story-004-goal-detail-page.md` because its `**Risk**` is HIGH.

**Fixture**:
- Story: `> **Type**: UI`, `> **Surface**: web`, `**Risk**: HIGH`, `**Stack Notes**: root apps/web`
- `docs/stack-reference/VERSION.md` row `| web | Next.js | 15.3 | HIGH | <source url> | 2026-09-27 |`
- Resolved `stack` line routing segment `[routing: web-specialist>nextjs-specialist, …]`
- Variants: (a) `specialists.web: web-specialist`; (b) `stack.layers.web.framework: SvelteKit` (route `web-specialist`, no sub); (c) no `stack.layers.web` block (web layer unset)

**Expected behavior**:
1. Base fixture: decides the rendering and caching approach itself, then delegates the framework-idiom guidance to nextjs-specialist through the `Agent` tool; the prompt carries the story path, the root `apps/web`, the contract operations, the relevant ADR decision, its rendering/caching decision, the performance budget and the Knowledge Risk of the web framework row
2. Reviews the sub's result against its web standards before presenting it
3. Returns guidance only and writes no files — in `/dev-story` stack specialists consult and the engineers write, and the prompt names no path
4. Variant (a): spawns no sub and says it handles the idiom work itself because the override names the lead
5. Variant (b): spawns no sub and says the framework matches no routing rule
6. Variant (c): spawns nobody and prints `NOT CHECKED — web layer not configured (run /setup-stack)`
7. Variant (d), the `Agent` tool is not available in the session: applies nextjs-specialist's standards itself or returns the hand-off `nextjs-specialist: <task>`, and states `NOT CONSULTED — nextjs-specialist (nested spawn unavailable)` so `/dev-story` can spawn the sub or carry the line into its summary

**Assertions**:
- [ ] Only members of `Agent(nextjs-specialist, vue-nuxt-specialist)` are spawned — never frontend-engineer, backend agents or any other agent (stack S3)
- [ ] The sub spawned equals the resolved route; the override `specialists.web` wins over the derived rule
- [ ] Variant (c) prints the `NOT CHECKED` line exactly and spawns nobody
- [ ] Variant (d) never skips the sub silently: the `NOT CONSULTED — nextjs-specialist (nested spawn unavailable)` line is present
- [ ] No file is written by the lead or the sub
- [ ] A sub's output is reviewed before it reaches the user

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Knowledge Risk — build tooling switch on a HIGH-risk pin

**Scenario**: The user asks web-specialist to switch Moa's production builds to the
framework's newer bundler and enable its React compiler integration "because the release
blog says it is stable now".

**Fixture**:
- `docs/stack-reference/VERSION.md` row `| web | Next.js | 15.3 | HIGH | <source url> | 2026-09-27 |`
- `docs/stack-reference/nextjs/breaking-changes.md` covers the fetch-caching default change (sourced) but says nothing about production bundler support or the compiler option
- `apps/web/package.json` and the lockfile present

**Expected behavior**:
1. Reads `docs/stack-reference/nextjs/` and reports what it does and does not confirm
2. Labels each unconfirmed config key or flag with its Knowledge Risk (e.g., `Knowledge Risk: HIGH`) and names `docs/stack-reference/nextjs/` as the reference that lacks it
3. Does not present the switch as settled; proposes a measured trial on a preview deploy with the bundle and build-time numbers as evidence, and suggests `/setup-stack refresh` to source the missing facts
4. May read the installed version from `package.json` or the lockfile and reports any drift from the pin instead of silently choosing one

**Assertions**:
- [ ] Every API or config key not confirmed by the reference carries a Knowledge Risk label (stack S2)
- [ ] No release date, default or "stable since" claim is stated from memory
- [ ] `/setup-stack refresh` is suggested for the missing facts

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: NOT SOURCEABLE — empty stack reference

**Scenario**: The user asks: "Which security headers does our framework set by default now,
and what is the minimum Node.js version for our pinned release?"

**Fixture**:
- `docs/stack-reference/VERSION.md` is the shipped skeleton: `**Stack Pinned**` `NOT DETERMINED`, Pinned Components row `| — | NOT DETERMINED | — | — | — | — |`
- No `docs/stack-reference/nextjs/` folder

**Expected behavior**:
1. Treats the missing web row as Knowledge Risk HIGH
2. Answers `NOT SOURCEABLE — run /setup-stack refresh` for both version-specific questions
3. Gives version-independent guidance separately and labels it as such: the app sets its own CSP, HSTS, `X-Content-Type-Options`, `Referrer-Policy`, `Permissions-Policy` and framing policy explicitly rather than relying on framework defaults

**Assertions**:
- [ ] Output contains `NOT SOURCEABLE` and names `/setup-stack refresh` (stack S5)
- [ ] No version number or framework default is stated from memory
- [ ] Version-independent advice is clearly separated from the unanswered questions

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: Conflict Escalation — deep-link paths across web and mobile

**Scenario**: mobile-specialist wants short Universal Link / App Link paths (`/g/:id`) for
push notifications; Moa's web routes and the analytics plan use `/goals/:goalId`, and
`apple-app-site-association` / `assetlinks.json` are served from the web origin.

**Fixture**:
- Web route table in `docs/architecture/architecture.md` uses `/goals/:goalId`
- mobile-specialist's proposal for `/g/:id`; no ADR on URL structure yet

**Expected behavior**:
1. States the conflict and the cost of each option (URL parity, analytics, SEO of shared links, link-verification files)
2. Does not edit the link-verification files or the route table to its own preference
3. Escalates to technical-director, the shared parent of both layer leads, with the options

**Assertions**:
- [ ] Conflict surfaced explicitly with both positions
- [ ] Escalates to technical-director
- [ ] No unilateral cross-layer change

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 8: Context Pass-Through — `/team-hardening` web review

**Scenario**: `/team-hardening` (`team.size: studio`) spawns web-specialist as the stack lead of
the configured web layer and asks for its layer checks — caching and CDN headers,
server-rendering error handling and error boundaries, public source maps, image and font
configuration — for the skill's single report.

**Fixture**:
- Context passed (distilled inline): a response-header dump of `apps/web` showing `/goals` served with `Cache-Control: public, s-maxage=60`; `.js.map` files reachable on the production origin; a full (unsubsetted) Korean webfont on every page; `performance.cls: 0.1`
- The prompt ends with the skill's return contract: "Do not write any file — this pipeline has one report, and the orchestrator writes it; …" and asks for the section body in the skill's format (`**Status**:` line, `**By**:` line, findings table with Class Blocker / Condition / Note, Evidence and Owner)

**Expected behavior**:
1. Uses the passed dump and values instead of re-asking or re-measuring first
2. Returns the section body in the requested format, tagged with the web layer: the shared-cached personalized `/goals` route as a Blocker (one user's balance served to another), public source maps and the unsubsetted CJK font as Conditions, each with its evidence, proposed fix and owner
3. Writes no file and edits no source or config — the return contract forbids files, and the header and cache fixes are proposals
4. Returns only the section body, the ≤5-bullet summary and the BLOCKED/CONCERNS lines the contract asks for

**Assertions**:
- [ ] Provided context is used; the result is scoped to the web layer's hardening checks
- [ ] The `**Status**:` token is one of `OK`, `CONDITIONS`, `BLOCKERS`, `NOT ASSESSED — <reason>`, `N/A — <reason>`, and the table uses the classes Blocker / Condition / Note
- [ ] Nothing is written or edited
- [ ] Output format is suitable for the parent skill (section body, not a free-form essay)

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Stays within the web layer — no hosting, CDN, API-contract, product or UX decisions (stack S4)
- [ ] Escalates cross-layer and architecture conflicts to technical-director
- [ ] Uses `"May I write this to [filepath(s)]?"` before file writes, except under the bounded exception
- [ ] Proposes the approach and trade-offs before implementing
- [ ] Delegates only through `Agent(nextjs-specialist, vue-nuxt-specialist)` and only to the routed sub; does not skip tiers (stack S3)
- [ ] Reads `docs/stack-reference/` before version-sensitive advice; flags Knowledge Risk; says `NOT SOURCEABLE` instead of guessing (stack S1, S2, S5)
- [ ] Never deploys, never changes a production feature flag such as `goals.v2-progress-ring`

---

## Coverage Notes

- Rubric map: Case 1 → stack S1; Case 2 → stack S4; Case 4 → stack S3; Case 5 → stack S2;
  Case 6 → stack S5 (the NOT ASSESSED-class case: the input the answer depends on is absent).
- The routing function itself (`[routing: …]` in the `stack` line) is exercised by the
  yaml-helper fixtures; this spec checks that the agent follows the resolved route.
- Parallel spawning of both subs (two web roots on different frameworks) cannot be expressed
  by one `framework` value; the agent handles the second root itself — verify in a live run.
- The studio-only paths where web-specialist stands in for an unrouted sub (`/code-review`,
  `/team-ui`, `/team-feature`) and the consumer-side adversarial review of `API` ADRs in
  `/architecture-decision` are not separate cases; Case 4 variants (a)/(b) cover the
  no-sub routing they share.
- Security-header advice is checked for shape (explicit headers, report-only rollout), not for
  exact header values, which depend on the product's origins.
