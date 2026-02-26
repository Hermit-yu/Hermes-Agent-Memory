# ROLLBACK_AND_OPERATIONS (R06 Fusion Closeout)

## Rollback Scope
- 回滚对象：R06融合收尾期间新增的收官文档聚合、指标绑定与脚本接线调整。
- 回滚基准点：R05-30封版快照 + R06-16稳定门快照。

## Rollback Procedure (draft)
1. 锁定当前收官快照（文档+metrics）。
2. 恢复到最近稳定快照并重跑：
   - `scripts/assert-strict-gate.ps1`
   - `scripts/assert-weekly-diff-evidence.ps1`
3. 对比回滚前后差异，确认仅撤销R06融合收尾变更。

## Day-2 Operations
- 每日一次门禁快照复核（strict + weekly）
- 发现异常立即写入 `RISK_AND_COMPRESSION.md`
- 大轮次（5轮）执行统一双端同步

## R06-26 Increment
- 回滚与运维说明初版落地，后续补充演练记录与异常处置示例。
