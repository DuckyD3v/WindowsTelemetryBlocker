@echo off
:: Windows Telemetry Blocker Launcher (Menu Version)
:: Enhanced user interaction for script execution

setlocal
set "SCRIPT_DIR=%~dp0"

set "PS_SCRIPT=%SCRIPT_DIR%windowstelementryblocker.ps1"


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

:: --- Find any available PowerShell executable ---
set "PS_EXE="
where pwsh.exe >nul 2>&1
if %errorlevel%==0 (
    for /f "delims=" %%P in ('where pwsh.exe') do (
        set "PS_EXE=%%P"
        goto :foundps
    )
)
where powershell.exe >nul 2>&1
if %errorlevel%==0 (
    for /f "delims=" %%P in ('where powershell.exe') do (
        set "PS_EXE=%%P"
        goto :foundps
    )
)

:: Try common install locations if not found in PATH
if not defined PS_EXE (
    if exist "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" (
        set "PS_EXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
        goto :foundps
    )
    if exist "%ProgramFiles%\PowerShell\7\pwsh.exe" (
        set "PS_EXE=%ProgramFiles%\PowerShell\7\pwsh.exe"
        goto :foundps
    )
)

if not defined PS_EXE (
    echo [ERROR] No PowerShell executable found (pwsh.exe or powershell.exe).
    pause
    exit /b 1
)

:foundps
echo [INFO] Using PowerShell: %PS_EXE%

:: --- Menu ---
:menu
echo Please select an option:
echo   1. Run Interactive Script (Recommended)
echo   2. Restore via builtin rollback system
echo   3. Restore via System Restore Point
echo   4. Exit
set /p MENUOPT=Enter your choice [1-4]: 

set "PS_ARGS="
set "PS_TARGET=%PS_SCRIPT%"
if "%MENUOPT%"=="1" (
    echo [INFO] Launching interactive script in a new PowerShell window...
    start "TelemetryBlocker-Interactive" %PS_EXE% -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -Interactive
    exit /b
)
if "%MENUOPT%"=="2" set "PS_ARGS=-Rollback"
if "%MENUOPT%"=="3" set "PS_ARGS=-RestorePoint"
if "%MENUOPT%"=="4" goto end

:: Only check for invalid selection for options other than 1-4
if not "%MENUOPT%"=="1" if not "%MENUOPT%"=="2" if not "%MENUOPT%"=="3" if not "%MENUOPT%"=="4" (
    echo Invalid selection. Please try again.
    echo.
    goto menu
)


:runscript
:: --- Critical: Check PowerShell version ---
set "PS_VER_OK=0"
where pwsh >nul 2>&1
if %errorlevel%==0 (
    for /f "delims=" %%V in ('pwsh -NoProfile -Command "$PSVersionTable.PSVersion.ToString()"') do set PSVER=%%V
    echo [INFO] Using PowerShell Core (pwsh) version %PSVER%...
    set "PS_VER_OK=1"
    pwsh -NoProfile -ExecutionPolicy Bypass -File "%PS_TARGET%" %PS_ARGS%
    set "PS_EXIT=%ERRORLEVEL%"
) else (
    where powershell >nul 2>&1
    if %errorlevel%==0 (
        for /f "delims=" %%V in ('powershell -NoProfile -Command "$PSVersionTable.PSVersion.ToString()"') do set PSVER=%%V
        echo [INFO] Using Windows PowerShell version %PSVER%...
        set "PS_VER_OK=1"
        powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_TARGET%" %PS_ARGS%
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
    echo.
    :: Ensure logs are written before exit
    if exist "%PS_EXE%" (
        "%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "try { Import-Module '%PS_SCRIPT%' -ErrorAction Stop; if (Get-Command Write-Log -ErrorAction SilentlyContinue) { Write-Log '=== Script ended ===' } } catch { }"
    )
    echo Press any key to exit...
    pause >nul
    exit /b



if "%PS_VER_OK%" == "0" (
    echo [FATAL] No compatible PowerShell found.
    pause
    exit /b 1
)

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
goto menu

:end
endlocal
exit /b