# Skill Test Spec: /help

## Skill Summary

`/help` works out where the project is in the delivery pipeline and names the one
thing to do next. It runs on the Haiku model and is read-only: it writes no file and
spawns no agent. It takes the phase from the resolved `project.stage` (the catalog
phase id is the stage value lowercased) or, when the stage is not set, from
`bash .claude/scripts/stage-estimate.sh`; it then runs
`bash .claude/scripts/artifact-check.sh --phase <id>` once and applies each step's
`tiers=` and `when=` fields to decide what is REQUIRED or OPTIONAL. The latest sprint
and the session state are read at run time (Glob `production/sprints/sprint-*.md`, the
tail of `production/session-state/active.md`); in Build and Launch it reads
`production/sprint-status.yaml` (`in-progress`, `review`, `ready-for-dev`, `done`,
`blocked`). An optional argument says what the user just finished or where they are
stuck.

The output is a short orientation block with a `/gate-check <next-phase-id>` pointer
named by the **target** phase (none in Launch, which is terminal), ending in
`Verdict: **COMPLETE** — next steps identified.` — or **NOT ASSESSED**, naming the script, when
`artifact-check.sh` or `stage-estimate.sh` exits non-zero.

---

## Static Assertions (Structural)

Verified automatically by `/skill-test static` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`; `name: help` equals the directory `.claude/skills/help/` and the catalog entry `help`
- [ ] `description` is exactly "What should I do next? Use when stuck or unsure what comes next."; `model: haiku`
- [ ] Bootstrap: the first body line is `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys project.stage,workflow,surfaces,compliance,stack,distribution,rigor` `` — this key string exactly
- [ ] `allowed-tools` grants `Bash(bash "*/.claude/skills/help/../../hooks/yaml-helper.sh" resolve_config *)` — the skill's own directory name
- [ ] The line after the bootstrap block is exactly ``Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] No automation prelude (`automation` is not in the keys)
- [ ] `allowed-tools` is exactly: `Read, Glob, Grep, Bash` + the grant (no `Write`, `Edit`, `Agent` or `AskUserQuestion`)
- [ ] The bootstrap line is the only `!` injection; no injection contains `$(`, `${`, `;`, `|` or `&&`
- [ ] Has ≥2 phase headings (`## Step 1: Read the Catalog` … `## Step 9: Escalation Paths`)
- [ ] Contains the verdict keywords `COMPLETE` and `NOT ASSESSED`
- [ ] Runs `stage-estimate.sh` only when `project.stage` is `not set`, and calls `artifact-check.sh --phase <phase id>` with the stage lowercased
- [ ] Renders the three step notes as written: "(required at <tiers>)", "(required when <cond>)" and "(when <cond> — unknown; run /setup-stack)"
- [ ] Does NOT contain "May I write" language; states "This skill is read-only — it reports findings but writes no files."
- [ ] Outputs: none
- [ ] No stage-to-phase mapping table (the phase id is the stage lowercased); no `file:line` citations of other files
- [ ] Has a next-step handoff (`/gate-check [next-phase-id]`, escalation paths `/project-stage-detect`, `/start`, `/settings`)

---

## Director Gate Checks

None. `/help` is a read-only navigation skill: `review_mode` is not in its keys, and it
has no `Agent` tool. No director gates apply.

---

## Test Cases

### Case 1: Happy Path — Build stage with an active sprint

**Fixture:**
- `project.yaml`: `project.stage: Build`, `modes.rigor: standard`
- `production/sprints/sprint-04.md` exists (the newest sprint file)
- `production/sprint-status.yaml` has `goals-core/story-002` at `status: in-progress` and `story-003` at `status: ready-for-dev`
- `production/session-state/active.md` ends with a STATUS block naming `Epic: goals-core`

**Input:** `/help`

**Expected behavior:**
1. Takes the phase from the resolved `project.stage` (`Build` → `build`); does not run the stage estimator
2. Runs `bash .claude/scripts/artifact-check.sh --phase build` once
3. Reads `production/sprint-status.yaml`: `story-002` is "currently active", `story-003` is "next up"
4. Prints `## Where You Are: Build (from project.stage)`, `**Latest sprint:** production/sprints/sprint-04.md`, one `→` next step, and "Approaching **Hardening** gate → run `/gate-check hardening` when ready."
5. Ends with `Verdict: **COMPLETE** — next steps identified.`

**Assertions:**
- [ ] Exactly one `→` (REQUIRED) next step is shown
- [ ] The sprint status words are read with a hyphen (`in-progress`); the glob check for `implement` and `story-done` is skipped in favour of the YAML
- [ ] The gate pointer names the target phase (`hardening`), not the current one
- [ ] No files are written

---

### Case 2: Mode Variant — `workflow: minimal` in Definition

**Fixture:**
- `project.yaml`: `project.stage: Definition`, no `modes.rigor` (resolves `workflow: minimal`)
- `design/product/one-pager.md` exists; `stack.pinned_on: 2026-09-20`

**Input:** `/help`

**Expected behavior:**
1. `artifact-check.sh --phase definition` reports `map-features`, `write-prd` and `prd-review` with `tiers=standard,full` (and `stack-setup` with `tiers=standard,full`, PRESENT from the pin)
2. The tier does not require them at `minimal`, so they are OPTIONAL "(required at standard,full)" — and optional docs are not surfaced at `minimal` at all
3. The next step points at code: the one-pager's `## Build Order` is the plan

**Assertions:**
- [ ] No PRD or feature-map step is shown as REQUIRED
- [ ] The primary recommendation is code, with the one-pager's `## Build Order` named as the plan — not document authoring
- [ ] Verdict is `COMPLETE`

**Variant B — stack not pinned at `minimal`:** the same fixture with `project.stage: Discovery` and no `stack.pinned_on` (the `stack` line carries ` pinned_on=unset`). `artifact-check.sh --phase discovery` reports `stack-setup` with `required=false` and `status=PATTERN_MISS` (`project.yaml` has no `pinned_on:` date), and `product-brief` PRESENT via the one-pager.
- [ ] Although optional docs are not surfaced at `minimal`, the `stack-setup` step (`/setup-stack`) is still surfaced — a pinned stack is the floor before code, and the catalog makes it required from the Architecture phase
- [ ] `prd-review-brief` (`tiers=standard,full`) is not surfaced at `minimal`

---

### Case 3: NOT ASSESSED — Stage and stack unset (A); a script that cannot run (B)

**Variant A fixture** (unknown inputs — the run still completes, with nothing dropped):
- `project.yaml` has no `project.stage`; the block prints `project.stage: not set`
- The block prints `stack: unset — run /setup-stack`, `platform.surfaces: (unset -- ask which surfaces ship)` and `compliance: regions=(unset -- ask) handles_pii=(unset -- ask)`
- `stage-estimate.sh` prints `STAGE: Architecture`, `SOURCE: estimated`, `EVIDENCE: rung 5: docs/architecture/adr-0001-identity-and-auth.md …`
- `modes.rigor: standard`

**Input:** `/help`

**Expected behavior:**
1. Runs `bash .claude/scripts/stage-estimate.sh` and takes its `STAGE:` line (lowercased) as the phase; says the phase is estimated and quotes the `EVIDENCE:` clause
2. Runs `artifact-check.sh --phase architecture`
3. `api-design` and `data-model` (`when=backend`), `threat-model` (`when=pii`) and `accessibility-doc` (`when=ui`) cannot be decided — an input is unset — so they render **REQUIRED** with "(when backend — unknown; run /setup-stack)" / "(when pii — unknown; run /setup-stack)" / "(when ui — unknown; run /setup-stack)"
4. The architecture-phase `stack-setup` step (`tiers=all`) is incomplete with `stack: unset` (`PATTERN_MISS` — `project.yaml` exists without a `pinned_on:` date) and renders **REQUIRED** (`/setup-stack`)

**Variant B fixture** (the run cannot assess):
- As Variant A, but `.claude/scripts/artifact-check.sh` is missing, so `bash .claude/scripts/artifact-check.sh --phase architecture` exits non-zero (127, "No such file or directory") and prints no `STEPS:` line

**Variant B expected behavior:**
1. Step 4 detects the failed call; no completion report (no `✓ Done`, `→ Next up` or `Coming up` block) is printed
2. The run ends `Verdict: **NOT ASSESSED** — artifact-check.sh could not run (<error>); fix it and re-run, or use /project-stage-detect.`

**Assertions:**
- [ ] The stage is never guessed from the skill's own reading of the tree
- [ ] Unknown conditions stay REQUIRED with the "unknown; run /setup-stack" note — unset is not false, and no step is dropped (Variant A ends `COMPLETE`)
- [ ] `NO_CHECK` is never reported as done; a `NO_CHECK:` total covering most of the phase is said plainly
- [ ] Variant B prints no completion report and ends with the exact NOT ASSESSED line above, naming `artifact-check.sh`; the same rule applies to `stage-estimate.sh` (Step 2) when it exits non-zero or prints no `STAGE:` line
- [ ] Variant B never re-derives completion with its own Glob/Grep

---

### Case 4: Argument — "just finished prd-review"

**Fixture:**
- `project.stage: Definition`, `modes.rigor: standard`
- `design/prd/goals.md` exists; `design/prd/reviews/` is empty (the review log is not yet written)

**Input:** `/help just finished prd-review`

**Expected behavior:**
1. The artifact check reports `prd-review` ABSENT
2. The user's argument advances past the named step even though the artifact check is ambiguous
3. The next required step after it is shown; "coming up" lists the later required steps

**Assertions:**
- [ ] `prd-review` is not presented as the current blocker
- [ ] Exactly one primary recommendation is given
- [ ] Escalation paths are NOT shown (the input does not suggest confusion)

---

### Case 5: Edge Case — Launch is terminal

**Fixture:**
- `project.stage: Launch`; `production/releases/1.0.0/release-record.md` exists

**Input:** `/help`

**Expected behavior:**
1. Surfaces the optional repeatable delivery-loop steps of the Launch phase
2. Replaces the gate line with "Launch is terminal — no further phase gate; use /release-checklist, /rollout-plan and /retrospective release <version>."

**Assertions:**
- [ ] No `/gate-check` pointer is printed in Launch
- [ ] The terminal line matches SKILL.md exactly
- [ ] Verdict is `COMPLETE`

---

### Case 6: Director Gate Check — No gate; help is read-only navigation

**Fixture:**
- Any project state

**Input:** `/help stuck on ADRs`

**Expected behavior:**
1. Produces the orientation block, then the escalation paths (the input says "stuck")
2. The `/settings` rigor line appears only when a `.claude/docs/settings-guidance.md` § 4 trigger fires
3. No director agent is spawned and no write tool is called

**Assertions:**
- [ ] No director gate is invoked and no gate skip message appears
- [ ] No write tool is called
- [ ] The next skill is recommended, never run

---

## Protocol Compliance

- [ ] Reads the resolved config, the catalog, the session tail and the latest sprint before suggesting anything
- [ ] Suggestions are specific to the current phase, tier and conditions (not generic)
- [ ] Asks about MANUAL steps ("I can't tell if [step] is done — has it been completed?") instead of assuming
- [ ] Does not write any files, including under `production/session-logs/`
- [ ] Never writes `modes.review_mode` or any other knob that `modes.rigor` fronts
- [ ] Ends with `Verdict: **COMPLETE** — next steps identified.` — or, when `stage-estimate.sh` or `artifact-check.sh` could not run, with the NOT ASSESSED line naming the script and no report above it

---

## Category Rubric (`utility`)

- `utility U1` — the static checks above pass: bootstrap line and grant exact, `--keys` exact, plain follow-on line, no "May I write" (read-only), outputs none
- `utility U2` — not applicable (no director gate)
- The NOT ASSESSED case is Case 3: Variant B is the run-level `Verdict: **NOT ASSESSED**` (artifact-check.sh could not run); Variant A covers missing inputs that do not stop the run (estimated stage, unknown conditions kept REQUIRED, verdict COMPLETE)

---

## Coverage Notes

- The uncataloged-skills footer (Step 1b) is not fixture-tested; it lists at most 10 installed skills that are
  not catalog commands.
- `tiers_error=` / `when_error=` catalog defects are reported by name; not fixture-tested here.
- `localization.locales` (for `when=multi-locale`) is read from `project.yaml` with Read; the multi-locale branch
  follows the Case 3 pattern.
