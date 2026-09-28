# One-Pager: [Product Name]

> **Status**: Draft | Approved
> **Owner**: [the person accountable for the bet]
> **Last Updated**: [YYYY-MM-DD]
> **Category**: [the `project.category` value — e.g. "B2C fintech (subscription savings)"]

<!--
THE ONE-PAGE BRIEF. At the `minimal` workflow tier this is the entire product
record: it replaces the product brief, the feature map and the PRDs. `/brainstorm`
writes it to `design/product/one-pager.md`; `/create-stories` turns its Build Order
into stories; `/scope-check` compares new work against its Scope & Non-Goals.

Keep it to one screen. If a section needs a second paragraph, the project has
outgrown `minimal` — raise the tier with `/settings modes.rigor=standard` and run
`/brainstorm` again for the full product brief.

MACHINE CONTRACT — the seven `##` headings below are checked by
`/gate-check definition` at `minimal` (each must have real content) and
`## Build Order` is the plan the Validation → Build gate reads (at least one item).
Do not rename, translate or reorder them. Write the body in the team's language.

Director review lines, when the resolved review mode runs a gate, go under the
status block (`.claude/docs/director-gates.md` § Recording Gate Outcomes); at the
default `solo` review mode `/brainstorm` writes the skip notes there instead.

Examples use Moa, a B2C subscription savings app for the Korean market; the
numbers are illustrative. Delete these comments when the one-pager is written.
-->

## Pitch

[One sentence. If it takes two, cut until it is one.]

*Example*: "Moa moves part of your salary into your savings goals automatically on
payday, so saving no longer depends on remembering."

## Problem & Target User

- **Who**: [the target user, concretely — e.g. salaried 25–34-year-olds in Korea
  who save toward a goal by manual transfer each payday]
- **Problem**: [what goes wrong for them today, in their words]
- **Today they use**: [the workaround or competing alternative — including
  "doing nothing"]

## Core User Journey

<!-- The 3–5 steps from first open to the moment of value, and the loop that brings
the user back. Every step should be a screen or an event you can point at. -->

1. [e.g. Sign in with Kakao]
2. [Create a goal: name, amount, date]
3. [Authorise the payday transfer]
4. [Payday: the transfer runs and the goal fills — the moment of value]
5. [Loop: a notification after each transfer brings the user back]

## Success Signal

<!-- The observable signal that the product works — the thing every story's
acceptance criteria trace back to. One or two lines, measurable. -->

- [e.g. 20 test users each complete one automatic transfer within their first
  payday cycle, and at least 15 keep the goal active after the second payday]

## Scope & Non-Goals

- **In**: [the ruthlessly short capability list that makes it the product — longer
  than about seven items and it is not a one-pager any more]
- **Not now**: [what is deliberately out — e.g. no Plus plan, no shared goals, no
  web goal creation]
- **Principle** (optional): [one decision rule the team will not trade away — e.g.
  "saving happens without remembering: the automatic transfer stays the primary
  flow"]

## Stack

<!-- One line restating what `/setup-stack` pinned (it is the source of truth in
`project.yaml` under `stack.*`). If the stack is not set up yet, write the proposal
and run `/setup-stack` next. -->

- [e.g. Expo (React Native) app + NestJS API + PostgreSQL on a managed cloud — pinned
  by `/setup-stack` on YYYY-MM-DD]

## Build Order

<!-- The plan at this tier: each item becomes a story (`/create-stories`). Riskiest
or most valuable thing first — prove the value before polishing anything. -->

1. [e.g. Automatic transfer against the payment provider's sandbox, end to end]
2. [Goal creation and the goal progress view]
3. [Sign-in with Kakao and Apple]
4. [Transfer result notification]
