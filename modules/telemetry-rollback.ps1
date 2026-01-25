# ============================================================================
# Telemetry Module Rollback
# ============================================================================
# Description: Restores telemetry registry settings to default
# Module: telemetry.ps1
# ============================================================================

#region Rollback Execution
$telemetryKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
if (Test-Path $telemetryKey) {
    Remove-ItemProperty -Path $telemetryKey -Name "AllowTelemetry" -ErrorAction SilentlyContinue
    Write-Host "Rollback: Removed AllowTelemetry registry value" -ForegroundColor Yellow
}
#endregion
