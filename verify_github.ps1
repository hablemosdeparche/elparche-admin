$token = "REEMPLAZAR_CON_TU_TOKEN"
$owner = "hablemosdeparche"
$cities = @("barranquilla","bogota","bucaramanga","cali","cartagena-local","eje-cafetero","guatape","leticia","medellin","mompox","nuqui","popayan","providencia","san-agustin","san-andres","san-gil","santa-marta","villa-de-leyva")
$allClean = $true
foreach ($city in $cities) {
    $uri = "https://api.github.com/repos/$owner/$city/contents/index.html"
    try {
        $file = Invoke-RestMethod -Uri $uri -Headers @{Authorization = "token $token"} -Method Get -ErrorAction Stop
        $content = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($file.content))
        $lines = ($content -split "`n").Count
        if ($content -match '\?\?') {
            Write-Host "${city}: ?? FOUND (lines: $lines)"
            $allClean = $false
        } else {
            Write-Host "${city}: OK (lines: $lines, size: $($file.size))"
        }
    } catch {
        Write-Host "${city}: ERROR - $_"
    }
}
if ($allClean) { Write-Host "`nALL CLEAN - no ?? en ningun repo" }
