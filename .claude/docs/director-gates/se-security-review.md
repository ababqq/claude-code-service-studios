> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# SE-SECURITY-REVIEW — Security & Privacy Design Review

Agent: `security-engineer` | Model tier: inherit | Domain: Application security & privacy

**Trigger**: Spawned by `/api-design` when an API contract is written or changed, by
`/data-model` after the data model is drafted, and by `/architecture-decision` for
ADRs whose Domain is `Auth`, `Security` or `Data`. It reviews authorization per
operation (BOLA/IDOR), trust boundaries, PII classification, retention and consent,
secrets, and the configured `compliance.regions` — at design time, before code is
written against the artifact.

**Context to pass**:
- artifact path (contract, data model or ADR)
- operations or entities with auth scope and PII classification
- resolved `compliance` line
- `docs/security/threat-model.md` path (or "none")

**Prompt**:
> "Review this design artifact for security and privacy before anything is built on
> it. Read the artifact and the threat model (if one exists) at the paths given; the
> operations or entities passed to you, with their auth scopes and PII
> classifications, are the scope of this review. Check:
>
> 1. **Authorization per operation** — every operation declares who may call it.
>    Object-level: each operation that takes an ID checks the caller's right to that
>    specific object (OWASP API Security Top 10 2023, API1 — BOLA/IDOR); for Moa,
>    `GET /goals/{goalId}` and `DELETE /payments/mandates/{mandateId}` are scoped to
>    the owner. Function-level: admin and support operations require a role (API5).
>    Property-level: responses expose only the fields the caller may see, and
>    requests cannot set protected fields such as `ownerId`, `plan` or `role` (API3).
> 2. **Authentication** — session and token lifetimes, refresh-token rotation and
>    revocation, social login (Kakao, Naver, Apple) and account linking without
>    takeover by matching email alone, step-up verification for sensitive actions
>    (changing the debit account, exporting data, deleting the account).
> 3. **Trust boundaries** — the server never trusts client-computed amounts, prices
>    or entitlements; webhooks are verified (signature or shared secret) and
>    replay-safe; URLs supplied by users cannot reach internal networks (SSRF);
>    responses from third parties are validated before use.
> 4. **Abuse and resource limits** — rate limits per user and per IP, limits on
>    page size and payload, protection of business flows that attackers automate
>    (sign-up reward abuse, SMS or OTP pumping, card or account enumeration).
> 5. **Personal data** — each field classified `Public`, `Internal`, `Confidential`,
>    `PII` or `Sensitive-PII`; data minimisation (collect nothing the feature does
>    not use — national identification numbers in particular); retention and a
>    deletion or anonymisation path for every PII field, reachable from account
>    deletion; consent linkage (marketing consent separate from terms acceptance);
>    encryption for Sensitive-PII; PII excluded from logs, analytics events and
>    error reports.
> 6. **Secrets** — no real keys or tokens in contracts, examples or fixtures; secrets
>    stored in a managed secret store and separated per environment.
> 7. **Regional compliance** — for each region in the `compliance` line, the relevant
>    items of `.claude/docs/compliance/<region>.md` as topics to verify (for `kr`:
>    personal-information consent, purpose limitation and cross-border transfer,
>    and electronic-financial-transaction obligations for payment flows).
> 8. **Threat model alignment** — new trust boundaries and data flows introduced by
>    this artifact appear in the threat model.
>
> Rate each finding Critical, High, Medium or Low, with the fix. Return APPROVE,
> CONCERNS [findings with severity and fix], or REJECT [a Critical or High design
> flaw — an operation without object-level authorization, Sensitive-PII without a
> retention and deletion path, an unverified money-moving webhook — resolve before
> the artifact is accepted]."

**Verdicts**: APPROVE / CONCERNS / REJECT

The first line of the reply is exactly `[SE-SECURITY-REVIEW]: <TOKEN>` with one token
from the line above; the spawning skill parses it. Findings follow the first line.

**Special handling**:
- Not a legal opinion. Regional items are checklist topics to verify; never state a
  deadline, fine or threshold unless a source is cited (`NOT SOURCEABLE` otherwise).
- A `compliance` line with parts `(unset -- ask)` is an open question to raise, never
  "no obligations"; `regions=none` means the user explicitly chose none — skip the
  regional items and say so. `handles_pii` unset while the artifact contains `PII`
  or `Sensitive-PII` fields is itself a finding: the skill asks the user to set it.
- A threat model passed as "none" while the artifact handles personal data is a
  CONCERNS item recommending `/security-audit threat-model`; it is not grounds for
  REJECT on its own.
