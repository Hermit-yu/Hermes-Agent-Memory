# 换机无缝恢复手册 (Full Rebuild Runbook)

> 最后全量同步: 2026-10-23。目标场景: 本机整体损坏, 在干净 VPS (Debian/Ubuntu, root) 上 1:1 重建。
> 一切以本仓库为唯一事实源; 不在仓库里的只有两件: ① 密钥包密码 (离线交付, 不入 git) ② 域名 DNS 记录 (改在 DNS 服务商侧, 见 ops/dns-notes.txt)。

## 仓库资产清单
| 路径 | 内容 | 恢复到 |
|---|---|---|
| `hermes-vps/memory/{MEMORY,USER}.md` | 长期记忆 live 版 | `/root/.hermes/memories/` |
| `hermes-vps/SOUL.core.md` (=SOUL.md) | 核心人格 | `/root/.hermes/SOUL.md` |
| `hermes-vps/SOUL.master.md` | 完整人格母本 | 按需, 勿覆盖运行版 |
| `hermes-vps/runtime/config.yaml` | Hermes 全量配置 | `/root/.hermes/config.yaml` |
| `skills/` | 32 个 skill 全量 (5.3M) | `/root/.hermes/skills/` |
| `services/honcho/` | Honcho 栈配置 + PG 快照 | 见 `services/honcho/README.md` |
| `services/web-mysql-snapshots/` | LDNMP mysql 全库 dump | 恢复后 `gunzip \| mysql` |
| `services/vault/hermes-secrets-*.enc` | 加密密钥包 (SSH key/bot token/LLM key/acme 账号/DB 密码等 13 项) | 解包回各自原路径 |
| `ops/systemd/` | nezha-agent/nezha-dashboard/sub-store unit | `/etc/systemd/system/` |
| `ops/web-docker-compose.yml` | /home/web LDNMP compose (密码已改 `${WEB_MYSQL_*}` 变量) | `/home/web/docker-compose.yml` |
| `ops/nginx-conf.d/` + `ops/nginx.conf` | 五个域名站点 (www/pass/sub/subs/komari) | `/home/web/conf.d/` + `nginx.conf` |
| `ops/ufw-added-rules.txt` / `ufw-status-20261023.txt` | 防火墙规则 | `ufw import` / 逐条 add |
| `ops/dns-notes.txt` | 域名→IP 登记 | 在 DNS 服务商改 |
| `governance/`、`projects/`、`memory-echoDB/` 等 | 治理/项目/长期归档 | 原地保留 |

## 不入库、可重拉的东西
- KPanel 参考源码 = `git clone https://github.com/kejilion/KPanel`
- argon-theme = `git clone https://github.com/solstice23/argon-theme.git`
- SubConv = `git clone https://github.com/SubConv/SubConv`, 自定义镜像 `local/subconv:taoque-auth-decode` 用其仓库内 Dockerfile 重建 (源在 `/home/web/subconv/source/`, 有本地改动时先 diff 再 rebase)
- docker 镜像 (kjlion/nginx, kjlion/php, honcho, pgvector, multica, redis) 均可从 registry 重拉

## 恢复步骤 (按序)
1. **基础件**: docker, docker-compose, git, node(或用 `/root/.hermes/tools/` 内置), hermes-agent (按官方安装), honcho CLI
2. **密钥包**: `openssl enc -d -aes-256-cbc -pbkdf2 -iter 200000 -in services/vault/hermes-secrets-20261023.tar.gz.enc -pass pass:"<密码>" | tar -xzf - -C /root/` 然后:
   - `.hermes/env` → `/root/.hermes/.env` (600)
   - `ssh/*` → `/root/.ssh/` (600; 公钥在 GitHub 账号里已有授权, 私钥原样恢复即可)
   - `acme-sh/accounts` → `/home/web/certs/accounts`
   - `web-mysql-credentials.env` 的值导出为 `WEB_MYSQL_ROOT_PASSWORD` / `WEB_MYSQL_PASSWORD` (供 compose 用)
   - `sub-store-data/*` → `/opt/sub-store/data/`; `config.yml` → `/opt/nezha/agent/`
   - 解包后跑 `sha256sum -c MANIFEST.sha256` 全 OK 才算恢复成功
3. **Hermes 本体**: 拷 `hermes-vps/runtime/config.yaml`、`hermes-vps/SOUL.md`、`skills/`、`memories/` 到 `/root/.hermes/`, 起 `hermes gateway`, 验证 Telegram 出站 + honcho 插件
4. **LDNMP**: 复原 `/home/web/{html,conf.d,nginx.conf,mysql,redis}` 目录结构 → 用 `ops/web-docker-compose.yml` (设好 env 密码后) `docker compose up -d` → 灌 `services/web-mysql-snapshots/*.sql.gz` → nginx `nginx -t`
5. **服务**: 拷 `ops/systemd/*.service` → daemon-reload → 启用 nezha/sub-store (先放好 `/opt/nezha` `/opt/sub-store` 二进制, nezha 从 GitHub release 下载, sub-store 用仓库 bundle 重建)
6. **Honcho**: 照 `services/honcho/README.md` (compose up + pg_restore 快照 + 回填 `.env` 密钥)
7. **防火墙/DNS**: `ufw` 按 `ops/ufw-added-rules.txt` 逐条 add; 在 DNS 服务商把 `ops/dns-notes.txt` 里的域名指到新 IP
8. **验收**: 五域名 HTTPS 200、`SELECT count(*) FROM messages`(honcho)≥479、mysql 四库在位、nezha/sub-store 面板可登、`hermes` 会话能召回长期记忆

## 硬性纪律 (本次踩过坑的)
- 明文密码只允许出现在: 加密包内、`.env` (600)、compose 的 `${VAR}` 引用。进 git 前先 `grep -rE` 扫一遍 D3 模式
- ufw 改完必须当场 canary 验证 (ss -tlnp + 外网探活), 未验证 = 未生效
- 每次换机后: 新 IP 同步到本仓库 `ops/dns-notes.txt` + 密钥包滚动 (旧私钥在 GitHub 撤权)
