# W02-R05-2 strict回放周报

- 周期：2026-02-26（R05-2 专项）
- 负责人：智妍
- 数据来源：`reports/metrics/round-metrics-R05-2.json`

## 1) strict主指标（默认验收）
- strictPreflightCoverage：**1.0**
- strictHighRiskPreflightIntersectOps：5
- uniqueHighRiskOps：5
- uniquePreflightOps：5
- strictMode：structured_only
- compatFallbackRatio：0.0

## 2) 本次变更与验证
- 新增：`scripts/apply-r05-2-regression.ps1`
  - 作用：向审计日志追加结构化 preflight/execute 成对样本（同 op_key）
- 执行回放：
  - `powershell -ExecutionPolicy Bypass -File projects/智妍的自我提升计划/scripts/collect-round-metrics.ps1 -RoundId R05-2`
- 产物：
  - `reports/metrics/round-metrics-R05-2.json`
  - `reports/metrics/latest-round-metrics.json`

## 3) 风险与结论
- 结论：strict口径已进入“可计算且可复现”状态。
- 风险：当前提升来自回归注入样本，不等价于真实上游流量稳定性。

## 4) 下一步
1. R05-3 优先项：上游审计写入链路实装 `event_type/op_key/preflight_flag`。
2. 关闭注入依赖后复跑，目标：strictPreflightCoverage 在真实流量下保持可计算。