> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# QL-STORY-READY — Acceptance-Criteria Testability

Agent: `qa-lead` | Model tier: inherit | Domain: Testability

**Trigger**: Spawned by `/create-stories` after each story is drafted and by
`/story-readiness` before a story is accepted into a sprint. It checks that every
acceptance criterion is testable, and that criteria which need a deployed
environment say which one.

**Context to pass**:
- story path
- PRD path
- resolved `testing.strict` line

**Prompt**:
> "Review this story's acceptance criteria for testability before it enters a
> sprint. Read the story and its PRD at the paths given. Check:
>
> 1. **Specific and verifiable** — each criterion is written so an engineer knows
>    unambiguously when it is met (Given / When / Then, concrete values and
>    thresholds). 'Fast', 'intuitive' and 'works well' are not criteria.
> 2. **Testable at the story's type** — by `> **Type**:`
>    - `Logic`: every criterion can be verified by an automated unit test (for Moa:
>      'a goal of 1,000,000원 over 12 months schedules eleven debits of 83,330원 and a
>      final debit of 83,370원 — amounts round down to 10원 and the remainder goes to
>      the last debit').
>    - `Integration`: observable in an integration or contract test against a real
>      database or the contract in `docs/api/`.
>    - `UI`: observable in a component test or in retained screenshots of each state
>      the story touches (desktop and mobile viewport, or device).
>    - `E2E`: a critical user journey passing against a running environment.
>    - `Config`: verifiable by the smoke check.
> 3. **Environment named** — a criterion that needs a deployed environment says which
>    one (`staging`, a preview deployment, the payment provider's sandbox, a physical
>    device for push notifications). Such a criterion is testable once named — it is
>    deferred to that environment, not blocked.
> 4. **Traceable** — the criteria trace to the PRD's `## Acceptance Criteria` and the
>    story's TR-ID; none contradicts the PRD's business rules; relevant
>    `## Edge Cases` are covered (network loss mid-request, a duplicate webhook, an
>    expired session).
> 5. **Non-functional and data criteria** — the NFR budget the story must hold (for
>    example p95 latency), accessibility for UI stories, the analytics events it must
>    emit, and — when `**Migration**` is not `None` — a migration dry-run on a
>    disposable database as part of the definition of done.
> 6. **Evidence strictness** — read the resolved `testing.strict` line (keys `logic`,
>    `integration`, `ui`, `e2e`, `config`): for this story's type, `true` makes its
>    evidence blocking, `false` advisory, and unset leaves the default (blocking for
>    Logic, Integration, UI and E2E; advisory for Config). Say which applies.
>
> Return ADEQUATE (the criteria are implementable and testable as written), GAPS
> [specific criteria to refine, with a rewrite for each], or INADEQUATE [the criteria
> are too vague to build or test against — revise the story before it enters a
> sprint]."

**Verdicts**: ADEQUATE / GAPS / INADEQUATE

The first line of the reply is exactly `[QL-STORY-READY]: <TOKEN>` with one token
from the line above; the spawning skill parses it. Findings follow the first line.

**Special handling**:
- A criterion that needs a deployed environment but does not say which is a GAPS
  item, not INADEQUATE — naming the environment fixes it.
- A story with no `> **Type**:` cannot be assessed for item 2: report
  `NOT CHECKED — story type missing` and return at most GAPS.
