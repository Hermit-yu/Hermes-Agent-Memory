# R05-7 Steady Progress: Structured Regression Diff Check

## 0) Pre-check (previous progress & unfinished list)
- Re-checked `R04-closeout-stability-checklist-2026-02-26.md`.
- R04 closeout unfinished items remain **0/4 done**:
  - Structured field integration plan ✅
  - Regression sample template ✅
  - Weekly report strict integration ✅
  - Round closeout summary ✅

## 1) Increment A (verifiable)
Ran one strict baseline metrics pass (default excludes synthetic):
- Command: `scripts/collect-round-metrics.ps1 -RoundId R05-7`
- Output: `reports/metrics/round-metrics-R05-7.json`
- Key result:
  - `auditTotal=16`
  - `strictPreflightCoverage=1.0`
  - `strictMode=structured_only`
  - `compatFallbackRatio=0`

## 2) Increment B (verifiable)
Ran one include-synthetic comparison pass (diff check):
- Command: `scripts/collect-round-metrics.ps1 -RoundId R05-7-includeSynthetic -IncludeSynthetic`
- Output: `reports/metrics/round-metrics-R05-7-includeSynthetic.json`
- Diff summary (vs default):
  - `auditTotal: 16 -> 18`
  - `highRiskCount: 14 -> 16`
  - `strictPreflightCoverage: 1.0 -> 1.0` (unchanged)
  - `strictMode: structured_only -> structured_only` (unchanged)
  - `compatFallbackRatio: 0 -> 0` (unchanged)

Interpretation: adding synthetic samples only expands volume; strict acceptance indicators remain stable.

## 3) Blocking status
No blocker in this run.

## 4) Next step (steady-first)
Do exactly one small increment next run:
- add an automated assertion script to fail fast when `strictPreflightCoverage < 1` or `compatFallbackRatio > 0` under default window.
