$base = "C:\Users\DIEGO\Desktop\moweb"
$dirs = Get-ChildItem $base -Directory | Where-Object {
  $_.Name -notmatch "^(\.git|\.github|admintaller|cartagena-local-automation|elparche-agent|reportes|submissions)$"
}
foreach ($d in $dirs) {
  $htmlPath = Join-Path $d.FullName "index.html"
  $lines = Get-Content $htmlPath
  $changed = $false
  for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    # Fix modal-barrio
    if ($line -match 'modal-barrio.*innerHTML') {
      $lines[$i] = $line -replace [regex]::Escape('`?? ${p.barrio}'), '`<i class="fa-solid fa-location-dot"></i> ${p.barrio}'
      $changed = $true
    }
    # Fix sharePlace
    if ($line -match 'navigator.share') {
      $cname = $d.Name
      $lines[$i] = "    navigator.share({title:p.name, text:`"Mira este parche en $cname Local: `${p.name} - `${p.barrio}`", url:window.location.href});"
      $changed = $true
    }
  }
  if ($changed) {
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($htmlPath, ($lines -join "`r`n"), $utf8NoBom)
    Write-Output ("Fixed $($d.Name)")
  }
}
