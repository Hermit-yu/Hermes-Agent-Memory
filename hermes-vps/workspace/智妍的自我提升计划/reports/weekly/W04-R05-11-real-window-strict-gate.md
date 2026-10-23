# W04-R05-11 真实窗口 strict gate 周报

- 周期：2026-02-26 ~ 2026-02-26
- 负责人：智妍
- 数据来源：`reports/metrics/round-metrics-R05-8.json`（默认不含 synthetic）
- 目的：按 R05-10 下一步要求，补一份真实窗口周报并验证与样例周报模板无漂移。

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
- 证据文件：`reports/metrics/round-metrics-R05-8.json`

证据片段（命令原样 + 输出）：

```powershell
powershell -ExecutionPolicy Bypass -File scripts/assert-strict-gate.ps1 -MetricsFile reports/metrics/round-metrics-R05-8.json
```

```text
Strict Gate Check
- strictPreflightCoverage: 1
- compatFallbackRatio: 0
- unknownEventTypeCount: 0
- result: PASS
```

## 3) 与样例周报模板对比（漂移检查）
- 对比对象：`reports/weekly/W03-R05-9-strict-gate-sample.md`
- 结论：**无模板字段漂移**（strict 字段、Gate-1/2/3、证据块结构一致）。
- 差异仅在：数据来源文件（latest → R05-8 真实窗口）、标题与目的描述。

## 4) 下周计划
- 继续保持每周 1 份真实窗口 strict gate 周报。
- 追加 1 次“latest 与真实窗口”双口径差异快照，提前发现口径漂移。