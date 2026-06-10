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

$results = @()
foreach ($dir in $cities.Keys) {
    $repo = $cities[$dir]
    $path = "C:\Users\DIEGO\Desktop\moweb\$dir\index.html"
    if (-not (Test-Path $path)) {
        $results += "${dir}: FILE NOT FOUND"
        continue
    }
    $content = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes((Get-Content -Path $path -Raw -Encoding UTF8)))
    $uri = "https://api.github.com/repos/$owner/$repo/contents/index.html"
    try {
        $current = Invoke-RestMethod -Uri $uri -Headers @{Authorization = "token $token"} -Method Get -ErrorAction Stop
        $sha = $current.sha
        $body = @{message = "fix: restaurar emojis originales, imagenes Pexels, body::before SVG, URL actualizada"; content = $content; sha = $sha} | ConvertTo-Json
        Invoke-RestMethod -Uri $uri -Headers @{Authorization = "token $token"} -Method Put -Body $body -ContentType "application/json" -ErrorAction Stop | Out-Null
        $results += "${dir}: OK"
    } catch {
        $results += "${dir}: ERROR - $_"
    }
}
$results
