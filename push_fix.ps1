$token = "REEMPLAZAR_CON_TU_TOKEN"
$owner = "hablemosdeparche"
$cities = @("barranquilla","bogota","bucaramanga","cali","cartagena","eje-cafetero","guatape","leticia","medellin","mompox","nuqui","popayan","providencia","san-agustin","san-andres","san-gil","santa-marta","villa-de-leyva")
$results = @()
foreach ($city in $cities) {
    $path = "C:\Users\DIEGO\Desktop\moweb\$city\index.html"
    $content = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes((Get-Content -Path $path -Raw)))
    $uri = "https://api.github.com/repos/$owner/$city/contents/index.html"
    try {
        $current = Invoke-RestMethod -Uri $uri -Headers @{Authorization = "token $token"} -Method Get -ErrorAction Stop
        $sha = $current.sha
        $body = @{message = "fix: reemplazar emojis corruptos con Font Awesome"; content = $content; sha = $sha} | ConvertTo-Json
        Invoke-RestMethod -Uri $uri -Headers @{Authorization = "token $token"} -Method Put -Body $body -ContentType "application/json" -ErrorAction Stop | Out-Null
        $results += "${city}: OK"
    } catch {
        $results += "${city}: ERROR - $_"
    }
}
$results
