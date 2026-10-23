$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$WorkspaceRoot = Resolve-Path (Join-Path $ScriptDir "../..")
$Cli = Join-Path $WorkspaceRoot "echodb-fusion/ours/memory-engine/mvp-bm25/bin/echodb-memory.js"

if (-not (Test-Path $Cli)) {
  Write-Error "echodb cli not found: $Cli"
  exit 1
}

$ForwardArgs = $args
& node $Cli @ForwardArgs
exit $LASTEXITCODE
