@echo off
:: Windows Telemetry Blocker Launcher (QoL Enhanced)
:: Ensures admin, supports spaces in paths, and works from any directory

setlocal
set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%windows-telemetry-blocker.ps1"

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

:: Prefer pwsh if available, fallback to Windows PowerShell
where pwsh >nul 2>&1
if %errorlevel%==0 (
    echo [INFO] Using PowerShell Core (pwsh)...
    pwsh -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"
    set "PS_EXIT=%ERRORLEVEL%"
) else (
    where powershell >nul 2>&1
    if %errorlevel%==0 (
        echo [INFO] Using Windows PowerShell...
        powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"
        set "PS_EXIT=%ERRORLEVEL%"
    ) else (
        echo [ERROR] PowerShell is not installed or not in PATH.
        pause
        exit /b 1
    )
)

:: QoL: Pause and show result
if "%PS_EXIT%" NEQ "0" (
    echo.
    echo [ERROR] The script exited with error code %PS_EXIT%.
    echo Please check the log and report files for details.
) else (
    echo.
    echo [SUCCESS] Script completed. Review the report and logs for results.
)
echo.
pause
endlocal