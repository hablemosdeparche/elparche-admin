@echo off
title El Parche Agent - Instalacion
color 0a
cls
echo ============================================
echo   EL PARCHE AGENT - INSTALACION
echo ============================================
echo.

set "AGENT_DIR=%~dp0"
set "EXE=%AGENT_DIR%ElParcheAgent.exe"
set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"

rem ─── Compilar si no existe ───
if not exist "%EXE%" (
    echo [1/3] Compilando ElParcheAgent.exe...
    cd /d "%AGENT_DIR%"
    powershell -ExecutionPolicy Bypass -File "build-exe.ps1"
    if errorlevel 1 (
        echo ERROR: No se pudo compilar.
        pause
        exit /b 1
    )
) else (
    echo [1/3] ElParcheAgent.exe ya existe.
)

rem ─── Copiar a Startup ───
echo [2/3] Agregando a Inicio...
copy /Y "%EXE%" "%STARTUP%\ElParcheAgent.exe" >nul
echo   OK: %STARTUP%\ElParcheAgent.exe

rem ─── Tarea programada (respaldo diario a las 6 AM) ───
echo [3/3] Creando tarea programada...
schtasks /Create /SC DAILY /TN "ElParcheAgent" /TR "'%EXE%'" /ST 06:00 /F >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo   OK: Tarea diaria a las 06:00
) else (
    echo   Info: Tarea ya existe (no critico)
)

rem ─── Iniciar ───
echo.
echo Iniciando El Parche Agent...
start "" "%EXE%"

echo.
echo ============================================
echo   LISTO!
echo ============================================
echo.
echo   El icono aparece en la bandeja del sistema.
echo   Clic derecho para opciones.
echo.
echo   - Se inicia automaticamente con Windows
echo   - Corre cada 24h (ciclo de facturacion)
echo   - Verifica vencidos y los oculta del sitio
echo.
echo   LOG:    %AGENT_DIR%elparche-agent.log
echo   CORE:   %AGENT_DIR%elparche-core.ps1
echo.
pause
