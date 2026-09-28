> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# PD-USER-VALIDATION — User Validation Review

Agent: `product-director` | Model tier: Opus | Domain: User evidence

**Trigger**: Spawned by `/usability-report` after a usability, beta or interview
report is written; by `/prototype` after the concept prototype's `REPORT.md` records
its PROCEED / PIVOT / KILL recommendation and before that decision is acted on; and
by `/walking-skeleton` only when a usability session runs on the skeleton. It weighs
the results against the hypotheses: is the value landing, and where do users get
stuck in confusion loops?

**Context to pass**:
- report path (usability report, prototype REPORT.md or walking-skeleton report)
- hypotheses tested
- target segment
- brief path

**Prompt**:
> "Review this user evidence against the hypotheses it was meant to test and the
> product brief. Read the report and the brief at the paths given. Check:
>
> 1. **Evidence quality** — did the participants match the target segment (for Moa:
>    salaried people in Korea in their 20s–30s saving toward a goal — not teammates
>    or friends of the founders)? Were the tasks realistic and the questions
>    non-leading? Does the report separate what participants did from what they
>    said? Is the sample honest about what it can show — five usability sessions
>    find usability problems; they do not prove demand.
> 2. **Each hypothesis** — supported, refuted or inconclusive, with the evidence
>    (task success, time on task, SEQ, quotes; for beta reports also activation,
>    D1/D7 retention, crash-free sessions, NPS/CSAT). Example: 'users understand and
>    trust automatic debit' — did participants complete the auto-debit authorisation
>    step, and where did they hesitate?
> 3. **Value delivered** — does the observed behaviour show the core user journey
>    delivering the value proposition, or only that the screens are usable?
> 4. **Confusion loops** — repeated back-and-forth between screens, dead ends,
>    misread copy, abandoned steps. Rank them by how directly they block the value.
> 5. **Principle drift** — patterns that work in isolation but undermine a product
>    principle (a streak mechanic that raises engagement but makes users feel
>    punished for a missed deposit).
> 6. **Conclusion follows the evidence** — does the report's recommendation (or the
>    prototype's PROCEED / PIVOT / KILL) follow from what was observed? PROCEED on
>    three friendly interviews does not.
>
> Return APPROVE (the value is landing and the evidence supports the next step),
> CONCERNS [gaps between intended and observed experience, and the cheapest test
> that would close each], or REJECT [the core value proposition is not landing —
> rework before further building or testing]."

**Verdicts**: APPROVE / CONCERNS / REJECT

The first line of the reply is exactly `[PD-USER-VALIDATION]: <TOKEN>` with one token
from the line above; the spawning skill parses it. Findings follow the first line.

**Special handling**:
- The spawning skill's own verdict tokens (a usability report's verdict, a
  prototype's PROCEED / PIVOT / KILL, a walking skeleton's VALIDATED / NOT VALIDATED)
  are not changed by this gate. When this gate disagrees with them — for example
  REJECT on a prototype marked PROCEED — say so explicitly so the skill surfaces the
  conflict to the user instead of silently keeping either.
- Judge evidence, not formatting. A report with thin evidence is CONCERNS or REJECT
  on substance, not because a heading is missing.
- If the hypotheses were not written down before the sessions, say so: results
  interpreted after the fact are weaker evidence and cap the verdict at CONCERNS.
