# Regional Compliance Checklist — Korea (`kr`)

> **Loaded only when** `compliance.regions` in `project.yaml` contains `kr`. Skills never read this file for a
> project whose regions are unset (they ask first) or explicitly `[]` (they skip regional items and say so).
>
> **What this is**: a topic checklist of what to verify before building, auditing or launching a service for users
> in Korea. **What this is not**: legal advice, a complete statement of the law, or a source of numbers.
>
> **Rules for every skill and agent that uses it**
> - Each item names its `Law/standard:` (official English name, Korean name in parentheses) and where to
>   `Verify at:` (the official body or the official statute database). Confirm the current text there — Korean
>   privacy, e-commerce and messaging rules are amended often.
> - This file states no deadlines, fines, age limits, revenue or user-count thresholds, retention periods or
>   hours. When an artifact needs one, the skill writes it with `(Source: <url>, retrieved YYYY-MM-DD)` at run
>   time, or writes `NOT SOURCEABLE — confirm with counsel`. A number without a source line is a defect.
> - Coverage is derived, not chosen: a skill that loads this file lists **every** item of the sections it uses and
>   gives each one the status vocabulary that skill defines (for example `/security-audit` uses
>   `Met | Gap | Accepted | N/A | NOT ASSESSED`). An item is `N/A` only with a one-line reason
>   (e.g. "no location data collected"); an item nobody could check is `NOT ASSESSED`, never `Met`.
> - Items are not advice to act on without review: a `Gap` is resolved by the product team with counsel, or
>   explicitly accepted by a named owner with the date and reason recorded in the artifact.
> - Statute texts: Korea Law Information Center (국가법령정보센터), law.go.kr.

## Privacy & Data Protection

- **Lawful basis for each processing purpose** — every purpose in the privacy policy maps to a basis the Act lists
  (consent, necessity for a contract with the user, legal obligation, or another listed basis); check whether consent
  is being asked for processing that another basis already covers, and that required and optional consent items are
  separated on screen.
  - Law/standard: Personal Information Protection Act (개인정보 보호법)
  - Verify at: Personal Information Protection Commission (개인정보보호위원회, PIPC) — pipc.go.kr; statute at law.go.kr
- **Consent presentation and records** — each consent names purpose, items collected, retention period and the
  right to refuse (with the consequence of refusing); consents are separable, not bundled with terms of service;
  the service stores which consent text version was accepted, when and through which channel.
  - Law/standard: Personal Information Protection Act (개인정보 보호법); PIPC guidance on consent
  - Verify at: PIPC — pipc.go.kr
- **Purpose limitation and minimization** — every collected field is needed for a stated purpose; new uses of
  existing data are checked against the original purpose or get a new basis; optional fields are not required to
  complete sign-up.
  - Law/standard: Personal Information Protection Act (개인정보 보호법)
  - Verify at: PIPC — pipc.go.kr
- **Resident registration numbers, unique identifiers and sensitive information** — resident registration numbers
  (주민등록번호) are not collected unless a statute explicitly requires or permits it; other unique identifiers
  (고유식별정보) and sensitive information (민감정보, e.g. health) have their own basis, separate consent where
  required, and encryption.
  - Law/standard: Personal Information Protection Act (개인정보 보호법) — restrictions on processing resident registration numbers, unique identifiers and sensitive information
  - Verify at: PIPC — pipc.go.kr
- **Children** — whether users below the statutory age may sign up; if so, verified consent of a legal
  representative (법정대리인 동의) and child-appropriate notices; if not, how age is checked at sign-up.
  - Law/standard: Personal Information Protection Act (개인정보 보호법) — processing of children's personal information
  - Verify at: PIPC — pipc.go.kr
- **Privacy policy (개인정보 처리방침)** — published, reachable from every sign-up and settings screen and the store
  listing, and consistent with what the product actually collects (including SDKs, analytics and crash reporting);
  names the privacy officer (개인정보 보호책임자) and how users exercise their rights.
  - Law/standard: Personal Information Protection Act (개인정보 보호법); PIPC privacy-policy drafting guideline (개인정보 처리방침 작성지침)
  - Verify at: PIPC — pipc.go.kr
- **Retention and destruction (보유 기간과 파기)** — a retention period per data set, destruction on expiry or
  account deletion that reaches replicas, backups, analytics and processors, and a documented exception list for
  records other laws require keeping (e.g. e-commerce transaction records) with their sources.
  - Law/standard: Personal Information Protection Act (개인정보 보호법); record-keeping duties under the Act on the Consumer Protection in Electronic Commerce (전자상거래 등에서의 소비자보호에 관한 법률)
  - Verify at: PIPC — pipc.go.kr; Korea Fair Trade Commission (공정거래위원회) — ftc.go.kr
- **Pseudonymization (가명처리)** — analytics, statistics and model training on personal data use pseudonymized data
  where the Act allows it, with re-identification risk controls, separation of additional information and records
  of pseudonymized processing.
  - Law/standard: Personal Information Protection Act (개인정보 보호법) — special provisions on pseudonymized information; PIPC pseudonymization guideline (가명정보 처리 가이드라인)
  - Verify at: PIPC — pipc.go.kr
- **Processing entrustment and third-party provision** — every processor (cloud, 알림톡/SMS vendor, email, support
  desk, analytics) is disclosed as entrustment (처리위탁) with a written contract; any provision to a third party for
  its own purposes (제3자 제공) has its own basis and separate disclosure.
  - Law/standard: Personal Information Protection Act (개인정보 보호법)
  - Verify at: PIPC — pipc.go.kr
- **Cross-border transfer (국외 이전)** — every destination country, recipient, data items, purpose and retention
  of personal data processed or stored outside Korea (cloud regions, SaaS tools, overseas support) is identified
  and has a basis the Act recognizes, and the privacy policy discloses it.
  - Law/standard: Personal Information Protection Act (개인정보 보호법) — cross-border transfer provisions
  - Verify at: PIPC — pipc.go.kr
- **Data subject rights** — working paths for access, correction, deletion, suspension of processing, withdrawal
  of consent and account deletion, with response time tracked against the statutory period; rights concerning
  fully automated decisions if the product makes them (e.g. automated credit or eligibility decisions).
  - Law/standard: Personal Information Protection Act (개인정보 보호법) — rights of data subjects, including rights concerning automated decisions
  - Verify at: PIPC — pipc.go.kr
- **Technical and administrative safeguards** — access control and least privilege, access-log retention and
  review, encryption of passwords, unique identifiers and other data the standard names, internal management plan
  (내부 관리계획), and protection of admin consoles.
  - Law/standard: Standards for Ensuring the Safety of Personal Information (개인정보의 안전성 확보조치 기준, PIPC notice)
  - Verify at: PIPC — pipc.go.kr
- **Location data** — whether the product collects location information (GPS, precise location, geofencing);
  if so, consent specific to location, business reporting or registration for location-based services, records of
  use and provision, and notices to users.
  - Law/standard: Act on the Protection, Use, etc. of Location Information (위치정보의 보호 및 이용 등에 관한 법률, 위치정보법)
  - Verify at: statute and competent authority at law.go.kr; Korea Internet & Security Agency (한국인터넷진흥원, KISA) — kisa.or.kr
- **Personal-data breach notification (유출 통지·신고)** — an incident runbook step that decides, for a leak of
  personal information, who must be notified (affected users, PIPC or KISA) and by when, with the notice content
  the Act requires; the deadline and thresholds are recorded with their source.
  - Law/standard: Personal Information Protection Act (개인정보 보호법) — notification and reporting of personal-information leaks
  - Verify at: PIPC — pipc.go.kr; KISA — kisa.or.kr
- **Security-incident reporting (침해사고 신고)** — whether an intrusion or service-disrupting attack must be reported
  as a security incident, separately from any personal-data breach notice, and to whom.
  - Law/standard: Act on Promotion of Information and Communications Network Utilization and Information Protection (정보통신망 이용촉진 및 정보보호 등에 관한 법률, 정보통신망법)
  - Verify at: KISA — kisa.or.kr (boho.or.kr for incident reporting)

## Security Certification

- **ISMS-P applicability** — whether the service is subject to mandatory information-security management system
  certification (ISMS) under the criteria in force, and whether ISMS-P (including the personal-information part)
  is expected by partners (banks, PGs, enterprise customers); if mandatory, the certification timeline is part of
  the launch plan.
  - Law/standard: Information Security and Personal Information Protection Management System (정보보호 및 개인정보보호 관리체계, ISMS-P); mandatory ISMS under the Network Act (정보통신망법)
  - Verify at: KISA ISMS-P — isms.kisa.or.kr; PIPC — pipc.go.kr
- **Electronic financial supervision** — if the company itself is an electronic financial business or a partner
  bank or PG requires it, the security requirements that follow (e.g. network separation, vulnerability
  assessments, outsourcing and cloud-use reporting).
  - Law/standard: Electronic Financial Transactions Act (전자금융거래법); Regulation on Supervision of Electronic Financial Transactions (전자금융감독규정)
  - Verify at: Financial Services Commission (금융위원회) — fsc.go.kr; Financial Supervisory Service (금융감독원) — fss.or.kr
- **Public-sector customers (B2G)** — if the product is sold to public institutions as cloud software, whether a
  cloud security assurance certification is required before contracting.
  - Law/standard: Cloud Security Assurance Program (클라우드 보안인증, CSAP)
  - Verify at: KISA — kisa.or.kr

## Commerce & Payments

- **Business identity disclosure** — the site and app show the operator's business name, representative,
  address, phone, email, business registration number (사업자등록번호) and mail-order business report number
  (통신판매업 신고번호), and the service has filed the mail-order business report with the local government where
  required.
  - Law/standard: Act on the Consumer Protection in Electronic Commerce (전자상거래 등에서의 소비자보호에 관한 법률, 전자상거래법)
  - Verify at: Korea Fair Trade Commission (공정거래위원회) — ftc.go.kr
- **Pre-purchase information and cancellation/refund (청약철회)** — price, billing cycle, cancellation and refund
  terms are shown before payment; the withdrawal period, its exceptions (e.g. digital content already used) and
  refund handling match the statute; cancellation is possible through the same channel as sign-up.
  - Law/standard: Act on the Consumer Protection in Electronic Commerce (전자상거래법)
  - Verify at: Korea Fair Trade Commission (공정거래위원회) — ftc.go.kr
- **Subscriptions and dark patterns** — recurring payments: consent to renewal, notice before a free trial converts
  to paid or before a price increase, no hidden or pre-ticked renewals, and a cancellation flow no harder than
  sign-up; check the current dark-pattern provisions for online commerce.
  - Law/standard: Act on the Consumer Protection in Electronic Commerce (전자상거래법) — provisions on deceptive online interface design (온라인 다크패턴)
  - Verify at: Korea Fair Trade Commission (공정거래위원회) — ftc.go.kr
- **Payment gateway and auto-debit flows** — card and bank payments go through a registered PG (e.g. Toss
  Payments) so the PG holds the electronic-payment registration; auto-debit (자동결제·정기결제 or account
  withdrawal) has the user's recorded debit authorization, a visible schedule, and a way to stop it.
  - Law/standard: Electronic Financial Transactions Act (전자금융거래법)
  - Verify at: Financial Services Commission (금융위원회) — fsc.go.kr; Financial Supervisory Service (금융감독원) — fss.or.kr
- **Points, credits and stored value** — whether in-app points, credits, balances or gift value are prepaid
  electronic payment means (선불전자지급수단) that require registration, safeguarding of user funds, or refund of
  the remaining balance; the exemption conditions are recorded with their source.
  - Law/standard: Electronic Financial Transactions Act (전자금융거래법) — prepaid electronic payment means
  - Verify at: Financial Services Commission (금융위원회) — fsc.go.kr; Financial Supervisory Service (금융감독원) — fss.or.kr
- **Holding or moving customer funds** — where users' money sits at every step (the user's own bank account, a
  partner bank or trust account, the PG, or the company's account); holding or pooling customer funds, or
  presenting a financial product, may require a licence or a partner institution.
  - Law/standard: Electronic Financial Transactions Act (전자금융거래법); Financial Consumer Protection Act (금융소비자 보호에 관한 법률) where financial products are advertised or intermediated
  - Verify at: Financial Services Commission (금융위원회) — fsc.go.kr; Financial Supervisory Service (금융감독원) — fss.or.kr
- **In-app payments for digital goods** — which billing path each app uses for subscriptions and digital goods
  (the store's in-app purchase, or an alternative payment option the store offers in Korea) and the entitlement,
  commission and disclosure conditions each store attaches; physical goods and services and money movement use
  the PG, not store billing.
  - Law/standard: Telecommunications Business Act (전기통신사업법) — app-market payment provisions; Apple App Store Review Guidelines and Google Play Payments policy
  - Verify at: statute at law.go.kr; Apple Developer (developer.apple.com); Google Play Console Help (support.google.com/googleplay/android-developer)
- **Tax receipts** — VAT treatment of the service and the receipts it issues (cash receipts 현금영수증 for
  consumers, electronic tax invoices 전자세금계산서 for business customers), usually through the PG.
  - Law/standard: Value-Added Tax Act (부가가치세법)
  - Verify at: National Tax Service (국세청) — nts.go.kr

## Marketing Messages & Consent

- **Prior opt-in for advertising messages (광고성 정보 전송)** — advertising sent by SMS, MMS, email, app push,
  KakaoTalk or any electronic channel requires the recipient's prior consent, collected separately from terms of
  service and required consents; check the narrow existing-transaction exception and its conditions before relying
  on it.
  - Law/standard: Network Act (정보통신망 이용촉진 및 정보보호 등에 관한 법률) — transmission of advertising information
  - Verify at: KISA illegal-spam response center (불법스팸대응센터) — spam.kisa.or.kr (Network Act advertising guide 불법 스팸 방지를 위한 정보통신망법 안내서); statute at law.go.kr
- **Separate consent for night-time sending** — advertising sent during the statutory night-time window needs its
  own consent in addition to the general marketing consent; the scheduler enforces the window in KST.
  - Law/standard: Network Act (정보통신망법) — night-time advertising transmission
  - Verify at: KISA — spam.kisa.or.kr
- **Periodic confirmation of consent** — recipients are reminded of their marketing consent at the statutory
  interval, and the result of every consent or withdrawal is notified to the user.
  - Law/standard: Network Act (정보통신망법) — confirmation of consent to receive advertising
  - Verify at: KISA — spam.kisa.or.kr
- **Message labelling and unsubscribe path** — advertising messages are marked as advertising in the required form,
  identify the sender and contact details, and carry a free, working unsubscribe or withdrawal method in the same
  channel; withdrawal takes effect without extra steps.
  - Law/standard: Network Act (정보통신망법) — indications required in advertising information
  - Verify at: KISA — spam.kisa.or.kr
- **App push advertising** — push used for advertising has both the OS notification permission and the
  advertising-message consent, and the in-app settings let users turn advertising push off separately from
  service notifications.
  - Law/standard: Network Act (정보통신망법); Apple App Store Review Guidelines and Google Play policy on notifications
  - Verify at: KISA — spam.kisa.or.kr; Apple Developer; Google Play Console Help
- **KakaoTalk 알림톡 is informational only** — 알림톡 carries informational (정보성) messages about a user's own
  transactions or account (e.g. auto-debit result, goal reached, security alerts); any advertising content goes
  through 친구톡 or brand messages, only to users with advertising consent and with the labelling above.
  - Law/standard: Kakao Business messaging policies; Network Act (정보통신망법) for advertising content
  - Verify at: Kakao Business — business.kakao.com; the official dealer (공식 딜러사) contracted to send
- **SMS sender-number registration** — every SMS sender number is pre-registered and verified with the messaging
  provider (발신번호 사전등록), and SMS fallback for 알림톡 follows the same content rules.
  - Law/standard: Telecommunications Business Act (전기통신사업법) — prevention of caller-number spoofing
  - Verify at: statute at law.go.kr; KISA — kisa.or.kr
- **Personal data used for marketing** — using personal information for marketing (targeting, profiling,
  third-party marketing) has its own optional consent under the privacy law, distinct from the consent to receive
  advertising messages.
  - Law/standard: Personal Information Protection Act (개인정보 보호법)
  - Verify at: PIPC — pipc.go.kr

## Accessibility

- **Duty to provide accessible services** — whether the operator is subject to the duty to provide reasonable
  accommodation (정당한 편의 제공) for its website and mobile apps, and how accessibility complaints are handled.
  - Law/standard: Act on the Prohibition of Discrimination against Persons with Disabilities, Remedy against Infringement of their Rights, etc. (장애인차별금지 및 권리구제 등에 관한 법률, 장애인차별금지법)
  - Verify at: statute at law.go.kr; National Human Rights Commission of Korea (국가인권위원회) — humanrights.go.kr
- **Web content: KWCAG 2.2** — the web surfaces meet the Korean Web Content Accessibility Guidelines 2.2 (한국형
  웹 콘텐츠 접근성 지침 2.2); `accessibility.target` and `design/accessibility-requirements.md` record how the WCAG
  2.2 level chosen maps to KWCAG items; decide whether to obtain a web accessibility quality certification
  (웹 접근성 품질인증).
  - Law/standard: Korean Web Content Accessibility Guidelines 2.2 (한국형 웹 콘텐츠 접근성 지침 2.2, national standard)
  - Verify at: National Information Society Agency (한국지능정보사회진흥원, NIA) — nia.or.kr; Ministry of Science and ICT (과학기술정보통신부) — msit.go.kr
- **Mobile apps** — iOS and Android apps meet the national mobile application accessibility guideline (screen
  reader labels, focus order, text scaling, contrast, alternatives to gestures).
  - Law/standard: Mobile Application Content Accessibility Guidelines (모바일 애플리케이션 콘텐츠 접근성 지침, national guideline)
  - Verify at: National Information Society Agency (한국지능정보사회진흥원, NIA) — nia.or.kr

## Integration Notes

These are not legal requirements; they are integration facts that routinely block Korean launches. Check each
provider's current documentation.

- **Kakao Login** — app registered in Kakao Developers with the production redirect URIs; the consent items
  (동의항목) the product requests are configured, and items that need Kakao's review (e.g. phone number or real
  name) have been approved; account linking only on a verified identifier; the unlink (연결 끊기) call runs on
  account deletion.
  - Law/standard: none — Kakao Developers policy
  - Verify at: Kakao Developers — developers.kakao.com
- **Naver Login** — the application has passed Naver's service review (검수) before being opened to all users;
  callback URLs and requested profile fields match production; tokens are revoked on account deletion.
  - Law/standard: none — Naver Developers policy
  - Verify at: Naver Developers — developers.naver.com
- **Social login on iOS** — an iOS app offering Kakao or Naver login checks the App Store login-services rule
  (an equivalent privacy-focused login option, e.g. Sign in with Apple).
  - Law/standard: none — Apple App Store Review Guidelines (login services)
  - Verify at: Apple Developer — developer.apple.com/app-store/review/guidelines
- **Toss Payments** — merchant review (가맹점 심사) completed before live keys; secret keys and billing keys only
  on the server; recurring billing (자동결제·빌링) enabled under a separate agreement where Toss requires it; payment
  approval confirmed server-side; webhook events verified and handled idempotently; live and test keys never mixed.
  - Law/standard: none — Toss Payments merchant terms and developer documentation
  - Verify at: Toss Payments Developers — docs.tosspayments.com
- **알림톡 template approval** — the sender profile (발신 프로필) is registered, every template is approved before
  launch (allow review lead time), variables match the approved text, and SMS fallback is configured.
  - Law/standard: none — Kakao Business messaging policies and the dealer's template guide
  - Verify at: Kakao Business — business.kakao.com; the contracted official dealer
- **Identity verification (본인인증, PASS)** — which provider verifies identity (mobile-carrier PASS, NICE, KCB,
  or others); the service receives connecting information (CI/DI) instead of resident registration numbers and
  classifies it as `Sensitive-PII` in the data model; age and minor checks use the provider's result; the provider
  contract covers the purposes used.
  - Law/standard: Network Act (정보통신망법) — identity verification by designated agencies; Personal Information Protection Act (개인정보 보호법)
  - Verify at: KISA — kisa.or.kr; the chosen provider's documentation
