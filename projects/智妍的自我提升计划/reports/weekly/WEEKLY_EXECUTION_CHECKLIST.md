# Weekly Execution Checklist (steady mode)

1. Pre-check previous progress and unfinished list
   - Confirm `reports/rounds/R04-closeout-stability-checklist-2026-02-26.md` still shows unfinished = 0.
   - Confirm last round report `reports/rounds/R05-*.md` next-step has been consumed.

2. Run strict gate assertion (mandatory)
```powershell
powershell -ExecutionPolicy Bypass -File scripts/assert-strict-gate.ps1 -MetricsFile reports/metrics/latest-round-metrics.json
```
- Record PASS/FAIL in weekly report.

3. Run structured diff evidence check (mandatory if diff artifact exists)
```powershell
powershell -ExecutionPolicy Bypass -File scripts/assert-weekly-diff-evidence.ps1 \
  -WeeklyReport reports/weekly/<THIS_WEEK_REPORT>.md \
  -DiffJson reports/metrics/strict-diff-R05-14-sample.json \
  -OutJson reports/metrics/weekly-diff-evidence-check-<RUN_ID>.json
```
- Attach generated JSON artifact path to weekly report.
- Ensure all checks are true and `allPass=true`.

4. Keep steady increment policy
- Only 1-2 verifiable increments per run.
- Every run must land file changes in project directory.

5. Blocking handling
- If blocked, document blocker + workaround plan in current round report.
