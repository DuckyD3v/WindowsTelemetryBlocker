# ============================================================================
# Common Module Functions
# ============================================================================
# Description: Shared utility functions used by all telemetry blocker modules
# ============================================================================

#region Logging Functions
# Enhanced Write-ModuleLog: robust fallback, cross-env
function Write-ModuleLog {
    param([string]$msg)
    try {
        if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
            Write-Log $msg
        } else {
            $logFile = Join-Path $PSScriptRoot '..' 'telemetry-blocker.log'
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            "$timestamp $msg" | Out-File -FilePath $logFile -Append -Encoding utf8
        }
    } catch {
        Write-Host "[LOG ERROR] $msg" -ForegroundColor Red
    }
}
#endregion

#region Registry Functions
# Enhanced Set-RegistryValue: supports more types, error handling, cross-env
function Set-RegistryValue {
    param(
        [Parameter(Mandatory)]$Path,
        [Parameter(Mandatory)]$Name,
        [Parameter(Mandatory)]$Value,
        [ValidateSet("DWord","QWord","String","ExpandString","Binary","MultiString")]
        [string]$Type = "DWord"
    )
    if ($global:dryrun) {
        Write-Host "[DRY-RUN] Would set $Path\$Name = $Value ($Type)" -ForegroundColor DarkYellow
        Write-ModuleLog "[DRY-RUN] Would set $($Path)\$($Name) = $Value ($Type)"
    } else {
        try {
            if ($Type -eq "DWord" -or $Type -eq "QWord") {
                Set-ItemProperty -Path $Path -Name $Name -Value ([Convert]::ToInt64($Value)) -Type $Type
            } elseif ($Type -eq "String" -or $Type -eq "ExpandString") {
                Set-ItemProperty -Path $Path -Name $Name -Value "$Value" -Type $Type
            } elseif ($Type -eq "Binary") {
                Set-ItemProperty -Path $Path -Name $Name -Value ([byte[]]$Value) -Type $Type
            } elseif ($Type -eq "MultiString") {
                Set-ItemProperty -Path $Path -Name $Name -Value ([string[]]$Value) -Type $Type
            } else {
                Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type
            }
            Write-ModuleLog "Set $($Path)\$($Name) = $Value ($Type)"
        } catch {
            Write-Host "[ERROR] Failed to set $($Path)\$($Name): $_" -ForegroundColor Red
            Write-ModuleLog "[ERROR] Failed to set $($Path)\$($Name): $_"
        }
    }
}
#endregion
