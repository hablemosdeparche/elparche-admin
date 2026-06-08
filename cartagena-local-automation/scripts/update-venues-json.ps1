if (!$CONFIG) { . "$PSScriptRoot\..\config.ps1" }

function Update-VenuesJson {
    param(
        [string]$Nombre,
        [string]$Nit,
        [string]$Ciudad,
        [string]$Telefono = "",
        [bool]$Activo = $true
    )

    $jsonPath = Join-Path $CONFIG.BASE_DIR "venues.json"
    $venues = @()
    if (Test-Path $jsonPath) {
        $venues = Get-Content $jsonPath -Raw | ConvertFrom-Json
    }

    $existing = $venues | Where-Object { $_.nombre -eq $Nombre -and $_.ciudad -eq $Ciudad }
    if ($existing) {
        $existing.nit = $Nit
        $existing.activo = $Activo
        if ($Telefono) { $existing.telefono = $Telefono }
    } else {
        $venues += @{
            nombre = $Nombre
            nit = $Nit
            ciudad = $Ciudad
            telefono = $Telefono
            activo = $Activo
        }
    }

    $venues | ConvertTo-Json -Depth 3 | Set-Content $jsonPath -Encoding UTF8
    Write-Output "venues.json actualizado: $Nombre - NIT: $Nit - $Ciudad"
}

Export-ModuleMember -Function Update-VenuesJson
