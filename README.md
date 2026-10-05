<p align="center">
  <h1 align="center">Claude Code Service Studios</h1>
  <p align="center">
    웹·모바일·API 서비스 개발을 실제 제품 조직처럼 운영하는 Claude Code 템플릿입니다.
    <br />
    에이전트 46개, 스킬 77개, 하나로 조율되는 AI 제품 팀.
  </p>
</p>

<p align="center">
  <a href="CHANGELOG.md"><img src="https://img.shields.io/badge/version-0.1.0-informational" alt="Version 0.1.0"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT License"></a>
  <a href=".claude/agents"><img src="https://img.shields.io/badge/agents-46-blueviolet" alt="46 Agents"></a>
  <a href=".claude/skills"><img src="https://img.shields.io/badge/skills-77-green" alt="77 Skills"></a>
  <a href=".claude/hooks"><img src="https://img.shields.io/badge/hooks-12-orange" alt="12 Hooks"></a>
  <a href=".claude/rules"><img src="https://img.shields.io/badge/rules-17-red" alt="17 Rules"></a>
  <a href=".claude/docs/templates"><img src="https://img.shields.io/badge/templates-57-lightgrey" alt="57 Templates"></a>
  <a href=".claude/docs/director-gates"><img src="https://img.shields.io/badge/director%20gates-29-yellow" alt="29 Director Gates"></a>
  <a href="https://docs.anthropic.com/en/docs/claude-code"><img src="https://img.shields.io/badge/built%20for-Claude%20Code-f5f5f5?logo=anthropic" alt="Built for Claude Code"></a>
</p>

---

## 왜 필요한가

AI와 함께 서비스를 만드는 일은 강력하지만, 채팅 세션 하나에는 구조가 없습니다. 요금제 가격이나 사용 한도를
코드에 박아 넣어도, PRD 없이 화면부터 만들어도, 되돌릴 방법 없는 마이그레이션을 배포해도 아무도 막지 않습니다.
보안 리뷰도, 롤백 계획도, "이 기능이 정말 사용자의 문제를 푸는가?"라고 묻는 사람도 없습니다.

**Claude Code Service Studios**는 AI 세션에 실제 제품 조직의 구조를 줍니다. 범용 어시스턴트 하나 대신
제품 조직처럼 배치된 에이전트 46개가 생깁니다. 방향과 품질 기준을 지키는 디렉터, 자기 영역을 책임지는 리드,
실제 작업을 수행하는 스페셜리스트, 그리고 선택한 기술 스택을 깊이 아는 스택 스페셜리스트입니다. 각 에이전트에는
책임 범위와 에스컬레이션 경로가 정해져 있고, 주요 결정 지점에는 디렉터 게이트가 있습니다.

결정은 여전히 사용자가 내립니다. 달라지는 점은 올바른 질문을 던지고, 실수를 일찍 잡아내고, 첫 브레인스토밍부터
출시와 그 이후의 운영까지 프로젝트를 정리된 상태로 유지해 주는 팀이 생긴다는 것입니다.

---

## 목차

- [구성 요소](#구성-요소)
- [7단계 파이프라인](#7단계-파이프라인)
- [조직도](#조직도)
- [빠른 시작](#빠른-시작)
- [설정](#설정)
- [한국 시장 옵션](#한국-시장-옵션)
- [자동 안전장치: 훅, 스크립트, 권한](#자동-안전장치-훅-스크립트-권한)
- [경로별 코딩 규칙](#경로별-코딩-규칙)
- [프로젝트 구조](#프로젝트-구조)
- [작동 방식](#작동-방식)
- [커스터마이징](#커스터마이징)
- [플랫폼 지원](#플랫폼-지원)
- [업그레이드와 기여](#업그레이드와-기여)
- [업스트림 크레딧](#업스트림-크레딧)
- [라이선스](#라이선스)

---

## 구성 요소

| 구분 | 개수 | 설명 |
|------|------|------|
| **에이전트** | 46 | 제품, 디자인, 엔지니어링, 품질, 운영, 기술 스택 영역의 전문 서브에이전트 (`.claude/agents/`) |
| **스킬** | 77 | 단계별 슬래시 명령 (`/start`, `/brainstorm`, `/write-prd`, `/api-design`, `/dev-story`, `/rollout-plan`, `/incident` 등) |
| **훅** | 12개 등록 (파일 14개) | 커밋·푸시 검증, 데이터 파일 파싱, 세션 수명주기, 에이전트 감사 로그, 공백 탐지. 파일 14개 중 나머지 둘은 설정 해석 라이브러리 `yaml-helper.sh`와 선택형 진단 훅 `log-instructions.sh`입니다 |
| **스크립트** | 8 | 관측 결과만 출력하고 판정은 하지 않는 보조 스크립트 (`.claude/scripts/`) |
| **규칙** | 17 | 파일 경로에 따라 자동 적용되는 코딩 표준 (API, 도메인 로직, UI, 모바일, 마이그레이션, 인프라 등) |
| **템플릿** | 57 | PRD, ADR, API 가이드라인, 데이터 모델, 위협 모델, SLO, 런북, 롤아웃 계획, 포스트모템 등 문서 템플릿 |
| **디렉터 게이트** | 29 | 디렉터·리드·보안·SRE가 주요 산출물을 검토하는 게이트 정의 (`.claude/docs/director-gates/`) |

## 7단계 파이프라인

모든 프로젝트는 아래 일곱 단계를 거칩니다. 단계 정의의 원본은 `.claude/docs/workflow-catalog.yaml`이며,
`/help`가 이 파일을 읽어 지금 해야 할 일을 알려 줍니다. 두 번째 단계부터는 `/gate-check <목표 단계>`로 진입
준비 상태를 점검합니다. 게이트 판정은 **권고**이며, 진행 여부는 언제나 사용자가 결정합니다.

| # | 단계 (`project.stage`) | 무엇을 하나 | 진입 게이트 |
|---|---|---|---|
| 1 | `Discovery` (탐색) | 문제·사용자·JTBD·가치 제안을 정리하고, 이미 정해진 스택 레이어의 버전을 고정합니다 | — (시작 단계) |
| 2 | `Definition` (기획) | 제품을 기능으로 나누고(기능 맵), MVP 기능마다 PRD를 씁니다 | `/gate-check definition` |
| 3 | `Architecture` (아키텍처) | 아키텍처 문서와 SLO, ADR, 초기 API 계약, 데이터 모델, 위협 모델, 접근성 기준, 테스트·CI 스캐폴드 | `/gate-check architecture` |
| 4 | `Validation` (검증) | 디자인 언어, 핵심 화면 UX 명세, UX에 맞춘 API 계약 조정, 에픽·스토리, 첫 스프린트, 스테이징에 배포된 **워킹 스켈레톤**(Sprint 0) | `/gate-check validation` |
| 5 | `Build` (구축) | 스프린트 단위로 스토리를 구현·검증·완료합니다 | `/gate-check build` |
| 6 | `Hardening` (안정화) | 성능·부하·보안·접근성·사용성 점검, QA 사인오프, 런북, 릴리스 준비 | `/gate-check hardening` |
| 7 | `Launch` (출시) | 출시와 운영, 그리고 이후의 모든 릴리스 (종착 단계 — 다음 게이트 없음) | `/gate-check launch` |

`/gate-check`의 인자는 언제나 **들어가려는 단계**입니다. 예를 들어 `/gate-check architecture`는
Definition → Architecture 전환을 점검합니다. `Launch`는 종착 단계이므로, 출시 후에는 게이트 대신
릴리스마다 `production/releases/<version>/`에 기록 세트(릴리스 체크리스트, 롤아웃 계획, 릴리스 노트,
릴리스 기록)를 남기는 방식으로 지속 전달을 추적합니다. 단계별 상세 절차는
[docs/WORKFLOW-GUIDE.md](docs/WORKFLOW-GUIDE.md), 스킬 흐름도는
[docs/skill-flow-diagrams.md](docs/skill-flow-diagrams.md)에 있습니다.

## 조직도

에이전트는 실제 서비스 회사의 제품 조직처럼 디렉터 → 리드 → 스페셜리스트로 배치되고, 여기에 기술 스택별
스페셜리스트 패밀리가 붙습니다. 괄호 안은 한국 스타트업에서 흔히 쓰는 직함입니다.

```text
디렉터 (4)
  product-director (CPO/프로덕트 디렉터)   technical-director (CTO/기술 디렉터)
  delivery-manager (PjM/딜리버리 매니저)   design-director (디자인 디렉터 — 게이트 패널의 네 번째 자리)

리드
  product-manager (PM/PO, 서비스 기획)     tech-lead (테크 리드)
  qa-lead (QA 리드)                        release-manager (릴리스 매니저)
  localization-lead (현지화 리드)

스페셜리스트
  제품      business-analyst (서비스·정책 기획자)  monetization-strategist (가격·수익화 전략)
            analytics-engineer (데이터 분석·트래킹)  prototyper (프로토타이퍼)
            growth-manager (그로스 매니저)          customer-success-manager (CS/CX 매니저)
  디자인    product-designer (프로덕트 디자이너)   ux-researcher (UX 리서처)
            ux-writer (UX 라이터)                  design-engineer (디자인 엔지니어)
            accessibility-specialist (접근성 전문가)
  엔지니어링 backend-engineer   frontend-engineer   mobile-engineer   platform-engineer
            internal-tools-engineer (어드민·운영툴)  ml-engineer   data-engineer
            performance-engineer (성능 엔지니어)
  품질·보안 qa-engineer (QA 엔지니어, SDET)        security-engineer (보안 엔지니어)
  운영      devops-engineer (데브옵스)              sre-engineer (SRE)

스택 패밀리 (technical-director 산하, 리드 5 + 하위 9)
  web-specialist      → nextjs-specialist, vue-nuxt-specialist
  mobile-specialist   → react-native-specialist, flutter-specialist, ios-specialist, android-specialist
  backend-specialist  → node-specialist, spring-specialist, python-specialist
  data-specialist     (OLTP 데이터베이스, 캐시, 큐, 마이그레이션 도구)
  cloud-specialist    (AWS / GCP / Azure / NCP, Vercel / Fly / Cloudflare, Kubernetes, IaC)
```

스택 스페셜리스트는 `project.yaml`의 `stack.layers.<layer>.framework` 값에 따라 자동으로 선택됩니다.
예를 들어 웹 프레임워크가 Next.js이면 `web-specialist` → `nextjs-specialist`, 백엔드가 Spring Boot이면
`backend-specialist` → `spring-specialist`로 연결됩니다. 설정되지 않은 레이어의 스페셜리스트는 호출되지 않고,
스킬이 그 사실을 `NOT CHECKED` 줄로 알립니다.

각 에이전트는 frontmatter에 모델을 선언합니다. 디렉터 셋(`product-director`, `technical-director`,
`delivery-manager`)은 Opus를, `tech-lead`·`prototyper`와 스택 하위 스페셜리스트 9개는 Sonnet을 지정하고,
나머지 32개는 **세션 모델을 그대로 상속**합니다. 이 구분은 역할의 무게를 나타낼 뿐 비용 계획이 아닙니다.
에이전트 전체 목록과 책임 범위는 [.claude/docs/agent-roster.md](.claude/docs/agent-roster.md)에 있습니다.

## 빠른 시작

### 준비물

- [Git](https://git-scm.com/)
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code)
- **Python 3** (필수 — 설정이 필요한 스킬은 모두 첫 줄에서 `yaml-helper.sh`로 `project.yaml`을 읽고, `/help`·`/gate-check`의 산출물
  점검과 훅의 JSON/YAML 검증도 Python을 씁니다. 없으면 모든 설정이 기본값으로 돌아갑니다. PyYAML이 있으면 YAML을 완전
  파싱하고, 없으면 구조 검사로 대신하면서 `NOT CHECKED` 줄로 알립니다)
- **권장**: [jq](https://jqlang.github.io/jq/) (훅 입력 파싱. 없으면 grep으로 대신합니다)
- **선택**: 사용하는 스택에 따라 Node.js와 pnpm, Docker, Playwright 브라우저, Xcode·Android SDK와 adb, k6

설치 세부 사항은 [.claude/docs/setup-requirements.md](.claude/docs/setup-requirements.md)를 참고하세요. 선택 도구가
없어도 훅은 멈추지 않습니다. 해당 검증을 건너뛰고 건너뛴 사실을 출력할 뿐입니다.

### 설치와 첫 실행

1. **이 저장소를 클론하거나 템플릿으로 새 저장소를 만듭니다.**
   ```bash
   git clone https://github.com/ababqq/claude-code-service-studios my-service
   cd my-service
   ```

2. **Claude Code 세션을 엽니다.**
   ```bash
   claude
   ```
   세션이 열리면 `session-start.sh`가 `Claude Code Service Studios` 배너와 함께 브랜치, 최근 커밋, 현재 단계를
   보여 줍니다.

3. **`/start`를 실행합니다.** 지금 어디에 있는지(A 아이디어 없음, B 문제 영역만 있음, C 제품 컨셉이 분명함,
   D 기존 제품·코드베이스 있음)를 묻고 알맞은 흐름으로 안내합니다. `/start`가 쓰는 설정은
   `project.stage`, `modes.rigor`, `modes.automation` 세 가지뿐입니다.

4. **일반적인 흐름**은 다음과 같습니다(`standard`·`full` 기준. `minimal`이면 `/brainstorm` → `/setup-stack` →
   `/create-stories` → `/dev-story` 네 단계로 코드에 들어갑니다).
   ```text
   /start → /brainstorm → /setup-stack → /prd-review (브리프) → /prototype (선택) → /gate-check definition
          → /map-features → /write-prd → /prd-review → /gate-check architecture
          → /create-architecture → /architecture-decision → /api-design → /data-model → /test-setup
          → … → /walking-skeleton → /gate-check build → /dev-story → /story-done → …
   ```
   어디서 막히든 `/help`를 실행하면 현재 단계와 산출물을 읽고 다음 필수 단계를 알려 줍니다. 이미 코드가 있는
   프로젝트라면 `/start`의 D를 고르거나 바로 `/adopt`를 실행하세요.

## 설정

저장소 루트의 `project.yaml`이 프로젝트 설정의 유일한 원본입니다. `/start`가 단계와 프로세스 강도·자동화 모드를,
`/setup-stack`이 스택과 배포 채널·규제 지역·로케일을 씁니다. 그 밖의 키는 해당 스킬이 묻고 씁니다(`/brainstorm`은
`project.name`, `/ux-design accessibility`는 `accessibility.target`, `/setup-stack`·`/design-handoff`는
`design.tool`(`claude-design`, `figma`, `none` — 설정하지 않으면 묻습니다), `/test-setup`은 `testing.*`·`commands.*` 등).
값을 직접 바꿀 때는 `/settings`를 씁니다. 파일을 손으로 편집할 일은 거의 없습니다.

### 프로세스 강도: `modes.rigor`

가장 중요한 질문은 **`modes.rigor`**(`minimal`, `standard`, `full`) 하나입니다. 이 값이 여섯 개의 세부 설정
(`modes.workflow`, `docs.density`, `qa.level`, `modes.story_granularity`, `modes.review_mode`, `team.size`)을
한꺼번에 결정하므로, `/start`는 여섯 번 대신 한 번만 묻습니다.

| `modes.rigor` | 이런 팀에 맞습니다 | 기획 산출물 | 리뷰 모드 |
|---|---|---|---|
| `minimal` (기본값) | 해커톤, 프로토타입, 사이드 프로젝트 | 한 장짜리 one-pager가 기획서를 대신합니다 | `solo` (디렉터 게이트 생략) |
| `standard` | 시드·시리즈 A 단계의 제품 팀, 앱스토어 출시 | 제품 브리프 + 기능 맵 + PRD(필수 8개 섹션과 조건부 섹션) | `lean` (단계 게이트만) |
| `full` | 핀테크·헬스케어처럼 규제가 있는 서비스, SLA가 있는 B2B·엔터프라이즈 | PRD 11개 섹션 전체와 모든 산출물 | `full` (모든 디렉터 게이트) |

설정하지 않은 프로젝트에서는 `modes.rigor`가 `minimal`로 해석되고, 그 결과 `review_mode`는 `solo`가 됩니다.
프로젝트가 커지면 `/settings modes.rigor=standard` 한 번으로 올리면 됩니다. `/help`와 `/gate-check`가 그럴
시점의 신호를 보면 먼저 제안합니다.

세부 설정을 개별로 바꿀 수도 있습니다(예: `modes.workflow: full`에 `docs.density: terse` — 빠짐없이, 그러나 짧게).
단, 여섯 개 세부 설정을 `project.yaml`에 직접 적으면 그 값이 고정되어 `modes.rigor`를 바꿔도 따라오지 않으니
주의하세요.

### 한 기능만 더 엄격하게, 테스트 유형별로 다르게

- **`workflow_overrides.feature_overrides.<prd-stem>`** — 특정 기능 하나만 더 높은 티어로 다룹니다. 예를 들어
  나머지는 `standard`로 두고 결제 기능(`design/prd/payments.md`)만 `full`로 관리할 수 있습니다.
- **`testing.strict`** — 테스트 유형 다섯 가지(`logic`, `integration`, `ui`, `e2e`, `config`)마다 증거가 없을 때
  스토리 완료를 막을지(`true`) 경고만 할지(`false`) 정합니다.

### 스택: `stack.*`

`/setup-stack`이 레이어(web, mobile, backend, data, cloud)별로 프레임워크·언어·런타임·코드 루트를 묻고, 각
구성 요소의 현재 안정 버전을 Context7 또는 웹 검색 같은 실시간 출처에서 확인해 고정합니다. 출처를 찾지 못한
버전은 추측하지 않고 `NOT DETERMINED`로 적은 뒤 사용자에게 수용 여부를 묻습니다. 아래는 웹·모바일·API를 함께
운영하는 모노레포의 예시입니다. **버전 숫자는 형식을 보여 주기 위한 예시일 뿐**이며, 실제 값은 `/setup-stack`이
출처와 함께 기록합니다.

```yaml
stack:
  pinned_on: 2026-09-27          # 설정된 모든 구성 요소의 출처가 확인되면 마지막에 기록됩니다
  monorepo: true
  package_manager: pnpm
  shared_roots: [packages]
  layers:
    web:
      framework: Next.js
      version: "15.3"
      language: TypeScript
      root: [apps/web, apps/admin]
    mobile:
      framework: React Native (Expo)
      version: "0.79"
      language: TypeScript
      root: apps/mobile
    backend:
      framework: NestJS
      version: "11.0"
      language: TypeScript
      runtime: Node.js 22
      root: [apps/api, services/worker]
    data:
      database: PostgreSQL 16
      cache: Redis 7
      orm: Prisma 6
      migrations_dir: apps/api/prisma/migrations
    cloud:
      provider: AWS
      iac: Terraform 1.9
      root: infra
platform:
  surfaces: [web, ios, android, api]
release:
  distribution: web+stores
```

아직 정하지 않은 레이어는 비워 둬도 됩니다. Discovery 단계에서는 이미 결정된 레이어(보통 웹·모바일·백엔드
프레임워크)만 고정하고, 데이터와 클라우드 레이어는 해당 ADR이 채택된 뒤 `/setup-stack refresh`로 추가합니다.

코드 루트는 고정되어 있지 않습니다. 레이어마다 `stack.layers.<layer>.root`에 경로 하나 또는 경로 목록을 선언하며,
선언되지 않은 `apps/*`, `services/*`, `packages/*` 작업 공간은 `undeclared`로 보고됩니다. 상세 규칙은
`.claude/docs/code-root-resolution.md`에 있습니다.

### 설정 보기와 바꾸기

```text
/settings                                   # 병합된 유효 설정 보기
/settings modes.review_mode                 # 설정 하나 보기
/settings modes.rigor=full                  # project.yaml에 쓰기 (팀 전체)
/settings --local modes.review_mode=solo    # project.local.yaml에 쓰기 (나만, gitignore 대상)
```

`modes.review_mode`, `modes.automation`, `team.size`, `testing.strict.*`, `performance.enforce` 같은 개인 선호는
`project.local.yaml`에서 개인별로 덮어쓸 수 있습니다. 전체 스키마와 설정별 동작은 `.claude/docs/effects-map.md`에
있습니다.

### 산출물 언어

AI가 읽거나 스크립트가 파싱하는 프레임워크 파일은 영어이고, 사람이 읽는 안내 문서(이 README 포함)는 한국어입니다.
스킬이 만드는 산출물(PRD, ADR, 보고서 등)은 템플릿의 제목, 굵은 필드 이름, 판정·상태 토큰, YAML 키, ID, 경로를
영어 그대로 유지하고, 본문은 사용자가 대화하는 언어로 씁니다. 스크립트와 게이트가 제목을 기준으로 찾기 때문에
제목은 번역하지 않습니다.

## 한국 시장 옵션

한국 사용자를 대상으로 하는 서비스라면 `project.yaml`에 다음을 설정합니다(`/setup-stack`이 물어봅니다).

```yaml
compliance:
  regions: [kr]
localization:
  locales: [ko-KR, en-US]
```

`compliance.regions`에 `kr`이 있으면 관련 스킬이 `.claude/docs/compliance/kr.md` 체크리스트를 불러옵니다.

- **개인정보·보안**: 개인정보 보호법(PIPA)의 동의·목적 제한·보관·가명처리·국외 이전·유출 통지, ISMS-P 적용
  여부, 위치정보법
- **결제·커머스**: 전자상거래법의 표시 의무와 청약철회·환불, 전자금융거래법(PG·자동이체 흐름, 포인트·크레딧이
  선불전자지급수단에 해당하는지), 전기통신사업법의 인앱 결제 규정
- **마케팅 메시지**: 정보통신망법 광고성 정보 전송 규정(사전 수신 동의, 야간 전송 별도 동의, 수신 동의 여부 정기
  확인, 수신 거부 경로, 전송자 표시). 카카오 알림톡은 정보성 메시지 전용이며, 광고는 광고 수신 동의를 받은 뒤
  친구톡·브랜드 메시지로 보냅니다. `/team-growth`와 `/team-content`는 캠페인이나 메시지 문구를 승인하기 전에
  이 항목들을 하나씩 확인받습니다.
- **접근성**: 장애인차별금지법과 한국형 웹 콘텐츠 접근성 지침(KWCAG 2.2), 모바일 앱 접근성 지침
- **연동 후보**: 카카오·네이버·Apple 로그인, 토스페이먼츠, 알림톡 템플릿 승인, PASS 본인인증. `/setup-stack`은 이를
  기술 레이더의 `Assess` 링에 후보로만 기록하고 설치하지는 않습니다.

이 체크리스트는 **무엇을 확인할지** 알려 주는 목록이지 법률 자문이 아닙니다. 기한·과징금·기준치 같은 숫자는
출처 URL과 확인 날짜가 붙을 때만 적습니다. 그 밖에 한국어 글꼴 서브셋(`/bundle-audit`), `word-break: keep-all`을
포함한 한국어 조판 규칙(`/design-language`), UTC와 KST를 함께 쓰는 인시던트 타임라인(`/incident`)도 기본으로
지원합니다. EU(`eu`)와 미국(`us`) 체크리스트도 같은 방식으로 제공됩니다.

## 자동 안전장치: 훅, 스크립트, 권한

### 훅

`.claude/settings.json`에 12개 훅이 등록되어 있습니다.

| 훅 | 이벤트 | 하는 일 | 차단 여부 |
|----|--------|---------|-----------|
| `session-start.sh` | 세션 시작 | 배너, 브랜치와 최근 커밋, `review_mode`, `project.yaml` 오류, 현재 단계, 진행 중인 스프린트·마일스톤, 미해결 버그 수, TODO/FIXME 수, 세션 체크포인트 미리보기, 스택 레퍼런스 점검 | 아니요 |
| `detect-gaps.sh` | 세션 시작 | 새 프로젝트면 `/start` 안내. 코드에 비해 부족한 PRD, 보고서 없는 프로토타입, ADR 없는 코드 루트, API 계약 없는 백엔드, 데이터 모델 없는 마이그레이션, 실제 진척보다 뒤처진 `project.stage`를 알립니다 | 아니요 |
| `validate-commit.sh` | Bash 실행 전 (`git commit`만. `pnpm test && git commit`처럼 이어 붙인 명령도 포함) | **차단**: 파싱되지 않는 JSON/YAML, 스테이징된 시크릿(클라우드 액세스 키, 개인 키, GitHub·Slack 토큰, Google API 키, 결제 라이브 키), `.env`·키스토어·인증서 파일. **경고**: PRD 필수 섹션 누락, 코드에 박힌 비즈니스 값과 호스트, 담당자 없는 TODO, Conventional Commits 형식과 스토리·태스크 ID | 예 |
| `validate-push.sh` | Bash 실행 전 (`git push`만) | 보호 브랜치(`main`, `master`, `develop`, `release/*`, `production`, `prod`) 푸시 경고, 마이그레이션이 포함되면 마이그레이션 계획의 단계 확인 알림 | 아니요 |
| `validate-data-files.sh` | 파일 쓰기·수정 후 | 설정, API 계약, 로케일, 레지스트리, CI 워크플로, `project.yaml`을 쓰자마자 JSON/YAML로 파싱해 오류를 되돌려 줍니다 | 피드백 (exit 2) |
| `validate-skill-change.sh` | 파일 쓰기·수정 후 | 스킬을 바꾸면 `/skill-test static <name>`, 에이전트를 바꾸면 `/skill-test spec <name>`을 권합니다 | 아니요 |
| `pre-compact.sh` | 컨텍스트 압축 전 | 작성 중인 PRD·제품 문서·ADR·API·데이터 문서와 세션 상태를 대화에 남깁니다 | 아니요 |
| `post-compact.sh` | 컨텍스트 압축 후 | `production/session-state/active.md`에서 상태를 복원하라고 알립니다 | 아니요 |
| `notify.sh` | 알림 | Windows 토스트, macOS `osascript`, Linux `notify-send` (없으면 조용히 넘어감) | 아니요 |
| `session-stop.sh` | 응답 종료 | 세션 로그와 서브에이전트 호출 집계를 기록합니다. 이름과 달리 응답이 끝날 때마다 실행됩니다 | 아니요 |
| `log-agent.sh` | 서브에이전트 시작 | 에이전트 호출 감사 로그 시작 | 아니요 |
| `log-agent-stop.sh` | 서브에이전트 종료 | 에이전트 호출 감사 로그 종료 | 아니요 |

`.claude/hooks/`에는 이 밖에 설정 해석 라이브러리 `yaml-helper.sh`(대부분의 스킬이 첫 줄에서 설정을 읽을 때 사용)와,
직접 등록해야 동작하는 진단 훅 `log-instructions.sh`가 있어 파일은 모두 14개입니다. 커밋·데이터 파일 훅은 모든
Bash·쓰기 호출에서 실행되지만, 관련 없는 명령이나 경로면 즉시 종료합니다.

### 스크립트

`.claude/scripts/`의 8개 스크립트(`artifact-check.sh`, `stage-estimate.sh`, `prd-structure-check.sh`,
`adr-dep-graph.sh`, `review-receipts.sh`, `review-scope.sh`, `project-coherence.sh`, `rotate-session-state.sh`)는
**관측 결과만 출력하고 판정하지 않습니다**. PASS/FAIL 판정과 차단 여부는 스킬과 게이트가 결정합니다.

### 권한

`settings.json`의 권한 규칙은 안전한 로컬 작업(상태 조회, 테스트·린트·타입체크 실행)을 자동 허용하고, 운영 환경과
공유 인프라를 바꾸는 명령(프로덕션 배포, `terraform apply`, `kubectl apply`, 데이터베이스 초기화·삭제, 스토어
제출)과 인증서·키 파일 읽기는 차단합니다. 에이전트는 운영 환경을 바꾸는 명령을 스스로 실행하지 않고, 사람이 실행할
정확한 명령과 영향 범위, 롤백 명령을 제안합니다.

Figma MCP 서버 도구, Claude Design 커넥터, `Artifact` 도구처럼 설치나 호스트에 따라 있을 수도 없을 수도 있는 도구는
공유 `settings.json`에 넣지 않습니다. MCP 도구 이름은 설치마다 다르기 때문입니다. 이 도구를 부르면 기본 권한
모드에서 매번 확인을 묻습니다. 읽기 전용 Figma 도구처럼 자주 쓰는 호출을 미리 허용하고 싶다면 개인별
`.claude/settings.local.json`(gitignore 대상)에 자기 설치의 도구 이름으로 적으세요. `settings.json`에는 적지 않습니다.
Figma에 쓰기, `/design-sync`로 Claude Design에 올리기, `/design`으로 디자인 아티팩트 게시하기 같은 외부 쓰기는
자동화 모드와 관계없이 항상 명시적으로 승인받습니다.

## 경로별 코딩 규칙

파일 위치에 따라 코딩 표준이 자동으로 적용됩니다. 규칙은 `src/` 기반 구조와 Next.js·Expo·NestJS식 모노레포
구조(`apps/*`, `packages/*`)를 모두 인식합니다.

| 규칙 | 적용 경로 (요약) | 핵심 내용 |
|------|------------------|-----------|
| `api-code.md` | `docs/api/**`, `apps/api/**`, `services/**`, 라우트·컨트롤러·GraphQL | 계약 우선, 모든 오퍼레이션의 인가, 경계에서의 검증, 버전 관리와 지원 중단, problem+json 오류, 페이지네이션, 멱등성 키, 타임아웃·재시도 |
| `domain-logic.md` | `**/src/domain/**`, `**/src/modules/**`, `**/src/features/**`, `services/*/src/**` 등 | 비즈니스 값은 설정·플래그에서, 멱등성, 경계에서의 인가, 테스트 가능한 순수 로직 |
| `platform-code.md` | `packages/**`, 공용 라이브러리 | 핫 패스의 블로킹 I/O 금지, 안정된 공개 API, 의존성 주입, 관측성 훅 |
| `ui-code.md` | 컴포넌트·화면·페이지 | 디자인 언어 컴포넌트만 사용, 로딩·빈 상태·오류·오프라인 상태, 접근성, i18n, 뷰에 비즈니스 로직 금지, 디자인 도구에서 내보낸 코드는 붙여 넣지 않고 라이브러리 컴포넌트로 다시 구현 |
| `styles-code.md` | CSS·SCSS·스타일·토큰·테마 | 토큰만 사용, 반응형 브레이크포인트, 다크 모드, 대비, 모션 줄이기, 목업의 토큰 없는 값은 `design-engineer`에게 토큰 요청 |
| `mobile-code.md` | `apps/mobile/**`, `ios/**`, `android/**`, Swift·Kotlin·Dart | 권한 사용 근거, 백그라운드 작업 제한, 딥링크 검증, 오프라인 동기화 충돌, 스토어 정책, 강제 업데이트 경로 |
| `migrations.md` | 마이그레이션 디렉터리 | expand/contract만, 되돌릴 수 있게, 배치 백필, 잠금 예산, 계획 문서 연결, 드라이런 증거 |
| `infra-code.md` | `infra/**`, Terraform, k8s, Helm, Dockerfile, CI 워크플로 | 시크릿 금지, 최소 권한, apply 전 plan, 에이전트는 apply하지 않음, 리소스 태그, 비용 메모 |
| `ai-integration.md` | AI·LLM·ML 코드 | 모델·프롬프트 버전 고정, 평가 세트를 테스트로, 타임아웃과 폴백, 토큰·비용 예산, 프롬프트·로그에 개인정보 금지, 출력 검증 |
| `data-files.md` | 설정, 시드, 픽스처, 로케일 | 유효한 JSON/YAML, 파일별 스키마, 키 표기 규칙, 시크릿 금지 |
| `content-copy.md` | 콘텐츠, 보이스 앤 톤, 문자열 리소스 | 보이스 앤 톤, 용어집, ICU 복수형, 문자열 이어 붙이기 금지, 길이 제한, 마케팅 수신 동의, 목업 속 문구는 초안이고 카피 덱이 최종 |
| `prd-docs.md` | `design/prd/**`, `design/product/**` | PRD 섹션 계약과 티어 규칙, 비즈니스 규칙, 레지스트리와 트래킹 플랜 갱신 |
| `test-standards.md` | `tests/**`, `*.test.*`, `*.spec.*`, `e2e/**` | 결정성, 격리, 단위 테스트에서 네트워크 금지, E2E에서 고정 sleep 금지·안정적인 셀렉터·시드 데이터 |
| `design-handoff.md` | `design/handoff/**` | 가져온 외부 디자인(Claude Design 번들, Figma·`/design` 스크린샷)은 원본 그대로의 스냅숏 — 고치지 않음, 토큰·컴포넌트 규칙은 구현에 적용, 참고 자료일 뿐 원본이 아님 |
| `prototype-code.md` | `prototypes/**` | 완화된 표준, `REPORT.md`(컨셉) 또는 `SPIKE-NOTE.md`(스파이크) 필수, 실제 개인정보·운영 키 금지 |
| `skill-authoring.md` | `.claude/skills/**`, `.claude/agents/**` | 스킬·게이트 작성의 다섯 가지 의무, 번호 붙은 스킬 파일 규칙 16개, 에이전트 파일 골격 |
| `agent-memory.md` | `.claude/agent-memory/**` | 에이전트 메모리 작성 규칙 |

규칙별 상세 설명은 [.claude/docs/rules-reference.md](.claude/docs/rules-reference.md)에 있습니다.

## 프로젝트 구조

```text
CLAUDE.md                        # 마스터 설정 (영어)
project.yaml                     # 프로젝트 설정의 원본 — 스택, 모드, 단계
.claude/
  settings.json                  # 훅 등록, 권한, 안전 규칙
  agents/                        # 에이전트 정의 46개
  skills/                        # 스킬 77개 (스킬마다 디렉터리 하나)
  hooks/                         # 훅 파일 14개 (등록 12 + yaml-helper.sh + 선택형 log-instructions.sh)
  scripts/                       # 관측 전용 스크립트 8개
  rules/                         # 경로별 코딩 규칙 17개
  statusline.sh                  # 상태 줄 (컨텍스트%, 모델, 단계 · rigor, 에픽 > 기능 > 태스크)
  docs/
    workflow-catalog.yaml        # 7단계 파이프라인 정의 (/help, /gate-check가 읽음)
    director-gates/              # 디렉터 게이트 정의 29개
    compliance/                  # 지역별 규제 체크리스트 (kr, eu, us)
    templates/                   # 문서 템플릿 57개
<code roots>/                    # 레이어별로 선언 (예: apps/web, apps/mobile, apps/api, services/worker, packages, infra)
design/                          # product/(브리프·기능 맵·저니·트래킹 플랜), prd/, ux/, handoff/(가져온 외부 디자인), brand/, content/, inventory/
docs/                            # architecture/, api/, data/, security/, ops/(SLO·런북), stack-reference/
tests/                           # unit/, integration/, contract/, e2e/, load/, helpers/
prototypes/                      # <name>-concept/, <name>-spike-YYYY-MM-DD/
production/                      # 스프린트, 에픽·스토리, QA 증거, 릴리스 기록, 인시던트, 그로스 실험
CCSS Skill Testing Framework/    # 스킬·에이전트 자체를 검증하는 테스트 프레임워크
```

템플릿에는 코드 루트 디렉터리가 들어 있지 않습니다. 첫 코드는 `/setup-stack`이 선언한 루트에 만들어집니다.

### 프레임워크 자체 테스트

이 템플릿은 고쳐 쓰라고 만든 것입니다. `CCSS Skill Testing Framework/`는 수정했거나 새로 만든 스킬·에이전트가
여전히 규칙을 지키는지 확인하는 도구입니다. 모든 스킬과 에이전트의 카탈로그, 카테고리별 품질 루브릭, 동작 명세,
명세 작성용 템플릿이 들어 있습니다.

```text
/skill-test static [name]     # 구조 린터
/skill-test category [name]   # 카테고리별 품질 루브릭
/skill-test spec [name]       # 동작 명세 검증
/skill-test audit             # 스킬·에이전트 전체 커버리지 보고
/skill-improve [name]         # 테스트-수정-재테스트 반복, 점수가 떨어지면 되돌림
```

이 프레임워크는 **템플릿 자체**를 테스트합니다. 여러분 서비스의 테스트는 `tests/`와 각 코드 루트에 둡니다.

## 작동 방식

### 에이전트 조율

1. **수직 위임** — 디렉터는 리드에게, 리드는 스페셜리스트에게 위임합니다. 복잡한 결정에서 계층을 건너뛰지 않습니다.
2. **수평 협의** — 같은 계층의 에이전트는 서로 의견을 구할 수 있지만, 자기 영역 밖의 결정을 확정하지 않습니다.
3. **갈등 해결** — 제품·UX·디자인 갈등은 `product-director`, 기술·품질 갈등은 `technical-director`로 올라갑니다.
4. **변경 전파** — 여러 영역에 걸친 변경은 `delivery-manager`가 조율합니다.
5. **영역 경계** — 명시적인 위임 없이 자기 영역 밖의 파일을 수정하지 않습니다.

### 자동 조종이 아니라 협업

모든 에이전트는 같은 협업 프로토콜을 따릅니다: **질문 → 선택지 → 결정 → 초안 → 승인**.

1. **질문** — 해결책을 내놓기 전에 먼저 묻습니다.
2. **선택지 제시** — 장단점과 함께 2–4개의 선택지를 보여 줍니다.
3. **사용자가 결정** — 결정은 언제나 사용자가 내립니다.
4. **초안** — 확정하기 전에 결과물을 먼저 보여 줍니다.
5. **승인** — "May I write this to [filepath]?"라고 묻고 승인을 받은 뒤에만 씁니다. 커밋은 지시가 있을 때만 합니다.

`modes.automation`(`collaborative` / `guided` / `autonomous`)으로 확인 빈도를 조절할 수 있습니다. 다만 기본
설정에서는 범위 변경, 파일 삭제, 스키마 변경, 프로덕션 배포, DB 마이그레이션, 인프라 변경, 시크릿·개인정보 접근,
과금 변경을 어떤 모드에서도 항상 묻습니다(`modes.automation_always_ask`). `/gate-check`, `/hotfix`, `/incident`,
`/rollout-plan`, `/setup-stack`, `/start`, `/settings`는 모드와 관계없이 모든 단계를 승인받습니다.

### "타입체크나 빌드는 실행이 아니다"

사용자가 보는 무언가를 바꾸는 스토리는 실제로 실행해서 관찰하기 전에는 닫히지 않습니다. 웹은 Playwright 캡처
스크립트로 데스크톱·모바일 화면을, iOS·Android는 시뮬레이터·에뮬레이터 스크린숏을, API는 요청·응답 스냅숏을
`production/qa/evidence/<story-slug>/`에 남깁니다. 이 원칙은 자동화 테스트가 면제되는 `minimal`에서도 유지됩니다.
DB 마이그레이션이 있는 스토리는 모든 티어에서 일회용 데이터베이스에 대한 드라이런 로그가 있어야 합니다.

## 커스터마이징

이것은 잠긴 프레임워크가 아니라 **템플릿**입니다. 무엇이든 바꿔 쓸 수 있습니다.

- **에이전트 추가·삭제** — 필요 없는 에이전트 파일을 지우고, 여러분 조직에 맞는 역할을 추가하세요.
- **에이전트 프롬프트 수정** — 도메인 지식과 팀의 관행을 넣으세요.
- **스킬 수정** — 팀의 실제 프로세스에 맞게 흐름을 조정하세요. 바꾼 뒤에는 `/skill-test`로 확인합니다.
- **규칙 추가** — 여러분의 디렉터리 구조에 맞는 경로별 규칙을 만드세요.
- **훅 조정** — 검증 강도를 바꾸거나 새 검사를 추가하세요.
- **스택 선택** — `/setup-stack`의 프리셋(`ts-fullstack-web`, `expo-mobile-ts-api`, `flutter-spring`,
  `python-api-react`)에서 시작하거나 레이어별로 직접 고르세요. 프리셋은 구성 요소만 정하고 버전은 정하지 않습니다.
- **프로세스 무게 조정** — `modes.rigor`와 세부 설정([설정](#설정) 참고). 한 번만 다르게 돌리려면 게이트를 쓰는
  스킬에 `--review solo`처럼 플래그를 붙이세요.

## 플랫폼 지원

훅과 스크립트는 POSIX 호환 패턴(`grep -P`가 아닌 `grep -E`)과 bash 3.2(macOS 기본 bash) 호환을 유지하도록 작성되어
macOS, Linux, Windows(Git Bash)를 대상으로 합니다. 선택 도구가 없으면 해당 검증을 건너뛰고 그 사실을 출력합니다.
플랫폼별 문제가 있으면 이 저장소의 이슈로 알려 주세요.

## 업그레이드와 기여

- 버전별 변경 사항: [CHANGELOG.md](CHANGELOG.md)
- 업그레이드 방법: [UPGRADING.md](UPGRADING.md)
- 기여 방법: [CONTRIBUTING.md](CONTRIBUTING.md)
- 보안 취약점 신고: [SECURITY.md](SECURITY.md)

---

## 업스트림 크레딧

이 저장소는 **Claude Code Game Studios v1.1.1**(커밋 `7ed2c3e`)을 포크해 만들었습니다. 원작자는 **Donchitos**이고,
MIT 라이선스로 공개되어 있습니다. 원본 저장소는 https://github.com/Donchitos/Claude-Code-Game-Studios 입니다.

업스트림의 제어 골격(협업 프로토콜, 단계 게이트와 판정 규칙, 설정 해석 체인, 세션 연속성, 스킬 테스트 프레임워크)을
이어받고, 조직·산출물·어휘를 웹·모바일·API 서비스 개발에 맞게 바꿨습니다.

## 라이선스

MIT 라이선스입니다. 자세한 내용은 [LICENSE](LICENSE)를 참고하세요. 원저작권 표기(Donchitos)와 이 포크의 저작권
표기(ababqq)를 함께 유지합니다.
