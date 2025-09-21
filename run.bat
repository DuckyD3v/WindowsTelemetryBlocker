@echo off
:: Windows Telemetry Blocker Launcher (Critical Features Enhanced)
:: Ensures admin, supports spaces in paths, and works from any directory

setlocal
set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%windows-telemetry-blocker.ps1"

:: --- Critical: Check for script existence ---
if not exist "%PS_SCRIPT%" (
    echo [FATAL] Main PowerShell script not found: %PS_SCRIPT%
    echo Please ensure all files are extracted and try again.
    pause
    exit /b 1
)

:: --- Critical: Print script version if available ---
for /f "tokens=3 delims=' " %%A in ('findstr /C:"$ScriptVersion = '" "%PS_SCRIPT%"') do set SCRIPT_VERSION=%%A
if defined SCRIPT_VERSION (
    echo [INFO] Script version: %SCRIPT_VERSION%
)

:: QoL: Clear screen and color title (if supported)
cls
title Windows Telemetry Blocker
echo ===================================
echo    Windows Telemetry Blocker
echo ===================================
echo.
echo [INFO] This launcher will ensure you have admin rights and run the script with the best available PowerShell.
echo [INFO] If you see errors, right-click and 'Run as administrator'.
echo [INFO] Logs and reports will be saved in the script folder.
echo.

:: Check for admin rights
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [WARN] Requesting administrator privileges...
    PowerShell -ExecutionPolicy Bypass -Command "Start-Process '%~dpnx0' -Verb RunAs"
    exit /b
)

echo [OK] Running with administrator privileges.
echo.

:: --- Critical: Check PowerShell version ---
set "PS_VER_OK=0"
where pwsh >nul 2>&1
if %errorlevel%==0 (
    for /f "delims=" %%V in ('pwsh -NoProfile -Command "$PSVersionTable.PSVersion.ToString()"') do set PSVER=%%V
    echo [INFO] Using PowerShell Core (pwsh) version %PSVER%...
    set "PS_VER_OK=1"
    pwsh -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"
    set "PS_EXIT=%ERRORLEVEL%"
) else (
    where powershell >nul 2>&1
    if %errorlevel%==0 (
        for /f "delims=" %%V in ('powershell -NoProfile -Command "$PSVersionTable.PSVersion.ToString()"') do set PSVER=%%V
        echo [INFO] Using Windows PowerShell version %PSVER%...
        set "PS_VER_OK=1"
        powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"
        set "PS_EXIT=%ERRORLEVEL%"
    ) else (
        echo [ERROR] PowerShell is not installed or not in PATH.
        pause
        exit /b 1
    )
)
if "%PS_VER_OK%" == "0" (
    echo [FATAL] No compatible PowerShell found.
    pause
    exit /b 1
)

:: --- Critical: Pause and show result, print log/report if error ---
if "%PS_EXIT%" NEQ "0" (
    echo.
    echo [ERROR] The script exited with error code %PS_EXIT%.
    if exist "%SCRIPT_DIR%telemetry-blocker-errors.log" (
        echo --- Error Log ---
        type "%SCRIPT_DIR%telemetry-blocker-errors.log"
    )
    if exist "%SCRIPT_DIR%telemetry-blocker-report.md" (
        echo --- Report ---
        type "%SCRIPT_DIR%telemetry-blocker-report.md"
    )
    echo Please check the log and report files for details.
) else (
    echo.
    echo [SUCCESS] Script completed. Review the report and logs for results.
)
echo.
pause
endlocal