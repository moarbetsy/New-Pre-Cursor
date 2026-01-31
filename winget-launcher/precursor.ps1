#!/usr/bin/env pwsh
#Requires -Version 7.0
<#
.SYNOPSIS
    PreCursor launcher: run bootstrap for the PreCursor repo (clone if needed, then bootstrap.ps1).

.DESCRIPTION
    When installed via winget, this script is on PATH. precursor -Setup clones the repo (if missing)
    to PRECURSOR_ROOT or $env:USERPROFILE\PreCursor and runs bootstrap.ps1.

.PARAMETER Setup
    Clone repo if missing and run full bootstrap (Cursor, tools, machine-setup, project-doctor).
.PARAMETER RepoRoot
    Override target repo path.
#>

[CmdletBinding()]
param(
    [switch]$Setup,
    [string]$RepoRoot = ""
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

# Repo location: env override, or default
$DefaultRoot = Join-Path $env:USERPROFILE "PreCursor"
$TargetRoot = if ($RepoRoot) { $RepoRoot } elseif ($env:PRECURSOR_ROOT) { $env:PRECURSOR_ROOT } else { $DefaultRoot }

# GitHub clone URL (publish repo here; winget package can ship with this default)
$GitHubRepo = $env:PRECURSOR_GITHUB_REPO
if (-not $GitHubRepo) {
    $GitHubRepo = "https://github.com/MoarBetsy/New-Pre-Cursor.git"
}

if ($Setup) {
    $BootstrapPath = Join-Path $TargetRoot "bootstrap.ps1"
    # Clone repo if not present
    if (-not (Test-Path $BootstrapPath -PathType Leaf)) {
        $parent = Split-Path -Parent $TargetRoot
        if (-not (Test-Path $parent -PathType Container)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        Write-Host "Cloning PreCursor repo to $TargetRoot ..." -ForegroundColor Cyan
        & git clone $GitHubRepo $TargetRoot
        if (-not $?) { Write-Host "Clone failed." -ForegroundColor Red; exit 1 }
    }
    if (Test-Path $BootstrapPath -PathType Leaf) {
        & $BootstrapPath -RepoRoot $TargetRoot
        exit $LASTEXITCODE
    }
    Write-Host "Bootstrap not found at $BootstrapPath" -ForegroundColor Red
    exit 1
}

# No -Setup: print usage
Write-Host "PreCursor launcher. Usage: precursor -Setup" -ForegroundColor Cyan
Write-Host "  Target repo: $TargetRoot" -ForegroundColor Gray
Write-Host "  Set PRECURSOR_ROOT to override; set PRECURSOR_GITHUB_REPO for clone URL." -ForegroundColor Gray
