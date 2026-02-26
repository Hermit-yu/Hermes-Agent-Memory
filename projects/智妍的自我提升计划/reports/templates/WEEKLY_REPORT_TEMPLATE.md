# WXX-治理周报（模板）

- 周期：YYYY-MM-DD ~ YYYY-MM-DD
- 负责人：
- 版本：v1

## 1. 本周指标快照（strict 默认验收）
- auditTotal：
- auditCompleteRate：
- highRiskCount：
- highRiskApprovedCount：
- highRiskDeniedCount：
- uniqueHighRiskOps：
- uniquePreflightOps：
- strictHighRiskPreflightIntersectOps：
- strictPreflightCoverage（默认验收）：
- strictMode（structured_only / structured_with_fallback）：
- compatFallbackRatio（结构化缺失回退占比）：
- unknownEventTypeCount（枚举漂移观测）：
- roughPreflightCoverage（estimated，仅趋势参考）：

## 2. 风险事件
- 事件 1：
  - 现象：
  - 影响：
  - 处置：
  - 当前状态：

## 3. 改进动作（本周完成）
- 动作 A：
- 动作 B：

## 4. 下周计划
- 计划 1：
- 计划 2：
- 计划 3：

## 5. 备注
- 数据来源：`scripts/collect-round-metrics.ps1` + `reports/metrics/latest-round-metrics.json`
- 口径规则：Round 03 起 strict 为默认验收口径。
- strict 字段映射（建议固定）：
  - `strictPreflightCoverage` ← `metrics.strictPreflightCoverage`
  - `strictMode` ← `metrics.strictMode`
  - `compatFallbackRatio` ← `metrics.compatFallbackRatio`
  - `unknownEventTypeCount` ← `metrics.unknownEventTypeCount`
  - `strictHighRiskPreflightIntersectOps` ← `metrics.strictHighRiskPreflightIntersectOps`