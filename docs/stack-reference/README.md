# Stack Reference

Version-pinned, sourced reference for the components this product is built on — frameworks, runtimes, databases,
caches, queues, ORMs, infrastructure-as-code tools and cloud providers.

It exists because a language model's knowledge stops at its training cutoff while the stack keeps shipping. Asked
about a framework release that came out after its cutoff, an agent does not say "I don't know" — it answers from the
older version it remembers, and the answer looks exactly like a correct one. These files are what agents consult
**instead of** memory for anything version-sensitive.

**Generated only by `/setup-stack`** (guided setup, `refresh`, `upgrade`). The template ships this README and an
empty `VERSION.md` skeleton — never a hand-curated snapshot, which would already be stale on the day a project starts
and would describe a stack the project may not use.

## Layout

```text
docs/stack-reference/
├── README.md                        # this file
├── VERSION.md                       # index: pin date, model cutoff, one Pinned Components row per configured component
└── <component-slug>/                # one folder per configured component
    ├── VERSION.md                   # from .claude/docs/templates/stack-component-version.md
    ├── breaking-changes.md          # Knowledge Risk MEDIUM/HIGH only
    ├── deprecated-apis.md           # Knowledge Risk MEDIUM/HIGH only
    ├── current-best-practices.md    # Knowledge Risk MEDIUM/HIGH only
    ├── upgrade-<old>-to-<new>.md    # written by /setup-stack upgrade
    └── modules/<topic>.md           # optional: one subsystem with significant post-cutoff change
```

`<component-slug>` is the component name lowercased, dots removed, and every other run of non-alphanumeric characters
replaced by `-`: `Next.js` → `nextjs`, `React Native (Expo)` → `react-native-expo`, `PostgreSQL` → `postgresql`,
`Spring Boot` → `spring-boot`, `Node.js` → `nodejs`.

## Consultation Order

Before giving version-sensitive advice or writing version-sensitive code, read in this order and stop when the
question is answered:

1. `VERSION.md` (this folder) — is the component configured and pinned, at which version, with which Knowledge Risk?
   No row, or a Version of `NOT DETERMINED`, means the version is unknown: treat the component as Knowledge Risk HIGH.
2. `<component-slug>/VERSION.md` — pinned version, release date, source, and the sourced post-cutoff changes.
3. `<component-slug>/breaking-changes.md` — what changed between the versions the model knows and the pinned one.
4. `<component-slug>/deprecated-apis.md` — "don't use X → use Y".
5. `<component-slug>/current-best-practices.md` — patterns that are new since the cutoff.
6. `<component-slug>/modules/*.md` — subsystem detail, when present.

If none of them covers the question, answer `NOT SOURCEABLE — <topic> is not covered by docs/stack-reference/<component-slug>/`
and suggest `/setup-stack refresh`. Do not fill the gap from training data: a confidently wrong API is worse than an
admitted gap, because it produces work that looks verified.

## Quality Rules

- **Every fact carries its source and retrieval date.** Table rows fill the `Source` and `Retrieved` columns; every
  bullet ends with `(Source: <url>, retrieved YYYY-MM-DD)`. The source is the most specific page that states the fact
  — release notes, the official changelog, a migration guide section, the vendor's support schedule.
- **Gaps are written down, never guessed.** A version no live source confirms is `NOT DETERMINED` (and blocks
  `stack.pinned_on` until the user accepts it: `NOT DETERMINED — accepted by user YYYY-MM-DD`). A topic no source covers
  is `NOT SOURCEABLE: <topic>`. Either line is a finished answer, not an unfinished file.
- **No inference presented as fact.** "The migration guide lists no change to X" is not "X is unchanged". If an
  inference is recorded, it says it is one and names what it rests on.
- **Managed services** with no user-visible version (a cloud provider, a hosting platform) are recorded as
  `n/a (managed service)`; their reference covers the specific services and the deprecation schedules the product
  depends on (for example managed runtime end-of-support dates). A hosted database still pins its database version
  (`PostgreSQL 16` on a managed service is `PostgreSQL`, version `16`).
- **Only what differs from the model's knowledge.** A component released before the cutoff (Knowledge Risk LOW) gets
  its `VERSION.md` only. Module files stay short; they are loaded into agent context.
- **Parsed labels stay exact.** The `**Stack Pinned**`, `**LLM Knowledge Cutoff**` and `**Last Verified**` rows and the
  Pinned Components header of `VERSION.md` are read by `.claude/scripts/project-coherence.sh` and
  `.claude/hooks/session-start.sh`. Never reword or translate them.
- **Change it through the skill.** Hand edits drift from `project.yaml`; run `/setup-stack refresh` or
  `/setup-stack upgrade` instead, and `bash .claude/scripts/project-coherence.sh` shows any disagreement.

## Who Reads It

| Reader | What it takes from here |
|--------|-------------------------|
| Stack agents (`web-specialist`, `mobile-specialist`, `backend-specialist`, `data-specialist`, `cloud-specialist` and their sub-specialists) | Their `## Version Awareness` discipline: consult before advising, flag post-cutoff APIs, say `NOT SOURCEABLE` rather than guess |
| `/architecture-decision` | Stamps `## Stack Compatibility` (components, Knowledge Risk, references consulted); spawns TD-STACK-RISK for MEDIUM/HIGH components |
| `/architecture-review`, `/gate-check` | Stack compatibility of ADRs; "stack pinned" and deprecated-API checks |
| `/dev-story` | A story whose component is HIGH (or has no row) goes to the layer lead instead of the sub-specialist |
| `session-start.sh`, `project-coherence.sh` | The pin date and the Pinned Components rows |

## Maintenance

- **`/setup-stack refresh`** — after an Accepted ADR adds data or cloud components, when the team moves to a model with
  a different knowledge cutoff, or when sources are old. It adds newly configured components, re-verifies every source,
  updates `Retrieved` and `Last Verified`, reports drift (including newer stable releases), and rewrites
  `stack.pinned_on`. It never bumps a version on its own.
- **`/setup-stack upgrade <component> <old> <new>`** — a deliberate version change: live migration notes, a pre-upgrade
  audit of the code roots, a TD-STACK-RISK review, and the list of ADRs whose `## Stack Compatibility` names the
  component, marked "re-validation required" in `upgrade-<old>-to-<new>.md`.
