---
name: project-init
description: 현재 프로젝트를 project scope 로 세팅한다. README.md 의 project 목록을 전부 설치하고 .claude 디렉터리 골격(skills/ rules/ agents/ CLAUDE.md)을 만든다. "이 프로젝트 세팅", "project 스킬 깔아줘", ".claude 구조 잡아줘" 요청에 사용.
---

# project-init

## 이 스킬이 하는 일은 하나다 — 스크립트를 실행한다

```bash
bash "${CLAUDE_PLUGIN_ROOT:-.}/skills/project-init/init.sh"
```

**사용자에게 무엇을 설치할지 묻지 마라.** `README.md` `## project` 에 있는 것은 전부 설치한다.
선택지를 제시하거나, 프로젝트 성격을 판단하거나, 일부만 고르는 일을 하지 마라.
환경 점검도 하지 마라 — 스크립트가 한다.

`init.sh` 가 없으면 즉흥적으로 명령을 지어내지 말고, 플러그인이 낡았다고 보고하고 멈춰라:

```bash
claude plugin marketplace update claude-init
```

실행 후에는 스크립트 출력을 그대로 전하고, `실패` 항목이 있으면 그것만 짚어준다.

## 설치 대상

`README.md` `## project` 섹션이 단일 기준이다. 현재는 eli5, hyperframes, Taste, okf hook 네 가지다.
목록이 바뀌면 README 만 고치면 된다 — 스크립트는 README 를 파싱한다.

`global-init` 과 달리 **기존 설치를 지우지 않는다.** 더하기만 한다.

## 만드는 구조

```
.claude/
├── skills/        이 프로젝트 전용 스킬 (디렉터리 하나당 SKILL.md 하나)
├── rules/         CLAUDE.md 에 넣기엔 긴 규칙 문서
├── agents/        이 프로젝트 전용 서브에이전트
├── CLAUDE.md      프로젝트 지침 (이미 있으면 건드리지 않음)
└── settings.json  권한·훅·플러그인 (커밋해서 팀과 공유)
```

빈 디렉터리는 git 이 추적하지 않으므로 `.gitkeep` 을 넣는다.

## 실행 전 확인 (하나라도 걸리면 아무것도 하지 않고 중단)

- 홈 디렉터리에서 실행 — 거부
- `claude-init` 저장소 자신에게 실행 — 거부 (플러그인 저장소가 오염된다)
- `.claude/settings.json` 이 깨진 JSON — 거부. 이 상태면 `claude` CLI 가 모든 설치를 조용히 실패시키므로, 절반만 적용된 상태를 만들지 않는다

## 동작

1. **골격** — `.claude/{skills,rules,agents}/` 생성, `CLAUDE.md` 없으면 생성
2. **설치** — `README.md` `## project` 의 `claude plugin` / `npx skills` 줄을 순서대로 전부 실행
3. **hook** — README 의 okf `UserPromptSubmit` 정의를 **프로젝트** `.claude/settings.json` 에 병합. 홈 설정은 건드리지 않는다. 기존 키와 기존 훅은 보존하고, 같은 command 가 이미 있으면 건너뛴다
4. **검증** — 설치된 것이 `scope=project` 이고 `projectPath` 가 이 디렉터리인지 대조

## 종료 코드

| | 의미 |
|---|---|
| `0` | 전부 성공 |
| `1` | 실행 전 확인에서 걸렸거나, 설치 실패가 있다 |

## 주의

- **`--scope project` 는 README 에 이미 적혀 있다.** 스크립트가 붙이지 않는다. 목록에 줄을 추가할 때 직접 넣을 것
- **`npx skills` 계열은 scope 개념이 없다.** Taste 는 `npx skills add` 가 두는 위치를 따른다
- **hyperframes 는 ffmpeg 없이도 설치한다.** 렌더링 단계에서만 필요하므로 경고만 찍고 진행한다. 나중에 `brew install ffmpeg` 으로 채우면 된다
- **Taste 는 프로젝트 루트에 `.agents/` 와 `skills-lock.json` 을 만든다.** 스킬 실체가 `.agents/skills/` 에 들어가고 `.claude/skills/` 에는 심볼릭 링크가 걸린다. 기본값은 14개 전부 설치다 — 하나만 원하면 README 의 Taste 줄에 `--skill "design-taste-frontend"` 를 붙인다
- **재실행해도 안전하다.** hook 은 중복되지 않고, 이미 있는 `CLAUDE.md` 는 건드리지 않는다. 다만 Taste 는 매번 다시 받는다
- **재시작 필요.** 설치 결과는 다음 세션부터 반영된다

## README 를 고쳤다면

`## project` 안의 명령은 `claude plugin` 또는 `npx skills` 로 시작해야 하고, `marketplace add` 가 `install` 보다 먼저 와야 한다.
설명용 변형 명령은 코드블록이 아니라 인용문(`>`)에 둘 것 — 코드블록에 있으면 그것도 실행된다.
