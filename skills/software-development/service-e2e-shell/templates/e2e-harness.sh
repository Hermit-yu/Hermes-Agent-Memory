#!/usr/bin/env bash
# 多进程服务 E2E harness 骨架（云瞳 agent+panel 形态；按你的端口/state 目录/端点改）。
# 用法: bash e2e-harness.sh ；全绿报成。terminal 里 foreground 跑（& 只能在脚本文件内）。
set -euo pipefail
cd /path/to/repo
export GOTOOLCHAIN=local

BASE=/tmp/yt_run          # 唯一 state 根，隔离本次运行
PORT=127.0.0.1:8907      # 唯一端口，避免串其它运行
rm -rf "$BASE"; mkdir -p "$BASE"

# 1) 构建到临时目录（别用源码树旧 binary）
go build -o "$BASE/yuntongd" ./cmd/yuntongd
go build -o "$BASE/agent"   ./cmd/agent

# 2) 清残留：pattern 用完整 binary 绝对路径 + || true（防误杀 terminal wrapper / set -e 中止）
for p in "$BASE/yuntongd" "$BASE/agent"; do pkill -f "$p" 2>/dev/null || true; done
sleep 0.3

# 3) 起进程（各自唯一 state 子目录；& 仅在脚本文件内合法）
"$BASE/yuntongd" -state "$BASE/state" -listen "$PORT" >"$BASE/panel.log" 2>&1 &
PANEL=$!
"$BASE/agent" -state "$BASE/agent" -push-url "http://$PORT/push" >"$BASE/agent.log" 2>&1 &
AG=$!
sleep 0.6

# 4) 先取登录态（首启 0600 密码文件第 2 行 → login → 抽 token；jq 更稳）
APW=$(sed -n '2p' "$BASE/state/admin-password.txt" 2>/dev/null || true)
TOK=$(curl -s -X POST -H 'Content-Type: application/json' \
  -d "$(jq -n --arg p "$APW" '{user:"admin",pass:$p}')" "$PORT/auth/login" | jq -r '.token // empty')

# 5) 逐端点 curl + 断言「期望码」；打 -> 实际。
chk(){ local desc="$1" want="$2"; shift 2; local code; code=$(curl -s -o /dev/null -w '%{http_code}' "$@" || echo 000); \
  [ "$code" = "$want" ] && echo "PASS $desc -> $code" || echo "FAIL $desc -> $code (want $want)"; }
chk "no-session /machines (401)" 401      "$PORT/machines"
chk "with-session /machines (200)" 200    -H "X-Yuntong-Session: $TOK" "$PORT/machines"
chk "no-session /killswitch (401)" 401    -X POST "$PORT/killswitch"
chk "non-admin /auth/accounts (403)" 403  -H "X-Yuntong-Session: $NONADMIN_TOK" "$PORT/auth/accounts"   # 按需造非 admin
chk "bad Bearer /push (401)" 401   -X POST -H "Authorization: Bearer wrong-xxxxxxxx" -H 'Content-Type: application/json' -d '{"machine_id":"x"}' "$PORT/push"
chk "good Bearer /push (200)" 200 -X POST -H "Authorization: Bearer $PUSH_TOK" -H 'Content-Type: application/json' -d '{"machine_id":"manual-a"}' "$PORT/push"
# 鉴权 SSE：token 走 query（EventSource 带不了 header）；timeout 限 1~2s
echo "SSE no-session     -> $(timeout 1.5 curl -s -N -o /dev/null -w '%{http_code}' "$PORT/events/stream" || echo 000)"
echo "SSE with-session   -> $(timeout 1.5 curl -s -N -o /dev/null -w '%{http_code}' "$PORT/events/stream?session=$TOK" || echo 000)"

# 6) 收尾
kill "$PANEL" "$AG" 2>/dev/null || true
[ -f "$BASE/panel.log" ] && { echo "--- panel.log ---"; tail -20 "$BASE/panel.log"; }
[ -f "$BASE/agent.log" ] && { echo "--- agent.log ---"; tail -20 "$BASE/agent.log"; }
echo "=== DONE ==="
