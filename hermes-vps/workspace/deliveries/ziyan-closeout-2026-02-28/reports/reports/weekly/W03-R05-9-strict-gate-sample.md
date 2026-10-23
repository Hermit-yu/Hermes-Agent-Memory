# W03-R05-9 strict gate sample weekly report

- 周期：2026-02-26 ~ 2026-02-26
- 负责人：智妍
- 数据来源：`reports/metrics/latest-round-metrics.json`
- 目的：按 R05-9 要求产出一份“可落地填写”的周报样例，并附 strict gate 证据片段。

## 1) 关键指标（strict 默认验收）
- auditTotal: 16
- auditCompleteRate: 1.0
- highRiskCount: 14
- highRiskApprovedCount: 12
- highRiskDeniedCount: 2
- uniqueHighRiskOps: 5
- uniquePreflightOps: 5
- strictHighRiskPreflightIntersectOps: 5
- strictPreflightCoverage: 1.0
- strictMode: structured_only
- compatFallbackRatio: 0.0
- unknownEventTypeCount: 0
- roughPreflightCoverage: 1.0 (raw=1.1429, clamped)

## 2) Strict Gate 验收（每周必填）
- Gate-1 `strictPreflightCoverage >= 1.0`: PASS
- Gate-2 `compatFallbackRatio <= 0.0`: PASS
- Gate-3 `unknownEventTypeCount <= 0`: PASS
- 证据文件：`reports/metrics/latest-round-metrics.json`

证据片段（命令原样 + 输出）：

```powershell
powershell -ExecutionPolicy Bypass -File scripts/assert-strict-gate.ps1 -MetricsFile reports/metrics/latest-round-metrics.json
```

```text
Strict Gate Check
- strictPreflightCoverage: 1
- compatFallbackRatio: 0
- unknownEventTypeCount: 0
- result: PASS
```

## 3) 本周关键事件
- 周报 strict gate 已接入模板，且本样例验证可直接复用。
- 当前口径稳定：strictMode=structured_only，fallback 为 0。

## 4) 下周计划
- 在真实流量窗口复跑一次 strict gate，并保留同格式证据。
- 新增 1 组 structured-first 回归样本，验证指标稳定性。
