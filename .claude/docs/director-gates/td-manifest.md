> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# TD-MANIFEST — Control Manifest Review

Agent: `technical-director` | Model tier: Opus | Domain: Engineering rules

**Trigger**: Spawned by `/create-control-manifest` after the rules are extracted and
previewed, before `docs/architecture/control-manifest.md` is written. It checks that
every rule traces to an Accepted ADR or the tech radar and that no two rules
contradict each other.

**Context to pass**:
- manifest draft path
- Accepted ADR paths
- `docs/architecture/tech-radar.md` path

**Prompt**:
> "Review this control manifest before it is written. Read the draft, the Accepted
> ADRs and the tech radar at the paths given. Check:
>
> 1. **Every rule has a source** — an Accepted ADR section (`## Decision`,
>    `## Alternatives Considered`, `## Performance & SLO Implications`,
>    `## Security & Privacy Implications`, `## Stack Compatibility`) or a tech radar
>    entry (`## Hold` and `## Forbidden Patterns` become 'Never' rules). Flag every
>    rule that was invented rather than extracted.
> 2. **Completeness** — each Accepted ADR's mandatory patterns and forbidden
>    approaches are captured. For `docs/architecture/adr-0001-identity-and-auth.md`:
>    'Always check resource ownership server-side on every goals endpoint', 'Never
>    store refresh tokens in web localStorage'.
> 3. **No contradictions** — between two rules, between a rule and an ADR, or between
>    the radar and an ADR (a library in `## Hold` that an Accepted ADR mandates).
> 4. **Layer placement** — each rule sits under the right `## <Layer> Layer Rules`
>    heading (Foundation / Core / Feature / Presentation).
> 5. **Guardrails match their sources** — performance and SLO guardrails equal what
>    the ADRs and budgets actually set; security and privacy rules state the concrete
>    Never/Always behaviour.
> 6. **Checkable** — a reviewer can answer yes or no for each rule in code review;
>    vague rules ('write clean code') are removed or made concrete.
> 7. **Scope** — Proposed, Superseded and Deprecated ADRs contribute no rules.
>
> Return APPROVE, CONCERNS [the specific rules to revise], or REJECT [rules that are
> wrong or unsourced and must be fixed before the manifest is written]."

**Verdicts**: APPROVE / CONCERNS / REJECT

The first line of the reply is exactly `[TD-MANIFEST]: <TOKEN>` with one token from
the line above; the spawning skill parses it. Findings follow the first line.

**Special handling**:
- If the tech radar does not exist yet, report
  `NOT CHECKED — tech radar absent (run /setup-stack)`, review the ADR-sourced rules,
  and cap the verdict at CONCERNS.
