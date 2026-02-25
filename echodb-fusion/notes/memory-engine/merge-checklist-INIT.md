# memory-engine 融合记录（INIT）

- 来源仓库：https://github.com/win4r/memory-lancedb-pro
- 引入策略：只学架构与工作流，不直接改变现有文件型记忆习惯
- 当前阶段：Phase A（骨架）

## 本次新增
- 目录骨架：`memory-echoDB/schema`、`memory-echoDB/indexes`
- 规划文档：`echodb-fusion/ours/memory-engine/PLAN.md`
- 同步脚本：`automation/echodb/sync.ps1`

## 风险控制
- indexes 仅存可再生文件（可删可重建）
- upstream 暂不落盘（等你确认是否 vendor）
