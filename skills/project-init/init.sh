#!/usr/bin/env bash
# project-init: README.md 의 ## project 섹션을 현재 프로젝트에 세팅하고
#               .claude 디렉터리 골격을 만든다.
# global-init 과 달리 기존 설치를 지우지 않는다. 더하기만 한다.
# macOS 기본 bash 3.2 호환.
set -euo pipefail

PLUGIN="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
README="$PLUGIN/README.md"
TARGET="$(pwd)"
DOT="$TARGET/.claude"

for bin in claude python3; do
  command -v "$bin" >/dev/null || { echo "필요한 명령 없음: $bin" >&2; exit 1; }
done
[ -f "$README" ] || { echo "README.md 없음: $README" >&2; exit 1; }
[ "$TARGET" != "$HOME" ] || { echo "홈 디렉터리에서 실행할 수 없다. 프로젝트 루트로 이동할 것." >&2; exit 1; }
[ "$TARGET" != "$PLUGIN" ] || { echo "claude-init 저장소 자신에게는 실행할 수 없다. 대상 프로젝트로 이동할 것." >&2; exit 1; }

# settings.json 이 깨져 있으면 claude CLI 가 모든 설치를 조용히 실패시킨다.
# 절반만 적용된 상태를 만들지 않도록 시작 전에 멈춘다.
if [ -f "$DOT/settings.json" ]; then
  python3 -c '
import json,sys
try:
    t=open(sys.argv[1]).read().strip()
    if t: json.loads(t)
except Exception as e:
    print(f"{sys.argv[1]} 이 올바른 JSON 이 아니다: {e}", file=sys.stderr); sys.exit(1)
' "$DOT/settings.json" || { echo "먼저 고치고 다시 실행할 것." >&2; exit 1; }
fi

echo "== 대상 프로젝트: $TARGET =="

# --- 1. .claude 골격 --------------------------------------------------------
# 빈 디렉터리는 git 이 추적하지 않으므로 .gitkeep 을 둔다.
for d in skills rules agents; do
  mkdir -p "$DOT/$d"
  [ -e "$DOT/$d/.gitkeep" ] || : > "$DOT/$d/.gitkeep"
  echo "   .claude/$d/"
done

if [ -f "$DOT/CLAUDE.md" ]; then
  echo "   .claude/CLAUDE.md (이미 있음 — 건드리지 않음)"
else
  cat > "$DOT/CLAUDE.md" <<'MD'
# CLAUDE.md

이 프로젝트에서 Claude Code 가 따를 지침.

## 구조

| 경로 | 용도 |
|---|---|
| `.claude/skills/` | 이 프로젝트 전용 스킬. 디렉터리 하나당 `SKILL.md` 하나 |
| `.claude/rules/` | 길어서 CLAUDE.md 에 두기 어려운 규칙 문서. 필요할 때 참조한다 |
| `.claude/agents/` | 이 프로젝트 전용 서브에이전트 정의 |
| `.claude/settings.json` | 권한·훅·플러그인. 커밋해서 팀과 공유한다 |

## 프로젝트 개요

<!-- 무엇을 하는 프로젝트인지, 어떻게 실행·테스트하는지 -->

## 규칙

<!-- 코드 스타일, 하지 말아야 할 것, 자주 틀리는 부분 -->
MD
  echo "   .claude/CLAUDE.md (생성)"
fi

# --- 2. README ## project 섹션 실행 ------------------------------------------
CMDS=()
while IFS= read -r line; do
  [ -n "$line" ] && CMDS+=("$line")
done < <(awk '/^## project/{f=1;next} /^## /{f=0} f && (/^claude plugin /||/^npx skills /)' "$README")
[ ${#CMDS[@]} -gt 0 ] || { echo "README ## project 에서 실행할 명령을 찾지 못함" >&2; exit 1; }

HAS_FFMPEG=0
command -v ffmpeg >/dev/null && HAS_FFMPEG=1
NODE_OK=0
if command -v node >/dev/null; then
  case "$(node -v)" in v2[2-9]*|v[3-9][0-9]*) NODE_OK=1 ;; esac
fi

FAILED=()    # 실제 실패 — 비정상
# 없어도 설치는 시도한다. 무엇이 왜 막히는지만 먼저 알린다.
HAS_LFS=0
command -v git-lfs >/dev/null && HAS_LFS=1
if [ "$HAS_LFS" -eq 0 ]; then
  echo "!! git-lfs 없음 — hyperframes 저장소가 LFS 를 쓰므로 설치가 실패한다."
  echo "   brew install git-lfs && git lfs install"
fi
if [ "$HAS_FFMPEG" -eq 0 ] || [ "$NODE_OK" -eq 0 ]; then
  echo "!! ffmpeg=$HAS_FFMPEG node22+=$NODE_OK — hyperframes 는 설치돼도 렌더링에서 실패한다."
  echo "   brew install ffmpeg"
fi

echo "== 설치 =="
set -f
for cmd in "${CMDS[@]}"; do
  # 둘 다 확인 프롬프트가 있다. -y 로 넘기고, 그래도 뭔가 물으면
  # </dev/null 로 즉시 실패시킨다 — 비대화형에서 멈추는 것보다 낫다.
  case "$cmd" in
    *" install "*)  echo "++ $cmd -y"; $cmd -y </dev/null || { echo "   (실패, 계속)"; FAILED+=("$cmd"); } ;;
    "npx skills "*) echo "++ $cmd -y"; $cmd -y </dev/null || { echo "   (실패, 계속)"; FAILED+=("$cmd"); } ;;
    *)              echo "++ $cmd";    $cmd    </dev/null || { echo "   (실패, 계속)"; FAILED+=("$cmd"); } ;;
  esac
done
set +f

# --- 3. okf 자동 검색 hook ---------------------------------------------------
# README 의 JSON 블록을 .claude/settings.json 에 병합한다. 기존 키는 보존한다.
HOOK_CMD="$(awk '/^## project/{f=1;next} /^## /{f=0} f && /kb-search\.sh/' "$README" \
            | sed -n 's/.*"command": *"\(.*\)".*/\1/p' | head -1)"

if [ -n "$HOOK_CMD" ]; then
  python3 - "$DOT/settings.json" "$HOOK_CMD" <<'PY'
import json, os, sys

path, cmd = sys.argv[1], sys.argv[2]
data = {}
if os.path.exists(path):
    with open(path) as f:
        text = f.read().strip()
    if text:
        try:
            data = json.loads(text)
        except json.JSONDecodeError as e:
            print(f"!! settings.json 파싱 실패 — hook 추가 건너뜀: {e}", file=sys.stderr)
            sys.exit(0)

groups = data.setdefault("hooks", {}).setdefault("UserPromptSubmit", [])
already = any(
    h.get("command") == cmd
    for g in groups
    for h in g.get("hooks", [])
)
if already:
    print("   okf hook (이미 있음)")
else:
    groups.append({"hooks": [{"type": "command", "command": cmd}]})
    tmp = path + ".tmp"
    with open(tmp, "w") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")
    os.replace(tmp, path)
    print("   okf hook 추가")
PY
else
  echo "   okf hook 정의를 README 에서 찾지 못함 — 건너뜀"
fi

# --- 4. 검증 ----------------------------------------------------------------
echo "== 검증 =="
WANT_IDS=()
while IFS= read -r id; do
  [ -n "$id" ] && WANT_IDS+=("$id")
done < <(printf '%s\n' "${CMDS[@]}" | sed -n 's/^claude plugin install \([^ ]*\).*/\1/p')

claude plugin list --json > "$DOT/.project-init-state.json"
if [ ${#WANT_IDS[@]} -gt 0 ]; then
python3 - "$DOT/.project-init-state.json" "$TARGET" "${WANT_IDS[@]}" <<'PY'
import json, sys

state, target = sys.argv[1], sys.argv[2]
want = sys.argv[3:]
rows = {p["id"]: p for p in json.load(open(state))
        if p.get("scope") == "project" and p.get("projectPath") == target}

for i in want:
    p = rows.get(i)
    if p is None:                 print(f"  없음      {i}  (설치 실패)")
    elif p.get("errors"):         print(f"  ERROR    {i}  {p['errors']}")
    elif not p.get("enabled"):    print(f"  DISABLED {i}")
    else:                         print(f"  ok       {i}")
PY
fi
rm -f "$DOT/.project-init-state.json"

for d in skills rules agents; do
  [ -d "$DOT/$d" ] && echo "  ok       .claude/$d/"
done
[ -f "$DOT/CLAUDE.md" ]     && echo "  ok       .claude/CLAUDE.md"
[ -f "$DOT/settings.json" ] && echo "  ok       .claude/settings.json"

if [ ${#FAILED[@]} -gt 0 ]; then
  echo "== 실패 ==" >&2
  printf '   %s\n' "${FAILED[@]}" >&2
  [ "$HAS_LFS" -eq 0 ] && echo "   (hyperframes 가 여기 있다면 git-lfs 부터 설치할 것)" >&2
  exit 1
fi
echo "== 완료. Claude Code 재시작 후 반영된다. =="
