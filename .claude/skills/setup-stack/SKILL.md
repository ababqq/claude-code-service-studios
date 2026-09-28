---
name: setup-stack
description: "Choose each stack layer, pin versions from live sources, populate the stack reference, declare code roots, route specialists."
argument-hint: "[profile] | refresh | upgrade <component> <old> <new> | no args for guided setup"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, WebSearch, WebFetch, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/setup-stack/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,workflow,stack,code_roots`

Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.


# Stack Setup

This skill decides what the product is built on and makes that decision safe for every agent that comes after it. It
chooses each **stack layer** that has been decided — web, mobile, backend, data, cloud — pins every component's
version **from a live source**, writes the sourced **stack reference** agents consult instead of their training data,
declares the **code roots** each layer lives in, records the product facts later gates branch on (surfaces,
distribution, regions, personal data, locales), and shows which **stack specialists** the configuration routes to.

`stack.pinned_on` is its completion marker: the catalog's `stack-setup` step, `/gate-check` and the session banner all
read it. It is written **last**, and only when every configured component is pinned from a source, recorded as a
managed service, or carries a gap the user explicitly accepted.

**Always collaborative.** Every question is asked and every write is approved, whatever `modes.automation` says —
stack pins and live sources are listed among the exemptions in `.claude/docs/automation-modes.md`. Present, ask, draft,
and write only after "yes".

**Tier awareness.** The resolved `workflow` decides which product artifact gives this skill its context, and which
next steps Phase 14 offers:

- **`minimal`** — `design/product/one-pager.md`. Its `## Stack` section, when present, is a proposal to confirm. The
  one-pager may not exist yet — stack setup often comes first at this tier — so its absence is expected, not a gap.
- **`standard` / `full`** — `design/product/product-brief.md` (target users, MVP scope and any platform or market
  statements inform Phase 3). If it is missing, suggest `/brainstorm` first, and continue if the user prefers to set
  up the stack now.

### Outputs

| Path | What is written |
|------|-----------------|
| `project.yaml` (stack.*, specialists.*, naming.*, commands.*, platform.*, release.*, privacy.*, compliance.*, localization.*) | The layer choices, pins, roots, overrides and product facts; `stack.pinned_on` last |
| `docs/stack-reference/VERSION.md` | The index: pin date, model knowledge cutoff, one Pinned Components row per configured component |
| `docs/stack-reference/<component>/*.md` | Per component (folder = the component slug): `VERSION.md` from `.claude/docs/templates/stack-component-version.md`; for MEDIUM/HIGH also `breaking-changes.md`, `deprecated-apis.md`, `current-best-practices.md`; in `upgrade` mode `upgrade-<old>-to-<new>.md` |
| `docs/architecture/tech-radar.md` | Seeded from `.claude/docs/templates/tech-radar.md`: `## Adopt` = the chosen components; `## Assess` = recorded integration candidates |
| `<root>/CLAUDE.md` | One per configured code root, from `.claude/docs/templates/code-root-claude.md` (offered, never forced) |

### What this skill never does

- **Guess a version.** A version comes from a source fetched in this run, from the lockfile of existing code verified
  against a source, or it is written `NOT DETERMINED`. Never from memory.
- **Edit the repository-root `CLAUDE.md`.** Its `@docs/stack-reference/VERSION.md` import is a fixed line; this skill
  fills the file the line imports, never the line.
- **Write** `project.stage`, any `modes.*` key, or the six knobs `modes.rigor` fronts (`modes.review_mode`,
  `modes.workflow`, `docs.density`, `qa.level`, `modes.story_granularity`, `team.size`). A written value would shadow
  the rigor expansion.
- **Scaffold application code** or run package installs, generators, migrations or deploys. When a declared root does
  not exist yet, it says so and names the framework's own generator (looked up live) as the user's step — a
  hand-written copy of generated framework files would look finished and be quietly wrong.
- **Edit ADRs.** Upgrades mark affected ADRs "re-validation required" in the upgrade record; `/architecture-decision`
  owns the ADRs.

---

## Phase 1: Parse Arguments

Modes, from `$ARGUMENTS`:

| Argument | Mode |
|----------|------|
| *(none)* | Guided setup — Phases 2–11, then Phase 14 |
| `ts-fullstack-web`, `expo-mobile-ts-api`, `flutter-spring`, `python-api-react` | Guided setup with that preset proposed in Phase 4 |
| `refresh` | Phase 12 |
| `upgrade <component> <old> <new>` | Phase 13 |

`--review full|lean|solo` may follow any mode; it overrides the resolved `review_mode` for this run (it only matters
where this skill spawns a gate — `upgrade`).

Anything else — an unknown preset name, `upgrade` with fewer than three values, a mode word misspelled — stop, show
the table above, and ask which was meant. Never guess a mode from a near-miss spelling.

If the resolved `stack` line already shows configured layers and the mode is guided setup, say so and ask before
going further:

- Prompt: "The stack is already configured (`<stack line>`). What do you want to do?"
- Options: `Add or change a layer (Recommended)` / `Refresh sources and dates (refresh)` / `Upgrade one component (upgrade)` / `Start over — reconfigure every layer`

Re-running never silently overwrites an existing choice: each changed value is shown old → new in Phase 7.

---

## Phase 2: Detect the Current State

### 2a. Configuration

Read `project.yaml` in full. Note every existing `stack.*`, `specialists.*`, `naming.*`, `commands.*`, `platform.*`,
`release.distribution`, `privacy.handles_pii`, `compliance.regions` and `localization.locales` value, and
`project.category` (read-only here — it colours the preset suggestion). Keys without a `resolve_config` label
(`naming.*`, `commands.*`, `localization.locales`, `platform.browsers`, `platform.min_os.*`, `stack.monorepo`,
`stack.package_manager`) are read here, from `project.yaml`, not from `project.local.yaml`.

If `project.yaml` does not exist, stop: "No `project.yaml` at the repository root — run `/start` first; it creates the
file this skill writes into."

### 2b. Product context

Read the tier's product artifact (see **Tier awareness**) and extract what it states about platforms (web, iOS,
Android, a partner or public API), markets and languages, personal data, and any stack preference. Quote what you use;
do not infer a surface the document does not name.

### 2c. Manifests and workspace layout

Glob the repository for these, skipping every directory named in yaml-helper's scan-prune list (`node_modules`,
`.next`, `.nuxt`, `.output`, `.turbo`, `.vercel`, `.expo`, `dist`, `build`, `out`, `coverage`, `Pods`, `DerivedData`,
`.gradle`, `.dart_tool`, `.venv`, `venv`, `__pycache__`, `.terraform`, `vendor`, `target`, `.git`):

`package.json`, `pnpm-workspace.yaml`, `turbo.json`, `nx.json`, `pyproject.toml`, `requirements.txt`,
`build.gradle(.kts)`, `settings.gradle(.kts)`, `pom.xml`, `go.mod`, `pubspec.yaml`, `Podfile`, `*.xcodeproj`,
`app.json` / `app.config.*` (Expo), `Dockerfile`, `*.tf`

Read the ones found and turn the evidence into proposals — never into decisions:

| Evidence | Proposal |
|----------|----------|
| `next` / `nuxt` / `vue` / `react` (+ `vite`) in a `package.json` | web layer: Next.js / Nuxt / Vue / React (Vite); root = that package's directory |
| `expo` (or `app.json` with an `expo` key) / `react-native` without Expo | mobile: React Native (Expo) / React Native |
| `pubspec.yaml` depending on the `flutter` SDK | mobile: Flutter |
| `*.xcodeproj` or `Podfile` / an Android application module, with no React Native or Flutter | mobile: native iOS (SwiftUI/UIKit) / native Android (Jetpack Compose) |
| `@nestjs/core` / `express` / `fastify` / `hono` | backend: NestJS / Express / Fastify / Hono, runtime Node.js |
| Spring Boot plugin or parent in Gradle / Maven | backend: Spring Boot; Kotlin when the Kotlin JVM plugin is applied, else Java |
| `fastapi` / `django` / `flask` in `pyproject.toml` / `requirements.txt` | backend: FastAPI / Django / Flask, runtime Python |
| `prisma` / `drizzle-orm` / `typeorm` / `sqlalchemy` + `alembic` / Flyway or Liquibase | data ORM and migration tooling; `migrations_dir` from where the migrations live |
| `postgres`, `mysql`, `redis`, `rabbitmq` images in a compose file | data components (an image tag is a hint, never the pin) |
| `*.tf` with `provider "aws"` / `"google"` / `"azurerm"` / `"ncloud"`; `vercel.json`, `fly.toml`, `wrangler.*` | cloud provider and IaC tool; root = the directory holding them |
| `pnpm-workspace.yaml`, `turbo.json`, `nx.json`, `workspaces` in the root `package.json`, Gradle `include(...)` | `stack.monorepo: true`; workspace directories are root candidates |
| `pnpm-lock.yaml` / `package-lock.json` / `yarn.lock` / `bun.lock` / `uv.lock` / `poetry.lock` | `stack.package_manager` |

A layer can have **several roots** (`apps/web` + `apps/admin`; `apps/api` + `services/worker`). Workspace
directories under `apps/*`, `services/*` or `packages/*` that hold a manifest and belong to no proposed root are listed
as undeclared — `resolve_code_roots` would report them — so the user can place each one.

For existing code, also read the **version each lockfile resolves** for the framework and major libraries. That
version is a fact about the repository; Phase 5 verifies it against a live source.

### 2d. Toolchain probe

For each runtime or toolchain a proposed layer implies, probe the installed version with Bash — `node --version`,
`python3 --version`, `java -version`, `go version`, `flutter --version`, `xcodebuild -version` — only for the ones
that apply.

**A probe that fails establishes nothing.** Report `installed version NOT DETERMINED — <why the probe failed>`; never
"not installed". A version manager, a container-only toolchain, or a CI-only build are all normal reasons a local
probe fails. Keep the results for Phase 5e and the Phase 14 summary.

### 2e. Present what was found

Show one block: the configuration already present, the product facts the artifact states, a table of detected layers
(evidence · proposed framework · proposed root(s)), undeclared workspace directories, lockfiles, and the toolchain
probe results. Then continue to Phase 3. On an empty repository, say "No manifests found — a greenfield setup" and
continue; presets (Phase 4a) help most here.

---

## Phase 3: Product Facts

These keys are read by gates and checklists long after this skill runs, and every one of them distinguishes **unset**
from a value: unset means "nobody has answered", and the readers ask. So each question offers `Decide later — leave
unset`, and a deferred key is simply not written — never written as an empty or placeholder value.

Ask with `AskUserQuestion`, at most four questions per call, proposing the answer the product artifact supports:

1. **`platform.surfaces`** (multi-select): `web` / `ios` / `android` / `api`. Explain `api`: an **externally consumed**
   API (public or partner). The backend the product's own apps call is not the `api` surface.
2. **`release.distribution`**: `web` / `stores` / `web+stores` (others typed: `enterprise`, `internal`). Propose from
   the surfaces: web only → `web`; iOS/Android only → `stores`; both → `web+stores`.
3. **`compliance.regions`** (multi-select): `kr` / `eu` / `us`, or "none apply". "None apply" is written `[]` — an
   answer, distinct from unset. Each listed region later loads `.claude/docs/compliance/<region>.md`.
4. **`privacy.handles_pii`**: `true` / `false`. Say plainly: accounts almost always mean personal data (email, phone,
   name); Korean identity verification adds name, date of birth, phone and CI/DI values; payments add financial data.
   Unset is **not** `false`.
5. **`localization.locales`**: BCP 47 tags, e.g. `[ko-KR]`, `[ko-KR, en-US]`.
6. **`platform.browsers`** — only when `web` is a surface: a browserslist query list. For the Korean market, name
   Samsung Internet and the KakaoTalk and Naver in-app browsers explicitly rather than relying on `defaults`.
7. **`platform.min_os.ios` / `platform.min_os.android`** — only when `ios` / `android` are surfaces. The minimums the
   chosen mobile framework supports are looked up live in Phase 5; propose them then, not from memory.

Record the answers; nothing is written until Phase 7.

---

## Phase 4: Choose the Layers

**Only the layers already decided are required.** Typically that is the web, mobile and backend frameworks — the
team skills and `/dev-story` route on them. The **data** and **cloud** layers may stay unset until their Foundation
ADRs are Accepted: `/architecture-decision accept` for a Domain `Data` or `Infra` ADR hands off to
`/setup-stack refresh`, which records them. Say this before asking about those two layers, and offer
`Leave unset until the ADR (Recommended)` whenever the choice is not already made. An unset layer means "not decided
yet", never "not used".

### 4a. Preset (optional)

Offer the golden-path presets; read `.claude/skills/setup-stack/references/profiles.md` only when the user wants one
or passed a profile argument:

- `ts-fullstack-web` — Next.js web + admin, NestJS API, TypeScript end to end
- `expo-mobile-ts-api` — React Native (Expo) apps with a TypeScript API
- `flutter-spring` — Flutter apps with a Spring Boot (Kotlin/Java) API
- `python-api-react` — React (Vite) web with a FastAPI/Django API
- `No preset — choose each layer`

A preset proposes components, roots and the repository shape; it **never** proposes a version. Each layer is still
confirmed individually below. Record the chosen name as `stack.profile` (informational only — no skill branches on
it). Use `project.category` and the Phase 2 detection to recommend one; with existing code, detection wins over a
preset.

### 4b. Per-layer choices

For each of `web`, `mobile`, `backend`, `data`, `cloud`, ask: decide now, or leave unset. For a layer decided now:

| Layer | Keys |
|-------|------|
| web | `framework`, `language`, `root` (path or list) |
| mobile | `framework`, `language`, `root` |
| backend | `framework`, `language`, `runtime` (e.g. `Node.js 22` — the version is filled in Phase 5), `root` |
| data | `database`, `cache`, `queue`, `orm` (each a component string or `none`), `migrations_dir` |
| cloud | `provider`, `iac`, `root` |

Propose from detection first, then the preset, then the product facts. Explain the consequence of a choice the user
may not see — for example that a web framework string of `React (Vite)` routes to the React/Next.js sub-specialist,
or that a framework the routing does not recognise (SvelteKit, Go) gets the layer lead alone (overridable with
`specialists.<layer>` after the write, Phase 7c).

Name trade-offs honestly and briefly when the user asks for a recommendation — team experience and hiring (Spring
with Java/Kotlin is common in Korean enterprises; TypeScript full-stack is common in early-stage teams in both
markets), native capability needs, regulated-domain expectations, operating cost — and always end with the user
choosing.

### 4c. Repository shape

- **`stack.monorepo`** — `true` for pnpm/yarn/npm workspaces, Turborepo, Nx or a Gradle multi-project build.
- **`stack.package_manager`** — from the lockfile when one exists; ask otherwise (`pnpm`, `npm`, `yarn`, `bun`,
  `gradle`, `maven`, `uv`, `poetry`, `pip`, …). One value: in a two-ecosystem repository record the manager of the
  primary layer and put the other ecosystem's install in `commands.install`.
- **`stack.shared_roots`** — directories holding code several layers share (`[packages]`).

### 4d. Integration candidates (only when `compliance.regions` includes `kr`)

Offer Kakao Login, Naver Login, Sign in with Apple, Toss Payments and in-app billing (App Store / Google Play) as
**integration candidates** — recorded in the tech radar's `## Assess` ring in Phase 9, never installed and never added
to a layer. `.claude/skills/setup-stack/references/profiles.md` (§ Korean-market integrations) says why each is
usually assessed. Let the user pick which to record.

### 4e. Validate the choices with the stack leads

For each layer decided or changed in this run, the layer's lead reviews the choice: `web-specialist`,
`mobile-specialist`, `backend-specialist`, `data-specialist`, `cloud-specialist`. This is a consultation, not a
director gate, so `review_mode` does not skip it — the user does, if they want to:

- Prompt: "Validate these layer choices with the stack leads before pinning versions?"
- Options: `Validate with the leads (Recommended)` / `Skip validation`

On validate, spawn the leads **in parallel** via `Agent` (issue every call before waiting for any). Give each: the
proposed block for its layer (framework, language, runtime, roots), the resolved or answered surfaces, distribution
and regions, the detected manifests for that layer, and the product artifact path (or "none"). Ask each to return:
fit for this product's surfaces and markets, risks the user should know before committing (ecosystem maturity, store
or platform constraints, team-skill assumptions), alternatives worth an ADR, and whether the proposed roots fit the
workspace layout — with any version-specific statement marked `NOT SOURCEABLE` rather than guessed (Phase 5 does the
sourcing).

Present each lead's findings under its layer and let the user keep or change the choice. A skipped validation
announces itself in the summary: `NOT CHECKED — <layer> choice not reviewed by <lead> (skipped by user)`. Layers left
unset get no lead.

---

## Phase 5: Pin Versions from Live Sources

### 5a. What gets a pin

Every configured **component**: each decided layer's framework; the backend runtime; the data layer's database,
cache, queue and ORM (a value of `none` is not a component); the cloud layer's provider and IaC tool. The language is
not pinned here (its version belongs to the framework's toolchain decisions and the lockfile).

### 5b. Look it up

For each component, use Context7 if its tools are present in the session, else WebSearch/WebFetch. Prefer, in order:
the official release notes or changelog, the project's GitHub releases, the official documentation's version or
support page, and a published support schedule for end-of-life dates. For each component record:

- **Version** — greenfield: the current stable release. Existing code: the version the lockfile resolves (Phase 2c),
  confirmed to exist at the source; a newer stable is reported as an upgrade candidate (`/setup-stack upgrade`), never
  silently chosen. Pin at the precision the ecosystem treats as the compatibility line — major.minor for frameworks
  (`15.3`) and for tools whose minor carries the changes (`Terraform 1.9`, any 0.x library), the major for runtimes
  and databases (`Node.js 22`, `PostgreSQL 16`) unless the user wants more — and use the **same string** in
  `project.yaml` and in the reference: `project-coherence.sh` compares them exactly.
- **Release date** of that version, from the source.
- **Source** — the most specific URL that states the version (not a home page), and **Retrieved** — today's date.
- **End of support**, when the source states one (runtimes, database major versions, managed runtimes).
- For mobile frameworks: the minimum iOS / Android versions the pinned version supports — the proposals for
  `platform.min_os.*` from Phase 3.

**Managed services** with no user-visible version — typically the cloud provider or a hosting platform — get Version
`n/a (managed service)`. Their reference (Phase 8) covers the specific services and deprecation schedules the product
relies on.

### 5c. Knowledge Risk

Record the **LLM knowledge cutoff** of the model running this session, as stated in its own system context. If it
cannot be stated, record `NOT DETERMINED` — then every component is Knowledge Risk HIGH. Never record a later cutoff
than the one the model can state: a cutoff claimed too late marks post-cutoff versions LOW and suppresses exactly the
reference docs that stop invented APIs. (A cutoff recorded too early only over-classifies risk — the safe direction.)

Grade each component from its sourced release date:

| Knowledge Risk | When |
|----------------|------|
| LOW | released before the model's knowledge cutoff |
| MEDIUM | released within six months after the cutoff |
| HIGH | released later — or the release date is not sourceable, the version is `NOT DETERMINED`, or the cutoff is `NOT DETERMINED` |

A managed service is graded MEDIUM: it keeps changing under one name.

### 5d. Gaps: `NOT DETERMINED`

When no source confirms a version, write `NOT DETERMINED` — never a remembered number — and ask:

- Prompt: "No live source confirmed a version for `<component>`. Accept the gap for now?"
- Options: `Accept the gap — record it and continue` / `I'll give a source URL` / `Leave it unresolved (blocks stack.pinned_on)`

An accepted gap is written `NOT DETERMINED — accepted by user YYYY-MM-DD` (Knowledge Risk HIGH) and does not block
`stack.pinned_on`; `/gate-check` lists it as CONCERNS by name. An unresolved `NOT DETERMINED` blocks `stack.pinned_on`
(Phase 11). A URL the user supplies is fetched and read before its version is used.

### 5e. The repository versus the pin

When the toolchain probe (2d) or the lockfile disagrees with the chosen pin — Node.js 20 installed, 22 chosen; the
lockfile resolves Next.js 14 while 15 is current — state both and ask; never pick silently:

- `Pin what the repository uses (Recommended for existing code)` — the reference then describes the APIs the code
  actually compiles against.
- `Pin the newer version and upgrade the code next` — say plainly that until the code moves, the reference describes
  APIs the code does not have, and `project-coherence.sh` will report the MISMATCH.
- `Something else` — the user states the intent.

A probe that returned `NOT DETERMINED` is reported as such, never as agreement.

### 5f. The pin table

Present one table for approval before anything is written:

| Layer | Component | Version | Release date | Knowledge Risk | Source | Retrieved |
|-------|-----------|---------|--------------|----------------|--------|-----------|

plus end-of-support notes, accepted gaps, unresolved gaps, and upgrade candidates. The user may change any row; a
changed version is looked up again.

---

## Phase 6: Roots, Naming and Commands

### 6a. Code roots

Every decided layer except data gets `root` — a scalar path or a **flow list** (`[apps/web, apps/admin]`; block lists
are not read for this key). The data layer declares `migrations_dir` instead; shared code goes in
`stack.shared_roots`. Propose from Phase 2c; for a greenfield monorepo the usual layout is `apps/web`, `apps/admin`,
`apps/mobile`, `apps/api`, `services/<name>`, `packages`, `infra`; for a single-app repository, the one source
directory (for example `src`).

A declared root that does not exist yet is allowed — `resolve_code_roots` reports it as `missing` until the code
arrives. Say so, and name the framework's own project generator (looked up live) as the way to create it. Workspace
directories still undeclared after this step are listed: every scan will warn about them until they are placed.

### 6b. Naming conventions

Propose `naming.*` from the chosen ecosystem and confirm; leave unset what the user does not want to fix yet.
Fields: `files`, `components`, `classes`, `variables`, `constants`, `api_paths`, `api_fields`, `db_tables`,
`db_columns`, `env_vars`, `events`. Typical values for a TypeScript web product with a Node API:

| Field | Typical value |
|-------|---------------|
| `files` | `kebab-case` (`goal-card.tsx`) |
| `components` / `classes` | `PascalCase` |
| `variables` | `camelCase` |
| `constants` / `env_vars` | `SCREAMING_SNAKE` (`TOSS_SECRET_KEY`) |
| `api_paths` | `kebab-case`, plural resources (`/v1/savings-goals`) |
| `api_fields` | `camelCase` (or `snake_case` — one per API) |
| `db_tables` / `db_columns` | `snake_case` (`savings_goals`) |
| `events` | `object_action` (`goal_created`, `payment_failed`) |

Other ecosystems differ — Kotlin and Swift files follow their type names (`PascalCase`), Python uses `snake_case`
files and functions, Dart uses `snake_case` files and `lowerCamelCase` members. Say which values follow the
ecosystem's published style guide and which are a team preference; the conventions are guidance that reaches code
through briefs and manifests, not a check.

### 6c. Commands

Fields: `install`, `dev`, `run`, `build`, `test`, `e2e`, `lint`, `typecheck`, `api_lint`, `migrate`, `smoke`,
`load_test`, `deploy_preview`. **`run` and `build` are asked, never guessed** — a wrong guess either fails loudly or,
worse, builds or starts the wrong app in a multi-app workspace. Propose from what exists (the scripts in each
`package.json`, a `Makefile`, Gradle tasks) and ask for the rest; leave unset what does not exist yet (`/test-setup`
fills `test`, `e2e`, `lint`, `typecheck` later).

- An OS-specific command uses the map form (`default` / `linux` / `macos` / `windows`).
- `migrate` runs dry runs against a disposable database only; `load_test` targets staging only.
- `deploy_preview` deploys a preview environment. **Never record a production deploy command** — production deploys
  are run by a human, after the rollout plan says so.

**YAML quoting rule — applies to every command and every quoted value.** `yaml-helper.sh`, the parser every config
read goes through, decodes **no** escape sequences: neither `\"` inside double quotes nor `''` inside single quotes.
It ends the value at the first matching quote. So choose the quote style that needs no escaping — a value containing
`'` goes in double quotes, a value containing `"` in single quotes, a value containing neither may stay unquoted or
take double quotes. A value containing both quote types cannot be represented; rewrite the command to drop one.

---

## Phase 7: Write `project.yaml`

### 7a. Draft

Show the complete set of blocks this run adds or changes, and for each changed key the old → new value. The shape
(values are illustrative — real versions come from Phase 5):

```yaml
stack:
  profile: ts-fullstack-web          # informational only
  monorepo: true
  package_manager: pnpm
  shared_roots: [packages]
  layers:
    web:
      framework: Next.js
      version: "15.3"
      language: TypeScript
      root: [apps/web, apps/admin]
    backend:
      framework: NestJS
      version: "11.0"
      language: TypeScript
      runtime: Node.js 22
      root: [apps/api, services/worker]
platform:
  surfaces: [web, ios, android]
  min_os:
    ios: "16.0"
    android: "26"
release:
  distribution: web+stores
privacy:
  handles_pii: true
compliance:
  regions: [kr]
localization:
  locales: [ko-KR, en-US]
naming:
  files: kebab-case
commands:
  install: pnpm install --frozen-lockfile
  test: pnpm turbo run test
```

`stack.pinned_on` is **not** in this draft — Phase 11 writes it last.

Ask: "May I write this to `project.yaml`?"

### 7b. Write rules

- Read `project.yaml` first, then Edit it. For each block (`stack`, `specialists`, `naming`, `commands`,
  `platform`, `release`, `privacy`, `compliance`, `localization`): absent → append it after the last top-level block;
  present → edit its keys in place and add the missing ones. Never write a second copy of a block. Preserve every
  other line — `schema_version`, `framework`, `project`, `modes`, comments.
- Lists in **flow style** `[a, b]`. `[]` only for an explicit "none" (`compliance.regions`).
- **Quote framework versions** (`version: "15.3"`): unquoted, `15.10` is read as the number 15.1 by any standard YAML
  parser (the commit hook's validation, CI tooling). Component strings with a trailing version (`PostgreSQL 16`) stay
  unquoted.
- A deferred key is **absent** — never an empty value, `TBD`, or a placeholder.
- `specialists.<layer>` is written only as an override (Phase 7c), never to restate the derived routing.
- Never write `project.stage`, `modes.*`, or any of the six rigor-fronted knobs.

### 7c. Read back: routing, roots and validation

Run:

```bash
bash .claude/hooks/yaml-helper.sh resolve_config --keys stack,code_roots,surfaces,distribution,compliance
```

and show the result:

- The `stack` line names every layer as `<layer>=…` or in `unset=`, followed by `[routing: …]` — the specialists
  skills will spawn. **This line is the routing**; do not restate it from any other table.
- If a configured layer routes to its lead alone because the framework is not recognised (for example Litestar for
  Python), or to a sub that does not fit (Ktor matched by `kotlin`), offer the override —
  `specialists.<layer>: <value>` — and on "yes" ask "May I write this to `project.yaml`?" before adding it. Valid
  values are one of that layer lead's own sub-specialists, `ios-specialist+android-specialist` for native mobile, or
  the lead itself (meaning "no sub"); any other value is ignored with a `notes:` line and the derived routing stands.
  Only web, mobile and backend take an override.
- The `code_roots` line lists every root with its source; a `missing` root is expected for code not yet generated;
  `undeclared=` names workspace directories still to place.
- A `notes:` line means a value was rejected (an enum outside its list, a surface that is not `web|ios|android|api`).
  Fix it with the user and write again — a rejected value reads as unset everywhere.

---

## Phase 8: Write the Stack Reference

### 8a. Check what exists first

For each configured component, compute its folder: `docs/stack-reference/<component-slug>/`, where the slug is the
component name lowercased, dots removed, and every other run of non-alphanumeric characters replaced by `-`
(`Next.js` → `nextjs`, `React Native (Expo)` → `react-native-expo`, `PostgreSQL` → `postgresql`). The component name
is the configured string with any trailing version removed. Then compare with what is on disk:

- **No folder** → create it (8c).
- **Same version pinned** → nothing to rewrite. Update `**Retrieved**` only if the source was actually re-fetched in
  this run — never restamp a date that was not checked.
- **Folder pins an older version** → update, do not replace: new `**Pinned Version**`, `**Release Date**`,
  `**Source**`, `**Retrieved**`, `**Knowledge Risk**`; **append** the new span to `breaking-changes.md`,
  `deprecated-apis.md` and `current-best-practices.md` under a heading naming it (`## 15.2 → 15.3`) and never truncate
  older spans — a project crossing two versions needs both. (A deliberate version change belongs in `upgrade` mode;
  if the user is changing versions here, offer Phase 13 instead.)
- **Folder pins a newer version** → stop and ask. Someone pinned forward on purpose, or the choice is wrong; never
  silently downgrade a reference.

### 8b. The index — `docs/stack-reference/VERSION.md`

Fill the skeleton; keep its row labels, table header and headings exactly as they are (`project-coherence.sh` and
`session-start.sh` parse them):

- `| **LLM Knowledge Cutoff** |` — the cutoff from 5c (or `NOT DETERMINED`).
- `| **Last Verified** |` — today's date.
- `| **Stack Pinned** |` — leave `NOT DETERMINED` for now; Phase 11 writes the pin date together with
  `stack.pinned_on`.
- `## Pinned Components` — replace the placeholder row with **one row per configured component**:
  `| <layer> | <Component> | <Version> | <Knowledge Risk> | <Source URL> | <YYYY-MM-DD> |`. Layer is lowercase
  `web|mobile|backend|data|cloud`; Component is the configured string with any trailing version removed; Version is
  the sourced version, `n/a (managed service)`, `NOT DETERMINED — accepted by user YYYY-MM-DD`, or (unresolved)
  `NOT DETERMINED`. Remove rows for components no longer configured (tell the user which).
- `## Knowledge Gap Warning` — keep as shipped.

### 8c. Component folders

For each configured component, write `docs/stack-reference/<component-slug>/VERSION.md` from
`.claude/docs/templates/stack-component-version.md` — the eight table rows exactly, and `## Post-Cutoff Changes (sourced)`.

For **MEDIUM and HIGH** components also write, from live sources:

- `breaking-changes.md` — changes between the last version the model knows and the pinned one: search the official
  migration guide, "breaking changes" and changelog pages for each version in between.
- `deprecated-apis.md` — "don't use X → use Y" entries with the version each changed in.
- `current-best-practices.md` — patterns introduced since the cutoff that this product's layer will meet.
- `modules/<topic>.md` — only for a subsystem with significant post-cutoff change that the product uses (for example
  caching or routing in a web framework); never an empty or speculative module file.

LOW components get `VERSION.md` only; extra files would cost context for little value.

### 8d. Sourcing rule for everything in this phase

**Never fill a gap from training data. Write the gap down.** These files exist to be read *instead of* training data,
so a confidently wrong entry is worse than no entry: it produces work that looks verified and is not.

- Every bullet ends with `(Source: <url>, retrieved YYYY-MM-DD)`, the URL being a page fetched in this run.
- A topic no source covers is written `NOT SOURCEABLE: <topic> — not stated at <url>` and the file moves on. That
  line is a successful outcome.
- Do not infer one fact from another. "The migration guide lists no change to X" is not "X is unchanged"; an
  inference that is recorded says it is one and names what it rests on.

Ask once for the whole set, listing every path: "May I write this to `docs/stack-reference/VERSION.md` and
`docs/stack-reference/<component>/` (<n> files, listed above)?"

---

## Phase 9: Seed the Tech Radar

Target `docs/architecture/tech-radar.md`, from `.claude/docs/templates/tech-radar.md` — headings `## Adopt`,
`## Trial`, `## Assess`, `## Hold`, `## Forbidden Patterns`, entries in the exact form
`- **<name>** — <why> (ADR-NNNN | Source: <url>)`.

- **`## Adopt`** — one entry per chosen component, **without a version in the name** (versions live in the stack
  reference, so an upgrade never leaves the radar stale), citing the pin's source URL:
  `- **NestJS** — backend framework for apps/api and services/worker (Source: <url>)`.
- **`## Assess`** — the integration candidates the user chose in 4d, each citing the vendor's official
  developer-documentation URL fetched in this run. A candidate whose documentation could not be fetched is left out
  and named in the summary as `NOT SOURCEABLE — <candidate>`.
- **`## Trial`, `## Hold`, `## Forbidden Patterns`** — left empty. Do not pre-populate them: those rings record
  decisions, and decisions come from ADRs (`/architecture-decision` updates the radar when one is Accepted). Never add
  a library speculatively because the product might need it later.

If the file already exists, never overwrite it: add only the missing `## Adopt` entries for components chosen in this
run, and show them as a diff.

Ask: "May I write this to `docs/architecture/tech-radar.md`?"

---

## Phase 10: Code-Root CLAUDE.md Files

For each configured code root — every `stack.layers.<layer>.root` entry, each shared root, and the cloud root —
offer a `<root>/CLAUDE.md` from `.claude/docs/templates/code-root-claude.md`. Claude Code loads it whenever work
touches files under that root, so the layer, pinned framework and stack-reference pointer travel with the code.

Fill it from this run: layer; framework, version and language; runtime (backend roots); the component folder
`docs/stack-reference/<component-slug>/`; the Knowledge Risk from the index; the exact `commands.*` strings that are
set. **Derive the applicable rules** — read the `paths:` frontmatter of every `.claude/rules/*.md` file and list each
rule whose globs match files under this root, with its one-line focus. Never copy a rule list from an example.

- An existing `<root>/CLAUDE.md` is never overwritten: show the difference and ask.
- A root that does not exist yet: writing the file creates the directory — say so, and ask whether the user prefers
  to wait until the framework generator has created the project there.
- The **repository-root `CLAUDE.md` is never written.** Its stack import line is fixed; the file it imports is
  `docs/stack-reference/VERSION.md`, filled in Phase 8.

Present the list of roots with a one-line preview each, then ask: "May I write this to `<root>/CLAUDE.md` for
<roots>?" The user may pick a subset; a skipped root is listed in the summary.

---

## Phase 11: Coherence and the Completion Marker

### 11a. Read back what was written

Run:

```bash
bash .claude/scripts/project-coherence.sh
```

It compares each configured component with its Pinned Components row, the backend runtime with the repository's
version files (`.nvmrc`, `.node-version`, `.python-version`, `.tool-versions`, `package.json` engines, Dockerfile
`FROM`), each framework's line with the manifest dependency in its roots, the lockfiles with
`stack.package_manager`, and every command that names a package script with that `package.json`.

- **Report every `MISMATCH` line** and resolve it with the user before finishing. One that is intended — a runtime
  upgrade the code has not caught up with (5e) — is named in the summary as known, with its reason.
- **`UNCHECKED` is not a pass.** Each such line says why a comparison could not run (a root with no code yet, a
  managed service, an accepted gap, a range the script does not evaluate). Say which ones applied.
- The script prints observations only; the judgement is the user's and yours.

### 11b. Completion check

`stack.pinned_on` may be written only when **every configured component** has a Pinned Components row whose Version
is sourced, `n/a (managed service)`, or `NOT DETERMINED — accepted by user YYYY-MM-DD`. Unconfigured layers do not
block it. If any configured component is still an unresolved `NOT DETERMINED`, or has no row, do **not** write the
marker: list the blocking components, and finish with verdict INCOMPLETE (Phase 14).

### 11c. Write the marker — last

When the check holds, ask: "May I write this to `project.yaml` (`stack.pinned_on: <today>`) and
`docs/stack-reference/VERSION.md` (the `**Stack Pinned**` row)?"

Write `pinned_on:` as an unquoted ISO date under `stack:` (`  pinned_on: 2026-09-27`), and the same date in the
`| **Stack Pinned** |` row. Then verify rather than assume:

1. Read both files back and confirm the two dates agree.
2. Run `bash .claude/scripts/artifact-check.sh --phase discovery` and confirm the `stack-setup` step now reads
   `status=PRESENT`. If it still reads `PATTERN_MISS`, the write did not land where the catalog looks — fix it before
   reporting success.

---

## Phase 12: `refresh`

Run when an Accepted ADR has added data or cloud components, when the session model's knowledge cutoff differs from
the recorded one, when `session-start.sh` warns that `stack.pinned_on` is set while the `**Stack Pinned**` row still
reads `NOT DETERMINED`, or simply when sources are old.

1. **Read state** — `project.yaml`, `docs/stack-reference/VERSION.md`, every component folder.
2. **Newly decided layers** — Grep `docs/architecture/adr-*.md` for Accepted ADRs whose `## Stack Compatibility`
   `**Domain**` is `Data` or `Infra` and whose `**Stack Components**` are not yet configured. Propose them, confirm the
   layer keys (Phase 4b/6a for those layers only), and pin them (Phase 5).
3. **Re-verify every row** — re-fetch each source. Update `Retrieved` (index row and the component's `**Retrieved**`)
   only for rows actually re-verified, and `| **Last Verified** |` to today when at least one was; a source that no
   longer resolves is replaced by a current one or reported as `could not re-verify — <url>` with the old date kept.
4. **Drift report** — newer stable releases (report `upgrade candidate: <component> <pinned> → <new>, released
   <date> — run /setup-stack upgrade <component> <pinned> <new>`; **never bump a version in refresh**), end-of-support
   dates now passed or within six months, and rows no configured component accounts for.
5. **Re-grade Knowledge Risk** if the recorded cutoff differs from the session model's; write the new cutoff to the
   `| **LLM Knowledge Cutoff** |` row. A component that moves to MEDIUM/HIGH gets its three reference files (8c).
6. **Code-root files** — update the Framework and Knowledge Risk rows of existing `<root>/CLAUDE.md` files that
   changed (ask).
7. **Coherence** — Phase 11a.
8. **Rewrite the marker** — Phase 11b and 11c: `stack.pinned_on` and the `**Stack Pinned**` row become today's date,
   under the same completion condition. If the condition no longer holds, leave the old marker in place and say why.

Every write is shown first and asked for ("May I write this to `<path>`?"); the summary lists what was re-verified,
what drifted, and what could not be checked.

---

## Phase 13: `upgrade <component> <old> <new>`

A deliberate version change for one component. It changes pins, references and records — **never source code**:
the code migrates through stories (`/create-stories`, `/dev-story`).

### 13a. Confirm the starting point

Find the component's Pinned Components row (match the component name or its slug). If `<old>` differs from the pinned
version, say so and ask which is right. If the component is not configured, stop: configure it with guided setup
first.

### 13b. Gather the migration facts from live sources

Use Context7 if its tools are present in the session, else WebSearch/WebFetch. For every version between `<old>` and
`<new>`: the official migration or upgrade guide, release notes, breaking changes, deprecations and removals, changed
defaults, available codemods; for runtimes the end-of-support schedule; for mobile components the current App Store
and Google Play submission requirements the new version affects. Record each URL. Unsourceable items are written
`NOT SOURCEABLE: <topic>`.

### 13c. Pre-upgrade audit of the code

Scan every code root the `code_roots` line lists (declared and undeclared) — iterate the roots, never assume one — with
Grep for the deprecated or removed APIs, configuration keys and imports the sources name. Present:

| File | API / config found | Change required | Effort (Low / Medium / High) |
|------|--------------------|-----------------|------------------------------|

plus the breaking changes to watch for and a dependency-ordered migration order. When `code_roots` is unresolved,
print `NOT CHECKED — no code root resolved (set stack.layers.<layer>.root via /setup-stack)` in place of the table. No
hits is reported as "No deprecated API usage found in <roots>", never as "safe".

### 13d. ADRs that depend on the component

Grep `docs/architecture/adr-*.md` for ADRs whose `## Stack Compatibility` section names the component (its
`**Stack Components**` row). Each one is listed as **re-validation required**. They are not edited here.

### 13e. TD-STACK-RISK

**Review mode check** — apply before spawning TD-STACK-RISK (`--review` overrides the resolved `review_mode`):

- `full` → spawn as normal.
- `lean` → **skip every gate whose ID does not end in `-PHASE-GATE`**. Note: `[GATE-ID] skipped — Lean mode`
  TD-STACK-RISK does not end in `-PHASE-GATE`, so lean skips it: record `[TD-STACK-RISK] skipped — Lean mode`.
- `solo` → skip all gates. Note: `[TD-STACK-RISK] skipped — Solo mode`.

A skipped review is written into the upgrade record where the review line would go, and the summary names the
omission: "TD-STACK-RISK not consulted — <Mode> mode; `--review full` runs it."

When it runs, spawn `technical-director` via `Agent`:

- Gate: **TD-STACK-RISK** — the prompt instructs the agent to read `.claude/docs/director-gates/td-stack-risk.md`
  first (do not read it or paste it yourself).
- Pass: component and version change (old → new, or pinned version) · `docs/stack-reference/<component>/` path · ADR paths whose `## Stack Compatibility` names the component
- Fill them from 13a–13d: `<Component> <old> → <new>`; the component folder; the ADR list (or "none"). Include the
  sources and the audit table in the prompt so the review works from them.

Parse the first line of the reply as `[TD-STACK-RISK]: TOKEN`, TOKEN one of `APPROVE`, `CONCERNS`, `REJECT`, and map it
with the verdict classes of `.claude/docs/director-gates.md` (`## Standard Verdict Format`):

- **APPROVE-class** (`APPROVE`) → continue to 13f.
- **CONCERNS-class** (`CONCERNS`) → present the concerns via `AskUserQuestion`: `Revise flagged items` /
  `Accept and proceed` / `Discuss further`.
- **REJECT-class** (`REJECT`) → present the blockers and the corrected approach. Write nothing; the pin stays at
  `<old>` (verdict INCOMPLETE). The user may re-run with a different target version.
- A first line that does not parse, or names another gate, is not an approval — treat it as CONCERNS-class and say
  the verdict line was missing.

### 13f. Write the upgrade

Show every change, then ask once for the set: "May I write this to <paths>?" — the paths being:

- `docs/stack-reference/<component>/upgrade-<old>-to-<new>.md` — the upgrade record (below);
- `docs/stack-reference/<component>/VERSION.md` — new `**Pinned Version**`, `**Release Date**`, `**Source**`,
  `**Retrieved**`, `**Knowledge Risk**`, and new sourced `## Post-Cutoff Changes (sourced)` bullets;
- `breaking-changes.md`, `deprecated-apis.md`, `current-best-practices.md` in the same folder — the new span appended
  under `## <old> → <new>` (created if the new version is MEDIUM/HIGH and they did not exist);
- `docs/stack-reference/VERSION.md` — the component's row (Version, Knowledge Risk, Source, Retrieved) and
  `| **Last Verified** |`;
- `project.yaml` — the layer's `version` key, or the trailing version inside the component string;
- the Framework / Knowledge Risk rows of the layer's `<root>/CLAUDE.md` files, where they exist.

The upgrade record:

```markdown
# Upgrade: <Component> <old> → <new>

> **Verdict**: <COMPLETE | INCOMPLETE | NOT ASSESSED>
> **Technical Director Review (TD-STACK-RISK)**: <APPROVED | CONCERNS (accepted) | REVISED> <YYYY-MM-DD>

## Sources
- <what the page states> (Source: <url>, retrieved YYYY-MM-DD)

## Breaking Changes
## Pre-Upgrade Audit
<the 13c table, or the NOT CHECKED line>

## ADRs — Re-validation Required
- docs/architecture/adr-NNNN-<slug>.md — <what in its Stack Compatibility depends on the old version>

## Migration Order
## Open Items
<NOT SOURCEABLE topics, concerns accepted, coherence MISMATCH lines expected until the code migrates>
```

When review mode skipped the gate, the second line is the skip note instead —
`> [TD-STACK-RISK] skipped — Lean mode` (or `— Solo mode`) — so the record shows the mode was applied.

After the write: run Phase 11a (the MISMATCH lines between the new pin and the not-yet-migrated manifests are the
code migration checklist — name them as expected), then Phase 11b/11c to rewrite `stack.pinned_on` and the
`**Stack Pinned**` row.

---

## Phase 14: Summary, Verdict and Next Steps

Output the summary:

```
Stack Setup — <guided | refresh | upgrade>
==========================================
Stack:           <the stack line from Phase 7c>
Code roots:      <the code_roots line>
Product facts:   surfaces=<…> distribution=<…> regions=<…> handles_pii=<…> locales=<…> (unset = asked later)
Pins:            <n> sourced · <n> managed · <n> accepted gaps · <n> unresolved
Knowledge Risk:  HIGH: <components> · MEDIUM: <components> · model cutoff <value>
Reference:       docs/stack-reference/VERSION.md + <n> component folders
Tech radar:      created | updated | unchanged
Root CLAUDE.md:  <roots written> | skipped: <roots>
Coherence:       <n> MATCH · <n> MISMATCH (<known / to fix>) · <n> UNCHECKED
Toolchain:       <probe results, NOT DETERMINED where a probe failed>
Not checked:     <every NOT CHECKED line of this run, or "none">
stack.pinned_on: <date> | not written — <blocking components>

Verdict: <COMPLETE | INCOMPLETE | NOT ASSESSED>
```

**Verdict** (precedence INCOMPLETE > NOT ASSESSED > COMPLETE):

- **COMPLETE** — every configured component is pinned (sourced, managed service, or accepted gap) and
  `stack.pinned_on` was written and verified in this run (`upgrade`: the new version is pinned and the ADRs are
  listed).
- **NOT ASSESSED** — nothing could be pinned: every layer was left unset, or no live source could be reached for any
  component and no gap was accepted. The summary says which.
- **INCOMPLETE** — at least one configured component is unresolved `NOT DETERMINED` or has no row while at least one
  live source was reached, a required write was declined, a `MISMATCH` the user did not accept remains, or
  TD-STACK-RISK returned a REJECT-class verdict; `stack.pinned_on` was not (re)written.

Then close with `AskUserQuestion` offering the next steps for the resolved tier (only the ones that apply):

**`minimal`**
- `/brainstorm` — when `design/product/one-pager.md` does not exist yet (its `## Stack` section then restates this
  setup in one line)
- `/create-stories` — turns the one-pager's `## Build Order` into stories
- `/dev-story` — implement the first story in the declared roots
- `/test-setup` — optional at this tier; scaffolds runners for the configured layers

**`standard` / `full`**
- `/brainstorm` — when `design/product/product-brief.md` does not exist yet
- `/prd-review design/product/product-brief.md` — required at standard/full before `/gate-check definition`
- `/prototype` — test the riskiest assumption before PRDs (optional)
- `/gate-check definition` — once the brief is reviewed and the stack is pinned
- `/architecture-decision` — for data and cloud: their Foundation ADRs, then `/setup-stack refresh` records them

**Any tier, when it applies**
- `/setup-stack refresh` — after resolving an INCOMPLETE item, or when a data/infra ADR is Accepted
- `/setup-stack upgrade <component> <old> <new>` — for each upgrade candidate reported
- `/architecture-review` — after an upgrade, to re-validate the listed ADRs
- `/help` — what comes next for this project

---

## Collaborative Protocol

This skill follows the collaborative design principle at every step, whatever `modes.automation` says:

1. **Question → Options → Decision → Draft → Approval** for each layer, pin, root, command and product fact.
2. **"May I write this to `<path>`?"** before every write — `project.yaml`, the stack reference, the tech radar, each
   `<root>/CLAUDE.md`, the upgrade record. A multi-file write is approved as one listed changeset.
3. **Unset stays unset.** A deferred answer is not written; readers ask later. Unset is never treated as "no" or
   "none".
4. **Sources over memory.** Every version and every reference fact carries its source and retrieval date, or says
   `NOT DETERMINED` / `NOT SOURCEABLE`.
5. **Skips announce themselves.** Every step that did not run — a skipped lead validation, a gate skipped by review
   mode, an unreachable source, an unresolved code root — appears in the summary as a `NOT CHECKED` line.
6. **No commits.** Committing is the user's decision.

## Guardrails

- Never guess a version; never record a knowledge cutoff later than the model can state.
- Never write `stack.pinned_on` before every configured component is sourced, managed or an accepted gap — and write
  it last.
- Never edit the repository-root `CLAUDE.md`, an ADR, or source code.
- Never overwrite existing reference files, the tech radar or a `<root>/CLAUDE.md` without showing the difference and
  asking; append version spans, never truncate them.
- Never pre-populate the Trial, Hold or Forbidden Patterns rings, and never add a library speculatively.
- Never record a production deploy command, and never run installs, generators, migrations or deploys.
- If sources disagree or search results are ambiguous, show them to the user and let them decide.
