param(
  [Parameter(Mandatory=$true)][string]$Operation,
  [Parameter(Mandatory=$true)][ValidateSet('L1','L2','L3')][string]$RiskLevel,
  [Parameter(Mandatory=$true)][ValidateSet('allow','deny','rollback','need-info')][string]$Decision,
  [Parameter(Mandatory=$true)][string]$Reason,
  [Parameter(Mandatory=$true)][string]$Actor,
  [Parameter(Mandatory=$true)][string]$RequestId,
  [Parameter(Mandatory=$true)][string]$Status,
  [string]$ApprovalChainJson = '[]',
  [string]$LogPath = 'memory-echoDB/indexes/edict-audit-log.jsonl'
)

$dir = Split-Path -Parent $LogPath
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

$approvalChain = @()
try { $approvalChain = $ApprovalChainJson | ConvertFrom-Json } catch { $approvalChain = @() }

$record = [ordered]@{
  request_id = $RequestId
  timestamp = (Get-Date).ToString('o')
  operation = $Operation
  risk_level = $RiskLevel
  decision = $Decision
  reason = $Reason
  approval_chain = $approvalChain
  actor = $Actor
  status = $Status
}

($record | ConvertTo-Json -Compress -Depth 6) | Add-Content -Path $LogPath -Encoding UTF8
Write-Output "ok: audit appended -> $LogPath"