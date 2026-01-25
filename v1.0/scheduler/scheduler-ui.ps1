# Phase 4: Scheduler UI Module
# Provides Windows Forms dialog for task scheduler management
# Handles task creation, viewing, and control operations

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ============================================================================
# SCHEDULER DIALOG FUNCTION
# ============================================================================

<#
.SYNOPSIS
    Shows the task scheduler management dialog
.PARAMETER Owner
    Parent form for the dialog
.PARAMETER Theme
    Current theme name for consistent styling
.OUTPUTS
    [System.Windows.Forms.DialogResult] Dialog result (OK, Cancel, etc)
#>
function Show-SchedulerDialog {
    param(
        [System.Windows.Forms.Form]$Owner,
        [string]$Theme = "Dark"
    )
    
    try {
        # Import task scheduler module
        . (Join-Path $PSScriptRoot "task-scheduler.ps1")
        
        # Create main dialog
        $dialog = New-Object System.Windows.Forms.Form
        $dialog.Text = "Task Scheduler - Windows Telemetry Blocker"
        $dialog.Size = New-Object System.Drawing.Size(700, 600)
        $dialog.StartPosition = "CenterParent"
        $dialog.Owner = $Owner
        $dialog.Icon = $Owner.Icon
        
        # Apply theme colors
        $bgColor = if ($Theme -eq "Dark") { [System.Drawing.Color]::FromArgb(45, 45, 48) } else { [System.Drawing.Color]::White }
        $fgColor = if ($Theme -eq "Dark") { [System.Drawing.Color]::White } else { [System.Drawing.Color]::Black }
        $accentColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
        
        $dialog.BackColor = $bgColor
        $dialog.ForeColor = $fgColor
        
        # Create TabControl
        $tabControl = New-Object System.Windows.Forms.TabControl
        $tabControl.Dock = "Fill"
        $tabControl.BackColor = $bgColor
        $tabControl.ForeColor = $fgColor
        
        # ====== CREATE TASK TAB ======
        $createTab = New-Object System.Windows.Forms.TabPage
        $createTab.Text = "Create Task"
        $createTab.BackColor = $bgColor
        $createTab.ForeColor = $fgColor
        
        # Task Name Label and TextBox
        $nameLabel = New-Object System.Windows.Forms.Label
        $nameLabel.Text = "Task Name:"
        $nameLabel.Location = New-Object System.Drawing.Point(20, 20)
        $nameLabel.Size = New-Object System.Drawing.Size(100, 20)
        $createTab.Controls.Add($nameLabel)
        
        $nameTextBox = New-Object System.Windows.Forms.TextBox
        $nameTextBox.Location = New-Object System.Drawing.Point(130, 20)
        $nameTextBox.Size = New-Object System.Drawing.Size(520, 25)
        $nameTextBox.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
        $nameTextBox.ForeColor = $fgColor
        $createTab.Controls.Add($nameTextBox)
        
        # Profile Label and ComboBox
        $profileLabel = New-Object System.Windows.Forms.Label
        $profileLabel.Text = "Profile:"
        $profileLabel.Location = New-Object System.Drawing.Point(20, 60)
        $profileLabel.Size = New-Object System.Drawing.Size(100, 20)
        $createTab.Controls.Add($profileLabel)
        
        $profileCombo = New-Object System.Windows.Forms.ComboBox
        $profileCombo.Location = New-Object System.Drawing.Point(130, 60)
        $profileCombo.Size = New-Object System.Drawing.Size(250, 25)
        $profileCombo.Items.AddRange(@('Minimal', 'Balanced', 'Maximum'))
        $profileCombo.DropDownStyle = "DropDownList"
        $profileCombo.SelectedIndex = 1  # Default to Balanced
        $profileCombo.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
        $profileCombo.ForeColor = $fgColor
        $createTab.Controls.Add($profileCombo)
        
        # Schedule Type Label and ComboBox
        $scheduleLabel = New-Object System.Windows.Forms.Label
        $scheduleLabel.Text = "Schedule:"
        $scheduleLabel.Location = New-Object System.Drawing.Point(400, 60)
        $scheduleLabel.Size = New-Object System.Drawing.Size(100, 20)
        $createTab.Controls.Add($scheduleLabel)
        
        $scheduleCombo = New-Object System.Windows.Forms.ComboBox
        $scheduleCombo.Location = New-Object System.Drawing.Point(500, 60)
        $scheduleCombo.Size = New-Object System.Drawing.Size(150, 25)
        $scheduleCombo.Items.AddRange(@('DAILY', 'WEEKLY', 'MONTHLY'))
        $scheduleCombo.DropDownStyle = "DropDownList"
        $scheduleCombo.SelectedIndex = 0  # Default to DAILY
        $scheduleCombo.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
        $scheduleCombo.ForeColor = $fgColor
        $createTab.Controls.Add($scheduleCombo)
        
        # Time Label and TextBox
        $timeLabel = New-Object System.Windows.Forms.Label
        $timeLabel.Text = "Time (HH:MM):"
        $timeLabel.Location = New-Object System.Drawing.Point(20, 100)
        $timeLabel.Size = New-Object System.Drawing.Size(100, 20)
        $createTab.Controls.Add($timeLabel)
        
        $timeTextBox = New-Object System.Windows.Forms.TextBox
        $timeTextBox.Location = New-Object System.Drawing.Point(130, 100)
        $timeTextBox.Size = New-Object System.Drawing.Size(100, 25)
        $timeTextBox.Text = "02:00"
        $timeTextBox.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
        $timeTextBox.ForeColor = $fgColor
        $createTab.Controls.Add($timeTextBox)
        
        # Dry Run Checkbox
        $dryRunCheckBox = New-Object System.Windows.Forms.CheckBox
        $dryRunCheckBox.Text = "Dry Run (no actual changes)"
        $dryRunCheckBox.Location = New-Object System.Drawing.Point(20, 145)
        $dryRunCheckBox.Size = New-Object System.Drawing.Size(300, 20)
        $dryRunCheckBox.ForeColor = $fgColor
        $dryRunCheckBox.Checked = $false
        $createTab.Controls.Add($dryRunCheckBox)
        
        # Quiet Mode Checkbox
        $quietCheckBox = New-Object System.Windows.Forms.CheckBox
        $quietCheckBox.Text = "Quiet Mode (hide UI)"
        $quietCheckBox.Location = New-Object System.Drawing.Point(20, 175)
        $quietCheckBox.Size = New-Object System.Drawing.Size(300, 20)
        $quietCheckBox.ForeColor = $fgColor
        $quietCheckBox.Checked = $false
        $createTab.Controls.Add($quietCheckBox)
        
        # Info Box
        $infoBox = New-Object System.Windows.Forms.TextBox
        $infoBox.Multiline = $true
        $infoBox.ReadOnly = $true
        $infoBox.Location = New-Object System.Drawing.Point(20, 210)
        $infoBox.Size = New-Object System.Drawing.Size(650, 150)
        $infoBox.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
        $infoBox.ForeColor = $fgColor
        $infoBox.Text = @"
Schedule Information:
  DAILY    - Runs at specified time every day
  WEEKLY   - Runs every Monday at specified time
  MONTHLY  - Runs on the 1st of each month at specified time

The task will execute as SYSTEM account with Highest privileges.
Enable Dry Run mode to preview changes without applying them.
Enable Quiet Mode to hide the UI during automated execution.
"@
        $createTab.Controls.Add($infoBox)
        
        # Create Task Button
        $createBtn = New-Object System.Windows.Forms.Button
        $createBtn.Text = "Create Task"
        $createBtn.Location = New-Object System.Drawing.Point(20, 370)
        $createBtn.Size = New-Object System.Drawing.Size(650, 35)
        $createBtn.BackColor = $accentColor
        $createBtn.ForeColor = "White"
        $createBtn.Cursor = "Hand"
        
        $createBtn.Add_Click({
            if ([string]::IsNullOrWhiteSpace($nameTextBox.Text)) {
                [System.Windows.Forms.MessageBox]::Show("Please enter a task name", "Validation Error", "OK", "Warning")
                return
            }
            
            if (-not (Validate-ScheduleTime -Time $timeTextBox.Text)) {
                [System.Windows.Forms.MessageBox]::Show("Invalid time format. Use HH:MM (24-hour)", "Validation Error", "OK", "Warning")
                return
            }
            
            $result = New-ScheduledTelemetryTask `
                -TaskName $nameTextBox.Text `
                -Profile $profileCombo.SelectedItem `
                -Schedule $scheduleCombo.SelectedItem `
                -Time $timeTextBox.Text `
                -DryRun $dryRunCheckBox.Checked `
                -Quiet $quietCheckBox.Checked
            
            if ($result.Success) {
                [System.Windows.Forms.MessageBox]::Show(
                    "Task created successfully!`n`nName: $($result.TaskName)`nSchedule: $($result.Schedule) at $($result.Time)`nProfile: $($result.Profile)",
                    "Success",
                    "OK",
                    "Information"
                )
                $nameTextBox.Clear()
                $timeTextBox.Text = "02:00"
                $dryRunCheckBox.Checked = $false
                $quietCheckBox.Checked = $false
                
                # Refresh manage tab
                Refresh-ManagedTasksList
            }
            else {
                [System.Windows.Forms.MessageBox]::Show(
                    "Error creating task: $($result.Error)",
                    "Error",
                    "OK",
                    "Error"
                )
            }
        })
        
        $createTab.Controls.Add($createBtn)
        
        # ====== MANAGE TASKS TAB ======
        $manageTab = New-Object System.Windows.Forms.TabPage
        $manageTab.Text = "Manage Tasks"
        $manageTab.BackColor = $bgColor
        $manageTab.ForeColor = $fgColor
        
        # Tasks ListBox
        $tasksListBox = New-Object System.Windows.Forms.ListBox
        $tasksListBox.Location = New-Object System.Drawing.Point(20, 20)
        $tasksListBox.Size = New-Object System.Drawing.Size(650, 300)
        $tasksListBox.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
        $tasksListBox.ForeColor = $fgColor
        $manageTab.Controls.Add($tasksListBox)
        
        # Task Details TextBox
        $detailsBox = New-Object System.Windows.Forms.TextBox
        $detailsBox.Multiline = $true
        $detailsBox.ReadOnly = $true
        $detailsBox.Location = New-Object System.Drawing.Point(20, 330)
        $detailsBox.Size = New-Object System.Drawing.Size(650, 140)
        $detailsBox.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
        $detailsBox.ForeColor = $fgColor
        $detailsBox.Text = "Select a task to view details"
        $manageTab.Controls.Add($detailsBox)
        
        # Refresh function
        $Refresh-ManagedTasksList = {
            $tasksListBox.Items.Clear()
            $tasks = Get-ScheduledTelemetryTasks
            
            foreach ($task in $tasks) {
                $enabledIndicator = if ($task.Enabled) { "âœ“" } else { "âœ—" }
                $displayText = "[$enabledIndicator] $($task.TaskName) [$($task.State)]"
                [void]$tasksListBox.Items.Add($displayText)
            }
        }
        
        # Selection change handler
        $tasksListBox.Add_SelectedIndexChanged({
            if ($tasksListBox.SelectedIndex -ge 0) {
                $taskName = $tasksListBox.SelectedItem.Split(']')[2].Trim().Split('[')[0]
                $details = Get-TaskDetails -TaskName $taskName
                
                if ($details) {
                    $detailsText = @"
Task: $($details.TaskName)
State: $($details.State)
Enabled: $($details.Enabled)
Last Run: $(if ($details.LastRunTime) { $details.LastRunTime.ToString("yyyy-MM-dd HH:mm:ss") } else { "Never" })
Next Run: $(if ($details.NextRunTime) { $details.NextRunTime.ToString("yyyy-MM-dd HH:mm:ss") } else { "Not scheduled" })
Last Result: $($details.LastTaskResult)
Missed Runs: $($details.NumberOfMissedRuns)
"@
                    $detailsBox.Text = $detailsText
                }
            }
        })
        
        # Button Panel
        $buttonPanel = New-Object System.Windows.Forms.Panel
        $buttonPanel.Location = New-Object System.Drawing.Point(20, 480)
        $buttonPanel.Size = New-Object System.Drawing.Size(650, 45)
        $buttonPanel.BackColor = $bgColor
        $manageTab.Controls.Add($buttonPanel)
        
        # Refresh Button
        $refreshBtn = New-Object System.Windows.Forms.Button
        $refreshBtn.Text = "Refresh"
        $refreshBtn.Location = New-Object System.Drawing.Point(0, 0)
        $refreshBtn.Size = New-Object System.Drawing.Size(90, 35)
        $refreshBtn.BackColor = $accentColor
        $refreshBtn.ForeColor = "White"
        $refreshBtn.Cursor = "Hand"
        $refreshBtn.Add_Click({ & $Refresh-ManagedTasksList })
        $buttonPanel.Controls.Add($refreshBtn)
        
        # Start Button
        $startBtn = New-Object System.Windows.Forms.Button
        $startBtn.Text = "Start"
        $startBtn.Location = New-Object System.Drawing.Point(95, 0)
        $startBtn.Size = New-Object System.Drawing.Size(90, 35)
        $startBtn.BackColor = $accentColor
        $startBtn.ForeColor = "White"
        $startBtn.Cursor = "Hand"
        $startBtn.Add_Click({
            if ($tasksListBox.SelectedIndex -ge 0) {
                $taskName = $tasksListBox.SelectedItem.Split(']')[2].Trim().Split('[')[0]
                Start-ScheduledTask -TaskName $taskName
                & $Refresh-ManagedTasksList
                [System.Windows.Forms.MessageBox]::Show("Task started", "Info", "OK", "Information")
            }
        })
        $buttonPanel.Controls.Add($startBtn)
        
        # Stop Button
        $stopBtn = New-Object System.Windows.Forms.Button
        $stopBtn.Text = "Stop"
        $stopBtn.Location = New-Object System.Drawing.Point(190, 0)
        $stopBtn.Size = New-Object System.Drawing.Size(90, 35)
        $stopBtn.BackColor = $accentColor
        $stopBtn.ForeColor = "White"
        $stopBtn.Cursor = "Hand"
        $stopBtn.Add_Click({
            if ($tasksListBox.SelectedIndex -ge 0) {
                $taskName = $tasksListBox.SelectedItem.Split(']')[2].Trim().Split('[')[0]
                Stop-ScheduledTaskForce -TaskName $taskName
                & $Refresh-ManagedTasksList
                [System.Windows.Forms.MessageBox]::Show("Task stopped", "Info", "OK", "Information")
            }
        })
        $buttonPanel.Controls.Add($stopBtn)
        
        # Delete Button
        $deleteBtn = New-Object System.Windows.Forms.Button
        $deleteBtn.Text = "Delete"
        $deleteBtn.Location = New-Object System.Drawing.Point(560, 0)
        $deleteBtn.Size = New-Object System.Drawing.Size(90, 35)
        $deleteBtn.BackColor = [System.Drawing.Color]::FromArgb(204, 41, 54)
        $deleteBtn.ForeColor = "White"
        $deleteBtn.Cursor = "Hand"
        $deleteBtn.Add_Click({
            if ($tasksListBox.SelectedIndex -ge 0) {
                $taskName = $tasksListBox.SelectedItem.Split(']')[2].Trim().Split('[')[0]
                $confirm = [System.Windows.Forms.MessageBox]::Show(
                    "Are you sure you want to delete task: $taskName?",
                    "Confirm Deletion",
                    "YesNo",
                    "Question"
                )
                
                if ($confirm -eq "Yes") {
                    Remove-ScheduledTelemetryTask -TaskName $taskName
                    & $Refresh-ManagedTasksList
                    $detailsBox.Clear()
                    [System.Windows.Forms.MessageBox]::Show("Task deleted", "Info", "OK", "Information")
                }
            }
        })
        $buttonPanel.Controls.Add($deleteBtn)
        
        # Add tabs to control
        [void]$tabControl.TabPages.Add($createTab)
        [void]$tabControl.TabPages.Add($manageTab)
        
        # Add control to dialog
        $dialog.Controls.Add($tabControl)
        
        # Load initial task list
        & $Refresh-ManagedTasksList
        
        # Show dialog
        $result = $dialog.ShowDialog()
        
        # Cleanup
        $dialog.Dispose()
        
        return $result
    }
    catch {
        Write-Host "Error showing scheduler dialog: $_" -ForegroundColor Red
        return "Error"
    }
}

# ============================================================================
# EXPORTS
# ============================================================================




