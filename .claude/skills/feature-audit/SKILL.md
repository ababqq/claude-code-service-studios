---
name: feature-audit
description: "Planned (PRD requirements, screens, endpoints, events, flags, notification templates, locales) versus implemented."
argument-hint: "[feature-slug] [--summary]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash(bash "*/.claude/skills/feature-audit/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys workflow,automation,code_roots`

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

# Feature Audit

Compares what the product planned with what the code implements, across seven
families of planned items:

1. **PRD functional requirements** (through their `TR-` IDs and the stories that
   implement them);
2. **Screens and routes** (the screen inventory and UX specs);
3. **API operations** (the contract in `docs/api/`);
4. **Analytics events** (the tracking plan);
5. **Feature flags** (PRD `## Configuration & Flags`);
6. **Notification templates** (push, e-mail, SMS, KakaoTalk 알림톡);
7. **Locales** (`localization.locales`).

| Output | Path |
|--------|------|
| Audit report (with the verdict line) | `production/qa/feature-audit-YYYY-MM-DD.md` |

The report satisfies the Build → Hardening gate's "all MVP features implemented" item.
`--summary` prints the summary in the conversation and writes nothing.

Verdict vocabulary (exact): `COMPLETE | GAPS | NOT ASSESSED` — precedence
**GAPS > NOT ASSESSED > COMPLETE** (a known gap is more actionable than an unknown;
an unknown still prevents COMPLETE).

---

## Workflow tier

This skill's scope depends on the tier, so it resolves `workflow` (above) before
auditing — without it the skill would apply whatever tier it assumed.

| `workflow` | Planned set audited |
|------------|---------------------|
| `full` | Every feature in the feature map whose Tier is `MVP`, `Beta` or `GA`; `Later` features are listed as not scored |
| `standard` | Features whose Tier is `MVP` — the set the Build → Hardening gate asks about |
| `minimal` | No PRDs exist at this tier: the planned set is the one-pager's `## Build Order` items and `## Core User Journey` steps; families with no plan behind them are `NOT CHECKED — no plan at minimal workflow` |

A `[feature-slug]` argument audits that one feature at any tier.

---

## Insufficient input — check this before producing any report

**If the inputs this skill needs do not exist, the answer is "could not run" —
not a filled-in report.** Check first, and stop if the check fails.

1. List the inputs this skill reads (feature map, PRDs, TR registry, stories and
   sprint status, screen inventory and UX specs, API contract, tracking plan, content
   decks, `project.yaml` locales, source in the resolved code roots).
2. For each, record `FOUND` or `ABSENT` — not "assumed present".
3. If any input required for a family is ABSENT, that family is
   **`NOT ASSESSED — NO DATA`**. Do not estimate it, do not infer it from an
   adjacent artifact, and do not leave a mandated cell to be filled by whoever
   reads the template next.
4. If **every** required input is ABSENT — no feature map and no PRDs (or no one-pager
   at minimal) — stop and report **`NOT ASSESSED — NO DATA`** as the whole verdict,
   naming what was missing and which skill produces it (`/map-features`, `/write-prd`,
   `/brainstorm`).

**A verdict of `NOT ASSESSED` is a success.** It is the correct, useful answer to
"what does the data say?" when there is no data. The failure mode this prevents is
specific: an audit that computes a completion percentage from an empty plan divides by
zero, and one that finds "nothing missing" because nothing was planned reads as done.

**Absence of evidence is never evidence of absence.** A code search that finds no
handler because no code root resolved has not shown the handler is missing. Say which
of the two happened.

---

## Phase 0: Parse the Argument and the Code Roots

- No argument → the tier's planned set; `[feature-slug]` → that feature only
  (`design/prd/<feature-slug>.md` must exist, else stop with
  `NOT ASSESSED — no PRD for <feature-slug> (run /write-prd <feature-slug>)`);
  `--summary` → no file is written.
- **Code roots** come from the resolved `code_roots` line — every directory listed there
  (per layer, plus `shared` and `undeclared` roots) is searched; the extensions it
  prints bound the search. If the line lists `undeclared=` roots, include them and
  print `WARN: undeclared code roots: <dirs> — declare them with /setup-stack`.
- When the line says `code_roots: unresolved — NOT CHECKED …`, every implementation
  family is `NOT CHECKED — no code root resolved (set stack.layers.<layer>.root via
  /setup-stack)`. Still build the planned set (Phase 1) — it is useful on its own — but
  the verdict is `NOT ASSESSED`, never GAPS computed from zero hits.

---

## Phase 1: Build the Planned Set

1. **Feature map** — read `design/product/feature-map.md`. Its main table
   (`| Feature | Category | Layer | Tier | Status | PRD | Depends On |`) gives each
   feature's tier, status, PRD path and dependencies; the tier decides the scope (see
   Workflow tier).

2. **PRDs — tiered reading.** Establish the denominator: Glob `design/prd/*.md` and
   count N. Then run two greps; they answer different questions and must not share a
   pattern:

   a. Which PRDs carry a Summary (for tiered reading):
   ```
   Grep pattern="^## Summary" glob="design/prd/*.md" output_mode="files_with_matches"
   ```
   b. Which PRDs declare planned items the audit counts:
   ```
   Grep pattern="^##+[[:space:]]+([0-9]+[.)][[:space:]]+)?(Functional Requirements|Configuration & Flags|Success Metrics & Instrumentation|Acceptance Criteria)" glob="design/prd/*.md" -i output_mode="files_with_matches"
   ```

   **Fail open on a missing Summary.** Fewer than N matches for (a) means those PRDs
   predate the preamble — never treat an absent Summary as a feature out of scope; read
   the whole of every unmatched in-scope PRD. A PRD that (b) does not match has no
   countable plan: list it under `### Unplanned or Unspecified` ("describes the feature
   without countable requirements") rather than scoring it as complete.

   For each in-scope PRD, read `## Summary`, `## Functional Requirements` (its
   `### Core Rules` and `### User Flows & States`), `## Configuration & Flags`,
   `## Success Metrics & Instrumentation` and `## Acceptance Criteria`.

3. **Requirements** — read `docs/architecture/tr-registry.yaml` and keep the
   `TR-<feature>-NNN` entries whose `prd:` is an in-scope PRD. No registry ⇒ count the
   `### Core Rules` items of each PRD instead and say the audit is coarser
   (`TR registry absent — requirements matched by PRD, not by ID`).

4. **Screens** — the web, iOS and Android rows of `design/inventory/screen-inventory.md`
   for the in-scope features (route, screen, deep link), and the screen specs in
   `design/ux/*.md` (not `app-shell.md` or `interaction-patterns.md`, which specify the
   shell and shared patterns).

5. **API operations** — the contract under `docs/api/`: OpenAPI paths × methods (with
   `operationId`), GraphQL `Query` / `Mutation` / `Subscription` fields, protobuf `rpc`
   definitions, AsyncAPI operations. Keep the operations the in-scope PRDs and UX specs
   (`## API Data`) use; at the `full` tier, all of them.

6. **Analytics events** — `design/product/tracking-plan.md` `## Events`
   (`| Event | Trigger | Properties | PII | Owner PRD | Status |`), rows whose Owner PRD
   is in scope. Cross-check with the `events` section of `design/registry/entities.yaml`
   when it exists — an event in one and not the other is listed in the report.

7. **Feature flags** — every flag key in the in-scope PRDs' `## Configuration & Flags`
   (e.g. `goals.v2-progress-ring`), with its recorded default.

8. **Notification templates** — the push, e-mail, SMS and KakaoTalk 알림톡 templates
   named in the in-scope PRDs and in the copy decks under `design/content/`, with their
   template keys or codes.

9. **Locales** — `localization.locales` from `project.yaml` (read with Read; it has no
   `resolve_config` label). Unset ⇒ `NOT CHECKED — localization.locales unset (set it via
   /setup-stack or /localize)`.

Record every family with no planned items as `none planned` — which is different from
`NOT CHECKED`.

---

## Phase 2: Scan the Implementation

Search only the resolved code roots, with the extensions the `code_roots` line printed.
Each item gets one status:

- `IMPLEMENTED` — the evidence below is present;
- `PARTIAL` — some of it is present (e.g. the handler exists but no contract test; a
  screen exists on web but not on the iOS app the inventory lists);
- `MISSING` — none of it is present;
- `NOT CHECKED — <reason>`.

| Family | Evidence of implementation |
|--------|----------------------------|
| Functional requirements | A story whose `**Requirement**:` is the TR-ID (`production/epics/*/story-*.md`) with status `done` in `production/sprint-status.yaml` (or `> **Status**: Complete`); `PARTIAL` when the story is `in-progress` or `review`, or some TR-IDs of the requirement are covered and others not |
| Screens | A route or screen file for each listed surface — web: the framework's route files (`app/**/page.*`, `pages/**`, `routes/**`); mobile: the screen component or Expo Router file, SwiftUI view or Compose screen — and the deep link registered (web route, Android intent filter, iOS associated domains / URL scheme, Expo linking configuration) when the inventory lists one |
| API operations | A handler for the operation in a backend root (the `operationId`, the path string, or the framework's route declaration for that method and path; the resolver for a GraphQL field), plus a contract test for `IMPLEMENTED` — where `testing.patterns` in `project.yaml` (read with Read) places contract tests, else under `tests/contract/` with `testing.patterns unset — using the tests/** convention` stated in the report; handler alone is `PARTIAL` |
| Analytics events | The event name emitted in code for every surface the event's trigger occurs on |
| Feature flags | The flag key evaluated in code; its default recorded in the PRD |
| Notification templates | The template key or code referenced in code, and the template content present (template files, i18n entries for push text); 알림톡 templates also need the provider's approval, which lives outside the repo — mark `approval: not verifiable here` |
| Locales | A resource file per locale (`locales/<tag>/…`, `messages/<tag>.json`, `<lang>.lproj/…` or `Localizable.xcstrings`, `res/values-<lang>/strings.xml`, `lib/l10n/app_<lang>.arb`) and key parity with the source locale — missing keys counted |

A string found in code is evidence that something was built, not that it works: say
so once in the report, and point readers to `/smoke-check`, `/team-qa` and
`/regression-suite` for behaviour.

**Unplanned implementation** — while scanning, record what exists without a plan: API
handlers whose path is absent from the contract (contract drift), routes absent from the
screen inventory, events emitted but absent from the tracking plan, flags evaluated but
named in no PRD. These are not gaps; they are drift, listed separately.

---

## Phase 3: Gap Report

Per feature, count the planned items per family and how many are `IMPLEMENTED`. The
feature status (percentages exclude `NOT CHECKED` families, which are listed):

- `DONE` — every planned item `IMPLEMENTED`;
- `IN PROGRESS` — 50–99 % implemented;
- `EARLY` — 1–49 % implemented;
- `NOT STARTED` — 0 %.

Flag a feature **HIGH PRIORITY** when it is `NOT STARTED` or `EARLY` and either its Tier
is `MVP`, or another in-scope feature lists it in `Depends On`.

**Verdict:**

- `GAPS` — at least one in-scope planned item is `MISSING` or `PARTIAL`;
- `NOT ASSESSED` — no gap found, but at least one family with planned items is
  `NOT CHECKED`, or there is no planned set;
- `COMPLETE` — every planned item in scope is `IMPLEMENTED` and no family with planned
  items is `NOT CHECKED`.

---

## Phase 4: Output

### Report mode (default)

Present the coverage table and the HIGH PRIORITY gaps, then ask:
"May I write this to `production/qa/feature-audit-YYYY-MM-DD.md`?" If today's report
exists, ask before overwriting it.

```markdown
# Feature Audit — [YYYY-MM-DD]

> **Verdict**: [COMPLETE | GAPS | NOT ASSESSED]

> **Scope**: [tier planned set at <workflow> | feature: <slug>]
> **Workflow tier**: [resolved workflow line]
> **Code roots**: [resolved code_roots line]
> **Generated by**: /feature-audit

## Summary

- Features in scope: [n] — DONE [n] · IN PROGRESS [n] · EARLY [n] · NOT STARTED [n]
- Planned items: [n] — IMPLEMENTED [n] · PARTIAL [n] · MISSING [n] · NOT CHECKED [n]
- HIGH PRIORITY gaps: [n]

> Evidence is a code search: it shows something was built, not that it behaves as
> specified. Behaviour is covered by /smoke-check, /team-qa and /regression-suite.

## Coverage by Feature

| Feature | Tier | Requirements | Screens | Operations | Events | Flags | Templates | Locales | Status |
|---------|------|--------------|---------|------------|--------|-------|-----------|---------|--------|
| goals | MVP | [7/8] | [5/5] | [9/10] | [4/6] | [1/1] | [2/3] | [2/2] | [IN PROGRESS] |

## HIGH PRIORITY Gaps

- [Feature — what is missing — why it is high priority (MVP tier / blocks <feature>)]

## Per-Feature Breakdown

### [feature]

- **PRD**: `design/prd/[feature].md`
- **Missing / partial**:

| Family | Item | Status | Evidence looked for |
|--------|------|--------|---------------------|
| Operations | `POST /v1/goals/{id}/deposits` (`createDeposit`) | PARTIAL | handler found in `apps/api`; no contract test |

## Unplanned Implementation

| Kind | Found | Where | Suggested action |
|------|-------|-------|------------------|
| Operation not in the contract | `GET /v1/goals/export` | [path — handler name] | `/api-design update goals` |

### Unplanned or Unspecified

- [PRDs that describe a feature without countable requirements, flags or events]

## Not Checked

- [Every family, surface or locale not checked, with its reason]

## Recommendation

Focus implementation on:
1. [Highest HIGH PRIORITY gap]
2. [..]
3. [..]
```

After writing, confirm the file exists and the verdict line sits directly under the H1.

### `--summary` mode

Print the Summary and the Coverage by Feature table in the conversation and write
nothing. End with: "Run `/feature-audit` without `--summary` to write the report — the
Build → Hardening gate reads the written report, not this summary."

---

## Phase 5: Next Steps

Close with the next steps that apply, as a short list:

- HIGH PRIORITY gaps → `/create-stories <epic-slug>` for each, or `/quick-spec` for a
  small one; then `/sprint-plan`.
- A requirement with no story at all → `/create-stories` (or `/create-epics` when no
  epic covers the feature).
- Operations implemented but missing from the contract → `/api-design update <resource>`.
- Events emitted but missing from the tracking plan, or planned and never emitted →
  `/write-prd <feature>` (its instrumentation section feeds the tracking plan).
- Locale files or keys missing → `/localize extract`.
- Unspecified PRDs → `/write-prd <feature>` to make the plan countable.
- Gaps closed → rerun `/feature-audit`, then `/gate-check hardening`.

---

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and `autonomous`
modes, see `.claude/docs/automation-modes.md`.

- **Never compute a percentage from nothing** — no planned set, or no code root, is
  `NOT ASSESSED`, not 0 % and not 100 %.
- **Name what was not checked** — every family skipped, and why, is in `## Not Checked`.
- **Drift is not a gap** — unplanned implementation is listed separately, for the plan
  to catch up, not scored against the build.
- This skill reads and reports; it changes no plan and no code. Ask "May I write this
  to `<path>`?" before writing the report.
