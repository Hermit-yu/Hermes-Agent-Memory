# Weekly Execution Checklist (steady mode)

1. Pre-check previous progress and unfinished list
   - Confirm `reports/rounds/R04-closeout-stability-checklist-2026-02-26.md` still shows unfinished = 0.
   - Confirm last round report `reports/rounds/R05-*.md` next-step has been consumed.

2. Run strict gate assertion (mandatory)
```powershell
powershell -ExecutionPolicy Bypass -File scripts/assert-strict-gate.ps1 -MetricsFile reports/metrics/latest-round-metrics.json
```
- Record PASS/FAIL in weekly report.
- For R06 ledger runs, also attach latest acceptance JSON (e.g., reports/metrics/r06-03-acceptance-gate.json).

3. Run R04 closeout machine gate snapshot (mandatory)
```powershell
powershell -ExecutionPolicy Bypass -File scripts/verify-r04-closeout.ps1 -ProjectRoot . -OutputJson reports/metrics/r04-closeout-verification-<RUN_ID>.json
```
- Record `verdict.pass` and `verdict.r04UnfinishedItems` in weekly report.

4. Run structured diff evidence check (mandatory if diff artifact exists)
```powershell
$json = powershell -ExecutionPolicy Bypass -File scripts/assert-weekly-diff-evidence.ps1 \\
  -WeeklyReport reports/weekly/<THIS_WEEK_REPORT>.md \\
  -DiffJson reports/metrics/strict-diff-R05-14-sample.json
$json | Set-Content reports/metrics/weekly-diff-evidence-check-<RUN_ID>.json
```
- Attach generated JSON artifact path to weekly report.
- Ensure all checks are true and `allPass=true`.

5. Keep steady increment policy
- Only 1-2 verifiable increments per run.
- Every run must land file changes in project directory.

6. Blocking handling
- If blocked, document blocker + workaround plan in current round report.


