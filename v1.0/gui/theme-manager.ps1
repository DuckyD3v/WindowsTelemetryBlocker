# ===============================
# GUI Theme Manager
# v1.0 - Theme System for Windows Forms
# ===============================

<#
.SYNOPSIS
Manages application themes and color schemes for Windows Forms GUI

.DESCRIPTION
Provides theme definitions and application for consistent styling across GUI components.
Supports dark theme (default), light theme, and high contrast mode.

.EXAMPLE
$theme = Get-ApplicationTheme -ThemeName "dark"
Apply-Theme -Form $mainForm -Theme $theme
#>

# ===============================
# Theme Definitions
# ===============================

function Get-DarkTheme {
    <#
    .SYNOPSIS
    Get dark theme color scheme (default)
    #>
    return @{
        Name = "dark"
        Description = "Dark theme (recommended)"
        
        # Primary colors
        BackgroundColor = [System.Drawing.Color]::FromArgb(30, 30, 30)           # #1e1e1e
        ForegroundColor = [System.Drawing.Color]::FromArgb(255, 255, 255)       # #ffffff
        
        # Accent colors
        AccentColor = [System.Drawing.Color]::FromArgb(0, 120, 212)             # #0078d4 (Windows Blue)
        AccentDarkColor = [System.Drawing.Color]::FromArgb(0, 80, 160)          # Darker blue
        
        # Status colors
        SuccessColor = [System.Drawing.Color]::FromArgb(16, 124, 16)            # #107c10 (Green)
        WarningColor = [System.Drawing.Color]::FromArgb(255, 185, 0)            # #ffb900 (Yellow)
        ErrorColor = [System.Drawing.Color]::FromArgb(209, 52, 56)              # #d13438 (Red)
        InfoColor = [System.Drawing.Color]::FromArgb(0, 120, 212)               # #0078d4 (Blue)
        
        # Panel colors
        PanelColor = [System.Drawing.Color]::FromArgb(45, 45, 48)               # #2d2d30
        BorderColor = [System.Drawing.Color]::FromArgb(60, 60, 60)              # #3c3c3c
        
        # Control colors
        ControlBackColor = [System.Drawing.Color]::FromArgb(50, 50, 52)         # #323234
        ControlForeColor = [System.Drawing.Color]::FromArgb(240, 240, 240)      # #f0f0f0
        ControlBorderColor = [System.Drawing.Color]::FromArgb(80, 80, 80)       # #505050
        
        # Hover/Focus colors
        HoverColor = [System.Drawing.Color]::FromArgb(60, 60, 62)               # #3c3c3e
        FocusColor = [System.Drawing.Color]::FromArgb(0, 120, 212)              # Blue glow
        DisabledColor = [System.Drawing.Color]::FromArgb(100, 100, 100)         # #646464
        
        # Font
        FontName = "Segoe UI"
        FontSize = 10
        FontSizeLarge = 12
        FontSizeSmall = 9
    }
}

function Get-LightTheme {
    <#
    .SYNOPSIS
    Get light theme color scheme
    #>
    return @{
        Name = "light"
        Description = "Light theme"
        
        # Primary colors
        BackgroundColor = [System.Drawing.Color]::FromArgb(255, 255, 255)       # #ffffff
        ForegroundColor = [System.Drawing.Color]::FromArgb(0, 0, 0)             # #000000
        
        # Accent colors
        AccentColor = [System.Drawing.Color]::FromArgb(0, 120, 212)             # #0078d4 (Windows Blue)
        AccentDarkColor = [System.Drawing.Color]::FromArgb(0, 80, 160)          # Darker blue
        
        # Status colors
        SuccessColor = [System.Drawing.Color]::FromArgb(16, 124, 16)            # #107c10 (Green)
        WarningColor = [System.Drawing.Color]::FromArgb(255, 140, 0)            # #ff8c00 (Orange)
        ErrorColor = [System.Drawing.Color]::FromArgb(209, 52, 56)              # #d13438 (Red)
        InfoColor = [System.Drawing.Color]::FromArgb(0, 120, 212)               # #0078d4 (Blue)
        
        # Panel colors
        PanelColor = [System.Drawing.Color]::FromArgb(240, 240, 240)            # #f0f0f0
        BorderColor = [System.Drawing.Color]::FromArgb(200, 200, 200)           # #c8c8c8
        
        # Control colors
        ControlBackColor = [System.Drawing.Color]::FromArgb(250, 250, 250)      # #fafafa
        ControlForeColor = [System.Drawing.Color]::FromArgb(32, 32, 32)         # #202020
        ControlBorderColor = [System.Drawing.Color]::FromArgb(180, 180, 180)    # #b4b4b4
        
        # Hover/Focus colors
        HoverColor = [System.Drawing.Color]::FromArgb(230, 230, 230)            # #e6e6e6
        FocusColor = [System.Drawing.Color]::FromArgb(0, 120, 212)              # Blue glow
        DisabledColor = [System.Drawing.Color]::FromArgb(150, 150, 150)         # #969696
        
        # Font
        FontName = "Segoe UI"
        FontSize = 10
        FontSizeLarge = 12
        FontSizeSmall = 9
    }
}

function Get-HighContrastTheme {
    <#
    .SYNOPSIS
    Get high contrast theme for accessibility
    #>
    return @{
        Name = "highcontrast"
        Description = "High contrast (accessibility)"
        
        # Primary colors
        BackgroundColor = [System.Drawing.Color]::Black                         # #000000
        ForegroundColor = [System.Drawing.Color]::White                         # #ffffff
        
        # Accent colors
        AccentColor = [System.Drawing.Color]::Yellow                            # #ffff00
        AccentDarkColor = [System.Drawing.Color]::FromArgb(200, 200, 0)        # Dark yellow
        
        # Status colors
        SuccessColor = [System.Drawing.Color]::Lime                             # #00ff00 (Bright green)
        WarningColor = [System.Drawing.Color]::Yellow                           # #ffff00 (Bright yellow)
        ErrorColor = [System.Drawing.Color]::Red                                # #ff0000 (Bright red)
        InfoColor = [System.Drawing.Color]::Cyan                                # #00ffff (Bright cyan)
        
        # Panel colors
        PanelColor = [System.Drawing.Color]::Black                              # #000000
        BorderColor = [System.Drawing.Color]::White                             # #ffffff
        
        # Control colors
        ControlBackColor = [System.Drawing.Color]::Black                        # #000000
        ControlForeColor = [System.Drawing.Color]::White                        # #ffffff
        ControlBorderColor = [System.Drawing.Color]::Yellow                     # #ffff00
        
        # Hover/Focus colors
        HoverColor = [System.Drawing.Color]::FromArgb(50, 50, 50)               # Dark gray
        FocusColor = [System.Drawing.Color]::Yellow                             # #ffff00
        DisabledColor = [System.Drawing.Color]::Gray                            # #808080
        
        # Font
        FontName = "Arial"
        FontSize = 11
        FontSizeLarge = 13
        FontSizeSmall = 10
    }
}

# ===============================
# Theme Management
# ===============================

function Get-ApplicationTheme {
    <#
    .SYNOPSIS
    Get theme by name
    #>
    param(
        [ValidateSet("dark", "light", "highcontrast")]
        [string]$ThemeName = "dark"
    )
    
    switch ($ThemeName) {
        "light" { return Get-LightTheme }
        "highcontrast" { return Get-HighContrastTheme }
        default { return Get-DarkTheme }
    }
}

function Get-AvailableThemes {
    <#
    .SYNOPSIS
    List all available themes
    #>
    return @(
        (Get-DarkTheme),
        (Get-LightTheme),
        (Get-HighContrastTheme)
    )
}

function Apply-Theme {
    <#
    .SYNOPSIS
    Apply theme to a form and its controls
    #>
    param(
        [parameter(Mandatory)]
        [System.Windows.Forms.Form]$Form,
        
        [parameter(Mandatory)]
        [hashtable]$Theme,
        
        [switch]$Recursive = $true
    )
    
    try {
        # Apply to form
        $Form.BackColor = $Theme.BackgroundColor
        $Form.ForeColor = $Theme.ForegroundColor
        
        # Apply to all controls
        foreach ($control in $Form.Controls) {
            Apply-ThemeToControl -Control $control -Theme $Theme -Recursive $Recursive
        }
        
        # Refresh
        $Form.Refresh()
        
        return $true
    } catch {
        Write-Host "[ERROR] Failed to apply theme: $_" -ForegroundColor Red
        return $false
    }
}

function Apply-ThemeToControl {
    <#
    .SYNOPSIS
    Recursively apply theme to control and children
    #>
    param(
        [parameter(Mandatory)]
        [System.Windows.Forms.Control]$Control,
        
        [parameter(Mandatory)]
        [hashtable]$Theme,
        
        [bool]$Recursive = $true
    )
    
    # Base properties for all controls
    $Control.BackColor = $Theme.ControlBackColor
    $Control.ForeColor = $Theme.ControlForeColor
    
    # Specific control types
    switch ($Control.GetType().Name) {
        "Panel" {
            $Control.BackColor = $Theme.PanelColor
        }
        
        "Button" {
            $Control.BackColor = $Theme.AccentColor
            $Control.ForeColor = $Theme.ForegroundColor
            $Control.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
            $Control.FlatAppearance.BorderColor = $Theme.AccentDarkColor
        }
        
        "Label" {
            $Control.BackColor = $Theme.PanelColor
            $Control.ForeColor = $Theme.ForegroundColor
        }
        
        "TextBox" {
            $Control.BackColor = $Theme.ControlBackColor
            $Control.ForeColor = $Theme.ControlForeColor
            $Control.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
        }
        
        "CheckBox" {
            $Control.BackColor = $Theme.PanelColor
            $Control.ForeColor = $Theme.ForegroundColor
        }
        
        "RadioButton" {
            $Control.BackColor = $Theme.PanelColor
            $Control.ForeColor = $Theme.ForegroundColor
        }
        
        "ComboBox" {
            $Control.BackColor = $Theme.ControlBackColor
            $Control.ForeColor = $Theme.ControlForeColor
        }
        
        "ListBox" {
            $Control.BackColor = $Theme.ControlBackColor
            $Control.ForeColor = $Theme.ControlForeColor
        }
        
        "ProgressBar" {
            # Note: ProgressBar doesn't support theming directly in .NET 4.0
        }
        
        "RichTextBox" {
            $Control.BackColor = $Theme.ControlBackColor
            $Control.ForeColor = $Theme.ControlForeColor
        }
        
        "GroupBox" {
            $Control.BackColor = $Theme.PanelColor
            $Control.ForeColor = $Theme.ForegroundColor
        }
    }
    
    # Recursively apply to child controls
    if ($Recursive -and $Control.HasChildren) {
        foreach ($child in $Control.Controls) {
            Apply-ThemeToControl -Control $child -Theme $Theme -Recursive $true
        }
    }
}

# ===============================
# Theme Persistence
# ===============================

function Save-UserTheme {
    <#
    .SYNOPSIS
    Save user's theme preference
    #>
    param(
        [parameter(Mandatory)]
        [string]$ThemeName
    )
    
    try {
        $appDataPath = [Environment]::GetFolderPath("ApplicationData")
        $configDir = Join-Path $appDataPath "WindowsTelemetryBlocker"
        $userConfigFile = Join-Path $configDir "user-config.json"
        
        if (Test-Path $userConfigFile) {
            $config = Get-Content $userConfigFile -Raw | ConvertFrom-Json
        } else {
            $config = @{}
        }
        
        $config.theme = $ThemeName
        
        if (-not (Test-Path $configDir)) {
            New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        }
        
        $config | ConvertTo-Json | Set-Content $userConfigFile -Encoding UTF8
        return $true
    } catch {
        Write-Host "[WARN] Failed to save theme preference: $_" -ForegroundColor Yellow
        return $false
    }
}

function Get-UserTheme {
    <#
    .SYNOPSIS
    Get user's saved theme preference (or default)
    #>
    try {
        $appDataPath = [Environment]::GetFolderPath("ApplicationData")
        $configDir = Join-Path $appDataPath "WindowsTelemetryBlocker"
        $userConfigFile = Join-Path $configDir "user-config.json"
        
        if (Test-Path $userConfigFile) {
            $config = Get-Content $userConfigFile -Raw | ConvertFrom-Json
            if ($config.theme) {
                return $config.theme
            }
        }
    } catch {
        Write-Host "[WARN] Failed to load user theme preference: $_" -ForegroundColor Yellow
    }
    
    return "dark"  # Default
}

# ===============================
# Color Utilities
# ===============================

function New-Color {
    <#
    .SYNOPSIS
    Create a color object from RGB values
    #>
    param(
        [int]$Red,
        [int]$Green,
        [int]$Blue,
        [int]$Alpha = 255
    )
    
    return [System.Drawing.Color]::FromArgb($Alpha, $Red, $Green, $Blue)
}

function Lighten-Color {
    <#
    .SYNOPSIS
    Lighten a color by increasing brightness
    #>
    param(
        [parameter(Mandatory)]
        [System.Drawing.Color]$Color,
        
        [int]$Amount = 30
    )
    
    $newR = [Math]::Min($Color.R + $Amount, 255)
    $newG = [Math]::Min($Color.G + $Amount, 255)
    $newB = [Math]::Min($Color.B + $Amount, 255)
    
    return [System.Drawing.Color]::FromArgb($Color.A, $newR, $newG, $newB)
}

function Darken-Color {
    <#
    .SYNOPSIS
    Darken a color by decreasing brightness
    #>
    param(
        [parameter(Mandatory)]
        [System.Drawing.Color]$Color,
        
        [int]$Amount = 30
    )
    
    $newR = [Math]::Max($Color.R - $Amount, 0)
    $newG = [Math]::Max($Color.G - $Amount, 0)
    $newB = [Math]::Max($Color.B - $Amount, 0)
    
    return [System.Drawing.Color]::FromArgb($Color.A, $newR, $newG, $newB)
}

# ===============================
# Export Functions
# ===============================




