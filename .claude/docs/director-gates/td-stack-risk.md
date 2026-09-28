> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# TD-STACK-RISK — Stack Version Risk Review

Agent: `technical-director` | Model tier: Opus | Domain: Stack versions, upgrade and EOL risk

**Trigger**: Spawned by `/architecture-decision` when a component named in the ADR's
`## Stack Compatibility` has Knowledge Risk HIGH or MEDIUM, and by
`/setup-stack upgrade <component> <old> <new>` before the new version is pinned. It
reviews post-cutoff APIs, end-of-life runtimes, breaking changes, and store
minimum-SDK and target-API rules.

**Context to pass**:
- component and version change (old → new, or pinned version)
- `docs/stack-reference/<component>/` path
- ADR paths whose `## Stack Compatibility` names the component

**Prompt**:
> "Review this stack component version against its reference documentation. Read the
> component folder at the path given — `VERSION.md` first, then
> `breaking-changes.md`, `deprecated-apis.md` and `current-best-practices.md` where
> they exist — and the ADRs that name the component. Check:
>
> 1. **Version reality** — is the version current and supported? Answer from the
>    reference files and their sources, never from memory: a version released after
>    your knowledge cutoff is exactly where memory is wrong.
> 2. **Post-cutoff APIs** — is each API or feature the ADRs rely on present in this
>    version, with the signature and behaviour they assume? Name replacements for
>    anything deprecated or removed.
> 3. **End of life** — is the runtime (for example the Node.js, Python or JDK line)
>    or a managed runtime on the hosting platform at or near end of support, per a
>    cited schedule?
> 4. **Upgrade breaking changes** (upgrade mode) — required code, configuration and
>    build changes, available codemods, and which of the listed ADRs must be marked
>    're-validation required'.
> 5. **Store rules** (mobile components) — the iOS SDK / Xcode version the App Store
>    requires for submission, the Google Play target API level requirement, privacy
>    manifest and SDK signature rules, and compatibility across React Native / Expo,
>    Flutter or native toolchains — levels and dates taken from the cited source.
> 6. **Ecosystem compatibility** — key libraries (ORM, auth SDK, payment SDK, test
>    runners) support this version.
>
> Return APPROVE (safe to use as described), CONCERNS [what to verify before
> implementing, and how], or REJECT [the API or version has changed or is
> unsupported — give the corrected approach]."

**Verdicts**: APPROVE / CONCERNS / REJECT

The first line of the reply is exactly `[TD-STACK-RISK]: <TOKEN>` with one token from
the line above; the spawning skill parses it. Findings follow the first line.

**Special handling**:
- Every factual claim about a version, a date or a store requirement carries its
  source (the URL recorded in the reference file). When the reference folder has no
  source for a question, answer `NOT SOURCEABLE — run /setup-stack refresh` for that
  item instead of guessing, and cap the verdict at CONCERNS.
- In upgrade mode, end the findings with the list of ADR paths to mark
  "re-validation required"; `/setup-stack` writes that into its report.
- A version recorded as `NOT DETERMINED — accepted by user YYYY-MM-DD` is an accepted
  gap, not a verified pin: say which ADR decisions depend on it.
