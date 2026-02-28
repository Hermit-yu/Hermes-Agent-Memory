param(
    [Parameter(Mandatory=$true)][string]$WeeklyReport,
    [Parameter(Mandatory=$true)][string]$DiffJson
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $WeeklyReport)) { throw "Weekly report not found: $WeeklyReport" }
if (-not (Test-Path $DiffJson)) { throw "Diff json not found: $DiffJson" }

$weeklyText = Get-Content -Path $WeeklyReport -Raw
$diff = Get-Content -Path $DiffJson -Raw | ConvertFrom-Json

$coverage = [string]$diff.metrics.strictPreflightCoverage
$ratio = [string]$diff.metrics.compatFallbackRatio
$fallback = [string]$diff.metrics.strictFallbackRecords

$checks = [ordered]@{
    containsArtifactPath = $weeklyText -match [regex]::Escape($DiffJson.Replace('\\','/'))
    containsCoverage = $weeklyText -match "strictPreflightCoverage\s*[:=]\s*$([regex]::Escape($coverage))"
    containsCompatRatio = $weeklyText -match "compatFallbackRatio\s*[:=]\s*$([regex]::Escape($ratio))"
    containsFallbackRecords = $weeklyText -match "strictFallbackRecords\s*[:=]\s*$([regex]::Escape($fallback))"
}

$allPass = ($checks.Values | Where-Object { -not $_ }).Count -eq 0
$result = [ordered]@{
    generatedAt = (Get-Date).ToString('o')
    weeklyReport = (Resolve-Path $WeeklyReport).Path
    diffJson = (Resolve-Path $DiffJson).Path
    checks = $checks
    allPass = $allPass
}

if (-not $allPass) {
    $result | ConvertTo-Json -Depth 8
    throw 'Weekly report and diff evidence are inconsistent.'
}

$result | ConvertTo-Json -Depth 8
