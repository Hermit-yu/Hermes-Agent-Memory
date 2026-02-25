param(
    [string]$From,
    [string]$To,
    [string]$RoundId
)

$ErrorActionPreference = 'Stop'

function Parse-DateOrNull {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return $null }
    try { return [DateTimeOffset]::Parse($Value) }
    catch { throw "Invalid date: '$Value'. Use ISO8601 like 2026-02-26T00:00:00+08:00" }
}

$workspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot "../../..")).Path
$inputPath = Join-Path $workspaceRoot "memory-echoDB/indexes/edict-audit-log.jsonl"
$metricsDir = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$metricsDir = Join-Path $metricsDir "reports/metrics"

if (-not (Test-Path $inputPath)) {
    Write-Host "[Friendly] Audit log not found: $inputPath" -ForegroundColor Yellow
    Write-Host "Please initialize/sync memory-echoDB then rerun." -ForegroundColor Yellow
    exit 0
}

$fromDt = Parse-DateOrNull -Value $From
$toDt = Parse-DateOrNull -Value $To
if ($fromDt -and $toDt -and $fromDt -gt $toDt) {
    throw "Invalid range: -From must be <= -To"
}

if ([string]::IsNullOrWhiteSpace($RoundId)) {
    $RoundId = "adhoc-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
}

$keyFields = @('request_id', 'timestamp', 'operation', 'risk_level', 'decision', 'status', 'actor')
$records = New-Object System.Collections.Generic.List[object]

Get-Content -Path $inputPath | ForEach-Object {
    if ([string]::IsNullOrWhiteSpace($_)) { return }
    try { $obj = $_ | ConvertFrom-Json } catch { return }

    $ts = $null
    if ($obj.PSObject.Properties.Name -contains 'timestamp' -and -not [string]::IsNullOrWhiteSpace([string]$obj.timestamp)) {
        try { $ts = [DateTimeOffset]::Parse([string]$obj.timestamp) } catch { $ts = $null }
    }

    if ($fromDt -and $ts -and $ts -lt $fromDt) { return }
    if ($toDt -and $ts -and $ts -gt $toDt) { return }
    if (($fromDt -or $toDt) -and -not $ts) { return }

    $records.Add($obj)
}

$auditTotal = $records.Count
$completeScoreSum = 0.0
$highRiskCount = 0
$preflightRelatedCount = 0

foreach ($r in $records) {
    $filled = 0
    foreach ($f in $keyFields) {
        $exists = $r.PSObject.Properties.Name -contains $f
        if ($exists -and -not [string]::IsNullOrWhiteSpace([string]$r.$f)) { $filled++ }
    }
    $completeScoreSum += ($filled / $keyFields.Count)

    if (([string]$r.risk_level) -match '^(?i)L3$') { $highRiskCount++ }

    $isPreflightOp = ([string]$r.operation) -match '(?i)preflight'
    $isRecognizableDecision = ([string]$r.decision) -match '^(?i)(allow|deny)$'
    if ($isPreflightOp -or $isRecognizableDecision) { $preflightRelatedCount++ }
}

$auditCompleteRate = if ($auditTotal -gt 0) { [Math]::Round(($completeScoreSum / $auditTotal), 4) } else { 0 }
$roughPreflightCoverage = if ($highRiskCount -gt 0) { [Math]::Round(($preflightRelatedCount / $highRiskCount), 4) } else { 'N/A' }

$result = [ordered]@{
    roundId = $RoundId
    generatedAt = (Get-Date).ToString('o')
    sourceFile = $inputPath
    window = [ordered]@{
        from = if ($fromDt) { $fromDt.ToString('o') } else { $null }
        to = if ($toDt) { $toDt.ToString('o') } else { $null }
    }
    metrics = [ordered]@{
        auditTotal = $auditTotal
        auditCompleteRate = $auditCompleteRate
        highRiskCount = $highRiskCount
        preflightRelatedCount = $preflightRelatedCount
        roughPreflightCoverage = $roughPreflightCoverage
    }
    assumptions = [ordered]@{
        completenessKeyFields = $keyFields
        preflightRelatedRule = "operation contains preflight OR decision is allow/deny"
        coverageRule = "preflightRelatedCount / highRiskCount; N/A if highRiskCount=0"
    }
}

New-Item -ItemType Directory -Path $metricsDir -Force | Out-Null
$roundFile = Join-Path $metricsDir ("round-metrics-{0}.json" -f $RoundId)
$latestFile = Join-Path $metricsDir "latest-round-metrics.json"

$json = $result | ConvertTo-Json -Depth 8
Set-Content -Path $roundFile -Value $json -Encoding UTF8
Set-Content -Path $latestFile -Value $json -Encoding UTF8

Write-Host "Round Metrics generated"
Write-Host "- roundId: $RoundId"
Write-Host "- auditTotal: $auditTotal"
Write-Host "- auditCompleteRate: $auditCompleteRate"
Write-Host "- highRiskCount: $highRiskCount"
Write-Host "- preflightRelatedCount: $preflightRelatedCount"
Write-Host "- roughPreflightCoverage: $roughPreflightCoverage"
Write-Host "- output: $roundFile"
Write-Host "- latest: $latestFile"