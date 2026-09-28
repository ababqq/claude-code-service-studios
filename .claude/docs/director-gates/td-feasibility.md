> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# TD-FEASIBILITY — Technical Feasibility of Early Risks

Agent: `technical-director` | Model tier: Opus | Domain: Technical feasibility & vendor risk

**Trigger**: Spawned by `/brainstorm` at the MVP-scope step, once the riskiest
assumptions are listed — a "[category] service on [surfaces] using [stack]"
feasibility read covering third-party and vendor risk, compliance-driven engineering
and cost risk, before the concept hardens into a brief.

**Context to pass**:
- one-line concept "<category> service on <surfaces> using <stack>"
- riskiest assumptions list
- resolved `stack` line (or "unset")
- resolved `compliance` line

**Prompt**:
> "Review the technical risks of this concept — a <category> service on <surfaces>
> using <stack, or 'an undecided stack'>. Flag:
>
> 1. **Risks that could invalidate the concept as described** — capabilities that
>    depend on a third party's approval, access or policy. For Moa (a B2C savings app
>    for Korea): automatic debit through a Korean payment provider usually needs a
>    separate merchant contract and review before live keys are issued; 알림톡
>    requires a KakaoTalk business channel and per-template approval; the App Store's
>    login-service rules require an equivalent privacy-focused login option (such as
>    Sign in with Apple) when Kakao or Naver login is offered.
> 2. **Vendor and platform risk** — lock-in, pricing changes, rate limits, sandbox
>    quality, the vendor's own availability; build versus buy for identity, payments,
>    notifications and search (early-stage teams should usually buy).
> 3. **Compliance-driven engineering** — from the resolved compliance line: handling
>    personal data, and each configured region's checklist in
>    `.claude/docs/compliance/<region>.md`. For Moa with `regions=kr`, whether the
>    product itself holds customer money (a prepaid-payment-means question under the
>    Electronic Financial Transactions Act) or only debits into a partner account is
>    an architecture-changing decision, as is hosting personal data outside Korea.
> 4. **Cost risk** — per-message costs (SMS, 알림톡), payment fees, egress, model
>    inference costs if the concept uses an LLM; whether the Free plan's unit
>    economics survive at the target volume.
> 5. **Risks small teams underestimate** — offline and sync on mobile, push delivery
>    reliability, store review lead time, time zones and currency rounding (KRW has
>    no minor unit), account deletion, data migrations, admin tooling for support.
> 6. **Stack fit** — with a stack set, whether it suits the surfaces and the team;
>    with the stack unset, which of the risks above should influence the choice.
>
> For each risk, name the cheapest test that would retire it (a sandbox spike, a
> vendor call, a fake-door page, a compliance question for counsel). Return VIABLE
> (risks are manageable with the named mitigations), CONCERNS [risks with mitigation
> suggestions], or HIGH RISK [blockers that require concept or scope revision — name
> the assumption that fails and what evidence would change the verdict]."

**Verdicts**: VIABLE / CONCERNS / HIGH RISK

The first line of the reply is exactly `[TD-FEASIBILITY]: <TOKEN>` with one token
from the line above; the spawning skill parses it. Findings follow the first line.

**Special handling**:
- Not a legal opinion. Compliance items are topics to verify, taken from the region
  checklists; never state a deadline, fine or threshold unless a source is cited
  (`NOT SOURCEABLE` otherwise).
- An unset compliance line (`(unset -- ask)`) is an open question to raise, never
  "no regional obligations". `regions=none` means the user explicitly chose none —
  skip regional items and say so.
