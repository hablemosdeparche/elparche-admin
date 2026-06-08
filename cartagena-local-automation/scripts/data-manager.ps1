if (!$CONFIG) { . "$PSScriptRoot\..\config.ps1" }

function Get-DBPath {
    return $CONFIG.BILLING_DB
}

function Load-DB {
    $dbPath = Get-DBPath
    if (!(Test-Path $dbPath)) {
        $base = @{ venues = @(); payments = @() }
        $base | ConvertTo-Json -Depth 10 | Set-Content $dbPath -Encoding UTF8
        return $base
    }
    try {
        $raw = Get-Content $dbPath -Raw
        $db = $raw | ConvertFrom-Json
        if (!$db.payments) { $db.payments = @() }
        return $db
    } catch {
        return @{ venues = @(); payments = @() }
    }
}

function Save-DB {
    param($db)
    $dbPath = Get-DBPath
    $db | ConvertTo-Json -Depth 10 | Set-Content $dbPath -Encoding UTF8
}

function Get-LocalByName {
    param([string]$nombre, [string]$ciudadSlug = "")
    $db = Load-DB
    $result = $db.venues | Where-Object {
        $match = $_.nombre.Trim().ToLower() -eq $nombre.Trim().ToLower()
        if ($ciudadSlug) { $match = $match -and $_.ciudad -eq $ciudadSlug }
        $match
    } | Select-Object -First 1
    return $result
}

function Get-LocalByNit {
    param([string]$nit, [string]$ciudadSlug = "")
    $db = Load-DB
    $result = $db.venues | Where-Object {
        $match = $_.nit -eq $nit
        if ($ciudadSlug) { $match = $match -and $_.ciudad -eq $ciudadSlug }
        $match
    } | Select-Object -First 1
    return $result
}

function Get-AllLocales {
    param([string]$ciudadSlug = "")
    $db = Load-DB
    if ($ciudadSlug) {
        return $db.venues | Where-Object { $_.ciudad -eq $ciudadSlug }
    }
    return $db.venues
}

function Get-NextVenueId {
    $venues = Get-AllLocales
    if ($venues.Count -eq 0) { return 1 }
    $maxId = ($venues | ForEach-Object { $_.id }) | Measure-Object -Maximum
    return $maxId.Maximum + 1
}

function Save-Local {
    param($datos)
    $db = Load-DB()

    $existing = $null
    for ($i = 0; $i -lt $db.venues.Count; $i++) {
        $v = $db.venues[$i]
        if ($v.nombre.Trim().ToLower() -eq $datos.Nombre.Trim().ToLower() -and $v.ciudad -eq $datos.Ciudad) {
            $existing = $i
            break
        }
    }

    $record = [PSCustomObject]@{
        ID          = if ($existing -ne $null) { $db.venues[$existing].ID } else { (Get-NextVenueId) }
        NIT         = if ($datos.ContainsKey("NIT")) { $datos.NIT } else { "" }
        Nombre      = $datos.Nombre
        Categoria   = if ($datos.ContainsKey("Categoria")) { $datos.Categoria } else { "" }
        Barrio      = if ($datos.ContainsKey("Barrio")) { $datos.Barrio } else { "" }
        Plan        = if ($datos.ContainsKey("Plan")) { $datos.Plan } else { "Presencia Basica" }
        Precio      = if ($datos.ContainsKey("Precio")) { $datos.Precio } else { 0 }
        FechaReg    = if ($datos.ContainsKey("FechaReg")) { $datos.FechaReg } else { "" }
        FechaIni    = if ($datos.ContainsKey("FechaIni")) { $datos.FechaIni } else { "" }
        FechaVen    = if ($datos.ContainsKey("FechaVen")) { $datos.FechaVen } else { "" }
        Estado      = if ($datos.ContainsKey("Estado")) { $datos.Estado } else { "Activo" }
        MetodoPago  = if ($datos.ContainsKey("MetodoPago")) { $datos.MetodoPago } else { "" }
        Comprobante = if ($datos.ContainsKey("Comprobante")) { $datos.Comprobante } else { "" }
        Notas       = if ($datos.ContainsKey("Notas")) { $datos.Notas } else { "" }
        Ciudad      = if ($datos.ContainsKey("Ciudad")) { $datos.Ciudad } else { $global:CIUDAD_ACTUAL.slug }
        activo      = $true
        updatedAt   = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    if ($existing -ne $null) {
        $db.venues[$existing] = $record
        Write-Output "EDITANDO venue existente: $($datos.Nombre)"
    } else {
        $db.venues += $record
        Write-Output "AGREGANDO nuevo venue: $($datos.Nombre)"
    }

    Save-DB $db
    return $record
}

function Register-Payment {
    param($fecha, $local, $plan, $monto, $metodo, $comprobante, $ciudad = "")

    $db = Load-DB()
    $payment = @{
        fecha       = $fecha
        local       = $local
        plan        = $plan
        monto       = $monto
        metodo      = $metodo
        comprobante = $comprobante
        ciudad      = if ($ciudad) { $ciudad } else { $global:CIUDAD_ACTUAL.slug }
        updatedAt   = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    $db.payments += $payment
    Save-DB $db
    Write-Output "Pago registrado: $local - $monto"
}

Export-ModuleMember -Function Get-LocalByName, Get-LocalByNit, Get-AllLocales, Get-NextVenueId, Save-Local, Register-Payment, Load-DB, Save-DB
