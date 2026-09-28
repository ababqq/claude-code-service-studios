# Tech Radar

<!--
TEMPLATE for docs/architecture/tech-radar.md — the product's single list of
technologies and patterns it adopts, trials, assesses, holds and forbids.

Written by:
- /setup-stack — seeds the file: `## Adopt` lists the chosen stack components;
  `## Assess` lists integration candidates it was asked to record (for a product
  whose compliance.regions includes `kr`: Kakao Login, Naver Login, Sign in with
  Apple, Toss Payments, in-app billing). It never writes Trial, Hold or
  Forbidden Patterns entries, and never overwrites an existing file.
- /architecture-decision — updates it, asking first, when an ADR is Accepted:
  an entry is added or moved between rings and cites that ADR.

Read by:
- /create-control-manifest — `## Hold` and `## Forbidden Patterns` become
  "Never" rules in docs/architecture/control-manifest.md;
- /code-review and /dev-story — new code does not introduce a Hold entry or a
  Forbidden Pattern, and does not add a dependency that is not on the radar
  without saying so;
- /tech-debt — Hold entries still in use are debt;
- /security-audit (deps mode) — dependency findings are checked against it.

Entry format (exact, one line per entry):
  - **<name>** — <why> (ADR-NNNN | Source: <url>)
Cite the ADR that decided the entry. Before an ADR exists (a /setup-stack seed),
cite the live source the entry was checked against. An entry with neither is not
written. Do not put versions in entry names — versions live in
docs/stack-reference/VERSION.md, so an upgrade never leaves the radar stale.

Rings:
- Adopt  — the default choice for its job in this product. New work uses it.
- Trial  — in use in a bounded scope (one feature, behind a flag, one service)
           to learn whether it earns Adopt. Name the scope in <why>.
- Assess — worth evaluating; not installed. Adopting it takes an ADR.
- Hold   — do not start new use. Existing use is migrated as its ADR says.
- Forbidden Patterns — code patterns (not products) that are never written
           here, each with the reason and the safe alternative.

Moa examples (names and reasons only; real entries carry a real ADR or URL):
  - **Next.js** — web framework for apps/web and apps/admin (Source: <release-notes URL>)
  - **Toss Payments** — PG candidate for auto-debit subscriptions; not integrated (Source: <developer-docs URL>)
  - **Client-side payment amount calculation** — the server computes every charge from the plan catalog; the client only displays it (ADR-0007)

Keep the five headings below exactly as spelled — the readers above find the
rings by heading. An empty ring stays in the file with no entries.
-->

## Adopt

- **[name]** — [why it is the default for its job] (ADR-[NNNN] | Source: [url])

## Trial

## Assess

## Hold

## Forbidden Patterns
