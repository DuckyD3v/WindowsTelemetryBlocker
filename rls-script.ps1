# ===============================
# Windows Telemetry Blocker
# Script Version: nextgen-0.8-RefreshedLauncherSystem (Refreshed)
# ===============================


param(
    [switch]$All,
    [string[]]$Modules,
    [string[]]$Exclude,
    [switch]$Interactive,
    [switch]$DryRun,
    [switch]$WhatIf,
    [switch]$RollbackOnFailure
)

$ScriptVersion = 'nextgen-0.8-RLS'

# --- Banner ---
Write-Host "===============================" -ForegroundColor Cyan
Write-Host (" Windows Telemetry Blocker v{0}" -f $ScriptVersion) -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan

# Fail fast for unhandled errors in scripts we call; we'll handle expected errors with try/catch
$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'

Write-Host ("Script started at: {0}" -f (Get-Date)) -ForegroundColor Yellow
Write-Host ("Running from: {0}" -f $PSScriptRoot) -ForegroundColor Yellow
Write-Host "================================`n"

# ==== Paths & files (define early) ====
$logFile            = Join-Path $PSScriptRoot "telemetry-blocker.log"
$errorLogFile       = Join-Path $PSScriptRoot "telemetry-blocker-errors.log"
$executionStatsFile = Join-Path $PSScriptRoot "telemetry-blocker-stats.log"
$reportFile         = Join-Path $PSScriptRoot "telemetry-blocker-report.md"
$modulesDir         = Join-Path $PSScriptRoot "modules"

# ==== Logging helpers (single authoritative definitions) ====
function Write-Log {
    param([string]$msg, [switch]$Error)
    try {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $entry = "$timestamp $msg"
        $entry | Out-File -FilePath $logFile -Append -Encoding utf8 -ErrorAction Stop
        if ($Error) {
            $entry | Out-File -FilePath $errorLogFile -Append -Encoding utf8 -ErrorAction Stop
        }
    } catch {
        # If logging fails, write minimal host output but don't throw
        Write-Host ("Logging failure: {0}" -f $_.Exception.Message) -ForegroundColor Red
    }
}

function Write-Stats {
    param([string]$msg)
    try {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "$timestamp $msg" | Out-File -FilePath $executionStatsFile -Append -Encoding utf8 -ErrorAction Stop
    } catch {
        Write-Log ("Failed to write stats: {0}" -f $_.Exception.Message) -Error
    }
}

# ==== Registry backup/export before changes ====
function Export-RegistryBackup {
    try {
        if (-not (Test-Path $modulesDir)) { New-Item -ItemType Directory -Path $modulesDir | Out-Null } # ensure modules dir exists for context
        $backupDir = Join-Path $PSScriptRoot "registry-backups"
        if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir | Out-Null }
        $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        $backupFile = Join-Path $backupDir ("regbackup_{0}.reg" -f $timestamp)
        Write-Host ("Exporting registry backup to {0} ..." -f $backupFile) -ForegroundColor Cyan
        # Use cmd reg.exe; call via & to ensure proper invocation
        & reg.exe export "HKLM" $backupFile /y | Out-Null
        Write-Host "[OK] Registry backup complete." -ForegroundColor Green
        Write-Log ("Registry backup exported to {0}" -f $backupFile)
    } catch {
        $msg = if ($_.Exception) { $_.Exception.Message } else { $_.ToString() }
        Write-Host ("[ERROR] Registry backup failed: {0}" -f $msg) -ForegroundColor Red
        Write-Log ("Registry backup failed: {0}" -f $msg) -Error
    }
}

if (-not $DryRun) { Export-RegistryBackup }

# ==== Gather OS info (safe) ====
try {
    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
    $winVersion = $osInfo.Version
    $winBuild   = $osInfo.BuildNumber
} catch {
    $winVersion = "Unknown"
    $winBuild   = "Unknown"
    Write-Log ("Failed to determine Windows version/build: {0}" -f $_.Exception.Message) -Error
}

Write-Log "=== Script started ==="
Write-Log ("Windows Version: {0}" -f $winVersion)
Write-Log ("Windows Build: {0}" -f $winBuild)
Write-Log ("Script Version: {0}" -f $ScriptVersion)

# ==== Ensure modules directory exists ====
if (-not (Test-Path $modulesDir)) {
    Write-Host "Creating modules directory..." -ForegroundColor Yellow
    try {
        New-Item -ItemType Directory -Path $modulesDir -Force | Out-Null
        Write-Host "[OK] Modules directory created" -ForegroundColor Green
        Write-Log ("Modules directory created at {0}" -f $modulesDir)
    } catch {
        Write-Host ("[ERROR] Failed to create modules directory: {0}" -f $_.Exception.Message) -ForegroundColor Red
        Write-Log ("Failed to create modules directory: {0}" -f $_.Exception.Message) -Error
        exit 1
    }
}

# ==== System helpers ====
function New-SystemRestorePoint {
    try {
        Write-Host "`nCreating system restore point..." -ForegroundColor Yellow
        $restorePointName = "Windows Telemetry Blocker - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        Checkpoint-Computer -Description $restorePointName -RestorePointType "APPLICATION_INSTALL" -ErrorAction Stop
        Write-Host "[OK] System restore point created successfully!" -ForegroundColor Green
        Write-Log ("System restore point created: {0}" -f $restorePointName)
        return $true
    } catch {
        Write-Host ("[ERROR] Failed to create system restore point: {0}" -f $_.Exception.Message) -ForegroundColor Red
        Write-Log ("Failed to create system restore point: {0}" -f $_.Exception.Message) -Error
        return $false
    }
}

function Test-WinVersion {
    try {
        $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        $version = [Version]$osInfo.Version
        $minVersion = [Version]"10.0.19041" # Windows 10 2004 or later
        if ($version -lt $minVersion) {
            Write-Host "[ERROR] Unsupported Windows version. This script requires Windows 10 2004 or later." -ForegroundColor Red
            Write-Log ("Unsupported Windows version: {0}" -f $version)
            return $false
        }
        Write-Host "[OK] Windows version check passed" -ForegroundColor Green
        Write-Log ("Windows version check passed: {0}" -f $version)
        return $true
    } catch {
        Write-Host ("[ERROR] Failed to check Windows version: {0}" -f $_.Exception.Message) -ForegroundColor Red
        Write-Log ("Failed to check Windows version: {0}" -f $_.Exception.Message) -Error
        return $false
    }
}

function Test-PowerShellVersion {
    try {
        $psVersion = $PSVersionTable.PSVersion
        $minVersion = [Version]"5.1"
        if ($psVersion -lt $minVersion) {
            Write-Host "[ERROR] Unsupported PowerShell version. This script requires PowerShell 5.1 or later." -ForegroundColor Red
            Write-Log ("Unsupported PowerShell version: {0}" -f $psVersion)
            return $false
        }
        Write-Host "[OK] PowerShell version check passed" -ForegroundColor Green
        Write-Log ("PowerShell version check passed: {0}" -f $psVersion)
        return $true
    } catch {
        Write-Host ("[ERROR] Failed to check PowerShell version: {0}" -f $_.Exception.Message) -ForegroundColor Red
        Write-Log ("Failed to check PowerShell version: {0}" -f $_.Exception.Message) -Error
        return $false
    }
}

function Test-AdminEvaluation {
    try {
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        if (-not $isAdmin) {
            Write-Host "[ERROR] This script requires administrative privileges. Please run as administrator." -ForegroundColor Red
            Write-Log "Insufficient privileges - script must be run as Administrator" -Error
            return $false
        }
        Write-Host "[OK] Administrative privileges confirmed" -ForegroundColor Green
        Write-Log "Administrative privileges confirmed"
        return $true
    } catch {
        Write-Host ("[ERROR] Failed to check admin privileges: {0}" -f $_.Exception.Message) -ForegroundColor Red
        Write-Log ("Failed to check admin privileges: {0}" -f $_.Exception.Message) -Error
        return $false
    }
}

function Invoke-IfNotDryRun {
    param([scriptblock]$Action, [string]$Description)
    if ($DryRun) {
        Write-Host ("[DRY-RUN] {0}" -f $Description) -ForegroundColor DarkYellow
        Write-Log ("[DRY-RUN] {0}" -f $Description)
    } else {
        & $Action
        Write-Log $Description
    }
}

function Test-PendingReboot {
    try {
        $pending = $false
        if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending") { $pending = $true }
        if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired") { $pending = $true }
        return $pending
    } catch {
        Write-Log ("Failed to check pending reboot: {0}" -f $_.Exception.Message) -Error
        return $false
    }
}

if (Test-PendingReboot) {
    Write-Host "⚠️  A system reboot is pending. It's recommended to reboot before running this script." -ForegroundColor Yellow
    Write-Log "Pending reboot detected."
}

# ==== Pre-checks ====

# IMPORTANT, $checks is out due to scoping issues with functions defined below
Write-Host "`n=== Running Pre-Execution Checks ===" -ForegroundColor Cyan
#$checks = @(
#    @{ Name = "Admin Privileges"; Function = { Test-AdminEvaluation } },
#    @{ Name = "Windows Version"; Function = { Test-WinVersion } },
#    @{ Name = "PowerShell Version"; Function = { Test-PowerShellVersion } }
#)

foreach ($check in $checks) {
    Write-Host ("`nChecking {0}..." -f $check.Name) -ForegroundColor Yellow
    if (-not (& $check.Function)) {
        Write-Host "Press any key to exit..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }
}

# Create system restore point (ask user if it fails)
if (-not (New-SystemRestorePoint)) {
    Write-Host "`n[ERROR] Failed to create system restore point. Do you want to continue anyway? (Y/N)" -ForegroundColor Yellow
    $response = Read-Host
    if ($response -ne 'Y') {
        Write-Host "Operation cancelled by user." -ForegroundColor Yellow
        Write-Host "Press any key to exit..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    } else {
        Write-Log "User chose to continue despite restore point failure"
    }
}

# ==== User interaction / module selection ====
$moduleList = @('telemetry','services','apps','misc')

function Show-Menu {
    Write-Host "`n=== Windows Telemetry Blocker ===" -ForegroundColor Cyan
    Write-Host "1. Default Mode (All Modules)" -ForegroundColor Yellow
    Write-Host "2. Custom Mode (Select Modules)" -ForegroundColor Yellow
    Write-Host "3. Exit" -ForegroundColor Red
    Write-Host "==============================`n"
}

function Show-ModuleSelection {
    Write-Host "`nAvailable Modules:" -ForegroundColor Cyan
    $i = 1
    foreach ($mod in $moduleList) {
        Write-Host ("{0}. {1}" -f $i, $mod) -ForegroundColor Yellow
        $i++
    }
    Write-Host "`nSelect modules to run (comma-separated numbers, e.g., 1,3,4):"
}

function Get-UserSelection {
    $selection = Read-Host
    $selectedModules = @()
    $numbers = $selection -split ','
    foreach ($num in $numbers) {
        if ([string]::IsNullOrWhiteSpace($num)) { continue }
        $trimmed = $num.Trim()
        $tryParse = $null
        if (-not [int]::TryParse($trimmed, [ref]$tryParse)) { continue }
        $index = [int]$trimmed - 1
        if ($index -ge 0 -and $index -lt $moduleList.Count) { $selectedModules += $moduleList[$index] }
    }
    return $selectedModules
}

if ($Interactive) {
    do {
        Show-Menu
        $choice = Read-Host "Enter your choice (1-3)"
        switch ($choice) {
            "1" { $toRun = $moduleList }
            "2" { Show-ModuleSelection; $toRun = Get-UserSelection }
            "3" { exit }
            default { Write-Host "Invalid choice. Please try again." -ForegroundColor Red; continue }
        }
        if ($toRun -and $toRun.Count -gt 0) {
            Write-Host "`nSelected modules:" -ForegroundColor Green
            $toRun | ForEach-Object { Write-Host ("- {0}" -f $_) -ForegroundColor Green }
            $confirm = Read-Host "`nProceed with selected modules? (Y/N)"
            if ($confirm -eq 'Y') { break }
        }
    } while ($true)
} elseif ($All) {
    $toRun = $moduleList
} elseif ($Modules) {
    $toRun = $Modules
} else {
    Write-Host "Specify -all, -modules <list>, or -interactive" -ForegroundColor Yellow
    exit 1
}

# ==== Module dependency resolution ====
$moduleDependencies = @{
    'telemetry' = @()
    'services'  = @('telemetry')
    'apps'      = @()
    'misc'      = @('telemetry','services')
}

function Resolve-ModuleDependencies {
    param([string[]]$mods)
    $resolved = @()
    foreach ($m in $mods) {
        if ($moduleDependencies.ContainsKey($m)) {
            foreach ($d in $moduleDependencies[$m]) {
                if ($d -and ($d -notin $resolved)) { $resolved += $d }
            }
        }
        if ($m -notin $resolved) { $resolved += $m }
    }
    return $resolved
}

# ==== Module execution loop ====
Write-Host "`n=== Starting Module Execution ===" -ForegroundColor Cyan
$summary = @()
$moduleResults = @{}
$executedModules = @()
$rollbackModules = @()
$startTime = Get-Date

$toRunResolved = Resolve-ModuleDependencies -mods $toRun

foreach ($mod in $toRunResolved) {
    Write-Host ("`nRunning module: {0}" -f $mod) -ForegroundColor Yellow
    $moduleStart = Get-Date
    try {
        $modulePath = Join-Path $modulesDir ("{0}.ps1" -f $mod)
        if (-not (Test-Path $modulePath)) { throw [System.IO.FileNotFoundException]("Module file not found: $modulePath") }
        $global:DryRun = $DryRun
        if ($DryRun) {
            Write-Host ("[DRY-RUN] Would run module: {0} ({1})" -f $mod, $modulePath) -ForegroundColor DarkYellow
            Write-Log ("[DRY-RUN] Would run module: {0}" -f $mod)
            $summary += ("DRY-RUN: {0} (skipped actual execution)" -f $mod)
            $moduleResults[$mod] = @{ Status='DRY-RUN'; Start=$moduleStart; End=(Get-Date) }
        } else {
            # Dot-source the module to run its logic
            $result = . $modulePath
            $executedModules += $mod
            if ($result -eq $false) {
                Write-Host ("[ERROR] Module {0} reported failure" -f $mod) -ForegroundColor Red
                Write-Log ("Module {0} reported failure" -f $mod) -Error
                $summary += ("Module {0} reported failure" -f $mod)
                $moduleResults[$mod] = @{ Status='Failure'; Start=$moduleStart; End=(Get-Date) }
            } else {
                Write-Log ("Module {0} completed" -f $mod)
                $summary += ("Module {0} completed" -f $mod)
                $moduleResults[$mod] = @{ Status='Success'; Start=$moduleStart; End=(Get-Date) }
            }
        }
        Write-Host ("[OK] Module {0} completed" -f $mod) -ForegroundColor Green
    } catch {
        $errMsg = if ($_.Exception) { $_.Exception.Message } else { $_.ToString() }
        Write-Host ("[ERROR] Error in module {0} : {1}" -f $mod, $errMsg) -ForegroundColor Red
        Write-Log ("ERROR in module {0} : {1}" -f $mod, $errMsg) -Error
        $summary += ("ERROR: {0} : {1}" -f $mod, $errMsg)
        $moduleResults[$mod] = @{ Status='Error'; Start=$moduleStart; End=(Get-Date); Error=$errMsg }

        if ($RollbackOnFailure) {
            Write-Host "Rolling back changes for executed modules..." -ForegroundColor Red
            Write-Log ("Rollback initiated due to failure in module {0}" -f $mod)

            # clone and reverse executedModules safely
            $executedClone = @()
            $executedClone += $executedModules
            [array]::Reverse($executedClone)

            foreach ($rmod in $executedClone) {
                $rollbackPath = Join-Path $modulesDir ("{0}-rollback.ps1" -f $rmod)
                if (Test-Path $rollbackPath) {
                    try {
                        Write-Host ("Running rollback for {0}..." -f $rmod) -ForegroundColor Yellow
                        . $rollbackPath
                        Write-Log ("Rollback for {0} completed" -f $rmod)
                        $rollbackModules += $rmod
                    } catch {
                        $rbErr = if ($_.Exception) { $_.Exception.Message } else { $_.ToString() }
                        Write-Host ("[ERROR] Rollback failed for {0}: {1}" -f $rmod, $rbErr) -ForegroundColor Red
                        Write-Log ("Rollback failed for {0}: {1}" -f $rmod, $rbErr) -Error
                    }
                } else {
                    Write-Host ("No rollback script for {0}" -f $rmod) -ForegroundColor DarkYellow
                    Write-Log ("No rollback script for {0}" -f $rmod)
                }
            }

            Write-Host "Rollback complete. Exiting." -ForegroundColor Red
            Write-Log "Rollback complete. Exiting."
            break
        } else {
            $response = Read-Host "Do you want to continue with remaining modules? (Y/N)"
            if ($response -ne 'Y') {
                Write-Host "Operation cancelled by user." -ForegroundColor Yellow
                Write-Log "Operation cancelled by user."
                break
            } else {
                Write-Log ("User chose to continue after error in {0}" -f $mod)
            }
        }
    }
}

# ==== Post execution stats & report ====
$endTime = Get-Date
$duration = $endTime - $startTime
Write-Stats ("Execution started: {0}" -f $startTime)
Write-Stats ("Execution ended: {0}" -f $endTime)
Write-Stats ("Total duration: {0}" -f $($duration.ToString()))

foreach ($mod in $moduleResults.Keys) {
    $res = $moduleResults[$mod]
    $status = $res.Status
    $s = $res.Start
    $e = $res.End
    $err = if ($res.ContainsKey('Error')) { $res.Error } else { '' }
    Write-Stats ("Module: {0} | Status: {1} | Start: {2} | End: {3} | Error: {4}" -f $mod, $status, $s, $e, $err)
}

if ($rollbackModules.Count -gt 0) {
    Write-Stats ("Rollback modules: {0}" -f ($rollbackModules -join ', '))
}

Write-Host "`n=== Operation Complete ===" -ForegroundColor Cyan
Write-Log "=== Operation Complete ==="
Write-Host "A system restore point was created before making changes." -ForegroundColor Green

# Summary to host & logs
Write-Host "`nSummary:" -ForegroundColor Cyan
foreach ($item in $summary) { Write-Host $item -ForegroundColor Gray }
Write-Log ("Summary:`n{0}" -f ($summary -join "`n"))

Write-Host ("`nExecution statistics written to: {0}" -f $executionStatsFile) -ForegroundColor Yellow
Write-Host ("Log file: {0}" -f $logFile) -ForegroundColor Yellow
Write-Host ("Error log: {0}" -f $errorLogFile) -ForegroundColor Yellow
if ($rollbackModules.Count -gt 0) {
    Write-Host ("Rollback modules executed: {0}" -f ($rollbackModules -join ', ')) -ForegroundColor Red
}

# --- Generate Markdown report ---
$reportContent = @()
$reportContent += "# Windows Telemetry Blocker - Change Report"
$reportContent += ""
$reportContent += ("**Date:** {0}" -f (Get-Date))
$reportContent += ("**Script Version:** {0}" -f $ScriptVersion)
$reportContent += ("**Windows Version:** {0}" -f $winVersion)
$reportContent += ("**Windows Build:** {0}" -f $winBuild)
$reportContent += ("**Execution Time:** {0}" -f $($duration.ToString()))
$reportContent += ""
$reportContent += "## Modules Run"

$moduleKeys = $moduleResults.Keys
foreach ($mod in $moduleKeys) {
    $res = $moduleResults[$mod]
    $status = $res.Status
    $s = $res.Start
    $e = $res.End
    $line = ("- {0} {1} (Start: {2}, End: {3})" -f $mod, $status, $s, $e)
    if ($res.ContainsKey('Error') -and $res.Error) { $line += (" - Error: {0}" -f $res.Error) }
    $reportContent += $line
}
$reportContent += ""
$reportContent += "## Summary"
foreach ($item in $summary) { $reportContent += ("- {0}" -f $item) }
$reportContent += ""
if ($rollbackModules.Count -gt 0) {
    $reportContent += "## Rollback Modules"
    $reportContent += ("- {0}" -f ($rollbackModules -join ', '))
}
$reportContent += ""
$errors = Get-Content -Path $errorLogFile -ErrorAction SilentlyContinue
if ($errors -and $errors.Count -gt 0) {
    $reportContent += "## Errors"
    foreach ($err in $errors) { $reportContent += ("- {0}" -f $err) }
}

try {
    $reportContent | Set-Content -Path $reportFile -Encoding utf8 -ErrorAction Stop
    Write-Host ("Report written to: {0}" -f $reportFile) -ForegroundColor Green
    Write-Log ("Report written to: {0}" -f $reportFile)
} catch {
    Write-Host ("[ERROR] Failed to write report: {0}" -f $_.Exception.Message) -ForegroundColor Red
    Write-Log ("Failed to write report: {0}" -f $_.Exception.Message) -Error
}

Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
