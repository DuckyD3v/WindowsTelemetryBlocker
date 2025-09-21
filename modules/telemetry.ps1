function Set-RegistryValue {
    param($Path, $Name, $Value, $Type = "DWord")
    if ($global:dryrun) {
        Write-Host "[DRY-RUN] Would set $Path\$Name = $Value ($Type)" -ForegroundColor DarkYellow
    } else {
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type
    }
}

# Telemetry Module
Write-Host "`nRunning Telemetry Module..." -ForegroundColor Cyan

# Disable Windows Telemetry
$telemetryKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
if (-not (Test-Path $telemetryKey)) {
    if ($global:dryrun) {
        Write-Host "[DRY-RUN] Would create registry key: $telemetryKey" -ForegroundColor DarkYellow
    } else {
        New-Item -Path $telemetryKey -Force | Out-Null
    }
}
Set-RegistryValue $telemetryKey "AllowTelemetry" 0

# Disable Windows Insider Program
$insiderKey = "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\System\AllowExperimentation"
if (-not (Test-Path $insiderKey)) {
    if ($global:dryrun) {
        Write-Host "[DRY-RUN] Would create registry key: $insiderKey" -ForegroundColor DarkYellow
    } else {
        New-Item -Path $insiderKey -Force | Out-Null
    }
}
Set-RegistryValue $insiderKey "value" 0

Write-Host "✓ Telemetry settings configured" -ForegroundColor Green

# Turn off Feedback prompts
try {
    Set-RegistryValue "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" "NumberOfSIUFInPeriod" 0
    Write-Host "✓ Disabled Feedback prompts" -ForegroundColor Green
}
catch {
    Write-Host "✗ Failed to disable Feedback prompts: $_" -ForegroundColor Red
    throw
}

# Disable Advertising ID
try {
    Set-RegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" 0
    Write-Host "✓ Disabled Advertising ID" -ForegroundColor Green
}
catch {
    Write-Host "✗ Failed to disable Advertising ID: $_" -ForegroundColor Red
    throw
}

# Disable Cortana
try {
    Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCortana" 0
    Write-Host "✓ Disabled Cortana" -ForegroundColor Green
}
catch {
    Write-Host "✗ Failed to disable Cortana: $_" -ForegroundColor Red
    throw
}