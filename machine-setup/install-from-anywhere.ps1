# install-from-anywhere.ps1
# Install setup-cursor from any computer with internet access

param(
    [string]$GitHubRepo = "moarbetsy/setup-cursor",  # Change this to your actual GitHub repo
    [string]$Branch = "main",
    [ValidateSet("BatchFile", "PowerShellProfile", "Path")]
    [string]$Method = "PowerShellProfile",
    [switch]$Force
)

Write-Host "🌍 Installing setup-cursor from anywhere..." -ForegroundColor Cyan
Write-Host "Repository: https://github.com/$GitHubRepo" -ForegroundColor Gray
Write-Host ""

# Check if already installed
$installPath = "$env:USERPROFILE\.setup-cursor"
if ((Test-Path $installPath) -and -not $Force) {
    Write-Host "setup-cursor is already installed at: $installPath" -ForegroundColor Yellow
    Write-Host "Use -Force to reinstall" -ForegroundColor Gray
    exit 0
}

# Create installation directory
if (-not (Test-Path $installPath)) {
    New-Item -ItemType Directory -Path $installPath -Force | Out-Null
}

# Download setup-cursor files
$filesToDownload = @(
    "run.ps1",
    "setup-cursor-profile.ps1",
    "setup-cursor.cmd",
    "install-global.ps1",
    "README.md",
    "pyproject.toml",
    "requirements.txt",
    "package.json",
    "cursor-settings.json"
)

Write-Host "📥 Downloading setup-cursor files..." -ForegroundColor Yellow

foreach ($file in $filesToDownload) {
    try {
        $url = "https://raw.githubusercontent.com/$GitHubRepo/$Branch/$file"
        $localPath = Join-Path $installPath $file

        Invoke-WebRequest -Uri $url -OutFile $localPath -UseBasicParsing
        Write-Host "  ✅ Downloaded: $file" -ForegroundColor Green
    } catch {
        Write-Host "  ⚠️  Failed to download: $file ($($_.Exception.Message))" -ForegroundColor Yellow
    }
}

# Create local directories
$dirsToCreate = @("logs", ".cursor", ".vscode")
foreach ($dir in $dirsToCreate) {
    $dirPath = Join-Path $installPath $dir
    if (-not (Test-Path $dirPath)) {
        New-Item -ItemType Directory -Path $dirPath -Force | Out-Null
    }
}

# Create local files
$gitignoreContent = @"
.venv/
__pycache__/
*.pyc
node_modules/
dist/
build/
logs/
.DS_Store
"@

$readmeContent = @"
# Local setup-cursor Installation

This is a local installation of setup-cursor.
For documentation, visit: https://github.com/$GitHubRepo

Run setup-cursor commands from anywhere after installation:
- setup-cursor -Setup
- setup-cursor -Doctor
- setup-cursor -NewProject "my-project"
"@

$reportContent = @"
# Local Report

This is a local installation of setup-cursor.
Issues are tracked in the main repository: https://github.com/$GitHubRepo
"@

$gitignoreContent | Out-File -FilePath (Join-Path $installPath ".gitignore") -Encoding UTF8
$readmeContent | Out-File -FilePath (Join-Path $installPath "README.md") -Encoding UTF8
$reportContent | Out-File -FilePath (Join-Path $installPath "REPORT.md") -Encoding UTF8

Write-Host ""
Write-Host "🔧 Running local installation..." -ForegroundColor Yellow

# Change to install directory and run the global installer
Push-Location $installPath
try {
    & ".\install-global.ps1" -Method $Method
} finally {
    Pop-Location
}

Write-Host ""
Write-Host "🎉 setup-cursor installed from anywhere!" -ForegroundColor Green
Write-Host "Installation path: $installPath" -ForegroundColor Gray
Write-Host ""
Write-Host "📖 Full documentation: https://github.com/$GitHubRepo" -ForegroundColor Cyan