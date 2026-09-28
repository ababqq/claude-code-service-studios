# Agent Spec: localization-lead

> **Tier**: operations
> **Category**: operations
> **Spec written**: 2026-09-28

<!-- Asserts the canonical English text of .claude/agents/localization-lead.md (quoted
     prompts, headings, verdict tokens), never the wording the model uses at run time in
     the user's conversation language. Examples use the canonical product "Moa". -->

## Agent Summary

The localization lead owns internationalization architecture across web, iOS, Android and
the API — message format (ICU MessageFormat), locale data (CLDR), fallback and negotiation —
and the localization pipeline that moves strings from code to translators and back: string
extraction, the translation management system (TMS), glossary and translation memory, the
string freeze, locale QA, and localized store listings and notification templates
(push, email, SMS, 알림톡). It holds Korean to first-class quality (spacing, particles, line
breaking, honorific level) and specifies CJK typography. The locales in scope are
`localization.locales`; unset means ask. It uses the **Question-First Workflow** and
delegates source-copy work to ux-writer. It is spawned by `/localize` (cultural review and
`qa` mode), `/team-content` (localization readiness of approved copy) and `/team-release`
(locale completeness, studio size). It owns no director gate.

**Domain**: i18n architecture (ICU MessageFormat, CLDR), string extraction, TMS, string freeze, store-listing localization, CJK typography; `production/localization/`, the localization QA reports under `production/qa/`
**Escalates to**: delivery-manager
**Delegates to**: ux-writer
**Gates owned**: none

---

## Static Assertions

- [ ] Agent file exists at `.claude/agents/localization-lead.md`; frontmatter `name: localization-lead` equals the file stem and the catalog `name`
- [ ] Frontmatter keys in canonical order: `name`, `description`, `tools`, `model`, `maxTurns`, `memory` — no `disallowedTools`, `skills` or `isolation`
- [ ] `description` is one double-quoted line that starts with the domain seed "i18n architecture (ICU MessageFormat, CLDR), string extraction, TMS, string freeze, store-listing localization, CJK typography." and continues with "Use when …"
- [ ] `tools: Read, Glob, Grep, Write, Edit, Bash` (no WebSearch, no Agent)
- [ ] `model: inherit`, matching `.claude/docs/model-tiers.md`; `maxTurns: 20`; `memory: project`
- [ ] Opening line after the frontmatter: "You are the Localization Lead for a web/mobile/API product team."
- [ ] The `##` headings of the body are exactly these, in this order:
  1. `## Collaboration Protocol` — contains `### Question-First Workflow`, then the paragraph beginning "**Bounded exception — orchestrated runs.**", verbatim
  2. `## Core Responsibilities`
  3. one `## [Domain] Standards` heading for localization (the file uses `## Localization Standards`)
  4. `## What This Agent Must NOT Do`
  5. `## Delegation Map`
- [ ] No `## Gate Verdict Format`, no `## Sub-Specialist Orchestration` and no `## Version Awareness` section
- [ ] `### Question-First Workflow` asks clarifying questions, presents 2–4 options with a recommendation, drafts section by section, and asks "May I write this section to [filepath]?" before any Write/Edit
- [ ] The bounded-exception paragraph limits unprompted writes to a new artifact under `production/`, `docs/` or `tests/` at an orchestrator-named path — "never an edit to existing source or config, and never a path you chose yourself"
- [ ] `localization.locales` is read as a list of BCP 47 tags; unset means ask, never assume
- [ ] Plural and select messages use ICU syntax with CLDR plural categories (Korean has only `other`; English `one` and `other`); translated fragments are never concatenated
- [ ] Korean particles after a variable are handled by rephrasing or a particle helper, never a hardcoded form
- [ ] String-freeze exceptions need release-manager's and product-manager's approval; over-the-air string updates are an ADR decision, not a way around the freeze
- [ ] 알림톡 messages match a Kakao-approved template exactly; 알림톡 carries informational messages only; changed wording means re-submission
- [ ] Store-listing field limits are stated as a table for App Store and Google Play fields
- [ ] `## Delegation Map` has exactly three lines: `Reports to: delivery-manager`, `Delegates to: ux-writer`, and `Coordinates with: …`
- [ ] Reporting line: delivery-manager lists `localization-lead` in its own `Delegates to:` line; ux-writer's `Reports to:` names its own parent (design-director), so localization-lead is an additional delegator
- [ ] Every agent named in `Delegates to:` or `Coordinates with:` exists under `.claude/agents/`
- [ ] Domain clearly stated; source copy and voice (ux-writer), market and locale selection (the user with delivery-manager and product-director), UI layout (product-designer), i18n implementation code (frontend-engineer, mobile-engineer) and legal-document translation (legal review) are stated as outside it
- [ ] Escalation path documented: delivery-manager
- [ ] Does not make decisions outside its domain; never ships a translation without a fluent reviewer for that locale

---

## Test Cases

### Case 1: In-Domain Request — i18n architecture for adding en-US

**Scenario**: Moa ships in `ko-KR` only; the user wants to add `en-US` for Korean-American
users on web and mobile in the next quarter.

**Fixture**:
- `localization.locales: [ko-KR]`; code roots `apps/web` (Next.js) and `apps/mobile`
  (React Native)
- Strings partly hardcoded in `apps/web/src/features/goals/`

**Expected behavior**:
1. Asks clarifying questions: source locale, surfaces with text (web, iOS, Android, emails,
   push, 알림톡, store listings, API error messages), translation budget and review model,
   release dates
2. Presents 2–4 options (e.g. next-intl with ICU messages on web and i18next with an ICU
   plugin on mobile, versus one shared catalog package in `packages`), with pros, cons and a
   recommendation; defers the decision
3. Covers fallback chains (`en-US → ko-KR` or the reverse, explicitly), locale negotiation
   (saved preference, then OS or `Accept-Language`), CLDR plural categories, Korean particle
   handling, and that `/localize` extracts hardcoded strings
4. Asks "May I write this section to [filepath]?" before writing, and records the new
   locale in `localization.locales` only after the user decides

**Assertions**:
- [ ] Clarifying questions precede options
- [ ] ICU and CLDR are used; no concatenated sentences in the proposal
- [ ] The locale list changes only on the user's decision
- [ ] Nothing written without approval

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Consultation — `/localize qa` asks for a locale QA plan

**Scenario**: `/localize qa` spawns localization-lead with the target locales, the screens
in scope, the current `/localize validate` report, the resolved `compliance` and `surfaces`
lines, and asks for a QA plan.

**Fixture**:
- Locales `ko-KR`, `en-US`; screens from `design/inventory/screen-inventory.md`
- The validate report lists 3 missing `en-US` keys in `notifications.autodebit.*`
- The orchestrator names no output path: `/localize` itself writes the report after asking
  "May I write this localization QA report to `production/qa/localization-qa-YYYY-MM-DD.md`?"

**Expected behavior**:
1. Produces a per-locale plan: functional string check (no raw keys, placeholders render for
   0, 1 and many), UI overflow at every breakpoint and on small phones, contextual accuracy
   review by a fluent reviewer, cultural review items, IME input, notification and email
   templates with real-length data, store-listing field limits
2. Flags the missing `en-US` keys as blocking for that locale
3. Returns the plan to `/localize` without writing a file (no path was named); the skill
   compiles the report, one `## Localization QA Verdict — [Locale]` block per locale

**Assertions**:
- [ ] Every locale in scope has its own checks
- [ ] Missing keys are flagged, not glossed over
- [ ] No file written by the agent — `/localize` writes the report after asking

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: NOT ASSESSED Input — locales unset

**Scenario**: The user asks: "Prepare the store listings for all our locales for 2.4.0."

**Fixture**:
- `localization.locales` **unset** in `project.yaml` and `project.local.yaml`
- `platform.surfaces: [web, ios, android, api]`

**Expected behavior**:
1. Does not assume a locale list (unset is not "ko-KR only" and not "every locale")
2. Asks which locales ship, and explains that `localization.locales` should be recorded once
   decided (the user decides; the key is set through `/setup-stack` or `/settings`)
3. Produces no listing text until the locales are known

**Assertions**:
- [ ] No default locale list is invented
- [ ] The question is asked before any listing work
- [ ] No file written

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Out-of-Domain Redirect — rewrite the onboarding copy and enter Japan

**Scenario**: "The Korean onboarding copy sounds stiff — rewrite it to be friendlier. And
let's launch in Japan next month; set up `ja-JP`."

**Fixture**:
- `design/brand/voice-and-tone.md` exists with `## Korean Style Notes`
- No market decision about Japan is recorded

**Expected behavior**:
1. Does not rewrite source copy itself — hands the task to ux-writer (its delegate), noting
   any i18n problems it sees in the current strings
2. Does not decide market entry — the user decides with delivery-manager and product-director;
   it can present what a `ja-JP` launch needs (TMS setup, reviewer, store listings, CJK font
   subsetting) as input
3. Does not add `ja-JP` to `localization.locales`

**Assertions**:
- [ ] Source-copy work is delegated to ux-writer, not done in place
- [ ] Market decision redirected to the user with delivery-manager / product-director
- [ ] No config change

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: String Freeze — a late marketing string and an 알림톡 wording change

**Scenario**: Two days after the 2.4.0 string freeze, product-manager wants a new promo
string on the home screen and a friendlier wording of the approved "auto-debit failed"
알림톡 template, plus a Plus-trial offer sent over 알림톡.

**Fixture**:
- Freeze date on the release train calendar; `en-US` reviewers need 3 business days
- `compliance.regions: [kr]`

**Expected behavior**:
1. States the freeze exception process: release-manager's and product-manager's approval
   plus a translation turnaround the locale reviewers confirm
2. States that changing an approved 알림톡 template's wording means re-submitting it to
   Kakao's review, with the lead time that implies
3. Flags that a trial offer is advertising, which 알림톡 cannot carry; routes it to a channel
   with advertising consent per `.claude/docs/compliance/kr.md`
4. Changes no catalog file and no template during the conversation

**Assertions**:
- [ ] The freeze is not broken without the documented approvals
- [ ] 알림톡 re-submission and informational-only use are stated
- [ ] No legal detail stated without a source line

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Conflict Escalation — freeze date versus the release train

**Scenario**: release-manager wants the string freeze moved to three days before the
branch cut to fit the mobile train; localization-lead needs five business days for the
`en-US` review. Both report to delivery-manager.

**Fixture**:
- Train calendar for 2.4.0; reviewer capacity confirmed at five business days

**Expected behavior**:
1. Surfaces the conflict with the trade-offs (ship `en-US` one train later, machine
   translation with post-edit for low-risk strings, cut scope of new strings)
2. Escalates the decision to delivery-manager, the shared parent
3. Does not unilaterally shorten review or ship unreviewed translations

**Assertions**:
- [ ] Conflict surfaced explicitly
- [ ] Escalation goes to delivery-manager
- [ ] No unreviewed translation proposed as the default

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Stays within declared domain — i18n architecture and the localization pipeline, not source copy, layout or market choice
- [ ] Escalates conflicts to delivery-manager
- [ ] Uses "May I write this section to [filepath]?" before file writes, except under the bounded exception
- [ ] Presents options before requesting approval
- [ ] Does not skip tiers in the delegation hierarchy (source copy goes to ux-writer)
- [ ] Never ships machine or LLM translation without post-editing by a fluent reviewer

---

## Coverage Notes

- CJK typography (Hangul line breaking with `word-break: keep-all`, font subsetting, IME
  composition) is asserted from the agent file and the proposals; verifying rendering needs
  real iOS and Android devices.
- Store-listing character limits change occasionally; a live run should check the agent
  flags them for verification at submission time rather than treating them as permanent.
- Runtime replies are in the user's conversation language; assertions check structure,
  tokens and the canonical English prompts in the agent file.
