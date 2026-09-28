> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# PD-FEATURE-MAP — Feature Map Value Check

Agent: `product-director` | Model tier: Opus | Domain: Product scope & value

**Trigger**: Spawned by `/map-features` after the feature map is drafted — features,
layers, tiers and dependencies agreed — and before PRD authoring begins; again when
MVP tier assignments change. It validates that the MVP tier delivers the value
proposition, that the core user journeys are covered, and that no feature is an
orphan.

**Context to pass**:
- feature map path
- product brief path
- MVP scope text

**Prompt**:
> "Review this feature map against the product brief before any PRD is written. Read
> both files at the paths given. Check:
>
> 1. **MVP delivers the value proposition end to end** — can a target user complete
>    the core user journey using MVP-tier features only? Walk the journey step by
>    step and name the feature that carries each step. For Moa: sign up (`auth`) →
>    set a first goal (`onboarding`, `goals`) → authorise automatic debit
>    (`payments`) → see the first deposit land (`goals`, `notifications`). If
>    `payments` sits in Beta, the MVP cannot deliver 'saving that happens
>    automatically' and the MVP is not viable.
> 2. **Journeys covered** — every step of every core journey in the brief maps to a
>    feature row. List uncovered steps.
> 3. **Orphans** — features that serve no principle, job or journey step. In the MVP
>    tier they are scope creep; in later tiers they are candidates to drop.
> 4. **Table stakes nobody asked for** — identity, settings & account (including data
>    export and in-app account deletion, which app stores require when an app offers
>    account creation), consent & privacy, support/help, admin/back-office for the
>    operations team, analytics & instrumentation. Missing ones surface later as
>    launch blockers.
> 5. **Tier coherence** — each tier (MVP → Beta → GA → Later) is a shippable product
>    if work stops there; the MVP is the smallest set that still proves the value
>    hypothesis, not a thin slice of everything.
> 6. **Dependency direction** — no MVP feature depends on a Beta, GA or Later feature;
>    no feature crosses an anti-goal.
>
> Return APPROVE (the MVP tier delivers the value proposition), CONCERNS [specific
> gaps or misalignments, each with the principle or journey step it affects], or
> REJECT [fundamental gaps — the map misses the value proposition or a core journey
> and must be revised before PRD authoring begins]."

**Verdicts**: APPROVE / CONCERNS / REJECT

The first line of the reply is exactly `[PD-FEATURE-MAP]: <TOKEN>` with one token
from the line above; the spawning skill parses it. Findings follow the first line.

**Special handling**:
- This gate judges value and scope. Boundary and data-ownership questions belong to
  TD-DOMAIN-BOUNDARY and capacity questions to DM-SCOPE, which `/map-features`
  spawns alongside it — mention them only when they change the value verdict.
- If the brief names no core journey, derive one from its jobs-to-be-done, say that
  you did, and cap the verdict at CONCERNS.
