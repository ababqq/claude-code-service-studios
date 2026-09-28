# CCSS Skill Testing Framework

Quality assurance infrastructure for the **Claude Code Service Studios** framework.
Tests the skills and agents themselves — not the product built with them.

**Optional to ship to end users; required for framework development.** CCSS is a
template you are expected to customize — edit a skill, add your own, retune an agent.
This folder is how you check that what you changed still holds up: `catalog.yaml`
tracks every skill and every agent (one entry each — count the entries, never trust a
number written in prose), `quality-rubric.md` defines per-category pass/fail metrics,
and `templates/` gives you the spec format for anything new you write. Driven by
`/skill-test` and `/skill-improve`.

> **What leaving it out costs.** A distribution that only runs the skills may drop this
> folder; anyone who changes a skill or agent needs it.
>
> | Mode | Without this folder |
> |------|---------------------|
> | `/skill-test static` | **Works** — the structural checks read `SKILL.md` only |
> | `/skill-test audit` | **Degrades** — reports that no catalog exists |
> | `/skill-test spec` | **Breaks** — the behavioral specs live here |
> | `/skill-test category` | **Breaks** — reads `quality-rubric.md` from here |
> | `/skill-improve` | **Degrades** — its test-fix-retest loop loses the spec pass |

---

## What's in here

```
CCSS Skill Testing Framework/
├── README.md              ← you are here
├── CLAUDE.md              ← tells Claude how to use this framework
├── catalog.yaml           ← master registry: every skill + every agent, coverage tracking
├── quality-rubric.md      ← category-specific pass/fail metrics for /skill-test category
│
├── skills/                ← behavioral spec files for skills (one per skill)
│   ├── gate/              ← gate category specs
│   ├── review/            ← review category specs
│   ├── authoring/         ← authoring category specs
│   ├── readiness/         ← readiness category specs
│   ├── pipeline/          ← pipeline category specs
│   ├── analysis/          ← analysis category specs
│   ├── team/              ← team category specs
│   ├── sprint/            ← sprint category specs
│   ├── ops/               ← ops category specs (incident, hotfix, rollout, postmortem)
│   └── utility/           ← utility category specs
│
├── agents/                ← behavioral spec files for agents (one per agent)
│   ├── directors/         ← product-director, technical-director, delivery-manager, design-director
│   ├── leads/             ← product-manager, tech-lead, qa-lead
│   ├── specialists/       ← product, design and engineering specialists (backend, frontend, mobile, platform, ML, …)
│   ├── qa/                ← qa-engineer, security-engineer, accessibility-specialist
│   ├── operations/        ← release, localization, monetization, DevOps, SRE, data, analytics, growth, customer success
│   └── stack/             ← stack layer leads and framework sub-specialists (web, mobile, backend, data, cloud)
│
├── templates/             ← spec file templates for writing new specs
│   ├── skill-test-spec.md ← template for skill behavioral specs
│   └── agent-test-spec.md ← template for agent behavioral specs
│
└── results/               ← test run outputs (written by /skill-test spec, gitignored)
```

---

## How to use it

All testing is driven by two skills already in the framework:

### Check structural compliance

```
/skill-test static [skill-name]     # Check one skill
/skill-test static all              # Check every skill under .claude/skills/
```

### Run a behavioral spec test

```
/skill-test spec gate-check         # Evaluate a skill against its written spec
/skill-test spec prd-review
/skill-test spec sre-engineer       # Agents have specs too
```

### Check against category rubric

```
/skill-test category gate-check     # Evaluate one skill against its category metrics
/skill-test category all            # Run rubric checks across all categorized skills
```

### See full coverage picture

```
/skill-test audit                   # Skills + agents: has-spec, last tested, result
```

`audit` globs `.claude/skills/*/SKILL.md` and `.claude/agents/*.md` and diffs both
against the catalog, so a skill or agent that was added without a catalog entry is
reported as a gap.

### Improve a failing skill

```
/skill-improve gate-check           # Test → diagnose → propose fix → retest loop
```

---

## Skill categories

| Category | Skills | Key metrics |
|----------|--------|-------------|
| `gate` | gate-check | `review_mode` from the resolved config, panel width per `modes.workflow`, lean runs only gate IDs ending in `-PHASE-GATE`, no auto-advance |
| `review` | prd-review, architecture-review, review-all-prds | Read-only, tier-required PRD sections or ADR headings checked, correct verdicts |
| `authoring` | write-prd, quick-spec, api-design, data-model, design-language, create-architecture, … | Section-by-section May-I-write, skeleton headings identical to the template |
| `readiness` | story-readiness, story-done | Blockers surfaced, gates skipped with a note outside `full` |
| `pipeline` | create-epics, create-stories, dev-story, map-features, walking-skeleton, … | Upstream dependency check, layer ordering, handoff path clear |
| `analysis` | consistency-check, business-rules-check, code-review, security-audit, … | Read-only scan, findings table with severity, no director gates, could-not-run reported as NOT ASSESSED |
| `team` | team-feature, team-content, team-ui, team-qa, … | Active set announced per `team.size`, only its own gates, blocked surfaced |
| `sprint` | sprint-plan, sprint-status, milestone-review, release-notes, … | Reads sprint data, status keywords present |
| `ops` | hotfix, incident, rollout-plan, postmortem | Never mutates production, timestamped record with verdict line, exact severity tokens, correct hand-off |
| `utility` | start, adopt, setup-stack, localize, smoke-check, … | Passes static checks; gate mode correct when it spawns gates |

---

## Agent categories

| Category (`category:`) | Spec folder | Agents |
|------|------|--------|
| `director` | `agents/directors/` | product-director, technical-director, delivery-manager, design-director |
| `lead` | `agents/leads/` | product-manager, tech-lead, qa-lead |
| `specialist` | `agents/specialists/` | business-analyst, backend-engineer, frontend-engineer, mobile-engineer, platform-engineer, internal-tools-engineer, ml-engineer, design-engineer, product-designer, ux-researcher, ux-writer, prototyper, performance-engineer |
| `qa` | `agents/qa/` | accessibility-specialist, security-engineer, qa-engineer |
| `operations` | `agents/operations/` | release-manager, localization-lead, monetization-strategist, devops-engineer, sre-engineer, data-engineer, analytics-engineer, growth-manager, customer-success-manager |
| `stack` | `agents/stack/` | web-specialist, nextjs-specialist, vue-nuxt-specialist, mobile-specialist, react-native-specialist, flutter-specialist, ios-specialist, android-specialist, backend-specialist, node-specialist, spring-specialist, python-specialist, data-specialist, cloud-specialist |

The catalog's `category:` field is authoritative; these tables are a reading aid.

---

## Updating the catalog

`catalog.yaml` tracks test coverage for every skill and agent. After running a test:

- `/skill-test spec [name]` will offer to update `last_spec` and `last_spec_result`
- `/skill-test category [name]` will offer to update `last_category` and `last_category_result`
- `last_static` and `last_static_result` are updated manually or via `/skill-improve`

`/skill-test spec [agent-name]` tests an agent: it reads the agent's entry in the
catalog's `agents:` section, evaluates the spec's Static Assertions and test cases plus
the metrics for the agent's category under `quality-rubric.md` § Agent Categories, and
records only `last_spec` and `last_spec_result`. `/skill-test category` is for skills
only. Saved results go to `results/skill-test-spec-[name]-[date].md`, an H1 with the
`> **Verdict**:` line directly under it.

Skill entries carry exactly `name`, `spec`, `last_static`, `last_static_result`,
`last_spec`, `last_spec_result`, `last_category`, `last_category_result`, `priority`
and `category`. Agent entries carry exactly `name`, `spec`, `last_spec`,
`last_spec_result` and `category`.

---

## Writing a new spec

1. Copy the template — `templates/skill-test-spec.md` for a skill,
   `templates/agent-test-spec.md` for an agent
2. Save it at `skills/[category]/[skill-name].md` or `agents/[folder]/[agent-name].md`
   (folder per the table above)
3. Write at least 4 test cases, one of them a NOT ASSESSED case (a required input is
   missing). A skill that spawns director gates gets one case per review mode:
   `full` spawns, `lean` skips every gate whose ID does not end in `-PHASE-GATE`,
   `solo` skips all. `/hotfix`, `/rollout-plan` and `/incident` get one case asserting
   their review-mode exemption instead.
4. Assert the canonical English text of the skill or agent file, never the wording the
   model uses at run time in the user's language
5. Add or update the entry in `catalog.yaml` so its `spec:` field points to the new file
6. Run `/skill-test spec [name]` to validate it

---

## Shipping without this folder

This folder has no hooks into the main project: nothing under `.claude/` loads it at
session start or from a hook. To build a distribution for end users who will only
run the skills:

```bash
rm -rf "CCSS Skill Testing Framework"
```

Keep it in the framework's own repository and in any fork where skills or agents are
edited. Without it, `/skill-test` and `/skill-improve` report that `catalog.yaml` is
missing, and only `/skill-test static` still runs in full.
