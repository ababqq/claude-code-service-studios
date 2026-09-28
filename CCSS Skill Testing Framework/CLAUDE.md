# CCSS Skill Testing Framework — Claude Instructions

This folder is the quality assurance layer for the Claude Code Service Studios skill/agent
framework. It tests the framework itself — skills and agents — and is separate from any
product built with it.

## Key files

| File | Purpose |
|------|---------|
| `catalog.yaml` | Master registry: one entry per skill (`.claude/skills/*/SKILL.md`) and one per agent (`.claude/agents/*.md`). Contains category, spec path, priority (skills) and last-test tracking fields. Always read this first when running any test command. Totals come from counting entries — never from a number written in prose. |
| `quality-rubric.md` | Category-specific pass/fail metrics. Read the matching `###` section for the skill's category when running `/skill-test category`. |
| `skills/[category]/[name].md` | Behavioral spec for a skill — at least 4 test cases (one of them a NOT ASSESSED case; one case per review mode for gate-spawning skills) + protocol compliance assertions. |
| `agents/[folder]/[name].md` | Behavioral spec for an agent — at least 4 test cases (one of them a NOT ASSESSED case: a required input is missing; the template carries six case types and a category may add its own, such as the stack NOT SOURCEABLE case) + static assertions on the canonical agent skeleton + protocol compliance assertions. |
| `templates/skill-test-spec.md` | Template for writing new skill spec files. |
| `templates/agent-test-spec.md` | Template for writing new agent spec files. |
| `results/` | Written by `/skill-test spec` when results are saved. Gitignored (`.gitignore` lists `CCSS Skill Testing Framework/results/`). |

## Path conventions

- Skill specs: `CCSS Skill Testing Framework/skills/[category]/[name].md` — the folder is the
  skill's catalog `category:` (singular).
- Agent specs: `CCSS Skill Testing Framework/agents/[folder]/[name].md` — folders are
  `directors/`, `leads/`, `specialists/`, `qa/`, `operations/` and `stack/` (flat, no
  per-framework subfolders).
- Catalog: `CCSS Skill Testing Framework/catalog.yaml`
- Rubric: `CCSS Skill Testing Framework/quality-rubric.md`

The `spec:` field in `catalog.yaml` is the authoritative path for each skill/agent spec.
Always read it rather than guessing the path. The spec basename, the catalog `name:`, the
skill directory (or agent file stem) and the frontmatter `name:` are the same string.

## Skill categories

```
gate        → gate-check
review      → prd-review, architecture-review, review-all-prds
authoring   → write-prd, quick-spec, architecture-decision, create-architecture,
              api-design, data-model, design-language, ux-design, ux-review
readiness   → story-readiness, story-done
pipeline    → create-epics, create-stories, dev-story, create-control-manifest,
              propagate-prd-change, map-features, walking-skeleton
analysis    → consistency-check, business-rules-check, feature-audit, code-review,
              tech-debt, scope-check, estimate, perf-profile, bundle-audit,
              security-audit, test-evidence-review, test-flakiness
team        → team-feature, team-content, team-ui, team-qa, team-release,
              team-hardening, team-growth
sprint      → sprint-plan, sprint-status, milestone-review, retrospective,
              changelog, release-notes
ops         → hotfix, incident, rollout-plan, postmortem
utility     → all remaining skills
```

The catalog `category:` field is authoritative; this list is a reading aid. The skill
category `ops` (production-safety skills) is distinct from the agent category `operations`
(operational roles).

## Agent categories

Catalog `category:` values are singular; spec folders are plural where the category name
allows it.

```
director    (agents/directors/)   → product-director, technical-director, delivery-manager,
                                    design-director
lead        (agents/leads/)       → product-manager, tech-lead, qa-lead
specialist  (agents/specialists/) → business-analyst, backend-engineer, frontend-engineer,
                                    mobile-engineer, platform-engineer, internal-tools-engineer,
                                    ml-engineer, design-engineer, product-designer,
                                    ux-researcher, ux-writer, prototyper, performance-engineer
qa          (agents/qa/)          → accessibility-specialist, security-engineer, qa-engineer
operations  (agents/operations/)  → release-manager, localization-lead, monetization-strategist,
                                    devops-engineer, sre-engineer, data-engineer,
                                    analytics-engineer, growth-manager, customer-success-manager
stack       (agents/stack/)       → web-specialist (nextjs-specialist, vue-nuxt-specialist),
                                    mobile-specialist (react-native-specialist,
                                    flutter-specialist, ios-specialist, android-specialist),
                                    backend-specialist (node-specialist, spring-specialist,
                                    python-specialist), data-specialist, cloud-specialist
```

## Workflow for testing a skill

1. Read `catalog.yaml` to get the skill's `spec:` path and `category:`
2. Read the skill at `.claude/skills/[name]/SKILL.md`
3. Read the spec at the `spec:` path
4. Evaluate assertions case by case (PASS / PARTIAL / FAIL / NOT ASSESSED)
5. Offer to write results to `results/` and update `catalog.yaml` — ask "May I write this to
   `<path>`?" first

## Workflow for testing an agent

`/skill-test spec [agent-name]` tests an agent. It follows the same steps with the agent
file `.claude/agents/[name].md` and the entry in the catalog's `agents:` section (its
`spec:` path and `category:`), evaluates the spec's Static Assertions and test cases plus
the metrics for the agent's category under the rubric's `## Agent Categories`, and records
only `last_spec` and `last_spec_result` — agent entries have no `last_static` or
`last_category` fields. `/skill-test category` is for skills only. Saved results go to
`results/skill-test-spec-[name]-[date].md`: an H1 (`# Agent Spec Test: [name]`) with the
`> **Verdict**:` line directly under it. `/skill-test audit` globs both
`.claude/skills/*/SKILL.md` and `.claude/agents/*.md` and diffs them against the catalog, so a
skill or agent without an entry shows up as a gap instead of disappearing.

## Workflow for improving a skill

Use `/skill-improve [name]`. It handles the full loop:
test → diagnose → propose fix → rewrite → retest → keep or revert.

## Spec validity note

Specs in this folder describe **current behavior**, not ideal behavior. They were
written by reading the skills, so they may encode bugs. When a skill misbehaves in
practice, correct the skill first, then update the spec to match the fixed behavior.
Treat spec failures as "this needs investigation," not "the skill is definitively wrong."

Specs assert the **canonical English text** of the skill or agent file — quoted prompts such
as "May I write this to `<path>`?", AskUserQuestion option labels, verdict tokens, headings.
At run time the model renders prompts in the user's conversation language; never assert that
runtime wording.

## Shipping this folder

**Optional to ship to end users; required for framework development.** Anyone who edits,
adds or reviews a skill or agent — including a product team customizing CCSS for its own
service — keeps this folder. A distribution that only runs the skills may leave it out.

Nothing under `.claude/` loads this folder at session start or from a hook; only `/skill-test`
and `/skill-improve` read it. Without it, `/skill-test static` still works (it reads
`SKILL.md` only), `/skill-test spec` and `/skill-test category` cannot run, `/skill-test audit`
reports that no catalog exists, and `/skill-improve` loses its spec pass.
