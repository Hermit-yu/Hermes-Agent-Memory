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

## 统计口径定义（Round 02 基线）

数据源：`memory-echoDB/indexes/edict-audit-log.jsonl`（JSONL，一行一条审计记录）  
脚本：`scripts/collect-round-metrics.ps1`

### 1) auditTotal
- 定义：统计窗口内可解析审计记录总数。
- 计算：`count(valid_json_records)`。
- 边界：空行/坏 JSON 跳过，不计入总数。

### 2) auditCompleteRate
- 定义：审计关键字段完整率（估算）。
- 关键字段：`request_id, timestamp, operation, risk_level, decision, status, actor`。
- 单条记录得分：`完整字段数 / 关键字段总数`。
- 指标计算：所有记录得分平均值，保留 4 位小数。
- N/A 条件：无记录时当前口径返回 `0`（后续严格口径可升级为 `N/A`）。

### 3) highRiskCount（L3）
- 定义：`risk_level = L3` 的记录数（大小写不敏感）。
- 计算：`count(risk_level == L3)`。

### 4) preflightRelatedCount
- 定义：可识别为“preflight 相关”的记录数。
- 识别规则（估算口径）：
  - `operation` 包含 `preflight`；或
  - `decision` 可识别为 `allow/deny`。
- 说明：当前规则偏宽松，用于快速趋势观测。

### 5) roughPreflightCoverage
- 定义：高风险场景下的 preflight 粗覆盖率。
- 计算：`preflightRelatedCount / highRiskCount`，保留 4 位小数。
- N/A 条件：`highRiskCount = 0` 时返回 `N/A`。

## 口径分层与升级路径

### 当前：估算口径（Round 02）
- 优先目标：快速可运行、可复盘、可跨轮次对比。
- 特征：基于字段启发式识别，容忍历史日志结构不一致。

### 后续：严格口径（建议 Round 03+）
- 引入标准事件模型：统一 `event_type`, `phase`, `decision_source` 字段。
- preflight 识别从“文本匹配”升级为“结构化标记（preflight=true）”。
- 完整率从“关键字段估算”升级为“schema 校验通过率”。
- 统一窗口定义（按业务日/轮次 tag）并补齐缺失 timestamp 的处理策略。
- 指标版本化（`metricsVersion`）确保历史可追溯与可重算。
