---
name: bundle-audit
description: "Per-route JS/CSS, images, fonts (CJK subsetting) and mobile app size against budgets; static-asset naming."
argument-hint: "[surface:<web|ios|android> | full]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash, Agent, Bash(bash "*/.claude/skills/bundle-audit/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,performance.enforce,surfaces,stack,code_roots`

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

# Bundle Audit

Measures what the product makes users download — initial JavaScript and CSS per web
route, images, web and app fonts (with Korean and other CJK font subsetting), and
mobile app download and install size — against the committed budgets, and checks
static-asset naming and hygiene (naming conventions, orphaned and missing assets,
duplicates).

| Output | Path |
|--------|------|
| Audit report (with the verdict line) | `production/qa/perf/bundle-audit-YYYY-MM-DD.md` |

**When to run:** in Hardening (catalog step `bundle-audit`), before a release whose
changes add dependencies, fonts or media, and whenever `/perf-profile` shows an LCP or
bundle breach it cannot attribute. `/perf-profile` reads the newest report of this
skill for its `performance.bundle_kb` row.

Verdict vocabulary (exact): `PASS | CONCERNS | FAIL | NOT ASSESSED`.

---

## Measuring sizes requires Bash

This report asks for **compressed sizes per route**, **file sizes and image
dimensions**, **font file sizes and glyph coverage** and **app download and install
sizes**. None of those is obtainable from `Read`/`Glob`/`Grep` — they need a build,
`stat`, `gzip`, an image or font inspector, or the platform's size tooling — so `Bash`
is declared for exactly that.

**If you cannot take a measurement, the cell is `NOT ASSESSED`, never an estimate.**
A size table filled from guesses is worse than an empty one: it looks like evidence.
If the report demands numbers the tools cannot produce, the only way to complete it
is to invent them — so do not complete it that way.

---

## Insufficient input — check this before producing any report

**If the inputs this skill needs do not exist, the answer is "could not run" —
not a filled-in report.** Check first, and stop if the check fails.

1. List the inputs this skill reads (the budget in `project.yaml`, the build command,
   build output, source and static files in the resolved code roots, the media
   manifest, prior bundle-audit reports, platform size reports).
2. For each, record `FOUND` or `ABSENT` — not "assumed present".
3. If any input required for a section is ABSENT, that section is
   **`NOT ASSESSED — NO DATA`**. Do not estimate it, do not infer it from an
   adjacent artifact, and do not leave a mandated cell to be filled by whoever
   reads the template next.
4. If **every** required input is ABSENT, stop and report
   **`NOT ASSESSED — NO DATA`** as the whole verdict, naming what was missing and
   which skill or setting produces it.

**A verdict of `NOT ASSESSED` is a success.** It is the correct, useful answer to
"what does the data say?" when there is no data. The failure mode this prevents is
specific: report templates whose verdict enum had no "could not run" state produced
**false clean passes** — an asset audit returning a clean result on a project with no
assets and no standards, and a performance profile reporting comfortable headroom with
zero measurements and no budget ever set.

**Absence of evidence is never evidence of absence.** A scan that finds no oversized
images because no code root resolved has not verified anything. Say which of the two
happened — a reader cannot tell from a green result.

---

## Phase 0: Resolve Configuration

Read the resolved block above; do not re-derive any of its values.

**`performance.enforce`** decides what a breach of a `performance.*` budget means:

| Value | Effect |
|-------|--------|
| `warn` | A breach makes the verdict **CONCERNS**. |
| `block` | A breach makes the verdict **FAIL**; `/gate-check` treats it as a blocker at the `hardening` and `launch` gates. |
| `off` | Budgets are informational: record every measurement and breach, score none, and write `Budgets not scored — performance.enforce: off` in the report. |

It is locally overridable, so use the resolved line, never a direct read of
`project.yaml`.

**`surfaces`** selects the families: `web` → per-route JS/CSS, images, web fonts;
`ios` / `android` → app size, bundled fonts and media. When the line says
`platform.surfaces: (unset -- ask which surfaces ship)`, ask the user in plain text
before auditing; without an answer, audit only what the argument names and mark the
rest `NOT ASSESSED — platform.surfaces unset`.

**`stack`** selects the build and analysis tooling (Phases 2 and 5). A layer under
`unset=` gets `NOT CHECKED — <layer> layer not configured (run /setup-stack)`.

**`code_roots`** lists where to look for source, static assets and references. When the
line says `code_roots: unresolved — NOT CHECKED …`, print it in `### Not Checked`: the
per-route, image, font and naming families cannot run, so the verdict cannot be PASS.
If the line lists `undeclared=` roots, include them and print
`WARN: undeclared code roots: <dirs> — declare them with /setup-stack`.

---

## Phase 1: Scope and Inputs

Parse the argument: `surface:web`, `surface:ios`, `surface:android`, or `full` (also
the default — announce it). A surface not in a set `platform.surfaces` is
`N/A — <surface> not configured`.

Read with Read (none of these has a `resolve_config` label):

- `project.yaml` → `performance.bundle_kb` (initial JavaScript per route, gzip — the
  scored budget; spell the key in full), `commands.build`, `platform.browsers`
  (browserslist targets — decides which polyfills and transpilation are justified),
  `naming.files` (file naming convention for static assets);
- `docs/architecture/architecture.md` (its NFR budgets section) and the PRDs'
  `## Non-Functional Requirements` → any **documented** size target (app download size,
  per-image weight) — used with its source, see Phase 7;
- `design/inventory/media-manifest.md` → the specified format, dimensions and weight of
  each media asset, if the manifest exists;
- `design/inventory/screen-inventory.md` and `docs/ops/slo.md` `## Critical User
  Journeys` → which web routes matter most;
- the newest `production/qa/perf/bundle-audit-*.md` → the previous run to compare against;
- the newest `production/qa/perf/perf-profile-*.md` → routes with LCP or bundle
  breaches (those routes are audited first).

`performance.bundle_kb` unset ⇒ the per-route rows are measured but
`NOT ASSESSED — budget unset (set performance.bundle_kb via /settings)`; do not score
against a number nobody chose.

---

## Phase 2: Web — Per-Route JavaScript and CSS

1. **Build for production.** Run `commands.build` (announce the command first). No
   build command ⇒ `NOT ASSESSED — commands.build unset (set it via /setup-stack or
   /settings)` for every route row. A development build is never measured.
2. **List the routes.** Derive them from the framework's routing (Next.js `app/**/page.*`
   or `pages/**`, Nuxt `pages/**`, SvelteKit `routes/**`, the router configuration of a
   single-page app) inside the resolved web roots; cross-check against the web rows of
   the screen inventory. Audit the critical-journey routes first; in `full` scope audit
   every route, grouping dynamic segments (`/goals/[id]`) as one route.
3. **Measure initial JavaScript per route** — the scripts a first visit to the route
   downloads before it is interactive, compressed, in kilobytes:
   - **Preferred, framework-independent**: serve the production build locally and load
     each route in headless Chromium (Playwright when installed), recording script
     responses; or use Lighthouse's resource summary for the route.
   - **From build artifacts**: map each route to its initial chunks with the bundler's
     manifest or stats (`.vite/manifest.json`, webpack stats, the Next.js build
     manifests or `@next/bundle-analyzer`, `nuxi analyze`, `rollup-plugin-visualizer`),
     then compress each chunk with `gzip -9 -c <file> | wc -c`.
   - The budget is **gzip**. If the CDN serves Brotli, still compute gzip for the budget
     row and report the Brotli transfer size beside it. Never mix the two in one column.
   - Use the framework's own size output only when the pinned version prints one — check
     `docs/stack-reference/<component>/` before relying on a column that a newer version
     may have removed.
4. **Measure render-blocking CSS per route** and flag unused CSS shipped to the route.
5. **Explain the biggest routes.** For each route over budget or in the top five by
   size, list the largest modules and the cause:
   - heavy dependencies in the initial bundle (date libraries with bundled locales, the
     whole of a utility library, charting, rich-text editors, full icon packs through
     barrel imports) and a lighter alternative or a lazy import;
   - duplicate packages (two versions of one library);
   - client-side code that the framework could render on the server;
   - polyfills and transpilation beyond the `platform.browsers` targets
     (`platform.browsers` unset ⇒ `NOT CHECKED — platform.browsers unset`);
   - third-party tags loaded on first visit (analytics, chat widgets, A/B testing).

---

## Phase 3: Images

Glob the image files in the resolved roots' static directories (`public/`, `static/`,
`assets/`, iOS asset catalogs, Android `res/drawable*` and `res/mipmap*`, the mobile
app's asset folders) and measure each with Bash (`stat` for bytes; `sips -g pixelWidth
-g pixelHeight` on macOS or ImageMagick `identify` for dimensions; `file` for format).

Check:

- **Format** — photographs and illustrations as AVIF or WebP (with a fallback only when
  `platform.browsers` needs one); PNG only for images that need lossless edges; SVG
  optimized (no editor metadata, no embedded rasters).
- **Dimensions** — intrinsic size far above the largest rendered size (use the media
  manifest's spec, or the component's declared size), missing responsive variants
  (`srcset`/`sizes` or the framework's image component).
- **Loading** — the LCP image of each key route loads eagerly with high fetch priority;
  below-the-fold images load lazily; every image has reserved dimensions (layout shift).
- **Weight** — no `performance.*` key budgets individual images. Report the heaviest
  images; compare with a per-image target only when the media manifest or a documented
  NFR states one (cite it).
- **App icons and store assets** are checked against the media manifest's spec, not
  against a web weight.

---

## Phase 4: Fonts (CJK subsetting)

List every font the product ships: `@font-face` rules, the framework's font loader
(`next/font`, `@nuxt/fonts`, …), font files in static directories, and fonts bundled into
the mobile apps. Measure each file.

A full Korean font is large because it covers every modern Hangul syllable — 11,172 of
them — plus Latin and symbols. Check which delivery strategy each font uses and whether
it fits the text it renders:

| Strategy | What it ships | Safe for user-generated text? |
|----------|---------------|-------------------------------|
| **Unicode-range slicing** (dynamic subsets) | The font split into many `unicode-range` slices; the browser downloads only the slices the page uses | Yes — every syllable still resolves |
| **Static subset** (e.g. the 2,350 syllables of KS X 1001 + Latin + digits + punctuation) | One much smaller file | **No** — syllables outside the set (rare names, user input) fall back to another font mid-word. Fixed UI text only |
| **System font stack** (Apple SD Gothic Neo, Malgun Gothic, Noto Sans CJK on Android) | Nothing | Yes |

Also check: WOFF2 only on the web (no TTF/OTF served); `font-display: swap` or
`optional`; preload only the font and slice needed above the fold; the number of
weights (one variable font or a small set of static weights, not every weight);
fallback metric overrides (`size-adjust`, `ascent-override`) or the framework loader's
automatic fallback to limit layout shift; the same font not shipped twice (self-hosted
and from a CDN). For mobile apps, a bundled CJK font adds directly to app size — prefer
the system font unless the design language requires a brand font
(`design/brand/design-language.md` `## 3. Typography`).

---

## Phase 5: Mobile App Size

Measure release builds only. The user may run the platform commands and hand over the
output — record who produced it.

- **iOS** — export the archive with app thinning enabled
  (`xcodebuild -exportArchive` with a thinning option in the export options); read the
  "App Thinning Size Report" for compressed (download) and uncompressed (install) size
  per device variant. App Store Connect's per-device sizes are the field equivalent after
  upload.
- **Android** — build the App Bundle, then `bundletool build-apks` and
  `bundletool get-size total --apks=<file>.apks` for download size by device
  specification; Play Console's app size report is the field equivalent.
- **Flutter** — `flutter build appbundle --analyze-size` (Android) and
  `flutter build ios --analyze-size` (iOS) for a per-package breakdown, viewable in
  DevTools' app size tool.
- **React Native** — the JavaScript bundle size (Hermes bytecode), native modules
  included but unused, and bundled images and fonts.
- **Shrinking** — Android R8 code shrinking and resource shrinking enabled for release;
  unused locales and densities excluded; large, rarely used assets delivered on demand
  (Play Asset Delivery, iOS on-demand resources) instead of bundled.

**Budget:** no `performance.*` key budgets app size. Report the sizes as informational
unless a documented target exists (Phase 1); store thresholds (Apple's cellular download
limit, Play's size warnings) may be cited only from the store's current documentation
with a retrieved date — never from memory (`NOT SOURCEABLE — <threshold>` otherwise).
Compare with the previous report: a jump of more than a few percent between releases
deserves a line in `## Ranked Recommendations` even without a budget.

---

## Phase 6: Static-Asset Naming and Hygiene

- **Convention** — `naming.files` from `project.yaml` (e.g. `kebab-case`); check the
  static assets in the resolved roots against it. Unset ⇒
  `NOT CHECKED — naming.files unset (set it via /setup-stack)`.
- **Platform rules that apply whatever the convention says** — Android resource file
  names may contain only lowercase letters, digits and underscores (the build rejects
  anything else); web public files served by URL avoid spaces and uppercase (hosting
  and CDN paths are case-sensitive); files under `public/` that are not content-hashed
  need a short cache lifetime or a versioned name.
- **Orphaned assets** — static files with no reference in any resolved root, the design
  language or the content decks (search for the file name and its stem). Recommend
  removal only after manual review — dynamic references (`/icons/${name}.svg`) are
  invisible to a text search, so say how each orphan was checked.
- **Missing assets** — references in code to static files that do not exist.
- **Duplicates** — identical content under different names (`shasum` over the static
  directories).

---

## Phase 7: Score, Consult and Rank

Scoring:

| Finding | Effect on the verdict |
|---------|-----------------------|
| Route over `performance.bundle_kb` | Per `performance.enforce`: FAIL (`block`), CONCERNS (`warn`), not scored (`off`) |
| Over a **documented** target (architecture NFR, PRD NFR, media manifest) | CONCERNS — a documented target, not a configured budget; `performance.enforce` governs `performance.*` keys only |
| Hygiene finding rated **High** (e.g. a multi-megabyte image on a key route, a full CJK font blocking first render, a missing asset on a critical journey) | At least CONCERNS |
| Hygiene finding rated Medium or Low | Recommendation only |

**Verdict** (precedence **FAIL > CONCERNS > NOT ASSESSED > PASS**):

- `FAIL` — at least one route breaches `performance.bundle_kb` under `block`;
- `CONCERNS` — a breach under `warn`, a documented target missed, or a High hygiene
  finding;
- `NOT ASSESSED` — none of the above, but an in-scope family could not be measured
  (budget unset, no build command, unresolved code roots, no mobile build output);
- `PASS` — every in-scope route measured within budget, app size reported, no High
  hygiene finding.

Then brief `performance-engineer` via `Agent` with the measurement tables and findings
(inline, not as file paths) and the resolved `stack` line. Return contract: *"Do not
write any file. Return only (1) the recommendations ranked by expected saving ÷ effort,
each with the route or asset, the expected saving in kB (measured or estimated), effort
S/M/L and risk, (2) any measurement you believe is wrong and why, (3) BLOCKED items, one
line each."* If it is blocked, rank the recommendations yourself and write
`performance-engineer not consulted — <reason>` in `## Scope`.

---

## Phase 8: Write the Report

Ask: "May I write this to `production/qa/perf/bundle-audit-YYYY-MM-DD.md`?" Create
`production/qa/perf/` if absent; if today's report exists (an earlier run with another
scope), ask before overwriting it. Keep every `NOT ASSESSED` row in the written file.

```markdown
# Bundle Audit

> **Verdict**: [PASS | CONCERNS | FAIL | NOT ASSESSED]

> **Date**: [YYYY-MM-DD]
> **Enforcement**: performance.enforce = [warn | block | off] ([source]) [— Budgets not scored, when off]
> **Build**: [commit SHA / app version (build number)]
> **Generated by**: /bundle-audit

## Scope

- Argument: [surface:web | full]
- Surfaces audited: [list] — not audited: [list with reason]
- Stack: [resolved `stack` line]
- Code roots: [resolved `code_roots` line]
- Consulted: performance-engineer [or "not consulted — <reason>"]

## Budgets

| Surface | Budget | Key / source | Value |
|---------|--------|--------------|-------|
| web | Initial JS per route (gzip) | `performance.bundle_kb` | [value or unset] |
| ios / android | App download size | [documented source or "none — informational"] | [value or —] |

## Measurements

### Web — Per-Route JavaScript and CSS

| Route | Initial JS (gzip kB) | Brotli transfer (kB) | Render-blocking CSS (kB) | Largest modules | Method |
|-------|----------------------|----------------------|--------------------------|-----------------|--------|

### Images

| Asset | Format | Dimensions | Size (kB) | Used on | Finding |
|-------|--------|------------|-----------|---------|---------|

### Fonts

| Font | Files / slices | Total size (kB) | Strategy | Preloaded | Finding |
|------|----------------|-----------------|----------|-----------|---------|

### Mobile App Size

| Platform | Build | Download size | Install size | Largest contributors | Change vs previous | Produced by |
|----------|-------|---------------|--------------|----------------------|--------------------|-------------|

## Breaches

| Item | Budget | Measured | Over by | Scored as |
|------|--------|----------|---------|-----------|

## Naming & Hygiene

| File | Issue (naming / orphaned / missing / duplicate) | Rule or evidence | Rating | Recommendation |
|------|-------------------------------------------------|------------------|--------|----------------|

## Ranked Recommendations

1. **[Title]** — [route or asset]
   - Expected saving: [kB] ([measured | estimated])
   - Effort: [S/M/L] · Risk: [Low/Med/High]
   - Approach: [how]
   - Verify with: [rerun /bundle-audit; the measurement to compare]

### Not Checked

- [Every skipped family, root or setting, with its reason]
```

After writing, confirm the file exists and the verdict line sits directly under the H1.
Print a summary: the verdict, the three largest routes against the budget, the font and
app-size headline numbers, and every `NOT ASSESSED` or `NOT CHECKED` line.

---

## Phase 9: Next Steps

Close with the next steps that apply, as a short list:

- Budget unset → `/settings performance.bundle_kb=<n>`.
- Fixes to schedule → `/quick-spec` or `/create-stories`, then `/sprint-plan`.
- A dependency swap or rendering-strategy change → `/architecture-decision` (and record
  the library in `docs/architecture/tech-radar.md` through it).
- Font or media decisions that belong to the design language → `/design-language`; media
  specs → `/ui-inventory media`.
- Confirm the effect on user-facing metrics → `/perf-profile surface:web` (or the route).
- After fixes → rerun `/bundle-audit` and compare.

---

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and `autonomous`
modes, see `.claude/docs/automation-modes.md`.

- **Measure, never estimate** — a size that was not measured is `NOT ASSESSED`.
- **Recommend, do not delete** — orphaned or duplicate assets are listed for review;
  this skill removes nothing and changes no dependency.
- **Name the gaps** — every skipped family, surface or setting appears under
  `### Not Checked`.
- Ask "May I write this to `<path>`?" before writing; this skill writes only its report.
