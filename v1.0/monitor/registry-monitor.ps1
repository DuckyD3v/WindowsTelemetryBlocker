# Phase 5: Registry Monitoring Module
# Real-time registry change detection and tracking
# Monitors telemetry-related registry keys for unauthorized changes

# ============================================================================
# REGISTRY PATHS TO MONITOR
# ============================================================================

$script:TelemetryRegistryPaths = @(
    'HKLM:\SYSTEM\CurrentControlSet\Services\DiagTrack',
    'HKLM:\SYSTEM\CurrentControlSet\Services\dmwappushservice',
    'HKLM:\SYSTEM\CurrentControlSet\Services\OneSyncSvc',
    'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection',
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy',
    'HKCU:\SOFTWARE\Microsoft\Simonyan',
    'HKCU:\SOFTWARE\Microsoft\InputPersonalization',
    'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options'
)

# ============================================================================
# REGISTRY MONITORING CLASSES AND TYPES
# ============================================================================

class RegistryChangeEvent {
    [string]$Timestamp
    [string]$RegistryPath
    [string]$ValueName
    [string]$OldValue
    [string]$NewValue
    [string]$ChangeType  # Modified, Added, Deleted
    [bool]$IsSuspicious
    [string]$Severity    # Low, Medium, High, Critical
    
    RegistryChangeEvent([string]$Path, [string]$Name, [object]$Old, [object]$New, [string]$Type) {
        $this.Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        $this.RegistryPath = $Path
        $this.ValueName = $Name
        $this.OldValue = $Old
        $this.NewValue = $New
        $this.ChangeType = $Type
        $this.IsSuspicious = $false
        $this.Severity = "Low"
    }
}

# ============================================================================
# BASELINE CREATION AND MANAGEMENT
# ============================================================================

<#
.SYNOPSIS
    Creates a baseline snapshot of monitored registry keys
.PARAMETER OutputPath
    Path to save baseline JSON file
.OUTPUTS
    [bool] $true if successful, $false otherwise
#>
function New-RegistryBaseline {
    param(
        [string]$OutputPath = (Join-Path $env:APPDATA "WindowsTelemetryBlocker\registry-baseline.json")
    )
    
    try {
        $baseline = @{}
        
        Write-LogMessage -Message "Creating registry baseline..." -Level "INFO"
        
        foreach ($regPath in $script:TelemetryRegistryPaths) {
            if (Test-Path $regPath -ErrorAction SilentlyContinue) {
                $keys = Get-Item $regPath -ErrorAction SilentlyContinue
                if ($keys) {
                    $values = @{}
                    foreach ($prop in $keys.Property) {
                        try {
                            $values[$prop] = $keys.GetValue($prop)
                        }
                        catch {
                            # Skip properties that can't be read
                        }
                    }
                    $baseline[$regPath] = $values
                }
            }
        }
        
        # Save baseline
        $baselineDir = Split-Path $OutputPath
        if (-not (Test-Path $baselineDir)) {
            New-Item -ItemType Directory -Path $baselineDir -Force | Out-Null
        }
        
        $baseline | ConvertTo-Json -Depth 5 | Set-Content -Path $OutputPath -Force
        Write-LogMessage -Message "Registry baseline created at: $OutputPath" -Level "INFO"
        
        return $true
    }
    catch {
        Write-LogMessage -Message "Error creating registry baseline: $_" -Level "ERROR"
        return $false
    }
}

<#
.SYNOPSIS
    Loads registry baseline from file
.PARAMETER BaselinePath
    Path to baseline JSON file
.OUTPUTS
    [PSCustomObject] Baseline object
#>
function Get-RegistryBaseline {
    param(
        [string]$BaselinePath = (Join-Path $env:APPDATA "WindowsTelemetryBlocker\registry-baseline.json")
    )
    
    try {
        if (Test-Path $BaselinePath) {
            $baseline = Get-Content $BaselinePath -Raw | ConvertFrom-Json
            return $baseline
        }
        else {
            Write-LogMessage -Message "Baseline file not found at: $BaselinePath" -Level "WARNING"
            return $null
        }
    }
    catch {
        Write-LogMessage -Message "Error loading registry baseline: $_" -Level "ERROR"
        return $null
    }
}

# ============================================================================
# REGISTRY CHANGE DETECTION
# ============================================================================

<#
.SYNOPSIS
    Compares current registry state with baseline to detect changes
.PARAMETER Baseline
    Baseline object from Get-RegistryBaseline
.OUTPUTS
    [RegistryChangeEvent[]] Array of detected changes
#>
function Find-RegistryChanges {
    param(
        [PSCustomObject]$Baseline
    )
    
    try {
        $changes = @()
        
        if ($null -eq $Baseline) {
            return $changes
        }
        
        # Check baseline paths for modifications
        foreach ($regPath in $Baseline.PSObject.Properties) {
            $path = $regPath.Name
            $baselineValues = $regPath.Value
            
            if (Test-Path $path -ErrorAction SilentlyContinue) {
                $currentKey = Get-Item $path -ErrorAction SilentlyContinue
                
                if ($currentKey) {
                    # Check for modified/deleted values
                    foreach ($valueName in $baselineValues.PSObject.Properties) {
                        $name = $valueName.Name
                        $oldValue = $valueName.Value
                        
                        try {
                            $currentValue = $currentKey.GetValue($name, $null)
                            
                            if ($null -eq $currentValue) {
                                # Value was deleted
                                $change = [RegistryChangeEvent]::new($path, $name, $oldValue, $null, "Deleted")
                                $change.IsSuspicious = $true
                                $change.Severity = "High"
                                $changes += $change
                            }
                            elseif ($currentValue -ne $oldValue) {
                                # Value was modified
                                $change = [RegistryChangeEvent]::new($path, $name, $oldValue, $currentValue, "Modified")
                                $change.IsSuspicious = Test-SuspiciousChange -OldValue $oldValue -NewValue $currentValue
                                $change.Severity = if ($change.IsSuspicious) { "High" } else { "Medium" }
                                $changes += $change
                            }
                        }
                        catch {
                            # Skip values that can't be accessed
                        }
                    }
                    
                    # Check for new values
                    foreach ($currentProp in $currentKey.Property) {
                        if (-not $baselineValues.PSObject.Properties[$currentProp]) {
                            try {
                                $newValue = $currentKey.GetValue($currentProp)
                                $change = [RegistryChangeEvent]::new($path, $currentProp, $null, $newValue, "Added")
                                $change.IsSuspicious = $true
                                $change.Severity = "High"
                                $changes += $change
                            }
                            catch {
                                # Skip
                            }
                        }
                    }
                }
            }
            else {
                # Registry path was deleted
                $change = [RegistryChangeEvent]::new($path, "Path", "Exists", "Deleted", "Deleted")
                $change.IsSuspicious = $true
                $change.Severity = "Critical"
                $changes += $change
            }
        }
        
        return $changes
    }
    catch {
        Write-LogMessage -Message "Error finding registry changes: $_" -Level "ERROR"
        return @()
    }
}

<#
.SYNOPSIS
    Analyzes a registry change to determine if it's suspicious
.PARAMETER OldValue
    Previous registry value
.PARAMETER NewValue
    New registry value
.OUTPUTS
    [bool] $true if change appears suspicious, $false otherwise
#>
function Test-SuspiciousChange {
    param(
        [object]$OldValue,
        [object]$NewValue
    )
    
    # Common suspicious patterns
    $suspiciousPatterns = @(
        'powershell',
        'cmd.exe',
        'wscript',
        'rundll32',
        'regsvr32',
        'msiexec',
        'certutil',
        'bitsadmin'
    )
    
    $newValueStr = $NewValue.ToString().ToLower()
    
    foreach ($pattern in $suspiciousPatterns) {
        if ($newValueStr.Contains($pattern)) {
            return $true
        }
    }
    
    return $false
}

# ============================================================================
# REGISTRY CHANGE HISTORY
# ============================================================================

<#
.SYNOPSIS
    Saves detected registry changes to history file
.PARAMETER Changes
    Array of RegistryChangeEvent objects
.PARAMETER HistoryPath
    Path to save history JSON file
#>
function Save-RegistryChangeHistory {
    param(
        [RegistryChangeEvent[]]$Changes,
        [string]$HistoryPath = (Join-Path $env:APPDATA "WindowsTelemetryBlocker\registry-history.json")
    )
    
    try {
        $historyDir = Split-Path $HistoryPath
        if (-not (Test-Path $historyDir)) {
            New-Item -ItemType Directory -Path $historyDir -Force | Out-Null
        }
        
        # Load existing history
        $history = @()
        if (Test-Path $HistoryPath) {
            $history = @(Get-Content $HistoryPath -Raw | ConvertFrom-Json)
        }
        
        # Add new changes
        foreach ($change in $Changes) {
            $history += @{
                Timestamp = $change.Timestamp
                RegistryPath = $change.RegistryPath
                ValueName = $change.ValueName
                OldValue = $change.OldValue
                NewValue = $change.NewValue
                ChangeType = $change.ChangeType
                IsSuspicious = $change.IsSuspicious
                Severity = $change.Severity
            }
        }
        
        # Keep last 1000 entries
        if ($history.Count -gt 1000) {
            $history = $history[-1000..-1]
        }
        
        $history | ConvertTo-Json -Depth 5 | Set-Content -Path $HistoryPath -Force
    }
    catch {
        Write-LogMessage -Message "Error saving registry change history: $_" -Level "ERROR"
    }
}

<#
.SYNOPSIS
    Retrieves registry change history
.PARAMETER HistoryPath
    Path to history JSON file
.PARAMETER MaxEntries
    Maximum number of entries to return (default: 100)
.OUTPUTS
    [PSCustomObject[]] Array of historical changes
#>
function Get-RegistryChangeHistory {
    param(
        [string]$HistoryPath = (Join-Path $env:APPDATA "WindowsTelemetryBlocker\registry-history.json"),
        [int]$MaxEntries = 100
    )
    
    try {
        if (Test-Path $HistoryPath) {
            $history = @(Get-Content $HistoryPath -Raw | ConvertFrom-Json)
            return $history | Select-Object -Last $MaxEntries | Sort-Object -Property Timestamp -Descending
        }
        return @()
    }
    catch {
        Write-LogMessage -Message "Error retrieving registry change history: $_" -Level "ERROR"
        return @()
    }
}

# ============================================================================
# REGISTRY REPAIR FUNCTIONS
# ============================================================================

<#
.SYNOPSIS
    Restores registry values from baseline
.PARAMETER Changes
    Array of RegistryChangeEvent objects to restore
.PARAMETER DryRun
    If true, shows what would be restored without making changes
.OUTPUTS
    [bool] $true if successful, $false otherwise
#>
function Restore-RegistryFromBaseline {
    param(
        [RegistryChangeEvent[]]$Changes,
        [bool]$DryRun = $true
    )
    
    try {
        if ($DryRun) {
            Write-LogMessage -Message "DRY RUN: Would restore $($Changes.Count) registry changes" -Level "INFO"
            foreach ($change in $Changes) {
                Write-LogMessage -Message "  - $($change.RegistryPath)\$($change.ValueName) = $($change.OldValue)" -Level "INFO"
            }
            return $true
        }
        
        $restored = 0
        foreach ($change in $Changes) {
            try {
                if ($change.ChangeType -eq "Deleted") {
                    # Restore deleted value
                    Set-ItemProperty -Path $change.RegistryPath -Name $change.ValueName -Value $change.OldValue -Force
                    $restored++
                }
                elseif ($change.ChangeType -eq "Modified") {
                    # Restore modified value
                    Set-ItemProperty -Path $change.RegistryPath -Name $change.ValueName -Value $change.OldValue -Force
                    $restored++
                }
                elseif ($change.ChangeType -eq "Added") {
                    # Remove added value
                    Remove-ItemProperty -Path $change.RegistryPath -Name $change.ValueName -Force -ErrorAction SilentlyContinue
                    $restored++
                }
            }
            catch {
                Write-LogMessage -Message "Error restoring $($change.RegistryPath)\$($change.ValueName): $_" -Level "WARNING"
            }
        }
        
        Write-LogMessage -Message "Registry restoration complete: $restored/$($Changes.Count) changes restored" -Level "INFO"
        return $true
    }
    catch {
        Write-LogMessage -Message "Error restoring registry: $_" -Level "ERROR"
        return $false
    }
}

# ============================================================================
# REGISTRY STATISTICS
# ============================================================================

<#
.SYNOPSIS
    Calculates statistics about registry monitoring
.OUTPUTS
    [PSCustomObject] Statistics object
#>
function Get-RegistryMonitoringStatistics {
    try {
        $history = Get-RegistryChangeHistory -MaxEntries 10000
        
        $suspiciousCount = ($history | Where-Object { $_.IsSuspicious }).Count
        $highSeverityCount = ($history | Where-Object { $_.Severity -eq "High" -or $_.Severity -eq "Critical" }).Count
        $uniquePaths = ($history | Select-Object -ExpandProperty RegistryPath -Unique).Count
        
        return [PSCustomObject]@{
            TotalChanges = $history.Count
            SuspiciousChanges = $suspiciousCount
            HighSeverityChanges = $highSeverityCount
            UniqueRegistryPaths = $uniquePaths
            LastChangeTime = if ($history) { $history[0].Timestamp } else { "Never" }
            CriticalChanges = ($history | Where-Object { $_.Severity -eq "Critical" }).Count
        }
    }
    catch {
        Write-LogMessage -Message "Error getting registry statistics: $_" -Level "ERROR"
        return $null
    }
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Write-LogMessage {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $(
        switch ($Level) {
            'ERROR' { 'Red' }
            'WARNING' { 'Yellow' }
            'INFO' { 'Green' }
            'DEBUG' { 'Gray' }
            default { 'White' }
        }
    )
}

# ============================================================================
# EXPORTS
# ============================================================================

Export-ModuleMember -Function @(
    'New-RegistryBaseline',
    'Get-RegistryBaseline',
    'Find-RegistryChanges',
    'Save-RegistryChangeHistory',
    'Get-RegistryChangeHistory',
    'Restore-RegistryFromBaseline',
    'Get-RegistryMonitoringStatistics',
    'Test-SuspiciousChange'
)
