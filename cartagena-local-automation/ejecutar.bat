@echo off
title El Parche - Sistema Automatizado v5.0 (JSON)
color 0a
cls
echo ============================================
echo   EL PARCHE - SISTEMA AUTOMATIZADO v5.0
echo   Panel central - Gestion JSON + GitHub
echo ============================================
echo.
echo  1. Automator interactivo (procesar WhatsApp manual)
echo  2. Procesar submissions web pendientes
echo  3. Ciclo de facturacion mensual
echo  4. Ver estado de facturacion
echo  5. Batch crear repos GitHub para ciudades
echo  6. Migrar Excel existente a JSON
echo.
echo  0. Salir
echo.
choice /C:1234560 /N /M "Elegi una opcion: "
if errorlevel 6 exit
if errorlevel 5 powershell -ExecutionPolicy Bypass -File "C:\Users\DIEGO\Desktop\moweb\cartagena-local-automation\scripts\batch-create-repos.ps1"; pause
if errorlevel 4 powershell -ExecutionPolicy Bypass -Command ". 'C:\Users\DIEGO\Desktop\moweb\cartagena-local-automation\config.ps1'; . 'C:\Users\DIEGO\Desktop\moweb\cartagena-local-automation\scripts\data-manager.ps1'; . 'C:\Users\DIEGO\Desktop\moweb\cartagena-local-automation\scripts\billing-manager.ps1'; Show-BillingStatus; pause"
if errorlevel 3 powershell -ExecutionPolicy Bypass -Command ". 'C:\Users\DIEGO\Desktop\moweb\cartagena-local-automation\config.ps1'; . 'C:\Users\DIEGO\Desktop\moweb\cartagena-local-automation\scripts\data-manager.ps1'; . 'C:\Users\DIEGO\Desktop\moweb\cartagena-local-automation\scripts\billing-manager.ps1'; Invoke-MonthlyBillingCycle; pause"
if errorlevel 2 powershell -ExecutionPolicy Bypass -Command ". 'C:\Users\DIEGO\Desktop\moweb\cartagena-local-automation\config.ps1'; . 'C:\Users\DIEGO\Desktop\moweb\cartagena-local-automation\scripts\web-processor.ps1'; Process-AllPendingSubmissions; pause"
if errorlevel 1 powershell -ExecutionPolicy Bypass -File "C:\Users\DIEGO\Desktop\moweb\cartagena-local-automation\automator.ps1"
pause
