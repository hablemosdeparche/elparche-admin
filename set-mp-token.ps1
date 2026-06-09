$repo = "hablemosdeparche/elparche-admin"

$token = Read-Host "Pegá tu MP_ACCESS_TOKEN de Mercado Pago"
if ([string]::IsNullOrWhiteSpace($token)) {
    Write-Output "No ingresaste ningún token. Saliendo."
    exit 1
}

gh secret set MP_ACCESS_TOKEN --repo $repo --body $token
if ($LASTEXITCODE -eq 0) {
    Write-Output "MP_ACCESS_TOKEN configurado correctamente en $repo"
} else {
    Write-Output "ERROR: no se pudo configurar. ¿Tenés gh CLI instalado y autenticado?"
    pause
    exit 1
}

Remove-Item -LiteralPath $PSCommandPath -Force
