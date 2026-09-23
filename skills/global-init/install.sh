#!/usr/bin/env bash
# global-init: README.md 의 ## global 섹션을 user scope 에 그대로 재현한다.
# README 에 없는 user scope plugin / marketplace 는 전부 제거한다.
# macOS 기본 bash 3.2 호환 (mapfile / 연관배열 미사용).
set -euo pipefail

REPO="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
README="$REPO/README.md"
GLOBAL_MD="$REPO/CLAUDE.global.md"
BACKUP="$HOME/.claude/global-init-backup-$(date +%Y%m%d-%H%M%S)"

# --- 0. 선행 확인 -----------------------------------------------------------
for bin in claude python3; do
  command -v "$bin" >/dev/null || { echo "필요한 명령 없음: $bin" >&2; exit 1; }
done
[ -f "$README" ] || { echo "README.md 없음: $README" >&2; exit 1; }

# 자기 자신(claude-init)은 teardown 대상에서 뺀다.
# 안 그러면 실행 중인 스크립트가 든 플러그인을 스스로 지우고, README 목록에 없으니 복구도 안 된다.
SELF_PLUGIN=""
SELF_MARKET=""
if [ -f "$REPO/.claude-plugin/plugin.json" ]; then
  SELF_PLUGIN="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1])).get("name",""))' "$REPO/.claude-plugin/plugin.json")"
fi
if [ -f "$REPO/.claude-plugin/marketplace.json" ]; then
  SELF_MARKET="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1])).get("name",""))' "$REPO/.claude-plugin/marketplace.json")"
fi
[ -n "$SELF_PLUGIN" ] && echo "== 보호: plugin '$SELF_PLUGIN' / marketplace '$SELF_MARKET' 는 제거하지 않는다 =="

# --- 1. README ## global 섹션에서 명령 추출 ---------------------------------
CMDS=()
while IFS= read -r line; do
  [ -n "$line" ] && CMDS+=("$line")
done < <(awk '/^## global/{f=1;next} /^## /{f=0} f && /^claude plugin /' "$README")
[ ${#CMDS[@]} -gt 0 ] || { echo "README ## global 에서 claude plugin 명령을 찾지 못함" >&2; exit 1; }

# npx skills 계열은 marketplace 관리 밖이라 별도로 모은다.
NPX_CMDS=()
while IFS= read -r line; do
  [ -n "$line" ] && NPX_CMDS+=("$line")
done < <(awk '/^## global/{f=1;next} /^## /{f=0} f && /^npx .* skills add /' "$README")

WANT_IDS=()
while IFS= read -r id; do
  [ -n "$id" ] && WANT_IDS+=("$id")
done < <(printf '%s\n' "${CMDS[@]}" | sed -n 's/^claude plugin install \([^ ]*\).*/\1/p')
[ ${#WANT_IDS[@]} -gt 0 ] || { echo "install 명령이 없음" >&2; exit 1; }

echo "== 목표: plugin ${#WANT_IDS[@]}개 =="
printf '   %s\n' "${WANT_IDS[@]}"

# --- 2. 백업 ---------------------------------------------------------------
mkdir -p "$BACKUP"
claude plugin list --json             > "$BACKUP/plugins.json"
claude plugin marketplace list --json > "$BACKUP/marketplaces.json"
cp "$HOME/.claude/settings.json" "$BACKUP/settings.json" 2>/dev/null || true
cp "$HOME/.claude/CLAUDE.md"     "$BACKUP/CLAUDE.md"     2>/dev/null || true
echo "== 백업: $BACKUP =="

# --- 3. 기존 user scope 전부 제거 -------------------------------------------
# plugin 먼저, marketplace 나중 (역순이면 참조가 끊긴다)
OLD_PLUGINS=()
while IFS= read -r id; do
  [ -n "$id" ] && OLD_PLUGINS+=("$id")
done < <(python3 -c '
import json,sys
for p in json.load(open(sys.argv[1])):
    if p.get("scope")=="user": print(p["id"])
' "$BACKUP/plugins.json")

if [ ${#OLD_PLUGINS[@]} -gt 0 ]; then
  for id in "${OLD_PLUGINS[@]}"; do
    if [ -n "$SELF_PLUGIN" ] && [ "${id%%@*}" = "$SELF_PLUGIN" ]; then
      echo "== skip  $id  (자기 자신)"
      continue
    fi
    echo "-- uninstall $id"
    claude plugin uninstall "$id" --scope user -y || echo "   (실패, 계속)"
  done
else
  echo "-- 제거할 user scope plugin 없음"
fi

# user scope 로 선언된 marketplace = settings.json 의 extraKnownMarketplaces
OLD_MPS=()
while IFS= read -r mp; do
  [ -n "$mp" ] && OLD_MPS+=("$mp")
done < <(python3 -c '
import json,os
p=os.path.expanduser("~/.claude/settings.json")
if os.path.exists(p):
    print("\n".join(json.load(open(p)).get("extraKnownMarketplaces",{})))
')

if [ ${#OLD_MPS[@]} -gt 0 ]; then
  for mp in "${OLD_MPS[@]}"; do
    if [ -n "$SELF_MARKET" ] && [ "$mp" = "$SELF_MARKET" ]; then
      echo "== skip  $mp  (자기 자신)"
      continue
    fi
    echo "-- marketplace remove $mp"
    claude plugin marketplace remove "$mp" --scope user || echo "   (실패, 계속)"
  done
else
  echo "-- 제거할 user scope marketplace 없음"
fi

# --- 4. README 순서대로 재설치 ----------------------------------------------
# eval 대신 단어 분리. glob 은 꺼둔다 (README 의 * 가 파일명으로 펼쳐지지 않도록).
set -f
for cmd in "${CMDS[@]}"; do
  case "$cmd" in
    *" install "*) echo "++ $cmd -y"; $cmd -y ;;
    *)             echo "++ $cmd";    $cmd    ;;
  esac
done
set +f

# --- 4b. npx skills ---------------------------------------------------------
if [ ${#NPX_CMDS[@]} -gt 0 ]; then
  echo "== npx skills =="
  set -f
  for cmd in "${NPX_CMDS[@]}"; do
    echo "++ $cmd"
    $cmd || echo "   (실패, 계속)"
  done
  set +f
fi

# --- 5. 최신화 --------------------------------------------------------------
# 방금 설치했다면 no-op. 재실행 시 의미가 있다.
echo "== 최신화 =="
claude plugin marketplace update || echo "   (marketplace update 실패, 계속)"
for id in "${WANT_IDS[@]}"; do
  echo "~~ update $id"
  claude plugin update "$id" -y || echo "   (실패, 계속)"
done

# --- 6. ~/.claude/CLAUDE.md -------------------------------------------------
if [ -f "$GLOBAL_MD" ]; then
  cp "$GLOBAL_MD" "$HOME/.claude/CLAUDE.md"
  echo "== ~/.claude/CLAUDE.md 갱신 =="
else
  echo "!! CLAUDE.global.md 없음 — 건너뜀" >&2
fi

# --- 7. 검증 ----------------------------------------------------------------
echo "== 검증 =="
claude plugin list --json             > "$BACKUP/plugins-after.json"
claude plugin marketplace list --json > "$BACKUP/marketplaces-after.json"

if python3 - "$BACKUP/plugins-after.json" "$BACKUP/marketplaces-after.json" "$SELF_PLUGIN" "${WANT_IDS[@]}" <<'PY'
import json, sys

plugins_file, markets_file, self_plugin = sys.argv[1], sys.argv[2], sys.argv[3]
want = sys.argv[4:]

after = {p["id"]: p for p in json.load(open(plugins_file)) if p.get("scope") == "user"}
markets = {m["name"]: m for m in json.load(open(markets_file))}
bad = 0

for i in want:
    p = after.get(i)
    if p is None:
        print(f"  MISSING   {i}"); bad = 1
    elif p.get("errors"):
        print(f"  ERROR     {i}  {p['errors']}"); bad = 1
    elif not p.get("enabled"):
        print(f"  DISABLED  {i}"); bad = 1
    else:
        print(f"  ok        {i}")

# install id 의 @suffix 가 실제로 등록된 marketplace 인지
for name in sorted({i.split("@")[1] for i in want if "@" in i}):
    m = markets.get(name)
    if m is None:
        print(f"  NO-MARKET {name}"); bad = 1
    elif m.get("source") == "directory":
        print(f"  LOCAL-DIR {name} -> {m.get('path')}  (다른 머신에서 깨진다)"); bad = 1

# 목록 밖 잔여물. 자기 자신과 의존성은 정상이므로 경고로만 둔다.
for i in sorted(k for k in after if k not in want):
    tag = "자기 자신" if i.split("@")[0] == self_plugin else "의존성이면 정상, 아니면 uninstall"
    print(f"  extra?    {i}  ({tag})")

sys.exit(bad)
PY
then
  echo "== 완료. Claude Code 재시작 후 반영된다. =="
else
  echo "!! 검증 실패. MISSING / ERROR / DISABLED / NO-MARKET / LOCAL-DIR 확인." >&2
  echo "   백업: $BACKUP" >&2
  exit 1
fi
