param(
    [int]$PairCount = 5
)

$ErrorActionPreference = 'Stop'

if ($PairCount -lt 1) { throw "PairCount must be >= 1" }

$workspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot "../../..")).Path
$auditPath = Join-Path $workspaceRoot "memory-echoDB/indexes/edict-audit-log.jsonl"

if (-not (Test-Path $auditPath)) {
    throw "Audit log not found: $auditPath"
}

$seedOps = @(
    'gateway.restart',
    'fs.write:/projects/demo',
    'cron.update:ziyan-plan',
    'tool.exec:powershell',
    'message.send:telegram'
)

$now = Get-Date
$lines = New-Object System.Collections.Generic.List[string]

for ($i = 0; $i -lt $PairCount; $i++) {
    $idx = $i + 1
    $op = $seedOps[$i % $seedOps.Count]
    $requestId = "R05-2-SAMPLE-{0:d3}" -f $idx
    $ts1 = $now.AddSeconds($i * 7).ToString('o')
    $ts2 = $now.AddSeconds($i * 7 + 2).ToString('o')

    $preflight = [ordered]@{
        case_id = "R05-2-P{0:d3}" -f $idx
        scenario = "R05-2结构化preflight样本"
        request_id = $requestId
        timestamp = $ts1
        risk_level = 'L3'
        event_type = 'preflight'
        phase = 'before_action'
        preflight_flag = $true
        op_key = $op
        operation = "$op preflight"
        decision = 'allow'
        status = 'ok'
        actor = 'r05-2-regression'
    }

    $execute = [ordered]@{
        case_id = "R05-2-E{0:d3}" -f $idx
        scenario = "R05-2结构化execute样本"
        request_id = $requestId
        timestamp = $ts2
        risk_level = 'L3'
        event_type = 'execute'
        phase = 'decision'
        preflight_flag = $false
        op_key = $op
        operation = $op
        decision = 'allow'
        status = 'ok'
        actor = 'r05-2-regression'
    }

    $lines.Add(($preflight | ConvertTo-Json -Compress -Depth 6))
    $lines.Add(($execute | ConvertTo-Json -Compress -Depth 6))
}

Add-Content -Path $auditPath -Value $lines -Encoding UTF8

Write-Host "R05-2 regression samples appended"
Write-Host "- auditPath: $auditPath"
Write-Host "- pairCount: $PairCount"
Write-Host "- recordsAdded: $($PairCount * 2)"