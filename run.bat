@echo off
:: Check for admin rights
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator privileges...
    PowerShell -ExecutionPolicy Bypass -Command "Start-Process '%~dpnx0' -Verb RunAs"
    exit /b
)
title Windows Telemetry Blocker
echo ===================================
echo    Windows Telemetry Blocker
echo ===================================
echo.
echo Starting script with administrator privileges...
echo Stuck? Try launching the .bat file as administrator.
echo.

PowerShell -ExecutionPolicy Bypass -NoProfile -File "%~dp0windows-telemetry-blocker.ps1"