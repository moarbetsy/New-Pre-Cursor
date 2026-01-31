# Simple diagnostic script to test the Cursor + PowerShell setup
# Run this manually if the main run.ps1 has terminal issues

Write-Host "=== Cursor + PowerShell Setup Test ===" -ForegroundColor Cyan

# Test 1: Check PowerShell version
Write-Host "1. PowerShell Version:" -ForegroundColor Yellow
$PSVersionTable.PSVersion

# Test 2: Check required tools
Write-Host "`n2. Required Tools:" -ForegroundColor Yellow
$tools = @("pwsh", "python")
foreach ($tool in $tools) {
    try {
        $version = & $tool --version 2>$null
        Write-Host "  [OK] $tool`: $version" -ForegroundColor Green
    }
    catch {
        Write-Host "  [FAIL] $tool`: Not found" -ForegroundColor Red
    }
}

# Test 3: Check optional tools
Write-Host "`n3. Optional Tools:" -ForegroundColor Yellow
$optionalTools = @("uv", "bun")
foreach ($tool in $optionalTools) {
    try {
        $version = & $tool --version 2>$null
        Write-Host "  [OK] $tool`: $version" -ForegroundColor Green
    }
    catch {
        Write-Host "  [WARN] $tool`: Not found" -ForegroundColor Yellow
    }
}

# Test 4: Check project files
Write-Host "`n4. Project Files:" -ForegroundColor Yellow
$files = @("main.py", "package.json", "cursor-settings.json", ".gitignore", "README.md", "REPORT.md")
foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "  [OK] $file`: Present" -ForegroundColor Green
    }
    else {
        Write-Host "  [FAIL] $file`: Missing" -ForegroundColor Red
    }
}

# Test 5: Try to run Python script
Write-Host "`n5. Python Execution Test:" -ForegroundColor Yellow
if (Test-Path "main.py") {
    try {
        & python main.py
        Write-Host "  [OK] Python script executed successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "  [FAIL] Python script failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}
else {
    Write-Host "  [WARN] main.py not found, skipping Python test" -ForegroundColor Yellow
}

# Test 6: Try to run JavaScript
Write-Host "`n6. JavaScript Execution Test:" -ForegroundColor Yellow
if ((Get-Command bun -ErrorAction SilentlyContinue) -and (Test-Path "package.json")) {
    try {
        & bun run dev
        Write-Host "  [OK] JavaScript executed successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "  [FAIL] JavaScript failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}
else {
    Write-Host "  [WARN] bun not available or package.json missing, skipping JS test" -ForegroundColor Yellow
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Cyan
Write-Host "If you see this message, basic setup verification completed." -ForegroundColor White