<#
.WEBSERVER
  WEB PROCESSOR - Cartagena Local
  Procesa formularios web automaticamente:
  1. Recibe datos del formulario
  2. Genera ilustracion con Pollinations.ai
  3. Sube a ImgBB
  4. Actualiza HTML de la ciudad
  5. Actualiza Excel de gestion
  6. Push a GitHub
#>

if (!$CONFIG) { . "$PSScriptRoot\..\config.ps1" }

function Invoke-PollinationsImage {
    param(
        [string]$VenueName,
        [string]$Category,
        [string]$City,
        [string]$CustomPrompt = ""
    )

    if ($CustomPrompt) {
        $prompt = $CustomPrompt
    } else {
        $catEmoji = $CONFIG.CAT_EMOJIS[$Category]
        $prompt = "flat minimalist vector illustration of a $Category called $VenueName in $City Colombia, $catEmoji style, clean background, no text, tourism guide, vibrant colors, professional"
    }

    $encoded = [System.Web.HttpUtility]::UrlEncode($prompt)
    $url = "$($CONFIG.POLLINATIONS_URL)/$($encoded)?width=$($CONFIG.POLLINATIONS_WIDTH)&height=$($CONFIG.POLLINATIONS_HEIGHT)&model=$($CONFIG.POLLINATIONS_MODEL)&nologo=true"

    Write-Output "Generando ilustracion con Pollinations.ai..."
    Write-Output "Prompt: $prompt"

    try {
        $tempDir = Join-Path $CONFIG.AUTOMATION_DIR "temp"
        if (!(Test-Path $tempDir)) { New-Item -ItemType Directory -Path $tempDir -Force | Out-Null }
        $outputPath = Join-Path $tempDir "$($VenueName -replace '[^a-zA-Z0-9]','_').jpg"

        $wc = [System.Net.WebClient]::new()
        $wc.DownloadFile($url, $outputPath)
        $wc.Dispose()

        if ((Get-Item $outputPath).Length -gt 1000) {
            Write-Output "Ilustracion generada: $outputPath"
            return $outputPath
        }
    } catch {
        Write-Output "Error Pollinations.ai: $($_.Exception.Message)"
    }
    return $null
}

function Invoke-PollinationsWithPhoto {
    param(
        [string]$VenueName,
        [string]$Category,
        [string]$City,
        [string]$PhotoUrl
    )

    $prompt = "convert this photo into a flat minimalist vector illustration of $VenueName in $City Colombia, tourism guide style, vibrant colors, no text"
    $encoded = [System.Web.HttpUtility]::UrlEncode($prompt)
    $url = "$($CONFIG.POLLINATIONS_URL)/$($encoded)?width=1024&height=1024&model=flux&nologo=true"

    Write-Output "Generando ilustracion desde foto con Pollinations.ai..."
    try {
        $tempDir = Join-Path $CONFIG.AUTOMATION_DIR "temp"
        if (!(Test-Path $tempDir)) { New-Item -ItemType Directory -Path $tempDir -Force | Out-Null }
        $outputPath = Join-Path $tempDir "$($VenueName -replace '[^a-zA-Z0-9]','_')_pollinations.jpg"

        $wc = [System.Net.WebClient]::new()
        $wc.DownloadFile($url, $outputPath)
        $wc.Dispose()

        if ((Get-Item $outputPath).Length -gt 1000) {
            Write-Output "Ilustracion generada desde foto: $outputPath"
            return $outputPath
        }
    } catch {
        Write-Output "Error Pollinations.ai con foto: $($_.Exception.Message)"
    }
    return $null
}

function Invoke-UploadToImgBB {
    param([string]$ImagePath)

    if (!(Test-Path $ImagePath)) {
        Write-Output "Imagen no encontrada: $ImagePath"
        return $null
    }

    $apiKey = $CONFIG.IMGBB_API_KEY
    if ([string]::IsNullOrWhiteSpace($apiKey)) {
        Write-Output "IMGBB_API_KEY no configurada"
        return $null
    }

    Write-Output "Subiendo imagen a ImgBB..."
    try {
        $base64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($ImagePath))
        $body = @{ key = $apiKey; image = $base64 }
        $resp = Invoke-RestMethod -Uri "https://api.imgbb.com/1/upload" -Method Post -Body $body -TimeoutSec 60
        if ($resp.status -eq 200) {
            $url = $resp.data.url
            Write-Output "Imagen subida a ImgBB: $url"
            return $url
        }
    } catch {
        Write-Output "Error subiendo a ImgBB: $($_.Exception.Message)"
    }
    return $null
}

function New-VenueObject {
    param(
        [string]$Name,
        [string]$Nit = "",
        [string]$Category,
        [string]$Barrio,
        [string]$Plan,
        [string]$Description = "",
        [string]$Horario = "",
        [string]$Phone = "",
        [string]$Instagram = "",
        [string]$Menu = "",
        [string]$Tags = "",
        [string]$ImageUrl = "",
        [double]$Lat = 0,
        [double]$Lng = 0
    )

    $orden = Get-PlanOrden $Plan
    $precio = $CONFIG.PLAN_PRECIO_TAG[$Plan]
    if (!$precio) { $precio = "$$ Promedio" }

    $tagsArray = @($Category)
    if ($Tags) {
        $userTags = $Tags -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
        $tagsArray = @($Category) + $userTags
    }

    $menuArray = @()
    if ($Menu) {
        $menuArray = $Menu -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    }

    $bg = $CONFIG.BG_CLASSES[$Category]
    if (!$bg) { $bg = "pt1" }

    return @{
        id         = 0
        orden      = $orden
        bg         = $bg
        cat        = $Category
        name       = $Name
        nit        = $Nit
        barrio     = $Barrio
        tags       = $tagsArray
        rating     = 4.5
        horario    = $Horario
        precio     = $precio
        desc       = $Description
        img        = $ImageUrl
        telefono   = $Phone
        instagram  = $Instagram
        menu       = $menuArray
        coords     = @($Lat, $Lng)
        plan       = $Plan
        activo     = $true
    }
}

function Add-VenueToCity {
    param(
        [string]$CitySlug,
        [hashtable]$VenueData
    )

    . "$PSScriptRoot\html-manager.ps1"

    $cfg = Get-CiudadConfig $CitySlug
    if (!$cfg) {
        Write-Error "Ciudad no encontrada: $CitySlug"
        return $false
    }

    $CONFIG.HTML_PATH = $cfg.htmlPath
    $CONFIG.BACKUP_DIR = $cfg.backupDir
    $CONFIG.GIT_REPO_DIR = $cfg.gitDir
    $CONFIG.EXCEL_PATH = $cfg.excelPath

    # Backup
    Backup-Html

    . "$PSScriptRoot\data-manager.ps1"
    # Verificar si ya existe
    $existing = Get-LocalByName $VenueData.name
    $isNew = !$existing

    if ($isNew) {
        $VenueData.id = Get-NextPlaceId
        Add-PlaceToHtml $VenueData
        Write-Output "Nuevo lugar agregado: $($VenueData.name)"
    } else {
        Update-PlaceInHtml $VenueData.name @{
            orden    = $VenueData.orden
            bg       = $VenueData.bg
            barrio   = $VenueData.barrio
            tags     = $VenueData.tags
            horario  = $VenueData.horario
            precio   = $VenueData.precio
            desc     = $VenueData.desc
            img      = $VenueData.img
            telefono = $VenueData.telefono
            instagram = $VenueData.instagram
            menu     = $VenueData.menu
        }
        Write-Output "Lugar actualizado: $($VenueData.name)"
    }

    # Guardar en billing-db.json via data-manager
    Save-Local @{
        Nombre     = $VenueData.name
        NIT        = $VenueData.nit
        Categoria  = $VenueData.cat
        Barrio     = $VenueData.barrio
        Ciudad     = $CitySlug
        Plan       = $VenueData.plan
        Precio     = $VenueData.precio
        FechaVen   = (Get-Date).AddMonths(1).AddDays(7).ToString("yyyy-MM-dd")
        Estado     = "Activo"
        Notas      = "Procesado via web - $(Get-Date -Format 'dd/MM/yyyy')"
    }

    . "$PSScriptRoot\update-venues-json.ps1"
    Update-VenuesJson -Nombre $VenueData.name -Nit $VenueData.nit -Ciudad $CitySlug -Telefono $VenueData.telefono -Activo $true

    Write-Output "Lugar procesado exitosamente en $CitySlug"

    . "$PSScriptRoot\github-manager.ps1"
    $accion = if ($isNew) { "Agregado" } else { "Actualizado" }
    Commit-And-Push "$accion : $($VenueData.name) - $($VenueData.plan) - $(Get-Date -Format 'dd/MM/yyyy')"

    return $true
}

function Update-BillingRecord {
    param(
        [string]$City,
        [string]$VenueName,
        [string]$Plan,
        [string]$FechaReg,
        [string]$FechaVence,
        [bool]$Activo = $true,
        [string]$Estado = "Activo",
        [string]$Notas = ""
    )

    $dbPath = $CONFIG.BILLING_DB
    $db = @{ venues = @() }

    if (Test-Path $dbPath) {
        try {
            $dbContent = Get-Content $dbPath -Raw | ConvertFrom-Json
            $db = @{ venues = @($dbContent.venues) }
        } catch { $db = @{ venues = @() } }
    }

    $idx = -1
    for ($i = 0; $i -lt $db.venues.Count; $i++) {
        if ($db.venues[$i].city -eq $City -and $db.venues[$i].name -eq $VenueName) {
            $idx = $i
            break
        }
    }

    $record = @{
        city       = $City
        name       = $VenueName
        plan       = $Plan
        fechaReg   = $FechaReg
        fechaVence = $FechaVence
        activo     = $Activo
        estado     = $Estado
        notas      = $Notas
        updatedAt  = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    if ($idx -ge 0) {
        $db.venues[$idx] = $record
    } else {
        $db.venues += $record
    }

    $db | ConvertTo-Json -Depth 10 | Set-Content $dbPath
}

function Get-PendingSubmissions {
    $dir = $CONFIG.SUBMISSIONS_DIR
    if (!(Test-Path $dir)) { return @() }

    $pending = Get-ChildItem $dir -Filter "*.json" | Where-Object { $_.Name -like "pending_*" }
    return $pending
}

function Process-SubmissionFile {
    param([string]$FilePath)

    try {
        $data = Get-Content $FilePath -Raw | ConvertFrom-Json
    } catch {
        Write-Output "Error leyendo submission: $_"
        Rename-Item $FilePath "$FilePath.error" -Force
        return $false
    }

    $citySlug = Get-CitySlug $data.ciudad
    if (!$citySlug) {
        Write-Output "Ciudad invalida: $($data.ciudad)"
        Rename-Item $FilePath "$FilePath.error" -Force
        return $false
    }

    Write-Output "Procesando: $($data.nombre) en $($data.ciudad) - Plan $($data.plan)"

    # 1. Generar imagen
    $imgUrl = ""
    if ($data.fotoUrl) {
        $imgPath = Invoke-PollinationsWithPhoto -VenueName $data.nombre -Category $data.categoria -City $data.ciudad -PhotoUrl $data.fotoUrl
        if ($imgPath) { $imgUrl = Invoke-UploadToImgBB $imgPath }
    }
    if (!$imgUrl) {
        $imgPath = Invoke-PollinationsImage -VenueName $data.nombre -Category $data.categoria -City $data.ciudad -CustomPrompt $data.promptPersonalizado
        if ($imgPath) { $imgUrl = Invoke-UploadToImgBB $imgPath }
    }

    # 2. Obtener coordenadas (por defecto centradas en la ciudad)
    $lat = 10.4240; $lng = -75.5510
    if ($data.lat -and $data.lng) { $lat = $data.lat; $lng = $data.lng }

    # 3. Crear objeto venue
    $venue = New-VenueObject -Name $data.nombre -Category $data.categoria -Barrio $data.barrio `
        -Plan $data.plan -Description $data.descripcion -Horario $data.horario `
        -Phone $data.telefono -Instagram $data.instagram -Menu $data.menu `
        -Tags $data.etiquetas -ImageUrl $imgUrl -Lat $lat -Lng $lng

    # 4. Agregar al HTML de la ciudad
    $result = Add-VenueToCity -CitySlug $citySlug -VenueData $venue

    # 5. Renombrar archivo procesado
    if ($result) {
        Rename-Item $FilePath "$($FilePath)_processed" -Force
        Write-Output "PROCESADO EXITOSAMENTE: $($data.nombre)"
    } else {
        Rename-Item $FilePath "$($FilePath)_failed" -Force
        Write-Output "FALLIDO: $($data.nombre)"
    }

    return $result
}

function Process-AllPendingSubmissions {
    $files = Get-PendingSubmissions
    if ($files.Count -eq 0) {
        Write-Output "No hay submissions pendientes."
        return
    }

    Write-Output "Procesando $($files.Count) submission(s) pendiente(s)..."
    $success = 0; $fail = 0
    foreach ($f in $files) {
        if (Process-SubmissionFile $f.FullName) { $success++ } else { $fail++ }
    }
    Write-Output "Resultado: $success exitosos, $fallidos fallidos"
}

function Invoke-ProcessWebSubmission {
    param(
        [string]$Ciudad,
        [string]$Nombre,
        [string]$Nit = "",
        [string]$Categoria,
        [string]$Barrio,
        [string]$Plan,
        [string]$Descripcion = "",
        [string]$Horario = "",
        [string]$Telefono = "",
        [string]$Instagram = "",
        [string]$Menu = "",
        [string]$Etiquetas = "",
        [string]$FotoUrl = "",
        [string]$CustomPrompt = "",
        [double]$Lat = 0,
        [double]$Lng = 0,
        [string]$Accion = "registrar"
    )

    if ($Accion -eq "editar") {
        . "$PSScriptRoot\html-manager.ps1"
        $cfg = Get-CiudadConfig $Ciudad
        $CONFIG.HTML_PATH = $cfg.htmlPath
        $CONFIG.GIT_REPO_DIR = $cfg.gitDir

        $updates = @{}
        if ($Descripcion) { $updates.desc = $Descripcion }
        if ($Horario) { $updates.horario = $Horario }
        if ($Telefono) { $updates.telefono = $Telefono }
        if ($Instagram) { $updates.instagram = $Instagram }
        if ($Menu) { $updates.menu = ($Menu -split ',' | ForEach-Object { $_.Trim() }) }

        if ($FotoUrl) {
            $imgPath = Invoke-PollinationsWithPhoto -VenueName $Nombre -Category $Categoria -City $Ciudad -PhotoUrl $FotoUrl
            if ($imgPath) {
                $imgUrl = Invoke-UploadToImgBB $imgPath
                if ($imgUrl) { $updates.img = $imgUrl }
            }
        }

        if ($updates.Count -gt 0) {
            Update-PlaceInHtml $Nombre $updates
            . "$PSScriptRoot\github-manager.ps1"
            Commit-And-Push "Editado: $Nombre - $(Get-Date -Format 'dd/MM/yyyy')"
            Write-Output "Local editado: $Nombre"
        }
        return
    }

    # Registrar nuevo local
    $imgUrl = ""
    $citySlug = Get-CitySlug $Ciudad
    if ($FotoUrl) {
        $imgPath = Invoke-PollinationsWithPhoto -VenueName $Nombre -Category $Categoria -City $Ciudad -PhotoUrl $FotoUrl
        if ($imgPath) { $imgUrl = Invoke-UploadToImgBB $imgPath }
    }
    if (!$imgUrl) {
        $imgPath = Invoke-PollinationsImage -VenueName $Nombre -Category $Categoria -City $Ciudad
        if ($imgPath) { $imgUrl = Invoke-UploadToImgBB $imgPath }
    }

    $venue = New-VenueObject -Name $Nombre -Nit $Nit -Category $Categoria -Barrio $Barrio -Plan $Plan `
        -Description $Descripcion -Horario $Horario -Phone $Telefono -Instagram $Instagram `
        -Menu $Menu -Tags $Etiquetas -ImageUrl $imgUrl -Lat $Lat -Lng $Lng

    Add-VenueToCity -CitySlug $citySlug -VenueData $venue
}
