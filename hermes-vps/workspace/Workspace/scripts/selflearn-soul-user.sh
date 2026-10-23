#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="/opt/OpenClaw/workspace"
SOUL="$BASE_DIR/SOUL.md"
USER="$BASE_DIR/USER.md"
OUT_DIR="$BASE_DIR/reports/selflearn"
mkdir -p "$OUT_DIR"

DATE_TS="$(date +"%Y-%m-%d_%H-%M-%S")"
OUT_FILE="$OUT_DIR/SOUL-USER-selflearn-$DATE_TS.md"

{
  echo "# 智妍 SOUL/USER 自学习快照"
  echo
  echo "- 生成时间：$(date +"%Y-%m-%d %H:%M:%S %Z")"
  echo "- SOUL 源文件：$SOUL"
  echo "- USER 源文件：$USER"
  echo
  echo "---"
  echo
  echo "## 当前 SOUL.md 内容快照"
  echo
  cat "$SOUL"
  echo
  echo "---"
  echo
  echo "## 当前 USER.md 内容快照"
  echo
  cat "$USER"
  echo
  echo "---"
  echo
  echo "## 后续分析说明"
  echo
  echo "本报告由定时任务生成，记录当时的 SOUL/USER 快照，后续由智妍基于这些快照在人格逻辑中持续自学习、细化设定。"
} > "$OUT_FILE"

echo "Selflearn snapshot written to: $OUT_FILE"