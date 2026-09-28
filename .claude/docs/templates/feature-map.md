# Feature Map: [Product Name]

> **Status**: Draft | In Review | Approved
> **Created**: [YYYY-MM-DD]
> **Last Updated**: [YYYY-MM-DD]
> **Source Brief**: design/product/product-brief.md

<!--
TEMPLATE NOTES — delete this comment block in the written feature map.

Written by /map-features to design/product/feature-map.md; /write-prd updates a row's
Status and PRD columns as each PRD moves; /prd-review sets Approved.

The main table header under ## Features is a contract, read by column name by
/write-prd, /prd-review, /create-epics, /create-stories, /story-readiness,
/architecture-review, /review-all-prds, /qa-plan, /regression-suite, /ui-inventory,
/adopt and the Definition -> Architecture gate. Never add, drop, rename or reorder a
column; prose about a feature goes in ## Overview.

Column values:
- Feature    - the feature slug, kebab-case. It is also the PRD file stem
               (design/prd/<slug>.md), the TR-<slug>-NNN prefix and the
               workflow_overrides.feature_overrides key.
- Category   - free text; use the recommended list under ## Categories when one fits.
               "Domain" names the product's core domain features (the word "Core" is
               reserved for the Layer column).
- Layer      - Foundation | Core | Feature | Presentation
- Tier       - MVP | Beta | GA | Later
- Status     - Not Started | Drafting | In Review | Needs Revision | Approved | Implemented
               (1:1 with the PRD's Status line: Draft <-> Drafting; the other four are
               the same word; Not Started = no PRD yet)
- PRD        - design/prd/<slug>.md, or — before the PRD exists
- Depends On - comma-separated feature slugs, or —. Lists every feature the PRD's
               ## Dependencies table marks "depends on"; the reverse direction is
               derived, never listed here.
-->

---

## Overview

[One paragraph on the product's functional scope: which features deliver the value proposition, which core user
journey they serve, and where the MVP line sits. At `balanced` and `thorough` docs density, add one short paragraph
per feature (and relationship analysis at `thorough`) — here, never as an extra table column. List the features that
were inferred rather than named in the brief: "Inferred: settings-account, admin-console, …".]

---

## Features

| Feature | Category | Layer | Tier | Status | PRD | Depends On |
|---|---|---|---|---|---|---|
| [e.g. auth] | Identity | Foundation | MVP | Not Started | — | — |
| [e.g. payments] | Payments | Core | MVP | Not Started | — | auth |
| [e.g. goals] | Domain | Feature | MVP | Drafting | design/prd/goals.md | auth, payments |
| [e.g. family-goals] | Collaboration | Feature | Later | Not Started | — | goals |

[One row per feature. Every step of every core user journey in the brief maps to at least one row.]

---

## Categories

| Category | Covers | Typical Features |
|----------|--------|------------------|
| **Identity** | Sign-up, sign-in, sessions, identity verification | Email and social login (Kakao, Naver, Apple, Google), passkeys, 본인인증 |
| **Onboarding** | First-run flow to the first moment of value | Welcome flow, permission priming, first-goal setup |
| **Domain** | The product's core domain features — why users come | Savings goals, orders, bookings, documents |
| **Payments** | Taking and returning money | Checkout, auto-debit (billing key), refunds, settlement webhooks |
| **Billing** | Plans and entitlements | Subscriptions, invoices, receipts, dunning |
| **Notifications** | Messages to users | Push, email, SMS, 알림톡, in-app inbox, preferences |
| **Search** | Finding things | Search, filters, sorting, recent searches |
| **Account** | The user's own data and settings | Profile, settings, data export, account deletion |
| **Permissions** | Who may do what | Roles, RBAC, workspaces and invitations (B2B) |
| **Collaboration** | Shared use | Sharing, comments, shared goals, activity feeds |
| **Content** | Authored or user-generated content | CMS pages, help content, user posts, moderation |
| **Reporting** | Information the user reads back | Statements, dashboards, exports |
| **Admin** | Back-office for the operating team | Support console, refunds tooling, content management |
| **Analytics** | Measuring the product | Instrumentation, experiments, attribution |
| **Compliance** | Legal and privacy obligations | Consent management, terms acceptance, retention, audit log |
| **Support** | Helping users | Help center, contact, chat, status page |
| **Integration** | Connections to other systems | Webhooks, public API, partner integrations |

[Not every product needs every category. Add a category when none fits — Category is free text.]

---

## Tiers

| Tier | Definition | Target Milestone | PRD Urgency |
|------|------------|------------------|-------------|
| **MVP** | The smallest set that lets a target user complete the core user journey and proves the value hypothesis | MVP / Private Beta | Write FIRST |
| **Beta** | Completes the experience for early users; closes the most painful gaps found in the MVP | Public Beta | Write SECOND |
| **GA** | Everything needed for a general launch: scale, self-service, admin depth, compliance completeness | GA | Write THIRD |
| **Later** | Valuable, not needed for GA; revisit with evidence | Post-GA | Write when scheduled |

[Each tier is a shippable product if work stops there. No MVP feature depends on a Beta, GA or Later feature.]

---

## Dependency Map

[Features sorted by dependency order — specify and build from the top down.]

### Foundation Layer (no feature dependencies)

1. [feature] — [why it is foundational: what depends on it]

### Core Layer (depends on Foundation only)

1. [feature] — depends on: [list]

### Feature Layer (depends on Core or other Feature-layer features)

1. [feature] — depends on: [list]

### Presentation Layer (flows and surfaces that wrap other features)

1. [feature] — depends on: [list]

---

## PRD Authoring Order

[Dependency order combined with tier: MVP Foundation first, then MVP Core, MVP Feature, MVP Presentation, then the
Beta layers, and so on. Independent features in the same layer can be written in parallel.]

| Order | Feature | Tier | Layer | Owner / Consultants | Est. Effort |
|-------|---------|------|-------|---------------------|-------------|
| 1 | [e.g. auth] | MVP | Foundation | product-manager; tech-lead, security-engineer | [S/M/L] |
| 2 | [e.g. payments] | MVP | Core | product-manager; business-analyst, tech-lead | [S/M/L] |

[Effort: S = one session, M = 2–3 sessions, L = 4+ sessions. A session is one focused `/write-prd` conversation
producing a complete PRD.]

---

## Circular Dependencies

[Cycles found in the dependency graph, each with its resolution — an event contract, an interface owned by one side,
or specifying both features together.]

- [None found] OR
- [e.g. goals ↔ payments: a debit belongs to a goal, and goal progress comes from debits. Resolved: payments stores
  the goal ID as an opaque reference and publishes `payment_settled`; goals depends on payments, never the reverse.]

---

## High-Risk Features

[Features that are technically unproven, uncertain in value, dependent on an external approval, or scope-dangerous.
Prototype or validate these early regardless of tier.]

| Feature | Risk Type | Risk Description | Mitigation |
|---------|-----------|------------------|------------|
| [e.g. payments] | [External / Technical / Value / Scope] | [e.g. payment-provider merchant review and auto-debit approval lead time] | [e.g. apply in week 1; sandbox integration first] |

---

## Progress Tracker

| Metric | Count |
|--------|-------|
| Features identified | [N] |
| PRDs drafting | [N] |
| PRDs in review | [N] |
| PRDs approved | [N] |
| MVP features with an approved PRD | [N / total MVP] |
| Beta features with an approved PRD | [N / total Beta] |

---

## Next Steps

- [ ] Review and approve this feature map
- [ ] Write the MVP PRDs in authoring order (`/write-prd <feature>`, or `/map-features next`)
- [ ] Review each PRD in a fresh session (`/prd-review design/prd/<feature>.md`)
- [ ] Run `/review-all-prds` when the MVP PRDs are written
- [ ] Run `/gate-check architecture` when every MVP PRD is reviewed
