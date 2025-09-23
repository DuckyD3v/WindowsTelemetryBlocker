<# misc.ps1 - Miscellaneous privacy tweaks #>
param()
. "$PSScriptRoot/common.ps1"

function Disable-CEIP {
    Write-ModuleLog "Disabling Customer Experience Improvement Program (CEIP)..."
    try {
        $regPath = 'HKLM:\SOFTWARE\Microsoft\SQMClient\Windows'
        if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
        Set-RegistryValue $regPath 'CEIPEnable' 0 'DWord'
        Write-ModuleLog "CEIP disabled."
        return $true
    } catch {
        Write-ModuleLog "Error disabling CEIP: $_" 'ERROR'
        return $false
    }
}

function Disable-ErrorReporting {
    Write-ModuleLog "Disabling Windows Error Reporting..."
    try {
        $regPath = 'HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting'
        if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
        Set-RegistryValue $regPath 'Disabled' 1 'DWord'
        Write-ModuleLog "Error Reporting disabled."
        return $true
    } catch {
        Write-ModuleLog "Error disabling Error Reporting: $_" 'ERROR'
        return $false
    }
}

Write-ModuleLog "Starting misc module..."
$results = @()
$results += Disable-CEIP
$results += Disable-ErrorReporting
if ($results -contains $false) {
    Write-ModuleLog "Misc module completed with errors." 'ERROR'
    return $false
} else {
    Write-ModuleLog "Misc module completed successfully."
    return $true
}