# Common functions for all modules
function Write-ModuleLog {
    param([string]$msg)
    if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
        Write-Log $msg
    }
}

function Set-RegistryValue {
    param($Path, $Name, $Value, $Type = "DWord")
    if ($global:dryrun) {
        Write-Host "[DRY-RUN] Would set $Path\$Name = $Value ($Type)" -ForegroundColor DarkYellow
        Write-ModuleLog "[DRY-RUN] Would set $Path\$Name = $Value ($Type)"
    } else {
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type
        Write-ModuleLog "Set $Path\$Name = $Value ($Type)"
    }
}
