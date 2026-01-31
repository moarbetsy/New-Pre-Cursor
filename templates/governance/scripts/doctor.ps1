Write-Host "== Governance System Template Doctor =="

Write-Host "`n-- Bun --"
if (Get-Command bun -ErrorAction SilentlyContinue) { bun --version } else { Write-Host "bun: NOT FOUND" }

Write-Host "`n-- Node (break-glass) --"
if (Get-Command node -ErrorAction SilentlyContinue) { node --version } else { Write-Host "node: NOT FOUND" }

Write-Host "`n-- Python --"
if (Get-Command python -ErrorAction SilentlyContinue) { python --version } else { Write-Host "python: NOT FOUND" }

Write-Host "`n-- uv --"
if (Get-Command uv -ErrorAction SilentlyContinue) { uv --version } else { Write-Host "uv: NOT FOUND" }

Write-Host "`n-- Rust --"
if (Get-Command rustc -ErrorAction SilentlyContinue) { rustc --version } else { Write-Host "rustc: NOT FOUND" }

Write-Host "`n-- just --"
if (Get-Command just -ErrorAction SilentlyContinue) { just --version } else { Write-Host "just: NOT FOUND" }

Write-Host "`n-- PowerShell 7 (pwsh) --"
$pwshCmd = Get-Command pwsh -ErrorAction SilentlyContinue
if ($pwshCmd) {
    $pwshVersion = & pwsh -NoProfile -Command '$PSVersionTable.PSVersion.ToString()'
    Write-Host "pwsh: $pwshVersion"
    $versionMajor = [int]($pwshVersion -split '\.')[0]
    if ($versionMajor -lt 7) {
        Write-Host "WARNING: PowerShell 7+ required (found version $pwshVersion). Install from https://aka.ms/powershell-release" -ForegroundColor Yellow
    }
} else {
    Write-Host "pwsh: NOT FOUND" -ForegroundColor Yellow
    Write-Host "WARNING: PowerShell 7 (pwsh) is required for Windows native execution. Install from https://aka.ms/powershell-release" -ForegroundColor Yellow
    Write-Host "Note: Windows PowerShell 5.1 (powershell.exe) is not sufficient. You need PowerShell 7 (pwsh)." -ForegroundColor Yellow
}

Write-Host "`nNext: run 'just ci'"
