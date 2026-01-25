# ===============================
# Configuration Manager
# v1.0 - Profile & Settings Management
# ===============================

param(
    [string]$Action = "load",
    [string]$ProfileName = "balanced",
    [hashtable]$CustomSettings = @{}
)

# Configuration directories
$appDataPath = [Environment]::GetFolderPath("ApplicationData")
$configDir = Join-Path $appDataPath "WindowsTelemetryBlocker"
$profilesFile = Join-Path $PSScriptRoot "profiles.json"
$userConfigFile = Join-Path $configDir "user-config.json"
$lastStateFile = Join-Path $configDir "last-execution.json"

# ===============================
# Utility Functions
# ===============================

function Ensure-ConfigDirectory {
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        Write-Host "[INFO] Created config directory: $configDir" -ForegroundColor Green
    }
}

function Load-ProfilesDefinition {
    <#
    .SYNOPSIS
    Load the predefined profiles from profiles.json
    #>
    if (-not (Test-Path $profilesFile)) {
        throw "Profiles definition file not found: $profilesFile"
    }
    
    try {
        $profiles = Get-Content $profilesFile -Raw | ConvertFrom-Json
        return $profiles
    } catch {
        throw "Failed to parse profiles.json: $_"
    }
}

function Load-UserConfig {
    <#
    .SYNOPSIS
    Load user configuration or create default if not exists
    #>
    if (Test-Path $userConfigFile) {
        try {
            $config = Get-Content $userConfigFile -Raw | ConvertFrom-Json
            return $config
        } catch {
            Write-Host "[WARN] Failed to parse user config, using defaults" -ForegroundColor Yellow
            return $null
        }
    }
    return $null
}

function Save-UserConfig {
    <#
    .SYNOPSIS
    Save user configuration to disk
    #>
    param(
        [parameter(Mandatory)]
        [psobject]$Config
    )
    
    Ensure-ConfigDirectory
    
    try {
        $Config | ConvertTo-Json -Depth 10 | Set-Content $userConfigFile -Encoding UTF8
        Write-Host "[OK] Config saved: $userConfigFile" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "[ERROR] Failed to save config: $_" -ForegroundColor Red
        return $false
    }
}

function Get-Profile {
    <#
    .SYNOPSIS
    Get a specific profile by name
    #>
    param(
        [parameter(Mandatory)]
        [string]$Name,
        
        [parameter(Mandatory)]
        [psobject]$Profiles
    )
    
    if ($Profiles.profiles.$Name) {
        return $Profiles.profiles.$Name
    } else {
        throw "Profile not found: $Name"
    }
}

function New-DefaultUserConfig {
    <#
    .SYNOPSIS
    Create a default user configuration object
    #>
    $config = @{
        version = "1.0"
        created = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        last_profile = "balanced"
        auto_schedule = $false
        schedule_frequency = "weekly"
        schedule_time = "22:00"
        enable_monitoring = $false
        monitoring_interval = 180
        auto_remediate = $false
        theme = "dark"
        gui_position = @{
            x = 100
            y = 100
            width = 900
            height = 700
        }
        last_execution = @{
            timestamp = $null
            profile = "balanced"
            modules_run = @()
            status = $null
        }
    }
    
    return $config | ConvertTo-Json -Depth 10 | ConvertFrom-Json
}

function List-Profiles {
    <#
    .SYNOPSIS
    List all available profiles
    #>
    param(
        [parameter(Mandatory)]
        [psobject]$Profiles
    )
    
    Write-Host "`n=== Available Profiles ===" -ForegroundColor Cyan
    
    foreach ($profileName in $Profiles.profiles.PSObject.Properties.Name) {
        $profile = $Profiles.profiles.$profileName
        $recommended = if ($profile.recommended) { "[RECOMMENDED]" } else { "" }
        
        Write-Host "`n▶ $($profile.name) $recommended"
        Write-Host "  Description: $($profile.description)"
        Write-Host "  Modules: $($profile.modules -join ', ')"
        Write-Host "  Apps to remove: $($profile.apps_remove.Count)"
        Write-Host "  Services to disable: $($profile.services_disable.Count)"
    }
    
    Write-Host "`n"
}

function Validate-Profile {
    <#
    .SYNOPSIS
    Validate that a profile has required fields
    #>
    param(
        [parameter(Mandatory)]
        [psobject]$Profile
    )
    
    $required = @('name', 'description', 'modules', 'apps_remove', 'services_disable')
    
    foreach ($field in $required) {
        if (-not $Profile.PSObject.Properties.Name.Contains($field)) {
            throw "Profile missing required field: $field"
        }
    }
    
    return $true
}

function Validate-Config {
    <#
    .SYNOPSIS
    Validate user configuration
    #>
    param(
        [parameter(Mandatory)]
        [psobject]$Config
    )
    
    $required = @('version', 'last_profile', 'enable_monitoring', 'auto_remediate')
    
    foreach ($field in $required) {
        if (-not $Config.PSObject.Properties.Name.Contains($field)) {
            Write-Host "[WARN] Config missing field: $field" -ForegroundColor Yellow
            return $false
        }
    }
    
    return $true
}

function Export-Config {
    <#
    .SYNOPSIS
    Export current configuration to file
    #>
    param(
        [parameter(Mandatory)]
        [string]$FilePath,
        
        [parameter(Mandatory)]
        [psobject]$Config
    )
    
    try {
        $Config | ConvertTo-Json -Depth 10 | Set-Content $FilePath -Encoding UTF8
        Write-Host "[OK] Config exported to: $FilePath" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "[ERROR] Failed to export config: $_" -ForegroundColor Red
        return $false
    }
}

function Import-Config {
    <#
    .SYNOPSIS
    Import configuration from file
    #>
    param(
        [parameter(Mandatory)]
        [string]$FilePath
    )
    
    if (-not (Test-Path $FilePath)) {
        throw "Config file not found: $FilePath"
    }
    
    try {
        $config = Get-Content $FilePath -Raw | ConvertFrom-Json
        
        if (-not (Validate-Config $config)) {
            throw "Imported config validation failed"
        }
        
        Write-Host "[OK] Config imported from: $FilePath" -ForegroundColor Green
        return $config
    } catch {
        throw "Failed to import config: $_"
    }
}

function Save-ExecutionState {
    <#
    .SYNOPSIS
    Save the execution state for monitoring/recovery
    #>
    param(
        [parameter(Mandatory)]
        [string]$ProfileName,
        
        [parameter(Mandatory)]
        [string[]]$ModulesRun,
        
        [string]$Status = "completed"
    )
    
    Ensure-ConfigDirectory
    
    $state = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        profile = $ProfileName
        modules_run = $ModulesRun
        status = $Status
    }
    
    try {
        $state | ConvertTo-Json | Set-Content $lastStateFile -Encoding UTF8
        return $true
    } catch {
        Write-Host "[WARN] Failed to save execution state: $_" -ForegroundColor Yellow
        return $false
    }
}

function Get-ExecutionState {
    <#
    .SYNOPSIS
    Get the last execution state
    #>
    if (Test-Path $lastStateFile) {
        try {
            return Get-Content $lastStateFile -Raw | ConvertFrom-Json
        } catch {
            return $null
        }
    }
    return $null
}

# ===============================
# Main Actions
# ===============================

switch ($Action.ToLower()) {
    "load" {
        # Load profile configuration
        try {
            Ensure-ConfigDirectory
            $profiles = Load-ProfilesDefinition
            $userConfig = Load-UserConfig
            
            if ($null -eq $userConfig) {
                $userConfig = New-DefaultUserConfig
                Save-UserConfig $userConfig
            }
            
            $selectedProfile = Get-Profile -Name $ProfileName -Profiles $profiles
            Validate-Profile $selectedProfile | Out-Null
            
            Write-Host "[OK] Profile loaded: $ProfileName" -ForegroundColor Green
            
            return @{
                Profile = $selectedProfile
                UserConfig = $userConfig
                Profiles = $profiles
            }
        } catch {
            Write-Host "[ERROR] Failed to load profile: $_" -ForegroundColor Red
            exit 1
        }
    }
    
    "list" {
        # List available profiles
        try {
            $profiles = Load-ProfilesDefinition
            List-Profiles -Profiles $profiles
        } catch {
            Write-Host "[ERROR] Failed to list profiles: $_" -ForegroundColor Red
            exit 1
        }
    }
    
    "save" {
        # Save user configuration
        try {
            $userConfig = Load-UserConfig
            if ($null -eq $userConfig) {
                $userConfig = New-DefaultUserConfig
            }
            
            # Update with custom settings
            foreach ($key in $CustomSettings.Keys) {
                $userConfig | Add-Member -MemberType NoteProperty -Name $key -Value $CustomSettings[$key] -Force
            }
            
            Save-UserConfig -Config $userConfig
        } catch {
            Write-Host "[ERROR] Failed to save config: $_" -ForegroundColor Red
            exit 1
        }
    }
    
    "export" {
        # Export configuration
        if ($CustomSettings.ContainsKey("Path")) {
            try {
                $userConfig = Load-UserConfig
                if ($null -eq $userConfig) {
                    $userConfig = New-DefaultUserConfig
                }
                Export-Config -FilePath $CustomSettings["Path"] -Config $userConfig
            } catch {
                Write-Host "[ERROR] Failed to export config: $_" -ForegroundColor Red
                exit 1
            }
        } else {
            Write-Host "[ERROR] Path parameter required for export" -ForegroundColor Red
            exit 1
        }
    }
    
    "import" {
        # Import configuration
        if ($CustomSettings.ContainsKey("Path")) {
            try {
                $config = Import-Config -FilePath $CustomSettings["Path"]
                Save-UserConfig -Config $config
            } catch {
                Write-Host "[ERROR] Failed to import config: $_" -ForegroundColor Red
                exit 1
            }
        } else {
            Write-Host "[ERROR] Path parameter required for import" -ForegroundColor Red
            exit 1
        }
    }
    
    "state" {
        # Get/set execution state
        if ($CustomSettings.ContainsKey("Save")) {
            $modulesRun = $CustomSettings["Modules"] -as [string[]]
            $status = $CustomSettings["Status"] -as [string]
            Save-ExecutionState -ProfileName $ProfileName -ModulesRun $modulesRun -Status $status
        } else {
            $state = Get-ExecutionState
            if ($state) {
                $state | ConvertTo-Json
            } else {
                Write-Host "[INFO] No execution state found"
            }
        }
    }
    
    "validate" {
        # Validate configurations
        try {
            $profiles = Load-ProfilesDefinition
            $userConfig = Load-UserConfig
            
            Write-Host "[OK] Profiles definition is valid" -ForegroundColor Green
            
            if ($userConfig) {
                if (Validate-Config $userConfig) {
                    Write-Host "[OK] User config is valid" -ForegroundColor Green
                } else {
                    Write-Host "[WARN] User config has issues" -ForegroundColor Yellow
                }
            } else {
                Write-Host "[INFO] No user config file exists (will create on first save)" -ForegroundColor Cyan
            }
        } catch {
            Write-Host "[ERROR] Validation failed: $_" -ForegroundColor Red
            exit 1
        }
    }
    
    default {
        Write-Host @"
Config Manager v1.0
Usage: .\config-manager.ps1 -Action <action> [-ProfileName <name>] [-CustomSettings <hashtable>]

Actions:
  load       Load profile configuration (default)
  list       List all available profiles
  save       Save user configuration
  export     Export configuration to file (-CustomSettings @{Path="file.json"})
  import     Import configuration from file (-CustomSettings @{Path="file.json"})
  state      Get/save execution state
  validate   Validate all configurations

Examples:
  .\config-manager.ps1 -Action list
  .\config-manager.ps1 -Action load -ProfileName maximum
  .\config-manager.ps1 -Action save -CustomSettings @{auto_schedule=$true}
  .\config-manager.ps1 -Action export -CustomSettings @{Path="C:\backup.json"}
"@
    }
}
