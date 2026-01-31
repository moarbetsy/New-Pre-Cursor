# create-release.ps1
# Create a GitHub release for setup-cursor

param(
    [string]$Version = "1.0.0",
    [string]$GitHubToken, # Get from https://github.com/settings/tokens
    [string]$Repo = "moarbetsy/setup-cursor"
)

Write-Host "📦 Creating GitHub release v$Version..." -ForegroundColor Cyan

# Create release archive
$releaseDir = "setup-cursor-v$Version"
$releasePath = "$releaseDir.zip"

if (Test-Path $releasePath) {
    Remove-Item $releasePath -Force
}

# Create a clean copy for release
$tempDir = Join-Path $env:TEMP "setup-cursor-release"
if (Test-Path $tempDir) {
    Remove-Item $tempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

# Copy files (exclude logs, temp files, etc.)
$excludePatterns = @("*.log", "logs", ".git", "*.tmp", "node_modules", ".venv")
Get-ChildItem -Path "." -Exclude $excludePatterns | Copy-Item -Destination $tempDir -Recurse -Force

# Create portable PowerShell script
$portableScript = @"
# setup-cursor-portable.ps1
# Portable version - run from anywhere without installation

# [Full portable script content here - embedded in release]
"@

$portableScript | Out-File (Join-Path $tempDir "setup-cursor-portable.ps1") -Encoding UTF8

# Create archive
Compress-Archive -Path "$tempDir\*" -DestinationPath $releasePath
Write-Host "✅ Created release archive: $releasePath" -ForegroundColor Green

# Create GitHub release if token provided
if ($GitHubToken) {
    Write-Host "🚀 Creating GitHub release..." -ForegroundColor Yellow

    $releaseData = @{
        tag_name = "v$Version"
        name = "setup-cursor v$Version"
        body = @"
# setup-cursor v$Version

A comprehensive "winget-like" development environment setup tool for Cursor IDE + PowerShell.

## Installation

### From any computer:
```powershell
irm https://raw.githubusercontent.com/$Repo/main/install-from-anywhere.ps1 | iex
```

### Or download and extract this ZIP, then run:
```powershell
.\install-global.ps1
```

## What's New in v$Version

- Complete environment setup with one command
- Global installation from any computer
- Winget-like package management
- Comprehensive IntelliSense configuration
- Automatic issue resolution
- MCP server setup

## Usage

```powershell
setup-cursor -Setup          # Complete environment setup
setup-cursor -Doctor         # Environment diagnostics
setup-cursor -NewProject "my-app"  # Create new project
```

---
*Full documentation: https://github.com/$Repo*
"@
        draft = $false
        prerelease = $false
    } | ConvertTo-Json

    try {
        $headers = @{
            "Authorization" = "token $GitHubToken"
            "Content-Type" = "application/json"
        }

        $releaseResponse = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases" -Method Post -Headers $headers -Body $releaseData
        Write-Host "✅ Created GitHub release: $($releaseResponse.html_url)" -ForegroundColor Green

        # Upload release asset
        $uploadUrl = $releaseResponse.upload_url -replace '\{.*\}', "?name=$releasePath"
        $fileBytes = [System.IO.File]::ReadAllBytes($releasePath)
        $fileEnc = [System.Text.Encoding]::GetEncoding('UTF-8').GetString($fileBytes)

        $uploadHeaders = @{
            "Authorization" = "token $GitHubToken"
            "Content-Type" = "application/zip"
        }

        Invoke-RestMethod -Uri $uploadUrl -Method Post -Headers $uploadHeaders -Body $fileBytes
        Write-Host "✅ Uploaded release asset: $releasePath" -ForegroundColor Green

    } catch {
        Write-Host "❌ Failed to create GitHub release: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Cleanup
Remove-Item $tempDir -Recurse -Force

Write-Host ""
Write-Host "🎉 Release v$Version created successfully!" -ForegroundColor Green
if (-not $GitHubToken) {
    Write-Host "💡 To publish to GitHub, run with -GitHubToken parameter" -ForegroundColor Yellow
}