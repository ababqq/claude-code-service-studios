---
paths:
  - ".claude/skills/**"
  - ".claude/agents/**"
---

# Skill and Gate Authoring

**A check that cannot report that it did not run is not a check.**

The same shape recurs across unrelated subsystems, so treat it as the default
risk in any check you write, not as an unusual mistake.

The failure is always the same trade: a step that could not run produces output
indistinguishable from a step that ran and found nothing. Nobody reading the
output can tell which happened, and the permissive reading is the one that gets
believed, because it is the one that lets work proceed.

## The five obligations

### 1. Every gating verdict needs a "could not assess" value

If a skill emits a verdict something else depends on, its vocabulary must include
one — `NOT ASSESSED`, or the local equivalent — and the report must say *which*
of the reasons applied. A vocabulary of three confident verdicts forces every
unknown into a claim.

**Rank it deliberately.** It must outrank the pass value: a run that could not
assess part of its scope has not established that the scope is good. It must
**not** outrank the failure values: a known problem is more actionable than an
unknown, and demoting a real failure behind an access problem buries it.

**`NOT ASSESSED` is not a gentler failure verdict.** "I looked and found nothing"
and "I could not look" have different fixes — one needs work done, the other
needs access granted or an input classified. Collapsing them sends the reader to
the wrong fix.

### 2. An absent value may not default to the permissive one

Especially when **nothing in the framework writes that key**. Before defaulting,
check who sets it: a key with a reader and no writer takes its default branch on
every project that ever runs, so that branch is not an edge case — it is the
behaviour.

Unset is not "no": `privacy.handles_pii` unset is not `false`,
`accessibility.target` unset is not `none`, and `compliance.regions` unset is not
`[]` — `[]` is the user saying "explicitly none", unset is nobody having been
asked. Each of them means **ask**.

Over-running a check costs minutes. Under-running one ships the category unrun.

### 3. A skipped step announces itself

In the output, not only in the source. If a phase, category, or agent did not run
— an unconfigured stack layer, missing config, no code root resolved, unavailable
input, a `team.size` that collapses the pipeline — the artifact must say so by
name (`NOT CHECKED — mobile layer not configured (run /setup-stack)`). A silent
skip and a successful one are the same artifact.

A rule enforced in the body and never surfaced in the output is, to the reader,
identical to no rule at all.

### 4. Never assert what you cannot source — and wire the gap to the verdict

Where this repo pins external facts (`docs/stack-reference/**`), do not fill a
gap from training data. Write the gap down instead: `NOT SOURCEABLE — <what> is
not covered by <path>`, or `NOT DETERMINED` for a version the pin has not
established. The regional compliance checklists (`.claude/docs/compliance/**`)
deliberately carry no deadlines, fines or thresholds: a number there needs
`(Source: <url>, retrieved YYYY-MM-DD)` from a live source, or it is not written.

**Flagging alone is not enough.** A named gap that does not reach the verdict is
just a comment. Wire it: a category with no sourced inputs must force obligation
1's value, so the gap makes the pass unreachable rather than sitting beside it.

A confidently wrong pattern list is worse than an absent one — it produces a scan
that looks thorough, finds nothing, and reads as a pass.

### 5. Gates derive their covered set; they do not enumerate it

An allowlist pins what was known when it was written and is silent about
everything added since. Derive the set from what the repo actually contains, so a
new skill or agent cannot ship outside coverage by simply not being on a list.

**If the category is not mechanically crisp, say so in the gate and keep the
list.** A gate that fires on forty files does not get fixed, it gets muted — and
a muted gate is worse than a narrow one, because it reads as coverage. When you
keep a list, record *why* derivation failed and state the obligation to extend it.

Two further gate rules earned the hard way:

- **Assert something that cannot be true by accident.** A short word is
  satisfied by accident: a check for "unit" — meant to prove a skill runs unit
  tests — passes on any file path that merely names `tests/unit/`, and, as a
  bare substring, on "community". Assert a distinctive token instead.
- **A gate you have not watched fail is not a gate.** Break the thing it guards,
  confirm it fails, restore. One mutation per tool invocation — a batch that
  times out leaves the repo holding a broken file, and `trap … EXIT` does not
  survive `SIGTERM`.

## Evidence

Every row below is a real instance this rule was written to prevent.

| Where | What was indistinguishable from success |
|---|---|
| `team-*` stack step | Specialist skipped when no stack layer was configured — output identical to a run that consulted one |
| `team-ui` accessibility gate | Passed vacuously; its criterion file did not exist |
| `yaml-helper` | Locked key in `project.local.yaml` dropped in silence; user saw the default they were overriding |
| every `team-*` skill | Pipeline printed six agents and ran one, with no statement of the difference |
| `/security-audit` | Greps written for one stack returned zero hits on the others — they looked in the wrong place — and zero hits read as clean |
| version reference `VERSION.md` | "Post-cutoff" table listed pre-cutoff versions, inverting the signal it exists to send |
| `/security-audit` | The config key gating the network category had a reader and no writer; the category never ran, on any project |
| `test-evidence-review` | No verdict for "could not check", so an unverifiable story got a verdict saying it was verified |
| `detect-gaps` stage-lag check | Read `project.stage` without passing the file; the check never saw `project.yaml` and printed nothing, like a project with no lag |
| `create-stories` catalog step | A glob with a minimum of two files was met by an epic's `EPIC.md` and the epic index — zero stories read as done |
| `/team-qa` | A missing smoke report was treated as PASS WITH WARNINGS |
| array config reader | Could not tell `[]` from an absent key — "explicitly none" and "never asked" read the same |
| the gate meant to catch all of this | Was a hand-written list, and read green over the gap |

## Skill file rules

Numbered so that skills, agents and reviews can cite them ("the rule-12 verdict
line"). Where a rule requires exact text, the text lives in the file named — copy
it from there, never from memory or from another skill that may have drifted.

1. **Identity.** Directory name == frontmatter `name` == the entry name in
   `CCSS Skill Testing Framework/catalog.yaml` == the spec file's basename.
2. **Bootstrap.** A skill that needs config has the `resolve_config --keys`
   injection as its first body line, a matching grant that names its own
   directory, only labels the helper emits, and exactly one of the two "Resolved
   above" lines after the block — all in `.claude/docs/config-resolution.md`
   § The rule and § Labels.
3. **Automation prelude.** A skill whose keys contain `automation` carries the
   prelude block verbatim right after the rule-2 line
   (`.claude/docs/automation-modes.md` § How to Use This Document).
4. **Ask before every write.** A skill with `Write` or `Edit` asks "May I write
   this to `<path>`?" before each write.
5. **Gate spawning.** A skill that spawns director gates has `Agent` and
   `AskUserQuestion` in `allowed-tools`, `review_mode` in its keys and a
   review-mode check naming each gate it spawns, with the lean suffix rule; each
   spawn passes the gate file path plus that gate's Context bullets on a `Pass:`
   line, and parses the agent's first line as `[GATE-ID]: TOKEN`
   (`.claude/docs/director-gates.md` § Review Modes, § Invocation Pattern,
   § Context to Pass). `/hotfix`, `/rollout-plan` and `/incident` carry the
   review-mode exemption sentence from § Review Modes instead.
6. **Exact verdicts.** Verdict tokens are spelled exactly as the skill defines
   them, and `NOT ASSESSED` is always available (obligation 1).
7. **Always-collaborative skills** — `/gate-check`, `/hotfix`, `/incident`,
   `/rollout-plan`, `/setup-stack`, `/start`, `/settings` — ignore
   `modes.automation`: every step is approved, and they **never gain an
   automation prelude** and never request the `automation` key, however an edit
   is phrased (`.claude/docs/automation-modes.md` § Exemptions — Skills That
   Ignore the Automation Setting).
8. **Nothing that counts goes to session logs.** `production/session-logs/` is
   gitignored: evidence, reports and plans written there do not exist for the
   next reader. Write them under the tracked `production/` paths the skill's
   contract names.
9. **No fronted knobs.** No skill writes or seeds the six keys `modes.rigor`
   fronts (`modes.workflow`, `docs.density`, `qa.level`,
   `modes.story_granularity`, `modes.review_mode`, `team.size`); only
   `/settings`, on the user's explicit request, changes them.
10. **Hand-offs name real skills.** Every "next step" names a skill that exists
    under `.claude/skills/` — check the directory. Claude Code's bundled skills
    (`/design`, `/design-sync`, `/design-login`) and plugin skills (Figma's) are
    never a next step: a skill names them only conditionally, as a tool the user
    runs or approves ("if the bundled `/design` skill is present in the
    session"), and no skill takes a bundled skill's name — a project skill of
    the same name would shadow it.
11. **No `file:line` citations.** Line numbers go stale with the next edit to
    the cited file. Cite the file and its heading instead
    (`.claude/docs/director-gates.md` § Context to Pass), never `<file>:<line>`.
12. **Report verdict line.** A report or record that carries a verdict has, directly
    under its H1 and one blank line, `> **Verdict**: <TOKEN>` with the skill's
    exact tokens. `/gate-check`, `/release-checklist`, `/rollout-plan`,
    `/team-release` and `/retrospective` parse that line.
13. **One injection.** The bootstrap line is the only `!` injection, and no
    injection contains `$(`, `${`, `;`, `|` or `&&` — the permission check
    rejects expansions. Everything else is gathered at run time with
    Read, Glob or Bash.
14. **Keys follow content.** A skill that mentions a code root requests
    `code_roots`; one that names an always-ask category requests
    `automation_always_ask` (unless it is always-collaborative). Keys with no
    `resolve_config` label — `performance.*`, `testing.patterns`,
    `testing.framework`, `naming.*`, `commands.*`, `localization.locales`,
    `platform.browsers`, `platform.min_os.*`, `stack.monorepo`,
    `stack.package_manager` — are read from `project.yaml` with Read at run
    time.
15. **`allowed-tools` is exact.** It lists the tools the skill uses — no more,
    no fewer — and never an MCP tool name, which varies per install. A skill
    that may use Context7 says "use Context7 if its tools are present in the
    session, else WebSearch/WebFetch". Every tool whose presence depends on the
    host is handled the same way — MCP servers (Context7, Figma, the Claude
    Design connector) and the host-conditional built-ins `Artifact` and
    `Skill`: never listed, named conditionally ("use the Figma MCP server if
    its tools are present in the session, else …"), and, when absent, a named
    `NOT CHECKED — <tool> … not present in this session` line in the output
    (obligation 3). No skill calls `DesignSync`; only the bundled
    `/design-sync` does. Agents cannot reach any of these tools — their
    `tools:` lists are allowlists — so the orchestrating skill reads the
    external source and briefs agents with file paths.
16. **Model.** New skills declare `model: sonnet` unless there is a stated
    reason; existing values are kept. The field is declared but not applied
    (`.claude/docs/model-tiers.md`).

A skill that hands work to another skill documents the hand-off in
`.claude/skills/<skill>/CONTRACT.md`, starting from
`.claude/docs/templates/SKILL-CONTRACT-TEMPLATE.md`.

## Agent file skeleton

Every file under `.claude/agents/` has the same shape, so a reader — and the
agent spec in `CCSS Skill Testing Framework/agents/` — can find the same thing
in the same place.

- **Frontmatter keys, in order**: `name`, `description`, `tools`,
  `disallowedTools` (only for agents that must not run shell commands),
  `model`, `maxTurns`, `memory` (only when set), `skills` (only when set),
  `isolation` (only `prototyper`). `name` equals the file stem. `description` is
  one double-quoted line: `"<what the agent owns>. Use when <trigger>."`.
  Frontmatter `model:` is the single source of truth for the tier;
  `.claude/docs/model-tiers.md` is derived from it, never the other way round.
- **Opening line** after the frontmatter: "You are the <Title> for a
  <web/mobile/API> product team."
- **Body headings (`##`), in this order**:
  1. `## Collaboration Protocol` — the agent's workflow as a `###` heading, one of
     `Strategic Decision Workflow`, `Question-First Workflow`,
     `Implementation Workflow`, `Operations Workflow` (a role with a second mode
     adds that workflow too, as `release-manager` adds Question-First for release
     planning), then the paragraph
     beginning "**Bounded exception — orchestrated runs.**", copied verbatim
     from any existing agent file.
  2. `## Core Responsibilities`
  3. `## <Domain> Standards` (for example `## API Standards`,
     `## Design Language Standards`)
  4. `## Gate Verdict Format` — only in agents that own a director gate
     (derive the set from the Owner column of `.claude/docs/director-gates.md`
     § Gate Index; no other agent has the section). It lists each owned gate
     with its exact tokens and the first-line contract `[GATE-ID]: TOKEN`.
  5. `## Sub-Specialist Orchestration` — only stack leads whose `tools` carry an
     `Agent(...)` grant.
  6. `## Version Awareness` — only stack agents (the layer leads and their
     sub-specialists): consult `docs/stack-reference/` before version-sensitive
     advice, flag post-cutoff APIs with their Knowledge Risk, answer
     `NOT SOURCEABLE — run /setup-stack refresh` rather than guess.
  7. `## What This Agent Must NOT Do`
  8. `## Delegation Map` — three lines: `Reports to: <agent|user>`,
     `Delegates to: <list|—>`, `Coordinates with: <list>`.
- **Reporting lines close**: the agent an agent names in `Reports to:` lists
  that agent in its own `Delegates to:` line. Additional delegators are allowed;
  a missing entry in the parent is a defect.

## The test to apply

Before shipping a skill or gate, ask: **if this step silently did not run, what
would the output look like?**

If the answer is "the same", it is not finished.
