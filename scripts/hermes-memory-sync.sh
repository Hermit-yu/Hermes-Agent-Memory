#!/bin/bash
# hermes-memory-sync.sh — 把 Hermes 运行时记忆与核心 SOUL 同步到 OpenClaw-Memory
# 完整人格母本 hermes-vps/SOUL.master.md 由权威仓库维护，本脚本绝不覆盖。
# 护栏：D3 命中即中止；无变更不提交；不 force-push；rebase 冲突中止。
set -euo pipefail

SRC_MEM="/root/.hermes/memories/"
SRC_SOUL_CORE="/root/.hermes/SOUL.md"
REPO="/root/OpenClaw-Memory"
DEST="$REPO/hermes-vps"
LOG="/root/.hermes/logs/memory-sync.log"
MSG="${1:-chore(ziyan): hermes memory backup $(date +'%Y-%m-%d %H:%M %Z')}"

log(){ echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG"; }

mkdir -p "$(dirname "$LOG")" "$DEST/memory"

# 1. 同步运行时记忆（排除备份、锁和数据库）。
rsync -a --delete \
  --exclude='*.bak*' --exclude='*.lock' --exclude='*.db' --exclude='*.db-wal' --exclude='*.db-shm' \
  "$SRC_MEM" "$DEST/memory/"

# 2. 同步核心运行人格与旧流程兼容镜像；母本不在写入列表中。
[ -f "$SRC_SOUL_CORE" ] && cp -f "$SRC_SOUL_CORE" "$DEST/SOUL.core.md"
[ -f "$SRC_SOUL_CORE" ] && cp -f "$SRC_SOUL_CORE" "$DEST/SOUL.md"
log "COPY_OK -> $DEST (memory + core SOUL; master preserved)"

# 3. D3 敏感串拦截。
cd "$REPO"
PAT='sk-[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|BEGIN [A-Z ]*PRIVATE KEY|xox[baprs]-[A-Za-z0-9-]{10,}|AKIA[0-9A-Z]{16}|-----BEGIN OPENSSH PRIVATE KEY-----'
HITS=$(grep -rlE "$PAT" hermes-vps/ 2>/dev/null || true)
if [ -n "$HITS" ]; then
  log "ABORT: 检测到疑似 D3 敏感串，已中止 push；命中文件："
  echo "$HITS" | tee -a "$LOG"
  git checkout -- hermes-vps/ 2>/dev/null || true
  echo "$HITS" | xargs rm -f 2>/dev/null || true
  log "已清除命中文件，未推送任何内容"
  exit 2
fi
log "SCAN_OK 无敏感串"

# 4. 幂等提交。
git add -A hermes-vps/
if git diff --cached --quiet; then
  log "NO_CHANGE 无需提交"
  exit 0
fi

# 5. pull --rebase 后 push。
BR=$(git rev-parse --abbrev-ref HEAD)
git -c user.name="ziyan-vps" -c user.email="hermit-yu@users.noreply.github.com" \
    commit -m "$MSG" >> "$LOG" 2>&1
if ! git pull --rebase origin "$BR" >> "$LOG" 2>&1; then
  log "REBASE_CONFLICT 需人工处理，已停止（未 push）"
  git rebase --abort 2>/dev/null || true
  exit 3
fi
git push origin "$BR" >> "$LOG" 2>&1
log "PUSH_OK $(git rev-parse --short HEAD)"
