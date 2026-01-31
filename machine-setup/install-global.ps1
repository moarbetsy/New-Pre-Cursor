# install-global.ps1
# Automatically install setup-cursor globally

param(
    [ValidateSet("BatchFile", "PowerShellProfile", "Path")]
    [string]$Method = "PowerShellProfile",

    [string]$InstallPath = "$env:USERPROFILE\bin"
)

Write-Host "🔧 Installing setup-cursor globally..." -ForegroundColor Cyan
Write-Host "Method: $Method" -ForegroundColor Gray
Write-Host ""

$scriptPath = $MyInvocation.MyCommand.Path
if ($null -eq $scriptPath) {
    # Fallback for when script was executed via iex (no file path)
    # Assume we're in the setup_cursor directory
    $SetupCursorDir = Get-Location
} else {
    $SetupCursorDir = Split-Path -Parent $scriptPath
}
$RunScriptPath = Join-Path $SetupCursorDir "run.ps1"
$ProfileScriptPath = Join-Path $SetupCursorDir "setup-cursor-profile.ps1"
$BatchFilePath = Join-Path $SetupCursorDir "setup-cursor.cmd"

# Validate that required files exist
$missingFiles = @()
if (-not (Test-Path $RunScriptPath)) { $missingFiles += "run.ps1" }
if (-not (Test-Path $ProfileScriptPath)) { $missingFiles += "setup-cursor-profile.ps1" }
if (-not (Test-Path $BatchFilePath)) { $missingFiles += "setup-cursor.cmd" }

if ($missingFiles.Count -gt 0) {
    Write-Host "❌ Missing required files: $($missingFiles -join ', ')" -ForegroundColor Red
    Write-Host "Please run this script from the setup_cursor directory." -ForegroundColor Yellow
    exit 1
}

switch ($Method) {
    "BatchFile" {
        Write-Host "📄 Installing as batch file..." -ForegroundColor Yellow

        # Copy to System32 (requires admin) or user bin directory
        $targetPaths = @(
            "$env:USERPROFILE\bin\setup-cursor.cmd",
            "$env:USERPROFILE\setup-cursor.cmd",
            "C:\Windows\System32\setup-cursor.cmd"
        )

        $installed = $false
        foreach ($targetPath in $targetPaths) {
            try {
                $targetDir = Split-Path -Parent $targetPath
                if (-not (Test-Path $targetDir)) {
                    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
                }

                Copy-Item $BatchFilePath $targetPath -Force
                Write-Host "✅ Installed to: $targetPath" -ForegroundColor Green
                $installed = $true

                # Check if target directory is in PATH
                $pathDirs = $env:Path -split ';' | Where-Object { $_ -and (Test-Path $_) }
                $targetDirInPath = $pathDirs -contains $targetDir

                if (-not $targetDirInPath) {
                    Write-Host "⚠️  Target directory not in PATH. Adding..." -ForegroundColor Yellow
                    $newPath = $env:Path + ";$targetDir"
                    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
                    Write-Host "✅ Added $targetDir to PATH" -ForegroundColor Green
                }
                break
            } catch {
                Write-Host "⚠️  Could not install to $targetPath : $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }

        if (-not $installed) {
            Write-Host "❌ Failed to install batch file to any location" -ForegroundColor Red
            exit 1
        }

        Write-Host ""
        Write-Host "🎉 Global installation complete!" -ForegroundColor Green
        Write-Host "Usage: setup-cursor -Setup" -ForegroundColor Cyan
    }

    "PowerShellProfile" {
        Write-Host "🐚 Installing to PowerShell profile..." -ForegroundColor Yellow

        $profilePath = $PROFILE.CurrentUserAllHosts
        $profileDir = Split-Path -Parent $profilePath

        # Create profile directory if it doesn't exist
        if (-not (Test-Path $profileDir)) {
            New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
        }

        # Read existing profile or create empty content
        $profileContent = ""
        if (Test-Path $profilePath) {
            $profileContent = Get-Content $profilePath -Raw
        }

        # Add setup-cursor import if not already present
        $importLine = ". `"$ProfileScriptPath`""
        if ($profileContent -notmatch [regex]::Escape($importLine)) {
            $profileContent += "`n# setup-cursor global command`n$importLine`n"
            $profileContent | Set-Content $profilePath -Encoding UTF8
            Write-Host "✅ Added setup-cursor to PowerShell profile: $profilePath" -ForegroundColor Green
        } else {
            Write-Host "✅ setup-cursor already in PowerShell profile" -ForegroundColor Green
        }

        Write-Host ""
        Write-Host "🎉 PowerShell profile updated!" -ForegroundColor Green
        Write-Host "Restart PowerShell/Cursor sessions to use:" -ForegroundColor Cyan
        Write-Host "  setup-cursor -Setup" -ForegroundColor White
        Write-Host "  sc -Setup  (short alias)" -ForegroundColor White
    }

    "Path" {
        Write-Host "📂 Adding to PATH..." -ForegroundColor Yellow

        # Add setup_cursor directory to PATH
        $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
        if ($currentPath -notlike "*$SetupCursorDir*") {
            $newPath = $currentPath + ";$SetupCursorDir"
            [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
            Write-Host "✅ Added $SetupCursorDir to PATH" -ForegroundColor Green
        } else {
            Write-Host "✅ setup_cursor directory already in PATH" -ForegroundColor Green
        }

        Write-Host ""
        Write-Host "🎉 PATH updated!" -ForegroundColor Green
        Write-Host "Usage: .\run.ps1 -Setup" -ForegroundColor Cyan
    }
}

Write-Host ""
Write-Host "📚 Available commands:" -ForegroundColor Cyan
Write-Host "  setup-cursor -Setup          # Complete setup" -ForegroundColor White
Write-Host "  setup-cursor -Doctor         # Environment check" -ForegroundColor White
Write-Host "  setup-cursor -InstallTools   # Install tools" -ForegroundColor White
Write-Host "  setup-cursor -NewProject 'name'  # Create project" -ForegroundColor White

if ($Method -eq "PowerShellProfile") {
    Write-Host "  sc -Setup                    # Short alias" -ForegroundColor White
}

Write-Host ""
Write-Host "📖 See README.md for all options!" -ForegroundColor Gray