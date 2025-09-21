# Rollback script for services.ps1
# Re-enables previously disabled services (example logic)
$servicesToEnable = @(
    "DiagTrack",
    "dmwappushservice",
    "RemoteRegistry",
    "WSearch",
    "MapsBroker",
    "XblAuthManager",
    "XblGameSave",
    "XboxNetApiSvc",
    "WMPNetworkSvc",
    "Fax",
    "WerSvc"
)
foreach ($service in $servicesToEnable) {
    if (Get-Service $service -ErrorAction SilentlyContinue) {
        try {
            Set-Service $service -StartupType Manual -ErrorAction Stop
            Write-Host "Rollback: Set $service to Manual" -ForegroundColor Yellow
        } catch {
            Write-Host "Rollback: Failed to set $service - $_" -ForegroundColor Red
        }
    }
}
