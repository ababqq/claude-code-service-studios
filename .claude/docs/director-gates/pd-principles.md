> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# PD-PRINCIPLES — Product Principles Stress Test

Agent: `product-director` | Model tier: Opus | Domain: Product strategy, principles, positioning

**Trigger**: Spawned by `/brainstorm` right after the product principles and
anti-goals are drafted — before brand direction, success metrics and MVP scope are
built on top of them — and again whenever the principles or anti-goals are revised.
The question is whether the principles carry weight: are they falsifiable, do they
differentiate the product from its alternatives, and do they resolve real
trade-offs?

**Context to pass**:
- brief path (draft)
- drafted principles & anti-goals text
- target users & JTBD summary
- named alternatives

**Prompt**:
> "Stress-test these product principles and anti-goals before the rest of the brief
> is built on them. Read the draft brief at the path given for surrounding context;
> the principles text passed to you is the version under review.
>
> For each principle, answer four questions with one line of evidence each:
> 1. **Falsifiable** — could a real product decision fail it? Name one plausible
>    decision it would reject. For Moa (a subscription savings app), 'Saving happens
>    automatically — the user never has to remember' rejects a manual 'deposit now'
>    button as the primary flow. A principle nobody could violate ('user first',
>    'simple and fast') carries no weight.
> 2. **Decides a trade-off** — does it state what the team gives up to honour it?
>    ('Trust over conversion: no dark patterns in the Free → Plus upsell, even if
>    upgrade rate is lower.') Name the trade-off, or flag it as missing.
> 3. **Differentiates** — against each named alternative (for Moa: a bank's own
>    installment savings product, the savings features inside a super-app, a
>    spreadsheet, doing nothing), would following this principle produce a
>    noticeably different product? A principle every alternative already follows is
>    table stakes, not positioning.
> 4. **Serves a job** — trace it to a job in the target users & JTBD summary. A
>    principle that serves no stated job is a founder preference, not a product
>    principle.
>
> Then assess the set as a whole. Do two principles conflict without a stated
> priority order? Do the anti-goals rule out things a reasonable team would actually
> be tempted to build (for Moa: 'no investment products', 'no social leaderboards',
> 'no notifications that shame a missed deposit'), or only strawmen nobody wanted?
> Could two people who disagree about a feature settle the argument by citing a
> principle? Is anything important to the target users left unprotected?
>
> Return a per-principle table (falsifiable / trade-off / differentiates / serves a
> job — yes or no, with the evidence line) and an overall verdict: APPROVE (the
> principles constrain real decisions), CONCERNS [the principles to sharpen, each
> with a suggested rewrite], or REJECT [the principles do not constrain decisions —
> rewrite them before the brief proceeds]."

**Verdicts**: APPROVE / CONCERNS / REJECT

The first line of the reply is exactly `[PD-PRINCIPLES]: <TOKEN>` with one token
from the line above; the spawning skill parses it. Findings follow the first line.

**Special handling**:
- If "named alternatives" is empty, do not conclude the product has no competition —
  every product competes at least with "doing nothing". Report
  `NOT CHECKED — differentiation (no alternatives named)` and return at most
  CONCERNS.
- If the draft is a one-pager (`minimal` workflow), principles may sit inside
  `## Pitch` or `## Scope & Non-Goals` rather than a section of their own. Assess the
  statements that are there; do not demand the product brief's section structure.
- Suggest rewrites; never edit the brief. `/brainstorm` asks the user before writing.
