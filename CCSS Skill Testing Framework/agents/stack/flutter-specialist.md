# Agent Spec: flutter-specialist

> **Tier**: stack
> **Category**: stack
> **Spec written**: 2026-09-28

<!-- Asserts the canonical English text of .claude/agents/flutter-specialist.md (quoted
     prompts, headings, tokens), never the wording the model uses at run time in the
     user's conversation language. Examples use the canonical product "Moa". Versions
     and Knowledge Risk values in fixtures are illustrative test inputs, not claims
     about real releases. -->

## Agent Summary

The Flutter specialist is the mobile layer's sub-specialist for Flutter and Dart: feature-first
app structure, the one state-management approach the ADR chose, typed navigation and deep-link
handling, platform channels and FFI, flavors and per-environment configuration, and Flutter
performance. mobile-specialist routes work to it when `stack.layers.mobile.framework` matches
`flutter`, and decides the navigation, offline and push architecture it implements;
`/dev-story` names it as the secondary agent on `mobile`, `ios` and `android` stories under
that route, `/code-review` routes `mobile`-root files to it, and `/team-ui` at `studio` asks it
for implementation notes before implementation. It uses the Implementation Workflow, runs on Sonnet, has Bash but no `Agent` grant
and no web search, and owns no director gate. It reads `docs/stack-reference/` before any
version-sensitive advice and answers `NOT SOURCEABLE — run /setup-stack refresh` where the
reference is silent. Server logic, the API contract, store submission and product decisions
are outside it.

**Domain**: Flutter/Dart in the mobile root (Moa variant on Flutter: `apps/mobile`) — widgets, state management, navigation, platform channels, flavors
**Escalates to**: mobile-specialist
**Delegates to**: —
**Gates owned**: none

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/flutter-specialist.md`; frontmatter `name: flutter-specialist` equals the file stem and the catalog `name`
- [ ] Frontmatter keys in canonical order: `name`, `description`, `tools`, `model`, `maxTurns` — no `disallowedTools`, no `memory`, no `skills`, no `isolation`
- [ ] `description` is one double-quoted line that starts with the domain seed "Flutter/Dart: widgets, state management, platform channels, flavors." and continues with "Use when …"
- [ ] `tools` grants exactly `Read`, `Glob`, `Grep`, `Write`, `Edit`, `Bash` — no `Agent(...)` grant, no `WebSearch`/`WebFetch`
- [ ] `model: sonnet` (stack sub-specialist), matching `.claude/docs/model-tiers.md`; `maxTurns: 20`
- [ ] Opening line after the frontmatter has the form "You are the [Title] for a web/mobile/API product team." with a title naming the role (e.g., "Flutter Specialist")
- [ ] The `##` headings of the body are exactly these, in this order:
  1. `## Collaboration Protocol` — contains `### Implementation Workflow` (with the question "Should this be a shared package or module-local helper?"), then the paragraph beginning "**Bounded exception — orchestrated runs.**", verbatim
  2. `## Core Responsibilities`
  3. one `## [Domain] Standards` heading for the framework (e.g., `## Flutter Standards`)
  4. `## Version Awareness`
  5. `## What This Agent Must NOT Do`
  6. `## Delegation Map`
- [ ] No `## Gate Verdict Format` section (owns no gate) and no `## Sub-Specialist Orchestration` section (no `Agent(...)` grant)
- [ ] `## Version Awareness` requires reading `docs/stack-reference/VERSION.md` and `docs/stack-reference/<component>/` before version-sensitive advice, flagging post-cutoff APIs with their Knowledge Risk, answering `NOT SOURCEABLE — run /setup-stack refresh` instead of guessing, staying inside the mobile layer, and escalating to mobile-specialist, its lead
- [ ] `## Delegation Map` has exactly three lines: `Reports to: mobile-specialist`, `Delegates to: —`, and `Coordinates with: …`
- [ ] Reporting line: mobile-specialist lists `flutter-specialist` in its `Delegates to:` line and in its `Agent(...)` grant
- [ ] Every agent named in `Coordinates with:` exists under `.claude/agents/`
- [ ] Domain clearly stated; mobile architecture decisions (mobile-specialist), a second state-management approach, server logic and the API contract, store submission, and product, UX, copy and monetization decisions are stated as outside it
- [ ] Escalation path documented: escalates to mobile-specialist
- [ ] Implementation Workflow step 1 treats design-tool exports (Figma design-context React + Tailwind, Claude Design HTML/CSS/JS) under `design/handoff/<slug>/` as reference, not source — layout and visual reference only, rebuilt with the project's widgets, theme and semantic tokens — never pasted into a code root
- [ ] Does not make decisions outside its domain; never submits store builds or commits signing material

---

## Test Cases

### Case 1: In-Domain Request — flavors, state and deep links

**Scenario**: mobile-engineer asks flutter-specialist to set up flavors and the goal-detail
navigation for a Moa variant built on Flutter.

**Fixture**:
- `stack.layers.mobile.framework: Flutter`; resolved routing `mobile-specialist>flutter-specialist`; root `apps/mobile`
- ADR `docs/architecture/adr-0007-mobile-state-management.md` Accepted (one state-management library chosen)
- `docs/stack-reference/VERSION.md` row `| mobile | Flutter | <pinned> | LOW | <source url> | 2026-09-27 |`; `docs/stack-reference/flutter/VERSION.md` present
- Web route `/goals/:goalId`

**Expected behavior**:
1. Reads `docs/stack-reference/flutter/` before naming APIs or build flags
2. Proposes development, staging and production flavors with separate application IDs, per-flavor configuration files (no secrets compiled into the app) and per-flavor push and analytics configuration
3. Uses the ADR's state-management approach only; typed routes with `/goals/:goalId` handled from a cold start and from a running app
4. Asks "Should this be a shared package or module-local helper?" where relevant and "May I write this to [filepath(s)]?" before writing

**Assertions**:
- [ ] The stack reference is read before version-sensitive statements (stack S1)
- [ ] Exactly one state-management approach is used, the ADR's
- [ ] Deep-link paths match the web routes
- [ ] Collaborative protocol followed (ask → propose → approve)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Out-of-Domain Redirect — contract shape and plan price

**Scenario**: The user asks flutter-specialist to change `GET /v1/goals` to return progress as a
formatted percentage string and to set the Plus plan price shown in the paywall.

**Fixture**:
- `docs/api/openapi.yaml` returns `savedAmount` and `targetAmount` as integers (KRW)
- `design/prd/subscription.md` owns plan pricing

**Expected behavior**:
1. Declines the contract change (goes through `/api-design`) and keeps formatting on the client with `intl` in the user's locale
2. Declines to set a price: pricing belongs to monetization-strategist; the paywall shows what the pricing source provides
3. Routes the cross-layer question through mobile-specialist, its lead

**Assertions**:
- [ ] No edit to `docs/api/openapi.yaml`; no price hard-coded as a decision
- [ ] Correct owners named
- [ ] Stays inside the mobile layer (stack S4)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: Consultation — `/team-ui` implementation notes (no gate)

**Scenario**: `/team-ui` at `team.size: studio` spawns the routed mobile sub before implementation
(its Phase 3) to review the UX spec and visual design notes for the goals dashboard and hand
framework-specific implementation notes to mobile-engineer. flutter-specialist owns no gate, so
this replaces the template's gate-verdict case.

**Fixture**:
- Context passed: UX spec `design/ux/goals-dashboard.md` and the visual design notes; root `apps/mobile`
- The screen lists up to 50 goal cards with 64-px avatars and KRW amounts under a header that collapses on scroll

**Expected behavior**:
1. Returns implementation notes: a lazily built list, rebuild scope kept narrow for the scroll-driven header (no `setState` at the top of the screen), `const` constructors, images decoded at display size, one cached locale-aware currency formatter outside `build`, safe areas and keyboard avoidance where the spec has input
2. Suggests confirming performance with a profile-mode run on a mid-range Android device rather than an emulator
3. Leaves the UI consistency verdict to design-director's DD-UI-CONSISTENCY gate

**Assertions**:
- [ ] No `[GATE-ID]: TOKEN` line and no gate verdict token in the reply
- [ ] Notes are actionable and addressed to the implementing engineer
- [ ] No files written

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Conflict Escalation — a second state-management library

**Scenario**: mobile-engineer wants to add a second state-management library for the new
onboarding screens because "it is faster to write".

**Fixture**:
- ADR on state management Accepted; the onboarding story does not mention a new library

**Expected behavior**:
1. States that a second approach contradicts the ADR and splits patterns across the codebase
2. Shows how the screens fit the chosen approach
3. Does not add the library; escalates to mobile-specialist, its lead, if the engineer still wants it (a change would need a superseding ADR)

**Assertions**:
- [ ] Escalates to mobile-specialist — does not skip a tier (stack S3)
- [ ] No second state-management library added
- [ ] Conflict surfaced explicitly

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Context Pass-Through — `/dev-story` secondary on a UI story (consult, no writes)

**Scenario**: `/dev-story` routes a `mobile` UI story to mobile-engineer with flutter-specialist as
the routed secondary, and spawns flutter-specialist first for framework guidance with no file
writes (the skill's Phase 4: stack specialists consult, engineers write).

**Fixture**:
- Context passed: story path `production/epics/goals-core/story-008-goal-card.md` (`> **Type**: UI`), root `apps/mobile`, UX spec path, the story's ADR decision summary
- The story will need an edit to the existing `apps/mobile/lib/features/goals/goal_card.dart`; the prompt names no destination path

**Expected behavior**:
1. Uses the passed context without re-asking
2. Returns guidance for mobile-engineer's brief: widget structure and rebuild scope, the ADR's state-management approach, a golden-test plan for the card's states, and any API the reference does not confirm, labelled with its Knowledge Risk
3. Describes the `goal_card.dart` change instead of making it, and writes no golden images or screenshots — the engineer writes the tests and the skill captures the evidence in its Phase 6
4. Returns a result scoped to the story

**Assertions**:
- [ ] No file written — no destination path was named, so the bounded exception does not apply
- [ ] Existing source is not edited by the agent
- [ ] Output format suits the orchestrator

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Knowledge Risk — new language syntax and renderer settings

**Scenario**: The user asks flutter-specialist to adopt a Dart syntax feature they read about
and to change the Android renderer setting in the same pull request.

**Fixture**:
- `docs/stack-reference/VERSION.md` row `| mobile | Flutter | <pinned> | HIGH | <source url> | 2026-09-27 |`
- `docs/stack-reference/flutter/breaking-changes.md` covers the Android renderer status (sourced); nothing about the Dart syntax feature
- `apps/mobile/pubspec.yaml` declares the Dart SDK constraint

**Expected behavior**:
1. Applies the sourced renderer guidance and cites it
2. Labels the syntax feature with its Knowledge Risk (e.g., `Knowledge Risk: HIGH`) as not confirmed in `docs/stack-reference/flutter/`, and reads the SDK constraint in `pubspec.yaml` as an observation
3. Does not rewrite code across the app on an unconfirmed feature; suggests `/setup-stack refresh`

**Assertions**:
- [ ] Unconfirmed features carry a Knowledge Risk label (stack S2)
- [ ] Sourced facts are cited; unsourced ones are not presented as settled
- [ ] `/setup-stack refresh` is suggested

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: NOT SOURCEABLE — minimum OS support of the pinned SDK

**Scenario**: The user asks: "Which minimum iOS and Android versions does our pinned Flutter
support, and can we drop the old ones in the next release?"

**Fixture**:
- `docs/stack-reference/VERSION.md` row `| mobile | Flutter | NOT DETERMINED — accepted by user 2026-09-27 | HIGH | — | — |`
- `platform.min_os.ios` and `platform.min_os.android` unset

**Expected behavior**:
1. Answers `NOT SOURCEABLE — run /setup-stack refresh` for the SDK's supported minimums
2. States no OS version from memory; reports that `platform.min_os.*` is unset rather than proposing values
3. Routes the "drop old versions" decision to mobile-specialist and release-manager (it affects users in the field)

**Assertions**:
- [ ] Output contains `NOT SOURCEABLE` and names `/setup-stack refresh` (stack S5)
- [ ] No OS version stated from memory; unset keys reported as unset
- [ ] The support-policy decision is routed to its owners

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Stays within Flutter/Dart in the mobile layer — no server, contract, release, product or monetization decisions (stack S4)
- [ ] Escalates architecture trade-offs and cross-layer questions to mobile-specialist (stack S3)
- [ ] Uses `"May I write this to [filepath(s)]?"` before file writes, except under the bounded exception
- [ ] Proposes the approach before implementing and explains trade-offs
- [ ] Spawns no agents (no `Agent` grant)
- [ ] Reads `docs/stack-reference/` before version-sensitive advice; flags Knowledge Risk; says `NOT SOURCEABLE` instead of guessing (stack S1, S2, S5)
- [ ] Never submits store builds, changes rollout percentages or commits signing material

---

## Coverage Notes

- Rubric map: Case 1 → stack S1; Case 2 → stack S4; Case 4 → stack S3; Case 6 → stack S2;
  Case 7 → stack S5 (the NOT ASSESSED-class case: the facts the answer depends on are absent).
- Platform-channel work with a substantial native side may be shared with ios-specialist /
  android-specialist when mobile-specialist spawns them; this spec checks only that
  flutter-specialist does not spawn them itself.
- Jank findings are checked for shape; confirming them needs a profile-mode run on a device.
