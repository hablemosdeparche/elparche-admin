$token = "REEMPLAZAR_CON_TU_TOKEN"
$owner = "hablemosdeparche"
$cities = @{
    barranquilla = "barranquilla"
    bogota = "bogota"
    bucaramanga = "bucaramanga"
    cali = "cali"
    cartagena = "cartagena-local"
    "eje-cafetero" = "eje-cafetero"
    guatape = "guatape"
    leticia = "leticia"
    medellin = "medellin"
    mompox = "mompox"
    nuqui = "nuqui"
    popayan = "popayan"
    providencia = "providencia"
    "san-agustin" = "san-agustin"
    "san-andres" = "san-andres"
    "san-gil" = "san-gil"
    "santa-marta" = "santa-marta"
    "villa-de-leyva" = "villa-de-leyva"
}

foreach ($dir in $cities.Keys) {
    $repo = $cities[$dir]
    $uri = "https://api.github.com/repos/$owner/$repo/contents/index.html"
    try {
        $file = Invoke-RestMethod -Uri $uri -Headers @{Authorization = "token $token"} -Method Get -ErrorAction Stop
        $content = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($file.content))
        $issues = @()
        if ($content -notmatch 'fractalNoise') { $issues += "NO_SVG" }
        if ($content -match 'body::before \{ display: none; \}') { $issues += "DISABLED" }
        if ($content -notmatch 'pexels') { $issues += "NO_IMAGES" }
        if ($dir -ne 'cartagena' -and $content -match 'Cartagena') { $issues += "HAS_CARTAGENA" }
        if ($content -match 'cartagenalocal\.github\.io') { $issues += "OLD_URL" }
        if ($content -notmatch 'hablemosdeparche\.github\.io') { $issues += "NO_NEW_URL" }
        if ($content -notmatch '\uD83D\uDD0D') { $issues += "NO_EMOJI" }
        if ($issues.Count -eq 0) { Write-Host "${dir}: OK ($($file.size) bytes)" }
        else { Write-Host "${dir}: $($issues -join ', ') ($($file.size) bytes)" }
    } catch {
        Write-Host "${dir}: FETCH ERROR - $_"
    }
}
