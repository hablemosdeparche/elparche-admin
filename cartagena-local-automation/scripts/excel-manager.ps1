# ═══════════════════════════════════════
# EXCEL MANAGER - Cartagena Local
# ═══════════════════════════════════════
# Funciones para leer y escribir en el Excel

if (!$CONFIG) { . "$PSScriptRoot\..\config.ps1" }

function Open-Excel {
    $excel = New-Object -ComObject Excel.Application
    $excel.Visible = $false
    $excel.DisplayAlerts = $false
    $wb = $excel.Workbooks.Open($CONFIG.EXCEL_PATH)
    return @{Excel=$excel; WB=$wb}
}

function Close-Excel($session) {
    $session.WB.Save()
    $session.WB.Close()
    $session.Excel.Quit()
    [Runtime.InteropServices.Marshal]::ReleaseComObject($session.Excel) | Out-Null
    [GC]::Collect()
}

function Get-LocalFromExcel($nombre) {
    $s = Open-Excel
    $ws = $s.WB.Worksheets("Registro")
    $rows = $ws.UsedRange.Rows.Count
    $result = $null
    for ($r = 2; $r -le $rows; $r++) {
        $name = $ws.Cells($r, 3).Text
        if ($name.Trim().ToLower() -eq $nombre.Trim().ToLower()) {
            $result = @{
                ID         = $ws.Cells($r, 1).Text
                NIT        = $ws.Cells($r, 2).Text
                Nombre     = $name
                Categoria  = $ws.Cells($r, 4).Text
                Barrio     = $ws.Cells($r, 5).Text
                Plan       = $ws.Cells($r, 6).Text
                Precio     = $ws.Cells($r, 7).Text
                FechaReg   = $ws.Cells($r, 8).Text
                FechaIni   = $ws.Cells($r, 9).Text
                FechaVen   = $ws.Cells($r, 10).Text
                Estado     = $ws.Cells($r, 11).Text
                MetodoPago = $ws.Cells($r, 12).Text
                Comprobante = $ws.Cells($r, 13).Text
                Notas      = $ws.Cells($r, 14).Text
                Fila       = $r
            }
            break
        }
    }
    Close-Excel $s
    return $result
}

function Get-AllLocalesFromExcel {
    $s = Open-Excel
    $ws = $s.WB.Worksheets("Registro")
    $rows = $ws.UsedRange.Rows.Count
    $result = @()
    for ($r = 2; $r -le $rows; $r++) {
        $name = $ws.Cells($r, 3).Text
        if ([string]::IsNullOrWhiteSpace($name)) { continue }
        $result += @{
            ID         = $ws.Cells($r, 1).Value
            NIT        = $ws.Cells($r, 2).Text
            Nombre     = $name
            Categoria  = $ws.Cells($r, 4).Text
            Barrio     = $ws.Cells($r, 5).Text
            Plan       = $ws.Cells($r, 6).Text
            Precio     = $ws.Cells($r, 7).Value
            FechaVen   = $ws.Cells($r, 10).Text
            Estado     = $ws.Cells($r, 11).Text
        }
    }
    Close-Excel $s
    return $result
}

function Get-NextID {
    $locales = Get-AllLocalesFromExcel
    if ($locales.Count -eq 0) { return 1 }
    $maxId = ($locales | ForEach-Object { $_.ID }) | Measure-Object -Maximum
    return $maxId.Maximum + 1
}

function Write-LocalToExcel {
    param($datos)  # Hashtable con keys: NIT, Nombre, Categoria, Barrio, Plan, Precio, FechaReg, FechaIni, FechaVen, Estado, MetodoPago, Comprobante, Notas

    $s = Open-Excel
    $ws = $s.WB.Worksheets("Registro")
    $rows = $ws.UsedRange.Rows.Count

    # Buscar si ya existe para editar
    $foundRow = $null
    for ($r = 2; $r -le $rows; $r++) {
        $name = $ws.Cells($r, 3).Text
        if ($name.Trim().ToLower() -eq $datos.Nombre.Trim().ToLower()) {
            $foundRow = $r
            break
        }
    }

    if ($foundRow) {
        $row = $foundRow
        Write-Output "EDITANDO local existente en fila $row"
    } else {
        $row = $rows + 1
        $ws.Cells($row, 1).Value = (Get-NextID)
        Write-Output "AGREGANDO nuevo local en fila $row"
    }

    $map = @{
        2  = "NIT"
        3  = "Nombre"
        4  = "Categoria"
        5  = "Barrio"
        6  = "Plan"
        7  = "Precio"
        8  = "FechaReg"
        9  = "FechaIni"
        10 = "FechaVen"
        11 = "Estado"
        12 = "MetodoPago"
        13 = "Comprobante"
        14 = "Notas"
    }

    foreach ($col in $map.Keys) {
        $key = $map[$col]
        if ($datos.ContainsKey($key)) {
            $ws.Cells($row, $col).Value = $datos[$key]
        }
    }

    Close-Excel $s
    Write-Output "Local '$($datos.Nombre)' guardado en Excel."
}

function Register-PaymentInExcel {
    param($fecha, $local, $plan, $monto, $metodo, $comprobante)

    $s = Open-Excel
    $ws = $s.WB.Worksheets("Ingresos")
    $rows = $ws.UsedRange.Rows.Count
    $row = $rows + 1

    $ws.Cells($row, 1).Value = $fecha
    $ws.Cells($row, 2).Value = $local
    $ws.Cells($row, 3).Value = $plan
    $ws.Cells($row, 4).Value = $monto
    $ws.Cells($row, 5).Value = $metodo
    $ws.Cells($row, 6).Value = $comprobante

    Close-Excel $s
    Write-Output "Pago registrado en Ingresos: $local - $monto"
}
