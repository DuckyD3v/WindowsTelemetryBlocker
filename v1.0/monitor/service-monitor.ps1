# Phase 5: Service Monitoring Module
# Real-time service state tracking and anomaly detection
# Monitors telemetry and system service states for unauthorized changes

# ============================================================================
# MONITORED SERVICES
# ============================================================================

$script:TelemetryServices = @(
    @{ Name = 'DiagTrack'; DisplayName = 'Connected User Experiences and Telemetry'; Category = 'Telemetry' },
    @{ Name = 'dmwappushservice'; DisplayName = 'dmwappushservice'; Category = 'Telemetry' },
    @{ Name = 'OneSyncSvc'; DisplayName = 'Sync Host'; Category = 'Telemetry' },
    @{ Name = 'DoSvc'; DisplayName = 'Delivery Optimization'; Category = 'Telemetry' },
    @{ Name = 'MapsBroker'; DisplayName = 'Maps Broker'; Category = 'Telemetry' },
    @{ Name = 'lfsvc'; DisplayName = 'Location Service'; Category = 'Telemetry' }
)

$script:CriticalServices = @(
    @{ Name = 'winlogon'; DisplayName = 'Winlogon'; Category = 'System' },
    @{ Name = 'svchost'; DisplayName = 'Service Host'; Category = 'System' },
    @{ Name = 'csrss'; DisplayName = 'Client/Server Runtime Subsystem'; Category = 'System' }
)

# ============================================================================
# SERVICE MONITORING CLASSES
# ============================================================================

class ServiceStateChange {
    [string]$Timestamp
    [string]$ServiceName
    [string]$DisplayName
    [string]$OldState
    [string]$NewState
    [int]$OldStartupType
    [int]$NewStartupType
    [bool]$IsAnomalous
    [string]$Severity  # Low, Medium, High, Critical
    [string]$Description
    
    ServiceStateChange([string]$Name, [string]$Display, [string]$OldS, [string]$NewS) {
        $this.Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        $this.ServiceName = $Name
        $this.DisplayName = $Display
        $this.OldState = $OldS
        $this.NewState = $NewS
        $this.IsAnomalous = $false
        $this.Severity = "Low"
    }
}

# ============================================================================
# SERVICE BASELINE FUNCTIONS
# ============================================================================

<#
.SYNOPSIS
    Creates a baseline of service states and startup types
.PARAMETER OutputPath
    Path to save service baseline JSON file
.OUTPUTS
    [bool] $true if successful, $false otherwise
#>
function New-ServiceBaseline {
    param(
        [string]$OutputPath = (Join-Path $env:APPDATA "WindowsTelemetryBlocker\service-baseline.json")
    )
    
    try {
        $baseline = @{}
        
        Write-LogMessage -Message "Creating service baseline..." -Level "INFO"
        
        # Capture all services
        $allServices = Get-Service -ErrorAction SilentlyContinue
        
        foreach ($service in $allServices) {
            try {
                $wmiService = Get-WmiObject -Class Win32_Service -Filter "Name = '$($service.Name)'" -ErrorAction SilentlyContinue
                
                if ($wmiService) {
                    $baseline[$service.Name] = @{
                        DisplayName = $service.DisplayName
                        State = $service.Status.ToString()
                        StartupType = $wmiService.StartMode
                        ProcessId = $service.ServiceHandle
                        Path = $wmiService.PathName
                    }
                }
            }
            catch {
                # Skip services that can't be queried
            }
        }
        
        # Save baseline
        $baselineDir = Split-Path $OutputPath
        if (-not (Test-Path $baselineDir)) {
            New-Item -ItemType Directory -Path $baselineDir -Force | Out-Null
        }
        
        $baseline | ConvertTo-Json -Depth 5 | Set-Content -Path $OutputPath -Force
        Write-LogMessage -Message "Service baseline created with $($baseline.Count) services" -Level "INFO"
        
        return $true
    }
    catch {
        Write-LogMessage -Message "Error creating service baseline: $_" -Level "ERROR"
        return $false
    }
}

<#
.SYNOPSIS
    Loads service baseline from file
.PARAMETER BaselinePath
    Path to baseline JSON file
.OUTPUTS
    [PSCustomObject] Baseline object
#>
function Get-ServiceBaseline {
    param(
        [string]$BaselinePath = (Join-Path $env:APPDATA "WindowsTelemetryBlocker\service-baseline.json")
    )
    
    try {
        if (Test-Path $BaselinePath) {
            $baseline = Get-Content $BaselinePath -Raw | ConvertFrom-Json
            return $baseline
        }
        else {
            Write-LogMessage -Message "Service baseline file not found at: $BaselinePath" -Level "WARNING"
            return $null
        }
    }
    catch {
        Write-LogMessage -Message "Error loading service baseline: $_" -Level "ERROR"
        return $null
    }
}

# ============================================================================
# SERVICE CHANGE DETECTION
# ============================================================================

<#
.SYNOPSIS
    Detects changes in service states and startup types
.PARAMETER Baseline
    Baseline object from Get-ServiceBaseline
.OUTPUTS
    [ServiceStateChange[]] Array of detected changes
#>
function Find-ServiceChanges {
    param(
        [PSCustomObject]$Baseline
    )
    
    try {
        $changes = @()
        
        if ($null -eq $Baseline) {
            return $changes
        }
        
        $allServices = Get-Service -ErrorAction SilentlyContinue
        
        foreach ($service in $allServices) {
            $serviceName = $service.Name
            
            if ($Baseline.PSObject.Properties[$serviceName]) {
                $baselineState = $Baseline.$serviceName
                $currentState = $service.Status.ToString()
                
                # Check for state changes
                if ($currentState -ne $baselineState.State) {
                    $change = [ServiceStateChange]::new($serviceName, $service.DisplayName, $baselineState.State, $currentState)
                    $change.IsAnomalous = Test-AnomalousServiceChange -ServiceName $serviceName -OldState $baselineState.State -NewState $currentState
                    $change.Severity = Get-ServiceChangeSeverity -ServiceName $serviceName -IsAnomalous $change.IsAnomalous
                    $changes += $change
                }
                
                # Check for startup type changes
                try {
                    $wmiService = Get-WmiObject -Class Win32_Service -Filter "Name = '$serviceName'" -ErrorAction SilentlyContinue
                    if ($wmiService -and $wmiService.StartMode -ne $baselineState.StartupType) {
                        $change = [ServiceStateChange]::new($serviceName, $service.DisplayName, $baselineState.StartupType, $wmiService.StartMode)
                        $change.Description = "Startup type changed from $($baselineState.StartupType) to $($wmiService.StartMode)"
                        $change.IsAnomalous = $wmiService.StartMode -eq "Auto"  # Suspicious if re-enabled to Auto
                        $change.Severity = if ($change.IsAnomalous) { "High" } else { "Medium" }
                        $changes += $change
                    }
                }
                catch {
                    # Skip services that can't be queried
                }
            }
        }
        
        return $changes
    }
    catch {
        Write-LogMessage -Message "Error finding service changes: $_" -Level "ERROR"
        return @()
    }
}

<#
.SYNOPSIS
    Determines if a service state change is anomalous
.PARAMETER ServiceName
    Name of the service
.PARAMETER OldState
    Previous service state
.PARAMETER NewState
    New service state
.OUTPUTS
    [bool] $true if change is anomalous, $false otherwise
#>
function Test-AnomalousServiceChange {
    param(
        [string]$ServiceName,
        [string]$OldState,
        [string]$NewState
    )
    
    # Check if it's a telemetry service that was supposed to be disabled
    $telemetryService = $script:TelemetryServices | Where-Object { $_.Name -eq $ServiceName }
    
    if ($telemetryService) {
        # Anomalous if changed from Stopped to Running
        if ($OldState -eq "Stopped" -and $NewState -eq "Running") {
            return $true
        }
    }
    
    return $false
}

<#
.SYNOPSIS
    Determines severity level of service change
.PARAMETER ServiceName
    Name of the service
.PARAMETER IsAnomalous
    Whether the change is anomalous
.OUTPUTS
    [string] Severity level
#>
function Get-ServiceChangeSeverity {
    param(
        [string]$ServiceName,
        [bool]$IsAnomalous
    )
    
    if (-not $IsAnomalous) {
        return "Low"
    }
    
    # Check if it's a critical service
    $criticalService = $script:CriticalServices | Where-Object { $_.Name -eq $ServiceName }
    
    if ($criticalService) {
        return "Critical"
    }
    
    # Check if it's a telemetry service
    $telemetryService = $script:TelemetryServices | Where-Object { $_.Name -eq $ServiceName }
    
    if ($telemetryService) {
        return "High"
    }
    
    return "Medium"
}

# ============================================================================
# SERVICE CHANGE HISTORY
# ============================================================================

<#
.SYNOPSIS
    Saves detected service changes to history file
.PARAMETER Changes
    Array of ServiceStateChange objects
.PARAMETER HistoryPath
    Path to save history JSON file
#>
function Save-ServiceChangeHistory {
    param(
        [ServiceStateChange[]]$Changes,
        [string]$HistoryPath = (Join-Path $env:APPDATA "WindowsTelemetryBlocker\service-history.json")
    )
    
    try {
        $historyDir = Split-Path $HistoryPath
        if (-not (Test-Path $historyDir)) {
            New-Item -ItemType Directory -Path $historyDir -Force | Out-Null
        }
        
        $history = @()
        if (Test-Path $HistoryPath) {
            $history = @(Get-Content $HistoryPath -Raw | ConvertFrom-Json)
        }
        
        foreach ($change in $Changes) {
            $history += @{
                Timestamp = $change.Timestamp
                ServiceName = $change.ServiceName
                DisplayName = $change.DisplayName
                OldState = $change.OldState
                NewState = $change.NewState
                IsAnomalous = $change.IsAnomalous
                Severity = $change.Severity
                Description = $change.Description
            }
        }
        
        if ($history.Count -gt 1000) {
            $history = $history[-1000..-1]
        }
        
        $history | ConvertTo-Json -Depth 5 | Set-Content -Path $HistoryPath -Force
    }
    catch {
        Write-LogMessage -Message "Error saving service change history: $_" -Level "ERROR"
    }
}

<#
.SYNOPSIS
    Retrieves service change history
.PARAMETER HistoryPath
    Path to history JSON file
.PARAMETER MaxEntries
    Maximum number of entries to return (default: 100)
.OUTPUTS
    [PSCustomObject[]] Array of historical changes
#>
function Get-ServiceChangeHistory {
    param(
        [string]$HistoryPath = (Join-Path $env:APPDATA "WindowsTelemetryBlocker\service-history.json"),
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
        Write-LogMessage -Message "Error retrieving service change history: $_" -Level "ERROR"
        return @()
    }
}

# ============================================================================
# SERVICE REMEDIATION
# ============================================================================

<#
.SYNOPSIS
    Restores service to baseline state
.PARAMETER ServiceName
    Name of service to restore
.PARAMETER Baseline
    Baseline object from Get-ServiceBaseline
.PARAMETER DryRun
    If true, shows what would be restored without making changes
.OUTPUTS
    [bool] $true if successful, $false otherwise
#>
function Restore-ServiceState {
    param(
        [string]$ServiceName,
        [PSCustomObject]$Baseline,
        [bool]$DryRun = $true
    )
    
    try {
        if (-not $Baseline.PSObject.Properties[$ServiceName]) {
            Write-LogMessage -Message "Service not found in baseline: $ServiceName" -Level "WARNING"
            return $false
        }
        
        $baselineState = $Baseline.$ServiceName
        $targetState = $baselineState.State
        $targetStartupType = $baselineState.StartupType
        
        if ($DryRun) {
            Write-LogMessage -Message "DRY RUN: Would restore $ServiceName to state: $targetState (startup: $targetStartupType)" -Level "INFO"
            return $true
        }
        
        # Set startup type
        Set-Service -Name $ServiceName -StartupType $targetStartupType -ErrorAction SilentlyContinue
        
        # Set service state
        if ($targetState -eq "Running") {
            Start-Service -Name $ServiceName -ErrorAction SilentlyContinue
        }
        else {
            Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
        }
        
        Write-LogMessage -Message "Service $ServiceName restored to baseline state" -Level "INFO"
        return $true
    }
    catch {
        Write-LogMessage -Message "Error restoring service state: $_" -Level "ERROR"
        return $false
    }
}

# ============================================================================
# SERVICE STATISTICS
# ============================================================================

<#
.SYNOPSIS
    Calculates statistics about service monitoring
.OUTPUTS
    [PSCustomObject] Statistics object
#>
function Get-ServiceMonitoringStatistics {
    try {
        $history = Get-ServiceChangeHistory -MaxEntries 10000
        
        $anomalousCount = ($history | Where-Object { $_.IsAnomalous }).Count
        $criticalChanges = ($history | Where-Object { $_.Severity -eq "Critical" }).Count
        $uniqueServices = ($history | Select-Object -ExpandProperty ServiceName -Unique).Count
        
        return [PSCustomObject]@{
            TotalChanges = $history.Count
            AnomalousChanges = $anomalousCount
            CriticalChanges = $criticalChanges
            UniqueServicesChanged = $uniqueServices
            LastChangeTime = if ($history) { $history[0].Timestamp } else { "Never" }
            TelemetryServicesMonitored = $script:TelemetryServices.Count
            CriticalServicesMonitored = $script:CriticalServices.Count
        }
    }
    catch {
        Write-LogMessage -Message "Error getting service statistics: $_" -Level "ERROR"
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
    'New-ServiceBaseline',
    'Get-ServiceBaseline',
    'Find-ServiceChanges',
    'Save-ServiceChangeHistory',
    'Get-ServiceChangeHistory',
    'Restore-ServiceState',
    'Get-ServiceMonitoringStatistics',
    'Test-AnomalousServiceChange',
    'Get-ServiceChangeSeverity'
)
