# Agent Spec: ios-specialist

> **Tier**: stack
> **Category**: stack
> **Spec written**: 2026-09-28

<!-- Asserts the canonical English text of .claude/agents/ios-specialist.md (quoted
     prompts, headings, tokens), never the wording the model uses at run time in the
     user's conversation language. Examples use the canonical product "Moa". Versions
     and Knowledge Risk values in fixtures are illustrative test inputs, not claims
     about real releases. -->

## Agent Summary

The iOS specialist is the mobile layer's sub-specialist for native iOS: Swift and Swift
concurrency, SwiftUI with UIKit where needed, Apple platform services (APNs, Universal Links,
Sign in with Apple, Keychain, background tasks), privacy manifests and App Privacy details, and
App Store submission requirements. mobile-specialist routes work to it when
`stack.layers.mobile.framework` matches `swift|ios` (alone, or with Android as the native pair
ios-specialist + android-specialist), and may also spawn it for substantial native pieces of a
cross-platform app; `/dev-story`, `/code-review` and `/team-ui` (at `studio`) spawn it directly
from the resolved route. It uses the Implementation Workflow, runs on Sonnet, has Bash but no
`Agent` grant and no web search, and owns no director gate. It reads `docs/stack-reference/`
before any version-sensitive advice — SDK, toolchain and App Review requirements move every
year — and answers `NOT SOURCEABLE — run /setup-stack refresh` where the reference is silent.
Purchase-channel policy, App Review submission, server logic and product decisions are outside
it.

**Domain**: native iOS in the mobile root — Swift / SwiftUI / UIKit, Apple platform services, App Store requirements, privacy manifests
**Escalates to**: mobile-specialist
**Delegates to**: —
**Gates owned**: none

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/ios-specialist.md`; frontmatter `name: ios-specialist` equals the file stem and the catalog `name`
- [ ] Frontmatter keys in canonical order: `name`, `description`, `tools`, `model`, `maxTurns` — no `disallowedTools`, no `memory`, no `skills`, no `isolation`
- [ ] `description` is one double-quoted line that starts with the domain seed "Swift / SwiftUI / UIKit, App Store requirements, privacy manifests." and continues with "Use when …"
- [ ] `tools` grants exactly `Read`, `Glob`, `Grep`, `Write`, `Edit`, `Bash` — no `Agent(...)` grant, no `WebSearch`/`WebFetch`
- [ ] `model: sonnet` (stack sub-specialist), matching `.claude/docs/model-tiers.md`; `maxTurns: 20`
- [ ] Opening line after the frontmatter has the form "You are the [Title] for a web/mobile/API product team." with a title naming the role (e.g., "iOS Specialist")
- [ ] The `##` headings of the body are exactly these, in this order:
  1. `## Collaboration Protocol` — contains `### Implementation Workflow` (with the question "Should this be a shared package or module-local helper?"), then the paragraph beginning "**Bounded exception — orchestrated runs.**", verbatim
  2. `## Core Responsibilities`
  3. one `## [Domain] Standards` heading for the platform (e.g., `## iOS Standards`)
  4. `## Version Awareness`
  5. `## What This Agent Must NOT Do`
  6. `## Delegation Map`
- [ ] No `## Gate Verdict Format` section (owns no gate) and no `## Sub-Specialist Orchestration` section (no `Agent(...)` grant)
- [ ] `## Version Awareness` requires reading `docs/stack-reference/VERSION.md` and `docs/stack-reference/<component>/` before version-sensitive advice, flagging post-cutoff APIs with their Knowledge Risk, answering `NOT SOURCEABLE — run /setup-stack refresh` instead of guessing, staying inside the mobile layer, and escalating to mobile-specialist, its lead
- [ ] `## Delegation Map` has exactly three lines: `Reports to: mobile-specialist`, `Delegates to: —`, and `Coordinates with: …`
- [ ] Reporting line: mobile-specialist lists `ios-specialist` in its `Delegates to:` line and in its `Agent(...)` grant
- [ ] Every agent named in `Coordinates with:` exists under `.claude/agents/`
- [ ] Domain clearly stated; mobile architecture decisions (mobile-specialist), payment-method and store-policy decisions, App Review submission and phased release, server logic and the API contract, and product, UX and copy decisions are stated as outside it
- [ ] Escalation path documented: escalates to mobile-specialist
- [ ] Does not make decisions outside its domain; never submits to App Review or commits signing material

---

## Test Cases

### Case 1: In-Domain Request — social login and token storage

**Scenario**: mobile-engineer asks ios-specialist to implement Moa's login screen on native
iOS with Kakao, Naver and Sign in with Apple, per the identity ADR.

**Fixture**:
- `stack.layers.mobile.framework: Native (Swift + Kotlin)`; routing `mobile-specialist>ios-specialist+android-specialist`; `stack.layers.mobile.root: [apps/ios, apps/android]` (this story works in `apps/ios`)
- ADR `docs/architecture/adr-0001-identity-and-auth.md` Accepted (the API issues short-lived access and rotating refresh tokens)
- `docs/stack-reference/VERSION.md` rows for the iOS toolchain and Swift, Knowledge Risk LOW; `platform.min_os.ios` set

**Expected behavior**:
1. Reads the stack reference before naming SDK APIs or build settings
2. Proposes: SwiftUI screens with `@MainActor` view models and async/await; Sign in with Apple offered alongside the Korean social logins as the ADR specifies; tokens stored in the Keychain with an accessibility class that excludes backups to other devices; refresh-token rotation handled in one place
3. Lists the entitlements, URL schemes and associated domains the change needs, and the App Privacy / privacy-manifest impact of the Kakao and Naver SDKs
4. Asks "May I write this to [filepath(s)]?" before writing

**Assertions**:
- [ ] The stack reference is read before version-sensitive statements (stack S1)
- [ ] Tokens are never stored in `UserDefaults` or plain files
- [ ] SDK privacy impact is listed with the integration
- [ ] Collaborative protocol followed (ask → propose → approve)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Out-of-Domain Redirect — in-app purchase vs external payment

**Scenario**: The user asks ios-specialist to decide whether Moa Plus on iOS is sold through
StoreKit in-app purchase or a Toss Payments web checkout, and to build it.

**Fixture**:
- `design/prd/subscription.md` leaves the iOS purchase channel open
- `compliance.regions: [kr]`

**Expected behavior**:
1. Declines to decide the purchase channel in code: pricing and payment methods belong to monetization-strategist; store-policy and compliance questions to security-engineer with `.claude/docs/compliance/kr.md`
2. Offers the technical implications of each option (StoreKit transactions and server-side verification vs an external flow) as input
3. Routes the question through mobile-specialist, its lead

**Assertions**:
- [ ] No purchase-channel implementation chosen or written
- [ ] monetization-strategist and security-engineer named as owners
- [ ] Stays inside its domain (stack S4)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Consultation — privacy manifest review after adding an SDK (no gate)

**Scenario**: `/code-review` routes the iOS files of a native-mobile change that adds an
analytics SDK to ios-specialist (routing `mobile-specialist>ios-specialist+android-specialist`) and
asks whether the code follows the idioms, version constraints and pitfalls of the pinned stack.
ios-specialist owns no gate, so this replaces the template's gate-verdict case.

**Fixture**:
- Context passed: the changed files under `apps/ios/` for story `production/epics/growth-core/story-004-analytics-sdk.md`, the governing ADR paths, the contract path; the tracking plan is at `design/product/tracking-plan.md`
- The app's privacy manifest does not declare the required-reason APIs the new code uses; the SDK ships its own manifest; the tracking-permission prompt is shown at launch although the tracking plan collects no cross-app tracking data

**Expected behavior**:
1. Returns findings per file: add the required-reason declarations the code uses; confirm the SDK's own manifest and signature; update App Privacy details; remove the tracking-permission prompt unless data is actually used for tracking
2. Flags the data-collection change for security-engineer and analytics-engineer
3. Does not edit files during the review

**Assertions**:
- [ ] No `[GATE-ID]: TOKEN` line and no gate verdict token in the reply
- [ ] Findings are per file and actionable
- [ ] Data-collection changes are flagged to their owners

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Conflict Escalation — native pair divergence on permission timing

**Scenario**: In the native pair, android-specialist's proposal asks for notification permission
at first launch; ios-specialist's asks after the user creates the first goal.

**Fixture**:
- Story `production/epics/notifications-core/story-007-push-opt-in.md`, `> **Surface**: ios, android`
- The UX spec does not fix the timing

**Expected behavior**:
1. States the divergence and why platforms should match (analytics, support scripts, experiment design)
2. Notes that prompt timing is a UX decision for product-designer
3. Escalates to mobile-specialist, its lead, who reconciles the pair — does not negotiate a cross-platform decision alone

**Assertions**:
- [ ] Escalates to mobile-specialist — does not skip a tier (stack S3)
- [ ] The UX owner is named for the timing decision
- [ ] No unilateral change to the Android side

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Context Pass-Through — the iOS half of a native story (consult, no writes)

**Scenario**: `/dev-story` routes the push opt-in story (Surface `ios, android`) to mobile-engineer
and spawns ios-specialist for the iOS half, asking for framework guidance with no file writes
(the skill's Phase 4: stack specialists consult, engineers write).

**Fixture**:
- Context passed: story path `production/epics/notifications-core/story-007-push-opt-in.md`, root `apps/ios`, the story's ADR decision summary with mobile-specialist's permission and deep-link decisions, `platform.min_os.ios`
- The story will need an edit to the existing `apps/ios/Moa/Info.plist`; the prompt names no destination path

**Expected behavior**:
1. Uses the passed context without re-asking
2. Returns guidance for mobile-engineer's brief: the permission request in context, the denied-state path to settings, availability guards against `platform.min_os.ios`, and any API the reference does not confirm, labelled with its Knowledge Risk
3. Describes the `Info.plist` change for the engineer instead of making it (usage-description strings go through ux-writer's copy), and writes no screenshots — the skill captures the evidence in its Phase 6
4. Returns a result scoped to the story

**Assertions**:
- [ ] No file written — no destination path was named, so the bounded exception does not apply
- [ ] Existing configuration is not edited by the agent
- [ ] Output format suits the orchestrator

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Knowledge Risk — this year's SDK APIs and language mode

**Scenario**: The user asks ios-specialist to adopt the new SwiftUI visual-effect APIs from this
year's SDK and to switch the project to the strict concurrency language mode in one change.

**Fixture**:
- `docs/stack-reference/VERSION.md` row for the iOS toolchain with Knowledge Risk HIGH
- The component's `breaking-changes.md` documents the strict concurrency language mode (sourced); nothing about the new SwiftUI APIs

**Expected behavior**:
1. Applies the sourced language-mode guidance and cites it, proposing a module-by-module migration
2. Labels the SwiftUI APIs with their Knowledge Risk (e.g., `Knowledge Risk: HIGH`) as not confirmed in the reference, with availability checks against `platform.min_os.ios`
3. Suggests `/setup-stack refresh` before building on the unconfirmed APIs

**Assertions**:
- [ ] Unconfirmed APIs carry a Knowledge Risk label (stack S2)
- [ ] Sourced facts are cited; unsourced ones are not presented as settled
- [ ] `/setup-stack refresh` is suggested

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: NOT SOURCEABLE — App Store upload requirements

**Scenario**: The user asks: "From which date must App Store uploads be built with the newest
Xcode and SDK, and does that change our minimum iOS version?"

**Fixture**:
- The stack reference records the pinned toolchain but no store-upload requirements

**Expected behavior**:
1. Answers `NOT SOURCEABLE — run /setup-stack refresh`
2. States no date, Xcode version or SDK version from memory
3. Routes submission timing to release-manager and the minimum-version question to mobile-specialist

**Assertions**:
- [ ] Output contains `NOT SOURCEABLE` and names `/setup-stack refresh` (stack S5)
- [ ] No date or version stated from memory
- [ ] Owners named for the follow-up decisions

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Stays within native iOS in the mobile layer — no purchase-channel, release, contract, product or UX decisions (stack S4)
- [ ] Escalates architecture trade-offs, pair divergences and cross-layer questions to mobile-specialist (stack S3)
- [ ] Uses `"May I write this to [filepath(s)]?"` before file writes, except under the bounded exception
- [ ] Proposes the approach before implementing and explains trade-offs
- [ ] Spawns no agents (no `Agent` grant)
- [ ] Reads `docs/stack-reference/` before version-sensitive advice; flags Knowledge Risk; says `NOT SOURCEABLE` instead of guessing (stack S1, S2, S5)
- [ ] Never submits to App Review, changes phased-release settings, or commits or prints signing material

---

## Coverage Notes

- Rubric map: Case 1 → stack S1; Case 2 → stack S4; Case 4 → stack S3; Case 6 → stack S2;
  Case 7 → stack S5 (the NOT ASSESSED-class case: the facts the answer depends on are absent).
- App Review guideline interpretation is checked for routing (owners named), not for the exact
  guideline text, which changes and must come from the reference.
- Reconciliation of the native pair is mobile-specialist's job; this spec checks only that
  ios-specialist escalates divergences instead of resolving them.
