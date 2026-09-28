# Model Tier Assignment

> ### DECLARED, NOT CURRENTLY APPLIED — skills only
>
> **Claude Code reads `model:` from a skill's frontmatter and then serves the
> skill from the session's model anyway.** This has been measured directly
> against session transcripts on several Claude Code versions, and held every
> time. To re-test it on a newer version, run a skill that declares a tier
> different from the session model and check which model the transcript
> attributes the skill's turns to.
>
> So the skill tiers below are **intent, not behaviour**. Setting one changes
> nothing today. They are kept because they are correct descriptions of what each
> skill needs, and because they cost nothing to carry if Claude Code honours them
> later — but do not budget on them, and never tell a user a tier is saving them
> money.
>
> **This does NOT apply to agents.** `model:` in `.claude/agents/*.md` is a
> different mechanism, spawned as a separate session rather than executed inline.
> It has not been measured here, so treat the agent section below as unverified
> in either direction rather than assuming it behaves the same way.

**Frontmatter is the single source of truth.** The `model:` line of each
`.claude/agents/<name>.md` and `.claude/skills/<name>/SKILL.md` is what counts;
the lists below are derived from it. When a list here and a frontmatter
disagree, the frontmatter wins and this file is corrected in the same change.

## Tiers

Frontmatter uses model aliases, never pinned model IDs; Claude Code resolves each
alias to the current model of that family.

| Tier | `model:` value | When to use |
|------|----------------|-------------|
| **Haiku** | `haiku` | Read-only status checks, formatting, simple lookups — no judgement or synthesis needed |
| **Sonnet** | `sonnet` | Implementation, spec and document authoring, analysis of one feature or one artifact — the default for skills |
| **Opus** | `opus` | Multi-document synthesis, high-stakes phase-gate verdicts, cross-feature holistic review |
| **Inherit** | `inherit` | Agents: run on the parent session's model — the default for agents in this repo |

## Skills

Skills with `model: opus`: `/architecture-review`, `/gate-check`, `/review-all-prds`

Skills with `model: haiku`: `/help`, `/onboard`, `/project-stage-detect`,
`/scope-check`, `/sprint-status`

All other skills are `sonnet`.

> `/release-notes` and `/changelog` are `sonnet`, not `haiku`: both produce
> **customer-facing** copy and need judgement the cheapest tier is defined as not
> doing. Full reasoning in each skill's own header.
>
> `/settings` is `sonnet` for the same reason. It does not only read and format —
> it resolves every leaf with provenance and then compares the configured rigor
> against the project's observable working practice. That is synthesis, which is
> what the Haiku row is defined as excluding.

**Authoring rule for skills.** A new skill declares `model: sonnet` unless it is
stated otherwise. Assign `haiku` only if the skill only reads and formats; assign
`opus` only if it must synthesize 5+ documents with high-stakes output. Every
skill in this repo declares a tier, and the lists above are kept in step with what
the `SKILL.md` files declare. That is a check on two descriptions agreeing; it
proves nothing about which model actually runs.

## Agents

| `model:` | Count | Agents |
|---|---|---|
| `opus` | 3 | product-director, technical-director, delivery-manager |
| `sonnet` | 11 | tech-lead, prototyper, nextjs-specialist, vue-nuxt-specialist, react-native-specialist, flutter-specialist, ios-specialist, android-specialist, node-specialist, spring-specialist, python-specialist |
| `inherit` | 32 | design-director, product-manager, qa-lead, release-manager, localization-lead, business-analyst, monetization-strategist, backend-engineer, frontend-engineer, mobile-engineer, platform-engineer, internal-tools-engineer, ml-engineer, design-engineer, product-designer, ux-researcher, ux-writer, performance-engineer, accessibility-specialist, security-engineer, qa-engineer, devops-engineer, sre-engineer, data-engineer, analytics-engineer, growth-manager, customer-success-manager, web-specialist, mobile-specialist, backend-specialist, data-specialist, cloud-specialist |
| `haiku` | 0 | — |

**Why.** The three Tier 1 directors stay `opus`: they own the Opus-tier director
gates (`PD-`, `TD-`, `DM-`) and sit on the `/gate-check` panel (delivery-manager
at every width, technical-director from `standard`, product-director at `full`).
tech-lead (code review and implementation feasibility gates), prototyper
(throwaway builds in an isolated worktree) and the framework sub-specialists
(idiom-level implementation advice inside one framework) are pinned at `sonnet`.
Everything else is `inherit`, so a fixed smaller model can't overflow when the
parent session runs a large-context tier — including design-director, the fourth
phase-gate panel seat, whose `DD-` gates run at `inherit`. No agent is `haiku`:
customer communication and incident-adjacent work (customer-success-manager,
devops-engineer) need judgement the cheapest tier is defined as not doing.

**Authoring rule for agents.** A new agent is `inherit` unless there is a reason
recorded here for pinning it. Change the agent's frontmatter first, then update
the table above in the same change.
