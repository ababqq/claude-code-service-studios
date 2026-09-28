---
name: onboard
description: "Onboarding doc for a new contributor or agent by role (pm, designer, frontend, backend, mobile, sre, security, data)."
argument-hint: "[pm | designer | frontend | backend | mobile | sre | security | data | <area>]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash(bash "*/.claude/skills/onboard/../../hooks/yaml-helper.sh" resolve_config *)
model: haiku
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,stack,code_roots,project.stage`

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

## Insufficient input — check this before producing any report

**If the inputs this skill needs do not exist, the answer is "could not run" —
not a filled-in report.** Check first, and stop if the check fails.

1. List the inputs this skill reads (CLAUDE.md, `project.yaml`, the product brief or
   one-pager, PRDs, ADRs, the resolved stack and code roots, sprint records, the
   role's agent definition).
2. For each, record `FOUND` or `ABSENT` — not "assumed present".
3. If any input required for a section is ABSENT, that section is
   **`NOT ASSESSED — NO DATA`**. Do not estimate it, do not infer it from an
   adjacent artifact, and do not leave a mandated cell to be filled by whoever
   reads the template next.
4. If **every** required input is ABSENT, stop and report
   **`NOT ASSESSED — NO DATA`** as the whole verdict, naming what was missing and
   which skill produces it.

**A verdict of `NOT ASSESSED` is a success.** It is the correct, useful answer to
"what does the data say?" when there is no data. The failure mode this prevents is
specific and has been observed in practice: report templates whose verdict
enum had no "could not run" state produced **false clean passes** — an audit
returning COMPLIANT on a project with nothing to audit and no standards to audit
against, and a performance profile reporting ">99% headroom" against a budget
nobody had set, with zero measurements behind it.

**Absence of evidence is never evidence of absence.** A scan that finds no
matches because there are no files to scan has not verified anything. Say which of
the two happened — a reader cannot tell from a green result.

---

## Phase 1: Load Project Context

Read CLAUDE.md for project overview and standards, and `project.yaml` for
`project.name` and `project.category`; the stage is the resolved `project.stage`
line (not set ⇒ say so and suggest /project-stage-detect). Read the product brief
`design/product/product-brief.md` (or the one-pager `design/product/one-pager.md` at
`minimal`) for what the product is and who it serves.

Map the role to the agent definitions in `.claude/agents/` and read them — the
primary agent defines the role's responsibilities and standards, the others are the
people it works with most:

| Role | Primary agent | Also read |
|------|---------------|-----------|
| `pm` | `product-manager` | `business-analyst`, `product-director` |
| `designer` | `product-designer` | `design-director`, `ux-writer`, `design-engineer`, `accessibility-specialist` |
| `frontend` | `frontend-engineer` | `web-specialist` and its routed sub-specialist |
| `backend` | `backend-engineer` | `backend-specialist` and its routed sub-specialist, `data-specialist` |
| `mobile` | `mobile-engineer` | `mobile-specialist` and its routed sub-specialists |
| `sre` | `sre-engineer` | `devops-engineer`, `cloud-specialist` |
| `security` | `security-engineer` | `technical-director` |
| `data` | `data-engineer` | `analytics-engineer`, `data-specialist` |

The routed sub-specialists are the ones named in the `[routing: …]` part of the
`stack` line above. Any other argument is an **area** (for example `payments`,
`qa`, `admin-console`): find the agent whose description matches it best, say which
one you chose, and scan the area's PRD, stories and code.

---

## Phase 2: Scan Relevant Area

- **pm**: `design/product/` (brief, feature map, user journey, tracking plan, pricing
  model), `design/prd/`, `production/milestones/`, the latest sprint plan in
  `production/sprints/`.
- **designer**: `design/brand/` (design language, tokens, voice and tone),
  `design/ux/` (specs, app shell, interaction patterns), `design/inventory/`,
  `design/accessibility-requirements.md`, `design/handoff/` (retained Claude Design
  and Figma records — each `HANDOFF.md` and the UX spec it backs), and the
  configured design tool: read `design.tool` (with `design.figma.file_url` or
  `design.claude_design.project_url`) from `project.yaml` with Read and name it —
  `claude-design`, `figma` or `none`; absent means nobody has chosen yet (say so and
  name `/setup-stack` or `/design-handoff`), never `none`.
- **frontend / backend / mobile**: the layer's framework and version from the
  `stack` line; the layer's code roots from the `code_roots` line (`web`,
  `backend` or `mobile`, plus `shared`) — scan them for structure, patterns and key
  files, and read each root's `CLAUDE.md`; `docs/stack-reference/` for the pinned
  versions; `docs/architecture/` (architecture, ADRs, control manifest, tech
  radar); `docs/api/` for the contract.
- **sre**: `docs/ops/slo.md`, `docs/ops/runbooks/`, the `cloud` code root (IaC),
  `.github/workflows/`, `production/incidents/`, `production/releases/`.
- **security**: `docs/security/threat-model.md`, `production/security/`,
  `.claude/docs/compliance/`, the `## Data Classification` section of
  `docs/data/data-model.md`.
- **data**: `docs/data/data-model.md`, `docs/data/migrations/`, the `data` code root
  (migrations directory), `design/product/tracking-plan.md`.

When the layer the role works in is not configured, say so instead of guessing:
the `stack` line lists it under `unset=` (print
`NOT CHECKED — <layer> layer not configured (run /setup-stack)`), or the
`code_roots` line reads `unresolved` (print
`NOT CHECKED — no code root resolved (set stack.layers.<layer>.root via /setup-stack)`).
The onboarding doc then says the codebase section could not be written, rather than
describing a directory that does not exist. Undeclared workspace roots on the
`code_roots` line are included and named with
`WARN: undeclared code roots: <dirs> — declare them with /setup-stack`.

Read recent changes to understand current momentum: the latest sprint plan and
`production/sprint-status.yaml`, the newest retrospective in
`production/retrospectives/`, and `docs/CHANGELOG.md` when it exists. (This skill
has no shell access, so it does not read git history.)

---

## Phase 3: Generate Onboarding Document

```markdown
# Onboarding: [Role/Area]

## Project Summary
[2-3 sentence summary of what this product is, who it serves, and its current state
(`project.stage`)]

## Your Role
[What this role does on this project, key responsibilities, who you report to]

## Project Architecture
[Relevant architectural overview for this role]

- **Stack**: [from the resolved `stack` line — framework and version per layer]
- **Code roots for this role**: [from the resolved `code_roots` line, or the NOT CHECKED line]

### Key Directories
| Directory | Contents | Your Interaction |
|-----------|----------|-----------------|

### Key Files
| File | Purpose | Read Priority |
|------|---------|--------------|

## Current Standards and Conventions
[Summary of conventions relevant to this role from CLAUDE.md, the agent definition,
the control manifest and the `.claude/rules/` files that apply to this role's paths]

## Current State of Your Area
[What has been built, what is in progress, what is planned next]

## Current Sprint Context
[What the team is working on now and what is expected of this role]

## Key Dependencies
[What other roles and services this role interacts with most]

## Common Pitfalls
[Things that trip up new contributors in this area]

## First Tasks
[Suggested first tasks to get oriented and productive]

1. [Read these documents first]
2. [Review this code/content]
3. [Start with this small task]

## Questions to Ask
[Questions the new contributor should ask to get fully oriented]
```

---

## Phase 4: Save Document

Present the onboarding document to the user.

Ask: "May I write this to `production/onboarding/onboard-<role>-YYYY-MM-DD.md`?"

If yes, write the file, creating the directory if needed.

If no, stop here. Verdict: **BLOCKED** — user declined write.

---

## Phase 5: Next Steps

Verdict: **COMPLETE** — onboarding document generated.

- Share the onboarding doc with the new contributor before their first session.
- Run `/sprint-status` to show the new contributor current progress.
- Run `/help` if the contributor needs guidance on what to work on next.
