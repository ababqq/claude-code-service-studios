> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# DM-MILESTONE — Milestone Risk Assessment

Agent: `delivery-manager` | Model tier: Opus | Domain: Milestone risk

**Trigger**: Spawned by `/milestone-review` after the review draft for a milestone
(MVP, Private Beta, Public Beta or GA) is assembled and before its go/no-go
recommendation is written. It assesses the risk that the milestone misses its date
or its exit criteria.

**Context to pass**:
- milestone review draft path
- milestone definition path
- `production/sprint-status.yaml` path
- unresolved S1/S2 count

**Prompt**:
> "Review this milestone's status. Read the review draft, the milestone definition and
> the sprint status at the paths given. Check:
>
> 1. **Date** — given velocity, remaining stories and blocked stories
>    (`status: blocked`), will the milestone hit its target date?
> 2. **Quality** — unresolved bugs (status Open, In Progress or Fixed — Pending
>    Verification): any unresolved S1 blocks Public Beta and GA; every unresolved S2
>    needs an owner and a target date. Where measured, compare crash-free sessions,
>    error rate and latency with the guardrails.
> 3. **Readiness for this kind of milestone** — Private Beta: invited users,
>    TestFlight and Play testing tracks, a feedback channel. Public Beta: store
>    listings, support channels, a status page. GA: SLOs with alerting, on-call,
>    runbooks, Terms of Service and Privacy Policy published, payments in live mode.
> 4. **Exit criteria** — the milestone definition's criteria are measurable, and the
>    draft reports each one with evidence rather than opinion.
> 5. **Top three risks** between now and the milestone, each with a mitigation, and
>    the scope items that can be cut versus those that are non-negotiable.
>
> Return ON TRACK, AT RISK [specific mitigations], or OFF TRACK [the date must slip
> or scope must be cut — give both options]."

**Verdicts**: ON TRACK / AT RISK / OFF TRACK

The first line of the reply is exactly `[DM-MILESTONE]: <TOKEN>` with one token from
the line above; the spawning skill parses it. Findings follow the first line.

**Special handling**:
- The unresolved S1/S2 count passed to you is an observation; if it disagrees with
  what you read in the draft, report both numbers rather than choosing one.
