# Skill Test Spec: /ux-design

## Skill Summary

`/ux-design` is a guided, section-by-section UX authoring skill for web and mobile products. Its modes and outputs:
a screen spec (`.claude/docs/templates/ux-spec.md`) or a multi-screen flow spec (`.claude/docs/templates/user-flow.md`)
at `design/ux/<slug>.md`; `shell` → `design/ux/app-shell.md` (`app-shell.md` template); `patterns` →
`design/ux/interaction-patterns.md` (`interaction-pattern-library.md` template); `accessibility` →
`design/accessibility-requirements.md` plus the single key `accessibility.target` in `project.yaml`; `journey` →
`design/product/user-journey.md`. The skill follows the skeleton-first pattern: it creates the file with every heading
of the mode's template (each body `[To be designed]`), then fills each section through discussion and writes it after
approval. Every screen spec carries `## API Data` (read by `/api-design reconcile`) and `## Analytics Events`, and must
say what happens on loading, empty, error, offline and session expiry.

The skill has no director gates — `/ux-review` is the separate review step. Each section write is preceded by
"May I write the [section name] section to `[filepath]`?". If the output file exists, the skill retrofits only empty
or placeholder sections. An API-only product (no `web`, `ios` or `android` surface) stops with `NOT ASSESSED`, except
in `journey` mode. Verdict: `COMPLETE` when the document was written and approved section by section.

Assertions quote the canonical English text of `.claude/skills/ux-design/SKILL.md`; prompts are rendered in the user's
conversation language at run time (`.claude/docs/coding-standards.md` § Language Policy) and this spec never asserts
the runtime wording.

---

## Static Assertions (Structural)

Verified automatically by `/skill-test static` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] `name: ux-design` equals the directory name (`.claude/skills/ux-design/`) and this spec's basename
- [ ] `argument-hint` is `"[screen/flow name] | shell | patterns | accessibility | journey"`
- [ ] The first body line is exactly
      `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow,docs.density,stack,surfaces,accessibility,compliance` ``
      — the `--keys` value is exactly `automation,workflow,docs.density,stack,surfaces,accessibility,compliance`
- [ ] `allowed-tools` contains the grant naming this skill's own directory:
      `Bash(bash "*/.claude/skills/ux-design/../../hooks/yaml-helper.sh" resolve_config *)`
- [ ] `allowed-tools` is exactly the set Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion plus that grant — no
      plain `Bash`, no MCP tool names
- [ ] The line after the bootstrap block is exactly: ``Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.``
      (the variant without `--review` — `review_mode` is not among the keys)
- [ ] The automation prelude block — from `**Automation mode**: Resolve` to `categories always prompt).` — follows
      that line verbatim
- [ ] The bootstrap line is the only `!` injection in the file; no `file:line` citation of another file
- [ ] `model: sonnet`; no `disable-model-invocation` and no `isolation` key
- [ ] Has ≥2 phase headings
- [ ] Contains the verdict keywords `COMPLETE` and `NOT ASSESSED`, and the stop line
      `NOT ASSESSED — no UI surface configured (platform.surfaces has no web, ios or android)`
- [ ] Names every output: `design/ux/<slug>.md`, `design/ux/app-shell.md`, `design/ux/interaction-patterns.md`,
      `design/accessibility-requirements.md` (and `accessibility.target` in `project.yaml`),
      `design/product/user-journey.md`
- [ ] Contains "May I write" language per section, before the skeleton, and before the `project.yaml` write
- [ ] The section-guidance table points to `.claude/skills/ux-design/references/sections-ux-spec.md`,
      `.claude/skills/ux-design/references/sections-app-shell.md` and
      `.claude/skills/ux-design/references/sections-patterns.md`, and all three files exist
- [ ] Has a next-step handoff (`/ux-review` to validate the completed spec; `/api-design reconcile` when `## API Data`
      has `proposed` or `mismatch` rows)

---

## Director Gate Checks

None. `/ux-design` has no `review_mode` key and spawns no director gate. `/ux-review` is the separate review skill run
after this one; its DD-UI-CONSISTENCY gate is where design-director review happens. The agents this skill spawns
(`product-designer`, `ux-writer`, `frontend-engineer`, `mobile-engineer`, `accessibility-specialist`) are
consultations that return analysis; this session owns every write.

---

## Test Cases

### Case 1: Happy Path — new screen spec for goal detail, all sections authored and written

**Fixture:**
- Moa; the config block prints `workflow: standard (rigor:standard)`, `docs.density: balanced (rigor:standard)`,
  `platform.surfaces: web, ios, android, api (project.yaml)`, `accessibility.target: wcag-aa (project.yaml)`,
  `compliance: regions=kr handles_pii=true (project.yaml)`
- `design/product/product-brief.md`, `design/product/feature-map.md`, `design/prd/goals.md` (with `## UI Requirements`)
  and `design/accessibility-requirements.md` (`> **Target**: wcag-aa`) exist; `docs/api/openapi.yaml` exists
- No `design/ux/goal-detail.md`; the user converses in Korean

**Input:** `/ux-design goal-detail`

**Expected behavior:**
1. The UI check passes (a UI surface exists); the name is one screen, so the template is `ux-spec.md`
2. Phase 2 reads the brief, feature map, journey (if any), the PRD's `## UI Requirements`, existing specs, the pattern
   catalog index only, the design language's components/layout/platform sections, the accessibility target, and
   derives input methods and breakpoints from the surfaces line (web: `sm`/`md`/`lg`; mobile: compact/regular)
3. The context summary is presented; the user confirms
4. "May I create the skeleton file at `design/ux/goal-detail.md`?" — the skeleton mirrors the template's headings
   (`## Purpose & User Need` … `## Open Questions`, with `### Wireframe`, `### Breakpoints`, `### Component Inventory`,
   `### Navigation Inputs`, `### Action Inputs`, `### State-Specific Behaviors`), each body `[To be designed]`
5. Each section follows Context → Questions → Options → Decision → Draft → Approval → Write; "May I write the
   [section name] section to `design/ux/goal-detail.md`?" before each Edit; `production/session-state/active.md` is
   updated after each write
6. Phase 5 runs the seven cross-reference checks (PRD coverage, pattern alignment, navigation, accessibility, states,
   API Data, analytics)
7. The handoff states that the spec must be validated with `/ux-review`; verdict `COMPLETE`

**Assertions:**
- [ ] The skeleton is created first, with every template heading byte-identical and never translated (`## API Data`
      in particular); section bodies are written in Korean
- [ ] "May I write the [section name] section" is asked per section (not once at the end)
- [ ] `## API Data` rows are marked `in contract`, `proposed` or `mismatch`; any `proposed` or `mismatch` row makes
      `/api-design reconcile` a next step
- [ ] Loading, empty, error and offline states and the auth and permission boundaries are covered (check 5)
- [ ] Handoff to `/ux-review` is at the end; verdict `COMPLETE`

---

### Case 2: Existing UX Spec — Retrofit: only empty or placeholder sections

**Fixture:**
- `design/ux/goal-detail.md` exists with every section populated except `## Localization Considerations`
  (`[To be designed]`), and it predates `## API Data` (the heading is absent)

**Input:** `/ux-design goal-detail`

**Expected behavior:**
1. Phase 2b detects the existing file and presents the section status table
2. `## API Data` counts as Empty and is offered with its exact template heading; `## Localization Considerations` is
   Placeholder
3. The skeleton step is skipped; only those two sections are authored, each with Edit in place after
   "May I write the [section name] section to `design/ux/goal-detail.md`?"

**Assertions:**
- [ ] The existing spec is detected and retrofit is offered — the skill never creates a new skeleton over it
- [ ] Only Empty or Placeholder sections are authored; complete sections are unchanged
- [ ] The added heading is exactly `## API Data`, at its template position
- [ ] Verdict `COMPLETE`

---

### Case 3: Context Gap — no user journey map

**Fixture:**
- As Case 1, but `design/product/user-journey.md` does not exist

**Input:** `/ux-design goal-create`

**Expected behavior:**
1. Phase 2b notes the gap: "No user journey map found at `design/product/user-journey.md`. Designing without it means
   we'll be making assumptions about the user's context. Run `/ux-design journey` after this spec is drafted."
2. The spec's Open Questions gets the entry "User journey map not yet created — run `/ux-design journey` to establish
   the user's context for this screen."
3. Authoring continues; the context summary shows `Lifecycle stage(s): unknown — no journey map`

**Assertions:**
- [ ] The skill does NOT block on the missing journey map — it continues and records the gap
- [ ] The gap is noted both in the output and in the spec's Open Questions
- [ ] "goal creation" is a multi-screen task, so the skill asks whether it is one screen or a flow before choosing the
      template (`ux-spec.md` or `user-flow.md`)

---

### Case 4: No Argument Provided — the skill asks instead of failing

**Fixture:**
- No argument provided with the skill invocation

**Input:** `/ux-design`

**Expected behavior:**
1. The skill does not fail; it asks with `AskUserQuestion` "What are we designing today?"
2. Options: "A specific screen or flow (I'll name it)", "The app shell", "The interaction pattern library",
   "Accessibility requirements or the user journey map (I'll say which)"
3. A named screen is normalised to kebab-case (`Goal Detail` → `goal-detail`)

**Assertions:**
- [ ] No file is created and no "May I write" is asked before the mode is known
- [ ] The question and its options are the canonical English forms in SKILL.md
- [ ] `app-shell` as an argument means `shell` mode; `reviews` is not accepted as a slug

---

### Case 5: Director Gate Check — No gate; ux-review is the separate review skill

**Fixture:**
- New screen spec with argument provided

**Input:** `/ux-design settings-account`

**Expected behavior:**
1. Skill authors all sections of the settings & account screen spec
2. No director agent is spawned
3. No gate ID appears in output during authoring

**Assertions:**
- [ ] No director gate is invoked during `/ux-design`
- [ ] No gate skip messages appear (the skill has no `review_mode` key to apply)
- [ ] Verdict is `COMPLETE` without any gate check

---

### Case 6: NOT ASSESSED — API-only product (missing input: no UI surface)

**Fixture:**
- The config block prints `platform.surfaces: api (project.yaml)` (a partner API product)
- Variant: `platform.surfaces: (unset -- ask which surfaces ship)`

**Input:** `/ux-design goal-detail` · then `/ux-design journey`

**Expected behavior:**
1. The screen request stops with `NOT ASSESSED — no UI surface configured (platform.surfaces has no web, ios or android)`
   and names `/setup-stack` as the fix if the product does have a UI
2. `journey` mode runs for the API product (activation is the first successful API call)
3. Variant: unset surfaces are not "no UI" — the skill continues and asks once in Phase 2h, then stores the answer for
   the session

**Assertions:**
- [ ] No file is written for the stopped screen request; verdict `NOT ASSESSED`
- [ ] `journey` mode is not stopped by the missing UI surface
- [ ] The surfaces question is asked once per session, never per section, and never written to `project.yaml`

---

### Case 7: Mode Variant — `accessibility` commits the target before the skeleton

**Fixture:**
- The config block prints `accessibility.target: (unset -- ask; unset is not none)` and
  `compliance: regions=kr handles_pii=true (project.yaml)`; no `design/accessibility-requirements.md`

**Input:** `/ux-design accessibility`

**Expected behavior:**
1. The target is decided first: "Which accessibility target does this product commit to (WCAG 2.2)?" with
   `wcag-aa` (Recommended), `wcag-a`, `wcag-aaa` (specific flows only), `none` (a recorded decision)
2. "May I write this to `project.yaml`?" shows the exact change — a top-level `accessibility:` block with the single key
   `target: wcag-aa` — and nothing else is written to `project.yaml`
3. The skeleton `design/accessibility-requirements.md` is created with `> **Target**: wcag-aa` as its first header line
4. `## Regional Standards` gets one row for `kr` from `.claude/docs/compliance/kr.md` § Accessibility (KWCAG 2.2),
   with no deadline, penalty or threshold unless sourced
5. The per-feature accessibility matrix has one row per feature in the feature map (counted first)

**Assertions:**
- [ ] The target is never assumed; a placeholder Target line is never written
- [ ] The document is written outside `design/ux/` at exactly `design/accessibility-requirements.md`
- [ ] If the user picks `none` or `wcag-a` while a region carries accessibility obligations, the skill says so and has
      `accessibility-specialist` explain the gap before confirmation
- [ ] The handoff offers `/design-language`, `/ux-design [key screen]` and `/gate-check validation`

---

### Case 8: Mode Variant — `shell` aggregates every PRD's UI Requirements

**Fixture:**
- Five PRDs exist; four have `## UI Requirements`, `design/prd/payments.md` has none

**Input:** `/ux-design shell`

**Expected behavior:**
1. The skill greps `^#+ .*UI Requirements` across `design/prd/*.md` after counting the denominator (5)
2. The unmatched PRD is listed and the user confirms whether it is genuinely without UI before it is excluded
3. The skeleton `design/ux/app-shell.md` carries `## Navigation Model`, `## Global Regions per Breakpoint`,
   `## Persistent Elements`, `## Global States`, `## Notifications & Banners`, `## Accessibility`

**Assertions:**
- [ ] A PRD without a UI Requirements section is never silently treated as having no UI needs
- [ ] The shell skeleton's headings are byte-identical to `.claude/docs/templates/app-shell.md`
- [ ] The shell runs cross-reference checks 1, 3, 4 and 5; a check that did not run is listed as
      `NOT CHECKED — <reason>`

---

## Protocol Compliance

- [ ] Creates the skeleton file with every template heading before discussing content (accessibility mode: the target
      decision first)
- [ ] Discusses and drafts one section at a time
- [ ] Asks "May I write the [section name] section to `[filepath]`?" after each section is approved
- [ ] Detects an existing document and offers the retrofit path
- [ ] Ends with the handoff (`/ux-review`, or the mode-specific next steps)
- [ ] Never assumes an accessibility target, a surface list or a region list the configuration leaves unset
- [ ] Agents never write files — this session owns every write; never commits

**Authoring rubric** (`CCSS Skill Testing Framework/quality-rubric.md` § `authoring`):

- [ ] A1 — Section-by-section cycle (Context → Questions → Options → Decision → Draft → Approval → Write)
- [ ] A2 — "May I write" per section write, before the skeleton and before the `project.yaml` write
- [ ] A3 — Retrofit: an existing output file is detected and only Empty or Placeholder sections are authored
- [ ] A4 — N/A: no director gate is defined for this skill (`/ux-review` carries DD-UI-CONSISTENCY)
- [ ] A5 — Skeleton headings byte-identical to the template file of the mode (`ux-spec.md`, `user-flow.md`,
      `app-shell.md`, `interaction-pattern-library.md`, `accessibility-requirements.md`, `user-journey.md` under
      `.claude/docs/templates/`)

---

## Coverage Notes

- The per-section content rules live in `.claude/skills/ux-design/references/` (one file per mode) and in the
  accessibility guide; they are loaded per section and not re-asserted here.
- `patterns` mode (catalog index, service-specific patterns such as forms with inline validation, payment sheet,
  OTP / identity verification) is covered only by the A5 heading assertion; its `> **UI Frameworks**:` header line
  comes from the resolved `stack` line (a layer under `unset=` leaves it `To be designed`), never from a Read of
  `project.yaml`.
- `journey` mode's lifecycle stages and metrics-per-stage content are not fixture-tested beyond Case 6.
- Wireframe descriptions are text-only; image references may be added manually by a designer after the fact.
