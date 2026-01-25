# Quick Reference: Phase 2.2, 2.4, and 4

## Phase 2.2: Data Binding System

### Core Functions

**Profile Loading**
```powershell
Load-ProfilesIntoComboBox -ProfileCombo $combo -FormState $state
Update-ProfileDescription -DescriptionLabel $label -ProfileCombo $combo -FormState $state
```

**Dynamic Content**
```powershell
Load-AppsIntoListBox -AppsListBox $list -FormState $state
Load-ServicesIntoListBox -ServicesListBox $list -FormState $state
Refresh-AllContent -ProfileCombo ... -AppsListBox ... -ServicesListBox ... -FormState ...
```

**User Preferences**
```powershell
$prefs = Get-UserPreferences                    # Load from %APPDATA%
Update-UserPreferences -Key "theme" -Value "Dark"  # Save single value
Save-UserPreferences -Preferences $prefs        # Save all preferences
```

**Event Handlers**
```powershell
$handler = New-ProfileChangeHandler -ProfileCombo ... -AppsListBox ... -FormState ...
$handler = New-SelectionChangeHandler -ListBox ... -FormState ... -SelectionType "Apps"
```

**Statistics**
```powershell
$stats = Get-SelectionStatistics -FormState $state -SelectedApps @(0,1,2) -SelectedServices @(0,1)
# Returns: TotalApps, SelectedApps, AppsPercentage, TotalServices, SelectedServices, ServicesPercentage, CriticalServicesSelected
```

---

## Phase 2.4: Advanced Options

### Location
`launcher-gui.ps1` → `Show-AdvancedOptionsDialog` function

### Features
- Theme selector (dark, light, high-contrast)
- Selection statistics button
- Advanced filtering button (Phase 3)
- Custom profile creation
- Task scheduler button (Phase 4)
- Import/export functionality

### Theme Persistence
```powershell
$themeCombo.Add_SelectedIndexChanged({
    Save-UserTheme -ThemeName $themeCombo.SelectedItem
    Update-UserPreferences -Key "theme" -Value $themeCombo.SelectedItem
})
```

---

## Phase 4: Task Scheduler

### Task Creation
```powershell
$result = New-ScheduledTelemetryTask `
    -TaskName "BlockTelemetry_Daily" `
    -Profile "Balanced" `
    -Schedule "DAILY" `
    -Time "02:00" `
    -DryRun $false `
    -Quiet $false

if ($result.Success) {
    Write-Host "Task created: $($result.TaskName)"
}
```

### Task Management
```powershell
$tasks = Get-ScheduledTelemetryTasks                    # Get all tasks
$details = Get-TaskDetails -TaskName "BlockTelemetry"   # Get task details
Start-ScheduledTask -TaskName "BlockTelemetry"          # Run immediately
Stop-ScheduledTaskForce -TaskName "BlockTelemetry"      # Stop running
Enable-ScheduledTask -TaskName "BlockTelemetry"         # Re-enable
Disable-ScheduledTask -TaskName "BlockTelemetry"        # Disable
Remove-ScheduledTelemetryTask -TaskName "BlockTelemetry"  # Delete
```

### Tracking and Stats
```powershell
$history = Get-TaskExecutionHistory -TaskName "BlockTelemetry" -MaxEntries 10
$stats = Get-ScheduleStatistics
# Returns: TotalTasks, EnabledTasks, DisabledTasks, RunningTasks, ReadyTasks, ErrorTasks
```

### Scheduler UI
```powershell
Show-SchedulerDialog -Owner $form -Theme "Dark"
# Opens tabbed dialog with Create Task and Manage Tasks tabs
```

---

## Integration in Main()

```powershell
# Load user preferences (Phase 2.2)
$userPrefs = Get-UserPreferences
Initialize-Theme -ThemeName $userPrefs.theme

# Load all content dynamically (Phase 2.2)
Refresh-AllContent -ProfileCombo $profilePanel.ComboBox `
    -AppsListBox $selectionPanel.AppsListBox `
    -ServicesListBox $selectionPanel.ServicesListBox `
    -DescriptionLabel $profilePanel.DescriptionLabel `
    -FormState $script:FormState

# Wire event handlers (Phase 2.2)
$profileChangeHandler = New-ProfileChangeHandler -ProfileCombo ... -FormState ...
$profilePanel.ComboBox.Add_SelectedIndexChanged($profileChangeHandler)

$appsHandler = New-SelectionChangeHandler -ListBox $selectionPanel.AppsListBox `
    -FormState $script:FormState -SelectionType "Apps"
$selectionPanel.AppsListBox.Add_SelectedIndexChanged($appsHandler)
```

---

## User Preferences JSON Structure

**Location:** `%APPDATA%\WindowsTelemetryBlocker\preferences.json`

```json
{
  "theme": "Dark",
  "lastProfile": "Balanced",
  "autoExpand": true,
  "showCriticalWarnings": true,
  "highlightMandatory": true
}
```

---

## Schedule Type Reference

| Type | Behavior | Example |
|------|----------|---------|
| DAILY | Runs every day at specified time | 02:00 every day |
| WEEKLY | Runs every Monday at specified time | 02:00 every Monday |
| MONTHLY | Runs 1st of month at specified time | 02:00 on 1st of month |

---

## Task Execution Details

- **Account:** NT AUTHORITY\SYSTEM
- **Privilege Level:** Highest
- **Window Style:** Hidden
- **Profile Loading:** No profile (clean environment)
- **Command Format:** `launcher-gui.ps1 -DefaultProfile <profile> [-DryRun] [-Quiet]`

---

## Error Handling

All functions include try-catch with logging:

```powershell
try {
    # Operation
}
catch {
    Write-LogMessage -Message "Error message: $_" -Level "ERROR"
}
```

Validation functions return boolean or object with Success flag:

```powershell
$valid = Validate-ScheduleTime -Time "02:00"          # Returns $true/$false
$valid = Validate-ScheduleType -ScheduleType "DAILY"   # Returns $true/$false
```

---

## Performance Notes

- Profile loading: O(n) where n = number of profiles
- App/service loading: O(n*m) where n = apps/services, m = categories
- Statistics calculation: O(n*m) where n = selected items, m = services
- Task enumeration: Filtered from full Task Scheduler list

---

## Testing Checklist

- [ ] Profile selector loads and changes profiles
- [ ] Apps/services display with correct categories/indicators
- [ ] User preferences save and load correctly
- [ ] Theme selector updates and persists
- [ ] Statistics button shows correct percentages
- [ ] Task scheduler dialog opens from advanced options
- [ ] Create task with DAILY/WEEKLY/MONTHLY schedules
- [ ] View created tasks in manage tab
- [ ] Start/stop/delete tasks work correctly
- [ ] Task execution history displays
- [ ] Scheduler statistics aggregate correctly

---

## Common Tasks

### Create a daily telemetry blocking task
```powershell
New-ScheduledTelemetryTask -TaskName "DailyBlockTelemetry" `
    -Profile "Maximum" -Schedule "DAILY" -Time "02:00"
```

### List all scheduled tasks
```powershell
Get-ScheduledTelemetryTasks | ForEach-Object {
    Write-Host "$($_.TaskName): $($_.State) [$($_.Enabled)]"
}
```

### Display task statistics
```powershell
$stats = Get-ScheduleStatistics
Write-Host "Total: $($stats.TotalTasks), Enabled: $($stats.EnabledTasks), Running: $($stats.RunningTasks)"
```

### Get user's last used profile
```powershell
$prefs = Get-UserPreferences
Write-Host "Last profile: $($prefs.lastProfile)"
```

---

## Troubleshooting

**Task creation fails:** Verify admin privileges and time format (HH:MM 24-hour)
**Preferences not saving:** Check %APPDATA%\WindowsTelemetryBlocker\ directory exists
**Scheduler UI not opening:** Verify task-scheduler.ps1 and scheduler-ui.ps1 are accessible
**Tasks not running:** Check SYSTEM account has execution permissions and task is enabled

---

## See Also

- PHASE_2_2_AND_4_IMPLEMENTATION.md - Full technical documentation
- launcher-gui.ps1 - Main GUI integration
- config-manager.ps1 - Configuration system
- advanced-filtering.ps1 - Phase 3 filtering
