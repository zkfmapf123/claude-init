#!/usr/bin/env bash
# global-init: README.md 의 ## global 섹션을 user scope 에 그대로 재현한다.
# README 에 없는 user scope plugin / marketplace 는 전부 제거한다.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
README="$REPO/README.md"
GLOBAL_MD="$REPO/CLAUDE.global.md"
TS="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/.claude/global-init-backup-$TS"

[ -f "$README" ] || { echo "README.md 없음: $README" >&2; exit 1; }

# --- 0. README ## global 섹션에서 명령 추출 -------------------------------
mapfile -t CMDS < <(awk '/^## global/{f=1;next} /^## /{f=0} f && /^claude plugin /' "$README")
[ ${#CMDS[@]} -gt 0 ] || { echo "README ## global 에서 claude plugin 명령을 찾지 못함" >&2; exit 1; }

mapfile -t WANT_IDS < <(printf '%s\n' "${CMDS[@]}" | sed -n 's/^claude plugin install \([^ ]*\).*/\1/p')
[ ${#WANT_IDS[@]} -gt 0 ] || { echo "install 명령이 없음" >&2; exit 1; }

echo "== 목표: plugin ${#WANT_IDS[@]}개 =="
printf '   %s\n' "${WANT_IDS[@]}"

# --- 1. 백업 ---------------------------------------------------------------
mkdir -p "$BACKUP"
claude plugin list --json            > "$BACKUP/plugins.json"
claude plugin marketplace list --json > "$BACKUP/marketplaces.json"
cp "$HOME/.claude/settings.json" "$BACKUP/settings.json" 2>/dev/null || true
cp "$HOME/.claude/CLAUDE.md"     "$BACKUP/CLAUDE.md"     2>/dev/null || true
echo "== 백업: $BACKUP =="

# --- 2. 기존 user scope 전부 제거 ------------------------------------------
# plugin 먼저, 그 다음 marketplace (역순이면 참조가 끊긴다)
mapfile -t OLD_PLUGINS < <(python3 -c '
import json,sys
for p in json.load(open(sys.argv[1])):
    if p.get("scope")=="user": print(p["id"])
' "$BACKUP/plugins.json")

for id in "${OLD_PLUGINS[@]:-}"; do
  [ -n "$id" ] || continue
  echo "-- uninstall $id"
  claude plugin uninstall "$id" --scope user -y || echo "   (실패, 계속)"
done

# user scope 로 선언된 marketplace = settings.json 의 extraKnownMarketplaces
mapfile -t OLD_MPS < <(python3 -c '
import json,os
p=os.path.expanduser("~/.claude/settings.json")
print("\n".join(json.load(open(p)).get("extraKnownMarketplaces",{}))) if os.path.exists(p) else None
')

for mp in "${OLD_MPS[@]:-}"; do
  [ -n "$mp" ] || continue
  echo "-- marketplace remove $mp"
  claude plugin marketplace remove "$mp" --scope user || echo "   (실패, 계속)"
done

# --- 3. README 순서대로 재설치 ---------------------------------------------
for cmd in "${CMDS[@]}"; do
  case "$cmd" in
    *"marketplace add"*) full="$cmd" ;;
    *"install"*)         full="$cmd -y" ;;
    *)                   full="$cmd" ;;
  esac
  echo "++ $full"
  eval "$full"
done

# --- 3.5 최신화 -------------------------------------------------------------
# 방금 설치했다면 no-op. 재실행 시 의미가 있다.
echo "== 최신화 =="
claude plugin marketplace update || echo "   (marketplace update 실패, 계속)"
for id in "${WANT_IDS[@]}"; do
  echo "~~ update $id"
  claude plugin update "$id" -y || echo "   (실패, 계속)"
done

# --- 4. ~/.claude/CLAUDE.md ------------------------------------------------
if [ -f "$GLOBAL_MD" ]; then
  cp "$GLOBAL_MD" "$HOME/.claude/CLAUDE.md"
  echo "== ~/.claude/CLAUDE.md 갱신 =="
else
  echo "!! CLAUDE.global.md 없음 — 건너뜀" >&2
fi

# --- 5. 검증 ---------------------------------------------------------------
echo "== 검증 =="
claude plugin list --json > "$BACKUP/plugins-after.json"
if python3 - "$BACKUP/plugins-after.json" "${WANT_IDS[@]}" <<'PY'
import json,sys
after={p["id"]:p for p in json.load(open(sys.argv[1])) if p.get("scope")=="user"}
want=sys.argv[2:]
bad=0
for i in want:
    p=after.get(i)
    if not p:            print(f"  MISSING  {i}");                bad=1
    elif p.get("errors"):print(f"  ERROR    {i}  {p['errors']}");  bad=1
    elif not p.get("enabled"): print(f"  DISABLED {i}");           bad=1
    else:                print(f"  ok       {i}")
extra=[i for i in after if i not in want]
for i in extra: print(f"  EXTRA    {i}")
sys.exit(1 if bad or extra else 0)
PY
then
  echo "== 완료. Claude Code 재시작 후 반영된다. =="
else
  echo "!! 검증 실패. 위 MISSING / ERROR / EXTRA 확인. 백업: $BACKUP" >&2
  exit 1
fi
