#!/usr/bin/env pwsh
#Requires -Version 7.0
<#
.SYNOPSIS
    Full PreCursor repo bootstrap: Cursor, repo path, machine-setup global install, tools (UV/Bun/Git), project-doctor setup.

.DESCRIPTION
    Idempotent. Safe to rerun. Use from repo root (after clone) or via precursor -Setup (which clones then calls this).
    Steps: 1) Install Cursor if missing. 2) Resolve repo root. 3) machine-setup install-global. 4) Install UV, Bun, Git. 5) project-doctor setup. 6) Print "Open this folder in Cursor."

.PARAMETER RepoRoot
    Override repo root (default: script parent if inside repo, else $env:USERPROFILE\PreCursor).

.PARAMETER GitHubRepo
    Clone URL if repo not present (e.g. https://github.com/owner/repo.git). Used when running from winget launcher.

.PARAMETER SkipCursor
    Do not install Cursor via winget.

.PARAMETER SkipTools
    Do not install UV, Bun, Git.

.EXAMPLE
    .\bootstrap.ps1
.EXAMPLE
    .\bootstrap.ps1 -RepoRoot $env:USERPROFILE\PreCursor -GitHubRepo "https://github.com/MoarBetsy/New-Pre-Cursor.git"
#>

[CmdletBinding()]
param(
    [string]$RepoRoot = "",
    [string]$GitHubRepo = "https://github.com/MoarBetsy/New-Pre-Cursor.git",
    [switch]$SkipCursor,
    [switch]$SkipTools
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

# Resolve repo root: explicit, or script dir (if this is the repo), or default PreCursor dir
$ScriptDir = if ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path } else { Get-Location }
if ($RepoRoot) {
    $Root = [System.IO.Path]::GetFullPath($RepoRoot)
} elseif (Test-Path (Join-Path $ScriptDir "machine-setup\install-global.ps1") -PathType Leaf) {
    $Root = $ScriptDir
} else {
    $Root = Join-Path $env:USERPROFILE "PreCursor"
}

$MachineSetup = Join-Path $Root "machine-setup"
$InstallGlobal = Join-Path $MachineSetup "install-global.ps1"
$RunPs1 = Join-Path $MachineSetup "run.ps1"
$DoctorDir = Join-Path $Root "project-doctor"

function Write-Step { param([string]$Message) Write-Host "`n== $Message ==" -ForegroundColor Cyan }
function Write-Ok { param([string]$Message) Write-Host "OK: $Message" -ForegroundColor Green }
function Write-Warn { param([string]$Message) Write-Host "WARN: $Message" -ForegroundColor Yellow }

# --- 0) Clone repo if missing ---
if (-not (Test-Path $Root -PathType Container)) {
    if (-not $GitHubRepo) {
        Write-Host "Repo root does not exist: $Root" -ForegroundColor Red
        Write-Host "Clone the repo there or run bootstrap.ps1 -RepoRoot <path> -GitHubRepo <clone-url>" -ForegroundColor Yellow
        exit 1
    }
    Write-Step "Cloning repo to $Root"
    $Parent = Split-Path -Parent $Root
    if (-not (Test-Path $Parent -PathType Container)) { New-Item -ItemType Directory -Path $Parent -Force | Out-Null }
    & git clone $GitHubRepo $Root
    if (-not $?) { Write-Host "Clone failed." -ForegroundColor Red; exit 1 }
    Write-Ok "Cloned repo"
}

if (-not (Test-Path $InstallGlobal -PathType Leaf)) {
    Write-Host "machine-setup not found at $MachineSetup. Repo layout invalid." -ForegroundColor Red
    exit 1
}

# --- 1) Cursor (winget) ---
if (-not $SkipCursor) {
    Write-Step "Cursor IDE"
    $cursorInstalled = Get-Command cursor -ErrorAction SilentlyContinue
    if (-not $cursorInstalled) {
        try {
            & winget install --id Cursor.Cursor -e --accept-source-agreements --accept-package-agreements
            if ($LASTEXITCODE -ne 0) { Write-Warn "winget Cursor install returned $LASTEXITCODE" }
            else { Write-Ok "Cursor installed" }
        } catch {
            Write-Warn "Could not install Cursor: $($_.Exception.Message)"
        }
    } else {
        Write-Ok "Cursor already available"
    }
}

# --- 2) Tools (UV, Bun, Git) ---
if (-not $SkipTools) {
    Write-Step "Development tools (UV, Bun, Git)"
    $tools = @(
        @{ Name = "UV";  Command = "uv";  Id = "astral-sh.uv" },
        @{ Name = "Bun"; Command = "bun"; Id = "Oven-sh.Bun" },
        @{ Name = "Git"; Command = "git"; Id = "Git.Git" }
    )
    foreach ($t in $tools) {
        if (Get-Command $t.Command -ErrorAction SilentlyContinue) {
            Write-Ok "$($t.Name) already installed"
        } else {
            Write-Host "Installing $($t.Name)..." -ForegroundColor Yellow
            & winget install --id $t.Id -e --accept-source-agreements --accept-package-agreements
            if ($LASTEXITCODE -eq 0) { Write-Ok "$($t.Name) installed" }
            else { Write-Warn "$($t.Name) install failed (exit $LASTEXITCODE)" }
        }
    }
    # Refresh PATH for current session
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

# --- 3) machine-setup install-global (setup-cursor in profile) ---
Write-Step "machine-setup install-global"
Push-Location $MachineSetup
try {
    & $InstallGlobal -Method PowerShellProfile
    if (-not $?) { Write-Warn "install-global.ps1 returned non-zero" }
    else { Write-Ok "setup-cursor registered globally" }
} finally {
    Pop-Location
}

# --- 4) project-doctor setup (bun install, cli setup) ---
if (Test-Path $DoctorDir -PathType Container) {
    Write-Step "project-doctor setup"
    if (Get-Command bun -ErrorAction SilentlyContinue) {
        Push-Location $DoctorDir
        try {
            & bun install
            if (-not $?) { Write-Warn "bun install failed" }
            else { Write-Ok "bun install" }
            & bun run src/cli.ts setup
            if (-not $?) { Write-Warn "bun run src/cli.ts setup failed" }
            else { Write-Ok "project-doctor setup" }
        } finally {
            Pop-Location
        }
    } else {
        Write-Warn "Bun not found; skipping project-doctor setup. Install Bun and re-run bootstrap."
    }
} else {
    Write-Warn "project-doctor not found at $DoctorDir; skipping."
}

# --- 5) Output ---
Write-Host ""
Write-Host "PreCursor bootstrap finished." -ForegroundColor Green
Write-Host "Open this folder in Cursor:" -ForegroundColor Cyan
Write-Host "  $Root" -ForegroundColor White
Write-Host ""
Write-Host "Then: setup-cursor -Setup (from any terminal) for full machine-setup in a project, or open the repo and work here." -ForegroundColor Gray
Write-Host ""
