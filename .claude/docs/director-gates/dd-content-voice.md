> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# DD-CONTENT-VOICE — Content Voice & Terminology Consistency

Agent: `design-director` | Model tier: inherit | Domain: Content voice & terminology

**Trigger**: Spawned by `/team-content` after the copy drafts are written and before
they go to localization. It reviews microcopy, notifications (push, email, SMS,
알림톡), help-center articles and store text against the voice-and-tone profile and
the product glossary.

**Context to pass**:
- content file paths under review
- `design/brand/voice-and-tone.md` path
- `design/registry/entities.yaml` path
- `localization.locales` value (or "unset")

**Prompt**:
> "Review this content for voice, tone and terminology consistency before it is
> localized. Read the content files, the voice-and-tone profile and the glossary
> registry at the paths given. Check:
>
> 1. **Voice** — the copy sounds like the profile. For Moa: warm and encouraging,
>    never guilt-tripping, plain words over banking jargon, and in Korean the polite
>    해요체 used consistently rather than mixed with 합니다체 on the same screen.
> 2. **Tone by situation** — the tone shifts the profile prescribes for success,
>    error, payment failure, account deletion and legal notices are applied (a failed
>    automatic debit is calm and actionable, never alarming or blaming).
> 3. **Terminology** — every product term matches the registry (`entities`, `plans`,
>    `rules`, `constants`, `events`): the plans are `Free` and `Plus`, a 'goal' is
>    never also called a 'pocket' or 'savings box', and the same concept has one name
>    across UI, notifications, help center and store listing.
> 4. **Clarity** — error messages say what happened and what to do next; empty states
>    help the user take the first step; numbers, dates and currency follow the locale
>    (`12,000원`, `2026년 10월 25일`).
> 5. **Channel fit** — push titles and bodies fit before truncation on both
>    platforms; each message sits on the right channel (알림톡 carries informational
>    messages only; marketing content needs the channel and consent rules of each
>    configured region's `.claude/docs/compliance/<region>.md`
>    `## Marketing Messages & Consent`).
> 6. **Localization readiness** — no concatenated sentences, ICU placeholders and
>    plural forms instead of hand-built strings, room for text expansion, no text
>    baked into images, context notes for translators on ambiguous strings.
> 7. **Store and help-center claims** — store text and help articles make no promise
>    the product does not keep (no 'guaranteed returns', no unverifiable 'safest'),
>    and agree with the in-app copy and the release notes.
>
> Return APPROVE, CONCERNS [the specific strings or articles to revise, with a
> suggested rewrite], or REJECT [content that contradicts the voice profile or the
> glossary in ways that would confuse users or create a compliance risk — resolve
> before localization]."

**Verdicts**: APPROVE / CONCERNS / REJECT

The first line of the reply is exactly `[DD-CONTENT-VOICE]: <TOKEN>` with one token
from the line above; the spawning skill parses it. Findings follow the first line.

**Special handling**:
- Not a legal review. Marketing-consent and channel items are confirmed by the user
  in `/team-content`'s consent & channel check; this gate only flags content that
  appears to conflict with them.
- `localization.locales` "unset" is not "single locale": review the source locale
  and report item 6 as `NOT CHECKED — locales unset`. Customer-facing copy is judged
  in the locale it ships in, whatever the conversation language.
- If `design/brand/voice-and-tone.md` does not exist, review terminology and clarity
  only, report `NOT CHECKED — voice (no voice-and-tone profile)`, and cap the
  verdict at CONCERNS.
