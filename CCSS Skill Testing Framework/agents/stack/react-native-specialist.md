# Agent Spec: react-native-specialist

> **Tier**: stack
> **Category**: stack
> **Spec written**: 2026-09-28

<!-- Asserts the canonical English text of .claude/agents/react-native-specialist.md
     (quoted prompts, headings, tokens), never the wording the model uses at run time in
     the user's conversation language. Examples use the canonical product "Moa".
     Versions and Knowledge Risk values in fixtures are illustrative test inputs, not
     claims about real releases. -->

## Agent Summary

The React Native specialist is the mobile layer's sub-specialist for React Native and Expo:
app configuration, EAS build profiles, submit configuration and update channels, config
plugins, native modules and New Architecture compatibility, plus React Native performance.
mobile-specialist routes work to it when `stack.layers.mobile.framework` matches
`react native|expo`, and decides the navigation, offline and push architecture it implements;
`/dev-story` names it as the secondary agent on `mobile`, `ios` and `android` stories under
that route (a consult: it returns guidance and the engineers write), and `/code-review` sends
it the files under the mobile root. It uses the Implementation Workflow, runs on Sonnet, has Bash but no `Agent` grant
and no web search, and owns no director gate. It reads `docs/stack-reference/` before any
version-sensitive advice and answers `NOT SOURCEABLE — run /setup-stack refresh` where the
reference is silent. Publishing OTA updates, store submission, server logic and product
decisions are outside it.

**Domain**: React Native / Expo in the mobile root (Moa: `apps/mobile`) — app config, EAS profiles and update channels, config plugins, native modules, New Architecture
**Escalates to**: mobile-specialist
**Delegates to**: —
**Gates owned**: none

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/react-native-specialist.md`; frontmatter `name: react-native-specialist` equals the file stem and the catalog `name`
- [ ] Frontmatter keys in canonical order: `name`, `description`, `tools`, `model`, `maxTurns` — no `disallowedTools`, no `memory`, no `skills`, no `isolation`
- [ ] `description` is one double-quoted line that starts with the domain seed "React Native / Expo: EAS, config plugins, native modules, New Architecture." and continues with "Use when …"
- [ ] `tools` grants exactly `Read`, `Glob`, `Grep`, `Write`, `Edit`, `Bash` — no `Agent(...)` grant, no `WebSearch`/`WebFetch`
- [ ] `model: sonnet` (stack sub-specialist), matching `.claude/docs/model-tiers.md`; `maxTurns: 20`
- [ ] Opening line after the frontmatter has the form "You are the [Title] for a web/mobile/API product team." with a title naming the role (e.g., "React Native Specialist")
- [ ] The `##` headings of the body are exactly these, in this order:
  1. `## Collaboration Protocol` — contains `### Implementation Workflow` (with the question "Should this be a shared package or module-local helper?"), then the paragraph beginning "**Bounded exception — orchestrated runs.**", verbatim
  2. `## Core Responsibilities`
  3. one `## [Domain] Standards` heading for the framework (e.g., `## React Native Standards`)
  4. `## Version Awareness`
  5. `## What This Agent Must NOT Do`
  6. `## Delegation Map`
- [ ] No `## Gate Verdict Format` section (owns no gate) and no `## Sub-Specialist Orchestration` section (no `Agent(...)` grant)
- [ ] `## Version Awareness` requires reading `docs/stack-reference/VERSION.md` and `docs/stack-reference/<component>/` before version-sensitive advice, flagging post-cutoff APIs with their Knowledge Risk, answering `NOT SOURCEABLE — run /setup-stack refresh` instead of guessing, staying inside the mobile layer, and escalating to mobile-specialist, its lead
- [ ] `## Delegation Map` has exactly three lines: `Reports to: mobile-specialist`, `Delegates to: —`, and `Coordinates with: …`
- [ ] Reporting line: mobile-specialist lists `react-native-specialist` in its `Delegates to:` line and in its `Agent(...)` grant
- [ ] Every agent named in `Coordinates with:` exists under `.claude/agents/`
- [ ] Domain clearly stated; mobile architecture decisions (mobile-specialist), server logic and the API contract, store submission and OTA publishing, and product, UX, copy and monetization decisions are stated as outside it
- [ ] Escalation path documented: escalates to mobile-specialist
- [ ] Does not make decisions outside its domain; never publishes updates, submits builds or prints credentials

---

## Test Cases

### Case 1: In-Domain Request — build profiles and update channels

**Scenario**: mobile-engineer asks react-native-specialist to set up Moa's build profiles,
update channels and the Kakao login SDK integration.

**Fixture**:
- Resolved routing `mobile-specialist>react-native-specialist`; root `apps/mobile`
- `docs/stack-reference/VERSION.md` row `| mobile | React Native (Expo) | 0.79 | LOW | <source url> | 2026-09-27 |`; `docs/stack-reference/react-native-expo/VERSION.md` present
- Environments: development, staging (preview), production; staging API `https://api.staging.moa.example`

**Expected behavior**:
1. Reads `docs/stack-reference/react-native-expo/` before naming config fields or CLI flags
2. Proposes build profiles for development, preview and production, each bound to its environment and update channel; a runtime-version policy so an over-the-air update never reaches a binary with incompatible native code
3. Integrates the Kakao login SDK through a config plugin (native projects generated, not hand-edited), with secrets kept out of `app.config.ts` public fields
4. Asks "Should this be a shared package or module-local helper?" where relevant and "May I write this to [filepath(s)]?" before writing

**Assertions**:
- [ ] The stack reference is read before version-sensitive statements (stack S1)
- [ ] OTA updates are tied to a runtime-version policy, not published to all binaries
- [ ] Native changes go through config plugins, not manual edits to generated native folders
- [ ] Collaborative protocol followed (ask → propose → approve)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Out-of-Domain Redirect — push fan-out and 알림톡 fallback

**Scenario**: The user asks react-native-specialist to write the worker that sends push
notifications to all Plus users and falls back to 알림톡 when push fails.

**Fixture**:
- `services/worker` is a NestJS worker (route `backend-specialist>node-specialist`)
- `design/prd/notifications.md` Approved

**Expected behavior**:
1. Declines the server-side fan-out and the 알림톡 fallback: they belong to backend-engineer with the routed backend sub-specialist
2. Keeps its part: device token registration, permission handling and notification handling in the app, per mobile-specialist's push decision
3. Routes the cross-layer question through mobile-specialist, its lead

**Assertions**:
- [ ] No code written under `services/worker/` or `apps/api/`
- [ ] Correct owners named
- [ ] Stays inside the mobile layer (stack S4)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Consultation — `/code-review` stack specialist review (no gate)

**Scenario**: `/code-review apps/mobile/src/features/goals production/epics/goals-core/story-002-create-goal-form.md`
maps the files to the `mobile` root and, in Phase 7, spawns the routed mobile sub with the
question "Does this code follow the idioms, version constraints and pitfalls of the pinned stack
(see `docs/stack-reference/VERSION.md`)?" react-native-specialist owns no gate, so this replaces
the template's gate-verdict case.

**Fixture**:
- Context passed: the mobile-layer files under `apps/mobile/src/features/goals/`, the governing ADR paths, the contract path `docs/api/openapi.yaml`
- The code stores the refresh token in unencrypted async storage, renders the goals list with inline item components re-created on every render, and fetches the list in an effect without cancellation

**Expected behavior**:
1. Returns findings per file with the line, the quoted code as evidence and the fix: tokens in the platform secure store (Keychain / Keystore-backed); stable item components and keys for the list; cancel or ignore stale requests
2. Ranks the token-storage finding first and flags it for security-engineer as well
3. Does not rewrite the files during the review; leaves the verdict to `/code-review`, which verifies each finding

**Assertions**:
- [ ] No `[GATE-ID]: TOKEN` line and no gate verdict token in the reply
- [ ] Findings are per file, carry line and evidence, and are actionable
- [ ] No files edited during the review

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Conflict Escalation — hand-editing generated native projects

**Scenario**: mobile-engineer wants to commit the generated `ios/` and `android/` folders and
hand-edit them to add a payment SDK quickly. mobile-specialist's ADR chose generated native
projects with config plugins.

**Fixture**:
- ADR `docs/architecture/adr-0007-mobile-build-and-native-code.md` Accepted (generated native projects)
- The payment SDK has no config plugin

**Expected behavior**:
1. States the conflict with the ADR and the cost (drift on every regeneration, lost upgrades)
2. Offers the in-domain alternative (write a config plugin for the SDK) but does not override the ADR or the engineer alone
3. Escalates to mobile-specialist, its lead; notes that adding the SDK also needs a tech-radar entry or ADR and a privacy-manifest / Data safety check

**Assertions**:
- [ ] Escalates to mobile-specialist — does not skip a tier (stack S3)
- [ ] No generated native folders committed or edited unilaterally
- [ ] Conflict surfaced explicitly

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Context Pass-Through — `/dev-story` secondary consult

**Scenario**: `/dev-story` routes story-002 (`> **Surface**: mobile`, Risk LOW) to
mobile-engineer and spawns react-native-specialist first as the routed secondary, asking for
framework guidance — idioms, version-sensitive APIs, pitfalls for this story — and no file writes.

**Fixture**:
- Context passed: story path `production/epics/goals-core/story-002-create-goal-form.md`, root `apps/mobile`, ADR summary
- The story's `## Test Evidence` names `tests/e2e/create-goal/create-goal.yaml` (a Maestro flow); the story also changes the existing `apps/mobile/app.config.ts`

**Expected behavior**:
1. Uses the passed context without re-asking
2. Returns guidance scoped to the story: whether the change is JavaScript-only or needs a store build (the `app.config.ts` change), keyboard and Hangul-input handling for the form, the idempotency key on create, and role- or accessibility-label-based selectors for the E2E flow
3. Writes nothing — not the E2E flow (the engineer writes it) and not `app.config.ts` (existing config)
4. Returns the notes in a form `/dev-story` can pass into mobile-engineer's brief

**Assertions**:
- [ ] No file is created or edited
- [ ] The OTA-versus-store-build consequence of the change is stated
- [ ] Output format suits the orchestrator

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Knowledge Risk — New Architecture and a community library

**Scenario**: The user asks react-native-specialist to confirm that the community Kakao login
library works with the New Architecture in the pinned SDK.

**Fixture**:
- `docs/stack-reference/VERSION.md` row `| mobile | React Native (Expo) | 0.79 | HIGH | <source url> | 2026-09-27 |`
- `docs/stack-reference/react-native-expo/breaking-changes.md` states the New Architecture default for the pinned SDK (sourced); nothing about third-party library compatibility

**Expected behavior**:
1. Cites the sourced New Architecture fact
2. Labels the library's compatibility as not confirmed, with its Knowledge Risk (e.g., `Knowledge Risk: HIGH`), instead of answering "compatible" from memory
3. Proposes a verification spike (a development build with the library, exercising login on both platforms) and suggests `/setup-stack refresh`

**Assertions**:
- [ ] Unconfirmed compatibility carries a Knowledge Risk label (stack S2)
- [ ] No compatibility claim stated from memory
- [ ] A concrete verification step is proposed

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: NOT SOURCEABLE — service limits of the update service

**Scenario**: The user asks: "What is the maximum update bundle size the update service accepts,
and how long are old updates kept?"

**Fixture**:
- `docs/stack-reference/react-native-expo/` has `VERSION.md` only; no service limits recorded

**Expected behavior**:
1. Answers `NOT SOURCEABLE — run /setup-stack refresh`
2. States no size or retention number from memory
3. Gives version-independent advice, labelled as such: keep large assets out of OTA updates and measure the bundle in CI

**Assertions**:
- [ ] Output contains `NOT SOURCEABLE` and names `/setup-stack refresh` (stack S5)
- [ ] No limit or retention period stated from memory
- [ ] Version-independent advice is separated from the unanswered question

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Stays within React Native / Expo in the mobile layer — no server, contract, release, product or monetization decisions (stack S4)
- [ ] Escalates architecture trade-offs and cross-layer questions to mobile-specialist (stack S3)
- [ ] Uses `"May I write this to [filepath(s)]?"` before file writes, except under the bounded exception
- [ ] Proposes the approach before implementing and explains trade-offs
- [ ] Spawns no agents (no `Agent` grant)
- [ ] Reads `docs/stack-reference/` before version-sensitive advice; flags Knowledge Risk; says `NOT SOURCEABLE` instead of guessing (stack S1, S2, S5)
- [ ] Never publishes OTA updates, submits store builds, changes rollout percentages, or commits or prints credentials and keystores

---

## Coverage Notes

- Rubric map: Case 1 → stack S1; Case 2 → stack S4; Case 4 → stack S3; Case 6 → stack S2;
  Case 7 → stack S5 (the NOT ASSESSED-class case: the facts the answer depends on are absent).
- Publishing an OTA update in an incident runs through `/hotfix` with humans; a live run should
  confirm the agent prepares the change and the command but does not publish.
- Native-module work may be shared with ios-specialist / android-specialist when
  mobile-specialist spawns them; this spec checks only that react-native-specialist does not
  spawn them itself.
