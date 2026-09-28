> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# DM-SPRINT — Sprint Plan Feasibility

Agent: `delivery-manager` | Model tier: Opus | Domain: Sprint feasibility

**Trigger**: Spawned by `/sprint-plan` before a sprint plan is finalised, and after
any mid-sprint scope change. It checks capacity, dependencies and story readiness.

**Context to pass**:
- sprint plan draft path
- velocity of previous sprints (or "none")
- story paths in the sprint

**Prompt**:
> "Review this sprint plan for feasibility. Read the plan and each story at the paths
> given. Check:
>
> 1. **Capacity** — is the committed load realistic against the velocity of the last
>    sprints and the capacity actually available: public holidays (Seollal and
>    Chuseok can remove most of a week in Korea), time off, on-call duty, and release
>    or store-review work that lands in the sprint?
> 2. **Dependencies** — are stories ordered so that each can start when planned?
>    Look for hidden dependencies between stories, and for external ones: the API
>    contract operation a client story needs, a migration whose Expand phase must ship
>    before the application change, an approved UX spec, sandbox access to a third
>    party.
> 3. **Readiness** — each story has `> **Status**: Ready`, testable acceptance
>    criteria, and `**API Contract**`, `**Migration**` and `**Feature Flag**` filled
>    in (or `None`); its QL-STORY-READY verdict line, or the skip note for the
>    review mode, is recorded.
> 4. **Risk concentration** — too many HIGH-risk stories, too much work in progress
>    at once, carry-over from the last sprint, a single person on the critical path.
> 5. **Sprint goal** — one coherent goal the stories add up to (for Moa: 'a user can
>    create a savings goal and see it on web and mobile'), not a grab bag.
>
> Return REALISTIC (the plan is achievable), CONCERNS [specific risks and their
> mitigations], or UNREALISTIC [the sprint must be descoped — name the stories to
> defer]."

**Verdicts**: REALISTIC / CONCERNS / UNREALISTIC

The first line of the reply is exactly `[DM-SPRINT]: <TOKEN>` with one token from the
line above; the spawning skill parses it. Findings follow the first line.

**Special handling**:
- Velocity "none" (first sprint): plan against a conservative estimate, say so, and
  treat the sprint as a calibration sprint — a first sprint committed at full
  theoretical capacity is CONCERNS at least.
