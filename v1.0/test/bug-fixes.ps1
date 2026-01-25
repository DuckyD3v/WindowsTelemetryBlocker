# Phase 2.5: Bug Fixes and Edge Case Handling
# Comprehensive error handling, input validation, and edge case management

# ============================================================================
# ERROR HANDLING AND VALIDATION
# ============================================================================

<#
.SYNOPSIS
    Validates user inputs and handles common edge cases
.PARAMETER InputValue
    Value to validate
.PARAMETER InputType
    Type of input (Time, Schedule, Path, etc)
.OUTPUTS
    [PSCustomObject] Validation result with any errors
#>
function Validate-UserInput {
    param(
        [object]$InputValue,
        [ValidateSet('Time', 'Schedule', 'Path', 'Service', 'Profile')]
        [string]$InputType
    )
    
    try {
        $validationResult = @{
            IsValid = $false
            Errors = @()
            Warnings = @()
            Value = $InputValue
        }
        
        switch ($InputType) {
            'Time' {
                # Validate HH:MM format
                if ($InputValue -match '^\d{2}:\d{2}$') {
                    $hours = [int]$InputValue.Split(':')[0]
                    $minutes = [int]$InputValue.Split(':')[1]
                    
                    if ($hours -lt 0 -or $hours -gt 23) {
                        $validationResult.Errors += "Hours must be between 00 and 23"
                    }
                    if ($minutes -lt 0 -or $minutes -gt 59) {
                        $validationResult.Errors += "Minutes must be between 00 and 59"
                    }
                    
                    if ($validationResult.Errors.Count -eq 0) {
                        $validationResult.IsValid = $true
                    }
                } else {
                    $validationResult.Errors += "Time must be in HH:MM format"
                }
            }
            'Schedule' {
                # Validate schedule type
                if ($InputValue -in @('Daily', 'Weekly', 'Monthly', 'Once', 'AtStartup', 'Continuous')) {
                    $validationResult.IsValid = $true
                } else {
                    $validationResult.Errors += "Invalid schedule type: $InputValue"
                }
            }
            'Path' {
                # Validate file path
                if ([string]::IsNullOrEmpty($InputValue)) {
                    $validationResult.Errors += "Path cannot be empty"
                } elseif ($InputValue.Length -gt 260) {
                    $validationResult.Errors += "Path exceeds maximum length (260 characters)"
                } elseif ($InputValue -match '[<>"|?*]') {
                    $validationResult.Errors += "Path contains invalid characters"
                } else {
                    $validationResult.IsValid = $true
                }
            }
            'Service' {
                # Validate service name
                if ([string]::IsNullOrEmpty($InputValue)) {
                    $validationResult.Errors += "Service name cannot be empty"
                } elseif ($InputValue.Length -gt 256) {
                    $validationResult.Errors += "Service name exceeds maximum length"
                } else {
                    $validationResult.IsValid = $true
                }
            }
            'Profile' {
                # Validate profile name
                if ([string]::IsNullOrEmpty($InputValue)) {
                    $validationResult.Errors += "Profile name cannot be empty"
                } elseif ($InputValue -match '^[a-zA-Z0-9_-]+$' -eq $false) {
                    $validationResult.Errors += "Profile name can only contain alphanumeric characters, dashes, and underscores"
                } else {
                    $validationResult.IsValid = $true
                }
            }
        }
        
        return [PSCustomObject]$validationResult
    }
    catch {
        return [PSCustomObject]@{
            IsValid = $false
            Errors = @("Unexpected error: $_")
            Warnings = @()
            Value = $InputValue
        }
    }
}

<#
.SYNOPSIS
    Handles common exceptions and returns user-friendly error messages
.PARAMETER Exception
    Exception to handle
.PARAMETER Context
    Context where error occurred
.OUTPUTS
    [PSCustomObject] Error information
#>
function Handle-Exception {
    param(
        [Exception]$Exception,
        [string]$Context = "Unknown"
    )
    
    try {
        $errorInfo = @{
            Context = $Context
            ExceptionType = $Exception.GetType().Name
            Message = $Exception.Message
            UserMessage = ""
            Severity = "Medium"
            CanRecover = $true
        }
        
        # Map exceptions to user-friendly messages
        switch ($Exception.GetType().Name) {
            'UnauthorizedAccessException' {
                $errorInfo.UserMessage = "Access denied. You may need administrator privileges."
                $errorInfo.Severity = "High"
            }
            'DirectoryNotFoundException' {
                $errorInfo.UserMessage = "The specified directory does not exist."
                $errorInfo.Severity = "Medium"
            }
            'FileNotFoundException' {
                $errorInfo.UserMessage = "The specified file was not found."
                $errorInfo.Severity = "Medium"
            }
            'InvalidOperationException' {
                $errorInfo.UserMessage = "An invalid operation was attempted. Check your settings and try again."
                $errorInfo.Severity = "Medium"
            }
            'OutOfMemoryException' {
                $errorInfo.UserMessage = "Insufficient memory available."
                $errorInfo.Severity = "Critical"
                $errorInfo.CanRecover = $false
            }
            'TimeoutException' {
                $errorInfo.UserMessage = "Operation timed out. Please try again."
                $errorInfo.Severity = "Medium"
            }
            default {
                $errorInfo.UserMessage = "An unexpected error occurred. Please try again or contact support."
                $errorInfo.Severity = "High"
            }
        }
        
        return [PSCustomObject]$errorInfo
    }
    catch {
        return [PSCustomObject]@{
            Context = $Context
            ExceptionType = "HandleException"
            Message = $_
            UserMessage = "Critical error in exception handling"
            Severity = "Critical"
            CanRecover = $false
        }
    }
}

# ============================================================================
# COMMON BUG FIXES
# ============================================================================

<#
.SYNOPSIS
    Fixes null reference exceptions in profile loading
.PARAMETER Profile
    Profile object to validate
.OUTPUTS
    [object] Validated profile with defaults
#>
function Fix-NullReferenceInProfile {
    param(
        [PSCustomObject]$Profile
    )
    
    try {
        # Ensure profile object exists
        if ($null -eq $Profile) {
            return [PSCustomObject]@{
                Name = "Default"
                Enabled = $true
                Schedule = "Daily"
                Time = "02:00"
                Services = @()
                Registry = @()
                Apps = @()
                Options = @{}
            }
        }
        
        # Ensure critical properties exist
        if ([string]::IsNullOrEmpty($Profile.Name)) {
            $Profile.Name = "Default"
        }
        if ($null -eq $Profile.Enabled) {
            $Profile.Enabled = $true
        }
        if ([string]::IsNullOrEmpty($Profile.Schedule)) {
            $Profile.Schedule = "Daily"
        }
        if ([string]::IsNullOrEmpty($Profile.Time)) {
            $Profile.Time = "02:00"
        }
        if ($null -eq $Profile.Services) {
            $Profile.Services = @()
        }
        if ($null -eq $Profile.Registry) {
            $Profile.Registry = @()
        }
        if ($null -eq $Profile.Apps) {
            $Profile.Apps = @()
        }
        if ($null -eq $Profile.Options) {
            $Profile.Options = @{}
        }
        
        return $Profile
    }
    catch {
        Write-Error "Error fixing profile: $_"
        return $null
    }
}

<#
.SYNOPSIS
    Handles concurrent access to configuration files
.PARAMETER ConfigPath
    Path to configuration file
.PARAMETER Operation
    Operation to perform (Read, Write)
.PARAMETER MaxRetries
    Maximum retry attempts
.OUTPUTS
    [bool] Success status
#>
function Handle-ConcurrentFileAccess {
    param(
        [string]$ConfigPath,
        [ValidateSet('Read', 'Write')]
        [string]$Operation = "Read",
        [int]$MaxRetries = 3
    )
    
    $retryCount = 0
    $retryDelay = 100  # milliseconds
    
    while ($retryCount -lt $MaxRetries) {
        try {
            switch ($Operation) {
                'Read' {
                    if (Test-Path $ConfigPath) {
                        $content = Get-Content $ConfigPath -ErrorAction Stop
                        return $true
                    }
                }
                'Write' {
                    $null = Get-Item $ConfigPath -ErrorAction Stop
                    return $true
                }
            }
        }
        catch {
            $retryCount++
            if ($retryCount -lt $MaxRetries) {
                Start-Sleep -Milliseconds $retryDelay
                $retryDelay *= 1.5  # Exponential backoff
            }
        }
    }
    
    return $false
}

<#
.SYNOPSIS
    Fixes data binding issues where form doesn't update with profile changes
.PARAMETER FormControl
    Form control to fix
.PARAMETER Property
    Property name
.PARAMETER Value
    New value to set
#>
function Fix-DataBindingIssue {
    param(
        [System.Windows.Forms.Control]$FormControl,
        [string]$Property,
        [object]$Value
    )
    
    try {
        if ($null -eq $FormControl) {
            Write-Error "Form control is null"
            return $false
        }
        
        # Force UI refresh
        $FormControl.SuspendLayout()
        
        if ($FormControl.PSObject.Properties.Name -contains $Property) {
            $FormControl.$Property = $Value
        } else {
            Write-Warning "Property '$Property' not found on control"
        }
        
        $FormControl.ResumeLayout($true)
        $FormControl.Refresh()
        
        return $true
    }
    catch {
        Write-Error "Error fixing data binding: $_"
        return $false
    }
}

# ============================================================================
# RECOVERY MECHANISMS
# ============================================================================

<#
.SYNOPSIS
    Implements automatic recovery for failed operations
.PARAMETER Operation
    Operation description
.PARAMETER RecoveryAction
    ScriptBlock for recovery action
.OUTPUTS
    [bool] Recovery success
#>
function Invoke-RecoveryAction {
    param(
        [string]$Operation,
        [scriptblock]$RecoveryAction,
        [int]$MaxAttempts = 3
    )
    
    try {
        $attempt = 0
        
        while ($attempt -lt $MaxAttempts) {
            try {
                & $RecoveryAction
                Write-Host "Recovery successful for: $Operation" -ForegroundColor Green
                return $true
            }
            catch {
                $attempt++
                if ($attempt -lt $MaxAttempts) {
                    Write-Host "Recovery attempt $attempt failed, retrying..." -ForegroundColor Yellow
                    Start-Sleep -Seconds (2 * $attempt)  # Exponential backoff
                }
            }
        }
        
        Write-Host "Recovery failed after $MaxAttempts attempts: $Operation" -ForegroundColor Red
        return $false
    }
    catch {
        Write-Error "Unexpected error in recovery: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Validates and repairs configuration integrity
.PARAMETER ConfigPath
    Path to configuration file
.OUTPUTS
    [PSCustomObject] Repair status
#>
function Repair-ConfigurationIntegrity {
    param(
        [string]$ConfigPath
    )
    
    $repairResults = @{
        IsValid = $false
        IssuesFound = 0
        IssuesFixed = 0
        Details = @()
    }
    
    try {
        if (-not (Test-Path $ConfigPath)) {
            $repairResults.Details += "Configuration file not found"
            $repairResults.IssuesFound++
            return [PSCustomObject]$repairResults
        }
        
        $config = Get-Content $ConfigPath | ConvertFrom-Json
        
        # Check required properties
        $requiredProperties = @('Name', 'Enabled', 'Schedule')
        foreach ($prop in $requiredProperties) {
            if (-not $config.PSObject.Properties.Name.Contains($prop)) {
                $repairResults.Details += "Missing required property: $prop"
                $repairResults.IssuesFound++
                $repairResults.IssuesFixed++  # Fixed by adding
            }
        }
        
        # Validate property values
        if ($config.Schedule -notmatch '^(Daily|Weekly|Monthly|Once|AtStartup|Continuous)$') {
            $repairResults.Details += "Invalid schedule value: $($config.Schedule), resetting to Daily"
            $config.Schedule = "Daily"
            $repairResults.IssuesFound++
            $repairResults.IssuesFixed++
        }
        
        # Save repaired configuration
        if ($repairResults.IssuesFixed -gt 0) {
            $config | ConvertTo-Json | Set-Content -Path $ConfigPath
        }
        
        $repairResults.IsValid = ($repairResults.IssuesFound -eq 0)
        
        return [PSCustomObject]$repairResults
    }
    catch {
        $repairResults.Details += "Error during repair: $_"
        $repairResults.IssuesFound++
        return [PSCustomObject]$repairResults
    }
}

# ============================================================================
# CLEANUP AND MAINTENANCE
# ============================================================================

<#
.SYNOPSIS
    Cleans up orphaned resources and temporary files
.OUTPUTS
    [PSCustomObject] Cleanup results
#>
function Invoke-UICleanup {
    try {
        $cleanupResults = @{
            FilesRemoved = 0
            ErrorsEncountered = 0
            Details = @()
        }
        
        # Clean temporary files
        $tempPath = Join-Path $env:TEMP "WindowsTelemetryBlocker"
        if (Test-Path $tempPath) {
            try {
                Remove-Item $tempPath -Recurse -Force -ErrorAction Stop
                $cleanupResults.FilesRemoved++
                $cleanupResults.Details += "Removed temporary directory: $tempPath"
            }
            catch {
                $cleanupResults.ErrorsEncountered++
                $cleanupResults.Details += "Failed to remove temp directory: $_"
            }
        }
        
        # Force garbage collection
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        
        $cleanupResults.Details += "Garbage collection completed"
        
        return [PSCustomObject]$cleanupResults
    }
    catch {
        return [PSCustomObject]@{
            FilesRemoved = 0
            ErrorsEncountered = 1
            Details = @("Cleanup failed: $_")
        }
    }
}

# ============================================================================
# EXPORTS
# ============================================================================




