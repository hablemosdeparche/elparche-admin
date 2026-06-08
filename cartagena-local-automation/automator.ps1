# AUTOMATOR AUTONOMO v3.0

. "$PSScriptRoot\config.ps1"
. "$PSScriptRoot\scripts\data-manager.ps1"
. "$PSScriptRoot\scripts\html-manager.ps1"
. "$PSScriptRoot\scripts\github-manager.ps1"
. "$PSScriptRoot\scripts\image-manager.ps1"

$global:CIUDAD_ACTUAL = $null

# ═══════════════════════════════════════
# AYUDA - PARSEO DE MENSAJES
# ═══════════════════════════════════════

function Get-IntentFromMessage($msg) {
    if ($msg -match 'quitar|eliminar|sacar|retirar|borrar') { return "quitar" }
    if ($msg -match 'renovar|recargar|extender|continuar|prorrogar') { return "renovar" }
    return "agregar"
}

function Get-NameFromMessage($msg) {
    $patrones = @(
        'Nombre[:\s]+(.+)',
        'agregar\s+(?:a\s+)?(.+?)(?:\s+al\s+|\s+en\s+|\s+con\s+|\s+plan\s+|\s+barrio\s+|\s+telefono\s+|\s+whatsapp\s+|\s+categoria\s+|\s+$)(?:\r?\n|$)',
        'mi\s+(?:restaurante|negocio|local|empresa|bar|caf[ée]|tienda)\s+(?:se\s+llama\s+)?(.+?)(?:\s+(?:y|que|en|con|est[áa]|queda)\s+|\s*$)',
        'se\s+llama\s+(.+?)(?:\s+y\s+|\s+en\s+|\s+est[áa]\s+|\s+queda\s+|\s+$|\s*$)'
    )
    foreach ($pat in $patrones) {
        if ($msg -match $pat) { return $matches[1].Trim() }
    }
    $lineas = $msg -split "`n"
    foreach ($l in $lineas) {
        $l = $l.Trim()
        if ($l -match '^(?!.*?:)') {
            $l = $l -replace '^(?:Hola|Buenas|Buenos días|Buenas tardes|Quisiera|Me gustaría|Por favor)[\s,;:]*', ''
            $l = $l.Trim()
            if ($l.Length -gt 3 -and $l -notmatch '^(?:qu[eé]|como|cu[aá]ndo|d[oó]nde|cu[aá]l)') {
                $palabras = $l -split '\s+'
                if ($palabras.Count -ge 2 -and $palabras.Count -le 8) { return $l }
            }
        }
    }
    return $null
}

function Get-PlanFromMessage($msg) {
    if ($msg -match 'completo') { return "Completo" }
    if ($msg -match 'd[ée]staca[dt]o') { return "Destacado" }
    if ($msg -match 'verifica[dt]o') { return "Verificado" }
    if ($msg -match 'b[aá]sic[ao]|normal|econ[oó]mico') { return "Presencia Basica" }
    return "Presencia Basica"
}

function Get-CategoryFromMessage($msg) {
    $msgLower = $msg.ToLower()
    if ($msgLower -match '\bcaf[ée]\b|\bcafeter[íi]a\b|\bcafecito\b') { return "cafe" }
    if ($msgLower -match '\bcom[ií]da\b|\bcomer\b|\brestaurante\b|\brapid[oi]\b|\basado\b|\bhamburguesa\b|\bpizza\b|\bparrilla\b|\basadero\b|\bhelader[ií]a\b|\bpanader[ií]a\b') { return "comida" }
    if ($msgLower -match '\barte\b|\bgaler[ií]a\b|\bcultura\b|\bmuseo\b|\btaller\b|\bartesano\b|\bartesan[ií]a\b') { return "arte" }
    if ($msgLower -match '\bplan\b|\bturismo\b|\btour\b|\bexcursi[oó]n\b|\baventura\b|\bgu[ií]a\b') { return "plan" }
    if ($msgLower -match '\bnoche\b|\bdisco\b|\bdiscoteca\b|\brumba\b|\bfiesta\b|\bpub\b|\bclub\b|\bkaraoke\b|\bcervecer[ií]a\b') { return "noche" }
    if ($msgLower -match '\bbar\b|\bbares\b') { return "bares" }
    if ($msgLower -match '\bcategor[ií]a[:\s]+(\w+)') { return $matches[1].ToLower().Trim() }
    return "bares"
}

function Get-BarrioFromMessage($msg) {
    $patrones = @(
        'Barrio[:\s]+(.+?)(?:\r?\n|$)',
        'en\s+el\s+barrio\s+(.+?)(?:\s+y\s+|\s+con\s+|\s+plan\s+|\s+telefono\s+|\s*$)',
        'queda\s+(?:en\s+)?(.+?)(?:\s+y\s+|\s+con\s+|\s+plan\s+|\s*$)',
        'est[áa]\s+(?:en\s+)?(.+?)(?:\s+y\s+|\s+con\s+|\s+plan\s+|\s*$)'
    )
    foreach ($pat in $patrones) {
        if ($msg -match $pat) {
            $b = $matches[1].Trim()
            if ($b.Length -gt 2 -and $b -notmatch '^(?:plan|telefono|whatsapp|instagram|el|la|los|las)') { return $b }
        }
    }
    return "Centro"
}

function Get-PhoneFromMessage($msg) {
    if ($msg -match '(?:Tel[ée]fono|WhatsApp|Celular|Cel|Tel|Whats)[:\s]*(\+?\d[\d\s\-]{6,15})') { return $matches[1].Trim() }
    if ($msg -match '(\+?\d{10,13})') { return $matches[1].Trim() }
    return ""
}

function Get-InstagramFromMessage($msg) {
    if ($msg -match '(?:Instagram|IG)[:\s]*@?([\w._]+)') { return $matches[1].Trim() }
    if ($msg -match '@([\w._]{3,30})') { return $matches[1].Trim() }
    return ""
}

function Get-NitFromMessage($msg) {
    if ($msg -match '(?:NIT|Nit|nit)[:\s]*(\d{5,15})') { return $matches[1].Trim() }
    return ""
}

function Get-HorarioFromMessage($msg) {
    if ($msg -match '(?:Horario|Horarios|Abierto)[:\s]+(.+?)(?:\r?\n|$)') { return $matches[1].Trim() }
    return ""
}

function Get-DescripcionFromMessage($msg) {
    if ($msg -match '(?:Descripci[oó]n|Descripcion)[:\s]+(.+?)(?:\r?\n|$)') { return $matches[1].Trim() }
    return ""
}

function Get-MenuFromMessage($msg) {
    if ($msg -match '(?:Menu|Men[úu]|Productos|Servicios)[:\s]+(.+?)(?:\r?\n|$)') { return $matches[1].Trim() }
    return ""
}

function Get-TagsFromMessage($msg) {
    if ($msg -match '(?:Tags|Etiquetas|Palabras clave)[:\s]+(.+?)(?:\r?\n|$)') { return $matches[1].Trim() }
    return ""
}

# ═══════════════════════════════════════
# LOGICA DE NEGOCIO
# ═══════════════════════════════════════

function Get-Hoy { return (Get-Date -Format "dd/MM/yyyy") }
function Get-FechaVencimiento { return (Get-Date).AddMonths(1).ToString("dd/MM/yyyy") }

function Parse-Date($str) {
    try {
        $parts = $str -split '/'
        if ($parts.Count -eq 3) { return Get-Date "$($parts[2])-$($parts[1])-$($parts[0])" }
    } catch {}
    return $null
}

function Test-Expirado($fechaStr) {
    $fecha = Parse-Date $fechaStr
    if (!$fecha) { return $false }
    return ((Get-Date) -gt $fecha)
}

function Get-EmailForCiudad($slug) {
    $accountsPath = $CONFIG.ACCOUNTS_JSON
    if (!(Test-Path $accountsPath)) { return $null }
    try {
        $accounts = Get-Content $accountsPath -Raw | ConvertFrom-Json
        $found = $accounts | Where-Object { $_.ciudad -eq $slug } | Select-Object -First 1
        if ($found -and $found.usuario) {
            return @{
                usuario = $found.usuario
                correo  = $found.correo
                token   = $found.token
                repoUrl = $found.repoUrl
            }
        }
    } catch { return $null }
    return $null
}

function Get-NombreCiudad($slug) {
    if ($CONFIG.CIUDADES.ContainsKey($slug)) { return $CONFIG.CIUDADES[$slug].nombre }
    return $slug
}

# ═══════════════════════════════════════
# ACCIONES AUTOMATICAS
# ═══════════════════════════════════════

function Auto-CheckExpirados {
    Write-Output "`n--- VERIFICANDO VENCIMIENTOS ---"
    $locales = Get-AllLocales
    $hoyStr = Get-Hoy
    $eliminados = 0
    foreach ($local in $locales) {
        if ($local.Estado -eq "Vencido") { continue }
        $fechaVenStr = $local.FechaVen
        if (Test-Expirado $fechaVenStr) {
            Write-Output "  VENCIDO: $($local.Nombre) - Plan: $($local.Plan) - Vence: $fechaVenStr"
            Save-Local @{
                Nombre     = $local.Nombre
                NIT        = $local.NIT
                Ciudad     = $local.Ciudad
                Plan       = $local.Plan
                Precio     = $local.Precio
                FechaVen   = $fechaVenStr
                Estado     = "Vencido"
                Notas      = "Vencido automaticamente - $hoyStr"
            }
            Remove-PlaceFromHtml $local.Nombre
            $eliminados++
        }
    }
    if ($eliminados -eq 0) { Write-Output "  No hay vencimientos nuevos." }
    else { Write-Output "  $eliminados local(es) vencido(s) procesado(s)." }
}

function Auto-ProcesarMensaje {
    param($msg)

    Write-Output "`n============================================"
    Write-Output "ANALIZANDO MENSAJE..."
    Write-Output "============================================"

    $intencion = Get-IntentFromMessage $msg
    $nombre = Get-NameFromMessage $msg
    $nitDetectado = Get-NitFromMessage $msg
    $planDetectado = Get-PlanFromMessage $msg
    $categoria = Get-CategoryFromMessage $msg
    $barrio = Get-BarrioFromMessage $msg
    $telefono = Get-PhoneFromMessage $msg
    $instagram = Get-InstagramFromMessage $msg
    $horario = Get-HorarioFromMessage $msg
    $desc = Get-DescripcionFromMessage $msg
    $menuTexto = Get-MenuFromMessage $msg

    Write-Output "  Intencion: $intencion"
    Write-Output "  Nombre: $nombre"
    if (!$nombre) { Write-Output "ERROR: No se pudo detectar el nombre del local."; return }

    $local = Get-LocalByName $nombre
    $hoy = Get-Hoy
    $fechaVen = Get-FechaVencimiento

    # ─── QUITAR ───
    if ($intencion -eq "quitar") {
        Write-Output "`n--- QUITANDO LOCAL ---"
        if ($local) {
            Save-Local @{
                Nombre   = $nombre
                NIT      = $local.NIT
                Ciudad   = $local.Ciudad
                Plan     = $local.Plan
                Precio   = $local.Precio
                Estado   = "Eliminado"
                Notas    = "Eliminado por solicitud - $hoy"
            }
        }
        Remove-PlaceFromHtml $nombre
        Commit-And-Push "Eliminado: $nombre - $hoy" 2>&1 | Out-Null
        Write-Output "`nLISTO. Local '$nombre' eliminado."
        return
    }

    # ─── RENOVAR ───
    if ($intencion -eq "renovar") {
        Write-Output "`n--- RENOVANDO LOCAL ---"
        if (!$local) {
            Write-Output "  AVISO: '$nombre' no existe en Excel. Se agregara como nuevo."
            $intencion = "agregar"
        } else {
            Save-Local @{
                NIT        = $local.NIT
                Nombre     = $nombre
                Categoria  = $local.Categoria
                Barrio     = $local.Barrio
                Ciudad     = $local.Ciudad
                Plan       = $planDetectado
                Precio     = $CONFIG.PLANES[$planDetectado]
                FechaReg   = $local.FechaReg
                FechaIni   = $hoy
                FechaVen   = $fechaVen
                Estado     = "Activo"
                MetodoPago = $local.MetodoPago
                Comprobante = "SI"
                Notas      = "Renovado a $planDetectado - $hoy"
            }
            Write-Output "  Local '$nombre' renovado: $planDetectado hasta $fechaVen"
            # Actualizar orden en HTML segun plan
            $planData = Get-PlanDataForPlace $planDetectado
            Update-PlaceInHtml $nombre @{ orden = $planData.orden }
            Commit-And-Push "Renovado: $nombre - $planDetectado - $hoy" 2>&1 | Out-Null
            Write-Output "`nLISTO. Local '$nombre' renovado hasta $fechaVen."
            return
        }
    }

    # ─── AGREGAR / ACTUALIZAR ───
    if ($intencion -eq "agregar") {
        Write-Output "`n--- PROCESANDO LOCAL ---"

        if ($local) {
            Write-Output "  LOCAL EXISTENTE: Plan actual: $($local.Plan) | Estado: $($local.Estado) | Vence: $($local.FechaVen)"
            $planData = Get-PlanDataForPlace $planDetectado

            if ($local.Estado -eq "Vencido" -or $local.Estado -eq "Eliminado") {
                Write-Output "  Reactivando local vencido/eliminado..."
                $notas = "Reactivado - $planDetectado - $hoy"
            } else {
                $notas = "Actualizado a $planDetectado - $hoy"
            }

            Save-Local @{
                NIT        = $local.NIT
                Nombre     = $nombre
                Categoria  = $categoria
                Barrio     = $barrio
                Ciudad     = $local.Ciudad
                Plan       = $planDetectado
                Precio     = $CONFIG.PLANES[$planDetectado]
                FechaReg   = $local.FechaReg
                FechaIni   = $hoy
                FechaVen   = $fechaVen
                Estado     = "Activo"
                MetodoPago = $local.MetodoPago
                Comprobante = "SI"
                Notas      = $notas
            }

            # Si estaba vencido/eliminado, hay que agregarlo de vuelta al HTML
            if ($local.Estado -eq "Vencido" -or $local.Estado -eq "Eliminado") {
                $htmlPlaces = Get-PlacesFromHtml
                $usedBgs = $htmlPlaces | Where-Object { $_.cat -eq $categoria } | ForEach-Object { $_.bg }
                $bg = Get-BgClass $categoria $usedBgs
                $newPlace = @{
                    id        = (Get-NextPlaceId)
                    orden     = $planData.orden
                    bg        = $bg
                    cat       = $categoria
                    name      = $nombre
                    barrio    = $barrio
                    tags      = @($categoria)
                    rating    = 4.5
                    horario   = $horario
                    precio    = Get-PrecioForPlan $planDetectado
                    desc      = $desc
                    img       = ""
                    telefono  = $telefono
                    instagram = $instagram
                    menu      = @()
                    coords    = @(10.4240, -75.5510)
                }
                Add-PlaceToHtml $newPlace
            } else {
                Update-PlaceInHtml $nombre @{ orden = $planData.orden; precio = Get-PrecioForPlan $planDetectado }
            }

            Write-Output "  Local '$nombre' actualizado a plan $planDetectado"
        } else {
            Write-Output "  NUEVO LOCAL - Mes gratuito"
            $planData = Get-PlanDataForPlace $planDetectado

            Save-Local @{
                NIT        = $nitDetectado
                Nombre     = $nombre
                Categoria  = $categoria.Substring(0,1).ToUpper() + $categoria.Substring(1)
                Barrio     = $barrio
                Ciudad     = $global:CIUDAD_ACTUAL.slug
                Plan       = $planDetectado
                Precio     = $CONFIG.PLANES[$planDetectado]
                FechaReg   = $hoy
                FechaIni   = $hoy
                FechaVen   = $fechaVen
                Estado     = "Activo"
                MetodoPago = "Nequi"
                Comprobante = ""
                Notas      = "Mes gratuito - Nuevo - $hoy"
            }

            $htmlPlaces = Get-PlacesFromHtml
            $usedBgs = $htmlPlaces | Where-Object { $_.cat -eq $categoria } | ForEach-Object { $_.bg }
            $bg = Get-BgClass $categoria $usedBgs

            $newPlace = @{
                id        = (Get-NextPlaceId)
                orden     = $planData.orden
                bg        = $bg
                cat       = $categoria
                name      = $nombre
                nit       = $nitDetectado
                barrio    = $barrio
                tags      = @($categoria)
                rating    = 4.5
                horario   = $horario
                precio    = Get-PrecioForPlan $planDetectado
                desc      = $desc
                img       = ""
                telefono  = $telefono
                instagram = $instagram
                menu      = @()
                coords    = @(10.4240, -75.5510)
            }
            Add-PlaceToHtml $newPlace
            Write-Output "  Nuevo local '$nombre' agregado con plan $planDetectado (mes gratuito)"
        }

        # Registrar pago si no es gratuito
        $precio = $CONFIG.PLANES[$planDetectado]
        if ($local -and $local.Estado -eq "Activo" -and $local.Plan -eq $planDetectado) {
            # Mismo plan y ya activo - probablemente renovacion pagada
            Register-Payment $hoy $nombre $planDetectado $precio "Nequi" "SI"
        } elseif (!$local) {
            # Nuevo - gratis solo si Presencia Basica
            if ($planDetectado -ne "Presencia Basica") {
                Register-Payment $hoy $nombre $planDetectado $precio "Pendiente" "Pendiente"
                Write-Output "  Pago pendiente registrado para $nombre ($planDetectado - ${precio})"
            } else {
                Write-Output "  Primer mes gratuito para $nombre"
            }
        }

        # Buscar imagen local y subir a ImgBB
        $ciudadNombre = $global:CIUDAD_ACTUAL.nombre
        $imgUrl = Auto-ProcessImageForPlace $nombre $categoria $ciudadNombre
        if ($imgUrl) {
            Update-PlaceInHtml $nombre @{ img = $imgUrl }
            Write-Output "  Imagen agregada al HTML"
        }

        # Actualizar venues.json
        . "$PSScriptRoot\scripts\update-venues-json.ps1"
        Update-VenuesJson -Nombre $nombre -Nit $nitDetectado -Ciudad $global:CIUDAD_ACTUAL.slug -Telefono $telefono -Activo $true

        Commit-And-Push "$intencion : $nombre - $planDetectado - $hoy" 2>&1 | Out-Null
        Write-Output "`nLISTO. Todo procesado y subido a GitHub."
    }
}

# ═══════════════════════════════════════
# SELECTOR DE CIUDAD
# ═══════════════════════════════════════

function Select-CiudadInicial {
    while ($true) {
        Clear-Host
        Write-Output "============================================"
        Write-Output "  CARTAGENA LOCAL - AUTOMATOR v3.0"
        Write-Output "  (Pega el mensaje y todo se hace solo)"
        Write-Output "============================================"
        Write-Output ""
        Write-Output "SELECCIONA LA CIUDAD (solo la primera vez):"
        Write-Output ""
        $lista = @($CONFIG.CIUDADES.Keys | Sort-Object)
        for ($i = 0; $i -lt $lista.Count; $i++) {
            $info = $CONFIG.CIUDADES[$lista[$i]]
            Write-Output "$($i+1). $($info.nombre)"
        }
        Write-Output "0. Salir"
        Write-Output ""
        $opt = Read-Host "Numero o nombre de la ciudad"
        if ($opt -eq "0") { return $null }
        if ([string]::IsNullOrWhiteSpace($opt)) { continue }

        # Numerico
        try {
            $idx = [int]$opt - 1
            if ($idx -ge 0 -and $idx -lt $lista.Count) {
                $slug = $lista[$idx]
                $cfg = Get-CiudadConfig $slug
                if ($cfg) { return $cfg }
            }
        } catch {}

        # Nombre
        foreach ($s in $lista) {
            $info = $CONFIG.CIUDADES[$s]
            if ($info.nombre -like "*$opt*") {
                $cfg = Get-CiudadConfig $s
                if ($cfg) { return $cfg }
            }
        }

        Write-Output "Invalido. Intenta de nuevo."
        Write-Output "Presiona Enter..."
        $null = Read-Host
    }
}

# ═══════════════════════════════════════
# MAIN
# ═══════════════════════════════════════

# 1. Seleccionar ciudad
$cfg = Select-CiudadInicial
if (!$cfg) { Write-Output "Hasta luego!"; exit }
$global:CIUDAD_ACTUAL = $cfg
$CONFIG.HTML_PATH = $cfg.htmlPath
$CONFIG.BACKUP_DIR = $cfg.backupDir
$CONFIG.GIT_REPO_DIR = $cfg.gitDir
$CONFIG.EXCEL_PATH = $cfg.excelPath

Clear-Host
Write-Output "============================================"
Write-Output "  $(Get-NombreCiudad $cfg.slug) - AUTOMATOR v3.0"
Write-Output "============================================"
Write-Output ""

# 2. Auto-configurar git desde Cuentas_GitHub.xlsx
Write-Output "Configurando git..."
$gitCuenta = Get-EmailForCiudad $cfg.slug
if ($gitCuenta) {
    $repoDir = $cfg.gitDir
    Set-Location $repoDir
    if (!(Test-Path "$repoDir\.git")) { git init 2>&1 | Out-Null }
    git config user.email $gitCuenta.correo 2>&1 | Out-Null
    git config user.name $gitCuenta.usuario 2>&1 | Out-Null
    git remote remove origin 2>$null
    git remote add origin $gitCuenta.repoUrl 2>&1 | Out-Null
    git branch -M main 2>&1 | Out-Null
    Write-Output "  Git configurado: $($gitCuenta.usuario) -> $($gitCuenta.repoUrl)"
} else {
    Write-Output "  AVISO: No se encontraron credenciales GitHub en Cuentas_GitHub.xlsx"
    Write-Output "  El push automatico no funcionara hasta configurar manualmente."
}

# 3. Auto-verificar vencimientos
Auto-CheckExpirados

# 3. Loop principal: pegar mensajes
while ($true) {
    Write-Output ""
    Write-Output "════════════════════════════════════════════"
    Write-Output "  CIUDAD: $(Get-NombreCiudad $cfg.slug)"
    Write-Output "  PEGA EL MENSAJE DE WHATSAPP Y PRESIONA ENTER"
    Write-Output "  (Escribe 0 y Enter para salir)"
    Write-Output "════════════════════════════════════════════"
    Write-Output ""

    # Multi-linea: leer hasta linea vacia
    $lineas = @()
    while ($true) {
        $linea = Read-Host
        if ($linea -eq "" -and $lineas.Count -gt 0) { break }
        if ($linea -eq "0" -and $lineas.Count -eq 0) { Write-Output "Hasta luego!"; exit }
        $lineas += $linea
    }

    $msgCompleto = $lineas -join "`n"

    if ([string]::IsNullOrWhiteSpace($msgCompleto)) { continue }

    Auto-ProcesarMensaje $msgCompleto

    Write-Output ""
    Write-Output "Presiona Enter para pegar otro mensaje..."
    $null = Read-Host
}
