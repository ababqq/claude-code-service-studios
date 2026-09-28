# Skill Spec: /setup-stack

> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-09-28

<!-- Assertions quote the canonical English text of .claude/skills/setup-stack/SKILL.md —
     prompts, AskUserQuestion option labels, verdict tokens, headings — never the
     wording the model uses at run time in the user's conversation language. -->

## Skill Summary

`/setup-stack` decides what the product is built on and makes that decision safe for
every agent after it. It detects manifests and workspace layout, asks the product facts
later gates branch on (`platform.surfaces`, `release.distribution`,
`compliance.regions`, `privacy.handles_pii`, `localization.locales`, and `design.tool`
when a UI surface is chosen or surfaces were deferred — each may be deferred, and a
deferred key stays unset), chooses each **decided** stack layer (web,
mobile, backend, data, cloud — data and cloud may wait for their Foundation ADRs),
optionally validates the choices with the layer leads, pins every configured component
**from a live source** (Context7 if its tools are present in the session, else
WebSearch/WebFetch) with source URL, retrieval date and Knowledge Risk, declares the code
roots, and writes `project.yaml` (`stack.*`, `specialists.*`, `naming.*`, `commands.*`,
`platform.*`, `release.*`, `privacy.*`, `compliance.*`, `localization.*`, `design.*`).

It then fills `docs/stack-reference/VERSION.md` and `docs/stack-reference/<component>/*.md`,
seeds `docs/architecture/tech-radar.md`, offers `<root>/CLAUDE.md` per root, runs
`bash .claude/scripts/project-coherence.sh`, and writes `stack.pinned_on` **last** —
only when every configured component is sourced, `n/a (managed service)` or an accepted
`NOT DETERMINED — accepted by user YYYY-MM-DD`. Modes: guided setup (optionally with a
preset), `refresh`, and `upgrade <component> <old> <new>`, which spawns TD-STACK-RISK.
It is always collaborative, never guesses a version, never edits the repository-root
`CLAUDE.md`, ADRs or source code, and ends `Verdict: COMPLETE | INCOMPLETE | NOT ASSESSED`
(precedence INCOMPLETE > NOT ASSESSED > COMPLETE).

---

## Static Assertions

These should pass before any behavioral testing:

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`); `name: setup-stack` equals the directory `.claude/skills/setup-stack/` and the catalog entry `setup-stack`
- [ ] `description` is exactly "Choose each stack layer, pin versions from live sources, populate the stack reference, declare code roots, route specialists."
- [ ] `argument-hint` is `"[profile] | refresh | upgrade <component> <old> <new> | no args for guided setup"`; `model: sonnet`; no `disable-model-invocation` and no `isolation` key
- [ ] Bootstrap: the first body line is `` !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,workflow,stack,code_roots` `` — this key string exactly (no `automation`)
- [ ] `allowed-tools` grants `Bash(bash "*/.claude/skills/setup-stack/../../hooks/yaml-helper.sh" resolve_config *)` — the skill's own directory name
- [ ] The line after the bootstrap block is exactly ``Resolved above — use as-is; `--review` overrides `review_mode`. No block → defaults in `.claude/docs/config-resolution.md`.``
- [ ] No automation prelude anywhere (always-collaborative; `.claude/docs/automation-modes.md` § Exemptions — Skills That Ignore the Automation Setting)
- [ ] `allowed-tools` is exactly: `Read, Glob, Grep, Write, Edit, Bash, WebSearch, WebFetch, Agent, AskUserQuestion` + the grant; no MCP tool name is listed
- [ ] 2+ phase headings (`## Phase 1: Parse Arguments` … `## Phase 14: Summary, Verdict and Next Steps`)
- [ ] Verdict tokens present exactly: `COMPLETE`, `INCOMPLETE`, `NOT ASSESSED`; Knowledge Risk values `LOW`, `MEDIUM`, `HIGH`; gate tokens `APPROVE`, `CONCERNS`, `REJECT`
- [ ] "May I write this to `<path>`?" before every write — `project.yaml`, the stack reference set, `docs/architecture/tech-radar.md`, each `<root>/CLAUDE.md`, the upgrade record — and the marker question "May I write this to `project.yaml` (`stack.pinned_on: <today>`) and `docs/stack-reference/VERSION.md` (the `**Stack Pinned**` row)?"
- [ ] Outputs at the exact paths `project.yaml`, `docs/stack-reference/VERSION.md`, `docs/stack-reference/<component>/*.md`, `docs/architecture/tech-radar.md`, `<root>/CLAUDE.md`, and in `upgrade` mode the upgrade record `docs/stack-reference/<component>/upgrade-<old>-to-<new>.md`, which carries `> **Verdict**:` directly under its H1
- [ ] Presets named exactly `ts-fullstack-web`, `expo-mobile-ts-api`, `flutter-spring`, `python-api-react` from `.claude/skills/setup-stack/references/profiles.md`; presets never propose a version
- [ ] Never writes `project.stage`, any `modes.*` key or the six knobs `modes.rigor` fronts
- [ ] No `!` injection other than the bootstrap line; no `file:line` citations of other files
- [ ] Next-step handoff at the end names current skills (`/brainstorm`, `/create-stories`, `/dev-story`, `/test-setup`, `/prd-review`, `/prototype`, `/gate-check definition`, `/architecture-decision`, `/setup-stack refresh`, `/architecture-review`, `/help`)

---

## Director Gate Checks

- **Gate**: TD-STACK-RISK (owner `technical-director`), `upgrade` mode only, Phase 13e; the prompt tells the agent to read `.claude/docs/director-gates/td-stack-risk.md` first; ``Pass: component and version change (old → new, or pinned version) · `docs/stack-reference/<component>/` path · ADR paths whose `## Stack Compatibility` names the component``
- **Full mode**: spawns
- **Lean mode**: skip every gate whose ID does not end in `-PHASE-GATE` — note `[TD-STACK-RISK] skipped — Lean mode`
- **Solo mode**: no gates — note `[TD-STACK-RISK] skipped — Solo mode`
- The layer-lead validation of Phase 4e is a consultation, not a director gate: `review_mode` never skips it (only the user does)

---

## Test Cases

### Case 1: Happy Path — Guided setup of the Moa monorepo

**Fixture** (assumed project state):
- `project.yaml` exists with no `stack` block; `modes.rigor: standard`; `design/product/product-brief.md` names web, iOS and Android and the Korean market
- `pnpm-workspace.yaml`, `turbo.json`, `pnpm-lock.yaml`; `apps/web/package.json` and `apps/admin/package.json` depend on `next`; `apps/api/package.json` on `@nestjs/core` and `prisma`; `apps/mobile/app.json` has an `expo` key
- Network access to official release pages is available

**Input:** `/setup-stack`

**Expected behavior:**
1. Phase 2 reads `project.yaml` and the brief, Globs the manifests (skipping `node_modules`, `.next`, `dist` and the rest of the prune list) and presents detected layers as proposals
2. Phase 3 asks the product facts with `Decide later — leave unset` available; the answers are `platform.surfaces: [web, ios, android]` (the API the apps call is not the `api` surface), `release.distribution: web+stores`, `compliance.regions: [kr]`, `privacy.handles_pii: true`, `localization.locales: [ko-KR]`; because a UI surface is chosen, question 8 asks `design.tool` with `Claude Design` / `Figma` / `None — markdown specs only` / `Decide later — leave unset`, and the answer is `Figma` with the project-level `design.figma.file_url`
3. Phase 4 confirms web (`[apps/web, apps/admin]`), mobile (`apps/mobile`), backend (`apps/api`); data and cloud get `Leave unset until the ADR (Recommended)`; with `kr`, Kakao Login, Naver Login, Sign in with Apple, Toss Payments and in-app billing are offered as `## Assess` candidates only
4. Phase 4e asks "Validate these layer choices with the stack leads before pinning versions?"; on validate, spawns `web-specialist`, `mobile-specialist`, `backend-specialist` in parallel
5. Phase 5 pins each component from a live source and shows one table: `| Layer | Component | Version | Release date | Knowledge Risk | Source | Retrieved |`
6. Phase 7 shows the draft and asks "May I write this to `project.yaml`?" — flow-style lists, quoted framework versions, no `stack.pinned_on`; the `design:` block carries `tool: figma` and the double-quoted `file_url`; then reads back with `bash .claude/hooks/yaml-helper.sh resolve_config --keys stack,code_roots,surfaces,distribution,compliance,design`, which prints `design.tool: figma file_url=<url> (project.yaml)`
7. Phases 8–10 write the reference set, seed the tech radar (`## Adopt` without versions in the names) and offer `<root>/CLAUDE.md` per root, each after its approval
8. Phase 11 runs `project-coherence.sh`, then writes `stack.pinned_on` and the `**Stack Pinned**` row after the marker question, re-reads both, and confirms `bash .claude/scripts/artifact-check.sh --phase discovery` reports `stack-setup` `status=PRESENT`
9. Phase 14 prints the summary with `Verdict: COMPLETE` and the `standard / full` next steps

**Assertions:**
- [ ] Every version carries a source URL and a retrieval date; no version comes from memory
- [ ] `stack.pinned_on` is the last write and only after the completion check holds
- [ ] `VERSION.md` rows use Layer ∈ `web|mobile|backend|data|cloud` and the Component name without a trailing version
- [ ] The repository-root `CLAUDE.md` is not modified
- [ ] Unset data and cloud layers do not block `stack.pinned_on`
- [ ] The Phase 14 `Product facts:` line includes `design=figma`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 2: Blocked — An unresolved `NOT DETERMINED` component

**Fixture:**
- As Case 1, but no source confirms a version for the chosen web framework and the user picks `Leave it unresolved (blocks stack.pinned_on)`

**Input:** `/setup-stack`

**Expected behavior:**
1. Phase 5d asks "No live source confirmed a version for `<component>`. Accept the gap for now?" with `Accept the gap — record it and continue` / `I'll give a source URL` / `Leave it unresolved (blocks stack.pinned_on)`
2. The row is written `NOT DETERMINED` (Knowledge Risk HIGH)
3. Phase 11b finds an unresolved configured component: `stack.pinned_on` is **not** written; the blocking component is listed
4. Phase 14 ends `Verdict: INCOMPLETE` with `stack.pinned_on: not written — <blocking components>`

**Assertions:**
- [ ] No remembered number replaces `NOT DETERMINED`
- [ ] `stack.pinned_on` stays absent
- [ ] `/setup-stack refresh` is offered to resolve the item later

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 3: NOT ASSESSED — Missing configuration file, nothing decided, or no live source

**Fixture A:** `project.yaml` does not exist.
**Fixture B:** `project.yaml` exists; the user leaves every layer unset in Phase 4.
**Fixture C:** `project.yaml` exists; a web framework is chosen; Context7, WebSearch and WebFetch are all unavailable; no gap is accepted (the user leaves each `NOT DETERMINED` unresolved).

**Input:** `/setup-stack`

**Expected behavior:**
1. A: stops with "No `project.yaml` at the repository root — run `/start` first; it creates the file this skill writes into."
2. B: nothing can be pinned; no marker is written; the summary says every layer was left unset and ends `Verdict: NOT ASSESSED`
3. C: every component stays `NOT DETERMINED`; no marker is written; the summary says no live source could be reached and ends `Verdict: NOT ASSESSED`

**Assertions:**
- [ ] A: no file is created and no layer question is asked
- [ ] B: verdict is NOT ASSESSED with the reason, never COMPLETE; `stack.pinned_on` is not written
- [ ] Unset layers are "not decided yet", never written as `none` or a placeholder
- [ ] C: verdict is NOT ASSESSED, not INCOMPLETE; no version is filled from memory

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 4: Mode Variant — `refresh` after a Data ADR is Accepted

**Fixture:**
- `stack.pinned_on: 2026-09-20`; web, mobile and backend configured
- `docs/architecture/adr-0002-primary-datastore.md` is Accepted; its `## Stack Compatibility` has `**Domain**` `Data` and `**Stack Components**` PostgreSQL and Redis, not yet configured

**Input:** `/setup-stack refresh`

**Expected behavior:**
1. Proposes the data layer from the ADR (`database: PostgreSQL 16`, `cache: Redis 7`, `orm: Prisma 6`), confirms its keys and `migrations_dir`, and pins the new components
2. Re-fetches every source; updates `Retrieved` only for rows actually re-verified; a dead source is `could not re-verify — <url>` with the old date kept
3. Reports drift as `upgrade candidate: <component> <pinned> → <new>, released <date> — run /setup-stack upgrade <component> <pinned> <new>` — never bumps a version in refresh
4. Rewrites `stack.pinned_on` and the `**Stack Pinned**` row under the same completion condition

**Assertions:**
- [ ] Data components keep their version inside the component string
- [ ] No pinned version changes during refresh
- [ ] Every write is shown and asked for

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 5: Edge Case — Repository and pin disagree; a toolchain probe fails

**Fixture:**
- `node --version` fails (the runtime lives in a container); `.nvmrc` says 20; the chosen runtime pin is `Node.js 22`
- The lockfile resolves Next.js 14 while a newer stable is current

**Input:** `/setup-stack`

**Expected behavior:**
1. The failed probe is reported as `installed version NOT DETERMINED — <why the probe failed>`, never "not installed"
2. For each disagreement the skill asks `Pin what the repository uses (Recommended for existing code)` / `Pin the newer version and upgrade the code next` / `Something else`
3. When the newer pin is chosen, the summary names the expected `MISMATCH` lines from `project-coherence.sh` as known, with the reason

**Assertions:**
- [ ] A newer stable is reported as an upgrade candidate, never silently chosen for existing code
- [ ] `UNCHECKED` coherence lines are not reported as a pass
- [ ] No install, generator, migration or deploy command is run

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 6: Director Gate — full mode (`upgrade`)

**Fixture:**
- Web layer pinned at Next.js `15.3`; `docs/architecture/adr-0001-identity-and-auth.md` names Next.js in `## Stack Compatibility`
- `modes.rigor: full` (resolves `review_mode: full`); `technical-director` replies `[TD-STACK-RISK]: APPROVE`

**Input:** `/setup-stack upgrade Next.js 15.3 16.0`

**Expected behavior:**
1. 13b gathers migration facts from live sources; 13c scans every root on the `code_roots` line for deprecated APIs and presents the audit table
2. 13d lists `adr-0001-identity-and-auth.md` as **re-validation required** (not edited)
3. 13e spawns `technical-director` with the gate file path and the three-item `Pass:` line; parses `[TD-STACK-RISK]: APPROVE`
4. 13f asks once "May I write this to <paths>?" and writes `docs/stack-reference/nextjs/upgrade-15.3-to-16.0.md` with `> **Verdict**:` and `> **Technical Director Review (TD-STACK-RISK)**: APPROVED <YYYY-MM-DD>`, the updated component files, the index row and the layer's `version`
5. Rewrites `stack.pinned_on`

**Assertions:**
- [ ] The parent never reads the gate file itself
- [ ] A CONCERNS verdict would be surfaced via AskUserQuestion (`Revise flagged items` / `Accept and proceed` / `Discuss further`); a REJECT writes nothing and ends INCOMPLETE
- [ ] No source code and no ADR is edited
- [ ] An unparseable first line is treated as CONCERNS-class and named

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 7: Director Gate — lean mode

**Fixture:**
- Same as Case 6 with `modes.rigor: standard` (resolves `review_mode: lean`)

**Input:** `/setup-stack upgrade Next.js 15.3 16.0`

**Expected behavior:**
1. TD-STACK-RISK does not end in `-PHASE-GATE`: skipped
2. The upgrade record's review line is `> [TD-STACK-RISK] skipped — Lean mode`; the summary says "TD-STACK-RISK not consulted — Lean mode; `--review full` runs it."

**Assertions:**
- [ ] Output contains `[TD-STACK-RISK] skipped — Lean mode`
- [ ] No `Agent` call is made for the gate

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 8: Director Gate — solo mode

**Fixture:**
- No `modes.rigor` (resolves `review_mode: solo`); guided setup, then `upgrade`

**Input:** `/setup-stack`, then `/setup-stack upgrade Next.js 15.3 16.0`

**Expected behavior:**
1. The Phase 4e lead validation is still offered in guided setup (it is not a director gate)
2. The upgrade record's review line is `> [TD-STACK-RISK] skipped — Solo mode`

**Assertions:**
- [ ] Output contains `[TD-STACK-RISK] skipped — Solo mode`
- [ ] A lead validation the user skips prints `NOT CHECKED — <layer> choice not reviewed by <lead> (skipped by user)`

**Case Verdict**: PASS / FAIL / PARTIAL

---

### Case 9: Always Collaborative — `autonomous` does not skip approvals

**Fixture:**
- `project.local.yaml`: `modes.automation: autonomous`

**Input:** `/setup-stack`

**Expected behavior:**
1. Every question (product facts, layers, pins, gaps) is asked and every write waits for "yes"
2. Nothing is decided and logged in place of an answer

**Assertions:**
- [ ] SKILL.md carries no automation prelude and `automation` is not in its `--keys`
- [ ] Each write is preceded by its "May I write this to `<path>`?" question in this mode too

**Case Verdict**: PASS / FAIL / PARTIAL

---

## Protocol Compliance

- [ ] Question → Options → Decision → Draft → Approval for each layer, pin, root, command and product fact
- [ ] Uses "May I write this to `<path>`?" before every write; a multi-file write is approved as one listed changeset
- [ ] Unset stays unset; a deferred key is absent, never empty or `TBD` — a deferred `design.tool` (`Decide later — leave unset`) writes no `design:` block, is never written as `none`, and the 7c read-back prints `design.tool: (unset -- ask; unset is not none)`
- [ ] `design.tool` is asked only when a UI surface (`web`, `ios`, `android`) is chosen or the surfaces were deferred; an `api`-only product is not asked
- [ ] A design URL is written double-quoted, and `design.claude_design.project_url` is project level only (no `?file=`)
- [ ] Never records a production deploy command; never runs installs, generators, migrations or deploys
- [ ] Writes nothing under `production/session-logs/`; never writes `modes.review_mode` or any other knob that `modes.rigor` fronts
- [ ] Ends with a recommended next step (AskUserQuestion) and never runs it

---

## Category Rubric (`utility`)

- `utility U1` — the static checks above pass: bootstrap line and grant exact, `--keys` exact, `--review` follow-on line, no automation prelude, "May I write" before each write, output paths exact
- `utility U2` — gate mode correct for TD-STACK-RISK (Cases 6–8)
- The NOT ASSESSED case is Case 3 (missing input: no `project.yaml`, no layer decided, or no live source reachable)

---

## Coverage Notes

- The offline case — no live source reachable for any component and no gap accepted — ends NOT ASSESSED: INCOMPLETE's
  unresolved-`NOT DETERMINED` clause applies only when at least one live source was reached (Case 3, fixture C).
- `specialists.<layer>` overrides (Phase 7c) and the YAML quoting rule for commands are not fixture-tested separately.
- Knowledge Risk grading depends on the session model's stated cutoff; a cutoff that cannot be stated makes every
  component HIGH (not fixture-tested).
