# 변경 이력

Claude Code Service Studios(CCSS) 프레임워크 자체의 변경 이력입니다. 프레임워크를 쓰는 사람의 관점에서
무엇이 달라졌고 왜 달라졌는지를 적습니다.

- 여러분이 만드는 **제품**의 변경 이력은 이 파일이 아닙니다. 제품의 변경 이력은 `/changelog`가
  `docs/CHANGELOG.md`에 따로 씁니다.
- 버전을 올리는 절차는 [UPGRADING.md](UPGRADING.md)에 있습니다.
- 형식은 Keep a Changelog를, 버전 번호는 Semantic Versioning을 따릅니다. 지금 프로젝트가 쓰는 프레임워크
  버전은 `project.yaml`의 `framework.version`에 기록되어 있습니다.

---

## [0.1.0] - 2026-09-27

**Claude Code Game Studios v1.1.1(7ed2c3e)에서 포크하여 IT 서비스 스튜디오로 전환한 첫 릴리스입니다.**
업스트림이 게임 개발을 위해 만든 제어 골격(협업 프로토콜, 단계 게이트, 디렉터 리뷰, 설정 엔진, 세션 연속성,
스킬 테스트 프레임워크)은 동작을 그대로 유지하고, 그 위에 얹힌 조직·문서·단계·스택을 웹·모바일·API 서비스
개발에 맞게 새로 짰습니다. 기준으로 삼은 것은 실리콘밸리와 한국 스타트업의 제품 조직(PM, 디자이너,
엔지니어, QA, SRE, CS)이 실제로 일하는 방식입니다.

**업스트림 크레딧** — Claude Code Game Studios v1.1.1(커밋 `7ed2c3e`), 작성자 Donchitos, MIT 라이선스,
`https://github.com/Donchitos/Claude-Code-Game-Studios`. 업스트림의 이전 버전 이력은 이 파일로 옮겨 오지
않았습니다. 필요하면 업스트림 저장소에서 확인하세요.

**전환은 하나의 원자적 변경입니다.** 옛 이름과 새 이름이 함께 쓰이는 중간 상태가 없고 호환 별칭도 두지
않았습니다. 옛 스킬 이름, 옛 설정 키, 옛 단계 값은 어디에서도 받아들이지 않습니다. 그래서 업스트림으로 만든
프로젝트를 이 버전으로 옮기는 마이그레이션은 지원하지 않습니다([UPGRADING.md](UPGRADING.md) 참고). 아래의
"변경" 절에 있는 이름 대응표는 업스트림을 알던 분이 새 구조를 빨리 찾도록 돕는 안내일 뿐, 옛 이름이 계속
동작한다는 뜻이 아닙니다.

### 추가

#### 서비스 개발 7단계 파이프라인

| # | 단계(`project.stage`) | 이 단계에서 하는 일 | 게이트(`/gate-check <목표>`) | 업스트림 단계 |
|---|---|---|---|---|
| 1 | `Discovery` | 문제와 해결 방향 정의, 제품 브리프(minimal은 one-pager), 이미 정한 레이어의 스택 고정 | — (시작 단계) | Concept |
| 2 | `Definition` | 기능 맵과 기능별 PRD(서비스 기획) | `definition` | Systems Design |
| 3 | `Architecture` | 아키텍처와 SLO, ADR, 초기 API 계약, 데이터 모델, 위협 모델, 접근성 기준, 테스트·CI 스캐폴드 | `architecture` | Technical Setup |
| 4 | `Validation` | 디자인 언어, UX 명세, 프로토타입 사용성 검증, UX와 맞춘 API 계약, 에픽·스토리, 첫 스프린트, 스테이징에 배포한 워킹 스켈레톤(Sprint 0) | `validation` | Pre-Production |
| 5 | `Build` | 스프린트 루프 — 스토리 구현, 코드 리뷰, 스모크 체크, QA | `build` | Production |
| 6 | `Hardening` | 베타·안정화 — 성능, 부하, 보안, 사용성, QA 사인오프, 런북, 릴리스 준비 | `hardening` | Polish |
| 7 | `Launch` | 출시와 지속적 전달(종착 단계) | `launch` | Release |

- **Launch는 종착 단계입니다.** 출시 뒤의 일은 게이트 없이 Launch 안에서 반복합니다. 인시던트, 핫픽스,
  그로스 실험, 회고, 그리고 이후의 모든 릴리스(PRD → 스프린트 → 스토리 → 스모크 체크 → 릴리스 체크리스트 →
  롤아웃 계획 → 릴리스 기록)가 여기에 속합니다. 워크플로 카탈로그가 이 전달 루프를 선택적 반복 스텝으로 보여
  주므로, 출시 뒤에도 `/help`가 다음 할 일을 안내합니다.
- **릴리스마다 기록이 남습니다.** `production/releases/<version>/` 아래에 `release-checklist.md`,
  `rollout-plan.md`, `launch-checklist.md`, `release-notes.md`, `release-record.md`가 쌓입니다. 게이트가 아니라
  기록입니다. `/retrospective release <version>`이 출시 결과를 각 PRD의 성공 지표와 비교해 루프를 닫습니다.
- **워킹 스켈레톤이 Validation의 필수 스텝입니다(`standard`, `full`).** 실제 코드로 된 가장 얇은 종단 경로를
  CI/CD로 스테이징에 배포하고, 롤백과 기능 플래그 전환을 한 번 연습합니다(`/walking-skeleton`). 이후의 모든
  게이트는 스테이징, 지속적 배포, 관측성, 기능 플래그가 이미 갖춰져 있다고 가정합니다.

#### 새 스킬

- `/api-design` — contract-first API 설계. API 가이드라인, OpenAPI·GraphQL·protobuf·AsyncAPI 계약, UX 명세와의
  조정(`reconcile`), 린트, 호환성을 깨는 변경 검사. 외부에 공개하는 API라면 개발자 가이드까지 씁니다.
- `/data-model` — 엔티티별 소유권·데이터 분류·보존 기간·인덱스와 expand/contract 방식의 마이그레이션 계획.
- `/incident` — SEV1–SEV4 분류, 역할 지정, 완화, 고객 커뮤니케이션, UTC와 KST를 함께 적는 타임라인.
  `runbook` 모드로 알림별 런북을 씁니다.
- `/postmortem` — 인시던트에 대한 비난 없는(blameless) 포스트모템: 타임라인, 영향, 기여 요인, 후속 조치.

업스트림 스킬 가운데 상당수도 이름과 내용을 바꿔 새로 썼습니다. 대응표는 아래 "변경" 절에 있습니다.

#### 새 에이전트

- 서비스 조직에 빠질 수 없는 역할 네 개: `mobile-engineer`, `sre-engineer`, `ux-researcher`, `data-engineer`.
- 스택 에이전트 14개 — 레이어 리드 5개와 서브 스페셜리스트 9개입니다.
  - web: `web-specialist` → `nextjs-specialist`, `vue-nuxt-specialist`
  - mobile: `mobile-specialist` → `react-native-specialist`, `flutter-specialist`, `ios-specialist`,
    `android-specialist`
  - backend: `backend-specialist` → `node-specialist`, `spring-specialist`, `python-specialist`
  - data: `data-specialist`, cloud: `cloud-specialist`(서브 스페셜리스트 없음)

  `project.yaml`의 `stack.layers.<layer>.framework` 값에 따라 자동으로 라우팅되고, `specialists.web`,
  `specialists.mobile`, `specialists.backend`로 직접 지정할 수도 있습니다. 스택 에이전트는 버전에 민감한 조언을
  하기 전에 `docs/stack-reference/`를 먼저 확인하고, 확인할 수 없으면 추측하는 대신
  `NOT SOURCEABLE — run /setup-stack refresh`라고 답합니다.
- 운영 역할(`sre-engineer`, `devops-engineer`, `release-manager`)을 위한 **Operations Workflow** 협업 템플릿.
  프로덕션, 공유 인프라, 공유 데이터베이스, 시크릿을 바꾸는 명령은 에이전트가 직접 실행하지 않습니다. 영향
  범위, 예상 출력, 롤백 명령을 붙여 사람에게 제안하고, 실행 결과를 확인한 뒤 기록합니다.

#### 새 디렉터 게이트와 판정 규칙

- `SE-SECURITY-REVIEW`(`security-engineer`) — API 계약, 데이터 모델, 인증·보안·데이터 영역 ADR에 대한 보안·
  개인정보 설계 리뷰. 작업별 인가(BOLA/IDOR), 신뢰 경계, PII 분류·보존·동의, 시크릿을 봅니다.
- `SR-PRODUCTION-READINESS`(`sre-engineer`) — 롤아웃 전 프로덕션 준비도 리뷰: SLO, 대시보드와 알림, 런북,
  온콜, 부하 테스트 근거, 백업·복구, 연습한 롤백.
- `DD-CONTENT-VOICE`(`design-director`) — 마이크로카피, 알림, 헬프센터, 스토어 문구의 보이스·용어 일관성.
- **판정 등급 매핑.** 게이트마다 다른 판정 토큰을 APPROVE·CONCERNS·REJECT 세 등급으로 묶었습니다. 게이트를
  호출하는 모든 스킬이 세 등급을 빠짐없이 처리합니다.
- **리뷰 모드 예외.** `/hotfix`, `/rollout-plan`, `/incident`는 릴리스에 결정적인 스킬이라, 이들이 부르는
  에이전트와 게이트는 `review_mode`와 관계없이 항상 실행됩니다.

#### 서비스 개발용 설정

- `stack.*` — web·mobile·backend·data·cloud 레이어별 프레임워크, 버전, 언어, 런타임, 코드 루트와
  `stack.shared_roots`, `stack.monorepo`, `stack.package_manager`, `stack.profile`, 그리고 스택 고정이 끝났음을
  뜻하는 `stack.pinned_on`.
- `platform.surfaces`(`web`, `ios`, `android`, `api` — `api`는 외부에서 쓰는 API), `platform.browsers`,
  `platform.min_os.ios`, `platform.min_os.android`.
- `release.distribution`(`web`, `stores`, `web+stores`, `enterprise`, `internal`).
- `privacy.handles_pii`, `compliance.regions`(`kr`, `eu`, `us` — `[]`는 "명시적으로 없음"),
  `localization.locales`(BCP 47 태그 목록).
- 성능 예산 키 9개(`performance.api_p95_ms`, `error_rate_pct`, `availability_pct`, `lcp_ms`, `inp_ms`, `cls`,
  `bundle_kb`, `cold_start_ms`, `crash_free_pct`)와 적용 강도 `performance.enforce`(`warn`, `block`, `off`).
- `testing.patterns`(테스트 파일 위치 glob — 코드 옆에 두는 테스트도 인정)와 `testing.strict.e2e`.
- `naming.*`와 `commands.*` 확장 — API 경로·필드, DB 테이블·컬럼, 환경 변수, 이벤트 이름 규칙, 그리고
  `install`, `dev`, `e2e`, `typecheck`, `api_lint`, `migrate`, `smoke`, `load_test`, `deploy_preview` 명령.
- `resolve_config` 라벨 `code_roots`, `surfaces`, `compliance`, `accessibility`.
- 배열 값(`platform.surfaces`, `compliance.regions`)도 원소 하나하나를 검증합니다. 오타 하나 때문에 표면이
  조용히 빠지는 일이 없고, 설정하지 않은 것과 빈 목록(`[]`)을 구분합니다.

#### 모노레포와 코드 루트

- 고정된 코드 루트가 없습니다. 레이어마다 `stack.layers.<layer>.root`에 경로 하나나 경로 목록을 선언합니다.
  예를 들어 `web: [apps/web, apps/admin]`, `backend: [apps/api, services/worker]`, `cloud: infra`, 공유 코드는
  `stack.shared_roots: [packages]`이고, 단일 앱 저장소라면 `src` 하나로 충분합니다.
- `resolve_code_roots`가 선언된 루트를 해석하고, 어떤 레이어도 선언하지 않은 `apps/*`, `services/*`,
  `packages/*` 워크스페이스를 찾아 `undeclared`로 경고합니다. 훅과 `/dev-story`, `/test-setup`, `/story-done`이
  모두 같은 결과를 씁니다. 해석되는 루트가 없으면 코드를 쓰지 않고 `NOT CHECKED`를 출력합니다.

#### 스택 레퍼런스와 테크 레이더

- `docs/stack-reference/`는 `/setup-stack`이 실시간 소스(Context7이 있으면 Context7, 없으면 웹 검색)에서
  생성합니다. 모든 사실에 출처와 조회 날짜가 붙고, 확인할 수 없는 값은 `NOT SOURCEABLE`이나 `NOT DETERMINED`로
  남깁니다. 템플릿에는 README와 비어 있는 `VERSION.md` 골격만 들어 있습니다 — 오래된 스냅숏을 싣지 않습니다.
- `docs/architecture/tech-radar.md`(`## Adopt`, `## Trial`, `## Assess`, `## Hold`, `## Forbidden Patterns`)에서
  허용·보류·금지 기술과 패턴을 ADR과 연결해 관리합니다. `/create-control-manifest`가 Hold와 Forbidden 항목을
  "Never" 규칙으로 옮깁니다.

#### 지역 컴플라이언스 점검 목록

- `.claude/docs/compliance/kr.md`, `eu.md`, `us.md` — `compliance.regions`에 넣은 지역의 파일만 로드됩니다.
  - 한국: 개인정보 보호법, ISMS-P, 위치정보법, 전자상거래법, 전자금융거래법(PG·자동이체, 포인트·크레딧의
    선불전자지급수단 해당 여부), 전기통신사업법의 인앱 결제, 정보통신망법의 광고성 정보 전송 동의(알림톡은
    정보성 메시지 전용), 장애인차별금지법과 KWCAG 2.2.
  - EU: GDPR, ePrivacy(쿠키와 전자 마케팅 동의), European Accessibility Act, 해당하는 경우 DSA.
  - 미국: CCPA/CPRA, COPPA, CAN-SPAM, TCPA, ADA/Section 508, 주별 유출 통지법, 카드 데이터를 다루면 PCI DSS.
- 법률 자문이 아니라 **확인할 주제의 목록**입니다. 기한, 과태료, 기준치 같은 숫자는 실행 시점에 출처 URL과
  조회 날짜를 붙였을 때만 적습니다.

#### 훅·스크립트·규칙·템플릿

- `validate-commit.sh`가 이제 **커밋을 막습니다**. 대상은 파싱되지 않는 JSON/YAML(설정, API 계약, 로케일,
  레지스트리, CI 워크플로, `project.yaml`), 추가된 줄에 들어 있는 시크릿(AWS 액세스 키, 개인 키, GitHub·Slack·
  Google API·Stripe 라이브 키 패턴), 자격 증명 파일(`.env`와 `.env.*` — `.env.example` 제외 — 그리고
  `*.keystore`, `*.jks`, `*.p12`, `*.mobileprovision`, `*.pem`)입니다. `EXAMPLE`로 끝나는 토큰과
  `pragma: allowlist secret`이 붙은 줄은 예외로 둡니다. 커밋 메시지가 Conventional Commits 형식이 아니거나
  스토리·태스크 ID가 없으면 경고합니다.
- `validate-data-files.sh` — 같은 JSON/YAML 규칙으로 파일을 쓰는 즉시 검사합니다. PyYAML이 없으면 구조 검사로
  대신하고 `NOT CHECKED: full YAML parse (PyYAML unavailable)`를 출력합니다. PyYAML이 없다는 이유만으로 막지는
  않습니다.
- `validate-push.sh`는 마이그레이션이 들어간 푸시에서 마이그레이션 계획의 단계를 확인하라고 알립니다.
  `validate-skill-change.sh`는 에이전트 파일을 고쳐도 `/skill-test spec <name>`을 권합니다. `notify.sh`는
  macOS와 Linux 데스크톱 알림도 지원합니다.
- `stage-estimate.sh` — 현재 단계를 추정하는 유일한 로직입니다. 상태 표시줄, `/help`, `/gate-check`,
  `/project-stage-detect`, 세션 훅이 모두 이 스크립트를 씁니다.
- `prd-structure-check.sh`(PRD 섹션 관찰)와, 설정 ↔ `docs/stack-reference/VERSION.md` ↔ 매니페스트·락파일·
  런타임 파일의 정합성을 관찰하는 `project-coherence.sh`. 두 스크립트 모두 관찰만 출력하고 판정은 하지 않습니다.
- 규칙 `migrations.md`(expand/contract, 되돌릴 수 있는 변경, 드라이런 증거), `infra-code.md`(시크릿 금지, 최소
  권한, plan 후 apply, 에이전트는 apply하지 않음), `mobile-code.md`(권한 요청 근거, 딥링크 검증, 오프라인 동기화
  충돌, 스토어 정책, 강제 업데이트 경로). 코드 규칙의 경로 glob은 `src/` 구조와 모노레포 구조(`apps/*/…`,
  `packages/*/src/**`)를 모두 포함합니다.
- 새 템플릿 13개: `api-guidelines.md`, `openapi-skeleton.yaml`, `data-model.md`, `migration-plan.md`,
  `threat-model.md`, `rollout-plan.md`, `incident-postmortem.md`, `runbook.md`, `slo.md`,
  `stack-component-version.md`, `code-root-claude.md`, `tech-radar.md`, `tracking-plan.md`.
- `.claude/settings.json`에 로컬 테스트·린트 명령의 허용 목록(npm, pnpm, yarn, `npx tsc --noEmit`, pytest,
  Gradle, Flutter, Go)과, 프로덕션 배포·IaC apply·파괴적인 DB 명령·스토어 제출·자격 증명 파일 읽기를 막는 거부
  목록을 추가했습니다. 항상 묻기 범주(`modes.automation_always_ask`) 뒤에 있는 두 번째 방어선입니다.

#### 언어 정책과 예시

- **언어 정책**: AI가 읽거나 스크립트가 파싱하는 프레임워크 파일은 영어이고, 사람이 읽는 문서 15개는
  한국어입니다(목록은 `.claude/docs/coding-standards.md` § Language Policy). 스킬이 만드는 산출물은 템플릿
  헤딩, 굵은 필드 라벨, 판정·심각도·상태 토큰, YAML 키, ID, 경로를 영어 그대로 두고, 본문은 사용자가 대화하는
  언어로 씁니다. 스크립트와 게이트가 헤딩으로 문서를 찾기 때문에 헤딩은 번역하지 않습니다.
- 프레임워크 전체의 예시를 하나의 가상 제품 **Moa**(한국 시장용 B2C 구독형 저축 앱 — 웹, iOS, Android, API)로
  통일했습니다. 파일마다 예시가 달라 서로 어긋나는 일이 없습니다.

#### 스킬 테스트 프레임워크

- 스킬 카테고리 `ops`(`/hotfix`, `/incident`, `/rollout-plan`, `/postmortem`)와 그 루브릭, 에이전트 카테고리
  `stack`(스펙 폴더 `agents/stack/`).
- 카탈로그를 새로 만들었습니다. 스킬 76개와 에이전트 46개, 모두 122개 항목이고 항목마다 스펙 파일이 있습니다.

### 변경

#### 브랜드

- `Claude Code Game Studios` → `Claude Code Service Studios`, `CCGS` → `CCSS`. 스킬 테스트 프레임워크 폴더는
  `CCSS Skill Testing Framework/`, 훅의 루트 변수는 `CCSS_ROOT`입니다.
- 설정 블록 머리글: `=== CCSS Config (resolved: local->yaml->rigor->default; use as-is) ===`.

#### 단계와 게이트 호출

- 단계 id와 `project.stage` 값이 위 표의 7개로 바뀌었습니다. `project.stage`는 한 단어 값(`Discovery` …
  `Launch`)이고, 카탈로그의 단계 id는 그 소문자입니다.
- `/gate-check`의 인자는 어디서나 **목표** 단계 id(`definition`, `architecture`, `validation`, `build`,
  `hardening`, `launch`)입니다. 출발 단계는 `project.stage`가 아니라 목표 단계에서 계산합니다. 인자가 없으면
  `stage-estimate.sh`가 추정한 단계의 다음 단계를 목표로 삼고, 이미 Launch라면 더 넘을 게이트가 없다고
  알려 줍니다.
- 워크플로 카탈로그 스텝에 `required_tiers`와 `required_when`(`ui`, `backend`, `pii`, `stores`,
  `multi-locale`) 필드가 생겼습니다. `artifact-check.sh`는 스텝마다 `tiers=`와 `when=`을 출력하고, `/help`와
  `/project-stage-detect`는 여러분의 티어나 조건에 해당하지 않는 필수 스텝을 선택 스텝으로 보여 줍니다.
  `--phase`에 빈 값을 넘기면 모든 단계를 평가하던 동작 대신 종료 코드 2로 멈춥니다.
- 카탈로그 스텝의 필수 여부를 게이트 기준 파일과 맞췄습니다. 브리프 검토는 standard·full 필수, 스택 고정은
  Discovery에서 권장이고 Definition(standard·full)과 Architecture(모든 티어)에서 필수, UX에 맞춘 API 계약 조정은
  full·백엔드에서 필수이며, Hardening에 `/changelog`(standard·full)와 릴리스 후보 `/smoke-check`(PASS만 인정)
  스텝이 생겼습니다.
- 테스트·CI 스캐폴드(`/test-setup`)는 Architecture로 옮겼고, API 계약은 초기 계약(Architecture)과 UX에 맞춘
  조정(Validation)으로 나눴습니다. 게이트가 자기가 들어가려는 단계의 산출물을 요구하는 일이 없습니다.
- QA 사인오프와 S2 버그 정리는 Hardening에 들어갈 때가 아니라 Hardening을 마치고 Launch로 넘어갈 때의
  조건입니다. 출시 게이트는 보안 감사(`standard`·`full`은 전체 감사, `minimal`은 빠른 감사)와, 로케일이 둘
  이상이면 현지화 QA를 요구합니다.

#### 조직 — 에이전트 이름 대응표

| 업스트림 에이전트 | 새 에이전트 | 실제 조직에서의 직함 |
|---|---|---|
| creative-director | `product-director` | CPO·프로덕트 디렉터 |
| producer | `delivery-manager` | PjM·딜리버리 매니저 |
| art-director | `design-director` | 디자인 디렉터 |
| game-designer | `product-manager` | PM/PO(서비스 기획) |
| systems-designer | `business-analyst` | 서비스·정책 기획자 |
| economy-designer | `monetization-strategist` | 가격·수익화 전략 담당 |
| lead-programmer | `tech-lead` | 테크 리드 |
| gameplay-programmer | `backend-engineer` | 백엔드 엔지니어 |
| ui-programmer | `frontend-engineer` | 프론트엔드 엔지니어 |
| engine-programmer | `platform-engineer` | 플랫폼 엔지니어(공유 라이브러리·SDK) |
| tools-programmer | `internal-tools-engineer` | 어드민·운영툴 엔지니어 |
| ai-programmer | `ml-engineer` | ML·LLM 엔지니어 |
| technical-artist | `design-engineer` | 디자인 엔지니어(디자인 토큰·컴포넌트 라이브러리) |
| ux-designer | `product-designer` | 프로덕트 디자이너 |
| writer | `ux-writer` | UX 라이터 |
| live-ops-designer | `growth-manager` | 그로스 매니저 |
| community-manager | `customer-success-manager` | CS/CX 매니저 |
| qa-tester | `qa-engineer` | QA 엔지니어(SDET) |
| performance-analyst | `performance-engineer` | 성능 엔지니어 |

이름을 유지한 에이전트: `technical-director`, `qa-lead`, `release-manager`, `localization-lead`,
`security-engineer`, `accessibility-specialist`, `analytics-engineer`, `devops-engineer`, `prototyper`. 이름은
같아도 본문은 서비스 기준으로 새로 썼습니다.

- **모든 에이전트 파일이 같은 골격을 따릅니다**(`.claude/rules/skill-authoring.md` § Agent file skeleton).
  협업 템플릿은 역할에 맞게 Strategic Decision, Question-First, Implementation, Operations 네 가지로 나눴습니다.
  코드를 쓰지 않는 역할에 구현용 템플릿이 붙어 있던 문제가 사라졌습니다.
- **모델 등급은 에이전트 frontmatter가 유일한 기준입니다.** opus는 `product-director`, `technical-director`,
  `delivery-manager` 세 디렉터, sonnet은 `tech-lead`, `prototyper`와 스택 서브 스페셜리스트 9개, 나머지는
  `inherit`이고 haiku는 쓰지 않습니다. `devops-engineer`와 `customer-success-manager`는 haiku에서 `inherit`로
  올렸습니다. 인시던트 대응과 고객 커뮤니케이션은 품질이 중요하기 때문입니다.
- **보고 체계**: `qa-lead`는 `technical-director`에게, `customer-success-manager`는 `product-director`에게
  보고합니다. 부모 에이전트의 "Delegates to"에 자식이 반드시 들어 있습니다.
- **`/dev-story` 라우팅**: 스토리의 `> **Surface**:`(`web`, `ios`, `android`, `mobile`, `api`, `admin`, `infra`,
  `analytics`)와 `> **Type**:`으로 담당 엔지니어와 스택 스페셜리스트를 고릅니다. 위험도가 HIGH인 스토리에는
  서브 스페셜리스트 대신 레이어 리드를 붙입니다.

#### 스킬 이름 대응표

| 업스트림 스킬 | 새 스킬 | 하는 일 |
|---|---|---|
| setup-engine | `/setup-stack` | 레이어별 스택 선택, 실시간 소스로 버전 고정, 코드 루트 선언 |
| map-systems | `/map-features` | 기능 맵과 MVP / Beta / GA / Later 티어 |
| design-system | `/write-prd` | 기능별 PRD 작성 |
| design-review | `/prd-review` | PRD나 제품 브리프 한 건 리뷰 |
| review-all-gdds | `/review-all-prds` | PRD 전체를 가로지르는 리뷰 |
| quick-design | `/quick-spec` | 작은 변경을 위한 가벼운 스펙과 롤아웃 메모 |
| propagate-design-change | `/propagate-prd-change` | PRD 변경이 ADR·API 계약·데이터 모델·스토리에 주는 영향 |
| art-bible | `/design-language` | 디자인 언어(토큰, 컴포넌트, 상태, 플랫폼 적응) |
| asset-spec | `/ui-inventory` | 화면·컴포넌트 목록과 미디어 에셋 명세 |
| vertical-slice | `/walking-skeleton` | 스테이징에 배포하는 가장 얇은 종단 경로 |
| playtest-report | `/usability-report` | 사용성·베타·인터뷰 보고서 |
| team-combat | `/team-feature` | 기능 스쿼드 오케스트레이션 |
| team-narrative | `/team-content` | 보이스·톤, 마이크로카피, 알림, 헬프센터 |
| team-live-ops | `/team-growth` | 그로스 실험과 라이프사이클 캠페인 |
| team-polish | `/team-hardening` | 성능·신뢰성·보안·접근성 하드닝 |
| soak-test | `/load-test` | smoke·load·stress·spike·soak 부하 테스트 |
| asset-audit | `/bundle-audit` | 라우트별 번들, 이미지, 폰트, 앱 크기 예산 |
| balance-check | `/business-rules-check` | 요금·한도·수수료·프로모션·환불 규칙 점검 |
| content-audit | `/feature-audit` | 계획 대비 구현 점검 |
| patch-notes | `/release-notes` | 채널별 고객용 릴리스 노트 |
| day-one-patch | `/rollout-plan` | 단계적 롤아웃, 플래그, 가드레일, 롤백 계획 |

이름은 같지만 서비스 기준으로 새로 쓴 스킬: `/adopt`, `/brainstorm`, `/code-review`, `/create-architecture`,
`/dev-story`, `/hotfix`, `/launch-checklist`, `/perf-profile`, `/prototype`, `/release-checklist`,
`/retrospective`, `/security-audit`, `/smoke-check`, `/start`, `/test-helpers`, `/test-setup`.

- **항상 협업하는 스킬**: `/gate-check`, `/hotfix`, `/incident`, `/rollout-plan`, `/setup-stack`, `/start`,
  `/settings`는 `modes.automation`과 관계없이 모든 단계를 승인받습니다.
- **팀 스킬**(`/team-*`)은 에이전트를 부르기 전에 `team.size`에 따른 참여 인원을 먼저 알리고, 자기에게 정해진
  게이트만 정해진 단계에서 호출합니다. 디렉터 리뷰는 팀 규모 때문에 빠지지 않습니다.
- `/hotfix`는 표면에 따라 경로를 고릅니다. 웹·API는 킬 스위치나 되돌리기로 먼저 완화한 뒤 트렁크에서
  수정을 내보내고, 모바일 앱은 서버 쪽에서 먼저 완화한 뒤 릴리스 태그에서 브랜치를 따 긴급 심사와 단계적 출시로
  내보냅니다. 인시던트와 연결되어 있으면 `/postmortem <INC-id>`로, 아니면 `/retrospective release <version>`으로
  넘깁니다.

#### 디렉터 게이트

- 게이트 ID 접두사는 이제 소유 에이전트를 나타냅니다: `PD-`(product-director), `TD-`(technical-director),
  `DM-`(delivery-manager), `DD-`(design-director), `TL-`(tech-lead), `QL-`(qa-lead), `SE-`(security-engineer),
  `SR-`(sre-engineer). 게이트는 모두 29개입니다.
- 업스트림 대응: CD-PILLARS → `PD-PRINCIPLES`, CD-GDD-ALIGN → `PD-PRD-ALIGN`, CD-SYSTEMS → `PD-FEATURE-MAP`,
  CD-PLAYTEST → `PD-USER-VALIDATION`, CD-PHASE-GATE → `PD-PHASE-GATE`, TD-SYSTEM-BOUNDARY → `TD-DOMAIN-BOUNDARY`,
  TD-ENGINE-RISK → `TD-STACK-RISK`, PR-SCOPE·PR-SPRINT·PR-MILESTONE·PR-EPIC·PR-PHASE-GATE → `DM-SCOPE`·`DM-SPRINT`·
  `DM-MILESTONE`·`DM-EPIC`·`DM-PHASE-GATE`, AD-CONCEPT-VISUAL → `DD-BRAND-DIRECTION`, AD-ART-BIBLE →
  `DD-DESIGN-LANGUAGE`, AD-VISUAL → `DD-UI-CONSISTENCY`, AD-PHASE-GATE → `DD-PHASE-GATE`, LP-FEASIBILITY →
  `TL-FEASIBILITY`, LP-CODE-REVIEW → `TL-CODE-REVIEW`. `TD-FEASIBILITY`, `TD-ARCHITECTURE`, `TD-ADR`,
  `TD-PHASE-GATE`, `TD-MANIFEST`, `TD-CHANGE-IMPACT`, `QL-STORY-READY`, `QL-TEST-COVERAGE`는 이름이 같습니다.
- 호출하는 스킬이 없던 게이트를 실제로 연결했습니다. `TD-STACK-RISK`는 `/architecture-decision`(Knowledge Risk가
  HIGH나 MEDIUM일 때)과 `/setup-stack`의 `upgrade` 모드가, `DD-UI-CONSISTENCY`는 `/ux-review`와 `/team-ui`가,
  `QL-TEST-COVERAGE`는 `/story-done`과 `/team-qa`가 부릅니다. 이제 모든 게이트에 호출하는 스킬이 있습니다.
- `DM-SCOPE`의 중간 판정은 `CONCERNS`입니다. 업스트림의 OPTIMISTIC 판정은 이를 처리하는 스킬이 없었습니다.
- **lean 모드 규칙**: 게이트 ID를 하나하나 나열하던 목록 대신 "ID가 `-PHASE-GATE`로 끝나지 않는 게이트는 모두
  건너뛴다"는 접미사 규칙 하나로 정했습니다. 새 게이트를 추가해도 목록을 고칠 필요가 없습니다.
- **기본값 문장 통일**: 기본값을 적는 모든 곳이 같은 문장을 씁니다 — "Unset on an unconfigured project:
  `modes.rigor` defaults to `minimal`, which resolves `review_mode` to `solo`."
- `/gate-check`의 디렉터 패널 너비는 `modes.workflow`를 따르고(1·2·4명), 표는 `/gate-check` 한 곳에만 있습니다.
  UI 표면이 없는 프로젝트에서는 `DD-PHASE-GATE`를 생략하고 생략했다고 밝힙니다.

#### 문서 체계

| 업스트림 문서 | CCSS 문서 | 경로 |
|---|---|---|
| 게임 컨셉 문서 | 제품 브리프(`standard`, `full`) | `design/product/product-brief.md` |
| 게임 브리프 | one-pager(`minimal`) | `design/product/one-pager.md` |
| 시스템 인덱스 | 기능 맵 | `design/product/feature-map.md` |
| GDD | 기능별 PRD | `design/prd/<feature>.md` |
| 아트 바이블 | 디자인 언어 | `design/brand/design-language.md` |
| HUD 설계 | 앱 셸 | `design/ux/app-shell.md` |
| 플레이어 여정 | 사용자 여정 | `design/product/user-journey.md` |
| 버티컬 슬라이스 보고서 | 워킹 스켈레톤 보고서 | `production/walking-skeleton/report-YYYY-MM-DD.md` |
| 패치 노트 | 릴리스 노트 | `production/releases/<version>/release-notes.md` |
| 데이원 패치 계획 | 롤아웃 계획 | `production/releases/<version>/rollout-plan.md` |
| 플레이테스트 보고서 | 사용성 테스트 보고서 | `production/qa/usability/` |
| 소크 테스트 | 부하 테스트(`soak` 프로필 포함) | `production/qa/load/` |
| 프로젝트 사후 분석 템플릿 | 프로젝트 회고 템플릿 | `.claude/docs/templates/project-retrospective.md` |

- **PRD는 11개 계약 섹션**입니다: `Overview`, `Goals & Non-Goals`, `User Value`, `Functional Requirements`,
  `Business Rules & Calculations`, `Edge Cases`, `Dependencies`, `Non-Functional Requirements`,
  `Configuration & Flags`, `Success Metrics & Instrumentation`, `Acceptance Criteria`. `full`은 11개 모두,
  `standard`는 8개(Goals & Non-Goals, 비기능 요구사항, 성공 지표 포함)와 숫자·정책 규칙이 있을 때의 Business
  Rules & Calculations, `minimal`은 PRD 없이 one-pager로 갑니다. 목표·비목표, 비기능 요구사항, 성공 지표는
  서비스 PRD가 가장 자주 빠뜨리는 곳이라 `standard`에서도 필수로 두었습니다.
- PRD의 `## Dependencies`는 `| Feature | PRD | Direction | Nature |` 표로 적고, `review-scope.sh`가 이 표에서
  의존 관계를 읽습니다. PRD 리뷰 기록은 `design/prd/reviews/`에 모아 `design/prd/`에는 PRD만 남깁니다.
- `/write-prd`가 트래킹 플랜 `design/product/tracking-plan.md`에 이벤트를 덧붙이고, 요금·플랜·크레딧을 정의하는
  PRD라면 `design/product/pricing-model.md`를 만들거나 갱신합니다.
- **ADR 헤딩**: `## Stack Compatibility`, `## Performance & SLO Implications`,
  `## Security & Privacy Implications`, `## Cost Implications`, `## PRD Requirements Addressed`가 생겼습니다.
  `/architecture-decision`은 템플릿 파일을 그대로 복사하고, 스킬 안에 따로 골격을 두지 않습니다.
- **스토리 헤더**: `> **Surface**:`, `> **Type**:`(Logic, Integration, UI, E2E, Config)과 `**API Contract**`,
  `**Migration**`, `**Feature Flag**`, `**Analytics Events**` 필드가 생겼습니다. 스프린트 상태는 `backlog`,
  `ready-for-dev`, `in-progress`, `review`, `done`, `blocked`로 정해져 있습니다.
- **테스트 증거**: `testing.strict`의 키는 `logic`, `integration`, `ui`, `e2e`, `config`입니다(계약 테스트는
  integration, 시각 회귀는 ui에 포함). 마이그레이션이 있는 스토리는 `qa.level`과 관계없이 일회용 DB에서 한
  드라이런 로그(`migration-dry-run.log`)가 있어야 완료됩니다. "타입 검사나 빌드는 실행이 아니다" — 사용자가 볼
  수 있는 것을 바꾼 스토리는 띄워서 확인하고, 그 증거를 `production/qa/evidence/`에 남깁니다.
- **심각도**: 버그는 `S1-Critical`~`S4-Trivial`, 인시던트는 `SEV1`~`SEV4`로 나눴습니다. "미해결 버그"의 정의는
  한 곳에서 정하고 모든 게이트와 훅이 같은 정의를 씁니다.
- **레지스트리**: `design/registry/entities.yaml`은 `entities`, `plans`, `rules`, `constants`, `events` 섹션,
  `docs/registry/architecture.yaml`은 `data_ownership`, `interfaces`, `slo_budgets`, `technology_decisions`,
  `forbidden_patterns` 섹션을 씁니다. `docs/architecture/tr-registry.yaml`은 `prd:` 필드와
  `TR-<feature>-NNN` ID를 씁니다.

#### 설정

- `engine.*`는 `stack.*`로, `platform.cert_tier`는 `release.distribution`으로, `project.genre`는
  `project.category`로 바뀌었습니다. `workflow_overrides`의 하위 키는 `feature_overrides.<prd-stem>`,
  `config_flags`, `design_language_strict`, `edge_cases`입니다. `specialists.*`는 `web`, `mobile`, `backend`
  세 키로 정리했습니다.
- `resolve_config` 라벨: 스택은 `stack`, 배포 방식은 `distribution`, 기능별 티어 예외는 `feature_overrides`로
  읽습니다.
- `accessibility.target`이 실제로 동작합니다. 값은 `none`, `wcag-a`, `wcag-aa`, `wcag-aaa`(WCAG 2.2)이고,
  한국의 KWCAG 같은 지역 기준은 `compliance.regions`로 더합니다. 설정하지 않은 것은 `none`과 다르게 취급합니다.
- 설정 해석 순서는 `project.local.yaml`(허용된 키만) → `project.yaml` → `modes.rigor` 확장 → 기본값입니다.
- `modes.automation_always_ask`의 범주를 서비스 기준으로 새로 정했습니다. 기본으로 항상 묻는 9개 범주는
  `scope_changes`, `file_deletions`, `schema_changes`, `production_deploys`, `db_migrations`, `infra_changes`,
  `secrets_access`, `pii_data_access`, `billing_changes`이고, `architecture_decisions`, `version_bumps`,
  `external_calls`를 더해 모두 12개 범주를 인식합니다.
- 상태 표시줄은 `stage-estimate.sh`로 단계를 보여 주고, rigor가 설정되지 않았을 때 `minimal`을 표시합니다.
  세션 시작 훅은 `review_mode`를 추측한 값으로 채우지 않고, 미해결 버그 수와 스택 레퍼런스 상태를 보여 줍니다.

#### 규칙·훅·스크립트·템플릿 정리

- 규칙 이름: ai-code → `ai-integration.md`, design-docs → `prd-docs.md`, engine-code → `platform-code.md`,
  gameplay-code → `domain-logic.md`, narrative → `content-copy.md`, network-code → `api-code.md`, shader-code →
  `styles-code.md`. 규칙은 모두 16개입니다.
- 훅: validate-assets → `validate-data-files.sh`. 훅 파일은 14개, `settings.json`에 등록된 훅은 12개입니다.
- 스크립트: gdd-structure-check → `prd-structure-check.sh`, 그리고 새 `stage-estimate.sh`. 스크립트는 모두
  8개입니다.
- 템플릿은 46개에서 56개가 되었습니다. 제품 브리프, one-pager, PRD, 기능 맵, 페르소나, 사용자 흐름, 보이스·톤,
  요금 모델, 앱 셸, 사용자 여정, 워킹 스켈레톤 보고서 등은 서비스 기준으로 새로 썼습니다.

#### 업스트림에서 이어받은 결함 수정

- 스프린트 상태 표기가 스킬마다 달라(밑줄과 하이픈) 서로의 결과를 읽지 못하던 문제를 `in-progress` 하나로
  통일했습니다.
- 에픽 문서와 에픽 인덱스만 있어도 "스토리 작성 완료"로 판정되던 카탈로그 검사를, 스토리 파일(`story-*.md`)만
  세도록 고쳤습니다.
- 테스트 증거가 gitignore된 `production/session-logs/`에 쓰여 다음 사람에게 존재하지 않던 문제를 없앴습니다.
  증거는 이제 추적되는 `production/qa/…` 아래에만 씁니다.
- 버그 파일 이름을 `production/qa/bugs/BUG-NNNN.md` 하나로 통일했습니다. `/team-qa`는 스모크 보고서가 없으면
  통과가 아니라 `NOT ASSESSED`로 판정합니다.
- `/perf-profile`이 보고서를 쓸 권한이 없던 문제, `/architecture-decision accept`가 막힌 스토리를 잘못된 패턴으로
  찾던 문제, ADR 인라인 골격이 템플릿과 달랐던 문제를 고쳤습니다.
- 서로 다른 기본값 설명 네 가지가 공존하던 문제를 한 문장으로 정리했고, `/adopt`와 `/sprint-plan`이
  `modes.review_mode`를 써 버리던 동작을 없앴습니다. 이 키는 `/settings`만 씁니다.
- 템플릿에 들어 있던 빈 코드 루트 디렉터리 때문에 새로 클론한 저장소에서 코드 루트 검사가 거짓으로 통과하던
  문제를 없앴습니다.
- 훅 입력 스키마 문서의 오류를 바로잡았고, 문서에만 있던 커밋 메시지 형식 검사를 실제 경고로 구현했습니다.
- `/security-audit`과 `/localize`는 출시 요건이라고 안내했지만 출시 게이트는 이를 확인하지 않았습니다. 이제
  출시 게이트가 보안 감사와, 로케일이 둘 이상이면 현지화 QA를 실제로 요구합니다.
- 프로토타입 산출물을 `REPORT.md`(컨셉)와 `SPIKE-NOTE.md`(스파이크)로 통일해, 스킬·규칙·세션 훅이 서로 다른
  파일을 찾던 문제를 없앴습니다.
- `/retrospective`가 `release <version>`을 받게 되어, 핫픽스와 롤아웃 뒤의 회고 연결이 끊기지 않습니다.
- `/release-notes`는 아무도 쓰지 않는 파일 대신 `/changelog`가 쓰는 `docs/CHANGELOG.md`를 읽습니다.
- `/skill-test audit`이 에이전트도 파일 목록으로 열거하므로, 카탈로그에 없는 에이전트가 검사를 피해 가지
  않습니다.
- 현재 단계를 추정하던 네 가지 다른 로직을 `stage-estimate.sh` 하나로 합쳤습니다.
- 디렉터 패널 너비 표가 네 곳에 흩어져 서로 달랐던 문제, `/qa-plan`의 인라인 템플릿이 `test-plan.md`와 달랐던
  문제를 한 곳의 원본으로 정리했습니다.
- `run-and-observe.md`가 `/test-setup`이 캡처 스크립트를 만든다고 주장했지만 실제로는 만들지 않던 문제를, 웹에
  한해 실제로 만들도록 해 사실로 바꿨습니다.
- `/help`의 두 번째 `!` 주입(권한 검사가 거부하던 형태)을 없앴습니다.
- 세션 시작 훅이 `<milestone>-review.md`를 활성 마일스톤으로 고르던 문제를 고쳤습니다.
- `validate-commit.sh`가 티어를 알 수 없을 때 `standard`로 가정하던 동작을 없애고 `NOT CHECKED`를 출력합니다.
- 스킬 테스트 프레임워크의 `results/` 폴더가 실제로 gitignore됩니다.

### 삭제

- **서비스에 대응하는 역할이 없는 에이전트 6개**: audio-director, narrative-director, level-designer,
  sound-designer, world-builder, network-programmer. 실시간 동기화는 `backend-engineer`와 `mobile-engineer`가
  맡습니다.
- **엔진 스페셜리스트 15개**(Godot, Unity, Unreal 계열 각 5개)와 `docs/engine-reference/`. 스택 에이전트는 이를
  옮긴 것이 아니라 처음부터 새로 썼습니다.
- **스킬** team-audio, team-level.
- **게이트** CD-NARRATIVE, ND-CONSISTENCY. 호출하는 스킬이 없던 게이트이고, 목적은 `DD-CONTENT-VOICE`로
  합쳤습니다.
- **템플릿** difficulty-curve.md(활성화 곡선은 사용자 여정에서 다룹니다), game-pillars.md(제품 브리프의
  `## Product Principles & Anti-Goals`로 합쳤습니다), sound-bible.md.
- **v1 레거시 설정 계층 전체**: production/stage.txt, production/review-mode.txt,
  .claude/docs/technical-preferences.md(명명 규칙은 `naming.*`, 성능 예산은 `performance.*`, 금지 패턴과 허용
  라이브러리는 테크 레이더로 옮겼습니다), migrate-v1-config.sh, docs/migration-guide-v1.1.md, `/adopt`의 v1
  마이그레이션 단계, 세션 시작 시의 레거시 파일 검사. 설정을 해석하는 경로가 절반으로 줄었습니다.
- **고정 코드 루트** `src/`(src/.gitkeep, src/CLAUDE.md). 템플릿은 코드 루트 디렉터리를 싣지 않습니다.
- **게임 전용 설정 키**: `engine.*` 전체, `platform.targets`, `platform.primary_input`,
  `platform.gamepad_support`, `platform.touch_support`, `platform.multiplayer`, `platform.online`,
  `performance.target_framerate`, `performance.frame_budget_ms`, `performance.draw_call_limit`,
  `performance.memory_ceiling_mb`, `naming.signals`, `naming.scenes`, `strict_gate_checks`, `project.kind`.
- validate-assets 훅의 `assets/` 파일 이름 규칙(웹의 명명 관례와 충돌했습니다).
- `.github/FUNDING.yml`과 업스트림의 후원 배지·링크.
- 업스트림의 이전 버전 이력. 이 파일과 [UPGRADING.md](UPGRADING.md)에는 옮기지 않았습니다.

### 알려진 제한 사항

- **업스트림으로 만든 프로젝트는 옮겨 올 수 없습니다.** 변환기를 제공하지 않습니다. 이유와 대안은
  [UPGRADING.md](UPGRADING.md)에 적었습니다.
- **스택 레퍼런스는 빈 상태로 배포됩니다.** `/setup-stack`을 실행하기 전에는 스택 에이전트가 버전에 민감한
  질문에 `NOT SOURCEABLE`로 답합니다. 의도한 동작입니다.
- **컴플라이언스 점검 목록은 법률 자문이 아닙니다.** 무엇을 확인해야 하는지 알려 줄 뿐, 해당 여부의 판단과 최신
  규정 확인은 전문가와 공식 기관의 몫입니다.
- **설정 엔진의 테스트 스위트는 이 버전에 포함되어 있지 않습니다.** 존재하지 않는 테스트를 인용하던 문서
  문구는 모두 지웠습니다.
- **스킬 frontmatter의 `model:`은 선언일 뿐 적용되지 않습니다.** Claude Code는 이 값을 읽지만 스킬은 세션
  모델로 실행됩니다(`.claude/docs/model-tiers.md`). 에이전트의 `model:`은 별개의 메커니즘입니다.
- **아직 아무것도 읽지 않는 예약 설정**: `qa.coverage_minimum`, `cadence.sprint_length`,
  `cadence.milestone_length`, `features.token_budget_warn_at`. 값을 저장하고 검증은 하지만 동작에는 영향이
  없고, `/settings`로 보거나 바꿀 때 예약 설정이라고 알려 줍니다.
