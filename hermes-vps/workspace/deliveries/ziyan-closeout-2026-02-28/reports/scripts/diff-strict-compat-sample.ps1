param(
    [Parameter(Mandatory=$true)][string]$InputJsonl,
    [string]$OutJson
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $InputJsonl)) { throw "Input not found: $InputJsonl" }

$lines = Get-Content -Path $InputJsonl | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
$rows = @()
foreach ($line in $lines) {
    $rows += ($line | ConvertFrom-Json)
}

$highRisk = $rows | Where-Object { $_.risk_level -eq 'L3' }
$execRows = $highRisk | Where-Object { $_.event_type -eq 'execute' }
$preRows = $highRisk | Where-Object { $_.event_type -eq 'preflight' -and $_.preflight_flag -eq $true }

$strictExec = $execRows | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_.op_key) }
$fallbackExec = $execRows | Where-Object { [string]::IsNullOrWhiteSpace([string]$_.op_key) -and -not [string]::IsNullOrWhiteSpace([string]$_.operation) }

$strictPre = $preRows | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_.op_key) }
$fallbackPre = $preRows | Where-Object { [string]::IsNullOrWhiteSpace([string]$_.op_key) -and -not [string]::IsNullOrWhiteSpace([string]$_.operation) }

$opsExec = $strictExec | ForEach-Object { $_.op_key } | Sort-Object -Unique
$opsPre = $strictPre | ForEach-Object { $_.op_key } | Sort-Object -Unique
$inter = @($opsExec | Where-Object { $opsPre -contains $_ })

$strictCoverage = if ($opsExec.Count -eq 0) { 'N/A' } else { [Math]::Round($inter.Count / $opsExec.Count, 4) }
$totalStrict = $strictExec.Count + $strictPre.Count
$totalFallback = $fallbackExec.Count + $fallbackPre.Count
$compatRatio = if (($totalStrict + $totalFallback) -eq 0) { 'N/A' } else { [Math]::Round($totalFallback / ($totalStrict + $totalFallback), 4) }

$result = [ordered]@{
    generatedAt = (Get-Date).ToString('o')
    input = (Resolve-Path $InputJsonl).Path
    metrics = [ordered]@{
        highRiskCount = $highRisk.Count
        uniqueHighRiskOps = $opsExec.Count
        uniquePreflightOps = $opsPre.Count
        strictIntersectOps = $inter.Count
        strictPreflightCoverage = $strictCoverage
        strictStructuredRecords = $totalStrict
        strictFallbackRecords = $totalFallback
        compatFallbackRatio = $compatRatio
    }
}

if (-not [string]::IsNullOrWhiteSpace($OutJson)) {
    $result | ConvertTo-Json -Depth 8 | Set-Content -Path $OutJson -Encoding UTF8
}

$result | ConvertTo-Json -Depth 8
