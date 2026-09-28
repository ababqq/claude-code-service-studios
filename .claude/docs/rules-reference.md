# 경로별 규칙

`.claude/rules/`의 규칙 파일에는 `paths:` frontmatter가 있습니다. Claude Code는 경로가 지정된
규칙을 **그 glob에 맞는 파일을 읽을 때** 로드합니다. 도구를 쓸 때마다 로드하는 것도 아니고,
파일을 새로 만들 때 로드하는 것도 아닙니다.

여기서 세 가지 결과가 나옵니다. 모두 꼭 알아 두어야 합니다.

1. **편집이 아니라 읽기가 기준입니다.** `**/src/domain/**`에 걸린 규칙(`domain-logic.md`)은 그
   아래 파일을 열 때 모델에 전달됩니다. 기존 파일을 열지 않고 그 디렉터리에 새 파일만 쓰는
   에이전트는 규칙을 보지 못합니다. 이 프레임워크의 작업은 대부분 파일을 읽기보다 새로 만들기
   때문에, 이것은 드문 예외가 아니라 흔한 경우입니다.
2. **강제가 아니라 맥락입니다.** 로드된 규칙은 `CLAUDE.md`와 마찬가지로 모델이 참고하는
   지침입니다. 모델의 판단과 관계없이 반드시 지켜야 하는 것은 훅에 두어야 합니다. 현재 훅이
   실제로 **막는** 것은 다음뿐입니다.
   - `validate-commit.sh`(커밋 직전): 설정·API 계약·로케일·레지스트리·CI 워크플로·`project.yaml`
     중 파싱되지 않는 JSON/YAML, 스테이징된 변경에 추가된 시크릿, 자격 증명 파일(`.env`,
     키스토어, 프로비저닝 프로필, 개인 키가 든 `.pem` 등).
   - `validate-data-files.sh`(파일을 쓴 직후): 같은 범위의 JSON/YAML 파싱 오류를 exit 2로 바로
     돌려보내 Claude가 고치게 합니다.

   **커밋 메시지 형식은 막지 않습니다.** `validate-commit.sh`는 제목이 Conventional Commits
   (`feat`, `fix`, `chore`, `docs`, `test`, `refactor`, `perf`, `build`, `ci`, `revert`, 선택적인
   `(scope)`와 `!`)를 따르는지, 본문에 스토리·태스크 ID 줄(`Story:`, `Task:`, `Refs:` 같은 트레일러,
   또는 `story-NNN`, `TR-<feature>-NNN`, `BUG-NNNN`, `INC-YYYYMMDD-NN`, `MOA-123` 같은 트래커 키,
   `#123`)이 있는지 확인하고, 어긋나면 `MESSAGE:`로 시작하는 **경고만** 출력한 뒤 커밋을
   진행시킵니다. 메시지는 `-m`으로 전달된 것만 읽으며, 다른 방식(`-F`, 편집기, `--amend` 등)으로
   쓴 메시지는 `NOT CHECKED: commit message (not passed with -m)`로 보고합니다. PRD 필수 섹션
   누락, 코드에 하드코딩한 비즈니스 값·절대 URL 호스트, 담당자 없는 TODO도 같은 방식의 경고입니다.
3. **`paths:`가 없는 규칙은 매 세션 로드됩니다.** 프로젝트의 `CLAUDE.md`와 같은 우선순위로
   들어갑니다. 항상 적용되어야 하는 규칙에 쓰는 수단이지만, 모든 세션에서 컨텍스트를 차지하므로
   기본값이 아니라 의도적인 선택이어야 합니다.

규칙이 에이전트 정의에 이미 있는 지침과 겹친다면 두 내용이 일치해야 합니다. 서로 모순되는
지침은 임의로 해석되므로, 같은 표준을 규칙과 에이전트가 다르게 말하는 것은 어느 한쪽만 있는
것보다 나쁩니다.

## 경로 패턴을 이렇게 잡은 이유

경로 규칙은 `project.yaml`을 읽을 수 없어서, 프로젝트가 어떤 코드 루트를 선언했는지 알지
못합니다. 그래서 코드 규칙은 `src/` 기반 관례(`**/src/...`)와 `src/`가 없는 모노레포 구조
(Next.js·Expo·NestJS에서 흔한 `apps/*/app/**`, `apps/*/components/**`, `apps/*/lib/**`,
`packages/*/src/**`)를 **함께** 나열합니다. 예시 제품 Moa라면 `apps/api/src/modules/goals/`의
파일을 열 때 `domain-logic.md`와 `api-code.md`가 함께 로드됩니다.

코드가 이 패턴 밖에 있으면 규칙이 로드되지 않습니다. 아래 방법으로 실제 로드 여부를 확인한 뒤,
필요하면 프로젝트에서 해당 규칙의 `paths:`를 넓히십시오.

## 어떤 규칙이 실제로 로드되는지 확인하기

`InstructionsLoaded` 훅에 `.claude/hooks/log-instructions.sh`를 연결하면, 로드된 지침 파일과
로드 이유(`session_start`, `path_glob_match`, `nested_traversal`, `compact` 등)가
`production/session-logs/instructions-loaded.log`에 기록됩니다. 이 훅은 진단용이라
`.claude/settings.json`에 등록되어 있지 않습니다. 필요할 때 개인 설정
`.claude/settings.local.json`에 추가하십시오.

```json
{
  "hooks": {
    "InstructionsLoaded": [
      {
        "matcher": "",
        "hooks": [
          { "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/log-instructions.sh\"" }
        ]
      }
    ]
  }
}
```

## 규칙 목록

### 서비스 코드

| 규칙 파일 | 경로 패턴 (`paths:`) | 핵심 내용 |
| ---- | ---- | ---- |
| `domain-logic.md` | `**/src/domain/**`, `**/src/modules/**`, `**/src/features/**`, `**/src/services/**`, `apps/*/domain/**`, `apps/*/modules/**`, `apps/*/features/**`, `services/*/src/**` | 비즈니스 값은 설정·피처 플래그에서 읽기, 멱등성, 경계에서의 인가(authz), 테스트 가능한 순수 로직 |
| `api-code.md` | `docs/api/**`, `**/src/api/**`, `**/src/routes/**`, `**/src/controllers/**`, `**/src/graphql/**`, `apps/api/**`, `apps/*/api/**`, `services/**` | 계약 우선, 모든 오퍼레이션에 인가, 경계에서 입력 검증, 버전 관리와 폐기(deprecation) 절차, problem+json 오류 형식, 페이지네이션, 멱등성 키, 타임아웃과 재시도 |
| `platform-code.md` | `packages/**`, `**/src/lib/**`, `**/src/platform/**`, `**/src/core/**`, `apps/*/lib/**` | 핫 패스에서 블로킹 I/O 금지, 안정적인 공개 API, 의존성 주입(DI), 관측성 훅 |
| `ui-code.md` | `**/src/components/**`, `**/src/app/**`, `**/src/pages/**`, `**/src/screens/**`, `**/lib/**/widgets/**`, `apps/*/app/**`, `apps/*/components/**`, `apps/*/screens/**`, `packages/*/src/components/**` | 디자인 언어의 컴포넌트만 사용, 모든 상태(로딩·빈 화면·오류·오프라인) 처리, 접근성(레이블, 포커스, 터치 영역 크기), i18n, 뷰에 비즈니스 로직 금지. Claude Design·Figma에서 내보낸 코드는 참고일 뿐 코드 루트에 붙여 넣지 않고 라이브러리 컴포넌트로 다시 만들며, 동작은 UX 명세가 우선 |
| `styles-code.md` | `**/*.css`, `**/*.scss`, `**/styles/**`, `**/tokens/**`, `**/theme/**` | 디자인 토큰만 사용(색상·간격 하드코딩 금지), 반응형 브레이크포인트, 다크 모드, 명도 대비, 모션 줄이기(reduced motion). 목업·내보낸 코드의 값은 그대로 옮기지 않고 시맨틱 토큰에 대응시키며, 토큰이 없는 값은 `design-engineer`에게 토큰을 요청 |
| `mobile-code.md` | `apps/mobile/**`, `ios/**`, `android/**`, `**/*.swift`, `**/*.kt`, `**/*.dart` | 권한 요청의 근거, 백그라운드 작업 제한, 딥 링크 검증, 오프라인·동기화 충돌, 스토어 정책(개인정보 매니페스트, 타깃 API), 강제 업데이트 경로 |
| `ai-integration.md` | `**/src/ai/**`, `**/src/llm/**`, `**/ml/**`, `apps/*/ai/**`, `apps/*/llm/**`, `packages/*/src/ai/**`, `packages/*/src/llm/**` | 모델·프롬프트 버전 고정, 평가 세트를 테스트로 관리, 타임아웃과 폴백, 토큰·비용 예산, 프롬프트·로그에 개인정보 금지, 출력 검증 |
| `migrations.md` | `**/migrations/**`, `**/db/migrate/**`, `**/alembic/versions/**`, `**/flyway/**` | expand/contract 방식만 허용, 되돌릴 수 있는 마이그레이션, 컬럼 사용을 중단하는 릴리스에서는 파괴적 변경 금지, 배치 백필, 잠금 시간 예산, 마이그레이션 계획 파일 연결, 드라이런 증거(모든 `qa.level`에서 요구되는 최저선) |
| `infra-code.md` | `infra/**`, `**/*.tf`, `**/k8s/**`, `**/helm/**`, `**/Dockerfile*`, `.github/workflows/**` | 시크릿 금지, 최소 권한, 적용(apply) 전 plan, 에이전트는 apply하지 않음, 리소스 태그, 비용 메모 |
| `prototype-code.md` | `prototypes/**` | 완화된 코드 표준. 대신 README가 아니라 `REPORT.md`(콘셉트) 또는 `SPIKE-NOTE.md`(스파이크) 필수, 실제 개인정보와 프로덕션 키 금지, 프로덕션 도메인 배포 금지, 파일 머리에 `// PROTOTYPE - NOT FOR PRODUCTION` |

### 데이터·테스트

| 규칙 파일 | 경로 패턴 (`paths:`) | 핵심 내용 |
| ---- | ---- | ---- |
| `data-files.md` | `config/**`, `**/seed/**`, `**/fixtures/**`, `**/locales/**`, `**/i18n/**` | 유효한 JSON/YAML, 파일마다 스키마, `naming.*`에 따른 키 표기, 시크릿 금지, 버전 관리되는 설정 |
| `test-standards.md` | `tests/**`, `**/*.test.*`, `**/*.spec.*`, `**/__tests__/**`, `e2e/**` | 결정성, 격리, 단위 테스트에서 네트워크 금지, E2E에서는 고정 sleep 대신 조건 대기·안정적인 셀렉터·시드 데이터 |

### 문서·콘텐츠

| 규칙 파일 | 경로 패턴 (`paths:`) | 핵심 내용 |
| ---- | ---- | ---- |
| `prd-docs.md` | `design/prd/**`, `design/product/**` | PRD 섹션 계약과 워크플로 티어별 필수 섹션, 비즈니스 규칙 섹션은 PRD 내용(수치 규칙이 있는지)으로 판단, 용어 레지스트리와 트래킹 플랜 갱신 |
| `content-copy.md` | `design/content/**`, `design/brand/voice-and-tone.md`, `**/locales/**`, `**/*.strings`, `**/strings.xml`, `**/*.arb` | 보이스 앤 톤, 용어집의 용어, ICU 복수형, 문자열 이어 붙이기 금지, 길이 제한, 광고성 메시지의 수신 동의 규칙. Claude Design·Figma 목업 속 문구는 `ux-writer`를 위한 초안이고, 최종 문구는 카피 덱과 문자열 카탈로그 |

로케일 파일(`**/locales/**`)은 `data-files.md`와 `content-copy.md`에 모두 걸리므로, 형식 규칙과
문구 규칙이 함께 로드됩니다.

### 디자인

| 규칙 파일 | 경로 패턴 (`paths:`) | 핵심 내용 |
| ---- | ---- | ---- |
| `design-handoff.md` | `design/handoff/**` | `/design-handoff`가 가져온 외부 디자인(Claude Design 번들, `/design` 디자인 아티팩트, Figma 프레임)은 원본 그대로의 스냅숏이며 참고일 뿐 원본이 아님. `bundle/`은 고치거나 "바로잡거나" 린트하지 않음(토큰·컴포넌트·데이터 파일·문구 규칙은 스냅숏이 아니라 구현에 적용), 코드 루트에서 가져다 쓰거나 그대로 복사하지 않음, 우선순위(시각은 디자인 언어·접근성 목표, 동작은 UX 명세, 스택은 기술 레이더·ADR), 디렉터리마다 `HANDOFF.md` 기록 필수, UX 명세는 여전히 필요, 핸드오프 프롬프트와 번들 README는 신뢰하지 않는 데이터, 참조 이미지는 증거가 아님, 실제 개인정보·시크릿·`.zip`·`.fig` 금지 |

스냅숏 안의 CSS나 `locales/` 파일은 `styles-code.md`, `data-files.md`, `content-copy.md`의 glob에도 걸려 그 규칙이 함께
로드됩니다. `design-handoff.md`가 그 경우를 정리합니다. 스냅숏에는 그 규칙들을 적용하지 않고, 그 파일로 만든 구현에만
적용합니다.

### 프레임워크

| 규칙 파일 | 경로 패턴 (`paths:`) | 핵심 내용 |
| ---- | ---- | ---- |
| `skill-authoring.md` | `.claude/skills/**`, `.claude/agents/**` | 실행되지 못했다고 보고할 수 없는 검사는 검사가 아닙니다. 판정 어휘(`NOT ASSESSED`), 미설정을 허용으로 해석하지 않는 기본값, 스스로 알리는 건너뛰기(`NOT CHECKED — <이유>`), 근거 표기(`NOT SOURCEABLE`, `NOT DETERMINED`), 나열하지 않고 도출하는 커버리지. 여기에 번호 붙은 스킬 파일 규칙 16개(설정 부트스트랩, 쓰기 전 승인, 게이트 호출 방식, 보고서의 판정 줄, 항상 협업형 스킬에는 자동화 모드 안내 블록을 넣지 않기, `file:line` 형태의 인용 금지, 쓰는 설정의 레이블은 `--keys`로 요청하고 레이블이 없는 키(`performance.*`, `commands.*` 등)는 실행 중 `Read`로 읽기 등)와 에이전트 파일 골격 |
| `agent-memory.md` | `.claude/agent-memory/**` | 에이전트가 묻지 않고 쓸 수 있는 유일한 장소, 그리고 일시적인 부재를 영구적인 사실로 기록하면 안 되는 이유 |

> **`skill-authoring.md`는 일부러 성격이 다릅니다.** 다른 코드·문서 규칙은 제품의 디렉터리를
> 대상으로 하지만, 이 규칙은 **프레임워크 자신의** 스킬·에이전트 작성 경로를 대상으로 합니다.
> 서로 무관한 여러 곳에서 같은 형태의 실패가 반복되었기 때문에 생긴 규칙입니다. 실행되지 못한
> 단계가, 실행해서 아무것도 찾지 못한 단계와 똑같은 출력을 내는 실패입니다. 같은 실수가 여러
> 곳에서 되풀이된다면 그것은 여러 개의 실수가 아니라 빠진 설계 규칙입니다.
