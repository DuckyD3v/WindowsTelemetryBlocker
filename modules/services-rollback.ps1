# ============================================================================
# Services Module Rollback
# ============================================================================
# Description: Re-enables previously disabled services
# Module: services.ps1
# ============================================================================

#region Service Configuration
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
#endregion

#region Rollback Execution
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
#endregion
