# Contributing to Windows Telemetry Blocker

Thank you for your interest in contributing! This document provides guidelines for making edits, submitting pull requests, and scaling the project.

## Table of Contents

- [Getting Started](#getting-started)
- [Making Edits](#making-edits)
- [Code Organization](#code-organization)
- [Adding New Modules](#adding-new-modules)
- [Testing Guidelines](#testing-guidelines)
- [Submitting Pull Requests](#submitting-pull-requests)
- [Scaling the Project](#scaling-the-project)

## Getting Started

1. **Fork the Repository**: Start by forking the repository to your GitHub account.
2. **Clone Your Fork**: Clone your fork locally to make changes.
   ```bash
   git clone https://github.com/YourUsername/WindowsTelemetryBlocker.git
   cd WindowsTelemetryBlocker
   ```
3. **Create a Branch**: Create a new branch for your changes.
   ```bash
   git checkout -b feature/your-feature-name
   ```

## Making Edits

### Code Style Guidelines

- **Use Regions**: Organize code into clear regions using `#region` and `#endregion`
- **Consistent Naming**: Use PascalCase for functions, camelCase for variables
- **Comments**: Add clear comments explaining complex logic
- **Error Handling**: Always use try-catch blocks for operations that can fail
- **Logging**: Use `Write-Log` or `Write-ModuleLog` for all operations

### File Organization

- **Main Script**: `windowstelementryblocker.ps1` - Core execution logic
- **Modules**: `modules/*.ps1` - Individual functionality modules
- **Rollback Scripts**: `modules/*-rollback.ps1` - Rollback functionality
- **v1.0 Features**: `v1.0/` - GUI, scheduler, monitor features

## Code Organization

### Script Structure Template

```powershell
# ============================================================================
# Module Name
# ============================================================================
# Description: Brief description of what this module does
# Dependencies: List dependencies (e.g., telemetry)
# Rollback: Available/Manual/Not Available
# ============================================================================

param()
. "$PSScriptRoot/common.ps1"

#region Configuration
# Configuration variables and arrays
#endregion

#region Functions
# Function definitions
#endregion

#region Module Execution
# Main execution logic
#endregion
```

### Required Sections

All scripts should have:
1. **Header**: Description, dependencies, rollback info
2. **Parameters**: If needed
3. **Common Import**: Dot-source common.ps1
4. **Regions**: Organized into clear sections
5. **Error Handling**: Try-catch blocks
6. **Logging**: Write-ModuleLog calls

## Adding New Modules

### Step 1: Create Module File

Create `modules/yourmodule.ps1` following the template above.

### Step 2: Implement Functions

```powershell
function Disable-Feature {
    Write-ModuleLog "Disabling feature..."
    try {
        # Your code here
        Write-ModuleLog "Feature disabled."
        return $true
    } catch {
        Write-ModuleLog "Error disabling feature: $_" 'ERROR'
        return $false
    }
}
```

### Step 3: Add to Main Script

Update `windowstelementryblocker.ps1`:

1. Add to `$moduleList`:
   ```powershell
   $moduleList = @('telemetry','services','apps','misc','yourmodule')
   ```

2. Add dependencies:
   ```powershell
   $moduleDependencies = @{
       'yourmodule' = @('telemetry')  # If it depends on telemetry
   }
   ```

### Step 4: Create Rollback Script (Optional)

Create `modules/yourmodule-rollback.ps1`:

```powershell
# ============================================================================
# YourModule Rollback
# ============================================================================
# Description: Restores settings changed by yourmodule.ps1
# ============================================================================

#region Rollback Execution
# Rollback logic here
#endregion
```

### Step 5: Update Documentation

- Update `README.md` with module information
- Add to module table
- Document dependencies

## Testing Guidelines

### Before Submitting

1. **Syntax Check**: Run PowerShell syntax validation
   ```powershell
   $errors = $null
   [System.Management.Automation.PSParser]::Tokenize((Get-Content yourfile.ps1 -Raw), [ref]$errors)
   ```

2. **Dry-Run Test**: Test with `-DryRun` parameter
   ```powershell
   .\windowstelementryblocker.ps1 -Modules yourmodule -DryRun
   ```

3. **VM Test**: Always test on a VM before production use

4. **Rollback Test**: Verify rollback works correctly

### Test Checklist

- [ ] Script runs without errors
- [ ] Dry-run mode works
- [ ] Actual execution works
- [ ] Rollback works (if applicable)
- [ ] Logging works correctly
- [ ] Error handling works
- [ ] No hardcoded secrets
- [ ] Code follows style guidelines

## Submitting Pull Requests

### PR Checklist

- [ ] Code follows style guidelines
- [ ] All tests pass
- [ ] Documentation updated
- [ ] No hardcoded secrets
- [ ] Error handling implemented
- [ ] Logging added
- [ ] Rollback script created (if needed)
- [ ] Dependencies documented

### PR Description Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Code refactoring

## Testing
Describe how you tested your changes

## Checklist
- [ ] Code follows style guidelines
- [ ] Tests pass
- [ ] Documentation updated
```

## Scaling the Project

### Modular Design Principles

1. **Single Responsibility**: Each module should do one thing well
2. **Dependency Management**: Clearly document and manage dependencies
3. **Rollback Support**: Always provide rollback when possible
4. **Error Isolation**: Module failures shouldn't break the entire script

### Adding v1.0 Features

When adding new v1.0 features:

1. **GUI Components**: Add to `v1.0/gui/`
2. **Scheduler Features**: Add to `v1.0/scheduler/`
3. **Monitoring**: Add to `v1.0/monitor/`
4. **Shared Utilities**: Add to `v1.0/shared/`

### Configuration Management

- Use `v1.0/config/profiles.json` for profile definitions
- Keep configuration separate from code
- Support environment-specific configs

### Version Management

- Update script version in `windowstelementryblocker.ps1`
- Update `CHANGELOG.md` with changes
- Tag releases appropriately

### Performance Considerations

- Use `-ErrorAction SilentlyContinue` for non-critical operations
- Batch registry operations when possible
- Minimize external command calls
- Cache frequently accessed data

### Documentation Standards

- Keep README.md up to date
- Document all public functions
- Include examples in documentation
- Update CHANGELOG.md for all changes

## Code Review Process

1. **Automated Checks**: All PRs must pass CI/CD checks
2. **Security Scan**: Security workflow validates code
3. **Manual Review**: Maintainers review code quality
4. **Testing**: Changes must be tested before merge

## Questions?

- Open an issue for questions
- Check existing issues first
- Follow the code of conduct

Thank you for contributing to Windows Telemetry Blocker!
