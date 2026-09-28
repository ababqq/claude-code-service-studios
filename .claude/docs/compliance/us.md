# Regional Compliance Checklist — United States (`us`)

> **Loaded only when** `compliance.regions` in `project.yaml` contains `us`. Skills never read this file for a
> project whose regions are unset (they ask first) or explicitly `[]` (they skip regional items and say so).
>
> **What this is**: a topic checklist of what to verify before building, auditing or launching a service for users
> in the United States. **What this is not**: legal advice, a complete statement of the law, or a source of numbers.
>
> **Rules for every skill and agent that uses it**
> - Each item names its `Law/standard:` (official name) and where to `Verify at:` (the official body or the
>   official source). US obligations are split between federal law and the laws of each state the product
>   serves — confirm which states apply.
> - This file states no deadlines, fines, age limits, revenue or record-count thresholds, calling hours or
>   effective dates. When an artifact needs one, the skill writes it with `(Source: <url>, retrieved YYYY-MM-DD)`
>   at run time, or writes `NOT SOURCEABLE — confirm with counsel`. A number without a source line is a defect.
> - Coverage is derived, not chosen: a skill that loads this file lists **every** item of the sections it uses and
>   gives each one the status vocabulary that skill defines (for example `/security-audit` uses
>   `Met | Gap | Accepted | N/A | NOT ASSESSED`). An item is `N/A` only with a one-line reason
>   (e.g. "no SMS sent"); an item nobody could check is `NOT ASSESSED`, never `Met`.
> - Items are not advice to act on without review: a `Gap` is resolved by the product team with counsel, or
>   explicitly accepted by a named owner with the date and reason recorded in the artifact.

## Privacy & Data Protection

- **CCPA/CPRA applicability** — whether the business meets any of the applicability criteria in force (revenue,
  volume of consumers' personal information, or share of revenue from selling or sharing it); record the result
  with its source even when the answer is "not yet".
  - Law/standard: California Consumer Privacy Act, as amended by the California Privacy Rights Act (CCPA/CPRA), and the CCPA Regulations
  - Verify at: California Privacy Protection Agency — cppa.ca.gov; California Attorney General — oag.ca.gov/privacy/ccpa
- **Notice at collection and privacy policy** — categories of personal information and sensitive personal
  information collected, purposes, retention per category, whether it is sold or shared (including cross-context
  behavioral advertising through SDKs and pixels), and how consumers exercise their rights.
  - Law/standard: CCPA/CPRA and CCPA Regulations
  - Verify at: California Privacy Protection Agency — cppa.ca.gov
- **Consumer rights** — working, verified paths to know, delete, correct, opt out of sale or sharing, and limit the
  use of sensitive personal information; response deadlines tracked with their source; deletion propagates to
  service providers.
  - Law/standard: CCPA/CPRA and CCPA Regulations
  - Verify at: California Privacy Protection Agency — cppa.ca.gov
- **Opt-out signals and links** — "Do Not Sell or Share My Personal Information" and "Limit the Use of My Sensitive
  Personal Information" links (or the permitted alternative), and Global Privacy Control browser signals honored as
  an opt-out.
  - Law/standard: CCPA/CPRA and CCPA Regulations
  - Verify at: California Privacy Protection Agency — cppa.ca.gov
- **Risk assessments, cybersecurity audits and automated decision-making technology** — whether the CPPA
  regulations on these topics apply to the business, and from when.
  - Law/standard: CCPA Regulations (California Privacy Protection Agency rulemaking)
  - Verify at: California Privacy Protection Agency — cppa.ca.gov
- **Other state privacy laws** — which other states' comprehensive consumer privacy laws the business meets the
  thresholds of, and their differences (opt-in for sensitive data, universal opt-out signals, data protection
  assessments).
  - Law/standard: state comprehensive consumer privacy laws (e.g. Virginia Consumer Data Protection Act, Colorado Privacy Act, Texas Data Privacy and Security Act)
  - Verify at: each state Attorney General's privacy page
- **Children (COPPA)** — whether the service is directed to children or has actual knowledge of collecting
  personal information from children below the statutory age; if so, verifiable parental consent, notices, data
  minimization and retention limits under the current rule.
  - Law/standard: Children's Online Privacy Protection Act (COPPA) and the FTC COPPA Rule (16 CFR Part 312)
  - Verify at: Federal Trade Commission — ftc.gov
- **Financial-data privacy (if a financial product)** — if the company offers a consumer financial product or
  service (savings, payments, lending), whether it is a financial institution under GLBA: privacy notices and
  sharing opt-outs.
  - Law/standard: Gramm-Leach-Bliley Act (GLBA) — Privacy Rule (Regulation P)
  - Verify at: Consumer Financial Protection Bureau — consumerfinance.gov; Federal Trade Commission — ftc.gov
- **Unfair or deceptive practices** — privacy and security statements in the product, policy and marketing match
  what the product does; no dark patterns in consent or cancellation flows.
  - Law/standard: Federal Trade Commission Act — Section 5
  - Verify at: Federal Trade Commission — ftc.gov
- **State breach-notification laws** — an incident runbook step that identifies, for a breach of personal
  information, the states of affected residents, whom to notify (individuals, state Attorneys General, consumer
  reporting agencies) and by when; each state's definitions and deadlines recorded with their source.
  - Law/standard: the data-breach notification statute of each affected resident's state
  - Verify at: each state Attorney General's data-breach page

## Security Certification

- **PCI DSS scope** — whether card data ever touches the product's systems; with hosted fields, redirects or the
  provider's SDK, confirm the reduced self-assessment type that applies and complete it annually; never store card
  numbers or security codes.
  - Law/standard: Payment Card Industry Data Security Standard (PCI DSS), current version, and its Self-Assessment Questionnaires
  - Verify at: PCI Security Standards Council — pcisecuritystandards.org; the acquiring bank or payment provider
- **FTC Safeguards Rule (if a financial product)** — a non-bank financial institution needs a written information
  security program (qualified individual, risk assessment, access controls, encryption, MFA, monitoring, incident
  response, and the notification duty the rule sets).
  - Law/standard: GLBA — FTC Standards for Safeguarding Customer Information (16 CFR Part 314)
  - Verify at: Federal Trade Commission — ftc.gov
- **State financial cybersecurity rules** — if the company holds a state financial licence (e.g. money
  transmission) in a state with its own cybersecurity regulation, such as New York's.
  - Law/standard: e.g. New York DFS Cybersecurity Regulation (23 NYCRR Part 500)
  - Verify at: New York State Department of Financial Services — dfs.ny.gov; the licensing state's regulator
- **Customer-requested assurance** — for B2B sales, which attestations customers expect (SOC 2 Type II is the
  usual one; ISO/IEC 27001 for international customers); these are contractual, not statutory.
  - Law/standard: AICPA SOC 2 (voluntary); ISO/IEC 27001 (voluntary)
  - Verify at: AICPA — aicpa-cima.com; the audit firm or certification body
- **Federal customers (B2G)** — if selling cloud services to federal agencies, the FedRAMP authorization path.
  - Law/standard: Federal Risk and Authorization Management Program (FedRAMP)
  - Verify at: FedRAMP — fedramp.gov

## Commerce & Payments

- **Automatic renewal and negative-option offers** — clear disclosure of renewal terms before purchase, express
  consent to the recurring charge, an acknowledgment that repeats the terms, and online cancellation that is as easy
  as sign-up; check each state's automatic renewal law (California's is the usual benchmark) and the current
  federal negative-option rules.
  - Law/standard: Restore Online Shoppers' Confidence Act (ROSCA); state automatic renewal laws (e.g. California Business and Professions Code §17600 et seq.)
  - Verify at: Federal Trade Commission — ftc.gov; California Attorney General — oag.ca.gov
- **Recurring bank debits** — auto-debits from a consumer's bank account have the written authorization, the notice
  of varying amounts and the stop-payment path the rules require, and the ACH origination rules are met through the
  payment provider.
  - Law/standard: Electronic Fund Transfer Act and Regulation E (12 CFR Part 1005); Nacha Operating Rules
  - Verify at: Consumer Financial Protection Bureau — consumerfinance.gov; Nacha — nacha.org
- **Holding or moving customer funds** — where users' money sits at every step; holding or transmitting funds on
  users' behalf may require state money-transmitter licences or a bank partner, and a federal registration.
  - Law/standard: state money transmission laws; Bank Secrecy Act — FinCEN money services business registration
  - Verify at: NMLS — nmlsconsumeraccess.org; Financial Crimes Enforcement Network — fincen.gov
- **Sales tax on software and digital services** — whether the service is taxable in each state where the company
  has economic nexus, and whether the payment provider or app store collects it.
  - Law/standard: state sales and use tax laws (post-*South Dakota v. Wayfair* economic nexus rules)
  - Verify at: each state's Department of Revenue; the Streamlined Sales Tax Governing Board — streamlinedsalestax.org
- **Advertising and endorsements** — pricing claims, "free" offers, reviews and influencer endorsements are
  truthful and disclosed.
  - Law/standard: Federal Trade Commission Act — Section 5; FTC Guides Concerning the Use of Endorsements and Testimonials (16 CFR Part 255); FTC rule on consumer reviews and testimonials (16 CFR Part 465)
  - Verify at: Federal Trade Commission — ftc.gov

## Marketing Messages & Consent

- **Commercial email (CAN-SPAM)** — accurate header and subject lines, identification as an advertisement where
  required, the sender's valid physical postal address, a working opt-out honored within the statutory period, and
  opt-outs propagated to every sending tool; transactional messages (receipts, security alerts) kept free of
  promotional content that would make them commercial.
  - Law/standard: Controlling the Assault of Non-Solicited Pornography And Marketing Act (CAN-SPAM Act) and the FTC CAN-SPAM Rule (16 CFR Part 316)
  - Verify at: Federal Trade Commission — ftc.gov
- **SMS and text marketing (TCPA)** — marketing texts sent with an automated system require prior express written
  consent that is not a condition of purchase; consent revocation "by any reasonable means" is honored across
  channels; quiet hours and the National Do Not Call Registry rules are applied; consent records are kept.
  - Law/standard: Telephone Consumer Protection Act (TCPA) and FCC rules (47 CFR 64.1200); state telemarketing laws (e.g. Florida Telephone Solicitation Act)
  - Verify at: Federal Communications Commission — fcc.gov; Federal Trade Commission, National Do Not Call Registry — ftc.gov
- **Informational vs marketing texts** — one-time passcodes, auto-debit results and security alerts are
  informational; any promotional content turns a message into marketing and needs marketing consent.
  - Law/standard: TCPA and FCC rules
  - Verify at: Federal Communications Commission — fcc.gov
- **Push notifications** — promotional push goes only to users who opted in to promotions, separately from the OS
  notification permission, with an in-app way to turn it off.
  - Law/standard: none statutory — Apple App Store Review Guidelines and Google Play policy on notifications; FTC Act Section 5 for deceptive content
  - Verify at: Apple Developer — developer.apple.com; Google Play Console Help — support.google.com/googleplay/android-developer

## Accessibility

- **ADA Title III exposure** — whether the web and mobile surfaces are accessible to people with disabilities as a
  place of public accommodation is assessed; WCAG conformance at the level in `accessibility.target` is the
  benchmark courts and settlements commonly use; an accessibility statement and a way to report barriers exist.
  - Law/standard: Americans with Disabilities Act (ADA) — Title III; U.S. Department of Justice web accessibility guidance
  - Verify at: U.S. Department of Justice — ada.gov
- **State civil-rights claims** — state laws that allow disability-access claims against online businesses
  (e.g. California's).
  - Law/standard: e.g. California Unruh Civil Rights Act
  - Verify at: California Civil Rights Department — calcivilrights.ca.gov
- **Public-sector customers (B2G)** — Section 508 for products sold to federal agencies (an Accessibility
  Conformance Report on the VPAT template), and the ADA Title II web and mobile accessibility rule for products
  deployed by state and local governments.
  - Law/standard: Section 508 of the Rehabilitation Act (Revised 508 Standards, 36 CFR Part 1194); ADA Title II regulation on web and mobile accessibility (28 CFR Part 35)
  - Verify at: U.S. Access Board — access-board.gov; GSA — section508.gov; U.S. Department of Justice — ada.gov

## Integration Notes

These are not legal requirements; they are integration facts that routinely block US launches. Check each
provider's current documentation.

- **Card payments without card data** — the payment provider's hosted checkout, hosted fields or native SDK keep
  card numbers out of the product's servers and logs, which keeps the PCI DSS scope at the reduced level; webhooks
  are verified and idempotent.
  - Law/standard: none — payment provider documentation (the standard itself is under Security Certification)
  - Verify at: the payment provider's developer documentation
- **A2P SMS registration** — business SMS on US long codes is registered (brand and campaign, 10DLC) through the SMS
  provider; toll-free numbers are verified; carriers filter unregistered traffic.
  - Law/standard: none statutory — carrier requirements and CTIA Messaging Principles and Best Practices
  - Verify at: CTIA — ctia.org; the SMS provider's documentation
- **Email sender authentication** — SPF, DKIM and DMARC are configured for every sending domain and bulk-sender
  requirements of the major mailbox providers (including one-click unsubscribe headers) are met.
  - Law/standard: none — mailbox-provider sender guidelines
  - Verify at: Google Workspace Admin Help (email sender guidelines) — support.google.com; Yahoo Sender Hub — senders.yahooinc.com
- **Consent and opt-out tooling** — the consent manager honors Global Privacy Control, suppresses sale or sharing
  of personal information by advertising SDKs for opted-out users, and the mobile SDK configuration matches the
  App Store privacy details and Google Play Data safety answers.
  - Law/standard: none — vendor documentation (the obligations are under Privacy & Data Protection)
  - Verify at: Global Privacy Control — globalprivacycontrol.org; the consent vendor's documentation
