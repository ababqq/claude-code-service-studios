# Claude Code Service Studios — 워크플로 가이드

> **아이디어에서 출시까지, 그리고 출시 후의 지속 전달까지 이 템플릿으로 서비스를 만드는 방법입니다.**
>
> 파이프라인은 7단계입니다. 시작 단계인 Discovery를 제외한 모든 단계에는 진입 게이트가 있고,
> `/gate-check <목표 단계>`로 점검합니다. 단계와 스텝의 원본 정의는 `.claude/docs/workflow-catalog.yaml`이며
> `/help`가 이 파일을 읽습니다. 이 가이드와 카탈로그가 다르면 카탈로그가 맞습니다.
>
> 이 가이드의 예시는 모두 가상의 서비스 **Moa**를 기준으로 합니다. Moa는 한국 시장을 겨냥한 B2C 구독형 저축
> 앱(웹 + iOS + Android + API)으로, `auth`(이메일·카카오·네이버·Apple 로그인), `onboarding`, `goals`(저축 목표),
> `payments`(토스페이먼츠 자동이체), `notifications`(푸시 + 알림톡), `subscription`(Free / Plus 요금제),
> `admin-console` 기능을 가집니다.

---

## 목차

1. [시작하기](#시작하기)
2. [전체 그림](#전체-그림)
3. [1단계 Discovery: 탐색](#1단계-discovery-탐색)
4. [2단계 Definition: 기획](#2단계-definition-기획)
5. [3단계 Architecture: 아키텍처](#3단계-architecture-아키텍처)
6. [4단계 Validation: 검증](#4단계-validation-검증)
7. [5단계 Build: 구축](#5단계-build-구축)
8. [6단계 Hardening: 안정화](#6단계-hardening-안정화)
9. [7단계 Launch: 출시](#7단계-launch-출시)
10. [출시 후 운영과 반복 전달](#출시-후-운영과-반복-전달)
11. [티어별 차이](#티어별-차이)
12. [리뷰 모드와 디렉터 게이트](#리뷰-모드와-디렉터-게이트)
13. [공통 관심사](#공통-관심사)
14. [부록 A: 어떤 에이전트에게 맡길까](#부록-a-어떤-에이전트에게-맡길까)
15. [부록 B: 자주 쓰는 흐름](#부록-b-자주-쓰는-흐름)
16. [활용 팁](#활용-팁)

전체 스킬 목록은 [.claude/docs/skills-reference.md](../.claude/docs/skills-reference.md), 에이전트 목록은
[.claude/docs/agent-roster.md](../.claude/docs/agent-roster.md), 스킬 사이의 흐름도는
[skill-flow-diagrams.md](skill-flow-diagrams.md)에 있습니다.

---

## 시작하기

### 준비물

- **Claude Code**가 설치되어 동작해야 합니다.
- **Git** (Windows에서는 Git Bash, macOS·Linux에서는 기본 터미널)
- **Python 3** (필수 — 설정이 필요한 스킬은 모두 첫 줄에서 `yaml-helper.sh`로 `project.yaml`을 읽고, `/help`·`/gate-check`·
  `/project-stage-detect`의 산출물 점검(`artifact-check.sh`)과 훅의 JSON/YAML 검증도 Python을 씁니다. 없으면 모든
  설정이 기본값으로 돌아가 프로세스 강도는 `minimal`, 단계는 미설정으로 처리됩니다. PyYAML이 있으면 YAML을 완전
  파싱하고, 없으면 구조 검사로 대신하면서 `NOT CHECKED: full YAML parse (PyYAML unavailable)`를 출력합니다)
- **jq** (권장 — 없으면 훅이 `grep`으로 대신합니다)
- 스택에 따라 선택: Node.js와 pnpm, Docker, Playwright 브라우저, Xcode·Android SDK와 adb, k6

자세한 설치 안내는 [.claude/docs/setup-requirements.md](../.claude/docs/setup-requirements.md)에 있습니다.

### 클론하고 세션 열기

```bash
git clone <이 저장소의 URL> my-service
cd my-service
claude
```

세션이 열리면 `session-start.sh` 훅이 다음과 비슷한 요약을 보여 줍니다(값은 프로젝트마다 다릅니다).

```text
=== Claude Code Service Studios — Session Context ===
Branch: main

Recent commits:
  abc1234 Initial commit
...
Stage: Discovery (estimated)
```

배너가 보이지 않으면 `.claude/settings.json`의 훅 경로가 여러분의 OS에서 올바른지 확인하세요.

### `/start` 실행

첫 세션이라면 `/start`부터 실행합니다. 지금 어디서 출발하는지 묻고 알맞은 흐름으로 안내합니다.

| 선택지 | 상황 | 다음 단계 |
|---|---|---|
| **A** | 아직 제품 아이디어가 없음 | `/brainstorm open` |
| **B** | 풀고 싶은 문제나 대상 사용자는 있지만 제품은 아직 없음 | `/brainstorm <문제 영역>` |
| **C** | 누구를 위해 무엇을 하는지 분명한 제품 컨셉이 있음 | `/brainstorm <컨셉>`(빠른 경로) → `/setup-stack` |
| **D** | 이미 코드·문서·프로토타입·운영 중인 서비스가 있음 | `stage-estimate.sh`로 단계를 추정한 뒤 `/adopt` |

`/start`는 세 가지만 기록합니다. `project.stage`(A·B·C는 `Discovery`, D는 추정된 단계), `modes.rigor`(프로세스
강도), `modes.automation`(확인 빈도)입니다. 프로세스 강도는 여러분이 설명한 상황에서 추천합니다. 해커톤이나
프로토타입이면 `minimal`, 시드 단계의 제품 팀이면 `standard`, 결제·헬스케어처럼 규제가 있거나 SLA가 있는 B2B라면
`full`입니다. 자세한 내용은 [티어별 차이](#티어별-차이)를 보세요.

### `/help`로 다음 할 일 찾기

언제든 `/help`를 실행하면 `project.yaml`의 `project.stage`를 읽고(비어 있으면
`bash .claude/scripts/stage-estimate.sh`로 추정합니다), 해당 단계의 산출물을 `artifact-check.sh`로 확인한 뒤
**필수(REQUIRED)** 다음 단계와 **선택(OPTIONAL)** 기회를 구분해 알려 줍니다. 필수 스텝이라도 현재 티어나 조건에
해당하지 않으면 선택으로 표시하고 이유를 붙입니다.

- `(required at standard, full)` — 현재 티어에서는 필수가 아닙니다.
- `(required when ui)` — 조건(여기서는 UI 표면)이 거짓으로 확인되었습니다.
- `(when backend — unknown; run /setup-stack)` — 조건을 판단할 설정이 없어 필수로 취급합니다. 설정되지 않은 값은
  "아니다"가 아닙니다.

### 디렉터리 구조

디렉터리는 필요할 때 만들어집니다. 처음부터 모두 만들 필요는 없지만, 만들 때는 아래 구조를 따라야 합니다. 경로별
코딩 규칙과 스크립트가 이 경로를 기준으로 동작하기 때문입니다.

```text
<code roots>/        # 레이어별로 /setup-stack이 선언 (예: apps/web, apps/admin, apps/mobile, apps/api,
                     #   services/worker, packages, infra). 고정된 src/는 없습니다
design/
  product/           # product-brief.md 또는 one-pager.md, feature-map.md, user-journey.md,
                     #   tracking-plan.md, pricing-model.md, personas/
  prd/               # 기능별 PRD <feature-slug>.md (이 깊이에는 PRD만), reviews/
  ux/                # UX 명세, app-shell.md, interaction-patterns.md, reviews/
  handoff/           # 가져온 외부 디자인 <slug>/HANDOFF.md + bundle/(원본 그대로) + screens/ (/design-handoff)
  brand/             # design-language.md, tokens.json, voice-and-tone.md
  content/           # 카피 덱, 도움말 센터 문서
  inventory/         # screen-inventory.md, media-manifest.md
  registry/          # entities.yaml (용어·비즈니스 사실 레지스트리)
  accessibility-requirements.md
docs/
  architecture/      # architecture.md, adr-NNNN-<slug>.md, control-manifest.md, tech-radar.md, tr-registry.yaml
  api/               # api-guidelines.md, openapi.yaml (또는 GraphQL·proto·AsyncAPI), changes/, guides/
  data/              # data-model.md, migrations/NNNN-<slug>.md (계획 문서)
  security/          # threat-model.md
  ops/               # slo.md, runbooks/
  stack-reference/   # VERSION.md와 구성 요소별 버전·변경 사항 (/setup-stack이 생성)
tests/               # unit/, integration/, contract/, e2e/, load/, helpers/
prototypes/          # <name>-concept/, <name>-spike-YYYY-MM-DD/
production/
  sprints/  epics/  milestones/  retrospectives/  gate-checks/  walking-skeleton/
  qa/                # smoke-*.md, qa-plan-*.md, qa-signoff-*.md, evidence/, bugs/, usability/, perf/, load/
  security/  releases/<version>/  incidents/  hotfixes/  growth/
  session-state/     # active.md (gitignore 대상)
```

---

## 전체 그림

### 일곱 단계

| # | 단계 (`project.stage`) | 목적 | 진입 게이트 | 게이트 정의 파일 |
|---|---|---|---|---|
| 1 | `Discovery` (탐색) | 문제·사용자·가치 제안이라는 "베팅"을 정리하고, 이미 정한 스택 레이어의 버전을 고정합니다 | — | — |
| 2 | `Definition` (기획) | 제품을 기능으로 나누고 MVP 기능마다 PRD를 씁니다 | `/gate-check definition` | `gate-definition.md` |
| 3 | `Architecture` (아키텍처) | 아키텍처와 SLO, ADR, 초기 API 계약, 데이터 모델, 위협 모델, 접근성 기준, 테스트·CI 스캐폴드 | `/gate-check architecture` | `gate-architecture.md` |
| 4 | `Validation` (검증) | 핵심 화면을 명세하고, API를 화면에 맞추고, 스테이징에서 끝에서 끝까지 동작함을 증명하고, 첫 스프린트를 계획합니다 | `/gate-check validation` | `gate-validation.md` |
| 5 | `Build` (구축) | 스프린트 단위로 스토리를 골라 구현·검증·완료합니다 | `/gate-check build` | `gate-build.md` |
| 6 | `Hardening` (안정화) | 성능·부하·보안·접근성·사용성을 점검하고, QA 사인오프와 런북, 릴리스를 준비합니다 | `/gate-check hardening` | `gate-hardening.md` |
| 7 | `Launch` (출시) | 출시하고 운영하며 계속 전달합니다. 종착 단계이므로 다음 게이트는 없습니다 | `/gate-check launch` | `gate-launch.md` |

게이트 정의 파일은 `.claude/skills/gate-check/references/`에 있습니다.

### 게이트 이름 붙이는 규칙

- `/gate-check`의 인자는 언제나 **들어가려는 단계**(목표 단계)입니다: `definition`, `architecture`, `validation`,
  `build`, `hardening`, `launch`. 예를 들어 Build를 마치고 Hardening으로 넘어갈 준비가 되었는지 보려면
  `/gate-check hardening`을 실행합니다.
- 산출물 점검에 쓰는 **출발 단계**는 목표 단계에서 거꾸로 도출합니다(`next_phase`가 목표 단계인 단계). 현재
  `project.stage` 값에서 가져오지 않습니다.
- 인자 없이 `/gate-check`를 실행하면 `stage-estimate.sh`가 알려 준 현재 단계의 다음 단계를 목표로 삼습니다. 현재가
  `Launch`면 "Launch is terminal — no further phase gate; use /release-checklist, /rollout-plan and
  /retrospective release <version>."이라고 안내하고 멈춥니다.

### 게이트 판정

- 판정은 `PASS`, `CONCERNS`, `NOT ASSESSED`, `FAIL` 넷입니다. 여러 항목이 섞이면
  **FAIL > CONCERNS > NOT ASSESSED > PASS** 순으로 가장 엄한 것이 전체 판정이 됩니다.
- 현재 티어에서 확인할 필수 항목이 하나도 남지 않으면 `PASS`가 아니라 `NOT ASSESSED`입니다. 아무것도 확인하지
  않은 통과는 없습니다.
- 게이트는 **권고**입니다. 진행을 강제로 막지 않고, 없는 산출물을 대신 만들지도 않습니다. 결정은 사용자가 합니다.
- 판정이 `PASS`이고 사용자가 확인했을 때만 `project.yaml`의 `project.stage`를 갱신하고, 쓴 뒤 다시 읽어 검증합니다.
- 보고서는 `production/gate-checks/gate-<target>-YYYY-MM-DD.md`에 남고, 제목 바로 아래에
  `> **Verdict**: <판정>` 줄이 붙습니다.
- 판정하기 전에 스스로 다섯 가지 반론 질문을 던지고, 그중 둘 이상은 도구로 다시 확인합니다.

### 필수 스텝의 티어와 조건

카탈로그의 필수 스텝에는 두 가지 한정자가 붙을 수 있습니다.

- **티어** (`required_tiers`) — `modes.workflow`가 목록에 있을 때만 필수입니다. 예: `[standard, full]`.
- **조건** (`required_when`) — 아래 조건이 참일 때만 필수입니다.

| 조건 | 참이 되는 경우 |
|---|---|
| `ui` | `platform.surfaces`에 `web`, `ios`, `android` 중 하나 이상이 있음 |
| `backend` | `stack.layers.backend.framework` 또는 `stack.layers.data.database`가 설정되었거나, `platform.surfaces`에 `api`가 있음 |
| `pii` | `privacy.handles_pii: true` |
| `stores` | `release.distribution`이 `stores` 또는 `web+stores` |
| `multi-locale` | `localization.locales`에 로케일이 둘 이상 |

게이트는 여기에 두 가지 조건을 더 씁니다. **Public API**는 `platform.surfaces`에 `api`가 있을 때(외부 파트너나
공개 사용자가 쓰는 API), **Regions**는 `compliance.regions` 목록(`[]`이면 명시적으로 없음)입니다. 설정되지 않은
조건은 거짓이 아니라 "알 수 없음"이며, 게이트는 사용자에게 묻습니다. 거짓으로 확인된 조건의 항목은
`N/A — <condition> not configured`로 표시하고 점수에 넣지 않습니다.

아래 단계별 표의 "필수 여부" 칸은 이 규칙을 줄여 적은 것입니다. "필수"는 모든 티어, "필수 (standard·full)"는 두
티어에서만, "UI", "백엔드", "개인정보", "다국어"는 위 조건을 뜻합니다.

---

## 1단계 Discovery: 탐색

### 이 단계에서 하는 일

"아직 아이디어가 없다" 또는 "대충 이런 걸 만들고 싶다"에서 출발해, **무엇을, 누구를 위해, 왜** 만드는지를 글로
정리합니다. 이미 정한 스택 레이어(대개 웹·모바일·백엔드 프레임워크)는 이 단계에서 버전까지 고정합니다.

```text
/start ─→ /brainstorm ─→ one-pager (minimal) 또는 product brief (standard·full)
                │
                └─→ /prd-review (브리프 검토, standard·full 필수)
/setup-stack ─→ project.yaml의 stack.* + docs/stack-reference/ (마지막에 stack.pinned_on 기록)
/prototype   ─→ prototypes/<name>-concept/REPORT.md  (PROCEED / PIVOT / KILL / NOT ASSESSED)
        │
        ▼
/gate-check definition
```

| 스텝 | 명령 | 필수 여부 | 산출물 |
|---|---|---|---|
| 제품 탐색 | `/brainstorm` | 선택 | (대화) |
| 제품 브리프 | `/brainstorm` | 필수 | `design/product/product-brief.md` 또는 `design/product/one-pager.md` |
| 브리프 검토 | `/prd-review` | 필수 (standard·full) | `design/product/reviews/*-review-log.md` |
| 스택 설정 | `/setup-stack` | 권장 (Definition에서 standard·full, Architecture에서 모든 티어 필수) | `project.yaml`의 `stack.pinned_on` |
| 컨셉 프로토타입 | `/prototype` | 선택 | `prototypes/*-concept/REPORT.md` |

### `/brainstorm` — 문제에서 베팅까지

```text
/brainstorm open                        # 완전히 처음부터
/brainstorm 월급날마다 저축을 잊는 사회초년생   # 문제 영역에서 출발
/brainstorm pitch                        # 브리프로 투자·내부 설득용 피치 문서 작성
```

단계별로 하나씩 합의하며 진행합니다.

1. **문제와 근거** — 누가, 얼마나 자주, 어떤 비용을 치르고 있는가
2. **사용자와 JTBD** — 대상 사용자와 그들이 해내려는 일. standard·full에서는 `ux-researcher`와 함께
   `design/product/personas/<slug>.md` 페르소나를 만들 수 있습니다.
3. **대안과 포지셔닝** — 지금 사용자는 무엇으로 버티는가(은행 앱의 자동이체, 가계부 앱, 엑셀)
4. **가치 제안과 비즈니스 모델 가설**
5. **제품 원칙과 안티골** — 각 원칙이 어떤 트레이드오프를 결정하는지 적습니다(PD-PRINCIPLES 게이트).
6. **브랜드 방향 앵커** (선택) — `full`이고 UI 표면이 있을 때만 제안하며(DD-BRAND-DIRECTION), `/design-language`로
   미룰 수 있습니다.
7. **성공 지표** — North Star 지표 하나와 가드레일 지표
8. **가장 위험한 가정과 검증 방법** — 가정마다 프로토타입, 인터뷰, 페이크 도어, 데이터 중 무엇으로 확인할지
9. **MVP 범위** — 범위와 비범위(DM-SCOPE, TD-FEASIBILITY 게이트)

결과물은 티어에 따라 다릅니다.

- `minimal` → `design/product/one-pager.md`: `## Pitch`, `## Problem & Target User`, `## Core User Journey`,
  `## Success Signal`, `## Scope & Non-Goals`, `## Stack`, `## Build Order`. 이 한 장이 기획서와 스프린트 계획을
  대신합니다.
- `standard`·`full` → `design/product/product-brief.md`: `## Elevator Pitch`, `## Problem Statement`,
  `## Target Users & Jobs-to-be-Done`, `## Alternatives & Positioning`, `## Value Proposition`,
  `## Business Model Hypothesis`, `## Product Principles & Anti-Goals`, `## Brand Direction Anchor`(선택),
  `## Success Metrics`, `## Riskiest Assumptions`, `## MVP Scope`, `## Non-Goals`, `## Open Questions`.

마지막에 `project.yaml`에 `project.name`과 `project.category`(예: `B2C fintech`)를 기록해도 되는지 묻습니다.

### `/prd-review` — 브리프 검토 (standard·full 필수)

```text
/prd-review design/product/product-brief.md
```

기능으로 쪼개기 전에 브리프의 완성도와 일관성을 확인합니다. 판정은 `APPROVED`, `NEEDS REVISION`,
`MAJOR REVISION NEEDED`, `NOT ASSESSED`입니다. standard·full에서는 게이트가 이 검토 기록을 요구합니다.

### `/setup-stack` — 스택 선택과 버전 고정

```text
/setup-stack                    # 대화형 설정
/setup-stack ts-fullstack-web   # 프리셋에서 시작
/setup-stack refresh            # 새로 정한 레이어 추가, 출처 재확인
/setup-stack upgrade NestJS 11.0 12.0
```

- **감지** — `package.json`, `pnpm-workspace.yaml`, `pyproject.toml`, `build.gradle(.kts)`, `pubspec.yaml`,
  `Podfile`, `app.json`, `Dockerfile`, `*.tf` 같은 매니페스트를 읽어 레이어와 프레임워크, 코드 루트를 제안합니다.
- **표면과 배포** — `platform.surfaces`, `release.distribution`, `compliance.regions`, `privacy.handles_pii`,
  `localization.locales`를 묻습니다. 모두 미룰 수 있고, 미룬 값은 비어 있는 채로 남으며 이후 게이트가 다시 묻습니다.
- **레이어** — web, mobile, backend, data, cloud 레이어마다 프레임워크·언어·런타임·코드 루트(여러 개 가능)를
  고릅니다. **이미 결정한 레이어만** 정하면 됩니다. 데이터와 클라우드 레이어는 해당 ADR이 채택된 뒤
  `/setup-stack refresh`로 추가합니다. 프리셋(`ts-fullstack-web`, `expo-mobile-ts-api`, `flutter-spring`,
  `python-api-react`)은 구성 요소만 정하고 버전은 정하지 않습니다.
- **버전 고정** — 구성 요소마다 현재 안정 버전을 Context7(세션에 있을 때) 또는 웹 검색으로 확인하고 출처 URL과
  확인 날짜를 기록합니다. 관리형 서비스는 `n/a (managed service)`, 출처를 찾지 못하면 `NOT DETERMINED`로 적은 뒤
  수용 여부를 묻고, 수용하면 `NOT DETERMINED — accepted by user YYYY-MM-DD`로 기록합니다. 절대 추측하지 않습니다.
  모델의 지식 시점 이후에 나온 버전은 Knowledge Risk `MEDIUM` 또는 `HIGH`가 됩니다.
- **레퍼런스 문서** — `docs/stack-reference/VERSION.md`와 구성 요소별 `VERSION.md`, 위험도가 있는 구성 요소에는
  `breaking-changes.md`, `deprecated-apis.md`, `current-best-practices.md`를 씁니다. 모든 항목에
  `(Source: <url>, retrieved YYYY-MM-DD)`가 붙습니다.
- **그 밖의 기록** — 기술 레이더 `docs/architecture/tech-radar.md`(`## Adopt`에 선택한 구성 요소), 코드 루트별
  `<root>/CLAUDE.md`(선택), 명명 규칙(`naming.*`), 실행 명령(`commands.*` — 추측하지 않고 묻습니다).
- **완료 표시** — 설정된 모든 구성 요소가 출처 확인, 관리형, 또는 수용된 공백 상태가 되면 마지막에
  `stack.pinned_on: YYYY-MM-DD`를 씁니다. 카탈로그는 이 값으로 스택 설정 완료를 판단합니다.
- **한국 지역** — `compliance.regions`에 `kr`이 있으면 카카오·네이버·Apple 로그인과 토스페이먼츠·인앱 결제를
  연동 후보로 제안하고, 기술 레이더의 `Assess` 링에만 기록합니다.
- `upgrade` 모드는 TD-STACK-RISK 게이트를 거치고, 그 구성 요소를 쓰는 ADR을 업그레이드 기록
  (`docs/stack-reference/<component>/upgrade-<old>-to-<new>.md`)에 "re-validation required"로 나열합니다. ADR 파일은
  고치지 않습니다(`/architecture-decision`이 담당).

### `/prototype` — 가장 위험한 가정부터 싸게 확인

```text
/prototype "첫 목표 설정까지 1분 안에" --path clickable
/prototype "자동이체 연결 의향" --path fake-door
/prototype "토스페이먼츠 자동이체 웹훅 흐름" --spike
/prototype report prototypes/goal-setup-concept
```

- 경로는 네 가지입니다. **clickable**(클릭 가능한 화면), **fake-door**(없는 기능의 버튼을 두고 클릭률 측정),
  **concierge**(사람이 수작업으로 서비스를 대신 제공), **code**(`prototyper`가 코드로 빠르게 구현).
- 결과는 `prototypes/<name>-concept/REPORT.md`이며 판정은 `PROCEED`(계속), `PIVOT`(방향 전환 —
  `PIVOT-NOTE.md`), `KILL`(중단)이며, 근거가 셋 중 어느 판정도 뒷받침하지 못하면(예: 세션을 한 번도 진행하지 못함) `NOT ASSESSED`입니다. 사용자 세션이 있으면 PD-USER-VALIDATION 게이트가 붙습니다.
- `--spike`는 기술 확인용으로 `prototypes/<name>-spike-YYYY-MM-DD/SPIKE-NOTE.md`를 씁니다.
- 프로토타입 코드는 운영 코드가 아닙니다. 실제 개인정보와 운영 키를 쓰지 않고, 운영 도메인에 배포하지 않습니다.

### 게이트: `/gate-check definition` (Discovery → Definition)

| 확인 항목 | full | standard | minimal |
|---|---|---|---|
| 제품 브리프가 있고 `Problem Statement`, `Target Users & Jobs-to-be-Done`, `Value Proposition`, `Product Principles & Anti-Goals`, `Success Metrics`, `Riskiest Assumptions`, `MVP Scope` 섹션이 채워져 있음 | 필수 | 필수 | — |
| one-pager의 제목이 모두 채워져 있음 | — | — | 필수 |
| 원칙마다 결정하는 트레이드오프가 적혀 있음 | 필수 | 권장 | — |
| 브랜드 방향 앵커 (UI가 있을 때) | 권장 | — | — |
| 컨셉 프로토타입이 `PROCEED` | 권장 | 권장 | — |
| 스택 고정 (`stack.pinned_on`) | 권장 | 권장 | 권장 |
| `/prd-review` 판정이 `MAJOR REVISION NEEDED`가 아님 | 필수 | 필수 | — |
| North Star 지표와 가드레일 지표 하나 이상 | 필수 | 필수 | — |
| 대상 세그먼트가 구체적으로 이름 붙어 있음 | 필수 | 필수 | — |
| 위험한 가정마다 검증 방법이 있음 | 필수 | 권장 | — |
| 비범위(Non-Goals)가 적혀 있음 | 필수 | 필수 | 필수 |

---

## 2단계 Definition: 기획

### 이 단계에서 하는 일

제품을 기능으로 나누고, MVP 기능마다 PRD를 섹션 단위로 씁니다. 아직 코드를 쓰지 않습니다. 한국 스타트업에서
"기획"이라고 부르는 일이 여기에 해당합니다.

```text
/map-features ─→ design/product/feature-map.md (기능, 의존 순서, MVP / Beta / GA / Later)
      │
      ▼ (MVP 기능마다, 의존 순서대로)
/write-prd <feature> ─→ design/prd/<feature>.md ─→ /prd-review ─→ design/prd/reviews/<feature>-review-log.md
      │
      ▼ (MVP PRD가 모두 승인되면)
/review-all-prds ─→ design/prd/reviews/prd-cross-review-YYYY-MM-DD.md
/consistency-check (PRD를 추가·수정할 때마다)    /ux-design journey (선택)
/setup-stack (Discovery에서 고정하지 않았다면)
      │
      ▼
/gate-check architecture
```

| 스텝 | 명령 | 필수 여부 | 산출물 |
|---|---|---|---|
| 기능 맵 | `/map-features` | 필수 (standard·full) | `design/product/feature-map.md` |
| 기능 PRD | `/write-prd` | 필수 (standard·full), 반복 | `design/prd/*.md` |
| PRD 검토 | `/prd-review` | 필수 (standard·full), 반복 | `design/prd/reviews/*-review-log.md` |
| PRD 교차 검토 | `/review-all-prds` | 필수 (full), standard는 권장 | `design/prd/reviews/prd-cross-review-*.md` |
| 스택 고정 | `/setup-stack` | 필수 (standard·full) | `project.yaml`의 `stack.pinned_on` |
| 사용자 여정 지도 | `/ux-design journey` | 선택 | `design/product/user-journey.md` |
| 일관성 점검 | `/consistency-check` | 선택, 반복 | (자동 판별 없음) |

`minimal`에서는 이 단계의 스텝이 모두 필수가 아닙니다. one-pager가 기획서 역할을 합니다.

### `/map-features` — 기능 맵

브리프를 읽고 서비스에 흔히 필요한 기능을 체크리스트로 제안합니다. 인증·계정, 온보딩, 핵심 도메인 기능, 알림,
결제·청구, 구독·권한(entitlement), 역할 기반 권한과 워크스페이스(B2B), 검색, 설정과 계정(데이터 내보내기, 회원
탈퇴 포함), 어드민·운영툴, 리포팅, 분석·계측, 동의와 개인정보, 고객 지원이 기본 목록입니다.

기능 맵의 표 헤더는 계약이므로 정확히 이 형태입니다.

```markdown
| Feature | Category | Layer | Tier | Status | PRD | Depends On |
```

- `Layer`: `Foundation`, `Core`, `Feature`, `Presentation`
- `Tier`: `MVP`, `Beta`, `GA`, `Later`
- `Status`: `Not Started`, `Drafting`, `In Review`, `Needs Revision`, `Approved`, `Implemented`

TD-DOMAIN-BOUNDARY(경계와 데이터 소유), PD-FEATURE-MAP(MVP가 가치 제안을 전달하는가), DM-SCOPE(범위와 일정)
게이트가 붙습니다. 다음 기능으로 넘어갈 때는 `/map-features next`를 씁니다.

### `/write-prd` — 섹션 단위 PRD 작성

```text
/write-prd goals
```

브리프, 기능 맵, 의존 관계에 있는 PRD를 읽은 뒤 섹션을 하나씩 진행합니다. 섹션마다 **맥락 → 질문 → 선택지 →
결정 → 초안 → 승인 → 쓰기** 순서이고, 승인된 섹션은 즉시 파일에 기록되므로 세션이 끊겨도 남습니다. 섹션마다
알맞은 에이전트에게 의견을 구합니다(비즈니스 규칙은 `business-analyst`, 가격은 `monetization-strategist`, 비기능
요구는 엔지니어와 `security-engineer`·`accessibility-specialist`, 성공 지표는 `analytics-engineer`, 인수 조건은
`qa-lead`).

PRD의 11개 계약 섹션과 티어별 요구 수준은 다음과 같습니다.

| # | 섹션 (`## …`) | full | standard | 내용 |
|---|---|---|---|---|
| 1 | `Overview` | 필수 | 필수 | 무엇을, 왜 — 한 단락 |
| 2 | `Goals & Non-Goals` | 필수 | 필수 | 브리프와 연결된 목표, 명시적인 제외 범위 (`/scope-check`가 비교) |
| 3 | `User Value` | 필수 | 권장 | 페르소나, JTBD, 사용자 스토리, 성공 순간 |
| 4 | `Functional Requirements` | 필수 | 필수 | `### Core Rules`, `### User Flows & States`, `### Interactions with Other Features` |
| 5 | `Business Rules & Calculations` | 필수 | 조건부 | 가격, 수수료, 한도, 쿼터, 자격 조건, 시간 창, 반올림 규칙이 있으면 필수 |
| 6 | `Edge Cases` | 필수 | 필수 | 네트워크 끊김, 부분 실패, 동시성, 재시도 포함 |
| 7 | `Dependencies` | 필수 | 필수 | 기능 PRD 의존 표(양방향) + `### External Services` |
| 8 | `Non-Functional Requirements` | 필수 | 필수 | 성능, 가용성, 보안·개인정보(개인정보 필드, 인가 규칙, 보관), 접근성, 현지화 |
| 9 | `Configuration & Flags` | 필수 | 권장 | 기능 플래그(키, 기본값, 담당, 제거 예정일), 설정값, 운영에 노출되는 한도 |
| 10 | `Success Metrics & Instrumentation` | 필수 | 필수 (기준값·목표가 있는 지표 1개 이상) | 움직일 지표, 이벤트, 대시보드 |
| 11 | `Acceptance Criteria` | 필수 | 필수 | 검증 가능한 Given/When/Then |

- 비즈니스 규칙은 변수·단위·반올림·예시를 함께 적습니다. 예: "월 이용료 = 요금제 가격 × 좌석 수, 10원 단위 반올림".
- `## Dependencies`는 `| Feature | PRD | Direction | Nature |` 표로 쓰고 PRD 경로(`design/prd/auth.md`)를 적습니다.
  스크립트가 이 표에서 의존 관계를 읽습니다.
- 새 엔터티·요금제·규칙·상수·이벤트는 `design/registry/entities.yaml`에 추가됩니다(삭제하지 않고
  `status: deprecated`로 표시).
- 성공 지표가 승인되면 이벤트를 `design/product/tracking-plan.md`에 추가해도 되는지 묻습니다. 요금제·가격·크레딧을
  정의하는 PRD라면 `design/product/pricing-model.md`도 만들거나 갱신합니다.
- 작성이 끝나면 기능 맵의 상태가 `Drafting`에서 `In Review`로 바뀌고, PD-PRD-ALIGN 게이트가 PRD와 제품 원칙의
  정렬을 봅니다.
- `workflow_overrides.edge_cases: true`는 minimal에서 자발적으로 쓴 PRD에도 `Edge Cases`를,
  `workflow_overrides.config_flags: true`는 standard에서도 `Configuration & Flags`를 필수로 만듭니다.
- 섹션 존재 여부는 `bash .claude/scripts/prd-structure-check.sh design/prd/goals.md`로 확인할 수 있습니다.

### `/prd-review` — PRD 하나씩 검토

```text
/prd-review design/prd/goals.md
```

티어가 요구하는 섹션, 규칙의 명확성, 엣지 케이스 해결, 양방향 의존, 검증 가능한 인수 조건을 봅니다. 판정은
`APPROVED`, `NEEDS REVISION`, `MAJOR REVISION NEEDED`, `NOT ASSESSED`이고, 기록은
`design/prd/reviews/goals-review-log.md`에 남습니다. `APPROVED`가 나오면 PRD의 `> **Status**: Approved`와 기능 맵의
상태를 `Approved`로 바꿀지 묻습니다. 다음 기능은 승인된 PRD 위에서 시작하는 것이 좋습니다.

### `/quick-spec` — PRD까지 필요 없는 작은 변경

```text
/quick-spec "Free 요금제의 저축 목표 개수 한도를 3개에서 5개로"
```

설정값 변경, 동작 조정, 작은 개선은 전체 PRD 대신 `design/quick-specs/<kebab-title>-YYYY-MM-DD.md`에 가볍게
명세합니다. 롤아웃 메모가 함께 들어갑니다.

### `/review-all-prds` — PRD 교차 검토

MVP PRD가 모두 개별 승인된 뒤 실행합니다. 모든 PRD를 함께 읽고 두 관점으로 검토합니다.

- **일관성** — 의존의 양방향성, 규칙 모순, 서로 충돌하는 한도·가격·지표, 오래된 참조, 설정·플래그 소유권
- **제품 이론** — 원칙 대비 가치 전달, 흐름 전반의 인지 부담, 비즈니스 규칙의 악용 경로, 안티골과 PRD 비범위를
  벗어난 범위 확장

판정은 `PASS`, `CONCERNS`, `FAIL`(과 `NOT ASSESSED`)이고, `/review-all-prds since-last-review`로 마지막 검토 이후
바뀐 PRD와 그 의존 대상만 볼 수 있습니다.

### `/consistency-check`와 `/ux-design journey`

- `/consistency-check`는 PRD를 용어 레지스트리(`entities`, `plans`, `rules`, `constants`, `events`)와 대조해
  모순을 찾습니다. PRD를 추가하거나 고칠 때마다 다시 실행하세요.
- `/ux-design journey`는 획득 → 가입 → 온보딩·활성화 → 습관 → 유지 → 수익화 → 추천에 이르는 생애주기 단계와
  가치를 느끼는 순간, 이탈 위험, 단계별 지표를 `design/product/user-journey.md`에 정리합니다.

### 게이트: `/gate-check architecture` (Definition → Architecture)

| 확인 항목 | full | standard |
|---|---|---|
| 기능 맵에 MVP 기능이 열거되어 있음 | 필수 | 필수 |
| MVP 기능마다 PRD와 `MAJOR REVISION NEEDED`로 끝나지 않은 검토 기록이 있음 | 필수 | 필수 |
| PRD 교차 검토 보고서 | 필수 | 권장 |
| 스택 고정 (설정된 레이어만) | 필수 | 필수 |
| MVP PRD가 티어의 필수 섹션을 갖춤 (`prd-structure-check.sh`) | 필수 (11개) | 필수 (8개 + 조건부) |
| `/review-all-prds` 판정이 `FAIL`이 아니고 지적 사항이 해결 또는 수용됨 | 필수 | 권장 (보고서가 있을 때) |
| 기능 의존이 기능 맵과 PRD `## Dependencies` 양쪽에서 일치 | 필수 | 필수 |
| MVP 티어가 정의되어 있고 오래된 PRD 참조가 없음 | 필수 | 필수 |
| 모든 MVP PRD의 비기능 요구에 성능·가용성·보안·개인정보·접근성이 있음 | 필수 | 필수 |
| 모든 MVP PRD에 기준값·목표가 있는 지표가 1개 이상 | 필수 | 필수 |
| `workflow_overrides.feature_overrides`의 키마다 같은 이름의 PRD가 있음 (없으면 `CONCERNS`) | 필수 | 필수 |

`minimal`에서는 이 게이트가 적용되지 않습니다. "one-pager가 기획 기록이다"라는 메모와 함께 `PASS`를 돌려주고, PRD가
없다고 지적하지 않습니다.

---

## 3단계 Architecture: 아키텍처

### 이 단계에서 하는 일

핵심 기술 결정을 내리고 ADR로 남깁니다. 초기 API 계약과 데이터 모델을 쓰고, 개인정보를 다룬다면 위협 모델을 만들고,
접근성 목표를 확정하고, 테스트 러너와 CI를 한 번 세팅합니다.

```text
/create-architecture ─→ docs/architecture/architecture.md + docs/ops/slo.md
/architecture-decision (×N) ─→ docs/architecture/adr-NNNN-<slug>.md
/api-design new ─→ docs/api/api-guidelines.md + docs/api/openapi.yaml (초기 계약: Foundation·Core 리소스)
/data-model ─→ docs/data/data-model.md (+ docs/data/migrations/NNNN-<slug>.md)
/security-audit threat-model ─→ docs/security/threat-model.md
/ux-design accessibility ─→ design/accessibility-requirements.md (+ accessibility.target)
/test-setup ─→ 러너 설정, tests/, .github/workflows/ci.yml  →  /test-helpers
/architecture-review ─→ 검토 보고서 + requirements-traceability.md + tr-registry.yaml
/setup-stack refresh (데이터·클라우드 ADR 채택 뒤) ─→ docs/stack-reference/VERSION.md 완비
        │
        ▼
/gate-check validation
```

| 스텝 | 명령 | 필수 여부 | 산출물 |
|---|---|---|---|
| 아키텍처 문서와 SLO | `/create-architecture` | 필수 (standard·full) | `docs/architecture/architecture.md` (+ `docs/ops/slo.md`) |
| 아키텍처 결정 | `/architecture-decision` | 필수 (standard·full), 반복 | `docs/architecture/adr-*.md` |
| API 계약 (초기) | `/api-design` | 필수 (standard·full, 백엔드), 반복 | `docs/api/openapi*.yaml` 등 |
| 데이터 모델 | `/data-model` | 필수 (standard·full, 백엔드) | `docs/data/data-model.md` |
| 위협 모델 | `/security-audit threat-model` | 필수 (standard·full, 개인정보) | `docs/security/threat-model.md` |
| 아키텍처 검토 | `/architecture-review` | 필수 (standard·full) | `docs/architecture/architecture-review-*.md` |
| 접근성 요구사항 | `/ux-design accessibility` | 필수 (standard·full, UI) | `design/accessibility-requirements.md` |
| 테스트 프레임워크와 CI | `/test-setup` | 필수 (standard·full) | `.github/workflows/*.yml` 등 CI 설정 |
| 스택 고정 (VERSION.md 완비) | `/setup-stack` (데이터·클라우드 ADR 채택 뒤 `/setup-stack refresh`) | 필수 | `project.yaml`의 `stack.pinned_on` + `docs/stack-reference/VERSION.md` |

### `/create-architecture` — 아키텍처 청사진과 SLO

- **아키텍처 문서** — 레이어와 모듈, 배포 토폴로지와 환경(dev / staging / prod + 프리뷰), 데이터 흐름, 외부 연동,
  보안 모델, 관측성, 비기능 예산(`performance.*`), 열린 질문
- **SLO 문서** (`docs/ops/slo.md`, `sre-engineer`와 함께) — `## Critical User Journeys`(항상), `## SLIs & SLOs`,
  `## Error Budget Policy`, `## Dashboards & Alerts`(여기 적힌 호출 알림마다 Hardening에서 런북을 만듭니다),
  `## On-call`
- `/create-architecture tdd goals`는 기능별 기술 설계 `docs/architecture/tdd-goals.md`를 씁니다(선택, 게이트 산출물
  아님).
- TD-ARCHITECTURE, TL-FEASIBILITY 게이트가 붙습니다.

### `/architecture-decision` — ADR

```text
/architecture-decision "인증 방식: 서버 세션 vs 액세스·리프레시 토큰"
/architecture-decision retrofit docs/architecture/adr-0003-api-style.md
/architecture-decision accept ADR-0001
```

- ADR은 `.claude/docs/templates/architecture-decision-record.md` 템플릿의 제목을 그대로 씁니다. 주요 섹션은
  `## Stack Compatibility`(구성 요소와 고정 버전, Domain, Layer, Knowledge Risk), `## ADR Dependencies`
  (`**Depends On**`, `**Enables**`, `**Blocks**`, `**Ordering Note**`), `## Alternatives Considered`,
  `## Consequences`, `## Performance & SLO Implications`, `## Security & Privacy Implications`,
  `## Cost Implications`, `## Migration Plan`(`**Rollback plan**:` 포함), `## PRD Requirements Addressed`입니다.
- 수명주기는 `Proposed` → `Accepted` → `Superseded by ADR-NNNN` 또는 `Deprecated`이며, 채택은 `technical-director`가
  승인합니다. 첫 ADR 예시는 `docs/architecture/adr-0001-identity-and-auth.md`입니다.
- **full**에서는 Foundation 레이어 ADR이 최소 3개 필요합니다(인증과 인가, 주 데이터 저장소, API 스타일, 배포
  토폴로지와 환경, 관측성 중에서). **standard**에서는 아키텍처 문서가 핵심으로 표시한 Foundation ADR만 필요합니다.
- `retrofit`은 기존 ADR에서 빠진 섹션만 채우고 기존 내용은 덮어쓰지 않습니다.
- 게이트: TD-ADR(채택 전 검토), TD-STACK-RISK(Knowledge Risk가 HIGH·MEDIUM일 때), SE-SECURITY-REVIEW(Domain이
  `Auth`, `Security`, `Data`일 때). Domain이 `Data`나 `Infra`인 ADR이 채택되면 `/setup-stack refresh`로 이어집니다.
- 허용·보류·금지 기술은 기술 레이더(`docs/architecture/tech-radar.md`)에 반영됩니다(쓰기 전에 묻습니다).

### `/api-design` — 계약 우선 API 설계

```text
/api-design new                # 초기 계약 (Architecture)
/api-design reconcile          # UX 명세와 맞추기 (Validation)
/api-design update goals       # 리소스 수정
/api-design breaking-check     # 하위 호환성 검사
```

- 백엔드 조건이 거짓으로 확인되면 `NOT ASSESSED — no backend layer, data layer or api surface configured`로 멈춥니다.
  standard·full에서 API 스타일을 결정한 채택된 ADR이 없으면 `/architecture-decision`으로 돌려보냅니다.
- **가이드라인** (`docs/api/api-guidelines.md`) — 버전 관리, 리소스 명명(`naming.api_paths`, `naming.api_fields`),
  오류 모델(RFC 9457 problem+json), 페이지네이션, 필터·정렬, 멱등성 키, 속도 제한, 인가 스코프, 지원 중단
  (Deprecation·Sunset 헤더), 시각과 시간대, 금액과 통화, 다국어
- **리소스 모델링** — PRD 기능마다 오퍼레이션, 메서드와 경로, 인가 스코프, 요청·응답 스키마, 오류, 멱등성 여부,
  개인정보 필드, TR-ID를 표로 정리합니다. Architecture 단계의 `new`는 인증·세션, 계정, 핵심 도메인 엔터티(Moa라면
  저축 목표)처럼 Foundation·Core 리소스만 다루는 **초기** 계약입니다.
- **계약 쓰기** — 기본은 OpenAPI 3.1(`docs/api/openapi.yaml`)이고, ADR이 정하면 GraphQL, protobuf, AsyncAPI를 씁니다.
- **린트와 호환성** — `commands.api_lint`가 있으면 실행하고, 없으면 구조 자체 점검을 합니다. 직전 커밋과 비교해
  필드·오퍼레이션 제거, 타입 변경, 새 필수 필드, enum 축소를 `BREAKING`으로 분류하고, 버전 올림이나 지원 중단 계획을
  요구합니다. 외부에 공개하는 API(`api` 표면)라면 `Sunset` 날짜와 지원 중단 기간을 지켜야 하고, 릴리스 노트에
  `## API / Developers` 항목이 들어갑니다.
- SE-SECURITY-REVIEW 게이트가 오퍼레이션별 인가(BOLA/IDOR), 신뢰 경계, 개인정보 분류를 봅니다.
- 판정: `CONTRACT READY`, `NEEDS REVISION`, `BREAKING CHANGE — ACTION REQUIRED`, `NOT ASSESSED`

### `/data-model` — 데이터 모델과 마이그레이션 계획

- **model** — 엔터티와 관계(Mermaid ER), 바운디드 컨텍스트별 소유권, 필드별 분류(`Public`, `Internal`,
  `Confidential`, `PII`, `Sensitive-PII`), 보관·삭제(삭제 요청 처리 경로), 동의 연결, 인덱스와 접근 패턴,
  멀티테넌시, 일관성과 트랜잭션. `PII` 필드가 있는데 `privacy.handles_pii`가 비어 있으면 `true`로 설정할지 묻습니다.
- **migration <slug>** — `docs/data/migrations/NNNN-<slug>.md`에 **Expand**(추가만) → **Migrate**(이중 쓰기, 배치
  백필, 검증 쿼리) → **Contract**(모든 읽기 측이 배포된 뒤에만 옛 경로 제거 — 모바일은 최소 지원 앱 버전이 더 이상
  읽지 않을 때) 계획을 씁니다. 잠금·소요 시간 예산, 단계별 롤백, 앱 릴리스와의 배포 순서도 포함됩니다. 드라이런은
  로컬·일회용 DB에서만 하며, 공유 DB나 운영 DB에는 절대 실행하지 않습니다.
- **review** — 계획 없는 파괴적 변경(컬럼·테이블 삭제·이름 변경, 타입 축소)이 있으면 `FAIL`입니다.
- SE-SECURITY-REVIEW 게이트가 붙습니다.

### `/security-audit threat-model`과 `/ux-design accessibility`

- 위협 모델은 아키텍처와 데이터 모델을 바탕으로 신뢰 경계마다 STRIDE 분석을 해서 `docs/security/threat-model.md`만
  씁니다. 감사 보고서가 아니므로 Hardening 단계의 보안 감사를 대신하지 않습니다. 개인정보를 다루지 않아도 권장합니다.
- 접근성 요구사항은 `accessibility.target`(`none`, `wcag-a`, `wcag-aa`, `wcag-aaa` — WCAG 2.2)을 확정하고,
  `compliance.regions`에 따라 지역 기준(한국은 KWCAG 2.2, EU는 EAA, 미국은 ADA·Section 508)을 더합니다. 이 파일이
  `design/ux/` 밖에 있는 것은 의도된 것입니다(UX 명세 개수에 포함되지 않도록).

### `/test-setup` — 테스트 러너와 CI를 한 번에

```text
/test-setup all --ci github
```

레이어마다 러너를 제안하고 하나씩 확인받습니다.

| 레이어 | 기본 제안 |
|---|---|
| 웹 | Vitest(또는 Jest) + Testing Library + Playwright |
| React Native | Jest + Maestro(또는 Detox) |
| Flutter | flutter_test + integration_test(또는 Maestro) |
| iOS 네이티브 | XCTest |
| Android 네이티브 | JUnit + Espresso |
| Node 백엔드 | Vitest/Jest + Supertest |
| Spring | JUnit 5 + Testcontainers |
| Python | pytest + httpx |
| 계약 테스트 | OpenAPI 계약 대상 Schemathesis(소비자 주도라면 Pact) |

러너 설정, `tests/{unit,integration,contract,e2e}/` 예제 테스트, `.github/workflows/ci.yml`(레이어별 `lint`,
`typecheck`, `test`, `e2e` 잡)을 쓰고, `testing.framework`, `testing.patterns`, `commands.test`, `commands.e2e`,
`commands.lint`, `commands.typecheck`를 기록할지 하나씩 묻습니다. 웹 레이어가 있으면 증거 캡처 스크립트
`tests/e2e/capture.spec.ts`도 만듭니다(1280×800 데스크톱, 390×844 모바일 스크린숏, `@axe-core/playwright`가 있으면
접근성 결과). 이어서 `/test-helpers`로 레이어별 팩토리(고정 시드), 인증 픽스처, DB 초기화, 네트워크 목, Playwright
픽스처를 만듭니다.

### `/architecture-review`

- `/architecture-review`는 PRD 요구사항 → ADR 추적 행렬(`docs/architecture/requirements-traceability.md`)을 만들고,
  TR-ID 레지스트리(`docs/architecture/tr-registry.yaml`, 예: `TR-goals-001`)를 유지하며, ADR 사이의 충돌과 스택
  호환성, ADR 의존 순환을 봅니다. 판정은 `PASS`, `CONCERNS`, `NOT ASSESSED`, `FAIL`입니다.

### 게이트: `/gate-check validation` (Architecture → Validation)

| 확인 항목 | full | standard | minimal |
|---|---|---|---|
| 스택 고정 + `docs/stack-reference/VERSION.md`에 설정된 구성 요소마다 출처 있는 행 (수용된 공백은 `CONCERNS`) | 필수 | 필수 | 필수 (minimal의 최저선) |
| `docs/architecture/architecture.md` | 필수 | 필수 | — |
| ADR (full: Foundation ADR 3개 이상, standard: 핵심 Foundation ADR) | 필수 | 필수 | — |
| 초기 API 계약 — 인증·세션, 계정, 핵심 도메인 엔터티 (백엔드) | 필수 | 필수 | — |
| 데이터 분류와 마이그레이션 전략이 있는 데이터 모델 (백엔드) | 필수 | 필수 | — |
| 위협 모델 (개인정보를 다룰 때 필수, 아니면 권장) | 필수 | 필수 | — |
| `requirements-traceability.md` | 필수 | 권장 | — |
| 아키텍처 검토 보고서 | 필수 | 필수 | — |
| 접근성 요구사항과 `accessibility.target` (UI) | 필수 | 필수 | — |
| 테스트 프레임워크(레이어별 러너 설정 + 예제 테스트)와 CI 워크플로 | 필수 | 필수 | — |
| `docs/ops/slo.md` (full: 핵심 여정마다 SLO, standard: 핵심 여정 섹션) | 필수 | 필수 | — |
| 기술 레이더 | 필수 | 권장 | — |
| 모든 ADR에 `Stack Compatibility`, `ADR Dependencies`, `PRD Requirements Addressed` | 필수 | 필수 | — |
| 지원 중단 API 미사용, ADR 사이 고정 버전 일치 | 필수 | 필수 | — |
| Knowledge Risk HIGH·MEDIUM 구성 요소가 모두 다뤄짐, Foundation 추적 공백 0, `performance.*` 예산 설정 | 필수 | 권장 | — |
| 개인정보 필드마다 분류·보관 규칙·삭제 경로 (개인정보) | 필수 | 필수 | — |
| 시크릿 관리 방식이 ADR로 결정됨 | 필수 | 필수 | — |
| ADR 순환 의존 없음 (`adr-dep-graph.sh`의 `CYCLE:`이 있으면 `FAIL`) | 필수 | 필수 | — |

---

## 4단계 Validation: 검증

### 이 단계에서 하는 일

핵심 화면을 명세하고, API 계약을 그 화면에 맞추고, 에픽과 스토리를 만들고, 첫 스프린트를 계획합니다. 그리고 가장
중요한 일로, **워킹 스켈레톤**을 스테이징에 배포해 UI → API → DB → 관측성으로 이어지는 실제 경로가 동작함을 증명합니다.
흔히 "Sprint 0"이라고 부르는 일입니다.

```text
/ui-inventory (선택) ─→ design/inventory/screen-inventory.md
/design-language ─→ design/brand/design-language.md (브리프에 브랜드 앵커가 없으면 방향부터)
/design-handoff <핸드오프 프롬프트 | 번들 | 아티팩트 URL | Figma URL> (선택, design.tool이 claude-design·figma일 때)
        ─→ design/handoff/<slug>/HANDOFF.md ─→ UX 명세의 > **Design Source**: 줄
/ux-design shell · patterns · <핵심 화면> ─→ design/ux/*.md ─→ /ux-review
/usability-report (선택) ─→ production/qa/usability/
/api-design reconcile ─→ docs/api/changes/api-change-YYYY-MM-DD.md
/create-control-manifest ─→ docs/architecture/control-manifest.md
/create-epics layer: foundation → /create-stories <epic> → /create-epics layer: core → /create-stories <epic>
/sprint-plan new ─→ production/sprints/sprint-01.md + production/sprint-status.yaml
/walking-skeleton ─→ production/walking-skeleton/report-YYYY-MM-DD.md (VALIDATED / NOT VALIDATED / NOT ASSESSED)
        │
        ▼
/gate-check build
```

| 스텝 | 명령 | 필수 여부 | 산출물 |
|---|---|---|---|
| 화면·미디어 인벤토리 | `/ui-inventory` | 선택 | `design/inventory/screen-inventory.md` |
| 디자인 언어 | `/design-language` | 필수 (standard·full, UI) | `design/brand/design-language.md` |
| 외부 디자인 가져오기 (Claude Design·Figma) | `/design-handoff` | 선택, 반복 | `design/handoff/*/HANDOFF.md` |
| 핵심 화면 UX 명세 | `/ux-design` | 필수 (standard·full, UI), 반복, 3개 이상 | `design/ux/*.md` |
| UX 검토 | `/ux-review` | 필수 (standard·full, UI) | `design/ux/reviews/*-ux-review-*.md` |
| 사용성 테스트 (프로토타입) | `/usability-report` | 선택, 반복 | `production/qa/usability/*.md` |
| API 계약 조정 | `/api-design reconcile` | 필수 (full, 백엔드·UI), standard는 권장, 반복 | `docs/api/changes/api-change-*.md` |
| 컨트롤 매니페스트 | `/create-control-manifest` | 필수 (full), standard는 권장 | `docs/architecture/control-manifest.md` |
| 에픽 | `/create-epics` | 필수 (standard·full), 반복 | `production/epics/*/EPIC.md` |
| 스토리 | `/create-stories` | 필수 (standard·full), 반복 | `production/epics/*/story-*.md` |
| 첫 스프린트 계획 | `/sprint-plan` | 필수 (standard·full) | `production/sprints/sprint-*.md` |
| 워킹 스켈레톤 | `/walking-skeleton` | 필수 (standard·full) | `production/walking-skeleton/report-*.md` |

### `/design-language` — 디자인 언어

UI 제작의 기준이 되는 문서를 아홉 섹션으로 씁니다: `## 1. Brand Principles`, `## 2. Color System`,
`## 3. Typography`, `## 4. Layout, Spacing & Grid`, `## 5. Components & States`, `## 6. Iconography & Illustration`,
`## 7. Motion & Feedback`, `## 8. Platform Adaptation`, `## 9. Content & Voice`.

- 브리프에 `## Brand Direction Anchor`가 없으면 먼저 DD-BRAND-DIRECTION 게이트가 2–3개의 방향을 제시하고, 사용자가
  고른 방향을 1번 섹션에 기록합니다.
- 색상 섹션에는 시맨틱 토큰, 다크 모드, `accessibility.target` 대비 기준이, 타이포그래피에는 한국어 조판(글꼴 스택,
  행간, `word-break: keep-all`, 글꼴 서브셋)이 들어갑니다. 9번 섹션은 `/team-content`가 관리하는
  `design/brand/voice-and-tone.md`를 가리키고 UI 문구 규칙만 담습니다.
- 티어: full은 9개 섹션 전체, standard는 1–5번 섹션(`workflow_overrides.design_language_strict: true`면 전체).
- `design-director`가 DD-DESIGN-LANGUAGE 게이트로 승인합니다. 판정은 `COMPLETE`, `PARTIAL — SECTIONS <n>-<m>`,
  `NOT ASSESSED`입니다.

### `/ux-design`과 `/ux-review` — 핵심 화면

```text
/ux-design shell            # design/ux/app-shell.md — 내비게이션, 전역 영역, 전역 상태(인증·오프라인·점검·강제 업데이트)
/ux-design patterns         # design/ux/interaction-patterns.md — 폼 검증, 목록, 결제 시트, 본인인증, 권한 요청 등
/ux-design sign-in
/ux-design onboarding
/ux-design goal-create      # 핵심 흐름
/ux-design account-settings
/ux-review all
```

- 핵심 화면은 가입·로그인, 온보딩, 핵심 흐름, 설정·계정입니다. 명세마다 브레이크포인트(웹 `sm/md/lg`, 모바일
  compact/regular), 입력 방식(키보드·포인터·터치·스크린 리더), 라우트와 딥링크, 인증·권한 상태, 로딩·빈 상태·오류·
  오프라인 상태, `## API Data`(화면이 호출하는 오퍼레이션과 페이지네이션), 분석 이벤트가 들어갑니다.
- `/ux-review`의 판정은 `APPROVED`, `NEEDS REVISION`, `MAJOR REVISION NEEDED`, `NOT ASSESSED`이며, DD-UI-CONSISTENCY
  게이트가 디자인 언어와 패턴 라이브러리 준수를 봅니다.
- 명세가 외부 디자인을 선언하면(`> **Design Source**:`가 `claude-design`이나 `figma`) `/ux-review`가 다섯 번째 차원
  **Design Source Parity**로 핸드오프 기록과 대조합니다. `DRIFT FOUND`면 판정은 최대 `NEEDS REVISION`이고, 남긴
  스냅숏도 쓸 수 있는 도구도 없어 `NOT ASSESSED`면 `APPROVED`가 될 수 없습니다.

### `/design-handoff` — Claude Design·Figma에서 그린 화면 가져오기

화면을 디자인 도구에서 그린다면 `project.yaml`의 `design.tool`에 그 도구를 적습니다(`claude-design`, `figma`, `none`).
`/setup-stack`이 UI 표면을 고를 때 묻고, 나중에 `/settings`로 바꿀 수 있습니다. 설정하지 않은 상태는 `none`이 아니므로
스킬이 묻습니다. `none`이면 지금처럼 마크다운 UX 명세가 디자인 기록의 전부입니다.

`/design-handoff`는 외부 디자인을 `design/handoff/<slug>/`로 가져옵니다. `<slug>`는 그 디자인이 뒷받침하는 UX 명세의
slug(예: `goal-detail`)이고, 앱 셸은 `app-shell`, 토큰·컴포넌트 출처는 `design-system`, 브랜드 방향 탐색은
`brand-directions`입니다.

```text
design/handoff/goal-detail/
├── HANDOFF.md      # 기록: 도구, 출처 URL, 가져온 날짜, 뒷받침하는 UX 명세, 화면·상태, 토큰, 확인하지 못한 것
├── bundle/         # Claude Design 번들이나 디자인 아티팩트 파일 — 원본 그대로, 절대 고치지 않음
└── screens/        # 상태·브레이크포인트별 참조 이미지 (*.png, *.jpg, *.pdf)
```

가져오는 방법은 세 가지입니다.

| 방법 | 입력 | 세션에 필요한 것 | 없을 때 |
|---|---|---|---|
| **Claude Design 핸드오프 프롬프트 / zip 번들** | 내보내기 대화상자의 "Handoff to Claude Code"가 만든 프롬프트나 `https://claude.ai/design/p/<PROJECT_ID>?file=<FILE>.dc.html` URL, 또는 "Download zip instead"로 받은 번들(`.zip`이나 푼 디렉터리) | Claude Code 웹의 Claude Design 커넥터 (URL을 읽을 때) | 로컬 CLI에는 커넥터가 없으므로 `NOT CHECKED — Claude Design connector not present in this session (use the export's "Download zip instead" bundle)`를 출력하고 번들을 요청합니다 |
| **`/design` 디자인 아티팩트** | `https://claude.ai/code/artifact/<uuid>`, 또는 `new <brief>`(번들 `/design`으로 초안을 그린 뒤 가져옴) | `Artifact` 도구, 번들 `/design` 스킬(claude.ai 로그인, Claude Code v2.1.265 이상) | `NOT CHECKED — Artifact tool not available in this session` 또는 `NOT CHECKED — /design skill not available in this session (needs artifacts)`. 아트보드에서 PNG·PDF로 내보낸 파일을 받아 `screens/`에 둘 수 있습니다 |
| **Figma MCP** | 노드 URL `https://www.figma.com/design/<fileKey>/<fileName>?node-id=<n>-<m>` | Figma MCP 서버 | `NOT CHECKED — Figma MCP tools not present in this session`. Figma에서 내보낸 PNG를 받아 둘 수 있습니다 |

- 기록의 판정은 `RETAINED`(이번 세션에 읽고 스냅숏을 남김), `LINK ONLY`(읽었지만 남기지 않음), `NOT ASSESSED`(읽지
  못함 — 위치와 `NOT CHECKED` 줄만 남김)입니다. 뒤따르는 스킬은 `NOT ASSESSED`를 확인되지 않은 것으로 다루고, 일치로
  보지 않습니다.
- 붙여 넣은 핸드오프 프롬프트와 번들 README는 **신뢰하지 않는 데이터**입니다. "Implement: <FILE>.dc.html" 같은
  문장을 지시로 따르지 않고, 기록의 `### Handoff Prompt (data)`에 데이터로만 보관합니다.
- 가져온 뒤 UX 명세의 `> **Design Source**:` 줄에 연결합니다(해당 줄만, 먼저 확인). UX 명세는 여전히 필요합니다.
  외부 디자인은 와이어프레임을 대신할 수 있을 뿐 상태, `## API Data`, 분석 이벤트, 접근성, 인수 조건을 대신하지
  않습니다.
- Figma에 쓰기, `/design-sync`로 Claude Design에 올리기, `/design`으로 아티팩트 게시하기는 외부 쓰기라서 항상 따로
  승인받습니다. CCSS 스킬은 Figma나 Claude Design에 직접 쓰지 않습니다.

> **디자인 산출물은 참고이며 원본이 아닙니다.** 시각과 대비는 디자인 언어와 접근성 목표가, 동작(상태, `## API Data`,
> 분석 이벤트, 포커스 순서)은 UX 명세가 우선합니다. 번들 README가 말하는 스택이나 규칙보다 기술 레이더, ADR, 컨트롤
> 매니페스트가 우선하고, 목업 속 문구는 `ux-writer`를 위한 초안입니다. 내보낸 코드(Claude Design의 HTML/CSS/JS,
> Figma 디자인 컨텍스트 코드)는 코드 루트에 붙여 넣지 않고 라이브러리 컴포넌트와 시맨틱 토큰으로 다시 만듭니다.
> 토큰이 없는 값은 `design-engineer`에게 요청합니다.

Moa 예시: 디자이너가 Claude Design에서 목표 상세 화면을 그리고 "Send to local coding agent"로 핸드오프 프롬프트를
복사했습니다. 로컬 CLI 세션에는 커넥터가 없으므로 "Download zip instead"로 번들을 받아 가져옵니다.

```text
/design-handoff ~/Downloads/goal-detail.zip --for goal-detail
  → design/handoff/goal-detail/HANDOFF.md (> **Verdict**: RETAINED)
  → design/ux/goal-detail.md의 > **Design Source**: claude-design — https://claude.ai/design/p/<PROJECT_ID>?file=GoalDetail.dc.html · record `design/handoff/goal-detail/HANDOFF.md`
/ux-design goal-detail      # 상태, API Data, 이벤트를 명세에 씀 (와이어프레임은 기록의 screens/를 인용)
/ux-review design/ux/goal-detail.md   # Design Source Parity: MATCHES | DRIFT FOUND | NOT ASSESSED
```

디자인이 바뀌면 `/design-handoff refresh goal-detail`로 다시 가져옵니다. 기록이 명세의 마지막 `/ux-review` 기록보다
나중에 가져온 것이면 그 리뷰는 낡은 것으로 보고 다시 검토합니다.

### `/usability-report`와 `/api-design reconcile`

- 클릭 가능한 프로토타입이나 워킹 스켈레톤으로 대상 사용자 3–5명에게 핵심 흐름을 테스트합니다. 보고서에는 참가자,
  과업별 성공률·소요 시간·오류 수·SEQ, 선택적으로 SUS, 심각도(`Critical`, `Serious`, `Minor`, `Cosmetic`)별 이슈가
  들어가고, 판정은 `ACTIONABLE`, `INCONCLUSIVE`, `NOT ASSESSED`입니다.
- `/api-design reconcile`은 핵심 UX 명세의 `## API Data` 섹션을 읽고, 계약에 없거나 맞지 않는 오퍼레이션(응답 형태,
  페이지네이션, 화면용 집계·BFF 엔드포인트)을 찾아 변경안을 제안하고 변경 기록을 남깁니다. 바꿀 것이 없으면 "no
  change" 기록을 남깁니다. 에픽을 만들기 전에 실행하세요.

### `/create-control-manifest` — 컨트롤 매니페스트

`/create-control-manifest`는 채택된 ADR과 기술 레이더를 레이어별 "반드시·절대" 규칙표로 평평하게 정리합니다(full 필수,
standard 권장). ADR 채택이 끝난 뒤, 에픽과 스토리를 만들기 전에 실행하세요. 스토리에 매니페스트 날짜가 찍혀 규칙이
낡았는지 알 수 있습니다. TD-MANIFEST 게이트가 붙습니다.

### `/create-epics`와 `/create-stories`

```text
/create-epics layer: foundation
/create-stories identity-auth
/create-epics layer: core
/create-stories goals-core
```

- `/create-epics`는 PRD, ADR, 아키텍처, API 계약을 읽어 아키텍처 모듈마다 에픽 하나를 만듭니다. 에픽에는 비기능 표,
  API 오퍼레이션, 소유 엔터티, 롤아웃·플래그 계획, 스택 위험이 들어가고, DM-EPIC 게이트가 크기와 순서를 봅니다.
- `/create-stories`는 에픽 하나를 구현 가능한 스토리 파일로 나눕니다(예:
  `production/epics/goals-core/story-001-create-goal.md`). 스토리 헤더에는 `> **Layer**:`, `> **Type**:`(`Logic`,
  `Integration`, `UI`, `E2E`, `Config`), `> **Surface**:`(`web`, `ios`, `android`, `mobile`, `api`, `admin`, `infra`,
  `analytics` — 쉼표로 여러 개, 첫 값이 주 표면)가, 본문 필드에는 `**PRD**`, `**Requirement**`(TR-ID),
  `**ADR Governing Implementation**`, `**API Contract**`, `**Migration**`, `**Feature Flag**`(예:
  `goals.v2-progress-ring`), `**Analytics Events**`가 들어갑니다.
- 근거가 되는 ADR이 아직 `Proposed`면 스토리는 `Blocked` 상태로 만들어집니다. QL-STORY-READY 게이트가 인수 조건의
  검증 가능성을 봅니다.
- `minimal`에서는 `/create-epics`가 경로에 없습니다. `/create-stories`를 인자 없이 실행하면 one-pager의
  `## Build Order`에서 에픽을 합성해 바로 스토리로 나눕니다(`EPIC.md`는 만들지 않습니다).

### `/sprint-plan` — 첫 스프린트

```text
/sprint-plan new
```

`delivery-manager`와 함께 스프린트 목표와 가용 시간을 정하고, 준비된 스토리를 Must / Should / Nice로 나누고, 위험과
막힌 점을 찾습니다. `production/sprints/sprint-01.md`와 기계가 읽는 `production/sprint-status.yaml`(상태:
`backlog`, `ready-for-dev`, `in-progress`, `review`, `done`, `blocked`)을 만들고, DM-SPRINT 게이트가 실현 가능성을
봅니다. 필요하면 `production/risk-register/`에 위험 항목을 추가하자고 제안합니다.

### `/walking-skeleton` — 끝에서 끝까지, 스테이징에서

```text
/walking-skeleton sign-up-to-first-goal
```

워킹 스켈레톤은 프로토타입이 아니라 **실제 코드**입니다. `docs/ops/slo.md`의 핵심 여정(또는 PRD) 하나를 골라,
설정된 모든 레이어를 가장 얇게 관통하는 구현을 기능 브랜치에 만들고 CI/CD로 스테이징에 배포합니다.

1. 여정 선택 → 레이어별 계획(`tech-lead`) → 담당 엔지니어가 구현
2. 파이프라인과 배포 — `devops-engineer`가 명령을 제안하고 **사람이** 실행합니다
3. 관측성 연결(`sre-engineer`) → 롤백 리허설 → 스테이징에서 플래그 전환(`platform-engineer`가 플래그 SDK 연결)
4. 검증 체크리스트:
   1. CI/CD 파이프라인으로 스테이징에 배포되었다 (손으로 배포하지 않음)
   2. 핵심 여정 하나가 스테이징에서 UI → API → DB까지 끝에서 끝까지 통과한다
   3. 헬스 엔드포인트, 로그, 그리고 지표나 트레이스가 최소 하나 관측성 도구에 보인다
   4. 스테이징 배포를 한 번 롤백하고 다시 배포하는 데 성공했다
   5. 재배포 없이 스테이징에서 기능 플래그를 전환했다 (standard·full만, minimal은 N/A)
5. 선택: 스켈레톤으로 사용성 세션을 하면 PD-USER-VALIDATION 게이트가 붙습니다.

판정은 `VALIDATED`(해당 항목 모두 YES), `NOT VALIDATED`(하나라도 NO), `NOT ASSESSED`입니다.

### 게이트: `/gate-check build` (Validation → Build)

| 확인 항목 | full | standard | minimal |
|---|---|---|---|
| 첫 스프린트 계획 | 필수 | 필수 | — |
| Foundation·Core 레이어 에픽과 각 에픽의 스토리 | 필수 | 필수 | — |
| Foundation·Core ADR이 모두 `Accepted` | 필수 | 필수 | — |
| 컨트롤 매니페스트 | 필수 | 권장 | — |
| 디자인 언어 (full: 9개 섹션, standard: 1–5번) (UI) | 필수 | 필수 | — |
| 가입·로그인, 온보딩, 핵심 흐름, 설정·계정 UX 명세 (UI) | 필수 | 필수 | — |
| 앱 셸과 인터랙션 패턴 (UI) | 필수 | 필수 | — |
| 핵심 화면 명세마다 `APPROVED`(또는 수용된 `NEEDS REVISION`) UX 검토 기록 (UI) | 필수 | 필수 | — |
| 외부 디자인을 선언한 명세마다 `design/handoff/<slug>/HANDOFF.md`가 있고, 승인된 UX 검토 뒤에 다시 가져온 것이 아님 (UI) | 필수 | 권장 | — |
| 워킹 스켈레톤 보고서 | 필수 | 필수 | — (만들었다면 아래 검증 규칙 적용) |
| 핵심 흐름 사용성 세션 1회 이상 | 권장 | 권장 | — |
| API 계약이 핵심 UX 명세와 조정됨 (백엔드 + UI) | 필수 | 권장 | — |
| one-pager의 `## Build Order`에 항목이 하나 이상 | — | — | 필수 |
| UX 명세가 MVP PRD의 UI 요구를 모두 다루고 접근성 목표를 반영 (UI) | 필수 | 필수 | — |
| 스프린트 계획이 실제 스토리 경로를 가리키고, 스토리에 TR-ID·ADR·API 계약·마이그레이션·플래그 필드가 있음 | 필수 | 필수 | — |
| UX 명세의 `## API Data`에 나온 오퍼레이션이 계약에 모두 있음 (백엔드 + UI) | 필수 | 권장 | — |
| DD-DESIGN-LANGUAGE 결과가 디자인 언어 문서에 기록됨 (UI) | 필수 | 필수 | — |
| PRD·아키텍처·API·에픽이 서로 맞는지 수동 확인 | 필수 | 필수 | — |

> **외부 디자인은 UX 명세를 대신하지 않습니다.** Claude Design·Figma·`/design`으로 그렸어도 UX 명세 파일은 필요합니다.
> 게이트는 MCP나 커넥터 도구를 부르지 않고 저장소에 남은 기록만 봅니다. 기록이 `LINK ONLY`나 `NOT ASSESSED`면 이
> 항목은 `NOT CHECKED — external design not retained (<url>)`이고, 결코 `PASS`가 아닙니다.

> **워킹 스켈레톤 판정 규칙**: 스켈레톤을 만들었는데 해당 검증 항목 중 하나라도 NO면 **모든 티어에서 `FAIL`**입니다.
> 만들지 않았다면 standard·full에서는 필수 산출물 누락이고, minimal에서는 요구되지 않습니다. 티어는 무엇이 있어야
> 하는지를 완화할 뿐, 무엇이 동작해야 하는지는 완화하지 않습니다.

---

## 5단계 Build: 구축

### 이 단계에서 하는 일

핵심 개발 루프입니다. 보통 1–2주 스프린트로 스토리를 하나씩 구현하고, 진행을 추적하고, 구조화된 완료 검토로 스토리를
닫습니다. MVP 기능이 모두 구현될 때까지 반복합니다.

```text
/sprint-plan ─→ /story-readiness ─→ /dev-story ─→ /code-review ─→ /story-done ─→ 다음 스토리
                                                                        │
                   /smoke-check (QA 인계 전)  →  /qa-plan · /team-qa  →  /retrospective (스프린트 끝)
   수시로: /sprint-status · /scope-check · /bug-report · /bug-triage · /propagate-prd-change
```

| 스텝 | 명령 | 필수 여부 | 산출물 |
|---|---|---|---|
| 스프린트 계획 | `/sprint-plan` | 필수 (standard·full), 반복 | `production/sprints/sprint-*.md` |
| 스토리 준비 점검 | `/story-readiness` | 선택, 반복 | (보고) |
| 스토리 구현 | `/dev-story` | 필수 (standard·full), 반복 | `production/sprint-status.yaml`의 `in-progress` 이상 |
| 코드 리뷰 | `/code-review` | 선택, 반복 | (대화 속 보고) |
| 스토리 완료 검토 | `/story-done` | 필수 (standard·full), 반복 | `production/sprint-status.yaml`의 `done` |
| 스모크 체크 | `/smoke-check` | 필수, 반복 | `production/qa/smoke-*.md` |
| QA 계획 | `/qa-plan` | 선택, 반복 | `production/qa/qa-plan-*.md` |
| 버그 보고·분류 | `/bug-report`, `/bug-triage` | 선택, 반복 | `production/qa/bugs/BUG-NNNN.md` |
| 새·변경 화면 UX 명세 | `/ux-design` | 선택, 반복 | `design/ux/*.md` |
| 바뀐 외부 디자인 다시 가져오기 | `/design-handoff refresh <slug>` | 선택, 반복 | `design/handoff/*/HANDOFF.md` |
| 스프린트 회고 | `/retrospective` | 선택, 반복 | `production/retrospectives/retro-*.md` |
| 팀 오케스트레이션 | `/team-feature`, `/team-ui`, `/team-content`, `/team-qa` | 선택, 반복 | 스킬별 |
| 범위 점검 | `/scope-check` | 선택, 반복 | (보고) |
| 스프린트 현황 | `/sprint-status` | 선택, 반복 | (보고) |

`minimal`에는 스프린트 계획이 없습니다. one-pager의 `## Build Order`가 계획입니다. 스모크 체크는 모든 티어에서 필수인
최저선입니다.

### 스토리 수명주기

**1. 준비 점검** — `/story-readiness production/epics/goals-core/story-001-create-goal.md`

설계 완결성, 근거 ADR의 상태(`Proposed`면 막힘), 매니페스트 버전(낡았으면 경고), `**API Contract**`·`**Migration**`·
`**Feature Flag**`·`**Surface**` 필드, 비기능 예산, 디자인 링크(`design.tool`이 `claude-design`·`figma`면 UI·E2E
스토리의 `Design reference:` 줄과 판정이 `NOT ASSESSED`가 아닌 핸드오프 기록까지), 분석 이벤트를 봅니다. 판정은 `READY`, `NEEDS WORK`,
`BLOCKED`, `NOT ASSESSED`입니다.

**2. 구현** — `/dev-story production/epics/goals-core/story-001-create-goal.md`

스토리를 읽고 ADR 지침, API 계약, 컨트롤 매니페스트를 확인한 뒤, 스토리의 `Surface`와 `Type`으로 담당 엔지니어와 스택
스페셜리스트를 고릅니다.

UI·E2E 스토리에는 `/create-stories`가 UX 명세의 `> **Design Source**:`에서 옮긴 `- Design reference:` 줄이 있습니다.
`/dev-story`와 `/team-ui`, `/team-feature`는 메인 세션에서 이 참조를 핸드오프 기록(`design/handoff/<slug>/HANDOFF.md`)으로
풀고, 엔지니어에게는 기록과 `screens/`의 로컬 경로, 그리고 "디자인 산출물은 참고이며 UX 명세·디자인 언어가 우선"이라는
우선순위 원칙을 넘깁니다. 서브에이전트는 Figma MCP나 Claude Design 커넥터에 닿을 수 없기 때문입니다. 참조에 닿을 수
없으면 `Design reference: NOT CHECKED — <reason>`을 출력합니다. 구현 뒤 캡처를 참조 화면과 비교한 결과는 권고
관찰로만 남고, 참조 이미지는 스토리 증거로 인정되지 않습니다.

| 스토리 | 주 담당 | 보조 |
|---|---|---|
| Type `Config`, 코드 없음 (플래그, 환경 설정, 가격표) | 없음 — 설정 경로로 처리 | — |
| Type `Config` + DB 마이그레이션 | `backend-engineer` | `data-specialist` |
| Surface `infra` | `devops-engineer` | `cloud-specialist` |
| Surface `analytics` (파이프라인, 웨어하우스, 지표 레이어) | `data-engineer` | `analytics-engineer` |
| Surface `admin` | `internal-tools-engineer` | 웹 스택 스페셜리스트 |
| ML·LLM 기능 (`**ML**: yes` 또는 ADR Domain `ML`) | `ml-engineer` | 백엔드 스택 스페셜리스트 |
| Surface `web` | `frontend-engineer` | 웹 스택 스페셜리스트 (+ 공용 루트면 `platform-engineer`) |
| Surface `ios`, `android`, `mobile` | `mobile-engineer` | 모바일 스택 스페셜리스트 (+ 공용 루트면 `platform-engineer`) |
| Surface `api` + Foundation 레이어 또는 공용 루트 | `platform-engineer` | 백엔드 스택 스페셜리스트 |
| Surface `api` | `backend-engineer` | 백엔드 스택 스페셜리스트 |

스토리의 위험도가 HIGH면 하위 스페셜리스트 대신 레이어 리드를 부릅니다. 위험도는 스토리 카드의 `**Risk**`가 아니라
`docs/stack-reference/VERSION.md`에서 주 표면을 구현하는 구성 요소 행의 Knowledge Risk로 정하며, 행이 없거나
`NOT DETERMINED`이면 HIGH로 봅니다. 코드 루트를 결정할 수 없으면 코드를 쓰지 않고
`NOT CHECKED — no code root resolved (set stack.layers.<layer>.root via /setup-stack)`를 출력합니다.

구현이 끝나면 **실행해서 관찰합니다**. 타입체크나 빌드는 실행이 아닙니다.

- **web** — `commands.run`(또는 `commands.dev`)으로 띄운 뒤 캡처 스크립트로 데스크톱·모바일 스크린숏을 남깁니다.
- **ios** — `xcrun simctl openurl booted <딥링크>` 후 `xcrun simctl io booted screenshot <파일>`
- **android** — `adb shell am start -W -a android.intent.action.VIEW -d <딥링크>` 후 `adb exec-out screencap -p`
- **api** — 로컬·스테이징 서버에 오퍼레이션을 호출하고 요청·응답 스냅숏을 저장합니다(개인정보와 토큰은 가림).

증거는 `production/qa/evidence/<story-slug>/`에 남고, 결과는 `Run result: OBSERVED | NOT VERIFIED | N/A` 줄로
기록합니다. 스토리 상태는 `production/sprint-status.yaml`에서 `in-progress`로 바뀝니다.

**3. 코드 리뷰** — `/code-review`

인가, 입력 검증, N+1 쿼리, 트랜잭션, 멱등성, 타임아웃, 페이지네이션, 로그 속 개인정보 같은 서비스 관점의 아키텍처
리뷰입니다. 인증·개인정보 코드를 건드리면 `security-engineer`가 함께 봅니다.

**4. 완료 검토** — `/story-done production/epics/goals-core/story-001-create-goal.md`

1. 스토리와 근거 PRD·ADR·API 계약·매니페스트를 읽습니다.
2. 인수 조건을 확인합니다(자동 확인, 수동 확인, 연기).
3. 스토리 유형별 증거를 확인합니다(아래 표).
4. PRD·ADR·API 계약과 어긋난 점을 찾습니다(차단 / 권고 / 범위 밖).
5. 마이그레이션 계획의 단계, 플래그 기본값 기록, 새 로그 문장의 개인정보, 트래킹 플랜의 이벤트를 확인합니다.
6. 코드 리뷰: `review_mode: full`에서는 TL-CODE-REVIEW 게이트, 리뷰 모드가 이를 건너뛰면 `/code-review` 체크리스트를 직접 돌리고
   `Code review: inline checklist (TL-CODE-REVIEW skipped — <Mode> mode)`를 기록합니다.
7. QL-TEST-COVERAGE 게이트로 테스트 커버리지를 봅니다.
8. 판정 `COMPLETE`, `COMPLETE WITH NOTES`, `NOT ASSESSED`, `BLOCKED`를 내리고, 완료면 상태를 `done`으로 바꾸고 다음
   준비된 스토리를 보여 줍니다.

작업 중 발견한 기술 부채는 `docs/tech-debt-register.md`에 남깁니다.

### 스토리 유형별 증거

| 유형 | 다루는 것 | 필요한 증거 | 기본 게이트 수준 | `testing.strict` 키 |
|---|---|---|---|---|
| **Logic** | 도메인 규칙, 계산, 검증기, 상태 머신 | 자동화된 단위 테스트 통과 | 차단 | `testing.strict.logic` |
| **Integration** | API 핸들러 + DB, 큐 소비자, 외부 어댑터, `docs/api/` 대상 **계약 테스트** | 통합 또는 계약 테스트 통과 | 차단 | `testing.strict.integration` |
| **UI** | 화면, 컴포넌트, 시각 상태(시각 회귀 포함) | 컴포넌트 테스트 또는 변경한 상태마다 보관된 스크린숏(데스크톱 + 모바일 뷰포트, 또는 기기) | 차단 | `testing.strict.ui` |
| **E2E** | UI → API → DB를 잇는 핵심 사용자 여정 | 실행 중인 환경에서 통과한 E2E 테스트(Playwright, Cypress, Detox, Maestro)와 트레이스·스크린숏 | 차단 | `testing.strict.e2e` |
| **Config** | 기능 플래그, 환경 설정, 가격·한도 표 | 스모크 체크 통과 | 권고 (`/smoke-check`에서는 설정이 없으면 차단) | `testing.strict.config` |

- **마이그레이션 최저선** — `**Migration**`이 `None`이 아닌 스토리는 유형과 관계없이
  `production/qa/evidence/<story-slug>/migration-dry-run.log`(일회용 DB에 Expand를 적용했다가 되돌린 기록)가 있어야
  합니다. 모든 `qa.level`에서, `testing.strict.config`와 관계없이 적용됩니다.
- 증거는 gitignore되지 않은 경로에 보관되어 있어야 인정됩니다. `production/session-logs/`는 증거 위치가 아닙니다.

### 스모크 체크와 QA

- `/smoke-check`는 QA에 넘기기 전의 핵심 경로 점검입니다. 1) 빌드와 기동(헬스 엔드포인트 200), 2) 핵심 여정(로그인,
  핵심 흐름), 3) 연동(결제 샌드박스, 이메일·푸시 샌드박스, 일회용 DB의 마이그레이션), 4) 비기능 스팟 체크(p95, 오류율)
  순으로 확인하고, 어느 환경(스테이징 또는 로컬)에서 돌렸는지 보고서에 적습니다. 판정 우선순위는
  **FAIL > NOT ASSESSED > PASS WITH WARNINGS > PASS**이고, 스모크 보고서는 모든 티어의 최저선입니다.
- `/qa-plan`은 스프린트나 기능 단위 QA 계획을 `.claude/docs/templates/test-plan.md` 제목에 맞춰 씁니다.
- `/team-qa`는 전략 → 테스트 케이스 → 실행 → 버그 → 사인오프의 전체 QA 사이클을 돌립니다.
- `/bug-report`는 서비스 환경 정보(환경, 빌드, 브라우저·기기, 계정·플래그 상태)가 들어간 `BUG-NNNN.md`를 씁니다.
  심각도는 `S1-Critical` / `S2-Major` / `S3-Minor` / `S4-Trivial`, 우선순위는 `P1-Fix this sprint` /
  `P2-Fix soon` / `P3-Backlog` / `P4-Won't fix`입니다. `/bug-triage`는 미해결 버그를 다시 분류하고 스프린트에
  배정합니다.
- `/regression-suite`, `/test-evidence-review`, `/test-flakiness`로 회귀 테스트 공백, 증거의 질, 불안정한 테스트를
  점검합니다.

### 여러 역할이 함께하는 기능: 팀 스킬

```text
/team-feature goals                      # 기능 slug 또는 design/prd/goals.md
/team-ui "계정 설정 화면 개편"
/team-content notifications              # 영역, voice, help-center <slug>
/team-qa sprint
```

팀 스킬은 여러 에이전트를 한 작업에 묶어 단계별로 진행하고, 결정 지점마다 사용자에게 묻습니다. 참여 인원은
`team.size`(`individual` / `small` / `studio`)에 따라 달라지고, 시작할 때 이번에 참여하는 에이전트를 먼저 알려 줍니다.
예를 들어 `/team-feature`는 1) 정의(PRD와 인수 조건 확인) → 2) UX 변경(`product-designer`, 화면 변경이 없으면 생략) →
3) 계약(API·데이터 변경) → 4) 표면별 병렬 구현 → 5) 통합(계약 테스트 + E2E) → 6) 검증(`qa-engineer`) → 7) 사인오프
순서로 진행합니다. 팀 크기를 줄여도 디렉터 게이트가 사라지지는 않습니다.

### 진행 추적과 변경 관리

- `/sprint-status` — `production/sprint-status.yaml`을 읽어 30줄 정도의 빠른 현황을 보여 줍니다.
- `/scope-check` — 스프린트 중 스토리가 늘어나면 PRD의 `Goals & Non-Goals`와 one-pager 대비 범위 확장을 점검합니다.
- `/propagate-prd-change design/prd/goals.md` — 스토리가 만들어진 뒤 PRD가 바뀌면 영향을 받는 ADR, API 오퍼레이션,
  데이터 모델 엔터티, 트래킹 이벤트, 스토리를 찾아 영향 보고서를 씁니다(TD-CHANGE-IMPACT).
- `/retrospective sprint-3` — 계획 대비 완료, 속도, 막힌 점, 실행 가능한 개선점을 정리합니다.
- `/milestone-review private-beta` — 마일스톤(MVP / Private Beta / Public Beta / GA)의 기능 완성도, 품질·운영 지표,
  위험, go/no-go 권고(DM-MILESTONE)를 냅니다.
- `/tech-debt` — 보안·인프라·관측성을 포함한 범주로 기술 부채를 추적하고 우선순위를 매깁니다.

### 게이트: `/gate-check hardening` (Build → Hardening)

Hardening에 들어간다는 것은 기능 완성·코드 동결을 뜻합니다. QA 사인오프와 S2 버그 소진은 Hardening의 **종료**
조건이라 이 게이트가 아니라 `launch` 게이트에서 봅니다.

| 확인 항목 | full | standard | minimal |
|---|---|---|---|
| MVP 기능이 모두 구현됨 (`/feature-audit` 보고서로 충족 가능) | 필수 | 필수 | — |
| `testing.patterns` 기준 Logic·Integration(계약 포함)·E2E 스토리의 테스트 | 필수 | 권장 | — |
| 클라이언트가 쓰는 API 오퍼레이션마다 계약 테스트 (백엔드) | 필수 | 권장 | — |
| `docs/ops/slo.md`의 핵심 여정마다 E2E 테스트 | 필수 | 필수 | — |
| 스테이징 대상 스모크 체크 `PASS` 또는 `PASS WITH WARNINGS` (minimal은 스테이징이 없으면 로컬) — 모든 티어의 최저선 | 필수 | 필수 | 필수 |
| 이번 단계의 QA 계획 (없으면 `CONCERNS`) | 권장 | 권장 | — |
| 미해결 S1 버그 없음 | 필수 | 필수 | 필수 |
| 미해결 S2 버그마다 담당자와 목표일 | 필수 | 필수 | — |
| 모든 마이그레이션의 Expand가 스테이징에 적용되고 Contract가 일정에 잡힘 | 필수 | 필수 | — |
| 테스트 스위트 통과 (`commands.test`가 있으면 실행, 없으면 `NOT ASSESSED`) | 필수 | 필수 | — |
| `performance.*` 예산 이내 (`performance.enforce`: `block`이면 차단, `warn`이면 `CONCERNS`, `off`면 메모와 함께 생략) | 필수 | 필수 | — |
| SLO마다 대시보드와 알림 | 필수 | 권장 | — |
| 기능 플래그의 기본 상태가 기록됨 | 필수 | 필수 | — |
| 구현된 화면마다 UX 명세 (UI) | 필수 | 권장 | — |
| `accessibility.target` 대비 접근성 준수 확인 (UI) | 필수 | 권장 | — |

"미해결"은 `**Status**`가 `Open`, `In Progress`, `Fixed — Pending Verification` 중 하나인 버그를 말합니다.

---

## 6단계 Hardening: 안정화

### 이 단계에서 하는 일

기능은 다 만들었습니다. 이제 출시할 수 있는 상태로 다듬습니다. 한국 조직에서 "안정화" 또는 베타 기간이라고 부르는
단계로, 성능·부하·보안·접근성·사용성을 점검하고 QA 사인오프를 받고, 운영에 필요한 런북과 릴리스 문서를 준비합니다.

```text
/team-hardening ─→ production/qa/hardening-YYYY-MM-DD.md (성능·신뢰성·보안·접근성·UI 일관성·회귀)
/perf-profile · /bundle-audit · /load-test · /security-audit full · /usability-report (×N)
/business-rules-check · /feature-audit · /team-qa (사인오프)
/incident runbook <alert-slug> (호출 알림마다) · /localize qa (다국어)
/changelog <version> → /release-notes → /smoke-check (릴리스 후보, PASS) → /release-checklist → /rollout-plan → /launch-checklist
        │
        ▼
/gate-check launch
```

| 스텝 | 명령 | 필수 여부 | 산출물 |
|---|---|---|---|
| 안정화 팀 패스 | `/team-hardening` | 필수 (standard·full) | `production/qa/hardening-*.md` |
| 성능 프로파일 | `/perf-profile` | 선택, 반복 | `production/qa/perf/perf-profile-*.md` |
| 번들·에셋 감사 | `/bundle-audit` | 선택 | `production/qa/perf/bundle-audit-*.md` |
| 부하 테스트 | `/load-test` | 필수 (full), standard는 권장 | `production/qa/load/load-test-*.md` |
| 보안·개인정보 감사 | `/security-audit` | 필수 | `production/security/security-audit-full-*.md` 또는 `…-quick-*.md` |
| 사용성·베타 세션 | `/usability-report` | 필수 (standard·full), 반복 | `production/qa/usability/*.md` |
| 비즈니스 규칙 점검 | `/business-rules-check` | 선택 | `production/qa/business-rules/business-rules-check-*.md` |
| 기능 감사 | `/feature-audit` | 선택 | `production/qa/feature-audit-*.md` |
| QA 사이클과 사인오프 | `/team-qa` | 필수 (standard·full) | `production/qa/qa-signoff-*.md` |
| 런북 | `/incident runbook` | 필수 (standard·full), 반복 | `docs/ops/runbooks/*.md` |
| 현지화 QA | `/localize qa` | 필수 (standard·full, 다국어) | `production/qa/localization-qa-*.md` |
| 변경 이력 | `/changelog <version>` | 필수 (standard·full), 반복 | `docs/CHANGELOG.md`의 `## [<version>]` 섹션 |
| 릴리스 노트 초안 | `/release-notes` | 필수 (standard·full), 반복 | `production/releases/*/release-notes.md` |
| 릴리스 후보 스모크 체크 | `/smoke-check` | 필수, 반복 (`PASS`만 인정) | `production/qa/smoke-*.md` |
| 릴리스 체크리스트 | `/release-checklist` | 필수, 반복 | `production/releases/*/release-checklist.md` |
| 롤아웃 계획 | `/rollout-plan` | 필수 (standard·full), 반복 | `production/releases/*/rollout-plan.md` |
| 출시 체크리스트 | `/launch-checklist` | 필수 (standard·full) | `production/releases/*/launch-checklist.md` |

### 성능, 번들, 부하

- `/perf-profile [surface:<web|ios|android|api> | route:<path> | full]` — `project.yaml`의 예산과 측정값을 비교합니다.
  예산 키는 `performance.api_p95_ms`, `performance.error_rate_pct`, `performance.availability_pct`,
  `performance.lcp_ms`, `performance.inp_ms`, `performance.cls`, `performance.bundle_kb`,
  `performance.cold_start_ms`, `performance.crash_free_pct`입니다. 보고서는 `## Scope`, `## Budgets`,
  `## Measurements`, `## Breaches`, `## Ranked Recommendations`로 구성됩니다.
- `/bundle-audit` — 라우트별 JS·CSS, 이미지, 글꼴(한국어 글꼴 서브셋 포함), 모바일 앱 크기를 예산과 비교합니다.
- `/load-test [smoke|load|stress|spike|soak]` — 스택에 맞는 도구(JS는 k6, Python은 Locust, JVM은 Gatling)로
  `tests/load/`에 스크립트를 만들고, **스테이징**을 대상으로 실행합니다. 운영 환경 대상 요청은 거절합니다.
  `commands.load_test`가 설정되어 있고 사용자가 확인했을 때만 실행하며, 그렇지 않으면 프로토콜과 빈 결과표를 남기고
  `NOT ASSESSED`로 판정합니다.
- 세 스킬 모두 `performance.enforce`(`warn` / `block` / `off`)에 따라 예산 초과를 `CONCERNS`로 볼지 `FAIL`로 볼지
  정합니다.

### 보안·개인정보 감사

```text
/security-audit full
/security-audit quick      # 시크릿 + 의존성 취약점 + 보안 헤더만
/security-audit privacy    # 개인정보 인벤토리, 동의, 보관, 삭제, 국외 이전
```

`full`은 OWASP Top 10, OWASP API Security Top 10, MASVS(모바일 표면이 있을 때), 시크릿과 보안 헤더(CSP, HSTS),
의존성 CVE·SBOM·라이선스, IaC 설정 오류, 인증·인가(BOLA/IDOR), 개인정보(마케팅 수신 동의 포함), 그리고
`compliance.regions`의 지역 체크리스트를 봅니다. 발견 사항은 `Critical` / `High` / `Medium` / `Low`, 판정은 `PASS`,
`CONCERNS`, `FAIL`, `NOT ASSESSED`입니다. standard·full의 게이트는 `full` 모드 보고서를 요구하고, minimal은 `quick`으로
충분합니다. 시크릿이나 개인정보 샘플을 읽을 때는 항상 먼저 묻습니다.

### 사용성·베타, 비즈니스 규칙, 기능 감사

- `/usability-report` — 첫 실행, 핵심 여정, 재방문 사용을 다루는 세션(또는 베타 결과)을 기록합니다. full은 3회,
  standard는 1회 이상이 필요합니다. `--type beta`는 크래시 없는 세션 비율, 활성화, D1·D7 리텐션, NPS·CSAT을 더합니다.
- `/business-rules-check` — PRD의 `Business Rules & Calculations`, 가격 모델, 레지스트리를 읽고 반올림과 통화(원화는
  소수 단위가 없음), 부가세 포함 여부, 프로모션 중복 적용, 무료 요금제 악용, 환불·해지 규칙을 봅니다.
- `/feature-audit` — PRD 요구사항, 화면, 엔드포인트, 이벤트, 플래그, 알림 템플릿, 로케일 기준으로 계획 대비 구현을
  비교합니다. 판정은 `COMPLETE`, `GAPS`, `NOT ASSESSED`입니다.

### 안정화 팀 패스와 QA 사인오프

- `/team-hardening`은 `team.size`가 `small`이면 `performance-engineer`, `sre-engineer`, `security-engineer`(quick
  감사), `accessibility-specialist`를 병렬로 돌린 뒤 `qa-engineer`가 회귀를 확인합니다(`studio`는 `design-engineer`와
  스택 리드가 더해지고, `individual`은 `performance-engineer` 혼자 진행합니다). 결과는 하나의 보고서에
  `## Performance`, `## Reliability`, `## Security (quick)`, `## Accessibility`, `## UI Consistency`, `## Regression`,
  `## Blockers`로 남고, 판정은 `READY`, `READY WITH CONDITIONS`, `NOT READY`, `NOT ASSESSED`입니다.
- `/team-qa`의 사인오프 판정은 `APPROVED`, `APPROVED WITH CONDITIONS`, `NOT APPROVED`, `NOT ASSESSED`입니다. 사용할 수
  있는 스모크 보고서가 없으면 승인할 수 없습니다.

### 런북과 현지화 QA

- `docs/ops/slo.md`의 `## Dashboards & Alerts`에 적힌 **호출(paging) 알림마다** `/incident runbook <alert-slug>`로
  런북을 씁니다. 런북은 `## Alert`, `## Impact`, `## Diagnosis`, `## Mitigation`, `## Escalation`, `## Verification`,
  `## Related`로 구성됩니다.
- 로케일이 둘 이상이면 `/localize qa`로 현지화 QA 보고서를 씁니다. 하드코딩 문자열, ICU 메시지, 문자열 확장,
  한중일 조판, 문화 검토를 봅니다.

### 릴리스 준비: 변경 이력 → 노트 → 스모크 → 체크리스트 → 롤아웃 계획 → 출시 체크리스트

```text
/changelog 1.0.0
/release-notes 1.0.0
/smoke-check          # 릴리스 후보 빌드
/release-checklist 1.0.0
/rollout-plan 1.0.0
/launch-checklist 1.0.0
```

- **`/changelog <version>`** — `docs/CHANGELOG.md`에 그 버전의 `## [<version>]` 섹션을 씁니다. `/release-notes`는 이
  섹션에서 문구를 만들고, 섹션이 없으면 `BLOCKED`로 멈춥니다.
- **`/release-notes`** — `/changelog`가 쓴 `docs/CHANGELOG.md`의 해당 버전 섹션을 읽어 채널별 고객용 문구를 씁니다:
  `## In-App / Web`, `## App Store`(4000자 이내), `## Google Play`(언어별 500자 이내), 외부 API가 있으면
  `## API / Developers`. 로케일마다 한 블록씩 씁니다.
- **`/smoke-check`** (릴리스 후보) — 릴리스 체크리스트 전에 릴리스 후보 빌드를 스모크합니다. Hardening → Launch
  게이트는 모든 티어에서 `PASS`만 인정하며 `PASS WITH WARNINGS`로는 충족되지 않습니다. 보고서의
  **Build under test** 줄로 어느 빌드를 점검했는지 확인하세요.
- **`/release-checklist`** — 빌드와 CI 산출물, DB 마이그레이션(단계별 상태), 기능 플래그 기본값, 환경 설정과 시크릿,
  관측성(SLO별 대시보드·알림), **롤백 경로(모든 티어 필수)**, 웹 블록(CDN·캐시 무효화, SEO·메타, 쿠키 동의), 스토어
  블록(빌드 번호, 서명, 개인정보 라벨·Data safety, 심사 지침, TestFlight·내부 트랙, 단계적 출시), 지역 블록,
  현지화, 릴리스 노트를 확인합니다. `release.distribution`이 비어 있으면 모든 트랙을 나열하지 않고 먼저 묻습니다.
  판정은 `GO`, `NO-GO`, `NOT ASSESSED`입니다.
- **`/rollout-plan`** — 점진적 배포 계획입니다. `## Scope`, `## Strategy per Surface`(웹·API는 플래그 비율 단계와
  카나리 체류 시간, 모바일은 App Store 단계적 출시·Play 단계적 출시 비율, 최소 지원 버전과 강제 업데이트 정책,
  서버 호환 기간), `## Migration Ordering`(배포 전 Expand, 배포 후 Contract),
  `## Guardrail Metrics & Halt Thresholds`(오류율, p95, 크래시 없는 세션 비율, 비즈니스 지표 하나와 자동 중단 조건),
  `## Rollback Plan`(단계별 — 모바일 바이너리는 되돌릴 수 없으므로 서버 플래그·킬 스위치와 긴급 심사),
  `## Communication Plan`, `## Go/No-Go per Stage`, `## Production Readiness Review`로 구성됩니다.
  SR-PRODUCTION-READINESS 게이트는 **리뷰 모드와 관계없이 항상** 실행됩니다. 판정은 `READY TO ROLL OUT`, `NOT READY`,
  `NOT ASSESSED`입니다.
- **`/launch-checklist`** — 첫 공개 출시(와 대규모 출시)의 부서별 준비 상태입니다. `## Product`,
  `## Engineering & SRE`(부하 테스트, 용량, SLO, 런북, 온콜, 백업·복구 — `sre-engineer` 자문), `## Security & Privacy`
  (감사, 이용약관, 개인정보 처리방침, 동의 — `security-engineer` 자문), `## Legal`(지역별 전자상거래 표시 의무, 오픈소스
  라이선스), `## Support`(도움말 센터, 매크로, 상태 페이지), `## Go-to-Market`(스토어 등록 정보·ASO, 출시 커뮤니케이션),
  `## Analytics`(트래킹 플랜 대비 이벤트 검증), `## Sign-offs`. 판정은 `GO`, `NO-GO`, `NOT ASSESSED`이며,
  `/launch-checklist 1.0.0 dry-run`으로 미리 점검할 수 있습니다.

### 게이트: `/gate-check launch` (Hardening → Launch)

| 확인 항목 | full | standard | minimal |
|---|---|---|---|
| 롤백 섹션을 포함하고 판정이 `GO`인 릴리스 체크리스트 | 필수 | 필수 | 필수 |
| 판정이 `READY TO ROLL OUT`이고 SR-PRODUCTION-READINESS 결과가 기록된 롤아웃 계획 | 필수 | 필수 | — |
| 판정이 `GO`인 출시 체크리스트 (첫 공개 출시, 이후 릴리스는 생략) | 필수 | 필수 | — |
| `full` 모드 보안 감사, 미해결 Critical·High 없음 | 필수 | 필수 | — |
| `quick`(또는 `full`) 보안 감사, 미해결 Critical 없음 | — | — | 필수 |
| 릴리스 후보 빌드의 스모크 체크 `PASS` | 필수 | 필수 | 필수 |
| QA 사인오프 `APPROVED` 또는 `APPROVED WITH CONDITIONS` | 필수 | 필수 | — |
| 판정이 `READY` 또는 `READY WITH CONDITIONS`인 안정화 보고서 | 필수 | 필수 | — |
| 기준을 충족한 부하 테스트 보고서 | 필수 | 권장 | — |
| 사용성·베타 세션 (full 3회 이상, standard 1회 이상) | 필수 | 필수 | — |
| 호출 알림마다 런북, `docs/ops/slo.md`의 `## On-call`에 온콜 로테이션 | 필수 | 필수 | — |
| 이용약관과 개인정보 처리방침 게시 (링크는 출시 체크리스트에 기록) | 필수 | 필수 | — |
| 스토어 제출 기록 — 개인정보 라벨·Data safety, 심사 지침 확인, 단계적 출시 설정 (스토어 배포 시) | 필수 | 필수 | — |
| 지역별 컴플라이언스 체크리스트 항목이 해결 또는 명시적으로 수용됨 (Regions) | 필수 | 필수 | — |
| 현지화 QA 보고서 (다국어) | 필수 | 필수 | — |
| 릴리스 노트 초안 (`/changelog <version>`이 쓴 `docs/CHANGELOG.md` 섹션을 바탕으로 `/release-notes`가 작성) | 필수 | 필수 | — |
| 미해결 S1·S2 버그 없음 | 필수 | 필수 | 필수 |
| 에러 버짓 정책 (`## Error Budget Policy`) | 필수 | 권장 | — |
| 백업·복구 테스트 (백엔드) | 필수 | 필수 | — |
| 설정된 모든 표면에서 성능 목표 충족 | 필수 | 필수 | — |
| `accessibility.target` 대비 접근성 감사 (UI) | 필수 | 권장 | — |
| 지역이 요구하는 쿠키·추적 동의와 마케팅 수신 동의 구현 | 필수 | 필수 | — |
| 출시 체크리스트의 `## Engineering & SRE` 블록 완료 | 필수 | 필수 | — |

보안 감사 보고서를 게이트에 넘길 때는 `/gate-check launch`를 실행하면서 그 경로를 함께 알려 주세요.

---

## 7단계 Launch: 출시

### 이 단계에서 하는 일

출시하고, 운영하고, 계속 전달합니다. Launch는 **종착 단계**입니다. 이후의 모든 릴리스, 인시던트, 핫픽스, 그로스 실험,
회고는 게이트 없이 이 단계 안에서 반복됩니다. 대신 릴리스마다 `production/releases/<version>/`에 기록이 남습니다.

| 스텝 | 명령 | 필수 여부 | 산출물 |
|---|---|---|---|
| 릴리스 실행 | `/team-release` | 필수, 반복 | `production/releases/*/release-record.md` |
| 릴리스 노트 | `/release-notes` | 선택, 반복 | `production/releases/*/release-notes.md` |
| 변경 이력 | `/changelog` | 선택, 반복 | `docs/CHANGELOG.md` |
| 인시던트 대응 | `/incident` | 선택, 반복 | `production/incidents/INC-*.md` |
| 포스트모템 | `/postmortem` | 선택, 반복 | `production/incidents/postmortems/INC-*.md` |
| 핫픽스 | `/hotfix` | 선택, 반복 | `production/hotfixes/hotfix-*.md` |
| 그로스 실험·캠페인 | `/team-growth` | 선택, 반복 | `production/growth/*/brief.md` |
| 릴리스 회고 | `/retrospective release <version>` | 선택, 반복 | `production/retrospectives/retro-*.md` |
| 다음 기능 PRD | `/write-prd` (작은 변경은 `/quick-spec`) | 선택, 반복 | `design/prd/*.md` |
| 스프린트 계획 | `/sprint-plan` | 선택, 반복 | `production/sprints/sprint-*.md` |
| 스토리 구현 | `/dev-story`, `/story-done` | 선택, 반복 | `production/sprint-status.yaml` |
| 스모크 체크 | `/smoke-check` | 선택, 반복 | `production/qa/smoke-*.md` |
| 릴리스 체크리스트 | `/release-checklist` | 선택, 반복 | `production/releases/*/release-checklist.md` |
| 롤아웃 계획 | `/rollout-plan` | 선택, 반복 | `production/releases/*/rollout-plan.md` |

### `/team-release` — 릴리스 열차 실행

```text
/team-release 1.0.0
```

`team.size`가 `small`이면 `release-manager` → `qa-lead` → `devops-engineer` → `sre-engineer` 순서로 릴리스 열차와
롤아웃 계획을 실행합니다(`studio`는 보안·CS·현지화·딜리버리·분석 담당이 더해집니다).
모든 배포 단계는 항상 확인을 받는 `production_deploys` 범주이고, 에이전트는 배포 명령을 직접 실행하지 않고 사람이 실행할
명령을 제안합니다. 결과는 `production/releases/<version>/release-record.md`에 무엇이 나갔는지(PRD·스토리 경로),
실행한 롤아웃 단계와 시각, 최종 상태 `COMPLETED` / `HALTED` / `ROLLED BACK`으로 남습니다. `project.version`을 갱신할지는
먼저 묻습니다.

출시한 뒤에는 `validate-push.sh`가 보호 브랜치 푸시를 경고합니다. 의도된 동작입니다. 릴리스 푸시는 신중해야 합니다.

---

## 출시 후 운영과 반복 전달

### 반복 전달 루프

출시 후의 모든 릴리스는 같은 루프를 돕니다.

```text
/write-prd <feature>  (작은 변경은 /quick-spec)
  → /sprint-plan → /dev-story → /story-done → /smoke-check
  → /changelog → /release-notes
  → /release-checklist <version> → /rollout-plan <version> → /team-release <version>
  → /retrospective release <version>
```

1. **명세** — 다음 기능은 `/write-prd`, 작은 변경은 `/quick-spec`으로 씁니다. 이미 있는 PRD를 고쳤다면
   `/propagate-prd-change`로 영향을 확인합니다.
2. **구현** — Build와 같은 스토리 수명주기를 따릅니다.
3. **릴리스 준비** — 릴리스마다 자기 체크리스트와 롤아웃 계획을 가집니다.
4. **실행** — `/team-release`가 롤아웃 단계를 실행·기록합니다.
5. **결과 확인** — `/retrospective release <version>`은 프로세스 회고와 함께 `## Outcome vs Success Metrics` 섹션을
   씁니다. 릴리스에 포함된 PRD마다 목표 지표, 관측값(없으면 `NOT DETERMINED — <이유>`), 기능별 결정 `KEEP` /
   `ITERATE` / `ROLL BACK` / `REMOVE`를 기록하고, 선택적으로 DORA 지표(배포 빈도, 리드 타임, 변경 실패율, 복구 시간)를
   더합니다. `analytics-engineer`가 자문합니다.

**예시 — Moa 1.3.0.** 저축 목표 화면의 새 진행률 링을 `goals.v2-progress-ring` 플래그 뒤에 두고 출시합니다. 웹과
API는 플래그를 1% → 10% → 50% → 100%로 단계마다 체류 시간을 두고 열고, iOS는 App Store 단계적 출시, Android는 Play
단계적 출시를 씁니다. 가드레일은 오류율, p95 지연, 크래시 없는 세션 비율, 그리고 비즈니스 지표로 "목표 생성 전환율"을
둡니다. 어느 단계에서든 중단 기준을 넘으면 플래그를 끄고(모바일 바이너리는 되돌릴 수 없으므로 서버 플래그가 롤백
수단입니다) `/incident`로 이어집니다.

### 인시던트 대응: `/incident`

```text
/incident open "자동이체 결제 실패율 급증"
/incident update INC-20261104-01
/incident resolve INC-20261104-01
/incident runbook payments-webhook-error-rate
```

- **열기** — 심각도를 분류합니다(사용자에게 묻고, 임의로 낮추지 않습니다). 인시던트 커맨더, 커뮤니케이션 리드, 기록
  담당은 **사람**이 맡고 에이전트는 조언합니다. 기록은 `production/incidents/INC-YYYYMMDD-NN.md`에 남습니다.
- **먼저 완화** — 롤아웃 계획에 따른 롤백, 플래그 킬 스위치, 스케일 조정, 페일오버. 스킬은 사람이 실행할 정확한 명령을
  제안할 뿐 운영 환경을 바꾸는 명령을 직접 실행하지 않습니다.
- **커뮤니케이션** — `customer-success-manager`가 상태 페이지, 인앱 배너, 고객 이메일 초안을 씁니다.
- **보안·개인정보 인시던트** — `security-engineer`가 참여하고, 설정된 지역의 컴플라이언스 체크리스트에서 유출 통지 관련
  항목을 꺼내 확인 목록으로 제시합니다. 법정 기한은 출처 없이 사실처럼 말하지 않습니다.
- **업데이트** — 타임라인은 UTC와 KST를 함께 기록하고, 영향과 다음 업데이트 시각을 적습니다.
- **종료** — 해결 내용, 고객 영향(사용자·테넌트·지역, 지속 시간, 데이터 영향), 후속 조치(`/bug-report`, `/tech-debt`)를
  씁니다. 상태는 `OPEN` → `MITIGATED` → `RESOLVED`이며, SEV1·SEV2는 `RESOLVED — POSTMORTEM REQUIRED`로 닫히고
  `/postmortem`으로 넘어갑니다.

`/incident`, `/hotfix`, `/rollout-plan`은 출시에 결정적인 스킬이라 **리뷰 모드와 관계없이** 이름이 붙은 모든 에이전트와
게이트가 실행되고, 자동화 모드와 관계없이 모든 단계를 승인받습니다.

### 포스트모템: `/postmortem`

```text
/postmortem INC-20261104-01
```

인시던트 기록을 읽고 `production/incidents/postmortems/INC-20261104-01.md`에 요약, 영향, 타임라인, 탐지·대응 지표(탐지,
완화, 해결까지 걸린 시간), 기여 요인(원인 분석, 5 whys), 잘된 점, 아쉬운 점, 운이 좋았던 점, 조치 항목(담당, 우선순위,
기한, 유형 `prevent` / `detect` / `mitigate`), 런북 변경을 씁니다. 사람을 탓하는 표현과 오류에 붙은 이름을 찾아 시스템
중심 문장으로 바꾸자고 제안합니다(비난 없는 포스트모템). 조치 항목은 하나씩 물어보고 `/bug-report`나 `/tech-debt`로
옮기며, 런북은 `/incident runbook`으로 갱신합니다. 판정은 `COMPLETE` 또는 `INCOMPLETE — MISSING <sections>`이며, 인시던트 기록을 읽을 수 없으면 파일을 쓰지 않고 대화에서 `NOT ASSESSED`로 끝납니다.

### 핫픽스: `/hotfix`

```text
/hotfix INC-20261104-01 --surface api
/hotfix BUG-0042 --surface ios
```

- **web·api** — 먼저 완화(킬 스위치·플래그, 또는 정상 파이프라인으로 되돌리기)하고, 짧은 브랜치와 빠른 리뷰로 트렁크에서
  수정합니다(fix forward).
- **ios·android** — 즉시 서버 측 완화(플래그, API 호환)를 한 뒤, 릴리스 태그에서 브랜치를 따서 수정하고 긴급 심사와
  단계적 출시로 내보냅니다. 패치 버전·빌드 번호, 긴급 심사, 단계적 출시 여부, 태그 브랜치의 트렁크 병합은
  `release-manager`가 자문하고, 제출은 사람이 합니다.
- `sre-engineer`는 매번 완화 선택지와 정확한 명령, 수정 배포의 가드레일, 배포 후 검증을 자문합니다.
- 사인오프는 매번 `tech-lead`(정확성·부작용·최소 변경)와 `qa-engineer`(대상 회귀 테스트, 스모크 체크 또는 범위를 좁힌
  `/team-qa` 권고)가 하고, 보안 수정이면 `security-engineer`, 고객에게 보이는 변경이면 `product-manager`도 합니다.
  필요한 사인오프가 모두 `APPROVE`여야 배포하며, `delivery-manager`에게는 알리기만 합니다.
- 기록은 `production/hotfixes/hotfix-YYYY-MM-DD-<slug>.md`, 판정은 `SHIPPED`, `MITIGATED — FIX PENDING`,
  `NOT ASSESSED`입니다. 인시던트에 연결되어 있으면 `/postmortem <INC-id>`로, 아니면
  `/retrospective release <version>`으로 이어집니다.

### 그로스 실험과 라이프사이클 캠페인: `/team-growth`

```text
/team-growth "온보딩 3단계에서 첫 목표 추천 문구 A/B 테스트"
/team-growth readout goal-suggestion-copy
```

- `team.size`가 `small`이면 `growth-manager` → `analytics-engineer`(트래킹, 최소 검출 효과(MDE), SRM, 가드레일) →
  `product-designer`와 `ux-writer` → 변형을 스토리로 넘기는 순서로 진행합니다.
- `production/growth/<experiment-slug>/brief.md`에는 `## Hypothesis`, `## Target Segment & Sizing`,
  `## Primary Metric & Guardrails`, `## Variants`, `## Instrumentation`, `## Flag & Rollout`,
  `## Consent & Channel Check`, `## Stories`, `## Decision Rule`이 들어갑니다. 변형은 `/quick-spec`과
  `/create-stories`(또는 `/dev-story`)로 만든 스토리가 되어 표면에 맞는 엔지니어에게 갑니다.
- **동의·채널 점검** — 캠페인, 푸시·이메일·SMS·알림톡 템플릿, 마케팅 문구를 승인하기 전에 지역 체크리스트의 항목을
  하나씩 확인받습니다. 한국이라면 광고성 정보 사전 동의, 야간 전송 별도 동의, 수신 동의 정기 확인, 수신 거부 경로, 그리고
  알림톡은 정보성 메시지 전용이라는 점입니다.
- 가격 실험은 항상 확인을 받는 `billing_changes` 범주입니다.
- 결과 보고 `readout.md`에는 `## Result`, `## SRM Check`, `## Primary Metric`, `## Guardrails`, `## Segments`,
  `## Decision`이 들어가고 판정은 `SHIP`, `ITERATE`, `STOP`, `NOT ASSESSED`입니다.

### 두 가지 심각도 체계

| 구분 | 버그 (`/bug-report`, `/bug-triage`, `/team-qa`, `/hotfix`) | 인시던트 (`/incident`, `/postmortem`, `/hotfix`) |
|---|---|---|
| 가장 심각 | `S1-Critical` — 장애, 데이터 손실·손상, 보안·개인정보 침해, 결제·청구 실패, 법규 위반 | `SEV1` — 전면 장애, 데이터 손실, 사용자에게 영향이 확인된 보안·개인정보 침해 |
| 심각 | `S2-Major` — 우회 방법 없이 일부 사용자층의 핵심 여정이 깨지거나 심하게 저하 | `SEV2` — 큰 저하, 또는 많은 사용자의 핵심 여정이 깨짐 |
| 보통 | `S3-Minor` — 우회 방법이 있음 | `SEV3` — 우회 방법이 있는 부분적·경미한 저하 |
| 경미 | `S4-Trivial` — 외관상 문제 | `SEV4` — 사용자 영향 없음(아차 사고, 내부 한정) |

SEV1·SEV2는 포스트모템이 필수입니다. 인시던트는 후속 조치로 S 체계의 버그를 만들 수 있습니다. 버그 상태는 `Open`,
`In Progress`, `Fixed — Pending Verification`, `Verified Fixed`, `Closed`, `Won't Fix`이고, 앞의 셋이 "미해결"입니다.

### 운영 안전 원칙

- 에이전트는 운영 환경, 공유 인프라, 공유 데이터베이스, 시크릿을 바꾸는 명령을 **자율 모드에서도** 실행하지 않습니다.
  사람이 실행할 정확한 명령과 영향 범위, 예상 결과, 롤백 명령을 제안하고, 실행 결과를 확인한 뒤 기록합니다.
- 스스로 바꿀 수 있는 대상은 프리뷰 환경과 로컬·일회용 데이터베이스뿐이며, 그것도 "May I run this?"로 먼저 묻습니다.
- `.claude/settings.json`의 거부 목록이 프로덕션 배포, IaC apply, 파괴적 DB 명령, 스토어 제출, 인증서·키 파일 읽기를
  두 번째 방어선으로 막습니다.

---

## 티어별 차이

### 프로세스 강도와 여섯 가지 세부 설정

`modes.rigor` 하나가 여섯 가지 세부 설정을 정합니다. `/start`가 이 값을 묻습니다. 여섯 가지 세부 설정은 사용자가
`/settings <key>=<value>`로 직접 지정할 때만 `project.yaml`에 쓰이고, 다른 스킬은 쓰지 않습니다. 직접 지정한 값은
고정되어 `modes.rigor`를 바꿔도 따라오지 않습니다.

| `modes.rigor` | `workflow` | `docs.density` | `qa.level` | `story_granularity` | `review_mode` | `team.size` |
|---|---|---|---|---|---|---|
| **minimal (기본값)** | minimal | terse | minimal | coarse | solo | individual |
| standard | standard | balanced | standard | balanced | lean | individual |
| full | full | thorough | full | fine | full | studio |

설정하지 않은 프로젝트에서는 `modes.rigor`가 `minimal`로 해석되고, 그 결과 `review_mode`는 `solo`가 됩니다.
`/gate-check`는 `minimal`인 프로젝트가 Build 이후 단계로 들어갈 때 한 번, `standard`로 올릴지 제안합니다(설정은
`/settings`로 사용자가 바꿉니다).

### 단계별로 무엇이 필요한가

| 게이트 | minimal | standard | full |
|---|---|---|---|
| `definition` | one-pager, 비범위 | 제품 브리프(7개 섹션), 브리프 검토, 지표, 대상 세그먼트, 비범위 | standard + 원칙별 트레이드오프, 가정별 검증 방법 |
| `architecture` | 적용되지 않음 (`PASS`) | 기능 맵, MVP PRD(8개 섹션 + 조건부)와 검토, 스택 고정 | standard + PRD 11개 섹션, PRD 교차 검토 |
| `validation` | 스택 고정 | 아키텍처, 핵심 ADR, 초기 API 계약·데이터 모델(백엔드), 위협 모델(개인정보), 검토 보고서, 접근성(UI), 테스트·CI, 핵심 여정 | standard + Foundation ADR 3개 이상, 추적 행렬, 기술 레이더, 여정별 SLO, 성능 예산 |
| `build` | one-pager의 `## Build Order` | 스프린트 계획, 에픽·스토리, 디자인 언어 1–5번, 핵심 UX 명세와 검토, 워킹 스켈레톤 | standard + 디자인 언어 9개 섹션, 컨트롤 매니페스트, UX 기준 API 조정 |
| `hardening` | 스모크 체크, 미해결 S1 없음 | MVP 구현, 핵심 여정 E2E, S2 담당·기한, 마이그레이션 상태, 테스트 통과, 성능 예산, 플래그 기본값 | standard + 계약 테스트, SLO 대시보드·알림, 화면별 UX 명세, 접근성 확인 |
| `launch` | 롤백 포함 릴리스 체크리스트, quick 보안 감사, 릴리스 후보 스모크, 미해결 S1·S2 없음 | 롤아웃 계획, 출시 체크리스트, full 보안 감사, QA 사인오프, 안정화 보고서, 사용성 1회+, 런북·온콜, 약관·방침, 스토어·지역·현지화 항목, 릴리스 노트 | standard + 부하 테스트, 사용성 3회+, 에러 버짓 정책, 접근성 감사 |

어떤 티어에서도 완화되지 않는 것이 있습니다. 스모크 보고서, 마이그레이션 드라이런 증거, 릴리스 체크리스트의 롤백 경로,
그리고 만들어진 워킹 스켈레톤의 검증 항목입니다. `qa.level`은 스토리별 증거 요구를 완화하지만 스모크 보고서라는
최저선은 그대로입니다.

### 한 기능만 다르게: 재정의

- `workflow_overrides.feature_overrides.<prd-stem>` — 기능 하나의 티어를 올립니다. 예:
  `workflow_overrides.feature_overrides.payments: full`. 키는 `design/prd/<stem>.md`와 이름이 같아야 하며, PRD가 없는
  키는 게이트에서 `CONCERNS`가 됩니다(아직 쓰지 않은 PRD를 `/write-prd` 중에 가리키는 것은 괜찮습니다).
- `workflow_overrides.edge_cases`, `workflow_overrides.config_flags`, `workflow_overrides.design_language_strict` —
  각각 Edge Cases, Configuration & Flags, 디자인 언어 9개 섹션을 더 낮은 티어에서도 필수로 만듭니다.
- `testing.strict.logic`, `testing.strict.integration`, `testing.strict.ui`, `testing.strict.e2e`,
  `testing.strict.config` — 테스트 유형별로 증거 누락을 차단(`true`)할지 경고(`false`)할지 정합니다. 설정하지 않으면
  스킬마다 자기 기본값을 씁니다.

---

## 리뷰 모드와 디렉터 게이트

디렉터 게이트는 주요 산출물을 해당 분야 책임자 에이전트가 검토하는 지점입니다. 게이트 ID의 접두사는 담당자를
나타냅니다: `PD-` `product-director`, `TD-` `technical-director`, `DM-` `delivery-manager`, `DD-` `design-director`,
`TL-` `tech-lead`, `QL-` `qa-lead`, `SE-` `security-engineer`, `SR-` `sre-engineer`. 정의는
`.claude/docs/director-gates/`에, 호출 규칙은 `.claude/docs/director-gates.md`에 있습니다.

### 세 가지 리뷰 모드

| 모드 | 무엇이 실행되나 | 이런 경우에 |
|---|---|---|
| `full` | 모든 디렉터 게이트 | 규제가 있는 서비스, 처음 이 프레임워크를 쓰는 팀 |
| `lean` | ID가 `-PHASE-GATE`로 끝나는 게이트만 (단계 전환 때) | 경험 있는 팀, 시드 단계 제품 |
| `solo` | 디렉터 게이트 없음 | 해커톤, 프로토타입, 최대 속도 |

- 결정 순서: 실행할 때 붙인 `--review` 플래그 → `project.local.yaml` → `project.yaml` → `modes.rigor` 확장
  (`minimal` → `solo`, `standard` → `lean`, `full` → `full`).
- `lean`은 **ID가 `-PHASE-GATE`로 끝나지 않는 모든 게이트를 건너뛰고** `[GATE-ID] skipped — Lean mode` 메모를 남깁니다.
  `solo`는 모든 게이트를 건너뛰고 `[GATE-ID] skipped — Solo mode`를 남깁니다.
- 예외: `/hotfix`, `/rollout-plan`, `/incident`는 출시에 결정적인 스킬이라 이름이 붙은 모든 에이전트와 게이트가 모든
  `review_mode`에서 실행됩니다. 이 세 스킬은 `review_mode`를 읽지 않습니다.
- `review_mode`를 바꾸는 스킬은 `/settings`뿐입니다.

한 번만 다르게 실행하려면 게이트를 쓰는 스킬에 플래그를 붙입니다.

```text
/brainstorm 소상공인 예약 관리 --review full
/architecture-decision "주 데이터 저장소" --review solo
```

### 단계 게이트 패널

`/gate-check`는 `PD-PHASE-GATE`, `TD-PHASE-GATE`, `DM-PHASE-GATE`, `DD-PHASE-GATE` 가운데 `modes.workflow`가 정한
너비만큼을 병렬로 호출하고, 가장 엄한 판정을 따릅니다. 티어별 패널 구성은 `.claude/skills/gate-check/SKILL.md` §4b의
표에만 있습니다. UI 표면이 없다고 확인된 프로젝트에서는 `design-director`를 빼고, 뺐다는 사실을 밝힙니다. `lean`
모드에서도 패널은 같은 너비로 실행됩니다.

### 판정 등급

게이트마다 쓰는 단어는 다르지만 세 등급으로 묶입니다.

| 등급 | 토큰 | 처리 |
|---|---|---|
| 진행 | `APPROVE`, `READY`, `VIABLE`, `REALISTIC`, `ON TRACK`, `FEASIBLE`, `ADEQUATE`, `STRONG` | 계속 진행 |
| 우려 | `CONCERNS`, `AT RISK`, `GAPS` | 수정 / 수용 / 논의 중에서 사용자가 선택 |
| 거부 | `REJECT`, `NOT READY`, `HIGH RISK`, `UNREALISTIC`, `OFF TRACK`, `INFEASIBLE`, `INADEQUATE` | 차단 |
| 선택 | `OPTIONS` | 제시된 방향 중 사용자가 고르면 진행 등급으로 처리 |

게이트 결과는 산출물에 `> **[Director] Review ([GATE-ID])**: APPROVED [date]`(또는 `CONCERNS (accepted)`,
`REVISED`) 형태로 기록됩니다. `/gate-check`가 "게이트 결과가 기록되었는가"를 확인할 때, 리뷰 모드 때문에 건너뛴 게이트는
건너뜀 메모가 증거가 되며 `NOT CHECKED — <GATE-ID> skipped (<mode> mode)`로 표시하고 점수에 넣지 않습니다.

### 단계별 게이트

| 단계 | 필수 게이트 | 선택 게이트 |
|---|---|---|
| Discovery | PD-PRINCIPLES | TD-FEASIBILITY, DM-SCOPE, DD-BRAND-DIRECTION (full + UI), PD-USER-VALIDATION (`/prototype`), TD-STACK-RISK (`/setup-stack upgrade`) |
| Definition | TD-DOMAIN-BOUNDARY, PD-FEATURE-MAP, DM-SCOPE, PD-PRD-ALIGN (PRD마다) | TD-CHANGE-IMPACT (PRD 수정 시) |
| Architecture | TD-ARCHITECTURE, TL-FEASIBILITY, TD-ADR (ADR마다), SE-SECURITY-REVIEW (API 계약·데이터 모델마다), TD-MANIFEST (full) | TD-STACK-RISK |
| Validation | DD-DESIGN-LANGUAGE, DM-EPIC, QL-STORY-READY (스토리마다), DM-SPRINT, 단계 게이트 (`/gate-check`) | DD-BRAND-DIRECTION (브리프에 앵커가 없을 때), PD-USER-VALIDATION, DD-UI-CONSISTENCY, SE-SECURITY-REVIEW (계약 수정) |
| Build | TL-CODE-REVIEW (스토리마다), QL-TEST-COVERAGE (스토리마다), QL-STORY-READY, DM-SPRINT (스프린트마다) | DM-MILESTONE, DD-UI-CONSISTENCY, DD-CONTENT-VOICE, TD-CHANGE-IMPACT |
| Hardening | QL-TEST-COVERAGE (`/team-qa`), PD-USER-VALIDATION (`/usability-report`), SR-PRODUCTION-READINESS (`/rollout-plan`) | DM-MILESTONE |
| Launch | 단계 게이트 (`/gate-check`, 진입 시), SR-PRODUCTION-READINESS (롤아웃 계획마다) | DM-MILESTONE, DD-CONTENT-VOICE |

---

## 공통 관심사

### 협업 프로토콜

이 시스템은 자율 실행이 아니라 **사용자 주도 협업**입니다. 모든 상호작용은 **질문 → 선택지 → 결정 → 초안 → 승인**
순서를 따릅니다.

1. 에이전트가 먼저 명확히 하는 질문을 합니다.
2. 장단점과 근거를 붙인 2–4개의 선택지를 제시합니다.
3. 사용자가 결정합니다.
4. 에이전트가 결정에 맞춰 초안을 씁니다.
5. 사용자가 검토하고 다듬습니다.
6. 쓰기 전에 "May I write this to [filepath]?"라고 묻습니다. 여러 파일을 바꿀 때는 전체 변경 묶음을 승인받습니다.
   커밋은 지시가 있을 때만 합니다.

예시와 함께 보려면 [COLLABORATIVE-DESIGN-PRINCIPLE.md](COLLABORATIVE-DESIGN-PRINCIPLE.md)를 읽으세요.

### AskUserQuestion 사용 방식

에이전트는 선택지를 제시할 때 `AskUserQuestion` 도구를 씁니다. 먼저 대화 속에서 충분히 분석해 설명하고, 그다음 깔끔한
선택 UI로 결정을 받습니다(설명 후 수집). 설계 선택, 아키텍처 결정, 전략적 질문에 쓰고, 열린 탐색 질문이나 단순한 예·아니오
확인에는 쓰지 않습니다.

### 자동화 모드

`modes.automation`은 스킬이 얼마나 자주 멈춰서 확인하는지를 정합니다.

- `collaborative`(기본값) — 항상 묻습니다.
- `guided` — 큰 결정에서만 묻습니다.
- `autonomous` — 결정을 기록하고 진행합니다.

어떤 모드에서도 `modes.automation_always_ask`의 범주는 항상 묻습니다. 기본 목록은 `scope_changes`, `file_deletions`,
`schema_changes`, `production_deploys`, `db_migrations`, `infra_changes`, `secrets_access`, `pii_data_access`,
`billing_changes`이고, 여기에 `architecture_decisions`, `version_bumps`, `external_calls`를 추가할 수 있습니다.
`/gate-check`, `/hotfix`, `/incident`, `/rollout-plan`, `/setup-stack`, `/start`, `/settings`는 항상 협업 모드로
동작합니다. 자세한 정의는 `.claude/docs/automation-modes.md`에 있습니다.

### 산출물 언어

스킬이 만드는 PRD, ADR, UX 명세, 보고서, 스토리는 템플릿의 제목(`#`/`##`/`###`), 굵은 필드 이름(`**Status**`,
`> **Surface**:` 등), 판정·심각도·상태 토큰, YAML 키와 enum 값, ID, 경로를 **영어 그대로** 둡니다. 스크립트와 게이트가
이 텍스트를 기준으로 찾기 때문에, 읽기 편하라고 제목을 번역하면 게이트가 섹션을 찾지 못합니다. 본문은 사용자가 대화하는
언어로 씁니다. 고객에게 나가는 문구(릴리스 노트, 스토어 문구, 마이크로카피)는 대화 언어와 관계없이 출시 로케일
(`localization.locales`)로 씁니다.

### 컨텍스트 복원

- **세션 상태 파일** `production/session-state/active.md`가 살아 있는 체크포인트입니다. 의미 있는 진척이 있을 때마다
  갱신하고, 압축·충돌·`/clear` 뒤에는 이 파일부터 읽습니다. 대화가 아니라 파일이 기억입니다.
- **점진적 쓰기** — 여러 섹션으로 된 문서는 섹션이 승인될 때마다 바로 파일에 씁니다. 완료된 섹션은 세션이 끊겨도 남고,
  그 섹션에 관한 이전 대화는 안전하게 압축될 수 있습니다.
- **자동 복구** — `session-start.sh`가 `active.md`를 찾아 미리 보여 주고, `pre-compact.sh`가 압축 직전에 상태를 대화에
  남기며, `post-compact.sh`가 복원을 알립니다.
- **스프린트 추적** — `production/sprint-status.yaml`이 기계가 읽는 스토리 추적기입니다. `/sprint-plan`이 만들고
  `/dev-story`와 `/story-done`이 상태를 갱신하며, `/sprint-status`, `/help`, `/story-done`이 읽습니다.
- **상태 줄** — 컨텍스트 사용률, 모델, 단계와 rigor를 보여 주고, Build·Hardening·Launch에서는
  `Epic > Feature > Task` 경로(예: `Goals > Progress Ring > Animation`)를 함께 보여 줍니다.

### 스택 지식 관리

모델은 학습 시점 이후에 나온 프레임워크 버전을 모릅니다. 그래서 스택 스페셜리스트는 버전에 민감한 조언을 하기 전에
`docs/stack-reference/VERSION.md`와 구성 요소별 문서를 먼저 읽고, 지식 시점 이후의 API는 Knowledge Risk로 표시하며,
확인할 수 없는 내용은 추측하는 대신 `NOT SOURCEABLE — run /setup-stack refresh`라고 답합니다. 레퍼런스 문서는
`/setup-stack`만 만들고, 모든 사실에 출처와 확인 날짜가 붙습니다.

### 자동 훅

세션 시작, Bash 실행 전, 파일 쓰기 후, 컨텍스트 압축 전후, 응답 종료, 서브에이전트 시작·종료 시점에 훅이 자동으로
실행됩니다. 커밋 훅은 파싱되지 않는 JSON/YAML, 시크릿, 인증 파일이 스테이징되면 커밋을 막고, 나머지는 경고나 안내만
합니다. 훅별 설명은 [README](../README.md#자동-안전장치-훅-스크립트-권한)와 `.claude/docs/hooks-reference.md`에 있습니다.

### 기존 프로젝트 도입

이미 산출물이 있는 프로젝트라면 `/adopt`로 시작합니다.

```text
/adopt
/adopt prds
/adopt adrs
/adopt api
/adopt infra
```

`/adopt`는 산출물의 **존재가 아니라 형식**을 감사합니다. PRD 섹션, 기능 맵의 열과 상태 값, ADR 제목, API 계약의 존재와
린트, 마이그레이션과 계획의 대응, 테스트와 CI, SLO와 런북, 선언되지 않은 코드 루트를 보고, 공백을 `BLOCKING` / `HIGH` /
`MEDIUM` / `LOW`로 분류한 뒤 번호 붙은 도입 계획을 `docs/adoption-plan-YYYY-MM-DD.md`에 씁니다. 원칙은 **교체가 아니라
이전**입니다. 기존 작업을 다시 만들지 않고 빈 곳만 채웁니다. 계획은 마지막에 `/gate-check <목표 단계>`로 넘깁니다.

빠진 문서는 코드에서 역으로 만들 수 있습니다.

```text
/reverse-document prd apps/api/src/modules/goals
/reverse-document architecture apps/api
/reverse-document brief prototypes/goal-setup-concept
/architecture-decision retrofit docs/architecture/adr-0005-queue.md
```

`/reverse-document brief`는 제품 브리프가 없으면 `design/product/product-brief.md`에 쓰고, 이미 있으면 묻지 않고
덮어쓰지 않습니다. 이때는 `design/product/product-brief-from-code-YYYY-MM-DD.md`에 써서 사용자가 합치게 합니다.

---

## 부록 A: 어떤 에이전트에게 맡길까

| 하고 싶은 일 | 에이전트 |
|---|---|
| 제품 아이디어 탐색 | `/brainstorm` 스킬 |
| 제품 방향, 원칙, 범위 충돌 판단 | `product-director` |
| 기술 방향, 벤더 선택(만들까 살까), 아키텍처 결정 | `technical-director` |
| 스프린트·마일스톤 계획, 일정과 위험, 변경 전파 조율 | `delivery-manager` |
| 디자인 언어, 컴포넌트 라이브러리와 디자인 토큰 관리 | `design-director` |
| 문제 정의, 기능 분해, PRD, 우선순위(RICE) | `product-manager` |
| 가입 자격, 한도·쿼터, 수수료, 환불·해지 같은 정책 규칙 | `business-analyst` |
| 요금제·권한 설계, 무료 체험, 쿠폰, 포인트·크레딧, 결제 수단 | `monetization-strategist` |
| 모듈·서비스 경계, API 계약과 마이그레이션 리뷰, 코드 리뷰 | `tech-lead` |
| 도메인 로직, REST·GraphQL 핸들러, 영속성, 백그라운드 작업 | `backend-engineer` |
| 웹 UI, 앱 셸, 폼, 상태 관리, Core Web Vitals | `frontend-engineer` |
| iOS·Android·React Native·Flutter 앱, 오프라인 동기화, 푸시, 딥링크 | `mobile-engineer` |
| 공용 라이브러리와 SDK(데이터 접근, 캐시, 큐, 플래그 SDK) | `platform-engineer` |
| 어드민·운영툴, CS 도구, 데이터 보정 스크립트 | `internal-tools-engineer` |
| LLM·ML 기능, RAG, 평가 하네스, 가드레일 | `ml-engineer` |
| 이벤트 수집, CDC, ETL/ELT 파이프라인, 백필 | `data-engineer` |
| 트래킹 플랜, dbt 모델, 실험 설계와 결과 분석, 대시보드 | `analytics-engineer` |
| Core Web Vitals, 번들 크기, API 지연, 쿼리 프로파일링, 부하 테스트 | `performance-engineer` |
| 흐름, 정보 구조, 와이어프레임, 인터랙션 패턴 | `product-designer` |
| 인터뷰, 사용성 테스트, 설문, 리서치 종합 | `ux-researcher` |
| 마이크로카피, 오류·빈 상태 문구, 알림 템플릿(푸시·이메일·SMS·알림톡) | `ux-writer` |
| 디자인 토큰 파이프라인, 컴포넌트 라이브러리와 Storybook, 모션, 시각 회귀 | `design-engineer` |
| 빠른 검증용 프로토타입(운영 코드 아님) | `prototyper` |
| WCAG 2.2·KWCAG 준수, 스크린 리더, 대비 | `accessibility-specialist` |
| 위협 모델링, OWASP·MASVS, 시크릿, 개인정보 처리 | `security-engineer` |
| 테스트 전략, 증거 기준, 릴리스 품질 게이트 | `qa-lead` |
| 테스트 케이스, E2E·계약 테스트 코드, 탐색 테스트 | `qa-engineer` |
| CI/CD, IaC, 환경, 컨테이너·서버리스, 시크릿 관리 | `devops-engineer` |
| SLO와 에러 버짓, 관측성, 온콜과 런북, 백업·복구 | `sre-engineer` |
| 릴리스 열차, 버전 관리, 스토어 제출, 점진적 배포 실행 | `release-manager` |
| i18n 구조, 문자열 추출, 번역 관리, 문자열 동결 | `localization-lead` |
| 활성화·온보딩 최적화, 리텐션 CRM, 실험 로드맵, ASO | `growth-manager` |
| 고객 지원 운영, VOC, 상태 페이지, 앱 리뷰 답변, B2B 고객 성공 | `customer-success-manager` |
| 웹 프레임워크 선택과 렌더링 전략 | `web-specialist` (→ `nextjs-specialist`, `vue-nuxt-specialist`) |
| 크로스플랫폼 대 네이티브, 서명과 스토어 빌드 | `mobile-specialist` (→ `react-native-specialist`, `flutter-specialist`, `ios-specialist`, `android-specialist`) |
| 백엔드 프레임워크 관용구, 모듈러 모놀리스 대 서비스 | `backend-specialist` (→ `node-specialist`, `spring-specialist`, `python-specialist`) |
| PostgreSQL·MySQL, Redis, 큐, 인덱스, 마이그레이션 도구 | `data-specialist` |
| AWS·GCP·Azure·NCP, Vercel·Fly·Cloudflare, Kubernetes, Terraform | `cloud-specialist` |

**에스컬레이션 규칙**: 두 에이전트의 의견이 갈리면 공통 상위자에게 올립니다. 제품·UX·디자인 갈등은
`product-director`, 기술·품질 갈등은 `technical-director`로 갑니다. 여러 영역에 걸친 변경은 `delivery-manager`가
조율합니다.

---

## 부록 B: 자주 쓰는 흐름

### "아이디어가 전혀 없다"

```text
1. /start (A 선택)
2. /brainstorm open                   → one-pager 또는 제품 브리프
3. /setup-stack                       → 결정된 레이어 고정
4. /prd-review design/product/product-brief.md   (standard·full)
5. /prototype "<가장 위험한 가정>"      (선택, PROCEED면 계속)
6. /gate-check definition             (minimal이면 6–7 대신 /create-stories → /dev-story)
7. /map-features → /write-prd <feature> (MVP 기능마다)
```

### "기획은 끝났고 개발을 시작하고 싶다"

```text
1. /prd-review design/prd/<feature>.md (PRD마다) → /review-all-prds → /setup-stack (아직 고정하지 않았다면)
2. /gate-check architecture
3. /create-architecture → /architecture-decision (결정마다)
4. /api-design new → /data-model → /security-audit threat-model (개인정보)
5. /ux-design accessibility → /test-setup → /test-helpers
6. /architecture-review
7. /gate-check validation
8. /design-language → /ux-design (핵심 화면) → /ux-review → /api-design reconcile
9. /create-control-manifest → /create-epics layer: foundation → /create-stories <epic> → /sprint-plan new
10. /walking-skeleton → /gate-check build
11. /story-readiness → /dev-story → /story-done (스토리마다)
```

### "스프린트 중에 큰 기능을 추가해야 한다"

```text
1. /write-prd <feature> 또는 /quick-spec "<변경>" (규모에 따라)
2. /prd-review로 검증, 기존 PRD를 고쳤다면 /propagate-prd-change
3. /api-design update <resource> → /data-model migration <slug> (필요하면)
4. /estimate로 공수와 위험 추정 → /scope-check
5. /team-feature <feature-slug> (화면 중심이면 /team-ui, 문구 중심이면 /team-content)
6. /story-done (완료 시) → /business-rules-check (가격·한도에 영향이 있으면)
```

### "운영 중에 장애가 났다"

```text
1. /incident open "<증상 요약>"        → SEV 분류, 먼저 완화
2. /incident update <INC-id>          → 타임라인(UTC + KST), 고객 커뮤니케이션
3. /hotfix <INC-id> --surface <표면>  → 수정과 배포 경로
4. /incident resolve <INC-id>
5. /postmortem <INC-id>               (SEV1·SEV2 필수) → 조치 항목을 /bug-report, /tech-debt로
6. /incident runbook <alert-slug>     (런북이 없었거나 부족했다면)
```

### "기존 제품에 이 시스템을 도입하고 싶다"

```text
1. /start (D 선택)                    → 단계 추정
2. /adopt                             → 형식 감사와 도입 계획
3. /setup-stack                       → 스택 고정, 코드 루트 선언
4. /reverse-document prd|architecture|brief <path>
5. /architecture-decision retrofit <path>
6. /project-stage-detect              → 영역별 공백 확인
7. /gate-check <목표 단계>
```

### "새 스프린트를 시작한다"

```text
1. /retrospective sprint-<N>          → 지난 스프린트 회고
2. /sprint-plan new                   → 다음 스프린트
3. /scope-check                       → 범위 확인
4. /story-readiness (스토리마다) → /dev-story → /story-done
5. /sprint-status                     (수시로)
6. /smoke-check → /qa-plan 또는 /team-qa sprint
```

### "첫 출시를 준비한다"

```text
1. /gate-check hardening
2. /team-hardening → /perf-profile → /load-test → /security-audit full
3. /usability-report (세션마다) → /team-qa → /incident runbook <alert> (알림마다)
4. /localize qa (다국어) → /tech-debt (출시 시점에 수용할 부채 결정)
5. /changelog → /release-notes → /smoke-check (릴리스 후보) → /release-checklist → /rollout-plan → /launch-checklist
6. /gate-check launch
7. /team-release <version> → /retrospective release <version>
```

### "출시 후 다음 릴리스를 낸다"

```text
1. /write-prd <feature> 또는 /quick-spec
2. /sprint-plan → /dev-story → /story-done → /smoke-check
3. /changelog → /release-notes <version>
4. /release-checklist <version> → /rollout-plan <version>
5. /team-release <version>
6. /retrospective release <version>   → 성공 지표 대비 결과, KEEP / ITERATE / ROLL BACK / REMOVE
7. 필요하면 /team-growth로 실험 설계
```

### "길을 잃었다"

```text
1. /help                              → 현재 단계, 산출물, 다음 필수 단계
2. /project-stage-detect              → 영역별 전체 감사
3. 단계가 틀린 것 같다면 /gate-check <목표 단계>
```

---

## 활용 팁

1. **설계 먼저, 구현은 그다음.** 에이전트는 PRD·ADR·API 계약이 코드보다 먼저 있다고 가정하고 계속 참조합니다.
2. **계약을 먼저 쓰세요.** API와 데이터 모델을 먼저 정하면 웹·모바일·백엔드를 병렬로 만들 수 있습니다.
3. **워킹 스켈레톤을 건너뛰지 마세요.** 이후의 모든 게이트는 스테이징, CD, 관측성, 플래그가 이미 있다고 가정합니다.
4. **팀 스킬에 맡기세요.** 에이전트 네 명을 손으로 조율하지 말고 `/team-feature`, `/team-ui` 같은 팀 스킬을 쓰세요.
5. **규칙이 지적하면 고치세요.** 경로별 규칙은 비즈니스 값을 설정으로 빼기, 경계에서의 인가, expand/contract
   마이그레이션처럼 서비스 운영에서 비싸게 배운 원칙을 담고 있습니다.
6. **미리 압축하세요.** 컨텍스트 사용률이 65–70% 정도면 압축하거나 `/clear`하세요. 압축 전 훅이 진행 상황을 남깁니다.
7. **알맞은 에이전트를 부르세요.** `product-director`에게 CSS를 맡기거나 `qa-engineer`에게 제품 결정을 맡기지 마세요.
8. **막히면 `/help`.** 실제 프로젝트 상태를 읽고 가장 중요한 다음 한 단계를 알려 줍니다.
9. **개발자에게 넘기기 전에 `/prd-review`.** 불완전한 명세를 일찍 잡으면 재작업이 줄어듭니다.
10. **기능마다 `/code-review`.** 인가 누락이나 N+1 같은 문제가 퍼지기 전에 잡습니다.
11. **위험한 가정은 먼저 프로토타입으로.** 하루짜리 페이크 도어가 한 스프린트짜리 헛수고를 막습니다.
12. **스프린트 계획을 정직하게.** `/scope-check`를 자주 돌리세요. 범위 확장은 초기 제품의 가장 흔한 실패 원인입니다.
13. **결정은 ADR로.** 왜 그렇게 만들었는지는 미래의 여러분이 가장 먼저 묻는 질문입니다.
14. **스토리 수명주기를 지키세요.** 착수 전 `/story-readiness`, 완료 후 `/story-done`. 어긋남을 일찍 잡습니다.
15. **릴리스마다 결과를 보세요.** `/retrospective release <version>`으로 출시한 기능이 실제로 지표를 움직였는지
    확인하고, 움직이지 않았다면 되돌리거나 빼는 결정도 내리세요.
