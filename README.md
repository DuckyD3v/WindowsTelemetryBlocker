# Windows Telemetry Blocker

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PowerShell](https://img.shields.io/badge/PowerShell-%3E%3D5.1-blue)](https://github.com/PowerShell/PowerShell)
[![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-blue)](https://www.microsoft.com/windows)
[![Issues](https://img.shields.io/github/issues/N0tHorizon/WindowsTelemetryBlocker)](https://github.com/N0tHorizon/WindowsTelemetryBlocker/issues)
[![Pull Requests](https://img.shields.io/github/issues-pr/N0tHorizon/WindowsTelemetryBlocker)](https://github.com/N0tHorizon/WindowsTelemetryBlocker/pulls)
[![Last Commit](https://img.shields.io/github/last-commit/N0tHorizon/WindowsTelemetryBlocker)](https://github.com/N0tHorizon/WindowsTelemetryBlocker/commits/main)
[![Code Size](https://img.shields.io/github/languages/code-size/N0tHorizon/WindowsTelemetryBlocker)](https://github.com/N0tHorizon/WindowsTelemetryBlocker)

A comprehensive, open-source toolkit to disable Windows telemetry and enhance privacy on Windows 10 and 11. Built with PowerShell, fully transparent, modular, and scriptable. Includes GUI, scheduling, monitoring, and advanced filtering capabilities.

## Features

- **Disable Windows Telemetry** - Blocks data collection and reporting to Microsoft
- **Block Feedback & Advertising** - Prevents feedback prompts and advertising ID usage
- **Stop Unnecessary Services** - Disables telemetry-related services like DiagTrack, Xbox services, etc.
- **Remove Bloatware** - Optionally removes pre-installed apps and disables background apps
- **Interactive Module Selection** - Choose which modules to run via CLI or GUI-like menu
- **Modern GUI** - Windows Forms-based interface with tabbed navigation
- **Data Binding** - Real-time synchronization between UI and configuration
- **Task Scheduling** - Schedule automated telemetry blocking with 6 schedule types
- **Advanced Filtering** - Regex-based filtering system with custom rules
- **Real-time Monitoring** - Registry and service change detection with alerts
- **Dashboard** - Monitoring dashboard with statistics and notifications
- **Easy Rollback** - Revert changes with dedicated rollback scripts
- **Advanced Logging** - Comprehensive logs, error tracking, and statistics
- **Modular Design** - 4 core modules with clear dependencies
- **System Restore Points** - Automatic creation before changes for safety
- **Multiple Execution Modes** - Interactive, batch, dry-run, and custom profiles
- **Audit Logging** - Logs to Windows Event Viewer for compliance
- **Auto-Update** - Fetch latest versions from GitHub
- **Integrity Checks** - Verifies script and module integrity
- **Detailed Reports** - Markdown reports of changes and execution results

## Quick Start

1. **Download**: Clone or download the repository.
2. **Run as Administrator**: Right-click `run.bat` and select "Run as administrator".
3. **Choose Mode**:
   - **Option 1**: v1.0 GUI Launcher (if available) - Modern interface with monitoring and scheduling
   - **Option 2**: v0.9 Interactive Script - Classic interactive telemetry blocker with module selection
   - **Option 3**: Rollback - Undo recent changes
   - **Option 4**: System Restore - Use Windows System Restore point
4. **Review Logs**: Check `telemetry-blocker.log` and `telemetry-blocker-report.md` for results.

### Prerequisites
- Windows 10 version 2004 or later / Windows 11.
- PowerShell 5.1 or later (PowerShell Core recommended).
- Administrative privileges.

The launcher (`run.bat`) will automatically check for prerequisites and attempt self-healing if files are missing.

### PowerShell Script (windowstelementryblocker.ps1)

Run directly with parameters:

```powershell
.\windowstelementryblocker.ps1 -All -EnableAuditLog
```
## Usage

#### Module Dependencies

- `telemetry`: No dependencies
- `services`: Depends on `telemetry`
- `apps`: No dependencies
- `misc`: Depends on `telemetry` and `services`

Dependencies are resolved automatically.

## Modules

| Module | Description | Rollback Available |
|--------|-------------|-------------------|
| **telemetry.ps1** | Disables Windows Telemetry, feedback prompts, advertising ID, and Cortana via registry settings. | ✅ |
| **services.ps1** | Disables telemetry services: DiagTrack, dmwappushservice, WMPNetworkSvc, WerSvc, PcaSvc, Xbox services, MapsBroker, WSearch. | ✅ |
| **apps.ps1** | Disables background apps, removes bloatware (optional), disables Widgets/News/OneDrive auto-launch, removes pre-installed apps like Bing Weather, Xbox apps, etc. | ❌ (Manual) |
| **misc.ps1** | Disables Customer Experience Improvement Program (CEIP) and Windows Error Reporting. | ✅ |

### Module Details

#### Telemetry Module
- Sets `AllowTelemetry` to 0 and `DisableTelemetry` to 1 in `HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection`
- Disables feedback in `HKCU:\SOFTWARE\Microsoft\Siuf\Rules`
- Disables advertising ID in `HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo`
- Disables Cortana in `HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search`

#### Services Module
Disables and stops the following services:
- DiagTrack (Connected User Experiences and Telemetry)
- dmwappushservice (Device Management Wireless Application Protocol)
- WMPNetworkSvc (Windows Media Player Network Sharing)
- WerSvc (Windows Error Reporting)
- PcaSvc (Program Compatibility Assistant)
- Xbox-related services (XblGameSave, MapsBroker)
- WSearch (Windows Search)

#### Apps Module
- Disables background apps globally
- Removes apps like Microsoft.BingWeather, Microsoft.GetHelp, Microsoft.WindowsFeedbackHub, Xbox apps, etc.
- Disables taskbar icons for Widgets, News, OneDrive

#### Misc Module
- Disables CEIP in `HKLM:\SOFTWARE\Microsoft\SQMClient\Windows`
- Disables Windows Error Reporting in `HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting`

## Rollback

Rollback scripts are available for most modules in `modules/*-rollback.ps1`.

### Using Rollback
- Via Launcher: Option 3 "Rollback (Undo recent changes)"
- Via Script: `.\windowstelementryblocker.ps1 -Rollback`
- Individual: Run specific rollback script, e.g., `.\modules\telemetry-rollback.ps1`

### Rollback Coverage
- **Telemetry**: Removes AllowTelemetry registry value.
- **Services**: Sets disabled services back to Manual startup.
- **Apps**: No automatic rollback (app removals are irreversible; reinstall manually).
- **Misc**: Removes Timeline-related registry values.

Registry backups are created in `registry-backups/` before changes.

## Logging and Reports

### Log Files
- `telemetry-blocker.log`: Main execution log with timestamps.
- `telemetry-blocker-errors.log`: Error messages only.
- `telemetry-blocker-stats.log`: Execution statistics (start/end times, durations).
- `telemetry-blocker-report.md`: Detailed Markdown report of changes.

### Audit Logging
With `-EnableAuditLog`, events are logged to Windows Event Viewer under "Application" source "TelemetryBlocker".

### Reports
Post-execution, a Markdown report is generated with:
- Execution details (date, version, Windows info)
- Modules run with status and timestamps
- Summary of changes
- Errors (if any)

## Customization

### Adding Modules
1. Create `modules/yourmodule.ps1` with functions and return `$true` on success.
2. Optionally create `modules/yourmodule-rollback.ps1` for rollback logic.
3. Update dependencies in the main script if needed.
4. Use `Write-ModuleLog` for logging (from common.ps1).

### Common Functions
Located in `modules/common.ps1`:
- `Write-ModuleLog`: Logs messages with fallback.
- `Set-RegistryValue`: Safely sets registry values with type support.

### Profiles
Customize profiles in `run.bat` by editing the module lists.

## Troubleshooting

### Common Issues
- **"Access Denied"**: Run as administrator.
- **"Script not found"**: Use self-healing mode in launcher.
- **Modules fail**: Check logs for specific errors; try rollback.
- **No PowerShell**: Install PowerShell or use Windows PowerShell.

### Pending Reboot
If a reboot is pending, the script warns but continues. Reboot before running for best results.

### Dry Run
Use `-DryRun` to preview changes without applying them.

### Update Issues
If update fails, download manually from GitHub.

## Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

- Fork the repo
- Make changes
- Test thoroughly
- Submit a pull request

### Developer Resources

- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Contribution guidelines
- **[MODULE_TEMPLATE.md](MODULE_TEMPLATE.md)** - Template for creating new modules
- **[DEVELOPMENT.md](DEVELOPMENT.md)** - Development workflow guide
- **[SCALABILITY.md](SCALABILITY.md)** - Architecture and scalability guide
- **[PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)** - Project structure documentation
- **[VERSIONING.md](VERSIONING.md)** - Version management guide
- **[QUICK_START.md](QUICK_START.md)** - Quick reference guide

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Inspired by [ShutUp10++](https://www.oo-software.com/en/shutup10)
- Thanks to the open-source community and contributors

---

**Test on a VM before use in production!**
