---
name: localize
description: "i18n pipeline: hardcoded strings, extraction, ICU, cultural review, RTL/CJK checks, string freeze, localization QA."
argument-hint: "[scan|extract|validate|status|brief|cultural-review|rtl-check|freeze|qa]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/localize/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,surfaces,compliance,code_roots,stack`

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

# Localization Pipeline

Localization is not just translation — it is the full process of making a product
feel native in every language and region. Poor localization erodes trust (most of all
where money is involved), confuses users, and can fail store review. This skill covers
the complete pipeline from string extraction through cultural review, RTL and CJK
layout checks, string freeze and localization QA sign-off.

**Modes:**
- `scan` — Find hardcoded strings and localization anti-patterns (read-only)
- `extract` — Extract strings and generate translation-ready catalog entries
- `validate` — Check translations for completeness, placeholders, plurals and length
- `status` — Coverage matrix across all locales
- `brief` — Generate translator context briefing document for an external team
- `cultural-review` — Flag culturally sensitive content, symbols, colours, idioms, claims
- `rtl-check` — Validate RTL language layout, mirroring, and font support
- `freeze` — Enforce string freeze; lock source strings before translation begins
- `qa` — Run the full localization QA cycle before release

If no subcommand is provided, output usage and stop. Verdict: **FAIL** — missing required subcommand.

---

## Phase 1: Inputs

Every mode starts from the same three inputs:

- **Locales** — `localization.locales` has no `resolve_config` label: read it from
  `project.yaml` with Read (a flow list of BCP 47 tags, e.g. `[ko-KR, en-US]`). **Unset ⇒
  ask which locales ship**; unset is not "one locale". The **source locale** is the locale
  the product's copy is written in — for a Korean-market product usually `ko-KR`, not
  English. Confirm it with the user on the first run and state it in every report.
- **Code roots** — the resolved `code_roots` line lists the roots to scan and the file
  extensions to scan in them. Include `undeclared` roots in every scan and print the line
  `WARN: undeclared code roots: <dirs> — declare them with /setup-stack`. **Unresolved ⇒
  print `NOT CHECKED — no code root resolved (set stack.layers.<layer>.root via /setup-stack)`
  and skip the code scan** — zero hits from an unresolved root reads as "nothing to
  localize", which is the failure this guards.
- **Message catalogs** — find them under the code roots by the formats the surfaces use:
  web `messages/<locale>.json`, `locales/<locale>/*.json` or `i18n/**` (next-intl,
  react-intl/FormatJS, i18next, vue-i18n); iOS `*.xcstrings` (String Catalogs) or
  `*.lproj/Localizable.strings`; Android `res/values*/strings.xml`; Flutter `l10n/*.arb`;
  backend message bundles for server-generated text (emails, push, 알림톡, API error
  messages). The resolved `surfaces` line says which of these must exist. Report each
  catalog found with its locale, and each surface that has none.

The copy decks under `design/content/` (written by `/team-content`) are the approved source
wording; the catalogs are what ships. A key whose catalog text differs from its approved
copy-deck text is reported, never silently "fixed" here.

---

## Phase 2A: Scan Mode

Search the **code roots** for hardcoded user-facing strings:

- String literals in UI code not wrapped in a localization function (`t()`, `useTranslations()`, `formatMessage()`, `$t()`, `String(localized:)`, `NSLocalizedString`, `stringResource()`, `getString()`, `AppLocalizations.of(context)`, etc.)
- Concatenated strings that should be one parameterized message
- Strings with positional placeholders (`%s`, `%d`) instead of named ones (`{goalName}`)
- Format strings that mix locale-sensitive data (numbers, dates, currencies) without locale-aware formatting
- Server-generated user-facing text (email and push bodies, 알림톡 templates, API error `detail` strings shown to users) built in code rather than taken from a catalog

Search for localization anti-patterns:

- Date/time formatting not using locale-aware functions (`Intl.DateTimeFormat`, platform formatters, ICU)
- Number and currency formatting without locale awareness (`1,000` vs `1.000`; `12,000원` vs `₩12,000`)
- Text embedded in images (flag image files under the code roots, web `public/` directories and asset catalogs)
- Strings that assume left-to-right text direction (physical `left`/`right` in layout, string assembly order)
- Gender/plurality assumptions baked into string logic (must use ICU plural and select forms)
- Hardcoded punctuation (e.g. `"Saved!"` — exclamation styles vary by locale)

**CJK anti-patterns** (whenever a CJK locale is in `localization.locales`):
- Korean particles hardcoded after a variable (`{goalName}을`) — they depend on the final consonant; rephrase or use a particle helper
- Web body text without `word-break: keep-all` for Korean (words split mid-syllable-block), and long tokens without an `overflow-wrap` fallback
- Enter-to-submit or validation handlers that ignore IME composition (`isComposing` / `compositionend`) — Hangul input submits twice or loses its last syllable
- Web fonts without Hangul coverage, or CJK fonts loaded whole instead of subset by `unicode-range`
- Synthetic bold or italic applied to Hangul instead of real font weights

Report all findings with file paths and line numbers. This mode is read-only — no files are written.

---

## Phase 2B: Extract Mode

- Scan all source files under the code roots for localized string references
- Compare against the existing source-locale catalog of each surface
- Generate new entries for strings not yet keyed
- Suggest key names following the convention `<feature>.<screen-or-context>.<element>` — namespaced by meaning, never by position
  - Example: `goals.create.submit_button`, `notifications.autodebit.failed.title`, `errors.payment.card_expired`
- Each new entry must include a `context` field (or the format's comment/description slot) — a translator comment explaining:
  - Where it appears (which screen, which state)
  - Maximum character length
  - Any placeholder meaning (`{goalName}` = the name the user gave the savings goal)
  - Gender/plurality context if applicable

Spawn `ux-writer` via `Agent` for new keys whose source text was written by an engineer
rather than taken from an approved copy deck: it proposes the source wording in the voice of
`design/brand/voice-and-tone.md` and the translator context. Return contract: no file —
return the proposed wording and context per key inline.

Output a diff of new entries to add to each catalog.

Present the diff to the user. Ask: "May I write these new entries to `<source-locale catalog path>`?" (e.g. `apps/web/messages/ko-KR.json`) — one question per catalog.

If yes, write only the diff (new entries), not a full replacement: existing entries keep their keys, values and order. Verdict: **COMPLETE** — strings extracted and written.

---

## Phase 2C: Validate Mode

Read every message catalog found in Phase 1. For each locale, check:

- **Completeness** — key exists in the source locale but no translation for this locale
- **Placeholder mismatches** — source has `{name}` but translation omits it or adds extras
- **String length violations** — translation exceeds the character limit recorded in the source `context` field
- **Plural and select forms** — the translation provides the CLDR plural categories its locale needs (`ko`, `ja`, `zh`: `other` only; `en`: `one`, `other`; `ru`, `pl`: more), and ICU syntax parses
- **Orphaned keys** — translation exists but nothing in the code roots references the key
- **Stale translations** — source string changed after translation was written (flag for re-translation)
- **Encoding and glyphs** — non-ASCII characters present and the shipped fonts cover them (flag if uncertain)
- **Store listing fields** — for `ios` / `android` surfaces, each locale's App Store and Google Play listing text fits its field limits (the table under `### Store listings and notification templates` in `.claude/agents/localization-lead.md`)

Report validation results grouped by locale and severity. This mode is read-only — no files are written.

---

## Phase 2D: Status Mode

- Count total localizable strings in the source-locale catalogs
- Per locale: count translated, untranslated, stale (source changed since translation)
- Generate a coverage matrix:

```markdown
## Localization Status
Generated: [Date]
Source locale: [locale]
String freeze: [Active / Not yet called / Lifted]

| Locale | Total | Translated | Missing | Stale | Coverage |
|--------|-------|-----------|---------|-------|----------|
| [source locale] | [N] | [N] | [N] | [N] | [N]% |

> **Every cell above is a count you must take from the message catalogs — including
> the source row.** Do not pre-fill the source locale as `100%`: that asserts a
> result before counting, and on a project with no message catalog it
> produces a coverage report for a catalog that does not exist. If no catalog
> is found, the whole status output is
> **`NOT ASSESSED — no message catalog found`**, not a matrix of zeros with a
> confident source row.
| [locale] | [N] | [N] | [N] | [N] | [X]% |

### Issues
- [N] hardcoded strings found in source code (run /localize scan)
- [N] strings exceeding character limits
- [N] placeholder mismatches
- [N] orphaned keys
- [N] strings added after freeze was called (freeze violations)
```

This mode is read-only — no files are written.

---

## Phase 2E: Brief Mode

Generate a translator context briefing document. This document is sent to the
external translation team or localization vendor (or attached to the TMS project) alongside
the catalog export.

Read:
- `design/product/product-brief.md` (or `design/product/one-pager.md`) — extract the product, its category, audience and markets
- `design/brand/voice-and-tone.md` — voice attributes, tone by context, terminology, Korean style notes
- `design/registry/entities.yaml` — product terms and plan names
- The source-locale catalogs and the copy decks under `design/content/`

Spawn `ux-writer` via `Agent` to draft the Tone and Voice section from the voice-and-tone
guide (return contract: no file — the section inline).

Generate `production/localization/translator-brief-[locale]-[date].md`:

```markdown
# Translator Brief — [Product Name] — [Locale]

## Product Overview
[2-3 paragraph summary of the product, its category, the users it serves, and what they use it for]

## Tone and Voice
- **Overall tone**: [e.g., "Warm and encouraging, never guilt-tripping about money — a coach, not a bank"]
- **User address**: [e.g., "Polite and friendly (해요체) in the interface; formal (합니다체) in legal notices. For ja-JP use です/ます"]
- **Money and legal wording**: [e.g., "Translate amounts, dates, fees and cancellation terms exactly — never soften or round them. Terms of Service and Privacy Policy are not translated from this catalog; they come from legal review per locale"]
- **Slogans**: [e.g., "Marketing lines in the store listing may be transcreated; interface strings are translated for clarity, not wit"]

## Product Glossary
| Term | Meaning | Notes |
|------|---------|-------|
| [Term] | [What it means in this product] | [Translate as X / keep in source language] |

## Do Not Translate List
The following must appear verbatim in all locales:
- [Product name]
- [Plan names, if kept in the source language]
- [Brand and partner names — e.g. Kakao, Naver, Toss Payments, Apple Pay]
- [Platform terms that must match OS labels — e.g. Face ID, App Store]

## Placeholder Reference
| Placeholder | What it represents | Example |
|-------------|-------------------|---------|
| `{goalName}` | Name the user gave a savings goal | "여름 여행" |
| `{amount}` | Pre-formatted currency amount — do not add a currency symbol | "12,000원" |
| `{count}` | Integer quantity (ICU plural) | "3" |

## Character Limits
Tight UI fields with hard limits are marked in the catalog `context` field.
Where no limit is stated, target ±30% of the source length as a guideline.

## Contact
Direct questions to: [placeholder for user/team contact]
Delivery format: the same format as the source catalog (JSON, XLIFF from the TMS, .xcstrings, strings.xml or ARB)
```

Ask: "May I write this translator brief to `production/localization/translator-brief-[locale]-[date].md`?"

---

## Phase 2F: Cultural Review Mode

Spawn `localization-lead` via `Agent`. Ask them to audit the following for cultural sensitivity across the target locales (read from the message catalogs, the copy decks under `design/content/`, the store listing text and the images the screens use):

### Content Areas to Review

**Symbols and gestures**
- Thumbs up, OK hand, peace sign — meanings vary by region
- Religious or spiritual symbols in illustrations, icons or empty states
- National flags, map representations, disputed territories and place names

**Colours**
- Red and blue for gains and losses — in Korean and Chinese finance interfaces red commonly marks a rise, the reverse of US convention; check every money-movement colour per locale
- White (mourning in some Asian cultures), green (political associations in some regions), red (luck vs danger)
- Alert/warning colours that conflict with cultural associations

**Numbers and dates**
- 4 (associated with death in Korean, Japanese and Chinese), 13, 666 — flag use in promotional prices, plan names or default values
- Holidays and payment timing (Lunar New Year, Chuseok, Golden Week) in scheduled messages and debit dates

**Humour and idioms**
- Idioms that translate as offensive in other locales
- Jokes in empty states or errors that land badly where money, health or loss is involved
- Humour around topics that are culturally sensitive in specific regions

**Regulated claims and legal text**
- Financial, health or comparative claims ("guaranteed", "safest", "No. 1") that a locale's rules restrict — check against `.claude/docs/compliance/<region>.md` for each region in the resolved `compliance` line
- Legal notices, consent wording and advertising-message labels that must come from legal review per region, not from translation

**Names and representations**
- Persona names, sample data (names, addresses, phone numbers) in screenshots and empty states — fictional and locale-appropriate
- Stereotyped representation of nationalities, religions, or ethnic groups

Present findings as a table:

| Finding | Locale(s) Affected | Severity | Recommended Action |
|---------|--------------------|----------|--------------------|
| [Description] | [Locale] | [BLOCKING / ADVISORY / NOTE] | [Change / Flag for review / Accept] |

BLOCKING = must fix before shipping that locale. ADVISORY = recommend change. NOTE = informational only.

Ask: "May I write this cultural review report to `production/localization/cultural-review-[date].md`?"

---

## Phase 2H: RTL Check Mode

Right-to-left languages (Arabic, Hebrew, Persian, Urdu) require layout mirroring beyond
just translating text. This mode validates the implementation. When no RTL locale is in
`localization.locales`, say so and stop: `NOT CHECKED — no RTL locale configured`.

Determine the frameworks: the resolved `surfaces` line, plus the web and mobile components
of the resolved `stack` line (a layer under `unset=` or `stack: unset` ⇒ ask; do not infer
from file extensions alone). Then check:

**Layout mirroring**
- Is RTL layout enabled? (web: `dir` set from the locale on `<html>`; Android: `android:supportsRtl="true"`; iOS: semantic content attributes left automatic; Flutter: `Directionality` from the locale; React Native: `I18nManager` configured)
- Are containers laid out with logical start/end properties, or are positions hardcoded left/right?
- Do progress rings, sliders, carousels, back arrows and directional icons mirror correctly?

**Text rendering**
- Are fonts loaded that support Arabic/Hebrew character sets?
- Is Arabic text rendered with correct ligatures (connected script)?
- Are numbers displayed as Eastern Arabic numerals where required?

**String assembly**
- Are there any string concatenations that assume left-to-right reading order?
- Do `{placeholder}` positions in sentences work correctly when sentence structure is reversed, and are mixed-direction values (amounts, IDs, URLs) isolated for bidi?

**Asset review**
- Are there UI icons with directional arrows or asymmetric designs that need mirrored variants?
- Do any text-in-image assets exist that require RTL versions?

Grep patterns to check (in the code roots):
- Physical properties in styles: `margin-left`, `padding-right`, `left:`, `text-align: left` (web); `marginLeft`, `paddingRight` (React Native); `layout_marginLeft`, `gravity="left"` (Android XML); `EdgeInsets.only(left:` (Flutter)
- Directional icons referenced by name (`arrow_left`, `chevron.right`)
- String concatenation with `+` near UI or message code

Report findings. Flag BLOCKING issues (content unreadable without fix) vs ADVISORY (cosmetic improvements).

Ask: "May I write this RTL check report to `production/localization/rtl-check-[date].md`?"

---

## Phase 2I: Freeze Mode

String freeze locks the source-locale catalogs so that translations can proceed
without the source changing under the translators. Mobile apps freeze per release train
(a store build cannot pick up late strings); web freezes before each major launch.

### freeze call

Check current freeze status in `production/localization/freeze-status.md` (if it exists).

If already frozen:
> "String freeze is currently ACTIVE (called [date]). [N] strings have been added or modified since freeze. These are freeze violations — they require re-translation or an approved freeze lift."

If not frozen, present the pre-freeze checklist:

```
Pre-Freeze Checklist
[ ] All planned UI screens are implemented
[ ] All copy decks under design/content/ for this release are Approved (no further copy revisions planned)
[ ] All system strings (error messages, onboarding, notification and email templates) are complete
[ ] /localize scan shows zero hardcoded strings
[ ] /localize validate shows no placeholder mismatches in the source locale
[ ] Store listing text and release-note wording are final
```

Use `AskUserQuestion`:
- Prompt: "Are all items above confirmed? Calling string freeze locks the source catalogs."
- Options: `[A] Yes — call string freeze now` / `[B] No — I still have strings to add`

If [A]: ask "May I write this to `production/localization/freeze-status.md`?" and write:

```markdown
# String Freeze Status

**Status**: ACTIVE
**Called**: [date]
**Called by**: [user]
**Release**: [version or train]
**Total strings at freeze**: [N]

## Post-Freeze Changes
[Any strings added or modified after freeze are listed here automatically by /localize extract]
```

### freeze lift

If argument includes `lift`: ask "May I write this to `production/localization/freeze-status.md`?", then rewrite it with Status `LIFTED`, the reason and the date. Warn: "Lifting the freeze requires re-translation of all modified strings. Notify the translators and the TMS project."

### freeze check (auto-integrated into extract)

When `extract` mode finds new or modified strings and `freeze-status.md` shows Status: ACTIVE — append the new keys to `## Post-Freeze Changes` (after "May I write this to `production/localization/freeze-status.md`?") and warn:
> "⚠️ String freeze is active. [N] new/modified strings have been added. These are freeze violations. They need the release-manager's and the product-manager's approval and a confirmed translation turnaround before this release."

---

## Phase 2J: QA Mode

Localization QA is a dedicated pass that runs after translations are delivered but
before any locale ships. This is not the same as `/localize validate` (which checks
completeness) — this is a structured, screen-by-screen quality check on real builds.

Spawn `localization-lead` via `Agent` with:
- The target locale(s) to QA
- The list of all screens and flows in scope (from the UX specs under `design/ux/`, `design/inventory/screen-inventory.md`, or `/feature-audit` output)
- The current `/localize validate` report
- The cultural review report (if it exists)
- The regions in the resolved `compliance` line and the surfaces in the resolved `surfaces` line

Ask the localization-lead to produce a QA plan covering:

1. **Functional string check** — every string displays on every surface without truncation, raw keys, placeholder errors, or encoding corruption
2. **UI overflow check** — translated strings that exceed UI bounds at every breakpoint and on small phones (even if within character limits, some languages expand)
3. **Contextual accuracy** — a sample of 10% of strings reviewed in the running product for translation accuracy and natural phrasing, by a fluent reviewer
4. **Cultural review items** — verify all BLOCKING items from the cultural review are resolved
5. **Formatting, input and typography** — plurals and placeholders render for 0, 1 and many; dates, numbers and currency match CLDR; sorting and search behave for the locale (Hangul order, initial-consonant search where offered); IME input works; CJK line breaking and fonts render correctly on real iOS and Android devices at the largest text size; notification and email templates render with real-length data
6. **Store & legal requirements** — store listing fields per locale within limits and localized screenshots; legal notices, consent wording and advertising-message labels per region (from each `.claude/docs/compliance/<region>.md`) prepared by legal review

Write one report for all locales in scope, with the overall verdict directly under the H1:

```markdown
# Localization QA Report — [YYYY-MM-DD]

> **Verdict**: [PASS / PASS WITH CONDITIONS / FAIL / NOT ASSESSED]

**Source locale**: [locale]
**Locales in scope**: [locales]
**Build / environment**: [web build or URL, app version and build number per platform]
**Reviewed by**: localization-lead
**Date**: [date]

## Localization QA Verdict — [Locale]

**Status**: PASS / PASS WITH CONDITIONS / FAIL / NOT ASSESSED

### Findings
| ID | Area | Description | Severity | Status |
|----|------|-------------|----------|--------|
| LOC-001 | UI Overflow | "[Button label]" overflows on [Screen] at the smallest breakpoint | BLOCKING | Open |
| LOC-002 | Translation | [Key] translation is literal — sounds unnatural | ADVISORY | Open |

### Conditions (if PASS WITH CONDITIONS)
- [Condition 1 — must resolve before ship]

### Sign-Off
[ ] All BLOCKING findings resolved
[ ] delivery-manager approves shipping [Locale]
```

Repeat the `## Localization QA Verdict — [Locale]` block per locale. A locale whose checks
could not run (no build for that surface, no fluent reviewer, translations not delivered)
is **NOT ASSESSED** with the reason — never PASS. The overall verdict is the worst locale
verdict, ranked **FAIL > NOT ASSESSED > PASS WITH CONDITIONS > PASS**: a known failure
outranks an unknown, and an unknown outranks a pass.

Ask: "May I write this localization QA report to `production/qa/localization-qa-YYYY-MM-DD.md`?"

**Gate integration**: `/gate-check launch` requires this report (`production/qa/localization-qa-*.md`) when more than one locale ships (*Multi-locale* — `localization.locales` has two or more entries). A FAIL blocks launch for that locale only — other locales may still proceed if their QA passes.

---

## Phase 3: Rules and Next Steps

### Rules
- The source locale is the locale the copy is written in; every other locale translates from it
- Every catalog entry must include a `context` field with translator notes, character limits, and placeholder meaning
- Never modify translation files directly — generate diffs for review
- Character limits must be defined per UI element and enforced in validate mode
- ICU MessageFormat for plurals, selects and formatted values; CLDR data for dates, numbers and currency — never hand-built
- String freeze must be called before sending strings to translators — never translate a moving target
- RTL support must be designed in from the start — retrofitting RTL layout is expensive
- Cultural review is required for any locale where the product will be sold or marketed commercially
- Machine and LLM translation is post-edited by a fluent reviewer before it ships

### Recommended Workflow

```
/localize scan            → find hardcoded strings
/localize extract         → build the source-locale catalogs
/localize freeze          → lock source before sending to translators
/localize brief           → generate translator briefing document
[Send to translators / TMS]
/localize validate        → check returned translations
/localize cultural-review → flag culturally sensitive content
/localize rtl-check       → if shipping Arabic / Hebrew / Persian / Urdu
/localize qa              → full localization QA pass
```

After `qa` returns PASS for all shipping locales, `/gate-check launch` finds the report under `production/qa/`. New or changed source copy goes through `/team-content <area>` before the next `extract`.
