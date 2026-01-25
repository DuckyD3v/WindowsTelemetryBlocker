$files = @(
    'e:\Github\WindowsTelementeryBlocker\v1.0\test\bug-fixes.ps1',
    'e:\Github\WindowsTelementeryBlocker\v1.0\scheduler\task-scheduler.ps1',
    'e:\Github\WindowsTelementeryBlocker\v1.0\scheduler\scheduler-ui.ps1',
    'e:\Github\WindowsTelementeryBlocker\v1.0\monitor\service-monitor.ps1',
    'e:\Github\WindowsTelementeryBlocker\v1.0\monitor\registry-monitor.ps1',
    'e:\Github\WindowsTelementeryBlocker\v1.0\monitor\monitoring-dashboard.ps1',
    'e:\Github\WindowsTelementeryBlocker\v1.0\gui\theme-manager.ps1',
    'e:\Github\WindowsTelementeryBlocker\v1.0\gui\form-controls.ps1',
    'e:\Github\WindowsTelemetryBlocker\v1.0\gui\event-handlers.ps1',
    'e:\Github\WindowsTelementeryBlocker\v1.0\gui\data-binding.ps1',
    'e:\Github\WindowsTelementeryBlocker\v1.0\gui\advanced-filtering.ps1'
)

foreach ($file in $files) {
    $content = Get-Content -Path $file -Raw
    $content = $content -replace '(?s)Export-ModuleMember.*?\)', ''
    Set-Content -Path $file -Value $content -Encoding UTF8
    Write-Host "Cleaned: $file"
}
