# Stack Profiles — Golden-Path Presets

Loaded by `/setup-stack` only when the user asks for a preset or passes a profile name as the argument. Each preset
is a **starting proposal for the layer choices** — components, typical code roots and the stack specialists the
`stack` line will route to. The user confirms or changes every layer individually, and the preset name is recorded
in `stack.profile` for information only: no skill ever branches on it.

**What a preset never contains:**

- **Versions.** Every version comes from a live source at setup time (Phase 5 of the skill), never from this file.
  A version written here would be stale within months and would read as verified.
- **Commands.** `commands.*` are asked, never assumed — the typical shapes below are prompts for the question, not
  defaults.
- **Decisions that belong to an ADR.** The data and cloud rows are the *usual* choice for this shape of product. Leave
  those layers unset until their Foundation ADRs are Accepted (`/architecture-decision`); acceptance of a `Data` or
  `Infra` ADR hands off to `/setup-stack refresh`, which records them.

Routing shown in each table is what the routing rules (`.claude/docs/effects-map.md`, `### Specialist routing`)
derive from the framework string; the `stack` line printed by `resolve_config` after the write is authoritative. When a framework is not recognised, the lead is spawned alone,
and `specialists.<layer>` can name the sub-specialist explicitly.

---

## `ts-fullstack-web`

**Fits:** a web product with an admin console — B2B SaaS, or a B2C service that starts on the web — built by a small
team that wants one language (TypeScript) end to end and shared types between the web apps and the API.

| Layer | Components | Typical root(s) | Routed specialists |
|-------|-----------|-----------------|--------------------|
| web | Next.js · TypeScript | `[apps/web, apps/admin]` | web-specialist > nextjs-specialist |
| backend | NestJS · TypeScript · runtime Node.js (an LTS line) | `[apps/api, services/worker]` | backend-specialist > node-specialist |
| data *(via ADR)* | PostgreSQL · Redis · queue `none` at first · Prisma or Drizzle | migrations: `apps/api/prisma/migrations` (Prisma) | data-specialist |
| cloud *(via ADR)* | Vercel for the web apps with AWS for the API and data, or AWS throughout · Terraform | `infra` | cloud-specialist |

- **Repository:** `stack.monorepo: true` (pnpm workspaces, usually with Turborepo); `stack.package_manager: pnpm`;
  `stack.shared_roots: [packages]` for the component library, API client and shared types.
- **Surfaces:** `[web]`; add `api` only when partners or the public call the API directly.
- **Variants:** Fastify or Hono instead of NestJS route to the same node-specialist. A product with no separate API
  service (route handlers and server actions inside the web app) leaves `backend` unset — a configured data layer
  still makes the *Backend* condition true for the gates.
- **Typical command shapes to ask about:** `pnpm install --frozen-lockfile`, `pnpm turbo run build`,
  `pnpm turbo run test`, `pnpm --filter <web package> exec playwright test`.

## `expo-mobile-ts-api`

**Fits:** a mobile-first consumer app on iOS and Android with an API behind it, built by a team without dedicated
native engineers — the shape of Moa's apps.

| Layer | Components | Typical root(s) | Routed specialists |
|-------|-----------|-----------------|--------------------|
| mobile | React Native (Expo) · TypeScript | `apps/mobile` | mobile-specialist > react-native-specialist |
| web *(optional)* | Next.js · TypeScript — admin console and marketing pages | `apps/admin` | web-specialist > nextjs-specialist |
| backend | NestJS (or Fastify / Hono) · TypeScript · runtime Node.js | `apps/api` | backend-specialist > node-specialist |
| data *(via ADR)* | PostgreSQL · Redis · Prisma or Drizzle | migrations under `apps/api` | data-specialist |
| cloud *(via ADR)* | AWS or GCP · Terraform | `infra` | cloud-specialist |

- **Mobile version:** with `framework: React Native (Expo)`, `version` holds the **React Native** version the pinned
  Expo SDK ships — it is what `react-native` in `apps/mobile/package.json` declares and what
  `project-coherence.sh` compares. Record the Expo SDK version in the component's post-cutoff changes. (With
  `framework: Expo`, `version` is the SDK version and the coherence check reads `expo` instead.)
- **Build & delivery:** EAS Build and EAS Submit for store builds, over-the-air updates only within store rules;
  push through APNs and FCM (directly or through Expo's push service) — each is an ADR decision, not a preset default.
- **Surfaces:** `[ios, android]` (+ `web` when the admin console ships to customers); `release.distribution: stores`
  or `web+stores`. Ask `platform.min_os.ios` and `platform.min_os.android`; the minimums the pinned Expo SDK supports
  are looked up live.
- **Repository:** Expo documents monorepo setups; read the pinned SDK's guidance for the chosen package manager
  during Phase 5 rather than assuming a layout works.

## `flutter-spring`

**Fits:** a team with Java or Kotlin backend experience — common in Korean enterprises and fintech — shipping one
Flutter codebase to iOS and Android, often in a regulated domain.

| Layer | Components | Typical root(s) | Routed specialists |
|-------|-----------|-----------------|--------------------|
| mobile | Flutter · Dart | `apps/mobile` | mobile-specialist > flutter-specialist |
| backend | Spring Boot · Kotlin (or Java) · runtime a JDK LTS line (Eclipse Temurin or Amazon Corretto) | `apps/api` (+ `services/batch` for Spring Batch jobs) | backend-specialist > spring-specialist |
| data *(via ADR)* | PostgreSQL or MySQL · Redis · Spring Data JPA (Hibernate) · Flyway | migrations: `apps/api/src/main/resources/db/migration` (Flyway's default location) | data-specialist |
| cloud *(via ADR)* | AWS, or Naver Cloud Platform where a Korean public-sector or financial customer requires a domestic cloud · Terraform | `infra` | cloud-specialist |
| web *(optional)* | Next.js or Vue/Nuxt admin console | `apps/admin` | web-specialist > nextjs-specialist or vue-nuxt-specialist |

- **Repository:** often a multi-directory repository without a workspace tool (`stack.monorepo: false`).
  `stack.package_manager` records one manager — usually `gradle` for the API; Flutter's `pubspec.lock` is still
  committed. A Gradle version catalog (`gradle/libs.versions.toml`) is where the Spring Boot version is usually read.
- **Surfaces:** `[ios, android]` (+ `api` for partner integrations); `release.distribution: stores`.
- **Regulated domains:** a domestic-cloud requirement is a contract or checklist fact, not a preset assumption — take it
  from the customer's requirements and `.claude/docs/compliance/kr.md`, and decide it in the cloud ADR.

## `python-api-react`

**Fits:** a data- or ML-heavy product (LLM features, recommendations, analytics) or an internal tool, where the API
sits next to Python data code and the web front end is a single-page app.

| Layer | Components | Typical root(s) | Routed specialists |
|-------|-----------|-----------------|--------------------|
| web | React (Vite) · TypeScript | `apps/web` | web-specialist > nextjs-specialist (covers React idioms) |
| backend | FastAPI (or Django when its admin and ORM earn their weight) · Python · runtime Python | `[apps/api, services/worker]` | backend-specialist > python-specialist |
| data *(via ADR)* | PostgreSQL (pgvector when embeddings are stored) · Redis · Redis or RabbitMQ as the task broker · SQLAlchemy with Alembic | migrations: `apps/api/alembic/versions` | data-specialist |
| cloud *(via ADR)* | AWS or GCP · Terraform | `infra` | cloud-specialist |

- **Repository:** `stack.package_manager: uv` for the API (`uv.lock` committed); the web app's own manager goes in
  `commands.install` (for example two commands chained with `&&`). `stack.monorepo` is `true` only when a workspace
  tool manages both.
- **Surfaces:** `[web]` (+ `api` when the API is offered to customers).
- **LLM features:** model and prompt versions are pinned like any component when they are part of the product — the
  ml-engineer owns their evaluation; `.claude/rules/ai-integration.md` applies to the code.

---

## Korean-market integrations (`compliance.regions` includes `kr`)

Offer these as **integration candidates**, recorded in the `## Assess` ring of `docs/architecture/tech-radar.md` —
never installed and never added to a layer by this skill:

| Candidate | Why it is usually assessed |
|-----------|----------------------------|
| Kakao Login | The dominant social login in Korea |
| Naver Login | Second major Korean social login |
| Sign in with Apple | Check App Store Review Guideline 4.8 (Login Services) for the current rule on offering an equivalent login when third-party or social login is used |
| Toss Payments | Korean payment gateway with auto-debit (billing keys) for subscriptions; alternatives such as NHN KCP, KG Inicis or the PortOne aggregator are assessed the same way |
| In-app billing (App Store / Google Play) | Digital goods sold inside the mobile apps go through store billing unless a store's alternative-billing program applies — read the current terms live |

Commonly assessed alongside: 알림톡 (Kakao BizMessage) through a messaging vendor for informational notifications, and
a 본인인증 (identity verification) provider when regulation or fraud controls require it.

Each entry is written in the tech-radar format with the vendor's official developer-documentation URL fetched in the
same run — `- **Toss Payments** — PG candidate for plan auto-debit; not integrated (Source: <url>)`. A candidate whose
documentation could not be fetched is left out and named in the run summary as `NOT SOURCEABLE`. Adopting any of them
takes an ADR (Domain `Auth` or `Integrations`), and the regional checklist `.claude/docs/compliance/kr.md` lists what
to verify (PIPA, 전자금융거래법, in-app payment rules, marketing-message consent).

Other regions follow the same pattern — for example a card processor for `us` or `eu` products — recorded in
`## Assess` with a live source, adopted only through an ADR.
