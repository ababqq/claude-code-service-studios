# Code Root Resolution

Shared procedure for any skill, hook or script that reads, scans, counts or
writes product source files. Skills cite this file at the point of use and keep
the one load-bearing imperative inline — **an unresolved code root means the
check did not run** — while this file holds the resolution order.

A service repository rarely has one code tree. A monorepo carries a web app, an
admin console, a mobile app, an API, background workers, shared packages and
infrastructure side by side; a single-app repository has one `src/` or `app/`.
There is therefore **no fixed code root**: each stack layer declares its own in
`project.yaml` (`/setup-stack` writes them), and the helper below turns those
declarations — plus what is actually on disk — into the list every consumer
uses. `.claude/docs/directory-structure.md` shows where code roots sit in the
repository layout; this file is the procedure for finding them.

## The contract — `resolve_code_roots`

Implemented once, in `.claude/hooks/yaml-helper.sh`, so a hook, a script and a
skill never disagree about where the code lives:

```
resolve_code_roots
  prints one line per root:  <dir>\t<layer>\t<source>
    dir    = repo-relative path (field 1, so existing `cut -f1` consumers keep working)
    layer  ∈ web | mobile | backend | cloud | data | shared | app | undeclared
    source ∈ project.yaml | missing | workspace | detected
  prints nothing when unresolved; exit 0 always
```

| `source` | Meaning | Scanned? |
|---|---|---|
| `project.yaml` | declared in `project.yaml` and present on disk | yes |
| `missing` | declared in `project.yaml`, not on disk yet | no — nothing to scan; a writer that creates the app (e.g. `/walking-skeleton`) may create it |
| `workspace` | a workspace package with a manifest that no layer declares (`layer` = `undeclared`) | yes, with the WARN line below |
| `detected` | single-app repository, derived from the tree (`layer` = `app`) | yes |

Field 1 is always the directory, so `resolve_code_roots | cut -f1` yields one
directory per line. Consumers iterate the lines; none of them may assume there
is only one.

## Algorithm

1. For `layer` in `web mobile backend cloud` (fixed order): read
   `stack.layers.<layer>.root`. The value is a scalar path or a flow list
   `[a, b]` (parsed with the `get_yaml_array` parser; `/setup-stack` writes flow
   lists). For each entry emit `<root>\t<layer>\tproject.yaml` when the
   directory exists, else `<root>\t<layer>\tmissing`.
2. `data`: if `stack.layers.data.migrations_dir` is set, emit
   `<dir>\tdata\tproject.yaml` (or `missing`).
3. For each entry of `stack.shared_roots`: emit `<dir>\tshared\tproject.yaml`
   (or `missing`).
4. **Always** — derivation, obligation 5 of `.claude/rules/skill-authoring.md`:
   for every directory matching `apps/*`, `services/*` or `packages/*` that
   contains a manifest (`package.json`, `pyproject.toml`, `build.gradle`,
   `build.gradle.kts`, `pom.xml`, `go.mod`, `pubspec.yaml`, `Cargo.toml`,
   `composer.json`, `Gemfile`) and is **not** equal to or inside a root emitted by
   steps 1–3, emit `<dir>\tundeclared\tworkspace`.
5. **Only if steps 1–4 emitted nothing**: if the repository root has a manifest
   and **exactly one** of `src/`, `app/`, `lib/` exists, emit
   `<that dir>\tapp\tdetected`. Zero or several ⇒ emit nothing — the project is
   genuinely undecidable, and guessing would scan half of it and report a pass.
6. Never default to `src`. Callers that get no lines print
   `NOT CHECKED — no code root resolved (set stack.layers.<layer>.root via /setup-stack)`
   and skip their scan.

Paths are normalised (no leading `./`, no trailing `/`). The template ships no
code-root directory, so an unconfigured clone resolves nothing and says so.

### Example — Moa

The Moa monorepo (web + admin console, React Native app, NestJS API with a
worker, shared packages, Terraform) declares:

```yaml
stack:
  shared_roots: [packages]
  layers:
    web:
      root: [apps/web, apps/admin]
    mobile:
      root: apps/mobile
    backend:
      root: [apps/api, services/worker]
    data:
      migrations_dir: apps/api/prisma/migrations
    cloud:
      root: infra
```

(Only the root keys are shown; the full stack block is in `effects-map.md`
§ "Complete example `project.yaml`".) With every directory on disk and one
package nobody declared, `services/notifier/package.json`:

```
apps/web	web	project.yaml
apps/admin	web	project.yaml
apps/mobile	mobile	project.yaml
apps/api	backend	project.yaml
services/worker	backend	project.yaml
infra	cloud	project.yaml
apps/api/prisma/migrations	data	project.yaml
packages	shared	project.yaml
services/notifier	undeclared	workspace
```

`packages/ui` has a manifest too, but it sits inside the declared shared root
`packages`, so it is not reported as undeclared. Skills read the same result
from the `code_roots` label of `resolve_config`
(`.claude/docs/config-resolution.md` § "code_roots line"):

```
code_roots: web=apps/web,apps/admin; mobile=apps/mobile; backend=apps/api,services/worker; cloud=infra; data=apps/api/prisma/migrations; shared=packages (project.yaml); undeclared=services/notifier (workspace); extensions: ts tsx js jsx mjs cjs vue svelte sql tf
```

## Undeclared roots

An `undeclared` root is real code that the configuration does not know about —
the classic case is a new service added under `services/` after
`/setup-stack` ran. Callers **include it in their scans** (skipping it would
reproduce the silent-pass problem this file exists for) and print one warning
line naming every undeclared directory:

```
WARN: undeclared code roots: services/notifier — declare them with /setup-stack
```

Running `/setup-stack` again declares the directory in the right layer (or in
`stack.shared_roots`), after which the warning stops.

## Scanning — `list_code_files`

Every multi-root scan goes through one sourced helper instead of hand-rolled
`find`/`grep` loops:

```
list_code_files [--limit N]
```

- Walks every `resolve_code_roots` directory whose source is `project.yaml`,
  `workspace` or `detected` — **never `missing`**.
- Prunes the directories named in `_yaml_helper_scan_prune`:
  `node_modules .next .nuxt .output .turbo .vercel .expo dist build out coverage Pods DerivedData .gradle .dart_tool .venv venv __pycache__ .terraform vendor target .git`.
  Without the prune a web root's `node_modules` alone outnumbers its sources by
  orders of magnitude, so a capped scan would count vendored files and stop.
- Keeps files whose extension is in `code_extensions` (below).
- Prints one repo-relative path per line; with `--limit N` stops after `N`
  files. A root nested inside another listed root (for example the migrations
  directory inside `apps/api`) is walked once, through its parent.
- Prints nothing when no root resolves — the caller prints its `NOT CHECKED`
  line. It is **not** dispatchable: hooks and scripts `source` the helper; skills
  use the `code_roots` label and their own Glob/Grep over the listed roots.

## Extensions — `code_extensions`

Prints a space-separated extension list derived from the configured `language`,
`framework` and `runtime` values of the web, mobile and backend layers:

| Configured | Extensions |
|---|---|
| TypeScript / JavaScript (incl. Node.js, Next.js, React, React Native, Expo, Vue, Nuxt, Svelte, NestJS, Express, Fastify, Hono) | `ts tsx js jsx mjs cjs vue svelte` |
| Python (incl. Django, FastAPI, Flask) | `py` |
| Java / Kotlin (incl. Spring, Jetpack Compose, Ktor) | `java kt kts` |
| Swift | `swift` |
| Dart (incl. Flutter) | `dart` |
| Go | `go` |
| Ruby (incl. Rails) | `rb` |
| PHP (incl. Laravel, Symfony) | `php` |
| C# (incl. .NET) | `cs` |
| Rust | `rs` |
| a data layer is set (`database` or `migrations_dir`) | adds `sql` |
| `stack.layers.cloud.iac` is Terraform (or OpenTofu) | adds `tf` |

Nothing configured ⇒ the union of all of the above, and the caller announces it
as `extensions: default union`. A union scan is slower but never blind; a
narrower guess would be.

## Unresolved does not default to `src/`

This is the rule the whole file exists for, and it is obligation 2 of
`.claude/rules/skill-authoring.md`: an absent value may not default to the
permissive one.

**For a read or scan:** print
`NOT CHECKED — no code root resolved (set stack.layers.<layer>.root via /setup-stack)`
and say which check did not run. Never report zero hits.

A scan anchored to a root the project does not use matches nothing, and
**nothing is indistinguishable from a clean result.** A localization check finds
no hardcoded strings; a security scan finds no leaked keys; a feature audit
counts no implemented features; a stage estimator counts no source files and
calls a shipped product a blank slate. Every one of those reads as a pass. The
same blind spot appears one level down when a scan covers one root of a
monorepo — `apps/web` scanned, `apps/api` and `services/worker` never opened —
which is why resolution is multi-root and lives in one place.

**For a write:** do not write. Report the unresolved root and stop. Writing to a
guessed directory is worse than a false pass: in a workspace monorepo, code
placed outside any package is never built, typechecked or deployed, so the work
is silently inert. Resolving a layer's framework to pick a specialist agent is
**not** the same as resolving where its code lives — a skill can do the first
correctly and still write to the wrong directory.

## Surfaces and roots

Stories name the surface they change in their `> **Surface**:` header field
(written by `/create-stories`; a comma list, the first value primary).
`/dev-story`, `/walking-skeleton`, `/test-setup`, `/story-done`, `/team-feature`
and `/team-ui` map it to a root from `resolve_code_roots`:

| Surface | Root used |
|---|---|
| `web` | the `web` root; if the web layer lists several roots, the one the story's `**Stack Notes**` or file list names, else ask |
| `ios`, `android`, `mobile` | the `mobile` root (same multi-root rule) |
| `api` | the `backend` root (same multi-root rule) |
| `admin` | the `web` root whose last path segment contains `admin`, if exactly one; else ask — never guess |
| `infra` | the `cloud` root |
| `analytics` | ask (no stack layer owns pipelines); record the answer in the story's `**Stack Notes**` |
| migrations (any story with `**Migration**` ≠ None) | `stack.layers.data.migrations_dir` |
| Layer `Foundation` shared code | the first `shared` root, else ask |

- Only an `app` root resolved (single-app repository) ⇒ use it for every surface.
- Only `detected` / `undeclared` roots ⇒ ask the user to choose, and suggest
  `/setup-stack`.
- Nothing resolved ⇒ do not write code; print
  `NOT CHECKED — no code root resolved (set stack.layers.<layer>.root via /setup-stack)`.

Beneath the chosen root, follow the framework's own conventions (the App Router
`app/` tree in Next.js, `src/modules/<feature>/` in NestJS, `lib/` in Flutter)
and the root's own `CLAUDE.md`, which `/setup-stack` offers to create from
`.claude/docs/templates/code-root-claude.md`.

## Consumers

Every consumer iterates lines (field 1 is the directory); none reads a single
root:

| Consumer | Use |
|---|---|
| `.claude/hooks/validate-commit.sh` | staged-file filter = any root prefix; scans the staged files under every root; unresolved ⇒ a `SKIPPED:` note naming `/setup-stack` |
| `.claude/hooks/detect-gaps.sh` | code-vs-PRD sparsity (via `list_code_files`), missing ADRs, backend root without an API contract, data-layer migrations_dir with files but no docs/data/data-model.md; unresolved ⇒ `NOT CHECKED` lines |
| `.claude/hooks/session-start.sh` | TODO/FIXME count via `list_code_files --limit 2000` within a 2-second budget, plus the undeclared-roots WARN line |
| `.claude/scripts/stage-estimate.sh` | the Build rung's source-file count via `list_code_files --limit 10` (skipped with `--quick`) |
| `.claude/statusline.sh` | no longer counts files: it shows the stage from `stage-estimate.sh --quick` |
| skills | every skill whose bootstrap `--keys` include `code_roots` reads the `code_roots` label — grep the SKILL.md bootstrap lines for the current set rather than trusting a list here |
