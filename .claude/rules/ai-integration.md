---
paths:
  - "**/src/ai/**"
  - "**/src/llm/**"
  - "**/ml/**"
  - "apps/*/ai/**"
  - "apps/*/llm/**"
  - "packages/*/src/ai/**"
  - "packages/*/src/llm/**"
---

# AI Integration Rules

These paths hold code that calls an LLM or an ML model: prompt assembly, retrieval (RAG), model clients, output
parsers, guardrails, ranking and recommendation. A model call is an outbound call to a dependency that is slow,
billed per token, non-deterministic and able to leak whatever it is given — treat it like a payment gateway, not
like a local function. Provider, model family, vector store and hosting are ADR decisions (Domain `ML`); the
`ml-engineer` agent owns evaluation.

## Versioning

- **Pin the model.** Every call names an exact, versioned model ID read from config — never a floating alias such
  as `latest`, and never a model ID typed into the call site. A model upgrade is a config change that goes through
  the same eval run as a code change.
- **Version the prompt.** Prompts are files or constants with an explicit version (`monthly-summary@3`), reviewed
  like code. Changing the wording, the few-shot examples, the tool list, the temperature or the retrieval settings
  (chunking, top-k, embedding model) is a new version.
- **Record what produced each answer.** Log the model ID, prompt version, retrieval configuration version and
  provider request ID with every call, so a bad answer in production can be reproduced against the same inputs.
- **Before relying on a model ID, SDK method or API parameter**, check `docs/stack-reference/VERSION.md` and
  `docs/stack-reference/<component>/` — model catalogs and SDKs change monthly. Not covered there ⇒
  `NOT SOURCEABLE — run /setup-stack refresh`; never fill the gap from memory.

## Eval sets are tests

- Every AI feature has a versioned eval set — representative inputs with expected outputs or grading criteria,
  including the edge cases and known prompt-injection strings — stored with the feature's tests (per
  `testing.patterns`) and free of real personal data.
- Each eval metric has a threshold written in the PRD's acceptance criteria (task success, schema-valid rate,
  groundedness for RAG, refusal rate where refusing is correct). A change that drops a metric below its threshold
  fails like any failing test.
- Changing the model, the prompt version or the retrieval configuration requires an eval run before merge; the
  report (scores, model ID, prompt version, seed and temperature) is retained as story evidence under
  `production/qa/evidence/<story-slug>/`.
- Deterministic code — prompt assembly, parsers, validators, guardrails, fallbacks — has ordinary unit tests with
  the provider mocked at the HTTP boundary. **Unit tests never call a live model.**

## Timeouts and fallbacks

- Every model call has an explicit timeout below the operation's latency budget (`performance.api_p95_ms` for
  synchronous endpoints). Generation that cannot fit the budget is streamed or moved to an asynchronous job that
  notifies the user when done.
- Retries only on retryable failures (timeouts, rate limiting, provider 5xx), with exponential backoff, jitter, a
  capped attempt count and the provider's `Retry-After` honoured; a circuit breaker opens when the provider fails
  hard.
- Every AI feature has a degraded path that works without the model — cached result, smaller model, rule-based
  answer, or the screen without the AI part. **A core journey (sign-in, payments, auto-debit, goal creation) never
  blocks on a model call.**

## Token and cost budgets

- Every call sets a maximum output token count; input context is bounded (truncate, summarize or re-rank retrieved
  chunks) rather than growing with user history.
- Per-request, per-user and per-day limits come from config or flags — including plan-based quotas (Free vs Plus) —
  never from constants in code, and exceeding one returns a defined error, not a surprise bill.
- Measure, do not estimate: emit input tokens, output tokens, cached tokens and cost per request as metrics tagged
  with feature, model ID and prompt version, and alert on the budget in the ADR. Use provider prompt caching where
  the ADR allows it.
- The cheapest model that meets the eval thresholds wins; moving to a more expensive model needs the eval delta that
  justifies it.

## No personal data in prompts or logs

- Send the model only the fields the task needs. Names, emails, phone numbers, account numbers, resident
  registration numbers, payment details and free-text support messages are redacted or pseudonymized before a
  third-party call, unless the ADR and the privacy review approve sending them (data processing agreement,
  retention and training terms, cross-border transfer — see `.claude/docs/compliance/<region>.md` for every region
  in `compliance.regions`).
- Logs, traces and analytics carry IDs, token counts, model ID, prompt version, latency and outcome — never the full
  prompt or completion when either can contain personal data. Debug sampling of prompts is redacted,
  retention-limited and a `pii_data_access` action (`.claude/docs/automation-modes.md`).
- Secrets never enter a prompt. Assume anything in the context window — system prompt included — can be extracted
  by a user.

## Validate every output

- Structured output is parsed against a schema (zod, Pydantic, a Kotlin or Swift `Codable` type). On failure, retry
  once with the validation error, then take the fallback — invalid output is never passed through.
- Model output is untrusted input: never executed as code, SQL or shell, never rendered as unescaped HTML or
  Markdown links without sanitizing, and never used as an authorization decision.
- Retrieved documents and user content are data, delimited from instructions; they cannot change the system prompt,
  the tool list or the output schema (prompt injection).
- Tools the model may call are an allowlist; every tool call is authorized with the **user's** permissions — the
  model acts on behalf of the user, never with more access than the user has — and money-moving or destructive
  tools require an explicit user confirmation in the UI.
- Numbers that matter (amounts, balances, dates, limits) are computed by code and passed in; the model writes the
  words around them and never becomes the source of a figure. Output that could read as financial, legal or medical
  advice stays inside the boundary the PRD states, with the disclosure copy the `ux-writer` provides.

## Examples

**Correct** (TypeScript — Moa monthly savings summary for Plus users; pinned model and prompt version from config,
timeout, token cap, schema validation, fallback, no personal data sent or logged):

```typescript
const SummarySchema = z.object({ headline: z.string().max(80), body: z.string().max(400) });

async function monthlySummary(userId: UserId, month: YearMonth): Promise<Summary> {
  const stats = await this.ledger.monthlyStats(userId, month); // figures computed by code, not by the model
  const cfg = this.config.ai.monthlySummary;                  // { modelId, promptVersion, timeoutMs, maxOutputTokens }
  try {
    const result = await this.llm.generate({
      modelId: cfg.modelId,
      prompt: this.prompts.render('monthly-summary', cfg.promptVersion, {
        savedKrw: stats.savedKrw,          // no name, email or account number in the prompt
        goalCount: stats.goalCount,
        streakMonths: stats.streakMonths,
      }),
      maxOutputTokens: cfg.maxOutputTokens,
      signal: AbortSignal.timeout(cfg.timeoutMs),
    });
    const parsed = SummarySchema.safeParse(result.json);
    this.metrics.llmCall({ feature: 'monthly-summary', modelId: cfg.modelId, promptVersion: cfg.promptVersion,
      inputTokens: result.usage.input, outputTokens: result.usage.output, outcome: parsed.success ? 'ok' : 'invalid' });
    if (parsed.success) return { ...parsed.data, source: 'ai' };
  } catch (err) {
    this.logger.warn({ event: 'llm_fallback', feature: 'monthly-summary', reason: errorCode(err) }); // IDs and codes only
  }
  return this.fallbackSummary(stats); // the goals screen still shows the numbers without the narrative
}
```

**Incorrect**:

```typescript
async function monthlySummary(user: User) {
  const res = await this.llm.generate({
    modelId: 'latest',                                                // VIOLATION: floating alias typed at the call site
    prompt: `Summarize ${user.name}'s month (${user.email}) and add up how much was saved: ` +
            JSON.stringify(user.transactions),                        // VIOLATION: personal data in the prompt, and the
  });                                                                 //   model computes the total instead of the ledger
                                                                      // VIOLATION: no timeout, no token cap, no fallback
  console.log(res);                                                   // VIOLATION: logs the full completion
  return JSON.parse(res.text);                                        // VIOLATION: unvalidated output passed through
}
```
