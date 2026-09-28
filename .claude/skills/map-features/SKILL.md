---
name: map-features
description: "Decompose the brief into features, dependencies and MVP / Beta / GA / Later tiers; create the feature map."
argument-hint: "[next | feature-name] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskUpdate, Bash(bash "*/.claude/skills/map-features/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,docs.density,team.size,stack`

Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

# Map Features

This skill turns the product brief into the **feature map** — `design/product/feature-map.md` — the list of features
the product needs, how they depend on each other, which layer each sits in, and which release tier (MVP, Beta, GA,
Later) each belongs to. It is the bridge between discovery and specification: every PRD `/write-prd` writes is one row
of this map, and the order the map recommends is the order the PRDs get written.

A brief rarely names every feature. Users sign in, pay, get notified, delete their accounts and contact support in
every service, whether or not the brief says so — and the features nobody listed are the ones that surface as launch
blockers. This skill makes them visible early, then has the three directors check the result: boundaries
(TD-DOMAIN-BOUNDARY), value (PD-FEATURE-MAP) and scope against capacity (DM-SCOPE).

### Outputs

| Path | What is written |
|------|-----------------|
| `design/product/feature-map.md` | From `.claude/docs/templates/feature-map.md`: overview, the `## Features` table, categories, tiers, dependency map, PRD authoring order, circular dependencies, high-risk features, progress tracker; the director review lines in its header |

Also updated: `production/session-state/active.md` (the checkpoint).

### What this skill never does

- **Change the column contract.** The `## Features` header is exactly
  `| Feature | Category | Layer | Tier | Status | PRD | Depends On |` — no column added, dropped, renamed or reordered
  (Phase 5).
- **Write a PRD.** Each feature's PRD belongs to `/write-prd`; this skill hands off to it (Phase 8).
- **Overwrite PRD progress.** On an existing map, the `Status` and `PRD` values of every row are carried over exactly
  — `/write-prd` and `/prd-review` own them.
- **Delete a row whose PRD exists.** A feature dropped from scope moves to `Later` with a note, or the user decides
  separately what happens to its PRD.

---

## Phase 1: Parse Arguments and Read the Brief

### 1a. Modes

- **No argument** — `/map-features`: the full decomposition (Phases 2–7) that creates or updates the feature map.
- **`next`** — `/map-features next`: pick the next feature to specify from the existing map and hand off to
  `/write-prd` (Phase 8). No map ⇒ say so and run the full decomposition instead, asking first.
- **`<feature-name>`** — `/map-features goals`: if the map does not list the feature, run the single-feature path:
  Phases 2c–7 for that one feature — its slug, category, layer, tier and dependencies — added as one row to the
  existing map, then hand off to `/write-prd` (Phase 8). If the map lists it, ask: `Write its PRD` (hand off, Phase 8)
  / `Update its row` (the single-feature path for the existing row — category, layer, tier, `Depends On` — keeping its
  `Status` and `PRD` values).
- An inline `--review full|lean|solo` overrides the resolved `review_mode` for this run (Phase 6).

**`workflow`** (`.claude/docs/workflow-modes.md`):
- `standard` / `full` — required before PRD authoring: features are mapped before per-feature PRDs are written.
- `minimal` — not required: the one-pager's `## Build Order` replaces the feature map. The skill can still be run
  voluntarily; it then reads `design/product/one-pager.md` as its source and says so.

**`docs.density`** controls how much prose surrounds the table: `terse` = the table plus a one-paragraph
`## Overview`; `balanced` = a short paragraph per feature in `## Overview` and one-line notes per layer in
`## Dependency Map`; `thorough` = per-feature rationale plus relationship analysis. The prose always goes into
`## Overview` and the layer notes — **never into a new table column**. Every consumer of the map (`/write-prd`,
`/prd-review`, `/create-epics`, `/create-stories`, `/story-readiness`, `/architecture-review`, `/review-all-prds`,
`/qa-plan`, `/regression-suite`, `/ui-inventory`, `/adopt` and the Definition → Architecture gate) reads the table by
its exact header and column names, so widening it is a contract change, not a formatting choice.

### 1b. Required context

- **Product brief**: read `design/product/product-brief.md` (at `minimal`: `design/product/one-pager.md`). If neither
  exists, stop:
  > "No product brief found. Run `/brainstorm` first, then come back to decompose it into features."
  — verdict `NOT ASSESSED — no product brief to decompose`.

**Optional** (read if present):
- `design/product/feature-map.md` — **resume**: update it, never recreate it from scratch.
- `design/product/personas/*.md` and `design/product/user-journey.md` — journeys the features must cover.
- `design/prd/*.md` (Glob only) — which features already have a PRD.
- `prototypes/*-concept/REPORT.md` — validated or killed assumptions that move features between tiers.

**If the feature map already exists**, read it, present its state and ask:
- "The feature map lists <N> features (<M> with an Approved PRD, <K> Not Started). What would you like to do?"
  - Options: `Add or update features` / `Write the next PRD` / `Review and revise tiers`

Create one task per phase (TaskCreate) so the user can see where the run is; update each as it completes.

---

## Phase 2: Enumerate Features

This is the creative core of the skill — it needs human judgment, because a brief describes value, not an inventory.

### 2a. Explicit features

Scan the brief for the features it names or directly requires:
- `## Value Proposition` and `## MVP Scope` — the most explicit
- `## Target Users & Jobs-to-be-Done` — each job implies a capability
- `## Business Model Hypothesis` — how money is made implies payments, plans or ads
- `## Riskiest Assumptions` — an assumption about behaviour usually names the feature it depends on
- (one-pager) `## Core User Journey`, `## Scope & Non-Goals`, `## Build Order`

### 2b. Implicit features — the service checklist

Walk this checklist for every product; each line is a question, not a default:

identity & auth · onboarding · core domain features · notifications · payments & billing · subscriptions and
entitlements · permissions/RBAC & workspaces (B2B) · search · settings & account (including data export and account
deletion) · admin/back-office · reporting · analytics & instrumentation · consent & privacy · support/help

For each explicit feature, name the **hidden features** it implies. Inference patterns:

- **"Users have accounts"** implies sign-up and sign-in (email, and the social logins the market expects — Kakao and
  Naver in Korea, Apple and Google elsewhere), session management and sign-out everywhere, account recovery, and
  in-app account deletion — Apple requires it in apps that offer account creation, and Google Play requires a
  deletion path as well (verify the current store policies when the feature is specified).
- **"Users pay"** implies payment-method registration, checkout or auto-debit (a billing key with the payment
  provider), receipts, failed-payment retries and messaging, refunds and cancellation, settlement webhooks, an admin
  refund tool, and store billing rules for digital goods sold inside iOS and Android apps.
- **"Paid plans"** implies plans and entitlements, upgrade and downgrade with proration, trials, a cancellation flow,
  store subscription server notifications, and a pricing page.
- **"We tell users things"** implies push (APNs and FCM), email, SMS or KakaoTalk 알림톡, notification preferences,
  quiet hours, marketing-consent capture and its periodic reconfirmation, and message-template approval.
- **"Teams use it" (B2B)** implies workspaces, invitations, roles and permissions, SSO (SAML or OIDC) for larger
  customers, an audit log, and seat-based billing.
- **"Users create content"** implies storage and media processing, moderation and abuse reporting, and search.
- **"An operating team runs it"** implies an admin console with support lookup, an audit log of admin actions, and a
  way to change flags and config without a release.
- **"We process personal data"** implies consent capture, terms and privacy-policy acceptance with versioning, data
  export on request, retention and deletion jobs, and cookie consent for EU web traffic.
- **"We measure success"** implies analytics instrumentation, an experiment framework, and install attribution for
  apps.

Explain in conversation why each inferred feature is needed, with a concrete example from this product. Example (Moa,
a savings app): the brief names `goals` and `payments`; the checklist adds `auth`, `notifications` (deposit and
failed-debit messages), `subscription` (the Plus plan), `admin-console` (support must see a user's goals and debits),
and `settings-account` (data export and account deletion).

### 2c. Name and review

Give each feature a **slug** (kebab-case: `goals`, `admin-console`) — it becomes the PRD file stem, the TR-ID prefix
and the `workflow_overrides.feature_overrides` key, so choosing slugs is a **major** decision. Present the enumeration
grouped by category (the recommended list is in `.claude/docs/templates/feature-map.md` § Categories; Category is free
text when none fits). For each feature: slug, category, one-sentence description, and whether it was explicit or
inferred.

Then capture feedback with `AskUserQuestion`:
- "Are features missing from this list?"
- "Should any be combined or split?"
- "Are there features listed that this product does NOT need?"

- **`collaborative`** — iterate until the user approves the enumeration.
- **`guided`** — ask once, apply the answer, and proceed; do not loop.
- **`autonomous`** — do not ask. Record the enumeration and every inferred feature with `log_decision` and proceed.

> The loop needs an exit that does not depend on being asked: `autonomous` makes no `AskUserQuestion` calls, so a
> loop that ends only when "the user approves" would never end there.

---

## Phase 3: Dependencies and Layers

A feature **depends on** another when it cannot work without it (hard) or works worse without it (soft). Both kinds
go into `Depends On`, because each PRD's `## Dependencies` table lists both and the Definition → Architecture gate
checks that the two agree in both directions.

### 3a. Map dependencies

For each feature, list what it depends on:
- **Data**: feature A produces data or events feature B needs (goals needs the settled deposits `payments` produces).
- **Structural**: A provides what B plugs into (everything signed-in depends on `auth`).
- **Surface**: a flow or surface that composes several features depends on each of them (`onboarding` depends on
  `auth`, `goals` and `payments`).

### 3b. Assign layers

Layer ∈ `Foundation | Core | Feature | Presentation`:
1. **Foundation** — no feature dependencies; others build on it (`auth`).
2. **Core** — depends on Foundation only (`payments`, `notifications`).
3. **Feature** — depends on Core or other Feature-layer features (`goals`, `subscription`).
4. **Presentation** — flows and surfaces that wrap other features (`onboarding`, `admin-console`).

Cross-cutting concerns take the layer of what they are: analytics instrumentation and consent capture are usually
Foundation; accessibility and localization are requirements inside every PRD, not features of their own.

### 3c. Circular dependencies

Check the graph for cycles. For each one, show it and propose a resolution: an event contract owned by one side, an
interface that one feature owns and the other consumes, or specifying the two features together. Example: goals ↔
payments — a debit belongs to a goal, and goal progress comes from debits; resolved by payments storing the goal ID as
an opaque reference and publishing `payment_settled`, so goals depends on payments and never the reverse.

### 3d. Present and confirm

Show the dependency map as layered lists. Highlight cycles and their resolutions, **bottleneck** features (many
others depend on them — high risk, specify early) and leaf features (nothing depends on them — lower risk, can come
late). `AskUserQuestion`: "Does this dependency order look right? Any dependency missing or wrong?"

---

## Phase 4: Tiers and Authoring Order

### 4a. Assign tiers

Tier ∈ `MVP | Beta | GA | Later` (definitions in `.claude/docs/templates/feature-map.md` § Tiers). Starting heuristics:
- **MVP** — the brief's `## MVP Scope`, every feature a target user needs to complete the core user journey, their
  Foundation dependencies, and the table stakes without which the product cannot launch where it ships (account
  deletion for store apps with accounts, consent capture where personal data is processed, a support contact).
- **Beta** — completes the experience for early users; the gaps the MVP will expose first.
- **GA** — scale, self-service, admin depth and compliance completeness for a general launch.
- **Later** — valuable, not needed for GA; revisit with evidence.

No MVP feature may depend on a Beta, GA or Later feature: either the dependency moves up or the dependent moves down.

### 4b. Review with reasoning

Present the tiers as a table and explain each placement. `AskUserQuestion`: "Do these tier assignments match your
plan? Which features should move up or down?"

Reasoning mixes user value with technical necessity, and cites the principle or journey step it serves — a purely
technical reason ("payments needs a PG integration") is not enough when the feature shapes what the user experiences:
- "MVP because the core journey stops without it — a user who cannot authorise the debit never sees saving happen
  automatically (principle: <principle from this brief>)."
- "Beta: valuable to the users who stay past the first month, but the MVP hypothesis is testable without it."
- "Foundation for every later money decision — refunds, plan changes and support tooling all read what it records."

> **Fill every bracket from this project.** A worked example from another product, reproduced verbatim, carries that
> product's vocabulary into this one. The rationale lives in the conversation and, for anything the team should still
> see later, in `## Overview` — the table has no `Why` column and gets none.

### 4c. Target and capacity inputs

Ask for the target milestone or date for the MVP (a Private Beta date, a demo day, an investor milestone) — or record
"none given". DM-SCOPE (Phase 6) weighs the MVP against it.

### 4d. PRD authoring order

Combine dependency order and tier: MVP Foundation first, then MVP Core, MVP Feature, MVP Presentation; then the Beta
layers, and so on. Independent features in the same layer can be written in parallel. For each row name the owner
(`product-manager`) and the consultants the PRD will need most (`business-analyst` for rule-heavy features,
`monetization-strategist` for pricing, `security-engineer` for identity and personal data), and an effort estimate
(S = one `/write-prd` session, M = 2–3, L = 4+).

### 4e. High-risk features

List the features that are technically unproven, uncertain in value, gated by an outside approval (payment-provider
merchant review, 알림톡 template approval, app store review of subscriptions), or scope-dangerous — each with a
mitigation (prototype, early application, sandbox integration, scope fallback). Prototype or validate them early
whatever their tier.

---

## Phase 5: Write the Feature Map

### 5a. Draft

Fill `.claude/docs/templates/feature-map.md` with the results of Phases 2–4:
- Header: `> **Status**: Draft`, dates, `> **Source Brief**:` (the brief or one-pager path).
- `## Overview` — the functional scope, the MVP line, the inferred features, and the per-feature prose the density
  asks for.
- `## Features` — one row per feature, header exactly `| Feature | Category | Layer | Tier | Status | PRD | Depends On |`:
  - `Feature` = slug · `Category` = free text (recommended list in the template) · `Layer` ∈
    `Foundation | Core | Feature | Presentation` · `Tier` ∈ `MVP | Beta | GA | Later`
  - `Status` ∈ `Not Started | Drafting | In Review | Needs Revision | Approved | Implemented` — `Not Started` for a
    new feature; for a feature with an existing PRD, the status matching its `> **Status**:` line (`Draft` ↔
    `Drafting`, the other four the same word); on an existing map, the row's current value unchanged
  - `PRD` = `design/prd/<slug>.md` when the file exists, else `—` · `Depends On` = comma-separated slugs, or `—`
- `## Categories`, `## Tiers`, `## Dependency Map`, `## PRD Authoring Order`, `## Circular Dependencies`,
  `## High-Risk Features`, `## Progress Tracker` (counts from the Status column), `## Next Steps`.

On an existing map, a tier change for a feature that already has a PRD leaves that PRD's `> **Feature Map Tier**:`
line stale: list each such PRD in the summary for the user to update (a PRD edit is outside this skill).

### 5b. Approval and write

Present a summary: feature count by category and by tier, the first three rows of the authoring order, the cycles
found, and the high-risk features.

- **`collaborative`** — ask "May I write this to `design/product/feature-map.md`?" and write only after "yes".
- **`guided`** — for a new file, ask the same question (guided still asks before creating a file); for an update to an
  existing map, present the summary, name the destination and write without waiting for an explicit "yes", then say
  what was written.
- **`autonomous`** — write, and log the decision with `log_decision`.

If the user declines: verdict **BLOCKED** — the feature map was not written. Skip Phase 6 (the gates review a written
map), report in Phase 7 and stop.

---

## Phase 6: Director Review Panel

Three gates review the written draft before any PRD is authored. Apply the review mode to **each** gate, then spawn
every surviving gate **in parallel** — issue all `Agent` calls before waiting for any result, and collect all
verdicts before continuing.

**Review mode check** — apply before spawning TD-DOMAIN-BOUNDARY, PD-FEATURE-MAP and DM-SCOPE (`--review` overrides
the resolved `review_mode`):
- `full` → spawn as normal.
- `lean` → **skip every gate whose ID does not end in `-PHASE-GATE`**. Note: `[GATE-ID] skipped — Lean mode`
  None of the three ends in `-PHASE-GATE`, so lean skips all three: `[TD-DOMAIN-BOUNDARY] skipped — Lean mode`,
  `[PD-FEATURE-MAP] skipped — Lean mode`, `[DM-SCOPE] skipped — Lean mode`.
- `solo` → skip all gates. Note: `[<GATE-ID>] skipped — Solo mode` for each of the three.

Each skip note is written into the feature map header where that gate's review line would go (5d below), and the
summary names the omission: "<GATE-ID> not consulted — <Mode> mode; `--review full` runs it."

Each spawn's `Agent` prompt instructs the agent to read its gate file **first**; never read a gate file or paste its
prompt in this session.

### 6a. TD-DOMAIN-BOUNDARY — `technical-director`

- Gate: **TD-DOMAIN-BOUNDARY** — `.claude/docs/director-gates/td-domain-boundary.md`
- Pass: feature map path · brief path · `docs/registry/architecture.yaml` path (or "none") · resolved `stack` line
- Fill them: `design/product/feature-map.md`; the brief (or one-pager) path; `docs/registry/architecture.yaml` if it
  exists, else `none`; the resolved `stack` line exactly as the block above printed it (including
  `stack: unset — run /setup-stack`).

### 6b. PD-FEATURE-MAP — `product-director`

- Gate: **PD-FEATURE-MAP** — `.claude/docs/director-gates/pd-feature-map.md`
- Pass: feature map path · product brief path · MVP scope text
- Fill them: `design/product/feature-map.md`; `design/product/product-brief.md` (a voluntary run at `minimal` passes
  `design/product/one-pager.md` and says so); the brief's `## MVP Scope` text (one-pager: `## Scope & Non-Goals`).

### 6c. DM-SCOPE — `delivery-manager`

- Gate: **DM-SCOPE** — `.claude/docs/director-gates/dm-scope.md`
- Pass: MVP scope text (brief, one-pager or feature map path) · resolved `team.size` · target milestone/date (or "none given")
- Fill them: `design/product/feature-map.md`; the resolved `team.size` line as printed; the answer from 4c, or
  `none given`.

### 6d. Verdicts

Parse the first line of each reply as `[GATE-ID]: TOKEN` and map the token with the verdict classes of
`.claude/docs/director-gates.md` (`## Standard Verdict Format`). The tokens are `APPROVE`, `CONCERNS`, `REJECT` for
TD-DOMAIN-BOUNDARY and PD-FEATURE-MAP, and `REALISTIC`, `CONCERNS`, `UNREALISTIC` for DM-SCOPE. The strictest verdict
across the panel decides what happens next:

- **APPROVE-class** (`APPROVE`, `REALISTIC`) → nothing to change for that gate.
- **CONCERNS-class** (`CONCERNS`) → present the concerns via `AskUserQuestion`: `Revise the map` / `Accept and record
  the concerns` / `Discuss further`. Accepted concerns are recorded as notes in the map:
  - PD-FEATURE-MAP → `> **Product Director Note** (<tier>): …` directly beneath the `## Tiers` table, naming the tier
    each concern applies to
  - TD-DOMAIN-BOUNDARY → `> **Technical Director Note**: …` beneath the `## Dependency Map` heading — the boundary
    concerns the PRDs' `## Dependencies` and `## API & Data Impact` sections must resolve
  - DM-SCOPE → `> **Delivery Manager Note**: …` beneath the `## PRD Authoring Order` table — what to cut, defer or buy
- **REJECT-class** (`REJECT`, `UNREALISTIC`) → present the blockers and revise the map with the user — back to Phase 2,
  3 or 4 as the finding requires — then rewrite the map (asking again) and re-spawn **only** the gates that returned a
  REJECT-class verdict. For DM-SCOPE `UNREALISTIC`, offer both of the gate's options: the cut list, or a date that fits
  the current scope. If the user stops without resolving it, the verdict is **BLOCKED**.
- A first line that does not parse, or names another gate, is not an approval — treat it as CONCERNS-class and say the
  verdict line was missing.

### 6e. Record the outcomes

Add one line per gate to the header block, directly under `> **Source Brief**:` (ask first — "May I write this to
`design/product/feature-map.md`?"):

```
> **Technical Director Review (TD-DOMAIN-BOUNDARY)**: APPROVED <date> | CONCERNS (accepted) <date> | REVISED <date>
> **Product Director Review (PD-FEATURE-MAP)**: APPROVED <date> | CONCERNS (accepted) <date> | REVISED <date>
> **Delivery Manager Review (DM-SCOPE)**: APPROVED <date> | CONCERNS (accepted) <date> | REVISED <date>
```

An APPROVE-class token is recorded as `APPROVED`; a map revised after a CONCERNS- or REJECT-class verdict as
`REVISED`. A skipped gate's line is its skip note: `> [DM-SCOPE] skipped — Lean mode`.

Then ask the user to approve the map as the plan for PRD authoring; on approval set `> **Status**: Approved` (it stays
`Draft` otherwise).

---

## Phase 7: Session State and Verdict

Overwrite the `<!-- STATUS -->` block (`Task: Feature map — <written | approved | not written>`) and the `<!-- CHECKPOINT -->` block
of `production/session-state/active.md` (Glob first: Write when absent, Edit when present): current task "Feature
map", next step "`/write-prd <first feature in authoring order>`", files in progress `design/product/feature-map.md`.

Summary:

```
Feature Map — <Product Name>
============================
File:           design/product/feature-map.md   Status: <Draft | Approved>
Features:       <n> (<n> explicit, <n> inferred) — MVP <n> · Beta <n> · GA <n> · Later <n>
Layers:         Foundation <n> · Core <n> · Feature <n> · Presentation <n>
Cycles:         <resolved list> | none
High risk:      <features> | none
Directors:      TD-DOMAIN-BOUNDARY <outcome> · PD-FEATURE-MAP <outcome> · DM-SCOPE <outcome>
Stale PRD tiers: <PRDs whose Feature Map Tier line no longer matches> | none
Not checked:    <skipped gates, and any NOT CHECKED line from a gate> | none
Next PRD:       /write-prd <slug>

Verdict: <COMPLETE | BLOCKED | NOT ASSESSED>
```

The verdict is reported here, in the conversation; the feature map is a plan, not a report, and carries no verdict
line — its state is its `> **Status**:` line and the director review lines.

**Verdict** (precedence BLOCKED > NOT ASSESSED > COMPLETE):
- **COMPLETE** — the feature map is written, and every gate of the panel is resolved (APPROVE-class, accepted
  concerns, or revised) or skip-noted by the review mode.
- **BLOCKED** — the write was declined, or a REJECT-class verdict was left unresolved; name which.
- **NOT ASSESSED** — there was no brief or one-pager to decompose (Phase 1b); nothing was written.

---

## Phase 8: Hand Off to `/write-prd`

Entered when the user wants to start writing PRDs after the map is done, or through `/map-features next` or
`/map-features <feature>`.

### 8a. Select the feature

- A feature name was given → find its row (the single-feature path of 1a has added it if it was missing).
- `next` → the first row of `## PRD Authoring Order` whose feature has `Status` `Not Started` in `## Features`; when
  none is left, the first `Needs Revision` row; when none of those either, say every feature has a PRD.
- Just finished the map → "The first feature in the authoring order is **<slug>**. Start its PRD now, pick a different
  feature, or stop here?"

### 8b. Hand off

Hand the selected feature to `/write-prd <slug>`. `/write-prd` owns the whole PRD process — it reads the brief, this
map and the dependency PRDs, creates the skeleton, walks the sections the workflow tier requires with the right
consultants, cross-checks the glossary registry, appends the tracking-plan events, runs PD-PRD-ALIGN and moves the
row's `Status` from `Drafting` to `In Review`. **Do not duplicate that workflow here**: this skill owns the feature
*map*; `/write-prd` owns each *PRD*.

### 8c. Loop or stop

After a PRD is written, `AskUserQuestion`: `Continue with the next feature (<slug>)` / `Pick a different feature` /
`Stop here for this session`. Continuing returns to 8a.

---

## Phase 9: Next Steps

Close with `AskUserQuestion` — "The feature map is written. What next?" — offering the options that apply:
- `/write-prd <first feature in authoring order>` — start the MVP PRDs (Recommended)
- `/map-features next` — always pick the next `Not Started` feature
- `/prototype` — for a high-risk feature whose value is still an assumption
- `/prd-review design/prd/<feature>.md` — in a fresh session, after each PRD is written
- `/review-all-prds` — when the MVP PRDs are written
- `/gate-check architecture` — when every MVP PRD is written and reviewed
- Stop here for this session

---

## Collaborative Protocol

**In `collaborative` mode (the default).** For `guided` and `autonomous`, the per-mode rules of
`.claude/docs/automation-modes.md` apply — the rules below describe what collaborative mode requires.

1. **Question → Options → Decision → Draft → Approval** at every phase.
2. **`AskUserQuestion` at every decision point** (Explain → Capture):
   - Phase 2: missing features? combine or split? not needed?
   - Phase 3: dependency order correct?
   - Phase 4: tiers match the plan? target milestone?
   - Phase 5: "May I write this to `design/product/feature-map.md`?"
   - Phase 6: gate concerns — revise, accept or discuss
   - Phase 8: start the next PRD, pick another, or stop — then hand off to `/write-prd`
3. **"May I write this to `<path>`?"** before every write of the feature map.
4. **Hand-off, not duplication** — PRD authoring belongs to `/write-prd`, which updates the map's `Status` and `PRD`
   columns as each PRD moves.
5. **Session state** after each milestone (map written, gates resolved, map approved).
6. **Skips announce themselves** — every gate skipped by the review mode is written into the map and named in the
   summary.

**Never** generate the full feature list and write it without review.
**Never** start a PRD without the user's confirmation.
**Always** show the enumeration, the dependencies and the tiers for the user to validate.

## Context Window Awareness

If context reaches or exceeds 70 % at any point, append:

> **Context is approaching the limit (≥70 %).** The feature map is saved to `design/product/feature-map.md`. Open a
> fresh Claude Code session to continue — run `/map-features next` to pick up the next feature to specify.

---

## Recommended Next Steps

- `/write-prd <first feature in authoring order>` — author the first PRD
- `/map-features next` — pick the next `Not Started` feature automatically
- `/prd-review design/prd/<feature>.md` in a fresh session after each PRD
- `/gate-check architecture` when every MVP PRD is written and reviewed
