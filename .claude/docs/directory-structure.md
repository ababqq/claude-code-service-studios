# Directory Structure

```text
/
├── CLAUDE.md                     # Master configuration (English)
├── project.yaml                  # Project config — stack, modes, stage (source of truth)
├── .claude/                      # Agents, skills, hooks, rules, docs, scripts
├── <code roots>/                 # Declared per layer in project.yaml stack.layers.<layer>.root — see below
├── design/
│   ├── CLAUDE.md
│   ├── product/                  # product-brief.md | one-pager.md, feature-map.md, user-journey.md,
│   │   │                         # tracking-plan.md, pricing-model.md, pitch.md, personas/<slug>.md,
│   │   │                         # product-brief-from-code-YYYY-MM-DD.md (reverse-document, for merging)
│   │   └── reviews/              # <stem>-review-log.md for the brief
│   ├── prd/                      # one PRD per feature: <feature-slug>.md  (NOTHING else at depth 1)
│   │   └── reviews/              # <stem>-review-log.md, prd-cross-review-YYYY-MM-DD.md
│   ├── quick-specs/              # <kebab-title>-YYYY-MM-DD.md
│   ├── ux/                       # UX specs <slug>.md, app-shell.md, interaction-patterns.md
│   │   └── reviews/              # <spec-stem>-ux-review-YYYY-MM-DD.md
│   ├── brand/                    # design-language.md, tokens.json, voice-and-tone.md
│   ├── content/                  # copy decks <area>.md, help-center/<slug>.md
│   ├── inventory/                # screen-inventory.md, media-manifest.md
│   ├── registry/entities.yaml    # glossary & business-fact registry
│   └── accessibility-requirements.md
├── docs/
│   ├── CLAUDE.md, COLLABORATIVE-DESIGN-PRINCIPLE.md (en), WORKFLOW-GUIDE.md (ko), skill-flow-diagrams.md (ko)
│   ├── CHANGELOG.md              # the PRODUCT's changelog, written by /changelog (not the framework's)
│   ├── architecture/             # architecture.md, adr-NNNN-<slug>.md, architecture-review-YYYY-MM-DD.md,
│   │                             # control-manifest.md, requirements-traceability.md, tr-registry.yaml,
│   │                             # tech-radar.md, change-impact-YYYY-MM-DD-<prd-stem>.md, tdd-<feature>.md
│   ├── api/                      # api-guidelines.md, openapi.yaml | schema.graphql | <svc>.proto | asyncapi.yaml
│   │   ├── changes/              # api-change-YYYY-MM-DD.md
│   │   └── guides/               # <slug>.md (developer guides — Public API only)
│   ├── data/                     # data-model.md
│   │   └── migrations/           # NNNN-<slug>.md (plans; executable migrations live in the data layer's migrations_dir)
│   ├── security/threat-model.md
│   ├── ops/                      # slo.md
│   │   └── runbooks/             # <alert-slug>.md
│   ├── registry/architecture.yaml
│   ├── stack-reference/          # README.md, VERSION.md, <component-slug>/{VERSION,breaking-changes,deprecated-apis,current-best-practices}.md
│   ├── tech-debt-register.md, adoption-plan-YYYY-MM-DD.md, consistency-failures.md (gitignored)
├── tests/                        # unit/, integration/, contract/, e2e/ (incl. capture.spec.ts), load/, helpers/,
│                                 # regression-suite.md (co-located tests allowed; testing.patterns says where)
├── prototypes/                   # <name>-concept/ (REPORT.md required), <name>-spike-YYYY-MM-DD/ (SPIKE-NOTE.md)
├── production/
│   ├── session-state/ (gitignored except .gitkeep), session-logs/ (gitignored — never evidence)
│   ├── sprints/sprint-NN.md, sprint-status.yaml, epics/<epic-slug>/{EPIC.md,story-NNN-<slug>.md}, epics/index.md
│   ├── milestones/<milestone>.md and <milestone>-review.md, retrospectives/, onboarding/,
│   │   gate-checks/gate-<target>-YYYY-MM-DD.md, project-stage-report-YYYY-MM-DD.md
│   ├── risk-register/<risk-slug>.md   # hand-authored from templates/risk-register-entry.md; /sprint-plan offers one
│   ├── walking-skeleton/report-YYYY-MM-DD.md
│   ├── qa/  smoke-YYYY-MM-DD.md, qa-plan-*.md, qa-signoff-*.md, hardening-YYYY-MM-DD.md, feature-audit-*.md,
│   │        bug-triage-*.md, evidence-review-*.md, flakiness-report-*.md, localization-qa-*.md,
│   │        evidence/<story-slug>/…, bugs/BUG-NNNN.md, test-cases/<feature>-cases.md, usability/…,
│   │        perf/{perf-profile-*,bundle-audit-*}.md, load/load-test-*.md (raw/ gitignored),
│   │        business-rules/business-rules-check-*.md
│   ├── security/security-audit-<mode>-YYYY-MM-DD.md
│   ├── releases/<version>/{release-checklist,rollout-plan,launch-checklist,release-notes,release-record}.md
│   ├── incidents/INC-YYYYMMDD-NN.md, incidents/postmortems/INC-YYYYMMDD-NN.md
│   ├── hotfixes/hotfix-YYYY-MM-DD-<slug>.md, growth/<experiment-slug>/{brief,readout}.md, localization/
└── CCSS Skill Testing Framework/  # QA for skills/agents — /skill-test, /skill-improve
```

`<version>` is `project.version` or the version passed to the skill (semver, e.g. `1.2.0`); mobile build numbers
go inside the release files, never in the directory name.

## Code roots

**Code roots**: there is no fixed code root. Each layer declares `stack.layers.<layer>.root` as a path or a flow
list of paths (monorepo e.g. `web: [apps/web, apps/admin]`, `mobile: apps/mobile`, `backend: [apps/api,
services/worker]`, `cloud: infra`, shared `packages`; single-app e.g. `src`). Workspace directories with a manifest
that no layer declares are still found and reported as `undeclared`. Resolution algorithm:
`.claude/docs/code-root-resolution.md`. The template ships **no** code-root directory.

- **Declared by `/setup-stack`.** It writes each layer's `root` (and `stack.shared_roots`,
  `stack.layers.data.migrations_dir`) into `project.yaml`, and offers to create a `<root>/CLAUDE.md` from
  `.claude/docs/templates/code-root-claude.md` for each configured root.
- **Undeclared workspaces are never silent.** A directory under `apps/*`, `services/*` or `packages/*` that holds a
  manifest (`package.json`, `pyproject.toml`, `build.gradle`, `go.mod`, `pubspec.yaml`, …) but belongs to no
  declared root is still scanned, and callers print one line:
  `WARN: undeclared code roots: <dirs> — declare them with /setup-stack`.
- **No default root.** `src/` is never assumed: with nothing declared, a single-app root is only *detected*
  (a manifest at the repository root and exactly one of `src/`, `app/`, `lib/`). When nothing resolves, a caller prints
  `NOT CHECKED — no code root resolved (set stack.layers.<layer>.root via /setup-stack)` and skips its scan.
  Shipping an empty code-root directory would make that unresolved state look resolved on a fresh clone, which is
  why the template ships none.
- **Path rules still apply.** `.claude/rules/` cannot read `project.yaml`, so every code rule lists both the
  `src/`-based convention and the src-less monorepo layouts (`apps/*/app/**`, `apps/*/components/**`,
  `apps/*/lib/**`, `packages/*/src/**`).
