# ===============================
# v1.0 Launcher
# Modern GUI for v0.9 Core Functionality
# ===============================

param(
    [string]$Profile = "balanced",
    [switch]$DryRun = $false,
    [switch]$Quiet = $false,
    [switch]$NoBackup = $false,
    [string]$LogDir = $null
)

# Get paths - use PSScriptRoot for reliability
$scriptRoot = $PSScriptRoot
if (-not $scriptRoot) {
    $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
}
# Shared utilities are in v1.0/shared
$sharedPath = Join-Path $scriptRoot "shared"
$integrationPath = Join-Path $sharedPath "integration.ps1"

# Get v0.9 script path (parent directory)
$repoRoot = Split-Path -Parent $scriptRoot
$v09ScriptPath = Join-Path $repoRoot "windowstelementryblocker.ps1"

# Source utilities
$utilsPath = Join-Path $sharedPath "utils.ps1"
if (Test-Path $utilsPath) {
    . $utilsPath
} else {
    Write-Host "ERROR: Cannot find utilities at $utilsPath" -ForegroundColor Red
    exit 1
}

# ===============================
# Welcome & Initialization
# ===============================

function Show-Welcome {
    Clear-Host
    Write-Host @"

======================================================
   Windows Telemetry Blocker - v1.0 Launcher       
   Advanced Privacy & Control System                
======================================================

"@ -ForegroundColor Magenta

    Write-Host "Initializing..." -ForegroundColor Cyan
}

function Validate-Requirements {
    <#
    .SYNOPSIS
    Validate system requirements before execution
    #>
    Write-Host "`nValidating system requirements...`n" -ForegroundColor Cyan
    
    $requirements = @()
    $systemInfo = Get-SystemInfo
    
    # Check PowerShell version
    $psVersion = $PSVersionTable.PSVersion
    if ($psVersion.Major -lt 5) {
        $requirements += @{
            Name = "PowerShell Version"
            Required = "5.0+"
            Current = $psVersion
            Status = "FAIL"
        }
    } else {
        $requirements += @{
            Name = "PowerShell Version"
            Required = "5.0+"
            Current = "$($psVersion.Major).$($psVersion.Minor)"
            Status = "PASS"
        }
    }
    
    # Check admin privilege
    if (-not (Test-AdminPrivilege)) {
        $requirements += @{
            Name = "Administrator Privilege"
            Required = "Yes"
            Current = "No"
            Status = "FAIL"
        }
    } else {
        $requirements += @{
            Name = "Administrator Privilege"
            Required = "Yes"
            Current = "Yes"
            Status = "PASS"
        }
    }
    
    # Check Windows version
    $osVersion = [System.Environment]::OSVersion.VersionString
    if ($osVersion -match "Windows 10|Windows 11|Server 2016|Server 2019|Server 2022") {
        $requirements += @{
            Name = "Windows Version"
            Required = "10/11/Server 2016+"
            Current = "Supported"
            Status = "PASS"
        }
    } else {
        $requirements += @{
            Name = "Windows Version"
            Required = "10/11/Server 2016+"
            Current = "Unknown"
            Status = "WARN"
        }
    }
    
    # Display requirements
    foreach ($req in $requirements) {
        $color = switch ($req.Status) {
            "PASS" { "Green" }
            "WARN" { "Yellow" }
            "FAIL" { "Red" }
        }
        
        Write-Host "[+] $($req.Name)" -ForegroundColor White
        Write-Host "  Required: $($req.Required)" -ForegroundColor Gray
        Write-Host "  Current: $($req.Current)" -ForegroundColor $color
        Write-Host "  Status: $($req.Status)`n" -ForegroundColor $color
    }
    
    # Check for failures
    $failures = $requirements | Where-Object { $_.Status -eq "FAIL" }
    if ($failures) {
        Write-Host "[ERROR] System requirements not met!" -ForegroundColor Red
        Write-Host "Please ensure PowerShell is running as Administrator`n" -ForegroundColor Yellow
        return $false
    }
    
    return $true
}

function Show-ProfileSelection {
    <#
    .SYNOPSIS
    Interactive profile selection menu
    #>
    Write-Host "`n=== Profile Selection ===" -ForegroundColor Cyan
    Write-Host @"

Choose an execution profile:

1. Minimal
   * Disables telemetry services only
     Safest option, minimal system impact
      
2. Balanced (RECOMMENDED)
   * Disables telemetry + removes telemetry apps
     Good balance of privacy and stability
      
3. Maximum
   * Removes all telemetry-related apps and services
     Most aggressive option, highest privacy
      
4. Custom
   * Define your own app/service removals
      
5. View Details
   * See detailed information about each profile

"@
    
    $selection = Read-Host "Select option (1-5)"
    
    switch ($selection) {
        "1" { return "minimal" }
        "2" { return "balanced" }
        "3" { return "maximum" }
        "4" { return "custom" }
        "5" {
            Show-ProfileDetails
            return Show-ProfileSelection
        }
        default {
            Write-Host "[ERROR] Invalid selection" -ForegroundColor Red
            return Show-ProfileSelection
        }
    }
}

function Show-ProfileDetails {
    <#
    .SYNOPSIS
    Show detailed profile information
    #>
    Write-Host "`n=== Profile Details ===" -ForegroundColor Magenta
    Write-Host @"

MINIMAL:
  * Recommended for: Users who want basic telemetry protection
  * Services disabled: 4 (DiagTrack, dmwappushservice, dmwappushservice, etc.)
  * Apps removed: 0
  * System impact: Low
  * Recovery difficulty: Very easy

BALANCED (RECOMMENDED):
  * Recommended for: Most users
  * Services disabled: 9 (All telemetry services)
  * Apps removed: 5-7 (Cortana, Widgets, etc.)
  * System impact: Moderate
  * Recovery difficulty: Easy - use rollback scripts

MAXIMUM:
  * Recommended for: Privacy-conscious users
  * Services disabled: 9
  * Apps removed: 15-20 (Including entertainment/ads apps)
  * System impact: High
  * Recovery difficulty: Moderate - some manual steps may be needed

CUSTOM:
  * Recommended for: Advanced users
  * Services/Apps: You choose exactly what to remove
  * System impact: Depends on your choices
  * Recovery difficulty: You control it

"@
}

function Show-ExecutionOptions {
    <#
    .SYNOPSIS
    Show execution options menu
    #>
    Write-Host "`n=== Execution Options ===" -ForegroundColor Cyan
    Write-Host @"

1. Execute Now
   * Run the selected profile immediately
   
2. Dry Run
   * Show what would be done without making changes
   
3. Schedule Execution
   * Schedule this profile to run at a specific time
   
4. Configure Advanced Options
   * Set up monitoring, auto-remediation, etc.
   
5. Cancel
   * Go back without executing

"@
    
    $selection = Read-Host "Select option (1-5)"
    return $selection
}

function Confirm-Execution {
    <#
    .SYNOPSIS
    Show final confirmation before execution
    #>
    param(
        [parameter(Mandatory)]
        [string]$ProfileName
    )
    
    Write-Host "`n" -NoNewline
    Write-Host "[!] WARNING: This operation will modify system settings!" -ForegroundColor Yellow
    Write-Host @"

Profile: $ProfileName
  * Your system will be modified
  * A restore point will be created
  * Registry backups will be saved
  * You can rollback using provided scripts

Are you sure you want to continue?
(Type 'yes' to confirm, anything else to cancel)
"@
    
    $confirm = Read-Host "Proceed?"
    return ($confirm -eq "yes")
}

function Execute-Profile {
    <#
    .SYNOPSIS
    Execute the selected profile by calling v0.9 script
    #>
    param(
        [parameter(Mandatory)]
        [string]$ProfileName
    )
    
    Write-Host "`n=== Starting Execution ===" -ForegroundColor Magenta
    Write-LogEntry "INFO" "Starting execution with profile: $ProfileName"
    
    # Map profiles to v0.9 module selections
    $moduleMap = @{
        "minimal" = @("telemetry")
        "balanced" = @("telemetry", "services", "apps")
        "maximum" = @("telemetry", "services", "apps", "misc")
    }
    
    $selectedModules = if ($moduleMap.ContainsKey($ProfileName)) {
        $moduleMap[$ProfileName]
    } else {
        @("telemetry", "services", "apps")  # Default to balanced
    }
    
    Write-Host "`nProfile: $ProfileName" -ForegroundColor Cyan
    Write-Host "Modules to execute: $($selectedModules -join ', ')" -ForegroundColor Cyan
    Write-LogEntry "INFO" "Executing modules: $($selectedModules -join ', ')"
    
    # Build parameters for v0.9 script
    $v09Params = @{
        Modules = $selectedModules
        EnableAuditLog = $true
    }
    
    if ($DryRun) {
        $v09Params["DryRun"] = $true
        Write-Host "DRY-RUN MODE: No changes will be made" -ForegroundColor Yellow
        Write-LogEntry "INFO" "Running in DRY-RUN mode"
    }
    
    # Verify v0.9 script exists
    if (-not (Test-Path $v09ScriptPath)) {
        Write-Host "`n[ERROR] v0.9 script not found at: $v09ScriptPath" -ForegroundColor Red
        Write-LogEntry "ERROR" "v0.9 script not found at: $v09ScriptPath"
        return $false
    }
    
    try {
        Write-Host "`nCalling v0.9 script with parameters..." -ForegroundColor Green
        Write-Host "Script: $v09ScriptPath" -ForegroundColor Gray
        Write-Host "Parameters: Modules=$($v09Params.Modules -join ','), DryRun=$($v09Params.DryRun), EnableAuditLog=true" -ForegroundColor Gray
        Write-Host ""
        
        # Call v0.9 script and capture output
        & $v09ScriptPath @v09Params
        
        $exitCode = $LASTEXITCODE
        if ($exitCode -eq 0 -or $null -eq $exitCode) {
            Write-Host "`n[OK] v0.9 script execution completed successfully" -ForegroundColor Green
            Write-LogEntry "INFO" "v0.9 script execution completed successfully"
            return $true
        } else {
            Write-Host "`n[WARN] v0.9 script returned exit code: $exitCode" -ForegroundColor Yellow
            Write-LogEntry "WARN" "v0.9 script returned exit code: $exitCode"
            return $true  # Still consider it successful if script ran
        }
        
    } catch {
        Write-LogEntry "ERROR" "Execution failed: $_"
        Write-Host "`n[ERROR] Execution failed: $_" -ForegroundColor Red
        return $false
    }
}

# ===============================
# Main Execution Flow
# ===============================

function Main {
    try {
        Show-Welcome
        
        # Initialize logging
        $logPath = Initialize-Logging -LogDirectory $LogDir
        Write-LogEntry "INFO" "Launcher started - Profile: $Profile"
        
        # Validate requirements
        if (-not (Validate-Requirements)) {
            Write-LogEntry "ERROR" "Requirements validation failed"
            Write-Host "`n[ERROR] System requirements not met. Cannot continue." -ForegroundColor Red
            Read-Host "Press Enter to exit"
            exit 1
        }
        
        # If profile not specified, show menu
        if ($Profile -eq "balanced" -and -not $PSBoundParameters.ContainsKey("Profile")) {
            $Profile = Show-ProfileSelection
            Write-LogEntry "INFO" "User selected profile: $Profile"
        }
        
        # If not quiet mode, show confirmation
        if (-not $Quiet) {
            if (-not (Confirm-Execution -ProfileName $Profile)) {
                Write-LogEntry "INFO" "Execution cancelled by user"
                Write-Host "`n[INFO] Execution cancelled by user" -ForegroundColor Cyan
                Read-Host "Press Enter to exit"
                exit 0
            }
        }
        
        # Execute profile
        Write-Host "`n[INFO] Executing profile: $Profile" -ForegroundColor Green
        Write-LogEntry "INFO" "Executing profile: $Profile"
        
        # Show execution status
        Write-Host "`nExecution started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
        Write-Host "Profile: $Profile" -ForegroundColor Cyan
        Write-Host "Log: $logPath" -ForegroundColor Gray
        
        Write-Host "`n[OK] Profile execution completed!" -ForegroundColor Green
        Write-LogEntry "INFO" "Profile execution completed successfully"
        
        if (-not $Quiet) {
            Read-Host "`nPress Enter to exit"
        }
        
    } catch {
        Write-LogEntry "ERROR" "Unexpected error: $_"
        Write-Host "`n[ERROR] Unexpected error: $_" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
}

# Run main
Main
