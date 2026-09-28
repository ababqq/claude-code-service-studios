# Regional Compliance Checklist — European Union (`eu`)

> **Loaded only when** `compliance.regions` in `project.yaml` contains `eu`. Skills never read this file for a
> project whose regions are unset (they ask first) or explicitly `[]` (they skip regional items and say so).
>
> **What this is**: a topic checklist of what to verify before building, auditing or launching a service for users
> in the EU/EEA. **What this is not**: legal advice, a complete statement of the law, or a source of numbers.
>
> **Rules for every skill and agent that uses it**
> - Each item names its `Law/standard:` (official name) and where to `Verify at:` (the official body or the
>   official law database). EU law is applied through national authorities and, for directives, national laws —
>   confirm the rules of each member state the product targets.
> - This file states no deadlines, fines, age limits, size thresholds, application dates or retention periods.
>   When an artifact needs one, the skill writes it with `(Source: <url>, retrieved YYYY-MM-DD)` at run time, or
>   writes `NOT SOURCEABLE — confirm with counsel`. A number without a source line is a defect.
> - Coverage is derived, not chosen: a skill that loads this file lists **every** item of the sections it uses and
>   gives each one the status vocabulary that skill defines (for example `/security-audit` uses
>   `Met | Gap | Accepted | N/A | NOT ASSESSED`). An item is `N/A` only with a one-line reason
>   (e.g. "no marketplace or user-generated content"); an item nobody could check is `NOT ASSESSED`, never `Met`.
> - Items are not advice to act on without review: a `Gap` is resolved by the product team with counsel, or
>   explicitly accepted by a named owner with the date and reason recorded in the artifact.
> - Legal texts: EUR-Lex, eur-lex.europa.eu.

## Privacy & Data Protection

- **Lawful basis per processing purpose** — every purpose in the record of processing has one lawful basis
  (consent, contract, legal obligation, vital interests, public task or legitimate interests with a documented
  balancing test); special-category data has an additional condition; the basis is not switched after the fact.
  - Law/standard: General Data Protection Regulation (Regulation (EU) 2016/679, GDPR) — Articles 6 and 9
  - Verify at: European Data Protection Board (EDPB) — edpb.europa.eu; the lead supervisory authority
- **Consent quality** — where consent is the basis: freely given, specific, informed, unambiguous, as easy to
  withdraw as to give, not bundled with the terms, and recorded (who, when, what text, which channel).
  - Law/standard: GDPR — Articles 4(11) and 7; EDPB Guidelines on consent
  - Verify at: EDPB — edpb.europa.eu
- **Children** — whether children may use the service; the member-state age for a child's own consent to
  information-society services, parental consent and age-appropriate notices where it applies.
  - Law/standard: GDPR — Article 8, as set by each member state
  - Verify at: EDPB — edpb.europa.eu; the national supervisory authority of each target member state
- **Transparency** — a privacy notice with the information the GDPR requires (controller identity, purposes and
  bases, recipients, transfers, retention, rights, complaint route), shown at collection, in plain language and in
  the locales the product ships in.
  - Law/standard: GDPR — Articles 12 to 14
  - Verify at: EDPB — edpb.europa.eu
- **Data subject rights (DSR)** — working, identity-checked paths for access, rectification, erasure, restriction,
  portability and objection, including in-app account deletion; the response deadline is tracked with its source;
  erasure reaches backups, analytics and processors on a documented schedule.
  - Law/standard: GDPR — Articles 15 to 21
  - Verify at: EDPB — edpb.europa.eu
- **Automated decisions and AI features** — whether any decision with legal or similarly significant effect is
  fully automated (e.g. eligibility, credit, fraud blocking) and how human review and explanation are offered;
  whether model-backed features (chatbots, generated content) carry the transparency duties of the AI Act that
  apply to them.
  - Law/standard: GDPR — Article 22; Artificial Intelligence Act (Regulation (EU) 2024/1689)
  - Verify at: EDPB — edpb.europa.eu; European Commission AI Office — digital-strategy.ec.europa.eu
- **DPIA** — a data protection impact assessment exists for processing likely to result in high risk (large-scale
  profiling, special-category data, systematic monitoring, new technology such as biometrics or AI scoring), with
  the national supervisory authority's list checked.
  - Law/standard: GDPR — Article 35; national DPIA lists
  - Verify at: EDPB — edpb.europa.eu; the national supervisory authority
- **Records, DPO and EU representative** — a record of processing activities; a data protection officer where
  required; an EU representative where the controller has no EU establishment but targets EU users (typical for a
  Korean or US startup entering the EU).
  - Law/standard: GDPR — Articles 27, 30 and 37
  - Verify at: EDPB — edpb.europa.eu
- **Processors** — a data processing agreement with every processor (cloud, email, SMS, analytics, support desk,
  crash reporting) and a sub-processor list the product can show to business customers.
  - Law/standard: GDPR — Article 28
  - Verify at: EDPB — edpb.europa.eu
- **International transfers** — every transfer of personal data outside the EEA (hosting region, SaaS tools,
  support teams, the parent company) relies on an adequacy decision, standard contractual clauses with a transfer
  impact assessment, or another Chapter V mechanism; check the current adequacy list and the status of the EU-U.S.
  Data Privacy Framework rather than assuming either.
  - Law/standard: GDPR — Chapter V (Articles 44 to 50)
  - Verify at: European Commission, adequacy decisions — commission.europa.eu; EDPB — edpb.europa.eu
- **Security of processing and privacy by design** — encryption, access control, pseudonymization where it fits,
  and data-protection defaults (minimal collection, most private settings on by default) documented against the
  threat model.
  - Law/standard: GDPR — Articles 25 and 32
  - Verify at: EDPB — edpb.europa.eu
- **Personal-data breach notification** — an incident runbook step that decides whether a breach is notified to
  the supervisory authority and to affected users, within the deadline recorded with its source, and keeps an
  internal breach register.
  - Law/standard: GDPR — Articles 33 and 34
  - Verify at: EDPB Guidelines on personal data breach notification — edpb.europa.eu; the lead supervisory authority

## Security Certification

- **NIS2 scope** — whether the company is an essential or important entity under the national law implementing
  NIS2 (by sector, e.g. digital infrastructure, ICT service management, digital providers, banking), and if so the
  risk-management, registration and incident-reporting duties.
  - Law/standard: Directive (EU) 2022/2555 (NIS2) and its national transpositions
  - Verify at: European Union Agency for Cybersecurity (ENISA) — enisa.europa.eu; the national competent authority
- **Financial-sector ICT rules** — if the product is a financial entity or an ICT third-party provider to one,
  the digital operational resilience duties (ICT risk management, incident reporting, testing, contract terms).
  - Law/standard: Digital Operational Resilience Act (Regulation (EU) 2022/2554, DORA)
  - Verify at: European Supervisory Authorities (EBA, EIOPA, ESMA) — eba.europa.eu; the national financial supervisor
- **Products with digital elements** — whether any software the company places on the market as a product
  (e.g. a downloadable SDK or an app sold as a product) falls under the Cyber Resilience Act, and which of its
  obligations apply by when.
  - Law/standard: Cyber Resilience Act (Regulation (EU) 2024/2847)
  - Verify at: European Commission — digital-strategy.ec.europa.eu; ENISA — enisa.europa.eu
- **Customer-requested assurance** — for B2B sales, which certifications customers expect (ISO/IEC 27001 is the
  common one in the EU; cloud-specific schemes where relevant); these are contractual, not statutory.
  - Law/standard: ISO/IEC 27001 (voluntary)
  - Verify at: ISO — iso.org; the accredited certification body

## Commerce & Payments

- **Pre-contract information and the right of withdrawal** — for consumer sales at a distance: price including
  taxes, billing cycle, duration and renewal terms shown before purchase; the withdrawal right for services and
  digital content and the conditions under which it is lost; the withdrawal function on the online interface for
  contracts concluded online (check its current requirements and application date).
  - Law/standard: Consumer Rights Directive (Directive 2011/83/EU, as amended by Directives (EU) 2019/2161 and (EU) 2023/2673) and national transpositions
  - Verify at: European Commission, consumer protection law — commission.europa.eu; the national consumer authority
- **Digital services conformity** — the service matches its description and receives the updates needed to stay
  conformant; remedies when it does not.
  - Law/standard: Digital Content and Digital Services Directive (Directive (EU) 2019/770)
  - Verify at: European Commission — commission.europa.eu
- **Unfair practices and price presentation** — no misleading urgency, hidden costs, pre-ticked extras or fake
  reviews; price-reduction announcements follow the price-indication rules; subscription cancellation is not made
  harder than sign-up.
  - Law/standard: Unfair Commercial Practices Directive (Directive 2005/29/EC); Price Indication Directive (Directive 98/6/EC), as amended by Directive (EU) 2019/2161
  - Verify at: European Commission — commission.europa.eu; the national consumer authority
- **Strong customer authentication** — card and account payments by EEA users go through a payment provider that
  applies strong customer authentication (e.g. 3-D Secure) with the exemptions it manages; recurring charges are
  set up as merchant-initiated transactions after an authenticated first payment.
  - Law/standard: Payment Services Directive (Directive (EU) 2015/2366, PSD2) and its regulatory technical standards on SCA — check the status of their successor legislation
  - Verify at: European Banking Authority (EBA) — eba.europa.eu; the payment provider's documentation
- **VAT on digital services** — VAT is charged at the rate of the customer's member state for B2C digital
  services, and the company registers for the One-Stop Shop or through the platform that sells on its behalf.
  - Law/standard: Council Directive 2006/112/EC (VAT Directive) — e-commerce and One-Stop Shop (OSS) rules
  - Verify at: European Commission, VAT e-commerce — taxation-customs.ec.europa.eu
- **Online platform duties (DSA), where applicable** — if the service hosts user content, connects users with each
  other or is a marketplace: notice-and-action, statements of reasons, points of contact, terms-of-service
  transparency, trader traceability (marketplaces), advertising transparency and the ban on deceptive interface
  design for online platforms; micro and small enterprise exemptions checked with their source.
  - Law/standard: Digital Services Act (Regulation (EU) 2022/2065, DSA)
  - Verify at: European Commission — digital-strategy.ec.europa.eu; the national Digital Services Coordinator

## Marketing Messages & Consent

- **Consent for electronic marketing messages** — marketing by email, SMS, messaging apps and push to individuals
  requires prior opt-in consent; the existing-customer exception ("soft opt-in") applies only for similar products,
  with an opt-out offered at collection and in every message; national rules for business recipients differ.
  - Law/standard: ePrivacy Directive (Directive 2002/58/EC) — Article 13, and national transpositions
  - Verify at: EDPB — edpb.europa.eu; the national authority enforcing the ePrivacy rules in each target member state
- **Cookie and device-storage consent** — non-essential cookies, local storage, SDKs and device identifiers
  (analytics, advertising, session replay, attribution) run only after consent; strictly necessary storage is
  documented; reject is as easy as accept on the first layer; consent is recorded and can be changed later.
  - Law/standard: ePrivacy Directive (Directive 2002/58/EC) — Article 5(3); GDPR consent conditions; national supervisory authority guidance on cookies
  - Verify at: EDPB — edpb.europa.eu; the national supervisory authority (e.g. the published cookie guidance of the authority for each target market)
- **Identification and unsubscribe in every message** — the sender is identifiable, the message is recognizable as
  commercial, and a free, one-step unsubscribe works in the same channel; unsubscribes propagate to every sending
  tool.
  - Law/standard: ePrivacy Directive (Directive 2002/58/EC) — Article 13; Directive 2000/31/EC (e-Commerce Directive) — commercial communications
  - Verify at: EDPB — edpb.europa.eu; European Commission — commission.europa.eu
- **Profiling for marketing** — segmentation and personalization based on personal data have a lawful basis, and
  users can object to direct-marketing profiling at any time.
  - Law/standard: GDPR — Articles 21 and 22
  - Verify at: EDPB — edpb.europa.eu

## Accessibility

- **European Accessibility Act scope** — whether the service is in scope (e.g. e-commerce services, consumer
  banking services, e-books, electronic communications) and whether the microenterprise exemption for services
  applies; the application date and exemption thresholds are recorded with their source.
  - Law/standard: European Accessibility Act (Directive (EU) 2019/882) and national transpositions
  - Verify at: European Commission — commission.europa.eu; the national market surveillance authority
- **Technical conformance** — web and mobile surfaces meet the harmonised standard referenced for the Act, and
  `accessibility.target` and `design/accessibility-requirements.md` record which WCAG level and standard edition
  the product conforms to.
  - Law/standard: EN 301 549 (harmonised standard for ICT accessibility, which references WCAG)
  - Verify at: ETSI — etsi.org; European Commission — commission.europa.eu
- **Accessibility information** — the service publishes how it meets the accessibility requirements (in the
  terms or an accessibility statement), in accessible form, and offers a way to report barriers.
  - Law/standard: European Accessibility Act (Directive (EU) 2019/882) — information on services
  - Verify at: the national market surveillance authority
- **Public-sector customers (B2G)** — if public bodies deploy the product to the public, the public-sector web
  accessibility duties they will pass on contractually.
  - Law/standard: Web Accessibility Directive (Directive (EU) 2016/2102)
  - Verify at: European Commission — digital-strategy.ec.europa.eu

## Integration Notes

These are not legal requirements; they are integration facts that routinely block EU launches. Check each
provider's current documentation.

- **Consent management platform** — the CMP blocks tags and SDKs until consent, passes consent state to analytics
  and advertising vendors (including Google's consent mode where Google tags are used, and the IAB TCF framework
  where the ad stack requires it), and logs consent records.
  - Law/standard: none — vendor frameworks (IAB Europe Transparency & Consent Framework; Google consent mode)
  - Verify at: IAB Europe — iabeurope.eu; Google Developers — developers.google.com
- **Hosting region and data residency** — which cloud regions hold EU users' data, whether any support or
  monitoring tool processes it outside the EEA, and whether enterprise customers require EU-only residency.
  - Law/standard: none — contractual; transfers themselves are covered under Privacy & Data Protection
  - Verify at: the cloud provider's region and data-processing documentation
- **Payment provider SCA handling** — the payment SDK handles 3-D Secure challenges in web and native flows,
  saved cards are set up for merchant-initiated renewals, and failed authentication has a recovery path.
  - Law/standard: none — payment provider documentation
  - Verify at: the payment provider's developer documentation
- **App-store options in the EU** — whether to use the alternative distribution or payment options the app
  stores offer in the EU under the Digital Markets Act, and the terms each store attaches.
  - Law/standard: Digital Markets Act (Regulation (EU) 2022/1925) — obligations fall on gatekeepers; developers opt in through store terms
  - Verify at: Apple Developer — developer.apple.com; Google Play Console Help — support.google.com/googleplay/android-developer
- **VAT collection** — whether the payment provider or app store acts as the seller of record and collects VAT,
  or the company collects and files it through the One-Stop Shop.
  - Law/standard: none — provider terms (the tax rules themselves are under Commerce & Payments)
  - Verify at: the payment provider's or store's tax documentation
