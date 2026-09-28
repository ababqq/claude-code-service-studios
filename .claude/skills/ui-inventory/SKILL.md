---
name: ui-inventory
description: "Screen & component inventory per surface and media-asset specs (icons, illustrations, store screenshots, OG images)."
argument-hint: "[surface:<web|ios|android> | feature:<name> | media] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/ui-inventory/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,surfaces`

Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

# UI Inventory

This skill keeps two lists that UI work is planned against:

- **The screen inventory** — every route and screen per UI surface (web, iOS,
  Android), with its navigation placement, deep link, auth state, owning feature
  and UX-spec status, plus the shared components those screens need. It is the
  coverage source for `/ux-design`: a key screen missing from it is a screen
  nobody specs.
- **The media manifest** — every icon, illustration, app icon, store screenshot,
  social preview (OG) image and notification asset the product needs, each with
  a spec a designer or illustrator can deliver against.

Both are built from the design documents — the feature map, the PRDs' UI
requirements, the user journey, the app shell and the design language — and
confirmed with the user before anything is written.

### Outputs

| Path | What is written |
|------|-----------------|
| `design/inventory/screen-inventory.md` | Screens per surface (web routes; iOS and Android navigation placement), deep links, auth state, owning feature, tier, UX spec and status; shared components; coverage gaps |
| `design/inventory/media-manifest.md` | Media assets by category with sequential `ASSET-NNN` IDs, a spec per asset, a production brief, usage and status |

Neither file carries a verdict: they are lists, not judgements. Coverage gaps are
written as observations; `/gate-check` and `/ux-review` draw the conclusions.

### What each review mode adds

`review_mode` scales the specialists this skill consults. It spawns no director
gate. Unset on an unconfigured project: `modes.rigor` defaults to `minimal`, which resolves `review_mode` to `solo`.
A `--review` argument overrides the resolved mode for this run.

| Mode | Screen inventory | Media manifest |
|------|------------------|----------------|
| `full` | `product-designer` (screens, IA, routes, deep links, auth states) and `design-engineer` (component coverage, shared components) in parallel | `product-designer` (sourced platform and store requirements, production briefs) and `design-engineer` (formats, density variants, delivery) in parallel |
| `lean` | `product-designer` only; shared components derived from the design language by this skill and marked so | `product-designer` only; formats derived from the design language and marked "design-engineer not consulted — lean mode" |
| `solo` | No specialists; compiled from the documents alone | No specialists; every platform- or store-mandated value is `NOT SOURCEABLE` |

Every skipped specialist is named in the file's `> **Specialists**:` line and in
the closing summary — a list compiled without them must not read like one they
checked.

### What this skill never does

- **Write a UX spec.** It lists screens and their spec status; `/ux-design` writes
  the specs.
- **Add a screen the documents do not imply** without the user confirming it.
  Commonly forgotten screens are asked about, never added by default.
- **Call an image generator or any other external service.** Production briefs
  are text for a designer, an illustrator or a tool the team runs itself.
- **State a platform- or store-mandated value without a source.** Icon sizes,
  screenshot dimensions and file limits change with OS and store releases; each one
  carries `Source: <url>, retrieved YYYY-MM-DD` from a specialist's lookup in this
  run, or `NOT SOURCEABLE — <reason>`.
- **Let a specialist write under `design/`.** Specialists return drafts; this skill
  writes after approval.

---

## Phase 0: Parse Arguments and Surfaces

Extract:
- **Target**: none, `surface:<web|ios|android>`, `feature:<name>` (normalize to
  kebab-case — the feature slug is the PRD stem, `design/prd/<name>.md`), or
  `media`.
- **Review mode**: `--review [full|lean|solo]` if present.

Read the resolved `platform.surfaces` line.
- **UI surfaces** are `web`, `ios` and `android`; `api` is not a UI surface.
- `api` only → there are no screens to inventory. Say so. `media` still applies
  when the API has a developer portal or docs site with social previews; offer
  `media` or `Stop here`.
- Unset (`platform.surfaces: (unset -- ask which surfaces ship)`) → unset is not
  "web only". Ask which surfaces ship; use the answer for this run and name
  `/setup-stack` as the place that records it.
- `surface:<x>` for a surface that is not in the resolved line → ask:
  `Inventory it anyway for this run` / `Stop — add the surface with /setup-stack first`.
  `surface:api` → explain that `api` has no screens and stop.

**No argument:**
- `design/inventory/screen-inventory.md` does not exist → build the full screen
  inventory for every UI surface (Phases 1–3).
- It exists → count its rows by surface and status with Grep (do not read it
  whole) and present the summary. Then use `AskUserQuestion`:
  - `Refresh from the latest PRDs, journey and specs`
  - `Work on one surface`
  - `Inventory one feature`
  - `Media manifest`
  - `/ux-design [slug] — spec the next Needed MVP screen` (only when one exists)
  - `Stop here`

---

## Phase 1: Gather Context

Read the sources **before** asking the user anything. Missing sources are not
errors, but each one is named in the context summary and in the file's
`> **Sources**:` line — a screen list built without the PRDs must say so.

- **Feature map** — `design/product/feature-map.md`. The main table header is
  `| Feature | Category | Layer | Tier | Status | PRD | Depends On |`; take each
  feature's slug, `Tier` (`MVP | Beta | GA | Later`) and `PRD` path.
- **PRD UI content** — do not full-read every PRD. The wanted sections are
  standard headings:
  ```
  Grep pattern="^## UI Requirements|^### User Flows & States" glob="design/prd/*.md" output_mode="content" -A 30
  ```
  `## UI Requirements` is optional in a PRD; `### User Flows & States` sits under
  `## Functional Requirements`. Full-read a PRD only when both are missing or read
  `[To be designed]` — and then ask the user rather than guess (Phase 2).
- **One-pager** — at the `minimal` tier `design/product/one-pager.md`
  `## Core User Journey` replaces PRDs.
- **User journey** — `design/product/user-journey.md` `## Lifecycle Stages`
  (acquisition, sign-up, onboarding/activation, habit, retention, monetization,
  advocacy) — each stage implies screens.
- **App shell** — `design/ux/app-shell.md` `## Navigation Model` (tabs, top-level
  destinations) and `## Global States` (signed out, offline, maintenance,
  force-update).
- **Existing specs** — Glob `design/ux/*.md` (a screen with a spec is `Specced`)
  and `design/ux/reviews/*-ux-review-*.md` (a spec with a review record is
  `Reviewed`).
- **Design language** — `design/brand/design-language.md`: Grep for
  `^## 5. Components & States`, `^## 6. Iconography & Illustration` and
  `^## 8. Platform Adaptation` and read only those sections.
- **Glossary** — `design/registry/entities.yaml`, when it exists, for the domain
  names screens should use (a "goal" is not also a "plan" on another screen).
- **Existing inventory and manifest** — to update rather than duplicate.

For `feature:<name>`: `design/prd/<name>.md` must exist. If it does not, use
`AskUserQuestion`: `Describe the feature's screens now` /
`Stop — write the PRD first with /write-prd <name>` / `Stop here`.

Present the context summary:
> **UI Inventory: [full | surface: <x> | feature: <name> | media]**
> - Surfaces: [line as printed, or the answer given]
> - Sources: feature map [read / not found] · PRDs with UI content [N of M] ·
>   journey [read / not found] · app shell [read / not found] · design language
>   [read / not found]
> - Existing: [N screens / none] · [N media assets / none]
> - Specialists this run: [per the mode table above]

If none of the feature map, a PRD, the one-pager or the journey exists, stop:
> "There is nothing to inventory yet. Run `/map-features` and `/write-prd` (or
> `/brainstorm` for a one-pager at the `minimal` tier) first."

For `media`, continue with Phase 4.

---

## Phase 2: Screen Identification

Derive the screen list per surface, in this order:
1. **Features by tier** — MVP first, then Beta, GA and Later: the screens each
   PRD's UI requirements and user flows name or imply (a list implies a detail; a
   create flow implies an edit and a delete path).
2. **Shell destinations and global states** from the app shell.
3. **Journey stages** — sign-up, onboarding and activation, the habit loop,
   retention touchpoints (notifications inbox), monetization (plans, checkout,
   receipts), advocacy (invite, share).

**Ask about the screens services most often forget** — ask, never add by
default: sign-in recovery (password reset, email verification); terms and consent
(required and optional consents, marketing consent kept separate); identity
verification where a flow needs it (for example 본인인증 before a first auto-debit);
notification preferences; subscription management and cancellation; account
deletion; receipts and payment history; error pages (404, 500); maintenance and
force-update; the operator screens of an admin console.

For each screen record:
- **Slug** — kebab-case; it becomes the UX spec path `design/ux/<slug>.md`.
- **Surface(s)** — one row per surface. A screen that is one responsive web page
  is one web row; the same screen on iOS and Android is one row in each.
- **Route** (web) — e.g. `/goals/:goalId`; or **Navigation** (mobile) — tab, stack
  push, sheet or full-screen modal, and its parent.
- **Deep link** — custom scheme and universal link / Android App Link, e.g.
  `moa://goals/{goalId}` and `https://moa.example/goals/{goalId}`; `—` when the
  screen is not linkable, and say why (a checkout step should not be).
- **Auth** — public, signed-in, or a role (e.g. `admin`).
- **Feature** — feature slug and PRD path; **Tier** from the feature map.
- **UX Spec** and **Status** — `Needed` (no spec) · `Specced` (spec exists) ·
  `Reviewed` (spec has a review record) · `Implemented` (only when the user
  confirms it — this skill does not read code).

**Specialists** (per the mode table; issue parallel `Agent` calls before waiting
for either):
- **`product-designer`**: "Here is the draft screen list per surface with its
  sources. Validate and complete it: information architecture and navigation
  placement, routes and deep links, auth states, entry points (navigation,
  notification, email link, deep link), screens the documents imply but do not
  name, and screens that should be one responsive screen instead of several.
  Cite the PRD, journey or shell section each addition comes from."
- **`design-engineer`** (`full` only): "Map each screen to the components it needs
  from section 5 of the design language [or 'design language not written']. List
  the shared components used by two or more screens with the screens that use
  them, and name every component a screen needs that section 5 does not define —
  that list is the component library backlog."

In `lean`, derive the shared components yourself from section 5 of the design
language and the screen list, and mark the section
"derived — design-engineer not consulted (lean mode)". In `solo`, do the same for
both and mark "specialists not consulted (solo mode)".

Collect all responses, then present the grouped list (by surface, then feature,
with the shared components and the gaps). If specialists disagree — a separate
iOS screen versus a shared sheet — show both positions; do not pick one silently.
Use `AskUserQuestion`:
`Proceed — write this inventory` / `Remove screens` / `Add screens I'll describe` / `Adjust surfaces or navigation`.

Do NOT proceed to Phase 3 without the user's confirmation of the list.

---

## Phase 3: Write the Screen Inventory

Ask: "May I write this to `design/inventory/screen-inventory.md`?"

A new file uses this structure — one section per configured UI surface, in the
order web, iOS, Android:

```markdown
# Screen Inventory: [Product Name]

> **Last Updated**: [YYYY-MM-DD]
> **Surfaces**: [resolved platform.surfaces line, or the answer given in this run]
> **Sources**: [feature map · PRDs (N) · one-pager · journey · app shell · design language — each read / not found]
> **Specialists**: [product-designer, design-engineer | "<agent> not consulted — <Mode> mode"]

## Web

| Screen | Slug | Route | Auth | Feature | Tier | Deep Link | UX Spec | Status |
|--------|------|-------|------|---------|------|-----------|---------|--------|
| Goal detail | goal-detail | `/goals/:goalId` | signed-in | goals (`design/prd/goals.md`) | MVP | `https://moa.example/goals/{goalId}` | `design/ux/goal-detail.md` | Specced |

## iOS

| Screen | Slug | Navigation | Auth | Feature | Tier | Deep Link | UX Spec | Status |
|--------|------|------------|------|---------|------|-----------|---------|--------|
| Goal detail | goal-detail | Goals tab → stack push | signed-in | goals (`design/prd/goals.md`) | MVP | `moa://goals/{goalId}` | `design/ux/goal-detail.md` | Specced |

## Android

| Screen | Slug | Navigation | Auth | Feature | Tier | Deep Link | UX Spec | Status |
|--------|------|------------|------|---------|------|-----------|---------|--------|

## Shared Components

| Component | Used By | Surfaces | Design Language | Status |
|-----------|---------|----------|-----------------|--------|
| ProgressRing | goal-detail, home | web, ios, android | §5 — defined | Needed |

## Coverage Gaps

- [MVP screens with status Needed]
- [screens a PRD names that no surface lists]
- [components screens need that section 5 of the design language does not define]
- [sources not found in this run]
```

Scoped runs edit only their part of an existing file, with Edit:
- `surface:<x>` — that surface's section (and the shared components it touches).
- `feature:<name>` — that feature's rows in every surface section, plus the shared
  components and gaps they change.
- A refresh updates status columns from the specs and reviews found, adds
  confirmed new rows, and never deletes a row the user did not agree to remove.

After writing, tell the user which MVP screens are still `Needed` — those are the
next `/ux-design` runs.

---

## Phase 4: Media Manifest (`media`)

### 4a. Identify the assets

Read, in addition to Phase 1: the screen inventory (screens with empty,
onboarding, error or success states that call for illustration), sections 2, 6
and 8 of the design language, and the existing manifest.

If section 6 of the design language is missing, say so: every asset's style is
then `NOT DETERMINED — design language section 6 not written`, and `/design-language`
is offered at the close. Do not fail.

Group the assets, including only the categories the configured surfaces need:
- **App Icons & Launch** — iOS app icon and its appearance variants; Android
  adaptive icon layers and themed (monochrome) layer; web favicon set, touch icon
  and PWA manifest icons; launch or splash screens.
- **UI Icons** — the icon set the inventoried screens use, marking which come from
  a platform set (SF Symbols, Material Symbols) and which are custom.
- **Illustrations & Animation** — empty states, onboarding, error pages, success
  moments; animation files (for example Lottie) with a size limit.
- **Store Listing** (ios, android — when the apps ship through the App Store or
  Google Play; ask when unclear) — screenshots per required device class,
  optional preview video, Google Play feature graphic. Store *text* is not media:
  it belongs to `/team-content`.
- **Web Social & SEO** — Open Graph and social-card images per shareable route
  type (a shared goal, an invite link), favicon.
- **Notifications & Email** — the Android status-bar notification icon, rich push
  images, email header and logo.

Present the grouped list with, for each asset, the screen or listing that needs
it. Use `AskUserQuestion`:
`Proceed — spec all of these` / `Remove some` / `Add assets I'll describe` / `Adjust categories`.
Do not spec before the list is confirmed.

### 4b. Spec generation

Per the mode table (parallel `Agent` calls in `full`):
- **`product-designer`**: "For each asset: (1) the platform- or store-mandated
  requirements — dimensions, formats, variants, safe zones, file limits — looked
  up now from the official source (Apple Human Interface Guidelines and App Store
  Connect Help, Android developer documentation and Play Console Help, the Open
  Graph protocol and each social platform's card documentation), each value with
  its URL and retrieval date, or `NOT SOURCEABLE` with the reason; (2) a production
  brief of 2–3 sentences anchored to sections 2 and 6 of the design language,
  specific enough that two designers would deliver consistent results; (3) which
  design-language rules govern it, by section."
- **`design-engineer`** (`full` only): "For each asset: source format and export
  formats (SVG, PDF, PNG, WebP or AVIF for the web; vector drawables for
  Android), density variants (@2x/@3x; mdpi–xxxhdpi or vector), naming per the
  project's convention, delivery location in the component library or app
  bundle, and size limits that keep bundles within budget. Flag any
  platform-mandated value that conflicts with the design language."

In `lean`, derive formats and variants from sections 6 and 8 of the design language
and mark them "design-engineer not consulted — lean mode". In `solo`, no specialist
runs: every platform- or store-mandated value is written
`NOT SOURCEABLE — not looked up (solo mode; rerun with --review lean or full)`, and
briefs come from section 6 alone.

Collect all responses. If they conflict (a store-mandated size against the
design language's icon grid), show both — do not silently resolve.

### 4c. Review and write

Present every spec in this format:

```
### ASSET-[NNN] — [Asset Name]

| Field | Value |
|-------|-------|
| Category | [App Icons & Launch / UI Icons / Illustrations & Animation / Store Listing / Web Social & SEO / Notifications & Email] |
| Surface | [web / ios / android] |
| Dimensions | [value — Source: <url>, retrieved YYYY-MM-DD | NOT SOURCEABLE — <reason> | from design language §6] |
| Format & Variants | [e.g. SVG source; PNG @2x/@3x; light and dark] |
| Naming | [file name per the project's convention] |
| Used By | [screen slugs from the inventory, or the listing] |
| Design Language Anchors | [§6 rule; §2 tokens used] |

**Production brief:** [2–3 sentences]

**Status:** Needed
```

Use `AskUserQuestion`:
`Approve all — write to the manifest` / `Revise a specific asset` / `Regenerate with a different direction`.
Revise small text inline without re-spawning; re-spawn only when the direction
itself changes.

Ask: "May I write this to `design/inventory/media-manifest.md`?" A new file uses:

```markdown
# Media Manifest: [Product Name]

> **Last Updated**: [YYYY-MM-DD]
> **Design Language**: `design/brand/design-language.md` (section 6 [complete / missing])
> **Specialists**: [product-designer, design-engineer | "<agent> not consulted — <Mode> mode"]

## Progress Summary

| Total | Needed | In Progress | Delivered | Approved |
|-------|--------|-------------|-----------|----------|
| [N] | [N] | [N] | [N] | [N] |

## Assets

| Asset ID | Name | Category | Surface | Used By | Status |
|----------|------|----------|---------|---------|--------|
| ASSET-001 | [name] | [category] | [surface] | [screens] | Needed |

## Asset Specs

[every ASSET-NNN block]
```

An existing manifest gets the new rows and blocks appended with Edit, and the
Progress Summary recounted. Status values: `Needed` · `In Progress` ·
`Delivered` · `Approved`.

**Asset IDs** are assigned sequentially across the whole project, never per
category. Find the highest existing ID first:

```
Grep pattern="ASSET-[0-9]+" path="design/inventory/media-manifest.md" output_mode="content"
```

Start new assets at the highest + 1, or `ASSET-001` when there is no manifest.
IDs are never reused or renumbered.

**Shared assets.** Before speccing an asset, check the manifest for an equivalent
— one empty-state illustration style reused across features, one OG template for
every shareable route. On a match, reference the existing ID and add the new
screens to its `Used By` instead of creating a duplicate:
> "ASSET-012 (empty-state illustration, goals) already specced. Reusing it for the
> notifications inbox — adding `notifications-inbox` to Used By."

---

## Phase 5: Close

Summarize in the conversation:

```
Screen inventory: design/inventory/screen-inventory.md — [N] screens ([web n · ios n · android n]); MVP Needed: [n]
Shared components: [n] ([k] not defined in the design language)
Media manifest: design/inventory/media-manifest.md — [N] assets; NOT SOURCEABLE values: [n]
Specialists: [who ran; who did not, with the mode]
Sources not found: [list or "none"]
```

Use `AskUserQuestion` for next steps, including only the options that apply:
- `[_] /ux-design [slug] — spec the next Needed MVP screen` (Recommended when one exists)
- `[_] /ux-design shell — specify the app shell` (when `design/ux/app-shell.md` is missing)
- `[_] /design-language — define the components and media rules this inventory references` (when the design language is missing or section 5/6 is incomplete)
- `[_] /ui-inventory media — specify the media assets` (when the manifest is missing)
- `[_] /ui-inventory surface:[x] — inventory a configured surface not covered yet`
- `[_] /ux-review [spec] — review Specced screens without a review record`
- `[_] /team-content store-listing` / `/team-content notifications` — store text and notification copy (not covered by the media manifest)
- `[_] Stop here`

---

## Error Recovery

If a spawned agent returns BLOCKED or cannot complete:
1. Surface it immediately: "[agent]: BLOCKED — [reason]".
2. `design-engineer` blocked → proceed with product-designer's output; mark the
   affected columns "design-engineer not consulted — blocked: <reason>".
3. `product-designer` blocked → compile from the documents; screen additions are
   limited to what the documents name, and every platform- or store-mandated media
   value is `NOT SOURCEABLE — product-designer blocked`.
4. Always produce a partial result — never discard confirmed rows because one
   agent blocked.

---

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and `autonomous`
modes, see `.claude/docs/automation-modes.md` — the rules below describe what
collaborative mode requires, not universal behaviour.

Every phase follows: **Identify → Confirm → Generate → Review → Approve → Write**

- Never write an inventory or a manifest without first confirming the list with
  the user.
- Ask "May I write this to `<path>`?" before every write to
  `design/inventory/screen-inventory.md` and `design/inventory/media-manifest.md`.
- Anchor media specs to the design language — a spec that contradicts it is wrong,
  or the design language needs a revision first (`/design-language`).
- Surface every specialist disagreement; do not silently pick one.
- Name every source not found and every specialist not consulted, in the file and
  in the summary.

---

## Recommended Next Steps

- Run `/ux-design [slug]` for each MVP screen still `Needed`, then `/ux-review` on
  each spec.
- Run `/design-language` if components or media rules referenced here are not
  defined yet.
- Run `/ui-inventory media` once the design language's section 6 is written.
- Rerun `/ui-inventory` after new PRDs are approved or `/ux-design` adds specs, to
  keep statuses current.
