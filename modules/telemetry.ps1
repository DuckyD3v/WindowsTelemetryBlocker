# Module: telemetry.ps1
# Purpose: Disables Windows telemetry and related privacy-invading features.
# Used by: rls-script.ps1

. "$PSScriptRoot/common.ps1"
if (-not $global:dryrun) { $global:dryrun = $false }

# Disable Windows Telemetry
$telemetryKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
if (-not (Test-Path $telemetryKey)) {
    if ($global:dryrun) {
        Write-Host "[DRY-RUN] Would create registry key: $telemetryKey" -ForegroundColor DarkYellow
        Write-ModuleLog "[DRY-RUN] Would create registry key: $telemetryKey"
    } else {
        New-Item -Path $telemetryKey -Force | Out-Null
        Write-ModuleLog "Created registry key: $telemetryKey"
    }
}
Set-RegistryValue $telemetryKey "AllowTelemetry" 0
 
$insiderKey = "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\System\AllowExperimentation"
if (-not (Test-Path $insiderKey)) {
    if ($global:dryrun) {
        Write-Host "[DRY-RUN] Would create registry key: $insiderKey" -ForegroundColor DarkYellow
        Write-ModuleLog "[DRY-RUN] Would create registry key: $insiderKey"
    } else {
        New-Item -Path $insiderKey -Force | Out-Null
        Write-ModuleLog "Created registry key: $insiderKey"
    }

Set-RegistryValue $insiderKey "value" 0
Write-ModuleLog "Telemetry settings configured"

# Turn off Feedback prompts
try {
    Set-RegistryValue "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" "NumberOfSIUFInPeriod" 0
    Write-Host "✓ Disabled Feedback prompts" -ForegroundColor Green
    Write-ModuleLog "Disabled Feedback prompts"
}
catch {
    Write-Host "✗ Failed to disable Feedback prompts: $_" -ForegroundColor Red
    Write-ModuleLog "Failed to disable Feedback prompts: $_"
    throw
}

# Disable Advertising ID
try {
    Set-RegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" 0
    Write-Host "✓ Disabled Advertising ID" -ForegroundColor Green
    Write-ModuleLog "Disabled Advertising ID"
}
catch {
    Write-Host "✗ Failed to disable Advertising ID: $_" -ForegroundColor Red
    Write-ModuleLog "Failed to disable Advertising ID: $_"
    throw
}

# Disable Cortana
try {
    Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCortana" 0
    Write-Host "✓ Disabled Cortana" -ForegroundColor Green
    Write-ModuleLog "Disabled Cortana"
}
catch {
    Write-Host "✗ Failed to disable Cortana: $_" -ForegroundColor Red
    Write-ModuleLog "Failed to disable Cortana: $_"
    throw
}

Write-ModuleLog "Telemetry module completed"
return $true