<#
.SYNOPSIS
  Crea repositorios en GitHub para cada ciudad que no tenga repo todavia
  y hace el primer push del index.html de cada ciudad.

  REQUISITO: Tener gh CLI instalado y autenticado (gh auth login)
  O usar tokens de Cuentas_GitHub.xlsx / github-accounts.json

  CORRE:
    powershell -ExecutionPolicy Bypass .\scripts\batch-create-repos.ps1
#>

if (!$CONFIG) { . "$PSScriptRoot\..\config.ps1" }

$accountsPath = $CONFIG.ACCOUNTS_JSON
if (!(Test-Path $accountsPath)) {
    Write-Error "No se encuentra github-accounts.json"
    exit 1
}

$accounts = Get-Content $accountsPath -Raw | ConvertFrom-Json
$baseDir = $CONFIG.BASE_DIR

Write-Output "============================================"
Write-Output "  CREACION DE REPOS GITHUB POR CIUDAD"
Write-Output "============================================"
Write-Output ""

foreach ($acc in $accounts) {
    $slug = $acc.ciudad
    $usuario = $acc.usuario
    $token = $acc.token
    $repoUrl = $acc.repoUrl

    Write-Output "`n--- $slug ---"

    # Verificar si el HTML existe
    $htmlPath = Join-Path $baseDir "$slug\index.html"
    if (!(Test-Path $htmlPath)) {
        Write-Output "  ⚠️  No hay index.html para $slug, se salta"
        continue
    }

    # Verificar si ya tiene git
    $gitDir = Join-Path $baseDir "$slug\.git"
    if (Test-Path $gitDir) {
        Write-Output "  ✅ Ya tiene .git en $slug"
        continue
    }

    if (!$usuario -or !$token) {
        Write-Output "  ⚠️  Sin credenciales GitHub para $slug"
        Write-Output "     Primero creá la cuenta en https://github.com/join"
        Write-Output "     y actualizá github-accounts.json con usuario y token"
        continue
    }

    # Extraer nombre del repo de la URL
    $repoName = if ($repoUrl -match 'github\.com/([^/]+)/([^/]+?)(?:\.git)?$') {
        "$($matches[1])/$($matches[2])"
    } else { "$usuario/$slug-local" }

    Write-Output "  Repo: $repoName"

    # Crear repo via GitHub API
    try {
        $apiUrl = "https://api.github.com/user/repos"
        $body = @{
            name = ($repoName -split '/')[1]
            description = "Guia turistica de $slug - El Parche"
            private = $false
            auto_init = $true
        } | ConvertTo-Json

        $headers = @{
            Authorization = "Bearer $token"
            "Content-Type" = "application/json"
        }

        $resp = Invoke-RestMethod -Uri $apiUrl -Method Post -Body $body -Headers $headers -ContentType "application/json"
        Write-Output "  ✅ Repo creado: $($resp.html_url)"
    } catch {
        $errMsg = $_.Exception.Message
        if ($errMsg -match "already exists") {
            Write-Output "  ℹ️  El repo ya existe en GitHub"
        } else {
            Write-Output "  ❌ Error creando repo: $errMsg"
            continue
        }
    }

    # Inicializar git local, hacer commit y push
    try {
        Push-Location (Join-Path $baseDir $slug)

        git init 2>&1 | Out-Null
        git config user.email $acc.correo
        git config user.name $usuario
        git remote add origin $repoUrl
        git branch -M main

        git add index.html 2>&1 | Out-Null
        git commit -m "Initial commit - $slug guide" 2>&1 | Out-Null

        # Usar token en URL para push
        $pushUrl = $repoUrl -replace 'https://', "https://$usuario`:$token@"
        git remote set-url origin $pushUrl
        git push -u origin main 2>&1 | Out-Null
        git remote set-url origin $repoUrl  # Limpiar token de remote

        Write-Output "  ✅ Push exitoso a $repoUrl"

        Pop-Location
    } catch {
        Write-Output "  ❌ Error en git: $_"
        Pop-Location
    }
}

Write-Output "`n============================================"
Write-Output "  PROCESO COMPLETADO"
Write-Output "============================================"
