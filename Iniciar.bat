@echo off
title PC Optimizer
cd /d "%~dp0"

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo   Pidiendo permisos de administrador...
    powershell -NoProfile -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0PCOptimizer.ps1"
if %errorlevel% neq 0 (
    echo.
    echo   La aplicacion termino con errores. Pulsa una tecla para cerrar.
    pause >nul
)
