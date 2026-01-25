# ============================================================================
# Miscellaneous Module Rollback
# ============================================================================
# Description: Restores registry settings to default
# Module: misc.ps1
# ============================================================================

#region Rollback Execution
$timelineKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
if (Test-Path $timelineKey) {
    Remove-ItemProperty -Path $timelineKey -Name "EnableActivityFeed" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $timelineKey -Name "PublishUserActivities" -ErrorAction SilentlyContinue
    Write-Host "Rollback: Removed Timeline registry values" -ForegroundColor Yellow
}
#endregion
