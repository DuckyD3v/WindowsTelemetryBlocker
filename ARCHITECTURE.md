# Windows Telemetry Blocker v1.0 - Architecture Overview

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│              Windows Telemetry Blocker v1.0 System                   │
└─────────────────────────────────────────────────────────────────────┘

                    ┌────────────────────────────┐
                    │    Entry Points             │
                    ├────────────────────────────┤
                    │  run.bat (Launcher)        │ ◄─── User executes
                    │  - Shows menu              │
                    │  - Routes to v1.0 or v0.9 │
                    └────────────────┬───────────┘
                                     │
                    ┌────────────────┴───────────┐
                    │                            │
       ┌────────────▼──────────┐    ┌──────────▼──────────┐
       │   v1.0 Path (New)     │    │  v0.9 Path (Legacy) │
       ├───────────────────────┤    ├────────────────────┤
       │ launcher.ps1 (CLI)    │    │ Windows...ps1      │
       │         OR            │    │ - Interactive      │
       │ launcher-gui.ps1 (GUI)│    │ - Modular          │
       └───────────┬───────────┘    │ - Proven           │
                   │                └────────────────────┘
                   │
       ┌───────────▼──────────────────────────┐
       │   Phase 1: Config & Integration       │
       ├────────────────────────────────────────┤
       │                                        │
       │  ┌──────────────────────────────┐     │
       │  │ config-manager.ps1           │     │
       │  ├──────────────────────────────┤     │
       │  │ • Load profiles.json          │     │
       │  │ • Save user settings          │     │
       │  │ • Manage configurations       │     │
       │  └──────────────────────────────┘     │
       │                                        │
       │  ┌──────────────────────────────┐     │
       │  │ profiles.json                │     │
       │  ├──────────────────────────────┤     │
       │  │ • Minimal profile             │     │
       │  │ • Balanced profile (default)  │     │
       │  │ • Maximum profile             │     │
       │  │ • 22 removable apps           │     │
       │  │ • 9 disableable services      │     │
       │  └──────────────────────────────┘     │
       │                                        │
       │  ┌──────────────────────────────┐     │
       │  │ integration.ps1               │     │
       │  ├──────────────────────────────┤     │
       │  │ • Load selected profile       │     │
       │  │ • Execute v0.9 modules        │     │
       │  │ • Create restore points       │     │
       │  │ • Backup registry             │     │
       │  │ • Track execution state       │     │
       │  └──────────────────────────────┘     │
       │                                        │
       │  ┌──────────────────────────────┐     │
       │  │ shared/utils.ps1              │     │
       │  ├──────────────────────────────┤     │
       │  │ • Logging (5 levels)          │     │
       │  │ • Notifications               │     │
       │  │ • System utilities            │     │
       │  │ • Registry operations         │     │
       │  │ • Service management          │     │
       │  │ • File backup/restore         │     │
       │  └──────────────────────────────┘     │
       │                                        │
       └────────────────┬─────────────────────┘
                        │
       ┌────────────────▼──────────────────────┐
       │  Phase 2: GUI Interface (Foundation)   │
       ├────────────────────────────────────────┤
       │                                        │
       │  ┌──────────────────────────────┐     │
       │  │ launcher-gui.ps1 (Phase 2.1) │     │
       │  ├──────────────────────────────┤     │
       │  │ Main Window                  │     │
       │  │ ├─ Profile selector          │     │
       │  │ ├─ App selection             │     │
       │  │ ├─ Service selection         │     │
       │  │ ├─ Execute button            │     │
       │  │ ├─ Progress bar              │     │
       │  │ ├─ Log viewer                │     │
       │  │ └─ Advanced options          │     │
       │  └──────────────────────────────┘     │
       │                                        │
       │  ┌──────────────────────────────┐     │
       │  │ theme-manager.ps1             │     │
       │  ├──────────────────────────────┤     │
       │  │ • Dark theme (default)        │     │
       │  │ • Light theme                 │     │
       │  │ • High contrast (accessibility)│    │
       │  │ • User theme persistence      │     │
       │  └──────────────────────────────┘     │
       │                                        │
       │  ┌──────────────────────────────┐     │
       │  │ form-controls.ps1             │     │
       │  ├──────────────────────────────┤     │
       │  │ • Styled buttons              │     │
       │  │ • Styled panels               │     │
       │  │ • Custom checkboxes           │     │
       │  │ • Log viewer control          │     │
       │  │ • Progress indicators         │     │
       │  └──────────────────────────────┘     │
       │                                        │
       │  ┌──────────────────────────────┐     │
       │  │ event-handlers.ps1 (Phase 2.3)│    │
       │  ├──────────────────────────────┤     │
       │  │ • Profile change events       │     │
       │  │ • Execute button click        │     │
       │  │ • Checkbox state changes      │     │
       │  │ • Log updates                 │     │
       │  └──────────────────────────────┘     │
       │                                        │
       └────────────────┬─────────────────────┘
                        │
       ┌────────────────▼──────────────────────┐
       │  Phase 3: Advanced Features            │
       ├────────────────────────────────────────┤
       │  • Custom profile builder              │
       │  • Selective app/service removal       │
       │  • Filter & search UI                  │
       │  • Profile import/export               │
       └────────────────┬─────────────────────┘
                        │
       ┌────────────────▼──────────────────────┐
       │  Phase 4: Scheduled Execution          │
       ├────────────────────────────────────────┤
       │  • Task Scheduler integration          │
       │  • Schedule creation UI                │
       │  • Quiet mode execution                │
       │  • Cron-like scheduling                │
       └────────────────┬─────────────────────┘
                        │
       ┌────────────────▼──────────────────────┐
       │  Phase 5: Monitoring & Alerts          │
       ├────────────────────────────────────────┤
       │  • Registry change detection           │
       │  • Service state monitoring            │
       │  • Anomaly detection                   │
       │  • Toast notifications                 │
       │  • Auto-remediation                    │
       └────────────────────────────────────────┘
```

---

## Data Flow

```
                    ┌──────────────────┐
                    │  User Action     │
                    │ (Launch GUI/CLI) │
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │  Load Profile    │
                    │ config-manager   │
                    └────────┬─────────┘
                             │
        ┌────────────────────┴────────────────────┐
        │                                         │
   ┌────▼─────┐                        ┌────────▼────┐
   │ profiles  │  ◄─ Load from         │ user-config │
   │ .json     │     %APPDATA%         │ .json       │
   └────┬─────┘                        └────────┬────┘
        │                                       │
        └───────────────┬───────────────────────┘
                        │
               ┌────────▼──────────┐
               │  Validate & Merge │
               │  Configurations   │
               └────────┬──────────┘
                        │
               ┌────────▼──────────┐
               │ Show Profile Info │
               │ in GUI/CLI        │
               └────────┬──────────┘
                        │
        ┌───────────────┴───────────────┐
        │                               │
   ┌────▼────────┐            ┌────────▼────┐
   │ User Select │            │ User Option │
   │ Apps/Services            │ (Dry Run)   │
   └────┬────────┘            └────────┬────┘
        │                              │
        └──────────────┬───────────────┘
                       │
           ┌───────────▼───────────┐
           │ Pre-Execution Checks  │
           │ • Admin privilege     │
           │ • System state        │
           │ • Validation          │
           └───────────┬───────────┘
                       │
           ┌───────────▼───────────┐
           │ Create Backup Points  │
           │ • Restore point       │
           │ • Registry backup     │
           │ • State snapshot      │
           └───────────┬───────────┘
                       │
           ┌───────────▼──────────────┐
           │ Execute (integration.ps1)│
           │ • Load selected profile  │
           │ • Call v0.9 modules      │
           │ • Track state            │
           └───────────┬──────────────┘
                       │
        ┌──────────────┴──────────────┐
        │                             │
   ┌────▼──────┐              ┌──────▼───┐
   │ Update    │              │ Save     │
   │ Log Viewer│              │ Execution│
   └────┬──────┘              │ State    │
        │                     └──────┬───┘
        │                            │
        └────────────┬───────────────┘
                     │
          ┌──────────▼──────────┐
          │ Display Final Status│
          │ • Success/Error     │
          │ • Statistics        │
          │ • Log summary       │
          └─────────────────────┘
```

---

## Component Dependencies

```
launcher.ps1 / launcher-gui.ps1
    │
    ├─► config-manager.ps1
    │   └─► profiles.json
    │
    ├─► integration.ps1
    │   ├─► shared/utils.ps1
    │   └─► modules/ (v0.9 scripts)
    │
    ├─► shared/utils.ps1
    │
    ├─► theme-manager.ps1 (GUI only)
    │
    └─► form-controls.ps1 (GUI only)
        └─► theme-manager.ps1


No Circular Dependencies ✓
All Dependencies Satisfied ✓
```

---

## Execution Flow Chart

```
┌─ Start
│
├─ Load Configuration
│  └─ Load profiles.json
│  └─ Load user settings from %APPDATA%
│
├─ Display UI (CLI or GUI)
│  └─ Show available profiles
│  └─ Show app/service options
│
├─ Get User Input
│  └─ Profile selection
│  └─ App/service checkboxes
│  └─ Execution mode (Normal/Dry-Run/Schedule)
│
├─ Validation
│  ├─ Check admin privileges
│  ├─ Validate profile
│  ├─ Check system state
│  └─ Get user confirmation
│
├─ Pre-Execution Preparation
│  ├─ Create system restore point
│  ├─ Backup registry keys
│  └─ Initialize logging
│
├─ Execute Modules
│  ├─ Load selected profile
│  ├─ For each v0.9 module:
│  │  ├─ Execute module
│  │  ├─ Capture output
│  │  ├─ Log results
│  │  └─ Handle errors
│  └─ Track execution state
│
├─ Post-Execution
│  ├─ Save execution state
│  ├─ Update log files
│  └─ Generate summary
│
├─ Display Results
│  ├─ Show completion status
│  ├─ List executed modules
│  ├─ Show any errors
│  └─ Display log summary
│
└─ Exit (with state for recovery)
```

---

## Safety & Security Architecture

```
┌─────────────────────────────────────────────┐
│       Safety & Security Layers              │
├─────────────────────────────────────────────┤
│                                             │
│  1. Pre-Execution Layer                     │
│     ├─ Admin privilege check                │
│     ├─ System validation                    │
│     └─ User confirmation                    │
│                                             │
│  2. Backup Layer                            │
│     ├─ Create restore point                 │
│     ├─ Backup registry                      │
│     ├─ Snapshot system state                │
│     └─ File backup with timestamps          │
│                                             │
│  3. Execution Layer                         │
│     ├─ Error isolation (try-catch)          │
│     ├─ State tracking                       │
│     ├─ Module isolation                     │
│     └─ Dry-run capability                   │
│                                             │
│  4. Logging Layer                           │
│     ├─ All operations logged                │
│     ├─ Error details captured               │
│     ├─ Execution timeline tracked           │
│     └─ Audit trail maintained               │
│                                             │
│  5. Recovery Layer                          │
│     ├─ Execution state saved                │
│     ├─ Rollback scripts available           │
│     ├─ System restore available             │
│     └─ File restore available               │
│                                             │
└─────────────────────────────────────────────┘
```

---

## Module Organization

```
v1.0/
├── launcher.ps1              (Entry point - CLI)
│   └─ Uses: config-manager, integration, utils
│
├── gui/
│   ├── launcher-gui.ps1      (Entry point - GUI) [Phase 2.1]
│   │   └─ Uses: config-manager, integration, utils, theme, controls
│   ├── theme-manager.ps1     (Theming system)
│   ├── form-controls.ps1     (Control library)
│   └── event-handlers.ps1    (Event system) [Phase 2.3]
│
├── config/
│   ├── config-manager.ps1    (Configuration I/O)
│   │   └─ Uses: profiles.json
│   └── profiles.json         (Data definitions)
│
├── shared/
│   ├── integration.ps1       (v0.9 bridge)
│   │   └─ Uses: utils, modules/
│   └── utils.ps1             (Utilities)
│
├── scheduler/                [Phase 4]
│   ├── task-scheduler.ps1
│   └── quiet-runner.ps1
│
└── monitor/                  [Phase 5]
    ├── telemetry-monitor.ps1
    └── alert-system.ps1
```

---

## Data Storage Locations

```
Installation:
  e:\Github\WindowsTelemetryBlocker\
  └─ v1.0/                    (New framework)
  └─ modules/                 (v0.9 scripts)

User Configuration:
  %APPDATA%\WindowsTelemetryBlocker\
  ├─ user-config.json         (User preferences)
  ├─ last-execution.json      (Execution state)
  ├─ backups/                 (Registry backups)
  └─ logs/                    (Execution logs)
    └─ wtb_YYYYMMDD.log

System Restore Points:
  (Created by Windows System Restore)
  └─ "WindowsTelemetryBlocker v1.0 - [profile]"
```

---

## Status Summary

| Layer | Status | Notes |
|-------|--------|-------|
| Phase 1: Config & Integration | ✅ Complete | Tested & ready |
| Phase 2: GUI Foundation | ⏳ 40% Ready | Theme & controls ready |
| Phase 2.1: Main Window | ⏳ Next | Ready to implement |
| Phase 3: Advanced Filtering | ⏳ Planned | After Phase 2 |
| Phase 4: Scheduling | ⏳ Planned | After Phase 3 |
| Phase 5: Monitoring | ⏳ Planned | After Phase 4 |

---

**This architecture ensures:**
- ✅ Modularity (each component independent)
- ✅ Safety (multiple backup layers)
- ✅ Scalability (easy to add features)
- ✅ Maintainability (clear separation of concerns)
- ✅ Reliability (comprehensive error handling)
- ✅ Usability (both CLI and GUI interfaces)
