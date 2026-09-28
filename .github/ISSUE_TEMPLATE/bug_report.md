---
name: 버그 신고
about: 템플릿의 스킬, 에이전트, 훅, 스크립트, 규칙, 문서가 기대한 대로 동작하지 않을 때
title: "[Bug] "
labels: bug
assignees: ''
---

<!-- 보안 취약점은 이 양식이 아니라 SECURITY.md의 비공개 신고 절차를 따라 주세요. -->
<!-- 붙여 넣는 출력과 설정에서 API 키, 토큰, 개인정보는 반드시 지워 주세요. -->

## 설명

무엇이 잘못되었는지 명확하게 적어 주세요.

## 영향받는 구성 요소

- [ ] 스킬(어느 것?): `/`
- [ ] 에이전트(어느 것?):
- [ ] 훅(어느 것?): `.claude/hooks/`
- [ ] 스크립트(어느 것?): `.claude/scripts/`
- [ ] 규칙(어느 것?): `.claude/rules/`
- [ ] 디렉터 게이트(어느 것?):
- [ ] 템플릿(어느 것?): `.claude/docs/templates/`
- [ ] 설정 키 또는 `resolve_config` 출력(어느 것?):
- [ ] 워크플로 카탈로그·단계 판정(`/help`, `/gate-check`, `/project-stage-detect`)
- [ ] 스킬 테스트 프레임워크(`CCSS Skill Testing Framework/`)
- [ ] 문서
- [ ] 기타:

## 재현 절차

1. 이 템플릿을 쓰는 프로젝트에서 Claude Code를 엽니다
2. `/<skill> <인자>`를 실행하거나, `<agent>`를 호출하거나, 훅이 걸리는 동작(예: `git commit`)을 합니다
3. ...
4. 오류나 잘못된 결과를 확인합니다

## 기대한 동작

어떻게 동작해야 한다고 생각했는지 적어 주세요. 근거가 되는 문서가 있다면 파일과 헤딩을 함께 적어 주세요.

## 실제 동작

실제로 무슨 일이 일어났는지 적어 주세요. 오류 메시지, 훅 출력(`BLOCKED`, `NOT CHECKED` 줄 포함), 잘못 만들어진
산출물의 경로를 붙여 주세요.

## 설정

관련 있는 설정을 적어 주세요. `/settings` 출력이나 스킬이 출력한 `=== CCSS Config ... ===` 블록을 붙여도 됩니다.

- `project.stage`:
- `modes.rigor` / `modes.review_mode` / `modes.automation`:
- `platform.surfaces`:
- 관련 스택 레이어(`stack.layers.*`)와 코드 루트:
- `project.local.yaml` 사용 여부: 예 / 아니오

## 환경

- **OS**: (예: macOS 15, Ubuntu 24.04, Windows 11)
- **셸**: (예: zsh, bash 3.2, Git Bash)
- **Claude Code 버전**: (`claude --version` 출력)
- **권한 모드**: (예: default, acceptEdits)
- **프레임워크 버전**: (`project.yaml`의 `framework.version`)
- **jq 설치 여부**: 예 / 아니오
- **Python 3 / PyYAML 설치 여부**: 예 / 아니오

## 추가 정보

스크린샷, 터미널 출력, 관련 있는 세션 로그 일부(`production/session-logs/`) 등 도움이 될 만한 내용을 붙여 주세요.
