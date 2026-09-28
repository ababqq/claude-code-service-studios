# Agent Spec: mobile-specialist

> **Tier**: stack
> **Category**: stack
> **Spec written**: 2026-09-28

<!-- Asserts the canonical English text of .claude/agents/mobile-specialist.md (quoted
     prompts, headings, tokens), never the wording the model uses at run time in the
     user's conversation language. Examples use the canonical product "Moa". Versions
     and Knowledge Risk values in fixtures are illustrative test inputs, not claims
     about real releases. -->

## Agent Summary

The mobile specialist leads the mobile layer of the stack: cross-platform vs native, app
navigation, offline storage and sync, push, deep links, runtime permissions, signing and store
builds. It drafts options for mobile ADRs, reviews mobile stack compatibility, and takes
HIGH-risk `ios`, `android` and `mobile` stories itself; it is also the stand-in for its subs
wherever no mobile sub is routed (`/dev-story`, `/code-review`, `/team-ui` at `studio`) and a
layer lead in `/setup-stack` and in `/team-hardening` at `studio`. Framework work goes to four
sub-specialists through its `Agent(...)` grant — react-native-specialist, flutter-specialist,
ios-specialist and android-specialist — selected by the derived routing of
`stack.layers.mobile.framework` (including the native pair ios-specialist + android-specialist),
never by preference. It uses the Implementation Workflow, runs at the `inherit` model tier, has
Bash but no web search, and owns no director gate. It reads `docs/stack-reference/` before any
version-sensitive advice (OS, SDK and store requirements move yearly) and answers
`NOT SOURCEABLE — run /setup-stack refresh` where the reference is silent. Store submission and
rollout, payment-method policy, the API contract and product/UX decisions sit outside it.

**Domain**: mobile framework choice, navigation, offline storage & sync, push, deep links, permissions, signing & store builds for the `mobile` layer roots (Moa: `apps/mobile`)
**Escalates to**: technical-director
**Delegates to**: react-native-specialist, flutter-specialist, ios-specialist, android-specialist
**Gates owned**: none

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/mobile-specialist.md`; frontmatter `name: mobile-specialist` equals the file stem and the catalog `name`
- [ ] Frontmatter keys in canonical order: `name`, `description`, `tools`, `model`, `maxTurns` — no `disallowedTools`, no `memory`, no `skills`, no `isolation`
- [ ] `description` is one double-quoted line that starts with the domain seed "Mobile layer lead: cross-platform vs native, navigation, offline storage & sync, push, deep links, permissions, signing & store builds." and continues with "Use when …"
- [ ] `tools` grants exactly `Read`, `Glob`, `Grep`, `Write`, `Edit`, `Bash` plus `Agent(react-native-specialist, flutter-specialist, ios-specialist, android-specialist)` — no `WebSearch`/`WebFetch`, and the `Agent(...)` grant names exactly these four members
- [ ] `model: inherit` (stack layer lead), matching `.claude/docs/model-tiers.md`; `maxTurns: 20`
- [ ] Opening line after the frontmatter has the form "You are the [Title] for a web/mobile/API product team." with a title naming the role (e.g., "Mobile Specialist")
- [ ] The `##` headings of the body are exactly these, in this order:
  1. `## Collaboration Protocol` — contains `### Implementation Workflow` (with the question "Should this be a shared package or module-local helper?"), then the paragraph beginning "**Bounded exception — orchestrated runs.**", verbatim
  2. `## Core Responsibilities`
  3. one `## [Domain] Standards` heading for the mobile layer (e.g., `## Mobile Standards`)
  4. `## Sub-Specialist Orchestration`
  5. `## Version Awareness`
  6. `## What This Agent Must NOT Do`
  7. `## Delegation Map`
- [ ] No `## Gate Verdict Format` section — mobile-specialist owns no director gate
- [ ] `## Sub-Specialist Orchestration` restates the grant and the routing of `stack.layers.mobile.framework`, case-insensitive, rules in order, first match wins:
  1. `react native|expo` → react-native-specialist
  2. `flutter` → flutter-specialist
  3. the value matches both (`swift|ios`) and (`kotlin|compose|android`), or matches `^native` → ios-specialist + android-specialist
  4. `swift|ios` → ios-specialist
  5. `kotlin|compose|android` → android-specialist
  6. anything else → no sub-specialist (mobile-specialist does the work and says so)
- [ ] `## Sub-Specialist Orchestration` names the override key `specialists.mobile`, says the route is read from the resolved `stack` line (not chosen by preference), and prints `NOT CHECKED — mobile layer not configured (run /setup-stack)` when the mobile layer is unset
- [ ] `## Version Awareness` requires reading `docs/stack-reference/VERSION.md` and `docs/stack-reference/<component>/` before version-sensitive advice, flagging post-cutoff APIs with their Knowledge Risk, answering `NOT SOURCEABLE — run /setup-stack refresh` instead of guessing, staying inside the mobile layer, and delegating only through the `Agent(...)` grant (its subs escalate to it)
- [ ] `## Delegation Map` has exactly three lines: `Reports to: technical-director`, `Delegates to: react-native-specialist, flutter-specialist, ios-specialist, android-specialist`, and `Coordinates with: …`
- [ ] Reporting line: technical-director lists `mobile-specialist` in its own `Delegates to:` line; each of the four subs names `mobile-specialist` in its `Reports to:` line
- [ ] Every agent named in `Agent(...)`, `Delegates to:` or `Coordinates with:` exists under `.claude/agents/`
- [ ] Domain clearly stated; product, UX and monetization decisions, store-policy and payment-compliance calls, store submission and rollout (release-manager), and the API contract are stated as outside it
- [ ] Escalation path documented: escalates to technical-director
- [ ] Does not make decisions outside its domain; never submits builds, changes rollout percentages or prints signing credentials

---

## Test Cases

### Case 1: In-Domain Request — offline, push and deep links for `goals`

**Scenario**: The user asks mobile-specialist to decide how Moa's React Native (Expo) app handles
the goals list offline, push registration and links to a single goal.

**Fixture**:
- Resolved `stack` line: `stack: web=Next.js 15.3 (language=TypeScript) @apps/web,apps/admin; mobile=React Native (Expo) 0.79 (language=TypeScript) @apps/mobile; backend=NestJS 11.0 (language=TypeScript, runtime=Node.js 22) @apps/api,services/worker; data=PostgreSQL 16 (cache=Redis 7, queue=none, orm=Prisma 6); cloud=AWS (iac=Terraform 1.9) @infra [routing: web-specialist>nextjs-specialist, mobile-specialist>react-native-specialist, backend-specialist>node-specialist, data-specialist, cloud-specialist] (project.yaml)`
- `docs/stack-reference/VERSION.md` row `| mobile | React Native (Expo) | 0.79 | LOW | <source url> | 2026-09-27 |`; `docs/stack-reference/react-native-expo/VERSION.md` present
- `design/prd/goals.md` and `design/prd/notifications.md` Approved; web route `/goals/:goalId`

**Expected behavior**:
1. Reads the stack reference before stating any framework or OS behaviour
2. Proposes: a read cache shown immediately and refreshed in the background; queued offline edits carrying idempotency keys; money-moving actions (auto-debit setup) online-only with a clear offline state
3. Push: token registration after login, re-registration on token rotation, unregistration on logout; permission prompt after the user has seen value (e.g., after creating the first goal), not at first launch — flagged as a UX decision for product-designer
4. Deep links: `/goals/:goalId` identical on web and mobile (Universal Links / App Links), with the link-verification files served from the web origin in coordination with web-specialist
5. Asks "May I write this to [filepath(s)]?" before writing the decision into the architecture or an ADR draft

**Assertions**:
- [ ] The stack reference is read before version-sensitive statements (stack S1)
- [ ] Money-moving actions are online-only — never replayed later from an offline queue; queued non-money edits carry idempotency keys
- [ ] UX-owned choices (prompt timing) are flagged for their owner, not decided
- [ ] Collaborative protocol followed (ask → propose → approve)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Out-of-Domain Redirect — payment method on iOS and a forced update

**Scenario**: The user asks mobile-specialist to (a) decide whether Moa Plus on iOS is sold
through in-app purchase or a Toss Payments link and implement it, and (b) raise the minimum
supported app version today to force everyone onto the new build.

**Fixture**:
- `design/prd/subscription.md` does not decide the purchase channel
- `compliance.regions: [kr]`; `release.distribution: web+stores`

**Expected behavior**:
1. (a) Declines to decide the purchase channel in code: pricing and payment methods belong to monetization-strategist, store-policy and compliance to security-engineer with `.claude/docs/compliance/kr.md`; offers the technical implications of each option
2. (b) Declines to raise the minimum supported version: rollout and force-update decisions belong to release-manager and humans
3. Names the owners and keeps its contribution to the mobile-layer facts

**Assertions**:
- [ ] No purchase-channel code and no minimum-version change made
- [ ] monetization-strategist, security-engineer and release-manager named correctly
- [ ] Stays inside the mobile layer (stack S4)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Consultation — `/create-architecture` mobile section (no gate)

**Scenario**: `/create-architecture` (Phase 9, Stack Lead Review) spawns the routed stack lead of
each configured layer; mobile-specialist reviews the drafted sections that touch the mobile
layer. mobile-specialist owns no gate, so this replaces the template's gate-verdict case.

**Fixture**:
- Context passed: the blueprint sections drafted so far that touch the mobile layer, the component versions from the resolved `stack` line (Case 1) and the `docs/stack-reference/` paths the skill read; `platform.surfaces: [web, ios, android, api]`; `performance.cold_start_ms` and `performance.crash_free_pct` unset
- The drafts say nothing about offline storage or the minimum OS versions; the team writes TypeScript and has no native iOS/Android engineers

**Expected behavior**:
1. Uses the passed context instead of asking for it again
2. Flags decisions that fight the pinned framework, APIs or patterns changed or deprecated after the knowledge cutoff (citing the stack-reference file), and the missing mobile pieces — offline storage and the minimum OS versions here, with push and deep links checked — each with the Knowledge Risk of the component from `docs/stack-reference/VERSION.md`
3. Reports that the mobile budgets are unset rather than inventing numbers
4. Returns findings to the skill, which writes `docs/architecture/architecture.md`

**Assertions**:
- [ ] No `[GATE-ID]: TOKEN` line and no gate verdict token (TD-ARCHITECTURE and TL-FEASIBILITY belong to other agents)
- [ ] Unset budgets reported as unset
- [ ] The agent does not write the architecture file itself when no path was named for it

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Sub-Specialist Orchestration — native pair and derived routing

**Scenario**: `/dev-story` spawns mobile-specialist (instead of a sub) for
`production/epics/notifications-core/story-007-push-opt-in.md` because its `**Risk**` is HIGH.

**Fixture**:
- Story: `> **Surface**: ios, android`, `**Risk**: HIGH`
- `stack.layers.mobile.framework: Native (Swift + Kotlin)`; resolved routing `mobile-specialist>ios-specialist+android-specialist`
- Variants: (a) framework `Flutter` (route `mobile-specialist>flutter-specialist`); (b) `specialists.mobile: mobile-specialist`; (c) the user invokes mobile-specialist directly on a project with no `stack.layers.mobile` block (mobile layer unset — `/dev-story` itself would spawn no mobile specialist)

**Expected behavior**:
1. Base fixture: spawns ios-specialist and android-specialist in parallel with the same story context (story path, root, API operations, its push and permission decisions, minimum OS versions from `platform.min_os.ios` / `platform.min_os.android`, Knowledge Risk of the mobile row)
2. Reconciles the two proposals before presenting one plan: same deep-link paths, identical analytics events, same error copy keys
3. Variant (a): spawns flutter-specialist only
4. Variant (b): spawns no sub and says the override names the lead
5. Variant (c): spawns nobody and prints `NOT CHECKED — mobile layer not configured (run /setup-stack)`

**Assertions**:
- [ ] Only members of `Agent(react-native-specialist, flutter-specialist, ios-specialist, android-specialist)` are spawned — never mobile-engineer or any other agent (stack S3)
- [ ] The sub(s) spawned equal the resolved route; the override `specialists.mobile` wins
- [ ] The native pair's outputs are reconciled before they reach the user
- [ ] Variant (c) prints the `NOT CHECKED` line exactly and spawns nobody

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Knowledge Risk — push API and edge-to-edge on a HIGH-risk pin

**Scenario**: The user asks mobile-specialist to switch Moa's push handling to the framework's
newer notifications API and enable edge-to-edge layout on Android in the same release.

**Fixture**:
- `docs/stack-reference/VERSION.md` row `| mobile | React Native (Expo) | 0.79 | HIGH | <source url> | 2026-09-27 |`
- `docs/stack-reference/react-native-expo/breaking-changes.md` covers edge-to-edge behaviour (sourced); nothing about the notifications API change

**Expected behavior**:
1. Applies the sourced edge-to-edge guidance and cites it
2. Labels the notifications API change with its Knowledge Risk (e.g., `Knowledge Risk: HIGH`) as not confirmed in `docs/stack-reference/react-native-expo/`
3. Suggests `/setup-stack refresh` and a development-build spike before committing the push change, and delegates the spike to react-native-specialist through its grant

**Assertions**:
- [ ] Unconfirmed APIs carry a Knowledge Risk label (stack S2)
- [ ] Sourced facts are cited; unsourced ones are not presented as settled
- [ ] Any delegation goes to the routed sub through the `Agent(...)` grant

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: NOT SOURCEABLE — store requirements with no reference

**Scenario**: The user asks: "What target API level does Google Play require for updates this
year, from which date, and which Xcode version must App Store uploads use?"

**Fixture**:
- `docs/stack-reference/VERSION.md` has mobile framework rows but no store-requirement facts; `docs/stack-reference/react-native-expo/` has `VERSION.md` only

**Expected behavior**:
1. Answers `NOT SOURCEABLE — run /setup-stack refresh` for each store requirement and date
2. States no API level, Xcode version or deadline from memory
3. Points submission planning to release-manager and offers to read the project's current `targetSdk` and Xcode build settings as observations

**Assertions**:
- [ ] Output contains `NOT SOURCEABLE` and names `/setup-stack refresh` (stack S5)
- [ ] No version number or date stated from memory
- [ ] Observed project settings are labelled as observations, not requirements

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: Conflict Escalation — delta sync endpoint vs full list

**Scenario**: mobile-specialist wants `GET /v1/goals/changes?since=` for efficient offline sync;
backend-specialist prefers the existing list endpoint with `ETag` and refuses a new endpoint.

**Fixture**:
- `docs/api/openapi.yaml` has `GET /v1/goals` with `ETag`; no sync ADR
- Both positions written in the story discussion

**Expected behavior**:
1. States the trade-off (payload size and battery on mobile vs contract surface and deletion tracking on the backend)
2. Does not edit the contract; any change goes through `/api-design`
3. Escalates to technical-director, the shared parent of both layer leads

**Assertions**:
- [ ] Conflict surfaced explicitly with both positions
- [ ] Escalates to technical-director
- [ ] No unilateral contract change

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 8: Context Pass-Through — orchestrated HIGH-risk story (consult, no writes)

**Scenario**: `/dev-story` spawns mobile-specialist (instead of the sub) for a HIGH-risk `mobile`
story and asks for framework guidance with no file writes (the skill's Phase 4: stack
specialists consult, engineers write).

**Fixture**:
- Context passed: story path `production/epics/goals-core/story-006-goal-home-widget.md`, root `apps/mobile`, contract operation `GET /v1/goals`, the story's ADR decision summary, Knowledge Risk HIGH; resolved routing `mobile-specialist>react-native-specialist`
- The story will need an edit to the existing `apps/mobile/app.config.ts`; the prompt names no destination path

**Expected behavior**:
1. Uses the passed context; does not re-ask for the root or the operation
2. Returns guidance for mobile-engineer's brief: framework idioms through react-native-specialist and, for the substantial native widget parts, ios-specialist / android-specialist — spawned through its grant, or returned as `<sub>: <task>` hand-offs with `NOT CONSULTED — <sub> (nested spawn unavailable)` when it cannot spawn; every API the stack reference does not confirm is labelled with its Knowledge Risk
3. Describes the `app.config.ts` change for the engineer instead of making it, and writes no evidence — the skill captures device screenshots in its Phase 6
4. Returns a result scoped to the story

**Assertions**:
- [ ] No file written — no destination path was named, so the bounded exception does not apply
- [ ] A sub it could not spawn appears as a `<sub>: <task>` hand-off or a `NOT CONSULTED` line, never silently skipped
- [ ] Output format suits the orchestrator

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Stays within the mobile layer — no API-contract, payment-policy, release or product/UX decisions (stack S4)
- [ ] Escalates cross-layer and architecture conflicts to technical-director
- [ ] Uses `"May I write this to [filepath(s)]?"` before file writes, except under the bounded exception
- [ ] Proposes the approach and trade-offs before implementing
- [ ] Delegates only through `Agent(react-native-specialist, flutter-specialist, ios-specialist, android-specialist)` and only to the routed sub(s); does not skip tiers (stack S3)
- [ ] Reads `docs/stack-reference/` before version-sensitive advice; flags Knowledge Risk; says `NOT SOURCEABLE` instead of guessing (stack S1, S2, S5)
- [ ] Never submits builds, changes rollout percentages, or commits or prints signing credentials

---

## Coverage Notes

- Rubric map: Case 1 → stack S1; Case 2 → stack S4; Case 4 → stack S3; Case 5 → stack S2;
  Case 6 → stack S5 (the NOT ASSESSED-class case: the facts the answer depends on are absent).
- Parallel spawning of the native pair and the reconciliation step need a live run to observe
  the actual spawn order.
- A cross-platform app that needs a substantial native piece (a home-screen widget) may add
  ios-specialist / android-specialist next to the routed sub; the spec accepts that as long as
  every spawn stays within the grant.
