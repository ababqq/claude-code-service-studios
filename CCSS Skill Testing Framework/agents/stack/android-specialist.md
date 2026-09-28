# Agent Spec: android-specialist

> **Tier**: stack
> **Category**: stack
> **Spec written**: 2026-09-28

<!-- Asserts the canonical English text of .claude/agents/android-specialist.md (quoted
     prompts, headings, tokens), never the wording the model uses at run time in the
     user's conversation language. Examples use the canonical product "Moa". Versions
     and Knowledge Risk values in fixtures are illustrative test inputs, not claims
     about real releases. -->

## Agent Summary

The Android specialist is the mobile layer's sub-specialist for native Android: Kotlin with
coroutines and Flow, Jetpack Compose with unidirectional data flow, Android platform services
(FCM, App Links, WorkManager, Keystore), Gradle build configuration, Google Play policies and
the target API level. mobile-specialist routes work to it when `stack.layers.mobile.framework`
matches `kotlin|compose|android` (alone, or with iOS as the native pair ios-specialist +
android-specialist), and may also spawn it for substantial native pieces of a cross-platform
app; `/dev-story`, `/code-review` and `/team-ui` (at `studio`) spawn it directly from the resolved
route. It uses the Implementation Workflow, runs on Sonnet, has Bash but no `Agent` grant and no
web search, and owns no director gate. It reads `docs/stack-reference/` before any
version-sensitive advice — target-API deadlines and Play policies change yearly — and answers
`NOT SOURCEABLE — run /setup-stack refresh` where the reference is silent. Billing-program
choices, Play publishing, server logic and product decisions are outside it.

**Domain**: native Android in the mobile root — Kotlin / Jetpack Compose, Android platform services, Gradle builds, Play policies, target API level
**Escalates to**: mobile-specialist
**Delegates to**: —
**Gates owned**: none

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/android-specialist.md`; frontmatter `name: android-specialist` equals the file stem and the catalog `name`
- [ ] Frontmatter keys in canonical order: `name`, `description`, `tools`, `model`, `maxTurns` — no `disallowedTools`, no `memory`, no `skills`, no `isolation`
- [ ] `description` is one double-quoted line that starts with the domain seed "Kotlin / Jetpack Compose, Play policies, target API level." and continues with "Use when …"
- [ ] `tools` grants exactly `Read`, `Glob`, `Grep`, `Write`, `Edit`, `Bash` — no `Agent(...)` grant, no `WebSearch`/`WebFetch`
- [ ] `model: sonnet` (stack sub-specialist), matching `.claude/docs/model-tiers.md`; `maxTurns: 20`
- [ ] Opening line after the frontmatter has the form "You are the [Title] for a web/mobile/API product team." with a title naming the role (e.g., "Android Specialist")
- [ ] The `##` headings of the body are exactly these, in this order:
  1. `## Collaboration Protocol` — contains `### Implementation Workflow` (with the question "Should this be a shared package or module-local helper?"), then the paragraph beginning "**Bounded exception — orchestrated runs.**", verbatim
  2. `## Core Responsibilities`
  3. one `## [Domain] Standards` heading for the platform (e.g., `## Android Standards`)
  4. `## Version Awareness`
  5. `## What This Agent Must NOT Do`
  6. `## Delegation Map`
- [ ] No `## Gate Verdict Format` section (owns no gate) and no `## Sub-Specialist Orchestration` section (no `Agent(...)` grant)
- [ ] `## Version Awareness` requires reading `docs/stack-reference/VERSION.md` and `docs/stack-reference/<component>/` before version-sensitive advice, flagging post-cutoff APIs with their Knowledge Risk, answering `NOT SOURCEABLE — run /setup-stack refresh` instead of guessing, staying inside the mobile layer, and escalating to mobile-specialist, its lead
- [ ] `## Delegation Map` has exactly three lines: `Reports to: mobile-specialist`, `Delegates to: —`, and `Coordinates with: …`
- [ ] Reporting line: mobile-specialist lists `android-specialist` in its `Delegates to:` line and in its `Agent(...)` grant
- [ ] Every agent named in `Coordinates with:` exists under `.claude/agents/`
- [ ] Domain clearly stated; mobile architecture decisions (mobile-specialist), billing-program and store-policy decisions, Play publishing and staged rollout, server logic and the API contract, and product, UX and copy decisions are stated as outside it
- [ ] Escalation path documented: escalates to mobile-specialist
- [ ] Implementation Workflow step 1 treats design-tool exports (Figma design-context React + Tailwind, Claude Design HTML/CSS/JS) under `design/handoff/<slug>/` as reference, not source — layout and visual reference only, rebuilt with Compose/Material 3 components and semantic tokens — never pasted into a code root
- [ ] Does not make decisions outside its domain; never publishes to Play tracks or commits keystores and signing passwords

---

## Test Cases

### Case 1: In-Domain Request — goal detail screen, links and background sync

**Scenario**: mobile-engineer asks android-specialist to build the goal detail screen for native
Android, open it from an App Link, and refresh goal balances in the background.

**Fixture**:
- `stack.layers.mobile.framework: Native (Swift + Kotlin)`; routing `mobile-specialist>ios-specialist+android-specialist`; `stack.layers.mobile.root: [apps/ios, apps/android]` (this story works in `apps/android`)
- mobile-specialist's decisions: deep link `/goals/:goalId`; balances refreshed by periodic background work, never more often than the API's rate limit allows
- `docs/stack-reference/VERSION.md` rows for Kotlin, Compose and the Android Gradle plugin, Knowledge Risk LOW; `platform.min_os.android` set

**Expected behavior**:
1. Reads the stack reference before naming APIs, library coordinates or build settings
2. Proposes: a ViewModel exposing immutable UI state as a `StateFlow`, collected lifecycle-aware in Compose; loading, empty, error and content states; App Link handling for `/goals/:goalId` with the `assetlinks.json` content coordinated with web-specialist through mobile-specialist
3. Uses WorkManager with constraints (network, battery) for the periodic refresh, and an idempotent API call
4. Asks "May I write this to [filepath(s)]?" before writing

**Assertions**:
- [ ] The stack reference is read before version-sensitive statements (stack S1)
- [ ] UI state is unidirectional and lifecycle-aware
- [ ] Deep-link paths match the web routes
- [ ] Collaborative protocol followed (ask → propose → approve)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Out-of-Domain Redirect — billing program choice

**Scenario**: The user asks android-specialist to choose between Google Play Billing and an
alternative billing option available in Korea for Moa Plus, and to implement it.

**Fixture**:
- `design/prd/subscription.md` leaves the Android purchase channel open
- `compliance.regions: [kr]`

**Expected behavior**:
1. Declines to decide the billing program in code: pricing and payment methods belong to monetization-strategist; store-policy and compliance questions to security-engineer with `.claude/docs/compliance/kr.md`
2. Offers the technical implications of each option as input (purchase flow, server-side verification, refunds and entitlement sync)
3. Routes the question through mobile-specialist, its lead

**Assertions**:
- [ ] No billing implementation chosen or written
- [ ] monetization-strategist and security-engineer named as owners
- [ ] Stays inside its domain (stack S4)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Consultation — `/code-review` of Android files (no gate)

**Scenario**: `/code-review` routes the Android files of a native-mobile change to
android-specialist (routing `mobile-specialist>ios-specialist+android-specialist`) and asks whether
the code follows the idioms, version constraints and pitfalls of the pinned stack.
android-specialist owns no gate, so this replaces the template's gate-verdict case.

**Fixture**:
- Context passed: the changed files under `apps/android/app/src/main/` for story `production/epics/auth-core/story-005-session-refresh.md`, the governing ADR paths, the contract path
- The code launches work in a global scope, collects a flow in a composable without lifecycle awareness, blocks the main thread while refreshing the token, and stores the refresh token in plain shared preferences

**Expected behavior**:
1. Returns findings per file with the fix: structured concurrency scoped to the ViewModel; lifecycle-aware collection; suspend the refresh off the main thread; keep secrets under a Keystore-backed key
2. Ranks the token-storage finding first and flags it for security-engineer as well
3. Does not edit files during the review

**Assertions**:
- [ ] No `[GATE-ID]: TOKEN` line and no gate verdict token in the reply
- [ ] Findings are per file and actionable
- [ ] No files edited during the review

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Conflict Escalation — native pair divergence on deep-link paths

**Scenario**: The Android implementation uses `/goal/:id` while the iOS side and the web routes
use `/goals/:goalId`; ios-specialist asks android-specialist to change.

**Fixture**:
- mobile-specialist's decision in the story names `/goals/:goalId`
- The Android code already shipped to internal testing with `/goal/:id`

**Expected behavior**:
1. Acknowledges the divergence from the lead's decision and the impact (broken shared links, analytics mismatch)
2. Proposes the fix (match `/goals/:goalId`, keep a redirect for the internal build) but does not settle a cross-platform decision alone
3. Escalates to mobile-specialist, its lead

**Assertions**:
- [ ] Escalates to mobile-specialist — does not skip a tier (stack S3)
- [ ] The lead's decision is treated as binding until the lead changes it
- [ ] Conflict surfaced explicitly

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Context Pass-Through — the Android half of a native story (consult, no writes)

**Scenario**: `/dev-story` routes the push opt-in story (Surface `ios, android`) to mobile-engineer
and spawns android-specialist for the Android half, asking for framework guidance with no file writes
(the skill's Phase 4: stack specialists consult, engineers write).

**Fixture**:
- Context passed: story path `production/epics/notifications-core/story-007-push-opt-in.md`, root `apps/android`, the story's ADR decision summary with mobile-specialist's permission and deep-link decisions, `platform.min_os.android`
- The story will need an edit to the existing `apps/android/app/build.gradle.kts`; the prompt names no destination path

**Expected behavior**:
1. Uses the passed context without re-asking
2. Returns guidance for mobile-engineer's brief: the permission request in context, the denied-state path to settings, availability guards against `platform.min_os.android`, and any API the reference does not confirm, labelled with its Knowledge Risk
3. Describes the `build.gradle.kts` change for the engineer instead of making it, and writes no screenshots — the skill captures the evidence in its Phase 6
4. Returns a result scoped to the story

**Assertions**:
- [ ] No file written — no destination path was named, so the bounded exception does not apply
- [ ] Existing configuration is not edited by the agent
- [ ] Output format suits the orchestrator

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Knowledge Risk — raising the target API level

**Scenario**: The user asks android-specialist to raise `targetSdk` to the newest level and to
adopt the predictive back gesture in the same release.

**Fixture**:
- `docs/stack-reference/VERSION.md` row for the Android toolchain with Knowledge Risk HIGH
- The component's `breaking-changes.md` documents the edge-to-edge behaviour change for the new target level (sourced); nothing about predictive back

**Expected behavior**:
1. Applies the sourced edge-to-edge change (insets on every screen) and cites it
2. Labels the predictive back APIs with their Knowledge Risk (e.g., `Knowledge Risk: HIGH`) as not confirmed in the reference
3. Proposes an audit of behaviour changes for the new target level before the bump and suggests `/setup-stack refresh`

**Assertions**:
- [ ] Unconfirmed APIs carry a Knowledge Risk label (stack S2)
- [ ] Sourced facts are cited; unsourced ones are not presented as settled
- [ ] `/setup-stack refresh` is suggested

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: NOT SOURCEABLE — a Play requirement and its deadline

**Scenario**: The user asks: "Does Play's 16 KB memory page size requirement apply to our native
libraries, and from what date?"

**Fixture**:
- The stack reference records the pinned toolchain but no Play policy requirements

**Expected behavior**:
1. Answers `NOT SOURCEABLE — run /setup-stack refresh` for the requirement's scope and date
2. States no date or API level from memory
3. Offers a local observation that does not depend on the policy text — inspect the built app bundle for native libraries and their alignment — labelled as an observation, and routes release timing to release-manager

**Assertions**:
- [ ] Output contains `NOT SOURCEABLE` and names `/setup-stack refresh` (stack S5)
- [ ] No date or API level stated from memory
- [ ] Local checks are labelled as observations, not policy statements

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Stays within native Android in the mobile layer — no billing-program, release, contract, product or UX decisions (stack S4)
- [ ] Escalates architecture trade-offs, pair divergences and cross-layer questions to mobile-specialist (stack S3)
- [ ] Uses `"May I write this to [filepath(s)]?"` before file writes, except under the bounded exception
- [ ] Proposes the approach before implementing and explains trade-offs
- [ ] Spawns no agents (no `Agent` grant)
- [ ] Reads `docs/stack-reference/` before version-sensitive advice; flags Knowledge Risk; says `NOT SOURCEABLE` instead of guessing (stack S1, S2, S5)
- [ ] Never publishes to Play tracks, changes staged-rollout percentages, or commits keystores and signing passwords

---

## Coverage Notes

- Rubric map: Case 1 → stack S1; Case 2 → stack S4; Case 4 → stack S3; Case 6 → stack S2;
  Case 7 → stack S5 (the NOT ASSESSED-class case: the facts the answer depends on are absent).
- Play policy interpretation is checked for routing and sourcing, not for the policy text,
  which changes and must come from the reference.
- Reconciliation of the native pair is mobile-specialist's job; this spec checks only that
  android-specialist escalates divergences instead of resolving them.
