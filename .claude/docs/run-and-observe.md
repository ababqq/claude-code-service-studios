# Run and Observe

Shared procedure for any skill that closes a story which changes something a
user can see or call. Referenced from the point of use in `/dev-story` (Phase 6
step 4) and `/story-done` (Phase 3). Those skills keep the one load-bearing
imperative inline — **a typecheck or build is not a run, and a story nobody
looked at does not close** — and cite this file for how to look.

`.claude/docs/coding-standards.md` is the authority for *what* evidence a story
needs (the story-type table and the `testing.strict` keys). This file is the
procedure for *producing* the observed half of it.

## The rule

Every story that changes something user-observable is **launched and observed
before it closes**, and the observation is **retained** in
`production/qa/evidence/<story-slug>/` (`<story-slug>` = the story file name
without `.md`). A passing typecheck proves the types line up. A green build
proves it compiles. Tests prove the logic. None of them proves that the Korean
goal name fits the card on a 390-pixel phone, or that the API returns the field
the app reads.

The agent can see images: Claude Code's `Read` tool renders a PNG, and it reads
a JSON snapshot as text. The whole problem is getting a picture or a response out
of the running product unattended, and every surface has a native way.

## The procedure

1. **Start the product** the way a developer would: `commands.run` (or
   `commands.dev`) from `project.yaml` for the layer that owns the surface — in
   the background for a web or API server, then wait until it answers (poll the
   URL or the health endpoint with `curl -sf`; do not sleep a fixed time). For a
   mobile app, build and launch it on a simulator, emulator or device.
2. **Go straight to the state the story touched.** A route, a deep link or an API
   operation — not the home screen and five taps. Reach it with seeded data, a test
   account and the story's feature flag switched on locally (see
   [Reaching the state](#reaching-the-state)).
3. **Capture** with the surface's mechanism below.
4. **Look.** `Read` every capture and compare it with the acceptance criteria.
   Clipped or overflowing text, a missing element, the wrong state, an empty list
   where data was seeded, an unexpected field or status code — these are defects,
   and this is the only step that finds them.
5. **Retain.** The capture lives in `production/qa/evidence/<story-slug>/`, named
   `NN-<state-or-operation>…` in capture order. A capture that was taken and
   discarded is an assertion, not evidence. Never retain it only under a
   gitignored path such as `production/session-logs/`.
6. **Stop what you started** (the background server, the simulator if you booted
   it) and **report** one `Run result:` line — vocabulary below.

## Per surface

| Story `**Surface**` | Start | Capture | Retained as |
|---|---|---|---|
| `web`, `admin` | `commands.run` (or `commands.dev`) of the web root | the capture script `/test-setup` wrote: `tests/e2e/capture.spec.ts` | `NN-<state>-desktop.png`, `NN-<state>-mobile.png`, optional `NN-<state>-axe.json` |
| `ios` | build and launch on a booted simulator | `xcrun simctl openurl` + `xcrun simctl io … screenshot` | `NN-<state>-ios.png` |
| `android` | build and install on an emulator or device | `adb shell am start` + `adb exec-out screencap` (or a Maestro/ARTEMIS flow) | `NN-<state>-android.png` |
| `mobile` (one cross-platform story) | both of the above | both of the above | both files |
| `api` | `commands.run` of the backend root (or the staging server) | the request/response snapshot | `NN-<operation>.json` |
| `infra`, `analytics` | — | no capture procedure; observe the user-visible effect through the surface that shows it, or record `N/A — <reason>` | — |

### Web — the capture script from `/test-setup`

`/test-setup` writes the capture script **only when a web layer is configured**
(Playwright requires Node): `tests/e2e/capture.spec.ts`. With the app running:

```bash
CAPTURE_URL=<route> CAPTURE_STATE=<state> CAPTURE_OUT_DIR=production/qa/evidence/<story-slug> npx playwright test tests/e2e/capture.spec.ts
```

- `CAPTURE_URL` — the route the story touched, e.g. `/goals/new`, or a full URL
  such as `http://localhost:3000/goals/new`.
- `CAPTURE_STATE` — a short kebab-case name for the state, e.g. `empty`,
  `validation-error`, `created`.
- `CAPTURE_OUT_DIR` — the story's evidence directory.

A relative `CAPTURE_URL` (e.g. `/goals/new`) resolves against `E2E_BASE_URL`,
which defaults to the local web server; the script fails loudly — never skips —
when a variable is missing, the state is not a kebab-case slug, or the route
answers 4xx/5xx.

The script writes `NN-<state>-desktop.png` (1280×800) and `NN-<state>-mobile.png`
(390×844) and, when `@axe-core/playwright` is installed, `NN-<state>-axe.json` —
the accessibility violations for that state. Run it once per state the story
touches. For the admin console, `CAPTURE_URL` points at the admin app's route.

**No capture script** — no web layer is configured, or `/test-setup` has not run
— means the web run is not verified:

```
Run result: NOT VERIFIED — no capture script (run /test-setup)
```

Do not improvise a replacement script inside the story: the capture interface is
shared by `/dev-story`, the engineer agents and `/story-done`, and a one-off
variant produces evidence nobody else can reproduce.

### iOS — simulator

```bash
xcrun simctl openurl booted <deep-link>
xcrun simctl io booted screenshot production/qa/evidence/<story-slug>/NN-<state>-ios.png
```

Build and launch the app first with the stack's run command (`commands.run` —
e.g. `npx expo run:ios`, `flutter run`, or an `xcodebuild` scheme). `openurl`
opens the deep link the story's screen is reachable by (for Moa,
`moa://goals/new`); give the screen a moment to render — wait for it, then
capture. For a clean status bar,
`xcrun simctl status_bar booted override --time 9:41` before capturing; for the
dark appearance, `xcrun simctl ui booted appearance dark`.

### Android — emulator or device

```bash
adb shell am start -W -a android.intent.action.VIEW -d <deep-link>
adb exec-out screencap -p > production/qa/evidence/<story-slug>/NN-<state>-android.png
```

Add the application ID after the deep link when several apps handle the scheme,
and `-s <serial>` when more than one device is attached (`adb devices` lists
them). `-W` waits for the launch to complete. When the project has Maestro flows
(`maestro test <flow>.yaml` with a `takeScreenshot` step) or ARTEMIS tools are
present in the session, a flow that drives the app to the state and captures it
is equally good evidence — say which one was used.

### API — request/response snapshot

Call the operation the story implemented against the local server (or staging,
with a test account — never production) and save one JSON file per call:

```json
{
  "operation": "POST /v1/goals",
  "request": {
    "headers": { "Authorization": "Bearer <redacted>", "Idempotency-Key": "b7c1…" },
    "body": { "name": "제주 여행", "targetAmount": 1500000, "targetDate": "2027-03-31" }
  },
  "response": {
    "status": 201,
    "body": { "id": "gl_01J…", "name": "제주 여행", "targetAmount": 1500000, "savedAmount": 0 }
  }
}
```

saved as `production/qa/evidence/<story-slug>/01-createGoal.json`. **Redact PII
and tokens before the file is written**: `Authorization` headers, cookies, API
keys, emails, phone numbers, names, account numbers, resident registration
numbers and card data become `<redacted>`. An unredacted snapshot is not evidence
— it is a leak into the repository. Compare status code, field names and types
with the contract in `docs/api/`; a field the contract does not declare is a
finding.

## The `Run result:` line

Exactly one of three shapes, in the implementation summary (and in the story's
evidence doc):

- **`Run result: OBSERVED — <what was seen, one line>`** with the retained path.
  *"Create-goal form shows the inline error for a past target date on desktop and
  mobile; the long Korean goal name wraps inside the card —
  `production/qa/evidence/story-001-create-goal/02-validation-error-mobile.png`."*
- **`Run result: NOT VERIFIED — <reason>`**. No capture script, `commands.run`
  unset, the app did not start, the simulator is not available, the capture is
  empty. This is a **blocker** at the default gate level for UI and E2E stories,
  not a note — a story nobody looked at does not close. Under an explicit
  `testing.strict.ui: false` (or `testing.strict.e2e: false` for an E2E story) it
  is recorded and the story may close with the gap in `## Completion Notes`. The
  other three strictness keys — `testing.strict.logic`,
  `testing.strict.integration`, `testing.strict.config` — govern their own types'
  test evidence, not this line; a Logic or Integration story with an observable
  surface still reports its run.
- **`Run result: N/A — <reason>`**, only for a pure Logic or Config story with
  genuinely nothing observable — a validator used by no endpoint yet, a flag
  default that ships off, an index-only migration. Say why. "It's a Logic story"
  is not a reason: the fee calculation shows up as a number on the payment screen
  and in the API response.

The run is **not waived at `qa.level: minimal`**. Tests are waived there; the
look is not. It is the cheapest verification in the pipeline and the one whose
absence produces a well-tested service that looks wrong.

## What a capture can and cannot show

**Can:** layout, clipping, overflow and wrapping (Korean text without spaces,
long names, large numbers with thousands separators), presence, alignment,
colour and contrast, dark mode, the right state at all (empty, loading, error,
success), and — for an API — status codes, field names, types and error bodies.
This is where shipped defects actually live.

**Cannot:** timing, perceived speed, animation and transition quality, haptics,
push delivery, or what happens under load. For motion, record video instead —
Playwright `--trace on` (or video), `xcrun simctl io booted recordVideo <file>`,
`adb shell screenrecord /sdcard/<file>.mp4` — and say which half the evidence
covers. Perceived quality stays a human check in `/team-qa` and usability
sessions; speed is `/perf-profile` and `/load-test`.

## Reaching the state

A capture of the home screen verifies nothing about the third step of the payment
flow. Reach the state directly:

- **Web** — a route with the needed parameters, a seeded test account signed in by
  the capture script's storage state, the story's flag on in the local flag
  provider.
- **Mobile** — a deep link to the screen (`moa://goals/<goalId>`), a debug launch
  argument or environment that selects the test account and seed data.
- **API** — a seed script or fixture that creates the resources the operation
  needs, and a test account's token.

Write stories so their surface is reachable one of these ways; a story that is
not will be marked `NOT VERIFIED` every time.

## Finding the tools

- **Web** — Node and the project's package manager; Playwright browsers installed
  (`npx playwright install chromium`).
- **iOS** — Xcode command-line tools (`xcrun`) and a simulator runtime; macOS only.
- **Android** — Android SDK platform-tools (`adb`) on `PATH` and a running
  emulator or authorized device (`adb devices` shows `device`, not
  `unauthorized` or `offline`).
- **API** — `curl` (or the stack's HTTP client) and a running server.

Absence of a tool is a `NOT VERIFIED — <tool> not available` result, never a
reason to report `N/A`. Commands above are the tools' documented CLI forms;
`docs/stack-reference/` is the project's pinned authority — check it before
trusting a version-qualified claim here.
