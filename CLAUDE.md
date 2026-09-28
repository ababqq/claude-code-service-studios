# Claude Code Service Studios -- Product Studio Agent Architecture

Web, mobile and API service development managed through 46 coordinated Claude Code subagents.
Each agent owns a specific domain, enforcing separation of concerns and quality.

## Technology Stack

Configured per layer in `project.yaml` under `stack.*` (web, mobile, backend, data, cloud) by `/setup-stack`; code roots per layer (`.claude/docs/code-root-resolution.md`); Git with trunk-based development.

> **Note**: Stack specialists exist per layer (`web-specialist`, `mobile-specialist`,
> `backend-specialist`, `data-specialist`, `cloud-specialist`), with framework
> sub-specialists under the web, mobile and backend leads. Routing is derived from
> the configured layers — see `.claude/docs/effects-map.md` § stack.layers and specialists.

## Project Structure

@.claude/docs/directory-structure.md

## Stack Version Reference

<!-- STACK-REFERENCE-IMPORT: fixed import. /setup-stack fills the file below; nothing rewrites this line. -->
@docs/stack-reference/VERSION.md

## Technical Preferences

`project.yaml` is the only config store (resolved via `resolve_config`, see `.claude/docs/config-resolution.md`). Allowed / held / forbidden technologies and patterns live in `docs/architecture/tech-radar.md` (seeded by `/setup-stack`).

## Coordination Rules

@.claude/docs/coordination-rules.md

## Collaboration Protocol

**User-driven collaboration, not autonomous execution.**
Every task follows: **Question -> Options -> Decision -> Draft -> Approval**

- Agents MUST ask "May I write this to [filepath]?" before using Write/Edit tools
- Agents MUST show drafts or summaries before requesting approval
- Multi-file changes require explicit approval for the full changeset
- No commits without user instruction

See `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md` for full protocol and examples.

> **First session?** If the project has no stack pinned and no product brief (or
> one-pager), run `/start` to begin the guided onboarding flow.

## Language Policy

- Framework files an AI loads or a script parses are English. Human-facing docs are Korean (list:
  `.claude/docs/coding-standards.md` § Language Policy).
- Artifacts you write: keep every template heading, bold field label, status/verdict/severity token, YAML key,
  enum value, ID and path in English exactly as the template spells it; write the body in the user's
  conversation language. Never translate a heading — scripts and gates match on it.
- Talk to the user in their conversation language; quoted prompts in skills are canonical English forms.

## Coding Standards

@.claude/docs/coding-standards.md

## Context Management

Read `.claude/docs/context-management.md` on demand — it is a reference, not
session context. Two of its conventions are load-bearing and cited by name
elsewhere in the repo, so they are restated here rather than lost:

- **`production/session-state/active.md` is the session checkpoint.** The file is
  the memory, not the conversation. Read it first after any compaction, crash, or
  `/clear`.
- **Helpers in `.claude/scripts/` emit observations, never verdicts.** A script
  that scores or judges will eventually contradict a mode or override it cannot
  see. (Cited by `artifact-check.sh` and `adr-dep-graph.sh`.)
