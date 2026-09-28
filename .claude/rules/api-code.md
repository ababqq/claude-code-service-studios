---
paths:
  - "docs/api/**"
  - "**/src/api/**"
  - "**/src/routes/**"
  - "**/src/controllers/**"
  - "**/src/graphql/**"
  - "apps/api/**"
  - "apps/*/api/**"
  - "services/**"
---

# API Code Rules

- **Contract first.** Every operation exists in the contract under `docs/api/` (`openapi.yaml`, `schema.graphql`,
  `<service>.proto` or `asyncapi.yaml`) before its handler is written, and the handler matches it — method, path,
  parameters, request and response schemas, status codes, error codes. An operation that is not in the contract
  does not ship. Contract changes go through `/api-design` (the change record names BREAKING changes).
- **Authorization on every operation.** Authenticate first, then check the caller's scope or role for the
  operation, then check ownership of **every object the request names** (BOLA/IDOR). Not visible to the caller ⇒
  404, never a confirmation that the object exists. Admin and support operations require a role and write an audit
  record. Never trust IDs, prices, plans or roles sent by the client.
- **Validate at the boundary.** Parse every request against a typed schema (zod, class-validator, Pydantic, Bean
  Validation) before domain code runs; reject unknown fields on writes (mass assignment); bound every string,
  array and page size. Domain code receives typed values, never raw request bodies.
- **Versioning and deprecation.** Changes are additive by default. A BREAKING change (removed field or operation,
  type change, new required field, enum narrowing, stricter validation) needs a version bump or a deprecation with
  `Deprecation` and `Sunset` headers per `docs/api/api-guidelines.md` `## Deprecation`. Keep serving every shape a
  supported mobile app version calls.
- **Errors are RFC 9457 problem details** (`application/problem+json`) with a stable `code`. No stack traces, SQL,
  internal hostnames, tokens or personal data in any response body. Map domain errors to status codes in one place.
- **Paginate every list.** Cursor pagination by default (`cursor`, `limit`, response `data` + `page`), a stable sort
  with a unique tiebreaker, a maximum page size enforced with 400 — never an unbounded list.
- **Idempotency keys** on every unsafe request a client may retry that moves money or has an external side effect:
  store key + request fingerprint + response; replay on a matching retry, 422 on a reused key with a different body,
  409 while the first request runs. Pass a derived key to the payment gateway.
- **Timeouts and retries.** Every outbound call (database, cache, payment gateway, identity provider, messaging
  API) has an explicit timeout below the operation's latency budget; retries only for idempotent calls, with
  exponential backoff and jitter, a capped attempt count and a circuit breaker for dependencies that fail hard.
  Never call a third party inside a database transaction.
- **No personal data in logs.** Log IDs and `traceId`, never emails, phone numbers, tokens, account numbers or
  request bodies; redact before logging, not after.
- **Money and time**: integer minor units plus an ISO 4217 code (KRW has no minor unit); RFC 3339 UTC instants.
- **Configuration, not constants**: rate limits, timeouts, quotas and prices come from config or flags.
- **Contract tests** prove the handler matches the contract (Integration story evidence under `tests/contract/`
  or per `testing.patterns`).

## Examples

**Correct** (NestJS + TypeScript — contract operation `getGoal`, ownership checked, typed input, problem details):

```typescript
@Get('goals/:goalId')
@RequireScopes('goals:read')
async getGoal(@CurrentUser() user: AuthUser, @Param() params: GoalIdParams): Promise<GoalDto> {
  // GoalIdParams validates the `goal_` + ULID format declared in docs/api/openapi.yaml
  const goal = await this.goals.findOwnedBy(user.id, params.goalId); // owner filter in the query
  if (!goal) {
    throw new ProblemException(404, 'GOAL_NOT_FOUND'); // same answer for "missing" and "not yours"
  }
  return toGoalDto(goal); // maps to the contract schema; internal columns never leak
}
```

**Correct** (retry-safe payment call with a timeout and a derived idempotency key):

```typescript
const confirmation = await this.pg.confirmDeposit(
  { paymentKey, orderId, amount: deposit.amount }, // Money computed server-side, never taken from the client
  { idempotencyKey: `deposit:${request.idempotencyKey}`, timeoutMs: this.config.pgTimeoutMs },
);
```

**Incorrect**:

```typescript
@Get('goals/:id')                                 // VIOLATION: path and parameter differ from the contract
async getGoal(@Param('id') id: string) {           // VIOLATION: no scope, no validation of the ID format
  const goal = await this.prisma.goal.findUnique({ where: { id } }); // VIOLATION: no ownership check (BOLA)
  if (!goal) throw new Error(`goal ${id} not found for ${this.req.user.email}`); // VIOLATION: not problem+json; email in the message
  return goal;                                     // VIOLATION: returns every column, including internal ones
}
```
