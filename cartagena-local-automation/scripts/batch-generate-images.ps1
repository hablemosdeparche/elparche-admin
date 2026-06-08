# BATCH IMAGE GENERATOR - Procesa todos los lugares sin imagen
. "$PSScriptRoot\config.ps1"
. "$PSScriptRoot\scripts\html-manager.ps1"
. "$PSScriptRoot\scripts\image-manager.ps1"
. "$PSScriptRoot\scripts\excel-manager.ps1"

$ciudadSlug = "cartagena"
$cfg = Get-CiudadConfig $ciudadSlug
$CONFIG.HTML_PATH = $cfg.htmlPath
$CONFIG.BACKUP_DIR = $cfg.backupDir
$CONFIG.GIT_REPO_DIR = $cfg.gitDir
$CONFIG.EXCEL_PATH = $cfg.excelPath

Write-Output "Generando imagenes para todos los lugares de $($cfg.nombre)..."
Write-Output ""

$places = Get-PlacesFromHtml
$sinImg = $places | Where-Object { [string]::IsNullOrWhiteSpace($_.img) }
$conImg = $places | Where-Object { ![string]::IsNullOrWhiteSpace($_.img) }

Write-Output "Total: $($places.Count) | Sin imagen: $($sinImg.Count) | Con imagen: $($conImg.Count)"
Write-Output ""

$contador = 0
$total = $sinImg.Count

foreach ($place in $sinImg) {
    $contador++
    $nombre = $place.name
    $cat = $place.cat
    Write-Output "[$contador/$total] $nombre ($cat)"
    Write-Output "----------------------------------------"

    $imgUrl = Auto-ProcessImageForPlace $nombre $cat $cfg.nombre
    if ($imgUrl) {
        Update-PlaceInHtml $nombre @{ img = $imgUrl }
        Write-Output "  IMAGEN AGREGADA: $imgUrl"
    }
    Write-Output ""
}

Write-Output "============================================"
$hechos = ($sinImg | Where-Object {
    $p = Get-PlacesFromHtml | Where-Object { $_.name -eq $_.name }
    $p.img
}).Count
# Aproximacion: contar cuantos tienen img ahora
$finalPlaces = Get-PlacesFromHtml
$finalSinImg = $finalPlaces | Where-Object { [string]::IsNullOrWhiteSpace($_.img) }
Write-Output "Procesados: $contador"
Write-Output "Quedan sin imagen: $($finalSinImg.Count)"

# Push a GitHub
if ($finalSinImg.Count -lt $sinImg.Count) {
    Write-Output ""
    $subir = Read-Host "Subir cambios a GitHub? (s/n)"
    if ($subir -eq "s") {
        Commit-And-Push "Imagenes generadas para $($sinImg.Count - $finalSinImg.Count) lugares - $ciudadSlug"
    }
}
