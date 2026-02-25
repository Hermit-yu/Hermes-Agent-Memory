$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Set-Location $root

Write-Host "[EchoDB] selflearn start..."
node "echodb-fusion/ours/memory-engine/mvp-bm25/bin/echodb-memory.js" memory selflearn --once
Write-Host "[EchoDB] selflearn done."
