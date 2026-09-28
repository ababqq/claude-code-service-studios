# 업그레이드 가이드

이 문서는 Claude Code Service Studios(CCSS) 템플릿으로 시작한 여러분의 제품 저장소를 템플릿의 새 버전으로
올리는 방법을 설명합니다. 버전마다 무엇이 바뀌었는지는 [CHANGELOG.md](CHANGELOG.md)에 있습니다.

**지금 쓰고 있는 버전은 `project.yaml`에서 확인합니다.** 템플릿 버전을 기록하는 곳은 이 키 하나뿐입니다.

```yaml
framework:
  version: <지금 쓰는 프레임워크 버전>
  last_upgraded: <마지막으로 업그레이드한 날짜>
```

Claude Code 세션에서 `/settings framework.version`으로 봐도 됩니다. README의 배지나 커밋 로그로 버전을
추측하지 마세요. 업그레이드를 마치면 이 두 값을 새 버전의 절이 알려 주는 값으로 바꿉니다.

---

## 목차

- [Claude Code Game Studios 프로젝트의 마이그레이션은 지원하지 않습니다](#claude-code-game-studios-프로젝트의-마이그레이션은-지원하지-않습니다)
- [파일 소유 구분](#파일-소유-구분)
- [업그레이드 전략](#업그레이드-전략)
- [첫 릴리스 (2026-09-27)](#010-2026-09-27)
- [업그레이드한 뒤 확인할 것](#업그레이드한-뒤-확인할-것)
- [버전별 절의 형식](#버전별-절의-형식)

---

## Claude Code Game Studios 프로젝트의 마이그레이션은 지원하지 않습니다

CCSS는 Claude Code Game Studios v1.1.1(커밋 `7ed2c3e`, 작성자 Donchitos, MIT 라이선스,
`https://github.com/Donchitos/Claude-Code-Game-Studios`)에서 포크했습니다. 하지만 **업스트림으로 만든 프로젝트를
CCSS로 옮기는 경로는 제공하지 않습니다.** 변환 스크립트도, 옛 이름을 받아 주는 호환 별칭도 없습니다.

**지원하지 않는 이유**

1. **식별자가 모두 바뀌었습니다.** 에이전트, 스킬, 디렉터 게이트, 단계 값, 설정 키, 산출물 경로, 템플릿
   헤딩이 한 번에 새 이름으로 바뀌었고, CCSS는 옛 이름을 어디에서도 읽지 않습니다. 옛 파일을 그대로 두면
   동작하는 것처럼 보이다가 조용히 아무것도 찾지 못합니다.
2. **문서 계약이 다릅니다.** 업스트림의 GDD 8개 섹션과 CCSS PRD의 11개 섹션은 일대일로 대응하지 않습니다.
   `Goals & Non-Goals`, `Non-Functional Requirements`, `Success Metrics & Instrumentation`처럼 새로 생긴 섹션의
   내용은 기계적 변환으로 만들어지지 않습니다. ADR 헤딩과 스토리 헤더(`**Surface**`, `**API Contract**`,
   `**Migration**` 등)도 마찬가지입니다.
3. **엔진 계층이 스택 계층으로 바뀌었습니다.** 업스트림의 `engine.*` 설정과 엔진 레퍼런스에는 서비스 스택의
   대응 값이 없습니다. 코드 루트도 고정 경로에서 레이어별 선언(`stack.layers.<layer>.root`)으로 바뀌었습니다.
4. **v1 레거시 설정 계층이 없어졌습니다.** production/stage.txt, production/review-mode.txt,
   .claude/docs/technical-preferences.md를 읽던 코드와 migrate-v1-config.sh가 모두 삭제되었습니다.

**대신 이렇게 하세요**

- **게임을 만들고 있다면** 업스트림을 계속 쓰고, 업스트림 저장소의 업그레이드 가이드를 따르세요.
- **업스트림 템플릿으로 서비스를 만들고 있었다면** CCSS로 새로 시작하는 편이 빠릅니다.
  1. 새 브랜치(또는 새 저장소)에서 업스트림 프레임워크 파일(`.claude/`, 루트 `CLAUDE.md`, `project.yaml`,
     업스트림의 스킬 테스트 프레임워크 폴더)을 지우고, CCSS 템플릿의 파일을 복사해 넣습니다. **옛 `.claude/`를
     CCSS 위에 덮어쓰거나 섞지 마세요.** 옛 스킬과 새 스킬이 섞이면 서로 없는 파일과 키를 가리킵니다.
     개인 설정(`.claude/settings.local.json` 등)을 옮겨 온다면 옛 훅 경로를 고칩니다.
     `.claude/hooks/validate-assets.sh`를 가리키는 항목은 `.claude/hooks/validate-data-files.sh`로 바꾸세요.
     옛 훅은 없어졌고, 새 훅은 에셋 이름 규칙 없이 설정·API 계약·로케일 같은 JSON/YAML 파일의 파싱만 검사합니다.
  2. Claude Code에서 `/start`를 실행하고 "기존 제품이나 코드베이스가 있다"(D)를 고릅니다. `/start`가
     `stage-estimate.sh`로 현재 단계를 추정해 기록합니다.
  3. `/setup-stack`으로 레이어별 스택과 코드 루트를 선언합니다. `/start`는 곧바로 `/adopt`를 권하지만, 코드
     루트를 먼저 선언해 두어야 `/adopt`가 코드를 제대로 찾습니다.
  4. `/adopt`로 기존 산출물이 CCSS 계약과 어디서 어긋나는지 감사하고, 번호가 매겨진 적용 계획을 받습니다.
  5. `/reverse-document`로 기존 코드와 문서에서 PRD, ADR, 제품 브리프를 다시 만듭니다. 옛 설계 문서(예:
     design/gdd/)는 이때 참고 자료로만 쓰고, 끝나면 정리합니다.
  6. `/gate-check <목표 단계>`로 지금 단계가 맞는지 확인합니다.

---

## 파일 소유 구분

업그레이드는 결국 "어떤 파일을 새 버전으로 바꾸고, 어떤 파일을 지킬 것인가"의 문제입니다. 아래 표가 모든
전략의 기준입니다.

| 구분 | 경로 | 업그레이드할 때 |
|---|---|---|
| **템플릿 소유** | `.claude/agents/`, `.claude/skills/`, `.claude/hooks/`, `.claude/scripts/`, `.claude/rules/`, `.claude/docs/`, `.claude/statusline.sh`, `docs/stack-reference/README.md`, `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md`, `docs/WORKFLOW-GUIDE.md`, `docs/skill-flow-diagrams.md`, `design/CLAUDE.md`, `docs/CLAUDE.md`, `CCSS Skill Testing Framework/`(`results/` 제외), `README.md`, `CHANGELOG.md`, `UPGRADING.md`, `CONTRIBUTING.md`, `SECURITY.md`, `LICENSE`, `.gitattributes` | 새 버전으로 교체합니다. 직접 고친 파일만 예외입니다 |
| **섞여 있음** — 템플릿의 구조와 여러분의 내용 | `CLAUDE.md`, `project.yaml`, `.claude/settings.json`, `.gitignore` | diff를 보고 손으로 병합합니다 |
| **여러분의 데이터** — 템플릿은 뼈대만 싣거나 싣지 않고, 스킬이 채우는 파일 | `docs/stack-reference/VERSION.md`와 `docs/stack-reference/<component>/`, `design/registry/entities.yaml`, `docs/registry/architecture.yaml`, `docs/architecture/tr-registry.yaml`, 그 밖의 `design/`·`docs/architecture/`·`docs/api/`·`docs/data/`·`docs/ops/`·`docs/security/` 아래 문서, `docs/CHANGELOG.md`, `production/`, `tests/`, `prototypes/`, 코드 루트와 `<root>/CLAUDE.md`, `.github/workflows/` | 절대 덮어쓰지 않습니다. 새 버전이 이 파일들의 형식을 바꾸면 그 버전의 절이 무엇을 고칠지 알려 줍니다 |
| **개인 파일** — gitignore 대상 | `project.local.yaml`, `.claude/settings.local.json`, `CLAUDE.local.md`, `.claude/agent-memory/`, `production/session-state/`, `production/session-logs/` | 건드리지 않습니다 |

- `.github/`의 이슈·PR 템플릿과 `CODEOWNERS`는 이 템플릿 저장소 자체를 위한 파일입니다. 제품 저장소에서는
  여러분의 것으로 바꾸고 업그레이드 대상에서 빼세요. `.github/workflows/ci.yml`은 `/test-setup`이 만든
  여러분의 CI입니다.
- **업그레이드를 쉽게 만드는 습관**: 개인 설정은 `project.local.yaml`(`/settings --local <key>=<value>`)과
  `.claude/settings.local.json`에 두고, 템플릿 소유 파일은 되도록 고치지 마세요. 꼭 고쳐야 한다면 그 사실이 커밋
  메시지에 드러나게 해서 `git log --oneline -- .claude`로 찾을 수 있게 해 두세요.

---

## 업그레이드 전략

템플릿 업데이트를 가져오는 방법은 네 가지입니다. 여러분 저장소가 템플릿과 Git 이력을 공유하는지에 따라
고르세요. 어느 전략이든 **작업 브랜치에서** 진행하고, 업그레이드는 제품 변경과 섞지 말고 별도 커밋으로
남기는 것이 좋습니다.

### 전략 A — Git 원격 병합 (권장)

**이럴 때**: 템플릿을 clone하거나 fork해서 그 위에 여러분의 커밋을 쌓아 온 경우 — 즉 저장소가 템플릿과 이력을
공유하는 경우입니다. GitHub의 "Use this template"으로 만든 저장소는 템플릿과 이력을 공유하지 않으므로 전략
A2를 쓰세요.

```bash
# 템플릿을 원격 저장소로 추가합니다(한 번만).
git remote add template <이 템플릿 저장소의 URL>

# 새 버전을 가져옵니다.
git fetch template main

# 작업 브랜치를 만들고 병합합니다.
git switch -c chore/upgrade-ccss
git merge template/main
```

Git은 템플릿과 여러분이 **둘 다** 고친 파일에서만 충돌을 표시합니다. 충돌마다 여러분의 내용은 지키고 구조
변경은 받아들인 뒤 병합을 커밋하세요.

- 충돌이 가장 잦은 파일은 `CLAUDE.md`, `project.yaml`, `.claude/settings.json`, `.gitignore`입니다.
- `project.yaml`에서는 여러분의 값(`project.*`, `modes.rigor`, `modes.automation`, `stack.*`, `platform.*` 등)을
  모두 지키고, 템플릿 쪽 주석 변경만 받아들인 다음 `framework.version`과 `framework.last_upgraded`를 새 버전의
  절이 알려 주는 값으로 바꿉니다. `modes.rigor`가 대신 정하는 여섯 개 설정(`modes.review_mode`,
  `modes.workflow`, `docs.density`, `qa.level`, `modes.story_granularity`, `team.size`)은 여러분이 `/settings`로
  직접 정한 값이 아니라면 병합하면서 새로 적어 넣지 마세요. 적힌 값은 rigor 확장을 가립니다.
- `CLAUDE.md`의 `## Stack Version Reference` 아래 import 줄(`@docs/stack-reference/VERSION.md`)은 고정된 줄입니다.
  `/setup-stack`도 이 줄을 고치지 않으니 그대로 두세요.

**`fatal: refusing to merge unrelated histories`가 나오면** 저장소가 템플릿의 clone에서 시작하지 않은 것입니다(zip
다운로드, 새 `git init`, "Use this template" 등). `--allow-unrelated-histories`로 억지로 병합하지 마세요. 공통
조상이 없으면 Git이 템플릿의 **모든** 파일을 충돌로 표시해 수백 개 파일을 손으로 풀어야 합니다. 전략 A2를
쓰세요.

### 전략 A2 — 선택적 체크아웃 (이력을 공유하지 않는 경우)

**이럴 때**: Git은 쓰지만 템플릿과 공통 이력이 없는 경우입니다.

> **먼저 프레임워크 파일을 직접 고친 적이 있는지 확인하세요.** 아래 체크아웃은 `.claude/` 아래의 템플릿
> 파일을 **새 버전으로 바꿉니다.** 여러분이 *추가한* 파일은 남지만, 템플릿도 싣고 있는 파일에 한 수정은
> 덮어써집니다. 에이전트 정의, 디렉터 게이트, `.claude/settings.json`이 가장 자주 고치는 파일입니다.
>
> ```bash
> git log --oneline -- .claude    # 처음 들여온 커밋 말고도 나오면 직접 고친 파일이 있다는 뜻입니다
> ```
>
> 무언가 나온다면 아래의 되돌리기 단계를 건너뛰지 마세요.

```bash
git remote add template <이 템플릿 저장소의 URL>
git fetch template main
git switch -c chore/upgrade-ccss

# 템플릿 소유 경로를 새 버전으로 통째로 가져옵니다.
# 템플릿 파일을 덮어쓰거나 추가할 뿐, 여러분이 추가한 파일은 지우지 않습니다.
git checkout template/main -- .claude docs/stack-reference/README.md UPGRADING.md CHANGELOG.md

# 스킬 테스트 프레임워크를 쓰고 있다면 함께 가져옵니다.
git checkout template/main -- "CCSS Skill Testing Framework"

# 체크아웃은 스테이징만 하고 커밋하지 않습니다. 아직 잃은 것은 없고,
# 다음 명령으로 바뀐 프레임워크 파일을 모두 볼 수 있습니다.
git diff --cached --stat -- .claude

# 여러분의 버전을 지킬 파일은 하나씩 되돌립니다. 파일마다 명령을 따로 쓰는 것은
# 의도적입니다 — 파일마다 여러분의 버전과 새 버전 중 하나를 고르는 결정이기 때문입니다.
git checkout HEAD -- <직접 고쳐서 지킬 파일>

# 새 버전에서 없어진 템플릿 파일은 체크아웃으로 지워지지 않습니다.
# 여러분 쪽에만 있는 파일을 나열합니다 — 여러분이 추가한 파일과 템플릿이 없앤 파일이 함께 나옵니다.
git diff --name-only --diff-filter=D HEAD template/main -- .claude

git status   # 커밋하기 전에 바뀐 내용을 검토합니다
```

- **되돌린 파일은 여러분의 버전이 통째로 남습니다.** 새 버전이 그 파일에서 고친 내용은 함께 잃게 됩니다.
  가볍게 고친 파일이라면 새 버전을 받고 여러분의 수정을 그 위에 다시 적용하는 편이 대개 낫습니다.
  `git diff HEAD template/main -- <file>`로 무엇을 포기하게 되는지 확인할 수 있습니다.
- **`.claude/settings.json`**: 되돌리면 새 버전의 훅 등록과 거부 목록 변경을 잃습니다. 새 버전을 받은 뒤
  여러분이 추가했던 항목만 다시 넣으세요. 개인용 허용 항목은 애초에 `.claude/settings.local.json`에 두는 편이
  낫습니다.
- **템플릿이 없앤 파일**: 마지막 `git diff` 목록에서 그 버전 절의 "삭제된 파일"에 있는 경로만 `git rm`으로
  지웁니다. 여러분이 추가한 파일은 남기세요. 이름이 바뀐 스킬의 옛 디렉터리가 남아 있으면 Claude Code가 옛
  스킬을 여전히 실행할 수 있고, `/skill-test audit`은 그것을 카탈로그에 없는 스킬로 보고합니다.
- **`CLAUDE.md`, `.gitignore`**: 체크아웃하지 말고 diff를 보며 손으로 병합합니다.

  ```bash
  git diff HEAD template/main -- CLAUDE.md
  git diff HEAD template/main -- .gitignore
  ```

- **`project.yaml`**: 여러분의 설정이 들어 있으므로 **절대 체크아웃하지 마세요.** `CLAUDE.md`처럼 diff를 보고 손으로
  병합한 뒤 `framework.version`과 `framework.last_upgraded`를 갱신합니다.

  ```bash
  git diff HEAD template/main -- project.yaml
  ```

- `docs/stack-reference/VERSION.md`와 레지스트리 파일(`design/registry/entities.yaml`,
  `docs/registry/architecture.yaml`, `docs/architecture/tr-registry.yaml`)은 여러분의 데이터입니다. 체크아웃
  목록에 넣지 마세요.

### 전략 B — 특정 커밋만 체리픽

**이럴 때**: 전체 업데이트가 아니라 특정 수정 하나만 필요할 때입니다.

```bash
git remote add template <이 템플릿 저장소의 URL>
git fetch template main

# 원하는 커밋을 찾습니다.
git log --oneline template/main

# 그 커밋만 가져옵니다.
git cherry-pick <commit-sha>
```

스킬은 게이트 참조 파일, `CONTRACT.md`, 템플릿, 디렉터 게이트 파일을 서로 참조합니다. 가져오려는 커밋이 앞선
커밋에 기대고 있지 않은지 [CHANGELOG.md](CHANGELOG.md)와 커밋 내용을 먼저 확인하세요. 기능 하나를 통째로
가져와야 한다면 전략 A나 A2가 안전합니다.

### 전략 C — 파일 직접 복사

**이럴 때**: Git 없이 템플릿을 내려받아(zip 등) 쓰고 있는 경우입니다.

1. 새 버전을 여러분 저장소 옆에 내려받거나 clone합니다.
2. [파일 소유 구분](#파일-소유-구분)의 **템플릿 소유** 파일을 복사합니다. **`.claude/`는 통째로 복사하고 일부만
   골라 복사하지 마세요.** 스킬은 게이트 참조 파일, `CONTRACT.md`, 템플릿, 디렉터 게이트 파일을 서로 참조하므로,
   일부만 복사하면 없는 문서를 가리키는 스킬이 생깁니다. 그리고 그 실패는 복사할 때가 아니라 스킬을 실행할 때
   드러납니다.
3. 복사는 더하기만 합니다. 새 버전에서 없어진 파일은 그 버전 절의 "삭제된 파일" 목록을 보고 손으로 지웁니다.
4. **섞여 있음** 파일은 두 버전을 나란히 열고, 여러분의 내용을 지키면서 구조 변경만 옮깁니다.
5. **여러분의 데이터**와 **개인 파일**은 복사 대상에서 뺍니다. 특히 템플릿의 `project.yaml`과
   `docs/stack-reference/VERSION.md`를 여러분의 파일 위에 복사하지 마세요.

> 재귀 복사는 여러분이 고친 템플릿 파일을 경고 없이 덮어씁니다. 복사하기 전에 `diff -r`로 두 `.claude/`
> 디렉터리를 비교해 두세요.

---

## 0.1.0 (2026-09-27)

**첫 릴리스입니다.** 이전 CCSS 버전이 없으므로 이 버전으로 업그레이드할 대상은 없습니다. Claude Code Game
Studios v1.1.1(`7ed2c3e`)에서 포크했으며, 무엇이 달라졌는지는 [CHANGELOG.md](CHANGELOG.md)에 정리했습니다.
업스트림 프로젝트를 옮기려 한다면 [위의 절](#claude-code-game-studios-프로젝트의-마이그레이션은-지원하지-않습니다)을
먼저 읽으세요.

### 새로 시작하기

1. 템플릿을 clone합니다. 나중에 전략 A로 업그레이드하려면 clone으로 시작하는 것이 가장 편합니다.
2. 저장소에서 Claude Code를 열고 `/start`를 실행합니다. 지금 어디에 있는지(아이디어 전, 문제 영역, 명확한 제품
   구상, 기존 제품)를 묻고 `project.stage`, `modes.rigor`, `modes.automation`을 기록합니다.
3. `/setup-stack`으로 레이어별 스택과 버전, 코드 루트, 표면(`platform.surfaces`), 배포 방식
   (`release.distribution`), 지역(`compliance.regions`), 로케일(`localization.locales`)을 정합니다. 버전은 실시간
   소스에서 확인해 `docs/stack-reference/`에 기록합니다.
4. 막히면 `/help`가 다음 할 일을 알려 줍니다.

PyYAML은 선택 사항입니다. `python3 -m pip install --user pyyaml`로 설치하면 `validate-commit.sh`와
`validate-data-files.sh`가 YAML을 완전한 파서로 검사합니다. 없으면 구조 검사로 대신하며
`NOT CHECKED: full YAML parse (PyYAML unavailable)`를 출력합니다. 운영체제별 설치 방법은
[.claude/docs/setup-requirements.md](.claude/docs/setup-requirements.md)에 있습니다.

자세한 안내는 [README.md](README.md), [.claude/docs/quick-start.md](.claude/docs/quick-start.md),
[docs/WORKFLOW-GUIDE.md](docs/WORKFLOW-GUIDE.md)에 있습니다.

### 이 버전의 `project.yaml`

- 템플릿의 `project.yaml`에는 `schema_version`, `framework.version`(이 버전),
  `framework.last_upgraded: 2026-09-27`과 주석만 들어 있고 `modes:` 블록은 없습니다.
- `/start`가 `modes.rigor`와 `modes.automation`을, `/setup-stack`이 `stack.*`, `platform.*`, `release.*`,
  `privacy.*`, `compliance.*`, `localization.*`, `naming.*`, `commands.*`를 채웁니다.
- 기본값: "Unset on an unconfigured project: `modes.rigor` defaults to `minimal`, which resolves `review_mode` to
  `solo`." 여러 사람이 함께 만드는 서비스라면 `/settings modes.rigor=standard`(또는 `full`) 한 번으로 올릴 수
  있습니다. `/start`는 만들려는 제품의 성격을 듣고 적절한 수준을 추천합니다.

### 다음 업그레이드를 위해 지금 해 둘 것

- 개인 설정은 `project.local.yaml`과 `.claude/settings.local.json`에 둡니다.
- `.github/`의 이슈·PR 템플릿과 `CODEOWNERS`를 여러분 제품 저장소에 맞게 바꿉니다.
- 템플릿 소유 파일을 고쳤다면 그 사실을 커밋 메시지에 남겨 둡니다.

---

## 업그레이드한 뒤 확인할 것

1. `project.yaml`의 `framework.version`과 `framework.last_upgraded`를 새 버전의 절이 알려 준 값으로 바꿨는지
   확인합니다.
2. 새 Claude Code 세션을 열어 세션 시작 배너(`Claude Code Service Studios`)와 경고를 확인합니다. 설정 값 오류,
   선언되지 않은 코드 루트, 스택 레퍼런스 상태가 여기에 나타납니다.
3. `/settings`로 최종 적용된 설정과 각 값의 출처를 확인합니다. 새 버전에서 허용 값이 바뀐 키가 있으면 여기서
   드러납니다.
4. `/skill-test static all`로 모든 스킬의 구조를 점검합니다. 직접 고친 스킬은 특히 새 버전과 비교해 다시
   읽어 보세요. 설정을 다른 방식으로 읽는 스킬은 오류를 내지 않고, 기본값 분기로 조용히 잘못 동작합니다.
   스킬 테스트 프레임워크를 함께 쓰고 있다면 `/skill-test audit`으로 카탈로그와 파일이 일치하는지도 봅니다.
5. `/help`나 `/project-stage-detect`로 워크플로 카탈로그가 여러분의 산출물을 여전히 알아보는지 확인합니다.
   새 버전이 템플릿 헤딩 같은 기계 계약을 바꿨다면, 그 버전의 절이 여러분 문서에서 무엇을 고칠지 알려 줍니다.
6. 업그레이드는 제품 변경과 섞지 말고 별도 커밋으로 남깁니다(예: `chore: upgrade CCSS framework`).

---

## 버전별 절의 형식

다음 버전부터는 버전마다 아래 형식의 절이 이 문서에 추가됩니다. 위의 전략은 이 절을 기준으로 움직입니다.

- **릴리스 날짜**, **커밋 범위**, **핵심 주제**
- `### 바뀐 것` — 영역별 변경 요약표
- `### 덮어써도 안전한 파일` — 여러분의 내용이 없는 템플릿 파일
- `### 주의해서 병합할 파일` — 섞여 있는 파일, 그리고 템플릿 헤딩·설정 키·판정 토큰 같은 계약이 바뀌었을 때
  여러분의 문서와 설정에서 고칠 내용
- `### 삭제된 파일` — 전략 A2와 C에서 손으로 지울 경로
- `### 업그레이드 후` — 확인 절차와 `project.yaml`에 적을 `framework.version`, `framework.last_upgraded` 값
