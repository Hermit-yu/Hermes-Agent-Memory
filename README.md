# OpenClaw-Memory

> Long-term identity, memory, governance, project source, and recovery archive for Ziyan/Hermes.
> 智妍/Hermes 的长期人格、记忆、治理、项目源文件和恢复归档仓库。

日常先看：[`REPOSITORY-INDEX.md`](REPOSITORY-INDEX.md)（双语仓库导航）。

## Authority / 权威来源

- `governance/SOURCE-OF-TRUTH.md` — authority matrix / 权威来源矩阵
- `hermes-vps/SOUL.master.md` — complete persona master / 完整人格母本
- `hermes-vps/SOUL.core.md` — runtime core persona / 运行时核心人格
- `hermes-vps/memory/` — Hermes disaster-recovery mirror / Hermes 灾备记忆镜像
- `projects/` — project-specific source of truth / 项目事实源

## Main directories / 主要目录

- `governance/` — Active rules and protocols / 当前治理规则与协议
- `hermes-vps/` — Hermes identity and recovery / Hermes 人格与恢复镜像
- `memory-echoDB/` — long-term memory archive / 长期记忆归档
- `memory/` — daily and migration records / 日志与迁移记录
- `projects/` — active project sources / 活跃项目源文件
- `skills/` — reusable Hermes skill packages / 可复用 Hermes Skill 技能包
- `scripts/` — maintained sync utilities / 维护中的同步脚本
- `archive/` — non-active historical material / 非活跃历史材料
- `deliveries/` — compatibility-preserved delivery snapshots / 为兼容保留的交付快照
- `周记/` — weekly journals / 周记

## Legacy compatibility / 历史兼容

Root `SOUL.md`, `MEMORY.md`, and `USER.md` remain as compatibility entry points / 根目录人格、记忆和用户文件继续作为兼容入口；权威 Hermes 文件位于 `hermes-vps/`。

## EchoDB Memory CLI / EchoDB 记忆 CLI

- Legacy entry points: `automation/echodb/echodb.cmd` and `automation/echodb/echodb.ps1`
- Usage: `echodb-fusion/ours/memory-engine/mvp-bm25/docs/USAGE.md`
- Chinese guide: `echodb-fusion/ours/memory-engine/mvp-bm25/docs/操作手册-中文.md`
- Regression: `node echodb-fusion/ours/memory-engine/mvp-bm25/scripts/regression.js`
