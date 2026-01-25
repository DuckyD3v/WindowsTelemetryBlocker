# Phase 4: Task Scheduler Module
# Provides Windows Task Scheduler integration for automated telemetry blocking
# Handles task creation, management, scheduling, and execution tracking

# ============================================================================
# TASK CREATION FUNCTIONS
# ============================================================================

<#
.SYNOPSIS
    Creates a new scheduled telemetry blocking task
.PARAMETER TaskName
    Name for the scheduled task
.PARAMETER Profile
    Profile to use (Minimal, Balanced, Maximum)
.PARAMETER Schedule
    Schedule type (DAILY, WEEKLY, MONTHLY)
.PARAMETER Time
    Execution time in HH:MM format (24-hour)
.PARAMETER DryRun
    If true, runs in dry-run mode without making changes
.PARAMETER Quiet
    If true, hides the UI during execution
.OUTPUTS
    [PSCustomObject] Task creation result with status and details
#>
function New-ScheduledTelemetryTask {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskName,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet('Minimal', 'Balanced', 'Maximum')]
        [string]$Profile,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet('DAILY', 'WEEKLY', 'MONTHLY')]
        [string]$Schedule,
        
        [Parameter(Mandatory=$true)]
        [string]$Time,  # HH:MM format
        
        [bool]$DryRun = $false,
        [bool]$Quiet = $false
    )
    
    try {
        # Validate schedule time format
        if (-not (Validate-ScheduleTime -Time $Time)) {
            return [PSCustomObject]@{
                Success = $false
                Error = "Invalid time format. Use HH:MM (24-hour)"
                TaskName = $TaskName
            }
        }
        
        # Parse time components
        $timeParts = $Time.Split(':')
        $hour = [int]$timeParts[0]
        $minute = [int]$timeParts[1]
        
        # Create task trigger based on schedule type
        $trigger = switch ($Schedule) {
            'DAILY' {
                New-ScheduledTaskTrigger -Daily -At $Time
            }
            'WEEKLY' {
                New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At $Time
            }
            'MONTHLY' {
                # Create monthly trigger for the 1st of each month
                $trigger = New-ScheduledTaskTrigger -Daily -At $Time
                $trigger.StartBoundary = [datetime]::Now
                $trigger
            }
        }
        
        # Build command line arguments
        $cmdArgs = "-NoProfile -WindowStyle Hidden -Command `"cd '$PSScriptRoot'; & '.\launcher-gui.ps1' -DefaultProfile '$Profile'"
        
        if ($DryRun) {
            $cmdArgs += " -DryRun"
        }
        
        if ($Quiet) {
            $cmdArgs += " -Quiet"
        }
        
        $cmdArgs += "`""
        
        # Create task action
        $action = New-ScheduledTaskAction `
            -Execute "PowerShell.exe" `
            -Argument $cmdArgs
        
        # Create task settings
        $settings = New-ScheduledTaskSettingsSet `
            -AllowStartIfOnBatteries `
            -StartWhenAvailable `
            -RunOnlyIfNetworkAvailable `
            -DontStopIfGoingOnBatteries
        
        # Create task principal (SYSTEM account)
        $principal = New-ScheduledTaskPrincipal `
            -UserID "NT AUTHORITY\SYSTEM" `
            -LogonType ServiceAccount `
            -RunLevel Highest
        
        # Register the task
        $task = Register-ScheduledTask `
            -TaskName $TaskName `
            -Action $action `
            -Trigger $trigger `
            -Settings $settings `
            -Principal $principal `
            -Force
        
        if ($task) {
            Write-LogMessage -Message "Created scheduled task: $TaskName ($Schedule at $Time)" -Level "INFO"
            return [PSCustomObject]@{
                Success = $true
                TaskName = $TaskName
                Schedule = $Schedule
                Time = $Time
                Profile = $Profile
                Task = $task
            }
        }
    }
    catch {
        Write-LogMessage -Message "Error creating scheduled task: $_" -Level "ERROR"
        return [PSCustomObject]@{
            Success = $false
            Error = $_.Exception.Message
            TaskName = $TaskName
        }
    }
}

# ============================================================================
# TASK ENUMERATION AND DETAILS FUNCTIONS
# ============================================================================

<#
.SYNOPSIS
    Gets all scheduled telemetry blocking tasks
.OUTPUTS
    [PSCustomObject[]] Array of scheduled tasks
#>
function Get-ScheduledTelemetryTasks {
    try {
        $tasks = Get-ScheduledTask -TaskPath "\*" -ErrorAction SilentlyContinue | `
            Where-Object { $_.TaskName -like "*Telemetry*" -or $_.TaskName -like "*BlockTelemetry*" }
        
        return $tasks
    }
    catch {
        Write-LogMessage -Message "Error getting scheduled tasks: $_" -Level "ERROR"
        return @()
    }
}

<#
.SYNOPSIS
    Gets detailed information about a scheduled task
.PARAMETER TaskName
    Name of the task to get details for
.OUTPUTS
    [PSCustomObject] Task details including state, enabled status, triggers, etc
#>
function Get-TaskDetails {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskName
    )
    
    try {
        $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop
        $taskInfo = Get-ScheduledTaskInfo -TaskName $TaskName -ErrorAction Stop
        
        return [PSCustomObject]@{
            TaskName = $task.TaskName
            State = $task.State
            Enabled = $task.Enabled
            LastRunTime = $taskInfo.LastRunTime
            NextRunTime = $taskInfo.NextRunTime
            LastTaskResult = $taskInfo.LastTaskResult
            NumberOfMissedRuns = $taskInfo.NumberOfMissedRuns
            Description = $task.Description
            Triggers = $task.Triggers
            Actions = $task.Actions
        }
    }
    catch {
        Write-LogMessage -Message "Error getting task details for '$TaskName': $_" -Level "ERROR"
        return $null
    }
}

# ============================================================================
# TASK CONTROL FUNCTIONS
# ============================================================================

<#
.SYNOPSIS
    Removes a scheduled telemetry task
.PARAMETER TaskName
    Name of the task to remove
.OUTPUTS
    [bool] $true if successful, $false otherwise
#>
function Remove-ScheduledTelemetryTask {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskName
    )
    
    try {
        # Stop task if running
        Stop-ScheduledTaskForce -TaskName $TaskName -ErrorAction SilentlyContinue
        
        # Unregister the task
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction Stop
        
        Write-LogMessage -Message "Removed scheduled task: $TaskName" -Level "INFO"
        return $true
    }
    catch {
        Write-LogMessage -Message "Error removing scheduled task '$TaskName': $_" -Level "ERROR"
        return $false
    }
}

<#
.SYNOPSIS
    Starts execution of a scheduled task immediately
.PARAMETER TaskName
    Name of the task to start
.OUTPUTS
    [bool] $true if successful, $false otherwise
#>
function Start-ScheduledTask {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskName
    )
    
    try {
        Start-ScheduledTask -TaskName $TaskName -ErrorAction Stop
        Write-LogMessage -Message "Started scheduled task: $TaskName" -Level "INFO"
        return $true
    }
    catch {
        Write-LogMessage -Message "Error starting scheduled task '$TaskName': $_" -Level "ERROR"
        return $false
    }
}

<#
.SYNOPSIS
    Stops a running scheduled task forcefully
.PARAMETER TaskName
    Name of the task to stop
.OUTPUTS
    [bool] $true if successful, $false otherwise
#>
function Stop-ScheduledTaskForce {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskName
    )
    
    try {
        $task = Get-ScheduledTaskInfo -TaskName $TaskName -ErrorAction Stop
        
        if ($task.State -eq "Running") {
            Stop-ScheduledTask -TaskName $TaskName -ErrorAction Stop
            Write-LogMessage -Message "Stopped scheduled task: $TaskName" -Level "INFO"
        }
        
        return $true
    }
    catch {
        # Task may not be running, which is fine
        return $false
    }
}

<#
.SYNOPSIS
    Enables a disabled scheduled task
.PARAMETER TaskName
    Name of the task to enable
.OUTPUTS
    [bool] $true if successful, $false otherwise
#>
function Enable-ScheduledTask {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskName
    )
    
    try {
        $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop
        
        if (-not $task.Enabled) {
            Enable-ScheduledTask -TaskName $TaskName -ErrorAction Stop
            Write-LogMessage -Message "Enabled scheduled task: $TaskName" -Level "INFO"
        }
        
        return $true
    }
    catch {
        Write-LogMessage -Message "Error enabling scheduled task '$TaskName': $_" -Level "ERROR"
        return $false
    }
}

<#
.SYNOPSIS
    Disables a scheduled task
.PARAMETER TaskName
    Name of the task to disable
.OUTPUTS
    [bool] $true if successful, $false otherwise
#>
function Disable-ScheduledTask {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskName
    )
    
    try {
        $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop
        
        if ($task.Enabled) {
            Disable-ScheduledTask -TaskName $TaskName -ErrorAction Stop
            Write-LogMessage -Message "Disabled scheduled task: $TaskName" -Level "INFO"
        }
        
        return $true
    }
    catch {
        Write-LogMessage -Message "Error disabling scheduled task '$TaskName': $_" -Level "ERROR"
        return $false
    }
}

# ============================================================================
# VALIDATION FUNCTIONS
# ============================================================================

<#
.SYNOPSIS
    Validates schedule time format (HH:MM 24-hour)
.PARAMETER Time
    Time string to validate
.OUTPUTS
    [bool] $true if valid, $false otherwise
#>
function Validate-ScheduleTime {
    param(
        [string]$Time
    )
    
    try {
        if ($Time -match '^\d{2}:\d{2}$') {
            $timeParts = $Time.Split(':')
            $hour = [int]$timeParts[0]
            $minute = [int]$timeParts[1]
            
            return ($hour -ge 0 -and $hour -le 23 -and $minute -ge 0 -and $minute -le 59)
        }
        return $false
    }
    catch {
        return $false
    }
}

<#
.SYNOPSIS
    Validates schedule type
.PARAMETER ScheduleType
    Schedule type to validate (DAILY, WEEKLY, MONTHLY)
.OUTPUTS
    [bool] $true if valid, $false otherwise
#>
function Validate-ScheduleType {
    param(
        [string]$ScheduleType
    )
    
    return $ScheduleType -in @('DAILY', 'WEEKLY', 'MONTHLY')
}

# ============================================================================
# EXECUTION HISTORY AND STATISTICS FUNCTIONS
# ============================================================================

<#
.SYNOPSIS
    Gets task execution history from Task Scheduler event log
.PARAMETER TaskName
    Name of the task to get history for
.PARAMETER MaxEntries
    Maximum number of history entries to retrieve (default: 10)
.OUTPUTS
    [PSCustomObject[]] Array of execution history records
#>
function Get-TaskExecutionHistory {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskName,
        
        [int]$MaxEntries = 10
    )
    
    try {
        # Query Task Scheduler event log
        $logName = "Microsoft-Windows-TaskScheduler/Operational"
        $filter = @"
            *[System[EventID=201 or EventID=200 or EventID=203]]
            and
            *[EventData[Data[@Name='TaskName']='$TaskName']]
"@
        
        $events = Get-WinEvent -LogName $logName -FilterXml $filter -MaxEvents $MaxEntries -ErrorAction SilentlyContinue
        
        $history = @()
        foreach ($event in $events) {
            $history += [PSCustomObject]@{
                TimeCreated = $event.TimeCreated
                EventID = $event.Id
                Level = $event.LevelDisplayName
                Message = $event.Message
            }
        }
        
        return $history
    }
    catch {
        Write-LogMessage -Message "Error getting task execution history: $_" -Level "ERROR"
        return @()
    }
}

<#
.SYNOPSIS
    Gets aggregate statistics about all scheduled telemetry tasks
.OUTPUTS
    [PSCustomObject] Statistics object with task counts and states
#>
function Get-ScheduleStatistics {
    try {
        $tasks = Get-ScheduledTelemetryTasks
        
        $stats = [PSCustomObject]@{
            TotalTasks = $tasks.Count
            EnabledTasks = ($tasks | Where-Object { $_.Enabled }).Count
            DisabledTasks = ($tasks | Where-Object { -not $_.Enabled }).Count
            RunningTasks = ($tasks | Where-Object { $_.State -eq "Running" }).Count
            ReadyTasks = ($tasks | Where-Object { $_.State -eq "Ready" }).Count
            ErrorTasks = 0
        }
        
        # Count tasks with errors from history
        foreach ($task in $tasks) {
            $history = Get-TaskExecutionHistory -TaskName $task.TaskName -MaxEntries 1
            if ($history -and $history[0].Level -eq "Error") {
                $stats.ErrorTasks++
            }
        }
        
        return $stats
    }
    catch {
        Write-LogMessage -Message "Error getting schedule statistics: $_" -Level "ERROR"
        return $null
    }
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

<#
.SYNOPSIS
    Placeholder for logging function (imported from utils.ps1)
.PARAMETER Message
    Message to log
.PARAMETER Level
    Log level (INFO, WARNING, ERROR, DEBUG)
#>
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
    'New-ScheduledTelemetryTask',
    'Get-ScheduledTelemetryTasks',
    'Get-TaskDetails',
    'Remove-ScheduledTelemetryTask',
    'Start-ScheduledTask',
    'Stop-ScheduledTaskForce',
    'Enable-ScheduledTask',
    'Disable-ScheduledTask',
    'Validate-ScheduleTime',
    'Validate-ScheduleType',
    'Get-TaskExecutionHistory',
    'Get-ScheduleStatistics'
)
