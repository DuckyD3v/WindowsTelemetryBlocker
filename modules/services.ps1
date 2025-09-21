# Services Module
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
        } else {
            Stop-Service $service -Force -ErrorAction SilentlyContinue
            Set-Service $service -StartupType Disabled -ErrorAction SilentlyContinue
            Write-Host "✓ Disabled service: $service" -ForegroundColor Green
        }
    }
}

Write-Host "✓ Services configured" -ForegroundColor Green