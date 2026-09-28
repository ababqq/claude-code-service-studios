# Agent Spec: nextjs-specialist

> **Tier**: stack
> **Category**: stack
> **Spec written**: 2026-09-28

<!-- Asserts the canonical English text of .claude/agents/nextjs-specialist.md (quoted
     prompts, headings, tokens), never the wording the model uses at run time in the
     user's conversation language. Examples use the canonical product "Moa". Versions
     and Knowledge Risk values in fixtures are illustrative test inputs, not claims
     about real releases. -->

## Agent Summary

The Next.js specialist is the web layer's sub-specialist for React, Next.js and TypeScript
idioms: App Router structure, the server/client component boundary, data fetching, caching and
revalidation, server actions, route handlers and middleware. web-specialist routes work to it
when `stack.layers.web.framework` matches `next|react`, and sets the rendering and caching
strategy it implements; `/dev-story` names it as the secondary agent on `web` and `admin`
stories under that route (a consult: it returns guidance and the engineers write), and
`/code-review` sends it the files under the web roots. It uses the Implementation Workflow, runs on Sonnet, has Bash but
no `Agent` grant and no web search, and owns no director gate. It reads `docs/stack-reference/`
before any version-sensitive statement and answers `NOT SOURCEABLE — run /setup-stack refresh`
where the reference is silent. Rendering-strategy changes, other frameworks and cross-layer
questions escalate to web-specialist.

**Domain**: React + Next.js + TypeScript idioms in the web roots (Moa: `apps/web`, `apps/admin`, shared UI and API clients in `packages/`)
**Escalates to**: web-specialist
**Delegates to**: —
**Gates owned**: none

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/nextjs-specialist.md`; frontmatter `name: nextjs-specialist` equals the file stem and the catalog `name`
- [ ] Frontmatter keys in canonical order: `name`, `description`, `tools`, `model`, `maxTurns` — no `disallowedTools`, no `memory`, no `skills`, no `isolation`
- [ ] `description` is one double-quoted line that starts with the domain seed "React + Next.js + TypeScript idioms: App Router, RSC, server actions, caching, middleware." and continues with "Use when …"
- [ ] `tools` grants exactly `Read`, `Glob`, `Grep`, `Write`, `Edit`, `Bash` — no `Agent(...)` grant, no `WebSearch`/`WebFetch`
- [ ] `model: sonnet` (stack sub-specialist), matching `.claude/docs/model-tiers.md`; `maxTurns: 20`
- [ ] Opening line after the frontmatter has the form "You are the [Title] for a web/mobile/API product team." with a title naming the role (e.g., "Next.js Specialist")
- [ ] The `##` headings of the body are exactly these, in this order:
  1. `## Collaboration Protocol` — contains `### Implementation Workflow` (with the question "Should this be a shared package or module-local helper?"), then the paragraph beginning "**Bounded exception — orchestrated runs.**", verbatim
  2. `## Core Responsibilities`
  3. one `## [Domain] Standards` heading for the framework (e.g., `## Next.js Standards`)
  4. `## Version Awareness`
  5. `## What This Agent Must NOT Do`
  6. `## Delegation Map`
- [ ] No `## Gate Verdict Format` section (owns no gate) and no `## Sub-Specialist Orchestration` section (no `Agent(...)` grant)
- [ ] `## Version Awareness` requires reading `docs/stack-reference/VERSION.md` and `docs/stack-reference/<component>/` before version-sensitive advice, flagging post-cutoff APIs with their Knowledge Risk, answering `NOT SOURCEABLE — run /setup-stack refresh` instead of guessing, staying inside the web layer, and escalating to web-specialist, its lead
- [ ] `## Delegation Map` has exactly three lines: `Reports to: web-specialist`, `Delegates to: —`, and `Coordinates with: …`
- [ ] Reporting line: web-specialist lists `nextjs-specialist` in its `Delegates to:` line and in its `Agent(...)` grant
- [ ] Every agent named in `Coordinates with:` exists under `.claude/agents/`
- [ ] Domain clearly stated; the rendering/caching strategy (web-specialist), the API contract and backend endpoints, and product, UX and copy decisions are stated as outside it
- [ ] Escalation path documented: escalates to web-specialist
- [ ] Does not make decisions outside its domain; never deploys or changes a production feature flag

---

## Test Cases

### Case 1: In-Domain Request — "create goal" form with a server action

**Scenario**: frontend-engineer asks nextjs-specialist how to implement the create-goal form in
`apps/web` for `production/epics/goals-core/story-002-create-goal-form.md`.

**Fixture**:
- Story: `> **Type**: UI`, `> **Surface**: web`, `**Risk**: LOW`, `**API Contract**: docs/api/openapi.yaml#/paths/~1v1~1goals/post`, `**Feature Flag**: None`
- web-specialist's route table: `/goals/new` rendered per request, no shared caching
- `docs/stack-reference/VERSION.md` row `| web | Next.js | 15.3 | LOW | <source url> | 2026-09-27 |`; `docs/stack-reference/nextjs/VERSION.md` present
- API client types generated from the contract into `packages/`

**Expected behavior**:
1. Reads the story, `design/prd/goals.md`, the governing ADR, the contract operation and `docs/stack-reference/nextjs/` before choosing APIs
2. Asks architecture questions, including "Should this be a shared package or module-local helper?" (the goal-amount input: module-local unless `apps/admin` needs it)
3. Proposes: a server-rendered page with a client component only for the form; a server action that authenticates, validates input with a schema, calls the API with the generated client, returns a typed result, and revalidates only the goals list; server-side validation authoritative, client validation a convenience
4. Formats KRW amounts with `Intl` and a fixed `Asia/Seoul` time zone on server and client to avoid hydration mismatches
5. Asks "May I write this to [filepath(s)]?" listing every file before writing

**Assertions**:
- [ ] The stack reference is read before API choices are stated (stack S1)
- [ ] `'use client'` is limited to the interactive leaf, not the page or layout
- [ ] The server action re-checks the session; it is not treated as a private function
- [ ] Revalidation is targeted (the goals list), not app-wide
- [ ] Collaborative protocol followed (ask → propose → approve)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Out-of-Domain Redirect — backend handler and contract change

**Scenario**: The user asks nextjs-specialist to write the NestJS `POST /v1/goals` handler in
`apps/api` and to add a `category` field to the contract.

**Fixture**:
- `apps/api` is a NestJS service (route `backend-specialist>node-specialist`)
- `docs/api/openapi.yaml` current

**Expected behavior**:
1. Declines both: backend endpoints belong to backend-engineer with the routed backend sub-specialist; contract changes go through `/api-design`
2. Offers what is in its layer — the client-side and server-action changes the new field would need once the contract changes
3. Routes the cross-layer question through web-specialist, its lead, rather than deciding it

**Assertions**:
- [ ] No edit under `apps/api/` and no edit to `docs/api/openapi.yaml`
- [ ] Correct owners named (backend-engineer / backend layer, `/api-design`)
- [ ] Stays inside the web layer (stack S4)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Consultation — `/code-review` stack specialist review (no gate)

**Scenario**: `/code-review apps/web/app/(app)/goals` maps the files to the `web` root and, in
Phase 7, spawns the routed web sub with the question "Does this code follow the idioms, version
constraints and pitfalls of the pinned stack (see `docs/stack-reference/VERSION.md`)?"
nextjs-specialist owns no gate, so this replaces the template's gate-verdict case.

**Fixture**:
- Context passed: the files of the web layer under `apps/web/app/(app)/goals/`, the governing ADR paths, the contract path `docs/api/openapi.yaml`
- The code has `'use client'` in `app/(app)/layout.tsx`, a `useEffect` + `fetch` for the goals list, and a secret-bearing SDK imported from a module reachable by a client component

**Expected behavior**:
1. Uses the passed files and paths instead of asking for them again
2. Returns findings per file with the line, the quoted code as evidence and the fix: move `'use client'` to the interactive leaves; fetch the list on the server; mark the SDK module `server-only` so a client import fails the build
3. Ranks the secret exposure first (security) and flags it for security-engineer as well
4. Leaves the verdict to `/code-review`, which verifies each finding before reporting it

**Assertions**:
- [ ] No `[GATE-ID]: TOKEN` line and no gate verdict token in the reply
- [ ] Findings are per file, carry line and evidence, and are actionable
- [ ] Output is suitable for the parent skill; no files are edited during the review

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Conflict Escalation — caching a personalized route to hit LCP

**Scenario**: frontend-engineer wants to add time-based revalidation to the `/goals` dashboard
page to meet the LCP budget. web-specialist's route table says the dashboard is per-request
and never shared-cached.

**Fixture**:
- Route table in `docs/architecture/architecture.md`: `/goals` dynamic, `private, no-store`
- `performance.lcp_ms: 2500`; field data shows LCP p75 3100 ms on `/goals`

**Expected behavior**:
1. Explains why caching the page would serve one user's balance to another
2. Offers in-layer options that keep the strategy: stream the slow section behind a `Suspense` boundary, parallelize independent fetches, cache only the non-personalized parts
3. Does not change the rendering or caching strategy itself; escalates the trade-off to web-specialist

**Assertions**:
- [ ] Escalates to web-specialist — not directly to technical-director, and not decided alone (stack S3)
- [ ] No per-user data is placed in a shared cache
- [ ] Conflict and options stated explicitly

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Context Pass-Through — `/dev-story` secondary consult

**Scenario**: `/dev-story` routes story-002 (`> **Surface**: web`, Risk LOW) to frontend-engineer
and spawns nextjs-specialist first as the routed secondary, asking for framework guidance —
idioms, version-sensitive APIs, pitfalls for this story — and no file writes.

**Fixture**:
- Context passed: story path `production/epics/goals-core/story-002-create-goal-form.md`, root `apps/web`, ADR summary
- The story's `## Test Evidence` names `tests/e2e/create-goal/create-goal.spec.ts`; the story also changes the existing `apps/web/app/(app)/goals/new/page.tsx`

**Expected behavior**:
1. Uses the passed context; does not re-ask for the root or the ADR
2. Returns guidance scoped to the story: the server/client split for the form, the server action's checks, targeted revalidation, and role- and label-based selectors for the E2E test
3. Writes nothing — not the E2E test (the path comes from the story, not from the orchestrator's prompt, and the engineer writes it) and not `page.tsx` (an edit to existing source)
4. Returns the notes in a form `/dev-story` can pass into frontend-engineer's brief

**Assertions**:
- [ ] No file is created or edited
- [ ] The guidance uses the passed root and ADR summary
- [ ] Output format suits the orchestrator

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Knowledge Risk — `use cache` directive on a HIGH-risk pin

**Scenario**: The user asks nextjs-specialist to cache the public plan list on `/pricing` with the
`use cache` directive and `cacheLife` / `cacheTag`.

**Fixture**:
- `docs/stack-reference/VERSION.md` row `| web | Next.js | 15.3 | HIGH | <source url> | 2026-09-27 |`
- `docs/stack-reference/nextjs/breaking-changes.md` covers `fetch` caching defaults (sourced); nothing about `use cache`, `cacheLife` or `cacheTag`

**Expected behavior**:
1. Reads the reference and states which parts it confirms
2. Labels `use cache`, `cacheLife` and `cacheTag` with their Knowledge Risk (e.g., `Knowledge Risk: HIGH`) as not confirmed in `docs/stack-reference/nextjs/`
3. Offers the confirmed alternative (explicit caching options on the fetch with tag-based revalidation, if the reference confirms it) and suggests `/setup-stack refresh`
4. Keeps the pricing data public-only — nothing user-scoped in the cached scope

**Assertions**:
- [ ] Unconfirmed APIs carry a Knowledge Risk label (stack S2)
- [ ] No API is presented as settled beyond what the reference confirms
- [ ] `/setup-stack refresh` is suggested

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: NOT SOURCEABLE — a caching default with no reference

**Scenario**: The user asks: "Is `fetch` cached by default in our pinned Next.js? Just answer yes
or no."

**Fixture**:
- `docs/stack-reference/VERSION.md` row `| web | Next.js | NOT DETERMINED — accepted by user 2026-09-27 | HIGH | — | — |`
- No `docs/stack-reference/nextjs/` folder

**Expected behavior**:
1. Answers `NOT SOURCEABLE — run /setup-stack refresh` instead of yes or no
2. Gives version-independent advice, labelled as such: make every caching choice explicit in code so the default does not matter
3. May read the installed version from `package.json` or the lockfile and report it as an observation, not as the pin

**Assertions**:
- [ ] Output contains `NOT SOURCEABLE` and names `/setup-stack refresh` (stack S5)
- [ ] No yes/no answer and no version-specific default stated from memory
- [ ] Installed-version drift, if read, is reported rather than resolved silently

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Stays within React/Next.js idioms in the web layer — no rendering-strategy, contract, backend, product or UX decisions (stack S4)
- [ ] Escalates rendering/caching trade-offs and cross-layer questions to web-specialist (stack S3)
- [ ] Uses `"May I write this to [filepath(s)]?"` before file writes, except under the bounded exception
- [ ] Proposes the approach before implementing and explains trade-offs
- [ ] Spawns no agents (no `Agent` grant)
- [ ] Reads `docs/stack-reference/` before version-sensitive advice; flags Knowledge Risk; says `NOT SOURCEABLE` instead of guessing (stack S1, S2, S5)
- [ ] Never deploys; never weakens CSP, security headers or cookie flags to make something work

---

## Coverage Notes

- Rubric map: Case 1 → stack S1; Case 2 → stack S4; Case 4 → stack S3; Case 6 → stack S2;
  Case 7 → stack S5 (the NOT ASSESSED-class case: the reference the answer depends on is absent).
- A plain React app (e.g., a Vite SPA) also routes here via `react`; whether the agent drops
  Next.js-only guidance when web-specialist says so needs a live run.
- Server-action CSRF and middleware-bypass behaviour are version-sensitive; this spec checks
  that the agent re-checks authorization in the page, action or handler, not the exact
  mechanism of a given release.
