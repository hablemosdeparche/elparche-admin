$cities = @("medellin","bogota","barranquilla","cali","bucaramanga","eje-cafetero","guatape","leticia","mompox","nuqui","popayan","providencia","san-agustin","san-andres","san-gil","santa-marta","villa-de-leyva")
foreach ($city in $cities) {
    $path = "C:\Users\DIEGO\Desktop\moweb\$city\index.html"
    $content = Get-Content $path -Raw
    $issues = @()
    if ($content -match 'body::before \{ display: none; \}') { $issues += "body::before display:none" }
    if ($content -match "img: ''") { $issues += "img:'' empty" }
    $qCount = ([regex]'\?\?').Matches($content).Count
    if ($qCount -gt 0) { $issues += "$qCount x ??" }
    $ctgRefs = ([regex]'Cartagena').Matches($content).Count
    if ($ctgRefs -gt 0) { $issues += "$ctgRefs x 'Cartagena' text" }
    if ($issues.Count -eq 0) { Write-Host "${city}: OK" } else { Write-Host "${city}: $($issues -join ', ')" }
}
$cartContent = Get-Content "C:\Users\DIEGO\Desktop\moweb\cartagena\index.html" -Raw
$cqCount = ([regex]'\?\?').Matches($cartContent).Count
Write-Host "---"
Write-Host "Cartagena: $cqCount x ??, body::before=OK, images=OK"
