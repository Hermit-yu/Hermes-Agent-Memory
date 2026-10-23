---
name: hermes-memory-git-sync
description: 把 VPS Hermes（智妍）的运行时记忆与核心人格同步到 Hermes-Agent-Memory 私有仓库，供灾难恢复使用。完整 SOUL 母本由仓库维护，脚本不会覆盖。内置 D3 拦截、幂等提交与冲突中止。
---

# Hermes Memory Git Sync

## 用途

备份落在 `Hermit-yu/Hermes-Agent-Memory` 私有仓库的 `hermes-vps/`：

- `hermes-vps/memory/` ← `/root/.hermes/memories/`
- `hermes-vps/SOUL.core.md` ← `/root/.hermes/SOUL.md`（每轮加载的短版核心人格）
- `hermes-vps/SOUL.md` ← 核心人格兼容镜像
- `hermes-vps/SOUL.master.md` = 完整人格母本，由 Hermes-Agent-Memory 维护；自动同步脚本**不得覆盖**

排除：`*.bak*`、`*.lock`、`*.db*`。

## 权威来源

- 人格母本、治理和项目规则：`governance/SOURCE-OF-TRUTH.md`
- 运行时人格：`hermes-vps/SOUL.core.md`
- 完整人格：`hermes-vps/SOUL.master.md`

## 手动执行

```bash
bash /root/.hermes/scripts/hermes-memory-sync.sh "可选自定义 commit 信息"
```

克隆/脚本缺失时（重装、迁移、或仓库目录被清过）：先 `ssh -T git@github.com` 验认证，`git clone` 到 `/root/Hermes-Agent-Memory`，再按本 skill 的映射语义手动执行（rsync 记忆目录带 `--delete` + 排除项、拷核心 SOUL 两份、母本不动、D3 扫描后 commit + pull --rebase + push）；跑完把 `scripts/hermes-memory-sync.sh` 与定时任务重建回来，避免下次再缺。

## 定时

系统 crontab 每天 UTC 20:00（北京 04:00）自动运行一次，日志：
`/root/.hermes/logs/memory-sync.log`

## 护栏

- D3 命中即中止，绝不 push。
- 无变更不产生空提交。
- 不 force-push。
- `pull --rebase` 冲突时自动 `--abort` 并交人工处理。
- 自动脚本只同步 `memory/`、`SOUL.core.md` 与兼容 `SOUL.md`，不修改 `SOUL.master.md`。
- 本同步属用户已授权的日常外部同步；若用户撤销，应停止定时任务。
- 访问前必须验证 SSH (`ssh -T git@github.com`); 若 crawl/extract 失败，必须报告失败并切换到 SSH/clone 验证，不能假装成功读取。

## 恢复方式

```bash
cd /root/Hermes-Agent-Memory && git pull
cp hermes-vps/memory/MEMORY.md /root/.hermes/memories/MEMORY.md
cp hermes-vps/memory/USER.md /root/.hermes/memories/USER.md
cp hermes-vps/SOUL.core.md /root/.hermes/SOUL.md
systemctl restart hermes-gateway
```

恢复前先备份现有文件。需要恢复完整人格资料时读取 `SOUL.master.md`，但不要直接把母本替换为每轮运行文件，除非用户明确要求回退到完整加载模式。

## 灾备镜像扩展位（用户要求把 Honcho 等本地服务数据一并入库时）

同步范围不止 `hermes-vps/`；本地服务的可恢复镜像落到仓库 `services/<服务名>/`，约定：
- **脱敏配置**：真实 `.env` 不进仓；生成 `env.example`（键名+非敏感值保留，仅 API_KEY/TOKEN/SECRET/PASSWORD 类打码 `***REDACTED***`——别过度打码端口/模型名）；harness 侧配置（如 `honcho.json`）复制后把 `api_key` 打码。
- **数据快照**：关系库用 `pg_dump -Fc` 压缩格式（几十 MB 数据→几百 KB），存 `snapshots/<名>-<YYYYMMDD>.dump`，先 `pg_restore --list` 校验可读再入库。
- **README 写恢复步骤**：重建顺序 + 回填密钥 + 验证查询（如 `SELECT count(*)`），引用相关技能名。
- 入库前对改动目录跑 D3 敏感串扫描（pat 同护栏），命中即 abort 不推。

## 失败处理

- exit 2：D3 命中，清除敏感内容后再运行。
- exit 3：rebase 冲突，人工处理。
