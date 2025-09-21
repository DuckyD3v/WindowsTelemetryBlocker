
# Module: apps.ps1
# Purpose: Removes bloatware and disables unnecessary apps for privacy.
# Used by: windows-telemetry-blocker.ps1

. "$PSScriptRoot/common.ps1"
if (-not $global:dryrun) { $global:dryrun = $false }

param(
    [switch]$RemoveBloatware
)

# Disable Background Apps
try {
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 1 -Type DWord
    Write-Host "✓ Disabled background apps" -ForegroundColor Green
    Write-ModuleLog "Disabled background apps"
} catch {
    Write-Host "✗ Failed to disable background apps: $_" -ForegroundColor Red
    Write-ModuleLog "Failed to disable background apps: $_"
}

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
                Write-Host "✓ Removed app: $bloat" -ForegroundColor Green
                Write-ModuleLog "Removed app: $bloat"
            } catch {
                Write-Host "✗ Failed to remove app: $bloat - $_" -ForegroundColor Red
                Write-ModuleLog "Failed to remove app: $bloat - $_"
            }
        }
    }
}

# Disable Widgets / News / OneDrive auto-launch
try {
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Value 0 -Type DWord
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarMn" -Value 0 -Type DWord
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -Value 0 -Type DWord
    Write-Host "✓ Disabled Widgets/News/OneDrive auto-launch" -ForegroundColor Green
    Write-ModuleLog "Disabled Widgets/News/OneDrive auto-launch"
} catch {
    Write-Host "✗ Failed to disable Widgets/News/OneDrive auto-launch: $_" -ForegroundColor Red
    Write-ModuleLog "Failed to disable Widgets/News/OneDrive auto-launch: $_"
}

# Apps Module
Write-Host "`nRunning Apps Module..." -ForegroundColor Cyan

# List of apps to remove
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

foreach ($app in $appsToRemove) {
    if ($global:dryrun) {
        Write-Host "[DRY-RUN] Would remove app: $app" -ForegroundColor DarkYellow
        Write-ModuleLog "[DRY-RUN] Would remove app: $app"
    } else {
        try {
            Get-AppxPackage -Name $app -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue
            Write-Host "✓ Removed app: $app" -ForegroundColor Green
            Write-ModuleLog "Removed app: $app"
        } catch {
            Write-Host "✗ Failed to remove app: $app - $_" -ForegroundColor Red
            Write-ModuleLog "Failed to remove app: $app - $_"
        }
    }
}

Write-Host "✓ Apps configured" -ForegroundColor Green
Write-ModuleLog "Apps module completed"
return $true