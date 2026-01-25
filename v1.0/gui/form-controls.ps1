# ===============================
# GUI Form Controls Library
# v1.0 - Reusable Control Components
# ===============================

<#
.SYNOPSIS
Provides reusable Windows Forms controls for GUI

.DESCRIPTION
Custom control builders and helpers for consistent styling and functionality
across the GUI application.
#>

# ===============================
# Custom Control Builders
# ===============================

function New-StyledButton {
    <#
    .SYNOPSIS
    Create a styled button with theme colors
    #>
    param(
        [parameter(Mandatory)]
        [string]$Text,
        
        [int]$Width = 100,
        [int]$Height = 35,
        [int]$Left = 0,
        [int]$Top = 0,
        
        [hashtable]$Theme = $null,
        [scriptblock]$OnClick = $null
    )
    
    $button = New-Object System.Windows.Forms.Button
    $button.Text = $Text
    $button.Width = $Width
    $button.Height = $Height
    $button.Left = $Left
    $button.Top = $Top
    $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $button.AutoSize = $false
    
    if ($Theme) {
        $button.BackColor = $Theme.AccentColor
        $button.ForeColor = $Theme.ForegroundColor
        $button.FlatAppearance.BorderColor = $Theme.AccentDarkColor
        $button.FlatAppearance.BorderSize = 1
    }
    
    if ($OnClick) {
        $button.Add_Click($OnClick)
    }
    
    return $button
}

function New-StyledLabel {
    <#
    .SYNOPSIS
    Create a styled label
    #>
    param(
        [parameter(Mandatory)]
        [string]$Text,
        
        [int]$Width = 200,
        [int]$Height = 25,
        [int]$Left = 0,
        [int]$Top = 0,
        
        [hashtable]$Theme = $null,
        
        [ValidateSet("Normal", "Large", "Small")]
        [string]$FontSize = "Normal"
    )
    
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $Text
    $label.Width = $Width
    $label.Height = $Height
    $label.Left = $Left
    $label.Top = $Top
    $label.AutoSize = $false
    $label.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    
    # Font sizing
    $fontSize = if ($FontSize -eq "Large") { 12 } elseif ($FontSize -eq "Small") { 9 } else { 10 }
    $label.Font = New-Object System.Drawing.Font("Segoe UI", $fontSize)
    
    if ($Theme) {
        $label.BackColor = $Theme.PanelColor
        $label.ForeColor = $Theme.ForegroundColor
    }
    
    return $label
}

function New-StyledPanel {
    <#
    .SYNOPSIS
    Create a styled panel
    #>
    param(
        [int]$Width = 400,
        [int]$Height = 300,
        [int]$Left = 0,
        [int]$Top = 0,
        
        [hashtable]$Theme = $null,
        [switch]$Bordered = $false
    )
    
    $panel = New-Object System.Windows.Forms.Panel
    $panel.Width = $Width
    $panel.Height = $Height
    $panel.Left = $Left
    $panel.Top = $Top
    $panel.AutoSize = $false
    
    if ($Theme) {
        $panel.BackColor = $Theme.PanelColor
        if ($Bordered) {
            $panel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
        }
    }
    
    return $panel
}

function New-StyledCheckBox {
    <#
    .SYNOPSIS
    Create a styled checkbox
    #>
    param(
        [parameter(Mandatory)]
        [string]$Text,
        
        [bool]$Checked = $false,
        [int]$Width = 300,
        [int]$Height = 25,
        [int]$Left = 0,
        [int]$Top = 0,
        
        [hashtable]$Theme = $null,
        [scriptblock]$OnCheckedChanged = $null
    )
    
    $checkbox = New-Object System.Windows.Forms.CheckBox
    $checkbox.Text = $Text
    $checkbox.Checked = $Checked
    $checkbox.Width = $Width
    $checkbox.Height = $Height
    $checkbox.Left = $Left
    $checkbox.Top = $Top
    $checkbox.AutoSize = $false
    
    if ($Theme) {
        $checkbox.BackColor = $Theme.PanelColor
        $checkbox.ForeColor = $Theme.ForegroundColor
    }
    
    if ($OnCheckedChanged) {
        $checkbox.Add_CheckedChanged($OnCheckedChanged)
    }
    
    return $checkbox
}

function New-StyledComboBox {
    <#
    .SYNOPSIS
    Create a styled combo box
    #>
    param(
        [string[]]$Items = @(),
        [int]$SelectedIndex = 0,
        [int]$Width = 300,
        [int]$Height = 30,
        [int]$Left = 0,
        [int]$Top = 0,
        
        [hashtable]$Theme = $null,
        [scriptblock]$OnSelectedIndexChanged = $null
    )
    
    $comboBox = New-Object System.Windows.Forms.ComboBox
    $comboBox.Width = $Width
    $comboBox.Height = $Height
    $comboBox.Left = $Left
    $comboBox.Top = $Top
    $comboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $comboBox.AutoSize = $false
    
    foreach ($item in $Items) {
        $comboBox.Items.Add($item) | Out-Null
    }
    
    if ($Items.Count -gt 0) {
        $comboBox.SelectedIndex = $SelectedIndex
    }
    
    if ($Theme) {
        $comboBox.BackColor = $Theme.ControlBackColor
        $comboBox.ForeColor = $Theme.ControlForeColor
    }
    
    if ($OnSelectedIndexChanged) {
        $comboBox.Add_SelectedIndexChanged($OnSelectedIndexChanged)
    }
    
    return $comboBox
}

function New-StyledTextBox {
    <#
    .SYNOPSIS
    Create a styled text box
    #>
    param(
        [string]$Text = "",
        [int]$Width = 300,
        [int]$Height = 25,
        [int]$Left = 0,
        [int]$Top = 0,
        
        [hashtable]$Theme = $null,
        [switch]$Multiline = $false,
        [switch]$ReadOnly = $false
    )
    
    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Text = $Text
    $textBox.Width = $Width
    $textBox.Height = $Height
    $textBox.Left = $Left
    $textBox.Top = $Top
    $textBox.Multiline = $Multiline
    $textBox.ReadOnly = $ReadOnly
    $textBox.AutoSize = $false
    
    if ($Multiline) {
        $textBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Both
    }
    
    if ($Theme) {
        $textBox.BackColor = $Theme.ControlBackColor
        $textBox.ForeColor = $Theme.ControlForeColor
        $textBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    }
    
    return $textBox
}

function New-StyledListBox {
    <#
    .SYNOPSIS
    Create a styled list box
    #>
    param(
        [string[]]$Items = @(),
        [int]$Width = 300,
        [int]$Height = 200,
        [int]$Left = 0,
        [int]$Top = 0,
        
        [hashtable]$Theme = $null
    )
    
    $listBox = New-Object System.Windows.Forms.ListBox
    $listBox.Width = $Width
    $listBox.Height = $Height
    $listBox.Left = $Left
    $listBox.Top = $Top
    $listBox.AutoSize = $false
    
    foreach ($item in $Items) {
        $listBox.Items.Add($item) | Out-Null
    }
    
    if ($Theme) {
        $listBox.BackColor = $Theme.ControlBackColor
        $listBox.ForeColor = $Theme.ControlForeColor
    }
    
    return $listBox
}

function New-StyledProgressBar {
    <#
    .SYNOPSIS
    Create a styled progress bar
    #>
    param(
        [int]$Width = 500,
        [int]$Height = 25,
        [int]$Left = 0,
        [int]$Top = 0,
        
        [hashtable]$Theme = $null,
        [int]$Minimum = 0,
        [int]$Maximum = 100
    )
    
    $progressBar = New-Object System.Windows.Forms.ProgressBar
    $progressBar.Width = $Width
    $progressBar.Height = $Height
    $progressBar.Left = $Left
    $progressBar.Top = $Top
    $progressBar.Minimum = $Minimum
    $progressBar.Maximum = $Maximum
    $progressBar.AutoSize = $false
    
    if ($Theme) {
        # ProgressBar theming is limited in .NET 4.0
        # We can only set ForeColor which acts as the progress color
        $progressBar.ForeColor = $Theme.AccentColor
    }
    
    return $progressBar
}

function New-StyledGroupBox {
    <#
    .SYNOPSIS
    Create a styled group box
    #>
    param(
        [parameter(Mandatory)]
        [string]$Text,
        
        [int]$Width = 400,
        [int]$Height = 200,
        [int]$Left = 0,
        [int]$Top = 0,
        
        [hashtable]$Theme = $null
    )
    
    $groupBox = New-Object System.Windows.Forms.GroupBox
    $groupBox.Text = $Text
    $groupBox.Width = $Width
    $groupBox.Height = $Height
    $groupBox.Left = $Left
    $groupBox.Top = $Top
    $groupBox.AutoSize = $false
    
    if ($Theme) {
        $groupBox.BackColor = $Theme.PanelColor
        $groupBox.ForeColor = $Theme.ForegroundColor
    }
    
    return $groupBox
}

# ===============================
# Custom Controls
# ===============================

function New-ModuleCheckBox {
    <#
    .SYNOPSIS
    Create a checkbox for module selection with description tooltip
    #>
    param(
        [parameter(Mandatory)]
        [string]$ModuleName,
        
        [parameter(Mandatory)]
        [string]$DisplayName,
        
        [string]$Description = "",
        [bool]$Checked = $false,
        [int]$Left = 10,
        [int]$Top = 10,
        
        [hashtable]$Theme = $null
    )
    
    $checkbox = New-StyledCheckBox -Text $DisplayName -Checked $Checked `
        -Width 300 -Height 25 -Left $Left -Top $Top -Theme $Theme
    
    # Add tooltip with description
    if ($Description) {
        $tooltip = New-Object System.Windows.Forms.ToolTip
        $tooltip.SetToolTip($checkbox, $Description)
    }
    
    # Store module name as tag for reference
    $checkbox.Tag = $ModuleName
    
    return $checkbox
}

function New-StatusIndicator {
    <#
    .SYNOPSIS
    Create a colored status indicator
    #>
    param(
        [parameter(Mandatory)]
        [string]$Status,
        
        [ValidateSet("success", "warning", "error", "info", "pending")]
        [string]$Type = "info",
        
        [int]$Size = 16,
        [hashtable]$Theme = $null
    )
    
    $panel = New-Object System.Windows.Forms.Panel
    $panel.Width = $Size
    $panel.Height = $Size
    $panel.BorderStyle = [System.Windows.Forms.BorderStyle]::None
    
    if ($Theme) {
        $color = switch ($Type) {
            "success" { $Theme.SuccessColor }
            "warning" { $Theme.WarningColor }
            "error" { $Theme.ErrorColor }
            "info" { $Theme.InfoColor }
            "pending" { $Theme.WarningColor }
        }
        $panel.BackColor = $color
    }
    
    $panel.Tag = @{
        Status = $Status
        Type = $Type
    }
    
    return $panel
}

function New-LogViewer {
    <#
    .SYNOPSIS
    Create a log viewer control with filtering
    #>
    param(
        [int]$Width = 500,
        [int]$Height = 300,
        [int]$Left = 0,
        [int]$Top = 0,
        
        [hashtable]$Theme = $null
    )
    
    $logBox = New-Object System.Windows.Forms.RichTextBox
    $logBox.Width = $Width
    $logBox.Height = $Height
    $logBox.Left = $Left
    $logBox.Top = $Top
    $logBox.ReadOnly = $true
    $logBox.AutoSize = $false
    $logBox.WordWrap = $true
    $logBox.ScrollBars = [System.Windows.Forms.RichTextBoxScrollBars]::Both
    
    if ($Theme) {
        $logBox.BackColor = $Theme.ControlBackColor
        $logBox.ForeColor = $Theme.ControlForeColor
    }
    
    # Store log entries for filtering
    $logBox.Tag = @{
        Entries = @()
        Filter = "ALL"
    }
    
    return $logBox
}

function New-AppSelector {
    <#
    .SYNOPSIS
    Create an app selection panel with category grouping
    #>
    param(
        [string[]]$AppNames = @(),
        [string[]]$AppDisplayNames = @(),
        [string[]]$Categories = @(),
        
        [int]$Width = 400,
        [int]$Height = 300,
        [int]$Left = 0,
        [int]$Top = 0,
        
        [hashtable]$Theme = $null
    )
    
    $panel = New-StyledPanel -Width $Width -Height $Height -Left $Left -Top $Top `
        -Theme $Theme -Bordered
    
    # Create tab control for categories
    $tabControl = New-Object System.Windows.Forms.TabControl
    $tabControl.Width = $Width - 10
    $tabControl.Height = $Height - 10
    $tabControl.Left = 5
    $tabControl.Top = 5
    $tabControl.AutoSize = $false
    
    # Store app data
    $panel.Tag = @{
        Apps = @{}
        Categories = $Categories
    }
    
    $panel.Controls.Add($tabControl)
    
    return $panel
}

# ===============================
# Helper Functions
# ===============================

function Set-ControlTheme {
    <#
    .SYNOPSIS
    Apply theme to a specific control
    #>
    param(
        [parameter(Mandatory)]
        [System.Windows.Forms.Control]$Control,
        
        [parameter(Mandatory)]
        [hashtable]$Theme
    )
    
    switch ($Control.GetType().Name) {
        "Button" {
            $Control.BackColor = $Theme.AccentColor
            $Control.ForeColor = $Theme.ForegroundColor
            if ($Control.FlatAppearance) {
                $Control.FlatAppearance.BorderColor = $Theme.AccentDarkColor
            }
        }
        "Label" {
            $Control.BackColor = $Theme.PanelColor
            $Control.ForeColor = $Theme.ForegroundColor
        }
        "TextBox" {
            $Control.BackColor = $Theme.ControlBackColor
            $Control.ForeColor = $Theme.ControlForeColor
        }
        "CheckBox" {
            $Control.BackColor = $Theme.PanelColor
            $Control.ForeColor = $Theme.ForegroundColor
        }
        "ComboBox" {
            $Control.BackColor = $Theme.ControlBackColor
            $Control.ForeColor = $Theme.ControlForeColor
        }
        "Panel" {
            $Control.BackColor = $Theme.PanelColor
        }
        "RichTextBox" {
            $Control.BackColor = $Theme.ControlBackColor
            $Control.ForeColor = $Theme.ControlForeColor
        }
    }
}

function Get-SelectedApps {
    <#
    .SYNOPSIS
    Get list of selected apps from app selector
    #>
    param(
        [parameter(Mandatory)]
        [System.Windows.Forms.Control]$AppSelector
    )
    
    $selected = @()
    
    foreach ($control in $AppSelector.Controls) {
        if ($control -is [System.Windows.Forms.CheckBox] -and $control.Checked) {
            $selected += $control.Tag
        }
    }
    
    return $selected
}

# ===============================
# Export Functions
# ===============================

Export-ModuleMember -Function @(
    'New-StyledButton',
    'New-StyledLabel',
    'New-StyledPanel',
    'New-StyledCheckBox',
    'New-StyledComboBox',
    'New-StyledTextBox',
    'New-StyledListBox',
    'New-StyledProgressBar',
    'New-StyledGroupBox',
    'New-ModuleCheckBox',
    'New-StatusIndicator',
    'New-LogViewer',
    'New-AppSelector',
    'Set-ControlTheme',
    'Get-SelectedApps'
)
