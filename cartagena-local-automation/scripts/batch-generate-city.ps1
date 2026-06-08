# BATCH GENERATE - Ilustraciones unicas para todos los lugares de una ciudad
# Uso: .\scripts\batch-generate-city.ps1 -Ciudad cartagena [-Fuerza $false] [-SoloFaltantes $true]

param(
    [string]$Ciudad = "",
    [switch]$Fuerza,
    [switch]$SoloFaltantes
)

$automationDir = Split-Path -Parent $PSScriptRoot
. "$automationDir\config.ps1"
. "$automationDir\scripts\image-manager.ps1"
. "$automationDir\scripts\html-manager.ps1"
. "$automationDir\scripts\excel-manager.ps1"
. "$automationDir\scripts\github-manager.ps1"

function Get-NombreCiudad($slug) {
    if ($CONFIG.CIUDADES.ContainsKey($slug)) { return $CONFIG.CIUDADES[$slug].nombre }
    return $slug
}

function Select-CiudadInteractiva {
    $lista = @($CONFIG.CIUDADES.Keys | Sort-Object)
    Write-Output "SELECCIONA LA CIUDAD:"
    for ($i = 0; $i -lt $lista.Count; $i++) {
        $info = $CONFIG.CIUDADES[$lista[$i]]
        Write-Output "$($i+1). $($info.nombre)"
    }
    Write-Output ""
    $opt = Read-Host "Numero o nombre"
    try {
        $idx = [int]$opt - 1
        if ($idx -ge 0 -and $idx -lt $lista.Count) { return $lista[$idx] }
    } catch {}
    foreach ($s in $lista) {
        $info = $CONFIG.CIUDADES[$s]
        if ($info.nombre -like "*$opt*") { return $s }
    }
    return $null
}

$ciudadSlug = $Ciudad
if ([string]::IsNullOrWhiteSpace($ciudadSlug)) {
    $ciudadSlug = Select-CiudadInteractiva
    if (!$ciudadSlug) { Write-Output "Cancelado."; exit }
}

$cfg = Get-CiudadConfig $ciudadSlug
if (!$cfg) { Write-Output "Ciudad no valida."; exit }

$CONFIG.HTML_PATH = $cfg.htmlPath
$CONFIG.BACKUP_DIR = $cfg.backupDir
$CONFIG.GIT_REPO_DIR = $cfg.gitDir
$CONFIG.EXCEL_PATH = $cfg.excelPath

Write-Output "`n============================================"
Write-Output "  GENERANDO ILUSTRACIONES"
Write-Output "  Ciudad: $(Get-NombreCiudad $cfg.slug)"
Write-Output "  Fuerza: $(if($Fuerza){'SI (todas)'}else{if($SoloFaltantes){'Solo faltantes'}else{'Solo genericas'}})"
Write-Output "============================================"

$htmlContent = Read-HtmlContent
$places = Get-PlacesFromHtml
if ($places.Count -eq 0) { Write-Output "No se encontraron lugares en el HTML."; exit }

$ciudadNombre = Get-NombreCiudad $cfg.slug

# Backup
Backup-Html

# Identificar imagenes genericas (las 4 de ImgBB)
$genericasUrls = @(
    "https://i.ibb.co/6cc1g8Tw/0845a6b976b4.png",
    "https://i.ibb.co/RpjR62sR/fd4944ca5116.png",
    "https://i.ibb.co/pNZSxHT/d18b1e2d2f09.png",
    "https://i.ibb.co/WpfBh7d0/1e96bca95312.png"
)

$exitos = 0
$fallos = 0
$saltados = 0
$total = $places.Count

foreach ($place in $places) {
    Write-Output "`n[$($exitos+$fallos+$saltados+1)/$total] $($place.name)..."
    
    # Determinar si necesita nueva imagen
    $tieneGenerica = $genericasUrls -contains $place.img
    $tieneImagen = ![string]::IsNullOrWhiteSpace($place.img) -and !$tieneGenerica
    
    if ($SoloFaltantes -and $tieneImagen -and !$Fuerza) {
        Write-Output "  Ya tiene imagen personalizada. Saltando."
        $saltados++
        continue
    }
    
    if (!$tieneGenerica -and !$Fuerza) {
        Write-Output "  Ya tiene imagen (no generica). Saltando."
        $saltados++
        continue
    }
    
    # Generar y subir imagen
    $imgUrl = Auto-ProcessImageForPlace $place.name $place.cat $ciudadNombre
    if ($imgUrl) {
        Update-PlaceInHtml $place.name @{ img = $imgUrl }
        Write-Output "  IMAGEN ASIGNADA: $imgUrl"
        $exitos++
    } else {
        Write-Output "  FALLO al generar imagen"
        $fallos++
    }
    
    # Pequena pausa entre cada lugar
    Start-Sleep -Seconds 2
}

Write-Output "`n============================================"
Write-Output "  RESUMEN"
Write-Output "  Total: $total"
Write-Output "  Exitos: $exitos"
Write-Output "  Fallos: $fallos"
Write-Output "  Saltados: $saltados"
Write-Output "============================================"

if ($exitos -gt 0) {
    Write-Output "`nSubiendo cambios a GitHub..."
    Commit-And-Push "Ilustraciones personalizadas para $exitos lugares - $(Get-Date -Format 'yyyy-MM-dd HH:mm')" 2>&1 | Out-Null
    Write-Output "`nLISTO. Las imagenes estan en la web."
    Write-Output "Abre: https://${ciudadSlug}local.github.io/${ciudadSlug}-local/"
}
