# IMAGE MANAGER - Cartagena Local
# Genera ilustraciones con IA gratis (Hugging Face) y las sube a ImgBB

if (!$CONFIG) { . "$PSScriptRoot\..\config.ps1" }

function Get-ImageDir {
    $dir = Join-Path $CONFIG.GIT_REPO_DIR "imagenes"
    if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    return $dir
}

function Get-ImagePathForPlace($nombre) {
    $dir = Get-ImageDir
    $nombreLower = $nombre.ToLower()
    Get-ChildItem $dir -ErrorAction SilentlyContinue | Where-Object {
        $base = [System.IO.Path]::GetFileNameWithoutExtension($_.Name).ToLower()
        $base -eq $nombreLower -or $base -like "*$nombreLower*"
    } | Select-Object -First 1 -ExpandProperty FullName
}

function Generate-WithHuggingFace {
    param($nombre, $categoria, $ciudad)

    $prompt = "flat minimalist vector illustration of a $categoria called '$nombre' in $ciudad Colombia, no text, clean background, tourism guide style"
    $body = @{ inputs = $prompt } | ConvertTo-Json

    Write-Output "  Generando ilustracion con IA (Hugging Face)..."
    $outputPath = Join-Path (Get-ImageDir) "$nombre.jpg"
    try {
        $resp = Invoke-RestMethod -Uri "https://api-inference.huggingface.co/models/black-forest-labs/FLUX.1-schnell" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 90
        if ($resp -is [System.Byte[]] -and $resp.Length -gt 1000) {
            [IO.File]::WriteAllBytes($outputPath, $resp)
            Write-Output "  Ilustracion generada: $outputPath ($($resp.Length) bytes)"
            return $outputPath
        }
    } catch {
        Write-Output "  Error IA: $($_.Exception.Message)"
    }
    return $null
}

function Upload-ImageToImgBB {
    param($imagePath)

    if (!(Test-Path $imagePath)) {
        Write-Output "  Imagen no encontrada: $imagePath"
        return $null
    }

    $apiKey = $CONFIG.IMGBB_API_KEY
    if ([string]::IsNullOrWhiteSpace($apiKey)) {
        Write-Output "  IMGBB_API_KEY no configurada"
        return $null
    }

    Write-Output "  Subiendo imagen a ImgBB..."
    try {
        $base64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($imagePath))
        $body = @{ key = $apiKey; image = $base64 }
        $resp = Invoke-RestMethod -Uri "https://api.imgbb.com/1/upload" -Method Post -Body $body -TimeoutSec 30
        if ($resp.status -eq 200) {
            $url = $resp.data.url
            Write-Output "  Imagen subida: $url"
            return $url
        }
    } catch {
        Write-Output "  Error subiendo a ImgBB: $($_.Exception.Message)"
    }
    return $null
}

function Auto-ProcessImageForPlace {
    param($nombre, $categoria, $ciudad)

    # 1. Buscar imagen local (si guardaste una con el nombre del local)
    $localImg = Get-ImagePathForPlace $nombre
    if ($localImg) {
        Write-Output "  Imagen local encontrada: $localImg"
        $url = Upload-ImageToImgBB $localImg
        if ($url) { return $url }
    }

    # 2. Generar con IA automaticamente
    $generated = Generate-WithHuggingFace $nombre $categoria $ciudad
    if ($generated) {
        $url = Upload-ImageToImgBB $generated
        if ($url) { return $url }
    }

    Write-Output "  No se pudo obtener imagen para '$nombre'"
    return $null
}
