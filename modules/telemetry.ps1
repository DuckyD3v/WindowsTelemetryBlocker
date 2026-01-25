# ============================================================================
# Telemetry Module
# ============================================================================
# Description: Disables Windows telemetry, feedback, advertising ID, and Cortana
# Dependencies: None
# Rollback: Available (telemetry-rollback.ps1)
# ============================================================================

param()
. "$PSScriptRoot/common.ps1"

#region Telemetry Functions
function Disable-Telemetry {
    Write-ModuleLog "Disabling telemetry..."
    try {
        $regPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'
        if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
        Set-RegistryValue $regPath 'AllowTelemetry' 0 'DWord'
        Set-RegistryValue $regPath 'DisableTelemetry' 1 'DWord'
        Write-ModuleLog "Telemetry disabled."
        return $true
    } catch {
        Write-ModuleLog "Error disabling telemetry: $_" 'ERROR'
        return $false
    }
}

function Disable-Feedback {
    Write-ModuleLog "Disabling feedback..."
    try {
        $regPath = 'HKCU:\SOFTWARE\Microsoft\Siuf\Rules'
        if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
        Set-RegistryValue $regPath 'NumberOfSIUFInPeriod' 0 'DWord'
        Set-RegistryValue $regPath 'PeriodInNanoSeconds' 0 'QWord'
        Write-ModuleLog "Feedback disabled."
        return $true
    } catch {
        Write-ModuleLog "Error disabling feedback: $_" 'ERROR'
        return $false
    }
}

function Disable-AdvertisingID {
    Write-ModuleLog "Disabling advertising ID..."
    try {
        $regPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo'
        if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
        Set-RegistryValue $regPath 'Enabled' 0 'DWord'
        Write-ModuleLog "Advertising ID disabled."
        return $true
    } catch {
        Write-ModuleLog "Error disabling advertising ID: $_" 'ERROR'
        return $false
    }
}

function Disable-Cortana {
    Write-ModuleLog "Disabling Cortana..."
    try {
        $regPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'
        if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
        Set-RegistryValue $regPath 'AllowCortana' 0 'DWord'
        Write-ModuleLog "Cortana disabled."
        return $true
    } catch {
        Write-ModuleLog "Error disabling Cortana: $_" 'ERROR'
        return $false
    }
}
#endregion

#region Module Execution
Write-ModuleLog "Starting telemetry module..."
$results = @()
$results += Disable-Telemetry
$results += Disable-Feedback
$results += Disable-AdvertisingID
$results += Disable-Cortana

if ($results -contains $false) {
    Write-ModuleLog "Telemetry module completed with errors." 'ERROR'
    return $false
} else {
    Write-ModuleLog "Telemetry module completed successfully."
    return $true
}
#endregion
