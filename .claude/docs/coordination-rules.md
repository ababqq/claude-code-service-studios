# Agent Coordination Rules

1. **Vertical Delegation**: Leadership agents delegate to department leads, who
   delegate to specialists. Never skip a tier for complex decisions.
2. **Horizontal Consultation**: Agents at the same tier may consult each other
   but must not make binding decisions outside their domain.
3. **Conflict Resolution**: When two agents disagree, escalate to the shared
   parent. If no shared parent, escalate to `product-director` for product, UX
   and design conflicts or `technical-director` for technical and quality
   conflicts.
4. **Change Propagation**: When a product or PRD change affects multiple
   domains, the `delivery-manager` agent coordinates the propagation.
5. **No Unilateral Cross-Domain Changes**: An agent must never modify files
   outside its designated directories without explicit delegation.

## Model Tier Assignment

Read `.claude/docs/model-tiers.md` on demand. It carries the tier table, the
per-skill assignments and the authoring rule.

**One line of it is load-bearing enough to restate here:** a skill's `model:`
frontmatter is **declared but not applied** — Claude Code reads it and serves the
skill from the session model regardless. Never tell a user that a skill's tier
is saving them money. The agent-side `model:` is a different mechanism and is
untested, not known-broken.

## Subagents vs Agent Teams

This project uses two distinct multi-agent patterns:

### Subagents (current, always active)
Spawned via the `Agent` tool within a single Claude Code session (renamed from
`Task` in Claude Code 2.1.63; `Task` still works as an alias). Used by all
`team-*` skills and orchestration skills. Subagents share the session's
permission context, run sequentially or in parallel within the session, and
return results to the parent.

**Who can spawn whom**: the stack leads are the only agents with an `Agent(...)`
grant in their `tools:` — `web-specialist`, `mobile-specialist` and
`backend-specialist`, each limited to its own framework sub-specialists
(`data-specialist` and `cloud-specialist` have no sub-specialists and no grant).
It is the one place vertical delegation is declared in the grant itself. The grant
is **declared but untested** when the lead itself runs as a subagent (a skill spawns
it), where nested spawning may be unavailable: the lead then applies the sub's
standards itself or returns a named hand-off, and states
`NOT CONSULTED — <sub> (nested spawn unavailable)`. Every other agent, directors
included, delegates by naming the agent and the task in its response; the calling
skill or the user spawns it.

**When to spawn in parallel**: If two subagents' inputs are independent (neither
needs the other's output to begin), spawn both `Agent` calls simultaneously
rather than waiting. Example: `/review-all-prds` **Phase 2** (consistency) and
**Phase 3** (product holism) are independent — spawn both at the same time.
Phase 1 loads the PRDs and both depend on it, so it is the one phase here that
must NOT be parallelised.

### Agent Teams (experimental — opt-in)
Multiple independent Claude Code *sessions* coordinated via a shared task list.
Opt-in and never yet used here — read `.claude/docs/agent-teams.md` on demand
before proposing one.

## Parallel Task Protocol

When an orchestration skill spawns multiple independent agents:

1. Issue all independent `Agent` calls before waiting for any result
2. Collect all results before proceeding to dependent phases
3. If any agent is BLOCKED, surface it immediately — do not silently skip
4. Always produce a partial report if some agents complete and others block
