$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$preflight = Join-Path $scriptDir 'preflight-check.ps1'
$audit = Join-Path $scriptDir 'audit-log.ps1'

function Run-Sim {
  param(
    [string]$Name,
    [string]$Operation,
    [string]$RiskLevel,
    [string]$Token,
    [string]$RequestId
  )

  $result = & $preflight -Operation $Operation -RiskLevel $RiskLevel -ApprovalToken $Token
  Write-Output "[$Name] $result"

  $decision = if ($result -like 'allow*') { 'allow' } else { 'deny' }
  & $audit -Operation $Operation -RiskLevel $RiskLevel -Decision $decision -Reason "simulation" -Actor "simulate-flow" -RequestId $RequestId -Status "executed" | Out-Null
}

Run-Sim -Name '外发消息' -Operation 'message.send.external' -RiskLevel 'L3' -Token '' -RequestId 'SIM-001'
Run-Sim -Name '批量改动' -Operation 'workspace.edit.batch' -RiskLevel 'L2' -Token 'APPROVED' -RequestId 'SIM-002'
Run-Sim -Name 'cron变更' -Operation 'cron.schedule.change' -RiskLevel 'L3' -Token 'APPROVED' -RequestId 'SIM-003'