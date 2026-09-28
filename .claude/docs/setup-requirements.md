# 설치 요구 사항

Claude Code Service Studios(CCSS)를 제대로 쓰려면 몇 가지 도구가 필요합니다. 도구가
빠져도 훅이 세션을 멈추지는 않습니다. 대신 실행할 수 없는 검사를 건너뛰고, 건너뛰었다는
사실을 `NOT CHECKED` 줄로 알려 줍니다. 검사가 통과한 것처럼 보이지는 않지만, 그만큼
안전장치가 줄어든다는 뜻입니다.

## 기본 도구 (모든 프로젝트)

아래 도구는 어떤 스택을 고르든 설치해 두십시오.

| 도구 | 쓰는 곳 | 설치 |
| ---- | ---- | ---- |
| **Git** | 버전 관리. `session-start.sh`가 브랜치와 최근 커밋을 보여 주고, `validate-commit.sh`·`validate-push.sh`가 커밋·푸시 직전에 변경 내용을 검사합니다 | [git-scm.com](https://git-scm.com/) |
| **Claude Code** | 에이전트 CLI. 스킬·에이전트·훅을 모두 여기서 실행합니다 | [아래 참고](#claude-code-설치) |
| **Bash** | 모든 훅(`.claude/hooks/`)과 스크립트(`.claude/scripts/`), 상태 표시줄(`.claude/statusline.sh`) | macOS·Linux 기본 포함. Windows는 Git for Windows의 Git Bash |
| **Python 3** | 설정 엔진 `yaml-helper.sh`(설정이 필요한 스킬은 모두 첫 줄에서 `resolve_config`로 `project.yaml`을 읽습니다), `artifact-check.sh`(`/help`, `/gate-check`, `/project-stage-detect`의 산출물 관찰), `project-coherence.sh`, 커밋·데이터 파일 훅의 JSON/YAML 검사와 커밋 메시지 해석 | [python.org](https://www.python.org/) 또는 패키지 관리자 |
| **jq** | 훅 입력(JSON) 파싱: `validate-commit.sh`, `validate-push.sh`, `validate-data-files.sh`, `validate-skill-change.sh`, `log-agent.sh`, `log-agent-stop.sh`, `session-stop.sh`, `notify.sh`, `.claude/statusline.sh` | [아래 참고](#jq-설치) |

이 프레임워크의 Python 코드는 표준 라이브러리만 씁니다. 설정 엔진과 `artifact-check.sh`는
YAML 파서를 직접 구현해 쓰므로 별도 패키지가 필요 없습니다. 훅은 `python` → `python3` → `py` 순서로
찾은 첫 번째 **Python 3** 인터프리터를 사용합니다(Python 2나 Windows 스토어 스텁은 건너뜁니다).

### PyYAML (선택)

PyYAML을 설치하면 `validate-commit.sh`와 `validate-data-files.sh`가 YAML 파일
(`project.yaml`, `docs/api/**`, 레지스트리, 로케일, `.github/workflows/*` 등)을 **완전한
파서로** 검사합니다. 없으면 표준 라이브러리 기반의 구조 검사(탭 들여쓰기, 괄호·따옴표 짝,
`:` 누락)로 대신하고 `NOT CHECKED: full YAML parse (PyYAML unavailable)` 줄을 출력합니다.
PyYAML이 없다는 이유로 커밋이 막히는 일은 없습니다.

PyYAML은 **훅이 실제로 고르는 인터프리터**(위 순서의 첫 번째 Python 3)에 설치해야 합니다.
[설치 확인](#설치-확인)의 명령으로 어느 인터프리터가 선택되는지 먼저 확인하십시오.

## 스택별 선택 도구

`/setup-stack`에서 고른 스택과 표면(`platform.surfaces`)에 따라 필요한 도구가 달라집니다.
해당하지 않는 도구는 설치하지 않아도 됩니다.

| 도구 | 필요한 경우 | 쓰는 곳 | 설치 |
| ---- | ---- | ---- | ---- |
| **Node.js + pnpm** | 웹(Next.js, Nuxt), JS/TS 백엔드(NestJS, Express, Fastify), React Native·Expo | `commands.test`·`commands.lint`·`commands.typecheck` 등 `project.yaml`의 명령, `/test-setup`이 만드는 러너, Playwright | [nodejs.org](https://nodejs.org/) 또는 `fnm`·`nvm` 같은 버전 관리자, `npm install -g pnpm` |
| **Docker** | 로컬 PostgreSQL·Redis·메시지 큐, 컨테이너 이미지 빌드 | 로컬 개발 환경, 실제 DB를 쓰는 통합·계약 테스트, k6를 컨테이너로 돌리는 `/load-test` | [Docker Desktop](https://www.docker.com/products/docker-desktop/) 또는 호환 런타임 |
| **Playwright 브라우저** | 웹 표면 | `/test-setup`이 만드는 캡처 스크립트 `tests/e2e/capture.spec.ts`와 E2E 테스트. `/dev-story`의 실행·관찰 단계가 이 스크립트로 스크린샷 증거를 남깁니다 | `npx playwright install` (Linux는 `npx playwright install --with-deps`) |
| **Xcode + iOS 시뮬레이터** | iOS 표면 (macOS 전용) | 실행·관찰 단계의 `xcrun simctl openurl booted <deep-link>`, `xcrun simctl io booted screenshot <file>` | Mac App Store의 Xcode (Command Line Tools만으로는 시뮬레이터가 없습니다) |
| **Android SDK + adb** | Android 표면 | 실행·관찰 단계의 `adb shell am start -W -a android.intent.action.VIEW -d <deep-link>`, `adb exec-out screencap -p > <file>` | [Android Studio](https://developer.android.com/studio) 또는 SDK의 `platform-tools` |
| **k6** | 부하 테스트 | `/load-test`의 smoke·load·stress·spike·soak 프로필을 스테이징에 실행 | [grafana.com/docs/k6](https://grafana.com/docs/k6/latest/set-up/install-k6/) |

Flutter SDK, JDK·Gradle, Python 가상 환경처럼 스택 자체가 요구하는 도구는 `/setup-stack`이
기록한 `docs/stack-reference/VERSION.md`의 고정 버전을 따르십시오.

## Claude Code 설치

Claude Code는 Pro, Max, Team, Enterprise 요금제나 Console(API) 계정이 있어야 쓸 수 있습니다.
공식 권장 방식은 네이티브 설치 프로그램이며, 백그라운드에서 자동 업데이트됩니다.

**macOS, Linux, WSL**:
```bash
curl -fsSL https://claude.ai/install.sh | bash
```

**Windows PowerShell**:
```powershell
irm https://claude.ai/install.ps1 | iex
```

**다른 방법**:
```bash
brew install --cask claude-code          # Homebrew (자동 업데이트 안 됨: brew upgrade claude-code)
winget install Anthropic.ClaudeCode      # WinGet (자동 업데이트 안 됨: winget upgrade Anthropic.ClaudeCode)
npm install -g @anthropic-ai/claude-code # npm (Node.js 22 이상, sudo 없이 실행)
```

설치 후 새 터미널에서 `claude --version`으로 버전이 출력되는지, `claude doctor`로 설치 상태와
설정 파일 오류가 없는지 확인하십시오.

## jq 설치

**Windows** (셋 중 하나):
```
winget install jqlang.jq
choco install jq
scoop install jq
```

**macOS**:
```
brew install jq
```

**Linux**:
```
sudo apt install jq     # Debian/Ubuntu
sudo dnf install jq     # Fedora
sudo pacman -S jq       # Arch
```

## Python 3와 PyYAML 설치

**macOS**:
```
brew install python     # 또는 xcode-select --install 로 Command Line Tools의 python3 사용
```

**Linux**: 대부분의 배포판에 `python3`가 기본으로 들어 있습니다. PyYAML은 배포판 패키지로
설치하는 편이 안전합니다.
```
sudo apt install python3-yaml       # Debian/Ubuntu
sudo dnf install python3-pyyaml     # Fedora
```

**Windows**: [python.org](https://www.python.org/downloads/windows/) 설치 프로그램으로 설치하면
`py` 런처가 함께 설치되며, 훅의 인터프리터 탐색 순서에 `py`가 포함되어 있습니다.
```
py -m pip install pyyaml
```

**pip로 설치할 때**: `python3 -m pip install --user pyyaml`을 쓰십시오. Homebrew Python처럼
`externally-managed-environment` 오류(PEP 668)로 설치를 거부하는 환경이라면, Linux에서는 위의
배포판 패키지를 쓰십시오. macOS에서는 PyYAML 없이 두어도 됩니다(구조 검사로 대체됩니다).
굳이 설치하려면 `--break-system-packages` 옵션이 시스템 패키지 관리와 충돌할 수 있다는 점을
이해한 뒤 `--user`와 함께 쓰십시오.

## 플랫폼별 참고

### Windows
- 훅은 `settings.json`에 `bash "<경로>"` 형태로 등록되어 있으므로 **Git for Windows**(Git Bash)가
  필요합니다. Git for Windows 설치 프로그램의 기본값대로 설치하면 `bash`가 PATH에 잡힙니다.
- Git for Windows가 없으면 Claude Code는 셸 도구로 PowerShell을 쓰지만, 이 경우에도 훅은
  `bash`로 실행되므로 Git Bash가 있어야 합니다. Claude Code가 Git Bash를 찾지 못하면
  설정 파일의 `env`에 `CLAUDE_CODE_GIT_BASH_PATH`를 지정하십시오(JSON 값 예:
  `"C:\\Program Files\\Git\\bin\\bash.exe"`).
- 리눅스 도구 체인(Docker, k6 등)을 많이 쓰거나 셸 샌드박스가 필요하면 WSL 2 안에 Claude
  Code를 설치해 쓰는 것이 좋습니다.

### macOS / Linux
- Bash가 기본으로 들어 있습니다. macOS의 기본 Bash 3.2로도 모든 훅과 스크립트가 동작합니다.
- 패키지 관리자로 `jq`와 Python 3를 설치하면 모든 훅 기능을 쓸 수 있습니다.
- iOS 시뮬레이터 기반 실행·관찰은 macOS에서만 가능합니다.

## 설치 확인

아래 명령으로 기본 도구를 확인하십시오.

```bash
git --version          # Git 버전
bash --version         # Bash 버전
claude --version       # Claude Code 버전
python3 --version      # Python 3 버전 (Windows는 py --version)
jq --version           # jq 버전
```

훅이 어느 Python 인터프리터를 쓰는지, 그 인터프리터에 PyYAML이 있는지는 다음 명령으로
확인합니다. 훅과 같은 순서로 찾습니다.

```bash
for c in python python3 py; do
  if command -v "$c" >/dev/null 2>&1 && "$c" -c 'import sys; sys.exit(0 if sys.version_info[0] >= 3 else 1)' 2>/dev/null; then
    echo "hook interpreter: $c"
    "$c" -c 'import yaml; print("PyYAML", yaml.__version__)' 2>/dev/null || echo "PyYAML: not installed"
    break
  fi
done
```

스택별 도구는 해당하는 것만 확인하십시오.

```bash
node --version && pnpm --version     # 웹·JS/TS 백엔드·React Native
docker --version                     # 로컬 인프라
npx playwright --version             # 웹 캡처·E2E
xcrun simctl list devices booted     # iOS 시뮬레이터 (macOS)
adb version                          # Android
k6 version                           # 부하 테스트
```

## 도구가 없을 때 일어나는 일

| 빠진 도구 | 영향 |
| ---- | ---- |
| **Python 3** | 설정 엔진이 `project.yaml`을 읽지 못해 모든 스킬이 설정을 미설정으로 보고 `.claude/docs/config-resolution.md`의 기본값으로 동작합니다. `artifact-check.sh`가 인터프리터를 찾지 못하고 종료하므로 `/help`, `/gate-check`, `/project-stage-detect`가 산출물 관찰 결과를 얻지 못합니다. 커밋·데이터 파일 훅은 JSON/YAML 검사, PRD 섹션 검사, 커밋 메시지 검사를 `NOT CHECKED`로 보고합니다. 시크릿과 자격 증명 파일 차단은 Python 없이도 동작합니다. |
| **PyYAML** | YAML 검사가 구조 검사로 대체되고 `NOT CHECKED: full YAML parse (PyYAML unavailable)`가 출력됩니다. 구조 검사가 잡지 못하는 문법 오류(예: 들여쓰기 구조가 어긋난 매핑)는 그대로 커밋될 수 있습니다. |
| **jq** | 훅이 grep 기반 대체 파서로 입력을 읽습니다. 대부분 그대로 동작하지만 이스케이프된 따옴표나 Windows 경로가 섞인 입력에서는 정확도가 떨어집니다. `validate-commit.sh`는 jq가 없으면 Python으로 명령을 해석합니다. |
| **Python 3와 jq 모두** | 훅은 계속 실행되고(exit 0) 시크릿·자격 증명 파일 차단도 동작하지만, 설정 해석과 파일 형식 검사는 사실상 모두 빠집니다. 안전망 없이 작업하는 상태입니다. |
| **스택별 선택 도구** | 해당 표면의 실행·관찰 단계가 `Run result: NOT VERIFIED — <이유>`로 기록되고, UI·E2E 스토리에 필요한 스크린샷·트레이스 증거를 남길 수 없습니다(예: 웹 캡처 스크립트가 없으면 `Run result: NOT VERIFIED — no capture script (run /test-setup)`). |

## 선택 성능 설정

CCSS는 아래 설정에 값을 **싣지 않습니다**. 가장 알맞은 값이 사용자의 컴퓨터, Claude 요금제,
작업 방식에 따라 달라서, 여기에 커밋한 값은 모든 사용자가 모르고 물려받는 추측이 되기
때문입니다. 원하는 값은 gitignore된 개인 설정 파일 `.claude/settings.local.json`에 넣으십시오.

| 설정 | 하는 일 | 바꿀 때 |
| ---- | ---- | ---- |
| `promptCacheTtl` | 메인 대화의 프롬프트 캐시 수명(`5m` 또는 `1h`). | 쉬었다가 이어 가는 긴 세션이 많다면 `1h`로 올리십시오. 캐시가 쉬는 시간을 넘기면 컨텍스트를 다시 보내지 않아도 됩니다. API 키나 클라우드 제공자를 쓰면 기본값이 5분입니다. |
| `subagentPromptCacheTtl` | 서브에이전트 등 메인 대화 밖 요청의 캐시 수명(`5m` 또는 `1h`). | `team-*` 스킬과 디렉터 게이트가 서브에이전트를 반복해서 띄우는 이 프레임워크에서는 올릴 가치가 있습니다. 서브에이전트는 구독 요금제에서도 기본 5분입니다. |
| `autoCompactWindow` | 컨텍스트가 얼마나 찼을 때 자동 압축할지. | 작업 도중 압축이 자주 끼어들면 낮추고, 압축 횟수를 줄이고 대화 기록을 더 오래 유지하고 싶으면 올리십시오. |
| `skillListingBudgetFraction` | 스킬 목록이 차지할 수 있는 컨텍스트 비율. | CCSS는 스킬이 많아 목록이 작지 않습니다. 작업 공간을 더 확보하려면 낮추십시오. 설명 길이만 줄이려면 `skillListingMaxDescChars`를 쓰십시오. |

두 캐시 수명 설정은 Claude Code v2.1.242 이상에서 동작합니다.

`sandbox.enabled`는 셸 명령을 파일 시스템과 네트워크로부터 격리합니다. 켜 둘 가치가
있지만 **macOS, Linux, WSL 2에서만** 동작하며 Windows 네이티브 환경에서는 쓸 수 없습니다.

### CCSS가 싣는 설정

`.claude/settings.json`의 `permissions.defaultMode`는 의도적으로 `default`입니다. Claude Code가
행동하기 전에 먼저 묻게 만드는 설정이며, 이 프레임워크의 모든 승인 절차("May I write this to
[filepath]?")가 여기에 기대고 있습니다. 프로젝트 설정은 사용자 설정(`~/.claude/settings.json`)보다
우선하므로, 사용자 설정에서 `acceptEdits`를 켜 두었더라도 이 프로젝트에서는 `default`가
유지됩니다. 그렇지 않으면 협업 프로토콜이 사용자 모르게 꺼지고, 에이전트가 승인받지 않은 파일을
쓰게 됩니다.

정말 바꾸고 싶다면 우선순위가 더 높은 `.claude/settings.local.json`에서 바꾸거나, 세션마다
`--permission-mode`를 지정하십시오. `auto`와 `bypassPermissions`는 프로젝트·로컬 설정 파일에서는
적용되지 않습니다. 무엇을 끄는지 먼저 이해하고 결정하십시오.

같은 파일의 `deny` 목록은 프로덕션·공유 인프라를 바꾸는 명령(`terraform apply`,
`kubectl apply`, `helm upgrade`, `vercel --prod`, `fly deploy`, `eas submit` 등), 파괴적인
DB 명령, `sudo`, 서명 키·인증서 파일 읽기를 막습니다. 이런 작업은 에이전트가 제안하고
사람이 직접 실행하는 것이 이 프레임워크의 원칙입니다.

## 권장 편집기

Claude Code는 어떤 편집기와도 함께 쓸 수 있지만, 이 템플릿은 다음 환경을 기준으로 다듬었습니다.
- **VS Code**와 Claude Code 확장
- **JetBrains IDE**와 Claude Code 플러그인
- **Cursor** (VS Code 확장 호환)
- 터미널에서 실행하는 Claude Code CLI
