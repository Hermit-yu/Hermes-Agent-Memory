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

function Get-SafeRatio {
    param(
        [double]$Numerator,
        [double]$Denominator,
        [int]$Digits = 4
    )
    if ($Denominator -le 0) { return $null }
    $ratio = $Numerator / $Denominator
    if ($ratio -lt 0) { $ratio = 0 }
    if ($ratio -gt 1) { $ratio = 1 }
    return [Math]::Round($ratio, $Digits)
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
$highRiskApprovedCount = 0
$highRiskDeniedCount = 0

$uniqueHighRiskOpsSet = New-Object 'System.Collections.Generic.HashSet[string]'
$uniquePreflightOpsSet = New-Object 'System.Collections.Generic.HashSet[string]'

foreach ($r in $records) {
    $filled = 0
    foreach ($f in $keyFields) {
        $exists = $r.PSObject.Properties.Name -contains $f
        if ($exists -and -not [string]::IsNullOrWhiteSpace([string]$r.$f)) { $filled++ }
    }
    $completeScoreSum += ($filled / $keyFields.Count)

    $operation = [string]$r.operation
    $decision = [string]$r.decision
    $riskLevel = [string]$r.risk_level

    $isHighRisk = $riskLevel -match '^(?i)L3$'
    $isPreflightOp = $operation -match '(?i)preflight'
    $isRecognizableDecision = $decision -match '^(?i)(allow|deny)$'

    if ($isHighRisk) {
        $highRiskCount++
        if (-not [string]::IsNullOrWhiteSpace($operation)) {
            [void]$uniqueHighRiskOpsSet.Add($operation)
        }

        if ($decision -match '^(?i)allow$') { $highRiskApprovedCount++ }
        if ($decision -match '^(?i)deny$') { $highRiskDeniedCount++ }
    }

    if ($isPreflightOp) {
        if (-not [string]::IsNullOrWhiteSpace($operation)) {
            [void]$uniquePreflightOpsSet.Add($operation)
        }
    }

    if ($isPreflightOp -or $isRecognizableDecision) { $preflightRelatedCount++ }
}

$auditCompleteRate = if ($auditTotal -gt 0) { [Math]::Round(($completeScoreSum / $auditTotal), 4) } else { 0 }

$roughCoverageRaw = $null
$roughCoverageClamped = $null
$roughCoverageExplanation = ""
if ($highRiskCount -gt 0) {
    $roughCoverageRaw = [Math]::Round(($preflightRelatedCount / $highRiskCount), 4)
    $roughCoverageClamped = Get-SafeRatio -Numerator $preflightRelatedCount -Denominator $highRiskCount -Digits 4
    if ($roughCoverageRaw -gt 1) {
        $roughCoverageExplanation = "estimated ratio exceeded 1 due to heuristic numerator (preflightRelatedCount); output is clamped to 1.0000. strictPreflightCoverage is the default acceptance metric from Round 03."
    }
    else {
        $roughCoverageExplanation = "estimated ratio based on heuristic preflight-related records; retained for trend only."
    }
}
else {
    $roughCoverageExplanation = "highRiskCount=0, estimated ratio is N/A."
}

$uniqueHighRiskOps = $uniqueHighRiskOpsSet.Count
$uniquePreflightOps = $uniquePreflightOpsSet.Count
$strictIntersectCount = 0
if ($uniqueHighRiskOps -gt 0 -and $uniquePreflightOps -gt 0) {
    $intersectSet = New-Object 'System.Collections.Generic.HashSet[string]' ($uniqueHighRiskOpsSet)
    $intersectSet.IntersectWith($uniquePreflightOpsSet)
    $strictIntersectCount = $intersectSet.Count
}

$strictPreflightCoverage = Get-SafeRatio -Numerator $strictIntersectCount -Denominator $uniqueHighRiskOps -Digits 4

$result = [ordered]@{
    roundId = $RoundId
    metricsVersion = "v2-round03-strict"
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
        highRiskApprovedCount = $highRiskApprovedCount
        highRiskDeniedCount = $highRiskDeniedCount
        preflightRelatedCount = $preflightRelatedCount
        uniqueHighRiskOps = $uniqueHighRiskOps
        uniquePreflightOps = $uniquePreflightOps
        strictHighRiskPreflightIntersectOps = $strictIntersectCount
        strictPreflightCoverage = if ($null -eq $strictPreflightCoverage) { 'N/A' } else { $strictPreflightCoverage }
        roughPreflightCoverage = [ordered]@{
            value = if ($null -eq $roughCoverageClamped) { 'N/A' } else { $roughCoverageClamped }
            raw = if ($null -eq $roughCoverageRaw) { 'N/A' } else { $roughCoverageRaw }
            label = "estimated"
            explanation = $roughCoverageExplanation
        }
    }
    assumptions = [ordered]@{
        completenessKeyFields = $keyFields
        preflightRelatedRule = "operation contains preflight OR decision is allow/deny"
        roughCoverageRule = "estimated: preflightRelatedCount / highRiskCount, clamped to [0,1]"
        strictCoverageRule = "strict: INTERSECT(uniquePreflightOps, uniqueHighRiskOps) / uniqueHighRiskOps, N/A if uniqueHighRiskOps=0"
        defaultAcceptanceMetricFrom = "Round 03"
        defaultAcceptanceMetric = "strictPreflightCoverage"
    }
}

New-Item -ItemType Directory -Path $metricsDir -Force | Out-Null
$roundFile = Join-Path $metricsDir ("round-metrics-{0}.json" -f $RoundId)
$latestFile = Join-Path $metricsDir "latest-round-metrics.json"

$json = $result | ConvertTo-Json -Depth 10
Set-Content -Path $roundFile -Value $json -Encoding UTF8
Set-Content -Path $latestFile -Value $json -Encoding UTF8

Write-Host "Round Metrics generated"
Write-Host "- roundId: $RoundId"
Write-Host "- auditTotal: $auditTotal"
Write-Host "- auditCompleteRate: $auditCompleteRate"
Write-Host "- highRiskCount: $highRiskCount"
Write-Host "- highRiskApprovedCount: $highRiskApprovedCount"
Write-Host "- highRiskDeniedCount: $highRiskDeniedCount"
Write-Host "- uniqueHighRiskOps: $uniqueHighRiskOps"
Write-Host "- uniquePreflightOps: $uniquePreflightOps"
Write-Host "- strictHighRiskPreflightIntersectOps: $strictIntersectCount"
Write-Host "- strictPreflightCoverage: $(if ($null -eq $strictPreflightCoverage) { 'N/A' } else { $strictPreflightCoverage })"
Write-Host "- roughPreflightCoverage(estimated): $(if ($null -eq $roughCoverageClamped) { 'N/A' } else { $roughCoverageClamped })"
if ($roughCoverageExplanation) { Write-Host "- roughCoverageExplanation: $roughCoverageExplanation" }
Write-Host "- output: $roundFile"
Write-Host "- latest: $latestFile"