# Release Notes: [Product] [x.y.z]

**Version**: [x.y.z] · **Release date**: [YYYY-MM-DD]
**Source**: `docs/CHANGELOG.md` `## [x.y.z]` — [N] of [M] commits in the range are customer-facing
**Locales**: [ko-KR, en-US] (`localization.locales`)
**Channels**: [In-App / Web · App Store · Google Play · API / Developers] — omitted: [channel — reason, e.g. "App Store, Google Play — release.distribution is 'web'"]
**Style**: [brief | detailed | full]
**Gaps**: [none | channel or locale that could not be completed — reason]

<!--
How to fill this template (read by /release-notes; delete these comments in the written file):
- One locale block per entry of `localization.locales`, in that order. A block starts with the
  `> **Locale**:` line and contains the headings below in this order. Headings stay in English exactly
  as written; the text under them is written in the block's locale.
- Content sections (Highlights … Known Issues) with nothing to say carry the single line
  "None in this release." in the block's language — never delete the heading.
- Channel sections (In-App / Web … API / Developers) appear only when the channel applies:
  App Store and Google Play only when release.distribution is `stores` or `web+stores`;
  API / Developers only when `api` is in platform.surfaces. An omitted channel is named on the
  **Channels** line above.
- Customer copy never contains ticket IDs, file paths, sprint numbers, commit hashes or people's names.
-->

---

> **Locale**: [ko-KR]

## Highlights

[One or two sentences on the change users will care about most. This line is what store update
notifications and the in-app "What's new" card show first.]

## New

- **[Feature name]**: [What the user can now do, and the benefit — one sentence. Name the plan when the
  feature is not on every plan.]

## Improved

- **[Area]**: [What got better from the user's point of view — faster, clearer, fewer steps. Quote a
  number only when it was measured.]

## Fixed

- [The symptom the user experienced, fixed — e.g. "Fixed an issue where the savings goal progress did not
  update after an automatic transfer." Describe the symptom, never the code.]

## Security

- [A security or privacy improvement described without exploit detail — e.g. "Strengthened protection of
  your sign-in session." Coordinate wording and timing with security-engineer.]

## Changes to Plans & Pricing

| Plan | What changes | Before | After | Effective |
|---|---|---|---|---|
| [Plus] | [monthly price / limit / entitlement] | [KRW 4,900] | [KRW 5,900] | [YYYY-MM-DD] |

[Who is affected, what existing subscribers keep and until when, and how to cancel or change plans. Follow
the regional notice items of the release checklist before publishing.]

## Deprecations

- **[Feature or version]**: [What is being retired, when, and what to use instead.]

## Known Issues

- **[Issue]**: [What the user may notice, and a workaround if one exists. "We're working on a fix." — no
  dates promised.]

## In-App / Web

[The copy for the in-app "What's new" screen and the web changelog page: the Highlights sentence, three to
five bullets drawn from the sections above, and a link to the help-center article when one exists.]

## App Store

[The "What's New in This Version" text for this locale — plain text, at most 4000 characters. No markdown,
no links that need rendering, no mention of other mobile platforms. Character count: [n] / 4000]

## Google Play

[The release-notes text for this language — plain text, at most 500 characters. Play Console takes all
languages in one field as `<ko-KR>…</ko-KR>` blocks; this section holds this language's text only.
Character count: [n] / 500]

## API / Developers

- **Breaking**: [change — affected operations — migration steps — link to `docs/api/guides/[slug].md`]
- **New**: [operation or field added]
- **Deprecated**: [operation or field — `Sunset` date — replacement]
- **API version**: [e.g. `/v1` unchanged]

---

> **Locale**: [en-US]

[Repeat every heading above, in the same order, written in this locale.]
