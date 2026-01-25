# Phase 2.2: Data Binding Module
# Provides dynamic data loading and binding between configuration and GUI
# Handles profile/app/service loading, user preferences, and event handler generation

using module .\config-manager.ps1

# ============================================================================
# CLASSES AND TYPES
# ============================================================================

class FilterGroup {
    [string]$Name
    [string[]]$Items
    [bool]$IsCritical
    
    FilterGroup([string]$Name, [string[]]$Items, [bool]$IsCritical = $false) {
        $this.Name = $Name
        $this.Items = $Items
        $this.IsCritical = $IsCritical
    }
}

class AppMetadata {
    [string]$DisplayName
    [string]$AppName
    [string]$Category
    [int]$Priority
    [bool]$IsSelected
    
    AppMetadata([string]$DisplayName, [string]$AppName, [string]$Category, [int]$Priority) {
        $this.DisplayName = $DisplayName
        $this.AppName = $AppName
        $this.Category = $Category
        $this.Priority = $Priority
        $this.IsSelected = $false
    }
}

class ServiceMetadata {
    [string]$DisplayName
    [string]$ServiceName
    [string]$Category
    [bool]$IsCritical
    [bool]$IsSelected
    
    ServiceMetadata([string]$DisplayName, [string]$ServiceName, [string]$Category, [bool]$IsCritical) {
        $this.DisplayName = $DisplayName
        $this.ServiceName = $ServiceName
        $this.Category = $Category
        $this.IsCritical = $IsCritical
        $this.IsSelected = $false
    }
}

# ============================================================================
# PROFILE LOADING FUNCTIONS
# ============================================================================

<#
.SYNOPSIS
    Loads profiles into a combo box from FormState
.PARAMETER ProfileCombo
    The combo box control to populate
.PARAMETER FormState
    The FormState object containing profiles
#>
function Load-ProfilesIntoComboBox {
    param(
        [System.Windows.Forms.ComboBox]$ProfileCombo,
        [PSCustomObject]$FormState
    )
    
    try {
        $ProfileCombo.Items.Clear()
        
        if ($FormState.Profiles -and $FormState.Profiles.Count -gt 0) {
            foreach ($profile in $FormState.Profiles) {
                [void]$ProfileCombo.Items.Add($profile.ProfileName)
            }
            
            # Set first profile as default
            if ($ProfileCombo.Items.Count -gt 0) {
                $ProfileCombo.SelectedIndex = 0
            }
        }
    }
    catch {
        Write-LogMessage -Message "Error loading profiles: $_" -Level "ERROR"
    }
}

<#
.SYNOPSIS
    Loads apps into a list box from FormState with category indicators
.PARAMETER AppsListBox
    The list box control to populate
.PARAMETER FormState
    The FormState object containing apps
#>
function Load-AppsIntoListBox {
    param(
        [System.Windows.Forms.ListBox]$AppsListBox,
        [PSCustomObject]$FormState
    )
    
    try {
        $AppsListBox.Items.Clear()
        
        if ($FormState.Apps -and $FormState.Apps.Count -gt 0) {
            $groupedApps = $FormState.Apps | Group-Object -Property Category
            
            foreach ($group in $groupedApps) {
                foreach ($app in $group.Group) {
                    $displayText = "[{0}] {1}" -f $group.Name, $app.AppName
                    [void]$AppsListBox.Items.Add($displayText)
                }
            }
        }
    }
    catch {
        Write-LogMessage -Message "Error loading apps: $_" -Level "ERROR"
    }
}

<#
.SYNOPSIS
    Loads services into a list box from FormState with critical indicators
.PARAMETER ServicesListBox
    The list box control to populate
.PARAMETER FormState
    The FormState object containing services
#>
function Load-ServicesIntoListBox {
    param(
        [System.Windows.Forms.ListBox]$ServicesListBox,
        [PSCustomObject]$FormState
    )
    
    try {
        $ServicesListBox.Items.Clear()
        
        if ($FormState.Services -and $FormState.Services.Count -gt 0) {
            $groupedServices = $FormState.Services | Group-Object -Property Category
            
            foreach ($group in $groupedServices) {
                foreach ($service in $group.Group) {
                    $criticalIndicator = if ($service.IsCritical) { "[⚠️ CRITICAL]" } else { "" }
                    $displayText = "{0} [{1}] {2}" -f $criticalIndicator, $group.Name, $service.ServiceName
                    [void]$ServicesListBox.Items.Add($displayText)
                }
            }
        }
    }
    catch {
        Write-LogMessage -Message "Error loading services: $_" -Level "ERROR"
    }
}

# ============================================================================
# PROFILE MANAGEMENT FUNCTIONS
# ============================================================================

<#
.SYNOPSIS
    Updates the profile description label based on selected profile
.PARAMETER DescriptionLabel
    The label control to display description
.PARAMETER ProfileCombo
    The combo box with selected profile
.PARAMETER FormState
    The FormState object containing profiles
#>
function Update-ProfileDescription {
    param(
        [System.Windows.Forms.Label]$DescriptionLabel,
        [System.Windows.Forms.ComboBox]$ProfileCombo,
        [PSCustomObject]$FormState
    )
    
    try {
        if ($ProfileCombo.SelectedIndex -ge 0) {
            $selectedProfile = $FormState.Profiles[$ProfileCombo.SelectedIndex]
            $DescriptionLabel.Text = $selectedProfile.Description
        }
    }
    catch {
        Write-LogMessage -Message "Error updating profile description: $_" -Level "ERROR"
    }
}

<#
.SYNOPSIS
    Updates FormState based on selected profile
.PARAMETER ProfileCombo
    The combo box with selected profile
.PARAMETER FormState
    The FormState object to update
#>
function Update-FormStateFromProfile {
    param(
        [System.Windows.Forms.ComboBox]$ProfileCombo,
        [PSCustomObject]$FormState
    )
    
    try {
        if ($ProfileCombo.SelectedIndex -ge 0) {
            $selectedProfile = $FormState.Profiles[$ProfileCombo.SelectedIndex]
            $FormState.SelectedProfile = $selectedProfile.ProfileName
            
            # Update app selections
            if ($selectedProfile.SelectedApps) {
                $FormState.SelectedApps = $selectedProfile.SelectedApps
            }
            
            # Update service selections
            if ($selectedProfile.SelectedServices) {
                $FormState.SelectedServices = $selectedProfile.SelectedServices
            }
        }
    }
    catch {
        Write-LogMessage -Message "Error updating FormState from profile: $_" -Level "ERROR"
    }
}

# ============================================================================
# USER PREFERENCES FUNCTIONS
# ============================================================================

<#
.SYNOPSIS
    Loads user preferences from %APPDATA%\preferences.json
.OUTPUTS
    [PSCustomObject] User preferences with defaults if file doesn't exist
#>
function Get-UserPreferences {
    try {
        $prefsPath = Join-Path $env:APPDATA "WindowsTelemetryBlocker\preferences.json"
        
        if (Test-Path $prefsPath) {
            $prefs = Get-Content $prefsPath -Raw | ConvertFrom-Json
            return $prefs
        }
        else {
            # Return defaults
            return [PSCustomObject]@{
                theme = "Dark"
                lastProfile = "Balanced"
                autoExpand = $true
                showCriticalWarnings = $true
                highlightMandatory = $true
            }
        }
    }
    catch {
        Write-LogMessage -Message "Error loading user preferences: $_" -Level "ERROR"
        return [PSCustomObject]@{ theme = "Dark" }
    }
}

<#
.SYNOPSIS
    Saves user preferences to %APPDATA%\preferences.json
.PARAMETER Preferences
    The preferences object to save
#>
function Save-UserPreferences {
    param(
        [PSCustomObject]$Preferences
    )
    
    try {
        $prefsDir = Join-Path $env:APPDATA "WindowsTelemetryBlocker"
        if (-not (Test-Path $prefsDir)) {
            New-Item -ItemType Directory -Path $prefsDir -Force | Out-Null
        }
        
        $prefsPath = Join-Path $prefsDir "preferences.json"
        $Preferences | ConvertTo-Json | Set-Content -Path $prefsPath -Force
    }
    catch {
        Write-LogMessage -Message "Error saving user preferences: $_" -Level "ERROR"
    }
}

<#
.SYNOPSIS
    Updates a single user preference and saves to file
.PARAMETER Key
    The preference key to update
.PARAMETER Value
    The value to set
#>
function Update-UserPreferences {
    param(
        [string]$Key,
        [object]$Value
    )
    
    try {
        $prefs = Get-UserPreferences
        if ($null -eq $prefs) {
            $prefs = [PSCustomObject]@{}
        }
        
        $prefs | Add-Member -NotePropertyName $Key -NotePropertyValue $Value -Force
        Save-UserPreferences -Preferences $prefs
    }
    catch {
        Write-LogMessage -Message "Error updating user preference '$Key': $_" -Level "ERROR"
    }
}

# ============================================================================
# VALIDATION FUNCTIONS
# ============================================================================

<#
.SYNOPSIS
    Validates that selected profile, apps, and services exist
.PARAMETER FormState
    The FormState object to validate
.PARAMETER SelectedApps
    Array of selected app indices
.PARAMETER SelectedServices
    Array of selected service indices
.OUTPUTS
    [bool] $true if valid, $false otherwise
#>
function Validate-ProfileSelection {
    param(
        [PSCustomObject]$FormState,
        [int[]]$SelectedApps,
        [int[]]$SelectedServices
    )
    
    try {
        # Check profile exists
        if ([string]::IsNullOrEmpty($FormState.SelectedProfile)) {
            Write-LogMessage -Message "No profile selected" -Level "WARNING"
            return $false
        }
        
        # Check at least one app or service selected
        if (($SelectedApps.Count -eq 0) -and ($SelectedServices.Count -eq 0)) {
            Write-LogMessage -Message "No apps or services selected" -Level "WARNING"
            return $false
        }
        
        return $true
    }
    catch {
        Write-LogMessage -Message "Error validating profile selection: $_" -Level "ERROR"
        return $false
    }
}

# ============================================================================
# EVENT HANDLER FACTORY FUNCTIONS
# ============================================================================

<#
.SYNOPSIS
    Creates a ScriptBlock for list box selection change events
.PARAMETER ListBox
    The list box control (captured in closure)
.PARAMETER FormState
    The FormState object (captured in closure)
.PARAMETER SelectionType
    Type of selection (Apps or Services)
.OUTPUTS
    [ScriptBlock] Event handler function
#>
function New-SelectionChangeHandler {
    param(
        [System.Windows.Forms.ListBox]$ListBox,
        [PSCustomObject]$FormState,
        [string]$SelectionType = "Unknown"
    )
    
    return {
        param($sender, $e)
        
        # Capture selected indices
        $selectedIndices = @()
        foreach ($i in 0..($ListBox.Items.Count - 1)) {
            if ($ListBox.SelectedIndices -contains $i) {
                $selectedIndices += $i
            }
        }
        
        # Update FormState based on selection type
        if ($SelectionType -eq "Apps") {
            $FormState.SelectedApps = $selectedIndices
        }
        elseif ($SelectionType -eq "Services") {
            $FormState.SelectedServices = $selectedIndices
        }
        
        Write-LogMessage -Message "$SelectionType selection changed (count: $($selectedIndices.Count))" -Level "DEBUG"
    }
}

<#
.SYNOPSIS
    Creates a ScriptBlock for profile combo box change events
.PARAMETER ProfileCombo
    The profile combo box
.PARAMETER AppsListBox
    The apps list box
.PARAMETER ServicesListBox
    The services list box
.PARAMETER DescriptionLabel
    The description label
.PARAMETER FormState
    The FormState object (captured in closure)
.OUTPUTS
    [ScriptBlock] Event handler function
#>
function New-ProfileChangeHandler {
    param(
        [System.Windows.Forms.ComboBox]$ProfileCombo,
        [System.Windows.Forms.ListBox]$AppsListBox,
        [System.Windows.Forms.ListBox]$ServicesListBox,
        [System.Windows.Forms.Label]$DescriptionLabel,
        [PSCustomObject]$FormState
    )
    
    return {
        param($sender, $e)
        
        # Update description
        Update-ProfileDescription -DescriptionLabel $DescriptionLabel `
                                 -ProfileCombo $ProfileCombo `
                                 -FormState $FormState
        
        # Update FormState with selected profile's apps/services
        Update-FormStateFromProfile -ProfileCombo $ProfileCombo `
                                   -FormState $FormState
        
        Write-LogMessage -Message "Profile changed to: $($ProfileCombo.SelectedItem)" -Level "DEBUG"
    }
}

# ============================================================================
# CONTENT REFRESH FUNCTIONS
# ============================================================================

<#
.SYNOPSIS
    Orchestrates loading all dynamic content into GUI controls
.PARAMETER ProfileCombo
    The profile combo box to populate
.PARAMETER AppsListBox
    The apps list box to populate
.PARAMETER ServicesListBox
    The services list box to populate
.PARAMETER DescriptionLabel
    The description label to update
.PARAMETER FormState
    The FormState object containing all data
#>
function Refresh-AllContent {
    param(
        [System.Windows.Forms.ComboBox]$ProfileCombo,
        [System.Windows.Forms.ListBox]$AppsListBox,
        [System.Windows.Forms.ListBox]$ServicesListBox,
        [System.Windows.Forms.Label]$DescriptionLabel,
        [PSCustomObject]$FormState
    )
    
    try {
        Write-LogMessage -Message "Refreshing all GUI content (Phase 2.2 Data Binding)" -Level "INFO"
        
        Load-ProfilesIntoComboBox -ProfileCombo $ProfileCombo -FormState $FormState
        Load-AppsIntoListBox -AppsListBox $AppsListBox -FormState $FormState
        Load-ServicesIntoListBox -ServicesListBox $ServicesListBox -FormState $FormState
        Update-ProfileDescription -DescriptionLabel $DescriptionLabel `
                                 -ProfileCombo $ProfileCombo `
                                 -FormState $FormState
    }
    catch {
        Write-LogMessage -Message "Error refreshing content: $_" -Level "ERROR"
    }
}

# ============================================================================
# STATISTICS FUNCTIONS
# ============================================================================

<#
.SYNOPSIS
    Calculates selection statistics for display
.PARAMETER FormState
    The FormState object containing all data
.PARAMETER SelectedApps
    Array of selected app indices
.PARAMETER SelectedServices
    Array of selected service indices
.OUTPUTS
    [PSCustomObject] Statistics object with counts and percentages
#>
function Get-SelectionStatistics {
    param(
        [PSCustomObject]$FormState,
        [int[]]$SelectedApps,
        [int[]]$SelectedServices
    )
    
    try {
        $totalApps = $FormState.Apps.Count
        $selectedAppsCount = $SelectedApps.Count
        $appsPercentage = if ($totalApps -gt 0) { [math]::Round(($selectedAppsCount / $totalApps) * 100) } else { 0 }
        
        $totalServices = $FormState.Services.Count
        $selectedServicesCount = $SelectedServices.Count
        $servicesPercentage = if ($totalServices -gt 0) { [math]::Round(($selectedServicesCount / $totalServices) * 100) } else { 0 }
        
        # Count critical services
        $criticalServices = @()
        foreach ($idx in $SelectedServices) {
            if ($idx -lt $FormState.Services.Count) {
                $service = $FormState.Services[$idx]
                if ($service.IsCritical) {
                    $criticalServices += $service
                }
            }
        }
        
        return [PSCustomObject]@{
            TotalApps = $totalApps
            SelectedApps = $selectedAppsCount
            AppsPercentage = $appsPercentage
            TotalServices = $totalServices
            SelectedServices = $selectedServicesCount
            ServicesPercentage = $servicesPercentage
            CriticalServicesSelected = $criticalServices.Count
        }
    }
    catch {
        Write-LogMessage -Message "Error calculating statistics: $_" -Level "ERROR"
        return $null
    }
}

# ============================================================================
# EXPORTS
# ============================================================================

Export-ModuleMember -Function @(
    'Load-ProfilesIntoComboBox',
    'Load-AppsIntoListBox',
    'Load-ServicesIntoListBox',
    'Update-ProfileDescription',
    'Update-FormStateFromProfile',
    'Get-UserPreferences',
    'Save-UserPreferences',
    'Update-UserPreferences',
    'Validate-ProfileSelection',
    'New-SelectionChangeHandler',
    'New-ProfileChangeHandler',
    'Refresh-AllContent',
    'Get-SelectionStatistics'
) -Variable @('FilterGroup', 'AppMetadata', 'ServiceMetadata')
