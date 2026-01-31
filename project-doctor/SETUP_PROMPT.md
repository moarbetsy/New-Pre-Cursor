# Setup Prompt: Add Precursor Rules

Use this prompt to set up the Precursor rules in a new workspace.

## Prompt Text

```
Set up the following Cursor rules for this workspace:

### 1. Create .cursor/rules directory structure

Create the following rule files in `.cursor/rules/`:

#### windows-systems-and-toolchain.mdc
```markdown
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
```

#### issue-reporting-and-apply-report.mdc
```markdown
---
description: Mandatory REPORT.md logging and the apply report repair workflow
alwaysApply: true
---

# Issue reporting rule (mandatory)
Whenever an issue occurs in this workspace (tool failure, terminal command failure, install error, config mismatch, unexpected behavior, flaky environment, etc.), you MUST append an entry to REPORT.md in the repository root.

## What to log
Must log:
- Any unexpected non-zero exit code
- Crashes, hangs, timeouts that block work
- Security or permission issues
- Data loss or corruption
- Breaking functional changes

Should log:
- Missing tools or PATH problems
- ExecutionPolicy blocks
- Dependency install failures
- Linter/typecheck failures introduced by changes
- Performance regressions
- Unexpected behavior requiring investigation

Do not log:
- Purely cosmetic issues
- Temporary network issues unless persistent

## How to log (append only)
Append under "## Issues" using:

### YYYY-MM-DD HH:MM (local) — <short descriptive title>
- **Context**: <what you were trying to do>
- **Command / action**: `<exact command or action>`
- **Observed**: <error message / behavior>
- **Root cause**: <what caused this issue>
- **Fix**: <what changed / what to do next>
- **Prevention**: <how to prevent this issue in the future>
- **Status**: resolved | mitigated | unresolved

Rules:
- Do not delete or rewrite REPORT.md history; only append.
- Log each distinct issue separately.
- Always include Prevention.
- Use local time for the timestamp.

# Apply report workflow (mandatory trigger phrase)
When the user says "apply report", do the following:

1) Read REPORT.md.
2) Identify entries with Status = unresolved or mitigated.
3) Fix each issue by:
   - reproducing safely with minimal commands (when feasible)
   - applying a permanent fix (config/script/code change), not a one-off workaround
   - keeping the single-entry run.ps1 pattern
4) Verify by re-running the relevant command(s).
5) Update REPORT.md:
   - do not delete or rewrite history
   - append a new entry for each applied fix if needed
   - add a follow-up note referencing the original issue and set final status to resolved once verified

Constraints:
- Prefer PowerShell 7 commands.
- If a fix requires machine-wide changes (PATH, ExecutionPolicy, installs), document steps and add a project-local mitigation when possible.

# Fail-fast contract
- Any native command must check success ($?) and/or $LASTEXITCODE.
- On failure: stop and report the exact command, exit code, and the next step.
```

#### diagnostics.mdc
```markdown
---
description: Self-healing diagnostics for common workspace issues
alwaysApply: false
---

# Diagnostics

Quick reference for common issues and their solutions:

- **Command Not Found**: Run `cursorkit -Setup` if available
- **Terminal Hangs**: Switch to Windows Terminal to isolate issues
```

#### python.mdc
```json
{
  "content": "# Python Development Rules\n\n## Toolchain\n- Runtime: uv\n- Linter: ruff\n- Formatter: ruff\n- Type Checker: pyright\n\n## Commands\n- Install: `uv sync`\n- Lint: `ruff check .`\n- Format: `ruff format .`\n- Type Check: `pyright .`\n\n## Virtual Environment\n- Path: `.venv`\n- Activate: `.\\.venv\\Scripts\\activate` (Windows) or `source .venv/bin/activate` (Unix)\n"
}
```

#### web.mdc
```json
{
  "content": "# Web/JS/TS Development Rules\n\n## Toolchain\n- Runtime: bun\n- Linter: biome\n- Formatter: biome\n- Type Checker: tsc\n\n## Commands\n- Install: `bun install`\n- Lint: `bunx biome check .`\n- Format: `bunx biome format --write .`\n- Type Check: `bunx tsc --noEmit`\n\n## Lockfile\n- Prefer: `bun.lock` (text format)\n- Legacy: `bun.lockb` (binary, accepted but not preferred)\n"
}
```

#### python-3-14.mdc
```markdown
---
description: Python 3.14 rules with strict typing, Ruff, mypy, and safe string practices
alwaysApply: false
globs:
  - "**/*.py"
  - "pyproject.toml"
---

# Role
You are an expert Python developer specialized in Python 3.14.

# 1. Version and tooling
- Target version: Python 3.14.
- Optimize code for Ruff linter/formatter.
- Use mypy strict mode standards for type checking.
- Prefer pyproject.toml for all configuration.

# 2. Type annotations (PEP 649 / 749)
- Always annotate all functions, methods, and public attributes.
- Do not assume __annotations__ contains resolved values.
- When inspecting types at runtime, use:
  annotationlib.get_annotations(obj, format=annotationlib.Format.VALUE)
- Avoid from __future__ import annotations if 3.14 semantics are active.

# 3. Concurrency and parallelism
- Default: use asyncio for I/O-bound tasks.
- Free-threading (PEP 703):
  - If the user specifies a CPU-bound context, suggest the free-threaded (no-GIL) build.
  - Prefer thread-safe data structures (queue.Queue over manual locking).
  - Verify that imported C-extensions (NumPy, etc.) are compatible with free-threading.
- Subinterpreters (PEP 734):
  - Use concurrent.interpreters only for strict component isolation or actor-model architectures.
  - Pass data between interpreters using serialized messages (JSON/bytes), never shared mutable objects.

# 4. String and security (PEP 750)
- Use template string literals for structured DSLs (SQL/HTML/etc.) where appropriate.
- Prohibit ad-hoc string concatenation (+ or f-strings) for SQL queries or shell commands.

# 5. Error handling and control flow
- Use specific exception types; never except Exception:.
- Use except* only when handling ExceptionGroup from concurrent tasks.
- Prefer logging with structured output/tracebacks over print.

# 6. Performance and libraries
- Prefer compression.zstd over gzip or zipfile for internal data processing if available.
- Use asyncio introspection tools to identify leaked tasks in long-running services.

# 7. Code style
- Keep business logic decoupled from I/O (HTTP, CLI, DB).
- Follow strict PEP 8 naming conventions.
- Prefer immutable data structures (frozen dataclasses) to simplify thread safety.

# Python execution contract for this repo
- Use uv for environments and execution:
  - uv sync
  - uv run <command>
- Do not recommend pip install or python -m venv.
```

### 2. Verify Setup

After creating the files:
1. Ensure `.cursor/rules/` directory exists with all rule files
2. Restart Cursor to load the new rules

The rules will be automatically applied based on their `alwaysApply` settings and glob patterns.
```

## Usage

Copy the prompt text above and paste it into Cursor when setting up a new workspace. The AI assistant will create all the necessary rule files.

## Notes

- The `windows-systems-and-toolchain.mdc` and `issue-reporting-and-apply-report.mdc` rules have `alwaysApply: true`, so they will always be active.
- The `python-3-14.mdc` rule applies only to Python files and `pyproject.toml` based on its glob patterns.
- The `python.mdc` and `web.mdc` files are JSON-formatted rule files.
- Node.js is included as a runtime option in the toolchain contract.
