# Module: services.ps1
# Purpose: Disables telemetry and unnecessary services for privacy.
# Used by: windows-telemetry-blocker.ps1

. "$PSScriptRoot/common.ps1"
if (-not $global:dryrun) { $global:dryrun = $false }

Write-Host "`nRunning Services Module..." -ForegroundColor Cyan

# List of services to disable
$servicesToDisable = @(
    "DiagTrack",           # Connected User Experiences and Telemetry
    "dmwappushservice",    # WAP Push Message Routing Service
    "RemoteRegistry",      # Remote Registry
    "WSearch",             # Windows Search
    "MapsBroker",          # Downloaded Maps Manager
    "XblAuthManager",      # Xbox Live Auth Manager
    "XblGameSave",         # Xbox Live Game Save
    "XboxNetApiSvc",       # Xbox Live Networking Service
    "WMPNetworkSvc",       # Windows Media Player Network Sharing
    "Fax",                 # Fax Service
    "WerSvc"               # Windows Error Reporting Service
)

foreach ($service in $servicesToDisable) {
    if (Get-Service $service -ErrorAction SilentlyContinue) {
        if ($global:dryrun) {
            Write-Host "[DRY-RUN] Would disable service: $service" -ForegroundColor DarkYellow
            Write-ModuleLog "[DRY-RUN] Would disable service: $service"
        } else {
            try {
                Stop-Service $service -Force -ErrorAction Stop
                Set-Service $service -StartupType Disabled -ErrorAction Stop
                Write-Host "✓ Disabled service: $service" -ForegroundColor Green
                Write-ModuleLog "Disabled service: $service"
            } catch {
                Write-Host "✗ Failed to disable service: $service - $_" -ForegroundColor Red
                Write-ModuleLog "Failed to disable service: $service - $_"
            }
        }
    }
}

Write-Host "✓ Services configured" -ForegroundColor Green
Write-ModuleLog "Services module completed"
return $true