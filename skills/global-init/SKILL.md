---
name: global-init
description: README.md 의 global 목록을 user scope 로 설치한다. 새 머신 세팅, "global 스킬 깔아줘", "내 기본 세팅 설치", "플러그인 초기화" 요청에 사용.
---

# global-init

이 플러그인의 `README.md` `## global` 섹션이 단일 기준이다. 거기 적히지 않은 user scope plugin / marketplace 는 전부 제거한다.

## 실행

```bash
bash "${CLAUDE_PLUGIN_ROOT:-.}/skills/global-init/install.sh"
```

플러그인으로 설치했다면 `CLAUDE_PLUGIN_ROOT` 가 잡혀 있다. 저장소를 직접 클론해 쓰는 경우 그 루트에서 `bash skills/global-init/install.sh`.

## 동작

1. **백업** — `~/.claude/global-init-backup-<타임스탬프>/` 에 plugin·marketplace 목록, `settings.json`, 기존 `CLAUDE.md` 저장
2. **제거** — user scope plugin 전부 → user scope marketplace 전부 (순서 반대면 참조가 끊긴다)
3. **설치** — `README.md` `## global` 의 `claude plugin ...` 줄을 적힌 순서대로 실행 (`install` 에는 `-y` 부착)
4. **npx skills** — `## global` 의 `npx ... skills add` 줄 실행 (`find-skills` 등). 제거 대상이 아니라 매번 덮어쓴다
5. **최신화** — `marketplace update` 전체 + 각 plugin `update`. 첫 설치면 no-op, 재실행 시 의미가 있다
6. **CLAUDE.md** — `CLAUDE.global.md` 를 `~/.claude/CLAUDE.md` 로 복사
7. **검증** — 목표 id 가 전부 `enabled` 이고 `errors` 없는지, 목록 밖 항목이 남지 않았는지 대조

## 주의

- **되돌릴 수 없다.** 실행 전 백업 경로를 사용자에게 알리고 확인을 받는다.
- **project scope 는 건드리지 않는다.** 모든 제거가 `--scope user`. 생략하면 다른 프로젝트의 설치까지 지워진다.
- **MCP connector 는 대상이 아니다.** `claude mcp` 관리 영역.
- **`settings.json` 의 `hooks` 블록은 남는다.** 플러그인 제거로 지워지지 않으므로 필요하면 따로 정리한다.
- **재시작 필요.** 설치 결과는 다음 세션부터 반영된다.
- **`--scope user` 는 붙이지 않는다.** `install` / `marketplace add` / `update` 모두 기본값이 `user` 다.
- **`-y` 는 마켓플레이스가 선언한 설치 명령을 확인 없이 실행한다.** 스크립트는 TTY 가 아니라 이게 없으면 멈춘다. 신뢰하는 저장소 목록에서만 쓴다.
- **플러그인 자동 업데이트 토글은 없다.** 설정 키를 찾지 못했다. 최신화는 4단계에서 명시적으로 돌린다 — 주기적으로 최신 상태를 원하면 이 스킬을 다시 실행한다.

## README 를 고쳤다면

스크립트는 README 를 파싱한다. 목록을 바꾸면 스크립트 수정 없이 그대로 반영된다.
단 `## global` 안의 명령은 `claude plugin` 또는 `npx ... skills add` 로 시작해야 하고, `marketplace add` 가 `install` 보다 먼저 와야 한다.

## 실패 시

검증 단계가 `MISSING` / `ERROR` / `DISABLED` / `EXTRA` 를 출력하고 exit 1 한다.
`EXTRA` 는 제거에 실패한 잔여 항목이다. 해당 id 를 `claude plugin uninstall <id> --scope user -y` 로 직접 지운다.
