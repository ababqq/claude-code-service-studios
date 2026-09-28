---
name: help
description: "What should I do next? Use when stuck or unsure what comes next."
argument-hint: "[optional: what you just finished, e.g. 'finished prd-review' or 'stuck on ADRs']"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Bash(bash "*/.claude/skills/help/../../hooks/yaml-helper.sh" resolve_config *)
model: haiku
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys project.stage,workflow,surfaces,compliance,stack,distribution,rigor`

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.

# Studio Help — What Do I Do Next?

This skill is read-only — it reports findings but writes no files.

This skill figures out exactly where you are in the product delivery pipeline and
tells you what comes next. It is **lightweight** — not a full audit. For a full
gap analysis, use `/project-stage-detect`.

## Live Project State

The config block above is resolved before this skill runs. Use it as-is:

- **`project.stage`** is the authoritative phase for Step 2 when it is set. When it
  prints `not set`, Step 2 asks `.claude/scripts/stage-estimate.sh` instead — never
  guess the stage from a quick look at the tree.
- **`workflow`** is the tier for Step 4 and Step 5 — do not re-read it.
- **`rigor`** decides whether the `/settings` rigor line fires (Step 9) — the
  `rigor:` value, not `workflow`, which can be set explicitly apart from it.
- **`platform.surfaces`**, **`stack`**, **`compliance`** and **`release.distribution`**
  decide the `when=` conditions of catalog steps (Step 4).
- If no config block rendered, shell preprocessing is disabled; fall back to the
  defaults in `.claude/docs/config-resolution.md`.

Everything else — the latest sprint, the session state, the stage estimate and
`localization.locales` — is read at run time with Read, Glob and Bash in the steps
below.

---

## Step 1: Read the Catalog

Read `.claude/docs/workflow-catalog.yaml`. This is the authoritative list of all
phases, their steps (in order), whether each step is required or optional, the
tiers and conditions under which a required step applies, and the artifact globs
that indicate completion.

---

## Step 1b: Find Skills Not in the Catalog

After reading the catalog, Glob `.claude/skills/*/SKILL.md` to get the full list
of installed skills. For each file, extract the `name:` field from its frontmatter.

Compare against the `command:` values in the catalog. Any skill whose name does
not appear as a catalog command is an **uncataloged skill** — still usable but not
part of the phase-gated workflow.

Collect these for the output in Step 7 — show them as a footer block:

```
### Also installed (not in workflow)
- `/skill-name` — [description from SKILL.md frontmatter]
- `/skill-name` — [description]
```

Only show this block if at least one uncataloged skill exists. Limit to the 10
most relevant based on the user's current phase (QA skills in Build, team skills
in Build and Hardening, operations skills in Launch, etc.).

---

## Step 2: Determine Current Phase

Check in this order:

1. **Take `project.stage` from the config block above** when it is set — it is
   already resolved and enum-validated. The catalog phase id is the stage value in
   lowercase (`Build` → `build`); there is no mapping table.

2. **If `project.stage` is not set**, run the shared stage estimator — the single
   ladder the status line, `/project-stage-detect` and `/gate-check` also use:

   ```
   Bash: bash .claude/scripts/stage-estimate.sh
   ```

   Take its `STAGE:` line (lowercased) as the current phase and keep its
   `EVIDENCE:` clause — say in the output that the phase is estimated and why
   ("Estimated: Definition — `design/prd/goals.md` exists"). Do not re-derive the
   stage from your own reading of the tree: one ladder means `/help` and the gates
   can never disagree about the same project.

   If `stage-estimate.sh` exits non-zero or prints no `STAGE:` line, print no
   completion report and end with `Verdict: **NOT ASSESSED** — stage-estimate.sh
   could not run (<error>); fix it and re-run, or use /project-stage-detect.`

3. **Take `workflow` from the config block above** (per
   `.claude/docs/workflow-modes.md`). It controls whether optional docs are
   surfaced as next steps (Step 5) and which required steps apply (Step 4).

4. **Read `localization.locales` from `project.yaml`** with Read (it has no
   config-block label). Absent key ⇒ the locale list is unset, which is not the
   same as a single locale.

---

## Step 3: Read Session Context

Read `production/session-state/active.md` if it exists — it is append-only and grows unbounded, and only the latest block is relevant, so read just the tail rather than the whole file: grep the last heading (`Grep pattern="^## (Session Extract|STATUS)" path="production/session-state/active.md" output_mode="content" -n`, take the highest line number) and `Read(offset=that line)`. Extract:
- What was most recently worked on
- Any in-progress tasks or open questions
- Current epic/feature/task from STATUS block (if present)

Then Glob `production/sprints/sprint-*.md` and take the newest (highest sprint
number) as the latest sprint; none ⇒ "no sprint plan yet".

This tells you what the user just finished or is stuck on — use it to personalize
the output.

---

## Step 4: Check Step Completion for the Current Phase

For each step in the current phase (from the catalog):

### Artifact-based checks

**Resolve these deterministically — one call, not a glob per step:**

```
Bash: bash .claude/scripts/artifact-check.sh --phase [current-phase]
```

`[current-phase]` is the catalog id from Step 2 and is never empty — the script
exits 2 on an empty `--phase`, and a run that errored is not a report. If
`artifact-check.sh` exits non-zero or prints no `STEPS:` line, print no completion
report and end with `Verdict: **NOT ASSESSED** — artifact-check.sh could not run
(<error>); fix it and re-run, or use /project-stage-detect.`

It evaluates every `glob`, `pattern`, `min_count` and `any_of` in the catalog
against the working tree and reports one line per step. Map its statuses:

| status | Report as |
|---|---|
| `PRESENT` | **Complete** |
| `ABSENT` | **Incomplete** |
| `SHORT` | **Incomplete** — say how far short (`count=`/`min=` are given) |
| `PATTERN_MISS` | **Incomplete** — the file exists but lacks its marker; say so, since "missing" would send the user to recreate a file they already have |
| `NO_CHECK` | **MANUAL** if the step carries a `note=`, else **UNKNOWN** — completion is not trackable (e.g. repeatable implementation work) |

Do not re-derive any of this with Glob/Grep. `any_of` in particular is a list of
**alternatives** — one match is enough — and hand-evaluating it produces false
"incomplete" results: `product-brief` is satisfied by
`design/product/product-brief.md` **or** by `design/product/one-pager.md`, and
the script reports which alternative matched (`alt=`/`match=`).

**`NO_CHECK` never means done.** The script prints a `NO_CHECK:` total before the
rows; if most of a phase is NO_CHECK, say that plainly rather than implying the
phase is nearly complete.

### Required or optional — apply `tiers=` and `when=`

Every `STEP:` line carries `tiers=` and `when=`. The script only echoes them; this
skill applies them to each `required=true` step:

1. **Tier** — `tiers=all`, or a list that contains the resolved `workflow` ⇒ the
   tier requires the step. A list that does not contain it ⇒ render the step as
   **OPTIONAL** with the note "(required at <tiers>)".
2. **Condition** (only when the tier requires it) — `when=always` ⇒ REQUIRED.
   Otherwise decide the condition from the config block and the locale list:

   | `when=` | True when | Inputs |
   |---|---|---|
   | `ui` | `platform.surfaces` contains `web`, `ios` or `android` | `platform.surfaces` |
   | `backend` | the `stack` line shows a `backend=` layer, or a `data=` layer, or `platform.surfaces` contains `api` | `stack`, `platform.surfaces` |
   | `pii` | `compliance` shows `handles_pii=true` | `compliance` |
   | `stores` | `release.distribution` is `stores` or `web+stores` | `release.distribution` |
   | `multi-locale` | `localization.locales` has two or more entries | `localization.locales` |

   - **Known true** ⇒ REQUIRED.
   - **Known false** — every input is set and none makes it true ⇒ render as
     **OPTIONAL** with the note "(required when <cond>)".
   - **Unknown** — an input the answer depends on is unset (an `(unset -- ask …)`
     line, `stack: unset — run /setup-stack`, no `localization.locales` key) ⇒
     render as **REQUIRED** with the note "(when <cond> — unknown; run
     /setup-stack)". Unset is not false. A layer listed under `unset=` on a
     configured `stack` line is known to be absent, not unknown.
3. A step line carrying `tiers_error=` or `when_error=` is a catalog defect: report
   it by name ("catalog defect: <step> — <field>") instead of trusting that field.

### Special case: Build and Launch — read `sprint-status.yaml`

When the current phase is `build` or `launch`, check for `production/sprint-status.yaml`
before doing any glob-based story checks. If it exists, read it directly:

- Stories with `status: in-progress` → surface as "currently active"
- Stories with `status: review` → surface as "in review — close with `/story-done`"
- Stories with `status: ready-for-dev` → surface as "next up"
- Stories with `status: done` → count as complete
- Stories with `status: blocked` → surface as blocker with the `blocker` field

This gives precise per-story status without markdown scanning. Skip the glob
artifact check for the `implement` and `story-done` steps — the YAML is authoritative.

### Special case: `repeatable: true` (outside Build and Launch)

For repeatable steps in the other phases (e.g. "Feature PRDs"), the artifact
check tells you whether *any* work has been done, not whether it's finished.
Label these differently — show what's been detected, then note it may be ongoing.

---

## Step 5: Find Position and Identify Next Steps

From the completion data, determine:

1. **Last confirmed complete step** — the furthest completed required step
2. **Current blocker** — the first incomplete *required* step (this is what the
   user must do next)
3. **Optional opportunities** — incomplete *optional* steps that can be done
   before or alongside the blocker. **Surface these per the workflow tier**: at
   `full`, list all of them; at `standard`, list an optional doc only if it is
   required for the current feature/phase (do not flag genuinely-optional docs as
   gaps); at `minimal`, do not surface optional docs at all — except the
   `stack-setup` step (Discovery, or Definition) while `stack.pinned_on` is unset:
   a pinned stack is the floor before code even at `minimal`
   (`.claude/docs/workflow-modes.md`), and the catalog marks it required from the
   Architecture phase. Once the one-pager
   and the stack pin exist, the next step is code (the one-pager's
   `## Build Order` is the plan). A step shown as OPTIONAL keeps its
   "(required at …)" or "(required when …)" note.
4. **Upcoming required steps** — required steps after the current blocker
   (show as "coming up" so user can plan ahead)

If the user provided an argument (e.g. "just finished prd-review"), use that
to advance past the step they named even if the artifact check is ambiguous.

---

## Step 6: Check for In-Progress Work

If `active.md` shows an active task or epic:
- Surface it prominently at the top: "It looks like you were working on [X]"
- Suggest continuing it or confirm if it's done

---

## Step 7: Present Output

Keep it **short and direct**. This is a quick orientation, not a report.

```
## Where You Are: [Phase Label]  ([from project.stage | estimated — EVIDENCE clause])

**In progress:** [from active.md, if any]
**Latest sprint:** [production/sprints/sprint-NN.md | none yet]

### ✓ Done
- [completed step name]
- [completed step name]

### → Next up (REQUIRED)
**[Step name]** — [description] [(when <cond> — unknown; run /setup-stack), if any]
Command: `[/command]`

### ~ Also available (OPTIONAL)
- **[Step name]** — [description] → `/command` [(required at …) / (required when …), if any]
- **[Step name]** — [description] → `/command`

### Coming up after that
- [Next required step name] (`/command`)
- [Next required step name] (`/command`)

---
Approaching **[next phase]** gate → run `/gate-check [next-phase-id]` when ready.
```

**Formatting rules:**
- `✓` for confirmed complete
- `→` for the current required next step (only one — the first blocker)
- `~` for optional steps available now
- Show commands inline as backtick code
- If a step has no command (e.g. "Implement Stories"), explain what to do instead of showing a slash command
- For MANUAL steps, ask the user: "I can't tell if [step] is done — has it been completed?"
- In the Launch phase there is no next gate: replace the last line with
  "Launch is terminal — no further phase gate; use /release-checklist, /rollout-plan
  and /retrospective release <version>."

The verdict line is `Verdict: **COMPLETE** — next steps identified.` — or, when
Step 2 or Step 4 could not run its script, the NOT ASSESSED line given there (and
no report above it).

---

## Step 8: Gate Warning (if close)

After the current phase's steps, check if the user is likely approaching a gate:
- If all required steps in the current phase are complete (or nearly complete),
  add: "You're close to the **[Current] → [Next]** gate. Run `/gate-check [next-phase-id]` when ready."
  The argument is the **target** phase — the catalog `next_phase` of the current
  phase (in Validation: `/gate-check build`).
- If multiple required steps remain, skip the gate warning — it's not relevant yet.
- In Launch, never suggest a gate (see the Launch line in Step 7).

---

## Step 9: Escalation Paths

After the recommendations, if the user seems stuck or confused, add:

```
---
Need more detail?
- `/project-stage-detect` — full gap analysis with all missing artifacts listed
- `/gate-check [next-phase-id]` — formal readiness check for your next phase
- `/start` — re-orient from scratch
- `/settings` — if the process feels mismatched to your project, adjust
  `modes.rigor`. Apply the change-triggers in
  `.claude/docs/settings-guidance.md` § 4: a **lower** tier when the user sounds
  overwhelmed by process (and rigor isn't already `minimal`), or a **higher** tier
  when the project has outgrown it (the PRD count crossed its band, or the stage
  reached `Build` or later on `rigor: minimal`)
```

Only show this if the user's input suggested confusion (e.g. "I don't know", "stuck",
"lost", "not sure"). Don't show it for simple "what's next?" queries. Show the
`/settings` rigor line only when a `.claude/docs/settings-guidance.md` § 4 trigger actually
fires — the user sounds overwhelmed (and rigor isn't already `minimal`), or the
project has outgrown its tier — not on every confused query.

---

## Collaborative Protocol

- **Never auto-run the next skill.** Recommend it, let the user invoke it.
- **Ask about MANUAL steps** rather than assuming complete or incomplete.
- **Unknown is not no.** A step whose condition could not be decided stays on the
  list as REQUIRED with its "unknown; run /setup-stack" note — never drop it
  because a setting is missing.
- **Match the user's tone** — if they sound stressed ("I'm totally lost"), be
  reassuring and give one action, not a list of six.
- **One primary recommendation** — the user should leave knowing exactly one thing
  to do next. Optional steps and "coming up" are secondary context.
