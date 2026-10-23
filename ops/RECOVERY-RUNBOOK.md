# 换机复原手册 — Hermes-Agent 全量 (Full Restore Runbook)

> 最后全量同步: 2026-10-23。
> 目标: 本机整体损坏时，在干净 VPS (Debian/Ubuntu, root) 上**一次 `git clone` 复原全部 Hermes-Agent 资产**。
> 范围: 本仓只保证 **Hermes-Agent 本体** (人格/记忆/技能/插件/配置/cron/honcho/密钥)。
> 网站与基础设施 (LDNMP/nginx/WordPress/web-mysql/nezha/sub-store/ufw/DNS) **不在本仓保证范围内**，由 kejilion 脚本单独备份复原。

## 对称保证的边界
本仓的"双边对称"由 `hermes-vps/symmetry/verify.py` 机器校验 (非口头):
- **L→R 可复原**: 本地 `/root/.hermes` 每个持久文件 (排除运行态噪声: 锁/心跳/socket/venv/可重拉参考仓) 在仓库有同路径同内容副本
- **R→L 无孤儿**: 仓库每个文件都能映射回本地真实路径 (复原时知道落哪)
- 全对称 => `verify.py` 退出 0, 即可一次 clone 复原

## 仓库资产清单 (Hermes-Agent 核心, 已 verify 对称)
| 路径 | 内容 | 复原到 |
|---|---|---|
| `hermes-vps/memory/{MEMORY,USER}.md` | 长期记忆 live 版 | `/root/.hermes/memories/` |
| `hermes-vps/SOUL.core.md` (=SOUL.md) | 核心人格 | `/root/.hermes/SOUL.md` |
| `hermes-vps/SOUL.master.md` | 完整人格母本 (权威, 勿被运行版覆盖) | 按需 |
| `hermes-vps/runtime/config.yaml` | Hermes 全量配置 (密钥走 `${VAR}`, 无明文) | `/root/.hermes/config.yaml` |
| `hermes-vps/runtime/tools-manifest.txt` | 可重装工具/本体精确版本登记 | 照此重装 |
| `hermes-vps/plugins/` | honcho 插件源码 | `/root/.hermes/plugins/` |
| `hermes-vps/{cron,pending,state,backups}/` | 定时/暂存/心跳/备份 | `/root/.hermes/` 对应目录 |
| `hermes-vps/.curator_backups/`（派生缓存） | **不入 git**（可再生）：skills 内容寻址缓存，历史版本曾内嵌共享 DB 活口令；换机只需 `mkdir -p /root/.hermes/.curator_backups/blobs` 占位，运行即自动重建 | restore.sh 已处理 |
| `hermes-vps/workspace/` | Hermes-Agent-Memory (含治理/项目/记忆归档, 已排 venv+参考仓) | `/root/.hermes/Hermes-Agent-Memory/` |
| `skills/` | 32 skill 全量 | `/root/.hermes/skills/` |
| `services/honcho/` | Honcho 栈配置 + PG 快照 | 见其 README |
| `services/vault/hermes-secrets-*.enc` | 加密密钥包 (SSH/Telegram/LLM/acme 等 12 项, 值不回显) | 解包回原路径 |
| `hermes-vps/restore.sh` | 一键复原脚本 | — |
| `hermes-vps/symmetry/verify.py` + `MANIFEST.json` | 双边对称校验器 + 结果 | — |

## 可重拉/可重装 (不进 git, 版本由 manifest 登记, 对称性=清单齐)
- **Hermes 本体** `/root/.hermes/hermes-agent` — 官方安装器重装, `hermes update` 追新 (manifest 登记当前 v0.21.5)
- **tools/** (ffmpeg/chromium/node/go/python/cua-driver/uv/ripgrep/agent-browser) — 各上游官方源按 manifest 版本重装
- **KPanel 参考源码** = `git clone https://github.com/kejilion/KPanel`
- **argon-theme** = `git clone https://github.com/solstice23/argon-theme.git`
- **Honcho/lancedb/pgvector 镜像** — registry 重拉

## 一次 clone 复原 (标准路径)
```bash
git clone git@github.com:Hermit-yu/OpenClaw-Memory.git /root/OpenClaw-Memory
cd /root/OpenClaw-Memory
bash hermes-vps/restore.sh "<密钥包密码>"   # 密码离线交付, 不入 git
hermes update                                  # 追最新本体 (或用 manifest 钉版本)
```
restore.sh 会自动: 还原 /root/.hermes 持久目录 → 解密密钥包 (sha256 校验 12 项) → 回填 honcho .env 密钥 + pg_restore → 复原 cron/plugins/state → 打印自检。

## 网站/基础设施 (归 kejilion 脚本, 非本仓保证)
LDNMP + 5 域名站点 + web-mysql + WordPress + nezha + sub-store + ufw + DNS —— 这套由你的 kejilion 备份脚本单独负责。本仓不再为其做对称保证 (上单曾入的 web-mysql/WordPress 快照已撤回, 避免与 kejilion 双份脱节)。

## 硬性纪律 (本次踩过坑的)
- 明文密钥永不进 git: 值只出现在加密包内 / `.env`(600) / compose `${VAR}` 引用; 提交前 `verify.py` + D3 全树 grep 双保险
- 密钥包密码持久存于 `/root/.hermes/vault-passwords/hermes-secrets-20261023.txt` (600, 不在会被剪枝的 scratch 里)
- 每次换机后滚动: 新 IP 写 `ops/dns-notes.txt` + 旧 SSH 私钥在 GitHub 撤权 + 重打密钥包 (换新密码)
- 对称性验收 = 跑 `python3 hermes-vps/symmetry/verify.py` 退出 0, 不靠肉眼
