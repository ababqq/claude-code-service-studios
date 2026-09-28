---
paths:
  - ".claude/agent-memory/**"
---

# Agent Memory Rules

**Agent memory is the one place an agent may write without asking — and the only
one.** `.claude/agent-memory/` is gitignored, per-agent, and never ships. That
exemption exists because the memory is the agent's own working notes about how to
do its job, not a project artifact.

It does **not** extend anywhere else. The Collaboration Protocol still governs
every file in the code roots `project.yaml` declares (`apps/`, `services/`,
`packages/`, `infra/` or wherever `stack.layers.<layer>.root` points) and every
file under `design/`, `docs/`, `tests/` and `production/`: ask first, naming the
path. Writing a memory is never a substitute for asking, and a memory must never
be used to record something the user declined to have written.

## Never record a temporary absence as a durable fact

This is the failure this file exists to prevent, and this repo is unusually
exposed to it.

**CCSS ships as a template the user clones *as their product*.** So on the first
run every agent observes the same things — no code roots, no PRDs, no stack
configured (`stack.pinned_on` unset), no `tests/load/` — and every one of those
observations is **guaranteed to stop being true**. A memory reading *"this repo is
the framework, not a product; load-test requests have no target"* is accurate when
written and actively harmful two weeks later, when it tells a future run to return
BLOCKED on a project that now has an API deployed to staging. The agent will not
re-derive it; that is what memory is for.

So:

- **Prefer recording a method over a state.** "Confirm a declared code root and a
  reachable staging URL (or a captured trace) exist before profiling; return
  BLOCKED naming what is missing rather than estimating" is durable. "There is no
  product here" is a timestamp.
- **If you must record a state, state what invalidates it**, on the same line:
  `INVALIDATED WHEN: project.yaml sets stack.pinned_on, or any stack.layers.<layer>.root contains code.`
  A reader with no other context must be able to tell whether the note still
  holds.
- **Never record absence of a product, of code, of tests or of config as a
  settled property of the project.** Those are the states CCSS exists to move a
  user out of.

## Disclose the write

Say in your response that you recorded a memory and where. An unmentioned write
is indistinguishable from no write, and the user cannot correct a note they do
not know exists — the same reason a skipped check has to announce itself
(`.claude/rules/skill-authoring.md`, obligation 3).

## Verify before you trust

A recalled memory reflects what was true when it was written. If it names a file,
a path, a setting or a count, **check that it still holds before acting on it**.
Memory is a starting point for investigation, never evidence.
