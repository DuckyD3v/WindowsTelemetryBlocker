# ============================================================================
# Services Module
# ============================================================================
# Description: Disables Windows telemetry and unnecessary services
# Dependencies: telemetry
# Rollback: Available (services-rollback.ps1)
# ============================================================================

param()
. "$PSScriptRoot/common.ps1"

#region Service Configuration
$servicesToDisable = @(
    'DiagTrack',
    'dmwappushservice',
    'WMPNetworkSvc',
    'WerSvc',
    'PcaSvc',
    'XblGameSave',
    'MapsBroker',
    'WSearch'
)
#endregion

#region Service Functions
function Disable-ServiceSafe($serviceName) {
    Write-ModuleLog "Disabling service: $serviceName"
    try {
        $svc = Get-Service -Name $serviceName -ErrorAction Stop
        if ($svc.Status -ne 'Stopped') {
            Stop-Service -Name $serviceName -Force -ErrorAction Stop
        }
        Set-Service -Name $serviceName -StartupType Disabled -ErrorAction Stop
        Write-ModuleLog "$serviceName disabled."
        return $true
    } catch {
        Write-ModuleLog "Error disabling ${serviceName}: $($_)" 'ERROR'
        return $false
    }
}
#endregion

#region Module Execution
Write-ModuleLog "Starting services module..."
$results = @()
foreach ($svc in $servicesToDisable) {
    $results += Disable-ServiceSafe $svc
}

if ($results -contains $false) {
    Write-ModuleLog "Services module completed with errors." 'ERROR'
    return $false
} else {
    Write-ModuleLog "Services module completed successfully."
    return $true
}
#endregion
