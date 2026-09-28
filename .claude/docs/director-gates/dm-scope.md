> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# DM-SCOPE — Scope & Timeline Validation

Agent: `delivery-manager` | Model tier: Opus | Domain: Scope & schedule

**Trigger**: Spawned by `/brainstorm` once the MVP scope is drafted (alongside
TD-FEASIBILITY) and by `/map-features` once features are assigned to tiers. It checks
MVP / Beta / GA scope against the team's capacity and any target date.

**Context to pass**:
- MVP scope text (brief, one-pager or feature map path)
- resolved `team.size`
- target milestone/date (or "none given")

**Prompt**:
> "Review this scope against capacity. Read the scope text (or the brief, one-pager
> or feature map at the path given). Check:
>
> 1. **Achievability** — can a team of the resolved size (`individual`, `small` or
>    `studio`) deliver the MVP by the target date? Count the work outside feature code
>    that early teams routinely leave out of estimates: app store developer accounts
>    and review lead time, payment-provider merchant review, 알림톡 channel and
>    template approval, Terms of Service and Privacy Policy review, CI/CD and
>    observability setup, admin tooling for support, account deletion, analytics
>    instrumentation, accessibility, beta recruitment.
> 2. **Tier ordering** — each tier (MVP → Beta → GA → Later) is a shippable product if
>    work stops there. The MVP proves the value hypothesis without carrying GA polish
>    (for Moa: full role-based access in `admin-console` belongs after MVP; a
>    read-only support view does not).
> 3. **Cut line** — the most likely cut point under time pressure, and whether it is a
>    graceful fallback (Moa ships without the Plus plan) or a broken product (Moa
>    ships without automatic debit).
> 4. **Buy versus build** — where buying (managed auth, a payment provider's hosted
>    checkout, a notification service) removes weeks from the critical path.
> 5. **No date given** — size the MVP relative to the team, propose a realistic
>    target, and state the assumptions behind it.
>
> Return REALISTIC (scope matches capacity), CONCERNS [specific adjustments — what to
> cut, defer to Beta, or buy instead of build], or UNREALISTIC [blockers — the
> timeline or the MVP must be revised; give both options: a cut list, and a date that
> fits the current scope]."

**Verdicts**: REALISTIC / CONCERNS / UNREALISTIC

The first line of the reply is exactly `[DM-SCOPE]: <TOKEN>` with one token from the
line above; the spawning skill parses it. Findings follow the first line.

**Special handling**:
- `CONCERNS` is the token for a scope that needs adjustment but does not block: the
  spawning skill handles it as CONCERNS-class and asks the user to revise, accept or
  discuss.
- `team.size` describes how the framework scales its agent pipelines, not a
  headcount. If the real headcount, skills or weekly hours matter to the verdict,
  state the assumption you made and list it as a question for the user.
