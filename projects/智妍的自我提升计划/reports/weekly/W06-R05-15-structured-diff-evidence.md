# W06 - R05-15 Structured Diff Evidence Weekly Note

- Window: 2026-02-26 ~ 2026-02-26
- Owner: ziyan
- Version: v2 (strict gate)

## 1) Strict gate metrics (latest)
- strictPreflightCoverage: 1.0
- strictMode: structured_only
- compatFallbackRatio: 0.0
- unknownEventTypeCount: 0

## 2) Structured sample diff evidence
- Evidence file: 
reports/metrics/strict-diff-R05-14-sample.json
- strictPreflightCoverage: 1.0
- compatFallbackRatio: 0.0
- strictFallbackRecords: 0
- Gate judgement: PASS

## 3) Verification commands
`powershell
powershell -ExecutionPolicy Bypass -File scripts/assert-strict-gate.ps1 -MetricsFile reports/metrics/latest-round-metrics.json
powershell -ExecutionPolicy Bypass -File scripts/diff-strict-compat-sample.ps1 
  -InputJsonl reports/samples/R05-14-structured-first-regression.jsonl 
  -OutJson rreports/metrics/strict-diff-R05-14-sample.json
`

## 4) Notes
- This week keeps strict as default acceptance gate.
- Structured sample diff evidence is now wired in weekly template for stable reuse.

