# ===============================
# Windows Telemetry Blocker
$ScriptVersion = '1.0 (presnapshot)'
# ===============================

# ==== SAFETY BARRIER SYSTEM ====
# Global state tracking for safe interruption handling
$global:CriticalOperationInProgress = $false
$global:CriticalOperationName = ""
$global:CriticalOperationStartTime = $null
$global:CleanupTasks = @()  # Queue of cleanup tasks to execute on exit
$global:ModulesExecuted = @()  # Track which modules have been executed
$global:PartialExecutionState = @{}  # Track state of partial operations

# Set up trap handler for interruptions (Ctrl+C)
trap {
    Write-Host "`n`n[CRITICAL] Script interrupted!" -ForegroundColor Red
    if ($global:CriticalOperationInProgress) {
        Write-Host "[SAFETY] Currently in critical operation: $($global:CriticalOperationName)" -ForegroundColor Yellow
        Write-Host "[SAFETY] Attempting graceful cleanup..." -ForegroundColor Yellow
        & Invoke-SafeCleanup
    }
    Write-Host "`n[INFO] Executing cleanup tasks..." -ForegroundColor Cyan
    & Invoke-CleanupTasks
    Write-Host "[INFO] Emergency exit complete." -ForegroundColor Yellow
    exit 1
}

# Register cleanup on script exit
$ExecutionContext.SessionState.Module.OnRemove = {
    & Invoke-CleanupTasks
}

param(
    [switch]$All,
    [string[]]$Modules,
    [string[]]$Exclude,
    [switch]$Interactive,
    [switch]$DryRun,
    [switch]$WhatIf,
    [switch]$RollbackOnFailure,
    [switch]$Rollback,
    [switch]$RestorePoint,
    [switch]$Update,
    [switch]$EnableAuditLog
)

# --- Special parameter handling (outside param block) ---
$handledSpecial = $false
if ($Rollback) {
    Write-Host "Starting rollback for all modules..." -ForegroundColor Yellow
    $rollbackList = @('telemetry','services','apps','misc')
    foreach ($mod in $rollbackList) {
        $rollbackPath = Join-Path $PSScriptRoot "modules\${mod}-rollback.ps1"
        if (Test-Path $rollbackPath) {
            try {
                Write-Host ("Running rollback for {0}..." -f $mod) -ForegroundColor Yellow
                . $rollbackPath
                Write-Log ("Rollback for {0} completed" -f $mod)
            } catch {
                $rbErr = if ($_.Exception) { $_.Exception.Message } else { $_.ToString() }
                Write-Host ("[ERROR] Rollback failed for {0}: {1}" -f $mod, $rbErr) -ForegroundColor Red
                Write-Log ("Rollback failed for {0}: {1}" -f $mod, $rbErr) -Error
            }
        } else {
            Write-Host ("No rollback script for {0}" -f $mod) -ForegroundColor DarkYellow
            Write-Log ("No rollback script for {0}" -f $mod)
        }
    }
    Write-Host "Rollback operation complete." -ForegroundColor Green
    Write-Log "Rollback operation complete."
    $handledSpecial = $true
}
if ($RestorePoint) {
    Write-Host "Restoring system via restore point and registry backup..." -ForegroundColor Yellow
    try {
        # Attempt system restore (requires admin)
        Write-Host "Attempting system restore..." -ForegroundColor Yellow
        # This is a placeholder; actual restore logic may require user interaction or external tools
        Write-Host "Please use Windows System Restore from Control Panel or Recovery Environment." -ForegroundColor Cyan
        Write-Log "Restore point operation requested. User should use Windows System Restore."
        # Optionally, restore registry backup
        $backupDir = Join-Path $PSScriptRoot "registry-backups"
        $backups = Get-ChildItem -Path $backupDir -Filter "regbackup_*.reg" | Sort-Object LastWriteTime -Descending
        if ($backups.Count -gt 0) {
            $latestBackup = $backups[0].FullName
            Write-Host ("Latest registry backup: {0}" -f $latestBackup) -ForegroundColor Yellow
            Write-Host "To restore, run: reg import \"$latestBackup\"" -ForegroundColor Cyan
            Write-Log ("Registry restore suggested: {0}" -f $latestBackup)
        } else {
            Write-Host "No registry backups found." -ForegroundColor Red
            Write-Log "No registry backups found for restore."
        }
    } catch {
        Write-Host ("[ERROR] Restore operation failed: {0}" -f $_.Exception.Message) -ForegroundColor Red
        Write-Log ("Restore operation failed: {0}" -f $_.Exception.Message) -Error
    }
    $handledSpecial = $true
}
if ($handledSpecial) {
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit
}

# --- Banner ---
Write-Host "===============================" -ForegroundColor Cyan
Write-Host (" Windows Telemetry Blocker v{0}" -f $ScriptVersion) -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan

# Check for updates if requested
if ($Update) {
    Write-Host "Update requested. Checking for updates..." -ForegroundColor Yellow
    Update-Script
    Write-Host "Update check complete." -ForegroundColor Green
    Write-AuditLog "Script update check performed"
}

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
$GitHubRepo         = "https://github.com/N0tHorizon/WindowsTelemetryBlocker"

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

# ==== SAFETY BARRIER FUNCTIONS ====
function Register-CleanupTask {
    param([scriptblock]$Task, [string]$Description)
    $cleanup = @{
        Task = $Task
        Description = $Description
        Timestamp = Get-Date
    }
    $global:CleanupTasks += $cleanup
    Write-Log ("Cleanup task registered: {0}" -f $Description)
}

function Invoke-CleanupTasks {
    if ($global:CleanupTasks.Count -eq 0) { return }
    
    Write-Host "`n[SAFETY] Executing registered cleanup tasks..." -ForegroundColor Cyan
    Write-Log "[SAFETY] Executing cleanup tasks"
    
    # Execute in reverse order (LIFO - Last In, First Out)
    for ($i = $global:CleanupTasks.Count - 1; $i -ge 0; $i--) {
        $cleanup = $global:CleanupTasks[$i]
        try {
            Write-Host ("  [CLEANUP] {0}..." -f $cleanup.Description) -ForegroundColor Yellow
            & $cleanup.Task
            Write-Log ("Cleanup completed: {0}" -f $cleanup.Description)
        } catch {
            Write-Host ("  [ERROR] Cleanup failed: {0} - {1}" -f $cleanup.Description, $_.Exception.Message) -ForegroundColor Red
            Write-Log ("Cleanup failed: {0} - {1}" -f $cleanup.Description, $_.Exception.Message) -Error
        }
    }
}

function Start-CriticalOperation {
    param([string]$OperationName, [scriptblock]$Operation)
    
    $global:CriticalOperationInProgress = $true
    $global:CriticalOperationName = $OperationName
    $global:CriticalOperationStartTime = Get-Date
    
    Write-Host "`n[CRITICAL OPERATION START] $OperationName" -ForegroundColor Yellow
    Write-Log "[CRITICAL OPERATION START] $OperationName"
    Write-Host "[WARNING] Do not interrupt this operation (Ctrl+C will trigger automatic rollback)" -ForegroundColor Yellow
    
    try {
        & $Operation
        Write-Host "[CRITICAL OPERATION SUCCESS] $OperationName completed successfully" -ForegroundColor Green
        Write-Log "[CRITICAL OPERATION SUCCESS] $OperationName"
        return $true
    } catch {
        $duration = $(Get-Date) - $global:CriticalOperationStartTime
        Write-Host "[CRITICAL OPERATION FAILED] $OperationName failed after $($duration.TotalSeconds)s" -ForegroundColor Red
        Write-Log "[CRITICAL OPERATION FAILED] $OperationName failed: $($_.Exception.Message)" -Error
        $global:PartialExecutionState[$OperationName] = @{
            Failed = $true
            Error = $_.Exception.Message
            StartTime = $global:CriticalOperationStartTime
            Duration = $duration
        }
        return $false
    } finally {
        $global:CriticalOperationInProgress = $false
        $global:CriticalOperationName = ""
    }
}

function Invoke-SafeCleanup {
    Write-Host "`n[SAFETY] Initiating emergency rollback procedures..." -ForegroundColor Red
    Write-Log "[SAFETY] Emergency rollback triggered"
    
    # Check if we need to rollback failed app removal
    if ($global:PartialExecutionState.ContainsKey("AppRemoval") -and $global:PartialExecutionState["AppRemoval"].Failed) {
        Write-Host "[SAFETY] Partial app removal detected - attempting restoration..." -ForegroundColor Yellow
        try {
            Write-Host "[SAFETY] Note: Windows Store apps cannot be fully restored automatically." -ForegroundColor Yellow
            Write-Host "[SAFETY] Please reinstall affected apps manually if needed." -ForegroundColor Yellow
            Write-Log "[SAFETY] Partial app removal - manual restoration may be needed"
        } catch {
            Write-Log "Failed to handle partial app removal: $($_.Exception.Message)" -Error
        }
    }
    
    # Registry restore is automatic on next Windows boot (restore point was created)
    Write-Host "[SAFETY] System Restore Point was created at script start - use it to revert changes if needed." -ForegroundColor Yellow
    Write-Log "[SAFETY] Registry rollback via System Restore Point available"
}

# ==== New Feature Functions ====
function Update-Script {
    Write-Host "Fetching latest version from GitHub..." -ForegroundColor Yellow
    try {
        # Download the main script
        $mainUrl = "$GitHubRepo/raw/main/windowstelementryblocker.ps1"
        $tempMain = Join-Path $PSScriptRoot "temp_main.ps1"
        Invoke-WebRequest -Uri $mainUrl -OutFile $tempMain -ErrorAction Stop

        # Download modules
        $apiUrl = "$GitHubRepo/contents/modules"
        $response = Invoke-WebRequest -Uri $apiUrl -Headers @{ "Accept" = "application/vnd.github.v3+json" } -ErrorAction Stop
        $files = $response.Content | ConvertFrom-Json

        foreach ($file in $files) {
            if ($file.name -like "*.ps1") {
                $fileUrl = $file.download_url
                $tempFile = Join-Path $PSScriptRoot ("temp_{0}" -f $file.name)
                Invoke-WebRequest -Uri $fileUrl -OutFile $tempFile -ErrorAction Stop
            }
        }

        # Confirm
        $confirm = Read-Host "Downloaded updates. Overwrite files? (Y/N)"
        if ($confirm -eq 'Y') {
            # Overwrite
            Move-Item $tempMain (Join-Path $PSScriptRoot "windowstelementryblocker.ps1") -Force -ErrorAction Stop
            foreach ($file in $files) {
                if ($file.name -like "*.ps1") {
                    $tempFile = Join-Path $PSScriptRoot ("temp_{0}" -f $file.name)
                    $dest = Join-Path $modulesDir $file.name
                    Move-Item $tempFile $dest -Force -ErrorAction Stop
                }
            }
            Write-Host "Update complete." -ForegroundColor Green
        } else {
            Write-Host "Update cancelled." -ForegroundColor Yellow
            # Clean temp
            Remove-Item (Join-Path $PSScriptRoot "temp_*") -Force -ErrorAction SilentlyContinue
        }
    } catch {
        Write-Host ("[ERROR] Update failed: {0}" -f $_.Exception.Message) -ForegroundColor Red
        # Clean temp
        Remove-Item (Join-Path $PSScriptRoot "temp_*") -Force -ErrorAction SilentlyContinue
    }
}

function Write-AuditLog {
    param([string]$Message, [string]$EventType = "Information")
    if (-not $EnableAuditLog) { return }
    try {
        if (-not (Get-EventLog -LogName Application -Source "TelemetryBlocker" -ErrorAction SilentlyContinue)) {
            New-EventLog -LogName Application -Source "TelemetryBlocker" -ErrorAction Stop
        }
        Write-EventLog -LogName Application -Source "TelemetryBlocker" -EventId 1000 -EntryType $EventType -Message $Message -ErrorAction Stop
    } catch {
        Write-Log ("Failed to write audit log: {0}" -f $_.Exception.Message) -Error
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
        # Show a simple status bar while reg.exe runs
        $script:backupJob = Start-Job -ScriptBlock { param($file) reg.exe export "HKLM" $file /y | Out-Null } -ArgumentList $backupFile
        $status = @('|','/','-','\\')
        $i = 0
        while ($backupJob.State -eq 'Running') {
            Write-Host -NoNewline ("`r[EXPORTING] Please wait " + $status[$i % $status.Length])
            Start-Sleep -Milliseconds 200
            $i++
            $backupJob = Get-Job -Id $backupJob.Id
        }
        Receive-Job -Id $backupJob.Id | Out-Null
        Remove-Job -Id $backupJob.Id | Out-Null
        Write-Host "`r[OK] Registry backup complete.           " -ForegroundColor Green
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
Write-AuditLog ("Script started - Version {0}, Windows {1} Build {2}" -f $ScriptVersion, $winVersion, $winBuild)

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

# ==== Rollback coverage scan ====
$rollbackCoverage = @{}
foreach ($mod in $moduleList) {
    $rollbackPath = Join-Path $modulesDir ("{0}-rollback.ps1" -f $mod)
    $rollbackCoverage[$mod] = Test-Path $rollbackPath
}
Write-Log ("Rollback coverage: {0}" -f (($rollbackCoverage.GetEnumerator() | ForEach-Object { "$($_.Key):$($_.Value)" }) -join ', '))

# ==== System helpers ====
function New-SystemRestorePoint {
    try {
        Write-Host "`nCreating system restore point..." -ForegroundColor Yellow
        $restorePointName = "Windows Telemetry Blocker - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        
        # Use Start-CriticalOperation to wrap restore point creation
        $result = Start-CriticalOperation -OperationName "Create System Restore Point" -Operation {
            Checkpoint-Computer -Description $restorePointName -RestorePointType "APPLICATION_INSTALL" -ErrorAction Stop
        }
        
        if ($result) {
            Write-Host "[OK] System restore point created successfully!" -ForegroundColor Green
            Write-Log ("System restore point created: {0}" -f $restorePointName)
            
            # Register cleanup to inform user about restore point availability
            Register-CleanupTask -Task {
                Write-Host "[SAFETY] Restore point available for rollback via System Restore." -ForegroundColor Yellow
            } -Description "Notify about system restore point for rollback"
            
            return $true
        } else {
            Write-Host ("[ERROR] Failed to create system restore point: Check Windows System Restore settings.") -ForegroundColor Red
            Write-Log "Failed to create system restore point"
            return $false
        }
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
$checks = @(
    @{ Name = "Admin Privileges"; Function = { Test-AdminEvaluation } },
    @{ Name = "Windows Version"; Function = { Test-WinVersion } },
    @{ Name = "PowerShell Version"; Function = { Test-PowerShellVersion } }
)

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
    Write-AuditLog ("Starting module execution: {0}" -f $mod)
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
                Write-AuditLog ("Module {0} execution failed" -f $mod) "Warning"
                $summary += ("Module {0} reported failure" -f $mod)
                $moduleResults[$mod] = @{ Status='Failure'; Start=$moduleStart; End=(Get-Date) }
            } else {
                Write-Log ("Module {0} completed" -f $mod)
                Write-AuditLog ("Module {0} execution completed successfully" -f $mod)
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
            Write-AuditLog ("Rollback initiated due to failure in module {0}" -f $mod) "Warning"

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
                        Write-AuditLog ("Rollback for {0} completed" -f $rmod)
                        $rollbackModules += $rmod
                    } catch {
                        $rbErr = if ($_.Exception) { $_.Exception.Message } else { $_.ToString() }
                        Write-Host ("[ERROR] Rollback failed for {0}: {1}" -f $rmod, $rbErr) -ForegroundColor Red
                        Write-Log ("Rollback failed for {0}: {1}" -f $rmod, $rbErr) -Error
                        Write-AuditLog ("Rollback failed for {0}: {1}" -f $rmod, $rbErr) "Error"
                    }
                } else {
                    Write-Host ("No rollback script for {0}" -f $rmod) -ForegroundColor DarkYellow
                    Write-Log ("No rollback script for {0}" -f $rmod)
                    Write-AuditLog ("No rollback script for {0}" -f $rmod) "Warning"
                }
            }

            Write-Host "Rollback complete. Exiting." -ForegroundColor Red
            Write-Log "Rollback complete. Exiting."
            Write-AuditLog "Rollback complete. Exiting."
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
