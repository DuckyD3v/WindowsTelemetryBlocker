# ===============================
# v1.0 Launcher
# Entry Point for Configuration & Execution
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

╔════════════════════════════════════════════════════╗
║   Windows Telemetry Blocker - v1.0 Launcher       ║
║   Advanced Privacy & Control System                ║
╚════════════════════════════════════════════════════╝

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
        
        Write-Host "▶ $($req.Name)" -ForegroundColor White
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
   └─ Disables telemetry services only
      Safest option, minimal system impact
      
2. Balanced (RECOMMENDED)
   └─ Disables telemetry + removes telemetry apps
      Good balance of privacy and stability
      
3. Maximum
   └─ Removes all telemetry-related apps and services
      Most aggressive option, highest privacy
      
4. Custom
   └─ Define your own app/service removals
      
5. View Details
   └─ See detailed information about each profile

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
  • Recommended for: Users who want basic telemetry protection
  • Services disabled: 4 (DiagTrack, dmwappushservice, dmwappushservice, etc.)
  • Apps removed: 0
  • System impact: Low
  • Recovery difficulty: Very easy

BALANCED (RECOMMENDED):
  • Recommended for: Most users
  • Services disabled: 9 (All telemetry services)
  • Apps removed: 5-7 (Cortana, Widgets, etc.)
  • System impact: Moderate
  • Recovery difficulty: Easy - use rollback scripts

MAXIMUM:
  • Recommended for: Privacy-conscious users
  • Services disabled: 9
  • Apps removed: 15-20 (Including entertainment/ads apps)
  • System impact: High
  • Recovery difficulty: Moderate - some manual steps may be needed

CUSTOM:
  • Recommended for: Advanced users
  • Services/Apps: You choose exactly what to remove
  • System impact: Depends on your choices
  • Recovery difficulty: You control it

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
   └─ Run the selected profile immediately
   
2. Dry Run
   └─ Show what would be done without making changes
   
3. Schedule Execution
   └─ Schedule this profile to run at a specific time
   
4. Configure Advanced Options
   └─ Set up monitoring, auto-remediation, etc.
   
5. Cancel
   └─ Go back without executing

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
    Write-Host "⚠ WARNING: This operation will modify system settings!" -ForegroundColor Yellow
    Write-Host @"

Profile: $ProfileName
  • Your system will be modified
  • A restore point will be created
  • Registry backups will be saved
  • You can rollback using provided scripts

Are you sure you want to continue?
(Type 'yes' to confirm, anything else to cancel)
"@
    
    $confirm = Read-Host "Proceed?"
    return ($confirm -eq "yes")
}

function Execute-Profile {
    <#
    .SYNOPSIS
    Execute the selected profile
    #>
    param(
        [parameter(Mandatory)]
        [string]$ProfileName
    )
    
    Write-Host "`n=== Starting Execution ===" -ForegroundColor Magenta
    Write-LogEntry "INFO" "Starting execution with profile: $ProfileName"
    
    $params = @{
        ProfileName = $ProfileName
        DryRun = $DryRun
        Quiet = $Quiet
    }
    
    if (-not [string]::IsNullOrEmpty($LogDir)) {
        $params.LogDir = $LogDir
    }
    
    try {
        & $integrationPath @params
    } catch {
        Write-LogEntry "ERROR" "Execution failed: $_"
        Write-Host "`n[ERROR] Execution failed: $_" -ForegroundColor Red
        return $false
    }
    
    return $true
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
        
        Write-Host "`n[OK] v1.0 Launcher initialized successfully!" -ForegroundColor Green
        Write-Host "`n[INFO] Profile: $Profile" -ForegroundColor Cyan
        if ($Quiet) {
            Write-Host "[INFO] Running in quiet mode" -ForegroundColor Cyan
        }
        Write-Host "[INFO] Log file: $logPath" -ForegroundColor Cyan
        
        Write-Host "`n[OK] Launcher is operational and ready!" -ForegroundColor Green
        
    } catch {
        Write-Host "`n[ERROR] Unexpected error: $_" -ForegroundColor Red
        exit 1
    }
}

# Run main
Main
