# my-claude-settings

자주 쓰는 Claude Code plugin 을 global(user) / project scope 로 설치하는 설정 모음.

각 저장소 README 와 `.claude-plugin/marketplace.json` 을 직접 확인해 적은 명령이다.
CLI 기준(`claude plugin ...`). Claude Code 세션 안에서는 앞에 `/` 만 붙이면 된다.

## global

`--scope user`. 모든 프로젝트에서 활성화.

### marketplace 등록

`claude-plugins-official` 은 기본 내장이라 등록 불필요.

```bash
claude plugin marketplace add JuliusBrussee/caveman
claude plugin marketplace add DietrichGebert/ponytail
claude plugin marketplace add jeffallan/claude-skills
claude plugin marketplace add anthropics/skills
claude plugin marketplace add zkfmapf123/okf
claude plugin marketplace add zkfmapf123/zkfmapf123-common
```

### plugin 설치

```bash
claude plugin install caveman@caveman
claude plugin install ponytail@ponytail
claude plugin install superpowers@claude-plugins-official
claude plugin install mattpocock-skills@claude-plugins-official
claude plugin install fullstack-dev-skills@jeffallan
claude plugin install document-skills@anthropic-agent-skills
claude plugin install okf-knowledge-base@okf
claude plugin install common@common
```

### 목록

| plugin                   | marketplace               | 저장소                                                                          | 내용                                                               |
| ------------------------ | ------------------------- | ------------------------------------------------------------------------------- | ------------------------------------------------------------------ |
| `caveman`                | `caveman`                 | [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman)               | 출력 토큰 압축. `/caveman lite\|full\|ultra`                       |
| `ponytail`               | `ponytail`                | [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail)           | 과설계 방지. `/ponytail-review`, `/ponytail-audit`                 |
| `superpowers`            | `claude-plugins-official` | [obra/superpowers](https://github.com/obra/superpowers)                         | 개발 프로세스 16종. brainstorming → plan → TDD → review            |
| `mattpocock-skills`      | `claude-plugins-official` | [mattpocock/skills](https://github.com/mattpocock/skills)                       | `/tdd`, `/teach`, `/handoff`, `/grill-me` 등 20여종                |
| `fullstack-dev-skills`   | `jeffallan`    | [jeffallan/claude-skills](https://github.com/jeffallan/claude-skills)           | 언어·프레임워크별 스킬 67종                                        |
| `document-skills`        | `anthropic-agent-skills`  | [anthropics/skills](https://github.com/anthropics/skills)                       | pdf / docx / pptx / xlsx 조작                                      |
| `okf-knowledge-base`     | `okf`                     | [zkfmapf123/okf](https://github.com/zkfmapf123/okf)                             | `~/.claude/kb/` 지식 저장. `/kb`, `/kb-end`                        |
| `common`                 | `common`                  | [zkfmapf123/zkfmapf123-common](https://github.com/zkfmapf123/zkfmapf123-common) | `/common:judge`, `report-outputs`, `context-*`, `loop-engineering` |

### 확인된 불일치

- **`fullstack-dev-skills`** — `marketplace.json` 의 `name` 필드는 `fullstack-dev-skills` 지만 실제 등록은 `jeffallan` 으로 잡힌다. 저장소 README 와 동일하게 `@jeffallan` 을 쓴다.
- **`common`** — 현재 로컬에는 이 마켓플레이스가 디렉터리 소스(`/Users/dong/dev/ai/claude-council`)로 등록돼 있어 `cache-miss` 가 난다. 위의 GitHub 주소로 재등록해야 다른 머신에서도 동작한다.
- **`superpowers`** — `obra/superpowers-marketplace` 를 따로 등록하는 경로도 있으나, 공식 마켓플레이스 쪽은 sha 가 고정돼 있어 더 안정적이다.

### ~/.claude/CLAUDE.md

[`CLAUDE.global.md`](./CLAUDE.global.md) 내용을 `~/.claude/CLAUDE.md` 로 넣는다.

```bash
cp CLAUDE.global.md ~/.claude/CLAUDE.md
```

이 파일이 `andrej-karpathy-skills` 플러그인의 4원칙을 그대로 담고 있어, 해당 플러그인은 설치하지 않는다.

## project

`--scope project`. 해당 프로젝트에서만. `.claude/settings.json` 에 기록되어 커밋 가능.

### eli5

```bash
claude plugin marketplace add anthropics/claude-plugins-community
claude plugin install eli5@claude-community --scope project
```

### hyperframes (모션 그래픽)

공식 마켓플레이스에 있어 별도 등록 불필요. **Node 22+ 와 FFmpeg 선행 필요.**

```bash
ffmpeg -version
claude plugin install hyperframes@claude-plugins-official --scope project
```

### Taste (웹 디자인)

plugin 이 아니라 `npx skills` 계열이라 설치 방식이 다르다.

```bash
npx skills add https://github.com/Leonxlnx/taste-skill

# 단일 스킬만
npx skills add https://github.com/Leonxlnx/taste-skill --skill "design-taste-frontend"
```

### okf 자동 검색 hook

`/kb` 를 매번 치지 않고 자동 검색시키려면 프로젝트 `.claude/settings.json` 에 추가한다.

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/plugins/marketplaces/okf/hooks/kb-search.sh"
          }
        ]
      }
    ]
  }
}
```

> 로컬 마켓플레이스 클론이 낡으면 `hooks/` 디렉터리가 없어 조용히 실패한다.
> `claude plugin marketplace update okf` 로 먼저 갱신할 것.

## 확인

```bash
claude plugin list --json      # id, scope, enabled
claude plugin marketplace list --json
```
