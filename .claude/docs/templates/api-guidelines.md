# API Guidelines: [Product Name]

> **Status**: Draft | Approved
> **Owner**: [tech-lead or named person]
> **Last Updated**: [YYYY-MM-DD]
> **API Style**: [OpenAPI 3.1 (REST) | GraphQL | gRPC (protobuf) | AsyncAPI (events)] — decided by [ADR-NNNN: title | "no ADR — minimal tier, chosen in /api-design"]
> **Contract**: [`docs/api/openapi.yaml` | `docs/api/schema.graphql` | `docs/api/<service>.proto` | `docs/api/asyncapi.yaml`]
> **Consumers**: [web · ios · android · admin console · partners — from `platform.surfaces`]
> **Public API**: [yes — `api` is in `platform.surfaces` (external consumers; developer guides under `docs/api/guides/`) | no — first-party clients only]

<!--
Template: .claude/docs/templates/api-guidelines.md, written to docs/api/api-guidelines.md by /api-design Phase 2.
Every `##` heading below is a contract: /api-design, tech-lead review and the Public API deprecation check
(`## Deprecation`) look for these exact headings. Keep them in English as spelled; write the body in the
team's language. Replace every [bracketed] choice; delete the "Example (Moa)" lines once real examples exist.
-->

These rules bind every operation in the contract. `/api-design` checks new and changed operations against them,
`tech-lead` reviews against them, and a deviation is allowed only when the change record
(`docs/api/changes/api-change-YYYY-MM-DD.md`) names the rule and the reason.

## Versioning

- **Scheme**: [URL major version (`/v1/...`) | request header (`Api-Version: 2026-11-01`, date-based) |
  no version segment — first-party backend-for-frontend with additive-only evolution]. One scheme for the whole API.
- **The contract is the source of truth.** Handlers are generated from it or verified against it in CI
  (contract drift fails the build); an operation that is not in the contract does not ship.
- **NON-BREAKING (ship any time)**: a new operation; a new optional request field or query parameter; a new
  response field; a new enum value **in a request**; relaxed validation.
- **BREAKING (needs a version bump or a deprecation — see `## Deprecation`)**: a removed field or operation; a type
  change; a new required request field or parameter; enum narrowing; stricter validation; a changed default,
  auth scope, status code, pagination order or error `code`.
- **Watch list (NON-BREAKING by rule, listed in every change record)**: a new enum value **in a response** and a
  new error `code`. Generated mobile clients that switch exhaustively crash or mis-render on unknown values —
  every client must map unknown values to a safe default.
- **Mobile version skew**: iOS and Android builds stay in the field for months. The server keeps serving every
  operation shape that a supported app version calls. Minimum supported app version: [x.y.z per platform] —
  raised only through the force-update path (store build + in-app update prompt), recorded in the release record.
- **Event and webhook payloads** follow the same BREAKING rules and carry a schema version (`[specVersion / type
  suffix]`).

## Resource Naming

- **Paths**: `naming.api_paths` = [`kebab-case`]. Plural nouns for collections (`/goals`, `/payment-methods`),
  one level of nesting at most (`/goals/{goalId}/deposits`), no verbs except for true actions that are not
  CRUD (`POST /subscriptions/{subscriptionId}/cancel`).
- **Fields**: `naming.api_fields` = [`camelCase`]. Timestamps end in `At` (`createdAt`), dates in `Date`
  (`targetDate`), identifiers in `Id` (`goalId`), booleans read as predicates (`isDefault`, `hasPin`).
- **IDs**: opaque strings with a type prefix (`goal_01JBZK4Q7X2M9V5T3R8N6P0H1C`, ULID). Never expose sequential
  integers — they invite enumeration, and an unguessable ID is still not an authorization check.
- **Enum values**: [`lower_snake`] strings (`active`, `paused`, `payment_failed`); never integers.
- **`operationId`**: `verbNoun` in camelCase, unique across the contract (`listGoals`, `createGoal`,
  `cancelSubscription`) — client code generators use it as the method name.
- **Tags**: one per feature, matching the PRD slug (`goals`, `payments`, `notifications`).

| Kind | Rule | Example (Moa) |
|---|---|---|
| Collection | plural noun | `GET /v1/goals` |
| Item | collection + ID | `GET /v1/goals/{goalId}` |
| Sub-resource | one level | `POST /v1/goals/{goalId}/deposits` |
| Action | verb sub-path, POST | `POST /v1/subscriptions/{subscriptionId}/cancel` |
| Current user | `me` alias | `GET /v1/me`, `GET /v1/me/consents` |

## Error Model

- Every 4xx and 5xx response is **RFC 9457 problem details** (`application/problem+json`): `type` (stable URI of
  the problem class), `title`, `status`, `detail`, `instance`, plus the extension members `code` (stable,
  SCREAMING_SNAKE — clients branch on it, never on `title` or `detail`), `errors[]` (field errors with a JSON
  Pointer `pointer`, a `code` and a `detail`) and `traceId`.
- **Status codes**:

| Status | When |
|---|---|
| 400 | malformed body, unknown query parameter or filter, `limit` above the maximum |
| 401 | missing, expired or invalid credentials |
| 403 | authenticated but the scope or role does not allow the operation |
| 404 | the resource does not exist **or is not visible to the caller** (never confirm that another user's object exists) |
| 409 | state conflict; a request with the same `Idempotency-Key` still in flight |
| 410 | the operation or version is past its `Sunset` |
| 412 | `If-Match` precondition failed (optimistic concurrency) |
| 422 | field validation or business-rule failure; `Idempotency-Key` reused with a different body |
| 429 | rate limited (with `Retry-After`) |
| 500 | unexpected error |
| 502 / 503 / 504 | an upstream dependency failed or timed out (payment gateway, identity provider); 503 carries `Retry-After` |

- Bodies never contain stack traces, SQL, internal hostnames, tokens or another user's data. `detail` is written for
  developers; apps show their own localized message per `code`.
- Error codes are documented per operation in the contract; a new code is on the `## Versioning` watch list.
- Example (Moa): `422` with `code: GOAL_LIMIT_REACHED` when a Free-plan user creates a fourth active goal.

## Pagination

- **Default: cursor pagination** for every list a user scrolls — `?cursor=<opaque>&limit=<n>`, default `limit`
  [20], maximum [100]; above the maximum ⇒ 400 (never a silent cap).
- Response envelope: `{ "data": [...], "page": { "nextCursor": "<opaque or null>", "hasMore": true } }`.
- The cursor encodes the sort key **plus a unique tiebreaker** (`createdAt`, `id`) so pages stay stable when rows
  are inserted; it is opaque (base64url) and clients never build or parse it.
- **Offset pagination** (`page`, `pageSize`) only for admin-console tables that need page jumps and totals;
  totals are computed only when the data model's access pattern says the count is cheap.
- Every list operation states its default sort in its description and in the contract.

## Filtering & Sorting

- Filters are explicit, allowlisted query parameters (`?status=active&createdAfter=2026-10-01T00:00:00Z`); no generic
  query language on a Public API. An unknown filter or value ⇒ 400, never silently ignored.
- Sorting: `sort=<field>` ascending, `sort=-<field>` descending, comma-separated for several keys
  (`sort=-createdAt,name`); only fields listed in the operation are sortable, each backed by an index in
  `docs/data/data-model.md` `## Indexes & Access Patterns`.
- Free-text search (`q=`) only where a search index exists; Korean text needs a morphological or n-gram analyzer —
  record which one in the data model.
- Range filters use `...After` / `...Before` (instants) and `...From` / `...To` (dates), inclusive lower bound,
  exclusive upper bound.

## Idempotency Keys

- `Idempotency-Key` request header (client-generated UUID or ULID) is **required** on every unsafe request that
  moves money or has an external side effect, and **accepted** on every other `POST`.
  Example (Moa): `POST /v1/goals/{goalId}/deposits`, `POST /v1/subscriptions`, `POST /v1/payment-methods`.
- The server stores the key with a fingerprint of the request (method, path, body hash, caller) and the response
  for [24 hours]:
  - same key, same fingerprint ⇒ replay the stored response (same status and body);
  - same key, different fingerprint ⇒ 422 with `code: IDEMPOTENCY_KEY_REUSED`;
  - same key while the first request is still running ⇒ 409 with `code: REQUEST_IN_PROGRESS`.
  This follows the IETF HTTPAPI `Idempotency-Key` header draft and the behaviour of widely used payment APIs.
- `PUT` and `DELETE` are idempotent by semantics; `PATCH` is not — use `If-Match` with an `ETag` where lost updates
  matter.
- Calls to a payment gateway carry their own idempotency key derived from ours, so a retried request never
  charges twice (Stripe and Toss Payments accept an `Idempotency-Key` header — confirm the current behaviour in
  the gateway's documentation and record the source in the PRD).
- Inbound webhooks (payment results, 알림톡 delivery reports) are deduplicated on the provider's event ID.

## Rate Limits

- Limits apply per [access token / user] and per client IP; stricter classes for authentication and messaging
  operations (sign-in, OTP and SMS sends, password reset) and for expensive exports.
- Exceeding a limit ⇒ 429 problem details with `Retry-After` (seconds).
- Rate-limit headers: [IETF `RateLimit-Policy` / `RateLimit` fields (HTTPAPI draft) | `X-RateLimit-Limit` /
  `X-RateLimit-Remaining` / `X-RateLimit-Reset`] — one convention everywhere.
- Business-flow abuse has its own caps, independent of request rate: OTP and SMS sends per phone number and per
  day, sign-up rewards per device, card or account verification attempts per user.
- Limit values live in configuration (the PRD's `## Configuration & Flags`), never hardcoded in handlers.

| Class | Operations (Moa) | Limit | Key |
|---|---|---|---|
| auth | `POST /v1/sessions`, `POST /v1/otp` | [n / window] | IP + phone number |
| write | `POST`/`PATCH`/`DELETE` on user resources | [n / window] | user |
| read | `GET` lists and items | [n / window] | user |
| partner | Public API operations | [n / window] | client ID |

## Auth Scopes

- **Schemes**: first-party apps use [short-lived JWT access tokens + rotating refresh tokens | OAuth 2.0 / OIDC
  Authorization Code with PKCE]; partners use [OAuth 2.0 client credentials | API keys for server-to-server only];
  outbound webhooks are signed (HMAC-SHA256 over timestamp + body, with a replay window).
- Every operation declares `security`. An operation open to anonymous callers declares `security: []` and the
  reason (health check, sign-up, public plan list).
- **Object level** — every operation that takes an ID checks that the caller may act on **that** object
  (OWASP API Security Top 10 2023 API1, BOLA/IDOR); not visible ⇒ 404.
- **Property level** — requests cannot set protected fields (`ownerId`, `plan`, `role`, `savedAmount`); responses
  expose only fields the caller may see (API3). Request schemas set `additionalProperties: false`.
- **Function level** — admin and support operations require a role and live under a separate tag or server (API5).
- **Step-up** verification for sensitive actions: changing the debit account, exporting personal data, deleting the
  account.
- **Social login** (Kakao, Naver, Apple): the server verifies the provider token; accounts are never linked by
  matching email alone.

| Scope | Grants | Granted to |
|---|---|---|
| `goals:read` | read the caller's goals | first-party apps |
| `goals:write` | create, change and archive the caller's goals | first-party apps |
| `payments:write` | register payment methods, trigger deposits | first-party apps (step-up) |
| `admin:support` | read-only account lookup with audit log | admin console, support role |

## Deprecation

- **Window**: a deprecated operation, field or version keeps working for at least [6 months] after the deprecation
  is announced when `api` is in `platform.surfaces` (Public API), and for first-party clients until the minimum
  supported app version no longer calls it — whichever is later. `/api-design` rejects a Public API deprecation
  whose `Sunset` date is closer than this window.
- **Headers** on every response of a deprecated operation: `Deprecation` (RFC 9745 — a structured-field date, e.g.
  `Deprecation: @1793491200` for 2026-11-01T00:00:00Z) and `Sunset` (RFC 8594 — an HTTP-date, e.g.
  `Sunset: Sat, 01 May 2027 00:00:00 GMT`), plus `Link: <[developer guide URL]>; rel="deprecation"`.
- **In the contract**: `deprecated: true` on the operation, parameter or schema property, and a description naming
  the replacement and the sunset date.
- **Communication**: the change record `docs/api/changes/api-change-YYYY-MM-DD.md`; an `## API / Developers` entry
  in the release notes (`/release-notes`); for a Public API, the developer guide and a direct notice to registered
  partners.
- **Before removal**: usage of the deprecated operation is measured per client and app version; removal needs the
  owner's sign-off when traffic is above [threshold]. After `Sunset` the operation returns 410 problem details.

## Timestamps & Timezones

- Instants are RFC 3339 strings in UTC with `Z` (`2026-11-04T00:30:00Z`), stored as timezone-aware values.
- Business dates are calendar dates (`YYYY-MM-DD`) interpreted in a named timezone — for the Korean market
  `Asia/Seoul` (UTC+9, no daylight saving). Example (Moa): the auto-debit date `2026-11-25` is a Seoul date; the
  debit job converts it to an instant.
- Never send local times without an offset; clients render in the user's timezone.
- Durations are ISO 8601 (`P1M`, `PT30M`) or integer fields with the unit in the name (`ttlSeconds`).
- Recurring schedules store the timezone with the rule, so daylight-saving regions (US, EU) keep wall-clock
  times correct.

## Money & Currency

- Money is an object `{ "amount": <integer>, "currency": "<ISO 4217>" }`; `amount` is in the currency's minor unit
  per its ISO 4217 exponent. **KRW has no minor unit** (exponent 0): `{ "amount": 10000, "currency": "KRW" }` is
  10,000 won. USD has two: `1999` is 19.99 dollars. Never floats, never formatted strings.
- The server computes every price, fee, discount and total from the rules in the PRD's
  `## Business Rules & Calculations` and `design/product/pricing-model.md`; clients never send computed amounts
  the server trusts.
- Rounding happens once, at the step the business rule names, with the rule's rounding mode (e.g. round down to
  10 won); intermediate values keep full precision.
- Tax display (inclusive or exclusive) follows `design/product/pricing-model.md` `## Taxes & Currency` per region.
- The currency of an account or subscription is fixed at creation; the API never converts silently.

## Internationalization

- Clients send `Accept-Language` (BCP 47: `ko-KR`, `en-US`); responses carrying server-generated text send
  `Content-Language`. Supported locales come from `localization.locales`.
- The API returns stable codes and enum values; apps localize them. Server-side localization is limited to text
  the server itself generates (notification bodies, emails, receipts), using ICU MessageFormat.
- The account stores the user's locale and timezone; notification templates use them, not the request header.
- Text is UTF-8, normalized to NFC; length limits count characters (Unicode code points), not bytes — Korean input
  is multi-byte.
- Personal names are one field (`name`) unless a feature needs parts — no first/last-name assumption. Phone numbers
  are E.164 (`+821012345678`). Korean addresses use road-name address fields (도로명주소) with the postal code.
