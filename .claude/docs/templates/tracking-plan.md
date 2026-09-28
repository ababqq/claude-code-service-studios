# Tracking Plan: [Product Name]

> **Owner**: analytics-engineer
> **Last Updated**: [YYYY-MM-DD]
> **Analytics Stack**: [e.g. Amplitude + BigQuery via server-side collection — or "not chosen yet"]

<!--
TEMPLATE NOTES — delete this comment block in the written plan.

Lives at design/product/tracking-plan.md — the single catalogue of analytics events
for the product.
- /write-prd creates it from this template when absent and appends each PRD's events
  after that PRD's "## Success Metrics & Instrumentation" section is approved
  (Owner PRD = that PRD's path, Status = Planned).
- /team-growth adds experiment exposure and variant events.
- /story-done checks that the events a story names exist here; /launch-checklist
  verifies the instrumentation before launch.

Keep the four "##" headings and the Events table header exactly as written — skills
match on them. Never delete an event row: set its Status to Deprecated, so history in
dashboards stays readable. One row per event name; a second PRD that uses an event
another PRD owns references it in its own PRD and leaves this row alone.
-->

## Naming Convention

[The convention every event and property follows. It comes from `naming.events` in `project.yaml`; when that key is
unset, propose one, confirm it with the user and record it here — the user sets the key itself with `/settings`.
Never mix two conventions in one plan.]

- **Events**: [e.g. `object_action`, snake_case, past tense — `goal_created`, `auto_debit_failed`]
- **Properties**: [e.g. snake_case; money as integer KRW with a `_krw` suffix; timestamps ISO 8601 in UTC; IDs as
  opaque strings]
- **One event per meaningful action**: variations are properties, not new events (`goal_created` with
  `source=onboarding`, not `goal_created_from_onboarding`).
- **Who emits**: money, subscription and state changes are emitted by the server after they commit; UI interactions
  are emitted by the client.
- **Standard context** (sent with every event, not repeated per row): platform, app version, pseudonymous user ID,
  anonymous or device ID, session ID, UTC timestamp, plan, locale.
- **Experiments**: exposure is its own event (`experiment_exposed` with `experiment_key`, `variant`).

## Events

[One row per event. `Properties` lists name (type), with enumerated values in parentheses. `PII` is `No`, or `Yes —
<field and classification>` together with the consent basis recorded in the owning PRD's `## Non-Functional
Requirements`; never email, phone, name, resident registration number (주민등록번호), card data or precise location
without it. `Owner PRD` is the PRD that defined the event. `Status` is one of:
`Planned` (defined, not yet emitted) · `Implemented` (emitted by shipped code) · `Verified` (instrumentation QA
passed: fires once per trigger, properties typed, checked in a non-production analytics project) · `Deprecated`
(no longer emitted; kept for history).]

| Event | Trigger | Properties | PII | Owner PRD | Status |
|---|---|---|---|---|---|
| goal_created | server commits a new goal | goal_id (string), target_amount_krw (int), target_date (date), source (onboarding \| home \| suggestion) | No | `design/prd/goals.md` | Planned |
| goal_limit_reached | goal creation blocked by the plan's active-goal limit | plan (free \| plus), active_goal_count (int) | No | `design/prd/goals.md` | Planned |
| auto_debit_failed | payment webhook reports a failed debit | goal_id (string), attempt (int), failure_code (string) | No | `design/prd/payments.md` | Planned |

## User Properties

[Attributes stored on the user profile in analytics destinations — set once or updated on change, never sent as
free text.]

| Property | Type | Values | PII | Set When | Owner PRD |
|---|---|---|---|---|---|
| plan | string | free \| plus | No | sign-up; every plan change | `design/prd/subscription.md` |
| signup_method | string | email \| kakao \| naver \| apple | No | sign-up | `design/prd/auth.md` |
| marketing_opt_in | boolean | true \| false | No | consent screen; settings change | `design/prd/notifications.md` |

## Destinations

[Where events go, what each destination receives, and the consent and data-residency rules that apply. Collection
that needs consent (App Tracking Transparency for cross-app tracking on iOS, cookie consent in the EU, separate
consent for overseas transfer of personal information under Korea's PIPA) is gated before the first event fires.
User-deletion requests must reach every destination listed here.]

| Destination | Type | Events Sent | Consent Required | Region / Residency | Owner |
|---|---|---|---|---|---|
| [e.g. Amplitude] | product analytics | [all Verified events] | [cookie consent (EU); ATT only for cross-app tracking] | [US or EU data center] | [analytics-engineer] |
| [e.g. BigQuery] | warehouse | [all events, server-side] | [covered by the privacy policy] | [asia-northeast3 (Seoul)] | [data-engineer] |
