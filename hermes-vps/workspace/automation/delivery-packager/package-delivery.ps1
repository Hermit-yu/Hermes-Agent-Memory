param(
  [Parameter(Mandatory=$true)][string]$ProjectName,
  [Parameter(Mandatory=$true)][string]$SourceRoot,
  [string]$OutRoot = "E:\OpenClawAI_bot\workspace\deliveries",
  [switch]$Zip
)

$DateTag = Get-Date -Format "yyyy-MM-dd"
$Target = Join-Path $OutRoot ("$ProjectName-$DateTag")
New-Item -ItemType Directory -Force -Path $Target | Out-Null
$folders = @('docs','reports','scripts','assets','evidence')
foreach($f in $folders){ New-Item -ItemType Directory -Force -Path (Join-Path $Target $f) | Out-Null }

# baseline copy
Copy-Item -Path (Join-Path $SourceRoot '*') -Destination (Join-Path $Target 'reports') -Recurse -Force -ErrorAction SilentlyContinue

$readme = Join-Path $Target 'README.md'
@"# 交付包：$ProjectName

- 生成时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
- 入口：reports/
- 说明：本包为集中交付，请按目录查阅。
"@ | Set-Content -Path $readme -Encoding UTF8

$manifest = Join-Path $Target 'MANIFEST.txt'
Get-ChildItem -Path $Target -Recurse -File | ForEach-Object { $_.FullName.Replace($Target,'') } | Set-Content -Path $manifest -Encoding UTF8

if($Zip){
  $zipPath = "$Target.zip"
  if(Test-Path $zipPath){ Remove-Item $zipPath -Force }
  Compress-Archive -Path (Join-Path $Target '*') -DestinationPath $zipPath
  Write-Output "ZIP=$zipPath"
}

Write-Output "DELIVERY=$Target"