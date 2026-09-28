# Voice & Tone: [Product Name]

> **Status**: Draft | Approved
> **Owner**: ux-writer
> **Last Updated**: [YYYY-MM-DD]
> **Source Locale**: [the locale the copy is written in, e.g. `ko-KR`]
> **Locales**: [the `localization.locales` value from `project.yaml`, or "unset"]

<!--
TEMPLATE NOTES — delete this comment block in the written guide.

Lives at design/brand/voice-and-tone.md — the single source of truth for how the
product sounds. /team-content writes it (ux-writer drafts, the user approves) and
reviews copy against it; the DD-CONTENT-VOICE gate, /localize (translator briefs),
/release-notes and every agent that writes user-facing words read it. The design
language's "## 9. Content & Voice" points here instead of repeating it.

MACHINE CONTRACT — keep the five "##" headings below exactly as spelled, in this
order; skills and gates match on them. Write the body in the team's language;
example strings are written in the locale they ship in.

Examples use Moa, a B2C subscription savings app for the Korean market (web, iOS,
Android). Replace them with the product's own; keep the shape.
-->

## Voice Attributes

[Three or four attributes that stay the same everywhere the product speaks. Each one says
what the voice is, what it is not (the failure mode on either side), and what it sounds
like. Derive them from the product brief's `## Product Principles & Anti-Goals` and the
target users — not from adjectives that fit any product.]

| Attribute | We are | We are not | Sounds like |
|---|---|---|---|
| [e.g. Warm] | [e.g. a friend who is good with money] | [e.g. cutesy, over-familiar, emoji-heavy] | ["이번 달도 목표에 한 걸음 가까워졌어요."] |
| [e.g. Clear] | [plain words, the most important word first] | [banking jargon, vague reassurance] | ["매달 25일에 50,000원이 자동이체돼요."] |
| [e.g. Encouraging] | [celebrates progress, however small] | [guilt-tripping, pushy about upgrades] | ["3번째 저축 완료! 꾸준함이 쌓이고 있어요."] |
| [e.g. Trustworthy] | [exact about money, dates and data] | [stiff, legalistic, over-promising] | ["해지해도 모은 돈은 그대로 남아 있어요."] |

## Tone by Context

[The voice stays constant; the tone moves with the user's situation. For each context:
what the user is feeling, where the tone dial sits, one example in each shipped locale,
and what to avoid. Keep all six contexts; add others (security, account deletion, legal
notices) when the product needs them.]

### Success

- **User state**: [e.g. relieved, pleased — a task just worked]
- **Tone**: [e.g. brief and warm; celebrate milestones, not every tap]
- **Example**: [ko-KR "목표를 만들었어요. 첫 저축은 10월 25일이에요." / en-US "Goal created. Your first deposit is on Oct 25."]
- **Avoid**: [exclamation marks on routine confirmations; fireworks for a settings change]

### Error

- **User state**: [e.g. blocked, possibly anxious if money is involved]
- **Tone**: [e.g. calm, specific, actionable — what happened, why if it helps, what to do now]
- **Example**: [ko-KR "카드 유효기간이 지나 결제하지 못했어요. 카드 정보를 업데이트해 주세요." / en-US "We couldn't charge your card because it has expired. Update your card to keep saving."]
- **Avoid**: [blaming the user, raw error codes, "Something went wrong" with no next step, jokes]

### Empty

- **User state**: [e.g. new or curious — nothing here yet]
- **Tone**: [e.g. inviting; name the value and offer one action]
- **Example**: [ko-KR "아직 목표가 없어요. 첫 목표를 만들어 저축을 시작해 보세요." + button "목표 만들기"]
- **Avoid**: [a blank screen, several competing calls to action, "No data"]

### Onboarding

- **User state**: [e.g. evaluating — will this be worth it?]
- **Tone**: [e.g. confident and brief; explain the benefit before asking for a permission]
- **Example**: [push priming: "저축일에 알려 드릴게요. 알림을 켜면 빠뜨리지 않아요."]
- **Avoid**: [walls of text, asking for every permission up front, promising outcomes]

### Billing

- **User state**: [e.g. careful — money is moving]
- **Tone**: [e.g. exact and neutral: amount, date, recurrence and how to undo, stated before it happens]
- **Example**: [ko-KR "Plus 플랜은 매월 4,900원이며 11월 1일부터 결제돼요. 언제든 해지할 수 있어요."]
- **Avoid**: [hiding the price, guilt at cancellation ("정말 포기하시겠어요?"), pre-checked upsells, urgency that is not real]

### Incident

- **User state**: [e.g. worried the product or their money is not safe]
- **Tone**: [e.g. direct and factual: acknowledge, say what is affected and what is not, what to do, when the next update comes]
- **Example**: [ko-KR "현재 일부 사용자의 자동이체가 지연되고 있어요. 저축한 금액은 안전하며, 오후 3시까지 다시 알려 드릴게요."]
- **Avoid**: [speculating about causes, blaming a partner, "no impact" before it is verified, cheerful tone]

## Terminology

[One term per concept, used identically in the interface, notifications, help center, store
listing and release notes. Every product term here matches the entity and plan names in
`design/registry/entities.yaml`; a new term is added there first. Localized terms are
decided with the localization-lead and carried into each locale's glossary.]

| Concept | Use | Don't use | Notes |
|---|---|---|---|
| [e.g. savings goal] | [목표 / goal] | [저금통, 포켓, plan] | [the entity `goal`] |
| [e.g. recurring transfer] | [자동이체 / auto-debit] | [정기결제, 자동결제] | [money moves from the user's account] |
| [e.g. ending a subscription] | [해지 / cancel your plan] | [탈퇴, 구독 취소] | [탈퇴 means deleting the account — a different action] |
| [e.g. subscription tiers] | [Free, Plus] | [Basic, Premium, 무료회원] | [plan names stay in English in every locale] |

## Do / Don't

[Rules that apply to every surface, with a paired example. Keep it short enough to
remember; the Tone by Context section handles situations.]

| Do | Don't |
|---|---|
| [Name the outcome on buttons — "목표 만들기", "Retry payment"] | [Generic labels — "확인", "OK", "Submit"] |
| [State amount, date and recurrence before money moves] | [Surprise the user after the fact] |
| [Say what to do next in every error] | [Show internal codes or stack traces; a support reference ID is fine] |
| [Write each locale natively and review it separately] | [Translate literally from the source locale] |
| [Keep cancellation as easy to read as sign-up] | [Shame or guilt the user for leaving] |
| [Use named placeholders — `{goalName}`, `{amount}`] | [Concatenate fragments or hardcode particles after variables] |

## Korean Style Notes

[Decisions for Korean copy (also a guide for other CJK locales). Record the choice, not a
survey of options.]

- **존댓말 level**: [e.g. 해요체 for interface copy, push and in-app messages; 합니다체 for
  Terms of Service, Privacy Policy, formal announcements and 알림톡 templates that read as
  notices. Never 반말. Never mix 해요체 and 합니다체 on the same screen.]
- **Addressing the user**: [e.g. no pronoun by default; `{name}님` only in personal messages;
  avoid 고객님 in the interface]
- **Button and label endings**: [e.g. noun or verb-stem labels — "저장", "목표 만들기" — not
  full sentences ("저장하시겠습니까?") on buttons]
- **Spacing (띄어쓰기)**: [e.g. follow 한글 맞춤법 spacing rules; units attach to numbers
  ("12,000원", "3개월"); bound nouns are spaced ("할 수 있어요"); product names keep their
  own spacing]
- **Numbers, dates and currency**: [e.g. "12,000원" in body text, "₩12,000" only where space
  is tight; "10월 25일 (토)"; 24-hour or 오전/오후 — pick one; formatted by CLDR, never by hand]
- **Particles after variables**: [e.g. rephrase to avoid them ("목표 이름: {goalName}") or use
  the particle helper; never hardcode 을/를, 이/가 after a variable]
- **Loanwords and English**: [e.g. 알림 not 노티; 푸시 알림 acceptable; brand and plan names in
  English; follow 외래어 표기법 for anything transliterated]
- **Punctuation and emoji**: [e.g. period at the end of body sentences, none on buttons or
  titles; at most one exclamation mark per screen; no emoji in errors, billing or incident
  copy]
