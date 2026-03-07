param(
  [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$OutputJson = ''
)

$ErrorActionPreference = 'Stop'

function Exists([string]$relativePath) {
  $full = Join-Path $ProjectRoot $relativePath
  return Test-Path $full
}

$required = @(
  'reports/rounds/R04-closeout-stability-checklist-2026-02-26.md',
  'templates/STRICT_REGRESSION_SAMPLE_TEMPLATE.jsonl',
  'reports/templates/WEEKLY_REPORT_TEMPLATE.md'
)

$fileChecks = @()
foreach ($rel in $required) {
  $fileChecks += [pscustomobject]@{
    file = $rel
    exists = (Exists $rel)
  }
}

$jsonlPath = Join-Path $ProjectRoot 'templates/STRICT_REGRESSION_SAMPLE_TEMPLATE.jsonl'
$jsonlValid = $true
$jsonlCount = 0
if (Test-Path $jsonlPath) {
  foreach ($line in Get-Content $jsonlPath) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    try {
      $line | ConvertFrom-Json | Out-Null
      $jsonlCount += 1
    } catch {
      $jsonlValid = $false
      break
    }
  }
} else {
  $jsonlValid = $false
}

$weeklyTemplatePath = Join-Path $ProjectRoot 'reports/templates/WEEKLY_REPORT_TEMPLATE.md'
$strictFields = @('strictPreflightCoverage','strictMode','compatFallbackRatio','unknownEventTypeCount')
$fieldMap = @{}
if (Test-Path $weeklyTemplatePath) {
  $content = Get-Content -Raw $weeklyTemplatePath
  foreach ($f in $strictFields) {
    $fieldMap[$f] = $content.Contains($f)
  }
} else {
  foreach ($f in $strictFields) { $fieldMap[$f] = $false }
}

$allFilesPresent = ($fileChecks | Where-Object { -not $_.exists }).Count -eq 0
$allFieldsMapped = ($fieldMap.GetEnumerator() | Where-Object { -not $_.Value }).Count -eq 0

$result = [pscustomobject]@{
  checkedAt = (Get-Date).ToString('s')
  profile = 'r04-closeout-stability-v1'
  checks = [pscustomobject]@{
    requiredFiles = $fileChecks
    regressionTemplateJsonlValid = $jsonlValid
    regressionTemplateRecordCount = $jsonlCount
    weeklyStrictFields = $fieldMap
  }
  verdict = [pscustomobject]@{
    r04UnfinishedItems = if ($allFilesPresent -and $jsonlValid -and $allFieldsMapped) { 0 } else { 1 }
    pass = ($allFilesPresent -and $jsonlValid -and $allFieldsMapped)
  }
}

$out = $result | ConvertTo-Json -Depth 8
if ($OutputJson) {
  $out | Set-Content -Encoding UTF8 $OutputJson
}
$out
