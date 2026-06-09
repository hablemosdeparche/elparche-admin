param([switch]$ReportOnly)

$BASE   = "C:\Users\DIEGO\Desktop\moweb"
$DB_PATH = Join-Path $BASE "billing-db.json"
$LOG    = Join-Path (Join-Path $BASE "elparche-agent") "elparche-core.log"

function Log($m) {
    $l = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $m"
    Write-Output $l
    Add-Content $LOG $l -Encoding UTF8
}

function Normalize-Name($s) {
    $norm = $s.ToLower().Trim()
    for ($i = 0xE0; $i -le 0xE5; $i++) { $norm = $norm.Replace([char]$i, 'a') }
    for ($i = 0xE8; $i -le 0xEB; $i++) { $norm = $norm.Replace([char]$i, 'e') }
    for ($i = 0xEC; $i -le 0xEF; $i++) { $norm = $norm.Replace([char]$i, 'i') }
    for ($i = 0xF2; $i -le 0xF6; $i++) { $norm = $norm.Replace([char]$i, 'o') }
    for ($i = 0xF9; $i -le 0xFC; $i++) { $norm = $norm.Replace([char]$i, 'u') }
    $norm = $norm.Replace([char]0xF1, 'n')
    $result = ""
    foreach ($c in $norm.ToCharArray()) {
        if (($c -ge 'a' -and $c -le 'z') -or ($c -ge '0' -and $c -le '9') -or $c -eq ' ') { $result += $c }
    }
    return $result
}

Log "=== EL PARCHE BILLING CYCLE ==="

if (!(Test-Path $DB_PATH)) { Log "ERROR: billing-db.json not found"; exit 1 }

# Pull latest changes first to avoid conflicts
try {
    & git -C $BASE config user.name "El Parche Bot"
    & git -C $BASE config user.email "bot@elparche.co" 2>$null
    & git -C $BASE pull --rebase origin main 2>&1 | Out-Null
    Log "Git pull OK"
} catch { Log "Git pull skipped: $_" }

$jsonBytes = [System.IO.File]::ReadAllBytes($DB_PATH)
$jsonRaw = [System.Text.Encoding]::UTF8.GetString($jsonBytes).TrimStart([char]0xFEFF)
$db = $jsonRaw | ConvertFrom-Json
$hoy = Get-Date
$hoyStr = Get-Date -Format "dd/MM/yyyy"
$vencidos = 0
$errores = 0
$modifiedHtml = $false

foreach ($v in $db.venues) {
    if ($v.activo -ne $true -or $v.Estado -eq "Vencido") { continue }

    $expirado = $false
    $razon = ""

    # Check 1: MP subscription cancelled by user or past due
    if ($v.mp_status -in @("cancelled", "rejected", "past_due")) {
        $expirado = $true
        $razon = "MP: $($v.mp_status)"
    }
    # Check 2: Date-based expiration (legacy)
    elseif ($v.FechaVen) {
        $fv = try { Get-Date $v.FechaVen -ErrorAction Stop } catch { $null }
        if ($fv -and $fv -le $hoy) {
            $expirado = $true
            $razon = "Fecha vencimiento: $($v.FechaVen)"
        }
    }
    # Check 3: No FechaVen and no MP subscription = active (skip)
    else { continue }

    if (!$expirado) { continue }

    $nombre  = $v.Nombre
    $ciudad  = $v.Ciudad
    $html    = Join-Path (Join-Path $BASE $ciudad) "index.html"
    $normBusqueda = Normalize-Name $nombre
    Log "EXPIRADO: $nombre en $ciudad ($razon)"

    if (!$ReportOnly -and (Test-Path $html)) {
        try {
            $rawBytes = [System.IO.File]::ReadAllBytes($html)
            $content = [System.Text.Encoding]::UTF8.GetString($rawBytes)
            if ($content.Contains([char]0xFFFD)) {
                $content = [System.Text.Encoding]::GetEncoding(1252).GetString($rawBytes)
            }
            $prefix = "name:'"
            $pos = 0
            $found = $false
            while ($true) {
                $startName = $content.IndexOf($prefix, $pos)
                if ($startName -lt 0) { break }
                $startName += $prefix.Length
                $endName = $content.IndexOf("'", $startName)
                if ($endName -lt 0) { break }
                $htmlName = $content.Substring($startName, $endName - $startName)
                if ((Normalize-Name $htmlName) -eq $normBusqueda) {
                    $objStart = $content.LastIndexOf('{', $startName)
                    $objEnd = $content.IndexOf('}', $endName) + 1
                    if ($objStart -ge 0 -and $objEnd -gt $objStart) {
                        $oldObj = $content.Substring($objStart, $objEnd - $objStart)
                        $newObj = $oldObj -replace "orden:\d+", "orden:99999"
                        $content = $content.Replace($oldObj, $newObj)
                        $bytes = [System.Text.Encoding]::UTF8.GetBytes($content)
                        [System.IO.File]::WriteAllBytes($html, $bytes)
                        $modifiedHtml = $true
                        Log "  -> Ocultado en $ciudad/index.html"
                        $found = $true
                    }
                    break
                }
                $pos = $endName + 1
            }
            if (!$found) { Log "  -> WARN: '$nombre' no encontrado en $html" }
        } catch { Log "  -> ERROR: $_"; $errores++ }
    }

    $v.Estado = "Vencido"
    $v.activo = $false
    $v.Notas = "Vencido automaticamente - $razon - $hoyStr"
    $v.updatedAt = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    $vencidos++
}

if ($vencidos -gt 0 -and !$ReportOnly) {
    $jsonOut = $db | ConvertTo-Json -Depth 10
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($jsonOut)
        [System.IO.File]::WriteAllBytes($DB_PATH, $bytes)
        Log "billing-db.json actualizado: $vencidos vencido(s)"
    } catch { Log "ERROR al guardar billing-db.json: $_" }
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
    Log "$($kv.Name.PadRight(20)) $($r.activos) activos / $($r.total) totales$flag"
}

if (!$ReportOnly -and ($vencidos -gt 0 -or $modifiedHtml)) {
    try {
        & git -C $BASE add -A 2>&1 | Out-Null
        & git -C $BASE commit -m "Billing cycle: $vencidos expirados - $hoyStr" 2>&1 | Out-Null
        & git -C $BASE push origin main 2>&1 | Out-Null
        Log "Git push OK"
    } catch { Log "Git error: $_" }
}

Log "=== CYCLE END: $vencidos expirados, $errores errores ==="

@{ date = $hoyStr; expired = $vencidos; errors = $errores; cities = $reporte } | ConvertTo-Json -Compress | Write-Output
