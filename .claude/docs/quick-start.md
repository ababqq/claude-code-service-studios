# Claude Code Service Studios — 빠른 시작

## 이 템플릿은 무엇인가요

Claude Code 세션 하나를 웹·모바일·API 서비스를 만드는 제품 조직처럼 움직이게 하는 템플릿입니다. 구성은 다음과 같습니다.

| 구성 요소 | 개수 | 위치 |
|---|---|---|
| 에이전트 | 46 | `.claude/agents/` |
| 스킬 (슬래시 명령) | 76 | `.claude/skills/` |
| 훅 | 등록 12 (파일 14) | `.claude/hooks/` |
| 스크립트 | 8 | `.claude/scripts/` |
| 경로별 규칙 | 16 | `.claude/rules/` |
| 문서 템플릿 | 56 | `.claude/docs/templates/` |
| 디렉터 게이트 | 29 | `.claude/docs/director-gates/` |

에이전트는 디렉터 → 리드 → 스페셜리스트로 배치되고, 웹·모바일·백엔드·데이터·클라우드 레이어마다 스택 스페셜리스트가
있습니다. `project.yaml`에 설정한 프레임워크(예: Next.js, React Native, NestJS, Spring Boot)에 맞는 스페셜리스트가
자동으로 선택됩니다. 무엇보다 이 시스템은 **자동 조종이 아니라 협업**입니다. 에이전트는 먼저 묻고, 선택지를 보여 주고,
사용자가 결정한 뒤에만 파일을 씁니다.

---

## 30분 온보딩

처음 30분 동안 아래 순서를 따라가면 "무엇을 만들지"가 글로 정리되고 다음에 할 일이 분명해집니다. 시간은 대략의
기준입니다. 문서는 섹션마다 바로 파일에 기록되므로, 중간에 멈춰도 다음 세션에서 이어 갈 수 있습니다.

| 시간 | 할 일 | 끝나면 이렇게 됩니다 |
|---|---|---|
| 0–5분 | 준비물을 확인하고(Git, Claude Code, Python 3, 권장: jq), 저장소를 클론한 뒤 `claude`를 실행합니다 | `Claude Code Service Studios` 배너와 함께 브랜치, 최근 커밋, 현재 단계가 보입니다 |
| 5–10분 | `/start`를 실행하고 지금 상황(A–D)을 고릅니다 | `project.yaml`에 `project.stage`, `modes.rigor`, `modes.automation`이 기록됩니다 |
| 10–20분 | `/brainstorm`으로 문제, 대상 사용자, 가치 제안, 성공 지표, 가장 위험한 가정을 정리합니다 | `minimal`이면 `design/product/one-pager.md`, `standard`·`full`이면 `design/product/product-brief.md`가 섹션별로 채워집니다 |
| 20–25분 | `/setup-stack`으로 이미 정한 스택 레이어를 고르고 버전을 고정합니다(아직 못 정했다면 미뤄도 됩니다) | `stack.*`와 `docs/stack-reference/VERSION.md`가 채워지고, 끝나면 `stack.pinned_on`이 기록됩니다 |
| 25–30분 | `/help`로 다음 필수 단계를 확인하고, [docs/WORKFLOW-GUIDE.md](../../docs/WORKFLOW-GUIDE.md)에서 지금 단계의 절을 읽습니다 | 다음에 실행할 스킬이 정해집니다(standard·full이면 먼저 `/prd-review design/product/product-brief.md`로 브리프를 검토하고, 필요하면 `/prototype`으로 가장 위험한 가정을 확인한 뒤 `/gate-check definition` → `/map-features`; minimal이면 `/create-stories`로 one-pager의 `## Build Order`를 스토리로 바꾸고 `/dev-story`로 첫 스토리를 구현) |

이미 코드가 있는 프로젝트라면 `/start`에서 D를 고르세요. 트리를 보고 단계를 추정한 뒤 `/adopt`로 안내합니다.

---

## 구조 한눈에

- **디렉터** — `product-director`(CPO), `technical-director`(CTO), `delivery-manager`(PjM), 그리고 게이트 패널의 네 번째
  자리인 `design-director`. 방향과 품질 기준을 지키고 단계 게이트에서 판정합니다.
- **리드** — `product-manager`(PM/PO, 서비스 기획), `tech-lead`, `qa-lead`, `release-manager`, `localization-lead`.
  자기 영역의 결정을 책임지고 스페셜리스트에게 위임합니다.
- **스페셜리스트** — 제품(`business-analyst`, `monetization-strategist`, `analytics-engineer`, `growth-manager`,
  `customer-success-manager`, `prototyper`), 디자인(`product-designer`, `ux-researcher`, `ux-writer`,
  `design-engineer`, `accessibility-specialist`), 엔지니어링(`backend-engineer`, `frontend-engineer`,
  `mobile-engineer`, `platform-engineer`, `internal-tools-engineer`, `ml-engineer`, `data-engineer`,
  `performance-engineer`), 품질·보안·운영(`qa-engineer`, `security-engineer`, `devops-engineer`, `sre-engineer`).
- **스택 패밀리** — 레이어 리드 5개(`web-specialist`, `mobile-specialist`, `backend-specialist`, `data-specialist`,
  `cloud-specialist`)와 하위 스페셜리스트 9개(`nextjs-specialist`, `vue-nuxt-specialist`, `react-native-specialist`,
  `flutter-specialist`, `ios-specialist`, `android-specialist`, `node-specialist`, `spring-specialist`,
  `python-specialist`).

모델은 에이전트 frontmatter에 선언되어 있습니다. `product-director`, `technical-director`, `delivery-manager`는
Opus, `tech-lead`·`prototyper`와 스택 하위 스페셜리스트 9개는 Sonnet이고, 나머지 32개는 세션 모델을 상속합니다.
전체 목록과 책임 범위는 [agent-roster.md](agent-roster.md)에 있습니다.

---

## 역할별 첫 명령

팀에 새로 합류했다면 먼저 `/onboard <역할>`로 역할별 온보딩 문서를 만들고(`production/onboarding/`에 저장), 아래 명령으로
실제 작업을 시작하세요.

| 역할 | 첫 명령 | 주로 함께 일하는 에이전트 | 먼저 읽을 곳 |
|---|---|---|---|
| PM·서비스 기획 | `/onboard pm` → 새 제품이면 `/brainstorm`, 새 기능이면 `/write-prd <feature>`, 작은 변경이면 `/quick-spec` | `product-manager`, `business-analyst`, `product-director` | `design/product/`, `design/prd/` |
| 디자이너 | `/onboard designer` → `/design-language` 또는 `/ux-design <화면>` | `product-designer`, `design-director`, `ux-writer`, `design-engineer`, `accessibility-specialist` | `design/brand/`, `design/ux/`, `design/accessibility-requirements.md` |
| 프런트엔드 | `/onboard frontend` → `/story-readiness <story>` → `/dev-story <story>` | `frontend-engineer`, `web-specialist`와 하위 스페셜리스트 | 웹 코드 루트의 `CLAUDE.md`, `docs/api/`, `docs/stack-reference/` |
| 백엔드 | `/onboard backend` → `/api-design review` → `/dev-story <story>` | `backend-engineer`, `backend-specialist`와 하위 스페셜리스트, `data-specialist` | `docs/api/`, `docs/data/`, `docs/architecture/` |
| 모바일 | `/onboard mobile` → `/dev-story <story>` | `mobile-engineer`, `mobile-specialist`와 하위 스페셜리스트 | 모바일 코드 루트, `design/ux/app-shell.md` |
| SRE·데브옵스 | `/onboard sre` → `/incident runbook <alert-slug>` 또는 `/load-test smoke` | `sre-engineer`, `devops-engineer`, `cloud-specialist` | `docs/ops/slo.md`, `docs/ops/runbooks/`, `.github/workflows/` |
| 보안 | `/onboard security` → `/security-audit quick` (설계 단계라면 `/security-audit threat-model`) | `security-engineer`, `technical-director` | `docs/security/`, `production/security/`, `.claude/docs/compliance/` |
| 데이터 | `/onboard data` → `/data-model review` | `data-engineer`, `analytics-engineer`, `data-specialist` | `docs/data/`, `design/product/tracking-plan.md` |
| QA | `/onboard qa` → `/qa-plan sprint` → `/smoke-check` | `qa-lead`, `qa-engineer` | `production/qa/`, `tests/` |
| 그로스·CS | `/team-growth "<실험>"` 또는 `/team-content <영역>` (예: `notifications`) | `growth-manager`, `customer-success-manager`, `ux-writer` | `production/growth/`, `design/content/`, `design/brand/voice-and-tone.md` |

`/onboard`는 `pm`, `designer`, `frontend`, `backend`, `mobile`, `sre`, `security`, `data`를 역할로 알아듣고, 그 밖의
인자(예: `qa`, `payments`, `admin-console`)는 가장 가까운 에이전트를 골라 해당 영역을 살핍니다.

---

## 어떤 에이전트에게 맡길까

"실제 제품 조직이라면 어느 팀이 이 일을 맡을까?"를 떠올리면 됩니다.

| 하고 싶은 일 | 에이전트 |
|---|---|
| 제품 방향과 범위 충돌 판단 | `product-director` |
| 아키텍처와 기술 선택 결정 | `technical-director` |
| 다음 스프린트 계획, 일정과 위험 관리 | `delivery-manager` |
| PRD 작성, 기능 우선순위 | `product-manager` |
| 한도·수수료·환불 같은 정책 규칙 | `business-analyst` |
| 요금제와 가격, 쿠폰, 크레딧 | `monetization-strategist` |
| 코드 리뷰, 모듈 경계, API 계약 리뷰 | `tech-lead` |
| API 핸들러, 도메인 로직, 백그라운드 작업 | `backend-engineer` |
| 웹 화면과 폼, 상태 관리 | `frontend-engineer` |
| iOS·Android 앱, 푸시, 딥링크, 오프라인 동기화 | `mobile-engineer` |
| 어드민·운영툴 | `internal-tools-engineer` |
| LLM 기능, RAG, 평가 | `ml-engineer` |
| 화면 흐름과 UX 명세 | `product-designer` |
| 사용성 테스트와 인터뷰 | `ux-researcher` |
| 버튼 문구, 오류 메시지, 알림톡 템플릿 | `ux-writer` |
| 테스트 케이스와 E2E 테스트 코드 | `qa-engineer` |
| 느린 API, 번들 크기, 부하 테스트 | `performance-engineer` |
| 위협 모델링, 보안 감사, 개인정보 | `security-engineer` |
| CI/CD, IaC, 환경 구성 | `devops-engineer` |
| SLO, 알림, 온콜, 런북 | `sre-engineer` |
| 릴리스 열차, 스토어 제출 | `release-manager` |
| 번역과 문자열 관리 | `localization-lead` |
| 트래킹 플랜과 실험 분석 | `analytics-engineer` |
| 리텐션 캠페인과 그로스 실험 | `growth-manager` |
| 고객 지원, VOC, 상태 페이지 | `customer-success-manager` |
| 가설을 빨리 확인할 프로토타입 | `prototyper` |
| 특정 프레임워크의 관용구와 버전 이슈 | 해당 스택 스페셜리스트 (예: `nextjs-specialist`, `spring-specialist`) |

더 자세한 표는 [WORKFLOW-GUIDE.md의 부록 A](../../docs/WORKFLOW-GUIDE.md#부록-a-어떤-에이전트에게-맡길까)에 있습니다.

---

## 자주 쓰는 명령

| 명령 | 하는 일 |
|---|---|
| `/start` | 첫 온보딩. 지금 상황(A–D)을 묻고 알맞은 흐름으로 안내 |
| `/help` | 현재 단계와 산출물을 읽고 다음 필수 단계를 알려 줌 |
| `/brainstorm` | 문제·사용자·가치 제안·지표·위험한 가정을 정리해 one-pager 또는 제품 브리프 작성 |
| `/setup-stack` | 레이어별 스택 선택, 실시간 출처로 버전 고정, 코드 루트 선언 |
| `/map-features` | 브리프를 기능으로 나누고 MVP / Beta / GA / Later 티어 지정 |
| `/write-prd` | 기능 하나의 PRD를 섹션 단위로 작성 |
| `/prd-review` | PRD 또는 제품 브리프 검토 |
| `/create-architecture` | 아키텍처 문서와 SLO 문서 작성 |
| `/architecture-decision` | ADR 작성·보완·채택 |
| `/api-design` | 계약 우선 API 설계(OpenAPI 등), UX와 조정, 하위 호환성 검사 |
| `/data-model` | 데이터 모델과 expand/contract 마이그레이션 계획 |
| `/test-setup` | 레이어별 테스트 러너와 CI 워크플로 스캐폴드 |
| `/design-language` | 디자인 언어(9개 섹션) 작성 |
| `/ux-design` | 화면·흐름 UX 명세, 앱 셸, 인터랙션 패턴, 접근성, 사용자 여정 |
| `/walking-skeleton` | 스테이징에 배포되는 얇은 끝에서 끝까지 경로(Sprint 0) |
| `/create-epics`, `/create-stories` | PRD·ADR·API 계약에서 에픽과 스토리 생성 |
| `/sprint-plan` | 스프린트 계획과 `production/sprint-status.yaml` 작성 |
| `/dev-story` | 스토리 구현 — 표면과 유형에 맞는 엔지니어에게 라우팅, 실행해서 관찰 |
| `/story-done` | 인수 조건과 증거 확인, 어긋난 점 점검, 스토리 완료 |
| `/smoke-check` | QA 인계 전과 릴리스 후보의 핵심 경로 스모크 점검 |
| `/gate-check` | 목표 단계 진입 준비 점검 (`PASS` / `CONCERNS` / `NOT ASSESSED` / `FAIL`) |
| `/security-audit` | 보안·개인정보 감사와 위협 모델링 |
| `/release-checklist`, `/rollout-plan` | 릴리스별 체크리스트와 점진적 배포 계획 |
| `/incident`, `/postmortem`, `/hotfix` | 장애 대응, 비난 없는 포스트모템, 긴급 수정 |
| `/settings` | 설정 보기·바꾸기 (`--local`로 나만의 설정) |

### 전체 스킬 (영역별)

- **시작과 탐색**: `/start`, `/help`, `/project-stage-detect`, `/adopt`, `/settings`, `/onboard`, `/gate-check`,
  `/reverse-document`
- **제품 기획**: `/brainstorm`, `/prototype`, `/setup-stack`, `/map-features`, `/write-prd`, `/prd-review`,
  `/review-all-prds`, `/quick-spec`, `/consistency-check`, `/propagate-prd-change`
- **아키텍처와 계약**: `/create-architecture`, `/architecture-decision`, `/architecture-review`,
  `/create-control-manifest`, `/api-design`, `/data-model`, `/security-audit`
- **UX와 디자인**: `/design-language`, `/ux-design`, `/ux-review`, `/ui-inventory`, `/usability-report`
- **스토리와 스프린트**: `/create-epics`, `/create-stories`, `/story-readiness`, `/dev-story`, `/code-review`,
  `/story-done`, `/walking-skeleton`, `/sprint-plan`, `/sprint-status`, `/estimate`, `/scope-check`,
  `/milestone-review`, `/retrospective`, `/tech-debt`
- **테스트와 QA**: `/test-setup`, `/test-helpers`, `/smoke-check`, `/qa-plan`, `/regression-suite`,
  `/test-evidence-review`, `/test-flakiness`, `/bug-report`, `/bug-triage`
- **안정화와 품질 분석**: `/perf-profile`, `/bundle-audit`, `/load-test`, `/business-rules-check`, `/feature-audit`,
  `/localize`
- **릴리스와 운영**: `/changelog`, `/release-notes`, `/release-checklist`, `/rollout-plan`, `/launch-checklist`,
  `/incident`, `/postmortem`, `/hotfix`
- **팀 오케스트레이션**: `/team-feature`, `/team-ui`, `/team-content`, `/team-qa`, `/team-hardening`,
  `/team-release`, `/team-growth`
- **프레임워크 관리**: `/skill-test`, `/skill-improve`

스킬별 설명과 인자는 [skills-reference.md](skills-reference.md)에 있습니다.

---

## 자주 쓰는 템플릿

스킬이 산출물을 쓸 때 `.claude/docs/templates/`의 템플릿(56개)을 그대로 따릅니다. 템플릿의 제목과 굵은 필드 이름은
스크립트와 게이트가 읽는 계약이므로 번역하거나 바꾸지 마세요.

| 템플릿 | 쓰임 | 주로 쓰는 스킬 |
|---|---|---|
| `product-brief.md`, `one-pager.md` | 제품 브리프(standard·full), 한 장짜리 기획(minimal) | `/brainstorm` |
| `persona.md`, `user-journey.md`, `user-flow.md` | 페르소나, 사용자 생애주기 여정, 화면 흐름 | `/brainstorm`, `/ux-design` |
| `feature-map.md`, `prd.md` | 기능 맵, 기능 PRD(11개 섹션) | `/map-features`, `/write-prd` |
| `tracking-plan.md`, `pricing-model.md` | 이벤트 트래킹 플랜, 요금제·가격 모델 | `/write-prd`, `/team-growth` |
| `architecture-decision-record.md`, `tech-radar.md`, `technical-design-document.md` | ADR, 기술 레이더, 기능별 기술 설계 | `/architecture-decision`, `/setup-stack`, `/create-architecture` |
| `api-guidelines.md`, `openapi-skeleton.yaml` | API 설계 가이드라인, OpenAPI 3.1 뼈대 | `/api-design` |
| `data-model.md`, `migration-plan.md` | 데이터 모델, expand/contract 마이그레이션 계획 | `/data-model` |
| `threat-model.md`, `slo.md`, `runbook.md` | 위협 모델, SLO, 런북 | `/security-audit`, `/create-architecture`, `/incident` |
| `design-language.md`, `ux-spec.md`, `app-shell.md`, `voice-and-tone.md` | 디자인 언어, 화면 명세, 앱 셸, 보이스 앤 톤 | `/design-language`, `/ux-design`, `/team-content` |
| `sprint-plan.md`, `test-plan.md`, `test-evidence.md` | 스프린트 계획, QA 계획, 테스트 증거 | `/sprint-plan`, `/qa-plan`, `/dev-story` |
| `walking-skeleton-report.md` | 워킹 스켈레톤 검증 보고서 | `/walking-skeleton` |
| `release-checklist-template.md`, `rollout-plan.md`, `release-notes.md` | 릴리스 체크리스트, 롤아웃 계획, 릴리스 노트 | `/release-checklist`, `/rollout-plan`, `/release-notes` |
| `incident-response.md`, `incident-postmortem.md` | 인시던트 기록, 포스트모템 | `/incident`, `/postmortem` |
| `project-retrospective.md` | 마일스톤·릴리스 회고 | `/retrospective` |

---

## 조율 규칙 요약

1. **수직 위임** — 디렉터 → 리드 → 스페셜리스트. 복잡한 결정에서 계층을 건너뛰지 않습니다.
2. **수평 협의** — 같은 계층끼리 의견을 구할 수 있지만 자기 영역 밖의 결정을 확정하지 않습니다.
3. **갈등 해결** — 제품·UX·디자인 갈등은 `product-director`, 기술·품질 갈등은 `technical-director`로 올립니다.
4. **변경 전파** — 여러 영역에 걸친 변경은 `delivery-manager`가 조율합니다.
5. **영역 경계** — 위임 없이 자기 영역 밖의 파일을 고치지 않습니다.

모든 스킬과 에이전트는 **질문 → 선택지 → 결정 → 초안 → 승인** 순서를 따르고, 쓰기 전에 "May I write this to
[filepath]?"라고 묻습니다. 커밋은 지시가 있을 때만 합니다.

---

## 새 프로젝트 시작 경로

**어디서 시작할지 모르겠다면 `/start`를 실행하세요.** 제품, 스택, 경험 수준에 대해 아무것도 가정하지 않고 묻습니다.

- **A. 아이디어가 없다** — `/brainstorm open` → `/setup-stack` → `/prd-review design/product/product-brief.md`
  → `/prototype`(선택) → `/gate-check definition` → `/map-features` → `/write-prd`(standard·full 기준)
- **B. 문제 영역은 있다** — `/brainstorm <문제 영역>` → 이후는 A와 같습니다.
- **C. 제품 컨셉이 분명하다** — `/brainstorm <컨셉>`(이미 아는 내용은 확인만 하는 빠른 경로) → `/setup-stack` →
  이후는 A와 같습니다.
- **D. 기존 제품이나 코드가 있다** — `/start`가 `stage-estimate.sh`로 단계를 추정 → `/adopt`로 형식 감사와 도입 계획 →
  계획에 따라 `/setup-stack`, `/project-stage-detect`, `/reverse-document`, `/architecture-decision retrofit <path>` →
  `/gate-check <목표 단계>`

`minimal`에서는 one-pager가 제품 브리프·기능 맵·PRD와 에픽·스프린트 계획을 대신하므로 경로가 훨씬 짧습니다.
A–C 모두 `/brainstorm` → `/setup-stack` → `/create-stories`(one-pager의 `## Build Order`를 스토리로) →
`/dev-story` 네 단계면 코드가 돌아가기 시작합니다. `/start`는 `modes.rigor`를 정한 뒤 그 값에 맞는 경로 하나만
보여 줍니다. 단계별 전체 흐름은
[WORKFLOW-GUIDE.md](../../docs/WORKFLOW-GUIDE.md)와 [skill-flow-diagrams.md](../../docs/skill-flow-diagrams.md)를
보세요.

---

## 파일 구조 참조

```text
CLAUDE.md                          # 마스터 설정 (영어, 먼저 읽는 파일)
project.yaml                       # 프로젝트 설정의 원본 — 스택, 모드, 단계
.claude/
  settings.json                    # 훅 등록, 권한, 안전 규칙
  agents/                          # 에이전트 정의 46개
  skills/                          # 스킬 76개 (스킬마다 디렉터리 하나)
  hooks/                           # 훅 파일 14개 (등록 12 + yaml-helper.sh + 선택형 log-instructions.sh)
  scripts/                         # 관측 전용 스크립트 8개 (artifact-check.sh, stage-estimate.sh 등)
  rules/                           # 경로별 규칙 16개
  statusline.sh                    # 상태 줄
  docs/
    quick-start.md                 # 이 파일
    workflow-catalog.yaml          # 7단계 파이프라인 정의 (/help, /gate-check가 읽음)
    effects-map.md                 # project.yaml 전체 스키마와 설정별 동작
    config-resolution.md           # 설정 해석 순서
    coding-standards.md            # 코딩·문서 표준, 스토리 유형별 증거, 언어 정책
    coordination-rules.md          # 에이전트 조율 규칙
    director-gates.md              # 디렉터 게이트 호출 규칙
    director-gates/                # 게이트 정의 29개
    automation-modes.md            # 자동화 모드와 항상 묻는 범주
    context-management.md          # 컨텍스트 관리와 세션 체크포인트
    directory-structure.md         # 프로젝트 디렉터리 구조
    code-root-resolution.md        # 코드 루트 해석 규칙
    run-and-observe.md             # 표면별 실행·관찰 절차
    compliance/                    # 지역별 규제 체크리스트 (kr, eu, us)
    setup-requirements.md          # 설치 준비물
    agent-roster.md                # 에이전트 목록
    skills-reference.md            # 스킬 목록
    rules-reference.md             # 규칙 목록
    templates/                     # 문서 템플릿 56개
```

---

## 자주 묻는 질문

### 모든 단계와 문서를 다 거쳐야 하나요?

아닙니다. `modes.rigor`가 얼마나 많은 과정을 요구할지 정합니다. `minimal`에서는 one-pager 한 장이 기획서와 스프린트
계획을 대신하고, PRD·ADR·디렉터 게이트가 필수가 아닙니다. `standard`와 `full`로 갈수록 필수 산출물이 늘어납니다.
프로젝트가 커지면 `/settings modes.rigor=standard`로 올리면 됩니다.

### 게이트가 `FAIL`이면 더 진행할 수 없나요?

게이트는 권고입니다. 무엇이 빠졌고 무엇이 위험한지 알려 줄 뿐, 진행을 강제로 막지 않고 산출물을 대신 만들지도
않습니다. 다만 `project.stage`는 판정이 `PASS`이고 사용자가 확인했을 때만 갱신됩니다.

### `review_mode`는 기본으로 무엇인가요?

설정하지 않은 프로젝트에서는 `modes.rigor`가 `minimal`로 해석되고, 그 결과 `review_mode`는 `solo`가 됩니다(디렉터 게이트
생략). `standard`는 `lean`(단계 게이트만), `full`은 `full`(모든 게이트)입니다. 한 번만 다르게 돌리려면 `--review full`
같은 플래그를 붙이세요. 단, `/hotfix`, `/rollout-plan`, `/incident`는 리뷰 모드와 관계없이 모든 게이트를 실행합니다.

### 에이전트가 운영 환경에 배포하거나 데이터베이스를 바꾸나요?

아니요. 운영 환경, 공유 인프라, 공유 데이터베이스, 시크릿을 바꾸는 명령은 자율 모드에서도 실행하지 않습니다. 사람이
실행할 명령과 영향 범위, 롤백 명령을 제안할 뿐입니다. `settings.json`의 거부 목록이 프로덕션 배포, `terraform apply`,
`kubectl apply`, 파괴적 DB 명령, 스토어 제출을 한 번 더 막습니다.

### 모델이 최신 프레임워크 버전을 알고 있나요?

모델은 학습 시점 이후의 변경을 모를 수 있습니다. 그래서 `/setup-stack`이 구성 요소마다 실시간 출처에서 버전을 확인해
`docs/stack-reference/`에 출처와 날짜와 함께 기록하고, 스택 스페셜리스트는 조언하기 전에 이 문서를 읽습니다. 확인할 수
없는 내용은 추측하지 않고 `NOT SOURCEABLE — run /setup-stack refresh`라고 답합니다.

### 모노레포가 아니어도 되나요? 코드는 어디에 두나요?

됩니다. 레이어마다 `stack.layers.<layer>.root`에 경로 하나(예: `src`) 또는 목록(예: `[apps/web, apps/admin]`)을
선언합니다. 아무것도 선언하지 않았고 저장소 루트에 매니페스트와 `src/`, `app/`, `lib/` 중 정확히 하나가 있으면 그
디렉터리를 단일 앱 루트로 감지합니다. 코드 루트를 결정할 수 없으면 스킬은 추측하지 않고 `NOT CHECKED` 줄로 알립니다.

### 웹만, 또는 API만 만드는 서비스에도 쓸 수 있나요?

쓸 수 있습니다. `platform.surfaces`에 실제로 내보내는 표면(`web`, `ios`, `android`, `api`)만 적으면, UI가 없는 서비스에서는
디자인 언어·UX 명세·접근성 항목이 `N/A`로 처리되고 스토어 관련 항목은 `release.distribution`에 따라 빠집니다. 값을
비워 두면 "없음"이 아니라 "모름"으로 보고 게이트가 묻습니다.

### 산출물은 어떤 언어로 쓰나요?

템플릿의 제목, 굵은 필드 이름, 판정·상태 토큰, YAML 키, ID, 경로는 영어 그대로 두고, 본문은 대화하는 언어(한국어로
대화하면 한국어)로 씁니다. 스크립트와 게이트가 제목을 기준으로 섹션을 찾으므로 제목은 번역하지 않습니다. 고객에게 나가는
문구는 `localization.locales`의 로케일로 씁니다.

### 한국 규제는 어떻게 다루나요?

`compliance.regions: [kr]`을 설정하면 개인정보 보호법, ISMS-P, 전자상거래법, 전자금융거래법, 정보통신망법의 광고성 정보
전송 규정, 알림톡 사용 범위, KWCAG 2.2 같은 항목을 체크리스트로 확인합니다. 무엇을 확인할지 알려 주는 목록이지 법률
자문이 아니며, 기한이나 과징금 같은 숫자는 출처가 있을 때만 적습니다.

### 자동화 모드를 `autonomous`로 해도 안전한가요?

`autonomous`에서도 `modes.automation_always_ask`에 있는 범주(기본: 범위 변경, 파일 삭제, 스키마 변경, 프로덕션 배포, DB
마이그레이션, 인프라 변경, 시크릿·개인정보 접근, 과금 변경)는 항상 묻습니다. `/gate-check`, `/hotfix`, `/incident`,
`/rollout-plan`, `/setup-stack`, `/start`, `/settings`는 모드와 관계없이 모든 단계를 승인받습니다.

### 스킬의 `model:` 설정으로 비용을 아낄 수 있나요?

아니요. 스킬 frontmatter의 `model:`은 선언되어 있지만 적용되지 않습니다. Claude Code는 스킬을 세션 모델로 실행합니다.
에이전트 frontmatter의 `model:`은 별개의 메커니즘이며, 역할의 무게를 나타내는 것이지 비용 계획이 아닙니다.

### 나만 다른 설정을 쓰고 싶어요

`/settings --local <key>=<value>`는 gitignore 대상인 `project.local.yaml`에 씁니다. 개인별로 덮어쓸 수 있는 키는
`modes.review_mode`, `modes.automation`, `modes.automation_always_ask`, `team.size`, `testing.strict.*`,
`performance.enforce`, `features.session_state`, `features.token_budget_warn_at`입니다. 팀 전체에 적용할 값은
`/settings <key>=<value>`로 `project.yaml`에 씁니다.

### 컨텍스트가 압축되거나 세션이 끊기면 어떻게 되나요?

`production/session-state/active.md`가 세션 체크포인트입니다. 압축 전후 훅이 상태를 보존하고 복원을 안내하며, 새 세션이
열리면 `session-start.sh`가 체크포인트를 미리 보여 줍니다. 문서는 섹션이 승인될 때마다 파일에 기록되므로 끊긴 지점부터
이어 갈 수 있습니다.

### 스킬이나 에이전트를 고쳤는데 괜찮은지 어떻게 확인하나요?

`/skill-test static <name>`(구조 린터), `/skill-test spec <name>`(동작 명세), `/skill-test category <name>`(품질 루브릭),
`/skill-test audit`(전체 커버리지)을 쓰세요. `/skill-improve <name>`은 테스트-수정-재테스트를 반복하고 점수가 떨어지면
되돌립니다. 스킬이나 에이전트 파일을 저장하면 `validate-skill-change.sh` 훅이 알맞은 테스트를 권합니다.
