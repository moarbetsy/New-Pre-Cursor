---
description: Windows PowerShell 7, uv, and Bun rules for stable, reproducible automation
alwaysApply: true
---

# Role and environment
- Role: Windows Systems and Automation Expert
- OS: Windows 11 (x64)
- Shell: PowerShell 7 (pwsh)
- Terminal assumption: `pwsh -NoLogo -NoProfile`
- Hardware: Intel i7-8665U / 16GB RAM (optimize for low overhead and speed)

# Hard constraints
## PowerShell syntax only
- Always output PowerShell 7 syntax.
- Never output Bash commands (ls, touch, export, source, rm -rf).
- Never use bash operators && or ||.
  - Use ";" or "if ($?) { ... }" instead of "&&".
  - Use "if (-not $?) { ... }" instead of "||".
- Use Windows paths with "\" or Join-Path.

## Encoding
In any PowerShell script you create or modify, force UTF-8 output encoding:
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

## Process management
- Do not leave background processes running indefinitely.
- If stopping processes, target specific PIDs and explain what is being terminated.
- Do not use broad Stop-Process by name unless explicitly requested.

# Toolchain contract
## Python (uv only)
- Never use "pip install" or "python -m venv".
- Use uv:
  - Init: uv init
  - Add deps: uv add <package>
  - Sync: uv sync
  - Run: uv run <command>

## JavaScript (Bun only)
- Never use npm or yarn unless explicitly forced by a legacy dependency.
- Use bun:
  - Install: bun install
  - Run: bun run <script>
  - Tooling: bunx <tool>

## Node.js
Use Node.js only as a runtime requirement when needed; do not use it as a package manager.

# Execution strategy: run.ps1 single entry point (mandatory)
- Do not ask the user to type many loose commands.
- Always create or update a run.ps1 script in the repository root and route execution through it.

## run.ps1 requirements
- Must be idempotent and safe to re-run.
- Must fail fast with clear errors.
- Must include tool preflight checks via Get-Command and include where.exe diagnostics on failure.
- Avoid indefinite watchers. If a watcher is unavoidable, provide bounded execution and a clean stop mechanism.

## Standard run.ps1 template
```powershell
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

Write-Host "Preflight checks..." -ForegroundColor Cyan

$tools = @("pwsh") # add "uv" and/or "bun" per project
foreach ($t in $tools) {
    if (-not (Get-Command $t -ErrorAction SilentlyContinue)) {
        Write-Host "Missing tool: $t" -ForegroundColor Red
        Write-Host ("PATH check: " + (where.exe $t 2>$null)) -ForegroundColor Yellow
        exit 1
    }
}

# Python (uv):
# if (Test-Path "pyproject.toml") { uv sync; if ($?) { uv run python main.py } }

# JavaScript (bun):
# if (Test-Path "package.json") { bun install; if ($?) { bun run start } }
```

# Troubleshooting defaults

* On failure, do not assume code is wrong first.
* Verify tool visibility:
  * where.exe <tool>
  * Get-Command <tool> -ErrorAction SilentlyContinue
* If scripts are blocked, suggest:
  * Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
* If exit code is 0xFFFFFFFF, treat as a silent crash. Capture stdout/stderr to a log file and print the tail.

# Diagnostics and self-healing

* **Command Not Found**: Run `cursorkit -Setup` if available
* **Terminal Hangs**: Switch to Windows Terminal to isolate issues
* **Tool spawn failures**: Retry once; if persistent, check PATH and execution policy
