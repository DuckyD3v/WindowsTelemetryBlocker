@echo off
:: Windows Telemetry Blocker Launcher
:: Ensures admin, supports spaces in paths, and works from any directory

setlocal
set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%windows-telemetry-blocker.ps1"

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

:: Prefer pwsh if available, fallback to Windows PowerShell
where pwsh >nul 2>&1
if %errorlevel%==0 (
    pwsh -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"
) else (
    where powershell >nul 2>&1
    if %errorlevel%==0 (
        powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"
    ) else (
        echo ERROR: PowerShell is not installed or not in PATH.
        pause
        exit /b 1
    )
)
endlocal