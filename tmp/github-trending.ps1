$ErrorActionPreference = 'Stop'
$u = 'https://github.com/trending?since=daily'
$r = Invoke-WebRequest -Uri $u -Headers @{ 'User-Agent'='Mozilla/5.0' }
$html = $r.Content
$blocks = $html -split '<article class="Box-row">' | Select-Object -Skip 1
$items = @()
foreach($b in $blocks){
  if($items.Count -ge 10){ break }
  $m = [regex]::Match($b, '<h2[^>]*>\s*<a[^>]*href="\s*/([^"]+)"')
  if(-not $m.Success){ continue }
  $repo = ($m.Groups[1].Value.Trim() -replace '\s','')

  $lang = ''
  $m2 = [regex]::Match($b, 'itemprop="programmingLanguage"[^>]*>\s*([^<]+)')
  if($m2.Success){ $lang = $m2.Groups[1].Value.Trim() }

  $desc = ''
  $m3 = [regex]::Match($b, '<p class="col-9[^"]*"[^>]*>\s*([^<]+?)\s*</p>')
  if($m3.Success){ $desc = ($m3.Groups[1].Value -replace '\s+',' ').Trim() }

  $today = ''
  # GitHub Trending markup varies; catch "X stars today" anywhere in the block.
  $m4 = [regex]::Match($b, '([0-9,]+)\s*stars\s*today')
  if($m4.Success){ $today = $m4.Groups[1].Value.Trim() }

  $items += [pscustomobject]@{ repo=$repo; lang=$lang; today=$today; desc=$desc }
}
$items | ConvertTo-Json -Depth 3
