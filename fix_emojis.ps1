$base = "C:\Users\DIEGO\Desktop\moweb"
$cityDirs = Get-ChildItem $base -Directory | Where-Object { Test-Path (Join-Path $_.FullName "index.html") } | Where-Object { $_.Name -notmatch "^(\.git|\.github|cartagena-local-automation|elparche-agent|reportes|submissions)$" }

foreach ($d in $cityDirs) {
  $htmlPath = Join-Path $d.FullName "index.html"
  $content = Get-Content $htmlPath -Raw
  $original = $content

  # 1. CSS search-box content
  $content = $content -replace "content:\s*'\?\?'", "content: '\f002'; font-family: 'Font Awesome 6 Free'; font-weight: 900"

  # 2. Category pills
  $content = $content -replace '(cat-pill[^>]*>)\?\? Bares', '$1<i class="fa-solid fa-martini-glass-citrus"></i> Bares'
  $content = $content -replace '(cat-pill[^>]*>)\?\? Comida', '$1<i class="fa-solid fa-utensils"></i> Comida'
  $content = $content -replace '(cat-pill[^>]*>)\?\? Planes', '$1<i class="fa-solid fa-calendar-check"></i> Planes'
  $content = $content -replace '(cat-pill[^>]*>)\?\? Arte', '$1<i class="fa-solid fa-palette"></i> Arte'
  $content = $content -replace '(cat-pill[^>]*>)\?\? Noche', '$1<i class="fa-solid fa-moon"></i> Noche'
  $content = $content -replace '(cat-pill[^>]*>)\? Cafés', '$1<i class="fa-solid fa-mug-saucer"></i> Cafés'
  $content = $content -replace '(cat-pill[^>]*>)\? Café', '$1<i class="fa-solid fa-mug-saucer"></i> Café'

  # 3. Banner flame
  $content = $content -replace '(banner-flame">)\?\?', '$1<i class="fa-solid fa-fire"></i>'

  # 4. WA button
  $content = $content -replace '(wa-btn-icon">)\?\?', '$1<i class="fa-solid fa-store"></i>'

  # 5. Event icons - replace icon:'' with empty since we use getEventIcon
  $content = $content -replace "icon:'\?\?'", "icon:''"

  # 6. Event detail rows in JS template literals
  $content = $content -replace '(ev-detail-row"><span>)\?\?(</span> \$\{e\.short\})', '$1<i class="fa-regular fa-calendar"></i>$2'
  $content = $content -replace '(ev-detail-row"><span>)\?\?(</span> \$\{e\.place\})', '$1<i class="fa-solid fa-location-dot"></i>$2'
  $content = $content -replace '(ev-detail-row"><span>)\?\?(</span> \$\{e\.price\})', '$1<i class="fa-solid fa-tag"></i>$2'

  # 7. Place barrio
  $content = $content -replace '(place-barrio">)\?\? \$\{p\.barrio\}', '$1<i class="fa-solid fa-location-dot"></i> ${p.barrio}'
  $content = $content -replace '(popup-barrio">)\?\? \$\{p\.barrio\}', '$1<i class="fa-solid fa-location-dot"></i> ${p.barrio}'
  $content = $content -replace '(modal-barrio\.innerHTML = `)\?\?', '$1<i class="fa-solid fa-location-dot"></i>'

  # 8. Phone icon
  $content = $content -replace '(info-line"><span>)\?\?(</span> <span style="cursor:pointer)', '$1<i class="fa-solid fa-phone"></i>$2'

  # 9. Instagram icon  
  $content = $content -replace '(info-line"><span>)\?\?(</span> <a href="https://instagram)', '$1<i class="fa-brands fa-instagram"></i>$2'

  # 10. Add getEventIcon function before renderEventsList and use it
  if ($content -match "function renderEventsList") {
    $iconFn = "`n`nfunction getEventIcon(cat) {`n  const map = { bares:'<i class=""fa-solid fa-martini-glass-citrus""></i>', cafe:'<i class=""fa-solid fa-mug-saucer""></i>', comida:'<i class=""fa-solid fa-utensils""></i>', arte:'<i class=""fa-solid fa-palette""></i>', plan:'<i class=""fa-solid fa-calendar-check""></i>', noche:'<i class=""fa-solid fa-moon""></i>', cultural:'<i class=""fa-solid fa-masks-theater""></i>' };`n  return map[cat] || '<i class=""fa-regular fa-star""></i>';`n}`n"
    $content = $content -replace "(function renderEventsList)", ($iconFn + "`$1")
    
    # In renderEventsList, change ${e.icon} to ${getEventIcon(e.cat)}
    # The pattern is: etClasses[i % 5]}>${e.icon}<div class=
    $content = $content -replace '(etClasses\[i % 5\]\}>)\$\{e\.icon\}(<div class="ev-badge-full)', '$1${getEventIcon(e.cat)}$2'
  }

  if ($content -ne $original) {
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($htmlPath, $content, $utf8NoBom)
    Write-Output ("FIXED $($d.Name) OK")
  } else {
    Write-Output ("NO CHANGE $($d.Name)")
  }
}
