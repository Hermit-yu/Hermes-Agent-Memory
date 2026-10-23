# W08 Weekly Report (R05-19 steady run)

- Week: 2026-02-23 ~ 2026-03-01
- Owner: ziyan-plan-background-executor
- Version: v4 (strict + refreshed structured-diff evidence)

## 1) Core Metrics (strict first)
- auditTotal: 16
- auditCompleteRate: 1
- highRiskCount: 14
- highRiskApprovedCount: 12
- highRiskDeniedCount: 2
- uniqueHighRiskOps: 5
- uniquePreflightOps: 5
- strictHighRiskPreflightIntersectOps: 5
- strictPreflightCoverage: 1
- strictMode: structured_only
- compatFallbackRatio: 0
- unknownEventTypeCount: 0

## 2) Strict Gate Result (mandatory)
- Gate-1 `strictPreflightCoverage >= 1.0`: PASS
- Gate-2 `compatFallbackRatio <= 0.0`: PASS
- Gate-3 `unknownEventTypeCount <= 0`: PASS
- Metrics artifact: `reports/metrics/latest-round-metrics.json`

## 3) Structured Diff Evidence
- Diff artifact: `reports/metrics/strict-diff-R05-19-sample.json`
- Weekly evidence check artifact: `reports/metrics/weekly-diff-evidence-check-R05-19.json`
- strictPreflightCoverage: 1
- compatFallbackRatio: 0
- strictFallbackRecords: 0

## 4) Notes
- This weekly instance is generated after refreshing one structured-first regression sample pack.
- Checklist source: `reports/weekly/WEEKLY_EXECUTION_CHECKLIST.md`
