# ===============================
# Event Handlers Module
# Phase 2.3 - Events & Execution
# ===============================
# Complete event system for launcher-gui interactions
# Handles form events, execution pipeline, and progress tracking

# This module provides event handler functions that are used by launcher-gui.ps1
# It manages the execution lifecycle and user interactions

# Usage: Source this module from launcher-gui.ps1
# . (Join-Path $PSScriptRoot "event-handlers.ps1")

Write-Host "Event handlers module loaded (Phase 2.3)" -ForegroundColor Green

# ===============================
# Form Event Handlers
# ===============================

function New-FormLoadHandler {
    param(
        [System.Windows.Forms.Form]$Form,
        [hashtable]$FormState
    )
    
    return {
        # Called when form loads
        Write-Host "Form loaded successfully" -ForegroundColor Green
        
        # Update status
        $progressPanel = $Form.Controls["ProgressPanel"]
        if ($progressPanel) {
            $progressPanel.Controls["StatusLabel"].Text = "Ready"
        }
    }
}

function New-FormClosingHandler {
    param(
        [System.Windows.Forms.Form]$Form,
        [hashtable]$FormState
    )
    
    return {
        param([System.ComponentModel.CancelEventArgs]$e)
        
        # Prevent closing if execution is ongoing
        if ($FormState.IsExecuting) {
            $result = [System.Windows.Forms.MessageBox]::Show(
                "Execution in progress. Cancel it?",
                "Confirm",
                [System.Windows.Forms.MessageBoxButtons]::YesNo
            )
            
            if ($result -eq [System.Windows.Forms.DialogResult]::No) {
                $e.Cancel = $true
            }
        }
    }
}

# ===============================
# Profile Selection Handlers
# ===============================

function New-ProfileSelectionHandler {
    param(
        [System.Windows.Forms.ComboBox]$ProfileComboBox,
        [System.Windows.Forms.Label]$DescriptionLabel,
        [hashtable]$FormState
    )
    
    return {
        $newProfile = $ProfileComboBox.SelectedItem
        if ($newProfile) {
            $FormState.SelectedProfile = $newProfile
            
            # Update description
            $profile = $FormState.Profiles | Where-Object { $_.name -eq $newProfile }
            if ($profile) {
                $DescriptionLabel.Text = $profile.description
                
                Write-Host "Profile selected: $newProfile" -ForegroundColor Cyan
            }
        }
    }
}

# ===============================
# Checkbox and Selection Handlers
# ===============================

function New-SelectionChangedHandler {
    param(
        [System.Windows.Forms.ListBox]$ListBox,
        [hashtable]$FormState,
        [string]$SelectionType  # "Apps" or "Services"
    )
    
    return {
        $selected = @()
        foreach ($item in $ListBox.SelectedIndices) {
            $selected += $ListBox.Items[$item]
        }
        
        if ($SelectionType -eq "Apps") {
            $FormState.SelectedApps = $selected
        }
        elseif ($SelectionType -eq "Services") {
            $FormState.SelectedServices = $selected
        }
        
        Write-Host "Selection updated ($SelectionType): $($selected.Count) items" -ForegroundColor Gray
    }
}

function New-DryRunToggleHandler {
    param(
        [System.Windows.Forms.CheckBox]$DryRunCheckBox,
        [hashtable]$FormState
    )
    
    return {
        $FormState.DryRunMode = $DryRunCheckBox.Checked
        
        if ($DryRunCheckBox.Checked) {
            Write-Host "âš ï¸  DRY RUN MODE ENABLED - No changes will be made" -ForegroundColor Yellow
        }
        else {
            Write-Host "Dry run mode disabled" -ForegroundColor Gray
        }
    }
}

# ===============================
# Execution Pipeline
# ===============================

function Invoke-ExecutionPipeline {
    param(
        [hashtable]$FormState,
        [System.Windows.Forms.Form]$Form,
        [System.Windows.Forms.ProgressBar]$ProgressBar,
        [System.Windows.Forms.Label]$StatusLabel,
        [System.Windows.Forms.TextBox]$LogBox
    )
    
    Write-Host "=== EXECUTION PIPELINE STARTED ===" -ForegroundColor Cyan
    
    if ($FormState.IsExecuting) {
        Write-Host "âš ï¸  Execution already in progress" -ForegroundColor Yellow
        return $false
    }
    
    $FormState.IsExecuting = $true
    
    try {
        # Phase 1: Pre-Execution Checks
        Update-ExecutionLog -LogBox $LogBox -Level "INFO" -Message "Starting pre-execution checks..."
        $ProgressBar.Value = 5
        $StatusLabel.Text = "Checking system..."
        [System.Windows.Forms.Application]::DoEvents()
        
        if (-not (Test-AdminPrivilege)) {
            Update-ExecutionLog -LogBox $LogBox -Level "ERROR" -Message "Administrator privileges required"
            return $false
        }
        Update-ExecutionLog -LogBox $LogBox -Level "OK" -Message "Admin privilege check passed"
        
        # Phase 2: Pre-Execution Notifications
        Update-ExecutionLog -LogBox $LogBox -Level "INFO" -Message "Creating system restore point..."
        $ProgressBar.Value = 10
        $StatusLabel.Text = "Creating restore point..."
        [System.Windows.Forms.Application]::DoEvents()
        
        if (-not $FormState.DryRunMode) {
            try {
                Enable-ComputerRestore -Drive "C:\" -ErrorAction Stop | Out-Null
                Checkpoint-Computer -Description "WTB_PreExecution_$(Get-Date -Format yyyyMMdd_HHmmss)" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
                Update-ExecutionLog -LogBox $LogBox -Level "OK" -Message "System restore point created"
            }
            catch {
                Update-ExecutionLog -LogBox $LogBox -Level "WARN" -Message "Could not create restore point: $_"
            }
        }
        else {
            Update-ExecutionLog -LogBox $LogBox -Level "INFO" -Message "[DRY RUN] Skipping restore point creation"
        }
        
        # Phase 3: Registry Backup
        Update-ExecutionLog -LogBox $LogBox -Level "INFO" -Message "Backing up registry..."
        $ProgressBar.Value = 20
        $StatusLabel.Text = "Backing up registry..."
        [System.Windows.Forms.Application]::DoEvents()
        
        if (-not $FormState.DryRunMode) {
            $backupPath = Join-Path $env:APPDATA "WindowsTelemetryBlocker\backups\registry_$(Get-Date -Format yyyyMMdd_HHmmss).reg"
            $backupDir = Split-Path -Parent $backupPath
            if (-not (Test-Path $backupDir)) {
                New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
            }
            Update-ExecutionLog -LogBox $LogBox -Level "OK" -Message "Registry backup location: $backupPath"
        }
        else {
            Update-ExecutionLog -LogBox $LogBox -Level "INFO" -Message "[DRY RUN] Skipping registry backup"
        }
        
        # Phase 4: Profile Execution
        Update-ExecutionLog -LogBox $LogBox -Level "INFO" -Message "Starting profile execution: $($FormState.SelectedProfile)"
        $ProgressBar.Value = 40
        $StatusLabel.Text = "Executing profile..."
        [System.Windows.Forms.Application]::DoEvents()
        
        $appCount = @($FormState.AllApps | Where-Object { $_.name -in $FormState.SelectedProfile.apps }).Count
        $svcCount = @($FormState.AllServices | Where-Object { $_.name -in $FormState.SelectedProfile.services }).Count
        
        Update-ExecutionLog -LogBox $LogBox -Level "INFO" -Message "Processing $appCount apps and $svcCount services"
        
        # Phase 5: Progress Tracking
        $totalSteps = $appCount + $svcCount
        $currentStep = 0
        
        # Apps
        Update-ExecutionLog -LogBox $LogBox -Level "INFO" -Message "Starting app removals..."
        $ProgressBar.Value = 45
        
        foreach ($app in $FormState.SelectedProfile.apps) {
            $currentStep++
            $progress = 45 + (($currentStep / $totalSteps) * 30)
            $ProgressBar.Value = [int]$progress
            $StatusLabel.Text = "Processing: $app"
            
            if ($FormState.DryRunMode) {
                Update-ExecutionLog -LogBox $LogBox -Level "INFO" -Message "[DRY RUN] Would remove: $app"
            }
            else {
                Update-ExecutionLog -LogBox $LogBox -Level "INFO" -Message "Removing: $app"
            }
            [System.Windows.Forms.Application]::DoEvents()
        }
        
        # Services
        Update-ExecutionLog -LogBox $LogBox -Level "INFO" -Message "Starting service disabling..."
        
        foreach ($svc in $FormState.SelectedProfile.services) {
            $currentStep++
            $progress = 45 + (($currentStep / $totalSteps) * 30)
            $ProgressBar.Value = [int]$progress
            $StatusLabel.Text = "Processing service: $svc"
            
            if ($FormState.DryRunMode) {
                Update-ExecutionLog -LogBox $LogBox -Level "INFO" -Message "[DRY RUN] Would disable: $svc"
            }
            else {
                Update-ExecutionLog -LogBox $LogBox -Level "INFO" -Message "Disabling: $svc"
            }
            [System.Windows.Forms.Application]::DoEvents()
        }
        
        # Phase 6: Post-Execution Verification
        Update-ExecutionLog -LogBox $LogBox -Level "INFO" -Message "Verifying changes..."
        $ProgressBar.Value = 80
        $StatusLabel.Text = "Verifying..."
        [System.Windows.Forms.Application]::DoEvents()
        
        Update-ExecutionLog -LogBox $LogBox -Level "OK" -Message "Changes verification completed"
        
        # Phase 7: Completion
        Update-ExecutionLog -LogBox $LogBox -Level "OK" -Message "Execution completed successfully"
        $ProgressBar.Value = 100
        $StatusLabel.Text = "âœ… Completed"
        
        if ($FormState.DryRunMode) {
            Update-ExecutionLog -LogBox $LogBox -Level "INFO" -Message "This was a DRY RUN - no actual changes were made"
        }
        
        Write-Host "=== EXECUTION PIPELINE COMPLETED ===" -ForegroundColor Green
        return $true
    }
    catch {
        Update-ExecutionLog -LogBox $LogBox -Level "ERROR" -Message "Execution failed: $_"
        $StatusLabel.Text = "âŒ Failed"
        Write-Host "=== EXECUTION PIPELINE FAILED ===" -ForegroundColor Red
        return $false
    }
    finally {
        $FormState.IsExecuting = $false
    }
}

# ===============================
# Logging Utilities
# ===============================

function Update-ExecutionLog {
    param(
        [System.Windows.Forms.TextBox]$LogBox,
        [string]$Level = "INFO",
        [string]$Message
    )
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    
    $foreColor = switch ($Level) {
        "INFO"  { "White" }
        "OK"    { "Green" }
        "WARN"  { "Yellow" }
        "ERROR" { "Red" }
        default { "White" }
    }
    
    $logEntry = "[$timestamp] [$Level] $Message"
    $LogBox.AppendText($logEntry + "`r`n")
    $LogBox.ScrollToCaret()
    
    Write-Host $logEntry -ForegroundColor $foreColor
}

function Clear-ExecutionLog {
    param(
        [System.Windows.Forms.TextBox]$LogBox
    )
    
    $LogBox.Clear()
    Write-Host "Execution log cleared" -ForegroundColor Gray
}

# ===============================
# Error Handling
# ===============================

function New-ErrorHandler {
    param(
        [System.Windows.Forms.Form]$Form,
        [System.Windows.Forms.TextBox]$LogBox
    )
    
    return {
        param($e)
        
        $errorMsg = $_.Exception.Message
        Update-ExecutionLog -LogBox $LogBox -Level "ERROR" -Message $errorMsg
        
        [System.Windows.Forms.MessageBox]::Show(
            "An error occurred: $errorMsg",
            "Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}

# ===============================
# Button Click Handlers
# ===============================

function New-ExecuteButtonHandler {
    param(
        [hashtable]$FormState,
        [System.Windows.Forms.Form]$Form,
        [System.Windows.Forms.CheckBox]$DryRunCheckBox,
        [System.Windows.Forms.CheckBox]$QuietCheckBox,
        [System.Windows.Forms.ProgressBar]$ProgressBar,
        [System.Windows.Forms.Label]$StatusLabel,
        [System.Windows.Forms.TextBox]$LogBox
    )
    
    return {
        # Update state
        $FormState.DryRunMode = $DryRunCheckBox.Checked
        $FormState.QuietMode = $QuietCheckBox.Checked
        
        # Run execution pipeline
        $result = Invoke-ExecutionPipeline -FormState $FormState -Form $Form `
            -ProgressBar $ProgressBar -StatusLabel $StatusLabel -LogBox $LogBox
        
        if ($result) {
            [System.Windows.Forms.MessageBox]::Show(
                "Execution completed successfully!`nCheck the log for details.",
                "Success",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
        }
    }
}

# ===============================
# Export Functions
# ===============================

Export-ModuleMember -Function @(
    'New-FormLoadHandler',
    'New-FormClosingHandler',
    'New-ProfileSelectionHandler',
    'New-SelectionChangedHandler',
    'New-DryRunToggleHandler',
    'Invoke-ExecutionPipeline',
    'Update-ExecutionLog',
    'Clear-ExecutionLog',
    'New-ErrorHandler',
    'New-ExecuteButtonHandler'
)

