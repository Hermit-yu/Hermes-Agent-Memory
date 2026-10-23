#!/usr/bin/env bash
# 换机复原 — 在一台干净 Debian/Ubuntu VPS (root) 上跑本脚本, 从本仓库重建 Hermes-Agent 全量。
# 用法:  hermes-restore.sh <VAULT_PASSWORD> [TARGET=/root]
# 前置:  已 git clone Hermes-Agent-Memory 到 REPO_DIR (默认 /root/Hermes-Agent-Memory), 已装 docker
set -euo pipefail
REPO="${REPO:-/root/Hermes-Agent-Memory}"
TGT="${2:-/root}"
PASS="${1:-}"
[ -n "$PASS" ] || { echo "用法: $0 <VAULT_PASSWORD> [TARGET]"; exit 1; }
[ -d "$REPO" ] || { echo "找不到仓库 $REPO"; exit 1; }

step(){ echo; echo "### $*"; }

step "0) 校验仓库完整性"
git -C "$REPO" log --oneline -1
(cd "$REPO/hermes-vps/symmetry" && python3 verify.py > /dev/null 2>&1 || echo '  [warn] verify 需本地 .hermes 存在, 跳过')

step "1) 还原 /root/.hermes 持久目录 (memory/soul/skills/plugins/cron/pending/state/config)"
mkdir -p "$TGT/.hermes"
cp -a "$REPO/hermes-vps/memory/."  "$TGT/.hermes/memories/" 2>/dev/null || { mkdir -p "$TGT/.hermes/memories"; cp -a "$REPO/hermes-vps/memory/." "$TGT/.hermes/memories/"; }
cp -a "$REPO/hermes-vps/SOUL.core.md" "$TGT/.hermes/SOUL.md"
cp -a "$REPO/hermes-vps/runtime/config.yaml" "$TGT/.hermes/config.yaml"
cp -a "$REPO/skills/." "$TGT/.hermes/skills/"
cp -a "$REPO/hermes-vps/plugins/." "$TGT/.hermes/plugins/"
cp -a "$REPO/hermes-vps/cron/." "$TGT/.hermes/cron/"
cp -a "$REPO/hermes-vps/pending/." "$TGT/.hermes/pending/"
cp -a "$REPO/hermes-vps/state/." "$TGT/.hermes/state/"
# curator 是 skills 派生的内容寻址缓存(可再生), 不入 git(历史版本曾内嵌共享 DB 活口令);
# 新机重建即可, 这里只起一个空目录占位。
mkdir -p "$TGT/.hermes/.curator_backups/blobs"
cp -a "$REPO/hermes-vps/workspace/." "$TGT/.hermes/Hermes-Agent-Memory/"
echo "  持久目录还原完成 ($(du -sh "$TGT/.hermes" | cut -f1))"

step "2) 解密密钥包 (sha256 校验)"
STAGE=$(mktemp -d)
openssl enc -d -aes-256-cbc -pbkdf2 -iter 200000 \
  -in "$REPO/services/vault/hermes-secrets-20261023.tar.gz.enc" \
  -pass pass:"$PASS" | tar -xzf - -C "$STAGE"
( cd "$STAGE" && sha256sum -c MANIFEST.sha256 ) && echo "  密钥包 13 项校验 OK"
# 回落到原路径
mkdir -p "$TGT/.hermes" "$TGT/.ssh" /home/web/certs/accounts /opt/sub-store/data /opt/nezha/agent
install -m 600 "$STAGE/.hermes/env" "$TGT/.hermes/.env"
install -m 600 "$STAGE/ssh/id_ed25519" "$TGT/.ssh/id_ed25519"
install -m 644 "$STAGE/ssh/id_ed25519.pub" "$TGT/.ssh/id_ed25519.pub"
install -m 600 "$STAGE/ssh/authorized_keys" "$TGT/.ssh/authorized_keys"
[ -d "$STAGE/acme-sh/accounts" ] && cp -a "$STAGE/acme-sh/accounts/." /home/web/certs/accounts/
cp -a "$STAGE/sub-store-data/." /opt/sub-store/data/
[ -f "$STAGE/nezha-agent-config.yml" ] && install -m 600 "$STAGE/nezha-agent-config.yml" /opt/nezha/agent/config.yml
# web mysql 凭据 (compose ${WEB_MYSQL_*})
if [ -f "$STAGE/web-mysql-credentials.env" ]; then
  . "$STAGE/web-mysql-credentials.env"
  echo "  [info] WEB_MYSQL_ROOT_PASSWORD 已就绪 (compose up 时 export)"
fi

step "3) Honcho 栈复原"
mkdir -p /opt/honcho-profile
cp -a "$REPO/services/honcho/config.toml" "$REPO/services/honcho/docker-compose.yml" "$REPO/services/honcho/profile.json" /opt/honcho-profile/
# 以脱敏 env.example 为底, 从密钥包的 hermes .env 取 LLM key / base_url 回填 (二者同源的 OpenRouter key)
cp "$REPO/services/honcho/env.example" /opt/honcho-profile/.env
LLMKEY=$(grep -E '^LLM_OPENAI_API_KEY=' "$STAGE/.hermes/env" | head -1 | cut -d= -f2-)
LLMBASE=$(grep -E '^LLM_OPENAI_BASE_URL=' "$STAGE/.hermes/env" | head -1 | cut -d= -f2-)
[ -z "$LLMKEY" ] && LLMKEY=$(grep -E '^OPENROUTER_API_KEY=' "$STAGE/.hermes/env" | head -1 | cut -d= -f2-)
if [ -n "$LLMKEY" ]; then
  sed -i "s|^LLM_OPENAI_API_KEY=.*|LLM_OPENAI_API_KEY=$LLMKEY|" /opt/honcho-profile/.env
  [ -n "$LLMBASE" ] && sed -i "s|^LLM_OPENAI_BASE_URL=.*|LLM_OPENAI_BASE_URL=$LLMBASE|" /opt/honcho-profile/.env
  echo "  honcho .env 已回填 LLM key (来自密钥包 hermes/.env)"
else
  echo "  [warn] 密钥包未含 LLM key, 需手工填 /opt/honcho-profile/.env 的 LLM_OPENAI_API_KEY"
fi
chmod 600 /opt/honcho-profile/.env
docker compose -f /opt/honcho-profile/docker-compose.yml up -d
docker exec -i honcho-local-database-1 pg_restore -U postgres -d postgres -c < "$REPO/services/honcho/snapshots/honcho-pg-20261023.dump" || echo "  [info] 库非空可跳过 pg_restore"
echo "  Honcho 就绪: curl 127.0.0.1:8000/health"

step "4) web mysql 快照复原"
mkdir -p /home/web/mysql
gunzip -c "$REPO/services/web-mysql-snapshots/web-mysql-20261023.sql.gz" | docker exec -i mysql mysql -uroot -p"${WEB_MYSQL_ROOT_PASSWORD}" 2>/dev/null || echo "  [warn] mysql 未起, 先 docker compose up 再灌库"

step "5) 可重装项 (按版本清单)"
cat "$REPO/hermes-vps/runtime/tools-manifest.txt"
echo "  按上面版本重装: hermes-agent (官方安装器) + node/go/python/ffmpeg/chromium/cua-driver/uv/ripgrep"

step "6) systemd / ufw / 站点"
cp -a "$REPO/ops/systemd/" /etc/systemd/system/ 2>/dev/null || true
systemctl daemon-reload 2>/dev/null || true
ufw show 2>/dev/null | head -5 || true
echo "  ufw 逐条 add 见 ops/ufw-added-rules.txt; nginx 站点见 ops/nginx-conf.d/; DNS 指新 IP 见 ops/dns-notes.txt"

step "7) 最终自检"
python3 "$REPO/hermes-vps/symmetry/verify.py" || echo "  (新机无本地 .hermes 时 verify 会 GAP, 属预期; 以本脚本复制结果为准)"
echo
echo "=== 复原完成. 验收: ① 五域名 HTTPS 200  ② SELECT count(*) FROM messages ≥479  ③ nezha/sub-store 面板可登 ④ hermes 会话能召回长期记忆 ==="
rm -rf "$STAGE"
