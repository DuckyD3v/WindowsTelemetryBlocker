# Changelog

All notable changes to Windows Telemetry Blocker are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0] - 2026-01-25

### Added
- **Code Organization**: All scripts organized into clear regions
  - Main script organized into 13 logical regions
  - Module scripts organized with consistent structure
  - Rollback scripts organized with clear sections
  - Improved code readability and maintainability

- **v1.0 Integration**: Full integration with v0.9 core
  - v1.0 launcher properly calls v0.9 script
  - GUI, scheduler, and monitor features use v0.9 functionality
  - Seamless integration between v0.9 and v1.0 features

- **Enhanced Workflows**: Comprehensive CI/CD pipeline
  - Security scanning workflow
  - Contributor validation workflow
  - Enhanced compliance checks
  - Code organization validation
  - Secret scanning and code injection detection

- **Documentation**: Comprehensive developer documentation
  - CONTRIBUTING.md - Complete contribution guidelines
  - MODULE_TEMPLATE.md - Module creation template
  - SCALABILITY.md - Scalability guide
  - PROJECT_STRUCTURE.md - Project structure documentation
  - DEVELOPMENT.md - Development workflow guide

- **Security Enhancements**: Enhanced security for contributions
  - Secret scanning in workflows
  - Code injection detection
  - Unsafe operation detection
  - Contributor validation
  - Automated security audits

### Changed
- **Script Organization**: All scripts reorganized with regions
  - Main script: 13 organized regions
  - Modules: Consistent region structure
  - Improved code navigation
  - Better maintainability

- **Error Handling**: Improved error handling
  - Trap handler distinguishes initialization vs interruption errors
  - Better error messages with stack traces
  - Graceful handling of missing functions

- **Parameter Handling**: Fixed parameter block positioning
  - Parameters moved to top of script (PowerShell requirement)
  - Proper initialization order
  - Fixed PSScriptRoot detection

- **v1.0 Launcher**: Fixed execution flow
  - Actually calls Execute-Profile function
  - Proper error handling and reporting
  - Better integration with v0.9 script

### Fixed
- **Immediate Interruption**: Fixed script being interrupted immediately
  - Proper initialization order
  - Write-Log available before use
  - Trap handler only catches actual interruptions

- **OnRemove Error**: Fixed OnRemove property error
  - Conditional check for module vs script execution
  - Graceful fallback when not available

- **Parameter Recognition**: Fixed "param not recognized" error
  - Moved param() block to top of script
  - Proper PowerShell syntax compliance

- **DryRun Variable**: Fixed dryrun variable mismatch
  - Consistent variable naming
  - Proper initialization before module execution

- **Registry Backup**: Improved registry backup function
  - Better error handling
  - File verification
  - Size reporting

### Security
- **Workflow Security**: Enhanced security checks
  - Secret scanning for hardcoded credentials
  - Code injection pattern detection
  - Unsafe file operation detection
  - Network call validation
  - Contributor validation

### Documentation
- **Developer Resources**: Comprehensive documentation
  - Module creation templates
  - Scalability guidelines
  - Development workflow
  - Project structure guide
  - Contribution guidelines

---

## [0.9] - 2026-01-24

### Added
- **Phase 5: Monitoring System** - Comprehensive real-time monitoring
  - Registry change detection with baseline snapshots
  - Service state monitoring with anomaly detection
  - Suspicious pattern analysis for malware detection
  - Monitoring dashboard with alerts and statistics
  - Alert system with severity levels and notifications
  - Change history persistence (1000-entry limit)
  - Alert history tracking (500-entry limit)

- **Phase 2.5: Testing & Refinement** - Complete testing suite
  - Testing framework with 9 comprehensive tests
  - Unit tests: Profile loading, preferences, event handlers, task validation
  - Integration tests: Data binding, scheduler workflow
  - Performance tests: Preferences loading, statistics calculation
  - UI refinement module for DPI scaling and accessibility
  - Bug fixes module with input validation and error recovery
  - End-to-end workflow testing (8 tests)

- **GUI Enhancements**
  - DPI scaling support for high-resolution displays
  - Accessibility features validation
  - Theme consistency testing
  - Color contrast validation (WCAG AA standards)
  - Memory profiling and optimization

- **Error Handling & Recovery**
  - Comprehensive input validation
  - User-friendly exception handling
  - Automatic recovery mechanisms
  - Configuration integrity repair
  - Resource cleanup utilities

### Changed
- Version updated to 1.0 (production release)
- All phases complete and integrated
- Monitoring system fully operational
- Testing framework comprehensive

### Technical
- 10,000+ lines of production-ready code
- 22 PowerShell modules
- 200+ exported functions
- 8 custom classes
- 20+ comprehensive tests
- All performance benchmarks met

---

## [0.9] - 2026-01-24

### Added
- **Safety Barriers System**: Comprehensive interrupt handling and recovery
  - Global state tracking for critical operations
  - Interrupt handler (trap) for Ctrl+C graceful shutdown
  - Cleanup task queue system with LIFO execution order
  - Emergency rollback procedures
  - Partial execution detection on launcher restart
  - State recovery and user guidance

- **Enhanced Run.bat Launcher** (v1.0)
  - Execution state file tracking across sessions
  - Incomplete execution detection on startup
  - Recovery options (rollback, continue, exit)
  - Separate safety event logging
  - Confirmation prompts for destructive operations
  - Double confirmation for critical operations
  - Error code tracking and persistence

- **Execution State Management**
  - Global operation tracking in PowerShell
  - Partial execution state storage
  - Removed apps tracking
  - Duration and error recording
  - Automatic cleanup task queuing

- **Enhanced Logging**
  - Separate safety event log (telemetry-blocker-safety.log)
  - Execution state persistence
  - Timestamp tracking for all operations
  - Error code logging
  - Session start/end markers

- **Apps Module Safety**
  - Removed apps tracking in global state
  - Interruption detection during removal
  - Removal count in completion messages
  - User guidance for manual reinstallation

- **System Restore Point Safety**
  - Wrapped in critical operation handler
  - Automatic cleanup task registration
  - Graceful failure handling
  - User notification of restore point availability

- **Documentation**
  - SAFETY_BARRIERS.md - Complete safety system documentation
  - Recovery procedures for all scenarios
  - Emergency manual recovery procedures
  - Testing recommendations
  - Configuration guide

### Fixed
- **Issue #18**: Fixed "param not recognized" error in apps.ps1
  - Moved param() block to correct position (after comments, before dot-source)
  - Verified other modules have correct param() placement

- **PowerShell Path Handling**
  - Added quotes around %PS_EXE% in all invocations
  - Handles paths with spaces (e.g., C:\Program Files)
  - Tested with custom PowerShell installations

- **Admin Elevation**
  - Proper elevation flow before operations
  - Clear UAC prompt messaging
  - Elevation state verification

### Changed
- Version strings updated to 0.9 (production ready)
- Removed "pending release" notes
- Updated launcher to v1.0 (matches 0.9 release)
- Menu descriptions enhanced with safety information
- Error messages include recovery guidance
- Log messages include operation context

### Security
- Safety barriers protect against interruption during operations
- State recovery prevents partial modification corruption
- Emergency cleanup ensures system consistency
- Registry backups available for all changes
- System restore points created before modifications

### Documentation Updates
- RELEASE_NOTES.md - Comprehensive v0.9 release documentation
- SAFETY_BARRIERS.md - Complete implementation guide
- README.md - Enhanced with feature descriptions
- CHANGELOG.md - This file (new)

---

## [0.8] - Pre-Release (Development)

### Features
- Core telemetry blocking functionality
- Service disabling and management
- App removal capabilities
- Rollback system for most modules
- Logging and reporting
- DryRun/WhatIf testing mode
- Module selection system
- Registry backup
- Auto-update capability

### Notes
- Pre-release version used for development and testing
- Not recommended for production use
- All features present but safety barriers incomplete
- Documentation partial

---

## Legend

- **Added**: New features
- **Changed**: Changes in existing functionality
- **Deprecated**: Soon-to-be removed features
- **Removed**: Removed features
- **Fixed**: Bug fixes
- **Security**: Security-related changes
- **Documentation**: Documentation improvements

---

## Versioning Scheme

This project follows Semantic Versioning (MAJOR.MINOR.PATCH):
- **MAJOR** (0): Significant releases, major feature additions
- **MINOR** (9): Feature completeness, safety additions
- **PATCH** (0): Bug fixes, minor improvements

---

## How to Report Issues

Found a bug or have a suggestion? Please report it:
1. Check existing [Issues](https://github.com/N0tHorizon/WindowsTelemetryBlocker/issues)
2. Create a new issue with detailed description
3. Include logs from execution
4. Specify Windows version and PowerShell version
5. Mention steps to reproduce

---

## Development

For development roadmap and planned features, see [RELEASE_NOTES.md](RELEASE_NOTES.md) future roadmap section.

---

**Last Updated**: 2026-01-24  
**Current Version**: 0.9
