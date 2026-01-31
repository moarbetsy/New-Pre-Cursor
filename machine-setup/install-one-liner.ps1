# One-liner installer for setup-cursor from any computer
# Run this command from any PowerShell terminal:

# Option 1: Direct execution (recommended)
# irm https://raw.githubusercontent.com/yourusername/setup-cursor/main/install-from-anywhere.ps1 | iex

# Option 2: Download and run
# Invoke-WebRequest -Uri "https://raw.githubusercontent.com/yourusername/setup-cursor/main/install-from-anywhere.ps1" -OutFile "$env:TEMP\install-setup-cursor.ps1"; & "$env:TEMP\install-setup-cursor.ps1"

# Option 3: Winget (once published)
# winget install YourName.SetupCursor

# Option 4: Portable usage (no installation)
# irm https://raw.githubusercontent.com/yourusername/setup-cursor/main/setup-cursor-portable.ps1 | iex -Setup

Write-Host "🌍 setup-cursor - Available from any computer!" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 Copy and paste one of these commands:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1️⃣  Install globally (recommended):" -ForegroundColor Green
Write-Host '   irm https://raw.githubusercontent.com/yourusername/setup-cursor/main/install-from-anywhere.ps1 | iex' -ForegroundColor White
Write-Host ""
Write-Host "2️⃣  Use portably (no installation):" -ForegroundColor Green
Write-Host '   irm https://raw.githubusercontent.com/yourusername/setup-cursor/main/setup-cursor-portable.ps1 | iex -Setup' -ForegroundColor White
Write-Host ""
Write-Host "3️⃣  Via winget (once published):" -ForegroundColor Green
Write-Host '   winget install YourName.SetupCursor' -ForegroundColor White
Write-Host ""
Write-Host "📖 Full documentation: https://github.com/yourusername/setup-cursor" -ForegroundColor Cyan