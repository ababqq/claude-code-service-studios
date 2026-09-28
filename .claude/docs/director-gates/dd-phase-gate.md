> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# DD-PHASE-GATE — Design & UX Readiness at Phase Transition

Agent: `design-director` | Model tier: inherit | Domain: Design & UX readiness

**Trigger**: Spawned by `/gate-check` in parallel with the other `-PHASE-GATE` gates,
whenever the panel width that `/gate-check` Section 4b resolves includes
`design-director`. `/gate-check` omits it when the configured surfaces are known to
contain no UI surface, and names the omission. It assesses design language maturity,
whether the key journeys are specced, and whether the accessibility target is
committed.

**Context to pass**:
- target phase
- gate reference file path
- artifact-check output for the departure phase
- resolved `surfaces` line
- design-language path (or "none")

**Prompt**:
> "Review the project's readiness to enter [target phase] from a design and UX
> perspective. Read the gate reference file at the path given — it is the checklist
> for this transition, and the only gate reference file you read — and the design language if
> one exists. Use the artifact-check output as observations of what exists on disk;
> do not re-derive them. Assess, in proportion to the phase:
>
> 1. **Design language maturity** — brand direction chosen; the design language has
>    the sections this tier requires, and the DD-DESIGN-LANGUAGE outcome (or its skip
>    note) is recorded in it.
> 2. **Key journeys specced** — sign-up and sign-in, onboarding, the core flow (for
>    Moa: create a goal and authorise automatic debit), settings and account
>    (including account deletion); the app shell and interaction patterns exist;
>    each key spec has a UX review record.
> 3. **Accessibility committed** — `accessibility.target` decided and recorded in
>    `design/accessibility-requirements.md`; key specs address it; from Hardening on,
>    implemented screens were checked against it.
> 4. **Specs and contract agree** — the operations each key spec's `## API Data`
>    section needs exist in the API contract (when there is a backend).
> 5. **Deferred decisions** — visual or interaction decisions postponed past their
>    last responsible moment, which will cause rework once engineers build against
>    them.
>
> Return READY, CONCERNS [specific design gaps that could cause rework], or NOT READY
> [design blockers that must exist before this phase can succeed — name the missing
> artifact and why it matters at this stage]."

**Verdicts**: READY / CONCERNS / NOT READY

The first line of the reply is exactly `[DD-PHASE-GATE]: <TOKEN>` with one token
from the line above; `/gate-check` parses it. Findings follow the first line.

**Special handling**:
- `/gate-check` omits this gate when no *UI* surface is configured. If it is spawned
  anyway and the resolved `surfaces` line is known and names no UI surface (none of
  `web`, `ios`, `android` — e.g. `api` only), return `[DD-PHASE-GATE]: READY` with
  the note "no UI surface — nothing to assess".
- An unset `surfaces` line is not "no UI": assess normally, as if the product has a
  UI, and state in the findings that `surfaces` is unset (`/setup-stack` sets it).
- Advisory: this verdict feeds `/gate-check`, which applies the strictest verdict of
  the panel and decides nothing on its own. Never propose writing `project.stage`.
- Items the artifact-check output reports as `NO_CHECK` or `UNKNOWN` are not
  evidence of absence: check them by reading the files, or report them as
  `NOT CHECKED — <reason>`.
