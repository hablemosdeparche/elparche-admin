<#
.SYNOPSIS
  BILLING MANAGER - Cartagena Local
  Gestiona ciclos de facturacion mensual:
  - Verifica vencimientos
  - Oculta locales que no pagaron (NO los elimina)
  - Rota locales segun interes/actividad
  - Envia recordatorios via WhatsApp
#>

if (!$CONFIG) { . "$PSScriptRoot\..\config.ps1" }
. "$PSScriptRoot\data-manager.ps1"

function Get-HoyStr { return (Get-Date -Format "yyyy-MM-dd") }

function Parse-Date($str) {
    try {
        $parts = $str -split '/'
        if ($parts.Count -eq 3) { return Get-Date "$($parts[2])-$($parts[1])-$($parts[0])" }
        $parts = $str -split '-'
        if ($parts.Count -eq 3) { return Get-Date "$($parts[0])-$($parts[1])-$($parts[2])" }
    } catch {}
    return $null
}

function Load-BillingDB {
    return Load-DB
}

function Save-BillingDB {
    param($db)
    Save-DB $db
}

function Get-VenuesForCity {
    param([string]$CitySlug)
    return Get-AllLocales $CitySlug
}

function Get-Expirados {
    $db = Load-BillingDB
    $hoy = Get-Date
    return $db.venues | Where-Object {
        $_.activo -eq $true -and $_.Estado -ne "Vencido" -and $_.FechaVen -and $(try { (Get-Date $_.FechaVen) -lt $hoy } catch { $false })
    }
}

function Get-ProximosAVencer {
    $db = Load-BillingDB
    $hoy = Get-Date
    $en7Dias = $hoy.AddDays(7)
    return $db.venues | Where-Object {
        $_.activo -eq $true -and $_.FechaVen -and $(try { $d = Get-Date $_.FechaVen; $d -gt $hoy -and $d -le $en7Dias } catch { $false })
    }
}

function Get-Inactivos {
    $db = Load-BillingDB
    $seisMeses = (Get-Date).AddMonths(-6)
    return $db.venues | Where-Object {
        $_.activo -eq $true -and $_.Estado -eq "Activo" -and $_.updatedAt -and $(try { (Get-Date $_.updatedAt) -lt $seisMeses } catch { $false })
    }
}

function Ocultar-VenueInHtml {
    param([string]$CitySlug, [string]$VenueName)

    . "$PSScriptRoot\html-manager.ps1"
    $cfg = Get-CiudadConfig $CitySlug
    if (!$cfg) { return $false }

    $CONFIG.HTML_PATH = $cfg.htmlPath
    $CONFIG.BACKUP_DIR = $cfg.backupDir
    $CONFIG.GIT_REPO_DIR = $cfg.gitDir

    Backup-Html
    # Ocultar: poner orden muy alto para que aparezca al final
    Update-PlaceInHtml $VenueName @{ orden = 99999 }
    Write-Output "Ocultado: $VenueName en $CitySlug"

    . "$PSScriptRoot\github-manager.ps1"
    Commit-And-Push "Ocultado (vencido): $VenueName - $(Get-Date -Format 'dd/MM/yyyy')"
    return $true
}

function Restaurar-VenueInHtml {
    param([string]$CitySlug, [string]$VenueName, [string]$Plan)

    . "$PSScriptRoot\html-manager.ps1"
    $cfg = Get-CiudadConfig $CitySlug
    if (!$cfg) { return $false }

    $CONFIG.HTML_PATH = $cfg.htmlPath
    $CONFIG.BACKUP_DIR = $cfg.backupDir
    $CONFIG.GIT_REPO_DIR = $cfg.gitDir

    Backup-Html
    $orden = Get-PlanOrden $Plan
    $precio = $CONFIG.PLAN_PRECIO_TAG[$Plan]
    Update-PlaceInHtml $VenueName @{ orden = $orden; precio = $precio }
    Write-Output "Restaurado: $VenueName en $CitySlug (Plan $Plan)"

    . "$PSScriptRoot\github-manager.ps1"
    Commit-And-Push "Restaurado (pago): $VenueName - $Plan - $(Get-Date -Format 'dd/MM/yyyy')"
    return $true
}

<#
.SYNOPSIS
  Ciclo mensual de facturacion: oculta vencidos, notifica proximos
#>
function Invoke-MonthlyBillingCycle {
    Write-Output "══════════════════════════════════════════"
    Write-Output "  CICLO DE FACTURACION MENSUAL"
    Write-Output "  $(Get-Date -Format 'dd/MM/yyyy HH:mm')"
    Write-Output "══════════════════════════════════════════"

    # 1. Procesar vencidos -> ocultar
    Write-Output "`n--- VERIFICANDO VENCIDOS ---"
    $expirados = Get-Expirados
    foreach ($ven in $expirados) {
        Write-Output "VENCIDO: $($ven.Nombre) en $($ven.Ciudad) - Vence: $($ven.FechaVen)"
        Ocultar-VenueInHtml -CitySlug $ven.Ciudad -VenueName $ven.Nombre

        # Actualizar billing db
        $db = Load-BillingDB
        for ($i = 0; $i -lt $db.venues.Count; $i++) {
            if ($db.venues[$i].Ciudad -eq $ven.Ciudad -and $db.venues[$i].Nombre -eq $ven.Nombre) {
                $db.venues[$i].Estado = "Vencido"
                $db.venues[$i].activo = $false
                $db.venues[$i].Notas = "Ocultado automaticamente - $(Get-HoyStr)"
                $db.venues[$i].updatedAt = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
                break
            }
        }
        Save-BillingDB $db
    }

    # 2. Notificar proximos a vencer
    Write-Output "`n--- PROXIMOS A VENCER (7 dias) ---"
    $proximos = Get-ProximosAVencer
    foreach ($prox in $proximos) {
        Write-Output "RECORDATORIO: $($prox.Nombre) en $($prox.Ciudad) - Vence: $($prox.FechaVen)"
        # Aqui se podria enviar un mensaje de WhatsApp automaticamente
    }

    # 3. Rotar inactivos (6+ meses sin actividad)
    Write-Output "`n--- ROTANDO INACTIVOS ---"
    $inactivos = Get-Inactivos
    $rotados = 0
    foreach ($inac in $inactivos) {
        Write-Output "INACTIVO: $($inac.Nombre) en $($inac.Ciudad) - Ultima actualizacion: $($inac.updatedAt)"
        Ocultar-VenueInHtml -CitySlug $inac.Ciudad -VenueName $inac.Nombre

        $db = Load-BillingDB
        for ($i = 0; $i -lt $db.venues.Count; $i++) {
            if ($db.venues[$i].Ciudad -eq $inac.Ciudad -and $db.venues[$i].Nombre -eq $inac.Nombre) {
                $db.venues[$i].Estado = "Rotado"
                $db.venues[$i].activo = $false
                $db.venues[$i].Notas = "Rotado por inactividad - $(Get-HoyStr)"
                $db.venues[$i].updatedAt = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
                break
            }
        }
        Save-BillingDB $db
        $rotados++
    }

    Write-Output "`n--- RESUMEN ---"
    Write-Output "Vencidos ocultados: $($expirados.Count)"
    Write-Output "Proximos a vencer: $($proximos.Count)"
    Write-Output "Inactivos rotados: $rotados"
    Write-Output "`nCiclo de facturacion completado."
}

<#
.SYNOPSIS
  Renueva un local (marca como pagado y restaura en HTML)
#>
function Invoke-RenewVenue {
    param(
        [string]$CitySlug,
        [string]$VenueName,
        [string]$Plan,
        [string]$MetodoPago = "Nequi"
    )

    $meses = 1
    $nuevaVence = (Get-Date).AddMonths($meses).ToString("yyyy-MM-dd")
    $precio = Get-PlanPrice $Plan

    Write-Output "Renovando: $VenueName en $CitySlug"
    Write-Output "Plan: $Plan | Pago: $precio | Vence: $nuevaVence"

    Restaurar-VenueInHtml -CitySlug $CitySlug -VenueName $VenueName -Plan $Plan

    $db = Load-BillingDB
    for ($i = 0; $i -lt $db.venues.Count; $i++) {
        if ($db.venues[$i].Ciudad -eq $CitySlug -and $db.venues[$i].Nombre -eq $VenueName) {
            $db.venues[$i].Plan = $Plan
            $db.venues[$i].FechaVen = $nuevaVence
            $db.venues[$i].activo = $true
            $db.venues[$i].Estado = "Activo"
            $db.venues[$i].Notas = "Renovado - $MetodoPago - $(Get-HoyStr)"
            $db.venues[$i].updatedAt = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            break
        }
    }
    Save-BillingDB $db

    Write-Output "Renovacion completada para $VenueName"
}

<#
.SYNOPSIS
  Verifica cuantas ciudades tienen 35+ venues activos
#>
function Get-CitiesReadyForLaunch {
    $ready = @()
    $db = Load-BillingDB

    foreach ($slug in (Get-AllCities)) {
        $activos = $db.venues | Where-Object { $_.Ciudad -eq $slug -and $_.activo -eq $true }
        $count = @($activos).Count
        if ($count -ge $CONFIG.MIN_VENUES_PER_CITY) {
            $ready += @{ slug = $slug; count = $count }
        }
    }
    return $ready
}

<#
.SYNOPSIS
  Muestra estado completo de facturacion
#>
function Show-BillingStatus {
    $db = Load-BillingDB
    Write-Output "`n══════════════════════════════════════════"
    Write-Output "  ESTADO DE FACTURACION"
    Write-Output "══════════════════════════════════════════"

    $total = $db.venues.Count
    $activos = @($db.venues | Where-Object { $_.activo -eq $true }).Count
    $vencidos = @($db.venues | Where-Object { $_.estado -eq "Vencido" }).Count
    $rotados = @($db.venues | Where-Object { $_.estado -eq "Rotado" }).Count
    $proxVencer = @(Get-ProximosAVencer).Count

    Write-Output "Total registrados: $total"
    Write-Output "Activos: $activos"
    Write-Output "Vencidos: $vencidos"
    Write-Output "Rotados: $rotados"
    Write-Output "Proximos a vencer (7d): $proxVencer"

    Write-Output "`n--- POR CIUDAD ---"
    foreach ($slug in (Get-AllCities)) {
        $count = @($db.venues | Where-Object { $_.Ciudad -eq $slug -and $_.activo -eq $true }).Count
        $bar = ""
        if ($count -ge $CONFIG.MIN_VENUES_PER_CITY) { $bar = " ✅ LISTA" }
        Write-Output "$slug : $count activos$bar"
    }
}
