# ============================================================================
# Apps Module
# ============================================================================
# Description: Removes bloatware and disables unnecessary apps for privacy
# Dependencies: None
# Rollback: Manual (app removals are not easily reversible)
# ============================================================================

param(
    [switch]$RemoveBloatware
)

. "$PSScriptRoot/common.ps1"
if (-not $global:dryrun) { $global:dryrun = $false }

#region App Configuration
$appsToRemove = @(
    "Microsoft.3DBuilder",
    "Microsoft.BingWeather",
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.People",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.SkypeApp",
    "Microsoft.XboxApp",
    "Microsoft.XboxGameOverlay",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.XboxSpeechToTextOverlay",
    "Microsoft.YourPhone",
    "Microsoft.MicrosoftStickyNotes",
    "Microsoft.OneConnect",
    "Microsoft.MSPaint",
    "Microsoft.Microsoft3DViewer",
    "Microsoft.MixedReality.Portal"
)
#endregion

#region Background Apps Configuration
# Disable Background Apps
try {
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 1 -Type DWord
    Write-Host "Disabled background apps" -ForegroundColor Green
    Write-ModuleLog "Disabled background apps"
} catch {
    Write-Host "Failed to disable background apps: $_" -ForegroundColor Red
    Write-ModuleLog "Failed to disable background apps: $_"
}
#endregion

#region Widgets and Taskbar Configuration
# Disable Widgets / News / OneDrive auto-launch
try {
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Value 0 -Type DWord
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarMn" -Value 0 -Type DWord
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -Value 0 -Type DWord
    Write-Host "Disabled Widgets/News/OneDrive auto-launch" -ForegroundColor Green
    Write-ModuleLog "Disabled Widgets/News/OneDrive auto-launch"
} catch {
    Write-Host "Failed to disable Widgets/News/OneDrive auto-launch: $_" -ForegroundColor Red
    Write-ModuleLog "Failed to disable Widgets/News/OneDrive auto-launch: $_"
}
#endregion

#region Optional Bloatware Removal
# Optionally remove preinstalled bloatware
if ($RemoveBloatware) {
    $bloatwareApps = @(
        "Microsoft.WindowsStore",
        "Microsoft.Office.OneNote"
        # Add more bloatware removal commands as needed
    )
    foreach ($bloat in $bloatwareApps) {
        if ($global:dryrun) {
            Write-Host "[DRY-RUN] Would remove app: $bloat" -ForegroundColor DarkYellow
            Write-ModuleLog "[DRY-RUN] Would remove app: $bloat"
        } else {
            try {
                Get-AppxPackage -Name $bloat | Remove-AppxPackage
                Write-Host "Removed app: $bloat" -ForegroundColor Green
                Write-ModuleLog "Removed app: $bloat"
            } catch {
                Write-Host "Failed to remove app: $bloat - $_" -ForegroundColor Red
                Write-ModuleLog "Failed to remove app: $bloat - $_"
            }
        }
    }
}
#endregion

#region Module Execution
Write-Host "`nRunning Apps Module..." -ForegroundColor Cyan

# Track removed apps for potential recovery
$removedApps = @()

foreach ($app in $appsToRemove) {
    if ($global:dryrun) {
        Write-Host "[DRY-RUN] Would remove app: $app" -ForegroundColor DarkYellow
        Write-ModuleLog "[DRY-RUN] Would remove app: $app"
    } else {
        try {
            # Check for interrupt signal
            if ($global:CriticalOperationInProgress -and -not ($global:CriticalOperationName -like "*app*")) {
                throw "Script interrupted by user during app removal"
            }
            
            Get-AppxPackage -Name $app -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue
            $removedApps += $app
            Write-Host "Removed app: $app" -ForegroundColor Green
            Write-ModuleLog "Removed app: $app"
        } catch {
            Write-Host "Failed to remove app: $app - $_" -ForegroundColor Red
            Write-ModuleLog "Failed to remove app: $app - $_"
        }
    }
}

# Store removed apps in global state for recovery
$global:PartialExecutionState["RemovedApps"] = $removedApps

Write-Host "Apps configured ($($removedApps.Count) apps removed)" -ForegroundColor Green
Write-ModuleLog "Apps module completed ($($removedApps.Count) apps removed)"
return $true
#endregion
