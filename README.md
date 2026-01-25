# Windows Telemetry Blocker

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PowerShell](https://img.shields.io/badge/PowerShell-%3E%3D5.1-blue)](https://github.com/PowerShell/PowerShell)
[![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-blue)](https://www.microsoft.com/windows)
[![Issues](https://img.shields.io/github/issues/N0tHorizon/WindowsTelemetryBlocker)](https://github.com/N0tHorizon/WindowsTelemetryBlocker/issues)
[![Pull Requests](https://img.shields.io/github/issues-pr/N0tHorizon/WindowsTelemetryBlocker)](https://github.com/N0tHorizon/WindowsTelemetryBlocker/pulls)

Windows Telemetry Blocker is a **PowerShell-based privacy hardening tool** for Windows 10 and Windows 11. It disables known telemetry mechanisms, feedback prompts, background services, and optional preinstalled apps in a **transparent and mostly reversible** manner.

---

> [!WARNING]
> This tool **modifies Windows system behavior**, including registry values, services, and installed applications.
> 
> * Administrator privileges are required
> * Some actions (notably app removal) are **not automatically reversible**
> * Testing in a **virtual machine** is strongly recommended before production use
> 
> Use at your own risk.

---

## Supported Platforms

| Component        | Supported                               |
| ---------------- | --------------------------------------- |
| Windows Versions | Windows 10 (2004+) / Windows 11         |
| Editions         | Home, Pro (Enterprise not fully tested) |
| PowerShell       | 5.1+ (PowerShell Core supported)        |

---

## Features

* Disable Windows telemetry and data collection
* Disable feedback prompts and advertising ID
* Disable telemetry-related Windows services
* Optional removal of preinstalled / background apps
* Modular execution with automatic dependency resolution
* Dry-run mode (preview changes)
* Detailed file-based logging
* Rollback scripts for most modules
* Automatic registry backups before modification

---

## Planned / Future Features

These are **not currently implemented** and are tracked as future work:

* GUI launcher
* Scheduled execution
* Auto-update mechanism
* Windows Event Viewer audit logging
* Integrity verification

---

## Quick Start

1. Download the latest version from `Releases` in github.
2. Right-click `run.bat` → **Run as administrator**
3. Choose an execution mode
4. Review logs after completion

All logs and reports are saved locally in the project directory.

---

## Modules Overview

| Module      | Description                                                   | Rollback   |
| ----------- | ------------------------------------------------------------- | ---------- |
| `telemetry` | Disables Windows telemetry, feedback, advertising ID, Cortana | ✅          |
| `services`  | Disables telemetry-related Windows services                   | ✅          |
| `apps`      | Removes optional preinstalled apps, disables background apps  | ❌ (manual) |
| `misc`      | Disables CEIP and Windows Error Reporting                     | ✅          |

Module dependencies are resolved automatically.

---

## Rollback & Safety

* Registry backups are created automatically before changes
* Rollback scripts are available in `modules/*-rollback.ps1`
* Services are restored to **Manual** startup where applicable
* App removals are **not reversible automatically** and must be reinstalled manually

### Rollback Usage

* Via launcher: Option "Rollback"

## Logging & Reports

### Log Files

* `telemetry-blocker.log` – full execution log
* `telemetry-blocker-errors.log` – errors only
* `telemetry-blocker-stats.log` – execution statistics
* `telemetry-blocker-report.md` – detailed Markdown summary

Audit-style logging currently writes to files only.

---

## What This Tool Does NOT Do

* It does not guarantee zero telemetry
* It does not bypass Windows licensing or DRM
* It does not modify Microsoft servers
* It does not attempt to hide activity from antivirus or EDR tools

---

## Customization & Extensibility

* Modules are located in `modules/`
* New modules can be added with optional rollback scripts
* Shared helper functions are in `modules/common.ps1`
* Profiles can be customized via `run.bat`

---

## Troubleshooting

* **Access denied**: Run as administrator
* **Module failure**: Check logs, then rollback
* **Pending reboot**: Reboot and rerun for best results
* **Dry run**: Use `-DryRun` to preview changes

---

## Contributing

Contributions are welcome. Please:

* Follow the pull request template
* Test changes on real or virtual machines
* Avoid irreversible or undocumented behavior

See `CONTRIBUTING.md` for details.

---

## License

MIT License. See `LICENSE` for details.

---

## Acknowledgments

* Inspired by ShutUp10++
* Thanks to the open-source community

---

**Always test in a VM before using on a primary system.**
