param(
  [string]$Message = "chore: sync echodb",
  [string]$Branch = "main"
)

$ErrorActionPreference = 'Stop'

function Run($cmd) {
  Write-Host "> $cmd"
  iex $cmd
}

Run "git fetch origin"
Run "git pull --rebase origin $Branch"

$st = (git status --porcelain)
if (-not $st) {
  Write-Host "No changes to commit."
  exit 0
}

Run "git add -A"
Run "git commit -m \"$Message\""
Run "git push origin $Branch"

Write-Host "Sync done."
