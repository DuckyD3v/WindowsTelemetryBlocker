# ============================================================================
# Syntax Validation Tool
# ============================================================================
# Description: Validates PowerShell syntax for all scripts in the repository
# Usage: .\tools\validate-syntax.ps1
# ============================================================================

param(
    [switch]$Verbose,
    [string]$Path = "."
)

$ErrorActionPreference = "Stop"
$errors = @()
$warnings = @()
$scripts = Get-ChildItem -Path $Path -Filter *.ps1 -Recurse | Where-Object {
    $_.FullName -notmatch '\\test\\|\\tools\\|\\\.git\\'
}

Write-Host "Validating PowerShell syntax for $($scripts.Count) scripts..." -ForegroundColor Cyan
Write-Host ""

foreach ($script in $scripts) {
    $relativePath = $script.FullName.Replace((Get-Location).Path + "\", "")
    Write-Host "Checking: $relativePath" -ForegroundColor Gray
    
    try {
        $parseErrors = $null
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $script.FullName -Raw), [ref]$parseErrors)
        
        if ($parseErrors.Count -gt 0) {
            $errors += @{
                File = $relativePath
                Errors = $parseErrors
            }
            Write-Host "  [ERROR] Syntax errors found" -ForegroundColor Red
            if ($Verbose) {
                $parseErrors | ForEach-Object {
                    Write-Host "    Line $($_.Token.StartLine): $($_.Message)" -ForegroundColor Yellow
                }
            }
        } else {
            Write-Host "  [OK] Syntax valid" -ForegroundColor Green
        }
    } catch {
        $errors += @{
            File = $relativePath
            Errors = @("Failed to parse: $_")
        }
        Write-Host "  [ERROR] Parse failed: $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== Validation Summary ===" -ForegroundColor Cyan
Write-Host "Total scripts: $($scripts.Count)" -ForegroundColor White
Write-Host "Valid: $($scripts.Count - $errors.Count)" -ForegroundColor Green
Write-Host "Errors: $($errors.Count)" -ForegroundColor $(if ($errors.Count -eq 0) { "Green" } else { "Red" })

if ($errors.Count -gt 0) {
    Write-Host ""
    Write-Host "Files with errors:" -ForegroundColor Red
    foreach ($error in $errors) {
        Write-Host "  - $($error.File)" -ForegroundColor Yellow
    }
    exit 1
} else {
    Write-Host ""
    Write-Host "All scripts have valid syntax!" -ForegroundColor Green
    exit 0
}

