# Phase 5: Monitoring Dashboard and Alerting System
# Real-time monitoring UI and alerting mechanisms
# Provides visual monitoring dashboard and alert management

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ============================================================================
# ALERT CLASSES
# ============================================================================

class MonitoringAlert {
    [string]$AlertId
    [string]$Timestamp
    [string]$AlertType        # Registry, Service, EventLog
    [string]$Severity         # Low, Medium, High, Critical
    [string]$Title
    [string]$Description
    [bool]$IsResolved
    [string]$ResolvedTime
    [bool]$IsAcknowledged
    
    MonitoringAlert([string]$Type, [string]$Sev, [string]$Title, [string]$Desc) {
        $this.AlertId = [guid]::NewGuid().ToString()
        $this.Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $this.AlertType = $Type
        $this.Severity = $Sev
        $this.Title = $Title
        $this.Description = $Desc
        $this.IsResolved = $false
        $this.IsAcknowledged = $false
    }
}

# ============================================================================
# ALERT MANAGEMENT
# ============================================================================

<#
.SYNOPSIS
    Creates a new alert from monitoring event
.PARAMETER AlertType
    Type of alert (Registry, Service, EventLog)
.PARAMETER Severity
    Severity level (Low, Medium, High, Critical)
.PARAMETER Title
    Alert title
.PARAMETER Description
    Alert description
.PARAMETER AlertPath
    Path to save alerts
.OUTPUTS
    [MonitoringAlert] Created alert object
#>
function New-MonitoringAlert {
    param(
        [string]$AlertType,
        [string]$Severity,
        [string]$Title,
        [string]$Description,
        [string]$AlertPath = (Join-Path $env:APPDATA "WindowsTelemetryBlocker\alerts.json")
    )
    
    try {
        $alert = [MonitoringAlert]::new($AlertType, $Severity, $Title, $Description)
        
        # Save alert
        $alertDir = Split-Path $AlertPath
        if (-not (Test-Path $alertDir)) {
            New-Item -ItemType Directory -Path $alertDir -Force | Out-Null
        }
        
        $alerts = @()
        if (Test-Path $AlertPath) {
            $alerts = @(Get-Content $AlertPath -Raw | ConvertFrom-Json)
        }
        
        $alerts += @{
            AlertId = $alert.AlertId
            Timestamp = $alert.Timestamp
            AlertType = $alert.AlertType
            Severity = $alert.Severity
            Title = $alert.Title
            Description = $alert.Description
            IsResolved = $alert.IsResolved
            IsAcknowledged = $alert.IsAcknowledged
        }
        
        # Keep last 500 alerts
        if ($alerts.Count -gt 500) {
            $alerts = $alerts[-500..-1]
        }
        
        $alerts | ConvertTo-Json -Depth 5 | Set-Content -Path $AlertPath -Force
        
        return $alert
    }
    catch {
        Write-Host "Error creating monitoring alert: $_" -ForegroundColor Red
        return $null
    }
}

<#
.SYNOPSIS
    Retrieves active alerts
.PARAMETER AlertPath
    Path to alerts JSON file
.PARAMETER Severity
    Filter by severity (optional)
.OUTPUTS
    [PSCustomObject[]] Array of active alerts
#>
function Get-ActiveAlerts {
    param(
        [string]$AlertPath = (Join-Path $env:APPDATA "WindowsTelemetryBlocker\alerts.json"),
        [string]$Severity = $null
    )
    
    try {
        if (-not (Test-Path $AlertPath)) {
            return @()
        }
        
        $alerts = @(Get-Content $AlertPath -Raw | ConvertFrom-Json)
        $activeAlerts = $alerts | Where-Object { -not $_.IsResolved }
        
        if ($Severity) {
            $activeAlerts = $activeAlerts | Where-Object { $_.Severity -eq $Severity }
        }
        
        return $activeAlerts | Sort-Object -Property Timestamp -Descending
    }
    catch {
        return @()
    }
}

<#
.SYNOPSIS
    Acknowledges an alert
.PARAMETER AlertId
    ID of alert to acknowledge
.PARAMETER AlertPath
    Path to alerts JSON file
.OUTPUTS
    [bool] $true if successful, $false otherwise
#>
function Acknowledge-MonitoringAlert {
    param(
        [string]$AlertId,
        [string]$AlertPath = (Join-Path $env:APPDATA "WindowsTelemetryBlocker\alerts.json")
    )
    
    try {
        if (-not (Test-Path $AlertPath)) {
            return $false
        }
        
        $alerts = @(Get-Content $AlertPath -Raw | ConvertFrom-Json)
        $alert = $alerts | Where-Object { $_.AlertId -eq $AlertId }
        
        if ($alert) {
            $alert.IsAcknowledged = $true
            $alerts | ConvertTo-Json -Depth 5 | Set-Content -Path $AlertPath -Force
            return $true
        }
        
        return $false
    }
    catch {
        return $false
    }
}

# ============================================================================
# MONITORING DASHBOARD
# ============================================================================

<#
.SYNOPSIS
    Shows the monitoring dashboard UI
.PARAMETER Owner
    Parent form for dialog
.PARAMETER Theme
    Current theme
.OUTPUTS
    [System.Windows.Forms.DialogResult] Dialog result
#>
function Show-MonitoringDashboard {
    param(
        [System.Windows.Forms.Form]$Owner,
        [string]$Theme = "Dark"
    )
    
    try {
        # Create dashboard window
        $dashboard = New-Object System.Windows.Forms.Form
        $dashboard.Text = "Telemetry Monitoring Dashboard"
        $dashboard.Size = New-Object System.Drawing.Size(900, 700)
        $dashboard.StartPosition = "CenterParent"
        $dashboard.Owner = $Owner
        $dashboard.Icon = $Owner.Icon
        
        # Theme colors
        $bgColor = if ($Theme -eq "Dark") { [System.Drawing.Color]::FromArgb(45, 45, 48) } else { [System.Drawing.Color]::White }
        $fgColor = if ($Theme -eq "Dark") { [System.Drawing.Color]::White } else { [System.Drawing.Color]::Black }
        $panelColor = if ($Theme -eq "Dark") { [System.Drawing.Color]::FromArgb(60, 60, 60) } else { [System.Drawing.Color]::FromArgb(240, 240, 240) }
        $accentColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
        
        $dashboard.BackColor = $bgColor
        $dashboard.ForeColor = $fgColor
        
        # ===== STATUS PANEL =====
        $statusPanel = New-Object System.Windows.Forms.Panel
        $statusPanel.Location = New-Object System.Drawing.Point(10, 10)
        $statusPanel.Size = New-Object System.Drawing.Size(870, 120)
        $statusPanel.BackColor = $panelColor
        $statusPanel.BorderStyle = "FixedSingle"
        
        # Title
        $titleLabel = New-Object System.Windows.Forms.Label
        $titleLabel.Text = "System Status"
        $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
        $titleLabel.Location = New-Object System.Drawing.Point(10, 10)
        $titleLabel.Size = New-Object System.Drawing.Size(200, 25)
        $titleLabel.ForeColor = $fgColor
        $statusPanel.Controls.Add($titleLabel)
        
        # Status indicators
        $statY = 40
        $stats = @(
            @{ Label = 'Registry Status:'; Value = 'Monitored'; Color = [System.Drawing.Color]::Green },
            @{ Label = 'Service Status:'; Value = 'Monitored'; Color = [System.Drawing.Color]::Green },
            @{ Label = 'Alert Level:'; Value = 'Normal'; Color = [System.Drawing.Color]::Yellow }
        )
        
        foreach ($stat in $stats) {
            $label = New-Object System.Windows.Forms.Label
            $label.Text = $stat.Label
            $label.Location = New-Object System.Drawing.Point(20, $statY)
            $label.Size = New-Object System.Drawing.Size(150, 20)
            $label.ForeColor = $fgColor
            $statusPanel.Controls.Add($label)
            
            $value = New-Object System.Windows.Forms.Label
            $value.Text = $stat.Value
            $value.Location = New-Object System.Drawing.Point(180, $statY)
            $value.Size = New-Object System.Drawing.Size(200, 20)
            $value.ForeColor = $stat.Color
            $value.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
            $statusPanel.Controls.Add($value)
            
            $statY += 25
        }
        
        $dashboard.Controls.Add($statusPanel)
        
        # ===== ALERTS PANEL =====
        $alertsPanel = New-Object System.Windows.Forms.Panel
        $alertsPanel.Location = New-Object System.Drawing.Point(10, 140)
        $alertsPanel.Size = New-Object System.Drawing.Size(870, 300)
        $alertsPanel.BackColor = $panelColor
        $alertsPanel.BorderStyle = "FixedSingle"
        
        $alertsLabel = New-Object System.Windows.Forms.Label
        $alertsLabel.Text = "Active Alerts"
        $alertsLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
        $alertsLabel.Location = New-Object System.Drawing.Point(10, 10)
        $alertsLabel.Size = New-Object System.Drawing.Size(200, 25)
        $alertsLabel.ForeColor = $fgColor
        $alertsPanel.Controls.Add($alertsLabel)
        
        # Alerts ListBox
        $alertsList = New-Object System.Windows.Forms.ListBox
        $alertsList.Location = New-Object System.Drawing.Point(10, 40)
        $alertsList.Size = New-Object System.Drawing.Size(850, 250)
        $alertsList.BackColor = if ($Theme -eq "Dark") { [System.Drawing.Color]::FromArgb(45, 45, 48) } else { [System.Drawing.Color]::White }
        $alertsList.ForeColor = $fgColor
        $alertsList.BorderStyle = "FixedSingle"
        
        # Load active alerts
        $activeAlerts = Get-ActiveAlerts
        foreach ($alert in $activeAlerts) {
            $severityIcon = switch ($alert.Severity) {
                'Critical' { 'â›”' }
                'High' { 'âš ï¸' }
                'Medium' { 'âš¡' }
                'Low' { 'â„¹ï¸' }
                default { '?' }
            }
            
            $displayText = "[$($alert.Severity)] $severityIcon $($alert.Title)"
            [void]$alertsList.Items.Add($displayText)
        }
        
        $alertsPanel.Controls.Add($alertsList)
        $dashboard.Controls.Add($alertsPanel)
        
        # ===== STATISTICS PANEL =====
        $statsPanel = New-Object System.Windows.Forms.Panel
        $statsPanel.Location = New-Object System.Drawing.Point(10, 450)
        $statsPanel.Size = New-Object System.Drawing.Size(870, 170)
        $statsPanel.BackColor = $panelColor
        $statsPanel.BorderStyle = "FixedSingle"
        
        $statsLabel = New-Object System.Windows.Forms.Label
        $statsLabel.Text = "Monitoring Statistics"
        $statsLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
        $statsLabel.Location = New-Object System.Drawing.Point(10, 10)
        $statsLabel.Size = New-Object System.Drawing.Size(200, 25)
        $statsLabel.ForeColor = $fgColor
        $statsPanel.Controls.Add($statsLabel)
        
        # Statistics info
        $statsInfo = New-Object System.Windows.Forms.TextBox
        $statsInfo.Multiline = $true
        $statsInfo.ReadOnly = $true
        $statsInfo.Location = New-Object System.Drawing.Point(10, 40)
        $statsInfo.Size = New-Object System.Drawing.Size(850, 120)
        $statsInfo.BackColor = if ($Theme -eq "Dark") { [System.Drawing.Color]::FromArgb(45, 45, 48) } else { [System.Drawing.Color]::White }
        $statsInfo.ForeColor = $fgColor
        $statsInfo.Text = @"
Total Active Alerts: $($activeAlerts.Count)
Critical Alerts: $(($activeAlerts | Where-Object { $_.Severity -eq 'Critical' }).Count)
High Severity Alerts: $(($activeAlerts | Where-Object { $_.Severity -eq 'High' }).Count)

Last Update: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Dashboard Status: Running
"@
        $statsPanel.Controls.Add($statsInfo)
        $dashboard.Controls.Add($statsPanel)
        
        # ===== ACTION BUTTONS =====
        $refreshBtn = New-Object System.Windows.Forms.Button
        $refreshBtn.Text = "Refresh"
        $refreshBtn.Location = New-Object System.Drawing.Point(10, 630)
        $refreshBtn.Size = New-Object System.Drawing.Size(90, 35)
        $refreshBtn.BackColor = $accentColor
        $refreshBtn.ForeColor = "White"
        $refreshBtn.Cursor = "Hand"
        $refreshBtn.Add_Click({
            # Refresh dashboard data
            $alertsList.Items.Clear()
            $activeAlerts = Get-ActiveAlerts
            foreach ($alert in $activeAlerts) {
                $severityIcon = switch ($alert.Severity) {
                    'Critical' { 'â›”' }
                    'High' { 'âš ï¸' }
                    'Medium' { 'âš¡' }
                    'Low' { 'â„¹ï¸' }
                    default { '?' }
                }
                $displayText = "[$($alert.Severity)] $severityIcon $($alert.Title)"
                [void]$alertsList.Items.Add($displayText)
            }
        })
        $dashboard.Controls.Add($refreshBtn)
        
        $closeBtn = New-Object System.Windows.Forms.Button
        $closeBtn.Text = "Close"
        $closeBtn.Location = New-Object System.Drawing.Point(790, 630)
        $closeBtn.Size = New-Object System.Drawing.Size(90, 35)
        $closeBtn.BackColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
        $closeBtn.ForeColor = "White"
        $closeBtn.Cursor = "Hand"
        $closeBtn.Add_Click({ $dashboard.Close() })
        $dashboard.Controls.Add($closeBtn)
        
        return $dashboard.ShowDialog()
    }
    catch {
        Write-Host "Error showing monitoring dashboard: $_" -ForegroundColor Red
        return "Error"
    }
}

# ============================================================================
# ALERT NOTIFICATIONS
# ============================================================================

<#
.SYNOPSIS
    Shows a toast-style notification for alerts
.PARAMETER Alert
    MonitoringAlert object to display
#>
function Show-AlertNotification {
    param(
        [MonitoringAlert]$Alert
    )
    
    try {
        $notificationForm = New-Object System.Windows.Forms.Form
        $notificationForm.Text = "Monitoring Alert"
        $notificationForm.Size = New-Object System.Drawing.Size(400, 150)
        $notificationForm.StartPosition = "Manual"
        
        # Position in bottom right
        $screen = [System.Windows.Forms.Screen]::PrimaryScreen
        $notificationForm.Location = New-Object System.Drawing.Point(
            $screen.WorkingArea.Width - 410,
            $screen.WorkingArea.Height - 160
        )
        
        # Set colors based on severity
        $bgColor = switch ($Alert.Severity) {
            'Critical' { [System.Drawing.Color]::FromArgb(204, 41, 54) }
            'High' { [System.Drawing.Color]::FromArgb(255, 140, 0) }
            'Medium' { [System.Drawing.Color]::FromArgb(255, 193, 7) }
            default { [System.Drawing.Color]::FromArgb(33, 150, 243) }
        }
        
        $notificationForm.BackColor = $bgColor
        $notificationForm.ForeColor = "White"
        
        $titleLabel = New-Object System.Windows.Forms.Label
        $titleLabel.Text = $Alert.Title
        $titleLabel.Location = New-Object System.Drawing.Point(10, 10)
        $titleLabel.Size = New-Object System.Drawing.Size(380, 25)
        $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $titleLabel.ForeColor = "White"
        $notificationForm.Controls.Add($titleLabel)
        
        $descLabel = New-Object System.Windows.Forms.Label
        $descLabel.Text = $Alert.Description
        $descLabel.Location = New-Object System.Drawing.Point(10, 40)
        $descLabel.Size = New-Object System.Drawing.Size(380, 60)
        $descLabel.AutoSize = $true
        $descLabel.ForeColor = "White"
        $notificationForm.Controls.Add($descLabel)
        
        # Auto-close after 5 seconds
        $timer = New-Object System.Windows.Forms.Timer
        $timer.Interval = 5000
        $timer.Add_Tick({
            $timer.Stop()
            $notificationForm.Close()
        })
        $timer.Start()
        
        [void]$notificationForm.ShowDialog()
    }
    catch {
        # Silent fail for notifications
    }
}

# ============================================================================
# EXPORTS
# ============================================================================




