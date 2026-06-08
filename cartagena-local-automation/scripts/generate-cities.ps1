# GENERADOR DE WEBS PARA CIUDADES V2
$BASE = "C:\Users\DIEGO\Desktop\moweb"
$TEMPLATE_PATH = Join-Path $BASE "cartagena\index.html"
$DATA_JSON = Join-Path $BASE "cartagena-local-automation\scripts\city-data.json"
$PLACES_JSON = Join-Path $BASE "cartagena-local-automation\scripts\city-places.json"

$TEMPLATE_HTML = Get-Content $TEMPLATE_PATH -Raw -Encoding UTF8
$CITIES = Get-Content $DATA_JSON -Raw -Encoding UTF8 | ConvertFrom-Json
$ALL_PLACES = Get-Content $PLACES_JSON -Raw -Encoding UTF8 | ConvertFrom-Json

function Generate-PlacesJS { param($places)
    $lines = @(); $id = 0
    $catOrder = @{"bares"=0; "cafe"=1; "comida"=2; "arte"=3; "plan"=4; "noche"=5}
    $sorted = $places | Sort-Object { $catOrder["$($_.cat)"] }
    $lines += "const places = ["; $currentCat = ""
    foreach ($p in $sorted) {
        $id++; if ($p.cat -ne $currentCat) { $currentCat = $p.cat
            $cn = @{"bares"="BARES"; "cafe"="CAFES"; "comida"="COMIDA"; "arte"="ARTE"; "plan"="PLAN"; "noche"="NOCHE"}[$p.cat]
            $lines += "  // === $cn ===" }
        $t = ($p.tags | % { "'$_'" }) -join ", "; $m = ($p.menu | % { "'$_'" }) -join ", "
        $c = "[$($p.coords[0]), $($p.coords[1])]"
        $n=$p.name-replace"'","'"; $b=$p.barrio-replace"'","'"; $d=$p.desc-replace"'","'"
        $h=$p.horario-replace"'","'"; $r=$p.precio-replace"'","'"
        $tel=$p.telefono-replace"'","'"; $ig=$p.instagram-replace"'","'"
        $lines += "  { id:$id, orden:$($p.orden), bg:'$($p.bg)', cat:'$($p.cat)', name:'$n', barrio:'$b', tags:[$t], rating:$($p.rating), horario:'$h', precio:'$r', desc:'$d', img:'', telefono:'$tel', instagram:'$ig', menu:[$m], coords:$c },"
    }; $lines += "];"; return $lines -join "`r`n" }

function Generate-EventsJS { param($events)
    $lines = @(); $lines += "const eventList = ["
    foreach ($e in $events) { $lines += "  { date:'$($e.date)', endDate:'$($e.endDate)', cat:'$($e.cat)', icon:'$($e.icon)', name:'$($e.name)', place:'$($e.place)', price:'$($e.price)', short:'$($e.short)' }," }
    $lines += "];"; return $lines -join "`r`n" }

function Generate-Html { param($slug, $city)
    Write-Host "Generating $slug..." -NoNewline
    $html = $TEMPLATE_HTML
    
    # Apply ALL CSS variable overrides (dark theme, city-specific)
    $html = $html -creplace "--gold:[^;]*;", "--gold: $($city.gold);"
    $html = $html -creplace "--gold-light:[^;]*;", "--gold-light: $($city.goldLight);"
    $html = $html -creplace "--coral:[^;]*;", "--coral: $($city.coral);"
    $html = $html -creplace "--dark:[^;]*;", "--dark: $($city.dark);"
    $html = $html -creplace "--dark2:[^;]*;", "--dark2: $($city.dark2);"
    $html = $html -creplace "--card-bg:[^;]*;", "--card-bg: $($city.cardBg);"
    $html = $html -creplace "--card-border:[^;]*;", "--card-border: $($city.cardBorder);"
    $html = $html -creplace "--text:[^;]*;", "--text: $($city.text);"
    $html = $html -creplace "--muted:[^;]*;", "--muted: $($city.muted);"
    $html = $html -creplace "--muted2:[^;]*;", "--muted2: $($city.muted2);"
    $html = $html -creplace "--tag-bg:[^;]*;", "--tag-bg: $($city.tagBg);"
    $html = $html -creplace "--nav-bg:[^;]*;", "--nav-bg: $($city.navBg);"

    # Replace ALL #C9983A (old gold) with new gold
    $html = $html -replace "#C9983A", $city.gold

    # Banner gradient
    $html = $html -replace 'background: linear-gradient\(135deg, #2A1505, #1C0F03\)', "background: linear-gradient(135deg, $($city.banner1), $($city.banner2))"
    $html = $html -replace 'border: 1px solid #3D2008', "border: 1px solid $($city.bannerBorder)"

    # Header border
    $r = [Convert]::ToInt32($city.gold.Substring(1,2), 16)
    $g = [Convert]::ToInt32($city.gold.Substring(3,2), 16)
    $b = [Convert]::ToInt32($city.gold.Substring(5,2), 16)
    $rgba = "rgba($r,$g,$b,0.15)"
    $html = $html -replace 'border-bottom: 1px solid rgba\(201,152,58,0\.08\)', "border-bottom: 1px solid $rgba"

    # Title and text
    $html = $html -replace '<title>Cartagena Local.*?</title>', "<title>$($city.title)</title>"
    $html = $html -replace '<h1>Cartagena Local</h1>', "<h1>$($city.logo)</h1>"
    $html = $html -replace 'Lo que hacen de los aqu', $city.subtitle
    $html = $html -replace 'Proximos eventos en Cartagena', $city.eventsText
    $html = $html -replace 'Pro[^ ]* eventos en Cartagena', $city.eventsText

    # Storage key
    $html = $html -replace "'ctg_saved'", "'$($city.storageKey)'"

    # Map
    $html = $html -replace '\.setView\(\[10\.4235,-75\.5470\],14\)', ".setView([$($city.mapCenter)],$($city.mapZoom))"

    # Inject places
    $cp = $ALL_PLACES.$slug
    if ($cp) {
        $np = Generate-PlacesJS $cp.places; $ne = Generate-EventsJS $cp.events
        $i1 = $html.IndexOf("const places = [")
        if ($i1 -ge 0) {
            $sub = $html.Substring($i1); $ci = $sub.IndexOf("];")
            if ($ci -ge 0) { $ci += 2; $html = $html.Substring(0,$i1) + $np + $html.Substring($i1+$ci) } }
        $i2 = $html.IndexOf("const eventList = [")
        if ($i2 -ge 0) {
            $sub2 = $html.Substring($i2); $ci2 = $sub2.IndexOf("];")
            if ($ci2 -ge 0) { $ci2 += 2; $html = $html.Substring(0,$i2) + $ne + $html.Substring($i2+$ci2) } }
    }

    # Remove body noise for cleaner look
    $html = $html -replace 'body::before \{[\s\S]*?\}', "body::before { display: none; }"

    # Write output
    $outDir = Join-Path $BASE $slug
    if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
    $bp = Join-Path $outDir "backup"
    if (-not (Test-Path $bp)) { New-Item -ItemType Directory -Path $bp -Force | Out-Null }
    $outPath = Join-Path $outDir "index.html"
    [System.IO.File]::WriteAllText($outPath, $html, [System.Text.Encoding]::UTF8)
    Write-Host " OK ($($cp.places.Count) places)" }

Write-Host "=== GENERADOR V2 ==="
$slugs = $CITIES | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
foreach ($s in $slugs) { Generate-Html $s $CITIES.$s }
Write-Host "Listo!" -ForegroundColor Green
