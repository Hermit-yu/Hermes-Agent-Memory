# W05-R05-13-latest-window-strict-gate.md

- 周期：2026-02-26 ~ 2026-02-26
- 负责人：智妍
- 数据来源：`reports/metrics/latest-round-metrics.json`
- 目的：在稳态节奏下继续固定“每轮至少一份 strict gate 周报”交付。

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
- strictStructuredRecords: 10
- strictFallbackRecords: 0
- roughPreflightCoverage: 1.0 (raw=1.1429, clamped)

## 2) Strict Gate 验收（每周必填）
- Gate-1 `strictPreflightCoverage >= 1.0`: PASS
- Gate-2 `compatFallbackRatio <= 0.0`: PASS
- Gate-3 `unknownEventTypeCount <= 0`: PASS
- 证据文件：`reports/metrics/latest-round-metrics.json`

证据片段（命令原文 + 输出）：

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

## 3) 本周改进记录
- 将 latest 窗口作为常规周报默认入口，减少人工挑选窗口造成的口径分叉。
- 保持 strict 字段与 `metrics.*` 一一映射，继续以结构化字段优先。

## 4) 下周计划
- 继续每轮 1 次 strict gate 快检并固化到周报。
- 若出现 `strictFallbackRecords > 0`，立即追加根因分析短报。
