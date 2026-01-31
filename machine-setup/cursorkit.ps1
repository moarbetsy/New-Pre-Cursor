#!/usr/bin/env pwsh
#Requires -Version 7.0

<#
.SYNOPSIS
    CursorKit 2026 - Ultimate Environment Bootstrapper (Best-of-Breed)

.DESCRIPTION
    Combines:
    - Robust JSONC parsing and atomic I/O
    - Useful repo onboarding features (extensions, Doctor/Clean)
    - Detailed policy templates

    Safety upgrades:
    - Git hooks are opt-in (-EnableGitHooks)
    - Full -WhatIf/-Confirm support
    - Repo root resolution is consistent (git-aware)
    - Atomic profile modifications (no Add-Content)
#>

[CmdletBinding(DefaultParameterSetName = 'Run', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(ParameterSetName = 'Setup')][switch]$Setup,
    [Parameter(ParameterSetName = 'Doctor')][switch]$Doctor,
    [Parameter(ParameterSetName = 'Clean')][switch]$Clean,

    [Parameter(ParameterSetName = 'Setup')][switch]$EnableGitHooks,
    [Parameter(ParameterSetName = 'Setup')][switch]$GlobalInstall,
    [Parameter(ParameterSetName = 'Setup')][switch]$SkipToolInstall,

    [Parameter()][switch]$Force,
    [Parameter()][string]$RootPath = (Get-Location).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:__pscmdlet = $PSCmdlet

# Repo root (set in MAIN after Resolve-RepoRoot)
$script:RepoRoot = $null

#region ==================== LOGGING ====================
function Write-Log {
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet("INFO","STEP","WARN","ERROR","DONE","OK","SKIP")][string]$Level = "INFO"
    )
    $colors = @{
        "INFO"  = "White"; "STEP"  = "Cyan"; "WARN"  = "Yellow"
        "ERROR" = "Red";   "DONE"  = "Green"; "OK"    = "Green"
        "SKIP"  = "Magenta"
    }
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp][$Level] $Message" -ForegroundColor $colors[$Level]
}

function Should-Do {
    param(
        [Parameter(Mandatory)][string]$Target,
        [Parameter(Mandatory)][string]$Action
    )
    if ($null -eq $script:__pscmdlet) { return $true }
    return $script:__pscmdlet.ShouldProcess($Target, $Action)
}
#endregion

#region ==================== PATH / REPO ROOT ====================
function Resolve-FullPath {
    param([Parameter(Mandatory)][string]$Path)
    $p = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
    return [System.IO.Path]::GetFullPath($p)
}

function Test-CommandExists {
    param([Parameter(Mandatory)][string]$Command)
    return [bool](Get-Command -Name $Command -ErrorAction SilentlyContinue)
}

function Resolve-RepoRoot {
    param([Parameter(Mandatory)][string]$StartPath)

    $full = Resolve-FullPath $StartPath
    if (-not (Test-Path -LiteralPath $full)) {
        throw "RootPath does not exist: $full"
    }

    # If git is available, prefer real repo root.
    if (Test-CommandExists "git") {
        try {
            $root = (& git -C $full rev-parse --show-toplevel 2>$null | Select-Object -First 1).Trim()
            if ($root) { return (Resolve-FullPath $root) }
        } catch { }
    }

    # Otherwise, walk up looking for .git
    $cur = $full
    while ($cur -and (Test-Path -LiteralPath $cur -PathType Container)) {
        if (Test-Path -LiteralPath (Join-Path $cur ".git") -PathType Container) { return $cur }
        $parent = Split-Path -Parent $cur
        if ($parent -eq $cur) { break }
        $cur = $parent
    }

    return $full
}
#endregion

#region ==================== SECURE FILE OPS ====================
function Get-Utf8NoBomEncoding { [System.Text.UTF8Encoding]::new($false) }

function Normalize-Newlines {
    param([AllowNull()][string]$Text)
    if ($null -eq $Text) { return "" }
    return ($Text -replace "`r`n", "`n") -replace "`r", "`n"
}

function Ensure-Directory {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        if (Should-Do $Path "Create directory") {
            New-Item -ItemType Directory -Path $Path -Force | Out-Null
        } else {
            Write-Log "WhatIf: would create directory $Path" "SKIP"
        }
    }
}

function Backup-FileOnce {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return }
    $bak = "$Path.bak"
    if (-not (Test-Path -LiteralPath $bak -PathType Leaf)) {
        if (Should-Do $bak "Create backup of $Path") {
            Copy-Item -LiteralPath $Path -Destination $bak -Force
            Write-Log "Backed up: $bak" "OK"
        } else {
            Write-Log "WhatIf: would back up $Path -> $bak" "SKIP"
        }
    }
}

# Repo-root aware timestamp backups (collision-safe)
function Test-IsUnderRepoRoot {
    param([Parameter(Mandatory)][string]$FullPath)
    if (-not $script:RepoRoot) { return $false }

    $root = (Resolve-FullPath $script:RepoRoot).TrimEnd([char]'\',[char]'/')
    $p    = (Resolve-FullPath $FullPath)

    $cmp = if ($IsWindows) { [System.StringComparison]::OrdinalIgnoreCase } else { [System.StringComparison]::Ordinal }
    $sep = [System.IO.Path]::DirectorySeparatorChar

    return $p.StartsWith($root + $sep, $cmp) -or $p.Equals($root, $cmp)
}

function New-TimestampBackupPath {
    param([Parameter(Mandatory)][string]$FullPath)

    # Only do timestamp backups for files inside the repo.
    if (-not (Test-IsUnderRepoRoot -FullPath $FullPath)) { return $null }

    # Millisecond precision + short random suffix => no same-second collisions.
    $ts   = Get-Date -Format "yyyyMMdd-HHmmssfff"
    $rand = [guid]::NewGuid().ToString('N').Substring(0,6)

    $rel = [System.IO.Path]::GetRelativePath((Resolve-FullPath $script:RepoRoot), (Resolve-FullPath $FullPath))

    $backupRoot = Join-Path $script:RepoRoot ".cursorkit\backups"
    $relDir  = Split-Path $rel -Parent
    $leaf    = Split-Path $rel -Leaf

    $dir = if ($relDir -and $relDir -ne ".") { Join-Path $backupRoot $relDir } else { $backupRoot }
    Ensure-Directory $dir

    return (Join-Path $dir "$leaf.$ts.$rand.bak")
}

function Write-FileAtomicUtf8NoBom {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Content
    )

    $full = Resolve-FullPath $Path
    $dir  = Split-Path -Parent $full
    if ($dir) { Ensure-Directory $dir }

    $leaf = Split-Path -Leaf $full
    $guid = [guid]::NewGuid().ToString('N').Substring(0, 12)
    $tmp  = Join-Path $dir ".tmp.$leaf.$guid"

    if (-not (Should-Do $full "Write file atomically")) {
        Write-Log "WhatIf: would atomically write $full" "SKIP"
        return
    }

    try {
        [System.IO.File]::WriteAllText($tmp, $Content, (Get-Utf8NoBomEncoding))

        if (Test-Path -LiteralPath $full -PathType Leaf) {
            # Optional timestamped backup (repo-local)
            $replaceBackup = New-TimestampBackupPath -FullPath $full

            try {
                # Best: atomic replace with optional atomic backup of old file
                [System.IO.File]::Replace($tmp, $full, $replaceBackup, $true) | Out-Null
            } catch {
                # Hardened fallback: do NOT delete-first.
                # Try to clear read-only then overwrite via Copy.
                try {
                    $attrs = [System.IO.File]::GetAttributes($full)
                    if (($attrs -band [System.IO.FileAttributes]::ReadOnly) -ne 0) {
                        $newAttrs = $attrs -band (-bnot [System.IO.FileAttributes]::ReadOnly)
                        [System.IO.File]::SetAttributes($full, $newAttrs)
                    }
                } catch { }

                Write-Log "File.Replace failed; used overwrite-copy fallback for: $full" "WARN"
                [System.IO.File]::Copy($tmp, $full, $true)
                Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
            }
        } else {
            Move-Item -LiteralPath $tmp -Destination $full -Force
        }
    }
    finally {
        if (Test-Path -LiteralPath $tmp -PathType Leaf) {
            Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
        }
    }
}

function Set-TextFileExact {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Content
    )

    $full = Resolve-FullPath $Path
    $dir  = Split-Path -Parent $full
    if ($dir) { Ensure-Directory $dir }

    $existing = $null
    if (Test-Path -LiteralPath $full -PathType Leaf) {
        $existing = Get-Content -LiteralPath $full -Raw -ErrorAction SilentlyContinue
    }

    if ((Normalize-Newlines $existing) -eq (Normalize-Newlines $Content)) {
        Write-Log "Up-to-date: $full" "OK"
        return
    }

    Backup-FileOnce -Path $full
    Write-FileAtomicUtf8NoBom -Path $full -Content $Content
    Write-Log "Wrote/updated: $full" "DONE"
}
#endregion

#region ==================== JSONC PARSING ====================
function Remove-JsonComments {
    param([Parameter(Mandatory)][string]$Text)

    $sb = [System.Text.StringBuilder]::new()
    $inString = $false
    $escape = $false
    $inLineComment = $false
    $inBlockComment = $false

    for ($i = 0; $i -lt $Text.Length; $i++) {
        $c = $Text[$i]
        $n = if ($i + 1 -lt $Text.Length) { $Text[$i + 1] } else { [char]0 }

        if ($inLineComment) {
            if ($c -eq "`n") { $inLineComment = $false; [void]$sb.Append($c) }
            continue
        }

        if ($inBlockComment) {
            if ($c -eq '*' -and $n -eq '/') { $inBlockComment = $false; $i++ }
            continue
        }

        if ($inString) {
            [void]$sb.Append($c)
            if ($escape) { $escape = $false; continue }
            if ($c -eq '\') { $escape = $true; continue }
            if ($c -eq '"') { $inString = $false }
            continue
        }

        if ($c -eq '"') { $inString = $true; [void]$sb.Append($c); continue }
        if ($c -eq '/' -and $n -eq '/') { $inLineComment = $true; $i++; continue }
        if ($c -eq '/' -and $n -eq '*') { $inBlockComment = $true; $i++; continue }

        [void]$sb.Append($c)
    }

    return $sb.ToString()
}

function Remove-TrailingCommasJson {
    param([Parameter(Mandatory)][string]$Text)

    $sb = [System.Text.StringBuilder]::new()
    $inString = $false
    $escape = $false

    for ($i = 0; $i -lt $Text.Length; $i++) {
        $c = $Text[$i]

        if ($inString) {
            [void]$sb.Append($c)
            if ($escape) { $escape = $false; continue }
            if ($c -eq '\') { $escape = $true; continue }
            if ($c -eq '"') { $inString = $false }
            continue
        }

        if ($c -eq '"') { $inString = $true; [void]$sb.Append($c); continue }

        if ($c -eq ',') {
            $j = $i + 1
            while ($j -lt $Text.Length -and [char]::IsWhiteSpace($Text[$j])) { $j++ }
            if ($j -lt $Text.Length) {
                $next = $Text[$j]
                if ($next -eq '}' -or $next -eq ']') { continue }
            }
        }

        [void]$sb.Append($c)
    }

    return $sb.ToString()
}

function ConvertFrom-JsoncHashtable {
    param([Parameter(Mandatory)][string]$Text)

    $clean = Remove-JsonComments -Text $Text
    $clean = Remove-TrailingCommasJson -Text $clean

    try {
        return ($clean | ConvertFrom-Json -AsHashtable -Depth 100)
    } catch {
        throw "Failed to parse JSONC: $($_.Exception.Message)"
    }
}

function Merge-HashtableRecursive {
    param(
        [Parameter(Mandatory)][hashtable]$Target,
        [Parameter(Mandatory)][hashtable]$Source
    )

    foreach ($k in $Source.Keys) {
        if ($Target.ContainsKey($k)) {
            $tv = $Target[$k]
            $sv = $Source[$k]
            if (($tv -is [hashtable]) -and ($sv -is [hashtable])) {
                Merge-HashtableRecursive -Target $tv -Source $sv
            } else {
                $Target[$k] = $sv
            }
        } else {
            $Target[$k] = $Source[$k]
        }
    }
}
#endregion

#region ==================== TOOL MANAGEMENT ====================
function Get-PwshExePath {
    $cmd = Get-Command -Name pwsh -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source) { return $cmd.Source }

    $candidates = @(
        (Join-Path $env:ProgramFiles 'PowerShell\7\pwsh.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'PowerShell\7\pwsh.exe'),
        (Join-Path $env:LocalAppData 'Programs\PowerShell\7\pwsh.exe'),
        "$env:USERPROFILE\.dotnet\tools\pwsh.exe"
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Leaf) }

    if ($candidates.Count -gt 0) { return $candidates[0] }
    return "pwsh.exe"
}

function Install-ToolsWithWinget {
    # Exit-code hardening + OS gate
    if (-not $IsWindows) {
        Write-Log "Non-Windows platform: skipping winget installs" "SKIP"
        return $true
    }

    if (-not (Test-CommandExists "winget")) {
        Write-Log "winget not found. Install App Installer from Microsoft Store." "ERROR"
        return $false
    }

    $tools = @(
        @{ Name = "pwsh"; Id = "Microsoft.PowerShell" }
        @{ Name = "git";  Id = "Git.Git" }
        @{ Name = "uv";   Id = "astral-sh.uv" }
        @{ Name = "bun";  Id = "Oven-sh.Bun" }
    )

    $toInstall = foreach ($tool in $tools) {
        if (-not (Test-CommandExists $tool.Name)) { $tool }
    }

    if (-not $toInstall -or $toInstall.Count -eq 0) {
        Write-Log "All tools already installed" "OK"
        return $true
    }

    if (-not $Force) {
        Write-Host "`nThe following tools will be installed via winget:" -ForegroundColor Cyan
        $toInstall | ForEach-Object { Write-Host "  - $($_.Id)" -ForegroundColor White }
        $confirm = Read-Host "Continue? (Y/N)"
        if ($confirm -notmatch '^[Yy]') {
            Write-Log "Installation cancelled" "WARN"
            return $false
        }
    }

    $allOk = $true

    foreach ($tool in $toInstall) {
        $target = "winget install $($tool.Id)"
        if (-not (Should-Do $target "Install tool")) {
            Write-Log "WhatIf: would install $($tool.Id)" "SKIP"
            continue
        }

        try {
            Write-Log "Installing $($tool.Id)..." "STEP"

            $out = & winget install --id $tool.Id -e --accept-source-agreements --accept-package-agreements --silent 2>&1
            $exit = $LASTEXITCODE

            if ($exit -ne 0) {
                $allOk = $false
                $snippet = ($out | Select-Object -First 10) -join "`n"
                Write-Log "winget failed ($exit) installing $($tool.Id). Output:`n$snippet" "ERROR"
                continue
            }

            Write-Log "Installed $($tool.Id)" "OK"
        } catch {
            $allOk = $false
            Write-Log "Failed to install $($tool.Id): $_" "ERROR"
        }
    }

    return $allOk
}
#endregion

#region ==================== CONFIGURATION ====================
function Set-WorkspaceSettings {
    param([Parameter(Mandatory)][string]$RepoRoot)

    $settingsPath = Join-Path $RepoRoot ".vscode\settings.json"
    Ensure-Directory (Split-Path -Parent $settingsPath)

    $desired = @{
        "terminal.integrated.profiles.windows" = @{
            "PowerShell 7 (NoProfile)" = @{
                "path" = (Get-PwshExePath)
                "args" = @("-NoLogo","-NoProfile")
            }
        }
        "terminal.integrated.defaultProfile.windows" = "PowerShell 7 (NoProfile)"
        "files.watcherExclude" = @{
            "**/.venv/**"        = $true
            "**/node_modules/**" = $true
            "**/__pycache__/**"  = $true
        }
        "search.exclude" = @{
            "**/.venv"        = $true
            "**/node_modules" = $true
            "**/dist"         = $true
        }
        "powershell.integratedConsole.showOnStartup" = $false
        "powershell.startAutomatically" = $false
        "powershell.enableProfileLoading" = $false
        "[powershell]" = @{
            "editor.defaultFormatter" = "ms-vscode.powershell"
            "editor.formatOnSave" = $true
        }
        "[python]" = @{
            "editor.formatOnSave" = $true
        }
    }

    $current = @{}
    if (Test-Path -LiteralPath $settingsPath -PathType Leaf) {
        try {
            $raw = Get-Content -LiteralPath $settingsPath -Raw
            $current = ConvertFrom-JsoncHashtable -Text $raw
            if (-not ($current -is [hashtable])) { $current = @{} }
        } catch {
            Write-Log "settings.json parse failed; backing up and recreating" "WARN"
            Backup-FileOnce -Path $settingsPath
            $current = @{}
        }
    }

    Merge-HashtableRecursive -Target $current -Source $desired
    $json = ($current | ConvertTo-Json -Depth 100) + "`n"
    Set-TextFileExact -Path $settingsPath -Content $json
}

function Set-VSCodeExtensions {
    param([Parameter(Mandatory)][string]$RepoRoot)

    $extPath = Join-Path $RepoRoot ".vscode\extensions.json"
    Ensure-Directory (Split-Path -Parent $extPath)

    $extensions = @{
        "recommendations" = @(
            "ms-vscode.powershell",
            "charliermarsh.ruff",
            "tamasfe.even-better-toml",
            "usernamehw.errorlens"
        )
    }

    $json = ($extensions | ConvertTo-Json) + "`n"
    Set-TextFileExact -Path $extPath -Content $json
}

function Set-PolicyFiles {
    param([Parameter(Mandatory)][string]$RepoRoot)

    $cursorIgnore = @'
# Secrets
.env
.env.*
**/*secret*
**/*token*
**/*apikey*
**/*.pfx
**/*.pem
**/*.key

# CursorKit backups
.cursorkit/

# Dependencies / Caches
.venv/
node_modules/
**/__pycache__/
**/*.pyc
.pytest_cache/
.mypy_cache/
.ruff_cache/

# Builds / Logs
dist/
build/
out/
logs/
*.log
'@

    $cursorIndexIgnore = @'
.cursorkit/
.venv/
node_modules/
dist/
build/
out/
**/__pycache__/
**/*.min.js
**/*.map
'@

    Set-TextFileExact -Path (Join-Path $RepoRoot ".cursorignore") -Content ($cursorIgnore + "`n")
    Set-TextFileExact -Path (Join-Path $RepoRoot ".cursorindexingignore") -Content ($cursorIndexIgnore + "`n")

    $rulesDir = Join-Path $RepoRoot ".cursor\rules"
    Ensure-Directory $rulesDir

    Set-TextFileExact -Path (Join-Path $rulesDir "00-windows-shell.mdc") -Content (@'
---
description: "Windows shell baseline: pwsh-only + -NoProfile"
alwaysApply: true
---
# Windows shell contract
- Target OS: Windows 11.
- Shell: PowerShell 7+ (`pwsh`) only.
- Assume terminals start with: `pwsh -NoLogo -NoProfile`
- Never output bash/zsh syntax: `&&`, `||`, `export`, `source`, `touch`, `ls -la`.
- Command sequencing: use `;` and explicit checks.
'@ + "`n")

    Set-TextFileExact -Path (Join-Path $rulesDir "10-toolchain-uv-bun.mdc") -Content (@'
---
description: "Toolchain: uv for Python, bun for JavaScript"
alwaysApply: true
---
# Toolchain contract
## Python
- Use: `uv venv`, `uv sync`, `uv run`
- Never use: `pip install`, `python -m venv`
## JavaScript
- Use: `bun install`, `bun run <script>`
- Never use: `npm`, `yarn`
'@ + "`n")

    Set-TextFileExact -Path (Join-Path $rulesDir "20-fail-fast.mdc") -Content (@'
---
description: "Fail-fast and report style"
alwaysApply: true
---
# Fail-fast contract
- Any native command must check exit codes.
- On failure: stop and report command + exit code + next step.
'@ + "`n")

    Set-TextFileExact -Path (Join-Path $rulesDir "40-diagnostics.mdc") -Content (@'
---
description: "Self-healing diagnostics"
alwaysApply: false
---
# Diagnostics
- **Command Not Found**: Run `cursorkit -Setup`
- **Terminal Hangs**: Switch to Windows Terminal to isolate.
'@ + "`n")

    Set-TextFileExact -Path (Join-Path $rulesDir "INCIDENTS.md") -Content (@'
# Rule Incidents (agent mistake log)
Purpose: Track repeat mistakes to update rules instead of re-litigating.

## Format
- Date:
- Trigger:
- What happened:
- Expected behavior:
- Proposed rule change:
- Status: open | accepted | rejected
'@ + "`n")

    $skillDir = Join-Path $RepoRoot ".cursor\skills\doctor"
    Ensure-Directory $skillDir
    Set-TextFileExact -Path (Join-Path $skillDir "SKILL.md") -Content (@'
---
name: doctor
description: Diagnose and repair Windows Cursor dev environment
---
# Doctor Skill
## When to use
- Commands hang or fail
- Tools missing from PATH
## Procedure
1) Run: `cursorkit -Doctor`
2) If tools missing: `cursorkit -Setup`
'@ + "`n")

    # AGENTS.md atomic append
    $agentsPath = Join-Path $RepoRoot "AGENTS.md"
    $mcpBlock = @"

## MCP policy
If an MCP server is configured, use it for authoritative lookups instead of guessing.

"@

    if (-not (Test-Path -LiteralPath $agentsPath -PathType Leaf)) {
        $content = "# Agent Operating Policy`n$mcpBlock"
        Set-TextFileExact -Path $agentsPath -Content $content
    } else {
        $existing = Get-Content -LiteralPath $agentsPath -Raw -ErrorAction SilentlyContinue
        if ((Normalize-Newlines $existing) -notmatch "## MCP policy") {
            Backup-FileOnce -Path $agentsPath
            $new = ($existing.TrimEnd() + (Normalize-Newlines $mcpBlock) + "`n")
            Write-FileAtomicUtf8NoBom -Path $agentsPath -Content $new
            Write-Log "Appended MCP policy to AGENTS.md" "DONE"
        }
    }
}

function Set-GitHooksSafe {
    param([Parameter(Mandatory)][string]$RepoRoot)

    if (-not (Test-Path -LiteralPath (Join-Path $RepoRoot ".git") -PathType Container)) {
        Write-Log "No .git directory; skipping hooks" "SKIP"
        return
    }

    $hooksDir = Join-Path $RepoRoot ".githooks"
    Ensure-Directory $hooksDir

    $psHook = Join-Path $hooksDir "pre-commit.ps1"
    Set-TextFileExact -Path $psHook -Content (@'
#Requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repo = (& git rev-parse --show-toplevel 2>$null | Select-Object -First 1).Trim()
if (-not $repo) { $repo = (Get-Location).Path }
Push-Location $repo
try {
    Write-Host "[pre-commit] Running checks..." -ForegroundColor Cyan

    # 1) Large files (>5MB)
    $files = git ls-files --exclude-standard -co
    $large = @()
    foreach ($f in $files) {
        try {
            $item = Get-Item -LiteralPath $f -ErrorAction Stop
            if ($item.Length -gt 5MB) { $large += $f }
        } catch { }
    }
    if ($large.Count -gt 0) { throw "Large files detected (>5MB): $($large -join ', ')" }

    # 2) Simple secret patterns on staged text files
    $patterns = @('password\s*=', 'api[_-]?key\s*=', 'secret\s*=')
    $staged = git diff --cached --name-only
    foreach ($file in $staged) {
        if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { continue }

        # Skip big files and probable binaries
        try {
            $item = Get-Item -LiteralPath $file -ErrorAction Stop
            if ($item.Length -gt 2MB) { continue }
        } catch { continue }

        try {
            $content = Get-Content -LiteralPath $file -Raw -ErrorAction Stop
        } catch {
            continue
        }

        foreach ($pat in $patterns) {
            if ($content -match $pat) {
                Write-Host "WARNING: Potential secret pattern '$pat' in $file" -ForegroundColor Yellow
            }
        }
    }

    Write-Host "[pre-commit] OK" -ForegroundColor Green
} finally {
    Pop-Location
}
'@ + "`n")

    $shim = Join-Path $hooksDir "pre-commit"
    Set-TextFileExact -Path $shim -Content (@'
#!/bin/sh
DIR="$(cd "$(dirname "$0")" && pwd)"
exec pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File "$DIR/pre-commit.ps1"
'@ + "`n")

    # Make hooks active (opt-in)
    $target = "git config core.hooksPath .githooks (repo: $RepoRoot)"
    if (Should-Do $target "Configure git hooksPath") {
        try {
            $out = & git -C $RepoRoot config core.hooksPath .githooks 2>&1
            $exit = $LASTEXITCODE
            if ($exit -ne 0) {
                $snippet = ($out | Select-Object -First 10) -join "`n"
                Write-Log "Git hooks configuration failed ($exit):`n$snippet" "WARN"
            } else {
                Write-Log "Git hooks configured (core.hooksPath=.githooks)" "OK"
            }
        } catch {
            Write-Log "Git hooks configuration failed: $_" "WARN"
        }
    } else {
        Write-Log "WhatIf: would set core.hooksPath to .githooks" "SKIP"
    }
}
#endregion

#region ==================== ACTIONS ====================
function Invoke-Setup {
    param([Parameter(Mandatory)][string]$RepoRoot)

    Write-Log "Starting CursorKit setup..." "STEP"

    if (-not $SkipToolInstall) {
        $installedOk = Install-ToolsWithWinget
        if (-not $installedOk) {
            Write-Log "Tool install skipped/failed. Continuing repo configuration." "WARN"
        }
    } else {
        Write-Log "Skipping tool installation (-SkipToolInstall)" "SKIP"
    }

    Set-WorkspaceSettings  -RepoRoot $RepoRoot
    Set-VSCodeExtensions   -RepoRoot $RepoRoot
    Set-PolicyFiles        -RepoRoot $RepoRoot

    if ($EnableGitHooks) {
        Set-GitHooksSafe -RepoRoot $RepoRoot
    } else {
        Write-Log "Git hooks not enabled (use -EnableGitHooks)" "SKIP"
    }

    # Dependency installs (only if tools exist) + exit-code hardening
    if (Test-Path -LiteralPath (Join-Path $RepoRoot "pyproject.toml") -PathType Leaf) {
        if (Test-CommandExists "uv") {
            $target = "uv sync (repo: $RepoRoot)"
            if (Should-Do $target "Install Python dependencies") {
                Write-Log "Installing Python dependencies with UV..." "STEP"
                Push-Location $RepoRoot
                try {
                    $out = & uv sync 2>&1
                    $exit = $LASTEXITCODE
                    if ($exit -ne 0) {
                        $snippet = ($out | Select-Object -First 20) -join "`n"
                        throw "uv sync failed ($exit). Output:`n$snippet"
                    }
                } finally { Pop-Location }
            } else { Write-Log "WhatIf: would run uv sync" "SKIP" }
        }
    }

    if (Test-Path -LiteralPath (Join-Path $RepoRoot "package.json") -PathType Leaf) {
        if (Test-CommandExists "bun") {
            $target = "bun install (repo: $RepoRoot)"
            if (Should-Do $target "Install Node dependencies") {
                Write-Log "Installing Node dependencies with Bun..." "STEP"
                Push-Location $RepoRoot
                try {
                    $out = & bun install 2>&1
                    $exit = $LASTEXITCODE
                    if ($exit -ne 0) {
                        $snippet = ($out | Select-Object -First 20) -join "`n"
                        throw "bun install failed ($exit). Output:`n$snippet"
                    }
                } finally { Pop-Location }
            } else { Write-Log "WhatIf: would run bun install" "SKIP" }
        }
    }

    # Global alias (opt-in, atomic)
    if ($GlobalInstall) {
        $profilePath = Resolve-FullPath $PROFILE.CurrentUserAllHosts
        Ensure-Directory (Split-Path -Parent $profilePath)

        $aliasLine = "function cursorkit { & '$PSCommandPath' @args }"
        $existing = ""
        if (Test-Path -LiteralPath $profilePath -PathType Leaf) {
            $existing = Get-Content -LiteralPath $profilePath -Raw -ErrorAction SilentlyContinue
        }

        if ($existing -notmatch [regex]::Escape($aliasLine)) {
            Backup-FileOnce -Path $profilePath
            $new = ($existing.TrimEnd() + "`n# CursorKit`n$aliasLine`n")
            Set-TextFileExact -Path $profilePath -Content $new
            Write-Log "Added global 'cursorkit' function to profile" "OK"
        } else {
            Write-Log "Profile already contains 'cursorkit' function" "OK"
        }
    }

    Write-Log "Setup complete!" "DONE"
}

function Invoke-Doctor {
    param([Parameter(Mandatory)][string]$RepoRoot)

    Write-Log "Running diagnostics..." "STEP"

    # Winget gating in Doctor (only check on Windows)
    $checks = @(
        @{ Name = "PowerShell 7"; Cmd = "pwsh"; Args = "--version" }
        @{ Name = "Git";         Cmd = "git";  Args = "--version" }
        @{ Name = "UV";          Cmd = "uv";   Args = "--version" }
        @{ Name = "Bun";         Cmd = "bun";   Args = "--version" }
    )
    if ($IsWindows) {
        $checks += @{ Name = "Winget"; Cmd = "winget"; Args = "--version" }
    }

    foreach ($c in $checks) {
        try {
            $outAll = & $c.Cmd $c.Args 2>&1
            $exit = $LASTEXITCODE
            $out = ($outAll | Select-Object -First 1)

            if ($exit -eq 0) {
                Write-Host "  PASS: $($c.Name) -> $out" -ForegroundColor Green
            } else {
                Write-Host "  FAIL: $($c.Name) -> exit $exit ($out)" -ForegroundColor Red
            }
        } catch {
            Write-Host "  FAIL: $($c.Name) not found" -ForegroundColor Red
        }
    }

    Write-Host ""

    # Validate settings.json contents (proves state, not vibes)
    $settingsPath = Join-Path $RepoRoot ".vscode\settings.json"
    if (-not (Test-Path -LiteralPath $settingsPath -PathType Leaf)) {
        Write-Host "  WARN: $settingsPath missing (run -Setup)" -ForegroundColor Yellow
    } else {
        try {
            $raw = Get-Content -LiteralPath $settingsPath -Raw
            $h = ConvertFrom-JsoncHashtable -Text $raw

            $wantName = "PowerShell 7 (NoProfile)"
            $def = $h["terminal.integrated.defaultProfile.windows"]
            $profiles = $h["terminal.integrated.profiles.windows"]

            if ($def -ne $wantName) {
                Write-Host "  FAIL: defaultProfile.windows != '$wantName' (got '$def')" -ForegroundColor Red
            } elseif (-not ($profiles -is [hashtable]) -or -not $profiles.ContainsKey($wantName)) {
                Write-Host "  FAIL: profiles.windows missing '$wantName'" -ForegroundColor Red
            } else {
                $p = $profiles[$wantName]
                $path = $p["path"]
                $args = $p["args"]

                if (-not $path) {
                    Write-Host "  FAIL: '$wantName' has no path" -ForegroundColor Red
                } else {
                    Write-Host "  PASS: settings.json terminal profile configured" -ForegroundColor Green
                }

                if (-not ($args -is [object[]]) -or ($args -notcontains "-NoProfile")) {
                    Write-Host "  WARN: '$wantName' args missing -NoProfile" -ForegroundColor Yellow
                }
            }
        } catch {
            Write-Host "  FAIL: settings.json parse/validation error: $_" -ForegroundColor Red
        }
    }

    # Validate key policy files
    $mustExist = @(
        (Join-Path $RepoRoot ".cursorignore"),
        (Join-Path $RepoRoot ".cursorindexingignore"),
        (Join-Path $RepoRoot ".cursor\rules\00-windows-shell.mdc")
    )
    foreach ($p in $mustExist) {
        if (Test-Path -LiteralPath $p) { Write-Host "  PASS: $p exists" -ForegroundColor Green }
        else { Write-Host "  WARN: $p missing" -ForegroundColor Yellow }
    }

    # Git hook check fix: presence-based (no dead $EnableGitHooks dependency)
    $hook = Join-Path $RepoRoot ".githooks\pre-commit"
    if (Test-Path -LiteralPath $hook -PathType Leaf) {
        Write-Host "  PASS: git hooks present (.githooks)" -ForegroundColor Green
    } else {
        Write-Host "  INFO: git hooks not configured (optional)" -ForegroundColor DarkGray
    }

    # Backup system visibility (helps prove rollback artifacts exist)
    $bk = Join-Path $RepoRoot ".cursorkit\backups"
    if (Test-Path -LiteralPath $bk -PathType Container) {
        Write-Host "  PASS: rollback backups directory present (.cursorkit\backups)" -ForegroundColor Green
    } else {
        Write-Host "  INFO: rollback backups directory not yet created (will appear on first overwrite inside repo)" -ForegroundColor DarkGray
    }
}

function Invoke-Clean {
    param([Parameter(Mandatory)][string]$RepoRoot)

    Write-Log "Cleaning artifacts..." "STEP"
    $targets = @(".venv", "node_modules", "dist", "build", "out", "__pycache__", ".ruff_cache")

    foreach ($t in $targets) {
        $path = Join-Path $RepoRoot $t
        if (Test-Path -LiteralPath $path) {
            if (Should-Do $path "Remove directory/file") {
                Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction SilentlyContinue
                Write-Log "Removed: $t" "OK"
            } else {
                Write-Log "WhatIf: would remove $path" "SKIP"
            }
        }
    }
}
#endregion

#region ==================== MAIN ENTRY ====================
try {
    $repoRoot = Resolve-RepoRoot -StartPath $RootPath
    $script:RepoRoot = $repoRoot
    Write-Log "Repo root: $repoRoot" "INFO"

    if ($Doctor) {
        Invoke-Doctor -RepoRoot $repoRoot
    } elseif ($Clean) {
        if ($Force -or (Read-Host "Clean build artifacts? (Y/N)") -match '^[Yy]') {
            Invoke-Clean -RepoRoot $repoRoot
        } else {
            Write-Log "Clean cancelled" "SKIP"
        }
    } else {
        Invoke-Setup -RepoRoot $repoRoot
    }
} catch {
    Write-Log "Fatal error: $($_.Exception.Message)" "ERROR"
    exit 1
}
#endregion
