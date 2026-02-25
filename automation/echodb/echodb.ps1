param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$Args
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$WorkspaceRoot = Resolve-Path (Join-Path $ScriptDir "../..")
$Cli = Join-Path $WorkspaceRoot "echodb-fusion/ours/memory-engine/mvp-bm25/bin/echodb-memory.js"

if (-not (Test-Path $Cli)) {
  Write-Error "echodb cli not found: $Cli"
  exit 1
}

& node $Cli @Args
exit $LASTEXITCODE
