param(
    [string]$MetricsFile,
    [double]$MinStrictPreflightCoverage = 1.0,
    [double]$MaxCompatFallbackRatio = 0.0,
    [int]$MaxUnknownEventTypeCount = 0
)

$ErrorActionPreference = 'Stop'

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
if ([string]::IsNullOrWhiteSpace($MetricsFile)) {
    $MetricsFile = Join-Path $projectRoot "reports/metrics/latest-round-metrics.json"
}

if (-not (Test-Path $MetricsFile)) {
    throw "Metrics file not found: $MetricsFile"
}

$data = Get-Content -Path $MetricsFile -Raw | ConvertFrom-Json
$metrics = $data.metrics

function To-NumberOrNull {
    param([object]$Value)
    if ($null -eq $Value) { return $null }
    $s = [string]$Value
    if ([string]::IsNullOrWhiteSpace($s) -or $s -eq 'N/A') { return $null }
    try { return [double]$s } catch { return $null }
}

$strictCoverage = To-NumberOrNull $metrics.strictPreflightCoverage
$compatFallback = To-NumberOrNull $metrics.compatFallbackRatio
$unknownEventTypeCount = [int]$metrics.unknownEventTypeCount

$failures = New-Object System.Collections.Generic.List[string]

if ($null -eq $strictCoverage) {
    $failures.Add("strictPreflightCoverage is N/A")
} elseif ($strictCoverage -lt $MinStrictPreflightCoverage) {
    $failures.Add("strictPreflightCoverage=$strictCoverage < $MinStrictPreflightCoverage")
}

if ($null -eq $compatFallback) {
    $failures.Add("compatFallbackRatio is N/A")
} elseif ($compatFallback -gt $MaxCompatFallbackRatio) {
    $failures.Add("compatFallbackRatio=$compatFallback > $MaxCompatFallbackRatio")
}

if ($unknownEventTypeCount -gt $MaxUnknownEventTypeCount) {
    $failures.Add("unknownEventTypeCount=$unknownEventTypeCount > $MaxUnknownEventTypeCount")
}

Write-Host "Strict Gate Check"
Write-Host "- metricsFile: $MetricsFile"
Write-Host "- strictPreflightCoverage: $strictCoverage"
Write-Host "- compatFallbackRatio: $compatFallback"
Write-Host "- unknownEventTypeCount: $unknownEventTypeCount"

if ($failures.Count -gt 0) {
    Write-Host "- result: FAIL" -ForegroundColor Red
    $failures | ForEach-Object { Write-Host "  * $_" -ForegroundColor Red }
    exit 2
}

Write-Host "- result: PASS" -ForegroundColor Green
exit 0
