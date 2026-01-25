# Quick Reference - Phase 2.1 & 3 Development

## 🚀 Start Phase 2.1 Now

### File to Create:
```
v1.0/gui/launcher-gui.ps1
```

### What It Should Do:
1. Load theme system
2. Create main form (900x700px)
3. Create 6 layout panels
4. Add 20+ styled controls
5. Apply themes
6. Wire basic events
7. Display form

### Basic Structure Template:
```powershell
# ===============================
# GUI Launcher - Phase 2.1
# ===============================

param(
    [string]$Profile = "balanced",
    [switch]$Quiet = $false
)

# Get script paths
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$themeManager = Join-Path $scriptRoot "theme-manager.ps1"
$formControls = Join-Path $scriptRoot "form-controls.ps1"
$utils = Join-Path (Split-Path -Parent $scriptRoot) "shared" "utils.ps1"

# Load dependencies
. $utils
. $themeManager
. $formControls

# Create main window
$form = New-Object System.Windows.Forms.Form
$form.Text = "Windows Telemetry Blocker v1.0"
$form.Width = 900
$form.Height = 700
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$form.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Font

# Get and apply theme
$theme = Get-ApplicationTheme -ThemeName (Get-UserTheme)
$form.BackColor = $theme.BackgroundColor
$form.ForeColor = $theme.ForegroundColor

# Create panels and controls here...

# Show form
[void]$form.ShowDialog()
```

---

## 📂 Essential Components Ready to Use

### From v1.0/gui/theme-manager.ps1:
```powershell
Get-ApplicationTheme -ThemeName "dark"      # Load theme
Get-UserTheme                               # Load user preference
Apply-Theme -Form $form -Theme $theme      # Apply theme to form
Save-UserTheme -ThemeName "light"          # Save user theme choice
```

### From v1.0/gui/form-controls.ps1:
```powershell
New-StyledButton -Text "Execute" -Theme $theme
New-StyledLabel -Text "Profile:" -Theme $theme
New-StyledComboBox -Items @("minimal", "balanced", "maximum")
New-StyledCheckBox -Text "Dry Run" -Theme $theme
New-StyledPanel -Width 400 -Height 300 -Theme $theme
New-StyledProgressBar -Width 500 -Height 25 -Theme $theme
New-StyledTextBox -Multiline -ReadOnly -Theme $theme
```

### From v1.0/shared/utils.ps1:
```powershell
Initialize-Logging                          # Setup logging
Write-LogEntry "INFO" "Message"             # Log something
Show-Notification -Title "Title" -Message "Text"
Test-AdminPrivilege                         # Check admin
Get-SystemInfo                              # System details
```

### From v1.0/config/config-manager.ps1:
```powershell
& ".\config\config-manager.ps1" -Action load -ProfileName balanced
& ".\config\config-manager.ps1" -Action list
```

---

## 🎨 Form Layout Reference

```
┌─────────────────────────────────────────────────┐
│  Profile: [▼ Balanced ▼] [Details] [Help]      │ (Top Panel)
├─────────────────────────────────────────────────┤
│ ☐ Apps to Remove    ☐ Services to Disable     │ (Selection Panels)
│ ├─ Cortana           ├─ DiagTrack              │
│ ├─ Widgets           └─ [8 more]               │
│ └─ [more]                                      │
├─────────────────────────────────────────────────┤
│ ☐ Dry Run    ☐ Quiet Mode                     │ (Options)
│ [Execute] [Cancel] [≡ Advanced]               │ (Controls)
├─────────────────────────────────────────────────┤
│ [========] 35% - Running: Remove Cortana       │ (Progress)
├─────────────────────────────────────────────────┤
│ [INFO] Starting execution...                   │ (Log Viewer)
│ [OK] Restore point created                     │
│ [WARN] Already disabled                        │
│ ___________________________________________    │
│ [Show All] [Info] [Warn] [Error] [⬆ Collapse] │
└─────────────────────────────────────────────────┘
```

---

## ✅ Quick Checklist

### Before Starting Code:
- [ ] Read DEVELOPMENT.md
- [ ] Review ARCHITECTURE.md
- [ ] Check existing components compile
  ```powershell
  . ".\v1.0\shared\utils.ps1"
  . ".\v1.0\gui\theme-manager.ps1"
  . ".\v1.0\gui\form-controls.ps1"
  ```

### While Coding launcher-gui.ps1:
- [ ] Import dependencies at top
- [ ] Create form object
- [ ] Set form properties
- [ ] Create layout panels
- [ ] Add controls to panels
- [ ] Apply theme
- [ ] Wire basic events
- [ ] Test with ShowDialog()

### After Creating:
- [ ] ✅ Test: `.\v1.0\gui\launcher-gui.ps1`
- [ ] Verify: Form displays
- [ ] Verify: All controls visible
- [ ] Verify: Theme applied
- [ ] Verify: No errors

---

## 🔧 Development Commands

### Test Phase 1 Components:
```powershell
# Test CLI launcher
.\v1.0\launcher.ps1 -Profile minimal -DryRun

# Test config manager
& ".\v1.0\config\config-manager.ps1" -Action list

# Test utils
. ".\v1.0\shared\utils.ps1"
Write-LogEntry "TEST" "This works"
```

### Test Phase 2 Foundation:
```powershell
# Test theme loading
. ".\v1.0\gui\theme-manager.ps1"
$theme = Get-ApplicationTheme -ThemeName "dark"
Write-Host "Theme loaded: $($theme.Name)"

# Test controls
. ".\v1.0\gui\form-controls.ps1"
$btn = New-StyledButton -Text "Test" -Theme $theme
Write-Host "Button created: $($btn.Text)"
```

### Debug GUI:
```powershell
# In PowerShell while GUI is running:
$Error  # Check for errors
Get-ChildItem Variable: | Where-Object Name -like "*form*"  # Find form object
```

---

## 📊 Phase Timeline

| Phase | Status | Next Task |
|-------|--------|-----------|
| Phase 1 | ✅ Complete | Already done |
| Phase 2.1 | ⏳ Next | Create launcher-gui.ps1 |
| Phase 2.2 | ⏳ Pending | Data integration |
| Phase 2.3 | ⏳ Pending | Event handlers |
| Phase 2.4 | ⏳ Pending | Advanced options |
| Phase 2.5 | ⏳ Pending | Polish |
| Phase 3 | ⏳ Future | Advanced filtering |

---

## 🎯 Phase 2.1 Success = 

Runnable GUI window with:
- ✅ Form displays
- ✅ All controls visible
- ✅ Theme applied
- ✅ Basic events work
- ✅ No compile errors

---

## 💾 Key File Locations

```
v1.0/
├── gui/
│   ├── launcher-gui.ps1          [CREATE THIS - Phase 2.1]
│   ├── theme-manager.ps1         [USE THIS - Already ready]
│   └── form-controls.ps1         [USE THIS - Already ready]
├── shared/
│   ├── utils.ps1                 [USE THIS - Ready]
│   └── integration.ps1           [USE THIS - Ready]
├── config/
│   ├── config-manager.ps1        [USE THIS - Ready]
│   └── profiles.json             [DATA - Ready]
└── launcher.ps1                  [Phase 1 CLI - Already done]
```

---

## 🚀 You're Ready!

**Workspace:** ✅ Clean  
**Dependencies:** ✅ Ready  
**Framework:** ✅ Complete (Phase 1 + Foundation)  
**Next Action:** Create launcher-gui.ps1

Start Phase 2.1 whenever you're ready!

---

**Last Updated:** January 24, 2026  
**Prepared For:** Phase 2.1 & Phase 3 Development
