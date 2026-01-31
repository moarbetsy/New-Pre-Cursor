# setup-cursor-portable.ps1
# Portable version - run from anywhere without installation
# Download and run: irm https://raw.githubusercontent.com/yourusername/setup-cursor/main/setup-cursor-portable.ps1 | iex

param(
    [switch]$Setup,
    [switch]$InstallTools,
    [switch]$UpdatePython,
    [switch]$ApplyAllSettings,
    [switch]$FixIssues,
    [switch]$SetupMCP,
    [switch]$Doctor,
    [switch]$Bootstrap,
    [switch]$Clean,
    [switch]$ApplyCursorSettings,
    [switch]$PreflightOnly,
    [string]$NewProject,
    [string]$PythonEntrypoint = ".\main.py",
    [string]$JsScript = "dev",
    [string]$DestinationRoot = "$HOME\Desktop"
)

# Self-contained setup-cursor script
# This file contains all the functionality needed to run setup-cursor from any computer

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
$OutputEncoding = [System.Text.UTF8Encoding]::new()

# Create temporary directory for portable execution
$tempDir = Join-Path $env:TEMP "setup-cursor-portable"
if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
}

# Download required files if not present
$requiredFiles = @(
    "https://raw.githubusercontent.com/moarbetsy/setup-cursor/main/run.ps1"
)

$localScript = Join-Path $tempDir "run.ps1"
if (-not (Test-Path $localScript)) {
    Write-Host "📥 Downloading setup-cursor..." -ForegroundColor Cyan
    try {
        Invoke-WebRequest -Uri $requiredFiles[0] -OutFile $localScript -UseBasicParsing
        Write-Host "✅ Downloaded setup-cursor" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to download setup-cursor: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# Execute the downloaded script with all parameters
Write-Host "🚀 Executing setup-cursor..." -ForegroundColor Cyan
Write-Host ""

# Build arguments array
$arguments = @()
if ($Setup) { $arguments += "-Setup" }
if ($InstallTools) { $arguments += "-InstallTools" }
if ($UpdatePython) { $arguments += "-UpdatePython" }
if ($ApplyAllSettings) { $arguments += "-ApplyAllSettings" }
if ($FixIssues) { $arguments += "-FixIssues" }
if ($SetupMCP) { $arguments += "-SetupMCP" }
if ($Doctor) { $arguments += "-Doctor" }
if ($Bootstrap) { $arguments += "-Bootstrap" }
if ($Clean) { $arguments += "-Clean" }
if ($ApplyCursorSettings) { $arguments += "-ApplyCursorSettings" }
if ($PreflightOnly) { $arguments += "-PreflightOnly" }
if ($NewProject) { $arguments += "-NewProject"; $arguments += $NewProject }
if ($PythonEntrypoint -ne ".\main.py") { $arguments += "-PythonEntrypoint"; $arguments += $PythonEntrypoint }
if ($JsScript -ne "dev") { $arguments += "-JsScript"; $arguments += $JsScript }
if ($DestinationRoot -ne "$HOME\Desktop") { $arguments += "-DestinationRoot"; $arguments += $DestinationRoot }

# Execute
& $localScript @arguments