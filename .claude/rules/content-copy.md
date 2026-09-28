---
paths:
  - "design/content/**"
  - "design/brand/voice-and-tone.md"
  - "**/locales/**"
  - "**/*.strings"
  - "**/strings.xml"
  - "**/*.arb"
---

# Content & Copy Rules

These paths hold every word a user reads: copy decks and help-center articles under `design/content/`, the voice
and tone guide `design/brand/voice-and-tone.md`, and the shipped string resources — locale JSON, iOS `.strings`,
Android `strings.xml` and Flutter `.arb` files. Copy ships in the locale(s) it is written for
(`localization.locales`), whatever language the conversation is in.

## Voice and tone

- Write in the voice attributes of `design/brand/voice-and-tone.md` and the tone its `## Tone by Context` section
  sets for the context at hand — success, error, empty, onboarding, billing, incident. A string that needs a tone
  the guide does not cover is a question for the `ux-writer`, not an improvisation.
- Error messages say what happened and what the user can do next, in the user's terms: no blame, no internal codes,
  stack traces or raw API messages. Map each problem-details `code` from the API to a reviewed message.
- Empty states name the next action ("첫 목표를 만들어 보세요"), not just the absence.
- Link and button text makes sense out of context ("자동이체 설정하기", never "여기를 누르세요" / "click here") — screen
  readers list links by their text.
- Korean copy follows the guide's `## Korean Style Notes` (speech level, spacing, number and currency formatting)
  consistently within a surface; never mix 해요체 and 합니다체 on one screen.

## Terminology

- Use exactly the terms in the guide's `## Terminology` table and the names in `design/registry/entities.yaml` —
  one term per concept everywhere: UI, notifications, help center, store listing and support macros. If Moa calls it
  a 목표 (goal), it is never also a 챌린지 or 플랜 elsewhere; plan names (Free / Plus) are never translated or
  paraphrased.
- New copy is checked against existing copy decks and help-center articles for contradictions — the same plan
  name, the same cancellation terms, the same limits everywhere.
- **Prices, limits and dates in copy are placeholders filled from config and data** (`{price}`, `{limit}`), never
  typed into the string: a price change must not require a copy change in five places.
- Legal and billing text (terms, refund and cancellation conditions, auto-debit disclosures, consent text) is
  approved by the owner the PRD names and is never paraphrased in microcopy; link to it instead.
- **Mockup copy is a draft.** Text in a Claude Design or Figma mockup or a `/design` artifact is a draft or
  placeholder; the copy deck under `design/content/` and the message catalogs are final. Engineers wire strings by
  key, never by copying them out of a mockup.

## Plurals, placeholders and concatenation

- **ICU MessageFormat** for plurals, selects and number/date formatting in locale JSON and `.arb` files; platform
  plural resources elsewhere (`<plurals>` in `strings.xml`, plural variations in `.stringsdict` or string catalogs).
  Every plural uses the CLDR categories of each locale (Korean has only `other`; English has `one` and `other`) —
  never `count === 1 ? … : …` in code.
- **Named or numbered placeholders only** (`{planName}`, `%1$s`, `%1$@`) so translators can reorder them; never
  positional `%s` twice in one string.
- **No concatenated strings.** A sentence is one message. Word order differs between languages, and Korean
  particles depend on the preceding word (을/를, 이/가, 은/는, 으로/로), so fragments joined in code break in one
  language or the other. Rephrase to avoid a particle after a placeholder, or use a message that handles it.
- Keys are dotted paths by feature and screen (`goals.create.title`), identical in every locale file; a key missing
  from any shipped locale fails CI (`.claude/rules/data-files.md`).

## Length limits

- Every string that ships into a constrained slot has its limit written next to it in the copy deck: push title and
  body, SMS and LMS, 알림톡 template variables, email subject and preheader, store listing fields (app name,
  subtitle, short description, keywords), button labels and tab titles.
- Limits are taken from the provider's or store's current documentation, or from the design language — never from
  memory. Korean length is counted in characters, and SMS length also in bytes as the provider counts them.
- Design for expansion: copy in other locales (German, French) runs longer than English and Korean. Check layouts
  with pseudo-localization and at the largest text size, not only with the Korean or English source.

## Messages and marketing consent

Every notification template — push, email, SMS/LMS, 알림톡, in-app message — is classified before it is written:

- **Informational** (정보성): about the user's own account or transaction — auto-debit succeeded or failed, goal
  reached, security alerts, receipts, service changes. No promotional content: a coupon or an upsell inside an
  informational message makes the whole message advertising.
- **Advertising** (광고성): promotions, coupons, win-back, upsell, event announcements. Sent only to users with
  recorded advertising consent for that channel, collected separately from the terms of service; carries the
  advertising label, sender identification and a working unsubscribe path in the same channel as the region
  requires; respects separate night-time consent and periodic consent confirmation where the region requires them.
- **알림톡 carries informational messages only**; advertising to KakaoTalk users goes through 친구톡 or brand
  messages with advertising consent. Advertising push needs both the OS notification permission and the
  advertising consent, and users can turn advertising push off separately from service notifications.
- Consent is enforced by the sending code at send time (consent status and channel checked per recipient), not by
  the copy alone. The copy deck records each template's classification and the consent it requires.
- For each region in `compliance.regions`, check the template against `.claude/docs/compliance/<region>.md`
  `## Marketing Messages & Consent`. Label wording, time windows and confirmation intervals come from the sources
  named there — never from memory. `compliance.regions` unset ⇒ ask; unset is not "no rules apply".

## Examples

**Correct** (`apps/web/locales/en-US/goals.json` and `ko-KR/goals.json` — ICU plural, named placeholders, one
message per sentence, limit filled from config):

```json
{
  "goals.list.count": "{count, plural, one {# goal} other {# goals}}",
  "goals.create.limitReached": "You can have up to {limit} active goals on {planName}. Upgrade to Plus for more."
}
```

```json
{
  "goals.list.count": "{count, plural, other {목표 #개}}",
  "goals.create.limitReached": "{planName} 플랜은 목표를 {limit}개까지 만들 수 있어요. 더 만들려면 Plus로 업그레이드하세요."
}
```

**Correct** (copy deck entry for an informational 알림톡 template):

```markdown
### notifications.autodebit.failed — 알림톡 (informational)
- Consent: none beyond the service terms (transaction notice to the account holder)
- Limits: template variables per the provider's approved template; SMS fallback per provider byte limit
- Copy: "[Moa] #{goalName} 자동이체가 실패했어요. 잔액을 확인한 뒤 앱에서 다시 시도해 주세요."
```

**Incorrect**:

```typescript
const msg = t('goals.count.prefix') + count + (count === 1 ? ' goal' : ' goals'); // VIOLATION: concatenation and
                                                                                  //   code-built plural
const notice = `${user.name}님, 자동이체 완료! 지금 Plus 가입 시 첫 달 무료`;          // VIOLATION: hardcoded copy; an upsell
                                                                                  //   inside an informational message,
                                                                                  //   sent to users without ad consent
```
