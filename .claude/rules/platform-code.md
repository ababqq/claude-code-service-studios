---
paths:
  - "packages/**"
  - "**/src/lib/**"
  - "**/src/platform/**"
  - "**/src/core/**"
  - "apps/*/lib/**"
---

# Platform Code Rules

These paths hold shared application code that every feature builds on: the data-access layer, caching, the queue
and job runner, the feature-flag and config SDK, logging and tracing libraries, HTTP and API client SDKs, and the
shared packages of a monorepo (`stack.shared_roots`). A defect here ships in every feature at once, so the bar is
higher than for feature code. Infrastructure definitions are not platform code — they follow
`.claude/rules/infra-code.md`.

- **No blocking I/O on hot paths.** Request handlers, event-loop callbacks, stream and queue consumers, and render
  paths never call synchronous file, network or crypto APIs (`readFileSync`, `execSync`, `pbkdf2Sync`, a blocking
  HTTP client inside an `async def`, JDBC on a reactive thread, disk or network work on a mobile main thread).
  CPU-heavy work (image processing, PDF generation, large JSON transforms) moves to a worker thread or a job. Pools
  and concurrency are bounded; caches have a TTL and a size bound — an unbounded in-memory map is a memory leak with
  a delay.
- **Measure before and after every optimization** and record the numbers (p50/p95 latency, allocations, query
  count) in the change description. An optimization without numbers is a refactor with a risk attached.
- **Stable public APIs.** Each package declares its public surface explicitly (`exports` in `package.json`, a single
  index module, a Gradle `api` vs `implementation` split); internal modules are not importable from outside. Public
  signatures are fully typed — no `any`, no untyped dictionaries. Versions follow semver: a breaking change is a
  major version, preceded by a deprecation (`@deprecated` / `@Deprecated` with the replacement named) in a minor
  release, and a migration note in the package changelog.
- **Documented.** Every public function, class and option carries a doc comment with a usage example — the doc
  comment is the API reference.
- **Strict dependency direction**: apps → feature/domain modules → platform. Platform code never imports app,
  feature or domain code. Enforce it with a module-boundary lint rule (`import/no-restricted-paths`,
  dependency-cruiser, Nx module boundaries, ArchUnit) rather than by convention.
- **Dependency injection, no hidden singletons.** Libraries expose factories that take their configuration and
  collaborators (HTTP client, clock, logger, tracer, meter) as parameters, so tests pass fakes. No connection,
  client or mutable state is created at import time, and no library reads `process.env` or other globals deep
  inside — configuration is passed in and validated once at startup.
- **Observability hooks built in.** Every helper that performs I/O emits a trace span (OpenTelemetry semantic
  conventions), propagates W3C trace context across HTTP and queue boundaries, and records latency and error
  metrics. Metric labels have bounded cardinality — never user IDs, emails or raw URLs as labels. Log lines are
  structured and carry `traceId`; no personal data, tokens or request bodies in logs or span attributes. The
  hooks default to no-ops so a library works without a telemetry backend.
- **Graceful degradation.** Timeouts are explicit parameters with safe defaults, never infinite. The flag SDK serves
  the last known snapshot or the documented safe default when the flag service is unreachable; a cache failure
  falls through to the source instead of failing the request; a client for a failing dependency trips a circuit
  breaker rather than piling up waiting requests.
- **Deterministic cleanup.** Pools, clients, subscriptions and timers are closed on shutdown; services handle
  `SIGTERM` by refusing new work, draining in-flight work within a deadline and then closing resources.
- **Concurrency is documented.** A shared client is either safe for concurrent use or says in its doc comment that
  it is not — never "probably fine".
- **Before writing against a framework, SDK or driver API**, consult `docs/stack-reference/VERSION.md` and
  `docs/stack-reference/<component>/` for the pinned version; a version-sensitive API not covered there is
  `NOT SOURCEABLE — run /setup-stack refresh`, not a guess.

## Examples

**Correct** (TypeScript — `packages/flags`: evaluation reads an in-memory snapshot, refresh happens in the
background, collaborators are injected, failures degrade to the last known snapshot):

```typescript
export interface FlagClientDeps {
  http: HttpClient;   // injected — tests pass a fake
  clock: Clock;
  logger: Logger;
  tracer: Tracer;
}

/**
 * Creates a flag client. Evaluation never performs I/O.
 * @example
 *   const flags = createFlagClient(config.flags, deps);
 *   await flags.start();
 *   if (flags.isEnabled('goals.v2-progress-ring', { userId })) { ... }
 */
export function createFlagClient(config: FlagClientConfig, deps: FlagClientDeps): FlagClient {
  let snapshot: FlagSnapshot = config.safeDefaults;

  async function refresh(): Promise<void> {
    await deps.tracer.startActiveSpan('flags.refresh', async (span) => {
      try {
        snapshot = await deps.http.getJson(config.snapshotUrl, { timeoutMs: config.timeoutMs });
      } catch (err) {
        deps.logger.warn({ event: 'flags_refresh_failed', code: errorCode(err) }); // keep the last snapshot
      } finally {
        span.end();
      }
    });
  }

  return {
    start: () => refresh().then(() => scheduleEvery(deps.clock, config.refreshMs, refresh)),
    isEnabled: (key, ctx) => evaluate(snapshot, key, ctx), // pure, synchronous, in memory
  };
}
```

**Incorrect**:

```typescript
import fs from 'node:fs';

const client = new FlagService(process.env.FLAG_API_KEY!);          // VIOLATION: singleton built at import time from env

export async function isEnabled(key: string, userId: string) {
  const rules = JSON.parse(fs.readFileSync('/etc/moa/flags.json', 'utf8')); // VIOLATION: blocking I/O on every evaluation
  const remote = await client.fetch(`${key}?user=${userId}`);        // VIOLATION: network on the hot path, no timeout,
                                                                     //   no fallback when the flag service is down
  console.log(`flag ${key} evaluated for ${userId}`);                // VIOLATION: unstructured log, no trace context
  return remote.enabled ?? rules[key];
}
```
