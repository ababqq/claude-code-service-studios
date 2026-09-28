# Settings Guidance — which value to recommend, and when

The **advisory** layer for project settings. This doc answers two questions no
other doc does:

1. **Which value should a skill recommend** for a given product or team?
2. **When should a skill proactively suggest changing** a setting already set?

## Boundary with its siblings — do not duplicate their content here

| Doc | Answers | Nature |
|---|---|---|
| `effects-map.md` | What each setting *does* | Descriptive |
| `config-resolution.md` | How a setting *resolves* (precedence chain) | Mechanical |
| **`settings-guidance.md`** (this file) | Which value to *recommend*, and *when* | Prescriptive |

Skills reference this doc **on demand**, only at a "recommend a setting" moment.
It is deliberately **not** a CLAUDE.md import — advisory content must not ride in
per-turn context (the same reason `context-management.md` is read on demand).

---

## 1. The knob that matters most: `modes.rigor`

Almost every "what settings should I use?" question reduces to one choice:
`modes.rigor` (`minimal` | `standard` | `full`). It fronts six sub-knobs —
`modes.workflow`, `docs.density`, `qa.level`, `modes.story_granularity`,
`modes.review_mode`, `team.size`. Recommend **rigor**, not the six; let the
expansion do the rest. The full expansion table lives in
`effects-map.md § modes.rigor` — do not restate it here.

Unset on an unconfigured project: `modes.rigor` defaults to `minimal`, which resolves `review_mode` to `solo`.

That default is deliberate: the heavier tiers cost several times more to reach
working code on a small project without producing a better result, and raising
rigor later is one `/settings` call. The upward triggers in § 4 are written to fire
from exactly that starting state.

`modes.automation` (`collaborative` | `guided` | `autonomous`) is a **separate
axis** — how often skills stop to confirm — and is *not* fronted by rigor. Pick it
by working style, not by product type: `collaborative` for anyone new to the
framework or working in a regulated codebase, `guided` once the team trusts the
defaults, `autonomous` only with `modes.automation_always_ask` kept at its default
list or stricter (`.claude/docs/automation-modes.md`).

---

## 2. Archetype → rigor presets

Match the project to an archetype; recommend the paired rigor. These are starting
points, not verdicts — the user can always override.

| Archetype | Rigor | Why | Common override |
|---|---|---|---|
| Hackathon / prototype / throwaway spike | `minimal` | Shipping beats recording; a one-pager and a pinned stack are enough to build from | Pin one risky feature higher: `workflow_overrides.feature_overrides: {payments: full}` |
| Seed-stage product team (a few engineers, first launch or early growth, one clear core journey) | `standard` | Enough product and technical design to build the right thing correctly — PRDs, an API contract, a walking skeleton on staging — without enterprise ceremony | "Comprehensive but compact": `rigor: full` + `docs.density: terse` |
| Regulated or enterprise — fintech, health, B2B with SLAs | `full` | Audit trails, security and privacy reviews, SLOs and every director gate pay for themselves when a mistake means a regulator, a breach or an SLA credit | Solo founder in a regulated space: keep `full` on disk, set `review_mode: solo` locally with `/settings --local` |

**The model:** the table picks a baseline; overrides handle the diagonal. Most real
projects are one baseline plus one or two deliberate exceptions — a `standard`
consumer app whose `payments` feature runs at `full`, or a `full` enterprise
product whose internal `admin-console` runs at `minimal`.

---

## 3. Seeding rigor from a described concept

When the user has described their product (for example in `/start`'s free-text
answer), map it to an archetype and **pre-select** the recommendation rather than
asking cold. Signals:

| Concept mentions… | Lean toward |
|---|---|
| payments, lending, investment, insurance, remittance, 전자금융, health or medical data, B2B enterprise, SLA, SOC 2, ISMS-P, audit, on-prem customers, "regulated" | `full` |
| hackathon, weekend, prototype, spike, proof of concept, fake door, side project, "just trying", "validating an idea" | `minimal` |
| seed or Series A, "launching", paying customers, app store release, a small team, a single clear core journey | `standard` |
| *ambiguous / nothing above* | `minimal` (the documented default) — the § 4 raise triggers catch growth |

**Rules:** these are heuristics, never locks. Always confirm the pre-selection with
the user in their own terms ("Sounds like a payments product with real customer
money — I'd suggest `full` rigor; want that?"). If the user has **no product idea
yet** (exploring), do not seed `full` — recommend `minimal`, and revisit once a
concept exists.

"No product idea yet" means **no signal**, not a particular onboarding path. A rough
one-line hint is still a description: if it trips the signals above, seed from the
signal. Only fall back to `minimal`-for-exploring when the user has given you
nothing to map. (`/start` states the same rule for its "no product idea yet" and
"a problem space" options — the two must agree, since both drive the identical
recommendation.)

---

## 4. When to recommend a *change* (adaptive triggers)

Bidirectional and **threshold-based**. Fire only on a threshold *crossing*, never
every session — that is what keeps this from becoming the nagging the `automation`
modes exist to eliminate.

| Trigger (crossing) | Direction | Detectable signal | Suggested action |
|---|---|---|---|
| Project grew past its band | ↑ raise | The PRD count (`design/prd/*.md`) crosses ~9, or `bash .claude/scripts/stage-estimate.sh` estimates `Build` or later, while rigor is `minimal` | "You're at N PRDs on `rigor: minimal` — most products this size run `standard`. Revisit? → `/settings`" |
| Stage advanced into Build | ↑ raise | `/gate-check` PASS into `Build` or a later phase while rigor is `minimal` | Same, offered once at the gate |
| User sounds overwhelmed by process | ↓ lower | Phrases like "too many steps", "so much documentation", "overwhelmed" — *and* rigor is not already `minimal` | "If the required-doc list feels heavy, a lower rigor trims it → `/settings modes.rigor=standard`" |
| Chosen rigor mismatches described scope | flag once | The onboarding pick contradicts the product the user described (a payments product on `minimal`, a weekend hackathon on `full`) | State it in one sentence, offer `/settings`, do not re-ask |

**Frequency guard:** the crossing *is* the gate. Because the hosts (`/gate-check` on
PASS, `/help` on request) are themselves infrequent, no persistent "already nudged"
state is needed — but never emit the same suggestion twice in one session.

---

## 5. Which skills reference this doc, and when

| Skill | Moment | Sections used |
|---|---|---|
| `/start` | Choosing rigor during onboarding | § 2 (presets), § 3 (seed from concept) |
| `/help` | Escalation footer when the user sounds stuck or overwhelmed | § 4 (lower trigger) |
| `/gate-check` | On PASS into `Build` or a later phase (the rigor-fit check) | § 4 (raise trigger) |
| `/settings` | View output — further reading | § 2 (choosing a value) |

Each skill carries a **one-line pointer** to this doc, not a copy of its tables.
The section numbers are pinned: skills cite `§ 2`–`§ 4` by number, so renumbering
this doc breaks them.

---

## 6. How to phrase a recommendation

- **Recommend, don't dictate.** State the suggestion and the reason in one line;
  the user decides.
- **Always route to `/settings`** — never edit `project.yaml` as a side effect of a
  recommendation. `/settings` is always collaborative, so the user approves the
  change in every automation mode, and it is the only skill that writes
  `modes.review_mode`.
- **Recommend rigor, not a fronted knob.** Pinning `modes.workflow` or
  `modes.review_mode` in `project.yaml` shadows the rigor expansion for the whole
  team; suggest a fronted knob only for a deliberate off-diagonal, and a personal
  preference (`review_mode`, `team.size`) as a `/settings --local` override.
- **One line, then stop.** A nudge is a nudge, not a lecture.
