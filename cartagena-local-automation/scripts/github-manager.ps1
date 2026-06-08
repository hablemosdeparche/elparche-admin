# ═══════════════════════════════════════
# GITHUB MANAGER - Cartagena Local
# ═══════════════════════════════════════
# Maneja git init, add, commit, push

if (!$CONFIG) { . "$PSScriptRoot\..\config.ps1" }

function Test-GitInstalled {
    $git = Get-Command git -ErrorAction SilentlyContinue
    if (!$git) {
        Write-Error "Git no está instalado. Descárgalo de: https://git-scm.com/download/win"
        return $false
    }
    return $true
}

function Get-GitRepoStatus {
    if (!(Test-Path "$($CONFIG.GIT_REPO_DIR)\.git")) {
        return "NO_INIT"
    }
    Set-Location $CONFIG.GIT_REPO_DIR
    $status = git status --porcelain
    $branch = git branch --show-current
    $remote = git remote -v
    if ([string]::IsNullOrWhiteSpace($remote)) {
        return "NO_REMOTE"
    }
    if ([string]::IsNullOrWhiteSpace($status)) {
        return "CLEAN"
    }
    return "DIRTY"
}

function Init-GitRepo {
    param($repoUrl)  # ej: https://github.com/tuusuario/cartagena-local.git

    if (!(Test-GitInstalled)) { return $false }

    $repoDir = $CONFIG.GIT_REPO_DIR
    if ((Test-Path "$repoDir\.git")) {
        Write-Output "Git ya está inicializado en $repoDir"
        return $true
    }

    Set-Location $repoDir
    git init 2>&1 | Out-Null
    Write-Output "Git init completado"

    if ($repoUrl) {
        git remote add origin $repoUrl 2>&1 | Out-Null
        Write-Output "Remote origin agregado: $repoUrl"
    }

    return $true
}

function Commit-And-Push {
    param($message)

    if (!(Test-GitInstalled)) { return $false }

    $repoDir = $CONFIG.GIT_REPO_DIR
    if (!(Test-Path "$repoDir\.git")) {
        Write-Error "Git no inicializado. Ejecuta primero Init-GitRepo"
        return $false
    }

    Set-Location $repoDir

    git add index.html 2>&1 | Out-Null
    git commit -m $message 2>&1 | Out-Null
    Write-Output "Commit hecho: $message"

    # Verificar si hay remote configurado
    $remote = git remote -v
    if ([string]::IsNullOrWhiteSpace($remote)) {
        Write-Output ""
        Write-Output "⚠️  No hay remote configurado. Para subir a GitHub:"
        Write-Output "   Crea un repo en https://github.com/new"
        Write-Output "   Luego ejecuta estos comandos MANUALMENTE una vez:"
        Write-Output ""
        Write-Output "   cd $repoDir"
        Write-Output '   git remote add origin https://github.com/TU_USUARIO/cartagena-local.git'
        Write-Output "   git branch -M main"
        Write-Output "   git push -u origin main"
        Write-Output ""
        return $true
    }

    # Push
    $branch = git branch --show-current
    if ([string]::IsNullOrWhiteSpace($branch)) { $branch = "main" }

    git push origin $branch 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Output "Push exitoso a origin/$branch"
    } else {
        Write-Output ""
        Write-Output "⚠️  Push falló. Posibles causas:"
        Write-Output "   - No tienes internet"
        Write-Output "   - No tienes permisos en el repo"
        Write-Output "   - El remote no está configurado correctamente"
        Write-Output "   Ejecuta manualmente: git push origin $branch"
        Write-Output ""
    }

    return $true
}

function Set-GitHubRemote {
    param($url)
    Set-Location $CONFIG.GIT_REPO_DIR
    git remote remove origin 2>$null
    git remote add origin $url 2>&1 | Out-Null
    Write-Output "Remote set: $url"
}

function Git-Status {
    Set-Location $CONFIG.GIT_REPO_DIR
    git status
}
