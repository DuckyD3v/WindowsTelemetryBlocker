# Phase 2 - GUI Implementation Plan
## Windows Telemetry Blocker v1.0

### Overview
Phase 2 focuses on creating a professional Windows Forms GUI that integrates with Phase 1's configuration system. The GUI will provide an intuitive interface for profile selection, execution control, and monitoring.

---

## 📋 Phase 2 Components

### 1. GUI Main Window (launcher-gui.ps1)
**Location:** `v1.0/gui/launcher-gui.ps1`  
**Purpose:** Primary GUI window with full feature integration

#### Features:
- **Profile Selection**
  - Dropdown menu (Minimal, Balanced, Maximum, Custom)
  - Profile description panel
  - Details button for more info
  
- **Module/App Selection**
  - Checkboxes for apps to remove
  - Checkboxes for services to disable
  - Category filters/search
  - Quick select buttons (All/None)
  
- **Execution Controls**
  - Execute button with loading spinner
  - Dry-Run checkbox
  - Quiet Mode checkbox
  - Schedule button
  
- **Progress Indication**
  - Progress bar with percentage
  - Current operation display
  - Cancel button
  
- **Log Viewer**
  - Real-time log tail display
  - Log level filters (Info, Warn, Error, Success)
  - Expandable log panel
  
- **Advanced Options**
  - Toggle monitoring enable/disable
  - Auto-remediation checkbox
  - Auto-schedule option
  - Enable audit log checkbox
  - Backup location selector

- **Status Panel**
  - Last execution timestamp
  - Current system state
  - Health indicators

### 2. Theme System (theme-manager.ps1)
**Location:** `v1.0/gui/theme-manager.ps1`  
**Purpose:** Handle GUI theming (dark/light mode)

#### Features:
- Dark theme (default)
- Light theme
- High contrast mode
- Custom color palettes
- Theme persistence
- Font scaling

### 3. Form Controls Library (form-controls.ps1)
**Location:** `v1.0/gui/form-controls.ps1`  
**Purpose:** Reusable Windows Forms controls

#### Controls:
- ModuleCheckbox - With tooltip and description
- AppSelector - Grouped app selection
- ServiceSelector - Grouped service selection
- ExecutionProgress - Custom progress bar
- LogViewer - Real-time log display
- ControlButton - Styled buttons
- StatusIndicator - Status display component

### 4. Event Handler System (event-handlers.ps1)
**Location:** `v1.0/gui/event-handlers.ps1`  
**Purpose:** Handle all GUI events and interactions

#### Handlers:
- OnProfileChanged - Update UI when profile changes
- OnExecuteClicked - Start execution with validation
- OnCancelClicked - Cancel running execution
- OnLogLevelChanged - Filter log display
- OnAdvancedToggled - Show/hide advanced options
- OnScheduleClicked - Open scheduler dialog
- OnThemeChanged - Apply theme changes

---

## 🎨 GUI Layout

```
┌──────────────────────────────────────────────────┐
│  Windows Telemetry Blocker v1.0 - Phase 1       │  Title Bar
├──────────────────────────────────────────────────┤
│                                                  │
│  Profile: [▼ Balanced ▼]  [Details]  [Help]    │  Profile Selector
│                                                  │
│  Description: Removes telemetry apps and        │  Profile Info
│  disables telemetry services for balanced       │
│  privacy/stability.                              │
│                                                  │
├──────────────────────────────────────────────────┤
│                                                  │
│  ☐ Apps to Remove        ☐ Services to Disable │  Module Selectors
│  ├─ Cortana              ├─ DiagTrack          │  (Expandable)
│  ├─ Widgets              ├─ dmwappushservice   │
│  ├─ Mail & Calendar      └─ [5 more]           │
│  └─ [4 more]                                    │
│                                                  │
├──────────────────────────────────────────────────┤
│  ☐ Dry Run    ☐ Quiet Mode                     │  Options
│                                                  │
│  [Execute] [Cancel] [≡ Advanced Options]       │  Controls
│                                                  │
├──────────────────────────────────────────────────┤
│  [======] 35% - Running: Remove Cortana        │  Progress
│                                                  │
├──────────────────────────────────────────────────┤
│  [INFO] Starting execution...                   │  Log Viewer
│  [OK] Restore point created                     │  (Real-time)
│  [WARN] Service DiagTrack already disabled      │
│  [DEBUG] Processing module: apps                │
│  ___________________________________________    │
│  [⬆ Collapse]  [All] [Info] [Warn] [Error] [▼] │
│                                                  │
├──────────────────────────────────────────────────┤
│  Last Execution: 2024-01-23 14:30               │  Status
│  System State: ✓ Clean (no telemetry detected)  │
└──────────────────────────────────────────────────┘
```

---

## 🔄 Interaction Flow

### Scenario 1: Execute Balanced Profile
1. User launches GUI → Default profile (Balanced) shown
2. Description panel displays profile details
3. Apps/services lists populated from profiles.json
4. User clicks Execute
5. Pre-execution validation runs
6. System restore point created
7. Progress bar appears with real-time status
8. Log viewer streams execution logs
9. On completion, status panel updates
10. User can view detailed log or close

### Scenario 2: Custom Profile Creation
1. User selects "Custom" from dropdown
2. All apps/services shown with checkboxes
3. User checks desired items to remove
4. Advanced options panel expands
5. User sets schedule, monitoring, etc.
6. User clicks Execute
7. Config manager saves custom profile
8. Execution proceeds

### Scenario 3: Dry Run
1. User checks "Dry Run" checkbox
2. Clicks Execute
3. No actual changes made
4. Log shows what would happen
5. User can review and then run for real

---

## 🛠 Technical Implementation Details

### Windows Forms Configuration
```powershell
# Core form setup
- Form size: 1000x800 (resizable, min 800x600)
- Form position: Center on screen
- Icon: Embedded telemetry blocker icon
- Font: Segoe UI, 10pt
- Owner: None (independent window)
- TopMost: False (but always-on-top option available)
```

### Color Scheme (Dark Theme - Default)
```
Background: #1e1e1e
Foreground: #ffffff
Accent: #0078d4 (Windows blue)
Success: #107c10 (Green)
Warning: #ffb900 (Yellow)
Error: #d13438 (Red)
Info: #0078d4 (Blue)
```

### Threading Model
```
Main Thread:
  - GUI updates
  - User interactions
  - Event handling

Background Thread:
  - Profile loading
  - Execution via integration.ps1
  - Log streaming
  - File operations
```

### Log Streaming
```powershell
# Real-time log monitoring
- Tail %APPDATA%\WindowsTelemetryBlocker\logs\wtb_*.log
- Display last 50 lines
- Scroll to bottom on new entries
- Color-code by level
- Update every 500ms
```

---

## 📦 Integration Points

### With Phase 1 Components:
1. **launcher.ps1** - Call via integration for execution
2. **config-manager.ps1** - Load/save profiles and configs
3. **integration.ps1** - Execute profiles in background
4. **utils.ps1** - Use logging, notifications, system info

### With v0.9 Scripts:
1. Discovered automatically via modules/ directory
2. Executed by integration.ps1
3. Errors captured and displayed in GUI

---

## 🎯 Success Criteria

✅ **Functional Requirements:**
- Profile selection and execution
- Real-time progress display
- Log viewing capability
- Advanced options access
- Schedule integration

✅ **Performance Requirements:**
- GUI responsive during execution
- No freezing or hanging
- Progress updates < 1 second latency
- Memory usage < 150MB

✅ **UX Requirements:**
- Intuitive profile selection
- Clear status indicators
- Helpful descriptions
- Undo/rollback easy to find
- Mobile-friendly icon sizes

✅ **Reliability Requirements:**
- Graceful error handling
- Log all operations
- Recover from crashes
- Persist user preferences
- Validate all inputs

---

## 📅 Implementation Schedule

### Phase 2 Sub-phases:

**Phase 2.1** - Core Form & Layout (estimated 2-3 hours)
- Create main window
- Add layout panels
- Implement basic controls
- Set up theming

**Phase 2.2** - Data Integration (estimated 2 hours)
- Load profiles from profiles.json
- Load user config
- Populate lists/checkboxes
- Implement profile switching

**Phase 2.3** - Execution & Monitoring (estimated 3-4 hours)
- Wire up Execute button
- Create background thread for execution
- Implement progress tracking
- Add log streaming

**Phase 2.4** - Advanced Features (estimated 2-3 hours)
- Theme switching
- Log filtering
- Advanced options
- Schedule integration

**Phase 2.5** - Polish & Testing (estimated 2 hours)
- UI refinement
- Error handling
- Documentation
- Testing

---

## 🚀 Next Steps

### Immediate (Phase 2.1):
1. Create launcher-gui.ps1
2. Define form layout
3. Add basic controls
4. Implement theme system

### Short-term (Phase 2.2-2.3):
5. Integrate config-manager
6. Wire execution logic
7. Add progress tracking
8. Implement log viewer

### Medium-term (Phase 2.4-2.5):
9. Add advanced options
10. Theme switching
11. Polish UI
12. Comprehensive testing

---

## 📝 Testing Checklist

- [ ] Form displays correctly on 100%, 125%, 150% DPI
- [ ] Profile dropdown changes contents appropriately
- [ ] Checkboxes can be checked/unchecked
- [ ] Execute button triggers execution
- [ ] Progress bar updates during execution
- [ ] Log viewer streams in real-time
- [ ] Cancel button stops execution
- [ ] Advanced options expand/collapse
- [ ] Theme switching works
- [ ] Window state persists between sessions
- [ ] Error messages display clearly
- [ ] Responsive to window resizing
- [ ] All buttons and controls are keyboard accessible

---

## 💡 Notes

- GUI is supplementary to CLI launcher, not replacement
- All safety features from Phase 1 preserved
- No breaking changes to v0.9
- Full rollback capability maintained
- Can run alongside v0.9 scripts without conflict

**Status:** Plan Complete - Ready for Phase 2.1 Implementation
