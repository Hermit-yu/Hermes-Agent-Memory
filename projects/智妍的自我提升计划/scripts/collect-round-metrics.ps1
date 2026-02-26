param(
    [string]$From,
    [string]$To,
    [string]$RoundId,
    [switch]$IncludeSynthetic
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

function Get-StringProp {
    param(
        [object]$Obj,
        [string]$Name
    )
    if (-not $Obj) { return $null }
    $exists = $Obj.PSObject.Properties.Name -contains $Name
    if (-not $exists) { return $null }
    $v = [string]$Obj.$Name
    if ([string]::IsNullOrWhiteSpace($v)) { return $null }
    return $v.Trim()
}

function Get-BoolProp {
    param(
        [object]$Obj,
        [string]$Name
    )
    if (-not $Obj) { return $null }
    $exists = $Obj.PSObject.Properties.Name -contains $Name
    if (-not $exists) { return $null }

    $raw = $Obj.$Name
    if ($null -eq $raw) { return $null }
    if ($raw -is [bool]) { return [bool]$raw }

    $s = [string]$raw
    if ([string]::IsNullOrWhiteSpace($s)) { return $null }
    switch -Regex ($s.Trim().ToLowerInvariant()) {
        '^(true|1|yes|y)$' { return $true }
        '^(false|0|no|n)$' { return $false }
        default { return $null }
    }
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

$structuredHighRiskCount = 0
$structuredPreflightCount = 0
$compatFallbackHighRiskCount = 0
$compatFallbackPreflightCount = 0
$unknownEventTypeCount = 0

foreach ($r in $records) {
    $filled = 0
    foreach ($f in $keyFields) {
        $exists = $r.PSObject.Properties.Name -contains $f
        if ($exists -and -not [string]::IsNullOrWhiteSpace([string]$r.$f)) { $filled++ }
    }
    $completeScoreSum += ($filled / $keyFields.Count)

    $operation = Get-StringProp -Obj $r -Name 'operation'
    $decision = Get-StringProp -Obj $r -Name 'decision'
    $riskLevel = Get-StringProp -Obj $r -Name 'risk_level'

    $eventType = Get-StringProp -Obj $r -Name 'event_type'
    $phase = Get-StringProp -Obj $r -Name 'phase'
    $opKey = Get-StringProp -Obj $r -Name 'op_key'
    $preflightFlag = Get-BoolProp -Obj $r -Name 'preflight_flag'
    $isSynthetic = Get-BoolProp -Obj $r -Name 'synthetic'
    if (-not $IncludeSynthetic -and $isSynthetic -eq $true) {
        continue
    }

    $effectiveOpKey = $opKey
    $usedFallbackOp = $false
    if ([string]::IsNullOrWhiteSpace($effectiveOpKey) -and -not [string]::IsNullOrWhiteSpace($operation)) {
        $effectiveOpKey = $operation
        $usedFallbackOp = $true
    }

    $isHighRisk = $riskLevel -match '^(?i)L3$'
    $isPreflightOp = $operation -match '(?i)preflight'
    $isRecognizableDecision = $decision -match '^(?i)(allow|deny)$'

    if ($isHighRisk) {
        $highRiskCount++
        if ($decision -match '^(?i)allow$') { $highRiskApprovedCount++ }
        if ($decision -match '^(?i)deny$') { $highRiskDeniedCount++ }

        $isStructuredHighRisk = ($eventType -match '^(?i)execute$') -and -not [string]::IsNullOrWhiteSpace($effectiveOpKey)
        if ($isStructuredHighRisk) {
            [void]$uniqueHighRiskOpsSet.Add($effectiveOpKey)
            if ($usedFallbackOp) { $compatFallbackHighRiskCount++ } else { $structuredHighRiskCount++ }
        }
        elseif (-not [string]::IsNullOrWhiteSpace($eventType) -and $eventType -notmatch '^(?i)(preflight|execute|rollback|audit_only)$') {
            $unknownEventTypeCount++
        }
    }

    $isStructuredPreflight = ($eventType -match '^(?i)preflight$') -and ($preflightFlag -eq $true) -and -not [string]::IsNullOrWhiteSpace($effectiveOpKey)
    if ($isStructuredPreflight) {
        [void]$uniquePreflightOpsSet.Add($effectiveOpKey)
        if ($usedFallbackOp) { $compatFallbackPreflightCount++ } else { $structuredPreflightCount++ }
    }
    elseif (-not [string]::IsNullOrWhiteSpace($eventType) -and $eventType -notmatch '^(?i)(preflight|execute|rollback|audit_only)$') {
        $unknownEventTypeCount++
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
$strictDenominatorRecords = $structuredHighRiskCount + $compatFallbackHighRiskCount
$strictFallbackRecords = $compatFallbackHighRiskCount + $compatFallbackPreflightCount
$strictStructuredRecords = $structuredHighRiskCount + $structuredPreflightCount
$compatFallbackRatio = Get-SafeRatio -Numerator $strictFallbackRecords -Denominator ($strictFallbackRecords + $strictStructuredRecords) -Digits 4
$strictMode = if ($strictFallbackRecords -gt 0) { 'structured_with_fallback' } else { 'structured_only' }

$result = [ordered]@{
    roundId = $RoundId
    metricsVersion = "v3.1-round05-structured-first-nosynth-default"
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
        strictMode = $strictMode
        strictStructuredRecords = $strictStructuredRecords
        strictFallbackRecords = $strictFallbackRecords
        compatFallbackRatio = if ($null -eq $compatFallbackRatio) { 'N/A' } else { $compatFallbackRatio }
        unknownEventTypeCount = $unknownEventTypeCount
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
        strictCoverageRule = "strict(v2): INTERSECT(uniquePreflightOps, uniqueHighRiskOps) / uniqueHighRiskOps; structured fields first(event_type/op_key/preflight_flag), operation fallback enabled"
        strictFallbackRule = "fallback is counted when op_key is missing and operation is used as effectiveOpKey"
        syntheticRule = "synthetic=true records are excluded by default; use -IncludeSynthetic to include them"
        defaultAcceptanceMetricFrom = "Round 03"
        defaultAcceptanceMetric = "strictPreflightCoverage"
    }
}

New-Item -ItemType Directory -Path $metricsDir -Force | Out-Null
$roundFile = Join-Path $metricsDir ("round-metrics-{0}.json" -f $RoundId)
$latestFile = Join-Path $metricsDir "latest-round-metrics.json"

$json = $result | ConvertTo-Json -Depth 12
Set-Content -Path $roundFile -Value $json -Encoding UTF8
Set-Content -Path $latestFile -Value $json -Encoding UTF8

Write-Host "Round Metrics generated"
Write-Host "- roundId: $RoundId"
Write-Host "- metricsVersion: $($result.metricsVersion)"
Write-Host "- includeSynthetic: $IncludeSynthetic"
Write-Host "- auditTotal: $auditTotal"
Write-Host "- auditCompleteRate: $auditCompleteRate"
Write-Host "- highRiskCount: $highRiskCount"
Write-Host "- highRiskApprovedCount: $highRiskApprovedCount"
Write-Host "- highRiskDeniedCount: $highRiskDeniedCount"
Write-Host "- uniqueHighRiskOps: $uniqueHighRiskOps"
Write-Host "- uniquePreflightOps: $uniquePreflightOps"
Write-Host "- strictHighRiskPreflightIntersectOps: $strictIntersectCount"
Write-Host "- strictPreflightCoverage: $(if ($null -eq $strictPreflightCoverage) { 'N/A' } else { $strictPreflightCoverage })"
Write-Host "- strictMode: $strictMode"
Write-Host "- compatFallbackRatio: $(if ($null -eq $compatFallbackRatio) { 'N/A' } else { $compatFallbackRatio })"
Write-Host "- roughPreflightCoverage(estimated): $(if ($null -eq $roughCoverageClamped) { 'N/A' } else { $roughCoverageClamped })"
if ($roughCoverageExplanation) { Write-Host "- roughCoverageExplanation: $roughCoverageExplanation" }
Write-Host "- output: $roundFile"
Write-Host "- latest: $latestFile"
