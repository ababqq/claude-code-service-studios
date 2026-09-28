# project.yaml — Effects Map

> ## READ ONE SECTION, NEVER THIS WHOLE FILE
>
> This document is large: one `## <key>` section per setting, and a skill needs
> one of them. Opening the whole file costs several times a turn's context budget
> and buys nothing. To look up a setting:
>
> ```
> Grep pattern="^## modes.review_mode" path=".claude/docs/effects-map.md" -A 80
> ```
>
> Read the section for your key — up to the next `## ` heading; raise `-A` for the
> long ones (`modes.workflow`, `modes.automation`) — and stop. The same rule the
> skills apply to their own reference files — `/gate-check` loads only the
> reference file of the target phase and never the others — applies here. "See `.claude/docs/effects-map.md`"
> in a skill or doc means "grep the one section", never "read the file".

This document defines what each `project.yaml` setting does across every skill,
hook and script that reads it. It is the authoritative key catalog: a key with no
`## ` section (or group section) here is not a Claude Code Service Studios setting,
and nothing reads it.

**Sibling documents — do not duplicate their content here:**

| Doc | Answers |
|---|---|
| `.claude/docs/effects-map.md` (this file) | What each setting *does*, per value, per reader |
| `.claude/docs/config-resolution.md` | How a setting *resolves* — the bootstrap line, the chain, failure modes |
| `.claude/docs/settings-guidance.md` | Which value to *recommend*, and when to suggest a change |
| `.claude/docs/automation-modes.md` | The shared interaction pattern behind `modes.automation` |
| `.claude/docs/workflow-modes.md` | The shared tier pattern behind `modes.workflow` |

### How a section is laid out

Every setting has its own `## <key>` heading, or shares a **group heading** that
names its keys (`## project.name and project.version`, `## stack.layers and
specialists`, …). A setting mentioned only inside a table is invisible to every
check that derives its scope from these headings — the `/settings` reserved-set
derivation and the enum-parity check among them — so it can neither be reported
as dead nor caught when it gains a reader. Add a heading, never just a row.

Each section opens with the same fields:

- **Controls** — what the setting decides.
- **Values** — the allowed values. For every enum or list-enum key this line
  names **exactly** the values in `_yaml_helper_enums` / `_yaml_helper_array_enums`
  of `.claude/hooks/yaml-helper.sh`, in the same order. `/settings` validates a
  write against those tables with `validate_enum_value`, and resolution drops any
  value outside them — so this line, the helper table and the reader's branches
  must change together.
- **Default** — the terminal default, if one exists. Only three keys have one
  (`modes.automation`, `modes.rigor`, `performance.enforce`). "Fronted" means the
  value comes from the `modes.rigor` expansion and there is deliberately no
  default. "unset ⇒ ask" means a reader that needs the value must ask or report
  `MANUAL CHECK NEEDED` — never assume the permissive reading
  (`.claude/rules/skill-authoring.md`, obligation 2).
- **Status** — `live` (at least one skill, hook or script reads it) or
  `RESERVED` (stored and validated, read by nothing).
- **Local override** — whether `project.local.yaml` may set it (§ Local Override Pattern).
- **Label** — the `resolve_config` label that delivers the resolved value to a
  skill's bootstrap block. `—` means no label exists: a skill reads the key from
  `project.yaml` with Read at run time, and `project.local.yaml` is not consulted
  for it.
- **Set by / Read by** — the writers and the readers. Where a reader list is long
  or changes often, the section also gives the grep that derives it.

**RESERVED banner rule.** A RESERVED setting carries the banner
`> ### RESERVED - NOT IMPLEMENTED` within 14 lines under its heading. `/settings`
derives its reserved set with `grep -B14` from those banners, so keep the banner
directly under the heading, and keep the section *above* a RESERVED section
longer than 14 lines (otherwise the previous heading is captured too).

### Resolution chain (every key)

```
project.local.yaml (whitelisted keys only)
  → project.yaml
  → modes.rigor expansion (the six fronted knobs only)
  → terminal default (modes.automation, modes.rigor, performance.enforce only)
  → unset
```

An enum-invalid value at any hop **falls through** to the next source — it never
wins — and `resolve_config` names what it rejected on its `notes:` line.
`resolve_config` always exits 0 and always emits a complete block. A skill's
bootstrap receives the result through the `--keys` labels; the mechanics are in
`.claude/docs/config-resolution.md`.

**Secrets never go in either file** — see § Local Override Pattern.

### Key index

`Local` ✓ = on the `project.local.yaml` whitelist. `Fronted` = supplied by `modes.rigor`.

| Key | Type / values | Default | Status | Local | Label | Section |
|---|---|---|---|---|---|---|
| `schema_version` | int | `1` | live | — | — | `schema_version` |
| `framework.version` | semver | template value (see `project.yaml`) | live | — | — | `framework` |
| `framework.last_upgraded` | ISO date | `2026-09-27` | live | — | — | `framework` |
| `project.name` | string | unset | live | — | — | `project.name and project.version` |
| `project.category` | string | unset | live | — | — | `project.category` |
| `project.version` | semver | unset | live | — | — | `project.name and project.version` |
| `project.stage` | `Discovery` … `Launch` (7) | unset ⇒ `stage-estimate.sh` | live | — | `project.stage` | `project.stage` |
| `modes.rigor` | `minimal\|standard\|full` | `minimal` | live | — | `rigor` | `modes.rigor` |
| `modes.automation` | `collaborative\|guided\|autonomous` | `collaborative` | live | ✓ | `automation` | `modes.automation` |
| `modes.automation_always_ask` | list of categories | 9-item default list | live | ✓ | `automation_always_ask` | `modes.automation_always_ask` |
| `modes.review_mode` | `full\|lean\|solo` | — (Fronted) | live | ✓ | `review_mode` | `modes.review_mode` |
| `modes.workflow` | `minimal\|standard\|full` | — (Fronted) | live | — | `workflow` | `modes.workflow` |
| `modes.story_granularity` | `coarse\|balanced\|fine` | — (Fronted) | live | — | `story_granularity` | `modes.story_granularity` |
| `docs.density` | `terse\|balanced\|thorough` | — (Fronted) | live | — | `docs.density` | `docs.density` |
| `qa.level` | `minimal\|standard\|full` | — (Fronted) | live | — | `qa.level` | `qa.level` |
| `qa.coverage_minimum` | int 0–100 | unset | RESERVED | — | — | `qa.coverage_minimum` |
| `team.size` | `individual\|small\|studio` | — (Fronted) | live | ✓ | `team.size` | `team.size` |
| `testing.framework` | string | unset | live | — | — | `testing.framework` |
| `testing.patterns` | flow list of globs | unset ⇒ `tests/**` + announce | live | — | — | `testing.patterns` |
| `testing.strict.{logic,integration,ui,e2e,config}` | `true\|false` | unset (per-skill default) | live | ✓ | `testing.strict` | `testing.strict` |
| `stack.pinned_on` | ISO date | unset | live | — | `stack` | `stack.pinned_on` |
| `stack.layers.<layer>.*`, `specialists.<layer>` | strings, paths | unset | live | — | `stack`, `code_roots` | `stack.layers and specialists` |
| `stack.monorepo` | `true\|false` | unset | live | — | — | `stack.monorepo and stack.shared_roots` |
| `stack.shared_roots` | flow list of paths | unset | live | — | `code_roots` | `stack.monorepo and stack.shared_roots` |
| `stack.package_manager` | string | unset | live | — | — | `stack.package_manager and stack.profile` |
| `stack.profile` | string (informational) | unset | live | — | — | `stack.package_manager and stack.profile` |
| `platform.surfaces` | list ⊆ `web\|ios\|android\|api` | unset ⇒ ask | live | — | `surfaces` | `platform.surfaces` |
| `platform.browsers` | flow list (browserslist) | unset | live | — | — | `platform.browsers and platform.min_os` |
| `platform.min_os.ios`, `platform.min_os.android` | strings | unset | live | — | — | `platform.browsers and platform.min_os` |
| `release.distribution` | `web\|stores\|web+stores\|enterprise\|internal` | unset ⇒ ask | live | — | `distribution` | `release.distribution` |
| `privacy.handles_pii` | `true\|false` | unset ⇒ ask | live | — | `compliance` | `privacy.handles_pii` |
| `compliance.regions` | list ⊆ `kr\|eu\|us` | unset ⇒ ask | live | — | `compliance` | `compliance.regions` |
| `localization.locales` | flow list of BCP 47 tags | unset ⇒ ask | live | — | — | `localization.locales` |
| `accessibility.target` | `none\|wcag-a\|wcag-aa\|wcag-aaa` | unset ⇒ ask | live | — | `accessibility` | `accessibility.target` |
| `performance.api_p95_ms` … `performance.crash_free_pct` (9 budgets) | number | unset | live | — | — | one section each |
| `performance.enforce` | `warn\|block\|off` | `warn` | live | ✓ | `performance.enforce` | `performance.enforce` |
| `workflow_overrides.{edge_cases,config_flags,design_language_strict}` | `true\|false` | unset | live | — | — | `workflow_overrides` |
| `workflow_overrides.feature_overrides.<prd-stem>` | `minimal\|standard\|full` | — | live | — | `feature_overrides` | `workflow_overrides` |
| `cadence.sprint_length`, `cadence.milestone_length` | strings | unset | RESERVED | — | — | `cadence.sprint_length and cadence.milestone_length` |
| `commands.<name>` | string or OS map | unset | live | — | — | `commands` |
| `naming.<field>` | string | unset | live | — | — | `naming` |
| `features.session_state` | `on\|off` | enabled unless `off` | live | ✓ | — | `features.session_state` |
| `features.token_budget_warn_at` | float 0–1 | unset | RESERVED | ✓ | — | `features.token_budget_warn_at` |

---

## Local Override Pattern — `project.local.yaml`

`project.yaml` is committed and shared by the team. `project.local.yaml` lets each
developer override a small set of **personal-experience** settings for their own
sessions without affecting anyone else. It is gitignored (`.gitignore`, block
`# === Claude Code Local ===`) and never committed.

### How it works

Priority chain for a whitelisted key: `project.local.yaml` → `project.yaml` →
`modes.rigor` expansion (fronted knobs only) → terminal default → unset.
For every other key, `project.local.yaml` is **not consulted** — the chain starts
at `project.yaml`.

If a whitelisted setting is present in `project.local.yaml`, that value wins —
unless it is enum-invalid, in which case it falls through to `project.yaml` and
the rejection is named on the `notes:` line.

---

### Deep merge semantics

When both files set values in the same block, only the explicitly-set leaf is
overridden. Sibling keys are read independently from their own files.

`project.yaml`:
```yaml
testing:
  strict:
    logic: true
    integration: true
    e2e: true
```

`project.local.yaml` (sparse override):
```yaml
testing:
  strict:
    logic: false
```

Effective values seen by skills: `logic: false`, `integration: true`, `e2e: true`.
Only `logic` is overridden; the siblings come through from `project.yaml`.

---

### Whitelist — which settings can be locally overridden

The rule for deciding which side a setting belongs on:

> **If a setting affects what artifacts exist or what they look like on disk,
> it must be locked to `project.yaml`. If a setting only changes your personal
> experience (which agents spawn for you, whether you get prompts, whether a
> failure blocks your local work), it can be locally overridden.**

**Locally overridable** — exactly these keys (`_yaml_helper_locally_overridable`
in `.claude/hooks/yaml-helper.sh`; `_yaml_helper_local_read_scope` equals it, so
what `/settings --local` may write is exactly what resolution reads):

| Setting | Why a local override makes sense |
|---|---|
| `modes.review_mode` | How much AI review you personally want |
| `modes.automation` | How often the AI stops to ask you |
| `modes.automation_always_ask` | Your personal safety categories |
| `team.size` | Which agents spawn for your runs (review depth differs, artifacts do not) |
| `testing.strict.logic`, `.integration`, `.ui`, `.e2e`, `.config` | Whether a failing test blocks *your* local story closure — CI runs against `project.yaml` |
| `performance.enforce` | Whether a budget breach blocks *your* local work — CI runs against `project.yaml` |
| `features.session_state` | Your session-tracking preference |
| `features.token_budget_warn_at` | Your personal cost threshold (RESERVED — nothing reads it) |

**Locked to `project.yaml`** (project-wide — a local value would make checkouts diverge):

| Setting | Why it must be project-wide |
|---|---|
| `schema_version`, `framework.*` | File metadata, not preferences — **exempt from the local-scope report below**, since a `project.local.yaml` carrying `schema_version: 1` is correct as written |
| `project.*` | Product identity, version and phase |
| `stack.*`, `specialists.*` | The whole team builds on the same stack, roots and routing |
| `naming.*`, `commands.*` | Code conventions and build/test commands are project facts |
| `testing.framework`, `testing.patterns` | One set of runners and one test layout per project |
| `platform.*`, `release.distribution` | What ships where, and how it is distributed |
| `privacy.handles_pii`, `compliance.regions`, `localization.locales` | Legal and product commitments |
| `accessibility.target` | A product commitment, not a preference |
| `performance.*` budgets | Shared SLO and budget targets |
| `cadence.*` | Sprint and milestone length coordinate the team (RESERVED) |
| `modes.rigor` | Fronts four on-disk knobs — locked for the same reason they are |
| `modes.workflow`, `workflow_overrides` | Decide which sections authored documents must contain |
| `modes.story_granularity` | Decides how big stories in the repo are |
| `docs.density` | Decides how deep authored documents go |
| `qa.level` | Decides what test evidence a story must carry on disk |
| `qa.coverage_minimum` | Project quality bar (RESERVED) |

> **A locked key written into `project.local.yaml` by hand is reported, not
> swallowed.** `/settings --local` refuses to write one, but the file is meant to
> be hand-edited and that path had no guard: `modes.rigor: full` there is a real
> key with a legal value, so enum validation passes it, and resolution then never
> consults the local file for that path — the setting vanishes and the user sees
> the value they were trying to override, with no error anywhere. Every check
> validated the **value**; nothing validated the **location**.
> `validate_local_scope` in `yaml-helper.sh` names such keys on `resolve_config`'s
> `notes:` line. It **warns and never reconciles**: it does not edit the file,
> does not begin honouring the key, and does not change resolution — a locked
> setting decides which artifacts exist on disk, so applying one quietly would
> produce exactly the divergence this table prevents. A clean file stays silent.

---

### `/settings --local` flag behavior

```
/settings modes.workflow=minimal                → writes project.yaml (team-wide)
/settings --local modes.automation=autonomous   → writes project.local.yaml (just you)
```

- Default (no flag): writes `project.yaml`.
- `--local`: writes `project.local.yaml` (creates it if absent).
- `--local` on a locked setting → refused:
  > *"`<setting>` cannot be locally overridden — it's a project-wide setting.
  > Use `/settings <setting>=<value>` (no `--local`) to change it for the whole team."*
- Writing `project.yaml` while the same setting is locally overridden → warning:
  > *"This setting is currently locally overridden in `project.local.yaml`.
  > Writing to `project.yaml` will not change your effective value."*

`/settings` is the only skill that writes `project.local.yaml`.

---

### Schema validation on read

| Issue | Behavior |
|---|---|
| Enum-invalid value (e.g. `modes.automation: chaotic`) | Dropped; resolution falls through to the next source and `resolve_config` names the rejected value on `notes:`. `session-start.sh` reports enum and scope errors at session start. `/settings` refuses to write it. Never a hard stop — a skill always receives a complete block. |
| Invalid element in a list-enum key (e.g. `platform.surfaces: [web, iso]`) | The element is dropped with a note (`platform.surfaces: dropped invalid element 'iso'`); the valid elements survive. |
| Locked key in `project.local.yaml` | Named on `notes:`, ignored (see above). |
| `project.local.yaml` without a `project.yaml` | Hard error from `validate_local_yaml_base`, surfaced on `notes:`; defaults are used. |
| Unknown key (typo, or a key this file does not define) | **Not detected.** Resolution reads only the paths it knows, so a misspelled key is simply never read. Check spelling against this file's headings; `/settings <key>` shows `(not set)` for a key nothing supplies. |
| Unparseable value of a key without an enum (a budget written as `fast`) | Not validated by `yaml-helper.sh`. A skill that cannot parse a value treats it as unset and says so (obligation 3) — it never measures against a guess. |

---

### Creation and error handling

| Scenario | Behavior |
|---|---|
| Fresh clone of the template | `project.yaml` ships with `schema_version` and `framework` only — no `modes:` block. |
| `/start` | Adds `project.stage`, `modes.rigor` and `modes.automation` to `project.yaml`. Never creates `project.local.yaml`. |
| `/setup-stack` | Adds the `stack.*` block and the product facts (surfaces, distribution, regions, locales, naming, commands). |
| `/settings --local <key>=<value>` with no local file | Creates `project.local.yaml` containing just that setting. |
| `project.local.yaml` exists but `project.yaml` doesn't | Hard error: *"`project.yaml` missing — run `/start` to create one. Local overrides require a base."* |
| Both files set the same whitelisted key | `project.local.yaml` wins. No prompting. |

---

### Two-developer clash scenarios — and why the whitelist prevents them

**File-level conflict (`project.yaml`):** an ordinary git merge conflict. Each
developer's `project.local.yaml` is gitignored and never collides with anyone
else's.

**Logical inconsistency (prevented by the whitelist).** Example of what the
whitelist prevents:

> Minji sets `modes.workflow: minimal` locally to skip PRD requirements. She stops
> writing PRDs because her local tier does not require them. Alex runs
> `/gate-check architecture` with the team's `standard`; the gate sees MVP
> features without PRDs and fails.

This cannot happen because `modes.workflow` is locked to `project.yaml`. The same
holds for `qa.level`, `docs.density`, `naming.*` and every other setting that
decides what artifacts exist on disk.

Personal-experience settings (`automation`, `review_mode`, `team.size`,
`testing.strict.*`, `performance.enforce`) can diverge freely without affecting
anyone else.

---

### Stricter reviewer reviewing a looser reviewer's work

A common worry: "my teammate has stricter review settings than me — will their
`/gate-check` or `/prd-review` flag things in my work?" It depends on which kind
of difference it is.

**Different review depth, same project requirements (HEALTHY):**

- Teammate A: local `review_mode: full`, `automation: collaborative`, `testing.strict.logic: true`
- Teammate B: local `review_mode: solo`, `automation: autonomous`, `testing.strict.logic: false`
- Both are bound by the same locked settings (e.g. `workflow: standard`, `qa.level: standard`)

B writes `design/prd/goals.md` meeting `workflow: standard` (the 8 required
sections present). B's `/prd-review` runs at `solo` — a single-session check, no
consultants. Later A reviews the same PRD at `full`, which consults the routed
specialists and finds an idempotency edge case in auto-debit retries that B's
lighter review missed. A files it as a review comment; B fixes it.

**This is normal team collaboration.** The artifacts on disk are the same; only
review depth differs.

**Different requirements (PREVENTED by the whitelist).** If `qa.level` were
locally overridable:

- B sets `qa.level: minimal` locally. B's stories close without test evidence.
- A pulls. A's `qa.level: standard` requires evidence; A's `/story-done` would have rejected them.
- A's next `/gate-check hardening` fails on missing evidence across B's "Complete" stories.

That is artifact divergence, which is why `qa.level` is locked.

| Difference type | Outcome |
|---|---|
| Review depth (`review_mode`, `team.size`) | The stricter reviewer surfaces more findings — healthy. Artifacts unchanged. |
| Local strictness on failures (`testing.strict.*`, `performance.enforce`) | The stricter developer's local `/story-done` blocks earlier — they fix it locally. CI runs `project.yaml`, so the team bar holds. |
| Artifact requirements (`workflow`, `qa.level`, `docs.density`, …) | **Cannot happen — these are locked.** The team agrees once in `project.yaml`. |

---

### CI behavior

CI has no `project.local.yaml` — the file is gitignored and absent from a fresh
clone — so CI always resolves from `project.yaml`, the `modes.rigor` expansion and
the terminal defaults. That is intentional: developers iterate with relaxed
personal settings, and CI holds the team bar.

| Setting | Typical local value | What CI resolves |
|---|---|---|
| `modes.review_mode` (overridable) | `solo` for fast solo iteration | whatever `project.yaml` or the rigor expansion gives — e.g. `lean` at `rigor: standard` |
| `testing.strict.logic` (overridable) | `false` for WIP commits | the `project.yaml` value (unset ⇒ the skill's own default) |
| `modes.automation` (overridable) | `autonomous` | `project.yaml` value or `collaborative` — mostly a no-op in CI, which asks no questions |

Unset on an unconfigured project: `modes.rigor` defaults to `minimal`, which resolves `review_mode` to `solo`.

---

### Secrets — never in either file

`project.yaml` and `project.local.yaml` hold **configuration**, never
**secrets**. API keys, tokens, signing keys and credentials belong in:

- **A secret manager** in deployed environments (AWS Secrets Manager / SSM,
  GCP Secret Manager, Vercel or Fly environment secrets, GitHub Actions secrets)
- **`.env` files** for local development — gitignored; only `.env.example` is committed
- **The OS keychain** for developer tokens that support it

`project.yaml` records *which* provider is used (`stack.layers.cloud.provider:
AWS`, a Toss Payments integration in the tech radar), never the key for it.
`validate-commit.sh` blocks commits that stage `.env` files, private keys,
keystores or recognisable secret tokens, and the shared `.claude/settings.json`
denies reading them.

---

## modes.rigor

**Controls:** How much process the project carries overall — the single question
`/start` asks, which supplies six knobs at once

**Values:** `minimal` | `standard` | `full`

- **Default:** `minimal` (terminal default in `_yaml_helper_defaults`). Unset on an unconfigured project: `modes.rigor` defaults to `minimal`, which resolves `review_mode` to `solo`.
- **Status:** live
- **Local override:** no — it fronts four on-disk knobs
- **Label:** `rigor` → `rigor: <value> (<source>)`
- **Set by:** `/start`, `/settings`
- **Read by:** the `yaml-helper.sh` expansion (every read of a fronted knob goes through it); `statusline.sh` (shows `minimal` when unset); `/launch-checklist` and `/release-checklist` through the `rigor` label (item blocking markers)

**Priority chain:** `modes.rigor` in `project.yaml` → terminal default `minimal`.
Locked: `project.local.yaml` is never consulted for it, like the four *on-disk*
knobs it fronts — `modes.workflow`, `docs.density`, `qa.level`,
`modes.story_granularity`. The two *personal-experience* knobs it also fronts,
`modes.review_mode` and `team.size`, stay locally overridable.

Which level to recommend for which product — and when to suggest a change — is
`.claude/docs/settings-guidance.md`, not this section.

---

### Expansion table

| `modes.rigor` | `modes.workflow` | `docs.density` | `qa.level` | `modes.story_granularity` | `modes.review_mode` | `team.size` |
|---|---|---|---|---|---|---|
| `minimal` *(default)* | `minimal` | `terse` | `minimal` | `coarse` | `solo` | `individual` |
| `standard` | `standard` | `balanced` | `standard` | `balanced` | `lean` | `individual` |
| `full` | `full` | `thorough` | `full` | `fine` | `full` | `studio` |

### It fronts, it does not replace

The expansion sits **below every explicit source and above the terminal default**:

```
project.local.yaml → project.yaml → rigor expansion → default
```

Consequences worth stating plainly:

- **An explicit value always answers first.** If `project.yaml` sets
  `docs.density: terse`, that value — and its reported source `project.yaml` —
  wins whatever `rigor` says.
- **Overrides go both ways.** Unlike the `workflow_overrides` boolean flags — which
  are additive and stricter-only — an explicit knob may be *looser* than the rigor
  level implies. `rigor: full` + `docs.density: terse` ("comprehensive but
  compact") is the off-diagonal the knobs exist to express.
- **Per-feature tiers still win.** `workflow_overrides.feature_overrides.<prd-stem>`
  beats the rigor-derived project tier for that feature. `modes.workflow` is fronted
  rather than folded away because it drives several distinct behaviors and owns the
  only per-feature override mechanism.

The six fronted knobs therefore have **no entry in `_yaml_helper_defaults`**, and
**no template, skill or onboarding step ever seeds them into `project.yaml`**. A
terminal default — or a seeded value — would answer before the expansion and make
`rigor` a no-op for anyone who had not also set the sub-knob. A user who wants to
pin one does so deliberately with `/settings`.

### Provenance

Derived values report their source as `rigor:<level>`, so the source vocabulary of
`resolve_setting` is `{project.local.yaml, project.yaml, rigor:<level>, default,
unset}`. `/settings` renders it as `(derived from rigor: standard)` and always
appends the rigor family to its view-all list — none of the six is a leaf of either
YAML file, so enumerating file leaves alone would hide exactly the settings the
user just chose.

---

## modes.review_mode

**Controls:** How many director and specialist agents a skill spawns — in
particular, which director gates run

**Values:** `full` | `lean` | `solo`

- **Default:** none — fronted by `modes.rigor` (`minimal`→`solo`, `standard`→`lean`, `full`→`full`).
- **Status:** live
- **Local override:** yes — a personal-experience knob
- **Label:** `review_mode` → `review_mode: <value> (<source>)`
- **Set by:** `/settings` only. No other skill writes it — not `/start`, `/adopt` or `/sprint-plan`.
- **Read by:** every gate-using skill (see the tables below). Derive the current list with `grep -lE 'resolve_config --keys ([a-z_.]+,)*review_mode' .claude/skills/*/SKILL.md`.

Unset on an unconfigured project: `modes.rigor` defaults to `minimal`, which resolves `review_mode` to `solo`.

**Priority chain (all skills):** inline `--review full|lean|solo` flag →
`project.local.yaml` → `project.yaml` → `modes.rigor` expansion. No terminal
default.

**Review-mode exemption:**

> `/hotfix`, `/rollout-plan` and `/incident` are release-critical: every agent and gate they name runs at every `review_mode`. They do not resolve `review_mode`.

**Panel width is not this setting.** How many directors sit on `/gate-check`'s
phase-gate panel is decided by `modes.workflow`; the only copy of that table is
`.claude/skills/gate-check/SKILL.md` Section 4b. Read it there. `review_mode`
decides only *whether* the panel runs (`solo` skips it).

---

### Value intent

| Value | Intent |
|---|---|
| `full` | Every director gate and every optional reviewer runs. For teams, regulated products, or anyone who wants thorough AI review on every decision. |
| `lean` | Phase gates only: `lean` → **skip every gate whose ID does not end in `-PHASE-GATE`**. Note: `[GATE-ID] skipped — Lean mode` |
| `solo` | Skip all gates, note `[GATE-ID] skipped — Solo mode`. Fastest; for confident solo iteration. |

The suffix rule is derived, not enumerated: a new gate is covered the moment it
exists, and no skill carries a hand-written list of the gates `lean` keeps.

---

### Gate-spawning skills

At `full` every gate below spawns. At `lean` only IDs ending in `-PHASE-GATE`
spawn — in practice only `/gate-check`'s panel. At `solo` none spawns. A skipped
gate always leaves its note (`[GATE-ID] skipped — Lean mode` / `— Solo mode`) in
the artifact, which is the evidence the mode was applied.

| Skill | Gates it spawns |
|---|---|
| `/gate-check` | the `*-PHASE-GATE` panel, at the width `/gate-check` Section 4b resolves |
| `/brainstorm` | PD-PRINCIPLES, TD-FEASIBILITY, DM-SCOPE, DD-BRAND-DIRECTION (optional: `full` with a UI surface) |
| `/map-features` | TD-DOMAIN-BOUNDARY, PD-FEATURE-MAP, DM-SCOPE |
| `/write-prd` | PD-PRD-ALIGN |
| `/prototype`, `/usability-report` | PD-USER-VALIDATION |
| `/walking-skeleton` | PD-USER-VALIDATION (only when a usability session runs on the skeleton) |
| `/setup-stack` | TD-STACK-RISK (`upgrade` mode) |
| `/create-architecture` | TD-ARCHITECTURE, TL-FEASIBILITY |
| `/architecture-decision` | TD-ADR; TD-STACK-RISK (Knowledge Risk HIGH or MEDIUM); SE-SECURITY-REVIEW (ADR Domain `Auth`, `Security` or `Data`) |
| `/api-design`, `/data-model` | SE-SECURITY-REVIEW |
| `/create-control-manifest` | TD-MANIFEST |
| `/propagate-prd-change` | TD-CHANGE-IMPACT |
| `/create-epics` | DM-EPIC |
| `/create-stories`, `/story-readiness` | QL-STORY-READY |
| `/sprint-plan` | DM-SPRINT |
| `/milestone-review` | DM-MILESTONE |
| `/design-language` | DD-BRAND-DIRECTION (when the brief has no `## Brand Direction Anchor`), DD-DESIGN-LANGUAGE |
| `/ux-review`, `/team-ui` | DD-UI-CONSISTENCY |
| `/team-content` | DD-CONTENT-VOICE |
| `/story-done` | TL-CODE-REVIEW, QL-TEST-COVERAGE |
| `/team-qa` | QL-TEST-COVERAGE |

Gate files, verdict tokens and the Context each spawn passes are in
`.claude/docs/director-gates.md`.

---

### Skills that resolve `review_mode` without spawning a gate

`/prd-review`, `/team-feature`, `/team-growth`, `/team-hardening`, `/team-release`
and `/ui-inventory` use it to scale optional consultants and reviewers; each
SKILL.md states what each mode adds. Team skills are execution pipelines, not review gates: `review_mode`
decides which *optional* reviewers join, never whether the pipeline runs, and
team-size scoping never removes a director gate.

---

### Special cases and notes

- **`/gate-check`** is the one skill where `full` and `lean` behave the same —
  its panel consists of `-PHASE-GATE` gates, which `lean` keeps. Only `solo`
  skips the panel (artifact checks still run). Width never softens a verdict: the
  strictest verdict from whoever ran wins, and `/gate-check` names the
  perspectives that did not run.
- **Gate-outcome items.** A gate reference item "<GATE-ID> outcome recorded" is
  satisfied by the recorded verdict line **or**, when the resolved `review_mode`
  skips that gate, by the skip note in the same artifact. `/gate-check` then
  prints `NOT CHECKED — <GATE-ID> skipped (<mode> mode)` and does not score the
  item — review mode is an explicit user choice.
- **`/story-done` code review.** When the mode skips TL-CODE-REVIEW, `/story-done`
  runs the `/code-review` checklist itself over the story's changed files and
  records `Code review: inline checklist (TL-CODE-REVIEW skipped — <Mode> mode)`.
- **Exempt skills** (`/hotfix`, `/rollout-plan`, `/incident`) never resolve the
  setting; SR-PRODUCTION-READINESS in `/rollout-plan` runs at every mode.
- **`/dev-story`** routing to the primary engineer always runs regardless of
  mode; `/dev-story` does not resolve `review_mode`.

---

## modes.workflow

**Controls:** How much product and technical documentation is required before
code — the trade-off between the time and token cost of documentation and the
speed of reaching working, deployed code

**Values:** `minimal` | `standard` | `full`

- **Default:** none — fronted by `modes.rigor` (`minimal`→`minimal`, `standard`→`standard`, `full`→`full`).
- **Status:** live
- **Local override:** no — it decides which artifacts exist
- **Label:** `workflow` → `workflow: <value> (<source>)`; with the optional positional `<feature>` argument, `resolve_config` also prints `workflow[<feature>]: …` (see `workflow_overrides`)
- **Set by:** `/settings`
- **Read by:** tiered skills and `/gate-check` (tables below); `/help` and `/project-stage-detect` render catalog steps whose `required_tiers` omit the resolved tier as OPTIONAL

**Priority chain:** `modes.workflow` in `project.yaml` → `modes.rigor` expansion →
*(no terminal default)*. For one feature,
`workflow_overrides.feature_overrides.<prd-stem>` wins over both.

> **Permissive, not restrictive.** `workflow` controls what is REQUIRED — not
> what is ALLOWED. Any skill can run at any tier. The setting changes what
> `/gate-check` enforces and what completeness checks validate, never what the
> user may invoke.

> **`minimal` floor.** Even at `minimal`, a filled one-pager
> (`design/product/one-pager.md`) and a pinned stack (`stack.pinned_on`) are
> required before code, and the one-pager's `## Build Order` section is the plan —
> there is no separate sprint plan. Both take minutes and prevent real problems
> downstream; everything else can be skipped.

> **Escape hatches via `workflow_overrides`.** A team that wants *almost* the
> `standard` set with one extra requirement (always write Configuration & Flags,
> say) sets a `workflow_overrides` flag instead of escalating to `full`.

---

### Value intent

| Value | Cost | Required before code | Best for |
|---|---|---|---|
| `full` | High | Product brief; feature map; all 11 PRD sections per MVP feature; architecture doc and SLO doc; Foundation ADRs; API contract and data model (*Backend*); threat model (*PII*); traceability; design language (all 9 sections, *UI*); UX specs, app shell and interaction patterns (*UI*); control manifest; walking skeleton on staging | Regulated products, B2B with SLAs, larger teams, or learning the full pipeline |
| `standard` | Balanced | Product brief; feature map; 8 PRD sections per MVP feature (+ conditional Business Rules & Calculations); architecture doc; critical ADRs; API contract and data model (*Backend*); design language sections 1–5 (*UI*); key UX specs (*UI*); walking skeleton on staging | Seed-stage product teams with several interacting features, or a design someone else implements |
| `minimal` | Low | `design/product/one-pager.md` + stack pinned; the one-pager's `## Build Order` is the plan | Hackathons, prototypes, small scope; resolved on an unconfigured project. Raise it when the project grows |

**`standard` required PRD sections:** Overview, Goals & Non-Goals, Functional
Requirements, Edge Cases, Dependencies, Non-Functional Requirements, Success
Metrics & Instrumentation, Acceptance Criteria. Advisory at `standard`: User Value,
Configuration & Flags. The contract (exact headings, order, template) is
`.claude/docs/templates/prd.md`.

**`standard` conditional:** Business Rules & Calculations is required when the
feature **defines any numeric or policy rule** — prices, fees, limits, quotas,
rate limits, eligibility thresholds, time windows, rounding.

> **The test is what the feature defines, not what it is called.** The feature
> map's `Category` column is free text and at most a hint — a `Payments` or
> `Billing` feature almost always qualifies, but an `Account` feature with a
> "3 failed sign-ins lock the account for 15 minutes" rule qualifies too. Never
> restate the condition as a list of categories: a feature categorised exactly as
> the template suggests would then silently skip the section it most needs.

> **Edge Cases is required at `standard`.** Skipping it reliably produces "what
> happens when the auto-debit call times out?" debt during implementation —
> network loss, partial failure, concurrency and retries are where service
> features break.

> **The design language is conditional at `standard`.** Sections 1–5 are required
> only when a UI surface exists (*UI* = `platform.surfaces` ∩ {web, ios, android}
> ≠ ∅); `workflow_overrides.design_language_strict: true` forces all 9. An
> API-only product skips it.

---

### Authoring skills

| Skill | full | standard | minimal |
|---|---|---|---|
| **`/brainstorm`** | Product brief (`design/product/product-brief.md`) | Product brief | One-pager (`design/product/one-pager.md`) |
| **`/write-prd`** | All 11 sections required | 8 required + conditional Business Rules & Calculations; User Value and Configuration & Flags advisory | Not required — the one-pager replaces PRDs; can still be run |
| **`/map-features`** | Required before PRDs | Required before PRDs | Not required |
| **`/design-language`** | All 9 sections | Sections 1–5 when a UI surface exists | Not required |
| **`/create-architecture`** | Full architecture doc + `docs/ops/slo.md` with an SLO per critical user journey | Architecture doc + the SLO doc's `## Critical User Journeys` | Not required |
| **`/architecture-decision`** | ≥3 Foundation-layer ADRs covering identity & auth, primary data store, API style, deployment topology & environments, observability | The Foundation-layer ADRs the architecture doc marks critical | Not required |
| **`/api-design`, `/data-model`** | Required when *Backend* | Required when *Backend* | Not required |
| **`/ux-design`** | UX spec per key screen + app shell + interaction patterns (*UI*) | Same key screens (sign-up/sign-in, onboarding, core flow, settings/account) | Not required |

---

### Review and validation skills

| Skill | full | standard | minimal |
|---|---|---|---|
| **`/prd-review`** | All 11 sections validated — any missing section blocks approval | 8 required sections validated; advisory sections warned, not blocking | The one-pager only |
| **`/review-all-prds`** | Required; all 11 sections across all PRDs | Recommended; required sections, advisory sections surfaced only | Not applicable |
| **`/architecture-review`** | Full traceability matrix — every MVP PRD, every ADR | Architecture doc + critical ADRs; traceability recommended | Not applicable |
| **`/consistency-check`** | Glossary registry cross-check against all PRD sections | Registry check against required sections | Not meaningful — no PRDs |
| **`/feature-audit`** | Planned vs implemented for every MVP, Beta and GA feature in the feature map (`Later` listed, not scored) | MVP features only | The one-pager's `## Build Order` items and `## Core User Journey` steps |

---

### Phase gate enforcement (`/gate-check`)

`/gate-check` is where the tier has the most visible impact. The authoritative
per-tier checklists are the `## Workflow tier reductions` sections of the gate
reference files (`.claude/skills/gate-check/references/gate-<target>.md`); this
table only summarizes them. Items marked with a condition (*UI*, *Backend*, *PII*,
*Stores*, *Regions*, *Multi-locale*) are `N/A` when the condition is known false.

| Gate (target) | full | standard | minimal |
|---|---|---|---|
| `definition` (Discovery → Definition) | Product brief with its seven checked sections; principles stated as decision tests; brief reviewed | Product brief; brief reviewed | One-pager only |
| `architecture` (Definition → Architecture) | Feature map; every MVP PRD (11 sections) reviewed; cross-PRD review | Feature map; MVP PRDs (8 + conditional) reviewed; cross-PRD review recommended | Not applicable — PASS with the note that the one-pager is the design record |
| `validation` (Architecture → Validation) | Stack pinned; architecture; Foundation ADRs; API contract and data model (*Backend*); threat model (*PII*); traceability; architecture review; accessibility requirements (*UI*); test framework + CI; SLO doc; tech radar | Same with critical ADRs only; traceability and tech radar recommended; SLO journeys section | Stack pinned (the floor) |
| `build` (Validation → Build) | Sprint plan; epics + stories; Foundation/Core ADRs Accepted; control manifest; design language 9 sections, UX specs, app shell, patterns and reviews (*UI*); walking skeleton; contract reconciled with UX (*Backend* + *UI*) | Same with control manifest and reconciliation recommended; design language sections 1–5 | One-pager `## Build Order` has at least one item |
| `hardening` (Build → Hardening) | MVP implemented; tests for Logic, Integration and E2E stories; contract tests (*Backend*); E2E per critical journey; smoke check; no unresolved S1; S2 owners; migrations expanded on staging | Same with Logic/Integration tests and contract tests recommended | Smoke check + no unresolved S1 |
| `launch` (Hardening → Launch) | Release checklist GO; rollout plan READY TO ROLL OUT; launch checklist GO; full security audit; smoke on the release candidate; QA sign-off; hardening report; load test; ≥3 usability/beta sessions; runbooks; ToS & Privacy Policy; store records (*Stores*); region items (*Regions*); localization QA (*Multi-locale*); release notes (built from the `/changelog <version>` section); no unresolved S1/S2 | Same with load test recommended and ≥1 usability/beta session | Release checklist GO; quick security audit; smoke on the release candidate; no unresolved S1/S2 |

> **Walking skeleton.** Built and any applicable validation item failing ⇒
> **FAIL at every tier**. Tier reductions relax what must *exist*, never what must
> *work*.

**Director panel width** is the tier's second effect at the gate — how many
directors sit on the phase-gate panel. The width table lives only in
`.claude/skills/gate-check/SKILL.md` Section 4b; read it there, do not copy it.
`review_mode` remains the axis that decides *whether* the panel runs at all.

---

### Planning and implementation skills

| Skill | full | standard | minimal |
|---|---|---|---|
| **`/create-epics`** | Requires approved 11-section PRDs | Requires approved 8-section PRDs | **Skipped** — no separate epic doc; `/create-stories` synthesizes the epic from the one-pager |
| **`/create-stories`** | Requires every Foundation ADR present | Requires critical ADRs present | No ADR requirement |
| **`/dev-story`** | Requires the TR registry entry, the governing ADR and the control manifest — blocks without them | TR registry optional; critical ADR required where present | Implements against the one-pager — no TR registry, no ADR required |
| **`/story-readiness`** | TR registry + ADR + control manifest validated | TR registry optional; critical ADR check only | Acceptance criteria check only |
| **`/story-done`** | Full PRD traceability + ADR consistency | Required-section PRD traceability | Acceptance criteria check only (the migration floor still applies) |
| **`/qa-plan`** | Plan derived from all 11 PRD sections | Plan from the required sections | Plan from acceptance criteria only |
| **`/regression-suite`** | Critical paths from all sections, including Edge Cases | Critical paths from required sections (including Edge Cases) | Smoke coverage only |
| **`/walking-skeleton`** | Required; validation items 1–5 bind | Required; validation items 1–5 bind | Optional; if built, items 1–4 bind and item 5 is N/A |

---

### Support skills

| Skill | full | standard | minimal |
|---|---|---|---|
| **`/project-stage-detect`** | Every document type expected; missing design language or UX specs flagged | Design language flagged only with a UI surface; non-key UX specs not flagged | One-pager + stack pinned is the normal state; absent PRDs are not gaps |
| **`/help`** | Surfaces every missing required step | Surfaces steps required at `standard` only | One-pager + stack pinned ⇒ the next step is code |
| **`/adopt`** | Full conformance audit across all contracts | Audit scope reduced to the documents required at `standard` | One-pager format check only |
| **`/reverse-document`** | Generates an 11-section PRD from code | Generates the 8 required sections | Not the right tool — update the one-pager |
| **`/propagate-prd-change`** | Full impact analysis across every ADR, contract operation, entity and tracking event | Checks critical ADRs and the API contract | Not applicable |

---

### Workflow change mid-project

Changing `modes.workflow` (or `modes.rigor`) migrates nothing: no document is
deleted, generated or blocked, and the new tier applies to enforcement from then
on. Run `/help` or `/project-stage-detect` to see what the new tier requires.

---

## workflow_overrides

**Controls:** Opt-in, granular requirements layered on the resolved workflow tier

**Location:** the **top level of `project.yaml`** — a sibling of `modes:`, *not* a
child of it

**Values:** `edge_cases`, `config_flags`, `design_language_strict` → `true` | `false`; `feature_overrides.<prd-stem>` → `minimal` | `standard` | `full`

- **Default:** every flag unset (nothing forced); no per-feature override
- **Status:** live
- **Local override:** no
- **Label:** `feature_overrides` → `feature_overrides: <stem>=<tier> … | none` (the map only; the three flags have no label and are read from `project.yaml`)
- **Set by:** `/settings`
- **Read by:** the three flags — PRD-tier skills (`/write-prd`, `/prd-review`, `/reverse-document` for `config_flags`), `/adopt` (`edge_cases`, `config_flags` in its PRD audit), `/gate-check` (all three), and `/design-language` for `design_language_strict`; the map — every per-feature skill and `/gate-check` (orphan check). Derive the map's readers with `grep -lE 'resolve_config --keys ([a-z_.]+,)*feature_overrides' .claude/skills/*/SKILL.md`.

> **Why the location is called out.** Resolution reads
> `workflow_overrides.feature_overrides.*` from the document root, and every
> consuming skill reads the same top-level path. Nested under `modes:` the block
> is still valid YAML, so nothing errors — it is simply never read. If you copy a
> `workflow_overrides` block from anywhere, check its indentation.

**Priority chain:** the three **boolean flags** are *additive* on top of the
resolved tier — they make things stricter, never looser. None of them has a value
that opts out of a requirement the tier imposes.

> **`feature_overrides` is not a flag and is not additive — it replaces the tier,
> in both directions.** On a `full` project, `feature_overrides.admin-console:
> minimal` really does drop that feature's required PRD sections to none. Do not
> rely on the additive rule as a safety net for the map; see
> `.claude/docs/workflow-modes.md`.

---

### Fields

```yaml
workflow_overrides:
  edge_cases: false              # force Edge Cases in PRDs written at minimal (already required at standard/full)
  config_flags: false            # force Configuration & Flags at standard (already required at full)
  design_language_strict: false  # force all 9 design-language sections at standard
  feature_overrides:             # per-feature tier — see below
    payments: full
```

### Per-feature overrides

```yaml
workflow_overrides:
  feature_overrides:
    payments: full          # design/prd/payments.md must carry all 11 sections on a standard project
    goals: standard
    admin-console: minimal  # internal back-office; the one-pager covers it
```

`feature_overrides` is a map of `<prd-stem>: <tier>`. The stem is the PRD file
name without `.md` (`design/prd/<stem>.md`) — the same slug as the feature-map
row, the `TR-<slug>-NNN` prefix and a story's `**PRD**:` field. Every other feature
uses the project tier.

A key whose PRD does not exist is an **orphan**: `/gate-check` reports it as
CONCERNS from the `architecture` gate onward. `/write-prd` treats a key naming a
PRD it is about to write as healthy.

An invalid `feature_overrides.<prd-stem>` tier is dropped (the feature follows
`modes.workflow`) and named on `resolve_config`'s `notes:` line.

---

### Affected skills

| Skill | How `workflow_overrides` changes behavior |
|---|---|
| **`/write-prd`** | Reads `feature_overrides[<feature>]` first, then the project tier; applies `edge_cases` / `config_flags` on top |
| **`/prd-review`** | Validates against the effective tier of the PRD under review, not the project default |
| **`/review-all-prds`** | Validates each PRD against its effective tier |
| **`/design-language`** | `design_language_strict: true` ⇒ all 9 sections regardless of tier |
| **`/gate-check`** | Checks each MVP PRD against its effective tier; `design_language_strict` raises the gate-build design-language item to all 9 sections; flags orphan `feature_overrides` keys |
| **`/create-epics`, `/create-stories`, `/story-done`, `/dev-story`, `/qa-plan`, `/regression-suite`, `/story-readiness`, `/propagate-prd-change`, `/reverse-document`** | Resolve the feature's effective tier through the `feature_overrides` label |

---

## modes.automation

**Controls:** Whether skills ask for decisions and approval before acting, or
recommend and proceed — the trade-off between user control and speed

**Values:** `collaborative` | `guided` | `autonomous`

- **Default:** `collaborative` (terminal default)
- **Status:** live
- **Local override:** yes
- **Label:** `automation` → `automation: <value> (<source>)`
- **Set by:** `/start`, `/settings`
- **Read by:** every automation-aware skill — each one whose bootstrap requests `automation` carries the automation prelude verbatim. Derive the list with the grep below (the `(,|`)` tail keeps `automation_always_ask` out).

```
grep -lE 'resolve_config --keys ([a-z_.]+,)*automation(,|`)' .claude/skills/*/SKILL.md
```

**Priority chain:** `project.local.yaml` → `project.yaml` → terminal default
`collaborative`.

> **Not a per-skill table.** This setting defines universal interaction rules that
> apply across all skills; the shared pattern each skill applies at every
> `AskUserQuestion` site and every write is `.claude/docs/automation-modes.md`.

> **Relaxes the collaboration protocol, opt-in.** `guided` and `autonomous`
> intentionally relax the Question → Options → Decision → Draft → Approval
> protocol of `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md`. `collaborative` preserves
> it exactly.

> **Safety net — `modes.automation_always_ask`.** Even at `autonomous`, the
> configured categories always prompt. See the next section.

---

### Value intent

| Value | Speed | Control | What changes |
|---|---|---|---|
| `collaborative` | Slowest | Full — every decision is the user's | Q → O → D → Draft → Approval strictly followed |
| `guided` | Balanced | High — major decisions are the user's, minor ones proceed | The AI states a recommendation and proceeds on minor decisions; `AskUserQuestion` is reserved for major or irreversible ones |
| `autonomous` | Fastest | Low — the AI decides, logs and proceeds | No `AskUserQuestion` except the always-ask categories; no draft review; no write approval; every decision logged |

---

### Universal rules per mode

#### collaborative

- `AskUserQuestion` for every multi-option decision
- 2–4 options with pros and cons for every design choice
- The full draft shown and approved before every write
- "May I write this to [filepath]?" before every write
- Section-by-section approval in multi-section authoring skills
- Multi-file changes need explicit approval of the full changeset

#### guided

- `AskUserQuestion` for **major decisions only** (classification below)
- Minor decisions: the AI states its recommendation inline and proceeds — e.g.
  *"Putting the formatter in the shared package — it matches the existing
  `packages/` layout. Continuing unless you want to change direction."*
- The draft is summarized briefly before writing; the skill proceeds without
  waiting for an explicit "yes"
- "May I write?" for **new files only** — updates to existing files proceed
- Major decisions still get options, capped at 2 with a clear recommendation
- Multi-section authoring writes each section as soon as it is drafted

#### autonomous

- No `AskUserQuestion` **except** for categories in `modes.automation_always_ask`
- No draft review and no "May I write?" prompts
- The recommended option is taken for every decision
- Every decision is logged immediately with `log_decision` to
  `production/session-logs/decision-log.md` (timestamp, skill, decision point,
  options, choice, reason, category) — decisions only, never evidence
- The user audits the decision log after the session

---

### Major vs minor decision classification (guided mode)

**Major — always `AskUserQuestion` in guided mode:**

| Decision type | Example |
|---|---|
| Naming a feature or choosing a document path | "What do we call this feature — `goals` or `savings-goals`?" |
| Mutually exclusive directions | "SSR or SPA for the marketing site?", "REST or GraphQL?" |
| A choice that gates downstream work | Stack choice, architecture approach, API style |
| Pricing and packaging | "Free / Plus plans, or a single paid tier with a trial?" |
| Scope changes | "Cut the referral feature or slip the beta?" |
| Anything that cannot change without significant rework | The data model's ownership of the savings goal entity |

**Minor — the AI recommends and proceeds in guided mode:**

| Decision type | Example |
|---|---|
| Which section to work on next | "Moving to Edge Cases next" |
| Optional section inclusion | "Adding an Open Questions section" |
| Formatting and structure | Heading levels, table vs prose |
| Detail inside an approved direction | Sub-options within an approved approach |
| Next-step routing after a phase completes | "Running /prd-review now" |

---

### Affected skills by category

**Authoring skills — highest impact.** Each pauses 10–15 times per document in
`collaborative`; 2–3 in `guided`; none in `autonomous`. Examples: `/brainstorm`,
`/write-prd`, `/map-features`, `/design-language`, `/ux-design`,
`/create-architecture`, `/architecture-decision`, `/api-design`, `/data-model`,
`/create-epics`, `/create-stories`, `/sprint-plan`.

**Review skills — medium impact.** They pause after presenting findings. In
`guided` the routing proceeds automatically; in `autonomous` the recommended path
is taken and logged. Examples: `/prd-review`, `/review-all-prds`,
`/architecture-review`, `/ux-review`, `/story-readiness`, `/story-done`,
`/milestone-review`, `/usability-report`.

**Team orchestration skills — medium impact.** They pause between phases. In
`guided` the pipeline advances unless BLOCKED; in `autonomous` it runs end to end
(always-ask categories still stop it). `/team-feature`, `/team-ui`,
`/team-content`, `/team-growth`, `/team-hardening`, `/team-qa`, `/team-release`.

**Implementation skills — lower impact.** They pause for architectural questions
before writing code. Examples: `/dev-story`, `/walking-skeleton`, `/code-review`.

**Setup and utility skills — lowest impact.** They pause for configuration or
routing questions; `guided` applies defaults, `autonomous` takes the recommended
default without prompting. Examples: `/adopt`, `/test-setup`, `/localize`,
`/retrospective`, `/smoke-check`, `/qa-plan`.

---

### Exemptions — skills that ignore the automation setting

These skills always behave as `collaborative`, never resolve `automation` and
never carry the automation prelude:

| Skill | Why always collaborative |
|---|---|
| **`/gate-check`** | Stage transitions |
| **`/hotfix`** | Production emergency |
| **`/incident`** | Production emergency |
| **`/rollout-plan`** | Production exposure |
| **`/setup-stack`** | Stack pins and live sources |
| **`/start`** | Runs before configuration |
| **`/settings`** | Changes the automation settings themselves |

---

### Decision log

Written with `log_decision` (six arguments: skill, decision point, options,
chosen, reason, category) to `production/session-logs/decision-log.md` —
append-only, created if absent, never truncated. The entry format is in
`.claude/docs/automation-modes.md`. `production/session-logs/` is gitignored, so
the decision log is an audit trail for the developer, **never** evidence for a
story, gate or release.

---

## modes.automation_always_ask

**Controls:** Decision categories that ALWAYS trigger `AskUserQuestion`, whatever
the automation mode

**Values:** list of category names from the table below (flow `[a, b]` or block list)

- **Default:** the 9-item default list (`_yaml_helper_always_ask_default`): `scope_changes`, `file_deletions`, `schema_changes`, `production_deploys`, `db_migrations`, `infra_changes`, `secrets_access`, `pii_data_access`, `billing_changes`
- **Status:** live
- **Local override:** yes — your personal safety categories
- **Label:** `automation_always_ask` → the configured list with `(configured)`, or the default list with `(default)`
- **Set by:** `/settings`
- **Read by:** autonomous-capable skills — every skill that names one of the categories requests this label (always-collaborative skills excepted, since they ask anyway). Membership is checked with `is_always_ask_category`.

> **Makes `autonomous` safe.** Without it, `autonomous` is "the AI does everything,
> no questions asked". With it, the AI does most things but stops on the
> destructive, irreversible or production-facing decisions you named.

> **A configured list replaces the default — it is not merged.** Setting
> `[scope_changes, file_deletions]` drops the other seven defaults, including
> `production_deploys` and `db_migrations`. List every category you want to keep.

---

### Recognized categories

| Category | Covers |
|---|---|
| `scope_changes` | adding/removing features or stories from an approved plan |
| `file_deletions` | deleting any tracked file |
| `schema_changes` | API/contract or config-file schema changes (OpenAPI, GraphQL, protobuf, AsyncAPI, JSON Schema, registry schemas) |
| `architecture_decisions` | accepting, superseding or deprecating an ADR |
| `version_bumps` | changing `project.version`, a pinned stack version, or a dependency major version |
| `external_calls` | calling third-party services or APIs from a skill |
| `production_deploys` | any deploy or rollout stage beyond preview/staging; a flag change in production |
| `db_migrations` | any database schema change or data migration/backfill (writing or running it) |
| `infra_changes` | IaC plan/apply, CI/CD workflow changes, DNS, CDN, scaling, staging environment changes |
| `secrets_access` | reading, creating or rotating secrets/keys |
| `pii_data_access` | querying or exporting personal data; log samples containing PII |
| `billing_changes` | prices, plans, entitlements, payment configuration, pricing experiments |

The three categories outside the default list (`architecture_decisions`,
`version_bumps`, `external_calls`) are opt-in.

---

### Affected skills

| Skill | Categories typically triggered |
|---|---|
| **`/api-design`** | `schema_changes` (contract changes) |
| **`/data-model`** | `db_migrations` (schema changes and migration files) |
| **`/architecture-decision`** | `architecture_decisions` |
| **`/test-setup`** | `infra_changes` (the CI workflow) |
| **`/walking-skeleton`** | `infra_changes` (pipeline and staging) — `production_deploys` never applies to staging |
| **`/load-test`** | `infra_changes` (when the run scales staging), `external_calls` (third-party traffic in the request path — stubbed, or sandbox use approved) |
| **`/security-audit`** | `secrets_access`, `pii_data_access` (reading secrets or PII samples) |
| **`/team-growth`** | `billing_changes` (pricing experiments) |
| **`/team-release`** | `production_deploys` (every deploy stage — and it never runs deploy commands itself) |
| **`/dev-story`, `/team-feature`** | `scope_changes`, `file_deletions`, `db_migrations`, `schema_changes` as the story requires |

---

## modes.story_granularity

**Controls:** How big each story is, and how many stories an epic and a sprint hold

**Values:** `coarse` | `balanced` | `fine`

- **Default:** none — fronted by `modes.rigor` (`minimal`→`coarse`, `standard`→`balanced`, `full`→`fine`)
- **Status:** live
- **Local override:** no — story size must be consistent across the team
- **Label:** `story_granularity` → `story_granularity: <value> (<source>)`
- **Set by:** `/settings`
- **Read by:** `/create-epics`, `/create-stories`, `/dev-story`, `/sprint-plan`, `/sprint-status`, `/story-done`

**Priority chain:** `modes.story_granularity` in `project.yaml` → `modes.rigor`
expansion → *(no terminal default)*

---

### Value intent

| Value | Story shape | Stories per sprint | Best for |
|---|---|---|---|
| `coarse` | 1 story = 1 feature slice. 3–5 days each. 5–10 acceptance criteria. | 2–4 | Solo builders, prototypes, "I know what I'm building" |
| `balanced` | 1 story = 1 task. 1–2 days each. 2–4 acceptance criteria. | 6–10 | Most product teams |
| `fine` | 1 story = 1 acceptance criterion. Hours each. Small PRs, easy review. | 15–25 | Larger teams, fine hand-offs, trunk-based teams merging several times a day |

---

### Affected skills

| Skill | coarse | balanced | fine |
|---|---|---|---|
| **`/create-epics`** | 3–5 child stories per epic | 5–10 per epic | 10–20 per epic |
| **`/create-stories`** | Each story carries 5–10 ACs covering a whole feature slice | 2–4 ACs covering one task | 1 AC; the story name restates it |
| **`/dev-story`** | Multi-day implementation cycle; longer working context for the engineer | 1–2 day expectation | Implementable in hours; tight context |
| **`/sprint-plan`** | 2–4 stories per sprint from velocity | 6–10 | 15–25 |
| **`/story-done`** | Fires every 3–5 days | Every 1–2 days | Several times a day |
| **`/sprint-status`** | Burn-down in feature-sized chunks | Task-sized chunks | AC-sized chunks |

---

## docs.density

**Controls:** How deep each section of an authored document goes — independent of
which sections are required

**Values:** `terse` | `balanced` | `thorough`

- **Default:** none — fronted by `modes.rigor` (`minimal`→`terse`, `standard`→`balanced`, `full`→`thorough`)
- **Status:** live
- **Local override:** no — the team produces documents of one depth
- **Label:** `docs.density` → `docs.density: <value> (<source>)`
- **Set by:** `/settings`
- **Read by:** authoring skills — `/brainstorm`, `/write-prd`, `/map-features`, `/design-language`, `/ux-design`, `/create-architecture`, `/architecture-decision`, `/create-epics`, `/create-stories`

**Priority chain:** `docs.density` in `project.yaml` → `modes.rigor` expansion →
*(no terminal default)*

> **Distinct from `workflow`, but set together by default.** `workflow` decides
> which sections exist; `density` decides how deep each goes. `modes.rigor` sets
> both, so the diagonal (`rigor: full` → 11 sections *and* thorough prose) is what
> you get without asking. The off-diagonal stays reachable because rigor overrides
> both ways: `rigor: full` + an explicit `docs.density: terse` gives every section,
> each one compact.

---

### Value intent

| Value | Per-section output style |
|---|---|
| `terse` | Bullet points, 2–5 lines per section. No rationale, no preamble — just the facts needed to implement. |
| `balanced` | Paragraphs with light rationale; examples where they help. |
| `thorough` | Full prose: rationale for every decision, examples, alternatives considered, decision history. |

---

### Combination matrix with workflow

|  | docs.density: terse | balanced | thorough |
|---|---|---|---|
| **workflow: minimal** | One-pager in bullets | One-pager in prose | One-pager + rationale |
| **workflow: standard** | 8 PRD sections, bullets | 8 sections, paragraphs | 8 sections + examples |
| **workflow: full** | 11 sections, bullets *(comprehensive but compact)* | 11 sections, paragraphs | 11 sections + rationale + examples |

---

### Affected skills

| Skill | terse | balanced | thorough |
|---|---|---|---|
| **`/write-prd`** | Each PRD section is 2–5 bullets | Paragraphs with the key decisions explained | Full prose, alternatives considered, decision history |
| **`/design-language`** | Each section is a bulleted list of tokens, constraints and references | Paragraphs explaining each choice | Full prose including explorations and rationale per token family |
| **`/create-architecture`** | Diagrams + decision bullets | Diagrams + paragraph explanations | Full prose with trade-offs and alternatives per layer |
| **`/ux-design`** | Wireframe descriptions + interaction bullets | Wireframes + flow descriptions | Full prose including research summaries and alternative flows |
| **`/map-features`** | One-line feature descriptions | A short paragraph per feature + dependency notes | Feature-by-feature rationale + relationship analysis |
| **`/brainstorm`** | Principle and brief bullets | Principles + brief with short rationale | Principles + brief with extensive rationale and alternatives |
| **`/architecture-decision`** | Context and decision as bullets | Paragraphs | Full prose with alternatives weighed in depth |

---

## testing.framework

**Controls:** Which test runners the project uses, per layer — the name skills put
in briefs and use to pick runner idioms

**Values:** string (e.g. `vitest+playwright`, `jest+maestro`, `pytest`, `junit5+testcontainers`)

- **Default:** unset
- **Status:** live
- **Local override:** no — one set of runners per project
- **Label:** — (read from `project.yaml`)
- **Set by:** `/test-setup`
- **Read by:** `/smoke-check`, `/test-helpers`, `/regression-suite`, `/test-setup` (shows the existing value before proposing runners)

**Priority chain:** `testing.framework` in `project.yaml` → unset. Unset is never
guessed: a reader that needs it asks, or reports `NOT CHECKED — testing.framework
unset (run /test-setup)`.

---

### Runners `/test-setup` proposes per layer

| Layer / stack | Unit & integration | UI / E2E |
|---|---|---|
| Web (React/Next.js, Vue/Nuxt) | Vitest (or Jest) + Testing Library | Playwright |
| React Native / Expo | Jest | Maestro (or Detox) |
| Flutter | `flutter_test` | `integration_test` (or Maestro) |
| iOS native | XCTest | XCUITest |
| Android native | JUnit | Espresso |
| Node backend | Vitest / Jest + Supertest | — |
| Spring | JUnit 5 + Testcontainers | — |
| Python | pytest + httpx | — |
| API contract | Schemathesis against the OpenAPI contract (or Pact when consumer-driven) | — |

The user confirms each choice; `/test-setup` then records the string here with
`testing.patterns` and the `commands.test` / `commands.e2e` / `commands.lint` /
`commands.typecheck` entries.

---

### Affected skills

| Skill | How `testing.framework` is used |
|---|---|
| **`/test-helpers`** | Generates factories, fixtures and mocks in the framework's idiom |
| **`/regression-suite`** | Test file naming and discovery patterns match the framework's conventions |
| **`/smoke-check`** | Names the runner in the report; the command it runs comes from `commands.*` |

---

## testing.patterns

**Controls:** Where tests live — the globs skills use to find test files, so
co-located tests (`apps/web/src/goals/goal-card.test.tsx`) count as evidence

**Values:** flow list of globs (e.g. `[apps/*/src/**/*.test.ts, tests/**]`)

- **Default:** unset ⇒ the `tests/**` convention, announced in the output
- **Status:** live
- **Local override:** no
- **Label:** — (read from `project.yaml`)
- **Set by:** `/test-setup`
- **Read by:** `/story-done`, `/test-evidence-review`, `/regression-suite`, `/qa-plan`, `/create-stories`, `/create-epics`, `/dev-story`, `/smoke-check`, `/test-helpers`, `/test-setup`, `/team-feature`, `/team-qa`, `/project-stage-detect`, `/gate-check` (smoke-report spot-read; Build → Hardening test items), `/architecture-review` (`rtm` mode), `/hotfix` (the regression test), `/feature-audit` (contract-test location), `/adopt` (tests & CI audit), `/bug-report` (verify mode)

**Priority chain:** `testing.patterns` in `project.yaml` → the `tests/**`
convention. A reader using the convention says so
(`testing.patterns unset — using the tests/** convention`), because in a JS/TS
monorepo with co-located tests "no test file under `tests/`" is not the same as
"no test" — a silent fallback would report tested stories as untested.

Write it in flow style. Globs follow the stack's naming convention: `*.test.ts`,
`*.spec.ts`, `test_*.py`, `*Test.kt`, `*_test.dart`.

---

## testing.strict

**Controls:** Whether failing or missing test evidence blocks a story from closing,
or produces a warning and lets work continue — per story type

**Values:** map of `{logic, integration, ui, e2e, config}` → `true` | `false`

- **Default:** unset — each skill applies its own per-type default (table below); `/smoke-check` treats an unset `config` as BLOCKING
- **Status:** live
- **Local override:** yes — each of the five keys
- **Label:** `testing.strict` → `testing.strict: logic=<v> integration=<v> ui=<v> e2e=<v> config=<v> (unset = each skill applies its own default)`
- **Set by:** `/settings`
- **Read by:** `/story-done`, `/dev-story`, `/story-readiness`, `/smoke-check`, `/gate-check`, `/create-stories` (QL-STORY-READY context), `/team-qa` (QL-TEST-COVERAGE context)

> **Per type, not a single boolean.** A global switch forces all-or-nothing. Per
> type matches how product teams actually work: strict unit, contract and E2E
> gates, an advisory config check.

> **Composes with `qa.level`.** `qa.level` decides whether evidence is REQUIRED;
> `testing.strict` decides whether a failure BLOCKS once evidence is required. At
> `qa.level: minimal` the map has little to act on.

> **Reported, never defaulted, by `resolve_config`.** The label prints `unset` for
> a type nobody configured, because the unset default legitimately differs between
> skills: `/smoke-check` is a build-health gate, so an unset
> `testing.strict.config` is BLOCKING there, while `/story-done` treats Config
> stories as ADVISORY. Emitting one default would silently pick a winner. Only an
> explicit `testing.strict.config: false` makes a failing smoke check advisory in
> `/smoke-check`.

---

### Value intent per type

| Type | Covers | `true` | `false` | Default when unset |
|---|---|---|---|---|
| `logic` | Domain rules, calculations, validators, state machines | A failing unit test BLOCKS — the story cannot close | Failures WARN — the story can close | BLOCKING |
| `integration` | API handler + DB, queue consumers, third-party adapters, contract tests against `docs/api/` | A failing integration or contract test BLOCKS | WARN | BLOCKING |
| `ui` | Screens, components, visual states (including visual regression) | Missing component tests or screenshots of each state touched BLOCK | Advisory | BLOCKING |
| `e2e` | A critical user journey across UI → API → DB | A failing or missing E2E run (with trace/screenshot) BLOCKS | Advisory | BLOCKING |
| `config` | Feature flags, env config, pricing and limit tables | A failing smoke check BLOCKS | Advisory | ADVISORY (`/smoke-check`: BLOCKING) |

**Migration floor — independent of this map.** A story whose `**Migration**` is not
`None` (any type) requires `production/qa/evidence/<story-slug>/migration-dry-run.log`
— Expand applied and rolled back on a disposable database — at every `qa.level`
and regardless of `testing.strict.config`. Absent ⇒ BLOCKING.

---

### Affected skills

| Skill | `strict.<type>: true` | `strict.<type>: false` |
|---|---|---|
| **`/story-done`** | A story of that type cannot close on failing or missing evidence | The story closes; a warning is recorded in the story file |
| **`/story-readiness`** | The story's test requirement must be defined before implementation — blocks if absent | Validated, surfaced as a warning |
| **`/gate-check`** | Failures of that type block the phase transition | Surfaced as CONCERNS |
| **`/smoke-check`** | A failing smoke check (`config`) blocks QA hand-off | Flagged; the hand-off proceeds |
| **`/dev-story`** | The routing brief states the test requirement; a story without one is flagged unverifiable | The requirement is advisory |

---

## qa.level

**Controls:** What test evidence a story must carry on disk to be marked Complete

**Values:** `minimal` | `standard` | `full`

- **Default:** none — fronted by `modes.rigor` (`minimal`→`minimal`, `standard`→`standard`, `full`→`full`)
- **Status:** live
- **Local override:** no — evidence on disk is a team contract
- **Label:** `qa.level` → `qa.level: <value> (<source>)`
- **Set by:** `/settings`
- **Read by:** `/story-done`, `/gate-check`, `/smoke-check`, `/dev-story`, `/story-readiness`, `/qa-plan`, `/regression-suite`, `/team-qa`

**Priority chain:** `qa.level` in `project.yaml` → `modes.rigor` expansion →
*(no terminal default)*

> **Different axis from `testing.strict`.** `qa.level` = what evidence is
> required. `testing.strict` = whether failures block.

> **It relaxes per-story evidence, never the floors.** At every level the smoke
> report (`production/qa/smoke-*.md`) is required at the `hardening` and `launch`
> gates, and the migration dry-run is required for every story with a migration.
> Evidence counts only when retained on disk outside gitignored paths —
> `production/session-logs/` never holds evidence.

---

### Value intent

| Aspect | minimal | standard | full |
|---|---|---|---|
| Logic stories | No test required | Unit test required (`testing.strict.logic` decides blocking) | Same, for every Logic story |
| Integration stories | No test required | Integration or contract test required | Same + regression coverage |
| UI stories | No evidence required | Screenshots of each state touched (desktop + mobile viewport, or device) or component tests | Same + visual regression where the stack has it |
| E2E stories | No test required | E2E test passing against a running environment, with trace/screenshot | Same, for every critical user journey |
| Config stories | No evidence required | Smoke check (advisory) | Smoke check required |
| Stories with a migration | Dry-run evidence required (floor) | Same | Same |
| `/story-done` test gate | Acceptance criteria only (+ the migration floor) | Enforced per story type | Enforced for every story type |
| `/gate-check` test enforcement | Per-story evidence not scored; the floors still apply (smoke report, migration dry-run) | Per-story evidence scored per type | Per-story evidence scored for every type |
| `/dev-story` routing brief | No "Test required" line | Per-type test requirement | Per-type requirement + regression note |
| Regression suite required by | Never | Hardening | Build |
| Best for | Hackathons, throwaway prototypes | Most product teams | Regulated products (fintech, health), B2B with SLAs, larger teams |

---

### Affected skills

| Skill | minimal | standard | full |
|---|---|---|---|
| **`/story-done`** | Acceptance criteria only; no evidence required (migration floor kept) | Per-type evidence required; strictness from `testing.strict` | Every type requires evidence; strictness from `testing.strict` |
| **`/story-readiness`** | No test requirement validated | Test requirement per story type validated | Test requirement + regression coverage validated |
| **`/dev-story`** | Routing brief has no "Test required" line | Per-type test requirement passed to the engineer | Plus the regression expectation |
| **`/smoke-check`** | Runs; the report is the floor | Required before QA hand-off | Required before QA hand-off and on every release candidate |
| **`/gate-check`** | Floors only (smoke report, migration dry-run) | Per-story evidence checked per type | Every type |
| **`/qa-plan`** | A minimal smoke plan | A full plan per story type | Full plan + regression targets per feature |
| **`/regression-suite`** | Not generated | Generated at Hardening entry | Generated at Build entry |

---

## qa.coverage_minimum

> ### RESERVED - NOT IMPLEMENTED
>
> **No skill or hook reads this setting. Setting it has no effect.** Everything
> below describes the intended design, not current behaviour.
>
> The value is stored when you set it, and then ignored. No gate compares any
> coverage report against it.

**Controls:** Minimum line-coverage percentage enforced at `qa.level: full`

**Values:** integer 0–100

- **Default:** unset
- **Status:** RESERVED
- **Local override:** no
- **Label:** —
- **Set by:** —
- **Read by:** none

**Intended design.** Only meaningful at `qa.level: full`. Coverage reports differ
per stack — V8/Istanbul `lcov` for JS/TS, `coverage.py` for Python, JaCoCo for
JVM, Xcode coverage for iOS, `lcov` from `flutter test --coverage` — so a reader
would have to name the report it parsed and report `NOT ASSESSED` when none
exists, never a pass.

---

## team.size

**Controls:** Which agents are active by default in team pipelines — a solo builder
should not get a full studio roster on every change

**Values:** `individual` | `small` | `studio`

- **Default:** none — fronted by `modes.rigor` (`minimal`/`standard`→`individual`, `full`→`studio`)
- **Status:** live
- **Local override:** yes — review and pipeline depth differ, artifacts do not
- **Label:** `team.size` → `team.size: <value> (<source>)`
- **Set by:** `/settings`
- **Read by:** all `team-*` skills; `/brainstorm`, `/map-features`, `/create-architecture`, `/architecture-decision`, `/gate-check`; its resolved value is passed as Context to DM-SCOPE and TL-FEASIBILITY

**Priority chain:** `project.local.yaml` → `project.yaml` → `modes.rigor` expansion
→ *(no terminal default)*

> **`individual` at `minimal` and `standard`, `studio` at `full`.** A smaller team
> on a big project sets `team.size: small` explicitly, which wins over the
> rigor-derived value.

> **Different axis from `workflow`.** `workflow` decides *what documents are
> required*; `team.size` decides *which agents exist to make them*. A solo founder
> on `workflow: full` still needs the same coverage from a smaller active set.

---

### Active set per team skill

Each team skill announces its active set for the resolved `team.size` in Phase 0,
so a collapsed pipeline is never mistaken for a full one.

| Skill | individual | small (the documented pipeline) | studio (adds) |
|---|---|---|---|
| **`/team-feature`** | backend-engineer (or frontend-engineer when the Surface is web only) runs the pipeline | product-manager → product-designer (UX delta) → tech-lead (API/data delta) → backend-engineer ∥ frontend-engineer ∥ mobile-engineer (per surface) → qa-engineer | Routed stack sub-specialists, security-engineer review, adversarial review pass |
| **`/team-ui`** | frontend-engineer or mobile-engineer | product-designer → design-engineer → frontend/mobile-engineer → accessibility-specialist | ux-writer, routed stack sub-specialists |
| **`/team-content`** | ux-writer | ux-writer → localization-lead → customer-success-manager | accessibility-specialist |
| **`/team-growth`** | growth-manager | growth-manager → analytics-engineer → product-designer ∥ ux-writer → variants handed off as stories | monetization-strategist, customer-success-manager, data-engineer |
| **`/team-hardening`** | performance-engineer | performance-engineer ∥ sre-engineer ∥ security-engineer (quick audit) ∥ accessibility-specialist → qa-engineer | design-engineer, routed stack leads, adversarial review |
| **`/team-qa`** | qa-engineer | qa-lead → qa-engineer | accessibility-specialist |
| **`/team-release`** | release-manager | release-manager → qa-lead → devops-engineer → sre-engineer | security-engineer, customer-success-manager, localization-lead, delivery-manager, analytics-engineer |

---

### Special cases

- **Team-size scoping never removes a director gate.** Team skills spawn only the
  gates they own, after the review-mode check; `modes.review_mode` — not
  `team.size` — decides whether those run.
- **`/gate-check` panel width** is `modes.workflow`'s axis (`/gate-check`
  Section 4b), not this one.
- **`individual` disables nothing.** It changes which agents are active by
  default; any agent can still be invoked by name.
- When `individual` needs a non-active agent (a security review of an auth
  change, say), the skill notes it and routes through the nearest active agent or
  asks — it never silently skips the concern.

---

## project.stage

**Controls:** The current development phase — which gate `/gate-check` targets next
and what artifacts are expected to exist

**Values:** `Discovery` | `Definition` | `Architecture` | `Validation` | `Build` | `Hardening` | `Launch`

- **Default:** unset ⇒ `bash .claude/scripts/stage-estimate.sh` estimates it from the tree (`SOURCE: estimated`)
- **Status:** live
- **Local override:** no — the phase is a project fact
- **Label:** `project.stage` → `project.stage: <value> (<source>)`
- **Set by:** `/start` (once: `Discovery`, or the estimator's `STAGE` for an existing codebase); `/gate-check` (on a PASS, after explicit user confirmation, then re-read and verified)
- **Read by:** `statusline.sh` and `detect-gaps.sh` (through `stage-estimate.sh`), `/help`, `/gate-check`, `/project-stage-detect`, `/release-checklist`, `/launch-checklist`, `/team-qa`, `/onboard`

> **A project attribute, not a mode.** It records where the product is in its
> lifecycle. Only `/gate-check` advances it — and only on PASS with user
> confirmation. `project.yaml` is the only place it is stored.

> **Enum-invalid ⇒ estimated.** A value outside the seven (for example a phase
> name from another framework) is rejected by resolution, named on `notes:`, and
> the estimator's answer is used instead.

> **The catalog id is the lowercase stage value** (`Build` → `build`), which is
> also the `/gate-check` target argument.

---

### Stage progression and gate requirements

Each row is the gate that must be passed to advance FROM that stage. The
requirements are summarized at `standard`; the tier-exact lists are the gate
reference files.

| From stage | `/gate-check` target | Key artifacts required to pass (standard) |
|---|---|---|
| **Discovery** | `definition` | Product brief (one-pager at `minimal`), reviewed by `/prd-review` |
| **Definition** | `architecture` | Feature map; every MVP PRD with the tier's sections, reviewed (not applicable at `minimal`) |
| **Architecture** | `validation` | Stack pinned; architecture doc; critical ADRs; API contract and data model (*Backend*); threat model (*PII*); architecture review; accessibility requirements (*UI*); test framework + CI; SLO journeys |
| **Validation** | `build` | Sprint plan; epics + stories; Foundation/Core ADRs Accepted; design language sections 1–5, UX specs and reviews (*UI*); walking skeleton on staging |
| **Build** | `hardening` | MVP features implemented; E2E per critical journey; smoke check PASS; no unresolved S1; migrations expanded on staging |
| **Hardening** | `launch` | Release checklist GO; rollout plan READY TO ROLL OUT; launch checklist GO; full security audit; smoke PASS on the release candidate; QA sign-off; hardening report; runbooks; ToS & Privacy Policy; release notes (`/changelog <version>`, then `/release-notes`); no unresolved S1/S2 |
| **Launch** | — (terminal) | No further gate. Every later release runs PRD → sprint → story → smoke → release checklist → rollout plan → release record, with its records under `production/releases/<version>/` — records, not gates |

---

### Affected skills

| Skill | How it uses the stage |
|---|---|
| **`/gate-check`** | With no argument, targets the `next_phase` of the estimator's `STAGE`; writes the new stage on PASS only after "Gate passed. May I update `project.stage` in `project.yaml` to '<Stage>'?" |
| **`/start`** | Writes the initial stage once |
| **`/help`, `/project-stage-detect`** | Report where the project is and what comes next; run `stage-estimate.sh` when the stage is unset |
| **`statusline.sh`** | Shows `STAGE` from `stage-estimate.sh --quick`; the Epic > Feature > Task breadcrumb appears from `Build` onward |
| **`detect-gaps.sh`** | Warns when the estimate is two or more phases ahead of the configured stage — "run /gate-check" |
| **`/release-checklist`, `/launch-checklist`** | Release context — the phase the release ships from |
| **`/onboard`** | States the current stage in the onboarding document's `## Project Summary` from the resolved `project.stage` line; unset ⇒ says so and suggests `/project-stage-detect` |

---

## project.category

**Controls:** What kind of product this is, in plain words — a signal for
recommendations, never a branch condition

**Values:** string (e.g. `B2C fintech`, `B2B SaaS`, `marketplace`, `consumer social`, `developer tool`, `health`)

- **Default:** unset
- **Status:** live
- **Local override:** no
- **Label:** — (read from `project.yaml`)
- **Set by:** `/brainstorm` (asks "May I set `project.name` and `project.category` in `project.yaml`?"), `/settings`
- **Read by:** `/brainstorm`, `/setup-stack` (profile suggestions), `/onboard` (Project Summary), `/launch-checklist` (a hint only: prompts the question whether business customers are onboarded), `.claude/docs/settings-guidance.md` (archetype seeding)

Free text: no script parses it and no skill branches on its value. Conditions that
change behavior come from structured keys — `platform.surfaces`,
`compliance.regions`, `privacy.handles_pii`, `release.distribution` — never from the
category string.

---

## project.name and project.version

**Controls:** The product's name, and the version of the release being prepared

**Values:** `project.name` → string; `project.version` → semver string (e.g. `1.2.0`)

| Key | Default | Status | Local override | Label | Set by | Read by |
|---|---|---|---|---|---|---|
| `project.name` | unset | live | no | — | `/brainstorm`, `/settings` | `/onboard`, `/release-notes`, `/launch-checklist` |
| `project.version` | unset | live | no | — | `/team-release` (asks first), `/settings` | `/changelog`, `/release-notes`, `/release-checklist`, `/rollout-plan`, `/team-release`, `/launch-checklist`, `/gate-check` (launch gate `<version>`), `/hotfix` (the record's `**Release**` line) |

`<version>` in release paths (`production/releases/<version>/…`) is
`project.version` or the version argument passed to the skill — semver, e.g.
`1.2.0`. Mobile build numbers and version codes go *inside* the release files,
never in the directory name.

Changing `project.version` is a `version_bumps` decision (see
`modes.automation_always_ask`).

---

## stack.pinned_on

**Controls:** The date the stack was last pinned and verified against live sources —
the completion marker of stack setup

**Values:** ISO date (e.g. `2026-09-27`)

- **Default:** unset
- **Status:** live
- **Local override:** no
- **Label:** `stack` — an unset value adds ` pinned_on=unset` to the stack line
- **Set by:** `/setup-stack` (and `/setup-stack refresh`, which rewrites it)
- **Read by:** the catalog `stack-setup` steps (discovery — recommended; definition — standard/full; architecture — every tier; pattern `pinned_on:`), `stage-estimate.sh`, `session-start.sh`, `/gate-check`

`/setup-stack` writes it **last**, and only when every *configured* component has a
Pinned Components row in `docs/stack-reference/VERSION.md` that is sourced,
`n/a (managed service)`, or `NOT DETERMINED — accepted by user YYYY-MM-DD`.
Unconfigured layers do not block it — data and cloud may wait for their
Foundation ADRs.

| Reader | Effect |
|---|---|
| **`/gate-check`** | "Stack pinned" is recommended at `definition`, required at `architecture`, and the `validation` floor at every tier; accepted `NOT DETERMINED` gaps ⇒ CONCERNS, named |
| **`session-start.sh`** | Warns "run /setup-stack refresh" when it is set but `docs/stack-reference/VERSION.md` still reads `NOT DETERMINED` in its `**Stack Pinned**` row |
| **Catalog / `/help`** | The `stack-setup` steps are PRESENT once the pattern matches |

---

## stack.layers and specialists

**Controls:** The product's technology stack per layer — framework, version,
language, runtime and code root(s) — and the stack specialist each layer routes to

**Values:** component strings, versions and paths per the key table below (no enum); `specialists.<layer>` takes an agent name

- **Default:** unset (every key). An unset layer means "not decided yet", never "not used".
- **Status:** live
- **Local override:** no — the whole team builds on the same stack
- **Label:** `stack` (components, versions, roots and routing); `code_roots` (roots)
- **Set by:** `/setup-stack` (guided setup, `refresh`, `upgrade`)
- **Read by:** specialist routing in `yaml-helper.sh`, `resolve_code_roots`, `project-coherence.sh`, `/data-model` (data layer), `validate-push.sh` (`migrations_dir`), and every skill whose bootstrap requests `stack` or `code_roots`

| Key | Type | Label |
|---|---|---|
| `stack.layers.web.framework`, `.version`, `.language` | strings (`Next.js`, `"15.3"`, `TypeScript`) | `stack` |
| `stack.layers.web.root` | path or flow list of paths | `stack`, `code_roots` |
| `stack.layers.mobile.framework`, `.version`, `.language` | strings (`React Native (Expo)`, `Flutter`, `SwiftUI`, `Jetpack Compose`) | `stack` |
| `stack.layers.mobile.root` | path or flow list | `stack`, `code_roots` |
| `stack.layers.backend.framework`, `.version`, `.language`, `.runtime` | strings (`NestJS`, `"11.0"`, `TypeScript`, `Node.js 22`) | `stack` |
| `stack.layers.backend.root` | path or flow list | `stack`, `code_roots` |
| `stack.layers.data.database`, `.cache`, `.queue`, `.orm` | component strings with an optional trailing version (`PostgreSQL 16`, `Redis 7`, `Prisma 6`, `none`) | `stack` |
| `stack.layers.data.migrations_dir` | path | `code_roots` |
| `stack.layers.cloud.provider`, `.iac` | component strings (`AWS`, `Terraform 1.9`) | `stack` |
| `stack.layers.cloud.root` | path or flow list | `stack`, `code_roots` |
| `specialists.web`, `specialists.mobile`, `specialists.backend` | agent name (an override of the derived routing) | `stack` |

**Versions.** Web, mobile and backend carry the version in the separate `version`
key. Data and cloud components carry it *inside* the component string when one is
pinned (`database: PostgreSQL 16`); `docs/stack-reference/VERSION.md` rows use the
component with the trailing version removed. Versions come from live sources with
a source URL and retrieval date — `/setup-stack` never guesses one, and a managed
service with no user-visible version is recorded as `n/a (managed service)`.

**Roots.** Each `root` is a scalar path or a flow list `[apps/web, apps/admin]`
(block lists are not supported for this key). `resolve_code_roots` emits one line
per root — `<dir>\t<layer>\t<source>` — plus `data` for `migrations_dir`,
`shared` for `stack.shared_roots`, and `undeclared` for workspace directories no
layer declares. It never defaults to `src`. The algorithm and its consumers are in
`.claude/docs/code-root-resolution.md`.

The `stack` label prints every one of the five layers, either as `<layer>=…` or in
`unset=`:

```
stack: web=Next.js 15.3 @apps/web,apps/admin; backend=NestJS 11.0 @apps/api,services/worker; data=PostgreSQL 16; unset=mobile,cloud [routing: web-specialist>nextjs-specialist, backend-specialist>node-specialist, data-specialist] (project.yaml)
```

With nothing configured it prints `stack: unset — run /setup-stack`.

---

### Specialist routing

Routing is derived once, in `yaml-helper.sh` (`_yaml_helper_route_specialist
<layer>`, internal), and printed in the `stack` line as `<lead>`, `<lead>><sub>`,
or `<lead>><sub1>+<sub2>` for native mobile. Skills spawn what the line says; none
carries its own routing table.

| Layer | Configured by | Lead | Sub-specialist chosen when the value matches (case-insensitive ERE; rules in order, first match wins) | Override key |
|---|---|---|---|---|
| web | `stack.layers.web.framework` | web-specialist | 1 `next\|react` → nextjs-specialist; 2 `nuxt\|vue` → vue-nuxt-specialist; else none | `specialists.web` |
| mobile | `stack.layers.mobile.framework` | mobile-specialist | 1 `react native\|expo` → react-native-specialist; 2 `flutter` → flutter-specialist; 3 value matches both (`swift\|ios`) and (`kotlin\|compose\|android`), or matches `^native` → ios-specialist + android-specialist; 4 `swift\|ios` → ios-specialist; 5 `kotlin\|compose\|android` → android-specialist; else none | `specialists.mobile` |
| backend | `stack.layers.backend.framework` | backend-specialist | 1 `nest\|express\|fastify\|hono\|node` → node-specialist; 2 `spring\|java\|kotlin` → spring-specialist; 3 `fastapi\|django\|flask\|python` → python-specialist; else none | `specialists.backend` |
| data | `stack.layers.data.database` | data-specialist | — | — |
| cloud | `stack.layers.cloud.provider` | cloud-specialist | — | — |

- **Unset layer ⇒ no specialist spawned**, and the skill prints
  `NOT CHECKED — <layer> layer not configured (run /setup-stack)`. A skipped
  specialist always announces itself.
- **Override.** `specialists.<layer>` (web, mobile, backend) replaces the derived
  *sub*-specialist — for example `specialists.backend: python-specialist` for a
  Litestar service, which the rules do not recognize. The lead is fixed per layer.
  Accepted values: that lead's own sub-specialists (web: `nextjs-specialist`,
  `vue-nuxt-specialist`; mobile: `react-native-specialist`, `flutter-specialist`,
  `ios-specialist`, `android-specialist`, and the native pair
  `ios-specialist+android-specialist`; backend: `node-specialist`,
  `spring-specialist`, `python-specialist`), or the layer lead itself
  (`web-specialist`, `mobile-specialist` or `backend-specialist`), which means
  lead only, no sub-specialist. Any other value is ignored — the derived routing
  stands — and named on `resolve_config`'s `notes:` line.
- **Lead vs sub.** Skills spawn the sub-specialist for routine work and the layer
  lead when the story's `**Risk**` is HIGH — taken from the Knowledge Risk of the
  component in `docs/stack-reference/VERSION.md`; no row or `NOT DETERMINED` counts
  as HIGH. The lead may delegate through its `Agent(...)` grant. Data and cloud
  leads have no subs.

---

### Affected skills

| Skill | How the stack is used |
|---|---|
| **`/dev-story`** | Routes the story by `**Surface**` to the primary engineer, adds the routed sub-specialist (or the lead on HIGH risk) and writes in the resolved root |
| **`/architecture-decision`, `/create-architecture`, `/architecture-review`** | Consult the routed stack leads; stamp component versions in `## Stack Compatibility`; read `docs/stack-reference/` |
| **`/code-review`** | Routes the review to the stack specialist of the changed files' layer |
| **`/test-setup`, `/test-helpers`** | Propose runners and write configs per configured layer and root |
| **`/data-model`** | Uses the data layer (database, ORM) and writes migration files under `migrations_dir` |
| **`/walking-skeleton`, `/team-feature`, `/team-ui`, `/team-hardening`** | Spawn routed specialists for the configured layers only |
| **`/team-feature`, `/team-ui`** | Write each surface's implementation in the root the `code_roots` line gives its layer (`data=` for migration files); no resolved root ⇒ reported as a blocker, never a guessed directory |
| **`/onboard`, `/project-stage-detect`, `/reverse-document`** | Read the resolved `stack` and `code_roots` lines to pick the roots they scan, and print `NOT CHECKED — no code root resolved (set stack.layers.<layer>.root via /setup-stack)` when none resolves |
| **`/security-audit`, `/perf-profile`, `/bundle-audit`, `/load-test`** | Choose stack-appropriate tools (k6 / Locust / Gatling; `npm audit` / `pip-audit` / `osv-scanner`) |
| **`project-coherence.sh`** | Compares each configured component with its VERSION.md row, runtime files and manifest dependencies — observations only (`MATCH` / `MISMATCH` / `UNCHECKED`) |

---

## stack.monorepo and stack.shared_roots

**Controls:** Whether the repository is a workspace monorepo, and which directories
hold code shared across layers

**Values:** `stack.monorepo` → `true` | `false`; `stack.shared_roots` → flow list of paths

| Key | Default | Status | Local override | Label | Set by | Read by |
|---|---|---|---|---|---|---|
| `stack.monorepo` | unset | live | no | — | `/setup-stack` | `resolve_code_roots`, `/test-setup`, `/security-audit` |
| `stack.shared_roots` | unset | live | no | `code_roots` | `/setup-stack` | `resolve_code_roots` |

- **`stack.monorepo: true`** — a pnpm/yarn/npm workspace, Turborepo or Nx
  monorepo, or a Gradle multi-project build. `/test-setup` reads it when placing
  runner configs (per workspace package rather than once at the repository root).
- **`stack.shared_roots`** — e.g. `[packages]`. `resolve_code_roots` emits each
  entry as layer `shared`. `/dev-story` adds platform-engineer as a secondary when
  a story's files sit under a shared root, and uses the first shared root for
  Foundation-layer shared code.
- **Undeclared workspaces are always found.** Whatever these keys say, every
  `apps/*`, `services/*` or `packages/*` directory that contains a manifest and
  lies outside the declared roots is emitted as `undeclared`; callers include it in
  their scans and print `WARN: undeclared code roots: <dirs> — declare them with /setup-stack`.
  Monorepos are supported, never assumed; a single-app repo keeps working.

---

## stack.package_manager and stack.profile

**Controls:** The package manager the repository uses, and the informational name of
the setup preset it started from

**Values:** `stack.package_manager` → string (`pnpm`, `npm`, `yarn`, `bun`, `gradle`, `maven`, `uv`, `poetry`, `pip`, …); `stack.profile` → string (informational)

| Key | Default | Status | Local override | Label | Set by | Read by |
|---|---|---|---|---|---|---|
| `stack.package_manager` | unset | live | no | — | `/setup-stack` | `project-coherence.sh` (the lockfile must match), `/test-setup`, `/test-helpers`, `/security-audit` (picks the dependency-audit tool; frozen-lockfile check) |
| `stack.profile` | unset | live | no | — | `/setup-stack` | `/setup-stack` only — never branched on |

`stack.profile` names the golden-path preset the user picked from
`.claude/skills/setup-stack/references/profiles.md` (`ts-fullstack-web`,
`expo-mobile-ts-api`, `flutter-spring`, `python-api-react`). Presets name components
only, never versions, and the layers remain individually editable — so no skill may
infer anything from the profile name. Read the layers.

---

## platform.surfaces

**Controls:** Which surfaces the product ships on — the input to the *UI*, *Backend*
and *Public API* conditions every gate and checklist uses

**Values:** list ⊆ `web` | `ios` | `android` | `api`

- **Default:** unset ⇒ ask
- **Status:** live
- **Local override:** no
- **Label:** `surfaces` → `platform.surfaces: web, ios, api (project.yaml)` or `platform.surfaces: (unset -- ask which surfaces ship)`
- **Set by:** `/setup-stack`
- **Read by:** every skill whose bootstrap requests `surfaces` (derive with `grep -lE 'resolve_config --keys ([a-z_.]+,)*surfaces' .claude/skills/*/SKILL.md`), and `/gate-check` conditions

**`api` means an externally consumed API** — public or partner. The backend your own
apps call is not the `api` surface; it is covered by the *Backend* condition
through `stack.layers.backend` and `stack.layers.data`.

**List-enum rules** (`_yaml_helper_array_enums`):

- Parsed as a list (flow `[web, ios]` or block), never as a scalar. Each element is
  validated; an invalid one is dropped with a note
  (`platform.surfaces: dropped invalid element 'iso'`) and the rest survives.
- **`[]` is invalid** here — a product ships at least one surface. It is noted and
  the key is treated as unset.
- `/settings` accepts `web,ios` or `[web, ios]`, validates each element, rejects
  the whole write if any element is invalid, and writes flow style.
- The story `**Surface**` field is a **superset** (`mobile`, `admin`, `infra`,
  `analytics` are story surfaces); those are not valid values here.

**Derived conditions:**

- *UI* = `platform.surfaces` ∩ {web, ios, android} ≠ ∅. **Unset ⇒ MANUAL CHECK NEEDED
  (ask), never "no UI".**
- *Backend* = `stack.layers.backend.framework` set, or `stack.layers.data.database`
  set, or `api` ∈ `platform.surfaces`.
- *Public API* = `api` ∈ `platform.surfaces`.

---

### Affected skills

| Skill | Effect |
|---|---|
| **`/gate-check`** | Evaluates *UI*, *Backend* and *Public API* items; an item whose condition is false is `N/A — <condition> not configured` and not scored; DD-PHASE-GATE is omitted (and named) when no UI surface is configured — known, not unset |
| **`/help`, `/project-stage-detect`** | Render `when=ui` / `when=backend` catalog steps as OPTIONAL only when the condition is **known** false |
| **`/release-checklist`, `/release-notes`** | Web block when `web` is listed; `## API / Developers` release-note section only with *Public API* |
| **`/smoke-check`, `/perf-profile`, `/bundle-audit`** | Scope batches and budgets per surface (`/smoke-check --surface web\|ios\|android\|api`; `/perf-profile surface:<web\|ios\|android\|api>`; `/bundle-audit surface:<web\|ios\|android>`) |
| **`/design-language`, `/ux-design`, `/team-ui`** | Platform adaptation (web / iOS HIG / Material) per UI surface |
| **`/team-feature`, `/walking-skeleton`** | Implement in parallel per surface |
| **`/api-design`** | Developer guides under `docs/api/guides/` only with *Public API* |

---

## platform.browsers and platform.min_os

**Controls:** The browsers the web surface supports, and the minimum OS versions the
mobile apps support

**Values:** `platform.browsers` → flow list of browserslist queries; `platform.min_os.ios`, `platform.min_os.android` → strings

| Key | Default | Status | Local override | Label | Set by | Read by |
|---|---|---|---|---|---|---|
| `platform.browsers` | unset | live | no | — | `/setup-stack` | `/test-setup` (Playwright projects), `/smoke-check`, `/bundle-audit` (transpile targets), `/release-checklist` (browser support), `/create-architecture` |
| `platform.min_os.ios` | unset | live | no | — | `/setup-stack` | `/release-checklist`, `/rollout-plan`, `/hotfix`, `/smoke-check` (iOS/Android surface batches), `/create-architecture` |
| `platform.min_os.android` | unset | live | no | — | `/setup-stack` | `/release-checklist`, `/rollout-plan`, `/hotfix`, `/smoke-check` (iOS/Android surface batches), `/create-architecture` |

```yaml
platform:
  browsers: [last 2 versions, not dead, iOS >= 16]   # browserslist syntax
  min_os:
    ios: "16.0"
    android: "26"          # minSdk API level (Android 8.0)
```

Korean-market web products usually test Samsung Internet and in-app browsers
(KakaoTalk, Naver) alongside Chrome and Safari; name them in the list rather than
relying on `defaults`. `min_os` drives the minimum-supported-version and
force-update policy in `/rollout-plan` and the store block of `/release-checklist`.

---

## release.distribution

**Controls:** How releases reach users — which release, rollout and store tracks the
checklists emit

**Values:** `web` | `stores` | `web+stores` | `enterprise` | `internal`

- **Default:** unset ⇒ ask. No default is substituted: an unset value must stay
  unset so skills take their "ask how this release ships" branch — substituting a
  value would either make the question unaskable or emit every track.
- **Status:** live
- **Local override:** no — a local value is ignored with a "not locally overridable" note
- **Label:** `distribution` (also accepted: `release.distribution`) → `release.distribution: <value> (project.yaml)` or `release.distribution: (unset -- ask how this release ships)`. The label resolves through `resolve_setting`, so an invalid value is dropped with a note and the unset form is printed.
- **Set by:** `/setup-stack`
- **Read by:** `/release-checklist`, `/launch-checklist`, `/release-notes`, `/rollout-plan`, `/team-release`, `/gate-check`, `/hotfix`, `/help`, `/project-stage-detect`, `/create-architecture`

---

### Value intent

| Value | Meaning |
|---|---|
| `web` | Web app delivered through CI/CD — deploys, CDN, progressive delivery with flags and canaries |
| `stores` | Mobile apps through the App Store and Google Play — store review, signing, phased release |
| `web+stores` | Both tracks |
| `enterprise` | Private distribution to customer organizations (Apple Business Manager custom apps, Managed Google Play, customer-hosted or single-tenant deployments) |
| `internal` | Employees or testers only (internal tools, TestFlight internal / Play internal testing) |

*Stores* = `release.distribution` ∈ {`stores`, `web+stores`}.

---

### Affected skills

| Skill | Effect |
|---|---|
| **`/release-checklist`** | Store block (build number/version code, signing, privacy nutrition labels / Data safety, review guidelines, TestFlight / internal track, phased release) only with *Stores*; unset ⇒ ask, never every track |
| **`/launch-checklist`** | `## Go-to-Market` store listing / ASO items only with *Stores* |
| **`/release-notes`** | `## App Store` (≤ 4000 characters) and `## Google Play` (≤ 500 characters per language) sections only with *Stores* |
| **`/rollout-plan`** | Mobile phased release, minimum supported version and force-update policy with *Stores*; web flags and canary stages otherwise |
| **`/hotfix`** | ios/android path: server-side mitigation first, then a patch from the release tag through expedited store review, with `release-manager` spawned to advise on the store path (a person submits) |
| **`/gate-check`** | Store submission records required at the `launch` gate with *Stores* |
| **`/team-release`** | Records each executed stage in `production/releases/<version>/release-record.md` |

---

## privacy.handles_pii

**Controls:** Whether the product stores or processes personal data — the *PII*
condition

**Values:** `true` | `false`

- **Default:** unset ⇒ ask. **Unset is not `false`** (obligation 2): a product whose
  PII status nobody has stated is never treated as PII-free.
- **Status:** live
- **Local override:** no
- **Label:** `compliance` → `… handles_pii=true (project.yaml)`; an unset value prints `(unset -- ask)` for this part
- **Set by:** `/setup-stack`, `/data-model` (asks first)
- **Read by:** `/gate-check`, `/security-audit`, `/data-model`, `/api-design`, `/brainstorm`, `/architecture-decision`, `/create-architecture`, `/architecture-review`, `/incident`, `/launch-checklist` (*PII* items), `/help` (`when=pii`), `/project-stage-detect` (`when=pii`) (through the `compliance` label)

Almost every consumer product with accounts handles PII (email, phone number,
name). Korean products that run 본인인증 (identity verification) also receive name,
date of birth, phone number and CI/DI values, and payment flows add financial data.
Answer `false` only for products that genuinely store no personal data.

| Skill | Effect when `true` |
|---|---|
| **`/gate-check`** | `docs/security/threat-model.md` required at the `validation` gate (recommended otherwise); every PII field in the data model needs a classification, retention rule and deletion path |
| **`/security-audit`** | The privacy category runs: PII inventory from the data model, consent, retention, erasure, cross-border transfer |
| **`/data-model`** | Classifies each field; sets the key (asking first) when it finds PII the configuration did not declare |

---

## compliance.regions

**Controls:** Which regional legal and accessibility checklists apply — the
*Regions* condition

**Values:** list ⊆ `kr` | `eu` | `us`; `[]` = explicitly none

- **Default:** unset ⇒ ask
- **Status:** live
- **Local override:** no
- **Label:** `compliance` → `compliance: regions=kr,eu handles_pii=true (project.yaml)`; `regions=none` for `[]`; an unset part prints `(unset -- ask)`
- **Set by:** `/setup-stack`
- **Read by:** `/security-audit`, `/release-checklist`, `/launch-checklist`, `/business-rules-check`, `/incident`, `/rollout-plan` (message-consent check of its Communication Plan), `/localize`, `/ux-design`, `/team-growth`, `/team-content`, `/gate-check`, `/help`, `/project-stage-detect`, `/brainstorm`, `/architecture-decision`, `/create-architecture`, `/api-design`, `/data-model` (through the `compliance` label)

Each listed region selects `.claude/docs/compliance/<region>.md` — a **topic
checklist** (what to verify, with the law or standard and where to verify it), not
legal advice and not a source of deadlines, fines or thresholds. A region that is
not listed is never loaded.

**List-enum rules:** each element validated; an invalid one is dropped with a note.
**Set-but-empty is not unset**: `[]` means "we have checked, and no regional
checklist applies" (`regions=none`), while an absent key means nobody has answered
yet (ask). `/settings` validates each element, rejects the whole write if any is
invalid, and writes flow style.

| Region | Topics the checklist covers |
|---|---|
| `kr` | PIPA (개인정보 보호법), ISMS-P applicability, 위치정보법, 전자상거래법, 전자금융거래법 (PG, auto-debit, prepaid points), in-app payment rules, 정보통신망법 advertising-message consent (알림톡 is for informational messages only), KWCAG 2.2; integration notes for Kakao/Naver login, Toss Payments, 본인인증 |
| `eu` | GDPR (lawful basis, DPIA, data-subject requests, transfers), ePrivacy (cookie consent and consent for marketing messages), European Accessibility Act, DSA where applicable |
| `us` | CCPA/CPRA, COPPA (if minors), CAN-SPAM, TCPA, ADA / Section 508, state breach-notification laws, PCI DSS scope for card data |

| Skill | Effect |
|---|---|
| **`/security-audit`** | Runs each listed region's checklist in `full` and `privacy` modes |
| **`/gate-check`** | `launch` gate: each region's items resolved or explicitly accepted; cookie and marketing-message consent implemented where the region requires it |
| **`/team-growth`, `/team-content`** | Consent & channel check before any campaign, push, email, SMS or 알림톡 template is approved; unset ⇒ ask |
| **`/business-rules-check`** | Refund and cancellation rules checked against the `kr` commerce items when `kr` is listed |
| **`/release-checklist`, `/launch-checklist`** | Regions block per listed region |
| **`/ux-design`** | Regional accessibility standard layered on `accessibility.target` (KWCAG 2.2, EAA, ADA/508) |
| **`/incident`** | Loads the listed regions' checklists for breach-notification topics when personal data is involved |

---

## localization.locales

**Controls:** Which locales the product ships in — the *Multi-locale* condition and
the language of customer-facing copy

**Values:** flow list of BCP 47 tags (e.g. `[ko-KR, en-US]`)

- **Default:** unset ⇒ ask
- **Status:** live
- **Local override:** no
- **Label:** — (read from `project.yaml`)
- **Set by:** `/setup-stack`, `/localize`
- **Read by:** `/localize`, `/release-notes`, `/api-design`, `/write-prd`, `/design-language`, `/ux-design`, `/ux-review`, `/launch-checklist` (*Multi-locale* items), `/release-checklist`, `/gate-check` (*Multi-locale*), `/rollout-plan`, `/incident`, `/team-content`, `/team-growth`, `/team-release`, `/help`, `/project-stage-detect`, `/feature-audit` (locale files and key parity), and the DD-CONTENT-VOICE context (the value, or "unset")

*Multi-locale* = `localization.locales` has two or more entries; unset ⇒ ask.

| Skill | Effect |
|---|---|
| **`/localize`** | Extraction, ICU MessageFormat checks and localization QA per locale; `qa` mode writes `production/qa/localization-qa-YYYY-MM-DD.md` |
| **`/gate-check`** | Localization QA report required at the `launch` gate with *Multi-locale* |
| **`/release-notes`** | One block per locale |
| **DD-CONTENT-VOICE** (via `/team-content`) | Voice and terminology reviewed per shipped locale |

Customer-facing copy — release notes, store text, microcopy — is written in the
locales it ships in, whatever the conversation language. Headings, keys and tokens
in artifacts stay English.

---

## accessibility.target

**Controls:** The accessibility conformance level the product commits to — WCAG 2.2
level, with regional standards layered on through `compliance.regions`

**Values:** `none` | `wcag-a` | `wcag-aa` | `wcag-aaa`

- **Default:** unset ⇒ ask. **Unset is not `none`**: `none` is a recorded decision,
  unset is an unanswered question.
- **Status:** live
- **Local override:** no — a product commitment
- **Label:** `accessibility` → `accessibility.target: <value> (project.yaml)` or `accessibility.target: (unset -- ask; unset is not none)`. Resolved through `resolve_setting`: an invalid value is dropped with a note and the unset form printed.
- **Set by:** `/ux-design accessibility` (which writes `design/accessibility-requirements.md` with `> **Target**: <value>` as the first header line)
- **Read by:** `/ux-review`, `/design-language`, `/ux-design`, `/write-prd`, `/qa-plan`, `/team-ui`, `/team-hardening`, `/launch-checklist`, `/gate-check`

---

### Value intent

| Value | Meaning |
|---|---|
| `none` | No conformance target — a deliberate decision, e.g. an internal prototype. Still recorded. |
| `wcag-a` | WCAG 2.2 Level A |
| `wcag-aa` | WCAG 2.2 Level AA — the level most regional accessibility laws and procurement rules reference; check `.claude/docs/compliance/<region>.md` for the standard that applies |
| `wcag-aaa` | WCAG 2.2 Level AAA — rarely achievable product-wide; usually a target for specific flows |

Regional standards come from `compliance.regions`: KWCAG 2.2 (한국형 웹 콘텐츠
접근성 지침) and the mobile app accessibility guideline for `kr`; the European
Accessibility Act for `eu`; ADA / Section 508 for `us`.

---

### Affected skills

| Skill | Effect |
|---|---|
| **`/ux-design accessibility`** | Writes the requirements document: POUR-organized requirement matrix per surface for the chosen level |
| **`/design-language`** | Color contrast and focus styles checked against the target; DD-DESIGN-LANGUAGE receives the resolved line |
| **`/ux-review`, `/team-ui`** | Specs and implementations reviewed against the target |
| **`/team-hardening`** | Accessibility audit (axe, VoiceOver / TalkBack / NVDA passes) against the target |
| **`/launch-checklist`** | Accessibility audit item |
| **`/qa-plan`** | The accessibility row of `## Non-Functional Checks` targets the resolved value; unset ⇒ `NOT DETERMINED — accessibility.target unset` |
| **`/gate-check`** | `validation`: accessibility requirements with the target committed (*UI*); `hardening` / `launch`: compliance verified against the target |

---

## performance.api_p95_ms

**Controls:** The API latency budget — server-side p95 response time, in milliseconds

**Values:** number (milliseconds, p95)

- **Default:** unset
- **Status:** live
- **Local override:** no — a shared SLO target
- **Label:** — (read from `project.yaml`)
- **Set by:** `/create-architecture`, `/settings`
- **Read by:** `/perf-profile`, `/load-test`, `/gate-check`, `/rollout-plan`, `/architecture-review`, `/milestone-review`, `/dev-story`, `/smoke-check` (Batch 4 spot check), `/create-architecture`, `/architecture-decision`, `/create-control-manifest` (Performance Budgets table), `/launch-checklist` (performance item; passed to the sre-engineer consult), `/qa-plan` (`## Non-Functional Checks`), `/team-hardening`, `/walking-skeleton`, `/write-prd` (NFR `### Performance`), `/ux-design` (acceptance criteria), `/adopt` (presence audit)

> **Unset is not zero and not a default.** A budget nobody set is not a budget
> that was met. Every performance reader reports `NOT ASSESSED` for a metric with
> no committed target rather than measuring against a placeholder, and
> `/load-test` asks for its thresholds. The same applies to every
> `performance.*` budget below; `performance.enforce` decides what a breach does.

Typical service targets are 200–500 ms at p95 for read endpoints; payment and
third-party-bound operations are usually budgeted separately in `docs/ops/slo.md`.
`/load-test` uses it as a k6/Locust/Gatling threshold; `/rollout-plan` uses it as a
guardrail with a halt threshold.

---

## performance.error_rate_pct

**Controls:** The API error budget — the percentage of requests that may fail
(server errors)

**Values:** number (percent, e.g. `0.5`)

- **Default:** unset
- **Status:** live
- **Local override:** no
- **Label:** — (read from `project.yaml`)
- **Set by:** `/create-architecture`, `/settings`
- **Read by:** `/perf-profile`, `/load-test`, `/gate-check`, `/rollout-plan`, `/milestone-review`, `/smoke-check` (Batch 4 spot check), `/create-architecture`, `/architecture-decision`, `/create-control-manifest` (Performance Budgets table), `/launch-checklist` (performance item; passed to the sre-engineer consult), `/qa-plan` (`## Non-Functional Checks`), `/team-hardening`, `/walking-skeleton`, `/write-prd` (NFR `### Performance`), `/ux-design` (acceptance criteria), `/adopt` (presence audit)

Used as a `/load-test` threshold and as a `/rollout-plan` guardrail metric whose
breach halts a rollout stage. Unset ⇒ `NOT ASSESSED` (see
`## performance.api_p95_ms`).

---

## performance.availability_pct

**Controls:** The availability SLO target — the percentage of time (or of
successful requests) the service must be available

**Values:** number (percent, e.g. `99.9`)

- **Default:** unset
- **Status:** live
- **Local override:** no
- **Label:** — (read from `project.yaml`)
- **Set by:** `/create-architecture`, `/settings`
- **Read by:** `/create-architecture` (writes `docs/ops/slo.md` `## SLIs & SLOs`), `/perf-profile`, `/gate-check`, `/rollout-plan`, `/milestone-review`, `/architecture-decision`, `/create-control-manifest` (Performance Budgets table), `/launch-checklist` (performance item; passed to the sre-engineer consult), `/qa-plan` (`## Non-Functional Checks`), `/team-hardening`, `/walking-skeleton`, `/write-prd` (NFR `### Performance`), `/ux-design` (acceptance criteria), `/adopt` (presence audit)

`99.9` allows about 43 minutes of downtime per 30 days; `99.95` about 22 minutes.
The error budget policy that goes with it lives in `docs/ops/slo.md`
`## Error Budget Policy`. Unset ⇒ the SLO doc records the SLI without a target and
the gate reports CONCERNS, not a pass.

---

## performance.lcp_ms

**Controls:** The Largest Contentful Paint budget for the web surface, at the 75th
percentile, in milliseconds

**Values:** number (milliseconds, p75)

- **Default:** unset
- **Status:** live
- **Local override:** no
- **Label:** — (read from `project.yaml`)
- **Set by:** `/create-architecture`, `/settings`
- **Read by:** `/perf-profile`, `/gate-check`, `/rollout-plan`, `/dev-story`, `/smoke-check` (Batch 4 spot check), `/create-architecture`, `/architecture-decision`, `/create-control-manifest` (Performance Budgets table), `/launch-checklist` (performance item; passed to the sre-engineer consult), `/qa-plan` (`## Non-Functional Checks`), `/team-hardening`, `/walking-skeleton`, `/write-prd` (NFR `### Performance`), `/ux-design` (acceptance criteria), `/adopt` (presence audit)

Google's published "good" threshold for LCP is 2500 ms at p75
(Source: https://web.dev/articles/vitals). Measure field data (RUM, CrUX) where it
exists; lab runs (Lighthouse) are a proxy and `/perf-profile` labels them as such.
Only meaningful with a `web` surface.

---

## performance.inp_ms

**Controls:** The Interaction to Next Paint budget for the web surface, at the 75th
percentile, in milliseconds

**Values:** number (milliseconds, p75)

- **Default:** unset
- **Status:** live
- **Local override:** no
- **Label:** — (read from `project.yaml`)
- **Set by:** `/create-architecture`, `/settings`
- **Read by:** `/perf-profile`, `/gate-check`, `/rollout-plan`, `/smoke-check` (Batch 4 spot check), `/create-architecture`, `/architecture-decision`, `/create-control-manifest` (Performance Budgets table), `/launch-checklist` (performance item; passed to the sre-engineer consult), `/qa-plan` (`## Non-Functional Checks`), `/team-hardening`, `/walking-skeleton`, `/write-prd` (NFR `### Performance`), `/ux-design` (acceptance criteria), `/adopt` (presence audit)

Google's published "good" threshold for INP is 200 ms at p75
(Source: https://web.dev/articles/vitals). INP needs real interactions — lab tools
approximate it with Total Blocking Time — so `/perf-profile` reports lab-only
results as partial.

---

## performance.cls

**Controls:** The Cumulative Layout Shift budget for the web surface, at the 75th
percentile

**Values:** number (unitless score, p75, e.g. `0.1`)

- **Default:** unset
- **Status:** live
- **Local override:** no
- **Label:** — (read from `project.yaml`)
- **Set by:** `/create-architecture`, `/settings`
- **Read by:** `/perf-profile`, `/gate-check`, `/rollout-plan`, `/smoke-check` (Batch 4 spot check), `/create-architecture`, `/architecture-decision`, `/create-control-manifest` (Performance Budgets table), `/launch-checklist` (performance item; passed to the sre-engineer consult), `/qa-plan` (`## Non-Functional Checks`), `/team-hardening`, `/walking-skeleton`, `/write-prd` (NFR `### Performance`), `/ux-design` (acceptance criteria), `/adopt` (presence audit)

Google's published "good" threshold for CLS is 0.1 at p75
(Source: https://web.dev/articles/vitals). Late-loading banners, web fonts without
size-adjusted fallbacks and images without dimensions are the usual causes — CJK
web fonts in particular, which is why `/design-language` covers font subsetting.

---

## performance.bundle_kb

**Controls:** The JavaScript budget per web route — initial JS, gzip, in kilobytes

**Values:** number (kilobytes, gzip, initial JS per route)

- **Default:** unset
- **Status:** live
- **Local override:** no
- **Label:** — (read from `project.yaml`)
- **Set by:** `/create-architecture`, `/settings`
- **Read by:** `/bundle-audit`, `/perf-profile`, `/gate-check`, `/design-language` (font budget), `/dev-story`, `/create-architecture`, `/architecture-decision`, `/create-control-manifest` (Performance Budgets table), `/launch-checklist` (performance item; passed to the sre-engineer consult), `/qa-plan` (`## Non-Functional Checks`), `/team-hardening`, `/walking-skeleton`, `/write-prd` (NFR `### Performance`), `/ux-design` (acceptance criteria), `/adopt` (presence audit)

`/bundle-audit` measures it per route from the build output (Next.js build stats,
a Vite/webpack bundle analyzer) and also reports CSS, images and fonts — CJK font
subsetting included — against it. Mobile app size is reported by `/bundle-audit`
from the store build, but has no budget key of its own.

---

## performance.cold_start_ms

**Controls:** The mobile cold-start budget — from process start to the first
interactive frame, in milliseconds

**Values:** number (milliseconds)

- **Default:** unset
- **Status:** live
- **Local override:** no
- **Label:** — (read from `project.yaml`)
- **Set by:** `/create-architecture`, `/settings`
- **Read by:** `/perf-profile`, `/gate-check`, `/dev-story`, `/create-architecture`, `/architecture-decision`, `/create-control-manifest` (Performance Budgets table), `/launch-checklist` (performance item; passed to the sre-engineer consult), `/qa-plan` (`## Non-Functional Checks`), `/team-hardening`, `/walking-skeleton`, `/write-prd` (NFR `### Performance`), `/ux-design` (acceptance criteria), `/adopt` (presence audit)

Measured on a mid-range device, not the newest flagship — Korean and US user bases
both include a long tail of older Android devices. Only meaningful with an `ios` or
`android` surface; `/perf-profile` reports it `N/A — <surface> not configured` on a
web-only product.

---

## performance.crash_free_pct

**Controls:** The mobile stability budget — the percentage of sessions without a
crash

**Values:** number (percent of sessions, e.g. `99.5`)

- **Default:** unset
- **Status:** live
- **Local override:** no
- **Label:** — (read from `project.yaml`)
- **Set by:** `/create-architecture`, `/settings`
- **Read by:** `/perf-profile`, `/rollout-plan`, `/gate-check`, `/milestone-review`, `/smoke-check` (Batch 4 spot check), `/create-architecture`, `/architecture-decision`, `/create-control-manifest` (Performance Budgets table), `/launch-checklist` (performance item; passed to the sre-engineer consult), `/qa-plan` (`## Non-Functional Checks`), `/team-hardening`, `/walking-skeleton`, `/write-prd` (NFR `### Performance`), `/ux-design` (acceptance criteria), `/adopt` (presence audit)

Read from the crash reporter (Firebase Crashlytics, Sentry, App Store Connect /
Play Console vitals). `/rollout-plan` uses it as a guardrail for phased release —
a drop below the target halts the next stage — and mobile binaries cannot be rolled
back, so the kill switch or server flag is the rollback path.

---

## performance.enforce

**Controls:** Whether a breach of a `performance.*` budget warns or blocks

**Values:** `warn` | `block` | `off`

- **Default:** `warn` (terminal default)
- **Status:** live
- **Local override:** yes — a stricter local value bites on that developer's machine only; CI runs `project.yaml`
- **Label:** `performance.enforce` → `performance.enforce: <value> (<source>)`
- **Set by:** `/settings`
- **Read by:** `/perf-profile`, `/load-test`, `/bundle-audit`, `/gate-check`, `/team-hardening`, `/rollout-plan`

**Priority chain:** `project.local.yaml` → `project.yaml` → terminal default `warn`,
resolved by `resolve_config` like every other knob — an invalid value falls through
to the default with a note, and the line names its source.

> **Read it from the resolved block, never from `project.yaml` directly.** The key
> is on the local whitelist, so "did this FAIL come from the project or from my own
> `project.local.yaml`?" is exactly the question the resolved line answers.

> **Mirrors the `testing.strict` pattern** for the nine budgets above: the budget
> says what the target is; `performance.enforce` says what missing it does.

---

### Value intent

| Value | Behavior |
|---|---|
| `warn` | A breach is a finding: `/perf-profile` and `/bundle-audit` report CONCERNS; `/load-test` reports FAIL and marks it advisory in its `> **Enforcement**:` line; `/gate-check` surfaces it as CONCERNS, not a blocker |
| `block` | A breach is a failure: the analysis skills report FAIL; `/gate-check` treats it as a blocker at the `hardening` and `launch` gates |
| `off` | Budgets are informational: no breach is scored, and each reader notes that budgets were not scored instead of staying silent (obligation 3) |

---

### Affected skills

| Skill | Effect |
|---|---|
| **`/perf-profile`** | `## Breaches` scored FAIL (`block`) or CONCERNS (`warn`) |
| **`/bundle-audit`** | Route budgets scored the same way |
| **`/load-test`** | Threshold breach → verdict FAIL; the `> **Enforcement**:` line marks it blocking (`block`) or advisory (`warn`); `off` → recorded, not scored |
| **`/gate-check`** | "Performance within budgets" at `hardening`: blocker (`block`), CONCERNS (`warn`), skipped with a note (`off`) |
| **`/team-hardening`** | `## Performance` section verdict |
| **`/rollout-plan`** | Whether a guardrail breach during a stage is an automatic halt or a decision for the stage owner |

---

## cadence.sprint_length and cadence.milestone_length

> ### RESERVED - NOT IMPLEMENTED
>
> **No skill or hook reads this setting. Setting it has no effect.** Everything
> below describes the intended design, not current behaviour.
>
> No reference anywhere outside this file.

**Controls:** Default sprint and milestone durations for planning

**Values:** strings — intended `cadence.sprint_length` ∈ `1w`, `2w`, `3w`, `4w`, `none`; `cadence.milestone_length` ∈ `4w`, `6w`, `8w`, `12w`

- **Default:** unset
- **Status:** RESERVED
- **Local override:** no
- **Label:** —
- **Set by:** —
- **Read by:** none

**Intended design.** `/sprint-plan` would size capacity as sprint length × velocity;
`none` would mean continuous flow (kanban) with weekly velocity; `/milestone-review`
would scope its window to the milestone length; `/sprint-status` would span the
burn-down over the sprint length; `/retrospective` would fire at the sprint cadence.

---

## commands

**Controls:** The exact shell commands to install, run, build, test and check the
product — so skills execute what the project really uses instead of guessing

**Values:** each field is a string, or an OS map with keys `default` / `linux` / `macos` / `windows`

- **Default:** unset — asked, never guessed
- **Status:** live
- **Local override:** no — build and test commands are project facts; OS differences go in the OS map
- **Label:** — (read from `project.yaml`)
- **Set by:** `/setup-stack`, `/test-setup` (`test`, `e2e`, `lint`, `typecheck`), `/settings`
- **Read by:** `/dev-story` (`run`, `dev`, `install`, `test`, `typecheck`, `lint`, `migrate`), `/walking-skeleton` (`install`, `run`, `build`, `test`, `typecheck`, `e2e`, `migrate`), `/smoke-check` (`build`, `test`, `e2e`, `smoke`, `run`, `dev`), `/test-setup` (`install`, `dev`, `run`, `test`, `e2e`, `lint`, `typecheck`), `/gate-check` (`test`, `e2e`), `/story-done` (`test`), `/hotfix` (`test`, `smoke`), `/team-feature` and `/team-hardening` (`test`, `e2e`), `/regression-suite` (`test`, `e2e` — named, not run), `/bundle-audit` (`build`), `/api-design` (`api_lint`), `/data-model` (`migrate`), `/load-test` (`load_test`), `/adopt` (`api_lint`; presence audit of `test`, `e2e`, `lint`, `typecheck`), `/bug-report` (`test`, verify mode), `/perf-profile` (`run`, `build`, `test` — passed to performance-engineer), `/security-audit` (`run`, `dev` — how to start a local target for the header check), `project-coherence.sh` (every command that names a package script must exist in the relevant `package.json`)

---

### Fields

| Field | Purpose | Main reader |
|---|---|---|
| `install` | Install dependencies from the lockfile | — (onboarding, CI) |
| `dev` | Start the local development servers | `/dev-story` run-and-observe (fallback for `run`) |
| `run` | Start the app so a story can be observed | `/dev-story` Phase 6 run-and-observe (`.claude/docs/run-and-observe.md`) |
| `build` | Production build | `/smoke-check` batch 1, `/bundle-audit` (per-route sizes) |
| `test` | Unit and integration suites | `/dev-story`, `/smoke-check`, `/gate-check` (test suite passing) |
| `e2e` | End-to-end suite (the smoke tag selects critical journeys) | `/smoke-check` batch 2 |
| `lint` | Linters | CI, `/dev-story` |
| `typecheck` | Type checking (`tsc --noEmit`, mypy, …) | `/dev-story` |
| `api_lint` | Contract linting (Spectral, Redocly) | `/api-design` |
| `migrate` | Apply migrations — dry runs only, against a disposable database | `/data-model`, `/dev-story` (migration dry-run) |
| `smoke` | Minimal "does it boot and answer?" check | `/smoke-check` |
| `load_test` | Load-test runner (k6, Locust, Gatling) | `/load-test` (runs only when set and confirmed) |
| `deploy_preview` | Deploy a **preview** environment — never production | — (humans; allowed locally, see `settings-local-template.md`) |

**Simple form** — one command used on every OS (Moa, a pnpm + Turborepo monorepo):

```yaml
commands:
  install: pnpm install --frozen-lockfile
  dev: pnpm turbo run dev
  run: pnpm --filter web start
  build: pnpm turbo run build
  test: pnpm turbo run test
  e2e: pnpm exec playwright test
  lint: pnpm turbo run lint
  typecheck: pnpm turbo run typecheck
  api_lint: pnpm exec redocly lint docs/api/openapi.yaml
  migrate: pnpm --filter api exec prisma migrate deploy   # against a disposable DATABASE_URL only
  smoke: pnpm exec playwright test --grep @smoke
  load_test: k6 run tests/load/load.js
  deploy_preview: vercel deploy
```

**OS-aware form** — different commands per OS:

```yaml
commands:
  test:
    default: ./gradlew test
    windows: gradlew.bat test
```

**Resolution rule:** a string is used as-is on every OS. A map is read for the
current OS key (`linux`, `macos`, `windows`), falling back to `default`. The
OS-specific keys live inside the locked file — they are not a local override.

> **`run` and `build` are asked, never guessed.** A wrong guess either fails
> loudly or — worse — succeeds while building or starting the wrong app in a
> multi-app workspace. With no command, readers say `NOT CHECKED` or
> `Run result: NOT VERIFIED — <reason>`.

> **Production deploys are never a command here.** `deploy_preview` targets a
> preview environment; the shared `.claude/settings.json` denies production deploy,
> IaC apply and destructive database commands, and agents never run them — a
> human does, after the rollout plan says so.

---

### Affected skills

| Skill | How `commands` is used |
|---|---|
| **`/dev-story`** | Runs `test` / `typecheck` as the build check, then `run` (or `dev`) to observe the story and retain evidence |
| **`/smoke-check`** | Batch 1 `build` + start + health endpoint; batch 2 critical journeys via `e2e` (smoke tag) or `smoke`; the report names the environment |
| **`/api-design`** | Runs `api_lint` on the contract |
| **`/data-model`** | Runs `migrate` as a dry run against a disposable database — never a shared one |
| **`/load-test`** | Runs `load_test` against staging only (production targets are refused) |
| **`/bundle-audit`** | Runs `build` (announced first) and measures per-route JS/CSS from the production build; unset ⇒ every route row `NOT ASSESSED — commands.build unset` |
| **`/gate-check`** | "Test suite passing" runs `test` via Bash when set; otherwise `NOT ASSESSED` |
| **`/regression-suite`** | Names the commands but cannot execute them — its tools have no Bash; coverage there means "a test file exists", never "a test passed" |
| **`validate-push.sh`** | Does **not** read `commands.*`; it warns on protected branches and reminds about migrations |

---

## naming

**Controls:** Naming conventions for code, API, database, environment and analytics
identifiers

**Values:** each field is a string convention (`kebab-case`, `PascalCase`, `camelCase`, `snake_case`, `SCREAMING_SNAKE`, `object_action`, …)

- **Default:** unset
- **Status:** live
- **Local override:** no — conventions are shared
- **Label:** — (read from `project.yaml`)
- **Set by:** `/setup-stack`
- **Read by:** `/dev-story`, `/create-control-manifest`, `/api-design`, `/data-model`, `/write-prd`, `/ux-design`, `/ux-review`, `/prd-review` (`naming.events`), `/architecture-review`, `/adopt`, `/bundle-audit`, `/walking-skeleton`, `/test-helpers`, `/test-setup`

> **Guidance, not a gate.** The conventions reach the code by being passed into
> briefs, manifests and contracts. No hook validates code against them;
> `/adopt` audits conformance. If you need enforcement, configure your linters
> (ESLint naming rules, ktlint, SwiftLint, Ruff) — the CI `lint` command is where it
> belongs.

---

### Fields

| Field | Governs | Typical value (TypeScript web + Node API) |
|---|---|---|
| `files` | Source file names | `kebab-case` (`goal-card.tsx`) |
| `components` | UI component names | `PascalCase` (`GoalCard`) |
| `classes` | Classes, types | `PascalCase` |
| `variables` | Variables, functions | `camelCase` |
| `constants` | Constants | `SCREAMING_SNAKE` |
| `api_paths` | REST path segments | `kebab-case`, plural resources (`/v1/savings-goals`) |
| `api_fields` | JSON field names | `camelCase` (or `snake_case` — pick one per API) |
| `db_tables` | Tables | `snake_case`, plural (`savings_goals`) |
| `db_columns` | Columns | `snake_case` |
| `env_vars` | Environment variables | `SCREAMING_SNAKE` (`TOSS_SECRET_KEY`) |
| `events` | Analytics event names | `object_action` (`goal_created`, `payment_failed`) |

Other ecosystems differ: Kotlin and Swift files follow their type names
(`PascalCase`), Python uses `snake_case` files and functions, Dart uses
`snake_case` files and `lowerCamelCase` members.

---

### Affected skills

| Skill | How naming is used |
|---|---|
| **`/dev-story`** | Passes the conventions to the engineer in the implementation brief |
| **`/create-control-manifest`** | Emits them as manifest rules |
| **`/api-design`** | `api_paths` and `api_fields` in the guidelines and contract |
| **`/data-model`** | `db_tables` and `db_columns` in the model and migrations |
| **`/bundle-audit`** | Static-asset naming |
| **`/adopt`** | Audits existing code against them |

`events` also governs the tracking plan (`design/product/tracking-plan.md`) that
`/write-prd` appends to.

---

## features.session_state

**Controls:** Whether the session-state pipeline runs — the checkpoint file, session
archive, compaction log, agent audit log and status-line breadcrumb

**Values:** `on` | `off`

- **Default:** enabled unless the value is the literal `off` (no terminal-default entry: `session_state_enabled()` returns disabled only on `off`)
- **Status:** live
- **Local override:** yes
- **Label:** — (hooks read it directly)
- **Set by:** `/settings`
- **Read by:** the session hooks and `statusline.sh`, through `session_state_enabled()` in `yaml-helper.sh`, which reads the **top-level `features:` block** with awk (`project.local.yaml` first, then `project.yaml`); any skill that writes to `production/session-state/`

> **What ships:** `production/session-state/active.md` is the session checkpoint.
> Its `<!-- STATUS -->` … `<!-- /STATUS -->` block carries the `Epic:` /
> `Feature:` / `Task:` breadcrumb the status line parses, and its
> `<!-- CHECKPOINT -->` region is what `session-start.sh` and `pre-compact.sh`
> preview. Read it first after any compaction, crash or `/clear`.

> **The default is on, deliberately.** `.claude/docs/context-management.md` tells
> you to rely on `active.md` as your crash-recovery checkpoint, so defaulting this
> off would quietly take away recovery, the session archive and the agent audit
> log. The ~2–5k tokens per session are an explicit opt-out
> (`/settings features.session_state=off`), never a silent default.

> **`features:` must be a top-level block.** The hooks read it with awk, not the
> YAML parser; nested anywhere else it is never seen.

> **`session-start.sh` is gated per block, not at the top.** Its git, sprint,
> milestone and bug context is not part of the pipeline; only the `active.md`
> recovery preview is gated. The check fails OPEN — an unavailable helper must
> never suppress the recovery checkpoint invisibly.

---

### Value intent

| Value | Intent |
|---|---|
| `on` | Full session tracking: `active.md` checkpoint, archive on session stop, compaction log, agent audit log, status-line breadcrumb. Adds ~2,000–5,000 tokens per session start and ~1,000–6,000 per compaction. |
| `off` | Recovery through skeleton-first output files: long-form skills write the full heading skeleton of their output before discussing sections, so a cleared session resumes from the file itself. No state file, no logs. |

---

### Hook behavior

The flag is checked inside each hook — the harness always fires the hook, and the
hook decides whether to act.

| Hook | `off` | `on` |
|---|---|---|
| **`session-start.sh`** | Runs (git, sprint, milestone, bugs, stack check) — skips the `active.md` preview | Runs fully, including the `active.md` preview |
| **`detect-gaps.sh`** | Runs unchanged — gap detection is independent of session state | Runs unchanged |
| **`pre-compact.sh`** | Emits "read the skeleton files and relevant docs to resume" — no state dump, no WIP scan, no compaction-log append | Dumps `active.md`, git diff and the WIP scan; appends the compaction log |
| **`post-compact.sh`** | No-op | Reminds the agent to re-read `active.md` |
| **`session-stop.sh`** | No-op | Archives `active.md` to the session log when its content hash changed; appends commits |
| **`log-agent.sh`**, **`log-agent-stop.sh`** | No-op | Append `Agent invoked:` / `Agent completed:` lines to the agent audit log |

---

### File existence by mode

| File | `off` | `on` |
|---|---|---|
| `production/session-state/active.md` | Not maintained | Written by skills and the agent; read by hooks and the status line |
| `production/session-logs/session-log.md` | Not written | Append-only archive of each changed `active.md` |
| `production/session-logs/compaction-log.txt` | Not written | Append-only log of compaction events |
| `production/session-logs/agent-audit.log` | Not written | `TS \| session \| Agent invoked: <agent_type>` / `Agent completed: <agent_type>` lines |

Both directories are gitignored (`production/session-state/.gitkeep` excepted):
nothing in them is ever evidence.

---

### Status line behavior

`statusline.sh` prints `ctx% | model | stage · rigor | Epic > Feature > Task`.

| Part | `off` | `on` |
|---|---|---|
| Context %, model | Always shown | Always shown |
| Stage | Always shown — `STAGE` from `stage-estimate.sh --quick` | Same |
| Rigor | Always shown — `minimal` when unset | Same |
| Epic > Feature > Task | Not shown | Parsed from the STATUS block of `active.md`, shown when the stage is `Build`, `Hardening` or `Launch` |

---

### Affected skills

When `off`, skills that would infer a missing argument from the checkpoint ask for
it instead — they never fail silently:

| Skill | Infers from `active.md` when `on` | When `off` |
|---|---|---|
| **`/dev-story`** | The active story path | Asks for the story path |
| **`/story-done`** | The in-progress story path | Asks for the story path |
| **`/team-release`** | The target version | Asks for the version |
| **`/team-qa`** | The active sprint | Asks for the sprint |
| **`/help`** | Current task and STATUS block | Answers from sprint and epic files only |

Long-form authoring skills write their output's heading skeleton before section
discussion either way (for example, `/write-prd` writes the PRD skeleton with the
exact headings of `.claude/docs/templates/prd.md`), which is what makes `off` a
workable recovery mode.

---

### Token cost summary

| Scenario | `off` | `on` |
|---|---|---|
| Per session start | ~500 tokens (git/sprint context) | ~2,000–5,000 tokens (+ checkpoint preview) |
| Per compaction | ~200 tokens (reminder) | ~1,000–6,000 tokens (checkpoint + git diff + WIP scan) |
| Per session end | 0 | File I/O only |
| Recovery after `/clear` | Read the skeleton + 2–3 docs (~1,000–3,000 tokens) | Read `active.md` (~200–500 tokens) |

The `off` recovery cost is paid only when recovery is needed; the `on`
session-start cost is paid every session.

---

## features.token_budget_warn_at

> ### RESERVED - NOT IMPLEMENTED
>
> **No skill or hook reads this setting. Setting it has no effect.** Everything
> below describes the intended design, not current behaviour.
>
> The value is stored when you set it, and then ignored. Nothing warns at any
> threshold.

**Controls:** The context-usage threshold at which session warnings would fire

**Values:** float between 0.0 and 1.0

- **Default:** unset
- **Status:** RESERVED
- **Local override:** yes — a personal cost threshold
- **Label:** —
- **Set by:** —
- **Read by:** none

**Intended design.** At or above the threshold, `statusline.sh` would show context
usage in yellow and the next session start would note "Last session reached [X]%
context — consider /clear". Red at 90% regardless of the value; `1.0` would disable
the warning.

---

## schema_version

**Controls:** Which version of the `project.yaml` schema the file conforms to

**Values:** integer

- **Default:** `1`
- **Status:** live
- **Local override:** no — file metadata, **exempt** from the local-scope report (a `project.local.yaml` carrying `schema_version: 1` is correct as written)
- **Label:** —
- **Set by:** the template
- **Read by:** `yaml-helper.sh`, `session-start.sh`

The schema is `1`. A future change to key names or structure bumps it, so a reader
can tell which schema a file was written for instead of misreading it. Never edit it
by hand.

---

## framework

**Controls:** Which Claude Code Service Studios release created or last upgraded this
project

**Values:** `framework.version` → semver string; `framework.last_upgraded` → ISO date

| Key | Default | Status | Local override | Label | Set by | Read by |
|---|---|---|---|---|---|---|
| `framework.version` | the template value — see `project.yaml` | live | no (metadata; exempt from the local-scope report) | — | the template; the steps in `UPGRADING.md` | `session-start.sh`, `/adopt`, `/settings` |
| `framework.last_upgraded` | `2026-09-27` | live | no (metadata) | — | the template | `/settings` |

File metadata, not a behavioral setting: `/settings` displays both fields; `/adopt`
and `session-start.sh` read the version to identify the framework release in use.
The version literal lives only in `project.yaml` — every other framework file reads
it from there.

---

## Complete example `project.yaml`

A configured `project.yaml` for **Moa** — a B2C subscription savings app for the
Korean market (web + iOS + Android + API). The stack block is the reference shape
`/setup-stack` writes. **Version numbers in this example are illustrative
placeholders** — real values are pinned from live sources by `/setup-stack` and
recorded in `docs/stack-reference/VERSION.md`.

```yaml
stack:
  pinned_on: 2026-09-27
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
    mobile:
      framework: React Native (Expo)
      version: "0.79"
      language: TypeScript
      root: apps/mobile
    backend:
      framework: NestJS
      version: "11.0"
      language: TypeScript
      runtime: Node.js 22
      root: [apps/api, services/worker]
    data:
      database: PostgreSQL 16
      cache: Redis 7
      queue: none
      orm: Prisma 6
      migrations_dir: apps/api/prisma/migrations
    cloud:
      provider: AWS
      iac: Terraform 1.9
      root: infra
platform:
  surfaces: [web, ios, android, api]
release:
  distribution: web+stores
privacy:
  handles_pii: true
compliance:
  regions: [kr]
localization:
  locales: [ko-KR, en-US]
```

The rest of the same file. `schema_version` and `framework` come from the template
(see `project.yaml`). Performance budgets are illustrative too.

```yaml
project:
  name: Moa
  category: B2C fintech
  version: 1.2.0
  stage: Build

# /start writes exactly these two modes. The six knobs modes.rigor fronts —
# review_mode, workflow, docs.density, qa.level, story_granularity, team.size —
# are deliberately absent: a value here pins the knob for the whole team and
# shadows the rigor expansion. Pin one only on purpose, with /settings.
modes:
  rigor: standard
  automation: guided

# TOP LEVEL — a sibling of modes:, never nested under it.
workflow_overrides:
  config_flags: true           # every PRD states its flags, even at standard
  feature_overrides:
    payments: full             # design/prd/payments.md
    admin-console: minimal     # design/prd/admin-console.md

testing:
  framework: vitest+playwright
  patterns: [apps/*/src/**/*.test.ts, tests/**]
  strict:
    logic: true
    integration: true
    e2e: true

accessibility:
  target: wcag-aa

performance:
  api_p95_ms: 300
  error_rate_pct: 0.5
  availability_pct: 99.9
  lcp_ms: 2500
  inp_ms: 200
  cls: 0.1
  bundle_kb: 170
  cold_start_ms: 2000
  crash_free_pct: 99.5
  enforce: warn

naming:
  files: kebab-case
  components: PascalCase
  classes: PascalCase
  variables: camelCase
  constants: SCREAMING_SNAKE
  api_paths: kebab-case
  api_fields: camelCase
  db_tables: snake_case
  db_columns: snake_case
  env_vars: SCREAMING_SNAKE
  events: object_action

commands:
  install: pnpm install --frozen-lockfile
  run: pnpm --filter web start
  build: pnpm turbo run build
  test: pnpm turbo run test
  e2e: pnpm exec playwright test
  lint: pnpm turbo run lint
  typecheck: pnpm turbo run typecheck
  api_lint: pnpm exec redocly lint docs/api/openapi.yaml
  migrate: pnpm --filter api exec prisma migrate deploy
  load_test: k6 run tests/load/load.js
  deploy_preview: vercel deploy

features:
  session_state: on
```

And a sparse `project.local.yaml` — one developer who works autonomously, skips
director reviews and keeps unit-test failures advisory on WIP commits:

```yaml
# project.local.yaml — per-developer overrides (gitignored)
modes:
  automation: autonomous
  review_mode: solo
testing:
  strict:
    logic: false
```

Only whitelisted keys belong here; everything else cascades from `project.yaml`.
See § Local Override Pattern for the whitelist.
