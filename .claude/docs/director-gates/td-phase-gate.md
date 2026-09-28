> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# TD-PHASE-GATE — Technical Readiness at Phase Transition

Agent: `technical-director` | Model tier: Opus | Domain: Technical readiness

**Trigger**: Spawned by `/gate-check` in parallel with the other `-PHASE-GATE` gates,
whenever the panel width that `/gate-check` Section 4b resolves includes
`technical-director`. It assesses stack risk, SLO and performance budgets, the
security baseline, environments and CI, and the Foundation decisions.

**Context to pass**:
- target phase
- gate reference file path
- artifact-check output for the departure phase
- resolved `stack` and `code_roots` lines

**Prompt**:
> "Review the project's readiness to enter [target phase] from a technical
> perspective. Read the gate reference file at the path given — it is the checklist
> for this transition, and the only gate reference file you read. Use the artifact-check output
> as observations of what exists on disk; do not re-derive them. Assess, in
> proportion to the phase:
>
> 1. **Stack risk** — `stack.pinned_on` set; every configured component pinned with a
>    sourced version, `n/a (managed service)`, or an accepted `NOT DETERMINED`; HIGH
>    and MEDIUM Knowledge Risk components addressed in the architecture or ADRs; no
>    ADR relying on a deprecated API.
> 2. **SLO and performance budgets** — `performance.*` budgets set and realistic for
>    the surfaces; critical user journeys with SLOs; from Hardening on, measured
>    results (load test, Core Web Vitals, mobile cold start and crash-free sessions)
>    against those budgets.
> 3. **Security baseline** — a threat model when personal data is handled; secrets
>    management decided in an ADR; object-level authorization designed into the API
>    contract; dependency and secret scanning in CI; before Launch, a security audit
>    without open Critical or High findings.
> 4. **Environments and CI** — dev, staging and prod exist; CI runs the test suite;
>    deploys go through the pipeline, never by hand; entering Build, the walking
>    skeleton ran on staging with a rehearsed rollback.
> 5. **Foundation decisions** — Foundation-layer ADRs accepted before Build; no ADR
>    dependency cycle; schema migrations planned as expand/contract, with Contract
>    phases scheduled.
> 6. **Code roots** — the resolved code roots match the declared layers; undeclared
>    roots reported by the `code_roots` line are declared or explained.
>
> Return READY, CONCERNS [list], or NOT READY [blockers — name the missing artifact
> or decision and why it matters at this phase]."

**Verdicts**: READY / CONCERNS / NOT READY

The first line of the reply is exactly `[TD-PHASE-GATE]: <TOKEN>` with one token
from the line above; `/gate-check` parses it. Findings follow the first line.

**Special handling**:
- Advisory: this verdict feeds `/gate-check`, which applies the strictest verdict of
  the panel and decides nothing on its own. Never propose writing `project.stage`.
- A `code_roots: unresolved — NOT CHECKED …` line means no code root is declared.
  Before Build that is normal; from Build on it is a finding — code-level checks are
  `NOT CHECKED`, never passed.
- Items the artifact-check output reports as `NO_CHECK` or `UNKNOWN` are not
  evidence of absence: check them by reading the files, or report them as
  `NOT CHECKED — <reason>`.
