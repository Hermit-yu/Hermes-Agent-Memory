# EDICT 审批矩阵（操作→风险→审批链）

| 操作 | 风险等级 | 是否双人规则 | 审批链 | 备注 |
|---|---|---|---|---|
| workspace.edit.single | L1 | 否 | 无（自动） | 默认允许，必须留审计 |
| workspace.edit.batch | L2 | 否 | 门下省 | 变更文件数≥10 必须审批 |
| message.send.external | L3 | 是 | 门下省 → 刑部 | 对外发送前必须双签 |
| cron.schedule.change | L3 | 是 | 门下省 → 工部 | 变更生效前需回滚点 |

## 快速规则
- L1：可直通执行，但必须记录审计。
- L2：必须有审批 token（`APPROVED`）。
- L3：必须双人审批（two-man rule）+ 审计必填。
- 任何缺失审计字段的操作，一律视为 `deny`。