# [Component] — Stack Component Reference

<!--
TEMPLATE for docs/stack-reference/<component-slug>/VERSION.md — one file per
configured stack component (framework, runtime, database, cache, queue, ORM,
IaC tool, cloud provider). Written by /setup-stack (guided setup, `refresh`,
`upgrade`); never hand-curated and never shipped pre-filled.

<component-slug> = the component name lowercased, dots removed, every other run
of non-alphanumeric characters replaced by "-": `Next.js` -> `nextjs`,
`React Native (Expo)` -> `react-native-expo`, `PostgreSQL` -> `postgresql`,
`Spring Boot` -> `spring-boot`.

THE ONE RULE: every value below comes from a live source fetched in the run that
wrote it (Context7 when its tools are present in the session, else
WebSearch/WebFetch) — release notes, the official changelog, the vendor's
documentation or its published support schedule. Never from memory. A value no
source states is written NOT SOURCEABLE (or NOT DETERMINED for the version); a
NOT SOURCEABLE line is a finished answer, not a failure to finish.

Contract (keep exact — agents, /architecture-decision and /setup-stack read
these labels; never translate them):
- the eight bold row labels of the table, in this order;
- the heading `## Post-Cutoff Changes (sourced)`;
- every bullet under it ends with `(Source: <url>, retrieved YYYY-MM-DD)`.

Values:
- **Component** — identical to the Component cell of this component's row in
  docs/stack-reference/VERSION.md: the configured string with any trailing
  version removed (`PostgreSQL`, not `PostgreSQL 16`).
- **Layer** — web | mobile | backend | data | cloud (lowercase).
- **Pinned Version** — the same string project.yaml carries for it (the
  `version` key for web/mobile/backend frameworks; the trailing version inside
  the configured string for runtimes, data and cloud components), or
  `n/a (managed service)`, or `NOT DETERMINED — accepted by user YYYY-MM-DD`.
- **Release Date** — of the pinned version, from the source; `n/a` for a
  managed service; NOT SOURCEABLE when no source states it.
- **Knowledge Risk** — LOW: released before the LLM knowledge cutoff;
  MEDIUM: released within six months after it; HIGH: released later, or the
  release date / version is not sourceable, or the cutoff itself is NOT
  DETERMINED. A managed service is MEDIUM: it keeps changing under one name.
  Give the one-line reason after the value.

MEDIUM and HIGH components also get, in the same folder, breaking-changes.md,
deprecated-apis.md and current-best-practices.md (same bullet rule; a topic no
source covers is written `NOT SOURCEABLE: <topic>` instead of a bullet), and
optionally modules/<topic>.md for a subsystem with significant post-cutoff
change. /setup-stack upgrade adds upgrade-<old>-to-<new>.md here.
-->

| Field | Value |
|-------|-------|
| **Component** | [Component name exactly as in the Pinned Components row, e.g. `Next.js`] |
| **Layer** | [web \| mobile \| backend \| data \| cloud] |
| **Pinned Version** | [sourced version, e.g. `15.3` \| `n/a (managed service)` \| `NOT DETERMINED — accepted by user YYYY-MM-DD`] |
| **Release Date** | [YYYY-MM-DD from the source \| `n/a` \| `NOT SOURCEABLE`] |
| **Source** | [URL of the release notes, changelog or official documentation page the version was read from] |
| **Retrieved** | [YYYY-MM-DD — the date that URL was fetched] |
| **LLM Knowledge Cutoff** | [the cutoff recorded in `docs/stack-reference/VERSION.md`] |
| **Knowledge Risk** | [LOW \| MEDIUM \| HIGH] — [one-line reason, e.g. "released 4 months after the cutoff"] |

## Post-Cutoff Changes (sourced)

<!--
Only what changed after the LLM knowledge cutoff and matters to how this product
uses the component: new or renamed APIs, changed defaults, removed features,
new configuration, end-of-support dates, store or platform rules. Do not restate
what the model already knows. One bullet per change; link the most specific page
(the migration guide section, not the docs home page).

For a LOW component write the single line
  No post-cutoff changes — released before the LLM knowledge cutoff.
For a component whose changes no source covers write
  NOT SOURCEABLE: <topic> — not stated at <url>
-->

- [What changed, and what to do instead] (Source: [url], retrieved [YYYY-MM-DD])
