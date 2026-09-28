# Skill Quality Rubric

Used by `/skill-test category [name|all]` to evaluate skills beyond structural compliance.
Each category defines binary PASS/FAIL metrics specific to the skill's job (4–5 for most
categories).

A metric is PASS when the skill's written instructions clearly satisfy the criterion.
A metric is FAIL when the instructions are absent, ambiguous, or contradictory.
A metric is WARN when the instructions partially address the criterion.

Metrics judge the canonical English text of `SKILL.md` — quoted prompts, option labels,
verdict tokens and headings — never the wording the model renders at run time in the
user's conversation language.

---

## Skill Categories

### `gate`

**Skills**: gate-check

Gate skills control phase transitions. They must enforce correctness without
auto-advancing the stage and must respect the three review modes.

| Metric | PASS criteria |
|---|---|
| **G1 — Review mode read** | Skill reads `review_mode` from its `resolve_config` block (its bootstrap line requests the `review_mode` label; `--review` overrides it for one run) before deciding which directors to spawn — no other file is read for the mode |
| **G2 — Panel width** | Panel width follows `modes.workflow` per `/gate-check` §4b Director Panel Assessment (1 / 2 / 4 directors — the table lives only there); DD-PHASE-GATE is omitted when no UI surface is configured (known, not unset); every omission is named in the report |
| **G3 — Lean mode: PHASE-GATE only** | In `lean` mode, only gate IDs ending in `-PHASE-GATE` run; every other gate is skipped with the note `[GATE-ID] skipped — Lean mode`. The skill applies the suffix rule and does not enumerate a list of gate IDs |
| **G4 — Solo mode: no directors** | In `solo` mode, no director gates spawn; each is noted as `[GATE-ID] skipped — Solo mode` |
| **G5 — No auto-advance** | Skill never writes `project.stage` in `project.yaml` without explicit user confirmation via "May I update `project.stage` …?"; re-reads `project.yaml` after writing to verify; passes `artifact-check.sh` the departure phase derived from the target phase (never the current `project.stage`) |

---

### `review`

**Skills**: prd-review, architecture-review, review-all-prds

Review skills read documents and produce structured verdicts. They are primarily
read-only and must not trigger director gates during the analysis phase.

| Metric | PASS criteria |
|---|---|
| **R1 — Read-only enforcement** | Skill does not modify the reviewed document without explicit user approval; any write operations (review logs, registry or index updates) are gated behind "May I write" |
| **R2 — Contract sections checked** | Skill evaluates the PRD sections the resolved `modes.workflow` tier requires — the section contract of `.claude/docs/templates/prd.md`, checked with `bash .claude/scripts/prd-structure-check.sh` — or, for architecture, the ADR headings of `.claude/docs/templates/architecture-decision-record.md` |
| **R3 — Correct verdict vocabulary** | Verdict is exactly one of: APPROVED / NEEDS REVISION / MAJOR REVISION NEEDED (`/prd-review`) or PASS / CONCERNS / FAIL (`/architecture-review`, `/review-all-prds`), plus NOT ASSESSED when the review could not be carried out |
| **R4 — No director gates during analysis** | Skill does not spawn director gates during its analysis phases; a post-analysis director review is acceptable only when the skill's scope and stakes warrant it and the skill states it |
| **R5 — Structured findings** | Output contains a per-section status table or checklist before the final verdict |

> **Exception:**
> - `prd-review`: Has `Write, Edit` in allowed-tools to write its review log and, after APPROVED, to set the PRD `> **Status**: Approved` and the feature-map row — each write behind user approval. R1 is satisfied because the reviewed document is never silently modified.

---

### `authoring`

**Skills**: write-prd, quick-spec, architecture-decision, create-architecture, api-design,
data-model, design-language, ux-design, ux-review

Authoring skills create or update product and technical documents collaboratively.
Full PRD, UX and design-language authoring skills use a section-by-section cycle;
lightweight authoring skills use a single-draft pattern appropriate to their scope.

| Metric | PASS criteria |
|---|---|
| **A1 — Section-by-section cycle** | Full authoring skills (write-prd, ux-design, design-language) author one section at a time, presenting content for approval before proceeding to the next. Lightweight skills (quick-spec, architecture-decision, create-architecture, api-design, data-model) may draft a complete artifact and then ask for approval — one draft per artifact. |
| **A2 — May-I-write per section** | Full authoring skills ask "May I write this to [filepath]?" before each section write. Lightweight skills ask once per artifact (a skill that writes several artifacts — contract, change record, migration plan — asks once for each). |
| **A3 — Retrofit mode** | Skill detects if the target file already exists and offers to update specific sections rather than overwriting the whole document. Lightweight skills that always create new files (quick-spec) are exempt. |
| **A4 — Director gate at correct tier** | If a director gate is defined for this skill (e.g., PD-PRD-ALIGN, TD-ADR, SE-SECURITY-REVIEW, DD-DESIGN-LANGUAGE), the skill applies the review mode before spawning it: `full` spawns; `lean` → skip every gate whose ID does not end in `-PHASE-GATE`; `solo` skips all — each skip noted as `[GATE-ID] skipped — <Mode> mode` |
| **A5 — Skeleton from the template** | Full authoring skills create the file skeleton with all section headers before filling content, to preserve progress on session interruption, and the skeleton headings are byte-identical, in order, to the template file the skill names (e.g. `.claude/docs/templates/prd.md`, `design-language.md`, `ux-spec.md`) — a skill either copies the template file or carries an inline skeleton whose headings reproduce the template exactly (`write-prd` Phase 3, `ux-design` Section 3); an inline skeleton that drifts from its template fails A5. Lightweight skills are exempt from skeleton-first, not from template fidelity: an artifact they write from a template keeps its headings byte-identical. |

> A5 for members without a template file under `.claude/docs/templates/`: `/quick-spec` — the headings of the category formats in its `## 3. Draft the Quick Spec`; `/ux-review` — the review-record format of its Phase 4b (`# UX Review:` with the `> **Verdict**:` line directly under it). `/ux-review` is the category's review-shaped member: A1–A3 do not apply to it; A4 and A5 do.

> **Full authoring skills** (must pass all 5 metrics): `write-prd`, `ux-design`, `design-language`
> **Lightweight authoring skills** (A1, A2 use the single-draft pattern; A3 exempt for new-file-only skills; A5 template fidelity only): `quick-spec`, `architecture-decision`, `create-architecture`, `api-design`, `data-model`
> **Review-shaped skill** (A4 and A5 only; A1–A3 do not apply): `ux-review`

---

### `readiness`

**Skills**: story-readiness, story-done

Readiness skills validate stories before or after implementation. They must produce
multi-dimensional verdicts and integrate correctly with director gate mode.

| Metric | PASS criteria |
|---|---|
| **RD1 — Multi-dimensional check** | Skill checks ≥3 independent dimensions (e.g., PRD, ADR, API contract, migration, scope, DoD) and reports each separately |
| **RD2 — Verdict levels** | Verdict hierarchy is clearly defined: READY/COMPLETE > NEEDS WORK/COMPLETE WITH NOTES > BLOCKED, with NOT ASSESSED available when a dimension could not be checked |
| **RD3 — BLOCKED requires external action** | BLOCKED verdict is reserved for issues that cannot be fixed by the story author alone (e.g., Proposed ADR, missing API contract operation, unresolvable dependency) |
| **RD4 — Director gate at correct mode** | QL-STORY-READY, TL-CODE-REVIEW or QL-TEST-COVERAGE spawns in `full` mode and is skipped in `lean`/`solo` (none of them ends in `-PHASE-GATE`) with a noted skip message |
| **RD5 — Next-story handoff** | After completion, skill surfaces the next READY story from the active sprint |

---

### `pipeline`

**Skills**: create-epics, create-stories, dev-story, create-control-manifest,
propagate-prd-change, map-features, walking-skeleton

Pipeline skills produce artifacts that other skills consume. They must write files
with correct schema, respect layer/priority ordering, and gate before writing.

| Metric | PASS criteria |
|---|---|
| **P1 — Correct output schema** | Each produced file follows the project template (EPIC.md, the story header block, the feature-map columns, etc.); skill references the template path |
| **P2 — Layer/priority ordering** | Skills that produce epics or stories respect layer ordering (Foundation → Core → Feature → Presentation) and priority fields |
| **P3 — May-I-write before each artifact** | Skill asks "May I write this to [filepath]?" before creating each output file, not batch-approving all files at once |
| **P4 — Director gate at correct tier** | In-scope gates (DM-EPIC, QL-STORY-READY, TD-MANIFEST, TD-CHANGE-IMPACT, PD-FEATURE-MAP, etc.) run in `full` and are skipped in `lean`/`solo` with a noted skip (lean: skip every gate whose ID does not end in `-PHASE-GATE`) |
| **P5 — Reads before writes** | Skill reads the relevant PRD, ADR, API contract or manifest before producing artifacts to ensure alignment |

---

### `analysis`

**Skills**: consistency-check, business-rules-check, feature-audit, code-review, tech-debt,
scope-check, estimate, perf-profile, bundle-audit, security-audit, test-evidence-review,
test-flakiness

Analysis skills scan the project and surface findings. They are read-only during
analysis and must ask before recommending any file writes.

| Metric | PASS criteria |
|---|---|
| **AN1 — Read-only scan** | Analysis phase uses only Read/Glob/Grep and read-only commands (e.g., a bundle-size report or a dependency audit); no Write or Edit during the scan itself |
| **AN2 — Structured findings table** | Output includes a findings table or checklist (not prose only) with severity/priority per finding |
| **AN3 — No auto-write** | Any suggested file writes (e.g., tech-debt register, fix patches, audit reports) are gated behind "May I write" |
| **AN4 — No director gates during analysis** | Analysis skills do not spawn director gates; specialist agents they consult return findings for human review, not gate verdicts |
| **AN5 — Could-not-run is reported** | A report the skill writes carries `> **Verdict**: <TOKEN>` directly under its H1 (rule 12 of `.claude/rules/skill-authoring.md` § Skill file rules); missing inputs, unset budgets or unresolved code roots yield `NOT ASSESSED` (or a named `NOT CHECKED — <reason>` line), never a PASS-class verdict; observations (measurements, counts, findings) are recorded apart from the verdict, which follows the skill's stated rules |

---

### `team`

**Skills**: team-feature, team-content, team-ui, team-qa, team-release, team-hardening,
team-growth

Team skills orchestrate multiple specialist agents for a cross-functional squad. They
must spawn the right agents, run independent ones in parallel, and surface blocks
immediately.

| Metric | PASS criteria |
|---|---|
| **T1 — Active set announced** | Skill explicitly names which agents it spawns and in what order, and — before spawning any agent — announces the active set for the resolved `team.size` (`individual` / `small` / `studio`); an agent outside the active set is reported as not run, never dropped in silence |
| **T2 — Parallel where independent** | Agents whose inputs don't depend on each other are spawned in parallel (single message, multiple Agent calls), and dependent phases wait until every parallel agent has returned |
| **T3 — BLOCKED surfacing** | If any spawned agent returns BLOCKED or fails, skill surfaces it immediately and halts dependent work — never silently skips |
| **T4 — Only its own gates, at the named phase** | Skill spawns only the director gates its `SKILL.md` assigns to it (e.g., QL-TEST-COVERAGE before `/team-qa` sign-off), at the phase it names, after the review-mode check — `lean` → skip every gate whose ID does not end in `-PHASE-GATE`; `solo` skips all; team-size scoping never removes a gate |
| **T5 — Usage error on no argument** | If required argument (e.g., feature name) is missing, skill outputs usage hint and stops without spawning agents |

---

### `sprint`

**Skills**: sprint-plan, sprint-status, milestone-review, retrospective, changelog, release-notes

Sprint skills read delivery state and produce reports or planning artifacts.
They have a DM-SPRINT or DM-MILESTONE gate at specific mode thresholds.

| Metric | PASS criteria |
|---|---|
| **SP1 — Reads sprint/milestone state** | Skill reads `production/sprints/`, `production/sprint-status.yaml` or `production/milestones/` before producing output |
| **SP2 — Correct sprint gate** | DM-SPRINT (for planning) or DM-MILESTONE (for milestone review) gate runs in `full` mode and is skipped in `lean`/`solo` with a noted skip |
| **SP3 — Structured output** | Output uses a consistent structure (velocity table, risk list, action items) rather than free prose |
| **SP4 — No auto-commit** | Skill never writes sprint files or milestone records without "May I write" |

---

### `ops`

**Skills**: hotfix, incident, rollout-plan, postmortem

Ops skills act on a running service: they drive incident response, ship emergency
fixes, plan production rollouts and review incidents afterwards. Their first
obligation is production safety.

| Metric | PASS criteria |
|---|---|
| **O1 — Collaboration mode** | `hotfix`, `incident`, `rollout-plan`: always collaborative — no automation prelude, every step approved. `postmortem`: honours `modes.automation` but asks before every write |
| **O2 — Never mutates production** | Skill never executes a production-mutating command (deploy, infrastructure apply, shared-database migration, secret change); it proposes the exact commands for a human to run and respects the permission deny list in `.claude/settings.json` |
| **O3 — Timestamped record** | Skill writes a timestamped record at its fixed path (e.g., `production/incidents/INC-YYYYMMDD-NN.md`, `production/hotfixes/hotfix-YYYY-MM-DD-<slug>.md`, `production/releases/<version>/rollout-plan.md`, `production/incidents/postmortems/INC-YYYYMMDD-NN.md`) with the line `> **Verdict**: <TOKEN>` directly under its H1 |
| **O4 — Exact severity tokens** | If the skill uses a severity scale, the tokens are exact: SEV1–SEV4 for incidents, S1-Critical / S2-Major / S3-Minor / S4-Trivial for bugs |
| **O5 — Hand-off** | `incident` → `/postmortem <INC-id>`; `hotfix` → `/postmortem <INC-id>` when linked to an incident, else `/retrospective release <version>`; `rollout-plan` → `/retrospective release <version>` |

> `hotfix`, `rollout-plan` and `incident` are also exempt from `modes.review_mode` — see
> `.claude/docs/director-gates.md` § Review Modes. Their specs assert the exemption
> instead of per-mode gate behaviour.

---

### `utility`

**Skills**: start, help, brainstorm, onboard, adopt, prototype, localize,
launch-checklist, release-checklist, smoke-check, load-test, test-setup, test-helpers,
regression-suite, qa-plan, bug-triage, bug-report, usability-report, ui-inventory,
design-handoff, reverse-document, project-stage-detect, setup-stack, settings, skill-test,
skill-improve, and any other skills not in categories above

Utility skills pass the 7 standard static checks. If they happen to spawn director
gates, the gate mode logic must also be correct.

| Metric | PASS criteria |
|---|---|
| **U1 — Passes all 7 static checks** | `/skill-test static [name]` returns COMPLIANT with 0 FAILs |
| **U2 — Gate mode correct (if applicable)** | If the skill spawns any director gate, it reads `review_mode` from its `resolve_config` block and applies full / lean / solo correctly — `lean` skips every gate whose ID does not end in `-PHASE-GATE` |

---

## Agent Categories

Used to validate the agent spec files in `agents/<folder>/` of this framework. Metric
IDs are scoped to their category heading — the `specialist` and `stack` sections both
number from `S`, and the agent category `operations` and the skill category `ops` both
number from `O` — so cite a metric as `<category> <ID>` (e.g., `stack S3`).

### `director`

**Agents**: product-director, technical-director, delivery-manager, design-director

| Metric | PASS criteria |
|---|---|
| **D1 — Correct verdict vocabulary** | Returns the exact tokens of the gates it owns, first line `[GATE-ID]: TOKEN` — APPROVE / CONCERNS / REJECT, or the gate's own set per `.claude/docs/director-gates.md` (e.g., READY / CONCERNS / NOT READY for a PHASE-GATE, REALISTIC / CONCERNS / UNREALISTIC and ON TRACK / AT RISK / OFF TRACK for delivery-manager, OPTIONS / STRONG / CONCERNS for DD-BRAND-DIRECTION) |
| **D2 — Domain boundary respected** | Does not make binding decisions outside its declared domain |
| **D3 — Conflict escalation** | When two departments conflict, escalates to the correct parent (product-director for product, UX and design conflicts; technical-director for technical and quality conflicts) rather than unilaterally deciding |
| **D4 — Model tier** | `model:` in frontmatter matches `.claude/docs/model-tiers.md`: `opus` for product-director, technical-director and delivery-manager; `inherit` for design-director, the fourth phase-gate panel seat |

### `lead`

**Agents**: product-manager, tech-lead, qa-lead

| Metric | PASS criteria |
|---|---|
| **L1 — Domain verdict** | Returns a domain-specific verdict (e.g., FEASIBLE / CONCERNS / INFEASIBLE for tech-lead's TL-FEASIBILITY, ADEQUATE / GAPS / INADEQUATE for qa-lead's gates, acceptance-criteria findings for product-manager) |
| **L2 — Escalates to shared parent** | Out-of-domain conflicts escalate to product-director (product) or technical-director (technical) |
| **L3 — Model tier** | `model:` in frontmatter matches `.claude/docs/model-tiers.md` (`sonnet` for tech-lead; `inherit` for product-manager and qa-lead) |

### `specialist`

**Agents**: business-analyst, backend-engineer, frontend-engineer, mobile-engineer,
platform-engineer, internal-tools-engineer, ml-engineer, design-engineer, product-designer,
ux-researcher, ux-writer, prototyper, performance-engineer

| Metric | PASS criteria |
|---|---|
| **S1 — Stays in domain** | Explicitly scopes itself to its declared domain; defers out-of-domain requests |
| **S2 — No binding cross-domain decisions** | Does not unilaterally decide matters owned by another specialist |
| **S3 — Defers correctly** | Out-of-domain requests are redirected to the correct agent, not refused silently |

### `stack`

**Agents**: web-specialist, nextjs-specialist, vue-nuxt-specialist, mobile-specialist,
react-native-specialist, flutter-specialist, ios-specialist, android-specialist,
backend-specialist, node-specialist, spring-specialist, python-specialist,
data-specialist, cloud-specialist

| Metric | PASS criteria |
|---|---|
| **S1 — Consults the stack reference** | Consults `docs/stack-reference/VERSION.md` and `docs/stack-reference/<component>/` before giving version-sensitive advice |
| **S2 — Flags post-cutoff APIs** | Flags APIs released after the model's knowledge cutoff with their Knowledge Risk instead of presenting them as settled |
| **S3 — Delegation lines** | Layer leads delegate only through their `Agent(...)` grant; sub-specialists escalate to their layer lead |
| **S4 — Stays inside its layer** | Advises and implements within its own layer (web, mobile, backend, data or cloud) and routes cross-layer questions to the owning lead or engineer |
| **S5 — NOT SOURCEABLE over guessing** | When the stack reference does not cover a question, says `NOT SOURCEABLE — run /setup-stack refresh` instead of answering from memory |

### `qa`

**Agents**: accessibility-specialist, security-engineer, qa-engineer

| Metric | PASS criteria |
|---|---|
| **Q1 — Produces verification artifacts, not feature code** | Primary output is test cases, test code (E2E, contract, integration), audits, bug reports, or coverage gaps — never product feature implementation |
| **Q2 — Evidence format** | Test evidence follows the story-type table in `.claude/docs/coding-standards.md` — Logic, Integration, UI, E2E, Config — with gate levels from `testing.strict.logic`, `testing.strict.integration`, `testing.strict.ui`, `testing.strict.e2e` and `testing.strict.config` |
| **Q3 — No scope creep** | Does not propose new features; flags gaps for humans to decide |

### `operations`

**Agents**: release-manager, localization-lead, monetization-strategist, devops-engineer,
sre-engineer, data-engineer, analytics-engineer, growth-manager, customer-success-manager

| Metric | PASS criteria |
|---|---|
| **O1 — Domain ownership clear** | Agent description clearly states what it owns (pipelines, releases, reliability, pricing, lifecycle, support, etc.) |
| **O2 — Defers implementation** | Does not implement product features (domain logic, UI); delegates them to the owning engineer |
| **O3 — Toolset matches role** | `tools` (and `disallowedTools`) in frontmatter match the operational nature of the role — no Bash for roles that only decide or write documents |
| **O4 — Never executes production-changing commands** | sre-engineer, devops-engineer, release-manager: use the Operations Workflow (Assess → Propose → Verify → Record) and never execute a command that changes production, shared infrastructure, a shared database or secrets — they give the exact commands for a human to run |
