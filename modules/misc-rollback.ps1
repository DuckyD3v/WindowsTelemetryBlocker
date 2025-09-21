# Rollback script for misc.ps1
# Restores some registry settings to default (example logic)
$timelineKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
if (Test-Path $timelineKey) {
    Remove-ItemProperty -Path $timelineKey -Name "EnableActivityFeed" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $timelineKey -Name "PublishUserActivities" -ErrorAction SilentlyContinue
    Write-Host "Rollback: Removed Timeline registry values" -ForegroundColor Yellow
}
