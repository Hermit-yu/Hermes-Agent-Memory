# METRICS（验收指标）

## 治理与安全
- preflight 覆盖率（高风险）：目标 ≥98%
- 审计完整率：目标 100%
- 高风险误放行率：目标 <1%
- 可验证回滚率：目标 100%

## 执行效率
- 复杂任务一次通过率：目标 ≥85%，长期冲刺 90%+
- 审批平均时延：逐季下降（目标 -30%+）
- 主会话上下文占用：常态 <75%

## 检索与学习
- hitRate/top1/top3：季度持续上升
- feedback→selflearn→regress 闭环执行率：100%
- 回归数据集规模与覆盖面：持续增加

## 体验质量
- 互动风格一致性：长期稳定
- 关键任务过程透明度：持续汇报率 100%
- 提醒文案自然度：避免机械化表达

---

## 统计口径定义（Round 03 起）

数据源：`memory-echoDB/indexes/edict-audit-log.jsonl`（JSONL，一行一条审计记录）  
脚本：`scripts/collect-round-metrics.ps1`

### 1) auditTotal
- 定义：统计窗口内可解析审计记录总数。
- 计算：`count(valid_json_records)`。

### 2) auditCompleteRate
- 定义：审计关键字段完整率（估算）。
- 关键字段：`request_id, timestamp, operation, risk_level, decision, status, actor`。
- 单条记录得分：`完整字段数 / 关键字段总数`。
- 指标计算：所有记录得分平均值，保留 4 位小数。

### 3) highRiskCount / highRiskApprovedCount / highRiskDeniedCount
- `highRiskCount`：`risk_level = L3` 的记录数（大小写不敏感）。
- `highRiskApprovedCount`：L3 且 `decision=allow` 的记录数。
- `highRiskDeniedCount`：L3 且 `decision=deny` 的记录数。

### 4) roughPreflightCoverage（估算口径，保留用于趋势）
- 相关字段：`preflightRelatedCount`。
- 识别规则：`operation` 包含 `preflight`，或 `decision` 可识别为 `allow/deny`。
- 计算：`preflightRelatedCount / highRiskCount`。
- 约束：输出会 clamp 到 `[0,1]`，并附带 explanation；该值标记为 `estimated`。

### 5) strictPreflightCoverage（严格口径，默认验收）
- 相关字段：
  - `uniqueHighRiskOps`：L3 记录的去重 operation 数量。
  - `uniquePreflightOps`：operation 包含 `preflight` 的去重 operation 数量。
  - `strictHighRiskPreflightIntersectOps`：两者交集去重 operation 数量。
- 计算：
  `strictPreflightCoverage = |uniquePreflightOps ∩ uniqueHighRiskOps| / |uniqueHighRiskOps|`
- 约束：结果严格在 `[0,1]`；当 `uniqueHighRiskOps=0` 返回 `N/A`。

---

## 口径分层（Round 03 正式生效）

- **rough（estimated）**：启发式快速趋势观测；允许历史异构日志兼容，但可能高估。
- **strict（default acceptance）**：以去重 operation 交集计算，具备可解释边界，作为验收与对外汇报默认口径。

> 从 **Round 03** 起，`strictPreflightCoverage` 为默认验收口径；`roughPreflightCoverage` 仅作辅助趋势参考。