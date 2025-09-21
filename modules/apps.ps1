param(
    [switch]$RemoveBloatware
)

# Disable Background Apps
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 1 -Type DWord

# Optionally remove preinstalled bloatware
if ($RemoveBloatware) {
    # Example: Remove Windows Store apps (adjust as needed)
    Get-AppxPackage -Name "Microsoft.WindowsStore" | Remove-AppxPackage
    Get-AppxPackage -Name "Microsoft.Office.OneNote" | Remove-AppxPackage
    # Add more bloatware removal commands as needed
}

# Disable Widgets / News / OneDrive auto-launch
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Value 0 -Type DWord
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarMn" -Value 0 -Type DWord
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -Value 0 -Type DWord

# Apps Module
Write-Host "`nRunning Apps Module..." -ForegroundColor Cyan

# List of apps to remove
$appsToRemove = @(
    "Microsoft.3DBuilder"
    "Microsoft.BingWeather"
    "Microsoft.GetHelp"
    "Microsoft.Getstarted"
    "Microsoft.WindowsFeedbackHub"
    "Microsoft.ZuneMusic"
    "Microsoft.ZuneVideo"
    "Microsoft.MicrosoftSolitaireCollection"
    "Microsoft.People"
    "Microsoft.MicrosoftOfficeHub"
    "Microsoft.SkypeApp"
    "Microsoft.XboxApp"
    "Microsoft.XboxGameOverlay"
    "Microsoft.XboxGamingOverlay"
    "Microsoft.XboxIdentityProvider"
    "Microsoft.XboxSpeechToTextOverlay"
    "Microsoft.YourPhone"
    "Microsoft.MicrosoftStickyNotes"
    "Microsoft.OneConnect"
    "Microsoft.MSPaint"
    "Microsoft.Microsoft3DViewer"
    "Microsoft.MixedReality.Portal"
)

foreach ($app in $appsToRemove) {
    if ($global:dryrun) {
        Write-Host "[DRY-RUN] Would remove app: $app" -ForegroundColor DarkYellow
    } else {
        Get-AppxPackage -Name $app -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue
        Write-Host "✓ Removed app: $app" -ForegroundColor Green
    }
}

Write-Host "✓ Apps configured" -ForegroundColor Green