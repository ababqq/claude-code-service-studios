# 스킬 흐름도

7단계 파이프라인에서 스킬이 어떤 순서로 이어지는지, 각 스킬이 무엇을 읽고 무엇을 남기는지 그림으로 보여 줍니다.
단계별 설명과 게이트 기준은 [WORKFLOW-GUIDE.md](WORKFLOW-GUIDE.md)에, 단계와 스텝의 원본 정의는
`.claude/docs/workflow-catalog.yaml`에 있습니다. 그림과 카탈로그가 다르면 카탈로그가 맞습니다.

## 그림 읽는 법

| 모양 | 뜻 |
|------|----|
| 사각형 `["/스킬"]` | 스킬 실행 |
| 원통 `[("path")]` | 디스크에 남는 산출물 |
| 마름모 `{"…"}` | 판정 또는 분기 |
| 육각형 `{{"/gate-check …"}}` | 단계 게이트 |
| 점선 화살표 | 선택 스텝이거나 조건부 흐름 |
| 괄호 안의 `standard · full`, `UI`, `백엔드`, `개인정보`, `다국어` | 그 티어나 조건에서만 필수 |

스킬 이름 아래의 대문자 ID(예: `TD-ADR`)는 그 스킬이 호출하는 디렉터 게이트입니다. 리뷰 모드에 따라 건너뛸 수 있습니다
([리뷰 모드](#리뷰-모드와-디렉터-게이트) 참고).

---

## 전체 파이프라인

### 한눈에 보기

```mermaid
flowchart LR
    DIS["1 Discovery<br/>탐색"] -->|"/gate-check definition"| DEF["2 Definition<br/>기획"]
    DEF -->|"/gate-check architecture"| ARC["3 Architecture<br/>아키텍처"]
    ARC -->|"/gate-check validation"| VAL["4 Validation<br/>검증"]
    VAL -->|"/gate-check build"| BLD["5 Build<br/>구축"]
    BLD -->|"/gate-check hardening"| HRD["6 Hardening<br/>안정화"]
    HRD -->|"/gate-check launch"| LCH["7 Launch<br/>출시"]
    LCH -->|"릴리스마다 반복 · 게이트 없음"| LCH
```

`/gate-check`의 인자는 들어가려는 단계입니다. `Launch`는 종착 단계이며, 이후의 릴리스는
`production/releases/<version>/`의 기록 세트로 추적합니다.

### 단계별 핵심 스킬과 산출물

```mermaid
flowchart TD
    subgraph P1["1 Discovery"]
        direction TB
        p1a["/start"] --> p1b["/brainstorm"]
        p1b --> p1c[("design/product/product-brief.md<br/>또는 one-pager.md")]
        p1d["/setup-stack"] --> p1e[("project.yaml stack.*<br/>docs/stack-reference/")]
        p1f["/prototype"] -.-> p1g[("prototypes/*-concept/REPORT.md")]
    end
    subgraph P2["2 Definition"]
        direction TB
        p2a["/map-features"] --> p2b[("design/product/feature-map.md")]
        p2c["/write-prd · /prd-review"] --> p2d[("design/prd/*.md<br/>design/prd/reviews/")]
        p2e["/review-all-prds"] --> p2f[("prd-cross-review-*.md")]
    end
    subgraph P3["3 Architecture"]
        direction TB
        p3a["/create-architecture"] --> p3b[("architecture.md · docs/ops/slo.md")]
        p3c["/architecture-decision"] --> p3d[("docs/architecture/adr-*.md")]
        p3e["/api-design · /data-model"] --> p3f[("docs/api/ · docs/data/")]
        p3g["/test-setup"] --> p3h[("tests/ · CI 워크플로")]
    end
    subgraph P4["4 Validation"]
        direction TB
        p4a["/design-language · /ux-design · /ux-review"] --> p4b[("design/brand/ · design/ux/")]
        p4c["/create-epics · /create-stories · /sprint-plan"] --> p4d[("production/epics/ · production/sprints/")]
        p4e["/walking-skeleton"] --> p4f[("production/walking-skeleton/report-*.md")]
    end
    subgraph P5["5 Build"]
        direction TB
        p5a["/story-readiness → /dev-story → /story-done"] --> p5b[("코드 · 테스트<br/>production/qa/evidence/")]
        p5c["/smoke-check"] --> p5d[("production/qa/smoke-*.md")]
    end
    subgraph P6["6 Hardening"]
        direction TB
        p6a["/team-hardening · /security-audit · /team-qa"] --> p6b[("production/qa/ · production/security/")]
        p6c["/changelog · /release-notes · /smoke-check (릴리스 후보) · /release-checklist · /rollout-plan · /launch-checklist"] --> p6d[("production/releases/*/")]
    end
    subgraph P7["7 Launch"]
        direction TB
        p7a["/team-release"] --> p7b[("release-record.md")]
        p7c["/incident · /postmortem · /hotfix · /team-growth"]
        p7d["/retrospective release"]
    end
    P1 -->|"/gate-check definition"| P2
    P2 -->|"/gate-check architecture"| P3
    P3 -->|"/gate-check validation"| P4
    P4 -->|"/gate-check build"| P5
    P5 -->|"/gate-check hardening"| P6
    P6 -->|"/gate-check launch"| P7
```

---

## Discovery → Definition

문제를 정리하고, 스택을 고정하고, 제품을 기능과 PRD로 나누는 흐름입니다.

```mermaid
flowchart TD
    start["/start<br/>A · B · C · D"] --> bs["/brainstorm<br/>PD-PRINCIPLES · TD-FEASIBILITY · DM-SCOPE"]
    start -.->|"D 기존 제품"| adopt["/adopt<br/>(기존 프로젝트 도입 참고)"]
    bs --> tier{"modes.workflow"}
    tier -->|"minimal"| op[("design/product/one-pager.md")]
    tier -->|"standard · full"| pb[("design/product/product-brief.md")]
    pb --> pr1["/prd-review<br/>(브리프 검토)"]
    pr1 --> log1[("design/product/reviews/*-review-log.md")]
    bs -.->|"가장 위험한 가정"| proto["/prototype<br/>clickable · fake-door · concierge · code"]
    proto --> rep[("prototypes/*-concept/REPORT.md")]
    rep --> pv{"판정"}
    pv -->|"PIVOT · KILL"| bs
    pv -->|"PROCEED"| ss
    bs --> ss["/setup-stack<br/>결정된 레이어만 · 버전은 실시간 출처로"]
    ss --> pin[("project.yaml stack.pinned_on<br/>docs/stack-reference/VERSION.md")]
    op --> g1{{"/gate-check definition"}}
    log1 --> g1
    pin -.-> g1
    g1 -->|"minimal"| g2
    g1 -->|"standard · full"| mf["/map-features<br/>TD-DOMAIN-BOUNDARY · PD-FEATURE-MAP · DM-SCOPE"]
    mf --> fm[("design/product/feature-map.md")]
    fm --> wp["/write-prd feature<br/>PD-PRD-ALIGN"]
    wp --> prd[("design/prd/feature.md<br/>+ entities.yaml · tracking-plan.md")]
    prd --> prr["/prd-review design/prd/feature.md"]
    prr --> rv{"판정"}
    rv -->|"NEEDS REVISION · MAJOR REVISION NEEDED"| wp
    rv -->|"APPROVED"| next{"남은 MVP 기능?"}
    next -->|"있음"| wp
    next -->|"없음"| rap["/review-all-prds<br/>(full 필수 · standard 권장)"]
    rap --> cr[("design/prd/reviews/prd-cross-review-*.md")]
    prd -.-> cc["/consistency-check"]
    fm -.-> uj["/ux-design journey"]
    uj -.-> ujd[("design/product/user-journey.md")]
    cr --> g2{{"/gate-check architecture"}}
    pin -.->|"standard · full 필수"| g2
```

`minimal`에서는 one-pager가 기획 기록이므로 기능 맵과 PRD가 없고, `/gate-check architecture`는 메모와 함께 `PASS`를
돌려줍니다.

### `/write-prd` 한 건의 흐름

```mermaid
flowchart TD
    in1[("product-brief.md · feature-map.md")] --> wp["/write-prd feature"]
    in2[("의존하는 PRD들")] --> wp
    wp --> sk[("템플릿과 같은 제목의 뼈대 작성<br/>design/prd/feature.md")]
    sk --> cyc["섹션마다 반복<br/>맥락 → 질문 → 선택지 → 결정 → 초안 → 승인 → 쓰기"]
    cyc --> cons["섹션별 자문<br/>business-analyst · monetization-strategist · analytics-engineer<br/>security-engineer · accessibility-specialist · qa-lead"]
    cons --> cyc
    cyc --> reg[("design/registry/entities.yaml<br/>(엔터티 · 요금제 · 규칙 · 상수 · 이벤트)")]
    cyc --> trk[("design/product/tracking-plan.md<br/>(이벤트 추가, 묻고 나서)")]
    cyc -.->|"가격 · 크레딧을 정의할 때"| pm[("design/product/pricing-model.md")]
    cyc --> st["기능 맵 상태 Drafting → In Review"]
    st --> v{"DRAFT COMPLETE?"}
    v -->|"아니요 · INCOMPLETE — MISSING sections"| cyc
    v -->|"예"| rev["/prd-review"]
```

---

## Architecture: API·데이터 계약, 테스트·CI 스캐폴드

```mermaid
flowchart TD
    ca["/create-architecture<br/>TD-ARCHITECTURE · TL-FEASIBILITY"] --> arch[("docs/architecture/architecture.md")]
    ca --> slo[("docs/ops/slo.md<br/>핵심 여정 · SLO · 알림 · 온콜")]
    arch --> ad["/architecture-decision (결정마다)<br/>TD-ADR · TD-STACK-RISK · SE-SECURITY-REVIEW"]
    ad --> adr[("docs/architecture/adr-*.md<br/>Proposed → Accepted")]
    adr -.->|"Domain Data · Infra 채택"| ssr["/setup-stack refresh"]
    adr --> radar[("docs/architecture/tech-radar.md")]
    adr --> api["/api-design new<br/>(백엔드) SE-SECURITY-REVIEW"]
    api --> oas[("docs/api/api-guidelines.md<br/>docs/api/openapi.yaml — 초기 계약")]
    oas --> dm["/data-model<br/>(백엔드) SE-SECURITY-REVIEW"]
    dm --> dmd[("docs/data/data-model.md<br/>docs/data/migrations/*.md")]
    dmd --> tm["/security-audit threat-model<br/>(개인정보)"]
    tm --> tmd[("docs/security/threat-model.md")]
    a11y["/ux-design accessibility<br/>(UI)"] --> a11yd[("design/accessibility-requirements.md<br/>accessibility.target")]
    ts["/test-setup<br/>레이어별 러너 · CI"] --> tsd[("러너 설정 · tests/unit · integration · contract · e2e<br/>.github/workflows/ci.yml")]
    ts --> cap[("tests/e2e/capture.spec.ts<br/>(웹 레이어가 있을 때)")]
    ts --> th["/test-helpers"]
    adr --> ar["/architecture-review"]
    oas --> ar
    ar --> ard[("architecture-review-*.md<br/>requirements-traceability.md · tr-registry.yaml")]
    ard --> g3{{"/gate-check validation"}}
    tmd --> g3
    a11yd --> g3
    tsd --> g3
    ssr --> vmd[("stack.pinned_on · docs/stack-reference/VERSION.md 완비<br/>(모든 티어 필수)")]
    vmd --> g3
```

- 이 단계의 `/api-design new`는 인증·세션, 계정, 핵심 도메인 엔터티 같은 Foundation·Core 리소스만 다루는 **초기**
  계약입니다. 화면에 필요한 오퍼레이션은 Validation의 `/api-design reconcile`에서 맞춥니다.
- 테스트 러너와 CI는 Validation 전에 한 번만 세팅합니다. 워킹 스켈레톤이 이 파이프라인으로 배포되기 때문입니다.

---

## Validation: 워킹 스켈레톤까지

```mermaid
flowchart TD
    inv["/ui-inventory (선택)"] -.-> invd[("design/inventory/screen-inventory.md")]
    dl["/design-language<br/>DD-BRAND-DIRECTION · DD-DESIGN-LANGUAGE"] --> dld[("design/brand/design-language.md")]
    dld --> ux["/ux-design shell · patterns · 핵심 화면"]
    ux --> uxd[("design/ux/app-shell.md · interaction-patterns.md<br/>design/ux/*.md")]
    uxd --> uxr["/ux-review<br/>DD-UI-CONSISTENCY"]
    uxr --> uxv{"판정"}
    uxv -->|"NEEDS REVISION · MAJOR REVISION NEEDED"| ux
    uxv -->|"APPROVED"| rec["/api-design reconcile<br/>(full 필수 · 백엔드와 UI)"]
    uxd -.-> usab["/usability-report (선택)<br/>PD-USER-VALIDATION"]
    usab -.-> usd[("production/qa/usability/*.md")]
    rec --> chg[("docs/api/changes/api-change-*.md<br/>(변경 없음 기록 포함)")]
    chg --> ce["/create-epics layer: foundation · core<br/>DM-EPIC"]
    cm["/create-control-manifest<br/>(full 필수) Accepted ADR · 기술 레이더<br/>TD-MANIFEST"] --> cmd[("docs/architecture/control-manifest.md")]
    cmd -.-> ce
    ce --> ep[("production/epics/*/EPIC.md")]
    ep --> cs["/create-stories epic-slug<br/>QL-STORY-READY"]
    cs --> st[("production/epics/*/story-*.md")]
    st --> spn["/sprint-plan new<br/>DM-SPRINT"]
    spn --> sprint[("production/sprints/sprint-01.md<br/>production/sprint-status.yaml")]
    sprint --> ws["/walking-skeleton"]
    ws --> wsr[("production/walking-skeleton/report-*.md")]
    wsr --> wsv{"판정"}
    wsv -->|"NOT VALIDATED"| ws
    wsv -->|"VALIDATED"| g4{{"/gate-check build"}}
```

### 워킹 스켈레톤 한 번의 흐름

```mermaid
flowchart LR
    j["핵심 여정 선택<br/>docs/ops/slo.md"] --> plan["레이어별 계획<br/>tech-lead"]
    plan --> impl["실제 코드 구현<br/>담당 엔지니어 · 기능 브랜치"]
    impl --> cd["CI/CD로 스테이징 배포<br/>devops-engineer 제안 · 사람이 실행"]
    cd --> obs["관측성 연결<br/>sre-engineer"]
    obs --> rb["롤백 후 재배포 리허설"]
    rb --> flag["재배포 없이 플래그 전환<br/>(standard · full)"]
    flag --> chk{"검증 항목 모두 YES?"}
    chk -->|"예"| ok[("VALIDATED")]
    chk -->|"아니요"| ng[("NOT VALIDATED<br/>build 게이트는 모든 티어에서 FAIL")]
```

검증 항목은 다섯 가지입니다: CI/CD로 스테이징에 배포, 핵심 여정이 UI → API → DB까지 통과, 헬스 엔드포인트·로그·지표나
트레이스가 관측됨, 롤백 후 재배포 성공, 재배포 없는 플래그 전환(standard·full).

---

## Build: 스토리 루프

```mermaid
flowchart TD
    sp["/sprint-plan<br/>DM-SPRINT"] --> sr["/story-readiness story<br/>QL-STORY-READY"]
    sr --> srv{"판정"}
    srv -->|"NEEDS WORK"| fixs["스토리 보완"]
    fixs --> sr
    srv -->|"BLOCKED"| up["선행 조건 해결<br/>ADR 채택 · 선행 스토리"]
    up --> sr
    srv -->|"READY"| dev["/dev-story story<br/>Surface · Type으로 엔지니어와 스택 스페셜리스트 선택"]
    dev --> st1[("sprint-status.yaml<br/>status: in-progress")]
    dev --> run["실행과 관찰<br/>Run result: OBSERVED · NOT VERIFIED · N/A"]
    run --> ev[("production/qa/evidence/story-slug/")]
    run --> cr["/code-review<br/>인가 · 검증 · N+1 · 멱등성 · 로그 속 개인정보"]
    cr --> sd["/story-done story<br/>TL-CODE-REVIEW · QL-TEST-COVERAGE"]
    sd --> sdv{"판정"}
    sdv -->|"BLOCKED · NOT ASSESSED"| dev
    sdv -->|"COMPLETE · COMPLETE WITH NOTES"| done[("sprint-status.yaml<br/>status: done")]
    done --> more{"스프린트에 남은 스토리?"}
    more -->|"있음"| sr
    more -->|"없음"| smoke["/smoke-check"]
    smoke --> smd[("production/qa/smoke-*.md")]
    smd --> qa["/qa-plan · /team-qa"]
    qa --> retro["/retrospective sprint-N"]
    retro --> mvp{"MVP 기능이 모두 구현됐나?"}
    mvp -->|"아니요"| sp
    mvp -->|"예"| g5{{"/gate-check hardening"}}
```

스프린트 중 수시로 쓰는 스킬도 있습니다.

```mermaid
flowchart LR
    ss["/sprint-status"] --- sc["/scope-check"]
    sc --- br["/bug-report → /bug-triage"]
    br --- pc["/propagate-prd-change<br/>TD-CHANGE-IMPACT"]
    pc --- tf["/team-feature · /team-ui · /team-content"]
    tf --- ms["/milestone-review<br/>DM-MILESTONE"]
```

### 스토리 유형과 증거

```mermaid
flowchart TD
    story["스토리 Type"] --> L["Logic<br/>단위 테스트 통과<br/>testing.strict.logic"]
    story --> I["Integration<br/>통합 · 계약 테스트 통과<br/>testing.strict.integration"]
    story --> U["UI<br/>컴포넌트 테스트 또는 상태별 스크린숏<br/>testing.strict.ui"]
    story --> E["E2E<br/>실행 환경에서 핵심 여정 E2E 통과<br/>testing.strict.e2e"]
    story --> C["Config<br/>스모크 체크 통과<br/>testing.strict.config"]
    story -.->|"Migration이 None이 아닐 때"| M["마이그레이션 드라이런 로그<br/>모든 티어 · 모든 qa.level"]
    L --> sd["/story-done"]
    I --> sd
    U --> sd
    E --> sd
    C --> sd
    M --> sd
```

`testing.strict`의 다섯 키(`logic`, `integration`, `ui`, `e2e`, `config`)는 증거가 없을 때 차단할지 경고할지를
유형별로 정합니다. 설정하지 않으면 스킬마다 자기 기본값을 씁니다.

### QA 파이프라인

```mermaid
flowchart TD
    tsu["/test-setup (Architecture, 한 번)"] --> thp["/test-helpers"]
    qp["/qa-plan sprint · feature"] --> qpd[("production/qa/qa-plan-*.md")]
    qpd --> smk["/smoke-check"]
    smk --> smv{"판정"}
    smv -->|"FAIL"| fix["핵심 경로부터 수정"]
    fix --> smk
    smv -->|"PASS · PASS WITH WARNINGS"| rs["/regression-suite"]
    smv -->|"NOT ASSESSED"| why["원인 확인 후 재실행<br/>(사인오프 불가)"]
    rs --> ter["/test-evidence-review"]
    ter -.-> tf["/test-flakiness"]
    br["/bug-report"] --> bd[("production/qa/bugs/BUG-NNNN.md<br/>S1-Critical … S4-Trivial")]
    bd --> bt["/bug-triage"]
    rs --> tq["/team-qa<br/>QL-TEST-COVERAGE"]
    tq --> so[("production/qa/qa-signoff-*.md<br/>APPROVED · APPROVED WITH CONDITIONS · NOT APPROVED · NOT ASSESSED")]
```

### UX·UI 파이프라인

```mermaid
flowchart TD
    prd[("PRD의 UI Requirements")] --> ux["/ux-design [화면]"]
    dl[("design/brand/design-language.md")] --> ux
    ux --> uxd[("design/ux/*.md<br/>상태 · 브레이크포인트 · API Data · 이벤트")]
    uxd --> uxr["/ux-review"]
    uxr -->|"APPROVED"| tui["/team-ui feature"]
    tui --> pd["product-designer<br/>명세 확인 · 보완"]
    pd --> de["design-engineer<br/>토큰 · 컴포넌트"]
    de --> fe["frontend-engineer · mobile-engineer<br/>구현"]
    fe --> a11y["accessibility-specialist<br/>접근성 점검"]
    a11y --> ddu["DD-UI-CONSISTENCY<br/>design-director"]
    ddu --> polish["마무리와 증거 스크린숏"]
```

`/team-ui`의 참여 인원은 `team.size`에 따라 달라집니다(위 그림은 `small` 기준). 화면을 새로 만들거나 바꿀 때는 구현
전에 `/ux-design`으로 명세부터 씁니다.

---

## Hardening → Launch

```mermaid
flowchart TD
    th["/team-hardening"] --> thr[("production/qa/hardening-*.md<br/>READY · READY WITH CONDITIONS · NOT READY · NOT ASSESSED")]
    subgraph checks["점검 (필요에 따라 병렬)"]
        direction TB
        pp["/perf-profile"]
        ba["/bundle-audit"]
        lt["/load-test (full 필수)"]
        sa["/security-audit full<br/>(minimal은 quick)"]
        ur["/usability-report<br/>(full 3회 · standard 1회 이상)"]
        brc["/business-rules-check"]
        fa["/feature-audit"]
    end
    th --- checks
    checks --> tq["/team-qa<br/>QL-TEST-COVERAGE"]
    tq --> so[("production/qa/qa-signoff-*.md")]
    rb["/incident runbook alert-slug<br/>(호출 알림마다)"] --> rbd[("docs/ops/runbooks/*.md")]
    lq["/localize qa<br/>(다국어)"] --> lqd[("production/qa/localization-qa-*.md")]
    cl["/changelog version"] --> rn["/release-notes"]
    rn --> rnd[("production/releases/*/release-notes.md")]
    rcs["/smoke-check<br/>(릴리스 후보 · PASS만 인정)"]
    rnd --> rcs
    rcs --> rc["/release-checklist<br/>롤백 경로는 모든 티어 필수"]
    rc --> rcd[("release-checklist.md · GO / NO-GO / NOT ASSESSED")]
    rcd --> rp["/rollout-plan<br/>SR-PRODUCTION-READINESS (항상 실행)"]
    rp --> rpd[("rollout-plan.md · READY TO ROLL OUT")]
    rpd --> lc["/launch-checklist<br/>(첫 공개 출시)"]
    lc --> lcd[("launch-checklist.md · GO / NO-GO / NOT ASSESSED")]
    thr --> g6{{"/gate-check launch"}}
    so --> g6
    rbd --> g6
    lqd -.-> g6
    lcd --> g6
    g6 -->|"PASS + 사용자 확인"| tr["/team-release version"]
    tr --> rr[("production/releases/*/release-record.md<br/>COMPLETED · HALTED · ROLLED BACK")]
    rr --> rt["/retrospective release version<br/>Outcome vs Success Metrics"]
```

### 롤아웃 한 번의 흐름

```mermaid
flowchart LR
    exp["Expand 마이그레이션 적용"] --> dep["배포<br/>(사람이 실행)"]
    dep --> s1["1단계<br/>플래그 1% · 카나리<br/>App Store 단계적 출시 · Play 단계적 출시"]
    s1 --> g{"가드레일<br/>오류율 · p95 · 크래시 없는 세션 · 비즈니스 지표"}
    g -->|"기준 이내 · 체류 시간 경과"| s2["다음 단계<br/>10% → 50% → 100%"]
    s2 --> g
    g -->|"중단 기준 초과"| halt["중단 · 롤백<br/>플래그 끄기 · 킬 스위치"]
    halt --> inc["/incident open"]
    s2 -->|"100% 완료"| con["Contract 마이그레이션 일정"]
    con --> rec[("release-record.md")]
```

모바일 바이너리는 되돌릴 수 없으므로, 모바일의 롤백 수단은 서버 플래그와 킬 스위치, 그리고 긴급 심사입니다.

---

## 출시 후 반복 전달 루프

Launch는 종착 단계입니다. 이후의 모든 릴리스는 게이트 없이 아래 루프를 돌며 릴리스마다 기록을 남깁니다.

```mermaid
flowchart LR
    spec["/write-prd<br/>또는 /quick-spec"] --> sp["/sprint-plan"]
    sp --> dev["/dev-story → /story-done"]
    dev --> sm["/smoke-check"]
    sm --> cl["/changelog → /release-notes"]
    cl --> rc["/release-checklist"]
    rc --> rp["/rollout-plan"]
    rp --> tr["/team-release"]
    tr --> rt["/retrospective release"]
    rt -->|"KEEP · ITERATE · ROLL BACK · REMOVE"| spec
    tg["/team-growth"] -.->|"실험 변형을 스토리로"| sp
    rt -.->|"다음 실험 가설"| tg
```

### 그로스 실험 한 건의 흐름

```mermaid
flowchart TD
    hyp["/team-growth 실험 설명"] --> gm["growth-manager<br/>가설 · 대상 세그먼트"]
    gm --> ae["analytics-engineer<br/>계측 · MDE · 표본 크기 · 가드레일"]
    ae --> cc{"동의 · 채널 점검<br/>(compliance.regions)"}
    cc -->|"항목 확인 또는 수용"| var["product-designer · ux-writer<br/>변형 설계"]
    cc -->|"미확인"| hold["승인 보류"]
    var --> brief[("production/growth/experiment-slug/brief.md")]
    brief --> stories["/quick-spec · /create-stories<br/>변형을 스토리로"]
    stories --> run["플래그로 배분 · 실행"]
    run --> ro["/team-growth readout experiment-slug"]
    ro --> rod[("readout.md<br/>SHIP · ITERATE · STOP · NOT ASSESSED")]
```

---

## 인시던트 루프

```mermaid
flowchart TD
    alert["알림 또는 고객 신고"] --> open["/incident open 요약<br/>SEV1–SEV4 분류 (사용자 확인)"]
    open --> rec[("production/incidents/INC-YYYYMMDD-NN.md<br/>Status: OPEN")]
    open --> roles["역할은 사람이 맡음<br/>인시던트 커맨더 · 커뮤니케이션 리드 · 기록 담당"]
    open --> mit["먼저 완화<br/>롤백 · 킬 스위치 · 스케일 · 페일오버<br/>명령은 제안만, 실행은 사람"]
    open -.->|"보안 · 개인정보 인시던트"| sec["security-engineer<br/>지역 체크리스트의 유출 통지 항목"]
    mit --> upd["/incident update INC-id<br/>타임라인 UTC + KST · 고객 커뮤니케이션"]
    upd --> st2[("Status: MITIGATED")]
    upd --> hf["/hotfix INC-id --surface"]
    hf --> hfr[("production/hotfixes/hotfix-*.md<br/>SHIPPED · MITIGATED — FIX PENDING · NOT ASSESSED")]
    hfr --> res["/incident resolve INC-id"]
    st2 --> res
    res --> sev{"SEV1 · SEV2?"}
    sev -->|"예 · RESOLVED — POSTMORTEM REQUIRED"| pm["/postmortem INC-id"]
    sev -->|"아니요 · RESOLVED"| fu["후속 조치<br/>/bug-report · /tech-debt"]
    pm --> pmd[("production/incidents/postmortems/INC-*.md<br/>비난 없는 서술 점검")]
    pmd --> ai["조치 항목<br/>prevent · detect · mitigate"]
    ai --> fu
    ai --> rbk["/incident runbook alert-slug"]
```

### 핫픽스 경로

```mermaid
flowchart TD
    in["/hotfix BUG-id 또는 INC-id"] --> surf{"--surface"}
    surf -->|"web · api"| w1["먼저 완화 (sre-engineer 자문)<br/>킬 스위치 · 플래그 · 되돌리기"]
    w1 --> fixw["트렁크 기준 짧은 브랜치에서 수정 · 회귀 테스트"]
    surf -->|"ios · android"| m1["즉시 서버 측 완화 (sre-engineer 자문)<br/>플래그 · API 호환"]
    m1 --> fixm["릴리스 태그에서 브랜치 · 수정 · 회귀 테스트"]
    fixw --> so["사인오프 · QA<br/>tech-lead · qa-engineer<br/>(+ 보안 수정이면 security-engineer, 고객에게 보이면 product-manager)"]
    fixm --> so
    so -->|"web · api"| shipw["web · api: 트렁크 병합 · 긴급 파이프라인 · 압축 카나리 (사람이 실행)"]
    so -->|"ios · android"| shipm["ios · android: 패치 빌드 · release-manager 자문<br/>긴급 심사 · 단계적 출시 (사람이 제출)"]
    shipw --> rec[("production/hotfixes/hotfix-YYYY-MM-DD-slug.md")]
    shipm --> rec
    rec --> link{"인시던트에 연결?"}
    link -->|"예"| pm["/postmortem INC-id"]
    link -->|"아니요"| rt["/retrospective release version"]
```

`/incident`, `/hotfix`, `/rollout-plan`은 리뷰 모드와 관계없이 이름 붙은 모든 에이전트와 게이트를 실행하고, 자동화
모드와 관계없이 모든 단계를 승인받습니다.

---

## 기존 프로젝트 도입

```mermaid
flowchart TD
    s["/start (D)"] --> se["stage-estimate.sh<br/>STAGE · SOURCE · ESTIMATE · EVIDENCE"]
    se --> ad["/adopt"]
    ad --> audit["형식 감사<br/>PRD 섹션 · 기능 맵 · ADR 제목 · API 계약<br/>마이그레이션 · 테스트와 CI · SLO와 런북"]
    audit --> plan[("docs/adoption-plan-YYYY-MM-DD.md<br/>BLOCKING · HIGH · MEDIUM · LOW")]
    plan --> ss["/setup-stack<br/>스택 고정 · 코드 루트 선언"]
    plan --> rd["/reverse-document prd · architecture · brief"]
    plan --> retro["/architecture-decision retrofit [경로]"]
    plan --> psd["/project-stage-detect"]
    ss --> gc{{"/gate-check 목표 단계"}}
    rd --> gc
    retro --> gc
```

`/adopt`는 기존 작업을 다시 만들지 않고 빈 곳만 채웁니다. `/reverse-document brief`는 기존 제품 브리프를 묻지 않고
덮어쓰지 않습니다.

---

## 리뷰 모드와 디렉터 게이트

```mermaid
flowchart TD
    skill["게이트를 쓰는 스킬"] --> ex{"/hotfix · /rollout-plan · /incident?"}
    ex -->|"예"| all["이름 붙은 모든 게이트 실행"]
    ex -->|"아니요"| rm{"review_mode<br/>--review → project.local.yaml → project.yaml → modes.rigor"}
    rm -->|"full"| all
    rm -->|"lean"| lean{"ID가 -PHASE-GATE로 끝나나?"}
    lean -->|"예"| runit["실행"]
    lean -->|"아니요"| skipl["건너뜀<br/>[GATE-ID] skipped — Lean mode"]
    rm -->|"solo"| skips["건너뜀<br/>[GATE-ID] skipped — Solo mode"]
    all --> v{"판정 등급"}
    runit --> v
    v -->|"APPROVE · READY · VIABLE · REALISTIC · ON TRACK · FEASIBLE · ADEQUATE · STRONG"| go["계속 진행"]
    v -->|"CONCERNS · AT RISK · GAPS"| ask["수정 · 수용 · 논의<br/>사용자가 선택"]
    v -->|"REJECT · NOT READY · HIGH RISK · UNREALISTIC<br/>OFF TRACK · INFEASIBLE · INADEQUATE"| stop["차단"]
    v -->|"OPTIONS"| pick["사용자가 방향 선택 후 진행"]
```

`modes.rigor`를 설정하지 않은 프로젝트는 `minimal`로 해석되어 `review_mode`가 `solo`가 됩니다. `standard`는 `lean`,
`full`은 `full`입니다.

---

## 자주 쓰는 진입점

| 지금 상황 | 실행할 것 |
|-----------|-----------|
| 완전히 처음, 아이디어 없음 | `/start` → `/brainstorm open` |
| 컨셉은 있는데 스택을 안 정함 | `/setup-stack` |
| 컨셉과 스택이 있음 | `/prd-review design/product/product-brief.md` → `/gate-check definition` → `/map-features` (standard·full); minimal이면 `/create-stories` → `/dev-story` |
| 기능 PRD를 쓰는 중 | `/map-features next` 또는 `/write-prd <feature>` |
| MVP PRD가 모두 끝남 | `/review-all-prds` → `/gate-check architecture` |
| 아키텍처 단계 | `/create-architecture` → `/architecture-decision` → `/api-design new` → `/data-model` |
| 테스트 기반 세팅 | `/test-setup` → `/test-helpers` |
| UX 설계 시작 | `/design-language` → `/ux-design shell` → `/ux-design <화면>` |
| Sprint 0 | `/walking-skeleton` → `/gate-check build` |
| 스토리가 있고 개발을 시작 | `/story-readiness <story>` → `/dev-story <story>` |
| 스토리 구현을 마침 | `/story-done <story>` |
| 스프린트 QA | `/qa-plan` → `/smoke-check` → `/regression-suite` |
| 버그가 쌓임 | `/bug-triage` |
| 출시 준비 | `/team-hardening` → `/changelog <version>` → `/release-notes` → `/smoke-check` (릴리스 후보) → `/release-checklist` → `/rollout-plan` → `/launch-checklist` (standard·full, 첫 공개 출시) → `/gate-check launch` |
| 운영 중 장애 | `/incident open "<요약>"` |
| 다음 릴리스 | `/write-prd` → … → `/team-release` → `/retrospective release <version>` |
| 기존 프로젝트 | `/adopt` |
| 모르겠음 | `/help` |
