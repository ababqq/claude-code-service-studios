# 에이전트 로스터

에이전트마다 `.claude/agents/<name>.md` 정의 파일이 하나씩 있고, 파일 이름과 frontmatter의
`name`은 같습니다. 모델·도구 설정의 기준은 각 파일의 frontmatter이며, 이 문서는 사람이 읽기
위한 요약입니다. 두 내용이 다르면 frontmatter가 맞습니다.

작업에 가장 잘 맞는 에이전트를 쓰십시오. 여러 영역에 걸친 작업은 조율 담당(보통
`delivery-manager`나 해당 영역의 리드)이 스페셜리스트에게 나눠 맡깁니다. 에스컬레이션과
충돌 해결 규칙은 [coordination-rules.md](coordination-rules.md), 모델 티어 정책은
[model-tiers.md](model-tiers.md), 디렉터 게이트는 [director-gates.md](director-gates.md)에
있습니다.

## 읽는 법

- **티어**: T1 디렉터, T2 리드, T3 스페셜리스트, S 스택(레이어 리드 / 서브 스페셜리스트).
- **모델**: `opus`, `sonnet`, `inherit`. `inherit`는 세션 모델을 그대로 씁니다. 세션을 Opus로
  열면 Opus로, Sonnet으로 열면 Sonnet으로 동작합니다. `haiku`를 쓰는 에이전트는 없습니다.
- **협업**: 에이전트 본문의 `## Collaboration Protocol`에 들어 있는 협업 템플릿입니다.

  | 약어 | 템플릿 | 흐름 |
  | ---- | ---- | ---- |
  | STR | `Strategic Decision Workflow` | 선택지와 트레이드오프를 제시하고 사용자가 결정합니다. 디렉터가 씁니다. |
  | QF | `Question-First Workflow` | 무엇을 만들지 정하기 전에 먼저 질문합니다. 기획·디자인·콘텐츠처럼 결정이 앞서는 역할이 씁니다. |
  | IMP | `Implementation Workflow` | 설계 판단(예: "공용 패키지인가, 모듈 내부 헬퍼인가?")을 확인한 뒤 코드와 테스트를 씁니다. 스택 에이전트를 포함해 코드를 쓰는 역할이 씁니다. |
  | OPS | `Operations Workflow` | 현재 상태 확인 → 사람이 실행할 명령 제안(영향 범위·기대 결과·롤백 명령 포함) → 결과 검증 → 타임라인 기록. 프로덕션, 공유 인프라, 공유 DB, 시크릿을 바꾸는 명령은 자율 모드에서도 직접 실행하지 않습니다. |

- **보고 대상 / 위임 대상**: 보고 라인은 양쪽이 일치합니다. 어떤 에이전트의 보고 대상은 자신의
  "위임 대상"에 반드시 그 에이전트를 올려 두고 있습니다. 보고 라인 밖에서 추가로 위임하는 경우도
  있습니다. 예를 들어 `qa-lead`는
  `accessibility-specialist`에게 테스트 작업을, `release-manager`는 `devops-engineer`에게 릴리스
  실행을, `localization-lead`는 `ux-writer`에게 문자열 작업을 맡깁니다.
- **도구·설정**: 모든 에이전트가 `Read, Glob, Grep, Write, Edit`를 씁니다. 표에는 그 밖의 차이만
  적었습니다. "Bash 없음"은 `disallowedTools: Bash`, "memory"는 `memory:` 범위, "턴"은
  `maxTurns`, "스킬"은 frontmatter `skills:`로 미리 로드되는 스킬입니다.
- **제한된 쓰기 예외**: 모든 에이전트는 파일을 쓰기 전에 "May I write this to [filepath]?"로
  묻습니다. 예외는 하나뿐입니다. 오케스트레이션 스킬이 경로를 지정했고, 그 경로가
  `production/`, `docs/`, `tests/` 아래의 새 파일이며, 해당 단계를 `AskUserQuestion`으로 승인받은
  경우입니다. `design/`은 이 예외에서 제외됩니다.

## 조직도

```
user
├── product-director ─────────── CPO / 프로덕트 디렉터
│   ├── product-manager ──────── PM/PO (서비스 기획)
│   │   ├── business-analyst
│   │   ├── monetization-strategist
│   │   ├── analytics-engineer
│   │   └── prototyper
│   ├── design-director ──────── 디자인 디렉터
│   │   ├── product-designer
│   │   ├── design-engineer
│   │   ├── ux-writer
│   │   ├── ux-researcher
│   │   └── accessibility-specialist
│   ├── growth-manager
│   └── customer-success-manager
├── technical-director ───────── CTO / 테크니컬 디렉터
│   ├── tech-lead ────────────── 테크 리드
│   │   ├── backend-engineer
│   │   ├── frontend-engineer
│   │   ├── mobile-engineer
│   │   ├── platform-engineer
│   │   ├── internal-tools-engineer
│   │   ├── ml-engineer
│   │   ├── data-engineer
│   │   └── performance-engineer
│   ├── qa-lead ──────────────── QA 리드
│   │   └── qa-engineer
│   ├── devops-engineer
│   ├── sre-engineer
│   ├── security-engineer
│   ├── web-specialist ──────── nextjs-specialist, vue-nuxt-specialist
│   ├── mobile-specialist ───── react-native-specialist, flutter-specialist,
│   │                            ios-specialist, android-specialist
│   ├── backend-specialist ──── node-specialist, spring-specialist, python-specialist
│   ├── data-specialist
│   └── cloud-specialist
└── delivery-manager ─────────── PjM / 딜리버리 매니저
    ├── release-manager
    └── localization-lead
```

## 1티어 — 디렉터

| 에이전트 | 직함 | 담당 영역 | 모델 | 협업 | 위임 대상 | 보고 대상 | 도구·설정 |
| ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- |
| `product-director` | CPO / 프로덕트 디렉터 | 제품 비전과 전략, 제품 원칙과 안티골, North Star·가드레일 지표, 범위 중재, PRD 정렬 | `opus` | STR | `product-manager`, `design-director`, `growth-manager`, `customer-success-manager` | user | Bash 없음 · WebSearch · memory: user · 30턴 · 스킬: `brainstorm`, `prd-review` |
| `technical-director` | CTO / 테크니컬 디렉터 | 아키텍처, 스택·벤더 선택(직접 구축 vs 구매), NFR·SLO 예산, 보안·신뢰성 에스컬레이션, ADR 승인, 품질 에스컬레이션 | `opus` | STR | `tech-lead`, `qa-lead`, `devops-engineer`, `sre-engineer`, `security-engineer`, `web-specialist`, `mobile-specialist`, `backend-specialist`, `data-specialist`, `cloud-specialist` | user | Bash · WebSearch · memory: user · 30턴 |
| `delivery-manager` | PjM / 딜리버리 매니저 | 스프린트·사이클 계획, 마일스톤(MVP / Beta / GA), 팀 간 의존성, 리스크와 범위, 변경 전파 조율 | `opus` | STR | `release-manager`, `localization-lead` | user | Bash · WebSearch · memory: user · 30턴 · 스킬: `sprint-plan`, `scope-check`, `estimate`, `milestone-review` |

## 2티어 — 리드

`design-director`는 2티어지만 디렉터 패널의 네 번째 자리를 맡습니다. `/gate-check`가 정하는
패널 폭이 가장 넓을 때(`modes.workflow: full`) 다른 디렉터와 함께 단계 전환 준비도를 판정하며,
UI 표면이 없는 것으로 확인된 프로젝트에서는 패널에서 빠집니다.

| 에이전트 | 직함 | 담당 영역 | 모델 | 협업 | 위임 대상 | 보고 대상 | 도구·설정 |
| ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- |
| `design-director` | 디자인 디렉터 | 디자인 언어와 브랜드, 컴포넌트 라이브러리·디자인 토큰 거버넌스, UI 일관성, 콘텐츠 보이스, 접근성 디자인 기준 | `inherit` | STR | `product-designer`, `design-engineer`, `ux-writer`, `ux-researcher`, `accessibility-specialist` | `product-director` | Bash 없음 · WebSearch · memory: project · 20턴 |
| `product-manager` | PM/PO (서비스 기획) | 문제 정의, 기능 분해, PRD 소유, 인수 조건, 우선순위(RICE) | `inherit` | QF | `business-analyst`, `monetization-strategist`, `analytics-engineer`, `prototyper` | `product-director` | Bash 없음 · WebSearch · memory: project · 20턴 · 스킬: `write-prd`, `map-features`, `prd-review`, `quick-spec` |
| `tech-lead` | 테크 리드 | 코드 수준 아키텍처, 모듈·서비스 경계, API 계약과 마이그레이션 리뷰, 코딩 표준, 코드 리뷰, 작업 배분 | `sonnet` | IMP | `backend-engineer`, `frontend-engineer`, `mobile-engineer`, `platform-engineer`, `internal-tools-engineer`, `ml-engineer`, `data-engineer`, `performance-engineer` | `technical-director` | Bash · memory: project · 20턴 · 스킬: `code-review`, `architecture-decision`, `tech-debt`, `api-design` |
| `qa-lead` | QA 리드 | 테스트 전략(unit / integration+contract / UI / E2E), 스토리 유형별 증거, 릴리스 품질 게이트, 버그 심각도 | `inherit` | QF | `qa-engineer`, `accessibility-specialist` | `technical-director` | Bash · memory: project · 20턴 · 스킬: `bug-report`, `release-checklist` |
| `release-manager` | 릴리스 매니저 | 릴리스 트레인, 버전 관리, 스토어 제출, 점진적 배포 실행, 릴리스 기록 | `inherit` | OPS (릴리스 계획은 QF) | `devops-engineer` | `delivery-manager` | Bash · 20턴 · 스킬: `release-checklist`, `changelog`, `release-notes` |
| `localization-lead` | 로컬라이제이션 리드 | i18n 아키텍처(ICU MessageFormat, CLDR), 문자열 추출, TMS, 문자열 동결, 스토어 등록 정보 현지화, CJK 타이포그래피 | `inherit` | QF | `ux-writer` | `delivery-manager` | Bash · memory: project · 20턴 |

## 3티어 — 스페셜리스트

3티어 에이전트는 다른 에이전트에게 위임하지 않습니다. 막히면 보고 대상에게 에스컬레이션합니다.

### 기획·수익화·그로스·고객

| 에이전트 | 직함 | 담당 영역 | 모델 | 협업 | 보고 대상 | 도구·설정 |
| ---- | ---- | ---- | ---- | ---- | ---- | ---- |
| `business-analyst` | 서비스·정책 기획자 | 서비스 정책과 비즈니스 규칙: 자격 조건, 한도·쿼터, 수수료, 환불·해지, 상태 머신, 규칙 표 | `inherit` | QF | `product-manager` | Bash 없음 · memory: project · 20턴 |
| `monetization-strategist` | 수익화 전략가 (BM·가격 정책) | 가격과 패키징, 요금제·권한(entitlement), 체험판, 프로모션·쿠폰, 크레딧·포인트 경제, 국내 PG·인앱 결제를 포함한 결제 수단 | `inherit` | QF | `product-manager` | Bash 없음 · memory: project · 20턴 |
| `analytics-engineer` | 애널리틱스 엔지니어 | 트래킹 플랜과 이벤트 분류 체계, 계측 QA, 웨어하우스 모델(dbt)과 지표 레이어, 실험 설계·판독(MDE, SRM, 가드레일), 대시보드, 퍼널·리텐션 | `inherit` | QF | `product-manager` | Bash · WebSearch · 20턴 |
| `growth-manager` | 그로스 매니저 | 활성화·온보딩 최적화, 리텐션과 라이프사이클 CRM(푸시 / 이메일 / 알림톡), 실험 로드맵, 추천(referral), ASO | `inherit` | QF | `product-director` | Bash 없음 · memory: project · 20턴 |
| `customer-success-manager` | CS/CX 매니저 | 고객 지원과 성공: 지원 운영(헬프센터, 매크로, VOC, 상태 페이지, 앱 리뷰 답변), B2B라면 고객사 온보딩·헬스·이탈 신호 | `inherit` | QF | `product-director` | Bash 없음 · 10턴 |

### 엔지니어링

| 에이전트 | 직함 | 담당 영역 | 모델 | 협업 | 보고 대상 | 도구·설정 |
| ---- | ---- | ---- | ---- | ---- | ---- | ---- |
| `backend-engineer` | 백엔드 엔지니어 | 도메인 로직, REST/GraphQL 핸들러, 영속성과 마이그레이션, 백그라운드 잡, 멱등성, 인가(authz) 적용, 실시간 엔드포인트 | `inherit` | IMP | `tech-lead` | Bash · 20턴 |
| `frontend-engineer` | 프론트엔드 엔지니어 | 디자인 언어 기반 웹 UI, 앱 셸과 내비게이션, 인증 UI, 상태·데이터 패칭, 폼과 검증, 라우팅, SSR/CSR, 웹 접근성, Core Web Vitals | `inherit` | IMP | `tech-lead` | Bash · 20턴 |
| `mobile-engineer` | 모바일 앱 엔지니어 | iOS/Android/React Native/Flutter 앱: 앱 셸과 내비게이션, 인증·토큰 갱신, 오프라인과 동기화, 푸시 등록, 딥 링크, 권한, 생명주기, 스토어 빌드, 강제 업데이트 | `inherit` | IMP | `tech-lead` | Bash · 20턴 |
| `platform-engineer` | 플랫폼 엔지니어 | 공용 애플리케이션 라이브러리와 SDK: 데이터 접근 계층, 캐싱, 큐·잡 러너, 피처 플래그·설정 SDK, 로깅·트레이싱 라이브러리, API 클라이언트 SDK. 인프라는 맡지 않습니다(`devops-engineer`, `cloud-specialist` 담당) | `inherit` | IMP | `tech-lead` | Bash · 20턴 |
| `internal-tools-engineer` | 사내 도구 엔지니어 | 어드민·운영툴, CS 도구, CMS, 운영 대시보드, 데이터 보정 스크립트, 개발자 CLI | `inherit` | IMP | `tech-lead` | Bash · 20턴 |
| `ml-engineer` | ML 엔지니어 | LLM/ML 기능: 모델 연동, RAG, 프롬프트·평가 하네스, 가드레일, 랭킹·추천, 비용·지연 예산 | `inherit` | IMP | `tech-lead` | Bash · 20턴 |
| `data-engineer` | 데이터 엔지니어 | 이벤트 수집, CDC, ETL/ELT 파이프라인, 백필, 데이터 품질 | `inherit` | IMP | `tech-lead` | Bash · 20턴 |
| `performance-engineer` | 성능 엔지니어 | Core Web Vitals, 번들 크기, API p50/p95/p99, DB 쿼리 프로파일링, 모바일 시작 시간·메모리, 부하 테스트, 용량 | `inherit` | IMP | `tech-lead` | Bash · memory: project · 20턴 |
| `prototyper` | 프로토타이퍼 | 검증용으로 쓰고 버리는 빌드: 클릭 가능한 프로토타입, 페이크 도어 페이지, 컨시어지 스크립트, 코드 스파이크. 프로덕션 코드는 쓰지 않습니다 | `sonnet` | IMP | `product-manager` | Bash · 25턴 · `isolation: worktree` |

### 디자인·리서치·콘텐츠

| 에이전트 | 직함 | 담당 영역 | 모델 | 협업 | 보고 대상 | 도구·설정 |
| ---- | ---- | ---- | ---- | ---- | ---- | ---- |
| `product-designer` | 프로덕트 디자이너 (UX/UI) | 플로우, 정보 구조(IA), 와이어프레임부터 하이파이 명세까지, 인터랙션 패턴(웹 / iOS HIG / Material), 앱 셸, 화면 상태 | `inherit` | QF | `design-director` | Bash 없음 · WebSearch · memory: project · 20턴 |
| `design-engineer` | 디자인 엔지니어 | 디자인 토큰 파이프라인, 컴포넌트 라이브러리와 Storybook, 모션, 테마·다크 모드, 시각 회귀 테스트 | `inherit` | IMP | `design-director` | Bash · 20턴 |
| `ux-researcher` | UX 리서처 | 인터뷰, 사용성 테스트, 설문, 리서치 종합(JTBD, 페르소나), 인사이트 저장소 | `inherit` | QF | `design-director` | Bash 없음 · WebSearch · memory: project · 20턴 |
| `ux-writer` | UX 라이터 | 마이크로카피, 오류·빈 화면 문구, 온보딩 카피, 알림 템플릿(푸시 / 이메일 / SMS / 알림톡), 헬프센터·개발자 가이드 문서, 보이스 앤 톤 | `inherit` | QF | `design-director` | Bash 없음 · memory: project · 20턴 |
| `accessibility-specialist` | 접근성 전문가 | WCAG 2.2와 지역 표준(`compliance.regions`에 따른 KWCAG 등), ARIA 패턴, VoiceOver/TalkBack/NVDA, 동적 글자 크기, 명도 대비, axe 도구 | `inherit` | IMP | `design-director` | Bash · 10턴 |

### 품질·보안·운영

| 에이전트 | 직함 | 담당 영역 | 모델 | 협업 | 보고 대상 | 도구·설정 |
| ---- | ---- | ---- | ---- | ---- | ---- | ---- |
| `qa-engineer` | QA 엔지니어 (SDET) | 테스트 케이스, E2E·계약·통합 테스트 코드, 탐색적 테스트, 버그 리포트, 증거 수집 | `inherit` | IMP | `qa-lead` | Bash · 10턴 |
| `security-engineer` | 보안 엔지니어 (AppSec·개인정보) | 위협 모델링, OWASP Top 10 / API Top 10 / MASVS, 인증·인가, 시크릿, 공급망, 개인정보 처리, 지역별 컴플라이언스 체크리스트 | `inherit` | IMP | `technical-director` | Bash · 20턴 |
| `devops-engineer` | DevOps 엔지니어 | CI/CD, IaC, 환경(dev / staging / prod + 프리뷰), 컨테이너·서버리스, 시크릿 관리, 빌드·배포 파이프라인 | `inherit` | OPS | `technical-director` | Bash · 20턴 |
| `sre-engineer` | SRE | SLO와 에러 버짓, 관측성(로그·지표·트레이스·알림), 온콜과 런북, 인시던트 지원, 용량, 백업·복구, 재해 복구(DR) | `inherit` | OPS | `technical-director` | Bash · WebSearch · 20턴 |

## 스택 패밀리

스택 에이전트는 `project.yaml`의 `stack.layers.<layer>`에 맞춰 호출됩니다. 레이어마다 리드가
하나 있고, 웹·모바일·백엔드 리드는 `Agent(...)` 권한으로 자기 서브 스페셜리스트에게만 위임할
수 있습니다. `Agent(...)` 권한을 가진 에이전트는 이 세 리드뿐입니다. 서브 스페셜리스트는 자기
레이어 리드에게 에스컬레이션하고, 리드는 `technical-director`에게 보고합니다.

| 에이전트 | 구분 | 직함 | 담당 영역 | 모델 | 위임 대상 (`Agent(...)`) | 보고 대상 |
| ---- | ---- | ---- | ---- | ---- | ---- | ---- |
| `web-specialist` | 레이어 리드 | 웹 스택 리드 | 프레임워크 선택, 렌더링(SSR/SSG/CSR/RSC), 라우팅, 데이터 패칭과 캐싱, 빌드 도구, 보안 헤더 | `inherit` | `nextjs-specialist`, `vue-nuxt-specialist` | `technical-director` |
| `nextjs-specialist` | 서브 | Next.js 전문가 | React + Next.js + TypeScript 관용 패턴: App Router, RSC, 서버 액션, 캐싱, 미들웨어 | `sonnet` | — | `web-specialist` |
| `vue-nuxt-specialist` | 서브 | Vue·Nuxt 전문가 | Vue 3 + Nuxt 관용 패턴: Composition API, Nitro, SSR/ISR, Pinia | `sonnet` | — | `web-specialist` |
| `mobile-specialist` | 레이어 리드 | 모바일 스택 리드 | 크로스플랫폼 vs 네이티브, 내비게이션, 오프라인 저장소와 동기화, 푸시, 딥 링크, 권한, 서명과 스토어 빌드 | `inherit` | `react-native-specialist`, `flutter-specialist`, `ios-specialist`, `android-specialist` | `technical-director` |
| `react-native-specialist` | 서브 | React Native 전문가 | React Native / Expo: EAS, 설정 플러그인, 네이티브 모듈, New Architecture | `sonnet` | — | `mobile-specialist` |
| `flutter-specialist` | 서브 | Flutter 전문가 | Flutter/Dart: 위젯, 상태 관리, 플랫폼 채널, flavor | `sonnet` | — | `mobile-specialist` |
| `ios-specialist` | 서브 | iOS 전문가 | Swift / SwiftUI / UIKit, App Store 요구 사항, 개인정보 매니페스트 | `sonnet` | — | `mobile-specialist` |
| `android-specialist` | 서브 | Android 전문가 | Kotlin / Jetpack Compose, Google Play 정책, 타깃 API 레벨 | `sonnet` | — | `mobile-specialist` |
| `backend-specialist` | 레이어 리드 | 백엔드 스택 리드 | 프레임워크 관용 패턴, 모듈러 모놀리스 vs 서비스 분리, 영속성 패턴, 잡·큐, API 구현 표준 | `inherit` | `node-specialist`, `spring-specialist`, `python-specialist` | `technical-director` |
| `node-specialist` | 서브 | Node.js 전문가 | Node.js/TypeScript 백엔드: NestJS, Express, Fastify; Prisma / TypeORM / Drizzle | `sonnet` | — | `backend-specialist` |
| `spring-specialist` | 서브 | Spring 전문가 | Java/Kotlin Spring Boot: JPA/Hibernate, Spring Security, Batch. 국내 기업 환경에서 흔한 스택 | `sonnet` | — | `backend-specialist` |
| `python-specialist` | 서브 | Python 백엔드 전문가 | Python 백엔드: FastAPI, Django; SQLAlchemy / Django ORM; Celery | `sonnet` | — | `backend-specialist` |
| `data-specialist` | 레이어 리드 | 데이터(OLTP) 스택 리드 | 운영 데이터 계층: PostgreSQL/MySQL, Redis, 큐(Kafka / SQS / RabbitMQ — publisher/consumer), 인덱싱, 마이그레이션 도구, 백업 | `inherit` | — (서브 없음) | `technical-director` |
| `cloud-specialist` | 레이어 리드 | 클라우드 스택 리드 | AWS / GCP / Azure / NCP, Vercel / Fly / Cloudflare, Kubernetes, Terraform / Pulumi, 네트워크, 비용 | `inherit` | — (서브 없음) | `technical-director` |

모든 스택 에이전트는 IMP 템플릿으로 일하고, 모두 Bash와 20턴 설정을 씁니다.

### 서브 스페셜리스트 라우팅

스킬은 레이어의 프레임워크 값을 대소문자 구분 없는 정규식(ERE)으로 위에서부터 맞춰 보고, 처음
맞는 규칙의 서브 스페셜리스트를 부릅니다. 맞는 규칙이 없으면 레이어 리드만 부릅니다.

| 레이어 | 기준 키 | 리드 | 서브 선택 규칙 (순서대로, 첫 일치) | 수동 지정 키 |
| ---- | ---- | ---- | ---- | ---- |
| web | `stack.layers.web.framework` | `web-specialist` | 1 `next\|react` → `nextjs-specialist`; 2 `nuxt\|vue` → `vue-nuxt-specialist` | `specialists.web` |
| mobile | `stack.layers.mobile.framework` | `mobile-specialist` | 1 `react native\|expo` → `react-native-specialist`; 2 `flutter` → `flutter-specialist`; 3 (`swift\|ios`)와 (`kotlin\|compose\|android`)에 모두 맞거나 `^native`에 맞으면 → `ios-specialist` + `android-specialist`; 4 `swift\|ios` → `ios-specialist`; 5 `kotlin\|compose\|android` → `android-specialist` | `specialists.mobile` |
| backend | `stack.layers.backend.framework` | `backend-specialist` | 1 `nest\|express\|fastify\|hono\|node` → `node-specialist`; 2 `spring\|java\|kotlin` → `spring-specialist`; 3 `fastapi\|django\|flask\|python` → `python-specialist` | `specialists.backend` |
| data | `stack.layers.data.database` | `data-specialist` | — | — |
| cloud | `stack.layers.cloud.provider` | `cloud-specialist` | — | — |

설정되지 않은 레이어의 에이전트는 호출되지 않으며, 스킬은
`NOT CHECKED — <layer> layer not configured (run /setup-stack)`를 출력합니다. `/dev-story`는
스토리의 위험도가 HIGH이면 서브 대신 레이어 리드를 부르고, 리드가 필요할 때 서브에게 위임합니다.
위험도는 스토리 카드의 `**Risk**`가 아니라 `docs/stack-reference/VERSION.md`에서 1차 표면을 구현하는
컴포넌트 행의 Knowledge Risk로 정하며, 행이 없거나 `NOT DETERMINED`이면 HIGH로 봅니다.

### 버전 인식 원칙

모든 스택 에이전트 본문에는 `## Version Awareness` 섹션이 있습니다. 버전에 따라 달라지는 조언을
하기 전에 `docs/stack-reference/VERSION.md`와 `docs/stack-reference/<component>/`를 확인하고,
학습 시점 이후의 API는 Knowledge Risk로 표시합니다. 근거를 찾을 수 없으면 추측하지 않고
`NOT SOURCEABLE — run /setup-stack refresh`라고 답합니다. 자기 레이어 밖의 판단은 하지 않습니다.

## `/dev-story`의 구현 담당 배정

스토리 헤더의 `> **Surface**:`와 `> **Type**:`에 따라 1차 구현 에이전트가 정해집니다.
`**Surface**`에 값이 여럿이면 첫 값이 1차이고, 나머지 표면의 1차 에이전트가 보조로 붙습니다.
위에서부터 처음 맞는 행을 씁니다.

| 스토리 조건 | 1차 에이전트 | 보조 에이전트 (코드 스토리) |
| ---- | ---- | ---- |
| Type `Config`, 코드 없음(플래그, 환경 설정, 가격·한도 표) | 없음 (Config 경로) | — |
| Type `Config`, DB 마이그레이션 포함(`**Migration**` ≠ None) | `backend-engineer` | `data-specialist` |
| Surface `infra` | `devops-engineer` | `cloud-specialist` |
| Surface `analytics` (파이프라인, 웨어하우스, 지표 레이어) | `data-engineer` | `analytics-engineer` |
| Surface `admin` | `internal-tools-engineer` | 라우팅된 웹 서브 (없으면 `web-specialist`) |
| ADR Domain `ML` 또는 스토리 필드 `**ML**: yes` | `ml-engineer` | 라우팅된 백엔드 서브 (없으면 `backend-specialist`) |
| Surface `web` | `frontend-engineer` | 라우팅된 웹 서브 (없으면 `web-specialist`); 파일이 `stack.shared_roots` 아래면 + `platform-engineer` |
| Surface `ios`, `android`, `mobile` | `mobile-engineer` | 라우팅된 모바일 서브 (없으면 `mobile-specialist`); 파일이 `stack.shared_roots` 아래면 + `platform-engineer` |
| Surface `api`, 그리고 Layer `Foundation`이거나 파일이 `stack.shared_roots` 아래 | `platform-engineer` | 라우팅된 백엔드 서브 (없으면 `backend-specialist`) |
| Surface `api` | `backend-engineer` | 라우팅된 백엔드 서브 (없으면 `backend-specialist`) |

## 디렉터 게이트 소유

게이트 판정은 아래 여덟 에이전트만 내립니다. 게이트 ID의 접두사가 소유 에이전트를 나타내며,
각 에이전트 본문의 `## Gate Verdict Format`에 판정 토큰이 정의되어 있습니다. 게이트 에이전트는
응답 첫 줄을 `[GATE-ID]: TOKEN` 형식으로 쓰고, 게이트를 호출한 스킬이 이 줄을 읽습니다.

| 에이전트 | 접두사 | 게이트 |
| ---- | ---- | ---- |
| `product-director` | `PD-` | `PD-PRINCIPLES`, `PD-PRD-ALIGN`, `PD-FEATURE-MAP`, `PD-USER-VALIDATION`, `PD-PHASE-GATE` |
| `technical-director` | `TD-` | `TD-DOMAIN-BOUNDARY`, `TD-FEASIBILITY`, `TD-ARCHITECTURE`, `TD-ADR`, `TD-STACK-RISK`, `TD-PHASE-GATE`, `TD-MANIFEST`, `TD-CHANGE-IMPACT` |
| `delivery-manager` | `DM-` | `DM-SCOPE`, `DM-SPRINT`, `DM-MILESTONE`, `DM-EPIC`, `DM-PHASE-GATE` |
| `design-director` | `DD-` | `DD-BRAND-DIRECTION`, `DD-DESIGN-LANGUAGE`, `DD-PHASE-GATE`, `DD-UI-CONSISTENCY`, `DD-CONTENT-VOICE` |
| `tech-lead` | `TL-` | `TL-FEASIBILITY`, `TL-CODE-REVIEW` |
| `qa-lead` | `QL-` | `QL-STORY-READY`, `QL-TEST-COVERAGE` |
| `security-engineer` | `SE-` | `SE-SECURITY-REVIEW` |
| `sre-engineer` | `SR-` | `SR-PRODUCTION-READINESS` |

게이트를 실제로 띄울지는 `modes.review_mode`(`full` / `lean` / `solo`)가 정합니다. `lean`에서는
ID가 `-PHASE-GATE`로 끝나지 않는 게이트를 모두 건너뛰고, `solo`에서는 모든 게이트를 건너뜁니다.
`/hotfix`, `/rollout-plan`, `/incident`는 릴리스에 직결되는 스킬이라 리뷰 모드와 관계없이 자신이
지정한 에이전트와 게이트를 항상 실행합니다.

## 모델 배분

| 모델 | 에이전트 수 | 에이전트 |
| ---- | ---- | ---- |
| `opus` | 3 | `product-director`, `technical-director`, `delivery-manager` |
| `sonnet` | 11 | `tech-lead`, `prototyper`, 스택 서브 스페셜리스트 전원(`nextjs-specialist`, `vue-nuxt-specialist`, `react-native-specialist`, `flutter-specialist`, `ios-specialist`, `android-specialist`, `node-specialist`, `spring-specialist`, `python-specialist`) |
| `inherit` | 32 | 위에 없는 모든 에이전트 |
| `haiku` | 0 | — |

새 에이전트는 고정할 이유가 없으면 `inherit`로 둡니다. 모델을 고정한 이유, 그리고 스킬
frontmatter의 `model:`은 선언일 뿐 실제로는 세션 모델로 실행된다는 점(에이전트의 `model:`과는
다른 메커니즘입니다)은 [model-tiers.md](model-tiers.md)에 정리되어 있습니다.
