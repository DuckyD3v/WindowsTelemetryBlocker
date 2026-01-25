# ===============================
# Integration Layer
# v1.0 - v0.9 Backward Compatibility Bridge
# ===============================

param(
    [string]$ConfigPath = $null,
    [string]$ProfileName = "balanced",
    [switch]$DryRun = $false,
    [switch]$Quiet = $false,
    [string]$LogDir = $null
)

# Get script root
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$configManagerPath = Join-Path (Split-Path -Parent $scriptRoot) "config" "config-manager.ps1"
$v09Root = Split-Path -Parent (Split-Path -Parent $scriptRoot)

# ===============================
# Configuration Loading
# ===============================

function Load-ExecutionConfig {
    <#
    .SYNOPSIS
    Load configuration for execution
    #>
    param(
        [string]$Profile = "balanced"
    )
    
    try {
        & $configManagerPath -Action load -ProfileName $Profile
    } catch {
        Write-Host "[ERROR] Failed to load config: $_" -ForegroundColor Red
        exit 1
    }
}

function Get-ModulesToExecute {
    <#
    .SYNOPSIS
    Determine which v0.9 modules to execute based on profile
    #>
    param(
        [parameter(Mandatory)]
        [psobject]$Profile
    )
    
    $modules = @()
    
    foreach ($module in $Profile.modules) {
        $moduleScript = Join-Path $v09Root "modules" "$module.ps1"
        
        if (Test-Path $moduleScript) {
            $modules += @{
                Name = $module
                Path = $moduleScript
                Type = if ($module.EndsWith("-rollback")) { "rollback" } else { "execute" }
            }
        } else {
            Write-Host "[WARN] Module not found: $module" -ForegroundColor Yellow
        }
    }
    
    return $modules
}

function Execute-Module {
    <#
    .SYNOPSIS
    Execute a v0.9 module with error handling
    #>
    param(
        [parameter(Mandatory)]
        [string]$ModulePath,
        
        [parameter(Mandatory)]
        [string]$ModuleName,
        
        [switch]$DryRun
    )
    
    try {
        Write-Host "`n[+] Executing: $ModuleName" -ForegroundColor Cyan
        
        # Dot source the module to execute it
        if ($DryRun) {
            Write-Host "  [DRY RUN] Would execute: $ModulePath" -ForegroundColor Yellow
        } else {
            & $ModulePath
        }
        
        return $true
    } catch {
        Write-Host "[ERROR] Module execution failed ($ModuleName): $_" -ForegroundColor Red
        return $false
    }
}

function Build-ExecutionSummary {
    <#
    .SYNOPSIS
    Build a summary of what will be executed
    #>
    param(
        [parameter(Mandatory)]
        [psobject]$Profile,
        
        [parameter(Mandatory)]
        [psobject[]]$Modules
    )
    
    $summary = @"

=== Execution Summary ===
Profile: $($Profile.name)
Description: $($Profile.description)

Modules to Execute:
"@
    
    foreach ($module in $Modules) {
        $summary += "`n  ✓ $($module.Name) ($($module.Type))"
    }
    
    if ($Profile.apps_remove) {
        $summary += "`n`nApps to Remove: $($Profile.apps_remove.Count)`n"
        foreach ($app in $Profile.apps_remove) {
            $summary += "  - $($app.display_name)`n"
        }
    }
    
    if ($Profile.services_disable) {
        $summary += "`nServices to Disable: $($Profile.services_disable.Count)`n"
        foreach ($service in $Profile.services_disable) {
            $summary += "  - $($service.display_name)`n"
        }
    }
    
    return $summary
}

function Create-RestorePoint {
    <#
    .SYNOPSIS
    Create a system restore point before execution
    #>
    param(
        [string]$Description = "WindowsTelemetryBlocker v1.0"
    )
    
    try {
        Write-Host "`n[INFO] Creating system restore point..." -ForegroundColor Cyan
        
        # Check if restore points are enabled
        $restoreEnabled = Get-ComputerRestorePoint -ErrorAction SilentlyContinue | Select-Object -First 1
        
        if ($restoreEnabled) {
            Checkpoint-Computer -Description $Description -ErrorAction Stop
            Write-Host "[OK] Restore point created" -ForegroundColor Green
            return $true
        } else {
            Write-Host "[WARN] System restore is not enabled, skipping restore point" -ForegroundColor Yellow
            return $false
        }
    } catch {
        Write-Host "[WARN] Failed to create restore point: $_" -ForegroundColor Yellow
        return $false
    }
}

function Backup-Registry {
    <#
    .SYNOPSIS
    Backup registry keys that will be modified
    #>
    param(
        [string]$BackupDir = $null
    )
    
    if ([string]::IsNullOrEmpty($BackupDir)) {
        $appDataPath = [Environment]::GetFolderPath("ApplicationData")
        $BackupDir = Join-Path $appDataPath "WindowsTelemetryBlocker" "backups"
    }
    
    try {
        if (-not (Test-Path $BackupDir)) {
            New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
        }
        
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $regFile = Join-Path $BackupDir "registry_backup_$timestamp.reg"
        
        Write-Host "[INFO] Backing up registry to: $regFile" -ForegroundColor Cyan
        
        # Backup common registry keys that v0.9 scripts modify
        $regKeys = @(
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
            "HKCU:\Software\Policies\Microsoft\Windows"
            "HKLM:\SYSTEM\CurrentControlSet\Services"
        )
        
        foreach ($key in $regKeys) {
            if (Test-Path $key) {
                # Export using reg.exe for compatibility
                & reg.exe export $key $regFile /y 2>&1 | Out-Null
            }
        }
        
        Write-Host "[OK] Registry backup created" -ForegroundColor Green
        return $regFile
    } catch {
        Write-Host "[WARN] Registry backup failed: $_" -ForegroundColor Yellow
        return $null
    }
}

function Validate-Execution {
    <#
    .SYNOPSIS
    Validate that system state is appropriate for execution
    #>
    param(
        [parameter(Mandatory)]
        [psobject]$Profile
    )
    
    $warnings = @()
    
    # Check if running as administrator
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        $warnings += "Script not running as administrator - some operations may fail"
    }
    
    # Check for critical services in profile
    $criticalServices = $Profile.services_disable | Where-Object { $_.critical -eq $true }
    if ($criticalServices) {
        $warnings += "Profile will disable critical services - ensure backups are made"
    }
    
    return $warnings
}

function Log-Execution {
    <#
    .SYNOPSIS
    Log execution details for audit/recovery
    #>
    param(
        [parameter(Mandatory)]
        [string]$Status,
        
        [string]$Details = "",
        [string]$LogPath = $null
    )
    
    if ([string]::IsNullOrEmpty($LogPath)) {
        $appDataPath = [Environment]::GetFolderPath("ApplicationData")
        $logPath = Join-Path $appDataPath "WindowsTelemetryBlocker" "logs"
        
        if (-not (Test-Path $logPath)) {
            New-Item -ItemType Directory -Path $logPath -Force | Out-Null
        }
        
        $LogPath = Join-Path $logPath "execution_$(Get-Date -Format 'yyyyMMdd').log"
    }
    
    $logEntry = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Status - $Details"
    Add-Content -Path $LogPath -Value $logEntry -Encoding UTF8
}

# ===============================
# Main Execution
# ===============================

function Start-IntegratedExecution {
    <#
    .SYNOPSIS
    Main execution flow with v1.0 features integrated
    #>
    
    try {
        # Load configuration
        Write-Host "`n=== Windows Telemetry Blocker v1.0 ===" -ForegroundColor Magenta
        Write-Host "Integration Layer - v0.9 Execution Bridge`n" -ForegroundColor Cyan
        
        $config = Load-ExecutionConfig -Profile $ProfileName
        $profile = $config.Profile
        $userConfig = $config.UserConfig
        
        # Get modules to execute
        $modules = Get-ModulesToExecute -Profile $profile
        
        if ($modules.Count -eq 0) {
            Write-Host "[WARN] No valid modules found for profile: $ProfileName" -ForegroundColor Yellow
            exit 0
        }
        
        # Display summary
        $summary = Build-ExecutionSummary -Profile $profile -Modules $modules
        Write-Host $summary -ForegroundColor White
        
        # Validate execution environment
        $warnings = Validate-Execution -Profile $profile
        if ($warnings) {
            Write-Host "`n⚠ Warnings:" -ForegroundColor Yellow
            foreach ($warning in $warnings) {
                Write-Host "  - $warning"
            }
        }
        
        # Confirmation
        if (-not $Quiet -and -not $DryRun) {
            Write-Host "`n" -NoNewline
            $confirm = Read-Host "Do you want to proceed? (yes/no)"
            if ($confirm -ne "yes") {
                Write-Host "[INFO] Execution cancelled by user" -ForegroundColor Cyan
                exit 0
            }
        }
        
        # Create backups
        if (-not $DryRun) {
            Create-RestorePoint -Description "WindowsTelemetryBlocker v1.0 - $ProfileName" | Out-Null
            Backup-Registry | Out-Null
        }
        
        # Execute modules
        $executedModules = @()
        $failedModules = @()
        
        Write-Host "`n=== Executing Modules ===" -ForegroundColor Magenta
        
        foreach ($module in $modules) {
            $result = Execute-Module -ModulePath $module.Path -ModuleName $module.Name -DryRun $DryRun
            
            if ($result) {
                $executedModules += $module.Name
            } else {
                $failedModules += $module.Name
            }
        }
        
        # Save execution state
        & $configManagerPath -Action state -ProfileName $ProfileName `
            -CustomSettings @{
                Save = $true
                Modules = $executedModules
                Status = if ($failedModules.Count -eq 0) { "completed" } else { "completed-with-errors" }
            }
        
        # Final summary
        Write-Host "`n=== Execution Complete ===" -ForegroundColor Magenta
        Write-Host "Modules Executed: $($executedModules.Count)" -ForegroundColor Green
        
        if ($failedModules.Count -gt 0) {
            Write-Host "Failed Modules: $($failedModules.Count)" -ForegroundColor Red
            foreach ($failed in $failedModules) {
                Write-Host "  - $failed"
            }
        }
        
        # Log execution
        $logDetails = "Profile: $ProfileName, Modules: $($executedModules.Count), Failed: $($failedModules.Count)"
        Log-Execution -Status "EXECUTION" -Details $logDetails
        
        Write-Host "`n[OK] Integration layer execution completed successfully" -ForegroundColor Green
        
    } catch {
        Write-Host "`n[ERROR] Execution failed: $_" -ForegroundColor Red
        Log-Execution -Status "ERROR" -Details $_
        exit 1
    }
}

# Execute main function
Start-IntegratedExecution
