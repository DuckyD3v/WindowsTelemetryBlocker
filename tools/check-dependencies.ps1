# ============================================================================
# Dependency Checker Tool
# ============================================================================
# Description: Validates module dependencies and structure
# Usage: .\tools\check-dependencies.ps1
# ============================================================================

param(
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"
$issues = @()

Write-Host "Checking module dependencies and structure..." -ForegroundColor Cyan
Write-Host ""

# Check main script for module list
$main = Get-Content windowstelementryblocker.ps1 -Raw
if ($main -match '\$moduleList\s*=\s*@\(([^)]+)\)') {
    $moduleList = $matches[1] -split ',' | ForEach-Object { $_.Trim().Replace("'", "").Replace('"', '') }
    Write-Host "Found modules in main script: $($moduleList -join ', ')" -ForegroundColor Green
} else {
    $issues += "Module list not found in main script"
    Write-Host "[ERROR] Module list not found" -ForegroundColor Red
}

# Check each module exists
foreach ($module in $moduleList) {
    $modulePath = "modules\$module.ps1"
    if (Test-Path $modulePath) {
        Write-Host "  [OK] $module.ps1 exists" -ForegroundColor Green
        
        # Check for rollback
        $rollbackPath = "modules\$module-rollback.ps1"
        if (Test-Path $rollbackPath) {
            Write-Host "    [OK] Rollback script exists" -ForegroundColor Green
        } else {
            Write-Host "    [WARN] No rollback script" -ForegroundColor Yellow
        }
        
        # Check for common.ps1 dot-sourcing
        $content = Get-Content $modulePath -Raw
        if ($content -match '\.\s+["'']\$PSScriptRoot/common\.ps1["'']') {
            Write-Host "    [OK] Dot-sources common.ps1" -ForegroundColor Green
        } else {
            $issues += "$module.ps1 does not dot-source common.ps1"
            Write-Host "    [ERROR] Does not dot-source common.ps1" -ForegroundColor Red
        }
    } else {
        $issues += "Module file not found: $modulePath"
        Write-Host "  [ERROR] $modulePath not found" -ForegroundColor Red
    }
}

# Check dependencies
if ($main -match '\$moduleDependencies\s*=\s*@\{([^}]+)\}') {
    Write-Host ""
    Write-Host "Checking dependency definitions..." -ForegroundColor Cyan
    # Parse dependencies (simplified check)
    Write-Host "  [OK] Dependency definitions found" -ForegroundColor Green
} else {
    $issues += "Module dependencies not found in main script"
    Write-Host "[ERROR] Dependency definitions not found" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Dependency Check Summary ===" -ForegroundColor Cyan
if ($issues.Count -eq 0) {
    Write-Host "All dependencies are properly defined!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Issues found:" -ForegroundColor Red
    $issues | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    exit 1
}

