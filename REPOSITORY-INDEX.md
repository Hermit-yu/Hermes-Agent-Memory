# Hermes-Agent-Memory Repository Index / 仓库导航索引

> This is the short operational map. The full 638-file inventory is archived at `archive/reports/REPOSITORY-ORGANIZATION-REPORT-2026-10-02.md`.
> 这是日常使用的简版地图。638 个文件的完整盘点已归档到上述路径。

## Authority / 权威来源

- `governance/SOURCE-OF-TRUTH.md` — Authority matrix / 权威来源矩阵
- `hermes-vps/SOUL.master.md` — Complete persona master / 完整人格母本
- `hermes-vps/SOUL.core.md` — Runtime core persona / 运行时核心人格
- `hermes-vps/memory/` — Hermes disaster-recovery mirror / Hermes 灾备记忆镜像
- `governance/dual-brain/` — Dual-brain protocols / 双脑协议
- `projects/` — Project-specific source of truth / 各项目事实源

## Directory tree / 目录树

```text
Hermes-Agent-Memory/
├── governance/       Active rules and protocols / 当前治理规则与协议
├── hermes-vps/       Hermes identity and recovery / Hermes 人格与恢复镜像
├── memory-echoDB/    Long-term memory archive / 长期记忆归档
├── memory/           Daily and migration memory / 日志与迁移记忆
├── projects/         Active project sources / 活跃项目源文件
├── skills/           Reusable skill packages / 可复用 Skill 技能包
├── scripts/          Maintained sync utilities / 维护中的同步脚本
├── services/         Service manifests / 服务部署清单
├── ops/              Runbooks and checks / 运维手册与检查
├── deliveries/       Historical delivery snapshots / 历史交付快照
├── archive/          Non-active historical material / 非活跃历史材料
│   ├── tmp/          Old drafts and temporary assets / 旧草稿与临时资产
│   ├── reports/      Historical inventory and reports / 历史盘点与报告
│   └── persona-backups/  Old persona backups / 旧人格备份
├── journals/         Weekly journals / 周记
├── echodb-fusion/    EchoDB fusion and upstream material / EchoDB 融合与上游材料
├── automation/       Legacy automation / 历史自动化
└── reports/          Current standalone reports / 当前独立报告
```

## Status labels / 状态标签

- **AUTHORITY / 权威** — current source of truth / 当前唯一来源
- **RUNTIME MIRROR / 运行时镜像** — synchronized recovery copy / 同步恢复副本
- **ACTIVE / 当前使用** — actively maintained / 当前维护
- **ARCHIVE / 归档** — retained for history, not execution / 仅供追溯，不参与执行
- **LEGACY / 历史兼容** — retained because old workflows may reference it / 因旧流程引用而保留
- **REVIEW / 待复核** — do not delete without a separate decision / 未单独确认前不删除

## Important compatibility files / 重要兼容文件

- Root `SOUL.md`, `MEMORY.md`, and `USER.md` remain as compatibility entry points / 根目录人格、记忆和用户文件继续作为兼容入口。
- Their authoritative Hermes counterparts are under `hermes-vps/` / 真正权威的 Hermes 对应文件位于 `hermes-vps/`。
- `deliveries/` remains in place for old delivery workflows / `deliveries/` 暂保留以兼容历史交付流程。
