# Skill Test Spec: /onboard

## Skill Summary

`/onboard` writes an onboarding document for a new contributor — or a new agent
session — in one role: `pm`, `designer`, `frontend`, `backend`, `mobile`, `sre`,
`security` or `data`, or any other word as an **area** (e.g. `payments`). It runs on
the Haiku model. It reads `CLAUDE.md`, `project.yaml` (`project.name`,
`project.category`), the stage from the resolved `project.stage` line, the product brief or one-pager, the role's
agent definitions in `.claude/agents/`, and the role's slice of the repository — for
engineering roles the layer's code roots from the resolved `code_roots` line and the
framework and version from the `stack` line — plus current momentum (latest sprint
plan, `production/sprint-status.yaml`, newest retrospective, `docs/CHANGELOG.md`). It
has no shell access, so it does not read git history.

It checks its inputs first: a section whose input is absent is
`NOT ASSESSED — NO DATA`, and when every required input is absent the whole verdict is
`NOT ASSESSED — NO DATA`. After showing the document it asks "May I write this to
`production/onboarding/onboard-<role>-YYYY-MM-DD.md`?". Verdicts: **COMPLETE**
(document generated), **BLOCKED** (user declined write), `NOT ASSESSED — NO DATA`.

---

## Static Assertions (Structural)

Verified automatically by `/skill-test static` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`; `name: onboard` equals the directory `.claude/skills/onboard/` and the catalog entry `onboard`
- [ ] `description` is exactly "Onboarding doc for a new contributor or agent by role (pm, designer, frontend, backend, mobile, sre, security, data)."; `model: haiku`
- [ ] Bootstrap: the first body line is `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,stack,code_roots,project.stage` `` — this key string exactly
- [ ] `allowed-tools` grants `Bash(bash "*/.claude/skills/onboard/../../hooks/yaml-helper.sh" resolve_config *)` — the skill's own directory name
- [ ] The line after the bootstrap block is exactly ``Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] The automation prelude (the block beginning "**Automation mode**: Resolve `modes.automation`") follows that line verbatim
- [ ] `allowed-tools` is exactly: `Read, Glob, Grep, Write` + the grant (no plain `Bash`, no `AskUserQuestion`)
- [ ] Has ≥2 phase headings (`## Phase 1: Load Project Context` … `## Phase 5: Next Steps`)
- [ ] Contains the verdict keywords `COMPLETE`, `BLOCKED` and `NOT ASSESSED — NO DATA`
- [ ] Contains "May I write this to `production/onboarding/onboard-<role>-YYYY-MM-DD.md`?" before the write
- [ ] Output at the exact path `production/onboarding/onboard-<role>-YYYY-MM-DD.md`
- [ ] No `!` injection other than the bootstrap line; no `file:line` citations of other files
- [ ] Has a next-step handoff (`/sprint-status`, `/help`)

---

## Director Gate Checks

None. `/onboard` is an orientation skill: `review_mode` is not in its keys and it has
no `Agent` tool. No director gates apply.

---

## Test Cases

### Case 1: Happy Path — Backend engineer joining Moa in Build

**Fixture:**
- `project.yaml`: `project.name: Moa`, `project.category: B2C fintech (subscription savings)`, `project.stage: Build`
- The block prints `project.stage: Build (project.yaml)`
- The block prints `stack: … backend=NestJS 11.0 @apps/api,services/worker; data=PostgreSQL 16 … [routing: … backend-specialist>node-specialist, data-specialist]` and `code_roots: … backend=apps/api,services/worker; data=apps/api/prisma/migrations; shared=packages (project.yaml)`
- `design/product/product-brief.md`, `docs/architecture/adr-0001-identity-and-auth.md`, `docs/api/openapi.yaml`, `apps/api/CLAUDE.md` exist
- `production/sprints/sprint-04.md` and `production/sprint-status.yaml` exist

**Input:** `/onboard backend`

**Expected behavior:**
1. Checks the inputs first and records `FOUND` / `ABSENT` for each
2. Reads `backend-engineer` as the primary agent and `backend-specialist`, its routed sub-specialist `node-specialist`, and `data-specialist`
3. Scans `apps/api`, `services/worker` and `packages`, each root's `CLAUDE.md`, `docs/stack-reference/`, `docs/architecture/`, `docs/api/`
4. Produces the document with `# Onboarding: [Role/Area]`, `## Project Summary`, `## Your Role`, `## Project Architecture` (with `- **Stack**:` and `- **Code roots for this role**:`), `## Current Standards and Conventions`, `## Current State of Your Area`, `## Current Sprint Context`, `## Key Dependencies`, `## Common Pitfalls`, `## First Tasks`, `## Questions to Ask`
5. Asks "May I write this to `production/onboarding/onboard-backend-YYYY-MM-DD.md`?" and writes on yes
6. Reports `Verdict: **COMPLETE** — onboarding document generated.` and the next steps

**Assertions:**
- [ ] The stack and version come from the resolved `stack` line, the roots from the `code_roots` line — not from a guess
- [ ] The current stage (`Build`) is taken from the resolved `project.stage` line, not re-read from `project.yaml` or inferred from artifacts
- [ ] The current stage and the sprint context are summarized (not only file names)
- [ ] The document is shown before the write question
- [ ] The file lands at `production/onboarding/onboard-backend-YYYY-MM-DD.md`

---

### Case 2: Blocked — User declines the write

**Fixture:**
- Same as Case 1

**Input:** `/onboard backend` → the user answers "no" to the write question

**Expected behavior:**
1. The document is presented in the conversation
2. Nothing is written; the skill stops with `Verdict: **BLOCKED** — user declined write.`

**Assertions:**
- [ ] No file is created under `production/onboarding/`
- [ ] Verdict is BLOCKED, not COMPLETE

---

### Case 3: NOT ASSESSED — Fresh template, no inputs

**Fixture:**
- No product brief or one-pager, no PRD or ADR, no sprint records
- The block prints `stack: unset — run /setup-stack` and `code_roots: unresolved — NOT CHECKED (set stack.layers.<layer>.root via /setup-stack)`

**Input:** `/onboard frontend`

**Expected behavior:**
1. The input check records every required input as `ABSENT`
2. The skill stops and reports `NOT ASSESSED — NO DATA` as the whole verdict, naming what was missing and which skill produces it (e.g. `/start`, `/brainstorm`, `/setup-stack`)

**Assertions:**
- [ ] No section is estimated or inferred from an adjacent artifact
- [ ] No filled-in onboarding document is produced
- [ ] Verdict is `NOT ASSESSED — NO DATA`, never COMPLETE

---

### Case 4: Role-Specific Onboarding — Product designer

**Fixture:**
- `design/brand/design-language.md`, `design/ux/app-shell.md`, `design/ux/goals-create.md`, `design/accessibility-requirements.md` exist
- The active sprint has UI stories for `goals`

**Input:** `/onboard designer`

**Expected behavior:**
1. Reads `product-designer` as the primary agent and `design-director`, `ux-writer`, `design-engineer`, `accessibility-specialist`
2. Scans `design/brand/`, `design/ux/`, `design/inventory/`, `design/accessibility-requirements.md`
3. The document is tailored to the designer role; code structure and ADRs are secondary

**Assertions:**
- [ ] The H1 follows `# Onboarding: [Role/Area]` and names the designer role
- [ ] The design language and UX specs are summarized when they exist
- [ ] Current UI stories from the active sprint are shown

---

### Case 5: Edge Case — Role whose layer is not configured

**Fixture:**
- The block prints `stack: web=Next.js 15.3 @apps/web; backend=NestJS 11.0 @apps/api; unset=mobile,data,cloud …`
- The `code_roots` line lists `undeclared=services/notifier (workspace)`

**Input:** `/onboard mobile`

**Expected behavior:**
1. The mobile layer is listed under `unset=`: the skill prints `NOT CHECKED — mobile layer not configured (run /setup-stack)`
2. The document says the codebase section could not be written, instead of describing a directory that does not exist
3. Undeclared roots are named with `WARN: undeclared code roots: services/notifier — declare them with /setup-stack`

**Assertions:**
- [ ] The skipped scan announces itself by name
- [ ] No mobile directory or framework is invented
- [ ] Other sections (project summary, sprint context) are still written from their inputs

---

### Case 6: Director Gate Check — No gate; onboard is an orientation utility

**Fixture:**
- Any configured project state

**Input:** `/onboard pm`

**Expected behavior:**
1. The document is produced and written after approval
2. No director agent is spawned; no gate IDs appear

**Assertions:**
- [ ] No director gate is invoked and no gate skip message appears
- [ ] The only write is the onboarding document, after "May I write"

---

## Protocol Compliance

- [ ] Reads all source files before generating output (no invented project state)
- [ ] Adapts the document to the project stage and the role or area
- [ ] Uses "May I write this to `<path>`?" before the single write, per the automation prelude
- [ ] Writes nothing under `production/session-logs/`; never writes `project.yaml`
- [ ] Ends with COMPLETE, BLOCKED or `NOT ASSESSED — NO DATA`

---

## Category Rubric (`utility`)

- `utility U1` — the static checks above pass: bootstrap line and grant exact, `--keys` exact, plain follow-on line, automation prelude, "May I write" before the write, output path exact
- `utility U2` — not applicable (no director gate)
- The NOT ASSESSED case is Case 3 (missing input: nothing to onboard onto)

---

## Coverage Notes

- Roles `frontend`, `sre`, `security` and `data` follow the same tailoring pattern as Cases 1 and 4 with the scan
  lists in SKILL.md Phase 2; they are not fixture-tested separately.
- An **area** argument (e.g. `payments`) picks the best-matching agent and says which one it chose; not
  fixture-tested here.
- Git history is out of scope: the skill has no shell access.
