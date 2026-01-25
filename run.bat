@echo off
REM Windows Telemetry Blocker Launcher

setlocal enabledelayedexpansion
set "SCRIPT_DIR=%~dp0"
set "LAUNCHER_VERSION=1.3"
set "LOG_FILE=%SCRIPT_DIR%telemetry-blocker.log"
set "PS_SCRIPT=%SCRIPT_DIR%windowstelementryblocker.ps1"
set "SAFETY_LOG=%SCRIPT_DIR%telemetry-blocker-safety.log"
set "LAST_EXECUTION_STATE=%SCRIPT_DIR%.last-execution-state"

REM Initialize logs
if not exist "%LOG_FILE%" echo. > "%LOG_FILE%"
if not exist "%SAFETY_LOG%" echo. > "%SAFETY_LOG%"
echo %date% %time% [INFO] Launcher started >> "%LOG_FILE%"

REM Create safety log entry for this session
echo. >> "%SAFETY_LOG%"
echo %date% %time% ====== LAUNCHER SESSION START ====== >> "%SAFETY_LOG%"
echo %date% %time% [INFO] Launcher version: %LAUNCHER_VERSION% >> "%SAFETY_LOG%"

REM Check for incomplete execution from previous session
if exist "%LAST_EXECUTION_STATE%" (
    echo.
    echo [WARN] Previous execution may have been interrupted.
    echo [INFO] Checking status...
    echo %date% %time% [WARN] Incomplete execution detected from previous session >> "%SAFETY_LOG%"
    
    for /f "delims=" %%A in (%LAST_EXECUTION_STATE%) do (
        echo %%A
        echo %date% %time% [STATUS] %%A >> "%SAFETY_LOG%"
    )
    
    echo.
    echo Do you want to:
    echo 1. Run full rollback for safety
    echo 2. Continue normally (not recommended)
    echo 3. Exit
    set /p INCOMPLETE_CHOICE="Enter choice [1-3]: "
    
    if "!INCOMPLETE_CHOICE!"=="1" (
        echo [INFO] Running rollback for safety...
        echo %date% %time% [SAFETY] User elected rollback for incomplete execution >> "%SAFETY_LOG%"
        del "%LAST_EXECUTION_STATE%"
        goto menu
    )
    if "!INCOMPLETE_CHOICE!"=="3" (
        echo [INFO] Exiting...
        exit /b 0
    )
    echo Continuing normally.
    del "%LAST_EXECUTION_STATE%"
)

REM Check admin rights
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [WARN] This script requires administrator privileges.
    echo [WARN] Requesting elevation...
    echo %date% %time% [INFO] Requesting admin elevation >> "%LOG_FILE%"
    echo %date% %time% [INFO] Requesting admin elevation >> "%SAFETY_LOG%"
    PowerShell -ExecutionPolicy Bypass -Command "Start-Process '%~dpnx0' -Verb RunAs"
    exit /b
)

REM Display title
cls
title Windows Telemetry Blocker
echo ===================================
echo    Windows Telemetry Blocker
echo ===================================
echo.
echo [OK] Running with administrator privileges.
echo %date% %time% [OK] Running with admin privileges >> "%LOG_FILE%"
echo.

REM Find PowerShell
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

REM Check for main script
if not exist "%PS_SCRIPT%" (
    echo [ERROR] Main PowerShell script not found: %PS_SCRIPT%
    echo %date% %time% [ERROR] Main script not found: %PS_SCRIPT% >> "%SAFETY_LOG%"
    pause
    exit /b 1
)

REM Get script version
"%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "(Get-Content '%PS_SCRIPT%' | Select-String '# Script Version:' | Select-Object -First 1).Line" >temp_version.txt 2>nul
if exist temp_version.txt (
    for /f "delims=" %%V in (temp_version.txt) do set "SCRIPT_VERSION=%%V"
    del temp_version.txt
)

if defined SCRIPT_VERSION (
    echo [INFO] %SCRIPT_VERSION%
)
echo.

REM Main menu
:menu
echo.
echo ===================================
echo         MENU
echo ===================================
echo 1. Run Interactive Script (Recommended)
echo 2. Rollback (Undo telemetry blocking)
echo 3. System Restore (Full system recovery)
echo 4. Exit
echo ===================================
echo.
echo [SAFETY] Note: A system restore point is created before any changes.
echo [SAFETY] Press Ctrl+C if the script is running incorrectly.
echo.
set /p CHOICE="Enter choice [1-4]: "

if "%CHOICE%"=="1" (
    echo [INFO] Launching interactive script...
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

if "%CHOICE%"=="2" (
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

if "%CHOICE%"=="3" (
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

if "%CHOICE%"=="4" (
    echo [INFO] Exiting...
    echo %date% %time% [INFO] Launcher exiting normally >> "%SAFETY_LOG%"
    exit /b 0
)

echo Invalid choice. Please try again.
goto menu
