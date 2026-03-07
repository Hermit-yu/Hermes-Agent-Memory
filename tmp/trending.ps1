$ErrorActionPreference = 'Stop'
$u = 'https://github.com/trending?since=daily'
$h = @{
  'User-Agent'      = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0 Safari/537.36'
  'Accept-Language' = 'zh-CN,zh;q=0.9,en;q=0.8'
}
$r = Invoke-WebRequest -Uri $u -Headers $h
$html = $r.Content

# Extract repo articles
$articlePattern = '(?s)<article[^>]*class="Box-row[^"]*"[^>]*>.*?</article>'
$arts = [regex]::Matches($html, $articlePattern) | ForEach-Object { $_.Value }

$repos = @()
foreach ($a in $arts) {
  $m = [regex]::Match($a, '<h2[^>]*>\s*<a[^>]*href="/(?<full>[^"]+)"')
  if (-not $m.Success) { continue }

  $full = $m.Groups['full'].Value.Trim()

  $descMatch = [regex]::Match($a, '(?s)<p[^>]*class="[^"]*col-9[^"]*"[^>]*>(?<d>.*?)</p>')
  $desc = $descMatch.Groups['d'].Value
  $desc = ($desc -replace '<.*?>', ' ' -replace '\s+', ' ').Trim()

  $lang = ([regex]::Match($a, 'itemprop="programmingLanguage"[^>]*>(?<l>[^<]+)<').Groups['l'].Value).Trim()
  if ([string]::IsNullOrWhiteSpace($lang)) { $lang = '-' }

  $today = ([regex]::Match($a, "(?i)(?<n>[0-9,.kK]+)\s+stars\s+today").Groups['n'].Value).Trim()
  if ([string]::IsNullOrWhiteSpace($today)) { $today = '-' }

  $repos += [pscustomobject]@{
    full  = $full
    lang  = $lang
    today = $today
    desc  = $desc
  }
}

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$outPath = 'E:\OpenClawAI_bot\workspace\tmp\trending.json'
$json = $repos | Select-Object -First 20 | ConvertTo-Json -Depth 3
Set-Content -Path $outPath -Value $json -Encoding UTF8
Write-Output $outPath
