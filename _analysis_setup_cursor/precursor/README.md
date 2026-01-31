# Precursor

**Precursor** is a config-driven, idempotent "project doctor" and scaffolder designed for **Cursor IDE**. It automates development environment setup and maintenance across multiple technology stacks, ensuring consistency and best practices.

## Features

- **Idempotent**: Running `-Setup` multiple times produces zero diffs (except timestamps/state)
- **Config-Driven**: All tool IDs, versions, and behaviors come from `precursor.json` with sensible defaults
- **Deep-Merge**: Never clobbers user config; safely merges JSON/JSONC/YAML files
- **Stateful Efficiency**: Hash-based caching for slow operations
- **Safe-by-Default**: Automatic backups before writes; rollback support; strict mode for CI
- **Cross-Platform**: Works on Windows PowerShell 7+ and Unix-like systems
- **MCP Integration**: Built-in Model Context Protocol server for Cursor IDE integration
- **Verification Loops**: Automatically verify code changes (tests, linting, type checking) after scaffolding
- **Post-Processing Hooks**: Automatically format code after generation to prevent CI issues
- **Shared Knowledge Base**: Accumulate team knowledge in PRECURSOR.md to prevent repeated mistakes
- **Slash Commands**: Define custom workflows for repeated tasks

## Supported Stacks

- **Python**: uv, ruff, pyright/basedpyright
- **Web/TypeScript**: bun, biome, TypeScript compiler
- **Rust**: cargo, clippy, rustfmt
- **C/C++**: cmake, clang-format, clang-tidy
- **Docker**: Dockerfile best-practice checks

## For Cursor AI Agents - Setup Instructions

**Copy and paste this entire block into Cursor's chat to set up Precursor:**

```
I need to set up Precursor in this project. Please follow these steps in order:

STEP 1: Verify Prerequisites
- Check PowerShell 7+: `$PSVersionTable.PSVersion`
- Check Bun: `bun --version`
- Check Git: `git --version`
- If missing, install from: PowerShell (https://aka.ms/powershell), Bun (https://bun.sh), Git (https://git-scm.com)

STEP 2: Install Precursor
- Clone: `git clone https://github.com/moarbetsy/Precursor.git`
- Navigate: `cd Precursor`
- Install: `bun install`

STEP 3: Initial Scan
- Run: `.\precursor.ps1 -Scan`
- Review detected stacks, missing tools, and recommendations

STEP 4: Configure (Optional)
- Create/edit `precursor.json` in project root
- Minimum config to enable MCP:
  {
    "$schema": "./precursor.schema.json",
    "mcp": { "enabled": true },
    "ci": { "enabled": true },
    "secrets": { "enabled": true },
    "backup": { "enabled": true, "maxBackups": 10 }
  }
- See `precursor.schema.json` for full schema

STEP 5: Bootstrap Project
- Run: `.\precursor.ps1 -Setup`
- This will:
  * Detect technology stacks
  * Install missing tools (unless -Offline)
  * Generate `.cursor/rules/` files
  * Create `.vscode/settings.json`
  * Generate GitHub Actions workflows
  * Scan for secrets
  * Create backup before changes

STEP 6: Verify MCP Configuration
- Check `.cursor/mcp.json` exists and contains:
  {
    "mcpServers": {
      "precursor": {
        "command": "bun",
        "args": [".precursor/mcp/server.ts"],
        "env": {}
      }
    }
  }
- Ensure `precursor.json` has `"mcp": { "enabled": true }`

STEP 7: Understand Generated Rules
Precursor generates these rules in `.cursor/rules/`:
- `windows-systems-and-toolchain.mdc` (always) - PowerShell 7, uv, Bun patterns
- `diagnostics.mdc` (always) - Self-healing diagnostics
- `issue-reporting-and-apply-report.mdc` (always) - Issue logging to REPORT.md
- `python-3-14.mdc` (if Python) - Python 3.14+ with uv
- `web.mdc` (if web/TS) - Bun, Biome, TypeScript patterns

Rules are automatically applied by Cursor when present in `.cursor/rules/`.

STEP 8: Verify Setup
- Run: `.\precursor.ps1 -Scan` to confirm all tools installed
- Check `.cursor/rules/` contains expected rule files
- Verify `.cursor/mcp.json` is properly configured
- Test MCP server: `bun .precursor/mcp/server.ts` (should start without errors)

IMPORTANT NOTES:
- Precursor is idempotent: safe to run `-Setup` multiple times
- All file changes are backed up to `.precursor/backups/`
- Use `.\precursor.ps1 -Rollback` to restore if needed
- Use `.\precursor.ps1 -ResetState` if cache is stale
- Rules are generated based on detected stacks (pyproject.toml, package.json, etc.)
- MCP server provides report collection, toolchain detection, and advanced features
- Issue reporting: any errors are logged to REPORT.md automatically
- Apply fixes: say "apply report" to fix all unresolved issues from REPORT.md
```

## Quick Start - Step by Step

Follow these commands **in order** to get started with Precursor:

### Step 1: Prerequisites Check

First, verify you have the required tools installed:

```powershell
# Check PowerShell version (must be 7+)
$PSVersionTable.PSVersion

# Check if Bun is installed
bun --version

# Check if Git is installed
git --version
```

If any are missing:
- **PowerShell 7+**: Install from https://aka.ms/powershell
- **Bun**: Install from https://bun.sh
- **Git**: Install from https://git-scm.com

### Step 2: Clone and Install

```powershell
# Clone the repository
git clone https://github.com/moarbetsy/Precursor.git

# Navigate to the directory
cd Precursor

# Install dependencies
bun install
```

### Step 3: First Run - Scan Your Project

Before setting up, run a read-only scan to see what Precursor detects:

```powershell
# Run a health scan (read-only, no changes)
.\precursor.ps1 -Scan
```

This will show you:
- Detected technology stacks
- Missing tools
- Configuration issues
- Recommendations

### Step 4: Configure (Optional)

If you want to customize settings, create or edit `precursor.json`:

```powershell
# Create a basic config file (or edit existing)
# Use your preferred editor to create precursor.json
```

Example `precursor.json`:

```json
{
  "$schema": "./precursor.schema.json",
  "python": {
    "runtime": "uv",
    "linter": "ruff",
    "formatter": "ruff",
    "typechecker": "pyright"
  },
  "web": {
    "runtime": "bun",
    "linter": "biome",
    "formatter": "biome",
    "typechecker": "tsc"
  },
  "workspace": {
    "mode": "auto"
  },
  "ci": {
    "enabled": true
  },
  "mcp": {
    "enabled": true
  }
}
```

**Note**: If you don't create `precursor.json`, Precursor will use sensible defaults.

### Step 5: Bootstrap Your Project

Now run the full setup to bootstrap your project:

```powershell
# Run the full bootstrap (idempotent - safe to run multiple times)
.\precursor.ps1 -Setup
```

This will:
1. Detect your technology stacks
2. Install missing tools (if not in offline mode)
3. Generate `.cursor/rules/` for AI guidance
4. Set up `.vscode/settings.json` with best practices
5. Create GitHub Actions workflows (if CI is enabled)
6. Scan for exposed secrets
7. Create a backup before any changes

### Step 6: Verify Setup

After setup, verify everything worked:

```powershell
# Run another scan to see the results
.\precursor.ps1 -Scan
```

You should see:
- ✅ All tools installed
- ✅ Configurations generated
- ✅ No critical issues

### Step 7: (Optional) View Generated Files

Check what Precursor created:

```powershell
# View Cursor rules
Get-Content .cursor\rules\*.mdc

# View VS Code settings
Get-Content .vscode\settings.json

# View GitHub Actions workflows
Get-ChildItem .github\workflows\
```

## Common Workflows

### Daily Usage

```powershell
# 1. Check project health
.\precursor.ps1 -Scan

# 2. If issues found, re-run setup
.\precursor.ps1 -Setup
```

### If Something Goes Wrong

```powershell
# 1. Rollback to latest backup
.\precursor.ps1 -Rollback

# 2. Or reset state cache if it's stale
.\precursor.ps1 -ResetState

# 3. Then re-run setup
.\precursor.ps1 -Setup
```

### CI/CD Pipeline

```powershell
# 1. Generate JSON report (no color, for CI)
.\precursor.ps1 -Scan --json --no-color > report.json

# 2. Or run strict mode (fails on warnings)
.\precursor.ps1 -Setup -Strict --json
```

### Offline Mode

If you're in an environment without internet:

```powershell
# Run setup without downloading anything
.\precursor.ps1 -Setup -Offline
```

This will:
- Use existing tools in PATH
- Use cached binaries in `.precursor/bin/`
- Report what's missing (but won't download)

### Self-Update

To update Precursor itself:

```powershell
.\precursor.ps1 -Update
```

## Command Reference

| Command | Description | When to Use |
|---------|-------------|-------------|
| `.\precursor.ps1 -Scan` | Read-only health check | Before setup, daily checks |
| `.\precursor.ps1 -Setup` | Full bootstrap | First time, after config changes |
| `.\precursor.ps1 -Setup -Strict` | Setup with strict mode | CI/CD pipelines |
| `.\precursor.ps1 -Setup -Offline` | Setup without downloads | Offline environments |
| `.\precursor.ps1 -Rollback` | Restore latest backup | When something breaks |
| `.\precursor.ps1 -ResetState` | Clear state cache | When cache is stale |
| `.\precursor.ps1 -Update` | Update Precursor | To get latest version |
| `.\precursor.ps1 -Scan --json` | JSON output | CI/CD integration |
| `.\precursor.ps1 -Scan --no-color` | No colored output | CI/CD, scripts |

## Configuration

Precursor looks for configuration in this order:
1. `precursor.json`
2. `precursor.jsonc` (JSON with comments)
3. `precursor.yaml` / `precursor.yml`

If none are found, sensible defaults are used.

See `precursor.schema.json` for the complete schema documentation.

## Cursor Rules Generated by Precursor

When you run `.\precursor.ps1 -Setup`, Precursor generates Cursor rules in `.cursor/rules/` based on your project's technology stacks:

### Available Rule Files

- **`windows-systems-and-toolchain.mdc`** (always applied)
  - Windows PowerShell 7 syntax requirements
  - uv (Python) and Bun (JavaScript) toolchain rules
  - Encoding and process management guidelines
  - Execution strategy and troubleshooting

- **`python-3-14.mdc`** (applied if Python detected)
  - Python 3.14+ specific rules
  - uv package manager patterns
  - Type checking and linting standards

- **`web.mdc`** (applied if web/TypeScript detected)
  - JavaScript/TypeScript best practices
  - Bun runtime patterns
  - Biome formatter/linter rules

- **`diagnostics.mdc`** (always applied)
  - Self-healing diagnostics for common issues
  - Automatic problem detection and resolution

- **`issue-reporting-and-apply-report.mdc`** (always applied)
  - Issue logging to `REPORT.md`
  - "apply report" workflow for fixing logged issues
  - Status tracking (resolved/mitigated/unresolved)

### MCP Server Configuration

Precursor includes an MCP (Model Context Protocol) server for advanced Cursor IDE integration:

**Configuration file:** `.cursor/mcp.json`
```json
{
  "mcpServers": {
    "precursor": {
      "command": "bun",
      "args": [".precursor/mcp/server.ts"],
      "env": {}
    }
  }
}
```

**Enable in `precursor.json`:**
```json
{
  "mcp": {
    "enabled": true
  }
}
```

The MCP server provides:
- Report collection and merging across projects
- Enhanced toolchain detection
- Advanced configuration management
- Real-time project health monitoring

## What Precursor Does

### Project Bootstrap
- Detects technology stacks in your project
- Installs and configures development tools
- Generates `.cursor/rules/` for AI guidance
- Sets up `.vscode/settings.json` with best practices
- Creates GitHub Actions workflows

### Health Checks
- Validates tool installations
- Checks for misconfigurations
- Scans for exposed secrets
- Reports missing dependencies

### Configuration Management
- Deep-merges configuration files without clobbering user settings
- Maintains consistent IDE settings across teams
- Generates CI/CD workflows automatically

## Architecture

```
precursor/
├── precursor.ps1          # PowerShell entry point
├── src/                   # TypeScript core (runs on Bun)
│   ├── index.ts          # Main orchestration
│   ├── config.ts         # Configuration loading
│   ├── detector.ts        # Stack detection
│   ├── toolchain.ts      # Tool resolution
│   ├── doctor.ts         # Health checks
│   ├── scaffold.ts       # File generation
│   ├── merge.ts          # Deep merge engine
│   ├── state.ts          # State management
│   ├── backup.ts         # Backup/rollback
│   ├── ci.ts             # CI workflow generation
│   ├── secrets.ts        # Secret scanning
│   └── report.ts         # Report collection
├── .precursor/           # Runtime state
│   ├── state.json        # Hash-based cache
│   ├── backups/          # Backup snapshots
│   └── mcp/              # MCP server
└── precursor.json        # Configuration file
```

## Development

### Running Tests

```powershell
bun test
```

### Building

```powershell
bun run build
```

### Linting and Formatting

```powershell
bun run lint
bun run format
```

## Troubleshooting

### Missing Tools

Precursor will attempt to install missing tools automatically. If installation fails:

```powershell
# 1. Check execution policy
Get-ExecutionPolicy

# 2. If needed, set execution policy (CurrentUser scope)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 3. Use offline mode if downloads are blocked
.\precursor.ps1 -Setup -Offline

# 4. Manually install missing tools, then re-run
.\precursor.ps1 -Setup
```

### State Cache Issues

If state cache becomes stale:

```powershell
# 1. Reset the cache
.\precursor.ps1 -ResetState

# 2. Re-run setup
.\precursor.ps1 -Setup
```

### Rollback

If something goes wrong, restore from backup:

```powershell
# 1. Rollback to latest backup
.\precursor.ps1 -Rollback

# 2. Verify the rollback worked
.\precursor.ps1 -Scan
```

Backups are stored in `.precursor/backups/<timestamp>/`.

### Permission Issues

If you get permission errors:

```powershell
# 1. Check if you're running as administrator (if needed)
[Security.Principal.WindowsIdentity]::GetCurrent().Groups -contains 'S-1-5-32-544'

# 2. Check execution policy
Get-ExecutionPolicy -List

# 3. Set execution policy for CurrentUser (doesn't require admin)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Documentation

- **Full Documentation**: See `DOCUMENTATION.md` for complete API reference and advanced usage
- **Schema**: See `precursor.schema.json` for configuration options
- **File Tree**: See `FILE_TREE.md` for project structure

## License

MIT License - see `LICENSE` file for details.
