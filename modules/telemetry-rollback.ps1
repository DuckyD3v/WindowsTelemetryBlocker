# Rollback script for telemetry.ps1
# Restores telemetry registry settings to default (example logic)
$telemetryKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
if (Test-Path $telemetryKey) {
    Remove-ItemProperty -Path $telemetryKey -Name "AllowTelemetry" -ErrorAction SilentlyContinue
    Write-Host "Rollback: Removed AllowTelemetry registry value" -ForegroundColor Yellow
}
