# ===============================
# Advanced Filtering Module
# Phase 3 - Selective App/Service Management
# ===============================
# Provides advanced filtering and selective removal UI
# Integrates with launcher-gui.ps1 for custom profile creation

param(
    [string]$Action = "filter",  # filter, create-profile, import, export
    [string]$FilterType,          # apps, services, both
    [array]$Items = @(),
    [string]$ProfileName,
    [string]$Category
)

# ===============================
# Initialize
# ===============================

$script:ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:ConfigPath = Join-Path (Split-Path -Parent $script:ScriptRoot) "config"
$script:SharedPath = Join-Path (Split-Path -Parent $script:ScriptRoot) "shared"
$script:GuiPath = $script:ScriptRoot

# Import dependencies
. (Join-Path $script:SharedPath "utils.ps1")
. (Join-Path $script:GuiPath "theme-manager.ps1")
. (Join-Path $script:GuiPath "form-controls.ps1")
. (Join-Path $script:ConfigPath "config-manager.ps1")

Write-LogEntry "INFO" "Advanced Filtering Module initialized (Phase 3)"

# ===============================
# Data Structures
# ===============================

class FilterGroup {
    [string]$Name
    [string]$Category
    [array]$Items
    [int]$Count
    
    FilterGroup([string]$name, [string]$category, [array]$items) {
        $this.Name = $name
        $this.Category = $category
        $this.Items = $items
        $this.Count = @($items).Count
    }
}

class AppMetadata {
    [string]$DisplayName
    [string]$InternalName
    [string]$Category
    [string]$Severity  # low, medium, high
    [string]$Description
    [bool]$IsSafe
}

class ServiceMetadata {
    [string]$DisplayName
    [string]$ServiceName
    [string]$Category
    [bool]$IsCritical
    [string]$Description
    [bool]$IsDisableable
}

# ===============================
# Filtering Functions
# ===============================

function Get-FilteredApps {
    param(
        [string]$Category,
        [string]$Severity,
        [bool]$SafeOnly = $false,
        [string]$SearchTerm
    )
    
    $profilesPath = Join-Path $script:ConfigPath "profiles.json"
    if (-not (Test-Path $profilesPath)) {
        Write-LogEntry "ERROR" "profiles.json not found"
        return @()
    }
    
    try {
        $profilesJson = Get-Content $profilesPath -Raw | ConvertFrom-Json
        $apps = $profilesJson.apps | ConvertTo-Object
        
        $filtered = @()
        
        foreach ($app in $apps) {
            $include = $true
            
            # Category filter
            if ($Category -and $app.category -ne $Category) {
                $include = $false
            }
            
            # Severity filter
            if ($Severity -and $app.severity -ne $Severity) {
                $include = $false
            }
            
            # Safety filter
            if ($SafeOnly -and -not $app.safe) {
                $include = $false
            }
            
            # Search filter
            if ($SearchTerm) {
                $lowerSearch = $SearchTerm.ToLower()
                if ($app.displayName -notlike "*$lowerSearch*" -and `
                    $app.name -notlike "*$lowerSearch*") {
                    $include = $false
                }
            }
            
            if ($include) {
                $filtered += $app
            }
        }
        
        Write-LogEntry "INFO" "Filtered to $($filtered.Count) apps"
        return $filtered
    }
    catch {
        Write-LogEntry "ERROR" "Failed to filter apps: $_"
        return @()
    }
}

function Get-FilteredServices {
    param(
        [string]$Category,
        [bool]$ExcludeCritical = $false,
        [string]$SearchTerm
    )
    
    $profilesPath = Join-Path $script:ConfigPath "profiles.json"
    if (-not (Test-Path $profilesPath)) {
        Write-LogEntry "ERROR" "profiles.json not found"
        return @()
    }
    
    try {
        $profilesJson = Get-Content $profilesPath -Raw | ConvertFrom-Json
        $services = $profilesJson.services | ConvertTo-Object
        
        $filtered = @()
        
        foreach ($service in $services) {
            $include = $true
            
            # Category filter
            if ($Category -and $service.category -ne $Category) {
                $include = $false
            }
            
            # Critical filter
            if ($ExcludeCritical -and $service.critical) {
                $include = $false
            }
            
            # Search filter
            if ($SearchTerm) {
                $lowerSearch = $SearchTerm.ToLower()
                if ($service.displayName -notlike "*$lowerSearch*" -and `
                    $service.name -notlike "*$lowerSearch*") {
                    $include = $false
                }
            }
            
            if ($include) {
                $filtered += $service
            }
        }
        
        Write-LogEntry "INFO" "Filtered to $($filtered.Count) services"
        return $filtered
    }
    catch {
        Write-LogEntry "ERROR" "Failed to filter services: $_"
        return @()
    }
}

function Get-AppCategories {
    param()
    
    $profilesPath = Join-Path $script:ConfigPath "profiles.json"
    if (-not (Test-Path $profilesPath)) {
        return @()
    }
    
    try {
        $profilesJson = Get-Content $profilesPath -Raw | ConvertFrom-Json
        $apps = $profilesJson.apps | ConvertTo-Object
        
        $categories = @($apps.category | Sort-Object -Unique)
        Write-LogEntry "INFO" "Found $($categories.Count) app categories"
        return $categories
    }
    catch {
        Write-LogEntry "ERROR" "Failed to get app categories: $_"
        return @()
    }
}

function Get-ServiceCategories {
    param()
    
    $profilesPath = Join-Path $script:ConfigPath "profiles.json"
    if (-not (Test-Path $profilesPath)) {
        return @()
    }
    
    try {
        $profilesJson = Get-Content $profilesPath -Raw | ConvertFrom-Json
        $services = $profilesJson.services | ConvertTo-Object
        
        $categories = @($services.category | Sort-Object -Unique)
        Write-LogEntry "INFO" "Found $($categories.Count) service categories"
        return $categories
    }
    catch {
        Write-LogEntry "ERROR" "Failed to get service categories: $_"
        return @()
    }
}

# ===============================
# Advanced Filtering Dialog
# ===============================

function Show-AdvancedFilterDialog {
    param(
        [System.Windows.Forms.Form]$Owner,
        [System.Object]$Theme
    )
    
    Write-LogEntry "INFO" "Opening advanced filter dialog..."
    
    $dialog = New-Object System.Windows.Forms.Form
    $dialog.Text = "Advanced Filtering - Phase 3"
    $dialog.Width = 700
    $dialog.Height = 600
    $dialog.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterParent
    $dialog.Owner = $Owner
    $dialog.BackColor = $Theme.BackgroundColor
    $dialog.ForeColor = $Theme.ForegroundColor
    $dialog.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Font
    
    # Tabs
    $tabControl = New-Object System.Windows.Forms.TabControl
    $tabControl.Location = New-Object System.Drawing.Point(10, 10)
    $tabControl.Width = $dialog.Width - 30
    $tabControl.Height = $dialog.Height - 70
    $tabControl.BackColor = $Theme.BackgroundColor
    
    # ===== Apps Tab =====
    $appsTab = New-Object System.Windows.Forms.TabPage
    $appsTab.Text = "Filter Apps"
    $appsTab.BackColor = $Theme.BackgroundColor
    $appsTab.ForeColor = $Theme.ForegroundColor
    
    # Category filter
    $catLbl = New-Object System.Windows.Forms.Label
    $catLbl.Text = "Category:"
    $catLbl.Location = New-Object System.Drawing.Point(10, 20)
    $catLbl.AutoSize = $true
    $catLbl.ForeColor = $Theme.ForegroundColor
    $appsTab.Controls.Add($catLbl)
    
    $catCombo = New-Object System.Windows.Forms.ComboBox
    $catCombo.Location = New-Object System.Drawing.Point(100, 20)
    $catCombo.Width = 200
    $catCombo.BackColor = $Theme.ControlColor
    $catCombo.ForeColor = $Theme.ForegroundColor
    $catCombo.Items.Add("All") | Out-Null
    foreach ($cat in (Get-AppCategories)) {
        $catCombo.Items.Add($cat) | Out-Null
    }
    $catCombo.SelectedItem = "All"
    $appsTab.Controls.Add($catCombo)
    
    # Severity filter
    $sevLbl = New-Object System.Windows.Forms.Label
    $sevLbl.Text = "Severity:"
    $sevLbl.Location = New-Object System.Drawing.Point(10, 55)
    $sevLbl.AutoSize = $true
    $sevLbl.ForeColor = $Theme.ForegroundColor
    $appsTab.Controls.Add($sevLbl)
    
    $sevCombo = New-Object System.Windows.Forms.ComboBox
    $sevCombo.Location = New-Object System.Drawing.Point(100, 55)
    $sevCombo.Width = 200
    $sevCombo.BackColor = $Theme.ControlColor
    $sevCombo.ForeColor = $Theme.ForegroundColor
    $sevCombo.Items.AddRange(@("All", "low", "medium", "high"))
    $sevCombo.SelectedItem = "All"
    $appsTab.Controls.Add($sevCombo)
    
    # Safe only checkbox
    $safeCheck = New-Object System.Windows.Forms.CheckBox
    $safeCheck.Text = "Safe Apps Only"
    $safeCheck.Location = New-Object System.Drawing.Point(100, 90)
    $safeCheck.AutoSize = $true
    $safeCheck.ForeColor = $Theme.ForegroundColor
    $appsTab.Controls.Add($safeCheck)
    
    # Search box
    $searchLbl = New-Object System.Windows.Forms.Label
    $searchLbl.Text = "Search:"
    $searchLbl.Location = New-Object System.Drawing.Point(10, 125)
    $searchLbl.AutoSize = $true
    $searchLbl.ForeColor = $Theme.ForegroundColor
    $appsTab.Controls.Add($searchLbl)
    
    $searchBox = New-Object System.Windows.Forms.TextBox
    $searchBox.Location = New-Object System.Drawing.Point(100, 125)
    $searchBox.Width = 300
    $searchBox.BackColor = $Theme.ControlColor
    $searchBox.ForeColor = $Theme.ForegroundColor
    $appsTab.Controls.Add($searchBox)
    
    # Results list
    $appsList = New-Object System.Windows.Forms.ListBox
    $appsList.Location = New-Object System.Drawing.Point(10, 160)
    $appsList.Width = $appsTab.Width - 20
    $appsList.Height = 150
    $appsList.SelectionMode = [System.Windows.Forms.SelectionMode]::MultiSimple
    $appsList.BackColor = $Theme.ControlColor
    $appsList.ForeColor = $Theme.ForegroundColor
    $appsTab.Controls.Add($appsList)
    
    # Filter button
    $filterAppsBtn = New-Object System.Windows.Forms.Button
    $filterAppsBtn.Text = "Apply Filter"
    $filterAppsBtn.Location = New-Object System.Drawing.Point(10, 320)
    $filterAppsBtn.Width = 100
    $filterAppsBtn.BackColor = $Theme.AccentColor
    $filterAppsBtn.ForeColor = $Theme.ForegroundColor
    $filterAppsBtn.Add_Click({
        $category = if ($catCombo.SelectedItem -eq "All") { $null } else { $catCombo.SelectedItem }
        $severity = if ($sevCombo.SelectedItem -eq "All") { $null } else { $sevCombo.SelectedItem }
        
        $filtered = Get-FilteredApps -Category $category -Severity $severity `
            -SafeOnly $safeCheck.Checked -SearchTerm $searchBox.Text
        
        $appsList.Items.Clear()
        foreach ($app in $filtered) {
            $appsList.Items.Add($app.displayName) | Out-Null
        }
        
        Write-LogEntry "INFO" "Filter applied, found $($appsList.Items.Count) apps"
    })
    $appsTab.Controls.Add($filterAppsBtn)
    
    # ===== Services Tab =====
    $servicesTab = New-Object System.Windows.Forms.TabPage
    $servicesTab.Text = "Filter Services"
    $servicesTab.BackColor = $Theme.BackgroundColor
    $servicesTab.ForeColor = $Theme.ForegroundColor
    
    # Service category filter
    $svcCatLbl = New-Object System.Windows.Forms.Label
    $svcCatLbl.Text = "Category:"
    $svcCatLbl.Location = New-Object System.Drawing.Point(10, 20)
    $svcCatLbl.AutoSize = $true
    $svcCatLbl.ForeColor = $Theme.ForegroundColor
    $servicesTab.Controls.Add($svcCatLbl)
    
    $svcCatCombo = New-Object System.Windows.Forms.ComboBox
    $svcCatCombo.Location = New-Object System.Drawing.Point(100, 20)
    $svcCatCombo.Width = 200
    $svcCatCombo.BackColor = $Theme.ControlColor
    $svcCatCombo.ForeColor = $Theme.ForegroundColor
    $svcCatCombo.Items.Add("All") | Out-Null
    foreach ($cat in (Get-ServiceCategories)) {
        $svcCatCombo.Items.Add($cat) | Out-Null
    }
    $svcCatCombo.SelectedItem = "All"
    $servicesTab.Controls.Add($svcCatCombo)
    
    # Exclude critical checkbox
    $criticalCheck = New-Object System.Windows.Forms.CheckBox
    $criticalCheck.Text = "Exclude Critical Services"
    $criticalCheck.Location = New-Object System.Drawing.Point(10, 55)
    $criticalCheck.AutoSize = $true
    $criticalCheck.Checked = $true
    $criticalCheck.ForeColor = $Theme.ForegroundColor
    $servicesTab.Controls.Add($criticalCheck)
    
    # Service search
    $svcSearchLbl = New-Object System.Windows.Forms.Label
    $svcSearchLbl.Text = "Search:"
    $svcSearchLbl.Location = New-Object System.Drawing.Point(10, 90)
    $svcSearchLbl.AutoSize = $true
    $svcSearchLbl.ForeColor = $Theme.ForegroundColor
    $servicesTab.Controls.Add($svcSearchLbl)
    
    $svcSearchBox = New-Object System.Windows.Forms.TextBox
    $svcSearchBox.Location = New-Object System.Drawing.Point(100, 90)
    $svcSearchBox.Width = 300
    $svcSearchBox.BackColor = $Theme.ControlColor
    $svcSearchBox.ForeColor = $Theme.ForegroundColor
    $servicesTab.Controls.Add($svcSearchBox)
    
    # Services results list
    $servicesList = New-Object System.Windows.Forms.ListBox
    $servicesList.Location = New-Object System.Drawing.Point(10, 125)
    $servicesList.Width = $servicesTab.Width - 20
    $servicesList.Height = 150
    $servicesList.SelectionMode = [System.Windows.Forms.SelectionMode]::MultiSimple
    $servicesList.BackColor = $Theme.ControlColor
    $servicesList.ForeColor = $Theme.ForegroundColor
    $servicesTab.Controls.Add($servicesList)
    
    # Filter services button
    $filterSvcBtn = New-Object System.Windows.Forms.Button
    $filterSvcBtn.Text = "Apply Filter"
    $filterSvcBtn.Location = New-Object System.Drawing.Point(10, 285)
    $filterSvcBtn.Width = 100
    $filterSvcBtn.BackColor = $Theme.AccentColor
    $filterSvcBtn.ForeColor = $Theme.ForegroundColor
    $filterSvcBtn.Add_Click({
        $category = if ($svcCatCombo.SelectedItem -eq "All") { $null } else { $svcCatCombo.SelectedItem }
        
        $filtered = Get-FilteredServices -Category $category `
            -ExcludeCritical $criticalCheck.Checked -SearchTerm $svcSearchBox.Text
        
        $servicesList.Items.Clear()
        foreach ($svc in $filtered) {
            $servicesList.Items.Add($svc.displayName) | Out-Null
        }
        
        Write-LogEntry "INFO" "Filter applied, found $($servicesList.Items.Count) services"
    })
    $servicesTab.Controls.Add($filterSvcBtn)
    
    # Add tabs
    $tabControl.TabPages.Add($appsTab)
    $tabControl.TabPages.Add($servicesTab)
    $dialog.Controls.Add($tabControl)
    
    # Buttons
    $selectBtn = New-Object System.Windows.Forms.Button
    $selectBtn.Text = "Select Filtered"
    $selectBtn.Location = New-Object System.Drawing.Point(10, $dialog.Height - 50)
    $selectBtn.Width = 120
    $selectBtn.BackColor = $Theme.SuccessColor
    $selectBtn.ForeColor = $Theme.ForegroundColor
    $dialog.Controls.Add($selectBtn)
    
    $closeBtn = New-Object System.Windows.Forms.Button
    $closeBtn.Text = "Close"
    $closeBtn.Location = New-Object System.Drawing.Point(140, $dialog.Height - 50)
    $closeBtn.Width = 100
    $closeBtn.BackColor = $Theme.BackgroundColor
    $closeBtn.ForeColor = $Theme.ForegroundColor
    $closeBtn.Add_Click({
        $dialog.Close()
    })
    $dialog.Controls.Add($closeBtn)
    
    [void]$dialog.ShowDialog()
}

# ===============================
# Custom Profile Creation
# ===============================

function New-CustomProfile {
    param(
        [string]$ProfileName,
        [array]$Apps,
        [array]$Services,
        [string]$Description
    )
    
    Write-LogEntry "INFO" "Creating custom profile: $ProfileName"
    
    try {
        $configManagerPath = Join-Path $script:ConfigPath "config-manager.ps1"
        $profilePath = Join-Path $env:APPDATA "WindowsTelemetryBlocker\profiles\$ProfileName.json"
        
        $profile = @{
            name = $ProfileName
            description = $Description
            apps = $Apps
            services = $Services
            custom = $true
            createdDate = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        }
        
        $profileJson = $profile | ConvertTo-Json
        
        # Ensure directory exists
        $profileDir = Split-Path -Parent $profilePath
        if (-not (Test-Path $profileDir)) {
            New-Item -Path $profileDir -ItemType Directory -Force | Out-Null
        }
        
        $profileJson | Out-File -FilePath $profilePath -Force -Encoding UTF8
        
        Write-LogEntry "OK" "Custom profile created: $ProfileName"
        return $true
    }
    catch {
        Write-LogEntry "ERROR" "Failed to create custom profile: $_"
        return $false
    }
}

function Show-CustomProfileDialog {
    param(
        [System.Windows.Forms.Form]$Owner,
        [System.Object]$Theme
    )
    
    Write-LogEntry "INFO" "Opening custom profile creation dialog..."
    
    $dialog = New-Object System.Windows.Forms.Form
    $dialog.Text = "Create Custom Profile - Phase 3"
    $dialog.Width = 600
    $dialog.Height = 500
    $dialog.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterParent
    $dialog.Owner = $Owner
    $dialog.BackColor = $Theme.BackgroundColor
    $dialog.ForeColor = $Theme.ForegroundColor
    
    # Profile name
    $nameLbl = New-Object System.Windows.Forms.Label
    $nameLbl.Text = "Profile Name:"
    $nameLbl.Location = New-Object System.Drawing.Point(10, 20)
    $nameLbl.AutoSize = $true
    $nameLbl.ForeColor = $Theme.ForegroundColor
    $dialog.Controls.Add($nameLbl)
    
    $nameBox = New-Object System.Windows.Forms.TextBox
    $nameBox.Location = New-Object System.Drawing.Point(150, 20)
    $nameBox.Width = 300
    $nameBox.BackColor = $Theme.ControlColor
    $nameBox.ForeColor = $Theme.ForegroundColor
    $dialog.Controls.Add($nameBox)
    
    # Description
    $descLbl = New-Object System.Windows.Forms.Label
    $descLbl.Text = "Description:"
    $descLbl.Location = New-Object System.Drawing.Point(10, 55)
    $descLbl.AutoSize = $true
    $descLbl.ForeColor = $Theme.ForegroundColor
    $dialog.Controls.Add($descLbl)
    
    $descBox = New-Object System.Windows.Forms.TextBox
    $descBox.Location = New-Object System.Drawing.Point(150, 55)
    $descBox.Width = 300
    $descBox.Height = 60
    $descBox.Multiline = $true
    $descBox.BackColor = $Theme.ControlColor
    $descBox.ForeColor = $Theme.ForegroundColor
    $dialog.Controls.Add($descBox)
    
    # Import existing selections
    $importLbl = New-Object System.Windows.Forms.Label
    $importLbl.Text = "Or use Advanced Filter to select items:"
    $importLbl.Location = New-Object System.Drawing.Point(10, 130)
    $importLbl.AutoSize = $true
    $importLbl.ForeColor = $Theme.ForegroundColor
    $dialog.Controls.Add($importLbl)
    
    $filterBtn = New-Object System.Windows.Forms.Button
    $filterBtn.Text = "Open Advanced Filter"
    $filterBtn.Location = New-Object System.Drawing.Point(10, 160)
    $filterBtn.Width = 200
    $filterBtn.BackColor = $Theme.AccentColor
    $filterBtn.ForeColor = $Theme.ForegroundColor
    $filterBtn.Add_Click({
        Show-AdvancedFilterDialog -Owner $dialog -Theme $Theme
    })
    $dialog.Controls.Add($filterBtn)
    
    # Create button
    $createBtn = New-Object System.Windows.Forms.Button
    $createBtn.Text = "Create Profile"
    $createBtn.Location = New-Object System.Drawing.Point(10, $dialog.Height - 50)
    $createBtn.Width = 120
    $createBtn.BackColor = $Theme.SuccessColor
    $createBtn.ForeColor = $Theme.ForegroundColor
    $createBtn.Add_Click({
        if ([string]::IsNullOrEmpty($nameBox.Text)) {
            [System.Windows.Forms.MessageBox]::Show("Please enter a profile name", "Validation Error")
            return
        }
        
        $success = New-CustomProfile -ProfileName $nameBox.Text `
            -Description $descBox.Text -Apps @() -Services @()
        
        if ($success) {
            [System.Windows.Forms.MessageBox]::Show("Profile created successfully!", "Success")
            $dialog.Close()
        }
        else {
            [System.Windows.Forms.MessageBox]::Show("Failed to create profile", "Error")
        }
    })
    $dialog.Controls.Add($createBtn)
    
    # Cancel button
    $cancelBtn = New-Object System.Windows.Forms.Button
    $cancelBtn.Text = "Cancel"
    $cancelBtn.Location = New-Object System.Drawing.Point(140, $dialog.Height - 50)
    $cancelBtn.Width = 100
    $cancelBtn.BackColor = $Theme.BackgroundColor
    $cancelBtn.ForeColor = $Theme.ForegroundColor
    $cancelBtn.Add_Click({
        $dialog.Close()
    })
    $dialog.Controls.Add($cancelBtn)
    
    [void]$dialog.ShowDialog()
}

# ===============================
# Profile Import/Export
# ===============================

function Export-Profile {
    param(
        [string]$ProfileName,
        [string]$OutputPath
    )
    
    Write-LogEntry "INFO" "Exporting profile: $ProfileName"
    
    try {
        $profilesPath = Join-Path $script:ConfigPath "profiles.json"
        $profilesJson = Get-Content $profilesPath -Raw | ConvertFrom-Json
        
        $profile = $profilesJson.profiles | Where-Object { $_.name -eq $ProfileName }
        
        if ($profile) {
            $profile | ConvertTo-Json | Out-File -FilePath $OutputPath -Force -Encoding UTF8
            Write-LogEntry "OK" "Profile exported to: $OutputPath"
            return $true
        }
        else {
            Write-LogEntry "WARN" "Profile not found: $ProfileName"
            return $false
        }
    }
    catch {
        Write-LogEntry "ERROR" "Failed to export profile: $_"
        return $false
    }
}

function Import-Profile {
    param(
        [string]$ImportPath
    )
    
    Write-LogEntry "INFO" "Importing profile from: $ImportPath"
    
    try {
        if (-not (Test-Path $ImportPath)) {
            Write-LogEntry "ERROR" "Import file not found: $ImportPath"
            return $false
        }
        
        $profile = Get-Content $ImportPath -Raw | ConvertFrom-Json
        
        # Validate profile structure
        if (-not $profile.name) {
            Write-LogEntry "ERROR" "Invalid profile: missing 'name' property"
            return $false
        }
        
        # Save to custom profiles directory
        $customProfileDir = Join-Path $env:APPDATA "WindowsTelemetryBlocker\profiles"
        if (-not (Test-Path $customProfileDir)) {
            New-Item -Path $customProfileDir -ItemType Directory -Force | Out-Null
        }
        
        $outputPath = Join-Path $customProfileDir "$($profile.name).json"
        $profile | ConvertTo-Json | Out-File -FilePath $outputPath -Force -Encoding UTF8
        
        Write-LogEntry "OK" "Profile imported: $($profile.name)"
        return $true
    }
    catch {
        Write-LogEntry "ERROR" "Failed to import profile: $_"
        return $false
    }
}

# ===============================
# Exports for launcher-gui.ps1
# ===============================

# Export public functions



