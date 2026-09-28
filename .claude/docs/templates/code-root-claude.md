# [root path] — [layer] code root

<!--
TEMPLATE for <root>/CLAUDE.md — one per configured code root (every entry of
stack.layers.<layer>.root, stack.shared_roots and stack.layers.cloud.root in
project.yaml). Written by /setup-stack, asking first; never overwrites an
existing <root>/CLAUDE.md without showing the difference. /setup-stack refresh
and /setup-stack upgrade rewrite the Framework and Knowledge Risk rows when the
pin changes. The repository-root CLAUDE.md is never written from this template.

Claude Code loads this file whenever it works on files under the root, so keep
it short: pointers, not copies. project.yaml and docs/stack-reference/ stay the
sources of truth — if this file disagrees with them, they win.

Fill it from the run's own decisions:
- Layer, Framework, Runtime: stack.layers.<layer>.* (a shared root says
  `shared` and names the layers that use it; a data migrations root says `data`).
- Stack Reference: docs/stack-reference/<component-slug>/ of the layer's main
  component (the framework; for data, the database; for cloud, the IaC tool).
- Knowledge Risk: the component's row in docs/stack-reference/VERSION.md.
- Applicable Rules: DERIVED, never copied from an example — list every
  .claude/rules/*.md file whose `paths:` frontmatter globs match files under this
  root, each with its one-line focus. A rule whose globs cannot match here is left
  out.
- Commands: the exact strings from project.yaml commands.*; leave a row out when
  the key is unset (do not invent one).

Delete this comment block in the written file.
-->

This directory is a code root of the **[layer]** layer (`stack.layers.[layer].root` in `project.yaml`).

| Field | Value |
|-------|-------|
| **Layer** | [web \| mobile \| backend \| data \| cloud \| shared] |
| **Framework** | [framework] [version] ([language]) |
| **Runtime** | [runtime string, e.g. Node.js 22 — backend roots only; delete the row elsewhere] |
| **Stack Reference** | `docs/stack-reference/[component-slug]/` |
| **Knowledge Risk** | [LOW \| MEDIUM \| HIGH] (from `docs/stack-reference/VERSION.md`) |

## Before You Change Code Here

1. Read `docs/stack-reference/VERSION.md` and the component folder above before writing version-sensitive code.
   At Knowledge Risk MEDIUM or HIGH, check `deprecated-apis.md` and `breaking-changes.md` there before using an
   API. If the reference does not cover it, say `NOT SOURCEABLE — run /setup-stack refresh`; never fill the gap
   from memory.
2. Nothing on the `## Hold` or `## Forbidden Patterns` lists of `docs/architecture/tech-radar.md` is introduced
   here; a dependency that is not on the radar is named in the change, not added silently.
3. Follow `docs/architecture/control-manifest.md` when it exists — its rules for this layer are the Accepted ADRs
   in actionable form.
4. Business values (prices, limits, quotas, timeouts, fees) come from configuration or feature flags, never literals;
   secrets and personal data never appear in code, logs or fixtures.

## Applicable Rules

- `.claude/rules/[rule-file].md` — [its focus, one line]

## Commands

| Purpose | Command (`project.yaml`) |
|---------|--------------------------|
| Run | `[commands.run]` |
| Test | `[commands.test]` |
| Typecheck | `[commands.typecheck]` |
| Lint | `[commands.lint]` |
| E2E | `[commands.e2e]` |
| Migrate (dry run, disposable database only) | `[commands.migrate]` |
