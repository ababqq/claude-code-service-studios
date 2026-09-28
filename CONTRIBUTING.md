# 기여 가이드

Claude Code Service Studios(CCSS)는 Claude Code로 웹·모바일·API 서비스를 개발할 때 쓰는 조율 프레임워크입니다.
에이전트, 스킬, 훅, 규칙, 템플릿이 하나의 제품 조직처럼 맞물려 움직입니다. 버그 수정, 실제 공백을 메우는 새
스킬, 에이전트 개선, 훅 수정 같은 기여를 환영합니다. 다만 프레임워크의 방향과 맞지 않는 PR은 긴 설명 없이 닫을
수 있습니다.

## 좋은 PR

- **버그 수정** — 무엇이 깨졌고 어떻게 고쳤는지가 분명한 변경
- **새 스킬** — 기존 스킬로는 해결되지 않는 워크플로의 공백을 메우는 것
- **개선** — 기존 에이전트, 스킬, 훅, 규칙, 템플릿을 더 정확하고 안전하게 만드는 것
- **문서 수정** — 틀린 정보, 깨진 참조, 오래된 절차

기능 요청을 PR로 보내면 닫습니다. 먼저 이슈를 열어 주세요(기능 요청 템플릿이 있습니다).

**이 저장소에 올리지 않는 것**: CCSS는 서비스를 만들도록 돕는 시스템이지, 만든 서비스를 보관하는 곳이
아닙니다. 여러분 프로젝트에서 CCSS로 만든 PRD, ADR, API 계약, 데이터 모델, UX 명세, 스토리, 런북, 인시던트 기록,
제품 코드는 병합하지 않습니다. 여러분의 저장소에 두세요.

## 시작하기 전에

| 위치 | 내용 |
|---|---|
| `.claude/agents/` | 에이전트 정의 — [에이전트 목록](.claude/docs/agent-roster.md) |
| `.claude/skills/<name>/SKILL.md` | 슬래시 명령으로 실행하는 스킬 — [스킬 레퍼런스](.claude/docs/skills-reference.md) |
| `.claude/hooks/`, `.claude/settings.json` | 세션·커밋·파일 쓰기 이벤트에 붙는 훅 — [훅 레퍼런스](.claude/docs/hooks-reference.md) |
| `.claude/scripts/` | 산출물·단계·ADR 의존성을 관찰하는 스크립트 |
| `.claude/rules/` | 파일 경로별로 로드되는 규칙 — [규칙 레퍼런스](.claude/docs/rules-reference.md) |
| `.claude/docs/` | 참조 문서, 워크플로 카탈로그, 디렉터 게이트, 템플릿 |
| `CCSS Skill Testing Framework/` | 스킬과 에이전트를 검증하는 스펙·루브릭·카탈로그 |

단계와 스킬이 어떻게 이어지는지는 [docs/WORKFLOW-GUIDE.md](docs/WORKFLOW-GUIDE.md)와
[docs/skill-flow-diagrams.md](docs/skill-flow-diagrams.md)에 있습니다. 스킬과 에이전트 작성 규칙의 원문은
[`.claude/rules/skill-authoring.md`](.claude/rules/skill-authoring.md)입니다. 이 문서는 그 요약이며, 둘이 다르면
원문이 맞습니다.

## 반드시 지켜야 할 규칙

아래를 놓치면 PR을 되돌려 보냅니다.

### 공통

- **식별자 규칙** — 에이전트 이름, 스킬 이름, 게이트 ID, 단계 값, 설정 키와 enum 값, 스크립트·템플릿 파일
  이름, 산출물 경로, 계약 헤딩, 판정 토큰은 모두 식별자입니다. 이름을 바꿀 때는 모든 참조를 같은 PR에서 함께
  바꾸고, 옛 이름을 별칭으로 남기거나 다른 뜻으로 다시 쓰지 않습니다. "예전 이름은 X였다" 같은 주석도 남기지
  않습니다. 이력은 `CHANGELOG.md`의 몫입니다.
- **언어 정책** — AI가 읽거나 스크립트가 파싱하는 파일(에이전트, 스킬, 규칙, 훅, 스크립트와 그 메시지, 템플릿,
  모든 `CLAUDE.md`, 영어로 정한 참조 문서, 스킬 테스트 프레임워크)은 영어로 씁니다. 사람이 읽는 문서는
  한국어이고, 그 목록은 `.claude/docs/coding-standards.md` § Language Policy에 있습니다. 한국어 문서 안에서도
  식별자는 영어 그대로 두고 명령은 코드 글꼴로 씁니다. 사람이 읽는 문서를 새로 추가한다면 그 목록도 같은 PR에서
  갱신하세요.
- **기계 계약 문자열은 번역하지 않습니다** — 템플릿 헤딩, `**Status**` 같은 굵은 필드 라벨, 판정·심각도·상태
  토큰, YAML 키와 enum 값은 스크립트와 게이트가 문서를 찾는 기준입니다. 헤딩 하나를 바꾸려면 그 헤딩을 읽는
  모든 소비자(스크립트, 게이트 참조 파일, 스킬, 에이전트, 스킬 테스트 스펙)를 같은 PR에서 바꿔야 합니다.
- **예시는 서비스 예시로, 하나의 제품으로** — 프레임워크 전체가 가상 제품 **Moa**(한국 시장용 B2C 구독형 저축
  앱 — 웹, iOS, Android, API)를 예시로 씁니다. 기능은 `auth`(이메일과 카카오·네이버·Apple 로그인),
  `onboarding`, `goals`, `payments`(토스페이먼츠 자동이체), `notifications`(푸시와 알림톡), `subscription`,
  `admin-console`입니다. 예시 PRD `design/prd/goals.md`, 요구사항 ID `TR-goals-001`, 기능 플래그
  `goals.v2-progress-ring`처럼 기존 예시와 맞춰 주세요.
- **실제 현장의 용어를 씁니다** — 메시지 큐는 publisher/consumer, 장애 대응 연습은 failure drill, 관측성은 세
  가지 신호(logs, metrics, traces), 출시 전 검증 환경은 staging, 첫날 잔존율은 D1 retention이라고 씁니다.
  디자인 토큰과 컴포넌트 묶음은 "design system"(하이픈 없이 두 단어)이나 "component library"라고 씁니다.
- **파일과 줄 번호로 인용하지 않습니다** — 줄 번호는 다음 수정 때 틀어집니다. 다른 파일은 파일과 헤딩으로
  인용하세요(예: `.claude/docs/director-gates.md` § Context to Pass).
- **개수를 여기저기 적지 않습니다** — 에이전트·스킬·규칙·템플릿·게이트의 현재 개수는 `README.md`,
  `.claude/docs/quick-start.md`, 루트 `CLAUDE.md`에만 적습니다(`CHANGELOG.md`의 릴리스 기록은 예외). 개수가
  바뀌는 PR은 이 세 파일을 함께 고칩니다.

### 스킬

- **형식** — `.claude/skills/<name>/SKILL.md` 하위 디렉터리 형식이어야 합니다. 평평한 `.md` 파일은 Claude Code가
  조용히 무시합니다. 디렉터리 이름 == frontmatter `name` == `CCSS Skill Testing Framework/catalog.yaml`의 항목
  이름 == 스펙 파일 이름입니다.
- **frontmatter** — `name`, `description`(한 줄, 큰따옴표), `argument-hint`, `user-invocable`, `allowed-tools`,
  `model`. `disable-model-invocation: true`는 사용자가 직접 입력했을 때만 실행해야 하는 스킬(스토리 구현·완료,
  핫픽스, 인시던트, 롤아웃)에만 둡니다. `isolation: worktree`는 코드를 쓰고 버리는 `/prototype`에만 있습니다.
  아직 커밋하지 않은 문서를 읽어야 하는 스킬(예: `/review-all-prds`)에는 두지 마세요. 격리된 작업 트리에서는 그
  문서가 보이지 않습니다.
- **model** — 새 스킬은 특별한 이유가 없으면 `sonnet`입니다. 읽기 전용 상태 확인은 `haiku`, 여러 문서를
  종합하거나 단계 게이트를 판정하는 스킬은 `opus`를 씁니다. 스킬의 `model:`은 선언일 뿐 적용되지 않는다는 점도
  알아 두세요(`.claude/docs/model-tiers.md`).
- **`allowed-tools`는 정확하게** — 실제로 쓰는 도구와 정확히 일치해야 합니다. MCP 도구 이름은 설치마다 다르므로
  절대 적지 않습니다. Context7을 쓸 수 있는 스킬은 "use Context7 if its tools are present in the session, else
  WebSearch/WebFetch"라고 씁니다.
- **설정 부트스트랩** — 설정이 필요한 스킬은 본문 첫 줄에 아래 한 줄을 두고,

  ```text
  !`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys <keys>`
  ```

  `allowed-tools`에 자기 디렉터리 이름이 들어간 허가
  `Bash(bash "*/.claude/skills/<name>/../../hooks/yaml-helper.sh" resolve_config *)`를 넣습니다. 둘 중 하나라도
  빠지면 기본 권한 모드에서 스킬이 시작하기도 전에 멈춥니다. `--keys`에는 `resolve_config`가 실제로 내보내는
  라벨만 쓰고, 블록 다음 줄은 정해진 두 문장 중 하나입니다(`.claude/docs/config-resolution.md` § The rule,
  § Labels).
- **주입은 한 줄만** — `!` 주입은 부트스트랩 줄 하나뿐이고, 어떤 주입에도 `$(`, `${`, `;`, `|`, `&&`를 넣지
  않습니다. 권한 검사가 확장을 거부합니다. 최신 스프린트나 세션 상태 같은 정보는 실행 중에 Read, Glob, Bash로
  모읍니다.
- **키는 내용을 따릅니다** — 코드 루트를 다루는 스킬은 `code_roots`를, 항상 묻기 범주(예: `db_migrations`,
  `production_deploys`)를 다루는 스킬은 `automation_always_ask`를 요청합니다. 라벨이 없는 키(`performance.*`,
  `commands.*`, `naming.*`, `localization.locales` 등)는 실행 중에 `project.yaml`을 Read로 읽습니다.
- **자동화 전문** — 키에 `automation`이 있으면 `.claude/docs/automation-modes.md` § How to Use This Document의
  블록을 그대로 넣습니다. 항상 협업하는 스킬 — `/gate-check`, `/hotfix`, `/incident`, `/rollout-plan`,
  `/setup-stack`, `/start`, `/settings` — 에는 절대 넣지 않고 `automation` 키도 요청하지 않습니다.
- **쓰기 전에 묻기** — `Write`나 `Edit`를 가진 스킬은 파일을 쓸 때마다 먼저 "May I write this to `<path>`?"라고
  묻습니다. 스킬 파일에는 이 영어 원문을 적고, 실제 대화에서는 모델이 사용자의 언어로 옮깁니다.
- **디렉터 게이트 호출** — 게이트를 부르는 스킬은 `allowed-tools`에 `Agent`와 `AskUserQuestion`, 키에
  `review_mode`, 부르는 게이트마다 리뷰 모드 검사를 둡니다. lean 모드에서는 ID가 `-PHASE-GATE`로 끝나지 않는
  게이트를 모두 건너뜁니다. 호출할 때는 게이트 파일 경로와 그 게이트의 Context 항목을 `Pass:` 줄로 넘기고,
  에이전트 응답의 첫 줄을 `[GATE-ID]: TOKEN`으로 읽습니다(`.claude/docs/director-gates.md` § Review Modes,
  § Invocation Pattern, § Context to Pass). `/hotfix`, `/rollout-plan`, `/incident`는 리뷰 모드와 관계없이 항상
  실행되므로 리뷰 모드 검사 대신 예외 문장을 넣습니다.
- **판정** — 판정 토큰은 스킬이 정의한 철자 그대로 쓰고, `NOT ASSESSED`는 언제나 선택할 수 있어야 합니다. 판정이
  있는 보고서나 기록은 H1 바로 아래(빈 줄 하나 다음)에 `> **Verdict**: <TOKEN>` 줄을 둡니다. 다른 스킬이 이 줄을
  읽습니다.
- **다섯 가지 의무** — (1) `NOT ASSESSED`는 정식 판정입니다. (2) 설정이 없다는 것은 허용하는 기본값이 아닙니다 —
  설정하지 않은 것은 `false`나 `none`과 다릅니다. (3) 건너뛴 검사는 `NOT CHECKED — <이유>`로 스스로 밝힙니다.
  (4) 출처 없는 주장을 하지 않습니다 — 모르면 `NOT SOURCEABLE`, `NOT DETERMINED`. (5) 적용 범위는 손으로
  나열하지 말고 파생합니다.
- **그 밖의 금지 사항** — 증거·보고서·계획을 gitignore된 `production/session-logs/`에 쓰지 않습니다.
  `modes.rigor`가 대신 정하는 여섯 설정(`modes.review_mode`, `modes.workflow`, `docs.density`, `qa.level`,
  `modes.story_granularity`, `team.size`)을 쓰거나 `project.yaml`에 심지 않습니다(사용자가 요청한 `/settings`만
  예외). "다음 단계" 안내에는 실제로 존재하는 스킬 이름만 씁니다.
- **워크플로 카탈로그** — 새 스킬이 단계의 스텝이라면 `.claude/docs/workflow-catalog.yaml`에 스텝을 추가합니다.
  이 파일은 `artifact-check.sh`의 손으로 쓴 파서가 읽으므로 들여쓰기 계약을 지키고, YAML 포매터를 절대 돌리지
  마세요. 스텝의 `command:`는 실제 스킬이어야 하고, glob은 스킬이 실제로 쓰는 경로와 정확히 맞아야 합니다.

### 에이전트

규칙의 원문은 `.claude/rules/skill-authoring.md` § Agent file skeleton입니다.

- **형식** — `.claude/agents/<name>.md`, frontmatter `name` == 파일 이름입니다.
- **frontmatter 순서** — `name`, `description`, `tools`, `disallowedTools`(셸을 쓰면 안 되는 에이전트만),
  `model`, `maxTurns`, `memory`(설정할 때만), `skills`(설정할 때만), `isolation`(`prototyper`만).
  `description`은 큰따옴표로 감싼 한 줄 `"<담당 영역>. Use when <trigger>."`입니다.
- **첫 문장** — frontmatter 바로 다음 줄은 "You are the <Title> for a <web/mobile/API> product team."입니다.
- **본문 `##` 헤딩 순서**
  1. `## Collaboration Protocol` — `### Strategic Decision Workflow`, `### Question-First Workflow`,
     `### Implementation Workflow`, `### Operations Workflow` 중 역할에 맞는 것, 그리고
     "**Bounded exception — orchestrated runs.**"로 시작하는 문단(기존 에이전트 파일에서 글자 그대로 복사)
  2. `## Core Responsibilities`
  3. `## <Domain> Standards` (예: `## API Standards`, `## Design Language Standards`)
  4. `## Gate Verdict Format` — 디렉터 게이트를 소유한 에이전트만
  5. `## Sub-Specialist Orchestration` — `Agent(...)` 허가가 있는 스택 리드만
  6. `## Version Awareness` — 스택 에이전트만
  7. `## What This Agent Must NOT Do`
  8. `## Delegation Map` — `Reports to:`, `Delegates to:`, `Coordinates with:` 세 줄
- **협업 템플릿 고르기** — 방향을 정하는 디렉터는 Strategic Decision, 만들기 전에 결정하는 역할(기획, 디자인,
  리서치, 그로스, CS 등)은 Question-First, 코드나 테스트를 쓰는 역할과 모든 스택 에이전트는 Implementation,
  배포·운영 역할은 Operations입니다.
- **보고 체계를 닫습니다** — `Reports to:`에 적은 부모 에이전트의 `Delegates to:`에 새 에이전트를 추가합니다.
  빠지면 결함입니다.
- **모델 등급** — frontmatter `model:`이 유일한 기준이고 `.claude/docs/model-tiers.md`는 거기서 파생한 문서입니다.
  opus는 세 디렉터(`product-director`, `technical-director`, `delivery-manager`)에게만 씁니다.
- **에이전트는 묻고, 결정은 사용자가 합니다** — 담당 영역 밖의 파일은 명시적인 위임 없이 고치지 않습니다.
  프로덕션, 공유 인프라, 공유 데이터베이스, 시크릿을 바꾸는 명령은 자율 모드에서도 직접 실행하지 않고, 영향
  범위와 롤백 명령을 붙여 사람에게 제안합니다.
- **스택 에이전트** — 버전에 민감한 조언 전에 `docs/stack-reference/`를 확인하고, 확인할 수 없으면 추측하지 말고
  `NOT SOURCEABLE — run /setup-stack refresh`라고 답합니다. 자기 레이어 밖으로 나가지 않고, 리드는 `Agent(...)`
  허가로만 위임하며 서브 스페셜리스트는 자기 리드에게 올립니다.

### 디렉터 게이트

- 게이트 파일은 `.claude/docs/director-gates/<소문자-id>.md`입니다. ID 접두사는 소유 에이전트를 나타냅니다:
  `PD-`, `TD-`, `DM-`, `DD-`, `TL-`, `QL-`, `SE-`, `SR-`. 새 소유자에게는 새 접두사를 붙입니다
  (`.claude/docs/director-gates.md` § Adding New Gates).
- 파일 모양은 기존 게이트 파일과 같게 합니다 — `Agent:`·`Model tier:`·`Domain:` 머리줄, `**Trigger**`,
  `**Context to pass**`, `**Prompt**`, `**Verdicts**`.
- `director-gates.md` § Gate Index에 행을 추가하고, § Context to Pass의 항목과 호출하는 스킬의 `Pass:` 줄이
  글자까지 같게 맞춥니다.
- 판정 토큰은 § Standard Verdict Format의 세 등급(APPROVE·CONCERNS·REJECT 계열) 가운데 하나에 매핑하고, 소유
  에이전트의 `## Gate Verdict Format`에 게이트와 토큰을 추가합니다.
- 호출하는 스킬이 없는 게이트는 만들지 않습니다. lean 모드는 ID의 접미사로 정해지므로 목록을 고칠 필요가
  없습니다 — 단계 전환 게이트만 이름이 `-PHASE-GATE`로 끝나야 합니다.

### 훅과 스크립트

- `grep -P`가 아니라 `grep -E`를 씁니다. Perl 정규식은 macOS의 BSD grep과 Windows Git Bash에서 깨집니다.
- macOS 기본 bash 3.2에서 동작해야 합니다. 연관 배열, `${var,,}`, `mapfile`처럼 bash 4 이상이 필요한 기능은 쓰지
  않고, `sed -i`, `date`, `readlink -f`처럼 GNU와 BSD의 동작이 다른 명령은 피하거나 분기합니다.
- `jq`나 Python이 없어도 정상 종료하는 대체 경로를 둡니다. PyYAML은 선택 사항이며, 없으면 조용히 넘어가지 말고
  `NOT CHECKED` 줄을 출력합니다.
- 프로젝트 루트는 기존 훅과 같은 네 단계 방식(`CCSS_ROOT`)으로 찾습니다.
- 훅은 빨리 끝나야 하고, 해당하지 않으면 `exit 0`으로 조용히 끝냅니다. 차단(`exit 2`)은 정말 막아야 할 때만
  씁니다 — 지금은 `validate-commit.sh`의 파싱 실패·시크릿·자격 증명 파일과 `validate-data-files.sh`의 파싱 실패
  피드백뿐입니다.
- `.claude/scripts/`의 스크립트는 관찰만 출력하고 판정(PASS/FAIL, 차단 여부)은 하지 않습니다. 판정은 스킬과 게이트
  참조 파일의 몫입니다.
- 새 훅은 `.claude/settings.json`에 등록하고 `.claude/docs/hooks-reference.md`에 추가합니다.
- `bash -n`으로 문법을 확인하고, 실제 저장소가 아니라 임시로 복사한 fixture 저장소에서 실행해 봅니다.
- `.claude/settings.json`의 허용 목록에 프로덕션 배포, IaC apply, 파괴적인 DB 명령을 넣지 않습니다. 거부 목록은
  `automation_always_ask` 뒤의 두 번째 방어선입니다.

### 규칙

- `.claude/rules/<name>.md`, frontmatter `paths:`에 적용할 경로 glob을 적습니다. 규칙은 `project.yaml`을 읽을 수
  없으므로 코드 규칙은 `src/` 구조와 모노레포 구조(`apps/*/app/**`, `apps/*/components/**`, `apps/*/lib/**`,
  `packages/*/src/**` 등)를 모두 적습니다.
- `.claude/docs/rules-reference.md`를 함께 갱신합니다.

### 템플릿과 설정 키

- 템플릿은 `.claude/docs/templates/`에 두고, `.claude/` 안의 파일 하나 이상이 반드시 인용해야 합니다. 템플릿의
  헤딩은 기계 계약입니다.
- 설정 키를 추가하면 `.claude/docs/effects-map.md`에 헤딩과 `**Values:**` 줄을, enum이면 `yaml-helper.sh`의 enum
  표를, 개인별 재정의(`project.local.yaml`)를 허용한다면 허용 목록을 함께 고칩니다. `modes.rigor`가 대신 정하는
  여섯 설정에는 기본값을 두지 않고, 어떤 템플릿이나 스킬도 `project.yaml`에 심지 않습니다.

## 협업 원칙

CCSS는 자율 시스템이 아닙니다. 모든 워크플로는 **질문 → 선택지 → 결정 → 초안 → 승인 → 쓰기**를 따릅니다
([docs/COLLABORATIVE-DESIGN-PRINCIPLE.md](docs/COLLABORATIVE-DESIGN-PRINCIPLE.md)).

- 스킬과 에이전트는 행동하기 전에 묻습니다. 파일을 쓰기 전마다 "May I write this to [filepath]?"로 확인합니다.
- 여러 파일을 바꾸는 작업은 변경 전체를 한 번에 보여 주고 승인받습니다.
- 사용자가 지시하지 않으면 커밋하지 않습니다.
- 유일한 예외는 오케스트레이션 스킬이 경로를 지정해 준 **새** 산출물을 `production/`, `docs/`, `tests/` 아래에 쓰는
  경우입니다. 사용자가 그 단계를 승인할 때 경로도 함께 승인했기 때문입니다. 기존 파일 수정, 스스로 고른 경로,
  `design/` 아래 문서에는 적용되지 않습니다.
- `modes.automation: autonomous`에서도 `modes.automation_always_ask`의 범주는 항상 묻고, 항상 협업하는 스킬은 모든
  단계를 승인받습니다.

에이전트가 혼자 결정하거나 승인 없이 파일을 쓰게 만드는 기여는 병합하지 않습니다.

## 변경 사항 테스트

### 스킬 테스트 프레임워크

| 명령 | 하는 일 |
|---|---|
| `/skill-test static <name>` | 스킬 구조 검사 — frontmatter, 부트스트랩, 쓰기 전 확인, 판정 규칙. `all`로 전체 검사 |
| `/skill-test spec <name>` | 스킬이나 에이전트를 스펙에 비추어 행동 평가 |
| `/skill-test category <name>` | 카테고리 루브릭 평가 |
| `/skill-test audit` | 모든 스킬과 에이전트의 스펙·카탈로그 커버리지 |
| `/skill-improve <name>` | 테스트 → 진단 → 수정 제안 → 재테스트 루프. 점수가 떨어지면 되돌립니다 |

스킬을 고치면 `validate-skill-change.sh` 훅이 `/skill-test static <name>`을, 에이전트를 고치면
`/skill-test spec <name>`을 권합니다. 무시하지 말고 돌려 보세요.

**새 스킬이나 에이전트를 추가할 때**

1. `CCSS Skill Testing Framework/templates/skill-test-spec.md` 또는 `agent-test-spec.md`를 복사해 스펙을 씁니다.
   스킬 스펙은 `CCSS Skill Testing Framework/skills/<category>/<skill>.md`, 에이전트 스펙은
   `CCSS Skill Testing Framework/agents/<folder>/<agent>.md`(`directors`, `leads`, `specialists`, `qa`,
   `operations`, `stack`)에 둡니다.
2. 케이스는 최소 4개이고, 입력이 없을 때의 `NOT ASSESSED` 케이스를 반드시 넣습니다. 게이트를 부르는 스킬은 리뷰
   모드(`full`, `lean`, `solo`)마다 케이스를 하나씩, 리뷰 모드 예외 스킬은 예외를 확인하는 케이스를 둡니다.
3. 스펙은 SKILL.md의 영어 원문을 확인합니다. 실행 중에 번역된 문구를 기준으로 삼지 않습니다.
4. `catalog.yaml`에 항목을 추가합니다. 스킬 항목은 10개 필드(`name`, `spec`, `last_static`,
   `last_static_result`, `last_spec`, `last_spec_result`, `last_category`, `last_category_result`, `priority`,
   `category`), 에이전트 항목은 5개 필드(`name`, `spec`, `last_spec`, `last_spec_result`, `category`)입니다.
   스킬 카테고리는 `gate`, `review`, `authoring`, `readiness`, `pipeline`, `analysis`, `team`, `sprint`, `ops`,
   `utility`, 에이전트 카테고리는 `director`, `lead`, `specialist`, `qa`, `operations`, `stack`입니다.
5. `/skill-test spec <name>`을 실행합니다.

자세한 절차는 `CCSS Skill Testing Framework/README.md` § Writing a new spec에 있습니다.

### 실제 세션에서 확인

- Claude Code 세션에서 처음부터 끝까지 실행해 보세요. 스킬이라면 주장하는 산출물이 약속한 경로와 헤딩으로 실제로
  나오는지, 훅이라면 해당 이벤트에서 제대로 실행되고 깨끗하게 끝나는지 확인합니다.
- 가능하면 임시 저장소에서 Moa 같은 샘플 제품으로 시험하세요. 이 저장소 자체에서 스킬을 실행해 산출물을 만들지
  마세요.
- PR 설명에 무엇을 시험했고 출력이 어땠는지 짧게 적어 주세요.

## 레퍼런스 문서 갱신

무언가를 추가하거나 바꾸면서 색인을 갱신하지 않은 PR은 되돌려 보냅니다.

| 바꾼 것 | 함께 고칠 문서 |
|---|---|
| 에이전트 | `.claude/docs/agent-roster.md`, `.claude/docs/model-tiers.md`, 부모 에이전트의 `## Delegation Map`, 스킬 테스트 카탈로그와 스펙 |
| 스킬 | `.claude/docs/skills-reference.md`, 스킬 테스트 카탈로그와 스펙, 단계 스텝이면 `.claude/docs/workflow-catalog.yaml`, 흐름이 바뀌면 `docs/WORKFLOW-GUIDE.md`와 `docs/skill-flow-diagrams.md` |
| 훅 | `.claude/settings.json`, `.claude/docs/hooks-reference.md` |
| 규칙 | `.claude/docs/rules-reference.md` |
| 디렉터 게이트 | `.claude/docs/director-gates.md`, 소유 에이전트의 `## Gate Verdict Format`, 호출하는 스킬 |
| 설정 키 | `.claude/docs/effects-map.md`, 라벨이 생기거나 바뀌면 `.claude/docs/config-resolution.md` |
| 개수 | `README.md`, `.claude/docs/quick-start.md`, 루트 `CLAUDE.md` |

프레임워크의 동작이 바뀌는 PR은 설명에 사용자 관점의 요약을 적어 주세요. 릴리스 때 메인테이너가
`CHANGELOG.md`에 옮깁니다.

## 커밋 형식

Conventional Commits를 씁니다.

```text
feat(skills): add runbook mode to /incident
fix(hooks): keep validate-push silent on tag pushes
docs: add /api-design to skills-reference
```

타입은 `feat`, `fix`, `docs`, `chore`, `refactor`, `test`를 주로 쓰고 `perf`, `build`, `ci`, `revert`도 받습니다.
본문에 관련 이슈나 태스크 ID를 적어 주세요(예: `Refs: #123`). `validate-commit.sh`가 제목 형식과 ID 줄을 검사해
경고합니다. 경고일 뿐 커밋을 막지는 않습니다.

## PR 절차

- PR은 `CODEOWNERS`에 따라 메인테이너에게 자동으로 배정됩니다.
- 혼자 유지보수하는 프로젝트라 리뷰는 시간이 날 때 합니다. 몇 주가 지나도 반응이 없으면 댓글로 알려 주세요.
- PR 템플릿의 체크리스트를 채워 주세요.
- 병합된 기여는 릴리스의 변경 이력에 기여자와 함께 기록합니다.

## 플랫폼 호환성

CCSS는 macOS(bash 3.2, BSD 도구), Linux(GNU 도구), Windows(Git Bash)에서 모두 동작해야 합니다. 특정 플랫폼에서만
동작하는 훅이나 스크립트는 받지 않습니다. 확신이 없으면 macOS와 Windows Git Bash에서 시험해 보세요.

## 보안

취약점은 공개 이슈로 올리지 말고 [SECURITY.md](SECURITY.md)의 절차를 따라 주세요.
