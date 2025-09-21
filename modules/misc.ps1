
# Module: misc.ps1
# Purpose: Applies miscellaneous privacy and anti-telemetry tweaks.
# Used by: windows-telemetry-blocker.ps1

. "$PSScriptRoot/common.ps1"
if (-not $global:dryrun) { $global:dryrun = $false }

# Disable Wi-Fi Sense
Set-RegistryValue "HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config" "AutoConnectAllowedOEM" 0

# Turn off Timeline / Activity History
Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "EnableActivityFeed" 0
Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "PublishUserActivities" 0

# Disable cloud clipboard
Set-RegistryValue "HKCU:\SOFTWARE\Microsoft\Clipboard" "EnableClipboardHistory" 0
Set-RegistryValue "HKCU:\SOFTWARE\Microsoft\Clipboard" "EnableCloudClipboard" 0

Write-Host "`nRunning Misc Module..." -ForegroundColor Cyan

# Disable Windows Tips
$tipsKey = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
if (-not (Test-Path $tipsKey)) {
    if ($global:dryrun) {
        Write-Host "[DRY-RUN] Would create registry key: $tipsKey" -ForegroundColor DarkYellow
        Write-ModuleLog "[DRY-RUN] Would create registry key: $tipsKey"
    } else {
        New-Item -Path $tipsKey -Force | Out-Null
        Write-ModuleLog "Created registry key: $tipsKey"
    }
}
Set-RegistryValue $tipsKey "SubscribedContent-338389Enabled" 0

# Disable Timeline
$timelineKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
if (-not (Test-Path $timelineKey)) {
    if ($global:dryrun) {
        Write-Host "[DRY-RUN] Would create registry key: $timelineKey" -ForegroundColor DarkYellow
        Write-ModuleLog "[DRY-RUN] Would create registry key: $timelineKey"
    } else {
        New-Item -Path $timelineKey -Force | Out-Null
        Write-ModuleLog "Created registry key: $timelineKey"
    }
}
Set-RegistryValue $timelineKey "EnableActivityFeed" 0

# Additional privacy tweaks
Set-RegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" 0
Set-RegistryValue "HKCU:\SOFTWARE\Microsoft\InputPersonalization" "RestrictImplicitTextCollection" 1
Set-RegistryValue "HKCU:\SOFTWARE\Microsoft\InputPersonalization" "RestrictImplicitInkCollection" 1
Set-RegistryValue "HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore" "HarvestContacts" 0

Write-Host "✓ Misc settings configured" -ForegroundColor Green
Write-ModuleLog "Misc module completed"
return $true