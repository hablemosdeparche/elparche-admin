$cities = @("barranquilla","bogota","bucaramanga","cali","eje-cafetero","guatape","leticia","mompox","nuqui","popayan","providencia","san-agustin","san-andres","san-gil","santa-marta","villa-de-leyva")
foreach ($city in $cities) {
    $path = "C:\Users\DIEGO\Desktop\moweb\$city\index.html"
    $content = Get-Content $path -Raw
    $content = $content -replace '\?\? \$\{p\.barrio\}' , '<i class="fas fa-location-dot"></i> ${p.barrio}'
    Set-Content -Path $path -Value $content -Encoding UTF8 -NoNewline:$false
    Write-Host "${city}: OK"
}
