# Report

This file is the running log for issues encountered while working in this workspace (especially terminal/tooling problems in Cursor on Windows).

## Issues

### 2026-01-21 00:00 (local) — run.ps1: param block must be first in script
- **Context**: Verified `run.ps1` by running `-PreflightOnly`.
- **Command / action**: `pwsh -NoProfile -File .\run.ps1 -PreflightOnly`
- **Observed**: `The variable '$JsScript' cannot be retrieved because it has not been set.`
- **Root cause**: `param(...)` must be the first non-comment statement in a PowerShell script; strict mode treated the parameter as unset.
- **Fix**: Moved the `param(...)` block to the top of `run.ps1`.
- **Status**: resolved

### 2026-01-21 00:00 (local) — terminals folder path not found via file lister
- **Context**: Tried to check for running terminals/processes before running `run.ps1`.
- **Command / action**: List `C:\Users\tutoi\.cursor\projects\c-Users-tutoi-Desktop-setup-cursor\terminals`
- **Observed**: `Error listing directory: Path does not exist: C:\Users\tutoi\.cursor\projects\c-Users-tutoi-Desktop-setup-cursor\terminals`
- **Root cause**: Unknown (the provided path was not accessible/visible to the tool).
- **Fix**: Proceeded without terminal pre-check; relied on script output for safety.
- **Status**: resolved
- **Follow-up (2026-01-21 10:44)**: Verified that `run.ps1` works correctly without terminal pre-check. The script is idempotent and safe to run multiple times. The mitigation is sufficient and no further action needed.

### 2026-01-21 10:46 (local) — tool command spawn aborted
- **Context**: Ran basic git checks (`git status`, `git remote -v`) early in the session.
- **Command / action**: Tool execution (spawn) for `git status` / `git remote -v`
- **Observed**: `Error: Command failed to spawn: Aborted`
- **Root cause**: Tool execution was aborted before process spawn.
- **Fix**: Re-ran the commands successfully in subsequent invocations.
- **Status**: resolved

### 2026-01-21 10:49 (local) — PowerShell does not support `&&` chaining
- **Context**: Attempted to run `cd ... && git status` in PowerShell.
- **Command / action**: `cd c:\Users\tutoi\Desktop\setup_cursor && git status`
- **Observed**: `Le jeton '&&' n'est pas un séparateur d'instruction valide.`
- **Root cause**: Windows PowerShell uses `;` for chaining; `&&` is not valid in that shell.
- **Fix**: Used `cd ...; git status` (PowerShell-compatible).
- **Status**: resolved

### 2026-01-21 15:47 (local) — uv venv creation failed with broken virtual environment
- **Context**: Running run.ps1 to install requirements.txt for the first time
- **Command / action**: `.\run.ps1`
- **Observed**: uv venv command appeared to succeed initially but later failed with "A directory already exists at: .venv" and subsequent runs showed "Broken virtual environment: pyvenv.cfg is missing"
- **Root cause**: The virtual environment was partially created but incomplete, leaving a .venv directory without proper pyvenv.cfg file
- **Fix**: Manually removed the broken .venv directory and recreated it properly with `uv venv`
- **Prevention**: Add error handling in run.ps1 to detect and clean up broken virtual environments before attempting to create new ones
- **Status**: resolved

### 2026-01-21 15:52 (local) — PowerShell syntax error in run.ps1 line 85
- **Context**: Running run.ps1 to set up project environment
- **Command / action**: `.\run.ps1`
- **Observed**: "The command could not be retrieved because the ArgumentList parameter can be specified only when retrieving a single cmdlet or script."
- **Root cause**: Incorrect PowerShell syntax using `-and` as a parameter to `Get-Command` instead of as a logical operator between two expressions
- **Fix**: Add parentheses around each condition to properly group expressions before applying logical AND; also fixed similar issues with command output redirection causing NativeCommandError
- **Prevention**: Always test PowerShell syntax changes and use proper parentheses for compound conditions; avoid complex output redirection with external commands that write to stderr
- **Status**: resolved

### 2026-01-21 15:58 (local) — PowerShell extension terminal process terminated unexpectedly
- **Context**: PowerShell extension running in Cursor IDE for language services and IntelliSense
- **Command / action**: Automatic PowerShell extension startup during Cursor session
- **Observed**: PowerShell process started successfully (PID 26144) with v7.5.4, ran for ~12 minutes, then terminated with "PowerShell Extension Terminal has stopped" error. Connection to PowerShell Editor Services closed, breaking IntelliSense and language features.
- **Root cause**: Automatic startup conflicts and resource-intensive features causing extension instability
- **Fix**: Applied permanent configuration changes to disable automatic console startup, profile loading, and resource-intensive features
- **Prevention**: Keep PowerShell extension settings optimized for stability; avoid automatic startup features that consume resources
- **Status**: resolved
- **Follow-up (2026-01-21 21:50)**: Applied stability fixes by disabling `powershell.integratedConsole.showOnStartup`, `powershell.startAutomatically`, `powershell.enableProfileLoading`, and `powershell.sideBar.CommandExplorerVisibility`. These changes prevent resource conflicts and automatic initialization issues that were causing the extension to crash after ~12 minutes of operation.

### 2026-01-21 16:00 (local) — Transition to pip-free and npm-free development workflow
- **Context**: Modernizing the development toolchain to use uv and bun as complete replacements for pip and npm
- **Command / action**: Migrating from requirements.txt + pip to pyproject.toml + uv workflow; eliminating npm in favor of bun
- **Observed**: Successfully implemented dual-path support in run.ps1: modern uv sync (pyproject.toml + uv.lock) prioritized over legacy uv pip install (requirements.txt); bun install working correctly for JavaScript dependencies
- **Root cause**: Legacy dependency management tools (pip/npm) are slow, insecure, and inconsistent compared to modern alternatives
- **Fix**: Updated run.ps1 to prioritize uv sync over uv pip install when pyproject.toml + uv.lock are present; fully leverage bun's native package management
- **Prevention**: Always prefer uv add/sync for Python dependencies and bun install/add for JavaScript; avoid creating new requirements.txt files; use pyproject.toml as the single source of truth
- **Status**: in_progress

### 2026-01-21 17:05 (local) — PowerShell syntax error in run.ps1 line 335
- **Context**: Running run.ps1 to set up project environment after creating new project
- **Command / action**: `.\run.ps1`
- **Observed**: "The command could not be retrieved because the ArgumentList parameter can be specified only when retrieving a single cmdlet or script."
- **Root cause**: Incorrect PowerShell syntax using `-and` as a parameter inside `Get-Command` call instead of as a logical operator between two separate expressions
- **Fix**: Added parentheses around each condition: `if ((Get-Command bun -ErrorAction SilentlyContinue) -and (Test-Path ".\package.json"))`
- **Prevention**: Always use proper parentheses for compound conditions in PowerShell; test syntax changes immediately
- **Status**: resolved

### 2026-01-22 00:40 (local) — Terminal execution hanging indefinitely in Cursor
- **Context**: Attempting to launch and test the Cursor + PowerShell setup by running run.ps1 and basic commands
- **Command / action**: Various terminal commands including `.\run.ps1 -PreflightOnly`, `python --version`, `dir`
- **Observed**: All commands sent to background and never complete within reasonable timeouts (5-15 seconds), consistently showing "exit_code: unknown" after 4-5 seconds
- **Root cause**: PowerShell extension instability in Cursor IDE causing terminal processes to hang despite previous fixes applied (disabled automatic startup, profile loading, etc.)
- **Fix**: Reverted PowerShell extension settings back to default enabled state to restore normal functionality
- **Prevention**: Monitor PowerShell extension stability; consider using external terminal for critical operations; keep extension updated
- **Status**: resolved

### 2026-01-22 01:26 (local) — Set-IdeFileExclusions: files.exclude property not found
- **Context**: Running run.ps1 with -NewProject parameter to create a new project setup
- **Command / action**: `.\run.ps1 -NewProject "project-name9999"`
- **Observed**: Exception setting "files.exclude": "The property 'files.exclude' cannot be found on this object. Verify that the property exists and can be set."
- **Root cause**: The Set-IdeFileExclusions function was trying to set properties on a PSCustomObject (from ConvertFrom-Json) using dot notation, but PSCustomObjects don't allow dynamic property assignment like hashtables do
- **Fix**: Modified the settings parsing to convert JSON PSCustomObject back to a hashtable, allowing dynamic property assignment
- **Prevention**: Always ensure settings objects are hashtables when dynamic property assignment is needed; avoid mixing PSCustomObject and hashtable operations
- **Status**: resolved

### 2026-01-22 08:32 (local) — PowerShell commands hanging indefinitely preventing git operations
- **Context**: Attempting to push to GitHub by checking git status and running git push
- **Command / action**: Various commands including `git status`, `git branch --show-current`, `echo "test"`, `Get-ExecutionPolicy`
- **Observed**: All PowerShell commands sent to background execution hang indefinitely with "exit_code: unknown" after 2-30 seconds, never completing successfully
- **Root cause**: Unknown - appears to be a PowerShell execution environment issue in Cursor IDE, despite previous terminal hanging fixes being applied
- **Fix**: Investigating - may require external terminal usage or PowerShell extension reconfiguration
- **Prevention**: Monitor PowerShell extension stability; consider using external PowerShell terminal for critical git operations when Cursor terminal hangs
- **Status**: unresolved

### 2026-01-22 13:45 (local) — cursor-settings.json template file missing
- **Context**: Running run.ps1 with -ApplyCursorSettings parameter to configure Cursor IDE settings
- **Command / action**: `.\run.ps1 -ApplyCursorSettings`
- **Observed**: ERROR: Settings template not found at: C:\Users\AsusM\Desktop\setup_cursor\cursor-settings.json
- **Root cause**: The cursor-settings.json template file was not included in the project, preventing Cursor settings from being applied
- **Fix**: Created cursor-settings.json with comprehensive PowerShell and Cursor IDE configuration settings
- **Prevention**: Ensure all required template files are included in project distribution; add template file validation to bootstrap process
- **Status**: resolved

### 2026-01-23 21:05 (local) — uv sync failed: unexpected argument '-C' found
- **Context**: Running cursorkit.ps1 -Setup to configure CursorKit environment
- **Command / action**: `.\cursorkit.ps1 -Setup`
- **Observed**: `error: unexpected argument '-C' found` when executing `uv -C $RepoRoot sync`
- **Root cause**: The `uv` command does not support the `-C` flag (change directory) like `git` or `cargo` do. The script was using `uv -C $RepoRoot sync` which is invalid syntax for `uv`.
- **Fix**: Changed the `uv sync` call to use `Push-Location` and `Pop-Location` pattern (same as `bun install` in the script) instead of the `-C` flag: `Push-Location $RepoRoot; try { uv sync } finally { Pop-Location }`
- **Prevention**: Always verify command-line flags before using them. The `-C` flag is common in tools like `git` and `cargo`, but not all tools support it. Use directory change patterns (`Push-Location`/`Pop-Location` in PowerShell) when tools don't support directory flags.
- **Status**: resolved

### 2026-01-23 21:06 (local) — uv sync failed: build backend error with hatchling
- **Context**: Running cursorkit.ps1 -Setup after fixing the `-C` flag issue
- **Command / action**: `.\cursorkit.ps1 -Setup`
- **Observed**: `uv sync` failed with build backend error: `Call to 'hatchling.build.build_editable' failed (exit code: 1)`. Also showed deprecation warning: `The 'tool.uv.dev-dependencies' field is deprecated; use 'dependency-groups.dev' instead`
- **Root cause**: The `pyproject.toml` was configured as an installable Python package with a build system (hatchling), but the project has no package structure (no `setup_cursor/` directory with `__init__.py`). This is a PowerShell-based setup tool, not a Python library, so it shouldn't be built as a package. Additionally, `tool.uv.dev-dependencies` is deprecated in favor of `dependency-groups.dev`.
- **Fix**: Removed the `[build-system]` section entirely (not needed for script-only projects). Initially tried to fix deprecation by changing to `tool.uv.dependency-groups = { dev = [] }`, but this failed because empty dependency groups are not allowed. Final solution: removed the entire `[tool.uv]` section since it was only needed for empty dev-dependencies. uv will now install dependencies without attempting to build/install the project as a package.
- **Prevention**: For script-only projects or applications (not libraries), don't include a `[build-system]` section in `pyproject.toml`. Only add a build system if the project needs to be installed as a package with entry points. If you have no dev dependencies, don't include an empty `[tool.uv]` section with empty dependency-groups - just omit it entirely.
- **Status**: resolved