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

## 恢复方式

```bash
cd /root/Hermes-Agent-Memory && git pull
cp hermes-vps/memory/MEMORY.md /root/.hermes/memories/MEMORY.md
cp hermes-vps/memory/USER.md /root/.hermes/memories/USER.md
cp hermes-vps/SOUL.core.md /root/.hermes/SOUL.md
systemctl restart hermes-gateway
```

恢复前先备份现有文件。需要恢复完整人格资料时读取 `SOUL.master.md`，但不要直接把母本替换为每轮运行文件，除非用户明确要求回退到完整加载模式。

## 失败处理

- exit 2：D3 命中，清除敏感内容后再运行。
- exit 3：rebase 冲突，人工处理。
