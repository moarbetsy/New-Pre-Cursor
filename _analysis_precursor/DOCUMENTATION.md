# Precursor - Complete Documentation

**Version:** 1.0.0  
**Last Updated:** January 2026

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Installation](#installation)
4. [Configuration](#configuration)
5. [Usage](#usage)
6. [Core Features](#core-features)
7. [Stack Support](#stack-support)
8. [API Reference](#api-reference)
9. [MCP Integration](#mcp-integration)
10. [State Management](#state-management)
11. [Backup and Rollback](#backup-and-rollback)
12. [CI/CD Integration](#cicd-integration)
13. [Verification Loops](#verification-loops)
14. [Post-Processing Hooks](#post-processing-hooks)
15. [Shared Knowledge Base](#shared-knowledge-base)
16. [Slash Commands](#slash-commands)
17. [Troubleshooting](#troubleshooting)
18. [Development](#development)
19. [Best Practices](#best-practices)

---

## Overview

**Precursor** is a config-driven, idempotent "project doctor" and scaffolder designed specifically for **Cursor IDE**. It automates the setup and maintenance of development environments across multiple technology stacks, ensuring consistency, best practices, and developer productivity.

### Key Principles

- **Idempotent**: Running `-Setup` multiple times produces zero diffs (except timestamps/state)
- **Config-Driven**: All tool IDs, versions, and behaviors come from `precursor.json`
- **Deep-Merge**: Never clobbers user config; merges JSON/JSONC/YAML safely
- **Stateful Efficiency**: Hash-based caching for slow operations
- **Safe-by-Default**: Backups before every write; rollback support; strict mode for CI
- **Cross-Platform**: Works on Windows PowerShell 7+ and Unix-like systems

### Supported Stacks

- **Python** (uv, ruff, pyright/basedpyright)
- **Web/JavaScript/TypeScript** (bun, biome, tsc)
- **Rust** (cargo, clippy, rustfmt)
- **C/C++** (cmake, clang-format, clang-tidy)
- **Docker** (Dockerfile best practices)

### Use Cases

- **Project Bootstrap**: Automatically set up new projects with best-practice configurations
- **Environment Validation**: Scan projects to identify missing tools, misconfigurations, or issues
- **Configuration Management**: Maintain consistent IDE settings, rules, and tooling across teams
- **CI/CD Integration**: Generate GitHub Actions workflows automatically
- **Monorepo Support**: Handle multi-project workspaces intelligently

---

## Architecture

### Component Overview

```
precursor/
├── precursor.ps1          # PowerShell entry point (orchestrator)
├── src/                   # TypeScript core (runs on Bun)
│   ├── index.ts          # Main exports and orchestration
│   ├── cli.ts            # CLI argument parsing
│   ├── config.ts         # Configuration loading/validation
│   ├── detector.ts        # Stack detection
│   ├── toolchain.ts      # Tool resolution/installation
│   ├── doctor.ts         # Health checks and diagnostics
│   ├── scaffold.ts       # File generation
│   ├── merge.ts          # Deep merge engine
│   ├── state.ts          # State management
│   ├── backup.ts         # Backup/rollback
│   ├── ci.ts             # CI workflow generation
│   ├── secrets.ts        # Secret scanning
│   └── report.ts         # Report collection and merging
├── .precursor/           # Runtime state
│   ├── state.json        # Hash-based cache
│   ├── backups/          # Backup snapshots
│   ├── bin/              # Portable tool binaries
│   ├── reports/          # Collected reports (JSON files)
│   └── mcp/              # MCP server
│       └── server.ts     # MCP server implementation
└── precursor.json        # Configuration file
```

### Execution Flow

1. **Entry Point**: `precursor.ps1` validates environment and calls TypeScript core
2. **Config Loading**: Loads `precursor.json` (or `.jsonc`, `.yaml`) with deep merge
3. **Stack Detection**: Scans project for marker files (e.g., `pyproject.toml`, `package.json`)
4. **Tool Resolution**: Checks system PATH → package manager → portable cache
5. **Backup**: Creates timestamped backup before any writes
6. **Scaffolding**: Generates/updates `.cursor/rules/`, `.vscode/settings.json`, etc.
7. **Post-Processing Hooks**: Runs formatters and linters on generated code
8. **Verification**: Runs tests, linting, and type checking
9. **CI Generation**: Creates GitHub Actions workflows
10. **Secret Scanning**: Scans codebase for exposed secrets
11. **State Update**: Saves hash-based state for efficient re-runs

### Data Flow

```
User Command
    ↓
PowerShell Wrapper (precursor.ps1)
    ↓
TypeScript Core (src/cli.ts)
    ↓
Config Loader (config.ts) → PrecursorConfig
    ↓
Stack Detector (detector.ts) → StackType[]
    ↓
Tool Resolver (toolchain.ts) → ToolResult[]
    ↓
Doctor/Scaffold (doctor.ts, scaffold.ts)
    ↓
File System (merge.ts, backup.ts)
    ↓
State Manager (state.ts) → State
```

---

## Installation

### Prerequisites

- **PowerShell 7+** (Windows/Linux/Mac)
- **Bun** runtime (for TypeScript execution)
- **Git** (for monorepo detection)

### Quick Start (Windows)

```powershell
# Clone or download Precursor
cd precursor
bun install
```

### Installation Methods

#### Method 1: Direct Clone

```powershell
git clone <repository-url>
cd precursor
bun install
```

#### Method 2: As a Submodule

```powershell
git submodule add <repository-url> precursor
cd precursor
bun install
```

#### Method 3: Standalone Script

Copy `precursor.ps1` and the `src/` directory to your project, then run:

```powershell
.\precursor.ps1 -Setup
```

### Verifying Installation

```powershell
# Check Bun is available
bun --version

# Check PowerShell version (must be 7+)
$PSVersionTable.PSVersion

# Run Precursor scan
.\precursor.ps1 -Scan
```

---

## Configuration

### Configuration File

Precursor looks for configuration files in this order:

1. `precursor.json`
2. `precursor.jsonc` (JSON with comments)
3. `precursor.yaml` / `precursor.yml`

If no config file is found, Precursor uses sensible defaults.

### Configuration Schema

The configuration follows a JSON Schema defined in `precursor.schema.json`. Here's a complete example:

```json
{
  "$schema": "./precursor.schema.json",
  "python": {
    "runtime": "uv",
    "linter": "ruff",
    "formatter": "ruff",
    "typechecker": "pyright",
    "venvPath": ".venv"
  },
  "web": {
    "runtime": "bun",
    "linter": "biome",
    "formatter": "biome",
    "typechecker": "tsc",
    "migrateFrom": ["eslint", "prettier"]
  },
  "rust": {
    "toolchain": "stable",
    "linter": "clippy",
    "formatter": "rustfmt",
    "audit": false,
    "deny": false
  },
  "cpp": {
    "buildSystem": "cmake",
    "formatter": "clang-format",
    "linter": "clang-tidy",
    "compileCommands": true
  },
  "docker": {
    "enabled": true,
    "lint": false
  },
  "workspace": {
    "mode": "auto",
    "root": null
  },
  "ci": {
    "enabled": true,
    "workflows": {
      "python": {
        "enabled": true,
        "os": ["ubuntu-latest"]
      },
      "web": {
        "enabled": true,
        "os": ["ubuntu-latest", "windows-latest"]
      }
    }
  },
  "mcp": {
    "enabled": true,
    "port": 0
  },
  "secrets": {
    "enabled": true,
    "ignorePatterns": [
      "**/node_modules/**",
      "**/.venv/**",
      "**/target/**",
      "**/*.lock"
    ],
    "highEntropyThreshold": 0.7
  },
  "backup": {
    "enabled": true,
    "maxBackups": 10
  },
  "strict": {
    "failOnWarnings": false,
    "failOnMissingTools": false,
    "requireAllChecks": false
  }
}
```

### Configuration Sections

#### Python Configuration

```json
{
  "python": {
    "runtime": "uv",           // "uv" | "pip" | "poetry"
    "linter": "ruff",         // Linter tool name
    "formatter": "ruff",       // Formatter tool name
    "typechecker": "pyright",  // "pyright" | "basedpyright" | "none"
    "venvPath": ".venv"        // Virtual environment path
  }
}
```

#### Web/JS/TS Configuration

```json
{
  "web": {
    "runtime": "bun",          // "bun" | "node" | "npm" | "pnpm" | "yarn"
    "linter": "biome",         // "biome" | "eslint" | "none"
    "formatter": "biome",      // "biome" | "prettier" | "none"
    "typechecker": "tsc",      // "tsc" | "none"
    "migrateFrom": []          // Array of tools to migrate from
  }
}
```

#### Rust Configuration

```json
{
  "rust": {
    "toolchain": "stable",     // Rust toolchain version
    "linter": "clippy",        // Linter tool
    "formatter": "rustfmt",    // Formatter tool
    "audit": false,            // Enable cargo audit
    "deny": false              // Enable cargo deny
  }
}
```

#### C/C++ Configuration

```json
{
  "cpp": {
    "buildSystem": "cmake",    // "cmake" | "meson" | "make"
    "formatter": "clang-format",
    "linter": "clang-tidy",
    "compileCommands": true    // Generate compile_commands.json
  }
}
```

#### Workspace Configuration

```json
{
  "workspace": {
    "mode": "auto",            // "root" | "subproject" | "auto"
    "root": null               // Explicit workspace root (optional)
  }
}
```

- **`root`**: Use git root as workspace root
- **`subproject`**: Use current directory
- **`auto`**: Detect automatically (prefers git root if available)

#### CI Configuration

```json
{
  "ci": {
    "enabled": true,
    "workflows": {
      "python": {
        "enabled": true,
        "os": ["ubuntu-latest", "windows-latest"],
        "matrix": {
          "python-version": ["3.10", "3.11", "3.12"]
        }
      }
    }
  }
}
```

#### Backup Configuration

```json
{
  "backup": {
    "enabled": true,
    "maxBackups": 10           // Maximum number of backups to keep
  }
}
```

#### Strict Mode Configuration

```json
{
  "strict": {
    "failOnWarnings": false,      // Exit with error on warnings
    "failOnMissingTools": false,  // Exit with error if tools missing
    "requireAllChecks": false     // Require all checks to pass
  }
}
```

#### Report Collection Configuration

```json
{
  "report": {
    "enabled": true,              // Enable report collection
    "reportsDir": ".precursor/reports",  // Directory to store collected reports
    "autoCollect": false,         // Automatically collect reports during setup
    "projectName": "my-project"   // Project name/identifier for collected reports
  }
}
```

**Features:**

- **Duplicate Detection**: Uses SHA-256 hashing to detect duplicate entries
- **JSON Storage**: Each entry stored as individual JSON file with metadata
- **Merged Reports**: Generate consolidated markdown reports for review
- **Multi-Project**: Collect reports from multiple projects into single location
- **Training Data**: Designed for collecting issue reports for AI training/learning

### Default Configuration

If no config file exists, Precursor uses these defaults:

```json
{
  "python": {
    "runtime": "uv",
    "linter": "ruff",
    "formatter": "ruff",
    "typechecker": "pyright",
    "venvPath": ".venv"
  },
  "web": {
    "runtime": "bun",
    "linter": "biome",
    "formatter": "biome",
    "typechecker": "tsc"
  },
  "rust": {
    "toolchain": "stable",
    "linter": "clippy",
    "formatter": "rustfmt"
  },
  "cpp": {
    "buildSystem": "cmake",
    "formatter": "clang-format",
    "linter": "clang-tidy",
    "compileCommands": true
  },
  "workspace": {
    "mode": "auto"
  },
  "ci": {
    "enabled": true
  },
  "mcp": {
    "enabled": true
  },
  "secrets": {
    "enabled": true,
    "ignorePatterns": [
      "**/node_modules/**",
      "**/.venv/**",
      "**/target/**",
      "**/dist/**",
      "**/*.lock",
      "**/*.lockb"
    ],
    "highEntropyThreshold": 0.7
  },
  "backup": {
    "enabled": true,
    "maxBackups": 10
  }
}
```

### Configuration Validation

Precursor validates configuration against the JSON Schema:

```powershell
# Invalid config will show errors
.\precursor.ps1 -Setup
# Error: Configuration validation failed: /python/runtime: must be equal to one of the allowed values
```

---

## Usage

### Basic Commands

#### Setup (Bootstrap)

```powershell
# Full bootstrap (idempotent)
.\precursor.ps1 -Setup

# With strict mode (fail on warnings)
.\precursor.ps1 -Setup -Strict

# Offline mode (no downloads)
.\precursor.ps1 -Setup -Offline

# JSON output (for CI)
.\precursor.ps1 -Setup --json
```

#### Scan (Read-Only Doctor)

```powershell
# Run doctor scan
.\precursor.ps1 -Scan

# JSON output
.\precursor.ps1 -Scan --json > report.json

# No color output
.\precursor.ps1 -Scan --no-color
```

#### Rollback

```powershell
# Restore latest backup
.\precursor.ps1 -Rollback
```

#### Reset State

```powershell
# Clear state cache
.\precursor.ps1 -ResetState
```

#### Self-Update

```powershell
# Update Precursor itself
.\precursor.ps1 -Update
```

### Command-Line Options

| Option | Description | Example |
|--------|-------------|---------|
| `-Setup` | Run full bootstrap | `.\precursor.ps1 -Setup` |
| `-Scan` | Read-only doctor scan | `.\precursor.ps1 -Scan` |
| `-Strict` | Fail on warnings (for CI) | `.\precursor.ps1 -Setup -Strict` |
| `-Offline` | No downloads/updates | `.\precursor.ps1 -Setup -Offline` |
| `-Rollback` | Restore latest backup | `.\precursor.ps1 -Rollback` |
| `-ResetState` | Wipe state cache | `.\precursor.ps1 -ResetState` |
| `-Update` | Self-update Precursor | `.\precursor.ps1 -Update` |
| `--json` | Output JSON format | `.\precursor.ps1 -Scan --json` |
| `--no-color` | Disable colored output | `.\precursor.ps1 -Scan --no-color` |

### CI Usage

```powershell
# Generate JSON report for CI
.\precursor.ps1 -Scan --json --no-color > report.json

# Strict mode in CI (fails on warnings)
.\precursor.ps1 -Setup -Strict --json
```

---

## Core Features

### 1. Idempotent Operations

Precursor is designed to be **idempotent**: running `-Setup` multiple times produces the same result (except for timestamps and state updates).

**How it works:**

- Uses hash-based state tracking (`.precursor/state.json`)
- Compares file hashes before writing
- Only updates files that have actually changed
- Preserves user modifications through deep merge

**Example:**

```powershell
# First run
.\precursor.ps1 -Setup
# Creates .cursor/rules/python.mdc, .vscode/settings.json, etc.

# Second run (idempotent)
.\precursor.ps1 -Setup
# No changes made (files already match desired state)
```

### 2. Deep Merge Engine

Precursor never clobbers user configuration. Instead, it uses a sophisticated deep merge algorithm:

**Features:**

- **Nested Object Merging**: Recursively merges nested objects
- **Array Append-Unique**: Appends unique values to arrays, preserving order
- **Type Preservation**: Maintains original data types
- **Null Handling**: Skips null/undefined values in source

**Example:**

```json
// Existing .vscode/settings.json
{
  "files.watcherExclude": {
    "**/node_modules/**": true,
    "**/custom/**": true
  },
  "editor.fontSize": 14
}

// Precursor adds:
{
  "files.watcherExclude": {
    "**/.venv/**": true
  },
  "python.defaultInterpreterPath": "${workspaceFolder}/.venv/Scripts/python.exe"
}

// Result (merged):
{
  "files.watcherExclude": {
    "**/node_modules/**": true,
    "**/custom/**": true,        // Preserved!
    "**/.venv/**": true          // Added
  },
  "editor.fontSize": 14,         // Preserved!
  "python.defaultInterpreterPath": "${workspaceFolder}/.venv/Scripts/python.exe"  // Added
}
```

### 3. Stack Detection

Precursor automatically detects technology stacks by scanning for marker files:

**Detection Logic:**

- **Python**: `pyproject.toml`, `uv.lock`, `requirements.txt`, `poetry.lock`, `setup.py`
- **Web/JS/TS**: `package.json`, `bun.lock`, `tsconfig.json`, `vite.config.*`, `next.config.*`, HTML/CSS files
- **Rust**: `Cargo.toml`, `Cargo.lock`
- **C/C++**: `CMakeLists.txt`, `meson.build`, `Makefile`, `.clang-format`, C/C++ source files
- **Docker**: `Dockerfile`, `docker-compose.yml`

**Workspace Root Detection:**

1. If `workspace.root` is set in config → use that
2. If `workspace.mode === "subproject"` → use current directory
3. If `workspace.mode === "root"` or `"auto"` → try git root
4. Fallback → current directory

### 4. Tool Resolution Waterfall

Precursor uses a waterfall strategy to find tools:

1. **System PATH**: Check if tool is in system PATH
2. **Package Manager**: Check if installed via package manager (winget, brew, apt, etc.)
3. **Portable Cache**: Check `.precursor/bin/<tool>/` for portable binaries
4. **Installation**: Attempt to install if not found (unless `-Offline`)

**Tool Resolution Result:**

```typescript
interface ToolResult {
  found: boolean;
  version?: string;
  path?: string;
  source?: "system" | "package-manager" | "portable";
  critical?: boolean;
  error?: string;
}
```

**Example:**

```powershell
# Tool found in PATH
{
  "found": true,
  "version": "0.1.0",
  "path": "PATH",
  "source": "system"
}

# Tool found in portable cache
{
  "found": true,
  "version": "0.1.0",
  "path": ".precursor/bin/ruff/0.1.0/ruff.exe",
  "source": "portable"
}
```

### 5. File Scaffolding

Precursor generates and maintains several types of files:

#### Generated Files

- **`.cursor/rules/*.mdc`**: Stack-specific Cursor rules
- **`.vscode/settings.json`**: VS Code workspace settings
- **`.vscode/extensions.json`**: Recommended extensions
- **`.cursor/mcp.json`**: MCP server configuration
- **`.github/workflows/*.yml`**: GitHub Actions workflows
- **`.gitignore`**: Git ignore patterns
- **`.cursorignore`**: Cursor ignore patterns

#### Rule Files

Each detected stack gets a rule file in `.cursor/rules/<stack>.mdc`:

**Example: `.cursor/rules/python.mdc`**

```markdown
# Python Development Rules

## Toolchain
- Runtime: uv
- Linter: ruff
- Formatter: ruff
- Type Checker: pyright

## Commands
- Install: `uv sync`
- Lint: `ruff check .`
- Format: `ruff format .`
- Type Check: `pyright .`

## Virtual Environment
- Path: `.venv`
- Activate: `.\\.venv\\Scripts\\activate` (Windows) or `source .venv/bin/activate` (Unix)
```

### 6. Secret Scanning

Precursor can scan your codebase for exposed secrets:

**Features:**

- High-entropy string detection
- Pattern-based secret detection
- Configurable ignore patterns
- Fails setup if secrets found (unless disabled)

**Configuration:**

```json
{
  "secrets": {
    "enabled": true,
    "ignorePatterns": [
      "**/node_modules/**",
      "**/.venv/**",
      "**/*.lock"
    ],
    "highEntropyThreshold": 0.7
  }
}
```

---

## Stack Support

### Python Stack

**Supported Tools:**

- **Runtime**: `uv` (default), `pip`, `poetry`
- **Linter**: `ruff` (default)
- **Formatter**: `ruff` (default)
- **Type Checker**: `pyright` (default), `basedpyright`, `none`

**Generated Files:**

- `.cursor/rules/python.mdc`
- `.vscode/settings.json` (Python interpreter path, type checking mode)
- `.vscode/extensions.json` (Python extensions)
- `.github/workflows/python.yml` (if CI enabled)

**Example Configuration:**

```json
{
  "python": {
    "runtime": "uv",
    "linter": "ruff",
    "formatter": "ruff",
    "typechecker": "pyright",
    "venvPath": ".venv"
  }
}
```

**Commands Generated:**

- Install: `uv sync`
- Lint: `ruff check .`
- Format: `ruff format .`
- Type Check: `pyright .`

### Web/JavaScript/TypeScript Stack

**Supported Tools:**

- **Runtime**: `bun` (default), `node`, `npm`, `pnpm`, `yarn`
- **Linter**: `biome` (default), `eslint`, `none`
- **Formatter**: `biome` (default), `prettier`, `none`
- **Type Checker**: `tsc` (default), `none`

**Generated Files:**

- `.cursor/rules/web.mdc`
- `.vscode/settings.json` (TypeScript SDK path)
- `.vscode/extensions.json` (Biome, ESLint extensions)
- `.github/workflows/web.yml` (if CI enabled)

**Example Configuration:**

```json
{
  "web": {
    "runtime": "bun",
    "linter": "biome",
    "formatter": "biome",
    "typechecker": "tsc",
    "migrateFrom": ["eslint", "prettier"]
  }
}
```

**Migration Support:**

If `migrateFrom` is specified, Precursor can help migrate from ESLint/Prettier to Biome.

### Rust Stack

**Supported Tools:**

- **Toolchain**: `stable` (default), or specific version
- **Linter**: `clippy` (default)
- **Formatter**: `rustfmt` (default)
- **Audit**: `cargo audit` (optional)
- **Deny**: `cargo deny` (optional)

**Generated Files:**

- `.cursor/rules/rust.mdc`
- `.vscode/settings.json` (rust-analyzer config)
- `.vscode/extensions.json` (rust-analyzer extension)
- `.github/workflows/rust.yml` (if CI enabled)

**Example Configuration:**

```json
{
  "rust": {
    "toolchain": "stable",
    "linter": "clippy",
    "formatter": "rustfmt",
    "audit": false,
    "deny": false
  }
}
```

### C/C++ Stack

**Supported Tools:**

- **Build System**: `cmake` (default), `meson`, `make`
- **Formatter**: `clang-format` (default)
- **Linter**: `clang-tidy` (default)
- **Compile Commands**: Generate `compile_commands.json`

**Generated Files:**

- `.cursor/rules/cpp.mdc`
- `.vscode/settings.json` (compile commands path)
- `.vscode/extensions.json` (C++ extensions)
- `.github/workflows/cpp.yml` (if CI enabled)

**Example Configuration:**

```json
{
  "cpp": {
    "buildSystem": "cmake",
    "formatter": "clang-format",
    "linter": "clang-tidy",
    "compileCommands": true
  }
}
```

### Docker Stack

**Supported Features:**

- Dockerfile best-practice checks
- Docker Compose support
- Optional linting

**Generated Files:**

- `.cursor/rules/docker.mdc`
- `.github/workflows/docker.yml` (if CI enabled)

**Example Configuration:**

```json
{
  "docker": {
    "enabled": true,
    "lint": false
  }
}
```

---

## API Reference

### TypeScript API

#### `setup(options?: PrecursorOptions): Promise<PrecursorResult>`

Main setup function - idempotent bootstrap.

**Parameters:**

```typescript
interface PrecursorOptions {
  configPath?: string;    // Path to config file
  strict?: boolean;       // Fail on warnings
  offline?: boolean;      // No downloads
  json?: boolean;         // JSON output
  noColor?: boolean;      // Disable colors
}
```

**Returns:**

```typescript
interface PrecursorResult {
  success: boolean;
  message?: string;
  data?: unknown;
  errors?: string[];
  warnings?: string[];
}
```

**Example:**

```typescript
import { setup } from "./precursor/src/index.js";

const result = await setup({
  strict: true,
  offline: false
});

if (result.success) {
  console.log("Setup completed:", result.data);
} else {
  console.error("Setup failed:", result.errors);
}
```

#### `scan(options?: PrecursorOptions): Promise<PrecursorResult>`

Read-only doctor scan.

**Example:**

```typescript
import { scan } from "./precursor/src/index.js";

const result = await scan();
console.log(result.data); // DoctorReport
```

#### `rollback(options?: PrecursorOptions): Promise<PrecursorResult>`

Restore latest backup.

**Example:**

```typescript
import { rollback } from "./precursor/src/index.js";

const result = await rollback();
if (result.success) {
  console.log("Rollback successful");
}
```

#### `reset(options?: PrecursorOptions): Promise<PrecursorResult>`

Reset state cache.

**Example:**

```typescript
import { reset } from "./precursor/src/index.js";

await reset();
```

### Configuration API

#### `loadConfig(configPath?: string): Promise<PrecursorConfig>`

Load configuration from file.

**Example:**

```typescript
import { loadConfig } from "./precursor/src/config.js";

const config = await loadConfig("precursor.json");
```

#### `validateConfig(config: PrecursorConfig): Promise<void>`

Validate configuration against schema.

**Example:**

```typescript
import { loadConfig, validateConfig } from "./precursor/src/config.js";

const config = await loadConfig();
await validateConfig(config);
```

### Stack Detection API

#### `detectStacks(config: PrecursorConfig): Promise<StackType[]>`

Detect all stacks in the project.

**Example:**

```typescript
import { detectStacks } from "./precursor/src/detector.js";
import { loadConfig } from "./precursor/src/config.js";

const config = await loadConfig();
const stacks = await detectStacks(config);
console.log("Detected stacks:", stacks); // ["python", "web"]
```

### Tool Resolution API

#### `resolveTool(toolId: string, config: PrecursorConfig, options?: PrecursorOptions): Promise<ToolResult>`

Resolve tool location and version.

**Example:**

```typescript
import { resolveTool } from "./precursor/src/toolchain.js";
import { loadConfig } from "./precursor/src/config.js";

const config = await loadConfig();
const tool = await resolveTool("ruff", config);
console.log(tool); // { found: true, version: "0.1.0", path: "PATH", source: "system" }
```

#### `installTool(toolId: string, config: PrecursorConfig, options?: PrecursorOptions): Promise<ToolResult>`

Install tool using waterfall strategy.

**Example:**

```typescript
import { installTool } from "./precursor/src/toolchain.js";
import { loadConfig } from "./precursor/src/config.js";

const config = await loadConfig();
const result = await installTool("ruff", config);
```

### Doctor API

#### `runDoctor(config: PrecursorConfig, stacks: string[], options?: PrecursorOptions): Promise<DoctorReport>`

Run doctor scan.

**Example:**

```typescript
import { runDoctor } from "./precursor/src/doctor.js";
import { loadConfig, detectStacks } from "./precursor/src/config.js";

const config = await loadConfig();
const stacks = await detectStacks(config);
const report = await runDoctor(config, stacks);
console.log(report.tools); // Record<string, ToolDiagnostic>
```

### Scaffold API

#### `runScaffold(config: PrecursorConfig, stacks: string[], options?: PrecursorOptions): Promise<void>`

Generate/update project files.

**Example:**

```typescript
import { runScaffold } from "./precursor/src/scaffold.js";
import { loadConfig, detectStacks } from "./precursor/src/config.js";

const config = await loadConfig();
const stacks = await detectStacks(config);
await runScaffold(config, stacks);
```

### Merge API

#### `deepMerge<T>(target: T, source: Partial<T>, options?: { arrayStrategy?: "replace" | "append-unique" }): T`

Deep merge two objects.

**Example:**

```typescript
import { deepMerge } from "./precursor/src/merge.js";

const merged = deepMerge(
  { a: 1, b: { c: 2 } },
  { b: { d: 3 } },
  { arrayStrategy: "append-unique" }
);
// Result: { a: 1, b: { c: 2, d: 3 } }
```

#### `mergeFile(filePath: string, newData: unknown, options?: MergeOptions): Promise<void>`

Merge file with new data.

**Example:**

```typescript
import { mergeFile } from "./precursor/src/merge.js";

await mergeFile(".vscode/settings.json", {
  "editor.fontSize": 14
}, { backup: true });
```

### State API

#### `getState(): State`

Get current state (load or create new).

**Example:**

```typescript
import { getState } from "./precursor/src/state.js";

const state = getState();
console.log(state.stacks); // ["python", "web"]
```

#### `updateState(config: PrecursorConfig, stacks: string[]): Promise<void>`

Update state with new information.

**Example:**

```typescript
import { updateState } from "./precursor/src/state.js";
import { loadConfig, detectStacks } from "./precursor/src/config.js";

const config = await loadConfig();
const stacks = await detectStacks(config);
await updateState(config, stacks);
```

#### `hasFileChanged(filePath: string): boolean`

Check if file has changed since last state.

**Example:**

```typescript
import { hasFileChanged } from "./precursor/src/state.js";

if (hasFileChanged("precursor.json")) {
  console.log("Config changed!");
}
```

### Backup API

#### `ensureBackup(config: PrecursorConfig): Promise<string>`

Create backup before writes.

**Example:**

```typescript
import { ensureBackup } from "./precursor/src/backup.js";
import { loadConfig } from "./precursor/src/config.js";

const config = await loadConfig();
const backupPath = await ensureBackup(config);
console.log("Backup created:", backupPath);
```

#### `restoreBackup(config: PrecursorConfig): Promise<{ success: boolean; message: string; backupPath?: string }>`

Restore from latest backup.

**Example:**

```typescript
import { restoreBackup } from "./precursor/src/backup.js";
import { loadConfig } from "./precursor/src/config.js";

const config = await loadConfig();
const result = await restoreBackup(config);
```

---

## MCP Integration

Precursor includes an MCP (Model Context Protocol) server for Cursor IDE integration.

### MCP Server Location

`.precursor/mcp/server.ts`

### MCP Tools

#### `doctor_diagnose`

Run Precursor doctor scan and return JSON report.

**Parameters:**

```json
{
  "configPath": "string (optional)",
  "offline": "boolean (optional, default: false)"
}
```

**Example:**

```json
{
  "name": "doctor_diagnose",
  "arguments": {
    "offline": true
  }
}
```

#### `doctor_fix`

Apply a specific fix.

**Parameters:**

```json
{
  "fixKey": "string (required)",
  "configPath": "string (optional)"
}
```

**Available Fix Keys:**

- `scaffold-ruff-config`: Create Ruff configuration
- `scaffold-biome-config`: Create Biome configuration
- `scaffold-clang-format`: Create clang-format configuration

**Example:**

```json
{
  "name": "doctor_fix",
  "arguments": {
    "fixKey": "scaffold-ruff-config"
  }
}
```

#### `scaffold_rule`

Generate a new `.cursor/rules/<tech>.mdc` file.

**Parameters:**

```json
{
  "stack": "string (required)",
  "configPath": "string (optional)"
}
```

**Stack Values:**

- `python`
- `web`
- `rust`
- `cpp`
- `docker`

**Example:**

```json
{
  "name": "scaffold_rule",
  "arguments": {
    "stack": "python"
  }
}
```

#### `collect_report`

Collect and merge report entries from `REPORT.md` or other report files into a single folder for training/learning.

**Parameters:**

```json
{
  "reportPath": "string (required)",
  "projectName": "string (optional)",
  "configPath": "string (optional)",
  "generateMerged": "boolean (optional, default: false)"
}
```

**Description:**

- Parses `REPORT.md` files and extracts individual issue entries
- Stores entries as JSON files in `.precursor/reports/` (or configured directory)
- Automatically detects and skips duplicate entries using content hashing
- Can generate a merged markdown report for easy review
- Supports multiple report files (comma-separated paths)

**Example:**

```json
{
  "name": "collect_report",
  "arguments": {
    "reportPath": "REPORT.md",
    "projectName": "setup_cursor",
    "generateMerged": true
  }
}
```

**Multiple Files:**

```json
{
  "name": "collect_report",
  "arguments": {
    "reportPath": "REPORT.md,../other-project/REPORT.md",
    "projectName": "multi-project"
  }
}
```

### MCP Configuration

Precursor automatically generates `.cursor/mcp.json`:

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

### Manual MCP Server Start

```powershell
cd .precursor/mcp
bun run server.ts
```

---

## State Management

### State File

Precursor maintains state in `.precursor/state.json`:

```json
{
  "version": "1.0.0",
  "lastUpdate": "2026-01-23T12:00:00.000Z",
  "hashes": {
    "precursor.json": "abc123...",
    "pyproject.toml": "def456...",
    ".vscode/settings.json": "ghi789..."
  },
  "stacks": ["python", "web"],
  "tools": {
    "ruff": {
      "version": "0.1.0",
      "path": "PATH",
      "installed": true,
      "lastCheck": "2026-01-23T12:00:00.000Z"
    }
  }
}
```

### Hash-Based Caching

Precursor uses SHA-256 hashes to track file changes:

**Tracked Files:**

- `precursor.json`, `precursor.jsonc`, `precursor.yaml`
- `precursor.schema.json`
- `pyproject.toml`, `package.json`, `Cargo.toml`
- Lock files (`uv.lock`, `bun.lock`, `Cargo.lock`)
- `.vscode/settings.json`
- `.cursor/mcp.json`

**Benefits:**

- Efficient change detection
- Skip unnecessary file writes
- Idempotent operations

### State Operations

#### Check if File Changed

```typescript
import { hasFileChanged } from "./precursor/src/state.js";

if (hasFileChanged("precursor.json")) {
  // Config changed, reload
}
```

#### Reset State

```powershell
.\precursor.ps1 -ResetState
```

This clears `.precursor/state.json`, forcing a full re-scan on next run.

---

## Backup and Rollback

### Backup System

Precursor creates timestamped backups before any file writes:

**Backup Location:** `.precursor/backups/<timestamp>/`

**Backed Up Files:**

- `.vscode/settings.json`
- `.vscode/extensions.json`
- `.cursor/mcp.json`
- `.cursor/rules/` (directory)
- `.github/workflows/` (directory)
- `.gitignore`
- `.cursorignore`

### Backup Configuration

```json
{
  "backup": {
    "enabled": true,
    "maxBackups": 10
  }
}
```

### Rollback

Restore from latest backup:

```powershell
.\precursor.ps1 -Rollback
```

**What Happens:**

1. Finds latest backup in `.precursor/backups/`
2. Restores all backed-up files
3. Reports success/failure

**Example Output:**

```
Restored from backup: 2026-01-23T12-00-00-000Z
```

### Manual Backup Management

Backups are stored in `.precursor/backups/` with ISO timestamp names:

```
.pre cursor/backups/
├── 2026-01-23T12-00-00-000Z/
│   ├── .vscode/
│   │   └── settings.json
│   └── .cursor/
│       └── rules/
└── 2026-01-23T11-00-00-000Z/
    └── ...
```

Old backups are automatically cleaned up (keeps `maxBackups` most recent).

---

## CI/CD Integration

### GitHub Actions Workflows

Precursor automatically generates GitHub Actions workflows for detected stacks.

#### Python Workflow

**File:** `.github/workflows/python.yml`

**Steps:**

1. Checkout code
2. Install uv
3. Install dependencies (`uv sync`)
4. Ruff check
5. Ruff format check
6. Type check (if enabled)
7. Run tests

**Example:**

```yaml
name: Python CI
on:
  push:
    branches: [main, master]
  pull_request:
    branches: [main, master]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v4
        with:
          uv-version: latest
      - run: uv sync
      - run: uv run ruff check .
      - run: uv run ruff format --check .
      - run: uv run pyright .
```

#### Web Workflow

**File:** `.github/workflows/web.yml`

**Steps:**

1. Checkout code
2. Setup Bun
3. Install dependencies (`bun install`)
4. Biome check
5. TypeScript check (if enabled)
6. Run tests

#### Rust Workflow

**File:** `.github/workflows/rust.yml`

**Steps:**

1. Checkout code
2. Install Rust toolchain
3. Cache cargo
4. Format check (`cargo fmt --check`)
5. Clippy (`cargo clippy -- -D warnings`)
6. Run tests (`cargo test`)

#### C/C++ Workflow

**File:** `.github/workflows/cpp.yml`

**Steps:**

1. Checkout code
2. Install clang tools
3. Configure CMake
4. Build
5. Format check
6. Run tests

#### Precursor CI Workflow

**File:** `.github/workflows/precursor.yml`

Runs Precursor scan on every push/PR:

```yaml
name: Precursor CI
on:
  push:
    branches: [main, master]
  pull_request:
    branches: [main, master]
jobs:
  precursor:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: oven-sh/setup-bun@v2
      - run: bun run precursor.ps1 -Scan --json
```

### CI Configuration

```json
{
  "ci": {
    "enabled": true,
    "workflows": {
      "python": {
        "enabled": true,
        "os": ["ubuntu-latest", "windows-latest"],
        "matrix": {
          "python-version": ["3.10", "3.11", "3.12"]
        }
      }
    }
  }
}
```

### Disabling CI

```json
{
  "ci": {
    "enabled": false
  }
}
```

Or disable specific workflows:

```json
{
  "ci": {
    "enabled": true,
    "workflows": {
      "python": {
        "enabled": false
      }
    }
  }
}
```

---

## Verification Loops

**Based on Boris Cherny's principle**: "Probably the most important thing to get great results - give AI a way to verify its work. If AI has that feedback loop, it will 2-3x the quality of the final result."

### Overview

Verification loops automatically run tests, linting, and type checking after scaffolding to ensure code quality. This feature implements the critical principle that verification dramatically improves AI-generated code quality.

### Configuration

Enable verification in `precursor.json`:

```json
{
  "verification": {
    "enabled": true,
    "failOnError": false,
    "browserTesting": false,
    "commands": {
      "python": ["uv run pytest", "uv run ruff check ."],
      "web": ["bun test", "bunx biome check ."]
    }
  }
}
```

### Default Verification Commands

Precursor automatically runs stack-specific verification:

- **Python**: `ruff check`, `ruff format --check`, type checking, `pytest`
- **Web/TypeScript**: `biome check`, `tsc --noEmit`, `bun test`
- **Rust**: `cargo fmt --check`, `cargo clippy`, `cargo test`
- **C/C++**: `cmake --build`, `ctest`

### Custom Commands

Override default commands per stack:

```json
{
  "verification": {
    "commands": {
      "python": ["uv run my-custom-test"],
      "web": ["bun run e2e"]
    }
  }
}
```

### Browser Testing

Enable browser-based UI testing (requires `cursor-ide-browser` MCP):

```json
{
  "verification": {
    "browserTesting": true
  }
}
```

### Integration

Verification runs automatically after scaffolding. Results are included in the setup output and can be accessed via the `run_verification` MCP tool.

### Verification Rule

Precursor generates `.cursor/rules/verification.mdc` that instructs Cursor to:
- Always verify changes after making them
- Run relevant tests and checks
- Fix issues immediately
- Document failures in PRECURSOR.md

---

## Post-Processing Hooks

**Based on Boris Cherny's PostToolUse hook pattern**: Automatically format code after generation to prevent formatting errors in CI.

### Overview

Post-processing hooks run automatically after scaffolding to format and lint generated code. This handles the "last 10% of formatting" that might be missed.

### Configuration

Configure hooks in `precursor.json`:

```json
{
  "hooks": {
    "postScaffold": [
      {
        "name": "format-code",
        "command": "bunx biome format --write .",
        "stack": "web",
        "enabled": true
      }
    ]
  }
}
```

### Default Hooks

Precursor automatically runs stack-specific formatters:

- **Python**: `ruff format .` (if using ruff)
- **Web/TypeScript**: `biome format --write .` (if using biome)
- **Rust**: `cargo fmt`
- **C/C++**: `clang-format -i` (for C/C++ files)

### Custom Hooks

Add custom hooks for any stack:

```json
{
  "hooks": {
    "postScaffold": [
      {
        "name": "custom-lint",
        "command": "my-custom-linter",
        "enabled": true
      }
    ]
  }
}
```

### Hook Results

Hook results are included in the setup output. Failed hooks generate warnings but don't fail setup unless configured to do so.

---

## Shared Knowledge Base

**Based on Boris Cherny's CLAUDE.md pattern**: Accumulate team knowledge to prevent repeated mistakes and implement "Compounding Engineering."

### Overview

The shared knowledge base (PRECURSOR.md) accumulates team knowledge over time, making the AI smarter about your codebase. When mistakes are made, they're documented here to prevent repetition.

### Configuration

Enable knowledge base in `precursor.json`:

```json
{
  "knowledge": {
    "enabled": true,
    "file": ".cursor/PRECURSOR.md"
  }
}
```

### File Structure

PRECURSOR.md is automatically initialized with:

- Common mistakes and fixes
- Project-specific patterns
- Tool configuration quirks
- Best practices learned over time

### Adding Entries

#### Via MCP Tool

Use the `add_knowledge_entry` MCP tool:

```json
{
  "title": "Common mistake: forgetting to run tests",
  "category": "mistake",
  "content": "Always run tests after making changes. Use verification loops.",
  "relatedIssues": ["2026-01-24 issue"]
}
```

#### Manually

Add entries directly to PRECURSOR.md:

```markdown
### 2026-01-24 — Common mistake: forgetting to run tests

**Category**: mistake

Always run tests after making changes. Use verification loops.

**Related Issues**: 2026-01-24 issue

---
```

### Categories

- **mistake**: Common errors and how to fix them
- **pattern**: Project-specific patterns and conventions
- **quirk**: Tool configuration quirks and workarounds
- **practice**: Best practices and recommendations
- **other**: Miscellaneous knowledge

### Knowledge Base Rule

Precursor generates `.cursor/rules/knowledge-base.mdc` that instructs Cursor to:
- Check PRECURSOR.md before making changes
- Document mistakes and fixes
- Add new patterns and practices
- Reference related issues from REPORT.md

### Integration with REPORT.md

Knowledge entries can reference resolved issues from REPORT.md, creating a comprehensive knowledge system.

---

## Slash Commands

**Based on Boris Cherny's slash commands pattern**: Automate repeated workflows that are performed many times daily.

### Overview

Slash commands allow you to define custom workflows for repeated tasks. Commands are checked into git and available to both developers and AI agents.

### Configuration

Define commands in `precursor.json`:

```json
{
  "commands": {
    "commit-push-pr": {
      "description": "Commit, push, and create PR",
      "steps": [
        { "type": "shell", "command": "git status" },
        { "type": "shell", "command": "git add ." },
        { "type": "interactive", "prompt": "Commit message" },
        { "type": "shell", "command": "git commit -m \"{commit_message}\"" },
        { "type": "shell", "command": "git push" }
      ]
    }
  }
}
```

### Command Format

Commands consist of steps:

- **shell**: Execute a shell command
- **interactive**: Prompt for user input

### File-Based Commands

Store commands in `.precursor/commands/*.json` files:

```json
{
  "name": "test-all",
  "description": "Run all tests",
  "steps": [
    { "type": "shell", "command": "bun test" },
    { "type": "shell", "command": "uv run pytest" }
  ]
}
```

### Executing Commands

#### Via MCP Tool

Use the `execute_command` MCP tool:

```json
{
  "commandName": "commit-push-pr",
  "interactiveInputs": {
    "Commit message": "Fix bug in feature X"
  }
}
```

#### Listing Commands

Use the `list_commands` MCP tool to see all available commands.

### Commands Rule

Precursor generates `.cursor/rules/commands.mdc` that documents available commands and how to use them.

### Benefits

- **Automation**: Save time on repeated workflows
- **Consistency**: Standardize common tasks across team
- **AI-Friendly**: Commands are available to AI agents via MCP
- **Version Controlled**: Commands are checked into git

---

## Troubleshooting

### Common Issues

#### 1. Bun Not Found

**Error:** `Bun not found. Please install Bun: https://bun.sh`

**Solution:**

```powershell
# Install Bun
powershell -c "irm bun.sh/install.ps1 | iex"

# Verify installation
bun --version
```

#### 2. PowerShell Version Too Old

**Error:** Script requires PowerShell 7+

**Solution:**

```powershell
# Check version
$PSVersionTable.PSVersion

# Install PowerShell 7+ from https://aka.ms/powershell-release
```

#### 3. Execution Policy Blocked

**Error:** `cannot be loaded because running scripts is disabled`

**Solution:**

```powershell
# Check current policy
Get-ExecutionPolicy

# Set execution policy (requires admin)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### 4. Tool Not Found

**Error:** `Critical tool <tool> not found`

**Solution:**

```powershell
# Run in offline mode to see what's missing
.\precursor.ps1 -Scan -Offline

# Install missing tools manually, or
# Let Precursor install them (remove -Offline flag)
```

#### 5. Configuration Validation Failed

**Error:** `Configuration validation failed: ...`

**Solution:**

1. Check `precursor.schema.json` for valid values
2. Validate JSON syntax
3. Check for typos in configuration keys

#### 6. State Cache Issues

**Symptom:** Precursor not detecting changes

**Solution:**

```powershell
# Reset state cache
.\precursor.ps1 -ResetState

# Re-run setup
.\precursor.ps1 -Setup
```

#### 7. Backup Restore Failed

**Error:** `No backups found`

**Solution:**

- Check if backups exist: `ls .precursor/backups/`
- Verify backup configuration: `"backup": { "enabled": true }`

#### 8. Merge Conflicts

**Symptom:** Files not merging correctly

**Solution:**

1. Check file format (JSON vs JSONC vs YAML)
2. Verify file syntax is valid
3. Manually merge if needed, then re-run Precursor

### Debug Mode

Enable verbose output:

```powershell
# PowerShell verbose mode
$VerbosePreference = "Continue"
.\precursor.ps1 -Setup
```

### Proxy Issues

Precursor respects standard proxy environment variables:

```powershell
$env:HTTP_PROXY = "http://proxy.example.com:8080"
$env:HTTPS_PROXY = "http://proxy.example.com:8080"
$env:NO_PROXY = "localhost,127.0.0.1"
```

### Offline Mode

Use `-Offline` flag to prevent all downloads:

```powershell
.\precursor.ps1 -Setup -Offline
```

**What Offline Mode Does:**

- Uses existing tools in PATH
- Uses cached binaries in `.precursor/bin/`
- Emits actionable report of missing tools
- Skips tool installation attempts

### Getting Help

1. **Check Logs**: Look for error messages in console output
2. **State File**: Inspect `.precursor/state.json` for clues
3. **Backups**: Check `.precursor/backups/` for previous working state
4. **Configuration**: Validate `precursor.json` against schema

---

## Development

### Project Structure

```
precursor/
├── .precursor/          # Runtime state (gitignored)
│   ├── state.json
│   ├── backups/
│   ├── bin/
│   └── mcp/
├── src/                  # TypeScript source
│   ├── index.ts
│   ├── cli.ts
│   ├── config.ts
│   ├── detector.ts
│   ├── toolchain.ts
│   ├── doctor.ts
│   ├── scaffold.ts
│   ├── merge.ts
│   ├── state.ts
│   ├── backup.ts
│   ├── ci.ts
│   └── secrets.ts
├── precursor.ps1        # PowerShell entry point
├── precursor.json       # Default configuration
├── precursor.schema.json # JSON Schema
├── package.json
├── tsconfig.json
└── biome.json
```

### Building

```powershell
# Install dependencies
bun install

# Build (if needed)
bun run build

# Type check
bun run typecheck

# Lint
bun run lint

# Format
bun run format
```

### Testing

```powershell
# Run tests
bun test

# Run specific test file
bun test src/merge.test.ts
```

### Development Workflow

1. **Make Changes**: Edit TypeScript files in `src/`
2. **Test Locally**: Run `.\precursor.ps1 -Setup` in a test project
3. **Run Tests**: `bun test`
4. **Lint/Format**: `bun run lint && bun run format`
5. **Type Check**: `bun run typecheck`

### Adding a New Stack

1. **Update `detector.ts`**: Add detection logic
2. **Update `scaffold.ts`**: Add rule generation
3. **Update `ci.ts`**: Add workflow generation
4. **Update `config.ts`**: Add configuration interface
5. **Update `precursor.schema.json`**: Add schema definition
6. **Update `toolchain.ts`**: Add tool resolution if needed

### Adding a New Tool

1. **Update `toolchain.ts`**: Add tool resolution logic
2. **Update `doctor.ts`**: Add tool-specific checks
3. **Update Configuration**: Add tool to default config

### MCP Server Development

The MCP server is in `.precursor/mcp/server.ts`. To test:

```powershell
cd .precursor/mcp
bun run server.ts
```

### Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes
4. Add tests
5. Run `bun test && bun run lint && bun run typecheck`
6. Submit a pull request

---

## Best Practices

### Configuration Management

1. **Version Control**: Commit `precursor.json` to version control
2. **Schema Reference**: Always include `"$schema": "./precursor.schema.json"`
3. **Team Consistency**: Use same configuration across team
4. **Documentation**: Document any custom configurations

### Project Setup

1. **Run Setup Early**: Run `.\precursor.ps1 -Setup` when starting a new project
2. **Review Generated Files**: Check `.cursor/rules/` and `.vscode/settings.json`
3. **Customize Carefully**: Use deep merge to add custom settings
4. **Commit Generated Files**: Commit generated files to version control

### CI/CD

1. **Use Strict Mode**: `.\precursor.ps1 -Setup -Strict` in CI
2. **JSON Output**: Use `--json` for machine-readable output
3. **Regular Scans**: Run `-Scan` regularly to catch issues early
4. **Workflow Generation**: Let Precursor generate workflows, then customize if needed

### State Management

1. **Don't Edit State File**: Never manually edit `.precursor/state.json`
2. **Reset When Needed**: Use `-ResetState` if state seems stale
3. **Backup Before Reset**: Consider backing up state before reset

### Backup Strategy

1. **Keep Backups Enabled**: Default `maxBackups: 10` is usually sufficient
2. **Review Backups**: Periodically check `.precursor/backups/`
3. **Test Rollback**: Test rollback process before you need it

### Tool Management

1. **Prefer System Tools**: Install tools system-wide when possible
2. **Use Offline Mode**: Use `-Offline` in CI or restricted environments
3. **Document Tool Versions**: Document required tool versions in README

### Monorepo Considerations

1. **Workspace Mode**: Use `"workspace": { "mode": "auto" }` for monorepos
2. **Subproject Mode**: Use `"mode": "subproject"` for individual packages
3. **Root Detection**: Let Precursor detect git root automatically

### Security

1. **Secret Scanning**: Keep secret scanning enabled
2. **Review Ignore Patterns**: Ensure sensitive files are in `ignorePatterns`
3. **Validate Config**: Always validate configuration against schema
4. **Backup Security**: Be aware backups may contain sensitive data

---

## Appendix

### File Reference

| File | Purpose |
|------|---------|
| `precursor.ps1` | PowerShell entry point |
| `precursor.json` | Configuration file |
| `precursor.schema.json` | JSON Schema for validation |
| `.precursor/state.json` | State cache |
| `.precursor/backups/` | Backup snapshots |
| `.cursor/rules/*.mdc` | Cursor rules |
| `.vscode/settings.json` | VS Code settings |
| `.vscode/extensions.json` | Recommended extensions |
| `.cursor/mcp.json` | MCP server config |
| `.github/workflows/*.yml` | CI workflows |

### Environment Variables

| Variable | Purpose |
|----------|---------|
| `HTTP_PROXY` | HTTP proxy URL |
| `HTTPS_PROXY` | HTTPS proxy URL |
| `NO_PROXY` | Comma-separated list of hosts to bypass proxy |

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Error (tool failure, validation error, etc.) |

### Supported File Formats

- **JSON**: Standard JSON
- **JSONC**: JSON with comments (via `jsonc-parser`)
- **YAML**: YAML 1.2 (via `yaml` package)

---

## License

See LICENSE file in repository root.

---

## Changelog

### Version 1.0.0 (January 2026)

- Initial release
- Support for Python, Web/JS/TS, Rust, C/C++, Docker
- Idempotent operations
- Deep merge engine
- State management
- Backup and rollback
- CI/CD integration
- MCP server
- Secret scanning
- Report collection and merging for training/learning

---

## Support

For issues, questions, or contributions, please refer to the repository's issue tracker.

---

**End of Documentation**
