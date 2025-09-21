function Set-RegistryValue {
    param($Path, $Name, $Value, $Type = "DWord")
    if ($global:dryrun) {
        Write-Host "[DRY-RUN] Would set $Path\$Name = $Value ($Type)" -ForegroundColor DarkYellow
    } else {
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type
    }
}

# Disable Wi-Fi Sense
Set-RegistryValue "HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config" "AutoConnectAllowedOEM" 0

# Turn off Timeline / Activity History
Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "EnableActivityFeed" 0
Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "PublishUserActivities" 0

# Disable cloud clipboard
Set-RegistryValue "HKCU:\SOFTWARE\Microsoft\Clipboard" "EnableClipboardHistory" 0
Set-RegistryValue "HKCU:\SOFTWARE\Microsoft\Clipboard" "EnableCloudClipboard" 0

# Misc Module
Write-Host "`nRunning Misc Module..." -ForegroundColor Cyan

# Disable Windows Tips
$tipsKey = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
if (-not (Test-Path $tipsKey)) {
    if ($global:dryrun) {
        Write-Host "[DRY-RUN] Would create registry key: $tipsKey" -ForegroundColor DarkYellow
    } else {
        New-Item -Path $tipsKey -Force | Out-Null
    }
}
Set-RegistryValue $tipsKey "SubscribedContent-338389Enabled" 0

# Disable Timeline
$timelineKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
if (-not (Test-Path $timelineKey)) {
    if ($global:dryrun) {
        Write-Host "[DRY-RUN] Would create registry key: $timelineKey" -ForegroundColor DarkYellow
    } else {
        New-Item -Path $timelineKey -Force | Out-Null
    }
}
Set-RegistryValue $timelineKey "EnableActivityFeed" 0

# Additional privacy tweaks
Set-RegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" 0
Set-RegistryValue "HKCU:\SOFTWARE\Microsoft\InputPersonalization" "RestrictImplicitTextCollection" 1
Set-RegistryValue "HKCU:\SOFTWARE\Microsoft\InputPersonalization" "RestrictImplicitInkCollection" 1
Set-RegistryValue "HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore" "HarvestContacts" 0

Write-Host "✓ Misc settings configured" -ForegroundColor Green