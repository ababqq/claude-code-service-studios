# 스킬 레퍼런스 (슬래시 명령)

Claude Code에서 `/`를 입력하면 모든 스킬을 불러올 수 있습니다. 스킬 정의는
`.claude/skills/<name>/SKILL.md`에 있고, 디렉터리 이름이 곧 명령 이름입니다. 이 문서는 스킬을
카테고리별로 묶어 하는 일, 쓰이는 단계, 산출물, 관여 에이전트, 디렉터 게이트를 정리합니다.
카테고리는 스킬 테스트 프레임워크(`CCSS Skill Testing Framework/`)가 스킬을 검증할 때 쓰는
분류와 같습니다.

## 표 읽는 법

- **단계**: 스킬이 `.claude/docs/workflow-catalog.yaml`에서 어느 단계의 스텝으로 등장하는지를
  나타냅니다. 단계는 Discovery → Definition → Architecture → Validation → Build → Hardening →
  Launch 순서입니다. "상시"는 카탈로그 스텝이 아니라 어느 단계에서든 필요할 때 쓰는 스킬입니다.
  Launch는 마지막 단계이며, 출시 이후의 반복 릴리스·인시던트·그로스 작업도 Launch 단계 안에서
  게이트 없이 이어집니다. 단계별 흐름은 [워크플로 가이드](../../docs/WORKFLOW-GUIDE.md)를
  참고하십시오.
- **산출물**: 스킬이 쓰는 파일 경로입니다. `YYYY-MM-DD`, `<slug>`, `NNNN` 같은 자리는 실행할 때
  채워집니다. "대화로 보고"는 파일을 쓰지 않는다는 뜻입니다.
- **관여 에이전트**: 스킬이 호출하는 서브에이전트입니다. "라우팅된"은 `project.yaml`의
  `stack.layers.*` 설정에 따라 고른 스택 에이전트를 뜻합니다([에이전트 로스터](agent-roster.md)).
- **게이트**: 스킬이 띄우는 디렉터 게이트입니다([director-gates.md](director-gates.md)).

## 모든 스킬에 공통인 동작

- **설정 읽기**: 대부분의 스킬은 첫 줄에서 `.claude/hooks/yaml-helper.sh`의 `resolve_config`로
  필요한 설정만 읽습니다. 결과 블록이 없으면 `.claude/docs/config-resolution.md`의 기본값으로
  동작합니다. 설정이 필요 없는 일부 스킬(설정 전에 실행되는 `/start` 등)에는 이 단계가 없습니다.
- **쓰기 전 승인**: 파일을 쓰는 스킬은 쓰기 전마다 "May I write this to `<path>`?"라고 묻습니다.
  질문 문구는 영어가 기준이지만 실제로는 사용자의 대화 언어로 묻습니다.
- **자동화 모드**: `modes.automation`이 질문 빈도를 정합니다. `collaborative`는 매번 묻고,
  `guided`는 중요한 결정만 묻고, `autonomous`는 기록을 남기고 진행합니다.
  `modes.automation_always_ask`에 넣은 범주는 모드와 관계없이 항상 묻습니다. 자세한 규칙은
  [automation-modes.md](automation-modes.md)에 있습니다.
- **항상 협업형 스킬**: `/gate-check`, `/hotfix`, `/incident`, `/rollout-plan`, `/setup-stack`,
  `/start`, `/settings`는 `modes.automation`을 따르지 않고 모든 단계를 승인받습니다.
- **리뷰 모드와 게이트**: 게이트를 띄울지는 `modes.review_mode`가 정합니다. `full`은 모든 게이트를
  실행하고, `lean`은 ID가 `-PHASE-GATE`로 끝나지 않는 게이트를 건너뛰며(`[GATE-ID] skipped — Lean mode`),
  `solo`는 모든 게이트를 건너뜁니다(`[GATE-ID] skipped — Solo mode`). `review_mode`를 읽는 스킬은
  `--review full|lean|solo` 인자로 한 번만 바꿔 실행할 수 있습니다. `/hotfix`, `/rollout-plan`,
  `/incident`는 릴리스에 직결되므로 리뷰 모드와 관계없이 지정된 에이전트와 게이트를 모두
  실행합니다.
- **판정**: 판정이 있는 보고서는 H1 바로 아래에 `> **Verdict**: <TOKEN>` 줄을 둡니다. 확인할 수
  없는 것은 통과로 처리하지 않고 `NOT ASSESSED`로 판정하며, 건너뛴 검사는
  `NOT CHECKED — <이유>`로 밝힙니다.
- **직접 입력 전용**: `/dev-story`, `/hotfix`, `/incident`, `/rollout-plan`, `/story-done`은
  `disable-model-invocation: true`라서 Claude가 대화 중에 스스로 실행하지 않습니다. 사용자가
  명령을 입력해야 실행됩니다.
- **격리 실행**: `/prototype`만 frontmatter에 `isolation: worktree`를 선언해, 별도의 git
  worktree에서 실행되도록 의도되어 있습니다. `/review-all-prds`는 아직 커밋하지 않은 PRD까지
  읽어야 하므로 격리하지 않고 메인 작업 트리에서 실행됩니다.

## 게이트 (`gate`)

단계 전환 판정입니다. 게이트는 권고일 뿐 진행을 강제로 막지 않으며, 다음 단계로 넘어갈지는 항상 사용자가 정합니다.
인자는 **목표** 단계입니다: `/gate-check definition | architecture | validation | build | hardening | launch`.
인자 없이 실행하면 현재 단계를 추정해 다음 단계를 목표로 삼습니다. Launch는 마지막 단계라 그 뒤의 게이트는 없고,
출시 이후에는 `/release-checklist`, `/rollout-plan`, `/retrospective release <version>`을 씁니다.

| 명령 | 하는 일 | 단계 | 산출물 | 관여 에이전트 | 게이트 |
| ---- | ---- | ---- | ---- | ---- | ---- |
| `/gate-check` | 목표 단계로 넘어갈 준비가 되었는지 판정합니다. PASS/CONCERNS/NOT ASSESSED/FAIL과 함께 차단 요인과 필요한 산출물을 제시합니다. | 상시 | `production/gate-checks/gate-<target>-YYYY-MM-DD.md`, `project.yaml`의 `project.stage` | 디렉터 패널: `modes.workflow`가 `minimal`이면 `delivery-manager`, `standard`면 `technical-director`까지, `full`이면 `product-director`, `design-director`까지 네 명(UI 표면이 없으면 `design-director` 제외) | `PD-PHASE-GATE`, `TD-PHASE-GATE`, `DM-PHASE-GATE`, `DD-PHASE-GATE` |

## 리뷰 (`review`)

작성된 문서와 아키텍처를 검토합니다.

| 명령 | 하는 일 | 단계 | 산출물 | 관여 에이전트 | 게이트 |
| ---- | ---- | ---- | ---- | ---- | ---- |
| `/prd-review` | PRD 하나 또는 제품 브리프의 완결성, 일관성, 구현 가능성을 리뷰합니다. | Discovery, Definition | `<doc-dir>/reviews/<stem>-review-log.md`(`design/prd/reviews/…` 또는 `design/product/reviews/…`) | `product-manager`와 문서 내용에 따라 라우팅된 자문 에이전트 | — |
| `/review-all-prds` | PRD 전체를 아우르는 리뷰: 모순, 서로 충돌하는 한도·지표, 인지 부하, 제품 원칙에서의 이탈. | Definition | `design/prd/reviews/prd-cross-review-YYYY-MM-DD.md` | `product-manager`(자문) | — |
| `/architecture-review` | PRD 요구 사항과 ADR 사이의 추적성 매트릭스, ADR 간 충돌, 스택 호환성을 점검합니다. 판정: PASS/CONCERNS/NOT ASSESSED/FAIL. | Architecture | `docs/architecture/architecture-review-YYYY-MM-DD.md`, `docs/architecture/requirements-traceability.md`, `docs/architecture/tr-registry.yaml`(추가만) | 라우팅된 스택 리드 | — |

## 문서 작성 (`authoring`)

섹션별로 사용자와 함께 계약 산출물(PRD, UX 명세, 디자인 언어, 아키텍처, ADR, API 계약, 데이터 모델)을 씁니다. 각 섹션을 쓰기 전에 승인을 받습니다.

| 명령 | 하는 일 | 단계 | 산출물 | 관여 에이전트 | 게이트 |
| ---- | ---- | ---- | ---- | ---- | ---- |
| `/write-prd` | 기능 하나의 PRD를 섹션별로 씁니다. 의존성, 용어 레지스트리, 트래킹 플랜과 교차 참조합니다. | Definition, Launch | `design/prd/<feature>.md`, `design/product/feature-map.md`(상태), `design/registry/entities.yaml`, `design/product/tracking-plan.md`(이벤트 추가), `design/product/pricing-model.md`(PRD가 요금제·가격·크레딧을 정의할 때) | `product-manager`와 문서 내용에 따라 라우팅된 자문 에이전트 | `PD-PRD-ALIGN` |
| `/quick-spec` | 설정 변경, 동작 조정, 작은 개선을 위한 가벼운 명세를 롤아웃 메모와 함께 씁니다. | 상시 | `design/quick-specs/<kebab-title>-YYYY-MM-DD.md` | — | — |
| `/ux-design` | 화면이나 플로우의 UX 명세를 섹션별로 씁니다. 앱 셸, 인터랙션 패턴, 접근성, 사용자 여정 모드가 있습니다. | Definition, Architecture, Validation, Build | `design/ux/<slug>.md`, `design/ux/app-shell.md`, `design/ux/interaction-patterns.md`, `design/accessibility-requirements.md`(+ `project.yaml`의 `accessibility.target`), `design/product/user-journey.md` | `product-designer`, `ux-writer`, `frontend-engineer`·`mobile-engineer`(구현 가능성), `accessibility-specialist` | — |
| `/ux-review` | UX 명세, 앱 셸, 패턴 라이브러리를 검증합니다. 판정: APPROVED / NEEDS REVISION / MAJOR REVISION NEEDED / NOT ASSESSED. | Validation | `design/ux/reviews/<spec-stem>-ux-review-YYYY-MM-DD.md` | `design-director`(게이트) | `DD-UI-CONSISTENCY` |
| `/design-language` | UI 제작의 관문이 되는 디자인 언어(9개 섹션)를 씁니다. 제품 브리프에 브랜드 방향이 없으면 브랜드 방향부터 정합니다. | Validation | `design/brand/design-language.md`, `design/brand/tokens.json`(선택) | `design-director`(게이트), `design-engineer`, `product-designer`, `accessibility-specialist` | `DD-BRAND-DIRECTION`, `DD-DESIGN-LANGUAGE` (`DD-BRAND-DIRECTION`은 브리프에 `## Brand Direction Anchor`가 없을 때) |
| `/create-architecture` | 아키텍처 청사진: 레이어, 토폴로지와 환경, 데이터 흐름, 외부 연동, 관측성, SLO. 기능별 기술 설계도 선택적으로 씁니다. | Architecture | `docs/architecture/architecture.md`, `docs/ops/slo.md`, `docs/architecture/tdd-<feature>.md`(`tdd` 모드) | `tech-lead`, `technical-director`, 라우팅된 스택 리드, `sre-engineer`(SLO 자문) | `TD-ARCHITECTURE`, `TL-FEASIBILITY` |
| `/architecture-decision` | ADR을 새로 쓰거나, 이미 내린 결정을 소급해 기록하거나, 승인합니다. 배경, 대안, 결과, 스택 호환성, 반영한 PRD 요구 사항을 담습니다. | Architecture | `docs/architecture/adr-NNNN-<slug>.md`, `docs/registry/architecture.yaml`, `docs/architecture/tech-radar.md`(갱신) | `technical-director`, `tech-lead`, 라우팅된 스택 리드 | `TD-ADR`, `TD-STACK-RISK`, `SE-SECURITY-REVIEW` (`TD-STACK-RISK`는 Knowledge Risk가 HIGH·MEDIUM일 때, `SE-SECURITY-REVIEW`는 ADR Domain이 `Auth`·`Security`·`Data`일 때) |
| `/api-design` | 계약 우선(contract-first) API 설계: API 가이드라인, OpenAPI/GraphQL/proto/AsyncAPI 계약, UX 명세와의 정합, 린트, 하위 호환성을 깨는 변경 점검. | Architecture, Validation | `docs/api/api-guidelines.md`, `docs/api/openapi.yaml`(또는 `docs/api/schema.graphql`, `docs/api/<service>.proto`, `docs/api/asyncapi.yaml`), `docs/api/changes/api-change-YYYY-MM-DD.md`, `docs/api/guides/<slug>.md`(공개 API일 때만) | `tech-lead`, 라우팅된 백엔드 서브(없으면 `backend-specialist`), `frontend-engineer`·`mobile-engineer`(`workflow: full`에서 소비자 관점 리뷰), `ux-writer`(개발자 가이드) | `SE-SECURITY-REVIEW` |
| `/data-model` | 데이터 모델(소유권, 데이터 분류, 보존 기간, 인덱스)과 expand/contract 방식의 마이그레이션 계획을 씁니다. | Architecture | `docs/data/data-model.md`, `docs/data/migrations/NNNN-<slug>.md`, `stack.layers.data.migrations_dir` 아래 마이그레이션 파일(선택), `project.yaml`(`privacy.handles_pii`, 먼저 확인) | `data-specialist`, `backend-engineer`, `tech-lead` | `SE-SECURITY-REVIEW` |

## 스토리 준비·완료 (`readiness`)

스토리를 집어 들기 전과 닫기 전에 확인합니다.

| 명령 | 하는 일 | 단계 | 산출물 | 관여 에이전트 | 게이트 |
| ---- | ---- | ---- | ---- | ---- | ---- |
| `/story-readiness` | 스토리가 구현할 준비가 되었는지 판정합니다: READY / NEEDS WORK / BLOCKED / NOT ASSESSED. | Build | 대화 내 보고만(Write·Edit 도구가 없어 스토리 파일을 수정하지 않음) | `qa-lead`(게이트) | `QL-STORY-READY` |
| `/story-done` | 인수 조건과 증거, PRD·ADR·API와의 차이, 코드 리뷰를 확인하고 스토리를 닫습니다. | Build | 스토리 파일, `production/sprint-status.yaml`(`done`) | `tech-lead`, `qa-lead`(게이트) | `TL-CODE-REVIEW`, `QL-TEST-COVERAGE` |

## 파이프라인 (`pipeline`)

앞 단계의 산출물을 다음 단계의 산출물로 바꿉니다. 브리프 → 기능 맵 → 에픽 → 스토리 → 구현으로 이어집니다.

| 명령 | 하는 일 | 단계 | 산출물 | 관여 에이전트 | 게이트 |
| ---- | ---- | ---- | ---- | ---- | ---- |
| `/map-features` | 제품 브리프를 기능과 의존성으로 분해하고 MVP / Beta / GA / Later 티어로 나눠 기능 맵을 만듭니다. | Definition | `design/product/feature-map.md` | 게이트로 호출되는 `product-director`, `technical-director`, `delivery-manager` | `PD-FEATURE-MAP`, `TD-DOMAIN-BOUNDARY`, `DM-SCOPE` |
| `/create-control-manifest` | 승인된(Accepted) ADR과 기술 레이더에서 레이어별 "반드시 / 절대 금지" 규칙을 평평한 목록으로 뽑습니다. | Validation | `docs/architecture/control-manifest.md` | `technical-director` | `TD-MANIFEST` |
| `/create-epics` | PRD, 아키텍처, API 계약으로 에픽을 만듭니다. 모듈당 하나이며, 어디에도 추적되지 않은 요구 사항을 드러냅니다. | Validation | `production/epics/<epic-slug>/EPIC.md`, `production/epics/index.md` | `delivery-manager`(게이트) | `DM-EPIC` |
| `/create-stories` | 에픽 하나를 스토리로 나눕니다. 각 스토리에 TR-ID, ADR 지침, API 계약, 마이그레이션, 플래그, 인수 조건을 담습니다. | Validation | `production/epics/<epic-slug>/story-NNN-<slug>.md` | `qa-lead`(게이트) | `QL-STORY-READY` |
| `/walking-skeleton` | CI/CD를 거쳐 스테이징에 배포되는, 실제 코드로 된 얇은 종단 간 경로를 만들고 롤백과 플래그 전환을 리허설합니다. 판정: VALIDATED / NOT VALIDATED / NOT ASSESSED. | Validation | 확인된 코드 루트의 브랜치 코드; `production/walking-skeleton/report-YYYY-MM-DD.md` | `tech-lead`, `backend-engineer`, `frontend-engineer`, `mobile-engineer`, `platform-engineer`, `devops-engineer`, `sre-engineer` | `PD-USER-VALIDATION` (스켈레톤으로 사용성 세션을 진행할 때만) |
| `/dev-story` | 스토리를 구현합니다: ADR 지침 확인, 담당 엔지니어와 스택 스페셜리스트 배정, 코드와 테스트 작성, 실행·관찰. | Build, Launch | 확인된 코드 루트의 코드·테스트; `production/qa/evidence/<story-slug>/…`; `production/sprint-status.yaml`(`in-progress`) | [에이전트 로스터](agent-roster.md)의 `/dev-story` 배정 규칙에 따름 | — |
| `/propagate-prd-change` | PRD가 바뀌었을 때 낡아진 ADR, API 계약 오퍼레이션, 데이터 모델 엔티티, 트래킹 이벤트, 스토리를 찾습니다. | 상시 | `docs/architecture/change-impact-YYYY-MM-DD-<prd-stem>.md` | `technical-director`(게이트) | `TD-CHANGE-IMPACT` |

## 분석 (`analysis`)

현재 상태를 측정하거나 점검해 보고합니다.

| 명령 | 하는 일 | 단계 | 산출물 | 관여 에이전트 | 게이트 |
| ---- | ---- | ---- | ---- | ---- | ---- |
| `/consistency-check` | PRD들을 용어 레지스트리와 대조해 엔티티, 요금제, 규칙, 상수, 이벤트의 모순을 찾습니다. | Definition | `docs/consistency-failures.md`(실행 시 생성, gitignore 대상), `design/registry/entities.yaml`(갱신) | — | — |
| `/code-review` | 서비스 관점의 아키텍처 코드 리뷰: 인가(authz), 입력 검증, N+1 쿼리, 트랜잭션, 멱등성, 타임아웃, 페이지네이션, 로그 속 개인정보. | Build | 대화로 보고(파일 없음) | 라우팅된 스택 스페셜리스트, `qa-engineer`, `security-engineer`(인증·개인정보 코드를 건드릴 때) | — |
| `/scope-check` | PRD의 Goals & Non-Goals와 원페이저를 기준으로 범위 증가(scope creep)를 점검합니다. | Build | 대화로 보고 | — | — |
| `/estimate` | 복잡도, 의존성, 속도(velocity), 서비스 특유의 리스크 요인으로 작업량을 추정합니다. | 상시 | 대화로 보고 | — | — |
| `/tech-debt` | 기술 부채를 추적하고 분류(Security, Infra, Observability 포함)해 우선순위를 매깁니다. | 상시 | `docs/tech-debt-register.md` | — | — |
| `/perf-profile` | `performance.*` 예산 대비 성능을 측정하고, 우선순위를 매긴 최적화 권고를 냅니다. | Hardening | `production/qa/perf/perf-profile-<scope>-YYYY-MM-DD.md` | `performance-engineer` | — |
| `/bundle-audit` | 라우트별 JS/CSS, 이미지, 폰트(CJK 서브세팅)와 모바일 앱 크기를 예산과 비교하고, 정적 자산 이름 규칙을 점검합니다. | Hardening | `production/qa/perf/bundle-audit-YYYY-MM-DD.md` | `performance-engineer` | — |
| `/business-rules-check` | 요금제 단계, 한도·쿼터, 수수료와 반올림, 프로모션 중복 적용, 크레딧 경제, 환불 규칙, 악용 경로를 점검합니다. | Hardening | `production/qa/business-rules/business-rules-check-<scope>-YYYY-MM-DD.md` | `business-analyst`, `monetization-strategist` | — |
| `/feature-audit` | 계획(PRD 요구 사항, 화면, 엔드포인트, 이벤트, 플래그, 알림 템플릿, 로케일)과 실제 구현을 대조합니다. | Hardening | `production/qa/feature-audit-YYYY-MM-DD.md` | — | — |
| `/security-audit` | 보안·개인정보 감사(OWASP Top 10, API Top 10, MASVS, 시크릿, 보안 헤더, 의존성·SBOM, IaC, 개인정보, 지역별 체크리스트)와 위협 모델링. | Architecture, Hardening | `production/security/security-audit-<mode>-YYYY-MM-DD.md`(모드: full, quick, privacy, api, mobile, deps); `docs/security/threat-model.md`(`threat-model` 모드만) | `security-engineer` | — |
| `/test-evidence-review` | 증거의 품질을 검토합니다: 단언(assertion) 커버리지, Playwright 트레이스, 시각 비교, axe 보고서, 계약 검증. 판정: ADEQUATE/INCOMPLETE/MISSING/NOT ASSESSED. | 상시 | `production/qa/evidence-review-YYYY-MM-DD.md` | — | — |
| `/test-flakiness` | CI 이력(Jest/Vitest/Playwright/pytest의 JUnit 결과)에서 불안정한(flaky) 테스트를 찾고 격리를 권고합니다. | 상시 | `tests/regression-suite.md`, `production/qa/flakiness-report-YYYY-MM-DD.md` | — | — |

## 팀 오케스트레이션 (`team`)

여러 에이전트를 한 작업 영역에 묶어 파이프라인으로 돌립니다. 시작할 때 `team.size`(`individual` / `small` / `studio`)에 따라 참여하는 에이전트를 알려 주며, 규모를 줄여도 디렉터 게이트는 빠지지 않습니다.

| 명령 | 하는 일 | 단계 | 산출물 | 관여 에이전트 | 게이트 |
| ---- | ---- | ---- | ---- | ---- | ---- |
| `/team-feature` | 기능 스쿼드: PRD와 인수 조건 확인, UX 변경분, API·데이터 계약, 표면별 병렬 구현, 계약·E2E 테스트, QA. | Build | 단계별 산출물(UX 명세, API·데이터 계약 변경, 코드와 테스트, `production/qa/bugs/BUG-NNNN.md`) | `product-manager`, `product-designer`, `tech-lead`, `backend-engineer`, `frontend-engineer`, `mobile-engineer`, `qa-engineer`; `team.size: studio`면 라우팅된 스택 서브, `security-engineer` 추가 | — |
| `/team-ui` | 웹·모바일 UI 파이프라인: 명세, 시각 디자인, 구현, 리뷰, 마무리 다듬기. | Build | `design/ux/…`, 코드 루트의 구현 | `product-designer`, `design-engineer`, `frontend-engineer`, `mobile-engineer`, `accessibility-specialist`; `team.size: studio`면 `ux-writer`, 라우팅된 스택 서브 추가; `design-director`(게이트) | `DD-UI-CONSISTENCY` |
| `/team-content` | 콘텐츠 디자인: 보이스 앤 톤, 마이크로카피, 알림(푸시 / 이메일 / SMS / 알림톡), 헬프센터, 스토어 문구. 수신 동의와 발송 채널 점검을 포함합니다. | Build | `design/brand/voice-and-tone.md`, `design/content/<area>.md`, `design/content/help-center/<slug>.md` | `ux-writer`, `localization-lead`, `customer-success-manager`, `accessibility-specialist`, `design-director`(게이트) | `DD-CONTENT-VOICE` |
| `/team-qa` | 전체 QA 사이클: 전략, 테스트 케이스, 실행, 버그, 사인오프. | Build, Hardening | `production/qa/qa-plan-<sprint>-YYYY-MM-DD.md`, `production/qa/test-cases/<feature>-cases.md`, `production/qa/bugs/BUG-NNNN.md`, `production/qa/qa-signoff-<sprint>-YYYY-MM-DD.md` | `qa-lead`, `qa-engineer`; `team.size: studio`면 `accessibility-specialist` 추가 | `QL-TEST-COVERAGE` |
| `/team-hardening` | 안정화 패스: 성능, 신뢰성, 보안 약식 감사, 접근성 감사, UI 일관성, 회귀. | Hardening | `production/qa/hardening-YYYY-MM-DD.md`(단일 보고서) | `performance-engineer`, `sre-engineer`, `security-engineer`, `accessibility-specialist`, `qa-engineer`; `team.size: studio`면 `design-engineer`(UI 일관성), 라우팅된 스택 리드 추가 | — |
| `/team-release` | 릴리스 트레인과 롤아웃 계획을 실행하고 모든 단계를 기록합니다. | Launch | `production/releases/<version>/release-record.md`, `project.yaml`(`project.version`, 먼저 확인) | `release-manager`, `qa-lead`, `devops-engineer`, `sre-engineer`; `team.size: studio`면 `security-engineer`, `customer-success-manager`, `localization-lead`, `delivery-manager`, `analytics-engineer` 추가 | — |
| `/team-growth` | 그로스 실험이나 라이프사이클 캠페인: 가설, 규모 산정, 계측, 스토리로 만든 변형안, 롤아웃, 결과 판독. | Launch | `production/growth/<experiment-slug>/brief.md`, `production/growth/<experiment-slug>/readout.md`, `design/product/tracking-plan.md`(갱신) | `growth-manager`, `analytics-engineer`, `product-designer`, `ux-writer`; `team.size: studio`면 `monetization-strategist`, `customer-success-manager`, `data-engineer` 추가 | — |

## 스프린트·릴리스 기록 (`sprint`)

스프린트와 마일스톤을 계획·추적하고 변경 이력을 남깁니다.

| 명령 | 하는 일 | 단계 | 산출물 | 관여 에이전트 | 게이트 |
| ---- | ---- | ---- | ---- | ---- | ---- |
| `/sprint-plan` | 마일스톤, 완료된 작업, 가용 인원으로 스프린트 계획을 세우고 `sprint-status.yaml`을 씁니다. `modes.review_mode`는 절대 쓰지 않습니다. | Validation, Build, Launch | `production/sprints/sprint-NN.md`, `production/sprint-status.yaml` | `delivery-manager`(게이트) | `DM-SPRINT` |
| `/sprint-status` | 빠른 스프린트 현황: 번다운과 새로 떠오르는 리스크. | Build | 대화로 보고 | — | — |
| `/milestone-review` | 마일스톤(MVP / Private Beta / Public Beta / GA)의 진행 상황과 품질·운영 지표를 검토하고 go/no-go를 판단합니다. | 상시 | `production/milestones/<milestone>-review.md` | `delivery-manager`(게이트) | `DM-MILESTONE` |
| `/retrospective` | 스프린트·마일스톤·릴리스 회고와 실행 가능한 인사이트. 릴리스 모드에서는 결과를 PRD 성공 지표와 비교합니다. | Build, Launch | `production/retrospectives/retro-sprint-<N>-YYYY-MM-DD.md` / `retro-<milestone>-YYYY-MM-DD.md` / `retro-release-<version>-YYYY-MM-DD.md` | `analytics-engineer`(릴리스 모드) | — |
| `/changelog` | 커밋과 스프린트 기록으로 Keep a Changelog 형식의 변경 이력을 만듭니다(내부용·공개용 섹션). | Hardening, Launch | `docs/CHANGELOG.md` | — | — |
| `/release-notes` | `docs/CHANGELOG.md`를 바탕으로 채널별 고객용 릴리스 노트를 씁니다. | Hardening, Launch | `production/releases/<version>/release-notes.md` | — | — |

## 운영 (`ops`)

출시와 장애 대응입니다. `/rollout-plan`, `/incident`, `/hotfix`는 항상 협업형이고 리뷰 모드와 관계없이 지정된 에이전트와 게이트를 모두 실행합니다. 프로덕션을 바꾸는 명령은 사람이 실행하고, 에이전트는 상태 확인·명령 제안·결과 검증·기록을 맡습니다.

| 명령 | 하는 일 | 단계 | 산출물 | 관여 에이전트 | 게이트 |
| ---- | ---- | ---- | ---- | ---- | ---- |
| `/rollout-plan` | 점진적 배포 계획: 플래그·카나리 단계, 모바일 단계적 출시, 마이그레이션 순서, 가드레일, 중단 임곗값, 롤백, 커뮤니케이션. | Hardening, Launch | `production/releases/<version>/rollout-plan.md` | `release-manager`, `devops-engineer`, `qa-lead`, `customer-success-manager`, `sre-engineer`(게이트) | `SR-PRODUCTION-READINESS` |
| `/incident` | 인시던트 대응: SEV 분류, 역할, 완화, 커뮤니케이션, 타임라인, 해결. 런북 작성 모드도 있습니다. | Hardening, Launch | `production/incidents/INC-YYYYMMDD-NN.md`, `docs/ops/runbooks/<alert-slug>.md`(`runbook` 모드) | `sre-engineer`, `backend-engineer`·`devops-engineer`(진단), `security-engineer`(보안 인시던트), `customer-success-manager`(고객 커뮤니케이션) | — |
| `/hotfix` | 긴급 수정: 먼저 완화(플래그, 되돌리기, 서버 측 조치)하고, 트렁크에서 수정해 배포하거나 스토어 빌드를 패치하고, 검증·기록한 뒤 인시던트와 연결합니다. | Launch | `production/hotfixes/hotfix-YYYY-MM-DD-<slug>.md` | `tech-lead`(승인), `qa-engineer`, `sre-engineer`, `security-engineer`(보안 수정), `product-manager`(고객에게 보이는 변경이면 승인), `release-manager`(iOS·Android 스토어 경로 자문) | — |
| `/postmortem` | 인시던트의 비난 없는(blameless) 포스트모템: 타임라인, 영향, 기여 요인, 액션 아이템. | Launch | `production/incidents/postmortems/INC-YYYYMMDD-NN.md` | `sre-engineer`, `tech-lead` | — |

## 유틸리티 (`utility`)

특정 산출물 계열에 속하지 않는 도구 모음입니다.

### 시작·탐색·설정

| 명령 | 하는 일 | 단계 | 산출물 | 관여 에이전트 | 게이트 |
| ---- | ---- | ---- | ---- | ---- | ---- |
| `/start` | 처음 시작할 때의 온보딩. 지금 어디에 있는지(A–D) 묻고 알맞은 워크플로로 안내합니다. | 상시 | `project.yaml`(`project.stage`, `modes.rigor`, `modes.automation`만) | — | — |
| `/help` | 다음에 무엇을 해야 할지 알려 줍니다. 막혔거나 다음 단계가 불확실할 때 씁니다. | 상시 | 없음 | — | — |
| `/project-stage-detect` | 지금 어디에 있는지 진단합니다. `stage-estimate.sh`로 단계를 추정하고, 빠진 산출물과 다음 단계를 정리합니다. | 상시 | `production/project-stage-report-YYYY-MM-DD.md` | — | — |
| `/settings` | 프로젝트 설정을 보거나 바꿉니다. 병합된 실제 값을 보여 주거나 `project.local.yaml`에 로컬 재정의를 씁니다. | 상시 | `project.yaml`, `project.local.yaml` | — | — |
| `/setup-stack` | 레이어별 스택을 고르고, 실시간 출처에서 버전을 고정하고, 스택 레퍼런스를 채우고, 코드 루트를 선언하고, 스페셜리스트 라우팅을 설정합니다. | Discovery, Definition, Architecture | `project.yaml`(`stack.*`, `specialists.*`, `naming.*`, `commands.*`, `platform.*`, `release.*`, `privacy.*`, `compliance.*`, `localization.*`), `docs/stack-reference/VERSION.md`, `docs/stack-reference/<component>/*.md`, `docs/architecture/tech-radar.md`, `<root>/CLAUDE.md` | 라우팅된 스택 리드(선택 검증), `technical-director`(게이트, `upgrade` 모드) | `TD-STACK-RISK` (`upgrade` 모드에서) |
| `/onboard` | 새 기여자나 에이전트를 위한 역할별 온보딩 문서를 만듭니다(pm, designer, frontend, backend, mobile, sre, security, data). | 상시 | `production/onboarding/onboard-<role>-YYYY-MM-DD.md` | — | — |

### 기존 프로젝트 도입

| 명령 | 하는 일 | 단계 | 산출물 | 관여 에이전트 | 게이트 |
| ---- | ---- | ---- | ---- | ---- | ---- |
| `/adopt` | 기존(브라운필드) 프로젝트 감사. 기존 산출물이 CCSS 계약(PRD 섹션, 기능 맵, ADR 헤딩, API 계약, 마이그레이션, 테스트·CI, 런북)을 따르는지 확인하고 번호 매긴 도입 계획을 만듭니다. | 상시 | `docs/adoption-plan-YYYY-MM-DD.md` | — | — |
| `/reverse-document` | 기존 코드나 프로토타입에서 빠진 PRD, ADR, 제품 브리프를 역으로 작성합니다. | 상시 | `design/prd/<feature>.md`, `docs/architecture/adr-NNNN-<slug>.md`, `design/product/product-brief.md`(기존 브리프는 묻지 않고 덮어쓰지 않음) | — | — |

### 제품 발견·디자인 검증

| 명령 | 하는 일 | 단계 | 산출물 | 관여 에이전트 | 게이트 |
| ---- | ---- | ---- | ---- | ---- | ---- |
| `/brainstorm` | 제품 발견을 안내합니다: 문제, JTBD, 사용자, 대안, 가치 제안, 비즈니스 모델, 제품 원칙, 지표, 가장 위험한 가정. | Discovery | `design/product/product-brief.md`(standard·full 티어) 또는 `design/product/one-pager.md`(minimal 티어); `design/product/personas/<slug>.md`(선택); `design/product/pitch.md`(`pitch` 모드); `project.yaml`(`project.name`, `project.category`) | 게이트로 호출되는 `product-director`, `technical-director`, `delivery-manager`, `design-director`; `ux-researcher`(페르소나) | `PD-PRINCIPLES`, `TD-FEASIBILITY`, `DM-SCOPE`, `DD-BRAND-DIRECTION` (`DD-BRAND-DIRECTION`은 선택 사항(`full` 티어이고 UI 표면이 있을 때)) |
| `/prototype` | 가장 위험한 가정을 검증하는 콘셉트 프로토타입: 클릭 가능한 프로토타입, 페이크 도어, 컨시어지, 코드 스파이크. 판정: PROCEED/PIVOT/KILL/NOT ASSESSED. | Discovery | `prototypes/<name>-concept/`(`REPORT.md`, `PIVOT-NOTE.md` 포함); `prototypes/<name>-spike-YYYY-MM-DD/SPIKE-NOTE.md`(`--spike`); 기존 디렉터리의 `REPORT.md`(`report` 모드) | `prototyper`(코드로 만들 때), `ux-researcher`(세션 진행) | `PD-USER-VALIDATION` |
| `/usability-report` | 사용성·베타·인터뷰 보고서: 과업 성공률, 과업 소요 시간, SEQ/SUS, 심각도별 이슈. | Validation, Hardening | `production/qa/usability/usability-YYYY-MM-DD-<slug>.md` | `ux-researcher` | `PD-USER-VALIDATION` |
| `/ui-inventory` | 표면별 화면·컴포넌트 목록과 미디어 자산 명세(아이콘, 일러스트, 스토어 스크린샷, OG 이미지)를 만듭니다. | Validation | `design/inventory/screen-inventory.md`, `design/inventory/media-manifest.md` | `product-designer`, `design-engineer` | — |

### 테스트·품질

| 명령 | 하는 일 | 단계 | 산출물 | 관여 에이전트 | 게이트 |
| ---- | ---- | ---- | ---- | ---- | ---- |
| `/test-setup` | 레이어별 테스트 러너(unit, integration, contract, E2E), 웹 캡처 스크립트, CI 워크플로를 스캐폴딩합니다. | Architecture | 러너 설정 파일, `tests/{unit,integration,contract,e2e}/`, `tests/e2e/capture.spec.ts`(웹), `.github/workflows/ci.yml`, `project.yaml`(`testing.framework`, `testing.patterns`, `commands.test`, `commands.e2e`, `commands.lint`, `commands.typecheck`) | — | — |
| `/test-helpers` | 레이어별 테스트 헬퍼 라이브러리: 팩토리(고정 시드), 인증 픽스처, DB 초기화·시드, 네트워크 목(mock), Playwright 픽스처. | 상시 | `tests/helpers/**` | — | — |
| `/qa-plan` | `templates/test-plan.md`의 헤딩에 맞춰 스프린트나 기능 단위의 QA 계획을 씁니다. | Build | `production/qa/qa-plan-<sprint-slug>-YYYY-MM-DD.md` | — | — |
| `/smoke-check` | QA 인계 전 핵심 경로 스모크 게이트: 부팅, 헬스 체크, 인증, 핵심 여정, 외부 연동, 마이그레이션. | Build, Hardening, Launch | `production/qa/smoke-YYYY-MM-DD.md` | — | — |
| `/regression-suite` | 테스트 커버리지를 PRD의 핵심 경로와 핵심 사용자 여정에 매핑하고, 회귀 테스트 없이 수정된 버그를 찾습니다. | 상시 | `tests/regression-suite.md` | — | — |
| `/bug-report` | 서비스 환경 정보 블록을 갖춘 구조화된 버그 리포트를 쓰거나, 코드를 분석해 잠재 버그를 찾습니다. 재현 절차와 심각도를 포함합니다. | Build | `production/qa/bugs/BUG-NNNN.md` | — | — |
| `/bug-triage` | 해결되지 않은 버그를 다시 평가합니다: 심각도와 우선순위, 스프린트 배정, 반복되는 경향. | 상시 | `production/qa/bug-triage-YYYY-MM-DD.md` | — | — |
| `/load-test` | 스테이징에서 SLO 임곗값을 기준으로 부하 테스트 프로토콜을 만들고 실행합니다(smoke, load, stress, spike, soak 프로필). | Hardening | `tests/load/<profile>.<ext>`, `production/qa/load/load-test-<profile>-YYYY-MM-DD.md` | `performance-engineer`, `sre-engineer` | — |

### 출시 준비

| 명령 | 하는 일 | 단계 | 산출물 | 관여 에이전트 | 게이트 |
| ---- | ---- | ---- | ---- | ---- | ---- |
| `/localize` | i18n 파이프라인: 하드코딩 문자열, 추출, ICU, 문화적 검토, RTL·CJK 점검, 문자열 동결, 현지화 QA. | Hardening | `production/localization/…`, `production/qa/localization-qa-YYYY-MM-DD.md`(`qa` 모드) | `localization-lead`, `ux-writer` | — |
| `/release-checklist` | 릴리스별 체크리스트(빌드, 마이그레이션, 플래그, 설정·시크릿, 관측성, 롤백, 웹·스토어 항목, 리전). GO/NO-GO/NOT ASSESSED. | Hardening, Launch | `production/releases/<version>/release-checklist.md` | — | — |
| `/launch-checklist` | 제품, 엔지니어링·SRE, 보안·개인정보, 법무, 고객 지원, 시장 출시(GTM) 전반의 GA 출시 준비도를 점검합니다. GO/NO-GO/NOT ASSESSED. | Hardening | `production/releases/<version>/launch-checklist.md` | `sre-engineer`(자문), `security-engineer`(자문) | — |

### 프레임워크 관리

| 명령 | 하는 일 | 단계 | 산출물 | 관여 에이전트 | 게이트 |
| ---- | ---- | ---- | ---- | ---- | ---- |
| `/skill-test` | 스킬과 에이전트를 검증합니다: 정적 린터, 스펙, 카테고리 루브릭, 감사. | 상시 | `CCSS Skill Testing Framework/results/…`, 카탈로그의 `last_*` 필드 | — | — |
| `/skill-improve` | 정적 검사와 카테고리 검사로 테스트-수정-재테스트 루프를 돌려 스킬 하나를 개선하고, 점수 변화에 따라 변경을 유지하거나 되돌립니다. | 상시 | SKILL.md 한 개 수정 | — | — |

## 단계별 찾아보기

위 표의 "단계" 열을 단계 기준으로 다시 모은 것입니다. 한 스킬이 여러 단계에 나올 수 있습니다.

| 단계 | 스킬 |
| ---- | ---- |
| Discovery | `/brainstorm`, `/prd-review`, `/prototype`, `/setup-stack` |
| Definition | `/consistency-check`, `/map-features`, `/prd-review`, `/review-all-prds`, `/setup-stack`, `/ux-design`, `/write-prd` |
| Architecture | `/api-design`, `/architecture-decision`, `/architecture-review`, `/create-architecture`, `/data-model`, `/security-audit`, `/setup-stack`, `/test-setup`, `/ux-design` |
| Validation | `/api-design`, `/create-control-manifest`, `/create-epics`, `/create-stories`, `/design-language`, `/sprint-plan`, `/ui-inventory`, `/usability-report`, `/ux-design`, `/ux-review`, `/walking-skeleton` |
| Build | `/bug-report`, `/code-review`, `/dev-story`, `/qa-plan`, `/retrospective`, `/scope-check`, `/smoke-check`, `/sprint-plan`, `/sprint-status`, `/story-done`, `/story-readiness`, `/team-content`, `/team-feature`, `/team-qa`, `/team-ui`, `/ux-design` |
| Hardening | `/bundle-audit`, `/business-rules-check`, `/changelog`, `/feature-audit`, `/incident`, `/launch-checklist`, `/load-test`, `/localize`, `/perf-profile`, `/release-checklist`, `/release-notes`, `/rollout-plan`, `/security-audit`, `/smoke-check`, `/team-hardening`, `/team-qa`, `/usability-report` |
| Launch | `/changelog`, `/dev-story`, `/hotfix`, `/incident`, `/postmortem`, `/release-checklist`, `/release-notes`, `/retrospective`, `/rollout-plan`, `/smoke-check`, `/sprint-plan`, `/team-growth`, `/team-release`, `/write-prd` |
| 상시 | `/adopt`, `/bug-triage`, `/estimate`, `/gate-check`, `/help`, `/milestone-review`, `/onboard`, `/project-stage-detect`, `/propagate-prd-change`, `/quick-spec`, `/regression-suite`, `/reverse-document`, `/settings`, `/skill-improve`, `/skill-test`, `/start`, `/tech-debt`, `/test-evidence-review`, `/test-flakiness`, `/test-helpers` |

## Claude Code 번들 스킬과 이름이 겹칠 때

Claude Code에는 자체 번들 스킬이 있고, 그중 `/code-review`가 CCSS 스킬과 이름이 같습니다.
프로젝트 스킬은 같은 이름의 번들 스킬을 대체하지만, 번들 스킬의 별칭까지 대체하지는 않습니다.

| 입력 | 실행되는 스킬 | 용도 |
| ---- | ---- | ---- |
| `/code-review` | **CCSS 스킬** (프로젝트 스킬이 이름을 차지합니다) | 이 프로젝트의 코딩 표준, 컨트롤 매니페스트, ADR, API 계약을 기준으로 한 아키텍처 리뷰. 인가, 입력 검증, N+1, 트랜잭션, 멱등성 같은 서비스 관점을 보고, 스토리와 `docs/architecture/`를 압니다. |
| `/review` | **Claude Code 번들** 리뷰 (`/code-review`의 별칭) | 풀 리퀘스트나 일반 diff 리뷰. CCSS의 설계 문서와 게이트는 모릅니다. |

두 리뷰는 서로 다른 질문에 답합니다. `/dev-story` 도중과 `/story-done` 전에는 CCSS 쪽을
쓰십시오. 게이트(`TL-CODE-REVIEW`)가 나중에 확인할 항목을 미리 점검합니다. 스토리와 상관없는
diff를 가볍게 훑어볼 때는 번들 쪽을 쓰십시오.

CCSS는 번들 스킬을 끄지 않습니다. `disableBundledSkills`를 켜면 `/debug`, `/loop`, `/run`처럼
쓸 만한 번들 스킬까지 모두 꺼집니다. 특정 번들 스킬만 숨기려면 개인 설정
`.claude/settings.local.json`의 `skillOverrides`에 스킬 이름과 값(`off`, `name-only`,
`user-invocable-only`)을 지정하십시오.
