# User Journey Map: [Product Name]

> **Status**: Draft | In Review | Approved
> **Author**: [product-manager + product-designer]
> **Last Updated**: [YYYY-MM-DD]
> **Primary Persona**: [`design/product/personas/<slug>.md`, or one line — e.g., "A salaried 20s–30s professional in Seoul who wants to save for a trip but never sticks to a plan"]
> **Links To**: `design/product/product-brief.md` (or `design/product/one-pager.md`), `design/product/feature-map.md`, `design/product/tracking-plan.md`
> **North Star Metric**: [From the brief's `## Success Metrics` — e.g., "monthly active savers with ≥ 1 successful auto-debit"]
> **Business Model**: [B2C subscription / B2B seat-based / usage-based / free with ads — it changes which stages matter most]

**Journey summary**: [One paragraph describing the user's story from first hearing about the product to recommending it — in terms of their situation and feelings, not the feature list. Where do they start (skeptical, curious, in a hurry)? What is the first moment the product proves its value? What makes it part of their routine, and what makes them pay or tell someone?

Example (Moa): "She installs Moa from a friend's referral link, skeptical that another savings app will stick. Kakao login and a three-question goal setup get her to a scheduled first debit in under three minutes. The first Monday debit — and the progress ring moving — is the moment she believes it works. Weekly progress pushes keep her checking in; when she wants a second goal, she upgrades to Plus; when she hits her first goal, she shares it."

If the arc cannot be described in one paragraph, the product's value proposition is not yet clear enough — resolve that before filling in the stages below.]

---

## Lifecycle Stages

> **Guidance**: The seven stages below are the standard template. Not every product
> has every stage in the same form — a B2B tool may acquire through sales and sign up
> through an admin invite; a free product may have no monetization stage yet. Mark a
> stage "Not applicable — [reason]" or merge stages rather than filling them with
> placeholders. For each stage, list the features involved using the feature slugs
> from `design/product/feature-map.md`.

### Acquisition

**User's state on arrival**: [What they feel before they touch the product — e.g., "Curious from a friend's link; skeptical of finance apps asking for account details."]

**Question the user is asking**: [e.g., "Is this trustworthy? Is it for someone like me?"]

**What the product must deliver**: [The one thing the store listing, landing page or referral message must make clear.]

**Channels & touchpoints**: [Store listing (ASO), landing page, referral link, search ads, content, sales demo, partner integration]

**Features involved**: [feature slugs — e.g., `onboarding`]

**Exit state (success)**: [e.g., "Installs the app / starts sign-up with a clear expectation of what happens next."]

**Risk if this stage fails**: [e.g., "High cost per install with low sign-up conversion; wrong-fit users who churn in week 1."]

### Sign-up

**User's state on arrival**: [State]

**Question the user is asking**: [e.g., "How much do I have to give before I see anything?"]

**What the product must deliver**: [The shortest trustworthy path to an account — e.g., "Kakao / Naver / Apple login or email; required and optional consents separated; no card before value."]

**Channels & touchpoints**: [Sign-up screens, social login providers, verification email / SMS]

**Features involved**: [`auth`]

**Exit state (success)**: [Account created, consents recorded]

**Risk if this stage fails**: [e.g., "Drop-off at identity verification; users who never finish consent screens."]

### Onboarding / Activation

**User's state on arrival**: [State]

**Question the user is asking**: [e.g., "What do I do first? Will this actually work for me?"]

**What the product must deliver**: [The path from a new account to the activation event — the first moment of value — with nothing in between that the user does not need yet.]

**Activation event**: [The single event that defines an activated user and its target time — e.g., "`goal_create_completed` with a scheduled first debit, within 10 minutes of sign-up".]

**Activation ramp** (what the user knows and does not yet know as they progress):

| Time Since Sign-up | What the User Knows | What They Do Not Know Yet | What the Product Introduces |
|--------------------|---------------------|---------------------------|------------------------------|
| [0 min] | [What the store listing and first screen told them] | [Everything else] | [One primary action] |
| [3 min] | [How to create a goal] | [How auto-debit timing works] | [The debit schedule, with the date of the first debit] |
| [First week] | [That the first debit happened] | [Plus features, multiple goals] | [A progress notification after the first debit] |

**Feature introduction order**: [Which capabilities are shown first and which are deferred — introduce one new concept per step; never ask for a payment method before the user has seen what they are saving toward.]

**First failure**: [The first place the user can fail — e.g., payment-method registration declined — and how the product makes the cause and the fix obvious.]

**Channels & touchpoints**: [In-app onboarding, empty states, first push, welcome email]

**Features involved**: [`onboarding`, `goals`, `payments`]

**Exit state (success)**: [The activation event happened.]

**Risk if this stage fails**: [e.g., "Users who create an account but never schedule a debit — the largest leak in savings apps."]

### Habit

**User's state on arrival**: [Activated; the product is new in their routine]

**Question the user is asking**: [e.g., "Is it still working without me thinking about it?"]

**What the product must deliver**: [The repeated value loop and the triggers that bring the user back.]

**Triggers that bring the user back**:

| Trigger | Cadence | Channel | What the User Sees on Return | Features |
|---------|---------|---------|-------------------------------|----------|
| [Debit succeeded] | [Per debit] | [Push (informational)] | [Goal detail with the new balance] | [`notifications`, `goals`] |
| [Weekly progress] | [Weekly] | [Push / 알림톡 (informational)] | [Progress summary] | [`notifications`] |
| [Trigger] | [Cadence] | [Channel] | [Landing] | [Features] |

**Exit state (success)**: [e.g., "Opens the app at least weekly for four consecutive weeks."]

**Risk if this stage fails**: [e.g., "Silent success — debits keep running but the user forgets the app exists and cancels at the next card statement."]

### Retention

**User's state on arrival**: [Established user; value is proven but taken for granted]

**Question the user is asking**: [e.g., "Is this still worth keeping? What else can it do?"]

**What the product must deliver**: [Reasons to stay after the first goal: new goals, streaks, insights; recovery when something goes wrong (failed debit, card expiry).]

**Win-back and recovery**: [What happens when a user goes dormant or a payment fails — lifecycle messages (informational vs marketing, with the consent each needs), in-app recovery paths.]

**Features involved**: [feature slugs]

**Exit state (success)**: [e.g., "Active at D30 and D90."]

**Risk if this stage fails**: [e.g., "Churn after the first goal is reached."]

### Monetization

**User's state on arrival**: [Retained; aware of the paid plan's value]

**Question the user is asking**: [e.g., "What do I get for paying, and can I cancel easily?"]

**What the product must deliver**: [A paid plan whose value the user has already felt (e.g., a second goal), with price, renewal date and cancellation shown before commitment. Plans and prices come from `design/product/pricing-model.md`.]

**Upgrade moments**: [Where the upgrade is offered — at the limit the user just hit, never as an interruption of a core task.]

**Features involved**: [`subscription`, `payments`]

**Exit state (success)**: [Paid conversion; renewal without surprise]

**Risk if this stage fails**: [e.g., "Refund requests and chargebacks from users who did not understand the renewal."]

### Advocacy

**User's state on arrival**: [A satisfied user with a result worth sharing]

**Question the user is asking**: [e.g., "Would my friends benefit? Is sharing easy and not embarrassing?"]

**What the product must deliver**: [A natural share moment (goal reached), a referral mechanism, a review prompt at a high point.]

**Features involved**: [feature slugs]

**Exit state (success)**: [Referral sent, store review, public share]

**Risk if this stage fails**: [e.g., "Growth depends entirely on paid acquisition."]

---

## Moments of Value

> **Guidance**: Specific, individual moments — not stages — that must land precisely.
> Each has an event that proves it happened, so it can be measured. Missing one
> through bad UX, poor timing or weak feedback can derail the journey. Identify
> 5–12 moments; mark the activation moment.

| Moment | Stage | What the User Experiences | Evidence (Event) | Target Time from Sign-up | If It Fails |
|--------|-------|---------------------------|------------------|--------------------------|-------------|
| [Goal created with a clear first-debit date] **(activation)** | [Onboarding / Activation] | ["I know exactly when saving starts"] | [`goal_create_completed`] | [≤ 10 min] | [User unsure the plan is real; abandons before the first debit] |
| [First debit succeeds and the progress ring moves] | [Habit] | ["It works without me"] | [`deposit_succeeded` (first)] | [≤ 7 days] | [User forgets the app] |
| [First goal reached] | [Advocacy] | [Pride — something worth sharing] | [`goal_completed`] | [Goal-dependent] | [No share moment; no second goal] |
| [Moment] | [Stage] | [Experience] | [Event] | [Target] | [Failure consequence] |

---

## Drop-off Risks

> **Guidance**: Where users leave, how you will see it, and what the product does
> about it. Every risk has a measurable signal — a risk without one is a guess.

| Risk | Stage | Signal (Metric / Event) | Likely Cause | Mitigation | Owner |
|------|-------|-------------------------|--------------|------------|-------|
| [Sign-up abandoned at identity verification] | [Sign-up] | [`signup_started` → `signup_completed` conversion by step] | [Vendor flow friction; unclear why it is needed] | [Explain why before the vendor flow; resume where the user left] | [product-designer] |
| [Account created, no goal] | [Onboarding / Activation] | [Share of new accounts without `goal_create_completed` at D1] | [Too many steps before value] | [Template goals; defer the payment method until review] | [product-manager] |
| [Debit failed, user churns] | [Retention] | [`deposit_failed` followed by no session in 7 days] | [Insufficient balance, expired card] | [Recovery banner + informational push with a one-tap fix] | [growth-manager] |
| [Risk] | [Stage] | [Signal] | [Cause] | [Mitigation] | [Owner] |

### Mitigations this product does not use

- [No confirmshaming ("No, I don't want to save money") on declines or dismissals]
- [No pre-checked optional or marketing consents; "agree to all" never hides an optional item]
- [Cancellation is reachable in-app and never harder than sign-up]
- [No fake urgency or countdowns on plans or prices]
- [Add any further pattern the team rules out]

---

## Metrics per Stage

> **Guidance**: At least one metric per applicable stage, defined from events in
> `design/product/tracking-plan.md`, with a baseline (or "unknown — measure first")
> and a target. Guardrail metrics (refund rate, unsubscribe rate, support contacts)
> sit next to the growth metric they protect.

| Stage | Metric | Definition (Event-Based) | Baseline | Target | Guardrail | Source (Dashboard / Event) | Review Cadence |
|-------|--------|--------------------------|----------|--------|-----------|----------------------------|----------------|
| [Acquisition] | [Store page → install conversion] | [Installs ÷ store page views] | [unknown] | [Target] | [Cost per install] | [Store console] | [Weekly] |
| [Sign-up] | [Sign-up completion] | [`signup_completed` ÷ `signup_started`] | [Baseline] | [Target] | [—] | [Product analytics] | [Weekly] |
| [Onboarding / Activation] | [Activation rate] | [New accounts with `goal_create_completed` within 24 h ÷ new accounts] | [Baseline] | [Target] | [Support contacts per 100 sign-ups] | [Funnel] | [Weekly] |
| [Habit] | [Weekly active savers] | [Accounts with ≥ 1 session and an active goal in the week] | [Baseline] | [Target] | [Push opt-out rate] | [Dashboard] | [Weekly] |
| [Retention] | [D1 / D7 / D30 retention] | [Cohort retention on any session] | [Baseline] | [Target] | [—] | [Cohort chart] | [Monthly] |
| [Monetization] | [Free → Plus conversion] | [`subscription_started` ÷ activated accounts, 30-day window] | [Baseline] | [Target] | [Refund and chargeback rate] | [Billing dashboard] | [Monthly] |
| [Advocacy] | [Referral rate] | [Accounts sending ≥ 1 referral ÷ active accounts] | [Baseline] | [Target] | [—] | [Referral dashboard] | [Monthly] |

### Validation Questions

> Questions a usability or interview session asks per stage to check that the journey
> works as intended (`/usability-report` records the answers). They probe the user's
> experience — avoid yes/no questions.

**Acquisition / Sign-up**
- [ ] "Before signing up, what did you expect this app to do for you?"
- [ ] "Was there any point where you hesitated? What made you hesitate?"

**Onboarding / Activation**
- [ ] "Without looking at any help, what happens next with your savings?"
- [ ] "Is there anything you feel you should understand but don't?"

**Habit / Retention**
- [ ] "When did you last open the app, and what made you open it?"
- [ ] "If the app disappeared tomorrow, what would you miss?"

**Monetization / Advocacy**
- [ ] "What would make the paid plan worth it to you — or not?"
- [ ] "Have you told anyone about the app? What did you say?"
