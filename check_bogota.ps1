$token = "REEMPLAZAR_CON_TU_TOKEN"
$uri = "https://api.github.com/repos/hablemosparche/bogota/contents/index.html"
$file = Invoke-RestMethod -Uri $uri -Headers @{Authorization = "token $token"} -Method Get
$content = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($file.content))
$lines = $content -split "`n"
$i = 0
foreach ($line in $lines) {
    $i++
    if ($line -match '\?\?') {
        Write-Host "Line ${i}: $($line.Trim())"
    }
}
