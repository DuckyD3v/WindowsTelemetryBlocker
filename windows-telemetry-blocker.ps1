# ===============================
# Windows Telemetry Blocker
# Script Version: nextgen-0.1-DB6
# ===============================

$ScriptVersion = 'nextgen-0.1-DB6'

param(
    [switch]$all,
    [string[]]$modules,
    [string[]]$exclude,
    [switch]$interactive,
    [switch]$dryrun,
    [switch]$whatif
)

# --- Version Banner ---
$ScriptVersion = 'nextgen-0.1-DB6'
Write-Host "===============================" -ForegroundColor Cyan
Write-Host " Windows Telemetry Blocker v$ScriptVersion" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan

# Enable detailed error reporting
$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'

Write-Host "Script started at: $(Get-Date)" -ForegroundColor Yellow
Write-Host "Running from: $PSScriptRoot" -ForegroundColor Yellow
Write-Host "================================`n"

# Registry backup/export before changes
function Export-RegistryBackup {
    $backupDir = Join-Path $PSScriptRoot "registry-backups"
    if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir | Out-Null }
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $backupFile = Join-Path $backupDir "regbackup_$timestamp.reg"
    Write-Host "Exporting registry backup to $backupFile ..." -ForegroundColor Cyan
    reg export HKLM $backupFile /y | Out-Null
    Write-Host "✓ Registry backup complete." -ForegroundColor Green
}

# Only export backup if not dryrun
if (-not $dryrun) { Export-RegistryBackup }

# Logging setup
$logFile = Join-Path $PSScriptRoot "telemetry-blocker.log"
function Write-Log {
    param([string]$msg)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp $msg" | Out-File -FilePath $logFile -Append -Encoding utf8
}

Write-Log "=== Script started ==="

# Check if modules directory exists
$modulesDir = Join-Path $PSScriptRoot "modules"
if (-not (Test-Path $modulesDir)) {
    Write-Host "Creating modules directory..." -ForegroundColor Yellow
    try {
        New-Item -ItemType Directory -Path $modulesDir -Force | Out-Null
        Write-Host "✓ Modules directory created" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ Failed to create modules directory: $_" -ForegroundColor Red
        exit 1
    }
}

# Function to create a system restore point
function New-SystemRestorePoint {
    try {
        Write-Host "`nCreating system restore point..." -ForegroundColor Yellow
        $restorePointName = "Windows Telemetry Blocker - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        Checkpoint-Computer -Description $restorePointName -RestorePointType "APPLICATION_INSTALL"
        Write-Host "✓ System restore point created successfully!" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "✗ Failed to create system restore point: $_" -ForegroundColor Red
        return $false
    }
}

# Function to check Windows version compatibility
function Test-WindowsVersion {
    try {
        $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
        $version = [Version]$osInfo.Version
        $minVersion = [Version]"10.0.19041" # Windows 10 2004 or later

        if ($version -lt $minVersion) {
            Write-Host "✗ Unsupported Windows version. This script requires Windows 10 2004 or later." -ForegroundColor Red
            return $false
        }
        Write-Host "✓ Windows version check passed" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "✗ Failed to check Windows version: $_" -ForegroundColor Red
        return $false
    }
}

# Function to check PowerShell version
function Test-PowerShellVersion {
    try {
        $psVersion = $PSVersionTable.PSVersion
        $minVersion = [Version]"5.1"

        if ($psVersion -lt $minVersion) {
            Write-Host "✗ Unsupported PowerShell version. This script requires PowerShell 5.1 or later." -ForegroundColor Red
            return $false
        }
        Write-Host "✓ PowerShell version check passed" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "✗ Failed to check PowerShell version: $_" -ForegroundColor Red
        return $false
    }
}

# Function to check for admin privileges
function Test-AdminPrivileges {
    try {
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        if (-not $isAdmin) {
            Write-Host "✗ This script requires administrative privileges. Please run as administrator." -ForegroundColor Red
            return $false
        }
        Write-Host "✓ Administrative privileges confirmed" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "✗ Failed to check admin privileges: $_" -ForegroundColor Red
        return $false
    }
}

# Dry-run helper
function Invoke-IfNotDryRun {
    param([scriptblock]$Action, [string]$Description)
    if ($dryrun) {
        Write-Host "[DRY-RUN] $Description" -ForegroundColor DarkYellow
        Write-Log "[DRY-RUN] $Description"
    } else {
        & $Action
        Write-Log "$Description"
    }
}

# Pending reboot check
function Test-PendingReboot {
    $pending = $false
    if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending") {
        $pending = $true
    }
    if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired") {
        $pending = $true
    }
    return $pending
}

if (Test-PendingReboot) {
    Write-Host "⚠️  A system reboot is pending. It's recommended to reboot before running this script." -ForegroundColor Yellow
    Write-Log "Pending reboot detected."
}

# Run pre-execution checks
Write-Host "`n=== Running Pre-Execution Checks ===" -ForegroundColor Cyan

$checks = @(
    @{ Name = "Windows Version"; Function = { Test-WindowsVersion } },
    @{ Name = "PowerShell Version"; Function = { Test-PowerShellVersion } },
    @{ Name = "Admin Privileges"; Function = { Test-AdminPrivileges } }
)

$allChecksPassed = $true
foreach ($check in $checks) {
    Write-Host "`nChecking $($check.Name)..." -ForegroundColor Yellow
    if (-not (& $check.Function)) {
        $allChecksPassed = $false
        Write-Host "Press any key to exit..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }
}

# Create system restore point
if (-not (New-SystemRestorePoint)) {
    Write-Host "`n✗ Failed to create system restore point. Do you want to continue anyway? (Y/N)" -ForegroundColor Yellow
    $response = Read-Host
    if ($response -ne 'Y') {
        Write-Host "Operation cancelled by user." -ForegroundColor Yellow
        Write-Host "Press any key to exit..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }
}

$moduleList = @('telemetry', 'services', 'apps', 'misc')

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
        Write-Host "$i. $mod" -ForegroundColor Yellow
        $i++
    }
    Write-Host "`nSelect modules to run (comma-separated numbers, e.g., 1,3,4):"
}

function Get-UserSelection {
    $selection = Read-Host
    $selectedModules = @()
    $numbers = $selection -split ','
    
    foreach ($num in $numbers) {
        $index = [int]$num.Trim() - 1
        if ($index -ge 0 -and $index -lt $moduleList.Count) {
            $selectedModules += $moduleList[$index]
        }
    }
    return $selectedModules
}

if ($interactive) {
    do {
        Show-Menu
        $choice = Read-Host "Enter your choice (1-3)"
        
        switch ($choice) {
            "1" {
                $toRun = $moduleList
                break
            }
            "2" {
                Show-ModuleSelection
                $toRun = Get-UserSelection
                break
            }
            "3" {
                exit
            }
            default {
                Write-Host "Invalid choice. Please try again." -ForegroundColor Red
                continue
            }
        }
        
        if ($toRun.Count -gt 0) {
            Write-Host "`nSelected modules:" -ForegroundColor Green
            $toRun | ForEach-Object { Write-Host "- $_" -ForegroundColor Green }
            $confirm = Read-Host "`nProceed with selected modules? (Y/N)"
            if ($confirm -eq 'Y') {
                break
            }
        }
    } while ($true)
} elseif ($all) {
    $toRun = $moduleList
} elseif ($modules) {
    $toRun = $modules
} else {
    Write-Host "Specify -all, -modules <list>, or -interactive"
    exit 1
}

# --- Enhanced complex module execution with dependencies, rollback, and stats ---
# Dependency map for future expansion
$moduleDependencies = @{
    'telemetry' = @()
    'services' = @('telemetry')
    'apps' = @()
    'misc' = @('telemetry','services')
}

# Advanced logging
$errorLogFile = Join-Path $PSScriptRoot "telemetry-blocker-errors.log"
$executionStatsFile = Join-Path $PSScriptRoot "telemetry-blocker-stats.log"
function Write-Log {
    param([string]$msg, [switch]$Error)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "$timestamp $msg"
    $entry | Out-File -FilePath $logFile -Append -Encoding utf8
    if ($Error) {
        $entry | Out-File -FilePath $errorLogFile -Append -Encoding utf8
    }
}
function Write-Stats {
    param([string]$msg)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp $msg" | Out-File -FilePath $executionStatsFile -Append -Encoding utf8
}

function Resolve-ModuleDependencies {
    param([string[]]$modules)
    $resolved = @()
    foreach ($mod in $modules) {
        if ($moduleDependencies.ContainsKey($mod)) {
            foreach ($dep in $moduleDependencies[$mod]) {
                if ($dep -and ($dep -notin $resolved)) {
                    $resolved += $dep
                }
            }
        }
        if ($mod -notin $resolved) { $resolved += $mod }
    }
    return $resolved
}

Write-Host "`n=== Starting Module Execution ===" -ForegroundColor Cyan
$summary = @()
$moduleResults = @{}
$executedModules = @()
$rollbackModules = @()
$startTime = Get-Date

$toRunResolved = Resolve-ModuleDependencies $toRun

foreach ($mod in $toRunResolved) {
    Write-Host "`nRunning module: $mod" -ForegroundColor Yellow
    $moduleStart = Get-Date
    try {
        $modulePath = Join-Path $PSScriptRoot "modules\$mod.ps1"
        if (-not (Test-Path $modulePath)) {
            throw "Module file not found: $modulePath"
        }
        $global:dryrun = $dryrun
        if ($dryrun) {
            Write-Host "[DRY-RUN] Would run module: $mod ($modulePath)" -ForegroundColor DarkYellow
            Write-Log "[DRY-RUN] Would run module: $mod"
            $summary += "DRY-RUN: $mod (skipped actual execution)"
            $moduleResults[$mod] = @{ Status = 'DRY-RUN'; Start = $moduleStart; End = Get-Date }
        } else {
            $result = . $modulePath
            $executedModules += $mod
            if ($result -eq $false) {
                Write-Host "✗ Module $mod reported failure" -ForegroundColor Red
                Write-Log "Module $mod reported failure" -Error
                $summary += "Module $mod reported failure"
                $moduleResults[$mod] = @{ Status = 'Failure'; Start = $moduleStart; End = Get-Date }
            } else {
                Write-Log "Module $mod completed"
                $summary += "Module $mod completed"
                $moduleResults[$mod] = @{ Status = 'Success'; Start = $moduleStart; End = Get-Date }
            }
        }
        Write-Host "✓ Module $mod completed" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ Error in module $mod : $_" -ForegroundColor Red
        Write-Log "ERROR in module $mod : $_" -Error
        $summary += "ERROR: $mod : $_"
        $moduleResults[$mod] = @{ Status = 'Error'; Start = $moduleStart; End = Get-Date; Error = $_ }
        if ($rollbackOnFailure) {
            Write-Host "Rolling back changes for executed modules..." -ForegroundColor Red
            foreach ($rmod in [array]::Reverse($executedModules)) {
                $rollbackPath = Join-Path $PSScriptRoot "modules\$rmod-rollback.ps1"
                if (Test-Path $rollbackPath) {
                    try {
                        Write-Host "Running rollback for $rmod..." -ForegroundColor Yellow
                        . $rollbackPath
                        Write-Log "Rollback for $rmod completed"
                        $rollbackModules += $rmod
                    } catch {
                        Write-Host "✗ Rollback failed for $rmod`: $_" -ForegroundColor Red
                        Write-Log "Rollback failed for $rmod`: $_" -Error
                    }
                } else {
                    Write-Host "No rollback script for $rmod" -ForegroundColor DarkYellow
                    Write-Log "No rollback script for $rmod"
                }
            }
            Write-Host "Rollback complete. Exiting." -ForegroundColor Red
            break
        } else {
            Write-Host "Do you want to continue with remaining modules? (Y/N)" -ForegroundColor Yellow
            $response = Read-Host
            if ($response -ne 'Y') {
                Write-Host "Operation cancelled by user." -ForegroundColor Yellow
                Write-Log "Operation cancelled by user."
                break
            }
        }
    }
}

$endTime = Get-Date
$duration = $endTime - $startTime
Write-Stats "Execution started: $startTime"
Write-Stats "Execution ended: $endTime"
Write-Stats "Total duration: $($duration.ToString())"
foreach ($mod in $moduleResults.Keys) {
    $res = $moduleResults[$mod]
    Write-Stats "Module: $mod | Status: $($res.Status) | Start: $($res.Start) | End: $($res.End) | Error: $($res.Error)"
}
if ($rollbackModules.Count -gt 0) {
    Write-Stats "Rollback modules: $($rollbackModules -join ', ')"
}

Write-Host "`n=== Operation Complete ===" -ForegroundColor Cyan
Write-Log "=== Operation Complete ==="
Write-Host "A system restore point was created before making changes." -ForegroundColor Green

# Summary report
Write-Host "`nSummary:" -ForegroundColor Cyan
foreach ($item in $summary) {
    Write-Host $item -ForegroundColor Gray
}
Write-Log "Summary:`n$($summary -join "`n")"

Write-Host "`nExecution statistics written to: $executionStatsFile" -ForegroundColor Yellow
Write-Host "Log file: $logFile" -ForegroundColor Yellow
Write-Host "Error log: $errorLogFile" -ForegroundColor Yellow
if ($rollbackModules.Count -gt 0) {
    Write-Host "Rollback modules executed: $($rollbackModules -join ', ')" -ForegroundColor Red
}
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")