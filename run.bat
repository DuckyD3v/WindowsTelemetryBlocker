@echo off
REM ============================================================================
REM Windows Telemetry Blocker Launcher
REM ============================================================================
REM Version: 1.5
REM Description: Batch launcher for Windows Telemetry Blocker with menu system
REM ============================================================================

setlocal enabledelayedexpansion

REM ============================================================================
REM Configuration and Path Setup
REM ============================================================================
set "SCRIPT_DIR=%~dp0"
set "LAUNCHER_VERSION=1.5"
set "LOG_FILE=%SCRIPT_DIR%telemetry-blocker.log"
set "PS_SCRIPT=%SCRIPT_DIR%windowstelemetryblocker.ps1"
set "SAFETY_LOG=%SCRIPT_DIR%telemetry-blocker-safety.log"
set "LAST_EXECUTION_STATE=%SCRIPT_DIR%.last-execution-state"
set "V1_LAUNCHER=%SCRIPT_DIR%v1.0\launcher.ps1"

REM ============================================================================
REM Logging Initialization
REM ============================================================================
if not exist "%LOG_FILE%" echo. > "%LOG_FILE%"
if not exist "%SAFETY_LOG%" echo. > "%SAFETY_LOG%"
echo %date% %time% [INFO] Launcher started >> "%LOG_FILE%"

REM Create safety log entry for this session
echo. >> "%SAFETY_LOG%"
echo %date% %time% ====== LAUNCHER SESSION START ====== >> "%SAFETY_LOG%"
echo %date% %time% [INFO] Launcher version: %LAUNCHER_VERSION% >> "%SAFETY_LOG%"

REM ============================================================================
REM Safety Checks
REM ============================================================================
REM Check for incomplete execution from previous session
if exist "%LAST_EXECUTION_STATE%" (
    echo.
    echo [WARN] Previous execution may have been interrupted.
    echo [INFO] Cleaning up...
    del "%LAST_EXECUTION_STATE%"
)

REM ============================================================================
REM Administrator Privilege Check
REM ============================================================================
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [WARN] This script requires administrator privileges.
    echo [WARN] Requesting elevation...
    echo %date% %time% [INFO] Requesting admin elevation >> "%LOG_FILE%"
    echo %date% %time% [INFO] Requesting admin elevation >> "%SAFETY_LOG%"
    PowerShell -ExecutionPolicy Bypass -Command "Start-Process '%~dpnx0' -Verb RunAs"
    exit /b
)

REM ============================================================================
REM Display Initialization
REM ============================================================================
cls
title Windows Telemetry Blocker
echo ===================================
echo    Windows Telemetry Blocker
echo ===================================
echo.
echo [OK] Running with administrator privileges.
echo %date% %time% [OK] Running with admin privileges >> "%LOG_FILE%"
echo.

REM ============================================================================
REM PowerShell Detection
REM ============================================================================
set "PS_EXE="
where pwsh.exe >nul 2>&1
if %errorlevel%==0 (
    for /f "delims=" %%P in ('where pwsh.exe') do (
        set "PS_EXE=%%P"
        goto :found_ps
    )
)

:check_pwsh
where powershell.exe >nul 2>&1
if %errorlevel%==0 (
    for /f "delims=" %%P in ('where powershell.exe') do (
        set "PS_EXE=%%P"
        goto :found_ps
    )
)

:check_default
if not defined PS_EXE (
    if exist "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" (
        set "PS_EXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
        goto :found_ps
    )
)

if not defined PS_EXE (
    echo [ERROR] No PowerShell found. Cannot continue.
    echo %date% %time% [ERROR] No PowerShell executable found >> "%LOG_FILE%"
    echo %date% %time% [ERROR] No PowerShell executable found >> "%SAFETY_LOG%"
    pause
    exit /b 1
)

:found_ps
echo [INFO] Using PowerShell: %PS_EXE%
echo %date% %time% [INFO] Using PowerShell: %PS_EXE% >> "%LOG_FILE%"
echo %date% %time% [INFO] Using PowerShell: %PS_EXE% >> "%SAFETY_LOG%"
echo.

REM ============================================================================
REM Script Validation
REM ============================================================================
REM Check for main script
if not exist "%PS_SCRIPT%" (
    echo [ERROR] Main PowerShell script not found: %PS_SCRIPT%
    echo %date% %time% [ERROR] Main script not found: %PS_SCRIPT% >> "%SAFETY_LOG%"
    pause
    exit /b 1
)

REM Get script version
"%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "(Get-Content '%PS_SCRIPT%' | Select-String 'Script Version:' | Select-Object -First 1).Line" >temp_version.txt 2>nul
if exist temp_version.txt (
    for /f "delims=" %%V in (temp_version.txt) do set "SCRIPT_VERSION=%%V"
    del temp_version.txt
)

if defined SCRIPT_VERSION (
    echo [INFO] %SCRIPT_VERSION%
)
echo.

REM ============================================================================
REM Main Menu Loop
REM ============================================================================
:menu
cls
title Windows Telemetry Blocker v1.0
timeout /t 1 /nobreak >nul
echo.
echo ======================================================================
echo.
echo         WINDOWS TELEMETRY BLOCKER v1.0 - Main Menu
echo.
echo ======================================================================
echo.
echo EXECUTION MODES:
echo.
echo  [1] v1.0 Launcher (NEW - Recommended)
echo      Modern interface with more advanced options
echo.
echo  [2] v0.9 Interactive Script
echo      Classic interactive telemetry blocker
echo.
echo RECOVERY AND MANAGEMENT:
echo.
echo  [3] Rollback (Undo recent changes)
echo      Restore services and registry to previous state
echo.
echo  [4] System Restore (Only use if rollback fails to recover)
echo      Use Windows System Restore point
echo.
echo  [5] Exit
echo      Close this launcher
echo.
echo ======================================================================
echo.
echo SAFETY NOTICE:
echo A system restore point is created before any changes.
echo Press Ctrl+C at any time to safely interrupt execution.
echo.
set /p CHOICE="Enter choice [1-5]: "

REM ============================================================================
REM Menu Option Handlers
REM ============================================================================
if "%CHOICE%"=="1" (
    REM Check if v1.0 launcher exists
    if not exist "%V1_LAUNCHER%" (
        echo [ERROR] v1.0 Launcher not found: %V1_LAUNCHER%
        echo [WARN] Falling back to v0.9 script.
        echo.
        goto choice_2
    )
    echo [INFO] Launching v1.0 GUI Launcher...
    echo [SAFETY] Recording execution state...
    echo v1.0 Launcher - Started %date% %time% > "%LAST_EXECUTION_STATE%"
    echo %date% %time% [EXECUTION] v1.0 launcher started >> "%SAFETY_LOG%"
    echo.
    "%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -File "%V1_LAUNCHER%"
    set LAUNCH_ERROR=!errorlevel!
    echo.
    echo [STATUS] v1.0 Launcher has closed.
    if !LAUNCH_ERROR! neq 0 (
        echo %date% %time% [ERROR] v1.0 launcher ended with error code !LAUNCH_ERROR! >> "%SAFETY_LOG%"
        echo [WARN] Launcher ended with error code: !LAUNCH_ERROR!
    ) else (
        echo %date% %time% [SUCCESS] v1.0 launcher completed successfully >> "%SAFETY_LOG%"
        del "%LAST_EXECUTION_STATE%"
    )
    echo.
    pause
    goto menu
)

:choice_2
if "%CHOICE%"=="2" (
    echo [INFO] Launching v0.9 interactive script...
    echo [SAFETY] Recording execution state...
    echo Interactive Mode - Started %date% %time% > "%LAST_EXECUTION_STATE%"
    echo %date% %time% [EXECUTION] Interactive mode started >> "%SAFETY_LOG%"
    "%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -Interactive
    if %errorlevel% neq 0 (
        echo %date% %time% [ERROR] Interactive mode ended with error code %errorlevel% >> "%SAFETY_LOG%"
        echo [WARN] Script ended with error. Check logs for details.
    ) else (
        echo %date% %time% [SUCCESS] Interactive mode completed successfully >> "%SAFETY_LOG%"
        del "%LAST_EXECUTION_STATE%"
    )
    pause
    goto menu
)

if "%CHOICE%"=="3" (
    echo [INFO] Launching rollback...
    echo [SAFETY] Recording execution state...
    echo Rollback Mode - Started %date% %time% > "%LAST_EXECUTION_STATE%"
    echo %date% %time% [EXECUTION] Rollback mode started >> "%SAFETY_LOG%"
    echo [WARN] This will UNDO all telemetry blocking changes made by this script.
    set /p CONFIRM="Are you sure? (Y/N): "
    if /i "!CONFIRM!"=="Y" (
        "%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -Rollback
        if %errorlevel% neq 0 (
            echo %date% %time% [ERROR] Rollback ended with error code %errorlevel% >> "%SAFETY_LOG%"
            echo [WARN] Rollback ended with error. Check logs for details.
        ) else (
            echo %date% %time% [SUCCESS] Rollback completed successfully >> "%SAFETY_LOG%"
            del "%LAST_EXECUTION_STATE%"
        )
    ) else (
        echo [INFO] Rollback cancelled by user.
        echo %date% %time% [INFO] Rollback cancelled by user >> "%SAFETY_LOG%"
        del "%LAST_EXECUTION_STATE%"
    )
    pause
    goto menu
)

if "%CHOICE%"=="4" (
    echo [INFO] Launching system restore...
    echo [SAFETY] Recording execution state...
    echo System Restore Mode - Started %date% %time% > "%LAST_EXECUTION_STATE%"
    echo %date% %time% [EXECUTION] System restore mode started >> "%SAFETY_LOG%"
    echo [WARN] This will perform a FULL SYSTEM RESTORE to a previous restore point.
    echo [WARN] All unsaved work will be lost. This action cannot be undone without data recovery.
    set /p CONFIRM="Are you absolutely sure? (Y/N): "
    if /i "!CONFIRM!"=="Y" (
        "%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -RestorePoint
        if %errorlevel% neq 0 (
            echo %date% %time% [ERROR] System restore ended with error code %errorlevel% >> "%SAFETY_LOG%"
            echo [WARN] System restore ended with error. Check logs for details.
        ) else (
            echo %date% %time% [SUCCESS] System restore completed >> "%SAFETY_LOG%"
            del "%LAST_EXECUTION_STATE%"
        )
    ) else (
        echo [INFO] System restore cancelled by user.
        echo %date% %time% [INFO] System restore cancelled by user >> "%SAFETY_LOG%"
        del "%LAST_EXECUTION_STATE%"
    )
    pause
    goto menu
)

if "%CHOICE%"=="5" (
    echo [INFO] Exiting...
    echo %date% %time% [INFO] Launcher exiting normally >> "%SAFETY_LOG%"
    exit /b 0
)

REM ============================================================================
REM Invalid Choice Handler
REM ============================================================================
echo Invalid choice. Please try again.
goto menu

