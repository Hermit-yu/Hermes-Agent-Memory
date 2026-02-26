# R05-18 Steady Increment: Weekly Instance + Evidence Artifact (2026-02-26)

## 0) Pre-check: previous progress and unfinished list
Checked:
- `reports/rounds/R05-17-steady-weekly-checklist-strict-wiring.md`
- `reports/rounds/R04-closeout-stability-checklist-2026-02-26.md`

Result:
- R04 unfinished checklist remains **0** (structured plan/template/weekly strict/closeout summary all done).
- Last run next step was to generate a real weekly report instance from template and attach machine-check artifact.

## 1) Increment A (verifiable)
Generated weekly report instance from strict template:
- added: `reports/weekly/W07-R05-18-weekly-strict-checklist-run.md`
- includes strict gate result + required diff evidence fields:
  - strictPreflightCoverage: 1
  - compatFallbackRatio: 0
  - strictFallbackRecords: 0

## 2) Increment B (verifiable)
Produced weekly diff evidence consistency artifact and fixed command drift in docs:
- added: `reports/metrics/weekly-diff-evidence-check-R05-18.json` (`allPass=true`)
- updated: `reports/templates/WEEKLY_REPORT_TEMPLATE.md`
- updated: `reports/weekly/WEEKLY_EXECUTION_CHECKLIST.md`

Fix detail:
- Previous docs used a non-existent script parameter `-OutJson`.
- Updated to actual usage: capture script JSON output then write via `Set-Content`.

## 3) Blocking status
Resolved blocker in-run:
- Blocker: `assert-weekly-diff-evidence.ps1` does not accept `-OutJson`.
- Cause: template/checklist command drifted from script signature.
- Solution: use supported parameters only (`-WeeklyReport`, `-DiffJson`) and pipe output to target JSON file.

## 4) Next step
Keep steady mode with one small increment:
- Add one new structured-first regression sample batch, regenerate strict/compat diff artifact, and verify against weekly checklist.
