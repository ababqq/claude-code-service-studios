---
paths:
  - "config/**"
  - "**/seed/**"
  - "**/fixtures/**"
  - "**/locales/**"
  - "**/i18n/**"
---

# Data File Rules

Configuration, seed data, test fixtures and locale files are code: they are reviewed, versioned and validated like
code.

- **Valid JSON or YAML, always.** The `validate-data-files` hook rejects an unparseable file under `config/**`,
  `**/locales/**` and `**/i18n/**` right after the write, and `validate-commit` blocks the commit. YAML is block
  style, indented with spaces, never tabs.
- **A schema per file.** Every config file has a schema — a JSON Schema referenced by `$schema`, or a typed loader
  (zod, Pydantic, a Kotlin or Swift `Codable` type) that validates at startup and in CI. The application refuses to
  start on an invalid config rather than falling back to guesses.
- **Key casing per `naming.*`.** File names follow `naming.files`. Keys in files the API serves to clients follow
  `naming.api_fields`; keys read only by server code follow `naming.variables`; environment variable names follow
  `naming.env_vars`. One casing per file. Locale message keys are dotted paths by feature and screen
  (`goals.create.title`), identical across every locale file.
- **No secrets.** API keys, tokens, passwords, private keys and connection strings with credentials never go in
  these files — they come from the secret manager or the environment at runtime. Commit `.env.example` with
  placeholder values only; `validate-commit` blocks `.env` files and known key formats.
- **Versioned config.** Each config file carries a `schemaVersion`; a breaking shape change bumps it and the loader
  rejects versions it does not know. Environment differences are overlays (`config/base.yaml` +
  `config/staging.yaml`), not copies. Business values (prices, limits, quotas, timeouts) live here or in feature
  flags — never hardcoded in code — and each one names the PRD rule it implements.
- **Money and time in data files** use the API conventions: integer minor units with an ISO 4217 code (KRW has no
  minor unit), RFC 3339 UTC instants, IANA timezone names (`Asia/Seoul`).
- **Seeds and fixtures are synthetic.** No production data and no real personal data: emails at `example.com`,
  obviously fake phone numbers, generated names. Fixtures are deterministic (fixed IDs and seeds, fixed clock) so
  tests do not depend on run order or time.
- **Locale files**: ICU MessageFormat for plurals, selects and numbers; named placeholders, never string
  concatenation; every key present in every shipped locale of `localization.locales` (a missing key fails CI);
  length limits noted for push, SMS and 알림톡 templates.
- **No orphans.** Every entry is read by code or referenced by another data file; unused keys are removed in the
  same change that stops reading them.

## Examples

**Correct** (`config/plans.yaml` — Moa subscription plans):

```yaml
$schema: ./schemas/plans.schema.json
schemaVersion: 2
plans:
  - id: free
    monthlyPrice: { amount: 0, currency: KRW }
    activeGoalLimit: 3          # PRD goals, Business Rules & Calculations — rule R2
  - id: plus
    monthlyPrice: { amount: 4900, currency: KRW }
    activeGoalLimit: 20
```

**Correct** (`apps/mobile/locales/ko-KR/goals.json` — ICU plural, named placeholder):

```json
{
  "goals.list.count": "{count, plural, other {목표 #개}}",
  "goals.create.limitReached": "{planName} 플랜은 목표를 {limit}개까지 만들 수 있어요."
}
```

**Incorrect** (`config/Plans.json`):

```json
{
  "Free": { "price": 0.0, "goal_limit": 3 },
  "Plus": { "Price": 4.9, "goalLimit": 20, "tossSecretKey": "live_sk_..." }
}
```

Violations: uppercase file name; mixed key casing (`goal_limit`, `goalLimit`, `Price`); prices as floats in the wrong
unit with no currency; a secret in a config file; no `schemaVersion` and no schema.
