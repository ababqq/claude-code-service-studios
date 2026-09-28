# Config Resolution

How a skill learns its effective settings. **One command, no prose chain.**

## The rule

A skill that needs config puts this as the first line of its **body** (not
frontmatter):

````markdown
!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys a,b`
````

**and** pre-approves exactly that command in its own frontmatter, with its own
directory name in the path:

````yaml
allowed-tools: Read, …, Bash(bash "*/.claude/skills/<skill-name>/../../hooks/yaml-helper.sh" resolve_config *)
````

The command runs as preprocessing *before the model sees the skill*, and its
output replaces the placeholder inline. The skill then reads the resolved values
and **does not re-derive them**. The line after the bootstrap block is exactly
one of:

- with `review_mode` in the keys: ``Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.``
- otherwise: ``Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.``

Every label in `--keys` must be one of the labels in [Labels](#labels) below.

**Per-feature tiers.** `workflow_overrides.feature_overrides` maps a PRD stem
(`design/prd/<stem>.md`) to a tier. The `feature_overrides` label dumps the whole
map, so a skill that learns the feature at run time looks its stem up there and
falls back to `workflow` when the stem is absent. A caller that already knows the
stem may pass it positionally — `resolve_config --keys workflow,feature_overrides
payments` — and gets one more line, `workflow[payments]: full (feature_overrides)`
or `workflow[payments]: standard (no override — project value)`.

## Why the body, not `context:`

`` !`cmd` `` in the skill body is the documented mechanism. Frontmatter
`context:` accepts only `context: fork` — it does **not** run shell. A
`context: |` block containing `!` commands **never executes**; put the command in
the skill body instead.

## Why exactly this command — the permission check

Claude Code permission-checks every injected command **before** the skill
renders. Outside auto mode, anything that does not come back "allow" — including
a command that would normally just prompt — **aborts the whole invocation**, and
the model never sees the skill. A preloaded skill (`skills:` on an agent) is
checked the same way at agent launch, so a failing bootstrap line stops the agent
from starting (GitHub issue #128). Measured on Claude Code 2.1.281 in default
mode:

| Bootstrap form | Repo root | Subdirectory | Bash-less agent preloading it |
|---|---|---|---|
| `source "${CLAUDE_PROJECT_DIR:-.}/…" && resolve_config` | aborts | aborts | fails to launch |
| same, with a bare `Bash` grant | aborts | — | — |
| `bash "${CLAUDE_PROJECT_DIR}/…"` + grant | runs | aborts | — |
| **`bash "${CLAUDE_SKILL_DIR}/../../hooks/…"` + per-skill grant** | **runs** | **runs** | **launches** |

What that table rules out:

- **No `${VAR:-x}` expansion.** It fails as "Contains expansion", and no grant
  can approve it. `${CLAUDE_SKILL_DIR}` and `${CLAUDE_PROJECT_DIR}` are fine: Claude
  Code substitutes them as text before the check.
- **No `${CLAUDE_PROJECT_DIR}` for the path.** In a skill it is the directory
  Claude Code was launched from, not the repo root, so it breaks when a session
  starts inside `apps/web/` or any other subdirectory. `${CLAUDE_SKILL_DIR}`
  always names the skill's own folder.
- **No `source … && …` compound.** Each part must be approved; `bash <file>
  resolve_config` is one command. `yaml-helper.sh` dispatches only
  `resolve_config` when executed, and finds the repo root from its own location.
- **The grant is required.** `allowed-tools` is what pre-approves an injected
  command. The pattern must include the literal `"` after the path — a pattern
  ending `…yaml-helper.sh *` does not match.
- **Any non-zero exit aborts too.** The entry point always exits 0; other
  injected commands that can fail end in `|| true`.
- **No second injection.** The bootstrap line is the only `!` injection a skill
  carries, and no injection contains `$(`, `${`, `;`, `|` or `&&`. Everything
  else a skill needs (sprint status, stage estimate, session state) it gathers at
  run time with Read, Glob or Bash.

Auto mode can approve the `source … &&` form on its own, which is how a broken
bootstrap can ship unnoticed. Test bootstrap changes in default mode, in a
project without a `settings.local.json`.

`disableSkillShellExecution: true` replaces every injected command with a
placeholder message. If a skill sees no config block, it falls back to the
defaults below.

## The block

Full form (no `--keys`), for the Moa example project — a Korean B2C savings app
with web, admin, mobile and API surfaces, `modes.rigor: standard` in
`project.yaml`, and one developer's `project.local.yaml` setting
`modes.automation: guided` and `testing.strict.e2e: false`:

```
=== CCSS Resolved Config ===
rigor: standard (project.yaml)
review_mode: lean (rigor:standard)
automation: guided (project.local.yaml)
workflow: standard (rigor:standard)
docs.density: balanced (rigor:standard)
story_granularity: balanced (rigor:standard)
qa.level: standard (rigor:standard)
team.size: individual (rigor:standard)
project.stage: Build (project.yaml)
automation_always_ask: scope_changes, file_deletions, schema_changes, production_deploys, db_migrations, infra_changes, secrets_access, pii_data_access, billing_changes (default)
testing.strict: logic=true integration=true ui=unset e2e=false config=unset (unset = each skill applies its own default)
performance.enforce: warn (default)
feature_overrides: payments=full admin-console=minimal
stack: web=Next.js 15.3 (language=TypeScript) @apps/web,apps/admin; mobile=React Native (Expo) 0.79 (language=TypeScript) @apps/mobile; backend=NestJS 11.0 (language=TypeScript, runtime=Node.js 22) @apps/api,services/worker; data=PostgreSQL 16 (cache=Redis 7, queue=none, orm=Prisma 6); cloud=AWS (iac=Terraform 1.9) @infra [routing: web-specialist>nextjs-specialist, mobile-specialist>react-native-specialist, backend-specialist>node-specialist, data-specialist, cloud-specialist] (project.yaml)
code_roots: web=apps/web,apps/admin; mobile=apps/mobile; backend=apps/api,services/worker; cloud=infra; data=apps/api/prisma/migrations; shared=packages (project.yaml); undeclared=services/notifier (workspace); extensions: ts tsx js jsx mjs cjs vue svelte sql tf
platform.surfaces: web, ios, android, api (project.yaml)
release.distribution: web+stores (project.yaml)
compliance: regions=kr handles_pii=true (project.yaml)
accessibility.target: wcag-aa (project.yaml)
notes: none
Values above are fully resolved (local -> yaml -> rigor -> default). Use as-is.
An inline --review flag, if passed, overrides review_mode.
=== end CCSS config ===
```

(Version numbers in the example are illustrative placeholders; real pins come
from `/setup-stack` and `docs/stack-reference/VERSION.md`.)

With `--keys` and three or more labels the block is terse — the header states
the chain once, `notes:` appears only when something went wrong, and the footer
is `=== end ===`:

```
=== CCSS Config (resolved: local->yaml->rigor->default; use as-is) ===
review_mode: lean (rigor:standard)
workflow: standard (rigor:standard)
feature_overrides: payments=full admin-console=minimal
workflow[payments]: full (feature_overrides)
=== end ===
```

With **one or two** labels there is no framing at all — `automation: guided
(project.local.yaml)` is self-describing, and a banner would cost more than the
line. A `notes:` line is still printed whenever there is something to say.

Output order is fixed (the order of the table below), whatever order `--keys`
names the labels in. Every knob line ends with its **provenance** in
parentheses. That is what makes a wrong value diagnosable — `review_mode: solo
(rigor:minimal)` when `project.yaml` was meant to say `full` points straight at
the problem.

## Labels

The exact vocabulary. A label outside this table prints nothing and is named on
`notes:` (`unknown label ignored — <label>`): a skill asking for a label that
does not exist must not silently run on defaults.

| Label | Emits | Source handling |
|---|---|---|
| `rigor` | `rigor: <v> (<src>)` | chain (below) |
| `review_mode` `automation` `workflow` `docs.density` `story_granularity` `qa.level` `team.size` `project.stage` | `<label>: <v> (<src>)`; `not set (unset)` when nothing resolves | chain |
| `automation_always_ask` | the configured list `(configured)` or the default list `(default)` | array; local then project, both on the whitelist |
| `testing.strict` | `testing.strict: logic=<v> integration=<v> ui=<v> e2e=<v> config=<v> (unset = each skill applies its own default)` | chain per type key; `unset` where nothing is configured |
| `performance.enforce` | `performance.enforce: <v> (<src>)` | chain (default `warn`) |
| `feature_overrides` | `feature_overrides: <stem>=<tier> …` or `feature_overrides: none`; the positional `<feature>` adds `workflow[<feature>]: …` | map dump from `project.yaml`; each tier validated |
| `stack` | `stack: <layer>=<component> … [routing: …] (project.yaml)` or `stack: unset — run /setup-stack` | `project.yaml` only, plus the routing function |
| `code_roots` | `code_roots: <layer>=<dirs>; … (<source>); …; extensions: <list>` or `code_roots: unresolved — NOT CHECKED (set stack.layers.<layer>.root via /setup-stack)` | `resolve_code_roots` + `code_extensions` |
| `surfaces` | `platform.surfaces: web, ios, api (project.yaml)` or `platform.surfaces: (unset -- ask which surfaces ship)` | array-element enum |
| `distribution` (also accepted: `release.distribution`) | `release.distribution: <v> (project.yaml)` or `release.distribution: (unset -- ask how this release ships)` | chain; not locally overridable; no default |
| `compliance` | `compliance: regions=kr,eu handles_pii=true (project.yaml)`; `regions=none` for `[]`; each unset part prints `(unset -- ask)` | array-element enum + chain for `privacy.handles_pii` |
| `accessibility` | `accessibility.target: <v> (project.yaml)` or `accessibility.target: (unset -- ask; unset is not none)` | chain; no default |

### `stack` line

Every one of the five layers — `web`, `mobile`, `backend`, `data`, `cloud` —
appears either as `<layer>=…` or in `unset=`, so "not configured" can never be
mistaken for "not printed". A layer is configured when its configuring key is
set: `framework` for web, mobile and backend; `database` for data; `provider`
for cloud. Each configured layer prints its configuring value, then the
`version` key (web, mobile, backend), then any of `language`, `runtime`,
`cache`, `queue`, `orm`, `iac` in parentheses, then its roots after `@`:

```
stack: web=Next.js 15.3 @apps/web,apps/admin; backend=NestJS 11.0 @apps/api,services/worker; data=PostgreSQL 16; unset=mobile,cloud [routing: web-specialist>nextjs-specialist, backend-specialist>node-specialist, data-specialist] (project.yaml)
```

- ` pinned_on=unset` is added (before `[routing:`) while `stack.pinned_on` is
  unset — the stack has not finished `/setup-stack`'s version pinning.
- `[routing: …]` lists, per configured layer, `<lead>`, `<lead>><sub>` or
  `<lead>><sub1>+<sub2>` (native mobile). The sub is derived from the layer's
  framework (effects-map.md § "stack.layers and specialists" has the rules);
  `specialists.<layer>` overrides it. An override that is not one of that lead's
  own sub-specialists (or the lead itself, meaning "no sub") is ignored and named
  on `notes:`.
- An unconfigured layer spawns no specialist; the skill prints
  `NOT CHECKED — <layer> layer not configured (run /setup-stack)`.

### `code_roots` line

The roots `resolve_code_roots` finds, grouped by source in the order
`project.yaml`, `missing`, `workspace`, `detected`, then the extension list scans
use. `.claude/docs/code-root-resolution.md` has the algorithm; the line is its
one-line summary for skills:

```
code_roots: web=apps/web,apps/admin; backend=apps/api,services/worker; data=apps/api/prisma/migrations; shared=packages (project.yaml); undeclared=services/notifier (workspace); extensions: ts tsx js jsx mjs cjs vue svelte sql
```

`missing` = declared in `project.yaml` but not on disk (scans skip it; a skill
that creates the app, such as `/walking-skeleton`, may create it).
`undeclared=… (workspace)` = a workspace package nobody declared: scan it, and
print `WARN: undeclared code roots: <dirs> — declare them with /setup-stack`. When
no language or framework is configured the list reads `extensions: default union
— …`.

### Array-element enums

`platform.surfaces` (`web|ios|android|api`) and `compliance.regions`
(`kr|eu|us`) are lists whose **elements** are validated one by one:

- An invalid element is dropped and named on `notes:` —
  `platform.surfaces: dropped invalid element 'iso' (expected: web|ios|android|api)`
  — and the valid rest survives.
- **Set-but-empty is not unset.** `compliance.regions: []` means "explicitly
  none" and prints `regions=none`; an absent key prints `regions=(unset -- ask)`.
  `platform.surfaces: []` is invalid — a product ships at least one surface — so
  it is noted and treated as unset.
- A scalar written where the list belongs counts as a one-element list.
- `/settings` validates a pending write with `validate_enum_value`, which accepts
  `a,b` or `[a, b]`, checks every element, and rejects the whole write when any
  element is invalid. It writes lists in flow style `[a, b]`.

## Resolution chain

| Step | Source | Applies to |
|---|---|---|
| 1 | `project.local.yaml` | only the keys on the `/settings --local` whitelist: `modes.review_mode`, `modes.automation`, `modes.automation_always_ask`, `team.size`, `testing.strict.logic`, `testing.strict.integration`, `testing.strict.ui`, `testing.strict.e2e`, `testing.strict.config`, `performance.enforce`, `features.session_state`, `features.token_budget_warn_at` |
| 2 | `project.yaml` | all keys |
| 3 | **`modes.rigor` expansion** | the six knobs `rigor` fronts — `modes.workflow`, `docs.density`, `qa.level`, `modes.story_granularity`, `modes.review_mode`, `team.size` |
| 4 | terminal default | the three keys in the table below — nothing else |

An **enum-invalid value does not win** — the chain continues past it and the
rejected value is named on the `notes:` line. A typo degrades to the next source
and ultimately the documented default (or to unset), rather than propagating a
nonsense mode into every skill.

> **Step 3 sits below every explicit source and above the terminal default, and
> that ordering is the whole contract.** A `project.yaml` that sets
> `docs.density: terse` keeps it whatever `rigor` says, because step 2 answers
> first. Invert steps 3 and 4 and `rigor` becomes a no-op; hoist step 3 above
> step 2 and it silently overrides settings people wrote down on purpose.
>
> Derived values report their provenance as **`rigor:<level>`**, so the source
> vocabulary is `{project.local.yaml, project.yaml, rigor:<level>, default,
> unset}`. `docs.density: balanced (rigor:standard)` says the value was never
> written down anywhere — it follows the project's rigor level and will move if
> that level moves.

> **Read scope == write whitelist.** Anything `/settings --local` may *write*
> is also *read* during resolution (`_yaml_helper_local_read_scope` is set from
> `_yaml_helper_locally_overridable`). If the read scope were ever narrower,
> `/settings --local modes.review_mode=solo` would write a value that `/settings`
> accepted and displayed and every skill then ignored. Adding a setting to one
> list without the other reproduces that bug. The convenience readers
> `get_effective_yaml_key` / `get_effective_yaml_array` apply the same gate: a
> locked key in `project.local.yaml` is never read, by any path.
>
> `effects-map.md` § "Local Override Pattern" states the same chain and the same
> whitelist, with the reason each locked key is project-wide.

> **A key OUTSIDE the whitelist, hand-written into `project.local.yaml`, is
> reported rather than swallowed.** `/settings --local` refuses to write one, but
> the file exists to be edited by hand, so that path needs its own guard.
> `modes.rigor: full` or `release.distribution: web` written there is a real key
> with a legal value, so `validate_yaml_enum` passes it — and then resolution
> never consults the local file for that path, so the setting vanishes and the
> user sees the value they were trying to override, with no error anywhere. Every
> check in the chain validates the **value**; only `validate_local_scope`
> validates the **location**.
>
> `validate_local_scope` names such keys on `notes:`. It **warns and never
> reconciles**: it does not edit the file, does not begin honouring the key, and
> does not change resolution. A locked setting is locked because it decides which
> artifacts exist on disk (or, like `release.distribution`, what ships), so a
> helper that quietly applied one would let two developers' checkouts diverge —
> the exact thing the whitelist prevents. The user moves the key to
> `project.yaml` or deletes it.
>
> `schema_version` and `framework.*` are exempt: `effects-map.md` classes them as
> file metadata rather than preferences, and a `project.local.yaml` carrying
> `schema_version: 1` is correct as written.

## Defaults

Unset on an unconfigured project: `modes.rigor` defaults to `minimal`, which resolves `review_mode` to `solo`.

| Knob | Default |
|---|---|
| `modes.automation` | `collaborative` |
| `modes.rigor` | `minimal` |
| `performance.enforce` | `warn` |
| `modes.automation_always_ask` | `scope_changes`, `file_deletions`, `schema_changes`, `production_deploys`, `db_migrations`, `infra_changes`, `secrets_access`, `pii_data_access`, `billing_changes` (the list `is_always_ask_category` falls back to; not a chain default — see `.claude/docs/automation-modes.md` for what each category covers) |

**The six knobs `rigor` fronts have no terminal default at all.**
`modes.workflow`, `docs.density`, `qa.level`, `modes.story_granularity`,
`modes.review_mode` and `team.size` are deliberately absent from
`_yaml_helper_defaults`: a default there would answer at step 4 before the
expansion at step 3 ever ran, making `rigor` a no-op for anyone who had not also
set the sub-knob. No template, skill or onboarding step writes them into
`project.yaml` either — seeding one pins it and shadows the expansion the same
way. Their effective values come from the rigor level:

| `modes.rigor` | `modes.workflow` | `docs.density` | `qa.level` | `modes.story_granularity` | `modes.review_mode` | `team.size` |
|---|---|---|---|---|---|---|
| `minimal` (default) | `minimal` | `terse` | `minimal` | `coarse` | `solo` | `individual` |
| `standard` | `standard` | `balanced` | `standard` | `balanced` | `lean` | `individual` |
| `full` | `full` | `thorough` | `full` | `fine` | `full` | `studio` |

`minimal` is the default because the heavier tier measured several times more
expensive to reach working code without producing a better result; see the
rationale block above `_yaml_helper_defaults` in `.claude/hooks/yaml-helper.sh`
for the reasoning and the ordering constraint it places on `/gate-check`.
Raising the tier is one question in `/start` or one `/settings` call, and the
upward triggers in `settings-guidance.md` § 4 are written to fire from this
starting state. (`team.size` is the one knob `minimal` and `standard` agree on:
both yield `individual`, and only `full` opts into the `studio` roster.)

A `project.yaml` that sets some of the six explicitly but never sets `rigor`
keeps its explicit values and takes the `minimal` row for the rest.

`modes.workflow` is **fronted, not replaced**: it keeps
`workflow_overrides.feature_overrides`, which still beats the derived value for
the features it names. Setting any of the six explicitly overrides just that one
and leaves its siblings on the rigor level, which is how "comprehensive but
compact" (`rigor: full` + `docs.density: terse`) stays expressible. Two of the
six — `modes.review_mode` and `team.size` — are personal-experience knobs that
also remain overridable from `project.local.yaml` (that source sits above the
expansion), unlike the four on-disk knobs, which are locked. Only `/settings`
ever writes `modes.review_mode`.

> **The helper is the source for both tables.** `_yaml_helper_defaults` and
> `_yaml_helper_rigor_expansion` in `yaml-helper.sh` are what resolution reads;
> these tables restate them. If the two ever disagree, the helper is right and
> this page is the bug — check with `resolve_config` on a scratch copy (see
> [Verifying a change](#verifying-a-change)).

**`testing.strict.*` has no central default on purpose.** Its unset default
differs per skill by design: `/smoke-check` treats unset as **blocking** (it is a
build-health gate), while `/story-done` and `/dev-story` apply the per-story-type
table in `.claude/docs/coding-standards.md`. `resolve_config` therefore reports
only the *configured state* (`unset` where absent) and each skill applies its own
default. The script resolves **sources**; the skill owns **policy**.

**Unset means "ask" for five keys.** `platform.surfaces`,
`release.distribution`, `compliance.regions`, `privacy.handles_pii` and
`accessibility.target` have no default anywhere, and their labels say so in the
line itself (`(unset -- ask …)`). Obligation 2 of
`.claude/rules/skill-authoring.md` — absence is not a permissive default — is
why: a default of `web`, `[]`, `false` or `none` would make the question
unaskable, and `unset` is not `false` (PII) and not `none` (accessibility).

**The stack is `project.yaml` only.** `stack`, `code_roots`, `surfaces` and
`compliance` never read `project.local.yaml` — the stack, the surfaces and the
regulatory scope are project facts that every developer shares.

Keys that have **no** label — `performance.*` budgets, `testing.patterns`,
`testing.framework`, `naming.*`, `commands.*`, `localization.locales`,
`platform.browsers`, `platform.min_os.*`, `stack.monorepo`,
`stack.package_manager` — are read from `project.yaml` with Read at run time
(`project.local.yaml` is not consulted for them).

## Failure modes

`resolve_config` **always exits 0 and always emits a complete block.** Each
condition below degrades to defaults (or to unset) and is named on `notes:`:

| Condition | Behavior |
|---|---|
| `project.yaml` absent | defaults; `notes: project.yaml absent — defaults in use` |
| `project.yaml` **empty** | defaults; `notes: project.yaml is EMPTY`. Distinct from absent on purpose — a truncated write or an interrupted `/setup-stack` looks like this |
| Malformed YAML | unparseable keys resolve empty and fall through |
| Tab-indented lines | rejected, and the **line numbers are named** on `notes:` |
| CRLF line endings | parsed correctly (the Windows default) |
| UTF-8 BOM | parsed correctly; the BOM does not poison the first key |
| 3-space indent | parsed correctly; the parser is indent-tolerant |
| Key present, value empty | treated as **unset**; falls through to the next source, never to `""` |
| Enum-invalid scalar value | chain continues; rejected value named on `notes:` |
| Invalid array element | element dropped, the rest kept; named on `notes:` |
| `platform.surfaces: []` | treated as unset; named on `notes:` (`compliance.regions: []` is valid: explicitly none) |
| A map where a list belongs | treated as unset; named on `notes:` |
| Invalid `feature_overrides` tier | that entry dropped; named on `notes:` |
| Invalid `specialists.<layer>` | ignored, derived routing used; named on `notes:` |
| Unknown label in `--keys` | nothing printed for it; named on `notes:` |
| `project.local.yaml` without a base | `validate_local_yaml_base` message on `notes:` |
| Locked key in `project.local.yaml` | ignored, and **named** on `notes:` — `local: not locally overridable, ignored — modes.rigor (move to project.yaml or delete)` |
| No Python interpreter | defaults only; **explicitly noted** on `notes:` |
| No block at all | shell preprocessing disabled (`disableSkillShellExecution`) — use the defaults above |
| Bootstrap line not approved, or exits non-zero | **not a degraded state — the skill never renders at all.** See "Why exactly this command" above |

A skill must never treat a missing block as "config is unset in an interesting
way". It means the block did not render; the defaults apply.

### Two behaviours that are correct but SILENT

In both cases the resolved *value* is right — the chain falls through to the
default — but the user is told nothing, and their explicit configuration was
discarded.

| Input | What happens | Note emitted |
|---|---|---|
| **Duplicate key** (`rigor:` twice in one block) | **the last occurrence wins**, deterministically | **none** |
| **Block list where a scalar belongs** (`rigor:` followed by `- standard`) | key resolves empty, falls through to the default | **none** |

**Why this is worth knowing rather than shrugging at.** An enum-*invalid* value is
announced (`modes.workflow: 'medium' is not a valid value … — ignored, chain
continued`), and so is a *flow* list under a scalar key (`modes.rigor: '[full]' is
not a valid value …`), because the scalar parser reads it as text. A block list
under a scalar key is not: the scalar parser sees a key with no value and
nothing to validate. So a user who mistypes the value gets told, and a user who
mistypes the *structure* in that one shape does not.

**Not fixed, deliberately.** Detecting "this key is present in the file but
resolved to nothing" means changing the parser every config read in the
framework goes through, and the empty-value fall-through above is a
*legitimate* case of exactly that signature. Distinguishing "empty on purpose"
from "unparseable" is real work in the most load-bearing file there is.

**Duplicate-key precedence is last-wins.** It is deterministic and reproducible,
so it is not a bug — and it is written down here so it can be relied on.

## Why not inject at session start

`resolve_config` is also safe to call from a hook, but session-start does **not**
call it. The block would cost tokens on every session whether or not any skill
needs config, and it would go stale mid-session as `/settings` writes land. The
per-skill body call is fresher and only loads where it is used. Session start
still prints the resolved review mode and any schema errors, which is the part a
human reads.

## Verifying a change

There is no standing test suite for the helper in this repository; verify a
change on scratch copies, never on the project itself. Copy
`.claude/hooks/yaml-helper.sh` into a temporary directory under
`.claude/hooks/`, write a `project.yaml` (and, where needed, a
`project.local.yaml`) there, and run
`bash .claude/hooks/yaml-helper.sh resolve_config --keys <labels>` from that
directory. The properties worth re-checking after any edit:

- The template `project.yaml` resolves `rigor: minimal (default)` and
  `review_mode: solo (rigor:minimal)` with no `notes:` line.
- An explicit value beats the rigor expansion, and an unset fronted knob follows
  it — both directions.
- None of the six fronted knobs gains an entry in `_yaml_helper_defaults`.
- The local read scope and the `/settings --local` write whitelist are the same
  list. If they drift, `/settings` accepts and displays a value that every
  skill then ignores.
- Every label in [Labels](#labels) prints at least one non-empty line on the
  template and on a fully configured project.
- `platform.surfaces: [web, iso]` prints `web` and names `iso` on `notes:`;
  `compliance.regions: []` prints `regions=none`; `release.distribution: steam`
  prints the unset form with a note; `release.distribution` in
  `project.local.yaml` only is ignored with a "not locally overridable" note.
- The expansion stays *reachable* (`/start` asks about `rigor`) and *legible*
  (`/settings` reports derived values rather than "(not set)"). A correct
  expansion nobody is asked about and no view displays would be worth nothing.
