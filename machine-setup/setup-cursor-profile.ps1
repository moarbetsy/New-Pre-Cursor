# setup-cursor-profile.ps1
# Add this to your PowerShell profile to enable global 'setup-cursor' command
# Run: notepad $PROFILE.CurrentUserAllHosts
# Then add: . "C:\Path\To\setup_cursor\setup-cursor-profile.ps1"

function setup-cursor {
    <#
    .SYNOPSIS
        Setup Cursor development environment (winget-like command)

    .DESCRIPTION
        Comprehensive development environment setup tool for Cursor IDE + PowerShell.
        Installs tools, updates dependencies, applies settings, and fixes issues.

    .PARAMETER Setup
        Run complete environment setup (recommended)

    .PARAMETER InstallTools
        Install UV, Bun, and Git via winget

    .PARAMETER UpdatePython
        Update Python and dependencies

    .PARAMETER ApplyAllSettings
        Apply all IDE settings

    .PARAMETER FixIssues
        Apply known issue fixes

    .PARAMETER SetupMCP
        Setup MCP servers

    .PARAMETER Doctor
        Run environment diagnostics

    .PARAMETER NewProject
        Create new project

    .PARAMETER Clean
        Clean project artifacts

    .EXAMPLE
        setup-cursor -Setup
        # Complete environment setup

    .EXAMPLE
        setup-cursor -Doctor
        # Check environment health

    .EXAMPLE
        setup-cursor -NewProject "my-project"
        # Create new project
    #>

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

    # Find the setup-cursor directory
    $scriptPath = $MyInvocation.MyCommand.Path
    $scriptDir = Split-Path -Parent $scriptPath
    $runScriptPath = Join-Path $scriptDir "run.ps1"

    if (-not (Test-Path $runScriptPath)) {
        Write-Host "ERROR: setup-cursor script not found at: $runScriptPath" -ForegroundColor Red
        Write-Host "Please ensure setup-cursor-profile.ps1 is in the same directory as run.ps1" -ForegroundColor Yellow
        return
    }

    # Build argument list
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

    # Execute the script
    & $runScriptPath @arguments
}

# Create alias for shorter command
Set-Alias sc setup-cursor

Write-Host "setup-cursor command loaded! Use 'setup-cursor -Setup' or 'sc -Setup'" -ForegroundColor Green