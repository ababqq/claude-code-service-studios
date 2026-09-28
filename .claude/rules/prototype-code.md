---
paths:
  - "prototypes/**"
---

# Prototype Code Standards (Relaxed)

Prototypes are throwaway builds that answer one product question — is it valuable,
is it understandable, will people take the first step, can we technically do it —
before anyone writes production code. Standards are intentionally relaxed to
maximize learning speed. The goal is evidence, not production quality.

Two kinds of directory live here, both created by `/prototype`:

- `prototypes/<name>-concept/` — a concept prototype on one of the four paths:
  clickable, code, fake-door or concierge.
- `prototypes/<name>-spike-YYYY-MM-DD/` — a time-boxed spike that answers one
  technical or design question.

## What's Allowed in Prototypes
- Hard-coded values, fixtures and copy (no config, no feature flags)
- Minimal or no doc comments
- Whatever structure is fastest to change: globals, copy-paste, a single file
- Faked steps (a "payment succeeded" screen with no payment behind it)
- Debug output left in place
- Placeholder visuals and copy
- No automated tests, unless the question itself is about behaviour under load or
  concurrency

## What's Still Required
- Each prototype lives in its own subdirectory, named as above.
- Every file starts with the prototype header in the file's comment syntax
  (`<!-- … -->` in HTML, `#` in YAML or Python):
  ```
  // PROTOTYPE - NOT FOR PRODUCTION
  // Question: [the question this prototype answers]
  // Date: [YYYY-MM-DD]
  ```
- Every concept prototype MUST have `REPORT.md` (from
  `.claude/docs/templates/prototype-report.md`) with its verdict line
  `> **Verdict**: PROCEED | PIVOT | KILL | NOT ASSESSED`. Every spike MUST have
  `SPIKE-NOTE.md` (question, result YES / NO / PARTIAL, evidence, next action). A
  README may explain how to run the build; it never replaces the record. A
  directory without its record is completed with `/prototype report <dir>`.
- No production code may reference or import from `prototypes/`, and prototype code
  never imports from a code root — copy what you need.
- Prototypes must not modify files outside `prototypes/`.

## Data, Secrets and Exposure (never relaxed)
- **No real personal data.** Fixtures use obviously fake values (names like
  "테스트 사용자", phone numbers like 010-0000-0000, `@example.com` emails).
  Concierge and session data about real participants stays in the team's approved
  research store and appears here only as participant IDs (P1, P2, …).
- **No production keys.** Sandbox or test credentials only, read from a local `.env`
  that is never committed; `.env.example` holds placeholders. Never paste, print or
  log a production key or token.
- **No real payment collection.** A fake door may collect a waitlist email only with
  explicit consent and a stated deletion date, and its follow-up says honestly that
  the feature is not available yet.
- **Never deployed to production domains** or shared infrastructure. A preview
  deploy for remote sessions runs on a throwaway URL, is marked `noindex`, and is
  torn down when the sessions end.

## When a Prototype Proves Out
If the verdict is PROCEED and the capability moves into the product:
1. The prototype code is NOT migrated — the capability is rebuilt from scratch to
   production standards in the declared code roots.
2. The `REPORT.md` findings inform the product brief, the feature map and the PRDs.
3. The prototype directory is kept for reference and never extended.

## Cleanup
Concluded prototypes are archived or deleted once their record is written.
Never let prototype code grow into production code through incremental "cleanup".
