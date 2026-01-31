#!/usr/bin/env pwsh
<#
.SYNOPSIS
    One command: setup and test the repo governor (project-doctor + optional governance).

.DESCRIPTION
    Runs project-doctor setup (scaffold + verification), then project-doctor unit tests.
    Optionally runs governance template CI (just ci) if just is installed.

.EXAMPLE
    .\setup-and-test.ps1
#>

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

$Root = if ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path } else { Get-Location }
$Doctor = Join-Path $Root "project-doctor"
$Governance = Join-Path $Root "templates\governance"

$failed = $false

# --- 1) Project doctor: setup (includes verification) ---
Write-Host ""
Write-Host "=== 1/3 Project doctor: setup ===" -ForegroundColor Cyan
Set-Location $Doctor
& bun run src/cli.ts setup
if (-not $?) {
    Write-Host "FAILED: project-doctor setup" -ForegroundColor Red
    $failed = $true
} else {
    Write-Host "OK: project-doctor setup" -ForegroundColor Green
}
Set-Location $Root

# --- 2) Project doctor: unit tests ---
Write-Host ""
Write-Host "=== 2/3 Project doctor: unit tests ===" -ForegroundColor Cyan
Set-Location $Doctor
& bun test
if (-not $?) {
    Write-Host "FAILED: project-doctor tests" -ForegroundColor Red
    $failed = $true
} else {
    Write-Host "OK: project-doctor tests" -ForegroundColor Green
}
Set-Location $Root

# --- 3) Governance template CI (optional if just is installed) ---
Write-Host ""
Write-Host "=== 3/3 Governance template: just ci ===" -ForegroundColor Cyan
if (Get-Command just -ErrorAction SilentlyContinue) {
    if (Test-Path $Governance) {
        Set-Location $Governance
        & just ci
        if (-not $?) {
            Write-Host "FAILED: governance just ci" -ForegroundColor Red
            $failed = $true
        } else {
            Write-Host "OK: governance just ci" -ForegroundColor Green
        }
        Set-Location $Root
    } else {
        Write-Host "SKIP: templates\governance not found" -ForegroundColor Yellow
    }
} else {
    Write-Host "SKIP: just not installed (optional). Install: winget install casey.just" -ForegroundColor Yellow
}

# --- Result ---
Write-Host ""
if ($failed) {
    Write-Host "Setup-and-test finished with failures." -ForegroundColor Red
    exit 1
}
Write-Host "Setup-and-test finished successfully." -ForegroundColor Green
exit 0
