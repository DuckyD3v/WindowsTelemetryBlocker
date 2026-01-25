# ===============================
# GUI Launcher - Phase 2.1
# Windows Telemetry Blocker v1.0
# ===============================
# Main GUI window with full form layout and control management
# Integrates Phase 1 config system and Phase 2 GUI framework

param(
    [string]$DefaultProfile = "balanced",
    [switch]$DryRun = $false,
    [switch]$Quiet = $false
)

# ===============================
# Initialize Environment
# ===============================

$script:ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:ConfigPath = Join-Path (Split-Path -Parent $script:ScriptRoot) "config"
$script:SharedPath = Join-Path (Split-Path -Parent $script:ScriptRoot) "shared"

# Import dependencies
. (Join-Path $script:SharedPath "utils.ps1")
. (Join-Path $script:SharedPath "integration.ps1")
. (Join-Path $script:ConfigPath "config-manager.ps1")
. (Join-Path $script:ScriptRoot "theme-manager.ps1")
. (Join-Path $script:ScriptRoot "form-controls.ps1")
. (Join-Path $script:ScriptRoot "advanced-filtering.ps1")
. (Join-Path $script:ScriptRoot "event-handlers.ps1")
. (Join-Path $script:ScriptRoot "data-binding.ps1")

# Import scheduler modules
$schedulerPath = Join-Path (Split-Path -Parent $script:ScriptRoot) "scheduler"
. (Join-Path $schedulerPath "task-scheduler.ps1")
. (Join-Path $schedulerPath "scheduler-ui.ps1")

# Initialize logging
Initialize-Logging

Write-LogEntry "INFO" "Launcher GUI starting (Phase 2.1)"

# ===============================
# Global State
# ===============================

$script:FormState = @{
    SelectedProfile = $DefaultProfile
    SelectedApps = @()
    SelectedServices = @()
    DryRunMode = $DryRun
    QuietMode = $Quiet
    IsExecuting = $false
    Profiles = $null
    AllApps = @()
    AllServices = @()
    Theme = $null
    LogBuffer = @()
}

# ===============================
# Load Configuration
# ===============================

function Initialize-FormState {
    param()
    
    Write-LogEntry "INFO" "Initializing form state..."
    
    try {
        # Load profiles from config manager
        $config = @{}
        
        # Load profiles.json
        $profilesPath = Join-Path $script:ConfigPath "profiles.json"
        if (Test-Path $profilesPath) {
            $profilesJson = Get-Content $profilesPath -Raw | ConvertFrom-Json
            $script:FormState.Profiles = $profilesJson.profiles
            
            # Extract apps and services
            if ($profilesJson.PSObject.Properties.Name -contains "apps") {
                $script:FormState.AllApps = $profilesJson.apps | ConvertTo-Object
            }
            if ($profilesJson.PSObject.Properties.Name -contains "services") {
                $script:FormState.AllServices = $profilesJson.services | ConvertTo-Object
            }
        }
        
        Write-LogEntry "INFO" "Loaded $(($script:FormState.Profiles | Measure-Object).Count) profiles"
        Write-LogEntry "INFO" "Loaded $(($script:FormState.AllApps | Measure-Object).Count) apps, $(($script:FormState.AllServices | Measure-Object).Count) services"
        
        return $true
    }
    catch {
        Write-LogEntry "ERROR" "Failed to initialize form state: $_"
        return $false
    }
}

# ===============================
# Theme Management
# ===============================

function Initialize-Theme {
    param(
        [string]$ThemeName
    )
    
    Write-LogEntry "INFO" "Loading theme: $ThemeName"
    $script:FormState.Theme = Get-ApplicationTheme -ThemeName $ThemeName
    return $script:FormState.Theme
}

# ===============================
# Form Layout Building
# ===============================

function New-MainForm {
    param()
    
    Write-LogEntry "INFO" "Creating main form layout..."
    
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Windows Telemetry Blocker v1.0"
    $form.Width = 950
    $form.Height = 800
    $form.MinimumSize = New-Object System.Drawing.Size(800, 600)
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $form.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Font
    $form.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    
    # Apply theme
    $form.BackColor = $script:FormState.Theme.BackgroundColor
    $form.ForeColor = $script:FormState.Theme.ForegroundColor
    
    # Add padding and margins
    $form.Padding = New-Object System.Windows.Forms.Padding(10)
    
    return $form
}

function New-ProfilePanel {
    param(
        [System.Windows.Forms.Form]$Form
    )
    
    Write-LogEntry "INFO" "Creating profile selector panel..."
    
    $panel = New-StyledPanel -Width ($Form.ClientSize.Width - 20) -Height 80 -Theme $script:FormState.Theme
    $panel.Location = New-Object System.Drawing.Point(10, 10)
    $panel.Text = "Profile Selection"
    $panel.Padding = New-Object System.Windows.Forms.Padding(10)
    
    # Label
    $lbl = New-StyledLabel -Text "Select Profile:" -Theme $script:FormState.Theme
    $lbl.Location = New-Object System.Drawing.Point(10, 15)
    $lbl.AutoSize = $true
    $panel.Controls.Add($lbl)
    
    # Combo box with profiles
    $combo = New-StyledComboBox -Theme $script:FormState.Theme
    $combo.Location = New-Object System.Drawing.Point(120, 12)
    $combo.Width = 200
    $combo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    
    # Add profile names
    if ($script:FormState.Profiles) {
        foreach ($profile in $script:FormState.Profiles) {
            $combo.Items.Add($profile.name) | Out-Null
        }
        $combo.SelectedItem = $script:FormState.SelectedProfile
    }
    
    $combo.Add_SelectedIndexChanged({
        $script:FormState.SelectedProfile = $combo.SelectedItem
        Write-LogEntry "INFO" "Profile changed to: $($combo.SelectedItem)"
        Update-SelectionsFromProfile -ProfileName $combo.SelectedItem
    })
    
    $panel.Controls.Add($combo)
    
    # Description label
    $descLabel = New-StyledLabel -Text "Description will appear here" -Theme $script:FormState.Theme
    $descLabel.Location = New-Object System.Drawing.Point(10, 40)
    $descLabel.Width = 400
    $descLabel.Height = 30
    $descLabel.AutoSize = $false
    $descLabel.Name = "DescriptionLabel"
    $panel.Controls.Add($descLabel)
    
    # Add to form
    $Form.Controls.Add($panel)
    return @{
        Panel = $panel
        ComboBox = $combo
        DescriptionLabel = $descLabel
    }
}

function New-SelectionPanels {
    param(
        [System.Windows.Forms.Form]$Form,
        [int]$TopPosition
    )
    
    Write-LogEntry "INFO" "Creating app/service selection panels..."
    
    # Create container panel
    $container = New-Object System.Windows.Forms.Panel
    $container.Location = New-Object System.Drawing.Point(10, $TopPosition)
    $container.Width = $Form.ClientSize.Width - 20
    $container.Height = 280
    $container.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $container.BackColor = $script:FormState.Theme.PanelColor
    
    # Apps panel (left side)
    $appsPanel = New-Object System.Windows.Forms.GroupBox
    $appsPanel.Text = "Applications to Remove"
    $appsPanel.Location = New-Object System.Drawing.Point(5, 5)
    $appsPanel.Width = ($container.Width - 20) / 2
    $appsPanel.Height = $container.Height - 10
    $appsPanel.BackColor = $script:FormState.Theme.ControlColor
    $appsPanel.ForeColor = $script:FormState.Theme.ForegroundColor
    
    # Apps list box
    $appsListBox = New-Object System.Windows.Forms.ListBox
    $appsListBox.Location = New-Object System.Drawing.Point(10, 25)
    $appsListBox.Width = $appsPanel.Width - 20
    $appsListBox.Height = $appsPanel.Height - 40
    $appsListBox.SelectionMode = [System.Windows.Forms.SelectionMode]::MultiSimple
    $appsListBox.BackColor = $script:FormState.Theme.ControlColor
    $appsListBox.ForeColor = $script:FormState.Theme.ForegroundColor
    $appsListBox.Name = "AppsListBox"
    
    # Populate apps
    foreach ($app in $script:FormState.AllApps) {
        $appsListBox.Items.Add($app.displayName) | Out-Null
    }
    
    $appsPanel.Controls.Add($appsListBox)
    $container.Controls.Add($appsPanel)
    
    # Services panel (right side)
    $servicesPanel = New-Object System.Windows.Forms.GroupBox
    $servicesPanel.Text = "Services to Disable"
    $servicesPanel.Location = New-Object System.Drawing.Point(($container.Width / 2) + 5, 5)
    $servicesPanel.Width = ($container.Width - 20) / 2
    $servicesPanel.Height = $container.Height - 10
    $servicesPanel.BackColor = $script:FormState.Theme.ControlColor
    $servicesPanel.ForeColor = $script:FormState.Theme.ForegroundColor
    
    # Services list box
    $servicesListBox = New-Object System.Windows.Forms.ListBox
    $servicesListBox.Location = New-Object System.Drawing.Point(10, 25)
    $servicesListBox.Width = $servicesPanel.Width - 20
    $servicesListBox.Height = $servicesPanel.Height - 40
    $servicesListBox.SelectionMode = [System.Windows.Forms.SelectionMode]::MultiSimple
    $servicesListBox.BackColor = $script:FormState.Theme.ControlColor
    $servicesListBox.ForeColor = $script:FormState.Theme.ForegroundColor
    $servicesListBox.Name = "ServicesListBox"
    
    # Populate services
    foreach ($service in $script:FormState.AllServices) {
        $servicesListBox.Items.Add($service.displayName) | Out-Null
    }
    
    $servicesPanel.Controls.Add($servicesListBox)
    $container.Controls.Add($servicesPanel)
    
    $Form.Controls.Add($container)
    
    return @{
        Container = $container
        AppsPanel = $appsPanel
        AppsListBox = $appsListBox
        ServicesPanel = $servicesPanel
        ServicesListBox = $servicesListBox
    }
}

function New-ControlsPanel {
    param(
        [System.Windows.Forms.Form]$Form,
        [int]$TopPosition
    )
    
    Write-LogEntry "INFO" "Creating options and controls panel..."
    
    $panel = New-StyledPanel -Width ($Form.ClientSize.Width - 20) -Height 60 -Theme $script:FormState.Theme
    $panel.Location = New-Object System.Drawing.Point(10, $TopPosition)
    $panel.Text = "Options"
    $panel.Padding = New-Object System.Windows.Forms.Padding(10)
    
    # Dry Run checkbox
    $dryRunCheck = New-StyledCheckBox -Text "Dry Run Mode" -Theme $script:FormState.Theme
    $dryRunCheck.Location = New-Object System.Drawing.Point(10, 15)
    $dryRunCheck.Checked = $script:FormState.DryRunMode
    $dryRunCheck.Name = "DryRunCheckBox"
    $panel.Controls.Add($dryRunCheck)
    
    # Quiet mode checkbox
    $quietCheck = New-StyledCheckBox -Text "Quiet Mode" -Theme $script:FormState.Theme
    $quietCheck.Location = New-Object System.Drawing.Point(180, 15)
    $quietCheck.Checked = $script:FormState.QuietMode
    $quietCheck.Name = "QuietCheckBox"
    $panel.Controls.Add($quietCheck)
    
    # Execute button
    $executeBtn = New-StyledButton -Text "Execute" -Theme $script:FormState.Theme
    $executeBtn.Location = New-Object System.Drawing.Point(350, 12)
    $executeBtn.Width = 100
    $executeBtn.Name = "ExecuteButton"
    $executeBtn.Add_Click({
        Start-Execution -Form $Form -DryRun $dryRunCheck.Checked -Quiet $quietCheck.Checked
    })
    $panel.Controls.Add($executeBtn)
    
    # Cancel button
    $cancelBtn = New-StyledButton -Text "Cancel" -Theme $script:FormState.Theme
    $cancelBtn.Location = New-Object System.Drawing.Point(460, 12)
    $cancelBtn.Width = 100
    $cancelBtn.Name = "CancelButton"
    $cancelBtn.Add_Click({
        $Form.Close()
    })
    $panel.Controls.Add($cancelBtn)
    
    # Advanced button
    $advancedBtn = New-StyledButton -Text "Advanced ≡" -Theme $script:FormState.Theme
    $advancedBtn.Location = New-Object System.Drawing.Point(570, 12)
    $advancedBtn.Width = 100
    $advancedBtn.Name = "AdvancedButton"
    $advancedBtn.Add_Click({
        Show-AdvancedOptionsDialog -Owner $Form
    })
    $panel.Controls.Add($advancedBtn)
    
    $Form.Controls.Add($panel)
    
    return @{
        Panel = $panel
        DryRunCheckBox = $dryRunCheck
        QuietCheckBox = $quietCheck
        ExecuteButton = $executeBtn
        CancelButton = $cancelBtn
        AdvancedButton = $advancedBtn
    }
}

function New-ProgressPanel {
    param(
        [System.Windows.Forms.Form]$Form,
        [int]$TopPosition
    )
    
    Write-LogEntry "INFO" "Creating progress panel..."
    
    $panel = New-StyledPanel -Width ($Form.ClientSize.Width - 20) -Height 50 -Theme $script:FormState.Theme
    $panel.Location = New-Object System.Drawing.Point(10, $TopPosition)
    $panel.Text = "Progress"
    $panel.Padding = New-Object System.Windows.Forms.Padding(10)
    
    # Progress bar
    $progressBar = New-StyledProgressBar -Width ($panel.Width - 30) -Height 20 -Theme $script:FormState.Theme
    $progressBar.Location = New-Object System.Drawing.Point(10, 20)
    $progressBar.Minimum = 0
    $progressBar.Maximum = 100
    $progressBar.Value = 0
    $progressBar.Name = "ProgressBar"
    $panel.Controls.Add($progressBar)
    
    # Status label
    $statusLabel = New-StyledLabel -Text "Ready" -Theme $script:FormState.Theme
    $statusLabel.Location = New-Object System.Drawing.Point(10, 45)
    $statusLabel.AutoSize = $true
    $statusLabel.Name = "StatusLabel"
    $panel.Controls.Add($statusLabel)
    
    $Form.Controls.Add($panel)
    
    return @{
        Panel = $panel
        ProgressBar = $progressBar
        StatusLabel = $statusLabel
    }
}

function New-LogViewerPanel {
    param(
        [System.Windows.Forms.Form]$Form,
        [int]$TopPosition
    )
    
    Write-LogEntry "INFO" "Creating log viewer panel..."
    
    $panel = New-StyledPanel -Width ($Form.ClientSize.Width - 20) -Height 120 -Theme $script:FormState.Theme
    $panel.Location = New-Object System.Drawing.Point(10, $TopPosition)
    $panel.Text = "Execution Log"
    $panel.Padding = New-Object System.Windows.Forms.Padding(10)
    
    # Log text box
    $logBox = New-Object System.Windows.Forms.TextBox
    $logBox.Location = New-Object System.Drawing.Point(10, 20)
    $logBox.Width = $panel.Width - 30
    $logBox.Height = $panel.Height - 45
    $logBox.Multiline = $true
    $logBox.ReadOnly = $true
    $logBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
    $logBox.BackColor = $script:FormState.Theme.ControlColor
    $logBox.ForeColor = $script:FormState.Theme.ForegroundColor
    $logBox.Font = New-Object System.Drawing.Font("Consolas", 9)
    $logBox.Name = "LogBox"
    $panel.Controls.Add($logBox)
    
    # Clear button
    $clearBtn = New-StyledButton -Text "Clear" -Theme $script:FormState.Theme
    $clearBtn.Location = New-Object System.Drawing.Point(10, $panel.Height - 25)
    $clearBtn.Width = 80
    $clearBtn.Add_Click({
        $logBox.Clear()
        $script:FormState.LogBuffer = @()
    })
    $panel.Controls.Add($clearBtn)
    
    $Form.Controls.Add($panel)
    
    return @{
        Panel = $panel
        LogBox = $logBox
        ClearButton = $clearBtn
    }
}

# ===============================
# Profile Management
# ===============================

function Update-SelectionsFromProfile {
    param(
        [string]$ProfileName
    )
    
    Write-LogEntry "INFO" "Updating selections from profile: $ProfileName"
    
    $profile = $script:FormState.Profiles | Where-Object { $_.name -eq $ProfileName }
    if ($profile) {
        $script:FormState.SelectedApps = @($profile.apps)
        $script:FormState.SelectedServices = @($profile.services)
        Write-LogEntry "INFO" "Selected $($profile.apps.Count) apps and $($profile.services.Count) services"
    }
}

# ===============================
# Execution
# ===============================

function Start-Execution {
    param(
        [System.Windows.Forms.Form]$Form,
        [bool]$DryRun = $false,
        [bool]$Quiet = $false
    )
    
    # Update form state
    $script:FormState.DryRunMode = $DryRun
    $script:FormState.QuietMode = $Quiet
    
    # Get UI controls
    $progressPanel = $Form.Controls["ProgressPanel"]
    $progressBar = $progressPanel.Controls["ProgressBar"]
    $statusLabel = $progressPanel.Controls["StatusLabel"]
    
    $logPanel = $Form.Controls["LogPanel"]
    $logBox = $logPanel.Controls["LogBox"]
    
    # Use event handler pipeline
    $executeBtn = New-ExecuteButtonHandler -FormState $script:FormState -Form $Form `
        -DryRunCheckBox ($Form.Controls["ControlsPanel"].DryRunCheckBox) `
        -QuietCheckBox ($Form.Controls["ControlsPanel"].QuietCheckBox) `
        -ProgressBar $progressBar -StatusLabel $statusLabel -LogBox $logBox
    
    & $executeBtn
}

function Log-Message {
    param(
        [System.Windows.Forms.TextBox]$LogBox,
        [string]$Level = "INFO",
        [string]$Message
    )
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    $script:FormState.LogBuffer += $logEntry
    $LogBox.AppendText($logEntry + "`r`n")
    $LogBox.ScrollToCaret()
    
    Write-LogEntry $Level $Message
}

# ===============================
# Advanced Options Dialog
# ===============================

function Show-SystemInfoDialog {
    param(
        [System.Windows.Forms.Form]$Owner
    )
    
    Write-LogEntry "INFO" "Opening system information dialog..."
    
    $sysInfo = Get-SystemInfo
    
    $dialog = New-Object System.Windows.Forms.Form
    $dialog.Text = "System Information"
    $dialog.Width = 500
    $dialog.Height = 400
    $dialog.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterParent
    $dialog.Owner = $Owner
    $dialog.BackColor = $script:FormState.Theme.BackgroundColor
    $dialog.ForeColor = $script:FormState.Theme.ForegroundColor
    
    # Create text box with system info
    $infoBox = New-Object System.Windows.Forms.TextBox
    $infoBox.Location = New-Object System.Drawing.Point(10, 10)
    $infoBox.Width = $dialog.Width - 30
    $infoBox.Height = $dialog.Height - 70
    $infoBox.Multiline = $true
    $infoBox.ReadOnly = $true
    $infoBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
    $infoBox.Font = New-Object System.Drawing.Font("Consolas", 9)
    $infoBox.BackColor = $script:FormState.Theme.ControlColor
    $infoBox.ForeColor = $script:FormState.Theme.ForegroundColor
    
    $infoText = @"
=== System Information ===

Windows Version: $($sysInfo.OSVersion)
Computer Name: $($sysInfo.ComputerName)
Username: $($sysInfo.UserName)
Admin Privilege: $(Test-AdminPrivilege)

=== Telemetry Blocker Info ===

Installation Path: $(Split-Path -Parent $script:ScriptRoot)
Config Path: $script:ConfigPath
Profiles Loaded: $(@($script:FormState.Profiles).Count)
Apps Available: $(@($script:FormState.AllApps).Count)
Services Available: $(@($script:FormState.AllServices).Count)

=== Execution Logs ===

$($script:FormState.LogBuffer -join "`r`n")
"@
    
    $infoBox.Text = $infoText
    $dialog.Controls.Add($infoBox)
    
    # Close button
    $closeBtn = New-StyledButton -Text "Close" -Theme $script:FormState.Theme
    $closeBtn.Location = New-Object System.Drawing.Point(10, $dialog.Height - 50)
    $closeBtn.Width = 100
    $closeBtn.Add_Click({
        $dialog.Close()
    })
    $dialog.Controls.Add($closeBtn)
    
    [void]$dialog.ShowDialog()
}

function Show-AdvancedOptionsDialog {
    param(
        [System.Windows.Forms.Form]$Owner
    )
    
    Write-LogEntry "INFO" "Opening advanced options dialog..."
    
    $dialog = New-Object System.Windows.Forms.Form
    $dialog.Text = "Advanced Options"
    $dialog.Width = 550
    $dialog.Height = 550
    $dialog.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterParent
    $dialog.Owner = $Owner
    $dialog.BackColor = $script:FormState.Theme.BackgroundColor
    $dialog.ForeColor = $script:FormState.Theme.ForegroundColor
    
    # Theme selector (Phase 2.4)
    $themeLbl = New-StyledLabel -Text "Theme:" -Theme $script:FormState.Theme
    $themeLbl.Location = New-Object System.Drawing.Point(20, 20)
    $dialog.Controls.Add($themeLbl)
    
    $themeCombo = New-StyledComboBox -Theme $script:FormState.Theme
    $themeCombo.Location = New-Object System.Drawing.Point(150, 20)
    $themeCombo.Width = 200
    $themeCombo.Items.AddRange(@("dark", "light", "high-contrast"))
    $themeCombo.SelectedItem = (Get-UserTheme)
    $themeCombo.Add_SelectedIndexChanged({
        $newTheme = Get-ApplicationTheme -ThemeName $themeCombo.SelectedItem
        Save-UserTheme -ThemeName $themeCombo.SelectedItem
        Write-LogEntry "INFO" "Theme changed to: $($themeCombo.SelectedItem)"
        Update-UserPreferences -Key "theme" -Value $themeCombo.SelectedItem
    })
    $dialog.Controls.Add($themeCombo)
    
    # Advanced Filtering (Phase 3)
    $filterBtn = New-StyledButton -Text "Advanced Filter (Phase 3)" -Theme $script:FormState.Theme
    $filterBtn.Location = New-Object System.Drawing.Point(20, 70)
    $filterBtn.Width = 300
    $filterBtn.Add_Click({
        Show-AdvancedFilterDialog -Owner $dialog -Theme $script:FormState.Theme
    })
    $dialog.Controls.Add($filterBtn)
    
    # Custom profile creation (Phase 2.4)
    $customProfileBtn = New-StyledButton -Text "Create Custom Profile (Phase 2.4)" -Theme $script:FormState.Theme
    $customProfileBtn.Location = New-Object System.Drawing.Point(20, 120)
    $customProfileBtn.Width = 300
    $customProfileBtn.Add_Click({
        Show-CustomProfileDialog -Owner $dialog -Theme $script:FormState.Theme
    })
    $dialog.Controls.Add($customProfileBtn)
    
    # Task Scheduler (Phase 4)
    $schedulerBtn = New-StyledButton -Text "Task Scheduler (Phase 4)" -Theme $script:FormState.Theme
    $schedulerBtn.Location = New-Object System.Drawing.Point(20, 170)
    $schedulerBtn.Width = 300
    $schedulerBtn.Add_Click({
        Show-SchedulerDialog -Owner $dialog -Theme $script:FormState.Theme
    })
    $dialog.Controls.Add($schedulerBtn)
    
    # Import profile button
    $importBtn = New-StyledButton -Text "Import Custom Profile" -Theme $script:FormState.Theme
    $importBtn.Location = New-Object System.Drawing.Point(20, 220)
    $importBtn.Width = 300
    $importBtn.Add_Click({
        $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $openFileDialog.Filter = "JSON files (*.json)|*.json|All files (*.*)|*.*"
        if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $success = Import-Profile -ImportPath $openFileDialog.FileName
            if ($success) {
                [System.Windows.Forms.MessageBox]::Show("Profile imported successfully!", "Success")
            }
        }
    })
    $dialog.Controls.Add($importBtn)
    
    # Export config button
    $exportBtn = New-StyledButton -Text "Export Configuration" -Theme $script:FormState.Theme
    $exportBtn.Location = New-Object System.Drawing.Point(20, 270)
    $exportBtn.Width = 300
    $exportBtn.Add_Click({
        & (Join-Path $script:ConfigPath "config-manager.ps1") -Action export
        Write-LogEntry "INFO" "Configuration exported"
        [System.Windows.Forms.MessageBox]::Show("Configuration exported to user directory", "Success")
    })
    $dialog.Controls.Add($exportBtn)
    
    # System Info button
    $systemBtn = New-StyledButton -Text "System Information" -Theme $script:FormState.Theme
    $systemBtn.Location = New-Object System.Drawing.Point(20, 320)
    $systemBtn.Width = 300
    $systemBtn.Add_Click({
        Show-SystemInfoDialog -Owner $dialog
    })
    $dialog.Controls.Add($systemBtn)
    
    # Statistics button (Phase 2.4)
    $statsBtn = New-StyledButton -Text "Selection Statistics (Phase 2.4)" -Theme $script:FormState.Theme
    $statsBtn.Location = New-Object System.Drawing.Point(20, 370)
    $statsBtn.Width = 300
    $statsBtn.Add_Click({
        $stats = Get-SelectionStatistics -FormState $script:FormState `
            -SelectedApps $script:FormState.SelectedApps `
            -SelectedServices $script:FormState.SelectedServices
        
        $statsMsg = @"
Apps: $($stats.Apps.SelectedApps)/$($stats.Apps.TotalApps) selected
Services: $($stats.Services.SelectedServices)/$($stats.Services.TotalServices) selected
Critical Services: $($stats.Services.CriticalSelected) of $($stats.Services.CriticalServices) selected
Overall Selection: $($stats.SelectionPercentage)%
"@
        
        [System.Windows.Forms.MessageBox]::Show($statsMsg, "Selection Statistics")
    })
    $dialog.Controls.Add($statsBtn)
    
    # Close button
    $closeBtn = New-StyledButton -Text "Close" -Theme $script:FormState.Theme
    $closeBtn.Location = New-Object System.Drawing.Point(20, $dialog.Height - 50)
    $closeBtn.Width = 100
    $closeBtn.Add_Click({
        $dialog.Close()
    })
    $dialog.Controls.Add($closeBtn)
    
    [void]$dialog.ShowDialog()
}

# ===============================
# Main Execution
# ===============================

function Main {
    Write-LogEntry "INFO" "=== GUI Launcher Started (Phase 2.2 Data Binding) ==="
    
    # Check admin privileges
    if (-not (Test-AdminPrivilege)) {
        Require-AdminPrivilege
        return
    }
    
    # Initialize
    if (-not (Initialize-FormState)) {
        Write-LogEntry "ERROR" "Failed to initialize form state"
        [System.Windows.Forms.MessageBox]::Show("Failed to initialize. See log for details.", "Error")
        return
    }
    
    # Load user preferences (Phase 2.2)
    $userPrefs = Get-UserPreferences
    
    # Load theme
    Initialize-Theme -ThemeName $userPrefs.theme
    
    # Create main form
    $form = New-MainForm
    
    # Build layout panels
    $topPos = 10
    
    $profilePanel = New-ProfilePanel -Form $form
    $form.Controls.Add($profilePanel.Panel)
    $topPos += 90
    
    $selectionPanel = New-SelectionPanels -Form $form -TopPosition $topPos
    $selectionPanel.Container.Name = "SelectionPanel"
    $topPos += 290
    
    $controlsPanel = New-ControlsPanel -Form $form -TopPosition $topPos
    $controlsPanel.Panel.Name = "ControlsPanel"
    $topPos += 70
    
    $progressPanel = New-ProgressPanel -Form $form -TopPosition $topPos
    $progressPanel.Panel.Name = "ProgressPanel"
    $topPos += 60
    
    $logPanel = New-LogViewerPanel -Form $form -TopPosition $topPos
    $logPanel.Panel.Name = "LogPanel"
    
    # ===== Phase 2.2: Data Binding Integration =====
    Write-LogEntry "INFO" "Initializing data binding (Phase 2.2)..."
    
    # Load all content dynamically (Phase 2.2)
    Refresh-AllContent -ProfileCombo $profilePanel.ComboBox `
        -AppsListBox $selectionPanel.AppsListBox `
        -ServicesListBox $selectionPanel.ServicesListBox `
        -DescriptionLabel $profilePanel.DescriptionLabel `
        -FormState $script:FormState
    
    # Wire profile change handler (Phase 2.2)
    $profileChangeHandler = New-ProfileChangeHandler -ProfileCombo $profilePanel.ComboBox `
        -AppsListBox $selectionPanel.AppsListBox `
        -ServicesListBox $selectionPanel.ServicesListBox `
        -DescriptionLabel $profilePanel.DescriptionLabel `
        -FormState $script:FormState
    
    $profilePanel.ComboBox.Add_SelectedIndexChanged($profileChangeHandler)
    
    # Wire selection change handlers (Phase 2.2)
    $appsChangeHandler = New-SelectionChangeHandler -ListBox $selectionPanel.AppsListBox `
        -FormState $script:FormState -SelectionType "Apps"
    $selectionPanel.AppsListBox.Add_SelectedIndexChanged($appsChangeHandler)
    
    $servicesChangeHandler = New-SelectionChangeHandler -ListBox $selectionPanel.ServicesListBox `
        -FormState $script:FormState -SelectionType "Services"
    $selectionPanel.ServicesListBox.Add_SelectedIndexChanged($servicesChangeHandler)
    
    Write-LogEntry "INFO" "Form layout complete with data binding (Phase 2.2)"
    
    # Show form
    [void]$form.ShowDialog()
    
    Write-LogEntry "INFO" "=== GUI Launcher Closed ==="
}

# Run main
Main
