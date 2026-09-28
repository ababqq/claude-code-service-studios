---
paths:
  - "**/src/domain/**"
  - "**/src/modules/**"
  - "**/src/features/**"
  - "**/src/services/**"
  - "apps/*/domain/**"
  - "apps/*/modules/**"
  - "apps/*/features/**"
  - "services/*/src/**"
---

# Domain Logic Rules

These paths hold the product's business behaviour: eligibility, limits and quotas, pricing and fees, state
machines, ledgers, scheduling and the use cases that tie them together. The PRD's `## Functional Requirements` and
`## Business Rules & Calculations` are the specification; this code is their executable form.

- **Business values come from config or flags, never from literals.** Prices, fees, limits, quotas, thresholds,
  trial lengths, retry counts and time windows are read from typed config (`config/**`, per
  `.claude/rules/data-files.md`) or a feature flag, and each one names the PRD rule it implements. The
  `validate-commit` hook warns on literal business values in code roots.
- **Idempotent commands.** Every command a client, a queue or a scheduler can deliver twice produces the same
  outcome the second time: an idempotency key or natural key backed by a unique constraint, a state-machine guard
  that rejects a transition already taken, and consumers that deduplicate by message ID (delivery is
  at-least-once). Side effects that leave the service (payments, notifications, webhooks) go through an outbox
  written in the same transaction as the state change — never "commit, then call and hope".
- **Authorization at the boundary, ownership in the domain.** The API layer authenticates and checks scopes
  (`.claude/rules/api-code.md`); domain operations receive an explicit actor and load aggregates **through** that
  actor (`findOwnedBy(actor, id)`, tenant-scoped repositories), so no code path can load another user's or
  tenant's data by ID alone. Never trust IDs, prices, plans or roles that arrive from a client.
- **Testable pure logic.** Calculations and decisions (fee computation, eligibility, rounding, next-state) are pure
  functions: no I/O, no clock, no randomness — the current time, IDs and random sources are injected. The use-case
  layer loads data, calls the pure core and persists the result (functional core, imperative shell). Every rule in
  the PRD's `## Business Rules & Calculations` has unit tests, boundary values included.
- **Money and time are explicit.** Money is integer minor units plus an ISO 4217 currency (KRW has no minor unit),
  with the rounding mode the PRD specifies, applied once at a defined step — never floating point. Business dates
  use an explicit time zone (`Asia/Seoul` for "today" in Korea), and instants are stored in UTC.
- **State machines are explicit.** Each stateful entity has a transition table in code (states, events, guards,
  side effects) matching the PRD's state diagram; an undefined transition is an error, not a silent no-op.
- **No UI, transport or vendor types in the domain.** Domain modules do not import view code, HTTP request objects,
  ORM entities from another module, or SDK types of a payment or messaging provider; they emit domain events
  (`GoalCreated`, `DepositFailed`) and depend on ports that adapters implement.
- **Module boundaries hold.** A module owns its tables and exposes operations; another module never reads its
  tables directly (`docs/registry/architecture.yaml` `data_ownership` is the record).
- **Trace code to requirements.** Each use case names the TR-ID it implements in its doc comment
  (`TR-goals-001`), so `/architecture-review` and `/story-done` can trace coverage.
- **No static singletons for domain state** — collaborators are injected, per `.claude/docs/coding-standards.md`.

## Examples

**Correct** (TypeScript — Moa `goals` module: plan limit from config, ownership through the actor, idempotent
create, pure calculation with an injected clock):

```typescript
/** Creates a savings goal. Implements TR-goals-001 (design/prd/goals.md). */
async createGoal(actor: Actor, input: CreateGoalInput, idempotencyKey: string): Promise<Goal> {
  const existing = await this.goals.findByIdempotencyKey(actor.userId, idempotencyKey);
  if (existing) return existing;                                   // retry returns the first result

  const plan = await this.subscriptions.planOf(actor.userId);
  const limit = this.config.plans[plan].activeGoalLimit;           // PRD goals, Business Rules & Calculations — R2
  if ((await this.goals.countActive(actor.userId)) >= limit) {
    throw new DomainError('GOAL_LIMIT_REACHED', { limit });
  }

  const goal = Goal.create({ id: this.ids.goalId(), ownerId: actor.userId, ...input, createdAt: this.clock.now() });
  await this.goals.insert(goal, { idempotencyKey });              // unique (owner_id, idempotency_key) backs the check
  await this.outbox.add(new GoalCreated(goal.id, actor.userId));  // same transaction as the insert
  return goal;
}

/** Pure: the monthly deposit that reaches the target by the target date (rounded up to KRW 10 per rule R4). */
export function monthlyDeposit(targetKrw: number, savedKrw: number, today: LocalDate, targetDate: LocalDate): number {
  const months = Math.max(1, monthsBetween(today, targetDate));
  return Math.ceil((targetKrw - savedKrw) / months / 10) * 10;
}
```

**Incorrect**:

```typescript
async createGoal(goalInput: any) {
  if ((await this.prisma.goal.count({ where: { userId: goalInput.userId } })) >= 3) { // VIOLATION: hardcoded limit;
    throw new Error('limit');                                       //   userId taken from the client (no actor)
  }
  const goal = await this.prisma.goal.create({ data: goalInput }); // VIOLATION: no idempotency — a retry creates a second goal
  await this.kakao.sendAlimtalk(goal.userId, 'GOAL_CREATED');     // VIOLATION: vendor call inside the use case, no outbox
  const monthly = goal.target / ((goal.targetDate - Date.now()) / 2.6e9); // VIOLATION: float money, wall clock, magic number
  return { ...goal, monthly };
}
```
