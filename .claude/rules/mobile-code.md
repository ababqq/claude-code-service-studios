---
paths:
  - "apps/mobile/**"
  - "ios/**"
  - "android/**"
  - "**/*.swift"
  - "**/*.kt"
  - "**/*.dart"
---

# Mobile Code Rules

These paths hold the iOS and Android apps — React Native / Expo, Flutter, or native Swift and Kotlin. A mobile
release cannot be rolled back like a deploy: once a build is on users' phones, it stays there until they update.
Everything below follows from that. Screens also follow `.claude/rules/ui-code.md`. The `mobile-engineer` agent
implements; the routed mobile sub-specialist owns framework idioms.

## Permissions are justified

- Request only the permissions a PRD requirement needs, each at the moment of use, after an in-app rationale —
  notification permission when the user sets a goal reminder, not on first launch; camera when they scan, not at
  sign-up.
- Every declared permission has its purpose written down: localized `Info.plist` usage descriptions on iOS, the
  manifest permission and its justification on Android, and the matching store declarations.
- Handle every answer: granted, denied, limited or approximate (partial photo access, approximate location), and
  "don't ask again" — with a path to system settings and a working app without the permission where possible.
- Prefer system pickers (photo picker, document picker, contact picker) to broad storage, media or contacts
  permissions; request App Tracking Transparency only if the app actually tracks.

## Background work has limits

- Use the platform schedulers — WorkManager on Android, `BGTaskScheduler` on iOS, or the framework's wrapper over
  them — for deferrable work, with constraints (network, charging) and backoff. Background work is opportunistic:
  the OS delays, batches or skips it, so it is idempotent and resumable, and nothing correct depends on exact timing.
- No polling loops or long-running background services to watch for server changes: the server sends a push (or a
  data message) and the app syncs when opened. Foreground services only for user-visible ongoing work, with the
  declared foreground service type; exact alarms only with a justification the store accepts.
- Reminders the user must receive on time are scheduled server-side (push) or as local notifications — not as
  background code that has to wake up.

## Deep links are untrusted input

- Verified links only: Universal Links (`apple-app-site-association`) and Android App Links (`assetlinks.json`)
  served from the web origin; a custom URL scheme proves nothing about who sent the link.
- Parse every incoming link into a typed route through one resolver with an allowlist of paths; validate every
  parameter's format; unknown links go home with no error leak. Authorization stays on the server — a link to a goal
  the user does not own gets the API's 404, never another user's data.
- A link never performs a state-changing or money-moving action by itself: it opens the screen, and the user
  confirms in the app. Links that need a session route through sign-in and resume afterwards.
- OAuth and social login redirects (Kakao, Naver, Apple) use PKCE and `state`; external web content opens in the
  system browser, `SFSafariViewController` or Custom Tabs — an in-app WebView loads only allowlisted origins and
  exposes no JavaScript bridge to untrusted pages.

## Offline and sync conflicts

- Classify each data type: server-only (never cached), cached read-only (stale-while-revalidate), or editable
  offline (queued mutations). Moa caches the goal list read-only, queues goal creation, and never queues payment
  actions — they require connectivity and an explicit confirmation.
- Queued mutations carry a client-generated idempotency key and the base version they were made against. The server
  is authoritative; the conflict policy per entity (reject, last-write-wins, field merge) is written in the ADR, and
  a user whose edit lost is told so — never silently overwritten.
- Timestamps that decide ordering come from the server, not the device clock. Local database schemas are
  versioned, and every migration is tested upgrading from the oldest supported app version.
- The UI shows offline and pending states (`.claude/rules/ui-code.md`); sign-out clears caches, queued mutations and
  secure storage, and unregisters the push token server-side.

## Store policy

- **iOS privacy manifest** (`PrivacyInfo.xcprivacy`) declares data collection and required-reason API use, and every
  third-party SDK ships its own; the App Store privacy details match what the app and its SDKs actually collect.
- **Android target API level** meets the level Google Play currently requires for new apps and updates;
  `platform.min_os.android` and `platform.min_os.ios` in `project.yaml` set the minimums, and APIs above the minimum
  are guarded by availability checks. The Play Data safety form matches actual collection, SDKs included.
- Apps that let users create accounts let them delete their account in the app. Login-service and in-app payment
  rules (Apple login alongside Kakao/Naver login; whether a subscription must use in-app billing or may use an
  external payment) are store-policy and legal questions: route them to `monetization-strategist` and
  `.claude/docs/compliance/<region>.md`, and never settle them in code.
- Check the stores' current policy text before a submission — never quote it from memory. Over-the-air updates ship
  only JavaScript and assets that stay within store rules and the binary's native runtime version; a native change
  needs a store build.
- With Expo continuous native generation, `ios/` and `android/` are generated: native changes go through the app
  config and config plugins, never by hand-editing generated directories.

## Force-update path

- The API exposes the minimum supported app version per platform (and optionally a recommended version); the app
  checks it on launch and on resume. Below the minimum, the app shell's force-update state
  (`design/ux/app-shell.md` `## Global States`) blocks use and links to the store; below the recommended version, it
  nudges once.
- The check is tiny, cacheable and independent of everything else it might have to rescue; when it cannot be
  reached, the app continues on the last known policy.
- The rollout plan (`/rollout-plan`) owns raising the minimum; until it is raised, the API keeps serving every shape
  a supported app version calls (`.claude/rules/api-code.md`). Remote kill switches for risky features are feature
  flags, not force updates.

## Also

- Tokens and secrets live only in the Keychain or Keystore-backed storage — never in `AsyncStorage`,
  `SharedPreferences`, `UserDefaults`, logs or crash reports. API keys shipped in the app are public; restrict them
  by bundle ID or signing certificate on the provider side.
- TLS only: no cleartext traffic exceptions in release builds.
- Release builds strip debug logging; crash reporting uploads symbols (dSYMs, R8 mapping files) and scrubs personal
  data.
- Separate bundle and application IDs per environment, so a staging build never talks to production or replaces the
  production install. Signing material lives in CI or a managed credentials service; `validate-commit` blocks
  keystores and provisioning profiles.
- Store submission is a human action: agents never run `eas submit`, `fastlane deliver` or `fastlane supply`
  (`production_deploys` is always-ask, and the settings deny list blocks them).
- Budgets come from `performance.cold_start_ms` and `performance.crash_free_pct`; unset ⇒ say so, never invent one.
  Test on a low-end Android device and the oldest supported iOS version, not only on flagship simulators.
- Before relying on a framework, SDK or OS API, check `docs/stack-reference/VERSION.md` and
  `docs/stack-reference/<component>/`; not covered ⇒ `NOT SOURCEABLE — run /setup-stack refresh`.

## Examples

**Correct** (Swift — one resolver, typed routes, validated parameters, unknown links rejected):

```swift
enum DeepLink: Equatable {
    case home
    case goal(GoalID)

    /// Parses `https://<link host>/goals/<goalId>`. Anything else returns nil.
    init?(url: URL, linkHost: String) {
        guard url.scheme == "https", url.host == linkHost else { return nil }
        let parts = url.pathComponents.filter { $0 != "/" }
        switch parts.count {
        case 0:
            self = .home
        case 2 where parts[0] == "goals":
            guard let id = GoalID(rawValue: parts[1]) else { return nil } // validates the goal_ + ULID format
            self = .goal(id)                                              // the API checks ownership on load
        default:
            return nil
        }
    }
}
```

**Correct** (Kotlin — queued goal sync as unique, constrained, backed-off work):

```kotlin
val request = OneTimeWorkRequestBuilder<PendingGoalSyncWorker>()
    .setConstraints(Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build())
    .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, WorkRequest.MIN_BACKOFF_MILLIS, TimeUnit.MILLISECONDS)
    .build()

WorkManager.getInstance(context)
    .enqueueUniqueWork("pending-goal-sync", ExistingWorkPolicy.KEEP, request) // one sync at a time
```

**Incorrect** (React Native):

```typescript
await Notifications.requestPermissionsAsync();                 // VIOLATION: asked on first launch, no rationale
await AsyncStorage.setItem('accessToken', token);              // VIOLATION: token in plain storage

Linking.addEventListener('url', ({ url }) => {
  const { amount, goalId } = parse(url);                       // VIOLATION: unvalidated parameters from any sender
  api.confirmDeposit(goalId, Number(amount));                  // VIOLATION: a link moves money without confirmation
});

setInterval(syncGoals, 60_000);                                // VIOLATION: polling instead of push-triggered sync
```
