# Skill Spec: /settings

> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-09-28

<!-- Assertions quote the canonical English text of .claude/skills/settings/SKILL.md —
     prompts, AskUserQuestion option labels, printed lines, headings — never the
     wording the model uses at run time in the user's conversation language. -->

## Skill Summary

`/settings` views or changes project configuration without hand-editing YAML. Four
forms: `/settings` (view-all), `/settings <key>` (view-one), `/settings <key>=<value>`
(set in `project.yaml`, team-wide, committed) and `/settings --local <key>=<value>` (set
in `project.local.yaml`, per developer, gitignored); anything else prints the usage
block. It sources `.claude/hooks/yaml-helper.sh` in the same Bash command as each
function it calls (`resolve_setting`, `resolve_config`, `get_yaml_key`,
`get_yaml_array`, `is_locally_overridable`, `validate_enum_value`, `validate_yaml_enum`,
`validate_local_scope`) and writes **only** `project.yaml` and `project.local.yaml`, and
only the key the user asked to change.

It is the only skill that writes `modes.review_mode`. It is **always collaborative**: it
changes the automation settings themselves, so it has no bootstrap block, never
resolves `modes.automation`, carries no automation prelude, and every write is shown
and approved in every mode. It validates list-enum keys (`platform.surfaces`,
`compliance.regions`) element by element, writes lists in flow style `[a, b]`, keeps
`[]` distinct from unset, derives the reserved-key set from the `> ### RESERVED`
banners in `.claude/docs/effects-map.md`, and prints what skills actually receive
(`resolve_config`, full form). It gives no verdict by design: its output is
configuration, not a judgement.

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`); `name: settings` equals the directory `.claude/skills/settings/` and the catalog entry `settings`
- [ ] `description` is exactly "View or change project config — effective merged values, or local overrides in project.local.yaml."; `argument-hint` is `"[key | key=value | --local key=value]"`; `model: sonnet`
- [ ] Bootstrap: **none** — no `!` injection at all, no `resolve_config --keys` line and no `Bash(bash "*/.claude/skills/settings/../../hooks/yaml-helper.sh" resolve_config *)` grant (the keys cell is empty)
- [ ] No rule-2 follow-on line ("Resolved above — …") and no automation prelude (always-collaborative; `.claude/docs/automation-modes.md` § Exemptions — Skills That Ignore the Automation Setting)
- [ ] `allowed-tools` is exactly: `Read, Glob, Grep, Write, Edit, Bash, AskUserQuestion` (no `Agent`, no grant)
- [ ] 2+ phase headings (`## Phase 0: Parse Arguments` … `## Phase 6: Usage`)
- [ ] No verdict token is required: `/skill-test static` Check 3 may WARN (never FAIL) — `.claude/skills/skill-test/SKILL.md` § Check 3 names `/settings` as its reference case of output that is a value, not a judgement
- [ ] Approval prompts present exactly: ``May I write this to `project.yaml`? (`<key>: <value>`)`` and ``May I write this to `project.local.yaml`? (`<key>: <value>` — your personal override, gitignored)``, each with options `[A] Yes, write` / `[B] No, cancel`
- [ ] Outputs: `project.yaml` and `project.local.yaml` only — "never a mirror file, never a value the user did not ask for"
- [ ] States that `/settings` is the only skill that writes `modes.review_mode`
- [ ] No `file:line` citations of other files; `.claude/docs/settings-guidance.md` § 2 is cited for which value to choose

---

## Director Gate Checks

N/A. `/settings` spawns no director gate and no agent: it has no keys and no `Agent`
tool.

---

## Test Cases

### Case 1: Happy Path — View-all on a configured Moa project

**Fixture** (assumed project state):
- `project.yaml`: `project.name: Moa`, `project.stage: Build`, `modes.rigor: standard`, `modes.automation: collaborative`, `docs.density: terse`, `platform.surfaces: [web, ios, android, api]`, `compliance.regions: [kr]`
- `project.local.yaml`: `modes.automation: guided`, `modes.review_mode: solo`

**Input:** `/settings`

**Expected behavior:**
1. Runs `validate_yaml_enum` on both files and `validate_local_scope project.local.yaml`; prints `Schema validation: ok`
2. Enumerates file leaves in order, then appends the rigor family (`modes.rigor`, `modes.workflow`, `docs.density`, `qa.level`, `modes.story_granularity`, `modes.review_mode`, `team.size`)
3. Reads each scalar leaf with `resolve_setting` (value + source) and each list leaf with `get_yaml_array`
4. Prints grouped effective config, e.g. `automation: guided (LOCAL OVERRIDE — yaml has: collaborative)`, `workflow: standard (derived from rigor: standard, locked)`, `density: terse (project.yaml, locked)`, `surfaces: [web, ios, android, api] (project.yaml, locked)`
5. Prints the `locked = …` legend and, under `What skills receive:`, the full `resolve_config` output verbatim, including its `notes:` line

**Assertions:**
- [ ] Derived knobs show their rigor-derived value, not "(not set)"
- [ ] The `locked` legend says locked does NOT mean fixed ("an explicit value wins over rigor")
- [ ] `notes: none` is printed when nothing was rejected (the notes line is never silent)
- [ ] No file is written in view mode

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Failure — Invalid list element and malformed operand

**Fixture:**
- A configured `project.yaml`

**Input:** `/settings platform.surfaces=web,iso`, then `/settings --local =foo`

**Expected behavior:**
1. `validate_enum_value platform.surfaces "web,iso"` validates each element and fails on `iso`; the stderr line (`Invalid value '<value>' for '<key>'. Allowed: ...`) is shown verbatim and the skill exits without writing
2. `--local =foo` has an empty key after the first `=`, so it routes to Phase 6 and prints the usage block

**Assertions:**
- [ ] The whole write is rejected when any element is invalid
- [ ] No approval prompt is shown for an invalid or malformed request
- [ ] Neither file changes

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: NOT ASSESSED — No `project.yaml`

**Fixture:**
- `project.yaml` is missing; `.claude/hooks/yaml-helper.sh` exists

**Input:** `/settings`, then `/settings --local modes.review_mode=solo`

**Expected behavior:**
1. View-all reports "No `project.yaml` found — run `/start` to create one." and exits
2. Set-local reports "Cannot create `project.local.yaml` — `project.yaml` is missing. Run `/start` to create one first." and exits

**Assertions:**
- [ ] No effective-config block is invented from defaults
- [ ] Neither file is created
- [ ] Both messages name the missing input and the skill that produces it (`/start`)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Mode Variant — Set `modes.rigor` in `project.yaml`

**Fixture:**
- `project.yaml`: `modes.rigor: standard`, `docs.density: terse`; no `project.local.yaml` override for rigor

**Input:** `/settings modes.rigor=full`

**Expected behavior:**
1. `validate_enum_value modes.rigor full` passes
2. Asks via `AskUserQuestion`: ``May I write this to `project.yaml`? (`modes.rigor: full`)`` with `[A] Yes, write` / `[B] No, cancel`
3. On yes, edits the existing line with an `old_string` that runs from the `modes:` block line through the leaf (Case A)
4. Confirms ``Set `modes.rigor=full` in `project.yaml`.`` and re-reads the six fronted knobs with `resolve_setting`: `docs.density: terse (project.yaml — explicit, unchanged)`, the other five `(derived from rigor: full)`

**Assertions:**
- [ ] The six knobs are re-read, not recited from the expansion table
- [ ] Only `modes.rigor` changes in the file
- [ ] Nothing is written on `[B] No, cancel`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Always Collaborative — `autonomous` does not skip the approval

**Fixture:**
- `project.local.yaml`: `modes.automation: autonomous`

**Input:** `/settings --local modes.review_mode=solo`

**Expected behavior:**
1. `is_locally_overridable modes.review_mode` returns 0 (overridable)
2. The skill still asks ``May I write this to `project.local.yaml`? (`modes.review_mode: solo` — your personal override, gitignored)`` and waits
3. On yes, edits `project.local.yaml` and confirms ``Set `modes.review_mode=solo` in `project.local.yaml` (your override).``

**Assertions:**
- [ ] SKILL.md has no automation prelude and does not resolve `modes.automation`
- [ ] The write is not logged-and-proceeded as in `autonomous` mode — the approval gate is always shown
- [ ] `modes.review_mode` is written only because the user asked (the one skill allowed to)

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Edge Case — Locked key, explicit none, fronted-knob warning

**Fixture:**
- A configured `project.yaml`; `platform.surfaces` stored as a block list (`- web`, `- ios`)

**Input:** `/settings --local release.distribution=web`, then `/settings compliance.regions=[]`, then `/settings platform.surfaces=web,ios,android`, then `/settings team.size=studio`

**Expected behavior:**
1. `release.distribution` is locked: prints ``release.distribution cannot be locally overridden — it's a project-wide setting. Use `/settings release.distribution=web` (no `--local`) to change it for the whole team.`` and exits
2. `compliance.regions=[]` is written as `[]`; the approval prompt says it means "explicitly none", which is different from unset
3. `platform.surfaces` replaces the whole block list with the single flow-style line `surfaces: [web, ios, android]`; `[]` for surfaces would be refused
4. `team.size=studio` prints the fronted-knob note ("this pins `team.size` for the whole team and shadows the `modes.rigor` expansion …") before the approval prompt and suggests `/settings --local` for a personal preference

**Assertions:**
- [ ] A locked key is never written to `project.local.yaml`
- [ ] Lists are written in flow style `[a, b]`; `[]` stays distinct from an absent key
- [ ] The scope warning appears before the approval prompt, not after the write

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: Edge Case — A reserved key is marked on every path

**Fixture:**
- `.claude/docs/effects-map.md` has a key heading followed by a `> ### RESERVED` banner; that key is set in `project.yaml`

**Input:** `/settings`, `/settings <that key>`, `/settings <that key>=<value>`, `/settings --local <that key>=<value>` (when locally overridable)

**Expected behavior:**
1. Phase 1b derives the set with `grep -B14 '^> ### RESERVED' .claude/docs/effects-map.md | grep -E '^## '`, splitting headings that name two keys joined by " and "
2. View-all appends `, reserved` and prints the reserved legend; view-one prints the RESERVED notice **above** the value block
3. Both write paths print the identical "Note: `<key>` is RESERVED — no skill or hook reads it, …" warning before the approval prompt, then write on approval

**Assertions:**
- [ ] The set is derived from the banner heading, never hard-coded and never matched on the bare word
- [ ] All four forms carry the marking; a write to a reserved key is never refused
- [ ] SKILL.md does not name the reserved keys literally

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Shows the exact key and value in the approval prompt before every write
- [ ] Writes only `project.yaml` or `project.local.yaml`, only the requested key, via `Edit` (or `Write` for a new `project.local.yaml`)
- [ ] Always collaborative: no automation prelude, no `modes.automation` resolution, every write approved
- [ ] Writes nothing under `production/session-logs/`
- [ ] Converses in the user's language; the quoted prompts in SKILL.md are the canonical English forms

---

## Category Rubric (`utility`)

- `utility U1` — the static checks above pass: no bootstrap line, grant or follow-on line (no keys), no automation prelude, "May I write" before each write, outputs exact (`project.yaml`, `project.local.yaml`)
- `utility U2` — not applicable (no director gate)
- The NOT ASSESSED case is Case 3 (missing input: no `project.yaml`)

---

## Coverage Notes

- Case C (new top-level block appended at end of file) and Case D (unusual structure ⇒ stop and ask) of the write
  strategy are not fixture-tested separately.
- `project.stage` set here prints the "normally advanced by `/gate-check`" note; follows the Case 6 pattern.
- The list of locally overridable keys lives in `yaml-helper.sh` (`_yaml_helper_locally_overridable`); the spec
  asserts only that `is_locally_overridable` decides it.
