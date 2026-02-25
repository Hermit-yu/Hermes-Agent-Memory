param(
  [Parameter(Mandatory=$true)][string]$Operation,
  [Parameter(Mandatory=$true)][ValidateSet('L1','L2','L3')][string]$RiskLevel,
  [string]$ApprovalToken = ''
)

$requiresApproval = @('L2','L3') -contains $RiskLevel
$requiresTwoMan = $RiskLevel -eq 'L3'

if ($requiresApproval -and [string]::IsNullOrWhiteSpace($ApprovalToken)) {
  Write-Output "deny: $Operation requires approval token for $RiskLevel"
  exit 1
}

if ($requiresApproval -and $ApprovalToken -ne 'APPROVED') {
  Write-Output "deny: invalid approval token"
  exit 1
}

if ($requiresTwoMan) {
  Write-Output "allow: $Operation $RiskLevel token accepted, two-man rule must be verified in approval chain"
  exit 0
}

Write-Output "allow: $Operation $RiskLevel passed preflight"
exit 0