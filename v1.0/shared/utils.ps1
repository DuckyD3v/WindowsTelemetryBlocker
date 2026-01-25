# ===============================
# Shared Utilities
# v1.0 - Common Functions Library
# ===============================

# Ensure this module is not executed directly
if ($MyInvocation.InvocationName -eq '.' -or $MyInvocation.InvocationName -eq '&') {
    # Being dot-sourced - this is correct
} else {
    # Being executed directly
    Write-Host "This module should be dot-sourced, not executed directly" -ForegroundColor Yellow
}

# ===============================
# Logging Functions
# ===============================

$script:LogPath = $null

function Initialize-Logging {
    <#
    .SYNOPSIS
    Initialize logging system
    #>
    param(
        [string]$LogDirectory = $null
    )
    
    if ([string]::IsNullOrEmpty($LogDirectory)) {
        $appDataPath = [Environment]::GetFolderPath("ApplicationData")
        $LogDirectory = Join-Path $appDataPath "WindowsTelemetryBlocker" "logs"
    }
    
    if (-not (Test-Path $LogDirectory)) {
        New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
    }
    
    $script:LogPath = Join-Path $LogDirectory "wtb_$(Get-Date -Format 'yyyyMMdd').log"
    
    Write-LogEntry "INFO" "Logging initialized"
    return $script:LogPath
}

function Write-LogEntry {
    <#
    .SYNOPSIS
    Write an entry to the log file and console
    #>
    param(
        [parameter(Mandatory)]
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS", "DEBUG")]
        [string]$Level,
        
        [parameter(Mandatory)]
        [string]$Message,
        
        [switch]$NoConsole
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Write to log file if initialized
    if (-not [string]::IsNullOrEmpty($script:LogPath)) {
        try {
            Add-Content -Path $script:LogPath -Value $logEntry -Encoding UTF8
        } catch {
            # Silently fail if can't write to log
        }
    }
    
    # Write to console
    if (-not $NoConsole) {
        $color = switch ($Level) {
            "INFO"    { "Cyan" }
            "WARN"    { "Yellow" }
            "ERROR"   { "Red" }
            "SUCCESS" { "Green" }
            "DEBUG"   { "Gray" }
        }
        
        Write-Host $logEntry -ForegroundColor $color
    }
}

# ===============================
# Notification Functions
# ===============================

function Show-Notification {
    <#
    .SYNOPSIS
    Show a Windows toast notification
    #>
    param(
        [parameter(Mandatory)]
        [string]$Title,
        
        [parameter(Mandatory)]
        [string]$Message,
        
        [ValidateSet("info", "success", "warning", "error")]
        [string]$Type = "info",
        
        [int]$DurationSeconds = 5
    )
    
    try {
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
        [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null
        
        # App ID for notifications
        $appId = "WindowsTelemetryBlocker"
        
        # Create toast XML
        $toastXml = @"
<toast>
    <visual>
        <binding template="ToastText02">
            <text id="1">$Title</text>
            <text id="2">$Message</text>
        </binding>
    </visual>
</toast>
"@
        
        $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
        $xml.LoadXml($toastXml)
        
        $toast = New-Object Windows.UI.Notifications.ToastNotification $xml
        $toast.Tag = "WTB-$([guid]::NewGuid().Guid)"
        $toast.Group = "WTB"
        
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId).Show($toast)
        
        return $true
    } catch {
        Write-LogEntry "WARN" "Failed to show notification: $_"
        return $false
    }
}

function Show-MessageBox {
    <#
    .SYNOPSIS
    Show a Windows message box (synchronous)
    #>
    param(
        [parameter(Mandatory)]
        [string]$Message,
        
        [string]$Title = "Windows Telemetry Blocker",
        
        [ValidateSet("Information", "Question", "Warning", "Error")]
        [string]$Icon = "Information",
        
        [ValidateSet("OK", "OKCancel", "YesNo", "YesNoCancel")]
        [string]$Buttons = "OK"
    )
    
    try {
        [System.Windows.Forms.MessageBox]::Show(
            $Message,
            $Title,
            [System.Windows.Forms.MessageBoxButtons]::$Buttons,
            [System.Windows.Forms.MessageBoxIcon]::$Icon
        )
    } catch {
        Write-LogEntry "ERROR" "Failed to show message box: $_"
        return [System.Windows.Forms.DialogResult]::None
    }
}

# ===============================
# System Utility Functions
# ===============================

function Test-AdminPrivilege {
    <#
    .SYNOPSIS
    Check if running with administrator privileges
    #>
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    return $isAdmin
}

function Require-AdminPrivilege {
    <#
    .SYNOPSIS
    Exit if not running with administrator privileges
    #>
    if (-not (Test-AdminPrivilege)) {
        Write-LogEntry "ERROR" "This operation requires administrator privileges"
        Write-Host "`nPlease run PowerShell as Administrator" -ForegroundColor Red
        exit 1
    }
}

function Get-SystemInfo {
    <#
    .SYNOPSIS
    Get relevant system information
    #>
    return @{
        OSVersion = [System.Environment]::OSVersion.VersionString
        OSBuild = (Get-Item "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").GetValue("CurrentBuild")
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        IsAdmin = Test-AdminPrivilege
        UserName = [System.Environment]::UserName
        ComputerName = [System.Environment]::MachineName
    }
}

# ===============================
# Registry Functions
# ===============================

function Get-RegistryValue {
    <#
    .SYNOPSIS
    Safely get a registry value
    #>
    param(
        [parameter(Mandatory)]
        [string]$Path,
        
        [parameter(Mandatory)]
        [string]$Name
    )
    
    try {
        $value = Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop
        return $value.$Name
    } catch {
        return $null
    }
}

function Set-RegistryValue {
    <#
    .SYNOPSIS
    Safely set a registry value with validation
    #>
    param(
        [parameter(Mandatory)]
        [string]$Path,
        
        [parameter(Mandatory)]
        [string]$Name,
        
        [parameter(Mandatory)]
        $Value,
        
        [ValidateSet("String", "DWord", "Binary", "ExpandString", "MultiString")]
        [string]$Type = "DWord"
    )
    
    try {
        # Create path if it doesn't exist
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }
        
        # Set the value
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force
        Write-LogEntry "INFO" "Registry value set: $Path\$Name = $Value"
        return $true
    } catch {
        Write-LogEntry "ERROR" "Failed to set registry value: $_"
        return $false
    }
}

function Backup-RegistryKey {
    <#
    .SYNOPSIS
    Backup a registry key to .reg file
    #>
    param(
        [parameter(Mandatory)]
        [string]$RegistryPath,
        
        [parameter(Mandatory)]
        [string]$BackupFile
    )
    
    try {
        # Convert PowerShell path to registry path
        $regPath = $RegistryPath -replace "^HKCU:\\", "HKEY_CURRENT_USER\"
        $regPath = $regPath -replace "^HKLM:\\", "HKEY_LOCAL_MACHINE\"
        
        & reg.exe export $regPath $BackupFile /y 2>&1 | Out-Null
        
        if (Test-Path $BackupFile) {
            Write-LogEntry "INFO" "Registry key backed up: $BackupFile"
            return $true
        } else {
            return $false
        }
    } catch {
        Write-LogEntry "ERROR" "Failed to backup registry key: $_"
        return $false
    }
}

# ===============================
# Service Functions
# ===============================

function Get-ServiceState {
    <#
    .SYNOPSIS
    Get the current state of a service
    #>
    param(
        [parameter(Mandatory)]
        [string]$ServiceName
    )
    
    try {
        $service = Get-Service -Name $ServiceName -ErrorAction Stop
        return @{
            Name = $service.Name
            DisplayName = $service.DisplayName
            Status = $service.Status
            StartType = $service.StartType
        }
    } catch {
        return $null
    }
}

function Disable-TelemetryService {
    <#
    .SYNOPSIS
    Disable a service with safety checks
    #>
    param(
        [parameter(Mandatory)]
        [string]$ServiceName,
        
        [switch]$DryRun
    )
    
    try {
        $service = Get-Service -Name $ServiceName -ErrorAction Stop
        
        if ($service.Status -eq "Running") {
            if (-not $DryRun) {
                Stop-Service -Name $ServiceName -Force -ErrorAction Stop
                Write-LogEntry "INFO" "Service stopped: $ServiceName"
            } else {
                Write-LogEntry "DEBUG" "[DRY RUN] Would stop service: $ServiceName"
            }
        }
        
        if ($service.StartType -ne "Disabled") {
            if (-not $DryRun) {
                Set-Service -Name $ServiceName -StartupType Disabled -ErrorAction Stop
                Write-LogEntry "INFO" "Service disabled: $ServiceName"
            } else {
                Write-LogEntry "DEBUG" "[DRY RUN] Would disable service: $ServiceName"
            }
        }
        
        return $true
    } catch {
        Write-LogEntry "ERROR" "Failed to disable service ($ServiceName): $_"
        return $false
    }
}

# ===============================
# File Operations
# ===============================

function Remove-TelemetryFile {
    <#
    .SYNOPSIS
    Safely remove a file with backups
    #>
    param(
        [parameter(Mandatory)]
        [string]$FilePath,
        
        [switch]$DryRun
    )
    
    try {
        if (Test-Path $FilePath) {
            if (-not $DryRun) {
                # Backup first
                $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
                $backup = "$FilePath.bak.$timestamp"
                Copy-Item $FilePath $backup -Force
                
                # Remove
                Remove-Item $FilePath -Force
                Write-LogEntry "INFO" "File removed: $FilePath (backup: $backup)"
            } else {
                Write-LogEntry "DEBUG" "[DRY RUN] Would remove file: $FilePath"
            }
            return $true
        }
        return $false
    } catch {
        Write-LogEntry "ERROR" "Failed to remove file ($FilePath): $_"
        return $false
    }
}

# ===============================
# Progress and Reporting
# ===============================

function Show-Progress {
    <#
    .SYNOPSIS
    Display a progress bar
    #>
    param(
        [parameter(Mandatory)]
        [int]$Current,
        
        [parameter(Mandatory)]
        [int]$Total,
        
        [parameter(Mandatory)]
        [string]$Activity,
        
        [string]$Status = ""
    )
    
    Write-Progress -Activity $Activity -Status $Status -PercentComplete (($Current / $Total) * 100) -CurrentOperation "$Current of $Total"
}

function Complete-Progress {
    <#
    .SYNOPSIS
    Complete and hide progress bar
    #>
    Write-Progress -Activity "Completing" -Status "Done" -Completed
}

function Format-ExecutionReport {
    <#
    .SYNOPSIS
    Format an execution report
    #>
    param(
        [parameter(Mandatory)]
        [hashtable]$Results
    )
    
    $report = @"
=== Execution Report ===
Profile: $($Results.Profile)
Timestamp: $($Results.Timestamp)
Duration: $($Results.Duration)

Results:
  Successful: $($Results.Successful)
  Failed: $($Results.Failed)
  Skipped: $($Results.Skipped)

Status: $($Results.Status)
"@
    
    return $report
}

# Export public functions
Export-ModuleMember -Function @(
    'Initialize-Logging',
    'Write-LogEntry',
    'Show-Notification',
    'Show-MessageBox',
    'Test-AdminPrivilege',
    'Require-AdminPrivilege',
    'Get-SystemInfo',
    'Get-RegistryValue',
    'Set-RegistryValue',
    'Backup-RegistryKey',
    'Get-ServiceState',
    'Disable-TelemetryService',
    'Remove-TelemetryFile',
    'Show-Progress',
    'Complete-Progress',
    'Format-ExecutionReport'
)
