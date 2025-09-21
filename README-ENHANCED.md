# Windows Telemetry Blocker (Enhanced)

## Features
- Modular privacy and telemetry blocking for Windows
- Dry-run mode, advanced logging, and error reporting
- Dependency-aware module execution
- Rollback support for most modules
- System restore point creation
- Interactive and batch modes

## Usage
Run `run.bat` as administrator. Use PowerShell parameters for advanced options:

```
powershell -ExecutionPolicy Bypass -File windows-telemetry-blocker.ps1 -all -dryrun -verbose -rollbackOnFailure
```

## Modules
- **telemetry**: Disables Windows telemetry and related features
- **services**: Disables telemetry and bloatware services
- **apps**: Removes bloatware apps
- **misc**: Miscellaneous privacy tweaks

## Rollback
If a module fails and `-rollbackOnFailure` is set, rollback scripts in `modules/` will attempt to revert changes.

## Logging
- `telemetry-blocker.log`: Main log
- `telemetry-blocker-errors.log`: Errors
- `telemetry-blocker-stats.log`: Execution stats

## Customization
- Add or edit modules in `modules/`
- Add rollback logic in `modules/rollback/` as needed
- Common functions in `modules/common.ps1`

## Contributing
See `CONTRIBUTING.md` for guidelines.

---
**Test on a VM before use in production!**
