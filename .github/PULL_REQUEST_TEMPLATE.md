## 요약

이 PR이 무엇을 왜 바꾸는지 한두 문장으로 적어 주세요.

## 관련 이슈·근거

- 관련 이슈: #
- 근거가 되는 스펙·스토리·태스크(해당하면): 예) 재현한 스킬과 입력, 인용한 규칙 파일과 헤딩, 태스크 ID

## 변경 유형

- [ ] 새 에이전트
- [ ] 새 스킬
- [ ] 훅 또는 스크립트
- [ ] 규칙
- [ ] 템플릿
- [ ] 디렉터 게이트
- [ ] 설정 키
- [ ] 버그 수정
- [ ] 문서 개선
- [ ] 기타:

## 변경 내용

-
-
-

## 테스트와 증거

무엇을 어떻게 시험했고 결과가 어땠는지 적어 주세요. 실행한 명령과 출력(필요하면 일부만), 스킬이 만든 산출물의
경로를 붙이면 리뷰가 빨라집니다.

- Claude Code 세션에서 실행한 내용:
- `/skill-test` 결과:
- 훅·스크립트를 시험한 fixture와 결과:

## 체크리스트

**공통**

- [ ] Claude Code 세션에서 처음부터 끝까지 실행해 보았고, 시험한 내용과 결과를 위에 적었습니다
- [ ] 비밀 정보, 자격 증명, 실제 개인정보가 들어 있지 않습니다(예시 토큰은 `EXAMPLE`로 끝납니다)
- [ ] 하드코딩된 절대 경로나 특정 플랫폼만 가정한 코드가 없습니다
- [ ] 템플릿 헤딩, 판정 토큰, 설정 키 같은 기계 계약 문자열은 영어 그대로이며, 바꿨다면 그것을 읽는 모든 곳을
      이 PR에서 함께 고쳤습니다
- [ ] 옛 이름을 별칭이나 "예전 이름" 주석으로 남기지 않았습니다
- [ ] 예시는 서비스 예시(가상 제품 Moa)를 씁니다

**스킬·에이전트를 바꿨다면**

- [ ] 바꾼 스킬마다 `/skill-test static <name>`이 통과합니다
- [ ] 바꾼 스킬과 에이전트마다 `/skill-test spec <name>`이 통과합니다
- [ ] `CCSS Skill Testing Framework/`의 `catalog.yaml` 항목과 스펙을 추가하거나 갱신했습니다
- [ ] 새 스킬은 `.claude/skills/<name>/SKILL.md` 형식이고, 디렉터리 이름과 frontmatter `name`이 같습니다
- [ ] 새 에이전트는 `.claude/rules/skill-authoring.md` § Agent file skeleton의 헤딩 순서를 따르고, 부모 에이전트의
      `Delegates to:`에 추가되어 있습니다
- [ ] 파일을 쓰는 스킬은 쓰기 전마다 "May I write this to `<path>`?"를 묻습니다

**훅·스크립트를 바꿨다면**

- [ ] `grep -E`만 쓰고(`grep -P` 없음) macOS bash 3.2에서 동작합니다
- [ ] `jq`나 Python이 없어도 정상 종료하며, 하지 못한 검사는 `NOT CHECKED`로 밝힙니다
- [ ] `bash -n`이 통과하고, 실제 저장소가 아닌 fixture에서 시험했습니다
- [ ] 스크립트는 관찰만 출력하고 판정은 하지 않습니다

**레퍼런스 문서**

- [ ] 해당하는 문서를 갱신했습니다: `.claude/docs/agent-roster.md`, `.claude/docs/skills-reference.md`,
      `.claude/docs/rules-reference.md`, `.claude/docs/hooks-reference.md`, `.claude/docs/model-tiers.md`,
      `.claude/docs/director-gates.md`, `.claude/docs/effects-map.md`, `.claude/docs/workflow-catalog.yaml`
- [ ] 에이전트·스킬·규칙·템플릿·게이트 개수가 바뀌었다면 `README.md`, `.claude/docs/quick-start.md`, 루트
      `CLAUDE.md`를 함께 고쳤습니다

**커밋**

- [ ] 커밋 메시지가 Conventional Commits 형식입니다(`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:` 등)
