---
name: settings
description: "View or change project config — effective merged values, or local overrides in project.local.yaml."
argument-hint: "[key | key=value | --local key=value]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, AskUserQuestion
model: sonnet
---

# /settings — view or change project config

Manages `project.yaml` (team-wide config, committed) and `project.local.yaml`
(per-developer overrides, gitignored). Use this skill to inspect the effective
settings or change them without hand-editing YAML. It writes **only** these two
files, and only the key the user asked to change.

`/settings` is the **only** skill that writes `modes.review_mode`. Every other
skill that uses it resolves it; none writes it.

**Always collaborative.** `/settings` ignores `modes.automation`: it changes the
automation settings themselves, so every write is shown and approved in every
mode (`.claude/docs/automation-modes.md`, exemptions table). It does not resolve
`modes.automation` and has no bootstrap block — it reads configuration through
`yaml-helper.sh` at run time.

## Phase 0: Parse Arguments

Determine which of the four forms the user invoked:

| Form | Mode |
|------|------|
| `/settings` (no args) | **View-all** (Phase 2) |
| `/settings <key>` (single arg, no `=`) | **View-one** (Phase 3) |
| `/settings <key>=<value>` (single arg with `=`) | **Set-yaml** (Phase 4) |
| `/settings --local <key>=<value>` (`--local` prefix) | **Set-local** (Phase 5) |

For Set-yaml and Set-local, `<key>` is a dotted YAML path (e.g.
`modes.review_mode`, `testing.strict.e2e`, `platform.surfaces`) and `<value>` is
the new value. A list value may be given as `a,b` or `[a, b]` (e.g.
`platform.surfaces=web,ios,api`).

**Empty-operand validation:** After splitting the `key=value` operand on the
**first** `=`, if either `<key>` or `<value>` is empty, this is malformed — route
to Phase 6 (usage) rather than attempting the write. The rule applies in both
Set-yaml and Set-local routing: for `--local`, strip the `--local` token first,
then check the remaining operand the same way (so `/settings --local =foo` and
`/settings --local key=` both go to Phase 6). `[]` is a non-empty value (see
Phase 4 step 1b).

Anything else that doesn't match the four forms above → Phase 6 (usage).

## Phase 1: Load Helper

Every subcommand needs `.claude/hooks/yaml-helper.sh`. Shell functions do not
survive between separate Bash calls, so source the helper **in the same Bash
command** as each function you call:

```bash
source "${CLAUDE_PROJECT_DIR:-.}/.claude/hooks/yaml-helper.sh" && resolve_setting modes.rigor
```

If `.claude/hooks/yaml-helper.sh` is missing, this is not a Claude Code Service
Studios project. Report the error and exit.

The functions this skill uses: `resolve_setting`, `resolve_config`, `get_yaml_key`,
`get_yaml_array`, `is_locally_overridable`, `validate_enum_value`,
`validate_yaml_enum`, `validate_local_scope`.

Show every effective scalar value with `resolve_setting <key>` — **never**
`get_effective_yaml_key` or `get_effective_yaml_array`. Those wrappers read
`project.local.yaml` only for whitelisted keys and do **no** enum validation and
no provenance, so an invalid value would be displayed as if it were in effect.

## Phase 1b: Reserved-setting detection

Some settings are fully documented, validated and settable, and **no skill or hook
reads them** — setting one changes nothing. **This skill must say so.** Returning
an ordinary success lets a user reasonably believe the behaviour the setting
describes is now enforced — a quality floor that no gate ever checks is the typical
case. (The keys are not named here on purpose; see the note below.) The banner
exists only in `.claude/docs/effects-map.md`, which someone configuring their
project will rarely open. A setting that does nothing must never look exactly like
one that works — `.claude/rules/skill-authoring.md` obligation 3.

Derive the set; do not hardcode it (obligation 5):

```bash
grep -B14 '^> ### RESERVED' .claude/docs/effects-map.md | grep -E '^## '
```

**Match the banner HEADING (`> ### RESERVED`), never the bare word "RESERVED".**
The effects-map introduction *mentions* the banner in prose to explain the
convention. A looser match re-reports a working setting as dead — the direction
that understates what the framework does — and a reserved set has to be right in
both directions: no live setting marked reserved, no reserved setting shown as live.

A heading may name **two keys joined by " and "** — split on that separator so both
are captured, or the second one silently escapes the set. Let `RESERVED_SET` be the
result.

> Deliberately phrased without naming those keys. Any reader audit that greps
> skill files for a key's name would count `/settings` as a reader of settings
> nothing reads, and "RESERVED — nothing reads it" would stop being true. Spelling
> a dead path out while explaining why not to use it trips the same wire. Reword
> instead of adding an exemption: the strictness is the point, so do not
> re-introduce the literal names to make an example clearer.

Never refuse a write to a reserved key. Storing the value a user intends is
legitimate; storing it *silently* is the defect.

## Phase 2: View-all Mode

(when no arguments)

1. Confirm `project.yaml` exists. If missing, report:
   > "No `project.yaml` found — run `/start` to create one."
   And exit.

2. Check if `project.local.yaml` exists.

3. **Validate.** Run `validate_yaml_enum project.yaml` and capture any errors. If
   `project.local.yaml` exists, also run `validate_yaml_enum project.local.yaml`
   and `validate_local_scope project.local.yaml` (the second names keys that are
   not locally overridable and are therefore ignored). Tag each error with its
   source file so the user can tell them apart. List-enum keys
   (`platform.surfaces`, `compliance.regions`) are validated element by element:
   an invalid element is reported, and resolution drops it while keeping the rest.
   `validate_yaml_enum` prints those array errors itself —
   `platform.surfaces: dropped invalid element '<x>' (expected: ...)` and
   `platform.surfaces: [] is not valid (at least one element is required) — treated as unset`
   — so show its output verbatim; do not re-derive or reword it.

4. **Enumerate leaves.** Use the `Read` tool to read both YAML files as text. Walk
   through each file's structure and collect every leaf key into a deduplicated
   list of dotted paths. A leaf is a `key: value` line whose value is non-empty (a
   scalar or a flow list `[a, b]`), or a key whose children are block-list items
   (`- a` lines) — NOT a parent block that introduces a nested map. Maintain
   insertion order per file; merge by appending leaves from `project.local.yaml`
   that aren't already present from `project.yaml`. The resulting list is the set
   of leaves to display.

   **Then append the rigor family** — `modes.rigor`, `modes.workflow`,
   `docs.density`, `qa.level`, `modes.story_granularity`, `modes.review_mode`,
   `team.size` — for any of the seven the merged list does not already contain.
   These are normally leaves of neither file: `modes.rigor` has a terminal default
   and the other six are supplied by the rigor expansion (`modes.review_mode` and
   `team.size` may also appear as file leaves when set locally, but must still be
   appended so their *derived* value shows). Enumerating only file leaves would
   hide exactly the settings a user just chose, in the one view meant to show them.

5. **For each leaf**, perform three reads and one check:
   - **Scalar leaf:** `resolve_setting <path>` → `<value>`, TAB, `<source>`. This
     walks the whole chain (`project.local.yaml` for whitelisted keys →
     `project.yaml` → `rigor` expansion → default), so it is the only read that
     can report a derived value or name what supplied it.
   - **List leaf:** `get_yaml_array <file> <path>` — from `project.local.yaml`
     when the key is locally overridable and set there, else from `project.yaml`.
     Display it in flow style `[a, b]`; a literal `[]` displays as `[]` (for
     `compliance.regions` it means "explicitly none"). For a list-enum key,
     remove invalid elements from the displayed value (check each with
     `validate_enum_value <path> <element>`) and name them in the annotation.
   - `get_yaml_key project.yaml <path>` (or `get_yaml_array` for a list) →
     yaml-only value (needed only to show what a local override is shadowing)
   - `is_locally_overridable <path>` → 0 (overridable) or 1 (locked)

   Compute the **source annotation** from `<source>`:

   | `<source>` | Annotation |
   |---|---|
   | `project.local.yaml`, yaml-only value non-empty | `(LOCAL OVERRIDE — yaml has: <yamlvalue>)` |
   | `project.local.yaml`, yaml-only value empty | `(project.local.yaml)` |
   | `project.yaml` | `(project.yaml)` |
   | `rigor:<level>` | `(derived from rigor: <level>)` |
   | `default` | `(default)` |
   | `unset` | skip the leaf (don't print unset keys) |

   Append `, locked` to the annotation when `is_locally_overridable` returned 1.
   Append `, dropped: <elements>` when list-enum validation removed elements.

   **Append `, reserved` when the leaf is in `RESERVED_SET` (Phase 1b)**, and print
   this line with the legend below the block:

   ```
   reserved = stored and validated, but nothing reads it. Setting it changes
   no behaviour today.
   ```

   > **All four phases must carry the reserved marking — view-one, view-all, and
   > both write paths.** Marking view-one and the writes while leaving view-all —
   > **the most-used form of this skill** — unmarked means a user who set a
   > reserved key sees it listed beside working settings with an ordinary
   > `(project.yaml)` annotation, in the view most people actually run. Guard all
   > four: view-one and view-all are twins in exactly the way the two write paths
   > are.

6. **Print**, grouped by top-level section (`project`, `modes`, `docs`, `qa`,
   `team`, `stack`, `platform`, etc.) in the order leaves first appeared. The
   grouping is determined by the dotted path, not by which file the leaf came
   from — e.g. `modes.automation` groups under `modes:` even if only
   `project.local.yaml` defines it. Within each section, indent leaves by 2
   spaces; nest further for sub-blocks (e.g. `testing.strict.*`,
   `stack.layers.web.*`). Example output (a configured Moa project; groups
   abbreviated with `…`):

```
project.yaml: present
project.local.yaml: present

Schema validation: ok

Effective config:

project:
  name: Moa                     (project.yaml, locked)
  category: B2C fintech         (project.yaml, locked)
  stage: Build                  (project.yaml, locked)

modes:
  rigor: standard               (project.yaml, locked)
  automation: guided            (LOCAL OVERRIDE — yaml has: collaborative)
  review_mode: solo             (project.local.yaml)
  workflow: standard            (derived from rigor: standard, locked)
  story_granularity: balanced   (derived from rigor: standard, locked)

docs:
  density: terse                (project.yaml, locked)

qa:
  level: standard               (derived from rigor: standard, locked)

team:
  size: individual              (derived from rigor: standard)

platform:
  surfaces: [web, ios, android, api]   (project.yaml, locked)

compliance:
  regions: [kr]                 (project.yaml, locked)

testing:
  strict:
    logic: false                (LOCAL OVERRIDE — yaml has: true)
    e2e: true                   (project.yaml)

stack: …

locked = cannot be overridden in project.local.yaml (project-wide setting).
It does NOT mean fixed: a derived value can still be set explicitly with
/settings <key>=<value>, and an explicit value wins over rigor.
```

Print that two-line legend after the config block whenever any rendered line
carries `locked`. Without it users read `locked` as "immutable" and conclude a
rigor-derived knob cannot be changed — the opposite of what Phase 3's view-one
tells them for the same knob ("an explicit value wins over rigor"). The two views
must not leave contradictory impressions of the same knob's mutability.

The `docs.density` line above is the precedence rule made visible: an explicit
`project.yaml` value keeps winning over the level `rigor` would otherwise derive,
so "comprehensive but compact" stays expressible.

If schema errors exist, print them before the effective config block, verbatim
from the helper, in this form (`validate_yaml_enum` lines carry the `[file]` tag;
`validate_local_scope` lines already name their file and are printed as-is):

```
Schema validation: ERRORS
  [project.yaml] modes.review_mode: 'chaotic' is not a valid value (expected: full|lean|solo)
  [project.yaml] platform.surfaces: dropped invalid element 'iso' (expected: web|ios|android|api)
  project.local.yaml: `release.distribution` is not locally overridable — ignored, not applied. Move it to project.yaml (or delete it); see the whitelist in yaml-helper.sh.
```

7. **Print what skills receive.** Run `resolve_config` (no arguments — the full
   form) and print its output verbatim under the heading `What skills receive:`.
   It is exactly the block every skill's bootstrap resolves, including the derived
   lines no single leaf shows — the `stack` line with its specialist routing, the
   `surfaces`, `compliance`, `accessibility` and `release.distribution` lines with
   their "unset -- ask" forms — and its `notes:` line names every value resolution
   rejected or dropped. That line is never silent: `notes: none` when nothing was
   rejected.

## Phase 3: View-one Mode

(when single arg, no `=`)

**If `<key>` is in `RESERVED_SET`, print this BEFORE the value block** — above,
not below. A caveat under a value reads as a footnote on a working setting:

> **`<key>` is RESERVED — nothing reads it.** The value below is stored and
> validated; it changes no behaviour today.

Let `<key>` be the argument. Perform four reads (for a list-valued key, use
`get_yaml_array` in place of `get_yaml_key`, and take the effective value from the
first file that sets it, `project.local.yaml` first only when the key is locally
overridable):

1. `resolve_setting <key>` → `<value>`, TAB, `<source>` (effective value + provenance)
2. `get_yaml_key project.yaml <key>` → yaml-only value
3. `get_yaml_key project.local.yaml <key>` → local-only value (skip if file absent)
4. `is_locally_overridable <key>` → 0 (overridable) or 1 (locked)

Determine the **source** from `<source>` (same table as Phase 2 step 5) and the
**Locally overridden** status:
- `yes` if the local-only value is non-empty
- `no` otherwise

Print:

```
<key>

  Effective value: <effective-value or "(not set)" if <source> is unset>
  Source: <project.yaml | project.local.yaml | project.local.yaml (overrides project.yaml) | derived from rigor: <level> | default>
  Locally overridden: <yes | no>
  Whitelist: <"can be locally overridden" if is_locally_overridable returned 0, else "locked — project-wide">
```

When both files set the key (the LOCAL OVERRIDE case), add two more lines under
Source:

```
  project.yaml value: <yamlvalue>
  project.local.yaml value: <localvalue>
```

When `<source>` is `rigor:<level>`, add one line under Source so the user knows the
value is settable and how:

```
  Set explicitly with: /settings <key>=<value>   (an explicit value wins over rigor)
```

When a file holds a value that validation rejects (an enum-invalid scalar, or
invalid elements of a list-enum key), add one line so the user sees why the
effective value differs from the file:

```
  Rejected: <value or elements> (expected: <allowed values>)
```

When the effective value is empty (key not set anywhere), print just:

```
<key>

  Effective value: (not set)
  Locally overridden: no
  Whitelist: <"can be locally overridden" | "locked — project-wide">
```

## Phase 4: Set-yaml Mode

(when `<key>=<value>`, no `--local`)

1. **Schema validation**: call `validate_enum_value <key> <value>`. For a
   list-enum key (`platform.surfaces`, `compliance.regions`) it accepts `a,b` or
   `[a, b]`, validates **each element**, and rejects the whole write if any element
   is invalid. If it returns 1, the stderr line is shown to the user verbatim
   (`Invalid value '<value>' for '<key>'. Allowed: ...`) and the skill exits
   without writing. If it returns 0, the value is either valid or the key has no
   enum constraint — proceed.

1b. **List values.** A list is always written in flow style `[a, b]` (elements
   separated by `, `). Treat the value as a list when it is given as `[...]`, or
   when the key is list-valued — the two list-enum keys, and the keys whose
   effects-map `**Values:**` line names a list (`modes.automation_always_ask`,
   `localization.locales`, `platform.browsers`, `stack.shared_roots`,
   `testing.patterns`, and `stack.layers.<layer>.root` when more than one path is
   given). A single value for a list-enum key becomes `[a]`. `[]` is written as
   `[]` for `compliance.regions` — it means "explicitly none", which is different
   from unset; say so in the approval prompt. `[]` for `platform.surfaces` is
   refused: a product ships at least one surface.

2. **Reserved warning**: if `<key>` is in `RESERVED_SET` (Phase 1b), print BEFORE
   the approval prompt:
   > "Note: `<key>` is RESERVED — no skill or hook reads it, so setting it will
   > not change any behaviour. Your value is stored either way."

   Then continue to the approval gate as normal. Phase 5 carries the identical
   warning. Warning on one write path and not the other leaves a silent route to
   the same outcome, which is the whole failure this guards against.

3. **Shadow warning**: read `get_yaml_key project.local.yaml <key>`. If it returns
   a non-empty value, print BEFORE the approval prompt:
   > "Note: this setting is currently locally overridden in `project.local.yaml` (value: `<localvalue>`). Writing to `project.yaml` will not change your effective value."

3b. **Scope warnings** — print BEFORE the approval prompt when they apply:
   - `<key>` is one of the six knobs `modes.rigor` fronts (`modes.workflow`,
     `docs.density`, `qa.level`, `modes.story_granularity`, `modes.review_mode`,
     `team.size`):
     > "Note: this pins `<key>` for the whole team and shadows the `modes.rigor`
     > expansion — changing `rigor` later will no longer move it. For a personal
     > preference (`modes.review_mode`, `team.size`), use `/settings --local` instead."
   - `<key>` is `project.stage`:
     > "Note: `project.stage` is normally advanced by `/gate-check` on a PASS.
     > Setting it here records a phase no gate has checked."

4. **Approval gate**: use `AskUserQuestion`:
   - Prompt: ``May I write this to `project.yaml`? (`<key>: <value>`)``
   - Options: `[A] Yes, write` / `[B] No, cancel`

5. **Write** using the `Edit` tool. The edit strategy depends on what already
   exists in `project.yaml`:

   **Case A — key exists**: Read `project.yaml`. Locate the line
   `<lastsegment>: <oldvalue>` and its parent block line (e.g. `modes:` for
   `modes.automation`). Construct the `Edit` with an `old_string` that runs from
   the parent block line through the leaf line, so the match is unique even if
   `<lastsegment>: <oldvalue>` appears elsewhere. Example for
   `modes.automation=guided`:
   ```
   old_string:
     modes:
       rigor: standard
       automation: collaborative
   new_string:
     modes:
       rigor: standard
       automation: guided
   ```
   When the existing value is a **block list** (`- a` lines under the key),
   include every item line in `old_string` and replace the whole block with the
   single flow-style line:
   ```
   old_string:
     platform:
       surfaces:
         - web
         - ios
   new_string:
     platform:
       surfaces: [web, ios, android]
   ```

   **Case B — parent block exists, leaf doesn't**: Find the last line of the
   parent block. Use `Edit` to append the new leaf line at the correct
   indentation, using the last existing leaf as the `old_string` anchor.

   **Case C — parent block doesn't exist**: Append a new top-level block at
   end-of-file (deterministic — always end-of-file, never between blocks). Use
   `Edit` with the last non-empty line of the file as `old_string` and append the
   new block after it. `workflow_overrides` and `features` are top-level blocks —
   never nest them under `modes:`.

   **Case D — file structure is unusual** (commented-out keys with the same name,
   ambiguous nesting, malformed YAML): STOP and ask via `AskUserQuestion`:
   > "Couldn't find a clean insertion point for `<key>` in `project.yaml`. Show me what to do."

6. Confirm: ``Set `<key>=<value>` in `project.yaml`.``

   **When `<key>` is `modes.rigor`**, the write also moves six other knobs, so
   print what they resolve to now — re-read each with `resolve_setting` rather
   than reciting the expansion table, since any of them may carry an explicit
   value that still wins:

   ```
   Set modes.rigor=full in project.yaml. It now supplies:
     modes.workflow: full            (derived from rigor: full)
     docs.density: terse             (project.yaml — explicit, unchanged)
     qa.level: full                  (derived from rigor: full)
     modes.story_granularity: fine   (derived from rigor: full)
     modes.review_mode: full         (derived from rigor: full)
     team.size: studio               (derived from rigor: full)
   ```

## Phase 5: Set-local Mode

(when `--local <key>=<value>`)

1. **Whitelist check**: call `is_locally_overridable <key>`.
   - If it returns 1 (locked), print one line:
     > ``<key> cannot be locally overridden — it's a project-wide setting. Use `/settings <key>=<value>` (no `--local`) to change it for the whole team.``
   - Exit without writing.

2. **Schema validation**: call `validate_enum_value <key> <value>`. If it returns
   1, show the stderr message verbatim and exit without writing. List values
   follow Phase 4 step 1b (flow style).

2b. **Reserved warning**: if `<key>` is in `RESERVED_SET` (Phase 1b), print BEFORE
   the approval prompt:
   > "Note: `<key>` is RESERVED — no skill or hook reads it, so setting it will
   > not change any behaviour. Your value is stored either way."

   Identical to Phase 4 step 2, and deliberately so. Both write paths reach the
   same file-of-record for a user's intent; warning on one only would leave
   `--local` as the silent route.

3. **Base check**: if `project.yaml` doesn't exist:
   > "Cannot create `project.local.yaml` — `project.yaml` is missing. Run `/start` to create one first."
   Exit. (Local overrides require a base.)

4. **Approval gate**: use `AskUserQuestion`:
   - Prompt: ``May I write this to `project.local.yaml`? (`<key>: <value>` — your personal override, gitignored)``
   - Options: `[A] Yes, write` / `[B] No, cancel`

5. **Write**:
   - If `project.local.yaml` doesn't exist, use `Write` to create it with the new
     setting wrapped in its parent block(s). Minimal example for
     `--local modes.automation=autonomous`:
     ```yaml
     # project.local.yaml — per-developer overrides (gitignored)
     modes:
       automation: autonomous
     ```
   - If it exists, use `Edit` with the same Case A/B/C strategy from Phase 4
     step 5.

6. Confirm: ``Set `<key>=<value>` in `project.local.yaml` (your override).``

## Phase 6: Usage

When the argument doesn't match any of the four valid forms (or has empty
operands), print:

```
Usage:
  /settings                          — view all effective config
  /settings <key>                    — view a single setting
  /settings <key>=<value>            — change a setting (project.yaml)
  /settings --local <key>=<value>    — change a setting locally
                                       (project.local.yaml, gitignored)

Examples:
  /settings modes.review_mode
  /settings modes.rigor=standard
  /settings platform.surfaces=web,ios,api
  /settings compliance.regions=[kr]
  /settings --local modes.automation=autonomous
  /settings --local modes.review_mode=solo
```

## Notes

- All YAML writes go through `Edit` (existing keys/blocks) or `Write` (new files).
  The skill does not depend on `yq` or any external YAML library. It writes only
  `project.yaml` and `project.local.yaml` — never a mirror file, never a value
  the user did not ask for.
- The whitelist is enforced in `yaml-helper.sh` (`is_locally_overridable`). To
  extend it, edit the `_yaml_helper_locally_overridable` constant — do not
  duplicate the list here. The effects-map `## Local Override Pattern` section
  explains each entry and why it is on the list.
- **Derived values are not stored anywhere.** `modes.workflow`, `docs.density`,
  `qa.level`, `modes.story_granularity`, `modes.review_mode` and `team.size` have
  no terminal default; when no file sets them their value comes from the
  `modes.rigor` expansion in `yaml-helper.sh` (`_yaml_helper_rigor_expansion`).
  Report them via `resolve_setting` — a `get_yaml_key` read returns empty and
  would render them "(not set)" while every skill is in fact acting on a real
  value.
- The validation tables are in `yaml-helper.sh`: `_yaml_helper_enums` (scalar
  enums) and `_yaml_helper_array_enums` (list-enum keys, checked element by
  element). `validate_enum_value` is the single-key validator for pending writes;
  `validate_yaml_enum` validates whole files (also used by `session-start.sh`);
  `validate_local_scope` checks the *location* of keys in `project.local.yaml`.
- `project.local.yaml` is gitignored. These overrides never propagate to
  teammates, and CI never sees them.
- For **which value to choose** for a given product type or team — and when to
  suggest changing one — see `.claude/docs/settings-guidance.md` § 2 (advisory
  presets + change triggers). `effects-map.md` says what each setting does; that
  doc says which to pick.
