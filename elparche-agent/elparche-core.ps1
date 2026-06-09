param([switch]$ReportOnly)

$BASE   = "C:\Users\DIEGO\Desktop\moweb"
$DB     = Join-Path $BASE "billing-db.json"
$LOG    = Join-Path (Join-Path $BASE "elparche-agent") "elparche-core.log"
$ADMIN  = Join-Path $BASE ".github"

function Log($m) {
    $l = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $m"
    Write-Output $l
    Add-Content $LOG "$l" -Encoding UTF8
}

Log "=== EL PARCHE BILLING CYCLE ==="

if (!(Test-Path $DB)) { Log "ERROR: billing-db.json not found"; exit 1 }

$db = Get-Content $DB -Raw | ConvertFrom-Json
$hoy = Get-Date
$hoyStr = Get-Date -Format "dd/MM/yyyy"
$vencidos = 0
$errores = 0

foreach ($v in $db.venues) {
    if ($v.activo -ne $true -or $v.Estado -eq "Vencido") { continue }
    if ([string]::IsNullOrWhiteSpace($v.FechaVen)) { continue }

    $fv = try { Get-Date $v.FechaVen -ErrorAction Stop } catch { $null }
    if (!$fv -or $fv -gt $hoy) { continue }

    $nombre  = $v.Nombre
    $ciudad  = $v.Ciudad
    $html    = Join-Path (Join-Path $BASE $ciudad) "index.html"
    Log "EXPIRADO: $nombre en $ciudad (vencia $($v.FechaVen))"

    if (!$ReportOnly -and (Test-Path $html)) {
        try {
            $content = Get-Content $html -Raw
            $esc = [regex]::Escape($nombre)
            $match = [regex]::Match($content, "\{[^}]*name\s*:\s*'$esc'[^}]*\}")
            if ($match.Success) {
                $old = $match.Value
                $new = $old -replace "orden:\d+", "orden:99999"
                $content = $content.Replace($old, $new)
                [System.IO.File]::WriteAllText($html, $content, [System.Text.Encoding]::UTF8)
                Log "  -> Ocultado en $ciudad/index.html (orden=99999)"
            } else {
                Log "  -> WARN: '$nombre' no encontrado en $html"
            }
        } catch { Log "  -> ERROR: $_"; $errores++ }
    }

    $v.Estado = "Vencido"
    $v.activo = $false
    $v.Notas = "Vencido automaticamente - $hoyStr"
    $v.updatedAt = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    $vencidos++
}

if ($vencidos -gt 0) {
    if (!$ReportOnly) {
        $db | ConvertTo-Json -Depth 10 | Set-Content $DB -Encoding UTF8
        Log "billing-db.json actualizado: $vencidos vencido(s)"
    }
}

$reporte = @{}
$ciudades = $db.venues | Group-Object Ciudad
foreach ($g in $ciudades) {
    $act = @($g.Group | Where-Object { $_.activo -eq $true })
    $reporte[$g.Name] = @{ activos = $act.Count; total = $g.Count; necesitaRotacion = $act.Count -lt 35 }
}

Log "--- RESUMEN POR CIUDAD ---"
foreach ($kv in $reporte.GetEnumerator() | Sort-Object Name) {
    $r = $kv.Value
    $flag = if ($r.necesitaRotacion) { " < 35 -- necesita rotacion" } else { "" }
    Log "${($kv.Name).PadRight(20)} $($r.activos) activos / $($r.total) totales$flag"
}

if (!$ReportOnly -and ($vencidos -gt 0 -or $errores -gt 0)) {
    try {
        Push-Location $BASE
        git config user.name "El Parche Bot"
        git config user.email "bot@elparche.co" 2>$null
        git add -A 2>&1 | Out-Null
        git commit -m "Billing cycle: $vencidos expirados - $hoyStr" 2>&1 | Out-Null
        git pull --rebase origin main 2>&1 | Out-Null
        git push origin main 2>&1 | Out-Null
        Log "Git push OK"
        Pop-Location
    } catch { Log "Git error: $_" }
}

Log "=== CYCLE END: $vencidos expirados, $errores errores ==="

# Output structured summary for the tray app to read
@{ date = $hoyStr; expired = $vencidos; errors = $errores; cities = $reporte } | ConvertTo-Json -Compress | Write-Output
