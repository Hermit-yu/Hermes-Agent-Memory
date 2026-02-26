# R05-8 Steady Progress: Strict Gate Assertion Script

## 0) Pre-check (previous progress & unfinished list)
- Re-checked `reports/rounds/R04-closeout-stability-checklist-2026-02-26.md`.
- R04 closeout unfinished items remain **0/4**:
  - Structured field integration plan ✅
  - Regression sample template ✅
  - Weekly report strict integration ✅
  - Round closeout summary ✅
- Last run next step was: add fast-fail assertion for strict acceptance gates.

## 1) Increment A (verifiable)
Added strict gate assertion script:
- New file: `scripts/assert-strict-gate.ps1`
- Gate defaults:
  - `strictPreflightCoverage >= 1.0`
  - `compatFallbackRatio <= 0.0`
  - `unknownEventTypeCount <= 0`
- Behavior:
  - Any gate violation exits with non-zero code (`exit 2`)
  - Supports custom thresholds via parameters

## 2) Increment B (verifiable)
Executed one strict baseline pass + assertion:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/collect-round-metrics.ps1 -RoundId R05-8
powershell -ExecutionPolicy Bypass -File scripts/assert-strict-gate.ps1 -MetricsFile reports/metrics/round-metrics-R05-8.json
```

Artifacts:
- `reports/metrics/round-metrics-R05-8.json`
- `reports/metrics/latest-round-metrics.json` (updated)

Result:
- `strictPreflightCoverage = 1`
- `compatFallbackRatio = 0`
- `unknownEventTypeCount = 0`
- Gate assertion: **PASS**

## 3) Blocking status
No blocker in this run.

## 4) Next step (steady-first)
Do exactly one small increment next run:
- wire `assert-strict-gate.ps1` into the weekly report generation checklist so weekly output must include gate pass/fail evidence.
