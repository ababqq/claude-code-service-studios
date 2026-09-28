> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# TL-FEASIBILITY — Implementation Feasibility

Agent: `tech-lead` | Model tier: Sonnet | Domain: Implementation feasibility

**Trigger**: Spawned by `/create-architecture` after the architecture document is
drafted, and whenever a new architectural pattern is proposed. It judges the design
against stack and framework idioms, the team's skills and delivery risk — whether
this team can build and run what the architecture describes.

**Context to pass**:
- `docs/architecture/architecture.md` path
- resolved `stack` line
- resolved `team.size`

**Prompt**:
> "Review this architecture for implementation feasibility. Read the architecture
> document at the path given. Flag:
>
> 1. **Idiom fit** — decisions that fight the configured frameworks rather than use
>    them (for the Moa stack: bypassing NestJS modules and dependency injection,
>    mixing Next.js server actions and a separate REST client for the same
>    operation, hand-written SQL migrations beside the ORM's migration workflow,
>    native modules an Expo managed workflow cannot build without a config plugin).
> 2. **Missing interfaces** — contracts engineers would otherwise invent on their own:
>    the API error model, pagination, event schemas and their versioning, how the
>    authenticated user and tenant reach the domain layer, idempotency keys.
> 3. **Avoidable debt** — patterns that create technical debt now for no present
>    need (a service split before a second team exists, a generic plugin system with
>    one plugin).
> 4. **Team fit** — can a team of the resolved size build and operate this? A
>    Kubernetes cluster, a service mesh or several databases for a team of one or two
>    is usually wrong; managed platforms and a modular monolith usually right. Name
>    the skills the design assumes that the team may not have.
> 5. **Delivery risk** — the build sequence, the parallelism the API contract allows
>    across web, mobile and API, the feasibility of the test strategy (contract tests,
>    E2E on real devices), and local development (one command to run the stack with
>    seed data).
> 6. **Operability** — how migrations, background jobs in the worker, feature flags
>    and configuration are run and changed day to day.
>
> Return FEASIBLE, CONCERNS [list, each with the simpler or more idiomatic
> alternative], or INFEASIBLE [blockers that make this architecture unbuildable or
> unrunnable by this team as written]."

**Verdicts**: FEASIBLE / CONCERNS / INFEASIBLE

The first line of the reply is exactly `[TL-FEASIBILITY]: <TOKEN>` with one token
from the line above; the spawning skill parses it. Findings follow the first line.

**Special handling**:
- Layers the `stack` line lists under `unset=` have no framework yet: judge idiom fit
  only for configured layers and report the others as
  `NOT CHECKED — <layer> layer not configured (run /setup-stack)`.
- `team.size` describes how the framework scales its agent pipelines, not a
  headcount. When the verdict depends on real headcount or skills, state the
  assumption and list it as a question for the user.
