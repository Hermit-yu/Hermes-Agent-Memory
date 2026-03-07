# WXX Weekly Report Template

- Week: YYYY-MM-DD ~ YYYY-MM-DD
- Owner:
- Version: v3 (strict + r04-closeout + structured-diff evidence)

## 1) Core Metrics (strict first)
- auditTotal
- auditCompleteRate
- highRiskCount
- highRiskApprovedCount
- highRiskDeniedCount
- uniqueHighRiskOps
- uniquePreflightOps
- strictHighRiskPreflightIntersectOps
- strictPreflightCoverage (strict gate primary)
- strictMode (structured_only / structured_with_fallback)
- compatFallbackRatio (structured fallback ratio)
- unknownEventTypeCount (enum drift)
- roughPreflightCoverage (estimated, reference only)

## 2) Strict Gate Result (mandatory)
- Gate-1 `strictPreflightCoverage >= 1.0`: PASS / FAIL
- Gate-2 `compatFallbackRatio <= 0.0`: PASS / FAIL
- Gate-3 `unknownEventTypeCount <= 0`: PASS / FAIL
- Metrics artifact: `reports/metrics/latest-round-metrics.json`

Verification command:
```powershell
powershell -ExecutionPolicy Bypass -File scripts/assert-strict-gate.ps1 -MetricsFile reports/metrics/latest-round-metrics.json
```

## 3) R04 Closeout Snapshot (mandatory)
- R04 closeout artifact: `reports/metrics/r04-closeout-verification-<RUN_ID>.json`
- `verdict.pass`: true / false
- `verdict.r04UnfinishedItems`: 0 / n

Verification command:
```powershell
powershell -ExecutionPolicy Bypass -File scripts/verify-r04-closeout.ps1 -ProjectRoot . -OutputJson reports/metrics/r04-closeout-verification-<RUN_ID>.json
```

## 4) Structured Diff Evidence (recommended; required when sample is updated)
- Diff artifact: `reports/metrics/strict-diff-R05-14-sample.json`
- Weekly evidence check artifact: `reports/metrics/weekly-diff-evidence-check-<RUN_ID>.json`

Verification commands:
```powershell
powershell -ExecutionPolicy Bypass -File scripts/diff-strict-compat-sample.ps1 \
  -InputJsonl reports/samples/R05-14-structured-first-regression.jsonl \
  -OutJson reports/metrics/strict-diff-R05-14-sample.json

$json = powershell -ExecutionPolicy Bypass -File scripts/assert-weekly-diff-evidence.ps1 \\
  -WeeklyReport reports/weekly/<THIS_WEEK_REPORT>.md \\
  -DiffJson reports/metrics/strict-diff-R05-14-sample.json
$json | Set-Content reports/metrics/weekly-diff-evidence-check-<RUN_ID>.json
```

Required evidence fields in weekly report:
- diff artifact path
- strictPreflightCoverage
- compatFallbackRatio
- strictFallbackRecords

## 5) Key Events
- Event 1
  - Background:
  - Impact:
  - Resolution:
  - Status:

## 6) Improvements Completed
- Item A
- Item B

## 7) Next Week Plan
- Plan 1
- Plan 2
- Plan 3

## 8) Notes
- Data source: `scripts/collect-round-metrics.ps1` + `reports/metrics/latest-round-metrics.json`
- Strict baseline: Round 03
